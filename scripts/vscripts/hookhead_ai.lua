tHookBlockWalls = {}

function AddWall(keys)
  print("an wall add to game")
  PrintTable(keys)
  local caster =  EntToHscript(keys.caster_entindex)
  local point  = keys.target_points[1]
  if not (caster and point) then
    print("caster or point invalid")
    return
  else
    local vOrigin = caster:GetOrigin()
    local vOFV = caster:GetForwardVector()
    local vTargetPos = point
    local ability = keys.abilityname
    local ABILITY_WALL = caster:FindAbilityByName("ability")
    local nWallLength = ABILITY:GetSpecialValueOf("wall_length")
    
    local vDirectionStart = Vector(-vOFV.y ,  vOFV.x , vOFV.z)
    local vDirectionEnd   = Vector( vOFV.y , -vOFV.x , vOFV.z)
    local vStartPos = vTargetPos + ( vDirectionStart * nWallLength / 2 )
    local vEndPos   = vTargetPos + ( vDirectionEnd   * nWallLength / 2 )
    
    local tWall = {
      owner = caster,
      vStart = vStartPos,
      vEnd   = vEndPos,
      id = tostring(caster) + tostring(GameRules:GetGameTime())
    }
    print("wall successfull add"..tWall.id)
    table.insert(tHookBlockWalls,tWall)
  end
end

function ThinkOfWallDisappear()
  local caster =  EntToHscript(keys.caster_entindex)
  for k,v in pairs(tHookBlockWalls) do
    if v.onwer == caster then
    	print("an wall removed"..v.id)
    	table.remove(tHookBlockWalls,k)
    end
  end
end

function PudgeWarsGameMode:HookHeadTHink()
  PrintTable(keys)
  
  if keys.think_entity == nil then
    print("add think to hook head failed")
    return
  else
    thisEntity = keys.think_entitiy
  end
  
  ThinkOfWallDisappear()
  for k,v in pairs(tHookBlockWalls) do
    local triggerLength = 50
    local tHook = {
      vStart = thisEntity:GetOrigin(),
      vEnd   = thisEntity:GetOrigin() + thisEntity:GetForwardVector() * triggerLength
    }
    local cross = thinkCross(tHook , v)
    if cross then
      local originFV = thisEntity:GetForwardVector()
      local Ms = math.sqrt(originFV.x * originFV.x + originFV.y * originFV.y)
      local Ds = originFV.y * -corss.x/Ms + originFV.x * cross.y / Ms
      local resultFV = Vector(originFV.x - 2 * cross.y * Ds/Ms, cross.y + 2*originFV.x * Ds / Ms ,originFV.z)
      thisEntity:SetForwardVector( resultFV )
    end
  end
end
