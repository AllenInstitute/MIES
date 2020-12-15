#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_WAVEGETTERS
#endif

/// @file MIES_WaveDataFolderGetters.ipf
///
/// @brief Collection of Wave and Datafolder getter functions
///
/// - All functions with return types `DF` or `Wave` return an existing wave or datafolder.
/// - Prefer functions which return a `DFREF` over functions which return strings.
///   The latter ones are only useful if you need to know if the folder exists.
/// - Modifying wave getter functions might require to introduce wave versioning, see @ref WaveVersioningSupport

static Constant NUM_COLUMNS_LIST_WAVE   = 11
static StrConstant WAVE_NOTE_LAYOUT_KEY = "WAVE_LAYOUT_VERSION"

static Constant WAVE_TYPE_NUMERICAL = 0x1
static Constant WAVE_TYPE_TEXTUAL   = 0x2

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
	variable versionOfNewWave = 3

	Wave/D/Z/SDFR=dfr wv = ChanAmpAssign

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/D/N=(10, NUM_HEADSTAGES, -1, -1) wv
	else
		Make/D/N=(10, NUM_HEADSTAGES) dfr:ChanAmpAssign/Wave=wv
		wv = NaN

		// we don't have dimension labels yet
		if(DeviceCanLead(panelTitle) || DeviceCanFollow(panelTitle))
			// Use AD channels 0-3 and then 8-11 so that
			// they are all on the same rack
			wv[0][0, 7] = q
			wv[2][0, 7] = q <= 3 ? q : q + 4
			wv[4][0, 7] = q
			wv[6][0, 7] = q <= 3 ? q : q + 4
		else
			wv[0][0, 3] = q
			wv[2][0, 3] = q
			wv[4][0, 3] = q
			wv[6][0, 3] = q
		endif

		wv[1, 7;2][] = 1
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
	variable versionOfNewWave = 1

	Wave/T/Z/SDFR=dfr wv = ChanAmpAssignUnit

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// do nothing
	else
		Make/T/N=(4, NUM_HEADSTAGES) dfr:ChanAmpAssignUnit/Wave=wv
		wv = ""

		wv[0][] = "mV"
		wv[1][] = "pA"
		wv[2][] = "pA"
		wv[3][] = "mV"
	endif

	SetDimLabel ROWS, 0, VC_DAUnit, wv
	SetDimLabel ROWS, 1, VC_ADUnit, wv
	SetDimLabel ROWS, 2, IC_DAUnit, wv
	SetDimLabel ROWS, 3, IC_ADUnit, wv

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
/// 	Function/Wave GetMyWave(panelTitle)
/// 		string panelTitle
///
/// 		DFREF dfr = GetMyPath(panelTitle)
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
/// @{

/// @brief Check if wv exists and has the correct version
threadsafe static Function ExistsWithCorrectLayoutVersion(wv, versionOfNewWave)
	Wave/Z wv
	variable versionOfNewWave

	// The equality check ensures that you can also downgrade, e.g. from version 5 to 4, although this is *strongly* discouraged.
	return WaveExists(wv) && GetWaveVersion(wv) == versionOfNewWave
End

/// @brief Check if the given wave's version is equal or larger than the given version, if version is not set false is returned
static Function WaveVersionIsAtLeast(wv, existingVersion)
	WAVE/Z wv
	variable existingVersion

	variable waveVersion

	ASSERT(WaveExists(wv), "Wave does not exist")
	ASSERT(IsValidWaveVersion(existingVersion), "existing version must be a positive integer")
	waveVersion = GetWaveVersion(wv)

	return !isNaN(waveVersion) && waveVersion >= existingVersion
End

/// @brief Check if the given wave's version is smaller than the given version, if version is not set true is returned
static Function WaveVersionIsSmaller(wv, existingVersion)
	WAVE/Z wv
	variable existingVersion

	variable waveVersion

	ASSERT(WaveExists(wv), "Wave does not exist")
	ASSERT(IsValidWaveVersion(existingVersion), "existing version must be a positive integer")
	waveVersion = GetWaveVersion(wv)

	return isNaN(waveVersion) || waveVersion < existingVersion
End

/// @brief return the Version of the Wave, returns NaN if no version was set
threadsafe Function GetWaveVersion(wv)
	Wave/Z wv

	return GetNumberFromWaveNote(wv, WAVE_NOTE_LAYOUT_KEY)
End

/// @brief Set the wave layout version of wave
static Function SetWaveVersion(wv, val)
	Wave wv
	variable val

	ASSERT(IsValidWaveVersion(val), "val must be a positive and non-zero integer")
	SetNumberInWaveNote(wv, WAVE_NOTE_LAYOUT_KEY, val)
End

/// @brief A valid wave version is a positive non-zero integer
static Function IsValidWaveVersion(variable value)
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
threadsafe Function/DF UpgradeDataFolderLocation(oldFolder, newFolder)
	string oldFolder, newFolder

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
	KillOrMoveToTrash(dfr=$newFolder)

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
	KillOrMoveToTrash(dfr=$tempFolder)

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
///		Function/WAVE GetMyWave(panelTitle)
///			string panelTitle
///
///			variable versionOfNewWave = 1
///			string newName = "newAndNiceName"
///			DFREF newDFR = GetNewAndFancyFolder(panelTitle)
///
///			STRUCT WaveLocationMod p
///			p.dfr     = $(GetSomeFolder(panelTitle) + ":oldSubFolder")
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
Function/WAVE UpgradeWaveLocationAndGetIt(p)
	STRUCT WaveLocationMod &p

	ASSERT(strlen(p.name) > 0, "Invalid name")

	if(!DataFolderExistsDFR(p.newDFR))
		ASSERT(DataFolderExistsDFR(p.dfr), "Invalid dfr")
		p.newDFR = p.dfr
	endif

	if(!(strlen(p.newName) > 0))
		p.newName = p.name
	endif

	WAVE/SDFR=p.newDFR/Z dest = $p.newName

	if(DataFolderExistsDFR(p.dfr))
		WAVE/SDFR=p.dfr/Z src = $p.name
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
		else
			ASSERT(IsValidObjectName(p.newName), "Invalid/Liberal wave name for newName")
			MoveWave src, p.newDFR:$p.newName
			RemoveEmptyDataFolder(p.dfr)
			return src
		endif
	endif

	ASSERT(0, "impossible case")
End

/// @}

/// @brief Return a wave reference to the tp result async buffer wave
///
/// Rows:
/// - buffered partial result entries
///
/// Column 0 (ASYNCDATA):
///   - Layers:
///     - 0: marker
///     - 1: received channels
///     - 2: now
/// Column 1: baseline level
/// Column 2: steady state res
/// Column 3: instantaneous res
/// Column 4: baseline position
/// Column 5: steady state res position
/// Column 6: instantaneous res position
///   - Layers NUM_HEADSTAGES positions with value entries at hsIndex
Function/Wave GetTPResultAsyncBuffer(panelTitle)
	string panelTitle

	DFREF dfr = GetDeviceTestPulse(panelTitle)

	Wave/Z/SDFR=dfr/D wv = TPResultAsyncBuffer

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(0, 7, NUM_HEADSTAGES)/D dfr:TPResultAsyncBuffer/Wave=wv

	SetDimLabel COLS, 0, ASYNCDATA, wv
	SetDimLabel COLS, 1, BASELINE, wv
	SetDimLabel COLS, 2, STEADYSTATERES, wv
	SetDimLabel COLS, 3, INSTANTRES, wv
	SetDimLabel COLS, 4, BASELINE_POS, wv
	SetDimLabel COLS, 5, STEADYSTATERES_POS, wv
	SetDimLabel COLS, 6, INSTANTRES_POS, wv
	SetDimLabel LAYERS, 0, MARKER, wv
	SetDimLabel LAYERS, 1, REC_CHANNELS, wv
	SetDimLabel LAYERS, 2, NOW, wv

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
Function/Wave GetChannelClampMode(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)
	variable versionOfNewWave = 1

	Wave/Z/SDFR=dfr wv = ChannelClampMode

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, -1, 2) wv

		// prefill with existing algorithm for easier upgrades
		wv[][%DAC][1] = GetHeadstageFromSettings(panelTitle, ITC_XOP_CHANNEL_TYPE_DAC, p, wv[p][%DAC][0])
		wv[][%ADC][1] = GetHeadstageFromSettings(panelTitle, ITC_XOP_CHANNEL_TYPE_ADC, p, wv[p][%ADC][0])
	else
		Make/R/N=(NUM_AD_CHANNELS, 2, 2) dfr:ChannelClampMode/Wave=wv
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
Function/WAVE GetHSProperties(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)
	variable versionOfNewWave = 1

	Wave/Z/SDFR=dfr wv = HSProperties

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(NUM_HEADSTAGES, 4) dfr:HSProperties/Wave=wv
	endif

	wv = NaN

	SetDimLabel COLS, 0, Enabled  , wv
	SetDimLabel COLS, 1, ADC      , wv
	SetDimLabel COLS, 2, DAC      , wv
	SetDimLabel COLS, 3, ClampMode, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the ITC devices folder "root:mies:HardwareDevices"
Function/DF GetITCDevicesFolder()

	return UpgradeDataFolderLocation(GetMiesPathAsString() + ":ITCDevices", GetITCDevicesFolderAsString())
End

/// @brief Return a data folder reference to the ITC devices folder
threadsafe Function/S GetITCDevicesFolderAsString()

	return GetMiesPathAsString() + ":HardwareDevices"
End

/// @brief Return the active ITC devices timer folder "root:mies:HardwareDevices:ActiveITCDevices:Timer"
Function/DF GetActiveITCDevicesTimerFolder()

	return createDFWithAllParents(GetActiveITCDevicesTimerAS())
End

/// @brief Return a data folder reference to the active ITC devices timer folder
Function/S GetActiveITCDevicesTimerAS()

	return GetActiveITCDevicesFolderAS() + ":Timer"
End

/// @brief Return the active ITC devices folder "root:mies:HardwareDevices:ActiveITCDevices"
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

/// @brief Return the path to the device type folder, e.g. root:mies:HardwareDevices:ITC1600
threadsafe Function/S GetDeviceTypePathAsString(deviceType)
	string deviceType

	return GetITCDevicesFolderAsString() + ":" + deviceType
End

/// @brief Return a datafolder reference to the device folder
threadsafe Function/DF GetDevicePath(panelTitle)
	string panelTitle
	return createDFWithAllParents(GetDevicePathAsString(panelTitle))
End

/// @brief Return the path to the device folder, e.g. root:mies:HardwareDevices:ITC1600:Device0
threadsafe Function/S GetDevicePathAsString(panelTitle)
	string panelTitle

	string deviceType, deviceNumber
	ASSERT_TS(ParseDeviceString(panelTitle, deviceType, deviceNumber), "Invalid/Non-locked paneltitle")

	switch(GetHardwareType(panelTitle))
		case HARDWARE_NI_DAC:
			return GetDeviceTypePathAsString(deviceType)
			break
		case HARDWARE_ITC_DAC:
			return GetDeviceTypePathAsString(deviceType) + ":Device" + deviceNumber
			break
		default:
			ASSERT_TS(0, "Invalid hardware type")
	endswitch
End

/// @brief Return a datafolder reference to the device data folder
Function/DF GetDeviceDataPath(panelTitle)
	string panelTitle
	return createDFWithAllParents(GetDeviceDataPathAsString(panelTitle))
End

/// @brief Return the path to the device folder, e.g. root:mies:HardwareDevices:ITC1600:Device0:Data
Function/S GetDeviceDataPathAsString(panelTitle)
	string panelTitle
	return GetDevicePathAsString(panelTitle) + ":Data"
End

/// @brief Returns a data folder reference to the mies base folder
threadsafe Function/DF GetMiesPath()
	return createDFWithAllParents(GetMiesPathAsString())
End

/// @brief Returns the base folder for all MIES functionality, e.g. root:MIES
threadsafe Function/S GetMiesPathAsString()
	return "root:MIES"
End

/// @brief Returns a data folder reference to the sweep formula folder
threadsafe Function/DF GetSweepFormulaPath()
	return createDFWithAllParents(GetSweepFormulaPathAsString())
End

/// @brief Returns the temporary folder for Sweep formula, e.g. root:MIES:SweepFormula
threadsafe Function/S GetSweepFormulaPathAsString()
	return GetMiesPathAsString() + ":SweepFormula"
End

/// @brief Retuns data folder path to the manipulator folder, e.g. root:mies:manipulators
Function/S GetManipulatorPathAsString()
	return GetMiesPathAsString() + ":Manipulators"
End

/// @brief Return a data folder reference for the Manipulator folder
Function/DF GetManipulatorPath()
	return createDFWithAllParents(GetManipulatorPathAsString())
End

/// @brief Return a datafolder reference to a subfolder below `dfr` for splitted sweep specific data, e.g. dfr:X_5
Function/DF GetSingleSweepFolder(dfr, sweepNo)
	DFREF dfr
	variable sweepNo

	return createDFWithAllParents(GetSingleSweepFolderAsString(dfr, sweepNo))
End

/// @brief Return the path to a subfolder below `dfr` for splitted sweep specific data
Function/S GetSingleSweepFolderAsString(dfr, sweepNo)
	DFREF dfr
	variable sweepNo

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
/// NI hardware:
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
/// @param panelTitle device
/// @param mode       One of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
Function/Wave GetDAQDataWave(string panelTitle, variable mode)

	string name

	DFREF dfr = GetDevicePath(panelTitle)
	variable hardwareType = GetHardwareType(panelTitle)

	switch(mode)
		case DATA_ACQUISITION_MODE:
			name = "DAQDataWave_DAQ"
			break
		case TEST_PULSE_MODE:
			name = "DAQDataWave_TP"
			break
		default:
			ASSERT(0, "Invalid dataAcqOrTP")
	endswitch

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			WAVE/W/Z/SDFR=dfr wv = $name

			if(WaveExists(wv))
				return wv
			endif

			Make/W/N=(1, NUM_DA_TTL_CHANNELS) dfr:$name/Wave=wv
			return wv
			break
		case HARDWARE_NI_DAC:
			WAVE/WAVE/Z/SDFR=dfr wv_ni = $name
			if(WaveExists(wv_ni))
				return wv_ni
			endif
			Make/WAVE/N=(NUM_DA_TTL_CHANNELS) dfr:$name/Wave=wv_ni
			return wv_ni
			break
	endswitch
End

/// @brief Get the single NI channel waves
///
/// Special use function, normal callers should use GetDAQDataWave()
/// instead.
Function/WAVE GetNIDAQChannelWave(panelTitle, channel)
	string panelTitle
	variable channel

	string name

	name = "NI_Channel" + num2str(channel)
	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/Z/SDFR=dfr wv = $name

	if(WaveExists(wv))
		return wv
	endif

	// type does not matter as we change it in DC_MakeNIChannelWave anyway
	Make/N=(0) dfr:$name/WAVE=wv

	return wv
End

static Constant EPOCHS_WAVE_VERSION = 1

/// @brief Return the epochs text wave
///
/// Rows:
/// - epochs
///
/// Column numbers must use global column number constants @sa epochColumnNumber
/// Columns:
///   0 Start time in sec
///   1 End time in sec
///   2 Name
///   3 Tree Level
/// Layers:
/// - NUM_DA_TTL_CHANNELS
///
/// Version 1:
/// - Initial version
Function/Wave GetEpochsWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/T/Z/SDFR=dfr wv = EpochsWave

	if(ExistsWithCorrectLayoutVersion(wv, EPOCHS_WAVE_VERSION))
	   return wv
	elseif(WaveExists(wv))
	   Redimension/N=(MINIMUM_WAVE_SIZE, 4, NUM_DA_TTL_CHANNELS) wv
	else
	  Make/T/N=(MINIMUM_WAVE_SIZE, 4, NUM_DA_TTL_CHANNELS) dfr:EpochsWave/Wave=wv
	endif

	SetDimLabel COLS, EPOCH_COL_STARTTIME, StartTime, wv
	SetDimLabel COLS, EPOCH_COL_ENDTIME, EndTime, wv
	SetDimLabel COLS, EPOCH_COL_NAME, Name, wv
	SetDimLabel COLS, EPOCH_COL_TREELEVEL, TreeLevel, wv

	SetWaveVersion(wv, EPOCHS_WAVE_VERSION)

	return wv
End

