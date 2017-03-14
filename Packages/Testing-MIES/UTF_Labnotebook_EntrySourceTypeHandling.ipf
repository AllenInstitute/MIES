#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=LBNEntrySourceTypeHandling

Function TestAllTypes()

	DFREF dfr = root:LB_Entrysourcetype_data:

	// current format with entrySourceType
	WAVE/SDFR=dfr numericalValues
	WAVE DAQSettings = GetLastSetting(numericalValues, 12, "DAC", DATA_ACQUISITION_MODE)
	WAVE TPSettings  = GetLastSetting(numericalValues, 12, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN})
	CHECK_EQUAL_WAVES(TPSettings, {NaN,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN})

	// two rows testpulse format
	WAVE/SDFR=dfr numericalValues_old
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_old, 12, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings  = GetLastSetting(numericalValues_old, 12, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN})
	CHECK_EQUAL_WAVES(TPSettings, {NaN,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN})

	// single row testpulse format before dd49bf
	WAVE/SDFR=dfr numericalValues_pre_dd49bf
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_pre_dd49bf, 11, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings  = GetLastSetting(numericalValues_pre_dd49bf, 11, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN})
	CHECK_EQUAL_WAVES(TPSettings, {NaN,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN})

	WAVE/SDFR=dfr numericalValues_no_type_no_TP
	WAVE/Z DAQSettings = GetLastSetting(numericalValues_no_type_no_TP, 0, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z TPSettings  = GetLastSetting(numericalValues_no_type_no_TP, 0, "DAC", TEST_PULSE_MODE)

	CHECK_EQUAL_WAVES(DAQSettings, {0,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN})
	CHECK(!WaveExists(TPSettings))
End
