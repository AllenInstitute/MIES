#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_WAVEGETTERS
#endif // AUTOMATED_TESTING

/// @file MIES_WaveDataFolderGetters.ipf
///
/// @brief Collection of Wave and Datafolder getter functions
///
/// - All functions with return types `DF` or `Wave` return an existing wave or datafolder.
/// - Prefer functions which return a `DFREF` over functions which return strings.
///   The latter ones are only useful if you need to know if the folder exists.
/// - Modifying wave getter functions might require to introduce wave versioning, see @ref WaveVersioningSupport

static Constant    ANALYSIS_BROWSER_LISTBOX_WAVE_VERSION           = 2
static Constant    ANALYSIS_BROWSER_FOLDER_LISTBOX_WAVE_VERSION    = 1
static Constant    ANALYSIS_BROWSER_FOLDERCOL_LISTBOX_WAVE_VERSION = 1
static Constant    ANALYSIS_BROWSER_FOLDERSEL_LISTBOX_WAVE_VERSION = 1
static Constant    NUM_COLUMNS_LIST_WAVE                           = 14
static StrConstant WAVE_NOTE_LAYOUT_KEY                            = "WAVE_LAYOUT_VERSION"

static Constant WAVE_TYPE_NUMERICAL = 0x1
static Constant WAVE_TYPE_TEXTUAL   = 0x2

static Constant PULSE_WAVE_VERSION = 4

static StrConstant TP_SETTINGS_LABELS = "bufferSize;resistanceTol;sendToAllHS;baselinePerc;durationMS;amplitudeVC;amplitudeIC;autoTPEnable;autoAmpMaxCurrent;autoAmpVoltage;autoAmpVoltageRange;autoTPPercentage;autoTPInterval;autoTPCycleID"

static StrConstant LOGBOOK_SUFFIX_SORTEDKEYS        = "_sorted"
static StrConstant LOGBOOK_SUFFIX_SORTEDKEYSINDICES = "_indices"

static Constant SWEEP_SETTINGS_WAVE_VERSION = 41

/// @brief Return a wave reference to the corresponding Logbook keys wave from an values wave input
threadsafe Function/WAVE GetLogbookValuesFromKeys(WAVE keyWave)

	string wName = NameOfWave(keyWave)
	DFREF  dfr   = GetWavesDataFolderDFR(keyWave)

	strswitch(wName)
		case LBN_NUMERICAL_KEYS_NAME:
			return dfr:$LBN_NUMERICAL_VALUES_NAME
		case LBN_TEXTUAL_KEYS_NAME:
			return dfr:$LBN_TEXTUAL_VALUES_NAME
		case LBN_NUMERICALRESULT_KEYS_NAME:
			return dfr:$LBN_NUMERICALRESULT_VALUES_NAME
		case LBN_TEXTUALRESULT_KEYS_NAME:
			return dfr:$LBN_TEXTUALRESULT_VALUES_NAME
		default:
			FATAL_ERROR("Can not resolve logbook values wave from key wave: " + wName)
	endswitch
End

/// @brief Return a wave reference to the corresponding Logbook values wave from an keys wave input
threadsafe Function/WAVE GetLogbookKeysFromValues(WAVE valuesWave)

	string wName = NameOfWave(valuesWave)
	DFREF  dfr   = GetWavesDataFolderDFR(valuesWave)

	strswitch(wName)
		case LBN_NUMERICAL_VALUES_NAME:
			return dfr:$LBN_NUMERICAL_KEYS_NAME
		case LBN_TEXTUAL_VALUES_NAME:
			return dfr:$LBN_TEXTUAL_KEYS_NAME
		case LBN_NUMERICALRESULT_VALUES_NAME:
			return dfr:$LBN_NUMERICALRESULT_KEYS_NAME
		case LBN_TEXTUALRESULT_VALUES_NAME:
			return dfr:$LBN_TEXTUALRESULT_KEYS_NAME
		default:
			FATAL_ERROR("Can not resolve logbook keys wave from values wave: " + wName)
	endswitch
End

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
Function/WAVE GetChanAmpAssign(string device)

	DFREF    dfr              = GetDevicePath(device)
	variable versionOfNewWave = 3

	WAVE/Z/D/SDFR=dfr wv = ChanAmpAssign

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/D/N=(10, NUM_HEADSTAGES, -1, -1) wv
	else
		Make/D/N=(10, NUM_HEADSTAGES) dfr:ChanAmpAssign/WAVE=wv
		wv = NaN

		// we don't have dimension labels yet
		if(IsITC1600(device))
			// Use AD channels 0-3 and then 8-11 so that
			// they are all on the same rack
			wv[0][0, 7] = q
			wv[2][0, 7] = (q <= 3) ? q : (q + 4)
			wv[4][0, 7] = q
			wv[6][0, 7] = (q <= 3) ? q : (q + 4)
		else
			wv[0][0, 3] = q
			wv[2][0, 3] = q
			wv[4][0, 3] = q
			wv[6][0, 3] = q
		endif

		wv[1, 7; 2][] = 1
	endif

	SetDimLabel ROWS, 0, VC_DA, wv
	SetDimLabel ROWS, 1, VC_DAGain, wv
	SetDimLabel ROWS, 2, VC_AD, wv
	SetDimLabel ROWS, 3, VC_ADGain, wv

	SetDimLabel ROWS, 4, IC_DA, wv
	SetDimLabel ROWS, 5, IC_DAGain, wv
	SetDimLabel ROWS, 6, IC_AD, wv
	SetDimLabel ROWS, 7, IC_ADGain, wv

	SetDimLabel ROWS, 8, AmpSerialNo, wv
	SetDimLabel ROWS, 9, AmpChannelID, wv

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
Function/WAVE GetChanAmpAssignUnit(string device)

	DFREF    dfr              = GetDevicePath(device)
	variable versionOfNewWave = 1

	WAVE/Z/T/SDFR=dfr wv = ChanAmpAssignUnit

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// do nothing
	else
		Make/T/N=(4, NUM_HEADSTAGES) dfr:ChanAmpAssignUnit/WAVE=wv
		wv = ""

		wv[0][] = GetDAChannelUnit(V_CLAMP_MODE)
		wv[1][] = GetADChannelUnit(V_CLAMP_MODE)
		wv[2][] = GetDAChannelUnit(I_CLAMP_MODE)
		wv[3][] = GetADChannelUnit(I_CLAMP_MODE)
	endif

	SetDimLabel ROWS, 0, VC_DAUnit, wv
	SetDimLabel ROWS, 1, VC_ADUnit, wv
	SetDimLabel ROWS, 2, IC_DAUnit, wv
	SetDimLabel ROWS, 3, IC_ADUnit, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @defgroup WaveVersioningSupport Wave versioning support
///
/// The wave getter functions always return an existing wave.
/// This can result in problems if the layout of the wave changes.
///
/// Layout in this context means:
/// - Sizes of all dimensions
/// - Labels of all dimensions
/// - Wave data type
/// - Prefilled wave content or wave note
///
/// This also means that the name and location of the wave does *not* influence
/// the wave version. Use UpgradeWaveLocationAndGetIt() if you need to move the
/// wave. The main reason is that for being able to query the wave version you
/// already need to know where it is.
///
/// In order to enable smooth upgrades between old and new wave layouts
/// the following code pattern can be used:
/// \rst
/// .. code-block:: igorpro
///
/// 	Function/Wave GetMyWave(device)
/// 		string device
///
/// 		DFREF dfr = GetMyPath(device)
/// 		variable versionOfNewWave = 2
///
/// 		Wave/Z/SDFR=dfr wv = myWave
///
/// 		if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
/// 			return wv
/// 		elseif(WaveExists(wv)) // handle upgrade
/// 			if(WaveVersionIsAtLeast(wv, 1)) // 1->2
/// 				Redimension/D wv
/// 			else // no-version->2
/// 				// change the required dimensions and leave all others untouched with -1
/// 				// the extended dimensions are initialized with zero
/// 				Redimension/D/N=(10, -1, -1, -1) wv
/// 			endif
/// 		else
/// 			Make/R/N=(10, 2) dfr:myWave/Wave=wv
/// 		endif
///
/// 		SetWaveVersion(wv, versionOfNewWave)
///
/// 		return wv
/// 	End
/// \endrst
///
/// Now everytime the layout of `myWave` changes, raise `versionOfNewWave` by 1
/// and add a new `WaveVersionIsAtLeast` branch. When `GetMyWave` is called the
/// first time, the wave is redimensioned or rebuilt as double wave depending
/// on the current version, and on successive calls the wave is returned as is.
///
/// Hints:
/// - Wave layout versioning is *mandatory* if you change the layout of the wave
/// - Wave layout versions start with 1 and are integers
/// - Rule of thumb: Raise the version if you change anything in or below the `Make` line
/// - Wave versioning needs a special wave note style, see @ref GetNumberFromWaveNote
///@{

/// @brief Check if wv exists and has the correct version
/// UTF_NOINSTRUMENTATION
threadsafe static Function ExistsWithCorrectLayoutVersion(WAVE/Z wv, variable versionOfNewWave)

	// The equality check ensures that you can also downgrade, e.g. from version 5 to 4, although this is *strongly* discouraged.
	return WaveExists(wv) && GetWaveVersion(wv) == versionOfNewWave
End

/// @brief Check if the given wave's version is equal or larger than the given version, if version is not set false is returned
threadsafe static Function WaveVersionIsAtLeast(WAVE/Z wv, variable existingVersion)

	variable waveVersion

	ASSERT_TS(WaveExists(wv), "Wave does not exist")
	ASSERT_TS(IsValidWaveVersion(existingVersion), "existing version must be a positive integer")
	waveVersion = GetWaveVersion(wv)

	return !isNaN(waveVersion) && waveVersion >= existingVersion
End

/// @brief Returns 1 if the wave has a valid version information attached, 0 otherwise
threadsafe static Function IsWaveVersioned(WAVE wv)

	return IsValidWaveVersion(GetWaveVersion(wv))
End

/// @brief Check if the given wave's version is smaller than the given version, if version is not set true is returned
threadsafe static Function WaveVersionIsSmaller(WAVE/Z wv, variable existingVersion)

	variable waveVersion

	ASSERT_TS(WaveExists(wv), "Wave does not exist")
	ASSERT_TS(IsValidWaveVersion(existingVersion), "existing version must be a positive integer")
	waveVersion = GetWaveVersion(wv)

	return isNaN(waveVersion) || waveVersion < existingVersion
End

/// @brief return the Version of the Wave, returns NaN if no version was set
/// UTF_NOINSTRUMENTATION
threadsafe Function GetWaveVersion(WAVE/Z wv)

	return GetNumberFromWaveNote(wv, WAVE_NOTE_LAYOUT_KEY)
End

/// @brief Set the wave layout version of wave
threadsafe static Function SetWaveVersion(WAVE wv, variable val)

	ASSERT_TS(IsValidWaveVersion(val), "val must be a positive and non-zero integer")
	SetNumberInWaveNote(wv, WAVE_NOTE_LAYOUT_KEY, val)
End

/// @brief A valid wave version is a positive non-zero integer
threadsafe static Function IsValidWaveVersion(variable value)

	return value > 0 && IsInteger(value)
End

/// @brief Clear the wave note but keep any valid wave version
Function ClearWaveNoteExceptWaveVersion(WAVE wv)

	variable version = GetWaveVersion(wv)

	Note/K wv

	if(IsValidWaveVersion(version))
		SetWaveVersion(wv, version)
	endif
End

/// @brief Move/Rename a datafolder across different locations
///
/// Both parameters must be absolute datafolder locations.
/// Cases where both exist are also handled gracefully.
///
/// \rst
/// .. code-block:: igorpro
///
///		Function/DF GetMyFolder()
///			return UpgradeDataFolderLocation("root:old", "root:new")
///		End
/// \endrst
///
/// @return DFREF to the `newFolder` with the contents of `oldFolder`
threadsafe Function/DF UpgradeDataFolderLocation(string oldFolder, string newFolder)

	string oldName, newName, from, to, msg, tempFolder

	ASSERT_TS(!IsEmpty(oldFolder), "oldFolder must not be empty")
	ASSERT_TS(!IsEmpty(newFolder), "newFolder must not be empty")
	ASSERT_TS(!IsValidObjectName(oldFolder), "oldFolder must be a valid object name (non-liberal)")
	ASSERT_TS(!IsValidObjectName(newFolder), "newFolder must be a valid object name (non-liberal)")
	ASSERT_TS(GrepString(oldFolder, "(?i)^root:"), "oldFolder must be an absolute path")
	ASSERT_TS(GrepString(newFolder, "(?i)^root:"), "newFolder must be an absolute path")

	oldFolder = RemoveEnding(oldFolder, ":")
	newFolder = RemoveEnding(newFolder, ":")

	if(!DataFolderExists(oldFolder))
		return createDFWithAllParents(newFolder)
	elseif(DataFolderExists(newFolder))

		if(!DataFolderRefsEqual($oldFolder, $newFolder))
			printf "WARNING! The location %s was supposed to be renamed/moved but the old location still exists.\r", oldFolder
			printf "Returning the new location and ignoring the old one.\r"
		endif

		return $newFolder
	endif

	sprintf msg, "%s -> %s", oldFolder, newFolder
	DEBUGPRINT_TS(msg)

	// oldFolder exists and newFolder not -> move it
	// 1: Rename to unique name
	// 2: Move into new location
	// 3: Rename to target name
	oldName = GetDataFolder(0, $oldFolder)
	newName = GetDataFolder(0, createDFWithAllParents(newFolder))
	KillOrMoveToTrash(dfr = $newFolder)

	sprintf msg, "%s -> %s", oldName, newName
	DEBUGPRINT_TS(msg)

	tempFolder = UniqueDataFolderName($"root:", "temp")
	NewDataFolder $tempFolder

	MoveDataFolder $oldFolder, $tempFolder
	RenameDataFolder $(tempFolder + ":" + oldName), $newName

	from = tempFolder + ":" + newName
	to   = RemoveEnding(newFolder, ":" + newName)

	sprintf msg, "%s -> %s", from, to
	DEBUGPRINT_TS(msg)

	MoveDataFolder $from, $to
	KillOrMoveToTrash(dfr = $tempFolder)

	return $newFolder
End

/// @brief Rename/Move a wave to a new location
///
/// Valid transformations (and all combinations of them):
/// - Moving into a new datafolder
/// - Renaming to a new name
/// - Nothing
///
/// The function is idempotent (i.e. it can be called also on already relocated
/// waves). Cases where new == old are also handled gracefully.
///
/// \rst
/// .. code-block:: igorpro
///
///		Function/WAVE GetMyWave(device)
///			string device
///
///			variable versionOfNewWave = 1
///			string newName = "newAndNiceName"
///			DFREF newDFR = GetNewAndFancyFolder(device)
///
///			STRUCT WaveLocationMod p
///			p.dfr     = $(GetSomeFolder(device) + ":oldSubFolder")
///			p.newDFR  = newDFR
///			p.name    = "oldAndUglyName"
///			p.newName = newName
///
///			WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
///
///			if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
///				return wv
///			elseif(WaveExists(wv))
///				// handle upgrade
///			else
///				Make/R/N=(10, 2) newDFR:newName/Wave=wv
///			end
///
///			SetWaveVersion(wv, versionOfNewWave)
///
///			return wv
///		End
/// \endrst
///
/// @returns wave reference to the wave in the new location, an invalid one if the wave does
/// not exist at the specified former location
Function/WAVE UpgradeWaveLocationAndGetIt(STRUCT WaveLocationMod &p)

	ASSERT(strlen(p.name) > 0, "Invalid name")

	if(!DataFolderExistsDFR(p.newDFR))
		ASSERT(DataFolderExistsDFR(p.dfr), "Invalid dfr")
		p.newDFR = p.dfr
	endif

	if(!(strlen(p.newName) > 0))
		p.newName = p.name
	endif

	WAVE/Z/SDFR=p.newDFR dest = $p.newName

	if(DataFolderExistsDFR(p.dfr))
		WAVE/Z/SDFR=p.dfr src = $p.name
	endif

	if(WaveExists(dest))
		if(!WaveExists(src))
			// wave already relocated
			return dest
		elseif(WaveRefsEqual(src, dest))
			// nothing to rename/move
			return dest
		else
			// both waves exists but are *not* equal
			printf "WARNING! The wave %s was supposed to be renamed/moved but the old wave still exists\r", p.name
			printf "Returning dest wave and ignoring src\r"
			return dest
		endif
	else // dest does not exist
		if(!WaveExists(src))
			// and src also not, the wave was not yet created
			return $""
		endif

		ASSERT(IsValidObjectName(p.newName), "Invalid/Liberal wave name for newName")
		MoveWave src, p.newDFR:$p.newName
		RemoveEmptyDataFolder(p.dfr)
		return src
	endif

	FATAL_ERROR("impossible case")
End

///@}

/// @brief Return a wave reference to the tp result async buffer wave
///
/// Rows:
/// - buffered partial result entries
///
/// Column 0 (ASYNCDATA):
///   - Layers:
///     - 0: marker
///     - 1: received channels
/// Column 1+: defined through TP_ANALYSIS_DATA_LABELS
///
/// Layers:
/// - NUM_HEADSTAGES
Function/WAVE GetTPResultAsyncBuffer(string device)

	variable versionOfNewWave = 2
	variable numCols          = ItemsInList(TP_ANALYSIS_DATA_LABELS) + 1

	DFREF dfr = GetDeviceTestPulse(device)

	WAVE/Z/D/SDFR=dfr wv = TPResultAsyncBuffer

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	numCols = ItemsInList(TP_ANALYSIS_DATA_LABELS) + 1
	if(WaveExists(wv))
		Redimension/N=(-1, numCols, -1) wv
	else
		Make/N=(0, numCols, NUM_HEADSTAGES)/D dfr:TPResultAsyncBuffer/WAVE=wv
	endif

	FastOp wv = (NaN)

	SetDimLabel COLS, 0, ASYNCDATA, wv
	SetDimensionLabels(wv, TP_ANALYSIS_DATA_LABELS, COLS, startPos = 1)

	SetDimLabel LAYERS, 0, MARKER, wv
	SetDimLabel LAYERS, 1, REC_CHANNELS, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the channel clamp mode wave
///
/// Only specialized code which does not have a headstage, or needs to know the
/// clamp mode for unassociated channels, should use this function.
///
/// Rows:
/// - Channel numbers
///
/// Columns:
/// - 0: DAC
/// - 1: ADC
///
/// Layers:
/// - 0: Clamp Mode
/// - 1: Headstage
Function/WAVE GetChannelClampMode(string device)

	DFREF    dfr              = GetDevicePath(device)
	variable versionOfNewWave = 1

	WAVE/Z/SDFR=dfr wv = ChannelClampMode

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, -1, 2) wv

		// prefill with existing algorithm for easier upgrades
		wv[][%DAC][1] = GetHeadstageFromSettings(device, XOP_CHANNEL_TYPE_DAC, p, wv[p][%DAC][0])
		wv[][%ADC][1] = GetHeadstageFromSettings(device, XOP_CHANNEL_TYPE_ADC, p, wv[p][%ADC][0])
	else
		Make/R/N=(NUM_AD_CHANNELS, 2, 2) dfr:ChannelClampMode/WAVE=wv
		wv = NaN
	endif

	SetDimLabel COLS, 0, DAC, wv
	SetDimLabel COLS, 1, ADC, wv

	SetDimLabel LAYERS, 0, ClampMode, wv
	SetDimLabel LAYERS, 1, Headstage, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return properties for the headstages *during* TP/DAQ
///
/// @sa DC_UpdateHSProperties()
Function/WAVE GetHSProperties(string device)

	DFREF    dfr              = GetDevicePath(device)
	variable versionOfNewWave = 1

	WAVE/Z/SDFR=dfr wv = HSProperties

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(NUM_HEADSTAGES, 4) dfr:HSProperties/WAVE=wv
	endif

	wv = NaN

	SetDimLabel COLS, 0, Enabled, wv
	SetDimLabel COLS, 1, ADC, wv
	SetDimLabel COLS, 2, DAC, wv
	SetDimLabel COLS, 3, ClampMode, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the DAQ devices folder "root:mies:HardwareDevices"
Function/DF GetDAQDevicesFolder()

	return UpgradeDataFolderLocation(GetMiesPathAsString() + ":ITCDevices", GetDAQDevicesFolderAsString())
End

/// @brief Return a data folder reference to the DAQ devices folder
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S GetDAQDevicesFolderAsString()

	return GetMiesPathAsString() + ":HardwareDevices"
End

/// @brief Return the active DAQ devices timer folder "root:mies:HardwareDevices:ActiveDAQDevices:Timer"
Function/DF GetActiveDAQDevicesTimerFolder()

	return createDFWithAllParents(GetActiveDAQDevicesTimerAS())
End

/// @brief Return a data folder reference to the active DAQ devices timer folder
Function/S GetActiveDAQDevicesTimerAS()

	return GetActiveDAQDevicesFolderAS() + ":Timer"
End

/// @brief Return the active DAQ devices folder "root:mies:HardwareDevices:ActiveDAQDevices"
Function/DF GetActiveDAQDevicesFolder()

	return createDFWithAllParents(GetActiveDAQDevicesFolderAS())
End

/// @brief Return a data folder reference to the active DAQ devices folder
Function/S GetActiveDAQDevicesFolderAS()

	return GetDAQDevicesFolderAsString() + ":ActiveDAQDevices"
End

/// @brief Return a datafolder reference to the device type folder
Function/DF GetDeviceTypePath(string deviceType)

	return createDFWithAllParents(GetDeviceTypePathAsString(deviceType))
End

/// @brief Return the path to the device type folder, e.g. root:mies:HardwareDevices:ITC1600
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S GetDeviceTypePathAsString(string deviceType)

	return GetDAQDevicesFolderAsString() + ":" + deviceType
End

/// @brief Return a datafolder reference to the device folder
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/DF GetDevicePath(string device)

	return createDFWithAllParents(GetDevicePathAsString(device))
End

/// @brief Return the path to the device info folder, e.g. root:mies:HardwareDevices:DeviceInfo
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S GetDeviceInfoPathAsString()

	return GetDAQDevicesFolderAsString() + ":DeviceInfo"
End

/// @brief Return a datafolder reference to the device info folder
threadsafe Function/DF GetDeviceInfoPath()

	return createDFWithAllParents(GetDeviceInfoPathAsString())
End

/// @brief Return the path to the device folder, e.g. root:mies:HardwareDevices:ITC1600:Device0
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S GetDevicePathAsString(string device)

	string deviceType, deviceNumber
	ASSERT_TS(ParseDeviceString(device, deviceType, deviceNumber), "Invalid/Non-locked device")

	switch(GetHardwareType(device))
		case HARDWARE_NI_DAC:
			return GetDeviceTypePathAsString(deviceType)
			break
		case HARDWARE_ITC_DAC:
			return GetDeviceTypePathAsString(deviceType) + ":Device" + deviceNumber
			break
		case HARDWARE_SUTTER_DAC:
			return GetDeviceTypePathAsString(deviceType)
			break
		default:
			FATAL_ERROR("Invalid hardware type")
	endswitch
End

/// @brief Return a datafolder reference to the device data folder
Function/DF GetDeviceDataPath(string device)

	return createDFWithAllParents(GetDeviceDataPathAsString(device))
End

/// @brief Return the path to the device folder, e.g. root:mies:HardwareDevices:ITC1600:Device0:Data
///
/// UTF_NOINSTRUMENTATION
Function/S GetDeviceDataPathAsString(string device)

	return GetDevicePathAsString(device) + ":Data"
End

/// @brief Returns a data folder reference to the mies base folder
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/DF GetMiesPath()

	return createDFWithAllParents(GetMiesPathAsString())
End

/// @brief Returns the base folder for all MIES functionality, e.g. root:MIES
/// UTF_NOINSTRUMENTATION
threadsafe Function/S GetMiesPathAsString()

	return "root:" + DF_NAME_MIES
End

/// @brief Returns a data folder reference to the sweep formula folder
threadsafe Function/DF GetSweepFormulaPath()

	return createDFWithAllParents(GetSweepFormulaPathAsString())
End

/// @brief Returns the temporary folder for Sweep formula, e.g. root:MIES:SweepFormula
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S GetSweepFormulaPathAsString()

	return GetMiesPathAsString() + ":SweepFormula"
End

/// @brief Return a Nx3 wave usable for setting trace colors
Function/WAVE GetColorWave(variable numEntries)

	Make/FREE/N=(numEntries, 3)/R traceColors
	SetDimensionLabels(traceColors, "Red;Green;Blue", COLS)

	return traceColors
End

/// @brief Returns a data folder reference to the call once folder
threadsafe Function/DF GetCalledOncePath()

	return createDFWithAllParents(GetCalledOncePathAsString())
End

/// @brief Returns a name of the data folder for the call once folder, e.g. root:MIES:CalledOnce
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S GetCalledOncePathAsString()

	return GetMiesPathAsString() + ":CalledOnce"
End

/// @brief Return a datafolder reference to a subfolder below `dfr` for splitted sweep specific data, e.g. dfr:X_5
///
/// UTF_NOINSTRUMENTATION
Function/DF GetSingleSweepFolder(DFREF dfr, variable sweepNo)

	return createDFWithAllParents(GetSingleSweepFolderAsString(dfr, sweepNo))
End

/// @brief Return the path to a subfolder below `dfr` for splitted sweep specific data
Function/S GetSingleSweepFolderAsString(DFREF dfr, variable sweepNo)

	ASSERT(DataFolderExistsDFR(dfr), "dfr must exist")
	ASSERT(IsValidSweepNumber(sweepNo), "Invalid sweepNo")

	// folder name starts with X as only liberal names are allowed to start with numbers. And we don't want liberal names.
	return GetDataFolder(1, dfr) + "X_" + num2str(sweepNo)
End

/// @brief Return the DAQ data wave
///
/// ITC hardware:
/// - 2D signed 16bit integer wave, the colums are for the channel
///
/// NI/SU hardware:
/// - Wave reference wave, one referencing each channel
///
/// Rows:
/// - data
///
/// Columns:
/// - one for each active DA, AD, TTL channel (in that order)
///
/// For scaling and gain information see SWS_GetChannelGains().
///
/// Note:
/// #TP_PROPERTIES_HASH: Unique hash for a combination of all properties which influence the test pulse.
///
/// @param device device
/// @param mode       One of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
Function/WAVE GetDAQDataWave(string device, variable mode)

	string name

	DFREF    dfr          = GetDevicePath(device)
	variable hardwareType = GetHardwareType(device)

	switch(mode)
		case DATA_ACQUISITION_MODE:
			name = "DAQDataWave_DAQ"
			break
		case TEST_PULSE_MODE:
			name = "DAQDataWave_TP"
			break
		default:
			FATAL_ERROR("Invalid dataAcqOrTP")
	endswitch

	WAVE/Z/W/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			Make/W/N=(1, NUM_DA_TTL_CHANNELS) dfr:$name/WAVE=wv
			break
		case HARDWARE_NI_DAC: // fallthrough
		case HARDWARE_SUTTER_DAC:
			Make/WAVE/N=(NUM_DA_TTL_CHANNELS) dfr:$name/WAVE=wv_ni
			WAVE wv = wv_ni
			break
		default:
			FATAL_ERROR("Unsupported hardware type")
			break
	endswitch

	SetStringInWaveNote(wv, TP_PROPERTIES_HASH, "n. a.")

	return wv
End

Function/WAVE GetSUCompositeTTLWave(string device)

	string name = "SU_OutputTTLComposite"

	DFREF dfr = GetDevicePath(device)

	WAVE/Z/D/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	Make/D/N=(0) dfr:$name/WAVE=wv

	return wv
End

/// @brief Get the single NI/Sutter channel waves
///
/// Special use function, normal callers should use GetDAQDataWave()
/// instead.
Function/WAVE GetNIDAQChannelWave(string device, variable channel, variable mode)

	string name, prefix
	variable hardwareType = GetHardwareType(device)

	switch(hardwareType)
		case HARDWARE_NI_DAC:
			prefix = "NI"
			break
		case HARDWARE_SUTTER_DAC:
			prefix = "SU"
			break
		default:
			FATAL_ERROR("unsupported device type")
	endswitch

	name = prefix + "_Channel" + num2str(channel)

	switch(mode)
		case DATA_ACQUISITION_MODE:
			name += "_DAQ"
			break
		case TEST_PULSE_MODE:
			name += "_TP"
			break
		default:
			FATAL_ERROR("Invalid dataAcqOrTP")
	endswitch

	DFREF dfr = GetDevicePath(device)

	WAVE/Z/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	// type does not matter as we change it in DC_MakeNIChannelWave anyway
	Make/N=(0) dfr:$name/WAVE=wv

	SetStringInWaveNote(wv, TP_PROPERTIES_HASH, "n. a.")

	return wv
End

/// @brief Get a single point output wave for Sutter device
Function/WAVE GetSutterSingleSampleDACOutputWave(string device)

	variable samplingInterval
	string name = "SU_SingleSample_DA"

	DFREF dfr = GetDevicePath(device)

	WAVE/Z/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	Make/N=1 dfr:$name/WAVE=wv
	samplingInterval = SI_CalculateMinSampInterval(device, DATA_ACQUISITION_MODE, XOP_CHANNEL_TYPE_DAC)
	SetScale/P x, 0, samplingInterval * MICRO_TO_ONE, "s", wv

	return wv
End

/// @brief Get a single point input wave for Sutter device
Function/WAVE GetSutterSingleSampleADCInputWave(string device)

	variable samplingInterval
	string name = "SU_SingleSample_AD"

	DFREF dfr = GetDevicePath(device)

	WAVE/Z/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	Make/N=1 dfr:$name/WAVE=wv
	samplingInterval = SI_CalculateMinSampInterval(device, DATA_ACQUISITION_MODE, XOP_CHANNEL_TYPE_ADC)
	SetScale/P x, 0, samplingInterval * MICRO_TO_ONE, "s", wv

	return wv
End

static Constant EPOCHS_WAVE_VERSION = 3

/// @brief Return the epochs text wave
///
/// Rows:
/// - epochs
///
/// Column numbers must use global column number constants @sa epochColumnNumber.
///
/// Columns:
/// - 0: Start time in sec
/// - 1: End time in sec
/// - 2: Tags
/// - 3: Tree Level
///
/// Layers: index the GUI channel numbers
/// - NUM_DA_TTL_CHANNELS
///
/// Chunks: index the XOP channel types
/// - XOP_CHANNEL_TYPE_COUNT
///
/// ## Version History
///
/// ### Wave
///
/// - 1: Initial version
/// - 2: Renamed column `Name` to `Tags`
/// - 3: Added chunks dimension indexing over channel types
///
/// ### Tags format
///
/// Initial version in a2172f03 (Added generations of epoch information wave,
/// 2019-05-22), parsed in PA plot since 4e534e29 (Pulse Averaging: Pulse
/// starting times are now read from the lab notebook, 2020-10-07).
///
/// In d150d896 (DC_AddEpochsFromStimSetNote: Add sub sub epoch information, 2021-02-02)
/// tree level 3 info for pulse train pulses was added, which is read out since
/// ba209bbd (PA plot: Gather more pulse infos, 2021-02-02).
///
/// And in 2371cfb0 (Epochs: Revise naming, 2021-09-22) we changed the naming
/// of the tags and also adapted PA_RetrievePulseStartTimesFromEpochs.
///
/// For these three formats we have tests in RPI_WorksWithOldData(). When
/// changing the tags format this test needs to be updated.
Function/WAVE GetEpochsWave(string device)

	string name = "EpochsWave"

	DFREF             dfr = GetDevicePath(device)
	WAVE/Z/T/SDFR=dfr wv  = $name

	if(ExistsWithCorrectLayoutVersion(wv, EPOCHS_WAVE_VERSION))
		return wv
	endif

	if(WaveExists(wv))
		if(WaveVersionIsSmaller(wv, 2))
			Redimension/N=(MINIMUM_WAVE_SIZE, 4, NUM_DA_TTL_CHANNELS) wv
		endif
		if(WaveVersionIsSmaller(wv, 3))
			Redimension/N=(MINIMUM_WAVE_SIZE, 4, NUM_DA_TTL_CHANNELS, XOP_CHANNEL_TYPE_COUNT) wv
			wv[][][][XOP_CHANNEL_TYPE_DAC] = wv[p][q][r][0]
			wv[][][][0]                    = ""
		endif

		SetEpochsDimensionLabelAndVersion(wv)
	else
		WAVE/T wv = GetEpochsWaveAsFree()
		MoveWave wv, dfr:$name
	endif

	return wv
End

Function/WAVE GetEpochsWaveAsFree()

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE, 4, NUM_DA_TTL_CHANNELS, XOP_CHANNEL_TYPE_COUNT) wv

	SetEpochsDimensionLabelAndVersion(wv)

	return wv
End

static Function SetEpochsDimensionLabelAndVersion(WAVE wv)

	SetEpochsDimensionLabelsSingleChannel(wv)

	SetDimLabel CHUNKS, XOP_CHANNEL_TYPE_ADC, ADC, wv
	SetDimLabel CHUNKS, XOP_CHANNEL_TYPE_DAC, DAC, wv
	SetDimLabel CHUNKS, XOP_CHANNEL_TYPE_TTL, TTL, wv

	SetWaveVersion(wv, EPOCHS_WAVE_VERSION)
End

threadsafe Function SetEpochsDimensionLabelsSingleChannel(WAVE wv)

	SetDimLabel COLS, EPOCH_COL_STARTTIME, StartTime, wv
	SetDimLabel COLS, EPOCH_COL_ENDTIME, EndTime, wv
	SetDimLabel COLS, EPOCH_COL_TAGS, Tags, wv
	SetDimLabel COLS, EPOCH_COL_TREELEVEL, TreeLevel, wv
End

/// @brief Return the folder for the epoch visualization waves
///        below the sweepfolder/databrowser specific folder
Function/DF GetEpochsVisualizationFolder(DFREF dfr)

	return createDFWithAllParents(GetDataFolder(1, dfr) + "epochs")
End

/// @brief Return the DAQ config wave
///
/// Rows:
/// - One for each channel, the order is DA, AD, TTL (same as in the DAQDataWave)
///
/// Columns:
/// - channel type, one of @ref XopChannelConstants
/// - channel number (0-based)
/// - sampling interval in microseconds (1e-6)
/// - decimation mode (always zero)
/// - data offset
/// - headstage number
/// - clamp mode
///
/// The wave note holds a list of channel units. The order
/// is the same as the rows. TTL channels don't have units. Querying the
/// channel unit should always be done via AFH_GetChannelUnit() or AFH_GetChannelUnits().
///
/// This wave is also used for NI devices as configuration template. There is one difference though:
/// While for ITC devices there is one TTL row for each rack,
/// for NI devices there is one TTL row for each channel (up to 8 currently)
/// The channel number column holds the hardware channel number for the NI device
///
/// ITC hardware:
/// The number of TTL bits which are stored in each TTL channel is hardware
/// dependent and can be queried with HW_ITC_GetRackRange().
///
/// Version 1 changes:
/// - Columns now have dimension labels
/// - One more column with the channel data offset
/// - Due to the wave versioning the channel unit is now stored with the
///   #CHANNEL_UNIT_KEY as key and it is now separated not with semicolon
///   anymore but a comma.
///
/// Version 2 changes:
/// - DAQChannelType column added
///
/// Version 3 changes:
/// - Change wave to double precision
/// - Headstage column added
/// - ClampMode column added
Function/WAVE GetDAQConfigWave(string device)

	DFREF dfr = GetDevicePath(device)

	WAVE/Z/D/SDFR=dfr wv = DAQConfigWave

	// On version upgrade also adapt function IsValidConfigWave
	if(ExistsWithCorrectLayoutVersion(wv, DAQ_CONFIG_WAVE_VERSION))
		return wv
	endif

	if(WaveExists(wv))
		// do sequential version upgrade
		if(WaveVersionIsSmaller(wv, 1))
			// this version adds the Offset column
			Redimension/I/N=(-1, 5) wv
			wv[][4] = 0
			Note/K wv
		endif
		if(WaveVersionIsSmaller(wv, 2))
			// this version adds the DAQChannelType column
			// In previous version of TPduringDAQ only DAQ type channels existed
			Redimension/I/N=(-1, 6) wv
			wv[][5] = DAQ_CHANNEL_TYPE_DAQ
			Note/K wv
		endif
		if(WaveVersionIsSmaller(wv, 3))
			// this version adds the HEADSTAGE and CLAMPMODE column
			Redimension/D/N=(-1, 8) wv
			wv[][6] = NaN
			wv[][7] = NaN
			Note/K wv
		endif
	else
		Make/D/N=(2, 8) dfr:DAQConfigWave/WAVE=wv
	endif

	SetDimLabel COLS, 0, ChannelType, wv
	SetDimLabel COLS, 1, ChannelNumber, wv
	SetDimLabel COLS, 2, SamplingInterval, wv
	SetDimLabel COLS, 3, DecimationMode, wv
	SetDimLabel COLS, 4, Offset, wv
	SetDimLabel COLS, 5, DAQChannelType, wv
	SetDimLabel COLS, 6, HEADSTAGE, wv
	SetDimLabel COLS, 7, CLAMPMODE, wv

	SetWaveVersion(wv, DAQ_CONFIG_WAVE_VERSION)
	AddEntryIntoWaveNoteAsList(wv, CHANNEL_UNIT_KEY, str = "")

	return wv
