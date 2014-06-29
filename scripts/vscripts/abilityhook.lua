
WORLDMAX_VEC = Vector(GetWorldMaxX(),GetWorldMaxY(),0)



function initHookData()
	tbHookByAlly = {}

	tbPlayerOutterHook   = {}
	tbPlayerFinishedHook = {}
	tbPlayerHookingBack  = {}
	tbPlayerHooking      = {}

	tHookElements = tHookElements or {}
	tnHookDamage  = {175 , 250 , 350 , 500  }
	tnHookLength  = {500 , 700 , 900 , 1200 }
	tnHookRadius  = {20  , 30  , 50  , 80   }
	tnHookSpeed   = {0.2 , 0.3 , 0.4 , 0.6  }

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
	tPlayerPudgeLastFV  = {}
	tnPlayerHookType    = {}
	tnPlayerKillStreak  = {}

	PER_HOOK_BODY_LENGTH = 50

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
			Body = {}
		}
		tnPlayerHookType[i] = tnHookTypeString[1]
		tnPlayerHookBDType[i] = tnHookParticleString[1]
		tnPlayerHookRadius[i] = 100
		tnPlayerHookLength[i] = 1300
		tnPlayerHookSpeed[i] = 0.4
		tnPlayerHookDamage[i] = 200

		tbPlayerOutterHook[i] = false

	end
	if developmentmode then
		PudgeWarsGameMode:CreateTimer("Create_Test_units",{
			endTime = Time(),
			callback = function ()
				if developmentmode then
					print("spawning test units")
					local testUnitTable = {
						 "npc_dota_goodguys_melee_rax_bot"
						,"npc_dota_neutral_blue_dragonspawn_overseer"
						,"npc_dota_necronomicon_warrior_2"
						,"npc_dota_warlock_golem_3"
					}
					for k,v in pairs(testUnitTable) do
						table.insert( tPossibleHookTargetName , #tPossibleHookTargetName + 1 ,v)
						--ability_dota2x_pudgewars_hook_applier
						
						local caster = CreateUnitByName(v,Vector(-1500,-1000,0) + RandomVector(300),false,nil,nil,DOTA_TEAM_BADGUYS)
						--[[
						local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", 
							caster:GetAbsOrigin(), false, caster, caster, DOTA_TEAM_GOODGUYS)
						if dummy then print("test dummy unit created") end
						dummy:AddAbility("ability_dota2x_pudgewars_hook_applier")
						local ABILITY_HOOK_APPLIER = dummy:FindAbilityByName("ability_dota2x_pudgewars_hook_applier")
						if ABILITY_HOOK_APPLIER then print("ability successful added") end
						ABILITY_HOOK_APPLIER:SetLevel(1)
		
						dummy:CastAbilityOnTarget(caster, ABILITY_HOOK_APPLIER, 0 )]]
						PudgeWarsGameMode:CreateTimer("damage_dealer_"..tostring(k)..tostring(GameRules:GetGameTime()),
						{
							endTime = Time() + 0.5,
							callback = function()
								--[[if caster:HasModifier("modifier_pudgewars_hooked") then
									print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
									print("the test unit  has the hooked modifier")
									print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
								end]]
								if dummy then dummy:Destroy() end
							end
						})
						
						
					end
					PrintTable(tPossibleHookTargetName)
				end
			end
		})
	end
	print("[pudgewars] finish init hook data")
end

local function distance(a, b)
    -- Pythagorian distance
    local xx = (a.x-b.x)
    local yy = (a.y-b.y)

    return math.sqrt(xx*xx + yy*yy)
end

