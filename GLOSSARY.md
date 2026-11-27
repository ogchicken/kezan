# Kezan

An open-source gold-making addon for World of Warcraft: Forever. Terms are the gold-making and WoW terms used in the plan, the code and the issues. Extend this list when a new term settles.

## Terms

**copper**:
The smallest unit of money; 100 copper make a silver and 100 silver make a gold. All money in the code is whole copper.

**session**:
One farming run, from start to stop, with pauses excluded from its duration. A session records raw gold, looted items and their values.

**raw gold**:
Money looted directly from mobs and containers during a session, as reported by the money loot events.

**looted item value**:
The sum over looted items of quantity times the item's price from the chosen price source.

**gold per hour (GPH)**:
(Raw gold + looted item value) divided by the session's active duration in hours.

**price source**:
Where an item's price comes from: Auctionator, a TradeSkillMaster custom price string, or the vendor price.

**AH value**:
An item's auction house price from a price source. Missing when the item has not been scanned.

**vendor value**:
The price a merchant pays for an item (`sellPrice` from `C_Item.GetItemInfo`). Zero for items that cannot be sold.

**Forever**:
World of Warcraft: Forever, Blizzard's level 60 Classic+ game launched on 4 November 2026, running the Mainline client (Interface 16001). Also called Camelot in the client's internals.
