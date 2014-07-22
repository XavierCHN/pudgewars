------------------------------------------------------------------------------------------------------------
-- REGION: INIT HOOK PARAMETERS
------------------------------------------------------------------------------------------------------------
-- LUA FUNCTION CONSTANTS
WORLDMAX_VEC = Vector(GetWorldMaxX(),GetWorldMaxY(),0)
PER_HOOK_BODY_LENGTH = 80
HEAD_SHOT_SCORE = 3
DENY_SCORE = 2
HOOK_KILL_SCORE = 1
MAX_SCORE = 100
tnHookDamage  = {175 , 250 , 350 , 500  }
tnHookLength  = {1400 , 1500 , 1600 , 1800 }
tnHookRadius  = {80  , 120  , 150  , 200   }
tnHookSpeed   = {0.17 , 0.22 , 0.27 , 0.35  }
tnUpgradeHookDamageCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookLengthCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookRadiusCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookSpeedCost  = {500 , 1000 , 1500 , 2000  }
tnHookTypeString = {
    [1] = "npc_dota2x_pudgewars_unit_pudgehook_lv1",    -- normal hook
    [2] = "npc_dota2x_pudgewars_unit_pudgehook_lv2",    -- black death hook
    [3] = "npc_dota2x_pudgewars_unit_pudgehook_lv3",    -- whale hook
    [4] = "npc_dota2x_pudgewars_unit_pudgehook_lv4"     -- skelton hook
}
tnHookParticleString = {
    [1] = "invoker_quas_orb",
    [2] = "invoker_wex_orb",
    [3] = "invoker_exort_orb"
}
tPossibleHookTargetName = {
    "npc_dota_hero_pudge",
    "npc_dota2x_pudgewars_chest",
    "npc_dota_neutral_blue_dragonspawn_overseer",
    "npc_dota2x_pudgewars_gold",
    "npc_dota_necronomicon_warrior_2",
    "npc_dota_warlock_golem_3",
    "npc_dota2x_pudgewars_unit_bomb"
}
------------------------------------------------------------------------------------------------------------
-- init hook parameters
function initHookData()
    tbPlayerFinishedHook = {}
    tbPlayerHookingBack  = {}
    tbPlayerHooking      = {}
    tnPlayerHookDamage   = {}
    tnPlayerHookLength   = {}
    tnPlayerHookRadius   = {}
    tnPlayerHookSpeed    = {}
    tnPlayerHookType     = {}
    tnPlayerHookBDType   = {}
    tvPlayerPudgeLastPos = {}
    tnPlayerHookType     = {}
    tnPlayerKillStreak   = {}
    tbHookByAlly         = {}
    tnHookTurbineBonusDamage = {}
    tbBarrierBonusDamageTriggered = {}
    tuBombPlanter = {}
    tHookElements = tHookElements or {}
    for i = 0,9 do
        tHookElements[i] = {
            Head = {unit = nil , paIndex = nil },
            Body = {},
            Target = nil,
            CurrentLength = nil
        }
        tnPlayerHookType[i] = tnHookTypeString[1]
        tnPlayerHookBDType[i] = tnHookParticleString[1]
        tnPlayerHookRadius[i] = 80
        tnPlayerHookLength[i] = 1400
        tnPlayerHookSpeed[i] = 0.2
        tnPlayerHookDamage[i] = 175
        tnHookTurbineBonusDamage[i] = 0
    end
    print("[pudgewars] finish init hook data")
end
------------------------------------------------------------------------------------------------------------
-- return the distance of vector a and vector b
local function distance(a, b)
    local xx = (a.x-b.x)
    local yy = (a.y-b.y)
    return math.sqrt(xx*xx + yy*yy)
end
local function GetHookType(nPlayerID)
    --define the hook model according to player kill streak
    local killStreak = PlayerResource:GetStreak(nPlayerID)
    local hookType
    if killStreak then  
        if killStreak < 2 then
            hookType = tnHookTypeString[1]
        elseif killStreak < 4 then
            hookType = tnHookTypeString[2]
        elseif killStreak <6 then
            hookType = tnHookTypeString[3]
        else
            hookType = tnHookTypeString[4]
        end
    else
        hookType = tnHookTypeString[1]
    end
    return hookType
end
------------------------------------------------------------------------------------------------------------
-- ENDREGION: INIT HOOK PARAMETERS
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- REGION HOOK START FUNCTIONS
------------------------------------------------------------------------------------------------------------
-- init single hook parameters
local function InitHookParameters(nPlayerID)
    -- set player is not hooking
    tbPlayerHooking[nPlayerID] = false
    -- set player not finished the hook yet
    tbPlayerFinishedHook[nPlayerID] = false
    -- set the player not hooking back
    tbPlayerHookingBack[nPlayerID] = false
    -- reset the hook target
    tHookElements[nPlayerID].Target = nil
    -- reset the hook length
    tHookElements[nPlayerID].CurrentLength = nil
    -- reset item turbine bonus damage
    tnHookTurbineBonusDamage[nPlayerID] = 0
end
------------------------------------------------------------------------------------------------------------
-- create hook head
local function CreateHookHeadForPlayer(nPlayerID , hero , heroPosition , headCreatedPosition)
    print("createing hook head")
    -- create the head unit
    local uHead = CreateUnitByName(
         GetHookType(nPlayerID)
        ,headCreatedPosition
        ,false,hero,hero,hero:GetTeam()
    )
    if uHead then
        print("head created")
        -- emit sound
        uHead:EmitSound("Hero_Pudge.AttackHookExtend")
        -- set the head model scale to the hook radius
        uHead:SetModelScale((tnPlayerHookRadius[nPlayerID]/80)*0.8,0)
        -- set head forward vector
        local diffVec = headCreatedPosition - heroPosition
        diffVec.z = 0
        if headCreatedPosition == heroPosition then diffVec = hero:GetForwardVector() end
        uHead:SetForwardVector(diffVec:Normalized())
    end
    return uHead