function OnHookStart(keys)
	local targetPoint = keys.target_points[1]
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = keys.unit:GetPlayerID()

	-- this is right!
	for i = 0,5 do
		local item = caster:GetItemInSlot(i)
		local itemName = item:GetName()
		print(tostring(i).."*!*!*"..itemName)
	end

	print("player "..nPlayerID.." Start A Hook")

	--create the hook head
	tbPlayerHooking[nPlayerID] = false
	tbPlayerFinishedHook[nPlayerID] = false
	tbPlayerHookingBack[nPlayerID] = false
	tHookElements[nPlayerID].Target = nil
	tHookElements[nPlayerID].CurrentLength = nil
	local hasModifieroh = false
	if caster:HasModifier("pudgewars_outter_hook") then
		hasModifieroh = true
	end
	if not hasModifieroh then targetPoint = caster:GetOrigin() end
	local unit = CreateUnitByName(
		"npc_dota2x_pudgewars_unit_pudgehook_lv1"
		,targetPoint
		,false
		,nil
		,nil
		,caster:GetTeam()
		)
	if not unit then
		print("failed to create hook head")
	else
		-- store the head
		tHookElements[nPlayerID].Head.unit = unit

		-- catch the head position
		local vOrigin = unit:GetOrigin()
		
		--create and store the first body		
		local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBDType[ nPlayerID ] , PATTACH_CUSTOMORIGIN, caster )
		vOrigin.z = vOrigin.z + 150
		ParticleManager:SetParticleControl( nFXIndex, 0, vOrigin )
		ParticleManager:SetParticleControl( nFXIndex, 1, vOrigin )
		ParticleManager:SetParticleControl( nFXIndex, 2, vOrigin )
		ParticleManager:SetParticleControl( nFXIndex, 3, vOrigin )
		tHookElements[nPlayerID].Body[1] = {
		    index = nFXIndex,
		    vec = vOrigin
		}

		-- create the head trail particle
		tnFXIndex = ParticleManager:CreateParticle( "the_quas_trail" , PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( tnFXIndex, 0, vOrigin )
		tHookElements[nPlayerID].Head.index = tnFXIndex
		
		--remove the set ability and add release ability
			caster:RemoveAbility("dota2x_pudgewars_hook")
			caster:AddAbility("dota2x_pudgewars_release_hook")
			ABILITY_RELEASE_HOOK = caster:FindAbilityByName("dota2x_pudgewars_release_hook")
			ABILITY_RELEASE_HOOK:SetLevel(1)
		
		if not hasModifieroh then

			ExecuteOrderFromTable({
				UnitIndex = caster:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = ABILITY_RELEASE_HOOK:entindex(),
			})
			
		end
	end
end

function OnSettingHookDirection(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	local casterFV = caster:GetForwardVector()
	local head = tHookElements[nPlayerID].Head.unit
	head:SetForwardVector(casterFV)
end

function OnSettingHookDirectionTimeUp(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	local head = tHookElements[nPlayerID].Head.unit
	local headpa = tHookElements[nPlayerID].Head.index
	local body1pa = tHookElements[nPlayerID].Body[1].index
	local ABILITY_SETTING_HOOK_DIRECTION = caster:FindAbilityByName("dota2x_pudgewars_release_hook")
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

	if ABILITY_SETTING_HOOK_DIRECTION then 
		caster:RemoveAbility("dota2x_pudgewars_release_hook")
		caster:AddAbility("dota2x_pudgewars_hook")
		if caster:HasModifier("pudgewars_setting_hook") then
			caster:RemoveModifierByName("pudgewars_setting_hook")
		end
		local ABILITY_HOOK = caster:FindAbilityByName("dota2x_pudgewars_hook")
		if ABILITY_HOOK then ABILITY_HOOK:SetLevel(1) end
	end
end

local function showCenterMessage( msg )
	local m = {
		message= msg,
		duration = 2
	}
	FireGameEvent("show_center_message",m)
	-- body
end

local function GetHookedUnit(caster, head , plyid)
		
	-- find unit in radius within hook radius	
	local tuHookedUnits = FindUnitsInRadius(
		caster:GetTeam(),		--caster team
		head:GetOrigin(),		--find position
		nil,					--find entity
		tnPlayerHookRadius[plyid],			--find radius
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_ALL, 
		0, FIND_CLOSEST,
		false
	)

	if #tuHookedUnits >= 1 then
		for k,v in pairs(tuHookedUnits) do
			print("unitunitname " .. tostring(k)..":"..v:GetUnitName())

			local va = false
			for s,t in pairs (tPossibleHookTargetName) do
				if v:GetUnitName() == t then
					-- the unit in the table , a valid hook unit
					va = true
				end
			end
			if ( not va ) or ( v == caster ) then
				-- not a valid unit , remove
				print("remove")
				table.remove(tuHookedUnits , k)
			end
		end
	end
	
	if #tuHookedUnits >= 1 then
		-- return the nearest unit
		return tuHookedUnits[1]
	end
	return nil
end

local function dealLastHit( caster,target )
	caster:AddAbility("ability_deal_the_last_hit")
	local ABILITY_LAST_HIT = caster:FindAbilityByName("ability_deal_the_last_hit")
	ABILITY_LAST_HIT:SetLevel(1)
	ExecuteOrderFromTable({
		UnitIndex = caster:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		AbilityIndex = ABILITY_LAST_HIT:entindex(),
		TargetIndex = target:entindex()
	})
	caster:RemoveAbility("ability_deal_the_last_hit")
	if target:IsAlive() then
		target:ForceKill(false)
	end
end

local function HookUnit( target , caster ,plyid )
	print ( "hooked something" )
	print ( "the enemy name "..target:GetName())

	if target:HasModifier("modifier_pudgewars_hooked") then
		print("the hooked unit has the hooked modifier already!!")
		print("the hooked unit has the hooked modifier already!!")
		print(tostring(target:GetTeamNumber()))
		print(tostring(caster:GetTeamNumber()))
		print(tostring(target:GetTeam()))
		print(tostring(caster:GetTeam()))
		print("the hooked unit has the hooked modifier already!!")
		if target:GetTeam() ~= caster:GetTeam() then
			--HEAD SHOT
			print("unit has been hooked and its an enemy")
			dealLastHit(caster,target)
			showCenterMessage("#pudgewars_head_shot")
			--TODO
			--EMIT SOUND
		end
		if tbHookByAlly[target] then
			print("the unit has been hooked by ally")
			if target:GetTeam() ~= caster:GetTeam() then
				--HEADSHOT
				dealLastHit(caster,target)
				showCenterMessage("#pudgewars_head_shot")
				--TODO
				--EMIT SOUND
			end
		else
			print("the unit has been hooked by enemy")
			if target:GetTeam() == caster:GetTeam() then
				--DENIED
				dealLastHit(caster,target)
				showCenterMessage("#pudgewars_denied")
				--TODO
			    --EMIT SOUND
			end
		end
	end
	local casterOrigin = caster:GetOrigin()
	local uOrigin = target:GetOrigin()
	
	local time = GameRules:GetGameTime()
	local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_dummy", 
		target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	if dummy then print("unit created") end
	dummy:AddAbility("ability_dota2x_pudgewars_hook_applier")
	local ABILITY_HOOK_APPLIER = dummy:FindAbilityByName("ability_dota2x_pudgewars_hook_applier")
	if ABILITY_HOOK_APPLIER then print("ability successful added") end
	ABILITY_HOOK_APPLIER:SetLevel(1)
	
	dummy:CastAbilityOnTarget(target, ABILITY_HOOK_APPLIER, 0 )
	PudgeWarsGameMode:CreateTimer("damage_dealer_"..tostring(caster)..tostring(GameRules:GetGameTime()),
	{
		endTime = Time() + 0.5,
		callback = function()
			dummy:Destroy()
		end
	})
<<<<<<< HEAD

	

=======
		
>>>>>>> origin/Xavier
	local dmg = tnPlayerHookDamage[plyid]
	print("dmg = "..tostring(dmg).."playerdi"..tostring(plyid))
	local hp = target:GetHealth()
	print(" hp = "..tostring(hp))
	if dmg < hp then
		-- take away health directly
<<<<<<< HEAD
		if caster:GetTeam() ~= target:GetTeam() then
			target:SetHealth(hp-dmg)
			-- think about naix jaw
			local itemName = ItemThinker:FindItemFuzzy(caster, "naix_jaw")
			if  itemName then
				print("NAIX JAW FOUND ADDING HEALTH")
				local index = ParticleManager:CreateParticle("life_stealer_infest_emerge_clean_lights",PATTACH_CUSTOMORIGIN,caster)
				local offsetVec = Vector(0,0,150)
				ParticleManager:SetParticleControl(index,0,caster:GetOrigin() + offsetVec)
				ParticleManager:ReleaseParticleIndex(index)
				local lifestealpercent = string.sub(itemName,-1,-1)
				lifestealpercent = (tonumber(lifestealpercent) * 5 + 5)/100
				if caster:GetMaxHealth() - caster:GetHealth() < dmg * lifestealpercent then
					caster:SetHealth(caster:GetMaxHealth())
				else
					caster:SetHealth(caster:GetHealth() + dmg * lifestealpercent )
				end
			end
		end
=======
		target:SetHealth(hp-dmg)
>>>>>>> origin/Xavier
	else
		-- ADD THE ABILITY "ability_deal_the_last_hit" AND DEAL DAMAGE WITH THE SPELL
		dealLastHit(caster,unit)
	end
	
	--THINK ABOUT HEADSHOT AND DENY
	


	
	if target:GetTeam() == caster:GetTeam() then
		tbHookByAlly[unit] = true
	else
		tbHookByAlly[unit] = false
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

		local ABILITY_SETTING_HOOK_DIRECTION = caster:FindAbilityByName("dota2x_pudgewars_release_hook")
		if caster:HasModifier( "pudgewars_setting_hook" ) then caster:RemoveModifierByName("pudgewars_setting_hook") end
		
		if ABILITY_SETTING_HOOK_DIRECTION then 
			local ABILITY_HOOK = caster:FindAbilityByName("dota2x_pudgewars_hook")
			if ABILITY_HOOK then ABILITY_HOOK:SetLevel(1) end
			caster:RemoveAbility("dota2x_pudgewars_release_hook")
			caster:AddAbility("dota2x_pudgewars_hook")
		end


		if uHead ~= nil and 
			tHookElements[nPlayerID].Target == nil and
			not tbPlayerHookingBack[nPlayerID] then

			if tHookElements[nPlayerID].CurrentLength == nil then 
				tHookElements[nPlayerID].CurrentLength = 2 
			else 
				tHookElements[nPlayerID].CurrentLength = tHookElements[nPlayerID].CurrentLength + 1 
			end

			if tHookElements[nPlayerID].CurrentLength 
				* PER_HOOK_BODY_LENGTH 
					* tnPlayerHookSpeed[nPlayerID] 
						> tnPlayerHookLength[nPlayerID] 
			then
				tbPlayerHookingBack[nPlayerID] = true
				return 
			else
				local vec3 = Vector(
					 headOrigin.x + headFV.x * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
					,headOrigin.y + headFV.y * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
					,headOrigin.z
				)
				uHead:SetOrigin(vec3)
				local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBDType[ nPlayerID ], PATTACH_CUSTOMORIGIN, caster )
				tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body + 1] = {
				    index = nFXIndex,
				    vec = vec3
				}

				tvec3 = vec3
				tvec3.z = vec3.z + 150
				ParticleManager:SetParticleControl( nFXIndex, 0, tvec3)
				ParticleManager:SetParticleControl( nFXIndex, 1, tvec3)
				ParticleManager:SetParticleControl( nFXIndex, 2, tvec3)
				ParticleManager:SetParticleControl( nFXIndex, 3, tvec3)
				ParticleManager:SetParticleControl( paHead, 0, tvec3 )

				tHookElements[nPlayerID].Target = GetHookedUnit(caster , uHead , nPlayerID)
				
				if tHookElements[nPlayerID].Target then
					tbPlayerHookingBack[nPlayerID]  = true
					HookUnit( tHookElements[nPlayerID].Target , caster ,nPlayerID)
					return
				end
			end
		else
			local backVec = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].vec
			local paIndex = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].index

			ParticleManager:SetParticleControl( paIndex, 0, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 1, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 2, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 3, WORLDMAX_VEC)
			ParticleManager:ReleaseParticleIndex( paIndex )

			tbackVec = backVec
			ParticleManager:SetParticleControl( paHead, 0, backVec )
			tbackVec.z = tbackVec.z - 150
			uHead:SetOrigin(backVec)
			if tHookElements[nPlayerID].Target then 
				tHookElements[nPlayerID].Target:SetOrigin(backVec)
			end
			table.remove(tHookElements[nPlayerID].Body,#tHookElements[nPlayerID].Body)

			if #tHookElements[nPlayerID].Body == 0 then
				if tHookElements[nPlayerID].Target ~= nil then
					if tHookElements[nPlayerID].Target:IsAlive() then
						tHookElements[nPlayerID].Target:AddNewModifier(tHookElements[nPlayerID].Target,nil,"modifier_phased",{})
						tHookElements[nPlayerID].Target:RemoveModifierByName("modifier_phased")
						tHookElements[nPlayerID].Target:RemoveModifierByName( "modifier_pudgewars_hooked" )
					end
				end
				
				hooked = false
				tHookElements[nPlayerID].CurrentLength = nil
				uHead:Remove()
				tHookElements[nPlayerID].Head.unit = nil
				ParticleManager:SetParticleControl( paHead, 0, WORLDMAX_VEC)
				ParticleManager:ReleaseParticleIndex(paHead)
				tHookElements[nPlayerID].Body = {}
				tHookElements[nPlayerID].Target = nil
				tbPlayerFinishedHook[nPlayerID] = true
			end
		end
	end	
end

function OnUpgradeHookDamage(keys)
	print("upgrading damage")
	PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrage_hook_damage")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_damage_not_enough_gold",false)
	end
