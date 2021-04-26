local component = require("component")
local fs = require("filesystem")
local gpu = component.gpu

-- GPU Pre-Configuration
local supportColor = not (gpu.getDepth == 1) -- Used for GUI

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
            for int i = 1, #proxy.getSensorInformation() do
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

            local function getOutput(gen)
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

        for path in fs.list("/embed/generators/") do
            local file = io.open("/embed/generators/" .. path)
            table.insert(outputs, file:read())
            file:close()
        end

        table.insert(generators, proxy)
    end
end

--while true do -- Main loop
    --todo
--end