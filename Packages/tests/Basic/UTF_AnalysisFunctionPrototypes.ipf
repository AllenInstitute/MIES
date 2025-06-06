#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = AnalysisFunctionPrototypeTests

static Function CheckThatTheyAllAssertOut()

	string funcList, func

	funcList = FunctionList("*", ";", "WIN:MIES_AnalysisFunctionPrototypes.ipf")
	CHECK_PROPER_STR(funcList)

	funcList = GrepList(funcList, "^IUTF_TagFunc.*", 1)

	WAVE/T funcs = ListToTextWave(funcList, ";")

	for(func : funcs)
		INFO("Function %s", s0 = func)

		try
			strswitch(func)
				case "AFP_ANALYSIS_FUNC_V1":
					AFP_ANALYSIS_FUNC_V1("", NaN, $"", NaN)
					break
				case "AFP_ANALYSIS_FUNC_V2":
					AFP_ANALYSIS_FUNC_V2("", NaN, $"", NaN, NaN)
					break
				case "AFP_ANALYSIS_FUNC_V3":
					STRUCT AnalysisFunction_V3 af
					AFP_ANALYSIS_FUNC_V3("", af)
					break
				case "AFP_PARAM_GETTER_V3":
					AFP_PARAM_GETTER_V3()
					break
				case "AFP_PARAM_HELP_GETTER_V3":
					AFP_PARAM_HELP_GETTER_V3("")
					break
				case "AFP_PARAM_CHECK_V1":
					AFP_PARAM_CHECK_V1("", "")
					break
				case "AFP_PARAM_CHECK_V2":
					STRUCT CheckParametersStruct cp
					AFP_PARAM_CHECK_V2("", cp)
					break
				default:
					FAIL()
			endswitch
			FAIL()
		catch
			CHECK_NO_RTE()
		endtry
	endfor
End
