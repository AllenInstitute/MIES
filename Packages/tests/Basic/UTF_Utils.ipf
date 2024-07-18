#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UtilsTest

// UTF_TD_GENERATOR InfiniteValues
static Function IVSN_WorksSpecialValues([variable val])

	CHECK(!IsValidSweepNumber(val))
End

static Function IVSN_Works()

	CHECK(!IsValidSweepNumber(INVALID_SWEEP_NUMBER))
	CHECK(IsValidSweepNumber(0))
	CHECK(IsValidSweepNumber(1000))
End

/// DAP_GetRAAcquisitionCycleID
/// @{

static StrConstant device = "ITC18USB_DEV_0"

Function AssertOnInvalidSeed()
	NVAR rngSeed = $GetRNGSeed(device)
	rngSeed = NaN

	try
		MIES_DAP#DAP_GetRAAcquisitionCycleID(device)
		FAIL()
	catch
		PASS()
	endtry
End

Function CreatesReproducibleResults()
	NVAR rngSeed = $GetRNGSeed(device)

	// Use GetNextRandomNumberForDevice directly
	// as we don't have a locked device

	rngSeed = 1
	Make/FREE/N=1024/L dataInt = GetNextRandomNumberForDevice(device)
	CHECK_EQUAL_VAR(2932874867, WaveCRC(0, dataInt))

	rngSeed = 1
	Make/FREE/N=1024/D dataDouble = GetNextRandomNumberForDevice(device)

	CHECK_EQUAL_WAVES(dataInt, dataDouble, mode = WAVE_DATA)
End
/// @}

/// ITCConfig Wave querying
/// @{

