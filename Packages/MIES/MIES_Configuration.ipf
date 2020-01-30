#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_CONF
#endif

/// @file MIES_Configuration.ipf
///
/// @brief __CONF__ Import user settings to configure paramters for Ephys experiments
///
/// @anchor Configuration Module brief description
///******************************************************************************************************************************
///
/// The Configuration module allows to save and load the GUI state of complete windows including its subwindows
///
/// The main functions are CONF_SaveWindow and CONF_RestoreWindow. CONF_SaveWindow automatically detects if the current window is
/// a DA_Ephys panel and uses the DA_Ephys GUI state savig configuration settings and saves additional information.
/// CONF_RestoreWindow also detects if the current window is of DA_Ephys type and handles that specific for this case.
/// CONF_RestoreDAEphys can be called directly as well if there is no panel open. It will open a new DA_Ephys panel automatically
/// if no other viable candidate panel was found.
///
/// The GUI state is saved in a text file in json format. In the basic structure of the file the main blocks
/// are the windows and subwindows and within are the control blocks.
/// A bitmask parameter allows to configure which control information is saved. See WindowControlSavingMask
/// Currently supported is Value, Position/Size, Userdata, Disabled state and Type of a control.
/// Not implemented is e.g. Color/Background Color
/// As Value only the V_Value and/or S_Value and/or S_DataFolder is saved. Special control properties for e.g.
/// ListBox like V_SelCol are currently not implemented.
///
/// How GUI controls are handled can be controlled through userdata settings of each control. The following
/// userdata settings are supported:
/// - Config_NiceName: sets a human readable name of the control used in the configuration file
///                    This name may not be a duplicate of another controls name or ControlArray name.
///                    Also suffixing with " ControlGroup" is not allowed.
/// - Config_GroupPath: Sets a group path in which the control appears in the configuration file.
///                     If not set then "Generic" is used. The group path elements can not contain the '/' character.
///                     Several levels can be separated by ";", e.g. "level1;level2;".
///                     In the configuration file the group path elements are suffixed by " ControlGroup" which identifies them
///                     as path compared to actual control names.
/// - Config_DontSave: When set to 1 the control is ignored on saving the window.
/// - Config_DontRestore: When set to 1 the control is ignored on restoring the window.
/// - Config_PushButtonOnRestore: Only valid with Button controls. When the button is restored a button press
///                               is issued.
/// - Config_RestorePriority: Sets a double precision number that defines the order in which controls get restored.
///                           Lower numbers correspond to earlier restore. If not set a priority of Inf is used.
///                           If multiple controls have the same priority the order of restore is not defined.
/// - Config_RadioCouplingFunc: A function name of a function that returns a text wave with lists of coupled
///                             CheckBoxes (aka RadioButtons). It is assumed that only one CheckBox of the group
///                             is in enabled state at the same time. See DAP_GetRadioButtonCoupling for example.
/// - ControlArray: Stores a name of a group of controls. All controls with the same ControlArray name are saved
///                 as group with that name in the configuration file. ControlArrays save only values and nothing
///                 is saved if the configured WindowControlSavingMask does not include values.
/// - ControlArrayIndex: Only valid if also ControlArray is set. Stores the index number of the control in its
///                      ControlArray. All member of the same ControlArray must have different indices.
///                      Currently not more than 100 controls are allowed for each ControlArray.
///
/// The function WindowtoJSON allows to give optional a list of control types that should be excluded.
///
/// If the type of the control was saved, it is checked against the GUI controls type on restore.
///
/// CheckBoxes are saved with true/false values.
///
/// For the DA_Ephys panel: The function CONF_DefaultSettings sets default values for parameters not present in the GUI.
///
/// Special mask flags:
/// - EXPCONFIG_SAVE_ONLY_RELEVANT: Saves only most relevant value data of a control. It is configured in EXPCONFIG_GUI_PREFERRED
/// - EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY: Saves value for PopupMenu only as string
/// - EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY: Saves value for PopupMenu only as index value
/// - EXPCONFIG_MINIMIZE_ON_RESTORE: Minimize window while restoring it.
/// - EXPCONFIG_SAVE_BUTTONS_ONLY_PRESSED: Saves Buttons only when its userdata Config_PushButtonOnRestore is "1"
///
/// Handling of window names on restore:
/// The currently selected windows main window is used as reference. The main window name in the configuration file is
/// internally replaced with the current main window. This allows to save from "DataBrowser" and load to "DataBrowser2".
///
/// Handling of errors in input data:
/// If input data is of unexpected format an ASSERTion or RTE is issued. The wrapping function converts the RTE to an ASSERT.
/// The panel restore is aborted and the panel stays in its state. It gets unhided.
///
/// Default configuration for generic windows:
/// By default only the Value property is saved and controls from EXPCONFIG_EXCLUDE_CTRLTYPES excluded.
///
/// Default configuration for DA_Ephys panel:
/// - By default only the Value property is saved
/// - Controls from DAEPHYS_EXCLUDE_CTRLTYPES are excluded.
/// - The window is minimized while restoring
/// - PopupMenu values are saved as string only
/// - Buttons are only saved if its userdata Config_PushButtonOnRestore is "1"
/// - Only most relevant data of a control is saved.
///******************************************************************************************************************************

#if exists("MCC_GetMode") && exists("AxonTelegraphGetDataStruct")
#define AMPLIFIER_XOPS_PRESENT
#endif

static StrConstant EXPCONFIG_FIELD_CTRLTYPE = "Type"
static StrConstant EXPCONFIG_FIELD_CTRLVVALUE = "NumValue"
static StrConstant EXPCONFIG_FIELD_CTRLSVALUE = "StrValue"
static StrConstant EXPCONFIG_FIELD_CTRLSDF = "DataSource"
static StrConstant EXPCONFIG_FIELD_CTRLDISABLED = "Disabled"
static StrConstant EXPCONFIG_FIELD_CTRLPOSHEIGHT = "Height"
static StrConstant EXPCONFIG_FIELD_CTRLPOSWIDTH = "Width"
static StrConstant EXPCONFIG_FIELD_CTRLPOSTOP = "Top"
static StrConstant EXPCONFIG_FIELD_CTRLPOSLEFT = "Left"
static StrConstant EXPCONFIG_FIELD_CTRLPOSRIGHT = "Right"
static StrConstant EXPCONFIG_FIELD_CTRLPOSPOS = "Pos"
static StrConstant EXPCONFIG_FIELD_CTRLPOSALIGN = "Align"
static StrConstant EXPCONFIG_FIELD_CTRLUSERDATA = "Userdata"
static StrConstant EXPCONFIG_FIELD_BASE64PREFIX = "Base64 "
static StrConstant EXPCONFIG_FIELD_CTRLARRAYVALUES = "Values"

static StrConstant EXPCONFIG_UDATA_NICENAME = "Config_NiceName"
static StrConstant EXPCONFIG_UDATA_JSONPATH = "Config_GroupPath"
static StrConstant EXPCONFIG_UDATA_EXCLUDE_SAVE = "Config_DontSave"
static StrConstant EXPCONFIG_UDATA_EXCLUDE_RESTORE = "Config_DontRestore"
static StrConstant EXPCONFIG_UDATA_BUTTONPRESS = "Config_PushButtonOnRestore"
// Lower means higher priority
static StrConstant EXPCONFIG_UDATA_RESTORE_PRIORITY = "Config_RestorePriority"
static StrConstant EXPCONFIG_UDATA_WINHANDLE = "Config_WindowHandle"
static StrConstant EXPCONFIG_UDATA_RADIOCOUPLING = "Config_RadioCouplingFunc"
static StrConstant EXPCONFIG_UDATA_CTRLARRAY = "ControlArray"
static StrConstant EXPCONFIG_UDATA_CTRLARRAYINDEX = "ControlArrayIndex"

static Constant EXPCONFIG_UDATA_MAXCTRLARRAYINDEX = 100
static Constant EXPCONFIG_JSON_INDENT = 4
static StrConstant EXPCONFIG_FILEFILTER = "Configuration Files (*.json):.json;All Files:.*;"
static StrConstant EXPCONFIG_CTRLGROUP_SUFFIX = " ControlGroup"
static StrConstant EXPCONFIG_SETTINGS_FOLDER = "Settings"

// DA_Ephys specific constants
static StrConstant DAEPHYS_UDATA_WINHANDLE = "DAEphys_WindowHandle"
// Headstage checkboxes ctrl niceName prefix
static StrConstant DAEPHYS_HEADSTAGECTRLARRAYPREFIX = "Check_DataAcqHS"
static StrConstant DAEPHYS_EXCLUDE_CTRLTYPES = "12;9;10;4;"

static StrConstant EXPCONFIG_DEFAULT_CTRL_JSONPATH = "Generic"
static StrConstant EXPCONFIG_RESERVED_DATABLOCK = "Common configuration data"
static StrConstant EXPCONFIG_RESERVED_TAGENTRY = "Target Window Type"

static StrConstant EXPCONFIG_EXCLUDE_USERDATA = "ResizeControlsInfo;"
static StrConstant EXPCONFIG_EXCLUDE_CTRLTYPES = "12;9;10;"

static StrConstant EXPCONFIG_SETTINGS_AMPTITLE = "0,1;2,3;4,5;6,7"


static StrConstant EXPCONFIG_JSON_HSASSOCBLOCK = "Headstage Association"
static StrConstant EXPCONFIG_JSON_AMPSERIAL = "Amplifier Serial"
static StrConstant EXPCONFIG_JSON_AMPTITLE = "Amplifier Title"
static StrConstant EXPCONFIG_JSON_AMPCHANNEL = "Amplifier Channel"
static StrConstant EXPCONFIG_JSON_AMPVCDA = "VC DA"
static StrConstant EXPCONFIG_JSON_AMPVCAD = "VC AD"
static StrConstant EXPCONFIG_JSON_AMPICDA = "IC DA"
static StrConstant EXPCONFIG_JSON_AMPICAD = "IC AD"
static StrConstant EXPCONFIG_JSON_PRESSDEV = "Pressure Device"
static StrConstant EXPCONFIG_JSON_PRESSDA = "Pressure DA"
static StrConstant EXPCONFIG_JSON_PRESSAD = "Pressure AD"
static StrConstant EXPCONFIG_JSON_PRESSDAGAIN = "Pressure DA Gain"
static StrConstant EXPCONFIG_JSON_PRESSADGAIN = "Pressure AD Gain"
static StrConstant EXPCONFIG_JSON_PRESSDAUNIT = "Pressure DA Unit"
static StrConstant EXPCONFIG_JSON_PRESSADUNIT = "Pressure AD Unit"
static StrConstant EXPCONFIG_JSON_PRESSTTLA = "Pressure TTLA"
static StrConstant EXPCONFIG_JSON_PRESSTTLB = "Pressure TTLB"
static StrConstant EXPCONFIG_JSON_PRESSCONSTNEG = "Pressure Constant Negative"
static StrConstant EXPCONFIG_JSON_PRESSCONSTPOS = "Pressure Constant Positive"

static StrConstant EXPCONFIG_JSON_USERPRESSBLOCK = "User Pressure Devices"
static StrConstant EXPCONFIG_JSON_USERPRESSDEV = "DAC Device"
static StrConstant EXPCONFIG_JSON_USERPRESSDA = "Pressure DA"

static StrConstant EXPCONFIG_RIGFILESUFFIX = "_rig.json"

static Constant EXPCONFIG_MIDDLEEXP_OFF = 0
static Constant EXPCONFIG_MIDDLEEXP_ON = 1

/// @brief Creates a json with default experiment configuration block
///
/// @returns json with default experiment configuration
static Function CONF_DefaultSettings()

	variable jsonID

	jsonID = JSON_New()

	JSON_AddString(jsonID, POSITION_MCC, NONE)
	JSON_AddString(jsonID, STIMSET_NAME, "")
	JSON_AddString(jsonID, SAVE_PATH, "C:MiesSave")

	return jsonID
End

