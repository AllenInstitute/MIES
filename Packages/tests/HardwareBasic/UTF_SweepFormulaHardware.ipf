#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=SweepFormulaHardware

// Check the root datafolder for waves which might be present and could help debugging

// Tests for SweepFormula that require hardware
//
// SF_TPTest
// - tests operation tp with two headstages with different ADC/DAC channels and three sweeps acquired
// - the result of tp is checked for correct layout/units and values based on the DA channel, as the DA "input" data is well known
//   (AD depends on test setup)

static Constant SF_TEST_VC_HEADSTAGE = 2
static Constant SF_TEST_IC_HEADSTAGE = 3

/// @brief Acquire data with the given DAQSettings on two headstages
static Function AcquireData(s, devices, stimSetName1, stimSetName2[, dDAQ, oodDAQ, onsetDelayUser, terminationDelay, analysisFunction, postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string devices
	string stimSetName1, stimSetName2, analysisFunction
	variable dDAQ, oodDAQ, onsetDelayUser, terminationDelay
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	string unlockedDevice, device
	variable i, numEntries

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(devices)
	endif

	dDAQ = ParamIsDefault(dDAQ) ? 0 : !!dDAQ
	oodDAQ = ParamIsDefault(oodDAQ) ? 0 : !!oodDAQ
	analysisFunction = SelectString(ParamIsDefault(analysisFunction), analysisFunction, "")

	EnsureMCCIsOpen()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, devices)

		unlockedDevice = DAP_CreateDAEphysPanel()

		PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=device)
		PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")

		REQUIRE(WindowExists(device))

		// Clear HS association
		PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 0)
		PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")
		PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 1)
		PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

		// Setup first HS
		PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = SF_TEST_VC_HEADSTAGE)
		PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1)
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, SF_TEST_VC_HEADSTAGE), val=1)
		DoUpdate/W=$device
		PGC_SetAndActivateControl(device, "Popup_Settings_VC_DA", str = "0")
		PGC_SetAndActivateControl(device, "Popup_Settings_IC_DA", str = "0")
		PGC_SetAndActivateControl(device, "Popup_Settings_VC_AD", str = "1")
		PGC_SetAndActivateControl(device, "Popup_Settings_IC_AD", str = "1")

		// Setup second HS
		PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = SF_TEST_IC_HEADSTAGE)
		PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 2)
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, SF_TEST_VC_HEADSTAGE), val=1)
		DoUpdate/W=$device
		PGC_SetAndActivateControl(device, "Popup_Settings_VC_DA", str = "1")
		PGC_SetAndActivateControl(device, "Popup_Settings_IC_DA", str = "1")
		PGC_SetAndActivateControl(device, "Popup_Settings_VC_AD", str = "2")
		PGC_SetAndActivateControl(device, "Popup_Settings_IC_AD", str = "2")

		PGC_SetAndActivateControl(device, GetPanelControl(SF_TEST_VC_HEADSTAGE, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1, switchTab = 1)
		PGC_SetAndActivateControl(device, GetPanelControl(SF_TEST_IC_HEADSTAGE, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)

		PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimSetName1)
		PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimSetName2)

		PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)

		PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")

		PGC_SetAndActivateControl(device, "check_Settings_MD", val = s.MD)
		PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = s.RA)
		PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = s.IDX)
		PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = s.LIDX)

		if(!s.MD)
			PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
		else
			CHECK_EQUAL_VAR(s.BKG_DAQ, 1)
		endif

		PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = s.RES)

		PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = dDAQ)
		PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = oodDAQ)

		PGC_SetAndActivateControl(device, "setvar_DataAcq_OnsetDelayUser", val = onsetDelayUser)
		PGC_SetAndActivateControl(device, "setvar_DataAcq_TerminationDelay", val = terminationDelay)

		PASS()
	endfor

	if(!IsEmpty(analysisFunction))
		ST_SetStimsetParameter(stimsetName1, "Analysis function (Generic)", str = analysisFunction)
		ST_SetStimsetParameter(stimsetName2, "Analysis function (Generic)", str = analysisFunction)
	endif

	device = devices