Function ITCC_WorksLegacy()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_legacy
	CHECK(IsValidConfigWave(config, version = 0))

	WAVE/T/Z units = AFH_GetChannelUnits(config)
	CHECK_WAVE(units, TEXT_WAVE)
	// we have one TTL channel which does not have a unit
	CHECK_EQUAL_VAR(DimSize(units, ROWS) + 1, DimSize(config, ROWS))
	CHECK_EQUAL_TEXTWAVES(units, {"DA0", "DA1", "DA2", "AD0", "AD1", "AD2"})

	for(i = 0; i < 3; i += 1)
		type     = XOP_CHANNEL_TYPE_DAC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)

		type     = XOP_CHANNEL_TYPE_ADC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)
	endfor

	WAVE/Z DACs = GetDACListFromConfig(config)
	CHECK_WAVE(DACs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z ADCs = GetADCListFromConfig(config)
	CHECK_WAVE(ADCs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z TTLs = GetTTLListFromConfig(config)
	CHECK_WAVE(TTLs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(TTLS, {1}, mode = WAVE_DATA)
End

Function ITCC_WorksVersion1()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_Version1
	CHECK(IsValidConfigWave(config, version = 1))

	WAVE/T/Z units = AFH_GetChannelUnits(config)
	CHECK_WAVE(units, TEXT_WAVE)
	// we have one TTL channel which does not have a unit
	CHECK_EQUAL_VAR(DimSize(units, ROWS) + 1, DimSize(config, ROWS))
	CHECK_EQUAL_TEXTWAVES(units, {"DA0", "DA1", "DA2", "AD0", "AD1", "AD2"})

	for(i = 0; i < 3; i += 1)
		type     = XOP_CHANNEL_TYPE_DAC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)

		type     = XOP_CHANNEL_TYPE_ADC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)
	endfor

	WAVE/Z DACs = GetDACListFromConfig(config)
	CHECK_WAVE(DACs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z ADCs = GetADCListFromConfig(config)
	CHECK_WAVE(ADCs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z TTLs = GetTTLListFromConfig(config)
	CHECK_WAVE(TTLs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(TTLS, {1}, mode = WAVE_DATA)
End

Function ITCC_WorksVersion2()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_Version2
	CHECK(IsValidConfigWave(config, version = 2))

	WAVE/T/Z units = AFH_GetChannelUnits(config)
	CHECK(WaveExists(units))
	// we have one TTL channel which does not have a unit
	CHECK_EQUAL_VAR(DimSize(units, ROWS) + 1, DimSize(config, ROWS))
	CHECK_EQUAL_TEXTWAVES(units, {"DA0", "DA1", "DA2", "AD0", "AD1", "AD2"})

	for(i = 0; i < 3; i += 1)
		type     = XOP_CHANNEL_TYPE_DAC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)

		type     = XOP_CHANNEL_TYPE_ADC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)
	endfor

	WAVE/Z DACs = GetDACListFromConfig(config)
	CHECK_WAVE(DACs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z ADCs = GetADCListFromConfig(config)
	CHECK_WAVE(ADCs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z TTLs = GetTTLListFromConfig(config)
	CHECK_WAVE(TTLs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(TTLS, {1}, mode = WAVE_DATA)

	WAVE/Z DACmode = GetDACTypesFromConfig(config)
	CHECK_WAVE(DACmode, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACmode, {1, 2, 2}, mode = WAVE_DATA)

	WAVE/Z ADCmode = GetADCTypesFromConfig(config)
	CHECK_WAVE(ADCmode, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCmode, {2, 1, 2}, mode = WAVE_DATA)
End

/// @}

/// FindIndizes
/// @{

Function FI_NumSearchWithCol1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, var = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithCol1Inverted()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, var = 1, prop = PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndLayer1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, var = 1, startLayer = 0, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndLayer2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, var = 1, startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithCol2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "2")
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

Function FI_NumSearchWithCol3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 2, var = 4711)
	CHECK_WAVE(indizes, NULL_WAVE)
End

Function FI_NumSearchWithColLabel()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", var = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndStr()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", str = "1")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", prop = PROP_EMPTY | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, colLabel = "abcd", prop = PROP_EMPTY)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, var = 2, prop = PROP_MATCHES_VAR_BIT_MASK)
	CHECK_EQUAL_WAVES(indizes, {1, 2, 3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp4()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, var = 2, prop = PROP_MATCHES_VAR_BIT_MASK | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp5()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "6+", prop = PROP_GREP)
	CHECK_EQUAL_WAVES(indizes, {3}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp5Inverted()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "6+", prop = PROP_GREP | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp6()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "6*", prop = PROP_WILDCARD)
	CHECK_EQUAL_WAVES(indizes, {3}, mode = WAVE_DATA)
End

static Function FI_NumSearchWithColAndProp6Inverted()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "6*", prop = PROP_WILDCARD | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithColAndProp6a()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, str = "!*2.00000", prop = PROP_WILDCARD)
	CHECK_EQUAL_WAVES(indizes, {0, 3, 4}, mode = WAVE_DATA)
End

Function FI_NumSearchWithRestRows()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	WAVE/Z indizes = FindIndizes(numeric, col = 1, var = 2, startRow = 2, endRow = 3)
	CHECK_EQUAL_WAVES(indizes, {2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithCol1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, str = "text123")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndLayer1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, str = "text123", startLayer = 0, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2, 3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndLayer2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, str = "text123", startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithCol2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2")
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithCol3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 2, str = "4711")
	CHECK_WAVE(indizes, NULL_WAVE)
End

Function FI_TextSearchWithColLabel()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", str = "text123")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndVar()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, var = 2)
	CHECK_EQUAL_WAVES(indizes, {1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchIgnoresCase()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", str = "TEXT123")
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", prop = PROP_EMPTY | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0, 1, 2}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, colLabel = "efgh", prop = PROP_EMPTY)
	CHECK_EQUAL_WAVES(indizes, {3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2", prop = PROP_MATCHES_VAR_BIT_MASK)
	CHECK_EQUAL_WAVES(indizes, {1, 2, 3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp4()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2", prop = PROP_MATCHES_VAR_BIT_MASK | PROP_NOT)
	CHECK_EQUAL_WAVES(indizes, {0}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp5()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "^1.*$", prop = PROP_GREP, startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithColAndProp6()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "1*", prop = PROP_WILDCARD, startLayer = 1, endLayer = 1)
	CHECK_EQUAL_WAVES(indizes, {0, 3, 4}, mode = WAVE_DATA)
End

Function FI_TextSearchWithRestRows()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr text

	WAVE/Z indizes = FindIndizes(text, col = 1, str = "2", startRow = 2, endRow = 3)
	CHECK_EQUAL_WAVES(indizes, {2}, mode = WAVE_DATA)
End

Function FI_EmptyWave()
	Make/FREE/N=0 emptyWave
	WAVE/Z indizes = FindIndizes(emptyWave, var = NaN)
	CHECK_WAVE(indizes, NULL_WAVE)
End

Function FI_AbortsWithInvalidParams1()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams2()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 1, str = "123")
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams3()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, prop = 4711)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams4()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, col = 0, colLabel = "dup")
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams5()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 0, startRow = 100)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams6()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 0, endRow = 100)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams7()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 0, startRow = 3, endRow = 2)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams8()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = NaN)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams9()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, str = "NaN")
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams10()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 1, startLayer = 1)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams11()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		WAVE/Z indizes = FindIndizes(numeric, var = 1, startLayer = 100, endLayer = 100)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidParams12()

	Make/FREE/N=(1, 2, 3, 4) data
	try
		WAVE/Z indizes = FindIndizes(data, var = 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidWave()

	try
		FindIndizes($"", var = 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function FI_AbortsWithInvalidRegExp()
	DFREF dfr = root:FindIndizes
	WAVE/SDFR=dfr numeric

	try
		FindIndizes(numeric, str = "*", prop = PROP_GREP)
		FAIL()
	catch
		PASS()
	endtry
End
/// @}

/// @{
/// oodDAQ regression tests

static Function oodDAQStore_IGNORE(stimset, offsets, regions, index)
	WAVE/WAVE stimset
	WAVE offsets, regions
	variable index

	variable i

	DFREF dfr = root:oodDAQ

	for(i = 0; i < DimSize(stimset, ROWS); i += 1)
		WAVE singleStimset = stimset[i]
		Duplicate/O singleStimset, dfr:$("stimset_oodDAQ_" + num2str(index) + "_" + num2str(i))
	endfor

	Duplicate/O offsets, dfr:$("offsets_" + num2str(index))
	Duplicate/O regions, dfr:$("regions_" + num2str(index))
End

static Function/WAVE GetoodDAQ_RefWaves_IGNORE(index)
	variable index

	variable i

	Make/FREE/WAVE/N=(64, 3) wv

	SetDimLabel COLS, 0, stimset, wv
	SetDimLabel COLS, 1, offset, wv
	SetDimLabel COLS, 2, region, wv

	DFREF dfr = root:oodDAQ

	for(i = 0; i < DimSize(wv, ROWS); i += 1)
		WAVE/Z/SDFR=dfr ref_stimset = $("stimset_oodDAQ_" + num2str(index) + "_" + num2str(i))

		if(!WaveExists(ref_stimset))
			break
		endif

		wv[i][%stimset] = ref_stimset
	endfor

	WAVE/Z/SDFR=dfr ref_offsets = $("offsets_" + num2str(index))
	WAVE/Z/SDFR=dfr ref_regions = $("regions_" + num2str(index))

	wv[0][%offset] = ref_offsets
	wv[0][%region] = ref_regions

	return wv
End

Function oodDAQRegTests_0()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 0
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_1()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 1
	InitOOdDAQParams(params, stimSet, {1, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_2()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 2
	InitOOdDAQParams(params, stimSet, {0, 1}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_3()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 3
	InitOOdDAQParams(params, stimSet, {0, 0}, 20, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_4()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 4
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 20)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_5()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 5
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_6()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 6
	InitOOdDAQParams(params, stimSet, {0, 1}, 20, 30)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_7()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=3/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 7
	InitOOdDAQParams(params, stimSet, {0, 0, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2][%stimset], stimset[2])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

/// @}

/// FloatWithMinSigDigits
/// @{

Function/WAVE InvalidSignDigits()

	Make/FREE digits = {-1, NaN, Inf, -Inf}

	return digits
End

// UTF_TD_GENERATOR InvalidSignDigits
Function FloatWithMinSigDigitsAborts([var])
	variable var
	try
		FloatWithMinSigDigits(1.234, numMinSignDigits = var)
		FAIL()
	catch
		PASS()
	endtry
End

Function FloatWithMinSigDigitsWorks()

	string result, expected

	result   = FloatWithMinSigDigits(1.234, numMinSignDigits = 0)
	expected = "1"
	CHECK_EQUAL_STR(result, expected)

	result   = FloatWithMinSigDigits(-1.234, numMinSignDigits = 0)
	expected = "-1"
	CHECK_EQUAL_STR(result, expected)

	result   = FloatWithMinSigDigits(1e-2, numMinSignDigits = 2)
	expected = "0.01"
	CHECK_EQUAL_STR(result, expected)
End

/// @}

/// DecimateWithMethod
/// @{

Function TestDecimateWithMethodInvalid()

	variable newSize, numRows, decimationFactor, method, err

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 2
	method           = DECIMATION_MINMAX
	Make/FREE/N=(DimSize(data, ROWS) / 2) output

	try
		DecimateWithMethod(data, output, 1, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, $"", decimationFactor, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod($"", output, decimationFactor, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, 0, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, Inf, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, -5); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		Duplicate/FREE output, outputWrong
		Redimension/N=(5) outputWrong
		DecimateWithMethod(data, outputWrong, decimationFactor, method); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastRowInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstColInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, firstColInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastColInp = -1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, lastColInp = 100); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		DecimateWithMethod(data, output, decimationFactor, method, factor = $""); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry

	try
		Make/N=(100)/FREE factor
		DecimateWithMethod(data, output, decimationFactor, method, factor = factor); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(-1)
		PASS()
	endtry
End

Function TestDecimateWithMethodDec1()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 8
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 2)
	Make/FREE/D/N=(newSize) output

	Make/FREE refOutput = {10, 800}
	Make/N=(1)/FREE factor = {100}

	DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = 1, lastRowInp = 15, firstColInp = 0, lastColInp = 0, factor = factor)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

Function TestDecimateWithMethodDec2()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 2
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 8)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 2, 0.3, 4, 0.5, 6, 0.7, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

Function TestDecimateWithMethodDec3()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 4
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 4, 0.5, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// decimation does not give a nice new size but it still works
Function TestDecimateWithMethodDec4()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 3
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 6)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 3, 0.4, 6, 0.7, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// decimation so large that only two points remain
Function TestDecimateWithMethodDec5()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 1000
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 2)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 8}

	DecimateWithMethod(data, output, decimationFactor, method)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// respects columns
