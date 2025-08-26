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

// The structure stores data that is required and gathered when a SF formula is parsed
static Structure SF_ParserData
	// jsonId of the JSON with JSON Logic that is build by the parser for later execution by the SF executor
	variable jsonId
	// Current working jsonPath of the parser
	string jsonPath
	// source location table that is created
	WAVE/T srcLocs
	// current character offset into the formula of the parser
	variable bufferOffset
EndStructure

// returns jsonID or Aborts is not successful
Function [variable jsonid, variable srcLocId] SFP_ParseFormulaToJSON(string formula)

	WAVE/T assertData = GetSFAssertData()
	assertData[%FORMULA] = formula
	NVAR trackParserBufferOffset = $GetSweepFormulaBufferOffsetTracker()
	if(CountSubstrings(formula, "(") != CountSubstrings(formula, ")"))
		trackParserBufferOffset = strsearch(formula, ")", Inf, 1)
		SFH_FATAL_ERROR("Bracket mismatch in formula.")
	endif
	if(CountSubstrings(formula, "[") != CountSubstrings(formula, "]"))
		trackParserBufferOffset = strsearch(formula, "]", Inf, 1)
		SFH_FATAL_ERROR("Array bracket mismatch in formula.")
	endif
	if(mod(CountSubstrings(formula, "\""), 2))
		trackParserBufferOffset = strsearch(formula, "\"", Inf, 1)
		SFH_FATAL_ERROR("Quotation marks mismatch in formula.")
	endif

	formula = ReplaceString("...", formula, "…")

#ifdef DEBUGGING_ENABLED
	SFP_LogParserStateInit(formula)
#endif // DEBUGGING_ENABLED

	[jsonId, WAVE/T srcLocs] = SFP_FormulaParser(formula, 0)

	srcLocId = SFP_ConvertSourceLocWaveToJSON(srcLocs, formula)

#ifdef DEBUGGING_ENABLED
	SFP_SaveParserStateLog()
#endif // DEBUGGING_ENABLED

	return [jsonId, srcLocId]
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
/// @param bufOffset Parser internal character offset into the initial formula string. When SFP_FormulaParser is called from a outside the parser this should be zero.
/// @param createdArray [optional, default 0] set on recursive calls, returns boolean if parser created a JSON array
/// @param indentLevel [internal use only] recursive call level, used for debug output
/// @returns a JSONid representation
Function [variable jsonId, WAVE/T srcLocs] SFP_FormulaParser(string formula, variable bufOffset, [variable &createdArray, variable indentLevel])

	STRUCT SF_ParserData pad
	variable action, collectedSign, level, arrayLevel, createdArrayLocal, wasArrayCreated, numStates
	variable consumedChars
	string token, indentation

	variable state           = SF_STATE_UNINITIALIZED
	variable lastState       = SF_STATE_UNINITIALIZED
	variable lastCalculation = SF_STATE_UNINITIALIZED
	variable lastAction      = SF_ACTION_UNINITIALIZED
	string   buffer          = ""

	pad.jsonId   = JSON_New()
	pad.jsonPath = ""

	WAVE/T pad.srcLocs = GetNewSourceLocationWave()
	pad.bufferOffset = bufOffset

	NVAR trackParserBufferOffset = $GetSweepFormulaBufferOffsetTracker()
	trackParserBufferOffset = bufOffset

#ifdef DEBUGGING_ENABLED
	indentation = ReplicateString("-> ", indentLevel)
	if(DP_DebuggingEnabledForCaller())
		printf "%sformula %s\r", indentation, formula
	endif
#endif // DEBUGGING_ENABLED

	WAVE/T wFormula = UTF8StringToTextWave(formula)
	if(!DimSize(wFormula, ROWS))
		return [pad.jsonID, pad.srcLocs]
	endif

	for(token : wFormula)

		consumedChars             += 1
		[state, arrayLevel, level] = SFP_ParserGetStateFromToken(token, pad.jsonId, buffer)

