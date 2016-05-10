#pragma rtGlobals=3

/// @file MIES_WaveDataFolderGetters.ipf
///
/// @brief Collection of Wave and Datafolder getter functions
///
/// - All functions with return types `DF` or `Wave` return an existing wave or datafolder.
/// - Prefer functions which return a `DFREF` over functions which return strings.
///   The latter ones are only useful if you need to know if the folder exists.
/// - Modifying wave getter functions might require to introduce wave versioning, see @ref WaveVersioningSupport

static Constant NUM_COLUMNS_LIST_WAVE   = 11
static Constant PRESSURE_WAVE_DATA_SIZE = 131072 // equals 2^17
static StrConstant WAVE_NOTE_LAYOUT_KEY = "WAVE_LAYOUT_VERSION"

/// @brief Return a wave reference to the channel <-> amplifier relation wave (numeric part)
///
/// Rows:
/// - 0-3: V-Clamp: DA channel, DA gain, AD channel, AD gain
/// - 4-7: I-Clamp: DA channel, DA gain, AD channel, AD gain
/// - 8: Amplifier Serial number as returned by `AxonTelegraphFindServers`. This differs
///      compared to the ones returned by `MCC_FindServers`, as the latter are strings with leading zeros.
///      E.g.: "00000123" vs 123
///      E.g.: "Demo"     vs 0
/// - 9: Amplifier Channel ID
///
/// Columns:
/// - Head stage number
///
Function/Wave GetChanAmpAssign(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)
	variable versionOfNewWave = 2

	Wave/Z/SDFR=dfr wv = ChanAmpAssign

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(10, NUM_HEADSTAGES, -1, -1) wv
	else
		Make/N=(10, NUM_HEADSTAGES) dfr:ChanAmpAssign/Wave=wv
		wv = NaN
	endif

	SetDimLabel ROWS,  0, VC_DA,        wv
	SetDimLabel ROWS,  1, VC_DAGain,    wv
	SetDimLabel ROWS,  2, VC_AD,        wv
	SetDimLabel ROWS,  3, VC_ADGain,    wv

	SetDimLabel ROWS,  4, IC_DA,        wv
	SetDimLabel ROWS,  5, IC_DAGain,    wv
	SetDimLabel ROWS,  6, IC_AD,        wv
	SetDimLabel ROWS,  7, IC_ADGain,    wv

	SetDimLabel ROWS,  8, AmpSerialNo,  wv
	SetDimLabel ROWS,  9, AmpChannelID, wv

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return a wave reference to the channel <-> amplifier relation wave (textual part)
///
/// Rows:
/// - 0: DA unit (V-Clamp mode)
/// - 1: AD unit (V-Clamp mode)
/// - 2: DA unit (I-Clamp mode)
/// - 3: AD unit (I-Clamp mode)
///
/// Columns:
/// - Head stage number
///
Function/Wave GetChanAmpAssignUnit(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	Wave/T/Z/SDFR=dfr wv = ChanAmpAssignUnit

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(4, NUM_HEADSTAGES) dfr:ChanAmpAssignUnit/Wave=wv
	wv = ""
	
	return wv
End

/// @brief Return a wave reference to the headstage <-> manipulator link (numeric part)
///
/// Rows:
/// -0: Manipulator number
///
/// Columns:
/// - Head stage number
///
Function/Wave GetHSManipulatorAssignments(panelTitle)
	string panelTitle

	DFREF dfr = GetManipulatorPath()
	variable versionOfNewWave = 1
	
	Wave/Z/SDFR=dfr wv = $panelTitle
	
	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
	    // change the required dimensions and leave all others untouched with -1
 	    // the extended dimensions are initialized with zero
 		Redimension/N=(NUM_HEADSTAGES,1, -1, -1) wv
	else
		Make/N=(NUM_HEADSTAGES, 1) dfr:$panelTitle/Wave=wv
		wv = NaN
		SetDimLabel COLS, 0, ManipulatorNumber, wv
	endif
	
	SetWaveVersion(wv, versionOfNewWave)
	
	return wv
End

/// @brief Return a wave reference to the headstage <-> manipulator link (textual part)
///
/// Rows:
/// -0: Manipulator name
///
/// Columns:
/// - Head stage number
///
Function/Wave GetHSManipulatorName(panelTitle)
	string panelTitle

	DFREF dfr = GetManipulatorPath()
	variable versionOfNewWave = 1
	
	Wave/T/Z/SDFR=dfr wv = $panelTitle + "_S"

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
 		Redimension/N=(NUM_HEADSTAGES,1, -1, -1) wv
 	else 
 		Make/T/N=(NUM_HEADSTAGES, 1) dfr:$panelTitle+"_S"/Wave=wv
		wv = ""
		SetDimLabel COLS, 0, ManipulatorName, wv
	endif

	SetWaveVersion(wv, versionOfNewWave)
	
	return wv
End

/// @brief Return a wave reference to the wave used for gizmo plotting manipulator positions in 3D
///
/// Rows:
/// - Manipulator
///
/// Columns:
/// - 0: Xpos
/// - 1: Ypos
/// - 2: Zpos
///
Function/Wave GetManipulatorPos(panelTitle)
	string panelTitle
	string Name = "Gizmo_" + panelTitle
	DFREF dfr = GetManipulatorPath()
	variable versionOfNewWave = 1

	Wave/Z/SDFR=dfr wv =$Name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
 		Redimension/N=(NUM_HEADSTAGES,3, -1, -1) wv
 		wv = NaN
	else
		Make/N=(NUM_HEADSTAGES, 3) dfr:$Name/Wave=wv
		SetDimLabel COLS, 0, Xpos, wv
		SetDimLabel COLS, 1, Ypos, wv
		SetDimLabel COLS, 2, Zpos, wv
	endif

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @name Wave versioning support
/// @anchor WaveVersioningSupport
///
/// The wave getter functions always return an existing wave.
/// This can result in problems if the layout of the wave changes.
///
/// Layout in this context means:
/// - Sizes of all dimensions
/// - Labels of all dimensions
/// - Wave data type
/// - Prefilled wave content
///
/// In order to enable smooth upgrades between old and new wave layouts
/// the following code pattern can be used:
/// @code
/// Function/Wave GetMyWave(panelTitle)
/// 	string panelTitle
///
/// 	DFREF dfr = GetMyPath(panelTitle)
/// 	variable versionOfNewWave = 1
///
/// 	Wave/Z/SDFR=dfr wv = myWave
///
/// 	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
/// 		return wv
/// 	elseif(WaveExists(wv)) // handle upgrade
/// 	    // change the required dimensions and leave all others untouched with -1
/// 	    // the extended dimensions are initialized with zero
/// 		Redimension/N=(10, -1, -1, -1) wv
/// 	else
/// 		Make/N=(10, 2) dfr:myWave/Wave=wv
/// 	end
///
/// 	SetWaveVersion(wv, versionOfNewWave)
///
/// 	return wv
/// End
/// @endcode
///
/// Now everytime the layout of `myWave` changes, raise `versionOfNewWave` by 1 and
/// adapt the `Make` and `Redimension` calls. When `GetMyWave` is called the first time,
/// the wave is redimensioned, and on successive calls the newly recreated wave is just returned.
/// Fancy solutions might adapt the redimensioning step depending on the new and old version.
/// The old version can be queried with `GetNumberFromWaveNote(wv, WAVE_NOTE_LAYOUT_KEY)`.
///
/// Hints:
/// - Wave layout versioning is *mandatory* if you change the layout of the wave
/// - Wave layout versions start with 1 and are integers
/// - Rule of thumb: Raise the version if you change anything in or below the `Make` line
/// - Wave versioning needs a special wave note style, see @ref GetNumberFromWaveNote
/// @{

/// @brief Check if wv exists and has the correct version
static Function ExistsWithCorrectLayoutVersion(wv, versionOfNewWave)
	Wave/Z wv
	variable versionOfNewWave

	// The equality check ensures that you can also downgrade, e.g. from version 5 to 4, although this is *strongly* discouraged.
	return WaveExists(wv) && GetNumberFromWaveNote(wv, WAVE_NOTE_LAYOUT_KEY) == versionOfNewWave
End

/// @brief Set the wave layout version of wave
static Function SetWaveVersion(wv, val)
	Wave wv
	variable val

	ASSERT(val > 0 && IsInteger(val), "val must be a positive and non-zero integer")
	SetNumberInWaveNote(wv, WAVE_NOTE_LAYOUT_KEY, val)
End

/// @}

/// @brief Return a wave reference to the channel clamp mode wave
///
/// Rows:
/// - Channel numbers
///
/// Columns:
/// - 0: DAC channels
/// - 1: ADC channels
///
/// Contents:
/// - Clamp mode: One of V_CLAMP_MODE, I_CLAMP_MODE and I_EQUAL_ZERO_MODE
Function/Wave GetChannelClampMode(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	Wave/Z/SDFR=dfr wv = ChannelClampMode

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(16,2) dfr:ChannelClampMode/Wave=wv

	SetDimLabel COLS, 0, DAC, wv
	SetDimLabel COLS, 1, ADC, wv

	return wv
End

/// @brief Return the ITC devices folder "root:mies:ITCDevices"
Function/DF GetITCDevicesFolder()

	return createDFWithAllParents(GetITCDevicesFolderAsString())
End

/// @brief Return a data folder reference to the ITC devices folder
Function/S GetITCDevicesFolderAsString()

	return GetMiesPathAsString() + ":ITCDevices"
End

/// @brief Return the active ITC devices timer folder "root:mies:ITCDevices:ActiveITCDevices:Timer"
Function/DF GetActiveITCDevicesTimerFolder()

	return createDFWithAllParents(GetActiveITCDevicesTimerAS())
End

/// @brief Return a data folder reference to the active ITC devices timer folder
Function/S GetActiveITCDevicesTimerAS()

	return GetActiveITCDevicesFolderAS() + ":Timer"
End

/// @brief Return the active ITC devices folder "root:mies:ITCDevices:ActiveITCDevices"
Function/DF GetActiveITCDevicesFolder()

	return createDFWithAllParents(GetActiveITCDevicesFolderAS())
End

/// @brief Return a data folder reference to the active ITC devices folder
Function/S GetActiveITCDevicesFolderAS()

	return GetITCDevicesFolderAsString() + ":ActiveITCDevices"
End

/// @brief Return a datafolder reference to the device type folder
Function/DF GetDeviceTypePath(deviceType)
	string deviceType
	return createDFWithAllParents(GetDeviceTypePathAsString(deviceType))
End

/// @brief Return the path to the device type folder, e.g. root:mies:ITCDevices:ITC1600
Function/S GetDeviceTypePathAsString(deviceType)
	string deviceType

	return GetITCDevicesFolderAsString() + ":" + deviceType
End

/// @brief Return a datafolder reference to the device folder
Function/DF GetDevicePath(panelTitle)
	string panelTitle
	return createDFWithAllParents(GetDevicePathAsString(panelTitle))
End

/// @brief Return the path to the device folder, e.g. root:mies:ITCDevices:ITC1600:Device0
Function/S GetDevicePathAsString(panelTitle)
	string panelTitle

	string deviceType, deviceNumber
	if(!ParseDeviceString(panelTitle, deviceType, deviceNumber) || !CmpStr(deviceType, StringFromList(0, BASE_WINDOW_TITLE, "_")))
		ASSERT(0, "Invalid/Non-locked paneltitle")
	endif

	return GetDeviceTypePathAsString(deviceType) + ":Device" + deviceNumber
End

/// @brief Return a datafolder reference to the device data browser folder
Function/DF GetDeviceDataBrowserPath(panelTitle)
	string panelTitle
	return createDFWithAllParents(GetDeviceDataBrowserPathAS(panelTitle))
End

/// @brief Return the path to the device folder, e.g. root:mies:ITCDevices:ITC1600:Device0:DataBrowser
Function/S GetDeviceDataBrowserPathAS(panelTitle)
	string panelTitle

	return GetDevicePathAsString(panelTitle) + ":DataBrowser"
End

/// @brief Return a datafolder reference to the device data folder
Function/DF GetDeviceDataPath(panelTitle)
	string panelTitle
	return createDFWithAllParents(GetDeviceDataPathAsString(panelTitle))
End

/// @brief Return the path to the device folder, e.g. root:mies:ITCDevices:ITC1600:Device0:Data
Function/S GetDeviceDataPathAsString(panelTitle)
	string panelTitle
	return GetDevicePathAsString(panelTitle) + ":Data"
End

/// @brief Returns a data folder reference to the mies base folder
Function/DF GetMiesPath()
	return createDFWithAllParents(GetMiesPathAsString())
End

/// @brief Returns the base folder for all MIES functionality, e.g. root:MIES
Function/S GetMiesPathAsString()
	return "root:MIES"
End

/// @brief Retuns data folder path to the manipulator folder, e.g. root:mies:manipulators
Function/S GetManipulatorPathAsString()
	return GetMiesPathAsString() + ":Manipulators"
End

/// @brief Return a data folder reference for the Manipulator folder
Function/DF GetManipulatorPath()
	return createDFWithAllParents(GetManipulatorPathAsString())
End

/// @brief Return the ITC data wave
Function/Wave GetITCDataWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/W/Z/SDFR=dfr wv = ITCDataWave

	if(WaveExists(wv))
		return wv
	endif

	Make/W/N=(1, NUM_DA_TTL_CHANNELS) dfr:ITCDataWave/Wave=wv

	return wv
End

/// @brief Return the ITC channel config wave
Function/Wave GetITCChanConfigWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/I/Z/SDFR=dfr wv = ITCChanConfigWave

	if(WaveExists(wv))
		return wv
	endif

	Make/I/N=(2, 4) dfr:ITCChanConfigWave/Wave=wv

	return wv
End

/// @brief Return the ITC fifo available for all channels wave
Function/Wave GetITCFIFOAvailAllConfigWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/I/Z/SDFR=dfr wv = ITCFIFOAvailAllConfigWave

	if(WaveExists(wv))
		return wv
	endif

	Make/I/N=(2, 4) dfr:ITCFIFOAvailAllConfigWave/Wave=wv

	return wv
End

/// @brief Return the ITC fifo available for all channels wave
Function/Wave GetITCFIFOPositionAllConfigWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/I/Z/SDFR=dfr wv = ITCFIFOPositionAllConfigWave

	if(WaveExists(wv))
		return wv
	endif

	Make/I/N=(2, 4) dfr:ITCFIFOPositionAllConfigWave/Wave=wv

	return wv
End

/// @brief Return the ITC result data wave
Function/Wave GetITCResultsWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/I/Z/SDFR=dfr wv = ResultsWave

	if(WaveExists(wv))
		return wv
	endif

	Make/I/N=(4) dfr:ResultsWave/Wave=wv

	return wv
End

/// @name Experiment Documentation
/// @{

/// @brief Return the datafolder reference to the lab notebook
Function/DF GetLabNotebookFolder()

	return createDFWithAllParents(GetLabNotebookFolderAsString())
End

/// @brief Return the full path to the lab notebook, e.g. root:MIES:LabNoteBook
Function/S GetLabNotebookFolderAsString()

	return GetMiesPathAsString() + ":LabNoteBook"
End

/// @brief Return the data folder reference to the device specific lab notebook
Function/DF GetDevSpecLabNBFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBFolderAsString(panelTitle))
End

/// @brief Return the full path to the device specific lab notebook, e.g. root:MIES:LabNoteBook:ITC18USB:Device0
Function/S GetDevSpecLabNBFolderAsString(panelTitle)
	string panelTitle

	string deviceType, deviceNumber
	variable ret

	ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
	ASSERT(ret, "Could not parse the panelTitle")

	return GetLabNotebookFolderAsString() + ":" + deviceType + ":Device" + deviceNumber
End

/// @brief Return the datafolder reference to the device specific settings key
Function/DF GetDevSpecLabNBSettKeyFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBSettKeyFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific settings key, e.g. root:mies:LabNoteBook:ITC18USB:Device0:KeyWave
Function/S GetDevSpecLabNBSettKeyFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":KeyWave"
End

/// @brief Return the datafolder reference to the device specific settings history
Function/DF GetDevSpecLabNBSettHistFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBSettHistFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific settings history, e.g. root:mies:LabNoteBook:ITC18USB:Device0:settingsHistory
Function/S GetDevSpecLabNBSettHistFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":settingsHistory"
End

/// @brief Return the datafolder reference to the device specific text doc key
Function/DF GetDevSpecLabNBTxtDocKeyFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBTextDocKeyFoldAS(panelTitle))
End