Function TestDecimateWithMethodDec6()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 4
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/D/FREE/N=(newSize, 2) output
	Make/D/FREE refOutput = {{0, 0, 0, 0}, {0.1, 4, 0.5, 8}}

	DecimateWithMethod(data, output, decimationFactor, method, firstColInp = 1)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// respects factor and has different output column
Function TestDecimateWithMethodDec7()

	variable newSize, numRows, decimationFactor, method

	Make/D/FREE data = {{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 4
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/D/N=(newSize, 2)/FREE output = {{-10, -400, -50, -800}, {2, 2, 2, 2}}
	// factor leaves first column untouched
	Make/D/FREE refOutput = {{-10, -400, -50, -800}, {2, 2, 2, 2}}
	Make/N=(1)/FREE factor = {-100}

	DecimateWithMethod(data, output, decimationFactor, method, factor = factor, firstColInp = 1, firstColOut = 0, lastColOut = 0)
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

// works with doing it in chunks
Function TestDecimateWithMethodDec8()

	variable newSize, numRows, decimationFactor, method, i

	Make/D/FREE data = {0.1, 1, 0.2, 2, 0.3, 3, 0.4, 4, 0.5, 5, 0.6, 6, 0.7, 7, 0.8, 8}
	numRows          = DimSize(data, ROWS)
	decimationFactor = 4
	method           = DECIMATION_MINMAX
	newSize          = GetDecimatedWaveSize(numRows, decimationFactor, method)
	CHECK_EQUAL_VAR(newSize, 4)
	Make/FREE/D/N=(newSize) output
	Make/D/FREE refOutput = {0.1, 4, 0.5, 8}

	Make/FREE chunks = {{0, 2}, {3, 8}, {9, 15}}

	for(i = 0; i < DimSize(chunks, COLS); i += 1)
		DecimateWithMethod(data, output, decimationFactor, method, firstRowInp = chunks[0][i], lastRowInp = chunks[1][i])
		switch(i)
			case 0:
				CHECK_EQUAL_WAVES(output, {0.1, 1, 0, 0}, mode = WAVE_DATA, tol = 1e-10)
				break
			case 1:
				CHECK_EQUAL_WAVES(output, {0.1, 4, 0.5, 0.5}, mode = WAVE_DATA, tol = 1e-10)
				break
			case 2:
				CHECK_EQUAL_WAVES(output, {0.1, 4, 0.5, 8}, mode = WAVE_DATA, tol = 1e-10)
				break
			default:
				FAIL()
		endswitch
	endfor

	CHECK_EQUAL_VAR(i, DimSize(chunks, COLS))
	CHECK_EQUAL_WAVES(output, refOutput, mode = WAVE_DATA)
End

/// @}

/// GetNotebookText/ReplaceNotebookText
/// @{

Function GNT_Works()

	string expected, result
	string win = "nb0"
	expected = "abcd 123"

	KillWindow/Z $win

	NewNotebook/N=$win/F=0
	Notebook $win, setData=expected

	result = GetNotebookText("nb0")
	CHECK_EQUAL_STR(expected, result)

	expected = "hi there!"
	ReplaceNotebookText(win, expected)
	result = GetNotebookText("nb0")
	CHECK_EQUAL_STR(expected, result)
End

/// @}

/// RestoreCursors
/// @{

Function RC_WorksWithReplacementTrace()

	string info, graph

	Make data

	Display data
	graph = S_name

	Cursor A, data, 30
	WAVE/T cursorInfos = GetCursorInfos(graph)

	RemoveTracesFromGraph(graph)

	AppendToGraph data/TN=abcd
	RestoreCursors(graph, cursorInfos)

	info = CsrInfo(A, graph)
	CHECK_PROPER_STR(info)

	KillWindow/Z $graph
	KillWaves/Z data
End

/// @}

/// MiesUtils XOP functions
/// @{

#ifndef THREADING_DISABLED

Function RunningInMainThread_Thread()

	make/FREE data
	multithread data = MU_RunningInMainThread()
	CHECK_EQUAL_VAR(Sum(data), 0)
End

#endif

Function RunningInMainThread_Main()

	make/FREE data
	data = MU_RunningInMainThread()
	CHECK_EQUAL_VAR(Sum(data), 128)
End

/// @}

/// GetSettingsJSONid
/// @{

Function GSJIWorks()

	NVAR/Z jsonID = $GetSettingsJSONid()
	CHECK(NVAR_Exists(jsonID))
	CHECK(JSON_Exists(jsonID, ""))
End

Function GSJIWorksWithCorruptID()

	NVAR/Z jsonID = $GetSettingsJSONid()
	CHECK(NVAR_Exists(jsonID))

	// close the JSON document to fake an invalid ID
	JSON_Release(jsonID)

	// fetching again now returns a valid ID again
	NVAR/Z jsonID = $GetSettingsJSONid()
	CHECK(NVAR_Exists(jsonID))
	CHECK(JSON_Exists(jsonID, ""))
End

/// @}

/// Backup functions
/// - CreateBackupWave
/// - CreateBackupWavesForAll
/// - GetBackupWave
/// - ReplaceWaveWithBackup
/// - ReplaceWaveWithBackupForAll
/// @{

Function CreateBackupWaveChecksArgs()

	// asserts out when passing a free wave
	try
		Make/FREE wv
		CreateBackupWave(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function CreateBackupWaveBasics()
	Make data
	WAVE/Z bak = CreateBackupWave(data)
	CHECK_WAVE(bak, NORMAL_WAVE)
	CHECK_EQUAL_WAVES(bak, data)

	KillWaves/Z data, bak
End

Function CreateBackupWaveCorrectNaming()

	string actual, expected

	Make data
	WAVE/Z bak = CreateBackupWave(data)

	// naming is correct
	actual   = NameOfWave(bak)
	expected = "data_bak"
	CHECK_EQUAL_STR(actual, expected)

	KillWaves/Z data, bak
End

Function CreateBackupWaveNoUnwantedRecreation()

	variable modCount

	// does not recreate it when called again
	Make data
	WAVE/Z bak = CreateBackupWave(data)
	modCount = WaveModCount(bak)

	WAVE/Z bakAgain = CreateBackupWave(data)

	CHECK_WAVE(bakAgain, NORMAL_WAVE)
	CHECK(WaveRefsEqual(bak, bakAgain))
	CHECK_EQUAL_VAR(modCount, WaveModCount(bakAgain))

	KillWaves/Z data, bak
End

Function CreateBackupWaveAllowsForcingRecreation()

	variable modCount

	// except when we force it
	Make data
	WAVE/Z bak = CreateBackupWave(data)
	modCount = WaveModCount(bak)

	WAVE/Z bakAgain = CreateBackupWave(data, forceCreation = 1)

	CHECK_GT_VAR(WaveModCount(bakAgain), modCount)

	KillWaves/Z data, bak
End

Function/DF PrepareFolderForBackup_IGNORE()

	variable numElements
	NewDataFolder folder
	Make :folder:data1 = p
	Make :folder:data2 = P^2
	string/G   :folder:str
	variable/G :folder:var
	NewDataFolder :folder:test

	DFREF dfr = $"folder"
	return dfr
End

Function CountElementsInFolder_IGNORE(DFREF dfr)
	return CountObjectsDFR(dfr, COUNTOBJECTS_WAVES) + CountObjectsDFR(dfr, COUNTOBJECTS_VAR)      \
	       + CountObjectsDFR(dfr, COUNTOBJECTS_STR) + CountObjectsDFR(dfr, COUNTOBJECTS_DATAFOLDER)
End

Function CreateBackupWaveForAllWorks()

	DFREF    dfr         = PrepareFolderForBackup_IGNORE()
	variable numElements = CountElementsInFolder_IGNORE(dfr)

	CreateBackupWavesForAll(dfr)

	CHECK_EQUAL_VAR(CountElementsInFolder_IGNORE(dfr), numElements + 2)

	WAVE/Z/SDFR=dfr data1_bak, data2_bak
	CHECK_WAVE(data1_bak, NORMAL_WAVE)
	CHECK_WAVE(data2_bak, NORMAL_WAVE)

	KillDataFolder/Z dfr
End

Function GetBackupWaveChecksArgs()

	// asserts out when passing a free wave
	try
		Make/FREE wv
		GetBackupWave(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetBackupWaveMightReturnNull()

	Make data
	WAVE/Z bak = GetBackupWave(data)
	CHECK_WAVE(bak, NULL_WAVE)

	KillWaves/Z data, bak
End

Function GetBackupWaveWorks()

	Make data
	WAVE/Z bak1 = CreateBackupWave(data)
	WAVE/Z bak2 = GetBackupWave(data)

	CHECK_WAVE(bak1, NORMAL_WAVE)
	CHECK_WAVE(bak2, NORMAL_WAVE)
	CHECK(WaveRefsEqual(bak1, bak2))

	KillWaves/Z data, bak1, bak2
End

Function ReplaceWaveWithBackupWorks()

	variable originalSum

	Make data = p
	WAVE bak = CreateBackupWave(data)
	originalSum = Sum(data)
	data        = 0

	CHECK_EQUAL_VAR(Sum(data), 0)

	WAVE/Z dataOrig = ReplaceWaveWithBackup(data)
	CHECK_WAVE(dataOrig, NORMAL_WAVE)
	CHECK_EQUAL_VAR(Sum(dataOrig), originalSum)
	CHECK(WaveRefsEqual(data, dataOrig))

	KillWaves/Z data, bak
End

Function ReplaceWaveWithBackupNonExistingBackupIsFatal()

	// backups are required by default
	try
		Make data
		ReplaceWaveWithBackup(data)
		FAIL()
	catch
		PASS()
	endtry

	KillWaves/Z data
End

Function ReplaceWaveWithBackupNonExistingBackupIsOkay()

	// but that can be turned off
	Make data
	WAVE/Z bak = ReplaceWaveWithBackup(data, nonExistingBackupIsFatal = 0)
	CHECK_WAVE(bak, NULL_WAVE)

	KillWaves/Z data, bak
End

Function ReplaceWaveWithBackupRemoval()

	Make data
	CreateBackupWave(data)
	ReplaceWaveWithBackup(data)

	// by default the backup is removed
	WAVE/Z bak = GetBackupWave(data)
	CHECK_WAVE(bak, NULL_WAVE)

	KillWaves/Z data, bak
End

Function ReplaceWaveWithBackupKeeping()

	Make data

	// but that can be turned off
	CreateBackupWave(data)
	ReplaceWaveWithBackup(data, keepBackup = 1)
	WAVE/Z bak = GetBackupWave(data)
	CHECK_WAVE(bak, NORMAL_WAVE)

	KillWaves/Z data, bak
End

Function ReplaceWaveWithBackupForAllNonFatal()

	DFREF    dfr         = PrepareFolderForBackup_IGNORE()
	variable numElements = CountElementsInFolder_IGNORE(dfr)
	ReplaceWaveWithBackupForAll(dfr)
	CHECK_EQUAL_VAR(CountElementsInFolder_IGNORE(dfr), numElements)

	KillDataFolder/Z dfr
End

Function ReplaceWaveWithBackupForAllWorks()

	variable originalSum1, originalSum2

	DFREF    dfr         = PrepareFolderForBackup_IGNORE()
	variable numElements = CountElementsInFolder_IGNORE(dfr)

	WAVE/SDFR=dfr data1

	WAVE/SDFR=dfr data1
	originalSum1 = Sum(data1)

	WAVE/SDFR=dfr data2
	originalSum2 = Sum(data2)

	CreateBackupWavesForAll(dfr)

	data1 = 0
	data2 = 0
	CHECK_EQUAL_VAR(Sum(data1), 0)
	CHECK_EQUAL_VAR(Sum(data2), 0)

	ReplaceWaveWithBackupForAll(dfr)

	WAVE/SDFR=dfr data1_restored = data1
	WAVE/SDFR=dfr data2_restored = data2
	CHECK_EQUAL_VAR(Sum(data1_restored), originalSum1)
	CHECK_EQUAL_VAR(Sum(data2_restored), originalSum2)

	// backup waves are kept
	CHECK_EQUAL_VAR(CountElementsInFolder_IGNORE(dfr), numElements + 2)

	KillDataFolder/Z dfr
End

/// @}

/// ExtractSweepNumber
/// @{

Function/WAVE GetValidStringsWithSweepNumber()

	Make/FREE/T wv = {"Sweep_100", "Sweep_100_bak", "Config_Sweep_100", "Config_Sweep_100_bak", "X_100"}

	return wv
End

// UTF_TD_GENERATOR GetValidStringsWithSweepNumber
Function ESN_Works([string str])

	CHECK_EQUAL_VAR(ExtractSweepNumber(str), 100)
End

Function/WAVE GetInvalidStringsWithSweepNumber()

	Make/FREE/T wv = {"", "A", "A__", "Sweep_-100"}

	return wv
End

// UTF_TD_GENERATOR GetInvalidStringsWithSweepNumber
Function ESN_Complains([string str])

	variable err

	try
		ExtractSweepNumber(str); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry
End

/// @}

/// GetUserDataKeys
/// @{

Function GUD_ReturnsNullWaveIfNothingFound()
	string recMacro, win

	Display
	win = s_name

	recMacro = WinRecreation(win, 0)
	WAVE/T/Z userDataKeys = GetUserdataKeys(recMacro)

	CHECK_WAVE(userDataKeys, NULL_WAVE)
End

Function GUD_ReturnsFoundEntries()
	string recMacro, win

	Display
	win = s_name
	SetWindow $win, userdata(abcd)="123"
	SetWindow $win, userData(efgh)="456"

	recMacro = WinRecreation(win, 0)
	WAVE/T userDataKeys = GetUserdataKeys(recMacro)

	CHECK_EQUAL_TEXTWAVES(userDataKeys, {"abcd", "efgh"})
End

Function GUD_ReturnsFoundEntriesWithoutDuplicates()
	string recMacro, win

	Display
	win = s_name

	// create lines a la
	//
	//	SetWindow kwTopWin,userdata(abcd)=  "123456                                                                                              "
	//	SetWindow kwTopWin,userdata(abcd) +=  "                                                                                                    "
	SetWindow $win, userdata(abcd)="123"
	SetWindow $win, userData(abcd)+=PadString("456", 1e3, 0x20)

	recMacro = WinRecreation(win, 0)
	WAVE/T userDataKeys = GetUserdataKeys(recMacro)

	CHECK_EQUAL_TEXTWAVES(userDataKeys, {"abcd"})
End

/// @}

Function SICP_EnsureValidGUIs()

	string   panel
	variable keepDebugPanel

	// avoid that the default TEST_CASE_BEGIN_OVERRIDE
	// hook keeps our debug panel open if it did not exist before
	keepDebugPanel = WindowExists("DebugPanel")

	panel = DAP_CreateDAEphysPanel()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	panel = WBP_CreateWaveBuilderPanel()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	panel = DB_OpenDataBrowser()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	panel = AB_OpenAnalysisBrowser()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	IVS_CreatePanel()
	panel = GetCurrentWindow()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	panel = DP_OpenDebugPanel()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	if(!keepDebugPanel)
		KillWindow/Z DebugPanel
	endif
End

Function RPI_WorksWithOldData()
	string epochInfo

	// 4e534e29 (Pulse Averaging: Pulse starting times are now read from the lab notebook, 2020-10-07)
	// no level 3 info
	epochInfo = EP_EpochWaveToStr(root:EpochsWave:EpochsWave_4e534e298, 0, XOP_CHANNEL_TYPE_DAC)
	WAVE/Z pulseInfos = MIES_PA#PA_RetrievePulseInfosFromEpochs(epochInfo)
	CHECK_WAVE(pulseInfos, NULL_WAVE)

	// d150d896 (DC_AddEpochsFromStimSetNote: Add sub sub epoch information, 2021-02-02)
	epochInfo = EP_EpochWaveToStr(root:EpochsWave:EpochsWave_d150d896e, 0, XOP_CHANNEL_TYPE_DAC)
	WAVE/Z pulseInfos_d150d896e = MIES_PA#PA_RetrievePulseInfosFromEpochs(epochInfo)
	CHECK_WAVE(pulseInfos_d150d896e, NUMERIC_WAVE)

	// 22c735d7 (Merge pull request #1130 from AllenInstitute/feature/1130-fix-is-constant, 2021-11-03)
	epochInfo = EP_EpochWaveToStr(root:EpochsWave:EpochsWave_22c735d7, 0, XOP_CHANNEL_TYPE_DAC)
	WAVE/Z pulseInfos_22c735d7 = MIES_PA#PA_RetrievePulseInfosFromEpochs(epochInfo)
	CHECK_WAVE(pulseInfos_22c735d7, NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(pulseInfos_d150d896e, pulseInfos_22c735d7, mode = WAVE_DATA)
End

Function/S CreateTestPanel_IGNORE()
	string win

	NewPanel/K=1
	win = S_name

	SetVariable setVar0, noEdit=1, format="%g"

	return win
End

Function GCP_Var_Works()
	string win, recMacro
	variable var, controlType

	win = CreateTestPanel_IGNORE()
	[recMacro, controlType] = GetRecreationMacroAndType(win, "setVar0")
	CHECK_EQUAL_VAR(controlType, CONTROL_TYPE_SETVARIABLE)

	// existing
	var = GetControlSettingVar(recMacro, "noEdit")
	CHECK_EQUAL_VAR(var, 1)

	// non-present, default defValue
	var = GetControlSettingVar(recMacro, "I DONT EXIST")
	CHECK_EQUAL_VAR(var, NaN)

	// non-present, custom defValue
	var = GetControlSettingVar(recMacro, "I DONT EXIST", defValue = 123)
	CHECK_EQUAL_VAR(var, 123)
End

Function GCP_Str_Works()
	string win, ref, str, recMacro
	variable controlType

	win = CreateTestPanel_IGNORE()
	[recMacro, controlType] = GetRecreationMacroAndType(win, "setVar0")
	CHECK_EQUAL_VAR(controlType, CONTROL_TYPE_SETVARIABLE)

	// existing
	str = GetControlSettingStr(recMacro, "format")
	ref = "%g"
	CHECK_EQUAL_STR(str, ref)

	// non-present, default defValue
	str = GetControlSettingStr(recMacro, "I DONT EXIST")
	CHECK_EMPTY_STR(str)

	// non-present, custom defValue
	str = GetControlSettingStr(recMacro, "I DONT EXIST", defValue = "123")
	ref = "123"
	CHECK_EQUAL_STR(str, ref)
End

Function BUGWorks()
	variable bugCount

	bugCount = ROVar(GetBugCount())
	CHECK_EQUAL_VAR(bugCount, 0)

	BUG("abcd")

	bugCount = ROVar(GetBugCount())
	CHECK_EQUAL_VAR(bugCount, 1)

	DisableBugChecks()
End

Function BUG_TSWorks1()
	variable bugCount

	TUFXOP_Clear/N=(TSDS_BUGCOUNT)/Q/Z

	bugCount = TSDS_ReadVar(TSDS_BUGCOUNT)
	CHECK_EQUAL_VAR(bugCount, NaN)

	BUG_TS("abcd")

	bugCount = TSDS_ReadVar(TSDS_BUGCOUNT)
	CHECK_EQUAL_VAR(bugCount, 1)

	DisableBugChecks()
End

threadsafe static Function BugHelper(variable idx)

	BUG_TS(num2str(idx))

	return TSDS_ReadVar(TSDS_BUGCOUNT) == 0
End

Function BUG_TSWorks2()
	variable bugCount, numThreads

	TUFXOP_Clear/N=(TSDS_BUGCOUNT)/Q/Z

	bugCount = TSDS_ReadVar(TSDS_BUGCOUNT)
	CHECK_EQUAL_VAR(bugCount, NaN)

	numThreads = 10

	Make/FREE/N=(numThreads) junk = NaN

	MultiThread/NT=(numThreads) junk = BugHelper(p)

	CHECK_EQUAL_VAR(Sum(junk), 0)

	bugCount = TSDS_ReadVar(TSDS_BUGCOUNT)
	CHECK_EQUAL_VAR(bugCount, numThreads)

	DisableBugChecks()
End

static Function FBD_CheckParams()

	variable lastIndex

	Make/FREE/N=0/T input = {""}

	WAVE/Z/T filtered = $""

	try
		[filtered, lastIndex] = FilterByDate(input, NaN, 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		[filtered, lastIndex] = FilterByDate(input, 0, NaN)
		FAIL()
	catch
		PASS()
	endtry

	try
		[filtered, lastIndex] = FilterByDate(input, 0, -1)
		FAIL()
	catch
		PASS()
	endtry

	try
		[filtered, lastIndex] = FilterByDate(input, -1, 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		[filtered, lastIndex] = FilterByDate(input, 2, 1)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FBD_Works()
	variable last, first

	variable lastIndex

	WAVE/Z/T result = $""

	// empty gives null
	Make/FREE/T/N=0 input
	[result, lastIndex] = FilterByDate(input, 0, 1)
	CHECK_WAVE(result, NULL_WAVE)

	Make/FREE/T input = {"{\"ts\" : \"2021-12-24T00:00:00Z\", \"stuff\" : \"abcd\"}", \
	                     "{\"ts\" : \"2022-01-20T00:00:00Z\", \"stuff\" : \"efgh\"}", \
	                     "{\"ts\" : \"2022-01-25T00:00:00Z\", \"stuff\" : \"ijkl\"}"}

	// borders are included (1)
	Make/FREE/T ref = {"{\"ts\" : \"2021-12-24T00:00:00Z\", \"stuff\" : \"abcd\"}", \
	                   "{\"ts\" : \"2022-01-20T00:00:00Z\", \"stuff\" : \"efgh\"}"}

	first = 0
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, 1)

	// borders are included (2)
	Make/FREE/T ref = {"{\"ts\" : \"2021-12-24T00:00:00Z\", \"stuff\" : \"abcd\"}", \
	                   "{\"ts\" : \"2022-01-20T00:00:00Z\", \"stuff\" : \"efgh\"}"}

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, 1)

	// will result null if nothing is in range (1)
	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z") + 1
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z") - 1
	[result, lastIndex] = FilterByDate(input, first, last)
	CHECK_WAVE(result, NULL_WAVE)

	// will result null if nothing is in range (2)
	first = ParseIsO8601TimeStamp("2020-01-01T00:00:00Z")
	last  = ParseIsO8601TimeStamp("2020-12-31T00:00:00Z")
	[result, lastIndex] = FilterByDate(input, first, last)
	CHECK_WAVE(result, NULL_WAVE)
End

static Function FBD_WorksWithInvalidTimeStamp()

	variable last, first
	variable lastIndex

	WAVE/Z/T result = $""

	Make/FREE/T input2 = {"{}", "{}", "{\"ts\" : \"2021-12-24T00:00:00Z\"}", \
	                      "{}", "{}", "{\"ts\" : \"2022-01-20T00:00:00Z\"}", \
	                      "{}", "{}", "{\"ts\" : \"2022-01-25T00:00:00Z\"}", \
	                      "{}", "{}"}

	Make/FREE/T input3 = {"{}", "{}", "{}", "{}", "{}", "{}", "{}", "{}"}

	// invalid ts at borders are included (2)
	Make/FREE/T ref = {"{}", "{}", "{\"ts\" : \"2021-12-24T00:00:00Z\"}", \
	                   "{}", "{}", "{\"ts\" : \"2022-01-20T00:00:00Z\"}", \
	                   "{}", "{}"}

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input2, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, 7)

	// left boundary
	first = 0
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input2, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, 7)

	// right boundary
	Make/FREE/T ref = {"{}", "{}", "{\"ts\" : \"2021-12-24T00:00:00Z\"}", \
	                   "{}", "{}", "{\"ts\" : \"2022-01-20T00:00:00Z\"}", \
	                   "{}", "{}", "{\"ts\" : \"2022-01-25T00:00:00Z\"}", \
	                   "{}", "{}"}

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = Inf
	[result, lastIndex] = FilterByDate(input2, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input2, ROWS) - 1)

	// all invalid ts
	first = 0
	last  = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	[result, lastIndex] = FilterByDate(input3, first, last)
	CHECK_EQUAL_TEXTWAVES(result, input3)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input3, ROWS) - 1)

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input3, first, last)
	CHECK_EQUAL_TEXTWAVES(result, input3)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input3, ROWS) - 1)

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = Inf
	[result, lastIndex] = FilterByDate(input3, first, last)
	CHECK_EQUAL_TEXTWAVES(result, input3)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input3, ROWS) - 1)

	// right boundary with invalid ts
	Make/FREE/T input4 = {"{\"ts\" : \"2021-12-24T00:00:00Z\"}",       \
	                      "{}", "{\"ts\" : \"2022-01-20T00:00:00Z\"}", \
	                      "{}", "{\"ts\" : \"2022-01-25T00:00:00Z\"}", \
	                      "{}"}

	first = 0
	last  = ParseIsO8601TimeStamp("2022-01-25T00:00:00Z")
	[result, lastIndex] = FilterByDate(input4, first, last)
	CHECK_EQUAL_TEXTWAVES(result, input4)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input4, ROWS) - 1)
