#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=WB_Testing

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	AdditionalExperimentCleanupAfterTest()

	KillDataFolder/Z GetWBSvdStimSetDAPath()

	KillDataFolder/Z GetWBSvdStimSetParamDAPath()
	DuplicateDataFolder root:wavebuilder_misc:DAParameterWaves, $GetWBSvdStimSetParamDAPathAS()
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

Function WB_RegressionTest()

	variable i, numEntries
	variable j, sweepCount, duration, k, epochCount
	string list, stimset, text

	DFREF ref = root:wavebuilder_misc:DAWaves
	DFREF dfr = GetWBSvdStimSetParamDAPath()
	list = GetListOfObjects(dfr, "WP_.*")

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		stimset = ReplaceString("WP_", StringFromList(i, list), "")
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
		WAVE/SDFR=ref refWave = $stimset
		CHECK_EQUAL_WAVES(refWave, wv, mode = WAVE_DATA | WAVE_DATA_TYPE | WAVE_SCALING | DIMENSION_LABELS | DIMENSION_UNITS | DIMENSION_SIZES | DATA_UNITS | DATA_FULL_SCALE, tol = 1e-12)

		text = note(wv)

		// check that we have a duration for all sweeps/epochs
		sweepCount = WB_GetWaveNoteEntryAsNumber(text, STIMSET_ENTRY, key = "Sweep Count")
		CHECK(sweepCount > 0)

		epochCount = WB_GetWaveNoteEntryAsNumber(text, STIMSET_ENTRY, key = "Epoch Count")
		CHECK(epochCount > 0)

		for(j = 0; j < sweepCount; j += 1)
			for(k = 0; k < epochCount; k += 1)
				duration = WB_GetWaveNoteEntryAsNumber(text, EPOCH_ENTRY, key = "Duration", sweep = j, epoch=k)
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
	endfor
End

