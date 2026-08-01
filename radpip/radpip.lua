---@type TelemetryScript
--------------------------------------------------
-- RadioPip
-- EdgeTx v2.12
-- RadioMaster Pocket - 128x64px
--------------------------------------------------

local name = "radpip"
local pipFace = dofile("/SCRIPTS/TELEMETRY/radpipface.lua")
local face = pipFace.new({
  x = 4,
  y = 4
})

-------------------------------------------------
-- Configuration
-------------------------------------------------

local ARM_SWITCH = "sa"
local IS_ARM_REVERSE = false

local BATT_CELL_COUNT = 4
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
  rxBatt = getValue("RxBt") / BATT_CELL_COUNT
  rxDbm = getValue("1RSS")
  linkQuality = getValue("RQly")
  throttle = math.floor(((getValue("thr") + 1024) * 100) / 2048)
end
------------------------------------------------
-- HELPER
------------------------------------------------

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


------------------------------------------------
-- DRAW
------------------------------------------------

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
  lcd.drawFilledRectangle(80, 15, 46, 10, ERASE)
  if isRxBattWarn() then
    lcd.drawText(82, 17, "BT:", SMLSIZE + BLINK)
  else
    lcd.drawText(82, 17, "BT:", SMLSIZE)
  end
  lcd.drawText(95, 17, string.format("%.2fv", rxBatt), SMLSIZE)

  -- rssi dbm
  lcd.drawFilledRectangle(80, 28, 46, 10, ERASE)
  if isRxDbmWarn() then
    lcd.drawText(82, 30, "RS:", SMLSIZE + BLINK)
  else
    lcd.drawText(82, 30, "RS:", SMLSIZE)
  end
  lcd.drawText(95, 30, string.format("%ddB", rxDbm), SMLSIZE)

  -- link quality
  lcd.drawFilledRectangle(80, 41, 46, 10, ERASE)
  if isLinkQualityWarn() then
    lcd.drawText(82, 43, "LQ:", SMLSIZE + BLINK)
  else
    lcd.drawText(82, 43, "LQ:", SMLSIZE)
  end
  lcd.drawText(95, 43, string.format("%d%%", linkQuality), SMLSIZE)

  -- throttle
  lcd.drawFilledRectangle(80, 54, 46, 8, ERASE)
  lcd.drawLine(81, 57, 125, 57, DOTTED, FORCE)
  lcd.drawLine(81, 58, 125, 58, DOTTED, FORCE)
  lcd.drawFilledRectangle(81, 55, throttle * 44 / 100, 6, FORCE)
end

------------------------------------------------
-- Main
------------------------------------------------

local function my_run(event)
  getTelemetryValues()

  lcd.clear()
  drawBorders()
  drawValues()




  if not armed then
    face:setExpression("SLEEP")
  else
    face:setExpression("NORMAL")
  end

  face:update()
  face:draw()
end

return { run = my_run, init = my_init }
