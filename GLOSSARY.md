# Kezan

An open-source gold-making addon for World of Warcraft: Forever. Terms are the gold-making and WoW terms used in the plan, the code and the issues. Extend this list when a new term settles.

## Terms

**Forever**:
World of Warcraft: Forever, Blizzard's level 60 Classic+ game launched on 4 November 2026, running the Mainline client (Interface 16001). Also called Camelot in the client's internals.

### Money

**copper**:
The smallest unit of money; 100 copper make a silver and 100 silver make a gold. All money in the code is whole copper.

### Sessions

**session**:
One farming run of one character, started and stopped by the player. A session counts the loot that arrives while it is running.

**paused**:
The state of a session that is not running but not yet stopped. Loot arriving while paused is not counted, and paused time is not active time. A session found after logging back in is paused.

**active time**:
A session's duration excluding paused time and time spent logged out.
_Avoid_: duration, elapsed time

**loot**:
Items and coin the player receives from a loot window: corpses, gathering nodes, skinning, fishing, containers and won rolls. Quest rewards, crafted items, purchases, mail, trades, sales and other players' loot are not loot.
_Avoid_: income, earnings

**drop**:
One item stack received as loot in one go, such as one Black Lotus or three Peacebloom.
_Avoid_: arrival, pickup

**opened item**:
An item that turns into loot when used: a clam, a lockbox, or an item being disenchanted. Its contents take its place in the session.
_Avoid_: container (when disenchanting is meant too)

**raw gold**:
Coin received as loot during a session: coin the player loots, and the player's share of coin split in a group.

**looted item value**:
The sum over a session's drops of quantity times item value.

**gold per hour (GPH)**:
(Raw gold + looted item value) divided by the session's active time in hours. Gross: repairs, reagents and other spending are not subtracted.

### Items and prices

**soulbound**:
Bound to the player when looted, so the item cannot be sold on the auction house.
_Avoid_: BoP

**tradable**:
Not soulbound when looted. Includes items that bind when equipped.

**price source**:
Where AH values come from: Auctionator, or later a TradeSkillMaster custom price string. With no price source, every item takes its vendor value.
_Avoid_: calling the vendor value a price source

**AH value**:
An item's auction house price from a price source. Missing when the item has not been scanned.

**vendor value**:
The price a merchant pays for one unit of an item. Zero for items that cannot be sold. Not the price a merchant charges for it.

**item value**:
The per-unit worth Kezan gives an item: its vendor value if it is of poor quality or soulbound, otherwise its AH value, falling back to its vendor value when the AH value is missing.

**stale price**:
An AH value last seen more than 3 days ago, or of unknown age.

**unpriced item**:
An item with neither an AH value nor a vendor value. It counts at zero and is listed as unpriced, never dropped.
