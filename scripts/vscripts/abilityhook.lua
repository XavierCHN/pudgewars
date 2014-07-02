
WORLDMAX_VEC = Vector(GetWorldMaxX(),GetWorldMaxY(),0)


-- init hook parameters
function initHookData()
	tbHookByAlly = {}

	tbPlayerOutterHook   = {}
	tbPlayerFinishedHook = {}
	tbPlayerHookingBack  = {}
	tbPlayerHooking      = {}
	tbPlayerNeverHookB4  = {}

	tHookElements = tHookElements or {}
	tnHookDamage  = {175 , 250 , 350 , 500  }
	tnHookLength  = {1400 , 1500 , 1600 , 1800 }
	tnHookRadius  = {80  , 120  , 150  , 200   }
	tnHookSpeed   = {0.10 , 0.14 , 0.18 , 0.22  }

	tnUpgradeHookDamageCost = {500 , 1000 , 1500 , 2000  }
	tnUpgradeHookLengthCost = {500 , 1000 , 1500 , 2000  }
	tnUpgradeHookRadiusCost = {500 , 1000 , 1500 , 2000  }
	tnUpgradeHookSpeedCost  = {500 , 1000 , 1500 , 2000  }

	tnPlayerHookDamage  = {}
	tnPlayerHookLength  = {}
	tnPlayerHookRadius  = {}
	tnPlayerHookSpeed   = {}
	tnPlayerHookType    = {}
	tnPlayerHookBDType  = {}
	tvPlayerPudgeLastPos  = {}
	tnPlayerHookType    = {}
	tnPlayerKillStreak  = {}

	PER_HOOK_BODY_LENGTH = 100

	tnHookTypeString = {
		[1] = "npc_dota2x_pudgewars_unit_pudgehook_lv1",	-- normal hook
		[2] = "npc_dota2x_pudgewars_unit_pudgehook_lv2",	-- black death hook
		[3] = "npc_dota2x_pudgewars_unit_pudgehook_lv3",	-- whale hook
		[4] = "npc_dota2x_pudgewars_unit_pudgehook_lv4"		-- skelton hook
	}

	tnHookParticleString = {
		[1] = "invoker_quas_orb",
		[2] = "invoker_wex_orb",
		[3] = "invoker_exort_orb"
	}

	tPossibleHookTargetName = {
		"npc_dota_hero_pudge",
		"npc_dota2x_pudgewars_chest",
		"npc_dota2x_pudgewars_gold"
	}
	for i = 0,9 do
		tHookElements[i] = {
			Head = {
				unit = nil,
				paIndex = nil
			},
			Target = nil,
			CurrentLength = nil,
			Body = {},
			longerBody = {
				vec = nil,
				index = nil
			}
		}
		tnPlayerHookType[i] = tnHookTypeString[1]
		tnPlayerHookBDType[i] = tnHookParticleString[1]
		tnPlayerHookRadius[i] = 80
		tnPlayerHookLength[i] = 1400
		tnPlayerHookSpeed[i] = 0.2
		tnPlayerHookDamage[i] = 175

		tbPlayerOutterHook[i] = false
		tbPlayerNeverHookB4[i] = true

	end
	PudgeWarsGameMode:CreateTimer("Create_Test_units",{
		endTime = Time(),
		callback = function ()
			if developmentmode then
				--print("spawning test units")
				local testUnitTable = {
					 "npc_dota_goodguys_melee_rax_bot"
					,"npc_dota_neutral_blue_dragonspawn_overseer"
					,"npc_dota_necronomicon_warrior_2"
					,"npc_dota_warlock_golem_3"
				}
				for k,v in pairs(testUnitTable) do
					table.insert( tPossibleHookTargetName , #tPossibleHookTargetName + 1 ,v)
					--ability_dota2x_pudgewars_hook_applier
					
					local caster = CreateUnitByName(
						v,
						Vector(-1500,-500,0) + RandomVector(400),
						false,
						nil,
						nil,
						DOTA_TEAM_BADGUYS)
					
					local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", 
						caster:GetAbsOrigin(), false, caster, caster, DOTA_TEAM_GOODGUYS)
					if dummy then print("test dummy unit created") end
					dummy:AddAbility("ability_dota2x_pudgewars_hook_applier")
					local ABILITY_HOOK_APPLIER = dummy:FindAbilityByName("ability_dota2x_pudgewars_hook_applier")
					if ABILITY_HOOK_APPLIER then print("ability successful added") end
					ABILITY_HOOK_APPLIER:SetLevel(1)
	
					dummy:CastAbilityOnTarget(caster, ABILITY_HOOK_APPLIER, 0 )
					PudgeWarsGameMode:CreateTimer("damage_dealer_"..tostring(k)..tostring(GameRules:GetGameTime()),
					{
						endTime = Time() + 0.5,
						callback = function()
							if caster:HasModifier("modifier_pudgewars_hooked") then
								print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
								print("the test unit  has the hooked modifier")
								print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
							end
							dummy:Destroy()
						end
					})
					
					
				end
				--PrintTable(tPossibleHookTargetName)
			end
		end
	})
	print("[pudgewars] finish init hook data")