/// @brief Return the full path to the device specific text doc key, e.g. root:mies:LabNoteBook:ITC18USB:Device0:textDocKeyWave
Function/S GetDevSpecLabNBTextDocKeyFoldAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":TextDocKeyWave"
End

/// @brief Return the datafolder reference to the device specific text documentation
Function/DF GetDevSpecLabNBTextDocFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBTextDocFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific text documentation, e.g. root:mies:LabNoteBook:ITC18USB:Device0:textDocumentation
Function/S GetDevSpecLabNBTextDocFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":textDocumentation"
End

/// @brief Returns a wave reference to the txtDocWave
///
/// Labnotebook with text settings
///
/// Rows:
/// - Filled at runtime
///
/// Columns:
/// - Filled at runtime
///
/// Layers:
/// - 0-7: data for a particular headstage using the layer index
/// - 8: headstage independent data
Function/Wave GetTextDocWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTextDocFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = txtDocWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1, 2, LABNOTEBOOK_LAYER_COUNT) dfr:txtDocWave/Wave=wv
	wv = ""

	return wv
End

/// @brief Handle upgrades of the numerical/text labnotebooks in one step
///
/// Supported upgrades:
/// - Addition of the third column "TimeStampSinceIgorEpochUTC"
/// - Addition of nineth layer for headstage independent data
/// - Conversion of numeric labnotebook to 64bit floats
/// - Removal of invalid units for "Stim Scale Factor", "DA Gain" and "AD Gain"
static Function UpgradeLabNotebook(panelTitle)
	string panelTitle

	variable numCols, i, col, numEntries
	string list, key

	WAVE  settingsHistory = GetNumDocWave(panelTitle)
	WAVE/T txtDocWave     = GetTextDocWave(panelTitle)

	Wave/Z/T/SDFR=GetDevSpecLabNBSettKeyFolder(panelTitle)   keyWave
	Wave/Z/T/SDFR=GetDevSpecLabNBTxtDocKeyFolder(panelTitle) txtDocKeyWave

	if(!WaveExists(keyWave))
		WAVE/T keyWave = GetNumDocKeyWave(panelTitle)
	endif

	if(!WaveExists(txtDocKeyWave))
		WAVE/T txtDocKeyWave = GetTextDocKeyWave(panelTitle)
	endif

	ASSERT(DimSize(keyWave, COLS) == DimSize(settingsHistory, COLS), "Non matching number of rows for numeric labnotebook")
	ASSERT(DimSize(txtDocKeyWave, COLS) == DimSize(txtDocWave, COLS), "Non matching number of rows for textual labnotebook")

	if(cmpstr(keyWave[0][2], "TimeStampSinceIgorEpochUTC"))

		numCols = DimSize(keyWave, COLS)

		Redimension/N=(-1, numCols + 1, -1) keyWave, settingsHistory

		keyWave[][numCols]           = keyWave[p][2]
		settingsHistory[][numCols][] = settingsHistory[p][2][r]

		settingsHistory[][2][] = NaN
		keyWave[][2]           = ""
		keyWave[0][2]          = "TimeStampSinceIgorEpochUTC"
		SetDimensionLabels(keyWave, settingsHistory)

		DEBUGPRINT("Upgraded numerical labnotebook to hold UTC timestamps")
	endif

	if(cmpstr(txtDocKeyWave[0][2], "TimeStampSinceIgorEpochUTC"))

		numCols = DimSize(txtDocKeyWave, COLS)

		Redimension/N=(-1, numCols + 1, -1) txtDocKeyWave, txtDocWave

		txtDocKeyWave[][numCols] = txtDocKeyWave[p][2]
		txtDocWave[][numCols][]  = txtDocWave[p][2][r]

		txtDocWave[][2][]   = ""
		txtDocKeyWave[][2]  = ""
		txtDocKeyWave[0][2] = "TimeStampSinceIgorEpochUTC"
		SetDimensionLabels(txtDocKeyWave, txtDocWave)

		DEBUGPRINT("Upgraded textual labnotebook to hold UTC timestamps")
	endif

	if(DimSize(txtDocWave, LAYERS) == NUM_HEADSTAGES && DimSize(settingsHistory, LAYERS) == NUM_HEADSTAGES)
		Redimension/N=(-1, -1, LABNOTEBOOK_LAYER_COUNT, -1) txtDocWave, settingsHistory
		txtDocWave[][][8]      = ""
		settingsHistory[][][8] = NaN

		DEBUGPRINT("Upgraded labnotebooks to handle headstage independent data")
	endif

	if(WaveType(settingsHistory) == IGOR_TYPE_32BIT_FLOAT)
		Redimension/Y=(IGOR_TYPE_64BIT_FLOAT) settingsHistory

		DEBUGPRINT("Upgraded numeric labnotebook to 64bit floats")
	endif

	list       = "Stim Scale Factor;DA Gain;AD Gain"
	numEntries = ItemsInList(list)

	for(i = 0; i < numEntries; i += 1)
		key = StringFromList(i, list)
		col = FindDimLabel(keyWave, COLS, key)
		if(col >= 0 && cmpstr(keyWave[%Units][col], ""))
			keyWave[%Units][col] = ""
			if(i == 0)
				DEBUGPRINT("Upgraded numeric labnotebook key wave to remove invalid units")
			endif
		endif
	endfor
End

/// @brief Return a wave reference to the textDocKeyWave
///
/// textDocKeyWave is used to index save settings for each data sweep
/// and create waveNotes for tagging data sweeps
///
/// Rows:
/// - 0: Parameter Name
/// - 1: Parameter Unit
/// - 2: Parameter Tolerance
///
/// Columns:
/// - 0: Sweep Number
/// - 1: Time Stamp in local time zone
/// - 2: Time Stamp in UTC
/// - other columns are filled at runtime
Function/Wave GetTextDocKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTxtDocKeyFolder(panelTitle)

	variable versionOfNewWave = 4

	Wave/Z/T/SDFR=dfr wv = txtDocKeyWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		UpgradeLabNotebook(panelTitle)
		SetWaveVersion(wv, versionOfNewWave)
		return wv
	else
		Make/T/N=(3, INITIAL_KEY_WAVE_COL_COUNT) dfr:txtDocKeyWave/Wave=wv
	endif

	wv = ""

	wv[0][0] = "SweepNum"
	wv[0][1] = "TimeStamp"
	wv[0][2] = "TimeStampSinceIgorEpochUTC"

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units,     wv
	SetDimLabel ROWS, 2, Tolerance, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to keyWave
///
/// keyWave is used to index save settings for each data sweep
/// and create waveNotes for tagging data sweeps
///
/// Rows:
/// - 0: Parameter Name
/// - 1: Parameter Unit
/// - 2: Parameter Tolerance
///
/// Columns:
/// - 0: Sweep Number
/// - 1: Time Stamp in local time zone
/// - 2: Time Stamp in UTC
/// - other columns are filled at runtime
Function/Wave GetNumDocKeyWave(panelTitle)
	string panelTitle

	variable versionOfNewWave = 4

	DFREF dfr = GetDevSpecLabNBSettKeyFolder(panelTitle)
	Wave/T/Z/SDFR=dfr wv = keyWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		UpgradeLabNotebook(panelTitle)
		SetWaveVersion(wv, versionOfNewWave)
		return wv
	else
		Make/T/N=(3, INITIAL_KEY_WAVE_COL_COUNT) dfr:keyWave/Wave=wv
	endif

	wv = ""

	wv[0][0] = "SweepNum"
	wv[0][1] = "TimeStamp"
	wv[0][2] = "TimeStampSinceIgorEpochUTC"

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units,     wv
	SetDimLabel ROWS, 2, Tolerance, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to settingsHistory
///
/// Labnotebook with numerical settings
///
/// Rows:
/// - Filled at runtime
///
/// Columns:
/// - Filled at runtime
///
/// Layers:
/// - 0-7: data for a particular headstage using the layer index
/// - 8: headstage independent data
Function/Wave GetNumDocWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBSettHistFolder(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = settingsHistory

	if(!WaveExists(wv))
		Make/D/N=(MINIMUM_WAVE_SIZE, 3, LABNOTEBOOK_LAYER_COUNT) dfr:settingsHistory/Wave=wv = NaN

		SetDimLabel COLS, 0, SweepNum                  , wv
		SetDimLabel COLS, 1, TimeStamp                 , wv
		SetDimLabel COLS, 2, TimeStampSinceIgorEpochUTC, wv

		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	endif

	return wv
End

/// @brief Returns a wave reference to the sweepSettingsWave
///
/// sweepSettingsWave is used to save stimulus settings for each
/// data sweep and create waveNotes for tagging data sweeps
///
/// Additional columns, necessary for unassociated channels, are created on runtime.
///
/// Rows:
///  - One row
///
/// Columns:
/// - Same as #GetSweepSettingsKeyWave
///
/// Layers:
/// - 0-7: data for a particular headstage using the layer index
/// - 8: headstage independent data
Function/Wave GetSweepSettingsWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBSettHistFolder(panelTitle)
	variable versionOfNewWave = 5

	Wave/Z/SDFR=dfr wv = sweepSettingsWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 23, LABNOTEBOOK_LAYER_COUNT) wv
	else
		Make/N=(1, 23, LABNOTEBOOK_LAYER_COUNT) dfr:sweepSettingsWave/Wave=wv
	endif

	wv = NaN

	SetDimLabel COLS, 0 , $"Stim Scale Factor"          , wv
	SetDimLabel COLS, 1 , $"DAC"                        , wv
	SetDimLabel COLS, 2 , $"ADC"                        , wv
	SetDimLabel COLS, 3 , $"DA Gain"                    , wv
	SetDimLabel COLS, 4 , $"AD Gain"                    , wv
	SetDimLabel COLS, 5 , $"Set Sweep Count"            , wv
	SetDimLabel COLS, 6 , $"TP Insert Checkbox"         , wv
	SetDimLabel COLS, 7 , $"Inter-trial interval"       , wv
	SetDimLabel COLS, 8 , $"TTL rack zero bits"         , wv
	SetDimLabel COLS, 9 , $"TTL rack one bits"          , wv
	SetDimLabel COLS, 10, $"TTL rack zero channel"      , wv
	SetDimLabel COLS, 11, $"TTL rack one channel"       , wv
	SetDimLabel COLS, 12, $"Delay onset user"           , wv
	SetDimLabel COLS, 13, $"Delay onset auto"           , wv
	SetDimLabel COLS, 14, $"Delay termination"          , wv
	SetDimLabel COLS, 15, $"Delay distributed DAQ"      , wv
	SetDimLabel COLS, 16, $"Distributed DAQ"            , wv
	SetDimLabel COLS, 17, $"Repeat Sets"                , wv
	SetDimLabel COLS, 18, $"Scaling zero"               , wv
	SetDimLabel COLS, 19, $"Indexing"                   , wv
	SetDimLabel COLS, 20, $"Locked indexing"            , wv
	SetDimLabel COLS, 21, $"Repeated Acquisition"       , wv
	SetDimLabel COLS, 22, $"Random Repeated Acquisition", wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns a wave reference to the sweepSettingsKeyWave
///
/// sweepSettingsKeyWave is used to index save stimulus settings for
/// each data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
/// - 0: Parameter
/// - 1: Units
/// - 2: Tolerance Factor
///
/// Columns:
/// - 0:  Stim Scale Factor
/// - 1:  DAC
/// - 2:  ADC
/// - 3:  DA Gain
/// - 4:  AD Gain
/// - 5:  Set sweep count
/// - 6:  Insert TP on/off
/// - 7:  Inter-trial interval
/// - 8:  TTL rack zero bits
/// - 9:  TTL rack one bits
/// - 10: TTL rack zero channel
/// - 11: TTL rack one channel
/// - 12: Delay onset user
/// - 13: Delay onset auto
/// - 14: Delay termination
/// - 15: Delay distributed DAQ
/// - 16: Distributed DAQ
/// - 17: Repeat Sets
/// - 18: Scaling zero
/// - 19: Indexing
/// - 20: Locked indexing
/// - 21: Repeated Acquisition
/// - 22: Random Repeated Acquisition
Function/Wave GetSweepSettingsKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBSettKeyFolder(panelTitle)
	variable versionOfNewWave = 6

	Wave/Z/T/SDFR=dfr wv = sweepSettingsKeyWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 23) wv
	else
		Make/T/N=(3, 23) dfr:sweepSettingsKeyWave/Wave=wv
	endif

	wv = ""

	SetDimLabel 0, 0, Parameter, wv
	SetDimLabel 0, 1, Units, wv
	SetDimLabel 0, 2, Tolerance, wv

	wv[%Parameter][0] = "Stim Scale Factor"
	wv[%Units][0]     = ""
	wv[%Tolerance][0] = ".0001"

	wv[%Parameter][1] = "DAC"
	wv[%Units][1]     = ""
	wv[%Tolerance][1] = ".0001"

	wv[%Parameter][2] = "ADC"
	wv[%Units][2]     = ""
	wv[%Tolerance][2] = ".0001"

	wv[%Parameter][3] = "DA Gain"
	wv[%Units][3]     = ""
	wv[%Tolerance][3] = ".000001"

	wv[%Parameter][4] = "AD Gain"
	wv[%Units][4]     = ""
	wv[%Tolerance][4] = ".000001"

	wv[%Parameter][5] = "Set Sweep Count"
	wv[%Units][5]     = ""
	wv[%Tolerance][5] = ".0001"
	
	wv[%Parameter][6] = "TP Insert Checkbox"
	wv[%Units][6]     = "On/Off"
	wv[%Tolerance][6] = "-"

	wv[%Parameter][7] = "Inter-trial interval"
	wv[%Units][7]     = "s"
	wv[%Tolerance][7] = "0.01"

	wv[%Parameter][8] = "TTL rack zero bits"
	wv[%Units][8]     = "bit mask"
	wv[%Tolerance][8] = "-"

	wv[%Parameter][9] = "TTL rack one bits"
	wv[%Units][9]     = "bit mask"
	wv[%Tolerance][9] = "-"

	wv[%Parameter][10] = "TTL rack zero channel"
	wv[%Units][10]     = ""
	wv[%Tolerance][10] = "-"

	wv[%Parameter][11] = "TTL rack one channel"
	wv[%Units][11]     = ""
	wv[%Tolerance][11] = "-"

	wv[%Parameter][12] = "Delay onset user"
	wv[%Units][12]     = "ms"
	wv[%Tolerance][12] = "1"

	wv[%Parameter][13] = "Delay onset auto"
	wv[%Units][13]     = "ms"
	wv[%Tolerance][13] = "1"

	wv[%Parameter][14] = "Delay termination"
	wv[%Units][14]     = "ms"
	wv[%Tolerance][14] = "1"

	wv[%Parameter][15] = "Delay distributed DAQ"
	wv[%Units][15]     = "ms"
	wv[%Tolerance][15] = "1"

	wv[%Parameter][16] = "Distributed DAQ"
	wv[%Units][16]     = "On/Off"
	wv[%Tolerance][16] = "-"

	wv[%Parameter][17] = "Repeat Sets"
	wv[%Units][17]     = "On/Off"
	wv[%Tolerance][17] = "-"

	wv[%Parameter][18] = "Scaling zero"
	wv[%Units][18]     = "On/Off"
	wv[%Tolerance][18] = "-"

	wv[%Parameter][19] = "Indexing"
	wv[%Units][19]     = "On/Off"
	wv[%Tolerance][19] = "-"

	wv[%Parameter][20] = "Locked indexing"
	wv[%Units][20]     = "On/Off"
	wv[%Tolerance][20] = "-"

	wv[%Parameter][21] = "Repeated Acquisition"
	wv[%Units][21]     = "On/Off"
	wv[%Tolerance][21] = "-"

	wv[%Parameter][22] = "Random Repeated Acquisition"
	wv[%Units][22]     = "On/Off"
	wv[%Tolerance][22] = "-"

	SetDimLabel COLS, 0 , $"Stim Scale Factor"          , wv
	SetDimLabel COLS, 1 , $"DAC"                        , wv
	SetDimLabel COLS, 2 , $"ADC"                        , wv
	SetDimLabel COLS, 3 , $"DA Gain"                    , wv
	SetDimLabel COLS, 4 , $"AD Gain"                    , wv
	SetDimLabel COLS, 5 , $"Set Sweep Count"            , wv
	SetDimLabel COLS, 6 , $"TP Insert Checkbox"         , wv
	SetDimLabel COLS, 7 , $"Inter-trial interval"       , wv
	SetDimLabel COLS, 8 , $"TTL rack zero bits"         , wv
	SetDimLabel COLS, 9 , $"TTL rack one bits"          , wv
	SetDimLabel COLS, 10, $"TTL rack zero channel"      , wv
	SetDimLabel COLS, 11, $"TTL rack one channel"       , wv
	SetDimLabel COLS, 12, $"Delay onset user"           , wv
	SetDimLabel COLS, 13, $"Delay onset auto"           , wv
	SetDimLabel COLS, 14, $"Delay termination"          , wv
	SetDimLabel COLS, 15, $"Delay distributed DAQ"      , wv
	SetDimLabel COLS, 16, $"Distributed DAQ"            , wv
	SetDimLabel COLS, 17, $"Repeat Sets"                , wv
	SetDimLabel COLS, 18, $"Scaling zero"               , wv
	SetDimLabel COLS, 19, $"Indexing"                   , wv
	SetDimLabel COLS, 20, $"Locked indexing"            , wv
	SetDimLabel COLS, 21, $"Repeated Acquisition"       , wv
	SetDimLabel COLS, 22, $"Random Repeated Acquisition", wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns a wave reference to SweepSettingsTxtData
