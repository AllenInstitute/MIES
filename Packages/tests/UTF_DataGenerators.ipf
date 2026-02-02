#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = DataGenerators

static Function/WAVE MajorNWBVersions()

	Make/FREE wv = {1, 2}

	SetDimensionLabels(wv, "v1;v2", ROWS)

	return wv
End

static Function/WAVE IndexingPossibilities()

	Make/FREE wv = {0, 1}

	SetDimensionLabels(wv, "UnlockedIndexing;LockedIndexing", ROWS)

	return wv
End

static Function/WAVE InsertedTPPossibilities()

	Make/FREE wv = {0, 1}

	SetDimensionLabels(wv, "NoInsertedTP;WithInsertedTP", ROWS)

	return wv
End

static Function/WAVE SingleMultiDeviceDAQ()

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

static Function/WAVE DeviceNameGenerator()

	return DeviceNameGeneratorMD1()
End

static Function/WAVE DeviceNameGeneratorMD1()

	string devList = ""
	string lblList = ""
	variable i

#ifdef TESTS_WITH_NI_HARDWARE
	devList = AddListItem("Dev1", devList, ":")
	lblList = AddListItem("NI", lblList)
#endif // TESTS_WITH_NI_HARDWARE

#ifdef TESTS_WITH_ITC18USB_HARDWARE
	devList = AddListItem("ITC18USB_Dev_0", devList, ":")
	lblList = AddListItem("ITC", lblList)
#endif // TESTS_WITH_ITC18USB_HARDWARE

#ifdef TESTS_WITH_ITC1600_HARDWARE
	devList = AddListItem("ITC1600_Dev_0", devList, ":")
	lblList = AddListItem("ITC1600", lblList)
#endif // TESTS_WITH_ITC1600_HARDWARE

#ifdef TESTS_WITH_SUTTER_HARDWARE
	devList = AddListItem("IPA_E_100170", devList, ":")
	lblList = AddListItem("SUTTER", lblList)
#endif // TESTS_WITH_SUTTER_HARDWARE

	WAVE data = ListToTextWave(devList, ":")
	for(i = 0; i < DimSize(data, ROWS); i += 1)
		SetDimLabel ROWS, i, $StringFromList(i, lblList), data
	endfor

	return data
End

static Function/WAVE DeviceNameGeneratorMD0()

#ifdef TESTS_WITH_NI_HARDWARE
	// NI Hardware has no single device support
	Make/FREE/T/N=0 data
	return data
#endif // TESTS_WITH_NI_HARDWARE

#ifdef TESTS_WITH_SUTTER_HARDWARE
	// SUTTER Hardware has no single device support
	Make/FREE/T/N=0 data
	return data
#endif // TESTS_WITH_SUTTER_HARDWARE

#ifdef TESTS_WITH_ITC18USB_HARDWARE
	return DeviceNameGeneratorMD1()
#endif // TESTS_WITH_ITC18USB_HARDWARE

#ifdef TESTS_WITH_ITC1600_HARDWARE
	return DeviceNameGeneratorMD1()
#endif // TESTS_WITH_ITC1600_HARDWARE

End

static Function/WAVE NWBVersionStrings()

	variable i, numEntries
	string name

	Make/T/FREE data = {"2.0b", "2.0.1", "2.1.0", "2.2.0"}
	return data
End

static Function/WAVE NeuroDataRefTree()

	variable i, numEntries
	string name

	Make/T/FREE data = {"VoltageClampSeries:TimeSeries;PatchClampSeries;VoltageClampSeries;",               \
	                    "CurrentClampSeries:TimeSeries;PatchClampSeries;CurrentClampSeries;",               \
	                    "IZeroClampSeries:TimeSeries;PatchClampSeries;CurrentClampSeries;IZeroClampSeries;" \
	                   }
	return data
End

static Function/WAVE SpikeCountsStateValues()

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

static Function/WAVE GenerateBaselineValues()

	Make/FREE wv = {25, 35, 45}

	SetDimensionLabels(wv, "BL_25;BL_35;BL_45", ROWS)

	return wv
End

static Function/WAVE GetITCDevices()

#ifdef TESTS_WITH_NI_HARDWARE
	Make/FREE/T/N=0 wv
	return wv
#endif // TESTS_WITH_NI_HARDWARE

#ifdef TESTS_WITH_SUTTER_HARDWARE
	Make/FREE/T/N=0 wv
	return wv
#endif // TESTS_WITH_SUTTER_HARDWARE

	return DeviceNameGeneratorMD1()
End

static Function/WAVE GetChannelNumbersForDATTL()

	string list

	Make/FREE/N=(NUM_DA_TTL_CHANNELS + 3) channelNumbers = p
	channelNumbers[NUM_DA_TTL_CHANNELS]     = CHANNEL_INDEX_ALL
	channelNumbers[NUM_DA_TTL_CHANNELS + 1] = CHANNEL_INDEX_ALL_V_CLAMP
	channelNumbers[NUM_DA_TTL_CHANNELS + 2] = CHANNEL_INDEX_ALL_I_CLAMP

	list = BuildList("%d", 0, 1, NUM_DA_TTL_CHANNELS) + "All;VC_All;IC_All"
	SetDimensionLabels(channelNumbers, list, ROWS)

	return channelNumbers
End

static Function/WAVE GetClampModesWithoutIZero()

	Make/FREE clampModes = {V_CLAMP_MODE, I_CLAMP_MODE}
	SetDimensionLabels(clampModes, "VC;IC;", ROWS)

	return clampModes
