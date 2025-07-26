#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_SFP
#endif // AUTOMATED_TESTING

// to enable debug mode with more persistent data
// #define SWEEPFORMULA_DEBUG

/// @file MIES_SweepFormula_Parser.ipf
///
/// @brief __SFP__ Sweep formula parser

static Constant SF_STATE_UNINITIALIZED    = -1
static Constant SF_STATE_COLLECT          = 1
static Constant SF_STATE_ADDITION         = 2
static Constant SF_STATE_SUBTRACTION      = 3
static Constant SF_STATE_MULTIPLICATION   = 4
static Constant SF_STATE_PARENTHESIS      = 6
static Constant SF_STATE_FUNCTION         = 7
static Constant SF_STATE_ARRAY            = 8
static Constant SF_STATE_ARRAYELEMENT     = 9
static Constant SF_STATE_WHITESPACE       = 10
static Constant SF_STATE_NEWLINE          = 12
static Constant SF_STATE_DIVISION         = 13
static Constant SF_STATE_STRING           = 14
static Constant SF_STATE_STRINGTERMINATOR = 15

static Constant SF_ACTION_UNINITIALIZED = -1
static Constant SF_ACTION_SKIP          = 0
static Constant SF_ACTION_COLLECT       = 1
static Constant SF_ACTION_LOWERORDER    = 2
static Constant SF_ACTION_HIGHERORDER   = 3
static Constant SF_ACTION_ARRAYELEMENT  = 4
static Constant SF_ACTION_PARENTHESIS   = 5
static Constant SF_ACTION_FUNCTION      = 6
static Constant SF_ACTION_ARRAY         = 7

static StrConstant SF_PARSER_REGEX_SIGNED_NUMBER      = "^(?i)[+-]?[0-9]+(?:\.[0-9]+)?(?:[\+-]?E[0-9]+)?$"
static StrConstant SF_PARSER_REGEX_QUOTED_STRING      = "^\".*\"$"
static StrConstant SF_PARSER_REGEX_SIGNED_PARENTHESIS = "^(?i)[+-]?\\([\s\S]*$"
static StrConstant SF_PARSER_REGEX_SIGNED_FUNCTION    = "^(?i)[+-]?[A-Za-z]+"
static StrConstant SF_PARSER_REGEX_OTHER_VALID_CHARS  = "[A-Za-z0-9_\.:;=!$]"

// returns jsonID or Aborts is not successful
Function SFP_ParseFormulaToJSON(string formula)

	variable jsonId

	SFH_ASSERT(CountSubstrings(formula, "(") == CountSubstrings(formula, ")"), "Bracket mismatch in formula.")
	SFH_ASSERT(CountSubstrings(formula, "[") == CountSubstrings(formula, "]"), "Array bracket mismatch in formula.")
	SFH_ASSERT(!mod(CountSubstrings(formula, "\""), 2), "Quotation marks mismatch in formula.")

	formula = ReplaceString("...", formula, "…")

#ifdef DEBUGGING_ENABLED
	SFP_LogParserStateInit(formula)
#endif // DEBUGGING_ENABLED

	jsonId = SFP_FormulaParser(formula)

#ifdef DEBUGGING_ENABLED
	SFP_SaveParserStateLog()
#endif // DEBUGGING_ENABLED

	return jsonId
End

static Function/S SFP_StringifyState(variable state)

	switch(state)
		case SF_STATE_COLLECT:
			return "SF_STATE_COLLECT"
		case SF_STATE_ADDITION:
			return "SF_STATE_ADDITION"
		case SF_STATE_SUBTRACTION:
			return "SF_STATE_SUBTRACTION"
		case SF_STATE_MULTIPLICATION:
			return "SF_STATE_MULTIPLICATION"
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
		case SF_STATE_DIVISION:
			return "SF_STATE_DIVISION"
		case SF_STATE_STRING:
			return "SF_STATE_STRING"
		case SF_STATE_STRINGTERMINATOR:
			return "SF_STATE_STRINGTERMINATOR"
		case SF_STATE_UNINITIALIZED:
			return "SF_STATE_UNINITIALIZED"
		default:
			FATAL_ERROR("unknown state")
	endswitch
End