end
------------------------------------------------------------------------------------------------------------
-- create the hook chain
local function CreateHookChainForPlayer( nPlayerID , hero , Origin , headPosition )
    local nFXIndex = ParticleManager:CreateParticle("wisp_tether",PATTACH_CUSTOMORIGIN,hero)
    ParticleManager:SetParticleControl(nFXIndex,0,Origin)
    ParticleManager:SetParticleControl(nFXIndex,1,headPosition)
    return nFXIndex
end
------------------------------------------------------------------------------------------------------------
-- on ability hook start
function OnHookStart(keys)
    print("hook start called")
    local targetPoint = keys.target_points[1]
    local caster = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = keys.unit:GetPlayerID()

    -- if there is already a hook, return
    if tHookElements[nPlayerID].Head.unit ~= nil then return end
    
    -- init hook parameters
    InitHookParameters(nPlayerID)

    -- create the hook head for player
    local uHead = CreateHookHeadForPlayer(nPlayerID , caster , caster:GetOrigin() , caster:GetOrigin() )
    tHookElements[nPlayerID].Head.unit = uHead

    -- create hook chain particle effect
    local nFXIndex = CreateHookChainForPlayer(nPlayerID , caster , caster:GetOrigin() , uHead:GetOrigin() )
    tHookElements[nPlayerID].Head.index = nFXIndex
end
------------------------------------------------------------------------------------------------------------
-- on set hook start
function OnHookSet(keys)
    local targetPoint = keys.target_points[1]
    local caster = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = keys.unit:GetPlayerID()

    -- if there is a hook already, return
    if tHookElements[nPlayerID].Head.unit ~= nil then return end

    -- init hook parameters
    InitHookParameters(nPlayerID)
    
    -- create the hook head for player
    local uHead = CreateHookHeadForPlayer(nPlayerID , caster , targetPoint , targetPoint )
    tHookElements[nPlayerID].Head.unit = uHead

    -- create hook chain particle effect
    local nFXIndex = CreateHookChainForPlayer(nPlayerID , caster , caster:GetOrigin() , uHead:GetOrigin() )
    tHookElements[nPlayerID].Head.index = nFXIndex

    --remove the set ability and add release ability
    caster:RemoveAbility("ability_pudgewars_set_hook")
    caster:AddAbility("ability_pudgewars_release_hook")
    ABILITY_RELEASE_HOOK = caster:FindAbilityByName("ability_pudgewars_release_hook")
    ABILITY_RELEASE_HOOK:SetLevel(1)