end

function OnUpgradeHookRadius( keys )
	print("upgrading radius")

	PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	
	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_radius")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_radius_not_enough_gold",false)
	end
end

function OnUpgradeHookLength( keys )
	print("upgrading length")

	PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_length")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookLengthCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_length_not_enough_gold",false)
	end
end

function OnUpgradeHookSpeed( keys )
	print("upgrading speed")

	PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_speed")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_speed_not_enough_gold",false)
	end
end

function OnUpgradeHookDamageFinished( keys )

	PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrage_hook_damage")
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

	PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()

	local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_radius")
	local nCurrentLevel = hHookAbility:GetLevel()
	
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

	PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeLengthCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_length")
	local nCurrentLevel = hHookAbility:GetLevel()
	
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

	PrintTable(keys)
	local caster    = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_speed")
	local nCurrentLevel = hHookAbility:GetLevel()
	

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
	if tbPlayerOutterHook[nPlayerID] then
		print("change from on to off")
		local ABILITY_OUTTER_HOOK = caster:FindAbilityByName("dota2x_pudgewars_toggle_hook")
		ABILITY_OUTTER_HOOK:__KeyValueFromString("AbilityTextureName","pudgewars_toggle_outter_hook_off")
		tbPlayerOutterHook[nPlayerID] = false
	else
		print("change from of to on")
		local ABILITY_OUTTER_HOOK = caster:FindAbilityByName("dota2x_pudgewars_toggle_hook")
		ABILITY_OUTTER_HOOK:__KeyValueFromString("AbilityTextureName","pudgewars_toggle_outter_hook_on")
		tbPlayerOutterHook[nPlayerID] = true
	end
end