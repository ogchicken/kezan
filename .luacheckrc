-- luacheck configuration. Run from the repository root: `luacheck .`

-- The WoW globals the in-game layer may use. Add one here when an
-- in-game file needs it; a session-core file never may (ADR 0003).
stds.wow = {
  globals = {
    "Kezan",
    "KezanDB",
    "SLASH_KEZAN1",
    "SLASH_KEZAN2",
  },
  read_globals = {
    "C_AddOns",
    "CreateFrame",
    SlashCmdList = { fields = { KEZAN = { read_only = false } } },
  },
}

-- In-game layer: every file outside Core/ and spec/.
std = "lua51+wow"
exclude_files = { ".release/", ".claude/", "lua_modules/" }
-- A method that ignores its implicit self is normal.
self = false

-- Session core: plain Lua 5.1 that also loads in the client unchanged, so
-- no WoW global and none of the standard libraries the client lacks.
files["Core/"] = {
  std = "lua51",
  not_globals = { "debug", "dofile", "io", "loadfile", "module", "os", "package", "require" },
}

files["spec/"] = { std = "lua51+busted" }
