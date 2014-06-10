#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// DATA ACQ MANAGEMENT - HANDLES MULTIPLE DEVICES INCLUDING YOKED DEVICES

/// @Brief Handles function calls for data acquistion. These include calls for starting Yoked ITC1600s. 
/// @param WavePath WavePath is a string that contains the path to the device file folder
/// @param TriggerMode Trigger mode is either 0 or 256. 256 causes the ITC1600 to wait for the external trigger (5V signal to the PCI card). 0 is used to bin all aquisition immediately on all ITC devies.
/// @param DataAcqOrTP DataAcqOrTP is used to indicate wether data aquistion or a testpulse is ongoing. 0 = Data acquistion. 1 = TP. Certain function handle data acq and Tp slightly differently.
/// FunctionStartDataAcq determines what device is being started and begins aquisition in the appropriate manner for the device
/// FunctionStartDataAcq is used when MD support is enabled in the settings tab of DA_ephys. If MD is not enabled, alternate functions are used to run data acquisition.
/// FunctionStartDataAcq
Function FunctionStartDataAcq(deviceType, deviceNum, panelTitle) // this function handles the calls to the data configurator (DC) functions and BackgroundMD - it is required because of the special handling syncronous ITC1600s require
	variable DeviceType, DeviceNum
	string panelTitle
	Variable start = stopmstimer(-2)
	variable i
	variable TriggerMode = 0
	variable numberOfFollowerDevices = 0
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave /z ITCDataWave = $WavePath + ":ITCDataWave"
	string followerPanelTitle = ""
	variable DataAcqOrTP = 0 // data acq, not TP
	DC_ConfigureDataForITC(panelTitle, DataAcqOrTP)
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
					controlinfo /w = $panelTitle popup_moreSettings_DeviceNo // shouldn't this be follower panel title
					//controlinfo /w = $followerPanelTitle popup_moreSettings_DeviceNo // shouldn't this be follower panel title
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
End // Function
//=================================================================================================================

