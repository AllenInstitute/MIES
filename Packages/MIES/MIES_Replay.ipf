#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_RD
#endif // AUTOMATED_TESTING

/// @file MIES_Replay.ipf
/// @brief __RD__ Replay data feature for advanced debugging

#ifdef REPLAY_DATA

Function RD_PrepareMIES()

	ASSERT(!DataFolderExists(GetReplayStorageAsString()), "Backup already exists")

	DFREF src = GetMiesPath()

	RenameDataFolder src, MIES_replay
End

/// @brief Replay the already acquired data of device starting from sweepNo
Function RD_ReplayData(string device, variable refSweepNo)

	string folder, path, unlockedDevice
	variable sweepNo

	DAP_UnlockAllDevices()
	KillWindows(WinList("*", ";", "WIN:64"))
	KillWindows(WinList("*", ";", "WIN:1"))
	KillWindows(WinList("*", ";", "WIN:2"))

	ASSERT(DataFolderExists(GetReplayStorageAsString()), "no replay folder to work with, call RD_PrepareMIES() before.")

	DFREF dfr = GetMiesPath()
	KilldataFolder/Z dfr
	DFREF dfr = GetMiesPath()

	RD_Enable()

	NVAR refSweepNoGlobal = $GetReplayRefSweep()
	refSweepNoGlobal = refSweepNo

	Make/FREE/T folders = {"LabNotebook", "WaveBuilder", "Cache"}

	for(folder : folders)
		path = GetReplayStorageAsString() + ":" + folder
		DFREF src = $path
		DuplicateDataFolder src, dfr
	endfor

	// copy raw data
	path = GetDeviceDataPathAsString(device)
	path = RD_TranslateToReplay(str = path)
	DFREF src = $path
	DFREF dfr = GetDevicePath(device)
	DuplicateDataFolder src, dfr

	// deep copy cache hashmap
	if(WaveExists(root:MIES:Cache:hashmap))
		WAVE hashmap_deep = DeepcopyWaveRefWave(root:MIES:Cache:hashmap)
		Duplicate/O hashmap_deep, root:MIES:Cache:hashmap
	endif

	CA_DeleteCacheEntry(CA_AmplifierHardwareWavesKey())

	CA_DeleteCacheEntry(CA_DACDevicesKey(HARDWARE_ITC_DAC))
	CA_DeleteCacheEntry(CA_DACDevicesKey(HARDWARE_NI_DAC))
	CA_DeleteCacheEntry(CA_DACDevicesKey(HARDWARE_SUTTER_DAC))

	DFREF deviceData = GetDeviceDataPath(device)
	ASSERT(!IsDataFolderEmpty(deviceData), "Can't work without data")
	ASSERT(WaveExists(GetSweepWave(device, refSweepNo)), "Missing data for sweepNo: " + num2str(refSweepNo))

	// now delete all acquired data with sweep >= refSweepNo
	WAVE sweeps = AFH_GetSweeps(device)

	for(sweepNo : sweeps)
		if(sweepNo < refSweepNo)
			continue
		endif

		WAVE/Z sweep = GetSweepWave(device, sweepNo)
		WAVE/Z wv    = GetBackupWave(sweep)
		KillOrMoveToTrash(wv = wv)

		WAVE/Z config = GetConfigWave(sweep)
		WAVE/Z wv     = GetBackupWave(config)
		KillOrMoveToTrash(wv = wv)

		KillOrMoveToTrash(wv = sweep)
		KillOrMoveToTrash(wv = config)

		DFREF dfr = GetSingleSweepFolder(deviceData, sweepNo)
		KillOrMoveToTrash(dfr = dfr)
	endfor

	InvalidateLBIndexAndRowCachesForDevice(device)

	RD_ApplySettingsFromPreviousSweep(device, refSweepNo)

	// and data for sweep >= refSweepNo from the labnotebooks
	WAVE values = GetLBnumericalValues(device)
	RD_DeleteLabnotebookEntries(values, refSweepNo)

	WAVE values = GetLBtextualValues(device)
	RD_DeleteLabnotebookEntries(values, refSweepNo)

	// remove data which is stale:
	// - labnotebook temp datafolder and hashmaps (numeric and text)
	// - testpulse
	DFREF dfr = GetDevSpecLabNBTempFolder(device)
	KillOrMoveToTrash(dfr = dfr)

	WAVE values = GetLBnumericalValues(device)
	WAVE wv     = GetLogbookKeyHashmap(values)
	KillOrMoveToTrash(wv = wv)

	WAVE values = GetLBtextualValues(device)
	WAVE wv     = GetLogbookKeyHashmap(values)
	KillOrMoveToTrash(wv = wv)

	DFREF dfr = GetDeviceTestPulse(device)
	KillOrMoveToTrash(dfr = dfr)

	DoUpdate/W=$device

	TP_UpdateTPSettingsCalculated(device)

	PGC_SetAndActivateControl(device, "DataAcquireButton")