///
/// SweepSettingsTxtData is passed to ED_createTextNotes to add entries to the labnotebook.
///
/// Rows:
/// - Only one
///
/// Columns:
/// - Same as #GetSweepSettingsTextKeyWave
///
/// Layers:
/// - 0-7: data for a particular headstage using the layer index
/// - 8: headstage independent data
Function/Wave GetSweepSettingsTextWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTextDocFolder(panelTitle)
	variable versionOfNewWave = 7

	Wave/Z/T/SDFR=dfr wv = SweepSettingsTxtData

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 10, LABNOTEBOOK_LAYER_COUNT) wv
	else
		Make/T/N=(1, 10, LABNOTEBOOK_LAYER_COUNT) dfr:SweepSettingsTxtData/Wave=wv
	endif

	wv = ""

	SetDimLabel COLS, 0, $STIM_WAVE_NAME_KEY        , wv
	SetDimLabel COLS, 1, $"DA unit"                 , wv
	SetDimLabel COLS, 2, $"AD unit"                 , wv
	SetDimLabel COLS, 3, $"TTL rack zero stim sets" , wv
	SetDimLabel COLS, 4, $"TTL rack one stim sets"  , wv
	SetDimLabel COLS, 5, $"Pre DAQ function"        , wv
	SetDimLabel COLS, 6, $"Mid sweep function"      , wv
	SetDimLabel COLS, 7, $"Post sweep function"     , wv
	SetDimLabel COLS, 8, $"Post set function"       , wv
	SetDimLabel COLS, 9, $"Post DAQ function"       , wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns a wave reference to the SweepSettingsKeyTxtData
///
/// SweepSettingsKeyTxtData is used to index SweepSettingsTxtData.
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: Stim set
/// - 1: DA unit
/// - 2: AD unit
/// - 3: TTL rack zero stim sets
/// - 4: TTL rack one stim sets
/// - 5: Analysis function pre daq
/// - 6: Analysis function mid sweep
/// - 7: Analysis function post sweep
/// - 8: Analysis function post set
/// - 9: Analysis function post daq
Function/Wave GetSweepSettingsTextKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTxtDocKeyFolder(panelTitle)
	variable versionOfNewWave = 7

	Wave/Z/T/SDFR=dfr wv = SweepSettingsKeyTxtData

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 10, 0) wv
	else
		Make/T/N=(1, 10) dfr:SweepSettingsKeyTxtData/Wave=wv
	endif

	wv = ""

	wv[0][0] = STIM_WAVE_NAME_KEY
	wv[0][1] = "DA unit"
	wv[0][2] = "AD unit"
	wv[0][3] = "TTL rack zero stim sets"
	wv[0][4] = "TTL rack one stim sets"
	wv[0][5] = "Pre DAQ function"
	wv[0][6] = "Mid sweep function"
	wv[0][7] = "Post sweep function"
	wv[0][8] = "Post set function"
	wv[0][9] = "Post DAQ function"

	SetDimLabel COLS, 0, $STIM_WAVE_NAME_KEY        , wv
	SetDimLabel COLS, 1, $"DA unit"                 , wv
	SetDimLabel COLS, 2, $"AD unit"                 , wv
	SetDimLabel COLS, 3, $"TTL rack zero stim sets" , wv
	SetDimLabel COLS, 4, $"TTL rack one stim sets"  , wv
	SetDimLabel COLS, 5, $"Pre DAQ function"        , wv
	SetDimLabel COLS, 6, $"Mid sweep function"      , wv
	SetDimLabel COLS, 7, $"Post sweep function"     , wv
	SetDimLabel COLS, 8, $"Post set function"       , wv
	SetDimLabel COLS, 9, $"Post DAQ function"       , wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End
/// @}

/// @name Test Pulse
/// @{

/// @brief Return a wave reference for TPStorage
///
/// The wave stores TP resistance and Vm data as
/// function of time while the TP is running.
Function/Wave GetTPStorage(panelTitle)
	string 	panelTitle

	dfref dfr = GetDeviceTestPulse(panelTitle)
	variable versionOfNewWave = 3

	Wave/Z/SDFR=dfr wv = TPStorage

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, -1, 12) wv
	else
		Make/N=(128, NUM_AD_CHANNELS, 12) dfr:TPStorage/Wave=wv
	endif

	wv = NaN

	SetDimLabel COLS,  -1,  ADChannel                 , wv

	SetDimLabel LAYERS, 0,  Vm                        , wv
	SetDimLabel LAYERS, 1,  PeakResistance            , wv
	SetDimLabel LAYERS, 2,  SteadyStateResistance     , wv
	SetDimLabel LAYERS, 3,  TimeInSeconds             , wv
	SetDimLabel LAYERS, 4,  DeltaTimeInSeconds        , wv
	SetDimLabel LAYERS, 5,  Vm_Slope                  , wv
	SetDimLabel LAYERS, 6,  Rpeak_Slope               , wv
	SetDimLabel LAYERS, 7,  Rss_Slope                 , wv
	SetDimLabel LAYERS, 8,  Pressure                  , wv
	SetDimLabel LAYERS, 9,  TimeStamp                 , wv
	SetDimLabel LAYERS, 10, TimeStampSinceIgorEpochUTC, wv
	SetDimLabel LAYERS, 11, PressureChange            , wv

	Note wv, TP_CYLCE_COUNT_KEY + ":0;"
	Note/NOCR wv, AUTOBIAS_LAST_INVOCATION_KEY + ":0;"
	Note/NOCR wv, DIMENSION_SCALING_LAST_INVOC + ":0;"

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a datafolder reference to the test pulse folder
Function/DF GetDeviceTestPulse(panelTitle)
	string panelTitle
	return createDFWithAllParents(GetDeviceTestPulseAsString(panelTitle))
End

/// @brief Return the path to the test pulse folder, e.g. root:mies:ITCDevices:ITC1600:Device0:TestPulse
Function/S GetDeviceTestPulseAsString(panelTitle)
	string panelTitle
	return GetDevicePathAsString(panelTitle) + ":TestPulse"
End

/// @brief Return a wave for displaying scaled data in the oscilloscope window
Function/Wave GetOscilloscopeWave(panelTitle)
	string 	panelTitle

	dfref dfr = GetDevicePath(panelTitle)
	WAVE/Z/SDFR=dfr wv = OscilloscopeData

	if(WaveExists(wv))
		return wv
	endif

	Make/R/N=(1, NUM_DA_TTL_CHANNELS) dfr:OscilloscopeData/Wave=wv

	return wv
End

/// @brief Return the testpulse instantenous resistance wave
///
/// The columns hold the *active* DA channels only and are subject to resizing.
Function/Wave GetInstResistanceWave(panelTitle)
	string 	panelTitle

	dfref dfr = GetDeviceTestPulse(panelTitle)
	WAVE/Z/SDFR=dfr wv = InstResistance

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(1, NUM_DA_TTL_CHANNELS) dfr:InstResistance/Wave=wv

	return wv
End

/// @brief Return the testpulse steady state resistance wave
///
/// The columns hold the *active* DA channels only and are subject to resizing.
Function/Wave GetSSResistanceWave(panelTitle)
	string 	panelTitle

	dfref dfr = GetDeviceTestPulse(panelTitle)
	WAVE/Z/SDFR=dfr wv = SSResistance

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(1, NUM_DA_TTL_CHANNELS) dfr:SSResistance/Wave=wv

	return wv
End

/// @}

/// @name Amplifier
/// @{

/// @brief Return the datafolder reference to the amplifier
Function/DF GetAmplifierFolder()
	return createDFWithAllParents(GetAmplifierFolderAsString())
End

/// @brief Return the path to the amplifierm e.g. root:mies:Amplifiers"
Function/S GetAmplifierFolderAsString()
	return GetMiesPathAsString() + ":Amplifiers"
End

/// @brief Return the datafolder reference to the amplifier settings
Function/DF GetAmpSettingsFolder()
	return createDFWithAllParents(GetAmpSettingsFolderAsString())
End

/// @brief Return the path to the amplifier settings, e.g. root:MIES:Amplifiers:Settings
Function/S GetAmpSettingsFolderAsString()
	return GetAmplifierFolderAsString() + ":Settings"
End

/// @brief Return a wave reference to the amplifier parameter storage wave
///
/// Rows:
/// - 0-31: Amplifier settings identified by dimension labels
///
/// Columns:
/// - Only one
///
/// Layers:
/// - 0-7: Headstage identifier
///
/// Contents:
/// - numerical amplifier settings
Function/Wave GetAmplifierParamStorageWave(panelTitle)
	string panelTitle

	variable versionOfNewWave = 4

	DFREF dfr = GetAmpSettingsFolder()

	// wave's name is like ITC18USB_Dev_0
	Wave/Z/SDFR=dfr wv = $panelTitle

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// nothing to do
	else
		Make/N=(31, 1, NUM_HEADSTAGES) dfr:$panelTitle/Wave=wv
	endif

	SetDimLabel LAYERS, -1, Headstage             , wv
	SetDimLabel ROWS  , 0 , HoldingPotential      , wv
	SetDimLabel ROWS  , 1 , HoldingPotentialEnable, wv
	SetDimLabel ROWS  , 2 , WholeCellCap          , wv
	SetDimLabel ROWS  , 3 , WholeCellRes          , wv
	SetDimLabel ROWS  , 4 , WholeCellEnable       , wv
	SetDimLabel ROWS  , 5 , Correction            , wv
	SetDimLabel ROWS  , 6 , Prediction            , wv
	SetDimLabel ROWS  , 7 , RsCompEnable          , wv
	SetDimLabel ROWS  , 8 , PipetteOffsetVC       , wv
	SetDimLabel ROWS  , 9 , FastCapacitanceComp   , wv
	SetDimLabel ROWS  , 10, SlowCapacitanceComp   , wv
	SetDimLabel ROWS  , 11, RSCompChaining        , wv
	SetDimLabel ROWS  , 12, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 13, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 14, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 15, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 16, BiasCurrent           , wv
	SetDimLabel ROWS  , 17, BiasCurrentEnable     , wv
	SetDimLabel ROWS  , 18, BridgeBalance         , wv
	SetDimLabel ROWS  , 19, BridgeBalanceEnable   , wv
	SetDimLabel ROWS  , 20, CapNeut               , wv
	SetDimLabel ROWS  , 21, CapNeutEnable         , wv
	SetDimLabel ROWS  , 22, AutoBiasVcom          , wv
	SetDimLabel ROWS  , 23, AutoBiasVcomVariance  , wv
	SetDimLabel ROWS  , 24, AutoBiasIbiasmax      , wv
	SetDimLabel ROWS  , 25, AutoBiasEnable        , wv
	SetDimLabel ROWS  , 26, PipetteOffsetIC       , wv
	SetDimLabel ROWS  , 27, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 28, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 29, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 30, IclampPlaceHolder     , wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns wave reference for the amplifier settings
///
/// Rows:
/// - Only one
///
/// Columns:
/// - Amplifier parameters as described in the amplifier settings key wave
///
/// Layers:
/// - 0-7: data for a particular headstage using the layer index
/// - 8: headstage independent data
Function/WAVE GetAmplifierSettingsWave(panelTitle)
	string panelTitle

	variable versionOfNewWave = 5
	dfref dfr = GetAmpSettingsFolder()

	Wave/Z/SDFR=dfr wv = ampSettings

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 43, LABNOTEBOOK_LAYER_COUNT) wv
	else
		Make/N=(1, 43, LABNOTEBOOK_LAYER_COUNT) dfr:ampsettings/Wave=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns wave reference for the amplifier settings keys
