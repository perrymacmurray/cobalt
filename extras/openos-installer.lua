-- This script installs Cobalt onto a specified drive, and is intented to be run with OpenOS
-- As such, it uses OpenOS libraries, OpenOS-style requires, etc etc...

-- Stop this script from running on Cobalt
if string.match(_G._OSVERSION, "COBALT") then
    io.println("This script is not compatible with your operating system.")
    return
end

local component = require("component")
local fs = require("filesystem")
local inet = require("internet")
local shell = require("shell")

local args, ops = shell.parse(...)

-- Github API url of the repository
local URL = "https://api.github.com/repos/perrymacmurray/cobalt/git/trees/master?recursive=1"

local root = args[1] -- root file to install everything in
if root == nil then
    io.stderr:write("Must specify directory! Exiting\n")
    return
end

if not fs.isDirectory(root) then
    io.stderr:write("The specified directory '" .. root .. "' does not exist! Exiting\n")
    return
end

if not ops["y"] then
    io.stdout:write("The Cobalt operating system will be installed in the following directory: " .. root .. "\n")
    io.stdout:write("This will overwrite any existing files at this directory and in its subdirectories!\n")
    io.stdout:write("Type 'y' to continue. Otherwise, program will exit\n")

    if not string.lower(io.stdin:read()) == "y" then
        io.stdout:write("Exiting")
        return
    end
end

-- Download JSON library (it's so stupid this isn't included in OpenOS, imo)
if not fs.exists("/lib/json.lua") then
    io.stdout:write("Downloading JSON library...\n")
    if not shell.execute("wget -fq https://raw.githubusercontent.com/perrymacmurray/cobalt/master/lib/json.lua /lib/json.lua") then
        io.stderr:write("Failed to download JSON library! Exiting\n")
        return
    end
end
local json = require("json")

-- Actually run program
for path in fs.list(root) do fs.remove(root .. "/" .. path) end

local data = ""
for chunk in inet.request(URL) do data = data .. chunk end
data = json.decode(data)

local ghr = "https://raw.githubusercontent.com/perrymacmurray/cobalt/master/"
for _, dep in ipairs(data.tree) do
    -- Because OpenOS doesn't include a base64 library EITHER, we're actually going to use wget here, putting
    -- the file in "root .. <github path>". This design decision is stupid - maybe I should make my own OS?
    if dep.type == "tree" then
        fs.makeDirectory(root .. "/" .. dep.path)
    else
        io.stdout:write("Downloading " .. dep.path .. "\n")
        if not shell.execute("wget -fq " .. ghr .. dep.path .. " " .. root .. "/" .. dep.path) then
            io.stderr:write("Failed!\n")
            return
        end
    end
end

io.stdout:write("Done!\n")