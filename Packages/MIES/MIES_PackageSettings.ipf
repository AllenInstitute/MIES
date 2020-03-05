#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PS
#endif

/// @file MIES_PackageSettings.ipf
/// @brief Routines for dealing with JSON settings

/// @brief This functions should return a JSON ID with the default settings
Function PS_GenerateSettingsDefaults()
	ASSERT(0, "Can not call prototype")
End

/// @brief Return a JSON ID with an opened JSON settings file
///
/// Caller is responsible for releasing the document.
Function PS_ReadSettings(package, generateDefaults)
	string package
	FUNCREF PS_GenerateSettingsDefaults generateDefaults

	string filepath, data, fName
	variable JSONid

	filepath = PS_GetSettingsFile(package)

	if(!FileExists(filepath))
		JSONid = generateDefaults()
		PS_WriteSettings(package, JSONid)
		return JSONid
	endif

	[data, fName] = LoadTextFile(filepath)
	return JSON_Parse(data)
End

/// @brief Write the settings from `JSONid` for `package` to disc
///
/// Call this function in `BeforeExperimentSaveHook` to write the settings to disc
Function PS_WriteSettings(package, JSONid)
	string package
	variable JSONid

	string filepath

	ASSERT(IsFinite(JSONid), "Invalid JSONid")

	filepath = PS_GetSettingsFile(package)
	SaveTextFile(JSON_Dump(JSONid, indent=2), filepath)
End

// @brief Return the absolute path to the settings folder for `package`
static Function/S PS_GetSettingsFolder(package)
	string package

	return SpecialDirPath("Igor Preferences", 0, 0, 1) + "Packages:" + CleanupName(package, 0)
End

// @brief Return the absolute path to the JSON settings file for `package`
static Function/S PS_GetSettingsFile(package)
	string package

	string folder

	folder = PS_GetSettingsFolder(package)

	if(!FolderExists(folder))
		CreateFolderOnDisk(folder)
	endif

	return folder + ":Settings.json"
End
