pZoneDebug = true
PBDMConf = {
	busModel='pbus',
    -- drivingStyle = 786603
    drivingStyle = 411
}
--
pedGroup = nil
pZones = {}
IsInPbusZone = false
currentZone = nil
--
PBusSigns = {}
CurrentDriver = nil
CurrentPbus = nil
CurrentDepot = nil
CanDrive = false
sLimit = 5.0
PrisonDepot = { 
    {
        uid = 'prisonbus_1',
        name = "Bolingbroke Penitentiary",
        aZone = 153,
        zones = {
            menu = {x = 1817.217, y = 2599.202, z = 44.523},
            passenger = {x = 1801.599, y = 2609.289, z = 44.565},
            departure = {x = 1800.453, y = 2607.865, z = 45.823, h = 269.899}, -- location leaving FROM
            recieving = {x = 472.07, y = -1023.654, z = 28.416, h = 279.469} -- location heading TO
        },
        blip = {sprite = 58, color = 8, scale = 0.5}
    },
    {
        uid = 'prisonbus_2',
        name = "Mission Row Police Station",
        aZone = 139,
        zones = {
            menu = {x = 472.854, y = -1019.361, z = 27.118},
            passenger = {x = 473.6, y = -1024.8, z = 28.1},
            departure = {x = 472.343, y = -1023.378, z = 28.407, h = 275.562},
            recieving = {x = 1799.957, y = 2607.87, z = 45.823, h = 91.443}
        },
        blip = {sprite = 58, color = 8, scale = 0.5}
    }
}
--
function drawOnScreen2D(text, r, g, b, a, x, y, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()    
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end
--
function addBusPZones(depot, radius, useZ, debug, options)
    table.insert(pZones, CircleZone:Create(vector3(depot.zones.menu.x, depot.zones.menu.y, depot.zones.menu.z), radius, {
        name=depot.name,
        useZ=useZ,
        data=depot,
        debugPoly=debug
    }))    
end
--
function CallBusAtZone(zone)
	local zData = zone.data
	print('Bus requested at ['..zData.uid..']')
	TriggerServerEvent('pbdm:requestbus', zData)
end
--
function spawnBusDriver(Depot, cb)
    Citizen.CreateThread(function()
        RequestModel(GetHashKey('u_m_m_promourn_01'))	
        while not HasModelLoaded(GetHashKey('u_m_m_promourn_01')) do
            Wait(1)
        end
        activeDriver = CreatePed(5, 'u_m_m_promourn_01', Depot.zones.menu.x+1.0, Depot.zones.menu.y, Depot.zones.menu.z, 0.0, true, false)        
        activeDriverNetId = NetworkGetNetworkIdFromEntity(activeDriver)
		SetEntityInvincible(activeDriver, true)        
        SetDriverAbility(activeDriver, 1.0)
        SetDriverAggressiveness(activeDriver, 0.0)
        SetPedCanBeDraggedOut(activeDriver, false)
        SetPedStayInVehicleWhenJacked(activeDriver, true)
        SetBlockingOfNonTemporaryEvents(activeDriver, false)
        SetPedCanPlayAmbientAnims(activeDriver, true)
        SetPedRelationshipGroupDefaultHash(activeDriver, pedGroup)
        SetPedRelationshipGroupHash(activeDriver, pedGroup)
        SetCanAttackFriendly(activeDriver, false, false)
        SetPedCombatMovement(activeDriver, 0)
        print('driver spawn:'.. activeDriver .. ' ['..activeDriverNetId..']')
        if cb ~= nil then
			cb({activeDriver, activeDriverNetId})
		end
    end)
end
--
function spawnBusAtDepot(busmodel, x, y, z, heading, driverPed, route, cb)
    local model = (type(busmodel) == 'number' and busmodel or GetHashKey(busmodel))
    Citizen.CreateThread(function()
		RequestModel(model)
		while not HasModelLoaded(model) do
			Citizen.Wait(0)
		end
		activeBus = CreateVehicle(model, x, y, z, heading, true, false)
		activeBusNetId = NetworkGetNetworkIdFromEntity(activeBus)
		SetNetworkIdCanMigrate(activeBusNetId, true)
		SetEntityAsMissionEntity(activeBus, true, false)
		SetVehicleHasBeenOwnedByPlayer(activeBus, false)
        SetDisableVehicleWindowCollisions(activeBus, false)
        SetEntityInvincible(activeBus, true)
		SetVehicleNeedsToBeHotwired(activeBus, false)
		SetModelAsNoLongerNeeded(model)
		RequestCollisionAtCoord(x, y, z)
		while not HasCollisionLoadedAroundEntity(activeBus) do
			RequestCollisionAtCoord(x, y, z)
			Citizen.Wait(0)
		end
		SetVehRadioStation(activeBus, 'OFF')
        print('bus spawn:'.. activeBus .. ' netid: '.. activeBusNetId ..'')
		if cb ~= nil then
			cb({activeBus, activeBusNetId})
		end
	end)
end
--
function DeleteLastBusAndDriver()
    if CurrentPbus ~= nil then
        if DoesEntityExist(CurrentPbus[1]) then
            if IsPedInVehicle(PlayerPedId(), CurrentPbus[1], false) then
                TaskLeaveVehicle(PlayerPedId(), CurrentPbus[1], 0)
            end
            DeleteEntity(CurrentDriver[1])
            DeleteEntity(CurrentPbus[1])
        end
        if not DoesEntityExist(CurrentPbus[1]) and DoesEntityExist(CurrentDriver[1]) then
            DeleteEntity(CurrentDriver[1])
        end
        CurrentPbus = nil
        CurrentDriver = nil
    end
end
--
function putplayerinseat(busid)    
    local numPass = GetVehicleMaxNumberOfPassengers(busid) - 1 
    for j=-1, numPass do
        local isfree = IsVehicleSeatFree(busid, j)        
        if isfree == 1 then
            local playerPed = PlayerPedId()
            TaskEnterVehicle(playerPed, busid, 15000, j, 2.0, 1, 0)
            TriggerServerEvent('bdm:passentered', {busid})
            break
        end        
    end
end
--
RegisterNetEvent('pbdm:createbus')
AddEventHandler('pbdm:createbus', function(bObj)
    CurrentDepot = bObj
    -- check for existing bus i own and delete.
    DeleteLastBusAndDriver()
    CanDrive = false
	-- Driver
	local bDriver = spawnBusDriver(bObj[2], function(driverData)
        CurrentDriver = driverData
		local bVehicle = spawnBusAtDepot(PBDMConf.busModel, bObj[2].zones.departure.x, bObj[2].zones.departure.y, bObj[2].zones.departure.z, bObj[2].zones.departure.h, driverData[1], 1, function(busData)
            CurrentPbus = busData
            print('Bus:'..CurrentPbus[1]..' Driver:'..CurrentDriver[1])
            TriggerServerEvent('pbdm:createdbusinfo', {CurrentDriver, CurrentPbus, bObj})
            --
            SetPedIntoVehicle(CurrentDriver[1], CurrentPbus[1], -1)         
            -----------------------------------------------------
            for i = 0, 1 do
                SetVehicleDoorOpen(CurrentPbus[1], i, false)
            end 
            TriggerServerEvent('pbdm:makepass', {CurrentPbus[1], CurrentPbus[2], bObj})  
            Citizen.Wait(30000)
            TriggerServerEvent('pbdm:delpass', {CurrentPbus[1], CurrentPbus[2], bObj})
            Citizen.Wait(30000)
            for i = 0, 1 do
                SetVehicleDoorShut(CurrentPbus[1], i, false)
            end 
            CanDrive = true
            sLimit = 5.0
            TaskVehicleDriveWander(CurrentDriver[1], CurrentPbus[1], sLimit, 411)
            SetDriveTaskDrivingStyle(CurrentDriver[1], 411)
            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, 411, 5.0)
            -- TaskVehicleDriveToCoord(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, 30.0, 1.0, GetHashKey(CurrentPbus[1]), 411, 1.0, 1)
            -- SetPedKeepTask(CurrentDriver[1], true)
		end)
   	end)
end)
--------------INIT--------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)	
		if NetworkIsPlayerActive(PlayerId()) then
			for j=1, #PrisonDepot do
				addBusPZones(PrisonDepot[j], 1.0, false, pZoneDebug, {})
				PBusSigns[j] = CreateObject(-1022684418, PrisonDepot[j].zones.menu.x, PrisonDepot[j].zones.menu.y, PrisonDepot[j].zones.menu.z, false, false, false)					
			end
			--
			DepotPolyList = ComboZone:Create(pZones, {name="DepotPolyList", debugPoly=polydebug})
			DepotPolyList:onPlayerInOut(function(isPointInside, point, zone)
				if zone then
					if isPointInside then
						currentZone = zone
						IsInPbusZone = true
					  else
						currentZone = nil
						IsInPbusZone = false
					  end
				end
			end)		
			break
		end
	end
