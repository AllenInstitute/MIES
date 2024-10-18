#pragma TextEncoding="UTF-8"
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

	WAVE multiDevices  = DeviceNameGeneratorMD1()
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
	devList = AddListItem("ITC1600_Dev_0", devList, ":")
	lblList = AddListItem("ITC1600", lblList)
#endif

#ifdef TESTS_WITH_SUTTER_HARDWARE
	devList = AddListItem("IPA_E_100170", devList, ":")
	lblList = AddListItem("SUTTER", lblList)
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

#ifdef TESTS_WITH_SUTTER_HARDWARE
	// SUTTER Hardware has no single device support
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

	Make/T/FREE data = {"VoltageClampSeries:TimeSeries;PatchClampSeries;VoltageClampSeries;",               \
	                    "CurrentClampSeries:TimeSeries;PatchClampSeries;CurrentClampSeries;",               \
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

#ifdef TESTS_WITH_SUTTER_HARDWARE
	Make/FREE/T/N=0 wv
	return wv
#endif

	return DeviceNameGeneratorMD1()
End

Function/WAVE GetChannelNumbersForDATTL()

	string list

	Make/FREE/N=(NUM_DA_TTL_CHANNELS + 3) channelNumbers = p
	channelNumbers[NUM_DA_TTL_CHANNELS]     = CHANNEL_INDEX_ALL
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

static Function/WAVE TestOperationAPFrequency2Gen()

	variable m

	Make/FREE/WAVE/N=3 wv

	Make/FREE/WAVE/N=4 results
	Make/FREE/D sweep0Result = {0.003 / 0.002, 0.003 / 0.002}
	Make/FREE/D sweep1Result = {1, 1, 1}
	results[0, 1] = sweep0Result
	results[2, 3] = sweep1Result
	note/K results, "apfrequency(data(select(selrange(),selchannels(AD),selsweeps(0,1),selvis(all))), 3, 15, time, normoversweepsmin)"
	wv[0] = results
	SetDimLabel ROWS, 0, normoversweepsmin, wv

	Make/FREE/WAVE/N=4 results
	Make/FREE/D sweep0Result = {1, 1}
	Make/FREE/D sweep1Result = {0.002 / 0.003, 0.002 / 0.003, 0.002 / 0.003}
	results[0, 1] = sweep0Result
	results[2, 3] = sweep1Result
	note/K results, "apfrequency(data(select(selrange(),selchannels(AD),selsweeps(0,1),selvis(all))), 3, 15, time, normoversweepsmax)"
	wv[1] = results
	SetDimLabel ROWS, 1, normoversweepsmax, wv

	Make/FREE/WAVE/N=4 results
	m = (2 * 0.003 + 3 * 0.002) / 5
	Make/FREE/D sweep0Result = {0.003 / m, 0.003 / m}
	Make/FREE/D sweep1Result = {0.002 / m, 0.002 / m, 0.002 / m}
	results[0, 1] = sweep0Result
	results[2, 3] = sweep1Result
	note/K results, "apfrequency(data(select(selrange(),selchannels(AD),selsweeps(0,1),selvis(all))), 3, 15, time, normoversweepsavg)"
	wv[2] = results
	SetDimLabel ROWS, 2, normoversweepsavg, wv

	return wv
End

static Function/WAVE SF_TestVariablesGen()

	// note that data is called for d and e to test if variables get cleaned up, if they would, the assignment for e would fail
	// as c and s were removed by the first data call.
	Make/FREE/T t1FormulaAndRest = {"c=cursors(A,B)\rs=select(selrange($c),selchannels(AD),selsweeps(0,1),selvis(all))\rd=data($s)\re=data($s)\r\r$d", "$d"}
	Make/FREE/T t1DimLbl = {"c", "s", "d", "e"}

	// case-insensitivity
	Make/FREE/T t2FormulaAndRest = {"c=cursors(A,B)\rs=select(selrange($c),selchannels(AD),selsweeps(0,1),selvis(all))\rd=data($S)\r\r$D", "$D"}
	Make/FREE/T t2DimLbl = {"c", "s", "d"}

	// result test
	Make/FREE/T t3FormulaAndRest = {"d=1...3\r$d", "$d"}
	Make/FREE/T t3DimLbl = {"d"}
	Make/FREE/D t3Result = {1, 2}

	// result test
	Make/FREE/T t4FormulaAndRest = {"b=1\ra$b=1", "a$b=1"}
	Make/FREE/T t4DimLbl = {"b"}
	Make/FREE/T t4Result = {"a$b=1"}

	// does not bug out with trailing whitespace
	Make/FREE/T t5FormulaAndRest = {"a=[1]\r 	\rb=$a\r\r$b", "$b"}
	t5FormulaAndRest[] = MIES_SF#SF_PreprocessInput(t5FormulaAndRest[p])
	Make/FREE/T t5DimLbl = {"a", "b"}

	Make/FREE/WAVE t1 = {t1FormulaAndRest, t1DimLbl, $""}
	Make/FREE/WAVE t2 = {t2FormulaAndRest, t2DimLbl, $""}
	Make/FREE/WAVE t3 = {t3FormulaAndRest, t3DimLbl, t3Result}
	Make/FREE/WAVE t4 = {t4FormulaAndRest, t4DimLbl, t4Result}
	Make/FREE/WAVE t5 = {t5FormulaAndRest, t5DimLbl, $""}

	Make/FREE/WAVE wv = {t1, t2, t3, t4, t5}
	return wv
End

Function/WAVE GetMiesMacrosWithPanelType()
	WAVE/T allMiesMacros = GetMIESMacros()

	Make/FREE/T panelsWithoutType = {"IDM_Headstage_Panel", "IDM_Popup_Panel", "DebugPanel", "ExportSettingsPanel", "PSXPanel"}

	WAVE/T matches = GetSetDifference(allMiesMacros, panelsWithoutType)

	SetDimensionLabels(matches, TextWaveToList(matches, ";"), ROWS)

	return matches
End

static Function/WAVE EpochTestSamplingFrequency_Gen()

	string frequencies = DAP_GetSamplingFrequencies()

	WAVE wTemp = ListToNumericWave(frequencies, ";", ignoreErr = 1)
	WAVE w     = ZapNaNs(wTemp)

	SetDimensionLabelsFromWaveContents(w, prefix = "f_", suffix = "_kHz")

	return w
End

static Function/WAVE EpochTestSamplingFrequencyTTL_Gen()

	string frequencies = DAP_GetSamplingFrequencies()

	WAVE wTemp = ListToNumericWave(frequencies, ";", ignoreErr = 1)

#ifdef TESTS_WITH_ITC18USB_HARDWARE
	wTemp[] = wTemp[p] == 100 ? NaN : wTemp[p]
#else
#ifdef TESTS_WITH_ITC1600_HARDWARE
	wTemp[] = wTemp[p] == 100 ? NaN : wTemp[p]
#endif
#endif

	WAVE w = ZapNaNs(wTemp)

	SetDimensionLabelsFromWaveContents(w, prefix = "f_", suffix = "_kHz")

	return w
End

static Function/WAVE EpochTestSamplingMultiplier_Gen()

	string multipliers = DAP_GetSamplingMultiplier()

	WAVE wTemp = ListToNumericWave(multipliers, ";")
	wTemp[] = wTemp[p] == 1 ? NaN : wTemp[p]
	WAVE w = ZapNaNs(wTemp)

	SetDimensionLabelsFromWaveContents(w, suffix = "x")

	return w
End

static Function/WAVE EpochTest_Stimsets_Gen()

	Make/FREE/T wt = {"EpochTest0_DA_0", "EpochTest1_DA_0", "EpochTest2_DA_0", "EpochTest3_DA_0", "EpochTest4_DA_0", "EpochTest5_DA_0", "EpochTest6_DA_0", "EpochTest17_DA_0"}
	SetDimensionLabelsFromWaveContents(wt)

	return wt
End

static Function/WAVE EpochTest_StimsetsTTL_Gen()

	Make/FREE/T wt = {"StimulusSetA_TTL_0", "StimulusSetB_TTL_0", "StimulusSetC_TTL_0", "StimulusSetD_TTL_0"}
	SetDimensionLabelsFromWaveContents(wt)

	return wt
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

Function/WAVE InfiniteValues()

	Make/FREE wv = {NaN, Inf, -Inf}

	SetDimLabel ROWS, 0, $"NaN", wv
	SetDimLabel ROWS, 1, $"Inf", wv
	SetDimLabel ROWS, 2, $"-Inf", wv

	return wv
End

static Function/WAVE RoundTripStimsetFileType()

	Make/FREE/T wv = {"nwb", "pxp"}
	SetDimensionLabels(wv, TextWaveToList(wv, ";"), ROWS)

	return wv
End

Function/WAVE IndexAfterDecimation_Positions()

	Make/FREE/D wv = {e / 11.1, Pi / 11.1, 0.73, 0.51}

	return wv
End

Function/WAVE IndexAfterDecimation_Sizes()

	// These are variations of the target size, the source size is fixed 1000
	Make/FREE/D wv = {345, 678, 1234, 5678}

	return wv
End

Function/WAVE CountObjectTypeFlags()

	Make/FREE/D input0 = {COUNTOBJECTS_WAVES}
	Make/FREE/T result0 = {"wv1;wv2;"}
	Make/FREE/T resultRec0 = {"wv1;wv2;wv3;wv4;"}

	Make/FREE/WAVE wrapper0 = {input0, result0, resultRec0}

	Make/FREE/D input1 = {COUNTOBJECTS_DATAFOLDER}
	Make/FREE/T result1 = {"test2;"}
	Make/FREE/T resultRec1 = {"test2;test3;"}

	Make/FREE/WAVE wrapper1 = {input1, result1, resultRec1}

	Make/FREE/D input2 = {COUNTOBJECTS_VAR}
	Make/FREE/T result2 = {"var1;var2;"}
	Make/FREE/T resultRec2 = {"var1;var2;var3;var4;"}

	Make/FREE/WAVE wrapper2 = {input2, result2, resultRec2}

	Make/FREE/D input3 = {COUNTOBJECTS_STR}
	Make/FREE/T result3 = {"str1;"}
	Make/FREE/T resultRec3 = {"str1;str2;"}

	Make/FREE/WAVE wrapper3 = {input3, result3, resultRec3}

	Make/FREE/WAVE wv = {wrapper0, wrapper1, wrapper2, wrapper3}

	SetDimensionLabels(wv, "Waves;Datafolder;Variables;String;", ROWS)

	return wv
End

Function/WAVE TrailSepOptions()

	Make/FREE wv = {0, 1}

	SetDimensionLabels(wv, "Without trailing sep;Trailing separator", ROWS)

	return wv
End

static Function/WAVE InvalidStoreFormulas()

	Make/T/N=3/FREE wv

	// invalid name
	wv[0] = "store(\"\", [0])"

	// array as name
	wv[1] = "store([\"a\", \"b\"], [0])"

	// numeric value as name
	wv[2] = "store([1], [0])"

	return wv
End

static Function/WAVE GetStoreWaves()

	Make/WAVE/N=3/FREE wv

	Make/FREE/D wv0 = {1234.5678}
	wv[0] = wv0

	Make/FREE wv1 = {1, 2}
	wv[1] = wv1

	Make/FREE/T wv2 = {"a", "b"}
	wv[2] = wv2

	return wv
End

static Function/WAVE TestOperationTPBase_TPSS_TPInst_FormulaGetter()

	Make/FREE/T data = {"tpbase;" + SF_DATATYPE_TPBASE, "tpss;" + SF_DATATYPE_TPSS, "tpinst;" + SF_DATATYPE_TPINST}

	return data
End

static Function/WAVE FuncCommandGetter()

	variable i, numEntries
	string name

	// Operation: Result 1D: Result 2D
	Make/T/FREE data = {                                                                                                                                                                                                                \
	                    "min:0:0,1",                                                                                                                                                                                                    \
	                    "max:4:4,5",                                                                                                                                                                                                    \
	                    "avg:2:2,3",                                                                                                                                                                                                    \
	                    "mean:2:2,3",                                                                                                                                                                                                   \
	                    "rms:2.449489742783178:2.449489742783178,3.3166247903554",                                                                                                                                                      \
	                    "variance:2.5:2.5,2.5",                                                                                                                                                                                         \
	                    "stdev:1.58113883008419:1.58113883008419,1.58113883008419",                                                                                                                                                     \
	                    "derivative:1,1,1,1,1:{1,1,1,1,1},{1,1,1,1,1}",                                                                                                                                                                 \
	                    "integrate:0,0.5,2,4.5,8:{0,0.5,2,4.5,8},{0,1.5,4,7.5,12}",                                                                                                                                                     \
	                    "log10:-inf,0,0.301029995663981,0.477121254719662,0.602059991327962:{-inf,0,0.301029995663981,0.477121254719662,0.602059991327962},{0,0.301029995663981,0.477121254719662,0.602059991327962,0.698970004336019}" \
	                   }

	numEntries = DimSize(data, ROWS)
	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(0, data[i], ":")
		SetDimLabel ROWS, i, $name, data
	endfor

	return data
End

static Function/WAVE InvalidInputs()

	Make/FREE/T wt = {",1", " ,1", "1,,", "1, ,", "(1), ,", "1,", "(1),",           \
	                  "1+", "1-", "1*", "1/", "1…", "(1-)", "(1+)", "(1*)", "(1/)", \
	                  "*1", "*[1]", "*(1)", "(*1)", "[1,*1]",                       \
	                  "/1", "/[1]", "/(1)", "(/1)", "[1,/1]",                       \
	                  "1**1", "1//1",                                               \
	                  "*max(1)", "max(1)**max(1)", "/max(1)", "max(1)//max(1)"}

	return wt
End

static Function/WAVE SweepFormulaFunctionsWithSweepsArgument()

	Make/FREE/T wv = {"data(select(selrange(), selchannels(AD), selsweeps()))",            \
	                  "epochs(\"I DONT EXIST\", select(selchannels(DA), selsweeps()))",    \
	                  "labnotebook(\"I DONT EXIST\", select(selchannels(DA), selsweeps()))"}

	SetDimensionLabels(wv, "data;epochs;labnotebook", ROWS)

	return wv
End

static Function/WAVE TestHelpNotebookGetter_IGNORE()

	WAVE/T wt = SF_GetNamedOperations()

	SetDimensionLabels(wt, TextWaveToList(wt, ";"), ROWS)

	return wt
End

// Returns a wave reference wave with each entry holding a wave reference wave
static Function/WAVE FLW_SampleDataMulti()

	WAVE/WAVE sampleData = FLW_SampleData()

	// Attach the results
	Make/FREE/D result1 = {4.25}
	SetDimLabel ROWS, 0, $"1", result1

	Make/FREE/D result2 = {-2.525}
	SetDimLabel ROWS, 0, $"1", result2

	Make/FREE/D result3 = {3.8, 3.6, NaN}
	SetDimLabel ROWS, 0, $"1", result3
	SetDimLabel ROWS, 1, $"1", result3
	SetDimLabel ROWS, 2, $"0", result3

	Make/FREE/D result4 = {NaN, NaN, NaN}
	SetDimLabel ROWS, 0, $"0", result4
	SetDimLabel ROWS, 1, $"0", result4
	SetDimLabel ROWS, 2, $"0", result4

	Make/FREE/D result5 = {3.95, 3.9, NaN}
	SetDimLabel ROWS, 0, $"1", result5
	SetDimLabel ROWS, 1, $"1", result5
	SetDimLabel ROWS, 2, $"0", result5

	Make/FREE/D/N=(3, 5) result6
	result6[0][0] = {3.95, 3.9, NaN}
	result6[0][1] = {NaN, 3.1, NaN}
	result6[0][2] = {NaN, 2.9, NaN}
	result6[0][3] = {NaN, 2.1, NaN}
	result6[0][4] = {NaN, 1.9, NaN}
	SetDimLabel ROWS, 0, $"1", result6
	SetDimLabel ROWS, 1, $"5", result6
	SetDimLabel ROWS, 2, $"0", result6

	Make/FREE/WAVE pairs1 = {sampleData[0], result1}
	Make/FREE/WAVE pairs2 = {sampleData[1], result2}
	Make/FREE/WAVE pairs3 = {sampleData[2], result3}
	Make/FREE/WAVE pairs4 = {sampleData[3], result4}
	Make/FREE/WAVE pairs5 = {sampleData[4], result5}
	Make/FREE/WAVE pairs6 = {sampleData[5], result6}

	Make/FREE/WAVE sampleDataMulti = {pairs1, pairs2, pairs3, pairs4, pairs5, pairs6}

	return sampleDataMulti
End

static Function/WAVE FLW_SampleData()

	Make/FREE data1 = {10, 20, 30, 40}
	SetScale/P x, 4, 0.5, data1
	SetNumberInWaveNote(data1, "edge", FINDLEVEL_EDGE_INCREASING)
	SetNumberInWaveNote(data1, "level", 15)

	Make/FREE data2 = {10, 20, 30, 10}
	SetScale/P x, -4, 0.5, data2
	SetNumberInWaveNote(data2, "edge", FINDLEVEL_EDGE_DECREASING)
	SetNumberInWaveNote(data2, "level", 11)

	Make/FREE data3 = {{10, 20}, {10, 15}, {10, 5}}
	SetScale/P x, 4, -0.5, data3
	SetNumberInWaveNote(data3, "edge", FINDLEVEL_EDGE_INCREASING)
	SetNumberInWaveNote(data3, "level", 14)

	Make/FREE data4 = {{10, 20}, {10, 15}, {10, 5}}
	SetScale/P x, 4, -0.5, data4
	SetNumberInWaveNote(data4, "edge", FINDLEVEL_EDGE_DECREASING)
	SetNumberInWaveNote(data4, "level", 11)

	Make/FREE data5 = {{10, 20}, {10, 15}, {10, 5}}
	SetScale/P x, 4, -0.5, data5
	SetNumberInWaveNote(data5, "edge", FINDLEVEL_EDGE_BOTH)
	SetNumberInWaveNote(data5, "level", 11)

	Make/FREE data6 = {{10, 20, 30, 40, 50, 60}, {10, 15, 10, 15, 10, 15}, {10, 5, 10, 5, 10, 5}}
	SetScale/P x, 4, -0.5, data6
	SetNumberInWaveNote(data6, "edge", FINDLEVEL_EDGE_BOTH)
	SetNumberInWaveNote(data6, "level", 11)

	Make/WAVE/FREE result = {data1, data2, data3, data4, data5, data6}

	return result
End

static Function/WAVE GetSupportedWaveTypes()

	Make/FREE/T input = {"NT_FP64", "NT_FP32", "NT_I32", "NT_I16", "NT_I8", "TEXT_WAVE", "WAVE_WAVE"}
	SetDimensionLabels(input, TextWaveToList(input, ";"), ROWS)

	return input
End

static Function/WAVE RoundNumberPairs()

	Make/FREE/WAVE/N=6 entries

	Make/FREE/D wv0 = {1.23456, 0, 1}
	entries[0] = wv0

	// rounds correctly
	Make/FREE/D wv1 = {1.23456, 4, 1.2346}
	entries[1] = wv1

	Make/FREE/D wv2 = {1.23456, 2, 1.23}
	entries[2] = wv2

	Make/FREE/D wv3 = {NaN, 0, NaN}
	entries[3] = wv3

	Make/FREE/D wv4 = {Inf, 0, Inf}
	entries[4] = wv4

	Make/FREE/D wv5 = {-Inf, 0, -Inf}
	entries[5] = wv5

	return entries
End

static Function/WAVE GetLimitValues()

	Make/WAVE/FREE/N=6 comb

	// value, low, high, replacement, result

	Make/FREE wv0 = {1, 0, 2, NaN, 1}
	comb[0] = wv0

	Make/FREE wv1 = {1, 1, 2, NaN, 1}
	comb[1] = wv1

	Make/FREE wv2 = {2, 1, 2, NaN, 2}
	comb[2] = wv2

	Make/FREE wv3 = {0, 1, 2, NaN, NaN}
	comb[3] = wv3

	Make/FREE wv4 = {3, 1, 2, NaN, NaN}
	comb[4] = wv4

	Make/FREE wv5 = {3, 1, 2, -1, -1}
	comb[5] = wv5

	return comb
End

static Function/WAVE NonFiniteValues()
	Make/D/FREE data = {NaN, Inf, -Inf}
	return data
End

static Function/WAVE InvalidUnits()
	Make/FREE/T result = {"", "ab", "MOhm", "xs", "sx"}

	return result
End

static Function/WAVE ValidUnits()
	// unitWithPrefix, prefix, numPrefix, unit
	Make/FREE/T wv0 = {"s", "", "NaN", "s"}
	Make/FREE/T wv1 = {"Gs", "G", "1e9", "s"}
	Make/FREE/T wv2 = {"m 	Ω", "m", "1e-3", "Ω"}

	Make/FREE/WAVE/N=1 result = {wv0, wv1, wv2}

	return result
End

static Function/WAVE ETValidInput()

	// input string, output string, passed length
	Make/FREE/T wv0 = {"a", "a", "1"}
	Make/FREE/T wv1 = {"abcd", "abcd", "10"}
	Make/FREE/T wv2 = {"abcd ef gh", "ab...", "5"}
	Make/FREE/T wv3 = {"a bcd ef gh", "a...", "5"}
	Make/FREE/T wv4 = {"a\rbcd\ref\rgh", "a...", "5"}
	Make/FREE/T wv5 = {"a\rbcd\ref\rgh", "a\rbcd...", "9"}
	Make/FREE/T wv6 = {" \t\r\nabcd", " ...", "4"}

	Make/WAVE/FREE wv = {wv0, wv1, wv2, wv3, wv4, wv5, wv6}

	return wv
End

static Function/WAVE ETInvalidInput()

	// input string, passed length
	Make/FREE/T wv0 = {" \t\r\n", "1"}
	Make/FREE/T wv1 = {" abcd", "1"}
	Make/FREE/T wv2 = {" abcd", "1.5"}

	Make/WAVE/FREE wv = {wv0, wv1, wv2}

	return wv
End

static Function/WAVE ISO8601_timestamps()

	Make/FREE/T wv = {                                                                  \
	                  GetIso8601TimeStamp(),                                            \
	                  GetIso8601TimeStamp(localTimeZone = 0),                           \
	                  GetIso8601TimeStamp(localTimeZone = 1),                           \
	                  GetIso8601TimeStamp(numFracSecondsDigits = 1),                    \
	                  GetIso8601TimeStamp(numFracSecondsDigits = 2),                    \
	                  GetIso8601TimeStamp(numFracSecondsDigits = 2, localTimeZone = 1), \
	                  "2007-08-31T16:47+00:00",                                         \
	                  "2007-12-24T18:21Z",                                              \
	                  "2008-02-01T09:00:22+05",                                         \
	                  "2009-01-01T12:00:00+01:00",                                      \
	                  "2009-06-30T18:30:00+02:00"                                       \
	                 }

	return wv
End

static Function/WAVE GenerateAllPossibleWaveTypes()

	variable numberOfNumericTypes

	Make/FREE types = {IGOR_TYPE_8BIT_INT,                                           \
	                   IGOR_TYPE_16BIT_INT,                                          \
	                   IGOR_TYPE_32BIT_INT,                                          \
	                   IGOR_TYPE_64BIT_INT,                                          \
	                   IGOR_TYPE_8BIT_INT | IGOR_TYPE_UNSIGNED,                      \
	                   IGOR_TYPE_16BIT_INT | IGOR_TYPE_UNSIGNED,                     \
	                   IGOR_TYPE_32BIT_INT | IGOR_TYPE_UNSIGNED,                     \
	                   IGOR_TYPE_64BIT_INT | IGOR_TYPE_UNSIGNED,                     \
	                   IGOR_TYPE_8BIT_INT | IGOR_TYPE_UNSIGNED | IGOR_TYPE_COMPLEX,  \
	                   IGOR_TYPE_16BIT_INT | IGOR_TYPE_UNSIGNED | IGOR_TYPE_COMPLEX, \
	                   IGOR_TYPE_32BIT_INT | IGOR_TYPE_UNSIGNED | IGOR_TYPE_COMPLEX, \
	                   IGOR_TYPE_64BIT_INT | IGOR_TYPE_UNSIGNED | IGOR_TYPE_COMPLEX, \
	                   IGOR_TYPE_32BIT_FLOAT,                                        \
	                   IGOR_TYPE_64BIT_FLOAT}

	numberOfNumericTypes = DimSize(types, ROWS)

	Make/FREE/WAVE/N=(numberOfNumericTypes + 3) waves
	waves[0, numberOfNumericTypes - 1] = NewFreeWave(types[p], 1)

	Make/T/FREE textWave
	waves[numberOfNumericTypes] = textWave

	Make/DF/FREE dfrefWave = NewFreeDataFolder()
	waves[numberOfNumericTypes + 1] = dfrefWave

	Make/WAVE/FREE wvRefWave = {NewFreeWave(IGOR_TYPE_16BIT_INT, 1), $""}
	waves[numberOfNumericTypes + 2] = wvRefWave

	return waves
End

static Function/WAVE SW_TrueValues()
	Make/D/FREE data = {1, Inf, -Inf, 1e-15, -1, NaN}
	return data
End

static Function/WAVE SW_FalseValues()
	Make/D/FREE data = {0}
	return data
End

static Function/WAVE InvalidSignDigits()

	Make/FREE digits = {-1, NaN, Inf, -Inf}

	return digits
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

static Function/WAVE GetBasicMathOperations()
	Make/FREE/T op = {"+", "-", "*", "/"}

	SetDimensionLabels(OP, "plus;minus;mult;div;", ROWS)

	return op
End

static Function/WAVE GetASYNCReadOutErrorFunctions()
	Make/FREE/T wt = {"FailReadOutAbort", "FailReadOut"}
	SetDimensionLabels(wt, TextWaveToList(wt, ";"), ROWS)

	return wt
End

static Function/WAVE GetASYNCThreadErrorFunctions()
	Make/FREE/T wt = {"RunGenericWorkerAbortOnValue,FailThreadReadOutAbortOnValue,", "RunGenericWorkerRTE,FailThreadReadOutRTE,"}
	SetDimensionLabels(wt, TextWaveToList(wt, ";"), ROWS)

	return wt
End

static Function/WAVE SF_TestOperationSelectFails()

	Make/FREE/T wt = {"select(1)",                                               \
	                  "select(selrange(),selrange())",                           \
	                  "select(selchannels(),selchannels())",                     \
	                  "select(selsweeps(),selsweeps())",                         \
	                  "select(selcm(all),selcm(all))",                           \
	                  "select(selvis(),selvis())",                               \
	                  "select(selstimset(),selstimset())",                       \
	                  "select(selivsccsetqc(failed),selivsccsetqc(failed))",     \
	                  "select(selivsccsweepqc(failed),selivsccsweepqc(failed))", \
	                  "select(selexp(" + GetExperimentName() + "not_exist))",    \
	                  "select(seldev(unknown_device))",                          \
	                  "select(seldev(device),seldev(device))",                   \
	                  "select(selexp(exp),selexp(exp))",                         \
	                  "select(selsciindex(0),selsciindex(0))",                   \
	                  "select(selracindex(0),selracindex(0))",                   \
	                  "select(selsetcyclecount(0),selsetcyclecount(0))",         \
	                  "select(selsetsweepcount(0),selsetsweepcount(0))",         \
	                  "select(selexpandrac(0),selexpandrac(0))",                 \
	                  "select(selexpandsci(0),selexpandsci(0))"}

	Duplicate/FREE/T wt, labels
	labels[] = CleanUpName(wt[p], 0)
	SetDimensionLabels(wt, TextWaveToList(labels, ";"), ROWS)

	return wt
End

static Function/WAVE SF_TestOperationSelSingleNumber()

	Make/FREE/T wt = {"selsetcyclecount", "selsetsweepcount", "selsciindex", "selracindex"}
	SetDimensionLabels(wt, TextWaveToList(wt, ";"), ROWS)

	return wt
End

static Function/WAVE SF_TestOperationSelSingleText()

	Make/FREE/T wt = {"seldev", "selexp"}
	SetDimensionLabels(wt, TextWaveToList(wt, ";"), ROWS)

	return wt
End

static Function/WAVE SF_TestOperationSelNoArg()

	Make/FREE/T wt = {"selexpandrac", "selexpandsci"}
	SetDimensionLabels(wt, TextWaveToList(wt, ";"), ROWS)

	return wt
End

static Function/WAVE PUB_TPFilters()

	Make/FREE/T wv = {ZMQ_FILTER_TPRESULT_NOW, ZMQ_FILTER_TPRESULT_1S, ZMQ_FILTER_TPRESULT_5S, ZMQ_FILTER_TPRESULT_10S}
	SetDimensionLabels(wv, "period_now;period_1s;period_5s;period_10s", ROWS)

	return wv
End
