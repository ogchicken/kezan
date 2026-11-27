-- In-game layer: the summary window. It shows a stopped session's summary
-- from the tracker: the character, start zone, start time and figures, the
-- unreadable-line count when there were any, and the top items by value.
-- ns.stopSessionAndShowSummary (Commands.lua) opens it at stop; /kz last
-- reopens the latest one. Nothing about it is saved.

local _, ns = ...

local PADDING = 12
local ROW_HEIGHT = 16
local LABEL_WIDTH = 110

-- The item columns, left to right: key in a top item, heading, width,
-- justification.
local COLUMNS = {
  { key = "link", heading = "Item", width = 190, justify = "LEFT" },
  { key = "quantity", heading = "Qty", width = 40, justify = "RIGHT" },
  { key = "itemValue", heading = "Each", width = 95, justify = "RIGHT" },
  { key = "value", heading = "Value", width = 95, justify = "RIGHT" },
  { key = "pricing", heading = "Priced", width = 70, justify = "RIGHT" },
}
local COLUMN_GAP = 6

local WIDTH = 2 * PADDING + COLUMN_GAP * (#COLUMNS - 1)
for _, column in ipairs(COLUMNS) do
  WIDTH = WIDTH + column.width
end

-- How each pricing mark reads, with its colour.
local PRICING = {
  ah = { text = "AH", r = 1, g = 1, b = 1 },
  stale = { text = "AH, stale", r = 1, g = 0.6, b = 0.2 },
  vendor = { text = "Vendor", r = 1, g = 1, b = 1 },
  unpriced = { text = "Unpriced", r = 0.6, g = 0.6, b = 0.6 },
}

local function startTime(seconds)
  return date("%Y-%m-%d %H:%M", seconds)
end

-- The session rows at the top, one label and value each.
local FIELDS = {
  { label = "Character", format = function(s) return s.character end },
  { label = "Start zone", format = function(s) return s.startZone or "Unknown" end },
  { label = "Started", format = function(s) return startTime(s.startedAt) end },
  { label = "Active time", format = function(s) return ns.activeTimeText(s.activeTime) end },
  { label = "Raw gold", format = function(s) return GetMoneyString(s.rawGold) end },
  { label = "Looted item value", format = function(s) return GetMoneyString(s.lootedItemValue) end },
  { label = "Total", format = function(s) return GetMoneyString(s.total) end },
  { label = "Per hour", format = function(s) return GetMoneyString(s.gph) end },
}

local CELL_FORMATS = {
  link = function(item) return item.link end,
  quantity = function(item) return tostring(item.quantity) end,
  itemValue = function(item) return GetMoneyString(item.itemValue) end,
  value = function(item) return GetMoneyString(item.value) end,
  pricing = function(item) return PRICING[item.pricing].text end,
}

local window -- built on first show
local fieldValues = {}
local warning, itemsHeading, headingRow, noItems
local itemRows = {}

local function fontString(parent, template, width, justify)
  local text = parent:CreateFontString(nil, "OVERLAY", template)
  text:SetWidth(width)
  text:SetJustifyH(justify)
  text:SetWordWrap(false)
  return text
end

-- One row of cells across the columns, anchored to `row`.
local function cells(row, template)
  local list = {}
  local x = 0
  for _, column in ipairs(COLUMNS) do
    local cell = fontString(row, template, column.width, column.justify)
    cell:SetPoint("LEFT", x, 0)
    list[column.key] = cell
    x = x + column.width + COLUMN_GAP
  end
  return list
end

local function itemRow(index)
  local row = CreateFrame("Frame", nil, window)
  row:SetSize(WIDTH - 2 * PADDING, ROW_HEIGHT)
  row.cells = cells(row, "GameFontHighlightSmall")
  -- Hovering a row shows the item's tooltip.
  row:EnableMouse(true)
  row:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.link)
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  itemRows[index] = row
  return row
end