/// @brief Return the ITC channel config wave
///
/// Rows:
/// - One for each channel, the order is DA, AD, TTL (same as in the DAQDataWave)
///
/// Columns:
/// - channel type, one of @ref ItcXopChannelConstants
/// - channel number (0-based)
/// - sampling interval in microseconds (1e-6)
/// - decimation mode (always zero)
/// - data offset
///
/// The wave note holds a list of channel units. The order
/// is the same as the rows. TTL channels don't have units. Querying the
/// channel unit should always be done via AFH_GetChannelUnit()/AFH_GetChannelUnits().
///
/// This wave is also used for NI devices as configuration template. There is one difference though:
/// While for ITC devices there is one TTL row for each rack,
/// for NI devices there is one TTL row for each channel (up to 8 currently)
/// The channel number column holds the hardware channel number for the NI device
/// Currently the sampling interval is read from channel 0 only and used for all channels
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
/// Version 2 changes:
/// - DAQChannelType column added
Function/Wave GetITCChanConfigWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/I/Z/SDFR=dfr wv = ITCChanConfigWave

	// On version upgrade also adapt function IsValidConfigWave
	if(ExistsWithCorrectLayoutVersion(wv, ITC_CONFIG_WAVE_VERSION))
		return wv
	elseif(WaveExists(wv))
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
	else
		Make/I/N=(2, 6) dfr:ITCChanConfigWave/Wave=wv
	endif

	SetDimLabel COLS, 0, ChannelType, wv
	SetDimLabel COLS, 1, ChannelNumber, wv
	SetDimLabel COLS, 2, SamplingInterval, wv
	SetDimLabel COLS, 3, DecimationMode, wv
	SetDimLabel COLS, 4, Offset, wv
	SetDimLabel COLS, 5, DAQChannelType, wv

	SetWaveVersion(wv, ITC_CONFIG_WAVE_VERSION)
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
Function/Wave GetDQMActiveDeviceList()

	DFREF dfr = GetActiveITCDevicesFolder()

	WAVE/Z/D/SDFR=dfr wv = ActiveDeviceList

	if(ExistsWithCorrectLayoutVersion(wv, DQM_ACTIVE_DEV_WAVE_VERSION))
		return wv
	elseif(WaveExists(wv))
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
			DeleteWavePoint(wv, COLS, 2)
		endif
	else
		Make/D/N=(0, 4) dfr:ActiveDeviceList/WAVE=wv
	endif

	SetDimLabel COLS, 0, DeviceID,    wv
	SetDimLabel COLS, 1, ADChannelToMonitor, wv
	SetDimLabel COLS, 2, HardwareType, wv
	SetDimLabel COLS, 3, ActiveChunk, wv

	SetWaveVersion(wv, DQM_ACTIVE_DEV_WAVE_VERSION)

	return wv
End

/// @brief Return the intermediate storage wave for the TTL data
Function/Wave GetTTLWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)
	variable hardwareType = GetHardwareType(panelTitle)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			WAVE/W/Z/SDFR=dfr wv = TTLWave

			if(WaveExists(wv))
				return wv
			endif

			Make/W/N=(0) dfr:TTLWave/Wave=wv

			return wv

			break
		case HARDWARE_NI_DAC:
			WAVE/WAVE/Z/SDFR=dfr wv_ni = TTLWave

			if(WaveExists(wv_ni))
				return wv_ni
			endif

			Make/WAVE/N=(NUM_DA_TTL_CHANNELS) dfr:TTLWave/Wave=wv_ni

			return wv_ni

			break
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
Function/Wave GetStimsetAcqIDHelperWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/D/Z/SDFR=dfr wv = stimsetAcqIDHelper

	if(WaveExists(wv))
		return wv
	endif

	Make/D/N=(NUM_DA_TTL_CHANNELS, 2) dfr:stimsetAcqIDHelper/Wave=wv

	SetDimLabel COLS, 0, fingerprint, wv
	SetDimLabel COLS, 1, id         , wv

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

	ASSERT(ParseDeviceString(panelTitle, deviceType, deviceNumber), "Could not parse the panelTitle")

	switch(GetHardwareType(panelTitle))
		case HARDWARE_NI_DAC:
			return GetLabNotebookFolderAsString() + ":" + deviceType
			break
		case HARDWARE_ITC_DAC:
			return GetLabNotebookFolderAsString() + ":" + deviceType + ":Device" + deviceNumber
			break
	endswitch
End

/// @brief Return the datafolder reference to the device specific settings key
/// @deprecated, don't use for new code
Function/DF GetDevSpecLabNBSettKeyFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBSettKeyFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific settings key, e.g. root:mies:LabNoteBook:ITC18USB:Device0:KeyWave
/// @deprecated, don't use for new code
Function/S GetDevSpecLabNBSettKeyFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":KeyWave"
End

/// @brief Return the datafolder reference to the device specific settings history
/// @deprecated, don't use for new code
Function/DF GetDevSpecLabNBSettHistFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBSettHistFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific settings history, e.g. root:mies:LabNoteBook:ITC18USB:Device0:settingsHistory
/// @deprecated, don't use for new code
Function/S GetDevSpecLabNBSettHistFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":settingsHistory"
End

/// @brief Return the datafolder reference to the device specific text doc key
/// @deprecated, don't use for new code
Function/DF GetDevSpecLabNBTxtDocKeyFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBTextDocKeyFoldAS(panelTitle))
End

/// @brief Return the full path to the device specific text doc key, e.g. root:mies:LabNoteBook:ITC18USB:Device0:textDocKeyWave
/// @deprecated, don't use for new code
Function/S GetDevSpecLabNBTextDocKeyFoldAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":TextDocKeyWave"
End

/// @brief Return the datafolder reference to the device specific text documentation
/// @deprecated, don't use for new code
Function/DF GetDevSpecLabNBTextDocFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBTextDocFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific text documentation, e.g. root:mies:LabNoteBook:ITC18USB:Device0:textDocumentation
/// @deprecated, don't use for new code
Function/S GetDevSpecLabNBTextDocFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":textDocumentation"
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
Function/Wave GetLBTextualValues(panelTitle)
	string panelTitle

	string newName = "textualValues"
	DFREF newDFR = GetDevSpecLabNBFolder(panelTitle)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(panelTitle) + ":textDocumentation")
	p.newDFR  = newDFR
	p.name    = "txtDocWave"
	p.newName = newName

	Wave/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(MINIMUM_WAVE_SIZE, INITIAL_KEY_WAVE_COL_COUNT, LABNOTEBOOK_LAYER_COUNT) newDFR:$newName/Wave=wv
	wv = ""

	SetDimLabel COLS, 0, SweepNum                  , wv
	SetDimLabel COLS, 1, TimeStamp                 , wv
	SetDimLabel COLS, 2, TimeStampSinceIgorEpochUTC, wv
	SetDimLabel COLS, 3, EntrySourceType           , wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	SetNumberInWaveNote(wv, LABNOTEBOOK_ROLLBACK_COUNT, 0)

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
static Function UpgradeLabNotebook(panelTitle)
	string panelTitle

	variable numCols, i, col, numEntries, sourceCol
	string list, key

	WAVE  numericalValues = GetLBNumericalValues(panelTitle)
	WAVE/T textualValues  = GetLBTextualValues(panelTitle)

	// we only have to check the new place and name as we are called
	// later than UpgradeWaveLocationAndGetIt from both key wave getters
	//
	// avoid recursion by checking the wave location first
	Wave/Z/T/SDFR=GetDevSpecLabNBFolder(panelTitle) numericalKeys
	Wave/Z/T/SDFR=GetDevSpecLabNBFolder(panelTitle) textualKeys

	if(!WaveExists(numericalKeys))
		WAVE/T numericalKeys = GetLBNumericalKeys(panelTitle)
	endif

	if(!WaveExists(textualKeys))
		WAVE/T textualKeys = GetLBTextualKeys(panelTitle)
	endif

	ASSERT(DimSize(numericalKeys, COLS) == DimSize(numericalValues, COLS), "Non matching number of rows for numeric labnotebook")
	ASSERT(DimSize(textualKeys, COLS) == DimSize(textualValues, COLS), "Non matching number of rows for textual labnotebook")

	// BEGIN UTC timestamps
	if(cmpstr(numericalKeys[0][2], "TimeStampSinceIgorEpochUTC"))

		numCols = DimSize(numericalKeys, COLS)

		Redimension/N=(-1, numCols + 1, -1) numericalKeys, numericalValues

		numericalKeys[][numCols]           = numericalKeys[p][2]
		numericalValues[][numCols][] = numericalValues[p][2][r]

		numericalValues[][2][] = NaN
		numericalKeys[][2]           = ""
		numericalKeys[0][2]          = "TimeStampSinceIgorEpochUTC"
		SetDimensionLabels(numericalKeys, numericalValues)

		DEBUGPRINT("Upgraded numerical labnotebook to hold UTC timestamps")
	endif

	if(cmpstr(textualKeys[0][2], "TimeStampSinceIgorEpochUTC"))

		numCols = DimSize(textualKeys, COLS)

		Redimension/N=(-1, numCols + 1, -1) textualKeys, textualValues

		textualKeys[][numCols]   = textualKeys[p][2]
		textualValues[][numCols][] = textualValues[p][2][r]

		textualValues[][2][]   = ""
		textualKeys[][2]  = ""
		textualKeys[0][2] = "TimeStampSinceIgorEpochUTC"
		SetDimensionLabels(textualKeys, textualValues)

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
		SetDimensionLabels(numericalKeys, numericalValues)

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
		SetDimensionLabels(textualKeys, textualValues)

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
		WAVE/T sweepKeyWave = GetSweepSettingsKeyWave(panelTitle)
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
		SetDimensionLabels(numericalKeys, numericalValues)
		SetDimensionLabels(textualKeys, textualValues)
	endif

	if(WaveVersionIsSmaller(numericalKeys, 39))
		SetNumberInWaveNote(numericalValues, LABNOTEBOOK_ROLLBACK_COUNT, 0)
		SetNumberInWaveNote(textualValues, LABNOTEBOOK_ROLLBACK_COUNT, 0)
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
/// - other columns are filled at runtime
Function/Wave GetLBTextualKeys(panelTitle)
	string panelTitle

	variable versionOfNewWave = LABNOTEBOOK_VERSION
	string newName = "textualKeys"
	DFREF newDFR = GetDevSpecLabNBFolder(panelTitle)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(panelTitle) + ":TextDocKeyWave")
	p.newDFR  = newDFR
	p.name    = "txtDocKeyWave"
	p.newName = newName

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		UpgradeLabNotebook(panelTitle)
		SetWaveVersion(wv, versionOfNewWave)
		return wv
	else
		Make/T/N=(3, INITIAL_KEY_WAVE_COL_COUNT) newDFR:$newName/Wave=wv
	endif

	wv = ""

	wv[0][0] = "SweepNum"
	wv[0][1] = "TimeStamp"
	wv[0][2] = "TimeStampSinceIgorEpochUTC"
	wv[0][3] = "EntrySourceType"

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units,     wv
	SetDimLabel ROWS, 2, Tolerance, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the numeric labnotebook keys
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
/// - other columns are filled at runtime
Function/Wave GetLBNumericalKeys(panelTitle)
	string panelTitle

	variable versionOfNewWave = LABNOTEBOOK_VERSION
	/// @todo move the renaming stuff into one function for all four labnotebook waves
	string newName = "numericalKeys"
	DFREF newDFR = GetDevSpecLabNBFolder(panelTitle)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(panelTitle) + ":KeyWave")
	p.newDFR  = newDFR
	p.name    = "keyWave"
	p.newName = newName

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		UpgradeLabNotebook(panelTitle)
		SetWaveVersion(wv, versionOfNewWave)
		return wv
	else
		Make/T/N=(3, INITIAL_KEY_WAVE_COL_COUNT) newDFR:$newName/Wave=wv
	endif

	wv = ""

	wv[0][0] = "SweepNum"
	wv[0][1] = "TimeStamp"
	wv[0][2] = "TimeStampSinceIgorEpochUTC"
	wv[0][3] = "EntrySourceType"

	SetDimLabel ROWS, 0, Parameter, wv
	SetDimLabel ROWS, 1, Units,     wv
	SetDimLabel ROWS, 2, Tolerance, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
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
Function/Wave GetLBNumericalValues(panelTitle)
	string panelTitle

	string newName = "numericalValues"
	DFREF newDFR = GetDevSpecLabNBFolder(panelTitle)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(panelTitle) + ":settingsHistory")
	p.newDFR  = newDFR
	p.name    = "settingsHistory"
	p.newName = newName

	WAVE/D/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(!WaveExists(wv))
		Make/D/N=(MINIMUM_WAVE_SIZE, INITIAL_KEY_WAVE_COL_COUNT, LABNOTEBOOK_LAYER_COUNT) newDFR:$newName/Wave=wv = NaN

		SetDimLabel COLS, 0, SweepNum                  , wv
		SetDimLabel COLS, 1, TimeStamp                 , wv
		SetDimLabel COLS, 2, TimeStampSinceIgorEpochUTC, wv
		SetDimLabel COLS, 3, EntrySourceType           , wv

		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
		SetNumberInWaveNote(wv, LABNOTEBOOK_ROLLBACK_COUNT, 0)
	endif

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
/// Cols:
/// - 0: First row
/// - 1: Last row
///
/// Layers:
/// - One for each entrySourceType, mapped via EntrySourceTypeMapper()
Function/WAVE GetLBRowCache(values)
	WAVE values

	variable actual, rollbackCount, sweepNo, first, last
	string key, name

	variable versionOfNewWave = 4

	actual        = WaveModCountWrapper(values)
	name          = GetWavesDataFolder(values, 2)
	rollbackCount = GetNumberFromWaveNote(values, LABNOTEBOOK_ROLLBACK_COUNT)
	ASSERT(!isEmpty(name), "Invalid path to wave, free waves won't work.")

	key = name + "_RowCache"

	WAVE/Z/D wv = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		if(actual == GetNumberFromWaveNote(wv, LABNOTEBOOK_MOD_COUNT))
			return wv
		elseif(rollbackCount == GetNumberFromWaveNote(wv, LABNOTEBOOK_ROLLBACK_COUNT))
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
				EnsureLargeEnoughWave(wv, minimumSize = sweepNo, dimension = ROWS, initialValue = LABNOTEBOOK_GET_RANGE)
				first = limit(sweepNo - 1, 0, inf)
				last = sweepNo
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
	SetDimLabel COLS, 1, last,  wv

	SetNumberInWaveNote(wv, LABNOTEBOOK_MOD_COUNT, actual)
	SetNumberInWaveNote(wv, LABNOTEBOOK_ROLLBACK_COUNT, rollbackCount)
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Index wave which serves as a labnotebook cache.
///
/// Rows:
/// - Sweep numbers
///
/// Cols:
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
Function/WAVE GetLBIndexCache(values)
	WAVE values

	variable actual, rollbackCount, sweepNo, first, last
	string key, name

	variable versionOfNewWave = 4

	actual        = WaveModCountWrapper(values)
	name          = GetWavesDataFolder(values, 2)
	rollbackCount = GetNumberFromWaveNote(values, LABNOTEBOOK_ROLLBACK_COUNT)
	ASSERT(!isEmpty(name), "Invalid path to wave, free waves won't work.")

	key = name + "_IndexCache"

	WAVE/Z/D wv = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		if(actual == GetNumberFromWaveNote(wv, LABNOTEBOOK_MOD_COUNT))
			return wv
		elseif(rollbackCount == GetNumberFromWaveNote(wv, LABNOTEBOOK_ROLLBACK_COUNT))
			// new entries were added so we need to propagate all entries to uncached values
			// for sweep numbers >= than the currently acquired sweep

			if(IsNumericWave(values))
				WAVE/Z sweeps = GetLastSweepWithSetting(values, "SweepNum", sweepNo)
			elseif(IsTextWave(values))
				WAVE/Z sweeps = GetLastSweepWithSettingText(values, "SweepNum", sweepNo)
			endif

			if(IsFinite(sweepNo))
				EnsureLargeEnoughWave(wv, minimumSize = sweepNo, dimension = ROWS, initialValue = LABNOTEBOOK_UNCACHED_VALUE)
				first = limit(sweepNo - 1, 0, inf)
				last = sweepNo
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
	SetNumberInWaveNote(wv, LABNOTEBOOK_ROLLBACK_COUNT, rollbackCount)
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
/// Cols:
/// - RAC (repeated acquisition cycle IDs) sweeps
/// - SCI (simset cycle IDs) sweeps
///
Function/WAVE GetLBNidCache(numericalValues)
	WAVE numericalValues

	variable actual, rollbackCount
	string key, name

	variable versionOfNewWave = 3

	ASSERT(!IsTextWave(numericalValues), "Expected numerical labnotebook")

	actual        = WaveModCountWrapper(numericalValues)
	name          = GetWavesDataFolder(numericalValues, 2)
	rollbackCount = GetNumberFromWaveNote(numericalValues, LABNOTEBOOK_ROLLBACK_COUNT)
	ASSERT(!isEmpty(name), "Invalid path to wave, free waves won't work.")

	key = name + "_RACidCache"

	WAVE/Z/WAVE wv = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		if(actual == GetNumberFromWaveNote(wv, LABNOTEBOOK_MOD_COUNT))
			return wv
		else
			// we can't easily do an incremental update as we would need to
			// update all RAC/SCI cycles which got changed by the new data
			// and that is not so easy
		endif
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/FREE/N=(MINIMUM_WAVE_SIZE, 2, NUM_HEADSTAGES)/WAVE wv
		CA_StoreEntryIntoCache(key, wv, options = CA_OPTS_NO_DUPLICATE)
	endif

	wv = $""

	SetNumberInWaveNote(wv, LABNOTEBOOK_MOD_COUNT, actual)
	SetNumberInWaveNote(wv, LABNOTEBOOK_ROLLBACK_COUNT, rollbackCount)
	SetWaveVersion(wv, versionOfNewWave)

	SetDimLabel COLS, 0, $RA_ACQ_CYCLE_ID_KEY     , wv
	SetDimLabel COLS, 1, $STIMSET_ACQ_CYCLE_ID_KEY, wv

	return wv
