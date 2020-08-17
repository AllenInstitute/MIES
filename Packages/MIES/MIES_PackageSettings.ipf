#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PS
#endif

/// @file MIES_PackageSettings.ipf
/// @brief Routines for dealing with JSON settings

static StrConstant PS_STORE_COORDINATES = "JSONSettings_StoreCoordinates"
static StrConstant PS_WINDOW_NAME = "JSONSettings_WindowName"

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

/// @brief Move the window to the stored location
static Function PS_ApplyStoredWindowCoordinate(variable JSONid, string win)

	string path, name
	variable left, top, right, bottom, err

	name = GetUserData(win, "", PS_WINDOW_NAME)
	ASSERT(!IsEmpty(name), "Invalid empty name")

	path = "/" + name + "/coordinates"

	if(JSON_GetType(JSONid, path, ignoreErr=1) != JSON_OBJECT)
		return NaN
	endif

	try
		ClearRTError()
		left = JSON_GetVariable(JSONid, path + "/left")
		top = JSON_GetVariable(JSONid, path + "/top")
		right = JSON_GetVariable(JSONid, path + "/right")
		bottom = JSON_GetVariable(JSONid, path + "/bottom")

		MoveWindow/W=$win left, top, right, bottom
		AbortONRTE
	catch
		err = ClearRTError()
		printf "Applying window coordinates for %s failed with %d\r", win, err
		ControlwindowToFront()
	endtry
End

/// @brief Add user data to mark the window as using coordinate saving
static Function PS_RegisterForCoordinateSaving(string win, string name)

	SetWindow $win, userdata($PS_STORE_COORDINATES) = "1"
	SetWindow $win, userdata($PS_WINDOW_NAME) = name
End

/// @brief Store the coordinates of all registered windows in the JSON settings file
///
/// The windows must have been registered beforehand with PS_InitCoordinates().
Function PS_StoreWindowCoordinates(variable JSONid)

	string list, win, part
	variable i, numEntries, store

	list = WinList("*", ";", "WIN:65") // Graphs + Panels

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		win = StringFromList(i, list)
		store = str2num(GetUserData(win, "", PS_STORE_COORDINATES))

		if(IsNaN(store) || store == 0)
			continue
		endif

		try
			ClearRTError()
			PS_StoreWindowCoordinate(JSONid, win); AbortOnRTE
		catch
			ClearRTError()
			// silently ignore
		endtry
	endfor
End

/// @brief Store the window coordinates of `win` in the JSON settings file
///
/// The window must have been registered beforehand with PS_InitCoordinates().
Function PS_StoreWindowCoordinate(variable JSONid, string win)

	string path, name

	name = GetUserData(win, "", PS_WINDOW_NAME)
	ASSERT(!IsEmpty(name), "Invalid empty name")

	path = "/" + name + "/coordinates"

	if(!JSON_Exists(JSONid, path))
		JSON_AddTreeObject(JSONid, path)
	endif

	GetWindow $win wsizeRM

	JSON_SetVariable(JSONid, path + "/left", V_left)
	JSON_SetVariable(JSONid, path + "/right", V_right)
	JSON_SetVariable(JSONid, path + "/bottom", V_bottom)
	JSON_SetVariable(JSONid, path + "/top", V_top)
End

/// @brief Add support for window coordinate storing and loading
///
/// Takes care of:
/// - Marking the window as using it with the given name
/// - Adding a hook to store the coordinates on window killing
/// - Read the current coordinates from the JSON settings file and applying
///   them
///
/// @param JSONid  JSON document with settings
/// @param win     window name
/// @param name    name to store the window under (especially useful for
///                windows which are renamed to their locked device)
/// @param addHook [optional, defaults to true] Add a window hook to store the
///                coordinates on window killing. Users with their own kill event
///                handling must pass `addHook=0`.
Function PS_InitCoordinates(variable JSONid, string win, string name, [variable addHook])

	if(ParamIsDefault(addHook))
		addHook = 1
	else
		addHook = !!addHook
	endif

	PS_RegisterForCoordinateSaving(win, name)
	PS_ApplyStoredWindowCoordinate(JSONid, win)

	if(addHook)
		SetWindow $win, hook(windowCoordinateSaving)=StoreWindowCoordinatesHook
	endif
End
