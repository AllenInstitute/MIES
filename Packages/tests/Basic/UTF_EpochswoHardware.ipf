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
	MIES_EP#EP_AddEpoch(device, DAC, 1, 2, "someDesc", "EP1", 1)
	MIES_EP#EP_AddEpoch(device, DAC, 10, 20, "otherDesc", "EP2", 2)

	DAC = 3 // HS 1
	MIES_EP#EP_AddEpoch(device, DAC, 100, 200, "someDesc", "EP_1", 1)
	MIES_EP#EP_AddEpoch(device, DAC, 1000, 2000, "otherDesc", "EP_2", -1)

	[key, keyText] = PrepareLBN_IGNORE(device)

	Make/N=(1, 1)/T keys = "Epochs"
	Make/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values
	values[0][0][0] = EP_EpochWaveToStr(epochsWave, 2)
	values[0][0][1] = EP_EpochWaveToStr(epochsWave, 3)

	ED_AddEntriesToLabnotebook(values, keys, 0, device, DATA_ACQUISITION_MODE)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues = GetLBTextualValues(device)

	return [numericalValues, textualValues, epochsWave]
End

static Function EP_GetEpochsAssertsOnError()

	[WAVE numericalValues, WAVE/T textualValues, WAVE/T epochsWave] = PrepareEpochsTable_IGNORE()

	try
		EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_TTL, 0, ".*")
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

	// all epochs with treeLevel 1
	WAVE/T/Z resultAllEpochs = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, ".*", treeLevel = 1)
	CHECK_WAVE(resultAllEpochs, TEXT_WAVE)

	CHECK_EQUAL_TEXTWAVES(result, resultAllEpochs)

	// can read epoch info from epochsWave
	WAVE/T/Z resultFromWave = EP_GetEpochs(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_DAC, 2, "EP1", epochsWave = epochsWave)
	CHECK_WAVE(resultFromWave, TEXT_WAVE)

	CHECK_EQUAL_TEXTWAVES(result, resultFromWave)
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
