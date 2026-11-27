# Name and platform research, 27 November 2026

Desk research done before the repository existed: what WoW Forever is, whether Auctionator and TradeSkillMaster can be used from another addon, which gold-tracking addons already exist, and whether the name Kezan is free. Version numbers and "it works" reports mostly come from third-party guide sites that sometimes disagree; Warcraft Wiki, CurseForge and addon source code are the firmest sources. Items marked *unverified* need an in-game check (plan section 6).

## WoW Forever

- Blizzard's official Classic+ game ("World of Warcraft: Forever"), announced at BlizzCon on 12 September 2026 and launched 4 November 2026. Original Azeroth, level 60 cap, no flying; included in a normal subscription. [Wikipedia](https://en.wikipedia.org/wiki/World_of_Warcraft:_Forever), [Warcraft Wiki](https://warcraft.wiki.gg/wiki/World_of_Warcraft:_Forever)
- Patch 1.60.1 (live build reported as 1.60.1.70755). It "shares Mainline WoW's UI architecture, including the vast majority of APIs available in 12.1.5". [Patch 1.60.1/API changes](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes), [ForeverPlusPlus API notes](https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/docs/forever-api.md)
- TOC: `## Interface: 16001`; flavour suffixes `_Forever` or `_Camelot`; the game type counts as the Mainline family; `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` (18). [TOC format](https://warcraft.wiki.gg/wiki/TOC_format)
- Modern API (`C_Container`, `C_Item`, `C_AuctionHouse`, `Settings`); old globals like `GetItemInfo` are gone. Midnight "secret values" rules apply; `COMBAT_LOG_EVENT_UNFILTERED` never fires for addons; registering a missing event raises an error.
- *Unverified:* whether `CHAT_MSG_LOOT`, `CHAT_MSG_MONEY` and `GetMoney` are affected by secret values.
- Full AH scans reported throttled during beta (a scan throttled over 162 s returned an empty market with no error). *Unverified on live.* [mmonster](https://mmonster.co/wow-forever/guides/addons/professions-and-gold)
- Distribution: CurseForge (Forever flavour, app detects installs), Wago, WowUp; addons go in `_forever_`. One repository with several TOC files is the norm. [kami-labs](https://kami-labs.fr/en/addons-wow-forever/), [mmonster install](https://mmonster.co/wow-forever/guides/addons/install)

## Auctionator

- Has a Forever file on CurseForge (version 354, 25 November 2026). [CurseForge](https://www.curseforge.com/wow/addons/auctionator)
- Public API v1, which the author says will stay stable; each call takes a `callerID`: `GetAuctionPriceByItemID` / `GetAuctionPriceByItemLink` (copper or nil), `GetAuctionAge*`, `IsAuctionDataExact*`, `GetVendorPrice*`, `GetDisenchantPrice*`, `MultiSearch`, `RegisterForDBUpdate(callerID, fn)`.
- Read in mirrors because the official repository (TheMouseNest/Auctionator) returned 404 to the GitHub API: [API README mirror](https://github.com/BurN-30/wow-forever-guide/tree/main/addons/Auctionator/Source/API/v1), [RegisterForDBUpdate in a third-party fork](https://github.com/fiote/AuctionatorForever/blob/main/Source_ModernAH/API/v1/RegisterForDBUpdate.lua).
- Licence: All Rights Reserved.

## TradeSkillMaster

- TSM 4.15 announced Forever support from launch; guides cite up to 4.15.9 (20 November). Regional prices come through the new TSM Desktop App. [TSM news](https://tradeskillmaster.com/news/tsm-4-15-brings-wow-forever-support-plus-new-desktop-app-1180), [mmonster](https://mmonster.co/wow-forever/guides/addons/tradeskillmaster)
- Public API: `TSM_API.GetCustomPriceValue(str, itemString)`, `ToItemString`, `GetPriceSourceKeys`, `IsCustomPriceValid`, `FormatMoneyString`, quantity functions. [Core/API.lua mirror](https://github.com/Connor9994/World-of-Warcraft/blob/main/AddOns/TradeSkillMaster/Core/API.lua). *Unverified* that the Forever build's file is identical, and which price sources are populated on Forever.
- Licence: All Rights Reserved. [Public data terms](https://tradeskillmaster.com/public-data): use in addons allowed with credit and a link; no bulk resale or republishing; no implied endorsement.

## Existing addons

On Forever, all updated in November 2026:

- [Gold Forever](https://www.curseforge.com/wow/addons/gold-forever) (`/gf`): AH values in tooltips, gold per hour, craft queue. Closest competitor.
- [Yield](https://www.curseforge.com/wow/addons/yield) (`/yld`): farm and loot tracker, gold per hour, Auctionator pricing.
- [Forever Ledger](https://www.curseforge.com/wow/addons/forever-ledger) (`/fl`), [Goblin Terminal](https://www.curseforge.com/wow/addons/goblin-terminal) (`/gt`), [Lootify](https://www.curseforge.com/wow/addons/lootify), [Haul](https://www.curseforge.com/wow/addons/haul-gold-per-hour-farm-session-tracker), [Sakal Venture Co. Gold](https://www.curseforge.com/wow/addons/sakal-venture-co-gold) (`/vcg`).
- [Forever Profiteer](https://www.curseforge.com/wow/addons/forever-profiteer), [Midas](https://www.curseforge.com/wow/addons/midas) (MIT), [Countinghouse](https://www.curseforge.com/wow/addons/countinghouse) (MIT), [Goldsmith](https://www.curseforge.com/wow/addons/goldsmith-crafting-profit-planner).

Elsewhere: LootAppraiser, MoneyLooter, WorthIt, Hyperspawn, GrindPlus, GoldPerHour (two GitHub repos), [Time-Is-Money](https://github.com/RyrinsRealm/Time-Is-Money) (`/tim`, loads on Forever).

## Name check: Kezan

Kezan is the goblin homeland and seat of the trade cartels. Names rejected because they are taken: Midas, Time Is Money, Golden Hour, Copperwise, Goldsmith, Profiteer, Countinghouse, Yield, Haul, Grindstone, Bilgewater (Bilgewater Trade Co. is an AH price source on Forever), GoldPerHour, and most "Gold…", "Ledger", "Farm…", "Loot…", "Goblin…" and "Forever…" combinations.

Checks for Kezan on 27 November 2026:

- CurseForge: no addon named Kezan in repeated searches; the direct URL `curseforge.com/wow/addons/kezan` could not be checked (403 to automated requests).
- Wago: `addons.wago.io/addons/kezan` returns 404 (free).
- WoWInterface: no search results.
- GitHub: no WoW addon. Related only: Project Epoch "Kezan" realm-status bots (an unrelated private server's realm name) and `KZeillmann/KezanMarketScreener`, a 2017 Elixir web app.
- Only in-game use of the word on Forever: quest names (Kezan's Taint).

Other names that looked free and were considered: TradePrince, Revilgaz, Coinclock, Kaching, Moneybags.
