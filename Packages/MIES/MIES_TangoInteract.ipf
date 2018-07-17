#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TI
#endif

/// @file MIES_TangoInteract.ipf
/// @brief __TI__ Interface to the [tango](http://www.tango-controls.org/) layer

/// @cond DOXYGEN_IGNORES_THIS
#if exists("tango_open_device")// tango XOP has been found
/// @endcond

#include "tango"
#include "tango_monitor"

/// @brief function for recieving the command strings from the WSE
/// @param cmdString			format is "cmd_id:<id>|<cmd_string>"
Function TI_TangoCommandInput(cmdString)
	string cmdString
	
	variable cmdNumber
	string cmdID
	string cmdPortion
	string igorCmd
	string igorCmdPortion
	string completeIgorCommand
	
	// make sure the incoming cmdString has the cmd_id
	if(!((GrepString(cmdString, "cmd_id:"))))
		print "Command is not properly formatted..."
		abort
	endif
	
	cmdNumber = ItemsInList(cmdString, "|")
	
	// the first portion of the cmdString should be the "cmd_id:<id>"
	cmdPortion = StringFromList(0, cmdString, "|")
	// now parse out the cmd_id
	sscanf cmdPortion, "cmd_id:%s", cmdID
	
	// the second portion of the cmdString should be the "cmd_string"
	igorCmd = StringFromList(1, cmdString, "|")
	
	// now strip the trailing ")" off the end of the igorCmd
	igorCmdPortion = StringFromList(0, igorCmd, ")")
	
	// and append the cmdNumber and the trailing ")"
	sprintf completeIgorCommand, "%s, cmdID=\"%s\")", igorCmdPortion, cmdID

	// now call the command 
	Execute/Z completeIgorCommand
	if(V_Flag != 0)
		print "Unable to run command....check command syntax..."
		TI_WriteAck(cmdID, -1)
	else
		print "Command ran successfully..."
	endif
End	

/// @brief function for opening da_ephys panel remotely from the WSE
/// @param placeHolder -- a dummy variable needed for making this command work with the TangoCommandInput call from the WSE
/// @param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_OpenDAPanel(placeHolder, [cmdID])
	variable placeHolder
	string cmdID
	
	// run the open DA_Ephys panel command
	DAP_CreateDAEphysPanel()
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif
End

/// @brief function for selecting the device number from the WSE
/// @param devNumber -- device number, set from the WSE
/// @param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_selectDeviceNumber(devNumber, [cmdID])
	variable devNumber
	string cmdID
	
	// Not the most elegant thing, but we know what the popup menu always is
	PGC_SetAndActivateControl(BASE_WINDOW_TITLE, "popup_moreSettings_DeviceNo", val=devNumber)
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif
End

/// @brief function for selecting the ITC18USB device
/// @param placeHolder -- a dummy variable needed for making this command work with the TangoCommandInput call from the WSE
/// @param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_selectITCDevice(placeHolder, [cmdID])
	variable placeHolder
	string cmdID
	
	// Not the most elegant thing, but we know what the popup menu always is
	PGC_SetAndActivateControl(BASE_WINDOW_TITLE, "popup_MoreSettings_DeviceType", val=5)
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif
End

/// @brief function for locking the device selection
/// @param placeHolder -- a dummy variable needed for making this command work with the TangoCommandInput call from the WSE
/// @param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_lockITCDevice(placeHolder, [cmdID])
	variable placeHolder
	string cmdID
	
	string lockDevButton = "button_SettingsPlus_LockDevice"
	
	// Lock the ITC device
	PGC_SetAndActivateControl(BASE_WINDOW_TITLE, lockDevButton)
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif
End

/// @brief function for querying the connected amps
/// @param placeHolder -- a dummy variable needed for making this command work with the TangoCommandInput call from the WSE
/// @param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_queryAmps(placeHolder, [cmdID])
	variable placeHolder
	string cmdID

	AI_FindConnectedAmps()

	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif
End

/// @brief function for loading UserConfig.txt
/// @param placeHolder -- a dummy variable needed for making this command work with the TangoCommandInput call from the WSE
/// @param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_loadConfig(placeHolder, [cmdID])
	variable placeHolder
	string cmdID

	ExpConfig_ConfigureMIES()

	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif
End
		
/// @brief function for querying the connected amps
/// @param ampChannel -- amplifier channel to be connected by the WSE 
/// @param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_selectAmpChannel(ampChannel, [cmdID])
	variable ampChannel
	string cmdID
	
	// Not the most elegant thing, but we know what the popup menu always is
	// if need be, we can have the WSE pass which amp channel we want, but we'll just always go with the first channel for now
	PGC_SetAndActivateControl("ITC18USB_Dev_0", "popup_Settings_Amplifier", val=ampChannel)
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif
End	

/// @brief function for hitting the autofill button
/// @param headstage -- headstage to be used in pipeline experiments and set via the WSE
/// @param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_autoFillAmps(headstage, [cmdID])
	variable headstage
	string cmdID

	string panelTitle = "ITC18USB_Dev_0"
	string controlTitle = "button_Hardware_AutoGainAndUnit"
	
	PGC_SetAndActivateControl(panelTitle, controlTitle)
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif
End

/// @brief function for selecting the headstage
/// @param headstage -- headstage to be used in pipeline experiments and selected via the WSE
/// @param cmdID		[optional, defaults to blank] if function is called from WSE, this will be present.
Function TI_selectHeadStage(headstage, [cmdID])
	variable headstage
	string cmdID

	string panelTitle = "ITC18USB_Dev_0"
	string headStageCheckBox
	
	headStageCheckBox = GetPanelControl(headstage, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)	

	PGC_SetAndActivateControl(panelTitle, headStageCheckBox, val=1)
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif
End

/// @brief function for saving data space in the nwb format, to be invoked from the WSE
/// @param nwbFileLocation	complete file path for nwb save file
/// @param cmdID			[optional, defaults to blank] if called from WSE, this will be present.
Function TI_saveNWBFile(nwbFileLocation, [cmdID])
	string nwbFileLocation
	string cmdID
	
	string changeFilePath
	string fileName
	
	changeFilePath = nwbFileLocation
	
	print "Saving experiment data in NWB format to ", changeFilePath

	NWB_ExportAllData(overrideFilePath=changeFilePath)
	CloseNWBFile()

	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 0)
	endif 
End

/// @brief Return the string containing the location of the saved NWB formatted data file.
/// @param cmdID	optional parameter...if being called from WSE, this will be present.
Function TI_returnNWBFileLocation([cmdID])
	string cmdID
	
	string responseString
	
	// Get the file location value
	SVAR fileValue =$GetNWBFilePathExport()	
	
	// build up the response string
	responseString = "nwbSaveFileLocation:" + fileValue
	
	// see if a cmdID was passed
	if(!ParamIsDefault(cmdID))
		// write the ack back to the WSE
		TI_WriteAck(cmdID, 1)
		
		// and now call the async function to return the value
		TI_WriteAsyncResponse(cmdID, responseString)
	else
		print "no WSE response required"
		print responseString
	endif 
