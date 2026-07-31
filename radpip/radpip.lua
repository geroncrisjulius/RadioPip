---@type TelemetryScript
--------------------------------------------------
-- RadioPip
-- EdgeTx v2.12
-- RadioMaster Pocket - 128x64px
--------------------------------------------------

local name = "radpip"
local midWidth = LCD_W / 2
local midHeight = LCD_H / 2

-------------------------------------------------
-- Configuration
-------------------------------------------------

local ARM_SWITCH = "sa"
local IS_ARM_REVERSE = false

local RX_BATT_WARN = 3.45
local RX_BATT_CRIT = 3.3

local RX_DBM_WARN = -99
local RX_DBM_CRIT = -105

local LINK_QUAL_WARN = 45
local LINK_QUAL_CRIT = 42

------------------------------------------------
-- STATE
------------------------------------------------

local armed = false
local rxBatt = 0
local rxDbm = 0
local linkQuality = 0
local throttle = 0

------------------------------------------------
-- GET VALUES
------------------------------------------------

local function getArmState()
  local armState = getValue(ARM_SWITCH)
  if IS_ARM_REVERSE then
    armState = -armState
  end
  return armState > 0
end

local function getTelemetryValues()
  armed = getArmState()
  rxBatt = getValue("RxBt")
  rxDbm = getValue("1RSS")
  linkQuality = getValue("RQly")
  throttle = getValue("thr")
end
------------------------------------------------
-- HELPER
------------------------------------------------

local function sp2p(subPixel)
  return subPixel * 4
end

local function drawSubPixel(x, y, w, h, style)
  lcd.drawFilledRectangle(sp2p(x), sp2p(y), sp2p(w), sp2p(h), style)
end

local function isRxBattWarn()
  return rxBatt <= RX_BATT_WARN
end

local function isRxBattCrit()
  return rxBatt <= RX_BATT_CRIT
end

local function isRxDbmWarn()
  return rxDbm <= RX_DBM_WARN
end

local function isRxDbmCrit()
  return rxDbm <= RX_DBM_CRIT
end

local function isLinkQualityWarn()
  return linkQuality <= LINK_QUAL_WARN
end

local function isLinkQualityCrit()
  return linkQuality <= LINK_QUAL_CRIT
end

local function percentThrottle()
  return math.floor(((throttle + 1024) * 100) / 2048)
end

------------------------------------------------
-- DRAW
------------------------------------------------
local function drawSleepEye(x, y)
  drawSubPixel(x, y, 1, 1, FORCE)
  drawSubPixel(x + 1, y + 1, 2, 1, FORCE)
  drawSubPixel(x + 3, y, 1, 1, FORCE)
end

local function drawSleep(x, y)
  -- left eye
  drawSleepEye(x, y + 6)

  --right eye
  drawSleepEye(x + 8, y + 6)

  if (getTime() % 500) < 250 then
    --mouth
    drawSubPixel(x + 4, y + 10, 4, 1, FORCE)
  else
    --mouth
    drawSubPixel(x + 5, y + 10, 2, 2, FORCE)
  end
end