/// @brief Configures ITC DACs
/// @param ITCDeviceIDGlobal ITCDeviceIDGlobal is the unique number assigned to a ITC device. ITCDeviceIDGlobal can range from 0 to 14.
/// ITC_ConfigUploadDAC selects the ITC device based on the panelTitle passed into the function.
/// ITC_ConfigUploadDAC configures all the DAC channels at once using the ITCconfigAllChannels command
/// ITC_ConfigUploadDAC resets the DAC FIFOs using the ITCUpdateFIFOPositionAll command
/// ITC_ConfigUploadDAC
Function ITC_ConfigUploadDAC(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
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
/// @brief StartTestPulse start the test pulse when MD support is activated.
/// @param DeviceType Each ITC device has a DeviceType number: 0 through 5.
/// @param DeviceNum Each locked ITC device has a number starting from zero for devices of that type. It is different from the device global ID. 
/// @param DeviceNum Ex. Two ITC18s would always have the device number 0 and 1 regardless of the number of other ITC devies connected of other types.
/// StartTestPulse handles the TP initiation for all ITC devices. Yoked ITC1600s are handled specially using the external trigger.
/// The external trigger is assumed to be a arduino device using the arduino squencer.
/// StartTestPulse
Function StartTestPulse(deviceType, deviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string TestPulsePath
	variable i = 0
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
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
				ARDStartSequence()
				string followerPanelTitle
				
				do // configure follower device for TP acquistion
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					TP_TPSetUp(followerPanelTitle)
					i += 1
				while(i < numberOfFollowerDevices)
				i = 0
				TriggerMode = 256
				
				//Lead board commands
				TP_TPSetUp(panelTitle)
				ITC_BkrdTPMD(DeviceType, DeviceNum, TriggerMode, panelTitle) // Sets lead board in wait for trigger mode
				wave /z SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
				wave /z SelectedDACScale = $(WavePath + ":SelectedDACScale")
				TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle) // restores lead board settings
				TP_RestoreDAScale(SelectedDACScale,panelTitle)
				
				//Follower board commands
				do
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					controlinfo /w = $followerPanelTitle popup_moreSettings_DeviceNo
					DeviceNum =  v_value - 1
					WavePath = HSU_DataFullFolderPathString(followerPanelTitle)
					ITC_BkrdTPMD(DeviceType, DeviceNum, TriggerMode, followerPanelTitle) // Sets lead board in wait for trigger mode
					wave /z SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
					wave /z SelectedDACScale = $(WavePath + ":SelectedDACScale")
					TP_ResetSelectedDACWaves(SelectedDACWaveList,followerPanelTitle) // restores lead board settings
					TP_RestoreDAScale(SelectedDACScale,followerPanelTitle)					
					i += 1
				while(i < numberOfFollowerDevices)
				
				// Arduino gives trigger
				ARDStartSequence()
				
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
	
		TP_TPSetUp(panelTitle)
		ITC_BkrdTPMD(DeviceType, DeviceNum, 0, panelTitle) // START TP DATA ACQUISITION
		wave SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
		wave SelectedDACScale = $(WavePath + ":SelectedDACScale")
		TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
		TP_RestoreDAScale(SelectedDACScale,panelTitle)
	
	endif
	
End
//=========================================================================================

Function Yoked_ITCStopDataAcq(panelTitle) // stops the TP on yoked devices simultaneously 
	string panelTitle

	variable i = 0
	variable deviceType = 0

	variable ITC1600True = stringmatch(panelTitle, "*ITC1600*")
	if(ITC1600True == 1)
		deviceType = 2
	endif
	if(DeviceType == 2) // if the device is a ITC1600 i.e., capable of yoking
		string pathToListOfFollowerDevices = Path_ITCDevicesFolder(panelTitle) + ":ITC1600:Device0:ListOfFollowerITC1600s"
		SVAR /z ListOfFollowerDevices = $pathToListOfFollowerDevices
		if(exists(pathToListOfFollowerDevices) == 2) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
			variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
			if(numberOfFollowerDevices != 0) 
				string followerPanelTitle
				
		
				//Lead board commands
				// ITC_StopTPMD(panelTitle)
				DAP_StopOngoingDataAcqMD(panelTitle)
				//Follower board commands
				do
					followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
					//ITC_StopTPMD(followerPanelTitle)
					DAP_StopOngoingDataAcqMD(followerPanelTitle)
					i += 1
				while(i < numberOfFollowerDevices)

				
			elseif(numberOfFollowerDevices == 0)
				DAP_StopOngoingDataAcqMD(panelTitle)
			endif
		elseif(exists(pathToListOfFollowerDevices) == 0)
			DAP_StopOngoingDataAcqMD(panelTitle)
		endif
	elseif(DeviceType != 2)
		// ITC_StopTPMD(panelTitle)
		DAP_StopOngoingDataAcqMD(panelTitle)
	endif
End
//=========================================================================================

Function ITCStopTP(panelTitle) // stops the TP on yoked devices simultaneously 

    string panelTitle

    variable i = 0
    variable deviceType = 0

    variable ITC1600True = stringmatch(panelTitle, "*ITC1600*")
    if(ITC1600True == 1)
        deviceType = 2
    endif
 
    if(DeviceType == 2) // if the device is a ITC1600 i.e., capable of yoking
        string pathToListOfFollowerDevices = Path_ITCDevicesFolder(panelTitle) + ":ITC1600:Device0:ListOfFollowerITC1600s"
        SVAR /z ListOfFollowerDevices = $pathToListOfFollowerDevices
        if(exists(pathToListOfFollowerDevices) == 2) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
            variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
            if(numberOfFollowerDevices != 0) 
                string followerPanelTitle
                
        
                //Lead board commands
                ITC_StopTPMD(panelTitle)
                ITC_FinishTestPulseMD(panelTitle)
                // ITC_StopTPMD(panelTitle)
               // DAP_StopOngoingDataAcqMD(panelTitle)
                //Follower board commands
                do
                    followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
                    ITC_StopTPMD(followerPanelTitle)
                   ITC_FinishTestPulseMD(followerPanelTitle)
                    i += 1
                while(i < numberOfFollowerDevices)

                
            elseif(numberOfFollowerDevices == 0)
                ITC_StopTPMD(panelTitle)
                ITC_FinishTestPulseMD(panelTitle)
               
            endif
        elseif(exists(pathToListOfFollowerDevices) == 0)
            ITC_StopTPMD(panelTitle)
            ITC_FinishTestPulseMD(panelTitle)
         
        endif
    elseif(DeviceType != 2)
            ITC_StopTPMD(panelTitle)
            ITC_FinishTestPulseMD(panelTitle)
            // ITC_StopTPMD(panelTitle)
        
    endif
End

//=========================================================================================
Function YokedRA_StartMD(panelTitle) // if devices are yoked, RA_StartMD is only called once the last device has finished the TP, and it is called for the lead device
	string panelTitle					// if devices are not yoked, it is the same as it would be if RA_StartMD was called directly


	variable i = 0
	variable deviceType = 0

	variable ITC1600True = stringmatch(panelTitle, "*ITC1600*")
	if(ITC1600True == 1)
		deviceType = 2
	endif

	if(DeviceType == 2) // if the device is a ITC1600 i.e., capable of yoking
		print "1600 device"
		string pathToListOfFollowerDevices = Path_ITCDevicesFolder(panelTitle) + ":ITC1600:Device0:ListOfFollowerITC1600s"
		SVAR /z ListOfFollowerDevices = $pathToListOfFollowerDevices
		if(exists(pathToListOfFollowerDevices) == 2) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
			variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
			if(numberOfFollowerDevices != 0) // There are follower devices
				string ActiveDeviceListStringPath
				sprintf ActiveDeviceListStringPath, "%s:ActiveDeviceList" Path_ActiveITCDevicesFolder(panelTitle)
				Wave / z ActiveDeviceList = $ActiveDeviceListStringPath
				if(dimsize(ActiveDeviceList, 0) > 0) // if list is empty, there are no active devices.

					string ActiveDeviListDevIDGlobPathStr
					sprintf ActiveDeviListDevIDGlobPathStr, "%s:ActiveDeviceListDeviceIDGlobals"  Path_ActiveITCDevicesFolder(panelTitle)
					if(waveexists($ActiveDeviListDevIDGlobPathStr) == 1)
						redimension /N = 0 $ActiveDeviListDevIDGlobPathStr
					endif
					
					duplicate /o /r = [][0] ActiveDeviceList $ActiveDeviListDevIDGlobPathStr
					Wave ActiveDeviceListDeviceIDGlobals = $ActiveDeviListDevIDGlobPathStr
				
				
					// Make sure yoked devices have all completed data acq.  If all devices have completed data acq start RA_StartMD(panelTitle) on the lead device (ITC1600_dev_0)
					// root:MIES:ITCDevices:ActiveITCDevices:ActiveDeviceTextList NEED to make sure all yoked devices are inactive !!!!!!!!!!!!
					
					// check if lead device is still active
					string ITCDeviceIDGlobalPathString
					sprintf ITCDeviceIDGlobalPathString, "%s:ITCDeviceIDGlobal" HSU_DataFullFolderPathString("ITC1600_Dev_0")
					NVAR ITCDeviceIDGlobal = $ITCDeviceIDGlobalPathString
					FindLevel /P /Q ActiveDeviceListDeviceIDGlobals, ITCDeviceIDGlobal
					
					if(V_flag == 1) // ITCDeviceIDGlobal was found indicating the device is still active
						return 0
					endif
					
					// check if follower devices are still active
					for (i = 0; i < numberOfFollowerDevices; i += 1)
						string FollowerITC1600
						sprintf FollowerITC1600, "%s" stringfromlist(i, ListOfFollowerDevices, ";")
						sprintf ITCDeviceIDGlobalPathString, "%s:ITCDeviceIDGlobal" HSU_DataFullFolderPathString(FollowerITC1600)
						NVAR ITCDeviceIDGlobal = $ITCDeviceIDGlobalPathString
						FindLevel /P /Q ActiveDeviceListDeviceIDGlobals, ITCDeviceIDGlobal
						if(V_flag == 1) // ITCDeviceIDGlobal was found indicating the device is still active
							return 0
						endif
					endfor
				endif
				print "RA_StartMD(ITC1600_dev_0)"
				RA_StartMD("ITC1600_dev_0")
			
			elseif(numberOfFollowerDevices == 0) // there are no follower devices
				RA_StartMD(panelTitle)
			endif
		elseif(exists(pathToListOfFollowerDevices) == 0) // list of follower devices does not exist
			RA_StartMD(panelTitle)
		endif
	
	elseif(DeviceType != 2) // not a ITC1600, therefore there can be no follower devices
			RA_StartMD(panelTitle)
	endif	
End
//=========================================================================================

Function YokedRA_BckgTPwCallToRACounter(panelTitle) // if devices are yoked, RA_BckgTPwithCallToRACounterMD(panelTitle) gets called if the panel title is the same as the last follower device
	string panelTitle
	
	variable i = 0
	variable deviceType = 0

	variable ITC1600True = stringmatch(panelTitle, "*ITC1600*")
	if(ITC1600True == 1)
		deviceType = 2
	endif

	if(DeviceType == 2) // if the device is a ITC1600 i.e., capable of yoking
		string pathToListOfFollowerDevices = Path_ITCDevicesFolder(panelTitle) + ":ITC1600:Device0:ListOfFollowerITC1600s"
		SVAR /z ListOfFollowerDevices = $pathToListOfFollowerDevices
		if(exists(pathToListOfFollowerDevices) == 2) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist

			variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
			if(numberOfFollowerDevices != 0) 
				string ActiveDeviceListStringPath
				sprintf ActiveDeviceListStringPath, "%s:ActiveDeviceList" Path_ActiveITCDevicesFolder(panelTitle)
				Wave / z ActiveDeviceList = $ActiveDeviceListStringPath
				string ActiveDeviListDevIDGlobPathStr
				sprintf ActiveDeviListDevIDGlobPathStr, "%s:ActiveDeviceListDeviceIDGlobals"  Path_ActiveITCDevicesFolder(panelTitle)
				if(waveexists($ActiveDeviListDevIDGlobPathStr) == 1)
					redimension /N = 0 $ActiveDeviListDevIDGlobPathStr
				endif
				
				duplicate /o /r = [][0] ActiveDeviceList $ActiveDeviListDevIDGlobPathStr
				Wave ActiveDeviceListDeviceIDGlobals = $ActiveDeviListDevIDGlobPathStr
				
				if(dimsize(ActiveDeviceList, 0) > 0)
					// Make sure yoked devices have all completed data acq.  If all devices have completed data acq start RA_StartMD(panelTitle) on the lead device (ITC1600_dev_0)
					// root:MIES:ITCDevices:ActiveITCDevices:ActiveDeviceTextList NEED to make sure all yoked devices are inactive !!!!!!!!!!!!
						
					// check if lead device is still active
					string ITCDeviceIDGlobalPathString
					sprintf ITCDeviceIDGlobalPathString, "%s:ITCDeviceIDGlobal" HSU_DataFullFolderPathString("ITC1600_Dev_0")
					NVAR ITCDeviceIDGlobal = $ITCDeviceIDGlobalPathString
					FindLevel /P /Q ActiveDeviceListDeviceIDGlobals, ITCDeviceIDGlobal
					
					if(V_flag == 1) // ITCDeviceIDGlobal was found indicating the device is still active
						return 0
					endif
					
					// check if follower devices are still active
					for (i = 0; i < numberOfFollowerDevices; i += 1)
						string FollowerITC1600
						sprintf FollowerITC1600, "%s" stringfromlist(i, ListOfFollowerDevices, ";")
						sprintf ITCDeviceIDGlobalPathString, "%s:ITCDeviceIDGlobal" HSU_DataFullFolderPathString(FollowerITC1600)
						NVAR ITCDeviceIDGlobal = $ITCDeviceIDGlobalPathString
						FindLevel /P /Q ActiveDeviceListDeviceIDGlobals, ITCDeviceIDGlobal
						if(V_flag == 1) // ITCDeviceIDGlobal was found indicating the device is still active
							return 0
						endif
					endfor
				endif
				print "RA_BckgTPwithCallToRACounterMD(\"ITC1600_dev_0\")"
				RA_BckgTPwithCallToRACounterMD("ITC1600_dev_0")
				
			elseif(numberOfFollowerDevices == 0) // there are no follower devices
				 RA_BckgTPwithCallToRACounterMD(panelTitle)
			endif
		elseif(exists(pathToListOfFollowerDevices) == 0) // list of follower devices does not exist
			 RA_BckgTPwithCallToRACounterMD(panelTitle)
		endif
	elseif(DeviceType != 2) // not a ITC1600, therefore there can be no follower devices
			 RA_BckgTPwithCallToRACounterMD(panelTitle)
	endif	
End

//=========================================================================================

Function TP_TPSetUp(panelTitle) // prepares device for TP - use this procedure just prior to calling TP start - don't forget to reset the panel config for data acq following TP
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
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
		//  print "test pulse path = ", testpulsepath
		make /o /n = 0 $TestPulsePath
		wave TestPulse = $TestPulsePath
		SetScale /P x 0,0.005,"ms", TestPulse // test pulse wave made at max possible samp frequency
		
		// adjust test pulse wave according to panel input
		//TP_UpdateTestPulseWave(TestPulse, panelTitle)
	
		TP_UpdateTestPulseWaveChunks(TestPulse, panelTitle) // makes the test pulse wave that contains enought test pulses to fill the min ITC DAC wave size 2^17
		
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
		
		if(NewNoOfPoints ==   43690) // extra special exceptions for 3 channels - super BS coding right here.
			NewNoOfPoints = 2^15
		endif
		// print "divisor =",(deltaX(ITCDataWave) / 0.005)
		// print "new no of points =", NewNoOfPoints
		redimension /N =(NewNoOfPoints, -1, -1, -1) ITCDataWave
		
		wave TestPulseITC = $WavePath+":TestPulse:TestPulseITC"
		SCOPE_UpdateGraph(TestPulseITC,panelTitle)
		//ITC_StartBackgroundTestPulseMD(DeviceType, DeviceNum, panelTitle)
		ITC_ConfigUploadDAC(panelTitle)
		
		// open scope window
		controlinfo /w = $panelTitle check_Settings_ShowScopeWindow
		if(v_value == 0)
			DAP_SmoothResizePanel(340, panelTitle)
			setwindow $panelTitle + "#oscilloscope", hide = 0
		endif
	
End
//=========================================================================================
