
WORLDMAX_VEC = Vector(GetWorldMaxX(),GetWorldMaxY(),0)
PER_HOOK_BODY_LENGTH = 100

HEAD_SHOT_SCORE = 3
DENY_SCORE = 2
HOOK_KILL_SCORE = 1

MAX_SCORE = 100

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


tnHookDamage  = {175 , 250 , 350 , 500  }
tnHookLength  = {1400 , 1500 , 1600 , 1800 }
tnHookRadius  = {80  , 120  , 150  , 200   }
tnHookSpeed   = {0.10 , 0.14 , 0.18 , 0.22  }

tnUpgradeHookDamageCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookLengthCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookRadiusCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookSpeedCost  = {500 , 1000 , 1500 , 2000  }

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
 	"npc_dota_neutral_blue_dragonspawn_overseer",
	"npc_dota2x_pudgewars_gold",
 	"npc_dota_necronomicon_warrior_2",
 	"npc_dota_warlock_golem_3",
 	"npc_dota2x_pudgewars_unit_bomb"
}

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
local function InitHookParameters(nPlayerID)
	--init hook parameters
	tbPlayerHooking[nPlayerID] = false
	tbPlayerFinishedHook[nPlayerID] = false
	tbPlayerHookingBack[nPlayerID] = false
	tHookElements[nPlayerID].Target = nil
	tHookElements[nPlayerID].CurrentLength = nil
	tnHookTurbineBonusDamage[nPlayerID] = 0
end
function OnHookStart(keys)
	local targetPoint = keys.target_points[1]
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = keys.unit:GetPlayerID()
	print("player "..nPlayerID.." start A Hook")
	print(keys.caster_entindex)
	-- if there is already a hook, return
	if tHookElements[nPlayerID].Head.unit ~= nil then return end
	InitHookParameters(nPlayerID)
	-- create the hook head
	local unit = CreateUnitByName(
		 GetHookType(nPlayerID)
		,caster:GetOrigin()
		,false,caster,caster,caster:GetTeam())
	if unit then
		unit:EmitSound("Hero_Pudge.AttackHookExtend")
		-- store the head
		tHookElements[nPlayerID].Head.unit = unit
		-- set the head model scale to the hook radius
		unit:SetModelScale((tnPlayerHookRadius[nPlayerID]/80)*0.8,0)
		-- set head forward vector
		local diffVec = targetPoint - caster:GetOrigin()
		diffVec.z = 0
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
	end
end

