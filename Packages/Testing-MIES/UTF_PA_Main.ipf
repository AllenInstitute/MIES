#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#include "MIES_include"
#include "unit-testing"

#include "UTF_HelperFunctions"
#include "UTF_PA_Tests"

Function run()
	// speeds up testing to start with a fresh copy
	KillWindow/Z HistoryCarbonCopy

	DisableDebugOutput()
	string procList = ""
	procList += "UTF_PA_Tests.ipf"

	RunTest(procList, enableJU = 1)
End
