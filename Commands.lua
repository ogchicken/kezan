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

sessionCommand("start", "start a session", function()
  local ok, reason = ns.tracker:start()
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

sessionCommand("stop", "stop the session and print what it earned", function()
  local stopped, reason = ns.tracker:stop()
  if not stopped then
    ns.print(reason)
    return nil
  end
  ns.print(("Session stopped after %s of active time."):format(duration(stopped.activeTime)))
  print(("  Raw gold %s, looted item value %s, total %s: %s per hour."):format(
    money(stopped.rawGold), money(stopped.lootedItemValue), money(stopped.total), money(stopped.gph)))
  return true
end)
