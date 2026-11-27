local support = require("spec.support.tracker")

describe("a tracker with no session", function()
  it("shows zero figures and the state none", function()
    local tracker = support.newTracker()

    assert.are.same({
      state = "none",
      activeTime = 0,
      rawGold = 0,
      lootedItemValue = 0,
      total = 0,
      gph = 0,
      unreadableLines = 0,
    }, tracker:frameFigures())
  end)
end)
