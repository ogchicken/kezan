local support = require("spec.support.tracker")

local SILK = support.itemLink(4306, "Silk Cloth")
local MAGEWEAVE = support.itemLink(4338, "Mageweave Cloth")
local LINEN = support.itemLink(2589, "Linen Cloth")
local MYSTERY = support.itemLink(9999, "Mystery Item")

-- A white item worth `vendorValue` copper at a vendor and nothing on the AH.
local function vendorItem(itemID, vendorValue)
  return { itemID = itemID, quality = 1, soulbound = false, vendorValue = vendorValue }
end

describe("the summary of a stopped session", function()
  it("lists the top 10 items by value, most valuable first", function()
    local itemFacts = support.fakeItemFacts()
    local tracker = support.newTracker({ itemFacts = itemFacts })
    tracker:start()
    -- Twelve items: item n is worth n * 10 copper a unit, looted once,
    -- except item 3, looted 5 times (150 copper in all).
    for n = 1, 12 do
      local link = support.itemLink(1000 + n, "Item " .. n)
      itemFacts.load(link, vendorItem(1000 + n, n * 10))
      tracker:chatLine("loot", "You receive loot: " .. link .. (n == 3 and "x5" or ""))
    end

    local summary = tracker:stop()

    local names = {}
    for index, item in ipairs(summary.topItems) do
      names[index] = item.link:match("%[(.-)%]")
    end
    assert.are.same({
      "Item 3", "Item 12", "Item 11", "Item 10", "Item 9",
      "Item 8", "Item 7", "Item 6", "Item 5", "Item 4",
    }, names)
    assert.are.same({
      link = support.itemLink(1003, "Item 3"),
      quantity = 5,
      itemValue = 30,
      value = 150,
      pricing = "vendor",
    }, summary.topItems[1])
  end)

  it("marks how each item was priced", function()
    local tracker = support.newTracker({
      itemFacts = support.fakeItemFacts({
        [SILK] = vendorItem(4306, 37),
        [MAGEWEAVE] = vendorItem(4338, 50),
        [LINEN] = vendorItem(2589, 13),
      }),
      priceSource = support.fakePriceSource({
        [SILK] = { copper = 400, ageDays = 1 },
        [MAGEWEAVE] = { copper = 300, ageDays = 9 },
      }),
    })
    tracker:start()
    for _, link in ipairs({ SILK, MAGEWEAVE, LINEN, MYSTERY }) do
      tracker:chatLine("loot", "You receive loot: " .. link)
    end

    local pricing = {}
    for _, item in ipairs(tracker:stop().topItems) do
      pricing[item.link] = item.pricing
    end

    assert.are.same({
      [SILK] = "ah",
      [MAGEWEAVE] = "stale",
      [LINEN] = "vendor",
      [MYSTERY] = "unpriced",
    }, pricing)
  end)

  it("says how many loot lines couldn't be read", function()
    local tracker = support.newTracker()
    tracker:start()
    tracker:unreadableLine()
    tracker:unreadableLine()

    assert.are.equal(2, tracker:stop().unreadableLines)
  end)

  it("names the character, the start zone and the start time", function()
    local clock = support.fakeClock(1764230400)
    local tracker = support.newTracker({ clock = clock, character = "Grimble-Stormreaver" })
    tracker:start("The Deadmines")
    clock.set(1764230400 + 900)

    local summary = tracker:stop()

    assert.are.equal("Grimble-Stormreaver", summary.character)
    assert.are.equal("The Deadmines", summary.startZone)
    assert.are.equal(1764230400, summary.startedAt)
    assert.are.equal(900, summary.activeTime)
  end)
end)

describe("the latest summary", function()
  it("is the summary of the character's last stopped session, after a reload too", function()
    local savedState = {}
    local clock = support.fakeClock(0)
    local itemFacts = support.fakeItemFacts({ [LINEN] = vendorItem(2589, 13) })
    local tracker = support.newTracker({
      clock = clock, itemFacts = itemFacts, savedState = savedState, character = "Grimble-Stormreaver",
    })
    tracker:start("Elwynn Forest")
    clock.set(60)
    tracker:stop()
    tracker:start("Westfall")
    tracker:chatLine("loot", "You receive loot: " .. LINEN .. "x2")
    clock.set(660)
    local stopped = tracker:stop()
    support.newTracker({ clock = clock, savedState = savedState, character = "Fizzle-Stormreaver" }):start()

    local reloaded = support.newTracker({
      clock = clock, savedState = savedState, character = "Grimble-Stormreaver",
    })
    local latest = reloaded:lastSummary()

    assert.are.equal("Westfall", latest.startZone)
    assert.are.equal(600, latest.activeTime)
    assert.are.equal(26, latest.lootedItemValue)
    assert.are.same(stopped.topItems, latest.topItems)
  end)

  it("is never another character's", function()
    local savedState = {}
    local main = support.newTracker({ savedState = savedState, character = "Grimble-Stormreaver" })
    main:start("Elwynn Forest")
    main:stop()
    local alt = support.newTracker({ savedState = savedState, character = "Fizzle-Stormreaver" })

    local summary, reason = alt:lastSummary()

    assert.is_nil(summary)
    assert.are.equal("No session has been stopped on this character yet.", reason)
  end)
end)