End

Function GMC_SomeVariants()

	// 1 mA -> 1e-3A
	CHECK_EQUAL_VAR(MILLI_TO_ONE, 1e-3)

	// 1 MA -> 1e9 mA
	CHECK_EQUAL_VAR(MEGA_TO_MILLI, 1e9)

	CHECK_EQUAL_VAR(PETA_TO_FEMTO, 1e30)

	CHECK_EQUAL_VAR(MICRO_TO_TERA, 1e-18)
End

Function GetMarqueeHelperWorks()
	string win, refWin
	variable first, last

	Make/N=1000 data = 0.1 * p
	SetScale/P x, 0, 0.5, data
	Display/K=1 data
	refWin = S_name

	DoUpdate/W=$refWin
	SetMarquee/HAX=bottom/VAX=left/W=$refWin 10, 2, 30, 4

	// non-existing axis
	try
		[first, last] = GetMarqueeHelper("I_DONT_EXIST", horiz = 1)
		FAIL()
	catch
		CHECK_EQUAL_VAR(first, NaN)
		CHECK_EQUAL_VAR(last, NaN)
	endtry

	// non-existing axis without assert
	[first, last] = GetMarqueeHelper("I_DONT_EXIST", horiz = 1, doAssert = 0)
	CHECK_EQUAL_VAR(first, NaN)
	CHECK_EQUAL_VAR(last, NaN)

	// missing horiz/vert
	try
		[first, last] = GetMarqueeHelper("left")
		FAIL()
	catch
		CHECK_EQUAL_VAR(first, NaN)
		CHECK_EQUAL_VAR(last, NaN)
	endtry

	// both horiz/vert
	try
		[first, last] = GetMarqueeHelper("left", horiz = 1, vert = 1)
		FAIL()
	catch
		CHECK_EQUAL_VAR(first, NaN)
		CHECK_EQUAL_VAR(last, NaN)
	endtry

	// querying without kill (default)
	[first, last] = GetMarqueeHelper("bottom", horiz = 1)
	CHECK_EQUAL_VAR(round(first), 10)
	CHECK_EQUAL_VAR(round(last), 30)

	// querying without kill (explicit)
	[first, last] = GetMarqueeHelper("bottom", horiz = 1)
	CHECK_EQUAL_VAR(round(first), 10)
	CHECK_EQUAL_VAR(round(last), 30)

	// query with kill and win
	[first, last] = GetMarqueeHelper("left", vert = 1, kill = 1, win = win)
	CHECK_EQUAL_VAR(round(first), 2)
	CHECK_EQUAL_VAR(round(last), 4)
	CHECK_EQUAL_STR(win, refWin)

	// marquee is gone
	[first, last] = GetMarqueeHelper("left", horiz = 1, doAssert = 0)
	CHECK_EQUAL_VAR(first, NaN)
	CHECK_EQUAL_VAR(last, NaN)

	KillWindow $refWin
	KillWaves/Z data
