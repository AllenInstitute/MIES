#pragma TextEncoding="UTF-8"
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
/// are the windows and subwindows and within are the control blocks. For notebook windows the content of the notebook is saved
/// as plain text and restored as plain text.
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
///
/// *_rig.json configuration files store settings that are specific to a rig.
/// When restoring a DAEphys panel the settings from the rig file are joined with the settings in the DAEphys configuration file.
/// Having entries for the same setting in both files is invalid and an assertion will be thrown.
///
/// Saving a DAEphys panel that was originally restored from a configuration file:
/// - entries from the "Common configuration data" block are updated with the values from the previous configuration,
///   if they already existed. New entries are set at default values.
/// - entries defined in an associated rig file are removed from the DAEphys panel configuration because they would appear in
///   both files
/// - the previously used rig file is copied to the new location
/// - By default for both files (DAEphys configuration and rig file) new file names are generated. If the new files already
///   exist a save dialog is opened to allow the user to modify the path/name.
///******************************************************************************************************************************

static StrConstant EXPCONFIG_FIELD_CTRLTYPE        = "Type"
static StrConstant EXPCONFIG_FIELD_CTRLVVALUE      = "NumValue"
static StrConstant EXPCONFIG_FIELD_CTRLSVALUE      = "StrValue"
static StrConstant EXPCONFIG_FIELD_CTRLSDF         = "DataSource"
static StrConstant EXPCONFIG_FIELD_CTRLDISABLED    = "Disabled"
static StrConstant EXPCONFIG_FIELD_CTRLPOSHEIGHT   = "Height"
static StrConstant EXPCONFIG_FIELD_CTRLPOSWIDTH    = "Width"
static StrConstant EXPCONFIG_FIELD_CTRLPOSTOP      = "Top"
static StrConstant EXPCONFIG_FIELD_CTRLPOSLEFT     = "Left"
static StrConstant EXPCONFIG_FIELD_CTRLPOSRIGHT    = "Right"
static StrConstant EXPCONFIG_FIELD_CTRLPOSPOS      = "Pos"
static StrConstant EXPCONFIG_FIELD_CTRLPOSALIGN    = "Align"
static StrConstant EXPCONFIG_FIELD_CTRLUSERDATA    = "Userdata"
static StrConstant EXPCONFIG_FIELD_BASE64PREFIX    = "Base64 "
static StrConstant EXPCONFIG_FIELD_CTRLARRAYVALUES = "Values"
static StrConstant EXPCONFIG_FIELD_NOTEBOOKTEXT    = "NotebookText"

static StrConstant EXPCONFIG_UDATA_NICENAME    = "Config_NiceName"
static StrConstant EXPCONFIG_UDATA_JSONPATH    = "Config_GroupPath"
static StrConstant EXPCONFIG_UDATA_BUTTONPRESS = "Config_PushButtonOnRestore"
// Lower means higher priority
static StrConstant EXPCONFIG_UDATA_RESTORE_PRIORITY = "Config_RestorePriority"
static StrConstant EXPCONFIG_UDATA_WINHANDLE        = "Config_WindowHandle"
static StrConstant EXPCONFIG_UDATA_RADIOCOUPLING    = "Config_RadioCouplingFunc"
static StrConstant EXPCONFIG_UDATA_CTRLARRAY        = "ControlArray"
static StrConstant EXPCONFIG_UDATA_CTRLARRAYINDEX   = "ControlArrayIndex"

static Constant    EXPCONFIG_UDATA_MAXCTRLARRAYINDEX = 100
static Constant    EXPCONFIG_JSON_INDENT             = 4
static StrConstant EXPCONFIG_FILEFILTER              = "Configuration Files (*.json):.json;All Files:.*;"
static StrConstant EXPCONFIG_CTRLGROUP_SUFFIX        = " ControlGroup"
static StrConstant EXPCONFIG_SETTINGS_FOLDER         = "Settings"

// DA_Ephys specific constants
static StrConstant DAEPHYS_UDATA_WINHANDLE = "DAEphys_WindowHandle"
// Headstage checkboxes ctrl niceName prefix
static StrConstant DAEPHYS_HEADSTAGECTRLARRAYPREFIX = "Check_DataAcqHS"
static StrConstant DAEPHYS_EXCLUDE_CTRLTYPES        = "12;9;10;4;"

static StrConstant EXPCONFIG_DEFAULT_CTRL_JSONPATH = "Generic"
static StrConstant EXPCONFIG_RESERVED_DATABLOCK    = "Common configuration data"
static StrConstant EXPCONFIG_RESERVED_TAGENTRY     = "Target Window Type"

static StrConstant EXPCONFIG_EXCLUDE_USERDATA  = "ResizeControlsInfo;"
static StrConstant EXPCONFIG_EXCLUDE_CTRLTYPES = "12;9;10;"

static StrConstant EXPCONFIG_SETTINGS_AMPTITLE = "0,1;2,3;4,5;6,7"

static StrConstant EXPCONFIG_JSON_GLOBALPACKAGESETTINGBLOCK = "Global Package Settings"

static StrConstant EXPCONFIG_JSON_HSASSOCBLOCK  = "Headstage Association"
static StrConstant EXPCONFIG_JSON_AMPBLOCK      = "Amplifier"
static StrConstant EXPCONFIG_JSON_ICBLOCK       = "IC"
static StrConstant EXPCONFIG_JSON_VCBLOCK       = "VC"
static StrConstant EXPCONFIG_JSON_PRESSUREBLOCK = "Pressure"
static StrConstant EXPCONFIG_JSON_AMPSERIAL     = "Serial"
static StrConstant EXPCONFIG_JSON_AMPTITLE      = "Title"
static StrConstant EXPCONFIG_JSON_AMPCHANNEL    = "Channel"
static StrConstant EXPCONFIG_JSON_AMPVCDA       = "DA"
static StrConstant EXPCONFIG_JSON_AMPVCDAGAIN   = "DA gain"
static StrConstant EXPCONFIG_JSON_AMPVCDAUNIT   = "DA unit"
static StrConstant EXPCONFIG_JSON_AMPVCAD       = "AD"
static StrConstant EXPCONFIG_JSON_AMPVCADGAIN   = "AD gain"
static StrConstant EXPCONFIG_JSON_AMPVCADUNIT   = "AD unit"
static StrConstant EXPCONFIG_JSON_AMPICDA       = "DA"
static StrConstant EXPCONFIG_JSON_AMPICDAGAIN   = "DA gain"
static StrConstant EXPCONFIG_JSON_AMPICDAUNIT   = "DA unit"
static StrConstant EXPCONFIG_JSON_AMPICAD       = "AD"
static StrConstant EXPCONFIG_JSON_AMPICADGAIN   = "AD gain"
static StrConstant EXPCONFIG_JSON_AMPICADUNIT   = "AD unit"
static StrConstant EXPCONFIG_JSON_PRESSDEV      = "Device"
static StrConstant EXPCONFIG_JSON_PRESSDA       = "DA"
static StrConstant EXPCONFIG_JSON_PRESSAD       = "AD"
static StrConstant EXPCONFIG_JSON_PRESSDAGAIN   = "DA Gain"
static StrConstant EXPCONFIG_JSON_PRESSADGAIN   = "AD Gain"
static StrConstant EXPCONFIG_JSON_PRESSDAUNIT   = "DA Unit"
static StrConstant EXPCONFIG_JSON_PRESSADUNIT   = "AD Unit"
static StrConstant EXPCONFIG_JSON_PRESSTTLA     = "TTLA"
static StrConstant EXPCONFIG_JSON_PRESSTTLB     = "TTLB"
static StrConstant EXPCONFIG_JSON_PRESSCONSTNEG = "Constant Negative"
static StrConstant EXPCONFIG_JSON_PRESSCONSTPOS = "Constant Positive"

static StrConstant EXPCONFIG_JSON_SAVE_PATH              = "Save data to"
static StrConstant EXPCONFIG_JSON_STIMSET_NAME           = "Stim set file name"
static StrConstant EXPCONFIG_JSON_POSITION_MCC           = "Position MCCs"
static StrConstant EXPCONFIG_JSON_LOGFILE_UPLOAD         = "Automatic logfile upload"
static Constant    EXPCONFIG_JSON_LOGFILE_UPLOAD_DEFAULT = 0

static StrConstant EXPCONFIG_JSON_USERPRESSBLOCK = "User Pressure Devices"
static StrConstant EXPCONFIG_JSON_USERPRESSDEV   = "DAC Device"
static StrConstant EXPCONFIG_JSON_USERPRESSDA    = "DA"

static StrConstant EXPCONFIG_JSON_AMP_HOLD_VC        = "Holding"
static StrConstant EXPCONFIG_JSON_AMP_HOLD_ENABLE_VC = "Holding Enable"

static StrConstant EXPCONFIG_JSON_AMP_LPF  = "LPF primary output"
static StrConstant EXPCONFIG_JSON_AMP_GAIN = "Gain primary output"

static StrConstant EXPCONFIG_JSON_AMP_PIPETTE_OFFSET_VC = "Pipette Offset"

static StrConstant EXPCONFIG_JSON_AMP_WHOLE_CELL_CAPACITANCE = "Whole Cell Capacitance"
static StrConstant EXPCONFIG_JSON_AMP_WHOLE_CELL_RESISTANCE  = "Whole Cell Resistance"
static StrConstant EXPCONFIG_JSON_AMP_WHOLE_CELL_ENABLE      = "Whole Cell Enable"

static StrConstant EXPCONFIG_JSON_AMP_RS_COMP_CORRECTION = "RS Compensation Correction"
static StrConstant EXPCONFIG_JSON_AMP_RS_COMP_PREDICTION = "RS Compensation Prediction"
static StrConstant EXPCONFIG_JSON_AMP_RS_COMP_ENABLE     = "RS Compensation Enable"
static StrConstant EXPCONFIG_JSON_AMP_COMP_CHAIN         = "RS Compensation Chain"

static StrConstant EXPCONFIG_JSON_AMP_HOLD_IC        = "Holding"
static StrConstant EXPCONFIG_JSON_AMP_HOLD_ENABLE_IC = "Holding Enable"

static StrConstant EXPCONFIG_JSON_AMP_BRIDGE_BALANCE        = "Bridge Balance"
static StrConstant EXPCONFIG_JSON_AMP_BRIDGE_BALANCE_ENABLE = "Bridge Balance Enable"

static StrConstant EXPCONFIG_JSON_AMP_CAP_NEUTRALIZATION        = "Capacitance Neutralization"
static StrConstant EXPCONFIG_JSON_AMP_CAP_NEUTRALIZATION_ENABLE = "Capacitance Neutralization Enable"

static StrConstant EXPCONFIG_JSON_AMP_AUTOBIAS_V          = "Autobias Voltage"
static StrConstant EXPCONFIG_JSON_AMP_AUTOBIAS_V_RANGE    = "Autobias Voltage Range"
static StrConstant EXPCONFIG_JSON_AMP_AUTOBIAS_I_BIAS_MAX = "Autobias Current Max"
static StrConstant EXPCONFIG_JSON_AMP_AUTOBIAS            = "Autobias Enable"

static StrConstant EXPCONFIG_JSON_AMP_PIPETTE_OFFSET_IC = "Pipette Offset"

static StrConstant EXPCONFIG_RIGFILESUFFIX = "_rig.json"

static Constant EXPCONFIG_MIDDLEEXP_OFF = 0
static Constant EXPCONFIG_MIDDLEEXP_ON  = 1

/// @brief Parameters for CONF_GetSettingsPath()
/// @{
static Constant CONF_AUTO_LOADER_GLOBAL = 0x0
static Constant CONF_AUTO_LOADER_USER   = 0x1
/// @}

