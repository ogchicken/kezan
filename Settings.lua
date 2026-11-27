-- In-game layer: the Kezan panel in the game's Settings (Options >
-- AddOns). It chooses the price source and shows or hides the frame. Both
-- are proxy settings: the tracker and Frame.lua keep the values, so the
-- panel never holds a copy that could disagree with /kz show and hide.

local addonName, ns = ...

local PRICE_SOURCE_VARIABLE = "KEZAN_PRICE_SOURCE"
local FRAME_SHOWN_VARIABLE = "KEZAN_FRAME_SHOWN"

local PRICE_SOURCE_LABELS = {
  auctionator = "Auctionator",
  none = "None",
}

-- The price source dropdown. Auctionator is offered only while it is
-- loaded; otherwise the one option is None, labelled with the tracker's
-- reason, which the tooltip repeats.
local function addPriceSource(category)
  local function getValue()
    return (ns.tracker:priceSource())
  end

  local function setValue(name)
    ns.tracker:setPriceSource(name)
    -- Values follow the choice at once rather than at the frame's next update.
    ns.tracker:refresh()
  end

  -- The default is what the tracker picks with no choice made: Auctionator
  -- whenever it is loaded.
  local default = ns.auctionatorPrices.isLoaded() and "auctionator" or "none"
  local setting = Settings.RegisterProxySetting(category, PRICE_SOURCE_VARIABLE,
    Settings.VarType.String, "Price source", default, getValue, setValue)

  local function options()
    local container = Settings.CreateControlTextContainer()
    local _, reason = ns.tracker:priceSource()
    if reason then
      container:Add("none", ("%s. %s"):format(PRICE_SOURCE_LABELS.none, reason))
    else
      container:Add("auctionator", PRICE_SOURCE_LABELS.auctionator)
      container:Add("none", PRICE_SOURCE_LABELS.none)
    end
    return container:GetData()
  end

  local function tooltip()
    local text = "Where tradable items take their AH value from. With None,"
      .. " every item takes its vendor value."
    local _, reason = ns.tracker:priceSource()
    if reason then
      text = text .. "\n\n" .. reason
    end
    return text
  end

  Settings.CreateDropdown(category, setting, options, tooltip)
end

-- The frame checkbox. /kz show and /kz hide also go through
-- ns.setFrameShown; the hook tells the checkbox to read the value again.
local function addFrameShown(category)
  local setting = Settings.RegisterProxySetting(category, FRAME_SHOWN_VARIABLE,
    Settings.VarType.Boolean, "Show the frame", Settings.Default.True,
    ns.isFrameShown, ns.setFrameShown)
  Settings.CreateCheckbox(category, setting,
    "The small frame with the session's figures and its buttons. /kz show and /kz hide do the same.")
  hooksecurefunc(ns, "setFrameShown", function()
    setting:NotifyUpdate()
  end)
end

-- After Kezan.lua and Frame.lua have handled ADDON_LOADED: this file loads
-- after both, so its handler runs after theirs, once the tracker and the
-- frame exist.
ns.on("ADDON_LOADED", function(loadedName)
  if loadedName ~= addonName then
    return
  end
  local category = Settings.RegisterVerticalLayoutCategory("Kezan")
  addPriceSource(category)
  addFrameShown(category)
  Settings.RegisterAddOnCategory(category)
end)
