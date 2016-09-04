-- This is a modified copy of the build-in excavate program

local tArgs = { ... }
if #tArgs < 1 or #tArgs > 4 then
	print( "Usage: excavate <diameter> [<depth> <forward> <right>]" )
	return
end

-- Network functions for reporting stuff:
local modem = peripheral.wrap("right")

local function message(msg)
	modem.transmit(1, 2, "msg:"..msg)
end

local function pmsg(msg)
	print(msg)
	message(msg)
end

local function reportInv()
	local details = {}

	for n=1,16 do
		local detail = turtle.getItemDetail(n)
		if detail then
			if details[detail.name] == nil then details[detail.name] = 0 end
			details[detail.name] = details[detail.name] + detail.count
		end
	end

	local report = "inv:"
	for name,count in pairs(details) do
		report = report..name..": x"..count.."\n"
	end

	modem.transmit(1,2, report)
end

-- Mine in a quarry pattern until we hit something we can't dig
local size = tonumber( tArgs[1] )
if size < 1 then
	pmsg( "Excavate diameter must be positive" )
	return
end

local xOffs = 0
local yOffs = 0
local zOffs = 0

if #tArgs >= 2 then yOffs = tonumber( tArgs[2] ) end
if #tArgs >= 3 then zOffs = tonumber( tArgs[3] ) end
if #tArgs >= 4 then xOffs = tonumber( tArgs[4] ) end

local depth = 0
local unloaded = 0
local collected = 0

local xPos,zPos = 0,0
local xDir,zDir = 0,1

local goTo -- Filled in further down
local refuel -- Filled in further down
local goHome -- Filled in further down
local goStart -- Filled in further down

local function unload( nKeepFuel )
	pmsg( "Unloading items..." )
	for n=1,16 do
		local nCount = turtle.getItemCount(n)
		if nCount > 0 then
			turtle.select(n)
			local bDrop = true
			if nKeepFuel > 0 and turtle.refuel(0) then
				bDrop = false
				nKeepFuel = nKeepFuel - 1
			end
			if bDrop then
				turtle.drop()
				unloaded = unloaded + nCount
			end
		end
	end
	collected = 0
	turtle.select(1)
end

local function returnSupplies()
	local x,y,z,xd,zd = xPos,depth,zPos,xDir,zDir
	pmsg( "Returning to surface..." )
	goTo(xOffs, yOffs, zOffs, xd, zd)
	goHome(-1)

	local fuelNeeded = 2*(x+y+z+xOffs+yOffs+zOffs) + 2
	if not refuel( fuelNeeded ) then
		unload( 3 )
		pmsg( "Waiting for fuel" )
		while not refuel( fuelNeeded ) do
			os.pullEvent( "turtle_inventory" )
		end
	else
		unload( 3 )
	end

	pmsg( "Resuming mining..." )
	goStart()
	goTo( x,y,z,xd,zd )
end

local function collect()
	local bFull = true
	local nTotalItems = 0
	for n=1,16 do
		local data = turtle.getItemDetail(n)
		local nCount = 0

		if data then
			nCount = data.count

			-- Drop cobblestone if we already have a stack
			if data.name == "minecraft:cobblestone" and data.count == 64 then
				local oldS = turtle.getSelectedSlot()
				turtle.select(n) turtle.dropUp() turtle.select(oldS)
				nCount = 0
			end
		end

		if nCount == 0 then
			bFull = false
		end
		nTotalItems = nTotalItems + nCount
	end

	reportInv()

	if nTotalItems > collected then
		collected = nTotalItems
		if math.fmod(collected + unloaded, 50) == 0 then
			pmsg( "Mined "..(collected + unloaded).." items." )
		end
	end

	if bFull then
		pmsg( "No empty slots left." )
		return false
	end
	return true
end

function refuel( ammount )
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" then
		return true
	end

	local needed = ammount or (xPos + zPos + depth + 2)
	if turtle.getFuelLevel() < needed then
		local fueled = false
		for n=1,16 do
			if turtle.getItemCount(n) > 0 then
				turtle.select(n)
				if turtle.refuel(1) then
					while turtle.getItemCount(n) > 0 and turtle.getFuelLevel() < needed do
						turtle.refuel(1)
					end
					if turtle.getFuelLevel() >= needed then
						turtle.select(1)
						return true
					end
				end
			end
		end
		turtle.select(1)
		return false
	end

	return true
end

