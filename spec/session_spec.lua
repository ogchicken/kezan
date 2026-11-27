local support = require("spec.support.tracker")

describe("starting and stopping a session", function()
  it("refuses to start a second session while one is running", function()
    local tracker = support.newTracker()
    tracker:start()
    tracker:chatLine("coin", "You loot 5 Silver")

    local ok, reason = tracker:start()

    assert.is_nil(ok)
    assert.are.equal("A session is already running.", reason)
    assert.are.equal(500, tracker:frameFigures().rawGold)
  end)

  it("refuses to stop when there is no session", function()
    local tracker = support.newTracker()

    local result, reason = tracker:stop()

    assert.is_nil(result)
    assert.are.equal("There is no session to stop.", reason)
  end)

  it("ends the session at stop and reports what it earned", function()
    local clock = support.fakeClock(1000)
    local tracker = support.newTracker({ clock = clock })
    assert.is_true(tracker:start())
    tracker:chatLine("coin", "You loot 3 Gold")
    clock.set(1000 + 1800)

    local stopped = tracker:stop()

    assert.are.equal(1800, stopped.activeTime)
    assert.are.equal(30000, stopped.rawGold)
    assert.are.equal(60000, stopped.gph)
    assert.are.equal("none", tracker:frameFigures().state)
  end)

  it("ignores coin looted with no session running", function()
    local tracker = support.newTracker()
    tracker:chatLine("coin", "You loot 9 Silver")
    tracker:start()
    tracker:chatLine("coin", "You loot 1 Silver")
    tracker:stop()
    tracker:chatLine("coin", "You loot 4 Silver")

    assert.are.equal(0, tracker:frameFigures().rawGold)
    tracker:start()
    assert.are.equal(0, tracker:frameFigures().rawGold)
  end)
end)

describe("the figures of a running session", function()
  it("takes active time from the clock and GPH from raw gold per hour", function()
    local clock = support.fakeClock(500)
    local tracker = support.newTracker({ clock = clock })
    tracker:start()
    clock.set(500 + 600)
    tracker:chatLine("coin", "You loot 2 Silver")
    clock.set(500 + 900)

    local figures = tracker:frameFigures()

    assert.are.equal(900, figures.activeTime)
    assert.are.equal(200, figures.rawGold)
    assert.are.equal(200, figures.total)
    assert.are.equal(800, figures.gph)
  end)

  it("shows GPH 0 while active time is 0", function()
    local tracker = support.newTracker()
    tracker:start()
    tracker:chatLine("coin", "You loot 8 Gold")

    local figures = tracker:frameFigures()

    assert.are.equal(0, figures.activeTime)
    assert.are.equal(80000, figures.rawGold)
    assert.are.equal(0, figures.gph)
  end)

  it("counts lines that arrived unreadable", function()
    local tracker = support.newTracker()
    tracker:start()
    tracker:unreadableLine()
    tracker:chatLine("coin", "You loot 4 Copper")
    tracker:unreadableLine()

    local figures = tracker:frameFigures()

    assert.are.equal(2, figures.unreadableLines)
    assert.are.equal(4, figures.rawGold)
  end)

  it("does not count an unreadable line with no session running", function()
    local tracker = support.newTracker()
    tracker:unreadableLine()
    tracker:start()

    assert.are.equal(0, tracker:frameFigures().unreadableLines)
  end)
end)