local function build()
  window = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  window:SetWidth(WIDTH)
  window:SetFrameStrata("DIALOG")
  window:SetClampedToScreen(true)
  window:SetPoint("CENTER")
  window:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  window:SetBackdropColor(0, 0, 0, 0.9)

  window:SetMovable(true)
  window:EnableMouse(true)
  window:RegisterForDrag("LeftButton")
  window:SetScript("OnDragStart", window.StartMoving)
  window:SetScript("OnDragStop", window.StopMovingOrSizing)

  local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", PADDING, -PADDING)
  title:SetText("Kezan session summary")

  local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -2, -2)

  for index, field in ipairs(FIELDS) do
    local top = -PADDING - ROW_HEIGHT * index - 4
    local label = fontString(window, "GameFontNormalSmall", LABEL_WIDTH, "LEFT")
    label:SetPoint("TOPLEFT", PADDING, top)
    label:SetText(field.label)
    local value = fontString(window, "GameFontHighlightSmall", WIDTH - 2 * PADDING - LABEL_WIDTH, "LEFT")
    value:SetPoint("TOPLEFT", PADDING + LABEL_WIDTH, top)
    fieldValues[index] = value
  end

  warning = fontString(window, "GameFontHighlightSmall", WIDTH - 2 * PADDING, "LEFT")
  warning:SetTextColor(1, 0.2, 0.2)

  itemsHeading = fontString(window, "GameFontNormal", WIDTH - 2 * PADDING, "LEFT")
  itemsHeading:SetText("Top items")

  headingRow = CreateFrame("Frame", nil, window)
  headingRow:SetSize(WIDTH - 2 * PADDING, ROW_HEIGHT)
  local headingCells = cells(headingRow, "GameFontNormalSmall")
  for _, column in ipairs(COLUMNS) do
    headingCells[column.key]:SetText(column.heading)
  end

  noItems = fontString(window, "GameFontDisableSmall", WIDTH - 2 * PADDING, "LEFT")
  noItems:SetText("No items looted.")
end

-- Lays out the rows below the session fields from the top down: the
-- warning only when some lines were unreadable, then the item list.
local function layout(summary)
  local y = -PADDING - ROW_HEIGHT * (#FIELDS + 1) - 10

  warning:ClearAllPoints()
  if summary.unreadableLines > 0 then
    warning:SetText(("%d loot lines couldn't be read, so the totals may be low."):format(summary.unreadableLines))
    warning:SetPoint("TOPLEFT", PADDING, y)
    warning:Show()
    y = y - ROW_HEIGHT - 6
  else
    warning:Hide()
  end

  itemsHeading:SetPoint("TOPLEFT", PADDING, y)
  y = y - ROW_HEIGHT - 2
  headingRow:SetPoint("TOPLEFT", PADDING, y)
  y = y - ROW_HEIGHT

  noItems:SetShown(#summary.topItems == 0)
  if #summary.topItems == 0 then
    noItems:SetPoint("TOPLEFT", PADDING, y)
    y = y - ROW_HEIGHT
  end

  for _, row in ipairs(itemRows) do
    row:Hide()
  end
  for index, item in ipairs(summary.topItems) do
    local row = itemRows[index] or itemRow(index)
    row.link = item.link
    for key, cell in pairs(row.cells) do
      cell:SetText(CELL_FORMATS[key](item))
    end
    local mark = PRICING[item.pricing]
    row.cells.pricing:SetTextColor(mark.r, mark.g, mark.b)
    row:SetPoint("TOPLEFT", PADDING, y)
    row:Show()
    y = y - ROW_HEIGHT
  end

  window:SetHeight(-y + PADDING)
end

-- Shows a summary as the tracker gives it (tracker:stop() or
-- tracker:lastSummary()), replacing any summary already shown.
function ns.showSummary(summary)
  if not window then
    build()
  end
  for index, field in ipairs(FIELDS) do
    fieldValues[index]:SetText(field.format(summary))
  end
  layout(summary)
  window:Show()
end

ns.addCommand("last", "show the latest session's summary again", function()
  local summary, reason = ns.tracker:lastSummary()
  if summary then
    ns.showSummary(summary)
  else
    ns.print(reason)
  end
end)
