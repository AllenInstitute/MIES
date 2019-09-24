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
static Constant STATE_WHITESPACE = 10
static Constant STATE_COMMENT = 11
static Constant STATE_NEWLINE = 12
static Constant STATE_OPERATION = 13

static Constant ACTION_SKIP = 0
static Constant ACTION_COLLECT = 1
static Constant ACTION_CALCULATION = 2
static Constant ACTION_SAMECALCULATION = 3
static Constant ACTION_HIGHERORDER = 4
static Constant ACTION_ARRAYELEMENT = 5
static Constant ACTION_PARENTHESIS = 6
static Constant ACTION_FUNCTION = 7
static Constant ACTION_ARRAY = 8

/// Regular expression which extracts both formulas from `$a vs $b`
static StrConstant SWEEPFORMULA_REGEXP = "^(.+?)(?:\\bvs\\b(.+))?$"

Function FormulaCheck(condition, message)
	Variable condition
	String message

	if(!condition)
		Abort message
	endif
End

/// @brief preparse user input to correct formula patterns
///
/// @return parsed formula
Function/S FormulaPreParser(formula)
	String formula

	FormulaCheck(CountSubstrings(formula, "(") == CountSubstrings(formula, ")"), "Bracket missmatch in formula.")
	FormulaCheck(CountSubstrings(formula, "[") == CountSubstrings(formula, "]"), "Array bracket missmatch in formula.")

	formula = ReplaceString("...", formula, "…")

	return formula
End

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
			case "…":
				state = STATE_OPERATION
				break
			case "(":
				level += 1
				break
			case ")":
				level -= 1
				if(!cmpstr(buffer[0], "("))
					state = STATE_PARENTHESIS
					break
				endif
				if(GrepString(buffer, "^[A-Za-z]"))
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
			case "#":
				state = STATE_COMMENT
				break
			case "\r":
			case "\n":
				state = STATE_NEWLINE
				break
			case " ":
			case "\t":
				state = STATE_WHITESPACE
				break
			default:
				if(!(char2num(token) > 0))
					continue
				endif
				state = STATE_COLLECT
				FormulaCheck(GrepString(token, "[A-Za-z0-9_\.:;]"), "undefined pattern in formula: " + formula[i,i+5])
		endswitch
		if(level > 0 || arrayLevel > 0)
			state = STATE_DEFAULT
		endif

		// state transition
		if(lastState == STATE_COMMENT && state != STATE_NEWLINE)
			action = ACTION_SKIP
		elseif(state != lastState)
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
				case STATE_OPERATION:
					if(!cmpstr(buffer, ""))
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
				case STATE_NEWLINE:
				case STATE_WHITESPACE:
				case STATE_COMMENT:
					action = ACTION_SKIP
					break
				case STATE_COLLECT:
				case STATE_DEFAULT:
					action = ACTION_COLLECT
					break
				default:
					FormulaCheck(0, "Encountered undefined transition " + num2str(state))
			endswitch
			lastState = state
		endif

		// action
		switch(action)
			case ACTION_COLLECT:
				buffer += token
			case ACTION_SKIP:
				token = ""
				continue
			case ACTION_FUNCTION:
				tempPath = jsonPath
				if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
					JSON_AddObjects(jsonID, jsonPath)
					tempPath += "/" + num2str(JSON_GetArraySize(jsonID, jsonPath) - 1)
				endif
				tempPath += "/"
				parenthesisStart = strsearch(buffer, "(", 0, 0)
				tempPath += EscapeJsonPath(buffer[0, parenthesisStart - 1])
				jsonIDdummy = FormulaParser(buffer[parenthesisStart + 1, inf])
				if(JSON_GetType(jsonIDdummy, "") != JSON_ARRAY)
					JSON_AddTreeArray(jsonID, tempPath)
				endif
				JSON_AddJSON(jsonID, tempPath, jsonIDdummy)
				JSON_Release(jsonIDdummy)
				break
			case ACTION_PARENTHESIS:
				JSON_AddJSON(jsonID, jsonPath, FormulaParser(buffer[1, inf]))
				break
			case ACTION_HIGHERORDER:
				lastCalculation = state
				if(!!cmpstr(buffer, ""))
					JSON_AddJSON(jsonID, jsonPath, FormulaParser(buffer))
				endif
				jsonPath = EscapeJsonPath(token)
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
			case ACTION_ARRAY:
				FormulaCheck(!cmpstr(buffer[0], "["), "Encountered array ending without array start.")
				jsonIDarray = JSON_New()
				jsonIDdummy = FormulaParser(buffer[1,inf])
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
				jsonPath += "/" + EscapeJsonPath(token)
			case ACTION_ARRAYELEMENT:
				JSON_AddTreeArray(jsonID, jsonPath)
				lastCalculation = state
			case ACTION_SAMECALCULATION:
			default:
				if(strlen(buffer) > 0)
					JSON_AddJSON(jsonID, jsonPath, FormulaParser(buffer))
				endif
		endswitch
		buffer = ""
		token = ""
	endfor

	// last element (recursion)
	if(!cmpstr(buffer, formula))
		if(GrepString(buffer, "^(?i)[0-9]+(?:\.[0-9]+)?(?:[\+-]?E[0-9]+)?$"))
			JSON_AddVariable(jsonID, jsonPath, str2num(formula))
		else
			JSON_AddString(jsonID, jsonPath, buffer)
		endif
	elseif(strlen(buffer) > 0)
		JSON_AddJSON(jsonID, jsonPath, FormulaParser(buffer))
	endif

	return jsonID
