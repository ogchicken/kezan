-- In-game layer: the GPH frame. A small movable frame that shows the
-- tracker's frame figures and one button per command they offer. Stop asks
-- for confirmation first; /kz stop doesn't. Its position and whether it is
-- shown are saved in KezanDB.frame. /kz show and /kz hide, and the settings
-- toggle, all go through ns.setFrameShown.

local addonName, ns = ...

-- The frame refreshes the tracker (re-valuing every item) and redraws this
-- often while shown; plan section 5 asks for at least every 5 seconds.
local UPDATE_SECONDS = 1

local WIDTH = 220
local PADDING = 10
local ROW_HEIGHT = 16
local BUTTON_HEIGHT = 22
local BUTTON_GAP = 6

local DEFAULT_POSITION = { point = "RIGHT", relativePoint = "RIGHT", x = -120, y = 120 }

local STATE_LABELS = {
  none = "No session",
  running = "Running",
  paused = "Paused",
}

local BUTTON_LABELS = {
  start = "Start",
  pause = "Pause",
  resume = "Resume",
  stop = "Stop",
  confirmStop = "Stop",
  cancelStop = "Cancel",
}

-- The figures shown, one row each, top to bottom.
local ROWS = {
  { key = "activeTime", label = "Active time", format = ns.activeTimeText },
  { key = "rawGold", label = "Raw gold", format = GetMoneyString },
  { key = "lootedItemValue", label = "Looted item value", format = GetMoneyString },
  { key = "total", label = "Total", format = GetMoneyString },
  { key = "gph", label = "Per hour", format = GetMoneyString },
}

-- KezanDB.frame: { shown, point, relativePoint, x, y }. An optional table,
-- filled with defaults on first use; no schema change.
local function settings()
  local saved = ns.db.frame
  if not saved then
    saved = { shown = true }
    for key, value in pairs(DEFAULT_POSITION) do
      saved[key] = value
    end
    ns.db.frame = saved
  end
  return saved
end

local frame -- built at ADDON_LOADED
local stateText, warning
local values = {}
local buttons = {}
-- True while the frame asks whether to stop.
local confirmingStop = false

-- Shows the named buttons side by side along the bottom, hiding the rest.
local function showButtons(names)
  for _, button in pairs(buttons) do
    button:Hide()
  end
  local width = (WIDTH - 2 * PADDING - BUTTON_GAP * (#names - 1)) / #names
  for index, name in ipairs(names) do
    local button = buttons[name]
    button:SetWidth(width)
    button:ClearAllPoints()
    button:SetPoint("BOTTOMLEFT", PADDING + (index - 1) * (width + BUTTON_GAP), PADDING)
    button:Show()
  end
end

local function update()
  local tracker = ns.tracker
  tracker:refresh()
  local figures = tracker:frameFigures()
  if figures.state == "none" then
    -- The session was stopped some other way, such as /kz stop.
    confirmingStop = false
  end
  for _, row in ipairs(ROWS) do
    values[row.key]:SetText(row.format(figures[row.key]))
  end
  warning.unreadableLines = figures.unreadableLines
  warning:SetShown(figures.unreadableLines > 0)
  if confirmingStop then
    stateText:SetText("Stop the session?")
    showButtons({ "confirmStop", "cancelStop" })
  else
    stateText:SetText(STATE_LABELS[figures.state])
    showButtons(figures.commands)
  end
end

local function onButton(name)
  if name == "stop" then
    confirmingStop = true
  elseif name == "confirmStop" then
    confirmingStop = false
    ns.stopSessionAndShowSummary()
  elseif name == "cancelStop" then
    confirmingStop = false
  else
    ns.sessionCommands[name]()
  end
  update()
end

local function savePosition()
  local point, _, relativePoint, x, y = frame:GetPoint()
  local saved = settings()
  saved.point, saved.relativePoint, saved.x, saved.y = point, relativePoint, x, y
end

local function build()
  frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  frame:SetSize(WIDTH, PADDING + ROW_HEIGHT * (1 + #ROWS) + 10 + BUTTON_HEIGHT + PADDING)
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  ns.styleWindow(frame, 0.8, savePosition)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", PADDING, -PADDING)
  title:SetText("Kezan")

  stateText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  stateText:SetPoint("TOPRIGHT", -PADDING, -PADDING - 2)

  -- The warning mark: some loot lines arrived unreadable, so the totals
  -- may be low. Its tooltip says how many.
  warning = CreateFrame("Frame", nil, frame)
  warning:SetSize(14, ROW_HEIGHT)
  warning:SetPoint("RIGHT", stateText, "LEFT", -4, 0)
  local mark = warning:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  mark:SetAllPoints()
  mark:SetText("!")
  mark:SetTextColor(1, 0.2, 0.2)
  warning:EnableMouse(true)
  warning:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(("%d loot lines couldn't be read."):format(self.unreadableLines or 0))
    GameTooltip:AddLine("The totals may be low.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  warning:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  for index, row in ipairs(ROWS) do
    local top = -PADDING - ROW_HEIGHT * index - 4
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", PADDING, top)
    label:SetText(row.label)
    local value = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("TOPRIGHT", -PADDING, top)
    value:SetJustifyH("RIGHT")
    values[row.key] = value
  end

  for name, label in pairs(BUTTON_LABELS) do
    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetHeight(BUTTON_HEIGHT)
    button:SetText(label)
    button:SetScript("OnClick", function()
      onButton(name)
    end)
    buttons[name] = button
  end

  -- OnUpdate runs only while the frame is shown, so a hidden frame costs
  -- nothing.
  local sinceUpdate = 0
  frame:SetScript("OnUpdate", function(_, elapsed)
    sinceUpdate = sinceUpdate + elapsed
    if sinceUpdate >= UPDATE_SECONDS then
      sinceUpdate = 0
      update()
    end
  end)
  frame:SetScript("OnShow", update)

  local saved = settings()
  frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
  frame:Hide()
end

-- The one way to show or hide the frame, for /kz show and hide and the
-- settings toggle. The choice is saved. Call it after ADDON_LOADED.
function ns.setFrameShown(shown)
  settings().shown = shown and true or false
  if frame then
    frame:SetShown(shown)
  end
end

-- Whether the frame is set to be shown. Call it after ADDON_LOADED.
function ns.isFrameShown()
  return settings().shown
end

ns.on("ADDON_LOADED", function(loadedName)
  if loadedName ~= addonName then
    return
  end
  build()
  ns.setFrameShown(ns.isFrameShown())
end)

ns.addCommand("show", "show the frame", function()
  ns.setFrameShown(true)
end)

ns.addCommand("hide", "hide the frame", function()
  ns.setFrameShown(false)
  ns.print("Frame hidden. /kz show brings it back.")
end)
