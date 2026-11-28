## Agent skills

### Issue tracker

Track issues and specs in GitHub Issues for `ogchicken/kezan`.
Read `docs/agents/issue-tracker.md` before issue operations.

### Triage labels

Use the five canonical triage labels.
Read `docs/agents/triage-labels.md` before triaging issues.

### Domain docs

Use a single-context layout: root `GLOSSARY.md` and `docs/adr/`.
Read `docs/agents/domain.md` before domain exploration or design.

## Project plan

`docs/PROJECT_PLAN.md` is the specification this repository is built from.
Read the section a task touches before writing a spec, a ticket or code:

- the Forever client, TOC, API and its restrictions: section 3;
- price sources (Auctionator, TradeSkillMaster, vendor): section 4;
- milestones and acceptance criteria: section 5;
- open questions that need an in-game check: section 6.

## Target client

Kezan targets World of Warcraft: Forever (patch 1.60.1, `## Interface: 16001`), which runs the modern Mainline API. Use `C_Container`, `C_Item`, `C_AddOns` and the `Settings` API; the old globals such as `GetItemInfo` and `GetContainerItemInfo` do not exist there. Registering an event the client does not have raises an error, and `COMBAT_LOG_EVENT_UNFILTERED` never fires for addons.

The session core (`Core/`) is plain Lua 5.1 that runs outside the game under busted and is linted by luacheck (ADR 0003). Run `busted` and `luacheck .` before pushing; the README says how to install them. The in-game layer and the UI run only in the client: a change to either states in its pull request what was checked in game and on which build.

### Milestone 1: in-game checks deferred

Agents implement milestone 1 (spec #3) without the owner checking each ticket in game. A pull request for a milestone 1 ticket lists that ticket's in-game checks as pending, and merges once its automated checks pass. The owner runs every deferred check in the verification pass (#16) after the last ticket merges. Never record an in-game result as confirmed unless the owner reports it. This section ends when #16 closes.

## Price addons

Auctionator and TradeSkillMaster are optional dependencies. Call only their public APIs (`Auctionator.API.v1.*`, `TSM_API.*`), check that the addon is loaded first, and never copy their code into this repository: both are All Rights Reserved.
Read `docs/adr/0001-price-addons-are-optional-and-called-through-public-apis.md` before touching pricing.

## Research files

`research/` holds the notes behind the name and the platform facts in the plan. They are dated; prefer a newer in-game check over a research note.

## Coding standards

Read `CODING_STANDARDS.md` before reviewing a change.

## Pull requests

Read `docs/agents/pull-requests.md` before opening, readying or merging a pull request.
