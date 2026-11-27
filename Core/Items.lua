-- The looted items of a session: one entry per distinct item, holding the
-- quantity looted and the item value it was last given. Internal to the
-- session core; only the tracker calls it.
--
-- An entry is keyed by the link the item was first looted with: a real
-- link, which the summary shows and the price source and item facts are
-- asked about. A later drop of the same item adds to it even when its link
-- differs in a field that describes the looting player rather than the
-- item (see ItemLinks.sameItemKey).
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

-- The link the session holds the item under, or nil if it holds none.
local function heldLink(session, link)
  if session.items[link] then
    return link
  end
  local key = ns.ItemLinks.sameItemKey(link)
  for held in pairs(session.items) do
    if ns.ItemLinks.sameItemKey(held) == key then
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

-- Takes one unit of the item with this item ID out of the session, for an
-- opened item. An item whose quantity reaches 0 leaves the session. Returns
-- true if the session held a unit, else false.
function Items.remove(session, itemID)
  for link, entry in pairs(session.items or {}) do
    if ns.ItemLinks.itemID(link) == itemID and entry.quantity > 0 then
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
