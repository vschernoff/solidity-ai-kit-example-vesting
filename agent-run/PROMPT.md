Build a small token vesting contract in this Foundry project.

- A beneficiary receives a fixed amount of one ERC-20 token, released linearly between a
  start time and an end time, with nothing released before a cliff.
- Anyone can call `release()`; it sends whatever has vested and not yet been released to the
  beneficiary.
- The token, beneficiary, amount, start, cliff and end are set once in the constructor. No
  owner, no admin functions, no upgradeability.
- Use only forge-std; don't add other dependencies. A minimal IERC20 interface and a mock token
  for the tests are fine.
- Put the contract in `src/` and unit and fuzz tests in `test/`.

Follow the workflow in CLAUDE.md. When you are done, end with a short final report: what you
built, what the tests and the linter show, and a "Still open" list of everything that was not
checked or that a reviewer should look at.
