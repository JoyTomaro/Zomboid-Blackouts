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

BlackoutsClientFunctions.shutoffPower = function()
    BlackoutsEventHandler.shutoffPower() --?? calls function in BlackoutsEventHandler.lua
end

BlackoutsClientFunctions.restorePower = function()
    BlackoutsEventHandler.restorePower() --?? calls function in BlackoutsEventHandler.lua
end

--** silently turns off power when syncing players who join a server during a blackout
BlackoutsClientFunctions.disablePower = function()
    getWorld():setHydroPowerOn(false)
end

Events.OnServerCommand.Add(BlackoutsClientFunctions.processServerCommand)
return BlackoutsClientFunctions
