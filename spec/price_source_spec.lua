local support = require("spec.support.tracker")

local SILK = support.itemLink(4306, "Silk Cloth")
local BROKEN_FANG = support.itemLink(3300, "Broken Fang", "ff9d9d9d")
local SCOUTING_BELT = support.itemLink(6587, "Scouting Belt", "ff1eff00")

describe("item values with Auctionator as price source", function()
  it("values a tradable item at its AH value", function()
    local clock = support.fakeClock(0)
    local tracker = support.newTracker({
      clock = clock,
      itemFacts = support.fakeItemFacts({
        [SILK] = { itemID = 4306, quality = 1, soulbound = false, vendorValue = 37 },
      }),
      priceSource = support.fakePriceSource({ [SILK] = { copper = 250, ageDays = 1 } }),
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK .. "x4")
    clock.set(1800)

    local figures = tracker:frameFigures()

    assert.are.equal(1000, figures.lootedItemValue)
    assert.are.equal(2000, figures.gph)
    assert.are.same({ quantity = 4, itemValue = 250, pricing = "ah" }, tracker:stop().items[SILK])
  end)

  it("values a grey at its vendor value even with an AH value", function()
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [BROKEN_FANG] = { itemID = 3300, quality = 0, soulbound = false, vendorValue = 21 },
      }),
      priceSource = support.fakePriceSource({ [BROKEN_FANG] = { copper = 900, ageDays = 0 } }),
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. BROKEN_FANG .. "x2")

    local stopped = tracker:stop()

    assert.are.equal(42, stopped.lootedItemValue)
    assert.are.same({ quantity = 2, itemValue = 21, pricing = "vendor" }, stopped.items[BROKEN_FANG])
  end)

  it("values a soulbound item at its vendor value even with an AH value", function()
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [SCOUTING_BELT] = { itemID = 6587, quality = 2, soulbound = true, vendorValue = 180 },
      }),
      priceSource = support.fakePriceSource({ [SCOUTING_BELT] = { copper = 5000, ageDays = 0 } }),
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SCOUTING_BELT)

    local stopped = tracker:stop()

    assert.are.equal(180, stopped.lootedItemValue)
    assert.are.same({ quantity = 1, itemValue = 180, pricing = "vendor" }, stopped.items[SCOUTING_BELT])
  end)

  it("values a tradable item with no AH value at its vendor value", function()
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [SILK] = { itemID = 4306, quality = 1, soulbound = false, vendorValue = 37 },
      }),
      priceSource = support.fakePriceSource(),
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK .. "x3")

    local stopped = tracker:stop()

    assert.are.equal(111, stopped.lootedItemValue)
    assert.are.same({ quantity = 3, itemValue = 37, pricing = "vendor" }, stopped.items[SILK])
  end)
end)

describe("stale AH values", function()
  local function stoppedSilk(price)
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [SILK] = { itemID = 4306, quality = 1, soulbound = false, vendorValue = 37 },
      }),
      priceSource = support.fakePriceSource({ [SILK] = price }),
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK .. "x2")
    return tracker:stop()
  end

  it("marks an AH value last seen 4 days ago stale, and still uses it", function()
    local stopped = stoppedSilk({ copper = 250, ageDays = 4 })

    assert.are.equal(500, stopped.lootedItemValue)
    assert.are.same({ quantity = 2, itemValue = 250, pricing = "stale" }, stopped.items[SILK])
  end)

  it("keeps an AH value last seen 3 days ago fresh", function()
    local stopped = stoppedSilk({ copper = 250, ageDays = 3 })

    assert.are.same({ quantity = 2, itemValue = 250, pricing = "ah" }, stopped.items[SILK])
  end)

  it("marks an AH value of unknown age stale, and still uses it", function()
    local stopped = stoppedSilk({ copper = 250 })

    assert.are.equal(500, stopped.lootedItemValue)
    assert.are.same({ quantity = 2, itemValue = 250, pricing = "stale" }, stopped.items[SILK])
  end)

  it("marks nothing stale when the price source can't tell ages", function()
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [SILK] = { itemID = 4306, quality = 1, soulbound = false, vendorValue = 37 },
      }),
      priceSource = support.fakePriceSource({ [SILK] = { copper = 250 } }, { withoutAges = true }),
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK .. "x2")

    local stopped = tracker:stop()

    assert.are.equal(500, stopped.lootedItemValue)
    assert.are.same({ quantity = 2, itemValue = 250, pricing = "ah" }, stopped.items[SILK])
  end)
end)

