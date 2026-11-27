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
    "BACKPACK_CONTAINER",
    "C_AddOns",
    "C_Container",
    "C_Item",
    "COPPER_AMOUNT",
    "CreateFrame",
    "GetLootSourceInfo",
    "GetMoneyString",
    "GetNumLootItems",
    "GetRealmName",
    "GetTime",
    "GOLD_AMOUNT",
    "hooksecurefunc",
    "issecretvalue",
    "ItemLocation",
    "LOOT_ITEM_SELF",
    "LOOT_ITEM_SELF_MULTIPLE",
    "LOOT_MONEY_SPLIT",
    "NUM_TOTAL_EQUIPPED_BAG_SLOTS",
    "SILVER_AMOUNT",
    "time",
    "UnitName",
    "YOU_LOOT_MONEY",
    SlashCmdList = { fields = { KEZAN = { read_only = false } } },
  },
}

-- In-game layer: every file outside Core/ and spec/.
std = "lua51+wow"
-- .lua/, .luarocks/ and .install/ are where the CI actions install Lua and the rocks.
exclude_files = { ".release/", ".claude/", "lua_modules/", ".lua/", ".luarocks/", ".install/" }
-- A method that ignores its implicit self is normal.
self = false

-- Session core: plain Lua 5.1 that also loads in the client unchanged, so
-- no WoW global and none of the standard libraries the client lacks.
files["Core/"] = {
  std = "lua51",
  not_globals = { "debug", "dofile", "io", "loadfile", "module", "os", "package", "require" },
}

files["spec/"] = { std = "lua51+busted" }
