--
function AuthCheck(source)
    -- put your qbcore or esx code for job rank or role here.
    -- if the player has a rank, and it matches the one you want...
    -- send a true return.. otherwise, send a false return.

    return true
end
--
local busid = 1
ActivePrisonBuses = {}
RegisterServerEvent('pbdm:requestbus')
AddEventHandler('pbdm:requestbus', function(zData)
    local tmpBusObj = {busid, zData}
    busid = busid + 1
    if AuthCheck(source) then
        print('Prison Bus Requested ['..zData.name..'] - '..source..'')
        TriggerClientEvent('pbdm:createbus', source, tmpBusObj)
    else
        TriggerClientEvent('pbdm:errormsg', source, 'unable to spawn you a prison bus. (perms) ')
    end
end)
--
RegisterServerEvent('pbdm:requestbus')
AddEventHandler('pbdm:requestbus', function(bData)
    table.insert(ActivePrisonBuses, bData)
end)

RegisterServerEvent('pbdm:makepass')
AddEventHandler('pbdm:makepass', function(bId)
    TriggerClientEvent('pbdm:makeclientpass', -1, bId)
    print('['.. source ..'] spawned BusId:'.. bId[1] ..' NetId:'.. bId[2] ..'')
end)

RegisterServerEvent('pbdm:delpass')
AddEventHandler('pbdm:delpass', function(bId)
    TriggerClientEvent('pbdm:delclientpass', -1, bId)
end)