#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

static Constant STATE_COLLECT = 0
static Constant STATE_ADDITION = 1
static Constant STATE_SUBTRACTION = 2
static Constant STATE_MULTIPLICATION = 3
static Constant STATE_DIVISION = 4
static Constant STATE_PARENTHESIS = 5
static Constant STATE_PARENTHESIS_END = 6
static Constant STATE_FUNCTION = 7
static Constant STATE_ARRAY = 8
static Constant STATE_ARRAYELEMENT = 9

/// @brief serialize a string formula into JSON
///
/// @param formula  string formula
/// @returns a JSONid representation
Function FormulaParser(formula)
	String formula

	Variable i, parenthesisStart, parenthesisEnd
	String token = ""
	Variable state = -1, lastState = -1
	Variable level = 0

	Variable jsonID = JSON_New()
	String jsonPath = ""

	if(strlen(formula) == 0)
		return jsonID
	endif

	for(i = 0; i < strlen(formula); i += 1)
		// state
		strswitch(formula[i])
			case "/":
				state = STATE_DIVISION
				break
			case "*":
				state = STATE_MULTIPLICATION
				break
			case "-":
				state = STATE_SUBTRACTION
				break
			case "+":
				state = STATE_ADDITION
				break
			case "(":
				level += 1
				break
			case ")":
				state = STATE_PARENTHESIS_END
				level -= 1
				break
			case "[":
				state = STATE_ARRAY
				break
			case "]":
			case ",":
				state = STATE_ARRAYELEMENT
				break
			default:
				state = STATE_COLLECT
		endswitch
		if(level > 0)
			state = STATE_PARENTHESIS
		endif

		// action
		parenthesisStart = strsearch(formula, "(", i)
		parenthesisEnd = parenthesisStart == -1 ? inf : strsearch(formula, ")", i)
		parenthesisStart = parenthesisStart == -1 ? inf : parenthesisStart
		switch(state)
			case STATE_DIVISION:
				if((strsearch(formula[i, parenthesisStart], "*", 0) != -1) || (strsearch(formula[parenthesisEnd, inf], "*", 1) != -1))
					token += formula[i]
					state = lastState
					continue
				endif
			case STATE_MULTIPLICATION:
				if((strsearch(formula[i, parenthesisStart], "-", 0) != -1) || (strsearch(formula[parenthesisEnd, inf], "-", 1) != -1))
					token += formula[i]
					state = lastState
					continue
				endif
			case STATE_SUBTRACTION:
				if((strsearch(formula[i, parenthesisStart], "+", 0) != -1) || (strsearch(formula[parenthesisEnd, inf], "+", 1) != -1))
					token += formula[i]
					state = lastState
					continue
				endif
			case STATE_ADDITION:
				ASSERT(!!cmpstr(token, ""), "Invalid action token.")
				break
			case STATE_COLLECT:
				ASSERT(GrepString(formula[i], "[A-Za-z0-9_\.]"), "undefined pattern in formula")
			case STATE_PARENTHESIS:
				token += formula[i]
				continue
			case STATE_PARENTHESIS_END:
				if(!cmpstr(token[0], "("))
					token = token[1,inf] // evaluate
					continue
				elseif(GrepString(token, "[A-Za-z]"))
					state = STATE_FUNCTION
					break
				else
					token += formula[i] // delay
					continue
				endif
			case STATE_ARRAY:
				ASSERT(!cmpstr(token, ""), "Invalid action token.")
				continue // wait for element
			case STATE_ARRAYELEMENT:
				break
			default:
				ASSERT(0, "Encountered undefined state " + num2str(state))
		endswitch

		// transition
		if(state != lastState)
			lastState = state
			if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
				JSON_AddObjects(jsonID, jsonPath) // prepare for decent
				jsonPath += "/" + num2str(JSON_GetArraySize(jsonID, jsonPath) - 1)
			endif

			switch(state)
				case STATE_DIVISION:
				case STATE_MULTIPLICATION:
				case STATE_SUBTRACTION:
				case STATE_ADDITION:
					jsonPath += "/" + EscapeJsonPath(formula[i])
					JSON_AddTreeArray(jsonID, jsonPath)
					break
				case STATE_FUNCTION:
					parenthesisStart = strsearch(formula, "(", 0)
					jsonPath += "/" + EscapeJsonPath(token[0, parenthesisStart - 1])
					token = token[parenthesisStart + 1, inf]
					break
				case STATE_ARRAYELEMENT:
					JSON_AddTreeArray(jsonID, jsonPath)
					break
				default:
					ASSERT(0, "Encountered undefined transition " + num2str(state))
					break
			endswitch
		endif

		JSON_AddJSON(jsonID, jsonPath, FormulaParser(token))
		token = ""
	endfor

	// last element (recursion)
	if(!cmpstr(token, formula))
		if(GrepString(token, "^(?i)[0-9]+(?:\.[0-9]+)?(?:[\+-]?E[0-9]+)?$"))
			JSON_AddVariable(jsonID, jsonPath, str2num(formula))
		else
			JSON_AddString(jsonID, jsonPath, token)
		endif
	elseif(strlen(token) > 0)
		JSON_AddJSON(jsonID, jsonPath, FormulaParser(token))
	endif

	return jsonID
End

// @brief add escape characters to a path element
Function/S EscapeJsonPath(str)
	String str

	return ReplaceString("/", str, "~1")
End

Function/WAVE FormulaExecutor(jsonID, [jsonPath])
	Variable jsonID
	String jsonPath

	Variable i, numIndices, JSONtype

	if(ParamIsDefault(jsonPath))
		jsonPath = ""
	endif

	JSONtype = JSON_GetType(jsonID, jsonPath)
	if(JSONtype == JSON_NUMERIC)
		Make/FREE out = { JSON_GetVariable(jsonID, jsonPath) }
		return out
	endif

	ASSERT(JSONtype == JSON_OBJECT, "Topmost element needs to be an object")
	WAVE/T operations = JSON_GetKeys(jsonID, jsonPath)
	ASSERT(DimSize(operations, ROWS) == 1, "Only one operation is allowed")

	jsonPath += "/" + EscapeJsonPath(operations[0])
	ASSERT(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY, "An array is required for operation evaluation.")
	WAVE wv = JSON_GetWave(jsonID, jsonPath)
	EXTRACT/FREE/INDX wv, indices, JSON_GetType(jsonID, jsonPath + "/" + num2str(p)) == JSON_OBJECT
	numIndices = DimSize(indices, 0)
	for(i = 0; i < numIndices; i += 1)
		wv[indices[i]] = FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2str(indices[i]))[0]
	endfor

	ASSERT(DimSize(wv, 1) < 2, "At least two operands are required")
	// ASSERT for unequal wavesizes and different scalings

	strswitch(operations[0])
		case "-":
			MatrixOP/FREE out = row(wv, 0) + sumCols((-1) * subRange(wv, 1, numRows(wv) - 1, 0, numCols(wv) - 1))
			break
		case "+":
			MatrixOP/FREE out = sumCols(wv)
			break
		case "~1": // division
			MatrixOP/FREE out = row(wv, 0) / productCols(subRange(wv, 1, numRows(wv) - 1, 0, numCols(wv) - 1))
			break
		case "*":
			MatrixOP/FREE out = productCols(wv)
			break
		case "min":
			MatrixOP/FREE out = minCols(wv)
			break
		case "max":
			MatrixOP/FREE out = maxCols(wv)
			break
		default:
	endswitch

	return out
End
