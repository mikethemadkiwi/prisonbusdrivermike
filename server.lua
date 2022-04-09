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