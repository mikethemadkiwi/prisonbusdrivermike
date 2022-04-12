local busid = 1
ActivePrisonBuses = {}
--
RegisterServerEvent('pbdm:requestbus')
AddEventHandler('pbdm:requestbus', function(zData)
    local tmpBusObj = {busid, zData}
    busid = busid + 1
    print('Prison Bus Requested ['..zData.name..'] - '..source..'')
    TriggerClientEvent('pbdm:createbus', source, tmpBusObj)
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