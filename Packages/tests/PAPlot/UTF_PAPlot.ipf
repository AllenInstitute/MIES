#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PAPlot

#include "UTF_PAPlot_Includes"

Function TEST_BEGIN_OVERRIDE(string name)

	TestBeginCommon()
End

Function TEST_END_OVERRIDE(string name)

	TestEndCommon()
End

// use copy of mies folder and restore it each time
Function TEST_CASE_BEGIN_OVERRIDE(string name)

	variable err
	string   miesPath

	TestCaseBeginCommon(name)

	miesPath = GetMiesPathAsString()
	DuplicateDataFolder/O=1 root:MIES_backup, $miesPath

	// monkey patch the labnotebook to claim it holds IC data instead of VC
	WAVE numericalValues = root:MIES:LabNoteBook:Dev1:numericalValues
	MultiThread numericalValues[][%$CLAMPMODE_ENTRY_KEY][] = ((numericalValues[p][%$CLAMPMODE_ENTRY_KEY][r] == V_CLAMP_MODE) ? I_CLAMP_MODE : numericalValues[p][%$CLAMPMODE_ENTRY_KEY][r])
End

Function TEST_CASE_END_OVERRIDE(string testcase)

	TestCaseEndCommon(testcase)
End
