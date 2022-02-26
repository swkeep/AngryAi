local interval = Config.TimeInterval
-- global event Ai management
local activeEvents = {}
local activeEntities = {}
--
local loadingIsDone = false
-- events loader
Citizen.CreateThread(function()
    -- loading events

    for key, Event in pairs(Config.Events) do
        local error = {}
        if Event.timings.CooldownDruration >= interval then
            assignCooldownValue(Event) -- create new filed in event to keep track of cooldown
            assignActiveSessionsValue(Event) -- create new filed in event to keep track of active sessions
            table.insert(activeEvents, Event)
            error = nil
        elseif Event.timings.CooldownDruration < interval then
            error = {
                eventName = Event.name,
                error = 'CooldownDruration cant be less than script interval'
            }
        end
        if error ~= nil then
            print('failed to load: ')
            print_table(error)
        end
    end
    print('events loaded:', #activeEvents)
    loadingIsDone = true
end)

local NPC_RelaseQueue = {}
-- Entities management system
Citizen.CreateThread(function()
    while true do
        Wait(interval)
        for key, entity in pairs(activeEntities) do
            for ped, info in pairs(entity) do
                -- force remove entities
                if NPC_RelaseQueue ~= nil then
                    RelaseEntityLogic(NPC_RelaseQueue, ped, info)
                end
                -- giveup on target death
                KeepTrackOfTragetDeath(info, ped)

                -- keep track of death and entity existence
                KeepTrackOfEntityDeath(info, ped)
                KeepTackOfEntityExistence(info, ped)

                -- keep track of Events duration Event.timings.ActiveDuration
                EventDurationTracker(info, ped)

                -- keep track of distance
                local distance = GetDistanceBetweenTwoEntities(info.targetedPed,
                                                               ped)
                TrackEventNpcDistance(distance, ped, info)

            end
        end
        -- print_table(activeEntities)
        -- tprint(NPC_RelaseQueue)
    end
end)

function EventDurationTracker(info, ped)
    if info.event.timings.AssignedDuration ~= nil and
        info.event.timings.AssignedDuration ~= 0 then
        info.event.timings.AssignedDuration = info.event.timings
                                                  .AssignedDuration - 1000
    elseif info.event.timings.AssignedDuration == 0 then
        RelaseThisEntityNow(ped)
    end
end

function KeepTackOfEntityExistence(info, ped)
    if DoesEntityExist(ped) == false then
        FlagEntityAsNoLongerNeeded(ped)
        updateActiveSessionsValue(info.event, 'decrement')
        activeEntities[info.eventKey][ped] = nil
    end
end

function KeepTrackOfEntityDeath(info, ped)
    if IsEntityDead(ped) == 1 then
        FlagEntityAsNoLongerNeeded(ped)
        updateActiveSessionsValue(info.event, 'decrement')
        activeEntities[info.eventKey][ped] = nil
    end
end

function KeepTrackOfTragetDeath(info, ped)
    if isTargetedPedDead(info.targetedPed) == true then
        ClearPedTasks(ped)
        leaveArea(ped, info)
        -- SetEntityHealth(ped, 0) --kill ped when it's done
        updateActiveSessionsValue(info.event, 'decrement')
        activeEntities[info.eventKey][ped] = nil -- clean table as we no longer need information about peds
    end
end

function TrackEventNpcDistance(distance, ped, info)
    if type(info.event.customDistance) == "function" then
        -- run customDistance if we have it in config file if not used default function
        info.event.customDistance(distance, ped, info.event)
        return
    end
    if distance <= 5 then
        PlayPedAmbientSpeechNative(ped, 'GENERIC_HI',
                                   'Speech_Params_Allow_Repeat')
    elseif distance > 130 then
        FlagEntityAsNoLongerNeeded(ped)
        updateActiveSessionsValue(info.event, 'decrement')
        activeEntities[info.eventKey][ped] = nil
    end
end

function RelaseEntityLogic(NPC_RelaseQueue, ped, info)
    for key, RelaseEntity in pairs(NPC_RelaseQueue) do
        local type = GetEntityType(RelaseEntity)
        if type == 1 then
            if ped == RelaseEntity then
                ClearPedTasks(RelaseEntity)
                FlagEntityAsNoLongerNeeded(RelaseEntity)
                updateActiveSessionsValue(info.event, 'decrement')
                activeEntities[info.eventKey][RelaseEntity] = nil
                NPC_RelaseQueue[key] = nil
                goto continue
            end
        elseif type == 2 then
            -- # TODO qbtarget sup for vehicles ????????
            -- local maxSeat = GetVehicleMaxNumberOfPassengers(RelaseEntity) -- from -1 to whatever
            -- for i = -1, maxSeat, 1 do
            --     local ped = GetPedInVehicleSeat(RelaseEntity, i)
            --     ClearPedTasks(ped)
            --     leaveArea(ped, {
            --         vehicle = {
            --             vehicleRef = RelaseEntity,
            --             seatIndex = i
            --         }
            --     })
            --     if i == maxSeat then
            --         FlagEntityAsNoLongerNeeded(RelaseEntity)
            --         updateActiveSessionsValue(info.event,
            --                                   'decrement')
            --         goto continue
            --     end
            -- end
            -- IsVehicleSeatFree(vehicle, seatIndex)
        end
    end
    ::continue::
end

function RelaseThisEntityNow(entity) table.insert(NPC_RelaseQueue, entity) end

function leaveArea(ped, info)
    if info.vehicle ~= nil then
        TaskEnterVehicle(ped, info.vehicle.vehicleRef, 10.0,
                         info.vehicle.seatIndex, 2.0, 1, 0)
        if info.vehicle.seatIndex == -1 then
            TaskVehicleDriveWander(ped --[[ Ped ]] , info.vehicle.vehicleRef,
                                   60.0 --[[ number ]] , 1074528293)
        end
    end
    FlagEntityAsNoLongerNeeded(ped)
end

Citizen.CreateThread(function()
    -- excute events
    WaitUntilEventsAreLoaded(loadingIsDone)
    while true do
        Wait(interval)
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
                Event.timings.AssignedDuration = Event.timings.ActiveDuration
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
    if Event.timings.CooldownDruration == nil then
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
