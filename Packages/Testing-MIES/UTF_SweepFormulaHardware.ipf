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

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc(devices)
	endif

	string unlockedDevice, device
	variable i, numEntries

	dDAQ = ParamIsDefault(dDAQ) ? 0 : !!dDAQ
	oodDAQ = ParamIsDefault(oodDAQ) ? 0 : !!oodDAQ
	analysisFunction = SelectString(ParamIsDefault(analysisFunction), analysisFunction, "")

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, devices)

		unlockedDevice = DAP_CreateDAEphysPanel()

		PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=device)
		PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")

		REQUIRE(WindowExists(device))

		WAVE ampMCC = GetAmplifierMultiClamps()
		WAVE ampTel = GetAmplifierTelegraphServers()

		REQUIRE_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
		REQUIRE_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

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

static Function	TestSweepFormulaTP(string device)

	string graph, dbPanel
	string formula

	graph = DB_OpenDataBrowser()
	dbPanel = BSP_GetPanel(graph)
	PGC_SetAndActivateControl(dbPanel, "check_BrowserSettings_OVS", val = 1)
	PGC_SetAndActivateControl(dbPanel, "popup_overlaySweeps_select", str = "All")

	formula = "tp(0)"
	try
		WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
		FAIL()
	catch
		PASS()
	endtry

	formula = "tp(unknown_mode, channels(AD), sweeps())"
	try
		WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
		FAIL()
	catch
		PASS()
	endtry

	formula = "tp(ss, channels(AD), 3)"
	try
		WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
		FAIL()
	catch
		PASS()
	endtry

	formula = "tp(ss, channels(unknown), sweeps())"
	try
		WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
		FAIL()
	catch
		PASS()
	endtry

	formula = "tp(ss, channels(AD), sweeps())"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	Make/FREE/D/N=(1, 3, 2) wRef
	CHECK_EQUAL_WAVES(tpResult, wRef, mode=DIMENSION_SIZES)

	PGC_SetAndActivateControl(dbPanel, "check_BrowserSettings_DAC", val=1)
	formula = "tp(ss, channels(DA), sweeps())"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	Make/FREE/D/N=(1, 3, 2) wRef = 1000
	SetDimLabel COLS, 0, sweep0, wRef
	SetDimLabel COLS, 1, sweep1, wRef
	SetDimLabel COLS, 2, sweep2, wRef
	SetDimLabel LAYERS, 0, DA0, wRef
	SetDimLabel LAYERS, 1, DA1, wRef
	SetScale d, 0, 0, "MΩ", wRef
	CHECK_EQUAL_WAVES(tpResult, wRef)

	formula = "tp(inst, channels(DA), sweeps())"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	CHECK_EQUAL_WAVES(tpResult, wRef)

	formula = "tp(1, channels(DA), sweeps())"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	CHECK_EQUAL_WAVES(tpResult, wRef)

	formula = "tp(2, channels(DA), sweeps())"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	CHECK_EQUAL_WAVES(tpResult, wRef)

	formula = "tp(base, channels(DA), sweeps())"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	wRef = 0
	SetScale d, 0, 0, "", wRef
	CHECK_EQUAL_WAVES(tpResult, wRef)

	formula = "tp(0, channels(DA), sweeps())"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	CHECK_EQUAL_WAVES(tpResult, wRef)

	Make/FREE/D/N=(1, 1, 1) wRef
	formula = "tp(base, channels(DA0), 0)"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	SetScale d, 0, 0, "pA", wRef
	CHECK_EQUAL_WAVES(tpResult, wRef, mode=DIMENSION_UNITS)

	formula = "tp(base, channels(DA1), 0)"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	SetScale d, 0, 0, "mV", wRef
	CHECK_EQUAL_WAVES(tpResult, wRef, mode=DIMENSION_UNITS)

	formula = "tp(base, channels(AD1), 0)"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	SetScale d, 0, 0, "mV", wRef
	CHECK_EQUAL_WAVES(tpResult, wRef, mode=DIMENSION_UNITS)

	formula = "tp(base, channels(AD2), 0)"
	WAVE tpResult = SF_FormulaExecutor(DirectToFormulaParser(formula), graph=graph)
	SetScale d, 0, 0, "pA", wRef
	CHECK_EQUAL_WAVES(tpResult, wRef, mode=DIMENSION_UNITS)
End

static Function DirectToFormulaParser(string code)

	code = MIES_SF#SF_PreprocessInput(code)
	code = MIES_SF#SF_FormulaPreParser(code)
	return MIES_SF#SF_FormulaParser(code)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SF_TPTest([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1_RES_3")
	AcquireData(s, str, "EpochTest0_DA_0", "EpochTest0_DA_0")
End

static Function SF_TPTest_REENTRY([str])
	string str

	TestSweepFormulaTP(str)
End
