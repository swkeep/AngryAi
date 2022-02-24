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

function AmbushEvent(PlayerCoord, duration, pedsList, VehicleName)
    -- Generates Random Coordinates somewhere near player
    local Coord = getSpawnLocation(PlayerCoord)

    -- Gets the closest road for vehicles to spawn on
    local found, outPos, Heading = GetClosestVehicleNodeWithHeading(Coord.x, Coord.y, Coord.z, 1.0, 1, false)

    if found then
        local pedRef, vehicleRef
        if duration == 'short' then
            pedRef, vehicleRef = SpawnVehicleWithPedInside(pedsList, VehicleName, outPos, Heading, 'short')
        elseif duration == 'long' then
            pedRef, vehicleRef = SpawnVehicleWithPedInside(pedsList, VehicleName, outPos, Heading, 'long')
        end
        -- pedRef[1] is first npc in car 
        DriveToGoal(pedRef[1], vehicleRef, PlayerCoord, 'Moonbeam')
        giveWeaponToCrew(pedRef, 'weapon_smg')
        CrewAttackTargetedPed(pedRef, PlayerPedId())
        return pedRef , vehicleRef
    end
end

--- spwan one vehicle with given models for peds
---@param pedmodels models table
---@param vehiclemodel model
---@param spwanCoord number
---@param heading number
---@return pedsRef , vehicleRef
function SpawnVehicleWithPedInside(pedmodels, vehiclemodel, spwanCoord, heading, duration)
    -- Load the models to spawn
    local vehiclemodel = GetHashKey(vehiclemodel)
    local pedsRef = {}

    -- while loops to ensure the models are actually loaded
    WaitUntilModelLoaded(vehiclemodel)
    -- Create vehicle + ped
    local pedveh = CreateVehicle(vehiclemodel, spwanCoord.x, spwanCoord.y, spwanCoord.z, heading, true, false)
    if duration == 'short' then
        SetEntityAsNoLongerNeeded(pedveh)
    end
    for key, pedModel in pairs(pedmodels) do
        local tempPedHash = GetHashKey(pedModel)
        WaitUntilModelLoaded(tempPedHash)
        local temp_ped = CreatePedInsideVehicle(pedveh, 2, tempPedHash, (key - 2), true, true)
        SetBlockingOfNonTemporaryEvents(temp_ped, true)
        table.insert(pedsRef, temp_ped)
        if duration == 'short' then
            SetEntityAsNoLongerNeeded(temp_ped)
        end
    end

    SetVehicleFixed(pedveh)
    SetVehicleOnGroundProperly(pedveh)
    return pedsRef, pedveh
end

--- if ped is in vehicle they gonna move toward given goal
---@param ped ped
---@param pedVehicle ped
---@param goal coord
---@param vehHash hash
function DriveToGoal(ped, pedVehicle, goal, vehHash)
    -- Let the car move
    TaskVehicleDriveToCoord(ped, pedVehicle, goal.x, goal.y, goal.z, 50.0, 0, vehHash, 1074528293, 5.0, true)
end

--- group of peds to seek and attack one ped
---@param attackersListByReference table
---@param targetPed ped
function CrewAttackTargetedPed(attackersListByReference, targetPed)
    for key, ped in pairs(attackersListByReference) do
        AttackTargetedPed(ped, targetPed)
        SetRelationshipBetweenPed(ped)
    end
end

--- gives ped ability to follow and attack targeted ped
---@param AttackerPed any
---@param targetPed any
---@return void
function AttackTargetedPed(AttackerPed, targetPed)
    if not AttackerPed and not targetPed then
        return
    end
    SetPedCombatAttributes(AttackerPed --[[ Ped ]] , 46 --[[ integer ]] , 1 --[[ boolean ]] )
    TaskGoToEntityWhileAimingAtEntity(AttackerPed --[[ Ped ]] , targetPed --[[ Entity ]] , targetPed --[[ Entity ]] , 1 --[[ number ]] ,
        1 --[[ boolean ]] , 0 --[[ number ]] , 15 --[[ number ]] , 1 --[[ boolean ]] , 1 --[[ boolean ]] , 1566631136 --[[ Hash ]] )
    TaskCombatPed(AttackerPed --[[ Ped ]] , targetPed --[[ Ped ]] , 0 --[[ integer ]] , 16 --[[ integer ]] )
end

--- remove Relationship againt player.
---@param ped any
function removeRelationship(ped)
    if not ped then
        return
    end
    RemovePedFromGroup(ped)
end

--- set relationship with ped againt player. and disable Friendly fire when fighting againt player.
---@param ped any
function SetRelationshipBetweenPed(ped)
    if not ped then
        return
    end
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
    if not ped and not weaponName then
        return
    end
    GiveWeaponToPed(ped, GetHashKey(weaponName), 1, false, false)
end

--- wait for model to load
---@param model model
function WaitUntilModelLoaded(model)
    if not model then
        return
    end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(1)
    end
end

--- it will return 1 or 2 , 1 is what we should aim for
---@param chance number
function ChanceToTrigger(chance)
    -- here we Complete the rest Chances to reach 100% in total in every try and then make EarnedLoot table
    if not chance then
        return
    end
    local sample
    local temp = {chance, (100 - chance)}
    sample = Alias_table_wrapper(temp)
    return sample
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