#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForCaller())
			printf "%stoken %s, state %s, lastCalculation %s, ", indentation, token, PadString(SFP_StringifyState(state), 25, 0x20), PadString(SFP_StringifyState(lastCalculation), 25, 0x20)
		endif
#endif // DEBUGGING_ENABLED

		[action, lastState, collectedSign] = SFP_ParserGetActionFromState(pad.jsonId, state, lastCalculation, IsEmpty(buffer))

#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForCaller())
			printf "action %s, lastState %s\r", PadString(SFP_StringifyAction(action), 25, 0x20), PadString(SFP_StringifyState(lastState), 25, 0x20)
		endif
#endif // DEBUGGING_ENABLED

		if(action != SF_ACTION_SKIP && lastAction == SF_ACTION_ARRAY)
			// If the last action was the handling of "]" from an array
			SFH_ASSERT(action == SF_ACTION_ARRAYELEMENT || action == SF_ACTION_HIGHERORDER, "Expected \",\" after \"]\"", jsonId = pad.jsonId)
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
			pad.bufferOffset += 1
			continue
		endif
		[pad, lastCalculation, wasArrayCreated, createdArrayLocal] = SFP_ParserModifyJSON(action, lastAction, state, buffer, token, indentLevel)
		pad.bufferOffset                                           = bufOffset + consumedChars
		trackParserBufferOffset                                    = pad.bufferOffset
#ifdef DEBUGGING_ENABLED
		SFP_LogParserState(token, state, lastState, lastCalculation, action, indentLevel)
#endif // DEBUGGING_ENABLED

		lastAction    = action
		buffer        = ""
		collectedSign = 0
	endfor

	if(lastAction != SF_ACTION_UNINITIALIZED)
		SFH_ASSERT(state != SF_STATE_ADDITION &&                           \
		           state != SF_STATE_SUBTRACTION &&                        \
		           state != SF_STATE_MULTIPLICATION &&                     \
		           state != SF_STATE_DIVISION,                             \
		           "Expected value after +, -, * or /", jsonId = pad.jsonId)
	endif
	SFH_ASSERT(state != SF_STATE_ARRAYELEMENT, "Expected value after \",\"", jsonId = pad.jsonId)

	if(!ParamIsDefault(createdArray))
		createdArray = createdArrayLocal
	endif

	if(!IsEmpty(buffer))
		SFP_ParserHandleRemainingBuffer(pad, formula, buffer)
#ifdef DEBUGGING_ENABLED
		SFP_LogParserState(buffer, state, lastState, lastCalculation, action, indentLevel)
#endif // DEBUGGING_ENABLED
	endif

	return [pad.jsonID, pad.srcLocs]
End

static Function SFP_ParserHandleRemainingBuffer(STRUCT SF_ParserData &pad, string formula, string buffer)

	variable subId, arraySize

	DEBUGPRINT("RemainingBuffer: " + buffer)

	if(!cmpstr(buffer, formula))
		if(GrepString(buffer, SF_PARSER_REGEX_SIGNED_NUMBER))
			// optionally signed Number
			JSON_AddVariable(pad.jsonID, pad.jsonPath, str2num(formula))
		elseif(!cmpstr(buffer, "\"\"")) // dummy check
			// empty string with explicit quotation marks
			JSON_AddString(pad.jsonID, pad.jsonPath, "")
		elseif(GrepString(buffer, SF_PARSER_REGEX_QUOTED_STRING))
			// non-empty string with quotation marks
			JSON_AddString(pad.jsonID, pad.jsonPath, buffer[1, strlen(buffer) - 2])
		else
			// string without quotation marks
			JSON_AddString(pad.jsonID, pad.jsonPath, buffer)
		endif
		SFP_AddSourceLocation(pad, pad.bufferOffset)
	else
		[subId, WAVE/T srcLocsSub] = SFP_FormulaParser(buffer, pad.bufferOffset)
		JSON_AddJSON(pad.jsonID, pad.jsonPath, subId)
		JSON_Release(subId)

		string str = JSON_Dump(pad.jsonId, indent = 2)

		SFP_AdaptSourceSubPaths(pad, srcLocsSub, 1)
		ConcatenateWavesWithNoteIndex(pad.srcLocs, srcLocsSub)
	endif