End

// @brief add escape characters to a path element
Function/S EscapeJsonPath(str)
	String str

	return ReplaceString("/", str, "~1")
End

Function/WAVE FormulaExecutor(jsonID, [jsonPath, graph])
	Variable jsonID
	String jsonPath
	String graph

	Variable i, j, numIndices, JSONtype, mode

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
			return FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2str(indices[0]), graph = graph)
		endif
		for(i = 0; i < DimSize(indices, ROWS); i += 1)
			WAVE element = FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2str(indices[i]), graph = graph)
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
			FormulaWaveScaleTransfer(element, out, ROWS, COLS)
			FormulaWaveScaleTransfer(element, out, COLS, LAYERS)
			FormulaWaveScaleTransfer(element, out, LAYERS, CHUNKS)
			out[indices[i]][0, max(0, DimSize(element, ROWS) - 1)][0, max(0, DimSize(element, COLS) - 1)][0, max(0, DimSize(element, LAYERS) - 1)] = element[q][r][s]
		endfor

		EXTRACT/FREE/INDX types, indices, types[p] == JSON_NUMERIC
		for(i = 0; i < DimSize(indices, ROWS); i += 1)
			out[indices[i]][][][] = out[indices[i]][0][0][0]
		endfor

		topArraySize[1,*] = topArraySize[p] == 1 ? 0 : topArraySize[p]
		Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])/E=1 out

		return out
	endif

	// operation evaluation
	ASSERT(JSONtype == JSON_OBJECT, "Topmost element needs to be an object")
	WAVE/T operations = JSON_GetKeys(jsonID, jsonPath)
	ASSERT(DimSize(operations, ROWS) == 1, "Only one operation is allowed")
	jsonPath += "/" + EscapeJsonPath(operations[0])
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
		case "wave":
			break
		default:
			WAVE wv = FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
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
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
			FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "+":
			MatrixOP/FREE out = sumCols(wv)^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
			FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "~1": // division
			ASSERT(DimSize(wv, ROWS) >= 2, "At least two operands are required")
			MatrixOP/FREE out = (row(wv, 0) / productCols(subRange(wv, 1, numRows(wv) - 1, 0, numCols(wv) - 1)))^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
			FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "*":
			MatrixOP/FREE out = productCols(wv)^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			FormulaWaveScaleTransfer(wv, out, LAYERS, COLS)
			FormulaWaveScaleTransfer(wv, out, CHUNKS, LAYERS)
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
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = minCols(wv)^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "max":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = maxCols(wv)^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "avg":
		case "mean":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = averageCols(wv)^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "rms":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = sqrt(averageCols(magsqr(wv)))^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "variance":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = (sumCols(magSqr(wv - rowRepeat(averageCols(wv), numRows(wv))))/(numRows(wv) - 1))^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "stdev":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = (sqrt(sumCols(powR(wv - rowRepeat(averageCols(wv), numRows(wv)), 2))/(numRows(wv) - 1)))^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
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
			WAVE data = FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
			WAVE lowPassCutoff = FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
			ASSERT(DimSize(lowPassCutoff, ROWS) == 1, "Too many input values for parameter lowPassCutoff")
			ASSERT(IsNumericWave(lowPassCutoff), "lowPassCutoff parameter must be numeric")
			WAVE highPassCutoff = FormulaExecutor(jsonID, jsonPath = jsonPath + "/2")
			ASSERT(DimSize(highPassCutoff, ROWS) == 1, "Too many input values for parameter highPassCutoff")
			ASSERT(IsNumericWave(highPassCutoff), "highPassCutoff parameter must be numeric")
			WAVE order = FormulaExecutor(jsonID, jsonPath = jsonPath + "/3")
			ASSERT(DimSize(order, ROWS) == 1, "Too many input values for parameter order")
			ASSERT(IsNumericWave(order), "order parameter must be numeric")
			FilterIIR/HI=(highPassCutoff[0])/LO=(lowPassCutoff[0])/ORD=(order[0])/DIM=(ROWS) data
			ASSERT(V_flag == 0, "FilterIIR returned error")
			WAVE out = data
			break
		case "time":
		case "xvalues":
			Make/FREE/N=(DimSize(wv, ROWS), DimSize(wv, COLS), DimSize(wv, LAYERS), DimSize(wv, CHUNKS)) out = DimOffset(wv, ROWS) + p * DimDelta(wv, ROWS)
			break
		case "setscale":
			/// `setscale(data, [dim, [dimOffset, [dimDelta[, unit]]]])
			numIndices = JSON_GetArraySize(jsonID, jsonPath)
			ASSERT(numIndices < 6, "Maximum number of arguments exceeded.")
			ASSERT(numIndices > 1, "At least two arguments.")
			WAVE data = FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
			WAVE/T dimension = FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
			ASSERT(DimSize(dimension, ROWS) == 1 && GrepString(dimension[0], "[x,y,z,t]") , "undefined input for dimension")

			if(numIndices >= 3)
				WAVE offset = FormulaExecutor(jsonID, jsonPath = jsonPath + "/2")
				ASSERT(DimSize(offset, ROWS) == 1, "wrong usage of argument")
			else
				Make/FREE/N=1 offset  = {0}
			endif
			if(numIndices >= 4)
				WAVE delta = FormulaExecutor(jsonID, jsonPath = jsonPath + "/3")
				ASSERT(DimSize(delta, ROWS) == 1, "wrong usage of argument")
			else
				Make/FREE/N=1 delta = {1}
			endif
			if(numIndices == 5)
				WAVE/T unit = FormulaExecutor(jsonID, jsonPath = jsonPath + "/4")
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
			WAVE/T wavelocation = FormulaExecutor(jsonID, jsonPath = jsonPath + "/0")
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
			for(i = 0; i < numIndices; i += 1)
				JSONtype = JSON_GetType(jsonID, jsonPath + "/" + num2str(i))
				channelName = ""
				if(JSONtype == JSON_NUMERIC)
					out[i][1] = JSON_GetVariable(jsonID, jsonPath + "/" + num2str(i))
				elseif(JSONtype == JSON_STRING)
					SplitString/E=regExp JSON_GetString(jsonID, jsonPath + "/" + num2str(i)), channelName, channelNumber
					if(V_flag == 0)
						continue
					endif
					out[i][1] = str2num(channelNumber)
				endif
				ASSERT(!isFinite(out[i][1]) || out[i][1] < NUM_MAX_CHANNELS, "Maximum Number Of Channels exceeded.")
				out[i][0] = WhichListItem(channelName, ITC_CHANNEL_NAMES, ";", 0, 0)
			endfor
			out[][] = out[p][q] < 0 ? NaN : out[p][q]
			break
		case "sweeps":
			/// `sweeps([str type])`
			///  @p type: `|displayed|all`
			///           displayed (default): get (selected) sweeps
			///           al:                  get all possible sweeps
			ASSERT(JSON_GetArraySize(jsonID, jsonPath) <= 1, "Function requires 1 argument at most.")

			JSONtype = JSON_GetType(jsonID, jsonPath + "/0")
			if(JSONtype == JSON_NULL)
				wvT[0] = "displayed"
			endif

			strswitch(wvT[0])
				case "all":
					mode = OVS_SWEEP_ALL_SWEEPNO
					break
				case "displayed":
					mode = OVS_SWEEP_SELECTION_SWEEPNO
					break
				default:
					ASSERT(0, "Undefined argument")
			endswitch

			ASSERT(!ParamIsDefault(graph) && !!cmpstr(graph, ""), "Graph not specified.")
			WAVE/Z out = OVS_GetSelectedSweeps(graph, mode)
			if(!WaveExists(out) && mode == OVS_SWEEP_SELECTION_SWEEPNO)
				WAVE/Z out = OVS_GetSelectedSweeps(graph, OVS_SWEEP_ALL_SWEEPNO)
			endif
			if(!WaveExists(out))
				Make/N=1/FREE out = {NaN} // simulates [null]
			endif
			break
		case "listtoarray":
			/// `listtoarray(str list)` convert a semicolon spearated list to an array
			///
			/// returns array [items]
			ASSERT(DimSize(wv, ROWS)  == 1 , "Function requires 1 argument.")
			JSONtype = JSON_GetType(jsonID, jsonPath + "/0")
			if(JSONtype == JSON_STRING)
				ASSERT(JSON_GetArraySize(jsonID, jsonPath) == 1, "Use sweepLists like 1;2;3 as input.")
				WAVE/T wvT = ListToTextWave(JSON_GetString(jsonID, jsonPath + "/0"), ";")
				Make/FREE/N=(DimSize(wvT, ROWS)) out = str2num(wvT[p])
			else
				WAVE out = FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
			endif
			break
		case "data":
			/// `data(array range,array channels,array sweeps)`
			///
			/// returns [[sweeps][channel]] for all [sweeps] in list sweepNumbers, grouped by channels
			ASSERT(!ParamIsDefault(graph) && !!cmpstr(graph, ""), "Graph for extracting sweeps not specified.")

			WAVE range = FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
			ASSERT(DimSize(range, ROWS) == 2, "A range can not hold more than two points.")
			range = !IsNaN(range[p]) ? range[p] : (p == 0 ? -1 : 1) * inf

			WAVE channels = FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
			ASSERT(DimSize(channels, COLS) == 2, "A channel input consists of [[channelName, channelNumber]+].")

			WAVE sweeps = FormulaExecutor(jsonID, jsonPath = jsonPath + "/2", graph = graph)
			ASSERT(DimSize(sweeps, COLS) < 2, "Sweeps are one-dimensional.")

			WAVE/Z out = GetSweepForFormula(graph, range[0], range[1], channels[0][0], channels[0][1], sweeps)
			if(!WaveExists(out))
				DebugPrint("Call to GetSweepForFormula returned no results")
				Make/FREE/N=1 out = {NaN}
				break
			endif
			numIndices = DimSize(channels, ROWS)
			Redimension/N=(-1, -1, numIndices) out
			j = 1
			for(i = 1; i < numIndices; i += 1)
				WAVE wv = GetSweepForFormula(graph, range[0], range[1], channels[i][0], channels[i][1], sweeps)
				if(!WaveExists(wv))
					continue
				endif
				out[][][j] = wv[p][q]
				j += 1
				WaveClear wv
			endfor
			Redimension/N=(-1, -1, j) out
			break
		case "log": // JSON logic debug operation
			print wv[0]
			WAVE out = wv
			break
		case "log10": // decadic logarithm
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = log(wv)
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "cursors":
			Make/FREE/N=(DimSize(wvT, ROWS)) out = NaN
			for(i = 0; i < DimSize(wvT, ROWS); i += 1)
				ASSERT(GrepString(wvT[i], "^(?i)[A-J]$"), "Invalid Cursor Name")
				if(ParamIsDefault(graph))
					out[i] = xcsr($wvT[i])
				else
					if(!cmpstr(CsrInfo($wvT[i], graph), ""))
						continue
					endif
					out[i] = xcsr($wvT[i], graph)
				endif
			endfor
			break
		default:
			ASSERT(0, "Undefined Operation")
	endswitch
	/// @}

	return out