local function tryForwards()
	if not refuel() then
		pmsg( "Not enough Fuel" )
		returnSupplies()
	end

	while not turtle.forward() do
		if turtle.detect() then
			if turtle.dig() then
				if not collect() then
					returnSupplies()
				end
			else
				return false
			end
		elseif turtle.attack() then
			if not collect() then
				returnSupplies()
			end
		else
			sleep( 0.5 )
		end
	end

	xPos = xPos + xDir
	zPos = zPos + zDir
	return true
end

local function tryDown()
	if not refuel() then
		pmsg( "Not enough Fuel" )
		returnSupplies()
	end

	while not turtle.down() do
		if turtle.detectDown() then
			if turtle.digDown() then
				if not collect() then
					returnSupplies()
				end
			else
				return false
			end
		elseif turtle.attackDown() then
			if not collect() then
				returnSupplies()
			end
		else
			sleep( 0.5 )
		end
	end

	depth = depth + 1
	if math.fmod( depth, 10 ) == 0 then
		pmsg( "Descended "..depth.." metres." )
	end

	return true
end

local function turnLeft()
	turtle.turnLeft()
	xDir, zDir = -zDir, xDir
end

local function turnRight()
	turtle.turnRight()
	xDir, zDir = zDir, -xDir
end

function goHome(zd)
	goTo(0, 0, 0, 0, zd)
end

function goStart()
	goTo(xOffs, yOffs, zOffs, 0, 1, {moveFirst='z'})
end

function goTo( x, y, z, xd, zd, opts )
	while depth > y do
		if turtle.up() then
			depth = depth - 1
		elseif turtle.digUp() or turtle.attackUp() then
			collect()
		else
			sleep( 0.5 )
		end
	end

	local function moveX()
		if xPos > x then
			while xDir ~= -1 do
				turnLeft()
			end
			while xPos > x do
				if turtle.forward() then
					xPos = xPos - 1
				elseif turtle.dig() or turtle.attack() then
					collect()
				else
					sleep( 0.5 )
				end
			end
		elseif xPos < x then
			while xDir ~= 1 do
				turnLeft()
			end
			while xPos < x do
				if turtle.forward() then
					xPos = xPos + 1
				elseif turtle.dig() or turtle.attack() then
					collect()
				else
					sleep( 0.5 )
				end
			end
		end
	end

	local function moveZ()
		if zPos > z then
			while zDir ~= -1 do
				turnLeft()
			end
			while zPos > z do
				if turtle.forward() then
					zPos = zPos - 1
				elseif turtle.dig() or turtle.attack() then
					collect()
				else
					sleep( 0.5 )
				end
			end
		elseif zPos < z then
			while zDir ~= 1 do
				turnLeft()
			end
			while zPos < z do
				if turtle.forward() then
					zPos = zPos + 1
				elseif turtle.dig() or turtle.attack() then
					collect()
				else
					sleep( 0.5 )
				end
			end
		end
	end

	if opts then
		if opts.moveFirst == 'z' then
			moveZ()
			moveX()
		else
			moveX()
			moveZ()
		end
	else
		moveX()
		moveZ()
	end

	while depth < y do
		if turtle.down() then
			depth = depth + 1
		elseif turtle.digDown() or turtle.attackDown() then
			collect()
		else
			sleep( 0.5 )
		end
	end

	while zDir ~= zd or xDir ~= xd do
		turnLeft()
	end
end

if not refuel() then
	pmsg( "Out of Fuel" )
	return
end

pmsg( "Excavating..." )

local reseal = false
turtle.select(1)
if turtle.digDown() then
	reseal = true
end

local alternate = 0
local done = false

goStart()

while not done do
	for n=1,size do
		for m=1,size-1 do
			if not tryForwards() then
				done = true
				break
			end
		end
		if done then
			break
		end
		if n<size then
			if math.fmod(n + alternate,2) == 0 then
				turnLeft()
				if not tryForwards() then
					done = true
					break
				end
				turnLeft()
			else
				turnRight()
				if not tryForwards() then
					done = true
					break
				end
				turnRight()
			end
		end
	end
	if done then
		break
	end

	if size > 1 then
		if math.fmod(size,2) == 0 then
			turnRight()
		else
			if alternate == 0 then
				turnLeft()
			else
				turnRight()
			end
			alternate = 1 - alternate
		end
	end

	if not tryDown() then
		done = true
		break
	end
end

pmsg( "Returning to surface..." )

-- Return to where we started
goStart()
goHome(-1)
unload( 0 )
goHome(1)

-- Seal the hole
if reseal then
	turtle.placeDown()
end

pmsg( "DONE! Mined "..(collected + unloaded).." items total." )