End

static Constant DQM_ACTIVE_DEV_WAVE_VERSION = 3

/// @brief Returns a reference to the wave of active devices for data acquisition in multi device mode
///
/// The wave is used in data acquisition in multiple device mode to keep track of active devices.
///
/// Columns:
/// - DeviceID id of an active device
/// - ADChannelToMonitor index of first active AD channel in DAQDataWave
/// - HardwareType type of hardware of the device
/// - ActiveChunk if a channel of the device is used for TP while DAQ this column saves the number of the last evaluated test pulse
///
/// Version changes:
/// - 1: Added column activeChunk
/// - 2: Changed precision to double
/// - 3: Removed column 2 with StopCollectionPoint as it is no longer used
Function/WAVE GetDQMActiveDeviceList()

	DFREF dfr = GetActiveDAQDevicesFolder()

	WAVE/Z/D/SDFR=dfr wv = ActiveDeviceList

	if(ExistsWithCorrectLayoutVersion(wv, DQM_ACTIVE_DEV_WAVE_VERSION))
		return wv
	endif

	if(WaveExists(wv))
		// do sequential version upgrade
		if(WaveVersionIsSmaller(wv, 1))
			Redimension/N=(-1, 5) wv
			wv[][4] = NaN
			Note/K wv
		endif
		if(WaveVersionIsSmaller(wv, 2))
			Redimension/D/N=(-1, -1) wv
		endif
		if(WaveVersionIsSmaller(wv, 3))
			DeleteWavePoint(wv, COLS, index = 2)
		endif
	else
		Make/D/N=(0, 4) dfr:ActiveDeviceList/WAVE=wv
	endif

	SetDimLabel COLS, 0, DeviceID, wv
	SetDimLabel COLS, 1, ADChannelToMonitor, wv
	SetDimLabel COLS, 2, HardwareType, wv
	SetDimLabel COLS, 3, ActiveChunk, wv

	SetWaveVersion(wv, DQM_ACTIVE_DEV_WAVE_VERSION)

	return wv
End

/// @brief Return the intermediate storage wave for the TTL data
Function/WAVE GetTTLWave(string device)

	DFREF    dfr          = GetDevicePath(device)
	variable hardwareType = GetHardwareType(device)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			WAVE/Z/W/SDFR=dfr wv = TTLWave

			if(WaveExists(wv))
				return wv
			endif

			Make/W/N=(0) dfr:TTLWave/WAVE=wv

			return wv

			break
		case HARDWARE_NI_DAC: // fallthrough
		case HARDWARE_SUTTER_DAC:
			WAVE/Z/WAVE/SDFR=dfr wv_ni = TTLWave

			if(WaveExists(wv_ni))
				return wv_ni
			endif

			Make/WAVE/N=(NUM_DA_TTL_CHANNELS) dfr:TTLWave/WAVE=wv_ni

			return wv_ni

			break
		default:
			FATAL_ERROR("Unsupported hardware type")
	endswitch
End

/// @brief Return the stimset acquistion cycle ID helper wave
///
/// Only valid during DAQ.
///
/// Rows:
/// - NUM_DA_TTL_CHANNELS
///
/// Columns:
/// - 0: Stimset fingerprint of the previous sweep
/// - 1: Current stimset acquisition cycle ID
Function/WAVE GetStimsetAcqIDHelperWave(string device)

	DFREF dfr = GetDevicePath(device)

	WAVE/Z/D/SDFR=dfr wv = stimsetAcqIDHelper

	if(WaveExists(wv))
		return wv
	endif

	Make/D/N=(NUM_DA_TTL_CHANNELS, 2) dfr:stimsetAcqIDHelper/WAVE=wv

	SetDimLabel COLS, 0, fingerprint, wv
	SetDimLabel COLS, 1, id, wv

	return wv
End

/// @name Experiment Documentation
///@{

/// @brief Return the datafolder reference to the lab notebook
Function/DF GetLabNotebookFolder()

	return createDFWithAllParents(GetLabNotebookFolderAsString())
End

/// @brief Return the full path to the lab notebook, e.g. root:MIES:LabNoteBook
///
/// UTF_NOINSTRUMENTATION
Function/S GetLabNotebookFolderAsString()

	return GetMiesPathAsString() + ":LabNoteBook"
End

/// @brief Return the data folder reference to the device specific lab notebook
Function/DF GetDevSpecLabNBFolder(string device)

	return createDFWithAllParents(GetDevSpecLabNBFolderAsString(device))
End

/// @brief Return the full path to the device specific lab notebook, e.g. root:MIES:LabNoteBook:ITC18USB:Device0
///
/// UTF_NOINSTRUMENTATION
Function/S GetDevSpecLabNBFolderAsString(string device)

	string deviceType, deviceNumber

	ASSERT(ParseDeviceString(device, deviceType, deviceNumber), "Could not parse the device")

	switch(GetHardwareType(device))
		case HARDWARE_NI_DAC:
			return GetLabNotebookFolderAsString() + ":" + deviceType
			break
		case HARDWARE_SUTTER_DAC:
			return GetLabNotebookFolderAsString() + ":" + deviceType
			break
		case HARDWARE_ITC_DAC:
			return GetLabNotebookFolderAsString() + ":" + deviceType + ":Device" + deviceNumber
			break
		default:
			FATAL_ERROR("Unsupported hardware type")
			break
	endswitch
End

Function/WAVE DAQ_LBN_GETTER_PROTO(string win)

	FATAL_ERROR("Can not call prototype")
End

/// @brief Returns a wave reference to the text labnotebook
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
Function/WAVE GetLBTextualValues(string device)

	string newName = LBN_TEXTUAL_VALUES_NAME
	DFREF  newDFR  = GetDevSpecLabNBFolder(device)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(device) + ":textDocumentation")
	p.newDFR  = newDFR
	p.name    = "txtDocWave"
	p.newName = newName

	WAVE/Z/T wv = UpgradeWaveLocationAndGetIt(p)

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(MINIMUM_WAVE_SIZE, INITIAL_KEY_WAVE_COL_COUNT, LABNOTEBOOK_LAYER_COUNT) newDFR:$newName/WAVE=wv
	wv = ""
	SetDimensionLabels(wv, LABNOTEBOOK_KEYS_INITIAL, COLS)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	GetLBTextualKeys(device)

	return wv
End

/// @brief Handle upgrades of the numerical/textual labnotebooks in one step
///
/// This function is idempotent and must stay that way.
///
/// Supported upgrades:
/// - Addition of the third column "TimeStampSinceIgorEpochUTC"
/// - Addition of nineth layer for headstage independent data
/// - Conversion of numeric labnotebook to 64bit floats
/// - Removal of invalid units for "Stim Scale Factor", "DA Gain" and "AD Gain"
/// - Addition of fourth column "EntrySourceType"
/// - Fix unit and tolerance of "Repeat Sets"
/// - Reapplying the dimension labels as the old ones were cut off after 31 bytes
/// - Making dimension labels valid liberal object names
/// - Extending the row dimension to 6 for the key waves
/// - Fixing empty column dimension labels in key waves
static Function UpgradeLabNotebook(string device)

	variable numCols, i, col, numEntries, sourceCol, timeStampColumn, nextFreeRow
	string list, key

	// we only have to check the new place and name as we are called
	// later than UpgradeWaveLocationAndGetIt from both key wave getters
	//
	// avoid recursion by checking the wave location first

	DFREF dfr = GetDevSpecLabNBFolder(device)

	WAVE/Z/SDFR=dfr   numericalValues = $LBN_NUMERICAL_VALUES_NAME
	WAVE/Z/T/SDFR=dfr textualValues   = $LBN_TEXTUAL_VALUES_NAME

	if(!WaveExists(numericalValues))
		WAVE numericalValues = GetLBNumericalValues(device)
	endif
	if(!WaveExists(textualValues))
		WAVE/T textualValues = GetLBTextualValues(device)
	endif

	WAVE/Z/T/SDFR=dfr numericalKeys = $LBN_NUMERICAL_KEYS_NAME
	WAVE/Z/T/SDFR=dfr textualKeys   = $LBN_TEXTUAL_KEYS_NAME

	if(!WaveExists(numericalKeys))
		WAVE/T numericalKeys = GetLBNumericalKeys(device)
	endif

	if(!WaveExists(textualKeys))
		WAVE/T textualKeys = GetLBTextualKeys(device)
	endif

	ASSERT(DimSize(numericalKeys, COLS) == DimSize(numericalValues, COLS), "Non matching number of rows for numeric labnotebook")
	ASSERT(DimSize(textualKeys, COLS) == DimSize(textualValues, COLS), "Non matching number of rows for textual labnotebook")

	// BEGIN IP9 dimension labels
	if(WaveVersionIsSmaller(numericalKeys, 49))
		numericalKeys[%Parameter][] = FixInvalidLabnotebookKey(numericalKeys[%Parameter][q])
		LBN_SetDimensionLabels(numericalKeys, numericalValues)
	endif

	if(WaveVersionIsSmaller(textualKeys, 49))
		textualKeys[%Parameter][] = FixInvalidLabnotebookKey(textualKeys[%Parameter][q])
		LBN_SetDimensionLabels(textualKeys, textualValues)
	endif
	// END IP9 dimension labels

	// BEGIN UTC timestamps
	if(cmpstr(numericalKeys[0][2], "TimeStampSinceIgorEpochUTC"))

		numCols = DimSize(numericalKeys, COLS)

		Redimension/N=(-1, numCols + 1, -1) numericalKeys, numericalValues

		numericalKeys[][numCols]     = numericalKeys[p][2]
		numericalValues[][numCols][] = numericalValues[p][2][r]

		numericalValues[][2][] = NaN
		numericalKeys[][2]     = ""
		numericalKeys[0][2]    = "TimeStampSinceIgorEpochUTC"
		LBN_SetDimensionLabels(numericalKeys, numericalValues)

		DEBUGPRINT("Upgraded numerical labnotebook to hold UTC timestamps")
	endif

	if(cmpstr(textualKeys[0][2], "TimeStampSinceIgorEpochUTC"))

		numCols = DimSize(textualKeys, COLS)

		Redimension/N=(-1, numCols + 1, -1) textualKeys, textualValues

		textualKeys[][numCols]     = textualKeys[p][2]
		textualValues[][numCols][] = textualValues[p][2][r]

		textualValues[][2][] = ""
		textualKeys[][2]     = ""
		textualKeys[0][2]    = "TimeStampSinceIgorEpochUTC"
		LBN_SetDimensionLabels(textualKeys, textualValues)

		DEBUGPRINT("Upgraded textual labnotebook to hold UTC timestamps")
	endif
	// END UTC timestamps

	// BEGIN epoch source type
	if(cmpstr(numericalKeys[0][3], "EntrySourceType"))

		numCols = DimSize(numericalKeys, COLS)

		Redimension/N=(-1, numCols + 1, -1) numericalKeys, numericalValues

		numericalKeys[][numCols]     = numericalKeys[p][3]
		numericalValues[][numCols][] = numericalValues[p][3][r]

		numericalValues[][3][] = NaN
		numericalKeys[][3]     = ""
		numericalKeys[0][3]    = "EntrySourceType"
		LBN_SetDimensionLabels(numericalKeys, numericalValues)

		DEBUGPRINT("Upgraded numerical labnotebook to hold entry source type column")
	endif

	if(cmpstr(textualKeys[0][3], "EntrySourceType"))

		numCols = DimSize(textualKeys, COLS)

		Redimension/N=(-1, numCols + 1, -1) textualKeys, textualValues

		textualKeys[][numCols]     = textualKeys[p][3]
		textualValues[][numCols][] = textualValues[p][3][r]

		textualValues[][3][] = ""
		textualKeys[][3]     = ""
		textualKeys[0][3]    = "EntrySourceType"
		LBN_SetDimensionLabels(textualKeys, textualValues)

		DEBUGPRINT("Upgraded textual labnotebook to hold entry source type column")
	endif
	// END epoch source type

	if(DimSize(textualValues, LAYERS) == NUM_HEADSTAGES && DimSize(numericalValues, LAYERS) == NUM_HEADSTAGES)
		Redimension/N=(-1, -1, LABNOTEBOOK_LAYER_COUNT, -1) textualValues, numericalValues
		textualValues[][][8]   = ""
		numericalValues[][][8] = NaN

		DEBUGPRINT("Upgraded labnotebooks to handle headstage independent data")
	endif

	if(WaveType(numericalValues) == IGOR_TYPE_32BIT_FLOAT)
		Redimension/Y=(IGOR_TYPE_64BIT_FLOAT) numericalValues

		DEBUGPRINT("Upgraded numeric labnotebook to 64bit floats")
	endif

	list       = "Stim Scale Factor;DA Gain;AD Gain"
	numEntries = ItemsInList(list)

	for(i = 0; i < numEntries; i += 1)
		key = StringFromList(i, list)
		col = FindDimLabel(numericalKeys, COLS, key)
		if(col >= 0 && cmpstr(numericalKeys[%Units][col], ""))
			numericalKeys[%Units][col] = ""
			if(i == 0)
				DEBUGPRINT("Upgraded numeric labnotebook key wave to remove invalid units")
			endif
		endif
	endfor

	key = "Repeat Sets"
	col = FindDimLabel(numericalKeys, COLS, key)
	if(col >= 0 && cmpstr(numericalKeys[%Units][col], ""))
		WAVE/T sweepKeyWave = GetSweepSettingsKeyWave(device)
		sourceCol = FindDimLabel(sweepKeyWave, COLS, key)
		ASSERT(sourceCol >= 0, "Unexpected sweep key wave format")
		numericalKeys[%Units][col]     = sweepKeyWave[%Units][sourceCol]
		numericalKeys[%Tolerance][col] = sweepKeyWave[%Tolerance][sourceCol]
		DEBUGPRINT("Fixed numeric labnotebook key wave entry \"Repeat Sets\"")
	endif

	// no upgrade for async entries also in the INDEP_HEADSTAGE layer

	// no upgrade for basic entries like sweepNum only in first layer due to IP7 semantics change

	if(WaveVersionIsSmaller(numericalKeys, 37))
		// reapply the dimension labels as the old ones were cut off after 31 bytes
		LBN_SetDimensionLabels(numericalKeys, numericalValues)
		LBN_SetDimensionLabels(textualKeys, textualValues)
	endif

	if(WaveVersionIsSmaller(numericalKeys, 39))
		// nothing to do
	endif

	// BEGIN acquisition state
	if(cmpstr(numericalKeys[0][4], "AcquisitionState"))

		numCols = DimSize(numericalKeys, COLS)

		Redimension/N=(-1, numCols + 1, -1) numericalKeys, numericalValues

		numericalKeys[][numCols]     = numericalKeys[p][4]
		numericalValues[][numCols][] = numericalValues[p][4][r]

		numericalValues[][4][] = NaN
		numericalKeys[][4]     = ""
		numericalKeys[0][4]    = "AcquisitionState"
		LBN_SetDimensionLabels(numericalKeys, numericalValues)

		DEBUGPRINT("Upgraded numerical labnotebook to hold acquisition state column")
	endif

	if(cmpstr(textualKeys[0][4], "AcquisitionState"))

		numCols = DimSize(textualKeys, COLS)

		Redimension/N=(-1, numCols + 1, -1) textualKeys, textualValues

		textualKeys[][numCols]     = textualKeys[p][4]
		textualValues[][numCols][] = textualValues[p][4][r]

		textualValues[][4][] = ""
		textualKeys[][4]     = ""
		textualKeys[0][4]    = "AcquisitionState"
		LBN_SetDimensionLabels(textualKeys, textualValues)

		DEBUGPRINT("Upgraded textual labnotebook to hold acquisition state column")
	endif
	// END acquisition state

	// BEGIN extending rows
	if(WaveVersionIsSmaller(numericalKeys, 55))
		Redimension/N=(6, -1) numericalKeys
	endif

	if(WaveVersionIsSmaller(textualKeys, 55))
		Redimension/N=(6, -1) textualKeys
	endif
	// END extending rows

	// BEGIN fix missing column dimension labels in keyWaves
	if(WaveVersionIsSmaller(numericalKeys, 74))
		numCols = DimSize(numericalValues, COLS)
		for(i = 0; i < numCols; i += 1)
			if(IsEmpty(GetDimLabel(numericalValues, COLS, i)))
				SetDimLabel COLS, i, $numericalKeys[0][i], numericalValues
			endif
		endfor
	endif

	if(WaveVersionIsSmaller(textualKeys, 74))
		numCols = DimSize(textualValues, COLS)
		for(i = 0; i < numCols; i += 1)
			if(IsEmpty(GetDimLabel(textualValues, COLS, i)))
				SetDimLabel COLS, i, $textualKeys[0][i], textualValues
			endif
		endfor
	endif
	// END fix missing column dimension labels in keyWaves

	// we don't remove the wavenote entry of sweep rollback as we might need to adapt the reading code
	// in the future to handle labnotebooks with that specially

	// BEGIN add note index
	// Timestamp was always present in column 1, see879683fd1 (-InitiateMies: Updated comments
	// -WaveDataFolderGetter: Updated comments, changed order to rows, columns, layers, 2014-09-12), but spelled
	// differently prior to ec6c1ac6b (Labnotebook: Add UTC timestamps, 2015-09-18)
	timeStampColumn = 1

	if(WaveVersionIsSmaller(numericalKeys, 77))
		nextFreeRow = GetNumberFromWaveNote(numericalValues, NOTE_INDEX)

		if(IsNaN(nextFreeRow))
			FindValue/FNAN/RMD=[][timeStampColumn][0]/R numericalValues
			if(!(V_row >= 0))
				// labnotebook is completely full
				V_row = DimSize(numericalValues, ROWS)
			endif
			SetNumberInWaveNote(numericalValues, NOTE_INDEX, V_row)
		endif
	endif

	if(WaveVersionIsSmaller(textualKeys, 77))
		nextFreeRow = GetNumberFromWaveNote(textualValues, NOTE_INDEX)

		if(IsNaN(nextFreeRow))
			FindValue/TEXT=("")/RMD=[][timeStampColumn][0]/R textualValues
			if(!(V_row >= 0))
				V_row = DimSize(textualValues, ROWS)
			endif
			SetNumberInWaveNote(textualValues, NOTE_INDEX, V_row)
		endif
	endif
	// END add note index
End

static Function/S FixInvalidLabnotebookKey(string name)

	string first, last, result

	if(strsearch(name, ":", 0) < 0)
		// fixup unknown user labnotebook keys which are now invalid
		return CleanupName(name, 1)
	endif

	// some common names are now invalid too,
	// these are changed from `A: B` to `A [B]`.

	SplitString/E="([^:]+):[[:space:]]*(.+)" name, first, last

	if(V_Flag == 2)
		sprintf result, "%s [%s]", trimstring(first), trimstring(last)
		return result
	endif

	return CleanupName(name, 1)
End

static Function SetLBKeysRowDimensionLabels(WAVE wv)

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units, wv
	SetDimLabel ROWS, 2, Tolerance, wv

	if(DimSize(wv, ROWS) == 6)
		SetDimLabel ROWS, 3, Description, wv
		SetDimLabel ROWS, 4, HeadstageContingency, wv
		SetDimLabel ROWS, 5, ClampMode, wv
	endif
End

/// @brief Return a wave reference to the text labnotebook keys
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
/// - 3: Source entry type, one of @ref DataAcqModes
/// - 4: Acquisition state, one of @ref AcquisitionStates
/// - other columns are filled at runtime
Function/WAVE GetLBTextualKeys(string device)

	variable versionOfNewWave = LABNOTEBOOK_VERSION
	string   newName          = LBN_TEXTUAL_KEYS_NAME
	DFREF    newDFR           = GetDevSpecLabNBFolder(device)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(device) + ":TextDocKeyWave")
	p.newDFR  = newDFR
	p.name    = "txtDocKeyWave"
	p.newName = newName

	WAVE/Z/T wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		UpgradeLabNotebook(device)
		SetWaveVersion(wv, versionOfNewWave)
		return wv
	else
		Make/T/N=(6, INITIAL_KEY_WAVE_COL_COUNT) newDFR:$newName/WAVE=wv
	endif

	wv = ""

	ASSERT(INITIAL_KEY_WAVE_COL_COUNT == ItemsInList(LABNOTEBOOK_KEYS_INITIAL), "Mismatched default keys")
	wv[0][] = StringFromList(q, LABNOTEBOOK_KEYS_INITIAL)

	SetLBKeysRowDimensionLabels(wv)

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the numeric labnotebook keys
///
/// Rows:
/// - 0: Name
/// - 1: Units
/// - 2: Tolerance
/// - 3: Description
/// - 4: Headstage Contingency
/// - 5: ClampMode
///
/// Columns:
/// - 0: Sweep Number
/// - 1: Time Stamp in local time zone
/// - 2: Time Stamp in UTC
/// - 3: Source entry type, one of @ref DataAcqModes
/// - 4: Acquisition state, one of @ref AcquisitionStates
/// - other columns are filled at runtime
Function/WAVE GetLBNumericalKeys(string device)

	variable versionOfNewWave = LABNOTEBOOK_VERSION
	/// @todo move the renaming stuff into one function for all four labnotebook waves
	string newName = LBN_NUMERICAL_KEYS_NAME
	DFREF  newDFR  = GetDevSpecLabNBFolder(device)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(device) + ":KeyWave")
	p.newDFR  = newDFR
	p.name    = "keyWave"
	p.newName = newName

	WAVE/Z/T wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		UpgradeLabNotebook(device)
		SetWaveVersion(wv, versionOfNewWave)
		return wv
	else
		Make/T/N=(6, INITIAL_KEY_WAVE_COL_COUNT) newDFR:$newName/WAVE=wv
	endif

	wv = ""

	SetLBKeysRowDimensionLabels(wv)

	WAVE/T desc = GetLBNumericalDescription(forceReload = 1)
	ASSERT(DimSize(desc, ROWS) == DimSize(wv, ROWS), "Non-matching number of rows")
	ASSERT(DimSize(wv, COLS) == INITIAL_KEY_WAVE_COL_COUNT, "Non-matching number of rows")

	// copy the "always present entries"
	wv = desc

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the static and read-only labnotebook descriptions
///        for the numerical entries
///
/// Requirements for each entry [@sa CheckLBNDescriptions()]:
///
/// - 0: Parameter
///   Not empty
/// - 1: Units
///   Something ParseUnit() can grok or `degC`, `bitMask`, `%` or `On/Off`
/// - 2: Tolerance
///   LABNOTEBOOK_NO_TOLERANCE or a positive number including zero
/// - 3: Description
///   Not empty
/// - 4: Headstage Contingency
///   One of `ALL`, `DEPEND`, `INDEP`
/// - 5: Clamp Mode
///   One of `IC`, `VC`, `IC;I=0`, `IC;VC`, `IC;VC;I=0` or empty
Function/WAVE GetLBNumericalDescription([variable forceReload])

	if(ParamIsDefault(forceReload))
		forceReload = 0
	else
		forceReload = !!forceReload
	endif

	return GetLBDescription_Impl("labnotebook_numerical_description", forceReload)
End

Function/WAVE GetLBTextualDescription([variable forceReload])

	if(ParamIsDefault(forceReload))
		forceReload = 0
	else
		forceReload = !!forceReload
	endif

	return GetLBDescription_Impl("labnotebook_textual_description", forceReload)
End

static Function/WAVE GetLBDescription_Impl(string name, variable forceReload)

	variable          versionOfNewWave = LABNOTEBOOK_VERSION
	DFREF             dfr              = GetStaticDataFolder()
	WAVE/Z/T/SDFR=dfr wv               = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave) && !forceReload)
		return wv
	endif

	KillOrMoveToTrash(wv = wv)

	WAVE/Z/T wv = LoadWaveFromDisk(name)
	ASSERT(WaveExists(wv), "Missing wave")
	ASSERT(!IsFreeWave(wv), "Not a permanent wave")

	// remove header
	DeletePoints/M=(ROWS) 0, 1, wv

	MatrixTranspose wv

	SetLBKeysRowDimensionLabels(wv)

	Duplicate/FREE/RMD=[0][] wv, labels
	Redimension/N=(numpnts(labels)) labels
	SetDimensionLabels(wv, TextWaveToList(labels, ";"), COLS)
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

static Constant LBN_NUMERICAL_DESCRIPTION_VERSION = 2

Function SaveLBNumericalDescription()

	SaveLBDescription_Impl("labnotebook_numerical_description", LBN_NUMERICAL_DESCRIPTION_VERSION)
End

static Constant LBN_TEXTUAL_DESCRIPTION_VERSION = 1

Function SaveLBTextualDescription()

	SaveLBDescription_Impl("labnotebook_textual_description", LBN_TEXTUAL_DESCRIPTION_VERSION)
End

static Function SaveLBDescription_Impl(string name, variable version)

	DFREF             dfr = GetStaticDataFolder()
	WAVE/Z/T/SDFR=dfr wv  = $name
	ASSERT(WaveExists(wv), "Missing wave")

	RemoveAllDimLabels(wv)
	Note/K wv

	Duplicate/FREE/T wv, dup

	MatrixTranspose dup

	SetWaveVersion(dup, version)

	InsertPoints/M=(ROWS) 0, 1, dup

	// Add header
	dup[0][] = {{"Name"}, {"Unit"}, {"Tolerance"}, {"Description"}, {"Headstage Contingency"}, {"ClampMode"}}

	StoreWaveOnDisk(dup, name)
End

/// @brief Handle upgrades of the numerical/textual results logbooks in one step
///
/// This function is idempotent and must stay that way.
///
/// Supported upgrades:
/// - Fixing empty column dimension labels in key waves
static Function UpgradeResultsNotebook()

	variable i, numCols

	DFREF             dfr                   = GetResultsFolder()
	WAVE/Z/SDFR=dfr   numericalResultValues = $LBN_NUMERICALRESULT_VALUES_NAME
	WAVE/Z/T/SDFR=dfr textualResultValues   = $LBN_TEXTUALRESULT_VALUES_NAME
	if(!WaveExists(numericalResultValues))
		WAVE numericalResultValues = GetNumericalResultsValues()
	endif
	if(!WaveExists(textualResultValues))
		WAVE/T textualResultValues = GetTextualResultsValues()
	endif

	WAVE/Z/T/SDFR=dfr numericalResultKeys = $LBN_NUMERICALRESULT_KEYS_NAME
	WAVE/Z/T/SDFR=dfr textualResultKeys   = $LBN_TEXTUALRESULT_KEYS_NAME
	if(!WaveExists(numericalResultKeys))
		WAVE/T numericalResultKeys = GetNumericalResultsKeys()
	endif
	if(!WaveExists(textualResultKeys))
		WAVE/T textualResultKeys = GetTextualResultsKeys()
	endif

	ASSERT(DimSize(numericalResultKeys, COLS) == DimSize(numericalResultValues, COLS), "Non matching number of rows for numeric results logbook")
	ASSERT(DimSize(textualResultKeys, COLS) == DimSize(textualResultValues, COLS), "Non matching number of rows for textual results logbook")

	// BEGIN fix missing column dimension labels in keyWaves
	if(WaveVersionIsSmaller(numericalResultKeys, 3))
		numCols = DimSize(numericalResultValues, COLS)
		for(i = 0; i < numCols; i += 1)
			if(IsEmpty(GetDimLabel(numericalResultValues, COLS, i)))
				SetDimLabel COLS, i, $numericalResultKeys[0][i], numericalResultValues
			endif
		endfor
	endif
	if(WaveVersionIsSmaller(textualResultKeys, 3))
		numCols = DimSize(textualResultValues, COLS)
		for(i = 0; i < numCols; i += 1)
			if(IsEmpty(GetDimLabel(textualResultValues, COLS, i)))
				SetDimLabel COLS, i, $textualResultKeys[0][i], textualResultValues
			endif
		endfor
	endif
	// END fix missing column dimension labels in keyWaves
End

/// @brief Return a wave reference to the numeric labnotebook keys
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
Function/WAVE GetLBNumericalValues(string device)

	string newName = LBN_NUMERICAL_VALUES_NAME
	DFREF  newDFR  = GetDevSpecLabNBFolder(device)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(device) + ":settingsHistory")
	p.newDFR  = newDFR
	p.name    = "settingsHistory"
	p.newName = newName

	WAVE/Z/D wv = UpgradeWaveLocationAndGetIt(p)

	if(!WaveExists(wv))
		Make/D/N=(MINIMUM_WAVE_SIZE, INITIAL_KEY_WAVE_COL_COUNT, LABNOTEBOOK_LAYER_COUNT) newDFR:$newName/WAVE=wv = NaN
		SetDimensionLabels(wv, LABNOTEBOOK_KEYS_INITIAL, COLS)
		SetNumberInWaveNote(wv, NOTE_INDEX, 0)

		GetLBNumericalKeys(device)
	endif

	return wv
End

/// @brief Return a wave reference to the numerical results keys
///
/// Rows:
/// - 0: Parameter Name
/// - 1: Parameter Unit
/// - 2: Parameter Tolerance
///
/// Columns:
/// - 0: Sweep Number (always NaN)
/// - 1: Time Stamp in local time zone
/// - 2: Time Stamp in UTC
/// - 3: Source entry type, one of @ref DataAcqModes
/// - 4: Acquisition state, one of @ref AcquisitionStates
/// - other columns are filled at runtime
Function/WAVE GetNumericalResultsKeys()

	variable versionOfNewWave
	string name = LBN_NUMERICALRESULT_KEYS_NAME

	DFREF             dfr = GetResultsFolder()
	WAVE/Z/T/SDFR=dfr wv  = $name
	versionOfNewWave = RESULTS_VERSION

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
		UpgradeResultsNotebook()
		SetWaveVersion(wv, versionOfNewWave)
		return wv
	else
		Make/T/N=(3, INITIAL_KEY_WAVE_COL_COUNT) dfr:$name/WAVE=wv
	endif

	wv = ""

	ASSERT(INITIAL_KEY_WAVE_COL_COUNT == ItemsInList(LABNOTEBOOK_KEYS_INITIAL), "Mismatched default keys")
	wv[0][] = StringFromList(q, LABNOTEBOOK_KEYS_INITIAL)

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units, wv
	SetDimLabel ROWS, 2, Tolerance, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the numerical results values
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
Function/WAVE GetNumericalResultsValues()

	string name = LBN_NUMERICALRESULT_VALUES_NAME

	DFREF             dfr = GetResultsFolder()
	WAVE/Z/D/SDFR=dfr wv  = $name

	if(WaveExists(wv))
		// upgrade will be handled in GetNumericalResultsKeys()
		return wv
	endif

	Make/D/N=(MINIMUM_WAVE_SIZE, INITIAL_KEY_WAVE_COL_COUNT, LABNOTEBOOK_LAYER_COUNT) dfr:$name/WAVE=wv = NaN
	SetDimensionLabels(wv, LABNOTEBOOK_KEYS_INITIAL, COLS)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	GetNumericalResultsKeys()

	return wv
End

/// @brief Return a wave reference to the textual results keys
///
/// One user of the results wave is Sweep Formula. It stores the code and
/// various meta information in it every time it is executed.
///
/// Rows:
/// - 0: Parameter Name
/// - 1: Parameter Unit
/// - 2: Parameter Tolerance
///
/// Columns:
/// - SweepNum: Sweep number (always NaN)
/// - TimeStamp: Time stamp in local time zone since igor epoch
/// - TimeStampSinceIgorEpochUTC: time stamp in UTC since igor epoch
/// - EntrySourceType: One of @ref DataAcqModes
/// - AcquisitionState: One of @ref AcquisitionStates
/// - Sweep Formula code: Executed code from SweepFormula
/// - Sweep Formula sweeps/channels: Displayed sweeps and channels as 2D array
///                                  in the form `$sweep0;$channelType0;$channelNumber0;,$sweep1;$channelType1;$channelNumber1;,...`
///                                  @sa SFH_NewSelectDataWave
/// - Sweep Formula displayed sweeps: Displayed sweeps (deprecated)
/// - Sweep Formula active channels: Active channels (deprecated)
/// - Sweep Formula experiment: Name of the experiment
/// - Sweep Formula device: Device
/// - Sweep Formula cursor X: Information about each available cursor, see
///                           GetCursorInfos() for the exact format.
/// - Sweep Formula store [X]: Stored data from SweepFormula `store` operation.
///                            The `X` is dynamic and the first argument passed.
/// - Other columns are created and filled at runtime
Function/WAVE GetTextualResultsKeys()

	variable versionOfNewWave
	string name = LBN_TEXTUALRESULT_KEYS_NAME

	DFREF             dfr = GetResultsFolder()
	WAVE/Z/T/SDFR=dfr wv  = $name
	versionOfNewWave = RESULTS_VERSION

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
		UpgradeResultsNotebook()
		SetWaveVersion(wv, versionOfNewWave)
		return wv
	else
		Make/T/N=(3, INITIAL_KEY_WAVE_COL_COUNT) dfr:$name/WAVE=wv
	endif

	wv = ""

	ASSERT(INITIAL_KEY_WAVE_COL_COUNT == ItemsInList(LABNOTEBOOK_KEYS_INITIAL), "Mismatched default keys")
	wv[0][] = StringFromList(q, LABNOTEBOOK_KEYS_INITIAL)

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units, wv
	SetDimLabel ROWS, 2, Tolerance, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the numerical results values
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
Function/WAVE GetTextualResultsValues()

	string name = LBN_TEXTUALRESULT_VALUES_NAME

	DFREF             dfr = GetResultsFolder()
	WAVE/Z/T/SDFR=dfr wv  = $name

	if(WaveExists(wv))
		// upgrade will be handled in GetTextualResultsKeys()
		return wv
	endif

	Make/T/N=(MINIMUM_WAVE_SIZE, INITIAL_KEY_WAVE_COL_COUNT, LABNOTEBOOK_LAYER_COUNT) dfr:$name/WAVE=wv
	SetDimensionLabels(wv, LABNOTEBOOK_KEYS_INITIAL, COLS)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	GetTextualResultsKeys()

	return wv
End

