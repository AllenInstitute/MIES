#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=LBNEntrySourceTypeHandling

Function TestAllTypes()

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

Function TestLabnotebookGetters()

	DFREF dfr = root:Labnotebook_misc:

	// check that we can find the first entries of the testpulse which have sweepNo == NaN
	WAVE/SDFR=dfr numericalValues_nan_sweep
	WAVE/Z settings = GetLastSetting(numericalValues_nan_sweep, NaN, "TP Steady State Resistance", TEST_PULSE_MODE)

	Make/D settingsRef = {10.0010900497437,10.001935005188,NaN,NaN,NaN,NaN,NaN,NaN,NaN}
	CHECK_EQUAL_WAVES(settings, settingsRef, mode = WAVE_DATA, tol = 1e-13)
End

End
