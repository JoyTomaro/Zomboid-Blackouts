----------------------------------------------------------------------------
--Blackouts Mod | --**Thanks to the Project Zomboid Discord server for help!**
----------------------------------------------------------------------------
if isClient() then return end
local BlackoutsServerFunctions = {}

--** global mod data that handles essential information for this mod
BlackoutsServerFunctions.initializeModData = function(isNewGame)
    local modData = ModData.getOrCreate("tmrblackouts")
    
    modData.cooldown = modData.cooldown or SandboxVars.Blackouts.InitialCooldown
    modData.recoverytime = modData.recoverytime or SandboxVars.Blackouts.Duration * 6
    modData.eventplaying = modData.eventplaying or false

end

--** overrides power shutoff date
BlackoutsServerFunctions.overrideShutoffDate = function()
    local modData = ModData.getOrCreate("tmrblackouts")

    if SandboxVars.Blackouts.Override > 0 then
        SandboxVars.ElecShutModifier = SandboxVars.Blackouts.Override
    end

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
                BlackoutsServerFunctions.directClients("TomaroBlackouts", "shutoffPower", {})
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
                BlackoutsServerFunctions.directClients("TomaroBlackouts", "restorePower", {})
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
    local modData = ModData.getOrCreate("tmrblackouts")
    local activeEvent = modData and modData.eventplaying
    
    if activeEvent then
        BlackoutsServerFunctions.directClients("TomaroBlackouts", "disablePower", {}, player)
        if isServer() then getWorld():setHydroPowerOn(false) end
    end

end

Events.OnClientCommand.Add(BlackoutsServerFunctions.processClientCommand)
Events.OnInitGlobalModData.Add(BlackoutsServerFunctions.initializeModData)
Events.OnSave.Add(BlackoutsServerFunctions.overrideShutoffDate)
Events.OnLoad.Add(BlackoutsServerFunctions.overrideShutoffDate)
Events.EveryHours.Add(BlackoutsServerFunctions.shutoffPower)
Events.EveryTenMinutes.Add(BlackoutsServerFunctions.restorePower)
return BlackoutsServerFunctions