/// @brief Return the labnotebook cache wave holding the first and last rows
///		into `values` of each sweep number.
///
/// Uses the `values` wave modification count to reset itself upon a change.
///
/// The stored information is the returned `first`/`last` parameter from
/// GetLastSettingNoCache().
///
/// Rows:
/// - Sweep numbers (only existing sweeps)
///
/// Columns:
/// - 0: First row
/// - 1: Last row
///
/// Layers:
/// - One for each entrySourceType, mapped via EntrySourceTypeMapper()
threadsafe Function/WAVE GetLBRowCache(WAVE values)

	variable actual, sweepNo, first, last
	string key

	variable versionOfNewWave = 6

	actual = WaveModCountWrapper(values)
	key    = CA_CreateLBRowCacheKey(values)

	WAVE/Z/D wv = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		if(actual == GetNumberFromWaveNote(wv, LABNOTEBOOK_MOD_COUNT))
			return wv
		elseif(!MU_RunningInMainThread() && GetLockState(values) == 1)
			return wv
		else
			// new entries were added so we need to propagate all entries to LABNOTEBOOK_GET_RANGE
			// for sweep numbers >= than the currently acquired sweep
			// this is required as the `last` element of the range can be changed if you add labnotebook
			// entries and then query them and then add again.

			if(IsNumericWave(values))
				WAVE/Z sweeps = GetLastSweepWithSetting(values, "SweepNum", sweepNo)
			elseif(IsTextWave(values))
				WAVE/Z sweeps = GetLastSweepWithSettingText(values, "SweepNum", sweepNo)
			endif

			if(IsFinite(sweepNo))
				EnsureLargeEnoughWave(wv, indexShouldExist = sweepNo, dimension = ROWS, initialValue = LABNOTEBOOK_GET_RANGE)
				first = limit(sweepNo - 1, 0, Inf)
				last  = sweepNo
				Multithread wv[first, last][][] = LABNOTEBOOK_GET_RANGE

				// now we are up to date
				SetNumberInWaveNote(wv, LABNOTEBOOK_MOD_COUNT, actual)

				return wv
			endif
		endif
	else
		Make/N=(MINIMUM_WAVE_SIZE, 2, NUMBER_OF_LBN_DAQ_MODES)/D/FREE wv
		CA_StoreEntryIntoCache(key, wv, options = CA_OPTS_NO_DUPLICATE)
	endif

	Multithread wv = LABNOTEBOOK_GET_RANGE

	SetDimLabel COLS, 0, first, wv
	SetDimLabel COLS, 1, last, wv

	SetNumberInWaveNote(wv, LABNOTEBOOK_MOD_COUNT, actual)
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Index wave which serves as a labnotebook cache.
///
/// Rows:
/// - Sweep numbers
///
/// Columns:
/// - One for each LBN key
///
/// Layers:
/// - One for each entrySourceType, mapped via EntrySourceTypeMapper()
///
/// The wave can be indexed with sweepNumber, settings column and
/// entrySourceType to return the row index of the labnotebok wave where the
/// desired value can be found.
///
/// Contents:
/// - row index if the entry could be found, #LABNOTEBOOK_MISSING_VALUE if it
///   could not be found, and #LABNOTEBOOK_UNCACHED_VALUE if the cache is empty.
threadsafe Function/WAVE GetLBIndexCache(WAVE values)

	variable actual, sweepNo, first, last
	string key

	variable versionOfNewWave = 5

	actual = WaveModCountWrapper(values)
	key    = CA_CreateLBIndexCacheKey(values)

	WAVE/Z/D wv = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		if(actual == GetNumberFromWaveNote(wv, LABNOTEBOOK_MOD_COUNT))
			return wv
		elseif(!MU_RunningInMainThread() && GetLockState(values) == 1)
			return wv
		else
			// new entries were added so we need to propagate all entries to uncached values
			// for sweep numbers >= than the currently acquired sweep

			if(IsNumericWave(values))
				WAVE/Z sweeps = GetLastSweepWithSetting(values, "SweepNum", sweepNo)
			elseif(IsTextWave(values))
				WAVE/Z sweeps = GetLastSweepWithSettingText(values, "SweepNum", sweepNo)
			endif

			if(IsFinite(sweepNo))
				EnsureLargeEnoughWave(wv, indexShouldExist = sweepNo, dimension = ROWS, initialValue = LABNOTEBOOK_UNCACHED_VALUE)
				first = limit(sweepNo - 1, 0, Inf)
				last  = sweepNo
				Multithread wv[first, last][][] = LABNOTEBOOK_UNCACHED_VALUE

				// now we are up to date
				SetNumberInWaveNote(wv, LABNOTEBOOK_MOD_COUNT, actual)

				return wv
			endif
		endif
	else
		Make/FREE/N=(MINIMUM_WAVE_SIZE, MINIMUM_WAVE_SIZE, NUMBER_OF_LBN_DAQ_MODES)/D wv
		CA_StoreEntryIntoCache(key, wv, options = CA_OPTS_NO_DUPLICATE)
	endif

	Multithread wv = LABNOTEBOOK_UNCACHED_VALUE

	SetNumberInWaveNote(wv, LABNOTEBOOK_MOD_COUNT, actual)
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Free wave to cache the sweeps of one RAC/SCI ID
///
/// Type of content:
/// - valid wave
/// - invalid wave reference (uncached entry)
/// - wave of size zero (non-existant entry)
///
/// Rows:
/// - One for each sweep number
///
/// Columns:
/// - RAC (repeated acquisition cycle IDs) sweeps
/// - SCI (simset cycle IDs) sweeps
///
threadsafe Function/WAVE GetLBNidCache(WAVE numericalValues)

	variable actual
	string key, name

	variable versionOfNewWave = 3

	ASSERT_TS(WaveExists(numericalValues) && IsNumericWave(numericalValues), "Expected existing numerical labnotebook")

	actual = WaveModCountWrapper(numericalValues)
	name   = GetWavesDataFolder(numericalValues, 2)
	ASSERT_TS(!isEmpty(name), "Invalid path to wave, free waves won't work.")

	key = name + "_RACidCache"

	WAVE/Z/WAVE wv = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		if(actual == GetNumberFromWaveNote(wv, LABNOTEBOOK_MOD_COUNT))
			return wv
		elseif(!MU_RunningInMainThread() && GetLockState(numericalValues) == 1)
			return wv
		else
			// we can't easily do an incremental update as we would need to
			// update all RAC/SCI cycles which got changed by the new data
			// and that is not so easy
		endif
	else
		Make/FREE/N=(MINIMUM_WAVE_SIZE, 2, NUM_HEADSTAGES)/WAVE wv
		CA_StoreEntryIntoCache(key, wv, options = CA_OPTS_NO_DUPLICATE)
	endif

	wv = $""

	SetNumberInWaveNote(wv, LABNOTEBOOK_MOD_COUNT, actual)
	SetWaveVersion(wv, versionOfNewWave)

	SetDimLabel COLS, 0, $RA_ACQ_CYCLE_ID_KEY, wv
	SetDimLabel COLS, 1, $STIMSET_ACQ_CYCLE_ID_KEY, wv

	return wv
End

/// @brief Uses the parameter names from the `sourceKey` columns and
///        write them as dimension into the columns of dest.
static Function SetSweepSettingsDimLabels(WAVE dest, WAVE/T sourceKey)

	variable i, numCols

	numCols = DimSize(dest, COLS)

	ASSERT(numCols == DimSize(sourceKey, COLS), "Dimension column size mismatch")
	ASSERT(DimSize(sourceKey, ROWS) == 3 || DimSize(sourceKey, ROWS) == 1, "Unexpected number of rows in the sourceKey wave")

	for(i = 0; i < numCols; i += 1)
		SetDimLabel COLS, i, $sourceKey[%Parameter][i], dest
	endfor
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
Function/WAVE GetSweepSettingsWave(string device)

	variable numCols

	variable versionOfNewWave = SWEEP_SETTINGS_WAVE_VERSION
	string   newName          = "sweepSettingsNumericValues"
	DFREF    newDFR           = GetDevSpecLabNBTempFolder(device)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(device) + ":settingsHistory")
	p.newDFR  = newDFR
	p.name    = "sweepSettingsWave"
	p.newName = newName

	WAVE/Z/D wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, SWEEP_SETTINGS_WAVE_VERSION))
		return wv
	endif

	WAVE/T keyWave = GetSweepSettingsKeyWave(device)
	numCols = DimSize(keyWave, COLS)

	if(WaveExists(wv))
		Redimension/D/N=(-1, numCols, LABNOTEBOOK_LAYER_COUNT) wv
	else
		Make/D/N=(1, numCols, LABNOTEBOOK_LAYER_COUNT) newDFR:$newName/WAVE=wv
	endif

	wv = NaN

	SetSweepSettingsDimLabels(wv, keyWave)
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
/// - 7:  Inter-trial interval (used after the sweep it is documented for)
/// - 8:  TTL rack zero bits (ITC hardware), bit sum in `INDEP_HEADSTAGE` layer of the active DAEphys TTL channels (called TTLBit)
/// - 9:  TTL rack one bits, same for the second rack
/// - 10: TTL rack zero channel (ITC hardware), device type dependent hardware channel used for acquisition in `INDEP_HEADSTAGE` layer
/// - 11: TTL rack one channel (ITC hardware), same for the second rack
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
/// - 23: Sampling interval DA
/// - 24: Sampling interval AD
/// - 25: Sampling interval TTL
/// - 26: Sampling interval multiplier
/// - 27: Stim set length
/// - 28: oodDAQ Pre Feature
/// - 29: oodDAQ Post Feature
/// - 30: oodDAQ Resolution
/// - 31: Optimized Overlap dDAQ
/// - 32: Delay onset oodDAQ
/// - 33: Repeated Acquisition Cycle ID
/// - 34: Stim Wave Checksum (can be used to disambiguate cases
///                           where two stimsets are named the same
///                           but have different contents)
/// - 35: Multi Device mode
/// - 36: Background Testpulse
/// - 37: Background DAQ
/// - 38: TP during ITI
/// - 39: Amplifier change via I=0
/// - 40: Skip analysis functions
/// - 41: Repeat sweep on async alarm
/// - 42: Set Cycle Count
/// - 43: Stimset cycle ID
/// - 44: Digitizer Hardware Type, one of @ref HardwareDACTypeConstants
/// - 45: Fixed frequency acquisition
/// - 46: Headstage Active, binary flag that indicates the enabled headstage(s), the index is the headstage number
/// - 47: Clamp Mode
/// - 48: Igor Pro bitness
/// - 49: DA ChannelType, one of @ref DaqChannelTypeConstants
/// - 50: AD ChannelType, one of @ref DaqChannelTypeConstants
/// - 51: oodDAQ member, true if headstage takes part in oodDAQ mode, false otherwise
/// - 52: Autobias % (DAEphys->Settings->Amplifier)
/// - 53: Autobias Interval (DAEphys->Settings->Amplifier)
/// - 54: TP after DAQ
/// - 55: Epochs version
/// - 56: Get/Set Inter-trial interval
/// - 57: Double precision data
/// - 58: Save amplifier settings
/// - 59: Require amplifier
/// - 60: Skip Ahead
/// - 61: TP power spectrum
/// - 62: ADC Configuration bits
Function/WAVE GetSweepSettingsKeyWave(string device)

	variable versionOfNewWave = SWEEP_SETTINGS_WAVE_VERSION
	string   newName          = "sweepSettingsNumericKeys"
	DFREF    newDFR           = GetDevSpecLabNBTempFolder(device)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(device) + ":KeyWave")
	p.newDFR  = newDFR
	p.name    = "sweepSettingsKeyWave"
	p.newName = newName

	WAVE/Z/T wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, 63) wv
	else
		Make/T/N=(3, 63) newDFR:$newName/WAVE=wv
	endif

	wv = ""

	SetDimLabel 0, 0, Parameter, wv
	SetDimLabel 0, 1, Units, wv
	SetDimLabel 0, 2, Tolerance, wv

	wv[%Parameter][0] = STIMSET_SCALE_FACTOR_KEY
	wv[%Units][0]     = ""
	wv[%Tolerance][0] = ".0001"

	wv[%Parameter][1] = "DAC"
	wv[%Units][1]     = ""
	wv[%Tolerance][1] = "0.1"

	wv[%Parameter][2] = "ADC"
	wv[%Units][2]     = ""
	wv[%Tolerance][2] = "0.1"

	wv[%Parameter][3] = "DA Gain"
	wv[%Units][3]     = ""
	wv[%Tolerance][3] = ".000001"

	wv[%Parameter][4] = "AD Gain"
	wv[%Units][4]     = ""
	wv[%Tolerance][4] = ".000001"

	wv[%Parameter][5] = "Set Sweep Count"
	wv[%Units][5]     = ""
	wv[%Tolerance][5] = "0.1"

	wv[%Parameter][6] = "TP Insert Checkbox"
	wv[%Units][6]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][6] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][7] = "Inter-trial interval"
	wv[%Units][7]     = "s"
	wv[%Tolerance][7] = "0.01"

	wv[%Parameter][8] = "TTL rack zero bits"
	wv[%Units][8]     = "bit mask"
	wv[%Tolerance][8] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][9] = "TTL rack one bits"
	wv[%Units][9]     = "bit mask"
	wv[%Tolerance][9] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][10] = "TTL rack zero channel"
	wv[%Units][10]     = ""
	wv[%Tolerance][10] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][11] = "TTL rack one channel"
	wv[%Units][11]     = ""
	wv[%Tolerance][11] = LABNOTEBOOK_NO_TOLERANCE

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
	wv[%Units][16]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][16] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][17] = "Repeat Sets"
	wv[%Units][17]     = ""
	wv[%Tolerance][17] = "1"

	wv[%Parameter][18] = "Scaling zero"
	wv[%Units][18]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][18] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][19] = "Indexing"
	wv[%Units][19]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][19] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][20] = "Locked indexing"
	wv[%Units][20]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][20] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][21] = "Repeated Acquisition"
	wv[%Units][21]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][21] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][22] = "Random Repeated Acquisition"
	wv[%Units][22]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][22] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][23] = "Sampling interval DA"
	wv[%Units][23]     = "ms"
	wv[%Tolerance][23] = "1"

	wv[%Parameter][24] = "Sampling interval AD"
	wv[%Units][24]     = "ms"
	wv[%Tolerance][24] = "1"

	wv[%Parameter][25] = "Sampling interval TTL"
	wv[%Units][25]     = "ms"
	wv[%Tolerance][25] = "1"

	wv[%Parameter][26] = "Sampling interval multiplier"
	wv[%Units][26]     = ""
	wv[%Tolerance][26] = "0.1"

	wv[%Parameter][27] = "Stim set length"
	wv[%Units][27]     = "" // points not time
	wv[%Tolerance][27] = "0.1"

	wv[%Parameter][28] = "oodDAQ Pre Feature"
	wv[%Units][28]     = "ms"
	wv[%Tolerance][28] = "1"

	wv[%Parameter][29] = "oodDAQ Post Feature"
	wv[%Units][29]     = "ms"
	wv[%Tolerance][29] = "1"

	wv[%Parameter][30] = "oodDAQ Resolution"
	wv[%Units][30]     = "ms"
	wv[%Tolerance][30] = "1"

	wv[%Parameter][31] = "Optimized Overlap dDAQ"
	wv[%Units][31]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][31] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][32] = "Delay onset oodDAQ"
	wv[%Units][32]     = "ms"
	wv[%Tolerance][32] = "1"

	wv[%Parameter][33] = RA_ACQ_CYCLE_ID_KEY
	wv[%Units][33]     = ""
	wv[%Tolerance][33] = "1"

	wv[%Parameter][34] = "Stim Wave Checksum"
	wv[%Units][34]     = ""
	wv[%Tolerance][34] = "1"

	wv[%Parameter][35] = "Multi Device mode"
	wv[%Units][35]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][35] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][36] = "Background Testpulse"
	wv[%Units][36]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][36] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][37] = "Background DAQ"
	wv[%Units][37]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][37] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][38] = "TP during ITI"
	wv[%Units][38]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][38] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][39] = "Amplifier change via I=0"
	wv[%Units][39]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][39] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][40] = "Skip analysis functions"
	wv[%Units][40]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][40] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][41] = "Repeat sweep on async alarm"
	wv[%Units][41]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][41] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][42] = "Set Cycle Count"
	wv[%Units][42]     = ""
	wv[%Tolerance][42] = "1"

	wv[%Parameter][43] = STIMSET_ACQ_CYCLE_ID_KEY
	wv[%Units][43]     = ""
	wv[%Tolerance][43] = "1"

	wv[%Parameter][44] = "Digitizer Hardware Type"
	wv[%Units][44]     = ""
	wv[%Tolerance][44] = "1"

	wv[%Parameter][45] = "Fixed frequency acquisition"
	wv[%Units][45]     = "kHz"
	wv[%Tolerance][45] = "1"

	wv[%Parameter][46] = "Headstage Active"
	wv[%Units][46]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][46] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][47] = CLAMPMODE_ENTRY_KEY
	wv[%Units][47]     = ""
	wv[%Tolerance][47] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][48] = "Igor Pro bitness"
	wv[%Units][48]     = ""
	wv[%Tolerance][48] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][49] = "DA ChannelType"
	wv[%Units][49]     = ""
	wv[%Tolerance][49] = "1"

	wv[%Parameter][50] = "AD ChannelType"
	wv[%Units][50]     = ""
	wv[%Tolerance][50] = "1"

	wv[%Parameter][51] = "oodDAQ member"
	wv[%Units][51]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][51] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][52] = AUTOBIAS_PERC_KEY
	wv[%Units][52]     = ""
	wv[%Tolerance][52] = "0.1"

	wv[%Parameter][53] = "Autobias Interval"
	wv[%Units][53]     = "s"
	wv[%Tolerance][53] = "0.1"

	wv[%Parameter][54] = "TP after DAQ"
	wv[%Units][54]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][54] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][55] = SWEEP_EPOCH_VERSION_ENTRY_KEY
	wv[%Units][55]     = ""
	wv[%Tolerance][55] = "1"

	wv[%Parameter][56] = "Get/Set Inter-trial interval"
	wv[%Units][56]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][56] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][57] = "Double precision data"
	wv[%Units][57]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][57] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][58] = "Save amplifier settings"
	wv[%Units][58]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][58] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][59] = "Require amplifier"
	wv[%Units][59]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][59] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][60] = "Skip Ahead"
	wv[%Units][60]     = ""
	wv[%Tolerance][60] = "1"

	wv[%Parameter][61] = "TP power spectrum"
	wv[%Units][61]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][61] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][62] = "ADC Configuration bits"
	wv[%Units][62]     = ""
	wv[%Tolerance][62] = "0.1"

	SetSweepSettingsDimLabels(wv, wv)
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns a wave reference to SweepSettingsTxtData
///
/// SweepSettingsTxtData is passed to ED_AddEntriesToLabnotebook to add entries to the labnotebook.
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
Function/WAVE GetSweepSettingsTextWave(string device)

	variable numCols

	variable versionOfNewWave = SWEEP_SETTINGS_WAVE_VERSION
	string   newName          = "sweepSettingsTextValues"
	DFREF    newDFR           = GetDevSpecLabNBTempFolder(device)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(device) + ":textDocumentation")
	p.newDFR  = newDFR
	p.name    = "SweepSettingsTxtData"
	p.newName = newName

	WAVE/Z/T wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	WAVE/T keyWave = GetSweepSettingsTextKeyWave(device)
	numCols = DimSize(keyWave, COLS)

	if(WaveExists(wv))
		Redimension/N=(-1, numCols, LABNOTEBOOK_LAYER_COUNT) wv
	else
		Make/T/N=(1, numCols, LABNOTEBOOK_LAYER_COUNT) newDFR:$newName/WAVE=wv
	endif

	wv = ""

	SetSweepSettingsDimLabels(wv, keyWave)
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
/// -  0: Stim set
/// -  1: DA unit
/// -  2: AD unit
/// -  3: TTL rack zero stim sets (ITC hardware), string list in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// -  4: TTL rack one stim sets (ITC hardware), same for the second rack
/// -  5: Analysis function pre daq
/// -  6: Analysis function mid sweep
/// -  7: Analysis function post sweep
/// -  8: Analysis function post set
/// -  9: Analysis function post daq
/// - 10: Analysis function pre sweep
/// - 11: Analysis function generic
/// - 12: Analysis function pre set
/// - 13: Analysis function parameters
/// - 14: oodDAQ regions list
///       - Format: `$begin1-$end1;$begin2-$end2;...`.
///       - Unit: `stimset build ms`.
/// - 15: Electrode
/// - 16: High precision sweep start timestamp in ISO8601 format
/// - 17: Stimset wave note
/// - 18: TTL rack zero set sweep counts (ITC hardware)
/// - 19: TTL rack one set sweep counts (ITC hardware)
/// - 20: TTL set sweep counts (NI hardware), string list in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// - 21: TTL stim sets (NI hardware), string list in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// - 22: TTL channels (NI hardware), string list  in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// - 23: Follower Device, list of follower devices (not supported anymore and therefore always empty)
/// - 24: MIES version, multi line mies version string
/// - 25: Igor Pro version
/// - 26: Digitizer Hardware Name
/// - 27: Digitizer Serial Numbers
/// - 28: Epochs
/// - 29: JSON config file [path] (`|` separated list of full file paths)
/// - 30: JSON config file [SHA-256 hash] (`|` separated list of hashes)
/// - 31: JSON config file [stimset nwb file path]
/// - 32: Igor Pro build
/// - 33: Indexing End Stimset
/// - 34: TTL Indexing End Stimset (hardware agnostic), string list in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// - 35: TTL Stimset wave note (hardware agnostic), same string list formatting
/// - 36: TTL Stim Wave Checksum (hardware agnostic) URL-encoded payload, see [URL-encoding](https://en.wikipedia.org/wiki/Percent-encoding)
///                                                  for background information, same string list formatting
/// - 37: TTL Stim set length (hardware agnostic), same string list formatting
/// - 38: TTL rack zero set cycle counts (ITC hardware)
/// - 39: TTL rack one set cycle counts (ITC hardware)
/// - 40: TTL set cycle counts (NI hardware), string list in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// - 41: Device (aka DAEphys panel name)
Function/WAVE GetSweepSettingsTextKeyWave(string device)

	variable versionOfNewWave = SWEEP_SETTINGS_WAVE_VERSION
	string   newName          = "sweepSettingsTextKeys"
	DFREF    newDFR           = GetDevSpecLabNBTempFolder(device)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(device) + ":textDocKeyWave")
	p.newDFR  = newDFR
	p.name    = "SweepSettingsKeyTxtData"
	p.newName = newName

	WAVE/Z/T wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, 50, 0) wv
	else
		Make/T/N=(1, 50) newDFR:$newName/WAVE=wv
	endif

	SetDimLabel ROWS, 0, Parameter, wv

	wv = ""

	wv[0][0]  = STIM_WAVE_NAME_KEY
	wv[0][1]  = "DA unit"
	wv[0][2]  = "AD unit"
	wv[0][3]  = "TTL rack zero " + LABNOTEBOOK_TTL_STIMSETS
	wv[0][4]  = "TTL rack one " + LABNOTEBOOK_TTL_STIMSETS
	wv[0][5]  = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][6]  = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][7]  = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][8]  = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][9]  = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][10] = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][11] = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][12] = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][13] = ANALYSIS_FUNCTION_PARAMS_LBN
	wv[0][14] = "oodDAQ regions"
	wv[0][15] = "Electrode"
	wv[0][16] = HIGH_PREC_SWEEP_START_KEY
	wv[0][17] = STIMSET_WAVE_NOTE_KEY
	wv[0][18] = "TTL rack zero " + LABNOTEBOOK_TTL_SETSWEEPCOUNTS
	wv[0][19] = "TTL rack one " + LABNOTEBOOK_TTL_SETSWEEPCOUNTS
	wv[0][20] = "TTL " + LABNOTEBOOK_TTL_SETSWEEPCOUNTS
	wv[0][21] = "TTL " + LABNOTEBOOK_TTL_STIMSETS
	wv[0][22] = "TTL channels"
	wv[0][23] = "Follower Device"
	wv[0][24] = "MIES version"
	wv[0][25] = "Igor Pro version"
	wv[0][26] = "Digitizer Hardware Name"
	wv[0][27] = "Digitizer Serial Numbers"
	wv[0][28] = EPOCHS_ENTRY_KEY
	wv[0][29] = "JSON config file [path]"
	wv[0][30] = "JSON config file [SHA-256 hash]"
	wv[0][31] = "JSON config file [stimset nwb file path]"
	wv[0][32] = "Igor Pro build"
	wv[0][33] = "Indexing End Stimset"
	wv[0][34] = "TTL Indexing End Stimset"
	wv[0][35] = "TTL Stimset wave note"
	wv[0][36] = "TTL Stim Wave Checksum"
	wv[0][37] = "TTL Stim set length"
	wv[0][38] = "TTL rack zero set cycle counts"
	wv[0][39] = "TTL rack one set cycle counts"
	wv[0][40] = "TTL set cycle counts"
	wv[0][41] = "Device"
	wv[0][42] = CreateTTLChannelLBNKey(EPOCHS_ENTRY_KEY, 0)
	wv[0][43] = CreateTTLChannelLBNKey(EPOCHS_ENTRY_KEY, 1)
	wv[0][44] = CreateTTLChannelLBNKey(EPOCHS_ENTRY_KEY, 2)
	wv[0][45] = CreateTTLChannelLBNKey(EPOCHS_ENTRY_KEY, 3)
	wv[0][46] = CreateTTLChannelLBNKey(EPOCHS_ENTRY_KEY, 4)
	wv[0][47] = CreateTTLChannelLBNKey(EPOCHS_ENTRY_KEY, 5)
	wv[0][48] = CreateTTLChannelLBNKey(EPOCHS_ENTRY_KEY, 6)
	wv[0][49] = CreateTTLChannelLBNKey(EPOCHS_ENTRY_KEY, 7)

	SetSweepSettingsDimLabels(wv, wv)
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End
///@}

/// @name Test Pulse
///@{

/// @brief Return a wave reference for TPStorage
///
/// Stores properties of the testpulse during TP
///
/// ROWS:
/// - One entry per step
///
/// COLS:
/// - NUM_HEADSTAGES
///
/// LAYERS:
/// -  0: Amplifier holding command (Voltage Clamp)
/// -  1: Amplifier bias current (Current Clamp)
/// -  2: (Peak/Instantaneous) Resistance
/// -  3: (Steady State) Resistance
/// -  4: Delta time in s relative to the entry in the first row of layer 3
/// -  5: (Steady State) Resistance slope
/// -  6: Pressure in psi
/// -  7: Timestamp since igor epoch (*with* timezone offsets)
/// -  8: Timestamp in UTC since igor epoch
/// -  9: Pressure changed
/// - 10: Holding current (pA, Voltage Clamp)
/// - 11: Vrest (mV, Current Clamp)
/// - 12: AD channel
/// - 13: DA channel
/// - 14: Headstage
/// - 15: ClampMode
/// - 16: UserPressure
/// - 17: PressureMethod (see @ref PressureModeConstants)
/// - 18: ValidState (true if the entry is considered valid, false otherwise)
/// - 19: UserPressureType (see @ref PressureTypeConstants)
/// - 20: UserPressureTimeStampUTC timestamp since Igor Pro epoch in UTC where
///       the user pressure was acquired
/// - 21: TPMarker unique number identifying this set of TPs
/// - 22: Cell state: Pressure control values defining the cell state, one of @ref CellStateValues
/// - 23: Testpulse Cycle Id (changes whenever TP is started, allows to group TPs together)
/// - 24: Auto TP Amplitude: success/fail state
/// - 25: Auto TP Baseline: success/fail state
/// - 26: Auto TP Baseline Range Exceeded: True/False
/// - 27: Auto TP Cycle ID: Unique number which is constant until the "Auto TP"
///       state is switched (aka on->off or off->on)
/// - 28: Auto TP Baseline Fit result: One of @ref TPBaselineFitResults
/// - 29: Auto TP Delta V [mV]
/// - 30: Clamp Amplitude [mV] or [pA] depending on Clamp Mode
/// - 31: Testpulse full length in points for AD channel [points]
/// - 32: Testpulse pulse length in points for AD channel [points]
/// - 33: Point index of pulse start for AD channel [point]
/// - 34: Sampling interval for AD channel [ms]
/// - 35: Testpulse full length in points for DA channel [points]
/// - 36: Testpulse pulse length in points for DA channel [points]
/// - 37: Point index of pulse start for DA channel [point]
/// - 38: Sampling interval for DA channel [ms]
Function/WAVE GetTPStorage(string device)

	DFREF    dfr              = GetDeviceTestPulse(device)
	variable versionOfNewWave = 18
	variable numLayersV16     = 40
	variable numLayers        = 39

	WAVE/Z/D/SDFR=dfr wv = TPStorage

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, NUM_HEADSTAGES, numLayersV16)/D wv

		if(WaveVersionIsSmaller(wv, 10))
			wv[][][17]     = NaN
			wv[][][20, 21] = NaN
		endif
		if(WaveVersionIsSmaller(wv, 11))
			wv[][][22] = NaN
		endif
		// no size change on version 12
		if(WaveVersionIsSmaller(wv, 13))
			wv[][][23] = NaN
		endif
		if(WaveVersionIsSmaller(wv, 14))
			wv[][][24] = NaN
		endif
		if(WaveVersionIsSmaller(wv, 15))
			wv[][][25, 30] = NaN
		endif
		if(WaveVersionIsSmaller(wv, 16))
			wv[][][31, numLayers - 1] = NaN
		endif
		if(WaveVersionIsSmaller(wv, 17))
			// Delete the former layer for %TimeInSeconds that was layer 4
			// The functionality is replaced by a precise %TimeStamp
			DeletePoints/M=(LAYERS) 4, 1, wv
		endif
	else
		Make/N=(MINIMUM_WAVE_SIZE_LARGE, NUM_HEADSTAGES, numLayers)/D dfr:TPStorage/WAVE=wv

		wv = NaN

		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	endif

	SetDimLabel COLS, -1, Headstage, wv

	SetDimLabel LAYERS, 0, HoldingCmd_VC, wv
	SetDimLabel LAYERS, 1, HoldingCmd_IC, wv
	SetDimLabel LAYERS, 2, PeakResistance, wv
	SetDimLabel LAYERS, 3, SteadyStateResistance, wv
	SetDimLabel LAYERS, 4, DeltaTimeInSeconds, wv
	SetDimLabel LAYERS, 5, Rss_Slope, wv
	SetDimLabel LAYERS, 6, Pressure, wv
	SetDimLabel LAYERS, 7, TimeStamp, wv
	SetDimLabel LAYERS, 8, TimeStampSinceIgorEpochUTC, wv
	SetDimLabel LAYERS, 9, PressureChange, wv
	SetDimLabel LAYERS, 10, Baseline_VC, wv
	SetDimLabel LAYERS, 11, Baseline_IC, wv
	SetDimLabel LAYERS, 12, ADC, wv
	SetDimLabel LAYERS, 13, DAC, wv
	SetDimLabel LAYERS, 14, Headstage, wv
	SetDimLabel LAYERS, 15, ClampMode, wv
	SetDimLabel LAYERS, 16, UserPressure, wv
	SetDimLabel LAYERS, 17, PressureMethod, wv
	SetDimLabel LAYERS, 18, ValidState, wv
	SetDimLabel LAYERS, 19, UserPressureType, wv
	SetDimLabel LAYERS, 20, UserPressureTimeStampUTC, wv
	SetDimLabel LAYERS, 21, TPMarker, wv
	SetDimLabel LAYERS, 22, CellState, wv
	SetDimLabel LAYERS, 23, TPCycleID, wv
	SetDimLabel LAYERS, 24, AutoTPAmplitude, wv
	SetDimLabel LAYERS, 25, AutoTPBaseline, wv
	SetDimLabel LAYERS, 26, AutoTPBaselineRangeExceeded, wv
	SetDimLabel LAYERS, 27, AutoTPCycleID, wv
	SetDimLabel LAYERS, 28, AutoTPBaselineFitResult, wv
	SetDimLabel LAYERS, 29, AutoTPDeltaV, wv
	// Dimlabels starting from here are taken from TP_ANALYSIS_DATA_LABELS
	// This is not required but convenient because in @ref TP_RecordTP data from TPResults (@ref GetTPResults)
	// is transferred to tpStorage and TPResults also uses dimlabels from TP_ANALYSIS_DATA_LABELS partially.
	SetDimLabel LAYERS, 30, CLAMPAMP, wv
	SetDimLabel LAYERS, 31, TPLENGTHPOINTSADC, wv
	SetDimLabel LAYERS, 32, PULSELENGTHPOINTSADC, wv
	SetDimLabel LAYERS, 33, PULSESTARTPOINTSADC, wv
	SetDimLabel LAYERS, 34, SAMPLINGINTERVALADC, wv
	SetDimLabel LAYERS, 35, TPLENGTHPOINTSDAC, wv
	SetDimLabel LAYERS, 36, PULSELENGTHPOINTSDAC, wv
	SetDimLabel LAYERS, 37, PULSESTARTPOINTSDAC, wv
	SetDimLabel LAYERS, 38, SAMPLINGINTERVALDAC, wv

	SetNumberInWaveNote(wv, AUTOBIAS_LAST_INVOCATION_KEY, 0)
	SetNumberInWaveNote(wv, DIMENSION_SCALING_LAST_INVOC, 0)
	SetNumberInWaveNote(wv, PRESSURE_CTRL_LAST_INVOC, 0)
	SetNumberInWaveNote(wv, INDEX_ON_TP_START, 0)
	SetNumberInWaveNote(wv, REFERENCE_START_TIME, 0)

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a free wave reference for AcqTPStorage wave for passing to ACQ4
///
/// The wave stores PeakResistance, SteadyStateResistance, and TimeStamp in rows and headstages in cols
Function/WAVE GetAcqTPStorage()

	Make/FREE/D/N=(3, NUM_HEADSTAGES, HARDWARE_MAX_DEVICES) wv

	SetDimLabel COLS, -1, HeadStage, wv
	SetDimLabel ROWS, 0, TimeStamp, wv
	SetDimLabel ROWS, 1, SteadyStateResistance, wv
	SetDimLabel ROWS, 2, PeakResistance, wv

	return wv
End

/// @brief Return a datafolder reference to the test pulse folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetDeviceTestPulse(string device)

	return createDFWithAllParents(GetDeviceTestPulseAsString(device))
End

/// @brief Return the path to the test pulse folder, e.g. root:mies:HardwareDevices:ITC1600:Device0:TestPulse
///
/// UTF_NOINSTRUMENTATION
Function/S GetDeviceTestPulseAsString(string device)

	return GetDevicePathAsString(device) + ":TestPulse"
End

/// @brief Return a wave which holds undecimated and scaled data
///
/// ScaledDataWave is initialized in @sa DC_InitScaledDataWave
/// Each channel contains scaled data that takes the gain from the headstage into account.
/// In the channel wave the voltage output to the DAC and read from the ADC is translated back
/// to the headstages input/output signal (e.g. mV / pA). The x-time interval is milliseconds.
///
/// For ITC on initialization the channels are filled with NaN and the headstages data unit is set.
/// In @sa SCOPE_ITC_UpdateOscilloscope all channels are copied from the DAQDataWave to the scaledDataWave
/// and properly scaled.
/// For NI on initialization the non-ADC channels are copied from the DAQDataWave to the scaledDataWave
/// and properly scaled. The ADC channels are scaled by a gain factor that is applied in hardware (or the device XOP).
/// Thus, in @sa SCOPE_NI_UpdateOscilloscope and @sa SCOPE_SU_UpdateOscilloscope the ADC channel data is simply
/// copied from the DAQDataWave to the scaledDataWave.
///
/// Unversioned Wave:
///
/// Rows:
/// - StopCollectionPoint
///
/// Columns:
/// - Number of active channels
///
/// Type:
/// - FP32 or FP64, as returned by SWS_GetRawDataFPType()
///
/// Version 1:
/// WAVEREF wave, initially with size 0
/// sized in @sa DC_MakeHelperWaves to number of hardware channels as in config wave
Function/WAVE GetScaledDataWave(string device)

	variable version = 1

	DFREF           dfr = GetDevicePath(device)
	WAVE/Z/SDFR=dfr wv  = ScaledData

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		if(!IsWaveVersioned(wv))
			KillOrMoveToTrash(wv = wv)
			Make/WAVE/N=0 dfr:ScaledData/WAVE=wv1
		endif
	else
		Make/WAVE/N=0 dfr:ScaledData/WAVE=wv1
	endif

	SetWaveVersion(wv1, version)

	return wv1
End

/// @brief Return a wave for displaying scaled data in the oscilloscope window
///
/// Contents can be decimated for faster display.
Function/WAVE GetOscilloscopeWave(string device)

	DFREF           dfr = GetDevicePath(device)
	WAVE/Z/SDFR=dfr wv  = OscilloscopeData

	if(WaveExists(wv))
		return wv
	endif

	Make/R/N=(1, NUM_DA_TTL_CHANNELS) dfr:OscilloscopeData/WAVE=wv

	return wv
End

/// @brief Return a wave for temporary storing scaled data for PowerSpectrum input
Function/WAVE GetScaledTPTempWave(string device)

	string name = "ScaledTPTempWave"

	DFREF             dfr = GetDevicePath(device)
	WAVE/Z/D/SDFR=dfr wv  = $name

	if(WaveExists(wv))
		return wv
	endif

	Make/D/N=(1, NUM_DA_TTL_CHANNELS) dfr:$name/WAVE=wv

	return wv
End

/// @brief Return a wave for displaying scaled TP data in the oscilloscope window
///        for the "TP during DAQ" channels or for TP power spectrum during Test Pulse
///
/// Rows:
/// - Holds exactly one TP
///
/// Columns:
/// - DA/AD/TTLs data, same order as GetDAQDataWave()
Function/WAVE GetTPOscilloscopeWave(string device)

	DFREF           dfr = GetDevicePath(device)
	WAVE/Z/SDFR=dfr wv  = TPOscilloscopeData

	if(WaveExists(wv))
		return wv
	endif

	Make/R/N=(0, NUM_DA_TTL_CHANNELS) dfr:TPOscilloscopeData/WAVE=wv

	return wv
End

