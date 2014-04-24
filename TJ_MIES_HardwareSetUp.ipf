#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//==================================================================================================
// ITC HARDWARE CONFIGURATION FUNCTIONS
// Hardware Set-up (HSU)
Function HSU_QueryITCDevice(PanelTitle)
	string PanelTitle
	variable DeviceType, DeviceNumber
	string cmd
	controlinfo /w = $PanelTitle popup_MoreSettings_DeviceType
	DeviceType = v_value - 1
	controlinfo /w = $PanelTitle popup_moreSettings_DeviceNo
	DeviceNumber = v_value - 1
	
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNumber
	Execute cmd
	//sprintf cmd, "ITCGetState /E=1 ResultWave"
	//Execute cmd
	DoAlert /t = "Ready light check"  0, "Click \"OK\" when finished checking device"
	
	sprintf cmd, "ITCCloseDevice" 
	execute cmd
End
//==================================================================================================

Function HSU_ButtonProc_Settings_OpenDev(ctrlName) : ButtonControl
	String ctrlName
	getwindow kwTopWin wtitle
	HSU_QueryITCDevice(s_value)
End
//==================================================================================================

Function HSU_ButtonProc_LockDev(ctrlName) : ButtonControl
	String ctrlName
	getwindow kwTopWin wtitle
	HSU_LockDevice(s_value)
End
//==================================================================================================

Function HSU_LockDevice(panelTitle)
	string PanelTitle
	string deviceType
	variable deviceNo
	PopupMenu popup_MoreSettings_DeviceType win = $PanelTitle, disable = 2
	PopupMenu popup_moreSettings_DeviceNo win = $PanelTitle, disable = 2
	Button button_SettingsPlus_LockDevice win = $PanelTitle, disable = 2
	Button button_SettingsPlus_PingDevice win = $panelTitle, disable = 2
	HSU_DataFolderPathDisplay(PanelTitle, 1)
	HSU_CreateDataFolderForLockdDev(PanelTitle)
	Button button_SettingsPlus_unLockDevic win = $PanelTitle, disable = 0
	controlinfo /W = $panelTitle popup_MoreSettings_DeviceType
	deviceType = s_value
	controlinfo /W = $panelTitle popup_moreSettings_DeviceNo
	deviceNo = v_value - 1
	dowindow /W = $panelTitle /C $DeviceType + "_Dev_" + num2str(DeviceNo)
	PanelTitle = DeviceType + "_Dev_" + num2str(DeviceNo)
	IM_MakeGlobalsAndWaves(PanelTitle)
	HSU_GlblListStrngOfITCPanlTitls()//checks to see if list string of panel titles exists, if it doesn't in creates it (in the root: folder)
	HSU_ListOfITCPanels()
	HSU_OpenITCDevice(panelTitle)
	DAP_EnableYoking(panelTitle)
End
//==================================================================================================

Function HSU_DataFolderPathDisplay(PanelTitle, LockStatus)
	string PanelTitle
	variable LockStatus // = 0; unlocked  = 1; locked
	if(LockStatus == 1)
		groupbox group_Hardware_FolderPath win = $PanelTitle, title = "Data folder path = " + HSU_DataFullFolderPathString(PanelTitle)
	endif
	
	if(LockStatus == 0)
		groupbox group_Hardware_FolderPath win = $PanelTitle, title = "Lock a device to generate device folder structure"
	endif
End
//==================================================================================================

Function HSU_CreateDataFolderForLockdDev(PanelTitle)
	string PanelTitle
	string FullFolderPath = HSU_DataFullFolderPathString(PanelTitle)
	string BaseFolderPath = HSU_BaseFolderPathString(PanelTitle)
	Newdatafolder /o $BaseFolderPath
	Newdatafolder /o $FullFolderPath
	Newdatafolder /o $FullFolderPath+":Data"
	Newdatafolder /o $FullFolderPath+":TestPulse"
End
//==================================================================================================