End

static Function/WAVE GetClampModes()

	Make/FREE clampModes = {V_CLAMP_MODE, I_CLAMP_MODE, I_EQUAL_ZERO_MODE}
	SetDimensionLabels(clampModes, "VC;IC;IZ;", ROWS)

	return clampModes
End

static Function/WAVE GetChannelTypes()

	Make/FREE channelTypes = {CHANNEL_TYPE_DAC, CHANNEL_TYPE_TTL}

	SetDimensionLabels(channelTypes, "DAC;TTL", ROWS)

	return channelTypes
End

static Function/WAVE NonExistingDevices()

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

static Function/WAVE GetMiesMacrosWithPanelType()

	WAVE/T allMiesMacros = GetMIESMacros()

	Make/FREE/T panelsWithoutType = {"IDM_Headstage_Panel", "IDM_Popup_Panel", "DebugPanel", "ExportSettingsPanel", "PSXPanel", "WaverefBrowser"}

	WAVE/T matches = GetSetDifference(allMiesMacros, panelsWithoutType)

	SetDimensionLabels(matches, TextWaveToList(matches, ";"), ROWS)

	return matches
End

static Function/WAVE GetMiesMacrosWithCoordinateSaving()

	WAVE/T allMiesMacros = GetMIESMacros()

	Make/FREE/T panelsWithoutGroup = {"IDM_Headstage_Panel", "IDM_Popup_Panel", "DebugPanel", "ExportSettingsPanel", "WaverefBrowser"}

	WAVE/T matches = GetSetDifference(allMiesMacros, panelsWithoutGroup)

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
	wTemp[] = (wTemp[p] == 100) ? NaN : wTemp[p]
#else
#ifdef TESTS_WITH_ITC1600_HARDWARE
	wTemp[] = (wTemp[p] == 100) ? NaN : wTemp[p]
#endif // TESTS_WITH_ITC1600_HARDWARE
#endif // TESTS_WITH_ITC18USB_HARDWARE

	WAVE w = ZapNaNs(wTemp)

	SetDimensionLabelsFromWaveContents(w, prefix = "f_", suffix = "_kHz")

	return w
End

static Function/WAVE EpochTestSamplingMultiplier_Gen()

	string multipliers = DAP_GetSamplingMultiplier()

	WAVE wTemp = ListToNumericWave(multipliers, ";")
	wTemp[] = (wTemp[p] == 1) ? NaN : wTemp[p]
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

static Function/WAVE InfiniteValues()

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

static Function/WAVE IndexAfterDecimation_Positions()

	Make/FREE/D wv = {e / 11.1, Pi / 11.1, 0.73, 0.51}

	return wv
End

static Function/WAVE IndexAfterDecimation_Sizes()

	// These are variations of the target size, the source size is fixed 1000
	Make/FREE/D wv = {345, 678, 1234, 5678}

	return wv
End

static Function/WAVE CountObjectTypeFlags()

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

static Function/WAVE TrailSepOptions()

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

	Make/FREE/T input = {"NT_FP64", "NT_FP32", "NT_I32", "NT_I16", "NT_I8", "NT_I32 | NT_UNSIGNED", "NT_I16 | NT_UNSIGNED", "NT_I8 | NT_UNSIGNED", "TEXT_WAVE", "WAVE_WAVE"}
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
	Make/FREE/T wv3 = {"μA", "μ", "1e-6", "A"}

	Make/FREE/WAVE/N=1 result = {wv0, wv1, wv2, wv3}

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

	Make/FREE/T/N=5 wv

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

static Function/WAVE GetAmplifierFuncs()

	variable numEntries

	// ]MCC_BEGIN_INVALID_FUNC, MCC_LAST_HARDWARE_FUNC]

	numEntries = MCC_LAST_HARDWARE_FUNC - MCC_BEGIN_INVALID_FUNC

	Make/FREE/N=(numEntries) funcs = MCC_BEGIN_INVALID_FUNC + 1 + p

	CHECK_EQUAL_VAR(DimSize(funcs, ROWS), 33)

	return funcs
End

static Function/WAVE GetNoAmplifierFuncs()

	variable numEntries

	// ]MCC_LAST_HARDWARE_FUNC, MCC_END_INVALID_FUNC[

	numEntries = MCC_END_INVALID_FUNC - MCC_LAST_HARDWARE_FUNC - 1

	Make/FREE/N=(numEntries) funcs = MCC_LAST_HARDWARE_FUNC + 1 + p

	CHECK_EQUAL_VAR(DimSize(funcs, ROWS), 5)

	return funcs
End

static Function/WAVE PUB_TPFilters()

	Make/FREE/T wv = {ZMQ_FILTER_TPRESULT_NOW, ZMQ_FILTER_TPRESULT_NOW_WITH_DATA, ZMQ_FILTER_TPRESULT_1S, ZMQ_FILTER_TPRESULT_5S, ZMQ_FILTER_TPRESULT_10S}
	SetDimensionLabels(wv, "period_now;period_now with data;period_1s;period_5s;period_10s", ROWS)

	return wv
End

static Function/WAVE GetConcatSingleElementWaves()

	Make/FREE/N=4/WAVE waves

	Make/FREE srcNum = {4711}
	waves[0] = srcNum

	Make/FREE/T srcText = {"baccab"}
	waves[1] = srcText

	Make/FREE/DF srcDFR = {NewfreeDataFolder()}
	waves[2] = srcDFR

	Make/FREE/WAVE srcWv = {NewFreeWave(IGOR_TYPE_16BIT_INT, 0)}
	waves[3] = srcWv

	SetDimensionLabels(waves, "Numeric;Text;DFREF;WAVE", ROWS)

	return waves
