#pragma TextEncoding="UTF-8"
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

static Function TEST_CASE_END_OVERRIDE(testCase)
	string testCase

	CheckForBugMessages()
End

// Copy stimset parameter waves and data waves into our own permanent location
Function CopyParamWavesAndWaves_IGNORE()

	string entry

	KillDataFolder/Z root:wavebuilder_misc:DAParameterWaves
	DuplicateDataFolder/O=2 $GetWBSvdStimSetParamDAPathAS(), root:wavebuilder_misc:DAParameterWaves

	// recreate all stimsets
	DFREF dfr = GetWBSvdStimSetDAPath()
	KillDataFolder/Z dfr

	WAVE/T stimsets = ListToTextWave(ST_GetStimsetList(), ";")
	for(entry : stimsets)
		WB_CreateAndGetStimSet(entry)
	endfor

	KillDataFolder/Z root:wavebuilder_misc:DAWaves
	DFREF dfr = GetWBSvdStimSetDAPath()
	DuplicateDataFolder/O=2 dfr, root:wavebuilder_misc:DAWaves
End

Function/WAVE WB_FetchRefWave_IGNORE(string name)

	string majorVersion = num2istr(IgorVersion())

	DFREF           dfr          = root:wavebuilder_misc:DAWaves
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

	variable i, j, sweepCount, duration, epochCount, minimum, maximum
	string text

	// stock MIES stimset
	CHECK(!WB_StimsetIsFromThirdParty(stimset))

	// can be rebuilt
	WAVE/Z wv = WB_CreateAndGetStimSet(stimset)
	CHECK_WAVE(wv, NUMERIC_WAVE, minorType = FLOAT_WAVE)

	INFO("Stimset %s needs to only have finite entries.", s0 = stimset)
	CHECK(!HasOneNonFiniteEntry(wv))

	// parameter waves were upgraded
	WAVE WP = WB_GetWaveParamForSet(stimset)
	CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(WP), MIES_WAVEGETTERS#GetWPVersion())

	WAVE WPT = WB_GetWaveTextParamForSet(stimset)
	CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(WPT), MIES_WAVEGETTERS#GetWPTVersion())

	WAVE SegWvType = WB_GetSegWvTypeForSet(stimset)
	CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(SegWvType), MIES_WAVEGETTERS#GetSegWvTypeVersion())

	// check against our stimset generated with earlier versions
	WAVE refWave = WB_FetchRefWave_IGNORE(stimset)

#ifdef AUTOMATED_TESTING_DEBUGGING
	Duplicate/O refwave, root:refwave
	Duplicate/O wv, root:wv
#endif // AUTOMATED_TESTING_DEBUGGING

	CHECK_EQUAL_WAVES(refWave, wv, mode = WAVE_DATA, tol = 1e-12)

	text = note(wv)

	// check that we have a duration for all sweeps/epochs
	sweepCount = WB_GetWaveNoteEntryAsNumber(text, STIMSET_ENTRY, key = "Sweep Count")
	CHECK_GT_VAR(sweepCount, 0)

	epochCount = WB_GetWaveNoteEntryAsNumber(text, STIMSET_ENTRY, key = "Epoch Count")
	CHECK_GT_VAR(epochCount, 0)

	// check number of entries in stimset
	// version line, one for each sweep, one for each epoch per sweep, stimset line
	CHECK_EQUAL_VAR(ItemsInList(text, "\r"), 1 + sweepCount + sweepCount * epochCount + 1)

	for(i = 0; i < sweepCount; i += 1)
		for(j = 0; j < epochCount; j += 1)
			duration = WB_GetWaveNoteEntryAsNumber(text, EPOCH_ENTRY, key = "Duration", sweep = i, epoch = j)
			CHECK_GT_VAR(duration, 0)

			// check inflection point info
			strswitch(stimset)
				case "Ref3_f_DA_0":
					WAVE/Z inflectionPoints = ListToNumericWave(WB_GetWaveNoteEntry(text, EPOCH_ENTRY, key = "Inflection Points", sweep = i, epoch = j), ",")
					CHECK_WAVE(inflectionPoints, NUMERIC_WAVE)

					// map -0 to 0
					inflectionPoints[] += 0

					switch(j)
						case 0:
							Make/D/FREE refInflectionPoints = {197.458726593435, 435.675394434122, 588.633714511935, 701.526877331138, 791.045847308983, 865.22891295094, 928.57002432697, 983.837930372523}
							break
						case 1:
							Make/D/FREE refInflectionPoints = {152.790159219023, 284.335069591481, 356.976185802109, 407.420806489504, 446.105169062074, 477.48904673523}
							break
						case 2:
							Make/D/FREE refInflectionPoints = {0, 250, 500, 750, 1000}
							break
						case 3:
							Make/D/FREE refInflectionPoints = {250}
							break
						case 4:
							Make/D/FREE/N=0 refInflectionPoints
							break
						case 5:
							Make/D/FREE refInflectionPoints = {0, 56.8275517074798, 134.011125536996, 254.863071610038, 551.280032534985}
							break
						case 6:
							Make/D/FREE refInflectionPoints = {13.8634120431695, 55.5281095180012, 197.212830141239}
							break
						default:
							FAIL()
					endswitch

					CHECK_EQUAL_WAVES(refInflectionPoints, inflectionPoints)
					break
				default:
					// do nothing
					break
			endswitch
		endfor

		MatrixOP/FREE singleSweep = col(wv, i)

		// check minimum/maximum
		minimum = WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "Minimum", sweep = i)
		MatrixOP/FREE minimumCal = minVal(singleSweep)
		CHECK_CLOSE_VAR(minimum, minimumCal[0])

		maximum = WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "Maximum", sweep = i)
		MatrixOP/FREE maximumCal = maxVal(singleSweep)
		CHECK_CLOSE_VAR(maximum, maximumCal[0])
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