Function/t HSU_BaseFolderPathString(PanelTitle)
	string PanelTitle
	string DeviceTypeList = "ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB"  
	variable DeviceType
	string BaseFolderPath
	controlinfo /w = $PanelTitle popup_MoreSettings_DeviceType
	DeviceType = v_value - 1
	BaseFolderPath = "root:MIES:ITCDevices:" + stringfromlist(DeviceType, DeviceTypeList, ";")
	return BaseFolderPath
End
//==================================================================================================

Function /t HSU_DataFullFolderPathString(PanelTitle)
	string PanelTitle
	string DeviceTypeList = "ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB"  
	variable DeviceType, DeviceNumber
	string FolderPath
	controlinfo /w = $PanelTitle popup_MoreSettings_DeviceType
	DeviceType = v_value - 1
	controlinfo /w = $PanelTitle popup_moreSettings_DeviceNo
	DeviceNumber = v_value - 1
	FolderPath = "root:MIES:ITCDevices:" + stringfromlist(DeviceType,DeviceTypeList,";") + ":Device" + num2str(DeviceNumber)
	return FolderPath
End
//==================================================================================================

Function HSU_ButProc_Hrdwr_UnlckDev(ctrlName) : ButtonControl
	String ctrlName
	getwindow kwTopWin wtitle
	string panelTitle = s_value
	HSU_UnlockDevSelection(panelTitle)
	HSU_ListOfITCPanels()
	DAP_EnableYoking(panelTitle)
End
//==================================================================================================

Function HSU_UnlockDevSelection(PanelTitle)
	string PanelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	PopupMenu popup_MoreSettings_DeviceType win = $PanelTitle, disable = 0
	PopupMenu popup_moreSettings_DeviceNo win = $PanelTitle, disable = 0
	Button button_SettingsPlus_LockDevice win = $PanelTitle, disable = 0
	Button button_SettingsPlus_unLockDevic win = $PanelTitle, disable = 2
	Button button_SettingsPlus_PingDevice win = $panelTitle, disable = 0

	//GroupBox group_Hardware_FolderPath win = $PanelTitle, title = "Lock device to set data folder path"
	HSU_DataFolderPathDisplay(PanelTitle, 0)
	string DAwindows = winlist("DA_Ephys*", ";", "WIN:64") //getwindow
	if(itemsinlist(DAwindows,";") == 0) // ensures that when other DA_Ephys windows are unlocked, the panel renaming does not attemp to duplicate the panel name
		dowindow /W = $panelTitle /C $"DA_Ephys"
	elseif((itemsinlist(DAwindows,";") >= 1))
		dowindow /W = $panelTitle /C $("DA_Ephys" + num2str(itemsinlist(DAwindows,";")))
	endif
	// ########## ADD CODE HERE TO REMOVE PANEL TITLE FROM GLOBAL LIST OF PANEL TITLES ##########
	print WavePath + ":ITCDeviceIDGlobal"
	NVAR /z ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	string cmd
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd	
	sprintf cmd, "ITCCloseDevice"
	execute cmd
End
//==================================================================================================

Function HSU_DeviceLockCheck(PanelTitle)
	string PanelTitle
	variable DeviceLockStatus
	controlinfo /W = $PanelTitle button_SettingsPlus_LockDevice
	if(V_disable == 1)
		DoAlert /t = "Hardware Status"  0, "A ITC device must be locked (see Hardware tab) to proceed"
		DeviceLockStatus = 1
	else
		DeviceLockStatus = 0	
	endif
	return DeviceLockStatus
End
//==================================================================================================

Function HSU_IsDeviceTypeConnected(PanelTitle)
	string PanelTitle
	string cmd
	controlinfo /w = $panelTitle popup_MoreSettings_DeviceType
	variable DeviceType = v_value - 1
	make  /O /I /N = 1 localwave
	sprintf cmd, "ITCGetDevices /Z=0 %d, localWave" DeviceType
	execute cmd
	if(LocalWave[0] == 0)
		button button_SettingsPlus_PingDevice win = $PanelTitle, disable = 2
	else
		button button_SettingsPlus_PingDevice win = $PanelTitle, disable = 0
	endif
	print "Available number of specified ITC devices =", LocalWave[0]
	killwaves localwave
