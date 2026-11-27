local addonName, ns = ...

Kezan = ns
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"

local DB_SCHEMA_VERSION = 1

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, loadedName)
  if loadedName ~= addonName then
    return
  end
  KezanDB = KezanDB or { schemaVersion = DB_SCHEMA_VERSION }
  ns.db = KezanDB
  self:UnregisterEvent("ADDON_LOADED")
end)

SLASH_KEZAN1 = "/kezan"
SLASH_KEZAN2 = "/kz"
SlashCmdList.KEZAN = function()
  print(("|cffd4af37Kezan|r %s loaded."):format(ns.version))
end
