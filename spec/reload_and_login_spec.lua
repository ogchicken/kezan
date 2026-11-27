local support = require("spec.support.tracker")

-- The game unloads (the save) and loads again (a UI reload or a login): the
-- saved state carries over to a tracker built at load, as KezanDB does.
local function unloadAndLoad(tracker, ports, loadedAt, kind)
  tracker:gameUnloading()
  ports.clock.set(loadedAt)
  local later = support.newTracker({
    clock = ports.clock, savedState = ports.savedState, character = ports.character,
  })
  later:gameLoaded(kind)
  return later
end

describe("a UI reload", function()
  it("keeps a running session running and leaves the reload out of active time", function()
    local tracker, ports = support.newTracker({ clock = support.fakeClock(0) })
    tracker:start()
    tracker:chatLine("coin", "You loot 3 Gold")
    ports.clock.set(600)

    local later = unloadAndLoad(tracker, ports, 640, "reload")
    later:chatLine("coin", "You loot 1 Gold")
    ports.clock.set(1240)

    local figures = later:frameFigures()
    assert.are.equal("running", figures.state)
    assert.are.equal(1200, figures.activeTime)
    assert.are.equal(40000, figures.rawGold)
    assert.are.equal(120000, figures.gph)
  end)
end)

describe("an initial login", function()
  it("brings a running session back paused, its run ending at the last save", function()
    local tracker, ports = support.newTracker({ clock = support.fakeClock(0) })
    tracker:start()
    tracker:chatLine("coin", "You loot 2 Gold")
    ports.clock.set(900)

    local later = unloadAndLoad(tracker, ports, 900 + 8 * 3600, "login")
    later:chatLine("coin", "You loot 9 Gold")
    ports.clock.set(900 + 9 * 3600)

    local figures = later:frameFigures()
    assert.are.equal("paused", figures.state)
    assert.are.equal(900, figures.activeTime)
    assert.are.equal(20000, figures.rawGold)
    assert.are.equal(80000, figures.gph)
  end)

  it("counts no time logged out once the session is resumed", function()
    local tracker, ports = support.newTracker({ clock = support.fakeClock(0) })
    tracker:start()
    ports.clock.set(600)

    local later = unloadAndLoad(tracker, ports, 5000, "login")
    ports.clock.set(5100)
    assert.is_true(later:resume())
    ports.clock.set(5400)

    assert.are.equal(900, later:frameFigures().activeTime)
  end)

  it("keeps a paused session paused with the active time it had", function()
    local tracker, ports = support.newTracker({ clock = support.fakeClock(0) })
    tracker:start()
    ports.clock.set(300)
    tracker:pause()
    ports.clock.set(700)

    local later = unloadAndLoad(tracker, ports, 4000, "login")
    ports.clock.set(4500)

    local figures = later:frameFigures()
    assert.are.equal("paused", figures.state)
    assert.are.equal(300, figures.activeTime)
  end)
end)

describe("two characters on one account", function()
  it("brings back each character's own session and leaves the other's untouched", function()
    local clock = support.fakeClock(0)
    local savedState = {}
    local function logIn(character, at)
      clock.set(at)
      local tracker = support.newTracker({ clock = clock, savedState = savedState, character = character })
      tracker:gameLoaded("login")
      return tracker
    end

    local alt = logIn("Grimble-Mograine", 0)
    alt:start()
    alt:chatLine("coin", "You loot 5 Silver")
    clock.set(1000)
    alt:gameUnloading()

    local main = logIn("Grimble-Stormreaver", 1100)
    main:start()
    clock.set(2000)
    main:gameUnloading()

    alt = logIn("Grimble-Mograine", 3000)
    local altFigures = alt:frameFigures()
    assert.are.equal("paused", altFigures.state)
    assert.are.equal(1000, altFigures.activeTime)
    assert.are.equal(500, altFigures.rawGold)
    alt:resume()
    clock.set(3500)
    alt:gameUnloading()

    main = logIn("Grimble-Stormreaver", 4000)
    local mainFigures = main:frameFigures()
    assert.are.equal("paused", mainFigures.state)
    assert.are.equal(900, mainFigures.activeTime)
    assert.are.equal(0, mainFigures.rawGold)
  end)
end)
