--
ClientDebug = false
----
ServerDebug = false
--
PBDMConf = {
	busModel = 'pbus', -- bus model used
    -- drivingStyle = 786603, -- apparently. "normal"... dude drives like a he has axiety of touching ANYTHING
    drivingStyle = 524697, -- MY personal choice for THIS usage.
    -- drivingStyle = 411, -- nice but can't overtake so causes LOOONG drive loops to avoid traffic ahead of it.
    creepSpeed = 2.5,
    slowSpeed = 5.0,
    citySpeed = 15.0,
    maxSpeed = 30.0,
    stopDistance = 1.0,
    passengerWaitTime = 60 * 1000 -- 60 seconds.
}