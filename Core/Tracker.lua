-- Session core (ADR 0003): plain Lua 5.1 that reads no WoW global. The
-- game reaches it only through the ports passed to Tracker.new.

local _, ns = ...

local Tracker = {}
Tracker.__index = Tracker

-- ports: clock, itemFacts, priceSource, lootStrings (see the README's
-- "Session core" section).
function Tracker.new(ports)
  local tracker = setmetatable({}, Tracker)
  tracker.ports = ports
  return tracker
end

function Tracker:frameFigures()
  return {
    state = "none",
    activeTime = 0,
    rawGold = 0,
    lootedItemValue = 0,
    total = 0,
    gph = 0,
    unreadableLines = 0,
  }
end

ns.Tracker = Tracker
