local arg = ...

local function magiclines(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

local f = fs.open(arg, "r")

local buffer = ""
while true do
    local data = f:read(500)
    if data == nil then break end
    buffer = buffer .. data
    thread.yield() -- some of these files can be rather large
end

for s in magiclines(buffer) do
    io.println(s)
end

f:close()