End

static Function [STRUCT SF_ParserData pad, variable lastCalculation, variable wasArrayCreated, variable createdArrayLocal] SFP_ParserModifyJSON(variable action, variable lastAction, variable state, string buffer, string token, variable indentLevel)

	variable parenthesisStart, subId, createArray, bufOffset, arrayPresent, addArrayIndex
	string functionName, jsonPathSave, jsonPathArray

	DEBUGPRINT("Buffer: " + buffer)

	switch(action)
		case SF_ACTION_FUNCTION:
			parenthesisStart               = strsearch(buffer, "(", 0, 0)
			functionName                   = buffer[0, parenthesisStart - 1]
			[functionName, bufOffset, pad] = SFP_ParserEvaluatePossibleSign()
			jsonPathSave                   = pad.jsonPath

			bufOffset                 += pad.bufferOffset + parenthesisStart + 1
			[subId, WAVE/T srcLocsSub] = SFP_FormulaParser(buffer[parenthesisStart + 1, Inf], bufOffset, createdArray = wasArrayCreated, indentLevel = indentLevel + 1)

			[pad]       = SFP_ParserAdaptSubPath(functionName)
			createArray = JSON_GetType(subId, "") != JSON_ARRAY || !wasArrayCreated
			if(createArray && JSON_GetType(subId, "") == JSON_OBJECT)
				[pad] = SFP_FPAddArray(subId, createArray)
				SFP_AddSourceLocation(pad, pad.bufferOffset + parenthesisStart + 1)
			else
				[pad] = SFP_FPAddArray(subId, createArray)
			endif

			SFP_AddToSourceLocationWave(pad.srcLocs, pad.jsonPath, pad.bufferOffset)

			SFP_AdaptSourceSubPaths(pad, srcLocsSub, createArray)
			ConcatenateWavesWithNoteIndex(pad.srcLocs, srcLocsSub)

			pad.jsonPath = jsonPathSave
			break
		case SF_ACTION_PARENTHESIS:
			[buffer, bufOffset, pad] = SFP_ParserEvaluatePossibleSign()
			[pad]                    = SFP_ParserAddJSON(buffer[1, Inf], 1 + bufOffset, indentLevel)
			break
		case SF_ACTION_HIGHERORDER:
			// - called if for the first time a "," is encountered (from SF_STATE_ARRAYELEMENT)
			// - called if a higher priority calculation, e.g. * over + requires to put array in sub json path
			lastCalculation = state
			if(state == SF_STATE_ARRAYELEMENT)
				SFH_ASSERT(!(IsEmpty(buffer) && (lastAction == SF_ACTION_COLLECT || lastAction == SF_ACTION_SKIP || lastAction == SF_ACTION_UNINITIALIZED)), "array element has no value", jsonId = pad.jsonId)
			endif
			if(!IsEmpty(buffer))
				[pad] = SFP_ParserAddJSON(buffer, 0, indentLevel)
			endif

			jsonPathArray = SF_EscapeJsonPath(token)
			if(!cmpstr(jsonPathArray, ",") || !cmpstr(jsonPathArray, "]"))
				jsonPathArray = ""
			endif
			[pad]             = SFP_FPPutInArrayAtPath(jsonPathArray)
			createdArrayLocal = 1
			break
		case SF_ACTION_ARRAY:
			// - buffer has collected chars between "[" and "]"(where "]" is not included in the buffer here)
			// - Parse recursively the inner part of the brackets
			// - return if the parsing of the inner part created implicitly in the JSON brackets or not
			// If there was no array created, we have to add another outer array around the returned json
			// An array needs to be also added if the returned json is a simple value as this action requires
			// to return an array.
			[buffer, bufOffset, pad] = SFP_ParserEvaluatePossibleSign()
			SFH_ASSERT(!CmpStr(buffer[0], "["), "Can not find array start. (Is there a \",\" before \"[\" missing?)", jsonId = pad.jsonId)
			bufOffset                 += pad.bufferOffset + 1
			[subId, WAVE/T srcLocsSub] = SFP_FormulaParser(buffer[1, Inf], bufOffset, createdArray = wasArrayCreated, indentLevel = indentLevel + 1)
			createArray                = JSON_GetType(subId, "") != JSON_ARRAY || !wasArrayCreated
			SFP_AddArray(pad, srcLocsSub, subId, createArray)
			ConcatenateWavesWithNoteIndex(pad.srcLocs, srcLocsSub)

			break
		case SF_ACTION_LOWERORDER: // fallthrough
			[pad] = SFP_ParserAdaptSubPath(token)
		case SF_ACTION_ARRAYELEMENT: // fallthrough
			// - "," was encountered, thus we have multiple elements, we need to set an array at current path
			// The actual content is added in the case fall-through
			SFH_ASSERT(!(IsEmpty(buffer) && (lastAction == SF_ACTION_COLLECT || lastAction == SF_ACTION_SKIP || lastAction == SF_ACTION_HIGHERORDER)), "array element has no value", jsonId = pad.jsonId)
			// add an array, in case there was already an array nothing is changed
			arrayPresent = JSON_GetType(pad.jsonID, pad.jsonPath, ignoreErr = 1) == JSON_ARRAY
			JSON_AddTreeArray(pad.jsonID, pad.jsonPath)
			if(!arrayPresent)
				SFP_AddSourceLocation(pad, pad.bufferOffset, arrayOnly = 1)
			endif
			lastCalculation = state
		default:
			if(!IsEmpty(buffer))
				[pad] = SFP_ParserAddJSON(buffer, 0, indentLevel)
			endif
			break
	endswitch

	return [pad, lastCalculation, wasArrayCreated, createdArrayLocal]
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