static StrConstant CONF_AUTO_LOADER_USER_PATH = "C:ProgramData:AllenInstitute:MIES:Settings"

/// @brief Creates a json with default experiment configuration block
///
/// @returns json with default experiment configuration
static Function CONF_DefaultSettings()

	variable jsonID
	string   jsonPath

	jsonID = JSON_New()

	JSON_AddString(jsonID, EXPCONFIG_JSON_POSITION_MCC, NONE)
	JSON_AddString(jsonID, EXPCONFIG_JSON_STIMSET_NAME, "")
	JSON_AddString(jsonID, EXPCONFIG_JSON_SAVE_PATH, "C:MiesSave")
	JSON_AddBoolean(jsonID, EXPCONFIG_JSON_LOGFILE_UPLOAD, EXPCONFIG_JSON_LOGFILE_UPLOAD_DEFAULT)

	jsonpath = "/" + EXPCONFIG_JSON_GLOBALPACKAGESETTINGBLOCK + "/" + PACKAGE_SETTINGS_USERPING
	JSON_AddTreeObject(jsonID, jsonPath)
	JSON_AddBoolean(jsonID, jsonPath + "/enabled", PACKAGE_SETTINGS_USERPING_DEFAULT)

	return jsonID
End

/// @brief Open all configuration files in plain text notebooks
///
/// Existing notebooks with the files are brought to the front.
Function CONF_OpenConfigInNotebook()
	variable i, numFiles
	string path, name

	WAVE/T/Z rawFileList = CONF_GetConfigFiles()

	if(!WaveExists(rawFileList))
		printf "There are no files to load from the %s folder.\r", EXPCONFIG_SETTINGS_FOLDER
		ControlWindowToFront()
		return NaN
	endif

	numFiles = DimSize(rawFileList, ROWS)
	for(i = 0; i < numFiles; i += 1)
		path = rawFileList[i]
		name = CleanupName(GetFile(path), 0)

		if(WindowExists(name))
			DoWindow/F $name
		else
			OpenNotebook/ENCG=1/N=$name path
		endif
	endfor
End

/// @brief Return a text wave with absolute paths to the JSON configuration files
static Function/WAVE CONF_GetConfigFiles([string customIPath])

	string settingsPath, fileList

	if(ParamIsDefault(customIPath))
		settingsPath = CONF_GetSettingsPath(CONF_AUTO_LOADER_GLOBAL)
	else
		settingsPath = customIPath
	endif
	fileList = GetAllFilesRecursivelyFromPath(settingsPath, extension = ".json")

	if(IsEmpty(fileList) && !ParamIsDefault(customIPath))
		settingsPath = CONF_GetSettingsPath(CONF_AUTO_LOADER_USER)
		fileList     = GetAllFilesRecursivelyFromPath(settingsPath, extension = ".json")
	endif

	if(IsEmpty(fileList))
		return $""
	endif

	return ListToTextWave(fileList, FILE_LIST_SEP)
End

/// @brief Automatically loads all *.json files from MIES Settings folder and opens and restores the corresponding windows
///        Files are restored in case-insensitive alphanumeric order. Associated *_rig.json files are taken into account.
Function CONF_AutoLoader([string customIPath])

	variable i, numFiles
	string rigCandidate

	if(ParamIsDefault(customIPath))
		WAVE/T/Z rawFileList = CONF_GetConfigFiles()
	else
		WAVE/T/Z rawFileList = CONF_GetConfigFiles(customIPath = customIPath)
	endif
	if(!WaveExists(rawFileList))
		printf "There are no files to load from the %s folder.\r", EXPCONFIG_SETTINGS_FOLDER
		ControlWindowToFront()
		Abort
	endif

	[WAVE/T rigFileList, WAVE/T mainFileList] = SplitTextWaveBySuffix(rawFileList, EXPCONFIG_RIGFILESUFFIX)

	Sort mainFileList, mainFileList
	numFiles = DimSize(mainFileList, ROWS)
	for(i = 0; i < numFiles; i += 1)
		rigCandidate = mainFileList[i]
		rigCandidate = rigCandidate[0, strlen(rigCandidate) - 6] + EXPCONFIG_RIGFILESUFFIX
		FindValue/TXOP=4/TEXT=rigCandidate rigFileList
		if(V_Value == -1)
			rigCandidate = ""
		endif
		CONF_RestoreWindow(mainFileList[i], rigFile = rigCandidate)
	endfor
End

/// @brief Returns a symbolic path to the settings folder
///
/// @param type One of #CONF_AUTO_LOADER_GLOBAL or CONF_AUTO_LOADER_USER
/// @returns name of an igor symbolic path to the settings folder
static Function/S CONF_GetSettingsPath(type)
	variable type

	variable numItems
	string symbPath, path

	switch(type)
		case CONF_AUTO_LOADER_GLOBAL:
			path = FunctionPath("CONF_GetSettingsPath")

			numItems = ItemsInList(path, ":")
			ASSERT(numItems >= 2, "Invalid path")

			path = RemoveListItem(numItems - 1, path, ":")
			path = RemoveListItem(numItems - 2, path, ":") + EXPCONFIG_SETTINGS_FOLDER + ":"
			ASSERT(FolderExists(path), "Unable to resolve MIES Settings folder path. Is it present and readable in Packages\\Settings ?")
			break
		case CONF_AUTO_LOADER_USER:
			path = CONF_AUTO_LOADER_USER_PATH
			if(!FolderExists(path))
				CreateFolderOnDisk(path)
			endif
			break
		default:
			ASSERT(0, "Invalid type parameter")
			break
	endswitch

	if(FolderExists(path))
		symbPath = "PathSettings"
		NewPath/O/Q $symbPath, path

		return symbPath
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

	AssertOnAndClearRTError()
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
			jsonID   = CONF_AllWindowsToJSON(wName, saveMask, excCtrlTypes = EXPCONFIG_EXCLUDE_CTRLTYPES)
			out      = JSON_Dump(jsonID, indent = EXPCONFIG_JSON_INDENT)
			JSON_Release(jsonID)

			PathInfo/S $CONF_GetSettingsPath(CONF_AUTO_LOADER_GLOBAL)

			saveResult = SaveTextFile(out, fName, fileFilter = EXPCONFIG_FILEFILTER, message = "Save configuration file for window")
			if(!IsNaN(saveResult))
				print "Configuration saved."
			else
				print "Save FAILED!"
			endif
		endif
	catch
		errMsg = getRTErrMessage()
		if(ClearRTError())
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry
End

/// @brief Restores the GUI state of window and all of its subwindows from a configuration file. If the configuration file contains a panel type string then
///        a new window of that type is opened and restored.
///
/// @param fName file name of configuration file to read configuration
/// @param rigFile [optional, default = ""] name of secondary rig configuration file with complementary data. This parameter is valid when loading for a DA_Ephys panel
Function CONF_RestoreWindow(string fName, [string rigFile])

	variable jsonID, restoreMask
	string input, wName, errMsg, fullFilePath, panelType

	rigFile = SelectString(ParamIsDefault(rigFile), rigFile, "")

	PathInfo/S $CONF_GetSettingsPath(CONF_AUTO_LOADER_GLOBAL)

	jsonID      = NaN
	restoreMask = EXPCONFIG_SAVE_VALUE | EXPCONFIG_SAVE_USERDATA | EXPCONFIG_SAVE_DISABLED
	AssertOnAndClearRTError()
	try
		[input, fullFilePath] = LoadTextFile(fName, fileFilter = EXPCONFIG_FILEFILTER, message = "Open configuration file")
		if(IsEmpty(input))
			return 0
		endif
		jsonID    = CONF_ParseJSON(input)
		panelType = JSON_GetString(jsonID, "/" + EXPCONFIG_RESERVED_TAGENTRY)
		if(IsEmpty(panelType))
			wName = GetMainWindow(GetCurrentWindow())
			if(PanelIsType(wName, PANELTAG_DAEPHYS))
				if(!IsEmpty(rigFile))
					CONF_JoinRigFile(jsonID, rigFile)
				endif
				wName = CONF_RestoreDAEphys(jsonID, fullFilePath)
			else
				wName = CONF_JSONToWindow(wName, restoreMask, jsonID)
				print "Configuration restored for " + wName
			endif
		else
			if(!CmpStr(panelType, PANELTAG_DAEPHYS))
				if(!IsEmpty(rigFile))
					CONF_JoinRigFile(jsonID, rigFile)
				endif
				wName = CONF_RestoreDAEphys(jsonID, fullFilePath, forceNewPanel = 1)
			elseif(!CmpStr(panelType, PANELTAG_DATABROWSER))
				DB_OpenDataBrowser()
				wName = GetMainWindow(GetCurrentWindow())
				wName = CONF_JSONToWindow(wName, restoreMask, jsonID)
				print "Data Browser restored in window \"" + wName + "\""
			elseif(!CmpStr(panelType, PANELTAG_WAVEBUILDER))
				WBP_CreateWaveBuilderPanel()
				wName = GetMainWindow(GetCurrentWindow())
				wName = CONF_JSONToWindow(wName, restoreMask, jsonID)
			elseif(!CmpStr(panelType, PANELTAG_ANALYSISBROWSER))
				AB_OpenAnalysisBrowser()
				wName = GetMainWindow(GetCurrentWindow())
				wName = CONF_JSONToWindow(wName, restoreMask, jsonID)
			elseif(!CmpStr(panelType, PANELTAG_IVSCCP))
				IVS_CreatePanel()
				wName = GetMainWindow(GetCurrentWindow())
				wName = CONF_JSONToWindow(wName, restoreMask, jsonID)
			else
				ASSERT(0, "Configuration file entry for panel type has an unknown type (" + panelType + ").")
			endif
		endif

		CONF_AddConfigFileUserData(wName, fullFilePath, rigFile)
	catch
		errMsg = getRTErrMessage()
		if(JSON_IsValid(jsonID))
			JSON_Release(jsonID)
		endif
		if(ClearRTError())
			ASSERT(0, errMsg)
		else
			printf "Configuration restore aborted at file %s.\r", fullFilePath
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

	variable i, jsonID, saveMask, saveResult, prevJsonId, prevRigJsonId
	string out, wName, errMsg, newFileName, newRigFullFilePath, jsonTxt

	wName = GetMainWindow(GetCurrentWindow())
	ASSERT(PanelIsType(wName, PANELTAG_DAEPHYS), "Current window is no DA_Ephys panel")
	[prevJsonId, jsonTxt] = CONF_LoadConfigUsedForDAEphysPanel(wName)
	[prevRigJsonId, jsonTxt] = CONF_LoadConfigUsedForDAEphysPanel(wName, loadRigFile = 1)

	AssertOnAndClearRTError()
	try

		saveMask = EXPCONFIG_SAVE_VALUE | EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY | EXPCONFIG_SAVE_BUTTONS_ONLY_PRESSED | EXPCONFIG_SAVE_ONLY_RELEVANT
		jsonID   = CONF_AllWindowsToJSON(wName, saveMask, excCtrlTypes = DAEPHYS_EXCLUDE_CTRLTYPES)

		JSON_SetJSON(jsonID, EXPCONFIG_RESERVED_DATABLOCK, CONF_DefaultSettings())
		if(JSON_IsValid(prevJsonId))
			CONF_TransferPreviousDAEphysJson(jsonId, prevJsonId)
			JSON_Release(prevJsonId)
		endif
		JSON_SetJSON(jsonID, EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_HSASSOCBLOCK, CONF_GetAmplifierSettings(wName))
		JSON_SetJSON(jsonID, EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_USERPRESSBLOCK, CONF_GetUserPressure(wName))
		if(JSON_IsValid(prevRigJsonId))
			CONF_RemoveRigElementsFromDAEphysJson(jsonId, prevRigJsonId)
		endif

		out = JSON_Dump(jsonID, indent = EXPCONFIG_JSON_INDENT)
		JSON_Release(jsonID)

		PathInfo/S $CONF_GetSettingsPath(CONF_AUTO_LOADER_GLOBAL)

		newFileName = CONF_GetDAEphysConfigurationFileNameSuggestion(wName)
		fName       = SelectString(IsEmpty(newFileName), newFileName, fName)

		saveResult = SaveTextFile(out, fName, fileFilter = EXPCONFIG_FILEFILTER, message = "Save configuration for DA_Ephys panel", savedFileName = newFileName, showDialogOnOverwrite = 1)
		if(JSON_IsValid(saveResult))
			printf "Configuration saved in %s.\r", newFileName
		endif
		if(JSON_IsValid(prevRigJsonId) && !IsEmpty(newFileName))
			JSON_Release(prevRigJsonId)
			newRigFullFilePath = GetFolder(newFileName) + GetBaseName(newFileName) + EXPCONFIG_RIGFILESUFFIX
			saveResult         = SaveTextFile(jsonTxt, newRigFullFilePath, fileFilter = EXPCONFIG_FILEFILTER, message = "Save Rig configuration for DA_Ephys panel", savedFileName = newFileName, showDialogOnOverwrite = 1)
			if(!IsNaN(saveResult))
				printf "Rig configuration saved in %s.\r", newFileName
			endif
		endif

	catch
		errMsg = getRTErrMessage()
		if(ClearRTError())
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry
End