End
//==================================================================================================

// below functions are used to create a list of the ITC panels. This list is will be used by functions that need to update items that are common to different panels.
// for example: DAC popup lists, TTL popup lists

Function HSU_GlblListStrngOfITCPanlTitls()
	If(exists("root:MIES:ITCDevices:ITCPanelTitleList") == 0)
	String /G root:MIES:ITCDevices:ITCPanelTitleList
	endif
End
//==================================================================================================

Function HSU_ListOfITCPanels()
	SVAR ITCPanelTitleList = root:MIES:ITCDevices:ITCPanelTitleList
	ITCPanelTitleList = winlist("ITC*", ";", "WIN:64") 
End
//==================================================================================================

Function HSU_OpenITCDevice(panelTitle)
	String panelTitle
	variable DeviceType, DeviceNumber
	string cmd
	controlinfo /w = $PanelTitle popup_MoreSettings_DeviceType
	DeviceType = v_value - 1
	controlinfo /w = $PanelTitle popup_moreSettings_DeviceNo
	DeviceNumber = v_value - 1
	Make /o  /I /U /N = 1 DevID = 50 // /FREE /I /U /N = 2 DevID = 50
	string DeviceID = "DevID"
	sprintf cmd, "ITCOpenDevice %d, %d, %s", DeviceType, DeviceNumber, DeviceID
	Execute cmd
	print "ITC Device ID = ",DevID[0], "is locked."
	//print "ITC Device ID = ",DevID[1], "is locked."
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	string ITCDeviceIDGlobal = WavePath + ":ITCDeviceIDGlobal"
	Variable /G $ITCDeviceIDGlobal = DevID[0]
End // Function HSU_OpenITCDevice(panelTitle)
//==================================================================================================

Function HSU_UpdateChanAmpAssignStorWv(panelTitle)
	string panelTitle
	Variable HeadStageNo, SweepNo, i
	wave /z W_TelegraphServers = root:MIES:Amplifiers:W_TelegraphServers
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave /z ChanAmpAssign = $WavePath + ":ChanAmpAssign"
	string ChanAmpAssignUnitPath = WavePath + ":ChanAmpAssignUnit"
	wave /z /T ChanAmpAssignUnit = $ChanAmpAssignUnitPath

	controlinfo /w = $panelTitle Popup_Settings_HeadStage
	HeadStageNo = str2num(s_value)
	
	If (waveexists($WavePath + ":ChanAmpAssign") == 0)// checks to see if data storage wave exists, makes it if it doesn't
		string ChanAmpAssignPath = WavePath + ":ChanAmpAssign"
		make /n = (12,8) $ChanAmpAssignPath
		wave ChanAmpAssign = $ChanAmpAssignPath
		ChanAmpAssign = nan
	endif
	
	If (waveexists($WavePath + ":ChanAmpAssignUnit") == 0)// if the wave doesn't exist, it makes the wave that channel unit info is stored in
		make /T  /n = (4,8)  $ChanAmpAssignUnitPath
		wave /T ChanAmpAssignUnit = $ChanAmpAssignUnitPath
	endif
	
	string ChannelClampModeString = WavePath + ":ChannelClampMode"
		if(waveexists($ChannelClampModeString) == 0) // makes the storage wave if it does not exist. This wave stores the active clamp mode of AD channels. It is populated in a different procedure
		make /o /n = (16, 2) $ChannelClampModeString = nan
	endif

	duplicate /free ChanAmpAssign ChanAmpAssignOrig

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
	
	//Assigns amplifier to a particualr headstage - sounds weird because this relationship is predetermined in hardware but now you are telling the software what it is
	if(waveexists(root:MIES:Amplifiers:W_telegraphServers) == 1)
	ControlInfo /w = $panelTitle popup_Settings_Amplifier
		if(v_value > 1)
		ChanAmpAssign[8][HeadStageNo] = W_TelegraphServers[v_value-2][0]
		ChanAmpAssign[9][HeadStageNo] = W_TelegraphServers[v_value-2][1]
		else
		ChanAmpAssign[8][HeadStageNo] = nan
		ChanAmpAssign[9][HeadStageNo] = nan
		endif
		ChanAmpAssign[10][HeadStageNo] = v_value

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

