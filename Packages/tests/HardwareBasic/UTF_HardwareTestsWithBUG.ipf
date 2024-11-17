#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HardwareTestsWithBUG

static Function GlobalPreAcq(string device)

	PASS()
End

static Function GlobalPreInit(string device)

	DisableBugChecks()
End

Function CheckSweepSavingCompatible_PreAcq(string device)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "BreakConfigWave")
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
Function CheckSweepSavingCompatible([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, str)
End

Function CheckSweepSavingCompatible_REENTRY([string str])

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD0
Function ExtendedDebugLoggingOnErrorWithITC([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:_TP0_DAQ0")

	AcquireData_NG(s, str)
End

Function ExtendedDebugLoggingOnErrorWithITC_REENTRY([string str])

	variable refNum
	string   history

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	refNum = CaptureHistoryStart()
	HW_ITC_HandleReturnValues(0, 1, 0)
	history = CaptureHistory(refNum, 1)

	CHECK_GE_VAR(strsearch(history, "The ITC XOP returned an error!", 0), 0)

	refNum = CaptureHistoryStart()
	HW_ITC_HandleReturnValues(0, 0, 100)
	history = CaptureHistory(refNum, 1)

	CHECK_GE_VAR(strsearch(history, "The ITC XOP was called incorrectly!", 0), 0)
End
