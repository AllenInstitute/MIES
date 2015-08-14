#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// relevant wave and DF getters:
// GetManipulatorPathAsString()
// GetManipulatorPath()
// GetHSManipulatorName(panelTitle)
// GetHSManipulatorAssignments(panelTitle)

Static StrConstant DEVICE_LIST = "http://localhost:8889/geom_config?fn=list_geom_iids"
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

/// @brief Returns positions of manipulators for all active headstages