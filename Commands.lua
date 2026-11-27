-- In-game layer: the session commands of /kz. Each calls the tracker and
-- prints the result, or the reason the tracker refused it. The frame's
-- buttons run the same commands through ns.sessionCommands.

local _, ns = ...

local function money(copper)
  return GetMoneyString(copper)
end

local function duration(seconds)
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor(seconds % 3600 / 60)
  return ("%d:%02d:%02d"):format(hours, minutes, seconds % 60)
end

ns.money = money
ns.duration = duration

-- ns.sessionCommands[name](), name as in the tracker's frame figures
-- (`commands`): runs the command, prints what happened and returns true,
-- or prints the tracker's reason and returns nil.
ns.sessionCommands = {}

local function sessionCommand(name, summary, run)
  ns.sessionCommands[name] = run
  ns.addCommand(name, summary, run)
end

-- The zone the player is in, for the session's start zone: the map
-- instance name (inside an instance, the instance), else the zone text
-- (research/2026-11-27-opened-items-reload-and-zone.md, section 4). Nil
-- when neither can be read.
local function currentZone()
  for _, read in ipairs({ GetRealZoneText, GetZoneText }) do
    local zone = read()
    if zone ~= nil and not ns.isSecret(zone) and zone ~= "" then
      return zone
    end
  end
  return nil
end

sessionCommand("start", "start a session", function()
  local ok, reason = ns.tracker:start(currentZone())
  ns.print(ok and "Session started." or reason)
  return ok
end)

sessionCommand("pause", "pause the session; loot while paused doesn't count", function()
  local ok, reason = ns.tracker:pause()
  ns.print(ok and "Session paused." or reason)
  return ok
end)

sessionCommand("resume", "resume the paused session", function()
  local ok, reason = ns.tracker:resume()
  ns.print(ok and "Session resumed." or reason)
  return ok
end)

-- Stops the session, prints what it earned and opens its summary
-- (SummaryWindow.lua). Returns true, or prints the tracker's reason and
-- returns nil. /kz stop and the frame's confirmed Stop both run it.
function ns.stopSessionAndShowSummary()
  local stopped, reason = ns.tracker:stop()
  if not stopped then
    ns.print(reason)
    return nil
  end
  ns.print(("Session stopped after %s of active time."):format(duration(stopped.activeTime)))
  print(("  Raw gold %s, looted item value %s, total %s: %s per hour."):format(
    money(stopped.rawGold), money(stopped.lootedItemValue), money(stopped.total), money(stopped.gph)))
  ns.showSummary(stopped)
  return true
end

sessionCommand("stop", "stop the session and show what it earned", ns.stopSessionAndShowSummary)
