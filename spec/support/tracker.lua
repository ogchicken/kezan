-- Builds a tracker from the session core with fake ports, the way every
-- tracker test starts (ADR 0003).

local support = {}

-- The enUS values of the client's own loot and coin format strings on
-- Forever (research/2026-11-27-loot-and-money-events.md, section 3; the
-- two _GUILD forms from the enUS GlobalStrings of Forever build 70938 in
-- Ketho/BlizzardInterfaceResources).
support.enUSLootStrings = {
  LOOT_ITEM_SELF = "You receive loot: %s",
  LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d",
  YOU_LOOT_MONEY = "You loot %s",
  YOU_LOOT_MONEY_GUILD = "You loot %s (%s deposited to guild bank)",
  LOOT_MONEY_SPLIT = "Your share of the loot is %s.",
  LOOT_MONEY_SPLIT_GUILD = "Your share of the loot is %s. (%s deposited to guild bank)",
  GOLD_AMOUNT = "%d Gold",
  SILVER_AMOUNT = "%d Silver",
  COPPER_AMOUNT = "%d Copper",
}

-- An item link as the client puts it in a chat line, such as
-- "|cffffffff|Hitem:2447::::::::60:::::::::|h[Peacebloom]|h|r". `color`
-- is the quality colour without "|c"; white when left out. `level` is the
-- looting player's level, which the client writes into the link; 60 when
-- left out.
function support.itemLink(itemID, name, color, level)
  return ("|c%s|Hitem:%d::::::::%d:::::::::|h[%s]|h|r"):format(color or "ffffffff", itemID, level or 60, name)
end

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
-- nil, then its age in whole days or nil when unknown, then
-- `ageUnsupported`: true when the source can't tell any price's age (as
-- when Auctionator's age call is missing or fails), so nothing is stale.
-- `set(itemLink, copper, ageDays)` changes a price. Options:
-- `withoutAges = true` makes a source that can't tell ages.
function support.fakePriceSource(pricesByLink, options)
  local withoutAges = options and options.withoutAges or false
  local prices = {}
  for link, price in pairs(pricesByLink or {}) do
    prices[link] = price
  end
  local priceSource = {}
  function priceSource.ahValue(itemLink)
    local price = prices[itemLink]
    if withoutAges then
      return price and price.copper, nil, true
    end
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
-- 0, no item facts, the enUS loot strings, and Auctionator loaded with no
-- prices. `priceSource = <port>` is short for
-- `priceSources = { auctionator = <port> }`; pass `priceSources = {}` for
-- no price addon loaded. Options left out get
-- an empty saved state and the character "Farmer-Realm"; pass one
-- `savedState` to two trackers to see what a later tracker finds. Returns
-- the tracker and the ports it was built with.
function support.newTracker(ports)
  ports = ports or {}
  local ns = support.loadCore()
  local built = {
    clock = ports.clock or support.fakeClock(0),
    itemFacts = ports.itemFacts or support.fakeItemFacts(),
    priceSources = ports.priceSources or { auctionator = ports.priceSource or support.fakePriceSource() },
    lootStrings = ports.lootStrings or support.enUSLootStrings,
    savedState = ports.savedState or {},
    character = ports.character or "Farmer-Realm",
  }
  return ns.Tracker.new(built), built
end

return support