/// @brief Return a wave reference wave for storing the *full* test pulses
Function/WAVE GetStoredTestPulseWave(string device)

	DFREF                dfr = GetDeviceTestPulse(device)
	WAVE/Z/WAVE/SDFR=dfr wv  = StoredTestPulses

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/WAVE dfr:StoredTestPulses/WAVE=wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the testpulse results wave
///
/// Rows:
/// - 0: Resistance Instantaneous: [MΩ]
/// - 1: Baseline Steady State: [mV] for IC, [pA] for VC
/// - 2: Resistance Steady State: [MΩ]
/// - 3: Elevated Steady State: [mV] for IC, [pA] for VC
/// - 4: Elevated Instantaneous: [mV] for IC, [pA] for VC
/// - 5: Auto TP Amplitude: Pass/Fail
/// - 6: Auto TP Baseline: Pass/Fail
/// - 7: Auto TP Baseline range exceeded: True/False
/// - 8: Auto TP Baseline fit result: One of @ref TPBaselineFitResults
/// - 9: Auto TP Delta V: [mV]
/// - 10+: partial dim labels from TP_ANALYSIS_DATA_LABELS, originally filled in TP_TSAnalysis
/// Columns:
/// - NUM_HEADSTAGES
Function/WAVE GetTPResults(string device)

	variable version = 4

	string labels = "ResistanceInst;BaselineSteadyState;ResistanceSteadyState;ElevatedSteadyState;ElevatedInst;"                + \
	                "AutoTPAmplitude;AutoTPBaseline;AutoTPBaselineRangeExceeded;AutoTPBaselineFitResult;AutoTPDeltaV;"          + \
	                "NOW;HEADSTAGE;MARKER;NUMBER_OF_TP_CHANNELS;TIMESTAMP;TIMESTAMPUTC;CLAMPMODE;CLAMPAMP;BASELINEFRAC;"        + \
	                "CYCLEID;TPLENGTHPOINTSADC;PULSELENGTHPOINTSADC;PULSESTARTPOINTSADC;SAMPLINGINTERVALADC;TPLENGTHPOINTSDAC;" + \
	                "PULSELENGTHPOINTSDAC;PULSESTARTPOINTSDAC;SAMPLINGINTERVALDAC;"

	DFREF             dfr = GetDeviceTestPulse(device)
	WAVE/Z/D/SDFR=dfr wv  = results

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/D/N=(ItemsInList(labels), NUM_HEADSTAGES) wv
		wv = NaN
	else
		Make/D/N=(ItemsInList(labels), NUM_HEADSTAGES) dfr:results/WAVE=wv
		wv = NaN

		// initialize with the old 1D waves
		WAVE/Z/D/SDFR=dfr InstResistance, BaselineSSAvg, SSResistance

		wv[0][] = WaveExists(InstResistance) ? InstResistance[q] : NaN
		wv[1][] = WaveExists(BaselineSSAvg) ? BaselineSSAvg[q] : NaN
		wv[2][] = WaveExists(SSResistance) ? SSResistance[q] : NaN

		// and get rid of them
		KillOrMoveToTrash(wv = InstResistance)
		KillOrMoveToTrash(wv = BaselineSSAvg)
		KillOrMoveToTrash(wv = SSResistance)
	endif

	SetDimensionLabels(wv, labels, ROWS)

	SetWaveVersion(wv, version)

	return wv
End

/// @brief Return the testpulse results buffer wave
///
/// Same layout as GetTPResults() but as many layers as the buffer size.
Function/WAVE GetTPResultsBuffer(string device)

	variable version = 2

	DFREF             dfr = GetDeviceTestPulse(device)
	WAVE/Z/D/SDFR=dfr wv  = resultsBuffer

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		// do upgrade
	else
		WAVE TPResults  = GetTPResults(device)
		WAVE TPSettings = GetTPSettings(device)

		Duplicate TPResults, dfr:resultsBuffer/WAVE=wv
		Redimension/N=(-1, -1, TPSettings[%bufferSize][INDEP_HEADSTAGE]) wv

		wv = NaN
	endif

	SetWaveVersion(wv, version)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End
///@}

/// @name Amplifier
///@{

/// @brief Return the datafolder reference to the amplifier
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAmplifierFolder()

	return createDFWithAllParents(GetAmplifierFolderAsString())
End

/// @brief Return the path to the amplifierm e.g. root:mies:Amplifiers"
///
/// UTF_NOINSTRUMENTATION
Function/S GetAmplifierFolderAsString()

	return GetMiesPathAsString() + ":Amplifiers"
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
Function/WAVE GetAmplifierParamStorageWave(string device)

	variable versionOfNewWave = 4
	STRUCT WaveLocationMod p

	DFREF newDFR = GetAmplifierFolder()
	p.dfr    = $(GetAmplifierFolderAsString() + ":Settings")
	p.newDFR = newDFR
	// wave's name is like ITC18USB_Dev_0
	p.name = device

	WAVE/Z/D wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// nothing to do
	else
		Make/N=(31, 1, NUM_HEADSTAGES)/D newDFR:$device/WAVE=wv
	endif

	SetDimLabel LAYERS, -1, Headstage, wv
	SetDimLabel ROWS, 0, HoldingPotential, wv
	SetDimLabel ROWS, 1, HoldingPotentialEnable, wv
	SetDimLabel ROWS, 2, WholeCellCap, wv
	SetDimLabel ROWS, 3, WholeCellRes, wv
	SetDimLabel ROWS, 4, WholeCellEnable, wv
	SetDimLabel ROWS, 5, Correction, wv
	SetDimLabel ROWS, 6, Prediction, wv
	SetDimLabel ROWS, 7, RsCompEnable, wv
	SetDimLabel ROWS, 8, PipetteOffsetVC, wv
	SetDimLabel ROWS, 9, FastCapacitanceComp, wv
	SetDimLabel ROWS, 10, SlowCapacitanceComp, wv
	SetDimLabel ROWS, 11, RSCompChaining, wv
	SetDimLabel ROWS, 12, VClampPlaceHolder, wv
	SetDimLabel ROWS, 13, VClampPlaceHolder, wv
	SetDimLabel ROWS, 14, VClampPlaceHolder, wv
	SetDimLabel ROWS, 15, VClampPlaceHolder, wv
	SetDimLabel ROWS, 16, BiasCurrent, wv // Hold IC
	SetDimLabel ROWS, 17, BiasCurrentEnable, wv // Hold Enable IC
	SetDimLabel ROWS, 18, BridgeBalance, wv
	SetDimLabel ROWS, 19, BridgeBalanceEnable, wv
	SetDimLabel ROWS, 20, CapNeut, wv
	SetDimLabel ROWS, 21, CapNeutEnable, wv
	SetDimLabel ROWS, 22, AutoBiasVcom, wv
	SetDimLabel ROWS, 23, AutoBiasVcomVariance, wv
	SetDimLabel ROWS, 24, AutoBiasIbiasmax, wv
	SetDimLabel ROWS, 25, AutoBiasEnable, wv
	SetDimLabel ROWS, 26, PipetteOffsetIC, wv
	SetDimLabel ROWS, 27, IclampPlaceHolder, wv
	SetDimLabel ROWS, 28, IclampPlaceHolder, wv
	SetDimLabel ROWS, 29, IclampPlaceHolder, wv
	SetDimLabel ROWS, 30, IclampPlaceHolder, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a free wave reference for the amplifier settings, data wave
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
Function/WAVE GetAmplifierSettingsWave()

	Make/FREE/N=(1, 47, LABNOTEBOOK_LAYER_COUNT)/D wv

	wv = NaN

	return wv
End

/// @brief Return a free wave reference for the amplifier settings, key wave
///
/// Rows:
/// - 0: Parameter
/// - 1: Units
/// - 2: Tolerance factor
///
/// Columns:
/// - Various settings
Function/WAVE GetAmplifierSettingsKeyWave()

	Make/FREE/T/N=(3, 47) wv

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units, wv
	SetDimLabel ROWS, 2, Tolerance, wv

	wv[0][0] = "V-Clamp Holding Enable"
	wv[1][0] = LABNOTEBOOK_BINARY_UNIT
	wv[2][0] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][1] = "V-Clamp Holding Level"
	wv[1][1] = "mV"
	wv[2][1] = "0.9"

	wv[0][2] = "Osc Killer Enable"
	wv[1][2] = LABNOTEBOOK_BINARY_UNIT
	wv[2][2] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][3] = "RsComp Bandwidth"
	wv[1][3] = "Hz"
	wv[2][3] = "0.9"

	wv[0][4] = "RsComp Correction"
	wv[1][4] = "%"
	wv[2][4] = "0.9"

	wv[0][5] = "RsComp Enable"
	wv[1][5] = LABNOTEBOOK_BINARY_UNIT
	wv[2][5] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][6] = "RsComp Prediction"
	wv[1][6] = "%"
	wv[2][6] = "0.9"

	wv[0][7] = "Whole Cell Comp Enable"
	wv[1][7] = LABNOTEBOOK_BINARY_UNIT
	wv[2][7] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][8] = "Whole Cell Comp Cap"
	wv[1][8] = "pF"
	wv[2][8] = "0.9"

	wv[0][9] = "Whole Cell Comp Resist"
	wv[1][9] = "MΩ"
	wv[2][9] = "0.9"

	wv[0][10] = "I-Clamp Holding Enable"
	wv[1][10] = LABNOTEBOOK_BINARY_UNIT
	wv[2][10] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][11] = "I-Clamp Holding Level"
	wv[1][11] = "pA"
	wv[2][11] = "0.9"

	wv[0][12] = "Neut Cap Enabled"
	wv[1][12] = LABNOTEBOOK_BINARY_UNIT
	wv[2][12] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][13] = "Neut Cap Value"
	wv[1][13] = "pF"
	wv[2][13] = "0.9"

	wv[0][14] = "Bridge Bal Enable"
	wv[1][14] = LABNOTEBOOK_BINARY_UNIT
	wv[2][14] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][15] = "Bridge Bal Value"
	wv[1][15] = "MΩ"
	wv[2][15] = "0.9"

	// and now add the Axon values to the amp settings key
	wv[0][16] = "Serial Number"
	wv[1][16] = ""
	wv[2][16] = "-"

	wv[0][17] = "Channel ID"
	wv[1][17] = ""
	wv[2][17] = "-"

	wv[0][18] = "ComPort ID"
	wv[1][18] = ""
	wv[2][18] = "-"

	wv[0][19] = "AxoBus ID"
	wv[1][19] = ""
	wv[2][19] = "-"

	wv[0][20] = "Operating Mode"
	wv[1][20] = ""
	wv[2][20] = "-"

	wv[0][21] = "Scaled Out Signal"
	wv[1][21] = ""
	wv[2][21] = "-"

	wv[0][22] = "Alpha"
	wv[1][22] = ""
	wv[2][22] = "-"

	wv[0][23] = "Scale Factor"
	wv[1][23] = ""
	wv[2][23] = "-"

	wv[0][24] = "Scale Factor Units"
	wv[1][24] = ""
	wv[2][24] = "-"

	wv[0][25] = "LPF Cutoff"
	wv[1][25] = ""
	wv[2][25] = "-"

	wv[0][26] = "Membrane Cap"
	wv[1][26] = "pF"
	wv[2][26] = "0.9"

	wv[0][27] = "Ext Cmd Sens"
	wv[1][27] = ""
	wv[2][27] = "-"

	wv[0][28] = "Raw Out Signal"
	wv[1][28] = ""
	wv[2][28] = "-"

	wv[0][29] = "Raw Scale Factor"
	wv[1][29] = ""
	wv[2][29] = "-"

	wv[0][30] = "Raw Scale Factor Units"
	wv[1][30] = ""
	wv[2][30] = "-"

	wv[0][31] = "Hardware Type"
	wv[1][31] = ""
	wv[2][31] = "-"

	wv[0][32] = "Secondary Alpha"
	wv[1][32] = ""
	wv[2][32] = "-"

	wv[0][33] = "Secondary LPF Cutoff"
	wv[1][33] = ""
	wv[2][33] = "-"

	wv[0][34] = "Series Resistance"
	wv[1][34] = "MΩ"
	wv[2][34] = LABNOTEBOOK_NO_TOLERANCE

	// new keys starting from 29a161c
	wv[0][35] = "Pipette Offset"
	wv[1][35] = "mV"
	wv[2][35] = "0.1"

	wv[0][36] = "Slow current injection"
	wv[1][36] = LABNOTEBOOK_BINARY_UNIT
	wv[2][36] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][37] = "Slow current injection level"
	wv[1][37] = "V"
	wv[2][37] = "0.1"

	wv[0][38] = "Slow current injection settling time"
	wv[1][38] = "s"
	wv[2][38] = "-"

	wv[0][39] = "Fast compensation capacitance"
	wv[1][39] = "F"
	wv[2][39] = "1e-12"

	wv[0][40] = "Slow compensation capacitance"
	wv[1][40] = "F"
	wv[2][40] = "1e-12"

	wv[0][41] = "Fast compensation time"
	wv[1][41] = "s"
	wv[2][41] = "1e-6"

	wv[0][42] = "Slow compensation time"
	wv[1][42] = "s"
	wv[2][42] = "1e-6"

	wv[0][43] = "Autobias Vcom"
	wv[1][43] = "mV"
	wv[2][43] = "0.1"

	wv[0][44] = "Autobias Vcom variance"
	wv[1][44] = "mV"
	wv[2][44] = "0.1"

	wv[0][45] = "Autobias Ibias max"
	wv[1][45] = "pA"
	wv[2][45] = "0.1"

	wv[0][46] = "Autobias"
	wv[1][46] = LABNOTEBOOK_BINARY_UNIT
	wv[2][46] = LABNOTEBOOK_NO_TOLERANCE

	return wv
End

/// @brief Return a *free* wave for the amplifier text settings, data wave
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
Function/WAVE GetAmplifierSettingsTextWave()

	Make/FREE/T/N=(1, 6, LABNOTEBOOK_LAYER_COUNT) wv

	return wv
End

/// @brief Return a *free* wave for the amplifier text settings, key wave
///
/// Rows:
/// - 0: Parameter
/// - 1: Units
/// - 2: Tolerance factor
///
/// Columns:
/// - Various settings
Function/WAVE GetAmplifierSettingsTextKeyWave()

	Make/FREE/T/N=(3, 6) wv

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units, wv
	SetDimLabel ROWS, 2, Tolerance, wv

	wv[0][0] = "OperatingModeString"
	wv[1][0] = ""
	wv[2][0] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][1] = "ScaledOutSignalString"
	wv[1][1] = ""
	wv[2][1] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][2] = "ScaleFactorUnitsString"
	wv[1][2] = ""
	wv[2][2] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][3] = "RawOutSignalString"
	wv[1][3] = ""
	wv[2][3] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][4] = "RawScaleFactorUnitsString"
	wv[1][4] = ""
	wv[2][4] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][5] = "HardwareTypeString"
	wv[1][5] = ""
	wv[2][5] = LABNOTEBOOK_NO_TOLERANCE

	return wv
End

/// @brief Return wave reference to the `W_TelegraphServers` wave
///
/// Call AI_FindConnectedAmps() to create that wave, otherwise an empty wave is
/// returned.
Function/WAVE GetAmplifierTelegraphServers()

	DFREF dfr = GetAmplifierFolder()

	WAVE/Z/I/SDFR=dfr wv = W_TelegraphServers

	if(WaveExists(wv))
		return wv
	endif

	Make/I/N=(0) dfr:W_TelegraphServers/WAVE=wv

	return wv
End

/// @brief Return wave reference to the `W_MultiClamps` wave
///
/// Call AI_FindConnectedAmps() to create that wave, if that was not done an
/// empty wave is returned.
Function/WAVE GetAmplifierMultiClamps()

	DFREF dfr = GetAmplifierFolder()

	WAVE/Z/I/SDFR=dfr wv = W_MultiClamps

	if(WaveExists(wv))
		return wv
	endif

	Make/I/N=(0) dfr:W_MultiClamps/WAVE=wv

	return wv
End
///@}

/// @name Wavebuilder
///@{

/// @brief Returns a data folder reference to the base
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWaveBuilderPath()

	return createDFWithAllParents(GetWaveBuilderPathAsString())
End

/// @brief Returns the full path to the base path, e.g. root:MIES:WaveBuilder
///
/// UTF_NOINSTRUMENTATION
Function/S GetWaveBuilderPathAsString()

	return GetMiesPathAsString() + ":WaveBuilder"
End

/// @brief Returns a data folder reference to the data
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWaveBuilderDataPath()

	return createDFWithAllParents(GetWaveBuilderDataPathAsString())
End

/// @brief Returns the full path to the data folder, e.g root:MIES:WaveBuilder:Data
///
/// UTF_NOINSTRUMENTATION
Function/S GetWaveBuilderDataPathAsString()

	return GetWaveBuilderPathAsString() + ":Data"
End

/// @brief Returns a data folder reference to the data
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWaveBuilderDataDAPath()

	return createDFWithAllParents(GetWaveBuilderDataDAPathAsString())
End

/// @brief Returns the full path to the data folder, e.g root:MIES:WaveBuilder:Data:DA
///
/// UTF_NOINSTRUMENTATION
Function/S GetWaveBuilderDataDAPathAsString()

	return GetWaveBuilderDataPathAsString() + ":DA"
End

/// @brief Returns a data folder reference to the data
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWaveBuilderDataTTLPath()

	return createDFWithAllParents(GetWaveBuilderDataTTLPathAsString())
End

/// @brief Returns the full path to the data folder, e.g root:MIES:WaveBuilder:Data:TTL
///
/// UTF_NOINSTRUMENTATION
Function/S GetWaveBuilderDataTTLPathAsString()

	return GetWaveBuilderDataPathAsString() + ":TTL"
End

/// @brief Returns a data folder reference to the stimulus set parameter
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWBSvdStimSetParamPath()

	return createDFWithAllParents(GetWBSvdStimSetParamPathAS())
End

/// @brief Returns the full path to the stimulus set parameter folder, e.g. root:MIES:WaveBuilder:SavedStimulusSetParameters
///
/// UTF_NOINSTRUMENTATION
Function/S GetWBSvdStimSetParamPathAS()

	return GetWaveBuilderPathAsString() + ":SavedStimulusSetParameters"
End

/// @brief Returns a data folder reference to the stimulus set
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWBSvdStimSetPath()

	return createDFWithAllParents(GetWBSvdStimSetPathAsString())
End

/// @brief Returns the full path to the stimulus set, e.g. root:MIES:WaveBuilder:SavedStimulusSets
///
/// UTF_NOINSTRUMENTATION
Function/S GetWBSvdStimSetPathAsString()

	return GetWaveBuilderPathAsString() + ":SavedStimulusSets"
End

/// @brief Returns a data folder reference to the stimulus set parameters of `DA` type
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWBSvdStimSetParamDAPath()

	return createDFWithAllParents(GetWBSvdStimSetParamDAPathAS())
End

/// @brief Returns the full path to the stimulus set parameters of `DA` type, e.g. root:MIES:WaveBuilder:SavedStimulusSetParameters:DA
///
/// UTF_NOINSTRUMENTATION
Function/S GetWBSvdStimSetParamDAPathAS()

	return GetWBSvdStimSetParamPathAS() + ":DA"
End

/// @brief Returns a data folder reference to the stimulus set parameters of `TTL` type
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWBSvdStimSetParamTTLPath()

	return createDFWithAllParents(GetWBSvdStimSetParamTTLAsString())
End

/// @brief Returns the full path to the stimulus set parameters of `TTL` type, e.g. root:MIES:WaveBuilder:SavedStimulusSetParameters:TTL
///
/// UTF_NOINSTRUMENTATION
Function/S GetWBSvdStimSetParamTTLAsString()

	return GetWBSvdStimSetParamPathAS() + ":TTL"
End

/// @brief Returns a data folder reference to the stimulus set of `DA` type
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWBSvdStimSetDAPath()

	return createDFWithAllParents(GetWBSvdStimSetDAPathAsString())
End

/// @brief Returns the full path to the stimulus set of `DA` type, e.g. root:MIES:WaveBuilder:SavedStimulusSet:DA
///
/// UTF_NOINSTRUMENTATION
Function/S GetWBSvdStimSetDAPathAsString()

	return GetWBSvdStimSetPathAsString() + ":DA"
End

/// @brief Returns a data folder reference to the stimulus set of `TTL` type
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWBSvdStimSetTTLPath()

	return createDFWithAllParents(GetWBSvdStimSetTTLPathAsString())
End

/// @brief Returns the full path to the stimulus set of `TTL` type, e.g. root:MIES:WaveBuilder:SavedStimulusSet:TTL
///
/// UTF_NOINSTRUMENTATION
Function/S GetWBSvdStimSetTTLPathAsString()

	return GetWBSvdStimSetPathAsString() + ":TTL"
End

/// @brief Return the testpulse wave
///
/// This wave will be written in TP_CreateTestPulseWave() and will use the real
/// sampling interval.
Function/WAVE GetTestPulse()

	DFREF           dfr = GetWBSvdStimSetDAPath()
	WAVE/Z/SDFR=dfr wv  = TestPulse

	if(WaveExists(wv))
		return wv
	endif

	/// create dummy wave
	WAVE wv = GetTestPulseAsFree()
	MoveWave wv, dfr:TestPulse

	return wv
End

Function/WAVE GetTestPulseAsFree()

	Make/FREE/R/N=0 wv

	return wv
End

static Constant WP_WAVE_LAYOUT_VERSION = 13

/// @brief Automated testing helper
static Function GetWPVersion()

	return WP_WAVE_LAYOUT_VERSION
End

/// @brief Upgrade the wave layout of `WP` to the most recent one
///        as defined in `WP_WAVE_LAYOUT_VERSION`
Function UpgradeWaveParam(WAVE wv)

	if(ExistsWithCorrectLayoutVersion(wv, WP_WAVE_LAYOUT_VERSION))
		return NaN
	endif

	Redimension/N=(88, -1, EPOCH_TYPES_TOTAL_NUMBER) wv
	AddDimLabelsToWP(wv)

	// custom wave offsets special location removed
	// and replaced with the default location
	if(WaveVersionIsSmaller(wv, 7))
		wv[4][][EPOCH_TYPE_CUSTOM] = wv[18][q][EPOCH_TYPE_CUSTOM]
		wv[5][][EPOCH_TYPE_CUSTOM] = wv[19][q][EPOCH_TYPE_CUSTOM]
	endif

	// upgrade to wave version 6
	// only dim labels

	// upgrade to wave version 5
	if(WaveVersionIsSmaller(wv, 5))
		// 41: pink noise, 42: brown noise, none: white noise -> 54: noise type
		wv[54][][EPOCH_TYPE_NOISE] = (wv[41][q][EPOCH_TYPE_NOISE] == 0 && wv[42][q][EPOCH_TYPE_NOISE] == 0) ? 0 : ((wv[41][q][EPOCH_TYPE_NOISE] == 1) ? 1 : 2)
		// adapt to changed filter order definition
		wv[26][][EPOCH_TYPE_NOISE] = 6
		wv[27][][EPOCH_TYPE_NOISE] = 0
	endif

	// upgrade to wave version 9
	if(WaveVersionIsSmaller(wv, 9))
		// preselect per epoch RNG
		wv[39][][] = 1
	endif

	// upgrade to wave version 10
	if(WaveVersionIsSmaller(wv, 10))
		// delta operation mode was global before but now is per entry
		Multithread wv[70, 85][][] = wv[40][q][r]
		wv[40][][] = NaN
	endif

	// upgrade to wave version 11
	// nothing to do as we keep them float

	// upgrade to wave version 12 is done in AddDimLabelsToWP (liberal object names)

	if(WaveVersionIsSmaller(wv, 13))
		wv[86][][] = NOISE_GEN_MERSENNE_TWISTER
		wv[87][][] = NOISE_GEN_LINEAR_CONGRUENTIAL
	endif

	SetWaveVersion(wv, WP_WAVE_LAYOUT_VERSION)
End

static Function AddDimLabelsToWP(WAVE wv)

	variable i

	RemoveAllDimLabels(wv)

	SetDimLabel COLS, -1, $("Epoch number"), wv

	for(i = 0; i < WB_TOTAL_NUMBER_OF_EPOCHS; i += 1)
		SetDimLabel COLS, i, $("Epoch " + num2str(i)), wv
	endfor

	SetDimLabel LAYERS, -1, $("Epoch type"), wv
	SetDimLabel LAYERS, 0, $("Square pulse"), wv
	SetDimLabel LAYERS, 1, $("Ramp"), wv
	SetDimLabel LAYERS, 2, $("Noise"), wv
	SetDimLabel LAYERS, 3, $("Sin"), wv
	SetDimLabel LAYERS, 4, $("Saw tooth"), wv
	SetDimLabel LAYERS, 5, $("Pulse train"), wv
	SetDimLabel LAYERS, 6, $("PSC"), wv
	SetDimLabel LAYERS, 7, $("Load custom wave"), wv
	SetDimLabel LAYERS, 8, $("Combine"), wv

	SetDimLabel ROWS, -1, $("Property"), wv
	SetDimLabel ROWS, 0, $("Duration"), wv
	SetDimLabel ROWS, 1, $("Duration delta"), wv
	SetDimLabel ROWS, 2, $("Amplitude"), wv
	SetDimLabel ROWS, 3, $("Amplitude delta"), wv
	SetDimLabel ROWS, 4, $("Offset"), wv
	SetDimLabel ROWS, 5, $("Offset delta"), wv
	SetDimLabel ROWS, 6, $("Sin/chirp/saw frequency"), wv
	SetDimLabel ROWS, 7, $("Sin/chirp/saw frequency delta"), wv
	SetDimLabel ROWS, 8, $("Train pulse duration"), wv
	SetDimLabel ROWS, 9, $("Train pulse duration delta"), wv
	SetDimLabel ROWS, 10, $("PSC exp rise time"), wv
	SetDimLabel ROWS, 11, $("PSC exp rise time delta"), wv
	SetDimLabel ROWS, 12, $("PSC exp decay time 1/2"), wv
	SetDimLabel ROWS, 13, $("PSC exp decay time 1/2 delta"), wv
	SetDimLabel ROWS, 14, $("PSC exp decay time 2/2"), wv
	SetDimLabel ROWS, 15, $("PSC exp decay time 2/2 delta"), wv
	SetDimLabel ROWS, 16, $("PSC ratio decay times"), wv
	SetDimLabel ROWS, 17, $("PSC ratio decay times delta"), wv
	// unused entries are not labeled
	SetDimLabel ROWS, 20, $("Low pass filter cut off"), wv
	SetDimLabel ROWS, 21, $("Low pass filter cut off delta"), wv
	SetDimLabel ROWS, 22, $("High pass filter cut off"), wv
	SetDimLabel ROWS, 23, $("High pass filter cut off delta"), wv
	SetDimLabel ROWS, 24, $("Chirp end frequency"), wv
	SetDimLabel ROWS, 25, $("Chirp end frequency delta"), wv
	SetDimLabel ROWS, 26, $("Noise filter order"), wv
	SetDimLabel ROWS, 27, $("Noise filter order delta"), wv
	SetDimLabel ROWS, 28, $("PT [First Mixed Frequency]"), wv
	SetDimLabel ROWS, 29, $("PT [First Mixed Frequency] delta"), wv
	SetDimLabel ROWS, 30, $("PT [Last Mixed Frequency]"), wv
	SetDimLabel ROWS, 31, $("PT [Last Mixed Frequency] delta"), wv
	// unused entries are not labeled
	SetDimLabel ROWS, 39, $("Reseed RNG for each epoch"), wv
	// unused entry, previously the global delta operation
	SetDimLabel ROWS, 41, $("PT [Mixed Frequency]"), wv
	SetDimLabel ROWS, 42, $("PT [Shuffle]"), wv
	SetDimLabel ROWS, 43, $("Chirp type [Log or sin]"), wv
	SetDimLabel ROWS, 44, $("Poisson distribution true/false"), wv
	SetDimLabel ROWS, 45, $("Number of pulses"), wv
	SetDimLabel ROWS, 46, $("Duration type [User/Automatic]"), wv
	SetDimLabel ROWS, 47, $("Number of pulses delta"), wv
	SetDimLabel ROWS, 48, $("Random Seed"), wv
	SetDimLabel ROWS, 49, $("Reseed RNG for each step"), wv
	// `dme` means `delta multiplier/exponential`
	SetDimLabel ROWS, 50, $("Amplitude dme"), wv
	SetDimLabel ROWS, 51, $("Offset dme"), wv
	SetDimLabel ROWS, 52, $("Duration dme"), wv
	SetDimLabel ROWS, 53, $("Trigonometric function Sin/Cos"), wv
	SetDimLabel ROWS, 54, $("Noise Type [White, Pink, Brown]"), wv
	SetDimLabel ROWS, 55, $("Build resolution (index)"), wv
	SetDimLabel ROWS, 56, $("Pulse train type (index)"), wv
	SetDimLabel ROWS, 57, $("Sin/chirp/saw frequency dme"), wv
	SetDimLabel ROWS, 58, $("Train pulse duration dme"), wv
	SetDimLabel ROWS, 59, $("PSC exp rise time dme"), wv
	SetDimLabel ROWS, 60, $("PSC exp decay time 1/2 dme"), wv
	SetDimLabel ROWS, 61, $("PSC exp decay time 2/2 dme"), wv
	SetDimLabel ROWS, 62, $("PSC ratio decay times dme"), wv
	SetDimLabel ROWS, 63, $("Low pass filter cut off dme"), wv
	SetDimLabel ROWS, 64, $("High pass filter cut off dme"), wv
	SetDimLabel ROWS, 65, $("Chirp end frequency dme"), wv
	SetDimLabel ROWS, 66, $("Noise filter order dme"), wv
	SetDimLabel ROWS, 67, $("PT [First Mixed Frequency] dme"), wv
	SetDimLabel ROWS, 68, $("PT [Last Mixed Frequency] dme"), wv
	SetDimLabel ROWS, 69, $("Number of pulses dme"), wv
	SetDimLabel ROWS, 70, $("Amplitude op"), wv
	SetDimLabel ROWS, 71, $("Offset op"), wv
	SetDimLabel ROWS, 72, $("Duration op"), wv
	SetDimLabel ROWS, 73, $("Sin/chirp/saw frequency op"), wv
	SetDimLabel ROWS, 74, $("Train pulse duration op"), wv
	SetDimLabel ROWS, 75, $("PSC exp rise time op"), wv
	SetDimLabel ROWS, 76, $("PSC exp decay time 1/2 op"), wv
	SetDimLabel ROWS, 77, $("PSC exp decay time 2/2 op"), wv
	SetDimLabel ROWS, 78, $("PSC ratio decay times op"), wv
	SetDimLabel ROWS, 79, $("Low pass filter cut off op"), wv
	SetDimLabel ROWS, 80, $("High pass filter cut off op"), wv
	SetDimLabel ROWS, 81, $("Chirp end frequency op"), wv
	SetDimLabel ROWS, 82, $("Noise filter order op"), wv
	SetDimLabel ROWS, 83, $("PT [First Mixed Frequency] op"), wv
	SetDimLabel ROWS, 84, $("PT [Last Mixed Frequency] op"), wv
	SetDimLabel ROWS, 85, $("Number of pulses op"), wv
	SetDimLabel ROWS, 86, $("Noise RNG type"), wv
	SetDimLabel ROWS, 87, $("Noise RNG type [Mixed Freq]"), wv
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
/// - Noise
/// - Sin
/// - Saw tooth
/// - Pulse train
/// - PSC
/// - Load custom wave
/// - Combine
Function/WAVE GetWaveBuilderWaveParam()

	DFREF           dfr = GetWaveBuilderDataPath()
	WAVE/Z/SDFR=dfr wv  = WP

	if(WaveExists(wv))
		UpgradeWaveParam(wv)
	else
		WAVE wv = GetWaveBuilderWaveParamAsFree()
		MoveWave wv, dfr:WP
	endif

	return wv
End

/// @brief Return a free wave version of GetWaveBuilderWaveParam()
///
/// @sa GetWaveBuilderWaveParam()
Function/WAVE GetWaveBuilderWaveParamAsFree()

	Make/D/N=(88, 100, EPOCH_TYPES_TOTAL_NUMBER)/FREE wv

	// noise low/high pass filter to off
	wv[20][][EPOCH_TYPE_NOISE] = 0
	wv[22][][EPOCH_TYPE_NOISE] = 0

	// noise filter order
	wv[26][][EPOCH_TYPE_NOISE] = 6

	// per epoch RNG seed
	wv[39][][] = 1

	// noise type
	wv[54][][EPOCH_TYPE_NOISE] = 0

	// noise generator types
	// compatibility defaults are set in UpgradeWaveParam()
	wv[86][][] = NOISE_GEN_XOSHIRO
	wv[87][][] = NOISE_GEN_XOSHIRO

	AddDimLabelsToWP(wv)
	SetWaveVersion(wv, WP_WAVE_LAYOUT_VERSION)

	return wv
End

static Constant WPT_WAVE_LAYOUT_VERSION = 11

/// @brief Automated testing helper
static Function GetWPTVersion()

	return WPT_WAVE_LAYOUT_VERSION
End

/// @brief Upgrade the wave layout of `WPT` to the most recent one
///        as defined in `WPT_WAVE_LAYOUT_VERSION`
Function UpgradeWaveTextParam(WAVE/T wv)

	string params, names, name, type
	variable numEntries, i

	if(ExistsWithCorrectLayoutVersion(wv, WPT_WAVE_LAYOUT_VERSION))
		return NaN
	endif

	Redimension/N=(51, -1, EPOCH_TYPES_TOTAL_NUMBER) wv
	AddDimLabelsToWPT(wv)

	// upgrade to wave version 7
	if(WaveVersionIsSmaller(wv, 7))
		// move entries into the epoch specific settings
		// version 6 and lower did only have one layer
		wv[%$("Custom epoch wave name")][][EPOCH_TYPE_CUSTOM] = wv[%$("Custom epoch wave name")][q][INDEP_EPOCH_TYPE]
		wv[%$("Custom epoch wave name")][][INDEP_EPOCH_TYPE]  = ""

		wv[%$("Combine epoch formula")][][EPOCH_TYPE_COMBINE] = wv[%$("Combine epoch formula")][q][INDEP_EPOCH_TYPE]
		wv[%$("Combine epoch formula")][][INDEP_EPOCH_TYPE]   = ""

		wv[%$("Combine epoch formula version")][][EPOCH_TYPE_COMBINE] = wv[%$("Combine epoch formula version")][q][INDEP_EPOCH_TYPE]
		wv[%$("Combine epoch formula version")][][INDEP_EPOCH_TYPE]   = ""
	endif

	// upgrade analysis parmeters
	// we need to URL encode the string/textwave entries, this is done by
	// WB_AddAnalysisParameterIntoWPT, and that also takes care of moving it
	// into the right place
	if(WaveVersionIsSmaller(wv, 10))
		params = wv[10][%Set][INDEP_EPOCH_TYPE]
		names  = AFH_GetListOfAnalysisParamNames(params)

		numEntries = ItemsInList(names)
		for(i = 0; i < numEntries; i += 1)
			name = Stringfromlist(i, names)
			type = AFH_GetAnalysisParamType(name, params)
			strswitch(type)
				case "string":
					WB_AddAnalysisParameterIntoWPT(wv, name, str = AFH_GetAnalysisParamTextual(name, params, percentDecoded = 0))
					break
				case "textwave":
					WB_AddAnalysisParameterIntoWPT(wv, name, wv = AFH_GetAnalysisParamTextWave(name, params, percentDecoded = 0))
					break
				case "variable":
					WB_AddAnalysisParameterIntoWPT(wv, name, var = AFH_GetAnalysisParamNumerical(name, params))
					break
				case "wave":
					WB_AddAnalysisParameterIntoWPT(wv, name, wv = AFH_GetAnalysisParamWave(name, params))
					break
				default:
					FATAL_ERROR("Unknown type")
					break
			endswitch
		endfor

		// clear old entry
		wv[10][%Set][INDEP_EPOCH_TYPE] = ""
	endif

	// upgrade to wave version 11 is done in AddDimLabelsToWPT (liberal object names)

	SetWaveVersion(wv, WPT_WAVE_LAYOUT_VERSION)
End

