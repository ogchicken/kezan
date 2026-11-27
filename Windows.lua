-- In-game layer: the look and the dragging that Kezan's windows share (the
-- frame and the summary window).

local _, ns = ...

local BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- Gives a frame built from BackdropTemplate the tooltip-style backdrop,
-- its background black at `backgroundAlpha`, and lets the player drag it
-- with the left button. `onMoved`, when given, runs after each drag.
function ns.styleWindow(window, backgroundAlpha, onMoved)
  window:SetBackdrop(BACKDROP)
  window:SetBackdropColor(0, 0, 0, backgroundAlpha)

  window:SetMovable(true)
  window:EnableMouse(true)
  window:RegisterForDrag("LeftButton")
  window:SetScript("OnDragStart", window.StartMoving)
  window:SetScript("OnDragStop", function()
    window:StopMovingOrSizing()
    if onMoved then
      onMoved()
    end
  end)
end
