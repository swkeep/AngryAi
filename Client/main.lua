local CoreName = exports['qb-core']:GetCoreObject()

Citizen.CreateThread(function()
    local PlayerId = PlayerId()
    local PlayerPedId = PlayerPedId()
    local PlayerCoord
    local VehicleCoord
    local NPC_ControlledRecently = false
    local sinceHitVehicle
    local sinceHitPed
    local ssd, groupHash = AddRelationshipGroup("CUS_CIVIL")
    SetRelationshipBetweenGroups(5, groupHash, GetHashKey("PLAYER"))

    while true do
        Wait(500)
        sinceHitVehicle = GetTimeSincePlayerHitVehicle(PlayerId)
        sinceHitPed = GetTimeSincePlayerHitPed(PlayerId)

        if sinceHitVehicle <= 250 and sinceHitVehicle ~= -1 then
            PlayerCoord = GetEntityCoords(PlayerPedId)
            local vehicle = GetClosestVehicle(PlayerCoord.x, PlayerCoord.y, PlayerCoord.z, 5.0, 0, 70)
            VehicleCoord = GetEntityCoords(vehicle)

            if NPC_ControlledRecently == false then
                local temp_ped
                local pedRef = {}

                for i = -1, 5, 1 do
                    temp_ped = GetPedInVehicleSeat(vehicle --[[ Vehicle ]] , i)
                    TaskLeaveVehicle(temp_ped --[[ Ped ]] , vehicle --[[ Vehicle ]] , 256 --[[ integer ]] )
                    SetPedRelationshipGroupHash(temp_ped, groupHash)
                    SetEntityMaxHealth(temp_ped --[[ Entity ]] , 500 --[[ integer ]] )
                    SetEntityHealth(temp_ped --[[ Entity ]] , 500 --[[ integer ]] )

                    Wait(750)
                    giveWeaponToPed(temp_ped, 'weapon_smg')
                    TaskPutPedDirectlyIntoMelee(temp_ped --[[ Ped ]] , PlayerPedId --[[ Ped ]] , 0 --[[ number ]] , 0 --[[ number ]] ,
                        0 --[[ number ]] , 0 --[[ boolean ]] )

                    -- AttackTargetedPed(temp_ped, PlayerPedId)
                end
                NPC_ControlledRecently = true
                Wait(500)
            end
        end

        NPC_ControlledRecently = false
    end
end)
-- AddEventHandler('keep-hunting:client:sellREQ', function()
--     TriggerServerEvent('keep-hunting:server:sellmeat')
-- end)
-- RegisterNetEvent('keep-hunting:client:ForceRemoveAnimalEntity')
-- AddEventHandler('keep-hunting:client:ForceRemoveAnimalEntity', function(entity)
--     DeleteEntity(entity)
-- end)
RegisterNetEvent('keep-AngryAi:client:spawn')
AddEventHandler('keep-AngryAi:client:spawn', function(model)
    model = (tonumber(model) ~= nil and tonumber(model) or GetHashKey(model))
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local x, y, z = table.unpack(coords + forward * 2.0)
    testSpwan(coords, coords)
    -- createCrewWithVehicle(model, "Toros", coords)

    -- SetPedDropsWeaponsWhenDead(s_ped, false)
    -- -- weapon_musket
    -- -- WEAPON_BAT
    -- GiveWeaponToPed(s_ped, GetHashKey("weapon_musket"), 1, false, false)

    -- AttackTargetedPlayer(s_ped, playerPed)
    -- SetPedCombatAbility(s_ped --[[ Ped ]] , 0  -- 0: CA_Poor  
    -- -- 1: CA_Average  
    -- -- 2: CA_Professional  
    -- )
end)

