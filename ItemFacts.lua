-- In-game layer: the item facts port, read with C_Item.GetItemInfo, and a
-- refresh of the tracker when item info that was not loaded arrives.

local _, ns = ...

-- Enum.ItemBind values from C_Item.GetItemInfo's bindType, and the quest
-- item class (Enum.ItemClass.Questitem).
local BIND_ON_PICKUP = 1
local BIND_QUEST = 4
local QUEST_ITEM_CLASS = 12

-- Item facts port (ADR 0003): { itemID, quality, soulbound, vendorValue }
-- for an item link, or nil while the client has not loaded the item yet.
-- An item that binds on pickup or is a quest item is soulbound.
ns.itemFacts = {
  lookup = function(itemLink)
    local name, _, quality, _, _, _, _, _, _, _, sellPrice, classID, _, bindType =
      C_Item.GetItemInfo(itemLink)
    if not name then
      return nil
    end
    return {
      itemID = ns.ItemLinks.itemID(itemLink),
      quality = quality,
      soulbound = bindType == BIND_ON_PICKUP or bindType == BIND_QUEST
        or classID == QUEST_ITEM_CLASS,
      vendorValue = sellPrice or 0,
    }
  end,
}

-- C_Item.GetItemInfo asks the server for an item it has not loaded and
-- fires this once the info arrives; refresh values the item then.
ns.on("GET_ITEM_INFO_RECEIVED", function()
  if ns.tracker then
    ns.tracker:refresh()
  end
end)
