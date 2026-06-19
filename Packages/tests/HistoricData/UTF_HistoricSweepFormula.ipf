#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HistoricDataSweepFormula

static Function/WAVE GetRefData()

	// number of peaks from apfrequency with default settings
	Make/FREE/D dataRef1 = {0, 1, 20, 46, 55, 64, 1, 89, 2, 2, 116, 141, 74}
	// max output current in sweeps DA channel
	Make/FREE/D xDataRef1 = {36, 38, 68, 88, 108, 128, 54, 182, 61, 64, 255, 374, 531}
	Make/FREE/D dataRef2 = {0, 5, 27, 58, 87, 109, 18, 132, 2, 175, 228, 275, 309}
	Make/FREE/D xDataRef2 = {130, 140, 170, 190, 210, 230, 155, 268, 147, 351, 479, 655, 867}
	Make/FREE/D avgDataRef = {0, 3, 1.5, 10, 14.5, 39, 66.5, 82, 98, 132, 172, 208, 191.5}
	Make/FREE/D xAvgDataRef = {83, 89, 100.5, 108, 117, 129, 149, 169, 198, 266.5, 367, 514.5, 699}
	Make/FREE/D fitDataRef = {NaN, -9.135609134854235, 6.792363194700215, 16.08563201991842, 26.47829761181345, 38.93664859188129, 57.44915335628912, 73.717024577703, 94.1953994857563, 132.5657870085096, 173.8614384346001, 217.4785790971106, NaN}
	Make/FREE/D fitxDataRef = {NaN, 88.87793321106729, 100.554524599647, 108.0635739861901, 117.1270485575746, 128.9993157257618, 148.8996436554057, 168.9060878165089, 197.9556707914339, 266.5069237449363, 367.0239482427364, 514.6282046677733, NaN}

	Make/FREE/D dascaleYRef = {141, 5}
	Make/FREE/D dascaleXRef = {374, 140}

	Make/FREE/D dascaleAvgYRef = {73}
	Make/FREE/D dascaleAvgXRef = {257}

	Make/FREE/D avgDataBinsRef = {34.95, 93.58333333333334, 132, 158, 228, 74, NaN}
	Make/FREE/D xAvgDataBinsRef = {133.2, 214.25, 268, 362.5, 479, 531, NaN}
	Make/FREE/D fitDataBinsRef = {29.29539771006682, 98.07740075839308, 130.470972508963, 174.1804239356826, 214.5091272186255, NaN, NaN}

	Make/FREE/WAVE wv = {dataRef1, xDataRef1, dataRef2, xDataRef2, dascaleYRef, dascaleXRef, dascaleAvgYRef, dascaleAvgXRef, avgDataRef, xAvgDataRef, fitDataRef, fitxDataRef, avgDataBinsRef, xAvgDataBinsRef, fitDataBinsRef}
	SetDimensionLabels(wv, "data1;xdata1;data2;xdata2;dascaleY;dascaleX;dascaleAvgY;dascaleAvgX;avgdata;avgxdata;fitdata;fitxdata;avgbinsdata;xavgbinsdata;fitbinsdata;", ROWS)

	for(data : wv)
		Redimension/N=(-1, 1) data // from SF_PrepareResultWavesForPlotting
	endfor

	return wv
End