static Function/S SFP_StringifyAction(variable action)

	switch(action)
		case SF_ACTION_SKIP:
			return "SF_ACTION_SKIP"
		case SF_ACTION_COLLECT:
			return "SF_ACTION_COLLECT"
		case SF_ACTION_LOWERORDER:
			return "SF_ACTION_LOWERORDER"
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
			FATAL_ERROR("Unknown action")
	endswitch
End

#ifdef DEBUGGING_ENABLED
static Function SFP_LogParserState(string token, variable state, variable lastState, variable lastCalculation, variable action, variable level)

	variable numStates

	WAVE/T stateLog = GetSFStateLog()
	numStates = GetNumberFromWaveNote(stateLog, NOTE_INDEX)
	EnsureLargeEnoughWave(stateLog, indexShouldExist = numStates)
	stateLog[numStates][%TOKEN]           = token
	stateLog[numStates][%STATE]           = num2istr(state)
	stateLog[numStates][%LASTSTATE]       = num2istr(lastState)
	stateLog[numStates][%LASTCALCULATION] = num2istr(lastCalculation)
	stateLog[numStates][%ACTION]          = num2istr(action)
	stateLog[numStates][%RECURSIONDEPTH]  = num2istr(level)
	SetNumberInWaveNote(stateLog, NOTE_INDEX, numStates + 1)

End

Function SFP_LogParserErrorState(string msg)

	variable numStates

	WAVE/T stateLog = GetSFStateLog()
	numStates = GetNumberFromWaveNote(stateLog, NOTE_INDEX)
	EnsureLargeEnoughWave(stateLog, indexShouldExist = numStates)
	stateLog[numStates][%ERRORMSG] = msg
	SetNumberInWaveNote(stateLog, NOTE_INDEX, numStates + 1)

End

static Function SFP_LogParserStateInit(string formula)

	variable numStates

	WAVE/T stateLog = GetSFStateLog()
	KillOrMoveToTrash(wv = stateLog)

	WAVE/T stateLog = GetSFStateLog()
	numStates = GetNumberFromWaveNote(stateLog, NOTE_INDEX)
	EnsureLargeEnoughWave(stateLog, indexShouldExist = numStates)
	stateLog[numStates][%FORMULA] = formula
	stateLog[numStates][%TOKEN]   = "**STARTPARSER**"
	SetNumberInWaveNote(stateLog, NOTE_INDEX, numStates + 1)

End

Function SFP_SaveParserStateLog()

	variable numStates

	WAVE/T stateLog = GetSFStateLog()

	numStates = GetNumberFromWaveNote(stateLog, NOTE_INDEX)
	if(numStates)
		Redimension/N=(numStates, -1) stateLog

		WAVE/T stateLogCollection = GetSFStateLogCollection()
		if(!DimSize(stateLogCollection, ROWS))
			Duplicate/O/T stateLog, stateLogCollection
		else
			Concatenate/NP=(ROWS)/T {stateLog}, stateLogCollection
		endif
	endif
End
#endif // DEBUGGING_ENABLED

/// @brief serialize a string formula into JSON
///
/// @param formula  string formula
/// @param createdArray [optional, default 0] set on recursive calls, returns boolean if parser created a JSON array
/// @param indentLevel [internal use only] recursive call level, used for debug output
/// @returns a JSONid representation
Function SFP_FormulaParser(string formula, [variable &createdArray, variable indentLevel])

	variable action, collectedSign, level, arrayLevel, createdArrayLocal, wasArrayCreated, numStates
	string token, indentation

	variable state           = SF_STATE_UNINITIALIZED
	variable lastState       = SF_STATE_UNINITIALIZED
	variable lastCalculation = SF_STATE_UNINITIALIZED
	variable lastAction      = SF_ACTION_UNINITIALIZED
	variable jsonID          = JSON_New()
	string   jsonPath        = ""
	string   buffer          = ""

#ifdef DEBUGGING_ENABLED
	indentation = ReplicateString("-> ", indentLevel)
	if(DP_DebuggingEnabledForCaller())
		printf "%sformula %s\r", indentation, formula
	endif