/// @brief Add dimension labels to the WaveBuilder `WPT` wave
static Function AddDimLabelsToWPT(WAVE wv)

	variable i

	RemoveAllDimLabels(wv)

	SetDimLabel ROWS, 0, $("Custom epoch wave name"), wv
	SetDimLabel ROWS, 1, $("Analysis pre DAQ function"), wv
	SetDimLabel ROWS, 2, $("Analysis mid sweep function"), wv
	SetDimLabel ROWS, 3, $("Analysis post sweep function"), wv
	SetDimLabel ROWS, 4, $("Analysis post set function"), wv
	SetDimLabel ROWS, 5, $("Analysis post DAQ function"), wv
	SetDimLabel ROWS, 6, $("Combine epoch formula"), wv
	SetDimLabel ROWS, 7, $("Combine epoch formula version"), wv
	// not renamed as this is v1/v2 only and therefore deprecated already
	SetDimLabel ROWS, 8, $("Analysis pre sweep function"), wv
	SetDimLabel ROWS, 9, $("Analysis function (generic)"), wv
	// empty: was "Analysis function params"
	SetDimLabel ROWS, 11, $("Amplitude ldel"), wv
	SetDimLabel ROWS, 12, $("Offset ldel"), wv
	SetDimLabel ROWS, 13, $("Duration ldel"), wv
	SetDimLabel ROWS, 14, $("Sin/chirp/saw frequency ldel"), wv
	SetDimLabel ROWS, 15, $("Train pulse duration ldel"), wv
	SetDimLabel ROWS, 16, $("PSC exp rise time ldel"), wv
	SetDimLabel ROWS, 17, $("PSC exp decay time 1/2 ldel"), wv
	SetDimLabel ROWS, 18, $("PSC exp decay time 2/2 ldel"), wv
	SetDimLabel ROWS, 19, $("PSC ratio decay times ldel"), wv
	SetDimLabel ROWS, 20, $("Low pass filter cut off ldel"), wv
	SetDimLabel ROWS, 21, $("High pass filter cut off ldel"), wv
	SetDimLabel ROWS, 22, $("Chirp end frequency ldel"), wv
	SetDimLabel ROWS, 23, $("Noise filter order ldel"), wv
	SetDimLabel ROWS, 24, $("PT [First Mixed Frequency] ldel"), wv
	SetDimLabel ROWS, 25, $("PT [Last Mixed Frequency] ldel"), wv
	SetDimLabel ROWS, 26, $("Number of pulses ldel"), wv
	SetDimLabel ROWS, 27, $("Analysis pre set function"), wv
	SetDimLabel ROWS, 28, $("Inter trial interval ldel"), wv
	SetDimLabel ROWS, 29, $("Analysis function params (encoded)"), wv

	for(i = 0; i < WB_TOTAL_NUMBER_OF_EPOCHS; i += 1)
		SetDimLabel COLS, i, $("Epoch " + num2str(i)), wv
	endfor

	SetDimLabel COLS, DimSize(wv, COLS) - 1, $("Set"), wv

	SetDimLabel LAYERS, -1, $("Epoch type"), wv
	SetDimLabel LAYERS, 0, $("Square pulse"), wv
	SetDimLabel LAYERS, 1, $("Ramp"), wv
	SetDimLabel LAYERS, 2, $("Noise"), wv
	SetDimLabel LAYERS, 3, $("Sin"), wv
	SetDimLabel LAYERS, 4, $("Saw tooth"), wv
	SetDimLabel LAYERS, 5, $("Pulse train"), wv
	SetDimLabel LAYERS, 6, $("PSC"), wv
	SetDimLabel LAYERS, 7, $("Load custom wave"), wv
	SetDimLabel LAYERS, 8, $("Combine"), wv
End

/// @brief Return the parameter text wave for the wave builder panel
///
/// Rows:
/// -  0: Name of the custom wave for #EPOCH_TYPE_CUSTOM (legacy format: wave
///       name only, current format: absolute path including the wave name)
/// -  1: Analysis function, pre daq (deprecated)
/// -  2: Analysis function, mid sweep (deprecated)
/// -  3: Analysis function, post sweep (deprecated)
/// -  4: Analysis function, post set (deprecated)
/// -  5: Analysis function, post daq (deprecated)
/// -  6: Formula
/// -  7: Formula version: "[[:digit:]]+"
/// -  8: Analysis function, pre sweep (deprecated)
/// -  9: Analysis function, generic
/// - 10: Unused
/// - 11-26: Explicit delta values. `;` separated list as long as the number of sweeps.
/// - 27: Analysis function, pre set (deprecated)
/// - 28: Explicit delta value for "Inter trial interval"
/// - 29: Analysis function parameters. See below for a detailed explanation.
/// - 30-50: unused
///
/// `Formula` and `Formula Version` are in the #EPOCH_TYPE_COMBINE layer, the
/// custom wave name is in the #EPOCH_TYPE_CUSTOM layer. 11 to 26 are for all
/// epoch types. The rest is layer independent (aka a setting for the full set)
/// in #INDEP_EPOCH_TYPE.
///
/// Columns:
/// - Segment/Epoch, the very last index is reserved for
///   textual settings for the complete set
///
/// Layers hold different stimulus wave form types:
/// - Square pulse/Set specific settings
/// - Ramp
/// - Noise
/// - Sin
/// - Saw tooth
/// - Pulse train
/// - PSC
/// - Load custom wave
/// - Combine
///
/// Analysis function parameters
///
/// Format of a single parameter:
/// - `name:(variable|string|wave|textwave)=value`
///
/// For these building blocks the following restrictions hold
/// - `name`: Must be a valid non-liberal igor object name
/// - `value`: URL-encoded payload, see
///            [URL-encoding](https://en.wikipedia.org/wiki/Percent-encoding) for
///            background information. Decoding is done by
///            AFH_GetAnalysisParamTextual() and AFH_GetAnalysisParamNumerical().
///
/// Multiple entries are separated by comma (`,`).
Function/WAVE GetWaveBuilderWaveTextParam()

	DFREF             dfr = GetWaveBuilderDataPath()
	WAVE/Z/T/SDFR=dfr wv  = WPT

	if(WaveExists(wv))
		UpgradeWaveTextParam(wv)
	else
		WAVE/T wv = GetWaveBuilderWaveTextParamAsFree()
		MoveWave wv, dfr:WPT
	endif

	return wv
End

/// @brief Return a free wave version of GetWaveBuilderWaveTextParam()
///
/// @sa GetWaveBuilderWaveTextParam()
Function/WAVE GetWaveBuilderWaveTextParamAsFree()

	Make/FREE/N=(51, 100, EPOCH_TYPES_TOTAL_NUMBER)/T wv
	AddDimLabelsToWPT(wv)
	SetWaveVersion(wv, WPT_WAVE_LAYOUT_VERSION)

	return wv
End

static Constant SEGWVTYPE_WAVE_LAYOUT_VERSION = 7

/// @brief Automated testing helper
static Function GetSegWvTypeVersion()

	return SEGWVTYPE_WAVE_LAYOUT_VERSION
End

/// @brief Upgrade the wave layout of `SegWvType` to the most recent one
///        as defined in `SEGWVTYPE_WAVE_LAYOUT_VERSION`
Function UpgradeSegWvType(WAVE wv)

	if(ExistsWithCorrectLayoutVersion(wv, SEGWVTYPE_WAVE_LAYOUT_VERSION))
		return NaN
	endif

	// no upgrade to double precision

	AddDimLabelsToSegWvType(wv)
	SetWaveVersion(wv, SEGWVTYPE_WAVE_LAYOUT_VERSION)
End

/// @brief Add dimension labels to the WaveBuilder `SegWvType` wave
static Function AddDimLabelsToSegWvType(WAVE wv)

	variable i

	ASSERT(WB_TOTAL_NUMBER_OF_EPOCHS < DimSize(wv, ROWS), "Number of reserved rows for epochs is larger than wave the itself")

	for(i = 0; i < WB_TOTAL_NUMBER_OF_EPOCHS; i += 1)
		SetDimLabel ROWS, i, $("Type of Epoch " + num2str(i)), wv
	endfor

	SetDimLabel ROWS, 94, $("Inter trial interval op"), wv
	SetDimLabel ROWS, 95, $("Inter trial interval dme"), wv
	SetDimLabel ROWS, 96, $("Inter trial interval delta"), wv
	SetDimLabel ROWS, 97, $("Stimset global RNG seed"), wv
	SetDimLabel ROWS, 98, $("Flip time axis"), wv
	SetDimLabel ROWS, 99, $("Inter trial interval"), wv
	SetDimLabel ROWS, 100, $("Total number of epochs"), wv
	SetDimLabel ROWS, 101, $("Total number of steps"), wv
End

/// @brief Returns the segment type wave used by the wave builder panel
/// Remember to change #WB_TOTAL_NUMBER_OF_EPOCHS if changing the wave layout
///
/// Rows:
/// - 0 - 93: epoch types using one of @ref WaveBuilderEpochTypes
/// - 94: Inter trial interval delta operation, one of @ref WaveBuilderDeltaOperationModes
/// - 95: Inter trial interval delta multiplier/exponent [a. u.]
/// - 96: Inter trial interval delta [s]
/// - 97: Stimset global RNG seed
/// - 98: Data flipping (1 or 0)
/// - 99: Inter trial interval [s]
/// - 100: total number of segments/epochs
/// - 101: total number of steps
Function/WAVE GetSegmentTypeWave()

	DFREF           dfr = GetWaveBuilderDataPath()
	WAVE/Z/SDFR=dfr wv  = SegWvType

	if(WaveExists(wv))
		UpgradeSegWvType(wv)
	else
		WAVE wv = GetSegmentTypeWaveAsFree()
		MoveWave wv, dfr:SegWvType
	endif

	return wv
End

/// @brief Return a free wave version of GetSegmentTypeWave()
///
/// @sa GetSegmentTypeWave()
Function/WAVE GetSegmentTypeWaveAsFree()

	Make/N=102/D/FREE wv

	wv[100] = 1
	wv[101] = 1

	AddDimLabelsToSegWvType(wv)
	SetWaveVersion(wv, SEGWVTYPE_WAVE_LAYOUT_VERSION)

	return wv
End

/// @brief Return the wave identifiying the begin and
/// end times of the current epoch
Function/WAVE GetEpochID()

	DFREF dfr = GetWaveBuilderDataPath()

	WAVE/Z/SDFR=dfr wv = epochID

	if(WaveExists(wv))
		return wv
	endif

	Make/R/N=(100, 2) dfr:epochID/WAVE=wv

	SetDimLabel COLS, 0, timeBegin, wv
	SetDimLabel COLS, 1, timeEnd, wv

	return wv
End

/// @brief Return the wave for visualization of the stim set
/// in the wavebuilder panel
Function/WAVE GetWaveBuilderDispWave()

	DFREF           dfr = GetWaveBuilderDataPath()
	WAVE/Z/SDFR=dfr wv  = dispData

	if(WaveExists(wv))
		return wv
	endif

	Make/R/N=(0) dfr:dispData/WAVE=wv

	return wv
End

Function/WAVE GetWBEpochCombineList(variable channelType)

	// remove the existing wave which is not channel type aware
	DFREF             dfr = GetWaveBuilderDataPath()
	WAVE/Z/T/SDFR=dfr wv  = epochCombineList
	KillOrMoveToTrash(wv = wv)

	switch(channelType)
		case CHANNEL_TYPE_DAC:
			DFREF dfr = GetWaveBuilderDataDAPath()
			break
		case CHANNEL_TYPE_TTL:
			DFREF dfr = GetWaveBuilderDataTTLPath()
			break
		default:
			FATAL_ERROR("Unknown channel type")
	endswitch

	WAVE/Z/T/SDFR=dfr wv = epochCombineList

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(0, 2) dfr:epochCombineList/WAVE=wv

	SetDimLabel 1, 0, Shorthand, wv
	SetDimLabel 1, 1, Stimset, wv

	WB_UpdateEpochCombineList(wv, channelType)

	return wv
End

/// @brief Returns the segment wave which stores the stimulus set of one segment/epoch
/// @param duration time of the stimulus in ms
Function/WAVE GetSegmentWave([variable duration])

	variable numPoints

	DFREF dfr = GetWaveBuilderDataPath()
	WAVE/Z/SDFR=dfr SegmentWave

	if(ParamIsDefault(duration))
		return segmentWave
	endif

	if(duration > MAX_SWEEP_DURATION_IN_MS)
		DoAbortNow("Sweeps are currently limited to 30 minutes in duration.\rAdjust MAX_SWEEP_DURATION_IN_MS to change that!")
	endif

	numPoints = ceil(duration / WAVEBUILDER_MIN_SAMPINT)
	// optimization: recreate the wave only if necessary or just resize it
	if(!WaveExists(SegmentWave))
		Make/R/N=(numPoints) dfr:SegmentWave/WAVE=SegmentWave
	elseif(numPoints != DimSize(SegmentWave, ROWS))
		Redimension/N=(numPoints) SegmentWave
	endif

	SetScale/P x, 0, WAVEBUILDER_MIN_SAMPINT, "ms", SegmentWave

	return SegmentWave
End

Function/WAVE GetEpochParameterNames()

	DFREF             dfr = GetWaveBuilderDataPath()
	WAVE/Z/T/SDFR=dfr wv  = epochParameterNames

	if(WaveExists(wv))
		return wv
	endif

	// IPT_FORMAT_OFF
	/// Generated code, see WBP_RegenerateEpochParameterNamesCode
	///@{
	Make/T/FREE st_0 = {"Amplitude", "Amplitude delta", "Amplitude dme", "Amplitude ldel", "Amplitude op", "Duration", "Duration delta", "Duration dme", "Duration ldel", "Duration op"}
	Make/T/FREE st_1 = {"Amplitude", "Amplitude delta", "Amplitude dme", "Amplitude ldel", "Amplitude op", "Duration", "Duration delta", "Duration dme", "Duration ldel", "Duration op", "Offset", "Offset delta", "Offset dme", "Offset ldel", "Offset op"}
	Make/T/FREE st_2 = {"Amplitude", "Amplitude delta", "Amplitude dme", "Amplitude ldel", "Amplitude op", "Build resolution (index)", "Duration", "Duration delta", "Duration dme", "Duration ldel", "Duration op", "High pass filter cut off", "High pass filter cut off delta", "High pass filter cut off dme", "High pass filter cut off ldel", "High pass filter cut off op", "Low pass filter cut off", "Low pass filter cut off delta", "Low pass filter cut off dme", "Low pass filter cut off ldel", "Low pass filter cut off op", "Noise filter order", "Noise filter order delta", "Noise filter order dme", "Noise filter order ldel", "Noise filter order op", "Noise Type [White, Pink, Brown]", "Offset", "Offset delta", "Offset dme", "Offset ldel", "Offset op", "Random Seed", "Reseed RNG for each epoch", "Reseed RNG for each step"}
	Make/T/FREE st_3 = {"Amplitude", "Amplitude delta", "Amplitude dme", "Amplitude ldel", "Amplitude op", "Chirp end frequency", "Chirp end frequency delta", "Chirp end frequency dme", "Chirp end frequency ldel", "Chirp end frequency op", "Chirp type [Log or sin]", "Duration", "Duration delta", "Duration dme", "Duration ldel", "Duration op", "Offset", "Offset delta", "Offset dme", "Offset ldel", "Offset op", "Sin/chirp/saw frequency", "Sin/chirp/saw frequency delta", "Sin/chirp/saw frequency dme", "Sin/chirp/saw frequency ldel", "Sin/chirp/saw frequency op", "Trigonometric function Sin/Cos"}
	Make/T/FREE st_4 = {"Amplitude", "Amplitude delta", "Amplitude dme", "Amplitude ldel", "Amplitude op", "Duration", "Duration delta", "Duration dme", "Duration ldel", "Duration op", "Offset", "Offset delta", "Offset dme", "Offset ldel", "Offset op", "Sin/chirp/saw frequency", "Sin/chirp/saw frequency delta", "Sin/chirp/saw frequency dme", "Sin/chirp/saw frequency ldel", "Sin/chirp/saw frequency op"}
	Make/T/FREE st_5 = {"Amplitude", "Amplitude delta", "Amplitude dme", "Amplitude ldel", "Amplitude op", "Duration", "Duration delta", "Duration dme", "Duration ldel", "Duration op", "Duration type [User/Automatic]", "Number of pulses", "Number of pulses delta", "Number of pulses dme", "Number of pulses ldel", "Number of pulses op", "Offset", "Offset delta", "Offset dme", "Offset ldel", "Offset op", "Poisson distribution true/false", "PT [First Mixed Frequency]", "PT [First Mixed Frequency] delta", "PT [First Mixed Frequency] dme", "PT [First Mixed Frequency] ldel", "PT [First Mixed Frequency] op", "PT [Last Mixed Frequency]", "PT [Last Mixed Frequency] delta", "PT [Last Mixed Frequency] dme", "PT [Last Mixed Frequency] ldel", "PT [Last Mixed Frequency] op", "PT [Mixed Frequency]", "PT [Shuffle]", "Pulse train type (index)", "Random Seed", "Reseed RNG for each epoch", "Reseed RNG for each step", "Sin/chirp/saw frequency", "Sin/chirp/saw frequency delta", "Sin/chirp/saw frequency dme", "Sin/chirp/saw frequency ldel", "Sin/chirp/saw frequency op", "Train pulse duration", "Train pulse duration delta", "Train pulse duration dme", "Train pulse duration ldel", "Train pulse duration op"}
	Make/T/FREE st_6 = {"Amplitude", "Amplitude delta", "Amplitude dme", "Amplitude ldel", "Amplitude op", "Duration", "Duration delta", "Duration dme", "Duration ldel", "Duration op", "Offset", "Offset delta", "Offset dme", "Offset ldel", "Offset op", "PSC exp decay time 1/2", "PSC exp decay time 1/2 delta", "PSC exp decay time 1/2 dme", "PSC exp decay time 1/2 ldel", "PSC exp decay time 1/2 op", "PSC exp decay time 2/2", "PSC exp decay time 2/2 delta", "PSC exp decay time 2/2 dme", "PSC exp decay time 2/2 ldel", "PSC exp decay time 2/2 op", "PSC exp rise time", "PSC exp rise time delta", "PSC exp rise time dme", "PSC exp rise time ldel", "PSC exp rise time op", "PSC ratio decay times", "PSC ratio decay times delta", "PSC ratio decay times dme", "PSC ratio decay times ldel", "PSC ratio decay times op"}
	Make/T/FREE st_7 = {"Custom epoch wave name", "Offset", "Offset delta", "Offset dme", "Offset ldel", "Offset op"}
	Make/T/FREE st_8 = {"Combine epoch formula", "Combine epoch formula version"}
	///@}
	// IPT_FORMAT_ON

	Make/FREE sizes = {DimSize(st_0, ROWS), DimSize(st_1, ROWS), DimSize(st_2, ROWS), DimSize(st_3, ROWS), DimSize(st_4, ROWS), DimSize(st_5, ROWS), DimSize(st_6, ROWS), DimSize(st_7, ROWS), DimSize(st_8, ROWS)}

	Redimension/N=(WaveMax(sizes)) st_0, st_1, st_2, st_3, st_4, st_5, st_6, st_7, st_8

	Concatenate/FREE/T {st_0, st_1, st_2, st_3, st_4, st_5, st_6, st_7, st_8}, wv

	MatrixTranspose wv

	MoveWave wv, dfr:epochParameterNames

	SetDimLabel ROWS, -1, $("Epoch type"), wv
	SetDimLabel ROWS, 0, $("Square pulse"), wv
	SetDimLabel ROWS, 1, $("Ramp"), wv
	SetDimLabel ROWS, 2, $("Noise"), wv
	SetDimLabel ROWS, 3, $("Sin"), wv
	SetDimLabel ROWS, 4, $("Saw tooth"), wv
	SetDimLabel ROWS, 5, $("Pulse train"), wv
	SetDimLabel ROWS, 6, $("PSC"), wv
	SetDimLabel ROWS, 7, $("Load custom wave"), wv
	SetDimLabel ROWS, 8, $("Combine"), wv

	return wv
End

///@}

/// @name Asynchronous Measurements
///@{

/// @brief Return a *free* wave for the asyncSettingsWave, data wave
///
/// asyncSettingsWave is used to save async settings for each
/// data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
///  - One row
///
/// Columns:
/// - Same as GetAsyncSettingsKeyWave
///
/// Layers:
///  - 0 - #LABNOTEBOOK_LAYER_COUNT: headstage dependent and independent entries
Function/WAVE GetAsyncSettingsWave()

	Make/D/N=(1, 7, LABNOTEBOOK_LAYER_COUNT)/FREE wv
	wv = NaN

	SetDimLabel COLS, 0, ADOnOff, wv
	SetDimLabel COLS, 1, ADGain, wv
	SetDimLabel COLS, 2, AlarmOnOff, wv
	SetDimLabel COLS, 3, AlarmMin, wv
	SetDimLabel COLS, 4, AlarmMax, wv
	SetDimLabel COLS, 5, MeasuredValue, wv
	SetDimLabel COLS, 6, AlarmState, wv

	return wv
End

/// @brief Return a *free* wave for the asyncSettingsKeyWave
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
/// - 0: Async AD $Channel OnOff
/// - 1: Async AD $Channel Gain
/// - 2: Async Alarm $Channel OnOff
/// - 3: Async Alarm $Channel Min
/// - 4: Async Alarm  $Channel Max
/// - 5: Async AD $Channel [$Title]
Function/WAVE GetAsyncSettingsKeyWave(WAVE settingsWave, variable channel, string title, string unit)

	string prefix

	sprintf prefix, "Async %d", channel

	Make/T/N=(3, 7)/FREE wv
	wv = ""

	CopyDimLabels settingsWave, wv

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units, wv
	SetDimLabel ROWS, 2, Tolerance, wv

	wv[%Parameter][0] = prefix + " On/Off"
	wv[%Units][0]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][0] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][1] = prefix + " Gain"
	wv[%Units][1]     = ""
	wv[%Tolerance][1] = ".001"

	sprintf prefix, "Async Alarm %d", channel

	wv[%Parameter][2] = prefix + " On/Off"
	wv[%Units][2]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][2] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][3] = prefix + " Min"
	wv[%Units][3]     = ""
	wv[%Tolerance][3] = ".001"

	// two spaces before number, use the same name for compatibility reasons
	sprintf prefix, "Async Alarm  %d", channel

	wv[%Parameter][4] = prefix + " Max"
	wv[%Units][4]     = ""
	wv[%Tolerance][4] = ".001"

	sprintf prefix, "Async AD %d [%s]", channel, title

	wv[%Parameter][5] = prefix
	wv[%Units][5]     = unit
	wv[%Tolerance][5] = "" // tolerance is calculated in ED_createAsyncWaveNoteTags()

	sprintf prefix, "Async Alarm %d", channel

	wv[%Parameter][6] = prefix + " State"
	wv[%Units][6]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][6] = LABNOTEBOOK_NO_TOLERANCE

	return wv
End

/// @brief Return a *free* wave for the AsyncSettingsTxtWave
///
/// AsyncSettingsTxtData is used to store the async text settings used on a particular
/// headstage and then create waveNotes for the sweep data
///
/// Rows:
/// - Only one
///
/// Columns:
/// - Same as GetAsyncSettingsTextKeyWave
///
/// Layers:
/// - 0 - #LABNOTEBOOK_LAYER_COUNT: headstage dependent and independent entries
Function/WAVE GetAsyncSettingsTextWave()

	Make/T/N=(1, 2, LABNOTEBOOK_LAYER_COUNT)/FREE wv
	wv = ""

	SetDimLabel COLS, 0, Title, wv
	SetDimLabel COLS, 1, Unit, wv

	return wv
End

/// @brief Return a *free* wave for the AsyncSettingsKeyTxtData
///
/// AsyncSettingsKeyTxtData is used to index Txt Key Wave
///
/// Rows:
/// - Just one
///
/// Columns:
/// - 0: Async $Channel Title
/// - 1: Async $Channel Unit
Function/WAVE GetAsyncSettingsTextKeyWave(WAVE/T settingsWave, variable channel)

	string prefix

	Make/T/N=(1, 2)/FREE wv
	wv = ""

	CopyDimLabels settingsWave, wv

	sprintf prefix, "Async AD%d", channel

	wv[0][0] = prefix + " Title"
	wv[0][1] = prefix + " Unit"

	return wv
End

///@}

/// @name Pressure Control
///@{

/// @brief Returns device specific pressure folder as string
Function/S P_GetDevicePressureFolderAS(string device)

	string DeviceNumber
	string DeviceType
	ParseDeviceString(device, deviceType, deviceNumber)
	string FolderPathString
	sprintf FolderPathString, "%s:Pressure:%s:Device_%s", GetMiesPathAsString(), DeviceType, DeviceNumber
	return FolderPathString
End

/// @brief Creates device specific pressure folder - used to store data for pressure regulators
///
/// UTF_NOINSTRUMENTATION
Function/DF P_DeviceSpecificPressureDFRef(string device)

	return CreateDFWithAllParents(P_GetDevicePressureFolderAS(device))
End

/// @brief Returns pressure folder as string
///
/// UTF_NOINSTRUMENTATION
Function/S P_GetPressureFolderAS(string device)

	return GetMiesPathAsString() + ":Pressure"
End

/// @brief Returns the data folder reference for the main pressure folder "root:MIES:Pressure"
///
/// UTF_NOINSTRUMENTATION
Function/DF P_PressureFolderReference(string device)

	return CreateDFWithAllParents(P_GetPressureFolderAS(device))
End

/// @brief Returns a wave reference to the DAQ data wave used for pressure pulses
///
/// Rows:
/// - data points, see P_GetITCChanConfig() for the sampling interval
///
/// Columns:
/// - 0: DA data
/// - 1: AD data
/// - 2: TTL data rack 0
/// - 3: TTL data rack 1 (available if supported by the device)
Function/WAVE P_GetITCData(string device)

	DFREF dfr = P_DeviceSpecificPressureDFRef(device)

	WAVE/Z/T/SDFR=dfr P_ITCData

	if(WaveExists(P_ITCData))
		return P_ITCData
	endif

	Make/W/N=(2^MINIMUM_ITCDATAWAVE_EXPONENT, 4) dfr:P_ITCData/WAVE=wv

	SetDimLabel COLS, 0, DA, wv
	SetDimLabel COLS, 1, AD, wv
	SetDimLabel COLS, 2, TTL_R0, wv
	SetDimLabel COLS, 3, TTL_R1, wv
	wv = 0

	return wv
End

/// @brief Returns a wave reference to the DAQ config wave used for pressure pulses
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
Function/WAVE P_GetITCChanConfig(string device)

	DFREF dfr = P_DeviceSpecificPressureDFRef(device)

	WAVE/Z/T/SDFR=dfr P_ChanConfig

	if(WaveExists(P_ChanConfig))
		return P_ChanConfig
	endif

	Make/I/N=(4, 4) dfr:P_ChanConfig/WAVE=wv

	wv       = 0
	wv[0][0] = XOP_CHANNEL_TYPE_DAC
	wv[1][0] = XOP_CHANNEL_TYPE_ADC
	wv[2][0] = XOP_CHANNEL_TYPE_TTL
	wv[3][0] = XOP_CHANNEL_TYPE_TTL

	// invalid TTL channels
	wv[2][1] = -1
	wv[3][1] = -1

	wv[][2] = WAVEBUILDER_MIN_SAMPINT * MILLI_TO_MICRO

	SetDimLabel ROWS, 0, DA, wv
	SetDimLabel ROWS, 1, AD, wv
	SetDimLabel ROWS, 2, TTL_R0, wv
	SetDimLabel ROWS, 3, TTL_R1, wv

	SetDimLabel COLS, 0, Chan_Type, wv
	SetDimLabel COLS, 1, Chan_num, wv
	SetDimLabel COLS, 2, Samp_int, wv

	return wv
End

/// @brief Set the dimension labels for the numeric pressure wave
static Function SetPressureWaveDimLabels(WAVE wv)

	SetDimLabel COLS, 0, Approach_Seal_BrkIn_Clear, wv
	SetDimLabel COLS, 1, DAC_List_Index, wv
	SetDimLabel COLS, 2, HW_DAC_Type, wv
	SetDimLabel COLS, 3, DAC_DevID, wv
	SetDimLabel COLS, 4, DAC, wv
	SetDimLabel COLS, 5, DAC_Gain, wv
	SetDimLabel COLS, 6, ADC, wv
	SetDimLabel COLS, 7, ADC_Gain, wv
	SetDimLabel COLS, 8, TTL_A, wv
	SetDimLabel COLS, 9, PSI_air, wv
	SetDimLabel COLS, 10, PSI_solution, wv
	SetDimLabel COLS, 11, PSI_slice, wv
	SetDimLabel COLS, 12, PSI_nearCell, wv
	SetDimLabel COLS, 13, PSI_SealInitial, wv
	SetDimLabel COLS, 14, PSI_SealMax, wv
	SetDimLabel COLS, 15, solutionZaxis, wv
	SetDimLabel COLS, 16, sliceZaxis, wv
	SetDimLabel COLS, 17, cellZaxis, wv
	SetDimLabel COLS, 18, cellXaxis, wv
	SetDimLabel COLS, 19, cellYaxis, wv
	SetDimLabel COLS, 20, PlaceHolderZero, wv
	SetDimLabel COLS, 21, RealTimePressure, wv
	SetDimLabel COLS, 22, LastResistanceValue, wv
	SetDimLabel COLS, 23, SSResistanceSlope, wv
	SetDimLabel COLS, 24, ActiveTP, wv
	/// @todo If user switched headStage mode while pressure regulation is
	/// ongoing, pressure reg either needs to be turned off, or steady state
	/// slope values need to be used
	/// @todo Enable mode switching with TP running (auto stop TP, switch mode, auto startTP)
	/// @todo Enable headstate switching with TP running (auto stop TP, change headStage state, auto start TP)
	SetDimLabel COLS, 25, SSResistanceSlopeThreshold, wv
	// If the PeakResistance slope is greater than the SSResistanceSlope
	// thershold pressure method does not need to update i.e. the pressure is
	// "good" as it is
	SetDimLabel COLS, 26, TimeOfLastRSlopeCheck, wv
	SetDimLabel COLS, 27, LastPressureCommand, wv
	SetDimLabel COLS, 28, OngoingPessurePulse, wv
	SetDimLabel COLS, 29, LastVcom, wv
	SetDimLabel COLS, 30, ManSSPressure, wv
	SetDimLabel COLS, 31, ManPPPressure, wv
	SetDimLabel COLS, 32, ManPPDuration, wv
	SetDimLabel COLS, 33, LastPeakR, wv
	SetDimLabel COLS, 34, PeakR, wv
	SetDimLabel COLS, 35, TimePeakRcheck, wv
	SetDimLabel COLS, 36, PosCalConst, wv
	SetDimLabel COLS, 37, NegCalConst, wv
	SetDimLabel COLS, 38, ApproachNear, wv
	SetDimLabel COLS, 39, SealAtm, wv
	SetDimLabel COLS, 40, UserSelectedHeadStage, wv
	SetDimLabel COLS, 41, UserPressureOffset, wv
	SetDimLabel COLS, 42, UserPressureOffsetTotal, wv
	SetDimLabel COLS, 43, UserPressureOffsetPeriod, wv
	SetDimLabel COLS, 44, TTL_B, wv
	SetDimLabel COLS, 45, UserPressureDeviceID, wv
	SetDimLabel COLS, 46, UserPressureDeviceHWType, wv
	SetDimLabel COLS, 47, UserPressureDeviceADC, wv

	SetDimLabel ROWS, 0, Headstage_0, wv
	SetDimLabel ROWS, 1, Headstage_1, wv
	SetDimLabel ROWS, 2, Headstage_2, wv
	SetDimLabel ROWS, 3, Headstage_3, wv
	SetDimLabel ROWS, 4, Headstage_4, wv
	SetDimLabel ROWS, 5, Headstage_5, wv
	SetDimLabel ROWS, 6, Headstage_6, wv
	SetDimLabel ROWS, 7, Headstage_7, wv
End

/// @brief Returns wave reference of wave used to store data used in functions that run pressure regulators
/// creates the wave if it does not exist
///
/// Rows:
/// - 0 - 7: Headstage 0 through 7
///
/// Columns:
/// -  0: Pressure method. -1 = none, 0 = Approach, 1 = Seal, 2 = Break In, 3 = Clear
/// -  1: List position of DAC (used for presssure control) selected for headstage
/// -  2: Type of DAC, index into #HARDWARE_DAC_TYPES
/// -  3: Device ID used by Instrutech DACs or index into HW_NI_ListDevices depending on column 2
/// -  4: DA channel used for pressure regulation.
/// -  5: Gain of DA channel used for presssure regulation.
/// -  6: AD channel used for pressure regulation.
/// -  7: Gain of AD channel used for pressure regulation.
/// -  8: TTL channel A used for pressure regulation.
/// -  9: Pipette pressure setting while pipette is positioned in air/outside of bath.
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
/// - 21: Realtime pressure
/// - 22: Last steady state resistance value.
/// - 23: Slope of the peak TP resistance over the last 5 seconds.
/// - 24: State of the TP (0 = OFF, 1 = ON).
/// - 25: Slope threshold. Used to determine if pressure should be incremented during sealing.
/// - 26: Time of last slope check
/// - 27: Last pressure command.
/// - 28: State of pressure pulse (0 = OFF, 1 = ON).
/// - 29: Last amplifier voltage command.
/// - 30: Manual pressure command amplitude in psi.
/// - 31: Manual pressure pulse command amplitude in psi.
/// - 32: Manual pressure pulse duation in ms.
/// - 33: Peak resistance on previous method cycle.
/// - 34: Peak resistance on active method cycle.
/// - 35: Time of last peak resistance check.
/// - 36: Calibration constant for positive pulse.
/// - 37: Calibration constant for negative pulse.
/// - 38: Checkbox state of "Approach Near".
/// - 39: Checkbox state of "Seal Atmosphere".
/// - 40: Selected headstage by the slider.
/// - 41: User pressure offset in psi.
/// - 42: Total sum of user pressure offsets in psi.
/// - 43: Total sum of user pressure offsets since last pulse in psi.
/// - 44: TTL channel B used for pressure regulation.
/// - 45: User pressure deviceID
/// - 46: User pressure device hardware type
/// - 47: User pressure ADC
Function/WAVE P_GetPressureDataWaveRef(string device)

	variable          versionOfNewWave = 8
	DFREF             dfr              = P_DeviceSpecificPressureDFRef(device)
	WAVE/Z/D/SDFR=dfr wv               = PressureData

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/D/N=(8, 48) wv
		SetPressureWaveDimLabels(wv)
	else
		Make/D/N=(8, 48) dfr:PressureData/WAVE=wv

		SetPressureWaveDimLabels(wv)

		wv = NaN

		// prime the wave to avoid index out of range error for popup menus and to
		// set all pressure methods to OFF (-1)
		wv[][%Approach_Seal_BrkIn_Clear] = -1
		wv[][%DAC_List_Index]            = 0
		wv[][%DAC]                       = 0
		wv[][%ADC]                       = 0
		wv[][%TTL_A]                     = 0
		wv[][%TTL_B]                     = NaN
		wv[][%ApproachNear]              = 0
		wv[][%SealAtm]                   = 0
		wv[][%ManSSPressure]             = 0
		wv[][%LastPressureCommand]       = 0

		wv[][%DAC_Gain]        = 2
		wv[][%ADC_Gain]        = 0.5
		wv[][%PSI_air]         = 3.8
		wv[][%PSI_solution]    = 0.55
		wv[][%PSI_slice]       = 0.2
		wv[][%PSI_nearCell]    = 0.6
		wv[][%PSI_SealInitial] = -0.2
		wv[][%PSI_SealMax]     = -1.4
		wv[][%solutionZAxis]   = 3500
		wv[][%sliceZAxis]      = 350
	endif

	wv[][%UserPressureOffset]       = 0
	wv[][%UserPressureOffsetPeriod] = 0
	wv[][%UserPressureOffsetTotal]  = NaN
	wv[][%UserPressureDeviceID]     = NaN
	wv[][%UserPressureDeviceHWType] = NaN
	wv[][%UserPressureDeviceADC]    = NaN

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
Function/WAVE P_PressureDataTxtWaveRef(string device)

	variable versionOfNewWave = 1
	DFREF    dfr              = P_DeviceSpecificPressureDFRef(device)

	WAVE/Z/T/SDFR=dfr wv = PressureDataTextWv

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(8, 3) wv
	else
		Make/T/N=(8, 3) dfr:PressureDataTextWv/WAVE=wv
	endif

	SetDimLabel COLS, 0, Device, wv
	SetDimLabel COLS, 1, DA_Unit, wv
	SetDimLabel COLS, 2, AD_Unit, wv

	SetDimLabel ROWS, 0, Headstage_0, wv
	SetDimLabel ROWS, 1, Headstage_1, wv
	SetDimLabel ROWS, 2, Headstage_2, wv
	SetDimLabel ROWS, 3, Headstage_3, wv
	SetDimLabel ROWS, 4, Headstage_4, wv
	SetDimLabel ROWS, 5, Headstage_5, wv
	SetDimLabel ROWS, 6, Headstage_6, wv
	SetDimLabel ROWS, 7, Headstage_7, wv

	wv[][0]        = NONE
	wv[][%DA_Unit] = "psi"
	wv[][%AD_Unit] = "psi"

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End
///@}

/// @brief Return the data folder reference to the device specific lab notebook folder for temporary waves
///
/// UTF_NOINSTRUMENTATION
Function/DF GetDevSpecLabNBTempFolder(string device)

	return createDFWithAllParents(GetDevSpecLabNBTempFolderAS(device))
End

/// @brief Return the full path to the device specific lab notebook temp folder, e.g. root:MIES:LabNoteBook:ITC18USB:Device0:Temp
///
/// UTF_NOINSTRUMENTATION
Function/S GetDevSpecLabNBTempFolderAS(string device)

	return GetDevSpecLabNBFolderAsString(device) + ":" + LOGBOOK_WAVE_TEMP_FOLDER
End

/// @brief Return the full path to the results folder, e.g. root:MIES:Results
///
/// UTF_NOINSTRUMENTATION
Function/S GetResultsFolderAsString()

	return GetMiesPathAsString() + ":Results"
End

/// @brief Return the data folder reference to the results folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetResultsFolder()

	return createDFWithAllParents(GetResultsFolderAsString())
End

/// @name Analysis Browser
///@{

/// @brief Return the datafolder reference to the root folder for the analysis browser
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisFolder()

	return createDFWithAllParents(GetAnalysisFolderAS())
End

