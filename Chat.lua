-- In-game layer: chat-event adapters. Each turns a chat event into the
-- tracker's chat line of one kind, or into an unreadable-line notice when
-- the text arrives secret (research/2026-11-27-loot-and-money-events.md).

local _, ns = ...

local function isSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

-- A handler for a chat event whose text is a line of the given kind
-- ("coin" or "loot").
local function chatAdapter(kind)
  return function(text)
    local tracker = ns.tracker
    if not tracker then
      return
    end
    if isSecret(text) then
      tracker:unreadableLine()
    else
      tracker:chatLine(kind, text)
    end
  end
end

ns.on("CHAT_MSG_MONEY", chatAdapter("coin"))
