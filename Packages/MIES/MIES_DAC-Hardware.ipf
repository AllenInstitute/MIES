#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_HW
#endif // AUTOMATED_TESTING

/// @file MIES_DAC-Hardware.ipf
/// @brief __HW__ Low level hardware configuration and querying functions
///
/// Naming scheme of the functions is `HW_$TYPE_$Suffix` where `$TYPE` is one of `ITC` or `NI`.

#if exists("ITCSelectDevice2")
#define ITC_XOP_PRESENT
#endif

/// Generic check for NIDAQmx XOP
///
/// In case newer functions are required which might
/// not be present in all NIDAQmx XOP versions,
/// check for their existance directly
#if exists("fDAQmx_DeviceNames")
#define NIDAQMX_XOP_PRESENT
#endif

#if exists("SutterDAQScanWave")
#define SUTTER_XOP_PRESENT
#endif

/// @name Error codes for the ITC XOP2
/// @anchor ITCXOP2Errors
///@{
static Constant OLD_IGOR = 10001

static Constant UNHANDLED_CPP_EXCEPTION = 10002

// DeviceID is locked to another thread.
static Constant SLOT_LOCKED_TO_OTHER_THREAD = 10003
// Tried to access an unused DeviceID.
static Constant SLOT_EMPTY = 10004
// No DeviceIDs available to use.
static Constant COULDNT_FIND_EMPTY_SLOT = 10005

// ITC DLL errors
static Constant ITC_DLL_ERROR = 10006

// Invalid numeric device type (/DTN).
static Constant INVALID_DEVICETYPE_NUMERIC = 10007
// Invalid string device type (/DTS).
static Constant INVALID_DEVICETYPE_STRING = 10008
// The device types specified by /DTN and /DTS do not agree.
static Constant DTN_DTS_DISAGREE = 10009

// Invalid numeric channel type (/CHN).
static Constant INVALID_CHANNELTYPE_NUMERIC = 10010
// Invalid string channel type (/CHS).
static Constant INVALID_CHANNELTYPE_STRING = 10011
// The channel types specified by /CHN and /CHS do not agree.
static Constant CHN_CHS_DISAGREE = 10012
// Must specify /CHN or /CHS.
static Constant MUST_SPECIFY_CHN_OR_CHS = 10013

// ITCConfigChannel2 flags
// Invalid value for /S flag.
static Constant ITCCONFIGCHANNEL2_BAD_S = 10014
// Invalid value for /M flag.
static Constant ITCCONFIGCHANNEL2_BAD_M = 10015
// Invalid value for /A flag.
static Constant ITCCONFIGCHANNEL2_BAD_A = 10016
// Invalid value for /O flag.
static Constant ITCCONFIGCHANNEL2_BAD_O = 10017
// Invalid value for /U flag.
static Constant ITCCONFIGCHANNEL2_BAD_U = 10018

// Wave does not have the minumum number of rows required
static Constant NEED_MIN_ROWS = 10019

// ITCInitialize2 errors
// The /F flag requires an ITC18, ITC18USB or ITC1600
static Constant F_FLAG_REQ_ITC18_18USB_1600 = 10020
// The /D flag requires an ITC1600
static Constant D_FLAG_REQUIRES_ITC1600 = 10021
// The /H flag requires an ITC1600
static Constant H_FLAG_REQUIRES_ITC1600 = 10022
// The /R flag requires an ITC1600
static Constant R_FLAG_REQUIRES_ITC1600 = 10023

// Tried to access the default device, but the default device has not been set.
static Constant THREAD_DEVICE_ID_NOT_SET = 10024
///@}

static Constant HW_ITC_RUNNING_STATE = 0x10
static Constant HW_ITC_MAX_TIMEOUT   = 10
static Constant HW_ITC_DSP_TIMEOUT   = 0x80303001

static Constant SUTTER_CHANNELOFFSET_TTL      = 3
static Constant SUTTER_ACQUISITION_FOREGROUND = 1
static Constant SUTTER_ACQUISITION_BACKGROUND = 2

/// @name Wrapper functions redirecting to the correct internal implementations depending on #HARDWARE_DAC_TYPES
///@{

/// @brief Prepare for data acquisition
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param mode         one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param data         hardware data wave
/// @param dataFunc     [optional, defaults to GetDAQDataWave()] override wave getter for the ITC data wave
/// @param config       ITC config wave
/// @param configFunc   [optional, defaults to GetDAQConfigWave()] override wave getter for the ITC config wave
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
/// @param offset       [optional, defaults to zero] offset into the data wave in points
Function HW_PrepareAcq(variable hardwareType, variable deviceID, variable mode, [WAVE/Z data, FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable flags, variable offset])

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return HW_ITC_PrepareAcq(deviceID, mode, flags = flags)
			break
		case HARDWARE_NI_DAC:
			return HW_NI_PrepareAcq(deviceID, mode, flags = flags)
			break
		case HARDWARE_SUTTER_DAC:
			return HW_SU_PrepareAcq(deviceID, mode, flags = flags)
		default:
			ASSERT(0, "Unsupported hardware type")
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
Function HW_SelectDevice(variable hardwareType, variable deviceID, [variable flags])

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return HW_ITC_SelectDevice(deviceID, flags = flags)
			break
		case HARDWARE_NI_DAC: // intended drop through
		case HARDWARE_SUTTER_DAC:
			// nothing to do
			return 0
		default:
			ASSERT(0, "Unsupported hardware type")
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
Function HW_OpenDevice(string deviceToOpen, variable &hardwareType, [variable flags])

	string deviceType, deviceNumber
	variable deviceTypeIndex, deviceNumberIndex, deviceID, prelimHWType

	hardwareType = GetHardwareType(deviceToOpen)
	switch(hardwareType)
		case HARDWARE_NI_DAC:
			deviceID = WhichListItem(deviceToOpen, HW_NI_ListDevices())
			HW_NI_OpenDevice(deviceToOpen, flags = flags)
			break
		case HARDWARE_SUTTER_DAC:
			HW_SU_OpenDevice(flags = flags)
			deviceID = 0
			break
		case HARDWARE_ITC_DAC:
			ParseDeviceString(deviceToOpen, deviceType, deviceNumber)
			deviceTypeIndex   = WhichListItem(deviceType, DEVICE_TYPES_ITC)
			deviceNumberIndex = WhichListItem(deviceNumber, DEVICE_NUMBERS)
			deviceID          = HW_ITC_OpenDevice(deviceTypeIndex, deviceNumberIndex, flags = flags)
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
Function HW_CloseDevice(variable hardwareType, variable deviceID, [variable flags])

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_CloseDevice(deviceID, flags = flags)
			break
		case HARDWARE_NI_DAC:
			HW_NI_CloseDevice(deviceID, flags = flags)
			break
		case HARDWARE_SUTTER_DAC:
			HW_SU_CloseDevice(deviceID, flags = flags)
			break
		default:
			ASSERT(0, "Unsupported hardware type")
			break
	endswitch
End

/// @brief Write a value to a DA/AO channel
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param channel      hardware channel number
/// @param value        value to write in volts
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_WriteDAC(variable hardwareType, variable deviceID, variable channel, variable value, [variable flags])

	string realDeviceOrPressure

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_WriteDAC(deviceID, channel, value, flags = flags)
			break
		case HARDWARE_NI_DAC:
			realDeviceOrPressure = HW_GetDeviceName(hardwareType, deviceID, flags = flags)
			HW_NI_AssertOnInvalid(realDeviceOrPressure)
			HW_NI_WriteAnalogSingleAndSlow(realDeviceOrPressure, channel, value, flags = flags)
			break
		case HARDWARE_SUTTER_DAC:
			HW_SU_WriteDAC(deviceID, channel, value, flags = flags)
			break
		default:
			ASSERT(0, "Unsupported hardware type")
			break
	endswitch
End

/// @brief Read a value from an AD/AI channel
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param channel      hardware channel number
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return value in volts
Function HW_ReadADC(variable hardwareType, variable deviceID, variable channel, [variable flags])

	string realDeviceOrPressure

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return HW_ITC_ReadADC(deviceID, channel, flags = flags)
			break
		case HARDWARE_NI_DAC:
			realDeviceOrPressure = HW_GetDeviceName(hardwareType, deviceID, flags = flags)
			HW_NI_AssertOnInvalid(realDeviceOrPressure)
			return HW_NI_ReadAnalogSingleAndSlow(realDeviceOrPressure, channel, flags = flags)
			break
		case HARDWARE_SUTTER_DAC:
			return HW_SU_ReadADC(deviceID, channel, flags = flags)
			break
		default:
			ASSERT(0, "Unsupported hardware type")
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
Function HW_ReadDigital(variable hardwareType, variable deviceID, variable channel, [variable line, variable flags])

	string realDeviceOrPressure
	variable rack, xopChannel, ttlBit

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			realDeviceOrPressure = HW_GetDeviceName(HARDWARE_ITC_DAC, deviceID, flags = flags)
			HW_ITC_AssertOnInvalid(realDeviceOrPressure)
			ttlBit     = channel
			rack       = HW_ITC_GetRackForTTLBit(realDeviceOrPressure, ttlBit)
			xopChannel = HW_ITC_GetITCXOPChannelForRack(realDeviceOrPressure, rack)
			return HW_ITC_ReadDigital(deviceID, xopChannel, flags = flags)
			break
		case HARDWARE_NI_DAC:
			realDeviceOrPressure = HW_GetDeviceName(hardwareType, deviceID, flags = flags)
			HW_NI_AssertOnInvalid(realDeviceOrPressure)
			if(ParamisDefault(line))
				return HW_NI_ReadDigital(realDeviceOrPressure, DIOPort = channel, flags = flags)
			else
				return HW_NI_ReadDigital(realDeviceOrPressure, DIOPort = channel, DIOline = line, flags = flags)
			endif
			break
		case HARDWARE_SUTTER_DAC:
			ASSERT(0, "Not yet implemented")
		default:
			ASSERT(0, "Unsupported hardware type")
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
Function HW_WriteDigital(variable hardwareType, variable deviceID, variable channel, variable value, [variable line, variable flags])

	string realDeviceOrPressure
	variable ttlBit, rack, xopChannel

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			realDeviceOrPressure = HW_GetDeviceName(HARDWARE_ITC_DAC, deviceID, flags = flags)
			HW_ITC_AssertOnInvalid(realDeviceOrPressure)
			ttlBit     = channel
			rack       = HW_ITC_GetRackForTTLBit(realDeviceOrPressure, ttlBit)
			xopChannel = HW_ITC_GetITCXOPChannelForRack(realDeviceOrPressure, rack)
			HW_ITC_WriteDigital(deviceID, xopChannel, value, flags = flags)
			break
		case HARDWARE_NI_DAC:
			realDeviceOrPressure = HW_GetDeviceName(hardwareType, deviceID, flags = flags)
			HW_NI_AssertOnInvalid(realDeviceOrPressure)
			if(ParamisDefault(line))
				HW_NI_WriteDigital(realDeviceOrPressure, value, DIOPort = channel, flags = flags)
			else
				HW_NI_WriteDigital(realDeviceOrPressure, value, DIOPort = channel, DIOline = line, flags = flags)
			endif
			break
		case HARDWARE_SUTTER_DAC:
			ASSERT(0, "Not yet implemented")
		default:
			ASSERT(0, "Unsupported hardware type")
			break
	endswitch
End

/// @brief Enable yoking
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_EnableYoking(variable hardwareType, variable deviceID, [variable flags])

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_EnableYoking(deviceID, flags = flags)
			break
		case HARDWARE_NI_DAC: // intended drop through
		case HARDWARE_SUTTER_DAC:
			ASSERT(0, "Not implemented")
			break
		default:
			ASSERT(0, "Unsupported hardware type")
			break
	endswitch
End

/// @brief Enable yoking
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_DisableYoking(variable hardwareType, variable deviceID, [variable flags])

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_DisableYoking(deviceID, flags = flags)
			break
		case HARDWARE_NI_DAC: // intended drop through
		case HARDWARE_SUTTER_DAC:
			ASSERT(0, "Not implemented")
			break
		default:
			ASSERT(0, "Unsupported hardware type")
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
Function HW_StopAcq(variable hardwareType, variable deviceID, [variable prepareForDAQ, variable zeroDAC, variable flags])

	string device
	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_StopAcq(deviceID, prepareForDAQ = prepareForDAQ, zeroDAC = zeroDAC, flags = flags)
			break
		case HARDWARE_NI_DAC:
			HW_NI_StopAcq(deviceID, zeroDAC = zeroDAC, flags = flags)
			break
		case HARDWARE_SUTTER_DAC:
			HW_SU_StopAcq(deviceID, zeroDAC = zeroDAC, flags = flags)
			break
		default:
			ASSERT(0, "Unsupported hardware type")
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
Function HW_IsRunning(variable hardwareType, variable deviceID, [variable flags])

	string realDeviceOrPressure, device
	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return HW_ITC_IsRunning(deviceID, flags = flags)
		case HARDWARE_NI_DAC:
			realDeviceOrPressure = HW_GetDeviceName(hardwareType, deviceID, flags = flags)
			HW_NI_AssertOnInvalid(realDeviceOrPressure)
			return HW_NI_IsRunning(realDeviceOrPressure)
		case HARDWARE_SUTTER_DAC:
			device = HW_GetMainDeviceName(HARDWARE_SUTTER_DAC, deviceID, flags = flags)
			return HW_SU_IsRunning(device)
		default:
			ASSERT(0, "Unsupported hardware type")
			break
	endswitch
End

