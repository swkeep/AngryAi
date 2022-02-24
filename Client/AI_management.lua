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
                            activeEntities[NPC_RelaseQueue_PED] = nil
                            NPC_RelaseQueue[key] = nil
                            goto continue
                        end
                    end
                end
                -- giveup on target death
                if isTargetedPedDead(info.targetedPed) == 1 then
                    ClearPedTasks(ped)
                    leaveArea(ped, info)
                    -- SetEntityHealth(ped, 0) --kill ped when it's done
                    activeEntities[key] = nil -- clean table as we no longer need information about peds
                    updateActiveSessionsValue(info.event, 'decrement')
                end
                -- keep track of Events duration Event.timings.ActiveDuration

                --print(info.event.timings.ActiveSessions)
                -- print(info.event.timings.AssignedCooldown)

                -- keep track of events duration distance

                local distance = GetDistanceBetweenTwoEntities(info.targetedPed, ped)
                if distance <= 5 then
                    PlayPedAmbientSpeechNative(ped , 'GENERIC_HI'  , 'Speech_Params_Allow_Repeat'  )
                end
                ::continue::
            end
        end
        -- print(#activeEntities)
        -- tprint(NPC_RelaseQueue)
    end
end)

function RelaseThisEntityNow(entity)
    table.insert(NPC_RelaseQueue, entity)
end

function leaveArea(ped, info)
    if info.vehicleRef ~= nil then
        TaskEnterVehicle(ped, info.vehicleRef, 10.0, info.seatIndex, 2.0, 1, 0)
        if info.seatIndex == -1 then
            TaskVehicleDriveWander(ped --[[ Ped ]] , info.vehicleRef --[[ Vehicle ]] , 60.0 --[[ number ]] , 1074528293 --[[ integer ]] )
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
            if Event.timings.ActiveSessions >= Event.timings.maximumActiveSessionsForOnePlayer then
                goto continue
            end
            if Event.timings.AssignedCooldown == 0 and ChanceToTrigger(Event.timings.ChanceToTrigger) == 1 then
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
    local EntityData = {}
    for key, entity in pairs(entities) do
        EntityData[entity] = {
            type = GetEntityType(entity),
            duration = Config.DefualtExpectedEventDuration,
            distance = Config.DefualtExpectedPursueDistance,
            targetedPed = targetedPed,
            event = event,
            eventKey = eventKey
        }
        if vehicleRef ~= nil then
            EntityData[entity].vehicle = {
                vehicleRef = vehicleRef,
                seatIndex = (key - 2)
            }
        end
    end
    table.insert(activeEntities, EntityData)
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
    local state
    -- IsEntityPlayingAnim(target, 'dead', 'dead_a', 3) or IsEntityPlayingAnim(target, 'combat@damage@writhe', 'writhe_loop', 3)
    -- these are needed when player's ped are playing bleeding animation or script will count then as not dead
    state = IsPedDeadOrDying(target, 1)
    state = IsPlayerDead(target)
    state = IsEntityDead(target)
    state = IsEntityPlayingAnim(target, 'dead', 'dead_a', 3)
    state = IsEntityPlayingAnim(target, 'combat@damage@writhe', 'writhe_loop', 3)
    return state
end

--- Ask game engine to flag entity as no longer needed
---@param entity entity
---@return void
function FlagEntityAsNoLongerNeeded(entity)
    SetEntityAsNoLongerNeeded(entity)
end

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
    while loadingIsDone == false or START == false do
        Citizen.Wait(1)
    end
end

-- local CoreName = exports['qb-core']:GetCoreObject()
-- local player = CoreName.Functions.GetPlayerData()
