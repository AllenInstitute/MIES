#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// relevant wave and DF getters:
// GetManipulatorPathAsString()
// GetManipulatorPath()
// GetHSManipulatorName(panelTitle)
// GetHSManipulatorAssignments(panelTitle)

Static StrConstant DEVICE_LIST = "http://localhost:8889/geom_config?fn=list_geom_iids"
Static StrConstant XYZ_IN_STAGE_FRAME = "http://localhost:8889/mssgeom?fn=get_position_stage_frame&iid="
Static StrConstant MANIP_BASE_NAME = "mg"

/// @brief Executes MSS server calls
///
/// parses the return string to remove brackets
/// replaces the string list separator returned by MSS to the Igor default string list separartor
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
Function CheckManipulatorNameFormat(manipulatorName)
	string manipulatorName
	// check if base name matches
	ASSERT(stringmatch(ManipulatorName, (MANIP_BASE_NAME + "*")), "Name of manipulator does not conform to standard format")
	// check if base name is followed by an integer
	variable val = M_GetManipulatorNumberFromName(ManipulatorName)
	ASSERT(val >= 0 && IsInteger(val), "Manipulator number must be a positive integer")
End

/// @brief Checks if manipulator is available
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

/// @brief Returns positions of manipulators for all active headstages

/// @brief Documents X,Y,Z position of manipulators of active headstages in lab notebook	
Function DocumentManipulatorXYZ(panelTitle)
	string panelTitle
	string manipulatorName, manipulatorXYZ
	variable i
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
	
/// @brief Creates gizmo plot of last documented manipulator position in lab notebook

			panelTitle = pa.win
			graph      = DB_GetLabNoteBookGraph(panelTitle)
			popStr     = pa.popStr

			if(!CmpStr(popStr, NONE))
				break
			endif

			Wave settingsHistory = DB_GetSettingsHistory(panelTitle)
			device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
			Wave/Z/T/SDFR=GetDevSpecLabNBSettKeyFolder(device) keyWave

			AddTraceToLBGraph(graph, keyWave, settingsHistory, popStr)