/// @brief If buffer has a sign then it is removed from buffer. If the sign was a minus then a negation is prefixed in the json.
static Function [string buffer, variable bufOffset, STRUCT SF_ParserData pad] SFP_ParserEvaluatePossibleSign()

	ASSERT(strlen(buffer) > 1, "Expected at least two characters.")

	if(!CmpStr(buffer[0], "-"))
		[pad] = SFP_ParserInsertNegation()
		return [buffer[1, Inf], 1, pad]
	endif
	if(!CmpStr(buffer[0], "+"))
		return [buffer[1, Inf], 1, pad]
	endif

	return [buffer, 0, pad]
End

/// @brief Parses a formula to json and puts it at jsonPath into the current json
static Function [STRUCT SF_ParserData pad] SFP_ParserAddJSON(string formula, variable bufOffset, variable indentLevel)

	variable subId

	[subId, WAVE/T srcLocsSub] = SFP_FormulaParser(formula, pad.bufferOffset + bufOffset, indentLevel = indentLevel + 1)
	JSON_AddJSON(pad.jsonID, pad.jsonPath, subId)
	JSON_Release(subId)
	SFP_AdaptSourceSubPaths(pad, srcLocsSub, 1)
	ConcatenateWavesWithNoteIndex(pad.srcLocs, srcLocsSub)

	return [pad]
End

static Function [STRUCT SF_ParserData pad] SFP_ParserInsertNegation()

	variable jsonId1

	jsonId1 = JSON_Parse("{\"*\":[-1]}")
	JSON_AddJSON(pad.jsonID, pad.jsonPath, jsonId1)
	JSON_Release(jsonId1)
	if(JSON_GetType(pad.jsonID, pad.jsonPath) == JSON_ARRAY)
		pad.jsonPath += "/1"
		SFP_AddSourceLocation(pad, pad.bufferOffset)
		pad.jsonPath += "/*"
	else
		pad.jsonPath += "/*"
	endif
	SFP_AddSourceLocation(pad, pad.bufferOffset)

	return [pad]
