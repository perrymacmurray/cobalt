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

while true do
    local result, _ = pcall(shell.getShell())
    if not result then
        break
    end
end