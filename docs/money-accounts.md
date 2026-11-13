# Home balances, loans, and credit cards

The home balances are compact horizontally scrolling cards in this order: today's expenses, cash in hand, bank funds, money to receive, money to repay, and credit card debt. Amounts use 18px text, labels use 12px, and cards reflow vertically when system text scaling grows. The bank card opens the bank-only accounts sheet.

## Accounting

- Regular income and expenses change the selected cash/bank account and appear in the usual income/expense totals.
- Lending money decreases cash/bank funds and creates a receivable. Receiving principal back increases funds and reduces that receivable. Neither is income or spending.
- Borrowing money increases cash/bank funds and creates a payable. Repaying principal decreases funds and reduces the payable. Neither is income or spending.
- Recording an existing debt with cash movement switched off only records the outstanding debt. It does not change available funds or today's activity.
- Adding an existing credit card balance records the liability without inventing past spending. A new card can start at zero.
- Adding a card purchase or fee increases its liability and creates one expense transaction with an account ID prefixed by `credit:`. That expense contributes to daily budgets, history, and analytics; it has no cash effect.
- Paying a credit card reduces its liability and the selected cash/bank funds. It does not create a second expense.
- Loan interest/fees should be recorded as ordinary expenses. Card fees can be entered through Add purchase / fee.

Cash/bank account edits account for debt movements when calculating the opening balance; debt balances are never added to liquid funds. Existing transactions without an account still belong to cash.

## Storage and consistency

Accounts live in `users/{uid}/money_accounts`; debts live in `debt_accounts`; immutable debt movements live in `debt_entries`. Debt creation is an atomic batch. Repayments and card charges use a Firestore transaction to recheck the current remaining balance and prevent concurrent overpayment. These actions wait for a connection before reporting success.

The budget repository waits for matching debt amounts, immutable movements, and credit purchase transactions before publishing changes from separate listeners. Owner-only rules validate paired changes, prevent overpayment and deletion of debt history, and protect linked card purchases against separate edits/deletion. Future-dated entries are blocked.

The new rules must be deployed before using these features with a live project. This change does not deploy rules.

## Validation

`test/debts_test.dart` covers cash-flow classification, debts recorded without money movement, credit spending counted once, repayments, amount validation, retry behavior, and scrolling at large text sizes. `test/money_accounts_test.dart` covers bank/cash totals and narrow/landscape layouts. The existing mocked Rules API runner includes debt, repayment, and credit-card permission cases.
