#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// DATA ACQ MANAGEMENT - HANDLES MULTIPLE DEVICES INCLUDING YOKED DEVICES

Function FunctionStartDataAcq(deviceType, deviceNum, panelTitle) // this function handles the calls to the data configurator (DC) functions and BackgroundMD - it is required because of the special handling syncronous ITC1600s require
	variable DeviceType, DeviceNum
	string panelTitle
	Variable start = stopmstimer(-2)
	variable i
	variable TriggerMode = 0
	variable numberOfFollowerDevices = 0
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave /z ITCDataWave = $WavePath + ":ITCDataWave"
	string followerPanelTitle = ""
	variable DataAcqOrTP = 0 // data acq, not TP
	DC_ConfigureDataForITC(PanelTitle, DataAcqOrTP)
	SCOPE_UpdateGraph(ITCDataWave, panelTitle)
	
	if(DeviceType == 2) // starts data acquisition for ITC1600 devices
		string pathToListOfFollowerDevices = Path_ITCDevicesFolder(panelTitle) + ":ITC1600:Device0:ListOfFollowerITC1600s"
		SVAR /z ListOfFollowerDevices = $pathToListOfFollowerDevices
		if(exists(pathToListOfFollowerDevices) == 2) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
			numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
			if(numberOfFollowerDevices != 0) // List of yoked ITC1600 devices does contain 1 or more yoked ITC1600s
				ARDStartSequence() // runs the arduino once before it matters to make sure it is intialized - not sure if i need to do this
				do // LOOP that configures data and oscilloscope for data acquisition on all follower ITC1600 devices
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					//print followerpaneltitle
					DC_ConfigureDataForITC(followerPanelTitle, DataAcqOrTP)
					WavePath = HSU_DataFullFolderPathString(followerPanelTitle)
					wave /z ITCDataWave = $WavePath + ":ITCDataWave"
					SCOPE_UpdateGraph(ITCDataWave, followerPanelTitle)
					i += 1
				while(i < numberOfFollowerDevices)
				i = 0
				TriggerMode = 256
				//print "start time =",TriggerMode
				
				do // LOOP that preconfigures each DAC to
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					ITC_ConfigUploadDAC(followerPanelTitle)
				i += 1
				while(i < numberOfFollowerDevices)
				
				i = 0
				ITC_ConfigUploadDAC(panelTitle) // configures lead device
				ITC_BkrdDataAcqMD(2, DeviceNum, TriggerMode, panelTitle) // starts data acq on Lead device
				
				do // LOOP that begins data acquistion follower ITC1600 devices
					followerPanelTitle = stringfromlist(i, ListOfFollowerDevices, ";")
					controlinfo /w = $panelTitle popup_moreSettings_DeviceNo
					DeviceNum =  v_value - 1
					ITC_BkrdDataAcqMD(2, DeviceNum, TriggerMode, followerPanelTitle)
					i += 1
				while(i < numberOfFollowerDevices)
				// activates trigger
				ARDStartSequence() // runs sequence already loaded on arduino - sequence and arduino hardware need to be set up manually!!!!!! THIS TRIGGERS THE YOKED ITC1600s
			elseif(numberOfFollowerDevices == 0)
				ITC_ConfigUploadDAC(panelTitle)
				ITC_BkrdDataAcqMD(DeviceType, DeviceNum, TriggerMode, panelTitle)
			endif
		elseif(exists(pathToListOfFollowerDevices) != 2) //ITC1600 device but no yoked devices - data acquisition proceeds in the same was as for all other ITC device types
			ITC_ConfigUploadDAC(panelTitle)
			ITC_BkrdDataAcqMD(DeviceType, DeviceNum, TriggerMode, panelTitle)
		endif
	elseIf(DeviceType != 2) // starts data acquisition for non ITC1600 ITC devices
		ITC_ConfigUploadDAC(panelTitle)
		ITC_BkrdDataAcqMD(DeviceType, DeviceNum, TriggerMode, panelTitle)
	endif
	print "Data Acquisition took: ", (stopmstimer(-2) - start) / 1000, " ms"
End

