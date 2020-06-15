#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SF
#endif

/// @file MIES_SweepFormula.ipf
///
/// @brief __SF__ Sweep formula allows to do analysis on sweeps with a
/// dedicated formula language

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
static Constant SF_STATE_COMMENT = 11
static Constant SF_STATE_NEWLINE = 12
static Constant SF_STATE_OPERATION = 13
static Constant SF_STATE_STRING = 14
static Constant SF_STATE_STRINGTERMINATOR = 15

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

static Constant SF_MAX_NUMPOINTS_FOR_MARKERS = 1000

static Constant SF_APFREQUENCY_FULL          = 0x0
static Constant SF_APFREQUENCY_INSTANTANEOUS = 0x1
static Constant SF_APFREQUENCY_APCOUNT       = 0x2

static Function SF_FormulaCheck(condition, message)
	Variable condition
	String message

	if(!condition)
		Abort message
	endif
End

/// @brief output an error message to a global variable in dfr
static Function SF_FormulaError(dfr, condition, message)
	DFREF dfr
	Variable condition
	String message

	if(!condition)
		SVAR error = $GetSweepFormulaParseErrorMessage(dfr)
		error = message
		Abort message
	endif
End

/// @brief preparse user input to correct formula patterns
///
/// @return parsed formula
static Function/S SF_FormulaPreParser(formula)
	String formula

	SF_FormulaCheck(CountSubstrings(formula, "(") == CountSubstrings(formula, ")"), "Bracket missmatch in formula.")
	SF_FormulaCheck(CountSubstrings(formula, "[") == CountSubstrings(formula, "]"), "Array bracket missmatch in formula.")

	formula = ReplaceString("...", formula, "…")

	return formula
End

/// @brief serialize a string formula into JSON
///
/// @param formula  string formula
/// @returns a JSONid representation
Function SF_FormulaParser(formula)
	String formula

	Variable i, parenthesisStart, parenthesisEnd, jsonIDdummy, jsonIDarray
	String tempPath
	Variable action = -1
	String token = ""
	String buffer = ""
	Variable state = -1
	Variable lastState = -1
	Variable lastCalculation = -1
	Variable level = 0
	Variable arrayLevel = 0

	Variable jsonID = JSON_New()
	String jsonPath = ""

	if(strlen(formula) == 0)
		return jsonID
	endif

	for(i = 0; i < strlen(formula); i += 1)
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
			case "#":
				state = SF_STATE_COMMENT
				break
			case "\"":
				state = SF_STATE_STRINGTERMINATOR
				break
			case "\r":
			case "\n":
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
				SF_FormulaCheck(GrepString(token, "[A-Za-z0-9_\.:;]"), "undefined pattern in formula: " + formula[i,i+5])
		endswitch
		if(level > 0 || arrayLevel > 0)
			state = SF_STATE_DEFAULT
		endif

		// state transition
		if(lastState == SF_STATE_STRING && state != SF_STATE_STRINGTERMINATOR)
			action = SF_ACTION_COLLECT
		elseif(lastState == SF_STATE_COMMENT && state != SF_STATE_NEWLINE)
			action = SF_ACTION_SKIP
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
						if(lastCalculation == -1)
							action = SF_ACTION_HIGHERORDER
						else
							action = SF_ACTION_SKIP
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
				case SF_STATE_COMMENT:
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
					SF_FormulaCheck(0, "Encountered undefined transition " + num2str(state))
			endswitch
			lastState = state
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
					tempPath += "/" + num2str(JSON_GetArraySize(jsonID, jsonPath) - 1)
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
				JSON_AddJSON(jsonID, jsonPath, SF_FormulaParser(buffer[1, inf]))
				break
			case SF_ACTION_HIGHERORDER:
				lastCalculation = state
				if(!IsEmpty(buffer))
					JSON_AddJSON(jsonID, jsonPath, SF_FormulaParser(buffer))
				endif
				jsonPath = SF_EscapeJsonPath(token)
				if(!cmpstr(jsonPath, ",") || !cmpstr(jsonPath, "]"))
					jsonPath = ""
				endif
				jsonIDdummy = jsonID
				jsonID = JSON_New()
				JSON_AddTreeArray(jsonID, jsonPath)
				if(JSON_GetType(jsonIDdummy, "") != JSON_NULL)
					JSON_AddJSON(jsonID, jsonPath, jsonIDdummy)
				endif
				JSON_Release(jsonIDdummy)
				break
			case SF_ACTION_ARRAY:
				SF_FormulaCheck(!cmpstr(buffer[0], "["), "Encountered array ending without array start.")
				jsonIDarray = JSON_New()
				jsonIDdummy = SF_FormulaParser(buffer[1,inf])
				if(JSON_GetType(jsonIDdummy, "") != JSON_ARRAY)
					JSON_AddTreeArray(jsonIDarray, "")
				endif
				JSON_AddJSON(jsonIDarray, "", jsonIDdummy)
				JSON_Release(jsonIDdummy)
				JSON_AddJSON(jsonID, jsonPath, jsonIDarray)
				JSON_Release(jsonIDarray)
				break
			case SF_ACTION_CALCULATION:
				if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
					JSON_AddObjects(jsonID, jsonPath) // prepare for decent
					jsonPath += "/" + num2str(JSON_GetArraySize(jsonID, jsonPath) - 1)
				endif
				jsonPath += "/" + SF_EscapeJsonPath(token)
			case SF_ACTION_ARRAYELEMENT:
				JSON_AddTreeArray(jsonID, jsonPath)
				lastCalculation = state
			case SF_ACTION_SAMECALCULATION:
			default:
				if(strlen(buffer) > 0)
					JSON_AddJSON(jsonID, jsonPath, SF_FormulaParser(buffer))
				endif
		endswitch
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
	elseif(strlen(buffer) > 0)
		JSON_AddJSON(jsonID, jsonPath, SF_FormulaParser(buffer))
	endif

	return jsonID
End

/// @brief add escape characters to a path element
static Function/S SF_EscapeJsonPath(str)
	String str

	return ReplaceString("/", str, "~1")
End

