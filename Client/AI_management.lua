-- global event Ai management
local activeEvents = {}
local activeEntities = {}
--
local loadingIsDone = false
-- events loader
Citizen.CreateThread(function()
    -- loading event inside activeEvents table
    for key, Event in pairs(Config.Events) do
        assignCooldownValue(Event)
        assignActiveSessionsValue(Event)
        table.insert(activeEvents, Event)
    end
    loadingIsDone = true
end)

local NPC_RelaseQueue = {}
-- Entities management system
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        for key, entity in pairs(activeEntities) do
            for ped, info in pairs(entity) do
                -- remove entities from Queue
                if NPC_RelaseQueue ~= nil then
                    for key, NPC_RelaseQueue_PED in pairs(NPC_RelaseQueue) do
                        if ped == NPC_RelaseQueue_PED then
                            ClearPedTasks(NPC_RelaseQueue_PED)
                            FlagEntityAsNoLongerNeeded(NPC_RelaseQueue_PED)
                            updateActiveSessionsValue(info.event, 'decrement')
                            activeEntities[info.eventKey][NPC_RelaseQueue_PED] =
                                nil
                            NPC_RelaseQueue[key] = nil
                            goto continue
                        end
                    end
                end
                -- giveup on target death
                if isTargetedPedDead(info.targetedPed) == true then
                    ClearPedTasks(ped)
                    leaveArea(ped, info)
                    -- SetEntityHealth(ped, 0) --kill ped when it's done
                    updateActiveSessionsValue(info.event, 'decrement')
                    activeEntities[info.eventKey][ped] = nil -- clean table as we no longer need information about peds
                end
                -- keep track of Events duration Event.timings.ActiveDuration

                -- print(info.event.timings.ActiveSessions)
                -- print(info.event.timings.AssignedCooldown)

                -- keep track of events duration distance

                local distance = GetDistanceBetweenTwoEntities(info.targetedPed,
                                                               ped)

                if distance <= 5 then
                    PlayPedAmbientSpeechNative(ped, 'GENERIC_HI',
                                               'Speech_Params_Allow_Repeat')
                elseif distance > 130 then
                    FlagEntityAsNoLongerNeeded(ped)
                    updateActiveSessionsValue(info.event, 'decrement')
                    activeEntities[info.eventKey][ped] = nil
                end

                -- print(ped, IsEntityDead(ped), DoesEntityExist(ped))
                -- keep track of death and entity existence
                if IsEntityDead(ped) == 1 or DoesEntityExist(ped) == false then
                    FlagEntityAsNoLongerNeeded(ped)
                    updateActiveSessionsValue(info.event, 'decrement')
                    activeEntities[info.eventKey][ped] = nil
                end
                ::continue::
            end
        end
        -- print_table(activeEntities)
        -- tprint(NPC_RelaseQueue)
    end
end)

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

function RelaseThisEntityNow(entity) table.insert(NPC_RelaseQueue, entity) end

function leaveArea(ped, info)
    if info.vehicle ~= nil then
        TaskEnterVehicle(ped, info.vehicle.vehicleRef, 10.0,
                         info.vehicle.seatIndex, 2.0, 1, 0)
        if info.vehicle.seatIndex == -1 then
            TaskVehicleDriveWander(ped --[[ Ped ]] , info.vehicle.vehicleRef --[[ Vehicle ]] ,
                                   60.0 --[[ number ]] , 1074528293 --[[ integer ]] )
        end
    end
    FlagEntityAsNoLongerNeeded(ped)
end

Citizen.CreateThread(function()
    -- excute events
    WaitUntilEventsAreLoaded(loadingIsDone)
    while true do
        Wait(1000)
        for key, Event in pairs(activeEvents) do
            -- call event when cooldown is over
            if Event.timings.ActiveSessions >=
                Event.timings.maximumActiveSessionsForOnePlayer then
                goto continue
            end
            if Event['isTargetDead']() == false and
                Event.timings.AssignedCooldown == 0 and
                ChanceToTrigger(Event.timings.ChanceToTrigger) == 1 then
                print('event ' .. Event.name .. ' is triggered')
                local ped, veh, target = Event['Function']()
                FlagAsActiveEntities(ped, veh, target, Event, key)
                Event.timings.AssignedCooldown = Event.timings.CooldownDruration -- reset cooldown after running it once
                updateActiveSessionsValue(Event, 'increment')
            end
            ::continue:: -- pretend i did't use goto :(
            updateCooldownValue(Event)
        end
    end
end)