End

static Function/WAVE GetConcatElementWaves2D()

	Make/FREE/N=4/WAVE waves

	Make/FREE/N=(2, 2) srcNum = 4711
	waves[0] = srcNum

	Make/FREE/T/N=(2, 2) srcText = "baccab"
	waves[1] = srcText

	Make/FREE/DF/N=(2, 2) srcDFR = NewfreeDataFolder()
	waves[2] = srcDFR

	Make/FREE/WAVE/N=(2, 2) srcWv = NewFreeWave(IGOR_TYPE_16BIT_INT, 0)
	waves[3] = srcWv

	SetDimensionLabels(waves, "Numeric;Text;DFREF;WAVE", ROWS)

	return waves
End

static Function/WAVE GetAnalysisFunctions()

	string funcs

	funcs = AFH_GetAnalysisFunctions(ANALYSIS_FUNCTION_VERSION_V3, includeUserFunctions = 0)

	// remove our test help functions which do nasty things
	funcs = GrepList(funcs, ".*_V3", 1)
	funcs = GrepList(funcs, ".*_.*")

	WAVE/T wv = ListToTextWave(funcs, ";")

	SetDimensionLabels(wv, funcs, ROWS)

	Sort/DIML wv, wv

	return wv
End

static Function/WAVE GetAnalysisParameterValues()

	Make/FREE/N=(5)/WAVE waves

	Make/FREE/T wv0 = {"var", "123"}
	waves[0] = wv0

	Make/FREE/T wv1 = {"str", "abcd"}
	waves[1] = wv1

	Make/FREE/T wv2 = {"wv", "1;2;"}
	waves[2] = wv2

	Make/FREE/T wv3 = {"txtwv", "a;b;"}
	waves[3] = wv3

	Make/FREE/T wv4 = {"i_dont_exist", ""}
	waves[4] = wv4

	return waves
End

static Function/WAVE OldEpochsFormats()

	Make/WAVE/N=2/FREE oldFormats = {root:EpochsWave:EpochsWave_4e534e298, root:EpochsWave:EpochsWave_d150d896e}

	SetDimensionLabels(oldFormats, "EpochsWave_4e534e298;EpochsWave_d150d896e", ROWS)

	return oldFormats
End

static Function/WAVE LBNInvalidValidPairs()

	Make/WAVE/N=5/FREE waves

	Make/T/FREE wv0 = {"a:b", "a [b]"}
	waves[0] = wv0

	Make/T/FREE wv1 = {"\"", "_"}
	waves[1] = wv1

	Make/T/FREE wv2 = {"\'", "_"}
	waves[2] = wv2

	Make/T/FREE wv3 = {";", "_"}
	waves[3] = wv3

	Make/T/FREE wv4 = {":", "_"}
	waves[4] = wv4

	return waves
End

static Function/WAVE AllDescriptionWaves()

	Make/FREE/WAVE/N=1 wvs

	// GetLBNumericalDescription creates a wave within the MIES datafolder, but that is killed at Test Begin
	// Thus, we use a copy of that wave here
	WAVE wDesc = GetLBNumericalDescription()
	Duplicate/FREE wDesc, wT
	wvs[0] = wT

	return wvs
End

static Function/WAVE ControlTypesWhichOnlyAcceptVar()

	Make/T/FREE wv = {"checkbox_ctrl_mode_checkbox", "slider_ctrl", "tab_ctrl", "valdisp_ctrl", "button_ctrl", "listbox_ctrl"}

	return wv
End

static Function/WAVE ControlTypesWhichRequireOneParameter()

	// all except button
	Make/T/FREE wv = {"checkbox_ctrl_mode_checkbox", "slider_ctrl", "tab_ctrl", "valdisp_ctrl", "popup_ctrl", "setvar_str_ctrl", "setvar_num_ctrl", "listbox_ctrl"}

	return wv
End

static Function/WAVE ControlTypesWhichOnlyAcceptVarOrStr()

	Make/T/FREE wv = {"popup_ctrl", "setvar_str_ctrl", "setvar_num_ctrl"}

	return wv
End

static Function/WAVE InvalidPopupMenuOtherIndizes()

	Make/FREE wv = {-1, NaN, Inf, -Inf, ItemsInList(PGCT_POPUPMENU_ENTRIES)}

	return wv
End

static Function/WAVE InvalidPopupMenuColorTableIndizes()

	Make/FREE wv = {-1, NaN, Inf, -Inf, ItemsInList(CTabList())}

	return wv
End

static Function/WAVE VariousModeFlags()

	Make/FREE/D modes = {-1, PGC_MODE_ASSERT_ON_DISABLED, PGC_MODE_FORCE_ON_DISABLED, PGC_MODE_SKIP_ON_DISABLED}

	return modes
End

