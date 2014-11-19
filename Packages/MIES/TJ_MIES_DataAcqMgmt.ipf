#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// DATA ACQ MANAGEMENT - HANDLES MULTIPLE DEVICES INCLUDING YOKED DEVICES

/// @brief Handles function calls for data acquistion. These include calls for starting Yoked ITC1600s.
///
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
	DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)
	SCOPE_UpdateGraph(ITCDataWave, panelTitle)
	
	if(DeviceType == 2) // starts data acquisition for ITC1600 devices
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	
		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0) 
		// if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0) // allows ITC1600 devices that are not device 0 to work independently
			print "Data Acq started on independent ITC1600"
			ITC_ConfigUploadDAC(panelTitle)
			ITC_BkrdDataAcqMD(DeviceType, DeviceNum, TriggerMode, panelTitle)
		elseif(stringmatch(panelTitle, "ITC1600_Dev_0") == 1) // it is ITC1600 device 0; potentially the lead device for a group of yoked devices
			SVAR /z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_Exists(listOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
				numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
				if(numberOfFollowerDevices != 0) // List of yoked ITC1600 devices does contain 1 or more yoked ITC1600s
					ARDStartSequence() // runs the arduino once before it matters to make sure it is intialized - not sure if i need to do this
					do // LOOP that configures data and oscilloscope for data acquisition on all follower ITC1600 devices
						followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
						//print followerpaneltitle
						DC_ConfigureDataForITC(followerPanelTitle, DATA_ACQUISITION_MODE)
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
					print "Call to ITC_BkrdDataAcqMD; panel title of lead device:", panelTitle
					ITC_BkrdDataAcqMD(2, DeviceNum, TriggerMode, panelTitle) // starts data acq on Lead device
					
					do // LOOP that begins data acquistion follower ITC1600 devices
						followerPanelTitle = stringfromlist(i, ListOfFollowerDevices, ";")
						controlinfo /w = $panelTitle popup_moreSettings_DeviceNo // shouldn't this be follower panel title
						//controlinfo /w = $followerPanelTitle popup_moreSettings_DeviceNo // shouldn't this be follower panel title
						DeviceNum =  v_value - 1
						ITC_BkrdDataAcqMD(2, DeviceNum, TriggerMode, followerPanelTitle)
						i += 1
					while(i < numberOfFollowerDevices)
					controlinfo /w =$panelTitle Check_DataAcq1_RepeatAcq
					variable RepeatedAcqOnOrOff = v_value
	
					if(RepeatedAcqOnOrOff == 1)
					//	print "started timer"
						ITC_StartITCDeviceTimer(panelTitle) // starts a timer for lead  ITC device. Timer is used to do real time ITI timing.
					endif
					// activates trigger	
					print "DATA Acquisition initiated"				
					ARDStartSequence() // runs sequence already loaded on arduino - sequence and arduino hardware need to be set up manually!!!!!! THIS TRIGGERS THE YOKED ITC1600s
				elseif(numberOfFollowerDevices == 0) // No follower devices in global string that contains list of follower devices
					ITC_ConfigUploadDAC(panelTitle)
					ITC_BkrdDataAcqMD(DeviceType, DeviceNum, TriggerMode, panelTitle)
				endif
			else
				ITC_ConfigUploadDAC(panelTitle)
				ITC_BkrdDataAcqMD(DeviceType, DeviceNum, TriggerMode, panelTitle)
			endif
		endif	
	elseIf(DeviceType != 2) // starts data acquisition for non ITC1600 ITC devices
		ITC_ConfigUploadDAC(panelTitle)
		ITC_BkrdDataAcqMD(DeviceType, DeviceNum, TriggerMode, panelTitle)
	endif
	print "Data Acquisition took: ", (stopmstimer(-2) - start) / 1000, " ms"
End // Function
//=================================================================================================================

/// @brief Configures ITC DACs
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
/// @param deviceType Each ITC device has a DeviceType number: 0 through 5.
/// @param deviceNum Each locked ITC device has a number starting from zero for devices of that type. It is different from the device global ID.
///                  Ex. Two ITC18s would always have the device number 0 and 1 regardless of the number of other ITC devies connected of other types.
/// @param panelTitle panel title
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

	TP_UpdateTPBufferSizeGlobal(panelTitle)
	TP_ResetTPStorage(panelTitle)
	if(DeviceType == 2) // if the device is a ITC1600 i.e., capable of yoking
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	
		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0) 
//		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0) // if the device being started isn't device 0, then it isn't a yoked device. Therefore it starts on its own.
			print "TP Started on independent ITC1600"
			TP_TPSetUp(panelTitle)
			ITC_BkrdTPMD(DeviceType, DeviceNum, 0, panelTitle) // START TP DATA ACQUISITION
			wave SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
			wave SelectedDACScale = $(WavePath + ":SelectedDACScale")
			TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
			TP_RestoreDAScale(SelectedDACScale,panelTitle)	
		elseif(stringmatch(panelTitle, "ITC1600_Dev_0") == 1) 
			SVAR/Z ListOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_exists(ListOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
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
						TP_UpdateTPBufferSizeGlobal(followerPanelTitle)
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
			else
				TP_TPSetUp(panelTitle)
				ITC_BkrdTPMD(DeviceType, DeviceNum, 0, panelTitle) // START TP DATA ACQUISITION
				wave SelectedDACWaveList = $(WavePath + ":SelectedDACWaveList")
				wave SelectedDACScale = $(WavePath + ":SelectedDACScale")
				TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
				TP_RestoreDAScale(SelectedDACScale,panelTitle)		
			endif
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
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	
		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0) 