End

static Function/S RD_TranslateToReplay([WAVE wv, DFREF dfr, string str])

	string path

	ASSERT((ParamIsDefault(wv) + ParamIsDefault(dfr) + ParamIsDefault(str)) == 2, "Exactly one of wv/dfr/str must be supplied")

	if(!ParamIsDefault(wv))
		path = GetWavesDataFolder(wv, 2)
	elseif(!ParamIsDefault(dfr))
		path = GetDataFolder(1, dfr)
	elseif(!ParamIsDefault(str))
		path = str
	endif

	ASSERT(!isEmpty(path), "Can not use an empty path")

	return ReplaceString(GetMiesPathAsString(), path, GetReplayStorageAsString())
End

static Function RD_CompareSweeps(string device, WAVE sweeps)

	variable sweepNo

	WAVE   numericalValues = GetLBnumericalValues(device)
	WAVE/T textualValues   = GetLBtextualValues(device)

	printf "*** Evaluating sweep and LBN data ***\r"
	for(sweepNo : sweeps)
		printf "*** Sweep: %d ***\r", sweepNo
		RD_CompareSweepData(device, sweepNo)
		RD_CompareLabnotebooks(device, sweepNo)
	endfor
End

/// @brief Compare the labnotebook entries for `new` and `replay` of the given
///        device and sweep
Function RD_CompareLabnotebooks(string device, variable sweepNo)

	WAVE   numericalValues_new = GetLBnumericalValues(device)
	WAVE/T textualValues_new   = GetLBtextualValues(device)

	WAVE   numericalValues_replay = $RD_TranslateToReplay(wv = numericalValues_new)
	WAVE/T textualValues_replay   = $RD_TranslateToReplay(wv = textualValues_new)

	RD_CompareLabnotebooks_Impl(numericalValues_new, numericalValues_replay, sweepNo)
	RD_CompareLabnotebooks_Impl(textualValues_new, textualValues_replay, sweepNo)
End

/// @brief Compare the labnotebook entries and sweep data of `new` and `replay` of
///        the given device and all sweeps of the stimset cycle
Function RD_CompareSCI(string device, variable refSweepNo, variable headstage)

	WAVE   numericalValues = GetLBnumericalValues(device)
	WAVE/T textualValues   = GetLBtextualValues(device)

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, refSweepNo, headstage)

	if(!WaveExists(sweeps))
		print "Nothing to compare as no sweeps were found."
		return NaN
	endif

	RD_CompareSweeps(device, sweeps)
End

/// @brief Compare the labnotebook entries and sweep data for `new` and `replay` of
///        the given device and all sweeps of the repeated acquisition cycle
Function RD_CompareRAC(string device, variable refSweepNo)

	WAVE   numericalValues = GetLBnumericalValues(device)
	WAVE/T textualValues   = GetLBtextualValues(device)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, refSweepNo)

	if(!WaveExists(sweeps))
		print "Nothing to compare as no sweeps were found."
		return NaN
	endif

	RD_CompareSweeps(device, sweeps)
End

