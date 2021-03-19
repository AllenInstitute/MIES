#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=VeryLastTestSuite

// This testcase is kind of a hack as it requires that a lot of other tests have run.
// It checks that we have encountered all possible acquisition state transitions during the tests.
Function CheckEncounteredAcquisitions()

	WAVE actual = AS_GenerateEncounteredTransitions()
	WAVE valid  = GetValidAcqStateTransitions()
	CHECK_EQUAL_WAVES(actual, valid, mode = WAVE_DATA)
End