Function CONF_PrimeDeviceLists(string device)

	variable hardwareType

	SVAR globalITCDeviceList = $GetITCDeviceList()
	SVAR globalNIDeviceList  = $GetNIDeviceList()
	SVAR globalSUDeviceList  = $GetSUDeviceList()

	hardwareType = GetHardwareType(device)
	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			if(IsEmpty(globalITCDeviceList))
				globalITCDeviceList = device + ";"
				globalNIDeviceList  = NONE
				globalSUDeviceList  = NONE
			endif
			break
		case HARDWARE_NI_DAC:
			if(IsEmpty(globalNIDeviceList))
				globalITCDeviceList = NONE
				globalNIDeviceList  = device + ";"
				globalSUDeviceList  = NONE
			endif
			break
		case HARDWARE_SUTTER_DAC:
			if(IsEmpty(globalSUDeviceList))
				globalITCDeviceList = NONE
				globalNIDeviceList  = NONE
				globalSUDeviceList  = device + ";"
			endif
			break
		default:
			ASSERT(0, "Unknown hardwareType")
	endswitch
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
	string   fullFilePath
	variable middleOfExperiment, forceNewPanel

	variable i, fnum, restoreMask, numPotentialUnlocked, err, winConfigChanged, isTagged, uploadLogfiles
	string device, getWName, jsonPath, potentialUnlockedList, winHandle, errMsg
	string AmpSerialLocal, AmpTitleLocal, deviceToRecreate, StimSetPath, path, filename, rStateSync
	string input = ""

	AssertOnAndClearRTError()
	try
		middleOfExperiment = ParamIsDefault(middleOfExperiment) ? 0 : !!middleOfExperiment
		forceNewPanel      = ParamIsDefault(forceNewPanel) ? 0 : !!forceNewPanel

		deviceToRecreate = CONF_GetStringFromSavedControl(jsonID, "popup_MoreSettings_Devices")

		if(!middleOfExperiment)
			CONF_PrimeDeviceLists(deviceToRecreate)
		endif

		if(forceNewPanel)
			device = DAP_CreateDAEphysPanel()
		else
			device = ""
			if(WindowExists(deviceToRecreate))
				device = deviceToRecreate
				if(PanelIsType(device, PANELTAG_DAEPHYS))
					winHandle = num2istr(GetUniqueInteger())
					SetWindow $device, userdata($EXPCONFIG_UDATA_WINHANDLE)=winHandle
					PGC_SetAndActivateControl(device, "button_SettingsPlus_unLockDevic")
					device = CONF_FindWindow(winHandle)
					ASSERT(!IsEmpty(device), "Could not find unlocked window, did it close?")
				endif
			endif
			if(IsEmpty(device))
				potentialUnlockedList = GetListOfUnlockedDevices()
				if(!IsEmpty(potentialUnlockedList))
					numPotentialUnlocked = ItemsInList(potentialUnlockedList)
					for(i = 0; i < numPotentialUnlocked; i += 1)
						device = StringFromList(i, potentialUnlockedList)
						if(PanelIsType(device, PANELTAG_DAEPHYS))
							break
						endif
					endfor
				endif
			endif
			if(IsEmpty(device))
				device = DAP_CreateDAEphysPanel()
			endif
		endif

		if(middleOfExperiment)
			PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = CHECKBOX_UNSELECTED)
			rStateSync = GetUserData(device, "check_Settings_SyncMiesToMCC", EXPCONFIG_UDATA_EXCLUDE_RESTORE)
			ModifyControl $"check_Settings_SyncMiesToMCC", win=$device, userdata($EXPCONFIG_UDATA_EXCLUDE_RESTORE)="1"
			winConfigChanged = 1
		endif

		StimSetPath = CONF_GetStringFromSettings(jsonID, EXPCONFIG_JSON_STIMSET_NAME)
		if(!IsEmpty(StimSetPath))
			ASSERT(FileExists(StimSetPath), "Specified StimSet file at " + StimSetPath + " not found!", extendedOutput = 0)
			err = NWB_LoadAllStimSets(overwrite = 1, fileName = StimSetPath)
			ASSERT(!err, "Specified StimSet file at " + StimSetPath + " could not be loaded!", extendedOutput = 0)

			print "Specified StimSet file at " + StimSetPath + " loaded successfully."
			SetWindow $device, userData($EXPCONFIG_UDATA_STIMSET_NWB_PATH)=StimSetPath
		endif

		restoreMask = EXPCONFIG_SAVE_VALUE | EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY | EXPCONFIG_SAVE_DISABLED | EXPCONFIG_SAVE_ONLY_RELEVANT | EXPCONFIG_MINIMIZE_ON_RESTORE
		winHandle   = num2istr(GetUniqueInteger())
		SetWindow $device, userdata($DAEPHYS_UDATA_WINHANDLE)=winHandle
		isTagged = 1

		WAVE/T winNames = CONF_GetWindowNames(jsonID)
		ASSERT(DimSize(winNames, ROWS) == 1, "DAEPhys configuration file contains configurations for more than one window.")

		if(restoreMask & EXPCONFIG_MINIMIZE_ON_RESTORE)
			SetWindow $device, hide=1
		endif

		jsonPath = winNames[0] + "/Generic ControlGroup/popup_MoreSettings_Devices"
		ASSERT(JSON_Exists(jsonID, jsonPath), "Missing critical JSON entry: " + jsonPath)
		CONF_RestoreControl(device, restoreMask, jsonID, "popup_MoreSettings_Devices", jsonPath = jsonPath)
		jsonPath = winNames[0] + "/Generic ControlGroup/button_SettingsPlus_LockDevice"
		ASSERT(JSON_Exists(jsonID, jsonPath), "Missing critical JSON entry: " + jsonPath)
		CONF_RestoreControl(device, restoreMask, jsonID, "button_SettingsPlus_LockDevice", jsonPath = jsonPath)
		device = CONF_FindWindow(winHandle, uKey = DAEPHYS_UDATA_WINHANDLE)

		CONF_RestoreHeadstageAssociation(device, jsonID, middleOfExperiment)

		device   = CONF_JSONToWindow(device, restoreMask, jsonID)
		isTagged = 0
		SetWindow $device, userdata($DAEPHYS_UDATA_WINHANDLE)=""

		if(middleOfExperiment)
			ModifyControl $"check_Settings_SyncMiesToMCC", win=$device, userdata($EXPCONFIG_UDATA_EXCLUDE_RESTORE)=rStateSync
		endif

		CONF_RestoreUserPressure(device, jsonID)

		filename = GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX
		path     = CONF_GetStringFromSettings(jsonID, EXPCONFIG_JSON_SAVE_PATH)

		if(IsDriveValid(path))
			CreateFolderOnDisk(path)
		endif

		NewPath/C/O SavePath, path

		SaveExperiment/P=SavePath as filename

		KillPath/Z SavePath

		uploadLogfiles = CONF_GetVariableFromSettings(jsonID, EXPCONFIG_JSON_LOGFILE_UPLOAD, defaultValue = EXPCONFIG_JSON_LOGFILE_UPLOAD_DEFAULT)
		if(uploadLogfiles)
			AssertOnAndClearRTError()
			try
				UploadLogFilesDaily(); AbortOnRTE
			catch
				ClearRTError()
				BUG("Error uploading logfiles -> skipped.")
			endtry
		endif

		PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 0, switchTab = 1)
		PGC_SetAndActivateControl(device, "StartTestPulseButton")

		print "Start Sciencing"
		SetWindow $device, hide=0, needUpdate=1
		return device
	catch
		if(isTagged)
			device = CONF_FindWindow(winHandle, uKey = DAEPHYS_UDATA_WINHANDLE)
		endif
		if(!IsEmpty(device) && WindowExists(device))
			SetWindow $device, userdata($DAEPHYS_UDATA_WINHANDLE)=""
			if(middleOfExperiment & winConfigChanged)
				ModifyControl $"check_Settings_SyncMiesToMCC", win=$device, userdata($EXPCONFIG_UDATA_EXCLUDE_RESTORE)=rStateSync
			endif
			SetWindow $device, hide=0, needUpdate=1
		endif
		errMsg = getRTErrMessage()
		if(ClearRTError())
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry
End

/// @brief Add the config file paths and SHA-256 hashes to the panel as user data
static Function CONF_AddConfigFileUserData(win, fullFilePath, rigFile)
	string win, fullFilePath, rigFile

	SetWindow $win, userData($EXPCONFIG_UDATA_SOURCEFILE_PATH)=fullFilePath + FILE_LIST_SEP + rigFile

	if(FileExists(rigFile))
		SetWindow $win, userData($EXPCONFIG_UDATA_SOURCEFILE_HASH)=CalcHashForFile(fullFilePath) + FILE_LIST_SEP + CalcHashForFile(rigFile)
	else
		SetWindow $win, userData($EXPCONFIG_UDATA_SOURCEFILE_HASH)=CalcHashForFile(fullFilePath) + FILE_LIST_SEP
	endif
End

/// @brief Parses a json formatted string to a json object. This function shows a helpful error message if the parse fails
///
/// @param[in] str string in json format
/// @returns jsonID of the json object
static Function CONF_ParseJSON(str)
	string str

	variable err

	AssertOnAndClearRTError()
	try
		JSONXOP_Parse/Z=0/Q=0 str; AbortOnRTE
		return V_Value
	catch
		ClearRTError()
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
End

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
	string   keyName

	CONF_RequireConfigBlockExists(jsonID)
	return JSON_GetString(jsonID, EXPCONFIG_RESERVED_DATABLOCK + "/" + keyName)
End

/// @brief Retrieves a variable/boolean/null value from a saved control
///        note: boolean control property values are also saved in the EXPCONFIG_FIELD_CTRLVVALUE field
///
/// @param jsonID       ID of existing json
/// @param keyName      key name of setting
/// @param defaultValue [optional, defaults to off] allows to query optional entries, if the value could not be found
///                     this is returned instead
///
/// @returns value of the EXPCONFIG_FIELD_CTRLVVALUE field of the control
static Function CONF_GetVariableFromSettings(jsonID, keyName, [defaultValue])
	variable jsonID
	string   keyName
	variable defaultValue

	variable val

	CONF_RequireConfigBlockExists(jsonID)

	if(ParamIsDefault(defaultValue))
		return JSON_GetVariable(jsonID, EXPCONFIG_RESERVED_DATABLOCK + "/" + keyName)
	endif

	val = JSON_GetVariable(jsonID, EXPCONFIG_RESERVED_DATABLOCK + "/" + keyName, ignoreErr = 1)

	if(!IsNaN(val))
		return val
	endif

	return defaultValue
