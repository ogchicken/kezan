# Pull requests

Merge pull requests with a merge commit (`gh pr merge <number> --merge`),
never a squash merge, so each branch's commits stay in `main`'s history.

Open a pull request as a draft (`gh pr create --draft`) while more work is
still coming, such as tickets that will merge into its branch. Once the work
is complete, run `gh pr ready <number>`.

There is no CI yet; the addon runs only inside the game client. Until a lint
or test workflow exists, a pull request that changes Lua or the TOC states
what was checked in game, on which build, and that no Lua error appeared
with `/console scriptErrors 1`. Once CI exists, merge only after
`gh pr checks <number> --watch` reports every check passing.

If `main` gained commits after the pull request's last check, merge `main`
into the branch and push before merging.

A pull request changes the README only when setup, the docs map or the
status paragraph changes.