Function HSU_UpdateChanAmpAssignPanel(PanelTitle)
	string panelTitle
	Variable HeadStageNo
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ChanAmpAssign = $WavePath + ":ChanAmpAssign"
	wave / T ChanAmpAssignUnit = $WavePath + ":ChanAmpAssignUnit"
	controlinfo /w =$panelTitle Popup_Settings_HeadStage
	HeadStageNo = str2num(s_value)
	
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

//==================================================================================================
Function HSU_SetITCDACasFollower(panelTitle, followerDAC) // This function sets a ITC1600 device as a follower, ie. The internal clock is used to synchronize 2 or more PCI-1600
	string panelTitle, followerDAC
	string LeadDeviceFolderPath =  HSU_DataFullFolderPathString(PanelTitle)
	string FollowerDeviceFolderPath = HSU_DataFullFolderPathString(followerDAC)
	// variable LeadITCDeviceIDGlobal
	NVAR /z FollowerITCDeviceIDGlobal = $(FollowerDeviceFolderPath + ":ITCDeviceIDGlobal")
	string cmd = ""

	// create/append to global string list of follower devices for lead device
	SVAR /z ListOfFollowerITC1600s = $(LeadDeviceFolderPath + ":ListOfFollowerITC1600s")
	string pathListOfFollowerITC1600s = (LeadDeviceFolderPath + ":ListOfFollowerITC1600s")
//	print pathListOfFollowerITC1600s
//	print "global exists = ", exists(pathListOfFollowerITC1600s) 
	
	if(exists(pathListOfFollowerITC1600s) == 2)
		if(whichlistitem(followerDAC,ListOfFollowerITC1600s, ";") == -1) // prevents user from adding the same follower device twice
			ListOfFollowerITC1600s += followerDAC + ";"
			sprintf cmd, "ITCSelectDevice %d" FollowerITCDeviceIDGlobal
			execute cmd
			Execute "ITCInitialize /M = 1" 
			setvariable setvar_Hardware_YokeList Win = $panelTitle, value= _STR:ListOfFollowerITC1600s, disable = 0
		endif
	elseif(exists(pathListOfFollowerITC1600s) == 0)
		string/ g $(LeadDeviceFolderPath + ":ListOfFollowerITC1600s")
		SVAR /z ListOfFollowerITC1600s = $(LeadDeviceFolderPath + ":ListOfFollowerITC1600s")
		ListOfFollowerITC1600s = followerDAC + ";"
		sprintf cmd, "ITCSelectDevice %d" FollowerITCDeviceIDGlobal
		execute cmd
		Execute "ITCInitialize /M = 1" 
		setvariable setvar_Hardware_YokeList Win = $panelTitle, value= _STR:ListOfFollowerITC1600s, disable = 0
	endif
	// set the internal clock of the device
End

root:MIES:ITCDevices:ITC1600:Device1
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
	Variable start = stopmstimer(-2)
	Execute "ITCInitialize /M = 1" 
//==================================================================================================
// MULTICLAMP HARDWARE CONFIGURATION FUNCTION BELOW
//==================================================================================================

//==================================================================================================
// AUTO IMPORT GAIN SETTINGS FROM AXON AMP FUNCTIONS BELOW
//==================================================================================================



