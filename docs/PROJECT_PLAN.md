# Kezan: project plan

Version of 27 November 2026. This plan starts small: milestone 1 is a working gold-per-hour tracker. Later milestones are listed so that early design choices leave room for them, not as commitments.

## 1. Goal

A farming player sees, while farming, how much gold the session is earning per hour, counting both raw gold and the value of looted items at auction house prices. Later, Kezan grows into a broader open-source gold-making toolkit for Forever.

## 2. Landscape

Forever's addon scene filled quickly after launch. The closest existing addons, which Kezan should stand apart from rather than copy:

- Gold Forever: auction values in tooltips, gold per hour, craft queue.
- Yield: farm and loot tracker with gold per hour, drop rates and Auctionator pricing.
- WorthIt, Haul, LootAppraiser (Retail/Classic), MoneyLooter: loot valuation and session tracking.
- Forever Profiteer, Midas, Countinghouse: auction house and market tools.

Kezan's position: open source (MIT) from day one, modular, and farmer-first. Sources and the full survey are in `research/2026-11-27-name-and-platform.md`.

## 3. Platform

- **Client:** World of Warcraft: Forever, patch 1.60.1, Blizzard's official Classic+ game. It shares Mainline's UI architecture and most of the 12.1.5 API.
- **TOC:** `## Interface: 16001`. The client also reads flavour-suffixed files (`Kezan_Forever.toc`, `Kezan_Camelot.toc`); a single `Kezan.toc` is used until a second client is supported. A `Kezan_Mainline.toc` would win over the plain file on Forever, so a Retail TOC needs a `Kezan_Forever.toc` beside it. `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` (18) identifies Forever in Lua.
- **API:** modern only: `C_Container`, `C_Item`, `C_AddOns`, `Settings`. The old globals are gone.
- **Restrictions:** the Midnight "secret values" rules apply; `COMBAT_LOG_EVENT_UNFILTERED` never fires for addons; registering a missing event raises an error. Full auction house scans were reported to be throttled during beta, so Kezan reads prices from Auctionator's or TSM's data rather than scanning itself.
- **Distribution:** CurseForge (Forever flavour) first, then Wago. Addons install into the `_forever_` folder.

## 4. Price sources

In order of preference, chosen per player in settings:

1. **Auctionator** (`Auctionator.API.v1`): `GetAuctionPriceByItemLink(callerID, itemLink)` and `GetAuctionPriceByItemID(callerID, itemID)` return copper or nil; `GetAuctionAge*` says how old the price is; `RegisterForDBUpdate(callerID, fn)` signals a finished scan, after which cached values are refreshed.
2. **TradeSkillMaster** (`TSM_API`): `GetCustomPriceValue(priceString, itemString)` with `ToItemString(itemLink)`; the player chooses the price string (for example `DBMarket`). Which TSM sources are populated on Forever is not yet verified.
3. **Vendor**: `sellPrice` from `C_Item.GetItemInfo`. Always available.

An item with no AH value falls back to the next source and is marked as such in the display. Both price addons are optional (ADR 0001). TSM's public data terms ask for credit and a link when its prices are shown.

## 5. Milestones

### Milestone 1: gold-per-hour tracker

| Ticket | Acceptance |
|---|---|
| Session start, stop, pause and resume | Duration excludes paused time; state survives `/reload`. |
| Raw gold tracking | Matches the change in `GetMoney()` from looting over a test session, excluding vendor sales, mail and trades. |
| Looted items | Every looted item and quantity is recorded from the loot events, including items whose info loads late. |
| Price lookup | Values come from the chosen source with fallback; a missing Auctionator or TSM causes no Lua error. |
| GPH display | A small movable frame shows duration, raw gold, item value, total and gold per hour, updating at least every 5 seconds. |
| Session summary | On stop, a summary lists the top items by value; the last sessions are kept in `KezanDB`. |
| Settings | A `Settings` panel chooses the price source and TSM price string and toggles the frame. |

### Later (unordered)

Session history and per-zone comparison; a LibDataBroker feed; tooltip values; vendor-trash auto-sell; mail and AH sales accounting; profit tracking across characters; crafting and flipping helpers.

## 6. Open questions

Desk research of 27 November 2026 (`research/2026-11-27-loot-and-money-events.md`) answered these on paper from Blizzard's generated API documentation for the Forever build and from shipped Forever addons. Each still needs a check in the live client before the ticket that depends on it; the note's last section lists the checks.

1. **Loot and money data: answered on paper, confirm in game.** Forever's API documentation makes `CHAT_MSG_SYSTEM` and 46 other chat events secret in dungeons, raids, encounters, keystones and PvP matches, but not `CHAT_MSG_LOOT` or `CHAT_MSG_MONEY`; `GetMoney()`, `PLAYER_MONEY` and the `LOOT_*` events carry no secret tag. To confirm in game, solo and in a group dungeon: the text arrives readable; its exact wording; which payload fields, if any, name the looter; whether a won roll gives one "You receive loot" line or two; and that nothing changes with the `addon*RestrictionsForced` CVars set. If the chat events turn out secret after all, the fallback is diffing `GetMoney()` and bag contents. Quest money arrives on `CHAT_MSG_SYSTEM`, so it is secret in dungeons either way.
2. **Plain TOC: answered.** A single `Kezan.toc` with `## Interface: 16001` loads on Forever without an "out of date" warning; ForeverPlusPlus confirmed it in the live client and most Forever addons ship that way. Confirm when Kezan first loads in game.
3. **TSM price sources: open.** TSM publishes region data for Forever (US and EU); whether the realm sources (`DBMarket`, `DBMinBuyout`, `DBHistorical`, `DBRecent`) hold values is unverified. Check before the price lookup ticket.
4. **`/kz`: answered, low risk.** No Blizzard command and no Forever addon found uses it; `/kezan` stays registered as well. Check `SlashCmdList` with popular addons loaded.