static Function RD_CompareLabnotebooks_Impl(WAVE values_new, WAVE values_replay, variable sweepNo)

	variable numCols, i
	string key_new, key_replay, key, str_new, str_replay

	numCols = DimSize(values_replay, COLS)

	Make/FREE/T keysToIgnore = {"TimeStamp",                                \
	                            "TimeStampSinceIgorEpochUTC",               \
	                            "EntrySourceType",                          \
	                            "High precision sweep start",               \
	                            "MIES version",                             \
	                            "Inter-trial interval (effective)",         \
	                            "Igor Pro version",                         \
	                            "Digitizer Serial Numbers",                 \
	                            "JSON config file [path]",                  \
	                            "JSON config file [SHA-256 hash]",          \
	                            "JSON config file [stimset nwb file path]", \
	                            "Igor Pro build",                           \
	                            "Serial Number"                             \
	                           }

	Make/FREE/T notYetOverridenKeys = {"Neut Cap Value",                \
	                                   "Bridge Bal Value",              \
	                                   "Pipette Offset",                \
	                                   "Slow current injection level",  \
	                                   "Autobias Ibias max",            \
	                                   "Async 2 Gain",                  \
	                                   "Async 3 Gain",                  \
	                                   "Epochs",                        \
	                                   "TP Baseline Vm",                \
	                                   "TP Peak Resistance",            \
	                                   "TP Steady State Resistance",    \
	                                   "TP Cycle ID",                   \
	                                   "I-Clamp Holding Enable",        \
	                                   "I-Clamp Holding Level",         \
	                                   "Fast compensation capacitance", \
	                                   "Slow compensation capacitance", \
	                                   "Fast compensation time",        \
	                                   "TP Baseline pA",                \
	                                   "V-Clamp Holding Level",         \
	                                   "Whole Cell Comp Cap",           \
	                                   "Whole Cell Comp Resist",        \
	                                   "Slow compensation time",        \
	                                   "Inter-trial interval",          \
	                                   "Neut Cap Enabled",              \
	                                   "Bridge Bal Enable",             \
	                                   "Device"}

	for(i = 0; i < numCols; i += 1)
		key_replay = GetDimLabel(values_replay, COLS, i)
		key_new    = GetDimLabel(values_new, COLS, i)
		ASSERT(!cmpstr(key_new, key_replay), "Mismatch in key names")
		key = key_new

		if(GetRowIndex(keysToIgnore, str = key) >= 0          \
		   || GetRowIndex(notYetOverridenKeys, str = key) >= 0)
			continue
		endif

		WAVE/Z settings_replay = GetLastSetting(values_replay, sweepNo, key, UNKNOWN_MODE)
		WAVE/Z settings_new    = GetLastSetting(values_new, sweepNo, key, UNKNOWN_MODE)

		if(!WaveExists(settings_replay) && !WaveExists(settings_new))
			continue
		endif

		if(EqualWaves(settings_replay, settings_new, 1, 1e-10))
			continue
		endif

		// post-process some keys
		if(!cmpstr(key, "Stim Wave Note"))
			WAVE/T settingsText = settings_replay

			settingsText[] = RemoveByKey("WP modification count ", settingsText[p], "=")
			settingsText[] = RemoveByKey("WPT modification count ", settingsText[p], "=")
			settingsText[] = RemoveByKey("SegWvType modification count ", settingsText[p], "=")

			WAVE/T settingsText = settings_new

			settingsText[] = RemoveByKey("WP modification count ", settingsText[p], "=")
			settingsText[] = RemoveByKey("WPT modification count ", settingsText[p], "=")
			settingsText[] = RemoveByKey("SegWvType modification count ", settingsText[p], "=")

			if(EqualWaves(settings_replay, settings_new, 1))
				continue
			endif
		endif

		str_replay = RD_SerializeLogbookEntry(settings_replay)
		str_new    = RD_SerializeLogbookEntry(settings_new)

		printf "%s: %s (replay) vs %s (new)\r", key_replay, str_replay, str_new
	endfor
End

static Function/S RD_SerializeLogbookEntry(WAVE/Z wv)

	if(!WaveExists(wv))
		return "(empty)"
	endif

	if(IsNumericWave(wv))
		return NumericWaveToList(ZapNaNs(wv), ";", trailSep = 0)
	endif

	ASSERT(IsTextWave(wv), "Expected a text wave")

	RemoveTextWaveEntry1D(wv, "", all = 1)
	return TextWaveToList(wv, ";", trailSep = 0)
