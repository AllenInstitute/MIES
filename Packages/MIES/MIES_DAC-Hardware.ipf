#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_HW
#endif

/// @file MIES_DAC-Hardware.ipf
/// @brief __HW__ Low level hardware configuration and querying functions
///
/// Naming scheme of the functions is `HW_$TYPE_$Suffix` where `$TYPE` is one of `ITC` or `NI`.

#if exists("ITCSelectDevice2")
#define ITC_XOP_PRESENT
#endif

/// @name Error codes for the ITC XOP2
/// @anchor ITCXOP2Errors
/// @{
Constant OLD_IGOR                    = 10001

Constant UNHANDLED_CPP_EXCEPTION     = 10002

// DeviceID is locked to another thread.
Constant SLOT_LOCKED_TO_OTHER_THREAD = 10003
// Tried to access an unused DeviceID.
Constant SLOT_EMPTY                  = 10004
// No DeviceIDs available to use.
Constant COULDNT_FIND_EMPTY_SLOT     = 10005

// ITC DLL errors
Constant ITC_DLL_ERROR               = 10006

// Invalid numeric device type (/DTN).
Constant INVALID_DEVICETYPE_NUMERIC  = 10007
// Invalid string device type (/DTS).
Constant INVALID_DEVICETYPE_STRING   = 10008
// The device types specified by /DTN and /DTS do not agree.
Constant DTN_DTS_DISAGREE            = 10009

// Invalid numeric channel type (/CHN).
Constant INVALID_CHANNELTYPE_NUMERIC = 10010
// Invalid string channel type (/CHS).
Constant INVALID_CHANNELTYPE_STRING  = 10011
// The channel types specified by /CHN and /CHS do not agree.
Constant CHN_CHS_DISAGREE            = 10012
// Must specify /CHN or /CHS.
Constant MUST_SPECIFY_CHN_OR_CHS     = 10013

// ITCConfigChannel2 flags
// Invalid value for /S flag.
Constant ITCCONFIGCHANNEL2_BAD_S     = 10014
// Invalid value for /M flag.
Constant ITCCONFIGCHANNEL2_BAD_M     = 10015
// Invalid value for /A flag.
Constant ITCCONFIGCHANNEL2_BAD_A     = 10016
// Invalid value for /O flag.
Constant ITCCONFIGCHANNEL2_BAD_O     = 10017
// Invalid value for /U flag.
Constant ITCCONFIGCHANNEL2_BAD_U     = 10018

// Wave does not have the minumum number of rows required
Constant  NEED_MIN_ROWS              = 10019

// ITCInitialize2 errors
// The /F flag requires an ITC18, ITC18USB or ITC1600
Constant F_FLAG_REQ_ITC18_18USB_1600 = 10020
// The /D flag requires an ITC1600
Constant D_FLAG_REQUIRES_ITC1600     = 10021
// The /H flag requires an ITC1600
Constant H_FLAG_REQUIRES_ITC1600     = 10022
// The /R flag requires an ITC1600
Constant R_FLAG_REQUIRES_ITC1600     = 10023

// Tried to access the default device, but the default device has not been set.
Constant THREAD_DEVICE_ID_NOT_SET    = 10024
/// @}

static Constant HW_ITC_RUNNING_STATE = 0x10

/// @name Wrapper functions redirecting to the correct internal implementations depending on #HARDWARE_DAC_TYPES
/// @{


/// @brief Prepare for data acquisition
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID    device identifier
/// @param data        hardware data wave
/// @param dataFunc    [optional, defaults to GetITCDataWave()] override wave getter for the ITC data wave
/// @param config      ITC config wave
/// @param configFunc  [optional, defaults to GetITCChanConfigWave()] override wave getter for the ITC config wave
/// @param flags       [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
/// @param offset      [optional, defaults to zero] offset into the data wave in points
Function HW_PrepareAcq(hardwareType, deviceID, [data, dataFunc, config, configFunc, flags, offset])
	variable hardwareType, deviceID
	WAVE/Z data, config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, configFunc
	variable flags, offset

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return HW_ITC_PrepareAcq(deviceID, flags=flags)
			break
		case HARDWARE_NI_DAC:
			return HW_NI_PrepareAcq(deviceID, flags=flags)
			break
	endswitch
	return 0
End

/// @brief Select a device
///
/// Only used in special cases for ITC hardware as all ITC operations use the
/// `/DEV` flag nowadays.
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID identifier of the device
/// @param flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return 0 if sucessfull, 1 on error
Function HW_SelectDevice(hardwareType, deviceID, [flags])
	variable hardwareType, deviceID, flags

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return HW_ITC_SelectDevice(deviceID, flags=flags)
			break
		case HARDWARE_NI_DAC:
			// nothing to do
			return 0
			break
	endswitch
End

/// @brief Open a device
///
/// @param deviceToOpen device
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return device identifier
Function HW_OpenDevice(deviceToOpen, hardwareType, [flags])
	string deviceToOpen
	variable &hardwareType, flags

	string deviceType, deviceNumber
	variable deviceTypeIndex, deviceNumberIndex, deviceID, prelimHWType

	hardwareType = GetHardwareType(deviceToOpen)
	switch(hardwareType)
		case HARDWARE_NI_DAC:
			deviceID = WhichListItem(deviceToOpen, HW_NI_ListDevices())
			HW_NI_OpenDevice(deviceToOpen)
			break
		case HARDWARE_ITC_DAC:
			ParseDeviceString(deviceToOpen, deviceType, deviceNumber)
			deviceTypeIndex   = WhichListItem(deviceType, DEVICE_TYPES_ITC)
			deviceNumberIndex = WhichListItem(deviceNumber, DEVICE_NUMBERS)
			deviceID     = HW_ITC_OpenDevice(deviceTypeIndex, deviceNumberIndex)
			break
		default:
			ASSERT(0, "Unable to open device: Device to open had an unsupported hardware type")
			break
	endswitch

	if(flags == HARDWARE_ABORT_ON_ERROR)
		HW_AssertOnInvalid(hardwareType, deviceID)
	endif

	return deviceID
End

/// @brief Close a device
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_CloseDevice(hardwareType, deviceID, [flags])
	variable hardwareType, deviceID, flags

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_CloseDevice(deviceID, flags=flags)
			break
		case HARDWARE_NI_DAC:
			HW_NI_CloseDevice(deviceID, flags=flags)
			break
	endswitch
End