/// @brief Automatically loads all *.json files from MIES Settings folder and opens and restores the corresponding windows
///        Files are restored in case-insensitive alphanumeric order. Associated *_rig.json files are taken into account.
Function CONF_AutoLoader()

	variable i, numFiles
	string fileList, fullFilePath, rigCandidate
	string settingsPath = CONF_GetSettingsPath()

	ASSERT(!IsEmpty(settingsPath), "Unable to resolve MIES Settings folder path. Is it present and readable in Packages\\Settings ?")
	NewPath/O/Q PathSettings, settingsPath
	fileList = GetAllFilesRecursivelyFromPath("PathSettings", extension = ".json")
	if(IsEmpty(fileList))
		printf "There are no files to load from the %s folder.\r", EXPCONFIG_SETTINGS_FOLDER
		ControlWindowToFront()
		Abort
	endif

	WAVE/T rawFileList = ListToTextWave(fileList, "|")
	rawFileList[] = LowerStr(rawFileList[p])
	WAVE/T/Z mainFileList
	WAVE/T/Z rigFileList
	[rigFileList, mainFileList] = SplitTextWaveBySuffix(rawFileList, LowerStr(EXPCONFIG_RIGFILESUFFIX))

	Sort mainFileList, mainFileList
	numFiles = DimSize(mainFileList, ROWS)
	for(i = 0; i < numFiles; i += 1)
		rigCandidate = mainFileList[i]
		rigCandidate = rigCandidate[0, strlen(rigCandidate) - 6] + EXPCONFIG_RIGFILESUFFIX
		FindValue/TXOP=4/TEXT=rigCandidate rigFileList
		if(V_Value == -1)
			rigCandidate = ""
		endif
		CONF_RestoreWindow(mainFileList[i], rigFile = rigCandidate, usePanelTypeFromFile = 1)
	endfor
End

/// @brief Returns the path to the settings folder
///
/// @returns string with full path to MIES Settings folder
static Function/S CONF_GetSettingsPath()

	variable numItems
	string reflectedProcpath = FunctionPath("CONF_GetSettingsPath")

	numItems = ItemsInList(reflectedProcpath, ":")
	if(numItems < 2)
		return ""
	endif
	reflectedProcpath = RemoveListItem(numItems - 1, reflectedProcpath, ":")
	reflectedProcpath = RemoveListItem(numItems - 2, reflectedProcpath, ":") + EXPCONFIG_SETTINGS_FOLDER + ":"

	if(FolderExists(reflectedProcpath))
		return reflectedProcpath
	endif

	return ""
End

/// @brief Saves the GUI state of a window and all of its subwindows to a configuration file
///
/// @param fName file name of configuration file to save configuration
Function CONF_SaveWindow(fName)
	string fName

	variable i, jsonID, saveMask, saveResult
	string out, wName, errMsg

	try
		wName = GetMainWindow(GetCurrentWindow())
		if(!CmpStr(wName, "HistoryCarbonCopy"))
			printf "Please select a window.\r"
			ControlWindowToFront()
			return NaN
		endif
		if(PanelIsType(wName, PANELTAG_DAEPHYS))
			CONF_SaveDAEphys(fName)
		else
			saveMask = EXPCONFIG_SAVE_VALUE
			jsonID = CONF_AllWindowsToJSON(wName, saveMask, excCtrlTypes = EXPCONFIG_EXCLUDE_CTRLTYPES)
			out = JSON_Dump(jsonID, indent = EXPCONFIG_JSON_INDENT)
			JSON_Release(jsonID)

			saveResult = SaveTextFile(out, fName, fileFilter = EXPCONFIG_FILEFILTER, message = "Save configuration file for window")
			if(!IsNaN(saveResult))
				print "Configuration saved."
			else
				print "Save FAILED!"
			endif
		endif
	catch
		errMsg = getRTErrMessage()
		if(getRTError(1))
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry
End

/// @brief Restores the GUI state of window and all of its subwindows from a configuration file
///
/// @param fName file name of configuration file to read configuration
/// @param usePanelTypeFromFile [optional, default = 0] if set to 1 then the panel type from the json is interpreted and a new panel of that type is opened
/// @param rigFile [optional, default = ""] name of secondary rig configuration file with complementary data. This parameter is valid when loading for a DA_Ephys panel
Function CONF_RestoreWindow(fName[, usePanelTypeFromFile, rigFile])
	string fName
	variable usePanelTypeFromFile
	string rigFile

	variable jsonID, restoreMask
	string input, wName, errMsg, fullFilePath, panelType

	usePanelTypeFromFile = ParamIsDefault(usePanelTypeFromFile) ? 0 : !!usePanelTypeFromFile
	rigFile = SelectString(ParamIsDefault(rigFile), rigFile, "")

	jsonID = NaN
	restoreMask = EXPCONFIG_SAVE_VALUE | EXPCONFIG_SAVE_USERDATA | EXPCONFIG_SAVE_DISABLED
	try
		if(usePanelTypeFromFile)
			[input, fullFilePath] = LoadTextFile(fName, fileFilter = EXPCONFIG_FILEFILTER, message = "Open configuration file")
			if(IsEmpty(input))
				return 0
			endif
			jsonID = CONF_ParseJSON(input)
			panelType = JSON_GetString(jsonID, "/" + EXPCONFIG_RESERVED_TAGENTRY)
			ASSERT(!IsEmpty(panelType), "Configuration file entry for panel type (" + EXPCONFIG_RESERVED_TAGENTRY + ") is empty.")
			if(!CmpStr(panelType, PANELTAG_DAEPHYS))
				if(!IsEmpty(rigFile))
					CONF_JoinRigFile(jsonID, rigFile)
				endif
				wName = CONF_RestoreDAEphys(jsonID, fullFilePath, forceNewPanel = 1)
			elseif(!CmpStr(panelType, PANELTAG_DATABROWSER))
				DB_OpenDataBrowser()
				wName = GetMainWindow(GetCurrentWindow())
				wName = CONF_JSONToWindow(wName, restoreMask, jsonID)
				print "Configuration restored for " + wName
			else
				ASSERT(0, "Configuration file entry for panel type has an unknown panel tag (" + panelType + ").")
			endif

		else
			wName = GetMainWindow(GetCurrentWindow())
			if(PanelIsType(wName, PANELTAG_DAEPHYS))
				[input, fullFilePath] = LoadTextFile(fName, fileFilter = EXPCONFIG_FILEFILTER, message = "Open configuration file for DA_Ephys panel")
				if(IsEmpty(input))
					return 0
				endif
				jsonID = CONF_ParseJSON(input)
				if(!IsEmpty(rigFile))
					CONF_JoinRigFile(jsonID, rigFile)
				endif
				wName = CONF_RestoreDAEphys(jsonID, fullFilePath)
			else
				[input, fullFilePath] = LoadTextFile(fName, fileFilter = EXPCONFIG_FILEFILTER, message = "Open configuration file for frontmost window")
				if(IsEmpty(input))
					return 0
				endif
				jsonID = CONF_ParseJSON(input)
				wName = CONF_JSONToWindow(wName, restoreMask, jsonID)
				print "Configuration restored for " + wName
			endif
		endif

		CONF_AddConfigFileUserData(wName, fullFilePath, rigFile)
	catch
		errMsg = getRTErrMessage()
		if(!IsNaN(jsonID))
			JSON_Release(jsonID)
		endif
		if(getRTError(1))
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry
	JSON_Release(jsonID)
End

/// @brief Saves the GUI state of a DA_Ephys panel to a configuration file
///
/// @param fName file name of configuration file to store DA_Ephys configuration
static Function CONF_SaveDAEphys(fName)
	string fName

	variable i, jsonID, saveMask, saveResult
	string out, wName, errMsg

	try
		wName = GetMainWindow(GetCurrentWindow())
		ASSERT(PanelIsType(wName, PANELTAG_DAEPHYS), "Current window is no DA_Ephys panel")

		saveMask = EXPCONFIG_SAVE_VALUE | EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY | EXPCONFIG_SAVE_BUTTONS_ONLY_PRESSED | EXPCONFIG_SAVE_ONLY_RELEVANT
		jsonID = CONF_AllWindowsToJSON(wName, saveMask, excCtrlTypes = DAEPHYS_EXCLUDE_CTRLTYPES)

		JSON_SetJSON(jsonID, EXPCONFIG_RESERVED_DATABLOCK, CONF_DefaultSettings())
		JSON_SetJSON(jsonID, EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_HSASSOCBLOCK, CONF_GetHeadstageAssociation(wName))
		JSON_SetJSON(jsonID, EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_USERPRESSBLOCK, CONF_GetUserPressure(wName))

		out = JSON_Dump(jsonID, indent = EXPCONFIG_JSON_INDENT)
		JSON_Release(jsonID)

		saveResult = SaveTextFile(out, fName, fileFilter = EXPCONFIG_FILEFILTER, message = "Save configuration file for DA_Ephys panel")
		if(!IsNaN(saveResult))
			print "Configuration saved."
		endif
	catch
		errMsg = getRTErrMessage()
		if(getRTError(1))
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry
End

/// @brief Restores the GUI state of a DA_Ephys panel from a configuration file
///
/// @param jsonID json ID of json object to restore DA_Ephys panel from
/// @param fullFilePath full file path of the file where the json object was parsed from
/// @param middleOfExperiment [optional, default = 0] Allows MIES config in the middle of experiment. Instead of setting MCC parameters they are pulled from actively recording MCCs to configure MIES]
/// @param forceNewPanel [optional, default = 0] When set opens always a fresh DA_Ephys panel, otherwise follows this priority order:
///                      - Reuses locked DA_Ephys panel with same device as saved in configuration
///                      - Uses open unlocked DA_Ephys panel
///                      - Opens new DA_Ephys panel
///
/// @return name of the created DAEphys panel
Function/S CONF_RestoreDAEphys(jsonID, fullFilePath, [middleOfExperiment, forceNewPanel])
	variable jsonID
	string fullFilePath
	variable middleOfExperiment, forceNewPanel

	variable i, fnum, restoreMask, numPotentialUnlocked, err, winConfigChanged, isTagged
	string panelTitle, getWName, jsonPath, potentialUnlockedList, winHandle, errMsg
	string AmpSerialLocal, AmpTitleLocal, device, StimSetPath, path, filename, rStateSync
	string input = ""

	try
		middleOfExperiment = ParamIsDefault(middleOfExperiment) ? 0 : !!middleOfExperiment
		forceNewPanel = ParamIsDefault(forceNewPanel) ? 0 : !!forceNewPanel

		if(forceNewPanel)
			panelTitle = DAP_CreateDAEphysPanel()
		else
			device = CONF_GetStringFromSavedControl(jsonID, "popup_MoreSettings_Devices")
			panelTitle = ""
			if(WindowExists(device))
				panelTitle = device
				if(PanelIsType(panelTitle, PANELTAG_DAEPHYS))
					winHandle = num2istr(GetUniqueInteger())
					SetWindow $panelTitle, userdata($EXPCONFIG_UDATA_WINHANDLE) = winHandle
					PGC_SetAndActivateControl(panelTitle, "button_SettingsPlus_unLockDevic")
					panelTitle = CONF_FindWindow(winHandle)
					ASSERT(!IsEmpty(panelTitle), "Could not find unlocked window, did it close?")
				endif
			endif
			if(IsEmpty(panelTitle))
				potentialUnlockedList = GetListOfUnlockedDevices()
				if(!IsEmpty(potentialUnlockedList))
					numPotentialUnlocked = ItemsInList(potentialUnlockedList)
					for(i = 0; i < numPotentialUnlocked; i += 1)
						panelTitle = StringFromList(i, potentialUnlockedList)
						if(PanelIsType(panelTitle, PANELTAG_DAEPHYS))
							break
						endif
					endfor
				endif
			endif
			if(IsEmpty(panelTitle))
				panelTitle = DAP_CreateDAEphysPanel()
			endif
		endif

		if(middleOfExperiment)
			PGC_SetAndActivateControl(panelTitle, "check_Settings_SyncMiesToMCC", val = CHECKBOX_UNSELECTED)
			rStateSync = GetUserData(panelTitle, "check_Settings_SyncMiesToMCC", EXPCONFIG_UDATA_EXCLUDE_RESTORE)
			ModifyControl $"check_Settings_SyncMiesToMCC" win=$panelTitle, userdata($EXPCONFIG_UDATA_EXCLUDE_RESTORE)="1"
			winConfigChanged = 1
		endif

		StimSetPath = CONF_GetStringFromSettings(jsonID, STIMSET_NAME)
		if(!IsEmpty(StimSetPath))
			if(FileExists(StimSetPath))
				err = NWB_LoadAllStimSets(overwrite = 1, fileName = StimSetPath)
				if(err)
					print "Stim set failed to load, check file path"
					ControlWindowToFront()
				endif
			else
				print "Specified StimSet file at " + StimSetPath + " not found! No file was loaded."
			endif
		endif

		restoreMask = EXPCONFIG_SAVE_VALUE | EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY | EXPCONFIG_SAVE_DISABLED | EXPCONFIG_SAVE_ONLY_RELEVANT | EXPCONFIG_MINIMIZE_ON_RESTORE
		winHandle = num2istr(GetUniqueInteger())
		SetWindow $panelTitle, userdata($DAEPHYS_UDATA_WINHANDLE) = winHandle
		isTagged = 1
		panelTitle = CONF_JSONToWindow(panelTitle, restoreMask, jsonID)
		isTagged = 0
		SetWindow $panelTitle, userdata($DAEPHYS_UDATA_WINHANDLE) = ""
		if(restoreMask & EXPCONFIG_MINIMIZE_ON_RESTORE)
			SetWindow $panelTitle, hide=1
		endif

		if(middleOfExperiment)
			ModifyControl $"check_Settings_SyncMiesToMCC" win=$panelTitle, userdata($EXPCONFIG_UDATA_EXCLUDE_RESTORE)=rStateSync
		endif

		CONF_RestoreHeadstageAssociation(panelTitle, jsonID, middleOfExperiment)
		CONF_RestoreUserPressure(panelTitle, jsonID)

		filename = GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX
		path = CONF_GetStringFromSettings(jsonID, SAVE_PATH)

		if(IsDriveValid(path))
			CreateFolderOnDisk(path)
		endif

		NewPath/C/O SavePath, path

		SaveExperiment /P=SavePath as filename

		KillPath/Z SavePath

		PGC_SetAndActivateControl(panelTitle, "StartTestPulseButton", switchTab = 1)

		print "Start Sciencing"
		SetWindow $panelTitle, hide=0, needUpdate=1
		return panelTitle
	catch
		if(isTagged)
			panelTitle = CONF_FindWindow(winHandle, uKey = DAEPHYS_UDATA_WINHANDLE)
		endif
		if(!IsEmpty(panelTitle) && WindowExists(panelTitle))
			SetWindow $panelTitle, userdata($DAEPHYS_UDATA_WINHANDLE) = ""
			if(middleOfExperiment & winConfigChanged)
				ModifyControl $"check_Settings_SyncMiesToMCC" win=$panelTitle, userdata($EXPCONFIG_UDATA_EXCLUDE_RESTORE)=rStateSync
			endif
			SetWindow $panelTitle, hide=0, needUpdate=1
		endif
		errMsg = getRTErrMessage()
		if(getRTError(1))
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry
End