end
------------------------------------------------------------------------------------------------------------
-- On outter hook setting hook direction to the caster direction
function OnSettingHookDirection(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()
    local casterFV = caster:GetForwardVector()
    local head = tHookElements[nPlayerID].Head.unit
    head:SetForwardVector(casterFV)
end
------------------------------------------------------------------------------------------------------------
-- set the head forward vector and release it
function OnSetOutterHookDirection(keys)
    local nPlayerID = caster:GetPlayerID()
    local head = tHookElements[nPlayerID].Head.unit
    local targetPoint = keys.target_points[1]
    
    local diffVec = targetPoint - head:GetOrigin()
    head:SetForwardVector(diffVec:Normalized())
end
------------------------------------------------------------------------------------------------------------
-- if timeup then the hook disappear
function OnSettingHookDirectionTimeUp(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()
    local head = tHookElements[nPlayerID].Head.unit
    local headpa = tHookElements[nPlayerID].Head.index
    local ABILITY_SETTING_HOOK_DIRECTION = caster:FindAbilityByName("ability_pudgewars_release_hook")

    if not tbPlayerHooking[nPlayerID] then
        head:Remove()
        ParticleManager:SetParticleControl(headpa,0,WORLDMAX_VEC)
        ParticleManager:ReleaseParticleIndex(headpa)
    end

    -- reset hook parameters
    InitHookParameters(nPlayerID)

    --reset the ability
    if ABILITY_SETTING_HOOK_DIRECTION then
        caster:RemoveAbility("ability_pudgewars_release_hook")
        caster:AddAbility("ability_pudgewars_hook")
        if caster:HasModifier("pudgewars_setting_hook") then
            caster:RemoveModifierByName("pudgewars_setting_hook")
        end
        local ABILITY_HOOK = caster:FindAbilityByName("ability_pudgewars_hook")
        if ABILITY_HOOK then ABILITY_HOOK:SetLevel(1) end
    end
end
------------------------------------------------------------------------------------------------------------
-- ENDREGION HOOK START FUNCTIONS
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- REGION RELEASING HOOK
------------------------------------------------------------------------------------------------------------
-- if a barrier found, think about hook direction turn and damage increasement
local function ThinkAboutBarriers(caster , head , wall , plyid )
    local headFV = head:GetForwardVector()
    local wallFV = wall:GetForwardVector()
    local wallOrigin = wall:GetOrigin()
    local wallFVP = wallOrigin + wallFV
    local wallAngleLeft = QAngle( 0, -90, 0 )
    local wallAngleRight = QAngle( 0, 90, 0 )
    local vLeft = RotatePosition( wallOrigin, wallAngleLeft, wallFVP )
    local vRight = RotatePosition( wallOrigin, wallAngleRight, wallFVP )

    local leftFV = (vLeft - wallOrigin):Normalized()
    local rightFV = (vRight - wallOrigin):Normalized()

    local x1 = leftFV.x
    local y1 = leftFV.y
    local x2 = rightFV.x
    local y2 = rightFV.y
    local x = headFV.x
    local y = headFV.y

    local angleLeft = math.acos( (x*x1 + y*y1) / ( math.sqrt(x*x + x1*x1) + math.sqrt(y*y + y1*y1) ) )
    angleLeft = angleLeft * 180 / 3.14
    local angleRight = math.acos( (x*x2 + y*y2) / ( math.sqrt(x*x + x2*x2) + math.sqrt(y*y + y2*y2) ) )
    angleRight = angleRight * 180 / 3.14

    if angleLeft > 10 and angleRight > 10 then
        local nearEnough = false
        for i = 1,3 do
            local pointLeft = Vector( wallOrigin.x + 20 * leftFV.x * i , wallOrigin.y + 20 * leftFV.y * i , 0)
            local pointRight = Vector( wallOrigin.x + 20 * rightFV.x * i , wallOrigin.y + 20 * rightFV.y * i , 0)

            if distance(pointLeft , head:GetOrigin()) < 30 
                or distance(pointRight , head:GetOrigin()) < 30 
            then
                nearEnough = true
            end
        end
        if nearEnough then
            local resFV = nil
            if angleLeft > angleRight then
                resFV = rightFV
            else
                resFV = leftFV
            end
            head:SetForwardVector(resFV)
            if not tbBarrierBonusDamageTriggered[wall][plyid] then
                local itemTurbine = ItemThinker:FindItemFuzzy(caster,"item_pudge_ricochet_turbine")
                if itemTurbine then
                    local itemLevel = string.sub(itemTurbine,-1,-1)
                    print("ITEAM RICOCHET TURBINE FOUND LEVEL:"..itemLevel)
                    --100 150 200 250 300
                    local bonusDmg = 50 + 50 * tonumber(itemLevel)
                    print("add turbine bonus damage for player id:"..tostring(plyid))
                    tnHookTurbineBonusDamage[plyid] = tnHookTurbineBonusDamage[plyid] + bonusDmg
                    tbBarrierBonusDamageTriggered[wall][plyid] = true
                end
            end
        end
    end
end
------------------------------------------------------------------------------------------------------------
-- catch the hook unit
local function GetHookedUnit(caster , head , plyid)
    -- search units around the head
    local tuHookedUnits = nil
    tuHookedUnits = FindUnitsInRadius(
        caster:GetTeam(),       --caster team
        head:GetOrigin(),       --find position
        nil,                    --find entity
        350,                    --find radius
        DOTA_UNIT_TARGET_TEAM_BOTH,
        DOTA_UNIT_TARGET_ALL,
        0, FIND_CLOSEST,
        false
    )
    -- remove all useless untis
    if #tuHookedUnits >= 1 then
        for k,v in pairs(tuHookedUnits) do

            --think about barriers
            if v:GetUnitName() == "npc_pudge_wars_barrier" then
                ThinkAboutBarriers( caster , head , v , plyid )
            end
            local va = false
            for s,t in pairs (tPossibleHookTargetName) do
                if v:GetUnitName() == t then
                    va = true
                    -- think about unit bomb
                    if t == "npc_dota2x_pudgewars_unit_bomb" and tuBombPlanter[v] == head then
                        print("catch a bomb but its created by this head, ignore")
                        va = false
                    elseif t == "npc_dota2x_pudgewars_unit_bomb" and tuBombPlanter[v] ~= head then
                        print("bomb not created by this head,catch it")
                    end
                end
            end
            if ( not va ) or ( v == caster )  or
                -- if unit  is in hook radius
                distance (head:GetOrigin(),v:GetOrigin()) > tnPlayerHookRadius[plyid]
                then
                tuHookedUnits[k] = nil
            end
        end
    end
    -- if there is units left then catch it
    for k,v in pairs(tuHookedUnits) do
        if v ~= nil then
            -- return the hook unit
            return v
        end
    end
    -- got nothing, return nil
    return nil
end
------------------------------------------------------------------------------------------------------------
-- a function to deal lasthit
local function DealLastHit( caster , target )
    local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", 
        target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
    dummy:SetOwner(caster)
    --if dummy then print("unit created") end
    dummy:AddAbility("ability_deal_the_last_hit")
    local ABILITY_LAST_HIT = dummy:FindAbilityByName("ability_deal_the_last_hit")
    ABILITY_LAST_HIT:SetLevel(1)
    dummy:CastAbilityOnTarget(target, ABILITY_LAST_HIT, 0 )

    PudgeWarsGameMode:CreateTimer("last_hit"..tostring(dummy)..tostring(GameRules:GetGameTime()),{
        endTime = Time()+ 0.1,
        callback = function()
            --print("removing dummy unit")
            if IsValidEntity(dummy) then dummy:Destroy() end
            if target:IsAlive() then
                print("WARNING! THE UNIT IS STILL ALIVE")
            end
        end
    })
end
------------------------------------------------------------------------------------------------------------
-- apply hook modifier
local function ApplyHookModifier(caster , target)
    local casterOrigin = caster:GetOrigin()
    local uOrigin = target:GetOrigin()
    local time = GameRules:GetGameTime()
    local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
    dummy:AddAbility("ability_dota2x_pudgewars_hook_applier")
    local ABILITY_HOOK_APPLIER = dummy:FindAbilityByName("ability_dota2x_pudgewars_hook_applier")
    ABILITY_HOOK_APPLIER:SetLevel(1)
    dummy:CastAbilityOnTarget(target, ABILITY_HOOK_APPLIER, 0 )
    PudgeWarsGameMode:CreateTimer("remove_hook_dummy"..tostring(dummy),{
        endTime = Time() + 0.1,
        callback = function()
            if IsValidEntity(dummy) then dummy:Destroy() end
        end
    })
end
------------------------------------------------------------------------------------------------------------
-- a function to do head shot and deny - triggered if a unit is hooked while hooking by another player
local function HeadShotnDeny(caster , target)
    -- head shot
    if target:GetTeam() ~= caster:GetTeam() then
        DealLastHit(caster,target)
        local msg = {
            message = "#pudgewars_head_shot",
            duration = 1
        }
        FireGameEvent('show_center_message',msg)
        AddScore(caster:GetTeam(),HEAD_SHOT_SCORE)
        caster:EmitSound("PudgeWars.Head.Shot")
        return
    end
    -- deny by a teamate
    if target:GetTeam() == caster:GetTeam() and not tbHookByAlly[target]  then
        DealLastHit(caster,target)
        local msg = {
            message = "#pudgewars_denied",
            duration = 1
            }
        FireGameEvent('show_center_message',msg)
        --print("team:"..tostring(caster:GetTeam()))
        AddScore(caster:GetTeam(),DENY_SCORE)
        return
    end
end
------------------------------------------------------------------------------------------------------------
-- function to deal damage when hook a unit
local function DealDamage(plyid , caster , target)
    local nDamageToDeal = tnPlayerHookDamage[plyid]

    -- think about barathon's latern item
    local itemLatern = ItemThinker:FindItemFuzzy(caster,"item_pudge_barathrum_lantern")
    if itemLatren then
        local itemLevel = string.sub(itemLatern,-1,-1)
        bonusdamage = (tonumber(itemLevel) * 5 + 10 / 100) * nDamageToDeal
        target:EmitSound("Hero_Spirit_Breaker.GreaterBash")
    end
    nDamageToDeal = nDamageToDeal + bonusdamage

    if tnHookTurbineBonusDamage[plyid] then
        nDamageToDeal = nDamageToDeal + tnHookTurbineBonusDamage[plyid]
    end

    -- deal the damage
    if nDamageToDeal < target:GetHealth() then
        target:SetHealth(target:GetHealth() - nDamageToDeal)
    else
        DealLastHit(caster,target)
        AddScore(caster:GetTeam(),HOOK_KILL_SCORE)
    end

    return nDamageToDeal
end
------------------------------------------------------------------------------------------------------------
-- deal item blood seeker's claw modifier
local function ApplyItemBloodModifier(caster , target , itemBlood)
    local itemLevel = string.sub(itemBlood,-1,-1)
    local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
    dummy:AddAbility("ability_dota2x_pudgewars_bloodsekker_claw")
    local ABILITY_BLOOD_APPLIER = dummy:FindAbilityByName("ability_dota2x_pudgewars_bloodsekker_claw")
    ABILITY_BLOOD_APPLIER:SetLevel(tonumber(itemLevel))
    dummy:CastAbilityOnTarget(target, ABILITY_BLOOD_APPLIER, 0 )
    PudgeWarsGameMode:CreateTimer("blood_claw_dealer_"..tostring(caster)..tostring(GameRules:GetGameTime()),
    {
        endTime = Time()+ 0.1,
        callback = function()
            if IsValidEntity(dummy) then dummy:Destroy() end
        end
    })
end
------------------------------------------------------------------------------------------------------------
-- get health if the caster has item naix's jaw
local function ApplyItemNaixJawModifier(caster , nDamageDealed , itemJaw)
    local index = ParticleManager:CreateParticle("life_stealer_infest_emerge_clean_lights_LV",PATTACH_CUSTOMORIGIN,caster)
    ParticleManager:SetParticleControl(index,0,caster:GetOrigin() + Vector(0,0,150))
    ParticleManager:ReleaseParticleIndex(index)
    
    local itemLevel = string.sub(itemJaw,-1,-1)
    local lifestealPercent = (tonumber(itemLevel) * 5 + 5) / 100
    caster:SetHealth(caster:GetHealth() + nDamageDealed * lifestealPercent)
end

local function ApplyHookModifier(caster,target)
    local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
    dummy:AddAbility("ability_dota2x_pudgewars_hook_applier")
    local ABILITY_HOOK_APPLIER = dummy:FindAbilityByName("ability_dota2x_pudgewars_hook_applier")
    ABILITY_HOOK_APPLIER:SetLevel(1)
    -- hook the target, this ability has no damage
    dummy:CastAbilityOnTarget(target, ABILITY_HOOK_APPLIER, 0 )
        
        -- timer to remove unit
    PudgeWarsGameMode:CreateTimer("hook_modifier_applier"..tostring(caster)..tostring(GameRules:GetGameTime()),
    {
        endTime = Time()+ 0.1,
            callback = function()
            if IsValidEntity(dummy) then dummy:Destroy() end
        end
    })
end
------------------------------------------------------------------------------------------------------------
-- create a dummt to catch the unit
local function HookUnit( target , caster ,plyid )
    target:EmitSound("Hero_Pudge.AttackHookImpact")
    ApplyHookModifier(caster,target)
    --if the unit is already hooked by someone
    if target:HasModifier("modifier_pudgewars_hooked") then
        -- think about headshot and deny
        HeadShotnDeny(caster,target)
    else
        -- if target is an enemy, deal damage and apply item blood seeker's claw modifier
        if target:GetTeam() ~= caster:GetTeam() then
            -- deal damage and apply item modifiers
            local nDamageDealed = DealDamage(plyid,caster,target)
            
            if target:IsAlive() then
                -- think about item blood seeker's claw
                local itemBlood = ItemThinker:FindItemFuzzy(caster,"item_pudge_bloodseeker_claw")
                if itemBlood then
                    ApplyItemBloodModifier(caster,target,itemBlood)
                end
                -- think about item naix's jaw
                local itemJaw = ItemThinker:FindItemFuzzy(caster,"item_pudge_naix_jaw")
                if itemJaw then
                    ApplyItemNaixJawModifier(caster,nDamageDealed,itemJaw)
                end
            end
        end
        
        if target:GetTeam() == caster:GetTeam() then
            tbHookByAlly[target] = true
        else
            tbHookByAlly[target] = false
        end
    end
end
------------------------------------------------------------------------------------------------------------
-- when forwarding the hook head unit, set its position and forward vector
local function SetForwardingHookHeadPosition(caster , uHead , nPlayerID)
    if tvPlayerPudgeLastPos[nPlayerID] == nil then tvPlayerPudgeLastPos[nPlayerID] = caster:GetOrigin() end
    local diffVec = caster:GetOrigin() - tvPlayerPudgeLastPos[nPlayerID]

    local headFV = uHead:GetForwardVector()
    local headOrigin = uHead:GetOrigin()
    if headFV.x == 0 and headFV.y == 0 then
        print("WARNING: HOOK HEAD IS NOT MOVING")
        say(nil," =>致命错误:钩子朝向错误，取消错误的钩子释放...",false)
        tbPlayerHookingBack[nPlayerID] = true
        return
    end
    if tHookElements[nPlayerID].CurrentLength < 30 then diffVec = Vector(0,0,0) end
    local vec3 = Vector(
        headOrigin.x + diffVec.x/20 + headFV.x * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
       ,headOrigin.y + diffVec.y/20 + headFV.y * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
       ,headOrigin.z
    )
    
    -- set the hook head position and turn the hook forward vector to next position
    diffVec = vec3 - uHead:GetOrigin()
    uHead:SetOrigin(vec3)
    uHead:SetForwardVector(diffVec:Normalized())

    -- store the last position of pudge
    tvPlayerPudgeLastPos[nPlayerID] = caster:GetOrigin()
end
------------------------------------------------------------------------------------------------------------
-- when taking the hook head unit back, set its position and forward vector
local function SetBackingHookHeadPosition(caster , uHead , nPlayerID)
    if tvPlayerPudgeLastPos[nPlayerID] == nil then tvPlayerPudgeLastPos[nPlayerID] = caster:GetOrigin() end
    local headOrigin = uHead:GetOrigin()
    local diffFV =  (headOrigin - caster:GetOrigin()):Normalized()
    local vec3 = Vector(
        headOrigin.x - diffFV.x * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
       ,headOrigin.y - diffFV.y * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
       ,headOrigin.z
    )
    
    -- set the hook head position and turn the hook forward vector to next position
    uHead:SetOrigin(vec3)
    uHead:SetForwardVector(diffFV)
end
------------------------------------------------------------------------------------------------------------
-- TODO function to refresh the hook chain particle effect
local function RefreshHookChainParticleEffect(caster , uHead , nChainFXIndex)
    local headOrigin = uHead:GetOrigin()
    local casterOrigin = caster:GetOrigin()
    headOrigin.z = headOrigin.z + 150
    casterOrigin.z = casterOrigin.z + 150
    ParticleManager:SetParticleControl(nChainFXIndex,0,headOrigin)
    ParticleManager:SetParticleControl(nChainFXIndex,1,casterOrigin)
end
------------------------------------------------------------------------------------------------------------
-- increase the length of the hook while releasing the hook
local function LongerTheHook(caster , uHead , nChainFXIndex , nPlayerID)
    if tbPlayerHookingBack[nPlayerID] then return end
    if tHookElements[nPlayerID].CurrentLength == nil then 
        tHookElements[nPlayerID].CurrentLength = 2 
    else 
        tHookElements[nPlayerID].CurrentLength = tHookElements[nPlayerID].CurrentLength + 1 
    end
    if tHookElements[nPlayerID].CurrentLength * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID] > tnPlayerHookLength[nPlayerID] then
        tbPlayerHookingBack[nPlayerID] = true
        return
    end
    SetForwardingHookHeadPosition(caster,uHead,nPlayerID)
    RefreshHookChainParticleEffect(caster,uHead,nChainFXIndex)
end
------------------------------------------------------------------------------------------------------------
-- tack the hook head back and refresh the hook chain particle effect
local function TackBackHook(caster , uHead , nChainFXIndex , nPlayerID)
    SetBackingHookHeadPosition(caster,uHead,nPlayerID)
    RefreshHookChainParticleEffect(caster,uHead,nChainFXIndex)
end
------------------------------------------------------------------------------------------------------------
-- main function of releasing hook
function OnReleaseHook( keys )
    print("function on realease hook called")
    local caster = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()
    
    if not tbPlayerFinishedHook[nPlayerID] then
        tbPlayerHooking[nPlayerID] = true

        -- ensure the hook head exists
        if tHookElements[nPlayerID] == nil then print("hook elements not found returning") return end
        local uHead = tHookElements[nPlayerID].Head.unit
        if not IsValidEntity(uHead) then print("not a valid entity") return end
        local headOrigin = uHead:GetOrigin()
        local paHead = tHookElements[nPlayerID].Head.index
        local headFV = uHead:GetForwardVector()
        
        -- clear outter hook modifiers and ability
        local ABILITY_RELEASE_HOOK = caster:FindAbilityByName("ability_pudgewars_release_hook")
        if ABILITY_RELEASE_HOOK then
            caster:RemoveAbility("ability_pudgewars_release_hook")
            caster:AddAbility("ability_pudgewars_hook")
            local ABILITY_HOOK = caster:FindAbilityByName("ability_pudgewars_hook")
            if ABILITY_HOOK then ABILITY_HOOK:SetLevel(1) end
        end

        if caster:HasModifier( "pudgewars_setting_hook" ) then caster:RemoveModifierByName("pudgewars_setting_hook") end

        
        if not tbPlayerHookingBack[nPlayerID] then
            -- longer the hook chain
            LongerTheHook(caster,uHead,paHead,nPlayerID)
             -- search for the target
            tHookElements[nPlayerID].Target = GetHookedUnit(caster , uHead , nPlayerID)
        end

        -- if success then hook the unit
        if tHookElements[nPlayerID].Target then
            tbPlayerHookingBack[nPlayerID]  = true
            HookUnit( tHookElements[nPlayerID].Target , caster ,nPlayerID)
            return
        end

        -- if we are hooking back, then take the hook head back
        if tbPlayerHookingBack[nPlayerID] then 
            TackBackHook(caster,uHead,paHead,nPlayerID)
        end

        -- if hooked any target then take it back
        if tHookElements[nPlayerID].Target then 
            tHookElements[nPlayerID].Target:SetOrigin(uHead:GetOrigin())
        end

        -- if reachs end
        if tbPlayerHookingBack[nPlayerID] and distance(uHead:GetOrigin(),caster:GetOrigin()) < 70 then
            -- if there is any target and its alive then remove hooked modifier
            if tHookElements[nPlayerID].Target ~= nil then
                if tHookElements[nPlayerID].Target:IsAlive() then
                    -- to prevent from got stacked with any unit
                    tHookElements[nPlayerID].Target:AddNewModifier(tHookElements[nPlayerID].Target,nil,"modifier_phased",{})
                    tHookElements[nPlayerID].Target:RemoveModifierByName("modifier_phased")
                        
                    --remove the hooked modifier
                    tHookElements[nPlayerID].Target:RemoveModifierByName( "modifier_pudgewars_hooked" )
                end
            end

            -- init hook parameters and release hook head trail particle
            hooked = false

            tHookElements[nPlayerID].CurrentLength = nil
            tHookElements[nPlayerID].Head.unit = nil
            uHead:Remove()
            local casterOrigin = caster:GetOrigin()
            casterOrigin.z = casterOrigin.z - 550
            ParticleManager:SetParticleControl(paHead,0,casterOrigin)
            ParticleManager:SetParticleControl(paHead,1,casterOrigin)


            tHookElements[nPlayerID].Target = nil
            tbPlayerFinishedHook[nPlayerID] = true
            tvPlayerPudgeLastPos[nPlayerID] = nil
            if caster:HasModifier("modifier_pudgewars_pudgemeathook_think_interval") then
                caster:RemoveModifierByName("modifier_pudgewars_pudgemeathook_think_interval")
            end
            if caster:HasModifier("modifier_pudgewars_hook_think_interval") then
                caster:RemoveModifierByName("modifier_pudgewars_hook_think_interval")
            end
        end
    end 
end
------------------------------------------------------------------------------------------------------------
-- ENDREGION RELEASING HOOK
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- REGION: HERO ABILITY HOOKS
------------------------------------------------------------------------------------------------------------
function OnUpgradeHookDamage(keys)
    --print("upgrading damage")
    --PrintTable(keys)
    local caster    = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()

    local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_damage")
    local nCurrentLevel = hHookAbility:GetLevel()
    local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
    local nCurrentGold  = PlayerResource:GetGold(nPlayerID)
    if nCurrentLevel >= 4 then
        caster:Stop()
        Say(caster:GetOwner()," =>伤害已经达到最大等级。",true)
        return
    end

    -- if the player has not enough gold then stop him from channeling
    if nUpgradeCost > nCurrentGold then
        caster:Stop()
        Say(caster:GetOwner()," =>金钱不足，升级钩子伤害失败！",true)
    end
end
------------------------------------------------------------------------------------------------------------
function OnUpgradeHookRadius( keys )
    --print("upgrading radius")

    --PrintTable(keys)
    local caster    = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()
    
    local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_radius")
    local nCurrentLevel = hHookAbility:GetLevel()
    local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]
    local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

    if nCurrentLevel >= 4 then
        caster:Stop()
        Say(caster:GetOwner()," =>范围已经达到最大等级。",true)
        return
    end

    -- if the player has not enough gold then stop him from channeling
    if nUpgradeCost > nCurrentGold then
        caster:Stop()
        Say(caster:GetOwner()," =>金钱不足，升级钩子范围失败！",true)
    end
