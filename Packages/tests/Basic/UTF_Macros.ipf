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
		CHECK_NO_RTE()
	endfor

	if(!keepDebugPanel)
		KillWindow/Z DP_DebugPanel
	endif
End

static Function CheckSetVariablesNoEditInMacros()

	string win, recMacro, subwin
	variable controlType

	WAVE/T macros = GetMIESMacros()

	for(win : macros)
		Execute win + "()"
		CHECK_NO_RTE()

		WAVE/T allWindows = ListToTextWave(GetAllWindows(win), ";")

		for(subwin : allWindows)

			WAVE/T controls = ListToTextWave(ControlNameList(subwin, ";"), ";")

			for(ctrl : controls)
				[recMacro, controlType] = GetRecreationMacroAndType(subwin, ctrl)
				CHECK_PROPER_STR(recMacro)

				if(controlType != CONTROL_TYPE_SETVARIABLE)
					continue
				endif

				if(!cmpstr(ctrl, "setvar_sweepFormula_parseResult"))
					Debugger
				endif

				if(GetControlSettingVar(recMacro, "noEdit") == 1)
					INFO("Win: %s, Control %s, dont restore set?", s0 = subwin, s1 = ctrl)
					CHECK_EQUAL_STR(GetUserData(subwin, ctrl, "Config_DontRestore"), "1")

					INFO("Win: %s, Control %s, dont save set?", s0 = subwin, s1 = ctrl)
					CHECK_EQUAL_STR(GetUserData(subwin, ctrl, "Config_DontSave"), "1")
				endif
			endfor
		endfor
	endfor
End
