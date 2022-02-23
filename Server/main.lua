local CoreName = exports['qb-core']:GetCoreObject()

-- RegisterServerEvent('keep-hunting:server:removeBaitFromPlayerInventory')
-- AddEventHandler('keep-hunting:server:removeBaitFromPlayerInventory', function()
--     local Player = CoreName.Functions.GetPlayer(source)
--     Player.Functions.RemoveItem("huntingbait", 1)
-- end)

CoreName.Commands.Add("spawnEvent", "Spawn Animals (Admin Only)",
    {{"model", "Animal Model"}, {"was_llegal", "area of hunt true/false"}}, false, function(source, args)
        TriggerClientEvent('keep-AngryAi:client:spawn', source, args[1] , args[2])
    end, 'admin')

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(garbageCollection_tm)
--         garbageCollection()
--     end
-- end)
