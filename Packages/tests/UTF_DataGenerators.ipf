#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=DataGenerators

Function/WAVE MajorNWBVersions()

	Make/FREE wv = {1, 2}

	SetDimensionLabels(wv, "v1;v2", ROWS)

	return wv
End

Function/WAVE IndexingPossibilities()
	Make/FREE wv = {0, 1}

	SetDimensionLabels(wv, "UnlockedIndexing;LockedIndexing", ROWS)

	return wv
End

Function/WAVE InsertedTPPossibilities()
	Make/FREE wv = {0, 1}

	SetDimensionLabels(wv, "NoInsertedTP;WithInsertedTP", ROWS)

	return wv
End

Function/WAVE SingleMultiDeviceDAQ()

	WAVE multiDevices = DeviceNameGeneratorMD1()
	WAVE singleDevices = DeviceNameGeneratorMD0()

	Make/FREE wv = {1}
	SetDimLabel ROWS, 0, MultiDevice, wv

	if(DimSize(singleDevices, ROWS) > 0)
		InsertPoints/M=(ROWS)/V=0 0, 1, wv
		SetDimLabel ROWS, 0, SingleDevice, wv
	endif

	return wv
End

Function/WAVE DeviceNameGenerator()
	return DeviceNameGeneratorMD1()
End

Function/WAVE DeviceNameGeneratorMD1()

	string devList = ""
	string lblList = ""
	variable i

#ifdef TESTS_WITH_NI_HARDWARE
	devList = AddListItem("Dev1", devList, ":")
	lblList = AddListItem("NI", lblList)
#endif

#ifdef TESTS_WITH_ITC18USB_HARDWARE
	devList = AddListItem("ITC18USB_Dev_0", devList, ":")
	lblList = AddListItem("ITC", lblList)
#endif

#ifdef TESTS_WITH_ITC1600_HARDWARE
	devList = AddListItem("ITC1600_Dev_1", devList, ":")
	lblList = AddListItem("ITC1600", lblList)
#endif

	WAVE data = ListToTextWave(devList, ":")
	for(i = 0; i < DimSize(data, ROWS); i += 1)
		SetDimLabel ROWS, i, $StringFromList(i, lblList), data
	endfor

	return data
End

Function/WAVE DeviceNameGeneratorMD0()

#ifdef TESTS_WITH_NI_HARDWARE
	// NI Hardware has no single device support
	Make/FREE/T/N=0 data
	return data
#endif

#ifdef TESTS_WITH_ITC18USB_HARDWARE
	return DeviceNameGeneratorMD1()
#endif

#ifdef TESTS_WITH_ITC1600_HARDWARE
	return DeviceNameGeneratorMD1()
#endif

End

Function/WAVE NWBVersionStrings()
	variable i, numEntries
	string name

	Make/T/FREE data = {"2.0b", "2.0.1", "2.1.0", "2.2.0"}
	return data
End

Function/WAVE NeuroDataRefTree()
	variable i, numEntries
	string name

	Make/T/FREE data = {"VoltageClampSeries:TimeSeries;PatchClampSeries;VoltageClampSeries;", \
						"CurrentClampSeries:TimeSeries;PatchClampSeries;CurrentClampSeries;", \
						"IZeroClampSeries:TimeSeries;PatchClampSeries;CurrentClampSeries;IZeroClampSeries;" \
						}
	return data
End

Function/WAVE SpikeCountsStateValues()
	variable numEntries = 6
	variable idx

	Make/FREE/WAVE/N=(numEntries) wv

	wv[idx++] = WaveRef({2, 2, 2, SC_SPIKE_COUNT_NUM_GOOD})
	wv[idx++] = WaveRef({1, 1, 1, SC_SPIKE_COUNT_NUM_GOOD})
	wv[idx++] = WaveRef({1, 2, 1, SC_SPIKE_COUNT_NUM_TOO_MANY})
	wv[idx++] = WaveRef({1, 2, 2, SC_SPIKE_COUNT_NUM_TOO_FEW})
	wv[idx++] = WaveRef({1, 3, 2, SC_SPIKE_COUNT_NUM_MIXED})
	wv[idx++] = WaveRef({NaN, NaN, 2, SC_SPIKE_COUNT_NUM_MIXED})

	Make/FREE/N=(numEntries) indexHelper = SetDimensionLabels(wv[p], "minimum;maximum;idealNumber;expectedState", ROWS)

	return wv
End

Function/WAVE GenerateBaselineValues()

	Make/FREE wv = {25, 35, 45}

	SetDimensionLabels(wv, "BL_25;BL_35;BL_45", ROWS)

	return wv
End

Function/WAVE GetITCDevices()

#ifdef TESTS_WITH_NI_HARDWARE
	Make/FREE/T/N=0 wv
	return wv
#endif

	return DeviceNameGeneratorMD1()
End

Function/WAVE GetChannelNumbersForDATTL()

	string list

	Make/FREE/N=(NUM_DA_TTL_CHANNELS + 3) channelNumbers = p
	channelNumbers[NUM_DA_TTL_CHANNELS] = CHANNEL_INDEX_ALL
	channelNumbers[NUM_DA_TTL_CHANNELS + 1] = CHANNEL_INDEX_ALL_V_CLAMP
	channelNumbers[NUM_DA_TTL_CHANNELS + 2] = CHANNEL_INDEX_ALL_I_CLAMP

	list = BuildList("%d", 0, 1, NUM_DA_TTL_CHANNELS) + "All;VC_All;IC_All"
	SetDimensionLabels(channelNumbers, list, ROWS)

	return channelNumbers
