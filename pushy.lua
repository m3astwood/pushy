-- PSHR Library
--
-- use an ableton push 1
-- on norns, i insist!
--
-- based off ericmoderbacher
-- 7/9/2020

local colourValue = { 0, 0, 0 }
local colourText = {}

local keySelect = 0
local keySelectText = {}

-- local setupParams = include("setupDemoParams")
local pshr = include("lib/Push")

function init()
  --sets up the pushy library
  pshr:init()

  -- pushColourText = pshr.text.new(52, 'colour: '..colourValue, 4)
  -- pushColourText:redraw()

  -- colour text
  for i,c in ipairs(colourValue) do
    local colour
    if i == 2 then
      colour = 'g'
    elseif i == 3 then
      colour = 'b'
    else
      colour = 'r'
    end
    colourText[i] = pshr.Text.new(46 + (i * 6), colour..'.'..c, 4, 5)
    colourText[i]:redraw()
  end

  keySelectText = pshr.Text.new(1, keySelect, 4, 3)
  keySelectText:redraw()

  -- slider
  slider = pshr.Slider.new(10, 1, 8, 1, 1, 1, 100, nil, true)
  slider:redraw()

  -- turn on a key
  pshr:setKey(0, 3)
end

function enc(num, d)
  print('enc:', num, d)

  if num == 72 then
    slider:set_value_delta(d)
    slider:redraw()
  end

  -- button activate
  if num == 14 then
    prevKey = keySelect
    keySelect = (keySelect + d) % 128

    pshr:setKey(keySelect, 6, true)

    keySelectText.entry = keySelect
    keySelectText:redraw()
  end

  -- colour test
  if num == 76 then
    colourValue[1] = (colourValue[1] + d) % 255
    colourText[1].entry = 'r.'..colourValue[1]
    colourText[1]:redraw()
  end

  if num == 77 then
    colourValue[2] = (colourValue[2] + d) % 255
    colourText[2].entry = 'g.'..colourValue[2]
    colourText[2]:redraw()
  end

  if num == 78 then
    colourValue[3] = (colourValue[3] + d) % 255
    colourText[3].entry = 'b.'..colourValue[3]
    colourText[3]:redraw()
  end

  if num >= 76 and num <= 78 then
    pshr:setColour(1, colourValue)
  end
end

function key(num, v)
  print('key:', num, v)
end
