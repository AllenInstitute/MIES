#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=LBNEntrySourceTypeHandling

/// GetLastSetting
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
	CHECK(!WaveExists(TPSettings))

	// contains two times sweep 0, created with sweep rollback
	WAVE/SDFR=dfr numericalValues_with_sweep_rb
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_with_sweep_rb, 0, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings  = GetLastSetting(numericalValues_with_sweep_rb, 0, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(TPSettings,  {1,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}, mode = WAVE_DATA)
End

Function GetLastSettingAbortsOnTextWave()

	Make/T/Free wv

	try
		GetLastSetting(wv, NaN, "My Key", UNKNOWN_MODE)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingAbortsInvalid1()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	variable first = LABNOTEBOOK_GET_RANGE

	try
		GetLastSetting(numericalValues, NaN, "My Key", UNKNOWN_MODE, first = first)
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
		GetLastSetting(numericalValues, NaN, "My Key", UNKNOWN_MODE, last = last)
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
		GetLastSetting(numericalValues, NaN, "My Key", UNKNOWN_MODE, first = first, last = last)
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
	CHECK(!WaveExists(settings))

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = GetLastSetting(numericalValues, NaN, "I DONT EXIST", UNKNOWN_MODE, first = first , last = last)
	CHECK(!WaveExists(settings))
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
	WAVE/Z settings = GetLastSetting(numericalValues, 100, "DA unit", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK(!WaveExists(settings))
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingWorks()

	variable first, last
	variable firstAgain, lastAgain

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	WAVE/Z settings = GetLastSetting(numericalValues, 10, "DAC", DATA_ACQUISITION_MODE)
	CHECK(WaveExists(settings))

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = GetLastSetting(numericalValues, 10, "DAC", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK(WaveExists(settings))
	CHECK(first >= 0)
	CHECK(last  >= 0)

	firstAgain = first
	lastAgain  = last
	WAVE/Z settingsAgain = GetLastSetting(numericalValues, 10, "DAC", DATA_ACQUISITION_MODE, first = firstAgain, last = lastAgain)
	CHECK_EQUAL_WAVES(settings, settingsAgain, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(first, firstAgain)
	CHECK_EQUAL_VAR(last, lastAgain)
End
/// @}

/// GetLastSetting
/// @{
Function GetLastSettingTextAbortsOnNum()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr numericalValues

	try
		GetLastSetting(numericalValues, NaN, "My Key", UNKNOWN_MODE)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetLastSettingTextAborts1()

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValues

	variable first = LABNOTEBOOK_GET_RANGE

	try
		GetLastSetting(textualValues, NaN, "My Key", UNKNOWN_MODE, first = first)
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
		GetLastSetting(textualValues, NaN, "My Key", UNKNOWN_MODE, last = last)
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
		GetLastSetting(textualValues, NaN, "My Key", UNKNOWN_MODE, first = first, last = last)
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
	CHECK(!WaveExists(settings))

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = GetLastSetting(textualValues, NaN, "I DONT EXIST", UNKNOWN_MODE, first = first , last = last)
	CHECK(!WaveExists(settings))
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
	WAVE/Z settings = GetLastSetting(textualValues, 100, "DA unit", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK(!WaveExists(settings))
	CHECK_EQUAL_VAR(first, -1)
	CHECK_EQUAL_VAR(last, -1)
End

Function GetLastSettingTextWorks()

	variable first, last
	variable firstAgain, lastAgain

	DFREF dfr = root:Labnotebook_misc:
	WAVE/SDFR=dfr textualValues

	WAVE/Z settings = GetLastSetting(textualValues, 1, "DA unit", DATA_ACQUISITION_MODE)
	CHECK(WaveExists(settings))

	first = LABNOTEBOOK_GET_RANGE
	last  = LABNOTEBOOK_GET_RANGE
	WAVE/Z settings = GetLastSetting(textualValues, 1, "DA unit", DATA_ACQUISITION_MODE, first = first, last = last)
	CHECK(WaveExists(settings))
	CHECK(first >= 0)
	CHECK(last  >= 0)

	firstAgain = first
	lastAgain  = last
	WAVE/Z settingsAgain = GetLastSetting(textualValues, 1, "DA unit", DATA_ACQUISITION_MODE, first = firstAgain, last = lastAgain)
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

/// Patch Seq
/// Check that all LBN keys have the correct length

Function CheckLength()

	variable type, i, numEntries
	string key

	numEntries = ItemsInList(PSQ_LIST_OF_TYPES)
	for(i = 0; i < numEntries; i += 1)
		type = str2num(StringFromList(i, PSQ_LIST_OF_TYPES))
		key = PSQ_CreateLBNKey(type, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = 99, query = 1)
		CHECK(strlen(key) < MAX_OBJECT_NAME_LENGTH_IN_BYTES)
	endfor
End
