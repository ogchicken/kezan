-- Stopped sessions: what the history keeps of each, and the summary shown
-- of it. Internal to the session core; only the tracker calls it.
--
-- A stored session, one entry of KezanDB.history, is plain data frozen at
-- stop; nothing changes it afterwards:
-- {
--   character = "Name-Realm", startZone = <name or nil>,
--   startedAt = <s>, stoppedAt = <s>, activeTime = <s>,
--   rawGold = <copper>, lootedItemValue = <copper>, total = <copper>,
--   gph = <copper>, unreadableLines = <n>,
--   items = { [itemLink] = { quantity, itemValue, pricing } },
-- }

local _, ns = ...

local Summary = {}

-- How many items the summary lists.
local TOP_ITEMS = 10

-- The session's items, at most TOP_ITEMS, most valuable first. Each is
-- { link, quantity, itemValue, value, pricing }, value being quantity
-- times item value. Items of equal value keep a fixed order, by link.
function Summary.topItems(items)
  local list = {}
  for link, entry in pairs(items) do
    table.insert(list, {
      link = link,
      quantity = entry.quantity,
      itemValue = entry.itemValue,
      value = entry.quantity * entry.itemValue,
      pricing = entry.pricing,
    })
  end
  table.sort(list, function(a, b)
    if a.value ~= b.value then
      return a.value > b.value
    end
    return a.link < b.link
  end)
  for index = #list, TOP_ITEMS + 1, -1 do
    list[index] = nil
  end
  return list
end

-- The fields a stored session copies from the stopped session's figures.
local FIGURES = { "activeTime", "rawGold", "lootedItemValue", "total", "gph", "unreadableLines" }

local function copyItems(items)
  local copy = {}
  for link, entry in pairs(items or {}) do
    copy[link] = { quantity = entry.quantity, itemValue = entry.itemValue, pricing = entry.pricing }
  end
  return copy
end

-- What the history keeps of a session stopped at `now`, given its final
-- figures. Its items are copies, so they no longer follow prices.
function Summary.stored(session, figures, character, now)
  local stored = {
    character = character,
    startZone = session.startZone,
    startedAt = session.startedAt,
    stoppedAt = now,
    items = copyItems(session.items),
  }
  for _, key in ipairs(FIGURES) do
    stored[key] = figures[key]
  end
  return stored
end

-- The summary of a stored session: its fields, with copies of its items,
-- and `topItems` (see Summary.topItems).
function Summary.of(stored)
  local summary = {}
  for key, value in pairs(stored) do
    summary[key] = value
  end
  summary.items = copyItems(stored.items)
  summary.topItems = Summary.topItems(stored.items)
  return summary
end

ns.Summary = Summary
