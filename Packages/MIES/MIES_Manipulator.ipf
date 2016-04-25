#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_Manipulator.ipf
/// @brief __M__ Functions related to manipulator control and position documentation

// relevant wave and DF getters:
// GetManipulatorPathAsString()
// GetManipulatorPath()
// GetHSManipulatorName(panelTitle) - returns manipulator name strings assigned to headstage
// GetHSManipulatorAssignments(panelTitle) - returns manipulator number assigned to headstage

// server commands (without manipulator name, where required)
Static StrConstant DEVICE_LIST = "http://localhost:8889/geom_config?fn=list_geom_iids"
Static StrConstant XYZ_IN_STAGE_FRAME = "http://localhost:8889/mssgeom?fn=get_position_stage_frame&iid="
Static StrConstant APPROACH_STEP = "Server call does not exist yet"

// manipulator name prefix defined by the MSS server
Static StrConstant MANIP_BASE_NAME = "mg"

/// @brief MSS command wrapper
///
/// Parses device specific and general MSS calls
static Function/S M_ExecuteMSSCommand(cmd, [deviceName])
	string cmd, deviceName
	if(paramIsDefault(deviceName)) // handle calls that don't require a device to be specified
		return M_ExecuteMSSServerCall(cmd)
	else // handle device specific calls
		cmd+=deviceName
		if(stringmatch(deviceName, (MANIP_BASE_NAME+"*"))) // handle manipulator calls
			M_CheckIfManipulatorIsAttached(deviceName)
		elseif(stringmatch(deviceName, ("STAGE"))) // handle stage calls
			// @todo place holder to handle stage commands
			ASSERT(0, "Stage commands have not been implemented")
		endif
		return M_ExecuteMSSServerCall(cmd)
	endif
	ASSERT(0, "Server command failed")
End

/// @brief Executes MSS server calls
///
/// parses the return string to convert MSS string to Igor friendly string
///
/// @param cmd The MSS server call
static Function/S M_ExecuteMSSServerCall(cmd)
	string cmd

	string response
	Variable error

	try
		response = FetchURL(cmd); AbortOnRTE
	catch
		error = GetRTError(1)
		Abort "Communcation with MSS server failed"
	endtry
	
	
	response = ReplaceString ("[", response, "")
	response = ReplaceString ("]", response, "")
	response = ReplaceString (",", response, ";")
	response = ReplaceString (" ", response, "")
	return response
End

/// @brief Checks if manipulator is available
///
/// @param manipulatorName e.g. "mg1"
Function M_CheckIfManipulatorIsAttached(manipulatorName)
	string manipulatorName
	ASSERT(M_ManipulatorNameFormatIsValid(manipulatorName), "Manipulator name format is not valid")
	ASSERT(WhichListItem(manipulatorName, M_GetListOfAttachedManipulators(),";",0,0) != -1, "Manipulator: " + manipulatorName + " is not available.")
End
	
/// @brief Checks format of manipulator name
///
/// @param manipulatorName e.g. "mg1"
Function M_ManipulatorNameFormatIsValid(manipulatorName)
	string manipulatorName
	
	variable val
	val = stringmatch(ManipulatorName, (MANIP_BASE_NAME + "*"))
	// check if prefix matches
	if(val == 0)
		print "Manipulator prefix is not valid"
		return 0
	endif
	// check if base name is followed by an integer
	val = M_GetManipulatorNumberFromName(ManipulatorName)
	if(val < 0 || !IsInteger(val))
		print "Manipulator number must be a positive integer"
		return 0
	endif
	
	return 1
End

/// @brief Gets the list of attached manipulators
Function/S M_GetListOfAttachedManipulators()
	string ManipulatorList = M_ExecuteMSSCommand(DEVICE_LIST)
	if(isEmpty(ManipulatorList))
		ManipulatorList = "No dev. avail."
	else
		ManipulatorList = ReplaceString ("stage;", ManipulatorList, "")
	endif
	
	return ManipulatorList
End

/// @ brief Sets the headstage manipulator association
Function M_SetManipulatorAssociation(panelTitle)
	string panelTitle
	variable 	headStage = GetPopupMenuIndex(panelTitle, "Popup_Settings_HeadStage") // get the active headstage
	WAVE ManipulatorDataWave = GetHSManipulatorAssignments(panelTitle)
	WAVE/T ManipulatorTextWave = GetHSManipulatorName(panelTitle)
	string ManipulatorName = GetPopupMenuString(panelTitle, "popup_Settings_Manip_MSSMnipLst")
	if(cmpstr(NONE, ManipulatorName) == 0)
		ManipulatorDataWave[headStage][%ManipulatorNumber] = NaN
		ManipulatorTextWave[headStage][%ManipulatorName] = ""
	else
		ManipulatorDataWave[headStage][%ManipulatorNumber] = M_GetManipulatorNumberFromName(ManipulatorName)
		ManipulatorTextWave[headStage][%ManipulatorName] = ManipulatorName
	endif
End

/// @brief Updates the manipulator hardware association controls in the Hardware tab of the DA_ephys panel
Function M_SetManipulatorAssocControls(panelTitle, headStage)
	string panelTitle
	variable headStage
	WAVE/T ManipulatorTextWave = GetHSManipulatorName(panelTitle)
	variable IndexOfSavedManipulator = whichListItem(ManipulatorTextWave[headStage][%ManipulatorName], M_GetListOfAttachedManipulators()) +1
	SetPopupMenuIndex(panelTitle, "popup_Settings_Manip_MSSMnipLst", IndexOfSavedManipulator)
End