function OnHookSet(keys)
	local targetPoint = keys.target_points[1]
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = keys.unit:GetPlayerID()
	print("player "..nPlayerID.." set A Hook")
	-- if there is a hook already, return
	if tHookElements[nPlayerID].Head.unit ~= nil then
		return
	end
	-- init hook parameters
	InitHookParameters(nPlayerID)
	-- create the hook head
	local unit = CreateUnitByName(
		 GetHookType(nPlayerID)
		,targetPoint
		,false,caster,caster,caster:GetTeam())
	if unit then
		unit:EmitSound("Hero_Pudge.AttackHookExtend")
		-- store the head
		tHookElements[nPlayerID].Head.unit = unit
		-- set the head model scale to the hook radius
		unit:SetModelScale((tnPlayerHookRadius[nPlayerID]/80)*0.8,0)
		-- set head forward vector
		local diffVec = targetPoint - caster:GetOrigin()
		diffVec.z = 0
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

		--init hook parameters
		tbPlayerHooking[nPlayerID] = false
		tbPlayerFinishedHook[nPlayerID] = false
		tbPlayerHookingBack[nPlayerID] = false
		tHookElements[nPlayerID].Target = nil
		tHookElements[nPlayerID].CurrentLength = nil
		tHookElements[nPlayerID].Head.unit = nil

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
		350,			        --find radius
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_ALL,
		0, FIND_CLOSEST,
		false
	)

	-- remove all useless untis
	if #tuHookedUnits >= 1 then
		for k,v in pairs(tuHookedUnits) do
			--print("found something"..v:GetUnitName())
			--think about barriers
			if v:GetUnitName() == "npc_pudge_wars_barrier" then
					--print("barrier found")
					local headFV = head:GetForwardVector()
					local wallFV = v:GetForwardVector()
					local wallOrigin = v:GetOrigin()
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

					--x1x2+y1y2/根号下（x1^2+x2^2)+根号下(y1^2+y2^2)
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
							print("barrier catched:"..tostring(v))
							if not tbBarrierBonusDamageTriggered[v][plyid] then
								local itemTurbine = ItemThinker:FindItemFuzzy(caster,"item_pudge_ricochet_turbine")
								if itemTurbine then
									local itemLevel = string.sub(itemTurbine,-1,-1)
									print("ITEAM RICOCHET TURBINE FOUND LEVEL:"..itemLevel)
									--100 150 200 250 300
									local bonusDmg = 50 + 50 * tonumber(itemLevel)
									print("add turbine bonus damage for player id:"..tostring(plyid))
									tnHookTurbineBonusDamage[plyid] = tnHookTurbineBonusDamage[plyid] + bonusDmg
									tbBarrierBonusDamageTriggered[v][plyid] = true
								end
							end
						end
					end
			end
			local va = false
			for s,t in pairs (tPossibleHookTargetName) do
				if v:GetUnitName() == t then
					va = true
					if t == "npc_dota2x_pudgewars_unit_bomb" and tuBombPlanter[v] == head then
						print("catch a bomb but its created by this head, ignore")
						va = false
					elseif t == "npc_dota2x_pudgewars_unit_bomb" and tuBombPlanter[v] ~= head then
						print("bomb not created by this head,catch it")
					end
				end
			end
			if ( not va ) or ( v == caster )  or
				distance (head:GetOrigin(),v:GetOrigin()) > tnPlayerHookRadius[plyid]
				then
				tuHookedUnits[k] = nil
			end
		end
	end
	
	-- if there is units left then catch it
	for k,v in pairs(tuHookedUnits) do
		if v ~= nil then
			return v
		end
	end
	return nil
end

-- a function to deal lasthit

function dealLastHit( caster,target )
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

-- catch the hook unit
local function HookUnit( target , caster ,plyid )
	--print ( "hooked something" )
	--print ( "the enemy name "..target:GetUnitName())
	target:EmitSound("Hero_Pudge.AttackHookImpact")
	--if the unit is already hooked by someone
	if target:HasModifier("modifier_pudgewars_hooked") then
		if target:GetTeam() ~= caster:GetTeam() then
			--HEAD SHOT
			--print("unit has been hooked and its an enemy")
			--print("head shot fired")
			dealLastHit(caster,target)
			local msg = {
			message = "#pudgewars_head_shot",
			duration = 1
			}
			FireGameEvent('show_center_message',msg)
			AddScore(caster:GetTeam(),HEAD_SHOT_SCORE)
			caster:EmitSound("PudgeWars.Head.Shot")
			return

		elseif target:GetTeam() == caster:GetTeam() 
			and not tbHookByAlly[target] then
			--DENIED
			--print("deny fired")
			dealLastHit(caster,target)
			local msg = {
				message = "#pudgewars_denied",
				duration = 1
				}
			FireGameEvent('show_center_message',msg)
			--print("team:"..tostring(caster:GetTeam()))
			AddScore(caster:GetTeam(),DENY_SCORE)
			return

		end
	else
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
			endTime = Time()+ 0.1,
			callback = function()
				if IsValidEntity(dummy) then dummy:Destroy() end
			end
		})

		-- todo add bonus damage according to hook head refract
		local dmg = tnPlayerHookDamage[plyid]
		local bonusdamage = 0
		
		-- think about barathon's latern item
		local itemLatern = ItemThinker:FindItemFuzzy(caster,"item_pudge_barathrum_lantern")
		--print("trying to find latern"..tostring(itemlaLatern))
		if itemLatren then
			local itemLevel = string.sub(itemLatern,-1,-1)
			print("ITEM LATERN FOUND LV :"..tostring(itemLevel))
			-- 15% 20% 25% 30% 45%
			bonusdamage = (tonumber(itemLevel) * 5 + 10 / 100) * dmg
			target:EmitSound("Hero_Spirit_Breaker.GreaterBash")
		end
		
		-- if the player has the barathon latern, add bonus damage
		dmg = dmg + bonusdamage

		print("item turbine bonus dmg"..tostring(plyid)..":"..tostring(tnHookTurbineBonusDamage[plyid]))
		if tnHookTurbineBonusDamage[plyid] then
			dmg = dmg + tnHookTurbineBonusDamage[plyid]
		end

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
						endTime = Time()+ 0.1,
						callback = function()
							if IsValidEntity(dummy) then dummy:Destroy() end
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

				-- add hook kill score
				AddScore(caster:GetTeam(),HOOK_KILL_SCORE)
			end
		end
		
		--THINK ABOUT HEADSHOT AND DENY
		if target:GetTeam() == caster:GetTeam() then
			tbHookByAlly[target] = true
		else
			tbHookByAlly[target] = false
		end
	end
	
	return 1
