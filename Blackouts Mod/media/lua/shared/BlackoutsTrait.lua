--------------------------------------
--Blackouts Mod Traits
--------------------------------------
local BlackoutsPlayer = {}

BlackoutsPlayer.flashlightTrait = function()
    TraitFactory.addTrait("HandTorch", getText("UI_trait_HandTorch"), 1, getText("UI_trait_HandTorchdesc"), false)
end

BlackoutsPlayer.flashlightStuff = function(player, square)
    if player:HasTrait("HandTorch") then
        player:getInventory():AddItem("Base.HandTorch")
    end
end

--------------------------------------
--Events
--------------------------------------
Events.OnGameBoot.Add(BlackoutsPlayer.flashlightTrait)
Events.OnNewGame.Add(BlackoutsPlayer.flashlightStuff)

return BlackoutsPlayer
