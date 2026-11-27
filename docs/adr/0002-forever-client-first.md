# Forever client first

Kezan targets World of Warcraft: Forever (Interface 16001, the Mainline API) and nothing else until milestone 1 ships. We chose this because the owner plays Forever, because Forever's API is the modern Mainline one, so a later Retail build is a TOC file and a few guarded calls away, and because supporting Classic Era or older private-server clients would need a second API layer from the start. Adding a client means adding its flavour-suffixed TOC file and a test pass on that client, recorded in a new ADR.
