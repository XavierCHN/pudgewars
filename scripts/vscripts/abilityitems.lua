if ItemThinker == nil then
    ItemThinker = {}
end

function ItemThinker:GetItems( player )
    local items = {}
    for i = 0,5 do
        local item = player:GetItemInSlot(i)
        if item then
            table.insert(items,item)
        end
    end
    return items
end

function ItemThinker:HasItem( player , itemname)
    local items = self:GetItems(player)
    for k,v in pairs(items) do
        if v:GetName() == itemname then
            return v:GetName()
        end
    end
    return false
end

function ItemThinker:FindItemFuzzy( player , itemname)
    local items = self:GetItems(player)
    for k,v in pairs(items) do
        if string.find(v:GetName(),itemname) then
            return v:GetName()
        end
    end
    return false
end

function ItemThinker:HasMItem(player , itemname )
    local items = self:GetItems(player)
    for k,v in pairs(items) do
        print("HasMItem.."..k..v:GetName())
        for i = 1,5 do
            if v:GetName() == itemname..tostring(i) then
                return true
            end
        end
    end
    return false
end

function ItemThinker:SerBarrel( keys )
    local caster = EntIndexToHScript(keys.caster_entindex)
    if caster then
        local nPlayerID = caster:GetPlayerID()
        local plantVec = Vector(0,0,0)
        if tHookElements[nPlayerID].Head.unit == nil then
            plantVec = caster:GetOrigin()
        else
            plantVec = tHookElements[nPlayerID].Head.unit:GetOrigin()
        end
        local dummy = CreateUnitByName("npc_dota2x_pudgewars_unit_bomb", 
        target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
        PudgeWarsGameMode:CreateTimer("bombisset"..tostring(dummy),{
            endTime = Time() + 2,
            callback = function()
                local o = dummy:GetOrigin()
                local index = ParticleManager:CreateParticle(
                    "rattletrap_cog_ambient",
                    o,
                    caster)
                local offset = Vector(0,0,20)
                ParticleManager:SetParticleControl(index,0,o)
                PudgeWarsGameMode:CreateTimer("bombtrigger"..tostring(dummy),{
                    endTime = Time() + 0.1,
                    callback = function()
                        -- find unit in radius within hook radius   
                        local tBombTargets = FindUnitsInRadius(
                            caster:GetTeam(),       --caster team
                            head:GetOrigin(),       --find position
                            nil,                    --find entity
                            tnPlayerHookRadius[plyid],          --find radius
                            DOTA_UNIT_TARGET_TEAM_ENEMY,
                            DOTA_UNIT_TARGET_ALL, 
                            0, FIND_CLOSEST,
                            false
                        )

                        if #tBombTargets >= 1 then
                            for k,v in pairs(tBombTargets) do
                                -- harm pudge only
                                if v:GetName() ~= "npc_dota2x_pudgewars_pudge" then
                                    table.remove(tBombTargets,k)
                                end
                            end
                        end
                        if #tBombTargets >=1 then
                            for k,v in pairs(tBombTargets) do
                                local hp = v:GetHealth()
                                local dmg = 200
                                if dmg > hp then
                                    dealLastHit(caster,v)
                                else
                                    v:SetHealth(hp-dmg)
                                end
                            end
                            PudgeWarsGameMode:RemoveTimer("bombtrigger"..tostring(dummy))
                        end
                    end
                    })
            end
            })
    end

end