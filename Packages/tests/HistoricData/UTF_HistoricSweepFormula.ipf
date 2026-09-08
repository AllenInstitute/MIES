#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HistoricDataSweepFormula

static Function TestSelectWithSeltag()

	string abWin, sweepBrowsers, sweepBrowser, str

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 0)

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	PGC_SetAndActivateControl(abWin, "button_show_tagcontrol")

	expBrowserSel[0][0][0] = expBrowserSel[0][0][0] | LISTBOX_SELECTED
	SetSetVariableString(MIES_AB#AB_GetTagControlName(), "setvar_tagcontrol_tagname", "myTag1")
	PGC_SetAndActivateControl(MIES_AB#AB_GetTagControlName(), "button_tagcontrol_addtag")
	expBrowserSel[0][0][0] = expBrowserSel[0][0][0] | LISTBOX_SELECTED
	SetSetVariableString(MIES_AB#AB_GetTagControlName(), "setvar_tagcontrol_tagname", "myTag2")
	PGC_SetAndActivateControl(MIES_AB#AB_GetTagControlName(), "button_tagcontrol_addtag")

	sweepBrowser = LoadSweepsFromAllExperimentsFromAB(abWin)

	// select with not tags set
	str = "select(selvis(displayed))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 1)

	str = "select(selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), (98 + 78) * 2)

	// with seltag set
	str = "select(seltag([myTag1,myTag2]),selvis(displayed))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 1)

	str = "select(seltag([myTag1,myTag2]),selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 98 * 2)

	str = "select(seltag([myTag2,myTag1]),selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 98 * 2)

	str = "select(seltag(myTag1),selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_WAVE(datasel, NULL_WAVE)

	str = "select(seltag(\"\"),selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 78 * 2)

	str = "select(seltag(myTag1),seltag(myTag2))"
	ExecuteSweepFormulaCode(sweepBrowser, str, expectFailure = 1)
End

static Function/WAVE GetRefData()

	// number of peaks from apfrequency with default settings
	Make/FREE/D dataRef1 = {0, 1, 1, 2, 2, 20, 46, 55, 64, 89, 116, 141, 74}
	// max output current in sweeps DA channel
	Make/FREE/D xDataRef1 = {36, 38, 54, 61, 64, 68, 88, 108, 128, 182, 255, 374, 531}
	Make/FREE/D dataRef2 = {0, 5, 2, 18, 27, 58, 87, 109, 132, 175, 228, 275, 309}
	Make/FREE/D xDataRef2 = {130, 140, 147, 155, 170, 190, 210, 230, 268, 351, 479, 655, 867}

	Make/FREE/D avgDataRef = {0, 3, 1.5, 10, 14.5, 39, 66.5, 82, 98, 132, 172, 208, 191.5}
	Make/FREE/D xAvgDataRef = {83, 89, 100.5, 108, 117, 129, 149, 169, 198, 266.5, 367, 514.5, 699}
	Make/FREE/D fitDataRef = {NaN, -9.135609134854235, 6.792363194700215, 16.08563201991842, 26.47829761181345, 38.93664859188129, 57.44915335628912, 73.717024577703, 94.1953994857563, 132.5657870085096, 173.8614384346001, 217.4785790971106, NaN}
	Make/FREE/D fitxDataRef = {NaN, 88.87793321106729, 100.554524599647, 108.0635739861901, 117.1270485575746, 128.9993157257618, 148.8996436554057, 168.9060878165089, 197.9556707914339, 266.5069237449363, 367.0239482427364, 514.6282046677733, NaN}

	Make/FREE/D dascaleYRef = {141, NaN}
	Make/FREE/D dascaleXRef = {374, NaN}

	Make/FREE/D dascaleAvgYRef = {141}
	Make/FREE/D dascaleAvgXRef = {374}

	Make/FREE/D avgDataBinsRef = {34.95, 93.58333333333334, 132, 158, 228, 74, NaN}
	Make/FREE/D xAvgDataBinsRef = {133.2, 214.25, 268, 362.5, 479, 531, NaN}
	Make/FREE/D fitDataBinsRef = {16.14485805525101, 95.01278145856668, 132, 182.094966964785, 228, NaN, NaN}
	Make/FREE/D fitxDataBinsRef = {132.9758617407321, 214.2722901887894, 268, 362.8597710244014, 479, NaN, NaN}

	Make/FREE/WAVE wv = {dataRef1, xDataRef1, dataRef2, xDataRef2, dascaleYRef, dascaleXRef, dascaleAvgYRef, dascaleAvgXRef, avgDataRef, xAvgDataRef, fitDataRef, fitxDataRef, avgDataBinsRef, xAvgDataBinsRef, fitDataBinsRef, fitxDataBinsRef}
	SetDimensionLabels(wv, "data1;xdata1;data2;xdata2;dascaleY;dascaleX;dascaleAvgY;dascaleAvgX;avgdata;avgxdata;fitdata;fitxdata;avgbinsdata;xavgbinsdata;fitbinsdata;fitbinsxdata;", ROWS)

	for(data : wv)
		Redimension/N=(-1, 1) data // from SF_PrepareResultWavesForPlotting
	endfor

	return wv
End

static Function/WAVE TestIVSCCAPFrequencyBinsGetTraceNames()

	Make/FREE/T plot0 = {"T000000d0_untagged_Scn1a_R613X_B6_825669_02_09_02_nwb", "T000001d0_untagged_Scn1a_R613X_B6_825669_02_09_04_nwb"}
	Make/FREE/T plot1 = {"T000000d0_untagged_ivscc_apfrequency_concat"}
	Make/FREE/T plot2 = {"T000000d0_untagged_ivscc_apfrequency_avg_bins"}
	Make/FREE/T plot3 = {"T000000d0_untagged_ivscc_apfrequency_fit"}
	Make/FREE/T plot4 = {"T000000d0_untagged_ivscc_apfrequency_DAScale"}
	Make/FREE/T plot5 = {"T000000d0_untagged_ivscc_apfrequency_Mean_Maximal_Firing_Point"}
	Make/FREE/WAVE traceNamesPlot = {plot0, plot1, plot2, plot3, plot4, plot5}

	CHECK_EQUAL_VAR(DimSize(traceNamesPlot, ROWS), 6) // see SF_IVSCC_APFREQUENCY_PLOTTYPE_ENUM_MAX

	return traceNamesPlot
End

static Function TestIVSCCAPFrequencyCheckTraceNames(WAVE/WAVE traceNamesPlot, string wName)

	variable i
	string   subWin

	for(WAVE/T traceNames : traceNamesPlot)
		subWin = wName + "#graph" + num2istr(i) // see SF_CreateDataDisplayWindow
		if(!WaveExists(traceNames))
			CHECK_EQUAL_VAR(WindowExists(subWin), 0)
			i += 1
			continue
		endif
		WAVE/T traceList = ListToTextWave(TraceNameList(subWin, ";", 0x01), ";")
		CHECK_EQUAL_WAVES(traceList, traceNames)
		i += 1
	endfor
End

static Function TestIVSCCAPFrequencyTraceDistribution()

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName, subWin
	variable i

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(on, none, none, 100, 100, prepareFit(log, 0, standard), bins, [100, 600], 80)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)
	wName = GetMainWindow(GetCurrentWindow())

	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()
	TestIVSCCAPFrequencyCheckTraceNames(traceNamesPlot, wName)
End

static Function [WAVE yWave, WAVE xWave] TestIVSCCAPFrequencyConcat(WAVE/WAVE yWaves, WAVE/WAVE xWaves)

	Concatenate/FREE/NP=(ROWS) {yWaves}, data3
	Concatenate/FREE/NP=(ROWS) {xWaves}, xdata3
	Sort xdata3, xdata3, data3

	return [data3, xdata3]
End

static Function TestIVSCCAPFrequencyGraph0_Graph1(string subWin, string subWin1)

	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()

	WAVE/T traceNames = traceNamesPlot[0]
	WAVE   data1      = TraceNameToWaveRef(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(data1, refData[%data1], mode = WAVE_DATA)
	WAVE data2 = TraceNameToWaveRef(subWin, traceNames[1])
	CHECK_EQUAL_WAVES(data2, refData[%data2], mode = WAVE_DATA)
	WAVE xData1 = XWaveRefFromTrace(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(xData1, refData[%xdata1], mode = WAVE_DATA)
	WAVE xData2 = XWaveRefFromTrace(subWin, traceNames[1])
	CHECK_EQUAL_WAVES(xData2, refData[%xdata2], mode = WAVE_DATA)

	WAVE/T traceNames  = traceNamesPlot[1]
	WAVE   concatData  = TraceNameToWaveRef(subWin1, traceNames[0])
	WAVE   concatXData = XWaveRefFromTrace(subWin1, traceNames[0])
	[WAVE data3, WAVE xdata3] = TestIVSCCAPFrequencyConcat({data1, data2}, {xData1, xData2})
	CHECK_EQUAL_WAVES(concatData, data3, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(concatXData, xdata3, mode = WAVE_DATA)
End

static Function TestIVSCCAPFrequencyGraph2(string subWin)

	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()

	WAVE/T traceNames = traceNamesPlot[2]
	WAVE   avgData    = TraceNameToWaveRef(subWin, traceNames[0])
	WAVE   xAvgData   = XWaveRefFromTrace(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(avgData, refData[%avgbinsdata], mode = WAVE_DATA, tol = 1E-12)
	CHECK_EQUAL_WAVES(xAvgData, refData[%xavgbinsdata], mode = WAVE_DATA, tol = 1E-12)
End

static Function TestIVSCCAPFrequencyBins2Graph2(string subWin)

	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()

	WAVE/T traceNames = traceNamesPlot[2]
	traceNames[0] += "2"
	WAVE avgData  = TraceNameToWaveRef(subWin, traceNames[0])
	WAVE xAvgData = XWaveRefFromTrace(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(avgData, refData[%avgdata], mode = WAVE_DATA, tol = 1E-12)
	CHECK_EQUAL_WAVES(xAvgData, refData[%avgxdata], mode = WAVE_DATA, tol = 1E-12)
End

static Function TestIVSCCAPFrequencyGraph3(string subWin)

	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()

	WAVE/T traceNames = traceNamesPlot[3]
	WAVE   fitData    = TraceNameToWaveRef(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(fitData, refData[%fitbinsdata], mode = WAVE_DATA, tol = 3E-2)
	WAVE xFitData = XWaveRefFromTrace(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(xFitData, refData[%fitbinsxdata], mode = WAVE_DATA, tol = 3E-2)
End

static Function TestIVSCCAPFrequencyGraph4(string subWin)

	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()

	WAVE/T traceNames   = traceNamesPlot[4]
	WAVE   dascaleDataY = TraceNameToWaveRef(subWin, traceNames[0])
	WAVE   dascaleDataX = XWaveRefFromTrace(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(dascaleDataY, refData[%dascaleY], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(dascaleDataX, refData[%dascaleX], mode = WAVE_DATA)
End

static Function TestIVSCCAPFrequencyGraph5(string subWin)

	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()

	WAVE/T traceNames      = traceNamesPlot[5]
	WAVE   dascaleAvgDataY = TraceNameToWaveRef(subWin, traceNames[0])
	WAVE   dascaleAvgDataX = XWaveRefFromTrace(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(dascaleAvgDataY, refData[%dascaleAvgY], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(dascaleAvgDataX, refData[%dascaleAvgX], mode = WAVE_DATA)
End

static Function TestIVSCCAPFrequencyBins()

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(on, none, none, 100, 100, prepareFit(log, 0, standard), bins, [100, 600], 80)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	wName = GetMainWindow(GetCurrentWindow()) + "#graph"
	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()

	// check data
	TestIVSCCAPFrequencyGraph0_Graph1(wName + "0", wName + "1")
	TestIVSCCAPFrequencyGraph2(wName + "2")
	TestIVSCCAPFrequencyGraph3(wName + "3")
	TestIVSCCAPFrequencyGraph4(wName + "4")
	TestIVSCCAPFrequencyGraph5(wName + "5")
End

static Function TestIVSCCAPFrequencyBins2()

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName, subWin

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code  = "ivscc_apfrequency(on, none, none, 100, 100, prepareFit(), bins2)\r"
	code += "and\r"
	code += "ivscc_apfrequency(on, none, none, 100, 100, prepareFit(log, 0, standard), bins2)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()
	wName = GetMainWindow(GetCurrentWindow()) + "#graph"

	TestIVSCCAPFrequencyGraph0_Graph1(wName + "0", wName + "1")
	TestIVSCCAPFrequencyGraph0_Graph1(wName + "6", wName + "7")

	TestIVSCCAPFrequencyBins2Graph2(wName + "2")
	TestIVSCCAPFrequencyBins2Graph2(wName + "8")

	CHECK_EQUAL_VAR(WindowExists(wName + "3"), 0)
	subWin = wName + "9"
	WAVE/T traceNames = traceNamesPlot[3]
	WAVE   fitData    = TraceNameToWaveRef(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(fitData, refData[%fitdata], mode = WAVE_DATA, tol = 1E-12)
	WAVE xFitData = XWaveRefFromTrace(subWin, traceNames[0])
	CHECK_EQUAL_WAVES(xFitData, refData[%fitxdata], mode = WAVE_DATA, tol = 1E-12)

	TestIVSCCAPFrequencyGraph4(wName + "4")
	TestIVSCCAPFrequencyGraph4(wName + "10")

	TestIVSCCAPFrequencyGraph5(wName + "5")
	TestIVSCCAPFrequencyGraph5(wName + "11")
End

static Function TestIVSCCAPFrequencyTagGroups()

	string abWin, code, sweepBrowsers, sweepBrowser, wName

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0, tagList = {"a", "b"})
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(on, none, none, 100, 100, prepareFit(log), bins2)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)
	wName = GetMainWindow(GetCurrentWindow())

	Make/FREE/T plot0 = {"T000000d0_a__Scn1a_R613X_B6_825669_02_09_02_nwb", "T000001d0_b__Scn1a_R613X_B6_825669_02_09_04_nwb"}
	Make/FREE/T plot1 = {"T000000d0_a__ivscc_apfrequency_concat", "T000001d0_b__ivscc_apfrequency_concat"}
	Make/FREE/T plot2 = {"T000000d0_a__ivscc_apfrequency_DAScale", "T000001d0_b__ivscc_apfrequency_DAScale"}
	Make/FREE/T plot3 = {"T000000d0_a__ivscc_apfrequency_Mean_Maximal_Firing_Point", "T000001d0_b__ivscc_apfrequency_Mean_Maximal_Firing_Point"}
	WAVE/Z plot4 = $""
	WAVE/Z plot5 = $""
	Make/FREE/WAVE traceNamesPlot = {plot0, plot1, plot2, plot3, plot4, plot5}

	CHECK_EQUAL_VAR(DimSize(traceNamesPlot, ROWS), 6) // see SF_IVSCC_APFREQUENCY_PLOTTYPE_ENUM_MAX

	TestIVSCCAPFrequencyCheckTraceNames(traceNamesPlot, wName)
End

static Function TestIVSCCAPFrequencySyncXAxis()

	string abWin, code, sweepBrowsers, sweepBrowser, wName, subWin
	variable i, numWins

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(on, none, none, 100, 100, prepareFit(log), bins2)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)
	wName = GetMainWindow(GetCurrentWindow())

	numWins = 6
	// check if all bottom axis have the same xAxis scale
	Make/FREE/D/N=(numWins) xMin, xMax
	for(i = 0; i < numWins; i += 1)
		subWin = wName + "#graph" + num2istr(i)
		GetAxis/W=$subWin/Q bottom
		xMin[i] = V_min
		xMax[i] = V_max
	endfor
	CHECK_EQUAL_VAR(IsConstant(xMin, xMin[0]), 1)
	CHECK_EQUAL_VAR(IsConstant(xMax, xMax[0]), 1)

	// check if all sync
	subWin = wName + "#graph0"
	SetAxis/W=$subWin/Z bottom, -1, 1

	// Just need to drop to the command line to trigger the hook functions
	CtrlNamedBackGround ivsccapfrequencytask, proc=TestIVSCCAPFrequencyWait, period=1, start
	RegisterIUTFMonitor("ivsccapfrequencytask", 1, "HistoricDataSweepFormula#TestIVSCCAPFrequencySyncXAxis_REENTRY")
End

Function TestIVSCCAPFrequencyWait(STRUCT WMBackgroundStruct &s)

	return 1
End

static Function TestIVSCCAPFrequencySyncXAxis_REENTRY()

	variable i, numWins
	string wName, subWin

	wName = GetMainWindow(GetCurrentWindow())

	numWins = 6
	Make/FREE/D/N=(numWins) xMin, xMax
	for(i = 0; i < numWins; i += 1)
		subWin = wName + "#graph" + num2istr(i)
		GetAxis/W=$subWin/Q bottom
		xMin[i] = V_min
		xMax[i] = V_max
	endfor
	CHECK_EQUAL_VAR(IsConstant(xMin, -1), 1)
	CHECK_EQUAL_VAR(IsConstant(xMax, 1), 1)
End

static Function TestIVSCCAPFrequencyAxisPercentage()

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName, info, subWin
	variable first, last, i, numSubWindows

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(on, none, none, 80, 60, prepareFit(log), bins, [100, 600], 80)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	wName         = GetMainWindow(GetCurrentWindow())
	numSubWindows = 6 // see SF_IVSCC_APFREQUENCY_PLOTTYPE_ENUM_MAX
	for(i = 0; i < numSubWindows; i += 1)

		subWin = wName + "#graph" + num2istr(i)

		info  = AxisInfo(subWin, "left")
		first = GetNumFromModifyStr(info, "axisEnab", "{", 0)
		last  = GetNumFromModifyStr(info, "axisEnab", "{", 1)
		CHECK_EQUAL_VAR(first, 0)
		CHECK_EQUAL_VAR(last, 0.6)

		info  = AxisInfo(subWin, "bottom")
		first = GetNumFromModifyStr(info, "axisEnab", "{", 0)
		last  = GetNumFromModifyStr(info, "axisEnab", "{", 1)
		CHECK_EQUAL_VAR(first, 0)
		CHECK_EQUAL_VAR(last, 0.8)
	endfor
End

// IUTF_TD_GENERATOR DataGenerators#IVSCCAPFrequencyOffsets
static Function TestIVSCCAPFrequencyAxisOffsetX([string str])

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName, subWin

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(on, " + str + ", none, 100, 100, prepareFit(), bins2)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	wName  = GetMainWindow(GetCurrentWindow())
	subWin = wName + "#graph0"

	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()
	WAVE/T    traceNames     = traceNamesPlot[0]

	WAVE xData = XWaveRefFromTrace(subWin, traceNames[0])
	TestIVSCCAPFrequencyCheckOffset(xData, refData[%xdata1], str)
	WAVE xData = XWaveRefFromTrace(subWin, traceNames[1])
	TestIVSCCAPFrequencyCheckOffset(xData, refData[%xdata2], str)
End

// IUTF_TD_GENERATOR DataGenerators#IVSCCAPFrequencyOffsets
static Function TestIVSCCAPFrequencyAxisOffsetY([string str])

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName, subWin

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(on, none, " + str + ", 100, 100, prepareFit(), bins2)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	wName  = GetMainWindow(GetCurrentWindow())
	subWin = wName + "#graph0"

	WAVE/WAVE refData        = GetRefData()
	WAVE/WAVE traceNamesPlot = TestIVSCCAPFrequencyBinsGetTraceNames()
	WAVE/T    traceNames     = traceNamesPlot[0]

	WAVE data = TraceNameToWaveRef(subWin, traceNames[0])
	TestIVSCCAPFrequencyCheckOffset(data, refData[%data1], str)
	WAVE data = TraceNameToWaveRef(subWin, traceNames[1])
	TestIVSCCAPFrequencyCheckOffset(data, refData[%data2], str)
End

static Function TestIVSCCAPFrequencyCheckOffset(WAVE data, WAVE dataRef, string mode)

	strswitch(mode)
		case "first":
			Duplicate/FREE dataRef, dataRef1
			dataRef1[] -= dataRef[0]
			break
		case "none":
			WAVE dataRef1 = dataRef
			break
		case "min":
			Duplicate/FREE dataRef, dataRef1
			dataRef1[] -= WaveMin(dataRef)
			break
		case "max":
			Duplicate/FREE dataRef, dataRef1
			dataRef1[] -= WaveMax(dataRef)
			break
		default:
			// unchecked offset mode
			FAIL()
			break
	endswitch

	CHECK_EQUAL_WAVES(data, dataRef1, mode = WAVE_DATA)
End

static Function TestIVSCCAPFrequencyWorks()

	string abWin, code, sweepBrowsers, sweepBrowser

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	// with optional apfrequency argument set
	code = "ivscc_apfrequency(on, none, none, 100, 100, prepareFit(log), bins, [100, 600], 80, 0, 0, time, nonorm, time)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code)
	code = "ivscc_apfrequency(on, none, none, 100, 100, prepareFit(log), bins2, 0, 0, time, nonorm, time)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code)
End

static Function TestIVSCCAPFrequencyFails()

	string abWin, code, sweepBrowsers, sweepBrowser

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1, multipleSweepBrowser = 0)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(fail, on, fail, none, 100, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(fail, none, none, 100, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), fail, none, none, 100, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), on, fail, none, 100, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), on, none, fail, 100, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), on, none, none, -1, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(seltag(a), on, none, none, 200, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, -1, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 200, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 100, prepareFit(log), fail, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 100, prepareFit(log), bins, 37, 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 100, prepareFit(log), bins, [a, b], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 100, prepareFit(log), bins, [NaN, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 100, prepareFit(log), bins, [100, NaN], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 100, prepareFit(log), bins, [100, 600], -1)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 100, prepareFit(log), bins, [100, 600], NaN)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 100, 0, bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(seltag(a), on, none, none, 100, 100, 0, bins2, 3)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
End