End

static Function/S ConvertMacroToPlainCommands(string recMacro)

	// remove first two and last line
	variable numLines

	numLines = ItemsInList(recMacro, "\r")
	CHECK_GT_VAR(numLines, 0)

	Make/FREE/T/N=(numLines) contents = StringFromList(p, recMacro, "\r")

	contents[0, 1]         = ""
	contents[numLines - 1] = ""

	return ReplaceString("\r", TextWaveToList(contents, "\r"), ";")
End

static Function/WAVE GetDifferentGraphs()

	string win, recMacro

	Make/FREE/T/N=5/O wv

	NewDataFolder/O/S root:temp_test
	Make/O data
	data = p

	Display data
	win = S_name
	ModifyGraph/W=$win log(left)=0, log(bottom)=1
	SetAxis/W=$win left, 10, 20
	recMacro = WinRecreation(win, 0)
	CHECK_PROPER_STR(recMacro)
	KillWindow $win
	wv[0] = recMacro

	Display data
	win = S_name
	ModifyGraph/W=$win log(left)=2, log(bottom)=1
	SetAxis/W=$win bottom, 70, 90
	recMacro = WinRecreation(win, 0)
	CHECK_PROPER_STR(recMacro)
	KillWindow $win
	wv[1] = recMacro

	Display data
	win      = S_name
	recMacro = WinRecreation(win, 0)
	CHECK_PROPER_STR(recMacro)
	KillWindow $win
	wv[2] = recMacro

	Display data
	win = S_name
	SetAxis/A/W=$win bottom
	// only supports the default autoscale mode
	//	SetAxis/A=2/W=$win left
	recMacro = WinRecreation(win, 0)
	CHECK_PROPER_STR(recMacro)
	KillWindow $win
	wv[3] = recMacro

	Display data
	win      = S_name
	recMacro = WinRecreation(win, 0)
	CHECK_PROPER_STR(recMacro)
	KillWindow $win
	wv[4] = recMacro

	KillWaves data

	return wv