/// @brief Write a value to a DA/AO channel
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param channel      channel number
/// @param value        value to write in volts
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_WriteDAC(hardwareType, deviceID, channel, value, [flags])
	variable hardwareType, deviceID, channel, value, flags

	string device

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_WriteDAC(deviceID, channel, value, flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			HW_NI_AssertOnInvalid(device)
			HW_NI_WriteAnalogSingleAndSlow(device, channel, value, flags=flags)
			break
	endswitch
End

/// @brief Read a value from an AD/AI channel
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param channel      channel number
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return value in volts
Function HW_ReadADC(hardwareType, deviceID, channel, [flags])
	variable hardwareType, deviceID, channel, flags

	string device

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return HW_ITC_ReadADC(deviceID, channel, flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			HW_NI_AssertOnInvalid(device)
			return HW_NI_ReadAnalogSingleAndSlow(device, channel, flags=flags)
			break
	endswitch
End

/// @brief Read from a digital channel
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param channel      The hardware documentation terms this as port(NI). For the
///                     ITC we call that ttlBit. Takes care of special rack handling
///                     for the ITC 1600. Range depends on hardware and hardware type.
/// @param line         bit of TTL line, (only for hardware types which support single TTL writes/read)
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return bitmask denoting the state of the channel/line
Function HW_ReadDigital(hardwareType, deviceID, channel, [line, flags])
	variable hardwareType, deviceID, channel, line, flags

	string device, panelTitle
	variable rack, xopChannel, ttlBit

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			panelTitle = HW_GetDeviceName(HARDWARE_ITC_DAC, deviceID)
			ttlBit	   = channel
			rack	   = HW_ITC_GetRackForTTLBit(panelTitle, ttlBit)
			xopChannel = HW_ITC_GetITCXOPChannelForRack(panelTitle, rack)
			return HW_ITC_ReadDigital(deviceID, xopChannel, flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			HW_NI_AssertOnInvalid(device)
			if(ParamisDefault(line))
				return HW_NI_ReadDigital(device, DIOPort=channel, flags=flags)
			else
				return HW_NI_ReadDigital(device, DIOPort=channel, DIOline=line, flags=flags)
			endif
			break
	endswitch
End

/// @brief Write to a digital channel
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param channel      The hardware documentation terms this as port(NI). For the
///                     ITC we call that ttlBit. Takes care of special rack handling
///                     for the ITC 1600. Range depends on hardware and hardware type.
/// @param value        bitmask to write
/// @param line         bit of TTL line, (only for hardware types which support single TTL writes/read)
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_WriteDigital(hardwareType, deviceID, channel, value, [line, flags])
	variable hardwareType, deviceID, value, channel, line, flags

	string device, panelTitle
	variable ttlBit, rack, xopChannel

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			panelTitle = HW_GetDeviceName(HARDWARE_ITC_DAC, deviceID)
			ttlBit     = channel
			rack       = HW_ITC_GetRackForTTLBit(panelTitle, ttlBit)
			xopChannel = HW_ITC_GetITCXOPChannelForRack(panelTitle, rack)
			HW_ITC_WriteDigital(deviceID, xopChannel, value, flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			HW_NI_AssertOnInvalid(device)
			if(ParamisDefault(line))
				HW_NI_WriteDigital(device, value, DIOPort=channel, flags=flags)
			else
				HW_NI_WriteDigital(device, value, DIOPort=channel, DIOline=line, flags=flags)
			endif
			break
	endswitch
End

/// @brief Enable yoking
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_EnableYoking(hardwareType, deviceID, [flags])
	variable hardwareType, deviceID, flags

	string device

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_EnableYoking(deviceID, flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			HW_NI_AssertOnInvalid(device)
			ASSERT(0, "Not implemented")
			break
	endswitch
End

/// @brief Enable yoking
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_DisableYoking(hardwareType, deviceID, [flags])
	variable hardwareType, deviceID, flags

	string device

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_DisableYoking(deviceID, flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			HW_NI_AssertOnInvalid(device)
			ASSERT(0, "Not implemented")
			break
	endswitch
End

/// @brief Stop data acquisition
///
/// @param hardwareType  One of @ref HardwareDACTypeConstants
/// @param deviceID      device identifier
/// @param prepareForDAQ immediately prepare for the next data acquisition after stopping it
/// @param zeroDAC       set all used DA channels to zero
/// @param flags         [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_StopAcq(hardwareType, deviceID, [prepareForDAQ, zeroDAC, flags])
	variable hardwareType, deviceID, prepareForDAQ, zeroDAC, flags

	string device
	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_StopAcq(deviceID, prepareForDAQ=prepareForDAQ, zeroDAC = zeroDAC, flags=flags)
			break
		case HARDWARE_NI_DAC:
			HW_NI_StopAcq(deviceID, zeroDAC = zeroDAC, flags=flags)
			break
	endswitch
End

/// @brief Determine if data acquisition is currently active
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return one if running, zero otherwise
Function HW_IsRunning(hardwareType, deviceID, [flags])
	variable hardwareType, deviceID, flags

	string device
	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return HW_ITC_IsRunning(deviceID, flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			HW_NI_AssertOnInvalid(device)
			return HW_NI_IsRunning(device, flags=flags)
			break
	endswitch
End

/// @brief Start data acquisition
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param triggerMode  [optional, defaults to #HARDWARE_DAC_DEFAULT_TRIGGER] one of @ref TriggerModeStartAcq
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
/// @param repeat       [optional, default 0] for NI devices, repeats the scan after it ends
Function HW_StartAcq(hardwareType, deviceID, [triggerMode, flags, repeat])
	variable hardwareType, deviceID, triggerMode, flags, repeat

	HW_AssertOnInvalid(hardwareType, deviceID)

	if(ParamIsDefault(triggerMode))
		triggerMode = HARDWARE_DAC_DEFAULT_TRIGGER
	endif

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_StartAcq(deviceID, triggerMode, flags=flags)
			break
		case HARDWARE_NI_DAC:
			HW_NI_StartAcq(deviceID, triggerMode, flags=flags, repeat=repeat)
			break
	endswitch
End

/// @brief Reset the device
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ResetDevice(hardwareType, deviceID, [flags])
	variable hardwareType, deviceID, flags

	string device
	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			// no equivalent functionality
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			HW_NI_AssertOnInvalid(device)
			HW_NI_ResetDevice(device, flags=flags)
			break
	endswitch
End

/// @brief Assert on using an invalid value of `hardwareType` or `deviceID`
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
Function HW_AssertOnInvalid(hardwareType, deviceID)
	variable hardwareType, deviceID

	ASSERT(HW_IsValidHardwareType(hardwareType), "Invalid hardwareType")
	ASSERT(HW_IsValidDeviceID(deviceID), "Invalid deviceID")
End

/// @brief Check if the given hardware type is valid
///
/// Invalid here means that the value is out-of-range.
static Function HW_IsValidHardwareType(hardwareType)
	variable hardwareType

#ifndef EVIL_KITTEN_EATING_MODE
	return hardwareType == HARDWARE_NI_DAC || hardwareType == HARDWARE_ITC_DAC
#else
	return 1
#endif
End

/// @brief Check if the given device ID is valid
///
/// Invalid here means that the value is out-of-range.
static Function HW_IsValidDeviceID(deviceID)
	variable deviceID

#ifndef EVIL_KITTEN_EATING_MODE
	return deviceID >= 0 && deviceID < HARDWARE_MAX_DEVICES
#else
	return 1
#endif
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
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_DeRegisterDevice(hardwareType, deviceID, [flags])
	variable deviceID, hardwareType, flags

	if(!HW_IsValidDeviceID(deviceID) || !HW_IsValidHardwareType(hardwareType))
		return NaN
	endif

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

	HW_AssertOnInvalid(hardwareType, deviceID)

	WAVE/T devMap = GetDeviceMapping()

	return devMap[deviceID][hardwareType][%InternalDevice]
End
/// @}

/// @name ITC
/// @{

#ifdef ITC_XOP_PRESENT

/// @brief Return a list of all open ITC devices
Function/S HW_ITC_ListOfOpenDevices()

	variable i
	string device, type, number
	string list = ""

	DEBUGPRINTSTACKINFO()

	for(i = 0; i < HARDWARE_MAX_DEVICES; i += 1)
		if(HW_ITC_SelectDevice(i))
			continue
		endif

		// device could be selected
		// get the device type
		do
			ITCGetDeviceInfo2/FREE DevInfo
		while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

		HW_ITC_HandleReturnValues(0, V_ITCError, V_ITCXOPError)

		type   = StringFromList(DevInfo[0], DEVICE_TYPES_ITC)
		number = StringFromList(DevInfo[1], DEVICE_NUMBERS)
		device = BuildDeviceString(type, number)
		list   = AddListItem(device, list, ";", Inf)
	endfor

	KillOrMoveToTrash(wv=DevInfo)

	return list
End

///@brief Return a list of all ITC devices which can be opened
///
///**Warning! This heavily interacts with the ITC* controllers, don't call
///during data/test pulse/whatever acquisition.**
///
///@returns A list of panelTitles with ITC devices which can be opened.
///         Does not include devices which are already open.
Function/S HW_ITC_ListDevices()

	variable i, j, deviceID
	string type, number, msg, device
	string list = ""

	DEBUGPRINTSTACKINFO()

	for(i=0; i < ItemsInList(DEVICE_TYPES_ITC); i+=1)
		type = StringFromList(i, DEVICE_TYPES_ITC)

		if(CmpStr(type,"ITC00") == 0) // don't test the virtual device
			continue
		endif

		do
			ITCGetDevices2/Z=1/DTS=type
		while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)


		if(V_Value > 0)
			for(j=0; j < ItemsInList(DEVICE_NUMBERS); j+=1)
				number = StringFromList(j, DEVICE_NUMBERS)
				device = BuildDeviceString(type,number)

				do
					ITCOpenDevice2/Z=1/DTS=type str2num(number)
				while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

				if(V_ITCError == 0x8D101000)
					ITCGeterrorString2 V_ITCError
					printf "Missing ITC initialization due to error \"%s\".\r", S_errorMessage
					printf "Please run Igor Pro or the ITCDemo application once as administrator to create the required registry keys.\r"
					ControlWindowToFront()
					return ""
				endif

				deviceID = V_Value
				if(V_ITCError == 0 && V_ITCXOPError == 0 && deviceID >= 0)
					sprintf msg, "Found device type %s with number %s", type, number
					DEBUGPRINT(msg)
					HW_ITC_CloseDevice(deviceID)
					list = AddListItem(device, list, ";", inf)
				endif
			endfor
		endif
	endfor

	return list
End

/// @brief Output an informative error message for the ITC XOP2 operations (threadsafe variant)
///
/// @return 0 on success, 1 otherwise
threadsafe Function HW_ITC_HandleReturnValues_TS(flags, ITCError, ITCXOPError)
	variable flags, ITCError, ITCXOPError

	// we only need the lower 32bits of the error
	ITCError = ITCError & 0x00000000ffffffff

	if(ITCError != 0 && !(flags & HARDWARE_PREVENT_ERROR_MESSAGE))
		printf "The ITC XOP returned the following errors: ITCError=%#x, ITCXOPError=%d\r", ITCError, ITCXOPError

		do
			ITCGetErrorString2/X itcError
		while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

		print S_errorMEssage
		print "Some hints you might want to try!"
		print "- Is the correct ITC device type selected?"
		print "- Is your ITC Device connected to a power socket?"
		print "- Is your ITC Device connected to your computer?"
		print "- Have you tried unlocking/locking the device already?"
		print "- Reseating all connections between the DAC and the computer has also helped in the past."
	elseif(ITCXOPError != 0 && !(flags & HARDWARE_PREVENT_ERROR_MESSAGE))
		printf "The ITC XOP returned the following errors: ITCError=%#x, ITCXOPError=%d\r", ITCError, ITCXOPError
		printf "The ITC XOP was called incorrectly, please inform the MIES developers!\r"
		printf "XOP error message: %s\r", HW_ITC_GetXOPErrorMessage(ITCXOPError)
		printf "Responsible function: (not available)\r"
		printf "Complete call stack: (not available)\r"
	endif

#ifndef EVIL_KITTEN_EATING_MODE
	if(ITCXOPError != 0 || ITCError != 0)
		ASSERT_TS(!(flags & HARDWARE_ABORT_ON_ERROR), "DAC error")
	endif

	return ITCXOPError != 0 || ITCError != 0
#else
	return 0
#endif
End

/// @brief Output an informative error message for the ITC XOP2 operations
///
/// @return 0 on success, 1 otherwise
Function HW_ITC_HandleReturnValues(flags, ITCError, ITCXOPError)
	variable flags, ITCError, ITCXOPError

	// we only need the lower 32bits of the error
	ITCError = ITCError & 0x00000000ffffffff

	if(ITCError != 0 && !(flags & HARDWARE_PREVENT_ERROR_MESSAGE))
		printf "The ITC XOP returned the following errors: ITCError=%#x, ITCXOPError=%d\r", ITCError, ITCXOPError

		do
			ITCGetErrorString2/X itcError
		while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

		print S_errorMEssage
		print "Some hints you might want to try!"
		print "- Is the correct ITC device type selected?"
		print "- Is your ITC Device connected to a power socket?"
		print "- Is your ITC Device connected to your computer?"
		print "- Have you tried unlocking/locking the device already?"
		print "- Reseating all connections between the DAC and the computer has also helped in the past."
	elseif(ITCXOPError != 0 && !(flags & HARDWARE_PREVENT_ERROR_MESSAGE))
		printf "The ITC XOP returned the following errors: ITCError=%#x, ITCXOPError=%d\r", ITCError, ITCXOPError
		printf "The ITC XOP was called incorrectly, please inform the MIES developers!\r"
		printf "XOP error message: %s\r", HW_ITC_GetXOPErrorMessage(ITCXOPError)
		printf "Responsible function: %s\r", GetRTStackInfo(2)
		printf "Complete call stack: %s\r", GetRTStackInfo(3)
	endif

#ifndef EVIL_KITTEN_EATING_MODE
	if(ITCXOPError != 0 || ITCError != 0)
		ControlWindowToFront()
		ASSERT(!(flags & HARDWARE_ABORT_ON_ERROR), "DAC error")
	endif

	return ITCXOPError != 0 || ITCError != 0
#else
	return 0
#endif
End

/// @brief Return the error message for the given ITC XOP2 error code
///
/// @param errCode one of @ref ITCXOP2Errors
threadsafe static Function/S HW_ITC_GetXOPErrorMessage(errCode)
	variable errCode

	switch(errCode)
		case OLD_IGOR:
			return "itcXOP2 requires at least Igor Pro 6.30 (32bit) or Igor Pro 7.0 (64bit)."
			break
		case UNHANDLED_CPP_EXCEPTION:
			return "Unhandled C++ Exception"
			break
		case SLOT_LOCKED_TO_OTHER_THREAD:
			return "DeviceID is locked to another thread."
			break
		case SLOT_EMPTY:
			return "Tried to access an unused DeviceID."
			break
		case COULDNT_FIND_EMPTY_SLOT:
			return "No DeviceIDs available to use."
			break
		case ITC_DLL_ERROR:
			return "Problem with ITC DLL."
			break
		case INVALID_DEVICETYPE_NUMERIC:
			return "Invalid numeric device type (/DTN)."
			break
		case INVALID_DEVICETYPE_STRING:
			return "Invalid string device type (/DTS)."
			break
		case DTN_DTS_DISAGREE:
			return "The device types specified by /DTN and /DTS do not agree."
			break
		case INVALID_CHANNELTYPE_NUMERIC:
			return "Invalid numeric channel type (/CHN)."
			break
		case INVALID_CHANNELTYPE_STRING:
			return "Invalid string channel type (/CHS)."
			break
		case CHN_CHS_DISAGREE:
			return "The channel types specified by /CHN and /CHS do not agree."
			break
		case MUST_SPECIFY_CHN_OR_CHS:
			return "Must specify /CHN or /CHS."
			break
		case ITCCONFIGCHANNEL2_BAD_S:
			return "Invalid value for /S flag."
			break
		case ITCCONFIGCHANNEL2_BAD_M:
			return "Invalid value for /M flag."
			break
		case ITCCONFIGCHANNEL2_BAD_A:
			return "Invalid value for /A flag."
			break
		case ITCCONFIGCHANNEL2_BAD_O:
			return "Invalid value for /O flag."
			break
		case ITCCONFIGCHANNEL2_BAD_U:
			return "Invalid value for /U flag."
			break
		case NEED_MIN_ROWS:
			return "Wave does not have the minumum number of rows required"
			break
		case F_FLAG_REQ_ITC18_18USB_1600:
			return "The /F flag requires an ITC18, ITC18USB or ITC1600"
			break
		case D_FLAG_REQUIRES_ITC1600:
			return "The /D flag requires an ITC1600"
			break
		case H_FLAG_REQUIRES_ITC1600:
			return "The /H flag requires an ITC1600"
			break
		case R_FLAG_REQUIRES_ITC1600:
			return "The /R flag requires an ITC1600"
			break
		case THREAD_DEVICE_ID_NOT_SET:
			return "Tried to access the default device, but the default device has not been set."
			break
		default:
			return "Unknown error code: " + num2str(errCode)
			break
	endswitch
End

/// @brief Open a ITC device
///
/// @param deviceType   zero-based index into #DEVICE_TYPES_ITC
/// @param deviceNumber zero-based index into #DEVICE_NUMBERS
/// @param flags [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return ITC device ID
Function HW_ITC_OpenDevice(deviceType, deviceNumber, [flags])
	variable deviceType, deviceNumber
	variable flags

	variable deviceID

	DEBUGPRINTSTACKINFO()

	do
		ITCOpenDevice2/DTN=(deviceType)/Z=(HW_ITC_GetZValue(flags)) deviceNumber
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
	deviceID = V_Value

	printf "ITC Device opened, returned deviceID is %d.\r", deviceID

	return deviceID
End

/// @brief Close all ITC devices 
Function HW_ITC_CloseAllDevices([flags])
	variable flags

	variable i

	DEBUGPRINTSTACKINFO()

	for(i = 0; i < HARDWARE_MAX_DEVICES; i += 1)
		if(HW_SelectDevice(HARDWARE_ITC_DAC, i, flags = HARDWARE_PREVENT_ERROR_MESSAGE | HARDWARE_PREVENT_ERROR_POPUP))
			continue // can not select device
		endif

		if(HW_ITC_IsRunning(i, flags=flags))
			HW_ITC_StopAcq(i, flags=flags)
		endif
	endfor

	ITCCloseAll2/Z=(HW_ITC_GetZValue(flags))
End

/// @see HW_CloseDevice
Function HW_ITC_CloseDevice(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINTSTACKINFO()

	if(HW_ITC_IsRunning(deviceID, flags=flags))
		HW_ITC_StopAcq(deviceID, flags=flags)
	endif

	do
		ITCCloseDevice2/DEV=(deviceID)/Z
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)
End

/// @see HW_SelectDevice
Function HW_ITC_SelectDevice(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINTSTACKINFO()

	do
		ITCSelectDevice2/Z=(HW_ITC_GetZValue(flags)) deviceID
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	return HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_EnableYoking
Function HW_ITC_EnableYoking(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINTSTACKINFO()

	do
		ITCInitialize2/DEV=(deviceID)/M=1/Z=(HW_ITC_GetZValue(flags))
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_DisableYoking
Function HW_ITC_DisableYoking(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINTSTACKINFO()

	do
		ITCInitialize2/DEV=(deviceID)/M=0/Z=(HW_ITC_GetZValue(flags))
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_StopAcq (threadsafe variant)
threadsafe Function HW_ITC_StopAcq_TS(deviceID, [prepareForDAQ, flags])
	variable deviceID, prepareForDAQ, flags

	do
		ITCStopAcq2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags))
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues_TS(flags, V_ITCError, V_ITCXOPError)

	if(prepareForDAQ)
		do
			ITCConfigChannelUpload2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags))
		while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

		HW_ITC_HandleReturnValues_TS(flags, V_ITCError, V_ITCXOPError)
	endif
End

/// @param deviceID      device identifier
/// @param config        [optional] ITC config wave
/// @param configFunc    [optional, defaults to GetITCChanConfigWave()] override wave getter for the ITC config wave
/// @param prepareForDAQ [optional, defaults to false] prepare for next DAQ immediately
/// @param zeroDAC       [optional, defaults to false] set all DA channels to zero
/// @param flags         [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @see HW_StopAcq
Function HW_ITC_StopAcq(deviceID, [config, configFunc, prepareForDAQ, zeroDAC, flags])
	variable deviceID, prepareForDAQ, zeroDAC, flags
	WAVE/Z config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc

	variable i, numEntries
	string panelTitle

	DEBUGPRINTSTACKINFO()

	do
		ITCStopAcq2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags))
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	if(zeroDAC)
		panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

		if(ParamIsDefault(config))
			if(ParamIsDefault(configFunc))
				WAVE config = GetITCChanConfigWave(panelTitle)
			else
				WAVE config = configFunc(panelTitle)
			endif
		endif

		WAVE/Z DACs = GetDACListFromConfig(config)

		numEntries = WaveExists(DACs) ? DimSize(DACs, ROWS) : 0
		for(i = 0; i < DimSize(DACs, ROWS); i += 1)
			HW_ITC_WriteDAC(deviceID, DACs[i], 0, flags = flags)
		endfor
	endif

	if(prepareForDAQ)
		do
			ITCConfigChannelUpload2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags))
		while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

		HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
	endif
End

/// @brief Return the deviceID of the currently selected
///        ITC device from the XOP
Function HW_ITC_GetCurrentDevice([flags])
	variable flags

	DEBUGPRINTSTACKINFO()

	do
		ITCGetCurrentDevice2/Z=(HW_ITC_GetZValue(flags))
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	return V_Value
End

/// @brief Create a fifo position wave from a ITCChanConfigWave
threadsafe static Function/WAVE HW_ITC_GetFifoPosFromConfig(config_t)
	WAVE config_t

	Duplicate/FREE config_t, fifoPos_t

	fifoPos_t[2,][] = NaN
	fifoPos_t[2][]  = -1

	return fifoPos_t
End

/// @brief Reset the AD/DA channel FIFOs (threadsafe variant)
///
/// @param deviceID device identifier
/// @param config   ITC config wave
/// @param flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
threadsafe Function HW_ITC_ResetFifo_TS(deviceID, config, [flags])
	variable deviceID
	WAVE config
	variable flags

	WAVE config_t  = HW_ITC_TransposeAndToDouble(config)
	WAVE fifoPos_t = HW_ITC_GetFifoPosFromConfig(config_t)

	do
		ITCUpdateFIFOPositionAll2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags)) fifoPos_t
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues_TS(flags, V_ITCError, V_ITCXOPError)
End

