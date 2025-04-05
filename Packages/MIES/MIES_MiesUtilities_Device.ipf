#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_DEVICE
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_Device.ipf
/// @brief This file holds MIES utility functions for Device handling

/// @brief Returns a list of all devices, e.g. "ITC18USB_Dev_0;..."
///        which were locked at some point
Function/S GetAllDevices()

	variable i, j, numEntries, numDevices
	string folder, number, device, folders, subFolders, subFolder
	string path
	string list = ""

	string devicesFolderPath = GetDAQDevicesFolderAsString()
	DFREF  devicesFolder     = GetDAQDevicesFolder()

	folders    = GetListOfObjects(devicesFolder, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER)
	numEntries = ItemsInList(folders)
	for(i = 0; i < numEntries; i += 1)
		folder = StringFromList(i, folders)

		if(GrepString(folder, ITC_DEVICE_REGEXP))
			DFREF subFolderDFR = $(devicesFolderPath + ":" + folder)
			subFolders = GetListOfObjects(subFolderDFR, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER)

			// ITC hardware is in a specific subfolder
			numDevices = ItemsInList(subFolders)
			for(j = 0; j < numDevices; j += 1)
				subFolder = StringFromList(j, subFolders)
				number    = RemovePrefix(subFolder, start = "Device")
				device    = HW_ITC_BuildDeviceString(folder, number)
				path      = GetDevicePathAsString(device)

				if(DataFolderExists(path))
					DFREF dfr = $path
					NVAR/SDFR=dfr/Z deviceID, ITCDeviceIDGlobal

					if(NVAR_Exists(deviceID) || NVAR_Exists(ITCDeviceIDGlobal))
						list = AddListItem(device, list, ";", Inf)
					endif
				endif
			endfor
		else
			// other hardware has no subfolder
			device = folder
			path   = GetDevicePathAsString(device)

			if(DataFolderExists(path))
				DFREF dfr = $path
				NVAR/SDFR=dfr/Z deviceID, ITCDeviceIDGlobal

				if(NVAR_Exists(deviceID) || NVAR_Exists(ITCDeviceIDGlobal))
					list = AddListItem(device, list, ";", Inf)
				endif
			endif
		endif
	endfor

	return list
End

static Function DeviceHasUserComments(string device)

	string userCommentDraft, userCommentNB, userComment, commentNotebook

	userComment = ROStr(GetUserComment(device))

	if(WindowExists(device))
		userCommentDraft = DAG_GetTextualValue(device, "SetVar_DataAcq_Comment")

		commentNotebook = DAP_GetCommentNotebook(device)
		if(WindowExists(commentNotebook))
			userCommentNB = GetNotebookText(commentNotebook)
		else
			userCommentNB = ""
		endif
	else
		userCommentNB    = ""
		userCommentDraft = ""
	endif

	return !IsEmpty(userComment) || !IsEmpty(userCommentDraft) || !IsEmpty(userCommentNB)
End

/// @brief Returns a list of all devices, e.g. "ITC18USB_Dev_0;", which have content.
///
/// @param contentType [optional, defaults to CONTENT_TYPE_SWEEP] type of
///                    content to look for, one of @ref CONTENT_TYPES
Function/S GetAllDevicesWithContent([variable contentType])

	variable i, numDevices
	string deviceList, device, dataPath, testPulsePath
	string list = ""

	if(ParamIsDefault(contentType))
		contentType = CONTENT_TYPE_SWEEP
	endif

	deviceList = GetAllDevices()

	numDevices = ItemsInList(deviceList)
	for(i = 0; i < numDevices; i += 1)
		device        = StringFromList(i, deviceList)
		dataPath      = GetDeviceDataPathAsString(device)
		testPulsePath = GetDeviceTestPulseAsString(device)

		if((contentType & CONTENT_TYPE_SWEEP)               \
		   && DataFolderExists(dataPath)                    \
		   && CountObjects(dataPath, COUNTOBJECTS_WAVES) > 0)
			list = AddListItem(device, list, ";", Inf)
			continue
		endif

		if((contentType & CONTENT_TYPE_TPSTORAGE)                                 \
		   && DataFolderExists(testPulsePath)                                     \
		   && ItemsInList(GetListOfObjects($testPulsePath, TP_STORAGE_REGEXP)) > 0)
			list = AddListItem(device, list, ";", Inf)
			continue
		endif

		if((contentType & CONTENT_TYPE_COMMENT) \
		   && DeviceHasUserComments(device))
			list = AddListItem(device, list, ";", Inf)
			continue
		endif
	endfor

	return list
End

