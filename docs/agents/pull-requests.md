# Pull requests

Merge pull requests with a merge commit (`gh pr merge <number> --merge`),
never a squash merge, so each branch's commits stay in `main`'s history.

Open a pull request as a draft (`gh pr create --draft`) while more work is
still coming, such as tickets that will merge into its branch. Once the work
is complete, run `gh pr ready <number>`.

CI (`.github/workflows/ci.yml`) runs luacheck and busted on every pull
request. Merge only after `gh pr checks <number> --watch` reports every
check passing. A pull request that changes the in-game layer, the UI or the
TOC also states what was checked in game, on which build, and that no Lua
error appeared with `/console scriptErrors 1`.

During milestone 1, in-game checks are deferred (AGENTS.md): instead of
stating what was checked in game, the pull request lists its ticket's
in-game checks under "In game: pending (#16)", and merges on its
automated checks.

If `main` gained commits after the pull request's last check, merge `main`
into the branch and push before merging.

A pull request changes the README only when setup, the docs map or the
status paragraph changes.
