local component = require("component")
local fs = require("filesystem")
local gpu = component.gpu

TARGETENERGY = 0.8

-- Functions
function getOutput(gen)
    if gen.getEUOutputAverage and gen.getEUOutputAverage() ~= 0 then
        return gen.getEUOutputAverage()
    elseif gen.getSensorInformation then
        for i = 1, #gen.getSensorInformation() do
            if string.match(gen.getSensorInformation()[i], "EU/t") then
                local a, b = string.gsub(gen.getSensorInformation()[i], "[^%d]", '')
                return tonumber(a)
            end
        end
    end
    return -1
end

-- GPU Pre-Configuration
local supportColor = not (gpu.getDepth() == 1) -- Used for GUI

gpu_w, gpu_h = gpu.maxResolution()
gpu.setResolution(gpu_w, gpu_h)

bar_w = math.floor(gpu_w / 6) -- Three bars, which should all be to the far left

-- Machine discovery
generators = {}
eu_objects = {}

outputs = {}

if not fs.exists("/embed/generators") then -- Folder with known generator outputs
    fs.makeDirectory("/embed/generators")
end

for address, _ in component.list("gt_machine") do
    io.write("Reading machine " .. address .. '\n')
    local proxy = component.proxy(address)

    if proxy.getEUCapacity() > 0 then
        table.insert(eu_objects, proxy)
    end

    local isGen = false
    if proxy.isWorkAllowed then
        if proxy.getWorkMaxProgress() <= 2 then -- Generators (usually) have work but with no/little progress
            isGen = true
        elseif proxy.getEUCapacity() == 0 then -- Sometimes, generators have no EU storage. This tries to catch generators that have work, just in case.
            isGen = true
        elseif proxy.getSensorInformation then -- Last resort
            for i = 1, #proxy.getSensorInformation() do
                if string.match(proxy.getSensorInformation()[i], "Turbine") then
                    isGen = true
                elseif string.match(proxy.getSensorInformation()[i], "Engine") then
                    isGen = true
                elseif string.match(proxy.getSensorInformation()[i], "Generator") then
                    isGen = true
                end
            end
        end
    end

    if isGen then
        proxy.setWorkAllowed(false) -- Ensure generator is off

        if not fs.exists("/embed/generators/" .. address) then -- Find max output
            io.write("Discovering new generator " .. address .. "...\n")
            proxy.setWorkAllowed(true)

            local output = -2
            local output_new = 0
            while output_new > output + 1 do
                output = getOutput(proxy)
                os.sleep(10) -- Wait for performance to improve
                output_new = getOutput(proxy)
            end

            proxy.setWorkAllowed(false)

            io.write("...Maximum energy output recorded as " .. output .. " EU/t\n")

            local file = io.open("/embed/generators/" .. address, "w")
            file:write(output)
            file:close()
        end

        local file = io.open("/embed/generators/" .. address)
        table.insert(outputs, file:read())
        file:close()

        table.insert(generators, proxy)
    end
end

totalBattery = 0
currentBattery = 0
for i = 1, #eu_objects do
    totalBattery = totalBattery + eu_objects[i].getEUCapacity()
end

prev_currentBattery = 0

currentGeneration = 0
maxGeneration = 0
for i = 1, #outputs do
    maxGeneration = maxGeneration + outputs[i]
end

while true do -- Main loop
    -- Get important variables
    prev_currentBattery = currentBattery
    currentBattery = 0
    currentGeneration = 0

    for i = 1, #eu_objects do
        currentBattery = currentBattery + eu_objects[i].getStoredEU()
    end

    for i = 1, #generators do
        currentGeneration = currentGeneration + getOutput(generators[i])
    end

    local batteryPerc = currentBattery / totalBattery
    local genPerc = currentGeneration / maxGeneration
    local batteryChange = ((currentBattery - prev_currentBattery) * 100) / totalBattery --constant may require tuning
    if batteryChange > 1 then
        batteryChange = 1
    elseif batteryChange < -1 then
        batteryChange = -1
    end

    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, gpu_w, gpu_h, ' ')

    -- Bar 1
    if supportColor then
        gpu.setForeground(0x00FF00)
        gpu.fill(1, math.floor((1 - batteryPerc) * gpu_h) + 1, bar_w, gpu_h, "█")
    else
        gpu.fill(1, math.floor((1 - batteryPerc) * gpu_h) + 1, bar_w, gpu_h, "#")
    end

    -- Bar 2
    if supportColor then
        gpu.setForeground(0xFF0000)
        gpu.fill(bar_w + 1, math.floor((1 - genPerc) * gpu_h) + 1, bar_w, gpu_h, "█")
    else
        gpu.fill(bar_w + 1, math.floor((1 - genPerc) * gpu_h) + 1, bar_w, gpu_h, "█")
    end

    -- Bar 3
    if supportColor then
        gpu.setForeground(0x0088FF)
        gpu.fill(2 * bar_w + 1, math.floor(gpu_h / 2) - math.floor((1 - batteryChange) * gpu_h), bar_w, math.floor(gpu_h / 2), "█")
    else
        gpu.fill(2 * bar_w + 1, math.floor((1 - batteryChange) * gpu_h) + math.floor(gpu_h / 2), bar_w, math.floor(gpu_h / 2), "X")
    end

    -- Diagnostics
    --TODO

    -- Decision-making
    if TARGETENERGY > batteryPerc + 0.5 then
        for i = 1, #generators do
            generators[i].setWorkAllowed(true)
        end
        if batteryChange < 0 then
            component.computer.beep(1300, 1) -- Alarm if low and losing power
        end
    elseif TARGETENERGY > batteryPerc + 0.2 then
        if batteryChange > 0 then
            smallest = nil
            for i = 1, #generators do
                if smallest ~= nil and getOutput(smallest) == 0 then goto continue end

                if smallest == nil then
                   smallest = generators[i]
                elseif getOutput(smallest) > getOutput(generators[i]) then
                    smallest = generators[i]
                end
                ::continue::
            end

            if batteryChange - getOutput(smallest) > 0 then
                smallest.setWorkAllowed(false)
            end
        else
            largest = nil
            for i = 1, #generators do
                if largest == nil and generators[i].isWorkAllowed() == false then
                   largest = generators[i]
                elseif getOutput(largest) < getOutput(generators[i]) and generators[i].isWorkAllowed() == false then
                    largest = generators[i]
                end
            end

            if largest == nil then
                component.computer.beep(1300, 0.3) -- Alarm if losing power with all machines
            else
                largest.setWorkAllowed(true)
            end
        end
    elseif TARGETENERGY + 0.05 < batteryPerc then
        for i = 1, #generators do
            generators[i].setWorkAllowed(false)
        end
    end

    -- Wait
    os.sleep(2)
end