/// @brief Return the hardware type of the device
///
/// @return One of @ref HardwareDACTypeConstants
///
/// UTF_NOINSTRUMENTATION
threadsafe Function GetHardwareType(string device)

	string deviceType, deviceNumber
	ASSERT_TS(ParseDeviceString(device, deviceType, deviceNumber), "Error parsing device string!")

	if(WhichListItem(deviceType, DEVICE_TYPES_ITC) != -1)
		return HARDWARE_ITC_DAC
	endif

	if(IsEmpty(deviceNumber))
		if(IsDeviceNameFromSutter(deviceType))
			return HARDWARE_SUTTER_DAC
		endif

		return HARDWARE_NI_DAC
	endif

	return HARDWARE_UNSUPPORTED_DAC
End

threadsafe Function IsDeviceNameFromSutter(string device)

	return strsearch(device, DEVICE_SUTTER_NAME_START_CLEAN, 0) == 0 && strlen(device) >= 7
End

/// @brief Parse a device string:
/// for ITC devices of the form X_DEV_Y, where X is from @ref DEVICE_TYPES_ITC
/// and Y from @ref DEVICE_NUMBERS.
/// for NI devices of the form X, where X is from DAP_GetNIDeviceList()
/// for Sutter devices of the form IPA_E_Xxxxxx, where X must be present
///
/// Returns the result in deviceType and deviceNumber.
/// Currently the parsing is successfull if
/// for ITC devices X and Y are non-empty.
/// for NI devices X is non-empty.
/// for Sutter devices if the name starts with IPA_E_ and is at least 7 characters long
/// deviceNumber is empty for NI devices as it does not apply
/// @param[in]  device       input device string X_DEV_Y
/// @param[out] deviceType   returns the device type X
/// @param[out] deviceNumber returns the device number Y
/// @returns one on successfull parsing, zero on error
///
/// UTF_NOINSTRUMENTATION
threadsafe Function ParseDeviceString(string device, string &deviceType, string &deviceNumber)

	if(isEmpty(device))
		return 0
	endif

	if(IsDeviceNameFromSutter(device))
		deviceType   = device
		deviceNumber = ""
		return 1
	endif

	if(strsearch(device, "_Dev_", 0, 2) == -1)
		// NI device
		deviceType   = device
		deviceNumber = ""
		return !isEmpty(deviceType) && cmpstr(deviceType, "DA")
	endif

	// ITC device notation with X_Dev_Y
	deviceType   = StringFromList(0, device, "_")
	deviceNumber = StringFromList(2, device, "_")
	return !isEmpty(deviceType) && !isEmpty(deviceNumber) && cmpstr(deviceType, "DA")
End

/// @brief Return the list of unlocked `DA_Ephys` panels
Function/S GetListOfUnlockedDevices()

	return WinList("DA_Ephys*", ";", "WIN:64")
End

/// @brief Return the list of locked devices
Function/S GetListOfLockedDevices()

	SVAR list = $GetLockedDevices()
	return list
End

/// @brief Return the list of locked ITC1600 devices
Function/S GetListOfLockedITC1600Devices()

	return ListMatch(GetListOfLockedDevices(), "ITC1600*")
End

/// @brief Check that the device is of type ITC1600
Function IsITC1600(string device)

	string deviceType, deviceNumber
	variable ret

	ret = ParseDeviceString(device, deviceType, deviceNumber)
	ASSERT(ret, "Could not parse device")

	return !cmpstr(deviceType, "ITC1600")
End

/// @brief Check wether the given background task is running and that the
///        device is active in multi device mode.
Function IsDeviceActiveWithBGTask(string device, string task)

	if(!IsBackgroundTaskRunning(task))
		return 0
	endif

	strswitch(task)
		case TASKNAME_TPMD:
			WAVE deviceIDList = GetActiveDevicesTPMD()
			break
		case TASKNAME_TIMERMD:
			WAVE/Z/SDFR=GetActiveDAQDevicesTimerFolder() deviceIDList = ActiveDevTimeParam
			break
		case TASKNAME_FIFOMONMD:
			WAVE deviceIDList = GetDQMActiveDeviceList()
			break
		case TASKNAME_TP:
		case TASKNAME_TIMER:
		case TASKNAME_FIFOMON:
			// single device tasks, nothing more to do
			return 1
			break
		default:
			DEBUGPRINT("Querying unknown task: " + task)
			break
	endswitch

	if(!WaveExists(deviceIDList))
		DEBUGPRINT("Inconsistent state encountered in IsDeviceActiveWithBGTask")
		return 1
	endif

	NVAR deviceID = $GetDAQDeviceID(device)

	// running in multi device mode
	FindValue/V=(deviceID)/RMD=[][0] deviceIDList
	return V_Value != -1
End

/// @brief Return the next random number using the device specific RNG seed
Function GetNextRandomNumberForDevice(string device)

	NVAR rngSeed = $GetRNGSeed(device)
	ASSERT(IsFinite(rngSeed), "Invalid rngSeed")
	SetRandomSeed/BETR=1 rngSeed
	rngSeed += 1

	// scale to the available mantissa bits in a single precision variable
	return trunc(GetReproducibleRandom() * 2^23)
End