static Function/WAVE StatsTest_GetInput()

	Make/T/FREE/N=(3) template
	SetDimensionLabels(template, "prop;state;postProc", ROWS)

	// wv0
	Duplicate/FREE/T template, wv0
	WAVE/T input = wv0

	input[%prop]     = "estate"
	input[%state]    = "accept"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {PSX_ACCEPT, PSX_ACCEPT, PSX_ACCEPT, PSX_ACCEPT})
	JWN_SetWaveInWaveNote(input, "/xValues", {1, 3, 5, 7})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})

	// wv1
	Duplicate/FREE/T template, wv1
	WAVE/T input = wv1

	input[%prop]     = "estate"
	input[%state]    = "reject"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {PSX_REJECT, PSX_REJECT, PSX_REJECT})
	JWN_SetWaveInWaveNote(input, "/xValues", {0, 4, 8})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_REJECT, PSX_MARKER_REJECT, PSX_MARKER_REJECT})

	// wv2
	Duplicate/FREE/T template, wv2
	WAVE/T input = wv2

	input[%prop]     = "estate"
	input[%state]    = "undetermined"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {PSX_UNDET, PSX_UNDET, PSX_UNDET})
	JWN_SetWaveInWaveNote(input, "/xValues", {2, 6, 9})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv3
	Duplicate/FREE/T template, wv3
	WAVE/T input = wv3

	input[%prop]     = "weightedTau"
	input[%state]    = "accept"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {0e-6, 4e-6, 8e-6})
	JWN_SetWaveInWaveNote(input, "/xValues", {0, 4, 8})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})

	// wv4
	Duplicate/FREE/T template, wv4
	WAVE/T input = wv4

	input[%prop]     = "amp"
	input[%state]    = "accept"
	input[%postProc] = "stats"

	JWN_SetWaveInWaveNote(input, "/results", {40, 40, 20, 25.81988897471611, 0, -2.0775, 20, 60, 40, 20, NaN})
	JWN_SetWaveInWaveNote(input, "/xValues", ListToTextWave(PSX_STATS_LABELS, ";"))
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, \
	                                         PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, \
	                                         PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, \
	                                         PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})
	// wv5
	Duplicate/FREE/T template, wv5
	WAVE/T input = wv5

	input[%prop]     = "fstate"
	input[%state]    = "undetermined"
	input[%postProc] = "count"

	JWN_SetWaveInWaveNote(input, "/results", {5})
	// no xValues
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET})

	// wv6
	Duplicate/FREE/T template, wv6
	WAVE/T input = wv6

	input[%prop]     = "peaktime"
	input[%state]    = "undetermined"
	input[%postProc] = "hist"

	JWN_SetWaveInWaveNote(input, "/results", {1, 2})
	// no xValues
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv7
	Duplicate/FREE/T template, wv7
	WAVE/T input = wv7

	input[%prop]     = "xinterval"
	input[%state]    = "undetermined"
	input[%postProc] = "log10"

	Make/FREE/D result = {NaN, log(60 - 20), log(90 - 60)}
	JWN_SetWaveInWaveNote(input, "/results", result)
	JWN_SetWaveInWaveNote(input, "/xValues", {2, 6, 9})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv8
	Duplicate/FREE/T template, wv8
	WAVE/T input = wv8

	input[%prop]     = "fitresult"
	input[%state]    = "undetermined"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {1, 1, 1, 1, 1})
	JWN_SetWaveInWaveNote(input, "/xValues", {1, 3, 5, 7, 9})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv9
	Duplicate/FREE/T template, wv9
	WAVE/T input = wv9

	input[%prop]     = "risetime"
	input[%state]    = "undetermined"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {0.2, 0.6, 0.9})
	JWN_SetWaveInWaveNote(input, "/xValues", {2, 6, 9})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv10
	Duplicate/FREE/T template, wv10
	WAVE/T input = wv10

	input[%prop]     = "peaktime"
	input[%state]    = "all"
	input[%postProc] = "nonfinite"

	JWN_SetWaveInWaveNote(input, "/results", {1, 3, 5, 7, 9})
	JWN_SetWaveInWaveNote(input, "/xValues", {0, -1, +1, 0, -1})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_UNDET})
	Make/FREE/T lbl = {"-inf", "NaN", "inf"}
	JWN_SetWaveInWaveNote(input, "/XTickLabels", lbl)
	JWN_SetWaveInWaveNote(input, "/XTickPositions", {-1, 0, 1})

	// end
	Make/FREE/WAVE results = {wv0, wv1, wv2, wv3, wv4, wv5, wv6, wv7, wv8, wv9, wv10}

	return results
End