/// @brief Gets the manipulator number from the string name
///
/// @param ManipulatorName e.g. "mg1"
Function M_GetManipulatorNumberFromName(ManipulatorName)
	string ManipulatorName
	return str2num(ReplaceString(MANIP_BASE_NAME, ManipulatorName,""))	
End

/// @brief Wrapper for stage frame position query server command
Function/S M_GetXYZinStageFrame(manipulatorName)
	string ManipulatorName
	string cmd = XYZ_IN_STAGE_FRAME
	return M_ExecuteMSSCommand(cmd, deviceName = manipulatorName)
End

/// @brief Returns string name of manipulator associated with headstage
Function/S M_GetManipFromHS(panelTitle, headStage)
	string panelTitle
	variable headStage
	WAVE/T ManipulatorTextWave = GetHSManipulatorName(panelTitle)
	return ManipulatorTextWave[headStage][%manipulatorName]
End

/// @brief Documents X,Y,Z position of manipulators of active headstages in lab notebook	
// This funciton should be run once whole cell config is aquired on all cells in experiment. Not sure how to do this.
Function M_DocumentManipulatorXYZ(panelTitle)
	string panelTitle

	string manipulatorName, manipulatorXYZ
	variable i, sweepNo

	AbortOnValue M_CheckSettings(panelTitle),1	
	
	Make/FREE/T/N=(3, 3, 1) TPKeyWave
	
	// add data to TPKeyWave
	// key
	TPKeyWave[0][0]  = "ManipX"  
	TPKeyWave[0][1]  = "ManipY"  
	TPKeyWave[0][2]  = "ManipZ"
	// unit
	TPKeyWave[1][0]  = "Micron"  
	TPKeyWave[1][1]  = "Micron"  
	TPKeyWave[1][2]  = "Micron"
	// tolerance
	TPKeyWave[2][0]  = "1"  
	TPKeyWave[2][1]  = "1"  
	TPKeyWave[2][2]  = "1"	
	
	Make/FREE/N=(1, 3, LABNOTEBOOK_LAYER_COUNT) TPSettingsWave = NaN

	WAVE statusHS = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif
		
		manipulatorName = M_GetManipFromHS(panelTitle, i)
		if(isNull(manipulatorName) || isEmpty(manipulatorName))
			print "Headstage", i, "does not have a manipulator assigned"
			continue
		endif
		
		ManipulatorXYZ = M_GetXYZinStageFrame(manipulatorName)
		
		TPSettingsWave[0][0][i] = str2num(stringfromlist(0, ManipulatorXYZ))
		TPSettingsWave[0][1][i] = str2num(stringfromlist(1, ManipulatorXYZ))
		TPSettingsWave[0][2][i] = str2num(stringfromlist(2, ManipulatorXYZ))
	endfor

	sweepNo = AFH_GetLastSweepAcquired(panelTitle)
	ED_createWaveNotes(TPSettingsWave, TPKeyWave, sweepNo, panelTitle)
End

/// @brief Check if settings are valid to send a manipulator server call
///
/// For invalid settings a message is printed into the history area
/// @param panelTitle device
/// @return 0 for valid settings, 1 for invalid settings
Function M_CheckSettings(panelTitle)
	string panelTitle
	
	variable i, numEntries, numHS
	string list

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	if(isEmpty(panelTitle))
		print "Invalid empty string for panelTitle, can not proceed"
		return 1
	endif	

	list = panelTitle

	if(DAP_DeviceCanLead(panelTitle))
		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices))
			list = AddListItem(list, listOfFollowerDevices, ";", inf)
		endif
	endif

	DEBUGPRINT("Checking the panelTitle list: ", str=list)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)

		panelTitle = StringFromList(i, list)

		AbortOnValue HSU_DeviceIsUnlocked(panelTitle),1

		if(HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal))
			printf "(%s) Device can not be selected. Please unlock and lock the device.\r", panelTitle
			return 1
		endif

		numHS = sum(DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE))
		if(!numHS)
			printf "(%s) Please activate at least one headstage\r", panelTitle
			return 1
		endif
	endfor
	
	if(SearchForDuplicates(GetHSManipulatorAssignments(panelTitle)) == 1)
		print "The same manipulator is assinged to more than one headstage"
		return 1
	endif
	
	return 0
End
	
/// @brief Creates gizmo plot manipulator positions in lab notebook
///
/// find columns where data is stored in lab notebook
/// find last row with data
Function M_ManipulatorGizmoPlot(panelTitle, [sweep])
	string panelTitle
	variable sweep

	DFREF ManipulatorDF = GetManipulatorPath()
	WAVE settingsHistory = GetNumDocWave(panelTitle)
	WAVE WaveForGizmo = GetManipulatorPos(panelTitle)
	if(paramIsDefault(sweep))
		sweep = AFH_GetLastSweepAcquired(panelTitle)
		// Need to check if there is actually manipulator data stored for the sweep
	endif
	
	WaveForGizmo[][0] = GetLastSetting(Settingshistory, sweep, "ManipX")[p]
	WaveForGizmo[][1] = GetLastSetting(Settingshistory, sweep, "ManipY")[p]
	WaveForGizmo[][2] = GetLastSetting(Settingshistory, sweep, "ManipZ")[p]
	
	string cmd = "NewGizmo/k=1/N=CellPosPlot/T=\"CellPosPlot\""
	Execute cmd
	sprintf cmd "AppendToGizmo/N=CellPosPlot defaultScatter= %s" GetWavesDataFolder(WaveForGizmo,2)
	Execute cmd
End		

/// @brief Steps manipulators on approach axis for headstages that are active and in approach pressure mode
/// Waiting for Approach to be implemented in MSS server
Function M_ApproachStep(panelTitle, stepSize, [headstage])
	string panelTitle
	variable stepSize
	variable headstage
End
