#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SF
#endif

// define SWEEPFORMULA_DEBUG to enable debug mode with more persistent data

/// @file MIES_SweepFormula.ipf
///
/// @brief __SF__ Sweep formula allows to do analysis on sweeps with a
/// dedicated formula language

static Constant SF_STATE_UNINITIALIZED = -1
static Constant SF_STATE_DEFAULT = 0
static Constant SF_STATE_COLLECT = 1
static Constant SF_STATE_ADDITION = 2
static Constant SF_STATE_SUBTRACTION = 3
static Constant SF_STATE_MULTIPLICATION = 4
static Constant SF_STATE_DIVISION = 5
static Constant SF_STATE_PARENTHESIS = 6
static Constant SF_STATE_FUNCTION = 7
static Constant SF_STATE_ARRAY = 8
static Constant SF_STATE_ARRAYELEMENT = 9
static Constant SF_STATE_WHITESPACE = 10
static Constant SF_STATE_NEWLINE = 12
static Constant SF_STATE_OPERATION = 13
static Constant SF_STATE_STRING = 14
static Constant SF_STATE_STRINGTERMINATOR = 15

static Constant SF_ACTION_UNINITIALIZED = -1
static Constant SF_ACTION_SKIP = 0
static Constant SF_ACTION_COLLECT = 1
static Constant SF_ACTION_CALCULATION = 2
static Constant SF_ACTION_SAMECALCULATION = 3
static Constant SF_ACTION_HIGHERORDER = 4
static Constant SF_ACTION_ARRAYELEMENT = 5
static Constant SF_ACTION_PARENTHESIS = 6
static Constant SF_ACTION_FUNCTION = 7
static Constant SF_ACTION_ARRAY = 8

/// Regular expression which extracts both formulas from `$a vs $b`
static StrConstant SF_SWEEPFORMULA_REGEXP = "^(.+?)(?:\\bvs\\b(.+))?$"
/// Regular expression which extracts formulas pairs from `$a vs $b\rand\r$c vs $d\rand\r...`
static StrConstant SF_SWEEPFORMULA_GRAPHS_REGEXP = "^(.+?)(?:\\r[ \t]*and[ \t]*\\r(.*))?$"

static Constant SF_MAX_NUMPOINTS_FOR_MARKERS = 1000

static Constant SF_APFREQUENCY_FULL          = 0x0
static Constant SF_APFREQUENCY_INSTANTANEOUS = 0x1
static Constant SF_APFREQUENCY_APCOUNT       = 0x2

static StrConstant SF_OP_MINUS = "-"
static StrConstant SF_OP_PLUS = "+"
static StrConstant SF_OP_MULT = "*"
static StrConstant SF_OP_DIV = "~1"
static StrConstant SF_OP_RANGE = "range"
static StrConstant SF_OP_RANGESHORT = "…"
static StrConstant SF_OP_MIN = "min"
static StrConstant SF_OP_MAX = "max"
static StrConstant SF_OP_AVG = "avg"
static StrConstant SF_OP_MEAN = "mean"
static StrConstant SF_OP_RMS = "rms"
static StrConstant SF_OP_VARIANCE = "variance"
static StrConstant SF_OP_STDEV = "stdev"
static StrConstant SF_OP_DERIVATIVE = "derivative"
static StrConstant SF_OP_INTEGRATE = "integrate"
static StrConstant SF_OP_TIME = "time"
static StrConstant SF_OP_XVALUES = "xvalues"
static StrConstant SF_OP_MERGE = "merge"
static StrConstant SF_OP_TEXT = "text"
static StrConstant SF_OP_LOG = "log"
static StrConstant SF_OP_LOG10 = "log10"
static StrConstant SF_OP_APFREQUENCY = "apfrequency"
static StrConstant SF_OP_CURSORS = "cursors"
static StrConstant SF_OP_SWEEPS = "sweeps"
static StrConstant SF_OP_AREA = "area"
static StrConstant SF_OP_SETSCALE = "setscale"
static StrConstant SF_OP_BUTTERWORTH = "butterworth"
static StrConstant SF_OP_CHANNELS = "channels"
static StrConstant SF_OP_DATA = "data"
static StrConstant SF_OP_LABNOTEBOOK = "labnotebook"
static StrConstant SF_OP_WAVE = "wave"
static StrConstant SF_OP_FINDLEVEL = "findlevel"
static StrConstant SF_OP_EPOCHS = "epochs"
static StrConstant SF_OP_TP = "tp"
static StrConstant SF_OP_STORE = "store"
static StrConstant SF_OP_SELECT = "select"

static StrConstant SF_OP_EPOCHS_TYPE_RANGE = "range"
static StrConstant SF_OP_EPOCHS_TYPE_NAME = "name"
static StrConstant SF_OP_EPOCHS_TYPE_TREELEVEL = "treelevel"
static StrConstant SF_OP_TP_TYPE_BASELINE = "base"
static StrConstant SF_OP_TP_TYPE_INSTANT = "inst"
static StrConstant SF_OP_TP_TYPE_STATIC = "ss"
static Constant SF_OP_TP_TYPE_BASELINE_NUM = 0
static Constant SF_OP_TP_TYPE_INSTANT_NUM = 1
static Constant SF_OP_TP_TYPE_STATIC_NUM = 2

static Constant EPOCHS_TYPE_INVALID = -1
static Constant EPOCHS_TYPE_RANGE = 0
static Constant EPOCHS_TYPE_NAME = 1
static Constant EPOCHS_TYPE_TREELEVEL = 2

static StrConstant SF_CHAR_COMMENT = "#"
static StrConstant SF_CHAR_CR = "\r"
static StrConstant SF_CHAR_NEWLINE = "\n"

static StrConstant MIXED_UNITS = "** undefined **"

static Constant SF_TRANSFER_ALL_DIMS = -1

static StrConstant SF_WORKING_DF = "FormulaData"
static StrConstant SF_WREF_MARKER = "\"WREF@\":"

static StrConstant SF_PLOTTER_TRACENAME = "formula"
static StrConstant SF_PLOTTER_GUIDENAME = "HOR"

Function/WAVE SF_GetNamedOperations()

	Make/FREE/T wt = {SF_OP_RANGE, SF_OP_MIN, SF_OP_MAX, SF_OP_AVG, SF_OP_MEAN, SF_OP_RMS, SF_OP_VARIANCE, SF_OP_STDEV, \
					  SF_OP_DERIVATIVE, SF_OP_INTEGRATE, SF_OP_TIME, SF_OP_XVALUES, SF_OP_MERGE, SF_OP_TEXT, SF_OP_LOG, \
					  SF_OP_LOG10, SF_OP_APFREQUENCY, SF_OP_CURSORS, SF_OP_SWEEPS, SF_OP_AREA, SF_OP_SETSCALE, SF_OP_BUTTERWORTH, \
					  SF_OP_CHANNELS, SF_OP_DATA, SF_OP_LABNOTEBOOK, SF_OP_WAVE, SF_OP_FINDLEVEL, SF_OP_EPOCHS, SF_OP_TP, \
					  SF_OP_STORE, SF_OP_SELECT}

	return wt
End

Function/WAVE SF_GetFormulaKeywords()

	// see also SF_SWEEPFORMULA_REGEXP and SF_SWEEPFORMULA_GRAPHS_REGEXP
	Make/FREE/T wt = {"vs", "and"}

	return wt
End

static Function/S SF_StringifyState(variable state)

	switch(state)
		case SF_STATE_DEFAULT:
			return "SF_STATE_DEFAULT"
		case SF_STATE_COLLECT:
			return "SF_STATE_COLLECT"
		case SF_STATE_ADDITION:
			return "SF_STATE_ADDITION"
		case SF_STATE_SUBTRACTION:
			return "SF_STATE_SUBTRACTION"
		case SF_STATE_MULTIPLICATION:
			return "SF_STATE_MULTIPLICATION"
		case SF_STATE_DIVISION:
			return "SF_STATE_DIVISION"
		case SF_STATE_PARENTHESIS:
			return "SF_STATE_PARENTHESIS"
		case SF_STATE_FUNCTION:
			return "SF_STATE_FUNCTION"
		case SF_STATE_ARRAY:
			return "SF_STATE_ARRAY"
		case SF_STATE_ARRAYELEMENT:
			return "SF_STATE_ARRAYELEMENT"
		case SF_STATE_WHITESPACE:
			return "SF_STATE_WHITESPACE"
		case SF_STATE_NEWLINE:
			return "SF_STATE_NEWLINE"
		case SF_STATE_OPERATION:
			return "SF_STATE_OPERATION"
		case SF_STATE_STRING:
			return "SF_STATE_STRING"
		case SF_STATE_STRINGTERMINATOR:
			return "SF_STATE_STRINGTERMINATOR"
		case SF_STATE_UNINITIALIZED:
			return "SF_STATE_UNINITIALIZED"
		default:
			ASSERT(0, "unknown state")
	endswitch
End

static Function/S SF_StringifyAction(variable action)

	switch(action)
		case SF_ACTION_SKIP:
			return "SF_ACTION_SKIP"
		case SF_ACTION_COLLECT:
			return "SF_ACTION_COLLECT"
		case SF_ACTION_CALCULATION:
			return "SF_ACTION_CALCULATION"
		case SF_ACTION_SAMECALCULATION:
			return "SF_ACTION_SAMECALCULATION"
		case SF_ACTION_HIGHERORDER:
			return "SF_ACTION_HIGHERORDER"
		case SF_ACTION_ARRAYELEMENT:
			return "SF_ACTION_ARRAYELEMENT"
		case SF_ACTION_PARENTHESIS:
			return "SF_ACTION_PARENTHESIS"
		case SF_ACTION_FUNCTION:
			return "SF_ACTION_FUNCTION"
		case SF_ACTION_ARRAY:
			return "SF_ACTION_ARRAY"
		case SF_ACTION_UNINITIALIZED:
			return "SF_ACTION_UNINITIALIZED"
		default:
			ASSERT(0, "Unknown action")
	endswitch
End

/// @brief Assertion for sweep formula
///
/// This assertion does *not* indicate a genearl programmer error but a
/// sweep formula user error.
///
/// All programmer error checks must still use ASSERT().
static Function SF_Assert(variable condition, string message[, variable jsonId])

	if(!condition)
		if(!ParamIsDefault(jsonId))
			JSON_Release(jsonId, ignoreErr=1)
		endif
		SVAR error = $GetSweepFormulaParseErrorMessage()
		error = message
#ifdef AUTOMATED_TESTING_DEBUGGING
		Debugger
#endif
		Abort
	endif
End

/// @brief preparse user input to correct formula patterns
///
/// @return parsed formula
static Function/S SF_FormulaPreParser(string formula)

	SF_Assert(CountSubstrings(formula, "(") == CountSubstrings(formula, ")"), "Bracket mismatch in formula.")
	SF_Assert(CountSubstrings(formula, "[") == CountSubstrings(formula, "]"), "Array bracket mismatch in formula.")
	SF_Assert(!mod(CountSubstrings(formula, "\""), 2), "Quotation marks mismatch in formula.")

	formula = ReplaceString("...", formula, "…")

	return formula
End

/// @brief serialize a string formula into JSON
///
/// @param formula  string formula
/// @param createdArray [optional, default 0] set on recursive calls, returns boolean if parser created a JSON array
/// @param indentLevel [internal use only] recursive call level, used for debug output
/// @returns a JSONid representation
static Function SF_FormulaParser(string formula, [variable &createdArray, variable indentLevel])

	variable i, parenthesisStart, parenthesisEnd, jsonIDdummy, jsonIDarray, subId
	variable formulaLength
	string tempPath
	string indentation = ""
	variable action = SF_ACTION_UNINITIALIZED
	string token = ""
	string buffer = ""
	variable state = SF_STATE_UNINITIALIZED
	variable lastState = SF_STATE_UNINITIALIZED
	variable lastCalculation = SF_STATE_UNINITIALIZED
	variable level = 0
	variable arrayLevel = 0
	variable createdArrayLocal, wasArrayCreated
	variable lastAction = SF_ACTION_UNINITIALIZED

	variable jsonID = JSON_New()
	string jsonPath = ""

#ifdef DEBUGGING_ENABLED
	for(i = 0; i < indentLevel; i += 1)
		indentation += "-> "
	endfor

	if(DP_DebuggingEnabledForCaller())
		printf "%sformula %s\r", indentation, formula
	endif
#endif

	formulaLength = strlen(formula)

	if(formulaLength == 0)
		return jsonID
	endif

	for(i = 0; i < formulaLength; i += 1)
		token += formula[i]

		// state
		strswitch(token)
			case "/":
				state = SF_STATE_DIVISION
				break
			case "*":
				state = SF_STATE_MULTIPLICATION
				break
			case "-":
				state = SF_STATE_SUBTRACTION
				break
			case "+":
				state = SF_STATE_ADDITION
				break
			case "…":
				state = SF_STATE_OPERATION
				break
			case "(":
				level += 1
				break
			case ")":
				level -= 1
				if(!cmpstr(buffer[0], "("))
					state = SF_STATE_PARENTHESIS
					break
				endif
				if(GrepString(buffer, "^[A-Za-z]"))
					state = SF_STATE_FUNCTION
					break
				endif
				state = SF_STATE_DEFAULT
				break
			case "[":
				arrayLevel += 1
				break
			case "]":
				arrayLevel -= 1
				state = SF_STATE_ARRAY
				break
			case ",":
				state = SF_STATE_ARRAYELEMENT
				break
			case "\"":
				state = SF_STATE_STRINGTERMINATOR
				break
			case "\r":
				state = SF_STATE_NEWLINE
				break
			case " ":
			case "\t":
				state = SF_STATE_WHITESPACE
				break
			default:
				if(!(char2num(token) > 0))
					continue
				endif
				state = SF_STATE_COLLECT
				SF_Assert(GrepString(token, "[A-Za-z0-9_\.:;=]"), "undefined pattern in formula: " + formula[i, i + 5], jsonId=jsonId)
		endswitch

		if(level > 0 || arrayLevel > 0)
			// transfer sub level "as is" to buffer
			state = SF_STATE_DEFAULT
		endif

#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForCaller())
			printf "%stoken %s, state %s, lastCalculation %s, ", indentation, token, SF_StringifyState(state),  SF_StringifyState(lastCalculation)
		endif
#endif

		// state transition
		if(lastState == SF_STATE_STRING && state != SF_STATE_STRINGTERMINATOR)
			action = SF_ACTION_COLLECT
		elseif(state != lastState)
			switch(state)
				case SF_STATE_ADDITION:
					if(lastCalculation == SF_STATE_SUBTRACTION)
						action = SF_ACTION_HIGHERORDER
						break
					endif
				case SF_STATE_SUBTRACTION:
					if(lastCalculation == SF_STATE_MULTIPLICATION)
						action = SF_ACTION_HIGHERORDER
						break
					endif
				case SF_STATE_MULTIPLICATION:
					if(lastCalculation == SF_STATE_DIVISION)
						action = SF_ACTION_HIGHERORDER
						break
					endif
				case SF_STATE_DIVISION:
				case SF_STATE_OPERATION:
					if(IsEmpty(buffer))
						if(lastCalculation == SF_STATE_UNINITIALIZED)
							action = SF_ACTION_HIGHERORDER
						else
							action = SF_ACTION_COLLECT
						endif
						break
					endif
					action = SF_ACTION_CALCULATION
					if(state == lastCalculation)
						action = SF_ACTION_SAMECALCULATION
					endif
					if(lastCalculation == SF_STATE_ARRAYELEMENT)
						action = SF_ACTION_COLLECT
					endif
					break
				case SF_STATE_PARENTHESIS:
					action = SF_ACTION_PARENTHESIS
					if(lastCalculation == SF_STATE_ARRAYELEMENT)
						action = SF_ACTION_COLLECT
					endif
					break
				case SF_STATE_FUNCTION:
					action = SF_ACTION_FUNCTION
					if(lastCalculation == SF_STATE_ARRAYELEMENT)
						action = SF_ACTION_COLLECT
					endif
					break
				case SF_STATE_ARRAYELEMENT:
					action = SF_ACTION_ARRAYELEMENT
					if(lastCalculation != SF_STATE_ARRAYELEMENT)
						action = SF_ACTION_HIGHERORDER
					endif
					break
				case SF_STATE_ARRAY:
					action = SF_ACTION_ARRAY
					break
				case SF_STATE_NEWLINE:
				case SF_STATE_WHITESPACE:
					action = SF_ACTION_SKIP
					break
				case SF_STATE_COLLECT:
				case SF_STATE_DEFAULT:
					action = SF_ACTION_COLLECT
					break
				case SF_STATE_STRINGTERMINATOR:
					if(lastState != SF_STATE_STRING)
						state = SF_STATE_STRING
					endif
					action = SF_ACTION_COLLECT
					break
				default:
					SF_Assert(0, "Encountered undefined transition " + num2istr(state), jsonId=jsonId)
			endswitch
			lastState = state
		endif

#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForCaller())
			printf "action %s, lastState %s\r", SF_StringifyAction(action), SF_StringifyState(lastState)
		endif