Function/WAVE StatsTestSpecialCases_GetInput()

	Make/T/FREE/N=(7) template
	SetDimensionLabels(template, "prop;state;postProc;refNumOutputRows;numEventsCombo0;numEventsCombo1;outOfRange", ROWS)

	// wv0
	// every
	Duplicate/FREE/T template, wv0
	WAVE/T input = wv0

	input[%prop]             = "estate"
	input[%state]            = "every"
	input[%postProc]         = "nothing"
	input[%refNumOutputRows] = "3"
	input[%numEventsCombo0]  = "5"
	input[%numEventsCombo1]  = "3"
	input[%outOfRange]       = "0"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {PSX_ACCEPT, PSX_ACCEPT, PSX_ACCEPT})
	JWN_SetWaveInWaveNote(input, "/0/xValues", {1, 3, 1})
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})

	JWN_CreatePath(input, "/1")
	JWN_SetWaveInWaveNote(input, "/1/results", {PSX_REJECT, PSX_REJECT, PSX_REJECT})
	JWN_SetWaveInWaveNote(input, "/1/xValues", {0, 4, 0})
	JWN_SetWaveInWaveNote(input, "/1/marker", {PSX_MARKER_REJECT, PSX_MARKER_REJECT, PSX_MARKER_REJECT})

	JWN_CreatePath(input, "/2")
	JWN_SetWaveInWaveNote(input, "/2/results", {PSX_UNDET, PSX_UNDET})
	JWN_SetWaveInWaveNote(input, "/2/xValues", {2, 2})
	JWN_SetWaveInWaveNote(input, "/2/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv1
	// no match
	Duplicate/FREE/T template, wv1
	WAVE/T input = wv1

	input[%prop]             = "estate"
	input[%state]            = "accept"
	input[%postProc]         = "nothing"
	input[%refNumOutputRows] = "0"
	input[%numEventsCombo0]  = "1"
	input[%numEventsCombo1]  = "1"
	input[%outOfRange]       = "0"

	// wv2
	// histogram works also with just one point
	Duplicate/FREE/T template, wv2
	WAVE/T input = wv2

	input[%prop]             = "estate"
	input[%state]            = "reject"
	input[%postProc]         = "hist"
	input[%refNumOutputRows] = "1"
	input[%numEventsCombo0]  = "1"
	input[%numEventsCombo1]  = "0"
	input[%outOfRange]       = "0"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {1})
	// no x values
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_REJECT})

	// wv3
	// histogram with no match as the tau values are out-of-range
	Duplicate/FREE/T template, wv3
	WAVE/T input = wv3

	input[%prop]             = "weightedTau"
	input[%state]            = "undetermined"
	input[%postProc]         = "hist"
	input[%refNumOutputRows] = "0"
	input[%numEventsCombo0]  = "3"
	input[%numEventsCombo1]  = "0"
	input[%outOfRange]       = "1"

	// wv4
	// histogram with match but cut out data
	Duplicate/FREE/T template, wv4
	WAVE/T input = wv4

	input[%prop]             = "amp"
	input[%state]            = "all"
	input[%postProc]         = "hist"
	input[%refNumOutputRows] = "1"
	input[%numEventsCombo0]  = "3"
	input[%numEventsCombo1]  = "0"
	input[%outOfRange]       = "1"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {1})
	// no xValues
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_REJECT})

	// wv5
	// stats ignores NaN
	Duplicate/FREE/T template, wv5
	WAVE/T input = wv5

	input[%prop]             = "amp"
	input[%state]            = "all"
	input[%postProc]         = "stats"
	input[%refNumOutputRows] = "1"
	input[%numEventsCombo0]  = "2"
	input[%numEventsCombo1]  = "2"
	input[%outOfRange]       = "0"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {10, NaN, 0, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN})
	JWN_SetWaveInWaveNote(input, "/0/xValues", ListToTextWave(PSX_STATS_LABELS, ";"))
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_REJECT, PSX_MARKER_REJECT, PSX_MARKER_REJECT, \
	                                           PSX_MARKER_REJECT, PSX_MARKER_REJECT, PSX_MARKER_REJECT, \
	                                           PSX_MARKER_REJECT, PSX_MARKER_REJECT, PSX_MARKER_REJECT, \
	                                           PSX_MARKER_REJECT, PSX_MARKER_REJECT})

	// wv6
	// stats ignores NaN and with all data NaN we don't get anything
	Duplicate/FREE/T template, wv6
	WAVE/T input = wv6

	input[%prop]             = "amp"
	input[%state]            = "all"
	input[%postProc]         = "stats"
	input[%refNumOutputRows] = "0"
	input[%numEventsCombo0]  = "1"
	input[%numEventsCombo1]  = "1"
	input[%outOfRange]       = "0"

	// no results
	// no xValues
	// no marker

	// wv7
	// xinterval with multiple combos
	Duplicate/FREE/T template, wv7
	WAVE/T input = wv7

	input[%prop]             = "xinterval"
	input[%state]            = "accept"
	input[%postProc]         = "nothing"
	input[%refNumOutputRows] = "1"
	input[%numEventsCombo0]  = "5"
	input[%numEventsCombo1]  = "5"
	input[%outOfRange]       = "0"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {NaN, 20, NaN, 20})
	JWN_SetWaveInWaveNote(input, "/0/xValues", {1, 3, 1, 3})
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})

	// end
	Make/FREE/WAVE results = {wv0, wv1, wv2, wv3, wv4, wv5, wv6, wv7}

	return results
End

static Function/WAVE GetAllStatsProperties()

	WAVE wv = MIES_PSX#PSX_GetAllStatsProperties()
	CHECK_WAVE(wv, TEXT_WAVE)

	SetDimensionLabelsFromWaveContents(wv)

	return wv
End

static Function/WAVE GetKernelAmplitude()

	Make/D/FREE wv = {5, -5}

	return wv
End

static Function/WAVE SupportedPostProcForEventSelection()

	// nonfinite is tested elsewhere
	Make/FREE/T wv = {"nothing", "log10"}
	SetDimensionLabels(wv, AddPrefixToEachListItem("PostProc=", TextWavetoList(wv, ";")), ROWS)

	return wv
End

static Function/WAVE SupportedAxisModesForEventSelection()

	Make/FREE wv = {MODIFY_GRAPH_LOG_MODE_NORMAL, MODIFY_GRAPH_LOG_MODE_LOG10, MODIFY_GRAPH_LOG_MODE_LOG2}
	SetDimensionLabels(wv, "LeftAxis=linear;LeftAxis=log10;LeftAxis=log2", ROWS)

	return wv
End