End

static Function RD_CompareSweepData(string device, variable sweepNo)

	string name
	variable i, diffCount, numRows

	DFREF deviceDFR       = GetDeviceDataPath(device)
	DFREF sweepDFR_new    = GetSingleSweepFolder(deviceDFR, sweepNo)
	DFREF sweepDFR_replay = $RD_TranslateToReplay(dfr = sweepDFR_new)

	WAVE/T wvs = ListToTextWave(GetListOfObjects(sweepDFR_replay, ".*"), ";")

	for(name : wvs)
		WAVE/Z/SDFR=sweepDFR_replay wv_replay = $name
		WAVE/Z/SDFR=sweepDFR_new    wv_new    = $name

		ASSERT(WaveExists(wv_replay), "Missing wv_replay:" + name)
		ASSERT(WaveExists(wv_new), "Missing wv_new:" + name)

		if(EqualWaves(wv_new, wv_replay, EQWAVES_DATA, 1e-6))
			continue
		endif

		numRows = DimSize(wv_replay, ROWS)

		for(i = 0; i < numRows && diffCount < 10; i += 1)
			if(EqualValuesOrBothNaN(wv_replay[i], wv_new[i]))
				continue
			endif

			printf "Difference %s at %d: %.15g (replay) vs %.15g (new)\r", name, i, wv_replay[i], wv_new[i]
			diffCount += 1
		endfor
	endfor
End