#endif // DEBUGGING_ENABLED

	WAVE/T wFormula = UTF8StringToTextWave(formula)
	if(!DimSize(wFormula, ROWS))
		return jsonID
	endif

	for(token : wFormula)

		[state, arrayLevel, level] = SFP_ParserGetStateFromToken(token, jsonId, buffer)

#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForCaller())
			printf "%stoken %s, state %s, lastCalculation %s, ", indentation, token, PadString(SFP_StringifyState(state), 25, 0x20), PadString(SFP_StringifyState(lastCalculation), 25, 0x20)
		endif
#endif // DEBUGGING_ENABLED

		[action, lastState, collectedSign] = SFP_ParserGetActionFromState(jsonId, state, lastCalculation, IsEmpty(buffer))

#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForCaller())
			printf "action %s, lastState %s\r", PadString(SFP_StringifyAction(action), 25, 0x20), PadString(SFP_StringifyState(lastState), 25, 0x20)
		endif
#endif // DEBUGGING_ENABLED

		if(action != SF_ACTION_SKIP && lastAction == SF_ACTION_ARRAY)
			// If the last action was the handling of "]" from an array
			SFH_ASSERT(action == SF_ACTION_ARRAYELEMENT || action == SF_ACTION_HIGHERORDER, "Expected \",\" after \"]\"", jsonId = jsonId)
		endif

		if(action == SF_ACTION_COLLECT)
			buffer += token
#ifdef DEBUGGING_ENABLED
			SFP_LogParserState(token, state, lastState, lastCalculation, action, indentLevel)
#endif // DEBUGGING_ENABLED
			continue
		elseif(action == SF_ACTION_SKIP)
#ifdef DEBUGGING_ENABLED
			SFP_LogParserState(token, state, lastState, lastCalculation, action, indentLevel)
#endif // DEBUGGING_ENABLED
			continue
		endif
		[jsonId, jsonPath, lastCalculation, wasArrayCreated, createdArrayLocal] = SFP_ParserModifyJSON(action, lastAction, state, buffer, token, indentLevel)

#ifdef DEBUGGING_ENABLED
		SFP_LogParserState(token, state, lastState, lastCalculation, action, indentLevel)
#endif // DEBUGGING_ENABLED

		lastAction    = action
		buffer        = ""
		collectedSign = 0
	endfor

	if(lastAction != SF_ACTION_UNINITIALIZED)
		SFH_ASSERT(state != SF_STATE_ADDITION &&                       \
		           state != SF_STATE_SUBTRACTION &&                    \
		           state != SF_STATE_MULTIPLICATION &&                 \
		           state != SF_STATE_DIVISION,                         \
		           "Expected value after +, -, * or /", jsonId = jsonId)
	endif
	SFH_ASSERT(state != SF_STATE_ARRAYELEMENT, "Expected value after \",\"", jsonId = jsonId)

	if(!ParamIsDefault(createdArray))
		createdArray = createdArrayLocal
	endif

	if(!IsEmpty(buffer))
		SFP_ParserHandleRemainingBuffer(jsonId, jsonPath, formula, buffer)
#ifdef DEBUGGING_ENABLED
		SFP_LogParserState(buffer, state, lastState, lastCalculation, action, indentLevel)
#endif // DEBUGGING_ENABLED
	endif

	return jsonID
End

static Function SFP_ParserHandleRemainingBuffer(variable jsonId, string jsonPath, string formula, string buffer)

	variable subId

	if(!cmpstr(buffer, formula))
		if(GrepString(buffer, SF_PARSER_REGEX_SIGNED_NUMBER))
			// optionally signed Number
			JSON_AddVariable(jsonID, jsonPath, str2num(formula))
		elseif(!cmpstr(buffer, "\"\"")) // dummy check
			// empty string with explicit quotation marks
			JSON_AddString(jsonID, jsonPath, "")
		elseif(GrepString(buffer, SF_PARSER_REGEX_QUOTED_STRING))
			// non-empty string with quotation marks
			JSON_AddString(jsonID, jsonPath, buffer[1, strlen(buffer) - 2])
		else
			// string without quotation marks
			JSON_AddString(jsonID, jsonPath, buffer)
		endif
	else
		subId = SFP_FormulaParser(buffer)
		JSON_AddJSON(jsonID, jsonPath, subId)
		JSON_Release(subId)
	endif
