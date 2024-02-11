----------------------------------------------------------------------------
--Event Handler | --**Thanks to the Project Zomboid Discord server for help!**
----------------------------------------------------------------------------
require "lua_timers"
local BlackoutEventHandler = {}

--** gets nearest building
local function getNearestBuilding()
    local player = getPlayer()
    local vector = Vector2f.new()
    local closest = AmbientStreamManager.getInstance():getNearestBuilding(player:getX(),player:getY(),vector)
    local closestSq = getSquare(closest:getX(), closest:getY(), getPlayer():getZ())

    return closestSq
end

--** external event handler for blackout start
local function initiateBlackout()
    local modData = ModData.getOrCreate("tmrblackouts")
    local playersquare = getPlayer():getSquare()

    timer:Simple(1.0, function() --?? sets timing of blackout sound effect
        if not playersquare:isOutside() then
            getSoundManager():PlayWorldSound("PowerShutoff", getPlayer():getSquare(), 1, 0, 0, false)
        elseif playersquare:isOutside() then
            local square = getNearestBuilding()
            getSoundManager():PlayWorldSound("PowerShutoff", square, 1, 0, 0, false)
        end

        timer:Simple(0.9, function()
            getWorld():setHydroPowerOn(false) --?? turns off the power, more effective than changing shutoffday
            modData.eventplaying = false --?? labels that event is not occurring
            modData.recoverytime = 2
        end)
    end)
end

--** external event handler for blackout end
local function returnPowerStatus()
    local modData = ModData.getOrCreate("tmrblackouts")
    local playersquare = getPlayer():getSquare()

    timer:Simple(1.0, function() --?? sets timing of power startup sound effect
        if not playersquare:isOutside() then
            getSoundManager():PlayWorldSound("PowerStartup", getPlayer():getSquare(), 1, 0, 0, false)
        elseif playersquare:isOutside() then
            local square = getNearestBuilding()
            getSoundManager():PlayWorldSound("PowerStartup", square, 1, 0, 0, false)
        end
        
        timer:Simple(0.8, function()
            getWorld():setHydroPowerOn(true) --?? turns off the power, more effective than changing shutoffday
            modData.eventplaying = false --?? labels that event is not occurring
            modData.cooldown = SandboxVars.Blackouts.Cooldown
        end)
    end)
end

LuaEventManager.AddEvent("BlackoutsPowerStartup")
LuaEventManager.AddEvent("BlackoutsPowerShutoff")
Events.BlackoutsPowerStartup.Add(returnPowerStatus)
Events.BlackoutsPowerShutoff.Add(initiateBlackout)
return BlackoutEventHandler