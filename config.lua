Config = Config or {}

Config.DEBUG = true -- make sure it's false

-- ============================
--       Server Config
-- ============================

-- g_f_y_vagos_01

-- ============================
--       Client Config
-- ============================
Config.TriggerAttackOnCarAccident = 100 -- 50% chance to trigger
Config.DefualtAssignedCooldown = 1000 -- 50% chance to trigger

Config.Events = {{
    name = 'Ambush',
    targetPedID = GetPlayerPed(-1),
    timings = {
        ActiveDuration = 5000, -- set free enntites after target left for this duration
        CooldownDruration = 30000, -- cooldown after triggered once
        ChanceToTrigger = 50, -- 50% after every cooldown
        maximumActiveSessionsForOnePlayer = 0, -- this should controlled by server
        ActiveSessions = 0, -- leave as zero -- this should controlled by server
        AssignedCooldown = 0 -- leave as zero
    },
    Function = function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local forward = GetEntityForwardVector(playerPed)
        local x, y, z = table.unpack(coords + forward * 2.0)

        local pedsList = {'g_m_y_mexgoon_01', 'g_m_y_mexgoon_03', 'g_f_y_vagos_01', 'g_f_importexport_01'}
        local VehicleName = 'Moonbeam'
        AmbushEvent(coords, 'short', pedsList, VehicleName)
    end
}}

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
