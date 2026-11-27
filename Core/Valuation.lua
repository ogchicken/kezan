-- Valuation step: the per-unit item value of one item and how it was
-- priced, by the rules of spec #3 ("Valuation rules"). Internal to the
-- session core; the session's items call it whenever they are re-valued.

local _, ns = ...

local Valuation = {}

-- How an item value was found. Stored with each item, so a stopped
-- session keeps it.
Valuation.VENDOR = "vendor"
Valuation.UNPRICED = "unpriced"

-- facts: what the item facts port returned for the item, or nil while not
-- loaded. Returns the item value in whole copper, then how it was priced.
-- With no price source every item takes its vendor value; an item with
-- none, or whose facts are not loaded, counts at 0 and is unpriced.
function Valuation.itemValue(facts)
  if facts and facts.vendorValue and facts.vendorValue > 0 then
    return facts.vendorValue, Valuation.VENDOR
  end
  return 0, Valuation.UNPRICED
end

ns.Valuation = Valuation