End
	
	
/// @brief Save Mies Experiment as a packed experiment.  This saves the entire Tango data space.  Will be supplimented in the future with a second function that will save the Sweep Data only.
/// @param saveFileName		file name for the saved packed experiment
/// @param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_TangoSave(saveFileName, [cmdID])
	string saveFileName
	string cmdID

	variable err

	try
		SaveExperiment/C/F={1,"",2}/P=home as saveFileName + ".pxp"; AbortOnRTE
		print "Packed Experiment Save Success!"
	catch
		err = GetRTError(1)
		print "Could not save into packed experiment file. Failure!"
		printf "Error %d, Message \"%s\"\r", err, GetErrMessage(err)
	endtry

	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 1)
	endif
End

/// @brief load initial settings into the MCC for use with the pipeline rigs
/// @param headstage 		headstage to be configured
/// @param cmdID	optional parameter...if being called from WSE, this will be present.
Function TI_ConfigureMCCforIVSCC(headstage, [cmdID])
	string cmdID
	variable headstage

	variable initResult, oldTab
	variable numErrors
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	string responseString

	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)

	// make sure the MCC is valid
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)

		// explicitly switch to the data acquistion tab to avoid having
		// the control layout messed up
		oldTab = GetTabID(currentPanel, "ADC")
		PGC_SetAndActivateControl(currentPanel, "ADC", val=0)

		initResult = AI_SelectMultiClamp(currentPanel, headstage)
		if(initResult != AMPLIFIER_CONNECTION_SUCCESS)
			print "MCC not valid...cannot initialize Amplifier Settings"
			numErrors += 1
		else
			// Do Current Clamp stuff
			// switch to IC
			PGC_SetAndActivateControl(currentPanel, DAP_GetClampModeControl(I_CLAMP_MODE, headstage), val=CHECKBOX_SELECTED)

			initResult = AI_SendToAmp(currentPanel, headstage, I_CLAMP_MODE, MCC_SETBRIDGEBALENABLE_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting Bridge Balance Enable to off"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, I_CLAMP_MODE,  MCC_SETNEUTRALIZATIONCAP_FUNC, 0.0)
			if(!IsFinite(initResult))
				print "Error setting Neutralization Cap to 0.0"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, I_CLAMP_MODE, MCC_SETNEUTRALIZATIONENABL_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting Neutralization Enable to off"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, I_CLAMP_MODE, MCC_SETSLOWCURRENTINJENABL_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting  SlowCurrentInjEnable to off"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, I_CLAMP_MODE, MCC_SETSLOWCURRENTINJLEVEL_FUNC, 0.0)
			if(!IsFinite(initResult))
				print "Error setting SlowCurrentInjLevel to 0"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, I_CLAMP_MODE, MCC_SETSLOWCURRENTINJSETLT_FUNC, 1)
			if(!IsFinite(initResult))
				print "Error setting SlowCurrentInjSetlTime to 1 second"
				numErrors += 1
			endif

			// these commands work for both IC and VC...here's the IC part
			initResult = AI_SendToAmp(currentPanel, headstage, I_CLAMP_MODE, MCC_SETHOLDING_FUNC, 0.0)
			if(!IsFinite(initResult))
				print "Error setting Holding Voltage to 0.0"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, I_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting Holding Enable to off"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, I_CLAMP_MODE, MCC_SETOSCKILLERENABLE_FUNC, 1)
			if(!IsFinite(initResult))
				print "Error setting OscKillerEnable to on"
				numErrors += 1
			endif

			// switch to VC
			PGC_SetAndActivateControl(currentPanel, DAP_GetClampModeControl(V_CLAMP_MODE, headstage), val=CHECKBOX_SELECTED)

			// These commands work with both current clamp and voltage clamp...so now do the voltage clamp mode
			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETHOLDING_FUNC, 0.0)
			if(!IsFinite(initResult))
				print "Error setting Holding Voltage to 0.0"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting Holding Enable to off"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETOSCKILLERENABLE_FUNC, 1)
			if(!IsFinite(initResult))
				print "Error setting OscKillerEnable to on"
				numErrors += 1
			endif

			// Voltage Clamp Mode only settings
			initResult =  AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETRSCOMPCORRECTION_FUNC, 0.0)
			if(!IsFinite(initResult))
				print "Error setting RsCompCorrection to 0"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETRSCOMPENABLE_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting RsCompEnable to off"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETRSCOMPPREDICTION_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting RsCompPrediction to off"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETSLOWCOMPTAUX20ENAB_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting SlowCompTauX20Enable to off"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETRSCOMPBANDWIDTH_FUNC, 0.0)
			if(!IsFinite(initResult))
				print "Error setting RsCompBandwidth to 0"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPCAP_FUNC, 0.0)
			if(!IsFinite(initResult))
				print "Error setting WholeCellCompCap to 0"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPENABLE_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting  WholeCellCompEnable to off"
				numErrors += 1
			endif

			initResult = AI_SendToAmp(currentPanel, headstage, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPRESIST_FUNC, 0)
			if(!IsFinite(initResult))
				print "Error setting WholeCellCompResist to 0"
				numErrors += 1
			endif
		endif

		if(oldTab != 0)
			PGC_SetAndActivateControl(currentPanel, "ADC", val=oldTab)
		endif
	endfor

	// build up the response string
	sprintf responseString, "ampConfigErrorCount:%d",  numErrors

	// see if a cmdID was passed
	if(!ParamIsDefault(cmdID))
		// and now call the async function to return the value
		TI_WriteAck(cmdID, 1)
		TI_WriteAsyncResponse(cmdID, responseString)
	else
		print "no WSE response required"
		print responseString
	endif
End

