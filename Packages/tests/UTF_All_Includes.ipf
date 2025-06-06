#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = AllIncludes

#include "UTF_Basic_Includes"
#include "UTF_HardwareBasic_Includes"
#include "UTF_HardwareAnalysisFunctions_Includes"
#include "UTF_HistoricData_Includes"
#include "UTF_PAPlot_Includes"

Function NoTestSuite()

	INFO("This file is not a test suite")
	FAIL()
End
