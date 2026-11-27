# Issue tracker: GitHub

Issues and specs live in GitHub Issues for `ogchicken/kezan`.
Use the `gh` CLI from this checkout; it infers the repository from origin.

## Operations

- Create: `gh issue create --title "..." --body-file <path>`.
  Write multiline bodies to a UTF-8 file first.
- Read: `gh issue view <number> --json number,title,body,labels,comments`.
- List: `gh issue list --state open`, with appropriate label filters.
- Comment: `gh issue comment <number> --body-file <path>`.
- Label: `gh issue edit <number> --add-label "..."` or `--remove-label "..."`.
- Close: `gh issue close <number> --comment "..."`.

When a skill says "publish to the issue tracker", create a GitHub issue.
When it says "fetch the relevant ticket", read the GitHub issue.

## Specs and their tickets

A spec is written from one milestone of `docs/PROJECT_PLAN.md` (section 5).
Each ticket names the plan sections it needs under its Parent line, e.g.
`Plan sections: 3; 4`, and takes its acceptance line from the milestone table.
A ticket that depends on an open question in plan section 6 says which one,
and is blocked until that question has an in-game answer.

## Issues from players

The repository is public, so players may open issues. New outside issues get
`needs-triage`. A bug report needs the Kezan version, the game build and
the Lua error text (with BugSack or `/console scriptErrors 1`); ask for
what is missing and label `needs-info`.

## Pull requests as a triage surface

**PRs as a request surface: no.**

## Wayfinding

A map is an issue labelled `wayfinder:map`. Link child tickets as GitHub
sub-issues, with `wayfinder:research`, `wayfinder:prototype`,
`wayfinder:grilling`, or `wayfinder:task` labels as appropriate.
Create these labels when first needed.

Use native GitHub issue dependencies for blockers. If unavailable, put
`Blocked by: #<number>` in the child body. If sub-issues are unavailable,
use a task list in the map and `Part of #<map>` in each child.

Choose the first open, unassigned child in map order with no open blockers.
Claim it by assigning yourself. Record its result before closing it and
link the result from the map's Decisions-so-far.