#endif

		// Checks for simple syntax dependencies
		if(action != SF_ACTION_SKIP)
			switch(lastAction)
				case SF_ACTION_ARRAY:
					// If the last action was the handling of "]" from an array
					SF_ASSERT(action == SF_ACTION_ARRAYELEMENT || action == SF_ACTION_HIGHERORDER, "Expected \",\" after \"]\"")
					break
				default:
					break
			endswitch
		endif

		// action
		switch(action)
			case SF_ACTION_COLLECT:
				buffer += token
			case SF_ACTION_SKIP:
				token = ""
				continue
			case SF_ACTION_FUNCTION:
				tempPath = jsonPath
				if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
					JSON_AddObjects(jsonID, jsonPath)
					tempPath += "/" + num2istr(JSON_GetArraySize(jsonID, jsonPath) - 1)
				endif
				tempPath += "/"
				parenthesisStart = strsearch(buffer, "(", 0, 0)
				tempPath += SF_EscapeJsonPath(buffer[0, parenthesisStart - 1])
				jsonIDdummy = SF_FormulaParser(buffer[parenthesisStart + 1, inf])
				if(JSON_GetType(jsonIDdummy, "") != JSON_ARRAY)
					JSON_AddTreeArray(jsonID, tempPath)
				endif
				JSON_AddJSON(jsonID, tempPath, jsonIDdummy)
				JSON_Release(jsonIDdummy)
				break
			case SF_ACTION_PARENTHESIS:
				JSON_AddJSON(jsonID, jsonPath, SF_FormulaParser(buffer[1, inf], indentLevel = indentLevel + 1))
				break
			case SF_ACTION_HIGHERORDER:
				// - called if for the first time a "," is encountered (from SF_STATE_ARRAYELEMENT)
				// - called if a higher priority calculation, e.g. * over + requires to put array in sub json path
				lastCalculation = state
				if(!IsEmpty(buffer))
					JSON_AddJSON(jsonID, jsonPath, SF_FormulaParser(buffer, indentLevel = indentLevel + 1))
				endif
				jsonPath = SF_EscapeJsonPath(token)
				if(!cmpstr(jsonPath, ",") || !cmpstr(jsonPath, "]"))
					jsonPath = ""
				endif
				jsonId = SF_FPPutInArrayAtPath(jsonID, jsonPath)
				createdArrayLocal = 1
				break
			case SF_ACTION_ARRAY:
				// - buffer has collected chars between "[" and "]"(where "]" is not included in the buffer here)
				// - Parse recursively the inner part of the brackets
				// - return if the parsing of the inner part created implicitly in the JSON brackets or not
				// If there was no array created, we have to add another outer array around the returned json
				// An array needs to be also added if the returned json is a simple value as this action requires
				// to return an array.
				SF_Assert(!cmpstr(buffer[0], "["), "Can not find array start. (Is there a \",\" before \"[\" missing?)", jsonId=jsonId)
				subId = SF_FormulaParser(buffer[1, inf], createdArray=wasArrayCreated, indentLevel = indentLevel + 1)
				if(wasArrayCreated)
					ASSERT(JSON_GetType(subId, "") == JSON_ARRAY, "Expected Array")
				endif

				SF_FPAddArray(jsonId, jsonPath, subId, wasArrayCreated)
				break
			case SF_ACTION_CALCULATION:
				if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
					JSON_AddObjects(jsonID, jsonPath) // prepare for decent
					jsonPath += "/" + num2istr(JSON_GetArraySize(jsonID, jsonPath) - 1)
				endif
				jsonPath += "/" + SF_EscapeJsonPath(token)
			case SF_ACTION_ARRAYELEMENT:
				// - "," was encountered, thus we have multiple elements, we need to set an array at current path
				// The actual content is added in the case fall-through
				JSON_AddTreeArray(jsonID, jsonPath)
				lastCalculation = state
			case SF_ACTION_SAMECALCULATION:
			default:
				if(!IsEmpty(buffer))
					JSON_AddJSON(jsonID, jsonPath, SF_FormulaParser(buffer, indentLevel = indentLevel + 1))
				endif
		endswitch
		lastAction = action
		buffer = ""
		token = ""
	endfor

	// last element (recursion)
	if(!cmpstr(buffer, formula))
		if(GrepString(buffer, "^(?i)[0-9]+(?:\.[0-9]+)?(?:[\+-]?E[0-9]+)?$"))
			JSON_AddVariable(jsonID, jsonPath, str2num(formula))
		elseif(!cmpstr(buffer, "\"\"")) // dummy check
			JSON_AddString(jsonID, jsonPath, "")
		elseif(GrepString(buffer, "^\".*\"$"))
			JSON_AddString(jsonID, jsonPath, buffer[1, strlen(buffer) - 2])
		else
			JSON_AddString(jsonID, jsonPath, buffer)
		endif
	elseif(!IsEmpty(buffer))
		JSON_AddJSON(jsonID, jsonPath, SF_FormulaParser(buffer))
	endif

	if(!ParamIsDefault(createdArray))
		createdArray = createdArrayLocal
	endif

	return jsonID
End

/// @brief Create a new empty array object, add mainId into it at path and return created json, release subId
static Function SF_FPPutInArrayAtPath(variable subId, string jsonPath)

	variable newId

	newId = JSON_New()
	JSON_AddTreeArray(newId, jsonPath)
	if(JSON_GetType(subId, "") != JSON_NULL)
		JSON_AddJSON(newId, jsonPath, subId)
	endif
	JSON_Release(subId)

	return newId
End

/// @brief Adds subId to mainId, if necessary puts subId into an array, release subId
static Function SF_FPAddArray(variable mainId, string jsonPath, variable subId, variable arrayWasCreated)

	variable tmpId

	if(JSON_GetType(subId, "") != JSON_ARRAY || !arrayWasCreated)

		tmpId = JSON_New()
		JSON_AddTreeArray(tmpId, "")
		JSON_AddJSON(tmpId, "", subId)

		JSON_AddJSON(mainId, jsonPath, tmpId)
		JSON_Release(tmpId)
	else
		JSON_AddJSON(mainId, jsonPath, subId)
	endif

	JSON_Release(subId)
End

/// @brief add escape characters to a path element
static Function/S SF_EscapeJsonPath(string str)

	return ReplaceString("/", str, "~1")
End

/// @brief Execute the formula parsed by SF_FormulaParser
///
/// Recursively executes the formula parsed into jsonID.
///
/// @param jsonID   JSON object ID from the JSON XOP
/// @param jsonPath JSON pointer compliant path
/// @param graph    graph to read from, mainly used by the `data` operation
Function/WAVE SF_FormulaExecutor(variable jsonID, [string jsonPath, string graph])

	string opName
	variable JSONType, i

	if(ParamIsDefault(jsonPath))
		jsonPath = ""
	endif
	if(ParamIsDefault(graph))
		graph = ""
	endif

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		printf "##########################\r"
		printf "%s\r", JSON_Dump(jsonID, indent = 2)
		printf "##########################\r"
	endif
#endif

	// object and array evaluation
	JSONtype = JSON_GetType(jsonID, jsonPath)
	if(JSONtype == JSON_NUMERIC)
		Make/FREE out = { JSON_GetVariable(jsonID, jsonPath) }
		return out
	elseif(JSONtype == JSON_STRING)
		Make/FREE/T outT = { JSON_GetString(jsonID, jsonPath) }
		return outT
	elseif(JSONtype == JSON_ARRAY)
		WAVE topArraySize = JSON_GetMaxArraySize(jsonID, jsonPath)
		Make/FREE/N=(topArraySize[0])/B types = JSON_GetType(jsonID, jsonPath + "/" + num2istr(p))

		if(topArraySize[0] != 0 && types[0] == JSON_STRING)
			SF_ASSERT(DimSize(topArraySize, ROWS) <= 1, "Text Waves Must Be 1-dimensional.", jsonId=jsonId)
			return JSON_GetTextWave(jsonID, jsonPath)
		endif
		EXTRACT/FREE types, strings, types[p] == JSON_STRING
		SF_ASSERT(DimSize(strings, ROWS) == 0, "Object evaluation For Mixed Text/Numeric Arrays Is Not Allowed", jsonId=jsonId)
		WaveClear strings

		SF_ASSERT(DimSize(topArraySize, ROWS) < 4, "Unhandled Data Alignment. Only 3 Dimensions Are Supported For Operations.", jsonId=jsonId)
		WAVE out = JSON_GetWave(jsonID, jsonPath)

		Redimension/N=4 topArraySize
		topArraySize[] = topArraySize[p] != 0 ? topArraySize[p] : 1
		Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])/E=1 out

		EXTRACT/FREE/INDX types, indices, (types[p] == JSON_OBJECT) || (types[p] == JSON_ARRAY)
		if(DimSize(indices, ROWS) == 1 && DimSize(out, ROWS) == 1)
			return SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2istr(indices[0]), graph = graph)
		endif
		for(i = 0; i < DimSize(indices, ROWS); i += 1)
			WAVE element = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2istr(indices[i]), graph = graph)
			if(DimSize(element, CHUNKS) > 1)
				DebugPrint("Merging Chunks To Layers for object: " + jsonPath + "/" + num2istr(indices[i]))
				Redimension/N=(-1, -1, max(1, DimSize(element, LAYERS)) * DimSize(element, CHUNKS), 0)/E=1 element
			endif
			topArraySize[1,*] = max(topArraySize[p], DimSize(element, p - 1))
			if((DimSize(out, ROWS)   < topArraySize[0]) || \
			   (DimSize(out, COLS)   < topArraySize[1]) || \
			   (DimSize(out, LAYERS) < topArraySize[2]) || \
			   (DimSize(out, CHUNKS) < topArraySize[3]))
				Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3]) out
			endif
			SF_FormulaWaveScaleTransfer(element, out, ROWS, COLS)
			SF_FormulaWaveScaleTransfer(element, out, COLS, LAYERS)
			SF_FormulaWaveScaleTransfer(element, out, LAYERS, CHUNKS)
			Multithread out[indices[i]][0, max(0, DimSize(element, ROWS) - 1)][0, max(0, DimSize(element, COLS) - 1)][0, max(0, DimSize(element, LAYERS) - 1)] = element[q][r][s]
		endfor

		EXTRACT/FREE/INDX types, indices, types[p] == JSON_NUMERIC
		for(i = 0; i < DimSize(indices, ROWS); i += 1)
			Multithread out[indices[i]][][][] = out[indices[i]][0][0][0]
		endfor

		topArraySize[1,*] = topArraySize[p] == 1 ? 0 : topArraySize[p]
		Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])/E=1 out

		return out
	endif

	// operation evaluation
	SF_ASSERT(JSONtype == JSON_OBJECT, "Topmost element needs to be an object", jsonId=jsonId)
	WAVE/T operations = JSON_GetKeys(jsonID, jsonPath)
	SF_ASSERT(DimSize(operations, ROWS) == 1, "Only one operation is allowed", jsonId=jsonId)
	jsonPath += "/" + SF_EscapeJsonPath(operations[0])
	SF_ASSERT(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY, "An array is required to hold the operands of the operation.", jsonId=jsonId)

	opName = LowerStr(operations[0])
#ifdef AUTOMATED_TESTING
	strswitch(opName)
		case SF_OP_MINUS:
		case SF_OP_PLUS:
		case SF_OP_DIV:
		case SF_OP_MULT:
		case SF_OP_RANGESHORT:
			break
		default:
			WAVE ops = SF_GetNamedOperations()
			ASSERT(GetRowIndex(ops, str = opName) >= 0, "List of operations with long name is out of date")
			break
	endswitch
