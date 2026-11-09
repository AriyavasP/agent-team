# Project: ledger-lite

A zero-dependency Node.js library for invoices. In-memory store; no server, no UI, no database.

## Stack
- Node.js >= 18, CommonJS (`require`), no dependencies, no build step.
- Tests: `node:test` and `node:assert`, files in `tests/`.

## Common commands
- Test (checkpoint, run after every task): `npm test`
- There is no lint, build or dev server.

## Conventions
- Errors are `Error` objects with a string `code` (`err.code`), made with `codeError` in `src/money.js`. Throw a code; never a bare message.
- Records are kept in `src/store.js`; `get` and `save` return copies. Domain functions live in `src/<noun>.js` and are exported with `module.exports`.
- Every exported function has a test in `tests/<noun>.test.js`.

## Decisions made
- No HTTP layer, no persistence: out of scope for every feature unless the request says so.

## Constraints that must not be broken
- Existing tests keep passing.

## UI / UX
- None. This project has no screens, so no `ux` call is needed (`UI: no`).

## Voice and style
- Plain English, short sentences. Error codes in `UPPER_SNAKE_CASE`.

## Reference work
- None.
