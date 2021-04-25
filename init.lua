local addr, invoke = computer.getBootAddress(), component.invoke
local function loadfile(file)
  local handle = assert(invoke(addr, "open", file))
  local buffer = ""
  repeat
    local data = invoke(addr, "read", handle, math.huge)
    buffer = buffer .. (data or "")
  until not data
  invoke(addr, "close", handle)
  return load(buffer, "=" .. file, "bt", _G)
end

do
  loadfile("/lib/core/boot.lua")(loadfile)
end

if runtype == 1 then
  while true do
    os.execute("/etc/cobalt/embed.lua")
    io.stderr:write("\nEmbedded program exited - relaunching\n")
    os.sleep(0.1)
  end
elseif runtype == 2 then -- Normal OpenOS shell handling
  while true do
    local result, reason = xpcall(require("shell").getShell(), function(msg)
      return tostring(msg).."\n"..debug.traceback()
    end)
    if not result then
      io.stderr:write((reason ~= nil and tostring(reason) or "unknown error") .. "\n")
      io.write("Press any key to continue.\n")
      os.sleep(0.5)
      require("event").pull("key")
    end
  end
end