End

Function FormulaPlotter(graph, formula, [dfr])
	String graph
	String formula
	DFREF dfr

	String formula0, formula1, trace, axes
	Variable i, numTraces
	String win = "FormulaPlot"
	String traceName = "formula"

	if(ParamIsDefault(dfr))
		dfr = root:
	endif

	SplitString/E=SWEEPFORMULA_REGEXP formula, formula0, formula1
	ASSERT(V_Flag == 2 || V_flag == 1, "Display command must follow the \"y[ vs x]\" pattern.")
	if(V_Flag == 2)
		WAVE wv = FormulaExecutor(FormulaParser(FormulaPreParser(formula1)), graph = graph)
		ASSERT(WaveExists(wv), "Error in x part of formula.")
		Redimension/N=(-1, DimSize(wv, LAYERS) * DimSize(wv, COLS))/E=1 wv
		if(WaveType(wv, 1) == 2)
			Duplicate/O wv dfr:xFormulaT/WAVE = wvX
		else
			Duplicate/O wv dfr:xFormula/WAVE = wvX
		endif
		WaveClear wv
	endif
	WAVE wv = FormulaExecutor(FormulaParser(FormulaPreParser(formula0)), graph = graph)
	ASSERT(WaveExists(wv), "Error in y part of formula.")
	Redimension/N=(-1, max(1, DimSize(wv, LAYERS)) * DimSize(wv, COLS))/E=1 wv
	if(WaveType(wv, 1) == 2)
		Duplicate/O wv dfr:yFormulaT/WAVE = wvY
	else
		Duplicate/O wv dfr:yFormula/WAVE = wvY
	endif
	WaveClear wv

	if(!WindowExists(win))
		Display/N=$win as win
		win = S_name
	endif

	WAVE cursorInfos = GetCursorInfos(win)
	WAVE axesRanges = GetAxesRanges(win)
	RemoveTracesFromGraph(win)

	numTraces = WaveExists(wvY) ? max(DimSize(wvY, COLS), 1) : 0
	if(WaveExists(wvX) && numTraces == DimSize(wvX, COLS))
		DebugPrint("Size missmatch for plotting waves.")
	endif
	for(i = 0; i < numTraces; i += 1)
		trace = traceName + num2istr(i)
		if(WaveExists(wvX))
			AppendTograph/W=$win wvY[][i]/TN=$trace vs wvX[][i]
		else
			AppendTograph/W=$win wvY[][i]/TN=$trace
		endif
	endfor

	axes = AxisList(win)
	if(WhichListItem("bottomText", axes) != -1)
		ModifyGraph/W=$win freePos(bottomText)={0,kwFraction}
		ModifyGraph/W=$win mode=0
	endif

	RestoreCursors(win, cursorInfos)
	SetAxesRanges(win, axesRanges)
	DoWindow/F $win
