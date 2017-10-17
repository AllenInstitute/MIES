#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "MIES_include"
#include "unit-testing"

#include "UTF_VeryBasicHardwareTests"

Function run()
	DisableDebugOutput()
	RunTest("UTF_VeryBasicHardwareTests.ipf", enableJU = 1)
End
