#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=LBNEntrySourceTypeHandling

static Function TEST_CASE_END_OVERRIDE(string testname)

	KillDataFolder/Z $LOGBOOK_WAVE_TEMP_FOLDER
	KillWaves/Z $LBN_NUMERICAL_VALUES_NAME, $LBN_NUMERICAL_KEYS_NAME, $LBN_TEXTUAL_VALUES_NAME, $LBN_TEXTUAL_KEYS_NAME
	TestCaseEndCommon(testname)
End

static Function/WAVE PrepareLBNNumericalValues(WAVE numericalValuesSrc)

	variable numCols

	WAVE/T numericalKeysTemplate = GetLBNumericalKeys("dummyDevice")
	numCols = DimSize(numericalValuesSrc, COLS)
	Redimension/N=(-1, numCols, -1, -1) numericalKeysTemplate
	numericalKeysTemplate[0][] = GetDimLabel(numericalValuesSrc, COLS, q)

	Duplicate/O numericalValuesSrc, $LBN_NUMERICAL_VALUES_NAME
	Duplicate/O numericalKeysTemplate, $LBN_NUMERICAL_KEYS_NAME

	return $LBN_NUMERICAL_VALUES_NAME
End

static Function/WAVE PrepareLBNTextualValues(WAVE textualValuesSrc)

	variable numCols

	WAVE/T textualKeysTemplate = GetLBTextualKeys("dummyDevice")
	numCols = DimSize(textualValuesSrc, COLS)
	Redimension/N=(-1, numCols, -1, -1) textualKeysTemplate
	textualKeysTemplate[0][] = GetDimLabel(textualValuesSrc, COLS, q)

	Duplicate/O textualValuesSrc, $LBN_TEXTUAL_VALUES_NAME
	Duplicate/O textualKeysTemplate, $LBN_TEXTUAL_KEYS_NAME

	return $LBN_TEXTUAL_VALUES_NAME
End

