#pragma rtGlobals=3

/// @file TJ_MIES_WaveDataFolderGetters.ipf
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
/// - 10: Index into popup_Settings_Amplifier in the DA_Ephys panel
/// - 11: Unused
///
/// Columns:
/// - Head stage number
///
Function/Wave GetChanAmpAssign(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	Wave/Z/SDFR=dfr wv = ChanAmpAssign

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(12, NUM_HEADSTAGES) dfr:ChanAmpAssign/Wave=wv
	wv = NaN

	return wv
End

/// @brief Return a wave reference to the channel <-> amplifier relation wave (textual part)
///
/// Rows:
/// - 0: DA unit (V-Clamp mode)
/// - 1: AD unit (V-Clamp mode)
/// - 3: DA unit (I-Clamp mode)
/// - 4: AD unit (I-Clamp mode)
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
		Abort "Invalid/Non-locked paneltitle"
	endif

	return GetDeviceTypePathAsString(deviceType) + ":Device" + deviceNumber
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

/// @brief Return the ITC data wave
Function/Wave GetITCDataWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/Z/SDFR=dfr wv = ITCDataWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(1, NUM_DA_TTL_CHANNELS) dfr:ITCDataWave/Wave=wv

	return wv
End

/// @brief Return the ITC channel config wave
Function/Wave GetITCChanConfigWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/Z/SDFR=dfr wv = ITCChanConfigWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(2, 4) dfr:ITCChanConfigWave/Wave=wv

	return wv
End

/// @brief Return the ITC fifo available for all channels wave
Function/Wave GetITCFIFOAvailAllConfigWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/Z/SDFR=dfr wv = ITCFIFOAvailAllConfigWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(2, 4) dfr:ITCFIFOAvailAllConfigWave/Wave=wv

	return wv
End

/// @brief Return the ITC fifo available for all channels wave
Function/Wave GetITCFIFOPositionAllConfigWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/Z/SDFR=dfr wv = ITCFIFOPositionAllConfigWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(2, 4) dfr:ITCFIFOPositionAllConfigWave/Wave=wv

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

/// @brief Returns a wave reference to the SweepData
///
/// SweepData is used to store GUI configuration info which can then be transferred into the documenting functions
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: DAC
/// - 1: ADC
/// - 2: DA Gain
/// - 3: AD Gain
/// - 4: DA Scale
/// - 5: Set sweep count 
/// - 6: TP Insert On/Off
/// - 7: Inter-trial interval
///
/// Layers:
/// - Headstage
Function/Wave DC_SweepDataWvRef(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	Wave/Z/SDFR=dfr wv = SweepData
	variable versionOfNewWave = 1

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 8,-1) wv
	else
		Make/N=(1, 8, NUM_HEADSTAGES) dfr:SweepData/Wave=wv
	endif

	wv = NaN
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns a wave reference to the SweepTxtData
///
/// SweepTxtData is used to store the set name used on a particular headstage
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: SetName
/// - 1: User comment
/// - 2: DA unit
/// - 3: AD unit
///
/// Layers:
/// - Headstage
Function/Wave DC_SweepDataTxtWvRef(panelTitle)
	string panelTitle
	
	DFREF dfr = GetDevicePath(panelTitle)

	Wave/Z/T/SDFR=dfr wv = SweepTxtData
	variable versionOfNewWave = 2

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 4, -1) wv
	else
		Make/T/N=(1, 4, NUM_HEADSTAGES) dfr:SweepTxtData/Wave=wv
	endif

	wv = ""
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

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
/// txtDocWave is used to save settings for each data sweep
///
/// Rows:
/// - Only one
///
/// Columns:
/// - Filled at runtime
///
/// Layers:
/// - Headstage
Function/Wave GetTextDocWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTextDocFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = txtDocWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,2,NUM_HEADSTAGES) dfr:txtDocWave/Wave=wv
	wv = ""

	return wv
End

