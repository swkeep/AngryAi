--- get safe coord for spawn around given coord 
---@param coord 'vector3'
---@return 'vector3'
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
    return vector3(posX, posY, posZ)
end

--- spwan one vehicle with given models for peds
---@param pedmodels 'models table'
---@param vehiclemodel 'model'
---@param spwanCoord number
---@param heading number
---@return 'pedsRef , vehicleRef'
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

--- ped will change their positions toward target and they will walk!
---@param ped 'ped'
---@param target 'ped'
function ChatWithTarget(ped, target)
    TaskChatToPed(ped, target, 17, 0.0, 0.0, 0.0, 0.0, 0.0)
end

--- if ped is in vehicle they gonna move toward given goal
---@param ped 'ped'
---@param pedVehicle 'ped'
---@param goal 'coord'
---@param vehHash 'hash'
function DriveToGoal(ped, pedVehicle, goal, vehHash)
    -- Let the car move
    TaskVehicleDriveToCoord(ped, pedVehicle, goal.x, goal.y, goal.z, 50.0, 0,
                            vehHash, 1074528293, 5.0, true)
end

--- group of peds to seek and attack one ped
---@param attackersListByReference table
---@param targetPed 'ped'
function CrewAttackTargetedPed(attackersListByReference, targetPed)
    for key, ped in pairs(attackersListByReference) do
        AttackTargetedPed(ped, targetPed)
        SetRelationshipBetweenPed(ped)
    end
end

--- gives ped ability to follow and attack targeted ped
---@param AttackerPed 'ped'
---@param targetPed 'ped'
---@return 'void'
function AttackTargetedPed(AttackerPed, targetPed)
    if not AttackerPed and not targetPed then return end
    SetPedCombatAttributes(AttackerPed, 46, 1)
    TaskGoToEntityWhileAimingAtEntity(AttackerPed, targetPed, targetPed, 1, 1,
                                      0, 15, 1, 1, 1566631136)
    TaskCombatPed(AttackerPed, targetPed, 0, 16)
end

--- remove Relationship againt player.
---@param ped 'ped'
function removeRelationship(ped)
    if not ped then return end
    RemovePedFromGroup(ped)
end

--- set relationship with ped againt player. and disable Friendly fire when fighting againt player.
---@param ped 'ped'
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
---@return 'void'
function giveWeaponToPed(ped, weaponName)
    if not ped and not weaponName then return end
    GiveWeaponToPed(ped, GetHashKey(weaponName), 1, false, false)
end

--- wait for model to load
---@param model 'model'
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