/// @brief Add the config file paths and SHA-256 hashes to the panel as user data
static Function CONF_AddConfigFileUserData(win, fullFilePath, rigFile)
	string win, fullFilePath, rigFile

	SetWindow $win, userData($EXPCONFIG_UDATA_SOURCEFILE_PATH)=fullFilePath + "|" + rigFile

	if(FileExists(rigFile))
		SetWindow $win, userData($EXPCONFIG_UDATA_SOURCEFILE_HASH)=CalcHashForFile(fullFilePath) + "|" + CalcHashForFile(rigFile)
	else
		SetWindow $win, userData($EXPCONFIG_UDATA_SOURCEFILE_HASH)=CalcHashForFile(fullFilePath) + "|"
	endif
End

/// @brief Parses a json formatted string to a json object. This function shows a helpful error message if the parse fails
///
/// @param[in] str string in json format
/// @returns jsonID of the json object
static Function CONF_ParseJSON(str)
	string str

	variable err

	try
		JSONXOP_Parse/Z=0/Q=0 str; AbortOnRTE
		return V_Value
	catch
		err = getRTError(1)
		ASSERT(0, "The text from the configuration file could not be parsed.\rThe above information helps to find the problematic location.\r")
	endtry

	return NaN
End

/// @brief Retrieves list of active headstages saved in a DA_Ephys configuration file
///
/// @param jsonID  ID of existing json
/// @returns List of active head stages
static Function/S CONF_GetDAEphysActiveHeadstages(jsonID)
	variable jsonID

	WAVE hsStates = CONF_GetWaveFromSavedControlArray(jsonID, DAEPHYS_HEADSTAGECTRLARRAYPREFIX)
	return NumericWaveToList(hsStates, ";")
end

/// @brief Checks if EXPCONFIG_RESERVED_DATABLOCK exists in json; ASSERTion is thrown if not found.
///
/// @param jsonID  ID of existing json
static Function CONF_RequireConfigBlockExists(jsonID)
	variable jsonID

	WAVE/T ctrlGroups = JSON_GetKeys(jsonID, "")
	FindValue/TXOP=4/TEXT=EXPCONFIG_RESERVED_DATABLOCK ctrlGroups
	ASSERT(V_Value >= 0, "\"" + EXPCONFIG_RESERVED_DATABLOCK + "\" block in config file not found.")
End

/// @brief Retrieves a string value from a setting
///
/// @param jsonID  ID of existing json
/// @param keyName key name of setting
/// @returns string from member with keyname in the EXPCONFIG_RESERVED_DATABLOCK
static Function/S CONF_GetStringFromSettings(jsonID, keyName)
	variable jsonID
	string keyName

	CONF_RequireConfigBlockExists(jsonID)
	return JSON_GetString(jsonID, EXPCONFIG_RESERVED_DATABLOCK + "/" + keyName)
End

/// @brief Retrieves a variable value from a setting
///
/// @param jsonID  ID of existing json
/// @param keyName key name of setting
/// @returns value of member with keyname in the EXPCONFIG_RESERVED_DATABLOCK
static Function CONF_GetVariableFromSettings(jsonID, keyName)
	variable jsonID
	string keyName

	CONF_RequireConfigBlockExists(jsonID)
	return JSON_GetVariable(jsonID, EXPCONFIG_RESERVED_DATABLOCK + "/" + keyName)
End

/// @brief Retrieves a boolean value from a saved control
///        note: boolean control property values are also saved in the EXPCONFIG_FIELD_CTRLVVALUE field
///
/// @param jsonID  ID of existing json
/// @param keyName key name of setting
/// @returns value of the EXPCONFIG_FIELD_CTRLVVALUE field of the control
static Function CONF_GetBooleanFromSettings(jsonID, keyName)
	variable jsonID
	string keyName

	return CONF_GetVariableFromSettings(jsonID, keyName)
End

/// @brief Returns the path to the first control named nicename found in the json in all saved windows
///        This might as well be a ControlArray.
///
/// @param jsonID   ID of existing json
/// @param niceName nice name of control
/// @returns Path to control in json, empty string if not found
static Function/S CONF_FindControl(jsonID, niceName)
	variable jsonID
	string niceName

	variable i, numWindows
	string result

	WAVE/T winNames = CONF_GetWindowNames(jsonID)
	numWindows = DimSize(winNames, ROWS)
	for(i = 0; i < numWindows; i += 1)
		result = CONF_TraversalFinder(jsonID, winNames[i], niceName)
		if(!IsEmpty(result))
			return result
		endif
	endfor

	return ""
End

/// @brief Returns the path to the first control named nicename found traversing the json starting at basePath
///        This might as well be a ControlArray. This function runs recursively.
///
/// @param jsonID   ID of existing json
/// @param basePath root of traversal start
/// @param niceName nice name of control
/// @returns Path to control in json, empty string if not found
static Function/S CONF_TraversalFinder(jsonID, basePath, niceName)
	variable jsonID
	string basePath, niceName


	variable i, numElems
	string result

	WAVE/T ctrlGroups = JSON_GetKeys(jsonID, basePath)

	WAVE/T/Z ctrlSubGroups
	WAVE/T/Z niceNames
	[ctrlSubGroups, niceNames] = SplitTextWaveBySuffix(ctrlGroups, EXPCONFIG_CTRLGROUP_SUFFIX)
	FindValue/TXOP=4/TEXT=niceName niceNames
	if(V_Value >= 0)
		return basePath + "/" + niceName
	endif

	numElems = DimSize(ctrlSubGroups, ROWS)
	for(i = 0; i < numElems; i += 1)
		result = CONF_TraversalFinder(jsonID, basePath + "/" + ctrlSubGroups[i], niceName)
		if(!IsEmpty(result))
			return result
		endif
	endfor

	return ""
End

/// @brief Retrieves a wave from a saved ControlArray
///        It is REQUIRED that ALL ELEMENTS of the ControlArray are of NUMERIC type
///
/// @param jsonID    ID of existing json
/// @param arrayName name of ControlArray
/// @returns text wave with data from ControlArray
static Function/WAVE CONF_GetWaveFromSavedControlArray(jsonID, arrayName)
	variable jsonID
	string arrayName

	string arrayPath = CONF_FindControl(jsonID, arrayName)
	ASSERT(!IsEmpty(arrayPath), "Can not find ControlArray " + arrayName + " in config file.")
	return JSON_GetWave(jsonID, arrayPath + "/" + EXPCONFIG_FIELD_CTRLARRAYVALUES)
End

/// @brief Retrieves a string value from a saved control
///
/// @param jsonID   ID of existing json
/// @param niceName nice name of control
/// @returns value of the EXPCONFIG_FIELD_CTRLSVALUE field of the control
static Function/S CONF_GetStringFromSavedControl(jsonID, niceName)
	variable jsonID
	string niceName

	string ctrlPath = CONF_FindControl(jsonID, niceName)
	ASSERT(!IsEmpty(ctrlPath), "Can not find control " + niceName + " in config file.")
	return JSON_GetString(jsonID, ctrlPath + "/" + EXPCONFIG_FIELD_CTRLSVALUE)
End

/// @brief Retrieves a variable value from a saved control
///
/// @param jsonID   ID of existing json
/// @param niceName nice name of control
/// @returns value of the EXPCONFIG_FIELD_CTRLVVALUE field of the control
static Function CONF_GetVariableFromSavedControl(jsonID, niceName)
	variable jsonID
	string niceName

	string ctrlPath = CONF_FindControl(jsonID, niceName)
	ASSERT(!IsEmpty(ctrlPath), "Can not find control " + niceName + " in config file.")
	return JSON_GetVariable(jsonID, ctrlPath + "/" + EXPCONFIG_FIELD_CTRLVVALUE)
End

/// @brief Returns a wave with all configuration sections ( aka control groups).
///        This equals the top level keys without the EXPCONFIG_RESERVED_DATABLOCK key.
///
/// @param[in] jsonID ID of existing json
/// @returns Text wave with all named configuration sections
static Function/WAVE CONF_GetWindowNames(jsonID)
	variable jsonID

	WAVE/T ctrlGroups = JSON_GetKeys(jsonID, "")
	RemoveTextWaveEntry1D(ctrlGroups, EXPCONFIG_RESERVED_DATABLOCK)
	RemoveTextWaveEntry1D(ctrlGroups, EXPCONFIG_RESERVED_TAGENTRY)

	return ctrlGroups
End

/// @brief Returns a two column free wave with ControlArrayName and associated control list from a window
///
/// @param[in] wName Name of window
/// @returns Text wave with two columns and in each row ControlArray name (column ARRAYNAME) and control list (column CTRLNAMELIST)
static Function/WAVE CONF_GetControlArrayList(wName)
	string wName

	string ctrlList, ctrlName, arrayName
	variable i, numWinCtrl, col1, numCtrlArrays

	ctrlList = ControlNameList(wName, ";", "*")
	numWinCtrl = ItemsInList(ctrlList)

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE, 2) ctrlArrays
	SetDimLabel COLS, 0, ARRAYNAME, ctrlArrays
	SetDimLabel COLS, 1, CTRLNAMELIST, ctrlArrays

	col1 = FindDimLabel(ctrlArrays, COLS, "ARRAYNAME")
	for(i = 0; i < numWinCtrl; i += 1)
		ctrlName = StringFromList(i, ctrlList)
		arrayName = GetUserData(wName, ctrlName, EXPCONFIG_UDATA_CTRLARRAY)
		if(!IsEmpty(arrayName))
			FindValue/RMD=[][col1]/TXOP=4/TEXT=arrayName ctrlArrays
			if(V_Value >= 0)
				ctrlArrays[V_Row][%CTRLNAMELIST] = AddListItem(ctrlName, ctrlArrays[V_Row][%CTRLNAMELIST])
			else
				EnsureLargeEnoughWave(ctrlArrays, dimension = ROWS, minimumSize = numCtrlArrays)
				ctrlArrays[numCtrlArrays][%ARRAYNAME] = arrayName
				ctrlArrays[numCtrlArrays][%CTRLNAMELIST] = ctrlName
				numCtrlArrays += 1
			endif
		endif
	endfor

	return ctrlArrays
End

/// @brief Gathers recursively all control nice names and control paths from a configuration json by traversing all sub objects.
///
/// @param[in] ctrlData ctrlData wave, 2d four column text wave as created in CONF_JSONToWindow(). This wave is updated by this function.
/// @param[in] jsonID json object to traverse
/// @param[in] basePath root path for traversal
static Function CONF_GatherControlsFromJSON(ctrlData, jsonID, basePath)
	WAVE/T ctrlData
	variable jsonID
	string basePath

	variable i, numElems, offset

	WAVE/T ctrlGroups = JSON_GetKeys(jsonID, basePath)
	if(!DimSize(ctrlGroups, ROWS))
		return 0
	endif

	WAVE/T/Z ctrlSubGroups
	WAVE/T/Z niceNames
	[ctrlSubGroups, niceNames] = SplitTextWaveBySuffix(ctrlGroups, EXPCONFIG_CTRLGROUP_SUFFIX)

	numElems = DimSize(ctrlSubGroups, ROWS)
	for(i = 0; i < numElems; i += 1)
		CONF_GatherControlsFromJSON(ctrlData, jsonID, basePath + "/" + ctrlSubGroups[i])
	endfor

	numElems = DimSize(niceNames, ROWS)
	if(!numElems)
		return 0
	endif
	offset = DimSize(ctrlData, ROWS)
	Redimension/N=(numElems + offset, 4) ctrlData
	ctrlData[offset, offset + numElems - 1][%JSONPATH] = basePath + "/" + niceNames[p - offset]
	ctrlData[offset, offset + numElems - 1][%NICENAME] = niceNames[p - offset]