/// @brief Return the full path to the root analysis folder, e.g. root:MIES:analysis
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisFolderAS()

	return GetMiesPathAsString() + ":Analysis"
End

/// @brief Return the datafolder reference to the per experiment folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisExpFolder(string expFolder)

	return createDFWithAllParents(GetAnalysisExpFolderAS(expFolder))
End

/// @brief Return the full path to the per experiment folder, e.g. root:MIES:Analysis:my_experiment
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisExpFolderAS(string expFolder)

	return GetAnalysisFolderAS() + ":" + expFolder
End

/// @brief Return the datafolder reference to the per experiment general folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisExpGeneralFolder(string expFolder)

	return createDFWithAllParents(GetAnalysisExpGeneralFolderAS(expFolder))
End

/// @brief Return the full path to the per experiment geneal folder, e.g. root:MIES:Analysis:my_experiment:general
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisExpGeneralFolderAS(string expFolder)

	return GetAnalysisExpFolderAS(expFolder) + ":general"
End

/// @brief Return the datafolder reference to the per device folder of an experiment
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisDeviceFolder(string expFolder, string device)

	return createDFWithAllParents(GetAnalysisDeviceFolderAS(expFolder, device))
End

/// @brief Return the full path to the per device folder of an experiment, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisDeviceFolderAS(string expFolder, string device)

	return GetAnalysisExpFolderAS(expFolder) + ":" + device
End

/// @brief Return the datafolder reference to the sweep to channel relation of a device and experiment pair
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisDevChannelFolder(string expFolder, string device)

	return createDFWithAllParents(GetAnalysisDevChannelFolderAS(expFolder, device))
End

/// @brief Return the full path to the sweep to channel relation folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:channel
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisDevChannelFolderAS(string expFolder, string device)

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":channel"
End

/// @brief Return the datafolder reference to the sweep config folder of a device and experiment pair
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisDeviceConfigFolder(string expFolder, string device)

	return createDFWithAllParents(GetAnalysisDeviceConfigFolderAS(expFolder, device))
End

/// @brief Return the full path to the sweep config folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:config
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisDeviceConfigFolderAS(string expFolder, string device)

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":config"
End

/// @brief Return the datafolder reference to the testpulse folder of a device and experiment pair
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisDeviceTestpulse(string expFolder, string device)

	return createDFWithAllParents(GetAnalysisDeviceTestpulseAS(expFolder, device))
End

/// @brief Return the full path to the testpulse folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:testpulse
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisDeviceTestpulseAS(string expFolder, string device)

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":testpulse"
End

/// @brief Return the datafolder reference to the labnotebook folder of a device and experiment pair
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisLabNBFolder(string expFolder, string device)

	return createDFWithAllParents(GetAnalysisLabNBFolderAS(expFolder, device))
End

/// @brief Return the full path to the labnotebook folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:labnotebook
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisLabNBFolderAS(string expFolder, string device)

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":labnotebook"
End

/// @brief Return the datafolder reference to the sweep folder of a device and experiment pair
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisSweepPath(string expFolder, string device)

	return createDFWithAllParents(GetAnalysisSweepPathAsString(expFolder, device))
End

/// @brief Return the full path to the sweep folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:sweep
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisSweepPathAsString(string expFolder, string device)

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":sweep"
End

/// @brief Return the datafolder reference to the per sweep folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisSweepDataPath(string expFolder, string device, variable sweep)

	return createDFWithAllParents(GetAnalysisSweepDataPathAS(expFolder, device, sweep))
End

/// @brief Return the full path to the the per sweep folder, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:sweep:X_$sweep
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisSweepDataPathAS(string expFolder, string device, variable sweep)

	ASSERT(IsValidSweepNumber(sweep), "Expected finite sweep number")
	return GetSingleSweepFolderAsString(GetAnalysisSweepPath(expFolder, device), sweep)
End

/// @brief Return the datafolder reference to the stim set folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisStimSetPath(string expFolder, string device)

	return createDFWithAllParents(GetAnalysisStimSetPathAS(expFolder, device))
End

/// @brief Return the full path to the stim set folder, e.g. root:MIES:Analysis:my_experiment::stimset
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisStimSetPathAS(string expFolder, string device)

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":stimset"
End

/// @brief Return the datafolder reference to results folder of an experiment
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAnalysisResultsFolder(string expFolder)

	return createDFWithAllParents(GetAnalysisResultsFolderAsString(expFolder))
End

/// @brief Return the datafolder reference to results folder of an experiment, e.g. root:MIES:Analysis:my_experiment:results
///
/// UTF_NOINSTRUMENTATION
Function/S GetAnalysisResultsFolderAsString(string expFolder)

	return GetAnalysisExpFolderAS(expFolder) + ":results"
End

/// @brief Return one of the four results waves
///
/// @param expFolder experiment datafolder name
/// @param type      One of @ref LabnotebookWaveTypes
Function/WAVE GetAnalysisResultsWave(string expFolder, variable type)

	string name

	DFREF ref = GetAnalysisResultsFolder(expFolder)

	switch(type)
		case LBN_NUMERICAL_VALUES:
			name = LBN_NUMERICALRESULT_VALUES_NAME
			break
		case LBN_NUMERICAL_KEYS:
			name = LBN_NUMERICALRESULT_KEYS_NAME
			break
		case LBN_TEXTUAL_VALUES:
			name = LBN_TEXTUALRESULT_VALUES_NAME
			break
		case LBN_TEXTUAL_KEYS:
			name = LBN_TEXTUALRESULT_KEYS_NAME
			break
		default:
			FATAL_ERROR("Invalid type")
	endswitch

	WAVE/Z/SDFR=dfr wv = $name

	return wv
End

///  wave is used to relate it's index to sweepWave and deviceWave.
Function/WAVE GetAnalysisChannelStorage(string dataFolder, string device)

	variable versionOfWave = 2

	DFREF                dfr = GetAnalysisDevChannelFolder(dataFolder, device)
	WAVE/Z/WAVE/SDFR=dfr wv  = channelStorage

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(ExistsWithCorrectLayoutVersion(wv, 1))
		// update Dimension label
	else
		Make/R/O/N=(MINIMUM_WAVE_SIZE, 1)/WAVE dfr:channelStorage/WAVE=wv
		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	endif

	SetDimLabel COLS, 0, configSweep, wv

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return a wave containing all stimulus channels in the NWB file as a ";"-separated List
///  wave is used to relate it's index to sweepWave and deviceWave.
Function/WAVE GetAnalysisChannelStimWave(string dataFolder, string device)

	DFREF dfr = GetAnalysisDevChannelFolder(dataFolder, device)

	WAVE/Z/T/SDFR=dfr wv = stimulus

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/T dfr:stimulus/WAVE=wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return a wave containing all acquisition channels in the NWB file as a ";"-separated List
///  wave is used to relate it's index to sweepWave and deviceWave.
Function/WAVE GetAnalysisChannelAcqWave(string dataFolder, string device)

	DFREF dfr = GetAnalysisDevChannelFolder(dataFolder, device)

	WAVE/Z/T/SDFR=dfr wv = acquisition

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/T dfr:acquisition/WAVE=wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return a wave containing all sweeps in a unique fashion.
///  wave is used to relate it's index to channelWave and deviceWave
Function/WAVE GetAnalysisChannelSweepWave(string dataFolder, string device)

	DFREF dfr = GetAnalysisDevChannelFolder(dataFolder, device)

	WAVE/Z/I/SDFR=dfr wv = sweeps

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/I dfr:sweeps/WAVE=wv = -1
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return a wave containing all devices
///  wave is used to relate it's index to sweepWave and channelWave.
Function/WAVE GetAnalysisDeviceWave(string dataFolder)

	DFREF dfr = GetAnalysisExpFolder(dataFolder)

	WAVE/Z/T/SDFR=dfr wv = devices

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/T dfr:devices/WAVE=wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return wave with all stored test pulses
Function/WAVE GetAnalysisStoredTestPulses(string dataFolder, string device)

	DFREF dfr = GetAnalysisDeviceTestpulse(dataFolder, device)

	WAVE/Z/WAVE/SDFR=dfr wv = StoredTestPulses

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(0)/WAVE dfr:StoredTestPulses/WAVE=wv

	return wv
End

/// @brief Return AnalysisBrowser indexing storage wave
///
/// Rows:
/// - Experiments found in current Directory
///
/// Columns:
/// - 0: %DiscLocation:  Path to Experiment on Disc
/// - 1: %FileName:      Name of File in experiment column in ExperimentBrowser
/// - 2: %DataFolder     Data folder inside current Igor experiment
/// - 3: %FileType       File Type identifier for routing to loader functions, one of @ref AnalysisBrowserFileTypes
Function/WAVE GetAnalysisBrowserMap()

	DFREF    dfr           = GetAnalysisFolder()
	variable versionOfWave = 3

	STRUCT WaveLocationMod p
	p.dfr     = dfr
	p.newDFR  = dfr
	p.name    = "experimentMap"
	p.newName = "analysisBrowserMap"

	WAVE/Z/T wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(ExistsWithCorrectLayoutVersion(wv, 1))
		// update dimension labels
	elseif(ExistsWithCorrectLayoutVersion(wv, 2))
		// clear file type as this now holds nwb version as well
		wv[][%FileType] = ""
	elseif(WaveExists(wv))
		Redimension/N=(-1, 4) wv
		wv[][3] = ANALYSISBROWSER_FILE_TYPE_IGOR
	else
		Make/N=(MINIMUM_WAVE_SIZE, 4)/T dfr:analysisBrowserMap/WAVE=wv
		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	endif

	SetDimLabel COLS, 0, DiscLocation, wv
	SetDimLabel COLS, 1, FileName, wv
	SetDimLabel COLS, 2, DataFolder, wv
	SetDimLabel COLS, 3, FileType, wv

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the text wave used in the folder listbox of the analysis browser
Function/WAVE GetAnalysisBrowserGUIFolderList()

	string   name          = "AnaBrowserFolderList"
	DFREF    dfr           = GetAnalysisFolder()
	variable versionOfWave = ANALYSIS_BROWSER_FOLDER_LISTBOX_WAVE_VERSION

	WAVE/Z/T/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(WaveExists(wv))
		// Upgrade here
	else
		Make/N=0/T dfr:$name/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the selection wave used in the folder listbox of the analysis browser
Function/WAVE GetAnalysisBrowserGUIFolderSelection()

	string   name          = "AnaBrowserFolderSelection"
	DFREF    dfr           = GetAnalysisFolder()
	variable versionOfWave = ANALYSIS_BROWSER_FOLDERSEL_LISTBOX_WAVE_VERSION

	WAVE/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(WaveExists(wv))
		// Upgrade here
	else
		Make/N=(1, 1, 3) dfr:$name/WAVE=wv
	endif

	SetDimLabel LAYERS, 1, $LISTBOX_LAYER_FOREGROUND, wv
	SetDimLabel LAYERS, 2, $LISTBOX_LAYER_BACKGROUND, wv
	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the color wave used in the folder listbox of the analysis browser
Function/WAVE GetAnalysisBrowserGUIFolderColors()

	string   name          = "AnaBrowserFolderColors"
	DFREF    dfr           = GetAnalysisFolder()
	variable versionOfWave = ANALYSIS_BROWSER_FOLDERCOL_LISTBOX_WAVE_VERSION

	WAVE/Z/U/W/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(WaveExists(wv))
		// Upgrade here
	else
		Make/W/U/N=(3, 3) dfr:$name/WAVE=wv
	endif

	SetDimLabel COLS, 0, R, wv
	SetDimLabel COLS, 1, G, wv
	SetDimLabel COLS, 2, B, wv

	// keep row 0 at {0, 0, 0} for default color
	wv[1][%R] = 255
	wv[1][%G] = 229
	wv[1][%B] = 229

	wv[2][%R] = 229
	wv[2][%G] = 255
	wv[2][%B] = 229

	wv = wv << 8

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the text wave used in the listbox of the experiment browser
///
/// The "experiment" column in the second layer maps to the corresponding row in the experimentMap.
Function/WAVE GetExperimentBrowserGUIList()

	DFREF    dfr           = GetAnalysisFolder()
	variable versionOfWave = ANALYSIS_BROWSER_LISTBOX_WAVE_VERSION

	WAVE/Z/T/SDFR=dfr wv = expBrowserList

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, NUM_COLUMNS_LIST_WAVE, -1) wv
		wv = ""
	else
		Make/N=(MINIMUM_WAVE_SIZE, NUM_COLUMNS_LIST_WAVE, 2)/T dfr:expBrowserList/WAVE=wv
	endif

	SetDimLabel COLS, 0, $"", wv
	SetDimLabel COLS, 1, file, wv
	SetDimLabel COLS, 2, type, wv
	SetDimLabel COLS, 3, $"", wv
	SetDimLabel COLS, 4, device, wv
	SetDimLabel COLS, 5, '#sweeps', wv
	SetDimLabel COLS, 6, sweep, wv
	SetDimLabel COLS, 7, '#headstages', wv
	SetDimLabel COLS, 8, 'stim sets', wv
	SetDimLabel COLS, 9, 'set count', wv
	SetDimLabel COLS, 10, '#DAC', wv
	SetDimLabel COLS, 11, '#ADC', wv
	SetDimLabel COLS, 12, 'start time', wv
	// the last columns is a dummy column that reserves space
	// where the scrollbar appears in the listbox. Otherwise the scrollbar covers data.
	SetDimLabel COLS, 13, $"", wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the selection wave used in the listbox of the experiment browser
///
Function/WAVE GetExperimentBrowserGUISel()

	DFREF    dfr           = GetAnalysisFolder()
	variable versionOfWave = ANALYSIS_BROWSER_LISTBOX_WAVE_VERSION

	WAVE/Z/SDFR=dfr wv = expBrowserSel

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, NUM_COLUMNS_LIST_WAVE, -1) wv
		wv = 0
	else
		Make/R/N=(MINIMUM_WAVE_SIZE, NUM_COLUMNS_LIST_WAVE) dfr:expBrowserSel/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the configSweep wave of a given sweep from the analysis subfolder
Function/WAVE GetAnalysisConfigWave(string dataFolder, string device, variable sweep)

	DFREF  dfr         = GetAnalysisDeviceConfigFolder(dataFolder, device)
	string configSweep = GetConfigWaveName(sweep)

	WAVE/Z/I/SDFR=dfr wv = $configSweep

	if(WaveExists(wv))
		// do nothing
	else
		Make/N=(0, 4)/I dfr:$configSweep/WAVE=wv = -1
	endif

	SetDimLabel COLS, 0, type, wv
	SetDimLabel COLS, 1, number, wv
	SetDimLabel COLS, 2, timeMS, wv

	return wv
End

/// UTF_NOINSTRUMENTATION
Function/WAVE ANALYSIS_LBN_GETTER_PROTO(string expFolder, string device)

	FATAL_ERROR("Can not call prototype function")
End

/// @brief Return the numerical labnotebook values in the analysis browser of a device and experiment pair
Function/WAVE GetAnalysLBNumericalValues(string expFolder, string device)

	STRUCT WaveLocationMod p
	p.dfr     = GetAnalysisLabNBFolder(expFolder, device)
	p.name    = "numericValues"
	p.newName = LBN_NUMERICAL_VALUES_NAME

	return UpgradeWaveLocationAndGetIt(p)
End

/// @brief Return the textual labnotebook keys in the analysis browser of a device and experiment pair
Function/WAVE GetAnalysLBTextualValues(string expFolder, string device)

	STRUCT WaveLocationMod p
	p.dfr     = GetAnalysisLabNBFolder(expFolder, device)
	p.name    = "textValues"
	p.newName = LBN_TEXTUAL_VALUES_NAME

	return UpgradeWaveLocationAndGetIt(p)
End

/// @brief Return the numerical labnotebook keys in the analysis browser of a device and experiment pair
Function/WAVE GetAnalysLBNumericalKeys(string expFolder, string device)

	STRUCT WaveLocationMod p
	p.dfr     = GetAnalysisLabNBFolder(expFolder, device)
	p.name    = "numericKeys"
	p.newName = LBN_NUMERICAL_KEYS_NAME

	return UpgradeWaveLocationAndGetIt(p)
End

/// @brief Return the textual labnotebook keys in the analysis browser of a device and experiment pair
Function/WAVE GetAnalysLBTextualKeys(string expFolder, string device)

	STRUCT WaveLocationMod p
	p.dfr     = GetAnalysisLabNBFolder(expFolder, device)
	p.name    = "textKeys"
	p.newName = LBN_TEXTUAL_KEYS_NAME

	return UpgradeWaveLocationAndGetIt(p)
End

///@}

/// @brief Return the indexing storage wave
///
/// Rows:
/// - 0: DA (#CHANNEL_TYPE_DAC)
/// - 1: TTL (#CHANNEL_TYPE_TTL)
///
/// Columns:
/// - 0: Popup menu index of Wave (stimset)
/// - 1: Popup menu index of Indexing end wave (stimset)
///
/// All zero-based as returned by GetPopupMenuIndex().
///
/// Layers:
/// - Channels
Function/WAVE GetIndexingStorageWave(string device)

	DFREF    dfr              = GetDevicePath(device)
	variable versionOfNewWave = 1

	WAVE/Z/SDFR=dfr wv = IndexingStorageWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
		return wv
	endif

	Make/R/N=(2, 2, NUM_DA_TTL_CHANNELS) dfr:IndexingStorageWave/WAVE=wv

	SetDimLabel ROWS, 0, CHANNEL_TYPE_DAC, wv
	SetDimLabel ROWS, 1, CHANNEL_TYPE_TTL, wv

	SetDimLabel COLS, 0, CHANNEL_CONTROL_WAVE, wv
	SetDimLabel COLS, 1, CHANNEL_CONTROL_INDEX_END, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the temporary folder below the MIES hierarchy, e.g. root:mies:trash.
///
/// UTF_NOINSTRUMENTATION
Function/DF GetTempPath()

	return createDFWithAllParents(GetMiesPathAsString() + ":" + TRASH_FOLDER_PREFIX)
End

/// @brief Return a unique temporary folder below the MIES hierarchy, e.g. root:mies:trash$digit.
///
/// As soon as you discard the latest reference to the folder it will
/// be slated for removal at some point in the future.
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/DF GetUniqueTempPath()

	return UniqueDataFolder(GetMiesPath(), TRASH_FOLDER_PREFIX)
End

/// @brief Return the datafolder reference to the static data location, e.g. root:mies:StaticData:
///
/// UTF_NOINSTRUMENTATION
Function/DF GetStaticDataFolder()

	return createDFWithAllParents(GetStaticDataFolderAS())
End

/// @brief Return the full path to the static data location
///
/// UTF_NOINSTRUMENTATION
Function/S GetStaticDataFolderAS()

	return GetMiesPathAsString() + ":StaticData"
End

/// @brief Return the datafolder reference to the active DAQ devices folder,
/// e.g. root:MIES:HardwareDevices:ActiveDAQDevices:TestPulse
///
/// UTF_NOINSTRUMENTATION
Function/DF GetActDAQDevicesTestPulseFolder()

	return createDFWithAllParents(GetActiveDAQDevicesTestPulseFolderAsString())
End

/// @brief Return the full path to the active DAQ devices location for the test pulse
///
/// UTF_NOINSTRUMENTATION
Function/S GetActiveDAQDevicesTestPulseFolderAsString()

	return GetDAQDevicesFolderAsString() + ":ActiveDAQDevices:TestPulse"
End

/// @brief Return the active devices wave for TP MD
///
/// Rows:
///   - Devices taking part in TP MD
/// Columns:
///   - 0: DeviceID
///   - 1: ActiveChunk
///
/// The `$NOTE_INDEX` wave note entry holds the number of active devices.
/// In addition it is also the next free row index.
Function/WAVE GetActiveDevicesTPMD()

	DFREF    dfr              = GetActDAQDevicesTestPulseFolder()
	variable versionOfNewWave = 1

	WAVE/Z/SDFR=dfr wv = ActiveDevicesTPMD

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(MINIMUM_WAVE_SIZE, 3) dfr:ActiveDevicesTPMD/WAVE=wv
		wv = NaN
	endif

	SetDimLabel COLS, 0, DeviceID, wv
	SetDimLabel COLS, 1, ActiveChunk, wv
	SetDimLabel COLS, 2, HardwareType, wv

	SetWaveVersion(wv, versionOfNewWave)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Returns wave (DA_EphysGuiState) that stores the DA_Ephys GUI state
/// DA_EphysGuiState is stored in the device specific folder
/// e.g. root:MIES:HardwareDevices:ITC18USB:Device0
///
/// Rows:
/// - Column specific GUI control settings usually associated with control name number
///
/// Columns:
/// -  0: State of control Check_DataAcqHS_RowNum. 0 = UnChecked, 1 = Checked
/// -  1: Clamp mode of HS number that matches Row number. 0 = VC, 1 = IC, 2 = NC.
/// -  2: State of control Check_DA_RowNum. 0 = UnChecked, 1 = Checked
/// -  3: Internal number stored in control Gain_DA_RowNum. Gain is user/hardware defined.
/// -  4: Internal number stored in setvar:Scale_DA_RowNum. Scalar is user defined.
/// -  5: PopupMenu Index of popupMenu:Wave_DA_RowNum. Stores index
///       of active DA stimulus set during data acquisition. Stores index of next DA
///       stimulus set when data acquistion is not active.
/// -  6: PopupMenu Index of popupMenu:IndexEnd_DA_RowNum. Stores the
///       index of the last DA stimulus set used in indexed aquisition mode.
/// -  7: State of checkbox control Check_AD_RowNum. 0 = UnChecked, 1 = Checked
/// -  8: Internal number stored in Gain_AD_RowNum. Gain is user/hardware defined.
/// -  9: State of checkbox control Check_TTL_RowNum.  0 = UnChecked, 1 = Checked
/// - 10: PopupMenu Index of popupMenu:Wave_TTL_RowNum. Stores
///       index of active TTL stimulus set during data acquisition. Stores index of
///       next TTL stimulus set when data acquistion is not active.
/// - 11: PopupMenu Index of popupMenu:IndexEnd_TTL_RowNum. Stores
///       the index of the last TTL stimulus set used in indexed aquisition mode.
/// - 12: State of control Check_AsyncAD_RowNum. 0 = UnChecked, 1 = Checked
/// - 13: Internal number stored in control SetVar_AsyncAD_Gain_RowNum. Gain is user/hardware defined.
/// - 14: State of control check_AsyncAlarm_RowNum. 0 = UnChecked, 1 = Checked
/// - 15: Internal number stored in control min_AsyncAD__RowNum. The minium value alarm trigger.
/// - 16: Internal number stored in control max_AsyncAD_RowNum. The max value alarm trigger.
/// - 17+: Unique controls
///
/// UTF_NOINSTRUMENTATION
Function/WAVE GetDA_EphysGuiStateNum(string device)

	variable uniqueCtrlCount
	string   uniqueCtrlList

	DFREF             dfr = GetDevicePath(device)
	WAVE/Z/D/SDFR=dfr wv  = DA_EphysGuiStateNum

	if(ExistsWithCorrectLayoutVersion(wv, DA_EPHYS_PANEL_VERSION))
		return wv
	endif

	if(WaveExists(wv)) // handle upgrade
		// change the required dimensions and leave all others untouched with -1
		// the extended dimensions are initialized with zero
		uniqueCtrlList  = DAG_GetUniqueSpecCtrlListNum(device)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Redimension/D/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT_NUM + uniqueCtrlCount, -1, -1) wv
		wv = NaN
	else
		uniqueCtrlList  = DAG_GetUniqueSpecCtrlListNum(device)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Make/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT_NUM + uniqueCtrlCount)/D dfr:DA_EphysGuiStateNum/WAVE=wv
		wv = NaN
	endif

	SetDimLabel COLS, 0, $GetSpecialControlLabel(CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS, 1, HSMode, wv
	SetDimLabel COLS, 2, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS, 3, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN), wv
	SetDimLabel COLS, 4, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), wv
	SetDimLabel COLS, 5, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), wv
	SetDimLabel COLS, 6, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), wv
	SetDimLabel COLS, 7, $GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS, 8, $GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN), wv
	SetDimLabel COLS, 9, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS, 10, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), wv
	SetDimLabel COLS, 11, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END), wv
	SetDimLabel COLS, 12, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS, 13, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN), wv
	SetDimLabel COLS, 14, $GetSpecialControlLabel(CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS, 15, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN), wv
	SetDimLabel COLS, 16, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX), wv
	SetDimLabel COLS, 17, HSMode_delayed, wv

	SetDimensionLabels(wv, uniqueCtrlList, COLS, startPos = COMMON_CONTROL_GROUP_COUNT_NUM)
	SetWaveVersion(wv, DA_EPHYS_PANEL_VERSION)
	// needs to be called after setting the wave version in order to avoid infinite recursion
	DAG_RecordGuiStateNum(device, GuiState = wv)
	return wv
End

/// @brief Return a wave reference to the textual GUI state wave
///
/// Rows:
/// - Column specific GUI control settings usually associated with control name number
///
/// Columns:
/// - 0: (DA)  First stimset name
/// - 1: (DA)  Last stimset name
/// - 2: (DA)  Unit
/// - 3: (DA)  Search string
/// - 4: (AD)  Unit
/// - 5: (TTL) First stimset name
/// - 6: (TTL) Last stimset name
/// - 7: (TTL) Search string
/// - 8: (Async) Title
/// - 9: (Async) Unit
/// - 10+: Unique controls (SetVariable and PopupMenu only)
///
/// UTF_NOINSTRUMENTATION
Function/WAVE GetDA_EphysGuiStateTxT(string device)

	DFREF             dfr = GetDevicePath(device)
	WAVE/Z/T/SDFR=dfr wv  = DA_EphysGuiStateTxT
	variable uniqueCtrlCount
	string   uniqueCtrlList

	if(ExistsWithCorrectLayoutVersion(wv, DA_EPHYS_PANEL_VERSION))
		return wv
	endif

	if(WaveExists(wv)) // handle upgrade
		// change the required dimensions and leave all others untouched with -1
		// the extended dimensions are initialized with zero
		uniqueCtrlList  = DAG_GetUniqueSpecCtrlListTxt(device)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Redimension/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT_TXT + uniqueCtrlCount, -1, -1) wv
		wv = ""
	else
		uniqueCtrlList  = DAG_GetUniqueSpecCtrlListTxt(device)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Make/T/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT_TXT + uniqueCtrlCount) dfr:DA_EphysGuiStateTxT/WAVE=wv
		wv = ""
	endif

	SetDimLabel COLS, 0, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), wv
	SetDimLabel COLS, 1, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), wv
	SetDimLabel COLS, 2, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT), wv
	SetDimLabel COLS, 3, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH), wv
	SetDimLabel COLS, 4, $GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT), wv
	SetDimLabel COLS, 5, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), wv
	SetDimLabel COLS, 6, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END), wv
	SetDimLabel COLS, 7, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_SEARCH), wv
	SetDimLabel COLS, 8, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE), wv
	SetDimLabel COLS, 9, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT), wv

	SetDimensionLabels(wv, uniqueCtrlList, COLS, startPos = COMMON_CONTROL_GROUP_COUNT_TXT)
	SetWaveVersion(wv, DA_EPHYS_PANEL_VERSION)
	// needs to be called after setting the wave version in order to avoid infinite recursion
	DAG_RecordGuiStateTxT(device, Guistate = wv)
	return wv
End

/// @brief Return the datafolder reference to the NeuroDataWithoutBorders folder,
///        e.g. root:MIES:NWB
///
/// UTF_NOINSTRUMENTATION
Function/DF GetNWBFolder()

	return createDFWithAllParents(GetNWBFolderAS())
End

/// @brief Return the full path to the NeuroDataWithoutBorders folder
///
/// UTF_NOINSTRUMENTATION
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
/// - 0: Main device (aka device of a DA_Ephys panel), used for deriving datafolders for storage
/// - 1: Name of the device used for pressure control (maybe empty)
Function/WAVE GetDeviceMapping()

	DFREF    dfr              = GetDAQDevicesFolder()
	variable versionOfNewWave = 3

	WAVE/Z/T/SDFR=dfr wv = deviceMapping

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		if(WaveVersionIsSmaller(wv, 2))
			Redimension/N=(HARDWARE_MAX_DEVICES, -1, 2) wv
			SetWaveVersion(wv, 2)
		endif
		if(WaveVersionIsSmaller(wv, 3))
			Redimension/N=(HARDWARE_MAX_DEVICES, ItemsInList(HARDWARE_DAC_TYPES), -1) wv
			SetWaveVersion(wv, 3)
		endif
	else
		Make/T/N=(HARDWARE_MAX_DEVICES, ItemsInList(HARDWARE_DAC_TYPES), 2) dfr:deviceMapping/WAVE=wv
	endif

	SetDimLabel ROWS, -1, DeviceID, wv

	SetDimLabel COLS, 0, ITC_DEVICE, wv
	SetDimLabel COLS, 1, NI_DEVICE, wv
	SetDimLabel COLS, 2, SUTTER_DEVICE, wv

	SetDimLabel LAYERS, 0, MainDevice, wv
	SetDimLabel LAYERS, 1, PressureDevice, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @name Getters relating to caching
///@{
/// @brief Return the datafolder reference to the wave cache
/// UTF_NOINSTRUMENTATION
threadsafe Function/DF GetCacheFolder()

	return createDFWithAllParents(GetCacheFolderAS())
End

/// @brief Return the full path to the wave cache datafolder, e.g. root:MIES:Cache
/// UTF_NOINSTRUMENTATION
threadsafe Function/S GetCacheFolderAS()

	return GetMiesPathAsString() + ":Cache"
End

/// @brief Return the wave reference wave holding the cached data
///
/// Dimension sizes and `NOTE_INDEX` value must coincide with other two cache waves.
/// UTF_NOINSTRUMENTATION
threadsafe Function/WAVE GetCacheValueWave()

	DFREF dfr = GetCacheFolder()

	WAVE/Z/WAVE/SDFR=dfr wv = values

	if(WaveExists(wv))
		return wv
	endif

	Make/WAVE/N=(MINIMUM_WAVE_SIZE) dfr:values/WAVE=wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the wave reference wave holding the cache keys
///
/// Dimension sizes and `NOTE_INDEX` value must coincide with other two cache waves.
/// UTF_NOINSTRUMENTATION
threadsafe Function/WAVE GetCacheKeyWave()

	DFREF dfr = GetCacheFolder()

	WAVE/Z/T/SDFR=dfr wv = keys

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(MINIMUM_WAVE_SIZE) dfr:keys/WAVE=wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the wave reference wave holding the cache stats
///
/// Rows:
/// - One for each cache entry
///
/// Columns:
/// - 0: Number of cache hits   (Incremented for every read)
/// - 1: Number of cache misses (Increment for every failed lookup)
/// - 2: Modification timestamp (Updated on write)
/// - 3: Size in bytes (Updated on write)
///
/// Dimension sizes and `NOTE_INDEX` value must coincide with other two cache waves.
/// UTF_NOINSTRUMENTATION
threadsafe Function/WAVE GetCacheStatsWave()

	variable versionOfNewWave = 3

	variable numRows, index, oldNumRows
	DFREF             dfr = GetCacheFolder()
	WAVE/Z/D/SDFR=dfr wv  = stats

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	WAVE/T    keys   = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()
	numRows = DimSize(values, ROWS)
	ASSERT_TS(DimSize(keys, ROWS) == numRows, "Mismatched row sizes")

	if(WaveExists(wv))
		// experiments prior to efebc382 (Merge pull request #490 from AllenInstitute/mh_fix_uniquedatafoldername, 2020-03-16)
		// have the wrong value of NOTE_INDEX of the stats wave
		if(WaveVersionIsAtLeast(wv, 1))
			index = GetNumberFromWaveNote(keys, NOTE_INDEX)
			SetNumberInWaveNote(wv, NOTE_INDEX, index)
		endif

		oldNumRows = DimSize(wv, ROWS)
		if(numRows != oldNumRows)
			Redimension/D/N=(numRows, 4) wv
			wv[oldNumRows, numRows - 1][] = NaN
		endif

		SetWaveVersion(wv, versionOfNewWave)
		return wv
	endif

	// experiments prior to ab795b55 (Cache: Add statistics for each entry, 2018-03-23)
	// don't hold this wave, but we still have to ensure that the stats wave has the right number of rows
	Make/D/N=(numRows, 4) dfr:stats/WAVE=wv

	wv = NaN

	index = GetNumberFromWaveNote(keys, NOTE_INDEX)
	SetNumberInWaveNote(wv, NOTE_INDEX, index)
	SetWaveVersion(wv, versionOfNewWave)

	SetDimLabel COLS, 0, Hits, wv
	SetDimLabel COLS, 1, Misses, wv
	SetDimLabel COLS, 2, ModificationTimestamp, wv
	SetDimLabel COLS, 3, Size, wv

	return wv
End
///@}

/// @brief Returns the names of the electrodes
///
/// The electrodes represents the physically connected part to the cell whereas
/// the headstage refers to the logical entity inside MIES.
///
/// Will be written into the labnotebook and used for the NWB export.
Function/WAVE GetCellElectrodeNames(string device)

	variable versionOfNewWave = 1
	DFREF    dfr              = GetDevicePath(device)

	WAVE/Z/T/SDFR=dfr wv = cellElectrodeNames

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	Make/T/N=(NUM_HEADSTAGES) dfr:cellElectrodeNames/WAVE=wv
	wv = GetDefaultElectrodeName(p)

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Returns a 1D wave with the same number of rows as headstages
///        used to store the pressure type
///
/// Available pressure types are one of @ref PressureTypeConstants
///
/// ROWS:
/// - One row for each headstage
///
/// @sa P_UpdatePressureType
Function/WAVE GetPressureTypeWv(string device)

	DFREF dfr = P_DeviceSpecificPressureDFRef(device)

	WAVE/Z/SDFR=dfr wv = pressureType

	if(WaveExists(wv))
		return wv
	endif

	Make/R/N=(NUM_HEADSTAGES) dfr:pressureType/WAVE=wv

	return wv
End

/// @brief Return the pulse averaging folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetDevicePulseAverageFolder(DFREF dfr)

	return createDFWithAllParents(GetDevicePulseAverageFolderAS(dfr))
End

/// @brief Return the full path to the pulse averaging folder, e.g. dfr:PulseAveraging
///
/// UTF_NOINSTRUMENTATION
Function/S GetDevicePulseAverageFolderAS(DFREF dfr)

	return GetDataFolder(1, dfr) + "PulseAveraging"
End

/// @brief Return the pulse averaging helper folder
///
/// This holds various helper waves for the graph generation.
///
/// UTF_NOINSTRUMENTATION
Function/DF GetDevicePulseAverageHelperFolder(DFREF dfr)

	return createDFWithAllParents(GetDevicePulseAverageHelperFolderAS(dfr))
End

/// @brief Return the full path to the pulse averaging helper folder, e.g. dfr:Helper
///
/// UTF_NOINSTRUMENTATION
Function/S GetDevicePulseAverageHelperFolderAS(DFREF dfr)

	return GetDevicePulseAverageFolderAS(dfr) + ":Helper"
End

/// @brief Return a wave reference to the single pulse defined by the given parameters
///
/// @param dfr           datafolder reference where to create the empty wave if it does not exist
/// @param length        Length in points of the new wave
/// @param channelType   channel type, one of @ref XopChannelConstants
/// @param channelNumber channel number
/// @param region        region index (a region is the range with data in a dDAQ/oodDAQ measurement)
/// @param pulseIndex    pulse number, 0-based
Function/WAVE GetPulseAverageWave(DFREF dfr, variable length, variable channelType, variable channelNumber, variable region, variable pulseIndex)

	variable versionOfNewWave = PULSE_WAVE_VERSION
	string wvName

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")
	wvName = PA_GeneratePulseWaveName(channelType, channelNumber, region, pulseIndex)

	WAVE/Z/SDFR=dfr wv = $wvName
	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// clear the wave note so that it is invalidated for cache checks through mod
		Note/K wv
	else
		Make/N=(length) dfr:$wvName/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the single pulse defined by the given parameters
///
/// @param dfr           datafolder reference where to create the empty wave if it does not exist
/// @param length        Length in points of the new wave
/// @param channelType   channel type, one of @ref XopChannelConstants
/// @param channelNumber channel number
/// @param region        region index (a region is the range with data in a dDAQ/oodDAQ measurement)
/// @param pulseIndex    pulse number, 0-based
Function/WAVE GetPulseAverageWaveNoteWave(DFREF dfr, variable length, variable channelType, variable channelNumber, variable region, variable pulseIndex)

	variable versionOfNewWave = PULSE_WAVE_VERSION
	string wvName

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")
	wvName = PA_GeneratePulseWaveName(channelType, channelNumber, region, pulseIndex) + PULSEWAVE_NOTE_SUFFIX

	WAVE/Z/SDFR=dfr wv = $wvName
	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// clear the wave note so that it is regenerated
		// by PA_CreateAndFillPulseWaveIfReq()
		Note/K wv
	else
		Make/N=0 dfr:$wvName/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Returns the pulse average set properties wave