end
------------------------------------------------------------------------------------------------------------
function OnUpgradeHookLength( keys )
    --print("upgrading length")

    --PrintTable(keys)
    local caster    = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()

    local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_length")
    local nCurrentLevel = hHookAbility:GetLevel()
    local nUpgradeCost  = tnUpgradeHookLengthCost[nCurrentLevel]
    local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

    if nCurrentLevel >= 4 then
        caster:Stop()
        Say(caster:GetOwner()," =>长度已经达到最大等级。",true)
        return
    end

    -- if the player has not enough gold then stop him from channeling
    if nUpgradeCost > nCurrentGold then
        caster:Stop()
        Say(caster:GetOwner()," =>金钱不足，升级钩子长度失败！",true)
    end
end
------------------------------------------------------------------------------------------------------------
function OnUpgradeHookSpeed( keys )
    --print("upgrading speed")

    --PrintTable(keys)
    local caster    = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()

    local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_speed")
    local nCurrentLevel = hHookAbility:GetLevel()
    local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]
    local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

    if nCurrentLevel >= 4 then
        caster:Stop()
        Say(caster:GetOwner()," =>速度已经达到最大等级。",true)
        return
    end

    -- if the player has not enough gold then stop him from channeling
    if nUpgradeCost > nCurrentGold then
        caster:Stop()
        Say(caster:GetOwner()," =>金钱不足，升级钩子速度失败！",true)
    end
