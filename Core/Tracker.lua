-- Session core (ADR 0003): plain Lua 5.1 that reads no WoW global. The
-- game reaches it only through the ports passed to Tracker.new.

local _, ns = ...

local Tracker = {}
Tracker.__index = Tracker

local SECONDS_PER_HOUR = 3600

-- ports: clock, itemFacts, priceSource, lootStrings (each documented with its
-- fake in spec/support/tracker.lua), and two options:
-- - savedState: the table the in-game layer stores as KezanDB. The tracker
--   keeps its state there as it changes, so a tracker built later on the
--   same table carries on where this one left off.
-- - character: "Name-Realm", the key of this character's current session.
function Tracker.new(ports)
  local tracker = setmetatable({}, Tracker)
  tracker.ports = ports
  tracker.character = ports.character
  tracker.saved = ports.savedState
  tracker.saved.currentSessions = tracker.saved.currentSessions or {}
  tracker.lines = ns.LootLines.new(ports.lootStrings)
  return tracker
end

-- The character's current session (running or paused) in saved state, or
-- nil. A stored session is plain data: strings, numbers and tables.
function Tracker:currentSession()
  return self.saved.currentSessions[self.character]
end

function Tracker:setCurrentSession(session)
  self.saved.currentSessions[self.character] = session
end

-- The current session if it is counting loot, else nil.
function Tracker:runningSession()
  local session = self:currentSession()
  if session and session.state == "running" then
    return session
  end
  return nil
end

-- Active time is the seconds accumulated before the current run plus the
-- time since the current run started.
local function activeTime(session, now)
  local seconds = session.accumulatedSeconds
  if session.state == "running" then
    seconds = seconds + (now - session.runStartedAt)
  end
  return seconds
end

local function figuresOf(session, now)
  local seconds = activeTime(session, now)
  local lootedItemValue = 0
  local total = session.rawGold + lootedItemValue
  local gph = 0
  if seconds > 0 then
    gph = math.floor(total * SECONDS_PER_HOUR / seconds)
  end
  return {
    state = session.state,
    activeTime = seconds,
    rawGold = session.rawGold,
    lootedItemValue = lootedItemValue,
    total = total,
    gph = gph,
    unreadableLines = session.unreadableLines,
  }
end

-- Commands return a true value on success, or nil and a reason the slash
-- command can print.
function Tracker:start()
  if self:currentSession() then
    return nil, "A session is already running."
  end
  local now = self.ports.clock.now()
  self:setCurrentSession({
    state = "running",
    startedAt = now,
    runStartedAt = now,
    accumulatedSeconds = 0,
    rawGold = 0,
    unreadableLines = 0,
  })
  return true
end

-- Returns the stopped session's figures.
function Tracker:stop()
  local session = self:currentSession()
  if not session then
    return nil, "There is no session to stop."
  end
  local figures = figuresOf(session, self.ports.clock.now())
  self:setCurrentSession(nil)
  return figures
end

-- kind: "coin" (CHAT_MSG_MONEY) or "loot" (CHAT_MSG_LOOT); text: the raw
-- chat text, already checked not to be secret.
function Tracker:chatLine(kind, text)
  local session = self:runningSession()
  if not session then
    return
  end
  if kind == "coin" then
    local copper = self.lines:ownCoinCopper(text)
    if copper then
      session.rawGold = session.rawGold + copper
    end
  end
end

-- A notice that a loot or coin line arrived secret, so its text could not
-- be read.
function Tracker:unreadableLine()
  local session = self:runningSession()
  if session then
    session.unreadableLines = session.unreadableLines + 1
  end
end

function Tracker:frameFigures()
  local session = self:currentSession()
  if not session then
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
  return figuresOf(session, self.ports.clock.now())
end

ns.Tracker = Tracker
