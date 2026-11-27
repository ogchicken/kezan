# Coding standards

Read at review time. The first checks come from the platform research of 27 November 2026 (`research/2026-11-27-name-and-platform.md`); lint and tests will enforce what they can once the toolchain exists. Add a check here when a defect passes every automated check.

## Modern API only

Forever runs the Mainline API (Interface 16001). Use `C_Item.GetItemInfo`, `C_Container.GetContainerItemInfo`, `C_AddOns.GetAddOnMetadata` and their siblings, never the removed globals. Item info can arrive late: handle a nil result and retry on `GET_ITEM_INFO_RECEIVED` or with `Item:ContinueOnItemLoad`.

## Register only events that exist

Registering an event the client does not have raises an error. A new event goes in only after it has been seen to fire on the Forever client, and the pull request says so.

## One global namespace

The addon exposes two globals of its own: the `Kezan` table and the `KezanDB` saved variable, plus the `SLASH_KEZAN*` names the slash-command system requires. Everything else is local or hangs off the namespace table passed to each file (`local _, ns = ...`). Slash commands are `/kezan` and `/kz`.

## Money is an integer number of copper

Store, add and compare money as whole copper. Convert to gold, silver and copper only when formatting for display, with `GetMoneyString` or `C_CurrencyInfo.GetCoinTextureString`.

## Price addons are guarded and never bundled

Every call into Auctionator or TradeSkillMaster checks that the addon is loaded (`C_AddOns.IsAddOnLoaded`), passes `"Kezan"` as the caller id where the API asks for one, and treats a nil price as "no data", not zero. No file from either addon is copied into this repository (ADR 0001).

## Saved variables are migrated, not reset

`KezanDB` carries a schema version. A change to its shape adds a migration step from the previous version; it never wipes a player's session history.
