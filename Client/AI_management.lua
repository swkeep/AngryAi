local interval = Config.TimeInterval
local loadingIsDone = false
--  Ai management
-- #TODO max npc spawn per area?! maybe?!

--
NPC = {
    peds = {}
}
EVENT = {
    events = {}
}
function NPC:addPed(entity, vehicleRef, targetedPed, eventIndex)
    local entityData = {}
    local eventDuration = EVENT:readEvent(eventIndex).timings.activeEventDuration or nil

    entityData[entity] = {
        type = GetEntityType(entity),
        duration = eventDuration or Config.DefualtExpectedEventDuration,
        targetedPed = targetedPed,
        eventIndex = eventIndex
    }
    if vehicleRef ~= nil then
        entityData[entity].vehicle = vehicleRef
    end
    if self.peds[eventIndex] == nil then
        self.peds[eventIndex] = {}
    end
    if self.peds[eventIndex][entity] == nil then
        self.peds[eventIndex][entity] = {}
    end
    self.peds[eventIndex][entity] = entityData[entity]
end
function NPC:removePed(entity, eventIndex)
    self.peds[eventIndex][entity] = nil
end
function NPC:readPed(entity, eventIndex)
    return self.peds[eventIndex][entity]
end

function EVENT:addEvent(event)
    local eventData = {}
    eventData = {
        name = event.name,
        timings = {
            activeEventDuration = event.timings.activeEventDuration or nil,
            spawnCooldown = event.timings.spawnCooldown or nil,
            chanceToTrigger = event.timings.chanceToTrigger or nil,
            maxSessions = event.timings.maxSessions or nil
        },
        isTargetDead = event.isTargetDead or nil,
        customDistance = event.customDistance or nil,
        currentActiveSessions = {},
        currentCooldowns = {},
        eventBehavior = event.eventBehavior,
        Zone = event.Zone
    }
    table.insert(self.events, eventData)
