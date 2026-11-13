# Daily target, wallet and balance correction

## Try it

1. Run `flutter run` on Android and sign in. Connect once so all financial
   history is cached on this phone.
2. On Home, select **Set daily target**, enter `500`, then save. You should see
   today's expenses against Rs. 500, rather than the old fixed monthly budget.
3. Add an expense. Below 70% the bar is green; from 70% it is amber; from 100%
   it is red. Above the target it shows **Over by Rs. X**.
4. On a later calendar day, Home offers to close previous days, oldest first.
   Select Yes to save leftover money or use the savings wallet. Select No to
   leave the wallet unchanged. Closing a day is permanent.
5. Use **Closed days** to see the saved results, including uncovered overspend
   and month-end outstanding amounts.
6. Select **Correct my balance**, enter bank funds and cash separately, and
   review before confirming. If recorded funds are Rs. 10,000 and your actual
   total is Rs. 9,000, the app adds a Rs. 1,000 **Unrecorded expense** today.
   A higher actual total adds **Balance adjustment income**. A matching total
   creates no transaction.

The wallet is a savings allocation within bank + cash, not another source of
income. Its deposits and withdrawals do not create income or expense entries.
A balance correction does not change closed days. An unrecorded expense counts
toward today's daily limit; an income correction does not.

## Add to the wallet and fund a goal

1. Record income or correct your bank + cash balance first, if needed.
2. On Home, tap **Add to wallet**, enter an amount and confirm. The available
   amount excludes money already reserved in the wallet and goals. Bank + cash
   stays unchanged; this action only sets money aside.
3. Create a goal using **Goals → New goal**.
4. Tap **Transfer to goal** on Home and choose the goal, or use **Add from
   wallet** on a goal card. Enter no more than the wallet balance and the amount
   still needed for the goal.
5. The wallet decreases and goal savings increase by the same amount. For
   example, a Rs. 1,000 wallet followed by a Rs. 400 transfer leaves Rs. 600 in
   the wallet and adds Rs. 400 to the goal. No income or expense is created.

Manual top-ups and goal transfers queue offline after the complete history
has been loaded. Upgrading to this version requires one initial connection to
cache goal funding history too. New goals also queue locally without waiting
for the server. The pending-sync message and error handling apply to these
actions just as they do to daily settlements.

Each top-up has a unique `topup-...` wallet entry ID. A goal transfer uses the
same unique `goal-...` ID for an immutable wallet withdrawal and an immutable
`users/{uid}/goal_contributions/{id}` document. Both documents are written in
one batch and the rules require them to match. Identical retries do not add a
second contribution. Goal savings equal the legacy `saved` amount plus linked
contributions; the old `saved` field is preserved rather than incremented.
Existing daily wallet entries keep their date IDs and schema.

## How overspend works

All calculations use integer cents. Rs. 500 is 50,000 cents. Uncovered overspend
is divided across the remaining calendar days of that month. Any rounding cents
are assigned to the earliest days (100 cents over three days is 34, 33, 33).
Each day's reduction pays down the outstanding amount once.

The adjusted limit never goes below zero. Any debt too large to absorb remains
visible in history. It does not reduce next month's limits. Wallet savings do
carry into the next month.

Today's result is provisional while earlier days still need review. Review
those days before changing the base target; changes then apply to today and
future days without rewriting closed history. Days before setup are excluded.

## Offline behavior

- Android Firestore persistence is enabled with no cache size eviction limit.
- A new phone must complete one online history load before settling days or
  changing its target. A persisted per-user marker records that initial load.
- After that load, transactions, daily target edits and settlement batches
  queue locally. The UI never waits for a server acknowledgement.
- Home distinguishes local pending changes from synced data. Rejected writes
  surface an error, and Firestore rolls back their local documents.
- Settlement and wallet entry use the same stable date ID and one atomic
  batch. Rules allow identical retries, but deny editing/deleting closed days
  or adding unrelated wallet entries.
- One phone per account is assumed for offline financial actions. Independent
  offline withdrawals on two phones cannot enforce a shared wallet balance
  without online coordination. No Cloud Functions are used.

Each day is reviewed only after it ends. Reopening Home or resuming the app
refreshes the plan; a timer also checks for midnight. If review is dismissed,
the Home review button remains available without answering on the user's behalf.

## Code structure

- `models/`: daily target, immutable settlement, wallet entry, goal, contribution and ledger.
- `daily_budget_calculator.dart`: arithmetic, no Firebase or system clock.
- `daily_budget_planner.dart`: replay history and find unresolved days.
- `balance_reconciliation.dart`: bank + cash adjustment calculation.
- `savings_transfer_calculator.dart`: available funds and wallet/goal allocation checks.
- `budget_firestore_codec.dart`: Firestore map conversion and validation.
- `budget_repository.dart`: cached reads and atomic queued writes.
- `budget_controller.dart`: state, day changes, action ordering and write errors.
- `widgets/home/`: progress bar, daily card, wallet and the small input/review sheets.
- `widgets/goals/`: goal cards, creation and goal list; screens remain thin.

Firestore stores `dailyLimit` in rupees and `dailyLimitStartDate` as `yyyy-MM-dd`
in `users/{uid}`. Settlements live in `daily_settlements/{day}` and wallet changes
in `wallet_entries/{day}` below that user. Settlement documents include the
requested rupee fields plus exact `amountsMinor` integers for rules validation;
wallet entries similarly include `amount` and `amountMinor`.

## Checks

```sh
flutter analyze
flutter test
flutter build apk --debug
```

`flutter analyze` currently reports an existing unused `_currentPage` field in
the onboarding screen. The budget feature has no analysis warnings.

The tested rules API checks need Node, PowerShell and a signed-in Firebase CLI.
All document lookups are mocked; they do not read or write user documents:

```powershell
firebase projects:list
./tool/test_budget_rules.ps1
```

There are also optional Firestore emulator integration tests. To run them,
install Node dependencies:

```sh
npm install --prefix .dart_tool/budget_rules --legacy-peer-deps @firebase/rules-unit-testing firebase
```

Start a Firestore emulator on `127.0.0.1:8787` with project
`demo-expenz-budget`, then run:

```sh
node test/firestore_budget_rules_test.cjs
```

The emulator tests use only the demo project and include local offline snapshots
and later sync. They were not run in this environment because the emulator
download stalled. The mocked rules checks and Flutter controller/widget tests
were run successfully.
