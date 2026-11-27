# A session counts loot when it arrives, and nothing else

A session counts only the player's own loot: the "You receive loot" lines for items, and the "You loot" and "Your share of the loot" lines for coin. It counts each drop once, when it arrives, and never counts what happens to it later, except when it is opened (below). Vendor sales, mail, trades, auction house money, quest rewards, crafted items, purchases and other players' loot are all left out, and spending is not subtracted, so gold per hour is gross. We chose this so that nothing is counted twice: a grey is counted when it drops, so selling it to a vendor adds nothing; ore smelted into bars mid-session keeps the ore's value; a won roll counts through its "You receive loot" line, not its "You won" line. It also gives the same answer in the open world and in a dungeon. Quest money arrives on a chat event that is secret in dungeons, so counting it would make a session's total depend on where it was played.

## Considered options

- **The change in the wallet and bags.** Rejected as the main path: it counts everything, including sales, mail and trades, unless every merchant, mailbox and trade window is tracked and subtracted. It stays the fallback if the loot lines turn out to be secret in game (plan section 6, question 1).
- **Net gold per hour**, with repairs and consumables subtracted. Deferred: spending often happens after a session ends, and tracking it is a feature of its own.

## Opened items

Opening a clam or a lockbox, and disenchanting if Forever shows its results in a loot window, turns one item into others, and the game reports the results as loot. The results count, and one unit of the opened item leaves the session, if the session holds one. When the opened item was already in the bags before the session started, its contents do not count, so opening old stock does not inflate a session. When Kezan cannot tell which item was opened, the contents count and nothing is removed: that overcounts by the container's usually small value rather than losing what was inside. Because disenchanting a soulbound drop swaps its vendor value for its materials' AH value, Kezan does not need Auctionator's disenchant price.
