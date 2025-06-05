#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = Amplifier

static Function TestFuncMapping()

	string text, funcStr, name, ctrl
	variable func, clampMode, funcBack, modeBack

	WAVE/Z/T content = ListToTextWave(ProcedureText("", 0, "MIES_Constants.ipf"), "\r")
	CHECK_WAVE(content, TEXT_WAVE)

	WAVE/Z/T results = GrepTextWave(content, "(?i)Constant[[:space:]]*MCC_(Set|Auto)")
	CHECK_WAVE(results, TEXT_WAVE)

	for(entry : results)
		SplitString/E="([[:digit:]]+)$" entry, funcStr
		CHECK_EQUAL_VAR(V_Flag, 1)
		func = str2num(funcStr)
		CHECK(IsInteger(func))

		Make/FREE modes = {V_CLAMP_MODE, I_CLAMP_MODE}

		for(clampMode : modes)

			ctrl = AI_MapFunctionConstantToControl(func, clampMode)
			INFO("entry: %s, ctrl: %s", s0 = entry, s1 = ctrl)

			if(IsEmpty(ctrl))
				continue
			endif

			if(GrepString(ctrl, "button.*"))
				continue
			endif

			CHECK_PROPER_STR(ctrl)

			INFO("entry: %s, ctrl: %s", s0 = entry, s1 = ctrl)
			name = AI_MapFunctionConstantToName(func, clampMode)
			CHECK_PROPER_STR(name)

			CHECK_EQUAL_STR(MIES_AI#AI_AmpStorageControlToRowLabel(ctrl), AI_MapFunctionConstantToName(func, clampMode))

			[funcBack, modeBack] = AI_MapControlNameToFunctionConstant(ctrl)

			INFO("entry: %s, ctrl: %s", s0 = entry, s1 = ctrl)
			CHECK_EQUAL_VAR(func, funcBack)

			if(AI_IsControlFromClampMode(ctrl, clampMode))
				INFO("entry: %s, ctrl: %s", s0 = entry, s1 = ctrl)
				CHECK_EQUAL_VAR(modeBack, clampMode)
			endif
		endfor
	endfor
End

// UTF_TD_GENERATOR GetClampModesWithoutIZero
static Function TestAmplifierUnits([variable clampMode])

	string unit, prefix, unitWithPrefix
	variable func, numPrefix

	WAVE/Z funcs = AI_GetFunctionConstantForClampMode(clampMode)
	CHECK_WAVE(funcs, FREE_WAVE | NUMERIC_WAVE)

	CHECK_GT_VAR(DimSize(funcs, ROWS), 0)
	for(func : funcs)

		unitWithPrefix = AI_GetUnitForFunctionConstant(func, clampMode)
		CHECK_PROPER_STR(unitWithPrefix)

		strswitch(unitWithPrefix)
			case "On/Off": // fallthrough
			case "%":
				PASS()
				break
			default:
				INFO("unitWithPrefix = %s", s0 = unitWithPrefix)
				// ParseUnit asserts out on invalid units
				ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
				PASS()
				break
		endswitch
	endfor
End