#endif

	/// @name SweepFormulaOperations
	/// @{
	strswitch(opName)
		case SF_OP_MINUS:
			WAVE out = SF_OperationMinus(jsonId, jsonPath, graph)
			break
		case SF_OP_PLUS:
			WAVE out = SF_OperationPlus(jsonId, jsonPath, graph)
			break
		case SF_OP_DIV: // division
			WAVE out = SF_OperationDiv(jsonId, jsonPath, graph)
			break
		case SF_OP_MULT:
			WAVE out = SF_OperationMult(jsonId, jsonPath, graph)
			break
		case SF_OP_RANGE:
		case SF_OP_RANGESHORT:
			WAVE out = SF_OperationRange(jsonId, jsonPath, graph)
			break
		case SF_OP_MIN:
			WAVE out = SF_OperationMin(jsonId, jsonPath, graph)
			break
		case SF_OP_MAX:
			WAVE out = SF_OperationMax(jsonId, jsonPath, graph)
			break
		case SF_OP_AVG:
		case SF_OP_MEAN:
			WAVE out = SF_OperationAvg(jsonId, jsonPath, graph)
			break
		case SF_OP_RMS:
			WAVE out = SF_OperationRMS(jsonId, jsonPath, graph)
			break
		case SF_OP_VARIANCE:
			WAVE out = SF_OperationVariance(jsonId, jsonPath, graph)
			break
		case SF_OP_STDEV:
			WAVE out = SF_OperationStdev(jsonId, jsonPath, graph)
			break
		case SF_OP_DERIVATIVE:
			WAVE out = SF_OperationDerivative(jsonId, jsonPath, graph)
			break
		case SF_OP_INTEGRATE:
			WAVE out = SF_OperationIntegrate(jsonId, jsonPath, graph)
			break
		case SF_OP_EPOCHS:
			WAVE out = SF_OperationEpochs(jsonId, jsonPath, graph)
			break
		case SF_OP_AREA:
			WAVE out = SF_OperationArea(jsonId, jsonPath, graph)
			break
		case SF_OP_BUTTERWORTH:
			WAVE out = SF_OperationButterworth(jsonId, jsonPath, graph)
			break
		case SF_OP_TIME:
		case SF_OP_XVALUES:
			WAVE out = SF_OperationXValues(jsonId, jsonPath, graph)
			break
		case SF_OP_TEXT:
			WAVE out = SF_OperationText(jsonId, jsonPath, graph)
			break
		case SF_OP_SETSCALE:
			WAVE out = SF_OperationSetScale(jsonId, jsonPath, graph)
			break
		case SF_OP_WAVE:
			WAVE out = SF_OperationWave(jsonId, jsonPath, graph)
			break
		case SF_OP_MERGE:
			WAVE out = SF_OperationMerge(jsonId, jsonPath, graph)
			break
		case SF_OP_CHANNELS:
			WAVE out = SF_OperationChannels(jsonId, jsonPath, graph)
			break
		case SF_OP_SWEEPS:
			WAVE out = SF_OperationSweeps(jsonId, jsonPath, graph)
			break
		case SF_OP_DATA:
			WAVE out = SF_OperationData(jsonId, jsonPath, graph)
			break
		case SF_OP_LABNOTEBOOK:
			WAVE out = SF_OperationLabnotebook(jsonId, jsonPath, graph)
			break
		case SF_OP_LOG: // JSON logic debug operation
			WAVE out = SF_OperationLog(jsonId, jsonPath, graph)
			break
		case SF_OP_LOG10: // decadic logarithm
			WAVE out = SF_OperationLog10(jsonId, jsonPath, graph)
			break
		case SF_OP_CURSORS:
			WAVE out = SF_OperationCursors(jsonId, jsonPath, graph)
			break
		case SF_OP_FINDLEVEL:
			WAVE out = SF_OperationFindLevel(jsonId, jsonPath, graph)
			break
		case SF_OP_APFREQUENCY:
			WAVE out = SF_OperationApFrequency(jsonId, jsonPath, graph)
			break
		case SF_OP_TP:
			WAVE out = SF_OperationTP(jsonId, jsonPath, graph)
			break
		case SF_OP_STORE:
			WAVE out = SF_OperationStore(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECT:
			WAVE out = SF_OperationSelect(jsonId, jsonPath, graph)
			break
		default:
			SF_ASSERT(0, "Undefined Operation", jsonId=jsonId)
	endswitch
	/// @}

	return out
End

static Function [WAVE/WAVE formulaResults, string dataType] SF_GatherFormulaResults(string xFormula, string yFormula, string graph)

	variable i, index, numResultsY, numResultsX, numFormulaPairs, xRefIndex

	WAVE/WAVE formulaResults = GetFormulaGatherWave()

	WAVE/WAVE/Z wvXRef = $""
	if(!IsEmpty(xFormula))
		WAVE/WAVE wvXRef = SF_ExecuteFormula(xFormula, graph)
		SF_ASSERT(WaveExists(wvXRef), "x part of formula returned no result.")
	endif
	WAVE/WAVE wvYRef = SF_ExecuteFormula(yFormula, graph)
	SF_ASSERT(WaveExists(wvYRef), "y part of formula returned no result.")
	numResultsY = DimSize(wvYRef, ROWS)
	if(WaveExists(wvXRef))
		numResultsX = DimSize(wvXRef, ROWS)
		SF_ASSERT(numResultsX == numResultsY || numResultsX == 1, "X-Formula data not fitting to Y-Formula.")
	endif
	EnsureLargeEnoughWave(formulaResults, minimumSize=index + numResultsY)
	dataType = GetStringFromJSONWaveNote(wvYRef, SF_META_DATATYPE)
	for(i = 0; i < numResultsY; i += 1)
		if(WaveExists(wvXRef))
			formulaResults[index][%FORMULAX] = wvXRef[numResultsX == 1 ? 0 : i]
		endif
		formulaResults[index][%FORMULAY] = wvYRef[i]
		index += 1
	endfor
	Redimension/N=(index, -1) formulaResults

	return [formulaResults, dataType]
End

static Function/S SF_GetMetaDataAnnotationText(string dataType, WAVE data, string traceName)

	variable channelNumber, channelType, sweepNo
	string annotation, channelId
	string traceAnnotation = ""

	if(!CmpStr(dataType, SF_DATATYPE_SWEEP))
		channelNumber = GetNumberFromJSONWaveNote(data, SF_META_CHANNELNUMBER)
		channelType = GetNumberFromJSONWaveNote(data, SF_META_CHANNELTYPE)
		sweepNo = GetNumberFromJSONWaveNote(data, SF_META_SWEEPNO)
		channelId = StringFromList(channelType, XOP_CHANNEL_NAMES) + num2istr(channelNumber)
		sprintf traceAnnotation, "Sweep %d %s", sweepNo, channelId
	endif

	annotation = "\\s(" + traceName + ") " + traceAnnotation + "\r"

	return annotation
End

static Function [STRUCT RGBColor s] SF_GetTraceColor(string graph, string dataType, WAVE data)

	variable channelNumber, channelType, sweepNo, headstage

	s.red = 0xFFFF
	s.green = 0x0000
	s.blue = 0x0000

	if(!CmpStr(dataType, SF_DATATYPE_SWEEP))
		channelNumber = GetNumberFromJSONWaveNote(data, SF_META_CHANNELNUMBER)
		channelType = GetNumberFromJSONWaveNote(data, SF_META_CHANNELTYPE)
		sweepNo = GetNumberFromJSONWaveNote(data, SF_META_SWEEPNO)

		WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
		if(WaveExists(numericalValues))
			headstage = GetHeadstageForChannel(numericalValues, sweepNo, channelType, channelNumber, DATA_ACQUISITION_MODE)
			[s] = GetHeadstageColor(headstage)
		endif
	endif
End

static Function/S SF_CreateTraceName(variable dataNum, variable &traceNum)

	string traceName

	traceName = SF_PLOTTER_TRACENAME + "_" + num2istr(dataNum) + "_" + num2istr(traceNum)
	traceNum += 1

	return traceName
End

static Function/S SF_PreparePlotterSubwindows(string win, variable numGraphs)

	variable i, guidePos
	string panelName, guideName1

	KillWindow/Z $win
	NewPanel/N=$win
	panelName = S_name
	NVAR JSONid = $GetSettingsJSONid()
	PS_InitCoordinates(JSONid, panelName, "sweepformula_" + panelName)
	for(i = 0; i < numGraphs + 1; i += 1)
		guideName1 = SF_PLOTTER_GUIDENAME + num2istr(i)
		guidePos = i / numGraphs
		DefineGuide $guideName1={FT, guidePos, FB}
	endfor

	SetWindow $panelName hook(resetScaling)=IH_ResetScaling

	return panelName
End

/// @brief  Plot the formula using the data from graph
///
/// @param graph  graph to pass to SF_FormulaExecutor
/// @param formula formula to plot
/// @param dfr     [optional, default current] working dataFolder
/// @param dmMode  [optional, default DM_SUBWINDOWS] display mode that defines how multiple sweepformula graphs are arranged
static Function SF_FormulaPlotter(string graph, string formula, [DFREF dfr, variable dmMode])

	string trace, dataType
	variable i, j, k, numTraces, splitTraces, splitY, splitX, numGraphs, numWins, numData, dataCnt, traceCnt
	variable dim1Y, dim2Y, dim1X, dim2X, winDisplayMode
	variable xMxN, yMxN, xPoints, yPoints
	string win, wList, winNameTemplate, exWList, wName, guideName1, guideName2, panelName, annotation
	STRUCT RGBColor color

	winDisplayMode = ParamIsDefault(dmMode) ? SF_DM_SUBWINDOWS : dmMode
	ASSERT(winDisplaymode == SF_DM_NORMAL || winDisplaymode == SF_DM_SUBWINDOWS, "Invalid display mode.")

	if(ParamIsDefault(dfr))
		dfr = GetDataFolderDFR()
	endif

	WAVE/T graphCode = SF_SplitCodeToGraphs(formula)
	WAVE/T/Z formulaPairs = SF_SplitGraphsToFormulas(graphCode)
	SF_Assert(WaveExists(formulaPairs), "Could not determine y [vs x] formula pair.")

	DFREF dfrWork = SF_GetWorkingDF(graph)
	KillOrMoveToTrash(dfr=dfrWork)

	numGraphs = DimSize(formulaPairs, ROWS)
	wList = ""
	winNameTemplate = SF_GetFormulaWinNameTemplate(graph)
	if(winDisplayMode == SF_DM_SUBWINDOWS)
		panelName = SF_PreparePlotterSubwindows(winNameTemplate, numGraphs)
	endif

	for(j = 0; j < numGraphs; j += 1)

		annotation = ""
		traceCnt = 0
		WAVE/Z wvX

		win = winNameTemplate + num2istr(j)
		if(winDisplayMode == SF_DM_NORMAL)
			if(!WindowExists(win))
				Display/N=$win as win
				win = S_name
				NVAR JSONid = $GetSettingsJSONid()
				PS_InitCoordinates(JSONid, win, "sweepformula_" + win)
				SetWindow $win hook(resetScaling)=IH_ResetScaling
			endif
			wList = AddListItem(win, wList)
		elseif(winDisplayMode == SF_DM_SUBWINDOWS)
			guideName1 = SF_PLOTTER_GUIDENAME + num2istr(j)
			guideName2 = SF_PLOTTER_GUIDENAME + num2istr(j + 1)
			Display/HOST=$panelName/FG=(FL, $guideName1, FR, $guideName2)/N=$win
			win = panelName + "#" + S_name
		endif

		WAVE/T/Z cursorInfos = GetCursorInfos(win)
		WAVE axesRanges = GetAxesRanges(win)
		RemoveTracesFromGraph(win)
		ModifyGraph/W=$win swapXY = 0

		WAVE/WAVE/Z formulaResults
		[formulaResults, dataType] = SF_GatherFormulaResults(formulaPairs[j][%FORMULA_X], formulaPairs[j][%FORMULA_Y], graph)
		numData = DimSize(formulaResults, ROWS)
		for(k = 0; k < numData; k += 1)

			WAVE/Z wvResultX = formulaResults[k][%FORMULAX]
			WAVE/Z wvResultY = formulaResults[k][%FORMULAY]
			if(!WaveExists(wvResultY))
				continue
			endif

			[color] = SF_GetTraceColor(graph, dataType, wvResultY)

			if(WaveExists(wvResultX))

				xPoints = DimSize(wvResultX, ROWS)
				dim1X = max(1, DimSize(wvResultX, COLS))
				dim2X = max(1, DimSize(wvResultX, LAYERS))
				xMxN = dim1X * dim2X
				if(xMxN)
					Redimension/N=(-1, xMxN)/E=1 wvResultX
				endif

				WAVE wvX = GetSweepFormulaX(dfr, dataCnt)
				if(WaveType(wvResultX, 1) == WaveType(wvX, 1))
					Duplicate/O wvResultX $GetWavesDataFolder(wvX, 2)
				else
					MoveWaveWithOverWrite(wvX, wvResultX)
				endif
				WAVE wvX = GetSweepFormulaX(dfr, dataCnt)
			endif

			yPoints = DimSize(wvResultY, ROWS)
			dim1Y = max(1, DimSize(wvResultY, COLS))
			dim2Y = max(1, DimSize(wvResultY, LAYERS))
			yMxN = dim1Y * dim2Y
			if(yMxN)
				Redimension/N=(-1, yMxN)/E=1 wvResultY
			endif

			WAVE wvY = GetSweepFormulaY(dfr, dataCnt)
			if(WaveType(wvResultY, 1) == WaveType(wvY, 1))
				Duplicate/O wvResultY $GetWavesDataFolder(wvY, 2)
			else
				MoveWaveWithOverWrite(wvY, wvResultY)
			endif
			WAVE wvY = GetSweepFormulaY(dfr, dataCnt)
			SF_Assert(!(IsTextWave(wvY) && IsTextWave(wvX)), "One wave needs to be numeric for plotting")

			if(IsTextWave(wvY) && WaveExists(wvX))
				SF_Assert(WaveExists(wvX), "Cannot plot a single text wave")
				ModifyGraph/W=$win swapXY = 1
				WAVE dummy = wvY
				WAVE wvY = wvX
				WAVE wvX = dummy
			endif

			if(!WaveExists(wvX))
				numTraces = yMxN
				for(i = 0; i < numTraces; i += 1)
					trace = SF_CreateTraceName(k, traceCnt)
					AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][i]/TN=$trace
					annotation += SF_GetMetaDataAnnotationText(dataType, wvResultY, trace)
				endfor
			elseif((xMxN == 1) && (yMxN == 1)) // 1D
				if(yPoints == 1) // 0D vs 1D
					numTraces = xPoints
					for(i = 0; i < numTraces; i += 1)
						trace = SF_CreateTraceName(k, traceCnt)
						AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][0]/TN=$trace vs wvX[i][]
						annotation += SF_GetMetaDataAnnotationText(dataType, wvResultY, trace)
					endfor
				elseif(xPoints == 1) // 1D vs 0D
					numTraces = yPoints
					for(i = 0; i < numTraces; i += 1)
						trace = SF_CreateTraceName(k, traceCnt)
						AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[i][]/TN=$trace vs wvX[][0]
						annotation += SF_GetMetaDataAnnotationText(dataType, wvResultY, trace)
					endfor
				else // 1D vs 1D
					splitTraces = min(yPoints, xPoints)
					numTraces = floor(max(yPoints, xPoints) / splitTraces)
					if(mod(max(yPoints, xPoints), splitTraces) == 0)
						DebugPrint("Unmatched Data Alignment in ROWS.")
					endif
					for(i = 0; i < numTraces; i += 1)
						trace = SF_CreateTraceName(k, traceCnt)
						splitY = SF_SplitPlotting(wvY, ROWS, i, splitTraces)
						splitX = SF_SplitPlotting(wvX, ROWS, i, splitTraces)
						AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[splitY, splitY + splitTraces - 1][0]/TN=$trace vs wvX[splitX, splitX + splitTraces - 1][0]
						annotation += SF_GetMetaDataAnnotationText(dataType, wvResultY, trace)
					endfor
				endif
			elseif(yMxN == 1) // 1D vs 2D
				numTraces = xMxN
				for(i = 0; i < numTraces; i += 1)
					trace = SF_CreateTraceName(k, traceCnt)
					AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][0]/TN=$trace vs wvX[][i]
					annotation += SF_GetMetaDataAnnotationText(dataType, wvResultY, trace)
				endfor
			elseif(xMxN == 1) // 2D vs 1D or 0D
				if(xPoints == 1) // 2D vs 0D -> extend X to 1D with constant value
					Redimension/N=(yPoints) wvX
					xPoints = yPoints
					wvX = wvX[0]
				endif
				numTraces = yMxN
				for(i = 0; i < numTraces; i += 1)
					trace = SF_CreateTraceName(k, traceCnt)
					AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][i]/TN=$trace vs wvX
					annotation += SF_GetMetaDataAnnotationText(dataType, wvResultY, trace)
				endfor
			else // 2D vs 2D
				numTraces = WaveExists(wvX) ? max(1, max(yMxN, xMxN)) : max(1, yMxN)
				if(yPoints != xPoints)
					DebugPrint("Size mismatch in data rows for plotting waves.")
				endif
				if(DimSize(wvY, COLS) != DimSize(wvX, COLS))
					DebugPrint("Size mismatch in entity columns for plotting waves.")
				endif
				for(i = 0; i < numTraces; i += 1)
					trace = SF_CreateTraceName(k, traceCnt)
					if(WaveExists(wvX))
						AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][min(yMxN - 1, i)]/TN=$trace vs wvX[][min(xMxN - 1, i)]
					else
						AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][i]/TN=$trace
					endif
					annotation += SF_GetMetaDataAnnotationText(dataType, wvResultY, trace)
				endfor
			endif

			if(DimSize(wvY, ROWS) < SF_MAX_NUMPOINTS_FOR_MARKERS \
				&& (!WaveExists(wvX) \
				|| DimSize(wvx, ROWS) <  SF_MAX_NUMPOINTS_FOR_MARKERS))
				ModifyGraph/W=$win mode=3,marker=19
			endif

			dataCnt += 1
		endfor

		if(!IsEmpty(annotation))
			annotation = RemoveEnding(annotation, "\r")
			Legend/W=$win/C/N=metadata/F=0 annotation
		endif

		RestoreCursors(win, cursorInfos)
		SetAxesRanges(win, axesRanges)
	endfor

	if(winDisplayMode == SF_DM_NORMAL)
		exWList = WinList(winNameTemplate + "*", ";", "WIN:1")
		numWins = ItemsInList(exWList)
		for(i = 0; i < numWins; i += 1)
			wName = StringFromList(i, exWList)
			if(WhichListItem(wName, wList) == -1)
				KillWindow/Z $wName
			endif
		endfor
	endif
End

/// @brief utility function for @c SF_FormulaPlotter
///
/// split dimension @p dim of wave @p wv into slices of size @p split and get
/// the starting index @p i
///
static Function SF_SplitPlotting(WAVE wv, variable dim, variable i, variable split)

	return min(i, floor(DimSize(wv, dim) / split) - 1) * split
End

/// @brief Returns a range from a epochName
///
/// @param graph name of databrowser graph
/// @param epochName name epoch
/// @param sweep number of sweep
/// @param channel number of DA channel
/// @returns a 1D wave with two elements, [startTime, endTime] in ms, if no epoch could be resolved [NaN, NaN] is returned
static Function/WAVE SF_GetRangeFromEpoch(string graph, string epochName, variable sweep, variable channel)

	string regex
	variable numEpochs

	Make/FREE/D range = {NaN, NaN}
	if(IsEmpty(epochName) || !IsValidSweepNumber(sweep))
		return range
	endif

	WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweep)
	if(!WaveExists(numericalValues))
		return range
	endif

	WAVE/Z textualValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweep)
	if(!WaveExists(textualValues))
		return range
	endif

	regex = "^" + epochName + "$"
	WAVE/T/Z epochs = EP_GetEpochs(numericalValues, textualValues, sweep, XOP_CHANNEL_TYPE_DAC, channel, regex)
	if(!WaveExists(epochs))
		return range
	endif
	numEpochs = DimSize(epochs, ROWS)
	SF_ASSERT(numEpochs <= 1, "Found several fitting epochs. Currently only a single epoch is supported")
	if(numEpochs == 0)
		return range
	endif

	range[0] = str2num(epochs[0][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
	range[1] = str2num(epochs[0][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI

	return range
End

static Function SF_GetDAChannel(string graph, variable sweep, variable channelType, variable channelNumber)

	variable DAC, index

	WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweep)
	if(!WaveExists(numericalValues))
		return NaN
	endif
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweep, "DAC", channelNumber, channelType, DATA_ACQUISITION_MODE)
	if(WaveExists(settings))
		DAC = settings[index]
		ASSERT(IsFinite(DAC) && index < NUM_HEADSTAGES, "Only associated channels are supported.")
		return DAC
	endif

	return NaN
End

static Function/WAVE SF_GetSweepsForFormula(string graph, WAVE range, WAVE/Z selectData, string opShort)

	variable i, rangeStart, rangeEnd, DAChannel, sweepNo
	variable chanNr, chanType, cIndex, isSweepBrowser
	variable numSelected, index
	string dimLabel, device, dataFolder, epochName

	ASSERT(WindowExists(graph), "graph window does not exist")

	SF_ASSERT(DimSize(range, COLS) == 0, "Range must be a 1d wave.")
	if(IsTextWave(range))
		SF_ASSERT(DimSize(range, ROWS) == 1, "A epoch range must be a single string with the epoch name.")
		WAVE/T wEpochName = range
		epochName = wEpochName[0]
	else
		SF_ASSERT(DimSize(range, ROWS) == 2, "A numerical range is must have two rows for range start and end.")
	endif
	if(!WaveExists(selectData))
		WAVE/WAVE output = SF_CreateSFRefWave(graph, opShort, 0)
		SetStringInJSONWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_SWEEP)
		return output
	endif
	SF_ASSERT(DimSize(selectData, COLS) == 3, "Select data must have 3 columns.")

	numSelected = DimSize(selectData, ROWS)
	WAVE/WAVE output = SF_CreateSFRefWave(graph, opShort, numSelected)

	isSweepBrowser = BSP_IsSweepBrowser(graph)

	if(isSweepBrowser)
		DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
		WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)
	else
		SF_ASSERT(BSP_HasBoundDevice(graph), "No device bound.")
		device = BSP_GetDevice(graph)
		DFREF deviceDFR = GetDeviceDataPath(device)
	endif

	for(i = 0; i < numSelected; i += 1)

		sweepNo = selectData[i][%SWEEP]
		chanNr = selectData[i][%CHANNELNUMBER]
		chanType = selectData[i][%CHANNELTYPE]

		if(isSweepBrowser)
			cIndex = FindDimLabel(sweepMap, COLS, "Sweep")
			FindValue/RMD=[][cIndex]/TEXT=num2istr(sweepNo)/TXOP=4 sweepMap
			if(V_value == -1)
				continue
			endif
			dataFolder = sweepMap[V_row][%DataFolder]
			device     = sweepMap[V_row][%Device]
			DFREF deviceDFR  = GetAnalysisSweepPath(dataFolder, device)
		else
			if(DB_SplitSweepsIfReq(graph, sweepNo))
				continue
			endif
		endif

		DFREF sweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)

		WAVE/Z sweep = GetDAQDataSingleColumnWave(sweepDFR, chanType, chanNr)
		if(!WaveExists(sweep))
			continue
		endif

		if(WaveExists(wEpochName))
			DAChannel = SF_GetDAChannel(graph, sweepNo, chanType, chanNr)
			WAVE range = SF_GetRangeFromEpoch(graph, epochName, sweepNo, DAChannel)
		endif
		rangeStart = range[0]
		rangeEnd = range[1]

		SF_ASSERT(!IsNaN(rangeStart) && !IsNaN(rangeEnd), "Specified range not valid.")
		SF_ASSERT(rangeStart == -inf || (IsFinite(rangeStart) && rangeStart >= leftx(sweep) && rangeStart < rightx(sweep)), "Specified starting range not inside sweep " + num2istr(sweepNo) + ".")
		SF_ASSERT(rangeEnd == inf || (IsFinite(rangeEnd) && rangeEnd >= leftx(sweep) && rangeEnd < rightx(sweep)), "Specified ending range not inside sweep " + num2istr(sweepNo) + ".")
		Duplicate/FREE/R=(rangeStart, rangeEnd) sweep, rangedSweepData

		SetNumberInJSONWaveNote(rangedSweepData, SF_META_SWEEPNO, sweepNo)
		SetNumberInJSONWaveNote(rangedSweepData, SF_META_CHANNELTYPE, chanType)
		SetNumberInJSONWaveNote(rangedSweepData, SF_META_CHANNELNUMBER, chanNr)

		output[index] = rangedSweepData
		index += 1
	endfor
	Redimension/N=(index) output

	SetStringInJSONWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_SWEEP)

	return output