End

/// @brief Returns the path to the first control named nicename found in the json in all saved windows
///        This might as well be a ControlArray.
///
/// @param jsonID   ID of existing json
/// @param niceName nice name of control
/// @returns Path to control in json, empty string if not found
static Function/S CONF_FindControl(jsonID, niceName)
	variable jsonID
	string   niceName

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
	string   arrayName

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
	string   niceName

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
	string   niceName

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

	ctrlList   = ControlNameList(wName, ";", "*")
	numWinCtrl = ItemsInList(ctrlList)

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE, 2) ctrlArrays
	SetDimLabel COLS, 0, ARRAYNAME, ctrlArrays
	SetDimLabel COLS, 1, CTRLNAMELIST, ctrlArrays

	col1 = FindDimLabel(ctrlArrays, COLS, "ARRAYNAME")
	for(i = 0; i < numWinCtrl; i += 1)
		ctrlName  = StringFromList(i, ctrlList)
		arrayName = GetUserData(wName, ctrlName, EXPCONFIG_UDATA_CTRLARRAY)
		if(!IsEmpty(arrayName))
			FindValue/RMD=[][col1]/TXOP=4/TEXT=arrayName ctrlArrays
			if(V_Value >= 0)
				ctrlArrays[V_Row][%CTRLNAMELIST] = AddListItem(ctrlName, ctrlArrays[V_Row][%CTRLNAMELIST])
			else
				EnsureLargeEnoughWave(ctrlArrays, dimension = ROWS, indexShouldExist = numCtrlArrays)
				ctrlArrays[numCtrlArrays][%ARRAYNAME]    = arrayName
				ctrlArrays[numCtrlArrays][%CTRLNAMELIST] = ctrlName
				numCtrlArrays                           += 1
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
	WAVE/T   ctrlData
	variable jsonID
	string   basePath

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
	variable arrayNameIndex, wType
	string ctrlName, niceName, arrayName, ctrlList, wList, uData, winHandle, jsonCtrlGroupPath, subWinTarget, str, errMsg

	AssertOnAndClearRTError()
	try
		ASSERT(WinType(wName), "Window " + wName + " does not exist!")
		ASSERT(restoreMask & (EXPCONFIG_SAVE_VALUE | EXPCONFIG_SAVE_POSITION | EXPCONFIG_SAVE_USERDATA | EXPCONFIG_SAVE_DISABLED | EXPCONFIG_SAVE_CTRLTYPE), "No property class enabled to restore in restoreMask.")

		SetWindow $wName, userData($EXPCONFIG_UDATA_SOURCEFILE_PATH)=""
		SetWindow $wName, userData($EXPCONFIG_UDATA_SOURCEFILE_HASH)=""

		if(restoreMask & EXPCONFIG_MINIMIZE_ON_RESTORE)
			SetWindow $wName, hide=1
		endif
		WAVE/T srcWinNames = CONF_GetWindowNames(jsonID)
		Duplicate/FREE/T srcWinNames, tgtWinNames
		tgtWinNames[] = RemoveListItem(0, srcWinNames[p], "#")

		numWindows = DimSize(srcWinNames, ROWS)
		for(winNum = 0; winNum < numWindows; winNum += 1)
			str          = tgtWinNames[winNum]
			subWinTarget = SelectString(IsEmpty(str), wName + "#" + str, wName)
			wType        = WinType(subWinTarget)
			ASSERT(wType, "Window " + subWinTarget + " does not exist!")
			if(wType == WINTYPE_NOTEBOOK)
				CONF_RestoreNotebookWindow(subWinTarget, srcWinNames[winNum], jsonID)
				continue
			endif

			Make/FREE/T/N=(0, 4) ctrlData
			SetDimLabel COLS, 0, NICENAME, ctrlData
			SetDimLabel COLS, 1, CTRLNAME, ctrlData
			SetDimLabel COLS, 2, JSONPATH, ctrlData
			SetDimLabel COLS, 3, PRIORITY, ctrlData

			CONF_GatherControlsFromJSON(ctrlData, jsonID, srcWinNames[winNum])

			colNiceName = FindDimLabel(ctrlData, COLS, "NICENAME")
			Duplicate/FREE/RMD=[][colNiceName] ctrlData, ctrlNiceNames
			Redimension/N=(DimSize(ctrlNiceNames, ROWS)) ctrlNiceNames

			ASSERT(!SearchForDuplicates(ctrlNiceNames), "Found duplicates in control names in configuration file for window " + subWinTarget)

			WAVE/T ctrlArrays = CONF_GetControlArrayList(subWinTarget)
			Make/FREE/B/U/N=(DimSize(ctrlArrays, ROWS)) ctrlArrayAdded
			ctrlList     = ControlNameList(subWinTarget, ";", "*")
			numWinCtrl   = ItemsInList(ctrlList)
			colArrayName = FindDimLabel(ctrlArrays, COLS, "ARRAYNAME")
			for(i = 0; i < numWinCtrl; i += 1)
				ctrlName  = StringFromList(i, ctrlList)
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
								numCtrl      = DimSize(ctrlData, ROWS)
								Redimension/N=(numCtrl + numArrayElem, 4) ctrlData
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%NICENAME] = arrayName
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%CTRLNAME] = StringFromList(p - numCtrl, ctrlArrays[arrayNameIndex][%CTRLNAMELIST])
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%JSONPATH] = jsonCtrlGroupPath
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%PRIORITY] = GetUserData(subWinTarget, ctrlData[p][%CTRLNAME], EXPCONFIG_UDATA_RESTORE_PRIORITY)
								ctrlData[numCtrl, numCtrl + numArrayElem - 1][%PRIORITY] = SelectString(strlen(ctrlData[p][%PRIORITY]), "Inf", ctrlData[p][%PRIORITY])
								ctrlArrayAdded[arrayNameIndex]                           = 1
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
						uData                      = GetUserData(subWinTarget, ctrlName, EXPCONFIG_UDATA_RESTORE_PRIORITY)
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
			SetWindow $subWinTarget, userdata($EXPCONFIG_UDATA_WINHANDLE)=winHandle
			isTagged = 1
			for(i = 0; i < numCtrl; i += 1)
				CONF_RestoreControl(subWinTarget, restoreMask, jsonID, ctrlData[i][%CTRLNAME], jsonPath = ctrlData[i][%JSONPATH])
				subWinTarget = CONF_FindWindow(winHandle)
				ASSERT(!IsEmpty(subWinTarget), "Could not find window, did it close?")
			endfor
			wName    = GetMainWindow(subWinTarget)
			isTagged = 0
			SetWindow $subWinTarget, userdata($EXPCONFIG_UDATA_WINHANDLE)=""
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
		if(ClearRTError())
			ASSERT(0, errMsg)
		else
			Abort
		endif
	endtry

	return wName
End

/// @brief Restores a notebook window content
///
/// @param wName  Name of notebook window in Igor
/// @param srcWin Name of window in JSON
/// @param jsonID Id of JSON
static Function CONF_RestoreNotebookWindow(string wName, string srcWin, variable jsonID)

	string jsonPath, nbText

	if(!CmpStr(GetUserData(wName, "", EXPCONFIG_UDATA_EXCLUDE_RESTORE), "1"))
		return NaN
	endif
	jsonPath = srcWin + "/" + EXPCONFIG_FIELD_NOTEBOOKTEXT
	nbText   = JSON_GetString(jsonID, jsonPath)
	ReplaceNotebookText(wName, nbText)
End