/// @brief Reset the AD/DA channel FIFOs
///
/// @param deviceID device identifier
/// @param[in] config                  [optional] ITC config wave
/// @param[in] configFunc              [optional, defaults to GetITCChanConfigWave()] override wave getter for the ITC config wave
/// @param     flags                   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_ResetFifo(deviceID, [config, configFunc, flags])
	variable deviceID
	WAVE/Z config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc
	variable  flags

	string panelTitle

	DEBUGPRINTSTACKINFO()

	panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

	if(ParamIsDefault(config))
		if(ParamIsDefault(configFunc))
			WAVE config = GetITCChanConfigWave(panelTitle)
		else
			WAVE config = configFunc(panelTitle)
		endif
	endif

	WAVE config_t = HW_ITC_TransposeAndToDouble(config)
	WAVE fifoPos_t = HW_ITC_GetFifoPosFromConfig(config_t)

	do
		ITCUpdateFIFOPositionAll2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags)) fifoPos_t
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_StartAcq (threadsafe variant)
threadsafe Function HW_ITC_StartAcq_TS(deviceID, triggerMode, [flags])
	variable deviceID, triggerMode, flags

	switch(triggerMode)
		case HARDWARE_DAC_EXTERNAL_TRIGGER:
			do
				ITCStartAcq2/DEV=(deviceID)/EXT=256/Z=(HW_ITC_GetZValue(flags))
			while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

			break
		case HARDWARE_DAC_DEFAULT_TRIGGER:
			do
				ITCStartAcq2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags))
			while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

			break
		default:
			ASSERT_TS(0, "Unknown trigger mode")
			break
	endswitch

	HW_ITC_HandleReturnValues_TS(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_StartAcq
Function HW_ITC_StartAcq(deviceID, triggerMode, [flags])
	variable deviceID, triggerMode, flags

	DEBUGPRINTSTACKINFO()

	switch(triggerMode)
		case HARDWARE_DAC_EXTERNAL_TRIGGER:
			do
				ITCStartAcq2/DEV=(deviceID)/EXT=256/Z=(HW_ITC_GetZValue(flags))
			while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

			break
		case HARDWARE_DAC_DEFAULT_TRIGGER:
			do
				ITCStartAcq2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags))
			while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

			break
		default:
			ASSERT(0, "Unknown trigger mode")
			break
	endswitch

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @brief Check wether DAQ is still ongoing
///
/// @param deviceID device identifier
/// @param flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_IsRunning(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINTSTACKINFO()

	WAVE/Z state = HW_ITC_GetState(deviceID, flags=flags)

	if(!WaveExists(state))
		return 0
	endif

	return (state[0] & HW_ITC_RUNNING_STATE) == HW_ITC_RUNNING_STATE
