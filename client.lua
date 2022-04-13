--
ClientDebug = false
--
PBDMConf = {
	busModel='pbus',
    -- drivingStyle = 786603, -- apparently. "normal"... dude drives like a he has axiety of touching ANYTHING
    drivingStyle = 524697, -- MY personal choice for THIS usage.
    -- drivingStyle = 411, -- nice but can't overtake so causes LOOONG drive loops to avoid traffic ahead of it.
    creepSpeed = 2.5,
    slowSpeed = 5.0,
    citySpeed = 15.0,
    maxSpeed = 30.0,
    stopDistance = 1.0
    passengerWaitTime = 60 * 1000 -- 60 seconds.
}
--
pedGroup = nil
pZones = {}
PassengerZones = {}
IsInPbusZone = false
currentZone = nil
buspass = nil
--
PBusSigns = {}
CurrentDriver = nil
CurrentPbus = nil
CurrentDepot = nil
CanDrive = false
ShouldEnd = false
AmInBus = false
sLimit = 5.0
PrisonDepot = { 
    {
        uid = 'prisonbus_1',
        name = "Bolingbroke Penitentiary",
        aZone = 153,
        zones = {
            menu = {x = 1817.217, y = 2599.202, z = 44.523},
            passenger = {x = 1801.579, y = 2606.286, z = 44.565},
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
    if ClientDebug == true then
	    print('Bus requested at ['..zData.uid..']')
    end
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
        if ClientDebug == true then
	        print('driver spawn:'.. activeDriver .. ' ['..activeDriverNetId..']')
        end
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
        if ClientDebug == true then
            print('bus spawn:'.. activeBus .. ' netid: '.. activeBusNetId ..'')
        end
		if cb ~= nil then
			cb({activeBus, activeBusNetId})
		end
	end)
end
--
function DeleteLastBusAndDriver()
    CanDrive = false
    ShouldEnd = false
    AmInBus = false
    if CurrentPbus ~= nil then
        if DoesEntityExist(CurrentPbus[1]) then
            if IsPedInVehicle(PlayerPedId(), CurrentPbus[1], false) then
                TaskLeaveVehicle(PlayerPedId(), CurrentPbus[1], 0)
            end
            Citizen.Wait(10000)
            NetworkFadeOutEntity(CurrentPbus[1],true, false)
            while NetworkIsEntityFading(CurrentPbus[1]) do      
                Citizen.Wait(100)
            end
            Citizen.Wait(1000)
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
            TriggerServerEvent('pbdm:passentered', {busid})            
            AmInBus = true
            break
        end        
    end
end
--
RegisterNetEvent('pbdm:createbus')
AddEventHandler('pbdm:createbus', function(bObj)
    CurrentDepot = bObj
    DeleteLastBusAndDriver()
	-- Driver
	local bDriver = spawnBusDriver(bObj[2], function(driverData)
        CurrentDriver = driverData
		local bVehicle = spawnBusAtDepot(PBDMConf.busModel, bObj[2].zones.departure.x, bObj[2].zones.departure.y, bObj[2].zones.departure.z, bObj[2].zones.departure.h, driverData[1], 1, function(busData)
            CurrentPbus = busData
            if ClientDebug == true then
                print('Bus:'..CurrentPbus[1]..' Driver:'..CurrentDriver[1])
            end
            TriggerServerEvent('pbdm:createdbusinfo', {CurrentDriver, CurrentPbus, bObj})
            SetPedIntoVehicle(CurrentDriver[1], CurrentPbus[1], -1)    
            for i = 0, 1 do
                SetVehicleDoorOpen(CurrentPbus[1], i, false)
            end 
            TriggerServerEvent('pbdm:makepass', {CurrentPbus[1], CurrentPbus[2], bObj})  
            Citizen.Wait(PBDMConf.passengerWaitTime)
            TriggerServerEvent('pbdm:delpass', {CurrentPbus[1], CurrentPbus[2], bObj})
            for i = 0, 1 do
                SetVehicleDoorShut(CurrentPbus[1], i, false)
            end 
            CanDrive = true 
            sLimit = PBDMConf.creepSpeed
            TaskVehicleDriveWander(CurrentDriver[1], CurrentPbus[1], sLimit, PBDMConf.drivingStyle)
            SetDriveTaskDrivingStyle(CurrentDriver[1], PBDMConf.drivingStyle)
            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
            SetPedKeepTask(CurrentDriver[1], true)
		end)
   	end)
end)
--------------INIT--------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)	
		if NetworkIsPlayerActive(PlayerId()) then
			for j=1, #PrisonDepot do
				addBusPZones(PrisonDepot[j], 1.0, false, ClientDebug, {})
				PBusSigns[j] = CreateObject(-1022684418, PrisonDepot[j].zones.menu.x, PrisonDepot[j].zones.menu.y, PrisonDepot[j].zones.menu.z, false, false, false)					
			end
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
        if ClientDebug == true then
            print('Added Bus group "bdmDrivers" as ['..pedGroup..']')
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
RegisterNetEvent('pbdm:makeclientpass')
AddEventHandler('pbdm:makeclientpass', function(bId)
    local pCoords = vector3(bId[3][2].zones.passenger.x, bId[3][2].zones.passenger.y, bId[3][2].zones.passenger.z)
    PassengerZones[bId[2]] = CircleZone:Create(pCoords, 1.0, {
        name="passengerZonePrisoner",
        useZ=false,
        debugPoly=ClientDebug
    })
    PassengerZones[bId[2]]:onPlayerInOut(function(isPointInside, point, zone)
        if isPointInside then
            buspass = NetworkGetEntityFromNetworkId(bId[2])
            putplayerinseat(buspass) 
            if ClientDebug == true then
                print('Entered Bus LOCAL: '..buspass..' NET: '..bId[2]..' ')
            end
        end
    end)	
end)
--
RegisterNetEvent('pbdm:delclientpass')
AddEventHandler('pbdm:delclientpass', function(bId)
    PassengerZones[bId[2]]:destroy()
end)
--
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsInPbusZone then
            if CurrentPbus == nil then
                if IsControlJustPressed(0, 51) then
                    CallBusAtZone(currentZone)
                end
                if not IsNuiFocused() then
                    drawOnScreen2D('~y~Press [ ~g~E~y~ ] to call a Prison Bus.', 255, 255, 255, 255, 0.40, 0.45, 0.6)
                end
            end
		end
	end
end)
--
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(60000)
		if NetworkIsPlayerActive(PlayerId()) then
            if CurrentPbus ~= nil then                
                if CanDrive == true then
                    if ClientDebug == true then
                        print('AI ['..CurrentDriver[1]..'] Updated')
                    end
                    TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                    SetPedKeepTask(CurrentDriver[1], true)
                end
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
                    SetVehicleHandbrake(CurrentPbus[1], false) -- hb off
                    SetVehicleDoorsLocked(CurrentPbus[1], 2) -- locked                   
                    local buscoords = GetEntityCoords(CurrentPbus[1])
                    local distancefromstart = GetDistanceBetweenCoords(buscoords[1], buscoords[2], buscoords[3], CurrentDepot[2].zones.departure.x, CurrentDepot[2].zones.departure.y, CurrentDepot[2].zones.departure.z, false)
                    local distancetostop = GetDistanceBetweenCoords(buscoords[1], buscoords[2], buscoords[3], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, false)     
                    if ClientDebug == true then 
                        drawOnScreen2D('Depot: '..CurrentDepot[2].uid..'\nDFS:[ '..distancefromstart..' ]\nDTS:[ '..distancetostop..' ]\n@ '..sLimit..' Speed ', 255, 255, 255, 255, 0.45, 0.45, 0.6)
                    end
                    ------ PRISON BUS 1
                    
                    if CurrentDepot[2].uid == 'prisonbus_1' then
                        if math.floor(distancefromstart) == 45 then
                            sLimit = PBDMConf.citySpeed
                            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                            SetPedKeepTask(CurrentDriver[1], true)
                        end
                        if math.floor(distancefromstart) == 150 then
                            sLimit = PBDMConf.maxSpeed
                            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                            SetPedKeepTask(CurrentDriver[1], true)
                        end
                        if math.floor(distancetostop) == 450 then
                            sLimit = PBDMConf.citySpeed
                            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                            SetPedKeepTask(CurrentDriver[1], true)
                        end
                        if math.floor(distancetostop) == 35 then
                            sLimit = PBDMConf.slowSpeed
                            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                            SetPedKeepTask(CurrentDriver[1], true)
                        end
                    end

                    ------ PRISON BUS 2

                    if CurrentDepot[2].uid == 'prisonbus_2' then
                        if math.floor(distancefromstart) == 30 then
                            sLimit = PBDMConf.citySpeed
                            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                            SetPedKeepTask(CurrentDriver[1], true)
                        end
                        if math.floor(distancefromstart) == 400 then
                            sLimit = PBDMConf.maxSpeed
                            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                            SetPedKeepTask(CurrentDriver[1], true)
                        end 
                        if math.floor(distancefromstart) == 4330 then
                            if math.floor(distancetostop) > 600 then
                                sLimit = PBDMConf.creepSpeed
                                TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                                SetPedKeepTask(CurrentDriver[1], true)
                            end
                        end
                        if math.floor(distancefromstart) == 4370 then
                            if math.floor(distancetostop) > 670 then
                                sLimit = PBDMConf.citySpeed
                                TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                                SetPedKeepTask(CurrentDriver[1], true)
                            end
                        end
                        if math.floor(distancetostop) == 150 then
                            sLimit = PBDMConf.citySpeed
                            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                            SetPedKeepTask(CurrentDriver[1], true)
                        end      
                        if math.floor(distancetostop) == 75 then
                            sLimit = PBDMConf.creepSpeed
                            TaskVehicleDriveToCoordLongrange(CurrentDriver[1], CurrentPbus[1], CurrentDepot[2].zones.recieving.x, CurrentDepot[2].zones.recieving.y, CurrentDepot[2].zones.recieving.z, sLimit, PBDMConf.drivingStyle, PBDMConf.stopDistance)
                            SetPedKeepTask(CurrentDriver[1], true)
                        end               

                    end  
                    -- ALL BUSES
                    if math.floor(distancetostop) < 5.0 then
                        CanDrive = false
                        ShouldEnd = true
                    end                    
                else -- Candrive = false
                    SetVehicleDoorsLocked(CurrentPbus[1], 1) -- unlocked
                    TaskVehicleTempAction(CurrentDriver[1], CurrentPbus[1], 6, 2000)
                    SetVehicleHandbrake(CurrentPbus[1], true)
                    SetVehicleEngineOn(CurrentPbus[1], true, true, false)
                end
                if ShouldEnd == true then
                    SetVehicleDoorsLocked(CurrentPbus[1], 1) -- unlocked 
                    for i = 0, 1 do
                        SetVehicleDoorOpen(CurrentPbus[1], i, false)
                    end              
                    DeleteLastBusAndDriver()
                end
            end            
            if IsPedInAnyVehicle(PlayerPedId(), true) then
                if AmInBus == true then
                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                    if veh == buspass then
                        DisableControlAction(0, 75, true)  -- Disable exit vehicle
                        DisableControlAction(27, 75, true) -- Disable exit vehicle
                    end
                end
            end
        end
	end
end)