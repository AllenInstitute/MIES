#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=WB_Testing

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	KillDataFolder/Z GetWBSvdStimSetDAPath()

	KillDataFolder/Z GetWBSvdStimSetParamDAPath()
	DuplicateDataFolder root:wavebuilder_misc:DAParameterWaves, $GetWBSvdStimSetParamDAPathAS()
End

// Copy stimset parameter waves into our own permanent location
Function CopyParamWaves_IGNORE()
	KillDataFolder/Z root:wavebuilder_misc:DAParameterWaves
	DuplicateDataFolder $GetWBSvdStimSetParamDAPathAS(), root:wavebuilder_misc:DAParameterWaves
End

// Copy stimsets into our own permanent location
Function CopyWaves_IGNORE()
	KillDataFolder/Z root:wavebuilder_misc:DAWaves
	DuplicateDataFolder $GetWBSvdStimSetDAPathAsString(), root:wavebuilder_misc:DAWaves
End

Function WB_RegressionTest()

	variable i, numEntries
	string list, stimset

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
	endfor
End

Function WB_StimsetEntryParsing()

	string actual, reference

	Make/FREE wv
	Note/K wv "Version = 2;\r" + \
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

	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, VERSION_ENTRY), 2)

	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, SWEEP_ENTRY, key = "ITI", sweep = 0), 1)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, SWEEP_ENTRY, key = "ITI", sweep = 1), 2)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, SWEEP_ENTRY, key = "ITI", sweep = 2), 3)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, SWEEP_ENTRY, key = "ITI", sweep = 3), 4)

	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, EPOCH_ENTRY, key = "Duration", epoch = 0, sweep = 0), 500)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, EPOCH_ENTRY, key = "Duration", epoch = 1, sweep = 1), 150)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, EPOCH_ENTRY, key = "Duration", epoch = 2, sweep = 2), 300)
	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, EPOCH_ENTRY, key = "Duration", epoch = 3, sweep = 3), 960.005)

	CHECK_EQUAL_VAR(WB_GetWaveNoteEntryAsNumber(wv, STIMSET_ENTRY, key = "Sweep Count"), 4)

	actual    = WB_GetWaveNoteEntry(wv, STIMSET_ENTRY, key = "Generic")
	reference = "PSQ_Ramp"
	CHECK_EQUAL_STR(actual, reference)
End