/// @brief Returns the window with the set window handle
///
/// @param winHandle window handle
/// @param uKey      [optional, default = EXPCONFIG_UDATA_WINHANDLE] userdata key that stores the handle value
/// @returns Window name of the window with the given handle; empty string if not found.
static Function/S CONF_FindWindow(winHandle, [uKey])
	string winHandle, uKey

	variable i, j, numWin, numSubWin
	string wList, wName, wSubList

	uKey   = SelectString(ParamIsDefault(uKey), uKey, EXPCONFIG_UDATA_WINHANDLE)
	wList  = WinList("*", ";", "WIN:87")
	numWin = ItemsInList(wList)
	for(i = 0; i < numWin; i += 1)
		wName     = StringFromList(i, wList)
		wSubList  = GetAllWindows(wName)
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
static Function CONF_RestoreControl(wName, restoreMask, jsonID, ctrlName, [jsonPath])
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
			i            = WhichListItem(ctrlTypeName, EXPCONFIG_GUI_CTRLLIST)
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
			VWidth  = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLPOSWIDTH)
			VTop    = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLPOSTOP)
			VPos    = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLPOSPOS)
			VAlign  = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLPOSALIGN)
			ModifyControl $ctrlName, win=$wName, align=VAlign, size={VWidth, VHeight}, pos={VPos, VTop}
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
						base64Key                  = uKey[strlen(EXPCONFIG_FIELD_BASE64PREFIX), Inf]
						udataBase64[base64Entries] = base64Key
						base64Entries             += 1
						DeletePoints i, 1, udataKeys
						i -= 1
					endif
				endfor
				Redimension/N=(base64Entries) udataBase64

				numUdataKeys = DimSize(udataKeys, ROWS)
				for(i = 0; i < numUdataKeys; i += 1)
					uKey  = udataKeys[i]
					uData = JSON_GetString(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLUSERDATA + "/" + uKey)
					FindValue/TXOP=4/TEXT=uKey udataBase64
					if(V_Value >= 0)
						uData = Base64Decode(uData)
					endif
					if(IsEmpty(uKey))
						ModifyControl $ctrlName, win=$wName, userdata=uData
					else
						ModifyControl $ctrlName, win=$wName, userdata($uKey)=uData
					endif
				endfor
			endif
		endif
		if(restoreMask & EXPCONFIG_SAVE_VALUE)
			if(ctrlType == CONTROL_TYPE_CHECKBOX || ctrlType == CONTROL_TYPE_SLIDER || ctrlType == CONTROL_TYPE_TAB || ctrlType == CONTROL_TYPE_VALDISPLAY)
				val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLVVALUE)
				PGC_SetAndActivateControl(wName, ctrlName, val = val, mode = PGC_MODE_SKIP_ON_DISABLED)
			elseif(ctrlType == CONTROL_TYPE_SETVARIABLE)
				setVarType = GetInternalSetVariableType(S_recreation)
				if(setVarType == SET_VARIABLE_BUILTIN_NUM)
					val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLVVALUE)
					PGC_SetAndActivateControl(wName, ctrlName, val = val, mode = PGC_MODE_SKIP_ON_DISABLED)
				elseif(setVarType == SET_VARIABLE_BUILTIN_STR)
					str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLSVALUE)
					PGC_SetAndActivateControl(wName, ctrlName, str = str, mode = PGC_MODE_SKIP_ON_DISABLED)
				else
					str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLSDF)
					if(IsEmpty(str))
						SetVariable $ctrlName, win=$wName, value=$""
					else
						varTypeGlobal = exists(str)
						if(varTypeGlobal == EXISTS_AS_WAVE || varTypeGlobal == EXISTS_AS_VAR_OR_STR)
							SetVariable $ctrlName, win=$wName, value=$str
						endif
					endif
				endif
			elseif(ctrlType == CONTROL_TYPE_POPUPMENU)
				if(restoreMask & EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY && !(restoreMask & EXPCONFIG_SAVE_ONLY_RELEVANT))
					val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLVVALUE)
					PGC_SetAndActivateControl(wName, ctrlName, val = val, mode = PGC_MODE_SKIP_ON_DISABLED)
				else
					str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_FIELD_CTRLSVALUE)
					PGC_SetAndActivateControl(wName, ctrlName, str = str, mode = PGC_MODE_SKIP_ON_DISABLED)
				endif
			elseif(ctrlType == CONTROL_TYPE_BUTTON)
				if(!CmpStr(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_BUTTONPRESS), "1"))
					PGC_SetAndActivateControl(wName, ctrlName, mode = PGC_MODE_SKIP_ON_DISABLED)
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
		ASSERT(arrayElemType != JSON_NULL, "Value for element " + num2istr(arrayIndex) + " in ControlArray of control " + ctrlName + " was not saved.")

		ControlInfo/W=$wName $ctrlName
		ctrlType = abs(V_Flag)
		if(ctrlType == CONTROL_TYPE_TAB || ctrlType == CONTROL_TYPE_SLIDER || ctrlType == CONTROL_TYPE_VALDISPLAY)
			ASSERT(arrayElemType == JSON_NUMERIC, "Expected numeric value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
			val = JSON_GetVariable(jsonID, arrayElemPath)
			PGC_SetAndActivateControl(wName, ctrlName, val = val, mode = PGC_MODE_SKIP_ON_DISABLED)
		elseif(ctrlType == CONTROL_TYPE_SETVARIABLE)
			setVarType = GetInternalSetVariableType(S_recreation)
			if(setVarType == SET_VARIABLE_BUILTIN_NUM)
				ASSERT(arrayElemType == JSON_NUMERIC, "Expected numeric value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
				val = JSON_GetVariable(jsonID, arrayElemPath)
				PGC_SetAndActivateControl(wName, ctrlName, val = val, mode = PGC_MODE_SKIP_ON_DISABLED)
			else
				ASSERT(arrayElemType == JSON_STRING, "Expected string value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
				str = JSON_GetString(jsonID, arrayElemPath)
				if(setVarType == SET_VARIABLE_BUILTIN_STR)
					PGC_SetAndActivateControl(wName, ctrlName, str = str, mode = PGC_MODE_SKIP_ON_DISABLED)
				elseif(IsEmpty(str))
					SetVariable $ctrlName, win=$wName, value=$""
				else
					varTypeGlobal = exists(str)
					if(varTypeGlobal == EXISTS_AS_WAVE || varTypeGlobal == EXISTS_AS_VAR_OR_STR)
						SetVariable $ctrlName, win=$wName, value=$str
					endif
				endif
			endif
		elseif(ctrlType == CONTROL_TYPE_POPUPMENU)
			if(restoreMask & EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY)
				ASSERT(arrayElemType == JSON_NUMERIC, "Expected numeric value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
				val = JSON_GetVariable(jsonID, arrayElemPath)
				PGC_SetAndActivateControl(wName, ctrlName, val = val, mode = PGC_MODE_SKIP_ON_DISABLED)
			else
				ASSERT(arrayElemType == JSON_STRING, "Expected string value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
				str = JSON_GetString(jsonID, arrayElemPath)
				PGC_SetAndActivateControl(wName, ctrlName, str = str, mode = PGC_MODE_SKIP_ON_DISABLED)
			endif
		elseif(ctrlType == CONTROL_TYPE_BUTTON)
			if(!CmpStr(GetUserData(wName, ctrlName, EXPCONFIG_UDATA_BUTTONPRESS), "1"))
				PGC_SetAndActivateControl(wName, ctrlName, mode = PGC_MODE_SKIP_ON_DISABLED)
			endif
		elseif(ctrlType == CONTROL_TYPE_CHECKBOX)
			ASSERT(arrayElemType == JSON_BOOL, "Expected boolean value for ControlArray of control " + ctrlName + " at " + num2istr(arrayIndex))
			val = JSON_GetVariable(jsonID, arrayElemPath)
			PGC_SetAndActivateControl(wName, ctrlName, val = val, mode = PGC_MODE_SKIP_ON_DISABLED)
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
Function CONF_AllWindowsToJSON(wName, saveMask, [excCtrlTypes])
	string   wName
	variable saveMask
	string   excCtrlTypes

	string wList, curWinName, errMsg
	variable i, numWins, jsonID, jsonIDWin

	AssertOnAndClearRTError()
	try
		excCtrlTypes = SelectString(ParamIsDefault(excCtrlTypes), excCtrlTypes, "")

		ASSERT(!CmpStr(wName, GetMainWindow(wName)), "Windows name is not a main window, use function CONF_WindowToJSON instead.")

		wList = GetAllWindows(wName)

		jsonID = JSON_New()

		JSON_AddString(jsonID, "/" + EXPCONFIG_RESERVED_TAGENTRY, GetUserData(wName, "", EXPCONFIG_UDATA_PANELTYPE))

		numWins = ItemsInList(wList)
		for(i = 0; i < numWins; i += 1)
			curWinName = StringFromList(i, wList)
			jsonIDWin  = CONF_WindowToJSON(curWinName, saveMask, excCtrlTypes = excCtrlTypes)

			if(JSON_GetType(jsonIDWin, "") == JSON_NULL)
				JSON_Release(jsonIDWin)
				continue
			endif

			WAVE/T ctrlList = JSON_GetKeys(jsonIDWin, "")
			if(DimSize(ctrlList, ROWS))
				JSON_SetJSON(jsonID, curWinName, jsonIDWin)
			endif
			JSON_Release(jsonIDWin)
		endfor

		return jsoNID

	catch
		errMsg = getRTErrMessage()
		if(ClearRTError())
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
Function CONF_WindowToJSON(wName, saveMask, [excCtrlTypes])
	string   wName
	variable saveMask
	string   excCtrlTypes

	string ctrlList, ctrlName, radioList, tmpList, wList, cbCtrlName, coupledIndexKeys = "", excUserKeys, radioFunc, str, errMsg
	variable numCtrl, i, j, jsonID, numCoupled, setRadioPos, ctrlType, coupledCnt, numUniqueCtrlArray, numDupCheck
	variable rbcIndex, wType

	AssertOnAndClearRTError()
	try
		excCtrlTypes = SelectString(ParamIsDefault(excCtrlTypes), excCtrlTypes, "")
		wType        = WinType(wName)
		ASSERT(wType, "Window " + wName + " does not exist!")
		jsonID = JSON_New()
		if(wType == WINTYPE_NOTEBOOK)
			CONF_NotebookToJSON(wName, jsonID)
			return jsonID
		endif

		ctrlList = ControlNameList(wName, ";", "*")
		numCtrl  = ItemsInList(ctrlList)
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
			WAVE/T arrayNamesRedux = GetUniqueEntries(arrayNames)
			arrayNamesRedux[] = LowerStr(arrayNamesRedux[p])
			FindValue/TXOP=4/TEXT="" arrayNamesRedux
			if(V_Value >= 0)
				DeletePoints V_Value, 1, arrayNamesRedux
			endif
		else
			Make/FREE/T/N=0 arrayNamesRedux
		endif

		Make/FREE/N=(numCtrl)/T duplicateCheck
		duplicateCheck[]   = SelectString(strlen(ctrlNames[p][%NICENAME]), LowerStr(ctrlNames[p][%CTRLNAME]), LowerStr(ctrlNames[p][%NICENAME]))
		numUniqueCtrlArray = DimSize(arrayNamesRedux, ROWS)
		if(numUniqueCtrlArray)
			Redimension/N=(numCtrl + numUniqueCtrlArray) duplicateCheck
			duplicateCheck[numCtrl, numCtrl + numUniqueCtrlArray - 1] = arrayNamesRedux[p - numCtrl]
		endif

		ASSERT(!SearchForDuplicates(duplicateCheck), "Human readable control names combined with internal control names have duplicates: " + TextWaveToList(duplicateCheck, ";"))

		numDupCheck = DimSize(duplicateCheck, ROWS)
		Make/FREE/I/N=(numDupCheck) groupEndingCheck
		groupEndingCheck[] = StringEndsWith(duplicateCheck[p], LowerStr(EXPCONFIG_CTRLGROUP_SUFFIX))
		FindValue/I=1 groupEndingCheck
		if(V_Value >= 0)
			ASSERT(0, "Control with [nice] name " + duplicateCheck[V_Value] + " uses a reserved suffix for control groups. Please change it to avoid conflicts.")
		endif

		radioFunc = GetUserData(wName, "", EXPCONFIG_UDATA_RADIOCOUPLING)
		if(!IsEmpty(radioFunc))
			FUNCREF CONF_GetRadioButtonCouplingProtoFunc rCoupleFunc         = $radioFunc
			WAVE/T                                       radioButtonCoupling = rCoupleFunc()
			coupledCnt = DimSize(radioButtonCoupling, ROWS)
			for(i = 0; i < coupledCnt; i += 1)
				radioList = radioButtonCoupling[i]
				numCtrl   = ItemsInList(radioList)
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
					FindValue/TXOP=4/TEXT=(StringFromList(1, radioList)) ctrlNames
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
		if(ClearRTError())
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

/// @brief Adds a notebook window including content to a json
///
/// @param wName  Window name
/// @param jsonID ID of existing json
static Function CONF_NotebookToJSON(string wName, variable jsonID)

	string nbText

	if(!CmpStr(GetUserData(wName, "", EXPCONFIG_UDATA_EXCLUDE_SAVE), "1"))
		return NaN
	endif
	nbText = GetNotebookText(wName, mode = 2)
	JSON_AddString(jsonID, EXPCONFIG_FIELD_NOTEBOOKTEXT, nbText)
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

	variable ctrlType, pos, i, numUdataKeys, setVarType, arrayIndex, oldSize, preferCode, arrayElemType
	string wList, ctrlPath, controlPath, niceName, jsonPath, udataPath, uDataKey, uData, s, arrayName, arrayElemPath

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

	arrayName   = GetUserData(wName, ctrlName, EXPCONFIG_UDATA_CTRLARRAY)
	niceName    = SelectString(IsEmpty(arrayName), arrayName, niceName)
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
			WAVE/T/Z udataKeys = GetUserDataKeys(S_recreation)
			numUdataKeys = WaveExists(udataKeys) ? DimSize(udataKeys, ROWS) : 0
			for(i = 0; i < numUdataKeys; i += 1)
				uDataKey = udataKeys[i]
				if(WhichListItem(uDataKey, excUserKeys) >= 0)
					continue
				endif
				uData = GetUserData(wName, ctrlName, uDataKey)
				AssertOnAndClearRTError()
				try
					s = ConvertTextEncoding(uData, TextEncodingCode("UTF-8"), TextEncodingCode("UTF-8"), 1, 0); AbortOnRTE
				catch
					ClearRTError()
					uData = Base64Encode(udata)
					JSON_AddString(jsonID, udataPath + EXPCONFIG_FIELD_BASE64PREFIX + uDataKey, "1")
				endtry
				JSON_AddString(jsonID, udataPath + uDataKey, uData)
			endfor
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
		JSONXOP_Remove/Q=1/Z=1 jsonID, controlPath
	endif
End

/// @brief Opens MCCs and restores Headstage Association from configuration data to DA_Ephys panel
/// @param[in] device panel title of DA_Ephys panel
/// @param[in] jsonID ID of json object with configuration data
/// @param[in] midExp middle of experiment - uploads MCC relevant settings from panel to MCC instead
static Function CONF_RestoreHeadstageAssociation(device, jsonID, midExp)
	string device
	variable jsonID, midExp

	variable i, type, numRows, ampSerial, ampChannel, index, value, warnMissingMCCSync
	string jsonPath, jsonBasePath, jsonPathAmpBlock
	string ampSerialList = ""
	string ampTitleList  = ""

	CONF_RequireConfigBlockExists(jsonID)
	WAVE/T keys = JSON_GetKeys(jsonID, EXPCONFIG_RESERVED_DATABLOCK)
	FindValue/TXOP=4/TEXT=EXPCONFIG_JSON_HSASSOCBLOCK keys
	ASSERT(V_Value >= 0, "Headstage Association block not found in configuration.")

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		jsonBasePath = EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_HSASSOCBLOCK + "/" + num2istr(i)
		type         = JSON_GetType(jsonID, jsonBasePath)
		if(type == JSON_NULL)
			continue
		elseif(type == JSON_OBJECT)
			jsonPath = jsonBasePath + "/" + EXPCONFIG_JSON_AMPBLOCK
			if(JSON_GetType(jsonID, jsonPath + "/" + EXPCONFIG_JSON_AMPSERIAL) == JSON_NULL)
				continue
			endif
			ampSerial = JSON_GetVariable(jsonID, jsonPath + "/" + EXPCONFIG_JSON_AMPSERIAL)

			if(IsNaN(ampSerial))
				continue
			endif

			ampSerialList = AddListItem(num2istr(ampSerial), ampSerialList)
			ampTitleList  = AddListItem(JSON_GetString(jsonID, jsonPath + "/" + EXPCONFIG_JSON_AMPTITLE), ampTitleList)
		else
			ASSERT(0, "Unexpected entry for headstage data in Headstage Association block")
		endif
	endfor

	WAVE telegraphServers = GetAmplifierTelegraphServers()
	numRows = DimSize(telegraphServers, ROWS)
	if(!numRows)
		Assert(AI_OpenMCCs(device, ampSerialList, ampTitleList = ampTitleList), "Evil kittens prevented MultiClamp from opening - FULL STOP")
	endif

	CONF_Position_MCC_Win(ampSerialList, ampTitleList, CONF_GetStringFromSettings(jsonID, EXPCONFIG_JSON_POSITION_MCC))

	PGC_SetAndActivateControl(device, "button_Settings_UpdateAmpStatus")
	PGC_SetAndActivateControl(device, "button_Settings_UpdateDACList")

	warnMissingMCCSync = !GetCheckBoxState(device, "check_Settings_SyncMiesToMCC")

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = i)

		jsonBasePath = EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_HSASSOCBLOCK + "/" + num2istr(i)
		type         = JSON_GetType(jsonID, jsonBasePath)

		if(type == JSON_NULL)
			PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", str = NONE)
			PGC_SetAndActivateControl(device, "popup_Settings_Pressure_dev", str = NONE)
			if(!IsDeviceNameFromSutter(device))
				PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")
			endif
		elseif(type == JSON_OBJECT)
			jsonPathAmpBlock = jsonBasePath + "/" + EXPCONFIG_JSON_AMPBLOCK + "/"
			ampSerial        = JSON_GetVariable(jsonID, jsonPathAmpBlock + EXPCONFIG_JSON_AMPSERIAL)
			ampChannel       = JSON_GetVariable(jsonID, jsonPathAmpBlock + EXPCONFIG_JSON_AMPCHANNEL)

			if(IsFinite(ampSerial) && IsFinite(ampChannel))
				PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = CONF_FindAmpInList(ampSerial, ampChannel))
				PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")
			else
				PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", str = NONE)
				jsonPath = jsonPathAmpBlock + EXPCONFIG_JSON_VCBLOCK + "/"
				CONF_OnExistSetAndActivateControlVar(device, "setvar_Settings_VC_DAgain", jsonID, jsonPath + EXPCONFIG_JSON_AMPVCDAGAIN)
				CONF_OnExistSetAndActivateControlVar(device, "setvar_Settings_VC_ADgain", jsonID, jsonPath + EXPCONFIG_JSON_AMPVCADGAIN)
				CONF_OnExistSetAndActivateControlStr(device, "SetVar_Hardware_VC_DA_Unit", jsonID, jsonPath + EXPCONFIG_JSON_AMPVCDAUNIT)
				CONF_OnExistSetAndActivateControlStr(device, "SetVar_Hardware_VC_AD_Unit", jsonID, jsonPath + EXPCONFIG_JSON_AMPVCADUNIT)

				jsonPath = jsonPathAmpBlock + EXPCONFIG_JSON_ICBLOCK + "/"
				CONF_OnExistSetAndActivateControlVar(device, "setvar_Settings_IC_DAgain", jsonID, jsonPath + EXPCONFIG_JSON_AMPICDAGAIN)
				CONF_OnExistSetAndActivateControlVar(device, "setvar_Settings_IC_ADgain", jsonID, jsonPath + EXPCONFIG_JSON_AMPICADGAIN)
				CONF_OnExistSetAndActivateControlStr(device, "SetVar_Hardware_IC_DA_Unit", jsonID, jsonPath + EXPCONFIG_JSON_AMPICDAUNIT)
				CONF_OnExistSetAndActivateControlStr(device, "SetVar_Hardware_IC_AD_Unit", jsonID, jsonPath + EXPCONFIG_JSON_AMPICADUNIT)
			endif
			jsonPath = jsonPathAmpBlock + EXPCONFIG_JSON_VCBLOCK + "/"
			CONF_SetDAEPhysChannelPopup(device, "Popup_Settings_VC_DA", jsonID, jsonPath + EXPCONFIG_JSON_AMPVCDA)
			CONF_SetDAEPhysChannelPopup(device, "Popup_Settings_VC_AD", jsonID, jsonPath + EXPCONFIG_JSON_AMPVCAD)
			jsonPath = jsonPathAmpBlock + EXPCONFIG_JSON_ICBLOCK + "/"
			CONF_SetDAEPhysChannelPopup(device, "Popup_Settings_IC_DA", jsonID, jsonPath + EXPCONFIG_JSON_AMPICDA)
			CONF_SetDAEPhysChannelPopup(device, "Popup_Settings_IC_AD", jsonID, jsonPath + EXPCONFIG_JSON_AMPICAD)

			jsonPath = jsonBasePath + "/" + EXPCONFIG_JSON_PRESSUREBLOCK + "/"
			PGC_SetAndActivateControl(device, "popup_Settings_Pressure_dev", str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDEV))
			PGC_SetAndActivateControl(device, "Popup_Settings_Pressure_DA", val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDA))
			PGC_SetAndActivateControl(device, "Popup_Settings_Pressure_AD", val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSAD))
			PGC_SetAndActivateControl(device, "setvar_Settings_Pressure_DAgain", val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDAGAIN))
			PGC_SetAndActivateControl(device, "setvar_Settings_Pressure_ADgain", val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSADGAIN))
			PGC_SetAndActivateControl(device, "SetVar_Hardware_Pressur_DA_Unit", str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDAUNIT))
			PGC_SetAndActivateControl(device, "SetVar_Hardware_Pressur_AD_Unit", str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_JSON_PRESSADUNIT))
			value = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSTTLA)
			if(IsNaN(value))
				PGC_SetAndActivateControl(device, "Popup_Settings_Pressure_TTLA", str = NONE)
			else
				PGC_SetAndActivateControl(device, "Popup_Settings_Pressure_TTLA", str = num2istr(value))
			endif
			value = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSTTLB)
			if(IsNaN(value))
				PGC_SetAndActivateControl(device, "Popup_Settings_Pressure_TTLB", str = NONE)
			else
				PGC_SetAndActivateControl(device, "Popup_Settings_Pressure_TTLB", str = num2istr(value))
			endif
			WAVE pressureDataWv = P_GetPressureDataWaveRef(device)
			index                               = FindDimLabel(pressureDataWv, ROWS, "headStage_" + num2str(i))
			pressureDataWv[index][%NegCalConst] = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSCONSTNEG)
			pressureDataWv[index][%PosCalConst] = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSCONSTPOS)

			if(IsFinite(ampSerial))
				if(!midExp)
					if(warnMissingMCCSync)
						printf "The sync MIES to MCC settings checkbox is not checked.\rRestored amplifier settings will not be applied to Multiclamp commander.\r"
						warnMissingMCCSync = 0
					endif

					CONF_RestoreAmplifierSettings(device, i, jsonID, jsonBasePath)
				else
					CONF_MCC_MidExp(device, i, jsonID)
				endif
			endif
		endif
	endfor
	PGC_SetAndActivateControl(device, "button_Hardware_P_Enable")

