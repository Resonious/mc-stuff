local glass = peripheral.wrap("left")
local modem = peripheral.wrap("back")

local turtleState = {
  message = "no message yet"
}

local function render()
  glass.clear()

  local x = 1
  local y = 1

  -- Render time
  glass.addBox(x,y,80,10,0xFFFFFF,0.2)
  time = textutils.formatTime(os.time(), false)
  glass.addText(x+4,y+1,"TIME: " .. time, 0xFF0000)
  y = y + 12

  -- Render turtle state
  glass.addBox(x,y, 100,10, 0xFFFF00, 0.2)
  glass.addText(x+4,y+1, turtleState.message, 0x000000)

  glass.sync()
end

local function telltime()
  while true do
    sleep(0.1)
    render()
  end
end

local function receive()
  modem.open(1)

  while true do
    local event, side, replyCh, message, dist = os.pullEvent("modem_message")

    local prefix = string.sub(message,0,4)
    local payload = string.sub(message,5)

    if prefix == "msg:" then
      turtleState.message = payload
    else
      print("BAD MODEM MESSAGE: "..message)
    end
  end
end

parallel.waitForAll(
  telltime,
  receive
)