end

local function distance(a, b)
    -- Pythagorian distance
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
		print("no kill streak!")
		hookType = tnHookTypeString[1]
	end
	return hookType
end

function OnHookStart(keys)

	local targetPoint = keys.target_points[1]
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = keys.unit:GetPlayerID()

	--PrintTable(keys)
	print("player "..nPlayerID.." Start A Hook")
	if not tbPlayerNeverHookB4[nPlayerID] then
		if not tbPlayerFinishedHook[nPlayerID] then
			print("invalid hook")
                     return
		end
              tbPlayerNeverHookB4[nPlayerID] = false
	end
	
	--init hook parameters
	tbPlayerHooking[nPlayerID] = false
	tbPlayerFinishedHook[nPlayerID] = false
	tbPlayerHookingBack[nPlayerID] = false
	tHookElements[nPlayerID].Target = nil
	tHookElements[nPlayerID].CurrentLength = nil
	
	hookSetPoint = caster:GetOrigin()

	-- create the hook head
	local unit = CreateUnitByName(
		 GetHookType(nPlayerID)
		,hookSetPoint
		,false
		,caster
		,caster
		,caster:GetTeam()
		)
	if not unit then
		--print("failed to create hook head")
	else
		-- the head ai, currently think about walls only
		unit:SetContextThink("hookheadthink",Dynamic_Wrap( PudgeWarsGameMode, 'HookHeadThink' ),0.1)
		
		-- store the head
		tHookElements[nPlayerID].Head.unit = unit
		
		-- set the head model scale to the hook radius
		unit:SetModelScale((tnPlayerHookRadius[nPlayerID]/80)*0.8,0)
	
		-- set head forward vector
		local diffVec = targetPoint - caster:GetOrigin()
		diffVec.z = 0
		print("diffVec "..tostring(diffVec))
		unit:SetForwardVector(diffVec:Normalized())
		
		-- catch the head position
		local vOrigin = unit:GetOrigin()
		tvPlayerPudgeLastPos[nPlayerID] = caster:GetOrigin()
		
		--create and store the first body particles ,vector and forward vector
		local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBDType[ nPlayerID ] , PATTACH_CUSTOMORIGIN, caster )
		vOrigin.z = vOrigin.z + 150
		ParticleManager:SetParticleControl( nFXIndex, 0, vOrigin )
		ParticleManager:SetParticleControl( nFXIndex, 1, vOrigin )
		ParticleManager:SetParticleControl( nFXIndex, 2, vOrigin )
		ParticleManager:SetParticleControl( nFXIndex, 3, vOrigin )
		tHookElements[nPlayerID].Body[1] = {
		    index = nFXIndex,
		    vec = vOrigin,
		    fvec = caster:GetForwardVector()
		}

		-- create the head trail particle
		tnFXIndex = ParticleManager:CreateParticle( "the_quas_trail" , PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( tnFXIndex, 0, vOrigin )
		tHookElements[nPlayerID].Head.index = tnFXIndex
		
		--remove the set ability and add release ability
		caster:RemoveAbility("ability_pudgewars_set_hook")
		caster:AddAbility("ability_pudgewars_release_hook")
		ABILITY_RELEASE_HOOK = caster:FindAbilityByName("ability_pudgewars_release_hook")
		ABILITY_RELEASE_HOOK:SetLevel(1)
	end

end

function OnHookSet(keys)

	
	local targetPoint = keys.target_points[1]
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = keys.unit:GetPlayerID()

	--PrintTable(keys)
	print("player "..nPlayerID.." Start A Hook")
	if not tbPlayerNeverHookB4[nPlayerID] then
		if not tbPlayerFinishedHook[nPlayerID] then
			print("invalid hook")
                     return
		end
              tbPlayerNeverHookB4[nPlayerID] = false
	end
	
	--init hook parameters
	tbPlayerHooking[nPlayerID] = false
	tbPlayerFinishedHook[nPlayerID] = false
	tbPlayerHookingBack[nPlayerID] = false
	tHookElements[nPlayerID].Target = nil
	tHookElements[nPlayerID].CurrentLength = nil
	
	
	-- the player is releasing an outter hook?
	local hasModifieroh = caster:HasModifier("pudgewars_outter_hook")
	if hasModifieroh then 
		hookSetPoint = targetPoint
	else
		hookSetPoint = caster:GetOrigin()
	end
	
	
	
	-- create the hook head
	local unit = CreateUnitByName(
		 GetHookType(nPlayerID)
		,hookSetPoint
		,false
		,caster
		,caster
		,caster:GetTeam()
		)
	if not unit then
		--print("failed to create hook head")
	else
		-- the head ai, currently think about walls only
		unit:SetContextThink("hookheadthink",Dynamic_Wrap( PudgeWarsGameMode, 'HookHeadThink' ),0.1)
		
		-- store the head
		tHookElements[nPlayerID].Head.unit = unit
		
		-- set the head model scale to the hook radius
		unit:SetModelScale((tnPlayerHookRadius[nPlayerID]/80)*0.8,0)
	
		-- set head forward vector
		local diffVec = targetPoint - caster:GetOrigin()
		diffVec.z = 0
		print("diffVec "..tostring(diffVec))
		unit:SetForwardVector(diffVec:Normalized())
		
		-- catch the head position
		local vOrigin = unit:GetOrigin()
		tvPlayerPudgeLastPos[nPlayerID] = caster:GetOrigin()
		
		--create and store the first body particles ,vector and forward vector
		local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBDType[ nPlayerID ] , PATTACH_CUSTOMORIGIN, caster )
		vOrigin.z = vOrigin.z + 150
		ParticleManager:SetParticleControl( nFXIndex, 0, vOrigin )
		ParticleManager:SetParticleControl( nFXIndex, 1, vOrigin )
		ParticleManager:SetParticleControl( nFXIndex, 2, vOrigin )
		ParticleManager:SetParticleControl( nFXIndex, 3, vOrigin )
		tHookElements[nPlayerID].Body[1] = {
		    index = nFXIndex,
		    vec = vOrigin,
		    fvec = caster:GetForwardVector()
		}

		-- create the head trail particle
		tnFXIndex = ParticleManager:CreateParticle( "the_quas_trail" , PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( tnFXIndex, 0, vOrigin )
		tHookElements[nPlayerID].Head.index = tnFXIndex
		
		--remove the set ability and add release ability
		caster:RemoveAbility("ability_pudgewars_set_hook")
		caster:AddAbility("ability_pudgewars_release_hook")
		ABILITY_RELEASE_HOOK = caster:FindAbilityByName("ability_pudgewars_release_hook")
		ABILITY_RELEASE_HOOK:SetLevel(1)
	end
end

-- On outter hook setting hook direction to the caster direction
function OnSettingHookDirection(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	local casterFV = caster:GetForwardVector()
	local head = tHookElements[nPlayerID].Head.unit
	head:SetForwardVector(casterFV)
end

-- if timeup then the hook disappear
function OnSettingHookDirectionTimeUp(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	local head = tHookElements[nPlayerID].Head.unit
	local headpa = tHookElements[nPlayerID].Head.index
	local body1pa = tHookElements[nPlayerID].Body[1].index
	local ABILITY_SETTING_HOOK_DIRECTION = caster:FindAbilityByName("ability_pudgewars_release_hook")
	if not tbPlayerHooking[nPlayerID] then
		head:Remove()
		ParticleManager:SetParticleControl(headpa,0,WORLDMAX_VEC)
		ParticleManager:ReleaseParticleIndex(headpa)
		ParticleManager:SetParticleControl(body1pa,0,WORLDMAX_VEC)
		ParticleManager:SetParticleControl(body1pa,1,WORLDMAX_VEC)
		ParticleManager:SetParticleControl(body1pa,2,WORLDMAX_VEC)
		ParticleManager:SetParticleControl(body1pa,3,WORLDMAX_VEC)
		ParticleManager:ReleaseParticleIndex(body1pa)
	end
	
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


local function GetHookedUnit(caster, head , plyid)
	local tuHookedUnits = nil
	tuHookedUnits = FindUnitsInRadius(
		caster:GetTeam(),		--caster team
		head:GetOrigin(),		--find position
		nil,					--find entity
		tnPlayerHookRadius[plyid],			--find radius
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_ALL, 
		0, FIND_CLOSEST,
		false
	)
	-- remove all useless untis
	if #tuHookedUnits >= 1 then
		for k,v in pairs(tuHookedUnits) do
			
			print("unitunitname " .. tostring(k)..":"..v:GetUnitName())

			local va = false
			for s,t in pairs (tPossibleHookTargetName) do
				if v:GetUnitName() == t then
					-- the unit in the table , a valid hook unit
					print("valid unit found")
					va = true
				end
			end
			if ( not va ) or ( v == caster ) then
				-- not a valid unit , remove
				print("remove invalid unit")
				print("v == caster:" ..tostring( v == caster))
				tuHookedUnits[k] = nil
			end
		end
	end
	
	-- if there is units left then catch it
	for k,v in pairs(tuHookedUnits) do
		if v ~= nil then
			print("return hooked unit"..v:GetUnitName())
			return v
		end
	end
	
	return nil
end

-- a function to deal lasthit

function dealLastHit( caster,target )
	local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", 
		target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	--if dummy then print("unit created") end
	dummy:AddAbility("ability_deal_the_last_hit")
	local ABILITY_LAST_HIT = dummy:FindAbilityByName("ability_deal_the_last_hit")
	ABILITY_LAST_HIT:SetLevel(1)
	dummy:CastAbilityOnTarget(target, ABILITY_LAST_HIT, 0 )

	PudgeWarsGameMode:CreateTimer("last_hit"..tostring(dummy)..tostring(GameRules:GetGameTime()),{
		endTime = Time() + 1,
		callback = function()
			print("removing dummy unit")
			dummy:Destroy()
			if target:IsAlive() then
				print("WARNING! THE UNIT IS STILL ALIVE")
				--target:ForceKill(false)
			end
		end
	})
	
	-- print the kill streak -- testing
	for i = 0,9 do
		print("current kill streak: "..i.." :"..PlayerResource:GetStreak(i))
	end
end

-- catch the hook unit
local function HookUnit( target , caster ,plyid )
	print ( "hooked something" )
	print ( "the enemy name "..target:GetUnitName())
	
	--if the unit is already hooked by someone
	if target:HasModifier("modifier_pudgewars_hooked") then
		if target:GetTeam() ~= caster:GetTeam() then
			--HEAD SHOT
			--print("unit has been hooked and its an enemy")
			dealLastHit(caster,target)
			local msg = {
			message = "#pudgewars_head_shot",
			duration = 1
			}
		FireGameEvent('show_center_message',msg)
			--TODO
			--EMIT SOUND
		end
		if tbHookByAlly[target] then
			--print("the unit has been hooked by ally")
			if target:GetTeam() ~= caster:GetTeam() then
				--HEADSHOT
				dealLastHit(caster,target)
				showCenterMessag("#pudgewars_head_shot")
				local msg = {
					message = "#pudgewars_head_shot",
					duration = 1
					}
				FireGameEvent('show_center_message',msg)
				--TODO
				--EMIT SOUND
			end
		else
			--print("the unit has been hooked by enemy")
			if target:GetTeam() == caster:GetTeam() then
				--DENIED
				dealLastHit(caster,target)
				local msg = {
					message = "#pudgewars_head_shot",
					duration = 1
					}
				FireGameEvent('show_center_message',msg)
				--TODO
			    --EMIT SOUND
			end
		end
	end

	-- fire particle effect
	local casterOrigin = caster:GetOrigin()
	local uOrigin = target:GetOrigin()
	local nFXIndex = ParticleManager:CreateParticle( "necrolyte_scythe", PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl(nFXIndex,0,uOrigin)
	ParticleManager:SetParticleControl(nFXIndex,1,uOrigin)
	ParticleManager:SetParticleControl(nFXIndex,2,casterOrigin)
	ParticleManager:ReleaseParticleIndex(nFXIndex)
	
	-- create hook dummy unit
	local time = GameRules:GetGameTime()
	local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", 
		target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	dummy:AddAbility("ability_dota2x_pudgewars_hook_applier")
	local ABILITY_HOOK_APPLIER = dummy:FindAbilityByName("ability_dota2x_pudgewars_hook_applier")
	ABILITY_HOOK_APPLIER:SetLevel(1)
	-- hook the target, this ability has no damage
	dummy:CastAbilityOnTarget(target, ABILITY_HOOK_APPLIER, 0 )
	
	-- timer to remove unit
	PudgeWarsGameMode:CreateTimer("damage_dealer_"..tostring(caster)..tostring(GameRules:GetGameTime()),
	{
		endTime = Time() + 0.5,
		callback = function()
			dummy:Destroy()
		end
	})

	-- todo add bonus damage according to hook head refract
	local dmg = tnPlayerHookDamage[plyid]
	local bonusdamage = 0
	
	-- think about barathon's latern item
	local itemLatern = ItemThinker:FindItemFuzzy(caster,"item_pudge_barathrum_lantern")
	if itemLatren then
		local itemLevel = string.sub(itemLatern,-1,-1)
		print("ITEM LATERN FOUND LV :"..tostring(itemLevel))
		-- 15% 20% 25% 30% 45%
		bonusdamage = (tonumber(itemLevel) * 5 + 10 / 100) * dmg
	end
	-- if the player has the barathon latern, add bonus damage
	dmg = dmg + bonusdamage


	--print("dmg = "..tostring(dmg).."playerdi"..tostring(plyid))
	local hp = target:GetHealth()
	--print(" hp = "..tostring(hp))
	if target:GetTeam() ~= caster:GetTeam() then
		if dmg < hp then
			-- take away health directly
			target:SetHealth(hp-dmg)
			
			--think about blood seeker's claw
			local itemBlood = ItemThinker:FindItemFuzzy(caster,"item_pudge_bloodseeker_claw")
			if itemBlood then
				local itemLevel = string.sub(itemBlood,-1,-1)
				print("ITEAM BLOOD SEEKER CLAW FOUND LEVEL:"..itemLevel)
				local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", 
					target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
				--if dummy then print("unit created") end
				dummy:AddAbility("ability_dota2x_pudgewars_bloodsekker_claw")
				local ABILITY_BLOOD_APPLIER = dummy:FindAbilityByName("ability_dota2x_pudgewars_bloodsekker_claw")
				--if ABILITY_BLOOD_APPLIER then print("ability_dota2x_pudgewars_bloodsekker_claw ability successful added") end
				ABILITY_BLOOD_APPLIER:SetLevel(tonumber(itemLevel))
					
				dummy:CastAbilityOnTarget(target, ABILITY_BLOOD_APPLIER, 0 )
				PudgeWarsGameMode:CreateTimer("blood_claw_dealer_"..tostring(caster)..tostring(GameRules:GetGameTime()),
				{
					endTime = Time() + 0.5,
					callback = function()
						dummy:Destroy()
					end
				})
			end
		
			-- think about naix's jaw
			local itemJaw = ItemThinker:FindItemFuzzy(caster,"item_pudge_naix_jaw")
			if itemJaw then

				local index = ParticleManager:CreateParticle("life_stealer_infest_emerge_clean_lights_LV",PATTACH_CUSTOMORIGIN,caster)
				local offsetVec = Vector(0,0,150)
				ParticleManager:SetParticleControl(index,0,caster:GetOrigin() + offsetVec)
				ParticleManager:ReleaseParticleIndex(index)

				local itemLevel = string.sub(itemJaw,-1,-1)
				--print("ITEM JAW FOUND LEVEL:"..itemLevel)
				local lifestealPercent = (tonumber(itemLevel) * 5 + 5) / 100
				caster:SetHealth(caster:GetHealth() + dmg * lifestealPercent)
			end
			
		else
			-- ADD THE ABILITY "ability_deal_the_last_hit" AND DEAL DAMAGE WITH THE SPELL
			dealLastHit(caster,target)
		end
	end
	
	--THINK ABOUT HEADSHOT AND DENY
	if target:GetTeam() == caster:GetTeam() then
		tbHookByAlly[target] = true
	else
		tbHookByAlly[target] = false
	end

	
	return 1
end

function OnReleaseHook( keys )
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	if not tbPlayerFinishedHook[nPlayerID] then
	
		if tHookElements[nPlayerID] == nil then print("hook elements not found returning") return end
		local uHead = tHookElements[nPlayerID].Head.unit
		local headOrigin = uHead:GetOrigin()
		local paHead = tHookElements[nPlayerID].Head.index
		local headFV = uHead:GetForwardVector()

		tbPlayerHooking[nPlayerID] = true
		
		-- clear outter hook modifiers and ability
		local ABILITY_RELEASE_HOOK = caster:FindAbilityByName("ability_pudgewars_release_hook")
		if caster:HasModifier( "pudgewars_setting_hook" ) then caster:RemoveModifierByName("pudgewars_setting_hook") end
		if ABILITY_RELEASE_HOOK then 
			caster:RemoveAbility("ability_pudgewars_release_hook")
			caster:AddAbility("ability_pudgewars_hook")
			local ABILITY_HOOK = caster:FindAbilityByName("ability_pudgewars_hook")
			if ABILITY_HOOK then ABILITY_HOOK:SetLevel(1) end
		end

		if uHead ~= nil and 
			tHookElements[nPlayerID].Target == nil and
			not tbPlayerHookingBack[nPlayerID] then
			
			-- if the head is valid and found not target and it's going out
			
			-- count the length
			if tHookElements[nPlayerID].CurrentLength == nil then 
				tHookElements[nPlayerID].CurrentLength = 2 
			else 
				tHookElements[nPlayerID].CurrentLength = tHookElements[nPlayerID].CurrentLength + 1 
			end
			
			
			if tvPlayerPudgeLastPos[nPlayerID] == nil then tvPlayerPudgeLastPos[nPlayerID] = caster:GetOrigin() end
			local diffVec = caster:GetOrigin() - tvPlayerPudgeLastPos[nPlayerID]
			
			-- if the hook reaches max length
			if tHookElements[nPlayerID].CurrentLength 
				* PER_HOOK_BODY_LENGTH 
					* tnPlayerHookSpeed[nPlayerID] 
						> tnPlayerHookLength[nPlayerID] 
			then
				-- turn it back
				tbPlayerHookingBack[nPlayerID] = true
				return 
			else
				
				-- if the hook is going out
				-- THINK ABOUT HEAD FORWARD VECTOR FATAL ERROR
				if headFV.x == 0 and headFV.y == 0 then
					print("WARNING: HOOK HEAD IS NOT MOVING")
					say(nil,"FATAL ERROR:钩子朝向错误，取消错误的钩子释放...",false)
					tbPlayerHookingBack[nPlayerID] = true
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
				
				-- create hook body particle and store position
				local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBDType[ nPlayerID ], PATTACH_CUSTOMORIGIN, caster )
				tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body + 1] = {
				    index = nFXIndex,
				    vec = vec3,
				    fvec = diffVec:Normalized()
				}
				tvec3 = vec3
				tvec3.z = vec3.z + 150
				ParticleManager:SetParticleControl( nFXIndex, 0, tvec3)
				ParticleManager:SetParticleControl( nFXIndex, 1, tvec3)
				ParticleManager:SetParticleControl( nFXIndex, 2, tvec3)
				ParticleManager:SetParticleControl( nFXIndex, 3, tvec3)
				ParticleManager:SetParticleControl( paHead, 0, tvec3 )

				-- try to catch any target
				tHookElements[nPlayerID].Target = GetHookedUnit(caster , uHead , nPlayerID)
				
				-- if success then turn the hook back
				if tHookElements[nPlayerID].Target then
					tbPlayerHookingBack[nPlayerID]  = true
					HookUnit( tHookElements[nPlayerID].Target , caster ,nPlayerID)
					return
				end
			end

			tvPlayerPudgeLastPos[nPlayerID] = caster:GetOrigin()
		else
			local backVec = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].vec
			local fVec = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].fvec
			local paIndex = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].index
			
			-- remove hook body and release the particle
			ParticleManager:SetParticleControl( paIndex, 0, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 1, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 2, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 3, WORLDMAX_VEC)
			ParticleManager:ReleaseParticleIndex( paIndex )
			
			-- set the head position and forward vector
			tbackVec = backVec
			ParticleManager:SetParticleControl( paHead, 0, backVec )
			tbackVec.z = tbackVec.z - 150
			uHead:SetOrigin(backVec)
			uHead:SetForwardVector(fVec)
			
			-- if hooked any target then take it back
			if tHookElements[nPlayerID].Target then 
				tHookElements[nPlayerID].Target:SetOrigin(backVec)
			end
			
			-- remove the body
			table.remove(tHookElements[nPlayerID].Body,#tHookElements[nPlayerID].Body)
			
			-- if reachs end
			if #tHookElements[nPlayerID].Body == 0 then
				
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
				local offsetVecs = Vector(0,0,-300)
				ParticleManager:SetParticleControl( paHead, 0, tHookElements[nPlayerID].Head.unit:GetOrigin() + offsetVecs)
				PudgeWarsGameMode:CreateTimer("release_hook_head_particle_out"..tostring(nPlayerID),{
					endTime = Time() + 0.1,
					callback = function()
						ParticleManager:SetParticleControl( paHead, 0, WORLDMAX_VEC)
						ParticleManager:ReleaseParticleIndex(paHead)
					end
					})
				tHookElements[nPlayerID].Head.unit = nil
				uHead:Remove()
				tHookElements[nPlayerID].Body = {}
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
end

-- upgrade hook functions below
function OnUpgradeHookDamage(keys)
	print("upgrading damage")
	--PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_damage")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)
	if nCurrentLevel == 4 then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_damage_max_level",false)
		return
	end

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_damage_not_enough_gold",false)
	end
end

function OnUpgradeHookRadius( keys )
	print("upgrading radius")

	--PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	
	local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_radius")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	if nCurrentLevel == 4 then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_radius_max_level",false)
		return
	end

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_radius_not_enough_gold",false)
	end