/// @brief Execute the formula parsed by SF_FormulaParser
///
/// Recursively executes the formula parsed into jsonID.
///
/// @param jsonID   JSON object ID from the JSON XOP
/// @param jsonPath JSON pointer compliant path
/// @param graph    graph to read from, mainly used by the `data` operation
Function/WAVE SF_FormulaExecutor(jsonID, [jsonPath, graph])
	Variable jsonID
	String jsonPath
	String graph

	Variable i, j, numIndices, JSONtype, mode
	string info, msg, str

	if(ParamIsDefault(jsonPath))
		jsonPath = ""
	endif
	if(ParamIsDefault(graph))
		graph = ""
	endif

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
		Make/FREE/N=(topArraySize[0])/B types = JSON_GetType(jsonID, jsonPath + "/" + num2str(p))

		if(topArraySize[0] != 0 && types[0] == JSON_STRING)
			ASSERT(DimSize(topArraySize, ROWS) <= 1, "Text Waves Must Be 1-dimensional.")
			return JSON_GetTextWave(jsonID, jsonPath)
		endif
		EXTRACT/FREE types, strings, types[p] == JSON_STRING
		ASSERT(DimSize(strings, ROWS) == 0, "Object evaluation For Mixed Text/Numeric Arrays Is Not Allowed")
		WaveClear strings

		ASSERT(DimSize(topArraySize, ROWS) < 4, "Unhandled Data Alignment. Only 3 Dimensions Are Supported For Operations.")
		WAVE out = JSON_GetWave(jsonID, jsonPath)

		Redimension/N=4 topArraySize
		topArraySize[] = topArraySize[p] != 0 ? topArraySize[p] : 1
		Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])/E=1 out

		EXTRACT/FREE/INDX types, indices, (types[p] == JSON_OBJECT) || (types[p] == JSON_ARRAY)
		if(DimSize(indices, ROWS) == 1 && DimSize(out, ROWS) == 1)
			return SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2str(indices[0]), graph = graph)
		endif
		for(i = 0; i < DimSize(indices, ROWS); i += 1)
			WAVE element = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2str(indices[i]), graph = graph)
			if(DimSize(element, CHUNKS) > 1)
				DebugPrint("Merging Chunks To Layers for object: " + jsonPath + "/" + num2str(indices[i]))
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
	ASSERT(JSONtype == JSON_OBJECT, "Topmost element needs to be an object")
	WAVE/T operations = JSON_GetKeys(jsonID, jsonPath)
	ASSERT(DimSize(operations, ROWS) == 1, "Only one operation is allowed")
	jsonPath += "/" + SF_EscapeJsonPath(operations[0])
	ASSERT(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY, "An array is required to hold the operands of the operation.")
	strswitch(operations[0])
		case "cursors":
		case "sweeps":
			WAVE/T wvT = JSON_GetTextWave(jsonID, jsonPath)
			break
		case "setscale":
		case "butterworth":
		case "channels":
		case "data":
		case "labnotebook":
		case "wave":
		case "findlevel":
			break
		default:
			WAVE wv = SF_FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	endswitch

	/// @name SweepFormulaOperations
	/// @{
	strswitch(LowerStr(operations[0]))
		case "-":
			if(DimSize(wv, ROWS) == 1)
				MatrixOP/FREE out = sumCols((-1) * wv)^t
			else
				MatrixOP/FREE out = (row(wv, 0) + sumCols((-1) * subRange(wv, 1, numRows(wv) - 1, 0, numCols(wv) - 1)))^t
			endif
			SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
			SF_FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "+":
			MatrixOP/FREE out = sumCols(wv)^t
			SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
			SF_FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "~1": // division
			ASSERT(DimSize(wv, ROWS) >= 2, "At least two operands are required")
			MatrixOP/FREE out = (row(wv, 0) / productCols(subRange(wv, 1, numRows(wv) - 1, 0, numCols(wv) - 1)))^t
			SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
			SF_FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "*":
			MatrixOP/FREE out = productCols(wv)^t
			SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			SF_FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
			SF_FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "range":
			/// range (start[, stop[, step]])
		case "…":
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, COLS) <= 1, "Unhandled dimension")
			if(DimSize(wv, ROWS) == 3)
				Make/N=(ceil(abs((wv[0] - wv[1]) / wv[2])))/FREE out = wv[0] + p * wv[2]
			elseif(DimSize(wv, ROWS) == 2)
				Make/N=(abs(trunc(wv[0])-trunc(wv[1])))/FREE out = wv[0] + p
			elseif(DimSize(wv, ROWS) == 1)
				Make/N=(abs(trunc(wv[0])))/FREE out = p
			else
				ASSERT(0, "Operation accepts 2-3 operands")
			endif
			break
		case "min":
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
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
			break
		case "max":
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
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
			break
		case "avg":
		case "mean":
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
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
			break
		case "rms":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = sqrt(averageCols(magsqr(wv)))^t
			SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "variance":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = (sumCols(magSqr(wv - rowRepeat(averageCols(wv), numRows(wv))))/(numRows(wv) - 1))^t
			SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "stdev":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = (sqrt(sumCols(powR(wv - rowRepeat(averageCols(wv), numRows(wv)), 2))/(numRows(wv) - 1)))^t
			SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "derivative":
			Make/FREE out
			ASSERT(DimSize(wv, ROWS) > 1, "Can not differentiate single point waves")
			Differentiate/DIM=(ROWS) wv/D=out
			CopyScales wv, out
			SetScale/P x, DimOffset(wv, ROWS), DimDelta(wv, ROWS), "d/dx", out
			break
		case "integrate":
			Make/FREE out
			ASSERT(DimSize(wv, ROWS) > 1, "Can not integrate single point waves")
			Integrate/METH=1/DIM=(ROWS) wv/D=out
			CopyScales wv, out
			SetScale/P x, DimOffset(wv, ROWS), DimDelta(wv, ROWS), "dx", out
			break
		case "butterworth":
			/// `butterworth(data, lowPassCutoff, highPassCutoff, order)`
			ASSERT(JSON_GetArraySize(jsonID, jsonPath) == 4, "The butterworth filter requires 4 arguments")
			WAVE data = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
			WAVE lowPassCutoff = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
			ASSERT(DimSize(lowPassCutoff, ROWS) == 1, "Too many input values for parameter lowPassCutoff")
			ASSERT(IsNumericWave(lowPassCutoff), "lowPassCutoff parameter must be numeric")
			WAVE highPassCutoff = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2")
			ASSERT(DimSize(highPassCutoff, ROWS) == 1, "Too many input values for parameter highPassCutoff")
			ASSERT(IsNumericWave(highPassCutoff), "highPassCutoff parameter must be numeric")
			WAVE order = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/3")
			ASSERT(DimSize(order, ROWS) == 1, "Too many input values for parameter order")
			ASSERT(IsNumericWave(order), "order parameter must be numeric")
			FilterIIR/HI=(highPassCutoff[0] / WAVEBUILDER_MIN_SAMPINT_HZ)/LO=(lowPassCutoff[0] / WAVEBUILDER_MIN_SAMPINT_HZ)/ORD=(order[0])/DIM=(ROWS) data
			ASSERT(V_flag == 0, "FilterIIR returned error")
			WAVE out = data
			break
		case "time":
		case "xvalues":
			Make/FREE/N=(DimSize(wv, ROWS), DimSize(wv, COLS), DimSize(wv, LAYERS), DimSize(wv, CHUNKS)) out = DimOffset(wv, ROWS) + p * DimDelta(wv, ROWS)
			break
		case "text":
			Make/FREE/T/N=(DimSize(wv, ROWS), DimSize(wv, COLS), DimSize(wv, LAYERS), DimSize(wv, CHUNKS)) outT = num2str(wv[p][q][r][s])
			CopyScales wv outT
			WAVE out = outT
			break
		case "setscale":
			/// `setscale(data, [dim, [dimOffset, [dimDelta[, unit]]]])`
			numIndices = JSON_GetArraySize(jsonID, jsonPath)
			ASSERT(numIndices < 6, "Maximum number of arguments exceeded.")
			ASSERT(numIndices > 1, "At least two arguments.")
			WAVE data = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
			WAVE/T dimension = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
			ASSERT(DimSize(dimension, ROWS) == 1 && GrepString(dimension[0], "[x,y,z,t]") , "undefined input for dimension")

			if(numIndices >= 3)
				WAVE offset = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2")
				ASSERT(DimSize(offset, ROWS) == 1, "wrong usage of argument")
			else
				Make/FREE/N=1 offset  = {0}
			endif
			if(numIndices >= 4)
				WAVE delta = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/3")
				ASSERT(DimSize(delta, ROWS) == 1, "wrong usage of argument")
			else
				Make/FREE/N=1 delta = {1}
			endif
			if(numIndices == 5)
				WAVE/T unit = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/4")
				ASSERT(DimSize(unit, ROWS) == 1, "wrong usage of argument")
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
			WAVE out = data
			break
		case "wave":
			ASSERT(JSON_GetArraySize(jsonID, jsonPath) == 1, "First argument is wave")
			WAVE/T wavelocation = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0")
			WAVE out = $(wavelocation[0])
			break
		case "merge":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE transposed = wv^T
			Extract/FREE transposed, out, (p < (JSON_GetType(jsonID, jsonPath + "/" + num2str(q)) != JSON_ARRAY ? 1 : JSON_GetArraySize(jsonID, jsonPath + "/" + num2str(q))))
			SetScale/P x, 0, 1, "", out
			break
		case "channels":
			/// `channels([str name]+)` converts a named channel from string to numbers.
			///
			/// returns [[channelName, channelNumber]+]
			String channelName, channelNumber
			String regExp = "^(?i)(" + ReplaceString(";", ITC_CHANNEL_NAMES, "|") + ")([0-9]+)?$"
			numIndices = JSON_GetArraySize(jsonID, jsonPath)

			Make/N=(numIndices, 2)/FREE out = NaN
			SetDimLabel COLS, 0, channelType, out
			SetDimLabel COLS, 1, channelNumber, out
			for(i = 0; i < numIndices; i += 1)
				JSONtype = JSON_GetType(jsonID, jsonPath + "/" + num2str(i))
				channelName = ""
				if(JSONtype == JSON_NUMERIC)
					out[i][%channelNumber] = JSON_GetVariable(jsonID, jsonPath + "/" + num2str(i))
				elseif(JSONtype == JSON_STRING)
					SplitString/E=regExp JSON_GetString(jsonID, jsonPath + "/" + num2str(i)), channelName, channelNumber
					if(V_flag == 0)
						continue
					endif
					out[i][%channelNumber] = str2num(channelNumber)
				endif
				ASSERT(!isFinite(out[i][%channelNumber]) || out[i][%channelNumber] < NUM_MAX_CHANNELS, "Maximum Number Of Channels exceeded.")
				out[i][%channelType] = WhichListItem(channelName, ITC_CHANNEL_NAMES, ";", 0, 0)
			endfor
			out[][] = out[p][q] < 0 ? NaN : out[p][q]
			break
		case "sweeps":
			/// `sweeps([str type])`
			///  @p type: `|displayed|all`
			///           displayed (default): get (selected) sweeps
			///           al:                  get all possible sweeps
			ASSERT(JSON_GetArraySize(jsonID, jsonPath) <= 1, "Function requires 1 argument at most.")
			ASSERT(!ParamIsDefault(graph) && !IsEmpty(graph), "Graph not specified.")

			JSONtype = JSON_GetType(jsonID, jsonPath + "/0")
			if(JSONtype == JSON_NULL)
				wvT[0] = "displayed"
			endif

			strswitch(wvT[0])
				case "all":
					WAVE out = OVS_GetSelectedSweeps(graph, OVS_SWEEP_ALL_SWEEPNO)
					break
				case "displayed":
					WAVE/T/Z traces = PA_GetTraceInfos(graph)
					if(WaveExists(traces))
						Make/N=(DimSize(traces, ROWS))/FREE traceSweeps = str2num(traces[p][%sweepNumber])
						WAVE out = GetUniqueEntries(traceSweeps)
					endif
					break
				default:
					ASSERT(0, "Undefined argument")
			endswitch

			if(!WaveExists(out))
				Make/N=1/FREE out = {NaN} // simulates [null]
			endif
			break
		case "data":
			/// `data(array range,array channels,array sweeps)`
			///
			/// returns [[sweeps][channel]] for all [sweeps] in list sweepNumbers, grouped by channels
			ASSERT(!ParamIsDefault(graph) && !IsEmpty(graph), "Graph for extracting sweeps not specified.")

			WAVE range = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
			ASSERT(DimSize(range, ROWS) == 2, "A range is of the form [rangeStart, rangeEnd].")
			range[][][] = !IsNaN(range[p][q][r]) ? range[p][q][r] : (p == 0 ? -1 : 1) * inf

			WAVE channels = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
			ASSERT(DimSize(channels, COLS) == 2, "A channel input consists of [[channelType, channelNumber]+].")

			WAVE sweeps = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2", graph = graph)
			ASSERT(DimSize(sweeps, COLS) < 2, "Sweeps are one-dimensional.")

			WAVE activeChannels = SF_GetActiveChannelNumbers(graph, channels, sweeps, DATA_ACQUISITION_MODE)
			WaveClear channels

			WAVE/Z out = SF_GetSweepForFormula(graph, range, activeChannels, sweeps)
			if(!WaveExists(out))
				DebugPrint("Call to SF_GetSweepForFormula returned no results")
				Make/FREE/N=1 out = {NaN}
				break
			endif

			break
		case "labnotebook":
			/// `labnotebook(string key, array channels, array sweeps [, string entrySourceType])`
			///
			/// return lab notebook @p key for all @p sweeps that belong to the channels @p channels
			ASSERT(!ParamIsDefault(graph) && !IsEmpty(graph), "Graph not specified.")

			numIndices = JSON_GetArraySize(jsonID, jsonPath)
			ASSERT(numIndices <= 4, "Maximum number of arguments exceeded.")
			ASSERT(numIndices >= 3, "At least three arguments are required.")

			JSONtype = JSON_GetType(jsonID, jsonPath + "/0")
			ASSERT(JSONtype == JSON_STRING, "first parameter needs to be a string labnotebook key")
			str = JSON_GetString(jsonID, jsonPath + "/0")

			WAVE channels = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1", graph = graph)
			ASSERT(DimSize(channels, COLS) == 2, "A channel input consists of [[channelType, channelNumber]+].")

			WAVE sweeps = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2", graph = graph)
			ASSERT(DimSize(sweeps, COLS) < 2, "Sweeps are one-dimensional.")

			mode = DATA_ACQUISITION_MODE
			if(numIndices == 4)
				JSONtype = JSON_GetType(jsonID, jsonPath + "/3")
				ASSERT(JSONtype == JSON_STRING, "Last parameter needs to be a string.")
				strswitch(JSON_GetString(jsonID, jsonPath + "/3"))
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
						ASSERT(0, "Undefined labnotebook mode. Use one in group DataAcqModes")
				endswitch
			endif

			WAVE activeChannels = SF_GetActiveChannelNumbers(graph, channels, sweeps, mode)
			WaveClear channels

			WAVE/Z settings
			Variable index

			if(BSP_IsDataBrowser(graph))
				WAVE numericalValues = DB_GetNumericalValues(graph)
				WAVE/T textualValues = DB_GetTextualValues(graph)
			endif

			Make/D/FREE/N=(DimSize(sweeps, ROWS), DimSize(activeChannels, ROWS)) outD = NaN
			Make/T/FREE/N=(DimSize(sweeps, ROWS), DimSize(activeChannels, ROWS)) outT
			for(i = 0; i < DimSize(sweeps, ROWS); i += 1)
				if(!BSP_IsDataBrowser(graph))
					WAVE/WAVE temp = SB_GetNumericalValuesWaves(graph, sweepNumber = sweeps[i])
					ASSERT(DimSize(temp, ROWS) == 1, "Unhandled number of sweeps in AnalysisBrowser map")
					WAVE numericalValues = temp[0]

					WAVE/WAVE temp = SB_GetTextualValuesWaves(graph, sweepNumber = sweeps[i])
					ASSERT(DimSize(temp, ROWS) == 1, "Unhandled number of sweeps in AnalysisBrowser map")
					WAVE/T textualValues = temp[0]
				endif

				for(j = 0; j <  DimSize(activeChannels, ROWS); j += 1)
					[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweeps[i], str, activeChannels[j][%channelNumber], activeChannels[j][%channelType], mode)
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
				Make/FREE/N=1 out = {NaN}
				break
			endif

			for(i = 0; i < DimSize(activeChannels, ROWS); i += 1)
				str = StringFromList(activeChannels[i][%channelType], ITC_CHANNEL_NAMES) + num2istr(activeChannels[i][%channelNumber])
				SetDimLabel COLS, i, $str, out
			endfor
			break
		case "log": // JSON logic debug operation
			print wv[0]
			WAVE out = wv
			break
		case "log10": // decadic logarithm
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = log(wv)
			SF_FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "cursors":
			Make/FREE/N=(DimSize(wvT, ROWS)) out = NaN
			for(i = 0; i < DimSize(wvT, ROWS); i += 1)
				ASSERT(GrepString(wvT[i], "^(?i)[A-J]$"), "Invalid Cursor Name")
				if(ParamIsDefault(graph))
					out[i] = xcsr($wvT[i])
				else
					info = CsrInfo($wvT[i], graph)
					if(IsEmpty(info))
						continue
					endif
					out[i] = xcsr($wvT[i], graph)
				endif
			endfor
			break
		case "findlevel":
			// findlevel(data, level, [edge])
			numIndices = JSON_GetArraySize(jsonID, jsonPath)
			ASSERT(numIndices <=3, "Maximum number of arguments exceeded.")
			ASSERT(numIndices > 1, "At least two arguments.")
			WAVE data = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
			WAVE level = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
			ASSERT(DimSize(level, ROWS) == 1, "Too many input values for parameter level")
			ASSERT(IsNumericWave(level), "level parameter must be numeric")
			if(numIndices == 3)
				WAVE edge = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2")
				ASSERT(DimSize(edge, ROWS) == 1, "Too many input values for parameter level")
				ASSERT(IsNumericWave(edge), "level parameter must be numeric")
			else
				Make/FREE edge = {0}
			endif

			WAVE out = FindLevelWrapper(data, level[0], edge[0], FINDLEVEL_MODE_SINGLE)
			break
		case "apfrequency":
			// apfrequency(data, [frequency calculation method], [spike detection crossing level])
			numIndices = JSON_GetArraySize(jsonID, jsonPath)
			ASSERT(numIndices <=3, "Maximum number of arguments exceeded.")
			ASSERT(numIndices >= 1, "At least one argument.")

			WAVE data = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
			if(numIndices == 3)
				WAVE level = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/2", graph = graph)
				ASSERT(DimSize(level, ROWS) == 1, "Too many input values for parameter level")
				ASSERT(IsNumericWave(level), "level parameter must be numeric")
			else
				Make/FREE/N=1 level = {0}
			endif

			if(numIndices >= 2)
				WAVE method = SF_FormulaExecutor(jsonID, jsonPath = jsonPath + "/1", graph = graph)
				ASSERT(DimSize(method, ROWS) == 1, "Too many input values for parameter method")
				ASSERT(IsNumericWave(method), "method parameter must be numeric.")
				ASSERT(method[0] == SF_APFREQUENCY_FULL || method[0] == SF_APFREQUENCY_INSTANTANEOUS ||  method[0] == SF_APFREQUENCY_APCOUNT, "method parameter is invalid")
			else
				Make/FREE method = {SF_APFREQUENCY_FULL}
			endif

			WAVE levels = FindLevelWrapper(data, level[0], FINDLEVEL_EDGE_INCREASING, FINDLEVEL_MODE_MULTI)
			variable numSets = DimSize(levels, ROWS)
			Make/FREE/N=(numSets) levelPerSet = str2num(GetDimLabel(levels, ROWS, p))

			// @todo we assume that the x-axis of data has a ms scale for FULL/INSTANTANEOUS
			switch(method[0])
				case SF_APFREQUENCY_FULL:
					Make/N=(numSets)/D/FREE outD = levelPerSet[p] / (DimDelta(data, ROWS) * DimSize(data, ROWS)) * 1e3
					break
				case SF_APFREQUENCY_INSTANTANEOUS:
					Make/N=(numSets)/D/FREE outD

					for(i = 0; i < numSets; i += 1)
						if(levelPerSet[i] <= 1)
							outD[i] = 0
						else
							Make/FREE/D/N=(levelPerSet[i] - 1) distances
							distances[0, levelPerSet[i] - 2] = levels[i][p + 1] - levels[i][p]
							outD[i] = 1.0 / Mean(distances) * 1e3
						endif
					endfor
					break
				case SF_APFREQUENCY_APCOUNT:
					Make/N=(numSets)/D/FREE outD = levelPerSet[p]
					break
			endswitch

			WAVE out = outD

			break
		default:
			ASSERT(0, "Undefined Operation")
	endswitch
	/// @}

	return out
