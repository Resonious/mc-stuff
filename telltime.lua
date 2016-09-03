local glass = peripheral.wrap("left")

function addBox()
  glass.addBox(1,1,80,10,0xFFFFFF,0.2)
end

function timeDis()
  time = textutils.formatTime(os.time(), false)
  glass.addText(5,2,"TIME: " .. time, 0xFF0000)
end

function start()
 while true do
    glass.clear()
    addBox()
    timeDis()
    glass.sync()
    sleep(0.1)
  end
end

start()