#ifdef TESTS_WITH_YOKING
	PGC_SetAndActivateControl(device, "button_Hardware_Lead1600")
	PGC_SetAndActivateControl(device, "popup_Hardware_AvailITC1600s", val=0)
	PGC_SetAndActivateControl(device, "button_Hardware_AddFollower")

	ARDLaunchSeqPanel()
	PGC_SetAndActivateControl("ArduinoSeq_Panel", "SendSequenceButton")
#endif

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc(device)
	endif

	PGC_SetAndActivateControl(device, "DataAcquireButton")
End

static Function/WAVE GetMultipleResults(string formula, string win)

	WAVE wTextRef = SF_FormulaExecutor(win, DirectToFormulaParser(formula))
	CHECK(IsTextWave(wTextRef))
	CHECK_EQUAL_VAR(DimSize(wTextRef, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(wTextRef, COLS), 0)
	return MIES_SF#SF_ParseArgument(win, wTextRef, "TestRun")
End

static Function/WAVE GetSingleResult(string formula, string win)

	WAVE/WAVE wRefResult = GetMultipleResults(formula, win)
	CHECK_EQUAL_VAR(DimSize(wRefResult, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(wRefResult, COLS), 0)

	return wRefResult[0]
End

static Function	TestSweepFormulaButtons(string device)

	string graph, dbPanel, sfPanel, jsonStr, win
	string refStr

	graph = DB_OpenDataBrowser()
	dbPanel = BSP_GetPanel(graph)
	PGC_SetAndActivateControl(dbPanel, "check_BrowserSettings_SF", val = 1)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_check")
	sfPanel = BSP_GetSFJSON(graph)
	jsonStr = GetNotebookText(sfPanel, mode=2)
	try
		JSON_Parse(jsonStr, ignoreErr=0)
		PASS()
	catch
		FAIL()
	endtry

	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display")

	refStr = MIES_SF#SF_GetFormulaWinNameTemplate(graph)
	DoWindow/B $refStr
	refStr = refStr + "#" + refStr + "0" // graph in panel with counter
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_tofront")
	win = GetCurrentWindow()
	CHECK_EQUAL_STR(refStr, win)
End

static Function TestSweepFormulaNoDataPlotted(string device)

	string plotWin, dbPanel, formula

	[dbPanel, plotWin] = GetNewDBforSF_IGNORE()

	formula = "data(cursors(A,B),select(channels(AD10),sweeps(),all))"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)
	PASS()
End

static Function	TestSweepFormulaAnnotations(string device)

	string plotWin, dbPanel, formula,annoInfo
	string str, strRef, typeRef, flagsRef, textRef

	[dbPanel, plotWin] = GetNewDBforSF_IGNORE()

	formula = "data(cursors(A,B),select(channels(AD),sweeps(),all))"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)
	annoInfo = AnnotationInfo(plotWin, "metadata", 1)
	typeRef = "Legend"
	flagsRef = "/N=metadata/J/I=0/V=1/D=1/LS=0/O=0/F=2/S=0/H=0/Q/Z=0/G=(0,0,0)/B=(65535,65535,65535)/T=36/A=RT/X=5.00/Y=5.00"
	textRef = "\\s(T000000d0_Sweep_0_AD1) Sweep 0 AD1\r\\s(T000001d1_Sweep_0_AD2) Sweep 0 AD2\r\\s(T000002d2_Sweep_1_AD1) Sweep 1 AD1\r\\s(T000003d3_Sweep_1_AD2) Sweep 1 AD2\r\\s(T000004d4_Sweep_2_AD1) Sweep 2 AD1\r\\s(T000005d5_Sweep_2_AD2) Sweep 2 AD2"
	str = StringByKey("TYPE", annoInfo)
	CHECK_EQUAL_STR(typeRef, str)
	str = StringByKey("FLAGS", annoInfo)
	CHECK_EQUAL_STR(flagsRef, str)
	str = StringByKey("TEXT", annoInfo)
	CHECK_EQUAL_STR(textRef, str)

	formula = "avg(data(cursors(A,B),select(channels(AD),sweeps(),all)))"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)
	annoInfo = AnnotationInfo(plotWin, "metadata", 1)
	typeRef = "Legend"
	flagsRef = "/N=metadata/J/I=0/V=1/D=1/LS=0/O=0/F=2/S=0/H=0/Q/Z=0/G=(0,0,0)/B=(65535,65535,65535)/T=36/A=RT/X=5.00/Y=5.00"
	textRef = "\\s(T000000d0_avg_data_Sweep_0_AD1) avg data Sweep 0 AD1\r\\s(T000001d1_avg_data_Sweep_0_AD2) avg data Sweep 0 AD2\r\\s(T000002d2_avg_data_Sweep_1_AD1) avg data Sweep 1 AD1\r\\s(T000003d3_avg_data_Sweep_1_AD2) avg data Sweep 1 AD2\r\\s(T000004d4_avg_data_Sweep_2_AD1) avg data Sweep 2 AD1\r\\s(T000005d5_avg_data_Sweep_2_AD2) avg data Sweep 2 AD2"
	str = StringByKey("TYPE", annoInfo)
	CHECK_EQUAL_STR(typeRef, str)
	str = StringByKey("FLAGS", annoInfo)
	CHECK_EQUAL_STR(flagsRef, str)
	str = StringByKey("TEXT", annoInfo)
	CHECK_EQUAL_STR(textRef, str)

	formula = "avg(avg(data(cursors(A,B),select(channels(AD),sweeps(),all))))"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)
	annoInfo = AnnotationInfo(plotWin, "metadata", 1)
	typeRef = "Legend"
	flagsRef = "/N=metadata/J/I=0/V=1/D=1/LS=0/O=0/F=2/S=0/H=0/Q/Z=0/G=(0,0,0)/B=(65535,65535,65535)/T=36/A=RT/X=5.00/Y=5.00"
	textRef = "\\s(T000000d0_avg_avg_data_Sweep_0_AD1) avg avg data Sweep 0 AD1\r\\s(T000001d1_avg_avg_data_Sweep_0_AD2) avg avg data Sweep 0 AD2\r\\s(T000002d2_avg_avg_data_Sweep_1_AD1) avg avg data Sweep 1 AD1\r\\s(T000003d3_avg_avg_data_Sweep_1_AD2) avg avg data Sweep 1 AD2\r\\s(T000004d4_avg_avg_data_Sweep_2_AD1) avg avg data Sweep 2 AD1\r\\s(T000005d5_avg_avg_data_Sweep_2_AD2) avg avg data Sweep 2 AD2"
	str = StringByKey("TYPE", annoInfo)
	CHECK_EQUAL_STR(typeRef, str)
	str = StringByKey("FLAGS", annoInfo)
	CHECK_EQUAL_STR(flagsRef, str)
	str = StringByKey("TEXT", annoInfo)
	CHECK_EQUAL_STR(textRef, str)