End

/// @brief  Plot the formula using the data from graph
///
/// @param graph  graph to pass to SF_FormulaExecutor
/// @param formula formula to plot
/// @param dfr     [optional, default current] working dataFolder
Function SF_FormulaPlotter(graph, formula, [dfr])
	String graph
	String formula
	DFREF dfr

	String formula0, formula1, trace, axes
	Variable i, numTraces, splitTraces, splitY, splitX
	Variable dim1Y, dim2Y, dim1X, dim2X
	String win
	String traceName = "formula"

	if(ParamIsDefault(dfr))
		dfr = GetDataFolderDFR()
	endif

	SplitString/E=SF_SWEEPFORMULA_REGEXP formula, formula0, formula1
	SF_FormulaError(dfr, V_Flag == 2 || V_flag == 1, "Display command must follow the \"y[ vs x]\" pattern.")
	if(V_Flag == 2)
		WAVE/Z wv = SF_FormulaExecutor(SF_FormulaParser(SF_FormulaPreParser(formula1)), graph = graph)
		SF_FormulaError(dfr, WaveExists(wv), "Error in x part of formula.")
		dim1X = max(1, DimSize(wv, COLS))
		dim2X = max(1, DimSize(wv, LAYERS))
		Redimension/N=(-1, dim1X * dim2X)/E=1 wv /// @todo Removes dimension labels in COLS and LAYERS

		WAVE wvX = GetSweepFormulaX(dfr)
		if(WaveType(wv, 1) == WaveType(wvX, 1))
			Duplicate/O wv $GetWavesDataFolder(wvX, 2)
		else
			MoveWaveWithOverWrite(wvX, wv)
		endif
		WAVE wvX = GetSweepFormulaX(dfr)
	endif

	WAVE/Z wv = SF_FormulaExecutor(SF_FormulaParser(SF_FormulaPreParser(formula0)), graph = graph)
	SF_FormulaError(dfr, WaveExists(wv), "Error in y part of formula.")
	dim1Y = max(1, DimSize(wv, COLS))
	dim2Y = max(1, DimSize(wv, LAYERS))
	Redimension/N=(-1, dim1Y * dim2Y)/E=1 wv /// @todo Removes dimension labels in COLS and LAYERS

	WAVE wvY = GetSweepFormulaY(dfr)
	if(WaveType(wv, 1) == WaveType(wvY, 1))
		Duplicate/O wv $GetWavesDataFolder(wvY, 2)
	else
		MoveWaveWithOverWrite(wvY, wv)
	endif
	WAVE wvY = GetSweepFormulaY(dfr)

	win = BSP_GetFormulaGraph(graph)

	if(!WindowExists(win))
		Display/N=$win as win
		win = S_name
	endif

	WAVE/T/Z cursorInfos = GetCursorInfos(win)
	WAVE axesRanges = GetAxesRanges(win)
	RemoveTracesFromGraph(win)
	ModifyGraph/W=$win swapXY = 0

	SF_FormulaError(dfr, !(IsTextWave(wvY) && IsTextWave(wvX)), "One wave needs to be numeric for plotting")
	if(IsTextWave(wvY) && WaveExists(wvX))
		SF_FormulaError(dfr, WaveExists(wvX), "Cannot plot a single text wave")
		ModifyGraph/W=$win swapXY = 1
		WAVE dummy = wvY
		WAVE wvY = wvX
		WAVE wvX = dummy
	endif

	if(!WaveExists(wvX))
		numTraces = dim1Y * dim2Y
		for(i = 0; i < numTraces; i += 1)
			trace = traceName + num2istr(i)
			AppendTograph/W=$win wvY[][i]/TN=$trace
		endfor
	elseif((dim1X * dim2X == 1) && (dim1Y * dim2Y == 1)) // 1D
		if(DimSize(wvY, ROWS) == 1) // 0D vs 1D
			numTraces = DimSize(wvX, ROWS)
			for(i = 0; i < numTraces; i += 1)
				trace = traceName + num2istr(i)
				AppendTograph/W=$win wvY[][0]/TN=$trace vs wvX[i][]
			endfor
		elseif(DimSize(wvX, ROWS) == 1) // 1D vs 0D
			numTraces = DimSize(wvY, ROWS)
			for(i = 0; i < numTraces; i += 1)
				trace = traceName + num2istr(i)
				AppendTograph/W=$win wvY[i][]/TN=$trace vs wvX[][0]
			endfor
		else // 1D vs 1D
			splitTraces = min(DimSize(wvY, ROWS), DimSize(wvX, ROWS))
			numTraces = floor(max(DimSize(wvY, ROWS), DimSize(wvX, ROWS)) / splitTraces)
			if(mod(max(DimSize(wvY, ROWS), DimSize(wvX, ROWS)), splitTraces) == 0)
				DebugPrint("Unmatched Data Alignment in ROWS.")
			endif
			for(i = 0; i < numTraces; i += 1)
				trace = traceName + num2istr(i)
				splitY = SF_SplitPlotting(wvY, ROWS, i, splitTraces)
				splitX = SF_SplitPlotting(wvX, ROWS, i, splitTraces)
				AppendTograph/W=$win wvY[splitY, splitY + splitTraces - 1][0]/TN=$trace vs wvX[splitX, splitX + splitTraces - 1][0]
			endfor
		endif
	elseif(dim1Y * dim2Y == 1) // 1D vs 2D
		numTraces = dim1X * dim2X
		for(i = 0; i < numTraces; i += 1)
			trace = traceName + num2istr(i)
			AppendTograph/W=$win wvY[][0]/TN=$trace vs wvX[][i]
		endfor
	elseif(dim1X * dim2X == 1) // 2D vs 1D
		numTraces = dim1Y * dim2Y
		for(i = 0; i < numTraces; i += 1)
			trace = traceName + num2istr(i)
			AppendTograph/W=$win wvY[][i]/TN=$trace vs wvX
		endfor
	else // 2D vs 2D
		numTraces = WaveExists(wvX) ? max(1, max(dim1Y * dim2Y, dim1X * dim2X)) : max(1, dim1Y * dim2Y)
		if(DimSize(wvY, ROWS) == DimSize(wvX, ROWS))
			DebugPrint("Size missmatch in data rows for plotting waves.")
		endif
		if(DimSize(wvY, ROWS) == DimSize(wvX, ROWS))
			DebugPrint("Size missmatch in entity columns for plotting waves.")
		endif
		for(i = 0; i < numTraces; i += 1)
			trace = traceName + num2istr(i)
			if(WaveExists(wvX))
				AppendTograph/W=$win wvY[][min(dim1Y * dim2Y - 1, i)]/TN=$trace vs wvX[][min(dim1X * dim2X - 1, i)]
			else
				AppendTograph/W=$win wvY[][i]/TN=$trace
			endif
		endfor
	endif

	// @todo preserve channel information in LAYERS
	// Redimension/N=(-1, dim1Y, dim2Y)/E=1 wvY
	// Redimension/N=(-1, dim1X, dim2X)/E=1 wvX

	if(DimSize(wvY, ROWS) < SF_MAX_NUMPOINTS_FOR_MARKERS \
		&& (!WaveExists(wvX) \
		|| DimSize(wvx, ROWS) <  SF_MAX_NUMPOINTS_FOR_MARKERS))
		ModifyGraph/W=$win mode=3,marker=19
	endif

	RestoreCursors(win, cursorInfos)
	SetAxesRanges(win, axesRanges)