static Function TestIVSCCAPFrequencyBins()

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log, 0, standard), bins, [100, 600], 80)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	wName = GetCurrentWindow()

	WAVE/T traceList = ListToTextWave(TraceNameList(wName, ";", 0x01), ";")
	// last trace is frontmost, which should be avg
	CHECK_EQUAL_STR(traceList[Inf], "T000004d0_ivscc_apfrequency_avg_bins")
	Sort traceList, traceList
	Make/FREE/T wRef = {"T000000d0_Scn1a_R613X_B6_825669_02_09_02_nwb", "T000001d0_Scn1a_R613X_B6_825669_02_09_04_nwb", "T000002d0_ivscc_apfrequency_DAScale", "T000003d0_ivscc_apfrequency_DAScale_Avg", "T000004d0_ivscc_apfrequency_avg_bins", "T000005d0_ivscc_apfrequency_fit"}
	CHECK_EQUAL_WAVES(traceList, wRef, mode = WAVE_DATA)

	WAVE/WAVE refData = GetRefData()

	// check data
	WAVE data1 = TraceNameToWaveRef(wName, traceList[0])
	CHECK_EQUAL_WAVES(data1, refData[%data1], mode = WAVE_DATA)
	WAVE data2 = TraceNameToWaveRef(wName, traceList[1])
	CHECK_EQUAL_WAVES(data2, refData[%data2], mode = WAVE_DATA)
	WAVE xData1 = XWaveRefFromTrace(wName, traceList[0])
	CHECK_EQUAL_WAVES(xData1, refData[%xdata1], mode = WAVE_DATA)
	WAVE xData2 = XWaveRefFromTrace(wName, traceList[1])
	CHECK_EQUAL_WAVES(xData2, refData[%xdata2], mode = WAVE_DATA)

	WAVE dascaleDataY = TraceNameToWaveRef(wName, traceList[2])
	WAVE dascaleDataX = XWaveRefFromTrace(wName, traceList[2])
	CHECK_EQUAL_WAVES(dascaleDataY, refData[%dascaleY], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(dascaleDataX, refData[%dascaleX], mode = WAVE_DATA)

	WAVE dascaleAvgDataY = TraceNameToWaveRef(wName, traceList[3])
	WAVE dascaleAvgDataX = XWaveRefFromTrace(wName, traceList[3])
	CHECK_EQUAL_WAVES(dascaleAvgDataY, refData[%dascaleAvgY], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(dascaleAvgDataX, refData[%dascaleAvgX], mode = WAVE_DATA)

	WAVE avgData  = TraceNameToWaveRef(wName, traceList[4])
	WAVE xAvgData = XWaveRefFromTrace(wName, traceList[4])
	CHECK_EQUAL_WAVES(avgData, refData[%avgbinsdata], mode = WAVE_DATA, tol = 1E-12)
	CHECK_EQUAL_WAVES(xAvgData, refData[%xavgbinsdata], mode = WAVE_DATA, tol = 1E-12)

	WAVE fitData = TraceNameToWaveRef(wName, traceList[5])
	CHECK_EQUAL_WAVES(fitData, refData[%fitbinsdata], mode = WAVE_DATA, tol = 1E-12)
	WAVE xFitData = XWaveRefFromTrace(wName, traceList[5])
	CHECK_EQUAL_WAVES(xFitData, refData[%xavgbinsdata], mode = WAVE_DATA, tol = 1E-12)
End

static Function TestIVSCCAPFrequencyBins2()

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName1, wName2

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code  = "ivscc_apfrequency(none, none, 100, 100, prepareFit(), bins2)\r"
	code += "and\r"
	code += "ivscc_apfrequency(none, none, 100, 100, prepareFit(log, 0, standard), bins2)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	wName2 = GetCurrentWindow()
	wName1 = StringFromList(0, wName2, "#") + "#graph0"

	WAVE/T traceList1 = ListToTextWave(TraceNameList(wName1, ";", 0x01), ";")
	Sort traceList1, traceList1
	Make/FREE/T wRef = {"T000000d0_Scn1a_R613X_B6_825669_02_09_02_nwb", "T000001d0_Scn1a_R613X_B6_825669_02_09_04_nwb", "T000002d0_ivscc_apfrequency_DAScale", "T000003d0_ivscc_apfrequency_DAScale_Avg", "T000004d0_ivscc_apfrequency_avg_bins2"}
	CHECK_EQUAL_WAVES(traceList1, wRef, mode = WAVE_DATA)
	WAVE/T traceList2 = ListToTextWave(TraceNameList(wName2, ";", 0x01), ";")
	// last trace is frontmost, which should be avg
	CHECK_EQUAL_STR(traceList2[Inf], "T000004d0_ivscc_apfrequency_avg_bins2")
	Sort traceList2, traceList2
	Make/FREE/T wRef = {"T000000d0_Scn1a_R613X_B6_825669_02_09_02_nwb", "T000001d0_Scn1a_R613X_B6_825669_02_09_04_nwb", "T000002d0_ivscc_apfrequency_DAScale", "T000003d0_ivscc_apfrequency_DAScale_Avg", "T000004d0_ivscc_apfrequency_avg_bins2", "T000005d0_ivscc_apfrequency_fit"}
	CHECK_EQUAL_WAVES(traceList2, wRef, mode = WAVE_DATA)

	WAVE/WAVE refData = GetRefData()

	// check data
	WAVE data1 = TraceNameToWaveRef(wName1, traceList1[0])
	CHECK_EQUAL_WAVES(data1, refData[%data1], mode = WAVE_DATA)

	WAVE data2 = TraceNameToWaveRef(wName1, traceList1[1])
	CHECK_EQUAL_WAVES(data2, refData[%data2], mode = WAVE_DATA)

	WAVE data1 = TraceNameToWaveRef(wName2, traceList2[0])
	CHECK_EQUAL_WAVES(data1, refData[%data1], mode = WAVE_DATA)
	WAVE data2 = TraceNameToWaveRef(wName2, traceList2[1])
	CHECK_EQUAL_WAVES(data2, refData[%data2], mode = WAVE_DATA)

	WAVE xData1 = XWaveRefFromTrace(wName1, traceList1[0])
	CHECK_EQUAL_WAVES(xData1, refData[%xdata1], mode = WAVE_DATA)

	WAVE xData2 = XWaveRefFromTrace(wName1, traceList1[1])
	CHECK_EQUAL_WAVES(xData2, refData[%xdata2], mode = WAVE_DATA)

	WAVE xData1 = XWaveRefFromTrace(wName2, traceList2[0])
	CHECK_EQUAL_WAVES(xData1, refData[%xdata1], mode = WAVE_DATA)
	WAVE xData2 = XWaveRefFromTrace(wName2, traceList2[1])
	CHECK_EQUAL_WAVES(xData2, refData[%xdata2], mode = WAVE_DATA)

	WAVE dascaleDataY = TraceNameToWaveRef(wName1, traceList1[2])
	WAVE dascaleDataX = XWaveRefFromTrace(wName1, traceList1[2])
	CHECK_EQUAL_WAVES(dascaleDataY, refData[%dascaleY], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(dascaleDataX, refData[%dascaleX], mode = WAVE_DATA)
	WAVE dascaleAvgDataY = TraceNameToWaveRef(wName1, traceList1[3])
	WAVE dascaleAvgDataX = XWaveRefFromTrace(wName1, traceList1[3])
	CHECK_EQUAL_WAVES(dascaleAvgDataY, refData[%dascaleAvgY], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(dascaleAvgDataX, refData[%dascaleAvgX], mode = WAVE_DATA)

	WAVE dascaleDataY = TraceNameToWaveRef(wName2, traceList2[2])
	WAVE dascaleDataX = XWaveRefFromTrace(wName2, traceList2[2])
	CHECK_EQUAL_WAVES(dascaleDataY, refData[%dascaleY], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(dascaleDataX, refData[%dascaleX], mode = WAVE_DATA)
	WAVE dascaleAvgDataY = TraceNameToWaveRef(wName2, traceList2[3])
	WAVE dascaleAvgDataX = XWaveRefFromTrace(wName2, traceList2[3])
	CHECK_EQUAL_WAVES(dascaleAvgDataY, refData[%dascaleAvgY], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(dascaleAvgDataX, refData[%dascaleAvgX], mode = WAVE_DATA)

	WAVE avgData  = TraceNameToWaveRef(wName1, traceList1[4])
	WAVE xAvgData = XWaveRefFromTrace(wName1, traceList1[4])
	CHECK_EQUAL_WAVES(avgData, refData[%avgdata], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(xAvgData, refData[%avgxdata], mode = WAVE_DATA)
	WAVE avgData  = TraceNameToWaveRef(wName2, traceList2[4])
	WAVE xAvgData = XWaveRefFromTrace(wName2, traceList2[4])
	CHECK_EQUAL_WAVES(avgData, refData[%avgdata], mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(xAvgData, refData[%avgxdata], mode = WAVE_DATA)

	WAVE fitData = TraceNameToWaveRef(wName2, traceList2[5])
	CHECK_EQUAL_WAVES(fitData, refData[%fitdata], mode = WAVE_DATA, tol = 1E-12)
	WAVE xFitData = XWaveRefFromTrace(wName2, traceList2[5])
	CHECK_EQUAL_WAVES(xFitData, refData[%fitxdata], mode = WAVE_DATA, tol = 1E-12)
End

static Function TestIVSCCAPFrequencyAxisPercentage()

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName, info
	variable first, last

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(none, none, 80, 60, prepareFit(log), bins, [100, 600], 80)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	wName = GetCurrentWindow()

	info  = AxisInfo(wName, "left")
	first = GetNumFromModifyStr(info, "axisEnab", "{", 0)
	last  = GetNumFromModifyStr(info, "axisEnab", "{", 1)
	CHECK_EQUAL_VAR(first, 0)
	CHECK_EQUAL_VAR(last, 0.6)

	info  = AxisInfo(wName, "bottom")
	first = GetNumFromModifyStr(info, "axisEnab", "{", 0)
	last  = GetNumFromModifyStr(info, "axisEnab", "{", 1)
	CHECK_EQUAL_VAR(first, 0)
	CHECK_EQUAL_VAR(last, 0.8)
End

// IUTF_TD_GENERATOR DataGenerators#IVSCCAPFrequencyOffsets
static Function TestIVSCCAPFrequencyAxisOffsetX([string str])

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(" + str + ", none, 100, 100, prepareFit(), bins2)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	wName = GetCurrentWindow()
	WAVE/T traceList = ListToTextWave(TraceNameList(wName, ";", 0x01), ";")
	Sort traceList, traceList

	WAVE/WAVE refData = GetRefData()

	WAVE xData = XWaveRefFromTrace(wName, traceList[0])
	TestIVSCCAPFrequencyCheckOffset(xData, refData[%xdata1], str)
	WAVE xData = XWaveRefFromTrace(wName, traceList[1])
	TestIVSCCAPFrequencyCheckOffset(xData, refData[%xdata2], str)
End

// IUTF_TD_GENERATOR DataGenerators#IVSCCAPFrequencyOffsets
static Function TestIVSCCAPFrequencyAxisOffsetY([string str])

	string abWin, code, sweepBrowsers, sweepBrowser
	string wName

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(none, " + str + ", 100, 100, prepareFit(), bins2)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)

	wName = GetCurrentWindow()
	WAVE/T traceList = ListToTextWave(TraceNameList(wName, ";", 0x01), ";")
	Sort traceList, traceList

	WAVE/WAVE refData = GetRefData()

	WAVE data = TraceNameToWaveRef(wName, traceList[0])
	TestIVSCCAPFrequencyCheckOffset(data, refData[%data1], str)
	WAVE data = TraceNameToWaveRef(wName, traceList[1])
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

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	// with optional apfrequency argument set
	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), bins, [100, 600], 80, 0, 0, time, nonorm, time)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code)
	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), bins2, 0, 0, time, nonorm, time)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code)
End

static Function TestIVSCCAPFrequencyFails()

	string abWin, code, sweepBrowsers, sweepBrowser

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code = "ivscc_apfrequency(fail, none, 100, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(none, fail, 100, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(none, none, -1, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(none, none, 200, 100, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(none, none, 100, -1, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(none, none, 100, 200, prepareFit(log), bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), fail, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), bins, 37, 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), bins, [a, b], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), bins, [NaN, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), bins, [100, NaN], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), bins, [100, 600], -1)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
	code = "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), bins, [100, 600], NaN)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)

	code = "ivscc_apfrequency(none, none, 100, 100, 0, bins, [100, 600], 80)\r"
	ExecuteSweepFormulaCode(sweepBrowser, code, expectFailure = 1)
End