End

static Function [string dbPanel, string plotWin] GetNewDBforSF_IGNORE()

	string graph, formula, formulaPanel, formulaSubwin

	graph = DB_OpenDataBrowser()
	dbPanel = BSP_GetPanel(graph)
	PGC_SetAndActivateControl(dbPanel, "check_BrowserSettings_SF", val = 1)
	formulaPanel = MIES_SF#SF_GetFormulaWinNameTemplate(dbPanel)
	formulaSubwin = MIES_SF#SF_GetFormulaWinNameTemplate(dbPanel) + num2istr(0)
	return [dbPanel, formulaPanel + "#" + formulaSubwin]
End

static Function	TestSweepFormulaAxisLabels(string device)

	string dbPanel, plotWin, formula, str, strRef

	[dbPanel, plotWin] = GetNewDBforSF_IGNORE()

	formula = "avg(data(cursors(A,B),select(channels(AD),sweeps(),all)))"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)

	// Test combine of different data unit in multiple data waves
	str = AxisLabel(plotWin, "left")
	strRef = "mV / pA"
	CHECK_EQUAL_STR(strRef, str)

	str = AxisLabel(plotWin, "bottom")
	strRef = "Sweeps"
	CHECK_EQUAL_STR(strRef, str)
End

static Function	TestSweepFormulaFittingXAxis(string device)

	string dbPanel, plotWin, formula, tInfo, wPath
	variable index

	[dbPanel, plotWin] = GetNewDBforSF_IGNORE()

	formula = "min(data(cursors(A,B),select(channels(AD),sweeps(),all)))\rvs\r1...7"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)

	WAVE/T traces = ListToTextWave(TraceNameList(plotWin, ";", 1), ";")
	Sort/A traces, traces
	CHECK_EQUAL_VAR(6, DimSize(traces, ROWS))
	index = 1
	for(trace : traces)
		WAVE wY = TraceNameToWaveRef(plotWin, trace)
		CHECK_EQUAL_VAR(1, numpnts(wY))
		tInfo = TraceInfo(plotWin, trace, 0)
		wPath = StringByKey("XWAVEDF", tInfo) + StringByKey("XWAVE", tInfo)
		WAVE wX = $wPath
		CHECK_EQUAL_VAR(1, numpnts(wX))
		CHECK_EQUAL_VAR(index, wx[0])
		index += 1
	endfor
