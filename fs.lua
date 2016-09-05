local modem = peripheral.wrap("back")
local ch = 50001

modem.open(ch+1)

local function send(msg)
  modem.transmit(ch, ch+1, msg)
end

local function input()
  while true do
    local event, key, held = os.pullEvent("key")

    if     key == keys.up    then send("^")
    elseif key == keys.down  then send("v")
    elseif key == keys.left  then send("<")
    elseif key == keys.right then send(">")
    elseif key == keys.w     then send("up")
    elseif key == keys.s     then send("down")
    elseif key == keys.leftCtrl or key == keys.rightCtrl then send("atk")
    elseif key == keys.leftShift or key == keys.rightShift then send("refuel")
    end
  end
end

local function log()
  while true do
    local event, side, _ch, replyCh, msg, dist = os.pullEvent("modem_message")
    print(msg)
  end
end

parallel.waitForAll(
  input,
  log
)
