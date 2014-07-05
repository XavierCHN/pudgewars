print("![PudgeWars] Hello World")

developmentmode = false
TIMER_USE_GAME_TIME =  true

STARTING_GOLD = 50000
DOTA2XGAMEMODE_PLACEHOLDER = nil
GameMode = nil

if PudgeWarsGameMode == nil then
    print ( '[pudgewars] create pudgewars game mode' )
    PudgeWarsGameMode = {}
    PudgeWarsGameMode.szEntityClassName = "pudgewars"
    PudgeWarsGameMode.szNativeClassName = "dota_base_game_mode"
    PudgeWarsGameMode.__index = PudgeWarsGameMode
end

function PudgeWarsGameMode:new( o )
    print ( '[pudgewars] new' )
    o = o or {}
    setmetatable( o, self )
    return o
end

function PudgeWarsGameMode:InitGameMode()
    print('[PudgeWars] Starting to load PudgeWars gamemode...')

    GameRules:SetHeroRespawnEnabled( false )
    GameRules:SetUseUniversalShopMode( false )
    GameRules:SetSameHeroSelectionEnabled( true )
    GameRules:SetPreGameTime( 30.0)
    GameRules:SetPostGameTime( 60.0 )
    GameRules:SetTreeRegrowTime( 60.0 )
    GameRules:SetUseCustomHeroXPValues ( false )
    GameRules:SetGoldPerTick(0)
    print('[PudgeWars] Rules set')

    ListenToGameEvent('entity_killed', Dynamic_Wrap(PudgeWarsGameMode, 'OnEntityKilled'), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(PudgeWarsGameMode, 'AutoAssignPlayer'), self)
    --ListenToGameEvent('player_disconnect', Dynamic_Wrap(PudgeWarsGameMode, 'CleanupPlayer'), self)
    --ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(PudgeWarsGameMode, 'ShopReplacement'), self)
    ListenToGameEvent('player_say', Dynamic_Wrap(PudgeWarsGameMode, 'PlayerSay'), self)
    --ListenToGameEvent('player_connect', Dynamic_Wrap(PudgeWarsGameMode, 'PlayerConnect'), self)
    --ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(PudgeWarsGameMode, 'AbilityUsed'), self)
    
    Convars:RegisterCommand('fake', function()
            self:CreateTimer('assign_fakes', {
                endTime = Time(),
                callback = function(PudgeWars, args)
                    for i=0, 9 do
                        if PlayerResource:IsFakeClient(i) then
                            local ply = PlayerResource:GetPlayer(i)
                            if ply then
                                CreateHeroForPlayer('npc_dota2x_pudgewars_pudge', ply)
                            end
                        end
                    end
                end})
    end, 'Connects and assigns fake Players.', 0)

    local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
    math.randomseed(tonumber(timeTxt))

    --Init Timers
    self.timers = {}

    --Init UserMap
    self.vUserNames = {}
    self.vUserIds = {}
    self.vSteamIds = {}
    self.vBots = {}
    self.vBroadcasters = {}
    self.vPlayers = {}
    self.vRadiant = {}
    self.vDire = {}
    self.vPlayerHeroData = {}

    self.RadiantScore = 0
    self.DireScore = 0

    initHookData()
    self.t0 = 0
    PrecacheUnitByName('npc_precache_everything')
    print('[PudgeWars] Done loading PudgeWars gamemode!\n\n')

end

function PudgeWarsGameMode:GetPudgeWarsScore(team)
    if team == DOTA_TEAM_GOODGUYS then
        return self.RadiantScore
    elseif team == DOTA_TEAM_BADGUYS then
        return self.DireScore
    else
        print("invalid request")
        return nil
    end
end

function PudgeWarsGameMode:AddPudgeWarsScore(team,value)
    if team == DOTA_TEAM_GOODGUYS then
        self.RadiantScore = self.RadiantScore + value
        return 1
    elseif team == DOTA_TEAM_BADGUYS then
        self.DireScore = self.DireScore + value
        return 2
    else
        print("invalid request")
        return nil
    end
end

function PudgeWarsGameMode:CaptureGameMode()
    if GameMode == nil then
        GameMode = GameRules:GetGameModeEntity()        
        GameMode:SetRecommendedItemsDisabled( true )
        GameMode:SetCameraDistanceOverride( 1154.0 )
        GameMode:SetCustomBuybackCostEnabled( true )
        GameMode:SetCustomBuybackCooldownEnabled( true )
        GameMode:SetBuybackEnabled( false )
        GameMode:SetTopBarTeamValuesOverride ( true )
        GameMode:SetUseCustomHeroLevels ( false )
        GameRules:SetHeroMinimapIconSize( 300 )
        GameRules:SetHeroRespawnEnabled(true)

        GameMode:SetContextThink("PudgewarsThink", Dynamic_Wrap( PudgeWarsGameMode, 'Think' ), 0.1 )
        print("[PudgeWars] Pudgewars game mode begin to think")

    end 
end

