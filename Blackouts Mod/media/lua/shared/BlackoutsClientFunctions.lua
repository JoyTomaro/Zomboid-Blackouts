----------------------------------------------------------------------------
--Blackouts Mod | --**Thanks to the Project Zomboid Discord server for help!**
----------------------------------------------------------------------------
local BlackoutsEventHandler = require("BlackoutsEventHandler")
local BlackoutsClientFunctions = {}

--** processes directClients from BlackoutsMainFunctions and distributes command to proper function
BlackoutsClientFunctions.processServerCommand = function(module, command, packet)
    if not (module == "TomaroBlackouts" and BlackoutsClientFunctions[command]) then return end
    BlackoutsClientFunctions[command](packet)
end

BlackoutsClientFunctions.shutoffPower = function(packet)
    BlackoutsEventHandler.serverModData = packet and packet.serverModData
    BlackoutsEventHandler.shutoffPower() --?? calls function in BlackoutsEventHandler.lua
end

BlackoutsClientFunctions.restorePower = function(packet)
    BlackoutsEventHandler.serverModData = packet and packet.serverModData
    BlackoutsEventHandler.restorePower() --?? calls function in BlackoutsEventHandler.lua
end

--** silently turns off power when syncing players who join a server during a blackout
BlackoutsClientFunctions.disablePower = function(packet)
    BlackoutsEventHandler.serverModData = packet and packet.serverModData
    getWorld():setHydroPowerOn(false)
end

--** silently restores power when syncing players who join a server with a modded shutoff time
BlackoutsClientFunctions.enablePower = function(packet)
    BlackoutsEventHandler.serverModData = packet and packet.serverModData
    getWorld():setHydroPowerOn(true)
end

--** provides mod data to newly connected player
BlackoutsClientFunctions.informNewConnection = function(packet)
    BlackoutsEventHandler.serverModData = packet and packet.serverModData
end

Events.OnServerCommand.Add(BlackoutsClientFunctions.processServerCommand)
return BlackoutsClientFunctions