End

/// @brief Returns the Unique numeric entries as free 1d wave from a column of a 2d wave, where the column is identified by its dimension label
static Function/WAVE SF_GetReducedColumn(WAVE w, string dimLabel)

	variable dimPos

	dimPos = FindDimLabel(w, COLS, dimLabel)
	SF_ASSERT(dimPos >= 0, "Columns with dimLabel " + dimlabel + " not found.")
	Duplicate/FREE/RMD=[][dimPos] w, wTmp
	Redimension/N=(-1) wTmp

	WAVE wReduced = GetUniqueEntries(wTmp, dontDuplicate=1)

	return wReduced
End

/// @brief Converts from a 1d wave of selected sweeps/channel type/channel number to a 2d wave that
///        holds the old channel layout where all selected channel type + channel number combinations appear exactly once
///        independent of the sweep number.
///        Converts also from a 1d wave of selected sweeps/channel type/channel to a 1d wave that
///        holds the old sweeps layout, where all selected sweep numbers appear exactly once.
///        Note: The association between sweep and channel type + channel number in the original selectData is lost by this back conversion.
static Function [WAVE sweeps, WAVE/D channels] SF_ReCreateOldSweepsChannelLayout(WAVE selectData)

	variable numSelected, numCombined
	variable shift = ceil(log(NUM_AD_CHANNELS) / log(2))

	WAVE sweepsReduced = SF_GetReducedColumn(selectData, "SWEEP")

	numSelected = DimSize(selectData, ROWS)
	Make/FREE/D/N=(numSelected) combined = selectData[p][%CHANNELTYPE] << shift + selectData[p][%CHANNELNUMBER]
	WAVE combReduced = GetUniqueEntries(combined, dontDuplicate=1)

	numCombined = DimSize(combReduced, ROWS)
	WAVE channels = SF_NewChannelsWave(numCombined)
	if(numCombined)
		channels[][%channelType] = combReduced[p] >> shift
		channels[][%channelNumber] = combReduced[p] - channels[p][%channelType] << shift
	endif

	return [sweepsReduced, channels]
End

/// @brief transfer the wave scaling from one wave to another
///
/// Note: wave scale transfer requires wave units for the first wave or second wave
///
/// @param source    Wave whos scaling should get transferred
/// @param dest      Wave that accepts the new scaling
/// @param dimSource dimension of the source wave, if SF_TRANSFER_ALL_DIMS is used then all scales and units are transferred on the same dimensions,
///                  dimDest is ignored in that case, no unit check is applied in that case
/// @param dimDest   dimension of the destination wave
static Function SF_FormulaWaveScaleTransfer(WAVE source, WAVE dest, variable dimSource, variable dimDest)

	string sourceUnit, destUnit

	if(dimSource == SF_TRANSFER_ALL_DIMS)
		CopyScales/P source, dest
		return NaN
	endif

	if(!(WaveDims(source) > dimSource && dimSource >= 0) || !(WaveDims(dest) > dimDest && dimDest >= 0))
		return NaN
	endif

	sourceUnit = WaveUnits(source, dimSource)
	destUnit = WaveUnits(dest, dimDest)

	if(IsEmpty(sourceUnit) && IsEmpty(destUnit))
		return NaN
	endif

	switch(dimDest)
		case ROWS:
			SetScale/P x, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		case COLS:
			SetScale/P y, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		case LAYERS:
			SetScale/P z, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		case CHUNKS:
			SetScale/P t, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		default:
			ASSERT(0, "Invalid dimDest")
	endswitch
End

/// @brief Use the labnotebook information to return the active channel numbers
///        for a given set of sweeps
///
/// @param graph           DataBrowser or SweepBrowser reference graph
/// @param channels        @c SF_FormulaExecutor style @c channels() wave
/// @param sweeps          @c SF_FormulaExecutor style @c sweeps() wave
/// @param fromDisplayed   boolean variable, if set the selectdata is determined from the displayed sweeps
///
/// @return a selectData style wave with three columns
///         containing sweepNumber, channelType and channelNumber
static Function/WAVE SF_GetActiveChannelNumbersForSweeps(string graph, WAVE/Z channels, WAVE/Z sweeps, variable fromDisplayed)

	variable i, j, k, l, channelType, channelNumber, sweepNo, sweepNoT, outIndex
	variable numSweeps, numInChannels, numSettings, maxChannels, activeChannel, numActiveChannels
	variable isSweepBrowser, cIndex
	variable dimPosSweep, dimPosChannelNumber, dimPosChannelType
	variable dimPosTSweep, dimPosTChannelNumber, dimPosTChannelType
	variable numTraces
	string setting, settingList, msg, device, dataFolder, singleSweepDFStr

	if(!WaveExists(sweeps) || !DimSize(sweeps, ROWS))
		return $""
	endif

	if(!WaveExists(channels) || !DimSize(channels, ROWS))
		return $""
	endif

	fromDisplayed = !!fromDisplayed

	if(fromDisplayed)
		WAVE/T/Z traces = GetTraceInfos(graph)
		if(!WaveExists(traces))
			return $""
		endif
		numTraces = DimSize(traces, ROWS)
		dimPosTSweep = FindDimLabel(traces, COLS, "sweepNumber")
		Make/FREE/D/N=(numTraces) displayedSweeps = str2num(traces[p][dimPosTSweep])
		WAVE displayedSweepsUnique = GetUniqueEntries(displayedSweeps, dontDuplicate=1)
		MatrixOp/FREE sweepsDP = fp64(sweeps)
		WAVE/Z sweepsIntersect = GetSetIntersection(sweepsDP, displayedSweepsUnique)
		if(!WaveExists(sweepsIntersect))
			return $""
		endif
		WAVE sweeps = sweepsIntersect
		numSweeps = DimSize(sweeps, ROWS)

		WAVE selectDisplayed = SF_NewSelectDataWave(numTraces, 1)
		dimPosSweep = FindDimLabel(selectDisplayed, COLS, "SWEEP")
		dimPosChannelType = FindDimLabel(selectDisplayed, COLS, "CHANNELTYPE")
		dimPosChannelNumber = FindDimLabel(selectDisplayed, COLS, "CHANNELNUMBER")

		dimPosTChannelType = FindDimLabel(traces, COLS, "channelType")
		dimPosTChannelNumber = FindDimLabel(traces, COLS, "channelNumber")
		for(i = 0; i < numSweeps; i += 1)
			sweepNo = sweeps[i]
			for(j = 0; j < numTraces; j += 1)
				sweepNoT = str2num(traces[j][dimPosTSweep])
				if(sweepNo == sweepNoT)
					selectDisplayed[outIndex][dimPosSweep] = sweepNo
					selectDisplayed[outIndex][dimPosChannelType] = WhichListItem(traces[j][dimPosTChannelType], XOP_CHANNEL_NAMES)
					selectDisplayed[outIndex][dimPosChannelNumber] = str2num(traces[j][dimPosTChannelNumber])
					outIndex += 1
				endif
				if(outIndex == numTraces)
					break
				endif
			endfor
			if(outIndex == numTraces)
				break
			endif
		endfor
		Redimension/N=(outIndex, -1) selectDisplayed
		numTraces = outIndex

		outIndex = 0
	else
		isSweepBrowser = BSP_IsSweepBrowser(graph)
		if(isSweepBrowser)
			DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
			WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)
		else
			SF_ASSERT(BSP_HasBoundDevice(graph), "No device bound.")
			device = BSP_GetDevice(graph)
			DFREF deviceDFR = GetDeviceDataPath(device)
		endif
	endif

	// search sweeps for active channels
	numSweeps = DimSize(sweeps, ROWS)
	numInChannels = DimSize(channels, ROWS)

	WAVE selectData = SF_NewSelectDataWave(numSweeps, NUM_DA_TTL_CHANNELS + NUM_AD_CHANNELS)
	if(!fromDisplayed)
		dimPosSweep = FindDimLabel(selectData, COLS, "SWEEP")
		dimPosChannelType = FindDimLabel(selectData, COLS, "CHANNELTYPE")
		dimPosChannelNumber = FindDimLabel(selectData, COLS, "CHANNELNUMBER")
	endif

	for(i = 0; i < numSweeps; i += 1)
		sweepNo = sweeps[i]

		if(!IsValidSweepNumber(sweepNo))
			continue
		endif

		if(!fromDisplayed)
			if(isSweepBrowser)
				cIndex = FindDimLabel(sweepMap, COLS, "Sweep")
				FindValue/RMD=[][cIndex]/TEXT=num2istr(sweepNo)/TXOP=4 sweepMap
				if(V_value == -1)
					continue
				endif
				dataFolder = sweepMap[V_row][%DataFolder]
				device     = sweepMap[V_row][%Device]
				DFREF deviceDFR  = GetAnalysisSweepPath(dataFolder, device)
			else
				if(DB_SplitSweepsIfReq(graph, sweepNo))
					continue
				endif
			endif
			singleSweepDFStr = GetSingleSweepFolderAsString(deviceDFR, sweepNo)
			if(!DataFolderExists(singleSweepDFStr))
				continue
			endif
			DFREF sweepDFR = $singleSweepDFStr
			WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
			if(!WaveExists(numericalValues))
				continue
			endif
		endif

		for(j = 0; j < numInChannels; j += 1)

			channelType = channels[j][%channelType]
			channelNumber = channels[j][%channelNumber]

			if(IsNaN(channelType))
				settingList = "ADC;DAC;"
			else
				switch(channelType)
					case XOP_CHANNEL_TYPE_DAC:
						settingList = "DAC;"
						break
					case XOP_CHANNEL_TYPE_ADC:
						settingList = "ADC;"
						break
					default:
						sprintf msg, "Unhandled channel type %g in channels() at position %d", channelType, j
						SF_ASSERT(0, msg)
				endswitch
			endif

			numSettings = ItemsInList(settingList)
			for(k = 0; k < numSettings; k += 1)
				setting = StringFromList(k, settingList)
				strswitch(setting)
					case "DAC":
						channelType = XOP_CHANNEL_TYPE_DAC
						maxChannels = NUM_DA_TTL_CHANNELS
						break
					case "ADC":
						channelType = XOP_CHANNEL_TYPE_ADC
						maxChannels = NUM_AD_CHANNELS
						break
					default:
						SF_ASSERT(0, "Unexpected setting entry for channel type resolution.")
						break
				endswitch

				if(fromDisplayed)
					for(l = 0; l < numTraces; l += 1)
						if(IsNaN(channelNumber))
							if(sweepNo == selectDisplayed[l][dimPosSweep] && channelType == selectDisplayed[l][dimPosChannelType])
								activeChannel = selectDisplayed[l][dimPosChannelNumber]
								if(activeChannel < maxChannels)
									selectData[outIndex][dimPosSweep] = sweepNo
									selectData[outIndex][dimPosChannelType] = channelType
									selectData[outIndex][dimPosChannelNumber] = selectDisplayed[l][dimPosChannelNumber]
									outIndex += 1
								endif
							endif
						else
							if(sweepNo == selectDisplayed[l][dimPosSweep] && channelType == selectDisplayed[l][dimPosChannelType] && channelNumber == selectDisplayed[l][dimPosChannelNumber] && channelNumber < maxChannels)
								selectData[outIndex][dimPosSweep] = sweepNo
								selectData[outIndex][dimPosChannelType] = channelType
								selectData[outIndex][dimPosChannelNumber] = channelNumber
								outIndex += 1
							endif
						endif
					endfor
				else
					WAVE/Z activeChannels = GetLastSetting(numericalValues, sweepNo, setting, DATA_ACQUISITION_MODE)
					if(!WaveExists(activeChannels))
						continue
					endif
					if(IsNaN(channelNumber))
						// faster than ZapNaNs due to no mem alloc
						numActiveChannels = DimSize(activeChannels, ROWS)
						for(l = 0; l < numActiveChannels; l += 1)
							activeChannel = activeChannels[l]
							if(!IsNaN(activeChannel) && activeChannel < maxChannels)
								selectData[outIndex][dimPosSweep] = sweepNo
								selectData[outIndex][dimPosChannelType] = channelType
								selectData[outIndex][dimPosChannelNumber] = activeChannel
								outIndex += 1
							endif
						endfor
					elseif(channelNumber < maxChannels)
						FindValue/V=(channelNumber) activeChannels
						if(V_Value >= 0)
							selectData[outIndex][dimPosSweep] = sweepNo
							selectData[outIndex][dimPosChannelType] = channelType
							selectData[outIndex][dimPosChannelNumber] = channelNumber
							outIndex += 1
						endif
					endif
				endif

			endfor
		endfor
	endfor
	if(!outIndex)
		return $""
	endif

	Redimension/N=(outIndex, -1) selectData
	WAVE out = SF_SortSelectData(selectData)

	return out
End

static Function/WAVE SF_SortSelectData(WAVE selectData)

	variable dimPosSweep, dimPosChannelType, dimPosChannelNumber

	if(DimSize(selectData, ROWS) >= 1)
		dimPosSweep = FindDimLabel(selectData, COLS, "SWEEP")
		dimPosChannelType = FindDimLabel(selectData, COLS, "CHANNELTYPE")
		dimPosChannelNumber = FindDimLabel(selectData, COLS, "CHANNELNUMBER")

		SortColumns/KNDX={dimPosSweep, dimPosChannelType, dimPosChannelNumber} sortWaves=selectData
	endif

	return selectData
End

/// @brief Pre process code entered into the notebook
///        - unify line endings to CR
///        - remove comments at line ending
///        - cut off last CR from back conversion with TextWaveToList
static Function/S SF_PreprocessInput(string formula)

	variable endsWithCR

	if(IsEmpty(formula))
		return ""
	endif

	formula = NormalizeToEOL(formula, SF_CHAR_CR)
	endsWithCR = StringEndsWith(formula, SF_CHAR_CR)

	WAVE/T lines = ListToTextWave(formula, SF_CHAR_CR)
	lines = StringFromList(0, lines[p], SF_CHAR_COMMENT)
	formula = TextWaveToList(lines, SF_CHAR_CR)
	if(IsEmpty(formula))
		return ""
	endif

	if(!endsWithCR)
		formula = formula[0, strlen(formula) - 2]
	endif

	return formula
End

