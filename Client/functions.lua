function getSpawnLocation(coord)
    local radius = 75.0
    local safeCoord, outPosition
    local finished = false
    local index = 0

    while finished == false and index <= 1000 do
        posX = coord.x + math.random(-radius, radius)
        posY = coord.y + math.random(-radius, radius)
        Z = coord.z + 999.0
        heading = math.random(0, 359) + .0
        ground, posZ = GetGroundZFor_3dCoord(posX + .0, posY + .0, Z, true)

        safeCoord, outPosition = GetSafeCoordForPed(posX, posY, posZ, false, 16)
        finished = safeCoord
        index = index + 1
    end
    return vector4(posX, posY, posZ, heading)
end

function testSpwan(PlayerCoord, Goal)
    -- Generates Random Coordinates somewhere on the island
    local Coord = getSpawnLocation(PlayerCoord)

    -- Gets the closest road for vehicles to spawn on
    local found, outPos, Heading = GetClosestVehicleNodeWithHeading(Coord.x, Coord.y, Coord.z, 1.0, 1, false)

    local pedRef, vehicleRef = SpawnVehicleWithPedInside({'g_m_y_mexgoon_01', 'g_m_y_mexgoon_03', 'g_f_y_vagos_01',
                                                          'g_f_importexport_01'}, 'Moonbeam', outPos, Heading)
    DriveToGoal(pedRef[1], vehicleRef, PlayerCoord, 'Moonbeam')
    giveWeaponToCrew(pedRef, 'weapon_smg')
    CrewAttackTargetedPed(pedRef, PlayerPedId())
end

--- spwan one vehicle with given models for peds
---@param pedmodels models table
---@param vehiclemodel model
---@param spwanCoord number
---@param heading number
---@return pedsRef , vehicleRef
function SpawnVehicleWithPedInside(pedmodels, vehiclemodel, spwanCoord, heading)
    -- Load the models to spawn
    local vehiclemodel = GetHashKey(vehiclemodel)
    local pedsRef = {}

    -- while loops to ensure the models are actually loaded
    WaitUntilModelLoaded(vehiclemodel)
    -- Create vehicle + ped
    local pedveh = CreateVehicle(vehiclemodel, spwanCoord.x, spwanCoord.y, spwanCoord.z, heading, true, false)
    for key, pedModel in pairs(pedmodels) do
        local tempPedHash = GetHashKey(pedModel)
        WaitUntilModelLoaded(tempPedHash)
        local temp_ped = CreatePedInsideVehicle(pedveh, 2, tempPedHash, (key - 2), true, true)
        SetBlockingOfNonTemporaryEvents(temp_ped, true)
        table.insert(pedsRef, temp_ped)
    end

    SetVehicleFixed(pedveh)
    SetVehicleOnGroundProperly(pedveh)
    return pedsRef, pedveh
end

--- if ped is in vehicle they gonna move toward given goal
---@param ped ped
---@param pedVeh ped
---@param goal coord
---@param VehModel hash
function DriveToGoal(ped, pedVeh, goal, VehModel)
    -- Let the car move
    TaskVehicleDriveToCoord(ped, pedVeh, goal.x, goal.y, goal.z, 50.0, 0, VehModel, 1074528293, 5.0, true)
end

--- AttackTargetedPed() but for table of peds
---@param attackersList table
---@param targetPed ped
function CrewAttackTargetedPed(attackersList, targetPed)
    for key, ped in pairs(attackersList) do
        AttackTargetedPed(ped, targetPed)
        SetRelationshipBetweenPed(ped)
    end
end

--- gives ped ability to follow and attack targeted ped
---@param AttackerPed any
---@param targetPed any
---@return void
function AttackTargetedPed(AttackerPed, targetPed)
    SetPedCombatAttributes(AttackerPed --[[ Ped ]] , 46 --[[ integer ]] , 1 --[[ boolean ]] )
    TaskGoToEntityWhileAimingAtEntity(AttackerPed --[[ Ped ]] , targetPed --[[ Entity ]] , targetPed --[[ Entity ]] , 1 --[[ number ]] ,
        1 --[[ boolean ]] , 0 --[[ number ]] , 15 --[[ number ]] , 1 --[[ boolean ]] , 1 --[[ boolean ]] , 1566631136 --[[ Hash ]] )
    TaskCombatPed(AttackerPed --[[ Ped ]] , targetPed --[[ Ped ]] , 0 --[[ integer ]] , 16 --[[ integer ]] )
end

--- set relationship with ped againt player. and disable Friendly fire when fighting againt player.
---@param ped any
function SetRelationshipBetweenPed(ped)
    -- note: if we don't do this they will fight between themselfs!
    RemovePedFromGroup(ped)
    SetPedRelationshipGroupHash(ped, GetHashKey('HATES_PLAYER'))
    SetCanAttackFriendly(ped, false, false)
end

--- give one type of weapon to group of peds 
---@param list table
---@param weaponName string
function giveWeaponToCrew(list, weaponName)
    for key, ped in pairs(list) do
        giveWeaponToPed(ped, weaponName)
    end
end

--- five weapon to ped
---@param ped any
---@param weaponName string
---@return void
function giveWeaponToPed(ped, weaponName)
    GiveWeaponToPed(ped, GetHashKey(weaponName), 1, false, false)
end

--- wait for model to load
---@param model model
function WaitUntilModelLoaded(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(1)
    end
end

function ActivateWarpInTouch()
    -- fun warping :)
    Citizen.CreateThread(function()
        local PlayerId = PlayerId()
        local PlayerPedId = PlayerPedId()
        local PlayerCoord
        local Warped = false
        local since
        while true do
            Wait(500)
            since = GetTimeSincePlayerHitVehicle(PlayerId)
            if since <= 200 then
                PlayerCoord = GetEntityCoords(PlayerPedId)
                local vehicle = GetClosestVehicle(PlayerCoord.x, PlayerCoord.y, PlayerCoord.z, 4.0, 0, 70)
                if Warped == false then
                    Warped = true
                    TaskWarpPedIntoVehicle(PlayerPedId --[[ Ped ]] , vehicle --[[ Vehicle ]] , -1 --[[ integer ]] )
                    Wait(500)
                    -- local temp_ped = CreatePedInsideVehicle(vehicle, 2, GetHashKey('g_m_y_mexgoon_03'), 0, true, true)
                    -- giveWeaponToPed(temp_ped, 'weapon_smg')
                    -- AttackTargetedPed(temp_ped, PlayerId)
                end
            end
            Warped = false
        end
    end)
end
