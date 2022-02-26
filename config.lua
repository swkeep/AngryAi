Config = Config or {}

Config.DEBUG = true -- make sure it's false

-- ============================
--       Server Config
-- ============================

-- g_f_y_vagos_01

-- ============================
--       Client Config
-- ============================
Config.TimeInterval = 1000

Config.TriggerAttackOnCarAccident = 100 -- 50% chance to trigger
Config.DefualtAssignedCooldown = 1000 -- 50% chance to trigger

Config.DefualtExpectedEventDuration = 10000 -- after this duration script will give up on NPCs.
Config.DefualtExpectedPursueDistance = 75 -- distance until NPCs gaveup on pursue

Config.Events = {
    {
        name = 'Ambush',
        timings = {
            ActiveDuration = 10000, -- set free enntites after target left for this duration
            CooldownDruration = 2000, -- cooldown after triggered once
            ChanceToTrigger = 50, -- 50% after every cooldown
            maximumActiveSessionsForOnePlayer = 0 -- #TODO this should controlled by server
        },
        isTargetDead = function()
            local playerPed = PlayerPedId()
            return isTargetedPedDead(playerPed)
        end,
        Function = function()
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)

            local pedsList = {
                'g_m_y_mexgoon_01', 'g_m_y_mexgoon_03', 'g_f_y_vagos_01',
                'g_f_importexport_01'
            }
            local VehicleName = 'Moonbeam'

            local Coord = getSpawnLocation(coords)

            -- Gets the closest road for vehicles to spawn on
            local found, outPos, Heading =
                GetClosestVehicleNodeWithHeading(Coord.x, Coord.y, Coord.z, 1.0,
                                                 1, false)

            if found then
                local entities, vehicleRef
                entities, vehicleRef = SpawnVehicleWithPedInside(pedsList,
                                                                 VehicleName,
                                                                 outPos, Heading)
                -- pedRef[1] is first npc in car 
                DriveToGoal(entities[1], vehicleRef, coords, 'Moonbeam')
                -- giveWeaponToCrew(entities, 'weapon_smg')
                -- CrewAttackTargetedPed(entities, playerPed)
                -- # TODO qbtarget sup for vehicles ????????
                -- assignQbTargetToEntity(vehicleRef)
                return entities, vehicleRef, playerPed
            end
        end
    }, {
        name = 'SeekPlayer',
        timings = {
            ActiveDuration = 20000, -- event and npcs are active until this value reach zero 
            CooldownDruration = 5000, -- cooldown after triggered once
            ChanceToTrigger = 100, -- 50% after every cooldown
            maximumActiveSessionsForOnePlayer = 1 -- this should controlled by server
        },
        isTargetDead = function()
            local playerPed = PlayerPedId()
            return isTargetedPedDead(playerPed)
        end,
        customDistance = function(distance, ped, info)
            print(distance, ped)
        end,
        Function = function()
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local forward = GetEntityForwardVector(playerPed)
            -- local x, y, z = table.unpack(coords + forward * 2.0)
            local x, y, z = table.unpack(getSpawnLocation(coords))

            local pedHash = GetHashKey('S_M_M_HighSec_05')

            WaitUntilModelLoaded(pedHash)
            local ped = CreatePed(2, pedHash, x, y, z, 0, true, false)
            followTargetedPlayer(ped, playerPed, 3.0, 5.0)

            -- TaskLookAtEntity(ped, playerPed, 60.0, 2048, 3)

            assignQbTargetToEntity(ped)
            return {ped}, nil, playerPed
        end
    }, {
        name = 'SeekPlayer2',
        timings = {
            ActiveDuration = 5000, -- set free enntites after target left for this duration
            CooldownDruration = 2000, -- cooldown after triggered once
            ChanceToTrigger = 100, -- 50% after every cooldown
            maximumActiveSessionsForOnePlayer = 0 -- this should controlled by server
        },
        isTargetDead = function()
            local playerPed = PlayerPedId()
            return isTargetedPedDead(playerPed)
        end,
        Function = function()
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local forward = GetEntityForwardVector(playerPed)
            -- local x, y, z = table.unpack(coords + forward * 2.0)
            local x, y, z = table.unpack(getSpawnLocation(coords))

            local pedHash = GetHashKey('S_M_M_HighSec_05')

            WaitUntilModelLoaded(pedHash)
            local ped = CreatePed(2, pedHash, x, y, z, 0, true, false)
            followTargetedPlayer(ped, playerPed, 3.0, 5.0)

            -- TaskLookAtEntity(ped, playerPed, 60.0, 2048, 3)

            assignQbTargetToEntity(ped)
            return ped, nil, playerPed
        end
    }
}

--- func desc
---@param ped any
---@param target any
function chatWithTarget(ped, target)
    TaskChatToPed(ped, target, 17, 0.0, 0.0, 0.0, 0.0, 0.0)
end

function assignQbTargetToEntity(Entity)
    exports['qb-target']:AddTargetEntity(Entity, {
        options = {
            {
                type = "client",
                event = "postop:getPackage",
                icon = "fas fa-box-circle-check",
                label = "Get Package",
                action = function(entity)
                    if IsPedAPlayer(entity) then return false end
                    -- PlayPedAmbientSpeechNative(entity , 'GENERIC_HI'  , 'SPEECH_PARAMS_FORCE'  )
                    PlayPedAmbientSpeechNative(entity, 'GENERIC_THANKS',
                                               'SPEECH_PARAMS_FORCE')
                    TriggerServerEvent('AngryAi:server:sellPackage')
                    RelaseThisEntityNow(entity)
                end,
                canInteract = function(entity, distance, data)
                    if IsPedAPlayer(entity) then return false end
                    return true
                end
            }
        },
        distance = 3.0
    })
end
-- ============================
--       FIRING_PATTERN_BURST
-- ============================

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