End

static Function CONF_OnExistSetAndActivateControlVar(string win, string ctrl, variable jsonId, string jsonPath)

	if(JSON_Exists(jsonId, jsonPath))
		PGC_SetAndActivateControl(win, ctrl, val = JSON_GetVariable(jsonID, jsonPath))
	endif
End

static Function CONF_OnExistSetAndActivateControlStr(string win, string ctrl, variable jsonId, string jsonPath)

	if(JSON_Exists(jsonId, jsonPath))
		PGC_SetAndActivateControl(win, ctrl, str = JSON_GetString(jsonID, jsonPath))
	endif
End

static Function CONF_SetDAEPhysChannelPopup(string device, string ctrl, variable jsonId, string jsonPath)

	variable channelNumber

	if(IsDeviceNameFromSutter(device))
		return NaN
	endif

	if(JSON_Exists(jsonId, jsonPath))
		channelNumber = JSON_GetVariable(jsonID, jsonPath)
		if(IsNaN(channelNumber))
			PGC_SetAndActivateControl(device, ctrl, str = NONE)
		else
			PGC_SetAndActivateControl(device, ctrl, val = channelNumber)
		endif
	endif
End

/// @brief Retrieves current User Pressure settings to json
/// @param[in] device panel title of DA_Ephys panel
/// @returns jsonID ID of json object with user pressure configuration data
static Function CONF_GetUserPressure(device)
	string device

	variable jsonID

	jsonID = JSON_New()

	JSON_AddString(jsonID, EXPCONFIG_JSON_USERPRESSDEV, GetPopupMenuString(device, "popup_Settings_UserPressure"))
	JSON_AddVariable(jsonID, EXPCONFIG_JSON_USERPRESSDA, str2num(GetPopupMenuString(device, "Popup_Settings_UserPressure_ADC")))

	return jsonID
End

/// @brief Restore User Pressure settings
/// @param[in] device panel title of DA_Ephys panel
/// @param[in] jsonID ID of json object with configuration data
static Function CONF_RestoreUserPressure(device, jsonID)
	string   device
	variable jsonID

	string jsonPath

	CONF_RequireConfigBlockExists(jsonID)
	WAVE/T keys = JSON_GetKeys(jsonID, EXPCONFIG_RESERVED_DATABLOCK)
	FindValue/TXOP=4/TEXT=EXPCONFIG_JSON_USERPRESSBLOCK keys
	ASSERT(V_Value >= 0, "User Pressure block not found in configuration.")
	jsonPath = EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_USERPRESSBLOCK + "/"
	PGC_SetAndActivateControl(device, "popup_Settings_UserPressure", str = JSON_GetString(jsonID, jsonPath + EXPCONFIG_JSON_USERPRESSDEV))
	PGC_SetAndActivateControl(device, "Popup_Settings_UserPressure_ADC", val = JSON_GetVariable(jsonID, jsonPath + EXPCONFIG_JSON_USERPRESSDA))
	PGC_SetAndActivateControl(device, "button_Hardware_PUser_Enable")
End