End

Function/WAVE GetChannelTypes()

	Make/FREE channelTypes = {CHANNEL_TYPE_DAC, CHANNEL_TYPE_TTL}

	SetDimensionLabels(channelTypes, "DAC;TTL", ROWS)

	return channelTypes
End

Function/WAVE NonExistingDevices()

	Make/FREE/T wv = {"Dev0815", "ITC16_DEV_15"}

	SetDimensionLabels(wv, TextWaveToList(wv, ";"), ROWS)

	return wv
End

Function/WAVE TestOperationAPFrequency2Gen()

	variable m

	Make/FREE/WAVE/N=3 wv

	Make/FREE/WAVE/N=4 results
	Make/FREE/D sweep0Result = {0.003 / 0.002, 0.003 / 0.002}
	Make/FREE/D sweep1Result = {1, 1, 1}
	results[0, 1] = sweep0Result
	results[2, 3] = sweep1Result
	note/K results, "apfrequency(data(cursors(A,B),select(channels(AD),[0,1],all)), 3, 15, time, normoversweepsmin)"
	wv[0] = results
	SetDimLabel ROWS, 0, normoversweepsmin, wv

	Make/FREE/WAVE/N=4 results
	Make/FREE/D sweep0Result = {1, 1}
	Make/FREE/D sweep1Result = {0.002 / 0.003, 0.002 / 0.003, 0.002 / 0.003}
	results[0, 1] = sweep0Result
	results[2, 3] = sweep1Result
	note/K results, "apfrequency(data(cursors(A,B),select(channels(AD),[0,1],all)), 3, 15, time, normoversweepsmax)"
	wv[1] = results
	SetDimLabel ROWS, 1, normoversweepsmax, wv

	Make/FREE/WAVE/N=4 results
	m = (2 * 0.003 + 3 * 0.002) / 5
	Make/FREE/D sweep0Result = {0.003 / m, 0.003 / m}
	Make/FREE/D sweep1Result = {0.002 / m, 0.002 / m, 0.002 / m}
	results[0, 1] = sweep0Result
	results[2, 3] = sweep1Result
	note/K results, "apfrequency(data(cursors(A,B),select(channels(AD),[0,1],all)), 3, 15, time, normoversweepsavg)"
	wv[2] = results
	SetDimLabel ROWS, 2, normoversweepsavg, wv

	return wv
End

static Function/WAVE SF_TestVariablesGen()

// note that data is called for d and e to test if variables get cleaned up, if they would, the assignment for e would fail
// as c and s were removed by the first data call.
	Make/FREE/T t1FormulaAndRest = {"c=cursors(A,B)\rs=select(channels(AD),[0,1],all)\rd=data($c,$s)\re=data($c,$s)\r\r$d", "$d"}
	Make/FREE/T t1DimLbl = {"c", "s", "d", "e"}

// case-insensitivity
	Make/FREE/T t2FormulaAndRest = {"c=cursors(A,B)\rs=select(channels(AD),[0,1],all)\rd=data($C,$S)\r\r$D", "$D"}
	Make/FREE/T t2DimLbl = {"c", "s", "d"}

// result test
	Make/FREE/T t3FormulaAndRest = {"d=1...3\r$d", "$d"}
	Make/FREE/T t3DimLbl = {"d"}
	Make/FREE/D t3Result = {1, 2}

// result test
	Make/FREE/T t4FormulaAndRest = {"b=1\ra$b=1", "a$b=1"}
	Make/FREE/T t4DimLbl = {"b"}
	Make/FREE/T t4Result = {"a$b=1"}

	Make/FREE/WAVE t1 = {t1FormulaAndRest, t1DimLbl, $""}
	Make/FREE/WAVE t2 = {t2FormulaAndRest, t2DimLbl, $""}
	Make/FREE/WAVE t3 = {t3FormulaAndRest, t3DimLbl, t3Result}
	Make/FREE/WAVE t4 = {t4FormulaAndRest, t4DimLbl, t4Result}

	Make/FREE/WAVE wv = {t1, t2, t3, t4}
	return wv
End

Function/WAVE GetMiesMacrosWithPanelType()
	WAVE/T allMiesMacros = GetMIESMacros()

	Make/FREE/T panelsWithoutType = {"IDM_Headstage_Panel", "IDM_Popup_Panel", "DebugPanel", "ExportSettingsPanel", "PSXPanel"}

	WAVE/T matches = GetSetDifference(allMiesMacros, panelsWithoutType)

	SetDimensionLabels(matches, TextWaveToList(matches, ";"), ROWS)

	return matches
End

static Function/WAVE EpochTestTTL_TP_Gen()

	Make/FREE w = {0, 1}

	return w
End

static Function/WAVE EpochTestTTL_TD_Gen()

	Make/FREE w = {0, 25}

	return w
End

static Function/WAVE EpochTestTTL_OD_Gen()

	Make/FREE w = {0, 15}

	return w
End
