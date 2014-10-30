#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//==================================================================================================
// ITC HARDWARE CONFIGURATION FUNCTIONS
// Hardware Set-up (HSU)

Function HSU_QueryITCDevice(panelTitle)
	string panelTitle

	variable DeviceType, DeviceNumber
	string cmd
	DeviceType   = HSU_GetDeviceTypeIndex(panelTitle)
	DeviceNumber = str2num(HSU_GetDeviceNumber(panelTitle))
	
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNumber
	Execute cmd
	//sprintf cmd, "ITCGetState /E=1 ResultWave"
	//Execute cmd
	DoAlert /t = "Ready light check"  0, "Click \"OK\" when finished checking device"
	
	sprintf cmd, "ITCCloseDevice" 
	execute cmd
End
//==================================================================================================

Function HSU_ButtonProc_Settings_OpenDev(s) : ButtonControl
	struct WMButtonAction& s

	if(s.eventCode != EVENT_MOUSE_UP)
		return 0
	endif

	HSU_QueryITCDevice(s.win)
End
//==================================================================================================

Function HSU_ButtonProc_LockDev(s) : ButtonControl
	struct WMButtonAction& s

	if(s.eventCode != EVENT_MOUSE_UP)
		return 0
	endif

	s.blockReentry = 1

	HSU_LockDevice(s.win)
	MCC_FindServers /Z = 1 // this is here to make sure the amp controls funciton, after a device is locked. /Z = 1 supresses errors
End
//==================================================================================================

Function HSU_LockDevice(panelTitle)
	string panelTitle

	string deviceType
	variable deviceNo
	string panelTitleLocked
	variable locked

	panelTitleLocked = BuildDeviceString(HSU_GetDeviceType(panelTitle), HSU_GetDeviceNumber(panelTitle))
	if(windowExists(panelTitleLocked))
		Abort "Attempt to duplicate device connection! Please choose another device number as that one is already in use."
	endif

	DisableListOfControls(panelTitle,"popup_MoreSettings_DeviceType;popup_moreSettings_DeviceNo;button_SettingsPlus_PingDevice")
	EnableControl(panelTitle,"button_SettingsPlus_unLockDevic")
	DisableControl(panelTitle,"button_SettingsPlus_LockDevice")

	DoWindow/W=$panelTitle/C $panelTitleLocked

	locked = 1
	HSU_UpdateDataFolderDisplay(panelTitleLocked, locked)

	IM_MakeGlobalsAndWaves(panelTitleLocked)
	HSU_UpdateListOfITCPanels()
	HSU_OpenITCDevice(panelTitleLocked)
	DAP_UpdateAllYokeControls()
	// create the amplifier settings waves
	GetAmplifierParamStorageWave(panelTitleLocked)
	WBP_UpdateITCPanelPopUps(panelTitleLocked)
End
//==================================================================================================

Function HSU_UpdateDataFolderDisplay(panelTitle, locked)
	string panelTitle
	variable locked

	string title
	if(locked)
		title = "Data folder path = " + HSU_DataFullFolderPathString(panelTitle)
	else
		title = "Lock a device to generate device folder structure"
	endif
	
	GroupBox group_Hardware_FolderPath win = $panelTitle, title = title
End
//==================================================================================================

Function HSU_CreateDataFolderForLockdDev(panelTitle)
	string panelTitle
	
	variable ret
	string deviceType, deviceNumber
	string path = HSU_DataFullFolderPathString(panelTitle)

	createDFWithAllParents(path + ":Data")
	createDFWithAllParents(path + ":TestPulse")

	GetDevSpecLabNBSettKeyFolder(panelTitle)
	GetDevSpecLabNBSettHistFolder(panelTitle)
	GetDevSpecLabNBTxtDocKeyFolder(panelTitle)
	GetDevSpecLabNBTextDocFolder(panelTitle)
End
//==================================================================================================