/// @brief Return hardware specific information from the device
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return free numeric/text wave with information and dimension labels
Function/WAVE HW_GetDeviceInfo(variable hardwareType, variable deviceID, [variable flags])

	string realDeviceOrPressure
	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return HW_ITC_GetDeviceInfo(deviceID, flags = flags)
			break
		case HARDWARE_NI_DAC:
			realDeviceOrPressure = HW_GetDeviceName(hardwareType, deviceID, flags = flags)
			HW_NI_AssertOnInvalid(realDeviceOrPressure)
			return HW_NI_GetDeviceInfo(realDeviceOrPressure, flags = flags)
			break
		case HARDWARE_SUTTER_DAC:
			return GetSUDeviceInfo()
			break
		default:
			ASSERT(0, "Unsupported hardware type")
			break
	endswitch
End

/// @brief Return hardware specific information from the device
///
/// This function does not require the device to be registered compared to HW_GetDeviceInfo().
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param device name of the device
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function/WAVE HW_GetDeviceInfoUnregistered(variable hardwareType, string device, [variable flags])

	variable deviceID

#ifdef EVIL_KITTEN_EATING_MODE
	return $""
#endif // EVIL_KITTEN_EATING_MODE

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			deviceID = HW_OpenDevice(device, hardwareType, flags = flags)

			if(!HW_IsValidDeviceID(deviceID))
				return $""
			endif

			WAVE devInfo = HW_ITC_GetDeviceInfo(deviceID, flags = flags)
			HW_CloseDevice(hardwareType, deviceID, flags = flags)
			break
		case HARDWARE_NI_DAC:
			HW_NI_AssertOnInvalid(device)
			WAVE/Z devInfo = HW_NI_GetDeviceInfo(device, flags = flags)
			// nothing to do for NI
			break
		case HARDWARE_SUTTER_DAC:
			WAVE/Z devInfo = GetSUDeviceInfo()
			break
		default:
			ASSERT(0, "Unsupported hardware")
	endswitch

	return devInfo
End

/// @brief Fill the device info wave
Function HW_WriteDeviceInfo(variable hardwareType, string device, WAVE deviceInfo)

	variable deviceID

#ifdef EVIL_KITTEN_EATING_MODE
	deviceInfo[%HardwareType] = hardwareType
	deviceInfo[%AD]           = 1024
	deviceInfo[%DA]           = 1024
	deviceInfo[%TTL]          = 1024
	deviceInfo[%Rack]         = NaN
	deviceInfo[%AuxAD]        = NaN
	deviceInfo[%AuxDA]        = NaN

	return NaN
#endif // EVIL_KITTEN_EATING_MODE

#ifndef ITC_XOP_PRESENT
	if(hardwareType == HARDWARE_ITC_DAC)
		return NaN
	endif
#endif // !ITC_XOP_PRESENT

#ifndef NIDAQMX_XOP_PRESENT
	if(hardwareType == HARDWARE_NI_DAC)
		return NaN
	endif
#endif // !NIDAQMX_XOP_PRESENT

#ifndef SUTTER_XOP_PRESENT
	if(hardwareType == HARDWARE_SUTTER_DAC)
		return NaN
	endif
#endif // !SUTTER_XOP_PRESENT

	deviceID = ROVar(GetDAQDeviceID(device))

	if(HW_IsValidDeviceID(deviceID) && !HW_SelectDevice(hardwareType, deviceID, flags = HARDWARE_PREVENT_ERROR_MESSAGE))
		WAVE/Z devInfoHW = HW_GetDeviceInfo(hardwareType, deviceID)
	else
		WAVE/Z devInfoHW = HW_GetDeviceInfoUnregistered(hardwareType, device, flags = HARDWARE_PREVENT_ERROR_MESSAGE)
	endif

	if(!WaveExists(devInfoHW))
		return NaN
	endif

	deviceInfo[%HardwareType] = hardwareType

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			deviceInfo[%AD]    = devInfoHW[%ADCCount]
			deviceInfo[%DA]    = devInfoHW[%DACCount]
			deviceInfo[%Rack]  = ceil(min(devInfoHW[%DOCount], devInfoHW[%DICount]) / 3)
			deviceInfo[%TTL]   = (deviceInfo[%Rack] == 1) ? 4 : 8
			deviceInfo[%AuxAD] = NaN
			deviceInfo[%AuxDA] = NaN
			break
		case HARDWARE_NI_DAC:
			WAVE/T devInfoHWText = devInfoHW
			deviceInfo[%AD]    = str2num(devInfoHWText[%AI])
			deviceInfo[%DA]    = str2num(devInfoHWText[%AO])
			deviceInfo[%TTL]   = str2num(devInfoHWText[%DIOPortWidth])
			deviceInfo[%Rack]  = NaN
			deviceInfo[%AuxAD] = NaN
			deviceInfo[%AuxDA] = NaN
			break
		case HARDWARE_SUTTER_DAC:
			WAVE/T devInfoHWText = devInfoHW
			deviceInfo[%AD]    = str2num(devInfoHWText[%SUMHEADSTAGES])
			deviceInfo[%DA]    = str2num(devInfoHWText[%SUMHEADSTAGES])
			deviceInfo[%TTL]   = str2num(devInfoHWText[%DIOPortWidth])
			deviceInfo[%Rack]  = NaN
			deviceInfo[%AuxAD] = str2num(devInfoHWText[%AI])
			deviceInfo[%AuxDA] = str2num(devInfoHWText[%AO])
			break
		default:
			ASSERT(0, "Unsupported hardware type")
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
Function HW_StartAcq(variable hardwareType, variable deviceID, [variable triggerMode, variable flags, variable repeat])

	HW_AssertOnInvalid(hardwareType, deviceID)

	if(ParamIsDefault(triggerMode))
		triggerMode = HARDWARE_DAC_DEFAULT_TRIGGER
	endif

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_StartAcq(deviceID, triggerMode, flags = flags)
			break
		case HARDWARE_NI_DAC:
			HW_NI_StartAcq(deviceID, triggerMode, flags = flags, repeat = repeat)
			break
		case HARDWARE_SUTTER_DAC:
			HW_SU_StartAcq(deviceID, flags = flags)
			break
		default:
			ASSERT(0, "Unknown hardware type")
	endswitch
End

/// @brief Reset the device
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ResetDevice(variable hardwareType, variable deviceID, [variable flags])

	string realDeviceOrPressure
	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			// no equivalent functionality
			break
		case HARDWARE_NI_DAC:
			realDeviceOrPressure = HW_GetDeviceName(hardwareType, deviceID, flags = flags)
			HW_NI_AssertOnInvalid(realDeviceOrPressure)
			HW_NI_ResetDevice(realDeviceOrPressure, flags = flags)
			break
		case HARDWARE_SUTTER_DAC:
			HW_SU_ResetDevice(flags = flags)
			break
		default:
			ASSERT(0, "Unknown hardware type")
	endswitch
End

/// @brief Assert on using an invalid value of `hardwareType` or `deviceID`
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID     device identifier
Function HW_AssertOnInvalid(variable hardwareType, variable deviceID)

	ASSERT(HW_IsValidHardwareType(hardwareType), "Invalid hardwareType")
	ASSERT(HW_IsValidDeviceID(deviceID), "Invalid deviceID")
End

/// @brief Check if the given hardware type is valid
///
/// Invalid here means that the value is out-of-range.
static Function HW_IsValidHardwareType(variable hardwareType)

#ifndef EVIL_KITTEN_EATING_MODE
	return hardwareType == HARDWARE_NI_DAC || hardwareType == HARDWARE_ITC_DAC || hardwareType == HARDWARE_SUTTER_DAC
#else
	return 1
#endif // !EVIL_KITTEN_EATING_MODE
End

/// @brief Check if the given device ID is valid
///
/// Invalid here means that the value is out-of-range.
static Function HW_IsValidDeviceID(variable deviceID)

#ifndef EVIL_KITTEN_EATING_MODE
	return deviceID >= 0 && deviceID < HARDWARE_MAX_DEVICES
#else
	return 1
#endif // !EVIL_KITTEN_EATING_MODE
End

/// @brief Register an opened device in our device map
///
/// @param mainDevice     Name of the DA_EPhys device
/// @param hardwareType   One of @ref HardwareDACTypeConstants
/// @param deviceID       device identifier
/// @param pressureDevice required for registering pressure control devices
Function HW_RegisterDevice(string mainDevice, variable hardwareType, variable deviceID, [string pressureDevice])

	HW_AssertOnInvalid(hardwareType, deviceID)

	WAVE/T devMap = GetDeviceMapping()

	ASSERT(!isEmpty(mainDevice), "Device name can not be empty")
	devMap[deviceID][hardwareType][%MainDevice] = mainDevice

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
Function HW_DeRegisterDevice(variable hardwareType, variable deviceID, [variable flags])

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
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function/S HW_GetMainDeviceName(variable hardwareType, variable deviceID, [variable flags])

	string mainDevice

	HW_AssertOnInvalid(hardwareType, deviceID)

	WAVE/T devMap = GetDeviceMapping()

	mainDevice = devMap[deviceID][hardwareType][%MainDevice]

	if(IsEmpty(mainDevice))
		if(!(flags & HARDWARE_PREVENT_ERROR_MESSAGE))
			printf "The main device for hardwareType %s and deviceID %d is empty!\r", StringFromList(hardwareType, HARDWARE_DAC_TYPES)
			ControlWindowToFront()
		endif

		ASSERT(!(flags & HARDWARE_ABORT_ON_ERROR), "Empty main device")

		return ""
	endif

	return mainDevice
End

/// @brief Return the name of the device given the `deviceID` and the `hardwareType`
///
/// Prefers the pressure device name if set.
///
/// @param deviceID     device identifier
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function/S HW_GetDeviceName(variable hardwareType, variable deviceID, [variable flags])

	string mainDevice, pressureDevice

	HW_AssertOnInvalid(hardwareType, deviceID)

	WAVE/T devMap = GetDeviceMapping()

	mainDevice = devMap[deviceID][hardwareType][%MainDevice]

	if(IsEmpty(mainDevice))
		if(!(flags & HARDWARE_PREVENT_ERROR_MESSAGE))
			printf "The main device for hardwareType %s and deviceID %d is empty!\r", StringFromList(hardwareType, HARDWARE_DAC_TYPES)
			ControlWindowToFront()
		endif

		ASSERT(!(flags & HARDWARE_ABORT_ON_ERROR), "Empty main device")

		return ""
	endif

	pressureDevice = devMap[deviceID][hardwareType][%PressureDevice]

	if(!IsEmpty(pressureDevice))
		return pressureDevice
	endif

	return mainDevice
End

/// @brief Generic function to retrieve the wave length of ADC channel(s).
/// For ITC this is defined through stopCollectionPoint, for other devices like
/// NI the acquisition wave had the correct size and the value can be retrieved
/// directly from that wave.
/// @param device device name
/// @param dataAcqOrTP data acquisition or tp mode @sa DataAcqModes
/// @returns effective size of ADC channel wave (for ITC the actual size is bigger)
Function HW_GetEffectiveADCWaveLength(string device, variable dataAcqOrTP)

	if(GetHardwareType(device) == HARDWARE_ITC_DAC)
		return ROVar(GetStopCollectionPoint(device))
	endif

	WAVE/WAVE dataWave = GetDAQDataWave(device, dataAcqOrTP)
	WAVE      config   = GetDAQConfigWave(device)

	return DimSize(dataWave[GetFirstADCChannelIndex(config)], ROWS)
End

Function HW_GetEffectiveDACWaveLength(string device, variable dataAcqOrTP)

	if(GetHardwareType(device) == HARDWARE_ITC_DAC)
		return ROVar(GetStopCollectionPoint(device))
	endif

	WAVE/WAVE dataWave = GetDAQDataWave(device, dataAcqOrTP)

	ASSERT(DimSize(dataWave, ROWS) > 0, "No channel in DAQ wave")

	// channel 0 is always DA
	return DimSize(dataWave[0], ROWS)
End

Function HW_GetDAFifoPosition(string device, variable dataAcqOrTP)

	variable hwType         = GetHardwareType(device)
	variable fifoPositionAD = ROVar(GetFifoPosition(device))

	switch(hwType)
		case HARDWARE_ITC_DAC: // intended drop through
		case HARDWARE_NI_DAC:
			return fifoPositionAD
		case HARDWARE_SUTTER_DAC:
			WAVE/WAVE dataWave  = GetDAQDataWave(device, dataAcqOrTP)
			WAVE      config    = GetDAQConfigWave(device)
			WAVE      channelDA = dataWave[0]
			WAVE      channelAD = dataWave[GetFirstADCChannelIndex(config)]

			return trunc(fifoPositionAD * DimDelta(channelAD, ROWS) / DimDelta(channelDA, ROWS))
			break
		default:
			ASSERT(0, "Unsupported hardware type")
	endswitch
End

/// @brief Return the minimum/maximum values for the given hardware and channel type
///
/// The type is the natural type for the hardware, volts for NI and Sutter, and 16 bit integer values for ITC.
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param channelType  One of @ref XopChannelConstants
/// @param isAssociated For Sutter hardware the voltage range differs for associated channels or unassociated ones
Function [variable minimum, variable maximum] HW_GetDataRange(variable hardwareType, variable channelType, variable isAssociated)

	switch(hardwareType)
		case HARDWARE_NI_DAC:
			switch(channelType)
				case XOP_CHANNEL_TYPE_DAC:
					return [NI_DAC_MIN, NI_DAC_MAX]
				case XOP_CHANNEL_TYPE_ADC:
					return [NI_ADC_MIN, NI_ADC_MAX]
				case XOP_CHANNEL_TYPE_TTL:
					return [NI_TTL_MIN, NI_TTL_MAX]
				default:
					ASSERT(0, "Not implemented")
			endswitch
		case HARDWARE_ITC_DAC:
			return [SIGNED_INT_16BIT_MIN, SIGNED_INT_16BIT_MAX]
		case HARDWARE_SUTTER_DAC:
			if(isAssociated)
				ASSERT(channelType != XOP_CHANNEL_TYPE_TTL, "Associated must be 0 for TTL")
				return [SU_HS_OUT_MIN, SU_HS_OUT_MAX]
			endif

			switch(channelType)
				case XOP_CHANNEL_TYPE_DAC:
					return [SU_DAC_MIN, SU_DAC_MAX]
				case XOP_CHANNEL_TYPE_ADC:
					return [SU_ADC_MIN, SU_ADC_MAX]
				case XOP_CHANNEL_TYPE_TTL:
					return [SU_TTL_MIN, SU_TTL_MAX]
				default:
					ASSERT(0, "Not implemented")
			endswitch
		default:
			ASSERT(0, "Unsupported hardware type")
	endswitch
