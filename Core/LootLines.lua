-- Loot-line reader: turns the client's own loot and coin format strings
-- into patterns, and reads chat lines with them. Internal to the session
-- core; only the tracker calls it.

local _, ns = ...

local LootLines = {}
LootLines.__index = LootLines

local PLACEHOLDER = "\001"

-- Turns a client format string such as "You loot %s" into a Lua pattern.
-- `%s` captures text, `%d` captures digits. The pattern matches the whole
-- line, which may end with or without a full stop whichever form the
-- format string has. `anchored` false leaves it unanchored, for finding
-- one amount inside a longer text.
local function patternFor(format, anchored)
  local marked = format:gsub("%.$", "")
    :gsub("%%%d*%$?([sd])", PLACEHOLDER .. "%1")
  local escaped = marked:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
  local pattern = escaped
    :gsub(PLACEHOLDER .. "s", "(.-)")
    :gsub(PLACEHOLDER .. "d", "(%%d+)")
  if anchored == false then
    return pattern
  end
  return "^" .. pattern .. "%.?$"
end

-- strings: the loot strings port, keyed by the WoW global names.
function LootLines.new(strings)
  local reader = setmetatable({}, LootLines)
  reader.ownCoin = patternFor(strings.YOU_LOOT_MONEY)
  -- The multiple form is tried first: the single form's `(.-)` would take
  -- "[Peacebloom]x3" whole as the link.
  reader.ownItemMultiple = patternFor(strings.LOOT_ITEM_SELF_MULTIPLE)
  reader.ownItem = patternFor(strings.LOOT_ITEM_SELF)
  reader.coinUnits = {
    { pattern = patternFor(strings.GOLD_AMOUNT, false), copper = 10000 },
    { pattern = patternFor(strings.SILVER_AMOUNT, false), copper = 100 },
    { pattern = patternFor(strings.COPPER_AMOUNT, false), copper = 1 },
  }
  return reader
end

-- Reads a money text such as "1 Gold, 2 Silver" into whole copper.
function LootLines:copperIn(moneyText)
  local copper = 0
  for _, unit in ipairs(self.coinUnits) do
    local amount = moneyText:match(unit.pattern)
    if amount then
      copper = copper + tonumber(amount) * unit.copper
    end
  end
  return copper
end

-- Reads a coin line. Returns the copper the player looted, or nil when the
-- line is not the player's own "You loot" line.
function LootLines:ownCoinCopper(text)
  local moneyText = text:match(self.ownCoin)
  if not moneyText then
    return nil
  end
  return self:copperIn(moneyText)
end

-- Reads an item line. Returns the item link and the quantity of the
-- player's own drop, or nil when the line is not a "You receive loot" line.
function LootLines:ownDrop(text)
  local link, quantity = text:match(self.ownItemMultiple)
  if link then
    return link, tonumber(quantity)
  end
  link = text:match(self.ownItem)
  if not link then
    return nil
  end
  return link, 1
end

ns.LootLines = LootLines