/// @brief Retrieves current amplifier and pressure settings to json
///
/// @param[in] device device
/// @returns jsonID ID of json object with user pressure configuration data
static Function CONF_GetAmplifierSettings(device)
	string device

	variable jsonID, i, clampMode, ampSerial, ampChannelID, index
	string jsonPath, amplifierDef, basePath

	jsonID = JSON_New()

	WAVE chanAmpAssign = GetChanAmpAssign(device)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		basePath = num2istr(i)

		if(!statusHS[i])
			JSON_AddNull(jsonID, basePath)
			continue
		endif

		PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = i)

		clampMode = DAG_GetHeadstageMode(device, i)

		jsonPath = basePath + "/" + EXPCONFIG_JSON_AMPBLOCK
		JSON_AddTreeObject(jsonID, jsonPath)

		jsonPath = basePath + "/" + EXPCONFIG_JSON_AMPBLOCK + "/" + EXPCONFIG_JSON_VCBLOCK
		JSON_AddTreeObject(jsonID, jsonPath)
		jsonPath += "/"

		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPVCDA, str2numsafe(GetPopupMenuString(device, "Popup_Settings_VC_DA")))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPVCAD, str2numsafe(GetPopupMenuString(device, "Popup_Settings_VC_AD")))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPVCDAGAIN, GetSetVariable(device, "setvar_Settings_VC_DAgain"))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPVCADGAIN, GetSetVariable(device, "setvar_Settings_VC_ADgain"))
		JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_AMPVCDAUNIT, GetSetVariableString(device, "SetVar_Hardware_VC_DA_Unit"))
		JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_AMPVCADUNIT, GetSetVariableString(device, "SetVar_Hardware_VC_AD_Unit"))

		jsonPath = basePath + "/" + EXPCONFIG_JSON_AMPBLOCK + "/" + EXPCONFIG_JSON_ICBLOCK
		JSON_AddTreeObject(jsonID, jsonPath)
		jsonPath += "/"

		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPICDA, str2num(GetPopupMenuString(device, "Popup_Settings_IC_DA")))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPICAD, str2num(GetPopupMenuString(device, "Popup_Settings_IC_AD")))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPICDAGAIN, GetSetVariable(device, "setvar_Settings_IC_DAgain"))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPICADGAIN, GetSetVariable(device, "setvar_Settings_IC_ADgain"))
		JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_AMPICDAUNIT, GetSetVariableString(device, "SetVar_Hardware_IC_DA_Unit"))
		JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_AMPICADUNIT, GetSetVariableString(device, "SetVar_Hardware_IC_AD_Unit"))

		ampSerial    = ChanAmpAssign[%AmpSerialNo][i]
		ampChannelID = ChanAmpAssign[%AmpChannelID][i]
		if(IsFinite(ampSerial) && IsFinite(ampChannelID))

			jsonPath = basePath + "/" + EXPCONFIG_JSON_AMPBLOCK + "/"

			JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_AMPTITLE, StringFromList(trunc(i / 2), EXPCONFIG_SETTINGS_AMPTITLE))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPSERIAL, ampSerial)
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMPCHANNEL, ampChannelID)

			jsonPath = basePath + "/" + EXPCONFIG_JSON_AMPBLOCK + "/" + EXPCONFIG_JSON_VCBLOCK + "/"

			// read VC settings
			DAP_ChangeHeadStageMode(device, V_CLAMP_MODE, i, DO_MCC_MIES_SYNCING)

			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_HOLD_VC, DAG_GetNumericalValue(device, "setvar_DataAcq_Hold_VC"))
			JSON_AddBoolean(jsonID, jsonPath + EXPCONFIG_JSON_AMP_HOLD_ENABLE_VC, DAG_GetNumericalValue(device, "check_DatAcq_HoldEnableVC"))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_PIPETTE_OFFSET_VC, DAG_GetNumericalValue(device, "setvar_DataAcq_PipetteOffset_VC"))

			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_WHOLE_CELL_CAPACITANCE, DAG_GetNumericalValue(device, "setvar_DataAcq_WCC"))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_WHOLE_CELL_RESISTANCE, DAG_GetNumericalValue(device, "setvar_DataAcq_WCR"))
			JSON_AddBoolean(jsonID, jsonPath + EXPCONFIG_JSON_AMP_WHOLE_CELL_ENABLE, DAG_GetNumericalValue(device, "check_DatAcq_WholeCellEnable"))

			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_RS_COMP_CORRECTION, DAG_GetNumericalValue(device, "setvar_DataAcq_RsCorr"))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_RS_COMP_PREDICTION, DAG_GetNumericalValue(device, "setvar_DataAcq_RsPred"))
			JSON_AddBoolean(jsonID, jsonPath + EXPCONFIG_JSON_AMP_RS_COMP_ENABLE, DAG_GetNumericalValue(device, "check_DatAcq_RsCompEnable"))
			JSON_AddBoolean(jsonID, jsonPath + EXPCONFIG_JSON_AMP_COMP_CHAIN, DAG_GetNumericalValue(device, "check_DataAcq_Amp_Chain"))

			// MCC settings without GUI control
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_LPF, AI_SendToAmp(device, i, V_CLAMP_MODE, MCC_GETPRIMARYSIGNALLPF_FUNC, NaN))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_GAIN, AI_SendToAmp(device, i, V_CLAMP_MODE, MCC_GETPRIMARYSIGNALGAIN_FUNC, NaN))

			jsonPath = basePath + "/" + EXPCONFIG_JSON_AMPBLOCK + "/" + EXPCONFIG_JSON_ICBLOCK + "/"

			// read IC settings
			DAP_ChangeHeadStageMode(device, I_CLAMP_MODE, i, DO_MCC_MIES_SYNCING)

			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_HOLD_IC, DAG_GetNumericalValue(device, "setvar_DataAcq_Hold_IC"))
			JSON_AddBoolean(jsonID, jsonPath + EXPCONFIG_JSON_AMP_HOLD_ENABLE_IC, DAG_GetNumericalValue(device, "check_DatAcq_HoldEnable"))

			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_BRIDGE_BALANCE, DAG_GetNumericalValue(device, "setvar_DataAcq_BB"))
			JSON_AddBoolean(jsonID, jsonPath + EXPCONFIG_JSON_AMP_BRIDGE_BALANCE_ENABLE, DAG_GetNumericalValue(device, "check_DatAcq_BBEnable"))

			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_CAP_NEUTRALIZATION, DAG_GetNumericalValue(device, "setvar_DataAcq_CN"))
			JSON_AddBoolean(jsonID, jsonPath + EXPCONFIG_JSON_AMP_CAP_NEUTRALIZATION_ENABLE, DAG_GetNumericalValue(device, "check_DatAcq_CNEnable"))

			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_AUTOBIAS_V, DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV"))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_AUTOBIAS_V_RANGE, DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasVrange"))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_AUTOBIAS_I_BIAS_MAX, DAG_GetNumericalValue(device, "setvar_DataAcq_IbiasMax"))
			JSON_AddBoolean(jsonID, jsonPath + EXPCONFIG_JSON_AMP_AUTOBIAS, DAG_GetNumericalValue(device, "check_DataAcq_AutoBias"))

			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_PIPETTE_OFFSET_IC, DAG_GetNumericalValue(device, "setvar_DataAcq_PipetteOffset_IC"))

			// MCC settings without GUI control
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_LPF, AI_SendToAmp(device, i, I_CLAMP_MODE, MCC_GETPRIMARYSIGNALLPF_FUNC, NaN))
			JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_AMP_GAIN, AI_SendToAmp(device, i, I_CLAMP_MODE, MCC_GETPRIMARYSIGNALGAIN_FUNC, NaN))

			if(clampMode != I_CLAMP_MODE)
				DAP_ChangeHeadStageMode(device, clampMode, i, DO_MCC_MIES_SYNCING)
			endif
		else
			jsonPath = basePath + "/" + EXPCONFIG_JSON_AMPBLOCK + "/"
			JSON_AddNull(jsonID, jsonPath + EXPCONFIG_JSON_AMPSERIAL)
			JSON_AddNull(jsonID, jsonPath + EXPCONFIG_JSON_AMPCHANNEL)
		endif

		// the following GUI values are *not* stored in the GUI state wave

		jsonPath = basePath + "/" + EXPCONFIG_JSON_PRESSUREBLOCK
		JSON_AddTreeObject(jsonID, jsonPath)
		jsonPath += "/"

		JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDEV, GetPopupMenuString(device, "popup_Settings_Pressure_dev"))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDA, str2num(GetPopupMenuString(device, "Popup_Settings_Pressure_DA")))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSAD, str2num(GetPopupMenuString(device, "Popup_Settings_Pressure_AD")))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDAGAIN, GetSetVariable(device, "setvar_Settings_Pressure_DAgain"))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSADGAIN, GetSetVariable(device, "setvar_Settings_Pressure_ADgain"))
		JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_PRESSDAUNIT, GetSetVariableString(device, "SetVar_Hardware_Pressur_DA_Unit"))
		JSON_AddString(jsonID, jsonPath + EXPCONFIG_JSON_PRESSADUNIT, GetSetVariableString(device, "SetVar_Hardware_Pressur_AD_Unit"))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSTTLA, str2numsafe(GetPopupMenuString(device, "Popup_Settings_Pressure_TTLA")))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSTTLB, str2numsafe(GetPopupMenuString(device, "Popup_Settings_Pressure_TTLB")))

		WAVE pressureDataWv = P_GetPressureDataWaveRef(device)
		index = FindDimLabel(pressureDataWv, ROWS, "headStage_" + num2str(i))
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSCONSTNEG, pressureDataWv[index][%NegCalConst])
		JSON_AddVariable(jsonID, jsonPath + EXPCONFIG_JSON_PRESSCONSTPOS, pressureDataWv[index][%PosCalConst])
	endfor

	return jsonID
End

