local support = require("spec.support.tracker")

local PEACEBLOOM = support.itemLink(2447, "Peacebloom")

describe("items looted during a session", function()
  it("values a single drop at its vendor value with no price source", function()
    local clock = support.fakeClock(0)
    local tracker = support.newTracker({
      clock = clock,
      itemFacts = support.fakeItemFacts({
        [PEACEBLOOM] = { itemID = 2447, quality = 1, soulbound = false, vendorValue = 5 },
      }),
    })
    tracker:start()
    tracker:chatLine("coin", "You loot 1 Silver")
    tracker:chatLine("loot", "You receive loot: " .. PEACEBLOOM)
    clock.set(1800)

    local figures = tracker:frameFigures()

    assert.are.equal(5, figures.lootedItemValue)
    assert.are.equal(105, figures.total)
    assert.are.equal(210, figures.gph)
  end)

  it("adds the drops of one item into a total quantity, single and multiple", function()
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [PEACEBLOOM] = { itemID = 2447, quality = 1, soulbound = false, vendorValue = 5 },
      }),
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. PEACEBLOOM .. "x3")
    tracker:chatLine("loot", "You receive loot: " .. PEACEBLOOM)
    tracker:chatLine("loot", "You receive loot: " .. PEACEBLOOM .. "x2")

    local stopped = tracker:stop()

    assert.are.equal(30, stopped.lootedItemValue)
    assert.are.same({ [PEACEBLOOM] = { quantity = 6, itemValue = 5, pricing = "vendor" } }, stopped.items)
  end)

  local counted = {
    { "You receive loot: " .. PEACEBLOOM, 1 },
    { "You receive loot: " .. PEACEBLOOM .. ".", 1 },
    { "You receive loot: " .. PEACEBLOOM .. "x4", 4 },
    { "You receive loot: " .. PEACEBLOOM .. "x4.", 4 },
    { "You receive loot: " .. PEACEBLOOM .. "x20", 20 },
  }
  for _, case in ipairs(counted) do
    local text, quantity = case[1], case[2]
    it(("counts %q as %d units"):format(text, quantity), function()
      local tracker = support.newTracker()
      tracker:start()

      tracker:chatLine("loot", text)

      assert.are.equal(quantity, tracker:stop().items[PEACEBLOOM].quantity)
    end)
  end

  local ignored = {
    { "a quest reward or purchase", "You receive item: " .. PEACEBLOOM .. "." },
    { "a quest reward or purchase, multiple", "You receive item: " .. PEACEBLOOM .. "x5." },
    { "a crafted item", "You create: " .. PEACEBLOOM .. "." },
    { "a crafted stack", "You create: " .. PEACEBLOOM .. "x5." },
    { "a won roll", "|HlootHistory:7|h[Loot]|h: You won: " .. PEACEBLOOM },
    { "a groupmate's loot", "Grimble receives loot: " .. PEACEBLOOM .. "." },
    { "a groupmate's stack", "Grimble receives loot: " .. PEACEBLOOM .. "x3." },
    { "a groupmate's received item", "Grimble receives item: " .. PEACEBLOOM .. "." },
  }
  for _, case in ipairs(ignored) do
    local name, text = case[1], case[2]
    it(("does not count %s: %q"):format(name, text), function()
      local tracker = support.newTracker({
        itemFacts = support.fakeItemFacts({
          [PEACEBLOOM] = { itemID = 2447, quality = 1, soulbound = false, vendorValue = 5 },
        }),
      })
      tracker:start()

      tracker:chatLine("loot", text)

      local stopped = tracker:stop()
      assert.are.equal(0, stopped.lootedItemValue)
      assert.are.same({}, stopped.items)
    end)
  end

  it("counts a won roll once, through its own receive loot line", function()
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [PEACEBLOOM] = { itemID = 2447, quality = 1, soulbound = false, vendorValue = 5 },
      }),
    })
    tracker:start()

    tracker:chatLine("loot", "|HlootHistory:7|h[Loot]|h: You won: " .. PEACEBLOOM)
    tracker:chatLine("loot", "You receive loot: " .. PEACEBLOOM)

    assert.are.equal(1, tracker:stop().items[PEACEBLOOM].quantity)
  end)

  it("does not count loot with no session running", function()
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [PEACEBLOOM] = { itemID = 2447, quality = 1, soulbound = false, vendorValue = 5 },
      }),
    })
    tracker:chatLine("loot", "You receive loot: " .. PEACEBLOOM)
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. PEACEBLOOM .. "x2")
    tracker:stop()
    tracker:chatLine("loot", "You receive loot: " .. PEACEBLOOM .. "x7")
    tracker:start()

    assert.are.equal(0, tracker:frameFigures().lootedItemValue)
    assert.are.same({}, tracker:stop().items)
  end)