End

static Function	TestSweepFormulaDefaultMetaDataInheritance(string device)

	string dbPanel, plotWin, formula, tInfo, wPath, strRef, str
	variable sweepNo

	[dbPanel, plotWin] = GetNewDBforSF_IGNORE()

	formula = "min(butterworth(integrate(derivative(data(cursors(A,B),select(channels(AD),sweeps(),all)))),4,100,4))"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)

	WAVE/T traces = ListToTextWave(TraceNameList(plotWin, ";", 1), ";")
	Sort/A traces, traces
	CHECK_EQUAL_VAR(6, DimSize(traces, ROWS))
	sweepNo = 0
	for(trace : traces)
		WAVE wY = TraceNameToWaveRef(plotWin, trace)
		CHECK_EQUAL_VAR(1, numpnts(wY))
		tInfo = TraceInfo(plotWin, trace, 0)
		wPath = StringByKey("XWAVEDF", tInfo) + StringByKey("XWAVE", tInfo)
		WAVE wX = $wPath
		CHECK_EQUAL_VAR(1, numpnts(wX))
		CHECK_EQUAL_VAR(trunc(sweepNo), wx[0])
		sweepNo += 0.5
	endfor

	str = AxisLabel(plotWin, "bottom")
	strRef = "Sweeps"
	CHECK_EQUAL_STR(strRef, str)
End

static Function TestSweepFormulaSelectClampMode(string device)

	string dbPanel, plotWin, formula, tInfo, wPath, strRef, str
	variable sweepNo

	[dbPanel, plotWin] = GetNewDBforSF_IGNORE()

	formula = "select(channels(AD),sweeps(),all,all)"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)
	WAVE/T traces = ListToTextWave(TraceNameList(plotWin, ";", 1), ";")
	Sort/A traces, traces
	CHECK_EQUAL_VAR(3, DimSize(traces, ROWS))
	WAVE wY = TraceNameToWaveRef(plotWin, traces[0])
	Make/FREE/N=(6, 3) dataRef
	dataRef[][0] = {0, 0, 1, 1, 2, 2}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {1, 2, 1, 2, 1, 2}
	CHECK_EQUAL_WAVES(dataRef, wY, mode = WAVE_DATA | DIMENSION_SIZES)

	formula = "select(channels(AD),sweeps(),all,ic)"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)
	WAVE/T traces = ListToTextWave(TraceNameList(plotWin, ";", 1), ";")
	Sort/A traces, traces
	CHECK_EQUAL_VAR(3, DimSize(traces, ROWS))
	WAVE wY = TraceNameToWaveRef(plotWin, traces[0])
	Make/FREE/N=(3, 3) dataRef
	dataRef[][0] = {0, 1, 2}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {1, 1, 1}
	CHECK_EQUAL_WAVES(dataRef, wY, mode = WAVE_DATA | DIMENSION_SIZES)

	formula = "select(channels(AD),sweeps(),all,vc)"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)
	WAVE/T traces = ListToTextWave(TraceNameList(plotWin, ";", 1), ";")
	Sort/A traces, traces
	CHECK_EQUAL_VAR(3, DimSize(traces, ROWS))
	WAVE wY = TraceNameToWaveRef(plotWin, traces[0])
	Make/FREE/N=(3, 3) dataRef
	dataRef[][0] = {0, 1, 2}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {2, 2, 2}
	CHECK_EQUAL_WAVES(dataRef, wY, mode = WAVE_DATA | DIMENSION_SIZES)

	formula = "select(channels(AD),sweeps(),all,izero)"
	SF_SetFormula(dbPanel, formula)
	PGC_SetAndActivateControl(dbPanel, "button_sweepFormula_display", val = 1)
	WAVE/T traces = ListToTextWave(TraceNameList(plotWin, ";", 1), ";")
	CHECK_EQUAL_VAR(0, DimSize(traces, ROWS))
