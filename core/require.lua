local require = function(file)
    local buffer = ""
    local f = fs.open(file)
    if f == nil then return nil end

    repeat
        local data = f:read(math.maxinteger)
        buffer = buffer .. data
    until not data

    f:close()

    return load(buffer, "=" .. file, "bt", _G)()
end

return require