end)

local LINEN = support.itemLink(2589, "Linen Cloth")
local STRANGE_SHARD = support.itemLink(90001, "Strange Shard")

describe("the value of looted items with no price source", function()
  it("counts an item with no vendor value at 0 and marks it unpriced", function()
    local clock = support.fakeClock(0)
    local tracker = support.newTracker({
      clock = clock,
      itemFacts = support.fakeItemFacts({
        [LINEN] = { itemID = 2589, quality = 1, soulbound = false, vendorValue = 13 },
        [STRANGE_SHARD] = { itemID = 90001, quality = 1, soulbound = true, vendorValue = 0 },
      }),
    })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. LINEN .. "x2")
    tracker:chatLine("loot", "You receive loot: " .. STRANGE_SHARD .. "x3")
    clock.set(3600)

    local stopped = tracker:stop()

    assert.are.equal(26, stopped.lootedItemValue)
    assert.are.equal(26, stopped.gph)
    assert.are.same({ quantity = 3, itemValue = 0, pricing = "unpriced" }, stopped.items[STRANGE_SHARD])
  end)

  it("records an item whose facts load late at once and values it on a later refresh", function()
    local clock = support.fakeClock(0)
    local itemFacts = support.fakeItemFacts()
    local tracker = support.newTracker({ clock = clock, itemFacts = itemFacts })
    tracker:start()
    tracker:chatLine("coin", "You loot 40 Copper")
    tracker:chatLine("loot", "You receive loot: " .. LINEN .. "x4")
    clock.set(1800)

    assert.are.equal(0, tracker:frameFigures().lootedItemValue)

    itemFacts.load(LINEN, { itemID = 2589, quality = 1, soulbound = false, vendorValue = 13 })
    tracker:refresh()

    local figures = tracker:frameFigures()
    assert.are.equal(52, figures.lootedItemValue)
    assert.are.equal(92, figures.total)
    assert.are.equal(184, figures.gph)
    assert.are.same({ quantity = 4, itemValue = 13, pricing = "vendor" }, tracker:stop().items[LINEN])
  end)

  it("stores an item whose facts never loaded before stop as unpriced", function()
    local tracker = support.newTracker()
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. LINEN .. "x4")
    tracker:refresh()

    local stopped = tracker:stop()

    assert.are.equal(0, stopped.lootedItemValue)
    assert.are.same({ quantity = 4, itemValue = 0, pricing = "unpriced" }, stopped.items[LINEN])
  end)

  it("values late facts that arrive just before stop", function()
    local itemFacts = support.fakeItemFacts()
    local tracker = support.newTracker({ itemFacts = itemFacts })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. LINEN)
    itemFacts.load(LINEN, { itemID = 2589, quality = 1, soulbound = false, vendorValue = 13 })

    assert.are.equal(13, tracker:stop().lootedItemValue)
  end)

  it("does nothing on refresh with no session", function()
    local tracker = support.newTracker()

    tracker:refresh()

    assert.are.equal("none", tracker:frameFigures().state)
  end)
end)

describe("items looted while paused", function()
  it("do not count, and items looted before the pause keep their value", function()
    local itemFacts = support.fakeItemFacts({
      [LINEN] = { itemID = 2589, quality = 1, soulbound = false, vendorValue = 13 },
    })
    local tracker = support.newTracker({ itemFacts = itemFacts })
    tracker:start()
    tracker:chatLine("loot", "You receive loot: " .. LINEN .. "x2")
    tracker:pause()
    tracker:chatLine("loot", "You receive loot: " .. LINEN .. "x5")
    tracker:refresh()

    assert.are.equal(26, tracker:frameFigures().lootedItemValue)
    tracker:resume()
    tracker:chatLine("loot", "You receive loot: " .. LINEN)
    assert.are.equal(3, tracker:stop().items[LINEN].quantity)
  end)
end)
