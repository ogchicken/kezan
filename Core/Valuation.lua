-- Valuation step: the per-unit item value of one item and how it was
-- priced, by the rules of spec #3 ("Valuation rules"). Internal to the
-- session core; the session's items call it whenever they are re-valued.

local _, ns = ...

local Valuation = {}

-- How an item value was found. Stored with each item, so a stopped
-- session keeps it.
Valuation.AH = "ah"
Valuation.STALE = "stale"
Valuation.VENDOR = "vendor"
Valuation.UNPRICED = "unpriced"

-- Item quality of a grey (Enum.ItemQuality.Poor).
local POOR = 0

-- An AH value older than this many whole days is stale. It is still used.
local FRESH_DAYS = 3

-- link: the item link; facts: what the item facts port returned for it, or
-- nil while not loaded; priceSource: the price source port, or nil for
-- None. Returns the item value in whole copper, then how it was priced.
function Valuation.itemValue(link, facts, priceSource)
  if not facts then
    return 0, Valuation.UNPRICED
  end
  -- Greys and soulbound items take their vendor value: noisy AH prices for
  -- vendor trash, and gear that can't be sold on the AH.
  local tradable = facts.quality ~= POOR and not facts.soulbound
  if tradable and priceSource then
    local copper, ageDays, ageUnsupported = priceSource.ahValue(link)
    if copper then
      -- An unknown age is stale, unless the source can't tell ages at all:
      -- then nothing is marked stale.
      if not ageUnsupported and (ageDays == nil or ageDays > FRESH_DAYS) then
        return copper, Valuation.STALE
      end
      return copper, Valuation.AH
    end
  end
  if facts.vendorValue and facts.vendorValue > 0 then
    return facts.vendorValue, Valuation.VENDOR
  end
  return 0, Valuation.UNPRICED
end

ns.Valuation = Valuation