End

static Constant SWEEP_SETTINGS_WAVE_VERSION = 26

/// @brief Uses the parameter names from the `sourceKey` columns and
///        write them as dimension into the columns of dest.
static Function SetSweepSettingsDimLabels(dest, sourceKey)
	WAVE dest
	WAVE/T sourceKey

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
Function/Wave GetSweepSettingsWave(panelTitle)
	string panelTitle

	variable numCols

	variable versionOfNewWave = SWEEP_SETTINGS_WAVE_VERSION
	string newName = "sweepSettingsNumericValues"
	DFREF newDFR = GetDevSpecLabNBTempFolder(panelTitle)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(panelTitle) + ":settingsHistory")
	p.newDFR  = newDFR
	p.name    = "sweepSettingsWave"
	p.newName = newName

	WAVE/D/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, SWEEP_SETTINGS_WAVE_VERSION))
		return wv
	endif

	WAVE/T keyWave = GetSweepSettingsKeyWave(panelTitle)
	numCols = DimSize(keyWave, COLS)

	if(WaveExists(wv))
		Redimension/D/N=(-1, numCols, LABNOTEBOOK_LAYER_COUNT) wv
	else
		Make/D/N=(1, numCols, LABNOTEBOOK_LAYER_COUNT) newDFR:$newName/Wave=wv
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
/// - 23: Sampling interval
/// - 24: Sampling interval multiplier
/// - 25: Stim set length
/// - 26: oodDAQ Pre Feature
/// - 27: oodDAQ Post Feature
/// - 28: oodDAQ Resolution
/// - 29: Optimized Overlap dDAQ
/// - 30: Delay onset oodDAQ
/// - 31: Repeated Acquisition Cycle ID
/// - 32: Stim Wave Checksum (can be used to disambiguate cases
///                           where two stimsets are named the same
///                           but have different contents)
/// - 33: Multi Device mode
/// - 34: Background Testpulse
/// - 35: Background DAQ
/// - 36: Sampling interval multiplier
/// - 37: TP buffer size
/// - 38: TP during ITI
/// - 39: Amplifier change via I=0
/// - 40: Skip analysis functions
/// - 41: Repeat sweep on async alarm
/// - 42: Set Cycle Count
/// - 43: Stimset cycle ID
/// - 44: Digitizer Hardware Type, one of @ref HardwareDACTypeConstants
/// - 45: Fixed frequency acquisition
/// - 46: Headstage Active
/// - 47: Clamp Mode
/// - 48: Igor Pro bitness
/// - 49: DA ChannelType, one of @ref DaqChannelTypeConstants
/// - 50: AD ChannelType, one of @ref DaqChannelTypeConstants
/// - 51: oodDAQ member, true if headstage takes part in oodDAQ mode, false otherwise
Function/Wave GetSweepSettingsKeyWave(panelTitle)
	string panelTitle

	variable versionOfNewWave = SWEEP_SETTINGS_WAVE_VERSION
	string newName = "sweepSettingsNumericKeys"
	DFREF newDFR = GetDevSpecLabNBTempFolder(panelTitle)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(panelTitle) + ":KeyWave")
	p.newDFR  = newDFR
	p.name    = "sweepSettingsKeyWave"
	p.newName = newName

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 52) wv
	else
		Make/T/N=(3, 52) newDFR:$newName/Wave=wv
	endif

	wv = ""

	SetDimLabel 0, 0, Parameter, wv
	SetDimLabel 0, 1, Units, wv
	SetDimLabel 0, 2, Tolerance, wv

	wv[%Parameter][0] = STIMSET_SCALE_FACTOR_KEY
	wv[%Units][0]     = ""
	wv[%Tolerance][0] = ".0001"

	wv[%Parameter][1] = "DAC"
	wv[%Units][1]     = "a. u."
	wv[%Tolerance][1] = "1"

	wv[%Parameter][2] = "ADC"
	wv[%Units][2]     = "a. u."
	wv[%Tolerance][2] = "1"

	wv[%Parameter][3] = "DA Gain"
	wv[%Units][3]     = ""
	wv[%Tolerance][3] = ".000001"

	wv[%Parameter][4] = "AD Gain"
	wv[%Units][4]     = ""
	wv[%Tolerance][4] = ".000001"

	wv[%Parameter][5] = "Set Sweep Count"
	wv[%Units][5]     = "a. u."
	wv[%Tolerance][5] = "1"

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
	wv[%Units][10]     = "a. u."
	wv[%Tolerance][10] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][11] = "TTL rack one channel"
	wv[%Units][11]     = "a. u."
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
	wv[%Units][17]     = "a. u."
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

	wv[%Parameter][23] = "Sampling interval"
	wv[%Units][23]     = "ms"
	wv[%Tolerance][23] = "1"

	wv[%Parameter][24] = "Sampling interval multiplier"
	wv[%Units][24]     = "a. u."
	wv[%Tolerance][24] = "0.1"

	wv[%Parameter][25] = "Stim set length"
	wv[%Units][25]     = "a. u." // points not time
	wv[%Tolerance][25] = "1"

	wv[%Parameter][26] = "oodDAQ Pre Feature"
	wv[%Units][26]     = "ms"
	wv[%Tolerance][26] = "1"

	wv[%Parameter][27] = "oodDAQ Post Feature"
	wv[%Units][27]     = "ms"
	wv[%Tolerance][27] = "1"

	wv[%Parameter][28] = "oodDAQ Resolution"
	wv[%Units][28]     = "ms"
	wv[%Tolerance][28] = "1"

	wv[%Parameter][29] = "Optimized Overlap dDAQ"
	wv[%Units][29]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][29] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][30] = "Delay onset oodDAQ"
	wv[%Units][30]     = "ms"
	wv[%Tolerance][30] = "1"

	wv[%Parameter][31] = RA_ACQ_CYCLE_ID_KEY
	wv[%Units][31]     = "a. u."
	wv[%Tolerance][31] = "1"

	wv[%Parameter][32] = "Stim Wave Checksum"
	wv[%Units][32]     = "a. u."
	wv[%Tolerance][32] = "1"

	wv[%Parameter][33] = "Multi Device mode"
	wv[%Units][33]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][33] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][34] = "Background Testpulse"
	wv[%Units][34]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][34] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][35] = "Background DAQ"
	wv[%Units][35]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][35] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][36] = "Sampling interval multiplier"
	wv[%Units][36]     = "a. u."
	wv[%Tolerance][36] = "1"

	wv[%Parameter][37] = "TP buffer size"
	wv[%Units][37]     = "a. u."
	wv[%Tolerance][37] = "1"

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
	wv[%Units][42]     = "a. u."
	wv[%Tolerance][42] = "1"

	wv[%Parameter][43] = STIMSET_ACQ_CYCLE_ID_KEY
	wv[%Units][43]     = "a. u."
	wv[%Tolerance][43] = "1"

	wv[%Parameter][44] = "Digitizer Hardware Type"
	wv[%Units][44]     = "a. u."
	wv[%Tolerance][44] = "1"

	wv[%Parameter][45] = "Fixed frequency acquisition"
	wv[%Units][45]     = "kHz"
	wv[%Tolerance][45] = "1"

	wv[%Parameter][46] = "Headstage Active"
	wv[%Units][46]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][46] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][47] = "Clamp Mode"
	wv[%Units][47]     = "a. u."
	wv[%Tolerance][47] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][48] = "Igor Pro bitness"
	wv[%Units][48]     = "a. u."
	wv[%Tolerance][48] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][49] = "DA ChannelType"
	wv[%Units][49]     = "a. u."
	wv[%Tolerance][49] = "1"

	wv[%Parameter][50] = "AD ChannelType"
	wv[%Units][50]     = "a. u."
	wv[%Tolerance][50] = "1"

	wv[%Parameter][51] = "oodDAQ member"
	wv[%Units][51]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][51] = LABNOTEBOOK_NO_TOLERANCE

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
Function/Wave GetSweepSettingsTextWave(panelTitle)
	string panelTitle

	variable numCols

	variable versionOfNewWave = SWEEP_SETTINGS_WAVE_VERSION
	string newName = "sweepSettingsTextValues"
	DFREF newDFR = GetDevSpecLabNBTempFolder(panelTitle)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(panelTitle) + ":textDocumentation")
	p.newDFR  = newDFR
	p.name    = "SweepSettingsTxtData"
	p.newName = newName

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	endif

	WAVE/T keyWave = GetSweepSettingsTextKeyWave(panelTitle)
	numCols = DimSize(keyWave, COLS)

	if(WaveExists(wv))
		Redimension/N=(-1, numCols, LABNOTEBOOK_LAYER_COUNT) wv
	else
		Make/T/N=(1, numCols, LABNOTEBOOK_LAYER_COUNT) newDFR:$newName/Wave=wv
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
/// - 0: Stim set
/// - 1: DA unit
/// - 2: AD unit
/// - 3: TTL rack zero stim sets (ITC hardware), string list in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// - 4: TTL rack one stim sets (ITC hardware), same for the second rack
/// - 5: Analysis function pre daq
/// - 6: Analysis function mid sweep
/// - 7: Analysis function post sweep
/// - 8: Analysis function post set
/// - 9: Analysis function post daq
/// -10: Analysis function pre sweep
/// -11: Analysis function generic
/// -12: Analysis function pre set
/// -13: Analysis function parameters
/// -14: oodDAQ regions list
///      - Format: `$begin1-$end1;$begin2-$end2;...`.
///      - Unit: `stimset build ms`.
/// -15: Electrode
/// -16: High precision sweep start timestamp in ISO8601 format
/// -17: Stimset wave note
/// -18: TTL rack zero set sweep counts (ITC hardware)
/// -19: TTL rack one set sweep counts (ITC hardware)
/// -20: TTL set sweep counts (NI hardware), string list in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// -21: TTL stim sets (NI hardware), string list in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// -22: TTL channels (NI hardware), string list  in `INDEP_HEADSTAGE` layer with empty entries indexed by [0, NUM_DA_TTL_CHANNELS[
/// -23: Follower Device, list of follower devices
/// -24: MIES version, multi line mies version string
/// -25: Igor Pro version
/// -26: Digitizer Hardware Name
/// -27: Digitizer Serial Numbers
/// -28: Epochs
/// -29: JSON config file: path (`|` separated list of full file paths)
/// -30: JSON config file: SHA-256 hash (`|` separated list of hashes)
/// -31: JSON config file: stimset nwb file path
Function/Wave GetSweepSettingsTextKeyWave(panelTitle)
	string panelTitle

	variable versionOfNewWave = SWEEP_SETTINGS_WAVE_VERSION
	string newName = "sweepSettingsTextKeys"
	DFREF newDFR = GetDevSpecLabNBTempFolder(panelTitle)

	STRUCT WaveLocationMod p
	p.dfr     = $(GetDevSpecLabNBFolderAsString(panelTitle) + ":textDocKeyWave")
	p.newDFR  = newDFR
	p.name    = "SweepSettingsKeyTxtData"
	p.newName = newName

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 32, 0) wv
	else
		Make/T/N=(1, 32) newDFR:$newName/Wave=wv
	endif

	SetDimLabel ROWS, 0, Parameter, wv

	wv = ""

	wv[0][0]  = STIM_WAVE_NAME_KEY
	wv[0][1]  = "DA unit"
	wv[0][2]  = "AD unit"
	wv[0][3]  = "TTL rack zero stim sets"
	wv[0][4]  = "TTL rack one stim sets"
	wv[0][5]  = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][6]  = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][7]  = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][8]  = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][9]  = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][10] = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][11] = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][12] = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	wv[0][13] = ANALYSIS_FUNCTION_PARAMS_LBN
	wv[0][14] = "oodDAQ regions"
	wv[0][15] = "Electrode"
	wv[0][16] = HIGH_PREC_SWEEP_START_KEY
	wv[0][17] = STIMSET_WAVE_NOTE_KEY
	wv[0][18] = "TTL rack zero set sweep counts"
	wv[0][19] = "TTL rack one set sweep counts"
	wv[0][20] = "TTL set sweep counts"
	wv[0][21] = "TTL stim sets"
	wv[0][22] = "TTL channels"
	wv[0][23] = "Follower Device"
	wv[0][24] = "MIES version"
	wv[0][25] = "Igor Pro version"
	wv[0][26] = "Digitizer Hardware Name"
	wv[0][27] = "Digitizer Serial Numbers"
	wv[0][28] = EPOCHS_ENTRY_KEY
	wv[0][29] = "JSON config file: path"
	wv[0][30] = "JSON config file: SHA-256 hash"
	wv[0][31] = "JSON config file: stimset nwb file path"

	SetSweepSettingsDimLabels(wv, wv)
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End
/// @}

/// @name Test Pulse
/// @{

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
/// -  4: Time in s (arbitrary zero)
/// -  5: Delta time in s relative to the entry in the first row of layer 3
/// -  6: (Steady State) Resistance slope
/// -  7: Pressure in psi
/// -  8: Timestamp since igor epoch (*with* timezone offsets)
/// -  9: Timestamp in UTC since igor epoch
/// - 10: Pressure changed
/// - 11: Holding current (pA, Voltage Clamp)
/// - 12: Vrest (mV, Current Clamp)
/// - 13: AD channel
/// - 14: DA channel
/// - 15: Headstage
/// - 16: ClampMode
/// - 17: UserPressure
/// - 18: PressureMethod (see @ref PressureModeConstants)
/// - 19: ValidState (true if the entry is considered valid, false otherwise)
/// - 20: UserPressureType (see @ref PressureTypeConstants)
/// - 21: UserPressureTimeStampUTC timestamp since Igor Pro epoch in UTC where
///       the user pressure was acquired
/// - 22: TPMarker unique number identifying this set of TPs
Function/Wave GetTPStorage(panelTitle)
	string 	panelTitle

	dfref dfr = GetDeviceTestPulse(panelTitle)
	variable versionOfNewWave = 12

	WAVE/Z/SDFR=dfr/D wv = TPStorage

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, NUM_HEADSTAGES, 23)/D wv

		if(WaveVersionIsSmaller(wv, 10))
			wv[][][17]    = NaN
			wv[][][20,21] = NaN
		endif
		if(WaveVersionIsSmaller(wv, 11))
			wv[][][22]    = NaN
		endif
	else
		Make/N=(MINIMUM_WAVE_SIZE_LARGE, NUM_HEADSTAGES, 23)/D dfr:TPStorage/Wave=wv

		wv = NaN

		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	endif

	SetDimLabel COLS,  -1,  Headstage                 , wv

	SetDimLabel LAYERS,  0, HoldingCmd_VC             , wv
	SetDimLabel LAYERS,  1, HoldingCmd_IC             , wv
	SetDimLabel LAYERS,  2, PeakResistance            , wv
	SetDimLabel LAYERS,  3, SteadyStateResistance     , wv
	SetDimLabel LAYERS,  4, TimeInSeconds             , wv
	SetDimLabel LAYERS,  5, DeltaTimeInSeconds        , wv
	SetDimLabel LAYERS,  6, Rss_Slope                 , wv
	SetDimLabel LAYERS,  7, Pressure                  , wv
	SetDimLabel LAYERS,  8, TimeStamp                 , wv
	SetDimLabel LAYERS,  9, TimeStampSinceIgorEpochUTC, wv
	SetDimLabel LAYERS, 10, PressureChange            , wv
	SetDimLabel LAYERS, 11, Baseline_VC               , wv
	SetDimLabel LAYERS, 12, Baseline_IC               , wv
	SetDimLabel LAYERS, 13, ADC                       , wv
	SetDimLabel LAYERS, 14, DAC                       , wv
	SetDimLabel LAYERS, 15, Headstage                 , wv
	SetDimLabel LAYERS, 16, ClampMode                 , wv
	SetDimLabel LAYERS, 17, UserPressure              , wv
	SetDimLabel LAYERS, 18, PressureMethod            , wv
	SetDimLabel LAYERS, 19, ValidState                , wv
	SetDimLabel LAYERS, 20, UserPressureType          , wv
	SetDimLabel LAYERS, 21, UserPressureTimeStampUTC  , wv
	SetDimLabel LAYERS, 22, TPMarker                  , wv

	SetNumberInWaveNote(wv, AUTOBIAS_LAST_INVOCATION_KEY, 0)
	SetNumberInWaveNote(wv, DIMENSION_SCALING_LAST_INVOC, 0)
	SetNumberInWaveNote(wv, PRESSURE_CTRL_LAST_INVOC, 0)
	SetNumberInWaveNote(wv, INDEX_ON_TP_START, 0)

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a free wave reference for AcqTPStorage wave for passing to ACQ4
///
/// The wave stores PeakResistance, SteadyStateResistance, and TimeStamp in rows and headstages in cols
Function/Wave GetAcqTPStorage()

	Make/FREE/D/N=(3, NUM_HEADSTAGES, HARDWARE_MAX_DEVICES) wv

	SetDimLabel COLS, -1, HeadStage            , wv
	SetDimLabel ROWS, 0 , TimeStamp            , wv
	SetDimLabel ROWS, 1 , SteadyStateResistance, wv
	SetDimLabel ROWS, 2 , PeakResistance       , wv

	return wv