end
------------------------------------------------------------------------------------------------------------
function OnUpgradeHookDamageFinished( keys )

    --PrintTable(keys)
    local caster    = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()

    local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_damage")
    local nCurrentLevel = hHookAbility:GetLevel()
    local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
    
    if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
        Say(caster:GetOwner()," =>金钱不足，升级钩子伤害失败",true)
    else
        -- upgrade the hook data and spend gold
        hHookAbility:SetLevel( nCurrentLevel + 1 )
        --if developmentmode then nUpgradeCost = -10000 end
        PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
        tnPlayerHookDamage[ nPlayerID ] =  tnHookDamage[ nCurrentLevel + 1 ]
    end
end
------------------------------------------------------------------------------------------------------------
function OnUpgradeHookRadiusFinished( keys )

    --PrintTable(keys)
    local caster    = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()


    local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_radius")
    local nCurrentLevel = hHookAbility:GetLevel()
    local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]
    if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
        Say(caster:GetOwner()," =>金钱不足，升级钩子范围失败！",true)
    else
        -- upgrade the hook data and spend gold
        hHookAbility:SetLevel( nCurrentLevel + 1 )
        PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
        tnPlayerHookRadius[ nPlayerID ] =  tnHookRadius[ nCurrentLevel + 1 ]
    end