function PudgeWarsGameMode:Think()
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        return
    end

    local now = GameRules:GetGameTime()
    if PudgeWarsGameMode.t0 == nil or PudgeWarsGameMode == 0 then
        PudgeWarsGameMode.t0 = now
    end
    local dt = now - PudgeWarsGameMode.t0
    PudgeWarsGameMode.t0 = now

    for k,v in pairs(PudgeWarsGameMode.timers) do
        local bUseGameTime = TIMER_USE_GAME_TIME
        if v.useGameTime and v.useGameTime == true then
            bUseGameTime = true;
        end
        if (bUseGameTime and GameRules:GetGameTime() > v.endTime) or (not bUseGameTime and Time() > v.endTime) then
            PudgeWarsGameMode.timers[k] = nil
            print("timer"..tostring(k).."triggered")
            local status, continousTimer = pcall(v.callback, PudgeWarsGameMode, v)
            
            -- Make sure it worked
            if not status then
                -- Nope, handle the error
                PudgeWarsGameMode:HandleEventError('Timer', k, continousTimer)
            end
        end
    end

    return dt
end
function PudgeWarsGameMode:AutoAssignPlayer(keys)
    -- if any player connected, then start theh game mode
    PudgeWarsGameMode:CaptureGameMode()

    print ('[pudgewars] AutoAssignPlayer Fired')
    PrintTable (keys)
    local entIndex = keys.index + 1
    local ply = EntIndexToHScript(entIndex)
    local playerID = ply:GetPlayerID()
    
    -- If we're not on D2MODD.in, assign players round robin to teams
    if playerID == -1 then
        if #self.vRadiant > #self.vDire then
            ply:SetTeam(DOTA_TEAM_BADGUYS)
            ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_BADGUYS)
            table.insert (self.vDire, ply)
        else
            ply:SetTeam(DOTA_TEAM_GOODGUYS)
            ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_GOODGUYS)
            table.insert (self.vRadiant, ply)
        end
        playerID = ply:GetPlayerID()
    end

    --Autoassign player
    self:CreateTimer('assign_player_'..entIndex, {
        endTime = Time(),
        callback = function(pudgewars, args)
            local heroEntity = ply:GetAssignedHero()
            if heroEntity == nil then
                print("ply hero entity = nil reassign it ")
                CreateHeroForPlayer('npc_dota_hero_pudge', ply)
                heroEntity = ply:GetAssignedHero()
                ABILITY = heroEntity:FindAbilityByName("ability_pudgewars_hook")
                if ABILITY then ABILITY:SetLevel(1) end
                ABILITY = heroEntity:FindAbilityByName("ability_pudgewars_toggle_hook")
                if ABILITY then ABILITY:SetLevel(1) end
                ABILITY = heroEntity:FindAbilityByName("ability_pudgewars_upgrade_damage")
                if ABILITY then ABILITY:SetLevel(1) end
                ABILITY = heroEntity:FindAbilityByName("ability_pudgewars_upgrade_radius")
                if ABILITY then ABILITY:SetLevel(1) end
                ABILITY = heroEntity:FindAbilityByName("ability_pudgewars_upgrade_length")
                if ABILITY then ABILITY:SetLevel(1) end
                ABILITY = heroEntity:FindAbilityByName("ability_pudgewars_upgrade_speed")
                if ABILITY then ABILITY:SetLevel(1) end
                heroEntity:SetAbilityPoints(0)
            end
        end
    })
end

function PudgeWarsGameMode:HandleEventError(name, event, err)
    print(err)
    name = tostring(name or 'unknown')
    event = tostring(event or 'unknown')
    err = tostring(err or 'unknown')
    Say(nil, name .. ' threw an error on event '..event, false)
    Say(nil, err, false)
    if not self.errorHandled then
        self.errorHandled = true
    end
end

function PudgeWarsGameMode:CreateTimer(name, args)
    if not args.endTime or not args.callback then
        print("Invalid timer created: "..name)
        return
    end
    self.timers[name] = args
end

function PudgeWarsGameMode:RemoveTimer(name)
    self.timers[name] = nil
end

function PudgeWarsGameMode:RemoveTimers(killAll)
    local timers = {}
    if not killAll then
        for k,v in pairs(self.timers) do
            if v.continousTimer then
                timers[k] = v
            end
        end
    end
    self.timers = timers
end

function PudgeWarsGameMode:OnEntityKilled(keys)
    PrintTable(keys)
    local killedUnit = EntIndexToHScript(keys.entindex_killed)
    if killedUnit:GetUnitName() == "npc_dota_hero_pudge" or 
        killedUnit:GetUnitName() == "npc_dota2x_pudgewars_pudge" then
        if killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS then self:AddPudgeWarsScore(DOTA_TEAM_BADGUYS,1) end
        if killedUnit:GetTeam() == DOTA_TEAM_BADGUYS then self:AddPudgeWarsScore(DOTA_TEAM_GOODGUYS,1) end
        GameMode:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,PudgeWarsGameMode:GetPudgeWarsScore(DOTA_TEAM_GOODGUYS))
        GameMode:SetTopBarTeamValue(DOTA_TEAM_BADGUYS,PudgeWarsGameMode:GetPudgeWarsScore(DOTA_TEAM_BADGUYS))
    end
end


function PudgeWarsGameMode:PlayerSay(keys)
    PrintTable(keys)
    local speakstring = keys.text
    if string.find(speakstring,"geiwoqian") then
        for i = 0,9 do
            PlayerResource:SpendGold(i,-10000,0)
        end
    end
end