End

/// @brief Return a datafolder reference to the test pulse folder
Function/DF GetDeviceTestPulse(panelTitle)
	string panelTitle
	return createDFWithAllParents(GetDeviceTestPulseAsString(panelTitle))
End

/// @brief Return the path to the test pulse folder, e.g. root:mies:HardwareDevices:ITC1600:Device0:TestPulse
Function/S GetDeviceTestPulseAsString(panelTitle)
	string panelTitle
	return GetDevicePathAsString(panelTitle) + ":TestPulse"
End

/// @brief Return a wave which holds undecimated and scaled data
///
/// Rows:
/// - StopCollectionPoint
///
/// Cols:
/// - Number of active channels
///
/// Type:
/// - FP32 or FP64, as returned by SWS_GetRawDataFPType()
Function/Wave GetScaledDataWave(panelTitle)
	string panelTitle

	dfref dfr = GetDevicePath(panelTitle)
	WAVE/Z/SDFR=dfr wv = ScaledData

	if(WaveExists(wv))
		return wv
	endif

	Make/Y=(SWS_GetRawDataFPType(panelTitle))/N=(1, NUM_DA_TTL_CHANNELS) dfr:ScaledData/Wave=wv

	return wv
End

/// @brief Return a wave for displaying scaled data in the oscilloscope window
///
/// Contents can be decimated for faster display.
Function/Wave GetOscilloscopeWave(panelTitle)
	string panelTitle

	dfref dfr = GetDevicePath(panelTitle)
	WAVE/Z/SDFR=dfr wv = OscilloscopeData

	if(WaveExists(wv))
		return wv
	endif

	Make/R/N=(1, NUM_DA_TTL_CHANNELS) dfr:OscilloscopeData/Wave=wv

	return wv
End

/// @brief Return a wave for displaying scaled TP data in the oscilloscope window
///        for the "TP during DAQ" channels or for TP power spectrum during Test Pulse
///
/// Rows:
/// - Holds exactly one TP
///
/// Cols:
/// - DA/AD/TTLs data, same order as GetDAQDataWave()
Function/Wave GetTPOscilloscopeWave(panelTitle)
	string panelTitle

	dfref dfr = GetDevicePath(panelTitle)
	WAVE/Z/SDFR=dfr wv = TPOscilloscopeData

	if(WaveExists(wv))
		return wv
	endif

	Make/R/N=(0, NUM_DA_TTL_CHANNELS) dfr:TPOscilloscopeData/Wave=wv

	return wv
End

