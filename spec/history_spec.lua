local support = require("spec.support.tracker")

local LINEN = support.itemLink(2589, "Linen Cloth")
local SILK = support.itemLink(4306, "Silk Cloth")
local NEVER_LOADED = support.itemLink(9999, "Never Loaded")

local LINEN_FACTS = { itemID = 2589, quality = 1, soulbound = false, vendorValue = 13 }
local SILK_FACTS = { itemID = 4306, quality = 1, soulbound = false, vendorValue = 37 }

-- KezanDB.history: every stopped session, oldest first (plan section 5).
describe("the history of stopped sessions", function()
  it("keeps every session of every character, totalled per item", function()
    local savedState = {}
    local clock = support.fakeClock(1000)
    local itemFacts = support.fakeItemFacts({ [LINEN] = LINEN_FACTS })
    local main = support.newTracker({
      clock = clock, itemFacts = itemFacts, savedState = savedState, character = "Grimble-Stormreaver",
    })
    local alt = support.newTracker({
      clock = clock, itemFacts = itemFacts, savedState = savedState, character = "Fizzle-Stormreaver",
    })

    main:start("Elwynn Forest")
    main:chatLine("coin", "You loot 2 Silver")
    main:chatLine("loot", "You receive loot: " .. LINEN .. "x2")
    main:chatLine("loot", "You receive loot: " .. LINEN .. "x3")
    clock.set(1600)
    main:stop()
    alt:start("Westfall")
    clock.set(1900)
    alt:stop()
    main:start("Duskwood")
    clock.set(2000)
    main:stop()

    assert.are.same({
      {
        character = "Grimble-Stormreaver",
        startZone = "Elwynn Forest",
        startedAt = 1000,
        stoppedAt = 1600,
        activeTime = 600,
        rawGold = 200,
        lootedItemValue = 65,
        total = 265,
        gph = 1590,
        unreadableLines = 0,
        items = { [LINEN] = { quantity = 5, itemValue = 13, pricing = "vendor" } },
      },
      {
        character = "Fizzle-Stormreaver",
        startZone = "Westfall",
        startedAt = 1600,
        stoppedAt = 1900,
        activeTime = 300,
        rawGold = 0,
        lootedItemValue = 0,
        total = 0,
        gph = 0,
        unreadableLines = 0,
        items = {},
      },
      {
        character = "Grimble-Stormreaver",
        startZone = "Duskwood",
        startedAt = 1900,
        stoppedAt = 2000,
        activeTime = 100,
        rawGold = 0,
        lootedItemValue = 0,
        total = 0,
        gph = 0,
        unreadableLines = 0,
        items = {},
      },
    }, savedState.history)
  end)

  it("keeps item values as they were at stop, whatever prices do later", function()
    local savedState = {}
    local priceSource = support.fakePriceSource({ [SILK] = { copper = 250, ageDays = 0 } })
    local itemFacts = support.fakeItemFacts({ [SILK] = SILK_FACTS })
    local tracker = support.newTracker({
      savedState = savedState, itemFacts = itemFacts, priceSource = priceSource,
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK .. "x2")
    tracker:stop()

    priceSource.set(SILK, 900, 0)
    tracker:refresh()
    tracker:start()
    tracker:refresh()
    local later = support.newTracker({
      savedState = savedState, itemFacts = itemFacts, priceSource = priceSource,
    })
    later:refresh()

    assert.are.same({ quantity = 2, itemValue = 250, pricing = "ah" }, savedState.history[1].items[SILK])
    assert.are.equal(500, savedState.history[1].lootedItemValue)
    assert.are.equal(250, later:lastSummary().topItems[1].itemValue)
  end)

  it("stores an item whose facts never loaded as unpriced, even once they load", function()
    local savedState = {}
    local itemFacts = support.fakeItemFacts()
    local tracker = support.newTracker({ savedState = savedState, itemFacts = itemFacts })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. NEVER_LOADED .. "x4")
    tracker:stop()

    itemFacts.load(NEVER_LOADED, { itemID = 9999, quality = 1, soulbound = false, vendorValue = 75 })
    tracker:refresh()

    assert.are.same(
      { quantity = 4, itemValue = 0, pricing = "unpriced" },
      savedState.history[1].items[NEVER_LOADED])
    assert.are.equal(0, savedState.history[1].lootedItemValue)
  end)
end)
