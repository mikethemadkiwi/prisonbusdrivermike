pZoneDebug = true
pZones = {}
PBusSigns = {}
PBUSDepot = {}
IsInPbusZone = false
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
            departure = {x = 441.569, y = -1015412, z = 28.924, h = 90.588},
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
--------------INIT--------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)	
		if NetworkIsPlayerActive(PlayerId()) then
			for j=1, #PrisonDepot do
				addBusPZones(PrisonDepot[j], 1.0, false, pZoneDebug, {})
				PBusSigns[PrisonDepot[j].uid] = CreateObject(-1022684418, PrisonDepot[j].zones.menu.x, PrisonDepot[j].zones.menu.y, PrisonDepot[j].zones.menu.z, false, false, false)					
			end
			--
			DepotPolyList = ComboZone:Create(pZones, {name="DepotPolyList", debugPoly=polydebug})
			DepotPolyList:onPlayerInOut(function(isPointInside, point, zone)
				if zone then
					if isPointInside then
						IsInPbusZone = true
					  else
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
			drawOnScreen2D('~o~Press [~g~E~o~] to call a Prison Bus.', 255, 255, 255, 255, 0.45, 0.45, 0.6)
		end
	end
end)