#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=EpochsTestwoHardware

static Function [WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] PrepareEpochsTable_IGNORE()
	variable DAC

	string key, keyText
	string device = "dummy"

	WAVE/T/Z epochsWave = GetEpochsWave(DEVICE)
	CHECK_WAVE(epochsWave, TEXT_WAVE)

	DAC = 2 // HS 0
	MIES_EP#EP_AddEpoch(device, DAC, XOP_CHANNEL_TYPE_DAC, 1, 3, "someDesc", "EP0", 0)
	MIES_EP#EP_AddEpoch(device, DAC, XOP_CHANNEL_TYPE_DAC, 4, 5, "someDesc", "EP_0a", 0)
	MIES_EP#EP_AddEpoch(device, DAC, XOP_CHANNEL_TYPE_DAC, 10, 20, "someDesc", "EP_0b", 0)
	MIES_EP#EP_AddEpoch(device, DAC, XOP_CHANNEL_TYPE_DAC, 1, 2, "someDesc", "EP1", 1)
	MIES_EP#EP_AddEpoch(device, DAC, XOP_CHANNEL_TYPE_DAC, 2, 3, "someDesc", "EP_1a", 1)
	// intentional gap
	MIES_EP#EP_AddEpoch(device, DAC, XOP_CHANNEL_TYPE_DAC, 4, 5, "someDesc", "EP_1b", 1)
	MIES_EP#EP_AddEpoch(device, DAC, XOP_CHANNEL_TYPE_DAC, 10, 20, "otherDesc", "EP2", 2)

	DAC = 3 // HS 1
	MIES_EP#EP_AddEpoch(device, DAC, XOP_CHANNEL_TYPE_DAC, 100, 200, "someDesc", "EP_1", 1)
	MIES_EP#EP_AddEpoch(device, DAC, XOP_CHANNEL_TYPE_DAC, 1000, 2000, "otherDesc", "EP_2", -1)

	[key, keyText] = PrepareLBN_IGNORE(device)

	Make/N=(1, 1)/T keys = "Epochs"
	Make/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values
	values[0][0][0] = EP_EpochWaveToStr(epochsWave, 2, XOP_CHANNEL_TYPE_DAC)
	values[0][0][1] = EP_EpochWaveToStr(epochsWave, 3, XOP_CHANNEL_TYPE_DAC)

	ED_AddEntriesToLabnotebook(values, keys, 0, device, DATA_ACQUISITION_MODE)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues = GetLBTextualValues(device)

	return [numericalValues, textualValues, epochsWave]
End

static Function EP_GetEpochsAssertsOnError()

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	try
		EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_COUNT, 0, ".*")
		FAIL()
	catch
		PASS()
	endtry
End

static Function EP_GetEpochsHasNothingInvalidSweep()

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	WAVE/Z result = EP_GetEpochs(numericalValues, textualValues, 1, XOP_CHANNEL_TYPE_DAC, 0, ".*")
	CHECK_WAVE(result, NULL_WAVE)
End

static Function EP_GetEpochsHasNothingInvalidDAC()

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	WAVE/Z result = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 0, ".*")
	CHECK_WAVE(result, NULL_WAVE)
End

static Function EP_GetEpochsNoEpochInfo()

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	WAVE/T epochsWaveEmpty = GetEpochsWave("I_DONT_EXIST")

	WAVE/Z result = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, ".*", epochsWave = epochsWaveEmpty)
	CHECK_WAVE(result, NULL_WAVE)
End

static Function EP_GetEpochsNoMatch()

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	WAVE/Z result = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "I_DONT_EXIST")
	CHECK_WAVE(result, NULL_WAVE)
End

static Function EP_GetEpochsHasMatch()
	string str, expected

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	WAVE/T/Z result = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1")
	CHECK_WAVE(result, TEXT_WAVE)

	CHECK_EQUAL_VAR(DimSize(result, ROWS), 1)
	CHECK_EQUAL_VAR(str2num(result[0][%StartTime]), 1 * MICRO_TO_ONE)
	CHECK_EQUAL_VAR(str2num(result[0][%EndTime]), 2 * MICRO_TO_ONE)
	str = result[0][%Tags]
	expected = "someDesc;ShortName=EP1;"
	CHECK_EQUAL_STR(str, expected)
	CHECK_EQUAL_VAR(str2num(result[0][%TreeLevel]), 1)
End

static Function EP_GetEpochsIgnoresCase()
	string str, expected

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	// same as in EP_GetEpochsHasMatch
	WAVE/T/Z resultUpper = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1")
	CHECK_WAVE(resultUpper, TEXT_WAVE)

	WAVE/T/Z resultLower = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "ep1")
	CHECK_WAVE(resultLower, TEXT_WAVE)

	CHECK_EQUAL_TEXTWAVES(resultUpper, resultLower)
End