End

/// @brief Restores GUI state of a window from a json
///        The following userdata properties are considered: EXPCONFIG_UDATA_EXCLUDE_RESTORE, EXPCONFIG_UDATA_RESTORE_PRIORITY
///        It is supported that the current main reference window in the GUI changes its name. It is not supported
///        that a not yet restored subwindow of it changes its name.
///
/// @param wName       main reference window name in GUI
/// @param restoreMask Bit mask which properties are restored from WindowControlSavingMask constants
/// @param jsonID      ID of existing json
/// @returns name of main window after restore
Function/S CONF_JSONToWindow(wName, restoreMask, jsonID)
	string wName
	variable restoreMask, jsonID
	string excludeList

	variable i, colNiceName, colArrayName, colCtrlName, winNum, numCtrl, numWinCtrl, numGroups, numNice, offset, numWindows, numCtrlArrays, numArrayElem, isTagged
	variable arrayNameIndex
	string ctrlName, niceName, arrayName, ctrlList, wList, uData, winHandle, jsonCtrlGroupPath, subWinTarget, str, errMsg

	try

		ASSERT(WinType(wName), "Window " + wName + " does not exist!")
		ASSERT(restoreMask & (EXPCONFIG_SAVE_VALUE | EXPCONFIG_SAVE_POSITION | EXPCONFIG_SAVE_USERDATA | EXPCONFIG_SAVE_DISABLED | EXPCONFIG_SAVE_CTRLTYPE), "No property class enabled to restore in restoreMask.")

		SetWindow $wName, userData($EXPCONFIG_UDATA_SOURCEFILE_PATH)=""
		SetWindow $wName, userData($EXPCONFIG_UDATA_SOURCEFILE_HASH)=""

		if(restoreMask & EXPCONFIG_MINIMIZE_ON_RESTORE)
			SetWindow $wName, hide=1
		endif
		WAVE/T srcWinNames = CONF_GetWindowNames(jsonID)
		Duplicate/FREE/T srcWinNames tgtWinNames
		tgtWinNames[] = RemoveListItem(0, srcWinNames[p], "#")

		numWindows = DimSize(srcWinNames, ROWS)
		for(winNum = 0; winNum < numWindows; winNum += 1)
			str = tgtWinNames[winNum]
			subWinTarget = SelectString(IsEmpty(str), wName + "#" + str, wName)
			ASSERT(WinType(subWinTarget), "Window " + subWinTarget + " does not exist!")

			Make/FREE/T/N=(0, 4) ctrlData
			SetDimLabel COLS, 0, NICENAME, ctrlData
			SetDimLabel COLS, 1, CTRLNAME, ctrlData
			SetDimLabel COLS, 2, JSONPATH, ctrlData
			SetDimLabel COLS, 3, PRIORITY, ctrlData

			CONF_GatherControlsFromJSON(ctrlData, jsonID, srcWinNames[winNum])

			colNiceName = FindDimLabel(ctrlData, COLS, "NICENAME")
			numCtrl = DimSize(ctrlData, ROWS)
			if(numCtrl > 1)
				Duplicate/FREE/RMD=[][colNiceName] ctrlData ctrlNiceNames
				Redimension/N=(numCtrl) ctrlNiceNames
				FindDuplicates/DT=dupWave ctrlNiceNames
				ASSERT(DimSize(dupWave, ROWS) == 0, "Found duplicates in control names in configuration file for window " + subWinTarget)
			endif

			WAVE/T ctrlArrays = CONF_GetControlArrayList(subWinTarget)
			Make/FREE/B/U/N=(DimSize(ctrlArrays, ROWS)) ctrlArrayAdded
			ctrlList = ControlNameList(subWinTarget, ";", "*")
			numWinCtrl = ItemsInList(ctrlList)
			colArrayName = FindDimLabel(ctrlArrays, COLS, "ARRAYNAME")
			for(i = 0; i < numWinCtrl; i += 1)
				ctrlName = StringFromList(i, ctrlList)
				arrayName = GetUserData(subWinTarget, ctrlName, EXPCONFIG_UDATA_CTRLARRAY)
				if(!IsEmpty(arrayName))
					FindValue/RMD=[][colArrayName]/TXOP=4/TEXT=arrayName ctrlArrays
					if(V_Value >= 0)
						if(!ctrlArrayAdded[V_Row])
							arrayNameIndex = V_Row
							FindValue/RMD=[][colNiceName]/TXOP=4/TEXT=arrayName ctrlData
							if(V_Value >= 0)
								jsonCtrlGroupPath = ctrlData[V_Row][%JSONPATH]
								DeletePoints V_Row, 1, ctrlData
								numArrayElem = ItemsInList(ctrlArrays[arrayNameIndex][%CTRLNAMELIST])
								numCtrl = DimSize(ctrlData, ROWS)
								Redimension/N=(numCtrl + numArrayElem, 4) ctrlData
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%NICENAME] = arrayName
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%CTRLNAME] = StringFromList(p - numCtrl, ctrlArrays[arrayNameIndex][%CTRLNAMELIST])
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%JSONPATH] = jsonCtrlGroupPath
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%PRIORITY] = GetUserData(subWinTarget, ctrlData[p][%CTRLNAME], EXPCONFIG_UDATA_RESTORE_PRIORITY)
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%PRIORITY] = SelectString(strlen(ctrlData[p][%PRIORITY]), "Inf", ctrlData[p][%PRIORITY])
								ctrlArrayAdded[arrayNameIndex] = 1
							endif
						endif
					else
						printf "ControlArray %s from config file does not exist in window %s.\r", arrayName, subWinTarget
					endif
				else
					niceName = GetUserData(subWinTarget, ctrlName, EXPCONFIG_UDATA_NICENAME)
					niceName = SelectString(IsEmpty(niceName), niceName, ctrlName)
					FindValue/RMD=[][colNiceName]/TXOP=4/TEXT=niceName ctrlData
					if(V_Value >= 0)
						ctrlData[V_Row][%CTRLNAME] = ctrlName
						uData = GetUserData(subWinTarget, ctrlName, EXPCONFIG_UDATA_RESTORE_PRIORITY)
						ctrlData[V_Row][%PRIORITY] = SelectString(IsEmpty(uData), uData, "Inf")
					endif
				endif
			endfor

			numCtrl = DimSize(ctrlData, ROWS)
			for(i = numCtrl - 1; i >= 0; i -= 1)
				if(!CmpStr(GetUserData(subWinTarget, ctrlData[i][%CTRLNAME], EXPCONFIG_UDATA_EXCLUDE_RESTORE), "1"))
					DeletePoints i, 1, ctrlData
				endif
			endfor

			colCtrlName = FindDimLabel(ctrlData, COLS, "CTRLNAME")
			do
				FindValue/RMD=[][colCtrlName]/TXOP=4/TEXT="" ctrlData
				if(V_Value >= 0)
					printf "Control %s from config file does not exist in window %s.\r", ctrlData[V_Row][%NICENAME], subWinTarget
					DeletePoints V_Row, 1, ctrlData
				endif
			while(V_Value >= 0)

			numCtrl = DimSize(ctrlData, ROWS)
			if(!numCtrl)
				return wName
			endif
			Make/FREE/N=(numCtrl) prioritySort
			prioritySort[] = str2num(ctrlData[p][%PRIORITY])
			SortColumns keyWaves={prioritySort}, sortWaves={ctrlData}

			winHandle = num2istr(GetUniqueInteger())
			SetWindow $subWinTarget, userdata($EXPCONFIG_UDATA_WINHANDLE) = winHandle
			isTagged = 1
			for(i = 0; i < numCtrl; i += 1)
				CONF_RestoreControl(subWinTarget, restoreMask, jsonID, ctrlData[i][%CTRLNAME], jsonPath = ctrlData[i][%JSONPATH])
				subWinTarget = CONF_FindWindow(winHandle)
				ASSERT(!IsEmpty(subWinTarget), "Could not find window, did it close?")
			endfor
			wName = GetMainWindow(subWinTarget)
			isTagged = 0
			SetWindow $subWinTarget, userdata($EXPCONFIG_UDATA_WINHANDLE) = ""
		endfor
		if(restoreMask & EXPCONFIG_MINIMIZE_ON_RESTORE)
			SetWindow $wName, hide=0, needUpdate=1
		endif

	catch
		if(isTagged)
			wName = CONF_FindWindow(winHandle, uKey = EXPCONFIG_UDATA_WINHANDLE)
		endif
		if(!IsEmpty(wName) && WindowExists(wName))
			SetWindow $wName, hide=0, needUpdate=1
		endif
		errMsg = getRTErrMessage()
		if(getRTError(1))
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry

	return wName
End

/// @brief Returns the window with the set window handle
///
/// @param winHandle window handle
/// @param uKey      [optional, default = EXPCONFIG_UDATA_WINHANDLE] userdata key that stores the handle value
/// @returns Window name of the window with the given handle; empty string if not found.
static Function/S CONF_FindWindow(winHandle[, uKey])
	string winHandle, uKey

	variable i, j, numWin, numSubWin
	string wList, wName, wSubList

	uKey = SelectString(ParamIsDefault(uKey), uKey, EXPCONFIG_UDATA_WINHANDLE)
	wList = WinList("*", ";", "WIN:87")
	numWin = ItemsInList(wList)
	for(i = 0; i < numWin; i += 1)
		wName = StringFromList(i, wList)
		wSubList = GetAllWindows(wName)
		numSubWin = ItemsInList(wSubList)
		for(j = 0; j < numSubWin; j += 1)
			wName = StringFromList(j, wSubList)
			if(!CmpStr(winHandle, GetUserData(wName, "", uKey)))
				return wName
			endif
		endfor
	endfor

	return ""
End