/// @brief Restore the per headstage amplifier settings
///
/// @param[in] device device
/// @param[in] headStage  MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param[in] jsonID     ID of json object with configuration data
/// @param[in] basePath   absolute path in the json file to search the entries
static Function CONF_RestoreAmplifierSettings(device, headStage, jsonID, basePath)
	string device
	variable headStage, jsonID
	string basePath

	variable clampMode, val, ret
	string path

	clampMode = DAG_GetHeadstageMode(device, headstage)

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = headStage)

	// set VC settings
	DAP_ChangeHeadStageMode(device, V_CLAMP_MODE, headStage, DO_MCC_MIES_SYNCING)

	path = basePath + "/" + EXPCONFIG_JSON_AMPBLOCK + "/" + EXPCONFIG_JSON_VCBLOCK + "/"

	PGC_SetAndActivateControl(device, "setvar_DataAcq_Hold_VC", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_HOLD_VC))
	PGC_SetAndActivateControl(device, "check_DatAcq_HoldEnableVC", val = !!JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_HOLD_ENABLE_VC))

	PGC_SetAndActivateControl(device, "setvar_DataAcq_PipetteOffset_VC", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_PIPETTE_OFFSET_VC))

	PGC_SetAndActivateControl(device, "setvar_DataAcq_WCC", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_WHOLE_CELL_CAPACITANCE))
	PGC_SetAndActivateControl(device, "setvar_DataAcq_WCR", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_WHOLE_CELL_RESISTANCE))
	PGC_SetAndActivateControl(device, "check_DatAcq_WholeCellEnable", val = !!JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_WHOLE_CELL_ENABLE))

	PGC_SetAndActivateControl(device, "setvar_DataAcq_RsCorr", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_RS_COMP_CORRECTION))
	PGC_SetAndActivateControl(device, "setvar_DataAcq_RsPred", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_RS_COMP_PREDICTION))
	PGC_SetAndActivateControl(device, "check_DatAcq_RsCompEnable", val = !!JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_RS_COMP_ENABLE))
	PGC_SetAndActivateControl(device, "check_DataAcq_Amp_Chain", val = !!JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_COMP_CHAIN))

	// MCC settings without GUI control
	val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_LPF, ignoreErr = 1)
	if(!IsNaN(val))
		ret = AI_SendToAmp(device, headstage, V_CLAMP_MODE, MCC_SETPRIMARYSIGNALLPF_FUNC, val)
		ASSERT(ret == 0, "Could not set LPF primary output")
	endif

	val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_GAIN, ignoreErr = 1)
	if(!IsNaN(val))
		ret = AI_SendToAmp(device, headstage, V_CLAMP_MODE, MCC_SETPRIMARYSIGNALGAIN_FUNC, val)
		ASSERT(ret == 0, "Could not set primary output gain")
	endif

	// set IC settings
	DAP_ChangeHeadStageMode(device, I_CLAMP_MODE, headStage, DO_MCC_MIES_SYNCING)

	path = basePath + "/" + EXPCONFIG_JSON_AMPBLOCK + "/" + EXPCONFIG_JSON_ICBLOCK + "/"

	PGC_SetAndActivateControl(device, "setvar_DataAcq_Hold_IC", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_HOLD_IC))
	PGC_SetAndActivateControl(device, "check_DatAcq_HoldEnable", val = !!JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_HOLD_ENABLE_IC))

	PGC_SetAndActivateControl(device, "setvar_DataAcq_BB", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_BRIDGE_BALANCE))
	PGC_SetAndActivateControl(device, "check_DatAcq_BBEnable", val = !!JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_BRIDGE_BALANCE_ENABLE))

	PGC_SetAndActivateControl(device, "setvar_DataAcq_CN", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_CAP_NEUTRALIZATION))
	PGC_SetAndActivateControl(device, "check_DatAcq_CNEnable", val = !!JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_CAP_NEUTRALIZATION_ENABLE))

	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_AUTOBIAS_V))
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasVrange", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_AUTOBIAS_V_RANGE))
	PGC_SetAndActivateControl(device, "setvar_DataAcq_IbiasMax", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_AUTOBIAS_I_BIAS_MAX))
	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = !!JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_AUTOBIAS))

	PGC_SetAndActivateControl(device, "setvar_DataAcq_PipetteOffset_IC", val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_PIPETTE_OFFSET_IC))

	// MCC settings without GUI control
	val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_LPF, ignoreErr = 1)
	if(!IsNaN(val))
		ret = AI_SendToAmp(device, headstage, I_CLAMP_MODE, MCC_SETPRIMARYSIGNALLPF_FUNC, val)
		ASSERT(ret == 0, "Could not set LPF primary output")
	endif

	val = JSON_GetVariable(jsonID, path + EXPCONFIG_JSON_AMP_GAIN, ignoreErr = 1)
	if(!IsNaN(val))
		ret = AI_SendToAmp(device, headstage, I_CLAMP_MODE, MCC_SETPRIMARYSIGNALGAIN_FUNC, val)
		ASSERT(ret == 0, "Could not set LPF primary output")
	endif

	if(clampMode != I_CLAMP_MODE)
		DAP_ChangeHeadStageMode(device, clampMode, headStage, DO_MCC_MIES_SYNCING)
	endif
End

/// @brief Find the list index of a connected amplifier serial number
///
/// @param ampSerialRef    Amplifier Serial Number to search for
/// @param ampChannelIDRef Headstage reference number
static Function CONF_FindAmpInList(ampSerialRef, ampChannelIDRef)
	variable ampSerialRef, ampChannelIDRef

	string listOfAmps, ampDef
	variable numAmps, i, ampSerial, ampChannelID

	listOfAmps = DAP_GetNiceAmplifierChannelList()
	numAmps    = ItemsInList(listOfAmps)

	for(i = 0; i < numAmps; i += 1)
		ampDef = StringFromList(i, listOfAmps)
		DAP_ParseAmplifierDef(ampDef, ampSerial, ampChannelID)
		if(ampSerial == ampSerialRef && ampChannelID == ampChannelIDRef)
			return i
		endif
	endfor

	ASSERT(0, "Could not find amplifier")
End

static Function CONF_MCC_MidExp(device, headStage, jsonID)
	string device
	variable headStage, jsonID

	variable settingValue, clampMode

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = headStage)

	clampMode = AI_GetMode(device, headstage)

	if(clampMode == V_CLAMP_MODE)

		settingValue = AI_SendToAmp(device, headStage, V_CLAMP_MODE, MCC_GETPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_PipetteOffset_VC", val = settingValue)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_PipetteOffset_IC", val = settingValue)
		settingValue = AI_SendToAmp(device, headStage, V_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_Hold_VC", val = settingValue)
		settingValue = AI_SendToAmp(device, headStage, V_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "check_DatAcq_HoldEnableVC", val = settingValue)
		PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = CHECKBOX_SELECTED)
		printf "HeadStage %d is in V-Clamp mode and has been configured from the MCC. I-Clamp settings were reset to initial values, check before switching!\r", headStage
	elseif(clampMode == I_CLAMP_MODE)
		settingValue = AI_SendToAmp(device, headStage, I_CLAMP_MODE, MCC_GETPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_PipetteOffset_VC", val = settingValue)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_PipetteOffset_IC", val = settingValue)
		settingValue = AI_SendToAmp(device, headStage, I_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_Hold_IC", val = settingValue)
		settingValue = AI_SendToAmp(device, headStage, I_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "check_DatAcq_HoldEnable", val = settingValue)
		settingValue = AI_SendToAmp(device, headStage, I_CLAMP_MODE, MCC_GETBRIDGEBALRESIST_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_BB", val = settingValue)
		settingValue = AI_SendToAmp(device, headStage, I_CLAMP_MODE, MCC_GETBRIDGEBALENABLE_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "check_DatAcq_BBEnable", val = settingValue)
		settingValue = AI_SendToAmp(device, headStage, I_CLAMP_MODE, MCC_GETNEUTRALIZATIONCAP_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_CN", val = settingValue)
		settingValue = AI_SendToAmp(device, headStage, I_CLAMP_MODE, MCC_GETNEUTRALIZATIONENABL_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(device, "check_DatAcq_CNEnable", val = settingValue)
		PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = CHECKBOX_UNSELECTED)
		PGC_SetAndActivateControl(device, "check_DatAcq_HoldEnableVC", val = CHECKBOX_UNSELECTED)
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

	cmdPath = GetWindowsPath(GetFolder(FunctionPath("")) + "::tools:nircmd:nircmd.exe")
	if(!FileExists(cmdPath))
		printf "nircmd.exe is not installed, please download it here: %s", "http://www.nirsoft.net/utils/nircmd.html"
		return NaN
	endif

	Make/T/FREE/N=(NUM_HEADSTAGES / 2) winNm
	for(w = 0; w < NUM_HEADSTAGES / 2; w += 1)

		winNm[w] = {stringfromlist(w, winTitle) + "(" + stringfromlist(w, serialNum) + ")"}
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
	string   rigFileName

	string   input
	variable jsonIDRig

	[input, rigFileName] = LoadTextFile(rigFileName)
	if(IsEmpty(input))
		return 0
	endif
	jsonIDRig = CONF_ParseJSON(input)
	JSON_SyncJSON(jsonIDRig, jsonID, "", "", JSON_SYNC_ADD_TO_TARGET)
	JSON_Release(jsonIDRig)
End

/// @brief Retrieves the JSON original used to restore the DAEphys panel from the disk
/// @param[in] wName name of DAEphys panel
/// @param[in] loadRigFile [optional, default 0] when set, load the rig file instead
///
/// @returns jsonId or NaN if data was not present
static Function [variable jsonId, string txtData] CONF_LoadConfigUsedForDAEphysPanel(string wName, [variable loadRigFile])

	string fName, str

	loadRigFile = ParamIsDefault(loadRigFile) ? 0 : !!loadRigFile
	ASSERT(PanelIsType(wName, PANELTAG_DAEPHYS), "Window is no DA_Ephys panel")

	fName = StringFromList(loadRigFile, GetUserData(wName, "", EXPCONFIG_UDATA_SOURCEFILE_PATH), FILE_LIST_SEP)
	if(IsEmpty(fName))
		return [NaN, ""]
	endif
	if(!FileExists(fName))
		printf "Info: Tried to load former configuration file saved in DAEphys user data, but file does not exist: %s\rUsing default settings.\r", fName
		return [NaN, ""]
	endif
	[txtData, str] = LoadTextFile(fName)
	if(IsEmpty(txtData))
		return [NaN, ""]
	endif

	return [JSON_Parse(txtData, ignoreErr = 1), txtData]
End

static Function CONF_TransferPreviousDAEphysJson(variable jsonId, variable prevJsonId)

	string jsonPath, entry

	WAVE/T entryList = JSON_GetKeys(jsonId, EXPCONFIG_RESERVED_DATABLOCK)
	for(entry : entryList)
		jsonPath = EXPCONFIG_RESERVED_DATABLOCK + "/" + entry
		JSON_SyncJSON(prevJsonId, jsonId, jsonPath, jsonPath, JSON_SYNC_ADD_TO_TARGET | JSON_SYNC_OVERWRITE_IN_TARGET)
	endfor
End

static Function CONF_RemoveRigElementsFromDAEphysJson(variable jsonId, variable rigJsonId, [string jsonPath])

	string newJsonPath, key

	if(ParamIsDefault(jsonpath))
		jsonPath = ""
	endif

	ASSERT(JSON_Exists(rigJsonId, jsonPath), "Attempt to access non-existing json path.")
	WAVE/T keys = JSON_GetKeys(rigJsonId, jsonPath)
	for(key : keys)
		newJsonPath = jsonPath + "/" + key
		switch(JSON_GetType(rigJsonId, newJsonPath))
			case JSON_OBJECT:
				CONF_RemoveRigElementsFromDAEphysJson(jsonId, rigJsonId, jsonPath = newJsonPath)
				break
			default:
				ASSERT(JSON_Exists(jsonId, newJsonPath), "JSON path from previous rig file not found in current DAEPhys JSON: " + newJsonPath)
				JSON_Remove(jsonId, newJsonPath)
				break
		endswitch
	endfor
End

static Function/S CONF_GetDAEphysConfigurationFileNameSuggestion(string wName)

	string prevFullFilePath

	ASSERT(PanelIsType(wName, PANELTAG_DAEPHYS), "Window is no DA_Ephys panel")

	prevFullFilePath = StringFromList(0, GetUserData(wName, "", EXPCONFIG_UDATA_SOURCEFILE_PATH), FILE_LIST_SEP)
	if(!FileExists(prevFullFilePath))
		return ""
	endif

	return GetFolder(prevFullFilePath) + GetBaseName(prevFullFilePath) + "_new.json"
End

/// @brief Loads through all config json files and synchronizes global package settings in config files (if present) to user package settings with overwrite.
Function CONF_UpdatePackageSettingsFromConfigFiles(variable jsonIdPkg)

	string fName, input, fullFilePath, globalSettingsPath
	variable jsonIdConf

	WAVE/T/Z configFiles = CONF_GetConfigFiles()
	if(WaveExists(configFiles))
		globalSettingsPath = "/" + EXPCONFIG_RESERVED_DATABLOCK + "/" + EXPCONFIG_JSON_GLOBALPACKAGESETTINGBLOCK
		for(fName : configFiles)

			[input, fullFilePath] = LoadTextFile(fName)
			if(IsEmpty(input))
				continue
			endif

			jsonIdConf = JSON_Parse(input, ignoreErr = 1)
			if(!JSON_IsValid(jsonIdConf))
				continue
			endif

			if(!JSON_Exists(jsonIdConf, globalSettingsPath))
				continue
			endif

			JSON_SyncJSON(jsonIdConf, jsonIdPkg, globalSettingsPath, "", JSON_SYNC_OVERWRITE_IN_TARGET)
		endfor
	endif
End
