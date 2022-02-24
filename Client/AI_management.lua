-- global event Ai management
local activeEvents = {}
local activeEntities = {}
--
local loadingIsDone = false
-- events
Citizen.CreateThread(function()
    -- loading event inside activeEvents table
    for key, Event in pairs(Config.Events) do
        assignCooldownValue(Event)
        assignActiveSessionsValue(Event)
        table.insert(activeEvents, Event)
    end
    loadingIsDone = true
end)

-- Entities management system
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        for key, entity in pairs(activeEntities) do
            for ped, info in pairs(entity) do
                if isTargetedPedDead(info.targetedPed) == 1 then
                    leaveAreaWhenEventIsOver(ped, info)
                    activeEntities[key] = nil -- clean table as we no longer need information about peds
                    updateActiveSessionsValue(Event, 'increment')
                end
            end
        end
        print(#activeEntities)
    end
end)

function leaveAreaWhenEventIsOver(ped, info)
    TaskEnterVehicle(ped, info.vehicleRef, 10.0, info.seatIndex, 2.0, 1, 0)
    if info.seatIndex == -1 then
        TaskVehicleDriveWander(ped --[[ Ped ]] , info.vehicleRef --[[ Vehicle ]] , 60.0 --[[ number ]] , 1074528293 --[[ integer ]] )
    end
    FlagEntityAsNoLongerNeeded(ped)
end

function isExpectedDurationReached(currentDuration)
    if currentDuration <= 0 then
        return true
    elseif Config.DefualtExpectedEventDuration - currentDuration > 0 then
        return false
    end
end

function GetDistanceBetweenTwoEntities(firstEntity, secondEntity)
    return #(firstEntity.xy - secondEntity.xy) -- Do not use Z
end

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

-- > expire event thread Event.timings.ActiveDuration

Citizen.CreateThread(function()
    -- excute events
    WaitUntilEventsAreLoaded(loadingIsDone)
    while true do
        Wait(1000)
        for key, Event in pairs(activeEvents) do
            -- call event when cooldown is over
            if Event.timings.ActiveSessions >= Event.timings.maximumActiveSessionsForOnePlayer then
                break -- skip evetn when it's already is running more than needed!
            end
            if Event.timings.AssignedCooldown == 0 and ChanceToTrigger(Event.timings.ChanceToTrigger) == 1 then
                print('event ' .. Event.name .. ' is triggered')
                Event['Function']()
                Event.timings.AssignedCooldown = Event.timings.CooldownDruration -- reset cooldown after running it once
                updateActiveSessionsValue(Event, 'increment')
            end
            updateCooldownValue(Event)
        end
    end
end)

function FlagAsActiveEntities(entities, vehicleRef, targetedPed)
    local tmp = {}
    for key, entity in pairs(entities) do
        tmp[entity] = {
            type = GetEntityType(entity),
            vehicleRef = vehicleRef,
            seatIndex = (key - 2),
            duration = Config.DefualtExpectedEventDuration,
            distance = Config.DefualtExpectedPursueDistance,
            targetedPed = targetedPed,
            redirectTargetTo = ''
        }
    end
    table.insert(activeEntities, tmp)
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

--- assgin value of AssignedCooldown inside events to start cooldown for evetns
---@param Event number
function assignCooldownValue(Event)
    if Event.timings.CooldownDruration == nil or Event.timings.CooldownDruration then
        Event.timings.AssignedCooldown = Config.DefualtAssignedCooldown
    end
    Event.timings.AssignedCooldown = Event.timings.CooldownDruration
end

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
    while loadingIsDone == false do
        Citizen.Wait(1)
    end
end