End

/// @brief utility function for @c SF_FormulaPlotter
///
/// split dimension @p dim of wave @p wv into slices of size @p split and get
/// the starting index @p i
///
static Function SF_SplitPlotting(wv, dim, i, split)
	WAVE wv
	Variable dim, i, split

	return min(i, floor(DimSize(wv, dim) / split) - 1) * split
End

static Function/WAVE SF_GetSweepForFormula(graph, range, channels, sweeps)
	String graph
	WAVE range, channels, sweeps

	variable i, j, rangeStart, rangeEnd, pOffset, delta
	string dimLabel
	variable channelType = -1
	variable xStart = NaN, xEnd = NaN

	ASSERT(WindowExists(graph), "graph window does not exist")
	ASSERT(DimSize(range, ROWS) == 2, "A range is of the form [rangeStart, rangeEnd].")
	ASSERT(DimSize(channels, COLS) == 2, "A channel input consists of [[channelName, channelNumber]+].")
	ASSERT(DimSize(sweeps, COLS) < 2, "Sweeps are one-dimensional.")
	ASSERT(DimSize(range, COLS) <= 1, "Multidimensional ranges not fully implemented.")

	// @todo calls cost intense graph functions to get wave locations
	WAVE/T/Z traces = PA_GetTraceInfos(graph)
	if(!WaveExists(traces) || DimSize(traces, ROWS) == 0)
		DebugPrint("No traces found for extracting sweep wave locations.")
		return $""
	endif
	SortColumns/A/DIML/KNDX={FindDimLabel(traces, COLS, "channelType"), FindDimLabel(traces, COLS, "channelNumber"), FindDimLabel(traces, COLS, "sweepNumber")} sortWaves=traces

	Make/FREE/N=(DimSize(sweeps, ROWS), DimSize(channels, ROWS)) indices = NaN
	for(i = 0; i < DimSize(sweeps, ROWS); i += 1)
		WAVE/Z sweepListIndex = FindIndizes(traces, colLabel = "sweepNumber", var = sweeps[i])
		if(!WaveExists(sweepListIndex))
			continue
		endif
		for(j = 0; j < DimSize(channels, ROWS); j += 1)
			if(channelType != channels[j][%channelType])
				channelType = channels[j][%channelType]
				WAVE channelTypeIndex = FindIndizes(traces, colLabel = "channelType", str = StringFromList(channelType, ITC_CHANNEL_NAMES))
			endif
			if(!WaveExists(channelTypeIndex))
				continue
			endif
			WAVE channelNumberIndex = FindIndizes(traces, colLabel = "channelNumber", var = channels[j][%channelNumber])
			if(!WaveExists(channelNumberIndex))
				continue
			endif

			// find matching index in @c traces wave
			Concatenate/FREE {sweepListIndex, channelTypeIndex, channelNumberIndex}, index
			Redimension/N=(numpnts(index))/E=1 index
			Sort index, index
			Extract/FREE index, matches, (p > 1 && (index[p] == index[p - 1]) && (index[p] == index[p - 2]))
			WaveClear index
			if(DimSize(matches, ROWS) == 0)
				continue
			endif
			ASSERT(DimSize(matches, ROWS) == 1, "More than one matching sweep for this sweepNumber, channelType, and channelNumber combination.")
			indices[i][j] = matches[0]
			WaveClear matches
		endfor
	endfor

	// ASSERT if sweeps are from different experiments
	Duplicate/FREE indices wv
	Redimension/N=(numpnts(wv))/E=1 wv
	WaveTransform zapNaNs, wv
	if(DimSize(wv, ROWS) == 0)
		DebugPrint("No matching sweep.")
		return $""
	endif
	Make/FREE/T/N=(DimSize(wv, ROWS)) experiments
	experiments[] = traces[wv][%experiment]
	WaveClear wv
	WAVE/Z uniqueExperiments = GetUniqueEntries(experiments)
	ASSERT(DimSize(uniqueExperiments, ROWS) == 1, "Sweep data is from more than one experiment. This is currently not supported.")

	// get data wave dimensions
	Make/FREE/U/I/N=(DimSize(sweeps, ROWS), DimSize(channels, ROWS)) pStart, pEnd
	for(i = 0; i < DimSize(sweeps, ROWS); i += 1)
		for(j = 0; j < DimSize(channels, ROWS); j += 1)
			if(IsNaN(indices[i][j]))
				continue
			endif
			WAVE sweep = $(traces[indices[i][j]][%fullPath])
			ASSERT(DimSize(sweep, COLS) <= 1, "Sweeps need to be one-dimensional.")

			delta = max(delta, DimDelta(sweep, ROWS))
			ASSERT(delta == DimDelta(sweep, ROWS), "Sweeps are not equally spaced. Data would need to get resampled.")

			if(DimSize(range, COLS) == DimSize(sweeps, ROWS) && DimSize(range, LAYERS) == DimSize(channels, ROWS))
				rangeStart = range[0][i][j]
				rangeEnd = range[1][i][j]
			else
				rangeStart = range[0]
				rangeEnd = range[1]
			endif
			ASSERT(!IsNaN(rangeStart) && !IsNaN(rangeEnd), "Specified range not valid.")

			pStart[i][j] = ScaleToIndexWrapper(sweep, rangeStart, ROWS)
			pEnd[i][j] = ScaleToIndexWrapper(sweep, rangeEnd, ROWS)

			if(IsNaN(xStart) && IsNaN(xEnd))
				xStart = IndexToScale(sweep, pStart[i][j], ROWS)
				xEnd = IndexToScale(sweep, pEnd[i][j], ROWS)
			else
				xStart = min(IndexToScale(sweep, pStart[i][j], ROWS), xStart)
				xEnd = max(IndexToScale(sweep, pEnd[i][j], ROWS), xEnd)
			endif
		endfor
	endfor

	// combine sweeps to data wave
	Make/FREE/D/N=((xEnd - xStart + 1) / delta, DimSize(sweeps, ROWS), DimSize(channels, ROWS)) sweepData = NaN
	SetScale/P x, xStart, delta, sweepData
	for(i = 0; i < DimSize(sweeps, ROWS); i += 1)
		for(j = 0; j < DimSize(channels, ROWS); j += 1)
			if(IsNaN(indices[i][j]))
				continue
			endif
			WAVE sweep = $(traces[indices[i][j]][%fullPath])

			pOffset = ScaleToIndexWrapper(sweepData, IndexToScale(sweep, pStart[i][j], ROWS), ROWS)
			MultiThread sweepData[pOffset, pOffSet + (pEnd[i][j] - pStart[i][j])][i][j] = sweep[pStart[i][j] + (p - pOffset)]

			if(i == 0)
				dimLabel = StringFromList(channels[j][%channelType], ITC_CHANNEL_NAMES) + num2istr(channels[j][%channelNumber])
				SetDimLabel LAYERS, j, $dimLabel, sweepData
			endif
		endfor

		sprintf dimLabel, "sweep%d", sweeps[i]
		SetDimLabel COLS, i, $dimLabel, sweepData
	endfor

	return sweepData