///
/// Rows:
/// - 0: Parameter
/// - 1: Units
/// - 2: Tolerance factor
///
/// Columns:
/// - Various settings
Function/WAVE GetAmplifierSettingsKeyWave(panelTitle)
	string panelTitle

	variable versionOfNewWave = 3
	dfref dfr = GetAmpSettingsFolder()

	Wave/T/Z/SDFR=dfr wv = ampSettingsKey

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 43) wv
	else
		Make/T/N=(3, 43) dfr:ampSettingsKey/Wave=wv
	endif

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units    , wv
	SetDimLabel ROWS, 2, Tolerance, wv

	wv[0][0] = "V-Clamp Holding Enable"
	wv[1][0] = "On/Off"
	wv[2][0] = "-"

	wv[0][1] =  "V-Clamp Holding Level"
	wv[1][1] = "mV"
	wv[2][1] = "0.9"

	wv[0][2] =  "Osc Killer Enable"
	wv[1][2] =  "On/Off"
	wv[2][2] =  "-"

	wv[0][3] =  "RsComp Bandwidth"
	wv[1][3] =  "Hz"
	wv[2][3] =  "0.9"

	wv[0][4] =  "RsComp Correction"
	wv[1][4] =  "%"
	wv[2][4] =  "0.9"

	wv[0][5] =  "RsComp Enable"
	wv[1][5] =  "On/Off"
	wv[2][5] =  "-"

	wv[0][6] =  "RsComp Prediction"
	wv[1][6] =  "%"
	wv[2][6] =  "0.9"

	wv[0][7] =  "Whole Cell Comp Enable"
	wv[1][7] =  "On/Off"
	wv[2][7] =  "-"

	wv[0][8] =  "Whole Cell Comp Cap"
	wv[1][8] =  "pF"
	wv[2][8] =  "0.9"

	wv[0][9] =  "Whole Cell Comp Resist"
	wv[1][9] =  "MOhm"
	wv[2][9] =  "0.9"

	wv[0][10] =  "I-Clamp Holding Enable"
	wv[1][10] =  "On/Off"
	wv[2][10] =  "-"

	wv[0][11] =  "I-Clamp Holding Level"
	wv[1][11] =  "pA"
	wv[2][11] =  "0.9"

	wv[0][12] =  "Neut Cap Enabled"
	wv[1][12] =  "On/Off"
	wv[2][12] =  "-"

	wv[0][13] =  "Neut Cap Value"
	wv[1][13] =  "pF"
	wv[2][13] =  "0.9"

	wv[0][14] =  "Bridge Bal Enable"
	wv[1][14] =  "On/Off"
	wv[2][14] =  "-"

	wv[0][15] =  "Bridge Bal Value"
	wv[1][15] =  "MOhm"
	wv[2][15] =  "0.9"

	// and now add the Axon values to the amp settings key
	wv[0][16] =  "Serial Number"
	wv[1][16] =  ""
	wv[2][16] =  ""

	wv[0][17] =  "Channel ID"
	wv[1][17] =  ""
	wv[2][17] =  ""

	wv[0][18] =  "ComPort ID"
	wv[1][18] =  ""
	wv[2][18] =  ""

	wv[0][19] =  "AxoBus ID"
	wv[1][19] =  ""
	wv[2][19] =  ""

	wv[0][20] =  "Operating Mode"
	wv[1][20] =  ""
	wv[2][20] =  ""

	wv[0][21] =  "Scaled Out Signal"
	wv[1][21] =  ""
	wv[2][21] =  ""

	wv[0][22] =  "Alpha"
	wv[1][22] =  ""
	wv[2][22] =  ""

	wv[0][23] =  "Scale Factor"
	wv[1][23] =  ""
	wv[2][23] =  ""

	wv[0][24] =  "Scale Factor Units"
	wv[1][24] =  ""
	wv[2][24] =  ""

	wv[0][25] =  "LPF Cutoff"
	wv[1][25] =  ""
	wv[2][25] =  ""

	wv[0][26] =  "Membrane Cap"
	wv[1][26] =  "pF"
	wv[2][26] =  "0.9"

	wv[0][27] =  "Ext Cmd Sens"
	wv[1][27] =  ""
	wv[2][27] =  ""

	wv[0][28] =  "Raw Out Signal"
	wv[1][28] =  ""
	wv[2][28] =  ""

	wv[0][29] =  "Raw Scale Factor"
	wv[1][29] =  ""
	wv[2][29] =  ""

	wv[0][30] =  "Raw Scale Factor Units"
	wv[1][30] =  ""
	wv[2][30] =  ""

	wv[0][31] =  "Hardware Type"
	wv[1][31] =  ""
	wv[2][31] =  ""

	wv[0][32] =  "Secondary Alpha"
	wv[1][32] =  ""
	wv[2][32] =  ""

	wv[0][33] =  "Secondary LPF Cutoff"
	wv[1][33] =  ""
	wv[2][33] =  ""

	wv[0][34] =  "Series Resistance"
	wv[1][34] =  "MOhms"
	wv[2][34] =  "0.9"

	// new keys starting from 29a161c
	wv[0][35] =  "Pipette Offset"
	wv[1][35] =  "mV"
	wv[2][35] =  ""

	wv[0][36] =  "Slow current injection"
	wv[1][36] =  "On/Off"
	wv[2][36] =  "-"

	wv[0][37] =  "Slow current injection level"
	wv[1][37] =  "V"
	wv[2][37] =  ""

	wv[0][38] =  "Slow current injection settling time"
	wv[1][38] =  "s"
	wv[2][38] =  ""

	wv[0][39] =  "Fast compensation capacitance"
	wv[1][39] =  "F"
	wv[2][39] =  ""

	wv[0][40] =  "Slow compensation capacitance"
	wv[1][40] =  "F"
	wv[2][40] =  ""

	wv[0][41] =  "Fast compensation time"
	wv[1][41] =  "s"
	wv[2][41] =  ""

	wv[0][42] =  "Slow compensation time"
	wv[1][42] =  "s"
	wv[2][42] =  ""

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns wave reference for the amplifier settings (text version)
///
/// Rows:
/// - Only one
///
/// Columns:
/// - Amplifier parameters as described in the amplifier settings text key wave
///
/// Layers:
/// - 0-7: data for a particular headstage using the layer index
/// - 8: headstage independent data
Function/WAVE GetAmplifierSettingsTextWave(panelTitle)
	string panelTitle

	dfref dfr = GetAmpSettingsFolder()
	variable versionOfNewWave = 2

	Wave/T/Z/SDFR=dfr wv = ampSettingsText

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 6, LABNOTEBOOK_LAYER_COUNT) wv
	else
		Make/T/N=(1, 6, LABNOTEBOOK_LAYER_COUNT) dfr:ampSettingsText/Wave=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns wave reference for the amplifier settings keys (text version)
///
/// Rows:
/// - 0: Parameter
/// - 1: Units
/// - 2: Tolerance factor
///
/// Columns:
/// - Various settings
Function/WAVE GetAmplifierSettingsTextKeyWave(panelTitle)
	string panelTitle

	dfref dfr = GetAmpSettingsFolder()
	variable versionOfNewWave = 1

	Wave/T/Z/SDFR=dfr wv = ampSettingsTextKey

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 6) wv
	else
		Make/T/N=(3, 6) dfr:ampSettingsTextKey/Wave=wv
	endif

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units    , wv
	SetDimLabel ROWS, 2, Tolerance, wv

	wv[0][0] = "OperatingModeString"
	wv[1][0] = ""
	wv[2][0] = "-"

	wv[0][1] = "ScaledOutSignalString"
	wv[1][1] = ""
	wv[2][1] = "-"

	wv[0][2] = "ScaleFactorUnitsString"
	wv[1][2] = ""
	wv[2][2] = "-"

	wv[0][3] = "RawOutSignalString"
	wv[1][3] = ""
	wv[2][3] = "-"

	wv[0][4] = "RawScaleFactorUnitsString"
	wv[1][4] = ""
	wv[2][4] = "-"

	wv[0][5] = "HardwareTypeString"
	wv[1][5] = ""
	wv[2][5] = "-"

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return wave reference to the `W_TelegraphServers` wave
///
/// Call AI_FindConnectedAmps() to create that wave, otherwise an empty wave is
/// returned.
Function/Wave GetAmplifierTelegraphServers()

	DFREF dfr = GetAmplifierFolder()

	WAVE/I/Z/SDFR=dfr wv = W_TelegraphServers

	if(WaveExists(wv))
		return wv
	else
		Make/I/N=(0) dfr:W_TelegraphServers/Wave=wv
	endif

	return wv
End

/// @brief Return wave reference to the `W_MultiClamps` wave
///
/// Call AI_FindConnectedAmps() to create that wave, if that was not done an
/// empty wave is returned.
Function/Wave GetAmplifierMultiClamps()

	DFREF dfr = GetAmplifierFolder()

	WAVE/I/Z/SDFR=dfr wv = W_MultiClamps

	if(WaveExists(wv))
		return wv
	else
		Make/I/N=(0) dfr:W_MultiClamps/Wave=wv
	endif

	return wv
End
/// @}

/// @name Wavebuilder
/// @{

/// @brief Returns a data folder reference to the base
Function/DF GetWaveBuilderPath()
	return createDFWithAllParents(GetWaveBuilderPathAsString())
End

/// @brief Returns the full path to the base path, e.g. root:MIES:WaveBuilder
Function/S GetWaveBuilderPathAsString()
	return GetMiesPathAsString() + ":WaveBuilder"
End

/// @brief Returns a data folder reference to the data
Function/DF GetWaveBuilderDataPath()
	return createDFWithAllParents(GetWaveBuilderDataPathAsString())
End

///	@brief Returns the full path to the data folder, e.g root:MIES:WaveBuilder:Data
Function/S GetWaveBuilderDataPathAsString()
	return GetWaveBuilderPathAsString() + ":Data"
End

/// @brief Returns a data folder reference to the stimulus set parameter
Function/DF GetWBSvdStimSetParamPath()
	return createDFWithAllParents(GetWBSvdStimSetParamPathAS())
End

///	@brief Returns the full path to the stimulus set parameter folder, e.g. root:MIES:WaveBuilder:SavedStimulusSetParameters
Function/S GetWBSvdStimSetParamPathAS()
	return GetWaveBuilderPathAsString() + ":SavedStimulusSetParameters"
End

/// @brief Returns a data folder reference to the stimulus set
Function/DF GetWBSvdStimSetPath()
	return createDFWithAllParents(GetWBSvdStimSetPathAsString())
End

///	@brief Returns the full path to the stimulus set, e.g. root:MIES:WaveBuilder:SavedStimulusSets
Function/S GetWBSvdStimSetPathAsString()
	return GetWaveBuilderPathAsString() + ":SavedStimulusSets"
End

/// @brief Returns a data folder reference to the stimulus set parameters of `DA` type
Function/DF GetWBSvdStimSetParamDAPath()
	return createDFWithAllParents(GetWBSvdStimSetParamDAPathAS())
End

///	@brief Returns the full path to the stimulus set parameters of `DA` type, e.g. root:MIES:WaveBuilder:SavedStimulusSetParameters:DA
Function/S GetWBSvdStimSetParamDAPathAS()
	return GetWBSvdStimSetParamPathAS() + ":DA"
End

/// @brief Returns a data folder reference to the stimulus set parameters of `TTL` type
Function/DF GetWBSvdStimSetParamTTLPath()
	return createDFWithAllParents(GetWBSvdStimSetParamTTLAsString())
End

///	@brief Returns the full path to the stimulus set parameters of `TTL` type, e.g. root:MIES:WaveBuilder:SavedStimulusSetParameters:TTL
Function/S GetWBSvdStimSetParamTTLAsString()
	return GetWBSvdStimSetParamPathAS() + ":TTL"
End

/// @brief Returns a data folder reference to the stimulus set of `DA` type
Function/DF GetWBSvdStimSetDAPath()
	return createDFWithAllParents(GetWBSvdStimSetDAPathAsString())
End

///	@brief Returns the full path to the stimulus set of `DA` type, e.g. root:MIES:WaveBuilder:SavedStimulusSet:DA
Function/S GetWBSvdStimSetDAPathAsString()
	return GetWBSvdStimSetPathAsString() + ":DA"
End

/// @brief Returns a data folder reference to the stimulus set of `TTL` type
Function/DF GetWBSvdStimSetTTLPath()
	return createDFWithAllParents(GetWBSvdStimSetTTLPathAsString())
End

///	@brief Returns the full path to the stimulus set of `TTL` type, e.g. root:MIES:WaveBuilder:SavedStimulusSet:TTL
Function/S GetWBSvdStimSetTTLPathAsString()
	return GetWBSvdStimSetPathAsString() + ":TTL"
End

/// @brief Return the testpulse stimulus set
Function/WAVE GetTestPulse()

	dfref dfr = GetWBSvdStimSetDAPath()
	WAVE/Z/SDFR=dfr wv = TestPulse

	if(WaveExists(wv))
		return wv
	endif

	/// create dummy wave
	Make/N=(0) dfr:TestPulse/Wave=wv
	SetScale/P x 0, HARDWARE_ITC_MIN_SAMPINT, "ms", wv

	return wv
End

static Constant WP_WAVE_LAYOUT_VERSION = 4

/// @brief Upgrade the wave layout of `WP` to the most recent one
///        as defined in `WP_WAVE_LAYOUT_VERSION`
Function UpgradeWaveParam(wv)
	WAVE wv

	if(ExistsWithCorrectLayoutVersion(wv, WP_WAVE_LAYOUT_VERSION))
		return NaN
	endif

	Redimension/N=(61, -1, 9) wv
	AddDimLabelsToWP(wv)
	SetWaveVersion(wv, WP_WAVE_LAYOUT_VERSION)
End

static Function AddDimLabelsToWP(wv)
	WAVE wv

	variable i, numCols

	SetDimLabel COLS,   -1, $("Epoch number"), wv

	numCols = DimSize(wv, COLS)
	for(i = 0; i < numCols; i += 1)
		SetDimLabel COLS, i, $("Epoch " + num2str(i)), wv
	endfor

	SetDimLabel LAYERS, -1, $("Epoch type")        , wv
	SetDimLabel LAYERS,  0, $("Square pulse")      , wv
	SetDimLabel LAYERS,  1, $("Ramp")              , wv
	SetDimLabel LAYERS,  2, $("GPB-Noise")         , wv
	SetDimLabel LAYERS,  3, $("Sin")               , wv
	SetDimLabel LAYERS,  4, $("Saw tooth")         , wv
	SetDimLabel LAYERS,  5, $("Square pulse train"), wv
	SetDimLabel LAYERS,  6, $("PSC")               , wv
	SetDimLabel LAYERS,  7, $("Load custom wave")  , wv
	SetDimLabel LAYERS,  8, $("Combine")           , wv

	SetDimLabel ROWS, -1, $("Property")                       , wv
	SetDimLabel ROWS, 0 , $("Duration")                       , wv
	SetDimLabel ROWS, 1 , $("Duration step delta")            , wv
	SetDimLabel ROWS, 2 , $("Amplitude")                      , wv
	SetDimLabel ROWS, 3 , $("Amplitude delta")                , wv
	SetDimLabel ROWS, 4 , $("Offset")                         , wv
	SetDimLabel ROWS, 5 , $("Offset delta")                   , wv
	SetDimLabel ROWS, 6 , $("Sin/chirp/saw tooth frequency")  , wv
	SetDimLabel ROWS, 7 , $("Sin/chirp/saw frequency delta")  , wv
	SetDimLabel ROWS, 8 , $("Square pulse duration")          , wv
	SetDimLabel ROWS, 9 , $("Square pulse duration delta")    , wv
	SetDimLabel ROWS, 10, $("PSC exp rise time")              , wv
	SetDimLabel ROWS, 11, $("PSC exp rise time delta")        , wv
	SetDimLabel ROWS, 12, $("PSC exp decay time 1/2")         , wv
	SetDimLabel ROWS, 13, $("PSC exp decay time 1/2 delta")   , wv
	SetDimLabel ROWS, 14, $("PSC exp decay time 2/2")         , wv
	SetDimLabel ROWS, 15, $("PSC exp decay time 2/2 delta")   , wv
	SetDimLabel ROWS, 16, $("PSC ratio decay times")          , wv
	SetDimLabel ROWS, 17, $("PSC ratio decay times delta")    , wv
	SetDimLabel ROWS, 18, $("Custom epoch offset")            , wv
	SetDimLabel ROWS, 19, $("Custom epoch offset delta")      , wv
	SetDimLabel ROWS, 20, $("Low pass filter cut off")        , wv
	SetDimLabel ROWS, 21, $("Low pass filter cut off delta")  , wv
	SetDimLabel ROWS, 22, $("High pass filter cut off")       , wv
	SetDimLabel ROWS, 23, $("High pass filter cut off delta") , wv
	SetDimLabel ROWS, 24, $("Chirp end frequency")            , wv
	SetDimLabel ROWS, 25, $("Chirp end frequency delta")      , wv
	SetDimLabel ROWS, 26, $("High pass filter coef num")      , wv
	SetDimLabel ROWS, 27, $("High pass filter coef num delta"), wv
	SetDimLabel ROWS, 28, $("Low pass filter coef")           , wv
	SetDimLabel ROWS, 29, $("Low pass filter coef delta")     , wv
	// unused entries are not labeled
	SetDimLabel ROWS, 40, $("Delta type")                     , wv
	SetDimLabel ROWS, 41, $("Pink noise amplitude")           , wv
	SetDimLabel ROWS, 42, $("Brown noise amplitude")          , wv
	SetDimLabel ROWS, 43, $("Chirp type: Log or sin")         , wv
	SetDimLabel ROWS, 44, $("Poisson distribution true/false"), wv
	SetDimLabel ROWS, 45, $("Number of pulses")               , wv
	SetDimLabel ROWS, 46, $("Duration type: User/Automatic")  , wv
	SetDimLabel ROWS, 47, $("Number of pulses delta")         , wv
	// P48 is a button
	SetDimLabel ROWS, 49, $("Reseed RNG for each step")       , wv
	SetDimLabel ROWS, 50, $("Amplitude delta mult/exp")       , wv
	SetDimLabel ROWS, 51, $("Offset delta mult/exp")          , wv
	SetDimLabel ROWS, 52, $("Duration delta mult/exp")        , wv
	SetDimLabel ROWS, 53, $("Trigonometric function Sin/Cos") , wv
End

/// @brief Return the parameter wave for the wave builder panel
///
/// Rows:
/// - Variables synced to GUI controls, see e.g. WB_MakeWaveBuilderWave in MIES_WaveBuilder for an up to date list
///
/// Columns:
/// - Segment/Epoch
///
/// Layers hold different stimulus wave form types:
/// - Square pulse
/// - Ramp
/// - GPB-Noise
/// - Sin
/// - Saw tooth
/// - Square pulse train
/// - PSC
/// - Load custom wave
/// - Combine
Function/WAVE GetWaveBuilderWaveParam()

	dfref dfr = GetWaveBuilderDataPath()
	WAVE/Z/SDFR=dfr wv = WP

	if(WaveExists(wv))
		UpgradeWaveParam(wv)
	else
		Make/N=(61, 100, 9) dfr:WP/Wave=wv

		// sets low pass filter to off (off value is related to sampling frequency)
		wv[20][][2] = 10001
		// sets coefficent count for low pass filter to a reasonable and legal Number
		wv[26][][2] = 500
		// sets coefficent count for high pass filter to a reasonable and legal Number
		wv[28][][2] = 500

		AddDimLabelsToWP(wv)
		SetWaveVersion(wv, WP_WAVE_LAYOUT_VERSION)
	endif

	return wv