/// @brief Restores properties of a control from a json
///        The following control userdata properties are considered: EXPCONFIG_UDATA_EXCLUDE_RESTORE; EXPCONFIG_UDATA_BUTTONPRESS (for Buttons)
///
/// @param wName       Window name
/// @param restoreMask Bit mask which properties are restored from WindowControlSavingMask constants
/// @param jsonID      ID of existing json
/// @param ctrlName    Control name
/// @param jsonPath    [optional, default = n/a] When given: the control is expected to be a named json object (with the control nice name)
///                    If not given: the jsons second level (assuming default format) is searched for the associated object. This is slower.
static Function CONF_RestoreControl(wName, restoreMask, jsonID, ctrlName[, jsonPath])
	string wName
	variable restoreMask, jsonID
	string ctrlName, jsonPath

	string ctrlTypeName, uData, uKey, base64Key, str, wList, niceName, arrayName, arrayElemPath
	variable i, base64Entries, ctrlType, setVarType, varTypeGlobal, val, numGroups, arrayElemType
	variable VHeight, VWidth, VTop, VLeft, VRight, VPos, VAlign
	variable VDisabled
	variable numUdataKeys, arrayIndex, arraySize

	ASSERT((restoreMask & (EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY | EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY)) != (EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY | EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY), "Invalid popup menu restore selection. String only and Index only can not be set at the same time.")
	ASSERT(WinType(wName), "Window " + wName + " does not exist!")

	if(!CmpStr(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_EXCLUDE_RESTORE), "1"))
		return NaN
	endif

	arrayName = GetUserData(wName, ctrlName, EXPCONFIG_UDATA_CTRLARRAY)
	if(ParamIsDefault(jsonPath))
		niceName = GetUserData(wName, ctrlName, EXPCONFIG_UDATA_NICENAME)
		niceName = SelectString(IsEmpty(niceName), niceName, ctrlName)
		niceName = SelectString(IsEmpty(arrayName), arrayName, niceName)
		jsonPath = CONF_FindControl(jsonID, niceName)
		ASSERT(!IsEmpty(jsonPath), "Control " + nicename + " not found in file.")
	endif

	WAVE/T ctrlPropList = JSON_GetKeys(jsonID, jsonPath)
	jsonPath = jsonPath + "/"

	if(IsEmpty(arrayName))

		FindValue/TXOP=4/TEXT=EXPCONFIG_FIELD_CTRLTYPE ctrlPropList
		if(V_Value >= 0)
			ctrlTypeName = JSON_GetString(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLTYPE)
			i = WhichListItem(ctrlTypeName, EXPCONFIG_GUI_CTRLLIST)
			ASSERT(i != -1, "Read unknown control type: " + ctrlTypeName)
			ctrlType = str2num(StringFromList(i, EXPCONFIG_GUI_CTRLTYPES))
			ControlInfo/W=$wName $ctrlName
			ASSERT(abs(V_Flag) == ctrlType, "Expected control of type " + ctrlTypeName + " in window " + wName)
		else
			ControlInfo/W=$wName $ctrlName
			ctrlType = abs(V_Flag)
		endif

		if(restoreMask & EXPCONFIG_SAVE_POSITION)
			VHeight = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLPOSHEIGHT)
			VWidth = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLPOSWIDTH)
			VTop = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLPOSTOP)
			VPos = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLPOSPOS)
			VAlign = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLPOSALIGN)
			ModifyControl $ctrlName win=$wName, align=VAlign, size={VWidth, VHeight}, pos={VPos, VTop}
		endif
		if(restoreMask & EXPCONFIG_SAVE_DISABLED)
			FindValue/TXOP=4/TEXT=EXPCONFIG_FIELD_CTRLDISABLED ctrlPropList
			if(V_Value >= 0)
				VDisabled = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLDISABLED)
				if(VDisabled & HIDDEN_CONTROL_BIT)
					HideControl(wName, ctrlName)
				elseif(VDisabled & DISABLE_CONTROL_BIT)
					DisableControl(wName, ctrlName)
				else
					ShowControl(wName, ctrlName)
					EnableControl(wName, ctrlName)
				endif
			endif
		endif
		if(restoreMask & EXPCONFIG_SAVE_USERDATA)
			FindValue/TXOP=4/TEXT=EXPCONFIG_FIELD_CTRLUSERDATA ctrlPropList
			if(V_Value >= 0)
				WAVE/T udataKeys = JSON_GetKeys(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLUSERDATA)

				Duplicate/T/FREE udataKeys, udataBase64
				numUdataKeys = DimSize(udataKeys, ROWS)
				for(i = numUdataKeys - 1; i >= 0; i -= 1)
					uKey = udataKeys[i]
					if(strsearch(uKey, EXPCONFIG_FIELD_BASE64PREFIX, 0) >= 0)
						base64Key = uKey[strlen(EXPCONFIG_FIELD_BASE64PREFIX), Inf]
						udataBase64[base64Entries] = base64Key
						base64Entries += 1
						DeletePoints i, 1, udataKeys
						i -= 1
					endif
				endfor
				Redimension/N=(base64Entries) udataBase64

				numUdataKeys = DimSize(udataKeys, ROWS)
				for(i = 0; i < numUdataKeys; i += 1)
					uKey = udataKeys[i]
					uData = JSON_GetString(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLUSERDATA + "/" + uKey)
					FindValue/TXOP=4/TEXT=uKey udataBase64
					if(V_Value >= 0)
						uData = Base64Decode(uData)
					endif
					if(IsEmpty(uKey))
						ModifyControl $ctrlName win=$wName, userdata=uData
					else
						ModifyControl $ctrlName win=$wName, userdata($uKey)=uData
					endif
				endfor
			endif
		endif
		if(restoreMask & EXPCONFIG_SAVE_VALUE)
			if(ctrlType == CONTROL_TYPE_CHECKBOX || ctrlType == CONTROL_TYPE_SLIDER || ctrlType == CONTROL_TYPE_TAB || ctrlType == CONTROL_TYPE_VALDISPLAY)
				val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLVVALUE)
				PGC_SetAndActivateControl(wName, ctrlName, val = val)
			elseif(ctrlType == CONTROL_TYPE_SETVARIABLE)
				setVarType = GetInternalSetVariableType(S_recreation)
				if(setVarType == SET_VARIABLE_BUILTIN_NUM)
					val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLVVALUE)
					PGC_SetAndActivateControl(wName, ctrlName, val = val)
				elseif(setVarType == SET_VARIABLE_BUILTIN_STR)
					str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLSVALUE)
					PGC_SetAndActivateControl(wName, ctrlName, str = str)
				else
					str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLSDF)
					if(IsEmpty(str))
						SetVariable $ctrlName win=$wName, value=$""
					else
						varTypeGlobal = exists(str)
						if(varTypeGlobal == EXISTS_AS_WAVE || varTypeGlobal == EXISTS_AS_VAR_OR_STR)
							SetVariable $ctrlName win=$wName, value=$str
						endif
					endif
				endif
			elseif(ctrlType == CONTROL_TYPE_POPUPMENU)
				if(restoreMask & EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY && !(restoreMask & EXPCONFIG_SAVE_ONLY_RELEVANT))
					val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLVVALUE)
					PGC_SetAndActivateControl(wName, ctrlName, val = val)
				else
					str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLSVALUE)
					PGC_SetAndActivateControl(wName, ctrlName, str = str)
				endif
			elseif(ctrlType == CONTROL_TYPE_BUTTON)
				if(!CmpStr(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_BUTTONPRESS), "1"))
					PGC_SetAndActivateControl(wName, ctrlName)
				endif
			elseif(ctrlType == CONTROL_TYPE_CHART)
			elseif(ctrlType == CONTROL_TYPE_CUSTOMCONTROL)
			elseif(ctrlType == CONTROL_TYPE_GROUPBOX)
			elseif(ctrlType == CONTROL_TYPE_LISTBOX)
			elseif(ctrlType == CONTROL_TYPE_TITLEBOX)
			else
				ASSERT(0, "Unknown control type to restore value")
			endif

		endif
	elseif(restoreMask & EXPCONFIG_SAVE_VALUE)
		arrayIndex = str2num(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_CTRLARRAYINDEX))
		ASSERT(!IsNaN(arrayIndex) && arrayIndex >= 0, "Read invalid ControlArrayIndex from userdata of control " + ctrlName)
		ASSERT(arrayIndex < EXPCONFIG_UDATA_MAXCTRLARRAYINDEX, "ControlArrayIndex is greater than " + num2istr(EXPCONFIG_UDATA_MAXCTRLARRAYINDEX) + ".")
		arraySize = JSON_GetArraySize(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLARRAYVALUES)
		ASSERT(arrayIndex < arraySize, "The ControlArray of control " + ctrlName + " has less data elements saved than the GUI control requests from its ControlArrayIndex.")
		arrayElemPath = jsonPath + EXPCONFIG_FIELD_CTRLARRAYVALUES + "/" + num2istr(arrayIndex)
		arrayElemType = JSON_GetType(jsonID, arrayElemPath)
		ASSERT(arrayElemType != JSON_NULL , "Value for element " + num2istr(arrayIndex) + " in ControlArray of control " + ctrlName + " was not saved.")

		ControlInfo/W=$wName $ctrlName
		ctrlType = abs(V_Flag)
		if(ctrlType == CONTROL_TYPE_TAB || ctrlType == CONTROL_TYPE_SLIDER || ctrlType == CONTROL_TYPE_VALDISPLAY)
			ASSERT(arrayElemType == JSON_NUMERIC, "Expected numeric value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
			val = JSON_GetVariable(jsonID, arrayElemPath)
			PGC_SetAndActivateControl(wName, ctrlName, val = val)
		elseif(ctrlType == CONTROL_TYPE_SETVARIABLE)
			setVarType = GetInternalSetVariableType(S_recreation)
			if(setVarType == SET_VARIABLE_BUILTIN_NUM)
				ASSERT(arrayElemType == JSON_NUMERIC, "Expected numeric value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
				val = JSON_GetVariable(jsonID, arrayElemPath)
				PGC_SetAndActivateControl(wName, ctrlName, val = val)
			else
				ASSERT(arrayElemType == JSON_STRING, "Expected string value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
				str = JSON_GetString(jsonID, arrayElemPath)
				if(setVarType == SET_VARIABLE_BUILTIN_STR)
					PGC_SetAndActivateControl(wName, ctrlName, str = str)
				elseif(IsEmpty(str))
					SetVariable $ctrlName win=$wName, value=$""
				else
					varTypeGlobal = exists(str)
					if(varTypeGlobal == EXISTS_AS_WAVE || varTypeGlobal == EXISTS_AS_VAR_OR_STR)
						SetVariable $ctrlName win=$wName, value=$str
					endif
				endif
			endif
		elseif(ctrlType == CONTROL_TYPE_POPUPMENU)
			if(restoreMask & EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY)
				ASSERT(arrayElemType == JSON_NUMERIC, "Expected numeric value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
				val = JSON_GetVariable(jsonID, arrayElemPath)
				PGC_SetAndActivateControl(wName, ctrlName, val = val)
			else
				ASSERT(arrayElemType == JSON_STRING, "Expected string value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
				str = JSON_GetString(jsonID, arrayElemPath)
				PGC_SetAndActivateControl(wName, ctrlName, str = str)
			endif
		elseif(ctrlType == CONTROL_TYPE_BUTTON)
			if(!CmpStr(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_BUTTONPRESS), "1"))
				PGC_SetAndActivateControl(wName, ctrlName)
			endif
		elseif(ctrlType == CONTROL_TYPE_CHECKBOX)
			ASSERT(arrayElemType == JSON_BOOL, "Expected boolean value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
			val = JSON_GetVariable(jsonID, arrayElemPath)
			PGC_SetAndActivateControl(wName, ctrlName, val = val)
		elseif(ctrlType == CONTROL_TYPE_CHART)
		elseif(ctrlType == CONTROL_TYPE_CUSTOMCONTROL)
		elseif(ctrlType == CONTROL_TYPE_GROUPBOX)
		elseif(ctrlType == CONTROL_TYPE_LISTBOX)
		elseif(ctrlType == CONTROL_TYPE_TITLEBOX)
		else
			ASSERT(0, "Unknown control type to restore value")
		endif

	endif
End

/// @brief Serializes all controls of a window and its subwindows into a json object
///
/// @param[in] wName name of main window
/// @param[in] saveMask bit pattern based configuration setting for saving @sa WindowControlSavingMask
/// @param[in] excCtrlTypes [optional, default = ""], list of control type codes for excluded control types for saving e.g. "1;6;" to exclude all buttons and charts
/// @returns json ID of object where all controls where serialized into
Function CONF_AllWindowsToJSON(wName, saveMask[, excCtrlTypes])
	string wName
	variable saveMask
	string excCtrlTypes

	string wList, curWinName, errMsg
	variable i, numWins, jsonID, jsonIDWin

	try
		excCtrlTypes = SelectString(ParamIsDefault(excCtrlTypes), excCtrlTypes, "")

		ASSERT(!CmpStr(wName, GetMainWindow(wName)), "Windows name is not a main window, use function CONF_WindowToJSON instead.")

		wList= GetAllWindows(wName)

		jsonID = JSON_New()

		JSON_AddString(jsonID, "/" + EXPCONFIG_RESERVED_TAGENTRY, GetUserData(wName, "", EXPCONFIG_UDATA_PANELTYPE))

		numWins = ItemsInList(wList)
		for(i = 0; i < numWins; i += 1)
			curWinName = StringFromList(i, wList)
			jsonIDWin = CONF_WindowToJSON(curWinName, saveMask, excCtrlTypes = excCtrlTypes)
			WAVE/T ctrlList = JSON_GetKeys(jsonIDWin, "")
			if(DimSize(ctrlList, ROWS))
				JSON_SetJSON(jsonID, curWinName, jsonIDWin)
			endif
			JSON_Release(jsonIDWin)
		endfor

		return jsoNID

	catch
		errMsg = getRTErrMessage()
		if(getRTError(1))
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry
End

Function/WAVE CONF_GetRadioButtonCouplingProtoFunc()
End

/// @brief Saves complete GUI state of a window in a json
///        For coupled CheckBoxes aka (radio buttons) the enabled radio button is saved, the disabled is not saved.
///        For three or more coupled CheckBoxes the first enabled radio button is saved, the disabled are not saved.
///        For three or more coupled CheckBoxes an assertion is thrown if no CheckBox is set.
///
/// @param wName               Window name
/// @param saveMask            Bit mask which properties are saved from WindowControlSavingMask constants
/// @param excCtrlTypes        [optional, default = ""] List of excluded control types that are ignored
/// @returns jsonID            ID of json containing the serialized GUI data
Function CONF_WindowToJSON(wName, saveMask[, excCtrlTypes])
	string wName
	variable saveMask
	string excCtrlTypes

	string ctrlList, ctrlName, radioList, tmpList, wList, cbCtrlName, coupledIndexKeys = "", excUserKeys, radioFunc, str, errMsg
	variable numCtrl, i, j, jsonID, numCoupled, setRadioPos, ctrlType, coupledCnt, numUniqueCtrlArray, numDupCheck
	variable rbcIndex

	try
		excCtrlTypes = SelectString(ParamIsDefault(excCtrlTypes), excCtrlTypes, "")
		ASSERT(WinType(wName), "Window " + wName + " does not exist!")
		jsonID = JSON_New()

		ctrlList = ControlNameList(wName, ";", "*")
		numCtrl = ItemsInList(ctrlList)
		if(!numCtrl)
			JSON_AddTreeObject(jsonID, "")
			return jsonID
		endif
		WAVE/T ctrlNames = ListToTextWave(ctrlList, ";")
		Redimension/N=(numCtrl, 2) ctrlNames
		SetDimLabel COLS, 0, CTRLNAME, ctrlNames
		SetDimLabel COLS, 1, NICENAME, ctrlNames

		ctrlNames[][%NICENAME] = GetUserData(wName, ctrlNames[p][%CTRLNAME], EXPCONFIG_UDATA_NICENAME)

		Make/FREE/T/N=(numCtrl) arrayNames
		arrayNames[] = GetUserData(wName, ctrlNames[p][%CTRLNAME], EXPCONFIG_UDATA_CTRLARRAY)
		if(numCtrl > 1)
			FindDuplicates/FREE/RT=arrayNamesRedux arrayNames
			arrayNamesRedux[] = LowerStr(arrayNamesRedux[p])
			FindValue/TXOP=4/TEXT="" arrayNamesRedux
			if(V_Value >= 0)
				DeletePoints V_Value, 1, arrayNamesRedux
			endif
		else
			Make/FREE/T/N=0 arrayNamesRedux
		endif

		Make/FREE/N=(numCtrl)/T duplicateCheck
		duplicateCheck[] = SelectString(strlen(ctrlNames[p][%NICENAME]), LowerStr(ctrlNames[p][%CTRLNAME]), LowerStr(ctrlNames[p][%NICENAME]))
		numUniqueCtrlArray = DimSize(arrayNamesRedux, ROWS)
		if(numUniqueCtrlArray)
			Redimension/N=(numCtrl + numUniqueCtrlArray) duplicateCheck
			duplicateCheck[numCtrl, numCtrl + numUniqueCtrlArray - 1] = arrayNamesRedux[p - numCtrl]
		endif

		numDupCheck = DimSize(duplicateCheck, ROWS)
		if(numDupCheck > 1)
			FindDuplicates/FREE/DT=duplicates duplicateCheck
			ASSERT(!DimSize(duplicates, ROWS), "Human readable control names combined with internal control names have duplicates: " + TextWaveToList(duplicates, ";"))
		endif
		Make/FREE/I/N=(numDupCheck) groupEndingCheck
		groupEndingCheck[] = StringEndsWith(duplicateCheck[p], LowerStr(EXPCONFIG_CTRLGROUP_SUFFIX))
		FindValue/I=1 groupEndingCheck
		if(V_Value >= 0)
			ASSERT(0, "Control with [nice] name " + duplicateCheck[V_Value] + " uses a reserved suffix for control groups. Please change it to avoid conflicts.")
		endif

		radioFunc = GetUserData(wName, "", EXPCONFIG_UDATA_RADIOCOUPLING)
		if(!IsEmpty(radioFunc))
			FUNCREF CONF_GetRadioButtonCouplingProtoFunc rCoupleFunc = $radioFunc
			WAVE/T radioButtonCoupling = rCoupleFunc()
			coupledCnt = DimSize(radioButtonCoupling, ROWS)
			for(i = 0; i < coupledCnt; i += 1)
				radioList = radioButtonCoupling[i]
				numCtrl = ItemsInList(radioList)
				for(j = 0; j < numCtrl; j += 1)
					coupledIndexKeys = ReplaceNumberByKey(StringFromList(j, radioList), coupledIndexKeys, i)
				endfor
			endfor

			numCtrl = ItemsInList(ctrlList)
			for(i = 0; i < numCtrl; i += 1)
				ctrlName = StringFromList(i, ctrlList)
				rbcIndex = NumberByKey(ctrlName, coupledIndexKeys)
				if(IsNaN(rbcIndex))
					continue
				endif
				radioList = radioButtonCoupling[rbcIndex]
				if(IsEmpty(radioList))
					continue
				endif
				radioButtonCoupling[rbcIndex] = ""

				numCoupled = ItemsInList(radioList)
				ASSERT(numCoupled >= 2, "At least two CheckBoxes must be coupled for Radio Buttons")
				if(numCoupled == 2)
					FindValue/TXOP=4/TEXT=StringFromList(1, radioList) ctrlNames
					ASSERT(V_Value >= 0, "Specified coupled CheckBox is not present as control in " + wName)
					DeletePoints V_Row, 1, ctrlNames
				else
					for(j = 0; j < numCoupled; j += 1)
						cbCtrlName = StringFromList(j, radioList)
						ControlInfo/W=$wName $cbCtrlName
						ctrlType = abs(V_Flag)
						ASSERT(ctrlType == 2, "Control is not present or not a CheckBox")
						if(V_Value)
							break
						endif
					endfor

					if(j < numCoupled)
						DEBUGPRINT("Ecountered >2 coupled CheckBoxes (RadioButtons) where all are in off state")
					endif

					setRadioPos = j
					for(j = 0; j < numCoupled; j += 1)
						cbCtrlName = StringFromList(j, radioList)
						if(setRadioPos != j)
							FindValue/TXOP=4/TEXT=cbCtrlName ctrlNames
							ASSERT(V_Value >= 0, "Specified coupled CheckBox " + cbCtrlName + " is not present as control in " + wName)
							DeletePoints V_Row, 1, ctrlNames
						endif
					endfor
				endif
			endfor
		endif

		excUserKeys = EXPCONFIG_EXCLUDE_USERDATA
		excUserKeys = AddListItem(EXPCONFIG_UDATA_NICENAME, excUserKeys)
		excUserKeys = AddListItem(EXPCONFIG_UDATA_JSONPATH, excUserKeys)
		excUserKeys = AddListItem(EXPCONFIG_UDATA_EXCLUDE_SAVE, excUserKeys)
		excUserKeys = AddListItem(EXPCONFIG_UDATA_EXCLUDE_RESTORE, excUserKeys)
		excUserKeys = AddListItem(EXPCONFIG_UDATA_BUTTONPRESS, excUserKeys)
		excUserKeys = AddListItem(EXPCONFIG_UDATA_RESTORE_PRIORITY, excUserKeys)
		excUserKeys = AddListItem(EXPCONFIG_UDATA_WINHANDLE, excUserKeys)

		numCtrl = DimSize(ctrlNames, ROWS)
		for(i = 0; i < numCtrl; i += 1)
			CONF_ControlToJSON(wName, ctrlNames[i][%CTRLNAME], saveMask, jsonID, excCtrlTypes, excUserKeys)
		endfor

		return jsonID

	catch
		errMsg = getRTErrMessage()
		if(getRTError(1))
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry
End

static Function/S CONF_GetCompleteJSONCtrlPath(path)
	string path

	variable i, numElems
	string completePath = ""

	numElems = ItemsInList(path)
	for(i = 0; i < numElems; i += 1)
		completePath = AddListItem(StringFromList(i, path) + EXPCONFIG_CTRLGROUP_SUFFIX, completePath, "/", Inf)
	endfor

	return completePath
End

/// @brief Adds properties of a control to a json
///
/// @param wName        Window name
/// @param ctrlName     Control name
/// @param saveMask     Bit mask which properties are saved from WindowControlSavingMask constants
/// @param jsonID       ID of existing json
/// @param excCtrlTypes List of excluded control types that are ignored
/// @param excUserKeys  List of excluded keys of userdata fields that are ignored
static Function CONF_ControlToJSON(wName, ctrlName, saveMask, jsonID, excCtrlTypes, excUserKeys)
	string wName, ctrlName
	variable saveMask
	variable jsonID
	string excCtrlTypes, excUserKeys

	variable ctrlType, pos, i, numUdataKeys, setVarType, err, arrayIndex, oldSize, preferCode, arrayElemType
	string wList, ctrlPath, controlPath, niceName, jsonPath, udataPath, udataKeys, uDataKey, uData, s, arrayName, arrayElemPath


	ASSERT((saveMask & (EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY | EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY)) != (EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY | EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY), "Invalid popup menu save selection. String only and Index only can not be set at the same time.")
	ASSERT(WinType(wName), "Window " + wName + " does not exist!")

	ControlInfo/W=$wName $ctrlName
	ctrlType = abs(V_Flag)
	ASSERT(ctrlType != 0, "Control does not exist")

	if(WhichListItem(num2str(ctrlType), excCtrlTypes) >= 0)
		return NaN
	endif
	if(!CmpStr(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_EXCLUDE_SAVE), "1"))
		return NaN
	endif

	niceName = GetUserData(wName, ctrlName, EXPCONFIG_UDATA_NICENAME)
	niceName = SelectString(IsEmpty(niceName), niceName, ctrlName)
	jsonPath = GetUserData(wName, ctrlName, EXPCONFIG_UDATA_JSONPATH)
	jsonPath = SelectString(IsEmpty(jsonPath), jsonPath, EXPCONFIG_DEFAULT_CTRL_JSONPATH)
	ASSERT(strsearch(jsonPath, "/", 0) == -1, "Control " + ctrlName + " has an invalid GroupPath configured in userdata containing a / character.")
	jsonPath = CONF_GetCompleteJSONCtrlPath(jsonPath)
	if(!CmpStr(jsonPath, EXPCONFIG_RESERVED_DATABLOCK))
		printf "Control %s has a reserved jsonPath configured in userdata, replacing with default path.\r", ctrlName
		jsonPath = EXPCONFIG_DEFAULT_CTRL_JSONPATH
	endif

	arrayName = GetUserData(wName, ctrlName, EXPCONFIG_UDATA_CTRLARRAY)
	niceName = SelectString(IsEmpty(arrayName), arrayName, niceName)
	controlPath = jsonPath + niceName
	JSON_AddTreeObject(jsonID, controlPath)
	ctrlPath = controlPath + "/"

	pos = WhichListItem(num2str(ctrlType), EXPCONFIG_GUI_CTRLTYPES)
	ASSERT(pos >= 0, "Unknown Control Type")

	if(IsEmpty(arrayName))

		if(IsNull(S_DataFolder))
			S_DataFolder = ""
		endif
		if(IsNull(S_Value))
			S_Value = ""
		endif

		if(saveMask & EXPCONFIG_SAVE_CTRLTYPE)
			JSON_AddString(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLTYPE, ControlTypeToName(ctrlType))
		endif

		if(saveMask & EXPCONFIG_SAVE_VALUE)
			if(ctrlType == CONTROL_TYPE_SETVARIABLE)
				setVarType = GetInternalSetVariableType(S_recreation)
				if(setVarType == SET_VARIABLE_BUILTIN_NUM)
					JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLVVALUE, V_Value)
				elseif(setVarType == SET_VARIABLE_BUILTIN_STR)
					JSON_AddString(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLSVALUE, S_Value)
				else
					JSON_AddString(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLSDF, S_DataFolder)
				endif
			elseif(ctrlType == CONTROL_TYPE_POPUPMENU)
				if(saveMask & EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY || saveMask & EXPCONFIG_SAVE_ONLY_RELEVANT)
					JSON_AddString(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLSVALUE, S_Value)
				elseif(saveMask & EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY)
					JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLVVALUE, V_Value)
				else
					JSON_AddString(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLSVALUE, S_Value)
					JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLVVALUE, V_Value)
				endif
			elseif(ctrlType == CONTROL_TYPE_BUTTON)
				if(saveMask & EXPCONFIG_SAVE_ONLY_RELEVANT)
					V_Value = 1
				endif
				if(saveMask & EXPCONFIG_SAVE_BUTTONS_ONLY_PRESSED)
					if(!CmpStr(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_BUTTONPRESS), "1"))
						JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLVVALUE, V_Value)
					endif
				else
					JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLVVALUE, V_Value)
				endif
			elseif(ctrlType == CONTROL_TYPE_CHECKBOX)
				JSON_AddBoolean(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLVVALUE, V_Value)
			else
				if(saveMask & EXPCONFIG_SAVE_ONLY_RELEVANT)
					preferCode = str2num(StringFromList(pos, EXPCONFIG_GUI_PREFERRED))
				endif
				if(preferCode == 0)
					if(str2num(StringFromList(pos, EXPCONFIG_GUI_VVALUE)))
						JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLVVALUE, V_Value)
					endif
					if(str2num(StringFromList(pos, EXPCONFIG_GUI_SVALUE)))
						JSON_AddString(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLSVALUE, S_Value)
					endif
					if(str2num(StringFromList(pos, EXPCONFIG_GUI_SDATAFOLDER)))
						JSON_AddString(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLSDF, S_DataFolder)
					endif
				elseif(preferCode == 1)
					JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLVVALUE, V_Value)
				elseif(preferCode == 2)
					JSON_AddString(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLSVALUE, S_Value)
				elseif(preferCode == 3)
					JSON_AddString(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLSDF, S_DataFolder)
				else
					ASSERT(0, "Unknown code for preference in EXPCONFIG_SAVE_ONLY_RELEVANT mode.")
				endif
			endif
		endif
		if(saveMask & EXPCONFIG_SAVE_DISABLED)
			JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLDISABLED, V_disable)
		endif
		if(saveMask & EXPCONFIG_SAVE_POSITION)
			JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLPOSHEIGHT, V_Height)
			JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLPOSWIDTH, V_Width)
			JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLPOSTOP, V_Top)
			JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLPOSPOS, V_Pos)
			JSON_AddVariable(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLPOSALIGN, V_Align)
		endif
		if(saveMask & EXPCONFIG_SAVE_USERDATA)
			udataPath = ctrlPath + EXPCONFIG_FIELD_CTRLUSERDATA
			JSON_AddTreeObject(jsonID, udataPath)
			udataPath = udataPath + "/"
			if(!IsEmpty(S_Userdata) && str2num(StringFromList(pos, EXPCONFIG_GUI_SUSERDATA)))
				JSON_AddString(jsonID, udataPath, S_Userdata)
			endif
			udataKeys = GetUserdataKeys(S_recreation)
			if(!IsEmpty(udataKeys))
				numUdataKeys = ItemsInList(udataKeys)
				for(i = 0; i < numUdataKeys; i +=1)
					uDataKey = StringFromList(i, udataKeys)
					if(WhichListItem(uDataKey, excUserKeys) >= 0)
						continue
					endif
					uData = GetUserData(wName, ctrlName, uDataKey)
					try
						s = ConvertTextEncoding(uData, TextEncodingCode("UTF-8"), TextEncodingCode("UTF-8"), 1, 0); AbortOnRTE
					catch
						err = GetRTError(1)
						uData = Base64Encode(udata)
						JSON_AddString(jsonID, udataPath + EXPCONFIG_FIELD_BASE64PREFIX + uDataKey, "1")
					endtry
					JSON_AddString(jsonID, udataPath + uDataKey, uData)
				endfor
			endif
		endif
	elseif(saveMask & EXPCONFIG_SAVE_VALUE)
		arrayIndex = str2num(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_CTRLARRAYINDEX))
		ASSERT(!IsNaN(arrayIndex) && arrayIndex >= 0, "Read invalid ControlArrayIndex from userdata of control " + ctrlName)
		ASSERT(arrayIndex < EXPCONFIG_UDATA_MAXCTRLARRAYINDEX, "ControlArrayIndex is greater than " + num2str(EXPCONFIG_UDATA_MAXCTRLARRAYINDEX) + ".")
		WAVE/T ctrlProps = JSON_GetKeys(jsonID, controlPath)
		FindValue/TXOP=4/TEXT=EXPCONFIG_FIELD_CTRLARRAYVALUES ctrlProps
		if(V_Value >= 0)
			oldSize = JSON_GetArraySize(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLARRAYVALUES)
		else
			JSON_AddTreeArray(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLARRAYVALUES)
			oldSize = 0
		endif
		for(i = oldSize; i < arrayIndex + 1; i += 1)
			JSON_AddNull(jsonID, ctrlPath + EXPCONFIG_FIELD_CTRLARRAYVALUES)
		endfor
		arrayElemPath = ctrlPath + EXPCONFIG_FIELD_CTRLARRAYVALUES + "/" + num2istr(arrayIndex)
		arrayElemType = JSON_GetType(jsonID, arrayElemPath)
		ASSERT(arrayElemType == JSON_NULL, "Control of ControlArray with the same ControlArrayIndex was already encountered. Check control: " + ctrlName)
		ControlInfo/W=$wName $ctrlName
		ctrlType = abs(V_Flag)
		if(IsNull(S_DataFolder))
			S_DataFolder = ""
		endif
		if(IsNull(S_Value))
			S_Value = ""
		endif
		if(ctrlType == CONTROL_TYPE_SETVARIABLE)
			setVarType = GetInternalSetVariableType(S_recreation)
			if(setVarType == SET_VARIABLE_BUILTIN_NUM)
				JSON_SetVariable(jsonID, arrayElemPath, V_Value)
			elseif(setVarType == SET_VARIABLE_BUILTIN_STR)
				JSON_SetString(jsonID, arrayElemPath, S_Value)
			else
				JSON_SetString(jsonID, arrayElemPath, S_DataFolder)
			endif
		elseif(ctrlType == CONTROL_TYPE_POPUPMENU)
			if(saveMask & EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY)
				JSON_SetVariable(jsonID, arrayElemPath, V_Value)
			else
				JSON_SetString(jsonID, arrayElemPath, S_Value)
			endif
		elseif(ctrlType == CONTROL_TYPE_BUTTON)
			if(saveMask & EXPCONFIG_SAVE_ONLY_RELEVANT)
				V_Value = 1
			endif
			if(saveMask & EXPCONFIG_SAVE_BUTTONS_ONLY_PRESSED)
				if(!CmpStr(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_BUTTONPRESS), "1"))
					JSON_SetVariable(jsonID, arrayElemPath, V_Value)
				endif
			else
				JSON_SetVariable(jsonID, arrayElemPath, V_Value)
			endif
		elseif(ctrlType == CONTROL_TYPE_CHART || ctrlType == CONTROL_TYPE_GROUPBOX)
			JSON_SetString(jsonID, arrayElemPath, S_Value)
		elseif(ctrlType == CONTROL_TYPE_CHECKBOX)
			JSON_SetBoolean(jsonID, arrayElemPath, V_Value)
		elseif(ctrlType == CONTROL_TYPE_CUSTOMCONTROL || ctrlType == CONTROL_TYPE_TAB || ctrlType == CONTROL_TYPE_SLIDER || ctrlType == CONTROL_TYPE_VALDISPLAY)
			JSON_SetVariable(jsonID, arrayElemPath, V_Value)
		elseif(ctrlType == CONTROL_TYPE_LISTBOX || ctrlType == CONTROL_TYPE_TITLEBOX)
			JSON_SetString(jsonID, arrayElemPath, S_DataFolder)
		endif
	endif

	WAVE/T ctrlProps = JSON_GetKeys(jsonID, controlPath)
	if(!DimSize(ctrlProps, ROWS))
		JSONXOP_Remove/Q=1 jsonID, controlPath; AbortOnRTE
	endif