End

static Function [STRUCT SF_ParserData pad] SFP_ParserAdaptSubPath(string subPath)

	if(JSON_GetType(pad.jsonID, pad.jsonPath) == JSON_ARRAY)
		JSON_AddObjects(pad.jsonID, pad.jsonPath)
		pad.jsonPath += "/" + num2istr(JSON_GetArraySize(pad.jsonID, pad.jsonPath) - 1)
		SFP_AddSourceLocation(pad, pad.bufferOffset)
	endif
	pad.jsonPath += "/" + SF_EscapeJsonPath(subPath)

	return [pad]
End

/// @brief Create a new empty array object, add mainId into it at path and return created json, release subId
static Function [STRUCT SF_ParserData pad] SFP_FPPutInArrayAtPath(string jsonPathArray)

	variable newId

	newId = JSON_New()
	JSON_AddTreeArray(newId, jsonPathArray)
	if(JSON_GetType(pad.jsonId, "") != JSON_NULL)
		JSON_AddJSON(newId, jsonPathArray, pad.jsonId)
		JSON_Release(pad.jsonId)
		pad.jsonId   = newId
		pad.jsonPath = jsonPathArray
		SF_ExpandWithBasePath(pad.srcLocs)
		SFP_AdaptSourceSubPaths(pad, pad.srcLocs, 1)
		if(!IsEmpty(pad.jsonPath))
			SFP_AddSourceLocation(pad, pad.bufferOffset, arrayOnly = 1)
		endif
	else
		JSON_Release(pad.jsonId)
		pad.jsonId   = newId
		pad.jsonPath = jsonPathArray
		SFP_AddSourceLocation(pad, pad.bufferOffset, arrayOnly = 1)
	endif

	return [pad]
End

/// @brief Adds subId to mainId, if necessary puts subId into an array, release subId
static Function [STRUCT SF_ParserData pad] SFP_FPAddArray(variable subId, variable createArray, [variable firstElementOffset])

	variable tmpId, offset
	string addJSONPath

	firstElementOffset = ParamIsDefault(firstElementOffset) ? NaN : firstElementOffset
	offset             = pad.bufferOffset + firstElementOffset

	if(createArray)
		tmpId = JSON_New()
		JSON_AddTreeArray(tmpId, "")
		JSON_AddJSON(tmpId, "", subId)

		if(!IsNaN(firstElementOffset))
			addJSONPath = SF_GetAddJSONPath(pad.jsonId, pad.jsonPath)
		endif
		JSON_AddJSON(pad.jsonId, pad.jsonPath, tmpId)
		JSON_Release(tmpId)

		if(!IsNaN(firstElementOffset))
			// at this path the AddJSON adds the tmpId, the subId path is added through the
			// srcLoc waves from the deeper recursion that gets it paths prefixed (in the caller)
			SFP_AddToSourceLocationWave(pad.srcLocs, addJSONPath, offset)
		endif
	else
		// subId contains an array
		JSON_AddJSON(pad.jsonId, pad.jsonPath, subId)
	endif

	JSON_Release(subId)

	return [pad]
End

// @brief Must be used before the JSON_AddJSON is applied to jsonId
static Function/S SF_GetAddJSONPath(variable jsonId, string jsonPath)

	variable arraySize

	if(JSON_GetType(jsonId, jsonPath) != JSON_ARRAY)
		return jsonPath
	endif

	arraySize = JSON_GetArraySize(jsonId, jsonPath)
	if(arraySize > 1)
		return jsonPath + "/" + num2istr(arraySize)
	endif

	if(JSON_GetType(jsonId, jsonPath + "/0") == JSON_NULL)
		return jsonPath + "/0"
	endif

	return jsonPath + "/1"
End

