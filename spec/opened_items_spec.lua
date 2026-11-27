local support = require("spec.support.tracker")

local CLAM = support.itemLink(7973, "Big-mouth Clam")
local PEARL = support.itemLink(13926, "Golden Pearl", "ff1eff00")

local function farmItemFacts()
  return support.fakeItemFacts({
    [CLAM] = { itemID = 7973, quality = 1, soulbound = false, vendorValue = 2 },
    [PEARL] = { itemID = 13926, quality = 2, soulbound = false, vendorValue = 1500 },
  })
end

describe("an opened item the session holds", function()
  it("leaves the session, one unit, and its contents count", function()
    local tracker = support.newTracker({ itemFacts = farmItemFacts() })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. CLAM)

    tracker:lootWindowOpened(7973)
    tracker:chatLine("loot", "You receive loot: " .. PEARL)
    tracker:lootWindowClosed()

    local stopped = tracker:stop()
    assert.are.equal(1500, stopped.lootedItemValue)
    assert.are.same({ [PEARL] = { quantity = 1, itemValue = 1500, pricing = "vendor" } }, stopped.items)
  end)
end)

describe("an opened item from before the session", function()
  it("adds none of its contents, items or coin", function()
    local tracker = support.newTracker({ itemFacts = farmItemFacts() })
    tracker:start()
    tracker:chatLine("coin", "You loot 3 Silver")

    tracker:lootWindowOpened(16883) -- a Worn Junkbox that was in the bags already
    tracker:chatLine("coin", "You loot 1 Gold")
    tracker:chatLine("loot", "You receive loot: " .. PEARL)
    tracker:lootWindowClosed()

    local stopped = tracker:stop()
    assert.are.equal(300, stopped.rawGold)
    assert.are.equal(0, stopped.lootedItemValue)
    assert.are.same({}, stopped.items)
  end)
end)

describe("an opened item that could not be identified", function()
  it("removes nothing, and its contents count", function()
    local tracker = support.newTracker({ itemFacts = farmItemFacts() })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. CLAM)

    tracker:lootWindowOpened(nil)
    tracker:chatLine("coin", "You loot 2 Silver")
    tracker:chatLine("loot", "You receive loot: " .. PEARL)
    tracker:lootWindowClosed()

    local stopped = tracker:stop()
    assert.are.equal(200, stopped.rawGold)
    assert.are.equal(1502, stopped.lootedItemValue)
    assert.are.equal(1, stopped.items[CLAM].quantity)
  end)
end)

describe("several clams opened from one stack", function()
  it("each take one unit out, and once the session's units are gone the old stock adds nothing", function()
    local tracker = support.newTracker({ itemFacts = farmItemFacts() })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. CLAM .. "x2")

    -- Three clams opened one after another from a stack of five: two
    -- looted this session and three that were in the bags before.
    for _ = 1, 3 do
      tracker:lootWindowOpened(7973)
      tracker:chatLine("loot", "You receive loot: " .. PEARL)
      tracker:lootWindowClosed()
    end

    local stopped = tracker:stop()
    assert.are.equal(3000, stopped.lootedItemValue)
    assert.are.same({ [PEARL] = { quantity = 2, itemValue = 1500, pricing = "vendor" } }, stopped.items)
  end)

  it("leaves the clams not opened in the session", function()
    local tracker = support.newTracker({ itemFacts = farmItemFacts() })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. CLAM .. "x4")

    tracker:lootWindowOpened(7973)
    tracker:chatLine("loot", "You receive loot: " .. PEARL)
    tracker:lootWindowClosed()

    local stopped = tracker:stop()
    assert.are.equal(3, stopped.items[CLAM].quantity)
    assert.are.equal(1506, stopped.lootedItemValue)
  end)
end)

describe("lines after an opened item's window closes", function()
  it("count as usual, even when the window was from old stock", function()
    local tracker = support.newTracker({ itemFacts = farmItemFacts() })
    tracker:start()
    tracker:lootWindowOpened(7973)
    tracker:chatLine("loot", "You receive loot: " .. PEARL)
    tracker:lootWindowClosed()

    tracker:chatLine("coin", "You loot 5 Copper")
    tracker:chatLine("loot", "You receive loot: " .. PEARL)

    local stopped = tracker:stop()
    assert.are.equal(5, stopped.rawGold)
    assert.are.equal(1, stopped.items[PEARL].quantity)
  end)

  it("count when a new window replaces one from old stock before it closed", function()
    local tracker = support.newTracker({ itemFacts = farmItemFacts() })
    tracker:start()
    tracker:lootWindowOpened(7973)

    tracker:lootWindowOpened(nil)
    tracker:chatLine("loot", "You receive loot: " .. PEARL)

    assert.are.equal(1, tracker:stop().items[PEARL].quantity)
  end)
end)

describe("a disenchanted drop", function()
  it("is replaced by its materials", function()
    local BLADE = support.itemLink(15213, "Mercenary Blade", "ff1eff00")
    local DUST = support.itemLink(11176, "Dream Dust")
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [BLADE] = { itemID = 15213, quality = 2, soulbound = true, vendorValue = 900 },
        [DUST] = { itemID = 11176, quality = 1, soulbound = false, vendorValue = 250 },
      }),
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. BLADE)

    tracker:lootWindowOpened(15213)
    tracker:chatLine("loot", "You receive loot: " .. DUST .. "x2")
    tracker:lootWindowClosed()

    local stopped = tracker:stop()
    assert.are.equal(500, stopped.lootedItemValue)
    assert.is_nil(stopped.items[BLADE])
  end)
end)

describe("an item opened while paused", function()
  it("stays in the session, and its contents do not count", function()
    local tracker = support.newTracker({ itemFacts = farmItemFacts() })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. CLAM)
    tracker:pause()

    tracker:lootWindowOpened(7973)
    tracker:chatLine("loot", "You receive loot: " .. PEARL)
    tracker:lootWindowClosed()

    local stopped = tracker:stop()
    assert.are.same({ [CLAM] = { quantity = 1, itemValue = 2, pricing = "vendor" } }, stopped.items)
  end)
end)
