--------------------------------------------------
-- RadioPip
-- EdgeTx v2.12
-- RadioMaster Pocket - 128x64px
--------------------------------------------------

local name = "radpip"

local function my_init()
  -- init is called once when model is loaded
end

local function my_background()
  -- background is called periodically
end

local function my_run(event)
  -- run is called periodically only when screen is visible
end

return { run = my_run, background = my_background, init = my_init }