End

/// @brief Retrieves current Headstage Association settings (amplifiers, pressure) )to json
/// @param[in] panelTitle panel title of DA_Ephys panel
/// @returns jsonID ID of json object with Headstage Association configuration data
static Function CONF_GetHeadstageAssociation(panelTitle)
	string panelTitle

	variable i, jsonID, ampSerial, ampChannelID, index
	string ctrl, amplifierDef, jsonPath, popupStr

	jsonID = JSON_New()

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		jsonPath = num2istr(i)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
		if(GetCheckBoxState(panelTitle, ctrl))

			JSON_AddTreeObject(jsonID, jsonPath)
			jsonPath = jsonPath + "/"
			PGC_SetAndActivateControl(panelTitle,"Popup_Settings_HeadStage", val = i)

			amplifierDef = GetPopupMenuString(panelTitle, "popup_Settings_Amplifier")
			DAP_ParseAmplifierDef(amplifierDef, ampSerial, ampChannelID)
			if(IsFinite(ampSerial) && IsFinite(ampChannelID))
				JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPSERIAL, ampSerial)
				JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPCHANNEL, ampChannelID)
			else
				JSON_AddNull(jsonID, jsonPath + EXPCONFIG_JSON_AMPSERIAL)
				JSON_AddNull(jsonID, jsonPath + EXPCONFIG_JSON_AMPCHANNEL)
			endif
			JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_AMPTITLE, StringFromList(trunc(i / 2), EXPCONFIG_SETTINGS_AMPTITLE))

			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPVCDA, str2num(GetPopupMenuString(panelTitle, "Popup_Settings_VC_DA")))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPVCAD, str2num(GetPopupMenuString(panelTitle, "Popup_Settings_VC_AD")))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPICDA, str2num(GetPopupMenuString(panelTitle, "Popup_Settings_IC_DA")))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPICAD, str2num(GetPopupMenuString(panelTitle, "Popup_Settings_IC_AD")))

			JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDEV, GetPopupMenuString(panelTitle, "popup_Settings_Pressure_dev"))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDA, str2num(GetPopupMenuString(panelTitle, "Popup_Settings_Pressure_DA")))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSAD, str2num(GetPopupMenuString(panelTitle, "Popup_Settings_Pressure_AD")))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDAGAIN, GetSetVariable(panelTitle, "setvar_Settings_Pressure_DAgain"))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSADGAIN, GetSetVariable(panelTitle, "setvar_Settings_Pressure_ADgain"))
			JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDAUNIT, GetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_DA_Unit"))
			JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_PRESSADUNIT, GetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_AD_Unit"))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSTTLA, str2numsafe(GetPopupMenuString(panelTitle, "Popup_Settings_Pressure_TTLA")))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSTTLB, str2numsafe(GetPopupMenuString(panelTitle, "Popup_Settings_Pressure_TTLB")))
			WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
			index = FindDimLabel(pressureDataWv, ROWS, "headStage_" + num2str(i))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSCONSTNEG, pressureDataWv[index][%NegCalConst])
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSCONSTPOS, pressureDataWv[index][%PosCalConst])

		else
			JSON_AddNull(jsonID, jsonPath)
		endif
	endfor

	return jsonID
