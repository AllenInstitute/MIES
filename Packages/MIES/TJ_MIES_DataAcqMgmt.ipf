#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_DataAcqMgmt.ipf
/// @brief Data Acquisition Management - Handles multiple devices including yoked devices

/// @brief Handles function calls for data acquistion. These include calls for starting Yoked ITC1600s.
///
/// DAM_FunctionStartDataAcq determines what device is being started and begins aquisition in
/// the appropriate manner for the device
///
/// DAM_FunctionStartDataAcq is used when MD support is enabled in the settings tab of DA_ephys.
/// If MD is not enabled, alternate functions are used to run data acquisition.
///
/// Handles the calls to the data configurator (DC) functions and BackgroundMD
/// it is required because of the special handling syncronous ITC1600s require
Function DAM_FunctionStartDataAcq(panelTitle)
	string panelTitle
	Variable start = stopmstimer(-2)
	variable i
	variable TriggerMode = 0
	variable numberOfFollowerDevices = 0
	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	string followerPanelTitle = ""
	DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)
	SCOPE_CreateGraph(ITCDataWave, panelTitle)
	
	if(DAP_DeviceIsYokeable(panelTitle)) // starts data acquisition for ITC1600 devices
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	
		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0) 
			print "Data Acq started on independent ITC1600"
			DAM_ConfigUploadDAC(panelTitle)
			ITC_BkrdDataAcqMD(TriggerMode, panelTitle)
		elseif(DAP_DeviceCanLead(panelTitle)) // it is ITC1600 device 0; potentially the lead device for a group of yoked devices
			SVAR /z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_Exists(listOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
				numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
				if(numberOfFollowerDevices != 0) // List of yoked ITC1600 devices does contain 1 or more yoked ITC1600s
					ARDStartSequence() // runs the arduino once before it matters to make sure it is intialized - not sure if i need to do this
					do // LOOP that configures data and oscilloscope for data acquisition on all follower ITC1600 devices
						followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
						DC_ConfigureDataForITC(followerPanelTitle, DATA_ACQUISITION_MODE)
						WAVE ITCDataWave = GetITCDataWave(followerPanelTitle)
						SCOPE_CreateGraph(ITCDataWave, followerPanelTitle)
						i += 1
					while(i < numberOfFollowerDevices)
					i = 0
					TriggerMode = 256
					
					do // LOOP that preconfigures each DAC to
						followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
						DAM_ConfigUploadDAC(followerPanelTitle)
					i += 1
					while(i < numberOfFollowerDevices)
					
					i = 0
					DAM_ConfigUploadDAC(panelTitle) // configures lead device
					print "Call to ITC_BkrdDataAcqMD; panel title of lead device:", panelTitle
					ITC_BkrdDataAcqMD(TriggerMode, panelTitle) // starts data acq on Lead device
					
					do // LOOP that begins data acquistion follower ITC1600 devices
						followerPanelTitle = stringfromlist(i, ListOfFollowerDevices, ";")
						ITC_BkrdDataAcqMD(TriggerMode, followerPanelTitle)
						i += 1
					while(i < numberOfFollowerDevices)
					controlinfo /w =$panelTitle Check_DataAcq1_RepeatAcq
					variable RepeatedAcqOnOrOff = v_value
	
					if(RepeatedAcqOnOrOff == 1)
						ITC_StartITCDeviceTimer(panelTitle) // starts a timer for lead  ITC device. Timer is used to do real time ITI timing.
					endif
					// activates trigger	
					print "DATA Acquisition initiated"				
					ARDStartSequence() // runs sequence already loaded on arduino - sequence and arduino hardware need to be set up manually!!!!!! THIS TRIGGERS THE YOKED ITC1600s
				else
					DAM_ConfigUploadDAC(panelTitle)
					ITC_BkrdDataAcqMD(TriggerMode, panelTitle)
				endif
			else
				DAM_ConfigUploadDAC(panelTitle)
				ITC_BkrdDataAcqMD(TriggerMode, panelTitle)
			endif
		endif	
	else
		DAM_ConfigUploadDAC(panelTitle)
		ITC_BkrdDataAcqMD(TriggerMode, panelTitle)
	endif
	print "Data Acquisition took: ", (stopmstimer(-2) - start) / 1000, " ms"
End

/// @brief Configures ITC DACs
/// selects the ITC device based on the panelTitle passed into the function.
/// configures all the DAC channels at once using the ITCconfigAllChannels command
/// resets the DAC FIFOs using the ITCUpdateFIFOPositionAll command
static Function DAM_ConfigUploadDAC(panelTitle)
	string panelTitle

	NVAR ITCDeviceIDGlobal            = $GetITCDeviceIDGlobal(panelTitle)
	WAVE ITCDataWave                  = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave            = GetITCChanConfigWave(panelTitle)
	WAVE ITCFIFOPositionAllConfigWave = GetITCFIFOPositionAllConfigWave(panelTitle)

	string cmd
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperation(cmd)

	sprintf cmd, "ITCconfigAllchannels, %s, %s" GetWavesDataFolder(ITCChanConfigWave, 2), GetWavesDataFolder(ITCDataWave, 2)
	ExecuteITCOperation(cmd)
	
	sprintf cmd, "ITCUpdateFIFOPositionAll , %s" GetWavesDataFolder(ITCFIFOPositionAllConfigWave, 2) // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
	ExecuteITCOperation(cmd)
End

/// @brief Start the test pulse when MD support is activated.
///
/// Handles the TP initiation for all ITC devices. Yoked ITC1600s are handled specially using the external trigger.
/// The external trigger is assumed to be a arduino device using the arduino squencer.
Function DAM_StartTestPulseMD(panelTitle)
	string panelTitle
	string TestPulsePath
	variable i = 0
	variable DataAcqOrTP = 1
	variable TriggerMode
	variable NewNoOfPoints

	DFREF deviceDFR = GetDevicePath(panelTitle)

	TP_UpdateTPBufferSizeGlobal(panelTitle)
	TP_ResetTPStorage(panelTitle)
	if(DAP_DeviceIsYokeable(panelTitle))
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	
		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0) 
			print "TP Started on independent ITC1600"
			DAM_TPSetup(panelTitle)
			ITC_BkrdTPMD(0, panelTitle) // START TP DATA ACQUISITION
			WAVE/SDFR=deviceDFR SelectedDACWaveList
			TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
			WAVE/SDFR=deviceDFR SelectedDACScale
			TP_RestoreDAScale(SelectedDACScale,panelTitle)	
		elseif(DAP_DeviceCanLead(panelTitle))
			SVAR/Z ListOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_exists(ListOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
				variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
				if(numberOfFollowerDevices != 0) 
					ARDStartSequence()
					string followerPanelTitle
					
					do // configure follower device for TP acquistion
						followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
						DAM_TPSetup(followerPanelTitle)
						i += 1
					while(i < numberOfFollowerDevices)
					i = 0
					TriggerMode = 256

					//Lead board commands
					DAM_TPSetup(panelTitle)
					ITC_BkrdTPMD(TriggerMode, panelTitle) // Sets lead board in wait for trigger mode
					WAVE/SDFR=deviceDFR SelectedDACWaveList
					TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle) // restores lead board settings
					WAVE/SDFR=deviceDFR SelectedDACScale
					TP_RestoreDAScale(SelectedDACScale,panelTitle)
					
					//Follower board commands
					do
						followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")

						TP_UpdateTPBufferSizeGlobal(followerPanelTitle)
						ITC_BkrdTPMD(TriggerMode, followerPanelTitle) // Sets lead board in wait for trigger mode
						WAVE/SDFR=GetDevicePath(followerPanelTitle) SelectedDACWaveList
						TP_ResetSelectedDACWaves(SelectedDACWaveList,followerPanelTitle) // restores lead board settings
						WAVE/SDFR=GetDevicePath(followerPanelTitle) SelectedDACScale
						TP_RestoreDAScale(SelectedDACScale,followerPanelTitle)					
						i += 1
					while(i < numberOfFollowerDevices)
					
					// Arduino gives trigger
					ARDStartSequence()
					
				elseif(numberOfFollowerDevices == 0)
					DAM_TPSetup(panelTitle)
					ITC_BkrdTPMD(0, panelTitle) // START TP DATA ACQUISITION
					WAVE/SDFR=deviceDFR SelectedDACWaveList
					TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
					WAVE/SDFR=deviceDFR SelectedDACScale
					TP_RestoreDAScale(SelectedDACScale,panelTitle)
				endif
			else
				DAM_TPSetup(panelTitle)
				ITC_BkrdTPMD(0, panelTitle) // START TP DATA ACQUISITION
				WAVE/SDFR=deviceDFR SelectedDACWaveList
				TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
				WAVE/SDFR=deviceDFR SelectedDACScale
				TP_RestoreDAScale(SelectedDACScale,panelTitle)		
			endif
		endif
	else
		DAM_TPSetup(panelTitle)
		ITC_BkrdTPMD(0, panelTitle) // START TP DATA ACQUISITION
		WAVE/SDFR=deviceDFR SelectedDACWaveList
		TP_ResetSelectedDACWaves(SelectedDACWaveList,panelTitle)
		WAVE/SDFR=deviceDFR SelectedDACScale
		TP_RestoreDAScale(SelectedDACScale,panelTitle)
	endif
