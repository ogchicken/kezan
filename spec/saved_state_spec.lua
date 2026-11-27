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