///
/// These are row indizes into GetPulseAverageProperties()/GetPulseAveragePropertiesWaves()
/// for the pulses which belong to the given set.
Function/WAVE GetPulseAverageSetIndizes(DFREF dfr, variable channelNumber, variable region)

	string name
	variable versionOfNewWave = 2

	sprintf name, "setProperties_AD%d_R%d", channelNumber, region

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(MINIMUM_WAVE_SIZE, 1) dfr:$name/WAVE=wv
		Multithread wv[] = NaN
	endif

	SetDimLabel COLS, 0, $"Index", wv

	SetWaveVersion(wv, versionOfNewWave)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	SetNumberInWaveNote(wv, NOTE_KEY_PULSE_SORT_ORDER, NaN)

	return wv
End

/// @brief Returns the pulse average image wave
///
/// This is used for the image display mode.
///
/// `NOTE_INDEX` is used for marking the length of the used *columns* as there
/// is one pulse per column.
Function/WAVE GetPulseAverageSetImageWave(DFREF dfr, variable channelNumber, variable region)

	string name
	variable versionOfNewWave = 1

	sprintf name, "setImage_AD%d_R%d", channelNumber, region

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(1, MINIMUM_WAVE_SIZE) dfr:$name/WAVE=wv
		Multithread wv[] = NaN
	endif

	SetWaveVersion(wv, versionOfNewWave)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the pulse average properties wave
///
/// It is filled by PA_GenerateAllPulseWaves() and consumed by others.
Function/WAVE GetPulseAverageProperties(DFREF dfr)

	variable versionOfNewWave = 3

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr wv = properties

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, 8) wv
	else
		Make/R/N=(MINIMUM_WAVE_SIZE_LARGE, 8) dfr:properties/WAVE=wv
	endif

	Multithread wv[] = NaN

	SetDimLabel COLS, PA_PROPERTIES_INDEX_SWEEP, $"Sweep", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_CHANNELNUMBER, $"ChannelNumber", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_REGION, $"Region", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_HEADSTAGE, $"Headstage", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_PULSE, $"Pulse", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_PULSEHASFAILED, $"PulseHasFailed", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_LASTSWEEP, $"LastSweep", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_CLAMPMODE, $"ClampMode", wv

	SetWaveVersion(wv, versionOfNewWave)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the pulse average properties wave with wave references
///
/// Belongs to GetPulseAverageProperties() and also has the same
/// `NOTE_INDEX` count stored there.
Function/WAVE GetPulseAveragePropertiesWaves(DFREF dfr)

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/WAVE/SDFR=dfr wv = propertiesWaves

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/WAVE/N=(MINIMUM_WAVE_SIZE_LARGE, 2) dfr:propertiesWaves/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)
	SetDimLabel COLS, PA_PROPERTIESWAVES_INDEX_PULSE, PULSE, wv
	SetDimLabel COLS, PA_PROPERTIESWAVES_INDEX_PULSENOTE, PULSENOTE, wv

	return wv
End

/// @brief Return the mapping wave for pulse averaging between region/channel to activeRegion/activeChannel
///
/// Belongs to GetPulseAverageProperties() and also has the same
/// `NOTE_INDEX` count stored there.
Function/WAVE GetPulseAverageDisplayMapping(DFREF dfr)

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/D/SDFR=dfr wv = displayMapping

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(NUM_HEADSTAGES, NUM_MAX_CHANNELS, 2) dfr:displayMapping/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)
	SetDimLabel LAYERS, 0, ACTIVEREGION, wv
	SetDimLabel LAYERS, 1, ACTIVECHANNEL, wv

	return wv
End

/// @brief Return the artefact removal listbox wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetArtefactRemovalListWave(DFREF dfr)

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/T/SDFR=dfr wv = artefactRemovalListBoxWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 2) dfr:artefactRemovalListBoxWave/WAVE=wv
	endif

	SetDimLabel COLS, 0, $"Begin [ms]", wv
	SetDimLabel COLS, 1, $"End   [ms]", wv

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return the artefact removal wave
///        databrowser or the sweepbrowser
Function/WAVE GetArtefactRemovalDataWave(DFREF dfr)

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/D/SDFR=dfr wv = artefactRemovalDataWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/D/N=(MINIMUM_WAVE_SIZE, 4) wv
	else
		Make/D/N=(MINIMUM_WAVE_SIZE, 4) dfr:artefactRemovalDataWave/WAVE=wv
	endif

	SetDimLabel COLS, 0, $"ArtefactPosition", wv
	SetDimLabel COLS, 1, $"DAC", wv
	SetDimLabel COLS, 2, $"ADC", wv
	SetDimLabel COLS, 3, $"HS", wv

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return the overlay sweeps listbox wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetOverlaySweepsListWave(DFREF dfr)

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/T/SDFR=dfr wv = overlaySweepsListBoxWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 2) dfr:overlaySweepsListBoxWave/WAVE=wv
	endif

	SetDimLabel COLS, 0, $"Sweep", wv
	SetDimLabel COLS, 1, $"Headstages", wv

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return the overlay sweeps listbox selection wave
/// for the databrowser or the sweepbrowser
Function/WAVE GetOverlaySweepsListSelWave(DFREF dfr)

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/B/SDFR=dfr wv = overlaySweepsListBoxSelWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/B/N=(MINIMUM_WAVE_SIZE, 2) dfr:overlaySweepsListBoxSelWave/WAVE=wv
	endif

	SetDimLabel COLS, 0, $"Sweep", wv
	SetDimLabel COLS, 1, $"Headstages", wv

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return the overlay sweeps wave with the parsed headstage removal
/// info
///
/// Rows:
/// - Same index as in GetOverlaySweepsListWave() and GetOverlaySweepsListSelWave()
///
/// Columns:
/// - #NUM_HEADSTAGES, 1 if active and 0 if removed
Function/WAVE GetOverlaySweepHeadstageRemoval(DFREF dfr)

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr wv = overlaySweepsHeadstageRemoval

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(MINIMUM_WAVE_SIZE, NUM_HEADSTAGES) dfr:overlaySweepsHeadstageRemoval/WAVE=wv
	endif

	wv = 1

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return the overlay sweeps wave with all sweep selection choices
/// for the databrowser or the sweepbrowser
Function/WAVE GetOverlaySweepSelectionChoices(string win, DFREF dfr, [variable skipUpdate])

	variable versionOfNewWave = 4

	if(ParamIsDefault(skipUpdate))
		skipUpdate = 0
	else
		skipUpdate = !!skipUpdate
	endif

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	string newName = "overlaySweepSelectionChoices"

	STRUCT WaveLocationMod p
	p.dfr     = dfr
	p.name    = "overlaySweepsStimSetListWave"
	p.newName = newName

	WAVE/Z/T wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		if(!skipUpdate)
			OVS_UpdateSweepSelectionChoices(win, wv)
		endif
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, -1, 7) wv
	else
		ASSERT(NUM_HEADSTAGES == NUM_DA_TTL_CHANNELS, "Unexpected channel count")
		Make/T/N=(MINIMUM_WAVE_SIZE, NUM_HEADSTAGES, 7) dfr:$newName/WAVE=wv
	endif

	SetDimensionLabels(wv, "Stimset;TTLStimset;DAStimsetAndClampMode;DAStimsetAndSetSweepCount;TTLStimsetAndSetSweepCount;DAStimsetAndSetCycleCount;TTLStimsetAndSetCycleCount", LAYERS)
	SetNumberInWaveNote(wv, NOTE_NEEDS_UPDATE, 1)
	SetWaveVersion(wv, versionOfNewWave)

	if(!skipUpdate)
		OVS_UpdateSweepSelectionChoices(win, wv)
	endif

	return wv
End

/// @brief Return the channel selection wave for the databrowser or sweep browser
Function/WAVE GetChannelSelectionWave(DFREF dfr)

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr wv = channelSelection

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(max(NUM_DA_TTL_CHANNELS, NUM_AD_CHANNELS, NUM_HEADSTAGES), 3) wv
	else
		Make/R/N=(max(NUM_DA_TTL_CHANNELS, NUM_AD_CHANNELS, NUM_HEADSTAGES), 3) dfr:channelSelection/WAVE=wv

		// by default all channels are selected
		wv = 1
	endif

	SetDimLabel COLS, 0, DA, wv
	SetDimLabel COLS, 1, AD, wv
	SetDimLabel COLS, 2, HEADSTAGE, wv

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return a *free* wave used for the axis label cache
Function/WAVE GetAxisLabelCacheWave()

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE, 2) wv

	SetDimLabel COLS, 0, Axis, wv
	SetDimLabel COLS, 1, Lbl, wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the sweepBrowser map wave from the given DFR
Function/WAVE GetSweepBrowserMap(DFREF dfr)

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Missing SweepBrowser DFR")

	WAVE/Z/T/SDFR=dfr wv = map
	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	Make/T/N=(MINIMUM_WAVE_SIZE, 4) dfr:map/WAVE=wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	SetDimLabel COLS, 0, FileName, wv
	SetDimLabel COLS, 1, DataFolder, wv
	SetDimLabel COLS, 2, Device, wv
	SetDimLabel COLS, 3, Sweep, wv

	SetNumberInWaveNote(wv, WAVE_NOTE_LAYOUT_KEY, versionOfNewWave)

	return wv
End

/// @name Getters related to debugging
///@{
/// @brief Return the datafolder reference to the debug folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetDebugPanelFolder()

	return createDFWithAllParents(GetDebugPanelFolderAS())
End

/// @brief Return the full path to the debug datafolder, e.g. root:MIES:Debug
///
/// UTF_NOINSTRUMENTATION
Function/S GetDebugPanelFolderAS()

	return GetMiesPathAsString() + ":Debug"
End

/// @brief Return the list wave for the debug panel
Function/WAVE GetDebugPanelListWave()

	variable          versionOfNewWave = 1
	DFREF             dfr              = GetDebugPanelFolder()
	WAVE/Z/T/SDFR=dfr wv               = fileSelectionListWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(MINIMUM_WAVE_SIZE) dfr:fileSelectionListWave/WAVE=wv
	endif

	return wv
End

/// @brief Return the list selection wave for the debugging panel
Function/WAVE GetDebugPanelListSelWave()

	variable          versionOfNewWave = 1
	DFREF             dfr              = GetDebugPanelFolder()
	WAVE/Z/B/SDFR=dfr wv               = fileSelectionListSelWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/B/N=(MINIMUM_WAVE_SIZE) dfr:fileSelectionListSelWave/WAVE=wv
	endif

	return wv
End
///@}

/// @name AnalysisFunctionGetters Getters used by analysis functions
///@{

/// @brief Return a wave reference which holds an headstage-dependent index
///
/// Can be used by analysis function to count the number of invocations.
Function/WAVE GetAnalysisFuncIndexingHelper(string device)

	variable          versionOfNewWave = 1
	DFREF             dfr              = GetDevicePath(device)
	WAVE/Z/D/SDFR=dfr wv               = analysisFuncIndexing

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(NUM_HEADSTAGES) dfr:analysisFuncIndexing/WAVE=wv
	endif

	return wv
End

/// @brief Return a wave reference which holds the "Delta V" values
/// of all sweeps from one repeated acquisition cycle
///
/// Used by PSQ_AdjustDAScale().
///
/// Rows:
/// - Sweeps
///
/// Columns:
/// - Headstages
Function/WAVE GetAnalysisFuncDAScaleDeltaV(string device)

	variable          versionOfNewWave = 1
	DFREF             dfr              = GetDevicePath(device)
	WAVE/Z/D/SDFR=dfr wv               = analysisFuncDAScaleDeltaV

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(MINIMUM_WAVE_SIZE, NUM_HEADSTAGES) dfr:analysisFuncDAScaleDeltaV/WAVE=wv
		wv = NaN
	endif

	SetScale d, 0, 0, "V", wv
	SetWaveVersion(wv, versionOfNewWave)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	SetNumberInWaveNote(wv, "Last Sweep", NaN)

	return wv
End

/// @brief Return a wave reference which holds the "Delta I" values
/// of all sweeps from one repeated acquisition cycle
///
/// Used by PSQ_AdjustDAScale().
///
/// Rows:
/// - Sweeps
///
/// Columns:
/// - Headstages
Function/WAVE GetAnalysisFuncDAScaleDeltaI(string device)

	variable          versionOfNewWave = 1
	DFREF             dfr              = GetDevicePath(device)
	WAVE/Z/D/SDFR=dfr wv               = analysisFuncDAScaleDeltaI

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(MINIMUM_WAVE_SIZE, NUM_HEADSTAGES) dfr:analysisFuncDAScaleDeltaI/WAVE=wv
		wv = NaN
	endif

	SetScale d, 0, 0, "A", wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the fitted resistance values and its error
///
/// Used by PSQ_AdjustDAScale().
///
/// Rows:
/// - Headstages
///
/// Columns:
/// - Value
/// - Error (standard deviation)
Function/WAVE GetAnalysisFuncDAScaleRes(string device)

	variable          versionOfNewWave = 1
	DFREF             dfr              = GetDevicePath(device)
	WAVE/Z/D/SDFR=dfr wv               = analysisFuncDAScaleRes

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(NUM_HEADSTAGES, 2) dfr:analysisFuncDAScaleRes/WAVE=wv
		wv = NaN
	endif

	SetScale d, 0, 0, "Ω", wv
	SetDimLabel COLS, 0, Value, wv
	SetDimLabel COLS, 1, Error, wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the fitted resistance wave created by `CurveFit`
///
/// Used by PSQ_AdjustDAScale().
Function/WAVE GetAnalysisFuncDAScaleResFit(string device, variable headstage)

	variable versionOfNewWave = 1
	string name

	DFREF dfr = GetDevicePath(device)
	name = "analysisFuncDAScaleResFit" + "_" + num2str(headstage)

	WAVE/Z/D/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(2) dfr:$name/WAVE=wv
		wv = NaN
	endif

	SetScale d, 0, 0, "Ω", wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the spikes frequency wave
///
/// Used by PSQ_AdjustDAScale().
Function/WAVE GetAnalysisFuncDAScaleSpikeFreq(string device, variable headstage)

	variable versionOfNewWave = 1
	string name

	DFREF dfr = GetDevicePath(device)
	name = "analysisFuncDAScaleSpikeFreq" + "_" + num2str(headstage)

	WAVE/Z/D/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(0) dfr:$name/WAVE=wv
	endif

	SetScale d, 0, 0, "Hz", wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the spikes frequency wave
///
/// Used by PSQ_AdjustDAScale().
Function/WAVE GetAnalysisFuncDAScaleFreqFit(string device, variable headstage)

	variable versionOfNewWave = 1
	string name

	DFREF dfr = GetDevicePath(device)
	name = "analysisFuncDAScaleFreqFit" + "_" + num2str(headstage)

	WAVE/Z/D/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(2) dfr:$name/WAVE=wv
		wv = NaN
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the DAScale wave
///
/// Used by PSQ_AdjustDAScale().
Function/WAVE GetAnalysisFuncDAScales(string device, variable headstage)

	variable versionOfNewWave = 1
	string name

	DFREF dfr = GetDevicePath(device)
	name = "analysisFuncDAScales" + "_" + num2str(headstage)

	WAVE/Z/D/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(0) dfr:$name/WAVE=wv
	endif

	SetScale d, 0, 0, "A", wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

///@}

/// @brief Return the storage wave for the analysis functions
///
/// Only contains *valid* functions. An analysis function is valid if it has
/// a compatible signature and can be found within the locations searched by
/// AFH_GetAnalysisFunctions().
///
/// Rows:
/// - Head stage number
///
/// Columns:
/// - 0-#TOTAL_NUM_EVENTS - 1:   Analysis functions
/// - #ANALYSIS_FUNCTION_PARAMS: Analysis function params (only for V3 generic functions)
Function/WAVE GetAnalysisFunctionStorage(string device)

	variable          versionOfWave = 4
	DFREF             dfr           = GetDevicePath(device)
	WAVE/Z/T/SDFR=dfr wv            = analysisFunctions

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
		Redimension/N=(NUM_HEADSTAGES, TOTAL_NUM_EVENTS + 1) wv
	else
		Make/T/N=(NUM_HEADSTAGES, TOTAL_NUM_EVENTS + 1) dfr:analysisFunctions/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Used for storing a true/false state that the pre and/or post set event
/// should be fired *after* the sweep which is currently prepared in DC_PlaceDataInDAQDataWave().
///
/// Rows:
/// - NUM_DA_TTL_CHANNELS
///
/// Columns:
/// - PRE_SET_EVENT
/// - POST_SET_EVENT
Function/WAVE GetSetEventFlag(string device)

	variable          versionOfWave = 1
	DFREF             dfr           = GetDevicePath(device)
	WAVE/Z/D/SDFR=dfr wv            = setEventFlag

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(NUM_DA_TTL_CHANNELS, 2) dfr:setEventFlag/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfWave)

	SetDimLabel COLS, 0, PRE_SET_EVENT, wv
	SetDimLabel COLS, 1, POST_SET_EVENT, wv

	return wv
End

/// @brief Return the wave for storing timestamps for perf testing repeated
///        acquisition
Function/WAVE GetRAPerfWave(string device)

	variable          versionOfWave = 1
	DFREF             dfr           = GetDevicePath(device)
	WAVE/Z/D/SDFR=dfr wv            = perfingRA

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(MINIMUM_WAVE_SIZE) dfr:perfingRA/WAVE=wv
	endif

	wv = NaN
	SetScale d, 0, Inf, "s", wv

	SetWaveVersion(wv, versionOfWave)

	return wv

End

/// @brief Return the list wave for the analysis parameter GUI
Function/WAVE WBP_GetAnalysisParamGUIListWave()

	variable          versionOfWave = 3
	DFREF             dfr           = GetWaveBuilderDataPath()
	WAVE/Z/T/SDFR=dfr wv            = analysisGUIListWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, 5) wv
	else
		Make/T/N=(0, 5) dfr:analysisGUIListWave/WAVE=wv
	endif

	SetDimLabel COLS, 0, Name, wv
	SetDimLabel COLS, 1, Type, wv
	SetDimLabel COLS, 2, Value, wv
	SetDimLabel COLS, 3, Required, wv
	SetDimLabel COLS, 4, Help, wv

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the selection wave for the analysis parameter GUI
Function/WAVE WBP_GetAnalysisParamGUISelWave()

	variable          versionOfWave = 1
	DFREF             dfr           = GetWaveBuilderDataPath()
	WAVE/Z/B/SDFR=dfr wv            = analysisGUISelWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	Make/B/N=(0) dfr:analysisGUISelWave/WAVE=wv

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the help wave for the analysis parameter GUI
Function/WAVE WBP_GetAnalysisParamGUIHelpWave()

	variable          versionOfWave = 1
	DFREF             dfr           = GetWaveBuilderDataPath()
	WAVE/Z/T/SDFR=dfr wv            = analysisGUIHelpWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	Make/T/N=(0, 5) dfr:analysisGUIHelpWave/WAVE=wv

	SetDimLabel COLS, 0, Name, wv
	SetDimLabel COLS, 1, Type, wv
	SetDimLabel COLS, 2, Value, wv
	SetDimLabel COLS, 3, Required, wv
	SetDimLabel COLS, 4, Help, wv

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the analysis function dashboard listbox wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetAnaFuncDashboardListWave(DFREF dfr)

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/T/SDFR=dfr wv = dashboardListWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, 4) wv
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 4) dfr:dashboardListWave/WAVE=wv
	endif

	SetDimLabel COLS, 0, $"Stimset", wv
	SetDimLabel COLS, 1, $"Analysis function", wv
	SetDimLabel COLS, 2, $"Headstage", wv
	SetDimLabel COLS, 3, $"Result", wv

	SetWaveVersion(wv, versionOfNewWave)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the analysis function dashboard info wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetAnaFuncDashboardInfoWave(DFREF dfr)

	variable versionOfNewWave = 3

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/T/SDFR=dfr wv = dashboardInfoWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
		Redimension/N=(-1, 4) wv
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 4) dfr:dashboardInfoWave/WAVE=wv
	endif

	SetDimLabel COLS, 0, $STIMSET_ACQ_CYCLE_ID_KEY, wv
	SetDimLabel COLS, 1, $"Passing Sweeps", wv
	SetDimLabel COLS, 2, $"Failing Sweeps", wv
	SetDimLabel COLS, 3, $"Ongoing DAQ", wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the analysis function dashboard listbox selection wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetAnaFuncDashboardSelWave(DFREF dfr)

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/B/SDFR=dfr wv = dashboardSelWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, 4, -1) wv
	else
		Make/B/N=(MINIMUM_WAVE_SIZE, 4, 2) dfr:dashboardSelWave/WAVE=wv
	endif

	SetDimLabel LAYERS, 1, $LISTBOX_LAYER_FOREGROUND, wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the analysis function dashboard listbox color wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetAnaFuncDashboardColorWave(DFREF dfr)

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/U/W/SDFR=dfr wv = dashboardColorWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(4, -1) wv
	else
		Make/W/U/N=(4, 3) dfr:dashboardColorWave/WAVE=wv
	endif

	wv[0][0] = {0, 65535, 0}
	wv[0][1] = {0, 0, 35000}
	wv[0][2] = {0, 0, 0}

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the analysis function dashboard help wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetAnaFuncDashboardHelpWave(DFREF dfr)

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/T/SDFR=dfr wv = dashboardHelpWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(0) dfr:dashboardHelpWave/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave with device information
///
///        Entries:
/// AD: - For devices that have mixed channels for HS, Unassoc AD the number of the channels combined
///     - For devices that have separate channels for HS and Unassoc AD the number of the headstages
/// DA: - For devices that have mixed channels for HS, Unassoc DA the number of the channels combined
///     - For devices that have separate channels for HS and Unassoc DA the number of the headstages
/// TTL: - Number of TTL channels
/// Rack: - Number of Racks for ITC, NaN for other HW
/// HardwareType: - One of @sa HardwareDACTypeConstants like HARDWARE_SUTTER_DAC
/// AuxAD: - For devices with HS independent AD channels the number of the separate AD channels, NaN for devices with mixed channels
/// AuxDA: - For devices with HS independent DA channels the number of the separate DA channels, NaN for devices with mixed channels
Function/WAVE GetDeviceInfoWave(string device)

	variable versionOfNewWave = 2
	variable hardwareType

	DFREF             dfr = GetDeviceInfoPath()
	WAVE/Z/D/SDFR=dfr wv  = $device

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		if(WaveVersionIsSmaller(wv, 2))
			Redimension/N=7 wv
			SetWaveVersion(wv, 2)
		endif
		// handle upgrade
	else
		Make/D/N=7 dfr:$device/WAVE=wv
	endif

	SetDimLabel ROWS, 0, AD, wv
	SetDimLabel ROWS, 1, DA, wv
	SetDimLabel ROWS, 2, TTL, wv
	SetDimLabel ROWS, 3, Rack, wv
	SetDimLabel ROWS, 4, HardwareType, wv
	SetDimLabel ROWS, 5, AuxAD, wv
	SetDimLabel ROWS, 6, AuxDA, wv

	wv = NaN

	SetWaveVersion(wv, versionOfNewWave)

	hardwareType = GetHardwareType(device)
	HW_WriteDeviceInfo(hardwareType, device, wv)

	return wv
End

/// @brief Return a wave suitable for storing elapsed time
///
/// Helper function for DEBUGPRINT_ELAPSED_WAVE() and StoreElapsedTime().
Function/WAVE GetElapsedTimeWave()

	variable versionOfNewWave = 1

	DFREF             dfr = GetTempPath()
	WAVE/Z/D/SDFR=dfr wv  = elapsedTime

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(MINIMUM_WAVE_SIZE) dfr:elapsedTime/WAVE=wv
	endif

	wv = NaN

	SetScale d, 0, 0, "s", wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the X wave for the sweep formula
Function/WAVE GetSweepFormulaX(DFREF dfr, variable graphNr)

	string wName = "sweepFormulaX_" + num2istr(graphNr)

	WAVE/Z/D/SDFR=dfr wv = $wName

	if(WaveExists(wv))
		return wv
	endif

	Make/N=0/D dfr:$wName/WAVE=wv

	return wv
End

/// @brief Return the Y wave for the sweep formula
Function/WAVE GetSweepFormulaY(DFREF dfr, variable graphNr)

	string wName = "sweepFormulaY_" + num2istr(graphNr)

	WAVE/Z/D/SDFR=dfr wv = $wName

	if(WaveExists(wv))
		return wv
	endif

	Make/N=0/D dfr:$wName/WAVE=wv

	return wv
End

/// @brief Return the global temporary wave for extended popup menu
Function/WAVE GetPopupExtMenuWave()

	variable          versionOfNewWave = 1
	DFREF             dfr              = GetMiesPath()
	WAVE/Z/T/SDFR=dfr wv               = popupExtMenuInfo

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=1 dfr:popupExtMenuInfo/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the reference to the graph user data datafolder as string
///
/// UTF_NOINSTRUMENTATION
Function/S GetGraphUserDataFolderAsString()

	return GetMiesPathAsString() + ":GraphUserData"
End

/// @brief Return the reference to the graph user data datafolder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetGraphUserDataFolderDFR()

	return createDFWithAllParents(GetGraphUserDataFolderAsString())
End

/// UTF_NOINSTRUMENTATION
static Function/S BuildGraphName(string graph)

	return CleanupName(graph, 0) + "_wave"
End

/// @brief Return the path to the text wave for the graph user data as string
///
/// UTF_NOINSTRUMENTATION
Function/S GetGraphUserDataAsString(string graph)

	return GetGraphUserDataFolderAsString() + ":" + BuildGraphName(graph)
End

/// @brief Return the text wave for the graph user data
///
/// @param graph existing graph
Function/WAVE GetGraphUserData(string graph)

	variable          versionOfNewWave = 1
	DFREF             dfr              = GetGraphUserDataFolderDFR()
	string            name             = BuildGraphName(graph)
	WAVE/Z/T/SDFR=dfr wv               = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(MINIMUM_WAVE_SIZE_LARGE, 0) dfr:$name/WAVE=wv
		TUD_Init(graph)
	endif

	SetWaveVersion(wv, versionOfNewWave)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	SetNumberInWaveNote(wv, TUD_INDEX_JSON, JSON_New())

	return wv
End

/// @brief Return the wave for trace counts per graph for pulse averaging plot
/// rows one per graph, dimlabel is graph name
///
/// Columns:
/// - 0: trace names of all average traces
/// - 1: trace names of all deconvolution traces
/// - 2: list of used image names
Function/WAVE GetPAGraphData()

	variable          versionOfNewWave = 1
	DFREF             dfr              = GetGraphUserDataFolderDFR()
	string            name             = "PAGraphData"
	WAVE/Z/T/SDFR=dfr wv               = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(0, 3) dfr:$name/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)
	SetDimLabel COLS, 0, TRACES_AVERAGE, wv
	SetDimLabel COLS, 1, TRACES_DECONV, wv
	SetDimLabel COLS, 2, IMAGELIST, wv

	return wv
End

/// @brief Return permanent average wave for PA plot for a given channel/region as well as its base name
///        Returns a null wave if the permanent wave does not exist.
Function [WAVE avg_, string baseName_] GetPAPermanentAverageWave(DFREF dfr, variable channel, variable region)

	string baseName, wName

	baseName = PA_BaseName(channel, region)
	wName    = PA_AVERAGE_WAVE_PREFIX + baseName
	WAVE/Z avg = dfr:$wName

	return [avg, baseName]
End

/// @brief Return a free wave for storing timing information of single pulses
///
/// Rows:
/// - Pulses
///
/// Columns:
/// - Length [ms]: Total length including baseline
/// - PulseStart [ms]: Start of the pulse (aka begin of active)
/// - PulseEnd [ms]: End of the pulse (aka end of active)
Function/WAVE GetPulseInfoWave()

	Make/D/FREE/N=(0, 3) pulseInfo

	SetDimLabel COLS, 0, Length, pulseInfo
	SetDimLabel COLS, 1, PulseStart, pulseInfo
	SetDimLabel COLS, 2, PulseEnd, pulseInfo

	return pulseInfo
End

/// @brief Return the wave used for storing mock data for tests
///
/// This wave is created by MSQ_CreateOverrideResults(),
/// PSQ_CreateOverrideResults(), TP_CreateOverrideResults(), CreateOverrideResults() and does also not
/// follow our usual rules so it might not exist.
threadsafe Function/WAVE GetOverrideResults()

	DFREF dfr = root:
	WAVE/Z/SDFR=dfr overrideResults

	return overrideResults
End

/// @brief Return the wave used for storing acquisition state transitions during testing
///
Function/WAVE GetAcqStateTracking()

	variable versionOfNewWave = 1
	DFREF    dfr              = root:

	string          name = "acquisitionStateTracking"
	WAVE/Z/SDFR=dfr wv   = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		// handle upgrade
	else
		Make/N=(MINIMUM_WAVE_SIZE, 2) dfr:$name/WAVE=wv
	endif

	wv = NaN

	SetDimLabel COLS, 0, OLD, wv
	SetDimLabel COLS, 1, NEW, wv

	SetWaveVersion(wv, versionOfNewWave)
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return a wave with all valid acquisition state transitions
///
/// It is AS_NUM_STATES x AS_NUM_STATES matrix were the old states are in the rows
/// and the new states in the columns. Every valid transition has a 1 in it.
Function/WAVE GetValidAcqStateTransitions()

	variable versionOfNewWave = 2
	DFREF    dfr              = GetMiesPath()

	string          name = "validAcqStateTransitions"
	WAVE/Z/SDFR=dfr wv   = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(AS_NUM_STATES, AS_NUM_STATES) wv
	else
		Make/R/N=(AS_NUM_STATES, AS_NUM_STATES) dfr:$name/WAVE=wv
	endif

	wv = 0

	Make/FREE/N=(AS_NUM_STATES) indexHelper

	SetDimLabel ROWS, -1, OLD, wv
	SetDimLabel COLS, -1, NEW, wv
	indexHelper[] = SetDimensionLabels(wv, AS_StateToString(p), ROWS, startPos = p)
	indexHelper[] = SetDimensionLabels(wv, AS_StateToString(p), COLS, startPos = p)

	wv[%AS_INACTIVE][%AS_EARLY_CHECK] = 1

	wv[%AS_EARLY_CHECK][%AS_PRE_DAQ]  = 1
	wv[%AS_EARLY_CHECK][%AS_INACTIVE] = 1

	wv[%AS_PRE_DAQ][%AS_PRE_SWEEP_CONFIG] = 1
	wv[%AS_PRE_DAQ][%AS_INACTIVE]         = 1
	wv[%AS_PRE_DAQ][%AS_POST_DAQ]         = 1

	wv[%AS_PRE_SWEEP_CONFIG][%AS_PRE_SWEEP] = 1
	wv[%AS_PRE_SWEEP_CONFIG][%AS_POST_DAQ]  = 1

	wv[%AS_PRE_SWEEP][%AS_MID_SWEEP] = 1

	wv[%AS_MID_SWEEP][%AS_MID_SWEEP]  = 1
	wv[%AS_MID_SWEEP][%AS_POST_SWEEP] = 1

	wv[%AS_POST_SWEEP][%AS_ITI]      = 1
	wv[%AS_POST_SWEEP][%AS_POST_DAQ] = 1

	wv[%AS_ITI][%AS_PRE_SWEEP_CONFIG] = 1
	wv[%AS_ITI][%AS_POST_DAQ]         = 1

	wv[%AS_POST_DAQ][%AS_INACTIVE] = 1

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// UTF_NOINSTRUMENTATION
Function/S GetDANDIFolderAsString()

	return "root:MIES:DANDI"
End

/// @brief Return the data folder reference to the DANDI folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetDANDIFolder()

	return createDFWithAllParents(GetDANDIFolderAsString())
End

/// @brief Return a free wave with the DANDI set properties
///
/// Rows:
/// - one row for each asset
///
/// Columns:
/// - ID
/// - created timestamp (ISO8601)
/// - modified timestamp (ISO8601)
/// - file path of the asset inside the DANDI set
Function/WAVE GetDandiSetProperties()

	Make/FREE/N=(0, 4)/T wv

	// we don't care about size
	SetDimensionLabels(wv, "asset_id;created;modified;path", COLS)

	return wv
End

Function/WAVE GetDandiDialogWave(WAVE props)

	DFREF dfr = GetDANDIFolder()
	Make/O/N=(DimSize(props, ROWS)) dfr:data/WAVE=data

	Duplicate/FREE/RMD=[][FindDimLabel(props, COLS, "path")] props, paths
	Redimension/N=(-1) paths

	SetDimensionLabels(data, TextWaveToList(paths, ";"), ROWS)

	return data
End

/// @brief Return a free wave with the DAC amplitudes
///
/// Rows:
/// - One for each *active* DAC
///
/// Columns:
///  - `DASCALE`:  DA Scale from the DAEphys GUI
///  - `TPAMP`:    Testpulse amplitude (clamp mode dependent)
Function/WAVE GetDACAmplitudes(variable numDACEntries)

	Make/D/FREE/N=(numDACEntries, 2) wv

	SetDimLabel COLS, 0, DASCALE, wv
	SetDimLabel COLS, 1, TPAMP, wv

	return wv
End

/// @brief Return a free text wave to store single y vs x formula combinations from sweepformula code
///
/// Rows:
/// - One for each y vs x formula combination
Function/WAVE GetYvsXFormulas()

	Make/T/FREE/N=(0, 2) wv
	SetDimLabel COLS, 0, GRAPHCODE, wv
	SetDimLabel COLS, 1, LINE, wv

	return wv
End

/// @brief Return a free text wave to store y and x formula combinations from sweepformula code
///
/// Rows:
/// - One for each formula
/// Columns:
/// - FORMULA_X: formula for x wave
/// - FORMULA_Y: formula for y wave
Function/WAVE GetYandXFormulas()

	Make/T/FREE/N=(0, 2) wv

	SetDimLabel COLS, 0, FORMULA_X, wv
	SetDimLabel COLS, 1, FORMULA_Y, wv

	return wv
End

/// @brief Free wave version of GetTPSettingsFree()
Function/WAVE GetTPSettingsFree()

	Make/N=(14, LABNOTEBOOK_LAYER_COUNT)/D/FREE wv
	wv = NaN

	SetDimensionLabels(wv, TP_SETTINGS_LABELS, ROWS)

	// supply initial values for headstage dependent controls
	// see also DAEPHYS_TP_CONTROLS_DEPEND
	wv[%amplitudeVC][0, NUM_HEADSTAGES - 1] = 10
	wv[%amplitudeIC][0, NUM_HEADSTAGES - 1] = -50

	wv[%autoTPEnable][0, NUM_HEADSTAGES - 1]        = 0
	wv[%autoAmpMaxCurrent][0, NUM_HEADSTAGES - 1]   = 200
	wv[%autoAmpVoltage][0, NUM_HEADSTAGES - 1]      = -5
	wv[%autoAmpVoltageRange][0, NUM_HEADSTAGES - 1] = 0.5

	return wv
End

/// @brief Return the testpulse GUI settings
///
/// Rows:
/// - Buffer size: Number of elements to average
/// - Resistance tolerance: Tolerance for labnotebook change reporting of resistance values, see GetTPResults()
/// - Baseline percentage:
///       Fraction which the baseline occupies relative to the total
///       testpulse length, before and after the pulse itself.
/// - Pulse duration [ms]
/// - Amplitude VC
/// - Amplitude IC
/// - Auto TP: On/Off (Requires to also call TP_AutoTPGenerateNewCycleID() when writing)
/// - Auto TP: Maximum current [pA]
/// - Auto TP: Voltage [mV]
/// - Auto TP: +/- Voltage [mV]
/// - Auto TP: Percentage [%]
/// - Auto TP: Interval [s]
/// - Auto TP: Cycle ID
///
/// Columns:
/// - LABNOTEBOOK_LAYER_COUNT
Function/WAVE GetTPSettings(string device)

	variable versionOfNewWave = TP_SETTINGS_WAVE_VERSION

	DFREF dfr = GetDeviceTestPulse(device)

	WAVE/Z/D/SDFR=dfr wv = settings

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(14, -1) wv
		SetDimensionLabels(wv, TP_SETTINGS_LABELS, ROWS)
	else
		WAVE wv = GetTPSettingsFree()
		MoveWave wv, dfr:settings
	endif

	DAP_TPSettingsToWave(device, wv)

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

static Constant TP_SETTINGSCALCULATED_WAVE_VERSION = 3