End

/// @brief Query the ITC device state
///
/// @param deviceID device identifier
/// @param flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function/WAVE HW_ITC_GetState(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINTSTACKINFO()

	do
		ITCGetState2/DEV=(deviceID)/ALL/FREE/Z=(HW_ITC_GetZValue(flags)) state
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)


	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	return state
End

/// @see HW_ReadADC
Function HW_ITC_ReadADC(deviceID, channel, [flags])
	variable deviceID, channel, flags

	DEBUGPRINTSTACKINFO()

	do
		ITCReadADC2/DEV=(deviceID)/C=1/V=1/Z=(HW_ITC_GetZValue(flags)) channel
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	return V_Value
End

/// @see HW_WriteDAC
Function HW_ITC_WriteDAC(deviceID, channel, value, [flags])
	variable deviceID, channel, value, flags

	DEBUGPRINTSTACKINFO()

	do
		ITCSetDAC2/DEV=(deviceID)/C=1/V=1/Z=(HW_ITC_GetZValue(flags)) channel, value
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_ReadDigital
Function HW_ITC_ReadDigital(deviceID, xopChannel, [flags])
	variable deviceID, xopChannel, flags

	DEBUGPRINTSTACKINFO()

	do
		ITCReadDigital2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags)) xopChannel
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	return V_Value
End

/// @see HW_WriteDigital
Function HW_ITC_WriteDigital(deviceID, xopChannel, value, [flags])
	variable deviceID, xopChannel, value, flags

	DEBUGPRINTSTACKINFO()

	do
		ITCWriteDigital2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags)) xopChannel, value
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @brief Set the debug flag of the ITC XOP to ON/OFF (threadsafe variant)
threadsafe Function HW_ITC_DebugMode_TS(state, [flags])
	variable state, flags

	ITCSetGlobals2/D=(state)/Z=(HW_ITC_GetZValue(flags))
End

/// @brief Set the debug flag of the ITC XOP to ON/OFF
Function HW_ITC_DebugMode(state, [flags])
	variable state, flags

	DEBUGPRINTSTACKINFO()

	ITCSetGlobals2/D=(state)/Z=(HW_ITC_GetZValue(flags))
End

/// @brief Prepare for data acquisition
///
/// @param deviceID    device identifier
/// @param data        ITC data wave
/// @param dataFunc    [optional, defaults to GetITCDataWave()] override wave getter for the ITC data wave
/// @param config      ITC config wave
/// @param configFunc  [optional, defaults to GetITCChanConfigWave()] override wave getter for the ITC config wave
/// @param offset      [optional, defaults to zero] offset into the data wave in points
/// @param flags       [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_PrepareAcq(deviceID, [data, dataFunc, config, configFunc, flags, offset])
	variable deviceID
	WAVE/Z data, config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, configFunc
	variable flags, offset

	string panelTitle

	DEBUGPRINTSTACKINFO()

	panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

	if(ParamIsDefault(data))
		if(ParamIsDefault(dataFunc))
			WAVE data = GetHardwareDataWave(panelTitle)
		else
			WAVE data = dataFunc(panelTitle)
		endif
	endif

	if(ParamIsDefault(config))
		if(ParamIsDefault(configFunc))
			WAVE config = GetITCChanConfigWave(panelTitle)
		else
			WAVE config = configFunc(panelTitle)
		endif
	endif

	if(!ParamIsDefault(offset))
		config[][%Offset] = offset
	endif

	WAVE config_t = HW_ITC_TransposeAndToDouble(config)

	do
		ITCconfigAllchannels2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags)) config_t, data
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForFile(GetFile(FunctionPath(""))))
		do
			ITCGetAllChannelsConfig2/DEV=(deviceID)/O/Z=(HW_ITC_GetZValue(flags)) config_t, settings
		while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

		HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

		printf "xop: %d with alignment %d\r", settings[%FIFOPointer][0], GetAlignment(settings[%FIFOPointer][0])
		printf "xop: %d with alignment %d\r", settings[%FIFOPointer][1], GetAlignment(settings[%FIFOPointer][1])
		printf "diff = %d\r", settings[%FIFOPointer][1] - settings[%FIFOPointer][0]
		printf "numRows = %d\r", DimSize(data, ROWS)
	endif