End

/// @brief transfer the wave scaling from one wave to another
///
/// Note: wave scale transfer requires wave units for the first wave in the array that
///
/// @param source    Wave whos scaling should get transferred
/// @param dest      Wave that accepts the new scaling
/// @param dimSource dimension of the source wave
/// @param dimDest   dimension of the destination wave
///
/// @return 0 if wave scaling was transferred, 1 if not
static Function SF_FormulaWaveScaleTransfer(source, dest, dimSource, dimDest)
	WAVE source, dest
	Variable dimSource, dimDest

	string sourceUnit, destUnit

	sourceUnit = WaveUnits(source, dimSource)
	destUnit = WaveUnits(dest, dimDest)

	if(IsEmpty(sourceUnit) && IsEmpty(destUnit))
		return 1
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
			return 1
	endswitch

	return 0
End

/// @brief Use the labnotebook information to return the active channel numbers
///        for a given set of sweeps
///
/// @param graph           DataBrowser or SweepBrowser reference graph
/// @param channels        @c SF_FormulaExecutor style @c channels() wave
/// @param sweeps          @c SF_FormulaExecutor style @c sweeps() wave
/// @param entrySourceType type of the labnotebook entry, one of @ref DataAcqModes.
///                        If you don't care about the entry source type pass #UNKNOWN_MODE.
/// @return a @c SF_FormulaExecutor style @c channels() wave with two columns
///         containing channelType and channelNumber
static Function/WAVE SF_GetActiveChannelNumbers(graph, channels, sweeps, entrySourceType)
	string graph
	WAVE channels, sweeps
	variable entrySourceType

	variable i, j, k, channelType, channelNumber, numIndices
	string setting, msg

	WAVE/Z settings
	Variable index

	ASSERT(windowExists(graph), "DB/SB not specified.")
	ASSERT(DimSize(channels, COLS) == 2, "A channel input consists of [[channelType, channelNumber]+].")
	SetDimLabel COLS, 0, channelType, channels
	SetDimLabel COLS, 1, channelNumber, channels
	ASSERT(DimSize(sweeps, COLS) < 2, "Sweeps are one-dimensional.")
	ASSERT((IsNaN(UNKNOWN_MODE) && IsNaN(entrySourceType)) || \
		entrySourceType == DATA_ACQUISITION_MODE || \
		entrySourceType == TEST_PULSE_MODE || \
		entrySourceType == NUMBER_OF_LBN_DAQ_MODES, \
		"Undefined labnotebook mode. Use one in group DataAcqModes")

	if(BSP_IsDataBrowser(graph))
		WAVE numericalValues = DB_GetNumericalValues(graph)
	endif

	Make/FREE/WAVE/N=2 channelNumbers
	Make/FREE/N=(GetNumberFromType(itcVar=ITC_XOP_CHANNEL_TYPE_ADC)) channelNumbersAD = NaN
	channelNumbers[ITC_XOP_CHANNEL_TYPE_ADC] = channelNumbersAD
	Make/FREE/N=(GetNumberFromType(itcVar=ITC_XOP_CHANNEL_TYPE_DAC)) channelNumbersDA = NaN
	channelNumbers[ITC_XOP_CHANNEL_TYPE_DAC] = channelNumbersDA

	// search sweeps for active channels
	for(i = 0; i < DimSize(sweeps, ROWS); i += 1)
		ASSERT(IsInteger(sweeps[i]), "Unsupported sweep number in sweeps() wave")
		if(!BSP_IsDataBrowser(graph))
			WAVE/WAVE temp = SB_GetNumericalValuesWaves(graph, sweepNumber = sweeps[i])
			ASSERT(DimSize(temp, ROWS) == 1, "Unhandled number of sweeps in AnalysisBrowser map")
			WAVE numericalValues = temp[0]
			WaveClear temp
		endif

		for(j = 0; j < DimSize(channels, ROWS); j += 1)
			channelType = channels[j][0]
			switch(channelType)
				case ITC_XOP_CHANNEL_TYPE_DAC:
					setting = "DAC"
					break
				case ITC_XOP_CHANNEL_TYPE_ADC:
					setting = "ADC"
					break
				default:
					sprintf msg, "Unhandled channel type %d in channels() at position %d", channelType, j
					ASSERT(0, msg)
			endswitch

			channelNumber = channels[j][1]
			WAVE wv = channelNumbers[channelType]
			for(k = 0; k < DimSize(wv, ROWS); k += 1)
				if(!IsNaN(wv[k]))
					continue
				endif
				if(!IsNaN(channelNumber) && channelNumber != k)
					continue
				endif
				[settings, index] = GetLastSettingChannel(numericalValues, $"", sweeps[i], setting, k, channelType, entrySourceType)
				if(!WaveExists(settings))
					continue
				endif
				wv[k] = settings[index]
			endfor
		endfor
	endfor

	// remove unmatched channel numbers
	for(i = 0; i < DimSize(channelNumbers, ROWS); i += 1)
		WAVE wv = channelNumbers[i]
		WaveTransform zapNaNs, wv
		numIndices += DimSize(wv, ROWS)
	endfor

	// create channels wave
	Make/FREE/N=(numIndices, 2) out
	SetDimLabel COLS, 0, channelType, out
	SetDimLabel COLS, 1, channelNumber, out
	numIndices = 0
	for(i = 0; i < DimSize(channelNumbers, ROWS); i += 1)
		WAVE wv = channelNumbers[i]
		for(j = 0; j < DimSize(wv, ROWS); j += 1)
			out[numIndices][%channelType] = i
			out[numIndices][%channelNumber] = wv[j]
			numIndices += 1
		endfor
	endfor

	return out