Function WB_StimsetEntryParsing()

	string actual, reference, text

	text = "Version = 2;\r" + \
	"Sweep = 0;Epoch = nan;ITI = 1;\r" + \
	"Sweep = 0;Epoch = 0;Type = Square pulse;Duration = 500;Amplitude = 0;\r" + \
	"Sweep = 0;Epoch = 1;Type = Ramp;Duration = 150;Amplitude = 1;Offset = 0;\r" + \
	"Sweep = 0;Epoch = 2;Type = Square pulse;Duration = 300;Amplitude = 0;\r" + \
	"Sweep = 0;Epoch = 3;Type = Pulse Train;Duration = 960.005;Amplitude = 1;Offset = 0;Pulse Type = Square;Frequency = 20;Pulse To Pulse Length = 50;Pulse duration = 10;Number of pulses = 20;Mixed frequency = False;First mixed frequency = 0;Last mixed frequency = 0;Poisson distribution = False;Random seed = 0.963638;Pulse Train Pulses = 0,50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,;Definition mode = Duration;\r" + \
	"Sweep = 1;Epoch = nan;ITI = 2;\r" + \
	"Sweep = 1;Epoch = 0;Type = Square pulse;Duration = 600;Amplitude = 0;\r" + \
	"Sweep = 1;Epoch = 1;Type = Ramp;Duration = 150;Amplitude = 1;Offset = 0;\r" + \
	"Sweep = 1;Epoch = 2;Type = Square pulse;Duration = 300;Amplitude = 0;\r" + \
	"Sweep = 1;Epoch = 3;Type = Pulse Train;Duration = 960.005;Amplitude = 1;Offset = 0;Pulse Type = Square;Frequency = 20;Pulse To Pulse Length = 50;Pulse duration = 10;Number of pulses = 20;Mixed frequency = False;First mixed frequency = 0;Last mixed frequency = 0;Poisson distribution = False;Random seed = 0.963638;Pulse Train Pulses = 0,50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,;Definition mode = Duration;\r" + \
	"Sweep = 2;Epoch = nan;ITI = 3;\r" + \
	"Sweep = 2;Epoch = 0;Type = Square pulse;Duration = 700;Amplitude = 0;\r" + \
	"Sweep = 2;Epoch = 1;Type = Ramp;Duration = 150;Amplitude = 1;Offset = 0;\r" + \
	"Sweep = 2;Epoch = 2;Type = Square pulse;Duration = 300;Amplitude = 0;\r" + \
	"Sweep = 2;Epoch = 3;Type = Pulse Train;Duration = 960.005;Amplitude = 1;Offset = 0;Pulse Type = Square;Frequency = 20;Pulse To Pulse Length = 50;Pulse duration = 10;Number of pulses = 20;Mixed frequency = False;First mixed frequency = 0;Last mixed frequency = 0;Poisson distribution = False;Random seed = 0.963638;Pulse Train Pulses = 0,50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,;Definition mode = Duration;\r" + \
	"Sweep = 3;Epoch = nan;ITI = 4;\r" + \
	"Sweep = 3;Epoch = 0;Type = Square pulse;Duration = 800;Amplitude = 0;\r" + \
	"Sweep = 3;Epoch = 1;Type = Ramp;Duration = 150;Amplitude = 1;Offset = 0;\r" + \
	"Sweep = 3;Epoch = 2;Type = Square pulse;Duration = 300;Amplitude = 0;\r" + \
	"Sweep = 3;Epoch = 3;Type = Pulse Train;Duration = 960.005;Amplitude = 1;Offset = 0;Pulse Type = Square;Frequency = 20;Pulse To Pulse Length = 50;Pulse duration = 10;Number of pulses = 20;Mixed frequency = False;First mixed frequency = 0;Last mixed frequency = 0;Poisson distribution = False;Random seed = 0.963638;Pulse Train Pulses = 0,50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,;Definition mode = Duration;\r" + \
	"Stimset;Sweep Count = 4;Epoch Count = 4;Pre DAQ = ;Mid Sweep = ;Post Sweep = ;Post Set = ;Post DAQ = ;Pre Sweep = ;Generic = PSQ_Ramp;Pre Set = ;Function params = NumberOfSpikes:variable=5,Elements:string=Hidiho,;Flip = 0;Random Seed = 0.963638;Checksum = 65446509;"

	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, VERSION_ENTRY), 2)

	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 0), 1)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 1), 2)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 2), 3)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "ITI", sweep = 3), 4)

	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, EPOCH_ENTRY, key = "Duration", epoch = 0, sweep = 0), 500)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, EPOCH_ENTRY, key = "Duration", epoch = 1, sweep = 1), 150)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, EPOCH_ENTRY, key = "Duration", epoch = 2, sweep = 2), 300)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, EPOCH_ENTRY, key = "Duration", epoch = 3, sweep = 3), 960.005)

	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, STIMSET_ENTRY, key = "Sweep Count"), 4)

	actual    = WB_GetWaveNoteEntry(text, STIMSET_ENTRY, key = "Generic")
	reference = "PSQ_Ramp"
	CHECK_EQUAL_STR(actual, reference)

	// check that unknown keys report as "" or NaN
	actual = WB_GetWaveNoteEntry(text, STIMSET_ENTRY, key = "Unknown Entry")
	CHECK_EMPTY_STR(actual)

	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(text, STIMSET_ENTRY, key = "Unknown Entry"), NaN)

	try
		WB_GetWaveNoteEntry(text, 123); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function WB_StimsetRecreation1()
	string setName = "Ref0_DA_0"

	// stimset does not yet exist
	CHECK_EQUAL_VAR(MIES_WB#WB_ParameterWvsNewerThanStim(setName), 1)

	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	CHECK_WAVE(stimset, NORMAL_WAVE)

	WAVE/Z WP = WB_GetWaveParamForSet(setName)
	CHECK_WAVE(WP, NORMAL_WAVE)

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(setName)
	CHECK_WAVE(WPT, NORMAL_WAVE)

	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)
	CHECK_WAVE(SegWvType, NORMAL_WAVE)

	// stimset exists and is up-to-date
	CHECK_EQUAL_VAR(MIES_WB#WB_ParameterWvsNewerThanStim(setName), 0)
End

Function WB_StimsetRecreation2()
	string setName = "Ref0_DA_0"

	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	CHECK_WAVE(stimset, NORMAL_WAVE)

	WAVE/Z WP = WB_GetWaveParamForSet(setName)
	CHECK_WAVE(WP, NORMAL_WAVE)

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(setName)
	CHECK_WAVE(WPT, NORMAL_WAVE)

	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)
	CHECK_WAVE(SegWvType, NORMAL_WAVE)

	CHECK_EQUAL_VAR(MIES_WB#WB_ParameterWvsNewerThanStim(setName), 0)

	// modifcation tracking works
	WP[0][0] += 0
	Sleep/S 2
	CHECK_EQUAL_VAR(MIES_WB#WB_ParameterWvsNewerThanStim(setName), 1)
End

Function WB_StimsetRecreation3()
	string setName = "Ref0_DA_0"

	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	CHECK_WAVE(stimset, NORMAL_WAVE)

	WAVE/Z WP = WB_GetWaveParamForSet(setName)
	CHECK_WAVE(WP, NORMAL_WAVE)

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(setName)
	CHECK_WAVE(WPT, NORMAL_WAVE)

	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)
	CHECK_WAVE(SegWvType, NORMAL_WAVE)

	CHECK_EQUAL_VAR(MIES_WB#WB_ParameterWvsNewerThanStim(setName), 0)

	stimset[0][0] += 0
	SegWvType[0][0] += 0
	WP[0][0] += 0
	WPT[0][0] += ""

	// this took less time than a second
	CHECK_EQUAL_VAR(ModDate(stimset), ModDate(WP))
	CHECK_EQUAL_VAR(ModDate(stimset), ModDate(WPT))
	CHECK_EQUAL_VAR(ModDate(stimset), ModDate(SegWvType))

	// but the mod count logic kicks in nevertheless
	CHECK_EQUAL_VAR(MIES_WB#WB_ParameterWvsNewerThanStim(setName), 1)
End

Function WB_EditingExistingKeepsPrecision()
	string panel = "WaveBuilder"
	string setName = "Ref6_b_DA_0"

	WAVE/Z WP = WB_GetWaveParamForSet(setName)
	CHECK_WAVE(WP, NORMAL_WAVE, minorType = FLOAT_WAVE)

	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)
	CHECK_WAVE(SegWvType, NORMAL_WAVE, minorType = FLOAT_WAVE)

	// this forces wave version upgrades
	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	CHECK_WAVE(stimset, NORMAL_WAVE)

	WAVE/Z WP = WB_GetWaveParamForSet(setName)
	CHECK_WAVE(WP, NORMAL_WAVE, minorType = FLOAT_WAVE)

	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)
	CHECK_WAVE(SegWvType, NORMAL_WAVE, minorType = FLOAT_WAVE)

	WBP_CreateWaveBuilderPanel()
	PGC_SetAndActivateControl(panel, "popup_WaveBuilder_SetList", str = setName)

	// change tau rise delta
	PGC_SetAndActivateControl(panel, "setvar_WaveBuilder_P11", val = 0.1)

	string newSetName = "newSet"
	PGC_SetAndActivateControl(panel, "setvar_WaveBuilder_baseName", str = newSetName)
	PGC_SetAndActivateControl(panel, "button_WaveBuilder_SaveSet")

	newSetName += "_DA_0"

	// now the new WP and SegWvType must still be float

	WAVE/Z stimset = WB_CreateAndGetStimSet(newSetName)
	CHECK_WAVE(stimset, NORMAL_WAVE)

	WAVE/Z WP = WB_GetWaveParamForSet(newSetName)
	CHECK_WAVE(WP, NORMAL_WAVE, minorType = FLOAT_WAVE)

	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(newSetName)
	CHECK_WAVE(SegWvType, NORMAL_WAVE, minorType = FLOAT_WAVE)
End
