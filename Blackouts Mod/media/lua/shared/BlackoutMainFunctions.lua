----------------------------------------------------------------------------
--Blackout Mod | --**Thanks to the Project Zomboid Discord server for help!**
----------------------------------------------------------------------------
local BlackoutMainFunctions = {}

--** mod data to be used in other functions
local function blackoutData(isNewGame)
    local modData = ModData.getOrCreate("tmrblackouts")
    
    if not modData.cooldown then
        modData.cooldown = SandboxVars.Blackouts.InitialCooldown
    end
    if not modData.recoverytime then
        modData.recoverytime = 2
    end
    if not modData.eventplaying then
        modData.eventplaying = false
    end
end

--** overrides power shutoff date
local function blackoutOverride()
    local modData = ModData.getOrCreate("tmrblackouts")

    if SandboxVars.Blackouts.Override > 0 then
        SandboxVars.ElecShutModifier = SandboxVars.Blackouts.Override
    end
end

--** blackout event starter
local function blackout()
    local modData = ModData.getOrCreate("tmrblackouts")
    local blackoutchance = SandboxVars.Blackouts.Chance

    if getGameTime():getNightsSurvived() + 1 < SandboxVars.ElecShutModifier and getWorld():isHydroPowerOn() and not modData.eventplaying then
        if modData.cooldown <= 0 then
            if ZombRand(1, 101) <= blackoutchance then
                
                modData.eventplaying = true --?? checks if event is occurring
                triggerEvent("BlackoutsPowerShutoff") --?? see BlackoutEventHandler.lua
            elseif SandboxVars.Blackouts.RampUp and SandboxVars.ElecShutModifier - getGameTime():getNightsSurvived() < 14 and ZombRand(1, 101) <= blackoutchance then

                modData.eventplaying = true --?? checks if event is occurring
                triggerEvent("BlackoutsPowerShutoff") --?? see BlackoutEventHandler.lua
            end
        elseif modData.cooldown >= 1 then
            modData.cooldown = modData.cooldown - 1
        end
    end
end

--** blackout event ender
local function blackoutEnd()
    local modData = ModData.getOrCreate("tmrblackouts")
    local blackoutrecovery = SandboxVars.Blackouts.Recovery
    
    if getGameTime():getNightsSurvived() + 1 < SandboxVars.ElecShutModifier and not getWorld():isHydroPowerOn() and not modData.eventplaying then
        if modData.recoverytime <= 0 then
            if ZombRand(1, 101) < blackoutrecovery then

                modData.eventplaying = true --?? checks if event is occurring
                triggerEvent("BlackoutsPowerStartup") --?? see BlackoutEventHandler.lua
            end
        elseif modData.recoverytime >= 1 then
            modData.recoverytime = modData.recoverytime - 1
        end
    end
end

Events.OnInitGlobalModData.Add(blackoutData)
Events.OnSave.Add(blackoutOverride)
Events.OnLoad.Add(blackoutOverride)
Events.EveryHours.Add(blackout)
Events.EveryTenMinutes.Add(blackoutEnd)
return BlackoutMainFunctions