Function SF_button_sweepFormula_check(STRUCT WMButtonAction &ba) : ButtonControl

	string mainPanel, bsPanel, formula_nb, json_nb, formula, errMsg, text
	variable jsonId

	switch(ba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(ba.win)
			bsPanel = BSP_GetPanel(mainPanel)

			if(!BSP_HasBoundDevice(bsPanel))
				DebugPrint("Unbound device in DataBrowser")
				break
			endif

			DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_PANEL_FOLDER)

			formula_nb = BSP_GetSFFormula(ba.win)
			formula = GetNotebookText(formula_nb, mode=2)

			SF_CheckInputCode(formula, dfr)

			errMsg = ROStr(GetSweepFormulaParseErrorMessage())
			SetValDisplay(bsPanel, "status_sweepFormula_parser", var=IsEmpty(errMsg))
			SetSetVariableString(bsPanel, "setvar_sweepFormula_parseResult", errMsg, setHelp = 1)

			json_nb = BSP_GetSFJSON(mainPanel)
			jsonID = ROVar(GetSweepFormulaJSONid(dfr))
			text = JSON_Dump(jsonID, indent = 2, ignoreErr = 1)
			text = NormalizeToEOL(text, "\r")
			ReplaceNotebookText(json_nb, text)

			break
	endswitch

	return 0
End

/// @brief Checks input code, sets globals for jsonId and error string
static Function SF_CheckInputCode(string code, DFREF dfr)

	variable i, numFormulae, numGraphs, jsonIDy, jsonIDx
	string jsonPath, tmpStr, xFormula

	SVAR errMsg = $GetSweepFormulaParseErrorMessage()
	errMsg = ""

	NVAR jsonID = $GetSweepFormulaJSONid(dfr)
	JSON_Release(jsonID, ignoreErr = 1)
	jsonID = JSON_New()
	JSON_AddObjects(jsonID, "")

	WAVE/T graphCode = SF_SplitCodeToGraphs(SF_PreprocessInput(code))
	WAVE/T/Z formulaPairs = SF_SplitGraphsToFormulas(graphCode)
	if(!WaveExists(formulaPairs))
		errMsg = "Could not determine y [vs x] formula pair."
		return NaN
	endif

	numGraphs = DimSize(formulaPairs, ROWS)
	for(i = 0; i < numGraphs; i += 1)
		jsonPath = "/Formula_" + num2istr(i)
		JSON_AddObjects(jsonID, jsonPath)

		// catch Abort from SF_Assert called from SF_FormulaParser
		try
			jsonIDy = SF_FormulaParser(SF_FormulaPreParser(formulaPairs[i][%FORMULA_Y]))
		catch
			JSON_Release(jsonID, ignoreErr = 1)
			return NaN
		endtry
		JSON_AddJSON(jsonID, jsonPath + "/y", jsonIDy)
		JSON_Release(jsonIDy)

		xFormula = formulaPairs[i][%FORMULA_X]
		if(!IsEmpty(xFormula))
			// catch Abort from SF_Assert called from SF_FormulaParser
			try
				jsonIDx = SF_FormulaParser(SF_FormulaPreParser(xFormula))
			catch
				JSON_Release(jsonID, ignoreErr = 1)
				return NaN
			endtry
			JSON_AddJSON(jsonID, jsonPath + "/x", jsonIDx)
			JSON_Release(jsonIDx)
		endif
	endfor
End

Function SF_Update(string graph)
	string bsPanel = BSP_GetPanel(graph)

	if(!SF_IsActive(bsPanel))
		return NaN
	endif

	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")
End

/// @brief checks if SweepFormula (SF) is active.
Function SF_IsActive(string win)

	return BSP_IsActive(win, MIES_BSP_SF)
End

/// @brief Return the sweep formula code in raw and with all necessary preprocesssing
Function [string raw, string preProc] SF_GetCode(string win)
	string formula_nb, code

	formula_nb = BSP_GetSFFormula(win)
	code = GetNotebookText(formula_nb,mode=2)

	return [code, SF_PreprocessInput(code)]
End

Function SF_button_sweepFormula_display(STRUCT WMButtonAction &ba) : ButtonControl

	string mainPanel, rawCode, bsPanel, preProcCode

	switch(ba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(ba.win)
			bsPanel = BSP_GetPanel(mainPanel)

			[rawCode, preProcCode] = SF_GetCode(mainPanel)

			if(IsEmpty(preProcCode))
				break
			endif

			if(!BSP_HasBoundDevice(bsPanel))
				DebugPrint("Databrowser has unbound device")
				break
			endif

			DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_PANEL_FOLDER)

			SVAR result = $GetSweepFormulaParseErrorMessage()
			result = ""

			SetSetVariableString(bsPanel, "setvar_sweepFormula_parseResult", "", setHelp = 1)
			SetValDisplay(bsPanel, "status_sweepFormula_parser", var=1)

			// catch Abort from SF_ASSERT
			try
				SF_FormulaPlotter(mainPanel, preProcCode, dfr = dfr); AbortOnRTE

				[WAVE/T keys, WAVE/T values] = SF_CreateResultsWaveWithCode(mainPanel, rawCode)

				ED_AddEntriesToResults(values, keys, UNKNOWN_MODE)
			catch
				SetValDisplay(bsPanel, "status_sweepFormula_parser", var=0)
				SetSetVariableString(bsPanel, "setvar_sweepFormula_parseResult", result, setHelp = 1)
			endtry

			break
	endswitch

	return 0
End

static Function/S SF_PrepareDataForResultsWave(WAVE data)
	variable numEntries, maxEntries

	if(IsNumericWave(data))
		Make/T/FREE/N=(DimSize(data, ROWS), DimSize(data, COLS), DimSize(data, LAYERS), DimSize(data, CHUNKS)) dataTxT
		MultiThread dataTxT[][][][] = num2strHighPrec(data[p][q][r][s], precision = MAX_DOUBLE_PRECISION, shorten = 1)
	else
		WAVE/T dataTxT = data
	endif

	// assuming 100 sweeps on average
	maxEntries = 100 * NUM_HEADSTAGES * 10 // NOLINT
	numEntries = numpnts(dataTxT)

	if(numpnts(dataTxT) > maxEntries)
		printf "The store operation received too much data to store, it will only store the first %d entries\r.", maxEntries
		ControlWindowToFront()
		numEntries = maxEntries
	endif

	return TextWaveToList(dataTxT, ";", maxElements = numEntries)
End

static Function [WAVE/T keys, WAVE/T values] SF_CreateResultsWaveWithCode(string graph, string code, [WAVE data, string name])
	variable numEntries, numOptParams, hasStoreEntry, numCursors, numBasicEntries
	string shPanel, dataFolder, device

	numOptParams = ParamIsDefault(data) + ParamIsDefault(name)
	ASSERT(numOptParams == 0 || numOptParams == 2, "Invalid optional parameters")
	hasStoreEntry = (numOptParams == 0)

	ASSERT(!IsEmpty(code), "Unexpected empty code")
	numCursors = ItemsInList(CURSOR_NAMES)
	numBasicEntries = 4
	numEntries = numBasicEntries + numCursors + hasStoreEntry

	Make/T/FREE/N=(1, numEntries) keys
	Make/T/FREE/N=(1, numEntries, LABNOTEBOOK_LAYER_COUNT) values

	keys[0][0]                                                 = "Sweep Formula code"
	keys[0][1]                                                 = "Sweep Formula sweeps/channels"
	keys[0][2]                                                 = "Sweep Formula experiment"
	keys[0][3]                                                 = "Sweep Formula device"
	keys[0][numBasicEntries, numBasicEntries + numCursors - 1] = "Sweep Formula cursor " + StringFromList(q - numBasicEntries, CURSOR_NAMES)

	if(hasStoreEntry)
		SF_ASSERT(IsValidLiberalObjectName(name[0]), "Can not use the given name for the labnotebook key")
		keys[0][numEntries - 1] = "Sweep Formula store [" + name + "]"
	endif

	LBN_SetDimensionLabels(keys, values)

	values[0][%$"Sweep Formula code"][INDEP_HEADSTAGE] = NormalizeToEOL(TrimString(code), "\n")

	WAVE/T/Z cursorInfos = GetCursorInfos(graph)

	WAVE/WAVE selectDataRef = SF_ExecuteFormula("select()", graph)
	WAVE/Z selectData = selectDataRef[0]
	if(WaveExists(selectData))
		values[0][%$"Sweep Formula sweeps/channels"][INDEP_HEADSTAGE] = NumericWaveToList(selectData, ";")
	endif

	shPanel = LBV_GetSettingsHistoryPanel(graph)

	dataFolder = GetPopupMenuString(shPanel, "popup_experiment")
	values[0][%$"Sweep Formula experiment"][INDEP_HEADSTAGE] = dataFolder

	device = GetPopupMenuString(shPanel, "popup_Device")
	values[0][%$"Sweep Formula device"][INDEP_HEADSTAGE] = device

	if(WaveExists(cursorInfos))
		values[0][numBasicEntries, numBasicEntries + numCursors - 1][INDEP_HEADSTAGE] = cursorInfos[q - numBasicEntries]
	endif

	if(hasStoreEntry)
		values[0][numEntries - 1][INDEP_HEADSTAGE] = SF_PrepareDataForResultsWave(data)
	endif

	return [keys, values]
End

Function SF_TabProc_Formula(STRUCT WMTabControlAction &tca) : TabControl

	string mainPanel, bsPanel, json_nb, text
	variable jsonID

	switch( tca.eventCode )
		case 2: // mouse up
			mainPanel = GetMainWindow(tca.win)
			bsPanel = BSP_GetPanel(mainPanel)
			if(tca.tab == 1)
				PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_check")
			elseif(tca.tab == 2)
				BSP_UpdateHelpNotebook(mainPanel)
			endif

			if(!BSP_HasBoundDevice(bsPanel))
				DebugPrint("Databrowser has unbound device")
				break
			endif

			break
	endswitch

	return 0
End

static Function/WAVE SF_FilterEpochs(WAVE/Z epochs, WAVE/Z ignoreTPs)
	variable i, numEntries, index

	if(!WaveExists(epochs))
		return $""
	elseif(!WaveExists(ignoreTPs))
		return epochs
	endif

	// descending sort
	SortColumns/KNDX={0}/R sortWaves={ignoreTPs}

	numEntries = DimSize(ignoreTPs, ROWS)
	for(i = 0; i < numEntries; i += 1)
		index = ignoreTPs[i]
		SF_ASSERT(IsFinite(index), "ignored TP index is non-finite")
		SF_ASSERT(index >=0 && index < DimSize(epochs, ROWS), "ignored TP index is out of range")
		DeletePoints/M=(ROWS) index, 1, epochs
	endfor

	if(DimSize(epochs, ROWS) == 0)
		return $""
	endif

	return epochs
End