---give ped a randowm voice by gender and origin
---@param ped 'ped'
---@param gender string
---@param origin string
---@return boolean
function GivePedRandomVoice(ped, gender, origin)
    local speech = {
        FEMALE = {
            BLACK = {
                'A_F_M_SKIDROW_01_BLACK_FULL_01',
                'A_F_M_SKIDROW_01_BLACK_MINI_01',
                'A_F_M_TRAMPBEAC_01_BLACK_FULL_01',
                'A_F_M_TRAMPBEAC_01_BLACK_MINI_01',
                'A_F_O_SOUCENT_01_BLACK_FULL_01',
                'A_M_M_BEACH_02_BLACK_FULL_01',
                'A_M_M_SKIDROW_01_BLACK_FULL_01',
                'A_F_M_BEVHILLS_02_BLACK_FULL_01',
                'A_F_M_SOUCENT_01_BLACK_FULL_01',
                'A_F_M_SOUCENT_02_BLACK_FULL_01',
                'A_F_O_SOUCENT_02_BLACK_FULL_01',
                'A_F_Y_BEACH_01_BLACK_MINI_01', 'A_F_Y_BEACH_BLACK_FULL_01',
                'A_F_Y_BUSINESS_04_BLACK_FULL_01',
                'A_F_Y_BUSINESS_04_BLACK_MINI_01',
                'A_F_Y_FITNESS_02_BLACK_FULL_01',
                'A_F_Y_FITNESS_02_BLACK_MINI_01',
                'A_F_Y_SOUCENT_01_BLACK_FULL_01',
                'A_F_Y_SOUCENT_02_BLACK_FULL_01',
                'A_F_Y_TENNIS_01_BLACK_MINI_01'
            },
            LATINO = {
                'A_F_M_EASTSA_01_LATINO_FULL_01',
                'A_F_Y_BUSINESS_03_LATINO_FULL_01',
                'A_F_Y_EASTSA_01_LATINO_FULL_01',
                'A_F_Y_EASTSA_01_LATINO_MINI_01',
                'A_F_Y_EASTSA_03_LATINO_FULL_01',
                'A_F_Y_EASTSA_03_LATINO_MINI_01',
                'A_F_Y_SOUCENT_03_LATINO_FULL_01',
                'A_F_Y_SOUCENT_03_LATINO_MINI_01'
            },
            WHITE = {
                'A_F_M_BEACH_01_WHITE_FULL_01', 'A_F_M_TRAMP_01_WHITE_FULL_01',
                'A_F_M_TRAMP_01_WHITE_MINI_01',
                'A_F_M_TRAMPBEAC_01_WHITE_FULL_01',
                'A_F_Y_VINEWOOD_01_WHITE_FULL_01',
                'A_F_Y_VINEWOOD_01_WHITE_MINI_01',
                'A_F_Y_VINEWOOD_02_WHITE_FULL_01',
                'A_F_Y_VINEWOOD_02_WHITE_MINI_01',
                'A_F_M_BEVHILLS_01_WHITE_FULL_01',
                'A_F_M_BEVHILLS_01_WHITE_MINI_01',
                'A_F_M_BEVHILLS_01_WHITE_MINI_02',
                'A_F_M_SKIDROW_01_WHITE_FULL_01',
                'A_F_M_SKIDROW_01_WHITE_MINI_01',
                'A_F_O_GENSTREET_01_WHITE_MINI_01',
                'A_F_O_SALTON_01_WHITE_FULL_01',
                'A_F_O_SALTON_01_WHITE_MINI_01', 'A_F_Y_BEACH_01_WHITE_FULL_01',
                'A_F_Y_BEACH_01_WHITE_MINI_01',
                'A_F_Y_BEVHILLS_01_WHITE_FULL_01',
                'A_F_Y_BEVHILLS_01_WHITE_MINI_01',
                'A_F_Y_BEVHILLS_02_WHITE_FULL_01',
                'A_F_Y_BEVHILLS_02_WHITE_MINI_01',
                'A_F_Y_BEVHILLS_02_WHITE_MINI_02',
                'A_F_Y_BEVHILLS_03_WHITE_FULL_01',
                'A_F_Y_BEVHILLS_03_WHITE_MINI_01',
                'A_F_Y_BEVHILLS_04_WHITE_FULL_01',
                'A_F_Y_BEVHILLS_04_WHITE_MINI_01',
                'A_F_Y_BUSINESS_01_WHITE_FULL_01',
                'A_F_Y_BUSINESS_01_WHITE_MINI_01',
                'A_F_Y_BUSINESS_01_WHITE_MINI_02',
                'A_F_Y_BUSINESS_02_WHITE_FULL_01',
                'A_F_Y_BUSINESS_02_WHITE_MINI_01',
                'A_F_Y_BUSINESS_04_WHITE_MINI_01',
                'A_F_Y_EASTSA_02_WHITE_FULL_01',
                'A_F_Y_EPSILON_01_WHITE_MINI_01', -- EPSILON
                'A_F_Y_FITNESS_01_WHITE_FULL_01',
                'A_F_Y_FITNESS_01_WHITE_MINI_01',
                'A_F_Y_FITNESS_02_WHITE_FULL_01',
                'A_F_Y_FITNESS_02_WHITE_MINI_01',
                'A_F_Y_GOLFER_01_WHITE_FULL_01',
                'A_F_Y_GOLFER_01_WHITE_MINI_01', 'A_F_Y_HIKER_01_WHITE_FULL_01',
                'A_F_Y_HIKER_01_WHITE_MINI_01',
                'A_F_Y_HIPSTER_01_WHITE_FULL_01',
                'A_F_Y_HIPSTER_01_WHITE_MINI_01',
                'A_F_Y_HIPSTER_02_WHITE_FULL_01',
                'A_F_Y_HIPSTER_02_WHITE_MINI_01',
                'A_F_Y_HIPSTER_02_WHITE_MINI_02',
                'A_F_Y_HIPSTER_03_WHITE_FULL_01',
                'A_F_Y_HIPSTER_03_WHITE_MINI_01',
                'A_F_Y_HIPSTER_03_WHITE_MINI_02',
                'A_F_Y_HIPSTER_04_WHITE_FULL_01',
                'A_F_Y_HIPSTER_04_WHITE_MINI_01',
                'A_F_Y_HIPSTER_04_WHITE_MINI_02',
                'A_F_Y_SKATER_01_WHITE_FULL_01',
                'A_F_Y_SKATER_01_WHITE_MINI_01',
                'A_F_Y_TENNIS_01_WHITE_MINI_01',
                'A_F_Y_VINEWOOD_04_WHITE_FULL_01',
                'A_F_Y_VINEWOOD_04_WHITE_MINI_01',
                'A_F_Y_VINEWOOD_04_WHITE_MINI_02', ''

            },
            TOURIST = {
                'A_F_M_TOURIST_01_WHITE_MINI_01',
                'A_F_Y_TOURIST_01_BLACK_FULL_01',
                'A_F_Y_TOURIST_01_BLACK_MINI_01',
                'A_F_Y_TOURIST_01_LATINO_FULL_01',
                'A_F_Y_TOURIST_01_LATINO_MINI_01',
                'A_F_Y_TOURIST_01_WHITE_FULL_01',
                'A_F_Y_TOURIST_01_WHITE_MINI_01',
                'A_F_Y_TOURIST_02_WHITE_MINI_01'
            },
            INDIAN = {
                'A_F_O_INDIAN_01_INDIAN_MINI_01',
                'A_F_Y_INDIAN_01_INDIAN_MINI_01',
                'A_F_Y_INDIAN_01_INDIAN_MINI_02'
            },
            KOREAN = {
                'A_F_O_KTOWN_01_KOREAN_FULL_01', 'A_F_O_KTOWN_01_KOREAN_MINI_01'
            },
            CHINESE = {
                'A_F_Y_BUSINESS_03_CHINESE_FULL_01',
                'A_F_Y_BUSINESS_03_CHINESE_MINI_01',
                'A_F_Y_VINEWOOD_03_CHINESE_FULL_01',
                'A_F_Y_VINEWOOD_03_CHINESE_MINI_01'
            }
        },
        MALE = {
            BLACK = {
                'A_M_M_AFRIAMER_01_BLACK_FULL_01',
                'A_M_M_BEACH_01_BLACK_MINI_01', 'A_M_M_BEACH_02_BLACK_FULL_01',
                'A_M_M_BEVHILLS_01_BLACK_FULL_01',
                'A_M_M_BEVHILLS_01_BLACK_MINI_01',
                'A_M_M_BEVHILLS_02_BLACK_FULL_01',
                'A_M_M_BEVHILLS_02_BLACK_MINI_01',
                'A_M_M_BUSINESS_01_BLACK_FULL_01',
                'A_M_M_BUSINESS_01_BLACK_MINI_01',
                'A_M_M_GOLFER_01_BLACK_FULL_01',
                'A_M_M_MALIBU_01_BLACK_FULL_01',
                'A_M_M_SKATER_01_BLACK_FULL_01',
                'A_M_M_SKIDROW_01_BLACK_FULL_01',
                'A_M_M_SOUCENT_01_BLACK_FULL_01',
                'A_M_M_SOUCENT_02_BLACK_FULL_01',
                'A_M_M_SOUCENT_03_BLACK_FULL_01',
                'A_M_M_SOUCENT_04_BLACK_FULL_01',
                'A_M_M_SOUCENT_04_BLACK_MINI_01',
                'A_M_M_TENNIS_01_BLACK_MINI_01', 'A_M_M_TRAMP_01_BLACK_FULL_01',
                'A_M_M_TRAMP_01_BLACK_MINI_01',
                'A_M_M_TRAMPBEAC_01_BLACK_FULL_01',
                'A_M_O_SOUCENT_01_BLACK_FULL_01',
                'A_M_O_SOUCENT_02_BLACK_FULL_01',
                'A_M_O_SOUCENT_03_BLACK_FULL_01',
                'A_M_O_TRAMP_01_BLACK_FULL_01', 'A_M_Y_BEACH_03_BLACK_FULL_01',
                'A_M_Y_BEACH_03_BLACK_MINI_01',
                'A_M_Y_BEVHILLS_01_BLACK_FULL_01',
                'A_M_Y_BEVHILLS_02_BLACK_FULL_01',
                'A_M_Y_BUSINESS_01_BLACK_FULL_01',
                'A_M_Y_BUSINESS_01_BLACK_MINI_01',
                'A_M_Y_BUSINESS_02_BLACK_FULL_01',
                'A_M_Y_BUSINESS_02_BLACK_MINI_01',
                'A_M_Y_BUSINESS_03_BLACK_FULL_01',
                'A_M_Y_DOWNTOWN_01_BLACK_FULL_01',
                'A_M_Y_EPSILON_01_BLACK_FULL_01', 'A_M_Y_GAY_01_BLACK_FULL_01',
                'A_M_Y_GENSTREET_02_BLACK_FULL_01',
                'A_M_Y_HIPSTER_01_BLACK_FULL_01',
                'A_M_Y_MUSCLBEAC_01_BLACK_FULL_01',
                'A_M_Y_SKATER_02_BLACK_FULL_01',
                'A_M_Y_SOUCENT_01_BLACK_FULL_01',
                'A_M_Y_SOUCENT_02_BLACK_FULL_01',
                'A_M_Y_SOUCENT_03_BLACK_FULL_01',
                'A_M_Y_SOUCENT_04_BLACK_FULL_01',
                'A_M_Y_SOUCENT_04_BLACK_MINI_01',
                'A_M_Y_STBLA_01_BLACK_FULL_01', 'A_M_Y_STBLA_02_BLACK_FULL_01',
                'A_M_Y_SUNBATHE_01_BLACK_FULL_01',
                'A_M_Y_VINEWOOD_01_BLACK_FULL_01',
                'A_M_Y_VINEWOOD_01_BLACK_MINI_01'
            },
            LATINO = {
                'A_M_M_BEACH_01_LATINO_FULL_01',
                'A_M_M_BEACH_01_LATINO_MINI_01',
                'A_M_M_EASTSA_01_LATINO_FULL_01',
                'A_M_M_EASTSA_01_LATINO_MINI_01',
                'A_M_M_EASTSA_02_LATINO_FULL_01',
                'A_M_M_EASTSA_02_LATINO_MINI_01',
                'A_M_M_FATLATIN_01_LATINO_FULL_01',
                'A_M_M_FATLATIN_01_LATINO_MINI_01',
                'A_M_M_GENFAT_01_LATINO_FULL_01',
                'A_M_M_GENFAT_01_LATINO_MINI_01',
                'A_M_M_MALIBU_01_LATINO_FULL_01',
                'A_M_M_MALIBU_01_LATINO_MINI_01',
                'A_M_M_SOCENLAT_01_LATINO_FULL_01',
                'A_M_M_SOCENLAT_01_LATINO_MINI_01',
                'A_M_M_STLAT_02_LATINO_FULL_01',
                'A_M_M_TRANVEST_02_LATINO_FULL_01',
                'A_M_M_TRANVEST_02_LATINO_MINI_01',
                'A_M_Y_BEACH_02_LATINO_FULL_01',
                'A_M_Y_EASTSA_01_LATINO_FULL_01',
                'A_M_Y_EASTSA_01_LATINO_MINI_01',
                'A_M_Y_EASTSA_02_LATINO_FULL_01', 'A_M_Y_GAY_01_LATINO_FULL_01',
                'A_M_Y_GENSTREET_02_LATINO_FULL_01',
                'A_M_Y_GENSTREET_02_LATINO_MINI_01',
                'A_M_Y_LATINO_01_LATINO_MINI_01',
                'A_M_Y_LATINO_01_LATINO_MINI_02',
                'A_M_Y_MEXTHUG_01_LATINO_FULL_01',
                'A_M_Y_MUSCLBEAC_02_LATINO_FULL_01',
                'A_M_Y_STLAT_01_LATINO_FULL_01',
                'A_M_Y_STLAT_01_LATINO_MINI_01',
                'A_M_Y_VINEWOOD_03_LATINO_FULL_01',
                'A_M_Y_VINEWOOD_03_LATINO_MINI_01', ''
            },
            WHITE = {
                'A_M_M_BEACH_01_WHITE_FULL_01', 'A_M_M_BEACH_01_WHITE_MINI_02',
                'A_M_M_BEACH_02_WHITE_FULL_01', 'A_M_M_BEACH_02_WHITE_MINI_01',
                'A_M_M_BEACH_02_WHITE_MINI_02',
                'A_M_M_BEVHILLS_01_WHITE_FULL_01',
                'A_M_M_BEVHILLS_01_WHITE_MINI_01',
                'A_M_M_BEVHILLS_02_WHITE_FULL_01',
                'A_M_M_BEVHILLS_02_WHITE_MINI_01',
                'A_M_M_BUSINESS_01_WHITE_FULL_01',
                'A_M_M_BUSINESS_01_WHITE_MINI_01',
                'A_M_M_FARMER_01_WHITE_MINI_01',
                'A_M_M_FARMER_01_WHITE_MINI_02',
                'A_M_M_FARMER_01_WHITE_MINI_03',
                'A_M_M_GENERICMALE_01_WHITE_MINI_01',
                'A_M_M_GENERICMALE_01_WHITE_MINI_02',
                'A_M_M_GENERICMALE_01_WHITE_MINI_03',
                'A_M_M_GENERICMALE_01_WHITE_MINI_04',
                'A_M_M_GOLFER_01_WHITE_FULL_01',
                'A_M_M_GOLFER_01_WHITE_MINI_01',
                'A_M_M_HASJEW_01_WHITE_MINI_01s',
                'A_M_M_HILLBILLY_01_WHITE_MINI_01',
                'A_M_M_HILLBILLY_01_WHITE_MINI_02',
                'A_M_M_HILLBILLY_01_WHITE_MINI_03',
                'A_M_M_HILLBILLY_02_WHITE_MINI_01',
                'A_M_M_HILLBILLY_02_WHITE_MINI_02',
                'A_M_M_HILLBILLY_02_WHITE_MINI_03',
                'A_M_M_HILLBILLY_02_WHITE_MINI_04',
                'A_M_M_MALIBU_01_WHITE_FULL_01',
                'A_M_M_MALIBU_01_WHITE_MINI_01',
                'A_M_M_SALTON_01_WHITE_FULL_01',
                'A_M_M_SALTON_02_WHITE_FULL_01',
                'A_M_M_SALTON_02_WHITE_MINI_01',
                'A_M_M_SALTON_02_WHITE_MINI_02',
                'A_M_M_SKATER_01_WHITE_FULL_01',
                'A_M_M_SKATER_01_WHITE_MINI_01',
                'A_M_M_TENNIS_01_WHITE_MINI_01',
                'A_M_M_TRANVEST_01_WHITE_MINI_01',
                'A_M_O_BEACH_01_WHITE_FULL_01', 'A_M_O_BEACH_01_WHITE_MINI_01',
                'A_M_O_GENSTREET_01_WHITE_FULL_01',
                'A_M_O_GENSTREET_01_WHITE_MINI_01',
                'A_M_O_SALTON_01_WHITE_FULL_01',
                'A_M_O_SALTON_01_WHITE_MINI_01', 'A_M_Y_BEACH_01_WHITE_FULL_01',
                'A_M_Y_BEACH_01_WHITE_MINI_01', 'A_M_Y_BEACH_02_WHITE_FULL_01',
                'A_M_Y_BEACH_03_WHITE_FULL_01',
                'A_M_Y_BEACHVESP_01_WHITE_FULL_01',
                'A_M_Y_BEACHVESP_02_WHITE_FULL_01',
                'A_M_Y_BEACHVESP_02_WHITE_MINI_01',
                'A_M_Y_BEVHILLS_01_WHITE_FULL_01',
                'A_M_Y_BEVHILLS_02_WHITE_FULL_01',
                'A_M_Y_BEVHILLS_02_WHITE_MINI_01',
                'A_M_Y_BUSICAS_01_WHITE_MINI_01',
                'A_M_Y_BUSINESS_01_WHITE_FULL_01',
                'A_M_Y_BUSINESS_01_WHITE_MINI_02',
                'A_M_Y_BUSINESS_02_WHITE_FULL_01',
                'A_M_Y_BUSINESS_02_WHITE_MINI_01',
                'A_M_Y_BUSINESS_02_WHITE_MINI_02',
                'A_M_Y_BUSINESS_03_WHITE_MINI_01',
                'A_M_Y_EPSILON_01_WHITE_FULL_01',
                'A_M_Y_EPSILON_02_WHITE_MINI_01', 'A_M_Y_GAY_02_WHITE_MINI_01',
                'A_M_Y_GENSTREET_01_WHITE_FULL_01',
                'A_M_Y_GENSTREET_01_WHITE_MINI_01',
                'A_M_Y_GOLFER_01_WHITE_FULL_01',
                'A_M_Y_GOLFER_01_WHITE_MINI_01',
                'A_M_Y_HASJEW_01_WHITE_MINI_01', 'A_M_Y_HIPPY_01_WHITE_FULL_01',
                'A_M_Y_HIPSTER_01_WHITE_FULL_01',
                'A_M_Y_HIPPY_01_WHITE_MINI_01',
                'A_M_Y_HIPSTER_01_WHITE_MINI_01',
                'A_M_Y_HIPSTER_02_WHITE_FULL_01',
                'A_M_Y_HIPSTER_02_WHITE_MINI_01',
                'A_M_Y_HIPSTER_03_WHITE_FULL_01',
                'A_M_Y_HIPSTER_03_WHITE_MINI_01',
                'A_M_Y_MUSCLBEAC_01_WHITE_FULL_01',
                'A_M_Y_MUSCLBEAC_01_WHITE_MINI_01',
                'A_M_Y_RACER_01_WHITE_MINI_01', 'A_M_Y_RUNNER_01_WHITE_FULL_01',
                'A_M_Y_RUNNER_01_WHITE_MINI_01',
                'A_M_Y_SALTON_01_WHITE_MINI_01',
                'A_M_Y_SALTON_01_WHITE_MINI_02',
                'A_M_Y_SKATER_01_WHITE_FULL_01',
                'A_M_Y_SKATER_01_WHITE_MINI_01', 'A_M_Y_STWHI_01_WHITE_FULL_01',
                'A_M_Y_STWHI_01_WHITE_MINI_01', 'A_M_Y_STWHI_02_WHITE_FULL_01',
                'A_M_Y_STWHI_02_WHITE_MINI_01',
                'A_M_Y_SUNBATHE_01_WHITE_FULL_01',
                'A_M_Y_SUNBATHE_01_WHITE_MINI_01',
                'A_M_Y_VINEWOOD_02_WHITE_FULL_01',
                'A_M_Y_VINEWOOD_02_WHITE_MINI_01',
                'A_M_Y_VINEWOOD_03_WHITE_FULL_01',
                'A_M_Y_VINEWOOD_03_WHITE_MINI_01',
                'A_M_Y_VINEWOOD_04_WHITE_FULL_01',
                'A_M_Y_VINEWOOD_04_WHITE_MINI_01', 'AMMUCITY', 'ANDY_MOON',
                'AVI'
            },
            TOURIST = {'A_M_M_TOURIST_01_WHITE_MINI_01'},
            INDIAN = {'A_M_M_INDIAN_01_INDIAN_MINI_01'},
            KOREAN = {
                'A_M_M_KTOWN_01_KOREAN_FULL_01',
                'A_M_M_KTOWN_01_KOREAN_MINI_01',
                'A_M_Y_EPSILON_01_KOREAN_FULL_01',
                'A_M_Y_KTOWN_01_KOREAN_FULL_01',
                'A_M_Y_KTOWN_01_KOREAN_MINI_01',
                'A_M_Y_KTOWN_02_KOREAN_FULL_01', 'A_M_Y_KTOWN_02_KOREAN_MINI_01'
            },
            CHINESE = {
                'A_M_Y_BEACH_01_CHINESE_FULL_01',
                'A_M_Y_BEACH_01_CHINESE_MINI_01',
                'A_M_Y_BEACHVESP_01_CHINESE_FULL_01',
                'A_M_Y_BEACHVESP_01_CHINESE_MINI_01',
                'A_M_Y_BUSINESS_01_CHINESE_FULL_01',
                'A_M_Y_GENSTREET_01_CHINESE_FULL_01',
                'A_M_Y_GENSTREET_01_CHINESE_MINI_01',
                'A_M_Y_MUSCLBEAC_02_CHINESE_FULL_01'
            }
        }
    }
    SetAmbientVoiceName(ped, speech[gender][origin][math.random(
                            #speech[gender][origin])])
    return true
end

-- function ActivateWarpInTouch()
--     -- fun warping :)
--     Citizen.CreateThread(function()
--         local PlayerId = PlayerId()
--         local PlayerPedId = PlayerPedId()
--         local PlayerCoord
--         local Warped = false
--         local since
--         while true do
--             Wait(500)
--             since = GetTimeSincePlayerHitVehicle(PlayerId)
--             if since <= 200 then
--                 PlayerCoord = GetEntityCoords(PlayerPedId)
--                 local vehicle = GetClosestVehicle(PlayerCoord.x, PlayerCoord.y,
--                                                   PlayerCoord.z, 4.0, 0, 70)
--                 if Warped == false then
--                     Warped = true
--                     TaskWarpPedIntoVehicle(PlayerPedId, vehicle, -1)
--                     Wait(500)
--                     -- local temp_ped = CreatePedInsideVehicle(vehicle, 2, GetHashKey('g_m_y_mexgoon_03'), 0, true, true)
--                     -- giveWeaponToPed(temp_ped, 'weapon_smg')
--                     -- AttackTargetedPed(temp_ped, PlayerId)
--                 end
--             end
--             Warped = false
--         end
--     end)
-- end

-- male : A_M_M_POLYNESIAN_01_POLYNESIAN_FULL_01
-- A_M_M_POLYNESIAN_01_POLYNESIAN_MINI_01
-- A_M_Y_POLYNESIAN_01_POLYNESIAN_FULL_01 
-- AIRCRAFT_WARNING_FEMALE_01
-- AIRCRAFT_WARNING_MALE_01
