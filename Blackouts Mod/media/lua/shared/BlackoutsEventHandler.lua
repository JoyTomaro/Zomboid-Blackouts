----------------------------------------------------------------------------
--Blackouts Mod | --**Thanks to the Project Zomboid Discord server for help!**
----------------------------------------------------------------------------
require "lua_timers" --?? lua timers by vishnya. requires this API so sound effects are timed properly
local BlackoutsEventHandler = {}

--** overrides power shutoff date
BlackoutsEventHandler.overrideShutoffDate = function()
    if SandboxVars.Blackouts.Override > 0 then
        SandboxVars.ElecShutModifier = SandboxVars.Blackouts.Override
    end
end

BlackoutsEventHandler.getNearestBuildingSquare = function()
    local player = getPlayer()
    local vector = Vector2f.new()
    local closestBuilding = AmbientStreamManager.getInstance():getNearestBuilding(player:getX(), player:getY(), vector)
    local closestSquare = closestBuilding and getSquare(closestBuilding:getX(), closestBuilding:getY(), player:getZ())

    return closestSquare
end

BlackoutsEventHandler.shutoffPower = function()
    local player = getPlayer()
    local playerSquare = player and player:getSquare()

    if playerSquare then
        if not playerSquare:isOutside() then
            player:playSoundLocal("PowerShutoff")
        elseif playerSquare:isOutside() then
            local buildingSquare = BlackoutsEventHandler.getNearestBuildingSquare()
            if buildingSquare then 
                getSoundManager():PlayWorldSound("PowerShutoff", buildingSquare, 1, 0, 0, true) 
            end
        end
    end

    timer:Simple(0.9, function()
        getWorld():setHydroPowerOn(false)
    end)

end

BlackoutsEventHandler.restorePower = function()
    local player = getPlayer()
    local playerSquare = player and player:getSquare()

    if playerSquare then    
        if not playerSquare:isOutside() then
            player:playSoundLocal("PowerStartup")
        elseif playerSquare:isOutside() then
            local buildingSquare = BlackoutsEventHandler.getNearestBuildingSquare()
            if buildingSquare then 
                getSoundManager():PlayWorldSound("PowerStartup", buildingSquare, 1, 0, 0, true) 
            end
        end
    end
    
    timer:Simple(0.8, function()
        getWorld():setHydroPowerOn(true)
    end)

end

--** tick delay to immediately sync players who join a server during a blackout
BlackoutsEventHandler.tickDelay = 5

BlackoutsEventHandler.requestPowerState = function()

    if BlackoutsEventHandler.tickDelay == 5 then
        BlackoutsEventHandler.tickDelay = BlackoutsEventHandler.tickDelay - 1
        Events.OnTick.Add(BlackoutsEventHandler.requestPowerState)
    elseif BlackoutsEventHandler.tickDelay > 0 then
        BlackoutsEventHandler.tickDelay = BlackoutsEventHandler.tickDelay - 1
    else
        Events.OnTick.Remove(BlackoutsEventHandler.requestPowerState)
        if getPlayer() then
            sendClientCommand(getPlayer(), "TomaroBlackouts", "requestPowerState", {})
        end
    end

end

--** admin commands for testing, or for other modders or server owners to trigger blackouts manually
BlackoutsEventHandler.forceShutoff = function()
    print("Command triggered... Force shutting power")
    sendClientCommand("TomaroBlackouts", "shutoffPower", {force = true})
end

BlackoutsEventHandler.forceRestore = function()
    print("Command triggered... Force restoring power")
    sendClientCommand("TomaroBlackouts", "restorePower", {force = true})
end

LuaEventManager.AddEvent("BlackoutsForceShutoff")
LuaEventManager.AddEvent("BlackoutsForceRestore")

Events.BlackoutsForceShutoff.Add(BlackoutsEventHandler.forceShutoff)
Events.BlackoutsForceRestore.Add(BlackoutsEventHandler.forceRestore)

Events.OnCreatePlayer.Add(BlackoutsEventHandler.requestPowerState)

Events.OnLoad.Add(BlackoutsEventHandler.overrideShutoffDate)
if isServer() then Events.OnServerStarted.Add(BlackoutsEventHandler.overrideShutoffDate) end
Events.OnSave.Add(BlackoutsEventHandler.overrideShutoffDate)
if isServer() then Events.OnServerStartSaving.Add(BlackoutsEventHandler.overrideShutoffDate) end

return BlackoutsEventHandler