#endif // DEBUGGING_ENABLED

	WAVE fifoPos_t = HW_ITC_GetFifoPosFromConfig(config_t)

	do
		ITCUpdateFIFOPositionAll2/DEV=(deviceID)/Z=(HW_ITC_GetZValue(flags)) fifoPos_t
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @brief Check wether more data can be acquired (threadsafe variant)
///
/// @param[in] deviceID            device identifier
/// @param[in] ADChannelToMonitor  first AD channel
/// @param[in] stopCollectionPoint number of points to acquire
/// @param[in] config              ITC config wave
/// @param[out] fifoPos            allows to query the current fifo position (ADC)
/// @param flags                   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return 1 if more data needs to be acquired, 0 if done
threadsafe Function HW_ITC_MoreData_TS(deviceID, ADChannelToMonitor, stopCollectionPoint, config, [fifoPos, flags])
	variable deviceID
	variable ADChannelToMonitor, stopCollectionPoint
	WAVE config
	variable &fifoPos
	variable flags

	variable fifoPosValue, offset

	offset = GetDataOffset(config)

	WAVE config_t = HW_ITC_TransposeAndToDouble(config)

	do
		ITCFIFOAvailableALL2/DEV=(deviceID)/FREE/Z=(HW_ITC_GetZValue(flags)) config_t, fifoAvail_t
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues_TS(flags, V_ITCError, V_ITCXOPError)

	fifoPosValue = fifoAvail_t[2][ADChannelToMonitor]

	if(!ParamIsDefault(fifoPos))
		fifoPos = fifoPosValue
	endif

	return (offset + fifoPosValue) < stopCollectionPoint
End

/// @brief Check wether more data can be acquired
///
/// @param[in] deviceID            device identifier
/// @param[in] ADChannelToMonitor  [optional, defaults to GetADChannelToMonitor()] first AD channel
/// @param[in] stopCollectionPoint [optional, defaults to GetStopCollectionPoint()] number of points to acquire
/// @param[in] config              [optional] ITC config wave
/// @param[in] configFunc          [optional, defaults to GetITCChanConfigWave()] override wave getter for the ITC config wave
/// @param[out] fifoPos            [optional] allows to query the current fifo position (ADC)
/// @param flags                   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return 1 if more data needs to be acquired, 0 if done
Function HW_ITC_MoreData(deviceID, [ADChannelToMonitor, stopCollectionPoint, config, configFunc, fifoPos, flags])
	variable deviceID
	variable ADChannelToMonitor, stopCollectionPoint
	WAVE/Z config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc
	variable &fifoPos
	variable flags

	variable fifoPosValue, offset
	string panelTitle

	DEBUGPRINTSTACKINFO()

	panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

	if(ParamIsDefault(ADChannelToMonitor))
		NVAR ADChannelToMonitor_NVAR = $GetADChannelToMonitor(panelTitle)
		ADChannelToMonitor = ADChannelToMonitor_NVAR
	endif

	if(ParamIsDefault(stopCollectionPoint))
		NVAR stopCollectionPoint_NVAR = $GetStopCollectionPoint(panelTitle)
		stopCollectionPoint = stopCollectionPoint_NVAR
	endif

	if(ParamIsDefault(config))
		if(ParamIsDefault(configFunc))
			WAVE config = GetITCChanConfigWave(panelTitle)
		else
			WAVE config = configFunc(panelTitle)
		endif
	endif

	offset = GetDataOffset(config)

	WAVE config_t = HW_ITC_TransposeAndToDouble(config)

	do
		ITCFIFOAvailableALL2/DEV=(deviceID)/FREE/Z=(HW_ITC_GetZValue(flags)) config_t, fifoAvail_t
	while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
	fifoPosValue = fifoAvail_t[2][ADChannelToMonitor]

	if(!ParamIsDefault(fifoPos))
		fifoPos = fifoPosValue
	endif

	return (offset + fifoPosValue) < stopCollectionPoint
End

#else

Function/S HW_ITC_ListOfOpenDevices()

	DEBUGPRINT("Unimplemented")
End

Function/S HW_ITC_ListDevices()

	DEBUGPRINT("Unimplemented")
End

threadsafe Function HW_ITC_HandleReturnValues_TS(flags, ITCError, ITCXOPError)
	variable flags, ITCError, ITCXOPError

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_HandleReturnValues(flags, ITCError, ITCXOPError)
	variable flags, ITCError, ITCXOPError

	DEBUGPRINT("Unimplemented")
End