/// @brief Return a wave reference wave for storing the *full* test pulses
Function/WAVE GetStoredTestPulseWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDeviceTestPulse(panelTitle)
	WAVE/WAVE/Z/SDFR=dfr wv = StoredTestPulses

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/WAVE dfr:StoredTestPulses/Wave=wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the testpulse instantenous resistance wave
///
/// The rows have NUM_HEADSTAGES size and are initialized with NaN
///
/// Version 1:
/// - stores number of headstages entrys, NaN when headstage not active
/// Version 2:
/// - upgraded precision to double
///
/// Unit: MOhm (1e6 Ohm)
Function/Wave GetInstResistanceWave(panelTitle)
	string 	panelTitle

	variable version = 2

	DFREF dfr = GetDeviceTestPulse(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = InstResistance

	if(ExistsWithCorrectLayoutVersion(wv, version))

		return wv

	elseif(WaveExists(wv))
		// Unversioned wave stored only active headstages
		Redimension/D/N=(NUM_HEADSTAGES) wv
		wv = NaN

	else

		Make/D/N=(NUM_HEADSTAGES) dfr:InstResistance/Wave=wv
		wv = NaN

	endif

	SetWaveVersion(wv, version)

	return wv
End

/// @brief Return the testpulse steady state average
///
/// The rows have NUM_HEADSTAGES size and are initialized with NaN
///
/// Version 1:
/// - stores number of headstages entrys, NaN when headstage not active
/// Version 2:
/// - upgraded precision to double
///
/// Unit: mV (1e-3 Volt) for IC, pA (1e-12 Amps) for VC
Function/Wave GetBaselineAverage(panelTitle)
	string 	panelTitle

	variable version = 2

	DFREF dfr = GetDeviceTestPulse(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = BaselineSSAvg

	if(ExistsWithCorrectLayoutVersion(wv, version))

		return wv

	elseif(WaveExists(wv))
		// Unversioned wave stored only active headstages
		Redimension/D/N=(NUM_HEADSTAGES) wv
		wv = NaN

	else

		Make/D/N=(NUM_HEADSTAGES) dfr:BaselineSSAvg/Wave=wv
		wv = NaN

	endif

	SetWaveVersion(wv, version)

	return wv
End

/// @brief Return the testpulse steady state resistance wave
///
/// The rows have NUM_HEADSTAGES size and are initialized with NaN
///
/// Version 1:
/// - stores number of headstages entrys, NaN when headstage not active
/// Version 2:
/// - upgraded precision to double
///
/// Unit: MOhm (1e6 Ohm)
Function/Wave GetSSResistanceWave(panelTitle)
	string 	panelTitle

	variable version = 2

	DFREF dfr = GetDeviceTestPulse(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = SSResistance

	if(ExistsWithCorrectLayoutVersion(wv, version))

		return wv

	elseif(WaveExists(wv))
		// Unversioned wave stored only active headstages
		Redimension/D/N=(NUM_HEADSTAGES) wv
		wv = NaN

	else

		Make/D/N=(NUM_HEADSTAGES) dfr:SSResistance/Wave=wv
		wv = NaN

	endif

	SetWaveVersion(wv, version)

	return wv
End

/// @brief Return the testpulse baseline running box average buffer
///
/// The columns hold the *active* AD channels only and are subject to resizing.
/// Currently the initialization and resize is done in TP_CreateTPAvgBuffer()
///
/// @todo change columns to hold entries for each headstage, num_cols = NUM_HEADSTAGES
///
/// Version 1:
/// - upgraded precision to double
///
/// Unit: Unit: mV (1e-3 Volt) for IC, pA (1e-12 Amps) for VC
Function/Wave GetGetBaselineBuffer(panelTitle)
	string 	panelTitle

	variable version = 1

	dfref dfr = GetDeviceTestPulse(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = TPBaselineBuffer

	if(ExistsWithCorrectLayoutVersion(wv, version))

		return wv

	elseif(WaveExists(wv))

		Redimension/D/N=(-1, -1) wv

	else

		Make/D/N=(0, 0) dfr:TPBaselineBuffer/Wave=wv

	endif

	SetWaveVersion(wv, version)

	return wv
End

/// @brief Return the testpulse instantaneous resistance running box average buffer
///
/// The columns hold the *active* AD channels only and are subject to resizing.
/// Currently the initialization and resize is done in TP_CreateTPAvgBuffer()
///
/// @todo change columns to hold entries for each headstage, num_cols = NUM_HEADSTAGES
///
/// Version 1:
/// - upgraded precision to double
///
/// Unit: MOhm (1e6 Ohm)
Function/Wave GetInstantaneousBuffer(panelTitle)
	string 	panelTitle

	variable version = 1

	dfref dfr = GetDeviceTestPulse(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = TPInstBuffer

	if(ExistsWithCorrectLayoutVersion(wv, version))

		return wv

	elseif(WaveExists(wv))

		Redimension/D/N=(-1, -1) wv

	else

		Make/D/N=(0, 0) dfr:TPInstBuffer/Wave=wv

	endif

	SetWaveVersion(wv, version)

	return wv
End

/// @brief Return the testpulse steady state resistance running box average buffer
///
/// The columns hold the *active* AD channels only and are subject to resizing.
/// Currently the initialization and resize is done in TP_CreateTPAvgBuffer()
///
/// @todo change columns to hold entries for each headstage, num_cols = NUM_HEADSTAGES
///
/// Version 1:
/// - upgraded precision to double
///
/// Unit: MOhm (1e6 Ohm)
Function/Wave GetSteadyStateBuffer(panelTitle)
	string 	panelTitle

	variable version = 1

	dfref dfr = GetDeviceTestPulse(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = TPSSBuffer

	if(ExistsWithCorrectLayoutVersion(wv, version))

		return wv

	elseif(WaveExists(wv))

		Redimension/D/N=(-1, -1) wv

	else

		Make/D/N=(0, 0) dfr:TPSSBuffer/Wave=wv

	endif

	SetWaveVersion(wv, version)

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
	STRUCT WaveLocationMod p

	DFREF newDFR = GetAmplifierFolder()
	p.dfr = $(GetAmplifierFolderAsString() + ":Settings")
	p.newDFR = newDFR
	// wave's name is like ITC18USB_Dev_0
	p.name = panelTitle

	WAVE/Z/D wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// nothing to do
	else
		Make/N=(31, 1, NUM_HEADSTAGES)/D newDFR:$panelTitle/Wave=wv
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
	SetDimLabel ROWS  , 16, BiasCurrent           , wv // Hold IC
	SetDimLabel ROWS  , 17, BiasCurrentEnable     , wv // Hold Enable IC
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
	SetDimLabel ROWS, 1, Units    , wv
	SetDimLabel ROWS, 2, Tolerance, wv

	wv[0][0] = "V-Clamp Holding Enable"
	wv[1][0] = LABNOTEBOOK_BINARY_UNIT
	wv[2][0] = LABNOTEBOOK_NO_TOLERANCE

	wv[0][1] =  "V-Clamp Holding Level"
	wv[1][1] = "mV"
	wv[2][1] = "0.9"

	wv[0][2] =  "Osc Killer Enable"
	wv[1][2] =  LABNOTEBOOK_BINARY_UNIT
	wv[2][2] =  LABNOTEBOOK_NO_TOLERANCE

	wv[0][3] =  "RsComp Bandwidth"
	wv[1][3] =  "Hz"
	wv[2][3] =  "0.9"

	wv[0][4] =  "RsComp Correction"
	wv[1][4] =  "%"
	wv[2][4] =  "0.9"

	wv[0][5] =  "RsComp Enable"
	wv[1][5] =  LABNOTEBOOK_BINARY_UNIT
	wv[2][5] =  LABNOTEBOOK_NO_TOLERANCE

	wv[0][6] =  "RsComp Prediction"
	wv[1][6] =  "%"
	wv[2][6] =  "0.9"

	wv[0][7] =  "Whole Cell Comp Enable"
	wv[1][7] =  LABNOTEBOOK_BINARY_UNIT
	wv[2][7] =  LABNOTEBOOK_NO_TOLERANCE

	wv[0][8] =  "Whole Cell Comp Cap"
	wv[1][8] =  "pF"
	wv[2][8] =  "0.9"

	wv[0][9] =  "Whole Cell Comp Resist"
	wv[1][9] =  "MOhm"
	wv[2][9] =  "0.9"

	wv[0][10] =  "I-Clamp Holding Enable"
	wv[1][10] =  LABNOTEBOOK_BINARY_UNIT
	wv[2][10] =  LABNOTEBOOK_NO_TOLERANCE

	wv[0][11] =  "I-Clamp Holding Level"
	wv[1][11] =  "pA"
	wv[2][11] =  "0.9"

	wv[0][12] =  "Neut Cap Enabled"
	wv[1][12] =  LABNOTEBOOK_BINARY_UNIT
	wv[2][12] =  LABNOTEBOOK_NO_TOLERANCE

	wv[0][13] =  "Neut Cap Value"
	wv[1][13] =  "pF"
	wv[2][13] =  "0.9"

	wv[0][14] =  "Bridge Bal Enable"
	wv[1][14] =  LABNOTEBOOK_BINARY_UNIT
	wv[2][14] =  LABNOTEBOOK_NO_TOLERANCE

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
	wv[1][36] =  LABNOTEBOOK_BINARY_UNIT
	wv[2][36] =  LABNOTEBOOK_NO_TOLERANCE

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

	wv[0][43] =  "Autobias Vcom"
	wv[1][43] =  "mV"
	wv[2][43] =  "0.1"

	wv[0][44] =  "Autobias Vcom variance"
	wv[1][44] =  "mV"
	wv[2][44] =  "0.1"

	wv[0][45] =  "Autobias Ibias max"
	wv[1][45] =  "pA"
	wv[2][45] =  "0.1"

	wv[0][46] =  "Autobias"
	wv[1][46] =  LABNOTEBOOK_BINARY_UNIT
	wv[2][46] =  LABNOTEBOOK_NO_TOLERANCE

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
	SetDimLabel ROWS, 1, Units    , wv
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

/// @brief Return the testpulse wave
///
/// This wave will be written in TP_CreateTestPulseWave() and will use the real
/// sampling interval.
Function/WAVE GetTestPulse()

	dfref dfr = GetWBSvdStimSetDAPath()
	WAVE/Z/SDFR=dfr wv = TestPulse

	if(WaveExists(wv))
		return wv
	endif

	/// create dummy wave
	Make/R/N=(0) dfr:TestPulse/Wave=wv

	return wv
End

static Constant WP_WAVE_LAYOUT_VERSION = 11

/// @brief Automated testing helper
static Function GetWPVersion()

	return WP_WAVE_LAYOUT_VERSION
End

/// @brief Upgrade the wave layout of `WP` to the most recent one
///        as defined in `WP_WAVE_LAYOUT_VERSION`
Function UpgradeWaveParam(wv)
	WAVE wv

	if(ExistsWithCorrectLayoutVersion(wv, WP_WAVE_LAYOUT_VERSION))
		return NaN
	endif

	Redimension/N=(86, -1, EPOCH_TYPES_TOTAL_NUMBER) wv
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
		wv[54][][EPOCH_TYPE_NOISE] = wv[41][q][EPOCH_TYPE_NOISE] == 0 && wv[42][q][EPOCH_TYPE_NOISE] == 0 ? 0 : ( wv[41][q][EPOCH_TYPE_NOISE] == 1 ? 1 : 2)
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
		Multithread wv[70,85][][] = wv[40][q][r]
		wv[40][][] = NaN
	endif

	// upgrade to wave version 11
	// nothing to do as we keep them float

	SetWaveVersion(wv, WP_WAVE_LAYOUT_VERSION)
End

static Function AddDimLabelsToWP(wv)
	WAVE wv

	variable i

	RemoveAllDimLabels(wv)

	SetDimLabel COLS,   -1, $("Epoch number"), wv

	for(i = 0; i <= SEGMENT_TYPE_WAVE_LAST_IDX; i += 1)
		SetDimLabel COLS, i, $("Epoch " + num2str(i)), wv
	endfor

	SetDimLabel LAYERS, -1, $("Epoch type")        , wv
	SetDimLabel LAYERS,  0, $("Square pulse")      , wv
	SetDimLabel LAYERS,  1, $("Ramp")              , wv
	SetDimLabel LAYERS,  2, $("Noise")             , wv
	SetDimLabel LAYERS,  3, $("Sin")               , wv
	SetDimLabel LAYERS,  4, $("Saw tooth")         , wv
	SetDimLabel LAYERS,  5, $("Pulse train")       , wv
	SetDimLabel LAYERS,  6, $("PSC")               , wv
	SetDimLabel LAYERS,  7, $("Load custom wave")  , wv
	SetDimLabel LAYERS,  8, $("Combine")           , wv

	SetDimLabel ROWS, -1, $("Property")                       , wv
	SetDimLabel ROWS, 0 , $("Duration")                       , wv
	SetDimLabel ROWS, 1 , $("Duration delta")                 , wv
	SetDimLabel ROWS, 2 , $("Amplitude")                      , wv
	SetDimLabel ROWS, 3 , $("Amplitude delta")                , wv
	SetDimLabel ROWS, 4 , $("Offset")                         , wv
	SetDimLabel ROWS, 5 , $("Offset delta")                   , wv
	SetDimLabel ROWS, 6 , $("Sin/chirp/saw frequency")        , wv
	SetDimLabel ROWS, 7 , $("Sin/chirp/saw frequency delta")  , wv
	SetDimLabel ROWS, 8 , $("Train pulse duration")           , wv
	SetDimLabel ROWS, 9 , $("Train pulse duration delta")     , wv
	SetDimLabel ROWS, 10, $("PSC exp rise time")              , wv
	SetDimLabel ROWS, 11, $("PSC exp rise time delta")        , wv
	SetDimLabel ROWS, 12, $("PSC exp decay time 1/2")         , wv
	SetDimLabel ROWS, 13, $("PSC exp decay time 1/2 delta")   , wv
	SetDimLabel ROWS, 14, $("PSC exp decay time 2/2")         , wv
	SetDimLabel ROWS, 15, $("PSC exp decay time 2/2 delta")   , wv
	SetDimLabel ROWS, 16, $("PSC ratio decay times")          , wv
	SetDimLabel ROWS, 17, $("PSC ratio decay times delta")    , wv
	// unused entries are not labeled
	SetDimLabel ROWS, 20, $("Low pass filter cut off")        , wv
	SetDimLabel ROWS, 21, $("Low pass filter cut off delta")  , wv
	SetDimLabel ROWS, 22, $("High pass filter cut off")       , wv
	SetDimLabel ROWS, 23, $("High pass filter cut off delta") , wv
	SetDimLabel ROWS, 24, $("Chirp end frequency")            , wv
	SetDimLabel ROWS, 25, $("Chirp end frequency delta")      , wv
	SetDimLabel ROWS, 26, $("Noise filter order")             , wv
	SetDimLabel ROWS, 27, $("Noise filter order delta")       , wv
	SetDimLabel ROWS, 28, $("PT: First Mixed Frequency")      , wv
	SetDimLabel ROWS, 29, $("PT: First Mixed Frequency delta"), wv
	SetDimLabel ROWS, 30, $("PT: Last Mixed Frequency")       , wv
	SetDimLabel ROWS, 31, $("PT: Last Mixed Frequency delta") , wv
	// unused entries are not labeled
	SetDimLabel ROWS, 39, $("Reseed RNG for each epoch")      , wv
	// unused entry, previously the global delta operation
	SetDimLabel ROWS, 41, $("PT: Mixed Frequency")            , wv
	SetDimLabel ROWS, 42, $("PT: Shuffle")                    , wv
	SetDimLabel ROWS, 43, $("Chirp type: Log or sin")         , wv
	SetDimLabel ROWS, 44, $("Poisson distribution true/false"), wv
	SetDimLabel ROWS, 45, $("Number of pulses")               , wv
	SetDimLabel ROWS, 46, $("Duration type: User/Automatic")  , wv
	SetDimLabel ROWS, 47, $("Number of pulses delta")         , wv
	SetDimLabel ROWS, 48, $("Random Seed")                    , wv
	SetDimLabel ROWS, 49, $("Reseed RNG for each step")       , wv
	// `dme` means `delta multiplier/exponential`
	SetDimLabel ROWS, 50, $("Amplitude dme")                  , wv
	SetDimLabel ROWS, 51, $("Offset dme")                     , wv
	SetDimLabel ROWS, 52, $("Duration dme")                   , wv
	SetDimLabel ROWS, 53, $("Trigonometric function Sin/Cos") , wv
	SetDimLabel ROWS, 54, $("Noise Type: White, Pink, Brown") , wv
	SetDimLabel ROWS, 55, $("Build resolution (index)")       , wv
	SetDimLabel ROWS, 56, $("Pulse train type (index)")       , wv
	SetDimLabel ROWS, 57, $("Sin/chirp/saw frequency dme")    , wv
	SetDimLabel ROWS, 58, $("Train pulse duration dme")       , wv
	SetDimLabel ROWS, 59, $("PSC exp rise time dme")          , wv
	SetDimLabel ROWS, 60, $("PSC exp decay time 1/2 dme")     , wv
	SetDimLabel ROWS, 61, $("PSC exp decay time 2/2 dme")     , wv
	SetDimLabel ROWS, 62, $("PSC ratio decay times dme")      , wv
	SetDimLabel ROWS, 63, $("Low pass filter cut off dme")    , wv
	SetDimLabel ROWS, 64, $("High pass filter cut off dme")   , wv
	SetDimLabel ROWS, 65, $("Chirp end frequency dme")        , wv
	SetDimLabel ROWS, 66, $("Noise filter order dme")         , wv
	SetDimLabel ROWS, 67, $("PT: First Mixed Frequency dme")  , wv
	SetDimLabel ROWS, 68, $("PT: Last Mixed Frequency dme")   , wv
	SetDimLabel ROWS, 69, $("Number of pulses dme")           , wv
	SetDimLabel ROWS, 70, $("Amplitude op")                   , wv
	SetDimLabel ROWS, 71, $("Offset op")                      , wv
	SetDimLabel ROWS, 72, $("Duration op")                    , wv
	SetDimLabel ROWS, 73, $("Sin/chirp/saw frequency op")     , wv
	SetDimLabel ROWS, 74, $("Train pulse duration op")        , wv
	SetDimLabel ROWS, 75, $("PSC exp rise time op")           , wv
	SetDimLabel ROWS, 76, $("PSC exp decay time 1/2 op")      , wv
	SetDimLabel ROWS, 77, $("PSC exp decay time 2/2 op")      , wv
	SetDimLabel ROWS, 78, $("PSC ratio decay times op")       , wv
	SetDimLabel ROWS, 79, $("Low pass filter cut off op")     , wv
	SetDimLabel ROWS, 80, $("High pass filter cut off op")    , wv
	SetDimLabel ROWS, 81, $("Chirp end frequency op")         , wv
	SetDimLabel ROWS, 82, $("Noise filter order op")          , wv
	SetDimLabel ROWS, 83, $("PT: First Mixed Frequency op")   , wv
	SetDimLabel ROWS, 84, $("PT: Last Mixed Frequency op")    , wv
	SetDimLabel ROWS, 85, $("Number of pulses op")            , wv
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

	dfref dfr = GetWaveBuilderDataPath()
	WAVE/Z/SDFR=dfr wv = WP

	if(WaveExists(wv))
		UpgradeWaveParam(wv)
	else
		Make/D/N=(86, 100, EPOCH_TYPES_TOTAL_NUMBER) dfr:WP/Wave=wvDouble
		WAVE wv = wvDouble

		// noise low/high pass filter to off
		wv[20][][EPOCH_TYPE_NOISE] = 0
		wv[22][][EPOCH_TYPE_NOISE] = 0

		// noise filter order
		wv[26][][EPOCH_TYPE_NOISE] = 6

		// per epoch RNG seed
		wv[39][][] = 1

		// noise type
		wv[54][][EPOCH_TYPE_NOISE] = 0

		AddDimLabelsToWP(wv)
		SetWaveVersion(wv, WP_WAVE_LAYOUT_VERSION)
	endif

	return wv
End

static Constant WPT_WAVE_LAYOUT_VERSION = 10

/// @brief Automated testing helper
static Function GetWPTVersion()

	return WPT_WAVE_LAYOUT_VERSION
End

/// @brief Upgrade the wave layout of `WPT` to the most recent one
///        as defined in `WPT_WAVE_LAYOUT_VERSION`
Function UpgradeWaveTextParam(wv)
	WAVE/T wv

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
	// WBP_AddAnalysisParameterIntoWPT, and that also takes care of moving it
	// into the right place
	if(WaveVersionIsSmaller(wv, 10))
		params = wv[10][%Set][INDEP_EPOCH_TYPE]
		names = AFH_GetListOfAnalysisParamNames(params)

		numEntries = ItemsInList(names)
		for(i = 0; i < numEntries; i += 1)
			name = Stringfromlist(i, names)
			type = AFH_GetAnalysisParamType(name, params)
			strswitch(type)
				case "string":
					WBP_AddAnalysisParameterIntoWPT(wv, name, str = AFH_GetAnalysisParamTextual(name, params, percentDecoded = 0))
					break
				case "textwave":
					WBP_AddAnalysisParameterIntoWPT(wv, name, wv = AFH_GetAnalysisParamTextWave(name, params, percentDecoded = 0))
					break
				case "variable":
					WBP_AddAnalysisParameterIntoWPT(wv, name, var = AFH_GetAnalysisParamNumerical(name, params))
					break
				case "wave":
					WBP_AddAnalysisParameterIntoWPT(wv, name, wv = AFH_GetAnalysisParamWave(name, params))
					break
				default:
					ASSERT(0, "Unknown type")
					break
			endswitch
		endfor

		// clear old entry
		wv[10][%Set][INDEP_EPOCH_TYPE] = ""
	endif

	SetWaveVersion(wv, WPT_WAVE_LAYOUT_VERSION)
End

/// @brief Add dimension labels to the WaveBuilder `WPT` wave
static Function AddDimLabelsToWPT(wv)
	WAVE wv

	variable i

	RemoveAllDimLabels(wv)

	SetDimLabel ROWS, 0 , $("Custom epoch wave name")        , wv
	SetDimLabel ROWS, 1 , $("Analysis pre DAQ function")     , wv
	SetDimLabel ROWS, 2 , $("Analysis mid sweep function")   , wv
	SetDimLabel ROWS, 3 , $("Analysis post sweep function")  , wv
	SetDimLabel ROWS, 4 , $("Analysis post set function")    , wv
	SetDimLabel ROWS, 5 , $("Analysis post DAQ function")    , wv
	SetDimLabel ROWS, 6 , $("Combine epoch formula")         , wv
	SetDimLabel ROWS, 7 , $("Combine epoch formula version") , wv
	SetDimLabel ROWS, 8 , $("Analysis pre sweep function")   , wv
	SetDimLabel ROWS, 9 , $("Analysis function (generic)")   , wv
	// empty: was "Analysis function params"
	SetDimLabel ROWS, 11, $("Amplitude ldel")                , wv
	SetDimLabel ROWS, 12, $("Offset ldel")                   , wv
	SetDimLabel ROWS, 13, $("Duration ldel")                 , wv
	SetDimLabel ROWS, 14, $("Sin/chirp/saw frequency ldel")  , wv
	SetDimLabel ROWS, 15, $("Train pulse duration ldel")     , wv
	SetDimLabel ROWS, 16, $("PSC exp rise time ldel")        , wv
	SetDimLabel ROWS, 17, $("PSC exp decay time 1/2 ldel")   , wv
	SetDimLabel ROWS, 18, $("PSC exp decay time 2/2 ldel")   , wv
	SetDimLabel ROWS, 19, $("PSC ratio decay times ldel")    , wv
	SetDimLabel ROWS, 20, $("Low pass filter cut off ldel")  , wv
	SetDimLabel ROWS, 21, $("High pass filter cut off ldel") , wv
	SetDimLabel ROWS, 22, $("Chirp end frequency ldel")      , wv
	SetDimLabel ROWS, 23, $("Noise filter order ldel")       , wv
	SetDimLabel ROWS, 24, $("PT: First Mixed Frequency ldel"), wv
	SetDimLabel ROWS, 25, $("PT: Last Mixed Frequency ldel") , wv
	SetDimLabel ROWS, 26, $("Number of pulses ldel")         , wv
	SetDimLabel ROWS, 27, $("Analysis pre set function")     , wv
	SetDimLabel ROWS, 28, $("Inter trial interval ldel")     , wv
	SetDimLabel ROWS, 29, $("Analysis function params (encoded)"), wv

	for(i = 0; i <= SEGMENT_TYPE_WAVE_LAST_IDX; i += 1)
		SetDimLabel COLS, i, $("Epoch " + num2str(i)), wv
	endfor

	SetDimLabel COLS, DimSize(wv, COLS) - 1, $("Set"), wv

	SetDimLabel LAYERS, -1, $("Epoch type")        , wv
	SetDimLabel LAYERS,  0, $("Square pulse")      , wv
	SetDimLabel LAYERS,  1, $("Ramp")              , wv
	SetDimLabel LAYERS,  2, $("Noise")             , wv
	SetDimLabel LAYERS,  3, $("Sin")               , wv
	SetDimLabel LAYERS,  4, $("Saw tooth")         , wv
	SetDimLabel LAYERS,  5, $("Pulse train")       , wv
	SetDimLabel LAYERS,  6, $("PSC")               , wv
	SetDimLabel LAYERS,  7, $("Load custom wave")  , wv
	SetDimLabel LAYERS,  8, $("Combine")           , wv
End

/// @brief Return the parameter text wave for the wave builder panel
///
/// Rows:
/// -  0: Name of the custom wave for #EPOCH_TYPE_CUSTOM (legacy format: wave
///       name only, current format: absolute path including the wave name)
/// -  1: Analysis function, pre daq
/// -  2: Analysis function, mid sweep
/// -  3: Analysis function, post sweep
/// -  4: Analysis function, post set
/// -  5: Analysis function, post daq
/// -  6: Formula
/// -  7: Formula version: "[[:digit:]]+"
/// -  8: Analysis function, pre sweep
/// -  9: Analysis function, generic
/// - 10: Unused
/// - 11-26: Explicit delta values. ";" separated list as long as the number of sweeps.
/// - 27: Analysis function, pre set
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
/// - `$name:(variable|string|wave|textwave)=$value`
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

	dfref dfr = GetWaveBuilderDataPath()
	WAVE/T/Z/SDFR=dfr wv = WPT

	if(WaveExists(wv))
		UpgradeWaveTextParam(wv)
	else
		Make/N=(51, 100, EPOCH_TYPES_TOTAL_NUMBER)/T dfr:WPT/Wave=wv
		AddDimLabelsToWPT(wv)
		SetWaveVersion(wv, WPT_WAVE_LAYOUT_VERSION)
	endif

	return wv
End

static Constant SEGWVTYPE_WAVE_LAYOUT_VERSION = 7

/// @brief Automated testing helper
static Function GetSegWvTypeVersion()

	return SEGWVTYPE_WAVE_LAYOUT_VERSION
End

/// @brief Upgrade the wave layout of `SegWvType` to the most recent one
///        as defined in `SEGWVTYPE_WAVE_LAYOUT_VERSION`
Function UpgradeSegWvType(wv)
	WAVE wv

	if(ExistsWithCorrectLayoutVersion(wv, SEGWVTYPE_WAVE_LAYOUT_VERSION))
		return NaN
	endif

	// no upgrade to double precision

	AddDimLabelsToSegWvType(wv)
	SetWaveVersion(wv, SEGWVTYPE_WAVE_LAYOUT_VERSION)
End

/// @brief Add dimension labels to the WaveBuilder `SegWvType` wave
static Function AddDimLabelsToSegWvType(wv)
	WAVE wv

	variable i

	ASSERT(SEGMENT_TYPE_WAVE_LAST_IDX < DimSize(wv, ROWS), "Number of reserved rows for epochs is larger than wave the itself")

	for(i = 0; i <= SEGMENT_TYPE_WAVE_LAST_IDX; i += 1)
		SetDimLabel ROWS, i, $("Type of Epoch " + num2str(i)), wv
	endfor

	SetDimLabel ROWS, 94,  $("Inter trial interval op"), wv
	SetDimLabel ROWS, 95,  $("Inter trial interval dme"), wv
	SetDimLabel ROWS, 96,  $("Inter trial interval delta"), wv
	SetDimLabel ROWS, 97,  $("Stimset global RNG seed"), wv
	SetDimLabel ROWS, 98,  $("Flip time axis")         , wv
	SetDimLabel ROWS, 99,  $("Inter trial interval")   , wv
	SetDimLabel ROWS, 100, $("Total number of epochs") , wv
	SetDimLabel ROWS, 101, $("Total number of steps")  , wv
End

/// @brief Returns the segment type wave used by the wave builder panel
/// Remember to change #SEGMENT_TYPE_WAVE_LAST_IDX if changing the wave layout
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
Function/Wave GetSegmentTypeWave()

	DFREF dfr = GetWaveBuilderDataPath()
	WAVE/Z/SDFR=dfr wv = SegWvType

	if(WaveExists(wv))
		UpgradeSegWvType(wv)
	else
		Make/N=102/D dfr:SegWvType/Wave=wvDouble
		WAVE wv = wvDouble

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

	Make/R/N=(100, 2) dfr:epochID/Wave=wv

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

	Make/R/N=(0) dfr:dispData/Wave=wv

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

/// @brief Returns the segment wave which stores the stimulus set of one segment/epoch
/// @param duration time of the stimulus in ms
Function/Wave GetSegmentWave([duration])
	variable duration

	DFREF dfr = GetWaveBuilderDataPath()
	variable numPoints = duration / WAVEBUILDER_MIN_SAMPINT
	Wave/Z/SDFR=dfr SegmentWave

	if(ParamIsDefault(duration))
		return segmentWave
	endif

	if(duration > MAX_SWEEP_DURATION_IN_MS)
		DoAbortNow("Sweeps are currently limited to 30 minutes in duration.\rAdjust MAX_SWEEP_DURATION_IN_MS to change that!")
	endif

	// optimization: recreate the wave only if necessary or just resize it
	if(!WaveExists(SegmentWave))
		Make/R/N=(numPoints) dfr:SegmentWave/Wave=SegmentWave
	elseif(numPoints != DimSize(SegmentWave, ROWS))
		Redimension/N=(numPoints) SegmentWave
	endif

	SetScale/P x 0, WAVEBUILDER_MIN_SAMPINT, "ms", SegmentWave

	return SegmentWave
End

/// @}

/// @name Asynchronous Measurements
/// @{

/// @brief Return a *free* wave for the async settings, data wave
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
/// - Layers:
///  - 0 - #LABNOTEBOOK_LAYER_COUNT: headstage dependent and independent entries
Function/Wave GetAsyncMeasurementWave()

	Make/D/FREE/N=(1,8, LABNOTEBOOK_LAYER_COUNT) wv
	wv = NaN

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

/// @brief Return a *free* wave for the async settings, key wave
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
Function/Wave GetAsyncMeasurementKeyWave()

	Make/FREE/T/N=(3,8) wv
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

/// @brief Return a *free* wave for the asyncSettingsWave, data wave
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
/// - Layers:
///  - 0 - #LABNOTEBOOK_LAYER_COUNT: headstage dependent and independent entries
Function/Wave GetAsyncSettingsWave()

	Make/D/N=(1, 40, LABNOTEBOOK_LAYER_COUNT)/FREE wv
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
Function/Wave GetAsyncSettingsKeyWave()

	Make/T/N=(3,40)/FREE wv
	wv = ""

	SetDimLabel 0, 0, Parameter, wv
	SetDimLabel 0, 1, Units, wv
	SetDimLabel 0, 2, Tolerance, wv

	wv[%Parameter][0] = "Async 0 On/Off"
	wv[%Units][0]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][0] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][1] = "Async 1 On/Off"
	wv[%Units][1]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][1] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][2] = "Async 2 On/Off"
	wv[%Units][2]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][2] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][3] = "Async 3 On/Off"
	wv[%Units][3]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][3] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][4] = "Async 4 On/Off"
	wv[%Units][4]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][4] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][5] = "Async 5 On/Off"
	wv[%Units][5]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][5] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][6] = "Async 6 On/Off"
	wv[%Units][6]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][6] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][7] = "Async 7 On/Off"
	wv[%Units][7]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][7] = LABNOTEBOOK_NO_TOLERANCE

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
	wv[%Units][16]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][16] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][17] = "Async Alarm 1 On/Off"
	wv[%Units][17]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][17] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][18] = "Async Alarm 2 On/Off"
	wv[%Units][18]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][18] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][19] = "Async Alarm 3 On/Off"
	wv[%Units][19]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][19] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][20] = "Async Alarm 4 On/Off"
	wv[%Units][20]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][20] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][21] = "Async Alarm 5 On/Off"
	wv[%Units][21]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][21] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][22] = "Async Alarm 6 On/Off"
	wv[%Units][22]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][22] = LABNOTEBOOK_NO_TOLERANCE

	wv[%Parameter][23] = "Async Alarm 7 On/Off"
	wv[%Units][23]     = LABNOTEBOOK_BINARY_UNIT
	wv[%Tolerance][23] = LABNOTEBOOK_NO_TOLERANCE

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