End

/// UTF_TD_GENERATOR GetDifferentGraphs
Function StoreRestoreAxisProps([string str])

	string win, actual, commands

	DFREF saveDFR = GetDataFolderDFR()

	NewDataFolder/O/S root:temp_test
	KillWaves/A
	KillStrings/A
	KillVariables/A
	Make data = p

	// execute recreation macro
	commands = ConvertMacroToPlainCommands(str)
	Execute commands
	DoUpdate
	win = GetCurrentWindow()

	WAVE props = GetAxesProperties(win)
	RemoveTracesFromGraph(win)

	WAVE/SDFR=root/Z data
	CHECK_WAVE(data, NORMAL_WAVE)
	AppendToGraph/W=$win data

	SetAxesProperties(win, props)
	actual = Winrecreation(win, 0)
	CHECK_EQUAL_STR(str, actual)

	KillWindow $win

	SetDataFolder saveDFR
End

static Function NoNullReturnFromGetValDisplayAsString()

	NewPanel/N=testpanelVal
	ValDisplay vdisp, win=testpanelVal

	GetValDisplayAsString("testpanelVal", "vdisp")
	PASS()
End

static Function NoNullReturnFromGetPopupMenuString()

	NewPanel/N=testpanelPM
	PopupMenu pmenu, win=testpanelPM

	GetPopupMenuString("testpanelPM", "pmenu")
	PASS()
