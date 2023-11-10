-- pushy
--
-- use an ableton push 1
-- on norns, i insist!
--
-- ericmoderbacher
-- 7/9/2020

local colourValue = 0

local setupParams = include("setupDemoParams")
local pushyLib = include("lib/pushyINC")


function init()

  --set up dummy params to display and edit with the push
  initParams() --in setupDemoParams.lua

  --sets up the pushy library
  --you must have all params added before calling this init() (for now)
  pushyLib.init()

  -- pushColourText = pushyLib.text.new(52, 'colour: '..colourValue, 4)
  -- pushColourText:redraw()

  --rest of init would go here, but this is a very simple example so nothing is here yet.
  --

  -- sliders[1] =
  slider = pushyLib.Slider.new(1, 1, 8, 1, 1, 1, 100, nil)
  slider:redraw()
end

function enc(num, d)
  print('enc:', num, d)

  if num == 71 then
    slider:set_value_delta(d)
    slider:redraw()
  end

  if num == 14 then
    colourValue = (colourValue + d) % 128
    for i = 0, 63 do
      pushyLib:setKey(36 + i, colourValue)
    end
    -- pushColourText.entry = "colour: "..colourValue
    -- pushColourText:redraw()
  end
end

function key(num, v)
  print('key:', num, v)
end
