#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//=====================================================================================
// ITC HARDWARE CONFIGURATION FUNCTIONS
Function HSU_QueryITCDevice()
	variable DeviceType, DeviceNumber
	string cmd
	controlinfo/w=datapro_itc1600 popup_MoreSettings_DeviceType
	DeviceType=v_value-1
	controlinfo/w=datapro_itc1600 popup_moreSettings_DeviceNo
	DeviceNumber=v_value-1
	
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNumber
	Execute cmd
	sprintf cmd, "ITCGetState /E=1 ResultWave"
	Execute cmd
	DoAlert/t="Ready light check"  0, "Click \"OK\" when finished checking device"
	
	sprintf cmd, "ITCCloseDevice" 
	execute cmd
End

Function HSU_ButtonProc_Settings_OpenDev(ctrlName) : ButtonControl
	String ctrlName
	HSU_QueryITCDevice()
End

Function HSU_ButtonProc_LockDev(ctrlName) : ButtonControl
	String ctrlName
	HSU_LockDevice()
End

Function HSU_LockDevice()
	PopupMenu popup_MoreSettings_DeviceType win=datapro_itc1600, disable=2
	PopupMenu popup_moreSettings_DeviceNo win=datapro_itc1600, disable=2
	Button button_SettingsPlus_LockDevice win=datapro_itc1600, disable=2
	HSU_DataFolderPathDisplay()
	HSU_CreateDataFolderForLockdDev()
	Button button_SettingsPlus_unLockDevic win=datapro_itc1600, disable=0
End

Function HSU_DataFolderPathDisplay()
	groupbox group_SettingsPlus_FolderPath win=datapro_itc1600, title="Data folder path = "+HSU_DataFullFolderPathString()
End

Function HSU_CreateDataFolderForLockdDev()
	string FullFolderPath=HSU_DataFullFolderPathString()
	string BaseFolderPath=HSU_BaseFolderPathString()
	Newdatafolder/o $BaseFolderPath
	Newdatafolder/o $FullFolderPath
End

Function/t HSU_BaseFolderPathString()
	string DeviceTypeList = "ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB"  
	variable DeviceType
	string BaseFolderPath
	
	controlinfo/w=datapro_itc1600 popup_MoreSettings_DeviceType
	DeviceType=v_value-1
	
	BaseFolderPath="root:"+stringfromlist(DeviceType,DeviceTypeList,";")
	return BaseFolderPath
End

Function/t HSU_DataFullFolderPathString()
	string DeviceTypeList = "ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB"  
	variable DeviceType, DeviceNumber
	string FolderPath
	
	controlinfo/w=datapro_itc1600 popup_MoreSettings_DeviceType
	DeviceType=v_value-1
	controlinfo/w=datapro_itc1600 popup_moreSettings_DeviceNo
	DeviceNumber=v_value-1
	
	FolderPath="root:"+stringfromlist(DeviceType,DeviceTypeList,";")+":Device"+num2str(DeviceNumber)
	return FolderPath
End

Function HSU_ButProc_Hrdwr_UnlckDev(ctrlName) : ButtonControl
	String ctrlName
	HSU_UnlockDevSelection()
End

Function HSU_UnlockDevSelection()
	PopupMenu popup_MoreSettings_DeviceType win=datapro_itc1600, disable=0
	PopupMenu popup_moreSettings_DeviceNo win=datapro_itc1600, disable=0
	Button button_SettingsPlus_LockDevice win=datapro_itc1600, disable=0
	Button button_SettingsPlus_unLockDevic win=datapro_itc1600, disable=2
	GroupBox group_SettingsPlus_FolderPath win=datapro_itc1600, title="Lock device to set data folder path"
End

Function HSU_DeviceLockCheck()
	variable DeviceLockStatus
	controlinfo /W = datapro_itc1600 button_SettingsPlus_LockDevice
	print v_disable
	if(V_disable==1)
	DoAlert/t="Hardware Status"  0, "A ITC device must be locked (see Hardware tab) to proceed"
	DeviceLockStatus=1
	else
	DeviceLockStatus=0	
	endif
	return DeviceLockStatus
End

Function PopMenuProc_Hrdwr_DevTypeCheck(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	HSU_IsDeviceTypeConnected()
End

Function HSU_IsDeviceTypeConnected()
	string cmd
	controlinfo/w=datapro_itc1600 popup_MoreSettings_DeviceType
	variable DeviceType=v_value-1
	make  /O /I /N=1 localwave
	sprintf cmd, "ITCGetDevices /Z=0 %d, localWave" DeviceType
	execute cmd
	if(LocalWave[0]==0)
		button button_SettingsPlus_PingDevice win=datapro_itc1600, disable=2
	else
		button button_SettingsPlus_PingDevice win=datapro_itc1600, disable=0
	endif
	killwaves localwave
End

//=====================================================================================
// MULTICLAMP HARDWARE CONFIGURATION FUNCTION BELOW
//=====================================================================================