End

static Constant WPT_WAVE_LAYOUT_VERSION = 4

/// @brief Upgrade the wave layout of `WPT` to the most recent one
///        as defined in `WPT_WAVE_LAYOUT_VERSION`
Function UpgradeWaveTextParam(wv)
	WAVE wv

	if(ExistsWithCorrectLayoutVersion(wv, WPT_WAVE_LAYOUT_VERSION))
		return NaN
	endif

	Redimension/N=(51, -1) wv
	AddDimLabelsToWPT(wv)
	SetWaveVersion(wv, WPT_WAVE_LAYOUT_VERSION)
End

/// @brief Add dimension labels to the WaveBuilder `WPT` wave
static Function AddDimLabelsToWPT(wv)
	WAVE wv

	variable i, numEpochs

	SetDimLabel ROWS, 0, $("Custom epoch wave name")       , wv
	SetDimLabel ROWS, 1, $("Analysis pre DAQ function")    , wv
	SetDimLabel ROWS, 2, $("Analysis mid sweep function")  , wv
	SetDimLabel ROWS, 3, $("Analysis post sweep function") , wv
	SetDimLabel ROWS, 4, $("Analysis post set function")   , wv
	SetDimLabel ROWS, 5, $("Analysis post DAQ function")   , wv
	SetDimLabel ROWS, 6, $("Combine epoch formula")        , wv
	SetDimLabel ROWS, 7, $("Combine epoch formula version"), wv

	numEpochs = DimSize(wv, COLS) - 1
	for(i = 0; i < numEpochs; i += 1)
		SetDimLabel COLS, i, $("Epoch " + num2str(i)), wv
	endfor

	SetDimLabel COLS, numEpochs, $("Set"), wv
End

/// @brief Return the parameter text wave for the wave builder panel
///
/// Rows:
/// - 0: name of the custom wave loaded
/// - 1: Analysis function, pre daq
/// - 2: Analysis function, mid sweep
/// - 3: Analysis function, post sweep
/// - 4: Analysis function, post set
/// - 5: Analysis function, post daq
/// - 6: Formula
/// - 7: Formula version: "[[:digit:]]+"
/// - 8-50: unused
///
/// Columns:
/// - Segment/Epoch, the very last index is reserved for
///   textual settings for the complete set
Function/WAVE GetWaveBuilderWaveTextParam()

	dfref dfr = GetWaveBuilderDataPath()
	WAVE/T/Z/SDFR=dfr wv = WPT

	if(WaveExists(wv))
		UpgradeWaveTextParam(wv)
	else
		Make/N=(51, 100)/T dfr:WPT/Wave=wv
		AddDimLabelsToWPT(wv)
		SetWaveVersion(wv, WPT_WAVE_LAYOUT_VERSION)
	endif

	return wv
End

static Constant SEGWVTYPE_WAVE_LAYOUT_VERSION = 4

/// @brief Upgrade the wave layout of `SegWvType` to the most recent one
///        as defined in `SEGWVTYPE_WAVE_LAYOUT_VERSION`
Function UpgradeSegWvType(wv)
	WAVE wv

	if(ExistsWithCorrectLayoutVersion(wv, SEGWVTYPE_WAVE_LAYOUT_VERSION))
		return NaN
	endif

	AddDimLabelsToSegWvType(wv)
	SetWaveVersion(wv, SEGWVTYPE_WAVE_LAYOUT_VERSION)
End

/// @brief Add dimension labels to the WaveBuilder `SegWvType` wave
static Function AddDimLabelsToSegWvType(wv)
	WAVE wv

	variable i

	for(i = 0; i <= SEGMENT_TYPE_WAVE_LAST_IDX; i += 1)
	 SetDimLabel ROWS, i, $("Type of Epoch " + num2str(i)), wv
	endfor

	SetDimLabel ROWS, SEGMENT_TYPE_WAVE_LAST_IDX + 1, $("Flip time axis")        , wv
	SetDimLabel ROWS, SEGMENT_TYPE_WAVE_LAST_IDX + 2, $("Inter trial interval")  , wv
	SetDimLabel ROWS, SEGMENT_TYPE_WAVE_LAST_IDX + 3, $("Total number of epochs"), wv
	SetDimLabel ROWS, SEGMENT_TYPE_WAVE_LAST_IDX + 4, $("Total number of steps") , wv
End

/// @brief Returns the segment type wave used by the wave builder panel
/// Remember to change #SEGMENT_TYPE_WAVE_LAST_IDX if changing the wave layout
/// - Rows
///   - 0 - 97: epoch types using the tabcontrol indizes
///   - 98: Data flipping (1 or 0)
///   - 99: set ITI (s)
///   - 100: total number of segments/epochs
///   - 101: total number of steps
Function/Wave GetSegmentTypeWave()

	DFREF dfr = GetWaveBuilderDataPath()
	WAVE/Z/SDFR=dfr wv = SegWvType

	if(WaveExists(wv))
		UpgradeSegWvType(wv)
	else
		Make/N=102 dfr:SegWvType/Wave=wv

		wv[100] = 1
		wv[101] = 1
		AddDimLabelsToSegWvType(wv)
		SetWaveVersion(wv, SEGWVTYPE_WAVE_LAYOUT_VERSION)
	endif

	return wv
End

/// @brief Return the wave identifiying the begin and
/// end times of the current epoch
Function/Wave GetEpochID()

	dfref dfr = GetWaveBuilderDataPath()

	WAVE/Z/SDFR=dfr wv = epochID

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(100, 2) dfr:epochID/Wave=wv

	SetDimLabel COLS, 0, timeBegin, wv
	SetDimLabel COLS, 1, timeEnd, wv

	return wv
End

/// @brief Return the wave for visualization of the stim set
/// in the wavebuilder panel
Function/Wave GetWaveBuilderDispWave()

	dfref dfr = GetWaveBuilderDataPath()
	WAVE/Z/SDFR=dfr wv = dispData

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(0) dfr:dispData/Wave=wv

	return wv
End

Function/WAVE GetWBEpochCombineList()

	DFREF dfr = GetWaveBuilderDataPath()
	WAVE/T/Z/SDFR=dfr wv = epochCombineList

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1, 2) dfr:epochCombineList/Wave=wv

	SetDimLabel 1, 0, Shorthand, wv
	SetDimLabel 1, 1, Stimset,   wv

	return wv
End
/// @}

/// @name Asynchronous Measurements
/// @}

/// @brief Returns a wave reference to the asyncMeasurementWave
///
/// asyncMeasurementWave is used to save the actual async measurement data
/// for each data sweep 
///
/// Rows:
/// - One row
///
/// - Columns:
/// - 0: Async Measurement 0
/// - 1: Async Measurement 1
/// - 2: Async Measurement 2
/// - 3: Async Measurement 3
/// - 4: Async Measurement 4
/// - 5: Async Measurement 5
/// - 6: Async Measurement 6
/// - 7: Async Measurement 7
///
/// Layers:
/// - Only one...all async measurements apply across all headstages, so no need to create multiple layers
Function/Wave GetAsyncMeasurementWave(panelTitle)
	string panelTitle

	DFREF dfr =GetDevSpecLabNBSettHistFolder(panelTitle)

	Wave/Z/SDFR=dfr wv = asyncMeasurementWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(1,8) dfr:asyncMeasurementWave/Wave=wv
	wv = Nan

	SetDimLabel 1, 0, MeasVal0, wv
	SetDimLabel 1, 1, MeasVal1, wv
	SetDimLabel 1, 2, MeasVal2, wv
	SetDimLabel 1, 3, MeasVal3, wv
	SetDimLabel 1, 4, MeasVal4, wv
	SetDimLabel 1, 5, MeasVal5, wv
	SetDimLabel 1, 6, MeasVal6, wv
	SetDimLabel 1, 7, MeasVal7, wv
	
	return wv
End

/// @brief Returns a wave reference to the asyncMeasurementKeyWave
///
/// asyncMeasurementKeyWave is used to index async measurements for
/// each data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
/// - 0: Parameter
/// - 1: Units
/// - 2: Tolerance Factor
///
/// Columns:
/// - 0: Async Measurement 0
/// - 1: Async Measurement 1
/// - 2: Async Measurement 2
/// - 3: Async Measurement 3
/// - 4: Async Measurement 4
/// - 5: Async Measurement 5
/// - 6: Async Measurement 6
/// - 7: Async Measurement 7
///
/// Layers:
/// - Just one
Function/Wave GetAsyncMeasurementKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBSettKeyFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = asyncMeasurementKeyWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(3,8) dfr:asyncMeasurementKeyWave/Wave=wv
	wv = ""

	SetDimLabel 0, 0, Parameter, wv
	SetDimLabel 0, 1, Units, wv
	SetDimLabel 0, 2, Tolerance, wv
	
	wv[%Parameter][0] = "Async AD 0"
	wv[%Units][0]     = ""
	wv[%Tolerance][0] = ".0001"

	wv[%Parameter][1] = "Async AD 1"
	wv[%Units][1]     = ""
	wv[%Tolerance][1] = ".0001"
	
	wv[%Parameter][2] = "Async AD 2"
	wv[%Units][2]     = ""
	wv[%Tolerance][2] = ".0001"
	
	wv[%Parameter][3] = "Async AD 3"
	wv[%Units][3]     = ""
	wv[%Tolerance][3] = ".0001"
	
	wv[%Parameter][4] = "Async AD 4"
	wv[%Units][4]     = ""
	wv[%Tolerance][4] = ".0001"

	wv[%Parameter][5] = "Async AD 5"
	wv[%Units][5]     = ""
	wv[%Tolerance][5] = ".0001"
	
	wv[%Parameter][6] = "Async AD 6"
	wv[%Units][6]     = ""
	wv[%Tolerance][6] = ".0001"
	
	wv[%Parameter][7] = "Async AD 7"
	wv[%Units][7]     = ""
	wv[%Tolerance][7] = ".0001"
	
	return wv
End

/// @brief Returns a wave reference to the asyncSettingsWave
///
/// asyncSettingsWave is used to save async settings for each
/// data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
///  - One row
///
/// Columns:
/// - 0: Async AD 0 OnOff
/// - 1: Async AD 1 OnOff
/// - 2: Async AD 2 OnOff
/// - 3: Async AD 3 OnOff
/// - 4: Async AD 4 OnOff
/// - 5: Async AD 5 OnOff
/// - 6: Async AD 6 OnOff
/// - 7: Async AD 7 OnOff
/// - 8: Async AD 0 Gain
/// - 9: Async AD 1 Gain
/// - 10: Async AD 2 Gain
/// - 11: Async AD 3 Gain
/// - 12: Async AD 4 Gain
/// - 13: Async AD 5 Gain
/// - 14: Async AD 6 Gain
/// - 15: Async AD 7 Gain
/// - 16: Async Alarm 0 OnOff
/// - 17: Async Alarm 1 OnOff
/// - 18: Async Alarm 2 OnOff
/// - 19: Async Alarm 3 OnOff
/// - 20: Async Alarm 4 OnOff
/// - 21: Async Alarm 5 OnOff
/// - 22: Async Alarm 6 OnOff
/// - 23: Async Alarm 7 OnOff
/// - 24: Async Alarm 0 Min
/// - 25: Async Alarm 1 Min
/// - 26: Async Alarm 2 Min
/// - 27: Async Alarm 3 Min
/// - 28: Async Alarm 4 Min
/// - 29: Async Alarm 5 Min
/// - 30: Async Alarm 6 Min
/// - 31: Async Alarm 7 Min
/// - 32: Async Alarm 0 Max
/// - 33: Async Alarm 1 Max
/// - 34: Async Alarm 2 Max
/// - 35: Async Alarm 3 Max
/// - 36: Async Alarm 4 Max
/// - 37: Async Alarm 5 Max
/// - 38: Async Alarm 6 Max
/// - 39: Async Alarm 7 Max
Function/Wave GetAsyncSettingsWave(panelTitle)
	string panelTitle

	DFREF dfr =GetDevSpecLabNBSettHistFolder(panelTitle)

	Wave/Z/SDFR=dfr wv = asyncSettingsWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(1,40) dfr:asyncSettingsWave/Wave=wv
	wv = Nan
	
	SetDimLabel 1, 0, ADOnOff0, wv
	SetDimLabel 1, 1, ADOnOff1, wv
	SetDimLabel 1, 2, ADOnOff2, wv
	SetDimLabel 1, 3, ADOnOff3, wv
	SetDimLabel 1, 4, ADOnOff4, wv
	SetDimLabel 1, 5, ADOnOff5, wv
	SetDimLabel 1, 6, ADOnOff6, wv
	SetDimLabel 1, 7, ADOnOff7, wv
	SetDimLabel 1, 8, ADGain0, wv
	SetDimLabel 1, 9, ADGain1, wv
	SetDimLabel 1, 10, ADGain2, wv
	SetDimLabel 1, 11, ADGain3, wv
	SetDimLabel 1, 12, ADGain4, wv
	SetDimLabel 1, 13, ADGain5, wv
	SetDimLabel 1, 14, ADGain6, wv
	SetDimLabel 1, 15, ADGain7, wv
	SetDimLabel 1, 16, AlarmOnOff0, wv
	SetDimLabel 1, 17, AlarmOnOff1, wv
	SetDimLabel 1, 18, AlarmOnOff2, wv
	SetDimLabel 1, 19, AlarmOnOff3, wv
	SetDimLabel 1, 20, AlarmOnOff4, wv
	SetDimLabel 1, 21, AlarmOnOff5, wv
	SetDimLabel 1, 22, AlarmOnOff6, wv
	SetDimLabel 1, 23, AlarmOnOff7, wv
	SetDimLabel 1, 24, AlarmMin0, wv
	SetDimLabel 1, 25, AlarmMin1, wv
	SetDimLabel 1, 26, AlarmMin2, wv
	SetDimLabel 1, 27, AlarmMin3, wv
	SetDimLabel 1, 28, AlarmMin4, wv
	SetDimLabel 1, 29, AlarmMin5, wv
	SetDimLabel 1, 30, AlarmMin6, wv
	SetDimLabel 1, 31, AlarmMin7, wv
	SetDimLabel 1, 32, AlarmMax0, wv
	SetDimLabel 1, 33, AlarmMax1, wv
	SetDimLabel 1, 34, AlarmMax2, wv
	SetDimLabel 1, 35, AlarmMax3, wv
	SetDimLabel 1, 36, AlarmMax4, wv
	SetDimLabel 1, 37, AlarmMax5, wv
	SetDimLabel 1, 38, AlarmMax6, wv
	SetDimLabel 1, 39, AlarmMax7, wv
	
	return wv
End

