-- In-game layer: game-loaded and game-unloading adapters. They tell the
-- tracker when the client loads (a UI reload or an initial login) and when
-- it is about to write the saved variables
-- (research/2026-11-27-opened-items-reload-and-zone.md, section 3).

local _, ns = ...

local function isSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

-- PLAYER_ENTERING_WORLD also fires on every loading screen between zones,
-- with both flags false; that is not a game load. A flag that can't be read
-- counts as a login, so that time logged out can never count.
ns.on("PLAYER_ENTERING_WORLD", function(isInitialLogin, isReloadingUi)
  local tracker = ns.tracker
  if not tracker then
    return
  end
  if isSecret(isInitialLogin) or isSecret(isReloadingUi) or isInitialLogin then
    tracker:gameLoaded("login")
  elseif isReloadingUi then
    tracker:gameLoaded("reload")
  end
end)

-- The last event before the client writes the saved variables, on logout,
-- disconnect, quit and /reload.
ns.on("PLAYER_LOGOUT", function()
  if ns.tracker then
    ns.tracker:gameUnloading()
  end
end)
