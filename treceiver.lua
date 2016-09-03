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
  glass.addText(5,2,"TIME: " .. time, 0xFF0000)
  y = y + 12

  -- Render turtle state
  glass.addBox(x,y, 100,50, 0xFFFF00, 0.2)
  glass.addText(5,92, turtleState.message, 0x000000)

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
  end
end

parallel.waitForAll(
  telltime,
  receive
)
