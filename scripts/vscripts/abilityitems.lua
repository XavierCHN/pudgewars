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