/// @brief Returns a wave reference to the textDocKeyWave
///
/// textDocKeyWave is used to index save settings for each data sweep
/// and create waveNotes for tagging data sweeps
///
/// Rows:
/// - 0: Parameter Name
/// - 0: Parameter Unit
/// - 0: Parameter Tolerance
///
/// Columns:
/// - 0: Sweep Number
/// - 1: Time Stamp
/// - other columns are filled at runtime
Function/Wave GetTextDocKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTxtDocKeyFolder(panelTitle)

	variable versionOfNewWave = 1

	Wave/Z/T/SDFR=dfr wv = txtDocKeyWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, INITIAL_KEY_WAVE_COL_COUNT) wv
	else
		Make/T/N=(3, INITIAL_KEY_WAVE_COL_COUNT) dfr:txtDocKeyWave/Wave=wv
	endif

	wv = ""

	wv[0][0] = "Sweep #"
	wv[0][1] = "Time Stamp"

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units,     wv
	SetDimLabel ROWS, 2, Tolerance, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns a wave reference to the sweepSettingsWave
///
/// sweepSettingsWave is used to save stimulus settings for each
/// data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
///  - One row
///
/// Columns:
/// - 0: Stim Scale Factor
/// - 1: DAC
/// - 2: ADC
/// - 3: DA Gain
/// - 4: AD Gain
/// - 5: Set sweep count
/// - 6: Insert TP on/off
/// - 7: Inter-trial interval
///
/// Layers:
/// - Headstage
Function/Wave GetSweepSettingsWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBSettHistFolder(panelTitle)
	variable versionOfNewWave = 1

	Wave/Z/SDFR=dfr wv = sweepSettingsWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 8, -1) wv
	else
		Make/N=(1, 8, NUM_HEADSTAGES) dfr:sweepSettingsWave/Wave=wv
	endif

	wv = Nan
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
/// - 0: Stim Scale Factor
/// - 1: DAC
/// - 2: ADC
/// - 3: DA Gain
/// - 4: AD Gain
/// - 5: Set sweep count
/// - 6: Insert TP on/off
/// - 7: Inter-trial interval
///
/// Layers:
/// - Headstage
Function/Wave GetSweepSettingsKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBSettKeyFolder(panelTitle)
	variable versionOfNewWave = 1

	Wave/Z/T/SDFR=dfr wv = sweepSettingsKeyWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 8) wv
	else
		Make/T/N=(3, 8) dfr:sweepSettingsKeyWave/Wave=wv
	endif

	wv = ""

	SetDimLabel 0, 0, Parameter, wv
	SetDimLabel 0, 1, Units, wv
	SetDimLabel 0, 2, Tolerance, wv

	wv[%Parameter][0] = "Stim Scale Factor"
	wv[%Units][0]     = "%"
	wv[%Tolerance][0] = ".0001"

	wv[%Parameter][1] = "DAC"
	wv[%Units][1]     = ""
	wv[%Tolerance][1] = ".0001"

	wv[%Parameter][2] = "ADC"
	wv[%Units][2]     = ""
	wv[%Tolerance][2] = ".0001"

	wv[%Parameter][3] = "DA Gain"
	wv[%Units][3]     = "mV/V"
	wv[%Tolerance][3] = ".000001"

	wv[%Parameter][4] = "AD Gain"
	wv[%Units][4]     = "V/pA"
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
/// - 0: SetName
/// - 1: User Comment
/// - 2: DA unit
/// - 3: AD unit
///
/// Layers:
/// - Headstage
Function/Wave GetSweepSettingsTextWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTextDocFolder(panelTitle)
	variable versionOfNewWave = 2

	Wave/Z/T/SDFR=dfr wv = SweepSettingsTxtData

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 4, -1) wv
	else
		Make/T/N=(1, 4, NUM_HEADSTAGES) dfr:SweepSettingsTxtData/Wave=wv
	endif

	wv = ""

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
/// - 0: SetName
/// - 1: User Comment
/// - 2: DA unit
/// - 3: AD unit
///
/// Layers:
/// - Headstage
Function/Wave GetSweepSettingsTextKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTxtDocKeyFolder(panelTitle)
	variable versionOfNewWave = 2

	Wave/Z/T/SDFR=dfr wv = SweepSettingsKeyTxtData

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 4, -1) wv
	else
		Make/T/N=(1, 4, NUM_HEADSTAGES) dfr:SweepSettingsKeyTxtData/Wave=wv
	endif

	wv = ""

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
	Wave/Z/SDFR=dfr wv = TPStorage

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(128, NUM_AD_CHANNELS, 9) dfr:TPStorage/Wave=wv
	wv = NaN

	SetDimLabel COLS,  -1, ADChannel            , wv

	SetDimLabel LAYERS, 0, Vm                   , wv
	SetDimLabel LAYERS, 1, PeakResistance       , wv
	SetDimLabel LAYERS, 2, SteadyStateResistance, wv
	SetDimLabel LAYERS, 3, TimeInSeconds        , wv
	SetDimLabel LAYERS, 4, DeltaTimeInSeconds   , wv
	SetDimLabel LAYERS, 5, Vm_Slope             , wv
	SetDimLabel LAYERS, 6, Rpeak_Slope          , wv
	SetDimLabel LAYERS, 7, Rss_Slope            , wv
	SetDimLabel LAYERS, 8, Pressure             , wv

	Note wv, TP_CYLCE_COUNT_KEY + ":0;"
	Note/NOCR wv, AUTOBIAS_LAST_INVOCATION_KEY + ":0;"
	Note/NOCR wv, DIMENSION_SCALING_LAST_INVOC + ":0;"

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

