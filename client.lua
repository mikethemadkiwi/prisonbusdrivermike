pZoneDebug = true
PBDMConf = {
	busModel='pbus'
}
pZones = {}
PBusSigns = {}
PBUSDepot = {}
CurrentDriver = nil
CurrentPbus = nil
IsInPbusZone = false
currentZone = nil
PrisonDepot = { 
    {
        uid = 'prisonbus_1',
        name = "Bolingbroke Penitentiary",
        aZone = 153,
        zones = {
            menu = {x = 1817.217, y = 2599.202, z = 44.523},
            passenger = {x = 1801.599, y = 2609.289, z = 44.565},
            departure = {x = 1800.453, y = 2607.865, z = 45.823, h = 269.899}, -- location leaving FROM
            recieving = {x = 446.004, y = -1020.88, z = 28.782, h = 279.469} -- location heading TO
        },
        blip = {sprite = 58, color = 8, scale = 0.5}
    },
    {
        uid = 'prisonbus_2',
        name = "Mission Row Police Station",
        aZone = 139,
        zones = {
            menu = {x = 446.645, y = -1011.495, z = 27.528},
            passenger = {x = 440.5, y = -1013.8, z = 28.7},
            departure = {x = 441.569, y = -1015.412, z = 28.924, h = 90.588},
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
        -- SetPedRelationshipGroupDefaultHash(activeDriver, pedGroup)
        -- SetPedRelationshipGroupHash(activeDriver, pedGroup)
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
            CurrentPbus[1] = nil
            CurrentDriver[1] = nil
        end
        if not DoesEntityExist(CurrentPbus[1]) and DoesEntityExist(CurrentDriver[1]) then
            DeleteEntity(CurrentDriver[1])
        end
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
    -- check for existing bus i own and delete.
    DeleteLastBusAndDriver()
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
            -- TriggerServerEvent('bdm:makepass', {activeBus,activeBusNetId,zData})  
            Citizen.Wait(30000)
            -- TriggerServerEvent('bdm:delpass', {activeBus,activeBusNetId})
            Citizen.Wait(30000)
            for i = 0, 1 do
                SetVehicleDoorShut(CurrentPbus[1], i, false)
            end 
            -- DeleteLastBusAndDriver()
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