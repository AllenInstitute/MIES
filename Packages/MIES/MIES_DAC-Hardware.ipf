#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_DAC-Hardware.ipf
/// @brief __HW__ Low level hardware configuration and querying functions
///
/// Naming scheme of the functions is `HW_$TYPE_$Suffix` where `$TYPE` is one of `ITC` or `NI`.

/// @name Wrapper functions redirecting to the correct internal implementations depending on #HARDWARE_DAC_TYPES
/// @{

/// @brief Select a device
///
/// @param hardwareType One of @ref HardwareDACTypeConstants
/// @param deviceID identifier of the device
/// @param flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return 0 if sucessfull, 1 on error
Function HW_SelectDevice(hardwareType, deviceID, [flags])
	variable hardwareType, deviceID, flags

	HW_AssertOnInvalid(hardwareType, deviceID)

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
	variable deviceTypeIndex, deviceNumberIndex, deviceID

	hardwareType = NaN

	if(ParseDeviceString(deviceToOpen, deviceType, deviceNumber))
		deviceTypeIndex   = WhichListItem(deviceType, DEVICE_TYPES)
		deviceNumberIndex = WhichListItem(deviceNumber, DEVICE_NUMBERS)
		deviceID     = HW_ITC_OpenDevice(deviceTypeIndex, deviceNumberIndex)
		hardwareType = HARDWARE_ITC_DAC
	else
		deviceID     = WhichListItem(deviceToOpen, HW_NI_ListDevices())
		hardwareType = HARDWARE_NI_DAC
	endif

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

	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_CloseDevice(flags=flags)
			break
		case HARDWARE_NI_DAC:
			// nothing do be done
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
			HW_ITC_EnableYoking(flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
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
			HW_ITC_DisableYoking(flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			ASSERT(0, "Not implemented")
			break
	endswitch
End

/// @brief Stop data acquisition
///
/// @param hardwareType  One of @ref HardwareDACTypeConstants
/// @param deviceID      device identifier
/// @param prepareForDAQ immediately prepare for the next data acquisition after stopping it
/// @param flags         [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_StopAcq(hardwareType, deviceID, [prepareForDAQ, flags])
	variable hardwareType, deviceID, prepareForDAQ, flags

	string device
	HW_AssertOnInvalid(hardwareType, deviceID)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_StopAcq(prepareForDAQ=prepareForDAQ, flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
			HW_NI_StopAcq(device)
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
			return HW_ITC_IsRunning(flags=flags)
			break
		case HARDWARE_NI_DAC:
			device = HW_GetInternalDeviceName(hardwareType, deviceID)
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
Function HW_StartAcq(hardwareType, deviceID, [triggerMode, flags])
	variable hardwareType, deviceID, triggerMode, flags

	HW_AssertOnInvalid(hardwareType, deviceID)

	if(ParamIsDefault(triggerMode))
		triggerMode = HARDWARE_DAC_DEFAULT_TRIGGER
	endif

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			HW_ITC_StartAcq(triggerMode, flags=flags)
			break
		case HARDWARE_NI_DAC:
			/// @todo add start acq NI code
			ASSERT(0, "not yet implemented")
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
			HW_NI_ResetDevice(device, flags=flags)
			break
	endswitch
End

/// @brief Assert on using an invalid value of `hardwareType` or `deviceID`
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

/// @name ITC
/// @{

/// @brief Open a ITC device
///
/// @param deviceType   zero-based index into #DEVICE_TYPES
/// @param deviceNumber zero-based index into #DEVICE_NUMBERS
/// @param flags [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return ITC device ID
Function HW_ITC_OpenDevice(deviceType, deviceNumber, [flags])
	variable deviceType, deviceNumber
	variable flags

	string cmd
	variable deviceID

	Make/O/I/U/N=1 DevID = -1
	sprintf cmd, "ITCOpenDevice %d, %d, DevID", deviceType, deviceNumber

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif

	printf "ITC Device ID = %d is locked.\r", DevID[0]

	deviceID = DevID[0]
	KillOrMoveToTrash(wv=DevID)

	return deviceID
End

/// @see HW_CloseDevice
Function HW_ITC_CloseDevice([flags])
	variable flags

	string cmd
	sprintf cmd, "ITCCloseDevice"

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

/// @see HW_SelectDevice
Function HW_ITC_SelectDevice(deviceID, [flags])
	variable deviceID, flags

	string cmd
	sprintf cmd, "ITCSelectDevice/Z %d", deviceID

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

/// @see HW_EnableYoking
Function HW_ITC_EnableYoking([flags])
	variable flags

	string cmd

	sprintf cmd, "ITCInitialize/M=1"
	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

/// @see HW_DisableYoking
Function HW_ITC_DisableYoking([flags])
	variable flags

	string cmd

	sprintf cmd, "ITCInitialize/M=0"
	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

/// @see HW_StopAcq
Function HW_ITC_StopAcq([prepareForDAQ, flags])
	variable prepareForDAQ, flags

	string cmd

	prepareForDAQ = !!prepareForDAQ

	sprintf cmd, "ITCStopAcq"

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif

	if(prepareForDAQ)
		sprintf cmd, "ITCConfigChannelUpload"

		if(flags & HARDWARE_ABORT_ON_ERROR)
			ExecuteITCOperationAbortOnError(cmd)
		else
			ExecuteITCOperation(cmd)
		endif
	endif
End

/// @brief Return the deviceID of the currently selected
///        ITC device from the XOP
Function HW_ITC_GetCurrentDevice([flags])
	variable flags

	string cmd
	variable val

	Make/O/I/N=1 dev
	sprintf cmd "ITCGetCurrentDevice %s", GetWavesDataFolder(dev, 2)

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif

	val = dev[0]
	KillOrMoveToTrash(wv=dev)
	return val
End

/// @brief Reset the AD/DA channel FIFOs
///
/// @param deviceID device identifier
/// @param fifoPos  [optional, defaults to GetITCFIFOPositionAllConfigWave()]
///                 Wave with new fifo positions
/// @param flags    [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_ResetFifo(deviceID, [fifoPos, flags])
	variable deviceID
	WAVE/Z fifoPos
	variable  flags

	string cmd, panelTitle

	panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

	if(ParamIsDefault(fifoPos))
		WAVE fifoPos = GetITCFIFOPositionAllConfigWave(panelTitle)
	endif

	sprintf cmd, "ITCUpdateFIFOPositionAll %s", GetWavesDataFolder(fifoPos, 2)
	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

/// @see HW_StartAcq
Function HW_ITC_StartAcq(triggerMode, [flags])
	variable triggerMode, flags

	string cmd

	switch(triggerMode)
		case HARDWARE_DAC_EXTERNAL_TRIGGER:
			sprintf cmd, "ITCStartAcq 1, 256"
			break
		case HARDWARE_DAC_DEFAULT_TRIGGER:
			sprintf cmd, "ITCStartAcq"
			break
		default:
			ASSERT(0, "Unknown trigger mode")
			break
	endswitch

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

/// @brief Check wether DAQ is still ongoing
///
/// @param flags        [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_IsRunning([flags])
	variable flags

	variable val

	Make/I/N=(4)/O state
	HW_ITC_GetState(state, flags=flags)
	val = state[0]
	KillOrMoveToTrash(wv=state)

	return val
End

/// @brief Fill the passed wave `state` with information about
///        the ITC device state
///
/// @param state 32bit integer wave with 4 rows to fill with state information
/// @param flags [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_GetState(state, [flags])
	WAVE state
	variable flags

	string cmd
	sprintf cmd, "ITCGetState/R/O/C/E %s", GetWavesDataFolder(state, 2)

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

/// @see HW_ReadADC
Function HW_ITC_ReadADC(deviceID, channel, [flags])
	variable deviceID, channel, flags

	string cmd
	variable val

	Make/N=1/D/O data
	sprintf cmd, "ITCReadADC/C=1/V=1 %d, %s", channel, GetWavesDataFolder(data, 2)

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif

	val = data[0]
	KillOrMoveToTrash(wv=data)

	return val
End

/// @see HW_WriteDAC
Function HW_ITC_WriteDAC(deviceID, channel, value, [flags])
	variable deviceID, channel, value, flags

	string cmd
	sprintf cmd, "ITCSetDAC %d, %g", channel, value

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

/// @see HW_ReadDigital
Function HW_ITC_ReadDigital(deviceID, xopChannel, [flags])
	variable deviceID, xopChannel, flags

	string cmd
	variable val

	Make/N=1/O/W data
	sprintf cmd, "ITCReadDigital %d, %s", xopChannel, GetWavesDataFolder(data, 2)

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
		val = data[0]
		KillOrMoveToTrash(wv=data)
	endif

	return val
End

/// @see HW_WriteDigital
Function HW_ITC_WriteDigital(deviceID, rack, value, [flags])
	variable deviceID, rack, value, flags

	string cmd
	sprintf cmd, "ITCWriteDigital %d, %d", rack, value

	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

Function/Wave HW_WAVE_GETTER_PROTOTYPE(str)
	string str
end

/// @brief Prepare for data acquisition
///
/// @param deviceID    device identifier
/// @param data        ITC data wave
/// @param dataFunc    [optional, defaults to GetITCDataWave()] override wave getter for the ITC data wave
/// @param config      ITC config wave
/// @param configFunc  [optional, defaults to GetITCChanConfigWave()] override wave getter for the ITC config wave
/// @param fifoPos     ITC fifo position wave
/// @param fifoPosFunc [optional, defaults to GetITCFIFOPositionAllConfigWave()] override wave getter for the ITC fifo position wave
/// @param flags       [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_ITC_PrepareAcq(deviceID, [data, dataFunc, config, configFunc, fifoPos, fifoPosFunc, flags])
	variable deviceID
	WAVE/Z data, config, fifoPos
	FUNCREF HW_WAVE_GETTER_PROTOTYPE dataFunc, configFunc, fifoPosFunc
	variable flags

	variable ret
	string cmd, panelTitle

	panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

	if(ParamIsDefault(data))
		if(ParamIsDefault(dataFunc))
			WAVE data = GetITCDataWave(panelTitle)
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

	if(ParamIsDefault(fifoPos))
		if(ParamIsDefault(fifoPosFunc))
			WAVE fifoPos = GetITCFIFOPositionAllConfigWave(panelTitle)
		else
			WAVE fifoPos = fifoPosFunc(panelTitle)
		endif
	endif

	sprintf cmd, "ITCconfigAllchannels %s, %s", GetWavesDataFolder(config, 2), GetWavesDataFolder(data, 2)
	if(flags & HARDWARE_ABORT_ON_ERROR)
		ret = ExecuteITCOperationAbortOnError(cmd)
	else
		ret = ExecuteITCOperation(cmd)
	endif

	if(ret)
		return NaN
	endif

	sprintf cmd, "ITCUpdateFIFOPositionAll %s", GetWavesDataFolder(fifoPos, 2)
	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif
End

/// @brief Check wether more data can be acquired
///
/// @param[in] deviceID            device identifier
/// @param[in] ADChannelToMonitor  [optional, defaults to GetADChannelToMonitor()] first AD channel
/// @param[in] stopCollectionPoint [optional, defaults to GetStopCollectionPoint()] number of points to acquire
/// @param[in] fifoAvail           [optional] ITC Fifo available wave
/// @param[in] fifoAvailFunc       [optional, defaults to GetITCFIFOPositionAllConfigWave()] override wave getter for the ITC fifo available wave
/// @param[out] fifoPos            [optional] allows to query the current fifo position
/// @param flags                   [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
///
/// @return 1 if more data needs to be acquired, 0 if done
Function HW_ITC_MoreData(deviceID, [ADChannelToMonitor, stopCollectionPoint, fifoAvail, fifoAvailFunc, fifoPos, flags])
	variable deviceID
	variable ADChannelToMonitor, stopCollectionPoint
	WAVE/Z fifoAvail
	FUNCREF HW_WAVE_GETTER_PROTOTYPE fifoAvailFunc
	variable &fifoPos
	variable flags

	variable fifoPosValue
	string cmd, panelTitle

	panelTitle = HW_GetMainDeviceName(HARDWARE_ITC_DAC, deviceID)

	if(ParamIsDefault(ADChannelToMonitor))
		NVAR ADChannelToMonitor_NVAR = $GetADChannelToMonitor(panelTitle)
		ADChannelToMonitor = ADChannelToMonitor_NVAR
	endif

	if(ParamIsDefault(stopCollectionPoint))
		NVAR stopCollectionPoint_NVAR = $GetStopCollectionPoint(panelTitle)
		stopCollectionPoint = stopCollectionPoint_NVAR
	endif

	if(ParamIsDefault(fifoAvail))
		if(ParamIsDefault(fifoAvailFunc))
			WAVE fifoAvail = GetITCFIFOAvailAllConfigWave(panelTitle)
		else
			WAVE fifoAvail = fifoAvailFunc(panelTitle)
		endif
	endif

	sprintf cmd, "ITCFIFOAvailableALL %s", GetWavesDataFolder(fifoAvail, 2)
	if(flags & HARDWARE_ABORT_ON_ERROR)
		ExecuteITCOperationAbortOnError(cmd)
	else
		ExecuteITCOperation(cmd)
	endif

	fifoPosValue = fifoAvail[ADChannelToMonitor][2]

	if(!ParamIsDefault(fifoPos))
		fifoPos = fifoPosValue
	endif

	return fifoPosValue < stopCollectionPoint
End

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
/// @}

/// @name NI
/// @{

#if exists("fDAQmx_DeviceNames")

/// @name Minimum voltages for the analog inputs/outputs
/// We always use the maximum range so that we have a constant resolution on the DAC
///@{
static Constant HW_NI_MIN_VOLTAGE = -10.0
static Constant HW_NI_MAX_VOLTAGE = +10.0
///@}

static Constant HW_NI_DIFFERENTIAL_SETUP = 0

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

	variable taskID, ret, result, lineGrouping
	string line

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

	DAQmx_DIO_Config/DEV=device/DIR=1/LGRP=(lineGrouping) line
	if (GetRTError(1))
		print fDAQmx_ErrorString()
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

	variable taskID, ret, lineGrouping
	string line

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

	DAQmx_DIO_Config/DEV=device/DIR=1/LGRP=(lineGrouping) line
	if (GetRTError(1))
		print fDAQmx_ErrorString()
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
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error calling fDAQmx_DIO_Write")
		endif
	endif

	ret = fDAQmx_DIO_Finished(device, taskID)
	if(ret)
		print fDAQmx_ErrorString()
		printf "Error %d: fDAQmx_DIO_Finished\r", ret
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

	ASSERT(value < HW_NI_MAX_VOLTAGE && value > HW_NI_MIN_VOLTAGE, "Value to set is out of range")
	ret = fDAQmx_WriteChan(device, channel, value, HW_NI_MIN_VOLTAGE, HW_NI_MAX_VOLTAGE)

	if(ret)
		if(flags & HARDWARE_ABORT_ON_ERROR)
			ASSERT(0, "Error: " + fDAQmx_ErrorString())
		else
			DEBUGPRINT("Error: ", str=fDAQmx_ErrorString())
		endif
	endif

	return ret != 0
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

	return fDAQmx_DeviceNames()
End

/// @brief Stop scanning and waveform generation
///
/// @param device name of the NI device
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_StopAcq(device, [flags])
	string device
	variable flags

	fDAQmx_ScanStop(device)
	return fDAQmx_WaveformStop(device) == 0
End

/// @brief Reset device
///
/// @param device name of the NI device
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_ResetDevice(device, [flags])
	string device
	variable flags

	fDAQmx_resetDevice(device)
End

/// @brief Check if the device is running
///
/// @param device name of the NI device
/// @param flags  [optional, default none] One or multiple flags from @ref HardwareInteractionFlags
Function HW_NI_IsRunning(device, [flags])
	string device
	variable flags

	return !fDAQmx_WF_IsFinished(device)
End

#else

Function HW_NI_PrintPropertiesOfDevices()
	Abort "NI-DAQ XOP is not available"
End

Function HW_NI_ReadDigital(device, [DIOPort, DIOLine, flags])
	string device
	variable DIOPort, DIOLine, flags

	Abort "NI-DAQ XOP is not available"
End

Function HW_NI_WriteDigital(device, value, [DIOPort, DIOLine, flags])
	string device
	variable DIOPort, DIOLine, value, flags

	Abort "NI-DAQ XOP is not available"
End

Function HW_NI_WriteAnalogSingleAndSlow(device, channel, value, [flags])
	string device
	variable channel, value, flags

	Abort "NI-DAQ XOP is not available"
End

Function HW_NI_ReadAnalogSingleAndSlow(device, channel, [flags])
	string device
	variable channel, flags

	Abort "NI-DAQ XOP is not available"
End

Function/S HW_NI_ListDevices([flags])
	variable flags

	return ""
End

Function HW_NI_StopAcq(device, [flags])
	string device
	variable flags

	Abort "NI-DAQ XOP is not available"
End

Function HW_NI_ResetDevice(device, [flags])
	string device
	variable flags

	Abort "NI-DAQ XOP is not available"
End

Function HW_NI_IsRunning(device, [flags])
	string device
	variable flags

	Abort "NI-DAQ XOP is not available"
End

#endif // exists NI DAQ XOP

/// @}