/// @brief Return the ITC testpulse wave
Function/Wave GetTestPulseITCWave(panelTitle)
	string 	panelTitle

	dfref dfr = GetDeviceTestPulse(panelTitle)
	WAVE/Z/SDFR=dfr wv = TestPulseITC

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(1, NUM_DA_TTL_CHANNELS) dfr:TestPulseITC/Wave=wv

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

	variable versionOfNewWave = 2

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
	SetDimLabel ROWS  , 8 , PipetteOffset         , wv
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
	SetDimLabel ROWS  , 26, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 27, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 28, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 29, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 30, IZeroEnable           , wv

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
Function/WAVE GetAmplifierSettingsWave(panelTitle)
	string panelTitle

	variable versionOfNewWave = 4
	dfref dfr = GetAmpSettingsFolder()

	Wave/Z/SDFR=dfr wv = ampSettings

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 43, -1) wv
	else
		Make/N=(1, 43, NUM_HEADSTAGES) dfr:ampsettings/Wave=wv
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
Function/WAVE GetAmplifierSettingsTextWave(panelTitle)
	string panelTitle

	dfref dfr = GetAmpSettingsFolder()
	variable versionOfNewWave = 1

	Wave/T/Z/SDFR=dfr wv = ampSettingsText

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 6 -1) wv
	else
		Make/T/N=(1, 6, NUM_HEADSTAGES) dfr:ampSettingsText/Wave=wv
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

/// @brief Return the parameter wave for the wave builder panel
///
/// Rows:
/// - Variables synced to GUI controls, see e.g. WB_MakeWaveBuilderWave in TJ_MIES_WaveBuilder for an up to date list
///
/// Columns:
/// - Segment/Epoch
///
/// Layers hold different stimulus wave form types:
/// - Ramp
/// - GPB_Noise
/// - Sin
/// - Saw tooth
/// - Square pulse train
/// - PSC
/// - Load custom wave
Function/WAVE GetWaveBuilderWaveParam()

	variable versionOfNewWave = 2
	dfref dfr = GetWaveBuilderDataPath()

	WAVE/Z/SDFR=dfr wv = WP

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(61, -1, -1) wv
	else
		Make/N=(61, 100, 8) dfr:WP/Wave=wv

		// sets low pass filter to off (off value is related to sampling frequency)
		wv[20][][2] = 10001
		// sets coefficent count for low pass filter to a reasonable and legal Number
		wv[26][][2] = 500
		// sets coefficent count for high pass filter to a reasonable and legal Number
		wv[28][][2] = 500
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the parameter text wave for the wave builder panel
///
/// Rows:
/// - 0: name of the custom wave loaded
/// - 1-50: unused
///
/// Columns:
/// - Segment/Epoch
Function/WAVE GetWaveBuilderWaveTextParam()

	variable versionOfNewWave = 1
	dfref dfr = GetWaveBuilderDataPath()

	WAVE/T/Z/SDFR=dfr wv = WPT

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(51, -1) wv
	else
		Make/N=(51, 100)/T dfr:WPT/Wave=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns the segment parameter wave used by the wave builder panel
/// - Rows
///   - 0 - 98: epoch types using the tabcontrol indizes
///   - 99: set ITI (s)
///   - 100: total number of segments/epochs
///   - 101: total number of steps
Function/Wave GetSegmentWave()

	dfref dfr = GetWaveBuilderDataPath()
	Wave/Z/SDFR=dfr wv = SegWvType

	if(WaveExists(wv))
		return wv
	endif

	Make/N=102 dfr:SegWvType/Wave=wv

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
///
/// Layers:
/// - Just one layer...all async settings apply to every headstage, so no need to copy across multiple layers
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
///
/// Layers:
/// - Just one
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
///
/// Layers:
/// - only do one...all of the aysnc measurement values apply to all headstages, so not necessary to save in 8 layers
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
///
/// Layers:
/// - Just one
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