static Function RD_ApplySettingsFromPreviousSweep(string device, variable sweepNo)

	variable overrideValue
	string   key

	WAVE   numericalValues = GetLBnumericalValues(device)
	WAVE/T textualValues   = GetLBtextualValues(device)

	STRUCT ACD_DAQSettings s

	s.MD      = GetLastSettingIndep(numericalValues, sweepNo, "Multi Device mode", DATA_ACQUISITION_MODE)
	s.RA      = GetLastSettingIndep(numericalValues, sweepNo, "Repeated Acquisition", DATA_ACQUISITION_MODE)
	s.IDX     = GetLastSettingIndep(numericalValues, sweepNo, "Indexing", DATA_ACQUISITION_MODE)
	s.LIDX    = GetLastSettingIndep(numericalValues, sweepNo, "Locked Indexing", DATA_ACQUISITION_MODE)
	s.BKG_DAQ = GetLastSettingIndep(numericalValues, sweepNo, "Background DAQ", DATA_ACQUISITION_MODE)
	s.RES     = GetLastSettingIndep(numericalValues, sweepNo, "Repeat Sets", DATA_ACQUISITION_MODE)
	s.DB      = 0
	s.AMP     = 1
	s.ITP     = GetLastSettingIndep(numericalValues, sweepNo, "TP Insert Checkbox", DATA_ACQUISITION_MODE)
	s.FAR     = 1
	s.oodDAQ  = GetLastSettingIndep(numericalValues, sweepNo, "Optimized Overlap dDAQ", DATA_ACQUISITION_MODE)
	s.dDAQ    = GetLastSettingIndep(numericalValues, sweepNo, "Distributed DAQ", DATA_ACQUISITION_MODE)
	s.OD      = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE)

	key           = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INIT_UOD, query = 1)
	overrideValue = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	if(IsFinite(overrideValue))
		s.OD = overrideValue
	endif

	s.TD  = GetLastSettingIndep(numericalValues, sweepNo, "Delay termination", DATA_ACQUISITION_MODE)
	s.TP  = 0
	s.ITI = GetLastSettingIndep(numericalValues, sweepNo, "Inter-trial interval", DATA_ACQUISITION_MODE)
	s.GSI = GetLastSettingIndep(numericalValues, sweepNo, "Get/Set Inter-trial interval", DATA_ACQUISITION_MODE)
	s.TPI = GetLastSettingIndep(numericalValues, sweepNo, "TP during ITI", DATA_ACQUISITION_MODE)
	s.DAQ = 0
	s.DDL = GetLastSettingIndep(numericalValues, sweepNo, "Delay distributed DAQ", DATA_ACQUISITION_MODE)
	s.SIM = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval multiplier", DATA_ACQUISITION_MODE)
	s.STP = 0
	s.TBP = GetLastSettingIndep(numericalValues, sweepNo, "TP Baseline Fraction", DATA_ACQUISITION_MODE) * ONE_TO_PERCENT
	s.TPD = GetLastSettingIndep(numericalValues, sweepNo, "TP Pulse Duration", DATA_ACQUISITION_MODE)
	s.FFR = num2str(GetLastSettingIndep(numericalValues, sweepNo, "Fixed frequency acquisition", UNKNOWN_MODE))
	s.TAD = GetLastSettingIndep(numericalValues, sweepNo, "TP After DAQ", DATA_ACQUISITION_MODE)

	if(!cmpstr(s.FFR, "NaN"))
		s.FFR = NONE
	endif

	WAVE s.hs = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)

	WAVE s.da = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)

	WAVE s.ad = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)
	WAVE s.cm = GetLastSetting(numericalValues, sweepNo, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)

	// @todo no support for TTL channels
	Make/FREE/N=(NUM_HEADSTAGES) s.ttl

	// @todo no support for unassociated channels
	Make/FREE/N=(NUM_HEADSTAGES) s.aso = 1
	WAVE/T s.st  = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	WAVE/T s.ist = GetLastSetting(textualValues, sweepNo, "Indexing End Stimset", DATA_ACQUISITION_MODE)

	WAVE s.dsc = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)

	// s.af/s.iaf not used as the analysis function attached to the stimset is used
	Make/T/FREE/N=(NUM_HEADSTAGES) s.af
	Make/T/FREE/N=(NUM_HEADSTAGES) s.iaf

	// @todo no support for TTL channels
	Make/T/FREE/N=(NUM_HEADSTAGES) s.st_ttl

	WAVE/Z s.ab  = GetLastSetting(numericalValues, sweepNo, "Autobias", DATA_ACQUISITION_MODE)
	WAVE/Z s.abv = GetLastSetting(numericalValues, sweepNo, "Autobias Vcom", DATA_ACQUISITION_MODE)
	WAVE/Z s.abr = GetLastSetting(numericalValues, sweepNo, "Autobias Vcom variance", DATA_ACQUISITION_MODE)

	Make/FREE/N=(NUM_ASYNC_CHANNELS) s.asyncAD, s.asyncALM
	Make/FREE/N=(NUM_ASYNC_CHANNELS)/D s.asyncAMI, s.asyncAMA, s.asyncGA

	Make/FREE/N=(NUM_ASYNC_CHANNELS)/T s.asyncTTE = "", s.asyncUN = ""

	s.asyncAD[]  = GetLastSettingIndep(numericalValues, sweepNo, "Async " + num2str(p) + " On/Off", DATA_ACQUISITION_MODE)
	s.asyncGA[]  = GetLastSettingIndep(numericalValues, sweepNo, "Async " + num2str(p) + " Gain", DATA_ACQUISITION_MODE)
	s.asyncALM[] = GetLastSettingIndep(numericalValues, sweepNo, "Async Alarm " + num2str(p) + " On/Off", DATA_ACQUISITION_MODE)
	s.asyncAMI[] = GetLastSettingIndep(numericalValues, sweepNo, "Async Alarm " + num2str(p) + " Min", DATA_ACQUISITION_MODE)
	s.asyncAMA[] = GetLastSettingIndep(numericalValues, sweepNo, "Async Alarm  " + num2str(p) + " Max", DATA_ACQUISITION_MODE)

	// @todo separate block which breaks LBN reading logic therefore we have to
	// use UNKNOWN_MODE, see https://github.com/AllenInstitute/MIES/issues/2721
	s.asyncTTE[] = GetLastSettingTextIndep(textualValues, sweepNo, "Async AD" + num2str(p) + " Title", UNKNOWN_MODE)
	s.asyncUN[]  = GetLastSettingTextIndep(textualValues, sweepNo, "Async AD" + num2str(p) + " Unit", UNKNOWN_MODE)

	WAVE/Z s.tai = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_IC_ENTRY_KEY, DATA_ACQUISITION_MODE)
	if(!WaveExists(s.tai))
		Make/FREE/N=(NUM_HEADSTAGES)/D s.tai = NaN
	endif

	WAVE/Z s.tav = GetLastSetting(numericalValues, sweepNo, TP_AMPLITUDE_VC_ENTRY_KEY, DATA_ACQUISITION_MODE)
	if(!WaveExists(s.tav))
		Make/FREE/N=(NUM_HEADSTAGES)/D s.tav = NaN
	endif

	ACD_AcquireData(s, device)