threadsafe static Function/S HW_ITC_GetXOPErrorMessage(errCode)
	variable errCode

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_OpenDevice(deviceType, deviceNumber, [flags])
	variable deviceType, deviceNumber
	variable flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_CloseAllDevices([flags])
	variable flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_CloseDevice(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_SelectDevice(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_EnableYoking(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_DisableYoking(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINT("Unimplemented")
End

threadsafe Function HW_ITC_StopAcq_TS(deviceID, [prepareForDAQ, flags])
	variable deviceID, prepareForDAQ, flags

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_StopAcq(deviceID, [config, configFunc, prepareForDAQ, zeroDAC, flags])
	variable deviceID, prepareForDAQ, zeroDAC, flags
	WAVE/Z config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_GetCurrentDevice([flags])
	variable flags

	DEBUGPRINT("Unimplemented")
End

threadsafe static Function/WAVE HW_ITC_GetFifoPosFromConfig(config_t)
	WAVE config_t

	DEBUGPRINT_TS("Unimplemented")
End

threadsafe Function HW_ITC_ResetFifo_TS(deviceID, config, [flags])
	variable deviceID
	WAVE config
	variable flags

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_ResetFifo(deviceID, [config, configFunc, flags])
	variable deviceID
	WAVE/Z config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc
	variable  flags

	DEBUGPRINT("Unimplemented")
End

threadsafe Function HW_ITC_StartAcq_TS(deviceID, triggerMode, [flags])
	variable deviceID, triggerMode, flags

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_StartAcq(deviceID, triggerMode, [flags])
	variable deviceID, triggerMode, flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_IsRunning(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINT("Unimplemented")
End

Function/WAVE HW_ITC_GetState(deviceID, [flags])
	variable deviceID, flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_ReadADC(deviceID, channel, [flags])
	variable deviceID, channel, flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_WriteDAC(deviceID, channel, value, [flags])
	variable deviceID, channel, value, flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_ReadDigital(deviceID, xopChannel, [flags])
	variable deviceID, xopChannel, flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_WriteDigital(deviceID, xopChannel, value, [flags])
	variable deviceID, xopChannel, value, flags

	DEBUGPRINT("Unimplemented")
End

threadsafe Function HW_ITC_DebugMode_TS(state, [flags])
	variable state, flags

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_DebugMode(state, [flags])
	variable state, flags

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_PrepareAcq(deviceID, [data, dataFunc, config, configFunc, flags, offset])
	variable deviceID
	WAVE/Z data, config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, configFunc
	variable flags, offset

	DEBUGPRINT("Unimplemented")
End

threadsafe Function HW_ITC_MoreData_TS(deviceID, ADChannelToMonitor, stopCollectionPoint, config, [fifoPos, flags])
	variable deviceID
	variable ADChannelToMonitor, stopCollectionPoint
	WAVE config
	variable &fifoPos
	variable flags

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_MoreData(deviceID, [ADChannelToMonitor, stopCollectionPoint, config, configFunc, fifoPos, flags])
	variable deviceID
	variable ADChannelToMonitor, stopCollectionPoint
	WAVE/Z config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc
	variable &fifoPos
	variable flags

	DEBUGPRINT("Unimplemented")
End

#endif

/// @brief Construct the /Z flag value for the ITC operations.
///
/// Takes interactiveMode into account for automated testing.
threadsafe static Function HW_ITC_GetZValue(flags)
	variable flags

	NVAR interactiveMode = $GetInteractiveMode()

	if(interactiveMode)
		return flags & HARDWARE_PREVENT_ERROR_POPUP
	else
		return flags | HARDWARE_PREVENT_ERROR_POPUP
	endif
End

Function/Wave HW_WAVE_GETTER_PROTOTYPE(str)
	string str
end

threadsafe Function/WAVE HW_ITC_TransposeAndToDouble(wv)
	WAVE wv

	MatrixOp/FREE wv_t = fp64(wv^t)

	return wv_t
End

Function/WAVE HW_ITC_TransposeAndToInt(wv)
	WAVE wv

	MatrixOp/FREE wv_t = int32(wv^t)

	return wv_t
End

/// @name Utility functions not interacting with hardware
/// @{

/// @brief Returns the device channel offset for the given device
///
/// @returns 16 for ITC1600 and 0 for all other types
Function HW_ITC_CalculateDevChannelOff(panelTitle)
	string panelTitle

	variable ret
	string deviceType, deviceNum

	ret = ParseDeviceString(panelTitle, deviceType, deviceNum)
	ASSERT(ret, "Could not parse device string")

	if(!cmpstr(deviceType, "ITC1600"))
		return 16
	endif

	return 0
End

/// @brief Return the `first` and `last` TTL bits/channels for the given `rack`
Function HW_ITC_GetRackRange(rack, first, last)
	variable rack
	variable &first, &last

	if(rack == RACK_ZERO)
		first = 0
		last = NUM_ITC_TTL_BITS_PER_RACK - 1
	elseif(rack == RACK_ONE)
		first = NUM_ITC_TTL_BITS_PER_RACK
		last = 2 * NUM_ITC_TTL_BITS_PER_RACK - 1
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
		return ttlBit - NUM_ITC_TTL_BITS_PER_RACK
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

	if(ttlBit >= NUM_ITC_TTL_BITS_PER_RACK)
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
/// @}

/// @name NI
/// @{

/// @brief Assert on using an invalid NI device name
///
/// @param deviceName NI device name
Function HW_NI_AssertOnInvalid(deviceName)
	string deviceName

	ASSERT(HW_NI_IsValidDeviceName(deviceName), "Invalid NI device name")
End

/// @brief Check wether the given NI device name is valid
///
/// Currently a device name is valid if it is not empty.
Function HW_NI_IsValidDeviceName(deviceName)
	string deviceName

	return !isEmpty(deviceName)
End

#if exists("fDAQmx_DeviceNames")

/// @name Minimum voltages for the analog inputs/outputs
/// We always use the maximum range so that we have a constant resolution on the DAC
///@{
static Constant HW_NI_MIN_VOLTAGE = -10.0
static Constant HW_NI_MAX_VOLTAGE = +10.0
///@}

static Constant HW_NI_DIFFERENTIAL_SETUP = 0
static Constant HW_NI_FIFOSIZE = 10
// HW_NI_FIFO_MIN_FREE_DISC_SPACE = SAFETY * HW_NI_FIFOSIZE * sizeof(double) * NI_MAX_SAMPLE_RATE
// HW_NI_FIFO_MIN_FREE_DISC_SPACE = 2      * 10             *              8 * 500000
static Constant HW_NI_FIFO_MIN_FREE_DISC_SPACE = 80000000

/// @name Functions for interfacing with National Instruments Hardware
///

/// @see HW_StartAcq
Function HW_NI_StartAcq(deviceID, triggerMode, [flags, repeat])
	variable deviceID, triggerMode, flags, repeat

	string panelTitle, device, FIFONote, noteID, fifoName, errMsg
	variable i, pos, endpos, channelTimeOffset, freeDiskSpace

	if(ParamIsDefault(repeat))
		repeat = 0
	endif

	panelTitle = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID)
	device = HW_GetInternalDeviceName(HARDWARE_NI_DAC, deviceID)
	SVAR scanStr = $GetNI_AISetup(panelTitle)
	fifoName = GetNIFIFOName(deviceID)
	try
		freeDiskSpace = MU_GetFreeDiskSpace(GetWindowsPath(SpecialDirPath("Temporary", 0, 0, 0)))
		if(isNaN(freeDiskSpace) || freeDiskSpace < HW_NI_FIFO_MIN_FREE_DISC_SPACE)
			printf "%s: Can not start acquisition. Not enough free disk space for data buffer.\rThe free disk space is less than %.0W0PB (%.1W0PB).\r", panelTitle, HW_NI_FIFO_MIN_FREE_DISC_SPACE, freeDiskSpace
			ControlWindowToFront()
			return NaN
		endif
		CtrlFIFO $fifoName, start
		if(repeat)
			DAQmx_Scan/DEV=device/BKG/RPTC FIFO=scanStr
		else
			DAQmx_Scan/DEV=device/BKG FIFO=scanStr
		endif
		// The following code just gathers additional information that is printed out
		FIFOStatus/Q $fifoName
		FIFONote = StringByKey("NOTE", S_Info)
		noteID = "Channel dt="
		pos = strsearch(FIFONote, noteID, 0)
		if(pos > -1)
			pos += strlen(noteID)
			endpos = strsearch(FIFONote, "\r", pos)
			channelTimeOffset = str2num(FIFONote[pos, endpos - 1])
			DEBUGPRINT("Time offset between NI channels: " + num2str(channelTimeOffset*1E6) + " µs")
		endif
	catch
		errMsg = GetRTErrMessage()
		ASSERT(0, "Start acquisition of NI device " + panelTitle + " failed with code: " + num2str(getRTError(1)) + "\r" + errMsg)
	endtry
End

/// @brief Prepare for data acquisition
///
/// @param deviceID    device identifier
/// @param data        ITC data wave
/// @param dataFunc    [optional, defaults to GetITCDataWave()] override wave getter for the ITC data wave
/// @param config      ITC config wave
/// @param configFunc  [optional, defaults to GetITCChanConfigWave()] override wave getter for the ITC config wave
/// @param offset      [optional, defaults to zero] offset into the data wave in points
/// @param flags       [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_PrepareAcq(deviceID, [data, dataFunc, config, configFunc, flags, offset])
	variable deviceID
	WAVE/Z data, config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, configFunc
	variable flags, offset

	string panelTitle, tempStr, device, filename, clkStr, wavegenStr, TTLStr, fifoName, errMsg
	variable i, aiCnt, ttlCnt, channels, sampleIntervall, numEntries, fifoSize

	DEBUGPRINTSTACKINFO()

	panelTitle = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID)
	device = HW_GetInternalDeviceName(HARDWARE_NI_DAC, deviceID)

	if(ParamIsDefault(data))
		if(ParamIsDefault(dataFunc))
			WAVE/WAVE NIDataWave = GetHardwareDataWave(panelTitle)
		else
		// TODO
			WAVE/WAVE NIDataWave = dataFunc(panelTitle)
		endif
	endif

	if(ParamIsDefault(config))
		if(ParamIsDefault(configFunc))
			WAVE config = GetITCChanConfigWave(panelTitle)
		else
			WAVE config = configFunc(panelTitle)
		endif
	endif

	if(!ParamIsDefault(offset))
		config[][%Offset] = offset
	endif
// TODO MH case offset not 0

// Get AD Scaling
	WAVE gain = SWS_GetChannelGains(panelTitle)

	fifoName = GetNIFIFOName(deviceID)
	channels = DimSize(config, ROWS)
	SVAR scanStr = $GetNI_AISetup(panelTitle)
	scanStr = fifoName + ";"
	wavegenStr = ""
	TTLStr = ""
	Make/FREE/WAVE/N=(channels) TTLWaves

	try

		NewFIFO $fifoName
		aiCnt = 0
		ttlCnt = 0
		for(i = 0;i < channels; i += 1)
			switch(config[i][%ChannelType])
				case ITC_XOP_CHANNEL_TYPE_ADC:
					scanStr += num2str(config[i][%ChannelNumber]) + "/RSE,"
					scanStr += num2str(NI_ADC_MIN) + "," + num2str(NI_ADC_MAX) + ","
					scanStr += num2str(gain[i]) + ",0"
					scanStr += ";"
					// note: the second parameter encodes the attributed NIDataWave index into the FIFO channel name
					NewFIFOChan $fifoName, $num2str(i),0,1,NI_ADC_MIN,NI_ADC_MAX,"V"
					aiCnt += 1
					break
				case ITC_XOP_CHANNEL_TYPE_DAC:
					WAVE NIChannel = NIDataWave[i]
					wavegenStr += GetWavesDataFolder(NIChannel, 2) + ","
					wavegenStr += num2str(config[i][%ChannelNumber]) + ","
					sprintf tempStr, "%10f", max(-10, WaveMin(NIChannel) - 0.001)
					wavegenStr += tempStr + ","
					sprintf tempStr, "%10f", min(10, WaveMax(NIChannel) + 0.001)
					wavegenStr += tempStr + ";"
					break
				case ITC_XOP_CHANNEL_TYPE_TTL:
					TTLStr += "/" + device + "/port0/line" + num2str(config[i][%ChannelNumber]) + ","
					TTLWaves[ttlCnt]= NIDataWave[i]
					ttlCnt += 1
					break
			endswitch
		endfor

		sampleIntervall = config[0][%SamplingInterval] * 1E-6
		fifoSize = HW_NI_FIFOSIZE/sampleIntervall
		NVAR fifopos = $GetFifoPosition(panelTitle)
		fifopos = 0
		NVAR fnum = $GetFIFOFileRef(panelTitle)
		NewPath/O/Q tempNIAcqPath, SpecialDirPath("Temporary", 0, 0, 0)
		filename = "MIES_FIFO_" + paneltitle + ".DAT"
		Open/P=tempNIAcqPath fnum as filename
		KillPath tempNIAcqPath
		CtrlFIFO $fifoName, deltaT=sampleIntervall, size=fifoSize, file=fnum, note="MIES Analog In File"

		clkStr = "/" + device + "/ai/sampleclock"
		// note actually this does already 'starts' a measurement
		DAQmx_WaveFormGen/DEV=device/STRT=1/CLK={clkStr, 0} wavegenStr
		switch(ttlCnt)
			case 0:
				break
			case 1:
				DAQmx_DIO_Config/DEV=device/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0]} TTLStr
				break
			case 2:
				DAQmx_DIO_Config/DEV=device/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1]} TTLStr
				break
			case 3:
				DAQmx_DIO_Config/DEV=device/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2]} TTLStr
				break
			case 4:
				DAQmx_DIO_Config/DEV=device/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3]} TTLStr
				break
			case 5:
				DAQmx_DIO_Config/DEV=device/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3], TTLWaves[4]} TTLStr
				break
			case 6:
				DAQmx_DIO_Config/DEV=device/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3], TTLWaves[4], TTLWaves[5]} TTLStr
				break
			case 7:
				DAQmx_DIO_Config/DEV=device/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3], TTLWaves[4], TTLWaves[5], TTLWaves[6]} TTLStr
				break
			case 8:
				DAQmx_DIO_Config/DEV=device/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3], TTLWaves[4], TTLWaves[5], TTLWaves[6], TTLWaves[7]} TTLStr
				break
		endswitch
	catch
		errMsg = GetRTErrMessage()
		ASSERT(0, "Prepare acquisition of NI device " + panelTitle + " failed with code: " + num2str(getRTError(1)) + "\r" + errMsg)
	endtry
	NVAR taskID = $GetNI_TTLTaskID(panelTitle)
	taskID = ttlCnt ? V_DAQmx_DIO_TaskNumber : NaN