Function HSU_AutoFillGain(panelTitle) // Auto fills the units and gains in the hardware tab of the DA_Ephys panel - has some limitations that are due to the MCC API limitations
	string panelTitle			
	string wavePath = HSU_DataFullFolderPathString(PanelTitle)


	// sets the units
	SetVariable SetVar_Hardware_VC_DA_Unit Win = $panelTitle, Value=_STR:"mV"
	SetVariable SetVar_Hardware_VC_AD_Unit Win = $panelTitle, Value=_STR:"pA"
	SetVariable SetVar_Hardware_IC_DA_Unit Win = $panelTitle, Value=_STR:"pA"
	SetVariable SetVar_Hardware_IC_AD_Unit Win = $panelTitle, Value=_STR:"mV"
	
	// get the headstage number being updated
	controlInfo /w = $PanelTitle Popup_Settings_HeadStage
	variable HeadStageNo = v_value - 1
	// get the associated amp serial number - the serial number of the assoicated amp is stored in row 8 of the ChaAmpAssign wave
	Wave ChanAmpAssign = $WavePath + ":ChanAmpAssign"
	variable AmpSerialNo = ChanAmpAssign[8][HeadStageNo]
	// get the amp channel
	variable AmpChannel = ChanAmpAssign[9][HeadStageNo]
	// Select the amp to query
	
	string AmpSerialNumberString
	sprintf AmpSerialNumberString, "%.8d" AmpSerialNo
	MCC_SelectMultiClamp700B(AmpSerialNumberString, AmpChannel)
	variable Mode = MCC_GetMode()
	
	variable ResetToModeTwo = 0
	// set the gain

	
	if(Mode == 0)
		SetVariable setvar_Settings_VC_DAgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveDAGain(panelTitle, AmpSerialNo, AmpChannel))
		SetVariable setvar_Settings_VC_ADgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveADGain(panelTitle, AmpSerialNo, AmpChannel))
	elseif(Mode == 1)
		SetVariable setvar_Settings_IC_DAgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveDAGain(panelTitle, AmpSerialNo, AmpChannel))
		SetVariable setvar_Settings_IC_ADgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveADGain(panelTitle, AmpSerialNo, AmpChannel))
	elseif(Mode == 2)
		if(MCC_GetHoldingEnable() == 0) // checks to see if a holding current or bias current is being applied, if yes, the mode switch required to pull in the gains for all modes is prevented.
			MCC_SetMode(1)
			ResetToModeTwo = 1
			SetVariable setvar_Settings_IC_DAgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveDAGain(panelTitle, AmpSerialNo, AmpChannel))
			SetVariable setvar_Settings_IC_ADgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveADGain(panelTitle, AmpSerialNo, AmpChannel))
		elseif(MCC_GetHoldingEnable() == 1)
			print "It appears that a bias current or holding potential is being applied by the MC Commader suggesting that a recording is ongoing, therefore as a precaution, the gain settings cannot be imported"
		endif
	endif
	
	if(MCC_GetHoldingEnable() == 0) // checks to see if a holding current or bias current is being applied, if yes, the mode switch required to pull in the gains for all modes is prevented.
		AI_SwitchAxonAmpMode(panelTitle, AmpSerialNo, AmpChannel)
	
		Mode = MCC_GetMode()
		 
		 if(Mode == 0)
			SetVariable setvar_Settings_VC_DAgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveDAGain(panelTitle, AmpSerialNo, AmpChannel))
			SetVariable setvar_Settings_VC_ADgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveADGain(panelTitle, AmpSerialNo, AmpChannel))
		elseif(Mode == 1)
			SetVariable setvar_Settings_IC_DAgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveDAGain(panelTitle, AmpSerialNo, AmpChannel))
			SetVariable setvar_Settings_IC_ADgain Win = $panelTitle, Value=_NUM:(real(AI_RetrieveADGain(panelTitle, AmpSerialNo, AmpChannel))
		endif
		
		if(ResetToModeTwo == 0)
			AI_SwitchAxonAmpMode(panelTitle, AmpSerialNo, AmpChannel)
		elseif(ResetToModeTwo == 1)
			MCC_SetMode(2)
		endif
	elseif((MCC_GetHoldingEnable() == 1))
		if(Mode == 0)
			print "It appears that a holding potential is being applied, therefore as a precaution, the gains cannot be imported for the I-clamp mode."
			print "The gains were successfully imported for the V-clamp mode on headstage: ", HeadstageNo
		elseif(Mode == 1)
			print "It appears that a bias current is being applied, therefore as a precaution, the gains cannot be imported for the V-clamp mode."
			print "The gains were successfully imported for the I-clamp mode on headstage: ", HeadstageNo
		endif
	endif

End

//==================================================================================================
// 
//==================================================================================================