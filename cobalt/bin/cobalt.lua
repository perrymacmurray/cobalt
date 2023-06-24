local fs = require("filesystem");
local component = require("component");

local internet = component.internet;

print("Welcome to the Cobalt setup!");

if (not fs.exists("/etc/cobalt/uid")) then
    print("This computer currently does not have a UID.")
    print("Please enter the desired UID, or press enter to generate a new one")
    local uid = io.read();
    if (uid == "" or uid == nil) then
        print("Generating UID...");
        uid = require("uuid").next();
        print("UUID:", uid);
    end
    fs.makeDirectory("/etc/cobalt");
    io.open("/etc/cobalt/uid", "w");
    io.write(uid);
    io.close();
end

if (internet != nil) then
    --todo
elseif
    print("WARNING: This computer cannot connect to the Internet, severely limiting Cobalt's functionality.")
end