/// @brief Returns a wave reference to the asyncSettingsKeyWave
///
/// asyncSettingsKeyWave is used to index async settings for
/// each data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
/// - 0: Parameter
/// - 1: Units
/// - 2: Tolerance Factor
///
/// Columns:
/// - 0: Async AD 0 OnOff
/// - 1: Async AD 1 OnOff
/// - 2: Async AD 2 OnOff
/// - 3: Async AD 3 OnOff
/// - 4: Async AD 4 OnOff
/// - 5: Async AD 5 OnOff
/// - 6: Async AD 6 OnOff
/// - 7: Async AD 7 OnOff
/// - 8: Async AD 0 Gain
/// - 9: Async AD 1 Gain
/// - 10: Async AD 2 Gain
/// - 11: Async AD 3 Gain
/// - 12: Async AD 4 Gain
/// - 13: Async AD 5 Gain
/// - 14: Async AD 6 Gain
/// - 15: Async AD 7 Gain
/// - 16: Async Alarm 0 OnOff
/// - 17: Async Alarm 1 OnOff
/// - 18: Async Alarm 2 OnOff
/// - 19: Async Alarm 3 OnOff
/// - 20: Async Alarm 4 OnOff
/// - 21: Async Alarm 5 OnOff
/// - 22: Async Alarm 6 OnOff
/// - 23: Async Alarm 7 OnOff
/// - 24: Async Alarm 0 Min
/// - 25: Async Alarm 1 Min
/// - 26: Async Alarm 2 Min
/// - 27: Async Alarm 3 Min
/// - 28: Async Alarm 4 Min
/// - 29: Async Alarm 5 Min
/// - 30: Async Alarm 6 Min
/// - 31: Async Alarm 7 Min
/// - 32: Async Alarm 0 Max
/// - 33: Async Alarm 1 Max
/// - 34: Async Alarm 2 Max
/// - 35: Async Alarm 3 Max
/// - 36: Async Alarm 4 Max
/// - 37: Async Alarm 5 Max
/// - 38: Async Alarm 6 Max
/// - 39: Async Alarm 7 Max
Function/Wave GetAsyncSettingsKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBSettKeyFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = asyncSettingsKeyWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(3,40) dfr:asyncSettingsKeyWave/Wave=wv
	wv = ""

	SetDimLabel 0, 0, Parameter, wv
	SetDimLabel 0, 1, Units, wv
	SetDimLabel 0, 2, Tolerance, wv

	wv[%Parameter][0] = "Async 0 On/Off"
	wv[%Units][0]     = "On/Off"
	wv[%Tolerance][0] = "-"
	
	wv[%Parameter][1] = "Async 1 On/Off"
	wv[%Units][1]     = "On/Off"
	wv[%Tolerance][1] = "-"
	
	wv[%Parameter][2] = "Async 2 On/Off"
	wv[%Units][2]     = "On/Off"
	wv[%Tolerance][2] = "-"
	
	wv[%Parameter][3] = "Async 3 On/Off"
	wv[%Units][3]     = "On/Off"
	wv[%Tolerance][3] = "-"
	
	wv[%Parameter][4] = "Async 4 On/Off"
	wv[%Units][4]     = "On/Off"
	wv[%Tolerance][4] = "-"
	
	wv[%Parameter][5] = "Async 5 On/Off"
	wv[%Units][5]     = "On/Off"
	wv[%Tolerance][5] = "-"
	
	wv[%Parameter][6] = "Async 6 On/Off"
	wv[%Units][6]     = "On/Off"
	wv[%Tolerance][6] = "-"
	
	wv[%Parameter][7] = "Async 7 On/Off"
	wv[%Units][7]     = "On/Off"
	wv[%Tolerance][7] = "-"		

	wv[%Parameter][8] = "Async 0 Gain"
	wv[%Units][8]     = ""
	wv[%Tolerance][8] = ".001"

	wv[%Parameter][9] = "Async 1 Gain"
	wv[%Units][9]     = ""
	wv[%Tolerance][9] = ".001"
	
	wv[%Parameter][10] = "Async 2 Gain"
	wv[%Units][10]     = ""
	wv[%Tolerance][10] = ".001"

	wv[%Parameter][11] = "Async 3 Gain"
	wv[%Units][11]     = ""
	wv[%Tolerance][11] = ".001"
	
	wv[%Parameter][12] = "Async 4 Gain"
	wv[%Units][12]     = ""
	wv[%Tolerance][12] = ".001"

	wv[%Parameter][13] = "Async 5 Gain"
	wv[%Units][13]     = ""
	wv[%Tolerance][13] = ".001"
	
	wv[%Parameter][14] = "Async 6 Gain"
	wv[%Units][14]     = ""
	wv[%Tolerance][14] = ".001"

	wv[%Parameter][15] = "Async 7 Gain"
	wv[%Units][15]     = ""
	wv[%Tolerance][15] = ".001"

	wv[%Parameter][16] = "Async Alarm 0 On/Off"
	wv[%Units][16]     = "On/Off"
	wv[%Tolerance][16] = "-"
	
	wv[%Parameter][17] = "Async Alarm 1 On/Off"
	wv[%Units][17]     = "On/Off"
	wv[%Tolerance][17] = "-"
	
	wv[%Parameter][18] = "Async Alarm 2 On/Off"
	wv[%Units][18]     = "On/Off"
	wv[%Tolerance][18] = "-"
	
	wv[%Parameter][19] = "Async Alarm 3 On/Off"
	wv[%Units][19]     = "On/Off"
	wv[%Tolerance][19] = "-"
	
	wv[%Parameter][20] = "Async Alarm 4 On/Off"
	wv[%Units][20]     = "On/Off"
	wv[%Tolerance][20] = "-"
	
	wv[%Parameter][21] = "Async Alarm 5 On/Off"
	wv[%Units][21]     = "On/Off"
	wv[%Tolerance][21] = "-"
	
	wv[%Parameter][22] = "Async Alarm 6 On/Off"
	wv[%Units][22]     = "On/Off"
	wv[%Tolerance][22] = "-"
	
	wv[%Parameter][23] = "Async Alarm 7 On/Off"
	wv[%Units][23]     = "On/Off"
	wv[%Tolerance][23] = "-"

	wv[%Parameter][24] = "Async Alarm 0 Min"
	wv[%Units][24]     = ""
	wv[%Tolerance][24] = ".001"
	
	wv[%Parameter][25] = "Async Alarm 1 Min"
	wv[%Units][25]     = ""
	wv[%Tolerance][25] = ".001"
	
	wv[%Parameter][26] = "Async Alarm 2 Min"
	wv[%Units][26]     = ""
	wv[%Tolerance][26] = ".001"
	
	wv[%Parameter][27] = "Async Alarm 3 Min"
	wv[%Units][27]     = ""
	wv[%Tolerance][27] = ".001"
	
	wv[%Parameter][28] = "Async Alarm 4 Min"
	wv[%Units][28]     = ""
	wv[%Tolerance][28] = ".001"
	
	wv[%Parameter][29] = "Async Alarm 5 Min"
	wv[%Units][29]     = ""
	wv[%Tolerance][29] = ".001"
	
	wv[%Parameter][30] = "Async Alarm 6 Min"
	wv[%Units][30]     = ""
	wv[%Tolerance][30] = ".001"
	
	wv[%Parameter][31] = "Async Alarm 7 Min"
	wv[%Units][31]     = ""
	wv[%Tolerance][31] = ".001"

	wv[%Parameter][32] = "Async Alarm  0 Max"
	wv[%Units][32]     = ""
	wv[%Tolerance][32] = ".001"
	
	wv[%Parameter][33] = "Async Alarm  1 Max"
	wv[%Units][33]     = ""
	wv[%Tolerance][33] = ".001"
	
	wv[%Parameter][34] = "Async Alarm  2 Max"
	wv[%Units][34]     = ""
	wv[%Tolerance][34] = ".001"
	
	wv[%Parameter][35] = "Async Alarm  3 Max"
	wv[%Units][35]     = ""
	wv[%Tolerance][35] = ".001"
	
	wv[%Parameter][36] = "Async Alarm  4 Max"
	wv[%Units][36]     = ""
	wv[%Tolerance][36] = ".001"
	
	wv[%Parameter][37] = "Async Alarm  5 Max"
	wv[%Units][37]     = ""
	wv[%Tolerance][37] = ".001"
	
	wv[%Parameter][38] = "Async Alarm  6 Max"
	wv[%Units][38]     = ""
	wv[%Tolerance][38] = ".001"
	
	wv[%Parameter][39] = "Async Alarm  7 Max"
	wv[%Units][39]     = ""
	wv[%Tolerance][39] = ".001"
	
	return wv
End

/// @brief Returns a wave reference to the AsyncSettingsTxtWave
///
/// AsyncSettingsTxtData is used to store the async text settings used on a particular
/// headstage and then create waveNotes for the sweep data
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: Async 0 Title
/// - 1: Async 1 Title
/// - 2: Async 2 Title
/// - 3: Async 3 Title
/// - 4: Async 4 Title
/// - 5: Async 5 Title
/// - 6: Async 6 Title
/// - 7: Async 7 Title
/// - 8: Async 0 Units
/// - 9: Async 1 Units
/// - 10: Async 2 Units
/// - 11: Async 3 Units
/// - 12: Async 4 Units
/// - 13: Async 5 Units
/// - 14: Async 6 Units
/// - 15: Async 7 Units
Function/Wave GetAsyncSettingsTextWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTextDocFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = asyncSettingsTxtData

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,16) dfr:asyncSettingsTxtData/Wave=wv
	wv = ""

	return wv
End

/// @brief Returns a wave reference to the AsyncSettingsKeyTxtData
///
/// AsyncSettingsKeyTxtData is used to index Txt Key Wave
///
/// Rows:
/// - Just one
///
/// Columns:
/// - 0: Async 0 Title
/// - 1: Async 1 Title
/// - 2: Async 2 Title
/// - 3: Async 3 Title
/// - 4: Async 4 Title
/// - 5: Async 5 Title
/// - 6: Async 6 Title
/// - 7: Async 7 Title
/// - 8: Async 0 Unit
/// - 9: Async 1 Unit
/// - 10: Async 2 Unit
/// - 11: Async 3 Unit
/// - 12: Async 4 Unit
/// - 13: Async 5 Unit
/// - 14: Async 6 Unit
/// - 15: Async 7 Unit
Function/Wave GetAsyncSettingsTextKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTxtDocKeyFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = asyncSettingsKeyTxtData

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,16) dfr:asyncSettingsKeyTxtData/Wave=wv
	wv = ""
	
	wv[0][0] = "Async AD0 Title"
	wv[0][1] = "Async AD1 Title"
	wv[0][2] = "Async AD2 Title"
	wv[0][3] = "Async AD3 Title"
	wv[0][4] = "Async AD4 Title"
	wv[0][5] = "Async AD5 Title"
	wv[0][6] = "Async AD6 Title"
	wv[0][7] = "Async AD7 Title"
	wv[0][8] = "Async AD0 Unit"
	wv[0][9] = "Async AD1 Unit"
	wv[0][10] = "Async AD2 Unit"
	wv[0][11] = "Async AD3 Unit"
	wv[0][12] = "Async AD4 Unit"
	wv[0][13] = "Async AD5 Unit"
	wv[0][14] = "Async AD6 Unit"
	wv[0][15] = "Async AD7 Unit"
	
	return wv
End

/// @}

/// @name Pressure Control
/// @{

/// @brief Returns device specific pressure folder as string
Function/S P_GetDevicePressureFolderAS(panelTitle)
	string panelTitle

	string 	DeviceNumber
	string 	DeviceType
	ParseDeviceString(panelTitle, deviceType, deviceNumber)
	string 	FolderPathString
	sprintf FolderPathString, "%s:Pressure:%s:Device_%s" GetMiesPathAsString(), DeviceType, DeviceNumber
	return FolderPathString
End

/// @brief Creates ITC device specific pressure folder - used to store data for pressure regulators
Function/DF P_DeviceSpecificPressureDFRef(panelTitle)
	string 	panelTitle
	return CreateDFWithAllParents(P_GetDevicePressureFolderAS(panelTitle))
End

/// @brief Returns pressure folder as string
Function/S P_GetPressureFolderAS(panelTitle)
	string panelTitle
	return GetMiesPathAsString() + ":Pressure"
End

/// @brief Returns the data folder reference for the main pressure folder "root:MIES:Pressure"
Function/DF P_PressureFolderReference(panelTitle)
	string panelTitle
	return CreateDFWithAllParents(P_GetPressureFolderAS(panelTitle))
End

