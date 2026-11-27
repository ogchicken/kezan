-- Builds a tracker from the session core with fake ports, the way every
-- tracker test starts (ADR 0003).

local support = {}

-- The enUS values of the client's own loot and coin format strings.
support.enUSLootStrings = {
  LOOT_ITEM_SELF = "You receive loot: %s.",
  LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d.",
  YOU_LOOT_MONEY = "You loot %s",
  LOOT_MONEY_SPLIT = "Your share of the loot is %s.",
  GOLD_AMOUNT = "%d Gold",
  SILVER_AMOUNT = "%d Silver",
  COPPER_AMOUNT = "%d Copper",
}

-- Loads every session-core file listed in Kezan.toc, in TOC order, into a
-- fresh namespace, as the client does with `local addonName, ns = ...`.
function support.loadCore()
  local ns = {}
  for line in io.lines("Kezan.toc") do
    local path = line:gsub("\\", "/"):match("^%s*(Core/%S+%.lua)%s*$")
    if path then
      local chunk = assert(loadfile(path))
      chunk("Kezan", ns)
    end
  end
  return ns
end

-- Clock port: `now()` returns whole seconds. `set(seconds)` moves it.
function support.fakeClock(seconds)
  local clock = {}
  function clock.now()
    return seconds
  end
  function clock.set(newSeconds)
    seconds = newSeconds
  end
  return clock
end

-- Item facts port: `lookup(itemLink)` returns
-- { itemID, quality, soulbound, vendorValue }, or nil while not loaded.
-- `load(itemLink, facts)` makes an item's facts arrive.
function support.fakeItemFacts(factsByLink)
  local known = {}
  for link, facts in pairs(factsByLink or {}) do
    known[link] = facts
  end
  local itemFacts = {}
  function itemFacts.lookup(itemLink)
    return known[itemLink]
  end
  function itemFacts.load(itemLink, facts)
    known[itemLink] = facts
  end
  return itemFacts
end

-- Price source port: `ahValue(itemLink)` returns the AH value in copper or
-- nil, then its age in whole days or nil when unknown.
-- `set(itemLink, copper, ageDays)` changes a price.
function support.fakePriceSource(pricesByLink)
  local prices = {}
  for link, price in pairs(pricesByLink or {}) do
    prices[link] = price
  end
  local priceSource = {}
  function priceSource.ahValue(itemLink)
    local price = prices[itemLink]
    if price then
      return price.copper, price.ageDays
    end
    return nil, nil
  end
  function priceSource.set(itemLink, copper, ageDays)
    prices[itemLink] = { copper = copper, ageDays = ageDays }
  end
  return priceSource
end

-- Builds a tracker. Any port left out of `ports` gets a fake: the clock at
-- 0, no item facts, no prices, the enUS loot strings. Returns the tracker
-- and the ports it was built with.
function support.newTracker(ports)
  ports = ports or {}
  local ns = support.loadCore()
  local built = {
    clock = ports.clock or support.fakeClock(0),
    itemFacts = ports.itemFacts or support.fakeItemFacts(),
    priceSource = ports.priceSource or support.fakePriceSource(),
    lootStrings = ports.lootStrings or support.enUSLootStrings,
  }
  return ns.Tracker.new(built), built
end

return support