local function drawExcited(x, y)
  local state = (getTime() % 300) < 150

  -- left eye
  local lx = x + 0
  local ly = y + 0
  if state then
    drawSubPixel(lx, ly, 1, 1, FORCE)
    drawSubPixel(lx + 1, ly + 1, 1, 1, FORCE)
    drawSubPixel(lx + 2, ly + 2, 1, 1, FORCE)
    drawSubPixel(lx + 1, ly + 3, 1, 1, FORCE)
    drawSubPixel(lx, ly + 4, 1, 1, FORCE)
  else
    drawSubPixel(lx, ly + 3, 1, 1, FORCE)
    drawSubPixel(lx + 1, ly + 2, 2, 1, FORCE)
    drawSubPixel(lx + 3, ly + 3, 1, 1, FORCE)
  end

  -- right eye
  local rx = x + 7
  local ry = y + 0
  if state then
    drawSubPixel(rx + 2, ry, 1, 1, FORCE)
    drawSubPixel(rx + 1, ry + 1, 1, 1, FORCE)
    drawSubPixel(rx, ry + 2, 1, 1, FORCE)
    drawSubPixel(rx + 1, ry + 3, 1, 1, FORCE)
    drawSubPixel(rx + 2, ry + 4, 1, 1, FORCE)
  else
    rx = rx - 1
    drawSubPixel(rx, ry + 3, 1, 1, FORCE)
    drawSubPixel(rx + 1, ry + 2, 2, 1, FORCE)
    drawSubPixel(rx + 3, ry + 3, 1, 1, FORCE)
  end

  --mouth
  local mx = x + 0
  local my = y + 7
  drawSubPixel(mx, my, 10, 1, FORCE)
  drawSubPixel(mx + 1, my + 1, 8, 1, FORCE)
  -- drawSubPixel(mx + 8, my + 1, 1, 1, FORCE)
  drawSubPixel(mx + 2, my + 2, 1, 1, FORCE)
  drawSubPixel(mx + 7, my + 2, 1, 1, FORCE)
  drawSubPixel(mx + 3, my + 3, 4, 1, FORCE)
end

local function drawBorders()
  lcd.drawFilledRectangle(0, 0, LCD_W, LCD_H, FORCE)
  lcd.drawFilledRectangle(4, 4, 72, LCD_H - 8, ERASE)
  lcd.drawFilledRectangle(4, 4, 4, 4, FORCE)
  lcd.drawFilledRectangle(4, 56, 4, 4, FORCE)
  lcd.drawFilledRectangle(72, 4, 4, 4, FORCE)
  lcd.drawFilledRectangle(72, 56, 4, 4, FORCE)
end

local function drawValues()
  -- arming
  if armed then
    lcd.drawFilledRectangle(80, 2, 46, 10, ERASE)
    lcd.drawText(82, 4, "ARMED", SMLSIZE)
  else
    lcd.drawText(82, 4, "DISARMED", SMLSIZE + INVERS)
  end

  -- battery
  lcd.drawFilledRectangle(80, 14, 46, 10, ERASE)
  if isRxBattWarn() then
    lcd.drawText(82, 16, string.format("BT:", rxBatt), SMLSIZE + BLINK)
  else
    lcd.drawText(82, 16, string.format("BT:", rxBatt), SMLSIZE)
  end
  lcd.drawText(95, 16, string.format("%.2fv", rxBatt), SMLSIZE)

  -- rssi dbm
  lcd.drawFilledRectangle(80, 26, 46, 10, ERASE)
  if isRxDbmWarn() then
    lcd.drawText(82, 28, string.format("RS:", rxDbm), SMLSIZE + BLINK)
  else
    lcd.drawText(82, 28, string.format("RS:", rxDbm), SMLSIZE)
  end
  lcd.drawText(95, 28, string.format("%ddB", rxDbm), SMLSIZE)

  -- link quality
  lcd.drawFilledRectangle(80, 38, 46, 10, ERASE)
  if isLinkQualityWarn() then
    lcd.drawText(82, 40, string.format("LQ:", linkQuality), SMLSIZE + BLINK)
  else
    lcd.drawText(82, 40, string.format("LQ:", linkQuality), SMLSIZE)
  end
  lcd.drawText(95, 40, string.format("%d%%", linkQuality), SMLSIZE)

  -- throttle
  lcd.drawFilledRectangle(80, 50, 46, 12, ERASE)
  lcd.drawLine(81, 55, 125, 55, DOTTED, FORCE)
  lcd.drawLine(81, 56, 125, 56, DOTTED, FORCE)
  lcd.drawFilledRectangle(81, 51, percentThrottle() * 44 / 100, 10, FORCE)
end

local function drawPip()
  if not armed then
    drawSleep(4, 2)
  elseif percentThrottle() > 50 then
    drawExcited(5, 3)
  else

  end
end


------------------------------------------------
-- Main
------------------------------------------------

local function my_run(event)
  getTelemetryValues()

  lcd.clear()
  drawBorders()

  drawPip()

  drawValues()
end

return { run = my_run }
