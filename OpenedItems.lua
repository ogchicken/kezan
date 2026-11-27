-- In-game layer: tells the tracker when a loot window opens from an item
-- (a clam, a lockbox, an item being disenchanted) and which item it was
-- (ADR 0004, opened items; research/2026-11-27-opened-items-reload-and-zone.md,
-- section 2).
--
-- The window's own loot source names the item: a source GUID starting
-- "Item-" marks an opened item. The GUID is turned into an item ID through
-- a map of bag item GUIDs, with C_Item.GetItemIDByGUID as a second try. A
-- read-only hook on using a container item, and the Disenchant spellcast,
-- are the fallback.

local _, ns = ...

local isSecret = ns.isSecret

-- Item ID by GUID of every item seen in the bags since the UI loaded. An
-- entry is never removed: a GUID names one item for good, and the map must
-- still answer once the last unit of a stack has been opened.
local itemIDByGUID = {}

local function scanBags()
  for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
      if C_Item.DoesItemExist(location) then
        local guid = C_Item.GetItemGUID(location)
        local itemID = C_Container.GetContainerItemID(bag, slot)
        if guid and itemID and not isSecret(guid) and not isSecret(itemID) then
          itemIDByGUID[guid] = itemID
        end
      end
    end
  end
end

ns.on("PLAYER_ENTERING_WORLD", scanBags)
ns.on("BAG_UPDATE_DELAYED", scanBags)

-- Fallbacks, when the window's source can't be read: the last container
-- item used that holds loot, or the last item disenchanted. Both come from
-- a hook that runs after C_Container.UseContainerItem, which the bags call
-- on a right-click and, while Disenchant waits for its target, on the
-- left-click that picks it (research note, section 2). The hook only
-- reads: one that calls anything protected is blocked
-- (ADDON_ACTION_FORBIDDEN).
local USE_WINDOW_SECONDS = 5
-- Disenchant's cast follows the click that picks its item.
local CAST_WINDOW_SECONDS = 10
local DISENCHANT_SPELL_ID = 13262

local lastOpen -- the item a loot window should come from: { itemID, at }
local lastTarget -- the last item used that holds no loot: { itemID, at }

hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
  if isSecret(bag) or isSecret(slot) then
    return
  end
  local info = C_Container.GetContainerItemInfo(bag, slot)
  if not info or isSecret(info.hasLoot) or isSecret(info.itemID) then
    return
  end
  local use = { itemID = info.itemID, at = GetTime() }
  if info.hasLoot then
    lastOpen = use
  else
    -- Only a Disenchant cast tells that this use opens a loot window.
    lastTarget = use
  end
end)

-- The player's Disenchant succeeded: the item picked just before is the
-- one whose window opens next. The cast alone can't tell which item it was.
ns.on("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
  if isSecret(unit) or isSecret(spellID) or unit ~= "player" or spellID ~= DISENCHANT_SPELL_ID then
    return
  end
  local target = lastTarget
  lastTarget = nil
  if target and GetTime() - target.at <= CAST_WINDOW_SECONDS then
    lastOpen = { itemID = target.itemID, at = GetTime() }
  end
end)

-- The item ID of a container item used, or an item disenchanted, in the
-- last few seconds, or nil. Taken once, so that it names one window at
-- most.
local function takeRecentUse()
  local use = lastOpen
  lastOpen = nil
  if use and GetTime() - use.at <= USE_WINDOW_SECONDS then
    return use.itemID
  end
  return nil
end

-- The first readable "Item-" GUID among GetLootSourceInfo's guid, quantity
-- pairs, or nil, and whether any source GUID could be read at all.
local function itemSourceIn(...)
  local readable = false
  for i = 1, select("#", ...), 2 do
    local guid = select(i, ...)
    if type(guid) == "string" and not isSecret(guid) then
      if guid:match("^Item%-") then
        return guid, true
      end
      readable = true
    end
  end
  return nil, readable
end

-- The open window's source: "item" and the item GUID, "other" for a corpse,
-- node or chest, "unreadable" when no slot has a source that can be read
-- (secret GUIDs), or "empty" when the window has no slot yet.
local function windowSource()
  local slots = GetNumLootItems()
  if isSecret(slots) then
    return "unreadable"
  elseif slots == 0 then
    return "empty"
  end
  local anyReadable = false
  for slot = 1, slots do
    local guid, readable = itemSourceIn(GetLootSourceInfo(slot))
    if guid then
      return "item", guid
    end
    anyReadable = anyReadable or readable
  end
  return anyReadable and "other" or "unreadable"
end

local function itemIDFor(guid)
  if not itemIDByGUID[guid] then
    scanBags()
  end
  local itemID = itemIDByGUID[guid]
  if not itemID then
    itemID = C_Item.GetItemIDByGUID(guid)
    if isSecret(itemID) then
      itemID = nil
    end
  end
  return itemID
end

-- LOOT_READY can fire more than once for one window; read each window once.
-- The source names the window, since a new one can open before LOOT_CLOSED.
local readSource

ns.on("LOOT_READY", function()
  local tracker = ns.tracker
  if not tracker then
    return
  end
  local kind, guid = windowSource()
  local key = guid or kind
  -- An empty window has nothing to count; its slots may come with a later
  -- LOOT_READY, so it is not read yet.
  if kind == "empty" or readSource == key then
    return
  end
  readSource = key
  if kind == "item" then
    tracker:lootWindowOpened(itemIDFor(guid) or takeRecentUse())
  elseif kind == "unreadable" then
    -- Possibly an opened item; nil reports it as unknown.
    tracker:lootWindowOpened(takeRecentUse())
  else
    -- Not from an item: it replaces any earlier window.
    tracker:lootWindowClosed()
  end
end)

ns.on("LOOT_CLOSED", function()
  readSource = nil
  if ns.tracker then
    ns.tracker:lootWindowClosed()
  end
end)
