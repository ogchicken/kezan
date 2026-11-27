local support = require("spec.support.tracker")

describe("coin split in a group", function()
  local lines = {
    { "Your share of the loot is 47 Copper.", 47 },
    { "Your share of the loot is 47 Copper", 47 },
    { "Your share of the loot is 1 Gold, 2 Silver, 3 Copper.", 10203 },
  }
  for _, case in ipairs(lines) do
    local text, copper = case[1], case[2]
    it(("counts only the player's share: %q as %d copper"):format(text, copper), function()
      local tracker = support.newTracker()
      tracker:start()

      tracker:chatLine("coin", text)

      assert.are.equal(copper, tracker:frameFigures().rawGold)
    end)
  end
end)

describe("a groupmate's coin", function()
  local lines = {
    "Grimble loots 5 Silver.",
    "Grimble loots 1 Gold, 2 Silver, 3 Copper.",
    "Grimble loots 47 Copper",
  }
  for _, text in ipairs(lines) do
    it(("does not count %q"):format(text), function()
      local tracker = support.newTracker()
      tracker:start()

      tracker:chatLine("coin", text)

      assert.are.equal(0, tracker:frameFigures().rawGold)
    end)
  end
end)

local LINEN = support.itemLink(2589, "Linen Cloth")
local BLADE = support.itemLink(1482, "Shadowfang", "ff0070dd")

describe("a group dungeon run", function()
  it("counts only the player's loot, a won roll once and a secret line as unreadable", function()
    local clock = support.fakeClock(0)
    local tracker = support.newTracker({
      clock = clock,
      itemFacts = support.fakeItemFacts({
        [LINEN] = { itemID = 2589, quality = 1, soulbound = false, vendorValue = 13 },
        [BLADE] = { itemID = 1482, quality = 3, soulbound = true, vendorValue = 9000 },
      }),
    })
    tracker:start()

    -- Trash.
    tracker:chatLine("coin", "Your share of the loot is 12 Copper.")
    tracker:chatLine("loot", "You receive loot: " .. LINEN .. "x2.")
    tracker:chatLine("loot", "Grimble receives loot: " .. LINEN .. "x3.")
    tracker:chatLine("coin", "Grimble loots 40 Copper.")
    -- A boss kill during the encounter: one line arrives secret.
    tracker:unreadableLine()
    -- After the encounter: split coin and a won roll, its lines in the
    -- order the client sends them, which is unverified on Forever.
    tracker:chatLine("coin", "Your share of the loot is 1 Silver, 5 Copper.")
    tracker:chatLine("loot", "You receive loot: " .. BLADE .. ".")
    tracker:chatLine("loot", "|HlootHistory:3|h[Loot]|h: You won: " .. BLADE)
    tracker:chatLine("loot", "|HlootHistory:4|h[Loot]|h: Grimble won: " .. LINEN)
    tracker:chatLine("loot", "Grimble receives loot: " .. LINEN .. ".")
    clock.set(1800)

    local stopped = tracker:stop()

    assert.are.equal(117, stopped.rawGold)
    assert.are.equal(9026, stopped.lootedItemValue)
    assert.are.equal(1, stopped.unreadableLines)
    assert.are.same({
      [LINEN] = { quantity = 2, itemValue = 13, pricing = "vendor" },
      [BLADE] = { quantity = 1, itemValue = 9000, pricing = "vendor" },
    }, stopped.items)
  end)
end)
