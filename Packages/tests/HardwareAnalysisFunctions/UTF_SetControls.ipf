#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=SetControlsTesting

static Function [STRUCT DAQSettings s] SC_GetDAQSettings(string device, [variable far])

	if(ParamisDefault(far))
		far = 1
	else
		far = !!far
	endif

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB0_FAR" + num2str(far)    + \
								 "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncSetCtrl_DA_0:")

	 return [s]
End

static Function GlobalPreAcq(string device)

	PASS()
End

static Function GlobalPreInit(string device)

	PASS()
End

static Function SC_SetControls1_preAcq(device)
	string device

	Make/FREE/T payload = {"Pre DAQ", "1"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "unknown_ctrl", wv=payload)
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "group_DataAcq_ClampMode", wv=payload)
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "valdisp_DataAcq_SweepsActiveSet", wv=payload)
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Title_DataAcq_Bridge", wv=payload)
End

// ignores invalid control
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls1([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function SC_SetControls1_REENTRY([str])
	string str

	variable sweepNo
	string contents

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	contents = GetNotebookText("HistoryCarbonCopy")
	CHECK_GT_VAR(strsearch(contents, "The analysis parameter group_DataAcq_ClampMode is a control which can not be set.", 0), 0)
	CHECK_GT_VAR(strsearch(contents, "The analysis parameter valdisp_DataAcq_SweepsActiveSet is a control which can not be set.", 0), 0)
	CHECK_GT_VAR(strsearch(contents, "The analysis parameter Title_DataAcq_Bridge is a control which can not be set.", 0), 0)
End

static Function SC_SetControls2_preAcq(device)
	string device

	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", str="myValue")
End

// complains on wrong parameter type (string)
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls2([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str, far = 0)

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function SC_SetControls2_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function SC_SetControls2a_preAcq(device)
	string device

	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", var = 1)
End

// complains on wrong parameter type (numeric)
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls2a([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str, far = 0)

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function SC_SetControls2a_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function SC_SetControls2b_preAcq(device)
	string device

	Make/FREE wv
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// complains on wrong parameter type (numeric wave)
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls2b([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str, far = 0)

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function SC_SetControls2b_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function SC_SetControls3_preAcq(device)
	string device

	Make/FREE/T/N=3 wv
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid parameter wave size
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls3([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str, far = 0)

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function SC_SetControls3_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function SC_SetControls3a_preAcq(device)
	string device

	Make/FREE/T wv = {"Unknown", "1"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid event type (unknown)
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls3a([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str, far = 0)

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function SC_SetControls3a_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function SC_SetControls3b_preAcq(device)
	string device

	Make/FREE/T wv = {"Mid Sweep", "1"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid event type (mid sweep)
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls3b([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str, far = 0)

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function SC_SetControls3b_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function SC_SetControls3c_PreAcq(device)
	string device

	Make/FREE/T wv = {"Generic", "1"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid event type (generic)
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls3c([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str, far = 0)

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function SC_SetControls3c_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function SC_SetControls4_preAcq(device)
	string device

	Make/FREE/T wv = {"Pre Sweep", "1"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// unchangeable control in other event than pre DAQ
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls4([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str, far = 0)

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function SC_SetControls4_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function SC_SetControls5_preAcq(device)
	string device

	Make/FREE/T wv = {"Post Sweep", "0"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcqHS_00", wv = wv)
End

// hidden control is ignored
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls5([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function SC_SetControls5_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	CHECK_EQUAL_VAR(GetCheckBoxState(str, "Check_DataAcqHS_00"), 1)
End

static Function SC_SetControls6_preAcq(device)
	string device

	// indexing and repeated acquistion are special as both can only be set in Pre/POST DAQ

	Make/FREE/T/N=2 wv
	wv[] = {"Pre DAQ", "0"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq1_RepeatAcq", wv = wv)

	wv[] = {"Pre DAQ", "1"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_Settings_UseDoublePrec", wv = wv)

	wv[] = {"Pre Set", "47"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "SetVar_DataAcq_TPBaselinePerc", wv = wv)

	wv[] = {"Pre Sweep", "4"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Popup_Settings_SampIntMult", wv = wv)

	wv[] = {"Post Sweep", "abcd efgh"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "SetVar_DataAcq_Comment", wv = wv)

	wv[] = {"Post Set", "10"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "setvar_DataAcq_OnsetDelayUser", wv = wv)

	wv[] = {"Post DAQ", "0"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// works with different controls
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls6([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function SC_SetControls6_REENTRY([str])
	string str

	variable sweepNo
	string ref, actual

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	CHECK_EQUAL_VAR(GetCheckBoxState(str, "Check_DataAcq1_RepeatAcq"), 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, "Check_Settings_UseDoublePrec"), 1)
	CHECK_EQUAL_VAR(GetSetVariable(str, "setvar_DataAcq_OnsetDelayUser"), 10)

	ref = "abcd efgh"
	actual = GetSetVariableString(str, "SetVar_DataAcq_Comment")
	CHECK_EQUAL_STR(ref, actual)

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_DataAcq_TPBaselinePerc"), 47)
	CHECK_EQUAL_VAR(GetSetVariable(str, "setvar_DataAcq_OnsetDelayUser"), 10)
	// the third entry is four
	CHECK_EQUAL_VAR(GetPopupMenuIndex(str, "Popup_Settings_SampIntMult"), 2)
End

static Function SC_SetControls7_preAcq(device)
	string device

	Make/FREE/T/N=4 wv
	wv[] = {"PRE daq", "2", "post DAQ", "1"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "SetVar_DataAcq_SetRepeats", wv = wv)

	wv[] = {"Pre DAQ", "1"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq1_RepeatAcq", wv = wv)
End

// works with event/data tuples and also accepts incorrect casing for the event names
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls7([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function SC_SetControls7_REENTRY([str])
	string str

	variable sweepNo
	string ref, actual

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 1)

	CHECK_EQUAL_VAR(GetCheckBoxState(str, "Check_DataAcq1_RepeatAcq"), 1)
	// before starting: 1, after "PRE DAQ" 2, after "POST DAQ" 1 again
	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_DataAcq_SetRepeats"), 1)
End

static Function SC_SetControls8_preAcq(device)
	string device

	Make/FREE/T/N=2 wv
	wv[] = {"Post DAQ", "abcdefgh"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "NB", wv = wv)

	PGC_SetAndActivateControl(device, "button_DataAcq_OpenCommentNB")

	wv[] = {"Post Sweep", "1 + 2"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "sweepFormula_formula", wv = wv)

	// create two databrowser locked to this device
	CreateLockedDatabrowser(device)
	CreateLockedDatabrowser(device)
End

// works with event/data tuples setting notebook text
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls8([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function SC_SetControls8_REENTRY([str])
	string str

	variable sweepNo
	string expected, actual, nb

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	expected	= "abcdefgh"
	actual = GetNotebookText(str + "#UserComments#NB")
	CHECK_EQUAL_STR(expected, actual)

	WAVE/T/Z allDBs = DB_FindAllDataBrowser(str)
	CHECK_WAVE(allDBs, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(allDbs, ROWS), 2)

	for(databrowser : allDBs)
		nb = BSP_GetSFFormula(databrowser)

		expected = "1 + 2"
		actual = GetNotebookText(nb, mode = 2)
		CHECK_EQUAL_STR(expected, actual)
	endfor
End

static Function SC_SetControls9_preAcq(device)
	string device

	Make/FREE/T/N=2 wv

	wv[] = {"Pre Sweep", "47"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "SetVar_DataAcq_TPBaselinePerc", wv = wv)

	wv[] = {"Pre Sweep Config", "10"}
	AFH_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "setvar_DataAcq_OnsetDelayUser", wv = wv)
End

// supports "Pre Sweep" (old) and "Pre Sweep Config" (new)
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function SC_SetControls9([str])
	string str

	[STRUCT DAQSettings s] = SC_GetDAQSettings(str)
	AcquireData_NG(s, str)
End

static Function SC_SetControls9_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_DataAcq_TPBaselinePerc"), 47)
	CHECK_EQUAL_VAR(GetSetVariable(str, "setvar_DataAcq_OnsetDelayUser"), 10)
End
