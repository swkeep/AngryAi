local CoreName = exports['qb-core']:GetCoreObject()

-- RegisterServerEvent('keep-hunting:server:removeBaitFromPlayerInventory')
-- AddEventHandler('keep-hunting:server:removeBaitFromPlayerInventory', function()
--     local Player = CoreName.Functions.GetPlayer(source)
--     Player.Functions.RemoveItem("huntingbait", 1)
-- end)

CoreName.Commands.Add("spawnEvent", "Spawn Animals (Admin Only)",
    {{"model", "Animal Model"}, {"was_llegal", "area of hunt true/false"}}, false, function(source, args)
        TriggerClientEvent('keep-AngryAi:client:spawn', source, args[1])
    end, 'admin')

function tprint(tbl, indent)
    if not indent then
        indent = 0
    end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent + 1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(garbageCollection_tm)
--         garbageCollection()
--     end
-- end)