End

/// @brief Opens MCCs and restores Headstage Association from configuration data to DA_Ephys panel
/// @param[in] panelTitle panel title of DA_Ephys panel
/// @param[in] jsonID ID of json object with configuration data
/// @param[in] midExp middle of experiment - uploads MCC relevant settings from panel to MCC instead
static Function CONF_RestoreHeadstageAssociation(panelTitle, jsonID, midExp)
	string panelTitle
	variable jsonID, midExp

	variable i, type, numRows, ampSerial, ampChannel, index, value
	string jsonPath, jsonHSPath, jsonBasePath
	string ampSerialList = ""
	string ampTitleList = ""

	CONF_RequireConfigBlockExists(jsonID)
	WAVE/T keys = JSON_GetKeys(jsonID, EXPCONFIG_RESERVED_DATABLOCK)
	FindValue/TXOP=4/TEXT=EXPCONFIG_JSON_HSASSOCBLOCK keys
	ASSERT(V_Value >= 0, "Headstage Association block not found in configuration.")
	jsonPath = EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_HSASSOCBLOCK + "/"
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		jsonHSPath = jsonPath + num2istr(i)
		type = JSON_GetType(jsonID, jsonHSPath)
		if(type == JSON_NULL)
			continue
		elseif(type == JSON_OBJECT)
			ampSerial = JSON_GetVariable(jsonID, jsonHSPath + "/" + EXPCONFIG_JSON_AMPSERIAL)

			if(IsNaN(ampSerial))
				continue
			endif

			ampSerialList = AddListItem(num2istr(ampSerial), ampSerialList)
			ampTitleList = AddListItem(JSON_GetString(jsonID, jsonHSPath + "/" + EXPCONFIG_JSON_AMPTITLE), ampTitleList)
		else
			ASSERT(0, "Unexpected entry for headstage data in Headstage Association block")
		endif
	endfor

	WAVE telegraphServers = GetAmplifierTelegraphServers()
	numRows = DimSize(telegraphServers, ROWS)
	if(!numRows)
		Assert(AI_OpenMCCs(ampSerialList, ampTitleList = ampTitleList), "Evil kittens prevented MultiClamp from opening - FULL STOP" )
	endif

	CONF_Position_MCC_Win(ampSerialList, ampTitleList, CONF_GetStringFromSettings(jsonID, POSITION_MCC))

	PGC_SetAndActivateControl(panelTitle, "button_Settings_UpdateAmpStatus")
	PGC_SetAndActivateControl(panelTitle, "button_Settings_UpdateDACList")

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		jsonHSPath = jsonPath + num2istr(i)
		PGC_SetAndActivateControl(panelTitle, "Popup_Settings_HeadStage", val = i)

		type = JSON_GetType(jsonID, jsonHSPath)
		jsonHSPath = jsonHSPath + "/"
		if(type == JSON_NULL)
			PGC_SetAndActivateControl(panelTitle, "popup_Settings_Amplifier", str = NONE)
			PGC_SetAndActivateControl(panelTitle, "popup_Settings_Pressure_dev", str = NONE)
		elseif(type == JSON_OBJECT)
			ampSerial = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_AMPSERIAL)
			ampChannel = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_AMPCHANNEL)
			if(IsFinite(ampSerial) && IsFinite(ampChannel))
				PGC_SetAndActivateControl(panelTitle, "popup_Settings_Amplifier", val = CONF_FindAmpInList(ampSerial, ampChannel))
			endif
			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_VC_DA", val = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_AMPVCDA))
			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_VC_AD", val = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_AMPVCAD))
			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_IC_DA", val = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_AMPICDA))
			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_IC_AD", val = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_AMPICAD))
			PGC_SetAndActivateControl(panelTitle,"button_Hardware_AutoGainAndUnit")

			PGC_SetAndActivateControl(panelTitle, "popup_Settings_Pressure_dev", str = JSON_GetString(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSDEV))
			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_Pressure_DA", val = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSDA))
			PGC_SetAndActivateControl(panelTitle, "Popup_Settings_Pressure_AD", val = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSAD))
			PGC_SetAndActivateControl(panelTitle, "setvar_Settings_Pressure_DAgain", val = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSDAGAIN))
			PGC_SetAndActivateControl(panelTitle, "setvar_Settings_Pressure_ADgain", val = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSADGAIN))
			PGC_SetAndActivateControl(panelTitle, "SetVar_Hardware_Pressur_DA_Unit", str = JSON_GetString(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSDAUNIT))
			PGC_SetAndActivateControl(panelTitle, "SetVar_Hardware_Pressur_AD_Unit", str = JSON_GetString(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSADUNIT))
			value = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSTTLA)
			if(IsNaN(value))
				PGC_SetAndActivateControl(panelTitle, "Popup_Settings_Pressure_TTLA", str = NONE)
			else
				PGC_SetAndActivateControl(panelTitle, "Popup_Settings_Pressure_TTLA", str = num2istr(value))
			endif
			value = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSTTLB)
			if(IsNaN(value))
				PGC_SetAndActivateControl(panelTitle, "Popup_Settings_Pressure_TTLB", str = NONE)
			else
				PGC_SetAndActivateControl(panelTitle, "Popup_Settings_Pressure_TTLB", str = num2istr(value))
			endif
			WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
			index = FindDimLabel(pressureDataWv, ROWS, "headStage_" + num2str(i))
			pressureDataWv[index][%NegCalConst] = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSCONSTNEG)
			pressureDataWv[index][%PosCalConst] = JSON_GetVariable(jsonID, jsonHSPath + EXPCONFIG_JSON_PRESSCONSTPOS)

			if(IsFinite(ampSerial))
				if(!midExp)
					CONF_MCC_InitParams(panelTitle, i)
				else
					CONF_MCC_MidExp(panelTitle, i, jsonID)
				endif
			endif
		endif
	endfor
	PGC_SetAndActivateControl(panelTitle, "button_Hardware_P_Enable")

