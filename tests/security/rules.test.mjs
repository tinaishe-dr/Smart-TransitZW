import { readFileSync } from 'node:fs';
import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, writeBatch, serverTimestamp, runTransaction } from 'firebase/firestore';
let env;
const service = () => ({ name: 'CBD to Mbare', origin: 'Market Square', destination: 'Mbare', vehicle: 'ABC1234', fare: 1, capacity: 1, company: 'Test operator', notice: '', status: 'active', departureAt: null, ownerId: 'operator', onboard: 0, archived: false, updatedAt: serverTimestamp() });
const as = uid => env.authenticatedContext(uid, { email: `${uid}@example.test` }).firestore();
before(async () => { env = await initializeTestEnvironment({ projectId: 'demo-smarttransitzw', firestore: { host: '127.0.0.1', port: 8080, rules: readFileSync('../../firestore.rules', 'utf8') } }); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    for (const [uid, role] of [['operator', 'operator'], ['otheroperator', 'operator'], ['rider', 'commuter'], ['other', 'commuter'], ['admin', 'admin']]) {
      await setDoc(doc(db, 'users', uid), { email: `${uid}@example.test`, role, company: role === 'operator' ? 'Test operator' : '' });
    }
    await setDoc(doc(db, 'routes', 'a'), service());
  });
});
after(async () => env?.cleanup());
function board(db, uid) {
  return runTransaction(db, async tx => {
    const route = doc(db, 'routes', 'a');
    const journey = doc(db, 'journeys', uid);
    const r = (await tx.get(route)).data();
    await tx.get(journey);
    if (r.onboard >= r.capacity) throw new Error('Full');
    tx.update(route, { onboard: r.onboard + 1 });
    tx.set(journey, { routeId: 'a', routeName: r.name, fare: r.fare, boardedAt: serverTimestamp() });
  });
}
test('authentication and profile roles cannot be bypassed', async () => {
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'routes', 'a')));
  await assertFails(setDoc(doc(as('new'), 'users', 'new'), { email: 'new@example.test', role: 'admin', company: '' }));
  await assertSucceeds(setDoc(doc(as('new'), 'users', 'new'), { email: 'new@example.test', role: 'commuter', company: '' }));
  await assertFails(updateDoc(doc(as('rider'), 'users', 'rider'), { role: 'admin' }));
  await assertFails(getDoc(doc(as('other'), 'users', 'rider')));
});
test('only the owning operator can create and edit valid services', async () => {
  await assertSucceeds(setDoc(doc(as('operator'), 'routes', 'b'), service()));
  await assertFails(setDoc(doc(as('rider'), 'routes', 'c'), { ...service(), ownerId: 'rider' }));
  await assertFails(updateDoc(doc(as('otheroperator'), 'routes', 'a'), { fare: 2, updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(as('operator'), 'routes', 'a'), { fare: 2, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(as('operator'), 'routes', 'a'), { fare: -1, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(as('operator'), 'routes', 'a'), { onboard: 1, updatedAt: serverTimestamp() }));
});
test('boarding requires atomic private journey and count updates', async () => {
  const db = as('rider');
  await assertFails(updateDoc(doc(db, 'routes', 'a'), { onboard: 1 }));
  await assertFails(setDoc(doc(db, 'journeys', 'rider'), { routeId: 'a', routeName: 'CBD to Mbare', fare: 1, boardedAt: serverTimestamp() }));
  await assertSucceeds(board(db, 'rider'));
  await assertFails(getDoc(doc(as('other'), 'journeys', 'rider')));
  await assertFails(updateDoc(doc(as('operator'), 'routes', 'a'), { archived: true, status: 'off', updatedAt: serverTimestamp() }));
  const batch = writeBatch(db);
  batch.update(doc(db, 'routes', 'a'), { onboard: 0 });
  batch.delete(doc(db, 'journeys', 'rider'));
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(doc(db, 'routes', 'a'))).data().onboard, 0);
});
test('competing transactions cannot sell the last seat twice', async () => {
  const results = await Promise.allSettled([board(as('rider'), 'rider'), board(as('other'), 'other')]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal((await getDoc(doc(as('rider'), 'routes', 'a'))).data().onboard, 1);
});
test('reports stay private and only admins can resolve them', async () => {
  const report = { routeId: 'a', routeName: 'CBD to Mbare', userId: 'rider', issue: 'Overcharging', details: '', status: 'open', timestamp: serverTimestamp() };
  await assertSucceeds(setDoc(doc(as('rider'), 'reports', 'r'), report));
  await assertFails(getDoc(doc(as('other'), 'reports', 'r')));
  await assertFails(getDoc(doc(as('operator'), 'reports', 'r')));
  await assertFails(getDocs(collection(as('rider'), 'reports')));
  await assertSucceeds(getDocs(query(collection(as('rider'), 'reports'), where('userId', '==', 'rider'))));
  await assertSucceeds(getDocs(collection(as('admin'), 'reports')));
  await assertFails(updateDoc(doc(as('rider'), 'reports', 'r'), { status: 'resolved', resolvedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(as('admin'), 'reports', 'r'), { status: 'resolved', resolvedAt: serverTimestamp() }));
});
test('saved routes are private to the account', async () => {
  await assertSucceeds(setDoc(doc(as('rider'), 'users', 'rider', 'saved', 'a'), { createdAt: serverTimestamp() }));
  await assertFails(getDocs(collection(as('other'), 'users', 'rider', 'saved')));
});

test('legacy services cannot board until occupancy is reconciled', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const data = service(); delete data.onboard;
    await setDoc(doc(context.firestore(), 'routes', 'a'), data);
  });
  const db = as('rider'); const batch = writeBatch(db);
  batch.update(doc(db, 'routes', 'a'), {onboard: 1});
  batch.set(doc(db, 'journeys', 'rider'), {routeId: 'a', routeName: 'CBD to Mbare', fare: 1, boardedAt: serverTimestamp()});
  await assertFails(batch.commit());
});
