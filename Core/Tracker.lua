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
  local lootedItemValue = ns.Items.lootedItemValue(session)
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
  local current = self:currentSession()
  if current and current.state == "paused" then
    return nil, "A session is already paused. Resume or stop it first."
  elseif current then
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

-- Pausing adds the current run to the accumulated seconds.
function Tracker:pause()
  local session = self:currentSession()
  if not session then
    return nil, "There is no session to pause."
  elseif session.state == "paused" then
    return nil, "The session is already paused."
  end
  local now = self.ports.clock.now()
  session.accumulatedSeconds = activeTime(session, now)
  session.state = "paused"
  return true
end

function Tracker:resume()
  local session = self:currentSession()
  if not session then
    return nil, "There is no session to resume."
  elseif session.state == "running" then
    return nil, "The session is already running."
  end
  session.runStartedAt = self.ports.clock.now()
  session.state = "running"
  return true
end

-- Returns the stopped session's figures, with `items`: its looted items
-- by item link, each { quantity, itemValue, pricing }.
function Tracker:stop()
  local session = self:currentSession()
  if not session then
    return nil, "There is no session to stop."
  end
  ns.Items.refresh(session, self.ports)
  local figures = figuresOf(session, self.ports.clock.now())
  figures.items = session.items or {}
  self:setCurrentSession(nil)
  return figures
end

-- A notice that the game is unloading, just before the client writes the
-- saved variables. The current session records the time as its last save.
function Tracker:gameUnloading()
  local session = self:currentSession()
  if session then
    session.lastSavedAt = self.ports.clock.now()
  end
end

-- A notice that the game loaded. kind: "reload" (a UI reload) or "login"
-- (an initial login). A running session's run ends at its last save: the
-- time since was spent in a loading screen or logged out, so it never
-- counts. After a reload a new run starts now; after a login the session
-- is paused. A paused session is left as it is.
function Tracker:gameLoaded(kind)
  local session = self:runningSession()
  if not session then
    return
  end
  -- With no last save on record, the end of the run is unknown, so none of
  -- it counts rather than risk counting time logged out.
  local savedAt = session.lastSavedAt or session.runStartedAt
  session.accumulatedSeconds = session.accumulatedSeconds
    + math.max(0, savedAt - session.runStartedAt)
  session.lastSavedAt = nil
  if kind == "reload" then
    session.runStartedAt = self.ports.clock.now()
  else
    session.state = "paused"
  end
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
  elseif kind == "loot" then
    local link, quantity = self.lines:ownDrop(text)
    if link then
      ns.Items.add(session, link, quantity, self.ports)
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

-- Re-values every item of the current session from the ports: item facts
-- that have loaded since, and prices that have changed. Called by the frame
-- and when late item info arrives.
function Tracker:refresh()
  local session = self:currentSession()
  if session then
    ns.Items.refresh(session, self.ports)
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