End

Function SF_button_sweepFormula_check(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String mainPanel, bsPanel, yFormula, xFormula, formula_nb, formula
	Variable numFormulae, jsonIDx, jsonIDy

	switch(ba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(ba.win)
			bsPanel = BSP_GetPanel(mainPanel)

			if(BSP_IsDataBrowser(bsPanel) && !BSP_HasBoundDevice(bsPanel))
				DebugPrint("Unbound device in DataBrowser")
				break
			endif

			DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_PANEL_FOLDER)

			formula_nb = BSP_GetSFFormula(ba.win)
			formula = GetNotebookText(formula_nb)

			SetValDisplay(bsPanel, "status_sweepFormula_parser", var=1)
			SetSetVariableString(bsPanel, "setvar_sweepFormula_parseResult", ":)")

			SVAR result = $GetSweepFormulaParseErrorMessage(dfr)
			result = ""

			NVAR jsonID = $GetSweepFormulaJSONid(dfr)

			SplitString/E=SF_SWEEPFORMULA_REGEXP formula, yFormula, xFormula
			numFormulae = V_flag
			if(numFormulae != 2 && numFormulae != 1)
				DebugPrint("Display command must follow the \"y[ vs x]\" pattern. Can not evaluate parsing status.")
				return 0
			endif

			try
				jsonIDy = SF_FormulaParser(SF_FormulaPreParser(yFormula))
				if(numFormulae == 1)
					jsonID = jsonIDy
					return 0
				endif
				JSON_Release(jsonID, ignoreErr = 1)
				jsonID = JSON_New()
				JSON_AddObjects(jsonID, "")
				JSON_AddJSON(jsonID, "/y", jsonIDy)
				JSON_Release(jsonIDy)
				DebugPrint("y part of formula is valid.")
				jsonIDx = SF_FormulaParser(SF_FormulaPreParser(xFormula))
				JSON_AddJSON(jsonID, "/x", jsonIDx)
				JSON_Release(jsonIDx)
			catch
				SetValDisplay(bsPanel, "status_sweepFormula_parser", var=0)
				JSON_Release(jsonID, ignoreErr = 1)
				SVAR result = $GetSweepFormulaParseErrorMessage(dfr)
				SetSetVariableString(bsPanel, "setvar_sweepFormula_parseResult", result)
			endtry
			break
	endswitch

	return 0
End

/// @brief checks if SweepFormula (SF) is active.
Function SF_IsActive(win)
	string win

	return BSP_IsActive(win, MIES_BSP_SF)
End

Function SF_button_sweepFormula_display(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String mainPanel, code, formula_nb, bsPanel

	switch(ba.eventCode)
		case 2: // mouse up
			formula_nb = BSP_GetSFFormula(ba.win)
			mainPanel = GetMainWindow(ba.win)
			bsPanel = BSP_GetPanel(mainPanel)

			code = GetNotebookText(formula_nb)

			if(IsEmpty(code))
				break
			endif

			if(BSP_IsDataBrowser(bsPanel) && !BSP_HasBoundDevice(bsPanel))
				DebugPrint("Databrowser has unbound device")
				break
			endif

			DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_PANEL_FOLDER)

			try
				ClearRTError()
				SF_FormulaPlotter(mainPanel, code, dfr = dfr); AbortONRTE
			catch
				ClearRTError()
				SVAR result = $GetSweepFormulaParseErrorMessage(dfr)
				SetSetVariableString(bsPanel, "setvar_sweepFormula_parseResult", result)
				break
			endtry

			SetSetVariableString(bsPanel, "setvar_sweepFormula_parseResult", ":)")

			break
	endswitch

	return 0
End

Function SF_TabProc_Formula(tca) : TabControl
	STRUCT WMTabControlAction &tca

	String mainPanel, bsPanel, json_nb, text
	variable jsonID

	switch( tca.eventCode )
		case 2: // mouse up
			mainPanel = GetMainWindow(tca.win)
			bsPanel = BSP_GetPanel(mainPanel)
			json_nb = BSP_GetSFJSON(mainPanel)

			ReplaceNotebookText(json_nb, "")

			if(tca.tab == 1)
				PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_check")
			endif

			if(BSP_IsDataBrowser(bsPanel) && !BSP_HasBoundDevice(bsPanel))
				DebugPrint("Databrowser has unbound device")
				break
			endif

			DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_PANEL_FOLDER)

			if(tca.tab == 1) // JSON
				jsonID = ROVar(GetSweepFormulaJSONid(dfr))
				text = JSON_Dump(jsonID, indent = 2)
				text = NormalizeToEOL(text, "\r")
				ReplaceNotebookText(json_nb, text)
			endif
			break
	endswitch

	return 0
End
