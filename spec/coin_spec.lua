local support = require("spec.support.tracker")

describe("coin looted during a session", function()
  it("counts a gold, silver and copper line as raw gold in copper", function()
    local tracker = support.newTracker()

    tracker:start()
    tracker:chatLine("coin", "You loot 1 Gold, 2 Silver, 3 Copper")

    local figures = tracker:frameFigures()
    assert.are.equal("running", figures.state)
    assert.are.equal(10203, figures.rawGold)
  end)

  local lines = {
    { "You loot 47 Copper", 47 },
    { "You loot 3 Silver", 300 },
    { "You loot 12 Gold", 120000 },
    { "You loot 5 Silver, 9 Copper", 509 },
    { "You loot 2 Gold, 15 Copper", 20015 },
    { "You loot 1 Gold, 50 Silver", 15000 },
    { "You loot 47 Copper.", 47 },
    { "You loot 1 Gold, 2 Silver, 3 Copper.", 10203 },
  }
  for _, case in ipairs(lines) do
    local text, copper = case[1], case[2]
    it(("reads %q as %d copper"):format(text, copper), function()
      local tracker = support.newTracker()

      tracker:start()
      tracker:chatLine("coin", text)

      assert.are.equal(copper, tracker:frameFigures().rawGold)
    end)
  end

  it("adds up every coin line of the session", function()
    local tracker = support.newTracker()

    tracker:start()
    tracker:chatLine("coin", "You loot 75 Copper")
    tracker:chatLine("coin", "You loot 1 Silver, 30 Copper.")

    assert.are.equal(205, tracker:frameFigures().rawGold)
  end)
end)