End

Function/WAVE GetSweepForFormula(graph, rangeStart, rangeEnd, channelType, channelNumber, sweeps)
	String graph
	Variable rangeStart, rangeEnd
	Variable channelType, channelNumber
	WAVE sweeps

	Variable i, numSweeps
	Variable pStart, pEnd

	ASSERT(WindowExists(graph), "graph window does not exist")
	ASSERT(!IsNaN(rangeStart) && !IsNaN(rangeEnd), "Specified range not valid.")
	ASSERT(DimSize(sweeps, COLS) < 2, "Sweeps are one-dimensional.")

	if(IsFinite(channelType))
		WAVE/T/Z traces = PA_GetTraceInfos(graph, channelType = channelType)
	else
		WAVE/T/Z traces = PA_GetTraceInfos(graph)
	endif
	if(!WaveExists(traces) || DimSize(traces, ROWS) == 0)
		DebugPrint("No matching sweeps for channel type: " + StringFromList(channelType, ITC_CHANNEL_NAMES))
		return $""
	endif

	// we want the sweeps sorted with ascending sweep numbers
	SortColumns/A/DIML/KNDX={FindDimLabel(traces, COLS, "sweepNumber")} sortWaves=traces

	Make/N=(DimSize(traces, ROWS))/FREE sweepListIndex
	for(i = 0; i < DimSize(traces, ROWS); i += 1)
		FindValue/V=(trunc(str2num(traces[i][%sweepNumber])))/T=(0.1) sweeps
		sweepListIndex[i] = V_Value != -1
	endfor
	Make/N=(DimSize(traces, ROWS))/FREE channelNumberIndex = IsFinite(channelNumber) ? str2num(traces[p][%channelNumber]) == channelNumber : 1
	Extract/FREE/INDX sweepListIndex, indices, (sweepListIndex[p] == 1) && (channelNumberIndex[p] == 1)
	numSweeps = DimSize(indices, ROWS)
	if(numSweeps == 0)
		DebugPrint("No matching sweeps")
		return $""
	endif

	Make/FREE/T/N=(numSweeps) experiments
	experiments[] = traces[indices][%experiment]
	WAVE/Z uniqueExperiments = GetUniqueEntries(experiments)
	ASSERT(DimSize(uniqueExperiments, ROWS) == 1, "Sweep data is from more than one experiment. This is currently not supported.")

	WAVE reference = $(traces[indices[0]][%fullPath])
	ASSERT(DimSize(reference, COLS) <= 1, "Unhandled Sweep Format.")

	pStart = IsFinite(rangeStart) ? ScaleToIndex(reference, rangeStart, ROWS) : 0
	pEnd = IsFinite(rangeEnd) ? ScaleToIndex(reference, rangeEnd, ROWS) : DimSize(reference, ROWS) - 1
	ASSERT(pEnd < DimSize(reference, ROWS) && pStart >= 0, "Invalid sweep range.")
	Make/FREE/N=(abs(pStart - pEnd), numSweeps) sweepData
	SetScale/P x, IndexToScale(reference, pStart, ROWS), DimDelta(reference, ROWS), sweepData
	for(i = 0; i < numSweeps; i += 1)
		WAVE sweep = $(traces[indices[i]][%fullPath])
		pStart = IsFinite(rangeStart) ? ScaleToIndex(sweep, rangeStart, ROWS) : 0
		pEnd = IsFinite(rangeEnd) ? ScaleToIndex(sweep, rangeEnd, ROWS) : DimSize(reference, ROWS) - 1
		ASSERT(pEnd < DimSize(sweep, ROWS) && pStart >= 0, "Invalid sweep range.")
		ASSERt(abs(pStart - pEnd) == DimSize(sweepData, ROWS), "Sweeps not equal.")
		ASSERT(DimDelta(sweep, ROWS) == DimDelta(sweepData, ROWS), "Sweeps not equal.")
		sweepData[][i] = sweep[pStart + p]
	endfor

	return sweepData
