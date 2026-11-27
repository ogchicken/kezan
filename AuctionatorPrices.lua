-- In-game layer: the Auctionator price source port (ADR 0001 and its
-- amendment). Only Auctionator's public v1 API is called; no Auctionator
-- code is copied here.

local _, ns = ...

-- Auctionator asks every caller to name itself.
local CALLER_ID = "Kezan"

local function isLoaded()
  return C_AddOns.IsAddOnLoaded("Auctionator") and Auctionator ~= nil
    and Auctionator.API ~= nil and Auctionator.API.v1 ~= nil
end

-- The AH value from the two supported price calls: by item link, falling
-- back to the item ID. nil means no data, never zero.
local function ahCopper(api, itemLink)
  local copper = api.GetAuctionPriceByItemLink(CALLER_ID, itemLink)
  if copper == nil then
    local itemID = tonumber(itemLink:match("|Hitem:(%d+)"))
    if itemID then
      copper = api.GetAuctionPriceByItemID(CALLER_ID, itemID)
    end
  end
  return copper
end

-- Price source port (shaped like support.fakePriceSource): the AH value in
-- copper or nil, then its age in whole days or nil when unknown, then true
-- when the age can't be told at all. The age comes from the undocumented
-- GetAuctionAgeByItemLink, so it is called only when it exists and inside
-- pcall; when it is missing or fails, the age is unknown and no price is
-- marked stale.
ns.auctionatorPrices = {
  isLoaded = isLoaded,
  ahValue = function(itemLink)
    if not isLoaded() then
      return nil, nil, true
    end
    local api = Auctionator.API.v1
    local copper = ahCopper(api, itemLink)
    if copper == nil then
      return nil, nil
    end
    if type(api.GetAuctionAgeByItemLink) ~= "function" then
      return copper, nil, true
    end
    local ok, ageDays = pcall(api.GetAuctionAgeByItemLink, CALLER_ID, itemLink)
    if not ok then
      return copper, nil, true
    end
    -- nil: never seen, or older than Auctionator's price history (stale).
    return copper, ageDays
  end,
}
