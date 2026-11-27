-- In-game layer: the entry point. It builds the tracker from the game's
-- ports once the saved variables are loaded, and gives the other in-game
-- files two registries: ns.on for events and ns.addCommand for /kz.

local addonName, ns = ...

Kezan = ns
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"

local DB_SCHEMA_VERSION = 1

function ns.print(message)
  print("|cffd4af37Kezan|r " .. message)
end

-- Whether a value from the game arrived secret, so it can't be read or
-- compared (research/2026-11-27-loot-and-money-events.md). A client
-- without secret values has none.
function ns.isSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

-- Events. ns.on(event, handler) registers the event on first use and calls
-- each handler with the event's payload. Register only events seen to fire
-- on Forever (CODING_STANDARDS.md).
local eventFrame = CreateFrame("Frame")
local handlers = {}

function ns.on(event, handler)
  if not handlers[event] then
    handlers[event] = {}
    eventFrame:RegisterEvent(event)
  end
  table.insert(handlers[event], handler)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  for _, handler in ipairs(handlers[event]) do
    handler(...)
  end
end)

-- Ports for the session core (ADR 0003).
local clock = {
  -- The wall clock, so that time survives reloads and logouts.
  now = function()
    return time()
  end,
}

local lootStrings = {
  LOOT_ITEM_SELF = LOOT_ITEM_SELF,
  LOOT_ITEM_SELF_MULTIPLE = LOOT_ITEM_SELF_MULTIPLE,
  YOU_LOOT_MONEY = YOU_LOOT_MONEY,
  YOU_LOOT_MONEY_GUILD = YOU_LOOT_MONEY_GUILD,
  LOOT_MONEY_SPLIT = LOOT_MONEY_SPLIT,
  LOOT_MONEY_SPLIT_GUILD = LOOT_MONEY_SPLIT_GUILD,
  GOLD_AMOUNT = GOLD_AMOUNT,
  SILVER_AMOUNT = SILVER_AMOUNT,
  COPPER_AMOUNT = COPPER_AMOUNT,
}

local function characterKey()
  return UnitName("player") .. "-" .. GetRealmName()
end

-- ns.tracker is nil until the saved variables load; handlers check it.
ns.on("ADDON_LOADED", function(loadedName)
  if loadedName ~= addonName then
    return
  end
  KezanDB = KezanDB or { schemaVersion = DB_SCHEMA_VERSION }
  ns.db = KezanDB
  ns.tracker = ns.Tracker.new({
    clock = clock,
    itemFacts = ns.itemFacts, -- ItemFacts.lua, loaded before ADDON_LOADED fires
    -- AuctionatorPrices.lua. Auctionator is an optional dependency, so when
    -- it is enabled it has loaded before Kezan's ADDON_LOADED.
    priceSources = {
      auctionator = ns.auctionatorPrices.isLoaded() and ns.auctionatorPrices or nil,
    },
    lootStrings = lootStrings,
    savedState = KezanDB,
    character = characterKey(),
  })
end)

-- Slash commands. ns.addCommand(name, summary, run) adds `/kz <name>`;
-- run gets the rest of the line. `/kz` alone prints the version and the
-- commands, in the order they were added.
local commands = {}

function ns.addCommand(name, summary, run)
  table.insert(commands, { name = name, summary = summary, run = run })
end

local function printHelp()
  ns.print(ns.version .. ". Commands:")
  for _, command in ipairs(commands) do
    print(("  /kz %s: %s"):format(command.name, command.summary))
  end
end

SLASH_KEZAN1 = "/kezan"
SLASH_KEZAN2 = "/kz"
SlashCmdList.KEZAN = function(message)
  local name, rest = message:match("^%s*(%S*)%s*(.-)%s*$")
  name = name:lower()
  if name == "" then
    printHelp()
    return
  end
  for _, command in ipairs(commands) do
    if command.name == name then
      if ns.tracker then
        command.run(rest)
      end
      return
    end
  end
  ns.print(("Unknown command %q."):format(name))
  printHelp()
end
