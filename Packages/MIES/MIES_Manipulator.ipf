#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_Manipulator.ipf
/// @brief Functions related to manipulator control and position documentation

// relevant wave and DF getters:
// GetManipulatorPathAsString()
// GetManipulatorPath()
// GetHSManipulatorName(panelTitle)
// GetHSManipulatorAssignments(panelTitle)

// server commands (without manipulator name, where required)
Static StrConstant DEVICE_LIST = "http://localhost:8889/geom_config?fn=list_geom_iids"
Static StrConstant XYZ_IN_STAGE_FRAME = "http://localhost:8889/mssgeom?fn=get_position_stage_frame&iid="

// manipulator name prefix defined by the MSS server
Static StrConstant MANIP_BASE_NAME = "mg"

/// @brief Executes MSS server calls
///
/// parses the return string to remove brackets
/// replaces the string list separator returned by MSS to the Igor default string list separartor
/// @param cmd The MSS server call
Function/S M_ExecuteMSSServerCall(cmd)
	string cmd
	string response = FetchURL(cmd)
	Variable error = GetRTError(1)
	if(error != 0)
		print "Communcation with MSS server failed"
		abort
	else
		response = ReplaceString ("[", response, "")
		response = ReplaceString ("]", response, "")
		response = ReplaceString (",", response, ";")
		response = ReplaceString (" ", response, "")
		return response
	endif	
End

/// @brief Gets the list of attached manipulators
Function/S M_GetListOfAttachedManipulators()
	string ManipulatorList = M_ExecuteMSSServerCall(DEVICE_LIST)
	
	if(numtype(strlen(ManipulatorList)))
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
	ManipulatorDataWave[headStage][%ManipulatorNumber] = M_GetManipulatorNumberFromName(ManipulatorName)
	ManipulatorTextWave[headStage][%ManipulatorName] = ManipulatorName
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
Function/S GetXYZinStageFrame(manipulatorName)
	string ManipulatorName
	CheckIfManipulatorIsAttached(manipulatorName)
	string cmd = XYZ_IN_STAGE_FRAME + ManipulatorName
	return M_ExecuteMSSServerCall(cmd)
End

/// @brief Checks format of manipulator name
///
/// @param ManipulatorName e.g. "mg1"
Function CheckManipulatorNameFormat(manipulatorName)
	string manipulatorName
	// check if base name matches
	ASSERT(stringmatch(ManipulatorName, (MANIP_BASE_NAME + "*")), "Name of manipulator does not conform to standard format")
	// check if base name is followed by an integer
	variable val = M_GetManipulatorNumberFromName(ManipulatorName)
	ASSERT(val >= 0 && IsInteger(val), "Manipulator number must be a positive integer")
End

/// @brief Checks if manipulator is available
///
/// @param ManipulatorName e.g. "mg1"
Function CheckIfManipulatorIsAttached(manipulatorName)
	string manipulatorName
	CheckManipulatorNameFormat(manipulatorName)
	ASSERT(WhichListItem(manipulatorName, M_GetListOfAttachedManipulators(),";",0,0) != -1, "Manipulator: " + manipulatorName + " is not available.")
End

/// @brief Returns manipulator associated with headstage
Function/S GetManipFromHS(panelTitle, headStage)
	string panelTitle
	variable headStage
	WAVE/T ManipulatorTextWave = GetHSManipulatorName(panelTitle)
	return ManipulatorTextWave[headStage][%manipulatorName]
End

/// @brief Documents X,Y,Z position of manipulators of active headstages in lab notebook	
// This funciton should be run once whole cell config is aquired on all cells in experiment. Not sure how to do this.
Function DocumentManipulatorXYZ(panelTitle)
	string panelTitle
	string manipulatorName, manipulatorXYZ
	variable i

	// Ensure each manipulator is assigned to only one headstage
	assert(SearchForDuplicates(GetHSManipulatorAssignments(panelTitle)) == -1, "The same manipulator is assinged to more than one headstage")
	
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
	
	Make/FREE/N=(1, 3, NUM_HEADSTAGES) TPSettingsWave = NaN

	WAVE statusHS = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif
	
		ManipulatorXYZ = GetXYZinStageFrame(GetManipFromHS(panelTitle, i))
		
		TPSettingsWave[0][0][i] = str2num(stringfromlist(0, ManipulatorXYZ))
		TPSettingsWave[0][1][i] = str2num(stringfromlist(1, ManipulatorXYZ))
		TPSettingsWave[0][2][i] = str2num(stringfromlist(2, ManipulatorXYZ))
	endfor
	
	variable sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep") - 1
	ED_createWaveNotes(TPSettingsWave, TPKeyWave, sweepNo, panelTitle)
End
	
/// @brief Creates gizmo plot manipulator positions in lab notebook
///
/// find columns where data is stored in lab notebook
/// find last row with data
Function ManipulatorGizmoPlot(panelTitle, [sweep])
	string panelTitle
	variable sweep
	string setting
	DFREF ManipulatorDF = GetManipulatorPath()
	DFREF settingsHistoryDFR = GetDevSpecLabNBSettHistFolder(panelTitle)
	WAVE/D/Z/SDFR=settingsHistoryDFR Settingshistory
	WAVE WaveForGizmo = GetManipulatorPos(panelTitle)
	if(paramIsDefault(sweep))
		sweep = DM_ReturnLastSweepAcquired(panelTitle)
		// Need to check if there is actually manipulator data stored for the sweep
	endif
	
	WaveForGizmo[][0] = GetLastSetting(Settingshistory, sweep, "ManipX")[p]
	WaveForGizmo[][1] = GetLastSetting(Settingshistory, sweep, "ManipY")[p]
	WaveForGizmo[][2] = GetLastSetting(Settingshistory, sweep, "ManipZ")[p]
	
End		

/// @brief Detects duplicate values in a 1d wave.
///
/// Returns -1 if duplicate is NOT found. Will not report NaNs as duplicates
/// Igor 7 will have a findDuplicates command
Function SearchForDuplicates(Wv)
	WAVE Wv
	ASSERT(dimsize(Wv,1) <= 1, (nameofwave(Wv) + " is not a 1D wave")) // make sure wave passed in is 1d
	Duplicate/FREE Wv WvCopyOne WvCopyTwo // make two copies. One to store duplicate search results, the other to sort and search for duplicates.
	variable Rows = (dimSize(Wv,0) // create a variable so dimSize is only called once instead of twice.
	WvCopyOne[Rows- 1] = 0 // Set last point to 0 because if it by chance was 1 it would come up as a duplicate, even when the penultimate value in Wv was not 1
	Sort WvCopyTwo, WvCopyTwo // sort so that duplicates will be in adjacent rows
 	WvCopyOne[0, Rows - 2] = WvCopyTwo[p] != WvCopyTwo[p + 1] ? 0 : 1 // could multithread but, MIES use case will be with short 1d waves.
	FindValue/V=1 WvCopyOne
	return V_value
End