End

/// @brief returns properties of NI device

/// @param devNr number of NI device to query
/// @return keyword list of device properties, empty if device not present
Function/S HW_NI_GetPropertyListOfDevices(devNr)
	variable devNr

	string device

	variable numAI, numAO, numCounter, numDIO
	string devices
	string lines = ""
	string propList
	variable numDevices, i, portWidth

	if(devNr < 0)
		return ""
	endif
	DEBUGPRINTSTACKINFO()

	devices    = fDAQmx_DeviceNames()
	numDevices = ItemsInList(devices)
	if(devNr >= numDevices)
		return ""
	endif

	device = StringFromList(devNr, devices)
	numAI       = fDAQmx_NumAnalogInputs(device)
	numAO       = fDAQmx_NumAnalogOutputs(device)
	numCounter  = fDAQmx_NumCounters(device)
	numDIO      = fDAQmx_NumDIOPorts(device)
	for(i = 0; i < numDIO; i += 1)
		portWidth = fDAQmx_DIO_PortWidth(device, i)
		lines = AddListItem(num2str(portWidth), lines, ",", Inf)
	endfor
	lines = RemoveEnding(lines, ",")

	propList = "NAME:" + device
	propList += ";AI:" + num2str(numAI)
	propList += ";AO:" + num2str(numAO)
	propList += ";COUNTER:" + num2str(numCounter)
	propList += ";DIOPORTS:" + num2str(numDIO)
	propList += ";LINES:" + lines

	return propList
End

/// @name Functions for interfacing with National Instruments Hardware
///

/// @brief Opens a NI device, executes reset and self calibration

/// @param device name of NI device
/// @param flags [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_OpenDevice(device, [flags])
	string device
	variable flags

	HW_NI_ResetDevice(device, flags=flags)
	HW_NI_CalibrateDevice(device, flags=flags)
End

/// @name Functions for interfacing with National Instruments Hardware
///
/// The manual for the USB 6001 device is available [here](../NI-USB6001-374259a.pdf).

/// @brief Print all available properties of all NI devices to the commandline
Function HW_NI_PrintPropertiesOfDevices()
	string device

	variable numAI, numAO, numCounter, numDIO, selfCalDate
	string devices
	string lines = ""
	variable numDevices, extCalDate, i, j, portWidth

	DEBUGPRINTSTACKINFO()

	devices    = fDAQmx_DeviceNames()
	numDevices = ItemsInList(devices)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, devices)

		numAI       = fDAQmx_NumAnalogInputs(device)
		numAO       = fDAQmx_NumAnalogOutputs(device)
		numCounter  = fDAQmx_NumCounters(device)
		numDIO      = fDAQmx_NumDIOPorts(device)
		selfCalDate = fDAQmx_SelfCalDate(device)
		extCalDate  = fDAQmx_ExternalCalDate(device)

		for(j = 0; j < numDIO; j += 1)
			portWidth = fDAQmx_DIO_PortWidth(device, j)
			lines = AddListItem(num2str(portWidth), lines, ",", Inf)
		endfor

		lines = RemoveEnding(lines, ",")

		printf "Device name: %s\r", device
		printf "#AI %d, #AO %d, #Cnt %d, #DIO ports %d with (%s) lines\r", numAI, numAO, numCounter, numDIO, lines
		printf "Last self calibration: %s\r", SelectString(IsFinite(selfCalDate), "na", GetIso8601TimeStamp(secondsSinceIgorEpoch=selfCalDate))
		printf "Last external calibration: %s\r", GetIso8601TimeStamp(secondsSinceIgorEpoch=extCalDate)
	endfor
End

/// @brief Read the digital port or single line
///
/// @param device name of the NI device
/// @param DIOPort [optional, defaults to `port0`] DIO port to query
/// @param DIOLine [optional, defaults to all lines of the port] Allows to write
///                only a single line instead of all bits of the port
/// @param flags   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return bitmask of variable width
Function HW_NI_ReadDigital(device, [DIOPort, DIOLine, flags])
	string device
	variable DIOPort, DIOLine, flags

	variable taskID, ret, result, lineGrouping, err
	string line

	DEBUGPRINTSTACKINFO()

	if(ParamIsDefault(DIOPort))
		DIOPort = 0
	endif

	if(ParamIsDefault(DIOLine))
		sprintf line "/%s/port%d", device, DIOPort
		lineGrouping = 0
	else
		lineGrouping = 1
		ASSERT(DIOline <= fDAQmx_DIO_PortWidth(device, DIOport), "Line does not exist in port")
		sprintf line "/%s/port%d/line%d", device, DIOPort, DIOline
	endif

	// clear RTE
	err = GetRTError(1)
	DAQmx_DIO_Config/DEV=device/DIR=1/LGRP=(lineGrouping) line
	if (GetRTError(1))
		print fDAQmx_ErrorString()
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling DAQmx_DIO_Config")
		endif
		return NaN
	endif

	taskID = V_DAQmx_DIO_TaskNumber

	result = fDAQmx_DIO_Read(device, taskID)

	ret = fDAQmx_DIO_Finished(device, taskID)
	if(ret)
		print fDAQmx_ErrorString()
		printf "Error %d: fDAQmx_DIO_Finished\r", ret
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling fDAQmx_DIO_Finished")
		endif
	endif

	return result
End

/// @brief Write the digital port or single line
///
/// @param device  name of the NI device
/// @param value   bitmask of variable width to write, width must be smaller
///                than the lines of the port
/// @param DIOPort [optional, defaults to `port0`] DIO port to write
/// @param DIOLine [optional, defaults to all lines of the port] Allows to write
///                only a single line instead of all bits of the port
/// @param flags   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_WriteDigital(device, value, [DIOPort, DIOLine, flags])
	string device
	variable DIOPort, DIOLine, value, flags

	variable taskID, ret, lineGrouping, err
	string line

	DEBUGPRINTSTACKINFO()

	if(ParamIsDefault(DIOPort))
		DIOPort = 0
	endif

	if(ParamIsDefault(DIOLine))
		sprintf line "/%s/port%d", device, DIOPort
		lineGrouping = 0
	else
		lineGrouping = 1
		ASSERT(DIOline <= fDAQmx_DIO_PortWidth(device, DIOport), "Line does not exist in port")
		sprintf line "/%s/port%d/line%d", device, DIOPort, DIOline
	endif

	// clear RTE
	err = GetRTError(1)
	DAQmx_DIO_Config/DEV=device/DIR=1/LGRP=(lineGrouping) line
	if (GetRTError(1))
		print fDAQmx_ErrorString()
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling DAQmx_DIO_Config")
		endif
		return NaN
	endif

	taskID = V_DAQmx_DIO_TaskNumber

	ASSERT(log(value)/log(2) <= fDAQmx_DIO_PortWidth(device, DIOport), "value has bits sets which are higher than the number of output lines in this port")
	ret = fDAQmx_DIO_Write(device, taskID, value)
	if(ret)
		print fDAQmx_ErrorString()
		printf "Error %d: fDAQmx_DIO_Write\r", ret
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling fDAQmx_DIO_Write")
		endif
	endif

	ret = fDAQmx_DIO_Finished(device, taskID)
	if(ret)
		print fDAQmx_ErrorString()
		printf "Error %d: fDAQmx_DIO_Finished\r", ret
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling fDAQmx_DIO_Finished")
		endif
	endif

	return ret
End

/// @brief Write a single value to the given device and analog output channel
///
/// This function is only to be used for single readings and *not* for real DAQ!
///
/// @param device  name of the NI device
/// @param channel analog channel to write to
/// @param value   value to write in volts
/// @param flags   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return 0 on success, 1 otherwise
Function HW_NI_WriteAnalogSingleAndSlow(device, channel, value, [flags])
	string device
	variable channel, value, flags

	variable ret

	DEBUGPRINTSTACKINFO()

	ASSERT(value < HW_NI_MAX_VOLTAGE && value > HW_NI_MIN_VOLTAGE, "Value to set is out of range")
	ret = fDAQmx_WriteChan(device, channel, value, HW_NI_MIN_VOLTAGE, HW_NI_MAX_VOLTAGE)

	if(ret)
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error: " + fDAQmx_ErrorString())
		else
			DEBUGPRINT("Error: ", str=fDAQmx_ErrorString())
		endif
	endif

	return ret
End

