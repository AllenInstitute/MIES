#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=SetControlsTesting

static Function SC_SetControls1_Setter(device)
	string device

	Make/FREE/T payload = {"Pre DAQ", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "unknown_ctrl", wv=payload)
End

// ignores invalid control
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls1_Setter)
End

static Function SC_SetControls1_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)
End

static Function SC_SetControls2_Setter(device)
	string device

	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", str="myValue")
End

// complains on wrong parameter type (string)
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls2_Setter)
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

static Function SC_SetControls2a_Setter(device)
	string device

	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", var = 1)
End

// complains on wrong parameter type (numeric)
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls2a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls2a_Setter)
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

static Function SC_SetControls2b_Setter(device)
	string device

	Make/FREE wv
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// complains on wrong parameter type (numeric wave)
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls2b([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls2b_Setter)
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

static Function SC_SetControls3_Setter(device)
	string device

	Make/FREE/T/N=3 wv
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid parameter wave size
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls3_Setter)
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

static Function SC_SetControls3a_Setter(device)
	string device

	Make/FREE/T wv = {"Unknown", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid event type (unknown)
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls3a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls3a_Setter)
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

static Function SC_SetControls3b_Setter(device)
	string device

	Make/FREE/T wv = {"Mid Sweep", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid event type (mid sweep)
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls3b([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls3b_Setter)
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

static Function SC_SetControls3c_Setter(device)
	string device

	Make/FREE/T wv = {"Generic", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid event type (generic)
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls3c([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls3c_Setter)
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

static Function SC_SetControls4_Setter(device)
	string device

	Make/FREE/T wv = {"Pre Sweep", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// unchangeable control in other event than pre DAQ
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	try
		AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls4_Setter)
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

static Function SC_SetControls5_Setter(device)
	string device

	Make/FREE/T wv = {"Post Sweep", "0"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcqHS_00", wv = wv)
End

// hidden control is ignored
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls5_Setter)
End

static Function SC_SetControls5_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	CHECK_EQUAL_VAR(GetCheckBoxState(str, "Check_DataAcqHS_00"), 1)
End

static Function SC_SetControls6_Setter(device)
	string device

	// indexing and repeated acquistion are special as both can only be set in Pre/POST DAQ

	Make/FREE/T/N=2 wv
	wv[] = {"Pre DAQ", "0"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq1_RepeatAcq", wv = wv)

	wv[] = {"Pre DAQ", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_Settings_UseDoublePrec", wv = wv)

	wv[] = {"Pre Set", "47"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "SetVar_DataAcq_TPBaselinePerc", wv = wv)

	wv[] = {"Pre Sweep", "4"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Popup_Settings_SampIntMult", wv = wv)

	wv[] = {"Post Sweep", "abcd efgh"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "SetVar_DataAcq_Comment", wv = wv)

	wv[] = {"Post Set", "10"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "setvar_DataAcq_OnsetDelayUser", wv = wv)

	wv[] = {"Post DAQ", "0"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// works with different controls
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls6_Setter)
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

static Function SC_SetControls7_Setter(device)
	string device

	Make/FREE/T/N=4 wv
	wv[] = {"PRE daq", "2", "post DAQ", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "SetVar_DataAcq_SetRepeats", wv = wv)

	wv[] = {"Pre DAQ", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq1_RepeatAcq", wv = wv)
End

// works with event/data tuples and also accepts incorrect casing for the event names
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls7_Setter)
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

static Function SC_SetControls8_Setter(device)
	string device

	Make/FREE/T/N=2 wv
	wv[] = {"Post DAQ", "abcdefgh"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "NB", wv = wv)
End

static Function SC_SetControls8_Setter2(device)
	string device

	PGC_SetAndActivateControl(device, "button_DataAcq_OpenCommentNB")
End

// works with event/data tuples setting notebook text
// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function SC_SetControls8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AnalysisFunctionTesting#AcquireData(s, "AnaFuncSetCtrl_DA_0", str, postInitializeFunc = SC_SetControls8_Setter, preAcquireFunc = SC_SetControls8_Setter2)
End

static Function SC_SetControls8_REENTRY([str])
	string str

	variable sweepNo
	string expected, actual

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	expected	= "abcdefgh"
	actual = GetNotebookText(str + "#UserComments#NB")
	CHECK_EQUAL_STR(expected, actual)
End