/// @brief run the baseline QC check from the WSE.  This will zero the amp using the pipette offset function call, and look at the baselineSSAvg, already calculated during the TestPulse.  
/// The EXTPINBATH wave will also be run as a way of making sure the baseline is recorded into the data set for post-experiment analysis
Function TI_runBaselineCheckQC(headstage, [cmdID])
	variable headstage
	
	string cmdID
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	string waveSelect 
	string StimWaveName = "EXTPINBATH*"
	string foundStimWave
	string bathStimWave
	variable baselineValue
	string ListOfWavesInFolder
	variable incomingWaveIndex
	variable baselineAverage
	variable qcResult
	variable adChannel
	string responseString
	variable cycleNum
	
	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
		DFREF dfr = GetDeviceTestPulse(currentPanel)
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value		
		waveSelect = GetPanelControl(headstage, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		
		// build up the list of available wave sets
		ListOfWavesInFolder = ReturnListOfAllStimSets(0, CHANNEL_DA_SEARCH_STRING)
		
		// find the stim wave that matches EXTPINBATH...can have date and DA number attached to the end
		foundStimWave = ListMatch(ListOfWavesInFolder, StimWaveName)
		bathStimWave = ReplaceString(";", foundStimWave, "")
		
		// make sure that the EXTPBREAKN is a valid wave name
		if(FindListItem(bathStimWave, ListOfWavesInFolder) == -1)
			print "EXTPINBATH* wave not loaded...please load and try again..."
			if(!ParamIsDefault(cmdID))
				// build up the response string
				TI_WriteAck(cmdID, 1)
				sprintf responseString, "qcResult:%f", qcResult
				TI_WriteAsyncResponse(cmdID, responseString)
			endif
			return 0
		endif
		
		// now find the index of the selected incoming wave in that list
		incomingWaveIndex = WhichListItem(bathStimWave, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 1 since the pulldown always has -none- as option
		PGC_SetAndActivateControl(currentPanel, waveSelect, val=incomingWaveIndex + 1)
		
		// Check to see if Test Pulse is already running...if not running, turn it on...
		if(!TP_CheckIfTestpulseIsRunning(currentPanel))
			PGC_SetAndActivateControl(currentPanel,"StartTestPulseButton")
		endif

		// and now hit the Auto pipette offset
		AI_UpdateAmpModel(currentPanel, "button_DataAcq_AutoPipOffset_VC", headStage)
		
		// Set up the QC Wave so the background task can get the information it needs
		Wave/T QCWave = GetQCWaveRef(currentPanel)
		QCWave[%headstage] = num2str(headstage)
		
		if(!ParamIsDefault(cmdID))
			QCWave[%cmdID] = cmdID
		else
			QCWave[%cmdID] = "foobar"
		endif
		
		if(!ParamIsDefault(cmdID))
			TI_WriteAck(cmdID, 1)
		endif
		// start the background task
		TI_StartBckgrdBaselineQCCheck()
	endfor
End

/// @brief Run the Baseline QC check in the background
Function TI_StartBckgrdBaselineQCCheck()
	CtrlNamedBackground TI_finishBaselineQCCheck, period=2, proc=TI_finishBaselineQCCheck
	CtrlNamedBackground TI_finishBaselineQCCheck, start
End

/// @brief Complete the Baseline QC check in the background
///
/// @ingroup BackgroundFunctions
Function TI_finishBaselineQCCheck(s)
	STRUCT WMBackgroundStruct &s

	string currentPanel

	variable headstage
	string cmdID
	string lockedDevList
	variable noLockedDevs
	variable cycles

	variable baselineAverage
	variable qcResult
	variable adChannel
	string responseString

	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)

	//this is a hack, but we know that for using this QC function we only have one locked device
	currentPanel = StringFromList(0, lockedDevList)

	Wave/T QCWave = GetQCWaveRef(currentPanel)
	headstage = str2num(QCWave[%headstage])
	cmdID =  QCWave[%cmdID]

	cycles = 5 //define how many cycles the test pulse must run
	if(TP_TestPulseHasCycled(currentPanel,cycles))
		print "Enough Cycles passed..."
	else
		return 0
	endif

	// grab the baseline avg value
	DFREF dfr = GetDeviceTestPulse(currentPanel)
	WAVE/SDFR=dfr BaselineSSAvg // wave that contains the baseline Vm from the TP

	adChannel = TP_GetTPResultsColOfHS(currentPanel, headstage)

	ASSERT(adChannel >= 0, "Could not query AD channel")
	baselineAverage = BaselineSSAvg[0][adChannel]

	print "baseline Average: ", baselineAverage

	// See if we pass the baseline QC
	if (abs(baselineAverage) < 100.0)
		PGC_SetAndActivateControl(currentPanel, "DataAcquireButton")
		qcResult = baselineAverage
	endif
	
	print "qcResult: ", qcResult
	
	// determine if the cmdID was provided
	if(cmpstr(cmdID,"foobar") != 0)
		// build up the response string
		sprintf responseString, "qcResult:%f", qcResult
		TI_WriteAsyncResponse(cmdID, responseString)
	endif

	return 1
End

/// @brief Run the Electrode Drift QC check
///
/// @param headstage    device
/// @param expTime      in minutes, from the WSE, from the start of the experiment
/// @param cmdID        optional parameter...if being called from WSE, this will be present.
Function TI_runElectrodeDriftQC(headstage, expTime, [cmdID])
	variable headstage
	variable expTime
	
	string cmdID
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	string waveSelect 
	string StimWaveName = "EXTPBLWOUT*"
	string foundStimWave
	string blowoutStimWave
	variable baselineValue
	string psaMenu
	string paaMenu
	string psaCheck
	string paaCheck
	string ListOfWavesInFolder
	string psaFuncList
	variable psaFuncIndex
	variable incomingWaveIndex
	variable startInstResistanceVal
	variable currentInstResistanceVal
	variable qcResult = 0
	variable adChannel
	variable meanValue
	string responseString
	
	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
		
		Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(currentPanel)
		
		// put the elapsed time value into the ActionScaleSettingsWave for use with the analysis framework
		Wave actionScaleSettingsWave =  GetActionScaleSettingsWaveRef(currentPanel)
		actionScaleSettingsWave[headStage][%elapsedTime] = expTime
		
		DFREF dfr = GetDeviceTestPulse(currentPanel)
		
		// get the reference to the asyn response wave ref 
		Wave/T asynRespWave = GetAsynRspWaveRef(currentPanel)
		// and put the cmdID there, if passed one
		if(ParamIsDefault(cmdID) == 0)
			asynRespWave[headstage][%cmdID] = cmdID
		endif
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value		
		waveSelect = GetPanelControl(headstage, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		
		// and build up the analysis master connections
		sprintf psaMenu, "PSA_headStage%d", headstage
		sprintf paaMenu, "PAA_headStage%d", headstage
		sprintf psaCheck, "headStage%d_postSweepAnalysisOn", headstage
		sprintf paaCheck, "headStage%d_postAnalysisActionOn", headstage
		
		// build up the list of available wave sets
		ListOfWavesInFolder = ReturnListOfAllStimSets(0, CHANNEL_DA_SEARCH_STRING)
		
		// find the stim wave that matches EXTPINBATH...can have date and DA number attached to the end
		foundStimWave = ListMatch(ListOfWavesInFolder, StimWaveName)
		blowoutStimWave = ReplaceString(";", foundStimWave, "")
		
		// make sure that the EXTPBREAKN is a valid wave name
		if(FindListItem(blowoutStimWave, ListOfWavesInFolder) == -1)
			print "EXTPBLWOUT* wave not loaded...please load and try again..."
			if(!ParamIsDefault(cmdID))
				TI_WriteAck(cmdID, 1)
				// build up the response string
				sprintf responseString, "qcResult:%d", qcResult
				TI_WriteAsyncResponse(cmdID, responseString)
			endif
			return 0
		endif
		
		// now find the index of the selected incoming wave in that list
		incomingWaveIndex = WhichListItem(blowoutStimWave, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 1 since the pulldown always has -none- as option
		PGC_SetAndActivateControl(currentPanel, waveSelect, val=incomingWaveIndex + 1)
				
		// look at the instResistance already saved in the lab notebook.  This should be the InstResistance from the start of the experiment.
		WAVE/SDFR=dfr InstResistance // wave that contains the Initial Access Resistance from the TP
		
		adChannel = TP_GetTPResultsColOfHS(currentPanel, headstage)
		startInstResistanceVal = InstResistance[0][adChannel]
		
		// Check to see if Test Pulse is already running...if not running, turn it on...
		if(!TP_CheckIfTestpulseIsRunning(currentPanel))
			PGC_SetAndActivateControl(currentPanel,"StartTestPulseButton")
		endif

		// and grab the initial resistance avg value again
		WAVE/SDFR=dfr InstResistance // wave that contains the Initial Access Resistance from the TP
		
		adChannel = TP_GetTPResultsColOfHS(currentPanel, headstage)
		currentInstResistanceVal = InstResistance[0][adChannel]		
		
		print "Current Access Resistance: ", currentInstResistanceVal
		
		//check that the current inst resistance value is within a specificed % of the startInstResistanceValue, currently defined as 10%
		if ((abs(currentInstResistanceVal) >= (1.10*(abs(startInstResistanceVal)))) || (abs(currentInstResistanceVal) >= (1.10*(abs(startInstResistanceVal)))))
			print "InstResistance Value does not match from beginning of the experiment...please clear the pipette and try again..."
			if(!ParamIsDefault(cmdID))
				TI_WriteAck(cmdID, 1)
				// build up the response string
				sprintf responseString, "qcResult:%f", qcResult
				TI_WriteAsyncResponse(cmdID, responseString)
			endif
			return 0
		endif
		
		// switch to IC
		PGC_SetAndActivateControl(currentPanel, DAP_GetClampModeControl(I_CLAMP_MODE, headstage), val=CHECKBOX_SELECTED)
		
		// and now disable the holding current
		PGC_SetAndActivateControl(currentPanel, "check_DatAcq_HoldEnable", val=CHECKBOX_UNSELECTED)
		
		//  disable the bridge balance
		PGC_SetAndActivateControl(currentPanel, "check_DatAcq_BBEnable", val=CHECKBOX_UNSELECTED)
		
		// disable the cap comp
		PGC_SetAndActivateControl(currentPanel, "check_DatAcq_CNEnable", val=CHECKBOX_UNSELECTED)
		
		// push the PSA_waveName into the right place
		// find the index for for the psa routine
		psaFuncList = AM_PS_sortFunctions()
		psaFuncIndex = WhichListItem("electrodeBaselineQC", psaFuncList, ";")
		PGC_SetAndActivateControl("analysisMaster", psaMenu, val=psaFuncIndex)
	
		// do the on/off check boxes for consistency
		SetCheckBoxState("analysisMaster", psaCheck, 1)
		SetCheckBoxState("analysisMaster", paaCheck, 0)
		
		// insure that the on/off parts of analysisSettingsWave are on...
		analysisSettingsWave[headstage][%PSAOnOff] = "1"
		analysisSettingsWave[headstage][%PAAOnOff] = "0"
		
		// and put the full psa function into the analysisSettingsWave...putting it as the correct item into the popmenu widget doesn't push it into wave
		analysisSettingsWave[headstage][%PSAType] = "electrodeBaselineQC"
		
		// now start the sweep process
		print "pushing the start button..."
		// now start the sweep process
		PGC_SetAndActivateControl(currentPanel, "DataAcquireButton")
	endfor
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 1)
		// build up the response string
		sprintf responseString, "qcResult:%f", qcResult
		TI_WriteAsyncResponse(cmdID, responseString)
	endif
End

/// @brief run the initial access resistance check from the WSE.  This will check must be < 20MOhm or 15% of the R input.
/// The EXTPBREAKN wave will also be run as a way of making sure the reading is recorded into the data set for post-experiment analysis
Function TI_runInitAccessResisQC(headstage, [cmdID])
	variable headstage

	string cmdID
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	string waveSelect
	string StimWaveName = "EXTPBREAKN*"
	string foundStimWave
	string breakinStimWave
	variable baselineValue
	string ListOfWavesInFolder
	variable incomingWaveIndex
	variable instResistanceVal
	variable ssResistanceVal
	variable qcResult
	variable adChannel
	variable tpBufferSetting
	string responseString

	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)

	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
		DFREF dfr = GetDeviceTestPulse(currentPanel)

		// pop the itc panel window to the front
		DoWindow /F $currentPanel

		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value
		waveSelect = GetPanelControl(headstage, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)

		// build up the list of available wave sets
		ListOfWavesInFolder = ReturnListOfAllStimSets(0, CHANNEL_DA_SEARCH_STRING)
		
		// find the stim wave that matches EXTPBREAKN...can have date and DA number attached to the end
		foundStimWave = ListMatch(ListOfWavesInFolder, StimWaveName)
		breakinStimWave = ReplaceString(";", foundStimWave, "")
		
		// make sure that the EXTPBREAKN is a valid wave name
		if(FindListItem(breakinStimWave, ListOfWavesInFolder) == -1)
			print "EXTPBREAKN* wave not loaded...please load and try again..."
			if(!ParamIsDefault(cmdID))
				TI_WriteAck(cmdID, 1)
				// build up the response string
				sprintf responseString, "qcResult:%f", qcResult
				TI_WriteAsyncResponse(cmdID, responseString)
			endif
			return 0
		endif

		// now find the index of the selected incoming wave in that list
		incomingWaveIndex = WhichListItem(breakinStimWave, ListOfWavesInFolder, ";")

		// and now set the wave popup menu to that index
		// have to add 1 since the pulldown always has -none- as option
		PGC_SetAndActivateControl(currentPanel, waveSelect, val=incomingWaveIndex + 1)

		// save the current test pulse buffer setting
		tpBufferSetting = GetSetVariable(currentPanel,"setvar_Settings_TPBuffer")

		// set the test pulse buffer up to a higher value to account for noise...using 5 for now
		PGC_SetAndActivateControl(currentPanel,"setvar_Settings_TPBuffer", val = 5)

		// Check to see if Test Pulse is already running...if not running, turn it on...
		if(!TP_CheckIfTestpulseIsRunning(currentPanel))
			PGC_SetAndActivateControl(currentPanel,"StartTestPulseButton")
		endif

		// Set up the QC Wave so the background task can get the information it needs
		Wave/T QCWave = GetQCWaveRef(currentPanel)
		QCWave[%headstage] = num2str(headstage)

		if(!ParamIsDefault(cmdID))
			QCWave[%cmdID] = cmdID
		else
			QCWave[%cmdID] = "foobar"
		endif

		QCWave[%tpBuffer] = num2str(tpBufferSetting)

		if(!ParamIsDefault(cmdID))
			TI_WriteAck(cmdID, 1)
		endif

		// start the background task
		TI_StartBckgrdInitAccessQCCheck()
	endfor
End

/// @brief Complete the Init Resistance QC check in the background
Function TI_StartBckgrdInitAccessQCCheck()
	CtrlNamedBackground TI_finishInitAccessQCCheck, period=2, proc=TI_finishInitAccessQCCheck
	CtrlNamedBackground TI_finishInitAccessQCCheck, start
End

/// @brief Complete the Baseline QC check in the background
///
/// @ingroup BackgroundFunctions
Function TI_finishInitAccessQCCheck(s)
	STRUCT WMBackgroundStruct &s

	string currentPanel

	variable headstage
	string cmdID
	string lockedDevList
	variable noLockedDevs
	variable cycles

	variable instResistanceVal, ssResistanceVal, tpBufferSetting
	variable qcResult
	variable adChannel
	string responseString

	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)

	//this is a hack, but we know that for using this QC function we only have one locked device
	currentPanel = StringFromList(0, lockedDevList)

	Wave/T QCWave = GetQCWaveRef(currentPanel)
	headstage = str2num(QCWave[%headstage])
	cmdID =  QCWave[%cmdID]
	tpBufferSetting = str2num(QCWave[%tpBuffer])

	cycles = 5 //define how many cycles the test pulse must run
	if(TP_TestPulseHasCycled(currentPanel,cycles))
		print "Enough Cycles passed..."
	else
		return 0
	endif

	// and grab the initial resistance avg value
	DFREF dfr = GetDeviceTestPulse(currentPanel)
	WAVE/SDFR=dfr InstResistance // wave that contains the Initial Access Resistance from the TP

	// and get the steady state resistance
	WAVE/SDFR=dfr SSResistance

	adChannel = TP_GetTPResultsColOfHS(currentPanel, headstage)
	ASSERT(adChannel >= 0, "Could not query AD channel")
	instResistanceVal = InstResistance[0][adChannel]
	ssResistanceVal = SSResistance[0][adChannel]

	print "Initial Access Resistance: ", instResistanceVal
	print "SS Resistance: ", ssResistanceVal

	// See if we pass the baseline QC
	if ((instResistanceVal<20.0) && (instResistanceVal < (.15*ssResistanceVal)))		
		qcResult = instResistanceVal
	endif

	// and now run the EXTPBREAKN wave so that things are saved into the data record
	PGC_SetAndActivateControl(currentPanel, "DataAcquireButton")

	print "qcResult: ", qcResult

	// set the test pulse buffer back to 1
	PGC_SetAndActivateControl(currentPanel,"setvar_Settings_TPBuffer", val = tpBufferSetting)

	// determine if the cmdID was provided
	if(stringmatch(cmdID,"foobar") != 1)
		// build up the response string
		sprintf responseString, "qcResult:%f", qcResult
		TI_WriteAsyncResponse(cmdID, responseString)
	endif

	return 1