end

function OnReleaseHook( keys )
	local caster = EntIndexToHScript(keys.caster_entindex)
	local nPlayerID = caster:GetPlayerID()
	if not tbPlayerFinishedHook[nPlayerID] then
	
		if tHookElements[nPlayerID] == nil then print("hook elements not found returning") return end
		local uHead = tHookElements[nPlayerID].Head.unit
		if not uHead then  print("FATAL: UNIT HEAD NOT FOUND")  return end
		if not IsValidEntity(uHead) then print("not a valid entity") return end
		if not uHead:IsAlive() then print("the head is dead ") return end
		local headOrigin = uHead:GetOrigin()
		local paHead = tHookElements[nPlayerID].Head.index
		local headFV = uHead:GetForwardVector()

		tbPlayerHooking[nPlayerID] = true
		
		-- clear outter hook modifiers and ability
		local ABILITY_RELEASE_HOOK = caster:FindAbilityByName("ability_pudgewars_release_hook")
		if ABILITY_RELEASE_HOOK then 
			caster:RemoveAbility("ability_pudgewars_release_hook")
			caster:AddAbility("ability_pudgewars_hook")
			local ABILITY_HOOK = caster:FindAbilityByName("ability_pudgewars_hook")
			if ABILITY_HOOK then ABILITY_HOOK:SetLevel(1) end
		end

		if caster:HasModifier( "pudgewars_setting_hook" ) then caster:RemoveModifierByName("pudgewars_setting_hook") end

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
				--return 
			else
				-- if the hook is going out
				-- THINK ABOUT HEAD FORWARD VECTOR FATAL ERROR
				if headFV.x == 0 and headFV.y == 0 then
					print("WARNING: HOOK HEAD IS NOT MOVING")
					say(nil," =>致命错误:钩子朝向错误，取消错误的钩子释放...",false)
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

function ThinkAboutBombTriggered(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local center = caster:GetOrigin()
	local ability = caster:FindAbilityByName("ability_make_bomb_a_bomb")
	local radius = ability:GetSpecialValueFor("Radius")
	local dmg = ability:GetSpecialValueFor("bomb_damage")
	
	local triggeredUnits = nil
	triggeredUnits = FindUnitsInRadius(
		caster:GetTeam(),		--caster team
		center,		--find position
		nil,					--find entity
		200,			--find radius
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
							dealLastHit(caster,v)
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

function OnBombSetFinished( keys )
	local caster = EntIndexToHScript(keys.caster_entindex)
	if caster then
		local sc = caster:GetModelScale()
		sc = sc * 2
		caster:SetModelScale(sc,0)
	end
end



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
