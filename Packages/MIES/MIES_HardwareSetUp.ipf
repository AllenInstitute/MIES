#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

/// @file MIES_HardwareSetUp.ipf
/// @brief __HSU__ ITC Hardware Configuration Functions

Function HSU_ButtonProc_Settings_OpenDev(ba) : ButtonControl
	struct WMButtonAction& ba

	string panelTitle, deviceToOpen
	variable hwType, deviceID

	switch(ba.eventCode)
		case 2: // mouse up
			deviceToOpen = BuildDeviceString(HSU_GetDeviceType(ba.win), HSU_GetDeviceNumber(ba.win))
			deviceID = HW_OpenDevice(deviceToOpen, hwType)
			DoAlert/T="Ready light check" 0, "Click \"OK\" when finished checking device"
			HW_CloseDevice(hwType, deviceID)
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

	variable locked, hardwareType, headstage
	string panelTitleLocked

	SVAR miesVersion = $GetMiesVersion()

	if(!cmpstr(miesVersion, UNKNOWN_MIES_VERSION))
		DEBUGPRINT_OR_ABORT("The MIES version is unknown, locking devices is therefore only allowed in debug mode.")
	endif

	panelTitleLocked = BuildDeviceString(HSU_GetDeviceType(panelTitle), HSU_GetDeviceNumber(panelTitle))
	if(windowExists(panelTitleLocked))
		Abort "Attempt to duplicate device connection! Please choose another device number as that one is already in use."
	endif

	if(!HasPanelLatestVersion(panelTitle, DA_EPHYS_PANEL_VERSION))
		Abort "Can not lock the device. The DA_Ephys panel is too old to be usable. Please close it and open a new one."
	endif

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(paneltitleLocked)
	ITCDeviceIDGlobal = HW_OpenDevice(paneltitleLocked, hardwareType)

	if(ITCDeviceIDGlobal < 0 || ITCDeviceIDGlobal >= HARDWARE_MAX_DEVICES)
#ifndef EVIL_KITTEN_EATING_MODE
		Abort "Can not lock the device."
#else
		print "EVIL_KITTEN_EATING_MODE is ON: Forcing ITCDeviceIDGlobal to zero"
		ITCDeviceIDGlobal = 0
