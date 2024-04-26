do -- I kind of hate this but I think OpenOS had it right
    local addr = computer.getBootAddress()

    local function loadfile(file)
        local handle = assert(component.invoke(addr, "open", file))
        local buffer = ""
        repeat
            local data = component.invoke(addr, "read", handle, math.maxinteger)
            buffer = buffer .. (data or "")
        until not data
        component.invoke(addr, "close", handle)

        return load(buffer, "=" .. file, "bt", _G)
    end

    loadfile("/core/kernel.lua")(loadfile)
end

_, err = xpcall(kernel.scheduler.begin, function(err)
    if kernel.runlevel() ~= 0 then kernel.panic(err) end
end)

-- Make it abundantly obvious if we panic
while true do
    computer.beep(2000, 0.5)
    computer.beep(1000, 0.5)
end

-- Try and keep panic on screen, but otherwise crash with message
computer.crash(err)