-- The looted items of a session: one entry per distinct item, holding the
-- quantity looted and the item value it was last given. Internal to the
-- session core; only the tracker calls it.
--
-- An entry is keyed by the link the item was first looted with: a real
-- link, which the summary shows and the price source and item facts are
-- asked about. A later drop of the same item adds to it even when its link
-- differs in a field that describes the looting player rather than the
-- item (see sameItemKey).
--
-- session.items[itemLink] = {
--   quantity = <n>,          -- every drop of the item added up
--   itemValue = <copper>,    -- per unit, from the last valuation
--   pricing = "ah" | "stale" | "vendor" | "unpriced",
-- }

local _, ns = ...

local Items = {}

-- Gives one item its item value from the ports.
local function value(entry, link, ports)
  entry.itemValue, entry.pricing =
    ns.Valuation.itemValue(link, ports.itemFacts.lookup(link), ports.priceSource)
end

-- The fields of an item string before the player's level: the item ID,
-- the enchant, four gems, the suffix and the unique ID.
local FIELDS_BEFORE_LEVEL = 8

-- The link with the fields that describe the looting player blanked: the
-- player's level and specialization, which the client writes into every
-- link. Two links with the same key are the same item.
local function sameItemKey(link)
  local key = link:gsub("(|Hitem:" .. ("[^:|]*:"):rep(FIELDS_BEFORE_LEVEL) .. ")[^:|]*:[^:|]*", "%1:", 1)
  return key
end

-- The link the session holds the item under, or nil if it holds none.
local function heldLink(session, link)
  if session.items[link] then
    return link
  end
  local key = sameItemKey(link)
  for held in pairs(session.items) do
    if sameItemKey(held) == key then
      return held
    end
  end
  return nil
end

-- Adds a drop of `quantity` units of the item to the session, and values
-- the item.
function Items.add(session, link, quantity, ports)
  session.items = session.items or {}
  link = heldLink(session, link) or link
  local entry = session.items[link]
  if not entry then
    entry = { quantity = 0 }
    session.items[link] = entry
  end
  entry.quantity = entry.quantity + quantity
  value(entry, link, ports)
end

-- The item ID in an item link, such as 2447 in "|Hitem:2447::...".
local function itemIDOf(link)
  return tonumber(link:match("|Hitem:(%d+)"))
end

-- Takes one unit of the item with this item ID out of the session, for an
-- opened item. An item whose quantity reaches 0 leaves the session. Returns
-- true if the session held a unit, else false.
function Items.remove(session, itemID)
  for link, entry in pairs(session.items or {}) do
    if itemIDOf(link) == itemID and entry.quantity > 0 then
      entry.quantity = entry.quantity - 1
      if entry.quantity == 0 then
        session.items[link] = nil
      end
      return true
    end
  end
  return false
end

-- Re-values every item of the session from the ports.
function Items.refresh(session, ports)
  for link, entry in pairs(session.items or {}) do
    value(entry, link, ports)
  end
end

-- The sum over the session's items of quantity times item value.
function Items.lootedItemValue(session)
  local total = 0
  for _, entry in pairs(session.items or {}) do
    total = total + entry.quantity * entry.itemValue
  end
  return total
end

ns.Items = Items