// tp(string type[, array selectData[, array ignoreTPs]])
// returns 3D wave in the layout: result x sweeps x channels
static Function/WAVE SF_OperationTP(variable jsonId, string jsonPath, string graph)

	variable numArgs, sweepCnt, activeChannelCnt, i, j, channelNr, channelType, dacChannelNr
	variable sweep, index, numTPEpochs
	variable tpBaseLinePoints, emptyOutput, headstage, outType
	string epShortName, tmpStr, unit, unitKey
	string epochTPRegExp = "^(U_)?TP[[:digit:]]*$"
	string baselineUnit = ""
	STRUCT TPAnalysisInput tpInput

	numArgs = SF_GetNumberOfArguments(jsonId, jsonPath)
	SF_ASSERT(numArgs >= 1 || numArgs <= 3, "tp requires 1 to 3 arguments")

	if(numArgs == 3)
		WAVE ignoreTPs = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2", graph = graph)
		SF_ASSERT(DimSize(ignoreTPs, COLS) < 2, "ignoreTPs must be one-dimensional.")
		SF_ASSERT(IsNumericWave(ignoreTPs), "ignoreTPs parameter must be numeric")
	else
		WAVE/Z ignoreTPs
	endif

	if(numArgs >= 2)
		WAVE selectData = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1", graph = graph)
	else
		WAVE selectData = SF_ExecuteFormula("select()", graph)
	endif
	SF_ASSERT(!SF_IsDefaultEmptyWave(selectData), "No valid sweep/channels combination found.")
	SF_ASSERT(DimSize(selectData, COLS) == 3, "A select input has 3 columns.")
	SF_ASSERT(IsNumericWave(selectData), "select parameter must be numeric")

	WAVE wType = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
	SF_ASSERT(DimSize(wType, ROWS) == 1, "Too many input values for parameter name")
	if(IsTextWave(wType))
		WAVE/T wTypeT = wType
		strswitch(wTypeT[0])
			case SF_OP_TP_TYPE_STATIC:
				outType = SF_OP_TP_TYPE_STATIC_NUM
				break
			case SF_OP_TP_TYPE_INSTANT:
				outType = SF_OP_TP_TYPE_INSTANT_NUM
				break
			case SF_OP_TP_TYPE_BASELINE:
				outType = SF_OP_TP_TYPE_BASELINE_NUM
				break
			default:
				SF_ASSERT(0, "tp: Unknown type.")
		endswitch
	else
		outType = wType[0]
	endif

	WAVE/Z activeChannels
	WAVE/Z sweeps
	[sweeps, activeChannels] = SF_ReCreateOldSweepsChannelLayout(selectData)

	sweepCnt = DimSize(sweeps, ROWS)
	activeChannelCnt = DimSize(activeChannels, ROWS)
	SF_ASSERT(sweepCnt > 0, "Could not find sweeps from given specification.")
	SF_ASSERT(activeChannelCnt > 0, "Could not find any active channel in given sweeps.")

	Make/FREE/D/N=(1, sweepCnt, activeChannelCnt) out = NaN
	emptyOutput = 1

	Duplicate/FREE selectData, singleSelect
	Redimension/N=(1, -1) singleSelect

	WAVE/Z settings
	for(i = 0; i < sweepCnt; i += 1)
		sweep = sweeps[i]

		if(!IsValidSweepNumber(sweep))
			continue
		endif

		WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweep)
		WAVE/Z textualValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweep)
		if(!WaveExists(numericalValues) || !WaveExists(textualValues))
			continue
		endif
		WAVE/Z keyValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_KEYS, sweepNumber=sweep)

		singleSelect[0][%SWEEP] = sweep

		for(j = 0; j < activeChannelCnt; j += 1)

			singleSelect[0][%CHANNELTYPE] = activeChannels[j][%channelType]
			singleSelect[0][%CHANNELNUMBER] = activeChannels[j][%channelNumber]
			WAVE/Z sweepData = SF_GetSweepsForFormula(graph, {-Inf, Inf}, singleSelect, SF_OP_TP)
			if(!WaveExists(sweepData))
				continue
			endif
			SetDimLabel COLS, i, $GetDimLabel(sweepData, COLS, 0), out
			SetDimLabel LAYERS, j, $GetDimLabel(sweepData, LAYERS, 0), out
			Redimension/N=(-1) sweepData

			channelNr = activeChannels[j][%channelNumber]
			channelType = activeChannels[j][%channelType]

			unitKey = ""
			unit = ""
			if(channelType == XOP_CHANNEL_TYPE_DAC)
				unitKey = "DA unit"
			elseif(channelType == XOP_CHANNEL_TYPE_ADC)
				unitKey = "AD unit"
			endif
			if(!IsEmpty(unitKey))
				[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweep, unitKey, channelNr, channelType, DATA_ACQUISITION_MODE)
				SF_ASSERT(WaveExists(settings), "Failed to retrieve channel unit from LBN")
				WAVE/T settingsT = settings
				unit = settingsT[index]
			endif

			headstage = GetHeadstageForChannel(numericalValues, sweep, channelType, channelNr, DATA_ACQUISITION_MODE)
			SF_ASSERT(IsFinite(headstage), "Associated headstage must not be NaN")
			[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweep, "DAC", channelNr, channelType, DATA_ACQUISITION_MODE)
			SF_ASSERT(WaveExists(settings), "Failed to retrieve DAC channels from LBN")
			dacChannelNr = settings[headstage]
			SF_ASSERT(IsFinite(dacChannelNr), "DAC channel number must be finite")

			WAVE/Z epochMatchesAll = EP_GetEpochs(numericalValues, textualValues, sweep, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epochTPRegExp)

			// drop TPs which should be ignored
			// relies on ascending sorting of start times in epochMatches
			WAVE/T/Z epochMatches = SF_FilterEpochs(epochMatchesAll, ignoreTPs)

			if(!WaveExists(epochMatches))
				continue
			endif

			// Use first TP as reference for pulse length and baseline
			epShortName = EP_GetShortName(epochMatches[0][EPOCH_COL_TAGS])
			WAVE/Z/T epochTPPulse = EP_GetEpochs(numericalValues, textualValues, sweep, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epShortName + "_P")
			SF_ASSERT(WaveExists(epochTPPulse) && DimSize(epochTPPulse, ROWS) == 1, "No TP Pulse epoch found for TP epoch")
			WAVE/Z/T epochTPBaseline = EP_GetEpochs(numericalValues, textualValues, sweep, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epShortName + "_B0")
			SF_ASSERT(WaveExists(epochTPBaseline) && DimSize(epochTPBaseline, ROWS) == 1, "No TP Baseline epoch found for TP epoch")
			tpBaseLinePoints = (str2num(epochTPBaseline[0][EPOCH_COL_ENDTIME]) - str2num(epochTPBaseline[0][EPOCH_COL_STARTTIME])) * ONE_TO_MILLI / DimDelta(sweepData, ROWS)

			// Assemble TP data
			WAVE tpInput.data = SF_AverageTPFromSweep(epochMatches, sweepData)
			tpInput.tpLengthPoints = DimSize(tpInput.data, ROWS)
			tpInput.duration = (str2num(epochTPPulse[0][EPOCH_COL_ENDTIME]) - str2num(epochTPPulse[0][EPOCH_COL_STARTTIME])) * ONE_TO_MILLI / DimDelta(sweepData, ROWS)
			tpInput.baselineFrac =  TP_CalculateBaselineFraction(tpInput.duration, tpInput.duration + 2 * tpBaseLinePoints)

			[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweep, CLAMPMODE_ENTRY_KEY, dacChannelNr, XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
			SF_ASSERT(WaveExists(settings), "Failed to retrieve TP Clamp Mode from LBN")
			tpInput.clampMode = settings[index]

			tpInput.clampAmp = NumberByKey("Amplitude", epochTPPulse[0][EPOCH_COL_TAGS], "=")
			SF_ASSERT(IsFinite(tpInput.clampAmp), "Could not find amplitude entry in epoch tags")

			// values not required for calculation result
			tpInput.device = graph

			DFREF dfrTPAnalysis = TP_PrepareAnalysisDF(graph, tpInput)
			DFREF dfrTPAnalysisInput = dfrTPAnalysis:input
			DFREF dfr = TP_TSAnalysis(dfrTPAnalysisInput)
			WAVE tpOutData = dfr:outData

			switch(outType)
				case SF_OP_TP_TYPE_STATIC_NUM:
					out[0][i][j] = tpOutData[%STEADYSTATERES]
					break
				case SF_OP_TP_TYPE_INSTANT_NUM:
					out[0][i][j] = tpOutData[%INSTANTRES]
					break
				case SF_OP_TP_TYPE_BASELINE_NUM:
					out[0][i][j] = tpOutData[%BASELINE]

					if(IsEmpty(baselineUnit))
						baselineUnit = unit
					elseif(CmpStr(baselineUnit, unit))
						baselineUnit = MIXED_UNITS
					endif
					break
				default:
					SF_ASSERT(0, "tp: Unknown type.")
					break
			endswitch

			emptyOutput = 0
		endfor
	endfor

	switch(outType)
		case SF_OP_TP_TYPE_STATIC_NUM:
			SetScale d, 0, 0, "MΩ", out
			break
		case SF_OP_TP_TYPE_INSTANT_NUM:
			SetScale d, 0, 0, "MΩ", out
			break
		case SF_OP_TP_TYPE_BASELINE_NUM:
			if(!CmpStr(baselineUnit, MIXED_UNITS))
				baselineUnit = ""
			endif
			SetScale d, 0, 0, baselineUnit, out
			break
		default:
			SF_ASSERT(0, "tp: Unknown type.")
			break
	endswitch

	if(emptyOutput)
		WAVE out = SF_GetDefaultEmptyWave()
	endif

	return out
End

// epochs(string shortName[, array selectData, [string type]])
// returns 2xN wave for type = range except for a single range result
static Function/WAVE SF_OperationEpochs(variable jsonId, string jsonPath, string graph)

	variable numArgs, i, j, k, epType, sweepCnt, activeChannelCnt, outCnt, index, numEpochs, sweepNo
	string str, epName, epShortName

	numArgs = SF_GetNumberOfArguments(jsonID, jsonPath)
	SF_ASSERT(numArgs >= 1 && numArgs <= 3, "epochs requires at least 1 and at most 3 arguments")

	if(numArgs == 3)
		WAVE/T epochType = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2", graph = graph)
		SF_ASSERT(DimSize(epochType, ROWS) == 1, "Too many input values for parameter type")
		SF_ASSERT(IsTextWave(epochType), "type parameter must be textual")
		strswitch(epochType[0])
			case SF_OP_EPOCHS_TYPE_RANGE:
				epType = EPOCHS_TYPE_RANGE
				break
			case SF_OP_EPOCHS_TYPE_NAME:
				epType = EPOCHS_TYPE_NAME
				break
			case SF_OP_EPOCHS_TYPE_TREELEVEL:
				epType = EPOCHS_TYPE_TREELEVEL
				break
			default:
				epType = EPOCHS_TYPE_INVALID
				break
		endswitch

		SF_ASSERT(epType != EPOCHS_TYPE_INVALID, "type must be either " + SF_OP_EPOCHS_TYPE_RANGE + ", " + SF_OP_EPOCHS_TYPE_NAME + " or " + SF_OP_EPOCHS_TYPE_TREELEVEL)
	else
		epType = EPOCHS_TYPE_RANGE
	endif

	if(numArgs >= 2)
		WAVE selectData = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1", graph = graph)
	else
		WAVE selectData = SF_ExecuteFormula("select()", graph)
	endif

	if(SF_IsDefaultEmptyWave(selectData))
		return selectData
	endif
	SF_ASSERT(DimSize(selectData, COLS) == 3, "A select input has 3 columns.")
	SF_ASSERT(IsNumericWave(selectData), "select parameter must be numeric")

	WAVE/T epochName = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
	SF_ASSERT(DimSize(epochName, ROWS) == 1, "Too many input values for parameter name")
	SF_ASSERT(IsTextWave(epochName), "name parameter must be textual")

	WAVE/Z activeChannels
	WAVE/Z sweeps
	[sweeps, activeChannels] = SF_ReCreateOldSweepsChannelLayout(selectData)

	sweepCnt = DimSize(sweeps, ROWS)
	activeChannelCnt = DimSize(activeChannels, ROWS)

	if(epType == EPOCHS_TYPE_NAME)
		Make/T/FREE/N=(activeChannelCnt * sweepCnt) outNames
		WAVE out = outNames
	elseif(epType == EPOCHS_TYPE_TREELEVEL)
		Make/D/FREE/N=(activeChannelCnt * sweepCnt) outTreeLevel
		MultiThread outTreeLevel = NaN
		WAVE out = outTreeLevel
	else
		Make/D/FREE/N=(2, activeChannelCnt * sweepCnt) outRange
		MultiThread outRange = NaN
		WAVE out = outRange
	endif

	outCnt = 0
	for(i = 0; i < sweepCnt; i += 1)
		sweepNo = sweeps[i]

		if(!IsValidSweepNumber(sweepNo))
			continue
		endif

		WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
		WAVE/Z textualValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)
		if(!WaveExists(numericalValues) || !WaveExists(textualValues))
			continue
		endif

		for(j = 0; j <  activeChannelCnt; j += 1)
			[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, EPOCHS_ENTRY_KEY, activeChannels[j][%channelNumber], activeChannels[j][%channelType], DATA_ACQUISITION_MODE)

			if(WaveExists(settings))
				WAVE/T settingsT = settings
				str = settingsT[index]
				SF_ASSERT(!IsEmpty(str), "Encountered channels without epoch information.")
				WAVE/T epochInfo = EP_EpochStrToWave(str)
				numEpochs = DimSize(epochInfo, ROWS)
				Make/FREE/N=(numEpochs)/T epNames
				for(k = 0; k < numEpochs; k += 1)
					epName = epochInfo[k][EPOCH_COL_TAGS]
					epShortName = EP_GetShortName(epName)
					epNames[k] = SelectString(IsEmpty(epShortName), epShortName, epName)
				endfor

				FindValue/TXOP=4/TEXT=epochName[0] epNames
				if(V_Row >= 0)
					SF_EpochsSetOutValues(epType, out, outCnt, name=epochInfo[V_Row][EPOCH_COL_TAGS], treeLevel=epochInfo[V_Row][EPOCH_COL_TREELEVEL], startTime=epochInfo[V_Row][EPOCH_COL_STARTTIME], endTime=epochInfo[V_Row][EPOCH_COL_ENDTIME])
				endif
			endif
			outCnt +=1
		endfor
	endfor

	if(epType == EPOCHS_TYPE_NAME || epType == EPOCHS_TYPE_TREELEVEL)
		Redimension/N=(outCnt) out
	else
		if(outCnt == 1)
			Redimension/N=2 out
		elseif(outCnt == 0)
			WAVE out = SF_GetDefaultEmptyWave()
		else
			Redimension/N=(-1, outCnt) out
		endif
	endif

	return out
End

static Function SF_EpochsSetOutValues(variable epType, WAVE out, variable outCnt[, string name, string treeLevel, string startTime, string endtime])

	if(epType == EPOCHS_TYPE_NAME)
		ASSERT(!ParamIsDefault(name), "name expected")
		ASSERT(!IsNull(name), "Epoch name can not be null")
		WAVE/T outNames = out
		outNames[outCnt] = name
	elseif(epType == EPOCHS_TYPE_TREELEVEL)
		ASSERT(!ParamIsDefault(treeLevel), "treeLevel expected")
		out[outCnt] = str2num(treeLevel)
	else
		ASSERT(!ParamIsDefault(startTime), "startTime expected")
		ASSERT(!ParamIsDefault(endTime), "endTime expected")
		out[0][outCnt] = str2num(startTime) * ONE_TO_MILLI
		out[1][outCnt] = str2num(endTime) * ONE_TO_MILLI
	endif
End

static Function/WAVE SF_OperationMinus(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	if(DimSize(wv, ROWS) == 1)
		MatrixOP/FREE out = sumCols((-1) * wv)^t
	else
		MatrixOP/FREE out = (row(wv, 0) + sumCols((-1) * subRange(wv, 1, numRows(wv) - 1, 0, numCols(wv) - 1)))^t
	endif
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
	SF_FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
	Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
	return out
End

static Function/WAVE SF_OperationPlus(variable jsonId, string jsonPath, string graph)

	string opShort = "plus"

	WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, opShort)
	WAVE/WAVE output = SF_CreateSFRefWave(graph, opShort, DimSize(input, ROWS))
	Note/K output, note(input)

	output[] = SF_OperationPlusImpl(input[p])

	return SF_GetOutputForExecutor(output, graph, opShort, clear=input)
End

static Function/WAVE SF_OperationPlusImpl(WAVE/Z wv)

	if(!WaveExists(wv))
		return $""
	endif
	SF_ASSERT(IsNumericWave(wv), "Operand for + must be numeric.")
	MatrixOP/FREE out = sumCols(wv)^t
	SF_FormulaWaveScaleTransfer(wv, out, SF_TRANSFER_ALL_DIMS, NaN)
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
	SF_FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
	Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
	Note/K out, note(wv)

	return out
End

