local require = function(file)
    local buffer = ""
    local f = fs.open(file)
    if f == nil then return nil end

    while true do
        local data = f:read(math.maxinteger)
        if data == nil then break end

        buffer = buffer .. data
    end

    f:close()

    return load(buffer, "=" .. file, "bt", _G)
end

return require