End

///@}

/// @name ITC
///@{

/// @brief Build the device string for ITC devices
///
/// There is no corresponding function for other hardware types like NI devices
/// because those do not have a two part device name
Function/S HW_ITC_BuildDeviceString(string deviceType, string deviceNumber)

	ASSERT(!isEmpty(deviceType) && !isEmpty(deviceNumber), "empty device type or number")

	if(FindListItem(deviceType, DEVICE_TYPES_ITC) > -1)
		return deviceType + "_Dev_" + deviceNumber
	endif

	ASSERT(0, "No NI or ITC device with this name found")
End

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

		WAVE DevInfo = HW_ITC_GetDeviceInfo(i)

		type   = StringFromList(DevInfo[0], DEVICE_TYPES_ITC)
		number = StringFromList(DevInfo[1], DEVICE_NUMBERS)
		device = HW_ITC_BuildDeviceString(type, number)
		list   = AddListItem(device, list, ";", Inf)
	endfor

	KillOrMoveToTrash(wv = DevInfo)

	return list
End

///@brief Return a list of all ITC devices which can be opened
///
///**Warning! This heavily interacts with the ITC* controllers, don't call
///during data/test pulse/whatever acquisition.**
///
///@returns A list ITC devices which can be opened.
///         Does not include devices which are already open.
Function/S HW_ITC_ListDevices()

	variable i, j, deviceID, tries, numTypes, numberPerType
	string type, number, msg, device
	string list = ""

	DEBUGPRINTSTACKINFO()

#ifndef EVIL_KITTEN_EATING_MODE
#if defined(TESTS_WITH_NI_HARDWARE)
	return ""
#elif defined(TESTS_WITH_SUTTER_HARDWARE)
	return ""
#elif defined(TESTS_WITH_ITC18USB_HARDWARE)
	return HW_ITC_BuildDeviceString("ITC18USB", "0")
#elif defined(TESTS_WITH_ITC1600_HARDWARE)
	return HW_ITC_BuildDeviceString("ITC1600", "0")
#endif
#endif // !EVIL_KITTEN_EATING_MODE

	numTypes      = ItemsInList(DEVICE_TYPES_ITC)
	numberPerType = ItemsInList(DEVICE_NUMBERS)

	for(i = 0; i < numTypes; i += 1)
		type = StringFromList(i, DEVICE_TYPES_ITC)

		if(CmpStr(type, "ITC00") == 0) // don't test the virtual device
			continue
		endif

#ifdef EVIL_KITTEN_EATING_MODE
		device = HW_ITC_BuildDeviceString(type, "0")
		list   = AddListItem(device, list, ";", Inf)
		continue
#endif // EVIL_KITTEN_EATING_MODE

		tries = 0
		do
			ITCGetDevices2/Z=1/DTS=type
		while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

		if(V_Value > 0)
			for(j = 0; j < numberPerType; j += 1)
				number = StringFromList(j, DEVICE_NUMBERS)
				device = HW_ITC_BuildDeviceString(type, number)

				tries = 0
				do
					ITCOpenDevice2/Z=1/DTS=type str2num(number)
				while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

				if(V_ITCError == 0x8D101000)
					ITCGeterrorString2 V_ITCError
					printf "Missing ITC initialization due to error \"%s\".\r", S_errorMessage
					printf "Please run the ITCDemo applications once for 32bit and 64bit (ITCDemoG32.exe and ITCDemoG64.exe) as administrator to create the required registry keys.\r"
					printf "And then run regedit.exe as administrator and allow READ/WRITE (better known as FULL) access to \"HKEY_LOCAL_MACHINE\SOFTWARE\Instrutech\" and \"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Instrutech\" for all users.\r"
					ControlWindowToFront()
					return ""
				endif

				deviceID = V_Value
				if(V_ITCError == 0 && V_ITCXOPError == 0 && deviceID >= 0)
					sprintf msg, "Found device type %s with number %s", type, number
					DEBUGPRINT(msg)

					tries = 0
					do
						ITCCloseDevice2/Z=1/DEV=(deviceID)
					while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

					list = AddListItem(device, list, ";", Inf)
				endif
			endfor
		endif
	endfor

	return list
End

/// @brief Output an informative error message for the ITC XOP2 operations
///
/// @return 0 on success, 1 otherwise
threadsafe Function HW_ITC_HandleReturnValues(variable flags, variable ITCError, variable ITCXOPError)

	string msg

	variable outputErrorMessage, tries

	if(ITCError == 0 && ITCXOPError == 0)
		// no errors
		return 0
	endif

	// we only need the lower 32bits of the error
	ITCError           = ITCError & 0x00000000ffffffff
	ITCXOPError        = ConvertXOPErrorCode(ITCXOPError)
	outputErrorMessage = !(flags & HARDWARE_PREVENT_ERROR_MESSAGE)

	if(ITCError != 0 && outputErrorMessage)
		printf "The ITC XOP returned the following errors: ITCError=%#x, ITCXOPError=%d\r", ITCError, ITCXOPError

		do
			ITCGetErrorString2/X itcError
		while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

		print S_errorMEssage
		print "Some hints you might want to try!"
		print "- Is the correct ITC device type selected?"
		print "- Is your ITC Device connected to a power socket?"
		print "- Is your ITC Device connected to your computer?"
		print "- Have you tried unlocking/locking the device already?"
		print "- Reseating all connections between the DAC and the computer has also helped in the past."
		printf "Responsible function: %s\r", GetRTStackInfo(2)
		printf "Complete call stack: %s\r", GetRTStackInfo(3)

		BUG_TS("The ITC XOP returned an error!", keys = {"ITCError", "ITCErrorMessage"}, values = {num2str(itcError, "%#x"), S_errorMessage})
	elseif(ITCXOPError != 0 && outputErrorMessage)
		msg = HW_ITC_GetXOPErrorMessage(ITCXOPError)
		printf "The ITC XOP returned the following errors: ITCError=%#x, ITCXOPError=%d\r", ITCError, ITCXOPError
		printf "XOP error message: %s\r", msg
		printf "Responsible function: %s\r", GetRTStackInfo(2)
		printf "Complete call stack: %s\r", GetRTStackInfo(3)
		BUG_TS("The ITC XOP was called incorrectly!", keys = {"ITCXOPError", "ITCXOPErrorMessage"}, values = {num2str(itcXOPError), msg})
	endif

#ifndef EVIL_KITTEN_EATING_MODE
	ASSERT_TS(!(flags & HARDWARE_ABORT_ON_ERROR), "DAC error")

	return 1
#else
	ClearRTError()
	return 0
#endif // !EVIL_KITTEN_EATING_MODE
End

/// @brief Return the error message for the given ITC XOP2 error code
///
/// @param errCode one of @ref ITCXOP2Errors
threadsafe static Function/S HW_ITC_GetXOPErrorMessage(variable errCode)

	if(errCode < FIRST_XOP_ERROR)
		return GetErrMessage(errCode)
	endif

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
Function HW_ITC_OpenDevice(variable deviceType, variable deviceNumber, [variable flags])

	variable deviceID, tries, i

	DEBUGPRINTSTACKINFO()

#ifdef AUTOMATED_TESTING
	for(i = 0; i < HARDWARE_MAX_DEVICES; i += 1)
		if(!HW_ITC_SelectDevice(i, flags = HARDWARE_PREVENT_ERROR_MESSAGE))

			WAVE DevInfo = HW_ITC_GetDeviceInfo(i)

			if(DevInfo[0] == deviceType)
				return i
			endif
		endif
	endfor
#endif // AUTOMATED_TESTING

	do
		ITCOpenDevice2/DTN=(deviceType)/Z=1 deviceNumber
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
	deviceID = V_Value

	return deviceID
End

/// @brief Close all ITC devices
Function HW_ITC_CloseAllDevices([variable flags])

	variable i

	DEBUGPRINTSTACKINFO()

	for(i = 0; i < HARDWARE_MAX_DEVICES; i += 1)
		if(HW_SelectDevice(HARDWARE_ITC_DAC, i, flags = HARDWARE_PREVENT_ERROR_MESSAGE))
			continue // can not select device
		endif

		HW_ITC_StopAcq(i)
	endfor

	ITCCloseAll2/Z=1
End