End

static Function [variable jsonId, string jsonPath, variable lastCalculation, variable wasArrayCreated, variable createdArrayLocal] SFP_ParserModifyJSON(variable action, variable lastAction, variable state, string buffer, string token, variable indentLevel)

	variable parenthesisStart, subId
	string functionName, tempPath

	switch(action)
		case SF_ACTION_FUNCTION:
			parenthesisStart         = strsearch(buffer, "(", 0, 0)
			functionName             = buffer[0, parenthesisStart - 1]
			[functionName, jsonPath] = SFP_ParserEvaluatePossibleSign(jsonId, indentLevel)
			tempPath                 = SFP_ParserAdaptSubPath(jsonId, jsonPath, functionName)
			subId                    = SFP_FormulaParser(buffer[parenthesisStart + 1, Inf], createdArray = wasArrayCreated, indentLevel = indentLevel + 1)
			SFP_FPAddArray(jsonId, tempPath, subId, wasArrayCreated)
			break
		case SF_ACTION_PARENTHESIS:
			[buffer, jsonPath] = SFP_ParserEvaluatePossibleSign(jsonId, indentLevel)
			SFP_ParserAddJSON(jsonId, jsonPath, buffer[1, Inf], indentLevel)
			break
		case SF_ACTION_HIGHERORDER:
			// - called if for the first time a "," is encountered (from SF_STATE_ARRAYELEMENT)
			// - called if a higher priority calculation, e.g. * over + requires to put array in sub json path
			lastCalculation = state
			if(state == SF_STATE_ARRAYELEMENT)
				SFH_ASSERT(!(IsEmpty(buffer) && (lastAction == SF_ACTION_COLLECT || lastAction == SF_ACTION_SKIP || lastAction == SF_ACTION_UNINITIALIZED)), "array element has no value", jsonId = jsonId)
			endif
			if(!IsEmpty(buffer))
				SFP_ParserAddJSON(jsonId, jsonPath, buffer, indentLevel)
			endif
			jsonPath = SF_EscapeJsonPath(token)
			if(!cmpstr(jsonPath, ",") || !cmpstr(jsonPath, "]"))
				jsonPath = ""
			endif
			jsonId            = SFP_FPPutInArrayAtPath(jsonID, jsonPath)
			createdArrayLocal = 1
			break
		case SF_ACTION_ARRAY:
			// - buffer has collected chars between "[" and "]"(where "]" is not included in the buffer here)
			// - Parse recursively the inner part of the brackets
			// - return if the parsing of the inner part created implicitly in the JSON brackets or not
			// If there was no array created, we have to add another outer array around the returned json
			// An array needs to be also added if the returned json is a simple value as this action requires
			// to return an array.
			[buffer, jsonPath] = SFP_ParserEvaluatePossibleSign(jsonId, indentLevel)
			SFH_ASSERT(!CmpStr(buffer[0], "["), "Can not find array start. (Is there a \",\" before \"[\" missing?)", jsonId = jsonId)
			subId = SFP_FormulaParser(buffer[1, Inf], createdArray = wasArrayCreated, indentLevel = indentLevel + 1)
			SFP_FPAddArray(jsonId, jsonPath, subId, wasArrayCreated)
			break
		case SF_ACTION_LOWERORDER: // fallthrough
			jsonPath = SFP_ParserAdaptSubPath(jsonId, jsonPath, token)
		case SF_ACTION_ARRAYELEMENT: // fallthrough
			// - "," was encountered, thus we have multiple elements, we need to set an array at current path
			// The actual content is added in the case fall-through
			SFH_ASSERT(!(IsEmpty(buffer) && (lastAction == SF_ACTION_COLLECT || lastAction == SF_ACTION_SKIP || lastAction == SF_ACTION_HIGHERORDER)), "array element has no value", jsonId = jsonId)
			JSON_AddTreeArray(jsonID, jsonPath)
			lastCalculation = state
		default:
			if(!IsEmpty(buffer))
				SFP_ParserAddJSON(jsonId, jsonPath, buffer, indentLevel)
			endif
			break
	endswitch

	return [jsonId, jsonPath, lastCalculation, wasArrayCreated, createdArrayLocal]