/// @brief Return a *free* wave for the AsyncSettingsTxtWave
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
/// - Layers:
///  - 0 - #LABNOTEBOOK_LAYER_COUNT: headstage dependent and independent entries
Function/Wave GetAsyncSettingsTextWave()

	Make/T/N=(1,16, LABNOTEBOOK_LAYER_COUNT)/FREE wv
	wv = ""

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
Function/Wave GetAsyncSettingsTextKeyWave()

	Make/T/N=(1,16)/FREE wv
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
Function/WAVE P_GetITCData(panelTitle)
	string panelTitle

	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	Wave/Z/T/SDFR=dfr P_ITCData

	if(WaveExists(P_ITCData))
		return P_ITCData
	endif

	Make/W/N=(2^MINIMUM_ITCDATAWAVE_EXPONENT, 4) dfr:P_ITCData/WAVE=wv

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

	wv[][2]  = WAVEBUILDER_MIN_SAMPINT * 1000

	SetDimLabel ROWS, 0, DA, 		wv
	SetDimLabel ROWS, 1, AD, 		wv
	SetDimLabel ROWS, 2, TTL_R0, 	wv
	SetDimLabel ROWS, 3, TTL_R1, 	wv

	SetDimLabel COLS, 0, Chan_Type, wv
	SetDimLabel COLS, 1, Chan_num, 	wv
	SetDimLabel COLS, 2, Samp_int, 	wv

	return wv
End

/// @brief Set the dimension labels for the numeric pressure wave
static Function SetPressureWaveDimLabels(wv)
	WAVE wv

	SetDimLabel COLS, 0 , Approach_Seal_BrkIn_Clear, wv
	SetDimLabel COLS, 1 , DAC_List_Index           , wv
	SetDimLabel COLS, 2 , HW_DAC_Type              , wv
	SetDimLabel COLS, 3 , DAC_DevID                , wv
	SetDimLabel COLS, 4 , DAC                      , wv
	SetDimLabel COLS, 5 , DAC_Gain                 , wv
	SetDimLabel COLS, 6 , ADC                      , wv
	SetDimLabel COLS, 7 , ADC_Gain                 , wv
	SetDimLabel COLS, 8 , TTL_A                    , wv
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
	SetDimLabel COLS, 23, SSResistanceSlope        , wv
	SetDimLabel COLS, 24, ActiveTP				   , wv
	/// @todo If user switched headStage mode while pressure regulation is
	/// ongoing, pressure reg either needs to be turned off, or steady state
	/// slope values need to be used
	/// @todo Enable mode switching with TP running (auto stop TP, switch mode, auto startTP)
	/// @todo Enable headstate switching with TP running (auto stop TP, change headStage state, auto start TP)
	SetDimLabel COLS, 25, SSResistanceSlopeThreshold, wv
	// If the PeakResistance slope is greater than the SSResistanceSlope
	// thershold pressure method does not need to update i.e. the pressure is
	// "good" as it is
	SetDimLabel COLS, 26, TimeOfLastRSlopeCheck   , wv
	SetDimLabel COLS, 27, LastPressureCommand     , wv
	SetDimLabel COLS, 28, OngoingPessurePulse     , wv
	SetDimLabel COLS, 29, LastVcom                , wv
	SetDimLabel COLS, 30, ManSSPressure           , wv
	SetDimLabel COLS, 31, ManPPPressure           , wv
	SetDimLabel COLS, 32, ManPPDuration           , wv
	SetDimLabel COLS, 33, LastPeakR               , wv
	SetDimLabel COLS, 34, PeakR                   , wv
	SetDimLabel COLS, 35, TimePeakRcheck          , wv
	SetDimLabel COLS, 36, PosCalConst             , wv
	SetDimLabel COLS, 37, NegCalConst             , wv
	SetDimLabel COLS, 38, ApproachNear            , wv
	SetDimLabel COLS, 39, SealAtm                 , wv
	SetDimLabel COLS, 40, UserSelectedHeadStage   , wv
	SetDimLabel COLS, 41, UserPressureOffset      , wv
	SetDimLabel COLS, 42, UserPressureOffsetTotal , wv
	SetDimLabel COLS, 43, UserPressureOffsetPeriod, wv
	SetDimLabel COLS, 44, TTL_B                   , wv
	SetDimLabel COLS, 45, UserPressureDeviceID    , wv
	SetDimLabel COLS, 46, UserPressureDeviceHWType, wv
	SetDimLabel COLS, 47, UserPressureDeviceADC   , wv

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
/// - 0: Pressure method. -1 = none, 0 = Approach, 1 = Seal, 2 = Break In, 3 = Clear
/// - 1: List position of DAC (used for presssure control) selected for headstage
/// - 2: Type of DAC, index into #HARDWARE_DAC_TYPES
/// - 3: Device ID used by Instrutech DACs or index into HW_NI_ListDevices depending on column 2
/// - 4: DA channel used for pressure regulation.
/// - 5: Gain of DA channel used for presssure regulation.
/// - 6: AD channel used for pressure regulation.
/// - 7: Gain of AD channel used for pressure regulation.
/// - 8: TTL channel A used for pressure regulation.
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
Function/WAVE P_GetPressureDataWaveRef(panelTitle)
	string	panelTitle

	variable versionOfNewWave = 8
	DFREF dfr = P_DeviceSpecificPressureDFRef(panelTitle)
	Wave/D/Z/SDFR=dfr wv=PressureData

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/D/N=(8, 48) wv
		SetPressureWaveDimLabels(wv)
	else
		Make/D/N=(8, 48) dfr:PressureData/Wave=wv

		SetPressureWaveDimLabels(wv)

		wv 	= nan

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

	wv[][%UserPressureOffset]        = 0
	wv[][%UserPressureOffsetPeriod]  = 0
	wv[][%UserPressureOffsetTotal]   = NaN
	wv[][%UserPressureDeviceID]      = NaN
	wv[][%UserPressureDeviceHWType]  = NaN
	wv[][%UserPressureDeviceADC]     = NaN

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

	wv[][0]        = NONE
	wv[][%DA_Unit] = "psi"
	wv[][%AD_Unit] = "psi"

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End
/// @}

/// @brief Returns a wave reference to the QC Wave
///
/// Used for completing QC functions background tasks.
///
/// Rows:
/// - 0: tpBuffer, used to hold previous tp settings.
///      Setting will be restored upon completion of qc function.
Function/Wave GetQCWaveRef(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTempFolder(panelTitle)

	WAVE/Z/T/SDFR=dfr wv = QCWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1) dfr:QCWave/Wave=wv
	SetDimLabel 0, 0, tpBuffer, wv

	return wv
End

/// @brief Return the data folder reference to the device specific lab notebook folder for temporary waves
Function/DF GetDevSpecLabNBTempFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBTempFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific lab notebook temp folder, e.g. root:MIES:LabNoteBook:ITC18USB:Device0:Temp
Function/S GetDevSpecLabNBTempFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":Temp"
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

/// @brief Return the datafolder reference to the sweep to channel relation of a device and experiment pair
Function/DF GetAnalysisDevChannelFolder(expFolder, device)
	string expFolder, device
	return createDFWithAllParents(GetAnalysisDevChannelFolderAS(expFolder, device))
End

/// @brief Return the full path to the sweep to channel relation folder of a device and experiment pair, e.g. root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:channel
Function/S GetAnalysisDevChannelFolderAS(expFolder, device)
	string expFolder, device

	return GetAnalysisDeviceFolderAS(expFolder, device) + ":channel"
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

/// @brief Return the full path to the the per sweep folder, e.g. root:MIES:Analysis:my_experiment:sweep:X_$sweep
Function/S GetAnalysisSweepDataPathAS(expFolder, device, sweep)
	string expFolder, device
	variable sweep

	ASSERT(IsFinite(sweep), "Expected finite sweep number")
	return GetSingleSweepFolderAsString(GetAnalysisSweepPath(expFolder, device), sweep)
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

///  wave is used to relate it's index to sweepWave and deviceWave.
Function/Wave GetAnalysisChannelStorage(dataFolder, device)
	String dataFolder, device
	Variable versionOfWave = 2

	DFREF dfr = GetAnalysisDevChannelFolder(dataFolder, device)
	Wave/Z/SDFR=dfr/WAVE wv = channelStorage

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	elseif(ExistsWithCorrectLayoutVersion(wv, 1))
		// update Dimension label
	else
		Make/R/O/N=(MINIMUM_WAVE_SIZE, 1)/WAVE dfr:channelStorage/Wave=wv
		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	endif

	SetDimLabel COLS, 0, configSweep,   wv

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return a wave containing all stimulus channels in the NWB file as a ";"-separated List
///  wave is used to relate it's index to sweepWave and deviceWave.
Function/Wave GetAnalysisChannelStimWave(dataFolder, device)
	String dataFolder, device

	DFREF dfr = GetAnalysisDevChannelFolder(dataFolder, device)

	Wave/Z/SDFR=dfr/T wv = stimulus

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/T dfr:stimulus/Wave=wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return a wave containing all acquisition channels in the NWB file as a ";"-separated List
///  wave is used to relate it's index to sweepWave and deviceWave.
Function/Wave GetAnalysisChannelAcqWave(dataFolder, device)
	String dataFolder, device

	DFREF dfr = GetAnalysisDevChannelFolder(dataFolder, device)

	Wave/Z/SDFR=dfr/T wv = acquisition

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/T dfr:acquisition/Wave=wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return a wave containing all sweeps in a unique fashion.
///  wave is used to relate it's index to channelWave and deviceWave
Function/Wave GetAnalysisChannelSweepWave(dataFolder, device)
	String dataFolder, device

	DFREF dfr = GetAnalysisDevChannelFolder(dataFolder, device)

	Wave/Z/SDFR=dfr/I wv = sweeps

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/I dfr:sweeps/Wave=wv = -1
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return a wave containing all devices
///  wave is used to relate it's index to sweepWave and channelWave.
Function/Wave GetAnalysisDeviceWave(dataFolder)
	String dataFolder

	DFREF dfr = GetAnalysisExpFolder(dataFolder)

	Wave/Z/SDFR=dfr/T wv = devices

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(MINIMUM_WAVE_SIZE)/T dfr:devices/Wave=wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return AnalysisBrowser indexing storage wave
///
/// Rows:
/// Experiments found in current Directory
///
/// Columns:
/// 0: %DiscLocation:  Path to Experiment on Disc
/// 1: %FileName:      Name of File in experiment column in ExperimentBrowser
/// 2: %DataFolder     Data folder inside current Igor experiment
/// 3: %FileType       File Type identifier for routing to loader functions
Function/Wave GetAnalysisBrowserMap()
	DFREF dfr = GetAnalysisFolder()
	variable versionOfWave = 2

	STRUCT WaveLocationMod p
	p.dfr     = dfr
	p.newDFR  = dfr
	p.name    = "experimentMap"
	p.newName = "analysisBrowserMap"

	WAVE/Z/T wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	elseif(ExistsWithCorrectLayoutVersion(wv, 1))
		// update dimension labels
	elseif(WaveExists(wv))
		Redimension/N=(-1, 4) wv
		wv[][3] = ANALYSISBROWSER_FILE_TYPE_IGOR
	else
		Make/N=(MINIMUM_WAVE_SIZE, 4)/T dfr:analysisBrowserMap/Wave=wv
		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	endif

	SetDimLabel COLS, 0, DiscLocation, wv
	SetDimLabel COLS, 1, FileName, wv
	SetDimLabel COLS, 2, DataFolder, wv
	SetDimLabel COLS, 3, FileType, wv

	SetWaveVersion(wv, versionOfWave)

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

	Make/R/N=(MINIMUM_WAVE_SIZE, NUM_COLUMNS_LIST_WAVE) dfr:expBrowserSel/Wave=wv

	return wv
End

/// @brief Return the configSweep wave of a given sweep from the analysis subfolder
Function/Wave GetAnalysisConfigWave(dataFolder, device, sweep)
	string dataFolder, device
	variable sweep

	DFREF dfr = GetAnalysisDeviceConfigFolder(dataFolder, device)
	string configSweep  = "Config_Sweep_" + num2str(sweep)

	Wave/I/Z/SDFR=dfr wv = $configSweep

	if(WaveExists(wv))
		// do nothing
	else
		Make/N=(0, 4)/I dfr:$configSweep/Wave=wv = -1
	endif

	SetDimLabel COLS, 0, type,   wv
	SetDimLabel COLS, 1, number, wv
	SetDimLabel COLS, 2, timeMS, wv

	return wv
End

/// @brief Return the numerical labnotebook values in the analysis browser of a device and experiment pair
Function/WAVE GetAnalysLBNumericalValues(expFolder, device)
	string expFolder, device

	string newName = "numericalValues"

	STRUCT WaveLocationMod p
	p.dfr     = GetAnalysisLabNBFolder(expFolder, device)
	p.name    = "numericValues"
	p.newName = newName

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(WaveExists(wv))
		return wv
	endif

	ASSERT(0, "Trying to access non existing numerical values labnotebook")
End

/// @brief Return the textual labnotebook keys in the analysis browser of a device and experiment pair
Function/WAVE GetAnalysLBTextualValues(expFolder, device)
	string expFolder, device

	string newName = "textualValues"

	STRUCT WaveLocationMod p
	p.dfr     = GetAnalysisLabNBFolder(expFolder, device)
	p.name    = "textValues"
	p.newName = newName

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(WaveExists(wv))
		return wv
	endif

	ASSERT(0, "Trying to access non existing textual values labnotebook")