End

///@brief run the Core StimSet Waves from the WSE, as part of the PatchSeq experiment.
///@param headstage		headstage to be used
///@param stimName 		coreSetWave to be run
///@param cmdID        optional parameter...if being called from WSE, this will be present.
Function TI_runCoreStimSet(headstage, stimName, [cmdID])
	variable headstage
	string stimName
	
	string cmdID
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	string waveSelect 
	string stimWaveName		
	string foundStimWave
	string attStimWave
	variable baselineValue
	string ListOfWavesInFolder
	variable incomingWaveIndex
	variable ssResistanceVal
	variable adChannel
	variable err
	string responseString

	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
		DFREF dfr = GetDeviceTestPulse(currentPanel)
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value		
		waveSelect = GetPanelControl(headstage, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		
		try
			PGC_SetAndActivateControl(currentPanel, waveSelect, str = stimName + "*"); AbortOnRTE
		catch
			err = GetRTError(1)
			print "Requested wave not loaded...please load and try again..."

			if(!ParamIsDefault(cmdID))
				TI_WriteAck(cmdID, 1)
				TI_WriteAsyncResponse(cmdID, "coreStimSetResult:0")
			endif

			return 0
		endtry
		
		// Check to see if Test Pulse is already running...if not running, turn it on...
		if(!TP_CheckIfTestpulseIsRunning(currentPanel))
			PGC_SetAndActivateControl(currentPanel,"StartTestPulseButton")
		endif
		
		// Set up the QC Wave so the background task can get the information it needs
		Wave/T CoreStimWave = GetCoreStimWaveRef(currentPanel)
		CoreStimWave[%headstage] = num2str(headstage)
		
		if(!ParamIsDefault(cmdID))
			CoreStimWave[%cmdID] = cmdID
		else
			CoreStimWave[%cmdID] = "foobar"
		endif

		if(!ParamIsDefault(cmdID))
			TI_WriteAck(cmdID, 1)
		endif
		
		// run the wave
		PGC_SetAndActivateControl(currentPanel,"DataAcquireButton")
		
		// start the background task
		TI_StartBckgrdRunCoreStimSet()
	endfor
End

/// @brief Complete the RunCoreStimSet in the background

Function TI_StartBckgrdRunCoreStimSet()
	CtrlNamedBackground TI_finishRunCoreStimSet, period=30, proc=TI_finishRunCoreStimSet
	CtrlNamedBackground TI_finishRunCoreStimSet, start
End

/// @brief finish the RunCoreStimSet in the background
///
/// @ingroup BackgroundFunctions
Function TI_finishRunCoreStimSet(s)
	STRUCT WMBackgroundStruct &s

	string currentPanel
	variable headstage
	string cmdID
	string lockedDevList
	variable noLockedDevs
	variable sweepNo
	string key

	variable setPassed
	string responseString

	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)

	//this is a hack, but we know that for using this QC function we only have one locked device
	currentPanel = StringFromList(0, lockedDevList)

	Wave/T CoreStimWave = GetCoreStimWaveRef(currentPanel)
	headstage = str2num(CoreStimWave[%headstage])
	cmdID =  CoreStimWave[%cmdID]

	// check that data acquisition is not running
	NVAR dataAcqRunMode = $GetDataAcqRunMode(currentPanel)
	if(dataAcqRunMode != DAQ_NOT_RUNNING)
		printf "Data Acquisition ongoing on %s \r" currentPanel
		return 0
	endif

	// set up the references to get the Set passed result
	WAVE numericalValues = GetLBNumericalValues(currentPanel)

	sweepNo = AFH_GetLastSweepAcquired(currentPanel)
	
	key = PSQ_CreateLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndepRAC(numericalValues, sweepNo, key, UNKNOWN_MODE)
	if (setPassed == 1)
		print "Set Passed"
	else
		print "Set Failed"
	endif
	
	// determine if the cmdID was provided
	if(cmpstr(cmdID,"foobar") != 0)
		// build up the response string
		sprintf responseString, "coreStimSetResult:%f", setPassed
		TI_WriteAsyncResponse(cmdID, responseString)
	endif

	return 1
