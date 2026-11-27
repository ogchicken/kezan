# Session logic is plain Lua tested with busted outside the game

The rules of a session (reading loot lines, the start, pause and stop states, active time, item value and gold per hour) are written as plain Lua 5.1 that touches no WoW global. They are tested with busted and linted with luacheck, locally and in GitHub Actions on every pull request. Everything the game provides (the clock, events, item info, the wallet, Auctionator and saved variables) reaches that logic through thin adapters that run only in the game client. We chose this because the milestone 1 counting and valuation rules are a long list of edge cases (split coin, won rolls, greys, soulbound gear, old and missing prices, reloads), and checking each of them by logging in and farming is slow and unrepeatable. WoW runs Lua 5.1, so the same files load in the client unchanged.

## Considered options

- **No automated tests**, checking everything in game. Rejected: every rule change would need a farming session to check it.
- **An in-game test runner.** Rejected: it still needs the client running, so it cannot run in CI.

## Consequences

- AGENTS.md's "nothing here can be run outside the game client" changes when the toolchain lands: the session logic runs under busted, and a change to an adapter or the UI still states in its pull request what was checked in game and on which build.
- luacheck is configured so that session-logic files fail the lint if they read a WoW global. A rule that needs game data gets it through an adapter.
- Contributors need Lua 5.1, LuaRocks, busted and luacheck installed to run the tests locally.