End

static Function [variable action, variable lastState, variable collectedSign] SFP_ParserGetActionFromState(variable jsonId, variable state, variable lastCalculation, variable bufferIsEmpty)

	string errMsg

	SFH_ASSERT(!(lastState == SF_STATE_ARRAYELEMENT && state == SF_STATE_ARRAYELEMENT), "Found , following a ,", jsonId = jsonId)
	// state transition
	action = SF_ACTION_COLLECT
	if(lastState == SF_STATE_STRING && state != SF_STATE_STRINGTERMINATOR)
		// collect between quotation marks
		action = SF_ACTION_COLLECT
	elseif(!collectedSign && (state == SF_STATE_ADDITION || state == SF_STATE_SUBTRACTION) && (lastState == SF_STATE_ADDITION || lastState == SF_STATE_SUBTRACTION))
		action        = SF_ACTION_COLLECT
		collectedSign = 1
	elseif(state != lastState)

		// Handle possible sign and collect for numbers as well as for functions
		// if we initially start with a - or + or we are after a * or / or ,
		if(!collectedSign && (state == SF_STATE_ADDITION || state == SF_STATE_SUBTRACTION) && \
		   (lastState == SF_STATE_UNINITIALIZED ||                                            \
		    lastState == SF_STATE_MULTIPLICATION ||                                           \
		    lastState == SF_STATE_DIVISION ||                                                 \
		    lastState == SF_STATE_ARRAYELEMENT))

			action        = SF_ACTION_COLLECT
			collectedSign = 1
		else

			switch(state)
				// *, / before +, - (as well as *, / here) and /, - are non-commutative
				// resulting in *, /, - are handled as higher order
				case SF_STATE_ADDITION: // fallthrough
				case SF_STATE_SUBTRACTION:
					if(bufferIsEmpty || lastCalculation == SF_STATE_SUBTRACTION || lastCalculation == SF_STATE_MULTIPLICATION || lastCalculation == SF_STATE_DIVISION)
						action = SF_ACTION_HIGHERORDER
						break
					endif
					if(lastCalculation == SF_STATE_UNINITIALIZED || lastCalculation == SF_STATE_ADDITION)
						action = SF_ACTION_LOWERORDER
						break
					endif
					if(lastCalculation == SF_STATE_ARRAYELEMENT)
						action = SF_ACTION_COLLECT
						break
					endif

					FATAL_ERROR("Unhandled state")

				case SF_STATE_MULTIPLICATION: // fallthrough
				case SF_STATE_DIVISION:

					// if the buffer is empty and we are either at the start of a new parse or at a new array element (which is basically the start of a new parse of a subsequent part)
					// and the left side is not a function, braces or brackets then we do not allow * and /.
					SFH_ASSERT(!(bufferIsEmpty &&                                                                                                                            \
					             (lastCalculation == SF_STATE_UNINITIALIZED || lastCalculation == SF_STATE_ARRAYELEMENT) &&                                                  \
					             !(lastState == SF_STATE_FUNCTION || lastState == SF_STATE_PARENTHESIS || lastState == SF_STATE_ARRAY)), "Unexpected token.", jsonId = jsonId)

					if(bufferIsEmpty || lastCalculation == SF_STATE_DIVISION)
						action = SF_ACTION_HIGHERORDER
						break
					endif
					if(lastCalculation == SF_STATE_UNINITIALIZED || lastCalculation == SF_STATE_ADDITION || lastCalculation == SF_STATE_SUBTRACTION || lastCalculation == SF_STATE_MULTIPLICATION)
						action = SF_ACTION_LOWERORDER
						break
					endif
					if(lastCalculation == SF_STATE_ARRAYELEMENT)
						action = SF_ACTION_COLLECT
						break
					endif

					FATAL_ERROR("Unhandled state")

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
					SFH_ASSERT(lastState != SF_STATE_UNINITIALIZED, "No value before ,", jsonId = jsonId)
					action = SF_ACTION_ARRAYELEMENT
					if(lastCalculation != SF_STATE_ARRAYELEMENT)
						action = SF_ACTION_HIGHERORDER
					endif
					break
				case SF_STATE_ARRAY:
					action = SF_ACTION_ARRAY
					break
				case SF_STATE_NEWLINE: // fallthrough
				case SF_STATE_WHITESPACE:
					action = SF_ACTION_SKIP
					break
				case SF_STATE_COLLECT:
					action = SF_ACTION_COLLECT
					break
				case SF_STATE_STRINGTERMINATOR:
					if(lastState != SF_STATE_STRING)
						state = SF_STATE_STRING
					endif
					action = SF_ACTION_COLLECT
					break
				default:
					sprintf errMsg, "Encountered undefined transition from %s to %s.", SFP_StringifyState(lastState), SFP_StringifyState(state)
					SFH_FATAL_ERROR(errMsg, jsonId = jsonId)
			endswitch

		endif
		if(action != SF_ACTION_SKIP)
			lastState = state
		endif
	endif

	return [action, lastState, collectedSign]