End

static Function	TestSweepFormulaTP(string device)

	string graph, dbPanel
	string formula, dataType, strRef
	variable i, sweep, chanNr, chanType

	graph = DB_OpenDataBrowser()
	dbPanel = BSP_GetPanel(graph)
	PGC_SetAndActivateControl(dbPanel, "check_BrowserSettings_OVS", val = 1)
	PGC_SetAndActivateControl(dbPanel, "popup_overlaySweeps_select", str = "All")

	// invalid number of args
	formula = "tp()"
	try
		WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
		FAIL()
	catch
		PASS()
	endtry

	// invalid mode
	formula = "tp(unknown_mode, select(channels(AD), sweeps()))"
	try
		WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
		FAIL()
	catch
		PASS()
	endtry

	// unknown channel name
	formula = "tp(ss, select(channels(unknown), sweeps()))"
	try
		WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
		FAIL()
	catch
		PASS()
	endtry

	// invalid argument for ignored TPs
	formula = "tp(ss, select(channels(AD), sweeps()), INVALID)"
	try
		WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
		FAIL()
	catch
		PASS()
	endtry

	// invalid argument for ignored TPs
	formula = "tp(ss, select(channels(AD), sweeps()), [inf])"
	try
		WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
		FAIL()
	catch
		PASS()
	endtry

	// invalid argument for ignored TPs
	formula = "tp(ss, select(channels(AD), sweeps()), 1)"
	try
		WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
		FAIL()
	catch
		PASS()
	endtry

	// sweep does not exist -> zero results
	formula = "tp(ss, select(channels(AD), 3))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	CHECK_EQUAL_VAR(DimSize(tpResult, ROWS), 0)

	// we setup only one TP per sweep, but we ignore TP 0 here, so we have zero results
	formula = "tp(ss, select(channels(AD), sweeps()), 0)"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	CHECK_EQUAL_VAR(DimSize(tpResult, ROWS), 0)

	// expect for 3 sweeps displayed with 2 AD channels each, 6 results
	formula = "tp(ss, select(channels(AD), sweeps()))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	CHECK_EQUAL_VAR(DimSize(tpResult, ROWS), 6)

	// same with shortened select()
	formula = "tp(ss, select())"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	CHECK_EQUAL_VAR(DimSize(tpResult, ROWS), 6)

	// same with omitted select()
	formula = "tp(ss)"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	CHECK_EQUAL_VAR(DimSize(tpResult, ROWS), 6)

	Make/FREE/D wRef = {1000}
	SetScale d, 0, 0, "MΩ", wRef
	PGC_SetAndActivateControl(dbPanel, "check_BrowserSettings_DAC", val=1)
	// Use DA channel for test calculation as it is well defined

	// Test static state resistance and instantaneous resistance that should be the same here (1000)
	// as string and numeric parameter
	formula = "tp(ss, select(channels(DA), sweeps()))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	for(data : tpResult)
		CHECK_EQUAL_WAVES(wRef, data, tol = 1e-12, mode = ~WAVE_NOTE)
	endfor

	formula = "tp(inst, select(channels(DA), sweeps()))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	for(data : tpResult)
		CHECK_EQUAL_WAVES(wRef, data, tol = 1e-12, mode = ~WAVE_NOTE)
	endfor

	formula = "tp(1, select(channels(DA), sweeps()))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	for(data : tpResult)
		CHECK_EQUAL_WAVES(wRef, data, tol = 1e-12, mode = ~WAVE_NOTE)
	endfor

	formula = "tp(2, select(channels(DA), sweeps()))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	for(data : tpResult)
		CHECK_EQUAL_WAVES(wRef, data, tol = 1e-12, mode = ~WAVE_NOTE)
	endfor

	// Test base line
	wRef = 0
	Make/FREE/T units = {"pA", "mV", "pA", "mV", "pA", "mV"}
	formula = "tp(base, select(channels(DA), sweeps()))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	i = 0
	for(data : tpResult)
		SetScale d, 0, 0, units[i], wRef
		CHECK_EQUAL_WAVES(wRef, data, tol = 1e-12, mode = ~WAVE_NOTE)
		i += 1
	endfor

	formula = "tp(0, select(channels(DA), sweeps()))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	i = 0
	for(data : tpResult)
		SetScale d, 0, 0, units[i], wRef
		CHECK_EQUAL_WAVES(wRef, data, tol = 1e-12, mode = ~WAVE_NOTE)
		i += 1
	endfor

	// Check also units for AD channel
	SetScale d, 0, 0, "mV", wRef
	formula = "tp(base, select(channels(AD1), 0))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	CHECK_EQUAL_VAR(DimSize(tpResult, ROWS), 1)
	WAVE data0 = tpResult[0]
	CHECK_EQUAL_WAVES(wRef, data0, mode= ~(WAVE_NOTE | WAVE_DATA))

	SetScale d, 0, 0, "pA", wRef
	formula = "tp(base, select(channels(AD2), 0))"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	CHECK_EQUAL_VAR(DimSize(tpResult, ROWS), 1)
	WAVE data0 = tpResult[0]
	CHECK_EQUAL_WAVES(wRef, data0, mode= ~(WAVE_NOTE | WAVE_DATA))

	// Check Meta Data
	formula = "tp(ss)"
	WAVE/WAVE tpResult = GetMultipleResults(formula, graph)
	dataType = JWN_GetStringFromWaveNote(tpResult, SF_META_DATATYPE)
	strRef = SF_DATATYPE_TP
	CHECK_EQUAL_STR(strRef, dataType)
	Make/FREE sweepNums = {0, 0, 0 ,0 ,1, 1, 1, 1, 2, 2, 2, 2}
	Make/FREE channelTypes = {0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1}
	Make/FREE channelNums = {1, 2, 0, 1, 1, 2, 0, 1, 1, 2, 0, 1}
	i = 0
	for(data : tpResult)
		sweep = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPNO)
		chanNr = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELNUMBER)
		chanType = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELTYPE)
		CHECK_EQUAL_VAR(sweepNums[i], sweep)
		CHECK_EQUAL_VAR(channelNums[i], chanNr)
		CHECK_EQUAL_VAR(channelTypes[i], chanType)
		i += 1
	endfor