End

/// @brief Return the numerical labnotebook keys in the analysis browser of a device and experiment pair
Function/WAVE GetAnalysLBNumericalKeys(expFolder, device)
	string expFolder, device

	string newName = "numericalKeys"

	STRUCT WaveLocationMod p
	p.dfr     = GetAnalysisLabNBFolder(expFolder, device)
	p.name    = "numericKeys"
	p.newName = newName

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(WaveExists(wv))
		return wv
	endif

	ASSERT(0, "Trying to access non existing numerical keys labnotebook")
End

/// @brief Return the textual labnotebook keys in the analysis browser of a device and experiment pair
Function/WAVE GetAnalysLBTextualKeys(expFolder, device)
	string expFolder, device

	string newName = "textualKeys"

	STRUCT WaveLocationMod p
	p.dfr     = GetAnalysisLabNBFolder(expFolder, device)
	p.name    = "textKeys"
	p.newName = newName

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(WaveExists(wv))
		return wv
	endif

	ASSERT(0, "Trying to access non existing textual keys labnotebook")
End

/// @}

/// @brief Return the indexing storage wave
///
/// Rows:
/// 0: DA (#CHANNEL_TYPE_DAC)
/// 0: TTL (#CHANNEL_TYPE_TTL)
///
/// Cols:
/// 0: Popup menu index of Wave (stimset)
/// 1: Popup menu index of Indexing end wave (stimset)
///
/// All zero-based as returned by GetPopupMenuIndex().
///
/// Layers:
/// - Channels
Function/Wave GetIndexingStorageWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)
	variable versionOfNewWave = 1

	WAVE/Z/SDFR=dfr wv = IndexingStorageWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
		return wv
	endif

	Make/R/N=(2, 2, NUM_DA_TTL_CHANNELS) dfr:IndexingStorageWave/Wave=wv

	SetDimLabel ROWS, 0, CHANNEL_TYPE_DAC, wv
	SetDimLabel ROWS, 1, CHANNEL_TYPE_TTL, wv

	SetDimLabel COLS, 0, CHANNEL_CONTROL_WAVE, wv
	SetDimLabel COLS, 1, CHANNEL_CONTROL_INDEX_END, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the temporary folder below the MIES hierarchy, e.g. root:mies:trash.
Function/DF GetTempPath()

	return createDFWithAllParents(GetMiesPathAsString() + ":" + TRASH_FOLDER_PREFIX)
End

/// @brief Return a unique temporary folder below the MIES hierarchy, e.g. root:mies:trash_$digit.
///
/// As soon as you discard the latest reference to the folder it will
/// be slated for removal at some point in the future.
threadsafe Function/DF GetUniqueTempPath()

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
/// e.g. root:MIES:HardwareDevices:ActiveITCDevices:TestPulse
Function/DF GetActITCDevicesTestPulseFolder()
	return createDFWithAllParents(GetActITCDevicesTestPulFolderA())
End

/// @brief Return the full path to the active ITC devices location
Function/S GetActITCDevicesTestPulFolderA()
	return GetITCDevicesFolderAsString() + ":ActiveITCDevices:TestPulse"
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

	DFREF dfr = GetActITCDevicesTestPulseFolder()
	variable versionOfNewWave = 1

	WAVE/Z/SDFR=dfr wv = ActiveDevicesTPMD

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(MINIMUM_WAVE_SIZE, 3) dfr:ActiveDevicesTPMD/Wave=wv
		wv = NaN
	endif

	SetDimLabel COLS, 0, DeviceID,    wv
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
/// - 0: State of control Check_DataAcqHS_RowNum. 0 = UnChecked, 1 = Checked
/// - 1: Clamp mode of HS number that matches Row number. 0 = VC, 1 = IC, 2 = NC.
/// - 2: State of control Check_DA_RowNum. 0 = UnChecked, 1 = Checked
/// - 3: Internal number stored in control Gain_DA_RowNum. Gain is user/hardware defined.
/// - 4: Internal number stored in setvar:Scale_DA_RowNum. Scalar is user defined.
/// - 5: PopupMenu Index of popupMenu:Wave_DA_RowNum. Stores index
///  	 of active DA stimulus set during data acquisition. Stores index of next DA
///      stimulus set when data acquistion is not active.
/// - 6: PopupMenu Index of popupMenu:IndexEnd_DA_RowNum. Stores the
///      index of the last DA stimulus set used in indexed aquisition mode.
/// - 7: State of checkbox control Check_AD_RowNum. 0 = UnChecked, 1 = Checked
/// - 8: Internal number stored in Gain_AD_RowNum. Gain is user/hardware defined.
/// - 9: State of checkbox control Check_TTL_RowNum.  0 = UnChecked, 1 = Checked
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
Function/Wave GetDA_EphysGuiStateNum(panelTitle)
	string panelTitle

	variable uniqueCtrlCount
	string uniqueCtrlList

	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/Z/D/SDFR=dfr wv = DA_EphysGuiStateNum

	if(ExistsWithCorrectLayoutVersion(wv, DA_EPHYS_PANEL_VERSION))
		return wv
	elseif(WaveExists(wv)) // handle upgrade
		// change the required dimensions and leave all others untouched with -1
		// the extended dimensions are initialized with zero
		uniqueCtrlList = DAG_GetUniqueSpecCtrlListNum(panelTitle)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Redimension/D/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT_NUM + uniqueCtrlCount, -1, -1) wv
		wv = Nan
	else
		uniqueCtrlList = DAG_GetUniqueSpecCtrlListNum(panelTitle)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Make/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT_NUM + uniqueCtrlCount)/D dfr:DA_EphysGuiStateNum/Wave=wv
		wv = Nan
	endif

	SetDimLabel COLS,  0, $GetSpecialControlLabel(CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS,  1, HSMode, wv
	SetDimLabel COLS,  2, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS,  3, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN), wv
	SetDimLabel COLS,  4, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), wv
	SetDimLabel COLS,  5, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), wv
	SetDimLabel COLS,  6, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), wv
	SetDimLabel COLS,  7, $GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS,  8, $GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN), wv
	SetDimLabel COLS,  9, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS, 10, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), wv
	SetDimLabel COLS, 11, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END), wv
	SetDimLabel COLS, 12, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS, 13, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN), wv
	SetDimLabel COLS, 14, $GetSpecialControlLabel(CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK), wv
	SetDimLabel COLS, 15, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN), wv
	SetDimLabel COLS, 16, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX), wv
	SetDimLabel COLS, 17, HSMode_delayed, wv

	SetWaveDimLabel(wv, uniqueCtrlList, COLS, startPos = COMMON_CONTROL_GROUP_COUNT_NUM)
	SetWaveVersion(wv, DA_EPHYS_PANEL_VERSION)
	// needs to be called after setting the wave version in order to avoid infinite recursion
	DAG_RecordGuiStateNum(panelTitle, GuiState = wv)
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
Function/Wave GetDA_EphysGuiStateTxT(panelTitle)
	string panelTitle

	DFREF dfr= GetDevicePath(panelTitle)
	Wave/Z/T/SDFR=dfr wv = DA_EphysGuiStateTxT
	variable uniqueCtrlCount
	string uniqueCtrlList

	if(ExistsWithCorrectLayoutVersion(wv, DA_EPHYS_PANEL_VERSION))
		return wv
	elseif(WaveExists(wv)) // handle upgrade
		// change the required dimensions and leave all others untouched with -1
		// the extended dimensions are initialized with zero
		uniqueCtrlList = DAG_GetUniqueSpecCtrlListTxt(panelTitle)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Redimension/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT_TXT + uniqueCtrlCount, -1, -1) wv
		wv = ""
	else
		uniqueCtrlList = DAG_GetUniqueSpecCtrlListTxt(panelTitle)
		uniqueCtrlCount = itemsInList(uniqueCtrlList)
		Make/T/N=(NUM_MAX_CHANNELS, COMMON_CONTROL_GROUP_COUNT_TXT + uniqueCtrlCount) dfr:DA_EphysGuiStateTxT/Wave=wv
		wv = ""
	endif

	SetDimLabel COLS,  0, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), wv
	SetDimLabel COLS,  1, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), wv
	SetDimLabel COLS,  2, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT), wv
	SetDimLabel COLS,  3, $GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH), wv
	SetDimLabel COLS,  4, $GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT), wv
	SetDimLabel COLS,  5, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), wv
	SetDimLabel COLS,  6, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END), wv
	SetDimLabel COLS,  7, $GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_SEARCH), wv
	SetDimLabel COLS,  8, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE), wv
	SetDimLabel COLS,  9, $GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT), wv

	SetWaveDimLabel(wv, uniqueCtrlList, COLS, startPos = COMMON_CONTROL_GROUP_COUNT_TXT)
	SetWaveVersion(wv, DA_EPHYS_PANEL_VERSION)
	// needs to be called after setting the wave version in order to avoid infinite recursion
	DAG_RecordGuiStateTxT(panelTitle, Guistate = wv)
	return wv
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
/// - 1: Name of the device used for pressure control (maybe empty)
Function/WAVE GetDeviceMapping()

	DFREF dfr = GetITCDevicesFolder()
	variable versionOfNewWave = 2

	WAVE/Z/T/SDFR=dfr wv = deviceMapping

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(HARDWARE_MAX_DEVICES, -1, 2) wv
	else
		Make/T/N=(HARDWARE_MAX_DEVICES, ItemsInList(HARDWARE_DAC_TYPES), 2) dfr:deviceMapping/Wave=wv
	endif

	SetDimLabel ROWS, -1, DeviceID, wv

	SetDimLabel COLS, 0, ITC_DEVICE, wv
	SetDimLabel COLS, 1, NI_DEVICE , wv

	SetDimLabel LAYERS, 0, MainDevice    , wv
	SetDimLabel LAYERS, 1, PressureDevice, wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @name Getters relating to caching
/// @{
/// @brief Return the datafolder reference to the wave cache
Function/DF GetCacheFolder()
	return createDFWithAllParents(GetCacheFolderAS())
End

/// @brief Return the full path to the wave cache datafolder, e.g. root:MIES:Cache
Function/S GetCacheFolderAS()
	return GetMiesPathAsString() + ":Cache"
End

/// @brief Return the wave reference wave holding the cached data
///
/// Dimension sizes and `NOTE_INDEX` value must coincide with other two cache waves.
Function/Wave GetCacheValueWave()

	DFREF dfr = GetCacheFolder()

	WAVE/WAVE/Z/SDFR=dfr wv = values

	if(WaveExists(wv))
		return wv
	else
		Make/WAVE/N=(MINIMUM_WAVE_SIZE) dfr:values/Wave=wv
	endif

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the wave reference wave holding the cache keys
///
/// Dimension sizes and `NOTE_INDEX` value must coincide with other two cache waves.
Function/Wave GetCacheKeyWave()

	DFREF dfr = GetCacheFolder()

	WAVE/T/Z/SDFR=dfr wv = keys

	if(WaveExists(wv))
		return wv
	else
		Make/T/N=(MINIMUM_WAVE_SIZE) dfr:keys/Wave=wv
	endif

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

/// @brief Return the wave reference wave holding the cache stats
///
/// Rows:
/// - One for each cache entry
///
/// Cols:
/// - 0: Number of cache hits   (Incremented for every read)
/// - 1: Number of cache misses (Increment for every failed lookup)
/// - 2: Modification timestamp (Updated on write)
/// - 3: Size in bytes (Updated on write)
///
/// Dimension sizes and `NOTE_INDEX` value must coincide with other two cache waves.
Function/Wave GetCacheStatsWave()

	variable versionOfNewWave = 3

	variable numRows, index, oldNumRows
	DFREF dfr = GetCacheFolder()
	WAVE/D/Z/SDFR=dfr wv = stats

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	else
		WAVE/T keys      = GetCacheKeyWave()
		WAVE/WAVE values = GetCacheValueWave()
		numRows = DimSize(values, ROWS)
		ASSERT(DimSize(keys, ROWS) == numRows, "Mismatched row sizes")

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
		else
			// experiments prior to ab795b55 (Cache: Add statistics for each entry, 2018-03-23)
			// don't hold this wave, but we still have to ensure that the stats wave has the right number of rows
			Make/D/N=(numRows, 4) dfr:stats/Wave=wv
		endif
	endif

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
/// @}

/// @brief Return the datafolder reference to the oodDAQ folder
Function/DF GetDistDAQFolder()
	return createDFWithAllParents(GetDistDAQFolderAS())
End

/// @brief Return the full path to the optimized overlap distributed
///        acquisition (oodDAQ) folder, e.g. root:MIES:HardwareDevices:oodDAQ
Function/S GetDistDAQFolderAS()
	return GetITCDevicesFolderAsString() + ":oodDAQ"
End

/// @brief Return the wave used for storing preloadable data
///
/// Required for yoked oodDAQ only.
Function/WAVE GetDistDAQPreloadWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDistDAQFolder()
	string wvName = "preload_" + panelTitle

	WAVE/Z/SDFR=dfr wv = $wvName

	if(WaveExists(wv))
		return wv
	else
		// wave type is overwritten in OOD_StorePreload
		Make/R/N=(0) dfr:$wvName/Wave=wv
	endif

	return wv
End

/// @brief Returns the names of the electrodes
///
/// The electrodes represents the physically connected part to the cell whereas
/// the headstage refers to the logical entity inside MIES.
///
/// Will be written into the labnotebook and used for the NWB export.
Function/WAVE GetCellElectrodeNames(panelTitle)
	string panelTitle

	variable versionOfNewWave = 1
	DFREF dfr = GetDevicePath(panelTitle)

	WAVE/Z/T/SDFR=dfr wv = cellElectrodeNames

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	else
		Make/T/N=(NUM_HEADSTAGES) dfr:cellElectrodeNames/WAVE=wv
		wv = GetDefaultElectrodeName(p)
	endif

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
Function/WAVE GetPressureTypeWv(panelTitle)
	string panelTitle

	DFREF dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	WAVE/Z/SDFR=dfr wv = pressureType

	if(WaveExists(wv))
		return wv
	endif

	Make/R/N=(NUM_HEADSTAGES) dfr:pressureType/Wave=wv

	return wv
End

/// @brief Return the pulse averaging folder
Function/DF GetDevicePulseAverageFolder(dfr)
	DFREF dfr

	return createDFWithAllParents(GetDevicePulseAverageFolderAS(dfr))
End

/// @brief Return the full path to the pulse averaging folder, e.g. dfr:PulseAveraging
Function/S GetDevicePulseAverageFolderAS(dfr)
	DFREF dfr

	return GetDataFolder(1, dfr) + "PulseAveraging"
End

/// @brief Return the pulse averaging helper folder
///
/// This holds various helper waves for the graph generation.
Function/DF GetDevicePulseAverageHelperFolder(dfr)
	DFREF dfr

	return createDFWithAllParents(GetDevicePulseAverageHelperFolderAS(dfr))
End

/// @brief Return the full path to the pulse averaging helper folder, e.g. dfr:Helper
Function/S GetDevicePulseAverageHelperFolderAS(dfr)
	DFREF dfr

	return GetDevicePulseAverageFolderAS(dfr) + ":Helper"
End

/// @brief Return a wave reference to the single pulse defined by the given parameters
///
/// @param dfr           datafolder reference where to create the empty wave if it does not exist
/// @param length        Length in points of the new wave
/// @param channelType   ITC XOP numeric channel type
/// @param channelNumber channel number
/// @param region        region index (a region is the range with data in a dDAQ/oodDAQ measurement)
/// @param pulseIndex    pulse number, 0-based
Function/WAVE GetPulseAverageWave(dfr, length, channelType, channelNumber, region, pulseIndex)
	DFREF dfr
	variable length, channelType, pulseIndex, channelNumber, region

	variable versionOfNewWave = 2
	string wvName

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")
	wvName = PA_GeneratePulseWaveName(channelType, channelNumber, region, pulseIndex)

	WAVE/SDFR=dfr/Z wv = $wvName
	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
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
/// @param channelType   ITC XOP numeric channel type
/// @param channelNumber channel number
/// @param region        region index (a region is the range with data in a dDAQ/oodDAQ measurement)
/// @param pulseIndex    pulse number, 0-based
Function/WAVE GetPulseAverageWaveNoteWave(dfr, length, channelType, channelNumber, region, pulseIndex)
	DFREF dfr
	variable length, channelType, pulseIndex, channelNumber, region

	variable versionOfNewWave = 1
	string wvName

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")
	wvName = PA_GeneratePulseWaveName(channelType, channelNumber, region, pulseIndex) + PULSEWAVE_NOTE_SUFFIX

	WAVE/SDFR=dfr/Z wv = $wvName
	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
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
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(MINIMUM_WAVE_SIZE, 1) dfr:$name/Wave=wv
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
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(1, MINIMUM_WAVE_SIZE) dfr:$name/Wave=wv
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

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr wv = properties

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 9) wv
	else
		Make/R/N=(MINIMUM_WAVE_SIZE_LARGE, 9) dfr:properties/Wave=wv
	endif

	Multithread wv[] = NaN

	SetDimLabel COLS, PA_PROPERTIES_INDEX_SWEEP, $"Sweep", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_CHANNELNUMBER, $"ChannelNumber", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_REGION, $"Region", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_HEADSTAGE, $"Headstage", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_PULSE, $"Pulse", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_PULSEHASFAILED, $"PulseHasFailed", wv
	SetDimLabel COLS, PA_PROPERTIES_INDEX_LASTSWEEP, $"LastSweep", wv

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
	WAVE/WAVE/Z/SDFR=dfr wv = propertiesWaves

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/WAVE/N=(MINIMUM_WAVE_SIZE_LARGE, 2) dfr:propertiesWaves/Wave=wv
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
	WAVE/D/Z/SDFR=dfr wv = displayMapping

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(NUM_HEADSTAGES, NUM_MAX_CHANNELS, 2) dfr:displayMapping/Wave=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)
	SetDimLabel LAYERS, 0, ACTIVEREGION, wv
	SetDimLabel LAYERS, 1, ACTIVECHANNEL, wv

	return wv
