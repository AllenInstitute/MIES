#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_SETTINGS
#endif

/// @file MIES_MiesUtilities_settings.ipf
/// @brief This file holds MIES utility functions for settings management

/// @brief Generate a default settings file in JSON format
///
/// \rst
/// .. code-block:: json
///
///     {
///       "diagnostics": {
///         "last upload": "2020-03-05T13:43:32Z"
///       },
///       "version": 1
///     }
///
/// \endrst
///
/// Explanation:
///
/// Window coordinates are stored as
///
/// \rst
/// .. code-block:: json
///
/// {"coordinates" : {"left" : 123, "top" : 456, "bottom" 789, "right" : 101112}}
///
/// \endrst
///
/// Entries:
///
/// - "version": Major version number to track breaking changes
/// - "diagnostics": Groups settings related to diagnostics and crash dump handling
/// - "diagnostics/last upload": ISO8601 timestamp when the last successfull
///                              upload of crash dumps was tried. This is also set
///                              when no crash dumps have been uploadad.
/// - "analysisbrowser": Groups settings related to the Analysisbrowser
/// - "analysisbrowser/directory": The directory initially opened for browsing existing NWB/PXP files
/// - "logfiles": Groups settings related to log files
/// - "logfiles/last upload": ISO8601 timestamp when the last successfull
///                              upload of log files was tried. This is also set
///                              when no log files have been uploadad.
/// - "*[/*]/coordinates": window coordinates
///
/// @return JSONid
///
/// Caller is responsible for releasing the document.
Function GenerateSettingsDefaults()

	variable JSONid

	JSONid = JSON_New()

	JSON_AddVariable(JSONid, "version", 1)
	JSON_AddTreeObject(JSONid, "/diagnostics")
	JSON_AddString(JSONid, "/diagnostics/last upload", GetIso8601TimeStamp(secondsSinceIgorEpoch = 0))

	UpgradeSettings(JSONid)

	return JSONid
End

Function UpgradeSettings(JSONid)
	variable JSONid

	string oldPath, jsonPath
	string documentsFolder = GetUserDocumentsFolderPath()

	if(!JSON_Exists(JSONid, "/analysisbrowser"))
		JSON_AddTreeObject(JSONid, "/analysisbrowser")
		JSON_AddString(JSONid, SETTINGS_AB_FOLDER, documentsFolder)
	endif

	if(!JSON_Exists(JSONid, "/logfiles"))
		JSON_AddTreeObject(JSONid, "/logfiles")
		JSON_AddString(JSONid, "/logfiles/last upload", GetIso8601TimeStamp(secondsSinceIgorEpoch = 0))
	endif

	if(JSON_GetType(JSONid, SETTINGS_AB_FOLDER) == JSON_STRING)
		oldPath = JSON_GetString(JSONid, SETTINGS_AB_FOLDER)
		if(!CmpStr(oldPath, SETTINGS_AB_FOLDER_OLD_DEFAULT))
			oldPath = documentsFolder
		endif
		Make/FREE/T wvt = {oldPath}
		JSON_SetWave(JSONid, SETTINGS_AB_FOLDER, wvt)
	endif

	jsonPath = "/" + PACKAGE_SETTINGS_USERPING
	if(!JSON_Exists(JSONid, jsonPath))
		JSON_AddTreeObject(JSONid, jsonPath)
	endif
	if(!JSON_Exists(JSONid, jsonPath + "/enabled"))
		JSON_AddBoolean(JSONid, jsonPath + "/enabled", PACKAGE_SETTINGS_USERPING_DEFAULT)
	endif
	if(!JSON_Exists(JSONid, jsonPath + "/last upload"))
		JSON_AddString(JSONid, jsonPath + "/last upload", GetIso8601TimeStamp(secondsSinceIgorEpoch = 0))
	endif
End

Function ToggleUserPingSetting()

	variable isEnabled

	NVAR JSONid = $GetSettingsJSONid()
	isEnabled = GetUserPingEnabled()

	JSON_SetBoolean(JSONid, "/" + PACKAGE_SETTINGS_USERPING + "/enabled", !isEnabled)
	PS_WriteSettings(PACKAGE_MIES, JSONid)
	printf "Changed periodically ping setting to %s.\r", ToOnOff(!IsEnabled)
	printf "Saved settings.\r"
End

Function GetUserPingEnabled()

	NVAR JSONid = $GetSettingsJSONid()
	return !!JSON_GetVariable(JSONid, "/" + PACKAGE_SETTINGS_USERPING + "/enabled")
End

Function/S GetUserPingTimestamp()

	NVAR JSONid = $GetSettingsJSONid()
	return JSON_GetString(JSONid, "/" + PACKAGE_SETTINGS_USERPING + "/last upload")
End

Function SetUserPingTimestamp(variable timeStamp)

	string isoTS

	isoTS = GetISO8601TimeStamp(secondsSinceIgorEpoch = timeStamp)
	NVAR JSONid = $GetSettingsJSONid()
	JSON_SetString(JSONid, "/" + PACKAGE_SETTINGS_USERPING + "/last upload", isoTS)
End