/// @brief Read a single value from the given analog output channel
///
/// This function is only to be used for single readings and *not* for real DAQ!
///
/// @param device  name of the NI device
/// @param channel analog channel to read from
/// @param flags   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return volts
Function HW_NI_ReadAnalogSingleAndSlow(device, channel, [flags])
	string device
	variable channel, flags

	variable value

	DEBUGPRINTSTACKINFO()

	value = fDAQmx_ReadChan(device, channel, HW_NI_MIN_VOLTAGE, HW_NI_MAX_VOLTAGE, HW_NI_DIFFERENTIAL_SETUP)

	if(!IsFinite(value))
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error " + fDAQmx_ErrorString())
		else
			DEBUGPRINT("Error: ", str=fDAQmx_ErrorString())
		endif
	endif

	return value
End

/// @brief Return a list of all NI devices which can be opened
///
/// @param flags [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function/S HW_NI_ListDevices([flags])
	variable flags

	DEBUGPRINTSTACKINFO()

	return fDAQmx_DeviceNames()
End

/// @brief Stop scanning and waveform generation
///
/// @param deviceID ID of the NI device
/// @param deviceID      device identifier
/// @param config        [optional] ITC config wave
/// @param configFunc    [optional, defaults to GetITCChanConfigWave()] override wave getter for the ITC config wave
/// @param prepareForDAQ [optional, defaults to false] prepare for next DAQ immediately
/// @param zeroDAC       [optional, defaults to false] set all DA channels to zero
/// @param flags         [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @see HW_StopAcq
Function HW_NI_StopAcq(deviceID, [config, configFunc, prepareForDAQ, zeroDAC, flags])
	variable deviceID, prepareForDAQ, zeroDAC, flags
	WAVE/Z config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc

	DEBUGPRINTSTACKINFO()

	variable i, channels, aoChannel, ret, err
	string panelTitle, paraStr, device, errMsg

	// dont stop here, only if all devices removed
	device = HW_GetInternalDeviceName(HARDWARE_NI_DAC, deviceID)
	panelTitle = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID)
	ret = fDAQmx_ScanStop(device)
	// note: calling Stop on a finished scan generates an error code
	if(ret)
		print fDAQmx_ErrorString()
		printf "Error %d: fDAQmx_ScanStop\r", ret
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling fDAQmx_ScanStop (has Scan already finished?)")
		endif
	endif
	ret = fDAQmx_WaveformStop(device)
	if(ret)
		print fDAQmx_ErrorString()
		printf "Error %d: fDAQmx_WaveformStop\r", ret
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling fDAQmx_WaveformStop")
		endif
	endif

	NVAR taskID = $GetNI_TTLTaskID(panelTitle)
	if(!isNaN(taskID))
		ret = fDAQmx_DIO_Finished(device, taskID)
		if(ret)
			print fDAQmx_ErrorString()
			printf "Error %d: fDAQmx_DIO_Finished\r", ret
			ControlWindowToFront()
			if(flags & HARDWARE_ABORT_ON_ERROR)
				ASSERT(0, "Error calling fDAQmx_DIO_Finished")
			endif
		endif
	endif

	if(zeroDAC)
		if(ParamIsDefault(config))
			if(ParamIsDefault(configFunc))
				WAVE config = GetITCChanConfigWave(panelTitle)
			else
				WAVE config = configFunc(panelTitle)
			endif
		endif
		paraStr = ""
		channels = DimSize(config, ROWS)
		for(i = 0;i < channels; i += 1)
			if(config[i][%ChannelType] == ITC_XOP_CHANNEL_TYPE_DAC)
				paraStr += "0," + num2str(aoChannel) + ";"
				aoChannel += 1
			endif
		endfor
		// clear RTE
		err = GetRTError(1)
		DAQmx_AO_SetOutputs/DEV=device paraStr
		if(GetRTError(1))
			print fDAQmx_ErrorString()
			ControlWindowToFront()
			if(flags & HARDWARE_ABORT_ON_ERROR)
				ASSERT(0, "Error calling DAQmx_AO_SetOutputs")
			endif
			return NaN
		endif
	endif

	HW_NI_KillFifo(deviceID)
End

/// @brief Kill the FIFO of the given NI device
///
/// @param deviceID device identifier
Function HW_NI_KillFifo(deviceID)
	variable deviceID

	string fifoName, errMsg, panelTitle

	panelTitle = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID)
	fifoName = GetNIFIFOName(deviceID)

	FIFOStatus/Q $fifoName
	if(!V_Flag)
		return NaN
	endif

	try
		if(V_FIFORunning)
			CtrlFIFO $fifoName stop; AbortOnRTE
		endif
		DoXOPIdle
		KillFIFO $fifoName; AbortOnRTE
	catch
		errMsg = GetRTErrMessage()
		print "Could not cleanup FIFO of NI device " + panelTitle + ", failed with code: " + num2str(getRTError(1)) + "\r" + errMsg
		ControlWindowToFront()
	endtry
End

/// @brief Reset device
///
/// @param device name of the NI device
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_ResetDevice(device, [flags])
	string device
	variable flags

	variable ret

	DEBUGPRINTSTACKINFO()

	ret = fDAQmx_resetDevice(device)
	if(ret)
		print fDAQmx_ErrorString()
		printf "Error %d: fDAQmx_resetDevice\r", ret
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling fDAQmx_resetDevice")
		endif
	endif
End

/// @brief Check if the device is running
///
/// @param device name of the NI device
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_IsRunning(device, [flags])
	string device
	variable flags

	DEBUGPRINTSTACKINFO()

	string errMsg
	variable WFstatus = fDAQmx_WF_IsFinished(device)
	if(isNan(WFstatus))
		errMsg = fDAQmx_ErrorString()
		if(strsearch(errMsg, "No waveform operation is currently running for that device", 0) == -1)
			print errMsg
			print "Error: fDAQmx_WF_IsFinished\r"
			ControlWindowToFront()
			if(flags & HARDWARE_ABORT_ON_ERROR)
				ASSERT(0, "Error calling fDAQmx_WF_IsFinished")
			endif
		else
			return 0
		endif
	elseif(WFstatus == 0)
		return 1
	endif
	return 0
End

/// @brief Calibrate a NI device if it wasn't calibrated within the last 24h.
///
/// @param device name of the NI device
/// @param force  [optional, default 0] When not zero, forces a calibration
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_CalibrateDevice(device, [force, flags])
	string device
	variable force, flags

	variable ret

	DEBUGPRINTSTACKINFO()

	if(ParamIsDefault(force))
		force = 0
	else
		force = !!force
	endif

	if((DateTime - fDAQmx_SelfCalDate(device)) >= 86400 || force)
		ret = fDAQmx_selfCalibration(device, 0)
		if(ret)
			print fDAQmx_ErrorString()
			printf "Error %d: fDAQmx_selfCalibration\r", ret
			ControlWindowToFront()
			if(flags & HARDWARE_ABORT_ON_ERROR)
				ASSERT(0, "Error calling fDAQmx_selfCalibration")
			endif
		endif
	endif
End

/// @see HW_CloseDevice
Function HW_NI_CloseDevice(deviceID, [flags])
	variable deviceID, flags

	string deviceType, deviceNumber
	DEBUGPRINTSTACKINFO()

	ASSERT(ParseDeviceString(HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID), deviceType, deviceNumber), "Error parsing device string!")

	if(HW_NI_IsRunning(deviceType, flags=flags))
		HW_NI_StopAcq(deviceID, flags=flags)
	else
		HW_NI_KillFifo(deviceID)
	endif

	HW_NI_ResetDevice(deviceType, flags=flags)
End


#else

Function HW_NI_StartAcq(deviceID, triggerMode, [flags, repeat])
	variable deviceID, triggerMode, flags, repeat
	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_PrepareAcq(deviceID, [data, dataFunc, config, configFunc, flags, offset])
	variable deviceID
	WAVE/Z data, config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, configFunc
	variable flags, offset

	DoAbortNow("NI-DAQ XOP is not available")
End

Function/S HW_NI_GetPropertyListOfDevices(devNr)
	variable devNr
	return ""
End

Function HW_NI_PrintPropertiesOfDevices()
	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_ReadDigital(device, [DIOPort, DIOLine, flags])
	string device
	variable DIOPort, DIOLine, flags

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_WriteDigital(device, value, [DIOPort, DIOLine, flags])
	string device
	variable DIOPort, DIOLine, value, flags

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_WriteAnalogSingleAndSlow(device, channel, value, [flags])
	string device
	variable channel, value, flags

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_ReadAnalogSingleAndSlow(device, channel, [flags])
	string device
	variable channel, flags

	DoAbortNow("NI-DAQ XOP is not available")
End

Function/S HW_NI_ListDevices([flags])
	variable flags

	return ""
End

Function HW_NI_StopAcq(deviceID, [config, configFunc, prepareForDAQ, zeroDAC, flags])
	variable deviceID, prepareForDAQ, zeroDAC, flags
	WAVE/Z config
	FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_ResetDevice(device, [flags])
	string device
	variable flags

	DoAbortNow("NI-DAQ XOP is not available")
End

HW_NI_CalibrateDevice(device, [force, flags])
	string device
	variable force, flags

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_IsRunning(device, [flags])
	string device
	variable flags

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_OpenDevice(device, [flags])
	string device
	variable flags

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_CloseDevice(deviceID, [flags])
	variable deviceID, flags

	DoAbortNow("NI-DAQ XOP is not available")
End


#endif // exists NI DAQ XOP

/// @}