static Function SF_ExpandWithBasePath(WAVE/T srcLocs)

	variable col, size

	col = FindDimLabel(srcLocs, COLS, "PATH")
	FindValue/TEXT=""/RMD=[, col] srcLocs
	if(V_row >= 0)
		return NaN
	endif

	size = GetNumberFromWaveNote(srcLocs, NOTE_INDEX)
	Make/FREE/D/N=(size) offsetRow
	offsetRow[] = str2num(srcLocs[p][%OFFSET])

	SFP_AddToSourceLocationWave(srcLocs, "", WaveMin(offsetRow))
End

/// @brief Adds the current jsonPath with formulaOffset as source location to the source location wave
///
/// The following modifications are made to the path string:
/// - the path is always prefixed with a "/" if it is not empty and has no "/" at the start
/// - if the current pad.jsonPath points to an array then the last existing array index is added to the path, e.g. "/array" -> "/array/3"
/// - if arrayOnly flag is set and pad.jsonPath points to an array then only the path to the array without index is added
static Function SFP_AddSourceLocation(STRUCT SF_ParserData &pad, variable formulaOffset, [variable arrayOnly])

	variable arraySize
	string   srcPath

	variable size = GetNumberFromWaveNote(pad.srcLocs, NOTE_INDEX)

	arrayOnly = ParamIsDefault(arrayOnly) ? 0 : !!arrayOnly

	srcPath = pad.jsonPath
	if(JSON_GetType(pad.jsonID, pad.jsonPath) == JSON_ARRAY)

		if(arrayOnly)
			if(!IsEmpty(pad.jsonPath) && CmpStr(pad.jsonPath[0], "/"))
				srcPath = "/" + pad.jsonPath
			endif
			SFP_AddToSourceLocationWave(pad.srcLocs, srcPath, formulaOffset)
			return NaN
		endif

		arraySize = JSON_GetArraySize(pad.jsonID, pad.jsonPath)
		srcPath   = pad.jsonPath + "/" + num2istr(arraySize - 1)
	endif

	if(!IsEmpty(srcPath) && CmpStr(srcPath[0], "/"))
		srcPath = "/" + srcPath
	endif

	SFP_AddToSourceLocationWave(pad.srcLocs, srcPath, formulaOffset)
End

/// @brief When the parsing returns from a recursion where a deeper level of the formula was parsed it also returns the gathered source locations
///        from this deeper level. These source locations need to be prefixed by the path where the JSON returned by the recursion is inserted
///        for the current level. This function applies that prefixing. The caller usually concatenates the wave with the modified paths to
///        the wave with the paths from the current recursion level.
///        The prefix is the current pad.jsonPath with the following modifications:
///        - the prefix is always prefixed with a "/" if it is not empty and has no "/" at the start
///        - if addArrayIndex flag is set and the current pad.jsonPath is an array then the last existing array index is added to the prefix
///          e.g. "/currentPath" -> "/currentPath/3"
///        All source location paths from the deeper recursion are then prefixed with this path
static Function SFP_AdaptSourceSubPaths(STRUCT SF_ParserData &pad, WAVE/T srcLocsSub, variable addArrayIndex)

	variable i, size
	string jsonPath

	variable arraySize = NaN
	string   suffix    = ""

	size = GetNumberFromWaveNote(srcLocsSub, NOTE_INDEX)
	if(!size)
		return NaN
	endif

	addArrayIndex = !!addArrayIndex

	if(addArrayIndex && JSON_GetType(pad.jsonID, pad.jsonPath) == JSON_ARRAY)
		arraySize = JSON_GetArraySize(pad.jsonID, pad.jsonPath)
		suffix    = "/" + num2istr(arraySize - 1)
	endif

	jsonPath = pad.jsonPath
	if(!IsEmpty(jsonPath) && CmpStr(jsonPath[0], "/"))
		jsonPath = "/" + jsonPath
	endif

	srcLocsSub[0, size - 1][%PATH] = jsonPath + suffix + SelectString(IsEmpty(srcLocsSub[p][%PATH]), srcLocsSub[p][%PATH], "")