function createCrewWithVehicle(pedModel, vehModel, playerCoord)
    RequestModel(vehModel)
    while not HasModelLoaded(vehModel) do
        Citizen.Wait(1)
    end
    local found, outPos, outHeading = GetClosestVehicleNodeWithHeading(playerCoord.x, playerCoord.y, playerCoord.z, 4,
        3.0, 0)

    -- local veh = CreateVehicle(vehModel, x, y, z, 0, true, false)
    local outPosition = getSpawnLocation(outPos)

    if outPosition.x ~= 0 and outPosition.y ~= 0 and outPosition.z ~= 0 then
        -- Citizen.CreateThread(function()
        --     startSpawningTimer = spawningTime
        --     while startSpawningTimer > 0 do
        --         startSpawningTimer = startSpawningTimer - 1000
        --         Wait(1000)
        --     end
        --     if startSpawningTimer == 0 then
        --         createThreadBaitCooldown()
        --         TriggerServerEvent('keep-hunting:server:choiceWhichAnimalToSpawn', coord, outPosition, was_llegal)
        --     end
        -- end)

        local spawned_car
        if found then
            spawned_car = CreateVehicle(vehModel, outPos.x, outPos.y, outPos.z, outHeading, true, false)
            SetVehicleOnGroundProperly(spawned_car)
            SetModelAsNoLongerNeeded(vehModel)
        end

        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Citizen.Wait(1)
        end

        local s_ped = CreatePedInsideVehicle(spawned_car, 2, pedModel, -1, true, true)
        GiveWeaponToPed(s_ped, GetHashKey("weapon_smg"), 1, false, false)

        TaskVehicleDriveToCoord(s_ped --[[ Ped ]] , spawned_car --[[ Vehicle ]] , playerCoord.x, playerCoord.y,
            playerCoord.z, 50.0, 0 --[[ Any ]] , vehModel, 1074528293, 5.0, true)

    else
        CoreName.Functions.Notify("pls find a better location for you bait!")
    end

    -- Wait(2000)
    -- TaskLeaveVehicle(s_ped, spawned_car, 256);
    -- Wait(1000)
    -- AttackTargetedPlayer(s_ped ,PlayerPedId() )
end

function followTargetedPlayer(Attacker, targetPlayer)
    TaskGotoEntityAiming(Attacker, targetPlayer, 15.0, 5.0)
end

-- FIRING_PATTERN_BURST_FIRE = 0xD6FF6D61 ( 1073727030 )  
-- FIRING_PATTERN_BURST_FIRE_IN_COVER = 0x026321F1 ( 40051185 )  
-- FIRING_PATTERN_BURST_FIRE_DRIVEBY = 0xD31265F2 ( -753768974 )  
-- FIRING_PATTERN_FROM_GROUND = 0x2264E5D6 ( 577037782 )  
-- FIRING_PATTERN_DELAY_FIRE_BY_ONE_SEC = 0x7A845691 ( 2055493265 )  
-- FIRING_PATTERN_FULL_AUTO = 0xC6EE6B4C ( -957453492 )  
-- FIRING_PATTERN_SINGLE_SHOT = 0x5D60E4E0 ( 1566631136 )  
-- FIRING_PATTERN_BURST_FIRE_PISTOL = 0xA018DB8A ( -1608983670 )  
-- FIRING_PATTERN_BURST_FIRE_SMG = 0xD10DADEE ( 1863348768 )  
-- FIRING_PATTERN_BURST_FIRE_RIFLE = 0x9C74B406 ( -1670073338 )  
-- FIRING_PATTERN_BURST_FIRE_MG = 0xB573C5B4 ( -1250703948 )  
-- FIRING_PATTERN_BURST_FIRE_PUMPSHOTGUN = 0x00BAC39B ( 12239771 )  
-- FIRING_PATTERN_BURST_FIRE_HELI = 0x914E786F ( -1857128337 )  
-- FIRING_PATTERN_BURST_FIRE_MICRO = 0x42EF03FD ( 1122960381 )  
-- FIRING_PATTERN_SHORT_BURSTS = 0x1A92D7DF ( 445831135 )  
-- FIRING_PATTERN_SLOW_FIRE_TANK = 0xE2CA3A71 ( -490063247 )  