/// Returns the device type as string, readout from the popup menu in the Hardware tab
Function/s HSU_GetDeviceType(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_MoreSettings_DeviceType
	ASSERT(V_flag != 0, "Non-existing control or window")
	return S_value
End

/// Returns the device type as index into the popup menu in the Hardware tab
Function HSU_GetDeviceTypeIndex(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_MoreSettings_DeviceType
	ASSERT(V_flag != 0, "Non-existing control or window")
	return V_value - 1
End

Function/s HSU_GetDeviceNumber(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_moreSettings_DeviceNo
	ASSERT(V_flag != 0, "Non-existing control or window")
	return S_value
End

Function HSU_GetDeviceNumberIndex(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_moreSettings_DeviceNo
	ASSERT(V_flag != 0, "Non-existing control or window")
	return V_value - 1
End

//==================================================================================================

///@todo remove
Function/S HSU_DataFullFolderPathString(panelTitle)
	string panelTitle

	return GetDevicePathAsString(panelTitle)
End
//==================================================================================================

Function HSU_ButProc_Hrdwr_UnlckDev(s) : ButtonControl
	struct WMButtonAction& s

	if(s.eventCode != EVENT_MOUSE_UP)
		return 0
	endif

	s.blockReentry = 1

	HSU_UnlockDevice(s.win)
End
//==================================================================================================

Function HSU_UnlockDevice(panelTitle)
	string panelTitle

	if(DAP_DeviceIsLeader(panelTitle))
		DAP_RemoveALLYokedDACs(panelTitle)
	else
		DAP_RemoveYokedDAC(panelTitle)
	endif

	EnableListOfControls(panelTitle,"button_SettingsPlus_LockDevice;popup_MoreSettings_DeviceType;popup_moreSettings_DeviceNo;button_SettingsPlus_PingDevice")
	DisableControl(panelTitle,"button_SettingsPlus_unLockDevic")
	EnableListOfControls(panelTitle, "StartTestPulseButton;DataAcquireButton;Check_DataAcq1_RepeatAcq;Check_DataAcq_Indexing;SetVar_DataAcq_ITI;SetVar_DataAcq_SetRepeats;Check_Settings_Override_Set_ITI")
	SetVariable setvar_Hardware_Status Win = $panelTitle, value= _STR:"Independent"

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
	Execute cmd
	sprintf cmd, "ITCCloseDevice"
	Execute cmd

	DAP_UpdateYokeControls(panelTitleUnlocked)
	HSU_UpdateListOfITCPanels()
	DAP_UpdateAllYokeControls()
End
//==================================================================================================

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
//==================================================================================================

Function HSU_IsDeviceTypeConnected(panelTitle)
	string panelTitle
	string cmd
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	make  /O /I /N = 1 localwave
	sprintf cmd, "ITCGetDevices /Z=0 %d, localWave" DeviceType
	Execute cmd
	if(LocalWave[0] == 0)
		button button_SettingsPlus_PingDevice win = $panelTitle, disable = 2
	else
		button button_SettingsPlus_PingDevice win = $panelTitle, disable = 0
	endif
	print "Available number of specified ITC devices =", LocalWave[0]
	killwaves localwave
End
//==================================================================================================

// below functions are used to create a list of the ITC panels. This list is will be used by functions that need to update items that are common to different panels.
// for example: DAC popup lists, TTL popup lists

//==================================================================================================
Function HSU_UpdateListOfITCPanels()
	string/G root:MIES:ITCDevices:ITCPanelTitleList = winlist("ITC*", ";", "WIN:64")
End

//==================================================================================================
Function HSU_OpenITCDevice(panelTitle)
	String panelTitle
	variable DeviceType, DeviceNumber
	string cmd
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	DeviceType = v_value - 1
	controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
	DeviceNumber = v_value - 1
	Make /o  /I /U /N = 1 DevID = 50 // /FREE /I /U /N = 2 DevID = 50
	string DeviceID = "DevID"
	sprintf cmd, "ITCOpenDevice %d, %d, %s", DeviceType, DeviceNumber, DeviceID
	Execute cmd
	print "ITC Device ID = ",DevID[0], "is locked."
	//print "ITC Device ID = ",DevID[1], "is locked."
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	string ITCDeviceIDGlobal = WavePath + ":ITCDeviceIDGlobal"
	Variable /G $ITCDeviceIDGlobal = DevID[0]
End
//==================================================================================================

Function HSU_UpdateChanAmpAssignStorWv(panelTitle)
	string panelTitle

	Variable HeadStageNo, SweepNo, i, amplifierIdx
	Wave/Z/SDFR=GetAmplifierFolder() W_TelegraphServers
	Wave ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	Wave/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)

	HeadStageNo = str2num(GetPopupMenuString(panelTitle,"Popup_Settings_HeadStage"))

	Duplicate/free ChanAmpAssign ChanAmpAssignOrig

	// Assigns V-clamp settings for a particular headstage
	ControlInfo /w = $panelTitle Popup_Settings_VC_DA
	ChanAmpAssign[0][HeadStageNo] = str2num(s_value)
	ControlInfo /w = $panelTitle setvar_Settings_VC_DAgain
	ChanAmpAssign[1][HeadStageNo] = v_value
	ControlInfo /w = $panelTitle SetVar_Hardware_VC_DA_Unit	
	ChanAmpAssignUnit[0][HeadStageNo] = s_value
	ControlInfo /w = $panelTitle Popup_Settings_VC_AD
	ChanAmpAssign[2][HeadStageNo] = str2num(s_value)
	ControlInfo /w = $panelTitle setvar_Settings_VC_ADgain
	ChanAmpAssign[3][HeadStageNo] = v_value
	ControlInfo /w = $panelTitle SetVar_Hardware_VC_AD_Unit
	ChanAmpAssignUnit[1][HeadStageNo] = s_value
	
	//Assigns I-clamp settings for a particular headstage
	ControlInfo /w = $panelTitle Popup_Settings_IC_DA
	ChanAmpAssign[4][HeadStageNo] = str2num(s_value)
	ControlInfo /w = $panelTitle setvar_Settings_IC_DAgain
	ChanAmpAssign[5][HeadStageNo] = v_value
	ControlInfo /w = $panelTitle SetVar_Hardware_IC_DA_Unit	
	ChanAmpAssignUnit[2][HeadStageNo] = s_value
	ControlInfo /w = $panelTitle Popup_Settings_IC_AD
	ChanAmpAssign[6][HeadStageNo] = str2num(s_value)
	ControlInfo /w = $panelTitle setvar_Settings_IC_ADgain
	ChanAmpAssign[7][HeadStageNo] = v_value
	ControlInfo /w = $panelTitle SetVar_Hardware_IC_AD_Unit	
	ChanAmpAssignUnit[3][HeadStageNo] = s_value
	
	// Assigns amplifier to a particular headstage - sounds weird because this relationship is predetermined in hardware
	// but now you are telling the software what it is
	amplifierIdx = GetPopupMenuIndex(panelTitle, "popup_Settings_Amplifier")
	if(WaveExists(W_TelegraphServers) && amplifierIdx >= 1)
		ChanAmpAssign[8][HeadStageNo]  = W_TelegraphServers[amplifierIdx - 1][0] // serial number
		ChanAmpAssign[9][HeadStageNo]  = W_TelegraphServers[amplifierIdx - 1][1] // channel ID
		ChanAmpAssign[10][HeadStageNo] = amplifierIdx
	else
		ChanAmpAssign[8][HeadStageNo] = nan
		ChanAmpAssign[9][HeadStageNo] = nan
	endif

	//Duplicate ChanampAssign wave and add sweep number if the wave is changed
	controlinfo SetVar_Sweep
	SweepNo = v_value
	
	if(SweepNo > 0)
		ChanAmpAssignOrig -= ChanAmpAssign//used to see if settings have changed
		if((wavemax(ChanAmpAssignOrig)) != 0 || (wavemin(ChanAmpAssignOrig)) != 0)
			ED_MakeSettingsHistoryWave(panelTitle)
		endif
	endif
End
//==================================================================================================

Function HSU_UpdateChanAmpAssignPanel(panelTitle)
	string panelTitle

	Variable HeadStageNo
	Wave ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	Wave/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)

	HeadStageNo = str2num(GetPopupMenuString(panelTitle,"Popup_Settings_HeadStage"))
	
	// VC DA settings
	Popupmenu Popup_Settings_VC_DA win = $panelTitle, mode = (ChanAmpAssign[0][HeadStageNo] + 1)
	Setvariable setvar_Settings_VC_DAgain win = $panelTitle, value = _num:ChanAmpAssign[1][HeadStageNo]
	Setvariable SetVar_Hardware_VC_DA_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[0][HeadStageNo]
	// VC AD settings
	Popupmenu Popup_Settings_VC_AD win = $panelTitle, mode = (ChanAmpAssign[2][HeadStageNo] + 1)
	Setvariable setvar_Settings_VC_ADgain win = $panelTitle, value = _num:ChanAmpAssign[3][HeadStageNo]
	Setvariable SetVar_Hardware_VC_AD_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[1][HeadStageNo]
	// IC DA settings
	Popupmenu Popup_Settings_IC_DA win = $panelTitle, mode = (ChanAmpAssign[4][HeadStageNo] + 1)
	Setvariable setvar_Settings_IC_DAgain win = $panelTitle, value = _num:ChanAmpAssign[5][HeadStageNo]
	Setvariable SetVar_Hardware_IC_DA_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[2][HeadStageNo]
	// IC AD settings
	Popupmenu  Popup_Settings_IC_AD win = $panelTitle, mode = (ChanAmpAssign[6][HeadStageNo] + 1)
	Setvariable setvar_Settings_IC_ADgain win = $panelTitle, value = _num:ChanAmpAssign[7][HeadStageNo]
	Setvariable SetVar_Hardware_IC_AD_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[3][HeadStageNo]
	
	Popupmenu popup_Settings_Amplifier win = $panelTitle, mode = ChanAmpAssign[10][HeadStageNo]
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

//==================================================================================================
/// This function sets a ITC1600 device as a follower, ie. The internal clock is used to synchronize 2 or more PCI-1600
Function HSU_SetITCDACasFollower(leadDAC, followerDAC)
	string leadDAC, followerDAC

	string cmd
	string followerPath = HSU_DataFullFolderPathString(followerDAC)

	SVAR listOfFollowerDevices = $HSU_CreateITCFollowerList(leadDAC)
	NVAR FollowerITCDeviceIDGlobal = $(followerPath + ":ITCDeviceIDGlobal")
	
	if(WhichListItem(followerDAC, listOfFollowerDevices) == -1)
		listOfFollowerDevices = AddListItem(followerDAC, listOfFollowerDevices,";",inf)
		sprintf cmd, "ITCSelectDevice %d" FollowerITCDeviceIDGlobal
		Execute cmd
		Execute "ITCInitialize /M = 1"
		setvariable setvar_Hardware_YokeList Win = $leadDAC, value= _STR:listOfFollowerDevices, disable = 0
	endif
	// TB: what does this comment mean?
	// set the internal clock of the device
End

//==================================================================================================
// MULTICLAMP HARDWARE CONFIGURATION FUNCTION BELOW
//==================================================================================================

//==================================================================================================
// AUTO IMPORT GAIN SETTINGS FROM AXON AMP FUNCTIONS BELOW
//==================================================================================================
/// @brief Auto fills the units and gains in the hardware tab of the DA_Ephys panel - has some limitations that are due to the MCC API limitations
Function HSU_AutoFillGain(panelTitle)
	string panelTitle			

	// sets the units
	SetVariable SetVar_Hardware_VC_DA_Unit Win = $panelTitle, Value=_STR:"mV"
	SetVariable SetVar_Hardware_VC_AD_Unit Win = $panelTitle, Value=_STR:"pA"
	SetVariable SetVar_Hardware_IC_DA_Unit Win = $panelTitle, Value=_STR:"pA"
	SetVariable SetVar_Hardware_IC_AD_Unit Win = $panelTitle, Value=_STR:"mV"
	
	// get the headstage number being updated
	controlInfo /w = $panelTitle Popup_Settings_HeadStage
	variable HeadStageNo = v_value - 1

	string mccSerial    = AI_GetAmpMCCSerial(panelTitle, headStageNo)
	variable axonSerial = AI_GetAmpAxonSerial(panelTitle, headStageNo)
	variable channel    = AI_GetAmpChannel(panelTitle, headStageNo)

	MCC_SelectMultiClamp700B(mccSerial, channel)
	variable Mode = MCC_GetMode()
	
	variable ResetToModeTwo = 0
	
	if(Mode == V_CLAMP_MODE)
		SetVariable setvar_Settings_VC_DAgain Win = $panelTitle, Value=_NUM:AI_RetrieveDAGain(panelTitle, axonSerial, channel)
		SetVariable setvar_Settings_VC_ADgain Win = $panelTitle, Value=_NUM:AI_RetrieveADGain(panelTitle, axonSerial, channel)
	elseif(Mode == I_CLAMP_MODE)
		SetVariable setvar_Settings_IC_DAgain Win = $panelTitle, Value=_NUM:AI_RetrieveDAGain(panelTitle, axonSerial, channel)
		SetVariable setvar_Settings_IC_ADgain Win = $panelTitle, Value=_NUM:AI_RetrieveADGain(panelTitle, axonSerial, channel)
	elseif(Mode == I_EQUAL_ZERO_MODE)
		if(MCC_GetHoldingEnable() == 0) // checks to see if a holding current or bias current is being applied, if yes, the mode switch required to pull in the gains for all modes is prevented.
			MCC_SetMode(V_CLAMP_MODE)
			ResetToModeTwo = 1
			SetVariable setvar_Settings_IC_DAgain Win = $panelTitle, Value=_NUM:AI_RetrieveDAGain(panelTitle, axonSerial, channel)
			SetVariable setvar_Settings_IC_ADgain Win = $panelTitle, Value=_NUM:AI_RetrieveADGain(panelTitle, axonSerial, channel)
		elseif(MCC_GetHoldingEnable() == 1)
			print "It appears that a bias current or holding potential is being applied by the MC Commader suggesting that a recording is ongoing, therefore as a precaution, the gain settings cannot be imported"
		endif
	endif
	
	if(MCC_GetHoldingEnable() == 0) // checks to see if a holding current or bias current is being applied, if yes, the mode switch required to pull in the gains for all modes is prevented.
		AI_SwitchAxonAmpMode(panelTitle, mccSerial, channel)
	
		Mode = MCC_GetMode()
		 
		 if(Mode == V_CLAMP_MODE)
			SetVariable setvar_Settings_VC_DAgain Win = $panelTitle, Value=_NUM:AI_RetrieveDAGain(panelTitle, axonSerial, channel)
			SetVariable setvar_Settings_VC_ADgain Win = $panelTitle, Value=_NUM:AI_RetrieveADGain(panelTitle, axonSerial, channel)
		elseif(Mode == I_CLAMP_MODE)
			SetVariable setvar_Settings_IC_DAgain Win = $panelTitle, Value=_NUM:AI_RetrieveDAGain(panelTitle, axonSerial, channel)
			SetVariable setvar_Settings_IC_ADgain Win = $panelTitle, Value=_NUM:AI_RetrieveADGain(panelTitle, axonSerial, channel)
		endif
		
		if(ResetToModeTwo == 0)
			AI_SwitchAxonAmpMode(panelTitle, mccSerial, channel)
		elseif(ResetToModeTwo == 1)
			MCC_SetMode(I_EQUAL_ZERO_MODE)
		endif
	elseif((MCC_GetHoldingEnable() == 1))
		if(Mode == V_CLAMP_MODE)
			print "It appears that a holding potential is being applied, therefore as a precaution, the gains cannot be imported for the I-clamp mode."
			print "The gains were successfully imported for the V-clamp mode on headstage: ", HeadstageNo
		elseif(Mode == I_CLAMP_MODE)
			print "It appears that a bias current is being applied, therefore as a precaution, the gains cannot be imported for the V-clamp mode."
			print "The gains were successfully imported for the I-clamp mode on headstage: ", HeadstageNo
		endif
	endif

End

//==================================================================================================
// 
//==================================================================================================
