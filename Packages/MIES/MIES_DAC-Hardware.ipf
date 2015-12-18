#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_DAC-Hardware.ipf
/// @brief __HW__ Low level hardware configuration and querying functions
///
/// Naming scheme of the functions is `HW_$TYPE_$Suffix` where `$TYPE` is one of `ITC` or `NI`.

/// @brief Asserts on using an invalid value of `hardwareType` or `deviceID`
///
/// Invalid here means that the values are out-of-range
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
Function HW_AssertOnInvalid(hardwareType, deviceID)
	variable hardwareType, deviceID

	ASSERT(hardwareType == HARDWARE_NI_DAC || hardwareType == HARDWARE_ITC_DAC , "Invalid hardwareType")
	ASSERT(deviceID >= 0 && deviceID < HARDWARE_MAX_DEVICES, "Invalid deviceID")
End

/// @brief Register an opened device in our device map
///
/// @param mainDevice     Name of the DA_EPhys device
/// @param hardwareType   One of @ref HardwareDACTypeConstants
/// @param deviceID       device identifier
/// @param pressureDevice required for registering pressure control devices
Function HW_RegisterDevice(mainDevice, hardwareType, deviceID, [pressureDevice])
	string mainDevice, pressureDevice
	variable hardwareType, deviceID

	HW_AssertOnInvalid(hardwareType, deviceID)

	WAVE/T devMap = GetDeviceMapping()

	ASSERT(!isEmpty(mainDevice), "Device name can not be empty")
	devMap[deviceID][hardwareType][%MainDevice] = mainDevice

	if(hardwareType == HARDWARE_ITC_DAC)
		devMap[deviceID][hardwareType][%InternalDevice] = NONE
	elseif(hardwareType == HARDWARE_NI_DAC)
		devMap[deviceID][hardwareType][%InternalDevice] = StringFromList(deviceID, HW_NI_ListDevices())
	endif

	if(!ParamIsDefault(pressureDevice))
		ASSERT(!isEmpty(pressureDevice), "Device name can not be empty")
		devMap[deviceID][hardwareType][%PressureDevice] = pressureDevice
	endif
End

/// @brief Deregister an opened device in our device map
///
/// @param deviceID     device identifier
/// @param hardwareType One of @ref HardwareDACTypeConstants
Function HW_DeRegisterDevice(deviceID, hardwareType)
	variable deviceID, hardwareType

	HW_AssertOnInvalid(hardwareType, deviceID)

	WAVE/T devMap = GetDeviceMapping()

	devMap[deviceID][hardwareType][] = ""
End

/// @brief Return the name of the main device given the `deviceID` and the `hardwareType`
///
/// Use this function if you want to derive a storage location from the device name.
///
/// @param deviceID     device identifier
/// @param hardwareType One of @ref HardwareDACTypeConstants
Function/S HW_GetMainDeviceName(hardwareType, deviceID)
	variable hardwareType, deviceID

	string mainDevice

	HW_AssertOnInvalid(hardwareType, deviceID)

	WAVE/T devMap = GetDeviceMapping()

	mainDevice = devMap[deviceID][hardwareType][%MainDevice]
	ASSERT(!isEmpty(mainDevice), "Empty main device")

	return mainDevice
End

/// @brief Return the name of the device given the `deviceID` and the `hardwareType`
///
/// Prefers the pressure device name if set.
///
/// @param deviceID     device identifier
/// @param hardwareType One of @ref HardwareDACTypeConstants
Function/S HW_GetDeviceName(hardwareType, deviceID)
	variable hardwareType, deviceID

	string mainDevice, pressureDevice

	HW_AssertOnInvalid(hardwareType, deviceID)

	WAVE/T devMap = GetDeviceMapping()

	mainDevice = devMap[deviceID][hardwareType][%MainDevice]
	ASSERT(!isEmpty(mainDevice), "Empty main device")
	pressureDevice = devMap[deviceID][hardwareType][%PressureDevice]

	if(!IsEmpty(pressureDevice))
		return pressureDevice
	endif

	return mainDevice
End

/// @brief Return the internal deviceName given the `deviceID` and the `hardwareType`
///
/// @param deviceID     device identifier
/// @param hardwareType One of @ref HardwareDACTypeConstants
Function/S HW_GetInternalDeviceName(hardwareType, deviceID)
	variable hardwareType, deviceID

	string internalDeviceName

	HW_AssertOnInvalid(hardwareType, deviceID)

	WAVE/T devMap = GetDeviceMapping()

	internalDeviceName = devMap[deviceID][hardwareType][%InternalDevice]

	return internalDeviceName
End
/// @}

/// @name Utility functions not interacting with hardware
/// @{

/// @brief Return the `first` and `last` TTL bits/channels for the given `rack`
Function HW_ITC_GetRackRange(rack, first, last)
	variable rack
	variable &first, &last

	if(rack == RACK_ZERO)
		first = 0
		last = NUM_TTL_BITS_PER_RACK - 1
	elseif(rack == RACK_ONE)
		first = NUM_TTL_BITS_PER_RACK
		last = 2 * NUM_TTL_BITS_PER_RACK - 1
	else
		ASSERT(0, "Invalid rack parameter")
	endif
End

/// @brief Clip the ttlBit to adapt for differences in notation
///
/// The DA_Ephys panel e.g. labels the first ttlBit of #RACK_ONE as 4, but the
/// ITC XOP treats that as 0.
Function HW_ITC_ClipTTLBit(panelTitle, ttlBit)
	string panelTitle
	variable ttlBit

	if(HW_ITC_GetRackForTTLBit(panelTitle, ttlBit) == RACK_ONE)
		return ttlBit - NUM_TTL_BITS_PER_RACK
	else
		return ttlBit
	endif
End

/// @brief Return the rack number for the given ttlBit (the ttlBit is
/// called `TTL channel` in the DA Ephys panel)
Function HW_ITC_GetRackForTTLBit(panelTitle, ttlBit)
	string panelTitle
	variable ttlBit

	string deviceType, deviceNumber
	variable ret

	ASSERT(ttlBit < NUM_DA_TTL_CHANNELS, "Invalid channel index")

	if(ttlBit >= NUM_TTL_BITS_PER_RACK)
		ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
		ASSERT(ret, "Could not parse device string")
		ASSERT(!cmpstr(deviceType, "ITC1600"), "Only the ITC1600 has multiple racks")

		return RACK_ONE
	else
		return RACK_ZERO
	endif
End

/// @brief Return the ITC XOP channel for the given rack
///
/// Only the ITC1600 has two racks. The channel numbers differ for the
/// different ITC device types.
Function HW_ITC_GetITCXOPChannelForRack(panelTitle, rack)
	string panelTitle
	variable rack

	string deviceType, deviceNumber
	variable ret

	ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
	ASSERT(ret, "Could not parse device string")

	if(rack == RACK_ZERO)
		if(!cmpstr(deviceType, "ITC18USB") || !cmpstr(deviceType, "ITC18"))
			return HARDWARE_ITC_TTL_DEF_RACK_ZERO
		else
			return HARDWARE_ITC_TTL_1600_RACK_ZERO
		endif
	elseif(rack == RACK_ONE)
		ASSERT(!cmpstr(deviceType, "ITC1600"), "Only the ITC1600 has multiple racks")
		return HARDWARE_ITC_TTL_1600_RACK_ONE
	endif
End
/// @}

/// @brief Return a list of all NI devices which can be opened
///
/// @param flags [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function/S HW_NI_ListDevices([flags])
	variable flags

	return fDAQmx_DeviceNames()
End