--- pass entities control to scirpt 
---@param entities any
---@param vehicleRef any
---@param targetedPed any
---@param event any
---@param eventKey any
function FlagAsActiveEntities(entities, vehicleRef, targetedPed, event, eventKey)
    local entityData = {}
    if type(entities) == "table" then
        for key, entity in pairs(entities) do
            entityData[entity] = {
                type = GetEntityType(entity),
                duration = Config.DefualtExpectedEventDuration,
                distance = Config.DefualtExpectedPursueDistance,
                targetedPed = targetedPed,
                event = event,
                eventKey = eventKey
            }
            if vehicleRef ~= nil then
                entityData[entity].vehicle = {
                    vehicleRef = vehicleRef,
                    seatIndex = (key - 2)
                }
            end
        end
        if activeEntities[eventKey] == nil then
            activeEntities[eventKey] = entityData
        else
            TableAppend(activeEntities[eventKey], entityData)
        end
    elseif type(entities) == "number" then
        entityData[entities] = {
            type = GetEntityType(entities),
            duration = Config.DefualtExpectedEventDuration,
            distance = Config.DefualtExpectedPursueDistance,
            targetedPed = targetedPed,
            event = event,
            eventKey = eventKey
        }
        if vehicleRef ~= nil then
            entityData[entities].vehicle = {
                vehicleRef = vehicleRef,
                seatIndex = -1
            }
        end
        if activeEntities[eventKey] == nil then
            activeEntities[eventKey] = entityData
        else
            activeEntities[eventKey][entities] = entityData[entities]
        end
    end
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

--- isExpectedDurationReached
---@param currentDuration number
function isExpectedDurationReached(currentDuration)
    if currentDuration <= 0 then
        return true
    elseif Config.DefualtExpectedEventDuration - currentDuration > 0 then
        return false
    end
end

--- distance between two entities
---@param firstEntity any
---@param secondEntity any
function GetDistanceBetweenTwoEntities(firstEntity, secondEntity)
    local firstVec = GetEntityCoords(firstEntity)
    local secondVec = GetEntityCoords(secondEntity)
    return #(firstVec.xy - secondVec.xy) -- Do not use Z
end

--- isTargetedPedDead?
---@param target ped
function isTargetedPedDead(target)
    local state = {
        IsPedDeadOrDying(target, 1), IsPlayerDead(target), IsEntityDead(target),
        IsEntityPlayingAnim(target, 'dead', 'dead_a', 3),
        IsEntityPlayingAnim(target, 'combat@damage@writhe', 'writhe_loop', 3)
    }
    -- IsEntityPlayingAnim(target, 'dead', 'dead_a', 3) or IsEntityPlayingAnim(target, 'combat@damage@writhe', 'writhe_loop', 3)
    -- these are needed when player's ped are playing bleeding animation or script will count then as not dead
    for key, value in pairs(state) do if value == 1 then return true end end
    return false
end

--- Ask game engine to flag entity as no longer needed
---@param entity entity
---@return void
function FlagEntityAsNoLongerNeeded(entity) SetEntityAsNoLongerNeeded(entity) end

--- assgin value of ActiveSessions to make sure it's always 0 at start of script
---@param Event number
function assignActiveSessionsValue(Event)
    if Event.timings.ActiveSessions == nil or Event.timings.ActiveSessions then
        Event.timings.ActiveSessions = 0
    end
    Event.timings.ActiveSessions = 0
end

--- update value of ActiveSessions
---@param Event number
function updateActiveSessionsValue(Event, type)
    if Event.timings.ActiveSessions == nil or Event.timings.ActiveSessions < 0 then
        Event.timings.ActiveSessions = 0
    end
    if type == 'increment' then
        Event.timings.ActiveSessions = Event.timings.ActiveSessions + 1
    elseif type == 'decrement' then
        Event.timings.ActiveSessions = Event.timings.ActiveSessions - 1
    end
end

-- # TODO cooldown just work for one event
-- ? event is stop decrement cooldown and just spawn one event 
--- assgin value of AssignedCooldown inside events to start cooldown for evetns
---@param Event number
function assignCooldownValue(Event)
    if Event.timings.CooldownDruration == nil or Event.timings.CooldownDruration then
        Event.timings.AssignedCooldown = Config.DefualtAssignedCooldown
    end
    Event.timings.AssignedCooldown = Event.timings.CooldownDruration
end

-- !FIX: cooldown just work for one event
-- ? event is stop decrement cooldown and just spawn one event 
--- update value of cooldown for event every sec. call it after wait 1000 in a thread
---@param Event any
function updateCooldownValue(Event)
    if Event.timings.AssignedCooldown == 0 or Event.timings.AssignedCooldown < 0 then
        return 0
    end
    Event.timings.AssignedCooldown = Event.timings.AssignedCooldown - 1000
end

--- Wait Until Events Are Loaded
---@param loadingIsDone boolean
function WaitUntilEventsAreLoaded(loadingIsDone)
    while loadingIsDone == false or START == false do Citizen.Wait(1) end
end

-- local CoreName = exports['qb-core']:GetCoreObject()
-- local player = CoreName.Functions.GetPlayerData()