end
------------------------------------------------------------------------------------------------------------
function OnUpgradeHookLengthFinished( keys )

    --PrintTable(keys)
    local caster    = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()

    local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_length")
    local nCurrentLevel = hHookAbility:GetLevel()
    local nUpgradeCost  = tnUpgradeHookLengthCost[nCurrentLevel]
    if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
        Say(caster:GetOwner()," =>金钱不足，升级钩子长度失败！",true)
    else
        -- upgrade the hook data and spend gold
        hHookAbility:SetLevel( nCurrentLevel + 1 )
        PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
        tnPlayerHookLength[ nPlayerID ] =  tnHookLength[ nCurrentLevel + 1 ]
    end
end
------------------------------------------------------------------------------------------------------------
function OnUpgradeHookSpeedFinished( keys )

    --PrintTable(keys)
    local caster    = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()

    local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_speed")
    local nCurrentLevel = hHookAbility:GetLevel()
    

    local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]
    if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
        Say(caster:GetOwner()," =>金钱不足，升级钩子速度失败！",true)
    else
        -- upgrade the hook data and spend gold
        hHookAbility:SetLevel( nCurrentLevel + 1 )
        PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
        tnPlayerHookSpeed[ nPlayerID ] =  tnHookSpeed[ nCurrentLevel + 1 ]
    end
