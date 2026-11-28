-- What an item link says about its item. Plain functions on the link text,
-- so the in-game layer reads links with them too.

local _, ns = ...

local ItemLinks = {}

-- The item ID in an item link, such as 2447 in "|Hitem:2447::...", or nil
-- when the text holds no item.
function ItemLinks.itemID(link)
  return tonumber(link:match("|Hitem:(%d+)"))
end

-- The fields of an item string before the player's level: the item ID,
-- the enchant, four gems, the suffix and the unique ID.
local FIELDS_BEFORE_LEVEL = 8

-- The link with the fields that describe the looting player blanked: the
-- player's level and specialization, which the client writes into every
-- link. Two links with the same key are the same item.
function ItemLinks.sameItemKey(link)
  local key = link:gsub("(|Hitem:" .. ("[^:|]*:"):rep(FIELDS_BEFORE_LEVEL) .. ")[^:|]*:[^:|]*", "%1:", 1)
  return key
end

ns.ItemLinks = ItemLinks