/// @see HW_CloseDevice
Function HW_ITC_CloseDevice(variable deviceID, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

#ifdef AUTOMATED_TESTING
	return NaN
#endif // AUTOMATED_TESTING

	if(HW_ITC_SelectDevice(deviceID, flags = HARDWARE_PREVENT_ERROR_MESSAGE))
		do
			ITCCloseDevice2/DEV=(deviceID)/Z=1
		while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

		return NaN
	endif

	HW_ITC_StopAcq(deviceID)

	do
		ITCCloseDevice2/DEV=(deviceID)/Z=1
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_SelectDevice
Function HW_ITC_SelectDevice(variable deviceID, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCSelectDevice2/Z=1 deviceID
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	return HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_GetDeviceInfo
Function/WAVE HW_ITC_GetDeviceInfo(variable deviceID, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCGetDeviceInfo2/Z=1/DEV=(deviceID)/FREE DevInfo
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	return DevInfo
End

/// @see HW_EnableYoking
Function HW_ITC_EnableYoking(variable deviceID, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCInitialize2/DEV=(deviceID)/M=1/Z=1
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_DisableYoking
Function HW_ITC_DisableYoking(variable deviceID, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCInitialize2/DEV=(deviceID)/M=0/Z=1
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_StopAcq (threadsafe variant)
threadsafe Function HW_ITC_StopAcq_TS(variable deviceID, [variable prepareForDAQ, variable flags])

	variable tries

	do
		ITCStopAcq2/DEV=(deviceID)/Z=1
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	if(prepareForDAQ)
		do
			ITCConfigChannelUpload2/DEV=(deviceID)/Z=1
		while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

		HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
	endif
End

/// @param deviceID      device identifier
/// @param config        [optional] ITC config wave
/// @param configFunc    [optional, defaults to GetDAQConfigWave()] override wave getter for the ITC config wave
/// @param prepareForDAQ [optional, defaults to false] prepare for next DAQ immediately
/// @param zeroDAC       [optional, defaults to false] set all DA channels to zero
/// @param flags         [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @see HW_StopAcq
Function HW_ITC_StopAcq(variable deviceID, [WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable prepareForDAQ, variable zeroDAC, variable flags])

	variable i, numEntries, tries
	string device

	DEBUGPRINTSTACKINFO()

	do
		ITCStopAcq2/DEV=(deviceID)/Z=1
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	if(zeroDAC)
		device = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID, flags = flags)

		if(ParamIsDefault(config))
			if(ParamIsDefault(configFunc))
				WAVE config = GetDAQConfigWave(device)
			else
				WAVE config = configFunc(device)
			endif
		endif

		WAVE DACs = GetDACListFromConfig(config)

		numEntries = DimSize(DACs, ROWS)
		for(i = 0; i < numEntries; i += 1)
			HW_ITC_WriteDAC(deviceID, DACs[i], 0, flags = flags)
		endfor
	endif

	if(prepareForDAQ)
		do
			ITCConfigChannelUpload2/DEV=(deviceID)/Z=1
		while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

		HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
	endif
End

/// @brief Return the deviceID of the currently selected
///        ITC device from the XOP
Function HW_ITC_GetCurrentDevice([variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCGetCurrentDevice2/Z=1
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	return V_Value
End

/// @brief Create a fifo position wave from a DAQConfigWave
threadsafe static Function/WAVE HW_ITC_GetFifoPosFromConfig(WAVE config_t)

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
threadsafe Function HW_ITC_ResetFifo_TS(variable deviceID, WAVE config, [variable flags])

	variable tries

	WAVE config_t  = HW_ITC_Transpose(config)
	WAVE fifoPos_t = HW_ITC_GetFifoPosFromConfig(config_t)

	do
		ITCUpdateFIFOPositionAll2/DEV=(deviceID)/Z=1 fifoPos_t
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @brief Reset the AD/DA channel FIFOs
///
/// @param deviceID device identifier
/// @param[in] config                  [optional] ITC config wave
/// @param configFunc    [optional, defaults to GetITCChanConfigWave()] override wave getter for the ITC config wave
/// @param     flags                   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_ResetFifo(variable deviceID, [WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable flags])

	variable tries
	string   device

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID, flags = flags)

	if(ParamIsDefault(config))
		if(ParamIsDefault(configFunc))
			WAVE config = GetDAQConfigWave(device)
		else
			WAVE config = configFunc(device)
		endif
	endif

	WAVE config_t  = HW_ITC_Transpose(config)
	WAVE fifoPos_t = HW_ITC_GetFifoPosFromConfig(config_t)

	do
		ITCUpdateFIFOPositionAll2/DEV=(deviceID)/Z=1 fifoPos_t
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_StartAcq (threadsafe variant)
threadsafe Function HW_ITC_StartAcq_TS(variable deviceID, variable triggerMode, [variable flags])

	variable tries

	switch(triggerMode)
		case HARDWARE_DAC_EXTERNAL_TRIGGER:
			do
				ITCStartAcq2/DEV=(deviceID)/EXT=256/Z=1
			while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

			break
		case HARDWARE_DAC_DEFAULT_TRIGGER:
			do
				ITCStartAcq2/DEV=(deviceID)/Z=1
			while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

			break
		default:
			ASSERT_TS(0, "Unknown trigger mode")
			break
	endswitch

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_StartAcq
Function HW_ITC_StartAcq(variable deviceID, variable triggerMode, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	switch(triggerMode)
		case HARDWARE_DAC_EXTERNAL_TRIGGER:
			do
				ITCStartAcq2/DEV=(deviceID)/EXT=256/Z=1
			while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

			break
		case HARDWARE_DAC_DEFAULT_TRIGGER:
			do
				ITCStartAcq2/DEV=(deviceID)/Z=1
			while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

			break
		default:
			ASSERT(0, "Unknown trigger mode")
			break
	endswitch

	if(V_ITCError == 0x80421000 && GetASLREnabledState())
		printf "DAQ with ITC hardware is broken as the installation is not complete.\r"
		printf "Please call \"Mies Panels->Advanced->Turn off ASLR (requires UAC elevation)\" or\r"
		printf "follow the steps at https://github.com/AllenInstitute/ITCXOP2#windows-10.\r"
		printf "In both cases Igor Pro needs to be restarted.\r"
		Abort
	endif

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @brief Check wether DAQ is still ongoing
///
/// @param deviceID device identifier
/// @param flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_IsRunning(variable deviceID, [variable flags])

	DEBUGPRINTSTACKINFO()

	WAVE/Z state = HW_ITC_GetState(deviceID, flags = flags)

	if(!WaveExists(state))
		return 0
	endif

	return (state[0] & HW_ITC_RUNNING_STATE) == HW_ITC_RUNNING_STATE
End

/// @brief Query the ITC device state
///
/// @param deviceID device identifier
/// @param flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function/WAVE HW_ITC_GetState(variable deviceID, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCGetState2/DEV=(deviceID)/ALL/FREE/Z=1 state
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	return state
End

threadsafe static Function HW_ITC_ShouldContinue(variable tries, variable itcError, variable itcXOPError)

	return (itcXOPError == SLOT_LOCKED_TO_OTHER_THREAD && itcError == 0)                       \
	       || (itcXOPError == 0 && itcError == HW_ITC_DSP_TIMEOUT && tries < HW_ITC_MAX_TIMEOUT)
End

/// @see HW_ReadADC
Function HW_ITC_ReadADC(variable deviceID, variable channel, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCReadADC2/DEV=(deviceID)/C=1/V=1/Z=1 channel
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	return V_Value
End

/// @see HW_WriteDAC
Function HW_ITC_WriteDAC(variable deviceID, variable channel, variable value, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCSetDAC2/DEV=(deviceID)/C=1/V=1/Z=1 channel, value
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @see HW_ReadDigital
Function HW_ITC_ReadDigital(variable deviceID, variable xopChannel, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCReadDigital2/DEV=(deviceID)/Z=1 xopChannel
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	return V_Value
End

/// @see HW_WriteDigital
Function HW_ITC_WriteDigital(variable deviceID, variable xopChannel, variable value, [variable flags])

	variable tries

	DEBUGPRINTSTACKINFO()

	do
		ITCWriteDigital2/DEV=(deviceID)/Z=1 xopChannel, value
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)
End

/// @brief Set the debug flag of the ITC XOP to ON/OFF (threadsafe variant)
threadsafe Function HW_ITC_DebugMode_TS(variable state, [variable flags])

	ITCSetGlobals2/D=(state)/Z=1
End

/// @brief Set the debug flag of the ITC XOP to ON/OFF
Function HW_ITC_DebugMode(variable state, [variable flags])

	DEBUGPRINTSTACKINFO()

	ITCSetGlobals2/D=(state)/Z=1
End

/// @brief Prepare for data acquisition
///
/// @param deviceID    device identifier
/// @param data        ITC data wave
/// @param dataFunc    [optional, defaults to GetDAQDataWave()] override wave getter for the ITC data wave
/// @param mode        one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param config      ITC config wave
/// @param configFunc  [optional, defaults to GetDAQConfigWave()] override wave getter for the ITC config wave
/// @param offset      [optional, defaults to zero] offset into the data wave in points
/// @param flags       [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_PrepareAcq(variable deviceID, variable mode, [WAVE/Z data, FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable flags, variable offset])

	string   device
	variable tries

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID, flags = flags)

	if(ParamIsDefault(data))
		if(ParamIsDefault(dataFunc))
			WAVE data = GetDAQDataWave(device, mode)
		else
			WAVE data = dataFunc(device)
		endif
	endif

	if(ParamIsDefault(config))
		if(ParamIsDefault(configFunc))
			WAVE config = GetDAQConfigWave(device)
		else
			WAVE config = configFunc(device)
		endif
	endif

	if(!ParamIsDefault(offset))
		config[][%Offset] = offset
	endif

	WAVE config_t = HW_ITC_Transpose(config)

	do
		ITCconfigAllchannels2/DEV=(deviceID)/Z=1 config_t, data
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		do
			ITCGetAllChannelsConfig2/DEV=(deviceID)/O/Z=1 config_t, settings
		while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

		HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

		printf "xop: %d with alignment %d\r", settings[%FIFOPointer][0], GetAlignment(settings[%FIFOPointer][0])
		printf "xop: %d with alignment %d\r", settings[%FIFOPointer][1], GetAlignment(settings[%FIFOPointer][1])
		printf "diff = %d\r", settings[%FIFOPointer][1] - settings[%FIFOPointer][0]
		printf "numRows = %d\r", DimSize(data, ROWS)
	endif
#endif // DEBUGGING_ENABLED

	WAVE fifoPos_t = HW_ITC_GetFifoPosFromConfig(config_t)

	do
		ITCUpdateFIFOPositionAll2/DEV=(deviceID)/Z=1 fifoPos_t
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

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
/// @return 1 if more data needs to be acquired, 0 if done. On hardware error we also return 1.
threadsafe Function HW_ITC_MoreData_TS(variable deviceID, variable ADChannelToMonitor, variable stopCollectionPoint, WAVE config, [variable &fifoPos, variable flags])

	variable fifoPosValue, offset, ret, tries

	offset = GetDataOffset(config)

	WAVE config_t = HW_ITC_Transpose(config)

	do
		ITCFIFOAvailableALL2/DEV=(deviceID)/FREE/Z=1 config_t, fifoAvail_t
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	ret = HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	if(ret)
		fifoPosValue = HARDWARE_ITC_FIFO_ERROR
	else
		fifoPosValue = fifoAvail_t[2][ADChannelToMonitor]
	endif

	if(!ParamIsDefault(fifoPos))
		fifoPos = fifoPosValue
	endif

	if(ret)
		return 1
	endif

	return (offset + fifoPosValue) < stopCollectionPoint
End

/// @brief Check wether more data can be acquired
///
/// @param[in] deviceID            device identifier
/// @param[in] ADChannelToMonitor  [optional, defaults to GetADChannelToMonitor()] first AD channel
/// @param[in] stopCollectionPoint [optional, defaults to GetStopCollectionPoint()] number of points to acquire
/// @param[in] config              [optional] ITC config wave
/// @param[in] configFunc          [optional, defaults to GetDAQConfigWave()] override wave getter for the ITC config wave
/// @param[out] fifoPos            [optional] allows to query the current fifo position (ADC)
/// @param flags                   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return 1 if more data needs to be acquired, 0 if done. On hardware error we also return 1.
Function HW_ITC_MoreData(variable deviceID, [variable ADChannelToMonitor, variable stopCollectionPoint, WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable &fifoPos, variable flags])

	variable fifoPosValue, offset, ret, tries
	string device

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID, flags = flags)

	if(ParamIsDefault(ADChannelToMonitor))
		NVAR ADChannelToMonitor_NVAR = $GetADChannelToMonitor(device)
		ADChannelToMonitor = ADChannelToMonitor_NVAR
	endif

	if(ParamIsDefault(stopCollectionPoint))
		NVAR stopCollectionPoint_NVAR = $GetStopCollectionPoint(device)
		stopCollectionPoint = stopCollectionPoint_NVAR
	endif

	if(ParamIsDefault(config))
		if(ParamIsDefault(configFunc))
			WAVE config = GetDAQConfigWave(device)
		else
			WAVE config = configFunc(device)
		endif
	endif

	offset = GetDataOffset(config)

	WAVE config_t = HW_ITC_Transpose(config)

	do
		ITCFIFOAvailableALL2/DEV=(deviceID)/FREE/Z=1 config_t, fifoAvail_t
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	ret = HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	if(ret)
		fifoPosValue = HARDWARE_ITC_FIFO_ERROR
	else
		fifoPosValue = fifoAvail_t[2][ADChannelToMonitor]
	endif

	if(!ParamIsDefault(fifoPos))
		fifoPos = fifoPosValue
	endif

	if(ret)
		return 1
	endif

	return (offset + fifoPosValue) < stopCollectionPoint
End

Function/WAVE HW_ITC_GetVersionInfo([variable flags])

	variable ret, tries

	do
		ITCGetVersions2/FREE/Z=1 versionInfo
	while(HW_ITC_ShouldContinue(tries++, V_ITCError, V_ITCXOPError))

	ret = HW_ITC_HandleReturnValues(flags, V_ITCError, V_ITCXOPError)

	if(ret)
		return $""
	endif

	return versionInfo
End

Function HW_ITC_SetLoggingTemplate(string template, [variable flags])

	// can't set /Z here as that is enabling/disabling it globally
	ITCSetGlobals2/LTS=template
End

#else

Function/S HW_ITC_ListOfOpenDevices()

	DEBUGPRINT("Unimplemented")
End

Function/S HW_ITC_ListDevices()

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_HandleReturnValues(variable flags, variable ITCError, variable ITCXOPError)

	DEBUGPRINT("Unimplemented")
End

threadsafe static Function/S HW_ITC_GetXOPErrorMessage(variable errCode)

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_OpenDevice(variable deviceType, variable deviceNumber, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_CloseAllDevices([variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_CloseDevice(variable deviceID, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_SelectDevice(variable deviceID, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function/WAVE HW_ITC_GetDeviceInfo(variable deviceID, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_EnableYoking(variable deviceID, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_DisableYoking(variable deviceID, [variable flags])

	DEBUGPRINT("Unimplemented")
End

threadsafe Function HW_ITC_StopAcq_TS(variable deviceID, [variable prepareForDAQ, variable flags])

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_StopAcq(variable deviceID, [WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable prepareForDAQ, variable zeroDAC, variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_GetCurrentDevice([variable flags])

	DEBUGPRINT("Unimplemented")
End

threadsafe static Function/WAVE HW_ITC_GetFifoPosFromConfig(WAVE config_t)

	DEBUGPRINT_TS("Unimplemented")
End

threadsafe Function HW_ITC_ResetFifo_TS(variable deviceID, WAVE config, [variable flags])

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_ResetFifo(variable deviceID, [WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable flags])

	DEBUGPRINT("Unimplemented")
End

threadsafe Function HW_ITC_StartAcq_TS(variable deviceID, variable triggerMode, [variable flags])

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_StartAcq(variable deviceID, variable triggerMode, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_IsRunning(variable deviceID, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function/WAVE HW_ITC_GetState(variable deviceID, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_ReadADC(variable deviceID, variable channel, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_WriteDAC(variable deviceID, variable channel, variable value, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_ReadDigital(variable deviceID, variable xopChannel, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_WriteDigital(variable deviceID, variable xopChannel, variable value, [variable flags])

	DEBUGPRINT("Unimplemented")
End

threadsafe Function HW_ITC_DebugMode_TS(variable state, [variable flags])

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_DebugMode(variable state, [variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_PrepareAcq(variable deviceID, variable mode, [WAVE/Z data, FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable flags, variable offset])

	DEBUGPRINT("Unimplemented")
End

threadsafe Function HW_ITC_MoreData_TS(variable deviceID, variable ADChannelToMonitor, variable stopCollectionPoint, WAVE config, [variable &fifoPos, variable flags])

	DEBUGPRINT_TS("Unimplemented")
End

Function HW_ITC_MoreData(variable deviceID, [variable ADChannelToMonitor, variable stopCollectionPoint, WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable &fifoPos, variable flags])

	DEBUGPRINT("Unimplemented")
End

Function/WAVE HW_ITC_GetVersionInfo([variable flags])

	DEBUGPRINT("Unimplemented")
End

Function HW_ITC_SetLoggingTemplate(string template, [variable flags])

	DEBUGPRINT("Unimplemented")
End

#endif // ITC_XOP_PRESENT

Function/WAVE HW_WAVE_GETTER_PROTOTYPE(string str)

End

threadsafe Function/WAVE HW_ITC_Transpose(WAVE wv)

	MatrixOp/FREE wv_t = wv^t

	return wv_t
End

Function/WAVE HW_ITC_TransposeAndToInt(WAVE wv)

	MatrixOp/FREE wv_t = int32(wv^t)

	return wv_t
End

/// @name Utility functions not interacting with hardware
///@{

/// @brief Returns the device channel offset for the given device
///
/// @returns 16 for ITC1600 and 0 for all other types
Function HW_ITC_CalculateDevChannelOff(string device)

	if(IsITC1600(device))
		return 16
	endif

	return 0
End

/// @brief Return the `first` and `last` TTL bits/channels for the given `rack`
threadsafe Function HW_ITC_GetRackRange(variable rack, variable &first, variable &last)

	if(rack == RACK_ZERO)
		first = 0
		last  = NUM_ITC_TTL_BITS_PER_RACK - 1
	elseif(rack == RACK_ONE)
		first = NUM_ITC_TTL_BITS_PER_RACK
		last  = 2 * NUM_ITC_TTL_BITS_PER_RACK - 1
	else
		ASSERT_TS(0, "Invalid rack parameter")
	endif

	ASSERT_TS((last - first + 1) == NUM_ITC_TTL_BITS_PER_RACK, "Rack channel range must be NUM_ITC_TTL_BITS_PER_RACK for each rack")
End

/// @brief Clip the ttlBit to adapt for differences in notation
///
/// The DA_Ephys panel e.g. labels the first ttlBit of #RACK_ONE as 4, but the
/// ITC XOP treats that as 0.
Function HW_ITC_ClipTTLBit(string device, variable ttlBit)

	if(HW_ITC_GetRackForTTLBit(device, ttlBit) == RACK_ONE)
		return ttlBit - NUM_ITC_TTL_BITS_PER_RACK
	else
		return ttlBit
	endif
End

/// @brief Return the rack number for the given ttlBit (the ttlBit is
/// called `TTL channel` in the DA Ephys panel)
Function HW_ITC_GetRackForTTLBit(string device, variable ttlBit)

	ASSERT(ttlBit < NUM_DA_TTL_CHANNELS, "Invalid channel index")

	if(ttlBit >= NUM_ITC_TTL_BITS_PER_RACK)
		ASSERT(IsITC1600(device), "Only the ITC1600 has multiple racks")
		return RACK_ONE
	else
		return RACK_ZERO
	endif
End

/// @brief Return the ITC XOP channel for the given rack
///
/// Only the ITC1600 has two racks. The channel numbers differ for the
/// different ITC device types.
Function HW_ITC_GetITCXOPChannelForRack(string device, variable rack)

	if(rack == RACK_ZERO)
		if(IsITC1600(device))
			return HARDWARE_ITC_TTL_1600_RACK_ZERO
		else
			return HARDWARE_ITC_TTL_DEF_RACK_ZERO
		endif
	elseif(rack == RACK_ONE)
		ASSERT(IsITC1600(device), "Only the ITC1600 has multiple racks")
		return HARDWARE_ITC_TTL_1600_RACK_ONE
	else
		ASSERT(0, "Unknown rack")
	endif
End

/// @brief Get the number of racks for the given device
///
/// - ITC1600 can have 1 or 2 racks
/// - other device types have 1
Function HW_ITC_GetNumberOfRacks(string device)

	WAVE deviceInfo = GetDeviceInfoWave(device)

	return deviceInfo[%Rack]
End

/// @brief Assert on using an invalid ITC device name
///
/// @param deviceName ITC device name
Function HW_ITC_AssertOnInvalid(string deviceName)

	ASSERT(HW_ITC_IsValidDeviceName(deviceName), "Invalid ITC device name")
End

/// @brief Check wether the given ITC device name is valid
///
/// Currently a device name is valid if it is not empty.
Function HW_ITC_IsValidDeviceName(string deviceName)

	return !isEmpty(deviceName)
End

///@}
///@}

/// @name NI
///@{

/// @brief Assert on using an invalid NI device name
///
/// @param deviceName NI device name
Function HW_NI_AssertOnInvalid(string deviceName)

	ASSERT(HW_NI_IsValidDeviceName(deviceName), "Invalid NI device name")
End

/// @brief Check wether the given NI device name is valid
///
/// Currently a device name is valid if it is not empty.
Function HW_NI_IsValidDeviceName(string deviceName)

	return !isEmpty(deviceName)
End

/// @brief Return the analog input configuration bits as string
///
/// @param config Bit combination of @ref NIAnalogInputConfigs
Function/S HW_NI_AnalogInputToString(variable config)

	string str = ""

	if(config & HW_NI_CONFIG_RSE)
		str += "RSE, "
	endif

	if(config & HW_NI_CONFIG_NRSE)
		str += "NRSE, "
	endif

	if(config & HW_NI_CONFIG_DIFFERENTIAL)
		str += "Differential, "
	endif

	if(config & HW_NI_CONFIG_PSEUDO_DIFFERENTIAL)
		str += "Pseudo Differential, "
	endif

	ASSERT(!IsEmpty(str), "Invalid config")

	return RemoveEnding(str, ", ")
End

#ifdef NIDAQMX_XOP_PRESENT

/// @name Minimum voltages for the analog inputs/outputs
/// We always use the maximum range so that we have a constant resolution on the DAC
///@{
static Constant HW_NI_MIN_VOLTAGE = -10.0
static Constant HW_NI_MAX_VOLTAGE = +10.0
///@}

static Constant HW_NI_DIFFERENTIAL_SETUP = 0

static Constant HW_NI_FIFOSIZE = 120

// HW_NI_FIFO_MIN_FREE_DISC_SPACE = SAFETY * HW_NI_FIFOSIZE * sizeof(double) * NI_MAX_SAMPLE_RATE
// HW_NI_FIFO_MIN_FREE_DISC_SPACE = 2      * 120            *              8 * 500000
static Constant HW_NI_FIFO_MIN_FREE_DISK_SPACE = 960000000

/// @name Functions for interfacing with National Instruments Hardware
///

/// @see HW_StartAcq
Function HW_NI_StartAcq(variable deviceID, variable triggerMode, [variable flags, variable repeat])

	string device, realDeviceOrPressure, FIFONote, noteID, fifoName, errMsg
	variable i, pos, endpos, channelTimeOffset, err

	DEBUGPRINTSTACKINFO()

	if(ParamIsDefault(repeat))
		repeat = 0
	endif

	device               = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
	realDeviceOrPressure = HW_GetDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
	SVAR scanStr = $GetNI_AISetup(device)
	fifoName = GetNIFIFOName(deviceID)
	AssertOnAndClearRTError()
	try
		if(!HasEnoughDiskspaceFree(SpecialDirPath("Temporary", 0, 0, 0), HW_NI_FIFO_MIN_FREE_DISK_SPACE))
			printf "%s: Can not start acquisition. Not enough free disk space for data buffer.\rThe free disk space is less than %.0W0PB.\r", device, HW_NI_FIFO_MIN_FREE_DISK_SPACE
			ControlWindowToFront()
			return NaN
		endif
		CtrlFIFO $fifoName, start
		if(repeat)
			DAQmx_Scan/DEV=realDeviceOrPressure/BKG/RPTC FIFO=scanStr; AbortOnRTE
		else
			DAQmx_Scan/DEV=realDeviceOrPressure/BKG FIFO=scanStr; AbortOnRTE
		endif
		NVAR taskIDADC = $GetNI_ADCTaskID(device)
		taskIDADC = 1

		// The following code just gathers additional information that is printed out
		FIFOStatus/Q $fifoName
		FIFONote = StringByKey("NOTE", S_Info)
		noteID   = "Channel dt="
		pos      = strsearch(FIFONote, noteID, 0)
		if(pos > -1)
			pos              += strlen(noteID)
			endpos            = strsearch(FIFONote, "\r", pos)
			channelTimeOffset = str2num(FIFONote[pos, endpos - 1])
			DEBUGPRINT("Time offset between NI channels: " + num2str(channelTimeOffset * ONE_TO_MICRO) + " µs")
		endif
	catch
		errMsg = GetRTErrMessage() + "\r" + fDAQmx_ErrorString()
		err    = ClearRTError()
		HW_NI_StopAcq(deviceID)
		HW_NI_KillFifo(deviceID)
		ASSERT(0, "Start acquisition of NI device " + device + " failed with code: " + num2str(err) + "\r" + errMsg)
	endtry
End

/// @brief Prepare for data acquisition
///
/// @param deviceID    device identifier
/// @param mode        one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param data        ITC data wave
/// @param dataFunc    [optional, defaults to GetDAQDataWave()] override wave getter for the ITC data wave
/// @param config      ITC config wave
/// @param configFunc  [optional, defaults to GetDAQConfigWave()] override wave getter for the ITC config wave
/// @param offset      [optional, defaults to zero] offset into the data wave in points
/// @param flags       [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_PrepareAcq(variable deviceID, variable mode, [WAVE/Z data, FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable flags, variable offset])

	string device, tempStr, realDeviceOrPressure, filename, clkStr, wavegenStr, TTLStr, fifoName, errMsg
	variable i, aiCnt, ttlCnt, channels, sampleIntervall, numEntries, fifoSize, err, minimum, maximum

	DEBUGPRINTSTACKINFO()

	device               = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
	realDeviceOrPressure = HW_GetDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)

	if(ParamIsDefault(data))
		if(ParamIsDefault(dataFunc))
			WAVE/WAVE NIDataWave = GetDAQDataWave(device, mode)
		else
			WAVE/WAVE NIDataWave = dataFunc(device)
		endif
	endif

	if(ParamIsDefault(config))
		if(ParamIsDefault(configFunc))
			WAVE config = GetDAQConfigWave(device)
		else
			WAVE config = configFunc(device)
		endif
	endif

	if(!ParamIsDefault(offset))
		ASSERT(0, "Offset is not supported")
	endif

	WAVE gain = SWS_GetChannelGains(device, timing = GAIN_BEFORE_DAQ)

	fifoName = GetNIFIFOName(deviceID)
	channels = DimSize(config, ROWS)
	SVAR scanStr = $GetNI_AISetup(device)
	scanStr    = fifoName + ";"
	wavegenStr = ""
	TTLStr     = ""
	Make/FREE/WAVE/N=(channels) TTLWaves

	AssertOnAndClearRTError()
	try
		NewFIFO $fifoName; AbortOnRTE
		aiCnt  = 0
		ttlCnt = 0
		for(i = 0; i < channels; i += 1)
			ASSERT(!IsFreeWave(NIDataWave[i]), "Can not work with free waves")
			switch(config[i][%ChannelType])
				case XOP_CHANNEL_TYPE_ADC:
					scanStr += num2str(config[i][%ChannelNumber]) + "/RSE,"
					scanStr += num2str(NI_ADC_MIN) + "," + num2str(NI_ADC_MAX) + ","
					scanStr += num2str(gain[i]) + ",0"
					scanStr += ";"
					// note: the second parameter encodes the attributed NIDataWave index into the FIFO channel name
					NewFIFOChan $fifoName, $num2str(i), 0, 1, NI_ADC_MIN, NI_ADC_MAX, "V"
					aiCnt += 1
					break
				case XOP_CHANNEL_TYPE_DAC:
					WAVE NIChannel = NIDataWave[i]
					wavegenStr        += GetWavesDataFolder(NIChannel, 2) + ","
					wavegenStr        += num2str(config[i][%ChannelNumber]) + ","
					[minimum, maximum] = WaveMinAndMax(NIChannel)
					sprintf tempStr, "%10f", max(-10, minimum - 0.001)
					wavegenStr += tempStr + ","
					sprintf tempStr, "%10f", min(10, maximum + 0.001)
					wavegenStr += tempStr + ";"
					break
				case XOP_CHANNEL_TYPE_TTL:
					TTLStr          += "/" + realDeviceOrPressure + "/port" + num2str(HARDWARE_NI_TTL_PORT) + "/line" + num2str(config[i][%ChannelNumber]) + ","
					TTLWaves[ttlCnt] = NIDataWave[i]
					ttlCnt          += 1
					break
				default:
					ASSERT(0, "Unsupported channel type")
					break
			endswitch
		endfor

		sampleIntervall = config[0][%SamplingInterval] * MICRO_TO_ONE
		fifoSize        = HW_NI_FIFOSIZE / sampleIntervall
		NVAR fifopos = $GetFifoPosition(device)
		fifopos = 0
		NVAR fnum = $GetFIFOFileRef(device)
		NewPath/O/Q tempNIAcqPath, SpecialDirPath("Temporary", 0, 0, 0)
		filename = "MIES_FIFO_" + device + ".DAT"
		Open/P=tempNIAcqPath fnum as filename
		KillPath tempNIAcqPath
		CtrlFIFO $fifoName, deltaT=sampleIntervall, size=fifoSize, file=fnum, note="MIES Analog In File"

		clkStr = "/" + realDeviceOrPressure + "/ai/sampleclock"
		// note actually this does already 'starts' a measurement
#ifdef EVIL_KITTEN_EATING_MODE
		// don't set any clock source to make the USB6001 work with DAQ
		DAQmx_WaveFormGen/DEV=realDeviceOrPressure/STRT=1 wavegenStr; AbortOnRTE
#else
		DAQmx_WaveFormGen/DEV=realDeviceOrPressure/STRT=1/CLK={clkStr, 0} wavegenStr; AbortOnRTE
#endif // EVIL_KITTEN_EATING_MODE
		NVAR taskIDDAC = $GetNI_DACTaskID(device)
		taskIDDAC = 1

		switch(ttlCnt)
			case 0:
				break
			case 1:
				DAQmx_DIO_Config/DEV=realDeviceOrPressure/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0]} TTLStr; AbortOnRTE
				break
			case 2:
				DAQmx_DIO_Config/DEV=realDeviceOrPressure/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1]} TTLStr; AbortOnRTE
				break
			case 3:
				DAQmx_DIO_Config/DEV=realDeviceOrPressure/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2]} TTLStr; AbortOnRTE
				break
			case 4:
				DAQmx_DIO_Config/DEV=realDeviceOrPressure/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3]} TTLStr; AbortOnRTE
				break
			case 5:
				DAQmx_DIO_Config/DEV=realDeviceOrPressure/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3], TTLWaves[4]} TTLStr; AbortOnRTE
				break
			case 6:
				DAQmx_DIO_Config/DEV=realDeviceOrPressure/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3], TTLWaves[4], TTLWaves[5]} TTLStr; AbortOnRTE
				break
			case 7:
				DAQmx_DIO_Config/DEV=realDeviceOrPressure/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3], TTLWaves[4], TTLWaves[5], TTLWaves[6]} TTLStr; AbortOnRTE
				break
			case 8:
				DAQmx_DIO_Config/DEV=realDeviceOrPressure/LGRP=1/CLK={clkStr, 0}/RPTC/DIR=1/WAVE={TTLWaves[0], TTLWaves[1], TTLWaves[2], TTLWaves[3], TTLWaves[4], TTLWaves[5], TTLWaves[6], TTLWaves[7]} TTLStr; AbortOnRTE
				break
			default:
				ASSERT(0, "Unsupported TTL count")
				break
		endswitch
		NVAR taskIDTTL = $GetNI_TTLTaskID(device)
		taskIDTTL = ttlCnt ? V_DAQmx_DIO_TaskNumber : NaN

	catch
		errMsg = GetRTErrMessage() + "\r" + fDAQmx_ErrorString()
		err    = ClearRTError()
		HW_NI_StopAcq(deviceID)
		HW_NI_KillFifo(deviceID)
		ASSERT(0, "Prepare acquisition of NI device " + device + " failed with code: " + num2str(err) + "\r" + errMsg)
	endtry
End

/// @brief returns properties of NI device
///
/// @param device name of NI device
///
/// @return keyword list of device properties, empty if device not present
Function/S HW_NI_GetPropertyListOfDevices(string device)

	variable numAI, numAO, numCounter, numDIO
	string lines = ""
	string propList
	variable i, portWidth

	DEBUGPRINTSTACKINFO()

	numAI      = fDAQmx_NumAnalogInputs(device)
	numAO      = fDAQmx_NumAnalogOutputs(device)
	numCounter = fDAQmx_NumCounters(device)
	numDIO     = fDAQmx_NumDIOPorts(device)
	for(i = 0; i < numDIO; i += 1)
		portWidth = fDAQmx_DIO_PortWidth(device, i)
		lines     = AddListItem(num2str(portWidth), lines, ",", Inf)
	endfor
	lines = RemoveEnding(lines, ",")

	propList  = "NAME:" + device
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
Function HW_NI_OpenDevice(string device, [variable flags])

	DEBUGPRINTSTACKINFO()

	HW_NI_ResetDevice(device, flags = flags)
	HW_NI_CalibrateDevice(device, flags = flags)
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
			lines     = AddListItem(num2str(portWidth), lines, ",", Inf)
		endfor

		lines = RemoveEnding(lines, ",")

		printf "Device name: %s\r", device
		printf "#AI %d, #AO %d, #Cnt %d, #DIO ports %d with (%s) lines\r", numAI, numAO, numCounter, numDIO, lines
		printf "Last self calibration: %s\r", SelectString(IsFinite(selfCalDate), "na", GetIso8601TimeStamp(secondsSinceIgorEpoch = selfCalDate))
		printf "Last external calibration: %s\r", GetIso8601TimeStamp(secondsSinceIgorEpoch = extCalDate)
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
Function HW_NI_ReadDigital(string device, [variable DIOPort, variable DIOLine, variable flags])

	variable taskID, ret, result, lineGrouping
	string line

	DEBUGPRINTSTACKINFO()

	if(ParamIsDefault(DIOPort))
		DIOPort = 0
	endif

	if(ParamIsDefault(DIOLine))
		sprintf line, "/%s/port%d", device, DIOPort
		lineGrouping = 0
	else
		lineGrouping = 1
		ASSERT(DIOline <= fDAQmx_DIO_PortWidth(device, DIOport), "Line does not exist in port")
		sprintf line, "/%s/port%d/line%d", device, DIOPort, DIOline
	endif

	AssertOnAndClearRTError()
	DAQmx_DIO_Config/DEV=device/DIR=1/LGRP=(lineGrouping) line

	if(ClearRTError())
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
Function HW_NI_WriteDigital(string device, variable value, [variable DIOPort, variable DIOLine, variable flags])

	variable taskID, ret, lineGrouping
	string line

	DEBUGPRINTSTACKINFO()

	if(ParamIsDefault(DIOPort))
		DIOPort = 0
	endif

	if(ParamIsDefault(DIOLine))
		sprintf line, "/%s/port%d", device, DIOPort
		lineGrouping = 0
	else
		lineGrouping = 1
		ASSERT(DIOline <= fDAQmx_DIO_PortWidth(device, DIOport), "Line does not exist in port")
		sprintf line, "/%s/port%d/line%d", device, DIOPort, DIOline
	endif

	AssertOnAndClearRTError()
	DAQmx_DIO_Config/DEV=device/DIR=1/LGRP=(lineGrouping) line

	if(ClearRTError())
		print fDAQmx_ErrorString()
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling DAQmx_DIO_Config")
		endif
		return NaN
	endif

	taskID = V_DAQmx_DIO_TaskNumber

	ASSERT((log(value) / log(2)) <= fDAQmx_DIO_PortWidth(device, DIOport), "value has bits sets which are higher than the number of output lines in this port")
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
Function HW_NI_WriteAnalogSingleAndSlow(string device, variable channel, variable value, [variable flags])

	variable ret

	DEBUGPRINTSTACKINFO()

	ASSERT(value < HW_NI_MAX_VOLTAGE && value > HW_NI_MIN_VOLTAGE, "Value to set is out of range")
	ret = fDAQmx_WriteChan(device, channel, value, HW_NI_MIN_VOLTAGE, HW_NI_MAX_VOLTAGE)

	if(ret)
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error: " + fDAQmx_ErrorString())
		else
			DEBUGPRINT("Error: ", str = fDAQmx_ErrorString())
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
Function HW_NI_ReadAnalogSingleAndSlow(string device, variable channel, [variable flags])

	variable value

	DEBUGPRINTSTACKINFO()

	value = fDAQmx_ReadChan(device, channel, HW_NI_MIN_VOLTAGE, HW_NI_MAX_VOLTAGE, HW_NI_DIFFERENTIAL_SETUP)

	if(!IsFinite(value))
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error " + fDAQmx_ErrorString())
		else
			DEBUGPRINT("Error: ", str = fDAQmx_ErrorString())
		endif
	endif

	return value
End

/// @brief Returns a bit combination of the allowed configurations for the given analog input channel
///
/// @return Bit combination of @ref NIAnalogInputConfigs
Function HW_NI_GetAnalogInputConfig(string device, variable channel, [variable flags])

	variable value

	DEBUGPRINTSTACKINFO()

#if exists("fDAQmx_AI_ChannelConfigs")
	value = fDAQmx_AI_ChannelConfigs(device, channel)
#else
	ASSERT(0, "Your NIDAQmx XOP is too old to be usable as it is missing fDAQmx_AI_ChannelConfigs. Please contact the manufacturer for an updated version.")
#endif

	if(!IsFinite(value))
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error " + fDAQmx_ErrorString())
		else
			DEBUGPRINT("Error: ", str = fDAQmx_ErrorString())
		endif
	endif

	return value
End

/// @brief Return a list of all NI devices which can be opened
///
/// @param flags [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function/S HW_NI_ListDevices([variable flags])

	DEBUGPRINTSTACKINFO()

#ifndef EVIL_KITTEN_EATING_MODE
#if defined(TESTS_WITH_ITC18USB_HARDWARE)
	return ""
#elif defined(TESTS_WITH_ITC1600_HARDWARE)
	return ""
#elif defined(TESTS_WITH_SUTTER_HARDWARE)
	return ""
#endif
#endif // !EVIL_KITTEN_EATING_MODE

	return fDAQmx_DeviceNames()
End

/// @brief Stop scanning and waveform generation
///
/// @param[in] deviceID 		 ID of the NI device
/// @param[in] zeroDAC       [optional, defaults to false] set all DA channels to zero
/// @param[in] flags         [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @see HW_StopAcq
Function HW_NI_StopAcq(variable deviceID, [variable zeroDAC, variable flags])

	string device

	HW_NI_StopADC(deviceID, flags = flags)
	HW_NI_StopDAC(deviceID, flags = flags)
	HW_NI_StopTTL(deviceID, flags = flags)

	if(zeroDAC)
		DEBUGPRINTSTACKINFO()
		HW_NI_ZeroDAC(deviceID, flags = flags)
	endif
End

/// @brief Stop ADC task
///
/// @param[in] deviceID ID of the NI device
/// @param[in] flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_StopADC(variable deviceID, [variable flags])

	DEBUGPRINTSTACKINFO()

	variable ret
	string realDeviceOrPressure, device

	device = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
	NVAR taskIDADC = $GetNI_ADCTaskID(device)
	if(!isNaN(taskIDADC))
		realDeviceOrPressure = HW_GetDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
		ret                  = fDAQmx_ScanStop(realDeviceOrPressure)
		if(ret)
			print fDAQmx_ErrorString()
			printf "Error %d: fDAQmx_ScanStop\r", ret
			ControlWindowToFront()
			if(flags & HARDWARE_ABORT_ON_ERROR)
				ASSERT(0, "Error calling fDAQmx_ScanStop (has Scan already finished?)")
			endif
		endif
		taskIDADC = NaN
		HW_NI_KillFifo(deviceID)
	endif
End

/// @brief Stop DAC task
///
/// @param[in] deviceID ID of the NI device
/// @param[in] flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_StopDAC(variable deviceID, [variable flags])

	DEBUGPRINTSTACKINFO()

	variable ret
	string realDeviceOrPressure, device

	device = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
	NVAR taskIDDAC = $GetNI_DACTaskID(device)
	if(!isNaN(taskIDDAC))
		realDeviceOrPressure = HW_GetDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
		ret                  = fDAQmx_WaveformStop(realDeviceOrPressure)
		if(ret)
			print fDAQmx_ErrorString()
			printf "Error %d: fDAQmx_WaveformStop\r", ret
			ControlWindowToFront()
			if(flags & HARDWARE_ABORT_ON_ERROR)
				ASSERT(0, "Error calling fDAQmx_WaveformStop")
			endif
		endif
		taskIDDAC = NaN
	endif
End

/// @brief Stop TTL task
///
/// @param[in] deviceID ID of the NI device
/// @param[in] flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_StopTTL(variable deviceID, [variable flags])

	DEBUGPRINTSTACKINFO()

	variable ret
	string realDeviceOrPressure, device

	device = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
	NVAR taskIDTTL = $GetNI_TTLTaskID(device)
	if(!isNaN(taskIDTTL))
		realDeviceOrPressure = HW_GetDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
		ret                  = fDAQmx_DIO_Finished(realDeviceOrPressure, taskIDTTL)
		if(ret)
			print fDAQmx_ErrorString()
			printf "Error %d: fDAQmx_DIO_Finished\r", ret
			ControlWindowToFront()
			if(flags & HARDWARE_ABORT_ON_ERROR)
				ASSERT(0, "Error calling fDAQmx_DIO_Finished")
			endif
		endif
		taskIDTTL = NaN
	endif
End

/// @brief Zero analog output on all DAC channels
///
/// @param[in] deviceID ID of the NI device
/// @param[in] flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_ZeroDAC(variable deviceID, [variable flags])

	DEBUGPRINTSTACKINFO()

	string realDeviceOrPressure, device, paraStr
	variable channels, i

	realDeviceOrPressure = HW_GetDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
	device               = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)
	WAVE config = GetDAQConfigWave(device)

	paraStr  = ""
	channels = DimSize(config, ROWS)
	for(i = 0; i < channels; i += 1)
		if(config[i][%ChannelType] == XOP_CHANNEL_TYPE_DAC)
			paraStr += "0," + num2str(config[i][%ChannelNumber]) + ";"
		endif
	endfor

	AssertOnAndClearRTError()
	DAQmx_AO_SetOutputs/DEV=realDeviceOrPressure paraStr

	if(ClearRTError())
		print fDAQmx_ErrorString()
		ControlWindowToFront()
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling DAQmx_AO_SetOutputs")
		endif
		return NaN
	endif
End

/// @brief Kill the FIFO of the given NI device
///
/// @param deviceID device identifier
Function HW_NI_KillFifo(variable deviceID)

	DEBUGPRINTSTACKINFO()

	string fifoName, errMsg, device
	variable err

	device   = HW_GetMainDeviceName(HARDWARE_NI_DAC, deviceID, flags = HARDWARE_PREVENT_ERROR_MESSAGE)
	fifoName = GetNIFIFOName(deviceID)

	FIFOStatus/Q $fifoName
	if(!V_Flag)
		return NaN
	endif

	AssertOnAndClearRTError()
	try
		if(V_FIFORunning)
			CtrlFIFO $fifoName, stop; AbortOnRTE
		endif
		DoXOPIdle
		KillFIFO $fifoName; AbortOnRTE
	catch
		errMsg = GetRTErrMessage()
		err    = ClearRTError()
		print "Could not cleanup FIFO of NI device " + device + ", failed with code: " + num2str(err) + "\r" + errMsg
		ControlWindowToFront()
	endtry
End

/// @brief Reset device
///
/// @param device name of the NI device
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
static Function HW_NI_ResetDevice(string device, [variable flags])

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
	HW_NI_ResetTaskIDs(device)
End

/// @brief Reset task IDs for NI hardware
///
/// @param device name of the NI device
Function HW_NI_ResetTaskIDs(string device)

	NVAR taskIDADC = $GetNI_ADCTaskID(device)
	NVAR taskIDDAC = $GetNI_DACTaskID(device)
	NVAR taskIDTTL = $GetNI_TTLTaskID(device)
	taskIDADC = NaN
	taskIDDAC = NaN
	taskIDTTL = NaN
End

/// @brief Check if the device is running
///
/// @param device name of the NI device
Function HW_NI_IsRunning(string device)

	DEBUGPRINTSTACKINFO()

	NVAR taskIDADC = $GetNI_ADCTaskID(device)
	NVAR taskIDDAC = $GetNI_DACTaskID(device)
	NVAR taskIDTTL = $GetNI_TTLTaskID(device)

	return (IsFinite(taskIDADC) || IsFinite(taskIDDAC) || IsFinite(taskIDTTL))
End

/// @brief Calibrate a NI device if it wasn't calibrated within the last 24h.
///
/// @param device name of the NI device
/// @param force  [optional, default 0] When not zero, forces a calibration
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
static Function HW_NI_CalibrateDevice(string device, [variable force, variable flags])

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
Function HW_NI_CloseDevice(variable deviceID, [variable flags])

	string deviceType, deviceNumber, deviceName

	DEBUGPRINTSTACKINFO()

	deviceName = HW_GetDeviceName(HARDWARE_NI_DAC, deviceID, flags = flags)

	if(IsEmpty(deviceName))
		return NaN
	endif

	ASSERT(ParseDeviceString(deviceName, deviceType, deviceNumber), "Error parsing device string!")

	if(HW_NI_IsRunning(deviceType))
		HW_NI_StopAcq(deviceID, flags = flags)
	else
		HW_NI_KillFifo(deviceID)
	endif
End

/// @see HW_GetDeviceInfo
Function/WAVE HW_NI_GetDeviceInfo(string device, [variable flags])

	DEBUGPRINTSTACKINFO()

#if exists("DAQmx_DeviceInfo")

	AssertOnAndClearRTError()
	try
		DAQmx_DeviceInfo/DEV=device; AbortOnRTE
	catch
		ClearRTError()
		return $""
	endtry

	Make/FREE/T/N=(8) deviceInfo
	SetDimLabel ROWS, 0, DeviceCategoryNum, deviceInfo
	SetDimLabel ROWS, 1, ProductNumber, deviceInfo
	SetDimLabel ROWS, 2, DeviceSerialNumber, deviceInfo
	SetDimLabel ROWS, 3, DeviceCategoryStr, deviceInfo
	SetDimLabel ROWS, 4, ProductType, deviceInfo
	SetDimLabel ROWS, 5, AI, deviceInfo
	SetDimLabel ROWS, 6, AO, deviceInfo
	SetDimLabel ROWS, 7, DIOPortWidth, deviceInfo

	deviceInfo[%DeviceCategoryNum]  = num2istr(V_NIDeviceCategory)
	deviceInfo[%ProductNumber]      = num2istr(V_NIProductNumber)
	deviceInfo[%DeviceSerialNumber] = num2istr(V_NIDeviceSerialNumber)
	deviceInfo[%DeviceCategoryStr]  = S_NIDeviceCategory
	// S_NIProductType has a trailing \0
	deviceInfo[%ProductType] = RemoveEnding(S_NIProductType, num2char(0))

	deviceInfo[%AI]           = num2str(fDAQmx_NumAnalogInputs(device))
	deviceInfo[%AO]           = num2str(fDAQmx_NumAnalogOutputs(device))
	deviceInfo[%DIOPortWidth] = num2str(fDAQmx_DIO_PortWidth(device, HARDWARE_NI_TTL_PORT))

	return deviceInfo
#else
	ASSERT(0, "Your NIDAQmx XOP is too old to be usable as it is missing DAQmx_DeviceInfo. Please contact the manufacturer for an updated version.")

	return $""
#endif

End

#else

Function HW_NI_StartAcq(variable deviceID, variable triggerMode, [variable flags, variable repeat])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_PrepareAcq(variable deviceID, variable mode, [WAVE/Z data, FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable flags, variable offset])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function/S HW_NI_GetPropertyListOfDevices(string device)

	return ""
End

Function HW_NI_PrintPropertiesOfDevices()

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_ReadDigital(string device, [variable DIOPort, variable DIOLine, variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_WriteDigital(string device, variable value, [variable DIOPort, variable DIOLine, variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_WriteAnalogSingleAndSlow(string device, variable channel, variable value, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_ReadAnalogSingleAndSlow(string device, variable channel, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_GetAnalogInputConfig(string device, variable channel, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function/S HW_NI_ListDevices([variable flags])

	return ""
End

Function HW_NI_StopAcq(variable deviceID, [variable zeroDAC, variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_StopDAC(variable deviceID, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_StopADC(variable deviceID, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_StopTTL(variable deviceID, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_ZeroDAC(variable deviceID, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

static Function HW_NI_ResetDevice(string device, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

static Function HW_NI_CalibrateDevice(string device, [variable force, variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_IsRunning(string device, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_OpenDevice(string device, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_CloseDevice(variable deviceID, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function/WAVE HW_NI_GetDeviceInfo(string device, [variable flags])

	DoAbortNow("NI-DAQ XOP is not available")
End

Function HW_NI_ResetTaskIDs(string device)

	DoAbortNow("NI-DAQ XOP is not available")
End

#endif // NIDAQMX_XOP_PRESENT

#ifdef SUTTER_XOP_PRESENT

/// @brief Return a the serial string of the SUTTER master device if present
///
/// @param flags [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function/S HW_SU_ListDevices([variable flags])

	DEBUGPRINTSTACKINFO()

#ifndef EVIL_KITTEN_EATING_MODE
#if defined(TESTS_WITH_ITC18USB_HARDWARE)
	return ""
#elif defined(TESTS_WITH_ITC1600_HARDWARE)
	return ""
#elif defined(TESTS_WITH_NI_HARDWARE)
	return ""
#endif
#endif // !EVIL_KITTEN_EATING_MODE

	WAVE/T deviceInfo = GetSUDeviceInfo()

	return deviceInfo[%MASTERDEVICE]
End

Function HW_SU_CloseDevice(variable deviceID, [variable flags])

	string device

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_SUTTER_DAC, deviceID, flags = flags)
	if(HW_SU_IsRunning(device))
		HW_SU_StopAcq(deviceID, flags = flags)
	endif

	SutterDAQUSBClose()
	WAVE/T deviceInfo = GetSUDeviceInfo()
	deviceInfo = ""
End

static Function HW_SU_IsRunning(string device)

	return ROVar(GetSU_IsAcquisitionRunning(device))
End

/// @brief Reset device
///
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
static Function HW_SU_ResetDevice([variable flags])

	DEBUGPRINTSTACKINFO()

	SutterDAQReset()
End

/// @brief Opens a Sutter device, executes reset

/// @param flags [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_SU_OpenDevice([variable flags])

	DEBUGPRINTSTACKINFO()

	HW_SU_ResetDevice(flags = flags)
End

/// @see HW_GetDeviceInfo
Function HW_SU_GetDeviceInfo(WAVE/T deviceInfo)

	variable numIPAs, i, numHeadstages, numDevices
	string serial
	string deviceList = ""
	string numHSList  = ""

	DEBUGPRINTSTACKINFO()

#ifdef AUTOMATED_TESTING
#ifndef TESTS_WITH_SUTTER_HARDWARE
	return NaN
#endif // !TESTS_WITH_SUTTER_HARDWARE
#endif // AUTOMATED_TESTING

	if(!IsEmpty(deviceInfo[%NUMBEROFDACS]))
		return NaN
	endif

	numIPAs                   = SutterDAQusbreset()
	deviceInfo[%NUMBEROFDACS] = num2istr(numIPAs)
	for(i = 0; i < numIPAs; i += 1)
		serial = CleanupName(SutterDAQSN(i), 0)
		ASSERT(strlen(serial) > 6, "Error parsing IPA serial: " + serial)
		deviceList = AddListItem(serial, deviceList, ";", Inf)
		strswitch(serial[6])
			case "1":
				numHeadstages += 1
				numHSList      = AddListItem("1", numHSList, ";", Inf)
				break
			case "2":
				numHeadstages += 2
				numHSList      = AddListItem("2", numHSList, ";", Inf)
				break
			default:
				ASSERT(0, "Error parsing IPA serial: " + serial)
		endswitch
	endfor
	numDevices = ItemsInList(deviceList)
	// @todo Check for SU MultiDevices if Master is subdev 0 (when multi device setup is available)
	deviceInfo[%MASTERDEVICE]     = StringFromList(0, deviceList)
	deviceInfo[%LISTOFDEVICES]    = deviceList
	deviceInfo[%LISTOFHEADSTAGES] = numHSList
	deviceInfo[%SUMHEADSTAGES]    = num2istr(numHeadstages)
	deviceInfo[%AI]               = num2istr(SUTTER_AI_PER_AMP * numDevices)
	deviceInfo[%AO]               = num2istr(SUTTER_AO_PER_AMP * numDevices)
	deviceInfo[%DIOPortWidth]     = num2istr(SUTTER_DIO_PER_AMP)
End

/// @brief Stop scanning and waveform generation
///
/// @param[in] zeroDAC       [optional, defaults to false] set all DA channels to zero
/// @param[in] flags         [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @see HW_StopAcq
Function HW_SU_StopAcq(variable deviceID, [variable zeroDAC, variable flags])

	string device

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_SUTTER_DAC, deviceID, flags = flags)
	NVAR acq = $GetSU_IsAcquisitionRunning(device)
	if(acq)
		SutterDAQReset()
		acq = 0
	endif

	if(zeroDAC)
		HW_SU_ZeroDAC(deviceID, flags = flags)
	endif
End

/// @brief Prepare for data acquisition
///
/// @param mode        one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param data        ITC data wave
/// @param dataFunc    [optional, defaults to GetDAQDataWave()] override wave getter for the ITC data wave
/// @param config      ITC config wave
/// @param configFunc  [optional, defaults to GetDAQConfigWave()] override wave getter for the ITC config wave
/// @param offset      [optional, defaults to zero] offset into the data wave in points
/// @param flags       [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_SU_PrepareAcq(variable deviceId, variable mode, [WAVE/Z data, FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable flags, variable offset])

	string device, encodeInfo
	variable channels, i, haveTTL, unassocADCIndex, unassocDACIndex
	variable headStage, channelNumber, amp0Type
	variable outIndex, inIndex, outChannel, inChannel

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_SUTTER_DAC, deviceID, flags = flags)
	if(ParamIsDefault(data))
		if(ParamIsDefault(dataFunc))
			WAVE/WAVE SUDataWave = GetDAQDataWave(device, mode)
		else
			WAVE/WAVE SUDataWave = dataFunc(device)
		endif
	endif

	if(ParamIsDefault(config))
		if(ParamIsDefault(configFunc))
			WAVE config = GetDAQConfigWave(device)
		else
			WAVE config = configFunc(device)
		endif
	endif

	if(!ParamIsDefault(offset))
		ASSERT(0, "Offset is not supported")
	endif

	WAVE gain        = SWS_GetChannelGains(device, timing = GAIN_BEFORE_DAQ)
	WAVE hwGainTable = GetSUDeviceInputGains(device)

	WAVE/T output = GetSUDeviceOutput(device)
	WAVE/T input  = GetSUDeviceInput(device)

	channels = DimSize(config, ROWS)
	for(i = 0; i < channels; i += 1)
		WAVE SUChannel = SUDataWave[i]

		ASSERT(!IsFreeWave(SUChannel), "Can not work with free waves")

		channelNumber = config[i][%ChannelNumber]
		headstage     = config[i][%HEADSTAGE]
		switch(config[i][%ChannelType])
			case XOP_CHANNEL_TYPE_ADC:
				EnsureLargeEnoughWave(input, indexShouldExist = inIndex)
				EnsureLargeEnoughWave(hwGainTable, indexShouldExist = inIndex)
				hwGainTable[inIndex][%GAINFACTOR] = gain[i]
				hwGainTable[inIndex][%OFFSET]     = 0
				input[inIndex][%INPUTWAVE]        = GetWavesDataFolder(SUChannel, 2)
				if(!IsAssociatedChannel(headStage))
					[inChannel, encodeInfo] = HW_SU_GetEncodeFromUnassocADC(unassocADCIndex)
					unassocADCIndex        += 1
				else
					[inChannel, encodeInfo] = HW_SU_GetEncodeFromHS(headstage)
					inChannel              *= 2
					if(config[i][%CLAMPMODE] == I_CLAMP_MODE)
						inChannel += 1
					endif
				endif
				input[inIndex][%CHANNEL]    = num2istr(inChannel)
				input[inIndex][%ENCODEINFO] = encodeInfo
				inIndex                    += 1
				break
			case XOP_CHANNEL_TYPE_DAC:
				EnsureLargeEnoughWave(output, indexShouldExist = outIndex)
				output[outIndex][%OUTPUTWAVE] = GetWavesDataFolder(SUChannel, 2)
				if(!IsAssociatedChannel(headStage))
					[outChannel, encodeInfo] = HW_SU_GetEncodeFromUnassocDAC(unassocDACIndex)
					unassocDACIndex         += 1
				else
					[outChannel, encodeInfo] = HW_SU_GetEncodeFromHS(headstage)
				endif
				output[outIndex][%CHANNEL]    = num2istr(outChannel)
				output[outIndex][%ENCODEINFO] = encodeInfo
				outIndex                     += 1
				break
			case XOP_CHANNEL_TYPE_TTL:
				if(!haveTTL)
					haveTTL = 1
					WAVE ttlComposite = GetSUCompositeTTLWave(device)
					FastOp ttlComposite = 0
					Redimension/N=(DimSize(SUChannel, ROWS)) ttlComposite
				endif
				MultiThread ttlComposite[] += SUChannel[p] * (1 << channelNumber)
				break
			default:
				ASSERT(0, "Unsupported channel type")
				break
		endswitch
	endfor

	if(haveTTL)
		WAVE/T deviceInfo = GetSUDeviceInfo()
		amp0Type = NumberFromList(0, deviceInfo[%LISTOFHEADSTAGES])
		sprintf encodeInfo, "00%02d-1", amp0Type

		EnsureLargeEnoughWave(output, indexShouldExist = outIndex)
		output[outIndex][%OUTPUTWAVE] = GetWavesDataFolder(ttlComposite, 2)
		output[outIndex][%CHANNEL]    = num2istr(amp0Type - 1 + SUTTER_CHANNELOFFSET_TTL)
		output[outIndex][%ENCODEINFO] = encodeInfo
		outIndex                     += 1
	endif
	Redimension/N=(outIndex, -1) output
	Redimension/N=(inIndex, -1) input
	Redimension/N=(inIndex, -1) hwGainTable
End

static Function [variable channel, string encode] HW_SU_GetEncodeFromHS(variable headstage)

	variable i, index, subHS, numAmps, ampType
	variable amp = NaN

	WAVE/T deviceInfo = GetSUDeviceInfo()
	WAVE   hsNums     = ListToNumericWave(deviceInfo[%LISTOFHEADSTAGES], ";")

	for(hsInAmp : hsNums)
		i += hsInAmp
		if(i > headstage)
			amp     = index
			ampType = hsInAmp
			subHS   = index ? (headstage - sum(hsNums, 0, index - 1)) : headstage
			break
		endif
		index += 1
	endfor

	ASSERT(!IsNaN(amp), "Headstage " + num2istr(headstage) + " beyond available headstages on connected IPAs")
	sprintf encode, "%02d%02d%02d", amp, ampType, subHS

	return [subHS, encode]
End

static Function [variable hwChannel, string encode] HW_SU_GetEncodeFromUnassocADC(variable channelNumber)

	variable amp, ampType, hwChannelOffset

	WAVE/T deviceInfo = GetSUDeviceInfo()
	WAVE   hsNums     = ListToNumericWave(deviceInfo[%LISTOFHEADSTAGES], ";")
	amp = trunc(channelNumber / SUTTER_AI_PER_AMP)
	ASSERT(amp < DimSize(hsNums, ROWS), "Analog In " + num2istr(channelNumber) + " beyond available Analog Ins on connected IPAs")
	ampType = hsNums[amp]
	// Each headstage adds two channel in the front
	hwChannelOffset = 2 * ampType
	hwChannel       = channelNumber - amp * SUTTER_AI_PER_AMP + hwChannelOffset

	sprintf encode, "%02d%02d%02d", amp, ampType, -1

	return [hwChannel, encode]
End

static Function [variable hwChannel, string encode] HW_SU_GetEncodeFromUnassocDAC(variable channelNumber)

	variable amp, ampType

	WAVE/T deviceInfo = GetSUDeviceInfo()
	WAVE   hsNums     = ListToNumericWave(deviceInfo[%LISTOFHEADSTAGES], ";")
	amp = trunc(channelNumber / SUTTER_AO_PER_AMP)
	ASSERT(amp < DimSize(hsNums, ROWS), "Analog Out " + num2istr(channelNumber) + " beyond available Analog Outs on connected IPAs")
	ampType   = hsNums[amp]
	hwChannel = channelNumber - amp * SUTTER_AO_PER_AMP + ampType

	sprintf encode, "%02d%02d%02d", amp, ampType, -1

	return [hwChannel, encode]
End

Function HW_SU_StartAcq(variable deviceId, [variable flags])

	string device, cmdError, cmdDone

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_SUTTER_DAC, deviceID, flags = flags)
	WAVE/T output      = GetSUDeviceOutput(device)
	WAVE/T input       = GetSUDeviceInput(device)
	WAVE   hwGainTable = GetSUDeviceInputGains(device)
	HW_SU_AcquireImpl(device, input, output, hwGainTable, SUTTER_ACQUISITION_BACKGROUND)
End

Function HW_SU_ZeroDAC(variable deviceID, [variable flags])

	string device, encodeInfo
	variable i, outIndex, channels, channelNumber, headStage, outChannel, inChannel, unassocDACIndex

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_SUTTER_DAC, deviceID, flags = flags)
	WAVE   config    = GetDAQConfigWave(device)
	WAVE/T input     = GetSUDeviceInput(device)
	WAVE/T output    = GetSUDeviceOutput(device)
	WAVE   channelDA = GetSutterSingleSampleDACOutputWave(device)
	WAVE   channelAD = GetSutterSingleSampleADCInputWave(device)
	channelDA = 0

	channels = DimSize(config, ROWS)
	for(i = 0; i < channels; i += 1)

		channelNumber = config[i][%ChannelNumber]
		headstage     = config[i][%HEADSTAGE]
		if(config[i][%ChannelType] == XOP_CHANNEL_TYPE_DAC)
			EnsureLargeEnoughWave(output, indexShouldExist = outIndex)
			output[outIndex][%OUTPUTWAVE] = GetWavesDataFolder(channelDA, 2)
			if(!IsAssociatedChannel(headStage))
				[outChannel, encodeInfo] = HW_SU_GetEncodeFromUnassocDAC(unassocDACIndex)
				unassocDACIndex         += 1
			else
				[outChannel, encodeInfo] = HW_SU_GetEncodeFromHS(headstage)
			endif
			output[outIndex][%CHANNEL]    = num2istr(outChannel)
			output[outIndex][%ENCODEINFO] = encodeInfo
			outIndex                     += 1
		endif
	endfor
	Redimension/N=(outIndex, -1) output

	// we need to run some input as well to have the command hook from SutterDAQScanWave
	Redimension/N=(1, -1) input
	input[0][%INPUTWAVE]    = GetWavesDataFolder(channelAD, 2)
	[inChannel, encodeInfo] = HW_SU_GetEncodeFromHS(0)
	inChannel              *= 2
	input[0][%CHANNEL]      = num2istr(inChannel)
	input[0][%ENCODEINFO]   = encodeInfo

	HW_SU_AcquireImpl(device, input, output, $"", SUTTER_ACQUISITION_FOREGROUND, timeout = 1)
End

Function HW_SU_ReadADC(variable deviceID, variable channel, [variable flags])

	string device, encodeInfo
	variable inChannel

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_SUTTER_DAC, deviceID, flags = flags)
	WAVE   config    = GetDAQConfigWave(device)
	WAVE/T input     = GetSUDeviceInput(device)
	WAVE   channelAD = GetSutterSingleSampleADCInputWave(device)

	Redimension/N=(1, -1) input
	input[0][%INPUTWAVE]    = GetWavesDataFolder(channelAD, 2)
	[inChannel, encodeInfo] = HW_SU_GetEncodeFromUnassocADC(channel)
	input[0][%CHANNEL]      = num2istr(inChannel)
	input[0][%ENCODEINFO]   = encodeInfo

	HW_SU_AcquireImpl(device, input, $"", $"", SUTTER_ACQUISITION_FOREGROUND, timeout = 1, inputOnly = 1)

	return channelAD[0]
End

Function HW_SU_WriteDAC(variable deviceID, variable channel, variable value, [variable flags])

	string device, encodeInfo
	variable outChannel, inChannel

	DEBUGPRINTSTACKINFO()

	device = HW_GetMainDeviceName(HARDWARE_SUTTER_DAC, deviceID, flags = flags)
	WAVE   config    = GetDAQConfigWave(device)
	WAVE/T input     = GetSUDeviceInput(device)
	WAVE/T output    = GetSUDeviceOutput(device)
	WAVE   channelDA = GetSutterSingleSampleDACOutputWave(device)
	WAVE   channelAD = GetSutterSingleSampleADCInputWave(device)
	channelDA = value

	Redimension/N=(1, -1) output
	output[0][%OUTPUTWAVE]   = GetWavesDataFolder(channelDA, 2)
	[outChannel, encodeInfo] = HW_SU_GetEncodeFromUnassocDAC(channel)
	output[0][%CHANNEL]      = num2istr(outChannel)
	output[0][%ENCODEINFO]   = encodeInfo

	// we need to run some input as well to have the command hook from SutterDAQScanWave
	Redimension/N=(1, -1) input
	input[0][%INPUTWAVE]    = GetWavesDataFolder(channelAD, 2)
	[inChannel, encodeInfo] = HW_SU_GetEncodeFromHS(0)
	inChannel              *= 2
	input[0][%CHANNEL]      = num2istr(inChannel)
	input[0][%ENCODEINFO]   = encodeInfo

	HW_SU_AcquireImpl(device, input, output, $"", SUTTER_ACQUISITION_FOREGROUND, timeout = 1)
End

/// @brief Wraps the hardware access for sutter acquisition
/// @param device    device name
/// @param input     input definition encoding for sutter
/// @param output    output definition encoding for sutter, can be a null wave if inputOnly flag is set
/// @param gain      gain wave for sutter input, can be a null wave if no gain should be set
/// @param mode      Either SUTTER_ACQUISITION_FOREGROUND or SUTTER_ACQUISITION_BACKGROUND for foreground or background acquisition respectively
/// @param timeout   [optional, default - required for foreground acquisition, must be > 0] time out in [s] for foreground acquisition. An ASSERT is thrown if the timeout is reached.
///                  timeout is not used in SUTTER_ACQUISITION_BACKGROUND mode.
/// @param inputOnly [optional, default 0] flag, when set only acquisition from ADC is run, when not set the DAC and ADC is run.
static Function HW_SU_AcquireImpl(string device, WAVE input, WAVE/Z output, WAVE/Z gain, variable mode, [variable timeout, variable inputOnly])

	string cmdError, cmdDone
	variable to

	inputOnly = ParamIsDefault(inputOnly) ? 0 : !!inputOnly

	if(mode == SUTTER_ACQUISITION_FOREGROUND)
		ASSERT(!ParamIsDefault(timeout), "Timeout argument in [s] must be set for foreground acquisition")
		ASSERT(timeout > 0, "Timeout must be greater than zero")
	endif

	NVAR err = $GetSU_AcquisitionError(device)
	NVAR acq = $GetSU_IsAcquisitionRunning(device)
	ASSERT(acq == 0, "Attempt to start acquisition while acquisition still running.")

	sprintf cmdDone, "HW_SU_AcqDone(\"%s\")", device
	sprintf cmdError, "HW_SU_AcqError(\"%s\")", device

	err = 0
	acq = 1
	if(!inputOnly)
		ASSERT(WaveExists(output), "definition wave for output is a null wave")
		SutterDAQWriteWave/MULT=1/T=1/R=0/RHP=0 output
	endif
	if(WaveExists(gain))
		SutterDAQScanWave/MULT=1/T=1/C=0/B=1/G=gain/E=cmdError/H=cmdDone input
	else
		SutterDAQScanWave/MULT=1/T=1/C=0/B=1/E=cmdError/H=cmdDone input
	endif
	SutterDAQClock(0, 0, 1)

	if(mode == SUTTER_ACQUISITION_BACKGROUND)
		return NaN
	endif

	to = DateTime + timeout
	do
		DoXOPIdle
	while(acq && err == 0 && DateTime < to)

	ASSERT(err == 0, "Hardware Error on foreground acquisition")
	ASSERT(acq == 0, "Hardware Error: Reached timeout in foreground acquisition")
End

Function HW_SU_AcqDone(string device)

	NVAR acq = $GetSU_IsAcquisitionRunning(device)
	acq = 0
End

Function HW_SU_AcqError(string device)

	NVAR err = $GetSU_AcquisitionError(device)
	NVAR acq = $GetSU_IsAcquisitionRunning(device)
	err = 1
	acq = 0
End

Function HW_SU_GetADCSamplePosition()

	variable pos

	SutterDAQReadAvailable(pos)

	return pos
End

#else

Function HW_SU_OpenDevice([variable flags])

	DoAbortNow("SUTTER XOP is not available")
End

Function/S HW_SU_ListDevices([variable flags])

	return ""
End

Function HW_SU_CloseDevice(variable deviceId, [variable flags])

	DoAbortNow("SUTTER XOP is not available")
End

static Function HW_SU_ResetDevice([variable flags])

	DoAbortNow("SUTTER XOP is not available")
End

Function HW_SU_GetDeviceInfo(WAVE/T deviceInfo)

	return NaN
End

static Function HW_SU_IsRunning(string device)

	DoAbortNow("SUTTER XOP is not available")
End

Function HW_SU_StopAcq(variable deviceId, [variable zeroDAC, variable flags])

	DoAbortNow("SUTTER XOP is not available")
End

Function HW_SU_PrepareAcq(variable deviceId, variable mode, [WAVE/Z data, FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, WAVE/Z config, FUNCREF HW_WAVE_GETTER_PROTOTYPE configFunc, variable flags, variable offset])

	DoAbortNow("SUTTER XOP is not available")
End

Function HW_SU_StartAcq(variable deviceId, [variable flags])

	DoAbortNow("SUTTER XOP is not available")
End

Function HW_SU_GetADCSamplePosition()

	DoAbortNow("SUTTER XOP is not available")
End

Function HW_SU_ZeroDAC(variable deviceID, [variable flags])

	DoAbortNow("SUTTER XOP is not available")
End

Function HW_SU_ReadADC(variable deviceID, variable channel, [variable flags])

	DoAbortNow("SUTTER XOP is not available")
End

Function HW_SU_WriteDAC(variable deviceID, variable channel, variable value, [variable flags])

	DoAbortNow("SUTTER XOP is not available")
End

#endif // SUTTER_XOP_PRESENT

///@}