end

function OnUpgradeHookLength( keys )
	print("upgrading length")

	--PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_length")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookLengthCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	if nCurrentLevel == 4 then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_length_max_level",false)
		return
	end

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_length_not_enough_gold",false)
	end
end

function OnUpgradeHookSpeed( keys )
	print("upgrading speed")

	--PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_speed")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	if nCurrentLevel == 4 then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_speed_max_level",false)
		return
	end

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_speed_not_enough_gold",false)
	end
end

function OnUpgradeHookDamageFinished( keys )

	--PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_damage")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
	
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_damage_fail_to_spend_gold",false)
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		if developmentmode then nUpgradeCost = -10000 end
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookDamage[ nPlayerID ] =  tnHookDamage[ nCurrentLevel + 1 ]
	end
end

function OnUpgradeHookRadiusFinished( keys )

	--PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()


	local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_radius")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_radius_fail_to_spend_gold",false)
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookRadius[ nPlayerID ] =  tnHookRadius[ nCurrentLevel + 1 ]
	end
end

function OnUpgradeHookLengthFinished( keys )

	--PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_length")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookLengthCost[nCurrentLevel]
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_length_fail_to_spend_gold",false)
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookLength[ nPlayerID ] =  tnHookLength[ nCurrentLevel + 1 ]
	end