End

/// @brief Delete all labnotebook entries starting from sweepNo (including) to the end
static Function RD_DeleteLabnotebookEntries(WAVE values, variable sweepNo)

	variable sweepCol, row

	sweepCol = GetSweepColumn(values)

	WAVE/Z indizes = FindIndizes(values, col = sweepCol, var = sweepNo)
	ASSERT(WaveExists(indizes), "Could not find labnotebook entries for sweep:" + num2str(sweepNo))

	row = WaveMin(indizes)

	if(IsTextWave(values))
		WAVE/T valuesText = values
		valuesText[row, Inf][][] = ""
	else
		values[row, Inf][][] = NaN
	endif

	SetNumberInWaveNote(values, NOTE_INDEX, row)
End

Function RD_Enable()

	NVAR enable = $GetReplayDataEnable()

	enable = 1

	print "****************************************************************************************"
	print "Enabling replay data logic. All future data will be replayed and *not* freshly acquired."
	print "****************************************************************************************"
End

static Function RD_ExtractSingelValue(WAVE/Z wv)

	if(!WaveExists(wv))
		return NaN
	endif

	WAVE/Z indizes = FindIndizes(wv, prop = PROP_NOT | PROP_EMPTY)
	ASSERT(WaveExists(indizes) && DimSize(indizes, ROWS) == 1, "Expected exactly one active HS")

	return wv[indizes[0]]
End

/// @brief Return the replay settings
///
/// Can be returned only once when starting at the reference sweep or always. And either
/// for the current sweep of the next sweep.
///
/// @param device device
/// @param mode, one of @ref ReplaySettingsMode
/// @param sweepSelector, one of @ref ReplaySettingsSelector
Function/WAVE RD_GetReplaySettings(string device, variable mode, variable sweepSelector)

	variable sweepNo, offset
	string key

	WAVE/Z sweeps = AFH_GetSweeps(device)

	switch(sweepSelector)
		case RD_SWEEP_SELECTOR_CURRENT:
			offset = 0
			break
		case RD_SWEEP_SELECTOR_NEXT:
			offset = 1
			break
		default:
			FATAL_ERROR("Unsupported sweepSelector")
	endswitch

	sweepNo = WaveExists(sweeps) ? (WaveMax(sweeps) + offset) : 0

	if(mode == RD_MODE_ONCE && sweepNo > RoVar(GetReplayRefSweep()))
		return $""
	endif

	WAVE   numericalValues_replay = $RD_TranslateToReplay(wv = GetLBnumericalValues(device))
	WAVE/T textualValues_replay   = $RD_TranslateToReplay(wv = GetLBtextualValues(device))

	WAVE settings = GetReplaySettings()

	settings[%RAC] = GetLastSettingIndep(numericalValues_replay, sweepNo, RA_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE)

	WAVE/Z stimsetCycleIDs = GetLastSetting(numericalValues_replay, sweepNo, STIMSET_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE)
	settings[%SCI] = RD_ExtractSingelValue(stimsetCycleIDs)

	WAVE/Z setSweepCount = GetLastSetting(numericalValues_replay, sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)
	settings[%SetColumn] = RD_ExtractSingelValue(setSweepCount)

	WAVE/Z setCycleCount = GetLastSetting(numericalValues_replay, sweepNo, "Set Cycle Count", DATA_ACQUISITION_MODE)
	settings[%SetCycleCount] = RD_ExtractSingelValue(setCycleCount)

	WAVE/Z stimScaleFactor = GetLastSetting(numericalValues_replay, sweepNo, "Stim Scale Factor", DATA_ACQUISITION_MODE)
	settings[%StimScaleFactor] = RD_ExtractSingelValue(stimScaleFactor)

	settings[%AsyncAD0] = RD_GetAsyncValue(numericalValues_replay, textualValues_replay, sweepNo, 0)
	settings[%AsyncAD1] = RD_GetAsyncValue(numericalValues_replay, textualValues_replay, sweepNo, 1)
	settings[%AsyncAD2] = RD_GetAsyncValue(numericalValues_replay, textualValues_replay, sweepNo, 2)
	settings[%AsyncAD3] = RD_GetAsyncValue(numericalValues_replay, textualValues_replay, sweepNo, 3)
	settings[%AsyncAD4] = RD_GetAsyncValue(numericalValues_replay, textualValues_replay, sweepNo, 4)
	settings[%AsyncAD5] = RD_GetAsyncValue(numericalValues_replay, textualValues_replay, sweepNo, 5)
	settings[%AsyncAD6] = RD_GetAsyncValue(numericalValues_replay, textualValues_replay, sweepNo, 6)
	settings[%AsyncAD7] = RD_GetAsyncValue(numericalValues_replay, textualValues_replay, sweepNo, 7)

	return settings