static Function/WAVE SF_OperationDiv(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	SF_ASSERT(DimSize(wv, ROWS) >= 2, "At least two operands are required")
	MatrixOP/FREE out = (row(wv, 0) / productCols(subRange(wv, 1, numRows(wv) - 1, 0, numCols(wv) - 1)))^t
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
	SF_FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
	Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
	return out
End

static Function/WAVE SF_OperationMult(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	MatrixOP/FREE out = productCols(wv)^t
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
	SF_FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
	Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
	return out
End

/// range (start[, stop[, step]])
static Function/WAVE SF_OperationRange(variable jsonId, string jsonPath, string graph)

	WAVE/WAVE input = SF_GetArgumentTop(jsonID, jsonPath, graph, SF_OP_RANGE)
	WAVE/Z wv = input[0]
	SF_ASSERT(WaveExists(wv), "Expected data input for range()")
	SF_ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
	SF_ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
	SF_ASSERT(DimSize(wv, COLS) <= 1, "Unhandled dimension")
	if(DimSize(wv, ROWS) == 3)
		Make/N=(ceil(abs((wv[0] - wv[1]) / wv[2])))/FREE range = wv[0] + p * wv[2]
	elseif(DimSize(wv, ROWS) == 2)
		Make/N=(abs(trunc(wv[0])-trunc(wv[1])))/FREE range = wv[0] + p
	elseif(DimSize(wv, ROWS) == 1)
		Make/N=(abs(trunc(wv[0])))/FREE range = p
	else
		SF_ASSERT(0, "Operation accepts 2-3 operands")
	endif

	return SF_GetOutputForExecutorSingle(range, graph, SF_OP_RANGE, clear=input)
End

static Function/WAVE SF_OperationMin(variable jsonId, string jsonPath, string graph)

	variable i, j

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	SF_ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
	if(DimSize(wv, LAYERS) > 1)
		i = DimSize(wv, COLS)
		j = DimSize(wv, LAYERS)
		Redimension/E=1/N=(-1, i * j, 0) wv
		MatrixOP/FREE out = minCols(wv)
		Redimension/E=1/N=(i, j) out
	else
		MatrixOP/FREE out = minCols(wv)^t
	endif
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
	return out
End

static Function/WAVE SF_OperationMax(variable jsonId, string jsonPath, string graph)

	variable i, j

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	SF_ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
	if(DimSize(wv, LAYERS) > 1)
		i = DimSize(wv, COLS)
		j = DimSize(wv, LAYERS)
		Redimension/E=1/N=(-1, i * j, 0) wv
		MatrixOP/FREE out = maxCols(wv)
		Redimension/E=1/N=(i, j) out
	else
		MatrixOP/FREE out = maxCols(wv)^t
	endif
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
	return out
End

static Function/WAVE SF_OperationAvg(variable jsonId, string jsonPath, string graph)

	variable i, j

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	SF_ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
	if(DimSize(wv, LAYERS) > 1)
		i = DimSize(wv, COLS)
		j = DimSize(wv, LAYERS)
		Redimension/E=1/N=(-1, i * j, 0) wv
		MatrixOP/FREE out = averageCols(wv)
		Redimension/E=1/N=(i, j) out
	else
		MatrixOP/FREE out = averageCols(wv)^t
	endif
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
	return out
End

static Function/WAVE SF_OperationRMS(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	SF_ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
	SF_ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
	MatrixOP/FREE out = sqrt(averageCols(magsqr(wv)))^t
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	return out
End

static Function/WAVE SF_OperationVariance(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	SF_ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
	SF_ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
	MatrixOP/FREE out = (sumCols(magSqr(wv - rowRepeat(averageCols(wv), numRows(wv))))/(numRows(wv) - 1))^t
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	return out
End

static Function/WAVE SF_OperationStdev(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	SF_ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
	SF_ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
	MatrixOP/FREE out = (sqrt(sumCols(powR(wv - rowRepeat(averageCols(wv), numRows(wv)), 2))/(numRows(wv) - 1)))^t
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
	return out
End

static Function/WAVE SF_OperationDerivative(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	Make/FREE out
	SF_ASSERT(DimSize(wv, ROWS) > 1, "Can not differentiate single point waves")
	Differentiate/DIM=(ROWS) wv/D=out
	CopyScales wv, out
	SetScale/P x, DimOffset(wv, ROWS), DimDelta(wv, ROWS), "d/dx", out
	return out
End

static Function/WAVE SF_OperationIntegrate(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	Make/FREE out
	SF_ASSERT(DimSize(wv, ROWS) > 1, "Can not integrate single point waves")
	Integrate/METH=1/DIM=(ROWS) wv/D=out
	CopyScales wv, out
	SetScale/P x, DimOffset(wv, ROWS), DimDelta(wv, ROWS), "dx", out
	return out
End

static Function/WAVE SF_OperationArea(variable jsonId, string jsonPath, string graph)

	variable zero,numArgs

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
	SF_ASSERT(DimSize(wv, ROWS) > 1, "Can not integrate single point waves")

	numArgs = JSON_GetArraySize(jsonID, jsonPath)
	if(numArgs == 1)
		zero = 1
	else
		SF_ASSERT(numArgs == 2, "area requires at most 2 arguments")
		WAVE zeroWave = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
		SF_ASSERT(DimSize(zeroWave, ROWS) == 1, "Too many input values for parameter zero")
		SF_ASSERT(IsNumericWave(zeroWave), "zero parameter must be numeric")
		zero = !!zeroWave[0]
	endif

	if(zero)
		Differentiate/DIM=0/EP=1 wv
		Integrate/DIM=0 wv
	endif

	Make/FREE out_integrate
	Integrate/METH=1/DIM=(ROWS) wv/D=out_integrate
	Make/FREE/N=(max(1, DimSize(out_integrate, COLS)), DimSize(out_integrate, LAYERS)) out = out_integrate[DimSize(wv, ROWS) - 1][p][q]
	return out
End

static Function/WAVE SF_OperationButterworth(variable jsonId, string jsonPath, string graph)

	/// `butterworth(data, lowPassCutoff, highPassCutoff, order)`
	SF_ASSERT(JSON_GetArraySize(jsonID, jsonPath) == 4, "The butterworth filter requires 4 arguments")
	WAVE data = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
	WAVE lowPassCutoff = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
	SF_ASSERT(DimSize(lowPassCutoff, ROWS) == 1, "Too many input values for parameter lowPassCutoff")
	SF_ASSERT(IsNumericWave(lowPassCutoff), "lowPassCutoff parameter must be numeric")
	WAVE highPassCutoff = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2")
	SF_ASSERT(DimSize(highPassCutoff, ROWS) == 1, "Too many input values for parameter highPassCutoff")
	SF_ASSERT(IsNumericWave(highPassCutoff), "highPassCutoff parameter must be numeric")
	WAVE order = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/3")
	SF_ASSERT(DimSize(order, ROWS) == 1, "Too many input values for parameter order")
	SF_ASSERT(IsNumericWave(order), "order parameter must be numeric")
	FilterIIR/HI=(highPassCutoff[0] / WAVEBUILDER_MIN_SAMPINT_HZ)/LO=(lowPassCutoff[0] / WAVEBUILDER_MIN_SAMPINT_HZ)/ORD=(order[0])/DIM=(ROWS) data
	SF_ASSERT(V_flag == 0, "FilterIIR returned error")

	return data
End

static Function/WAVE SF_OperationXValues(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	Make/FREE/N=(DimSize(wv, ROWS), DimSize(wv, COLS), DimSize(wv, LAYERS), DimSize(wv, CHUNKS)) out = DimOffset(wv, ROWS) + p * DimDelta(wv, ROWS)
	return out
End

static Function/WAVE SF_OperationText(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	Make/FREE/T/N=(DimSize(wv, ROWS), DimSize(wv, COLS), DimSize(wv, LAYERS), DimSize(wv, CHUNKS)) outT
	Multithread outT = num2strHighPrec(wv[p][q][r][s], precision=7)
	CopyScales wv outT
	return outT
End

static Function/WAVE SF_OperationSetScale(variable jsonId, string jsonPath, string graph)

	variable numIndices

	/// `setscale(data, [dim, [dimOffset, [dimDelta[, unit]]]])`
	numIndices = JSON_GetArraySize(jsonID, jsonPath)
	SF_ASSERT(numIndices < 6, "Maximum number of arguments exceeded.")
	SF_ASSERT(numIndices > 1, "At least two arguments.")
	WAVE data = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
	WAVE/T dimension = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
	SF_ASSERT(DimSize(dimension, ROWS) == 1 && GrepString(dimension[0], "[x,y,z,t]") , "undefined input for dimension")

	if(numIndices >= 3)
		WAVE offset = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2")
		SF_ASSERT(DimSize(offset, ROWS) == 1, "wrong usage of argument")
	else
		Make/FREE/N=1 offset  = {0}
	endif
	if(numIndices >= 4)
		WAVE delta = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/3")
		SF_ASSERT(DimSize(delta, ROWS) == 1, "wrong usage of argument")
	else
		Make/FREE/N=1 delta = {1}
	endif
	if(numIndices == 5)
		WAVE/T unit = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/4")
		SF_ASSERT(DimSize(unit, ROWS) == 1, "wrong usage of argument")
	else
		Make/FREE/N=1/T unit = {""}
	endif

	strswitch(dimension[0])
		case "x":
			SetScale/P x, offset[0], delta[0], unit[0], data
			ASSERT(DimDelta(data, ROWS) == delta[0], "Encountered Igor Bug.")
			break
		case "y":
			SetScale/P y, offset[0], delta[0], unit[0], data
			ASSERT(DimDelta(data, COLS) == delta[0], "Encountered Igor Bug.")
			break
		case "z":
			SetScale/P z, offset[0], delta[0], unit[0], data
			ASSERT(DimDelta(data, LAYERS) == delta[0], "Encountered Igor Bug.")
			break
		case "t":
			SetScale/P t, offset[0], delta[0], unit[0], data
			ASSERT(DimDelta(data, CHUNKS) == delta[0], "Encountered Igor Bug.")
			break
	endswitch

	return data
End

static Function/WAVE SF_OperationWave(variable jsonId, string jsonPath, string graph)

	SF_ASSERT(JSON_GetArraySize(jsonID, jsonPath) == 1, "First argument is wave")
	WAVE/T wavelocation = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0")

	return $(wavelocation[0])
End

static Function/WAVE SF_OperationMerge(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	SF_ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
	SF_ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
	MatrixOP/FREE transposed = wv^T
	Extract/FREE transposed, out, (p < (JSON_GetType(jsonID, jsonPath + "/" + num2istr(q)) != JSON_ARRAY ? 1 : JSON_GetArraySize(jsonID, jsonPath + "/" + num2istr(q))))
	SetScale/P x, 0, 1, "", out
	return out
End

/// `channels([str name]+)` converts a named channel from string to numbers.
///
/// returns [[channelName, channelNumber]+]
static Function/WAVE SF_OperationChannels(variable jsonId, string jsonPath, string graph)

	variable numIndices, i, channelType
	string channelName, channelNumber
	string regExp = "^(?i)(" + ReplaceString(";", XOP_CHANNEL_NAMES, "|") + ")([0-9]+)?$"

	SF_ASSERT(!IsEmpty(graph), "Graph not specified.")
	numIndices = SF_GetNumberOfArguments(jsonId, jsonPath)
	WAVE channels = SF_NewChannelsWave(numIndices ? numIndices : 1)
	for(i = 0; i < numIndices; i += 1)
		WAVE/Z chanSpec = SF_GetArgumentSingle(jsonId, jsonPath, graph, SF_OP_CHANNELS, i)
		SF_ASSERT(WaveExists(chanSpec), "Channel specification returned null wave.")
		channelName = ""
		if(IsNumericWave(chanSpec))
			channels[i][%channelNumber] = chanSpec[0]
		elseif(IsTextWave(chanSpec))
			WAVE/T chanSpecT = chanSpec
			SplitString/E=regExp chanSpecT[0], channelName, channelNumber
			if(V_flag == 0)
				SF_ASSERT(0, "Unknown channel: " + chanSpecT[0])
			endif
			channels[i][%channelNumber] = str2num(channelNumber)
		else
			SF_ASSERT(0, "Unsupported arg type for channels.")
		endif
		SF_ASSERT(!isFinite(channels[i][%channelNumber]) || channels[i][%channelNumber] < NUM_MAX_CHANNELS, "Maximum Number Of Channels exceeded.")
		if(!IsEmpty(channelName))
			channelType = WhichListItem(channelName, XOP_CHANNEL_NAMES, ";", 0, 0)
			if(channelType >= 0)
				channels[i][%channelType] = channelType
			endif
		endif
	endfor

	return SF_GetOutputForExecutorSingle(channels, graph, SF_OP_CHANNELS)
End

/// `sweeps()`
/// returns all possible sweeps as 1d array
static Function/WAVE SF_OperationSweeps(variable jsonId, string jsonPath, string graph)

	variable numIndices

	numIndices = SF_GetNumberOfArguments(jsonId, jsonPath)
	SF_ASSERT(numIndices == 0, "Sweep function takes no arguments.")
	SF_ASSERT(!IsEmpty(graph), "Graph not specified.")

	WAVE/Z sweeps = OVS_GetSelectedSweeps(graph, OVS_SWEEP_ALL_SWEEPNO)

	return SF_GetOutputForExecutorSingle(sweeps, graph, SF_OP_SWEEPS)
End

/// `select([array channels, array sweeps, [string mode]])`
///
/// returns n x 3 with columns [sweepNr][channelType][channelNr]
static Function/WAVE SF_OperationSelect(variable jsonId, string jsonPath, string graph)

	variable numIndices
	string mode = "displayed"

	SF_ASSERT(!IsEmpty(graph), "Graph for extracting sweeps not specified.")

	numIndices = SF_GetNumberOfArguments(jsonId, jsonPath)
	if(!numIndices)
		WAVE channels = SF_ExecuteFormula("channels()", graph, singleResult=1)
		WAVE/Z sweeps = SF_ExecuteFormula("sweeps()", graph, singleResult=1)
	else
		SF_ASSERT(numIndices >= 2 && numIndices <= 3, "Function requires None, 2 or 3 arguments.")
		WAVE channels = SF_GetArgumentSingle(jsonId, jsonPath, graph, SF_OP_SELECT, 0)
		SF_ASSERT(DimSize(channels, COLS) == 2, "A channel input consists of [[channelType, channelNumber]+].")

		WAVE sweeps = SF_GetArgumentSingle(jsonId, jsonPath, graph, SF_OP_SELECT, 1)
		SF_ASSERT(DimSize(sweeps, COLS) < 2, "Sweeps are one-dimensional.")

		if(numIndices == 3)
			WAVE/T wMode = SF_GetArgumentSingle(jsonId, jsonPath, graph, SF_OP_SELECT, 2)
			SF_ASSERT(IsTextWave(wMode), "mode parameter can not be a number. Use \"all\" or \"displayed\".")
			SF_ASSERT(!DimSize(wMode, COLS) && DimSize(wMode, ROWS) == 1, "mode must not be an array with multiple options.")
			mode = wMode[0]
			SF_ASSERT(!CmpStr(mode, "displayed") || !CmpStr(mode, "all"), "mode must be \"all\" or \"displayed\".")
		endif
	endif

	WAVE/Z selectData = SF_GetActiveChannelNumbersForSweeps(graph, channels, sweeps, !CmpStr(mode, "displayed"))

	return SF_GetOutputForExecutorSingle(selectData, graph, SF_OP_SELECT)
End

/// `data(array range[, array selectData])`
///
/// returns [sweepData][sweeps][channelTypeNumber] for all sweeps selected by selectData
static Function/WAVE SF_OperationData(variable jsonId, string jsonPath, string graph)

	variable numIndices

	numIndices = SF_GetNumberOfArguments(jsonID, jsonPath)

	SF_ASSERT(!IsEmpty(graph), "Graph for extracting sweeps not specified.")
	SF_ASSERT(numIndices >= 1, "data function requires at least 1 argument.")
	SF_ASSERT(numIndices <= 2, "data function has maximal 2 arguments.")

	WAVE/Z range = SF_GetArgumentSingle(jsonID, jsonPath, graph, SF_OP_DATA, 0)
	SF_ASSERT(WaveExists(range), "Expected data input for range argument for data")
	SF_ASSERT(DimSize(range, COLS) == 0, "Range must be a 1d wave.")
	if(IsTextWave(range))
		SF_ASSERT(DimSize(range, ROWS) == 1, "For range from epoch only a single name is supported.")
	else
		SF_ASSERT(DimSize(range, ROWS) == 2, "A numerical range is of the form [rangeStart, rangeEnd].")
		range[] = !IsNaN(range[p]) ? range[p] : (p == 0 ? -1 : 1) * inf
	endif

	if(numIndices == 2)
		WAVE/Z selectData = SF_GetArgumentSingle(jsonID, jsonPath, graph, SF_OP_DATA, 1)
	else
		WAVE/Z selectData = SF_ExecuteFormula("select()", graph, singleResult=1)
	endif
	if(WaveExists(selectData))
		SF_ASSERT(DimSize(selectData, COLS) == 3, "A select input has 3 columns.")
		SF_ASSERT(IsNumericWave(selectData), "select parameter must be numeric")
	endif

	WAVE/WAVE output = SF_GetSweepsForFormula(graph, range, selectData, SF_OP_DATA)
	if(!DimSize(output, ROWS))
		DebugPrint("Call to SF_GetSweepsForFormula returned no results")
	endif

	return SF_GetOutputForExecutor(output, graph, SF_OP_DATA)
End

/// `labnotebook(string key[, array selectData [, string entrySourceType]])`
///
/// return lab notebook @p key for all @p sweeps that belong to the channels @p channels
static Function/WAVE SF_OperationLabnotebook(variable jsonId, string jsonPath, string graph)

	variable numIndices, i, j, mode, JSONtype, index, sweepNo, numSweeps, numChannels
	string str, lbnKey

	SF_ASSERT(!IsEmpty(graph), "Graph not specified.")

	numIndices = SF_GetNumberOfArguments(jsonID, jsonPath)
	SF_ASSERT(numIndices <= 3, "Maximum number of three arguments exceeded.")
	SF_ASSERT(numIndices >= 1, "At least one argument is required.")

	if(numIndices == 3)
		WAVE/T wMode = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2", graph = graph)
		SF_ASSERT(IsTextWave(wMode) && DimSize(wMode, ROWS) == 1 && !DimSize(wMode, COLS), "Last parameter needs to be a string.")
		strswitch(wMode[0])
			case "UNKNOWN_MODE":
				mode = UNKNOWN_MODE
				break
			case "DATA_ACQUISITION_MODE":
				break
			case "TEST_PULSE_MODE":
				mode = TEST_PULSE_MODE
				break
			case "NUMBER_OF_LBN_DAQ_MODES":
				mode = NUMBER_OF_LBN_DAQ_MODES
				break
			default:
				SF_ASSERT(0, "Undefined labnotebook mode. Use one in group DataAcqModes")
		endswitch
	else
		mode = DATA_ACQUISITION_MODE
	endif

	if(numIndices >= 2)
		WAVE selectData = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1", graph = graph)
	else
		WAVE selectData = SF_ExecuteFormula("select()", graph)
	endif

	if(SF_IsDefaultEmptyWave(selectData))
		return selectData
	endif
	SF_ASSERT(DimSize(selectData, COLS) == 3, "A select input has 3 columns.")
	SF_ASSERT(IsNumericWave(selectData), "select parameter must be numeric")

	WAVE/T wLbnKey = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
	SF_ASSERT(IsTextWave(wLbnKey) && DimSize(wLbnKey, ROWS) == 1 && !DimSize(wLbnKey, COLS), "First parameter needs to be a string labnotebook key.")
	lbnKey = wLbnKey[0]

	WAVE/Z sweeps
	WAVE/Z activeChannels
	[sweeps, activeChannels] = SF_ReCreateOldSweepsChannelLayout(selectData)
	numSweeps = DimSize(sweeps, ROWS)
	numChannels = DimSize(activeChannels, ROWS)

	Make/D/FREE/N=(numSweeps, numChannels) outD = NaN
	Make/T/FREE/N=(numSweeps, numChannels) outT
	for(i = 0; i < numSweeps; i += 1)
		sweepNo = sweeps[i]

		if(!IsValidSweepNumber(sweepNo))
			continue
		endif

		WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
		WAVE/Z textualValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)
		if(!WaveExists(numericalValues) || !WaveExists(textualValues))
			continue
		endif

		for(j = 0; j <  numChannels; j += 1)
			[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweeps[i], lbnKey, activeChannels[j][%channelNumber], activeChannels[j][%channelType], mode)
			if(!WaveExists(settings))
				continue
			endif
			if(IsNumericWave(settings))
				outD[i][j] = settings[index]
				WAVE out = outD
			elseif(IsTextWave(settings))
				WAVE/T settingsT = settings
				outT[i][j] = settingsT[index]
				WAVE out = outT
			endif
		endfor
	endfor

	if(!WaveExists(out))
		DebugPrint("labnotebook entry not found.")
		WAVE out = SF_GetDefaultEmptyWave()
		return out
	endif

	for(i = 0; i < numChannels; i += 1)
		str = StringFromList(activeChannels[i][%channelType], XOP_CHANNEL_NAMES) + num2istr(activeChannels[i][%channelNumber])
		SetDimLabel COLS, i, $str, out
	endfor

	return out
End

static Function/WAVE SF_OperationLog(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	if(IsTextWave(wv))
		WAVE/T wt = wv
		print wt[0]
	else
		print wv[0]
	endif

	return wv
End

static Function/WAVE SF_OperationLog10(variable jsonId, string jsonPath, string graph)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	SF_ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
	SF_ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
	MatrixOP/FREE out = log(wv)
	SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)

	return out
End

static Function/WAVE SF_OperationCursors(variable jsonId, string jsonPath, string graph)

	variable i
	string info
	variable numIndices

	numIndices = SF_GetNumberOfArguments(jsonID, jsonPath)
	if(!numIndices)
		Make/FREE/T wvT = {"A", "B"}
		numIndices = 2
	else
		Make/FREE/T/N=(numIndices) wvT
		for(i = 0; i < numIndices; i += 1)
			WAVE csrName = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2istr(i), graph = graph)
			SF_ASSERT(IsTextWave(csrName), "cursors argument at " + num2istr(i) + " must be textual.")
			WAVE/T csrNameT = csrName
			wvT[i] = csrNameT[0]
		endfor
	endif
	Make/FREE/N=(numIndices) out = NaN
	for(i = 0; i < numIndices; i += 1)
		SF_ASSERT(GrepString(wvT[i], "^(?i)[A-J]$"), "Invalid Cursor Name")
		if(IsEmpty(graph))
			out[i] = xcsr($wvT[i])
		else
			info = CsrInfo($wvT[i], graph)
			if(IsEmpty(info))
				continue
			endif
			out[i] = xcsr($wvT[i], graph)
		endif
	endfor

	return out
End

// findlevel(data, level, [edge])
static Function/WAVE SF_OperationFindLevel(variable jsonId, string jsonPath, string graph)

	variable numIndices

	numIndices = JSON_GetArraySize(jsonID, jsonPath)
	SF_ASSERT(numIndices <=3, "Maximum number of arguments exceeded.")
	SF_ASSERT(numIndices > 1, "At least two arguments.")
	WAVE data = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
	WAVE level = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
	SF_ASSERT(DimSize(level, ROWS) == 1, "Too many input values for parameter level")
	SF_ASSERT(IsNumericWave(level), "level parameter must be numeric")
	if(numIndices == 3)
		WAVE edge = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2")
		SF_ASSERT(DimSize(edge, ROWS) == 1, "Too many input values for parameter level")
		SF_ASSERT(IsNumericWave(edge), "level parameter must be numeric")
	else
		Make/FREE edge = {0}
	endif

	WAVE out = FindLevelWrapper(data, level[0], edge[0], FINDLEVEL_MODE_SINGLE)

	return out
End

// apfrequency(data, [frequency calculation method], [spike detection crossing level])
static Function/WAVE SF_OperationApFrequency(variable jsonId, string jsonPath, string graph)

	variable numIndices, i

	numIndices = JSON_GetArraySize(jsonID, jsonPath)
	SF_ASSERT(numIndices <=3, "Maximum number of arguments exceeded.")
	SF_ASSERT(numIndices >= 1, "At least one argument.")

	WAVE data = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
	if(numIndices == 3)
		WAVE level = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2", graph = graph)
		SF_ASSERT(DimSize(level, ROWS) == 1, "Too many input values for parameter level")
		SF_ASSERT(IsNumericWave(level), "level parameter must be numeric")
	else
		Make/FREE/N=1 level = {0}
	endif

	if(numIndices >= 2)
		WAVE method = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1", graph = graph)
		SF_ASSERT(DimSize(method, ROWS) == 1, "Too many input values for parameter method")
		SF_ASSERT(IsNumericWave(method), "method parameter must be numeric.")
		SF_ASSERT(method[0] == SF_APFREQUENCY_FULL || method[0] == SF_APFREQUENCY_INSTANTANEOUS ||  method[0] == SF_APFREQUENCY_APCOUNT, "method parameter is invalid")
	else
		Make/FREE method = {SF_APFREQUENCY_FULL}
	endif

	WAVE levels = FindLevelWrapper(data, level[0], FINDLEVEL_EDGE_INCREASING, FINDLEVEL_MODE_MULTI)
	variable numSets = DimSize(levels, ROWS)
	Make/FREE/N=(numSets) levelPerSet = str2num(GetDimLabel(levels, ROWS, p))

	// @todo we assume that the x-axis of data has a ms scale for FULL/INSTANTANEOUS
	switch(method[0])
		case SF_APFREQUENCY_FULL:
			Make/N=(numSets)/D/FREE outD = levelPerSet[p] / (DimDelta(data, ROWS) * DimSize(data, ROWS) * MILLI_TO_ONE)
			break
		case SF_APFREQUENCY_INSTANTANEOUS:
			Make/N=(numSets)/D/FREE outD

			for(i = 0; i < numSets; i += 1)
				if(levelPerSet[i] <= 1)
					outD[i] = 0
				else
					Make/FREE/D/N=(levelPerSet[i] - 1) distances
					distances[0, levelPerSet[i] - 2] = levels[i][p + 1] - levels[i][p]
					outD[i] = 1.0 / (Mean(distances) * MILLI_TO_ONE)
				endif
			endfor
			break
		case SF_APFREQUENCY_APCOUNT:
			Make/N=(numSets)/D/FREE outD = levelPerSet[p]
			break
	endswitch

	return outD
End

// `store(name, ...)`
static Function/WAVE SF_OperationStore(variable jsonId, string jsonPath, string graph)
	string rawCode, preProcCode
	variable maxEntries, numEntries

	SF_ASSERT(JSON_GetArraySize(jsonID, jsonPath) == 2, "Function accepts only two arguments")

	WAVE/T name = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
	SF_ASSERT(IsTextWave(name), "name parameter must be textual")
	SF_ASSERT(DimSize(name, ROWS) == 1, "name parameter must be a plain string")

	WAVE out = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1", graph = graph)

	[rawCode, preProcCode] = SF_GetCode(graph)

	[WAVE/T keys, WAVE/T values] = SF_CreateResultsWaveWithCode(graph, rawCode, data = out, name = name[0])

	ED_AddEntriesToResults(values, keys, SWEEP_FORMULA_RESULT)

	// return second argument unmodified
	return out
End

static Function/WAVE SF_SplitCodeToGraphs(string code)

	string group0, group1
	variable graphCount, size

	WAVE/T graphCode = GetYvsXFormulas()

	do
		SplitString/E=SF_SWEEPFORMULA_GRAPHS_REGEXP code, group0, group1
		if(!IsEmpty(group0))
			EnsureLargeEnoughWave(graphCode, dimension = ROWS, minimumSize = graphCount + 1)
			graphCode[graphCount] = group0
			graphCount += 1
			code = group1
		endif
	while(!IsEmpty(group1))
	Redimension/N=(graphCount) graphCode

	return graphCode
End

static Function/WAVE SF_SplitGraphsToFormulas(WAVE/T graphCode)

	variable i, numGraphs, numFormulae
	string yFormula, xFormula

	WAVE/T wFormulas = GetYandXFormulas()

	numGraphs = DimSize(graphCode, ROWS)
	Redimension/N=(numGraphs, -1) wFormulas
	for(i = 0; i < numGraphs; i += 1)
		SplitString/E=SF_SWEEPFORMULA_REGEXP graphCode[i], yFormula, xFormula
		numFormulae = V_Flag
		if(numFormulae != 1 && numFormulae != 2)
			return $""
		endif
		wFormulas[i][%FORMULA_X] = SelectString(numFormulae == 2, "", xFormula)
		wFormulas[i][%FORMULA_Y] = yFormula
	endfor

	return wFormulas
End

static Function/S SF_GetFormulaWinNameTemplate(string mainWindow)

	return BSP_GetFormulaGraph(mainWindow) + "_"
End

Function SF_button_sweepFormula_tofront(STRUCT WMButtonAction &ba) : ButtonControl

	string winNameTemplate, wList, wName
	variable numWins, i

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			winNameTemplate = SF_GetFormulaWinNameTemplate(GetMainWindow(ba.win))
			wList = WinList(winNameTemplate + "*", ";", "WIN:65")
			numWins = ItemsInList(wList)
			for(i = 0; i < numWins; i += 1)
				wName = StringFromList(i, wList)
				DoWindow/F $wName
			endfor

			break
	endswitch

	return 0
End

static Function/WAVE SF_NewChannelsWave(variable size)

	ASSERT(size >= 0, "Invalid wave size specified")

	Make/N=(size, 2)/FREE out = NaN
	SetDimLabel COLS, 0, channelType, out
	SetDimLabel COLS, 1, channelNumber, out

	return out
End

/// @brief Create a new selectData wave
///        The row counts the selected combinations of sweep, channel type, channel number
///        The three columns per row store the sweep number, channel type, channel number
static Function/WAVE SF_NewSelectDataWave(variable numSweeps, variable numChannels)

	ASSERT(numSweeps >= 0 && numChannels >= 0, "Invalid wave size specified")

	Make/FREE/D/N=(numSweeps * numChannels, 3) selectData
	SetDimLabel COLS, 0, SWEEP, selectData
	SetDimLabel COLS, 1, CHANNELTYPE, selectData
	SetDimLabel COLS, 2, CHANNELNUMBER, selectData

	return selectData
End

static Function/WAVE SF_GetDefaultEmptyWave()

	Make/FREE/D/N=1 out = NaN

	return out
End

/// @brief Returns a wave that is the default for SweepFormula for "no return value"
///        The wave is numeric, consists of one element that is {NaN}.
///        This effectively represent a JSON_NULL: {null}
static Function SF_IsDefaultEmptyWave(WAVE w)

	if(IsNumericWave(w) && DimSize(w, ROWS) == 1 && !DimSize(w, COLS))
		return IsNaN(w[0])
	endif

	return 0
End

static Function/WAVE SF_AverageTPFromSweep(WAVE/T epochMatches, WAVE sweepData)

	variable numTPEpochs, tpDataSizeMin, tpDataSizeMax, sweepDelta

	numTPEpochs = DimSize(epochMatches, ROWS)
	sweepDelta = DimDelta(sweepData, ROWS)
	Make/FREE/D/N=(numTPEpochs) tpStart = trunc(str2num(epochMatches[p][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI / sweepDelta)
	Make/FREE/D/N=(numTPEpochs) tpDelta = trunc(str2num(epochMatches[p][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI / sweepDelta) - tpStart[p]
	[tpDataSizeMin, tpDataSizeMax] = WaveMinAndMaxWrapper(tpDelta)
	SF_ASSERT(tpDataSizeMax - tpDataSizeMin <= 1, "TP data size from TP epochs mismatch within sweep.")

	Make/FREE/D/N=(tpDataSizeMin) tpData
	CopyScales/P sweepData, tpData
	tpDelta = SF_AverageTPFromSweepImpl(tpData, tpStart, sweepData, p)
	if(numTPEpochs > 1)
		MultiThread tpData /= numTPEpochs
	endif

	return tpData
End

static Function SF_AverageTPFromSweepImpl(WAVE tpData, WAVE tpStart, WAVE sweepData, variable i)

	MultiThread tpData += sweepData[tpStart[i] + p]
End

Function/WAVE SF_GetAllOldCodeForGUI(string win) // parameter required for popup menu ext
	WAVE/T/Z entries = SF_GetAllOldCode()

	if(!WaveExists(entries))
		return $""
	endif

	entries[] = num2str(p) + ": " + ElideText(ReplaceString("\n", entries[p], " "), 60)

	WAVE/T/Z splittedMenu = PEXT_SplitToSubMenus(entries, method = PEXT_SUBSPLIT_ALPHA)

	PEXT_GenerateSubMenuNames(splittedMenu)

	return splittedMenu
End

static Function/WAVE SF_GetAllOldCode()
	string entry

	WAVE/T textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)

	entry = "Sweep Formula code"
	WAVE/Z indizes = GetNonEmptyLBNRows(textualResultsValues, entry)

	if(!WaveExists(indizes))
		return $""
	endif

	Make/FREE/T/N=(DimSize(indizes, ROWS)) entries = textualResultsValues[indizes[p]][%$entry][INDEP_HEADSTAGE]

	return GetUniqueEntries(entries)
End

Function SF_PopMenuProc_OldCode(STRUCT WMPopupAction &pa) : PopupMenuControl

	string sweepFormulaNB, bsPanel, code
	variable index

	switch(pa.eventCode)
		case 2: // mouse up
			if(!cmpstr(pa.popStr, NONE))
				break
			endif

			bsPanel = BSP_GetPanel(pa.win)
			sweepFormulaNB = BSP_GetSFFormula(bsPanel)
			WAVE/T/Z entries = SF_GetAllOldCode()
			// -2 as we have NONE
			index = str2num(pa.popStr)
			code = entries[index]

			// translate back from \n to \r
			code = ReplaceString("\n", code, "\r")

			ReplaceNotebookText(sweepFormulaNB, code)
			PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display", val = CHECKBOX_SELECTED)
			break
	endswitch

	return 0
End

// Sets a formula in the SweepFormula notebook of the given data/sweepbrowser
Function SF_SetFormula(string databrowser, string formula)

	string nb = BSP_GetSFFormula(databrowser)
	ReplaceNotebookText(nb, formula)
End

/// @brief Executes a given formula without changing the current SweepFormula notebook
/// @param formula formula string to execute
/// @param databrowser name of databrowser window
/// @param singleResult [optional, default 0], if set then the first dataSet is retrieved from the waveRef wave and returned, the waveRef wave is disposed
Function/WAVE SF_ExecuteFormula(string formula, string databrowser[, variable singleResult])

	variable jsonId

	singleResult = ParamIsDefault(singleResult) ? 0 : !!singleResult

	formula = SF_PreprocessInput(formula)
	formula = SF_FormulaPreParser(formula)
	jsonId = SF_FormulaParser(formula)
	WAVE/Z result = SF_FormulaExecutor(jsonId, graph = databrowser)
	JSON_Release(jsonId, ignoreErr=1)

	WAVE/WAVE out = SF_ParseArgument(databrowser, result, "FormulaExecution")
	if(singleResult)
		SF_ASSERT(DimSize(out, ROWS) == 1, "Expected only a single dataSet")
		WAVE/Z data = out[0]
		SF_CleanUpInput(out)
		return data
	endif

	return out
End

// returns number of operation arguments
static Function SF_GetNumberOfArguments(variable jsonId, string jsonPath)

	return JSON_GetType(jsonId, jsonPath + "/0") == JSON_NULL ? 0 : JSON_GetArraySize(jsonID, jsonPath)
End

static Function/DF SF_GetWorkingDF(string win)

	DFREF dfr = BSP_GetFolder(GetMainWindow(win), MIES_BSP_PANEL_FOLDER)

	return createDFWithAllParents(GetDataFolder(1, dfr) + SF_WORKING_DF)
End

static Function/WAVE SF_CreateSFRefWave(string win, string opShort, variable size)

	string wName

	DFREF dfrWork = SF_GetWorkingDF(win)
	wName = CreateDataObjectName(dfrWork, opShort + "_output_", 1, 0, 4)

	Make/WAVE/N=(size) dfrWork:$wName/WAVE=wv

	return wv
End

static Function/WAVE SF_ParseArgument(string win, WAVE input, string opShort)

	string wName, tmpStr

	if(IsTextWave(input) && DimSize(input, ROWS) == 1 && DimSize(input, COLS) == 0)
		WAVE/T wvt = input
		if(strsearch(wvt[0], SF_WREF_MARKER, 0) == 0)
			tmpStr = wvt[0]
			wName =tmpStr[strlen(SF_WREF_MARKER), Inf]
			WAVE/Z out = $wName
			ASSERT(WaveExists(out), "Referenced wave not found: " + wName)
			return out
		endif
	endif

	WAVE/WAVE wRef = SF_CreateSFRefWave(win, opShort + "_refFromUserInput", 1)
#ifdef SWEEPFORMULA_DEBUG
	DFREF dfrWork = SF_GetWorkingDF(win)
	wName = CreateDataObjectName(dfrWork, opShort + "_dataInput_", 1, 0, 4)
	Duplicate input, dfrWork:$wName
	WAVE input = dfrWork:$wName
#endif
	wRef[0] = input

	return wRef
End

static Function SF_CleanUpInput(WAVE input)

#ifndef SWEEPFORMULA_DEBUG
	KillOrMoveToTrash(wv = input)
#endif
End

static Function SF_ConvertAllReturnDataToPermanent(WAVE/WAVE output, string win, string opShort)

	string wName
	variable i

	for(data : output)
		if(WaveExists(data) && IsFreeWave(data))
			DFREF dfrWork = SF_GetWorkingDF(win)
			wName = CreateDataObjectName(dfrWork, opShort + "_return_arg" + num2istr(i) + "_", 1, 0, 4)
			MoveWave data, dfrWork:$wName
		endif
		i += 1
	endfor
End

static Function/WAVE SF_GetOutputForExecutorSingle(WAVE/Z data, string graph, string opShort[, WAVE clear])

	if(!ParamIsDefault(clear))
		SF_CleanUpInput(clear)
	endif

	WAVE/WAVE output = SF_CreateSFRefWave(graph, opShort, 1)
	if(WaveExists(data))
		output[0] = data
	endif

	return SF_GetOutputForExecutor(output, graph, opShort)
End

static Function/WAVE SF_GetOutputForExecutor(WAVE output, string win, string opShort[, WAVE clear])

	if(!ParamIsDefault(clear))
		SF_CleanUpInput(clear)
	endif
	Make/FREE/T wRefPath = {SF_WREF_MARKER + GetWavesDataFolder(output, 2)}

#ifdef SWEEPFORMULA_DEBUG
	SF_ConvertAllReturnDataToPermanent(output, win, opShort)
#endif

	return wRefPath
End

/// @brief Executes the complete arguments of the JSON and parses the resulting data to a waveRef type
///        @deprecated: executing all arguments e.g. as array in the executor poses issues as soon as data types get mixed.
///                    e.g. operation(0, A, [1, 2, 3]) fails as [0, A, [1, 2, 3]] can not be converted to an Igor wave.
///                    Thus, it is strongly recommended to parse each argument separately.
static Function/WAVE SF_GetArgumentTop(variable jsonId, string jsonPath, string graph, string opShort)

	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	WAVE/WAVE input = SF_ParseArgument(graph, wv, opShort + "_argTop")

	return input
End

/// @brief Executes the part of the argument part of the JSON and parses the resulting data to a waveRef type
static Function/WAVE SF_GetArgument(variable jsonId, string jsonPath, string graph, string opShort, variable argNum)

	string opSpec, argStr

	argStr = num2istr(argNum)
	WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + argStr, graph = graph)
	opSpec = "_arg" + argStr
	WAVE/WAVE input = SF_ParseArgument(graph, wv, opShort + opSpec)

	return input
End

/// @brief Retrieves from an argument the first dataset and disposes the argument
static Function/WAVE SF_GetArgumentSingle(variable jsonId, string jsonPath, string graph, string opShort, variable argNum)

	WAVE/WAVE input = SF_GetArgument(jsonId, jsonPath, graph, opShort, argNum)
	SF_ASSERT(DimSize(input, ROWS) == 1, "Expected only a single dataSet")
	WAVE/Z data = input[0]
	SF_CleanUpInput(input)

	return data
End