Function ITC_ConfigUploadDAC(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	NVAR ITCDeviceIDGlobal = $WavePath + ":ITCDeviceIDGlobal"
	string cmd = ""
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute cmd
	
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	string ITCDataWavePath = WavePath + ":ITCDataWave"//, ITCFIFOAvailAllConfigWavePath = WavePath + ":ITCFIFOAvailAllConfigWave"
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	Execute cmd	
	
	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
	execute cmd// this also seems necessary to update the DA channel data to the board!!
End
//=================================================================================================================
// TP MANAGEMENT - HANDLES MULTIPLE DEVICES INCLUDING YOKED DEVICES
//=================================================================================================================
Function StartTestPulse(deviceType, deviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string TestPulsePath
	variable i = 0
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	variable DataAcqOrTP = 1
	variable TriggerMode
	string TPDurationGlobalPath
	variable NewNoOfPoints

	if(DeviceType == 2) // if the device is a ITC1600 i.e., capable of yoking
		string pathToListOfFollowerDevices = Path_ITCDevicesFolder(panelTitle) + ":ITC1600:Device0:ListOfFollowerITC1600s"
		SVAR /z ListOfFollowerDevices = $pathToListOfFollowerDevices
		if(exists(pathToListOfFollowerDevices) == 2) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
			variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
			if(numberOfFollowerDevices != 0) 
				string followerPanelTitle
				do // configure follower device for TP acquistion
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					TP_TPSetUp(followerPanelTitle)
					i += 1
				while(i < numberOfFollowerDevices)
				i = 0
				TriggerMode = 256
				
				ITC_BkrdTPMD(DeviceType, DeviceNum, TriggerMode, panelTitle) // Sets lead board in wait for trigger mode
				wave /z SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
				wave /z SelectedDACScale = $(WavePath + ":SelectedDACScale")
				TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle) // restores lead board settings
				TP_RestoreDAScale(SelectedDACScale,panelTitle)
				
				
				do
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					WavePath = HSU_DataFullFolderPathString(followerPanelTitle)
					ITC_BkrdTPMD(DeviceType, DeviceNum, TriggerMode, followerPanelTitle) // Sets lead board in wait for trigger mode
					wave /z SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
					wave /z SelectedDACScale = $(WavePath + ":SelectedDACScale")
					TP_ResetSelectedDACWaves(SelectedDACWaveList,followerPanelTitle) // restores lead board settings
					TP_RestoreDAScale(SelectedDACScale,followerPanelTitle)					
					i += 1
				while(i < numberOfFollowerDevices)
			elseif(numberOfFollowerDevices == 0)
				TP_TPSetUp(panelTitle)
				ITC_BkrdTPMD(DeviceType, DeviceNum, 0, panelTitle) // START TP DATA ACQUISITION
				wave SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
				wave SelectedDACScale = $(WavePath + ":SelectedDACScale")
				TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
				TP_RestoreDAScale(SelectedDACScale,panelTitle)
			endif
		elseif(exists(pathToListOfFollowerDevices) == 0)
			TP_TPSetUp(panelTitle)
			ITC_BkrdTPMD(DeviceType, DeviceNum, 0, panelTitle) // START TP DATA ACQUISITION
			wave SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
			wave SelectedDACScale = $(WavePath + ":SelectedDACScale")
			TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
			TP_RestoreDAScale(SelectedDACScale,panelTitle)		
		endif
	elseif(DeviceType != 2)
	
//		DAP_StoreTTLState(panelTitle)
//		DAP_TurnOffAllTTLs(panelTitle)
//		
//		// stores panel settings
//		make /free /n = 8 SelectedDACWaveList
//		TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
//		TP_SelectTestPulseWave(panelTitle)
//		
//		make /free /n = 8 SelectedDACScale
//		TP_StoreDAScale(SelectedDACScale,panelTitle)
//		TP_SetDAScaleToOne(panelTitle)
//		
//		// creates test pulse wave
//		TestPulsePath = Path_WBSvdStimSetDAFolder(panelTitle) + ":TestPulse"
//		print "test pulse path = ", testpulsepath
//		make /o /n = 0 $TestPulsePath
//		wave TestPulse = $TestPulsePath
//		SetScale /P x 0,0.005,"ms", TestPulse // test pulse wave made at max possible samp frequency
//		
//		// adjust test pulse wave according to panel input
//		//TP_UpdateTestPulseWave(TestPulse, panelTitle)
//	
//		TP_UpdateTestPulseWaveChunks(TestPulse, panelTitle) // makes the test pulse wave that contains enought test pulses to fill the min ITC DAC wave size 2^16
//		
//		// creates TP wave used for display
//		//DM_CreateScaleTPHoldingWave(panelTitle)
//		
//		//string TPDurationGlobalPath
//		sprintf TPDurationGlobalPath, "%s:TestPulse:Duration" WavePath
//		NVAR GlobalTPDurationVariable = $TPDurationGlobalPath
//		DM_CreateScaleTPHoldWaveChunk(panelTitle,0, GlobalTPDurationVariable)  // first TP so start point = 0
//		TP_ClampModeString(panelTitle)
//		
//		// configures data for ITC with testpulse wave selected
//		DC_ConfigureDataForITC(panelTitle, DataAcqOrTP)
//		// special mod for test pulse to ITC data wave that makes sure the entire TP is filled with test pulses because of how data is placed into the ITCDataWave based on sampling frequency
//		wave ITCDataWave = $WavePath + ":ITCDataWave"
//		// variable NewNoOfPoints = floor(dimsize(ITCDataWave, 0) / (deltaX(ITCDataWave) / 0.005))
//		NewNoOfPoints = floor(dimsize(ITCDataWave, 0) / (deltaX(ITCDataWave) / 0.005))
//		if(NewNoOfPoints == 21845) // extra special exceptions for 3 channels - super BS coding right here.
//			NewNoOfPoints = 2^14
//		endif
//		// print "divisor =",(deltaX(ITCDataWave) / 0.005)
//		// print "new no of points =", NewNoOfPoints
//		redimension /N =(NewNoOfPoints, -1, -1, -1) ITCDataWave
//		
//		wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
//		SCOPE_UpdateGraph(TestPulseITC,panelTitle)
//		//ITC_StartBackgroundTestPulseMD(DeviceType, DeviceNum, panelTitle)
//		ITC_ConfigUploadDAC(panelTitle)
		TP_TPSetUp(panelTitle)
		ITC_BkrdTPMD(DeviceType, DeviceNum, 0, panelTitle) // START TP DATA ACQUISITION
		wave SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
		wave SelectedDACScale = $(WavePath + ":SelectedDACScale")
		TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
		TP_RestoreDAScale(SelectedDACScale,panelTitle)
	
	endif
	
End

Function TP_TPSetUp(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	string TestPulsePath
	variable DataAcqOrTP = 1
	
		DAP_StoreTTLState(panelTitle)
		DAP_TurnOffAllTTLs(panelTitle)
		
		// stores panel settings
		make /o /n = 8 $(WavePath + ":SelectedDACWaveList")
		wave SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
		TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
		TP_SelectTestPulseWave(panelTitle)
		
		make /o /n = 8 $(WavePath + ":SelectedDACScale")
		wave SelectedDACScale = $(WavePath + ":SelectedDACScale")
		TP_StoreDAScale(SelectedDACScale,panelTitle)
		TP_SetDAScaleToOne(panelTitle)
		
		// creates test pulse wave
		TestPulsePath = Path_WBSvdStimSetDAFolder(panelTitle) + ":TestPulse"
		print "test pulse path = ", testpulsepath
		make /o /n = 0 $TestPulsePath
		wave TestPulse = $TestPulsePath
		SetScale /P x 0,0.005,"ms", TestPulse // test pulse wave made at max possible samp frequency
		
		// adjust test pulse wave according to panel input
		//TP_UpdateTestPulseWave(TestPulse, panelTitle)
	
		TP_UpdateTestPulseWaveChunks(TestPulse, panelTitle) // makes the test pulse wave that contains enought test pulses to fill the min ITC DAC wave size 2^16
		
		// creates TP wave used for display
		//DM_CreateScaleTPHoldingWave(panelTitle)
		
		string TPDurationGlobalPath
		sprintf TPDurationGlobalPath, "%s:TestPulse:Duration" WavePath
		NVAR GlobalTPDurationVariable = $TPDurationGlobalPath
		DM_CreateScaleTPHoldWaveChunk(panelTitle,0, GlobalTPDurationVariable)  // first TP so start point = 0
		TP_ClampModeString(panelTitle)
		
		// configures data for ITC with testpulse wave selected
		DC_ConfigureDataForITC(panelTitle, DataAcqOrTP)
		// special mod for test pulse to ITC data wave that makes sure the entire TP is filled with test pulses because of how data is placed into the ITCDataWave based on sampling frequency
		wave ITCDataWave = $WavePath + ":ITCDataWave"
		variable NewNoOfPoints = floor(dimsize(ITCDataWave, 0) / (deltaX(ITCDataWave) / 0.005))
		
		if(NewNoOfPoints == 21845) // extra special exceptions for 3 channels - super BS coding right here.
			NewNoOfPoints = 2^14
		endif
		// print "divisor =",(deltaX(ITCDataWave) / 0.005)
		// print "new no of points =", NewNoOfPoints
		redimension /N =(NewNoOfPoints, -1, -1, -1) ITCDataWave
		
		wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
		SCOPE_UpdateGraph(TestPulseITC,panelTitle)
		//ITC_StartBackgroundTestPulseMD(DeviceType, DeviceNum, panelTitle)
		ITC_ConfigUploadDAC(panelTitle)
	
End