End

/// @brief Stop DAQ on yoked devices simultaneously
Function DAM_StopDataAcq(panelTitle)
	string panelTitle

	variable i

	if(DAP_DeviceIsYokeable(panelTitle)) // if the device is a ITC1600 i.e., capable of yoking
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	
		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0) 
			print "Data Acquisition stopped on independent ITC1600"
			DAP_StopOngoingDataAcqMD(panelTitle)
		elseif(DAP_DeviceCanLead(panelTitle))
			SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_Exists(listOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
				variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
				if(numberOfFollowerDevices != 0) 
					string followerPanelTitle
			
					//Lead board commands
					DAP_StopOngoingDataAcqMD(panelTitle)
					//Follower board commands
					do
						followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
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
	else
		DAP_StopOngoingDataAcqMD(panelTitle)
	endif
End

/// @brief Stop the TP on yoked devices simultaneously
Function DAM_StopTPMD(panelTitle)

	string panelTitle
	variable i = 0
 
	if(DAP_DeviceIsYokeable(panelTitle)) // if the device is a ITC1600 i.e., capable of yoking
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value
		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0)
			print "TP stopped on independent ITC1600"
			ITC_StopTPMD(panelTitle)
		else
			SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_Exists(listOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
				variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
				if(numberOfFollowerDevices != 0)
					string followerPanelTitle
	                
					//Lead board commands
					ITC_StopTPMD(panelTitle)
					do
						followerPanelTitle = stringfromlist(i,ListOfFollowerDevices, ";")
						ITC_StopTPMD(followerPanelTitle)
						i += 1
					while(i < numberOfFollowerDevices)
	                
				else
					ITC_StopTPMD(panelTitle)
				endif
			else
				ITC_StopTPMD(panelTitle)
			endif
		endif
	else
		ITC_StopTPMD(panelTitle)
	endif
End

/// @brief if devices are yoked, RA_StartMD is only called once the last device has finished the TP,
/// and it is called for the lead device if devices are not yoked, it is the same as it would be if
/// RA_StartMD was called directly
Function DAM_YokedRAStartMD(panelTitle)
	string panelTitle

	variable i

	if(DAP_DeviceIsYokeable(panelTitle)) // if the device is a ITC1600 i.e., capable of yoking
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
					Wave/Z/SDFR=GetActiveITCDevicesFolder() ActiveDeviceList
					if(dimsize(ActiveDeviceList, 0) > 0) // if list is empty, there are no active devices.
						// so the list isn't empty (Active devices could included yoked ITC1600s or independent ITC devices of other types)
						string ActiveDeviListDevIDGlobPathStr
						sprintf ActiveDeviListDevIDGlobPathStr, "%s:ActiveDeviceListDeviceIDGlobals"  GetActiveITCDevicesFolderAS()
						if(waveexists($ActiveDeviListDevIDGlobPathStr) == 1) // if the wave exists, redimension to 0
							redimension /N = 0 $ActiveDeviListDevIDGlobPathStr
						endif
						
						duplicate /o /r = [][0] ActiveDeviceList $ActiveDeviListDevIDGlobPathStr
						Wave ActiveDeviceListDeviceIDGlobals = $ActiveDeviListDevIDGlobPathStr
					
						// Make sure yoked devices have all completed data acq.  If all devices have completed data acq start RA_StartMD(panelTitle) on the lead device (ITC1600_dev_0)
						// root:MIES:ITCDevices:ActiveITCDevices:ActiveDeviceTextList NEED to make sure all yoked devices are inactive !!!!!!!!!!!!
						
						// check if lead device is still active
						NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal("ITC1600_Dev_0")
						FindLevel /P /Q ActiveDeviceListDeviceIDGlobals, ITCDeviceIDGlobal
						
						if(V_flag == 1) // ITCDeviceIDGlobal was found indicating the device is still active
							return 0 // breaks out of function
						endif
						
						// check if follower devices are still active 
						for (i = 0; i < numberOfFollowerDevices; i += 1)
							NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(StringFromList(i, ListOfFollowerDevices))
							FindLevel /P /Q ActiveDeviceListDeviceIDGlobals, ITCDeviceIDGlobal
							if(V_flag == 1) // ITCDeviceIDGlobal was found indicating the device is still active
								return 0 // does not initiate data acquisition unless all follower devices have completed data acquistion
							endif
						endfor
					endif
					print "RA_StartMD(ITC1600_dev_0)" 
					RA_StartMD("ITC1600_dev_0") // This should run if the device is an ITC1600_Dev0 as a lead or independent, all other devices get initated elswhere in this function
				
				else
					RA_StartMD(panelTitle)
				endif
			else
				RA_StartMD(panelTitle)
			endif
		endif
	else
		RA_StartMD(panelTitle)
	endif	
End

/// @brief If devices are yoked, RA_BckgTPwithCallToRACounterMD(panelTitle) gets called if the panel title is the same as the last follower device
Function DAM_YokedRABckgTPCallRACounter(panelTitle)
	string panelTitle

	variable i

	if(DAP_DeviceIsYokeable(panelTitle)) // if the device is a ITC1600 i.e., capable of yoking
		controlinfo /w = $panelTitle setvar_Hardware_Status
		string ITCDACStatus = s_value	
		if(stringmatch(panelTitle, "ITC1600_Dev_0") == 0 && stringmatch(ITCDACStatus, "Follower") == 0)
			RA_BckgTPwithCallToRACounterMD(panelTitle)
		else
			SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
			if(SVAR_Exists(listOfFollowerDevices)) // ITC1600 device with the potential for yoked devices - need to look in the list of yoked devices to confirm, but the list does exist
	
				variable numberOfFollowerDevices = itemsinlist(ListOfFollowerDevices)
				if(numberOfFollowerDevices != 0) 
					Wave/Z/SDFR=GetActiveITCDevicesFolder() ActiveDeviceList
					string ActiveDeviListDevIDGlobPathStr
					sprintf ActiveDeviListDevIDGlobPathStr, "%s:ActiveDeviceListDeviceIDGlobals"  GetActiveITCDevicesFolderAS()
					if(waveexists($ActiveDeviListDevIDGlobPathStr) == 1)
						redimension /N = 0 $ActiveDeviListDevIDGlobPathStr
					endif
					
					duplicate /o /r = [][0] ActiveDeviceList $ActiveDeviListDevIDGlobPathStr
					Wave ActiveDeviceListDeviceIDGlobals = $ActiveDeviListDevIDGlobPathStr
					
					if(dimsize(ActiveDeviceList, 0) > 0)
						// Make sure yoked devices have all completed data acq.  If all devices have completed data acq start RA_StartMD(panelTitle) on the lead device (ITC1600_dev_0)
						// root:MIES:ITCDevices:ActiveITCDevices:ActiveDeviceTextList NEED to make sure all yoked devices are inactive !!!!!!!!!!!!
							
						// check if lead device is still active
						NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal("ITC1600_Dev_0")
						FindLevel /P /Q ActiveDeviceListDeviceIDGlobals, ITCDeviceIDGlobal
						
						if(V_flag == 1) // ITCDeviceIDGlobal was found indicating the device is still active
							return 0
						endif
						
						// check if follower devices are still active
						for (i = 0; i < numberOfFollowerDevices; i += 1)
							NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(StringFromList(i, ListOfFollowerDevices))
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
	else
		 RA_BckgTPwithCallToRACounterMD(panelTitle)
	endif	
End

/// @brief Prepares device for TP - use this procedure just prior to calling TP start - don't forget to reset the panel config for data acq following TP
static Function DAM_TPSetup(panelTitle)
	string panelTitle

	string TestPulsePath
	DFREF deviceDFR = GetDevicePath(panelTitle)

	DAP_StoreTTLState(panelTitle)
	print "TTL state of:", panelTitle, "stored"
	DAP_TurnOffAllTTLs(panelTitle)

	// stores panel settings
	Make/O/N=8 deviceDFR:SelectedDACWaveList/Wave=SelectedDACWaveList
	TP_StoreSelectedDACWaves(SelectedDACWaveList, panelTitle)
	TP_SelectTestPulseWave(panelTitle)

	Make/O/N=8 deviceDFR:SelectedDACScale/Wave=SelectedDACScale
	TP_StoreDAScale(SelectedDACScale,panelTitle)
	TP_SetDAScaleToOne(panelTitle)

	WAVE TestPulse = GetTestPulse()
	TP_UpdateTestPulseWaveChunks(TestPulse, panelTitle) // makes the test pulse wave that contains enought test pulses to fill the min ITC DAC wave size 2^17

	NVAR duration = $GetTestpulseDuration(panelTitle)
	DM_CreateScaleTPHoldWaveChunk(panelTitle,0, duration)  // first TP so start point = 0

	// configures data for ITC with testpulse wave selected
	DC_ConfigureDataForITC(panelTitle, TEST_PULSE_MODE)
	// special mod for test pulse to ITC data wave that makes sure the entire TP is filled with test pulses because of how data is placed into the ITCDataWave based on sampling frequency
	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	variable NewNoOfPoints = floor(dimsize(ITCDataWave, 0) / (deltaX(ITCDataWave) / MINIMUM_SAMPLING_INTERVAL))

	if(NewNoOfPoints ==   43690) // extra special exceptions for 3 channels - super BS coding right here.
		NewNoOfPoints = 2^15
	endif
	redimension /N =(NewNoOfPoints, -1, -1, -1) ITCDataWave

	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	SCOPE_CreateGraph(TestPulseITC, panelTitle)
	DAM_ConfigUploadDAC(panelTitle)
	SCOPE_OpenScopeWindow(panelTitle)
End
