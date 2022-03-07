START = true

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

        if (sinceHitVehicle <= 250 and sinceHitVehicle ~= -1) then
            local chance = ChanceToTrigger(Config.TriggerAttackOnCarAccident)
            PlayerCoord = GetEntityCoords(PlayerPedId)
            local vehicle = GetClosestVehicle(PlayerCoord.x, PlayerCoord.y,
                                              PlayerCoord.z, 5.0, 0, 70)
            VehicleCoord = GetEntityCoords(vehicle)

            if NPC_ControlledRecently == false and chance == 1 then
                local temp_ped
                local pedRef = {}

                for i = -1, 5, 1 do
                    temp_ped = GetPedInVehicleSeat(vehicle, i)
                    TaskLeaveVehicle(temp_ped, vehicle, 256)
                    SetPedRelationshipGroupHash(temp_ped, groupHash)
                    SetEntityMaxHealth(temp_ped, 250)
                    SetEntityHealth(temp_ped, 250)
                    SetCanAttackFriendly(temp_ped, false, false)

                    Wait(750)
                    giveWeaponToPed(temp_ped, 'weapon_pistol')
                    SetEntityAsMissionEntity(temp_ped, 0, 0)

                    -- TaskPutPedDirectlyIntoMelee(temp_ped --[[ Ped ]] , PlayerPedId --[[ Ped ]] , 0 --[[ number ]] , 0 --[[ number ]] ,
                    --     0 --[[ number ]] , 0 --[[ boolean ]] )
                    SetPedCombatAbility(temp_ped, 0)
                    TaskCombatPed(temp_ped, PlayerPedId, 0, 16)
                    SetEntityAsNoLongerNeeded(temp_ped) -- remove entity when it's fit
                end
                NPC_ControlledRecently = true
                Wait(500)
            end
        end

        NPC_ControlledRecently = false
    end
end)

RegisterNetEvent('keep-AngryAi:client:spawn')
AddEventHandler('keep-AngryAi:client:spawn', function(model, duration)
    model = (tonumber(model) ~= nil and tonumber(model) or GetHashKey(model))
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local x, y, z = table.unpack(coords + forward * 2.0)

    local pedsList = {
        'g_m_y_mexgoon_01', 'g_m_y_mexgoon_03', 'g_f_y_vagos_01',
        'g_f_importexport_01'
    }
    local VehicleName = 'Moonbeam'
    AmbushEvent(coords, duration, pedsList, VehicleName)

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

RegisterNetEvent('keep-AngryAi:client:Start')
AddEventHandler('keep-AngryAi:client:Start', function()
    START = true
    -- call after player spawned
end)

function followTargetedPlayer(follower, targetPlayer, distanceToStopAt,
                              StartAimingDist)
    TaskGotoEntityAiming(follower, targetPlayer, distanceToStopAt,
                         StartAimingDist)
end
