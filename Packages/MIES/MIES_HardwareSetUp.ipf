#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_HardwareSetUp.ipf
/// @brief __HSU__ ITC Hardware Configuration Functions

Function HSU_QueryITCDevice(panelTitle)
	string panelTitle

	variable DeviceType, DeviceNumber
	string cmd
	DeviceType   = HSU_GetDeviceTypeIndex(panelTitle)
	DeviceNumber = str2num(HSU_GetDeviceNumber(panelTitle))
	
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNumber
	ExecuteITCOperation(cmd)
	DoAlert /t = "Ready light check"  0, "Click \"OK\" when finished checking device"

	sprintf cmd, "ITCCloseDevice"
	ExecuteITCOperation(cmd)
End

Function HSU_ButtonProc_Settings_OpenDev(ba) : ButtonControl
	struct WMButtonAction& ba

	switch(ba.eventCode)
		case 2: // mouse up
			HSU_QueryITCDevice(ba.win)
			break
	endswitch

	return 0
End

Function HSU_ButtonProc_LockDev(ba) : ButtonControl
	struct WMButtonAction& ba

	switch(ba.eventCode)
		case 2: // mouse up
			ba.blockReentry = 1
			HSU_LockDevice(ba.win)
			break
	endswitch

	return 0
End

Function HSU_LockDevice(panelTitle)
	string panelTitle

	string deviceType
	variable deviceNo
	string panelTitleLocked
	variable locked

	SVAR miesVersion = $GetMiesVersion()

	if(!cmpstr(miesVersion, UNKNOWN_MIES_VERSION))
		DEBUGPRINT_OR_ABORT("The MIES version is unknown, locking devices is therefore only allowed in debug mode.")
	endif

	panelTitleLocked = BuildDeviceString(HSU_GetDeviceType(panelTitle), HSU_GetDeviceNumber(panelTitle))
	if(windowExists(panelTitleLocked))
		Abort "Attempt to duplicate device connection! Please choose another device number as that one is already in use."
	endif

	if(!DAP_PanelIsUpToDate(panelTitle))
		Abort "Can not lock the device. The DA_Ephys panel is too old to be usable. Please close it and open a new one."
	endif

	DisableControls(panelTitle,"popup_MoreSettings_DeviceType;popup_moreSettings_DeviceNo;button_SettingsPlus_PingDevice")
	EnableControl(panelTitle,"button_SettingsPlus_unLockDevic")
	DisableControl(panelTitle,"button_SettingsPlus_LockDevice")

	DoWindow/W=$panelTitle/C $panelTitleLocked

	locked = 1
	HSU_UpdateDataFolderDisplay(panelTitleLocked, locked)

	HSU_UpdateChanAmpAssignStorWv(panelTitleLocked)
	AI_FindConnectedAmps()
	HSU_UpdateListOfITCPanels()
	HSU_OpenITCDevice(panelTitleLocked)
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	DAP_UpdateListOfPressureDevices()
	HSU_UpdateChanAmpAssignPanel(panelTitleLocked)

	DAP_UpdateAllYokeControls()
	// create the amplifier settings waves
	GetAmplifierParamStorageWave(panelTitleLocked)
	WBP_UpdateITCPanelPopUps(panelTitle=panelTitleLocked)
	DAP_UnlockCommentNotebook(panelTitleLocked)
	DAP_ToggleAcquisitionButton(panelTitleLocked, DATA_ACQ_BUTTON_TO_DAQ)
	SI_CalculateMinSampInterval(panelTitleLocked, DATA_ACQUISITION_MODE)
	DAP_RecordDA_EphysGuiState(panelTitleLocked)

	NVAR sessionStartTime = $GetSessionStartTime()
	sessionStartTime = DateTimeInUTC()

	DAP_UpdateOnsetDelay(panelTitleLocked)

	HW_RegisterDevice(panelTitleLocked, HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
End

Function HSU_UpdateDataFolderDisplay(panelTitle, locked)
	string panelTitle
	variable locked

	string title
	if(locked)
		title = "Data folder path = " + GetDevicePathAsString(panelTitle)
	else
		title = "Lock a device to generate device folder structure"
	endif
	
	GroupBox group_Hardware_FolderPath win = $panelTitle, title = title
End

/// @brief Returns the device type as string, readout from the popup menu in the Hardware tab
Function/s HSU_GetDeviceType(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_MoreSettings_DeviceType
	ASSERT(V_flag != 0, "Non-existing control or window")
	return S_value
End

/// @brief Returns the device type as index into the popup menu in the Hardware tab
static Function HSU_GetDeviceTypeIndex(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_MoreSettings_DeviceType
	ASSERT(V_flag != 0, "Non-existing control or window")
	return V_value - 1
End

/// @brief Returns the selected ITC device number from a DA_Ephys panel (locked or unlocked)
static Function/s HSU_GetDeviceNumber(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_moreSettings_DeviceNo
	ASSERT(V_flag != 0, "Non-existing control or window")
	return S_value
End

Function HSU_ButProc_Hrdwr_UnlckDev(ba) : ButtonControl
	struct WMButtonAction& ba

	switch(ba.eventCode)
		case 2: // mouse up
			ba.blockReentry = 1
			HSU_UnlockDevice(ba.win)
			break
	endswitch

	return 0
End

static Function HSU_ClearWaveIfExists(wv)
	WAVE/Z wv

	if(WaveExists(wv))
		Redimension/N=(0, -1, -1, -1) wv
	endif
End

Function HSU_UnlockDevice(panelTitle)
	string panelTitle

	if(!windowExists(panelTitle))
		DEBUGPRINT("Can not unlock the non-existing panel", str=panelTitle)
		return NaN
	endif

	DAP_SerializeCommentNotebook(panelTitle)
	DAP_LockCommentNotebook(panelTitle)
	P_Disable() // Closes DACs used for pressure regulation
	if(DAP_DeviceIsLeader(panelTitle))
		DAP_RemoveALLYokedDACs(panelTitle)
	else
		DAP_RemoveYokedDAC(panelTitle)
	endif

	EnableControls(panelTitle,"button_SettingsPlus_LockDevice;popup_MoreSettings_DeviceType;popup_moreSettings_DeviceNo;button_SettingsPlus_PingDevice")
	DisableControl(panelTitle,"button_SettingsPlus_unLockDevic")
	EnableControls(panelTitle, "StartTestPulseButton;DataAcquireButton;Check_DataAcq1_RepeatAcq;Check_DataAcq_Indexing;SetVar_DataAcq_ITI;SetVar_DataAcq_SetRepeats;Check_DataAcq_Get_Set_ITI")
	SetVariable setvar_Hardware_Status Win = $panelTitle, value= _STR:"Independent"
	DAP_ResetGUIAfterDAQ(panelTitle)
	DAP_ToggleTestpulseButton(panelTitle, TESTPULSE_BUTTON_TO_START)

	string panelTitleUnlocked = BASE_WINDOW_TITLE
	if(CheckName(panelTitleUnlocked,CONTROL_PANEL_TYPE))
		panelTitleUnlocked = UniqueName(BASE_WINDOW_TITLE + "_",CONTROL_PANEL_TYPE,1)
	endif
	DoWindow/W=$panelTitle/C $panelTitleUnlocked

	variable locked = 0
	HSU_UpdateDataFolderDisplay(panelTitleUnlocked,locked)

	NVAR/SDFR=GetDevicePath(panelTitle) ITCDeviceIDGlobal
	string cmd
	sprintf cmd, "ITCSelectDevice/Z %d" ITCDeviceIDGlobal
	ExecuteITCOperation(cmd)
	sprintf cmd, "ITCCloseDevice"
	ExecuteITCOperation(cmd)
	HW_DeRegisterDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

	DAP_UpdateYokeControls(panelTitleUnlocked)
	HSU_UpdateListOfITCPanels()
	DAP_UpdateAllYokeControls()

	// reset our state variables to safe defaults
	NVAR dataAcqState = $GetDataAcqState(panelTitle)
	dataAcqState = 0
	NVAR count = $GetCount(panelTitle)
	count = NaN
	NVAR runMode = $GetTestpulseRunMode(panelTitle)
	runMode = TEST_PULSE_NOT_RUNNING

	SVAR/SDFR=GetITCDevicesFolder() ITCPanelTitleList
	if(!cmpstr(ITCPanelTitleList, ""))
		CloseNWBFile()

		DFREF dfr = GetActITCDevicesTestPulseFolder()
		WAVE/Z/SDFR=dfr ActiveDeviceList, ActiveDeviceTextList, ActiveDevWavePathWave
		HSU_ClearWaveIfExists(ActiveDeviceList)
		HSU_ClearWaveIfExists(ActiveDeviceTextList)
		HSU_ClearWaveIfExists(ActiveDevWavePathWave)

		DFREF dfr = GetActiveITCDevicesFolder()
		WAVE/Z/SDFR=dfr ActiveDeviceList, ActiveDeviceTextList, ActiveDevWavePathWave
		HSU_ClearWaveIfExists(ActiveDeviceList)
		HSU_ClearWaveIfExists(ActiveDeviceTextList)
		HSU_ClearWaveIfExists(ActiveDevWavePathWave)

		DFREF dfr = GetActiveITCDevicesTimerFolder()
		WAVE/Z/SDFR=dfr ActiveDevTimeParam, TimerFunctionListWave
		HSU_ClearWaveIfExists(ActiveDevTimeParam)
		HSU_ClearWaveIfExists(TimerFunctionListWave)

		SVAR/Z listOfFollowers = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowers))
			listOfFollowers = ""
		endif

		KillOrMoveToTrash(wv = GetDeviceMapping())
	endif
End

/// @brief Query the device lock status
/// @param   panelTitle name of the device panel
/// @param   silentCheck (optional) Alert the user if it is not locked, 0 (default) means yes, everything else no
/// @returns device lock status, 1 if unlocked, 0 if locked
Function HSU_DeviceIsUnlocked(panelTitle, [silentCheck])
	string panelTitle
	variable silentCheck

	variable parseable
	variable validDeviceType
	variable validDeviceNumber
	string deviceType, deviceNumber

    if(ParamIsDefault(silentCheck))
        silentCheck = 0
    endif

    parseable = ParseDeviceString(panelTitle, deviceType, deviceNumber)
    if(parseable)
		validDeviceType   = ( WhichListItem(deviceType, DEVICE_TYPES)     != -1 )
		validDeviceNumber = ( WhichListItem(deviceNumber, DEVICE_NUMBERS) != -1 )
    else
		validDeviceType   = 0
		validDeviceNumber = 0
	endif

	if(parseable && validDeviceType && validDeviceNumber)
		return 0
	endif

    if(!silentCheck)
	    DoAlert /t = "Hardware Status"  0, "A ITC device must be locked (see Hardware tab) to proceed"
	endif

	return 1
End

Function HSU_IsDeviceTypeConnected(panelTitle)
	string panelTitle

	variable numDevices

	numDevices = ItemsInList(ListMatch(HW_ITC_ListDevices(), HSU_GetDeviceType(panelTitle) + "_DEV_*"))

	if(!numDevices)
		DisableControl(panelTitle, "button_SettingsPlus_PingDevice")
	else
		EnableControl(panelTitle, "button_SettingsPlus_PingDevice")
	endif

	printf "Available number of specified ITC devices = %d\r" numDevices
End

/// @brief Update the list of locked devices
Function HSU_UpdateListOfITCPanels()
	DFREF dfr = GetITCDevicesFolder()
	string/G dfr:ITCPanelTitleList = WinList("ITC*", ";", "WIN:64")
End

Function HSU_OpenITCDevice(panelTitle)
	String panelTitle

	variable deviceType, deviceNumber
	string cmd

	deviceType = HSU_GetDeviceTypeIndex(panelTitle)
	deviceNumber = str2num(HSU_GetDeviceNumber(panelTitle))

	Make/O/I/U/N=1 DevID = 50
	sprintf cmd, "ITCOpenDevice %d, %d, DevID", deviceType, deviceNumber
	ExecuteITCOperation(cmd)

	print "ITC Device ID = ",DevID[0], "is locked."
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	ITCDeviceIDGlobal = DevID[0]

	KillOrMoveToTrash(wv=DevID)
End

Function HSU_UpdateChanAmpAssignStorWv(panelTitle)
	string panelTitle

	variable HeadStageNo, ampSerial, ampChannelID
	string amplifierDef
	Wave ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	Wave/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)

	HeadStageNo = str2num(GetPopupMenuString(panelTitle,"Popup_Settings_HeadStage"))

	// Assigns V-clamp settings for a particular headstage
	ChanAmpAssign[%VC_DA][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_VC_DA"))
	ChanAmpAssign[%VC_DAGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_VC_DAgain")
	ChanAmpAssignUnit[0][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_VC_DA_Unit")
	ChanAmpAssign[%VC_AD][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_VC_AD"))
	ChanAmpAssign[%VC_ADGain][HeadStageNo]  = GetSetVariable(panelTitle, "setvar_Settings_VC_ADgain")
	ChanAmpAssignUnit[1][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_VC_AD_Unit")
	
	//Assigns I-clamp settings for a particular headstage
	ChanAmpAssign[%IC_DA][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_IC_DA"))
	ChanAmpAssign[%IC_DAGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_IC_DAgain")
	ChanAmpAssignUnit[2][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_IC_DA_Unit")
	ChanAmpAssign[%IC_AD][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_IC_AD"))
	ChanAmpAssign[%IC_ADGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_IC_ADgain")
	ChanAmpAssignUnit[3][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_IC_AD_Unit")

	// Assigns amplifier to a particular headstage
	// sounds weird because this relationship is predetermined in hardware
	// but now you are telling the software what it is
	amplifierDef = GetPopupMenuString(panelTitle, "popup_Settings_Amplifier")
	DAP_ParseAmplifierDef(amplifierDef, ampSerial, ampChannelID)

	WAVE telegraphServers = GetAmplifierTelegraphServers()
	if(DimSize(telegraphServers, ROWS) > 0 && IsFinite(ampSerial) && IsFinite(ampChannelID))
		ChanAmpAssign[%AmpSerialNo][HeadStageNo]  = ampSerial
		ChanAmpAssign[%AmpChannelID][HeadStageNo] = ampChannelID
	else
		ChanAmpAssign[%AmpSerialNo][HeadStageNo]  = nan
		ChanAmpAssign[%AmpChannelID][HeadStageNo] = nan
	endif
End

Function HSU_UpdateChanAmpAssignPanel(panelTitle)
	string panelTitle

	variable HeadStageNo, channel
	string entry

	Wave ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	Wave/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)

	HeadStageNo = str2num(GetPopupMenuString(panelTitle,"Popup_Settings_HeadStage"))

	// VC DA settings
	channel = ChanAmpAssign[0][HeadStageNo]
	Popupmenu Popup_Settings_VC_DA win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_VC_DAgain win = $panelTitle, value = _num:ChanAmpAssign[1][HeadStageNo]
	Setvariable SetVar_Hardware_VC_DA_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[0][HeadStageNo]

	// VC AD settings
	channel = ChanAmpAssign[2][HeadStageNo]
	Popupmenu Popup_Settings_VC_AD win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_VC_ADgain win = $panelTitle, value = _num:ChanAmpAssign[3][HeadStageNo]
	Setvariable SetVar_Hardware_VC_AD_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[1][HeadStageNo]

	// IC DA settings
	channel = ChanAmpAssign[4][HeadStageNo]
	Popupmenu Popup_Settings_IC_DA win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_IC_DAgain win = $panelTitle, value = _num:ChanAmpAssign[5][HeadStageNo]
	Setvariable SetVar_Hardware_IC_DA_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[2][HeadStageNo]

	// IC AD settings
	channel = ChanAmpAssign[6][HeadStageNo]
	Popupmenu  Popup_Settings_IC_AD win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_IC_ADgain win = $panelTitle, value = _num:ChanAmpAssign[7][HeadStageNo]
	Setvariable SetVar_Hardware_IC_AD_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[3][HeadStageNo]

	if(cmpstr(DAP_GetNiceAmplifierChannelList(), NONE))
		entry = DAP_GetAmplifierDef(ChanAmpAssign[%AmpSerialNo][HeadStageNo], ChanAmpAssign[%AmpChannelID][HeadStageNo])
		Popupmenu popup_Settings_Amplifier win = $panelTitle, popmatch=entry
	endif
End

/// Create, if it does not exist, the global variable ListOfFollowerITC1600s storing the ITC follower list
/// @todo merge with GetFollowerList once the doNotCreateSVAR-hack is removed
static Function/S HSU_CreateITCFollowerList(panelTitle)
	string panelTitle

	// ensure that the device folder exists
	dfref dfr = GetDevicePath(panelTitle)
	SVAR/Z/SDFR=dfr list = ListOfFollowerITC1600s
	if(!SVAR_Exists(list))
		string/G dfr:ListOfFollowerITC1600s = ""
	endif

	// now we can return the absolute path to the SVAR
	// as we know it exists
	return GetFollowerList(doNotCreateSVAR=1)
End

/// This function sets a ITC1600 device as a follower, ie. The internal clock is used to synchronize 2 or more PCI-1600
Function HSU_SetITCDACasFollower(leadDAC, followerDAC)
	string leadDAC, followerDAC

	string cmd

	SVAR listOfFollowerDevices = $HSU_CreateITCFollowerList(leadDAC)
	NVAR followerITCDeviceIDGlobal = $GetITCDeviceIDGlobal(followerDAC)
	
	if(WhichListItem(followerDAC, listOfFollowerDevices) == -1)
		listOfFollowerDevices = AddListItem(followerDAC, listOfFollowerDevices,";",inf)
		sprintf cmd, "ITCSelectDevice %d" followerITCDeviceIDGlobal
		ExecuteITCOperation(cmd)
		sprintf cmd, "ITCInitialize /M = 1"
		ExecuteITCOperation(cmd)
		setvariable setvar_Hardware_YokeList Win = $leadDAC, value= _STR:listOfFollowerDevices, disable = 0
	endif
	// TB: what does this comment mean?
	// set the internal clock of the device
End

End

/// @brief Try to select the ITC device
/// @return 0 if sucessfull, 1 on error
Function HSU_CanSelectDevice(panelTitle)
	string panelTitle

	string cmd

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	sprintf cmd, "ITCSelectDevice/Z %d", ITCDeviceIDGlobal
	return ExecuteITCOperation(cmd)
End