end
function EVENT:manageActiveSessions(eventIndex, _type)
    -- event current session should be like 
    -- types increment/decrement or incrementNested/decrementNested
    if self.events[eventIndex].currentActiveSessions == nil then
        self.events[eventIndex].currentActiveSessions = {}
        return
    end
    local array = self.events[eventIndex].currentActiveSessions

    if _type == 'increment' then
        table.insert(array, 1)
    elseif _type == 'decrement' then
        table.remove(array, #array)
    end
end
function EVENT:removeEvent(eventIndex)
    self.events[eventIndex] = nil
end
function EVENT:readEvent(eventIndex)
    return self.events[eventIndex]
end
function EVENT:readEvent(eventIndex)
    return self.events[eventIndex]
end
function EVENT:readAll()
    return self.events
end
function EVENT:getSize()
    return #self.events
end
function EVENT:manangeCooldown(eventIndex, _type)
    local defaultCooldown = self.events[eventIndex].timings.spawnCooldown -- number
    local currentCooldowns = self.events[eventIndex].currentCooldowns -- table

    if _type == 'addCooldown' then
        table.insert(currentCooldowns, defaultCooldown)
    elseif _type == 'update' then
        for key, currentCooldown in pairs(currentCooldowns) do
            if currentCooldown > 0 then
                currentCooldowns[key] = currentCooldowns[key] - 1000
            elseif currentCooldown <= 0 then
                currentCooldowns[key] = 0
            end
        end
    end
end

local NPC_RelaseQueue = {}
-- 

-- event loader
Citizen.CreateThread(function()
    -- loading events
    for key, Event in pairs(Config.Events) do
        -- add event to event chain when there is no error detected
        if Event.timings.spawnCooldown < interval then
            Loading_ErrorHandler(1)
        else
            EVENT:addEvent(Event)
        end
    end
    print('events loaded:', EVENT:getSize())
    loadingIsDone = true
end)

--- contains all error messages 
---@param errorNumber integer
function Loading_ErrorHandler(errorNumber)
    local error = {
        [1] = 'script cant spawn faster than its interval'
    }
    print('failed to load: ', error[errorNumber])
end

-- Entities management system
Citizen.CreateThread(function()
    while true do
        Wait(interval)
        for key, entity in pairs(NPC.peds) do
            for ped, info in pairs(entity) do
                local event = EVENT:readEvent(info['eventIndex'])
                -- force remove entities
                if next(NPC_RelaseQueue) ~= nil then
                    RelaseEntityLogic(NPC_RelaseQueue, ped, event)
                    goto skip
                end
                -- track target death logic
                KeepTrackOfTragetDeath(event, ped) --

                -- keep track of npc death and existence
                KeepTrackOfEntityDeath(event, ped) --
                KeepTackOfEntityExistence(event, ped) --

                -- keep track of Events duration Event.timings.ActiveDuration

                EventDurationTracker(event, ped)

                -- keep track of distance
                TrackEventNpcDistanceToTarget(event, ped)
                ::skip::
            end
        end
    end
end)

Zones = {}

Citizen.CreateThread(function()
    WaitUntilEventsAreLoaded(loadingIsDone)
    -- event excution routine
    local events = EVENT:readAll()
    for key, Event in pairs(events) do
        -- save zoneRef in Zones
        if Event.Zone ~= nil then
            Zones[key] = Event.Zone()
        end
    end
    while true do
        Wait(interval)
        for key, Event in pairs(events) do
            -- call event when cooldown is over
            if Event.timings.maxSessions == 0 then
                -- maxSessions = 0 means we don't want to spawn this event!
            else
                local chance = ChanceToTrigger(Event.timings.chanceToTrigger)
                local event = EVENT:readEvent(key)
                local SessionTrigger = canWeCreateMoreEventOfThisType(event)
                local cooldownTrigger = isEventStillOnCooldown(event)
                local insideZone
                local customDeathFunction

                if event['isTargetDead'] ~= nil then
                    customDeathFunction = event['isTargetDead']()
                else
                    customDeathFunction = isTargetedPedDead(PlayerPedId())
                end

                -- check if we have need to be in a zone!?
                if Zones[key] ~= nil then
                    insideZone = Zones[key]:isPointInside(GetEntityCoords(PlayerPedId()))
                else
                    insideZone = true
                end

                if insideZone and SessionTrigger and not cooldownTrigger and not customDeathFunction and chance == 1 then
                    print('event ' .. Event.name .. ' triggered')
                    local ped, veh, target = Event['eventBehavior']()
                    ActivateAIManagement(ped, veh, target, Event, key)
                    EVENT:manageActiveSessions(key, 'increment')
                    EVENT:manangeCooldown(key, 'addCooldown')
                end
                EVENT:manangeCooldown(key, 'update')
            end
        end
    end
end)

function isEventStillOnCooldown(event)
    local tmp = {}
    for key, cooldown in pairs(event.currentCooldowns) do
        if cooldown == 0 then
            table.insert(tmp, 1)
        end
    end
    return not (#tmp == #event.currentCooldowns)
end

--- track events active duration 
---@param event 'event'
---@param ped 'ped'
function EventDurationTracker(event, ped)
    local pedMetaData = NPC:readPed(ped, event.eventKey)
    if pedMetaData ~= nil and pedMetaData.duration ~= 0 then
        pedMetaData.duration = pedMetaData.duration - 1000
    elseif pedMetaData ~= nil and pedMetaData.duration == 0 then
        RelaseThisEntityNow(ped)
    end
end

--- excute custom distance function or run defalut function
---@param ped 'ped'
---@param event 'event'
function TrackEventNpcDistanceToTarget(event, ped)
    local pedMetaData = NPC:readPed(ped, event.eventKey)
    if pedMetaData ~= nil then
        local distance = GetDistanceBetweenTwoEntities(ped, pedMetaData.targetedPed)
        if event.customDistance ~= nil and type(event.customDistance) == "function" then
            -- run customDistance if we have it in config file if not used default function
            event.customDistance(distance, ped, event)
            return
        end
        if distance > 130 then
            SetEntityAsNoLongerNeeded(ped)
            EVENT:manageActiveSessions(event.eventKey, 'decrement')
            NPC:removePed(ped, event.eventKey)
        end
    end
end

---retrun true if we have space to add new event 
---@param currenEventData 'event'
---@return boolean
function canWeCreateMoreEventOfThisType(currenEventData)
    -- compare current active Sessions to maxSessions in config file
    if currenEventData.timings.maxSessions - #currenEventData.currentActiveSessions > 0 then
        return true
    else
        return false
    end
end

--- does entity exist? and what to do if it doesn't!
---@param event 'event'
---@param ped 'ped'
function KeepTackOfEntityExistence(event, ped)
    if DoesEntityExist(ped) == false then
        SetEntityAsNoLongerNeeded(ped)
        EVENT:manageActiveSessions(event['eventKey'], 'decrement')
        NPC:removePed(ped, event['eventKey'])
    end
end

--- is entity alive? and what to do if it doesn't!
---@param event 'event'
---@param ped 'ped'
function KeepTrackOfEntityDeath(event, ped)
    -- #TODO when we spawn more than one entiry this will remove one event per entity so add more to events!?
    if IsEntityDead(ped) == 1 then
        SetEntityAsNoLongerNeeded(ped)
        EVENT:manageActiveSessions(event['eventKey'], 'decrement')
        NPC:removePed(ped, event['eventKey'])
    end
end

--- is target still alive? what to do if its not!
---@param event 'event'
---@param ped 'ped'
function KeepTrackOfTragetDeath(event, ped)
    local customDeathFunction
    if event['isTargetDead'] ~= nil then
        customDeathFunction = event['isTargetDead']()
    else
        customDeathFunction = isTargetedPedDead(PlayerPedId())
    end
    if customDeathFunction == true then
        ClearPedTasks(ped)
        LeaveArea(ped, event)
        EVENT:manageActiveSessions(event['eventKey'], 'decrement')
        NPC:removePed(ped, event['eventKey'])
    end
    -- SetEntityHealth(ped, 0) --kill ped when it's done
end

---logic of how we relase npcs from script
---@param NPC_RelaseQueue 'table'
---@param ped 'ped'
---@param event 'event'
function RelaseEntityLogic(NPC_RelaseQueue, ped, event)
    for key, RelaseEntity in pairs(NPC_RelaseQueue) do
        local type = GetEntityType(RelaseEntity)
        if type == 1 then
            if ped == RelaseEntity then
                ClearPedTasks(RelaseEntity)
                SetEntityAsNoLongerNeeded(RelaseEntity)
                EVENT:manageActiveSessions(event['eventKey'], 'decrement')
                NPC:removePed(RelaseEntity, event['eventKey'])
                NPC_RelaseQueue[key] = nil
            end
        elseif type == 2 then
            -- # TODO qbtarget sup for vehicles ????????
            -- local maxSeat = GetVehicleMaxNumberOfPassengers(RelaseEntity) -- from -1 to whatever
            -- for i = -1, maxSeat, 1 do
            --     local ped = GetPedInVehicleSeat(RelaseEntity, i)
            --     ClearPedTasks(ped)
            --     LeaveArea(ped, {
            --         vehicle = {
            --             vehicleRef = RelaseEntity,
            --             seatIndex = i
            --         }
            --     })
            --     if i == maxSeat then
            --         SetEntityAsNoLongerNeeded(RelaseEntity)
            --          EVENT:manageActiveSessions(info.event , 'decrement')

            --         goto continue
            --     end
            -- end
            -- IsVehicleSeatFree(vehicle, seatIndex)
        end
    end
end

--- add 'Entity' to NPC_RelaseQueue: script will remove this 'Entity' from its peds pool
---@param entity any
function RelaseThisEntityNow(entity)
    table.insert(NPC_RelaseQueue, entity)
end

--- peds or ped will find their vehicle and then leave area
---@param ped 'ped'
---@param event 'event'
function LeaveArea(ped, event)
    local pedMetaData = NPC:readPed(ped, event['eventKey'])
    if pedMetaData.vehicle ~= nil then
        TaskEnterVehicle(ped, pedMetaData.vehicle.vehicleRef, 10.0, pedMetaData.vehicle.seatIndex, 2.0, 1, 0)
        if pedMetaData.vehicle.seatIndex == -1 then
            TaskVehicleDriveWander(ped, pedMetaData.vehicle.vehicleRef, 60.0, 1074528293)
        end
    end
    SetEntityAsNoLongerNeeded(ped)
end

--- pass entities/entity control to scirpt 
---@param entities 'ped or peds'
---@param vehicleRef 'vehicle'
---@param targetedPed 'ped'
---@param event 'Event'
---@param eventKey 'Event index'
function ActivateAIManagement(entities, vehicleRef, targetedPed, event, eventKey)
    -- create data struct needed for tracking entities
    local tmpVehRef = nil
    local tmpEvent = event
    tmpEvent.eventKey = eventKey

    if type(entities) == "table" then
        for key, entity in pairs(entities) do
            if vehicleRef ~= nil then
                tmpVehRef = {}
                tmpVehRef = {
                    vehicleRef = vehicleRef,
                    seatIndex = (key - 2)
                }
            end
            NPC:addPed(entity, tmpVehRef, targetedPed, eventKey)
        end
    elseif type(entities) == "number" then
        if vehicleRef ~= nil then
            tmpVehRef = {}
            tmpVehRef = {
                vehicleRef = vehicleRef,
                seatIndex = -1
            }
        end
        NPC:addPed(entities, tmpVehRef, targetedPed, eventKey)
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
---@param firstEntity 'Entity'
---@param secondEntity 'Entity'
function GetDistanceBetweenTwoEntities(firstEntity, secondEntity)
    local firstVec = GetEntityCoords(firstEntity)
    local secondVec = GetEntityCoords(secondEntity)
    return #(firstVec.xy - secondVec.xy) -- Do not use Z
end

--- is Targeted Ped Dead?
---@param target 'ped'
function isTargetedPedDead(target)
    local state = {IsPedDeadOrDying(target, 1), IsPlayerDead(target), IsEntityDead(target),
                   IsEntityPlayingAnim(target, 'dead', 'dead_a', 3),
                   IsEntityPlayingAnim(target, 'combat@damage@writhe', 'writhe_loop', 3)}
    -- IsEntityPlayingAnim(target, 'dead', 'dead_a', 3) or IsEntityPlayingAnim(target, 'combat@damage@writhe', 'writhe_loop', 3)
    -- these are needed when player's ped is playing bleeding animation
    for key, value in pairs(state) do
        if value == 1 then
            return true
        end
    end
    return false
end

--- Wait Until Events Are Loaded
---@param loadingIsDone boolean
function WaitUntilEventsAreLoaded(loadingIsDone)
    while loadingIsDone == false or START == false do
        Citizen.Wait(1)
    end
end
