local busid = 1
ActivePrisonBuses = {}
--
RegisterServerEvent('pbdm:requestbus')
AddEventHandler('pbdm:requestbus', function(zData)
    local tmpBusObj = {busid, zData}
    busid = busid + 1
    TriggerClientEvent('pbdm:createbus', source, tmpBusObj)
end)