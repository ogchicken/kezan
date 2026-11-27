-- Session core (ADR 0003): plain Lua 5.1 that reads no WoW global. The
-- game reaches it only through the ports passed to Tracker.new.

local _, ns = ...

local Tracker = {}
Tracker.__index = Tracker

local SECONDS_PER_HOUR = 3600

-- ports: clock, itemFacts, lootStrings (each documented with its fake in
-- spec/support/tracker.lua), priceSources, and two options:
-- - priceSources: the price source ports of the price addons that are
--   loaded, by name; today only `auctionator`. Each is shaped like
--   support.fakePriceSource. A source missing from it is not loaded.
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
  tracker.saved.history = tracker.saved.history or {}
  tracker.priceSources = ports.priceSources or {}
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

-- Price sources by the name kept as the choice in saved state.
local AUCTIONATOR = "auctionator"
local NONE = "none"

-- The price source item values come from: "auctionator" or "none", then,
-- when it is None only because Auctionator is not loaded, the reason. The
-- choice is kept in saved state (account-wide); with no choice made it is
-- Auctionator whenever Auctionator is loaded.
function Tracker:priceSource()
  if self.saved.priceSource == NONE then
    return NONE
  elseif self.priceSources[AUCTIONATOR] then
    return AUCTIONATOR
  end
  return NONE, "Auctionator is not loaded."
end

-- Keeps the price source choice, "auctionator" or "none", in saved state.
-- Item values follow it at the next refresh.
function Tracker:setPriceSource(name)
  self.saved.priceSource = name
  return true
end

-- What valuing an item reads: the item facts port and the chosen price
-- source's port, nil for None.
function Tracker:valuationPorts()
  return {
    itemFacts = self.ports.itemFacts,
    priceSource = self.priceSources[self:priceSource()],
  }
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
--
-- zone: the name of the zone the session starts in, kept for the summary;
-- nil when the in-game layer could not tell.
function Tracker:start(zone)
  local current = self:currentSession()
  if current and current.state == "paused" then
    return nil, "A session is already paused. Resume or stop it first."
  elseif current then
    return nil, "A session is already running."
  end
  local now = self.ports.clock.now()
  self:setCurrentSession({
    state = "running",
    startZone = zone,
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

-- Ends the session and keeps it in the history (see Core/Summary.lua),
-- its item values frozen as they are now. Returns its summary: the stored
-- session's fields, `items` and `topItems`, and `state` as it was at stop
-- ("running" or "paused").
function Tracker:stop()
  local session = self:currentSession()
  if not session then
    return nil, "There is no session to stop."
  end
  local now = self.ports.clock.now()
  ns.Items.refresh(session, self:valuationPorts())
  local stored = ns.Summary.stored(session, figuresOf(session, now), self.character, now)
  table.insert(self.saved.history, stored)
  self:setCurrentSession(nil)
  local summary = ns.Summary.of(stored)
  summary.state = session.state
  return summary
end

-- The summary of this character's latest stopped session, the same as
-- stop returned but without `state`, or nil and a reason when there is
-- none.
function Tracker:lastSummary()
  local history = self.saved.history
  for index = #history, 1, -1 do
    if history[index].character == self.character then
      return ns.Summary.of(history[index])
    end
  end
  return nil, "No session has been stopped on this character yet."
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
  if not session or self.windowFromOldStock then
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
      ns.Items.add(session, link, quantity, self:valuationPorts())
    end
  end
end

-- A notice that a loot window opened from an item (ADR 0004, opened
-- items): a clam, a lockbox or an item being disenchanted. itemID is that
-- item's item ID, or nil when the in-game layer could not tell which item
-- it was.
--
-- If the session holds a unit of the item, that unit leaves the session
-- and the window's contents count. If it holds none, the item was in the
-- bags before the session started, so no line counts until the window
-- closes. An unknown item removes nothing and its contents count. Only one
-- loot window is open at a time, so a new one replaces the last.
--
-- The window is not saved: a reload or logout closes it.
function Tracker:lootWindowOpened(itemID)
  self.windowFromOldStock = nil
  local session = self:runningSession()
  if session and itemID then
    self.windowFromOldStock = not ns.Items.remove(session, itemID)
  end
end

-- A notice that the loot window closed: lines count as usual again.
function Tracker:lootWindowClosed()
  self.windowFromOldStock = nil
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
    ns.Items.refresh(session, self:valuationPorts())
  end
end

-- The commands that apply in each state, in the order the frame shows
-- their buttons. Each is the name of a tracker method.
local COMMANDS = {
  none = { "start" },
  running = { "pause", "stop" },
  paused = { "resume", "stop" },
}

-- The figures the frame shows, with `commands`: the commands that apply
-- now (see COMMANDS). Read after refresh, so that item values are current.
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
      commands = COMMANDS.none,
    }
  end
  local figures = figuresOf(session, self.ports.clock.now())
  figures.commands = COMMANDS[session.state]
  return figures
end

ns.Tracker = Tracker
