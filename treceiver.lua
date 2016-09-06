local glass = peripheral.wrap("left")
local modem = peripheral.wrap("back")

local tArgs = { ... }

local listenCh = -1
if #tArgs >= 1 then listenCh = tonumber(tArgs[1])
else print("please specify listen channel") return end

local sendCh = 1000 + listenCh

local turtleState = {
  message = "no message yet",
  items   = "...\nno item report yet"
}

local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={} ; i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end
  return t
end

local function render()
  if glass then
    glass.clear()

    local x = 1
    local y = 1

    -- Render time
    glass.addBox(x,y,80,10,0xFFFFFF,0.2)
    time = textutils.formatTime(os.time(), false)
    glass.addText(x+4,y+1,"TIME: " .. time, 0xFF0000)
    y = y + 12

    -- Render turtle state
    local itemLines = split(turtleState.items, "\n")
    local h = 13 + #itemLines * 9

    glass.addBox(x,y, 150,h, 0xFFFF00, 0.2)
    glass.addText(x+4,y+1, turtleState.message, 0x000000)
    y = y + 11

    for i,str in ipairs(itemLines) do
      glass.addText(x+4,y+1, str, 0x000000)
      y = y + 9
    end

    glass.sync()
  else
    term.clear()
    print("==CH: "..listenCh.."==")
    print(turtleState.message)
    print("---inv:")
    write(turtleState.items)
    print("========")
  end
end

local function telltime()
  while true do
    sleep(0.1)
    render()
  end
end

local function receive()
  modem.open(listenCh)

  while true do
    local event, side, ch, replyCh, message, dist = os.pullEvent("modem_message")

    local prefix = string.sub(message,0,4)
    local payload = string.sub(message,5)

    if prefix == "msg:" then
      turtleState.message = payload
    elseif prefix == "inv:" then
      turtleState.items = payload
    end

    modem.transmit(sendCh, sendCh+1, message)
  end
end

parallel.waitForAll(
  telltime,
  receive
)
