#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=WB_Testing

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	AdditionalExperimentCleanup()

	KillDataFolder/Z GetWBSvdStimSetDAPath()

	KillDataFolder/Z GetWBSvdStimSetParamDAPath()
	DuplicateDataFolder root:wavebuilder_misc:DAParameterWaves, $GetWBSvdStimSetParamDAPathAS()
End

Function WB_StimsetEntryParsing()

	string actual, reference, text

	// IPT_FORMAT_OFF

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

	// IPT_FORMAT_ON

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

Function WB_CheckEpochParameters()
	string newCode, existingCode

	newCode = WBP_RegenerateEpochParameterNamesCode()
	existingCode = ProcedureText("GetEpochParameterNames")

	// remove Z_() functions calls for tracing
	existingCode = GrepList(existingCode, "^Z_\(\d+,[[:space:]]\d+\)$", 1, "\r")

	newCode = TrimString(newCode, 1)
	existingCode = TrimString(existingCode, 1)

	CHECK_GE_VAR(strsearch(existingCode, newCode, 0), 0)
End

Function WB_SaveErrorsDontDeleteExistingStimSets()
	string win, setName, history
	variable refNum, modCount

	setName = "myset"
	setName = ST_CreateStimSet("myset", CHANNEL_TYPE_DAC)
	ST_SetStimsetParameter(setName, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setName, "Duration", epochIndex = 0, var = 500)

	win = WBP_CreateWaveBuilderPanel()

	// stimset can be loaded
	PGC_SetAndActivateControl(win, "popup_WaveBuilder_SetList", str = setName)

	// and saved
	PGC_SetAndActivateControl(win, "button_WaveBuilder_SaveSet")

	// now load it again
	PGC_SetAndActivateControl(win, "popup_WaveBuilder_SetList", str = setName)

	// attach an analysis function
	ST_SetStimsetParameter(setName, "Analysis function (generic)", str = "ComplainWithProperString")

	// add analysis parameter
	AFH_AddAnalysisParameter(setName, "param", str = "some_string")

	// load it
	PGC_SetAndActivateControl(win, "popup_WaveBuilder_SetList", str = setName)

	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	CHECK_WAVE(stimset, NORMAL_WAVE)
	modCount = WaveModCount(stimset)
	CHECK_GT_VAR(modCount, 0)

	// and try resaving again
	refNum = CaptureHistoryStart()
	PGC_SetAndActivateControl(win, "button_WaveBuilder_SaveSet")
	history = CaptureHistory(refNum, 1)

	// something was outputted as saving failed
	CHECK_PROPER_STR(history)
	CHECK_GT_VAR(strsearch(history, "wrong value", 0), 0)

	// saved stimset was not changed
	CHECK_EQUAL_VAR(modCount, WaveMOdCount(stimset))
End

/// UTF_TD_GENERATOR GetChannelTypes
Function ExportAndLoadOfCustomWaves([variable var])

	string setName, path, filename, history
	variable historyRef

	setName = ST_CreateStimSet("setA", var)

	DFREF dfr = GetSetFolder(var)
	Make/D dfr:myCustomWave/WAVE=customWave
	customWave = p

	ST_SetStimsetParameter(setName, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setName, "Type of Epoch 0", var = EPOCH_TYPE_CUSTOM)
	ST_SetStimsetParameter(setName, "Custom epoch wave name", epochIndex = 0, str = GetWavesDataFolder(customWave, 2))

	historyRef = CaptureHistoryStart()

	PathInfo home
	CHECK_PROPER_STR(S_path)
	filename = UniqueFileOrFolder("home", "customWaveExportTest")
	path = S_path  + filename
	NWB_ExportAllStimsets(NWB_VERSION_LATEST, overrideFilePath = path)

	// check that we don't got a recreation error warning
	history = CaptureHistory(historyRef, 1)
	CHECK_EQUAL_STR(history, "Please be patient while we export all existing stimsets to NWB\r")

	WAVE customWaveRef = MakeWaveFree(customWave)
	KillOrMoveToTrash(dfr = GetWaveBuilderPath())

	// now read the file again and compare it's contents
	NWB_LoadAllStimsets(filename = path)

	DFREF dfr = GetSetFolder(var)
	WAVE/Z/SDFR=dfr customWave = myCustomWave
	CHECK_EQUAL_WAVES(customWaveRef, customWave)
