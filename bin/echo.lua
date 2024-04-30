local arg = {...}

local buffer = ""

for i, v in ipairs(arg) do
    if i == 1 then
        buffer = v
    else
        buffer = buffer .. " " .. v
    end
end

io.println(buffer)