/// @brief Returns a wave reference to a DA data wave used for pressure pulses
///
/// Rows:
/// - data points (@ 5 microsecond intervals)
///
/// Columns:
/// - 0: DA data
Function/WAVE P_ITCDataDA(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr ITCDataDA

	if(WaveExists(ITCDataDA))
		return ITCDataDA
	endif

	Make/W/N=(PRESSURE_WAVE_DATA_SIZE) dfr:ITCDataDA/WAVE=wv

	wv = 0
	return wv
End

/// @brief Returns a wave reference to a AD data wave used for pressure pulses
///
/// Rows:
/// - data points (@ 5 microsecond intervals)
///
/// Columns:
/// - 0: AD data
Function/WAVE P_ITCDataAD(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr ITCDataAD

	if(WaveExists(ITCDataAD))
		return ITCDataAD
	endif

	Make/W/N=(PRESSURE_WAVE_DATA_SIZE) dfr:ITCDataAD/WAVE=wv

	wv = 0
	return wv
End

/// @brief Returns a wave reference to a TTL data wave used for pressure pulses on rack 0
///
/// Rows:
/// - data points (@ 5 microsecond intervals)
///
/// Columns:
/// - 0: TTL data
Function/WAVE P_ITCDataTTLRz(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr ITCDataTTLRz

	if(WaveExists(ITCDataTTLRz))
		return ITCDataTTLRz
	endif

	Make/W/N=(PRESSURE_WAVE_DATA_SIZE) dfr:ITCDataTTLRz/WAVE=wv

	wv = 0
	return wv
End

/// @brief Returns a wave reference to a TTL data wave used for pressure pulses on rack 1
///
/// Rows:
/// - data points (@ 5 microsecond intervals)
///
/// Columns:
/// - 0: TTL data
Function/WAVE P_ITCDataTTLRo(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr ITCDataTTLRo

	if(WaveExists(ITCDataTTLRo))
		return ITCDataTTLRo
	endif

	Make/W/N=(PRESSURE_WAVE_DATA_SIZE) dfr:ITCDataTTLRo/WAVE=wv

	wv = 0
	return wv
End

/// @brief Returns a wave reference to the data wave for the ITC TTL state
///
/// Rows:
/// - one row
///
/// Columns:
/// - one column
Function/WAVE P_DIO(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr DIO

	if(WaveExists(DIO))
		return DIO
	endif

	Make/N=1/W dfr:DIO/WAVE=wv

	return wv
End

/// @brief Returns a wave reference to the wave used to store the ITC device state
///
/// Rows:
/// - 1: State
/// - 2: Overflow / Underrun
/// - 3: Clipping conditions
/// - 4: Error code
///
/// Columns:
/// - 1: State
Function/WAVE P_ITCState(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr ITCState

	if(WaveExists(ITCState))
		return ITCState
	endif

	Make/I/N=4 dfr:ITCState/WAVE=wv

	return wv
End

/// @brief Returns a wave reference to the ITCDataWave used for pressure pulses
///
/// Rows:
/// - data points (@ 50 microsecond intervals)
///
/// Columns:
/// - 0: DA data
/// - 1: AD data
/// - 2: TTL data rack 0
/// - 3: TTL data rack 1
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
/// - 3: TTL rack 1 specifications
///
/// Columns:
/// - 0: Channel Type
/// - 1: Channel number (for DA or AD) or Rack (for TTL)
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
	wv[0][0] = 1 // DA
	wv[1][0] = 0 // AD
	wv[2][0] = 3 // TTL
	wv[3][0] = 3 // TTL

	wv[2][1] = 0 // TTL rack 0
	wv[3][1] = 3 // TTL rack 1

	wv[][2] = SAMPLE_INT_MICRO // 5 micro second sampling interval

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
/// - 3: TTL rack 1 specifications
/// Columns:
/// - 0: Channel Type
/// - 1: Channel number (for DA or AD) or Rack (for TTL)
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
	wv[0][0] = 1 // DA
	wv[1][0] = 0 // AD
	wv[2][0] = 3 // TTL
	wv[3][0] = 3 // TTL

	wv[2][1] = 0 // TTL rack 0
	wv[3][1] = 3 // TTL rack 1

	wv[][2]	= -1 // reset the FIFO

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
/// - 1: Channel number (for DA or AD) or Rack (for TTL)
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
	wv[0][0] = 1 // DA
	wv[1][0] = 0 // AD
	wv[2][0] = 3 // TTL
	wv[3][0] = 3 // TTL

	wv[2][1] = 0 // TTL rack 0
	wv[3][1] = 3 // TTL rack 1

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
/// - 1: List position of DAC (used for presssure control) selected for headstage .
/// - 2: Type of Instrutech DAC.
/// - 3: Device ID used by Instrutech DACs.
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

	dfref 	dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/SDFR=dfr PressureData

	if(WaveExists(PressureData))
		return PressureData
	endif

	Make/N=(8,40,1) dfr:PressureData/Wave=PressureData

	PressureData 	= nan

	SetDimLabel COLS, 0 , Approach_Seal_BrkIn_Clear,		PressureData // -1 = atmospheric pressure; 0 = approach; 1 = Seal; Break in = 2     , Clear = 3
	SetDimLabel COLS, 1 , DAC_List_Index,				PressureData // The position in the popup menu list of attached ITC devices
	SetDimLabel COLS, 2 , DAC_Type, 					PressureData // type of ITC DAC
	SetDimLabel COLS, 3 , DAC_DevID,					PressureData // ITC DAC number
	SetDimLabel COLS, 4 , DAC,							PressureData // DA channel
	SetDimLabel COLS, 5 , DAC_Gain,						PressureData
	SetDimLabel COLS, 6 , ADC,							PressureData
	SetDimLabel COLS, 7 , ADC_Gain, 					PressureData
	SetDimLabel COLS, 8 , TTL, 							PressureData // TTL channel
	SetDimLabel COLS, 9 , PSI_air,						PressureData // used to set pipette pressure on approach
	SetDimLabel COLS, 10, PSI_solution,					PressureData // used to set pipette pressure on approach
	SetDimLabel COLS, 11, PSI_slice,						PressureData // used to set pipette pressure on approach
	SetDimLabel COLS, 12, PSI_nearCell,					PressureData // used to set pipette pressure on approach
	SetDimLabel COLS, 13, PSI_SealInitial,					PressureData // used to set the minium negative pressure for sealing
	SetDimLabel COLS, 14, PSI_SealMax,					PressureData // used to set the maximum negative pressure for sealing
	SetDimLabel COLS, 15, solutionZaxis,					PressureData // solution height in microns (as measured from bottom of the chamber).
	SetDimLabel COLS, 16, sliceZaxis,						PressureData // top of slice in microns (as measured from bottom of the chamber).
	SetDimLabel COLS, 17, cellZaxis,						PressureData // height of cell (as measured from bottom of the chamber).
	SetDimLabel COLS, 18, cellXaxis,						PressureData // cell position data
	SetDimLabel COLS, 19, cellYaxis,						PressureData // cell position data
	SetDimLabel COLS, 20, PlaceHolderZero,				PressureData // used to store pressure method currently being used on cell
	SetDimLabel COLS, 21, RealTimePressure,				PressureData // // stores the last pressure pulse amplitude in psi. This is used to determine the amplitude of the next pressure pulse.
	SetDimLabel COLS, 22, LastResistanceValue,			PressureData // last steady state resistance value
	SetDimLabel COLS, 23, PeakResistanceSlope,			PressureData // Slope of the peak TP resistance value over the last 5 seconds
	/// @todo Dim label for  col 23 needs to be changed to steadStateResistanceSlope
	SetDimLabel COLS, 24, ActiveTP,						PressureData // Indicates if the TP is active on the headStage
	/// @todo If user switched headStage mode while pressure regulation is ongoing, pressure reg either needs to be turned off, or steady state slope values need to be used
	/// @todo Enable mode switching with TP running (auto stop TP, switch mode, auto startTP)
	/// @todo Enable headstate switching with TP running (auto stop TP, change headStage state, auto start TP)
	SetDimLabel COLS, 24, PeakResistanceSlopeThreshold, 	PressureData // If the PeakResistance slope is greater than the PeakResistanceSlope thershold pressure method does not need to update i.e. the pressure is "good" as it is
	SetDimLabel COLS, 25, TimeOfLastRSlopeCheck,		PressureData // The time in ticks of the last check of the resistance slopes
	SetDimLabel COLS, 26, LastPressureCommand, 		PressureData
	SetDimLabel COLS, 27, OngoingPessurePulse,			PressureData
	SetDimLabel COLS, 28, LastVcom,						PressureData
	SetDimLabel COLS, 29, ManSSPressure,				PressureData
	SetDimLabel COLS, 30, ManPPPressure,				PressureData
	SetDimLabel COLS, 31, ManPPDuration,				PressureData
	SetDimLabel COLS, 32, LastPeakR,					PressureData
	SetDimLabel COLS, 33, PeakR,						PressureData
	SetDimLabel COLS, 34, TimePeakRcheck,				PressureData
	SetDimLabel COLS, 35, PosCalConst,					PressureData
	SetDimLabel COLS, 36, NegCalConst,					PressureData
	SetDimLabel COLS, 37, ApproachNear,					PressureData
	SetDimLabel COLS, 38, SealAtm,						PressureData
	SetDimLabel COLS, 39, UserSelectedHeadStage			PressureData
	
	SetDimLabel ROWS, 0, Headstage_0, PressureData
	SetDimLabel ROWS, 1, Headstage_1, PressureData
	SetDimLabel ROWS, 2, Headstage_2, PressureData
	SetDimLabel ROWS, 3, Headstage_3, PressureData
	SetDimLabel ROWS, 4, Headstage_4, PressureData
	SetDimLabel ROWS, 5, Headstage_5, PressureData
	SetDimLabel ROWS, 6, Headstage_6, PressureData
	SetDimLabel ROWS, 7, Headstage_7, PressureData

	PressureData[][0]					= -1 // prime the wave to avoid index out of range error for popup menus and to set all pressure methods to OFF (-1)
	PressureData[][%DAC_List_Index]	= 0
	PressureData[][%DAC]			= 0
	PressureData[][%ADC]			= 0
	PressureData[][%TTL]				= 0
	PressureData[][%ApproachNear]	= 0
	PressureData[][%SealAtm]		= 0
	
	return PressureData
End

/// @brief Returns wave reference for wave used to store text used in pressure control.
///
/// creates the text storage wave if it doesn't already exist.
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

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr PressureDataTextWv

	if(WaveExists(PressureDataTextWv))
		return PressureDataTextWv
	endif

	Make/T/N=(8, 3, 1) dfr:PressureDataTextWv/WAVE= PressureDataTextWv

	SetDimLabel COLS, 0, ITC_Device, PressureDataTextWv
	SetDimLabel COLS, 1, DA_Unit, 	PressureDataTextWv
	SetDimLabel COLS, 2, AD_Unit, 	PressureDataTextWv

	SetDimLabel ROWS, 0, Headstage_0, PressureDataTextWv
	SetDimLabel ROWS, 1, Headstage_1, PressureDataTextWv
	SetDimLabel ROWS, 2, Headstage_2, PressureDataTextWv
	SetDimLabel ROWS, 3, Headstage_3, PressureDataTextWv
	SetDimLabel ROWS, 4, Headstage_4, PressureDataTextWv
	SetDimLabel ROWS, 5, Headstage_5, PressureDataTextWv
	SetDimLabel ROWS, 6, Headstage_6, PressureDataTextWv
	SetDimLabel ROWS, 7, Headstage_7, PressureDataTextWv

	PressureDataTextWv[][0] = "- none -"

	return PressureDataTextWv
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

	Make/N=(NUM_HEADSTAGES,6) dfr:actionScaleSettingsWave/Wave=wv
	
	SetDimLabel 0, -1, HeadStage, wv	
	SetDimLabel 1, 0, coarseScaleValue, wv
	SetDimLabel 1, 1, fineScaleValue, wv
	SetDimLabel 1, 2, apThreshold, wv
	SetDimLabel 1, 3, coarseTuneUse, wv
	SetDimLabel 1, 4, fineTuneUse, wv
	SetDimLabel 1, 5, result, wv
	
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

/// @brief Return the datafolder reference to the sweep config folder of an device and experiment pair
Function/DF GetAnalysisDeviceConfigFolder(expFolder, device)
	string expFolder, device
	return createDFWithAllParents(GetAnalysisDeviceConfigFolderAS(expFolder, device))
End

/// @brief Return the full path to the sweep config folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:config
Function/S GetAnalysisDeviceConfigFolderAS(expFolder, device)
	string expFolder, device

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":config"
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
/// The "experiment" column in the second layer maps to the corresponding row in he experimentMap.
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
/// @}
