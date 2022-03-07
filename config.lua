Config = Config or {}

Config.DEBUG = true -- make sure it's false

-- ============================
--       Server Config
-- ============================

-- ============================
--       Client Config
-- ============================
Config.TimeInterval = 1000

Config.Events = {{
    name = 'Ambush',
    timings = {
        activeEventDuration = 50000, -- peds are gonna get removed from script controll 
        spawnCooldown = 5000,
        chanceToTrigger = 100,
        maxSessions = 0
    },
    isTargetDead = function()
        local playerPed = PlayerPedId()
        return isTargetedPedDead(playerPed)
    end,
    eventBehavior = function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local pedsList = {'g_m_y_mexgoon_01', 'g_f_y_vagos_01'}
        local VehicleName = 'Moonbeam'
        local Coord = getSpawnLocation(coords)
        -- Gets the closest road for vehicles to spawn on
        local found, outPos, Heading = GetClosestVehicleNodeWithHeading(Coord.x, Coord.y, Coord.z, 1.0, 1, false)
        if found then
            local entities, vehicleRef
            entities, vehicleRef = SpawnVehicleWithPedInside(pedsList, VehicleName, outPos, Heading)
            -- pedRef[1] is first npc in car 
            DriveToGoal(entities[1], vehicleRef, coords, 'Moonbeam')
            giveWeaponToCrew(entities, 'weapon_smg')
            CrewAttackTargetedPed(entities, playerPed)

            return entities, vehicleRef, playerPed
        end
    end
}, {
    name = 'SeekPlayer',
    timings = {
        activeEventDuration = 60000,
        spawnCooldown = 2000,
        chanceToTrigger = 50,
        maxSessions = 0
    },
    isTargetDead = function()
        local playerPed = PlayerPedId()
        return isTargetedPedDead(playerPed)
    end,
    customDistance = function(distance, ped, evnet)
        if distance <= 5 then
            WalkTowardTarget(ped, GetPlayerPed(-1))
            PlayPedAmbientSpeechNative(ped, 'GENERIC_HI', 'Speech_Params_Allow_Repeat')
        end
    end,
    eventBehavior = function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local x, y, z = table.unpack(getSpawnLocation(coords))

        local pedHash = GetHashKey('S_M_M_HighSec_05')

        WaitUntilModelLoaded(pedHash)
        local ped = CreatePed(2, pedHash, x, y, z, 0, true, false)
        SetPedAudioGender(ped, true)
        GivePedRandomVoice(ped, 'MALE', 'LATINO') -- set voice for ped!
        followTargetedPlayer(ped, playerPed, 3.0, 5.0)

        InitQbTargetForEntity(ped)
        return ped, nil, playerPed
    end
}, {
    name = 'SeekPlayer2',
    timings = {
        activeEventDuration = 50000,
        spawnCooldown = 2000,
        chanceToTrigger = 50,
        maxSessions = 0
    },
    isTargetDead = function()
        local playerPed = PlayerPedId()
        return isTargetedPedDead(playerPed)
    end,
    eventBehavior = function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local x, y, z = table.unpack(getSpawnLocation(coords))

        local pedHash = GetHashKey('S_M_M_HighSec_05')

        WaitUntilModelLoaded(pedHash)
        local ped = CreatePed(2, pedHash, x, y, z, 0, true, false)
        followTargetedPlayer(ped, playerPed, 3.0, 5.0)
        InitQbTargetForEntity(ped)
        return ped, nil, playerPed
    end
}, {
    name = 'Heli',
    timings = {
        activeEventDuration = 60000,
        spawnCooldown = 2000,
        chanceToTrigger = 50,
        maxSessions = 0
    },
    isTargetDead = function()
        local playerPed = PlayerPedId()
        return isTargetedPedDead(playerPed)
    end,
    customDistance = function(distance, ped, evnet)
        if distance <= 5 then
            WalkTowardTarget(ped, GetPlayerPed(-1))
            PlayPedAmbientSpeechNative(ped, 'GENERIC_HI', 'Speech_Params_Allow_Repeat')
        end
    end,
    eventBehavior = function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local x, y, z = table.unpack(getSpawnLocation(coords))

        local pedHash = GetHashKey('S_M_M_HighSec_05')
        WaitUntilModelLoaded(pedHash)
        local vehiclemodel = GetHashKey('Frogger')
        -- while loops to ensure the models are actually loaded
        WaitUntilModelLoaded(vehiclemodel)
        -- Create vehicle + ped
        local pedveh = CreateVehicle(vehiclemodel, x, y, z + 80.0, 0, true, false)
        local ped = CreatePedInsideVehicle(pedveh, 2, pedHash, -1, true, true)

        TaskHeliChase(ped, playerPed, 0.0, 0.0, 15.0)

        -- InitQbTargetForEntity(ped)
        return ped, pedveh, playerPed
    end
}, {
    name = 'PolyzoneSpawn',
    timings = {
        activeEventDuration = 60000,
        spawnCooldown = 1000,
        chanceToTrigger = 100,
        maxSessions = 2
    },
    customDistance = function(distance, ped, event)
        if distance <= 5 then
            WalkTowardTarget(ped, GetPlayerPed(-1))
            PlayPedAmbientSpeechNative(ped, 'GENERIC_HI', 'Speech_Params_Allow_Repeat')
        end
    end,
    Zone = function()
        -- eventBehavior will only excuted when player is inside provided area
        local coord = vector4(-71.04, 6266.42, 31.12, 212.35)
        local x, y, z, w = table.unpack(coord)
        local BOX_A = BoxZone:Create(coord, 2.0, 6.5, {
            name = 'BOX_A',
            useZ = true,
            heading = w,
            maxZ = z + 1.5,
            minZ = z - 1.5,
            debugPoly = true
        })

        -- this part is just visualation of eventBehavior to see where npcs are coming form!
        local staticPosition = {vector3(-71.13, 6243.63, 31.07), vector3(-83.12, 6240.64, 31.09),
                                vector3(-73.59, 6224.65, 31.09), vector3(-84.18, 6218.9, 31.09)}
        for key, value in pairs(staticPosition) do
            local x, y, z = table.unpack(value)
            BoxZone:Create(value, 1.0, 1.0, {
                name = 'test' .. key,
                useZ = true,
                maxZ = z + 1.5,
                minZ = z - 1.5,
                debugPoly = true
            })
        end
        ----------------------------------------------------------------------------------------------------

        return BOX_A
    end,
    eventBehavior = function()
        local playerPed = PlayerPedId()
        -- spawn locations
        local staticPosition = {vector3(-71.13, 6243.63, 31.07), vector3(-83.12, 6240.64, 31.09),
                                vector3(-73.59, 6224.65, 31.09), vector3(-84.18, 6218.9, 31.09)}
        -- choice one of spawn locations
        local chnaced = Alias_table_wrapper({25, 25, 25, 25})
        local x, y, z = table.unpack(staticPosition[chnaced])

        local pedHash = GetHashKey('S_M_M_HighSec_05')

        WaitUntilModelLoaded(pedHash)
        local ped = CreatePed(2, pedHash, x, y, z, 0, true, false)
        GivePedRandomVoice(ped, 'MALE', 'LATINO') -- set voice for ped!
        giveWeaponToPed(ped, 'weapon_smg')
        AttackTargetedPed(ped, playerPed)
        return ped, nil, playerPed
    end
}}

function InitQbTargetForEntity(Entity)
    exports['qb-target']:AddTargetEntity(Entity, {
        options = {{
            type = "client",
            event = "postop:getPackage",
            icon = "fas fa-box-circle-check",
            label = "Get Package",
            action = function(entity)
                if IsPedAPlayer(entity) then
                    return false
                end
                PlayPedAmbientSpeechNative(entity, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE')
                TriggerServerEvent('AngryAi:server:sellPackage')
                RelaseThisEntityNow(entity)
            end,
            canInteract = function(entity, distance, data)
                if IsPedAPlayer(entity) or IsEntityDead(entity) == 1 then
                    return false
                end
                return true
            end
        }},
        distance = 3.0
    })
end
