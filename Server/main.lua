RegisterServerEvent('AngryAi:server:sellPackage')
AddEventHandler('AngryAi:server:sellPackage', function()
    local Player = CoreName.Functions.GetPlayer(source)
    local price = 500
    Player.Functions.AddMoney("cash", price, "sold-items-hunting")
end)
