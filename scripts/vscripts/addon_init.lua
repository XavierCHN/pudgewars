print ( '[PudgeWars] Addon Init' )

local function loadModule(name)
    local status, err = pcall(function()
        -- Load the module
        require(name)
    end)

    if not status then
        -- Tell the user about it
        print('WARNING: '..name..' failed to load!')
        print(err)
    end
end

function Dynamic_Wrap( mt, name )
    if Convars:GetFloat( 'developer' ) == 1 then
        local function w(...) return mt[name](...) end
        return w
    else
        return mt[name]
    end
end

InitLogFile("log/pudgewars.txt","init pudgewars")

loadModule ( 'util' )
loadModule ( 'pudgewars' )
loadModule ( 'abilityhook' )