End

///@brief routine to be called from the WSE to use a one step scale adjustment to find the scale factor that causes and AP firing
///@param stimWaveName		stimWaveName to be used
///@param initScaleFactor			initial scale factor to start with
///@param scaleFactor			scale factor adjustment value
///@param threshold				threshold value to indicate AP firing
///@param headstage				headstage to be used
///@param cmdID					optional parameter...if being called from WSE, this will be present.  
Function/S TI_runAdaptiveStim(stimWaveName, initScaleFactor, scaleFactor, threshold, headstage, [cmdID])
	string stimWaveName
	variable initScaleFactor
	variable scaleFactor
	variable threshold
	variable headstage

	string cmdID
	
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	string waveSelect 
	string psaMenu
	string paaMenu
	string psaCheck
	string paaCheck
	string scaleWidgetName
	string ListOfWavesInFolder
	variable incomingWaveIndex
	string psaFuncList
	variable psaFuncIndex
	string paaFuncList
	variable paaFuncIndex
	
	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
	
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(currentPanel)
		Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(currentPanel)
		
		// get the reference to the asyn response wave ref 
		Wave/T asynRespWave = GetAsynRspWaveRef(currentPanel)
		// and put the cmdID there, if you were passed one
		if(ParamIsDefault(cmdID) == 0)
			asynRespWave[headstage][%cmdID] = cmdID
		endif
		
		// put the scaleDelta in the  actionscalesettings wave
		actionScaleSettingsWave[headStage][%coarseScaleValue] = scaleFactor
		// reset the result value before starting the cycle
		actionScaleSettingsWave[headStage][%result] = 0
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value		
		sprintf waveSelect, "Wave_DA_%02d", headstage
		sprintf psaMenu, "PSA_headStage%d", headstage
		sprintf paaMenu, "PAA_headStage%d", headstage
		sprintf psaCheck, "headStage%d_postSweepAnalysisOn", headstage
		sprintf paaCheck, "headStage%d_postAnalysisActionOn", headstage
		sprintf scaleWidgetName, "Scale_DA_%02d", headStage
		
		// build up the list of available wave sets
		ListOfWavesInFolder = ReturnListOfAllStimSets(0, CHANNEL_DA_SEARCH_STRING)
		
		// make sure that the incoming StimWaveName is a valid wave name
		if(FindListItem(StimWaveName, ListOfWavesInFolder) == -1)
			print "Not a valid wave selection...please try again..."
			return "RETURN: -1"
		endif
		
		// now find the index of the selected incoming wave in that list
		incomingWaveIndex = WhichListItem(StimWaveName, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 1 since the pulldown always has -none- as option
		PGC_SetAndActivateControl(currentPanel, waveSelect, val=incomingWaveIndex + 1)
	
		// push the PSA_waveName into the right place
		// find the index for for the psa routine 
		// do this if the window actually exists
		ASSERT(WindowExists(amPanel), "Analysis master panel must exist")

		psaFuncList = AM_PS_sortFunctions()
		psaFuncIndex	 = WhichListItem("returnActionPotential", psaFuncList)
		PGC_SetAndActivateControl("analysisMaster", psaMenu, val=psaFuncIndex)
		
		// push the PAA_waveName into the right place
		// find the index for for the psa routine
		paaFuncList = AM_PA_sortFunctions()
		paaFuncIndex = WhichListItem("adjustScaleFactor", paaFuncList, ";")
		PGC_SetAndActivateControl("analysisMaster", paaMenu, val=paaFuncIndex)
	
		// do the on/off check boxes for consistency
		SetCheckBoxState("analysisMaster", psaCheck, 1)
		SetCheckBoxState("analysisMaster", paaCheck, 1)
		
		// insure that the on/off parts of analysisSettingsWave are on...
		analysisSettingsWave[headstage][%PSAOnOff] = "1"
		analysisSettingsWave[headstage][%PAAOnOff] = "1"
		
		// and put the full psa function into the analysisSettingsWave...putting it as the correct item into the popmenu widget doesn't push it into wave
		analysisSettingsWave[headstage][%PSAType] = "returnActionPotential"
		analysisSettingsWave[headstage][%PAAType] = "adjustScaleFactor"

		// turn on the repeated acquisition
		PGC_SetAndActivateControl(currentPanel, "Check_DataAcq1_RepeatAcq", val = 1)
		
		// put the delta in the right place 
		actionScaleSettingsWave[headstage][%coarseScaleValue] = scaleFactor
		
		// put the threshold value in the right place
		actionScaleSettingsWave[headstage][%apThreshold] = threshold

		// make sure the analysisResult is set to 0
		analysisSettingsWave[headstage][%PSAResult] = "0"

		// put the init Scale factor where it needs to go
		PGC_SetAndActivateControl(currentPanel, scaleWidgetName, val = initScaleFactor)

		PGC_SetAndActivateControl(currentPanel, "DataAcquireButton")
	endfor

	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 1)
	endif
