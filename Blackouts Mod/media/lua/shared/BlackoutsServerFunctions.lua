----------------------------------------------------------------------------
--Blackouts Mod | --**Thanks to the Project Zomboid Discord server for help!**
----------------------------------------------------------------------------
if isClient() then return end

local BlackoutsServerFunctions = {}

BlackoutsServerFunctions.shutoffTimeDelayedByOverride = function()
    return SandboxVars.Blackouts.Override > 0 and getGameTime():getNightsSurvived() + 1 < SandboxVars.ElecShutModifier
end

--** global mod data that handles essential information for this mod
BlackoutsServerFunctions.initializeModData = function()
    local modData = ModData.getOrCreate("tmrblackouts")

    if not modData.ready then
        modData.cooldown = modData.cooldown or SandboxVars.Blackouts.InitialCooldown
        modData.recoverytime = modData.recoverytime or SandboxVars.Blackouts.Duration * 6
        modData.eventplaying = modData.eventplaying or false
        modData.ready = true
    end

    if modData.eventplaying then
        getWorld():setHydroPowerOn(false)
    elseif BlackoutsServerFunctions.shutoffTimeDelayedByOverride() then
        getWorld():setHydroPowerOn(true)
    end

    return modData
end

--** conditions to execute a blackout
BlackoutsServerFunctions.shutoffPower = function(packet)
    local modData = ModData.getOrCreate("tmrblackouts")
    local blackoutchance = SandboxVars.Blackouts.Chance
    local force = packet and packet.force

    if getGameTime():getNightsSurvived() + 1 < SandboxVars.ElecShutModifier and not modData.eventplaying or force then
        
        if modData.cooldown >= 1 then
            modData.cooldown = modData.cooldown - 1
        end

        if modData.cooldown <= 0 or force then
            local climate = getClimateManager()

            --?? conditions for bonus roll during intense weather
            local isWeatherEvent = SandboxVars.Blackouts.WeatherEvent and
                climate:getPrecipitationIntensity() > 0.7 and
                climate:getWindIntensity() > 0.7 and
                ZombRand(100) <= blackoutchance

            --?? conditions for bonus roll when close to shutoff date
            local isRampUpEvent = SandboxVars.Blackouts.RampUp and 
                SandboxVars.ElecShutModifier - getGameTime():getNightsSurvived() < 14 and 
                ZombRand(100) <= blackoutchance

            if ZombRand(100) <= blackoutchance or isRampUpEvent or isWeatherEvent or force then

                modData.eventplaying = true --?? recognizes the server to be in a blackout state
                if isServer() then getWorld():setHydroPowerOn(false) end
                BlackoutsServerFunctions.directClients("TomaroBlackouts", "shutoffPower", { serverModData = modData })
                modData.recoverytime = SandboxVars.Blackouts.Duration * 6

            end
        end
    end
end

--** conditions to end a blackout
BlackoutsServerFunctions.restorePower = function(packet)
    local modData = ModData.getOrCreate("tmrblackouts")
    local blackoutrecovery = SandboxVars.Blackouts.Recovery
    local force = packet and packet.force
    
    if getGameTime():getNightsSurvived() + 1 < SandboxVars.ElecShutModifier and modData.eventplaying or force then
        
        if modData.recoverytime >= 1 then
            modData.recoverytime = modData.recoverytime - 1
        end

        if modData.recoverytime <= 0 or force then
            if ZombRand(100) < blackoutrecovery or force then

                modData.eventplaying = false --?? recognizes the server to not be in a blackout state
                if isServer() then getWorld():setHydroPowerOn(true) end
                BlackoutsServerFunctions.directClients("TomaroBlackouts", "restorePower", { serverModData = modData })
                modData.cooldown = SandboxVars.Blackouts.Cooldown + 1

            end
        end
    end
end

--** directClients is essential for this mod working in multiplayer. thanks to Burryaga!
BlackoutsServerFunctions.directClients = function(module, command, packet, player)

    if not isClient() and not isServer() then
        triggerEvent("OnServerCommand", module, command, packet)
    else
        if player then
            sendServerCommand(player, module, command, packet)
        else
            sendServerCommand(module, command, packet)
        end
    end

end

--** stuff to handle client commands
BlackoutsServerFunctions.processClientCommand = function(module, command, player, packet)
    if not (module == "TomaroBlackouts" and BlackoutsServerFunctions[command]) then return end
    BlackoutsServerFunctions[command](packet, player)
end

--** handles syncing players who join a server during a blackout
BlackoutsServerFunctions.requestPowerState = function(packet, player)
    local modData = BlackoutsServerFunctions.initializeModData()
    
    if modData.eventplaying then
        getWorld():setHydroPowerOn(false)
        BlackoutsServerFunctions.directClients("TomaroBlackouts", "disablePower", {serverModData = modData}, player)
    elseif BlackoutsServerFunctions.shutoffTimeDelayedByOverride() then
        getWorld():setHydroPowerOn(true)
        BlackoutsServerFunctions.directClients("TomaroBlackouts", "enablePower", {serverModData = modData}, player)
    else
        BlackoutsServerFunctions.directClients("TomaroBlackouts", "informNewConnection", {serverModData = modData}, player)
    end
end

Events.OnClientCommand.Add(BlackoutsServerFunctions.processClientCommand)
Events.OnInitGlobalModData.Add(BlackoutsServerFunctions.initializeModData)
Events.EveryHours.Add(BlackoutsServerFunctions.shutoffPower)
Events.EveryTenMinutes.Add(BlackoutsServerFunctions.restorePower)

return BlackoutsServerFunctions