End

Function button_sweepFormula_check(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String mainPanel, bsPanel, yFormula, xFormula
	Variable numFormulae, jsonIDx, jsonIDy

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			mainPanel = GetMainWindow(ba.win)
			bsPanel = BSP_GetPanel(mainPanel)
			DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_PANEL_FOLDER)

			SVAR/Z formula = dfr:sweepFormulaText
			ASSERT(SVAR_EXISTS(formula), "Global variable sweepFormulaText not found")
			Notebook $bsPanel#sweepFormula_formula getData=2
			formula = S_Value

			NVAR/Z status = dfr:sweepFormulaParse
			ASSERT(NVAR_EXISTS(status), "Global variable sweepFormulaParse not found")
			status = 0
			SVAR/Z result = dfr:sweepFormulaParseResult
			ASSERT(SVAR_EXISTS(result), "Global variable sweepFormulaParseResult not found. Can not evaluate parsing status.")
			result = ""

			NVAR/Z jsonID = dfr:sweepFormulaJSONid
			ASSERT(NVAR_EXISTS(jsonID), "Global variable sweepFormulaJSONid not found. Can not evaluate parsing status.")

			SplitString/E=SWEEPFORMULA_REGEXP formula, yFormula, xFormula
			numFormulae = V_flag
			if(numFormulae != 2 && numFormulae != 1)
				DebugPrint("Display command must follow the \"y[ vs x]\" pattern. Can not evaluate parsing status.")
				return 0
			endif

			try
				jsonIDy = FormulaParser(FormulaPreParser(yFormula))
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
				jsonIDx = FormulaParser(FormulaPreParser(xFormula))
				JSON_AddJSON(jsonID, "/x", jsonIDx)
				JSON_Release(jsonIDx)
			catch
				result = "Error Parsing Formula"
				status = 1
				JSON_Release(jsonID, ignoreErr = 1)
			endtry
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function button_sweepFormula_display(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String bsPanel, mainPanel, code

	switch( ba.eventCode )
		case 2: // mouse up
			bsPanel = BSP_GetPanel(ba.win)
			mainPanel = GetMainWindow(ba.win)

			Notebook $bsPanel#sweepFormula_formula getData=2
			code = S_Value
			if(IsEmpty(code))
				break
			endif

			FormulaPlotter(mainPanel, code, dfr = dfr)
			break
	endswitch

	return 0
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
Function FormulaWaveScaleTransfer(source, dest, dimSource, dimDest)
	WAVE source, dest
	Variable dimSource, dimDest

	if(cmpstr(WaveUnits(source, dimSource), "") && cmpstr(WaveUnits(dest, dimDest), ""))
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

Function SF_TabProc_Formula(tca) : TabControl
	STRUCT WMTabControlAction &tca

	String mainPanel, bsPanel

	ACL_DisplayTab(tca)

	switch( tca.eventCode )
		case 2: // mouse up
			mainPanel = GetMainWindow(tca.win)
			bsPanel = BSP_GetPanel(mainPanel)

			DFREF dfr = BSP_GetFolder(mainPanel, MIES_BSP_PANEL_FOLDER)

			Notebook $bsPanel#sweepFormula_formula visible=(tca.tab == 0)
			Notebook $bsPanel#sweepFormula_json visible=(tca.tab == 1)
			Notebook $bsPanel#sweepFormula_help visible=(tca.tab == 2)

			Notebook $bsPanel#sweepFormula_json selection={startOfFile, endOfFile},setData=""
			if(tca.tab == 1)
				PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_check")
			endif
			NVAR status = dfr:sweepFormulaParse
			if(status != 0) // error
				return 1
			endif

			if(tca.tab == 1) // JSON
				NVAR/Z jsonID = dfr:sweepFormulaJSONid
				Notebook $bsPanel#sweepFormula_json text=(ReplaceString("\n", JSON_Dump(jsonID, indent = 2), "\r"))
			endif
			break
		default:
			break
	endswitch

	return 0
End
