# Profile: finance

For any product that records or moves money: accounting and ledgers, invoicing, payments and refunds, the money side of ERP, e-commerce checkout, POS sales. The rules are about behaviour, not about a language or framework.

A human who knows accounting reads the ACs at GATE 1. This profile catches the common engineering mistakes; it does not replace that person, and it states no tax rate or legal requirement of any country.

## 1. Rules newcomers get wrong

1. **Money is never a binary float.** Store, compute and send amounts as integer minor units or a decimal type. Every amount travels with its currency.
2. **One rounding rule, in one function.** The rule names the mode and the level (per line or per document). When an amount is split, the parts sum exactly to the whole; the remainder goes to a named part.
3. **A posted record is never edited or deleted.** A correction is a new reversing or adjusting record that points at the original.
4. **Every posting balances.** Total debits equal total credits, written in one database transaction, enforced in the posting function or the database, never only in the UI.
5. **Every money-moving operation is idempotent.** Payment, refund, posting and incoming webhook each carry a key; a repeat returns the first result and moves nothing. The same key with different parameters is rejected, never treated as new.
6. **Check and write in the same transaction.** A balance or remaining-amount check followed by a write uses a row lock or a version check. Read, then write later, is a race.
7. **One source of truth for a balance.** It is derived from the entries, or stored with a reconciliation check against them.
8. **A closed period refuses postings.** Document date, posting date and created-at are three fields.
9. **Document numbers are allocated in the posting transaction** and never reused. Whether gaps are allowed is a ruling from the human.
10. **Tax rates, tax rounding and document content come from the human**, with effective dates, as data. They live in `.agent/regulations.md`, each with an official source and the date it was checked. Never hardcode a rate, never use one from memory: a missing or `unverified` row → `NEEDS-PM`.
11. **Every state change of a financial record is in an append-only audit trail**: who, when, what, the value before and after.
12. **Timestamps are stored in UTC; period boundaries use the business date** in the time zone `project.md` names.
13. **A refund or credit never exceeds what remains refundable.** Partial payment and overpayment each have a stated behaviour.
14. **An exchange rate is stored on the transaction** with its source and date, and never recomputed afterwards.
15. **Where approval exists, the approver is not the maker.**
16. **Card numbers and bank credentials stay with the payment provider.** They never reach the database, a log or an error message.
17. **A payment provider's events arrive more than once, out of order, and can be forged.** Verify the signature first, record each event id and skip one already seen, never rely on arrival order, acknowledge quickly and do the work from a queue.

## 2. Required ACs

`sa` writes an AC for each row that applies. A row that does not apply is named in requirements section 6 with the reason, so the human sees the omission at GATE 1.

| class | the AC states |
|---|---|
| repeat | what a double submit or a replayed webhook returns, and that no second movement exists; the same key sent with different parameters |
| provider event | an event with a bad signature; the "paid" event arriving before the "created" one |
| concurrency | two simultaneous operations on one record: which wins, what the other receives |
| limits | zero, negative, over the remaining amount, the largest supported amount |
| rounding | a split that does not divide evenly, with exact expected amounts |
| correction | how a posted record is corrected, and what the original looks like afterwards |
| period | an operation dated in a closed period |
| permission | who may post, approve, refund and reverse; the wrong role and the maker approving their own record |
| audit | which entry appears in the audit trail for each state change |
| failure | the provider or the database fails mid-operation: the state afterwards, and how it is resumed |

## 3. Design must decide

`sa` answers each in design section 1 (as a decision with a rejected option) or section 2:

- the money representation in storage, in code and in the API, and the currency field
- the rounding function: where it lives, mode, level
- the transaction boundary and isolation level of each money-moving operation, and the lock or version check it uses
- where the idempotency key is stored, its scope and how long it is kept
- which constraints the database enforces itself (balance, non-negative, unique document number, foreign keys on entries)
- how a balance is derived, or how a stored one is reconciled
- the audit trail's shape, and what stops it being edited
- how period close is represented

## 4. Tests that must exist

`qa` adds these to the AC tests; a missing one is reported as a gap, not skipped:

- an amount that fails in binary floating point (0.1 + 0.2, a three-way split of 100.00) with exact expected values
- the same request sent twice, and sent twice at the same time: one movement
- two concurrent operations that together exceed the limit: exactly one succeeds
- after every operation in the suite, debits equal credits and each stored balance equals the sum of its entries
- an attempt to edit or delete a posted record through the API, with every role
- a refund over the remaining amount; a posting into a closed period
- a provider event delivered twice, delivered out of order, and delivered with a wrong signature
- a failure injected between the two writes of one operation: nothing is half-written

## 5. Review checks

`tech-lead-review` reports each as a finding, `blocker` unless noted:

- a float or untyped number holding money anywhere in the diff, including tests and API examples
- arithmetic on money outside the rounding function (major)
- a read followed by a write on a balance or remaining amount without a lock or version check
- a money-moving handler with no idempotency key, or one that checks the key outside the transaction
- a webhook handler that acts before verifying the signature, or assumes events arrive once and in order
- an UPDATE or DELETE on posted entries or the audit trail
- several writes of one operation outside one transaction
- a tax rate, currency or account code as a literal in code (major)
- card or bank data in a log line, an error or a test fixture
