#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

static Constant STATE_DEFAULT = 0
static Constant STATE_COLLECT = 1
static Constant STATE_ADDITION = 2
static Constant STATE_SUBTRACTION = 3
static Constant STATE_MULTIPLICATION = 4
static Constant STATE_DIVISION = 5
static Constant STATE_PARENTHESIS = 6
static Constant STATE_FUNCTION = 7
static Constant STATE_ARRAY = 8
static Constant STATE_ARRAYELEMENT = 9

static Constant ACTION_SKIP = 0
static Constant ACTION_COLLECT = 1
static Constant ACTION_CALCULATION = 2
static Constant ACTION_SAMECALCULATION = 3
static Constant ACTION_HIGHERORDER = 4
static Constant ACTION_ARRAYELEMENT = 5
static Constant ACTION_PARENTHESIS = 6
static Constant ACTION_FUNCTION = 7
static Constant ACTION_ARRAY = 8

/// @brief serialize a string formula into JSON
///
/// @param formula  string formula
/// @returns a JSONid representation
Function FormulaParser(formula)
	String formula

	Variable i, parenthesisStart, parenthesisEnd, jsonIDdummy, jsonIDarray
	String tempPath
	Variable action = -1
	String token = ""
	Variable state = STATE_DEFAULT
	Variable lastState = STATE_DEFAULT
	Variable lastCalculation = -1
	Variable level = 0
	Variable arrayLevel = 0

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
				level -= 1
				if(!cmpstr(token[0], "("))
					state = STATE_PARENTHESIS
					break
				endif
				if(GrepString(token, "^[A-Za-z]"))
					state = STATE_FUNCTION
					break
				endif
				state = STATE_DEFAULT
				break
			case "[":
				arrayLevel += 1
				break
			case "]":
				arrayLevel -= 1
				state = STATE_ARRAY
				break
			case ",":
				state = STATE_ARRAYELEMENT
				break
			default:
				state = STATE_COLLECT
				ASSERT(GrepString(formula[i], "[A-Za-z0-9_\.]"), "undefined pattern in formula")
		endswitch
		if(level > 0 || arrayLevel > 0)
			state = STATE_DEFAULT
		endif

		// state transition
		action = ACTION_COLLECT
		if(state != lastState)
			switch(state)
				case STATE_ADDITION:
					if(lastCalculation == STATE_SUBTRACTION)
						action = ACTION_HIGHERORDER
						break
					endif
				case STATE_SUBTRACTION:
					if(lastCalculation == STATE_MULTIPLICATION)
						action = ACTION_HIGHERORDER
						break
					endif
				case STATE_MULTIPLICATION:
					if(lastCalculation == STATE_DIVISION)
						action = ACTION_HIGHERORDER
						break
					endif
				case STATE_DIVISION:
					if(!cmpstr(token, ""))
						if(lastCalculation == -1)
							action = ACTION_HIGHERORDER
						else
							action = ACTION_SKIP
						endif
						break
					endif
					action = ACTION_CALCULATION
					if(state == lastCalculation)
						action = ACTION_SAMECALCULATION
					endif
					if(lastCalculation == STATE_ARRAYELEMENT)
						action = ACTION_COLLECT
					endif
					break
				case STATE_PARENTHESIS:
					action = ACTION_PARENTHESIS
					if(lastCalculation == STATE_ARRAYELEMENT)
						action = ACTION_COLLECT
					endif
					break
				case STATE_FUNCTION:
					action = ACTION_FUNCTION
					if(lastCalculation == STATE_ARRAYELEMENT)
						action = ACTION_COLLECT
					endif
					break
				case STATE_ARRAYELEMENT:
					action = ACTION_ARRAYELEMENT
					if(lastCalculation != STATE_ARRAYELEMENT)
						action = ACTION_HIGHERORDER
					endif
					break
				case STATE_ARRAY:
					action = ACTION_ARRAY
					break
				case STATE_COLLECT:
				case STATE_DEFAULT:
					action = ACTION_COLLECT
					break
				default:
					ASSERT(0, "Encountered undefined transition " + num2str(state))
			endswitch
			lastState = state
		endif

		// action
		switch(action)
			case ACTION_COLLECT:
				token += formula[i]
			case ACTION_SKIP:
				continue
			case ACTION_FUNCTION:
				tempPath = jsonPath
				if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
					JSON_AddObjects(jsonID, jsonPath)
					tempPath += "/" + num2str(JSON_GetArraySize(jsonID, jsonPath) - 1)
				endif
				tempPath += "/"
				parenthesisStart = strsearch(token, "(", 0, 0)
				tempPath += EscapeJsonPath(token[0, parenthesisStart - 1])
				jsonIDdummy = FormulaParser(token[parenthesisStart + 1, inf])
				if(JSON_GetType(jsonIDdummy, "") != JSON_ARRAY)
					JSON_AddTreeArray(jsonID, tempPath)
				endif
				JSON_AddJSON(jsonID, tempPath, jsonIDdummy)
				JSON_Release(jsonIDdummy)
				break
			case ACTION_PARENTHESIS:
				JSON_AddJSON(jsonID, jsonPath, FormulaParser(token[1, inf]))
				break
			case ACTION_HIGHERORDER:
				lastCalculation = state
				if(!!cmpstr(token, ""))
					JSON_AddJSON(jsonID, jsonPath, FormulaParser(token))
				endif
				jsonPath = EscapeJsonPath(formula[i])
				if(!cmpstr(jsonPath, ",") || !cmpstr(jsonPath, "]"))
					jsonPath = ""
				endif
				jsonIDdummy = jsonID
				jsonID = JSON_New()
				JSON_AddTreeArray(jsonID, jsonPath)
				JSON_AddJSON(jsonID, jsonPath, jsonIDdummy)
				JSON_Release(jsonIDdummy)
				break
			case ACTION_ARRAY:
				ASSERT(!cmpstr(token[0], "["), "Encountered array ending without array start.")
				jsonIDarray = JSON_New()
				jsonIDdummy = FormulaParser(token[1,inf])
				if(JSON_GetType(jsonIDdummy, "") != JSON_ARRAY)
					JSON_AddTreeArray(jsonIDarray, "")
				endif
				JSON_AddJSON(jsonIDarray, "", jsonIDdummy)
				JSON_Release(jsonIDdummy)
				JSON_AddJSON(jsonID, jsonPath, jsonIDarray)
				JSON_Release(jsonIDarray)
				break
			case ACTION_CALCULATION:
				if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
					JSON_AddObjects(jsonID, jsonPath) // prepare for decent
					jsonPath += "/" + num2str(JSON_GetArraySize(jsonID, jsonPath) - 1)
				endif
				jsonPath += "/" + EscapeJsonPath(formula[i])
			case ACTION_ARRAYELEMENT:
				JSON_AddTreeArray(jsonID, jsonPath)
				lastCalculation = state
			case ACTION_SAMECALCULATION:
			default:
				if(strlen(token) > 0)
					JSON_AddJSON(jsonID, jsonPath, FormulaParser(token))
				endif
		endswitch
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
