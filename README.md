# solidity-ai-kit example: token vesting

A small token vesting contract written by an AI coding agent, in a Foundry project set up with
[solidity-ai-kit](https://github.com/vschernoff/solidity-ai-kit) 0.1.2. It shows what the kit
sets up and what one agent run produced. It is example code, not a contract to deploy.

**Before you use any of it:** passing tests and a clean lint are not a security review or an
audit. Nobody has audited this contract, and no person has reviewed it line by line. See
[What was not checked](#what-was-not-checked).

## How it was made

Each step is its own commit, so `git log` shows the order:

1. `forge init`, with the sample Counter removed.
2. `npx solidity-ai-kit@0.1.2 init --write`. It wrote `.mcp.json`, `.cursor/mcp.json`,
   `.codex/config.toml`, and the workflow rules in `CLAUDE.md` and `AGENTS.md`. The servers
   are solhint-mcp 0.1.7 (lint) and forge-test-mcp 0.1.0 (build and test).
3. The prompt, [`agent-run/PROMPT.md`](agent-run/PROMPT.md): a linear vesting contract with a
   cliff and a public `release()`, no owner, forge-std only, unit and fuzz tests, and a final
   report with a "Still open" list.
4. One non-interactive Claude Code run (CLI 2.1.310, `claude -p`, 22 turns). It was allowed to
   edit files, run `forge build`, `forge test` and `forge fmt`, and use the kit's MCP servers.
   Nothing else. The code it left is committed unchanged.
5. Its final message, unedited: [`agent-run/FINAL-REPORT.md`](agent-run/FINAL-REPORT.md),
   with the "Still open" part also in [`agent-run/STILL-OPEN.md`](agent-run/STILL-OPEN.md).

The run's transcript is not published; it contains local paths. What it shows:

- **Tools used:** `build` and `run_tests` of forge-test-mcp (twice each) and `lint_file` of
  solhint-mcp (six times). Those were the only MCP tools the agent called. The same Claude Code
  install also had other plugins and MCP servers, including a separate Solhint plugin; the
  agent did not use them.
- **Tests:** 23 passed, 0 failed, 0 skipped, with 256 fuzz runs per fuzz test and FFI off.
- **Lint:** the first pass found 1 error in each of the three files. The agent changed the code
  and linted again: 0 errors, with 4 warnings in the contract, 2 in the mock token and 60 in
  the test file. It explains each kind in its report and left them. It did not switch rules off
  or add a Solhint config.
- **Build:** one compiler warning was not in the agent's report: the test contract
  (`test/TokenVesting.t.sol`) is larger than the 24,576-byte deploy limit. This doesn't affect
  `src/`, but the report should have mentioned it.

After the run, `forge test` was run again outside the agent (forge 1.8.5): 23 passed, 0 failed.

## What was not checked

- No audit, and no review by a person. The agent's own "Still open" list names token behaviour
  (fee-on-transfer, rebasing, tokens that don't return a bool), re-entrancy through token
  callbacks, and rounding. Those are its notes, not findings someone confirmed.
- No invariant tests, formal verification, gas review, or static analysis beyond Solhint.
- Not deployed anywhere, and no test against a real token.
- One run with one client. Codex and Cursor were configured by the kit, but not run.

## Run it yourself

```sh
git clone --recurse-submodules <this repository>
forge test
```

To repeat the agent step, open the project in your coding agent and give it the prompt in
`agent-run/PROMPT.md`. Results will differ from run to run.

## Licence

The Solidity files carry `SPDX-License-Identifier: MIT`. forge-std is in `lib/` as a git
submodule under its own licence.