/// @brief Return the calculated/derived TP settings
///
/// The entries in this wave are only valid during DAQ/TP and are updated via DC_UpdateGlobals().
Function/WAVE GetTPSettingsCalculated(string device)

	DFREF dfr = GetDeviceTestPulse(device)

	WAVE/Z/D/SDFR=dfr wv = settingsCalculated

	if(ExistsWithCorrectLayoutVersion(wv, TP_SETTINGSCALCULATED_WAVE_VERSION))
		return wv
	elseif(WaveExists(wv))
		if(!IsWaveVersioned(wv))
			Redimension/N=(7) wv
			SetDimensionLabels(wv, "baselineFrac;pulseLengthMS;pulseLengthPointsTP;pulseLengthPointsDAQ;totalLengthMS;totalLengthPointsTP;totalLengthPointsDAQ;", ROWS)
			SetWaveVersion(wv, 1)
		endif
		if(WaveVersionIsAtLeast(wv, 1))
			Redimension/N=(10) wv
			SetDimensionLabels(wv, "baselineFrac;pulseLengthMS;pulseLengthPointsTP;pulseLengthPointsDAQ;totalLengthMS;totalLengthPointsTP;totalLengthPointsDAQ;pulseStartMS;pulseStartPointsTP;pulseStartPointsDAQ;", ROWS)
			SetWaveVersion(wv, 2)
		endif
		if(WaveVersionIsAtLeast(wv, 2))
			Redimension/N=(16) wv
			SetDimensionLabels(wv, "baselineFrac;pulseLengthMS;pulseLengthPointsTP;pulseLengthPointsDAQ;totalLengthMS;totalLengthPointsTP;totalLengthPointsDAQ;pulseStartMS;pulseStartPointsTP;pulseStartPointsDAQ;pulseLengthPointsTP_ADC;pulseLengthPointsDAQ_ADC;totalLengthPointsTP_ADC;totalLengthPointsDAQ_ADC;pulseStartPointsTP_ADC;pulseStartPointsDAQ_ADC;", ROWS)
			wv[%pulseLengthPointsTP_ADC]  = wv[%pulseLengthPointsTP]
			wv[%pulseLengthPointsDAQ_ADC] = wv[%pulseLengthPointsDAQ]
			wv[%totalLengthPointsTP_ADC]  = wv[%totalLengthPointsTP]
			wv[%totalLengthPointsDAQ_ADC] = wv[%totalLengthPointsDAQ]
			wv[%pulseStartPointsTP_ADC]   = wv[%pulseStartPointsTP]
			wv[%pulseStartPointsDAQ_ADC]  = wv[%pulseStartPointsDAQ]
		endif

		SetTPSettingsCalculatedProperties(wv)

		return wv
	endif

	WAVE/D wv = GetTPSettingsCalculatedAsFree()
	MoveWave wv, dfr:settingsCalculated

	return wv
End

Function/WAVE GetTPSettingsCalculatedAsFree()

	Make/FREE/D/N=(16) wv
	wv = NaN

	SetTPSettingsCalculatedProperties(wv)

	return wv
End

static Function SetTPSettingsCalculatedProperties(WAVE wv)

	SetDimensionLabels(wv, "baselineFrac;pulseLengthMS;pulseLengthPointsTP;pulseLengthPointsDAQ;totalLengthMS;totalLengthPointsTP;totalLengthPointsDAQ;pulseStartMS;pulseStartPointsTP;pulseStartPointsDAQ;pulseLengthPointsTP_ADC;pulseLengthPointsDAQ_ADC;totalLengthPointsTP_ADC;totalLengthPointsDAQ_ADC;pulseStartPointsTP_ADC;pulseStartPointsDAQ_ADC;", ROWS)
	SetWaveVersion(wv, TP_SETTINGSCALCULATED_WAVE_VERSION)
End

static Constant TP_SETTINGS_WAVE_VERSION = 2

/// @brief Returns a wave reference to the TP settings key wave
///
/// Rows:
/// - 0: Parameter
/// - 1: Units
/// - 2: Tolerance Factor
///
/// Columns (all entries headstage dependent except otherwise noted):
/// -  0: TP Baseline Fraction (INDEP_HEADSTAGE)
/// -  1: TP Amplitude VC
/// -  2: TP Amplitude IC
/// -  3: TP Pulse Duration (INDEP_HEADSTAGE)
/// -  4: TP Auto On/Off
/// -  5: TP Auto max current
/// -  6: TP Auto voltage
/// -  7: TP Auto voltage range
/// -  8: TP buffer size (INDEP_HEADSTAGE)
/// -  9: Minimum TP resistance for tolerance (INDEP_HEADSTAGE)
/// - 10: Send TP settings to all headstages (INDEP_HEADSTAGE)
/// - 11: TP Auto percentage (INDEP_HEADSTAGE)
/// - 12: TP Auto interval (INDEP_HEADSTAGE)
/// - 13: TP Auto QC
/// - 14: TP Cycle ID
Function/WAVE GetTPSettingsLabnotebookKeyWave(string device)

	variable versionOfNewWave = TP_SETTINGS_WAVE_VERSION

	DFREF             dfr = GetDevSpecLabNBTempFolder(device)
	WAVE/Z/T/SDFR=dfr wv  = TPSettingsKeyWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	if(WaveExists(wv))
		Redimension/N=(-1, 15) wv
	else
		Make/T/N=(3, 15) dfr:TPSettingsKeyWave/WAVE=wv
	endif

	wv = ""

	SetDimLabel 0, 0, Parameter, wv
	SetDimLabel 0, 1, Units, wv
	SetDimLabel 0, 2, Tolerance, wv

	wv[%Parameter][0] = "TP Baseline Fraction" // fraction of total TP duration
	wv[%Units][0]     = ""
	wv[%Tolerance][0] = "0.01"

	wv[%Parameter][1] = TP_AMPLITUDE_VC_ENTRY_KEY
	wv[%Units][1]     = "pA"
	wv[%Tolerance][1] = "-"

	wv[%Parameter][2] = TP_AMPLITUDE_IC_ENTRY_KEY
	wv[%Units][2]     = "mV"
	wv[%Tolerance][2] = "-"

	wv[%Parameter][3] = "TP Pulse Duration"
	wv[%Units][3]     = "ms"
	wv[%Tolerance][3] = "-"

	wv[%Parameter][4] = "TP Auto"
	wv[%Units][4]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][4] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][5] = "TP Auto max current"
	wv[%Units][5]     = "pA"
	wv[%Tolerance][5] = "0.1"

	wv[%Parameter][6] = "TP Auto voltage"
	wv[%Units][6]     = "mV"
	wv[%Tolerance][6] = "0.1"

	wv[%Parameter][7] = "TP Auto voltage range"
	wv[%Units][7]     = "mV"
	wv[%Tolerance][7] = "0.1"

	wv[%Parameter][8] = "TP buffer size"
	wv[%Units][8]     = ""
	wv[%Tolerance][8] = "0.1"

	wv[%Parameter][9] = "Minimum TP resistance for tolerance"
	wv[%Units][9]     = "MΩ"
	wv[%Tolerance][9] = "1"

	wv[%Parameter][10] = "Send TP settings to all headstages"
	wv[%Units][10]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][10] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][11] = "TP Auto percentage"
	wv[%Units][11]     = "%"
	wv[%Tolerance][11] = "1"

	wv[%Parameter][12] = "TP Auto interval"
	wv[%Units][12]     = "s"
	wv[%Tolerance][12] = "0.1"

	wv[%Parameter][13] = "TP Auto QC"
	wv[%Units][13]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][13] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][14] = "TP Cycle ID"
	wv[%Units][14]     = ""
	wv[%Tolerance][14] = "1"

	return wv
End

/// @brief Get TP settings wave for the labnotebook
///
/// See GetTPSettingsLabnotebookKeyWave() for the dimension label description.
Function/WAVE GetTPSettingsLabnotebook(string device)

	variable numCols
	variable versionOfNewWave = TP_SETTINGS_WAVE_VERSION

	DFREF             dfr = GetDevSpecLabNBTempFolder(device)
	WAVE/Z/D/SDFR=dfr wv  = TPSettings

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	WAVE/T keyWave = GetTPSettingsLabnotebookKeyWave(device)
	numCols = DimSize(keyWave, COLS)

	if(WaveExists(wv))
		Redimension/D/N=(-1, numCols, LABNOTEBOOK_LAYER_COUNT) wv
	else
		Make/D/N=(1, numCols, LABNOTEBOOK_LAYER_COUNT) dfr:TPSettings/WAVE=wv
	endif

	wv = NaN

	SetSweepSettingsDimLabels(wv, keyWave)
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @name Async Framework
///@{

/// @brief Return wave reference to wave with data folder reference buffer for delayed readouts
/// 1d wave for data folder references, starts with size 0
/// when jobs should be read out in order, the waiting data folders are buffered in this wave
/// e.g. if the next read out would be job 2, but a data folder from job 3 is returned
/// the data folder is buffered until the one from job 2 appears from the output queue
Function/WAVE GetDFREFbuffer(DFREF dfr)

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/DF/SDFR=dfr wv = DFREFbuffer

	if(WaveExists(wv))
		return wv
	endif
	Make/DF/N=0 dfr:DFREFbuffer/WAVE=wv

	return wv
End

/// @brief Returns wave ref for workload tracking
/// 2d wave
/// row stores work load classes named through dimension label
/// column 0 stores how many work loads were pushed to Async
/// column 1 stores how many work loads were read out from Async
Function/WAVE GetWorkloadTracking(DFREF dfr)

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/U/L/SDFR=dfr wv = WorkloadTracking

	if(WaveExists(wv))
		return wv
	endif

	Make/L/U/N=(0, 3) dfr:WorkloadTracking/WAVE=wv
	SetDimLabel COLS, 0, $"INPUTCOUNT", wv
	SetDimLabel COLS, 1, $"OUTPUTCOUNT", wv
	SetDimLabel COLS, 2, $"INORDER", wv
	return wv
End

/// @brief Returns wave ref for buffering results when THREADING_DISABLED is defined
/// 1D wave using NOTE_INDEX logic
Function/WAVE GetSerialExecutionBuffer(DFREF dfr)

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/DF/SDFR=dfr wv = SerialExecutionBuffer

	if(WaveExists(wv))
		return wv
	endif

	Make/DF/N=(MINIMUM_WAVE_SIZE) dfr:SerialExecutionBuffer/WAVE=wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Returns string path to async framework home data folder
///
/// UTF_NOINSTRUMENTATION
Function/S GetAsyncHomeStr()

	return "root:Packages:Async"
End

/// @brief Returns reference to async framework home data folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetAsyncHomeDF()

	return createDFWithAllParents(getAsyncHomeStr())
End

///@}

/// @brief Returns a free wave for gathering formula results
///
/// The wave stores the wave reference waves returned from SFE_ExecuteFormula for the X and Y formulas.
/// In SF_GatherFormulaResults() all formula pairs for on graph subwindow are gathered.
Function/WAVE GetFormulaGatherWave()

	Make/FREE/WAVE/N=(0, 2) formulaResults
	SetDimLabel COLS, 0, FORMULAX, formulaResults
	SetDimLabel COLS, 1, FORMULAY, formulaResults

	return formulaResults
End

/// @brief Returns variable storage of data browser referenced by dfr
Function/WAVE GetSFVarStorage(string graph)

	string name = "VariableStorage"

	DFREF dfr = SF_GetBrowserDF(graph)
	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/WAVE wv = dfr:$name

	if(WaveExists(wv))
		return wv
	endif

	Make/WAVE/N=0 dfr:$name/WAVE=wv

	return wv
End

/// @brief Returns a wave where variable assignments are collected into
///
/// This 2D wave is used by "check" when the variables from the SF notebook are processed
/// The ROWS collect the variables
/// Columns:
/// VARNAME    : name of the variable
/// EXPRESSION : formula for this variable
/// LINE       : line number in SF notebook where the variable is defined
/// OFFSET     : character offset in the line where the formula for this variable starts
Function/WAVE GetSFVarAssignments()

	Make/FREE/T/N=(0, 4) varAssignments
	SetDimLabel COLS, 0, VARNAME, varAssignments
	SetDimLabel COLS, 1, EXPRESSION, varAssignments
	SetDimLabel COLS, 2, LINE, varAssignments
	SetDimLabel COLS, 3, OFFSET, varAssignments

	return varAssignments
End

/// @brief Returns a wave where GetActiveChannels fills in the mapping between GUI and hardware TTL channels
///        The wave is initialized here with no active channels
threadsafe Function/WAVE GetActiveChannelMapTTLGUIToHW()

	Make/FREE/D/N=(NUM_DA_TTL_CHANNELS, 2) channelMapGUIToHW = NaN
	SetDimlabel COLS, 0, HWCHANNEL, channelMapGUIToHW
	SetDimlabel COLS, 1, TTLBITNR, channelMapGUIToHW

	return channelMapGUIToHW
End

/// @brief Returns a wave where GetActiveChannels fills in the mapping between hardware and GUI TTL channels
///        The wave is initialized here with no active channels
threadsafe Function/WAVE GetActiveChannelMapTTLHWToGUI()

	variable numHWTTLChannels

	numHWTTLChannels = max(HARDWARE_ITC_TTL_1600_RACK_ONE + 1, NUM_DA_TTL_CHANNELS)
	Make/FREE/D/N=(numHWTTLChannels, NUM_ITC_TTL_BITS_PER_RACK) channelMapHWToGUI = NaN

	return channelMapHWToGUI
End

/// @name SweepFormula PSX
///@{

static Constant PSX_WAVE_VERSION       = 3
static Constant PSX_EVENT_WAVE_COLUMNS = 17

/// @brief Return the upgraded psxEvent wave
Function/WAVE UpgradePSXEventWave(WAVE psxEvent)

	if(WaveVersionIsAtLeast(psxEvent, PSX_WAVE_VERSION))
		return psxEvent
	elseif(WaveVersionIsAtLeast(psxEvent, 2))

		if(!AlreadyCalledOnce(CO_PSX_UPGRADE_EVENT))
			print "The algorithm for psp/psc event detection was heavily overhauled, therefore we are very sorry " \
			      + "to say that we can't upgrade your existing data."
			ControlWindowToFront()
		endif

		return $""
	elseif(WaveVersionIsAtLeast(psxEvent, 1))
		SetPSXEventDimensionLabels(psxEvent)
	else
		FATAL_ERROR("Missing upgrade path")
	endif

	return psxEvent
End

/// @brief Return a 2D events wave as free wave
///
/// Rows:
/// - count
///
/// Cols:
/// -  0/index: event index
/// -  1/deconvPeak: event amplitude in deconvoluted data [y unit of data]
/// -  2/deconvPeak_t: deconvolved peak time [ms]
/// -  3/peak: Maximum (positive kernel amp sign) or minimum (negative kernel amp sign) in the range of
///            [deconvPeak_t – kernelRiseTau or devonvPeak_t of the previous event (whichever comes later),
///             deconvPeak_t + 0.33 * kernelDecayTau or deconvPeak_t of the next event (which ever comes first)]
///            in the filtered sweep wave
/// -  4/peak_t: peak time
/// -  5/baseline: Maximum (negative kernel amp sign) or minimum (positive kernel amp sign) in the range of
///                    [peak_t – 10 * kernelRiseTau, peak_t], averaged over +/- 5 points, in the filtered sweep wave
/// -  6/baseline_t: baseline time
/// -  7/amplitude: Relative amplitude: [3] - [5]
/// -  8/iei: Time difference to previous event (inter event interval) [ms]
/// -  9/tau: Decay constant tau of exponential fit
/// - 10/Fit manual QC call: One of @ref PSXStates
/// - 11/Fit result: 1 for success, everything smaller than 0 is failure:
///   - `]-10000, 0[`: CurveFit error codes
///   - `]-inf, -10000]`: Custom error codes, one of @ref FitEventDecayCustomErrors
/// - 12/Event manual QC call: One of @ref PSXStates
/// - 13/Onset time as calculated by PSX_CalculateOnsetTime
/// - 14/Rise Time as calculated by PSX_CalculateRiseTime
/// - 15/Slew Rate
/// - 16/Slew Rate Time
Function/WAVE GetPSXEventWaveAsFree()

	variable versionOfWave = PSX_WAVE_VERSION

	Make/D/FREE=1/N=(0, PSX_EVENT_WAVE_COLUMNS) psxEvent = NaN
	WAVE wv = psxEvent

	SetPSXEventDimensionLabels(wv)
	SetWaveVersion(wv, versionOfWave)

	return wv
End

static Function SetPSXEventDimensionLabels(WAVE wv)

	SetDimLabel COLS, 0, index, wv
	SetDimLabel COLS, 1, deconvPeak, wv
	SetDimLabel COLS, 2, deconvPeak_t, wv
	SetDimLabel COLS, 3, peak, wv
	SetDimLabel COLS, 4, peak_t, wv
	SetDimLabel COLS, 5, baseline, wv
	SetDimLabel COLS, 6, baseline_t, wv
	SetDimLabel COLS, 7, amplitude, wv
	SetDimLabel COLS, 8, iei, wv
	SetDimLabel COLS, 9, tau, wv
	SetDimLabel COLS, 10, $"Fit manual QC call", wv
	SetDimLabel COLS, 11, $"Fit result", wv
	SetDimLabel COLS, 12, $"Event manual QC call", wv
	SetDimLabel COLS, 13, $"Onset Time", wv
	SetDimLabel COLS, 14, $"Rise Time", wv
	SetDimLabel COLS, 15, $"Slew Rate", wv
	SetDimLabel COLS, 16, $"Slew Rate Time", wv
End

Function/WAVE GetPSXSingleEventFitWaveFromDFR(DFREF dfr)

	WAVE/Z/D/SDFR=dfr wv = singleEventFit

	if(WaveExists(wv))
		return wv
	endif

	Make/D/N=(0) dfr:singleEventFit/WAVE=wv

	return wv
End

Function/WAVE GetPSXEventFitWaveAsFree()

	variable versionOfWave = 1

	Make/WAVE/FREE=1/N=(0) eventFit
	WAVE wv = eventFit

	SetWaveVersion(wv, versionOfWave)

	return wv
End

Function/WAVE GetPSXEventColorsWaveAsFree(variable numEvents)

	Make/FREE/N=(numEvents, 4)/FREE=1 eventColors

	return eventColors
End

Function/WAVE GetPSXEventMarkerWaveAsFree(variable numEvents)

	Make/FREE/N=(numEvents)/FREE=1 eventMarker

	return eventMarker
End

static Function/WAVE GetWaveFromFolder(DFREF dfr, string name)

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")

	WAVE/Z/SDFR=dfr wv = $name
	ASSERT(WaveExists(wv), "Missing wave:" + name)

	return wv
End

Function/WAVE GetPSXEventWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "psxEvent")
End

Function/WAVE GetPSXPeakXWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "peakX")
End

Function/WAVE GetPSXPeakYWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "peakY")
End

Function/WAVE GetPSXPeakYAtFiltWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "peakYAtFilt")
End

Function/WAVE GetPSXEventColorsWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "eventColors")
End

Function/WAVE GetPSXEventMarkerWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "eventMarker")
End

Function/WAVE GetPSXEventFitWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "eventFit")
End

Function/WAVE GetPSXSweepDataWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "sweepData")
End

Function/WAVE GetPSXSweepDataOffFiltWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "sweepDataOffFilt")
End

Function/WAVE GetPSXSweepDataOffFiltDeconvWaveFromDFR(DFREF dfr)

	return GetWaveFromFolder(dfr, "sweepDataOffFiltDeconv")
End

Function/WAVE GetPSXEventLocationLabels(DFREF dfr)

	return GetWaveFromFolder(dfr, "eventLocationLabels")
End

Function/WAVE GetPSXEventLocationTicks(DFREF dfr)

	return GetWaveFromFolder(dfr, "eventLocationTicks")
End

Function/S GetPSXFolderForComboAsString(DFREF dfr, variable index)

	return GetDataFolder(1, dfr) + "combo_" + num2istr(index)
End

Function/DF GetPSXFolderForCombo(DFREF dfr, variable index)

	return createDFWithAllParents(GetPSXFolderForComboAsString(dfr, index))
End

Function/WAVE GetPSXComboListBox(DFREF dfr)

	string name = "combinations"

	WAVE/Z/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	WAVE wv = PSX_CreateCombinationsListBoxWaveAsFree(dfr)

	MoveWave wv, dfr:$name

	return wv
End

Function/S GetPSXSingleEventFolderAsString(DFREF comboDFR)

	return GetDataFolder(1, comboDFR) + "singleEvent"
End

Function/DF GetPSXSingleEventFolder(DFREF comboDFR)

	return createDFWithAllParents(GetPSXSingleEventFolderAsString(comboDFR))
End

/// @brief Return the average wave of the given state for the PSX event plot
///
/// `dfr` can be either `singleEventDFR` for the per-combo averages or `workDFR`
/// for the average over all events disregarding the combo.
Function/WAVE GetPSXAverageWave(DFREF dfr, variable state)

	string name = "average" + PSX_StateToString(state)

	WAVE/Z/D/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	Make/D/N=0 dfr:$name/WAVE=wv

	return wv
End

Function/WAVE GetPSXAcceptedAverageFitWaveFromDFR(DFREF dfr)

	WAVE/Z/D/SDFR=dfr wv = acceptedAverageFit

	if(WaveExists(wv))
		return wv
	endif

	Make/D/N=(0) dfr:acceptedAverageFit/WAVE=wv

	return wv
End

///@}

/// @brief Returns a wave with the names of all log files
Function/WAVE GetLogFileNames()

	Make/FREE/T files = {{LOG_GetFile(PACKAGE_MIES), GetZeroMQXOPLogfile(), GetITCXOP2Logfile()}, {"MIES-log-file-does-not-exist", "ZeroMQ-XOP-log-file-does-not-exist", "ITC-XOP2-log-file-does-not-exist"}, {"MIES log file", "ZeroMQ log file", "ITCXOP2 log file"}}
	SetDimLabel COLS, 0, FILENAME, files
	SetDimLabel COLS, 1, NOTEXISTTEXT, files
	SetDimLabel COLS, 2, DESCRIPTION, files

	return files
End

/// @brief Used as temporary wave to store various sampling intervals in ms
Function/WAVE GetNewSamplingIntervalsAsFree()

	Make/FREE/D/N=4 wv

	SetDimLabel ROWS, 0, SI_TP_DAC, wv
	SetDimLabel ROWS, 1, SI_DAQ_DAC, wv
	SetDimLabel ROWS, 2, SI_TP_ADC, wv
	SetDimLabel ROWS, 3, SI_DAQ_ADC, wv

	return wv
End

/// @brief Return wave with Sutter device info
///
/// ROWS:
/// - NUMBEROFDACS: number of IPA devices
/// - MASTERDEVICE: Serial of master device
/// - LISTOFDEVICES: Serials of SubDevices
/// - LISTOFHEADSTAGES: Number of Headstages per Device
/// - SUMHEADSTAGES: Sum of Headstages
/// - AI: Number of analog ins
/// - AO: Number of analog outs
/// - DIOPortWidth: Number of digital outs
Function/WAVE GetSUDeviceInfo()

	variable version = 1
	string   name    = "SUDeviceInfo"

	DFREF dfr = GetDeviceInfoPath()

	WAVE/Z/T/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		// upgrade here
	else
		Make/T/N=8 dfr:$name/WAVE=wv
	endif

	SetDimensionLabels(wv, "NUMBEROFDACS;MASTERDEVICE;LISTOFDEVICES;LISTOFHEADSTAGES;SUMHEADSTAGES;AI;AO;DIOPortWidth;", ROWS)
	HW_SU_GetDeviceInfo(wv)

	return wv
End

/// @brief Return wave with Sutter input list wave
///
/// ROWS:
/// - entries
///
/// COLS:
/// - INPUTWAVE: full path to input wave
/// - CHANNEL: sutter hardware channel number
/// - ENCODEINFO: additional information for multi-device configuration
Function/WAVE GetSUDeviceInput(string device)

	variable version = 1
	string   name    = "SUDeviceInput"

	DFREF dfr = GetDevicePath(device)

	WAVE/Z/T/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		// upgrade here
	else
		Make/T/N=(0, 3) dfr:$name/WAVE=wv
	endif

	SetDimensionLabels(wv, "INPUTWAVE;CHANNEL;ENCODEINFO;", COLS)

	return wv
End

/// @brief Return wave with Sutter output list wave
///
/// ROWS:
/// - entries
///
/// COLS:
/// - OUTPUTWAVE: full path to output wave
/// - CHANNEL: sutter hardware channel number
/// - ENCODEINFO: additional information for multi-device configuration
Function/WAVE GetSUDeviceOutput(string device)

	variable version = 1
	string   name    = "SUDeviceOutput"

	DFREF dfr = GetDevicePath(device)

	WAVE/Z/T/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		// upgrade here
	else
		Make/T/N=(0, 3) dfr:$name/WAVE=wv
	endif

	SetDimensionLabels(wv, "OUTPUTWAVE;CHANNEL;ENCODEINFO;", COLS)

	return wv
End

/// @brief Return wave with Sutter gains for input
///
/// ROWS:
/// - entries
///
/// COLS:
/// - GAINFACTOR: gain factor
/// - OFFSET: offset
Function/WAVE GetSUDeviceInputGains(string device)

	variable version = 1
	string   name    = "SUDeviceInputGains"

	DFREF dfr = GetDevicePath(device)

	WAVE/Z/D/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		// upgrade here
	else
		Make/D/N=(0, 2) dfr:$name/WAVE=wv
	endif

	SetDimensionLabels(wv, "GAINFACTOR;OFFSET;", COLS)

	return wv
End

/// @brief Returns valid TTL channel sample intervals of sutter IPA hardware in microseconds
Function/WAVE GetSutterDACTTLSampleInterval()

	Make/FREE/D rates = {1 / 100, 1 / 200, 1 / 400, 1 / 800, 1 / 1000, 1 / 2000, 1 / 4000, 1 / 5000, 1 / 8000, 1 / 10000} // NOLINT
	rates *= ONE_TO_MICRO
	SetScale d, 0, 0, "µs", rates

	return rates
End

/// @brief Returns valid ADC channel sample intervals of sutter IPA hardware in microseconds
Function/WAVE GetSutterADCSampleInterval()

	Make/FREE/D rates = {1 / 100, 1 / 200, 1 / 400, 1 / 800, 1 / 1000, 1 / 2000, 1 / 4000, 1 / 5000, 1 / 8000, 1 / 10000, 1 / 20000, 1 / 25000, 1 / 40000, 1 / 50000} // NOLINT
	rates *= ONE_TO_MICRO
	SetScale d, 0, 0, "µs", rates

	return rates
End

/// @brief Gets from a Logbook values wave the wave with sortedKeys and associated indices in a separate wave
threadsafe Function [WAVE/T sortedKeys, WAVE/D indices] GetLogbookSortedKeys(WAVE values)

	variable numKeys
	string keysName, sortedKeysName, sortedKeysIndicesName, cacheKey

	WAVE/T keys = GetLogbookKeysFromValues(values)
	cacheKey = CA_GenKeyLogbookSortedKeys(keys)

	DFREF dfrTmp = createDFWithAllParents(GetWavesDataFolder(keys, 1) + LOGBOOK_WAVE_TEMP_FOLDER)
	keysName              = NameOfWave(keys)
	sortedKeysName        = keysName + LOGBOOK_SUFFIX_SORTEDKEYS
	sortedKeysIndicesName = keysName + LOGBOOK_SUFFIX_SORTEDKEYSINDICES

	WAVE/Z/T sortedKeys = dfrTmp:$sortedKeysName
	if(WaveExists(sortedKeys) && !CmpStr(note(sortedKeys), cacheKey))
		WAVE indices = dfrTmp:$sortedKeysIndicesName
		return [sortedKeys, indices]
	endif

	numKeys = DimSize(keys, COLS)
	Make/O/T/N=(numKeys) dfrTmp:$sortedKeysName/WAVE=sortedKeys
	Make/O/D/N=(numKeys) dfrTmp:$sortedKeysIndicesName/WAVE=indices
	MultiThread sortedKeys[] = keys[0][p]
	MultiThread indices[] = p
	Sort {sortedKeys}, sortedKeys, indices
	Note/K sortedKeys, cacheKey

	return [sortedKeys, indices]
End

/// @brief Return the stimset folder from the numeric channelType, #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
///
/// @returns Data Folder reference to Stimset dataFolder
Function/DF GetSetFolder(variable channelType)

	if(channelType == CHANNEL_TYPE_DAC)
		return GetWBSvdStimSetDAPath()
	elseif(channelType == CHANNEL_TYPE_TTL)
		return GetWBSvdStimSetTTLPath()
	else
		FATAL_ERROR("unknown channelType")
	endif
End

/// @brief Return the stimset folder from the numeric channelType, #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
///
/// @returns String with full path to Stimset dataFolder
Function/S GetSetFolderAsString(variable channelType)

	if(channelType == CHANNEL_TYPE_DAC)
		return GetWBSvdStimSetDAPathAsString()
	elseif(channelType == CHANNEL_TYPE_TTL)
		return GetWBSvdStimSetTTLPathAsString()
	else
		FATAL_ERROR("unknown channelType")
	endif
End

/// @brief Get the stimset parameter folder
///
/// @param channelType #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
///
/// @returns dataFolder as DFREF
Function/DF GetSetParamFolder(variable channelType)

	if(channelType == CHANNEL_TYPE_DAC)
		return GetWBSvdStimSetParamDAPath()
	elseif(channelType == CHANNEL_TYPE_TTL)
		return GetWBSvdStimSetParamTTLPath()
	else
		FATAL_ERROR("unknown channelType")
	endif
End

/// @brief Get the stimset parameter folder
///
/// @param channelType #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
///
/// @returns dataFolder as String
Function/S GetSetParamFolderAsString(variable channelType)

	if(channelType == CHANNEL_TYPE_DAC)
		return GetWBSvdStimSetParamPathAS() + ":DA"
	elseif(channelType == CHANNEL_TYPE_TTL)
		return GetWBSvdStimSetParamPathAS() + ":TTL"
	else
		FATAL_ERROR("unknown channelType")
	endif
End

/// @brief returns a composite wave for select
Function/WAVE GetSFSelectDataComp(string graph, string opShort)

	WAVE/WAVE selectDataComp = SFH_CreateSFRefWave(graph, opShort, 2)
	SetDimensionLabels(selectDataComp, "SELECTION;RANGE;", ROWS)

	return selectDataComp
End

/// @brief Get a free wave that can store TP analysis data
///
/// @returns a named (tpData) free wave
threadsafe Function/WAVE GetTPAnalysisDataWave()

	Make/FREE=1/D/N=(ItemsInList(TP_ANALYSIS_DATA_LABELS)) tpData
	SetDimensionLabels(tpData, TP_ANALYSIS_DATA_LABELS, ROWS)

	return tpData
End

/// @name Waveref Browser
///@{

/// @brief Returns string path to Waveref Browser home data folder
///
/// UTF_NOINSTRUMENTATION
Function/S GetWaverefBrowserHomeStr()

	return "root:Packages:WaverefBrowser"
End

/// @brief Returns reference to Waveref Browser home data folder
///
/// UTF_NOINSTRUMENTATION
Function/DF GetWaverefBRowserHomeDF()

	return createDFWithAllParents(GetWaverefBrowserHomeStr())
End

Function/WAVE GetWaverefBRowserListWave()

	variable version = 1
	string   name    = "listWave"

	DFREF dfr = GetWaverefBRowserHomeDF()

	WAVE/Z/T/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		// upgrade here
	else
		Make/T/N=(0) dfr:$name/WAVE=wv
	endif

	return wv
End

Function/WAVE GetWaverefBRowserSelectionWave()

	variable version = 1
	string   name    = "selectionWave"

	DFREF dfr = GetWaverefBRowserHomeDF()

	WAVE/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		// upgrade here
	else
		Make/N=(0, 1, 3) dfr:$name/WAVE=wv
	endif

	SetDimLabel LAYERS, 1, $LISTBOX_LAYER_FOREGROUND, wv
	SetDimLabel LAYERS, 2, $LISTBOX_LAYER_BACKGROUND, wv

	return wv
End

Function/WAVE GetWaverefBRowserColorWave()

	variable version = 1
	string   name    = "colorWave"

	DFREF dfr = GetWaverefBRowserHomeDF()

	WAVE/Z/U/W/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		// upgrade here
	else
		Make/W/U/N=(5, 3) dfr:$name/WAVE=wv
	endif

	SetDimLabel COLS, 0, R, wv
	SetDimLabel COLS, 1, G, wv
	SetDimLabel COLS, 2, B, wv

	wv[1][%R] = 255
	wv[1][%G] = 255
	wv[1][%B] = 229

	wv[2][%R] = 229
	wv[2][%G] = 255
	wv[2][%B] = 229

	wv[3][%R] = 255
	wv[3][%G] = 229
	wv[3][%B] = 229

	wv[4][%R] = 229
	wv[4][%G] = 255
	wv[4][%B] = 255

	wv = wv << 8

	return wv
End

Function/WAVE GetWaverefBRowserReferenceWave()

	variable version = 1
	string   name    = "referenceWave"

	DFREF dfr = GetWaverefBRowserHomeDF()

	WAVE/Z/WAVE/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, version))
		return wv
	endif

	if(WaveExists(wv))
		// upgrade here
	else
		Make/WAVE/N=(0) dfr:$name/WAVE=wv
	endif

	return wv
End

///@}

#ifdef DEBUGGING_ENABLED
// Stores logging information from the SF parser for a single parser run
Function/WAVE GetSFStateLog()

	string name = "stateLog"

	DFREF dfr = GetSweepFormulaPath()

	WAVE/Z/T/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(0, 8) dfr:$name/WAVE=wv

	SetDimLabel COLS, 0, TOKEN, wv
	SetDimLabel COLS, 1, STATE, wv
	SetDimLabel COLS, 2, LASTSTATE, wv
	SetDimLabel COLS, 3, LASTCALCULATION, wv
	SetDimLabel COLS, 4, ACTION, wv
	SetDimLabel COLS, 5, RECURSIONDEPTH, wv
	SetDimLabel COLS, 6, ERRORMSG, wv
	SetDimLabel COLS, 7, FORMULA, wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

// Aggregates parser state logs globally
// The wave is created in root: because the MIES folder is volatile
Function/WAVE GetSFStateLogCollection()

	string name = "SFParserStateLog"

	DFREF dfr = root:

	WAVE/Z/T/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(0) dfr:$name/WAVE=wv

	return wv
End
#endif // DEBUGGING_ENABLED

/// @brief returns a color wave for the error message for sweepformula in the databrowser
Function/WAVE GetSFErrorColorWave()

	Make/FREE/W/U/N=(3, 3) wv

	SetDimLabel COLS, 0, R, wv
	SetDimLabel COLS, 1, G, wv
	SetDimLabel COLS, 2, B, wv

	SetDimLabel ROWS, 0, OK, wv
	SetDimLabel ROWS, 1, WARN, wv
	SetDimLabel ROWS, 2, ERROR, wv

	wv[%OK][%R] = 0
	wv[%OK][%G] = 128
	wv[%OK][%B] = 0

	wv[%WARN][%R] = 255
	wv[%WARN][%G] = 128
	wv[%WARN][%B] = 0

	wv[%ERROR][%R] = 255
	wv[%ERROR][%G] = 0
	wv[%ERROR][%B] = 0

	wv = wv << 8

	return wv
End

/// @brief Creates a new free wave for source location tracking
///
/// Columns:
/// PATH : json path in the jsonId returned by SFP_FormulaParser
/// OFFSET : character offset into the parsed formula where the element for json path starts
///
/// The wave rows are NOTE_INDEX managed
Function/WAVE GetNewSourceLocationWave()

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE, 2) srcLocs
	SetDimLabel COLS, 0, PATH, srcLocs
	SetDimLabel COLS, 1, OFFSET, srcLocs
	SetNumberInWaveNote(srcLocs, NOTE_INDEX, 0)

	return srcLocs
End

/// @brief Creates a global wave storing data for the case the SF executor runs into an SFH_ASSERT
///
/// Rows:
/// SRCLOCID : json id of the JSON storing the source location information
/// JSONPATH : last json path the executor was working on, this element is updated by the executor while executing
/// STEP : step in the sweepformula exection, one of @sa SFExecutionSteps
/// LINE : line number where the current formula is in the SF notebook
/// OFFSET : character offset in the line where the current formula starts in the SF notebook
/// FORMULA : current formula string
/// INFORMULAOFFSET : character offset in the formula where the error is located
Function/WAVE GetSFAssertData()

	string name = "SFAssertData"

	DFREF dfr = GetSweepFormulaPath()

	WAVE/Z/T/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(8) dfr:$name/WAVE=wv

	SetDimLabel ROWS, 0, JSONID, wv
	SetDimLabel ROWS, 1, SRCLOCID, wv
	SetDimLabel ROWS, 2, JSONPATH, wv
	SetDimLabel ROWS, 3, STEP, wv
	SetDimLabel ROWS, 4, LINE, wv
	SetDimLabel ROWS, 5, OFFSET, wv
	SetDimLabel ROWS, 6, FORMULA, wv
	SetDimLabel ROWS, 7, INFORMULAOFFSET, wv

	wv[%STEP] = num2istr(SF_STEP_OUTSIDE)

	return wv
End