#if defined(DEBUGGING_ENABLED)
	DEBUGPRINT("SrcPath Moved up: " + jsonpath + suffix)
	for(i = 0; i < size; i += 1)
		DEBUGPRINT(srcLocsSub[i][%PATH])
	endfor
#endif
End

static Function SFP_AddToSourceLocationWave(WAVE/T srcLocs, string srcPath, variable loc)

	variable size = GetNumberFromWaveNote(srcLocs, NOTE_INDEX)
	EnsureLargeEnoughWave(srcLocs, indexShouldExist = size)
	srcLocs[size][%PATH]   = srcPath
	srcLocs[size][%OFFSET] = num2istr(loc)
	SetNumberInWaveNote(srcLocs, NOTE_INDEX, size + 1)
	DEBUGPRINT("Added SrcPath: " + srcPath + " Loc:" + num2istr(loc))
End

/// @brief After parsing a SF formula the gathered source locations are put into a JSON by this function.
///        The JSON has a simple format and is used a key/value store:
///        key       : value
///        --------------------------------------
///        ""        : formula (string)
///        "<path1>" : character offset (numeric)
///        "<path2>" : character offset (numeric)
///        ...       : ...
///
///        The JSON has to be released by the caller of SFP_ParseFormulaToJSON after its information is no longer needed or
///        in the case of a SFH_ASSERT by the assertion handler (currently in SFH_GetAssertLocationMessage)
static Function SFP_ConvertSourceLocWaveToJSON(WAVE/T srcLocs, string formula)

	variable i, size, jsonId, tmpId
	string path

	DEBUGPRINT("Final SrcPathWave")

	size = GetNumberFromWaveNote(srcLocs, NOTE_INDEX)

	jsonId = JSON_New()
	JSON_AddTreeObject(jsonId, "")
	for(i = 0; i < size; i += 1)
		DEBUGPRINT(srcLocs[i][%PATH] + " at " + srcLocs[i][%OFFSET])
		path = SF_EscapeJsonPath(srcLocs[i][%PATH])
		if(IsEmpty(path))
			continue
		endif
		if(!JSON_Exists(jsonId, path))
			JSON_AddVariable(jsonId, path, str2num(srcLocs[i][%OFFSET]))
		else
			BUG("Got same source location multiple times: " + srcLocs[i][%PATH])
		endif
	endfor
	JSON_AddString(jsonId, "/", formula)

	return jsonId
End

static Function SFP_AddArray(STRUCT SF_ParserData &pad, WAVE/T srcLocsSub, variable subId, variable createArray)

	string addJsonPath, jsonPathSave
	variable addArrayIndex

	addJsonPath = SF_GetAddJSONPath(pad.jsonId, pad.jsonPath)
	if(JSON_GetType(pad.jsonId, "") == JSON_NULL)
		[pad] = SFP_FPAddArray(subId, createArray, firstElementOffset = 0)
		if(createArray)
			SFP_AdaptSourceSubPathsAtJSONPath(pad, srcLocsSub, addJsonPath)
		else
			SFP_AdaptSourceSubPaths(pad, srcLocsSub, 0)
		endif
	else
		[pad] = SFP_FPAddArray(subId, createArray, firstElementOffset = 0)
		if(createArray)
			SFP_AdaptSourceSubPathsAtJSONPath(pad, srcLocsSub, addJsonPath)
		else
			addArrayIndex = createArray || (!createArray && JSON_GetType(pad.jsonId, pad.jsonPath) == JSON_ARRAY)
			SFP_AdaptSourceSubPaths(pad, srcLocsSub, addArrayIndex)
		endif
	endif
End

static Function SFP_AdaptSourceSubPathsAtJSONPath(STRUCT SF_ParserData &pad, WAVE/T srcLocsSub, string jsonPath)

	string jsonPathSave

	jsonPathSave = pad.jsonPath
	pad.jsonPath = jsonPath
	SFP_AdaptSourceSubPaths(pad, srcLocsSub, 1)
	pad.jsonPath = jsonPathSave
End
