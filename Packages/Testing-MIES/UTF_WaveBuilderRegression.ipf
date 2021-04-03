#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=WB_Regression

static Function TEST_SUITE_BEGIN_OVERRIDE(testSuite)
	string testSuite

	AdditionalExperimentCleanup()

	KillDataFolder/Z GetWBSvdStimSetDAPath()

	KillDataFolder/Z GetWBSvdStimSetParamDAPath()
	DuplicateDataFolder root:wavebuilder_misc:DAParameterWaves, $GetWBSvdStimSetParamDAPathAS()
End

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	// do nothing
End

// Copy stimset parameter waves into our own permanent location
Function CopyParamWaves_IGNORE()
	KillDataFolder/Z root:wavebuilder_misc:DAParameterWaves
	DuplicateDataFolder/O=2 $GetWBSvdStimSetParamDAPathAS(), root:wavebuilder_misc:DAParameterWaves
End

// Copy stimsets into our own permanent location
Function CopyWaves_IGNORE()
	KillDataFolder/Z root:wavebuilder_misc:DAWaves
	DuplicateDataFolder/O=2 $GetWBSvdStimSetDAPathAsString(), root:wavebuilder_misc:DAWaves
End

Function/WAVE WB_FetchRefWave_IGNORE(string name)

	string majorVersion = num2istr(IgorVersion())

	DFREF dfr = root:wavebuilder_misc:DAWaves
	WAVE/SDFR=dfr/Z overrideWave = $(name + "_IP" + majorVersion)
	if(WaveExists(overrideWave))
		return overrideWave
	endif

	WAVE/SDFR=dfr/Z wv = $name
	CHECK_WAVE(wv, NORMAL_WAVE)

	return wv
End

Function/WAVE WB_GatherStimsets()

	string list

	DFREF dfr = root:wavebuilder_misc:DAParameterWaves
	list = GetListOfObjects(dfr, "WP_.*")
	list = RemovePrefixFromListItem("WP_", list)
	WAVE/T wv = ListToTextWave(list, ";")

	SetDimensionLabels(wv, list, ROWS)

	return wv
End

// UTF_TD_GENERATOR WB_GatherStimsets
Function WB_RegressionTest([string stimset])

	variable i, j, sweepCount, duration, epochCount
	string text

	// stock MIES stimset
	CHECK(!WB_StimsetIsFromThirdParty(stimset))

	// can be rebuilt
	WAVE/Z wv = WB_CreateAndGetStimSet(stimset)
	CHECK_WAVE(wv, NUMERIC_WAVE, minorType = FLOAT_WAVE)

	// parameter waves were upgraded
	WAVE WP = WB_GetWaveParamForSet(stimset)
	CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(WP), MIES_WAVEGETTERS#GetWPVersion())

	WAVE WPT = WB_GetWaveTextParamForSet(stimset)
	CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(WPT), MIES_WAVEGETTERS#GetWPTVersion())

	WAVE SegWvType = WB_GetSegWvTypeForSet(stimset)
	CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(SegWvType), MIES_WAVEGETTERS#GetSegWvTypeVersion())

	// check against our stimset generated with earlier versions
	WAVE refWave = WB_FetchRefWave_IGNORE(stimset)
	DUplicate/O refwave, root:refwave
	duplicate/O wv, root:wv
	CHECK_EQUAL_WAVES(refWave, wv, mode = WAVE_DATA, tol = 1e-12)

	text = note(wv)

	// check that we have a duration for all sweeps/epochs
	sweepCount = WB_GetWaveNoteEntryAsNumber(text, STIMSET_ENTRY, key = "Sweep Count")
	CHECK(sweepCount > 0)

	epochCount = WB_GetWaveNoteEntryAsNumber(text, STIMSET_ENTRY, key = "Epoch Count")
	CHECK(epochCount > 0)

	for(i = 0; i < sweepCount; i += 1)
		for(j = 0; j < epochCount; j += 1)
			duration = WB_GetWaveNoteEntryAsNumber(text, EPOCH_ENTRY, key = "Duration", sweep = i, epoch= j)
			CHECK(duration > 0)
		endfor
	endfor

	// check ITIs
	strswitch(stimset)
		case "RefSetITI1_DA_0":
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 0), 1)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 1), 2)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 2), 3)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 3), 4)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 4), 5)
			break
		case "RefSetITI2_DA_0":
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 0), 1)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 1), 2)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 2), 4)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 3), 8)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 4), 16)
			break
		case "RefSetITI3_DA_0":
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 0), 1)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 1), 101)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 2), 103)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 3), 103.301)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 4), 102.78)
			break
		case "RefSetITI4_DA_0":
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 0), 1)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 1), 3)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 2), 7)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 3), 23)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 4), 279)
			break
		case "RefSetITI5_DA_0":
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 0), 1)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 1), 4)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 2), 13)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 3), 94)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 4), 6655)
			break
		case "RefSetITI6_DA_0":
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 0), 1)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 1), 5)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 2), 1)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 3), 5)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 4), 1)
			break
		case "RefSetITI7_DA_0":
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 0), 1)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 1), 11)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 2), 21)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 3), 31)
			CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 4), 41)
			break
		default:
			// do nothing
			break
	endswitch
End
