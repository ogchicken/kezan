-- In-game layer: the session commands of /kz. Each calls the tracker and
-- prints the result, or the reason the tracker refused it.

local _, ns = ...

local function money(copper)
  return GetMoneyString(copper)
end

local function duration(seconds)
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor(seconds % 3600 / 60)
  return ("%d:%02d:%02d"):format(hours, minutes, seconds % 60)
end

ns.addCommand("start", "start a session", function()
  local ok, reason = ns.tracker:start()
  ns.print(ok and "Session started." or reason)
end)

ns.addCommand("stop", "stop the session and print what it earned", function()
  local stopped, reason = ns.tracker:stop()
  if not stopped then
    ns.print(reason)
    return
  end
  ns.print(("Session stopped. Raw gold %s in %s of active time: %s per hour."):format(
    money(stopped.rawGold), duration(stopped.activeTime), money(stopped.gph)))
end)
