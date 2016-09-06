local modem = peripheral.wrap("right")
local ch = 50001

modem.open(ch)

local function log(rch, msg)
  print(msg)
  -- rch does not work for some reason (it's nil don't know why)
  modem.transmit(ch+1, ch, msg)
end

local function checkFuel(rch)
  if turtle.getFuelLevel() == 0 then
    log(rch, "Out of fuel!")
    return false
  end
  return true
end

local function move(rch, dir)
  if not checkFuel() then return false end
  if turtle[dir]() then
    log(rch, "FUEL: "..turtle.getFuelLevel())
  else
    log(rch, "Failed to move "..dir)
  end
end

local function turn(rch, dir)
  if not turtle["turn"..dir]() then
    log(rch, "Failed to turn "..dir)
  end
end

local function attack(rch)
  local f, u, d = turtle.attack(), turtle.attackUp(), turtle.attackDown()
  if f or u or d then
    log(rch, "Hit!")
  else
    log(rch, "No hit")
  end
end

local function refuel(rch)
  if turtle.refuel() then
    log(rch, "Now at "..turtle.getFuelLevel().." fuel")
  else
    log(
      rch,
      "Couldn't do it. Either full "
      ..turtle.getFuelLevel()
      .." or you gotta stick a fuel item in slot 1"
    )
  end
end

while true do
  local event, side, _ch, rch, msg, dist = os.pullEvent("modem_message")
  rch = ch + 1

  if     msg == '^'    then move(rch, "forward")
  elseif msg == 'v'    then move(rch, "backward")
  elseif msg == '<'    then turn(rch, "Left")
  elseif msg == '>'    then turn(rch, "Right")
  elseif msg == 'atk'  then attack(rch)
  elseif msg == 'up'   then move(rch, "up")
  elseif msg == 'down' then move(rch, "down")
  elseif msg == 'refuel' then refuel(rch)
  end
end
