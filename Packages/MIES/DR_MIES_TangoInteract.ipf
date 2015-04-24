#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "tango"
#include "tango_monitor"

/// @brief function for recieving the command strings from the WSE
/// @param cmdString			format is "cmd_id:<id>;<cmd_string>"
Function TI_TangoCommandInput(cmdString)
	string cmdString
	
	variable cmdNumber
	string cmdID
	string cmdPortion
	string igorCmd
	string igorCmdPortion
	string completeIgorCommand
	
	// make sure the incoming cmdString has the cmd_id and a TI function call
	if(!((GrepString(cmdString, "cmd_id:")) && (GrepString(cmdString, "TI_"))))
		print "Command is not properly formatted..."
		abort
	endif
	
	cmdNumber = ItemsInList(cmdString)
	
	// the first portion of the cmdString should be the "cmd_id:<id>"
	cmdPortion = StringFromList(0, cmdString)
	// now parse out the cmd_id
	sscanf cmdPortion, "cmd_id:%s", cmdID
	
	// the second portion of the cmdString should be the "cmd_string"
	igorCmd = StringFromList(1, cmdString)
	
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

/// @brief Save Mies Experiment as a packed experiment.  This saves the entire Tango data space.  Will be supplimented in the future with a second function that will save the Sweep Data only.
/// @param saveFileName		file name for the saved packed experiment
Function TI_TangoSave(saveFileName, [cmdID])
	string saveFileName
	string cmdID
	
	//save as packed experiment
	SaveExperiment/C/F={1,"",2}/P=home as saveFileName + ".pxp"
	print "Packed Experiment Save Success!"
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 1)
	endif
End

///@brief routine to be called from the WSE to use a one step scale adjustment to find the scale factor that causes and AP firing
///@param stimWaveName		stimWaveName to be used
///@param initScaleFactor			initial scale factor to start with
///@param scaleFactor			scale factor adjustment value
///@param threshold				threshold value to indicate AP firing
///@param headstage				headstage to be used
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
	string FolderPath
	string folder
	string ListOfWavesInFolder
	variable incomingWaveIndex
	string psaFuncList
	variable psaFuncIndex
	string paaFuncList
	variable paaFuncIndex
	
	// get the da_ephys panel names
	lockedDevList = DAP_ListOfLockedDevs()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
	
		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
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
		FolderPath = GetWBSvdStimSetDAPathAsString()
		folder = "*DA*"
		setdatafolder FolderPath // sets the wavelist for the DA popup menu to show all waves in DAC folder
		ListOfWavesInFolder = Wavelist(Folder,";","") 
		
		// make sure that the incoming StimWaveName is a valid wave name
		if(FindListItem(StimWaveName, ListOfWavesInFolder) == -1)
			print "Not a valid wave selection...please try again..."
			return "RETURN: -1"
		endif
		
		// now find the index of the selected incoming wave in that list
		incomingWaveIndex = WhichListItem(StimWaveName, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 2 since the pulldown always has -none- and TestPulse as options
		SetPopupMenuIndex(currentPanel, waveSelect, incomingWaveIndex + 2)  
	
		// push the PSA_waveName into the right place
		// find the index for for the psa routine 
		// do this if the window actually exists
		ASSERT(WindowExists(amPanel), "Analysis master panel must exist")

		psaFuncList = AM_PS_sortFunctions()
		psaFuncIndex	 = WhichListItem("returnActionPotential", psaFuncList)
		SetPopupMenuIndex("analysisMaster", psaMenu, psaFuncIndex)
		
		// push the PAA_waveName into the right place
		// find the index for for the psa routine
		paaFuncList = AM_PA_sortFunctions()
		paaFuncIndex = WhichListItem("adjustScaleFactor", paaFuncList, ";")
		SetPopupMenuIndex("analysisMaster", paaMenu, paaFuncIndex)
	
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
		SetCheckBoxState(currentPanel, "Check_DataAcq1_RepeatAcq", 1)
		
		// put the delta in the right place 
		actionScaleSettingsWave[headstage][%coarseScaleValue] = scaleFactor
		
		// put the threshold value in the right place
		actionScaleSettingsWave[headstage][%apThreshold] = threshold
		
		// make sure the analysisResult is set to 0
		analysisSettingsWave[headstage][%PSAResult] = "0"
		
		// put the init Scale factor where it needs to go
		SetSetVariable(currentPanel, scaleWidgetName, initScaleFactor)
		
		// now start the sweep process
		print "pushing the start button..."
		// now start the sweep process
		// setting the ba structure
		ba.eventCode = 2
		ba.ctrlName = "DataAcquireButton"
		ba.win = currentPanel
		
		DAP_ButtonProc_AcquireData(ba)
	endfor
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		TI_WriteAck(cmdID, 1)
	endif
End

///@brief routine to be called from the WSE to run a 2 step bracketing algorithm to find the scale factor that causes the AP to fire
///@param stimWaveName		stimWaveName to be used
///@param coarseScaleFactor		coarse scale adjustment factor
///@param fineScaleFactor			fine scale adjustment factor
///@param threshold				threshold for AP firing
///@param headstage				headstage to use
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
	string FolderPath
	string folder
	string ListOfWavesInFolder
	variable incomingWaveIndex
	string psaFuncList
	variable psaFuncIndex	
	string paaFuncList
	variable paaFuncIndex
	
	// save the present data folder
	//savedDataFolder = GetDataFolder(1)
	
	// get the da_ephys panel names
	lockedDevList = DAP_ListOfLockedDevs()
	noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	for(n = 0; n<noLockedDevs; n+= 1)
		string currentPanel = StringFromList(n, lockedDevList)
	
		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
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
		FolderPath = GetWBSvdStimSetDAPathAsString()
		folder = "*DA*"
		setdatafolder FolderPath // sets the wavelist for the DA popup menu to show all waves in DAC folder
		ListOfWavesInFolder = Wavelist(Folder,";","") 
		
		// make sure that the incoming StimWaveName is a valid wave name
		if(FindListItem(StimWaveName, ListOfWavesInFolder) == -1)
			print "Not a valid wave selection...please try again..."
			return "RETURN: -1"
		endif
		
		// now find the index of the selected incoming wave in that list
		incomingWaveIndex = WhichListItem(StimWaveName, ListOfWavesInFolder, ";")
		
		// and now set the wave popup menu to that index
		// have to add 2 since the pulldown always has -none- and TestPulse as options
		SetPopupMenuIndex(currentPanel, waveSelect, incomingWaveIndex + 2)  
	
		// push the PSA_waveName into the right place
		// find the index for for the psa routine 
		// do this if the window actually exists
		ASSERT(WindowExists(amPanel), "Analysis master panel must exist")

		psaFuncList = AM_PS_sortFunctions()
		psaFuncIndex	 = WhichListItem("returnActionPotential", psaFuncList, ";")
		SetPopupMenuIndex("analysisMaster", psaMenu, psaFuncIndex)
		
		// push the PAA_waveName into the right place
		// find the index for for the psa routine
		paaFuncList = AM_PA_sortFunctions()
		paaFuncIndex = WhichListItem("bracketScaleFactor", paaFuncList, ";")
		SetPopupMenuIndex("analysisMaster", paaMenu, paaFuncIndex)
	
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
		SetCheckBoxState(currentPanel, "Check_DataAcq1_RepeatAcq", 1)
		
		// make sure the analysisResult is set to 0
		analysisSettingsWave[headstage][%PSAResult] = "0"
		
		// now start the sweep process
		print "pushing the start button..."
		// now start the sweep process
		// setting the ba structure
		ba.eventCode = 2
		ba.ctrlName = "DataAcquireButton"
		ba.win = currentPanel
		
		DAP_ButtonProc_AcquireData(ba)
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
	lockedDevList = DAP_ListOfLockedDevs()
	noLockedDevs = ItemsInList(lockedDevList)
	
	variable n
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)
	
		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		// push the waveSet to the ephys panel
		// first, build up the control name by using the headstage value	
		sprintf waveSelect, "Wave_DA_%02d", headstage
		sprintf scaleWidgetName, "Scale_DA_%02d", headStage
		
		// build up the list of available wave sets
		FolderPath = GetWBSvdStimSetDAPathAsString()
		folder = "*DA*"
		setdatafolder FolderPath // sets the wavelist for the DA popup menu to show all waves in DAC folder
		ListOfWavesInFolder = Wavelist(Folder,";","") 
		
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
		SetPopupMenuIndex(currentPanel, waveSelect, incomingWaveIndex + 2)  // have to add 2 since the pulldown always has -none- and TestPulse as options
		
		// put the scale in the right place 
		SetSetVariable(currentPanel, scaleWidgetName, scaleFactor)
		
		// now start the sweep process
		// setting the ba structure
		ba.eventCode = 2
		ba.ctrlName = "DataAcquireButton"
		ba.win = currentPanel
		
		DAP_ButtonProc_AcquireData(ba)
	endfor
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))	
		TI_WriteAck(cmdID, 1)
	endif
