PBusSigns = {}
PBUSDepot = {}
BDDB.PrisonDepot = { 
    {
        uid = 'prisonbus_1',
        name = "Bolingbroke Penitentiary",
        aZone = 153,
        zones = {
            menu = {x = 1817.217, y = 2599.202, z = 44.523},
            passenger = {x = 1801.599, y = 2609.289, z = 44.565},
            departure = {x = 1800.453, y = 2607.865, z = 45.823, h = 269.899},
            recieving = {x = 1799.957, y = 2607.87, z = 45.823, h = 91.443}
        },
        blip = {sprite = 58, color = 8, scale = 0.5}
    },
    {
        uid = 'prisonbus_2',
        name = "Mission Row Police Station",
        aZone = 139,
        zones = {
            menu = {x = 455.614, y = -1024.432, z = 72.460},
            passenger = {x = 440.5, y = -1013.8, z = 28.7},
            departure = {x = 441.569, y = -1015412, z = 28.924, h = 90.588},
            recieving = {x = 446.004, y = -1020.88, z = 28.782, h = 279.469}
        },
        blip = {sprite = 58, color = 8, scale = 0.5}
    }
}
--------------INIT--------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)	
		if NetworkIsPlayerActive(PlayerId()) then
			for j=1, #BDDB.PrisonDepot do
				-- add polyzone for bus		
				addBusPZones(PBUSDepot[j], 2.0, false, true, {})
				-- create bus sign
				PBusSigns[BDDB.PrisonDepot[j].uid] = CreateObject(-1022684418, BDDB.PrisonDepot[j].zones.menu.x, BDDB.PrisonDepot[j].zones.menu.y, BDDB.PrisonDepot[j].zones.menu.z, false, false, false)					
			end			
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