End

static Function RD_GetAsyncValue(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channel)

	string key, title

	// UNKNOWN_MODE because of https://github.com/AllenInstitute/MIES/issues/2721
	sprintf key, "Async AD%d Title", channel
	title = GetLastSettingTextIndep(textualValues, sweepNo, key, UNKNOWN_MODE)

	sprintf key, "Async AD %d [%s]", channel, title
	return GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
End

// Transfer data back from sweep data into DAQDataWave
Function RD_UpdateData(string device, WAVE allGain, WAVE dataWave, variable fifoPosGlobal, variable fifoPos)

	variable sweepNo, numRows, chan, i, fifoEndWritePos, clearBefore, err

	WAVE/Z sweeps = AFH_GetSweeps(device)

	clearBefore = (fifoPosGlobal == 0) && (IsInf(fifoPos))

	fifoEndWritePos = fifoPos - 1

	sweepNo = WaveExists(sweeps) ? (WaveMax(sweeps) + 1) : 0

	WAVE   numericalValues = GetLBnumericalValues(device)
	WAVE/T textualValues   = GetLBtextualValues(device)

	DFREF deviceDFR = GetDeviceDataPath(device)
	DFREF sweepDFR  = $RD_TranslateToReplay(dfr = GetSingleSweepFolder(deviceDFR, sweepNo))

	WAVE config = GetDAQConfigWave(device)

	numRows = DimSize(config, ROWS)

	for(i = 0; i < numRows; i += 1)
		if(config[i][%ChannelType] != XOP_CHANNEL_TYPE_ADC)
			continue
		endif

		chan = config[i][%ChannelNumber]
		WAVE/Z singleAD_replay = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_ADC, chan)
		ASSERT(WaveExists(singleAD_replay), "Expected an existing single AD wave from the replay dataset")

		if(clearBefore)
			if(IsWaveRefWave(dataWave))
				WAVE singleWave = WaveRef(dataWave, row = i)
				singleWave[] = NaN
			else
				FATAL_ERROR("Unsupported wave type")
			endif
		endif

		if(fifoPosGlobal >= DimSize(singleAD_replay, ROWS))
			continue
		endif

		fifoEndWritePos = limit(fifoEndWritePos, 0, DimSize(singleAD_replay, ROWS) - 1)

		if(IsWaveRefWave(dataWave))
			WAVE singleWave = WaveRef(dataWave, row = i)
			singleWave[fifoPosGlobal, fifoEndWritePos] = singleAD_replay[p] * allGain[i]
		else
			dataWave[fifoPosGlobal, fifoEndWritePos][i] = singleAD_replay[p] * allGain[i]
		endif
	endfor
End

#endif // REPLAY_DATA