End

/// @brief run the GigOhm seal QC check from the WSE.  This will make sure the Steady State resistance must be > 1.0 GOhm . 
/// The EXTPCIIATT wave will also be run as a way of making sure the baseline is recorded into the data set for post-experiment analysis
Function TI_runGigOhmSealQC(headstage, [cmdID])
	variable headstage
	
	string cmdID
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	string waveSelect 
	string StimWaveName = "EXTPCllATT*"		//NOTE!  The l character found in this wave name is a lower case l
	string foundStimWave
	string attStimWave
	variable baselineValue
	string ListOfWavesInFolder
	variable incomingWaveIndex
	variable ssResistanceVal
	variable qcResult
	variable adChannel
	string responseString

	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
		DFREF dfr = GetDeviceTestPulse(currentPanel)
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value		
		waveSelect = GetPanelControl(headstage, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		
		// build up the list of available wave sets
		ListOfWavesInFolder = ReturnListOfAllStimSets(0, CHANNEL_DA_SEARCH_STRING)
		
		// find the stim wave that matches EXTPCIIATT...can have date and DA number attached to the end
		foundStimWave = ListMatch(ListOfWavesInFolder, StimWaveName)
		print "foundStimWave: ", foundStimWave
		attStimWave = ReplaceString(";", foundStimWave, "")
		
		// make sure that the  EXTPCllATT is a valid wave name
		if(FindListItem(attStimWave, ListOfWavesInFolder) == -1)
			print " EXTPCllATT* wave not loaded...please load and try again..."
			if(!ParamIsDefault(cmdID))
				TI_WriteAck(cmdID, 1)
				// build up the response string
				sprintf responseString, "qcResult:%f", qcResult
				TI_WriteAsyncResponse(cmdID, responseString)
			endif
			return 0
		endif

		// now find the index of the selected incoming wave in that list
		incomingWaveIndex = WhichListItem(attStimWave, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 1 since the pulldown always has -none- as option
		PGC_SetAndActivateControl(currentPanel, waveSelect, val=incomingWaveIndex + 1)
		
		// Check to see if Test Pulse is already running...if not running, turn it on...
		if(!TP_CheckIfTestpulseIsRunning(currentPanel))
			PGC_SetAndActivateControl(currentPanel,"StartTestPulseButton")
		endif
		
		// Set up the QC Wave so the background task can get the information it needs
		Wave/T QCWave = GetQCWaveRef(currentPanel)
		QCWave[%headstage] = num2str(headstage)
		
		if(!ParamIsDefault(cmdID))
			QCWave[%cmdID] = cmdID
		else
			QCWave[%cmdID] = "foobar"
		endif

		if(!ParamIsDefault(cmdID))
			TI_WriteAck(cmdID, 1)
		endif
		// start the background task
		TI_StartBckgrdGigOhmSealQCCheck()
	endfor
End

/// @brief Complete the Gig Ohm Seal QC check in the background
Function TI_StartBckgrdGigOhmSealQCCheck()
	CtrlNamedBackground TI_finishGigOhmSealQCCheck, period=2, proc=TI_finishGigOhmSealQCCheck
	CtrlNamedBackground TI_finishGigOhmSealQCCheck, start
End

/// @brief finish the Gig Ohm Seal QC in the background
///
/// @ingroup BackgroundFunctions
Function TI_finishGigOhmSealQCCheck(s)
	STRUCT WMBackgroundStruct &s

	string currentPanel
	variable headstage
	string cmdID
	string lockedDevList
	variable noLockedDevs
	variable cycles

	variable ssResistanceVal
	variable qcResult
	variable adChannel
	string responseString

	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)

	//this is a hack, but we know that for using this QC function we only have one locked device
	currentPanel = StringFromList(0, lockedDevList)

	Wave/T QCWave = GetQCWaveRef(currentPanel)
	headstage = str2num(QCWave[%headstage])
	cmdID =  QCWave[%cmdID]

	cycles = 10 //define how many times the test pulse must run
	if(TP_TestPulseHasCycled(currentPanel, cycles))
		print "Enough Cycles passed..."
	else
		return 0
	endif

	// and grab the Steady State Resistance
	DFREF dfr = GetDeviceTestPulse(currentPanel)
	WAVE/Z/SDFR=dfr SSResistance // wave that contains the Steady State Resistance from the TP

	adChannel = TP_GetTPResultsColOfHS(currentPanel, headstage)
	ASSERT(adChannel >= 0, "Could not query AD channel")
	ssResistanceVal = SSResistance[0][adChannel]
		
	print "Steady State Resistance: ", ssResistanceVal
		
	// See if we pass the Steady State Resistance
	//  added a second pass....if we don't pass the QC on the first go, check again before you fail out of the QC
	try
		if(ssResistanceVal > 1000)  // ssResistance value is in MOhms
			// and now run the EXTPCIIATT wave so that things are saved into the data record	
			PGC_SetAndActivateControl(currentPanel, "DataAcquireButton")
			qcResult = ssResistanceVal
		else
			print "Below QC threshold...will repeat QC test..."
			abort
		endif
	catch
		ssResistanceVal = SSResistance[0][adChannel]
			
		print "Second Pass: Steady State Resistance: ", ssResistanceVal
			
		if(ssResistanceVal > 1000)  // ssResistance value is in MOhms
			qcResult = ssResistanceVal
		endif

		PGC_SetAndActivateControl(currentPanel, "DataAcquireButton") // Run the EXTPCIIATT wave so that things are saved into the data record
	endtry
	
	print "qcResult: ", qcResult
	
	// determine if the cmdID was provided
	if(stringmatch(cmdID,"foobar") != 1)
		// build up the response string
		sprintf responseString, "qcResult:%f", qcResult
		TI_WriteAsyncResponse(cmdID, responseString)
	endif

	return 1
End
		
		
///@brief routine to be called from the WSE to run a 2 step bracketing algorithm to find the scale factor that causes the AP to fire
///@param stimWaveName		stimWaveName to be used
///@param coarseScaleFactor		coarse scale adjustment factor
///@param fineScaleFactor			fine scale adjustment factor
///@param threshold				threshold for AP firing
///@param headstage				headstage to use
///@param cmdID					optional parameter...if being called from WSE, this will be present.
Function/S TI_runBracketingFunction(stimWaveName, coarseScaleFactor, fineScaleFactor, threshold, headstage, [cmdID])
	string stimWaveName
	variable coarseScaleFactor
	variable fineScaleFactor
	variable threshold
	variable headstage
	string cmdID
	
	string savedDataFolder
	string lockedDevList
	variable noLockedDevs
	string waveSelect 
	string psaMenu
	string paaMenu
	string psaCheck
	string paaCheck
	string scaleWidgetName
	string ListOfWavesInFolder
	variable incomingWaveIndex
	string psaFuncList
	variable psaFuncIndex	
	string paaFuncList
	variable paaFuncIndex
	
	// save the present data folder
	//savedDataFolder = GetDataFolder(1)
	
	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	for(n = 0; n<noLockedDevs; n+= 1)
		string currentPanel = StringFromList(n, lockedDevList)
	
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(currentPanel)
		Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(currentPanel)
		
		// put the coarse scale factor in the  actionscalesettings wave
		actionScaleSettingsWave[headStage][%coarseScaleValue] = coarseScaleFactor
		// put the fine scale factor in the  actionscalesettings wave
		actionScaleSettingsWave[headStage][%fineScaleValue] = fineScaleFactor
		// put the threshold in the  actionscalesettings wave
		actionScaleSettingsWave[headStage][%apThreshold] = threshold
		// reset the result value before starting the cycle
		actionScaleSettingsWave[headStage][%result] = 0
		
		// get the reference to the asyn response wave ref 
		Wave/T asynRespWave = GetAsynRspWaveRef(currentPanel)
		// and put the cmdID there, if passed one
		if(ParamIsDefault(cmdID) == 0)
			asynRespWave[headstage][%cmdID] = cmdID
		endif
		
		// push the waveSet to the ephys panel		
		sprintf waveSelect, "Wave_DA_0%d", headstage
		sprintf psaMenu, "PSA_headStage%d", headstage
		sprintf paaMenu, "PAA_headStage%d", headstage
		sprintf psaCheck, "headStage%d_postSweepAnalysisOn", headstage
		sprintf paaCheck, "headStage%d_postAnalysisActionOn", headstage
		sprintf scaleWidgetName, "Scale_DA_0%0d", headStage
		
		// build up the list of available wave sets
		ListOfWavesInFolder = ReturnListOfAllStimSets(0, CHANNEL_DA_SEARCH_STRING)
		
		// make sure that the incoming StimWaveName is a valid wave name
		if(FindListItem(StimWaveName, ListOfWavesInFolder) == -1)
			print "Not a valid wave selection...please try again..."
			return "RETURN: -1"
		endif
		
		// now find the index of the selected incoming wave in that list
		incomingWaveIndex = WhichListItem(StimWaveName, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 1 since the pulldown always has -none- as option
		PGC_SetAndActivateControl(currentPanel, waveSelect, val=incomingWaveIndex + 1)
	
		// push the PSA_waveName into the right place
		// find the index for for the psa routine 
		// do this if the window actually exists
		ASSERT(WindowExists(amPanel), "Analysis master panel must exist")

		psaFuncList = AM_PS_sortFunctions()
		psaFuncIndex	 = WhichListItem("returnActionPotential", psaFuncList, ";")
		PGC_SetAndActivateControl("analysisMaster", psaMenu, val=psaFuncIndex)
		
		// push the PAA_waveName into the right place
		// find the index for for the psa routine
		paaFuncList = AM_PA_sortFunctions()
		paaFuncIndex = WhichListItem("bracketScaleFactor", paaFuncList, ";")
		PGC_SetAndActivateControl("analysisMaster", paaMenu, val=paaFuncIndex)
	
		// do the on/off check boxes for consistency
		SetCheckBoxState("analysisMaster", psaCheck, 1)
		SetCheckBoxState("analysisMaster", paaCheck, 1)
		
		// insure that the on/off parts of analysisSettingsWave are on...
		analysisSettingsWave[headstage][%PSAOnOff] = "1"
		analysisSettingsWave[headstage][%PAAOnOff] = "1"
		
		// and put the full psa function into the analysisSettingsWave...putting it as the correct item into the popmenu widget doesn't push it into wave
		analysisSettingsWave[headstage][%PSAType] = "returnActionPotential"
		analysisSettingsWave[headstage][%PAAType] = "bracketScaleFactor"
		
		// turn on the repeated acquisition
		PGC_SetAndActivateControl(currentPanel, "Check_DataAcq1_RepeatAcq", val = 1)

		// make sure the analysisResult is set to 0
		analysisSettingsWave[headstage][%PSAResult] = "0"

		PGC_SetAndActivateControl(currentPanel, "DataAcquireButton")
	endfor
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 1)
	endif
End

///@brief routine to be called from the WSE to run a designated stim wave
///@param stimWaveName		stimWaveName to be used
///@param scaleFactor			scale factor to run the stim wave at
///@param headstage				headstage to use
///@param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_runStimWave(stimWaveName, scaleFactor, headstage, [cmdID])
	string stimWaveName
	variable scaleFactor
	variable headstage
	string cmdID
	
	string lockedDevList
	variable noLockedDevs
	string currentPanel
	string waveSelect 
	string scaleWidgetName
	string FolderPath
	string folder
	string ListOfWavesInFolder
	
	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
	
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value	
		sprintf waveSelect, "Wave_DA_%02d", headstage
		sprintf scaleWidgetName, "Scale_DA_%02d", headStage
		
		// build up the list of available wave sets
		ListOfWavesInFolder = ReturnListOfAllStimSets(0, CHANNEL_DA_SEARCH_STRING)
		
		// make sure that the incoming StimWaveName is a valid wave name
		if(FindListItem(StimWaveName, ListOfWavesInFolder) == -1)
			print "Not a valid wave selection...please try again..."
			// determine if the cmdID was provided
			if(ParamIsDefault(cmdID) == 0)	
				TI_WriteAck(cmdID, -1)
			endif
		endif
		
		// now find the index of the selected incoming wave in that list
		variable incomingWaveIndex = WhichListItem(StimWaveName, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 1 since the pulldown always has -none- as option
		PGC_SetAndActivateControl(currentPanel, waveSelect, val=incomingWaveIndex + 1)
		
		// put the scale in the right place 
		PGC_SetAndActivateControl(currentPanel, scaleWidgetName, val = scaleFactor)
		PGC_SetAndActivateControl(currentPanel, "DataAcquireButton")
	endfor
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))	
		TI_WriteAck(cmdID, 0)
	endif
