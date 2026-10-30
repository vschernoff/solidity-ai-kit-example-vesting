<!-- solidity-ai-kit:start -->
## Solidity workflow

Tools installed by solidity-ai-kit: `solhint` (lint), `forge-test` (build-test).

1. After changing Solidity, build and run the relevant tests with the `build` and `run_tests` tools of the `forge-test` MCP server; use `forge build` or `forge test` in a shell only when the tool cannot run. Fix failures first.
2. When a test tool reports an error, the tests did not run: fix the cause and run them again. Never report that as passing, even if it shows 0 failed.
3. Then lint with the `solhint` MCP server. Use its fix tools for auto-fixable findings.
4. Repeat until tests pass and lint shows no errors. Stop after 5 rounds and report what remains.
5. Never make a check pass by weakening it: no comments that switch lint rules off, no skipped or deleted tests, no lowered fuzz runs, no loosened configs, unless the user agrees.
6. For contracts that hold value, write fuzz or invariant tests.
7. Passing tests and a clean lint do not prove a contract is secure. Say so when reporting, and recommend an independent audit before value is deployed.
8. Never send transactions, deploy, or handle private keys. Leave that to the user.

This block is rewritten by `solidity-ai-kit init`; edit outside it.
<!-- solidity-ai-kit:end -->
