local support = require("spec.support.tracker")

describe("the current session in saved state", function()
  it("is found again by a tracker built later on the same saved state", function()
    local savedState = {}
    local clock = support.fakeClock(0)
    local first = support.newTracker({
      clock = clock, savedState = savedState, character = "Grimble-Stormreaver",
    })
    first:start()
    first:chatLine("coin", "You loot 6 Silver")
    first:unreadableLine()
    clock.set(300)

    local later = support.newTracker({
      clock = clock, savedState = savedState, character = "Grimble-Stormreaver",
    })

    local figures = later:frameFigures()
    assert.are.equal("running", figures.state)
    assert.are.equal(600, figures.rawGold)
    assert.are.equal(1, figures.unreadableLines)
    assert.are.equal(300, figures.activeTime)
  end)

  it("keeps one session per character and realm", function()
    local savedState = {}
    local main = support.newTracker({ savedState = savedState, character = "Grimble-Stormreaver" })
    local alt = support.newTracker({ savedState = savedState, character = "Grimble-Mograine" })
    main:start()
    main:chatLine("coin", "You loot 1 Gold")

    assert.are.equal("none", alt:frameFigures().state)
    assert.is_true(alt:start())
    alt:chatLine("coin", "You loot 3 Copper")
    alt:stop()

    local mainAgain = support.newTracker({ savedState = savedState, character = "Grimble-Stormreaver" })
    assert.are.equal(10000, mainAgain:frameFigures().rawGold)
    assert.are.equal("none", support.newTracker({
      savedState = savedState, character = "Grimble-Mograine",
    }):frameFigures().state)
  end)
end)

describe("looted items in saved state", function()
  it("are found again, with their values, by a tracker built later", function()
    local savedState = {}
    local linen = support.itemLink(2589, "Linen Cloth")
    local itemFacts = support.fakeItemFacts({
      [linen] = { itemID = 2589, quality = 1, soulbound = false, vendorValue = 13 },
    })
    local first = support.newTracker({ savedState = savedState, itemFacts = itemFacts })
    first:start()
    first:chatLine("loot", "You receive loot: " .. linen .. "x3")

    local later = support.newTracker({ savedState = savedState, itemFacts = support.fakeItemFacts() })

    assert.are.equal(39, later:frameFigures().lootedItemValue)
  end)
end)