end
------------------------------------------------------------------------------------------------------------
function OnToggleHookType( keys )
    local caster = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()

    local ABILITY_START_HOOK = caster:FindAbilityByName("ability_pudgewars_hook")
    if ABILITY_START_HOOK then
        --print("remove ability")
        caster:RemoveAbility("ability_pudgewars_hook")
        --print("add ability")
        caster:AddAbility("ability_pudgewars_set_hook")
        local ABILITY_SET_HOOK = caster:FindAbilityByName("ability_pudgewars_set_hook")
        if ABILITY_SET_HOOK then
            ABILITY_SET_HOOK:SetLevel(1)
        end
    end
end
-- ENDREGION: HERO ABILITY HOOKS
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- REGION: ITEM ABILITY HOOKS
------------------------------------------------------------------------------------------------------------
-- REGION: ITEM BOMB
function PlantABomb(keys)
    --PrintTable(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local nPlayerID = caster:GetPlayerID()
    local returnPos = nil

    if tHookElements[nPlayerID].Head.unit then
        --print("there is a head,plant bomb at head")
        returnPos = tHookElements[nPlayerID].Head.unit:GetOrigin()
    else
        returnPos = caster:GetOrigin()
    end
    local dummy =CreateUnitByName(
        "npc_dota2x_pudgewars_unit_bomb",
        returnPos,
        false,
        nil,
        nil,
        caster:GetTeam())
    dummy:AddNewModifier(unit,nil,"modifier_phased",{})
    --dummy:AddNewModifier(unit,nil,"modifier_invulnerable",{})

    dummy:AddAbility("ability_dota2x_pudgewars_hook_dummy")
    dummy:EmitSound("Hero_Techies.LandMine.Plant")

    if tHookElements[nPlayerID].Head.unit then
        tuBombPlanter[dummy] = tHookElements[nPlayerID].Head.unit
    end

    local item_bomb = ItemThinker:FindItemFuzzy(caster,"item_pudge_techies_explosive_barrel")
    if item_bomb then
        local itemLevel = string.sub(item_bomb,-1,-1)
        print("ITEM BOMB FOUND LV :"..tostring(itemLevel))
            --unit:AddAbility("ability_make_bomb_a_bomb")
        local ABILITY_BOMB = dummy:FindAbilityByName("ability_make_bomb_a_bomb")
        if ABILITY_BOMB then
            --print("bomb level set")
            ABILITY:SetLevel(tonumber(itemLevel))
        else
            print("UNIT ABILITY NOT FOUND")
        end
    else
        print("FATAL: FAILD TO FIND ITEM BOMB")
    end
end
------------------------------------------------------------------------------------------------------------
function ThinkAboutBombTriggered(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local center = caster:GetOrigin()
    local ability = caster:FindAbilityByName("ability_make_bomb_a_bomb")
    local radius = ability:GetSpecialValueFor("Radius")
    local dmg = ability:GetSpecialValueFor("bomb_damage")
    
    local triggeredUnits = nil
    triggeredUnits = FindUnitsInRadius(
        caster:GetTeam(),       --caster team
        center,     --find position
        nil,                    --find entity
        200,            --find radius
        --DOTA_UNIT_TARGET_TEAM_BOTH,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_ALL, 
        0, FIND_CLOSEST,
        false
    )
    local triggered = false
    if #triggeredUnits > 1 then
        for k,v in pairs(triggeredUnits) do
            --print("bomb_test_triggered by :"..v:GetUnitName())
            if v:GetUnitName() ~= "npc_dota_hero_pudge" then
                v = nil
                print("invcalid unit found")
            else
                triggered = true
            end
        end
    end
    if not triggered then 
        return 
    else
        for k,v in pairs(triggeredUnits) do
            if v ~= nil then
                v:EmitSound("Hero_Techies.LandMine.Detonate")
                local health = v:GetHealth()
                if dmg > health then
                    PudgeWarsGameMode:CreateTimer("bomb_last_hit"..tostring(GameRules:GetGameTime()),{
                        endTime = Time() + 0.1,
                        callback = function()
                            DealLastHit(caster,v)
                        end
                    })
                else
                    v:SetHealth(v:GetHealth() - dmg)
                end
            end
        end

        -- create boooooooooom particle effect
        local bombPos = caster:GetOrigin()
        local paindex = ParticleManager:CreateParticle("techies_land_mine_explode",PATTACH_CUSTOMORIGIN,caster)
        ParticleManager:SetParticleControl(paindex,0,bombPos)
        ParticleManager:ReleaseParticleIndex(paindex)
        -- remove the bomb
        caster:Destroy()

    end
end
------------------------------------------------------------------------------------------------------------
function OnBombSetFinished( keys )
    local caster = EntIndexToHScript(keys.caster_entindex)
    if caster then
        local sc = caster:GetModelScale()
        sc = sc * 2
        caster:SetModelScale(sc,0)
    end
end
-- ENDREGION: ITEM BOMB
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- REGION: TINY'S ARM
function OnTinyArmCast(keys)
    print("tiny arm casted")
    --PrintTable(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local target = keys.target_entities[1]
    local itemLevel = keys.Level
    print("ITEAM TINY ARM FOUND LEVEL:"..itemLevel)
    
    local ABILITY_TOSS_APPLIER = caster:FindAbilityByName("ability_dota2x_pudgewars_toss")
    --if ABILITY_BLOOD_APPLIER then print("ability_dota2x_pudgewars_bloodsekker_claw ability successful added") end
    ABILITY_TOSS_APPLIER:SetLevel(tonumber(itemLevel))
    caster:CastAbilityOnTarget(target, ABILITY_TOSS_APPLIER, 0 )

end
-- ENDREGION: TINY'S ARM
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- REGION: GRAPPLING HOOK
function OnGrapplingHook(keys)
    --PrintTable(keys)
    local point = keys.target_points[1]
    local caster = EntIndexToHScript(keys.caster_entindex)

    local itemGH = ItemThinker:FindItemFuzzy(caster,"item_pudge_grappling_hook")
    if itemGH then
        local itemLevel = string.sub(itemGH,-1,-1)
        print("ITEM GH FOUND LV :"..tostring(itemLevel))
        
        local ABILITY_GRAPPLING_HOOK = caster:FindAbilityByName("ability_pudge_wars_grappling_hook")
        if ABILITY_GRAPPLING_HOOK then
            ABILITY_GRAPPLING_HOOK:SetLevel(tonumber(itemLevel))
            caster:CastAbilityOnPosition(point,ABILITY_GRAPPLING_HOOK,0)
        end
    end
end
-- ENDREGION: GRAPPLING HOOK
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- REGION: BARRIER
function OnBarrierBuilt(keys)
    --PrintTable(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local casterOrigin = caster:GetOrigin()
    local barrier = keys.target_entities[1]
    local diffVec = barrier:GetOrigin() - casterOrigin
    barrier:SetForwardVector(diffVec:Normalized())
    print("regist barrier :"..tostring(barrier))
    tbBarrierBonusDamageTriggered[barrier] = {}
    for i = 0,9 do
        tbBarrierBonusDamageTriggered[barrier][i] = false
    end
end
-- ENDREGION: BARRIER
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- REGION: TEST FUNCTIONS
------------------------------------------------------------------------------------------------------------
-- function to spawn test units
function spawnTestUnit(withmodifier,team)
    PudgeWarsGameMode:CreateTimer("Create_Test_units",{
        endTime = Time()+ 0.1,
        callback = function ()
            if developmentmode then
                local testUnitTable = {
                    "npc_dota_neutral_blue_dragonspawn_overseer"
                    ,"npc_dota_necronomicon_warrior_2"
                    ,"npc_dota_warlock_golem_3"
                    ,"npc_dota_neutral_blue_dragonspawn_overseer"
                    ,"npc_dota_necronomicon_warrior_2"
                    ,"npc_dota_warlock_golem_3"

                }
                for k,v in pairs(testUnitTable) do
                    table.insert( tPossibleHookTargetName , #tPossibleHookTargetName + 1 ,v)
                    
                    local caster = CreateUnitByName(
                        v,
                        Vector(-1500,-800,0) + RandomVector(400),
                        false,
                        nil,
                        nil,
                        team)
                    if withmodifier then
                        local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", 
                            caster:GetAbsOrigin(), false, caster, caster, team)
                        if dummy then print("test dummy unit created") end
                        dummy:AddAbility("ability_dota2x_pudgewars_hook_applier")
                        local ABILITY_HOOK_APPLIER = dummy:FindAbilityByName("ability_dota2x_pudgewars_hook_applier")
                        if ABILITY_HOOK_APPLIER then print("ability successful added") end
                        ABILITY_HOOK_APPLIER:SetLevel(1)
        
                        dummy:CastAbilityOnTarget(caster, ABILITY_HOOK_APPLIER, 0 )
                        PudgeWarsGameMode:CreateTimer("timer_test_unit_spawn_"..tostring(k)..tostring(GameRules:GetGameTime()),
                        {
                            endTime = Time()+ 0.1,
                            callback = function()
                                if caster:HasModifier("modifier_pudgewars_hooked") then
                                    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
                                    print("the test unit  has the hooked modifier")
                                print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
                                end
                                if dummy then dummy:Destroy() end
                            end
                        })
                    end
                end
            end
        end
    })
end
-- ENDREGION: TEST FUNCITONS
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- function to add score 
function AddScore(team,score)
    PudgeWarsGameMode:AddPudgeWarsScore(team,score)
    GameMode:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,PudgeWarsGameMode:GetPudgeWarsScore(DOTA_TEAM_GOODGUYS))
    GameMode:SetTopBarTeamValue(DOTA_TEAM_BADGUYS,PudgeWarsGameMode:GetPudgeWarsScore(DOTA_TEAM_BADGUYS))
    -- think about game ends
    if PudgeWarsGameMode:GetPudgeWarsScore(DOTA_TEAM_GOODGUYS) > MAX_SCORE then
        GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
        PudgeWarsGameMode:CreateTimer("close_server_radiant",{
            endTime = Time() + 30,
            callback = function()
                SendToServerConsole("exit")
            end
        })
    end
    if PudgeWarsGameMode:GetPudgeWarsScore(DOTA_TEAM_BADGUYS) > MAX_SCORE then
        GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
        PudgeWarsGameMode:CreateTimer("close_server_dire",{
            endTime = Time() + 30,
            callback = function()
                SendToServerConsole("exit")
            end
        })
    end
end
------------------------------------------------------------------------------------------------------------