static Function/WAVE GetCodeVariations()

	string code

	Make/T/N=(2)/FREE wv

	// one sweep per operation separated with `with`
	code  = "psx(myId, psxKernel(select(selrange([50, 150]), selchannels(AD6), selsweeps([0]), selvis(all))), 2, psxSweepBPFilter(100, 0))"
	code += "\r with \r"
	code += "psx(myId, psxKernel(select(selrange([50, 150]), selchannels(AD6), selsweeps([2]), selvis(all))), 0.3, psxSweepBPFilter(100, 0))"
	code += "\r and \r"
	code += "psxStats(myId, select(selrange([50, 150]), selchannels(AD6), selsweeps([0, 2]), selvis(all)), peak, all, nothing)"
	wv[0] = code
	code  = ""

	// same as code[1] but with a select array for stats
	code  = "psx(myId, psxKernel(select(selrange([50, 150]), selchannels(AD6), selsweeps([0]), selvis(all))), 2, psxSweepBPFilter(100, 0))"
	code += "\r with \r"
	code += "psx(myId, psxKernel(select(selrange([50, 150]), selchannels(AD6), selsweeps([2]), selvis(all))), 0.3, psxSweepBPFilter(100, 0))"
	code += "\r and \r"
	code += "psxStats(myId, [select(selrange([50, 150]), selchannels(AD6), selsweeps([0]), selvis(all)), select(selrange([50, 150]), selchannels(AD6), selsweeps([2]), selvis(all))], peak, all, nothing)"
	wv[1] = code
	code  = ""

	return wv
End

static Function/WAVE SomeTextWaves()

	Make/WAVE/FREE/N=5 all

	Make/FREE/T/N=0 wv1

	// both empty and null roundtrip to an empty wave
	all[0] = wv1
	all[1] = $""

	Make/FREE/T/N=(3, 3) wv2 = {{"1", "2", "3"}, {"4", "5", "6"}, {"7", "8", "9"}}
	all[2] = wv2

	Make/FREE/T/N=(2, 2, 2) wv3 = {{{"1", "2"}, {"3", "4"}}, {{"5", "6"}, {"7", "8"}}}
	all[3] = wv3

	Make/FREE/T/N=(2, 2, 2, 2) wv4 = {{{{"1", "2"}, {"3", "4"}}, {{"5", "6"}, {"7", "8"}}}, {{{"9", "10"}, {"11", "12"}}, {{"13", "14"}, {"15", "16"}}}}
	all[4] = wv4

	return all
End

static Function/WAVE STIW_TestAbortGetter()

	Make/D/FREE data = {4, -1, 0.1, NaN, Inf, -Inf}
	return data
End

static Function/WAVE GetValidStringsWithSweepNumber()

	Make/FREE/T wv = {"Sweep_100", "Sweep_100_bak", "Config_Sweep_100", "Config_Sweep_100_bak", "X_100"}

	return wv
End

static Function/WAVE GetInvalidStringsWithSweepNumber()

	Make/FREE/T wv = {"", "A", "A__", "Sweep_-100"}

	return wv
End

static Function/WAVE SupportedTypeGetter()

	Make/FREE result = {IGOR_TYPE_32BIT_FLOAT, IGOR_TYPE_64BIT_FLOAT}

	SetDimLabel 0, 0, $"float", result
	SetDimLabel 0, 1, $"double", result

	return result
End

static Function/WAVE WB_GatherStimsets()

	string list

	DFREF dfr = root:wavebuilder_misc:DAParameterWaves
	list = GetListOfObjects(dfr, "WP_.*")
	list = RemovePrefixFromListItem("WP_", list)
	WAVE/T wv = ListToTextWave(list, ";")

	SetDimensionLabels(wv, list, ROWS)

	return wv
End

static Function/WAVE PAT_IncrementalSweepAdd_Generator()

	Make/FREE/WAVE/N=4 w

	Make/FREE sweeps = {0, 1, 2, 3, 4, 5}
	w[0] = sweeps
	Make/FREE sweeps = {5, 4, 3, 2, 1, 0}
	w[1] = sweeps
	Make/FREE sweeps = {2, 1, 5, 3, 4, 0}
	w[2] = sweeps
	Make/FREE sweeps = {4, 3, 5, 0, 1, 2}
	w[3] = sweeps

	return w
End

static Function/WAVE AllDatabrowserSubWindows()

	string win

	win = DB_OpenDatabrowser()

	WAVE/Z/T allWindows = ListToTextWave(GetAllWindows(win), ";")
	CHECK_WAVE(allWindows, TEXT_WAVE)

	allWindows[] = StringFromList(1, allWindows[p], "#")

	RemoveTextWaveEntry1D(allWindows, "", all = 1)

	WAVE/Z/T allWindowsUnique = GetUniqueEntries(allWindows)
	CHECK_WAVE(allWindowsUnique, TEXT_WAVE)

	SetDimensionLabels(allWindowsUnique, TextWaveToList(allWindowsUnique, ";"), ROWS)

	KillWindow $win

	return allWindowsUnique
End

