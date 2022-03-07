# AngryAi
Bunch of predefined NPC behavior functions and npc/event management system

** 

It's not optimized by any mean. i made it to just test something in my server.
event template

```lua
{
    name = 'event name',
    timings = {
        activeEventDuration = 60000,
        spawnCooldown = 2000,
        chanceToTrigger = 50,
        maxSessions = 2
    },
    isTargetDead = function()
        return isTargetedPedDead(PlayerPedId())
    end,
    customDistance = function(distance, ped, info)
    end,
    Zone = function()
        return BoxZone:Create()
    end,
    eventBehavior = function()
        return ped, pedveh, playerPed
    end
}
```
