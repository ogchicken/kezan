-- In-game layer: text the commands and windows share. Active time as the
-- player reads it, and the name of the zone the player is in. Money needs
-- no helper here: GetMoneyString formats it.

local _, ns = ...

-- Active time in seconds as "h:mm:ss".
function ns.activeTimeText(seconds)
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor(seconds % 3600 / 60)
  return ("%d:%02d:%02d"):format(hours, minutes, seconds % 60)
end

-- The zone the player is in, for the session's start zone: the map
-- instance name (inside an instance, the instance), else the zone text
-- (research/2026-11-27-opened-items-reload-and-zone.md, section 4). Nil
-- when neither can be read.
function ns.currentZone()
  for _, read in ipairs({ GetRealZoneText, GetZoneText }) do
    local zone = read()
    if zone ~= nil and not ns.isSecret(zone) and zone ~= "" then
      return zone
    end
  end
  return nil
end