static Function/WAVE VariousInputForHasRequiredQCOrder()

	// IPT_FORMAT_OFF

	// all zero
	Make/FREE firstQC      = {0, 0, 0, 0}
	Make/FREE checkQCFirst = {0, 0, 0}
	Make/FREE lastQC       = {0, 0, 0, 0}
	Make/FREE checkQCLast  = {0, 0, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv0 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// only first
	Make/FREE firstQC      = {0, 0, 0, 0}
	Make/FREE checkQCFirst = {1, 1, 1}
	Make/FREE lastQC       = {0, 0, 0, 0}
	Make/FREE checkQCLast  = {0, 0, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv1 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// only last
	Make/FREE firstQC      = {0, 0, 0, 0}
	Make/FREE checkQCFirst = {0, 0, 0}
	Make/FREE lastQC       = {0, 0, 0, 0}
	Make/FREE checkQCLast  = {1, 1, 1}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv2 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// wrong order
	Make/FREE firstQC      = {0, 1, 1, 0}
	Make/FREE checkQCFirst = {0, 1, 0}
	Make/FREE lastQC       = {0, 1, 1, 0}
	Make/FREE checkQCLast  = {1, 0, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv3 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// correct order
	Make/FREE firstQC      = {0, 1, 1, 0}
	Make/FREE checkQCFirst = {1, 0, 0}
	Make/FREE lastQC       = {0, 1, 1, 0}
	Make/FREE checkQCLast  = {0, 1, 0}
	Make/FREE result       = {1}

	Make/FREE/WAVE wv4 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// correct order but last sweep failed
	Make/FREE firstQC      = {0, 1, 0, 0}
	Make/FREE checkQCFirst = {1, 0, 0}
	Make/FREE lastQC       = {0, 1, 0, 0}
	Make/FREE checkQCLast  = {0, 1, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv5 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// correct order but first sweep failed
	Make/FREE firstQC      = {0, 0, 0, 0}
	Make/FREE checkQCFirst = {1, 0, 0}
	Make/FREE lastQC       = {0, 0, 1, 0}
	Make/FREE checkQCLast  = {0, 1, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv6 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// passes with fail gap
	Make/FREE firstQC      = {0, 0, 1, 0, 0}
	Make/FREE checkQCFirst = {0, 1, 0, 0}
	Make/FREE lastQC       = {0, 0, 0, 0, 1}
	Make/FREE checkQCLast  = {0, 0, 0, 1}
	Make/FREE result       = {1}

	Make/FREE/WAVE wv7 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// fails due to gap with firstQC passing
	Make/FREE firstQC      = {0, 0, 1, 1, 0}
	Make/FREE checkQCFirst = {0, 1, 0, 0}
	Make/FREE lastQC       = {0, 0, 0, 0, 1}
	Make/FREE checkQCLast  = {0, 0, 0, 1}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv8 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// fails due to gap with lastQC passing
	Make/FREE firstQC      = {0, 1, 0, 0, 0}
	Make/FREE checkQCFirst = {1, 0, 0, 0}
	Make/FREE lastQC       = {0, 0, 1, 1, 0}
	Make/FREE checkQCLast  = {0, 0, 1, 0}
	Make/FREE result       = {0}

	// IPT_FORMAT_ON

	Make/FREE/WAVE wv9 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	Make/FREE/WAVE wv = {wv0, wv1, wv2, wv3, wv4, wv5, wv6, wv7, wv8, wv9}

	return wv
End

static Function/WAVE VariousInputForCalculateFillinQC()

	// all constant
	Make/FREE DAScales = {1, 1, 1, 1}
	Make/FREE ref = {0, 0, 0, 0}

	Make/FREE/WAVE wv0 = {DAScales, ref}

	// sorted
	Make/FREE DAScales = {1, 2, 3, 4}
	Make/FREE ref = {0, 0, 0, 0}

	Make/FREE/WAVE wv1 = {DAScales, ref}

	// reverse sorted
	Make/FREE DAScales = {4, 3, 2, 1}
	Make/FREE ref = {0, 1, 1, 1}

	Make/FREE/WAVE wv2 = {DAScales, ref}

	// first is largest
	Make/FREE DAScales = {8, 4, 7, 6, 5}
	Make/FREE ref = {0, 1, 1, 1, 1}

	Make/FREE/WAVE wv3 = {DAScales, ref}

	// complicated, smallest first
	Make/FREE DAScales = {1, 4, 3, 6, 5}
	Make/FREE ref = {0, 0, 1, 0, 1}

	Make/FREE/WAVE wv4 = {DAScales, ref}

	// complicated, middle one first
	Make/FREE DAScales = {3, 4, 1, 6, 5}
	Make/FREE ref = {0, 0, 1, 0, 1}

	Make/FREE/WAVE wv5 = {DAScales, ref}

	Make/FREE/WAVE wv = {wv0, wv1, wv2, wv3, wv4, wv5}

	return wv
End

static Function/WAVE CacheOptions()

	Make/FREE wv = {0, CA_OPTS_NO_DUPLICATE}

	SetDimensionLabels(wv, "none;no duplicate", ROWS)

	return wv
End

static Function/WAVE DG_SourceLocationsBrackets()

	Make/FREE/T wv = {"\"\r\"\"", "(\r))", "[\r]]"}

	SetDimensionLabels(wv, "parenthesis;braces;brackets", ROWS)

	return wv
End

static Function/WAVE DG_SourceLocationsVarious()

	Make/FREE pos = {4}
	Make/FREE/T formula = {"max(,,)"}
	Make/FREE/WAVE wv0 = {pos, formula}

	Make/FREE pos = {6}
	Make/FREE/T formula = {"max(1,a)"}
	Make/FREE/WAVE wv1 = {pos, formula}

	Make/FREE pos = {12}
	Make/FREE/T formula = {"max(1...10) + a"}
	Make/FREE/WAVE wv2 = {pos, formula}

	Make/FREE pos = {11}
	Make/FREE/T formula = {"max(1, min(a))"}
	Make/FREE/WAVE wv3 = {pos, formula}

	Make/FREE pos = {2}
	Make/FREE/T formula = {"1+++1"}
	Make/FREE/WAVE wv4 = {pos, formula}

	Make/FREE pos = {13}
	Make/FREE/T formula = {"[1*(-1),1*-1][]"}
	Make/FREE/WAVE wv4 = {pos, formula}

	Make/FREE/WAVE wv = {wv0, wv1, wv2, wv3, wv4}

	return wv
End

static Function/WAVE DG_SourceLocationsJSON()

	Make/FREE pos = {4}
	Make/FREE/T formula = {"1"}
	Make/FREE/WAVE wv0 = {pos, formula}

	Make/FREE pos = {6}
	Make/FREE/T formula = {"1+2"}
	Make/FREE/WAVE wv1 = {pos, formula}

	Make/FREE pos = {12}
	Make/FREE/T formula = {"max()"}
	Make/FREE/WAVE wv2 = {pos, formula}

	Make/FREE pos = {11}
	Make/FREE/T formula = {"max(1)"}
	Make/FREE/WAVE wv3 = {pos, formula}

	Make/FREE pos = {2}
	Make/FREE/T formula = {"[1,2]"}
	Make/FREE/WAVE wv4 = {pos, formula}

	Make/FREE pos = {13}
	Make/FREE/T formula = {"1+2*3"}
	Make/FREE/WAVE wv4 = {pos, formula}

	Make/FREE/WAVE wv = {wv0, wv1, wv2, wv3, wv4}

	return wv
End

static Function/WAVE DG_SourceLocationsContent()

	Make/FREE/T wFormula = {"max(max(1,1),1)"}
	Make/FREE/T/N=(6, 2) wSrcLocs
	wSrcLocs[0][0] = "/max"
	wSrcLocs[0][1] = "0"
	wSrcLocs[1][0] = "/max/0/max"
	wSrcLocs[1][1] = "4"
	wSrcLocs[2][0] = "/max/0/max/0"
	wSrcLocs[2][1] = "8"
	wSrcLocs[3][0] = "/max/0/max/1"
	wSrcLocs[3][1] = "10"
	wSrcLocs[4][0] = "/max/0"
	wSrcLocs[4][1] = "4"
	wSrcLocs[5][0] = "/max/1"
	wSrcLocs[5][1] = "13"
	Make/FREE/WAVE wv0 = {wFormula, wSrcLocs}

	Make/FREE/T wFormula = {"1+[1,2,3]"}
	Make/FREE/T/N=(5, 2) wSrcLocs
	wSrcLocs[0][0] = "/+"
	wSrcLocs[0][1] = "0"
	wSrcLocs[1][0] = "/+/0"
	wSrcLocs[1][1] = "0"
	wSrcLocs[2][0] = "/+/1/0"
	wSrcLocs[2][1] = "3"
	wSrcLocs[3][0] = "/+/1/1"
	wSrcLocs[3][1] = "5"
	wSrcLocs[4][0] = "/+/1/2"
	wSrcLocs[4][1] = "7"
	Make/FREE/WAVE wv1 = {wFormula, wSrcLocs}

	Make/FREE/T wFormula = {"[1, max(1)]"}
	Make/FREE/T/N=(3, 2) wSrcLocs
	wSrcLocs[0][0] = "/0"
	wSrcLocs[0][1] = "1"
	wSrcLocs[1][0] = "/1/max"
	wSrcLocs[1][1] = "4"
	wSrcLocs[2][0] = "/1/max/0"
	wSrcLocs[2][1] = "8"
	Make/FREE/WAVE wv2 = {wFormula, wSrcLocs}

	Make/FREE/T wFormula = {"[1,[2]]"}
	Make/FREE/T/N=(3, 2) wSrcLocs
	wSrcLocs[0][0] = "/0"
	wSrcLocs[0][1] = "1"
	wSrcLocs[1][0] = "/1"
	wSrcLocs[1][1] = "3"
	wSrcLocs[2][0] = "/1/0"
	wSrcLocs[2][1] = "4"
	Make/FREE/WAVE wv3 = {wFormula, wSrcLocs}

	Make/FREE/T wFormula = {"[[1],[3,4],[5,6]]"}
	Make/FREE/T/N=(6, 2) wSrcLocs
	wSrcLocs[0][0] = "/0"
	wSrcLocs[0][1] = "1"
	wSrcLocs[1][0] = "/0/0"
	wSrcLocs[1][1] = "2"
	wSrcLocs[2][0] = "/1/0"
	wSrcLocs[2][1] = "6"
	wSrcLocs[3][0] = "/1/1"
	wSrcLocs[3][1] = "8"
	wSrcLocs[4][0] = "/2/0"
	wSrcLocs[4][1] = "12"
	wSrcLocs[5][0] = "/2/1"
	wSrcLocs[5][1] = "14"
	Make/FREE/WAVE wv4 = {wFormula, wSrcLocs}

	Make/FREE/WAVE wv = {wv0, wv1, wv2, wv3, wv4}

	return wv
End

static Function/WAVE GetAllPSXFilterOperations()

	Make/FREE/T wv = {"psxDeconvBPFilter", "psxSweepBPFilter"}

	SetDimensionLabelsFromWaveContents(wv)

	return wv
End

static Function/WAVE GetAllPSXStates()

	WAVE wv = MIES_PSX#PSX_GetStates(withAllState = 1)

	Make/FREE/T/N=(DimSize(wv, ROWS)) labels = MIES_PSX#PSX_StateToString(wv[p])

	SetDimensionLabels(wv, TextWaveToList(labels, ";"), ROWS)

	return wv
End

static Function/WAVE GetPSXHelperAxisTypes()

	Make/FREE/T wv = {NONE, "deconv", "peak", "baseline"}

	SetDimensionLabelsFromWaveContents(wv)

	return wv
End