/// @brief Returns a wave reference to the ITCDataWave used for pressure pulses
///
/// Rows:
/// - data points, see P_GetITCChanConfig() for the sampling interval
///
/// Columns:
/// - 0: DA data
/// - 1: AD data
/// - 2: TTL data rack 0
/// - 3: TTL data rack 1 (available if supported by the device)
Function/WAVE P_GetITCData(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr P_ITCData

	if(WaveExists(P_ITCData))
		return P_ITCData
	endif

	Make/W/N=(PRESSURE_WAVE_DATA_SIZE, 4) dfr:P_ITCData/WAVE=wv

	SetDimLabel COLS, 0, DA, 		wv
	SetDimLabel COLS, 1, AD, 		wv
	SetDimLabel COLS, 2, TTL_R0, 	wv
	SetDimLabel COLS, 3, TTL_R1, 	wv
	wv = 0

	return wv
End

/// @brief Returns a wave reference to the ITCChanConfig wave used for pressure pulses
///
/// Rows:
/// - 0: DA channel specifications
/// - 1: AD channel specifications
/// - 2: TTL rack 0 specifications
/// - 3: TTL rack 1 specifications (available if supported by the device)
///
/// Columns:
/// - 0: Channel Type
/// - 1: Channel number
/// - 2: Sampling interval
/// - 3: Decimation
Function/WAVE P_GetITCChanConfig(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr P_ChanConfig

	if(WaveExists(P_ChanConfig))
		return P_ChanConfig
	endif

	Make/I/N=(4, 4) dfr:P_ChanConfig/WAVE=wv

	wv = 0
	wv[0][0] = ITC_XOP_CHANNEL_TYPE_DAC
	wv[1][0] = ITC_XOP_CHANNEL_TYPE_ADC
	wv[2][0] = ITC_XOP_CHANNEL_TYPE_TTL
	wv[3][0] = ITC_XOP_CHANNEL_TYPE_TTL

	// invalid TTL channels
	wv[2][1] = -1
	wv[3][1] = -1

	wv[][2]  = HARDWARE_ITC_MIN_SAMPINT * 1000

	SetDimLabel ROWS, 0, DA, 		wv
	SetDimLabel ROWS, 1, AD, 		wv
	SetDimLabel ROWS, 2, TTL_R0, 	wv
	SetDimLabel ROWS, 3, TTL_R1, 	wv

	SetDimLabel COLS, 0, Chan_Type, wv
	SetDimLabel COLS, 1, Chan_num, 	wv
	SetDimLabel COLS, 2, Samp_int, 	wv

	return wv
End

/// @brief Returns a wave reference to the ITCFIFOAvailConfig wave used for pressure pulses
///
/// Rows:
/// - 0: DA channel specifications
/// - 1: AD channel specifications
/// - 2: TTL rack 0 specifications
/// - 3: TTL rack 1 specifications (available if supported by the device)
/// Columns:
/// - 0: Channel Type
/// - 1: Channel number
/// - 2: FIFO advance
/// - 3: Reserved
Function/WAVE P_GetITCFIFOConfig(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr P_ITCFIFOConfig

	if(WaveExists(P_ITCFIFOConfig))
		return P_ITCFIFOConfig
	endif

	Make/I/N=(4, 4) dfr:P_ITCFIFOConfig/WAVE=wv

	wv = 0
	wv[0][0] = ITC_XOP_CHANNEL_TYPE_DAC
	wv[1][0] = ITC_XOP_CHANNEL_TYPE_ADC
	wv[2][0] = ITC_XOP_CHANNEL_TYPE_TTL
	wv[3][0] = ITC_XOP_CHANNEL_TYPE_TTL

	// invalid TTL channels
	wv[2][1] = -1
	wv[3][1] = -1

	wv[][2]  = -1 // reset the FIFO

	SetDimLabel ROWS, 0, DA, 			wv
	SetDimLabel ROWS, 1, AD, 			wv
	SetDimLabel ROWS, 2, TTL_R0, 		wv
	SetDimLabel ROWS, 3, TTL_R1, 		wv

	SetDimLabel COLS, 0, Chan_Type,	 	wv
	SetDimLabel COLS, 1, Chan_num, 		wv
	SetDimLabel COLS, 2, FIFO_advance, 	wv
	return wv
End

/// @brief Returns a wave reference to the ITCFIFOAvail wave used for pressure pulses
///
/// Rows:
/// - 0: DA channel specifications
/// - 1: AD channel specifications
/// - 2: TTL rack 0 specifications
/// - 3: TTL rack 1 specifications
/// Columns:
/// - 0: Channel Type
/// - 1: Channel number
/// - 2: FIFO available
/// - 3: Reserved
Function/WAVE P_GetITCFIFOAvail(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr P_ITCFIFOAvail

	if(WaveExists(P_ITCFIFOAvail))
		return P_ITCFIFOAvail
	endif

	Make/I/N=(4, 4) dfr:P_ITCFIFOAvail/WAVE=wv

	SetDimLabel ROWS, 0, DA        , wv
	SetDimLabel ROWS, 1, AD        , wv
	SetDimLabel ROWS, 2, TTL_R0    , wv
	SetDimLabel ROWS, 3, TTL_R1    , wv

	SetDimLabel COLS, 0, Chan_Type , wv
	SetDimLabel COLS, 1, Chan_num  , wv
	SetDimLabel COLS, 2, FIFO_avail, wv

	wv = 0
	wv[0][0] = ITC_XOP_CHANNEL_TYPE_DAC
	wv[1][0] = ITC_XOP_CHANNEL_TYPE_ADC
	wv[2][0] = ITC_XOP_CHANNEL_TYPE_TTL
	wv[3][0] = ITC_XOP_CHANNEL_TYPE_TTL

	// invalid TTL channels
	wv[2][1] = -1
	wv[3][1] = -1

	return wv
End

/// @brief Returns wave reference of wave used to store data used in functions that run pressure regulators
/// creates the wave if it does not exist
///
/// Rows:
/// - 0 - 7: Headstage 0 through 7
///
/// Columns:
/// - 0: Pressure method. -1 = none, 0 = Approach, 1 = Seal, 2 = Break In, 3 = Clear
/// - 1: List position of DAC (used for presssure control) selected for headstage
/// - 2: Type of DAC, index into #HARDWARE_DAC_TYPES
/// - 3: Device ID used by Instrutech DACs or index into HW_NI_ListDevices depending on column 2
/// - 4: DA channel used for pressure regulation.
/// - 5: Gain of DA channel used for presssure regulation.
/// - 6: AD channel used for pressure regulation.
/// - 7: Gain of AD channel used for pressure regulation.
/// - 8: TTL chanel used for pressure regulation.
/// - 9: Pipette pressure setting while pipette is positioned in air/outside of bath.
/// - 10: Pipette pressure setting for pipette positioned in the bath.
/// - 11: Pipette pressure setting for pipette positioned in the slice.
/// - 12: Pipette pressure setting for pipette positioned near the target cell.
/// - 13: Pipette pressure setting for pipette at the initialization of seal formation.
/// - 14: Maximum Pipette pressure setting for seal formation.
/// - 15: Distance between the bottom of the recording chamber to the surface of the bath solution.
/// - 16: Distance between the bottom of the recording chamber and the top of the tissue slice.
/// - 17: Distance between the bottom of the recording chamber and the soma of the target cell.
/// - 18: X position (in the stage frame) of the soma of the target cell.
/// - 19: Y position (in the stage frame) of the soma of the target cell.
/// - 20: Place holder for future data.
/// - 21: Place holder for future data.
/// - 22: Last steady state resistance value.
/// - 23: Slope of the peak TP resistance over the last 5 seconds.
/// - 24: State of the TP (0 = OFF, 1 = ON).
/// - 25: Slope threshold. Used to determine if pressure should be incremented during sealing.
/// - 26: Last pressure command.
/// - 27: State of pressure pulse (0 = OFF, 1 = ON).
/// - 28: Last amplifier voltage command.
/// - 29: Manual pressure command amplitude in psi.
/// - 30: Manual pressure pulse command amplitude in psi.
/// - 31: Manual pressure pulse duation in ms.
/// - 32: Peak resistance on previous method cycle.
/// - 33: Peak resistance on active method cycle.
/// - 34: Time of last peak resistance check.
Function/WAVE P_GetPressureDataWaveRef(panelTitle)
	string	panelTitle

	variable versionOfNewWave = 1
	DFREF dfr = P_DeviceSpecificPressureDFRef(panelTitle)
	Wave/Z/SDFR=dfr wv=PressureData

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(8,40) wv
	else
		Make/N=(8,40) dfr:PressureData/Wave=wv
	endif

	wv 	= nan

	SetDimLabel COLS, 0 , Approach_Seal_BrkIn_Clear, wv
	SetDimLabel COLS, 1 , DAC_List_Index           , wv
	SetDimLabel COLS, 2 , HW_DAC_Type              , wv
	SetDimLabel COLS, 3 , DAC_DevID                , wv
	SetDimLabel COLS, 4 , DAC                      , wv
	SetDimLabel COLS, 5 , DAC_Gain                 , wv
	SetDimLabel COLS, 6 , ADC                      , wv
	SetDimLabel COLS, 7 , ADC_Gain                 , wv
	SetDimLabel COLS, 8 , TTL                      , wv
	SetDimLabel COLS, 9 , PSI_air                  , wv
	SetDimLabel COLS, 10, PSI_solution             , wv
	SetDimLabel COLS, 11, PSI_slice                , wv
	SetDimLabel COLS, 12, PSI_nearCell             , wv
	SetDimLabel COLS, 13, PSI_SealInitial          , wv
	SetDimLabel COLS, 14, PSI_SealMax              , wv
	SetDimLabel COLS, 15, solutionZaxis            , wv
	SetDimLabel COLS, 16, sliceZaxis               , wv
	SetDimLabel COLS, 17, cellZaxis                , wv
	SetDimLabel COLS, 18, cellXaxis                , wv
	SetDimLabel COLS, 19, cellYaxis                , wv
	SetDimLabel COLS, 20, PlaceHolderZero          , wv
	SetDimLabel COLS, 21, RealTimePressure         , wv
	SetDimLabel COLS, 22, LastResistanceValue      , wv
	SetDimLabel COLS, 23, PeakResistanceSlope      , wv // Slope of the peak TP resistance value over the last 5 seconds
	/// @todo Dim label for  col 23 needs to be changed to steadStateResistanceSlope
	SetDimLabel COLS, 24, ActiveTP				   , wv // Indicates if the TP is active on the headStage
	/// @todo If user switched headStage mode while pressure regulation is ongoing, pressure reg either needs to be turned off, or steady state slope values need to be used
	/// @todo Enable mode switching with TP running (auto stop TP, switch mode, auto startTP)
	/// @todo Enable headstate switching with TP running (auto stop TP, change headStage state, auto start TP)
	SetDimLabel COLS, 24, PeakResistanceSlopeThreshold, wv // If the PeakResistance slope is greater than the PeakResistanceSlope thershold pressure method does not need to update i.e. the pressure is "good" as it is
	SetDimLabel COLS, 25, TimeOfLastRSlopeCheck, wv
	SetDimLabel COLS, 26, LastPressureCommand  , wv
	SetDimLabel COLS, 27, OngoingPessurePulse  , wv
	SetDimLabel COLS, 28, LastVcom             , wv
	SetDimLabel COLS, 29, ManSSPressure        , wv
	SetDimLabel COLS, 30, ManPPPressure        , wv
	SetDimLabel COLS, 31, ManPPDuration        , wv
	SetDimLabel COLS, 32, LastPeakR            , wv
	SetDimLabel COLS, 33, PeakR                , wv
	SetDimLabel COLS, 34, TimePeakRcheck       , wv
	SetDimLabel COLS, 35, PosCalConst          , wv
	SetDimLabel COLS, 36, NegCalConst          , wv
	SetDimLabel COLS, 37, ApproachNear         , wv
	SetDimLabel COLS, 38, SealAtm              , wv
	SetDimLabel COLS, 39, UserSelectedHeadStage, wv

	SetDimLabel ROWS, 0, Headstage_0, wv
	SetDimLabel ROWS, 1, Headstage_1, wv
	SetDimLabel ROWS, 2, Headstage_2, wv
	SetDimLabel ROWS, 3, Headstage_3, wv
	SetDimLabel ROWS, 4, Headstage_4, wv
	SetDimLabel ROWS, 5, Headstage_5, wv
	SetDimLabel ROWS, 6, Headstage_6, wv
	SetDimLabel ROWS, 7, Headstage_7, wv

	// prime the wave to avoid index out of range error for popup menus and to
	// set all pressure methods to OFF (-1)
	wv[][0]                    = -1
	wv[][%DAC_List_Index]      = 0
	wv[][%DAC]                 = 0
	wv[][%ADC]                 = 0
	wv[][%TTL]                 = 0
	wv[][%ApproachNear]        = 0
	wv[][%SealAtm]             = 0
	wv[][%ManSSPressure]       = 0
	wv[][%LastPressureCommand] = 0

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns wave reference for wave used to store text used in pressure control.
///
/// Rows:
/// - 0 - 7: Headstage 0 through 7
///
/// Columns:
/// - 0: Digitial to analog converter device type string.
/// - 1: DA unit.
/// - 2: AD unit.
Function/WAVE P_PressureDataTxtWaveRef(panelTitle)
	string panelTitle

	variable versionOfNewWave = 1
	DFREF dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr wv=PressureDataTextWv

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(8, 3) wv
	else
		Make/T/N=(8, 3) dfr:PressureDataTextWv/WAVE=wv
	endif

	SetDimLabel COLS, 0, Device     , wv
	SetDimLabel COLS, 1, DA_Unit    , wv
	SetDimLabel COLS, 2, AD_Unit    , wv

	SetDimLabel ROWS, 0, Headstage_0, wv
	SetDimLabel ROWS, 1, Headstage_1, wv
	SetDimLabel ROWS, 2, Headstage_2, wv
	SetDimLabel ROWS, 3, Headstage_3, wv
	SetDimLabel ROWS, 4, Headstage_4, wv
	SetDimLabel ROWS, 5, Headstage_5, wv
	SetDimLabel ROWS, 6, Headstage_6, wv
	SetDimLabel ROWS, 7, Headstage_7, wv

	wv[][0] = NONE

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End
/// @}

/// @brief Returns a wave reference to the Analysis Master Wave
///
/// Analysis Master Wave is used to store routines for doing post-sweep analysis and post analysis actions.
///
/// Rows:
/// - Headstages
///
/// Columns:
/// - 0: Analysis On/Off
/// - 1: Analysis Function
/// - 2: Action On/Off
/// - 3: Action Function
///
Function/Wave GetAnalysisSettingsWaveRef(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecAnlyssSttngsWavePath(panelTitle)

	Wave/Z/T/SDFR=dfr wv = analysisSettingsWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(NUM_HEADSTAGES,9) dfr:analysisSettingsWave/Wave=wv
	wv = ""
	
	SetDimLabel 0, -1, HeadStage, wv
	
	SetDimLabel 1, 0, PSAOnOff, wv
	SetDimLabel 1, 1, PSAType, wv
	SetDimLabel 1, 2, PSAResult, wv
	SetDimLabel 1, 3, PAAOnOff, wv
	SetDimLabel 1, 4, PAAType, wv 
	SetDimLabel 1, 5, PAAResult, wv 
	SetDimLabel 1, 6, MSAOnOff, wv
	SetDimLabel 1, 7, MSAType, wv
	SetDimLabel 1, 8, MSAResult, wv

	return wv
End

///@brief Returns a wave reference to the ActionScaleSettings Wave
Function/Wave GetActionScaleSettingsWaveRef(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecAnlyssSttngsWavePath(panelTitle)

	Wave/Z/SDFR=dfr wv = actionScaleSettingsWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(NUM_HEADSTAGES,7) dfr:actionScaleSettingsWave/Wave=wv
	
	SetDimLabel 0, -1, HeadStage, wv	
	SetDimLabel 1, 0, coarseScaleValue, wv
	SetDimLabel 1, 1, fineScaleValue, wv
	SetDimLabel 1, 2, apThreshold, wv
	SetDimLabel 1, 3, coarseTuneUse, wv
	SetDimLabel 1, 4, fineTuneUse, wv
	SetDimLabel 1, 5, result, wv
	SetDimLabel 1, 6, elapsedTime, wv
	
	// put the coarse scale value to a default
	wv[][%coarseScaleValue] = 0.10 
	
	// put the fine scale value to a default
	wv[][%fineScaleValue] = 0.05
	
	// put the apThreshold to a default
	wv[][%apThreshold] = 0.0
	
	// put the coarse tune use factor to 1 as an initial state
	wv[][%coarseTuneUse] = 1

	return wv
End

/// @brief Return the datafolder reference to the device specific text documentation
Function/DF GetDevSpecAnlyssSttngsWavePath(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecAnlyssSttngsWaveAS(panelTitle))
End

/// @brief Return the full path to the device specific text documentation, e.g. root:mies:LabNoteBook:ITC18USB:Device0:analysisSettings
Function/S GetDevSpecAnlyssSttngsWaveAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":analysisSettings"
End

/// @name Analysis Browser
/// @{

/// @brief Return the datafolder reference to the root folder for the analysis browser
Function/DF GetAnalysisFolder()
	return createDFWithAllParents(GetAnalysisFolderAS())
End

/// @brief Return the full path to the root analysis folder, e.g. root:MIES:analysis
Function/S GetAnalysisFolderAS()
	return GetMiesPathAsString() + ":Analysis"
End

/// @brief Return the datafolder reference to the per experiment folder
Function/DF GetAnalysisExpFolder(expFolder)
	string expFolder
	return createDFWithAllParents(GetAnalysisExpFolderAS(expFolder))
End

/// @brief Return the full path to the per experiment folder, e.g. root:MIES:Analysis:my_experiment
Function/S GetAnalysisExpFolderAS(expFolder)
	string expFolder
	return GetAnalysisFolderAS() + ":" + expFolder
End

/// @brief Return the datafolder reference to the per device folder of an experiment
Function/DF GetAnalysisDeviceFolder(expFolder, device)
	string expFolder, device
	return createDFWithAllParents(GetAnalysisDeviceFolderAS(expFolder, device))
End

/// @brief Return the full path to the per device folder of an experiment, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0
Function/S GetAnalysisDeviceFolderAS(expFolder, device)
	string expFolder, device
	return GetAnalysisExpFolderAS(expFolder) + ":" + device
End

/// @brief Return the datafolder reference to the sweep config folder of a device and experiment pair
Function/DF GetAnalysisDeviceConfigFolder(expFolder, device)
	string expFolder, device
	return createDFWithAllParents(GetAnalysisDeviceConfigFolderAS(expFolder, device))
End

/// @brief Return the full path to the sweep config folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:config
Function/S GetAnalysisDeviceConfigFolderAS(expFolder, device)
	string expFolder, device

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":config"
End

/// @brief Return the datafolder reference to the testpulse folder of a device and experiment pair
Function/DF GetAnalysisDeviceTestpulse(expFolder, device)
	string expFolder, device
	return createDFWithAllParents(GetAnalysisDeviceTestpulseAS(expFolder, device))
End

/// @brief Return the full path to the testpulse folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:testpulse
Function/S GetAnalysisDeviceTestpulseAS(expFolder, device)
	string expFolder, device
	return GetAnalysisDeviceFolderAS(expFolder, device) + ":testpulse"
End

/// @brief Return the datafolder reference to the labnotebook folder of a device and experiment pair
Function/DF GetAnalysisLabNBFolder(expFolder, device)
	string expFolder, device
	return createDFWithAllParents(GetAnalysisLabNBFolderAS(expFolder, device))
End

/// @brief Return the full path to the labnotebook folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:labnotebook
Function/S GetAnalysisLabNBFolderAS(expFolder, device)
	string expFolder, device
	return GetAnalysisDeviceFolderAS(expFolder, device) + ":labnotebook"
End

/// @brief Return the datafolder reference to the sweep folder of a device and experiment pair
Function/DF GetAnalysisSweepPath(expFolder, device)
	string expFolder, device

	return createDFWithAllParents(GetAnalysisSweepPathAsString(expFolder, device))
End

/// @brief Return the full path to the sweep folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:sweep
Function/S GetAnalysisSweepPathAsString(expFolder, device)
	string expFolder, device

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":sweep"
End

/// @brief Return the datafolder reference to the per sweep folder
Function/DF GetAnalysisSweepDataPath(expFolder, device, sweep)
	string expFolder, device
	variable sweep

	return createDFWithAllParents(GetAnalysisSweepDataPathAS(expFolder, device, sweep))
End

/// @brief Return the full path to the the per sweep folder, e.g. root:MIES:Analysis:my_experiment:sweep
Function/S GetAnalysisSweepDataPathAS(expFolder, device, sweep)
	string expFolder, device
	variable sweep

	ASSERT(IsFinite(sweep), "Expected finite sweep number")
	// folder name starts with X as only liberal names are allowed to start with numbers. And we don't want liberal names.
	return GetAnalysisSweepPathAsString(expFolder, device) + ":X_" + num2str(sweep)
End

/// @brief Return the datafolder reference to the stim set folder
Function/DF GetAnalysisStimSetPath(expFolder, device)
	string expFolder, device

	return createDFWithAllParents(GetAnalysisStimSetPathAS(expFolder, device))
End

/// @brief Return the full path to the stim set folder, e.g. root:MIES:Analysis:my_experiment::stimset
Function/S GetAnalysisStimSetPathAS(expFolder, device)
	string expFolder, device

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":stimset"
End

/// @brief Return the text wave mapping the properties of the loaded experiments
Function/Wave GetExperimentMap()

	DFREF dfr = GetAnalysisFolder()

	Wave/Z/SDFR=dfr/T wv = experimentMap

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE, 3)/T dfr:experimentMap/Wave=wv

	SetDimLabel COLS, 0, ExperimentDiscLocation, wv
	SetDimLabel COLS, 1, ExperimentName, wv
	SetDimLabel COLS, 2, ExperimentFolder, wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the text wave used in the listbox of the experiment browser
///
/// The "experiment" column in the second layer maps to the corresponding row in the experimentMap.
Function/Wave GetExperimentBrowserGUIList()

	DFREF dfr = GetAnalysisFolder()

	Wave/Z/SDFR=dfr/T wv = expBrowserList

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE, NUM_COLUMNS_LIST_WAVE, 2)/T dfr:expBrowserList/Wave=wv

	SetDimLabel COLS, 0 , $""          , wv
	SetDimLabel COLS, 1 , experiment   , wv
	SetDimLabel COLS, 2 , $""          , wv
	SetDimLabel COLS, 3 , device       , wv
	SetDimLabel COLS, 4 , '#sweeps'    , wv
	SetDimLabel COLS, 5 , sweep        , wv
	SetDimLabel COLS, 6 , '#headstages', wv
	SetDimLabel COLS, 7 , 'stim sets'  , wv
	SetDimLabel COLS, 8 , 'set count'  , wv
	SetDimLabel COLS, 9 , '#DAC'       , wv
	SetDimLabel COLS, 10, '#ADC'       , wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the selection wave used in the listbox of the experiment browser
///
Function/Wave GetExperimentBrowserGUISel()

	DFREF dfr = GetAnalysisFolder()

	Wave/Z/SDFR=dfr wv = expBrowserSel

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE, NUM_COLUMNS_LIST_WAVE) dfr:expBrowserSel/Wave=wv

	return wv
End

/// @brief Return the config wave of a given sweep from the analysis subfolder
Function/Wave GetAnalysisConfigWave(expFolder, device, sweep)
	string expFolder, device
	variable sweep

	Wave/SDFR=GetAnalysisDeviceConfigFolder(expFolder, device) wv = $("Config_Sweep_" + num2str(sweep))

	return wv
End

/// @brief Return the sweep wave of a given sweep from the analysis subfolder
Function/Wave GetAnalysisSweepWave(expFolder, device, sweep)
	string expFolder, device
	variable sweep

	Wave/SDFR=GetAnalysisSweepDataPath(expFolder, device, sweep) wv = $("Sweep_" + num2str(sweep))

	return wv
End

/// @}

///@brief Returns a wave reference to the new config settings Wave
Function/Wave GetConfigSettingsWaveRef(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecConfigSttngsWavePath(panelTitle)

	Wave/Z/T/SDFR=dfr wv = configSettings

	if(WaveExists(wv))
		return wv
	endif

	print "making the config wave..."
	// Make this a 2 by 1 wave...the 1st row will have the name of the thing saved, the 2nd row will have the value, and the third will have the control state.  This wave will get redimensioned and
	// expanded and new things are added
	Make/T/N=(3,1) dfr:configSettings/Wave=wv
	
	SetDimLabel 0, 0, settingName, wv
	SetDimLabel 0, 1, settingValue, wv
	SetDimLabel 0, 2, controlState, wv
	SetDimLabel 1, 0, version, wv
	
	return wv
End

/// @brief Return the datafolder reference to the device specific config settings wave
Function/DF GetDevSpecConfigSttngsWavePath(panelTitle)
	string panelTitle
	return createDFWithAllParents(GetDevSpecConfigSttngsWaveAS(panelTitle))
End

/// @brief Return the full path to the device specific config settings wave
Function/S GetDevSpecConfigSttngsWaveAS(panelTitle)
	string panelTitle
	return GetDevSpecLabNBFolderAsString(panelTitle) + ":configSettings"
End

///@brief Returns a wave reference to the Asynch response wave
Function/Wave GetAsynRspWaveRef(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecAsynRspWavePath(panelTitle)

	Wave/T/Z/SDFR=dfr wv = asynRspWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(NUM_HEADSTAGES,1) dfr:asynRspWave/Wave=wv
	
	SetDimLabel 0, -1, HeadStage, wv	
	SetDimLabel 1, 0, cmdID, wv

	return wv
End

/// @brief Return the datafolder reference to the device specific Asyn Response Wave..used for holding the cmd_id required by the workflow sequencing engine
Function/DF GetDevSpecAsynRspWavePath(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecAsynRspWaveAS(panelTitle))
End

/// @brief Return the full path to the device specific Asyn Response wave for holding the cmd_id value
Function/S GetDevSpecAsynRspWaveAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":cmdID"
End

/// @brief Return the TTL indexing storage wave
///
/// Rows:
/// 0: Popup menu index of TTL wave
/// 1: Popup menu index of Indexing end wave
/// 2-3: Unused
///
/// Columns:
/// - TLL channels
Function/Wave GetTTLIndexingStorageWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/Z/SDFR=dfr wv = TTLIndexingStorageWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(4, NUM_DA_TTL_CHANNELS) dfr:TTLIndexingStorageWave/Wave=wv

	return wv
End

/// @brief Return the DAC indexing storage wave
///
/// Rows:
/// 0: Popup menu index of DAC wave
/// 1: Popup menu index of Indexing end wave
/// 2-3: Unused
///
/// Columns:
/// - DACs
Function/Wave GetDACIndexingStorageWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/Z/SDFR=dfr wv = DACIndexingStorageWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(4, NUM_DA_TTL_CHANNELS) dfr:DACIndexingStorageWave/Wave=wv

	return wv
End

/// @brief Return a unique temporary folder below the MIES hierarchy, e.g. root:mies:trash_$digit.
///
/// As soon as you discard the latest reference to the folder it will
/// be slated for removal at some point in the future.
Function/DF GetUniqueTempPath()

	return UniqueDataFolder(GetMiesPath(), TRASH_FOLDER_PREFIX)
End

/// @brief Return the datafolder reference to the static data location, e.g. root:mies:StaticData:
Function/DF GetStaticDataFolder()
	return createDFWithAllParents(GetStaticDataFolderAS())
End

/// @brief Return the full path to the static data location
Function/S GetStaticDataFolderAS()

	return GetMiesPathAsString() + ":StaticData"
End

/// @brief Return the datafolder reference to the active ITC devices folder,
/// e.g. root:MIES:ITCDevices:ActiveITCDevices:TestPulse
Function/DF GetActITCDevicesTestPulseFolder()
	return createDFWithAllParents(GetActITCDevicesTestPulFolderA())
End


/// @brief Return the full path to the active ITC devices location
Function/S GetActITCDevicesTestPulFolderA()
	return GetITCDevicesFolderAsString() + ":ActiveITCDevices:TestPulse"
End

/// @brief Returns wave (DA_EphysGuiState) that stores the DA_Ephys GUI state
/// DA_EphysGuiState is stored in the device specific folder
/// e.g. root:MIES:ITCDevices:ITC18USB:Device0
///
/// Rows:
/// - Column specific GUI control settings usually associated with control name number
///
/// Columns:
/// - DACs
/// 0: HSState State of control Check_DataAcqHS_RowNum. 0 = UnChecked, 1 = Checked
/// 1: HSMode Clamp mode of HS number that matches Row number. 0 = VC, 1 = IC, 2 = NC. 
/// 2: DAState State of control Check_DA_RowNum. 0 = UnChecked, 1 = Checked
/// 3: DAGain Internal number stored in control Gain_DA_RowNum. Gain is user/hardware defined.
/// 4: DAScale Internal number stored in setvar:Scale_DA_RowNum. Scalar is user defined.
/// 5: DAStartIndex PopupMenu Index of popupMenu:Wave_DA_RowNum. Stores index of active DA stimulus set during data acquisition. Stores index of next DA stimulus set when data acquistion is not active.
/// 6: DAEndIndex PopupMenu Index of popupMenu:IndexEnd_DA_RowNum. Stores the index of the last DA stimulus set used in indexed aquisition mode.
/// 7: ADState State of checkbox control Check_AD_RowNum. 0 = UnChecked, 1 = Checked
/// 8: ADGain Internal number stored in Gain_AD_RowNum. Gain is user/hardware defined.
/// 9: TTLState State of checkbox control Check_TTL_RowNum.  0 = UnChecked, 1 = Checked
/// 10: TTLStartIndex PopupMenu Index of popupMenu:Wave_TTL_RowNum. Stores index of active TTL stimulus set during data acquisition. Stores index of next TTL stimulus set when data acquistion is not active.
/// 11: TTLEndIndex PopupMenu Index of popupMenu:IndexEnd_TTL_RowNum. Stores the index of the last TTL stimulus set used in indexed aquisition mode.
/// 12: AsyncState State of control Check_AsyncAD_RowNum. 0 = UnChecked, 1 = Checked 
/// 13: AsyncGain Internal number stored in control SetVar_AsyncAD_Gain_RowNum. Gain is user/hardware defined.
/// 14: AlarmState State of control check_AsyncAlarm_RowNum. 0 = UnChecked, 1 = Checked
/// 15: AlarmMin Internal number stored in control min_AsyncAD__RowNum. The minium value alarm trigger.
/// 16: AlarmMax Internal number stored in control max_AsyncAD_RowNum. The max value alarm trigger.
/// 17+: Unique controls
Function/Wave GetDA_EphysGuiStateNum(panelTitle)
	string panelTitle

	DFREF dfr= GetDevicePath(panelTitle)
	Wave/Z/SDFR=dfr wv = DA_EphysGuiState
	variable uniqueCtrlCount
	string uniqueCtrlList

	if(ExistsWithCorrectLayoutVersion(wv, DA_EPHYS_PANEL_VERSION))
		return wv
	elseif(WaveExists(wv)) // handle upgrade
		// change the required dimensions and leave all others untouched with -1
		// the extended dimensions are initialized with zero
		uniqueCtrlList = GetUniqueSpecCtrlTypeList(panelTitle)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Redimension/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT + uniqueCtrlCount, -1, -1) wv
		wv = Nan
	else
		uniqueCtrlList = GetUniqueSpecCtrlTypeList(panelTitle)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Make/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT + uniqueCtrlCount) dfr:DA_EphysGuiState/Wave=wv
		wv = Nan
	endif

	SetDimLabel COLS, 0, HSState, wv
	SetDimLabel COLS, 1, HSMode, wv
	SetDimLabel COLS, 2, DAState, wv
	SetDimLabel COLS, 3, DAGain, wv
	SetDimLabel COLS, 4, DAScale, wv
	SetDimLabel COLS, 5, DAStartIndex, wv
	SetDimLabel COLS, 6, DAEndIndex, wv
	SetDimLabel COLS, 7, ADState, wv
	SetDimLabel COLS, 8, ADGain, wv
	SetDimLabel COLS, 9, TTLState, wv
	SetDimLabel COLS, 10, TTLStartIndex, wv
	SetDimLabel COLS, 11, TTLEndIndex, wv
	SetDimLabel COLS, 12, AsyncState, wv
	SetDimLabel COLS, 13, AsyncGain, wv
	SetDimLabel COLS, 14, AlarmState, wv
	SetDimLabel COLS, 15, AlarmMin, wv
	SetDimLabel COLS, 16, AlarmMax, wv

	SetWaveDimLabel(wv, uniqueCtrlList, COLS, startPos = COMMON_CONTROL_GROUP_COUNT)
	SetWaveVersion(wv, DA_EPHYS_PANEL_VERSION)
	// needs to be called after setting the wave version in order to avoid infinite recursion
	RecordDA_EphysGuiStateWrapper(panelTitle, wv)
	return wv
End

/// @brief Calls `DAP_RecordDA_EphysGuiState` if it can be found,
/// otherwise calls `RecordDA_EphysGuiStateProto` which aborts.
static Function RecordDA_EphysGuiStateWrapper(str, wv)
	string str
	WAVE wv

	FUNCREF RecordDA_EphysGuiStateProto f = $"DAP_RecordDA_EphysGuiState"
	f(str, GUISTATE=wv)
End

Function RecordDA_EphysGuiStateProto(str, [GUISTATE])
	string str
	WAVE GUISTATE

	Abort "Prototype function can not be called"
End

/// @brief Returns a list of unique and type specific controls
///
Function/S GetUniqueSpecCtrlTypeList(panelTitle)
	string panelTitle

	return GetSpecificCtrlTypes(panelTitle, GetUniqueCtrlList(panelTitle))
End

/// @brief Parses a list of controls in the panelTitle and returns a list of unique controls
///
Function/S GetUniqueCtrlList(panelTitle)
	string panelTitle

	string list = controlNameList(panelTitle)
	string relatedSetVar   = "Gain_*;Scale_*;Unit_*;Min_*;Max_*;Search_DA_*;Search_TTL_*;"
	string relatedCheckBox = "Check_AD_*;Check_DA_*;Check_TTL_*;Check_AsyncAlarm_*;Check_AsyncAD_*;Check_DataAcqHS_*;Radio_ClampMode_*;"
	string relatedPopUp    = "IndexEnd_*;Wave_*;"
	string relatedValDisp  = "ValDisp_DataAcq_P_*;"
	string ctrlToRemove    = relatedSetVar + relatedCheckBox + relatedPopUp + relatedValDisp
	string prunedList
	variable i,j

	for(i=0;i<itemsinlist(ctrlToRemove);i+=1)
		prunedList = ListMatch(list, stringfromlist(i, ctrlToRemove))
		list = removefromlist(prunedList, list)
	endfor

	return list
End

/// @brief Parses a list of controls and returns numeric checkBox, valDisplay, setVariable, popUpMenu, and slider controls
///
Function/S GetSpecificCtrlTypes(panelTitle,list)
	string panelTitle
	string list

	string subtypeCtrlList = ""
	variable i, type
	string controlName

	for(i=0;i<itemsinlist(list);i+=1)
		controlName = stringfromlist(i, list)
		controlInfo/W=$panelTitle $controlName
		type = abs(V_flag)
		switch(type)
			case CONTROL_TYPE_CHECKBOX:
			case CONTROL_TYPE_POPUPMENU:
			case CONTROL_TYPE_SLIDER: // fallthrough by design
				subtypeCtrlList = AddListItem(controlName, subtypeCtrlList)
				break
			case CONTROL_TYPE_VALDISPLAY:
			case CONTROL_TYPE_SETVARIABLE:  // fallthrough by design
				if(!DoesControlHaveInternalString(panelTitle, controlName))
					subtypeCtrlList = AddListItem(controlName, subtypeCtrlList)
				endif
				break
			default:
				// do nothing
				break
		endswitch
	endfor

	return subtypeCtrlList
End

/// @brief Return the datafolder reference to the NeuroDataWithoutBorders folder,
///        e.g. root:MIES:NWB
Function/DF GetNWBFolder()
	return createDFWithAllParents(GetNWBFolderAS())
End

/// @brief Return the full path to the NeuroDataWithoutBorders folder
Function/S GetNWBFolderAS()
	return GetMiesPathAsString() + ":NWB"
End

/// @brief Return a wave mapping the deviceIDs (numeric) to the device name(NI HW only) and user visible device name
///
/// Rows:
/// - DeviceIDs, supports 32 as the ITC XOP does
///
/// COLS:
/// - One column for each supported HW type
///
/// LAYERS:
/// - 0: Main device (aka panelTitle of a DA_Ephys panel), used for deriving datafolders for storage
/// - 1: (NI only) Internally used name of the device
/// - 2: Name of the device used for pressure control (maybe empty)
Function/WAVE GetDeviceMapping()

	DFREF dfr = GetITCDevicesFolder()

	WAVE/Z/T/SDFR=dfr wv = deviceMapping

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(HARDWARE_MAX_DEVICES, ItemsInList(HARDWARE_DAC_TYPES), 3) dfr:deviceMapping/Wave=wv

	SetDimLabel ROWS, -1, DeviceID, wv

	SetDimLabel COLS, 0, ITC_DEVICE, wv
	SetDimLabel COLS, 1, NI_DEVICE , wv

	SetDimLabel LAYERS, 0, MainDevice    , wv
	SetDimLabel LAYERS, 1, InternalDevice, wv
	SetDimLabel LAYERS, 2, PressureDevice, wv

	return wv
End
