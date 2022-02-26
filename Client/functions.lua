function getSpawnLocation(coord)
    local maxRadius = 75.0
    local minRadius = 50.0
    local safeCoord, outPosition
    local finished = false
    local index = 0

    while finished == false and index <= 1000 do
        posX = coord.x + math.random(math.random(-maxRadius, -minRadius),
                                     math.random(minRadius, maxRadius))
        posY = coord.y + math.random(math.random(-maxRadius, -minRadius),
                                     math.random(minRadius, maxRadius))
        Z = coord.z + 999.0
        heading = math.random(0, 359) + .0
        ground, posZ = GetGroundZFor_3dCoord(posX + .0, posY + .0, Z, true)

        safeCoord, outPosition = GetSafeCoordForPed(posX, posY, posZ, false, 16)
        finished = safeCoord
        index = index + 1
    end
    return vector4(posX, posY, posZ, heading)
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
    local pedveh = CreateVehicle(vehiclemodel, spwanCoord.x, spwanCoord.y,
                                 spwanCoord.z, heading, true, false)

    for key, pedModel in pairs(pedmodels) do
        local tempPedHash = GetHashKey(pedModel)
        WaitUntilModelLoaded(tempPedHash)
        local temp_ped = CreatePedInsideVehicle(pedveh, 2, tempPedHash,
                                                (key - 2), true, true)
        SetBlockingOfNonTemporaryEvents(temp_ped, true)
        table.insert(pedsRef, temp_ped)
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
    TaskVehicleDriveToCoord(ped, pedVehicle, goal.x, goal.y, goal.z, 50.0, 0,
                            vehHash, 1074528293, 5.0, true)
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
    if not AttackerPed and not targetPed then return end
    SetPedCombatAttributes(AttackerPed, 46, 1)
    TaskGoToEntityWhileAimingAtEntity(AttackerPed, targetPed, targetPed, 1, 1,
                                      0, 15, 1, 1, 1566631136)
    TaskCombatPed(AttackerPed, targetPed, 0, 16)
end

--- remove Relationship againt player.
---@param ped any
function removeRelationship(ped)
    if not ped then return end
    RemovePedFromGroup(ped)
end

--- set relationship with ped againt player. and disable Friendly fire when fighting againt player.
---@param ped any
function SetRelationshipBetweenPed(ped)
    if not ped then return end
    -- note: if we don't do this they will fight between themselfs!
    RemovePedFromGroup(ped)
    SetPedRelationshipGroupHash(ped, GetHashKey('HATES_PLAYER'))
    SetCanAttackFriendly(ped, false, false)
end

--- give one type of weapon to group of peds 
---@param list table
---@param weaponName string
function giveWeaponToCrew(list, weaponName)
    for key, ped in pairs(list) do giveWeaponToPed(ped, weaponName) end
end

--- five weapon to ped
---@param ped any
---@param weaponName string
---@return void
function giveWeaponToPed(ped, weaponName)
    if not ped and not weaponName then return end
    GiveWeaponToPed(ped, GetHashKey(weaponName), 1, false, false)
end

--- wait for model to load
---@param model model
function WaitUntilModelLoaded(model)
    if not model then return end
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(1) end
end

--- it will return 1 or 2 , 1 is what we should aim for
---@param chance number
function ChanceToTrigger(chance)
    -- here we Complete the rest Chances to reach 100% in total in every try and then make EarnedLoot table
    if not chance then return end
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
                local vehicle = GetClosestVehicle(PlayerCoord.x, PlayerCoord.y,
                                                  PlayerCoord.z, 4.0, 0, 70)
                if Warped == false then
                    Warped = true
                    TaskWarpPedIntoVehicle(PlayerPedId, vehicle, -1)
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

function print_table(node)
    local cache, stack, output = {}, {}, {}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k, v in pairs(node) do size = size + 1 end

        local cur_index = 1
        for k, v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str, "}", output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str, "\n", output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output, output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "[" .. tostring(k) .. "]"
                else
                    key = "['" .. tostring(k) .. "']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t', depth) .. key ..
                                     " = " .. tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t', depth) .. key ..
                                     " = {\n"
                    table.insert(stack, node)
                    table.insert(stack, v)
                    cache[node] = cur_index + 1
                    break
                else
                    output_str = output_str .. string.rep('\t', depth) .. key ..
                                     " = '" .. tostring(v) .. "'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" ..
                                     string.rep('\t', depth - 1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" ..
                                     string.rep('\t', depth - 1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t', depth - 1) ..
                             "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output, output_str)
    output_str = table.concat(output)

    print(output_str)
end

function TableAppend(t1, t2)
    -- A numeric for loop is faster than pairs, but it only gets the sequential part of t2
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i] -- this is slightly faster than table.insert
    end

    -- This loop gets the non-sequential part (e.g. ['a'] = 1), if it exists
    local k, v = next(t2, #t2 ~= 0 and #t2 or nil)
    while k do
        t1[k] = v -- if index k already exists in t1 then it will be overwritten
        k, v = next(t2, k)
    end
end