End

/// @brief Retrieves current User Pressure settings to json
/// @param[in] panelTitle panel title of DA_Ephys panel
/// @returns jsonID ID of json object with user pressure configuration data
static Function CONF_GetUserPressure(panelTitle)
	string panelTitle

	variable jsonID

	jsonID = JSON_New()

	JSON_AddString(jsonID, EXPCONFIG_JSON_USERPRESSDEV, GetPopupMenuString(panelTitle, "popup_Settings_UserPressure"))
	JSON_AddVariable(jsonID, EXPCONFIG_JSON_USERPRESSDA, str2num(GetPopupMenuString(panelTitle, "Popup_Settings_UserPressure_ADC")))

	return jsonID
End

/// @brief Restore User Pressure settings
/// @param[in] panelTitle panel title of DA_Ephys panel
/// @param[in] jsonID ID of json object with configuration data
static Function CONF_RestoreUserPressure(panelTitle, jsonID)
	string panelTitle
	variable jsonID

	string jsonPath

	CONF_RequireConfigBlockExists(jsonID)
	WAVE/T keys = JSON_GetKeys(jsonID, EXPCONFIG_RESERVED_DATABLOCK)
	FindValue/TXOP=4/TEXT=EXPCONFIG_JSON_USERPRESSBLOCK keys
	ASSERT(V_Value >= 0, "User Pressure block not found in configuration.")
	jsonPath = EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_USERPRESSBLOCK + "/"
	PGC_SetAndActivateControl(panelTitle, "popup_Settings_UserPressure", str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_JSON_USERPRESSDEV))
	PGC_SetAndActivateControl(panelTitle, "Popup_Settings_UserPressure_ADC", val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_USERPRESSDA))
	PGC_SetAndActivateControl(panelTitle, "button_Hardware_PUser_Enable")
End


#ifdef AMPLIFIER_XOPS_PRESENT

/// @brief Intiate MCC parameters for active headstages
///
/// @param panelTitle ITC device panel
/// @param headStage  MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
static Function CONF_MCC_InitParams(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable clampMode

	WAVE GuiState = GetDA_EphysGuiStateNum(panelTitle)
	clampMode = GuiState[headStage][%HSmode]

	// Set initial parameters within MCC itself.
	AI_SelectMultiClamp(panelTitle, headStage)

	//Set V-clamp parameters
	DAP_ChangeHeadStageMode(panelTitle, V_CLAMP_MODE, headStage, DO_MCC_MIES_SYNCING)

	MCC_SetHoldingEnable(0)
	MCC_SetOscKillerEnable(0)
	MCC_SetFastCompTau(1.8e-6)
	MCC_SetSlowCompTau(1e-5)
	MCC_SetSlowCompTauX20Enable(0)
	MCC_SetRsCompBandwidth(1.02e3)
	MCC_SetRSCompCorrection(0)
	MCC_SetPrimarySignalGain(1)
	MCC_SetPrimarySignalLPF(10e3)
	MCC_SetPrimarySignalHPF(0)
	MCC_SetSecondarySignalGain(1)
	MCC_SetSecondarySignalLPF(10e3)

	//Set I-Clamp Parameters
	DAP_ChangeHeadStageMode(panelTitle, I_CLAMP_MODE, headStage, DO_MCC_MIES_SYNCING)

	MCC_SetHoldingEnable(0)
	MCC_SetSlowCurrentInjEnable(0)
	MCC_SetNeutralizationEnable(0)
	MCC_SetOscKillerEnable(0)
	MCC_SetPrimarySignalGain(5)
	MCC_SetPrimarySignalLPF(10e3)
	MCC_SetPrimarySignalHPF(0)
	MCC_SetSecondarySignalGain(1)
	MCC_SetSecondarySignalLPF(10e3)

	if(clampMode != I_CLAMP_MODE)
		DAP_ChangeHeadStageMode(panelTitle, clampMode, headStage, DO_MCC_MIES_SYNCING)
	endif
End

#else

static Function CONF_MCC_InitParams(panelTitle, headStage)
	string panelTitle
	variable headStage

	DEBUGPRINT("Unimplemented")

	return NaN
End

#endif

/// @brief Find the list index of a connected amplifier serial number
///
/// @param ampSerialRef    Amplifier Serial Number to search for
/// @param ampChannelIDRef Headstage reference number
static Function CONF_FindAmpInList(ampSerialRef, ampChannelIDRef)
	variable ampSerialRef, ampChannelIDRef

	string listOfAmps, ampDef
	variable numAmps, i, ampSerial, ampChannelID

	listOfAmps = DAP_GetNiceAmplifierChannelList()
	numAmps = ItemsInList(listOfAmps)

	for(i = 0; i < numAmps; i += 1)
		ampDef = StringFromList(i, listOfAmps)
		DAP_ParseAmplifierDef(ampDef, ampSerial, ampChannelID)
		if(ampSerial == ampSerialRef && ampChannelID == ampChannelIDRef)
			return i
		endif
	endfor

	ASSERT(0, "Could not find amplifier")
End

static Function CONF_MCC_MidExp(panelTitle, headStage, jsonID)
	string panelTitle
	variable headStage, jsonID

	variable settingValue, clampMode

	PGC_SetAndActivateControl(panelTitle,"slider_DataAcq_ActiveHeadstage", val = headStage)

	clampMode = AI_GetMode(panelTitle, headstage)

	if(clampMode == V_CLAMP_MODE)

		settingValue = AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_GETPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_PipetteOffset_VC", val = settingValue)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_PipetteOffset_IC", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_Hold_VC", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "check_DatAcq_HoldEnableVC", val = settingValue)
		PGC_SetAndActivateControl(panelTitle,"check_DataAcq_AutoBias", val = CHECKBOX_SELECTED)
		printf "HeadStage %d is in V-Clamp mode and has been configured from the MCC. I-Clamp settings were reset to initial values, check before switching!\r", headStage
	elseif(clampMode == I_CLAMP_MODE)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_PipetteOffset_VC", val = settingValue)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_PipetteOffset_IC", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_Hold_IC", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "check_DatAcq_HoldEnable", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETBRIDGEBALRESIST_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_BB", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETBRIDGEBALENABLE_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "check_DatAcq_BBEnable", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETNEUTRALIZATIONCAP_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_CN", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETNEUTRALIZATIONENABL_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "check_DatAcq_CNEnable", val = settingValue)
		PGC_SetAndActivateControl(panelTitle,"check_DataAcq_AutoBias", val = CHECKBOX_UNSELECTED)
		PGC_SetAndActivateControl(panelTitle,"check_DatAcq_HoldEnableVC", val = CHECKBOX_UNSELECTED)
		printf "HeadStage %d is in I-Clamp mode and has been configured from the MCC. V-Clamp settings were reset to initial values, check before switching!\r", headStage
	elseif(clampMode == I_EQUAL_ZERO_MODE)
		// do nothing
	endif
End

/// @brief Position MCC windows to upper right monitor using nircmd.exe
///
/// @param serialNum   Serial number of MCC
/// @param winTitle    Name of MCC window
/// @param winPosition One of 4 monitors to position MCCs in
Function CONF_Position_MCC_Win(serialNum, winTitle, winPosition)
	string serialNum, winTitle, winPosition

	string cmd, fullPath, cmdPath
	variable w

	if(cmpstr(winPosition, NONE) == 0)
		return 0
	endif

	cmdPath = GetWindowsPath(GetFolder(FunctionPath("")) + "..:..:tools:nircmd:nircmd.exe")
	if(!FileExists(cmdPath))
		printf "nircmd.exe is not installed, please download it here: %s", "http://www.nirsoft.net/utils/nircmd.html"
		return NaN
	endif

	Make/T/FREE/N=(NUM_HEADSTAGES/2) winNm
	for(w = 0; w<NUM_HEADSTAGES/2; w+=1)

		winNm[w] = {stringfromlist(w,winTitle) + "(" + stringfromlist(w,serialNum) + ")"}
		sprintf cmd, "\"%s\" nircmd.exe win center title \"%s\"", cmdPath, winNm[w]
		ExecuteScriptText cmd
	endfor

	if(cmpstr(winPosition, "Upper Right") == 0)
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2300 -1250 0 0", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2675 -1250 0 0", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2300 -900 0 0", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\"nircmd.exe win move title \"%s\" 2675 -900 0 0", cmdPath, winNm[3]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[3]
		ExecuteScriptText cmd
	elseif(cmpstr(winPosition, "Lower Right") == 0)
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2300 -200 0 0", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2675 -200 0 0", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2300 100 0 0", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\"nircmd.exe win move title \"%s\" 2675 100 0 0", cmdPath, winNm[3]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[3]
		ExecuteScriptText cmd
	elseif(cmpstr(winPosition, "Lower Left") == 0)
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 300 -200 0 0", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 700 -200 0 0", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 300 100 0 0", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\"nircmd.exe win move title \"%s\" 700 100 0 0", cmdPath, winNm[3]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[3]
		ExecuteScriptText cmd
	elseif(cmpstr(winPosition, "Upper Left") == 0)
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 300 -1250 0 0", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 700 -1250 0 0", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 300 -900 0 0", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\"nircmd.exe win move title \"%s\" 700 -900 0 0", cmdPath, winNm[3]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[3]
		ExecuteScriptText cmd
	else
		printf "Message: If you would like to position the MCC windows please select a monitor in the Configuration text file"
	endif
End

/// @brief Loads, parses and joins a *_rig.json file to a main configuration file.
/// @param[in] jsonID jsonID of main configuration
/// @param[in] rigFileName full file path of rig file
static Function CONF_JoinRigFile(jsonID, rigFileName)
	variable jsonID
	string rigFileName

	string input
	variable jsonIDRig

	[input, rigFileName] = LoadTextFile(rigFileName)
	if(IsEmpty(input))
		return 0
	endif
	jsonIDRig = CONF_ParseJSON(input)
	SyncJSON(jsonIDRig, jsonID, "", "", rigFileName)
	JSON_Release(jsonIDRig)
End
