#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MIESUTILS_SETTINGS
#endif // AUTOMATED_TESTING

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
/// - "/<group>/<name>/coordinates": window coordinates
///
/// @return JSONid
///
/// Caller is responsible for releasing the document.
Function GenerateSettingsDefaults()

	variable JSONid

	JSONid = JSON_New()

	JSON_AddVariable(JSONid, "version", PACKAGE_JSON_VERSION)
	JSON_AddTreeObject(JSONid, "/diagnostics")
	JSON_AddString(JSONid, "/diagnostics/last upload", GetIso8601TimeStamp(secondsSinceIgorEpoch = 0))

	JSON_AddTreeObject(JSONid, "/analysisbrowser")
	JSON_AddTreeArray(JSONid, "/analysisbrowser/directory")

	JSON_AddTreeObject(JSONid, "/logfiles")
	JSON_AddString(JSONid, "/logfiles/last upload", GetIso8601TimeStamp(secondsSinceIgorEpoch = 0))

	JSON_AddTreeObject(JSONid, "/userping")
	JSON_AddBoolean(JSONid, "/userping/enabled", PACKAGE_SETTINGS_USERPING_DEFAULT)
	JSON_AddString(JSONid, "/userping/last upload", GetIso8601TimeStamp(secondsSinceIgorEpoch = 0))

	UpgradeSettings(JSONid)

	return JSONid
End

Function UpgradeSettings(variable JSONid)

	string oldPath, jsonPath, documentsFolder
	variable version

	version = JSON_GetVariable(JSONid, "/version")

	if(version == PACKAGE_JSON_VERSION)
		return NaN
	endif

	if(version <= 1)
		documentsFolder = GetUserDocumentsFolderPath()

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

		UpgradeCoordinateSavePaths(jsonID)
	endif

	// upgrade version variable
	JSON_SetVariable(JSONId, "/version", PACKAGE_JSON_VERSION)
End

/// @brief Upgrade save paths for panels/graphs
///
/// v1:
///
/// \rst
/// .. code-block:: json
///
///     "datasweepbrowser": {
///       "coordinates": {
///         "bottom": 664.25,
///         "left": 427.5,
///         "right": 916.5,
///         "top": 292.25
///       }
///     }
///
/// \endrst
///
/// v2:
///
/// \rst
/// .. code-block:: json
///
///   "datasweepbrowser": {
///     "DataBrowser": {
///       "coordinates": {
///         "bottom": 981.5,
///         "left": 427.5,
///         "right": 1548,
///         "top": 292.25
///       }
///     }
///    }
///
/// \endrst
///
/// This is done for a couple of windows.
static Function UpgradeCoordinateSavePaths(variable jsonID)

	variable numEntries, i
	string group, old_name, new_name, old_path_full, new_path

	Make/FREE/T map = {{"datasweepbrowser", "wavebuilder", "daephys", "analysisbrowser"}, \
	                   {"DataBrowser", "WaveBuilder", "DA_Ephys", "AnalysisBrowser"}}

	numEntries = DimSize(map, ROWS)
	for(i = 0; i < numEntries; i += 1)
		group    = map[i][0]
		new_name = map[i][1]

		old_path_full = "/" + group + "/coordinates"
		new_path      = "/" + group + "/" + new_name

		if(!JSON_Exists(jsonID, old_path_full))
			continue
		endif

		JSON_AddObjects(jsonID, new_path)
		JSON_SyncJSON(jsonID, jsonID, old_path_full, new_path + "/coordinates", JSON_SYNC_ADD_TO_TARGET)
		JSON_Remove(jsonID, old_path_full)
	endfor
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