End

///@brief routine to be called from the WSE to see if the Action Potential has fired
///@param headstage		indicate which headstage to look for the AP
///@param cmdID					optional parameter...if being called from WSE, this will be present.
Function/S TI_runAPResult(headstage, [cmdID])
	variable headstage
	string cmdID
	
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	variable apResult
	string returnResult
	
	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n < noLockedDevs; n += 1)
		currentPanel = StringFromList(n, lockedDevList)
	
		Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(currentPanel)		
		apResult = AM_PSA_returnActionPotential(currentPanel, headstage)
		
		// return the ActionPotential Result
		sprintf returnResult, "RETURN: %s" analysisSettingsWave[headstage][%PSAResult]
		print returnResult
	endfor
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))	
		TI_WriteAck(cmdID, 1)
	endif
End

///@brief routine to be called from the WSE to start and stop the test pulse
///@param tpCmd		1 to turn on Test Pulse, 0 to turn off Test Pulse
///@param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_runTestPulse(tpCmd, [cmdID])
	variable tpCmd
	string cmdID
	
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	variable returnValue
	
	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
		
		if(tpCmd == 1)	// Turn on the test pulse

			TPS_StartTestPulseSingleDevice(currentPanel)

			returnValue = 0
		elseif(tpCmd == 0) // Turn off the test pulse
			TPS_StopTestPulseSingleDevice(currentPanel)
			returnValue = 0
		else
			returnValue = -1
		endif
	endfor

	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))	
		TI_WriteAck(cmdID, returnValue)
	endif