/// GetLastSetting with numeric wave
/// @{
Function GetLastSettingEntrySourceTypes()

	DFREF dfr = root:LB_Entrysourcetype_data:

	// current format with entrySourceType
	WAVE/SDFR=dfr numericalValuesSrc = dfr:numericalValues
	WAVE          numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)
	WAVE          DAQSettings        = GetLastSetting(numericalValues, 12, "DAC", DATA_ACQUISITION_MODE)
	WAVE          TPSettings         = GetLastSetting(numericalValues, 12, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings, {NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// two rows testpulse format
	WAVE/SDFR=dfr numericalValues_old
	WAVE   numericalValues = PrepareLBNNumericalValues(numericalValues_old)
	WAVE/Z DAQSettings     = GetLastSetting(numericalValues, 12, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings      = GetLastSetting(numericalValues, 12, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings, {NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// single row testpulse format before dd49bf
	WAVE/SDFR=dfr numericalValues_pre_dd49bf
	WAVE   numericalValues = PrepareLBNNumericalValues(numericalValues_pre_dd49bf)
	WAVE/Z DAQSettings     = GetLastSetting(numericalValues, 11, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings      = GetLastSetting(numericalValues, 11, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings, {NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/SDFR=dfr numericalValues_no_type_no_TP
	WAVE   numericalValues = PrepareLBNNumericalValues(numericalValues_no_type_no_TP)
	WAVE/Z DAQSettings     = GetLastSetting(numericalValues, 0, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings      = GetLastSetting(numericalValues, 0, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_WAVE(TPSettings, NULL_WAVE)

	// contains two times sweep 0, created with sweep rollback
	WAVE/SDFR=dfr numericalValues_with_sweep_rb
	WAVE   numericalValues = PrepareLBNNumericalValues(numericalValues_with_sweep_rb)
	WAVE/Z DAQSettings     = GetLastSetting(numericalValues, 0, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings      = GetLastSetting(numericalValues, 0, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings, {1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// contains two times sweep 73, created with sweep rollback and a trailing TP
	// and does not have entry source type information
	WAVE/SDFR=dfr numericalValues_no_type_with_sweep_rb_with_tp
	WAVE   numericalValues = PrepareLBNNumericalValues(numericalValues_no_type_with_sweep_rb_with_tp)
	WAVE/Z DAQSettings     = GetLastSetting(numericalValues, 73, "DAC", DATA_ACQUISITION_MODE)

	WAVE/Z TPSettings = GetLastSetting(numericalValues, 73, "DAC", TEST_PULSE_MODE)
	CHECK_WAVE(TPSettings, NULL_WAVE)

	WAVE/Z TPSettings = GetLastSetting(numericalValues, 73, "TP Steady State Resistance", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings, {119.7, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 0.1)

	// no entry source type and two trailing TP entries
	WAVE/SDFR=dfr numericalValues_no_type_with_two_tp_entries
	WAVE   numericalValues = PrepareLBNNumericalValues(numericalValues_no_type_with_two_tp_entries)
	WAVE/Z DAQSettings     = GetLastSetting(numericalValues, 0, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings      = GetLastSetting(numericalValues, 0, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// this entry is treated as TP
	WAVE/Z DAQSettings = GetLastSetting(numericalValues, 0, "TP Steady State Resistance", DATA_ACQUISITION_MODE)
	CHECK_WAVE(DAQSettings, NULL_WAVE)
End

Function GetLastSettingFindCaseInsensitive()

	DFREF dfr = root:LB_Entrysourcetype_data:

	// current format with entrySourceType
	WAVE/SDFR=dfr numericalValuesSrc = dfr:numericalValues
	WAVE          numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)
	WAVE/Z        DAQSettingsUC      = GetLastSetting(numericalValues, 12, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z        DAQSettingsLC      = GetLastSetting(numericalValues, 12, "dac", DATA_ACQUISITION_MODE)
	CHECK_WAVE(DAQSettingsUC, NUMERIC_WAVE)
	CHECK_WAVE(DAQSettingsLC, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DAQSettingsLC, DAQSettingsUC)
End

Function GetLastSettingAbortsInvalid1()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	variable first = LABNOTEBOOK_GET_RANGE

	try
		MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(numericalValues, NaN, "My Key", UNKNOWN_MODE, first = first)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingAbortsInvalid2()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	variable last = LABNOTEBOOK_GET_RANGE

	try
		MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(numericalValues, NaN, "My Key", UNKNOWN_MODE, last = last)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingAbortsInvalid3()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	variable first = -10
	variable last  = -10

	try
		MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(numericalValues, NaN, "My Key", UNKNOWN_MODE, first = first, last = last)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingEmptyUnknown()

	variable first, last

	DFREF         dfr                = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValuesSrc = numericalValues
	WAVE          numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)

	WAVE/Z settings = GetLastSetting(numericalValues, NaN, "I DONT EXIST", UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(numericalValues, NaN, "I DONT EXIST", UNKNOWN_MODE, first = first, last = last)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingFindsNaNSweep()

	DFREF dfr = root:Labnotebook_misc:

	// check that we can find the first entries of the testpulse which have sweepNo == NaN
	WAVE/SDFR=dfr numericalValues_nan_sweep
	WAVE   numericalValues = PrepareLBNNumericalValues(numericalValues_nan_sweep)
	WAVE/Z settings        = GetLastSetting(numericalValues, NaN, "TP Steady State Resistance", TEST_PULSE_MODE)

	Make/D/FREE settingsRef = {10.0010900497437, 10.001935005188, NaN, NaN, NaN, NaN, NaN, NaN, NaN}
	CHECK_EQUAL_WAVES(settings, settingsRef, mode = WAVE_DATA, tol = 1e-13)
End

static Function GetLastSettingFindsWithinNonConsecutiveSweepOrder()

	string   key
	variable chunkPassed
	variable sweepNo = 41
	DFREF    dfr     = root:Labnotebook_misc:

	WAVE/SDFR=dfr numericalValuesTest

	WAVE numericalValues = PrepareLBNNumericalValues(numericalValuesTest)
	key         = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_CHUNK_PASS, chunk = 0, query = 1)
	chunkPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE, defValue = NaN)
	CHECK_EQUAL_VAR(chunkPassed, 0)
End

Function GetLastSettingQueryWoMatch()

	variable first, last

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	// sweep is unknown
	WAVE/Z settings = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(numericalValues, 100, "DA unit", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingWorks()

	variable first, last
	variable firstAgain, lastAgain

	DFREF         dfr                = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValuesSrc = numericalValues

	WAVE   numericalValues = PrepareLBNNumericalValues(numericalValuesSrc)
	WAVE/Z settings        = GetLastSetting(numericalValues, 10, "DAC", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(numericalValues, 10, "DAC", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_GE_VAR(first, 0)
	CHECK_GE_VAR(last, 0)

	firstAgain = first
	lastAgain  = last
	WAVE/Z settingsAgain = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(numericalValues, 10, "DAC", DATA_ACQUISITION_MODE, first = firstAgain, last = lastAgain)
	CHECK_EQUAL_WAVES(settings, settingsAgain, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(first, firstAgain)
	CHECK_EQUAL_VAR(last, lastAgain)
End
/// @}

/// GetLastSetting with textual wave
/// @{

Function GetLastSettingTextAborts1()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValues

	variable first = LABNOTEBOOK_GET_RANGE

	try
		MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(textualValues, NaN, "My Key", UNKNOWN_MODE, first = first)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingTextAborts2()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValues

	variable last = LABNOTEBOOK_GET_RANGE

	try
		MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(textualValues, NaN, "My Key", UNKNOWN_MODE, last = last)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingTextAborts3()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValues

	variable first = -10
	variable last  = -10

	try
		MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(textualValues, NaN, "My Key", UNKNOWN_MODE, first = first, last = last)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingTextEmptyUnknown()

	variable first, last

	DFREF         dfr              = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValuesSrc = textualValues

	WAVE   textualValues = PrepareLBNTextualValues(textualValuesSrc)
	WAVE/Z settings      = GetLastSetting(textualValues, NaN, "I DONT EXIST", UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(textualValues, NaN, "I DONT EXIST", UNKNOWN_MODE, first = first, last = last)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingTextQueryWoMatch()

	variable first, last

	DFREF         dfr              = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValuesSrc = textualValues
	WAVE/T        textualValues    = PrepareLBNTextualValues(textualValuesSrc)

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	// sweep is unknown
	WAVE/Z settings = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(textualValues, 100, "DA unit", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingTextWorks()

	variable first, last
	variable firstAgain, lastAgain

	DFREF         dfr              = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValuesSrc = textualValues
	WAVE          textualValues    = PrepareLBNTextualValues(textualValuesSrc)

	WAVE/Z settings = GetLastSetting(textualValues, 1, "DA unit", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(textualValues, 1, "DA unit", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_GE_VAR(first, 0)
	CHECK_GE_VAR(last, 0)

	firstAgain = first
	lastAgain  = last
	WAVE/Z settingsAgain = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(textualValues, 1, "DA unit", DATA_ACQUISITION_MODE, first = firstAgain, last = lastAgain)
	CHECK_EQUAL_WAVES(settings, settingsAgain, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(first, firstAgain)
	CHECK_EQUAL_VAR(last, lastAgain)
End

/// @}

/// GetLastSweepWithSetting
/// @{
Function GetLastSWSWorksWithIndep()

	DFREF dfr = root:Labnotebook_misc
	WAVE/SDFR=dfr numericalValues_large

	variable sweepNo
	WAVE numericalValues = PrepareLBNNumericalValues(numericalValues_large)

	WAVE/Z settings = GetLastSweepWithSetting(numericalValues, "TP Pulse Duration", sweepNo)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK(IsValidSweepNumber(sweepNo))
	CHECK_EQUAL_VAR(settings[INDEP_HEADSTAGE], 104)
End

/// @}

/// GetLastSweepWithSettingText
/// @{
Function GetLastSWSTextWorksWithIndep()

	DFREF         dfr              = root:Labnotebook_misc
	WAVE/SDFR=dfr textualValuesSrc = textualValues

	variable sweepNo
	string   miesVersion

	WAVE/T   textualValues = PrepareLBNTextualValues(textualValuesSrc)
	WAVE/Z/T settings      = GetLastSweepWithSettingText(textualValues, "MIES Version", sweepNo)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK(IsValidSweepNumber(sweepNo))
	miesVersion = settings[INDEP_HEADSTAGE]
	CHECK_PROPER_STR(miesVersion)
End

/// @}

Function LBNCache_InvalidSweep()

	variable sweepNo            = 1000
	WAVE     numericalValuesSrc = root:Labnotebook_CacheTest:numericalValues
	WAVE     numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NULL_WAVE)

	WAVE indexWave = GetLBIndexCache(numericalValues)
	CHECK_EQUAL_VAR(indexWave[sweepNo][FindDimLabel(numericalValues, COLS, "DAC")][EntrySourceTypeMapper(DATA_ACQUISITION_MODE)], LABNOTEBOOK_MISSING_VALUE)
End

Function LBNCache_InvalidKey()

	variable sweepNo            = 10
	WAVE     numericalValuesSrc = root:Labnotebook_CacheTest:numericalValues
	WAVE     numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "I DONT EXIST", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
End

Function LBN_CacheCorrectSourceTypes1()

	variable index
	variable sweepNo = 1

	WAVE numericalValuesSrc = root:Labnotebook_CacheTest:numericalValues
	WAVE numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)

	index = FindDimlabel(numericalValues, COLS, "DAC")

	WAVE indexWave = GetLBIndexCache(numericalValues)
	WAVE rowWave   = GetLBRowCache(numericalValues)

	Duplicate/FREE indexWave, indexWavePlain
	Duplicate/FREE rowWave, rowWavePlain

	matrixop/FREE indexWavePlain = replace(indexWave, LABNOTEBOOK_UNCACHED_VALUE, NaN)
	WaveStats/Q/M=1 indexWavePlain
	CHECK_EQUAL_VAR(V_npnts, 0)

	matrixop/FREE rowWavePlain = replace(rowWavePlain, LABNOTEBOOK_GET_RANGE, NaN)
	WaveStats/Q/M=1 rowWavePlain
	CHECK_EQUAL_VAR(V_npnts, 0)

	Make/FREE/D ref = {LABNOTEBOOK_UNCACHED_VALUE, LABNOTEBOOK_UNCACHED_VALUE, LABNOTEBOOK_UNCACHED_VALUE}
	Make/FREE/N=3/D actual = indexWave[sweepNo][index][p]
	CHECK_EQUAL_WAVES(ref, actual)

	Make/N=(2, 3)/D/FREE ref = {{LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}}
	Make/N=(2, 3)/D/FREE actual = rowWave[sweepNo][p][q]
	CHECK_EQUAL_WAVES(ref, actual)

	WAVE settings = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	Make/FREE/D ref = {LABNOTEBOOK_UNCACHED_VALUE, 9, LABNOTEBOOK_UNCACHED_VALUE}
	Make/FREE/N=3/D actual = indexWave[sweepNo][index][p]
	CHECK_EQUAL_WAVES(ref, actual)

	Make/N=(2, 3)/D/FREE ref = {{LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}, {9, 12}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}}
	Make/N=(2, 3)/D/FREE actual = rowWave[sweepNo][p][q]
	CHECK_EQUAL_WAVES(ref, actual, tol = 1)

	Duplicate/FREE indexWave, indexWavePlain
	Duplicate/FREE rowWave, rowWavePlain

	matrixop/FREE indexWavePlain = replace(indexWave, LABNOTEBOOK_UNCACHED_VALUE, NaN)
	WaveStats/Q/M=1 indexWavePlain
	CHECK_EQUAL_VAR(V_npnts, 1)

	matrixop/FREE rowWavePlain = replace(rowWavePlain, LABNOTEBOOK_GET_RANGE, NaN)
	WaveStats/Q/M=1 rowWavePlain
	CHECK_EQUAL_VAR(V_npnts, 2)
End

Function LBN_CacheCorrectSourceTypes2()

	variable index
	variable sweepNo = 1

	WAVE numericalValuesSrc = root:Labnotebook_CacheTest:numericalValues
	WAVE numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)
	index = FindDimlabel(numericalValues, COLS, "DAC")

	WAVE indexWave = GetLBIndexCache(numericalValues)
	WAVE rowWave   = GetLBRowCache(numericalValues)

	Duplicate/FREE indexWave, indexWavePlain
	Duplicate/FREE rowWave, rowWavePlain

	matrixop/FREE indexWavePlain = replace(indexWave, LABNOTEBOOK_UNCACHED_VALUE, NaN)
	WaveStats/Q/M=1 indexWavePlain
	CHECK_EQUAL_VAR(V_npnts, 0)

	matrixop/FREE rowWavePlain = replace(rowWavePlain, LABNOTEBOOK_GET_RANGE, NaN)
	WaveStats/Q/M=1 rowWavePlain
	CHECK_EQUAL_VAR(V_npnts, 0)

	Make/FREE/D ref = {LABNOTEBOOK_UNCACHED_VALUE, LABNOTEBOOK_UNCACHED_VALUE, LABNOTEBOOK_UNCACHED_VALUE}
	Make/FREE/N=3/D actual = indexWave[sweepNo][index][p]
	CHECK_EQUAL_WAVES(ref, actual)

	Make/N=(2, 3)/D/FREE ref = {{LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}}
	Make/N=(2, 3)/D/FREE actual = rowWave[sweepNo][p][q]
	CHECK_EQUAL_WAVES(ref, actual)

	WAVE settings = GetLastSetting(numericalValues, sweepNo, "DAC", UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	Make/FREE/D ref = {9, LABNOTEBOOK_UNCACHED_VALUE, LABNOTEBOOK_UNCACHED_VALUE}
	Make/FREE/N=3/D actual = indexWave[sweepNo][index][p]
	CHECK_EQUAL_WAVES(ref, actual)

	Make/N=(2, 3)/D/FREE ref = {{9, 22}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}}
	Make/N=(2, 3)/D/FREE actual = rowWave[sweepNo][p][q]
	CHECK_EQUAL_WAVES(ref, actual)

	Duplicate/FREE indexWave, indexWavePlain
	Duplicate/FREE rowWave, rowWavePlain

	matrixop/FREE indexWavePlain = replace(indexWave, LABNOTEBOOK_UNCACHED_VALUE, NaN)
	WaveStats/Q/M=1 indexWavePlain
	CHECK_EQUAL_VAR(V_npnts, 1)

	matrixop/FREE rowWavePlain = replace(rowWavePlain, LABNOTEBOOK_GET_RANGE, NaN)
	WaveStats/Q/M=1 rowWavePlain
	CHECK_EQUAL_VAR(V_npnts, 2)
End

Function CompareLBNEntry(WAVE values, variable sweepNo, string key)

	WAVE/Z settingsNoCache = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(values, sweepNo, key, DATA_ACQUISITION_MODE)
	WAVE/Z settings        = GetLastSetting(values, sweepNo, key, DATA_ACQUISITION_MODE)

	if(WaveExists(settingsNoCache) && WaveExists(settings))
		CHECK_EQUAL_WAVES(settingsNoCache, settings)
	else
		CHECK_WAVE(settings, NULL_WAVE)
		CHECK_WAVE(settingsNoCache, NULL_WAVE)
	endif
End

/// Check that the cache returns the same entries
Function LBNCache_Reliable()

	variable i, j, numKeys
	string key
	variable numSweeps = 100

	Duplicate root:Labnotebook_CacheTest:numericalValues, numericalValues
	Duplicate/T root:Labnotebook_CacheTest:numericalKeys, numericalKeys

	numKeys = DimSize(numericalKeys, COLS)

	Make/FREE/N=(numSweeps, numKeys) junkWave

	junkWave[1, numSweeps - 1][INITIAL_KEY_WAVE_COL_COUNT, numKeys - 1] = CompareLBNEntry(numericalValues, p, numericalKeys[0][q])

	Duplicate/T root:Labnotebook_CacheTest:textualValues, textualValues
	Duplicate/T root:Labnotebook_CacheTest:textualKeys, textualKeys

	numKeys = DimSize(textualValues, COLS)

	junkWave[1, numSweeps - 1][INITIAL_KEY_WAVE_COL_COUNT, numKeys - 1] = CompareLBNEntry(textualValues, p, textualKeys[0][q])
End

/// Check that the cache returns the same entries
Function RACid_Reliable()

	variable i, j
	string key
	variable numSweeps = 100

	WAVE numericalValuesSrc = root:Labnotebook_misc:numericalValues_large
	WAVE numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)

	for(i = 1; i < numSweeps; i += 1)
		WAVE/Z settingsNoCache = MIES_AFH#AFH_GetSweepsFromSameRACycleNC(numericalValues, i)
		WAVE/Z settings        = AFH_GetSweepsFromSameRACycle(numericalValues, i)

		if(WaveExists(settingsNoCache) && WaveExists(settings))
			CHECK_EQUAL_WAVES(settingsNoCache, settings)
		else
			CHECK_WAVE(settings, NULL_WAVE)
			CHECK_WAVE(settingsNoCache, NULL_WAVE)
		endif
	endfor
End

Function RACid_InvalidWaveRef()

	variable sweepNo = 1000

	WAVE numericalValuesSrc = root:Labnotebook_misc:numericalValues_large
	WAVE numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)

	WAVE/Z settingsNoCache = MIES_AFH#AFH_GetSweepsFromSameRACycleNC(numericalValues, sweepNo)
	WAVE/Z settings        = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_WAVE(settingsNoCache, NULL_WAVE)

	// try the cached version again

	WAVE/Z settings = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(settings, NULL_WAVE)
End

/// Check that the cache returns the same entries
Function SCid_Reliable()

	variable i, j
	string key
	variable numSweeps = 100

	WAVE numericalValuesSrc = root:Labnotebook_CacheTest:second:numericalValues
	WAVE numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)

	for(i = 1; i < numSweeps; i += 1)
		for(j = 1; j < 2; j += 1)
			WAVE/Z settingsNoCache = MIES_AFH#AFH_GetSweepsFromSameSCINC(numericalValues, i, j)
			WAVE/Z settings        = AFH_GetSweepsFromSameSCI(numericalValues, i, j)

			if(WaveExists(settingsNoCache) && WaveExists(settings))
				CHECK_EQUAL_WAVES(settingsNoCache, settings)
			else
				CHECK_WAVE(settings, NULL_WAVE)
				CHECK_WAVE(settingsNoCache, NULL_WAVE)
			endif
		endfor
	endfor
End

Function SCid_InvalidWaveRef()

	variable sweepNo = 1000

	WAVE numericalValuesSrc = root:Labnotebook_CacheTest:second:numericalValues
	WAVE numericalValues    = PrepareLBNNumericalValues(numericalValuesSrc)

	WAVE/Z settingsNoCache = MIES_AFH#AFH_GetSweepsFromSameSCINC(numericalValues, sweepNo, 0)
	WAVE/Z settings        = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, 0)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_WAVE(settingsNoCache, NULL_WAVE)

	// try the cached version again

	WAVE/Z settings = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(settings, NULL_WAVE)
End

Function/WAVE LBNInvalidValidPairs()
	Make/WAVE/N=5/FREE waves

	Make/T/FREE wv0 = {"a:b", "a [b]"}
	waves[0] = wv0

	Make/T/FREE wv1 = {"\"", "_"}
	waves[1] = wv1

	Make/T/FREE wv2 = {"\'", "_"}
	waves[2] = wv2

	Make/T/FREE wv3 = {";", "_"}
	waves[3] = wv3

	Make/T/FREE wv4 = {":", "_"}
	waves[4] = wv4

	return waves
End

// UTF_TD_GENERATOR LBNInvalidValidPairs
Function LabnotebookUpgradeForValidDimensionLabelsNum([WAVE/T wv])
	string device, txtSetting, refSetting, invalidName, newName
	variable numSetting

	device = "ABCD"

	WAVE/Z   numericalValues = GetLBNumericalValues(device)
	WAVE/T/Z numericalKeys   = GetLBNumericalKeys(device)

	// add entry (numerical)
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[INDEP_HEADSTAGE] = 4711
	ED_AddEntryToLabnotebook(device, "someSetting", values, overrideSweepNo = 0)

	// now check that this exists
	numSetting = GetLastSettingIndep(numericalValues, 0, "USER_someSetting", UNKNOWN_MODE)
	CHECK_EQUAL_VAR(numSetting, 4711)

	// pretend the LBN is old so that the name cleanup for IP9 triggers
	MIES_WAVEGETTERS#SetWaveVersion(numericalValues, 48)
	MIES_WAVEGETTERS#SetWaveVersion(numericalKeys, 48)

	invalidName = wv[0]
	newName     = wv[1]

	// numerical

	// overwrite the old name with an invalid one
	numericalKeys[%Parameter][%$"USER_someSetting"] = invalidName

	// trigger LBN upgrade
	MIES_WAVEGETTERS#UpgradeLabNotebook(device)

	// and check that this entry is now renamed
	CHECK_GE_VAR(FindDimLabel(numericalKeys, COLS, newName), 0)
	CHECK_GE_VAR(FindDimLabel(numericalValues, COLS, newName), 0)
	txtSetting = numericalKeys[%Parameter][%$newName]
	CHECK_EQUAL_STR(txtSetting, newName)
End

// UTF_TD_GENERATOR LBNInvalidValidPairs
Function LabnotebookUpgradeForValidDimensionLabelsText([WAVE/T wv])
	string device, refSetting, invalidName, newName, setting

	device = "ABCD"

	WAVE/Z   textualValues = GetLBTextualValues(device)
	WAVE/T/Z textualKeys   = GetLBTextualKeys(device)

	// add entry (textual)
	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesTxt
	valuesTxt[INDEP_HEADSTAGE] = "4711"
	ED_AddEntryToLabnotebook(device, "someSetting", valuesTxt, overrideSweepNo = 0)

	// now check that this exists
	setting    = GetLastSettingTextIndep(textualValues, 0, "USER_someSetting", UNKNOWN_MODE)
	refSetting = "4711"
	CHECK_EQUAL_STR(setting, refSetting)

	// pretend the LBN is old so that the name cleanup for IP9 triggers
	MIES_WAVEGETTERS#SetWaveVersion(textualValues, 48)
	MIES_WAVEGETTERS#SetWaveVersion(textualKeys, 48)

	invalidName = wv[0]
	newName     = wv[1]

	// overwrite the old name with an invalid one
	textualKeys[%Parameter][%$"USER_someSetting"] = invalidName

	// trigger LBN upgrade
	MIES_WAVEGETTERS#UpgradeLabNotebook(device)

	// and check that this entry is now renamed
	CHECK_GE_VAR(FindDimLabel(textualKeys, COLS, newName), 0)
	CHECK_GE_VAR(FindDimLabel(textualKeys, COLS, newName), 0)
	setting = textualKeys[%Parameter][%$newName]
	CHECK_EQUAL_STR(setting, newName)
End

static Function Test_GetHeadstageForChannel()

	string device, key, keyTxt
	variable index, sweepNo, channelCnt, channel, hs, i

	device = "ABCD"
	[key, keyTxt] = PrepareLBN_IGNORE(device)
	WAVE numericalValues = GetLBNumericalValues(device)

	Make/FREE/N=(NUM_DA_TTL_CHANNELS) chanNums = p
	Make/FREE hsNumsADC = {NaN, NaN, NaN, NaN, NaN, NaN, 0, 1}
	Make/FREE hsNumsDAC = {NaN, NaN, 0, 1, NaN, NaN, NaN, NaN}
	Duplicate/FREE chanNums, hsResultADC, hsResultDAC

	channelCnt = DimSize(chanNums, ROWS)
	for(sweepNo = 0; sweepNo < 2; sweepNo += 1)
		for(i = 0; i < channelCnt; i += 1)
			hsResultADC[i] = GetHeadstageForChannel(numericalValues, sweepNo, XOP_CHANNEL_TYPE_ADC, chanNums[i], DATA_ACQUISITION_MODE)
			hsResultDAC[i] = GetHeadstageForChannel(numericalValues, sweepNo, XOP_CHANNEL_TYPE_DAC, chanNums[i], DATA_ACQUISITION_MODE)
		endfor
		CHECK_EQUAL_WAVES(hsResultADC, hsNumsADC, mode = WAVE_DATA)
		CHECK_EQUAL_WAVES(hsResultDAC, hsNumsDAC, mode = WAVE_DATA)
	endfor

	sweepNo = 0
	channel = 8 // Invalid channel

	hs = GetHeadstageForChannel(numericalValues, sweepNo, XOP_CHANNEL_TYPE_ADC, channel, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(hs, NaN)

	channel = 6
	hs      = GetHeadstageForChannel(numericalValues, sweepNo, XOP_CHANNEL_TYPE_TTL, channel, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(hs, INDEP_HEADSTAGE)
	hs = GetHeadstageForChannel(numericalValues, sweepNo, XOP_CHANNEL_TYPE_DAC, channel, TEST_PULSE_MODE)
	CHECK_EQUAL_VAR(hs, NaN)
	hs = GetHeadstageForChannel(numericalValues, sweepNo, XOP_CHANNEL_TYPE_ADC, channel, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(hs, 0)
End

Function Test_GetLastSettingChannel()
	string device, key, keyTxt
	variable index, sweepNo, channelNumber

	device = "ABCD"
	[key, keyTxt] = PrepareLBN_IGNORE(device)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	// null/NaN for non-existing key
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "I DON'T EXIST", channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// or sweepNo
	sweepNo       = 10
	channelNumber = 2
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// or channelNumber
	sweepNo       = 0
	channelNumber = 7
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// or wrong channel type
	sweepNo       = 0
	channelNumber = 2
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// numerical

	// works with associated entry
	// HS0: DA
	sweepNo       = 0
	channelNumber = 2
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_WAVES(settings, {131415, 161718, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS0: AD
	sweepNo       = 0
	channelNumber = 6
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_WAVES(settings, {131415, 161718, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS1: DA
	sweepNo       = 0
	channelNumber = 3
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_WAVES(settings, {131415, 161718, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS1: AD
	sweepNo       = 0
	channelNumber = 7
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_WAVES(settings, {131415, 161718, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// works with unassociated DA entry (old)
	sweepNo       = 0
	channelNumber = 4
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 123}, mode = WAVE_DATA)

	// works with unassociated AD entry (old)
	sweepNo       = 0
	channelNumber = 8
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 789}, mode = WAVE_DATA)

	// textual

	// works with associated entry
	// HS0: DA
	sweepNo       = 0
	channelNumber = 2
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_TEXTWAVES(settings, {"131415", "161718", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS0: AD
	sweepNo       = 0
	channelNumber = 6
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_TEXTWAVES(settings, {"131415", "161718", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS1: DA
	sweepNo       = 0
	channelNumber = 3
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_TEXTWAVES(settings, {"131415", "161718", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS1: AD
	sweepNo       = 0
	channelNumber = 7
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_TEXTWAVES(settings, {"131415", "161718", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// works with unassociated DA entry (old)
	sweepNo       = 0
	channelNumber = 4
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "123"}, mode = WAVE_DATA)

	// works with unassociated AD entry (old)
	sweepNo       = 0
	channelNumber = 8
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "789"}, mode = WAVE_DATA)

	// numerical

	// works with associated entry
	// HS0: DA
	sweepNo       = 1
	channelNumber = 2
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_WAVES(settings, {192021, 222324, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS0: AD
	sweepNo       = 1
	channelNumber = 6
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_WAVES(settings, {192021, 222324, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS1: DA
	sweepNo       = 1
	channelNumber = 3
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_WAVES(settings, {192021, 222324, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS1: AD
	sweepNo       = 1
	channelNumber = 7
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_WAVES(settings, {192021, 222324, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// works with unassociated DA entry (new)
	sweepNo       = 1
	channelNumber = 5
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 456}, mode = WAVE_DATA)

	// works with unassociated AD entry (new)
	sweepNo       = 1
	channelNumber = 9
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 101112}, mode = WAVE_DATA)

	// textual

	// works with associated entry
	// HS0: DA
	sweepNo       = 1
	channelNumber = 2
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_TEXTWAVES(settings, {"192021", "222324", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS0: AD
	sweepNo       = 1
	channelNumber = 6
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_TEXTWAVES(settings, {"192021", "222324", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS1: DA
	sweepNo       = 1
	channelNumber = 3
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_TEXTWAVES(settings, {"192021", "222324", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS1: AD
	sweepNo       = 1
	channelNumber = 7
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_TEXTWAVES(settings, {"192021", "222324", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// works with unassociated DA entry (new)
	sweepNo       = 1
	channelNumber = 5
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "456"}, mode = WAVE_DATA)

	// works with unassociated AD entry (new)
	sweepNo       = 1
	channelNumber = 9
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "101112"}, mode = WAVE_DATA)

	// indep headstage

	// numerical

	// returns nothing as the channel was not active
	sweepNo       = 2
	channelNumber = 0
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// works
	sweepNo       = 2
	channelNumber = 6
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 252627}, mode = WAVE_DATA)

	// textual
	sweepNo       = 2
	channelNumber = 0
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	sweepNo       = 2
	channelNumber = 6
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "252627"}, mode = WAVE_DATA)
End

Function/WAVE AllDescriptionWaves()
	Make/FREE/WAVE/N=1 wvs

	// GetLBNumericalDescription creates a wave within the MIES datafolder, but that is killed at Test Begin
	// Thus, we use a copy of that wave here
	WAVE wDesc = GetLBNumericalDescription()
	Duplicate/FREE wDesc, wT
	wvs[0] = wT

	return wvs
End

Function IsValidUnit(string unitWithPrefix)
	string prefix, unit
	variable numPrefix

	ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
	CHECK_PROPER_STR(unit)
	CHECK(IsFinite(numPrefix))
End

// UTF_TD_GENERATOR AllDescriptionWaves
Function CheckLBNDescriptions([WAVE/T wv])
	variable i, numEntries, num
	string entry

	CHECK_WAVE(wv, TEXT_WAVE)

	numEntries = DimSize(wv, COLS)
	for(i = 0; i < numEntries; i += 1)
		// name is not empty
		entry = wv[%Parameter][i]
		CHECK_PROPER_STR(entry)

		entry = wv[%Units][i]

		if(IsEmpty(entry))
			PASS()
		elseif(!cmpstr(entry, "On/Off"))
			PASS()
		elseif(!cmpstr(entry, "%"))
			PASS()
		elseif(!cmpstr(entry, "degC"))
			PASS()
		elseif(!cmpstr(entry, "bit mask"))
			PASS()
		else
			IsValidUnit(entry)
		endif

		// tolerance is either -, "runtime" or a positive number including zero
		entry = wv[%Tolerance][i]
		CHECK_PROPER_STR(entry)

		if(!cmpstr(entry, "-"))
			PASS()
		elseif(!cmpstr(entry, "runtime"))
			PASS()
		else
			num = str2num(entry)
			CHECK_GE_VAR(num, 0)
		endif

		// description is not empty
		entry = wv[%Description][i]
		CHECK_PROPER_STR(entry)

		// headstage contingency is known
		entry = wv[%HeadstageContingency][i]
		Make/FREE/T knownValues = {"ALL", "DEPEND", "INDEP"}
		FindValue/TEXT=(entry)/TXOP=4 knownValues
		CHECK_GE_VAR(V_Value, 0)

		// clamp mode is empty or known
		entry = wv[%ClampMode][i]
		Make/FREE/T knownValues = {"", "IC", "VC", "IC;I=0", "IC;VC", "IC;VC;I=0"}
		FindValue/TEXT=(entry)/TXOP=4 knownValues
		CHECK_GE_VAR(V_Value, 0)
	endfor
End

Function Test_GetEntryProperties()
	string key, keyTxT, unit, device, ref
	variable col, result

	device = "ABCD"
	[key, keyTxt] = PrepareLBN_IGNORE(device)

	WAVE keys = GetLBNumericalKeys(device)

	// no key wave
	[result, unit, col] = LBN_GetEntryProperties($"", "DAC")
	CHECK_EQUAL_VAR(result, 1)
	CHECK_EMPTY_STR(unit)
	CHECK_EQUAL_VAR(col, NaN)

	// invalid entry
	[result, unit, col] = LBN_GetEntryProperties(keys, "I DONT EXIST")
	CHECK_EQUAL_VAR(result, 1)
	CHECK_EMPTY_STR(unit)
	CHECK_EQUAL_VAR(col, NaN)

	// no unit
	[result, unit, col] = LBN_GetEntryProperties(keys, "DAC")
	CHECK_EQUAL_VAR(result, 0)
	CHECK_EMPTY_STR(unit)
	// DAC is the first non-standard key
	CHECK_EQUAL_VAR(col, INITIAL_KEY_WAVE_COL_COUNT + 0)

	// valid unit
	[result, unit, col] = LBN_GetEntryProperties(keys, "Headstage Active")
	CHECK_EQUAL_VAR(result, 0)
	ref = LABNOTEBOOK_BINARY_UNIT
	CHECK_EQUAL_STR(unit, ref)
	CHECK_EQUAL_VAR(col, INITIAL_KEY_WAVE_COL_COUNT + 2)
End

Function GNW_Works()

	WAVE values = LBN_GetNumericWave()

	CHECK_EQUAL_VAR(WaveDims(values), 1)
	CHECK_EQUAL_VAR(DimSize(values, ROWS), LABNOTEBOOK_LAYER_COUNT)
	CHECK_WAVE(values, FREE_WAVE, minorType = DOUBLE_WAVE)

	WaveStats/Q values
	CHECK_EQUAL_VAR(V_numNans, 9)
End

Function GNW_WorksWithCustomDefault()

	WAVE values = LBN_GetNumericWave(defValue = -1)

	WaveStats/Q values
	CHECK_EQUAL_VAR(V_numNans, 0)
	CHECK_EQUAL_VAR(V_max, -1)
	CHECK_EQUAL_VAR(V_min, -1)
End

Function GTW_Works()

	WAVE/T values = LBN_GetTextWave()

	CHECK_EQUAL_VAR(WaveDims(values), 1)
	CHECK_EQUAL_VAR(DimSize(values, ROWS), LABNOTEBOOK_LAYER_COUNT)
	CHECK_WAVE(values, FREE_WAVE | TEXT_WAVE)

	Make/FREE/N=(DimSize(values, ROWS)) status = strlen(values[p])

	WaveStats/Q status
	CHECK_EQUAL_VAR(V_numNans, 0)
	CHECK_EQUAL_VAR(V_max, 0)
	CHECK_EQUAL_VAR(V_min, 0)
End

Function GTW_WorksWithCustomDefault()

	WAVE/T values = LBN_GetTextWave(defValue = "abcd")

	WAVE/T/Z result = GetUniqueEntries(values)
	CHECK_EQUAL_TEXTWAVES(result, {"abcd"})
End

Function GFE_Works()

	string device, key, keyTxt

	device = "ABCD"

	// handles null wave graciously
	WAVE/Z null = LBV_GetFilledLabnotebookEntries($"")
	CHECK_NO_RTE()
	CHECK_WAVE(null, NULL_WAVE)

	// no valid entries by default
	WAVE numericalValues = GetLBNumericalValues(device)
	CHECK_WAVE(numericalValues, NUMERIC_WAVE)

	WAVE/Z null = LBV_GetFilledLabnotebookEntries(numericalValues)
	CHECK_WAVE(null, NULL_WAVE)

	WAVE textualValues = GetLBTextualValues(device)
	CHECK_WAVE(textualValues, TEXT_WAVE)

	WAVE/Z null = LBV_GetFilledLabnotebookEntries(textualValues)
	CHECK_WAVE(null, NULL_WAVE)

	// our fake LBNs have only valid entries
	[key, keyTxt] = PrepareLBN_IGNORE(device)

	WAVE/Z filled = LBV_GetFilledLabnotebookEntries(numericalValues)
	CHECK_EQUAL_VAR(DimSize(filled, ROWS), DimSize(numericalValues, COLS))

	WAVE/Z filled = LBV_GetFilledLabnotebookEntries(textualValues)
	CHECK_EQUAL_VAR(DimSize(filled, ROWS), DimSize(textualValues, COLS))
End

Function MultipleSameEDAdds()

	string device = "dummy"
	string entry  = "tp baseline pa"

	Make/FREE/N=(3, 1)/T keys

	keys[0][0] = entry
	keys[1][0] = "pA"
	keys[2][0] = "50"

	Make/FREE/D/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[][][0] = 1

	ED_AddEntriesToLabnotebook(values, keys, 0, device, DATA_ACQUISITION_MODE)

	keys[0][0] = UpperStr(entry)
	ED_AddEntriesToLabnotebook(values, keys, 0, device, DATA_ACQUISITION_MODE)

	WAVE/T keys = GetLogbookWaves(LBT_LABNOTEBOOK, LBN_NUMERICAL_KEYS, device = device)
	Duplicate/FREE/RMD=[0][][0] keys, keyCheck
	Redimension/E=1/N=(DimSize(keyCheck, COLS)) keyCheck
	WAVE indices = FindIndizes(keyCheck, str = entry)
	CHECK_WAVE(indices, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(indices, ROWS), 1)
	CHECK_GE_VAR(indices[0], 0)
End