describe("AH values while the session runs", function()
  it("follow a price change, such as a fresh scan, at the next refresh", function()
    local priceSource = support.fakePriceSource({ [SILK] = { copper = 250, ageDays = 6 } })
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [SILK] = { itemID = 4306, quality = 1, soulbound = false, vendorValue = 37 },
      }),
      priceSource = priceSource,
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK .. "x2")
    assert.are.equal(500, tracker:frameFigures().lootedItemValue)

    priceSource.set(SILK, 310, 0)
    assert.are.equal(500, tracker:frameFigures().lootedItemValue)
    tracker:refresh()

    assert.are.equal(620, tracker:frameFigures().lootedItemValue)
    assert.are.same({ quantity = 2, itemValue = 310, pricing = "ah" }, tracker:stop().items[SILK])
  end)
end)

describe("the price source choice", function()
  local function silkFacts()
    return support.fakeItemFacts({
      [SILK] = { itemID = 4306, quality = 1, soulbound = false, vendorValue = 37 },
    })
  end

  it("is Auctionator by default when Auctionator is loaded", function()
    local tracker = support.newTracker({
      itemFacts = silkFacts(),
      priceSources = { auctionator = support.fakePriceSource({ [SILK] = { copper = 250, ageDays = 0 } }) },
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK)

    assert.are.same({ "auctionator" }, { tracker:priceSource() })
    assert.are.equal(250, tracker:stop().lootedItemValue)
  end)

  it("is None, with the reason, when Auctionator is not loaded, and items take vendor values", function()
    local tracker = support.newTracker({ itemFacts = silkFacts(), priceSources = {} })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK .. "x2")

    assert.are.same({ "none", "Auctionator is not loaded." }, { tracker:priceSource() })
    assert.are.same({ quantity = 2, itemValue = 37, pricing = "vendor" }, tracker:stop().items[SILK])
  end)

  it("can be None with Auctionator loaded, kept in saved state for a later load", function()
    local savedState = {}
    local auctionator = support.fakePriceSource({ [SILK] = { copper = 250, ageDays = 0 } })
    local first = support.newTracker({
      itemFacts = silkFacts(),
      priceSources = { auctionator = auctionator },
      savedState = savedState,
    })
    first:start()
    first:chatLine("loot", "You receive loot: " .. SILK)

    assert.is_true(first:setPriceSource("none"))
    first:refresh()
    assert.are.equal(37, first:frameFigures().lootedItemValue)

    local later = support.newTracker({
      itemFacts = silkFacts(),
      priceSources = { auctionator = auctionator },
      savedState = savedState,
    })
    assert.are.same({ "none" }, { later:priceSource() })
    later:setPriceSource("auctionator")
    later:refresh()
    assert.are.equal(250, later:frameFigures().lootedItemValue)
  end)
end)

describe("the price source the settings panel shows", function()
  local function silkFacts()
    return support.fakeItemFacts({
      [SILK] = { itemID = 4306, quality = 1, soulbound = false, vendorValue = 37 },
    })
  end

  it("is None with the reason when Auctionator is not loaded, even after None was chosen", function()
    local savedState = { priceSource = "none" }
    local tracker = support.newTracker({ itemFacts = silkFacts(), priceSources = {}, savedState = savedState })

    assert.are.same({ "none", "Auctionator is not loaded." }, { tracker:priceSource() })
  end)

  it("gives vendor values from the next refresh once None is chosen with Auctionator loaded", function()
    local tracker = support.newTracker({
      itemFacts = silkFacts(),
      priceSources = { auctionator = support.fakePriceSource({ [SILK] = { copper = 250, ageDays = 0 } }) },
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK .. "x2")
    assert.are.equal(500, tracker:frameFigures().lootedItemValue)

    tracker:setPriceSource("none")
    assert.are.same({ "none" }, { tracker:priceSource() })
    assert.are.equal(500, tracker:frameFigures().lootedItemValue)
    tracker:refresh()

    assert.are.equal(74, tracker:frameFigures().lootedItemValue)
    assert.are.same({ quantity = 2, itemValue = 37, pricing = "vendor" }, tracker:stop().items[SILK])
  end)

  it("gives vendor values to loot that arrives after None is chosen", function()
    local tracker = support.newTracker({
      itemFacts = silkFacts(),
      priceSources = { auctionator = support.fakePriceSource({ [SILK] = { copper = 250, ageDays = 0 } }) },
    })
    tracker:setPriceSource("none")
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. SILK)

    assert.are.same({ quantity = 1, itemValue = 37, pricing = "vendor" }, tracker:stop().items[SILK])
  end)
end)
