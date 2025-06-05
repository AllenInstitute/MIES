#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HardwareAnalysisFunctions

#include "UTF_HardwareAnalysisFunctions_Includes"

Function TEST_BEGIN_OVERRIDE(string name)

	HardwareTestBeginCommon(name)
End

Function TEST_END_OVERRIDE(string name)

	TestEndCommon()
End

Function TEST_CASE_BEGIN_OVERRIDE(string name)

	HardwareTestCaseBeginCommon(name)
End

Function TEST_CASE_END_OVERRIDE(string name)

	HardwareTestCaseEndCommon(name)
End