End

Function WB_StimsetWithTooLongNameIsNotSaved()

	string win, history, basename
	variable refNum

	win = WBP_CreateWaveBuilderPanel()

	PGC_SetAndActivateControl(win, "SetVar_WaveBuilder_P0", val = 100)

	basename = ReplicateString("abcd", 10)
	PGC_SetAndActivateControl(win, "setvar_WaveBuilder_baseName", str = basename)

	refNum = CaptureHistoryStart()
	PGC_SetAndActivateControl(win, "button_WaveBuilder_SaveSet")
	history = CaptureHistory(refNum, 1)

	CHECK_PROPER_STR(history)
	CHECK_GT_VAR(strsearch(history, "it is too long", 0), 0)

	CHECK_EQUAL_STR(ST_GetStimsetList(searchString = "abcd*"), "")
End

Function WB_StimsetWithEmptyEpochsAreNotSaved()

	string win, history, basename
	variable refNum

	win = WBP_CreateWaveBuilderPanel()

	basename = "abcd"
	PGC_SetAndActivateControl(win, "setvar_WaveBuilder_baseName", str = basename)

	refNum = CaptureHistoryStart()
	PGC_SetAndActivateControl(win, "button_WaveBuilder_SaveSet")
	history = CaptureHistory(refNum, 1)
	CHECK_PROPER_STR(history)
	CHECK_GT_VAR(strsearch(history, "duration of zero", 0), 0)

	CHECK_EQUAL_STR(ST_GetStimsetList(searchString = basename + "*"), "")
End

Function WB_StimsetWithNoEpochsAreNotSaved()

	string win, history, basename
	variable refNum

	win = WBP_CreateWaveBuilderPanel()

	basename = "abcd"
	PGC_SetAndActivateControl(win, "setvar_WaveBuilder_baseName", str = basename)

	// directly write into the SegWvType as the GUI does not allow no epochs
	WAVE SegWvType = GetSegmentTypeWave()
	SegWvType[%$"Total number of epochs"] = 0

	refNum = CaptureHistoryStart()
	PGC_SetAndActivateControl(win, "button_WaveBuilder_SaveSet")
	history = CaptureHistory(refNum, 1)
	CHECK_PROPER_STR(history)
	CHECK_GT_VAR(strsearch(history, "stimset has no epochs", 0), 0)

	CHECK_EQUAL_STR(ST_GetStimsetList(searchString = basename + "*"), "")
End

Function CombineStimsetSubStrings()

	string setNameA, setNameAA, setNameCombine

	setNameA  = ST_CreateStimSet("setABC", CHANNEL_TYPE_DAC)
	setNameAA = ST_CreateStimSet("newsetABC", CHANNEL_TYPE_DAC)

	setNameCombine = ST_CreateStimSet("setCombine", CHANNEL_TYPE_DAC)

	ST_SetStimsetParameter(setNameCombine, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setNameCombine, "Type of Epoch 0", var = EPOCH_TYPE_COMBINE)

	ST_SetStimsetParameter(setNameCombine, "Combine epoch formula version", epochIndex = 0, str = WAVEBUILDER_COMBINE_FORMULA_VER)
	ST_SetStimsetParameter(setNameCombine, "Combine epoch formula", epochIndex = 0, str = LowerStr(setNameA) + "?" + " + " + LowerStr(setNameAA) + "?")

	WAVE/Z wv = WB_CreateAndGetStimSet(setNameCombine)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	CHECK_GT_VAR(DimSize(wv, ROWS), 0)
	CHECK_NO_RTE()
End