end)
--
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then       
        local v, pGroup = AddRelationshipGroup('bdmDrivers')
        pedGroup = pGroup
        print('Added Bus group "bdmDrivers" as ['..pedGroup..']')
    end
end)
--
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for j=1, #PBusSigns do
            DeleteObject(PBusSigns[j])        
        end
    end
end)
--
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsInPbusZone then
			if IsControlJustPressed(0, 51) then
				CallBusAtZone(currentZone)
			end
			if not IsNuiFocused() then
				drawOnScreen2D('~y~Press [ ~g~E~y~ ] to call a Prison Bus.', 255, 255, 255, 255, 0.40, 0.45, 0.6)
			end
		end
	end
end)
--
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if NetworkIsPlayerActive(PlayerId()) then
            if CurrentPbus ~= nil then
                if IsVehicleStuckOnRoof(CurrentPbus[1]) or IsEntityUpsidedown(CurrentPbus[1]) or IsEntityDead(CurrentDriver[1]) or IsEntityDead(CurrentPbus[1]) then
                    DeleteBusAndDriver(CurrentPbus[1], CurrentDriver[1])           
                end
                if CanDrive == true then
                    -- print('yes bus. but can moving.')
                    -- SetVehicleHandbrake(CurrentPbus[1], false) -- hb off
                    SetVehicleDoorsLocked(CurrentPbus[1], 2) -- locked                   
                    local buscoords = GetEntityCoords(CurrentPbus[1])
                    local distancefromstart = GetDistanceBetweenCoords(buscoords[1], buscoords[2], buscoords[3], CurrentDepot[2].zones.departure.x, CurrentDepot[2].zones.departure.y, CurrentDepot[2].zones.departure.z, false)
                    local distancetostop = GetDistanceBetweenCoords(buscoords[1], buscoords[2], buscoords[3], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, false)     
                    drawOnScreen2D('DFS:[ '..distancefromstart..' ] DTS:[ '..distancetostop..' ] @ '..sLimit..' Speed ', 255, 255, 255, 255, 0.45, 0.45, 0.6)
                    -- -- do our ai logic from current location to destination loca.
                    if math.floor(distancefromstart) == 100 then
                        sLimit = 60.0
                        TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, 411, 1.0)
                    --     -- SetPedKeepTask(CurrentDriver[1], true)
                    end
                else
                    -- print('yes bus. but not moving.')
                    -- JFST. just flippin sit there.
                    SetVehicleDoorsLocked(CurrentPbus[1], 1) -- unlocked
                    TaskVehicleTempAction(CurrentDriver[1], CurrentPbus[1], 6, 2000)
                    -- SetVehicleHandbrake(CurrentPbus[1], true)
                    SetVehicleEngineOn(CurrentPbus[1], true, true, false)

                end
            end
        end
	end
end)