End

///@brief Routine to test starting and stopping acquisition by remotely hitting the start/stop button on the DA_Ephys panel
///@param cmdID					optional parameter...if being called from WSE, this will be present.
Function TI_runStopStart([cmdID])
	string cmdID
	
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	
	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)

		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		PGC_SetAndActivateControl(currentPanel, "DataAcquireButton")
	endfor

	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 1)
	endif
End

/// @brief Write the acknowledgement string back to the WSE
/// @param cmdID		cmdID number to be sent back to WSE
/// @param returnValue	returnValue number to be sent back to the WSE...0 means acknowledged, -1 means failure
Function TI_WriteAck(cmdID, returnValue)
	string cmdID
	Variable returnValue
	
	String logMessage
	String dev_name
	String cmd
	Variable mst_ref
	Variable mst_dt
		
	// put the response string together...
	sprintf logMessage, "cmd_id:%s;response:%d", cmdID, returnValue 
	print "logMessage: ", logMessage
	
	//- function arg: the name of the device on which the commands will be executed 
	dev_name = "mies_device/MiesDevice/test"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	cmd = "post_ack"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = logMessage
  
	mst_ref = StartMSTimer
    
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if(tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)		
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	print "\t'-> ack sent\r"
End

/// @brief Write async responses back to the WSE
/// @param cmdID   		saved cmdID identifier number to be returned to the WSE
/// @param returnString 	string containing all return values to be sent back to the WSE
Function TI_WriteAsyncResponse(cmdID, returnString)
	String cmdID
	String returnString
	
	String responseMessage
	variable numberOfReturnItems
	String dev_name
	String cmd
	Variable mst_ref
	Variable mst_dt
		
	numberOfReturnItems = ItemsInList(returnString)
	
	// put the response string together...
	sprintf responseMessage, "cmd_id:%s;%s", cmdID, returnString
	print "responseMessage: ", responseMessage
	
	//- function arg: the name of the device on which the commands will be executed 
	dev_name = "mies_device/MiesDevice/test"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev>
	cmd = "post_response"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = responseMessage
  
	mst_ref = StartMSTimer
    
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if(tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)		
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	print "\t'-> async response sent\r"	
End

/// @cond DOXYGEN_IGNORES_THIS
#endif
/// @endcond