End

///@brief routine to be called from the WSE to see if the Action Potential has fired
///@param headstage		indicate which headstage to look for the AP
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
	lockedDevList = DAP_ListOfLockedDevs()
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
Function TI_runTestPulse(tpCmd, [cmdID])
	variable tpCmd
	string cmdID
	
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	variable returnValue
	
	// get the da_ephys panel names
	lockedDevList = DAP_ListOfLockedDevs()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)

		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
		if(tpCmd == 1)	// Turn on the test pulse
		
			// setting the ba structure
			ba.eventCode = 2
			ba.ctrlName = "StartTestPulseButton"
			ba.win = currentPanel
			
			TP_ButtonProc_DataAcq_TestPulse(ba)
			
			returnValue = 0
		elseif(tpCmd == 0) // Turn off the test pulse
			ITC_STOPTestPulse(currentPanel)
			ITC_TPDocumentation(currentPanel) // documents the TP Vrest, peak and steady state resistance values. for manually terminated TPs
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
Function TI_runStopStart([cmdID])
	string cmdID
	
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	
	// get the da_ephys panel names
	lockedDevList = DAP_ListOfLockedDevs()
	noLockedDevs = ItemsInList(lockedDevList)
	
	for(n = 0; n<noLockedDevs; n+= 1)
		currentPanel = StringFromList(n, lockedDevList)

		// structure needed for communicating with the start acquisition button on the DA_Ephys panel
		STRUCT WMButtonAction ba
		
		// pop the itc panel window to the front
		DoWindow /F $currentPanel
		
		// setting the ba structure
		ba.eventCode = 2
		ba.ctrlName = "DataAcquireButton"
		ba.win = currentPanel
		
		DAP_ButtonProc_AcquireData(ba)
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
