// Run against a local demo-project emulator; never against production.
// Dependencies are isolated under .dart_tool/budget_rules (see docs).
const { createRequire } = require('node:module');
const path = require('node:path');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const load = createRequire(path.resolve('.dart_tool/budget_rules/package.json'));
const { initializeTestEnvironment, assertSucceeds, assertFails } = load('@firebase/rules-unit-testing');
const { doc, collection, setDoc, getDoc, getDocs, deleteDoc, writeBatch,
  disableNetwork, enableNetwork, onSnapshot, setLogLevel } = load('firebase/firestore');
setLogLevel('silent');

const { settlement } = require('./support/budget_rules_fixture.cjs');

function batchFor(db, value, { includeWallet = true, walletOverride = {} } = {}) {
  const batch = writeBatch(db);
  batch.set(doc(db, `users/alice/daily_settlements/${value.date}`), value);
  if (includeWallet && value.walletChange !== 0) {
    batch.set(doc(db, `users/alice/wallet_entries/${value.date}`), {
      amount: Math.abs(value.walletChange), amountMinor: Math.abs(value.amountsMinor.walletChange),
      type: value.walletChange > 0 ? 'deposit' : 'withdraw',
      date: value.date, relatedDay: value.date, ...walletOverride,
    });
  }
  return batch;
}

async function main() {
  const env = await initializeTestEnvironment({
    projectId: 'demo-expenz-budget',
    firestore: { host: '127.0.0.1', port: 8787, rules: fs.readFileSync('firestore.rules', 'utf8') },
  });
  let count = 0;
  async function test(name, run) { await run(); count++; process.stdout.write(`PASS ${name}\n`); }
  try {
    await env.clearFirestore();
    const alice = env.authenticatedContext('alice').firestore();
    const bob = env.authenticatedContext('bob').firestore();
    const guest = env.unauthenticatedContext().firestore();
    const settings = doc(alice, 'users/alice');
    await test('owner can create and update daily limit', async () => {
      await assertSucceeds(setDoc(settings, { dailyLimit: 500, dailyLimitStartDate: '2026-04-01' }));
      await assertSucceeds(setDoc(settings, { dailyLimit: 0 }, { merge: true }));
      await assertSucceeds(setDoc(settings, { dailyLimit: 500 }, { merge: true }));
    });
    await test('other users and guests cannot access settings or history', async () => {
      await assertFails(getDoc(doc(bob, 'users/alice')));
      await assertFails(getDoc(doc(guest, 'users/alice')));
      await assertFails(getDocs(collection(bob, 'users/alice/daily_settlements')));
      await assertFails(getDocs(collection(guest, 'users/alice/wallet_entries')));
      await assertFails(setDoc(doc(bob, 'users/alice'), { dailyLimit: 1 }, { merge: true }));
    });
    await test('invalid limits, start-date edits, extra fields and deletes are denied', async () => {
      await assertFails(setDoc(settings, { dailyLimit: -1 }, { merge: true }));
      await assertFails(setDoc(settings, { dailyLimit: '500' }, { merge: true }));
      await assertFails(setDoc(settings, { dailyLimitStartDate: '2026-03-01' }, { merge: true }));
      await assertFails(setDoc(settings, { admin: true }, { merge: true }));
      await assertFails(deleteDoc(settings));
    });
    const saved = settlement('2026-04-01', 30000, 20000, 'savedToWallet');
    await test('savings settlement and wallet deposit commit together', async () => {
      await assertSucceeds(batchFor(alice, saved).commit());
      assert.equal((await getDoc(doc(alice, 'users/alice/wallet_entries/2026-04-01'))).data().amount, 200);
    });
    await test('identical batch retries do not create duplicate wallet entries', async () => {
      await assertSucceeds(batchFor(alice, saved).commit());
      assert.equal((await getDocs(collection(alice, 'users/alice/wallet_entries'))).size, 1);
    });
    await test('closed days and wallet entries cannot be edited or deleted', async () => {
      await assertFails(setDoc(doc(alice, 'users/alice/daily_settlements/2026-04-01'),
        { ...saved, spent: 1 }));
      await assertFails(deleteDoc(doc(alice, 'users/alice/daily_settlements/2026-04-01')));
      await assertFails(setDoc(doc(alice, 'users/alice/wallet_entries/2026-04-01'), { amount: 999 }));
      await assertFails(deleteDoc(doc(alice, 'users/alice/wallet_entries/2026-04-01')));
    });
    await test('wallet changes require the matching settlement and exact amount', async () => {
      const value = settlement('2026-04-02', 30000, 20000, 'savedToWallet');
      await assertFails(batchFor(alice, value, { includeWallet: false }).commit());
      await assertFails(batchFor(alice, value, { walletOverride: { amount: 300, amountMinor: 30000 } }).commit());
      await assertFails(setDoc(doc(alice, 'users/alice/wallet_entries/2026-04-02'), {
        amount: 200, amountMinor: 20000, type: 'deposit', date: '2026-04-02', relatedDay: '2026-04-02',
      }));
    });
    await test('partial coverage and uncovered carry are accepted', async () => {
      await assertSucceeds(batchFor(alice, settlement('2026-04-02', 75000, -20000, 'coveredByWallet')).commit());
      await assertSucceeds(batchFor(alice, settlement('2026-04-03', 60000, 0, 'carriedForward')).commit());
    });
    await test('fractional rupee amounts compare exactly using integer cents', async () => {
      await assertSucceeds(batchFor(alice,
        settlement('2026-04-04', 30000, 19310, 'savedToWallet', 690, 20000)).commit());
    });
    await test('inconsistent money and actions are denied', async () => {
      await assertFails(batchFor(alice, { ...settlement('2026-04-05', 30000, 20000, 'savedToWallet'), leftover: 999 }).commit());
      await assertFails(batchFor(alice, settlement('2026-04-05', 70000, 10000, 'savedToWallet')).commit());
      await assertFails(batchFor(alice, settlement('2026-03-31', 30000, 20000, 'savedToWallet')).commit());
    });
    await test('offline batch is visible locally before acknowledgement and syncs later', async () => {
      await disableNetwork(alice);
      const ref = doc(alice, 'users/alice/daily_settlements/2026-04-06');
      let unsubscribe;
      const local = new Promise((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('No local offline snapshot')), 10000);
        unsubscribe = onSnapshot(ref, { includeMetadataChanges: true }, (snapshot) => {
          if (snapshot.exists() && snapshot.metadata.hasPendingWrites) {
            clearTimeout(timeout); resolve();
          }
        }, reject);
      });
      const commit = batchFor(alice, settlement('2026-04-06', 40000, 10000, 'savedToWallet')).commit();
      await local;
      unsubscribe();
      await enableNetwork(alice);
      await assertSucceeds(commit);
    });
    process.stdout.write(`${count} Firestore rule tests passed.\n`);
  } finally { await env.cleanup(); }
}
module.exports = { settlement };
if (require.main === module) {
  main().catch((error) => { console.error(error); process.exitCode = 1; });
}
