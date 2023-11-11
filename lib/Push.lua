local Pshr = {}
Pshr.__index = Pshr

-- ==> PRIVATE VARIABLES
local lcdLines = {
  {
    dirty=true, elementsMoved = false, message={}
  },
  {
    dirty=true, elementsMoved = false, message={}
  },
  {
    dirty=true, elementsMoved = false, message={}
  },
  {
    dirty=true, elementsMoved = false, message={}
  }
}

local sliderChars = {
  empty=6,
  left=3,
  right=4,
  center=5
}

-- ==> PRIVATE FUNCTIONS-
function tprint(tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end

local function midi_control(data)
    message = midi.to_msg(data)

    if message.type == "cc" then
      -- handle turn of encoders
      if ((message.cc >= 71 and message.cc <= 79) or (message.cc == 14 or message.cc == 15)) then
        delta = -1 * (math.floor((message.val - 64)/math.abs(message.val - 64))* (64 - math.abs(message.val - 64))) --yeah i know
        enc(message.cc, delta)
      -- handle key presses
      else if (message.cc == 3 or message.cc == 9)
        or (message.cc >= 20 and message.cc <= 29)
        or (message.cc >= 36 and message.cc <= 63)
        or (message.cc >= 85 and message.cc <= 90)
        or (message.cc >= 102 and message.cc <= 119) then
        val = 0
        if message.val > 0 then
          val = 1
        end
        key(message.cc, val)
      else
        print(message.cc, message.val)
      end
    end
  end

  -- handle touch of encoders
  if message.type == "note_on" or message.type == "note_off" then
    if message.note >= 0 and message.note <= 10 then
      val = 0
      if message.vel > 0 then
        val = 1
      end
      key(message.note, val)
    else
      print('note:', message.note)
    end
  end
end

local function send_sysex(m, d)
  -- from user zebra on lines
  m:send{0xf0}
  for i,v in ipairs(d) do
      m:send{d[i]}
  end
  m:send{0xf7}
end

local function setupEmptyLine(lineNumber)
  header = {71, 127, 21, (23 + lineNumber), 0, 69, 0}
  for i=1,7,1 do
    lcdLines[lineNumber].message[i] = header[i]
  end

  for i=8,75,1 do
    lcdLines[lineNumber].message[i] = 32
  end
end

local function pushColour(val, idx)
  idx = idx or 1
  if idx == 1 then
    return math.floor(val / 16)
  else
    return val % 16
  end
end

-- ==> CLASS
function Pshr:init()
  -- local p = {}
  setmetatable(self, Pshr)

  -- midi
  self.midi = midi.connect(2)
  self.midi.event = midi_control

  -- clear the screen
  self:clear()

  -- clear all pads
  for i = 0, 71, 1 do
    self:setKey(36 + i, 0)
  end

  -- clear all keys
  for i = 1, 127 do
    self:setKey(i, 0, true)
  end

  -- loop for screen redrawing
  clock.run(function()
    while true do
      clock.sleep(1/30)
      for i,v in ipairs(lcdLines) do
        if v.dirty == true then
          self:redraw(i)
        end
      end
    end
  end)

  return self
end

function Pshr:clear()
  for i=1,4,1 do
      setupEmptyLine(i)
      lcdLines[i].dirty = true
  end
end

function Pshr:redraw(line)
  send_sysex(self.midi, lcdLines[line].message)
  lcdLines[line].dirty = false
end

function Pshr:setKey(key, val, cc)
  cc = cc or false
  if cc then
    self.midi:cc(key, val, 1)
  else
    send_sysex(self.midi, {0x90, key, val})
  end
end

function Pshr:setColour(key, colour)
  print('setting key', key, 'to', colour)
  colour = colour or { 255, 255, 255 }
  key = key or 0

  -- Push colour format
  -- c1 = c / 16 (return int)
  -- c2 = c % 16
  r1 = pushColour(colour[1], 1)
  r2 = pushColour(colour[1], 2)
  g1 = pushColour(colour[2], 1)
  g2 = pushColour(colour[2], 2)
  b1 = pushColour(colour[3], 1)
  b2 = pushColour(colour[3], 2)


  -- {0x90, key, val}
  message = {71, 127, 21, 4, 0, 8, key, 0, r1, r2, g1, g2, b1, b2 }
  send_sysex(self.midi, message)
end

-- ==> SLIDER
Pshr.Slider = {}
Pshr.Slider.__index = Pshr.Slider

function Pshr.Slider.new(x, line, width, height, value, min_value, max_value, markers, filled)
  local slider = {
    x = x or 0,
    line = line or 0,
    width = width or 3,
    height = height or 1,
    value = value or 0,
    min_value = min_value or 0,
    max_value = max_value or 1,
    markers = markers or {},
    filled = filled or false,
    active = true,
    dirty = true
  }
  -- setmetatable(Pshr.Slider, {__index = UI})
  setmetatable(slider, Pshr.Slider)

  return slider
end

--- Set value.
-- @tparam number number Value number.
function Pshr.Slider:set_value(number)
  self.value = util.clamp(number, self.min_value, self.max_value)
  self.dirty = true
end

--- Set value using delta.
-- @tparam number delta Number.
function Pshr.Slider:set_value_delta(delta)
  self:set_value(self.value + delta)
end

function Pshr.Slider:changeWidth(delta)
    local previousWidth = self.width
    self.width = util.clamp(self.width + delta, 1, (numberOfCharsPerLine - self.x + 1))
    --remove the chars that we dont need.
    lcdLines[self.line].elementsMoved = true

    self.dirty = true
end

--- Set marker position.
-- @tparam number id Marker number.
-- @tparam number position Marker position number.
function Pshr.Slider:set_marker_position(id, position)
  self.markers[id] = util.clamp(position, self.min_value, self.max_value)
end

--- Redraw Slider. --Call when changed.
function Pshr.Slider:redraw()
  local charLength = (self.value/self.max_value)*(self.width)
  local onChar = math.ceil(charLength) --the number of chars that will be lit up
  local partials = math.ceil((charLength + 1 - onChar)*2)-- the portion of the last char that will be on

  print(charLength, onChar, partials)

  -- setting loop to start after sysex header (7) + x position
  -- maxing out to the width of the slider
  for pos=1, self.width do
    local i = pos + (6 + self.x)

    if pos == onChar then
      if partials == 1 then
        lcdLines[self.line].message[i] = sliderChars.left
      elseif partials ==  2 then
        if self.filled == true then
          lcdLines[self.line].message[i] = 5
        else
          lcdLines[self.line].message[i] = sliderChars.right
        end
      end
    else
      if self.filled == true then
        if onChar > pos then
          lcdLines[self.line].message[i] = 5
        else
          lcdLines[self.line].message[i] = sliderChars.empty
        end
      else
        lcdLines[self.line].message[i] = sliderChars.empty
      end
    end
  end

  lcdLines[self.line].dirty = true
  self.dirty = false
end


-------- Text Block --------
--this section pertains to writing text to the push screen
Pshr.Text = {}
Pshr.Text.__index = Pshr.Text

function Pshr.Text.new(x, entry, line, width, height)
  local text = {
    x = x or 0,
    entry = entry or "String entry",
    line = line or 0,
    width = width or #entry,
    height = height or 1,
    active = true,
    dirty = true
  }

  lcdLines[line].dirty = true
  setmetatable(Pshr.Text, {__index = UI})
  setmetatable(text, Pshr.Text)

  return text
end

--- Redraw text block. --Call when changed.
function Pshr.Text:redraw()

  local pos = 1
  local charVal

  for i=(7 + self.x),(6 + self.x + self.width),1 do
    if self.entry == nil then charVal = 32
    elseif pos <= string.len(self.entry) then
      charVal = string.byte(self.entry, pos)
    else
    charVal = 32
    end

    if charVal > 127 then charval = 1 end

    lcdLines[self.line].message[i] = charVal
    pos = pos + 1
  end
  lcdLines[self.line].dirty = true
  self.dirty = false
end

-------- Text Block END --------


return Pshr