End

/// @brief Return the artefact removal listbox wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetArtefactRemovalListWave(dfr)
	DFREF dfr

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/T/Z/SDFR=dfr wv = artefactRemovalListBoxWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 2) dfr:artefactRemovalListBoxWave/Wave=wv
	endif

	SetDimLabel COLS, 0, $"Begin [ms]", wv
	SetDimLabel COLS, 1, $"End   [ms]", wv

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return the artefact removal wave
///        databrowser or the sweepbrowser
Function/WAVE GetArtefactRemovalDataWave(dfr)
	DFREF dfr

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/D/Z/SDFR=dfr wv = artefactRemovalDataWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/D/N=(MINIMUM_WAVE_SIZE, 4) wv
	else
		Make/D/N=(MINIMUM_WAVE_SIZE, 4) dfr:artefactRemovalDataWave/Wave=wv
	endif

	SetDimLabel COLS, 0, $"ArtefactPosition", wv
	SetDimLabel COLS, 1, $"DAC",           wv
	SetDimLabel COLS, 2, $"ADC",           wv
	SetDimLabel COLS, 3, $"HS",            wv

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return the overlay sweeps listbox wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetOverlaySweepsListWave(dfr)
	DFREF dfr

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/T/Z/SDFR=dfr wv = overlaySweepsListBoxWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 2) dfr:overlaySweepsListBoxWave/Wave=wv
	endif

	SetDimLabel COLS, 0, $"Sweep", wv
	SetDimLabel COLS, 1, $"Headstages", wv

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return the overlay sweeps listbox selection wave
/// for the databrowser or the sweepbrowser
Function/WAVE GetOverlaySweepsListSelWave(dfr)
	DFREF dfr

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/B/Z/SDFR=dfr wv = overlaySweepsListBoxSelWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/B/N=(MINIMUM_WAVE_SIZE, 2) dfr:overlaySweepsListBoxSelWave/Wave=wv
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
/// Cols:
/// - #NUM_HEADSTAGES, 1 if active and 0 if removed
Function/WAVE GetOverlaySweepHeadstageRemoval(DFREF dfr)
	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr wv = overlaySweepsHeadstageRemoval

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/R/N=(MINIMUM_WAVE_SIZE, NUM_HEADSTAGES) dfr:overlaySweepsHeadstageRemoval/Wave=wv
	endif

	wv = 1

	SetWaveVersion(wv, versionOfNewWave)
	return wv
End

/// @brief Return the overlay sweeps wave with all sweep selection choices
/// for the databrowser or the sweepbrowser
Function/WAVE GetOverlaySweepSelectionChoices(win, dfr, [skipUpdate])
	string win
	DFREF dfr
	variable skipUpdate

	variable versionOfNewWave = 3

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

	WAVE/T/Z wv = UpgradeWaveLocationAndGetIt(p)

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		if(!skipUpdate)
			OVS_UpdateSweepSelectionChoices(win, wv)
		endif
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, -1, 3) wv
	else
		ASSERT(NUM_HEADSTAGES == NUM_DA_TTL_CHANNELS, "Unexpected channel count")
		Make/T/N=(MINIMUM_WAVE_SIZE, NUM_HEADSTAGES, 3) dfr:$newName/Wave=wv
	endif

	SetWaveDimLabel(wv, "Stimset;TTLStimset;StimsetAndClampMode", LAYERS)
	SetNumberInWaveNote(wv, "NeedsUpdate", 1)
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the channel selection wave for the databrowser or sweep browser
Function/WAVE GetChannelSelectionWave(dfr)
	DFREF dfr

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr wv = channelSelection

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(max(NUM_DA_TTL_CHANNELS, NUM_AD_CHANNELS, NUM_HEADSTAGES), 3) wv
	else
		Make/R/N=(max(NUM_DA_TTL_CHANNELS, NUM_AD_CHANNELS, NUM_HEADSTAGES), 3) dfr:channelSelection/Wave=wv

		// by default all channels are selected
		wv = 1
	endif

	SetDimLabel COLS, 0, DA       , wv
	SetDimLabel COLS, 1, AD       , wv
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
Function/Wave GetSweepBrowserMap(dfr)
	DFREF dfr

	variable versionOfNewWave = 1

	ASSERT(DataFolderExistsDFR(dfr), "Missing SweepBrowser DFR")

	WAVE/T/Z/SDFR=dfr wv = map
	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 4) dfr:map/Wave=wv
		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	endif

	SetDimLabel COLS, 0, FileName, wv
	SetDimLabel COLS, 1, DataFolder, wv
	SetDimLabel COLS, 2, Device, wv
	SetDimLabel COLS, 3, Sweep, wv

	SetNumberInWaveNote(wv, WAVE_NOTE_LAYOUT_KEY, versionOfNewWave)

	return wv
End

/// @name Getters related to debugging
/// @{
/// @brief Return the datafolder reference to the debug folder
Function/DF GetDebugPanelFolder()
	return createDFWithAllParents(GetDebugPanelFolderAS())
End

/// @brief Return the full path to the debug datafolder, e.g. root:MIES:Debug
Function/S GetDebugPanelFolderAS()
	return GetMiesPathAsString() + ":Debug"
End

/// @brief Return the list wave for the debug panel
Function/WAVE GetDebugPanelListWave()

	variable versionOfNewWave = 1
	DFREF dfr = GetDebugPanelFolder()
	WAVE/T/Z/SDFR=dfr wv = fileSelectionListWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(MINIMUM_WAVE_SIZE) dfr:fileSelectionListWave/WAVE=wv
	endif

	return wv
End

/// @brief Return the list selection wave for the debugging panel
Function/WAVE GetDebugPanelListSelWave()

	variable versionOfNewWave = 1
	DFREF dfr = GetDebugPanelFolder()
	WAVE/B/Z/SDFR=dfr wv = fileSelectionListSelWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/B/N=(MINIMUM_WAVE_SIZE) dfr:fileSelectionListSelWave/WAVE=wv
	endif

	return wv
End
/// @}

/// @name AnalysisFunctionGetters Getters used by analysis functions
/// @{

/// @brief Return a wave reference which holds an headstage-dependent index
///
/// Can be used by analysis function to count the number of invocations.
Function/WAVE GetAnalysisFuncIndexingHelper(panelTitle)
	string panelTitle

	variable versionOfNewWave = 1
	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = analysisFuncIndexing

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
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
Function/WAVE GetAnalysisFuncDAScaleDeltaV(panelTitle)
	string panelTitle

	variable versionOfNewWave = 1
	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = analysisFuncDAScaleDeltaV

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
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
Function/WAVE GetAnalysisFuncDAScaleDeltaI(panelTitle)
	string panelTitle

	variable versionOfNewWave = 1
	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = analysisFuncDAScaleDeltaI

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
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
Function/WAVE GetAnalysisFuncDAScaleRes(panelTitle)
	string panelTitle

	variable versionOfNewWave = 1
	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = analysisFuncDAScaleRes

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(NUM_HEADSTAGES, 2) dfr:analysisFuncDAScaleRes/WAVE=wv
		wv = NaN
	endif

	SetScale d, 0, 0, "Ohm", wv
	SetDimLabel COLS, 0, Value, wv
	SetDimLabel COLS, 1, Error, wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the fitted resistance wave created by `CurveFit`
///
/// Used by PSQ_AdjustDAScale().
Function/WAVE GetAnalysisFuncDAScaleResFit(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable versionOfNewWave = 1
	string name

	DFREF dfr = GetDevicePath(panelTitle)
	name = "analysisFuncDAScaleResFit" + "_" + num2str(headstage)

	WAVE/D/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(2) dfr:$name/WAVE=wv
		wv = NaN
	endif

	SetScale d, 0, 0, "Ohm", wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave reference to the spikes frequency wave
///
/// Used by PSQ_AdjustDAScale().
Function/WAVE GetAnalysisFuncDAScaleSpikeFreq(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable versionOfNewWave = 1
	string name

	DFREF dfr = GetDevicePath(panelTitle)
	name = "analysisFuncDAScaleSpikeFreq" + "_" + num2str(headstage)

	WAVE/D/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
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
Function/WAVE GetAnalysisFuncDAScaleFreqFit(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable versionOfNewWave = 1
	string name

	DFREF dfr = GetDevicePath(panelTitle)
	name = "analysisFuncDAScaleFreqFit" + "_" + num2str(headstage)

	WAVE/D/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
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
Function/WAVE GetAnalysisFuncDAScales(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable versionOfNewWave = 1
	string name

	DFREF dfr = GetDevicePath(panelTitle)
	name = "analysisFuncDAScales" + "_" + num2str(headstage)

	WAVE/D/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(0) dfr:$name/WAVE=wv
	endif

	SetScale d, 0, 0, "A", wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @}

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
Function/WAVE GetAnalysisFunctionStorage(panelTitle)
	string panelTitle

	variable versionOfWave = 4
	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/T/Z/SDFR=dfr wv = analysisFunctions

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	elseif(WaveExists(wv))
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
/// Cols:
/// - PRE_SET_EVENT
/// - POST_SET_EVENT
Function/WAVE GetSetEventFlag(panelTitle)
	string panelTitle

	variable versionOfWave = 1
	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = setEventFlag

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	elseif(WaveExists(wv))
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
Function/WAVE GetRAPerfWave(panelTitle)
	string panelTitle

	variable versionOfWave = 1
	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = perfingRA

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	elseif(WaveExists(wv))
		 // handle upgrade
	else
		Make/D/N=(MINIMUM_WAVE_SIZE) dfr:perfingRA/WAVE=wv
	endif

	wv = NaN
	SetScale d, 0, inf, "s", wv

	SetWaveVersion(wv, versionOfWave)

	return wv

End

/// @brief Return the list wave for the analysis parameter GUI
Function/WAVE WBP_GetAnalysisParamGUIListWave()

	variable versionOfWave = 3
	DFREF dfr = GetWaveBuilderDataPath()
	WAVE/T/Z/SDFR=dfr wv = analysisGUIListWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	elseif(WaveExists(wv))
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

	variable versionOfWave = 1
	DFREF dfr = GetWaveBuilderDataPath()
	WAVE/B/Z/SDFR=dfr wv = analysisGUISelWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfWave))
		return wv
	endif

	Make/B/N=(0) dfr:analysisGUISelWave/WAVE=wv

	SetWaveVersion(wv, versionOfWave)

	return wv
End

/// @brief Return the help wave for the analysis parameter GUI
Function/WAVE WBP_GetAnalysisParamGUIHelpWave()

	variable versionOfWave = 1
	DFREF dfr = GetWaveBuilderDataPath()
	WAVE/T/Z/SDFR=dfr wv = analysisGUIHelpWave

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
Function/WAVE GetAnaFuncDashboardListWave(dfr)
	DFREF dfr

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/T/Z/SDFR=dfr wv = dashboardListWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 4) wv
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 4) dfr:dashboardListWave/Wave=wv
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
Function/WAVE GetAnaFuncDashboardInfoWave(dfr)
	DFREF dfr

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/T/Z/SDFR=dfr wv = dashboardInfoWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 3) dfr:dashboardInfoWave/Wave=wv
	endif

	SetDimLabel COLS, 0, $STIMSET_ACQ_CYCLE_ID_KEY, wv
	SetDimLabel COLS, 1, $"Passing Sweeps", wv
	SetDimLabel COLS, 2, $"Failing Sweeps", wv

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the analysis function dashboard listbox selection wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetAnaFuncDashboardSelWave(dfr)
	DFREF dfr

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/B/Z/SDFR=dfr wv = dashboardSelWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(-1, 4, -1) wv
	else
		Make/B/N=(MINIMUM_WAVE_SIZE, 4, 2) dfr:dashboardSelWave/Wave=wv
	endif

	SetDimLabel LAYERS, 1, foreColors, wv
	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the analysis function dashboard listbox color wave for the
///        databrowser or the sweepbrowser
Function/WAVE GetAnaFuncDashboardColorWave(dfr)
	DFREF dfr

	variable versionOfNewWave = 2

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/W/U/Z/SDFR=dfr wv = dashboardColorWave

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		Redimension/N=(4, -1) wv
	else
		Make/W/U/N=(4, 3) dfr:dashboardColorWave/Wave=wv
	endif

	wv[0][0]= {0, 65535, 0}
	wv[0][1]= {0, 0,     35000}
	wv[0][2]= {0, 0,     0}

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave with device information
Function/WAVE GetDeviceInfoWave(panelTitle)
	string panelTitle

	variable versionOfNewWave = 1

	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/D/Z/SDFR=dfr wv = deviceInfo

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(5) dfr:deviceInfo/Wave=wv
	endif

	SetDimLabel ROWS, 0, AD, wv
	SetDimLabel ROWS, 1, DA, wv
	SetDimLabel ROWS, 2, TTL, wv
	SetDimLabel ROWS, 3, Rack, wv
	SetDimLabel ROWS, 4, HardwareType, wv

	wv = NaN

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return a wave suitable for storing elapsed time
///
/// Helper function for DEBUGPRINT_ELAPSED_WAVE() and StoreElapsedTime().
Function/WAVE GetElapsedTimeWave()

	variable versionOfNewWave = 1

	DFREF dfr = GetTempPath()
	WAVE/D/Z/SDFR=dfr wv = elapsedTime

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/D/N=(MINIMUM_WAVE_SIZE) dfr:elapsedTime/Wave=wv
	endif

	wv = NaN

	SetScale d, 0, 0, "s", wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the X wave for the sweep formula
Function/WAVE GetSweepFormulaX(dfr)
	DFREF dfr

	WAVE/Z/D/SDFR=dfr wv = sweepFormulaX

	if(WaveExists(wv))
		return wv
	endif

	Make/N=0/D dfr:sweepFormulaX/Wave=wv

	return wv
End

/// @brief Return the Y wave for the sweep formula
Function/WAVE GetSweepFormulaY(dfr)
	DFREF dfr

	WAVE/Z/D/SDFR=dfr wv = sweepFormulaY

	if(WaveExists(wv))
		return wv
	endif

	Make/N=0/D dfr:sweepFormulaY/Wave=wv

	return wv
End

/// @brief Return the global temporary wave for extended popup menu
Function/WAVE GetPopupExtMenuWave()

	variable versionOfNewWave = 1
	DFREF dfr = GetMiesPath()
	WAVE/T/Z/SDFR=dfr wv = popupExtMenuInfo

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
		// handle upgrade
	else
		Make/T/N=1 dfr:popupExtMenuInfo/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End

/// @brief Return the reference to the graph user data datafolder as string
Function/S GetGraphUserDataFolderAsString()

	return GetMiesPathAsString() + ":GraphUserData"
End

/// @brief Return the reference to the graph user data datafolder
Function/DF GetGraphUserDataFolderDFR()

	return createDFWithAllParents(GetGraphUserDataFolderAsString())
End

/// @brief Return the text wave for the graph user data
///
/// @param graph existing graph
Function/WAVE GetGraphUserData(string graph)

	variable versionOfNewWave = 1
	DFREF dfr = GetGraphUserDataFolderDFR()
	string name = graph + "_wave"
	WAVE/T/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
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
/// col 0 trace names of all average traces
/// col 1 trace names of all deconvolution traces
/// col 2 list of used image names
Function/WAVE GetPAGraphData()

	variable versionOfNewWave = 1
	DFREF dfr = GetGraphUserDataFolderDFR()
	string name = "PAGraphData"
	WAVE/T/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv))
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
	wName = PA_AVERAGE_WAVE_PREFIX + baseName
	WAVE/Z avg = dfr:$wName

	return [avg, baseName]
End
