#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=MacrosTest

static Function ExecuteAllMacros()

	string mac
	variable keepDebugPanel

	// avoid that the default TEST_CASE_BEGIN_OVERRIDE
	// hook keeps our debug panel open if it did not exist before
	keepDebugPanel = WindowExists("DP_DebugPanel")

	WAVE/T macros = GetMIESMacros()

	for(mac : macros)
		Execute mac + "()"
	endfor

	// we only get here if all Macros execute without errrors
	// so in case we get errors the test case fails as it does not have at least one assertion
	PASS()

	if(!keepDebugPanel)
		KillWindow/Z DP_DebugPanel
	endif
End
