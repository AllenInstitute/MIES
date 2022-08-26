#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HardwareTestsWithBUG

Function CheckSweepSavingCompatible_IGNORE(string device)

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Analysis function (generic)", str = "BreakConfigWave")

	DisableBugChecks()
End

/// UTF_TD_GENERATOR HardwareHelperFunctions#DeviceNameGeneratorMD1
Function CheckSweepSavingCompatible([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG_1")

	AcquireData_BHT(s, str, preAcquireFunc = CheckSweepSavingCompatible_IGNORE)
End

Function CheckSweepSavingCompatible_REENTRY([string str])
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End
