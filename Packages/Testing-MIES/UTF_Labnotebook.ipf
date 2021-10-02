#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=LBNEntrySourceTypeHandling

/// GetLastSetting with numeric wave
/// @{
Function GetLastSettingEntrySourceTypes()

	DFREF dfr = root:LB_Entrysourcetype_data:

	// current format with entrySourceType
	WAVE/SDFR=dfr numericalValues
	WAVE DAQSettings = GetLastSetting(numericalValues, 12, "DAC", DATA_ACQUISITION_MODE)
	WAVE TPSettings  = GetLastSetting(numericalValues, 12, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings, {NaN,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)

	// two rows testpulse format
	WAVE/SDFR=dfr numericalValues_old
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_old, 12, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings  = GetLastSetting(numericalValues_old, 12, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings, {NaN,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)

	// single row testpulse format before dd49bf
	WAVE/SDFR=dfr numericalValues_pre_dd49bf
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_pre_dd49bf, 11, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings  = GetLastSetting(numericalValues_pre_dd49bf, 11, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings, {NaN,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)

	WAVE/SDFR=dfr numericalValues_no_type_no_TP
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_no_type_no_TP, 0, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings  = GetLastSetting(numericalValues_no_type_no_TP, 0, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)
	CHECK_WAVE(TPSettings, NULL_WAVE)

	// contains two times sweep 0, created with sweep rollback
	WAVE/SDFR=dfr numericalValues_with_sweep_rb
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_with_sweep_rb, 0, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings  = GetLastSetting(numericalValues_with_sweep_rb, 0, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings,  {1,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)

	// contains two times sweep 73, created with sweep rollback and a trailing TP
	// and does not have entry source type information
	WAVE/SDFR=dfr numericalValues_no_type_with_sweep_rb_with_tp
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_no_type_with_sweep_rb_with_tp, 73, "DAC", DATA_ACQUISITION_MODE)

	WAVE/Z TPSettings  = GetLastSetting(numericalValues_no_type_with_sweep_rb_with_tp, 73, "DAC", TEST_PULSE_MODE)
	CHECK_WAVE(TPSettings, NULL_WAVE)

	WAVE/Z TPSettings  = GetLastSetting(numericalValues_no_type_with_sweep_rb_with_tp, 73, "TP Steady State Resistance", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings,  {119.7,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA, tol=0.1)

	// no entry source type and two trailing TP entries
	WAVE/SDFR=dfr numericalValues_no_type_with_two_tp_entries
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_no_type_with_two_tp_entries, 0, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings  = GetLastSetting(numericalValues_no_type_with_two_tp_entries, 0, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings,  {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)

	// this entry is treated as TP
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_no_type_with_two_tp_entries, 0, "TP Steady State Resistance", DATA_ACQUISITION_MODE)
	CHECK_WAVE(DAQSettings, NULL_WAVE)
End

Function GetLastSettingAbortsInvalid1()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	variable first = LABNOTEBOOK_GET_RANGE

	try
		MIES_MIESUTILS#GetLastSettingNoCache(numericalValues, NaN, "My Key", UNKNOWN_MODE, first = first)
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
		MIES_MIESUTILS#GetLastSettingNoCache(numericalValues, NaN, "My Key", UNKNOWN_MODE, last = last)
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
		MIES_MIESUTILS#GetLastSettingNoCache(numericalValues, NaN, "My Key", UNKNOWN_MODE, first = first, last = last)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingEmptyUnknown()

	variable first, last

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	WAVE/Z settings = GetLastSetting(numericalValues, NaN, "I DONT EXIST", UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = MIES_MIESUTILS#GetLastSettingNoCache(numericalValues, NaN, "I DONT EXIST", UNKNOWN_MODE, first = first , last = last)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingFindsNaNSweep()

	DFREF dfr = root:Labnotebook_misc:

	// check that we can find the first entries of the testpulse which have sweepNo == NaN
	WAVE/SDFR=dfr numericalValues_nan_sweep
	WAVE/Z settings = GetLastSetting(numericalValues_nan_sweep, NaN, "TP Steady State Resistance", TEST_PULSE_MODE)

	Make/D settingsRef = {10.0010900497437,10.001935005188,NaN,NaN,NaN,NaN,NaN,NaN,NaN}
	CHECK_EQUAL_WAVES(settings, settingsRef, mode = WAVE_DATA, tol = 1e-13)
End

Function GetLastSettingQueryWoMatch()

	variable first, last

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	// sweep is unknown
	WAVE/Z settings = MIES_MIESUTILS#GetLastSettingNoCache(numericalValues, 100, "DA unit", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingWorks()

	variable first, last
	variable firstAgain, lastAgain

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	WAVE/Z settings = GetLastSetting(numericalValues, 10, "DAC", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = MIES_MIESUTILS#GetLastSettingNoCache(numericalValues, 10, "DAC", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK(first >= 0)
	CHECK(last  >= 0)

	firstAgain = first
	lastAgain  = last
	WAVE/Z settingsAgain = MIES_MIESUTILS#GetLastSettingNoCache(numericalValues, 10, "DAC", DATA_ACQUISITION_MODE, first = firstAgain, last = lastAgain)
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
		MIES_MIESUTILS#GetLastSettingNoCache(textualValues, NaN, "My Key", UNKNOWN_MODE, first = first)
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
		MIES_MIESUTILS#GetLastSettingNoCache(textualValues, NaN, "My Key", UNKNOWN_MODE, last = last)
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
		MIES_MIESUTILS#GetLastSettingNoCache(textualValues, NaN, "My Key", UNKNOWN_MODE, first = first, last = last)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingTextEmptyUnknown()

	variable first, last

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValues

	WAVE/Z settings = GetLastSetting(textualValues, NaN, "I DONT EXIST", UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = MIES_MIESUTILS#GetLastSettingNoCache(textualValues, NaN, "I DONT EXIST", UNKNOWN_MODE, first = first , last = last)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingTextQueryWoMatch()

	variable first, last

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValues

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	// sweep is unknown
	WAVE/Z settings = MIES_MIESUTILS#GetLastSettingNoCache(textualValues, 100, "DA unit", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingTextWorks()

	variable first, last
	variable firstAgain, lastAgain

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValues

	WAVE/Z settings = GetLastSetting(textualValues, 1, "DA unit", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = MIES_MIESUTILS#GetLastSettingNoCache(textualValues, 1, "DA unit", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK(first >= 0)
	CHECK(last  >= 0)

	firstAgain = first
	lastAgain  = last
	WAVE/Z settingsAgain = MIES_MIESUTILS#GetLastSettingNoCache(textualValues, 1, "DA unit", DATA_ACQUISITION_MODE, first = firstAgain, last = lastAgain)
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

	WAVE/Z settings = GetLastSweepWithSetting(numericalValues_large, "TP Pulse Duration", sweepNo)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK(IsValidSweepNumber(sweepNo))
	CHECK_EQUAL_VAR(settings[INDEP_HEADSTAGE], 104)
End

/// @}

/// GetLastSweepWithSettingText
/// @{
Function GetLastSWSTextWorksWithIndep()

	DFREF dfr = root:Labnotebook_misc
	WAVE/SDFR=dfr textualValues

	variable sweepNo
	string miesVersion

	WAVE/Z/T settings = GetLastSweepWithSettingText(textualValues, "MIES Version", sweepNo)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK(IsValidSweepNumber(sweepNo))
	miesVersion = settings[INDEP_HEADSTAGE]
	CHECK_PROPER_STR(miesVersion)
End

/// @}

Function LBNCache_InvalidSweep()

	variable sweepNo = 1000
	WAVE numericalValues = root:Labnotebook_CacheTest:numericalValues

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NULL_WAVE)

	WAVE indexWave = GetLBIndexCache(numericalValues)
	CHECK_EQUAL_VAR(indexWave[sweepNo][FindDimLabel(numericalValues, COLS, "DAC")][EntrySourceTypeMapper(DATA_ACQUISITION_MODE)], LABNOTEBOOK_MISSING_VALUE)
End

Function LBNCache_InvalidKey()

	variable sweepNo = 10
	WAVE numericalValues = root:Labnotebook_CacheTest:numericalValues

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "I DONT EXIST", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
End

Function LBN_CacheCorrectSourceTypes1()

	variable index
	variable sweepNo = 1

	WAVE numericalValues = root:Labnotebook_CacheTest:numericalValues
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

	Make/N=(2, 3)/D/FREE ref = {{LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE},{LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}}
	Make/N=(2, 3)/D/FREE actual = rowWave[sweepNo][p][q]
	CHECK_EQUAL_WAVES(ref, actual)

	WAVE settings = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	Make/FREE/D ref = {LABNOTEBOOK_UNCACHED_VALUE, 9, LABNOTEBOOK_UNCACHED_VALUE}
	Make/FREE/N=3/D actual = indexWave[sweepNo][index][p]
	CHECK_EQUAL_WAVES(ref, actual)

	Make/N=(2, 3)/D/FREE ref = {{LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE},{9, 12}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}}
	Make/N=(2, 3)/D/FREE actual = rowWave[sweepNo][p][q]
	CHECK_EQUAL_WAVES(ref, actual, tol=1)

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

	WAVE numericalValues = root:Labnotebook_CacheTest:numericalValues
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

	Make/N=(2, 3)/D/FREE ref = {{LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE},{LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}, {LABNOTEBOOK_GET_RANGE, LABNOTEBOOK_GET_RANGE}}
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

	WAVE/Z settingsNoCache = MIES_MIESUTILS#GetLastSettingNoCache(values, sweepNo, key, DATA_ACQUISITION_MODE)
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

	WAVE numericalValues = root:Labnotebook_CacheTest:numericalValues
	WAVE/T numericalKeys = root:Labnotebook_CacheTest:numericalKeys

	numKeys = DimSize(numericalKeys, COLS)

	Make/FREE/N=(numSweeps, numKeys) junkWave

	junkWave[1, numSweeps - 1][INITIAL_KEY_WAVE_COL_COUNT, numKeys - 1] = CompareLBNEntry(numericalValues, p, numericalKeys[0][q])

	WAVE/T textualValues = root:Labnotebook_CacheTest:textualValues
	WAVE/T textualKeys = root:Labnotebook_CacheTest:textualKeys

	numKeys = DimSize(textualValues, COLS)

	junkWave[1, numSweeps - 1][INITIAL_KEY_WAVE_COL_COUNT, numKeys - 1] = CompareLBNEntry(textualValues, p, textualKeys[0][q])
End

/// Check that the cache returns the same entries
Function RACid_Reliable()

	variable i, j
	string key
	variable numSweeps = 100

	WAVE numericalValues = root:Labnotebook_misc:numericalValues_large

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

	WAVE numericalValues = root:Labnotebook_misc:numericalValues_large

	WAVE/Z settingsNoCache = MIES_AFH#AFH_GetSweepsFromSameRACycleNC(numericalValues, sweepNo)
	WAVE/Z settings        = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_WAVE(settingsNoCache, NULL_WAVE)

	// try the cached version again

	WAVE/Z settings  = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(settings, NULL_WAVE)
End

/// Check that the cache returns the same entries
Function SCid_Reliable()

	variable i, j
	string key
	variable numSweeps = 100

	WAVE numericalValues = root:Labnotebook_CacheTest:second:numericalValues

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

	WAVE numericalValues = root:Labnotebook_CacheTest:second:numericalValues

	WAVE/Z settingsNoCache = MIES_AFH#AFH_GetSweepsFromSameSCINC(numericalValues, sweepNo, 0)
	WAVE/Z settings        = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, 0)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_WAVE(settingsNoCache, NULL_WAVE)

	// try the cached version again

	WAVE/Z settings  = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
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

	WAVE/Z numericalValues = GetLBNumericalValues(device)
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
	CHECK(FindDimLabel(numericalKeys, COLS, newName) >= 0)
	CHECK(FindDimLabel(numericalValues, COLS, newName) >= 0)
	txtSetting = numericalKeys[%Parameter][%$newName]
	CHECK_EQUAL_STR(txtSetting, newName)
End

// UTF_TD_GENERATOR LBNInvalidValidPairs
Function LabnotebookUpgradeForValidDimensionLabelsText([WAVE/T wv])
	string device, refSetting, invalidName, newName, setting

	device = "ABCD"

	WAVE/Z textualValues = GetLBTextualValues(device)
	WAVE/T/Z textualKeys   = GetLBTextualKeys(device)

	// add entry (textual)
	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesTxt
	valuesTxt[INDEP_HEADSTAGE] = "4711"
	ED_AddEntryToLabnotebook(device, "someSetting", valuesTxt, overrideSweepNo = 0)

	// now check that this exists
	setting = GetLastSettingTextIndep(textualValues, 0, "USER_someSetting", UNKNOWN_MODE)
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
	CHECK(FindDimLabel(textualKeys, COLS, newName) >= 0)
	CHECK(FindDimLabel(textualKeys, COLS, newName) >= 0)
	setting = textualKeys[%Parameter][%$newName]
	CHECK_EQUAL_STR(setting, newName)
End

Function [string device, string key, string keyTxt] PrepareLBN_IGNORE()

	variable sweepNo

	device = "ABCD"
	key    = "some key"
	keyTxt = "other key"

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	// prepare the LBN
	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values, valuesDAC, valuesADC
	Make/T/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) valuesTxt
	Make/T/FREE/N=(1, 1, 1) keys

	sweepNo = 0

	// HS 0: DAC 2 and ADC 6
	// HS 1: DAC 3 and ADC 7
	valuesDAC[]  = NaN
	valuesDAC[0][0][0] = 2
	valuesDAC[0][0][1] = 3
	keys[] = "DAC"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]  = NaN
	valuesADC[0][0][0] = 6
	valuesADC[0][0][1] = 7
	keys[] = "ADC"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// numerical entries

	// DAC 4: unassoc (old)
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 123
	keys[] = CreateLBNUnassocKey(key, 4, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 8: unassoc (old)
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 789
	keys[] = CreateLBNUnassocKey(key, 8, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	values[] = NaN
	values[0][0][0] = 131415
	values[0][0][1] = 161718
	keys[] = key
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// textual entries

	// DAC 4: unassoc (old)
	valuesTxt[] = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "123"
	keys[] = CreateLBNUnassocKey(keyTxt, 4, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 8: unassoc (old)
	valuesTxt[] = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "789"
	keys[] = CreateLBNUnassocKey(keyTxt, 8, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	valuesTxt[] = ""
	valuesTxt[0][0][0] = "131415"
	valuesTxt[0][0][1] = "161718"
	keys[] = keyTxt
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	sweepNo = 1

	valuesDAC[]  = NaN
	valuesDAC[0][0][0] = 2
	valuesDAC[0][0][1] = 3
	keys[] = "DAC"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]  = NaN
	valuesADC[0][0][0] = 6
	valuesADC[0][0][1] = 7
	keys[] = "ADC"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// numerical entries

	// DAC 5: unassoc (new)
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 456
	keys[] = CreateLBNUnassocKey(key, 5, XOP_CHANNEL_TYPE_DAC)
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 9: unassoc (new)
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 101112
	keys[] = CreateLBNUnassocKey(key, 9, XOP_CHANNEL_TYPE_ADC)
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	values[] = NaN
	values[0][0][0] = 192021
	values[0][0][1] = 222324
	keys[] = key
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// textual entries

	// DAC 5: unassoc (new)
	valuesTxt[] = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "456"
	keys[]= CreateLBNUnassocKey(keyTxt, 5, XOP_CHANNEL_TYPE_DAC)
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 9: unassoc (new)
	valuesTxT[] = ""
	valuesTxT[0][0][INDEP_HEADSTAGE] = "101112"
	keys[] = CreateLBNUnassocKey(keyTxt, 9, XOP_CHANNEL_TYPE_ADC)
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	valuesTxT[] = ""
	valuesTxT[0][0][0] = "192021"
	valuesTxT[0][0][1] = "222324"
	keys[] = keyTxt
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	sweepNo = 2

	valuesDAC[]  = NaN
	valuesDAC[0][0][0] = 2
	valuesDAC[0][0][1] = 3
	keys[] = "DAC"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]  = NaN
	valuesADC[0][0][0] = 6
	valuesADC[0][0][1] = 7
	keys[] = "ADC"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// indep headstage
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 252627
	keys[] = key
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesTxt[] = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "252627"
	keys[] = keyTxt
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	return [device, key, keyTxt]
End

Function Test_GetLastSettingChannel()
	string device, key, keyTxt
	variable index, sweepNo, channelNumber

	[device, key, keyTxt] = PrepareLBN_IGNORE()

	WAVE/Z settings
	WAVE/T/Z settingsTxt

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	// null/NaN for non-existing key
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "I DON'T EXIST", channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// or sweepNo
	sweepNo = 10
	channelNumber = 2
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// or channelNumber
	sweepNo = 0
	channelNumber = 7
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// or wrong channel type
	sweepNo = 0
	channelNumber = 2
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// numerical

	// works with associated entry
	// HS0: DA
	sweepNo = 0
	channelNumber = 2
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_WAVES(settings, {131415, 161718, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS0: AD
	sweepNo = 0
	channelNumber = 6
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_WAVES(settings, {131415, 161718, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS1: DA
	sweepNo = 0
	channelNumber = 3
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_WAVES(settings, {131415, 161718, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS1: AD
	sweepNo = 0
	channelNumber = 7
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_WAVES(settings, {131415, 161718, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// works with unassociated DA entry (old)
	sweepNo = 0
	channelNumber = 4
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 123}, mode = WAVE_DATA)

	// works with unassociated AD entry (old)
	sweepNo = 0
	channelNumber = 8
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 789}, mode = WAVE_DATA)

	// textual

	// works with associated entry
	// HS0: DA
	sweepNo = 0
	channelNumber = 2
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_TEXTWAVES(settings, {"131415", "161718", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS0: AD
	sweepNo = 0
	channelNumber = 6
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_TEXTWAVES(settings, {"131415", "161718", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS1: DA
	sweepNo = 0
	channelNumber = 3
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_TEXTWAVES(settings, {"131415", "161718", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS1: AD
	sweepNo = 0
	channelNumber = 7
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_TEXTWAVES(settings, {"131415", "161718", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// works with unassociated DA entry (old)
	sweepNo = 0
	channelNumber = 4
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "123"}, mode = WAVE_DATA)

	// works with unassociated AD entry (old)
	sweepNo = 0
	channelNumber = 8
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "789"}, mode = WAVE_DATA)

	// numerical

	// works with associated entry
	// HS0: DA
	sweepNo = 1
	channelNumber = 2
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_WAVES(settings, {192021, 222324, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS0: AD
	sweepNo = 1
	channelNumber = 6
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_WAVES(settings, {192021, 222324, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS1: DA
	sweepNo = 1
	channelNumber = 3
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_WAVES(settings, {192021, 222324, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// HS1: AD
	sweepNo = 1
	channelNumber = 7
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_WAVES(settings, {192021, 222324, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	// works with unassociated DA entry (new)
	sweepNo = 1
	channelNumber = 5
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 456}, mode = WAVE_DATA)

	// works with unassociated AD entry (new)
	sweepNo = 1
	channelNumber = 9
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 101112}, mode = WAVE_DATA)

	// textual

	// works with associated entry
	// HS0: DA
	sweepNo = 1
	channelNumber = 2
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_TEXTWAVES(settings, {"192021", "222324", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS0: AD
	sweepNo = 1
	channelNumber = 6
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 0)
	CHECK_EQUAL_TEXTWAVES(settings, {"192021", "222324", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS1: DA
	sweepNo = 1
	channelNumber = 3
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_TEXTWAVES(settings, {"192021", "222324", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// HS1: AD
	sweepNo = 1
	channelNumber = 7
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, 1)
	CHECK_EQUAL_TEXTWAVES(settings, {"192021", "222324", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// works with unassociated DA entry (new)
	sweepNo = 1
	channelNumber = 5
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_DAC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "456"}, mode = WAVE_DATA)

	// works with unassociated AD entry (new)
	sweepNo = 1
	channelNumber = 9
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "101112"}, mode = WAVE_DATA)

	// indep headstage

	// numerical

	// returns nothing as the channel was not active
	sweepNo = 2
	channelNumber = 0
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	// works
	sweepNo = 2
	channelNumber = 6
	[settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_WAVES(settings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 252627}, mode = WAVE_DATA)

	// textual
	sweepNo = 2
	channelNumber = 0
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, NULL_WAVE)
	CHECK_EQUAL_VAR(index, NaN)

	sweepNo = 2
	channelNumber = 6
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, keyTxt, channelNumber, XOP_CHANNEL_TYPE_ADC, UNKNOWN_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
	CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
	CHECK_EQUAL_TEXTWAVES(settings, {"", "", "", "", "", "", "", "", "252627"}, mode = WAVE_DATA)
End