end

function OnUpgradeHookSpeedFinished( keys )

	--PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("ability_pudgewars_upgrade_speed")
	local nCurrentLevel = hHookAbility:GetLevel()
	

	local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_speed_fail_to_spend_gold",false)
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookSpeed[ nPlayerID ] =  tnHookSpeed[ nCurrentLevel + 1 ]
	end
end

function OnToggleHookType( keys )
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local ABILITY_START_HOOK = caster:FindAbilityByName("ability_pudgewars_hook")
	if ABILITY_START_HOOK then
		print("remove ability")
		caster:RemoveAbility("ability_pudgewars_hook")
		print("add ability")
		caster:AddAbility("ability_pudgewars_set_hook")
		local ABILITY_SET_HOOK = caster:FindAbilityByName("ability_pudgewars_set_hook")
		if ABILITY_SET_HOOK then
			ABILITY_SET_HOOK:SetLevel(1)
		end
	end
end

function PlantABomb(keys)
	PrintTable(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	local returnPos = nil

	if tHookElements[nPlayerID].Head.unit then
		print("there is a head,plant bomb at head")
		returnPos = tHookElements[nPlayerID].Head.unit:GetOrigin()
	else
		returnPos = caster:GetOrigin()
	end
	local unit =CreateUnitByName(
		"npc_dota2x_pudgewars_unit_bomb",
		returnPos,
		false,
		nil,
		nil,
		caster:GetTeam())
	unit:AddNewModifier(unit,nil,"modifier_phased",{})
		
	local item_bomb = ItemThinker:FindItemFuzzy(caster,"item_pudge_techies_explosive_barrel")
	if item_bomb then
		local itemLevel = string.sub(item_bomb,-1,-1)
		print("ITEM LATERN FOUND LV :"..tostring(itemLevel))
			unit:AddAbility("ability_make_bomb_a_bomb")
		local ABILITY_BOMB = unit:FindAbilityByName("ability_make_bomb_a_bomb")
		if ABILITY_BOMB then
			print("bomb level set")
			ABILITY:SetLevel(itemLevel)
		else
			print("UNIT ABILITY NOT FOUND")
		end
	else
		print("FATAL: FAILD TO FIND ITEM BOMB")
	end
end
function ThinkAboutBombTriggered(keys)
	if not ThinkAboutBombTriggeredprinted then
		print("thinkaboutbombtriggered")
		ThinkAboutBombTriggeredprinted = ture
		PrintTable(keys)
	end
	local caster = EntIndedxToHscript(keys.caster_entindex)
	local center = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_make_bomb_a_bomb")
	local radius = ability:GetSpecialValueFor("Radius")
	local dmg = ability:GetSpecialValueFor("bomb_damage")
	
	local triggeredUnits = nil
	triggeredUnits = FindUnitsInRadius(
		caster:GetTeam(),		--caster team
		center,		--find position
		nil,					--find entity
		radius,			--find radius
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_ALL, 
		0, FIND_CLOSEST,
		false
	)
	local triggered = false
	if triggeredUnits then
		for k,v in pairs(triggeredUnits) do
			if v:GetUnitName() ~= "npc_dota_hero_pudge" then
				v = nil
			else
				triggered = true
			end
	end
	if triggered then
		print("bomb triggered")
		for k,v in pairs(triggeredUnits) do
			if v ~= nil then
				local health = v:GetHealth()
				if dmg > health then
					PudgeWarsGameMode:CreateTimer("bomb_last_hit"..tostring(GameRules:GetGameTime()),{
						endTime = Time()
						callback = function()
							dealLastHit(caster,v)
						end
					})
				else
					v:SetHealth(v:GetHealth() - dmg)
				end
			end
		end
	end
end