//		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0)
			print "Data Acquisition stopped on independent ITC1600"
			DAP_StopOngoingDataAcqMD(panelTitle)
		elseif(stringmatch(panelTitle, "ITC1600_Dev_0") == 1) 
			SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_Exists(listOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
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
			else
				DAP_StopOngoingDataAcqMD(panelTitle)
			endif
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
//print "ITCStopTP panel title = panelTitle:", panelTitle
if(ITC1600True == 1)
	deviceType = 2
endif
 
if(DeviceType == 2) // if the device is a ITC1600 i.e., capable of yoking
	controlinfo /w = $panelTitle setvar_Hardware_Status
	string ITCDACStatus = s_value	
	    if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0)  
	    // if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0)
	    	print "TP stopped on independent ITC1600"
          	ITC_StopTPMD(panelTitle)
           	ITC_FinishTestPulseMD(panelTitle)
 //         	ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values.

		else
			SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_Exists(listOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
	      		variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
	      		if(numberOfFollowerDevices != 0) 
	             	string followerPanelTitle
	                
	        
	              	//Lead board commands
	               	ITC_StopTPMD(panelTitle)
	               	ITC_FinishTestPulseMD(panelTitle)                // ITC_StopTPMD(panelTitle)
//				ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values.
	               	// DAP_StopOngoingDataAcqMD(panelTitle)
	               	//Follower board commands
	              do
	                   followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
	                   ITC_StopTPMD(followerPanelTitle)
	                   ITC_FinishTestPulseMD(followerPanelTitle)
//	                   ITC_TPDocumentation(followerPanelTitle) // documents the TP Vrest, peak and steady state resistance values.
                   i += 1
	              while(i < numberOfFollowerDevices)
	
	                
	           	elseif(numberOfFollowerDevices == 0)
	              	ITC_StopTPMD(panelTitle)
	              	ITC_FinishTestPulseMD(panelTitle)
//				ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values.
	               
	          	endif
			else
	          	ITC_StopTPMD(panelTitle)
	           	ITC_FinishTestPulseMD(panelTitle)
//			ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values.
         
	       endif
	endif	   
   elseif(DeviceType != 2)
            ITC_StopTPMD(panelTitle)
            ITC_FinishTestPulseMD(panelTitle)
//            ITC_TPDocumentation(panelTitle) // documents the TP Vrest, peak and steady state resistance values.
            // ITC_StopTPMD(panelTitle)
        
    endif
End

Function YokedRA_StartMD(panelTitle) // if devices are yoked, RA_StartMD is only called once the last device has finished the TP, and it is called for the lead device
	string panelTitle					// if devices are not yoked, it is the same as it would be if RA_StartMD was called directly


	variable i = 0
	variable deviceType = 0

	variable ITC1600True = stringmatch(panelTitle, "*ITC1600*")
	if(ITC1600True == 1)
		deviceType = 2
	endif

	if(DeviceType == 2) // if the device is a ITC1600 i.e., capable of yoking
	    	controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	
	    	if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0) // checks for ITC1600s of device numbers 1 or greater that are not followers
			print "RA started on independent ITC1600"
			RA_StartMD(panelTitle)
		else // receives any follower ITC1600s or Lead ITC1600
			// prevents data acquistion from being run on follower device first before another device has
			SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_Exists(listOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
				variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
				if(numberOfFollowerDevices != 0) // There are follower devices
					string ActiveDeviceListStringPath
					sprintf ActiveDeviceListStringPath, "%s:ActiveDeviceList" Path_ActiveITCDevicesFolder(panelTitle)
					Wave / z ActiveDeviceList = $ActiveDeviceListStringPath
					if(dimsize(ActiveDeviceList, 0) > 0) // if list is empty, there are no active devices.
						// so the list isn't empty (Active devices could included yoked ITC1600s or independent ITC devices of other types)
						string ActiveDeviListDevIDGlobPathStr
						sprintf ActiveDeviListDevIDGlobPathStr, "%s:ActiveDeviceListDeviceIDGlobals"  Path_ActiveITCDevicesFolder(panelTitle)
						if(waveexists($ActiveDeviListDevIDGlobPathStr) == 1) // if the wave exists, redimension to 0
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
							return 0 // breaks out of function
						endif
						
						// check if follower devices are still active 
						for (i = 0; i < numberOfFollowerDevices; i += 1)
							string FollowerITC1600
							sprintf FollowerITC1600, "%s" stringfromlist(i, ListOfFollowerDevices, ";")
							sprintf ITCDeviceIDGlobalPathString, "%s:ITCDeviceIDGlobal" HSU_DataFullFolderPathString(FollowerITC1600)
							NVAR ITCDeviceIDGlobal = $ITCDeviceIDGlobalPathString
							FindLevel /P /Q ActiveDeviceListDeviceIDGlobals, ITCDeviceIDGlobal
							if(V_flag == 1) // ITCDeviceIDGlobal was found indicating the device is still active
								return 0 // does not initiate data acquisition unless all follower devices have completed data acquistion
							endif
						endfor
					endif
					print "RA_StartMD(ITC1600_dev_0)" 
					RA_StartMD("ITC1600_dev_0") // This should run if the device is an ITC1600_Dev0 as a lead or independent, all other devices get initated elswhere in this function
				
				elseif(numberOfFollowerDevices == 0) // there are no follower devices
					RA_StartMD(panelTitle)
				endif
			else
				RA_StartMD(panelTitle)
			endif
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
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	
		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0)
			RA_BckgTPwithCallToRACounterMD(panelTitle)
		else
			SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_Exists(listOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
	
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
			else
				 RA_BckgTPwithCallToRACounterMD(panelTitle)
			endif
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
	
		DAP_StoreTTLState(panelTitle)
		print "TTL state of:", panelTitle, "stored" 
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
		TestPulsePath = GetWBSvdStimSetDAPathAsString() + ":TestPulse"
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
		DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE)
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