End

static Function NoNullReturnFromGetSetVariableString()

	NewPanel/N=testpanelSV
	SetVariable svari, win=testpanelSV

	GetSetVariableString("testpanelSV", "svari")
	PASS()
End

static Function CheckLogFiles()

	string file, line
	variable foundFiles, jsonID

	// ensure that the ZeroMQ logfile exists as well
	// and also have the right layout
	PrepareForPublishTest()

	WAVE/T filesAndOther = GetLogFileNames()
	Duplicate/RMD=[][0]/FREE/T filesAndOther, files

	for(file : files)
		if(!FileExists(file))
			continue
		endif

		WAVE/T contents = LoadTextFileToWave(file, "\n")
		CHECK_WAVE(contents, TEXT_WAVE)
		CHECK_GT_VAR(DimSize(contents, ROWS), 0)

		for(line : contents)
			if(cmpstr(line, "{}"))
				break
			endif
		endfor

		if(!cmpstr(line, "{}"))
			// only {} inside the file, no need to check for timestamp
			continue
		endif

		jsonID = JSON_Parse(line)
		CHECK(JSON_IsValid(jsonID))

		INFO("File: \"%s\", Line: \"%s\"", s0 = file, s1 = line)

		CHECK(MIES_LOG#LOG_HasRequiredKeys(jsonID))
		WAVE/T keys = JSON_GetKeys(jsonID, "")
		FindValue/TEXT="ts" keys

		INFO("File: \"%s\", Line: \"%s\"", s0 = file, s1 = line)

		CHECK_GE_VAR(V_Value, 0)

		foundFiles += 1
	endfor

	CHECK_GT_VAR(foundFiles, 0)
End

static Function TestCaseInsensitivityWB_SplitStimsetName()

	string   setPrefix
	variable stimulusType
	variable setNumber

	WB_SplitStimsetName("formula_DA_0", setPrefix, stimulusType, setNumber)
	CHECK_EQUAL_STR(setPrefix, "formula")
	CHECK_EQUAL_VAR(stimulusType, CHANNEL_TYPE_DAC)
	CHECK_EQUAL_VAR(setNumber, 0)

	WB_SplitStimsetName("formula_da_0", setPrefix, stimulusType, setNumber)
	CHECK_EQUAL_STR(setPrefix, "formula")
	CHECK_EQUAL_VAR(stimulusType, CHANNEL_TYPE_DAC)
	CHECK_EQUAL_VAR(setNumber, 0)
End