End

static Function DirectToFormulaParser(string code)

	code = MIES_SF#SF_PreprocessInput(code)
	code = MIES_SF#SF_FormulaPreParser(code)
	return MIES_SF#SF_FormulaParser(code)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function SF_TPTest([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES3")
	AcquireData(s, str, "EpochTest0_DA_0", "EpochTest0_DA_0")
End

static Function SF_TPTest_REENTRY([str])
	string str

	TestSweepFormulaTP(str)
	TestSweepFormulaAnnotations(str)
	TestSweepFormulaAxisLabels(str)
	TestSweepFormulaFittingXAxis(str)
	TestSweepFormulaDefaultMetaDataInheritance(str)
	TestSweepFormulaNoDataPlotted(str)
	TestSweepFormulaSelectClampMode(str)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function SF_ButtonTest([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES3")
	AcquireData(s, str, "EpochTest0_DA_0", "EpochTest0_DA_0")
End

static Function SF_ButtonTest_REENTRY([str])
	string str

	TestSweepFormulaButtons(str)
End

static Function TestSweepFormulaCodeResults_IGNORE(string device)

	PGC_SetAndActivateControl(device, GetPanelControl(SF_TEST_IC_HEADSTAGE, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=0)
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function TestSweepFormulaCodeResults([string str])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES1")
	AcquireData(s, str, "StimulusSetA_DA_0", "StimulusSetA_DA_0", analysisFunction = "SetSweepFormula", preAcquireFunc = TestSweepFormulaCodeResults_IGNORE)
End

static Function TestSweepFormulaCodeResults_REENTRY([string str])
	string content, contentRef, graph, trace, bsPanel

	WAVE/T textualResultsValues = GetTextualResultsValues()

	WAVE/Z indizes = GetNonEmptyLBNRows(textualResultsValues, "Sweep Formula code")
	CHECK_WAVE(indizes, NUMERIC_WAVE)

	Make/FREE/T/N=(DimSize(indizes, ROWS)) code = textualResultsValues[indizes[p]][%$"Sweep Formula code"][INDEP_HEADSTAGE]

	Make/FREE/T/N=(3) ref = {"data(TP, select(channels(AD), [0]))", "data(TP, select(channels(AD), [1]))", "data(TP, select(channels(AD), [2]))"}
	CHECK_EQUAL_TEXTWAVES(ref, code, mode = WAVE_DATA)

	// set cursors and execute formula again
	graph = DB_FindDataBrowser(str)
	trace = StringFromList(0, TraceNameList(graph, ";", 1))
	Cursor/W=$graph A $trace 0
	Cursor/W=$graph J $trace 50

	bsPanel = BSP_GetPanel(graph)
	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")

	// check other entries of last invocation
	CHECK_EQUAL_VAR(DimSize(textualResultsValues, COLS), 19)

	content    = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula sweeps/channels", UNKNOWN_MODE)
	contentRef = "2;0;1;,"
	CHECK_EQUAL_STR(content, contentRef)

	content    = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula experiment", UNKNOWN_MODE)
	contentRef = NONE
	CHECK_EQUAL_STR(content, contentRef)

	content    = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula device", UNKNOWN_MODE)
	contentRef = NONE
	CHECK_EQUAL_STR(content, contentRef)

	// cursors A-J
	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor A", UNKNOWN_MODE)
	CHECK_PROPER_STR(content)

	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor B", UNKNOWN_MODE)
	CHECK_EMPTY_STR(content)

	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor C", UNKNOWN_MODE)
	CHECK_EMPTY_STR(content)

	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor D", UNKNOWN_MODE)
	CHECK_EMPTY_STR(content)

	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor E", UNKNOWN_MODE)
	CHECK_EMPTY_STR(content)

	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor F", UNKNOWN_MODE)
	CHECK_EMPTY_STR(content)

	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor G", UNKNOWN_MODE)
	CHECK_EMPTY_STR(content)

	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor H", UNKNOWN_MODE)
	CHECK_EMPTY_STR(content)

	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor I", UNKNOWN_MODE)
	CHECK_EMPTY_STR(content)

	content = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula cursor J", UNKNOWN_MODE)
	CHECK_PROPER_STR(content)
End

Function SF_InsertedTPVersusTP_IGNORE(string device)

	ST_SetStimsetParameter("PSQ_QC_Stimsets_DA_0", "Analysis function (generic)", str = "AddUserEpochsForTPLike")
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "PSQ_QC_Stimsets_DA_0")
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "PSQ_QC_Stimsets_DA_0")

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 10)

	// HS0: IC
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 0), val=CHECKBOX_SELECTED)

	// HS1: VC
	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(V_CLAMP_MODE, 1), val=CHECKBOX_SELECTED)

	// make IC less noisy
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val=-150)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StartAcq_IGNORE
End

// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
static Function SF_InsertedTPVersusTP([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES0")
	AcquireData_BHT(s, str, preAcquireFunc = SF_InsertedTPVersusTP_IGNORE, startTPinstead = 1)
End

static Function SF_InsertedTPVersusTP_REENTRY([str])
	string str

	string graph, formula
	variable index

	graph = DB_OpenDataBrowser()

	// check that the inserted TP is roughly the same as the other TPs in the stimset

	// HS0
	formula = "tp(ss, select(channels(AD0), sweeps()), [1, 2, 3])"
	WAVE steadyStateInsertedHS0 = GetSingleResult(formula, graph)

	CHECK_WAVE(steadyStateInsertedHS0, NUMERIC_WAVE)

	formula = "tp(inst, select(channels(AD0), sweeps()), [1, 2, 3])"
	WAVE instInsertedHS0 = GetSingleResult(formula, graph)
	CHECK_WAVE(instInsertedHS0, NUMERIC_WAVE)

	formula = "tp(ss, select(channels(AD0), sweeps()), [0])"
	WAVE steadyStateOthersHS0 = GetSingleResult(formula, graph)
	CHECK_WAVE(steadyStateOthersHS0, NUMERIC_WAVE)

	formula = "tp(inst, select(channels(AD0), sweeps()), [0])"
	WAVE instOthersHS0 = GetSingleResult(formula, graph)
	CHECK_WAVE(instOthersHS0, NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(steadyStateInsertedHS0, steadyStateOthersHS0, mode = WAVE_DATA, tol = 50^2)
	CHECK_EQUAL_WAVES(instInsertedHS0, instOthersHS0, mode = WAVE_DATA,tol = 50^2)

	// HS1
	formula = "tp(ss, select(channels(AD1), sweeps()), [1, 2, 3])"
	WAVE steadyStateInsertedHS1 = GetSingleResult(formula, graph)
	CHECK_WAVE(steadyStateInsertedHS1, NUMERIC_WAVE)

	formula = "tp(inst, select(channels(AD1), sweeps()), [1, 2, 3])"
	WAVE instInsertedHS1 = GetSingleResult(formula, graph)
	CHECK_WAVE(instInsertedHS1, NUMERIC_WAVE)

	formula = "tp(ss, select(channels(AD1), sweeps()), [0])"
	WAVE steadyStateOthersHS1 = GetSingleResult(formula, graph)
	CHECK_WAVE(steadyStateOthersHS1, NUMERIC_WAVE)

	formula = "tp(inst, select(channels(AD1), sweeps()), [0])"
	WAVE instOthersHS1 = GetSingleResult(formula, graph)
	CHECK_WAVE(instOthersHS1, NUMERIC_WAVE)

	CHECK_EQUAL_WAVES(steadyStateInsertedHS1, steadyStateOthersHS1, mode = WAVE_DATA, tol = 0.1)
	CHECK_EQUAL_WAVES(instInsertedHS1, instOthersHS1, mode = WAVE_DATA, tol = 0.1)

	// `tp` gives the same results as TP from TPStorage

	WAVE TPStorage = GetTPstorage(str)
	index = GetNumberFromWaveNote(TPstorage, NOTE_INDEX)
	CHECK_GT_VAR(index, 0)

	Duplicate/FREE/RMD=[0, index - 1][0][FindDimlabel(TPStorage, LAYERS, "PeakResistance")] TPStorage, instTPStorageLayer_HS0
	Duplicate/FREE/RMD=[0, index - 1][0][FindDimlabel(TPStorage, LAYERS, "SteadyStateResistance")] TPStorage, steadyStateTPStorageLayer_HS0

	Duplicate/FREE/RMD=[0, index - 1][1][FindDimlabel(TPStorage, LAYERS, "PeakResistance")] TPStorage, instTPStorageLayer_HS1
	Duplicate/FREE/RMD=[0, index - 1][1][FindDimlabel(TPStorage, LAYERS, "SteadyStateResistance")] TPStorage, steadyStateTPStorageLayer_HS1

	Redimension/N=(-1) instTPStorageLayer_HS0, steadyStateTPStorageLayer_HS0, steadyStateInsertedHS0, instInsertedHS0

	matrixOP/FREE instTPStorage_HS0 = mean(instTPStorageLayer_HS0)
	matrixOP/FREE steadyStateTPStorage_HS0 = mean(steadyStateTPStorageLayer_HS0)

	CHECK_EQUAL_WAVES(steadyStateInsertedHS0, SteadyStateTPStorage_HS0, mode = WAVE_DATA, tol = 0.1)
	CHECK_EQUAL_WAVES(instInsertedHS0, InstTPStorage_HS0, mode = WAVE_DATA, tol = 0.1)

	Redimension/N=(-1) instTPStorageLayer_HS1, steadyStateTPStorageLayer_HS1, steadyStateInsertedHS1, instInsertedHS1

	matrixOP/FREE instTPStorage_HS1 = mean(instTPStorageLayer_HS1)
	matrixOP/FREE steadyStateTPStorage_HS1 = mean(steadyStateTPStorageLayer_HS1)

	CHECK_EQUAL_WAVES(steadyStateInsertedHS1, steadyStateTPStorage_HS1, mode = WAVE_DATA, tol = 0.1)
	CHECK_EQUAL_WAVES(instInsertedHS1, instTPStorage_HS1, mode = WAVE_DATA, tol = 0.1)
End