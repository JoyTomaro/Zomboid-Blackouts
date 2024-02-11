--------------------------------------
--Blackout Traits
--------------------------------------
local BlackoutPlayer = {}

BlackoutPlayer.flashlightTrait = function()
    TraitFactory.addTrait("HandTorch", getText("UI_trait_HandTorch"), 1, getText("UI_trait_HandTorchdesc"), false)
end

BlackoutPlayer.flashlightStuff = function(player, square)
    if player:HasTrait("HandTorch") then
        player:getInventory():AddItem("Base.HandTorch")
    end
end

--------------------------------------
--Events
--------------------------------------
Events.OnGameBoot.Add(BlackoutPlayer.flashlightTrait)
Events.OnNewGame.Add(BlackoutPlayer.flashlightStuff)
return BlackoutPlayer