#endif
	endif

	DisableControls(panelTitle,"popup_MoreSettings_DeviceType;popup_moreSettings_DeviceNo;button_SettingsPlus_PingDevice")
	EnableControl(panelTitle,"button_SettingsPlus_unLockDevic")
	DisableControl(panelTitle,"button_SettingsPlus_LockDevice")

	DoWindow/W=$panelTitle/C $panelTitleLocked

	locked = 1
	HSU_UpdateDataFolderDisplay(panelTitleLocked, locked)

	AI_FindConnectedAmps()
	HSU_UpdateListOfITCPanels()
	DAP_UpdateListOfPressureDevices()
	headstage = str2num(GetPopupMenuString(panelTitleLocked, "Popup_Settings_HeadStage"))
	DAP_SyncDeviceAssocSettToGUI(paneltitleLocked, headstage)

	DAP_UpdateAllYokeControls()
	// create the amplifier settings waves
	GetAmplifierParamStorageWave(panelTitleLocked)
	WBP_UpdateITCPanelPopUps(panelTitle=panelTitleLocked)
	DAP_UnlockCommentNotebook(panelTitleLocked)
	DAP_ToggleAcquisitionButton(panelTitleLocked, DATA_ACQ_BUTTON_TO_DAQ)
	SI_CalculateMinSampInterval(panelTitleLocked, DATA_ACQUISITION_MODE)
	DAP_RecordDA_EphysGuiState(panelTitleLocked)

	headstage = GetSliderPositionIndex(panelTitleLocked, "slider_DataAcq_ActiveHeadstage")
	P_SaveUserSelectedHeadstage(panelTitleLocked, headstage)

	// upgrade all four labnotebook waves in wanna-be atomic way
	GetLBNumericalKeys(panelTitleLocked)
	GetLBNumericalValues(panelTitleLocked)
	GetLBTextualKeys(panelTitleLocked)
	GetLBTextualValues(panelTitleLocked)

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

	variable flags

	if(!windowExists(panelTitle))
		DEBUGPRINT("Can not unlock the non-existing panel", str=panelTitle)
		return NaN
	endif

	DAP_SerializeCommentNotebook(panelTitle)
	DAP_LockCommentNotebook(panelTitle)
	P_Disable() // Closes DACs used for pressure regulation
	if(DeviceHasFollower(panelTitle))
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
	flags = HARDWARE_PREVENT_ERROR_POPUP | HARDWARE_PREVENT_ERROR_MESSAGE
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=flags)
	HW_CloseDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=flags)
	HW_DeRegisterDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=flags)

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
		WAVE/Z/SDFR=dfr ActiveDeviceList
		HSU_ClearWaveIfExists(ActiveDeviceList)

		DFREF dfr = GetActiveITCDevicesFolder()
		WAVE/Z/SDFR=dfr ActiveDeviceList
		HSU_ClearWaveIfExists(ActiveDeviceList)

		DFREF dfr = GetActiveITCDevicesTimerFolder()
		WAVE/Z/SDFR=dfr ActiveDevTimeParam, TimerFunctionListWave
		HSU_ClearWaveIfExists(ActiveDevTimeParam)
		HSU_ClearWaveIfExists(TimerFunctionListWave)

		SVAR listOfFollowers = $GetFollowerList(ITC1600_FIRST_DEVICE)
		listOfFollowers = ""

		KillOrMoveToTrash(wv = GetDeviceMapping())
	endif
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
	ChanAmpAssignUnit[%VC_DAUnit][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_VC_DA_Unit")
	ChanAmpAssign[%VC_AD][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_VC_AD"))
	ChanAmpAssign[%VC_ADGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_VC_ADgain")
	ChanAmpAssignUnit[%VC_ADUnit][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_VC_AD_Unit")

	//Assigns I-clamp settings for a particular headstage
	ChanAmpAssign[%IC_DA][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_IC_DA"))
	ChanAmpAssign[%IC_DAGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_IC_DAgain")
	ChanAmpAssignUnit[%IC_DAUnit][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_IC_DA_Unit")
	ChanAmpAssign[%IC_AD][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_IC_AD"))
	ChanAmpAssign[%IC_ADGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_IC_ADgain")
	ChanAmpAssignUnit[%IC_ADUnit][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_IC_AD_Unit")

	// Assigns amplifier to a particular headstage
	// sounds weird because this relationship is predetermined in hardware
	// but now you are telling the software what it is
	amplifierDef = GetPopupMenuString(panelTitle, "popup_Settings_Amplifier")
	DAP_ParseAmplifierDef(amplifierDef, ampSerial, ampChannelID)

	if(IsFinite(ampSerial) && IsFinite(ampChannelID))
		ChanAmpAssign[%AmpSerialNo][HeadStageNo]  = ampSerial
		ChanAmpAssign[%AmpChannelID][HeadStageNo] = ampChannelID
	else
		ChanAmpAssign[%AmpSerialNo][HeadStageNo]  = nan
		ChanAmpAssign[%AmpChannelID][HeadStageNo] = nan
	endif
End

Function HSU_UpdateChanAmpAssignPanel(panelTitle)
	string panelTitle

	variable HeadStageNo, channel, ampSerial, ampChannelID
	string entry

	Wave ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	Wave/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)

	HeadStageNo = str2num(GetPopupMenuString(panelTitle,"Popup_Settings_HeadStage"))

	// VC DA settings
	channel = ChanAmpAssign[%VC_DA][HeadStageNo]
	Popupmenu Popup_Settings_VC_DA win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_VC_DAgain win = $panelTitle, value = _num:ChanAmpAssign[%VC_DAGain][HeadStageNo]
	Setvariable SetVar_Hardware_VC_DA_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[%VC_DAUnit][HeadStageNo]

	// VC AD settings
	channel = ChanAmpAssign[%VC_AD][HeadStageNo]
	Popupmenu Popup_Settings_VC_AD win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_VC_ADgain win = $panelTitle, value = _num:ChanAmpAssign[%VC_ADGain][HeadStageNo]
	Setvariable SetVar_Hardware_VC_AD_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[%VC_ADUnit][HeadStageNo]

	// IC DA settings
	channel = ChanAmpAssign[%IC_DA][HeadStageNo]
	Popupmenu Popup_Settings_IC_DA win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_IC_DAgain win = $panelTitle, value = _num:ChanAmpAssign[%IC_DAGain][HeadStageNo]
	Setvariable SetVar_Hardware_IC_DA_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[%IC_DAUnit][HeadStageNo]

	// IC AD settings
	channel = ChanAmpAssign[%IC_AD][HeadStageNo]
	Popupmenu  Popup_Settings_IC_AD win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_IC_ADgain win = $panelTitle, value = _num:ChanAmpAssign[%IC_ADGain][HeadStageNo]
	Setvariable SetVar_Hardware_IC_AD_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[%IC_ADUnit][HeadStageNo]

	if(cmpstr(DAP_GetNiceAmplifierChannelList(), NONE))
		ampSerial    = ChanAmpAssign[%AmpSerialNo][HeadStageNo]
		ampChannelID = ChanAmpAssign[%AmpChannelID][HeadStageNo]
		if(isFinite(ampSerial) && isFinite(ampChannelID))
			entry = DAP_GetAmplifierDef(ampSerial, ampChannelID)
			Popupmenu popup_Settings_Amplifier win = $panelTitle, popmatch=entry
		else
			Popupmenu popup_Settings_Amplifier win = $panelTitle, popmatch=NONE
		endif
	endif
End

/// This function sets a ITC1600 device as a follower, ie. The internal clock is used to synchronize 2 or more PCI-1600
Function HSU_SetITCDACasFollower(leadDAC, followerDAC)
	string leadDAC, followerDAC

	SVAR listOfFollowerDevices = $GetFollowerList(leadDAC)
	NVAR followerITCDeviceIDGlobal = $GetITCDeviceIDGlobal(followerDAC)
	
	if(WhichListItem(followerDAC, listOfFollowerDevices) == -1)
		listOfFollowerDevices = AddListItem(followerDAC, listOfFollowerDevices,";",inf)
		HW_SelectDevice(HARDWARE_ITC_DAC, followerITCDeviceIDGlobal)
		HW_EnableYoking(HARDWARE_ITC_DAC, followerITCDeviceIDGlobal)
		setvariable setvar_Hardware_YokeList Win = $leadDAC, value= _STR:listOfFollowerDevices, disable = 0
	endif
	// TB: what does this comment mean?
	// set the internal clock of the device
End