static Function EP_GetEpochsWorks()
	string str, expected

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	// same as in EP_GetEpochsHasMatch
	WAVE/T/Z result = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1")
	CHECK_WAVE(result, TEXT_WAVE)

	WAVE/T/Z resultWithLevel = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1", treeLevel = 1)
	CHECK_WAVE(resultWithLevel, TEXT_WAVE)

	CHECK_EQUAL_TEXTWAVES(result, resultWithLevel)

	// treeLevel NaN means all treelevels
	WAVE/T/Z resultNaNTreeLevel = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1", treeLevel = NaN)
	CHECK_WAVE(resultNaNTreeLevel, TEXT_WAVE)

	CHECK_EQUAL_TEXTWAVES(result, resultNaNTreeLevel)

	// unknown treelevel
	WAVE/T/Z resultEmpty = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1", treeLevel = 4711)
	CHECK_WAVE(resultEmpty, NULL_WAVE)

	// no epoch with that treelevel
	WAVE/T/Z resultEmpty = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1", treeLevel = 2)
	CHECK_WAVE(resultEmpty, NULL_WAVE)

	// can read epoch info from epochsWave
	WAVE/T/Z resultFromWave = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1", epochsWave = epochsWave)
	CHECK_WAVE(resultFromWave, TEXT_WAVE)

	CHECK_EQUAL_TEXTWAVES(result, resultFromWave)

	// all epochs with treeLevel 1
	WAVE/T/Z resultAllEpochs = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, ".*", treeLevel = 1)
	CHECK_WAVE(resultAllEpochs, TEXT_WAVE)

	CHECK_EQUAL_VAR(DimSize(resultAllEpochs, ROWS), 3)
	Redimension/N=(3, -1) result
	result[][EPOCH_COL_TREELEVEL] = "1"
	result[1][EPOCH_COL_STARTTIME] = "0.0000020"
	result[1][EPOCH_COL_ENDTIME] = "0.0000030"
	result[1][EPOCH_COL_TAGS] = "someDesc;ShortName=EP_1a;"
	result[2][EPOCH_COL_STARTTIME] = "0.0000040"
	result[2][EPOCH_COL_ENDTIME] = "0.0000050"
	result[2][EPOCH_COL_TAGS] = "someDesc;ShortName=EP_1b;"

	CHECK_EQUAL_TEXTWAVES(result, resultAllEpochs)
End

static Function EP_GetEpochsDoesNotFallbackWithShortNames()

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	WAVE/T/Z resultEmpty = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "someDesc")
	CHECK_WAVE(resultEmpty, NULL_WAVE)

	WAVE/T/Z resultEmpty = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "otherDesc")
	CHECK_WAVE(resultEmpty, NULL_WAVE)
End

static Function/WAVE OldEpochsFormats()

	Make/WAVE/N=2/FREE oldFormats = {root:EpochsWave:EpochsWave_4e534e298, root:EpochsWave:EpochsWave_d150d896e}

	SetDimensionLabels(oldFormats, "EpochsWave_4e534e298;EpochsWave_d150d896e", ROWS)

	return oldFormats
End

// UTF_TD_GENERATOR OldEpochsFormats
static Function EP_GetEpochsWorksWithoutShortNames([WAVE wv])

	WAVE/T/Z result = EP_GetEpochs($"", $"", NaN, XOP_CHANNEL_TYPE_DAC, 0, "Inserted TP", epochsWave = wv)
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 2)

	WAVE/T/Z result = EP_GetEpochs($"", $"", NaN, XOP_CHANNEL_TYPE_DAC, 0, "Test Pulse", epochsWave = wv)
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 2)

	WAVE/T/Z result = EP_GetEpochs($"", $"", NaN, XOP_CHANNEL_TYPE_DAC, 0, "Inserted TP;Test Pulse", epochsWave = wv)
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 2)

	WAVE/T/Z result = EP_GetEpochs($"", $"", NaN, XOP_CHANNEL_TYPE_DAC, 0, "STIM.*", epochsWave = wv)
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 1)
End

static Function EP_GetNextEpochsHasMatch()
	string str, expected

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	WAVE/T/Z result = EP_GetNextEpoch(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1", 1)
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 1)
	CHECK_EQUAL_VAR(str2num(result[0][%StartTime]), 2 * MICRO_TO_ONE)
	CHECK_EQUAL_VAR(str2num(result[0][%EndTime]), 3 * MICRO_TO_ONE)
	str = result[0][%Tags]
	expected = "someDesc;ShortName=EP_1a;"
	CHECK_EQUAL_STR(str, expected)
	CHECK_EQUAL_VAR(str2num(result[0][%TreeLevel]), 1)
End

static Function EP_GetNextEpochsWithGapHasMatch()
	string str, expected

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	WAVE/T/Z result = EP_GetNextEpoch(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP_1a", 1, ignoreGaps=1)
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 1)
	CHECK_EQUAL_VAR(str2num(result[0][%StartTime]), 4e-6)
	CHECK_EQUAL_VAR(str2num(result[0][%EndTime]), 5e-6)
	str = result[0][%Tags]
	expected = "someDesc;ShortName=EP_1b;"
	CHECK_EQUAL_STR(str, expected)
	CHECK_EQUAL_VAR(str2num(result[0][%TreeLevel]), 1)
End

static Function EP_CheckADCToDACMApping()
	string str, expected

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	// HS0 ADC6 -> DAC2
	WAVE/T/Z result = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_ADC, 6, "EP_1a")
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 1)
	CHECK_EQUAL_VAR(str2num(result[0][%StartTime]), 2e-6)
	CHECK_EQUAL_VAR(str2num(result[0][%EndTime]), 3e-6)
	str = result[0][%Tags]
	expected = "someDesc;ShortName=EP_1a;"
	CHECK_EQUAL_STR(str, expected)
	CHECK_EQUAL_VAR(str2num(result[0][%TreeLevel]), 1)
End