End

static Function [variable state, variable arrayLevel, variable level] SFP_ParserGetStateFromToken(string token, variable jsonId, string buffer)

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
			// use SF_STATE_DIVISION because it fulfills the same rules required for the range operation
			state = SF_STATE_DIVISION
			break
		case "(":
			level += 1
			break
		case ")":
			level -= 1
			if(GrepString(buffer, SF_PARSER_REGEX_SIGNED_PARENTHESIS))
				state = SF_STATE_PARENTHESIS
				break
			endif
			if(GrepString(buffer, SF_PARSER_REGEX_SIGNED_FUNCTION))
				state = SF_STATE_FUNCTION
				break
			endif
			state = SF_STATE_COLLECT
			break
		case "[":
			arrayLevel += 1
			break
		case "]":
			arrayLevel -= 1
			state       = SF_STATE_ARRAY
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
		case " ": // fallthrough
		case "\t":
			state = SF_STATE_WHITESPACE
			break
		default:
			state = SF_STATE_COLLECT
			SFH_ASSERT(GrepString(token, SF_PARSER_REGEX_OTHER_VALID_CHARS), "undefined pattern in formula near: " + buffer + token, jsonId = jsonId)
			break
	endswitch

	if(level > 0 || arrayLevel > 0)
		// transfer sub level "as is" to buffer
		state = SF_STATE_COLLECT
	endif

	return [state, arrayLevel, level]
End

static Function [string buffer, string jsonPath] SFP_ParserEvaluatePossibleSign(variable jsonId, variable indentLevel)

	ASSERT(strlen(buffer) > 1, "Expected at least two characters.")

	if(!CmpStr(buffer[0], "-"))
		return [buffer[1, Inf], SFP_ParserInsertNegation(jsonID, jsonPath, indentLevel)]
	endif
	if(!CmpStr(buffer[0], "+"))
		return [buffer[1, Inf], jsonPath]
	endif

	return [buffer, jsonpath]
End

static Function SFP_ParserAddJSON(variable jsonId, string jsonPath, string formula, variable indentLevel)

	variable subId

	subId = SFP_FormulaParser(formula, indentLevel = indentLevel + 1)
	JSON_AddJSON(jsonID, jsonPath, subId)
	JSON_Release(subId)
End

static Function/S SFP_ParserInsertNegation(variable jsonId, string jsonPath, variable indentLevel)

	variable jsonId1

	jsonId1 = JSON_Parse("{\"*\":[-1]}")
	JSON_AddJSON(jsonID, jsonPath, jsonId1)
	JSON_Release(jsonId1)
	if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
		jsonPath += "/1/*"
	else
		jsonPath += "/*"
	endif

	return jsonPath
End

static Function/S SFP_ParserAdaptSubPath(variable jsonId, string jsonPath, string subPath)

	if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
		JSON_AddObjects(jsonID, jsonPath)
		jsonPath += "/" + num2istr(JSON_GetArraySize(jsonID, jsonPath) - 1)
	endif
	jsonPath += "/" + SF_EscapeJsonPath(subPath)

	return jsonpath
End

/// @brief Create a new empty array object, add mainId into it at path and return created json, release subId
static Function SFP_FPPutInArrayAtPath(variable subId, string jsonPath)

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
static Function SFP_FPAddArray(variable mainId, string jsonPath, variable subId, variable arrayWasCreated)

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
