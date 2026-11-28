local support = require("spec.support.tracker")

-- The frame shows one button per command its figures offer, in this order.
describe("the commands the frame offers", function()
  it("offers Start with no session", function()
    local tracker = support.newTracker()

    assert.are.same({ "start" }, tracker:frameFigures().commands)
  end)

  it("offers Pause and Stop while the session runs", function()
    local tracker = support.newTracker()
    tracker:start()

    assert.are.same({ "pause", "stop" }, tracker:frameFigures().commands)
  end)

  it("offers Resume and Stop while the session is paused", function()
    local tracker = support.newTracker()
    tracker:start()
    tracker:pause()

    assert.are.same({ "resume", "stop" }, tracker:frameFigures().commands)
  end)

  it("offers Start again once the session is stopped", function()
    local tracker = support.newTracker()
    tracker:start()
    tracker:stop()

    assert.are.same({ "start" }, tracker:frameFigures().commands)
  end)

  it("offers Resume for a session brought back paused by a login", function()
    local savedState = {}
    support.newTracker({ savedState = savedState }):start()
    local tracker = support.newTracker({ savedState = savedState })

    tracker:gameLoaded("login")

    assert.are.same({ "resume", "stop" }, tracker:frameFigures().commands)
  end)

  -- A button the frame shows must never be refused, and a command it hides
  -- must never apply.
  local states = {
    none = function() end,
    running = function(tracker)
      tracker:start()
    end,
    paused = function(tracker)
      tracker:start()
      tracker:pause()
    end,
  }
  for state, reach in pairs(states) do
    it(("offers exactly the commands the tracker accepts when %s"):format(state), function()
      for _, command in ipairs({ "start", "pause", "resume", "stop" }) do
        local tracker = support.newTracker()
        reach(tracker)
        local offered = false
        for _, name in ipairs(tracker:frameFigures().commands) do
          offered = offered or name == command
        end

        local accepted = tracker[command](tracker) ~= nil

        assert.are.equal(offered, accepted, command)
      end
    end)
  end
end)
