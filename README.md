# Kezan

An open-source gold-making addon for World of Warcraft: Forever. The first module tracks a farming session: raw gold looted, the auction value of looted items, and gold per hour. Item values come from Auctionator or TradeSkillMaster when either is installed, with the vendor price as the fallback. More gold-making tools follow once the tracker works.

Kezan is named after the goblin homeland, seat of the trade cartels.

## Status

The addon skeleton loads a slash command. The session core has its tracker and test seam, but no tracking rules yet. The research behind the name and the target platform is in [research/](research/). The first milestone is in [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md).

## Start here

1. Link this checkout into the game's AddOns folder (below) and confirm the addon loads in the Forever client: `/kezan` prints the version. This settles the Interface number (16001) on the live client.
2. In game, confirm that `CHAT_MSG_LOOT`, `CHAT_MSG_MONEY` and `GetMoney()` return readable values for addons on Forever (plan section 3). The whole tracker depends on them.
3. Work through milestone 1 in plan section 5.

## Install for development

The repository root is the addon folder. Link it into the Forever AddOns folder under the name `Kezan` with a junction, adjusting the game path (a junction needs no elevated shell):

```powershell
New-Item -ItemType Junction -Path "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\Kezan" -Target "$HOME\Desktop\Code\kezan"
```

The junction is the project folder itself, not a copy, so a saved edit is in the game folder at once. The client reads files only when it loads them:

- Type `/reload` in game after editing a Lua file. If a TOC change, such as a new file or saved variable, does not show after `/reload`, restart the client.
- The client loads whichever branch is checked out. Type `/reload` after switching branches.
- `KezanDB` lives outside the repository, in `_forever_\WTF\Account\<account>\SavedVariables\Kezan.lua`. The client writes it on `/reload` and on logout, overwriting any edit made while the game runs.

To remove the link, run `cmd /c rmdir "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\Kezan"`, which deletes only the junction. Never run `Remove-Item -Recurse` on it: Windows PowerShell 5.1 follows the junction and deletes the project's files.

## Tests and lint

The session core (`Core/`) is plain Lua 5.1 that runs outside the game ([ADR 0003](docs/adr/0003-session-logic-is-plain-lua-tested-with-busted.md)). busted runs its tests in `spec/`, and luacheck lints every file; a session-core file that reads a WoW global fails the lint. CI runs both on every pull request.

Run both from the repository root:

```powershell
luacheck .
busted
```

In Git Bash, type `luacheck.bat .` and `busted.bat`.

### Install on Windows

These steps install Lua 5.1, LuaRocks, busted and luacheck for the current user, with no administrator rights. They need Python 3 and winget. busted and luacheck pull in C modules, so LuaRocks needs a C compiler; the steps use MinGW-w64 GCC from WinLibs. Run them in PowerShell:

```powershell
# 1. A C compiler, and hererocks to build Lua 5.1.
winget install --id BrechtSanders.WinLibs.POSIX.UCRT -e --scope user
python -m pip install --user hererocks

# 2. Lua 5.1, built with that compiler, in a folder of its own.
$L = "$env:LOCALAPPDATA\lua51"
$env:PATH = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin;$env:PATH"
python -m hererocks $L --lua 5.1 --target mingw

# 3. LuaRocks, as its standalone Windows executable.
Invoke-WebRequest https://luarocks.github.io/luarocks/releases/luarocks-3.11.1-windows-64.zip -OutFile "$env:TEMP\luarocks.zip"
Expand-Archive "$env:TEMP\luarocks.zip" "$env:TEMP\luarocks" -Force
Copy-Item "$env:TEMP\luarocks\luarocks-3.11.1-windows-64\luarocks.exe" "$L\bin"

# 4. busted and luacheck.
& "$L\bin\luarocks.exe" --lua-version 5.1 --lua-dir $L --tree $L install busted
& "$L\bin\luarocks.exe" --lua-version 5.1 --lua-dir $L --tree $L install luacheck

# 5. Put them on the user PATH, then open a new terminal.
[Environment]::SetEnvironmentVariable("Path", "$L\bin;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")
```

The compiler is needed only while installing rocks. hererocks can install LuaRocks itself, but its Windows installer step failed under Python 3.13, so step 3 fetches it directly. To undo, remove `$L\bin` from the user PATH, delete the `lua51` folder, and run `winget uninstall BrechtSanders.WinLibs.POSIX.UCRT` and `python -m pip uninstall hererocks`.

## Docs

- [Project plan](docs/PROJECT_PLAN.md): platform facts, scope, price sources, milestones and open questions.
- [Glossary](GLOSSARY.md): the gold-making and WoW terms used in the plan and the code.
- [Architectural decisions](docs/adr/): price addons are optional and called only through their public APIs; the Forever client comes first; session logic is plain Lua tested with busted; a session counts loot when it arrives.
- [Coding standards](CODING_STANDARDS.md): the checks a reviewer makes.
- [Agent instructions](AGENTS.md): repository instructions for coding agents. [CLAUDE.md](CLAUDE.md) imports them. The issue-tracker, triage-label, domain and pull-request conventions are in [docs/agents/](docs/agents/).

## Repository layout

```text
Kezan.toc                addon manifest (Interface 16001); loads Core/ first
Core/                    session core: plain Lua 5.1, no WoW globals
Kezan.lua                in-game layer: addon entry point
spec/                    busted tests of the session core, and their fakes
.luacheckrc              lint rules, including the session core's
.github/workflows/       CI: luacheck and busted on every pull request
AGENTS.md, CLAUDE.md     instructions for coding agents
CODING_STANDARDS.md      review checks
GLOSSARY.md              domain terms
docs/PROJECT_PLAN.md     the plan
docs/adr/                architectural decisions
docs/agents/             issue tracker, triage labels, domain docs, pull requests
research/                research notes behind the plan
```

## Licence

[MIT](LICENSE). Auctionator and TradeSkillMaster are separate addons under their own terms; Kezan calls their public APIs at runtime and contains none of their code.
