#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_SF
#endif // AUTOMATED_TESTING

// to enable debug mode with more persistent data
// #define SWEEPFORMULA_DEBUG

/// @file MIES_SweepFormula.ipf
///
/// @brief __SF__ Sweep formula allows to do analysis on sweeps with a
/// dedicated formula language

/// Regular expression which extracts both formulas from `$a vs $b`
static StrConstant SF_SWEEPFORMULA_REGEXP = "^(.+?)(?:\\bvs\\b(.+))?$"
/// Regular expression which extracts formulas pairs from `$a vs $b\rand\r$c vs $d\rand\r...`
static StrConstant SF_SWEEPFORMULA_GRAPHS_REGEXP = "^(.+?)(?:\\r[ \t]*and[ \t]*\\r(.*))?$"
/// Regular expression which extracts y-formulas from `$a\rwith\r$b\rwith\r$c\r...`
static StrConstant SF_SWEEPFORMULA_WITH_REGEXP = "^(.+?)(?:\\r[ \t]*with[ \t]*\\r(.*))?$"

static Constant SF_MAX_NUMPOINTS_FOR_MARKERS = 1000

static Constant SF_APFREQUENCY_FULL               = 0x0
static Constant SF_APFREQUENCY_INSTANTANEOUS      = 0x1
static Constant SF_APFREQUENCY_APCOUNT            = 0x2
static Constant SF_APFREQUENCY_INSTANTANEOUS_PAIR = 0x3

static StrConstant SF_OP_MINUS               = "-"
static StrConstant SF_OP_PLUS                = "+"
static StrConstant SF_OP_MULT                = "*"
static StrConstant SF_OP_DIV                 = "~1"
static StrConstant SF_OP_RANGE               = "range"
static StrConstant SF_OP_CONCAT              = "concat"
static StrConstant SF_OP_RANGESHORT          = "…"
static StrConstant SF_OP_MIN                 = "min"
static StrConstant SF_OP_MAX                 = "max"
static StrConstant SF_OP_AVG                 = "avg"
static StrConstant SF_OP_MEAN                = "mean"
static StrConstant SF_OP_RMS                 = "rms"
static StrConstant SF_OP_VARIANCE            = "variance"
static StrConstant SF_OP_STDEV               = "stdev"
static StrConstant SF_OP_DERIVATIVE          = "derivative"
static StrConstant SF_OP_INTEGRATE           = "integrate"
static StrConstant SF_OP_TIME                = "time"
static StrConstant SF_OP_XVALUES             = "xvalues"
static StrConstant SF_OP_TEXT                = "text"
static StrConstant SF_OP_LOG                 = "log"
static StrConstant SF_OP_LOG10               = "log10"
static StrConstant SF_OP_APFREQUENCY         = "apfrequency"
static StrConstant SF_OP_CURSORS             = "cursors"
static StrConstant SF_OP_SELECTSWEEPS        = "selsweeps"
static StrConstant SF_OP_AREA                = "area"
static StrConstant SF_OP_SETSCALE            = "setscale"
static StrConstant SF_OP_BUTTERWORTH         = "butterworth"
static StrConstant SF_OP_SELECTCHANNELS      = "selchannels"
static StrConstant SF_OP_DATA                = "data"
static StrConstant SF_OP_LABNOTEBOOK         = "labnotebook"
static StrConstant SF_OP_ANAFUNCPARAM        = "anaFuncParam"
static StrConstant SF_OP_WAVE                = "wave"
static StrConstant SF_OP_FINDLEVEL           = "findlevel"
static StrConstant SF_OP_EPOCHS              = "epochs"
static StrConstant SF_OP_TP                  = "tp"
static StrConstant SF_OP_STORE               = "store"
static StrConstant SF_OP_SELECT              = "select"
static StrConstant SF_OP_SELECTVIS           = "selvis"
static StrConstant SF_OP_SELECTEXP           = "selexp"
static StrConstant SF_OP_SELECTDEV           = "seldev"
static StrConstant SF_OP_SELECTEXPANDSCI     = "selexpandsci"
static StrConstant SF_OP_SELECTEXPANDRAC     = "selexpandrac"
static StrConstant SF_OP_SELECTSETCYCLECOUNT = "selsetcyclecount"
static StrConstant SF_OP_SELECTSETSWEEPCOUNT = "selsetsweepcount"
static StrConstant SF_OP_SELECTSCIINDEX      = "selsciindex"
static StrConstant SF_OP_SELECTRACINDEX      = "selracindex"
static StrConstant SF_OP_SELECTCM            = "selcm"
static StrConstant SF_OP_SELECTSTIMSET       = "selstimset"
static StrConstant SF_OP_SELECTIVSCCSWEEPQC  = "selivsccsweepqc"
static StrConstant SF_OP_SELECTIVSCCSETQC    = "selivsccsetqc"
static StrConstant SF_OP_SELECTRANGE         = "selrange"
static StrConstant SF_OP_POWERSPECTRUM       = "powerspectrum"
static StrConstant SF_OP_TPSS                = "tpss"
static StrConstant SF_OP_TPINST              = "tpinst"
static StrConstant SF_OP_TPBASE              = "tpbase"
static StrConstant SF_OP_TPFIT               = "tpfit"

static StrConstant SF_OPSHORT_MINUS = "minus"
static StrConstant SF_OPSHORT_PLUS  = "plus"
static StrConstant SF_OPSHORT_MULT  = "mult"
static StrConstant SF_OPSHORT_DIV   = "div"

static StrConstant SF_OP_EPOCHS_TYPE_RANGE     = "range"
static StrConstant SF_OP_EPOCHS_TYPE_NAME      = "name"
static StrConstant SF_OP_EPOCHS_TYPE_TREELEVEL = "treelevel"
static StrConstant SF_OP_TP_TYPE_BASELINE      = "base"
static StrConstant SF_OP_TP_TYPE_INSTANT       = "inst"
static StrConstant SF_OP_TP_TYPE_STATIC        = "ss"

static StrConstant SF_OP_SELECTVIS_ALL       = "all"
static StrConstant SF_OP_SELECTVIS_DISPLAYED = "displayed"

/// @name Constants for SweepFormula Clampmode user argument strings used in selcm()
/// @anchor SFClampModeStrings
/// @{
static StrConstant SF_OP_SELECTCM_CLAMPMODE_ALL   = "all"
static StrConstant SF_OP_SELECTCM_CLAMPMODE_NONE  = "none"
static StrConstant SF_OP_SELECTCM_CLAMPMODE_IC    = "ic"
static StrConstant SF_OP_SELECTCM_CLAMPMODE_VC    = "vc"
static StrConstant SF_OP_SELECTCM_CLAMPMODE_IZERO = "izero"
/// @}

static StrConstant SF_OP_SELECT_IVSCCQC_PASSED = "passed"
static StrConstant SF_OP_SELECT_IVSCCQC_FAILED = "failed"

static StrConstant SF_OP_TPFIT_FUNC_EXP       = "exp"
static StrConstant SF_OP_TPFIT_FUNC_DEXP      = "doubleexp"
static StrConstant SF_OP_TPFIT_RET_TAULARGE   = "tau"
static StrConstant SF_OP_TPFIT_RET_TAUSMALL   = "tausmall"
static StrConstant SF_OP_TPFIT_RET_AMP        = "amp"
static StrConstant SF_OP_TPFIT_RET_MINAMP     = "minabsamp"
static StrConstant SF_OP_TPFIT_RET_FITQUALITY = "fitq"

static StrConstant SF_OP_APFREQUENCY_Y_TIME             = "time"
static StrConstant SF_OP_APFREQUENCY_Y_FREQ             = "freq"
static StrConstant SF_OP_APFREQUENCY_NORMOVERSWEEPSMIN  = "normoversweepsmin"
static StrConstant SF_OP_APFREQUENCY_NORMOVERSWEEPSMAX  = "normoversweepsmax"
static StrConstant SF_OP_APFREQUENCY_NORMOVERSWEEPSAVG  = "normoversweepsavg"
static StrConstant SF_OP_APFREQUENCY_NORMWITHINSWEEPMIN = "norminsweepsmin"
static StrConstant SF_OP_APFREQUENCY_NORMWITHINSWEEPMAX = "norminsweepsmax"
static StrConstant SF_OP_APFREQUENCY_NORMWITHINSWEEPAVG = "norminsweepsavg"
static StrConstant SF_OP_APFREQUENCY_NONORM             = "nonorm"
static StrConstant SF_OP_APFREQUENCY_X_COUNT            = "count"
static StrConstant SF_OP_APFREQUENCY_X_TIME             = "time"

static StrConstant SF_OP_AVG_INSWEEPS   = "in"
static StrConstant SF_OP_AVG_OVERSWEEPS = "over"

static StrConstant SF_OP_SELECT_STIMSETS_ALL = "*"

static Constant EPOCHS_TYPE_INVALID   = -1
static Constant EPOCHS_TYPE_RANGE     = 0
static Constant EPOCHS_TYPE_NAME      = 1
static Constant EPOCHS_TYPE_TREELEVEL = 2

static StrConstant SF_CHAR_COMMENT = "#"
static StrConstant SF_CHAR_CR      = "\r"
static StrConstant SF_CHAR_NEWLINE = "\n"

static Constant SF_TRANSFER_ALL_DIMS = -1

static StrConstant SF_PLOTTER_GUIDENAME = "HOR"

static StrConstant SF_XLABEL_USER = ""

static Constant SF_NUMTRACES_ERROR_THRESHOLD = 10000
static Constant SF_NUMTRACES_WARN_THRESHOLD  = 1000

static StrConstant SF_AVERAGING_NONSWEEPDATA_LBL = "NOSWEEPDATA"

static StrConstant SF_POWERSPECTRUM_UNIT_DEFAULT           = "default"
static StrConstant SF_POWERSPECTRUM_UNIT_DB                = "db"
static StrConstant SF_POWERSPECTRUM_UNIT_NORMALIZED        = "normalized"
static StrConstant SF_POWERSPECTRUM_AVG_ON                 = "avg"
static StrConstant SF_POWERSPECTRUM_AVG_OFF                = "noavg"
static StrConstant SF_POWERSPECTRUM_WINFUNC_NONE           = "none"
static Constant    SF_POWERSPECTRUM_RATIO_DELTAHZ          = 10
static Constant    SF_POWERSPECTRUM_RATIO_EPSILONHZ        = 0.25
static Constant    SF_POWERSPECTRUM_RATIO_EPSILONPOSFIT    = 1E-3
static Constant    SF_POWERSPECTRUM_RATIO_MAXFWHM          = 5
static Constant    SF_POWERSPECTRUM_RATIO_GAUSS_SIGMA2FWHM = 2.35482004503
static Constant    SF_POWERSPECTRUM_RATIO_GAUSS_NUMCOEFS   = 4

static Constant SF_VARIABLE_PREFIX = 36

static StrConstant SF_GETSETINTERSECTIONSELECT_FORMAT = "%d_%d_%d_%f"

static Constant SELECTDATA_MODE_SCI = 1
static Constant SELECTDATA_MODE_RAC = 2

static Constant SWEEPPROP_CLAMPMODE     = 0
static Constant SWEEPPROP_SETCYCLECOUNT = 1
static Constant SWEEPPROP_SETSWEEPCOUNT = 2
static Constant SWEEPPROP_END           = 3

static StrConstant DB_EXPNAME_DUMMY = "|DataBrowserExperiment|"

static Constant SF_SWEEPFORMULA_AXIS_X = 0
static Constant SF_SWEEPFORMULA_AXIS_Y = 1

Menu "GraphPopup"
	"Bring browser to front", /Q, SF_BringBrowserToFront()
End

Function SF_BringBrowserToFront()

	string browser, graph

	graph   = GetMainWindow(GetCurrentWindow())
	browser = SFH_GetBrowserForFormulaGraph(graph)

	if(IsEmpty(browser))
		print "This menu option only applies to SweepFormula plots."
		return NaN
	elseif(!WindowExists(browser))
		printf "The browser %s does not exist anymore.\r", browser
		return NaN
	endif

	DoWindow/F $browser
End

Function/WAVE SF_GetNamedOperations()

	Make/FREE/T wt = {SF_OP_RANGE, SF_OP_MIN, SF_OP_MAX, SF_OP_AVG, SF_OP_MEAN, SF_OP_RMS, SF_OP_VARIANCE, SF_OP_STDEV,                 \
	                  SF_OP_DERIVATIVE, SF_OP_INTEGRATE, SF_OP_TIME, SF_OP_XVALUES, SF_OP_TEXT, SF_OP_LOG,                              \
	                  SF_OP_LOG10, SF_OP_APFREQUENCY, SF_OP_CURSORS, SF_OP_SELECTSWEEPS, SF_OP_AREA, SF_OP_SETSCALE, SF_OP_BUTTERWORTH, \
	                  SF_OP_SELECTCHANNELS, SF_OP_DATA, SF_OP_LABNOTEBOOK, SF_OP_WAVE, SF_OP_FINDLEVEL, SF_OP_EPOCHS, SF_OP_TP,         \
	                  SF_OP_STORE, SF_OP_SELECT, SF_OP_POWERSPECTRUM, SF_OP_TPSS, SF_OP_TPBASE, SF_OP_TPINST, SF_OP_TPFIT,              \
	                  SF_OP_PSX, SF_OP_PSX_KERNEL, SF_OP_PSX_STATS, SF_OP_PSX_RISETIME, SF_OP_PSX_PREP, SF_OP_PSX_DECONV_FILTER,        \
	                  SF_OP_MERGE, SF_OP_FIT, SF_OP_FITLINE, SF_OP_DATASET, SF_OP_SELECTVIS, SF_OP_SELECTCM, SF_OP_SELECTSTIMSET,       \
	                  SF_OP_SELECTIVSCCSWEEPQC, SF_OP_SELECTIVSCCSETQC, SF_OP_SELECTRANGE, SF_OP_SELECTEXP, SF_OP_SELECTDEV,            \
	                  SF_OP_SELECTEXPANDSCI, SF_OP_SELECTEXPANDRAC, SF_OP_SELECTSETCYCLECOUNT, SF_OP_SELECTSETSWEEPCOUNT,               \
	                  SF_OP_SELECTSCIINDEX, SF_OP_SELECTRACINDEX, SF_OP_ANAFUNCPARAM, SF_OP_CONCAT}

	return wt
End

Function/WAVE SF_GetFormulaKeywords()

	// see also SF_SWEEPFORMULA_REGEXP and SF_SWEEPFORMULA_GRAPHS_REGEXP
	Make/FREE/T wt = {"vs", "and", "with"}

	return wt
End

/// @brief add escape characters to a path element
Function/S SF_EscapeJsonPath(string str)

	return ReplaceString("/", str, "~1")
End

static Function SF_PlaceSubArrayAt(WAVE/Z out, WAVE/Z subArray, variable index)

	if(!WaveExists(out))
		return NaN
	endif

	SF_FormulaWaveScaleTransfer(subArray, out, ROWS, COLS)
	SF_FormulaWaveScaleTransfer(subArray, out, COLS, LAYERS)
	SF_FormulaWaveScaleTransfer(subArray, out, LAYERS, CHUNKS)
	// Copy max 3d subarray to data
	if(IsTextWave(out))
		WAVE/T outT      = out
		WAVE/T subArrayT = subArray
		Multithread outT[index][0, max(0, DimSize(subArray, ROWS) - 1)][0, max(0, DimSize(subArray, COLS) - 1)][0, max(0, DimSize(subArray, LAYERS) - 1)] = subArrayT[q][r][s]
	else
		Multithread out[index][0, max(0, DimSize(subArray, ROWS) - 1)][0, max(0, DimSize(subArray, COLS) - 1)][0, max(0, DimSize(subArray, LAYERS) - 1)] = subArray[q][r][s]
	endif
End

static Function/WAVE SF_FormulaExecutorStringOrVariable(string graph, variable jsonId, string jsonPath)

	string   str
	variable dim

	str = JSON_GetString(jsonID, jsonPath)
	if(strlen(str) > 1 && char2num(str[0]) == SF_VARIABLE_PREFIX)
		WAVE/WAVE varStorage = GetSFVarStorage(graph)
		dim = FindDimLabel(varStorage, ROWS, str[1, Inf])
		SFH_ASSERT(dim != -2, "Unknown variable " + str[1, Inf])
		return varStorage[dim]
	endif

	Make/FREE/T outT = {str}
	return SFH_GetOutputForExecutorSingle(outT, graph, "ExecutorStringReturn")
End

/// @brief Execute the formula parsed by SF_FormulaParser
///
/// Recursively executes the formula parsed into jsonID.
///
/// @param graph    graph to read from, mainly used by the `data` operation
/// @param jsonID   JSON object ID from the JSON XOP
/// @param jsonPath JSON pointer compliant path
static Function/WAVE SF_FormulaExecutor(string graph, variable jsonID, [string jsonPath])

	string opName, str
	variable i, size, JSONType, arrayElemJSONType, effectiveArrayDimCount, dim
	variable colSize, layerSize, chunkSize, operationsWithScalarResultCount

	if(ParamIsDefault(jsonPath))
		jsonPath = ""
	endif

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		printf "##########################\r"
		printf "%s\r", JSON_Dump(jsonID, indent = 2)
		printf "##########################\r"
	endif
#endif // DEBUGGING_ENABLED

	// object and array evaluation
	JSONtype = JSON_GetType(jsonID, jsonPath)
	if(JSONtype == JSON_NUMERIC)
		Make/FREE/D out = {JSON_GetVariable(jsonID, jsonPath)}
		return SFH_GetOutputForExecutorSingle(out, graph, "ExecutorNumberReturn")
	elseif(JSONtype == JSON_STRING)
		return SF_FormulaExecutorStringOrVariable(graph, jsonId, jsonPath)
	elseif(JSONtype == JSON_ARRAY)
		// Evaluate an array consisting of any elements including subarrays and objects (operations)

		// If we want to return an Igor Pro data wave the final dimensionality can not exceed 4
		WAVE topArraySize = JSON_GetMaxArraySize(jsonID, jsonPath)
		effectiveArrayDimCount = DimSize(topArraySize, ROWS)
		SFH_ASSERT(effectiveArrayDimCount <= MAX_DIMENSION_COUNT, "Array in evaluation has more than " + num2istr(MAX_DIMENSION_COUNT) + "dimensions.", jsonId = jsonId)
		// Check against empty array
		if(DimSize(topArraySize, ROWS) == 1 && topArraySize[0] == 0)
			Make/FREE/D/N=0 out
			return SFH_GetOutputForExecutorSingle(out, graph, "ExecutorNumberReturn")
		endif

		// Get all types of current level (row)
		Make/FREE/N=(topArraySize[0]) types = JSON_GetType(jsonID, jsonPath + "/" + num2istr(p))
		// Do not allow null, that can happen if a formula like "integrate()" is executed and SF_GetArgumentTop attempts to parse all arguments into one array
		FindValue/V=(JSON_NULL) types
		SFH_ASSERT(!(V_Value >= 0), "Encountered null element in array.", jsonId = jsonId)

		Redimension/N=(MAX_DIMENSION_COUNT) topArraySize
		topArraySize[] = (topArraySize[p] != 0) ? topArraySize[p] : 1

		Make/FREE/D/N=0 indicesOfOperationsWithScalarResult
		WAVE/ZZ   out
		WAVE/ZZ/T outT

		// Get indices of Objects, Arrays and Strings on current level
		EXTRACT/FREE/INDX types, arrElemAt, (types[p] == JSON_OBJECT) || (types[p] == JSON_ARRAY) || (types[p] == JSON_STRING) || (types[p] == JSON_NUMERIC)
		// Iterate over all subarrays and objects on current level
		for(index : arrElemAt)
			WAVE/WAVE genericElement = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, index)
			if(DimSize(genericElement, ROWS) == 1)
				// single dataset
				WAVE/Z subArray = genericElement[0]
				SFH_ASSERT(WaveExists(subArray), "no data in array element")
				if(IsTextWave(subArray))
					WAVE/Z numericalAttempt = SF_ConvertNonFiniteElements(subArray)
					if(WaveExists(numericalAttempt))
						WAVE subArray = numericalAttempt
						[out, outT] = SF_ExecutorCreateOrCheckNumeric(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
					else
						[out, outT] = SF_ExecutorCreateOrCheckTextual(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
					endif
				elseif(IsNumericWave(subArray))
					[out, outT] = SF_ExecutorCreateOrCheckNumeric(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
				else
					[out, outT] = SF_ExecutorCreateOrCheckTextual(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
					WAVE subArrayWrapped = SFH_GetOutputForExecutor(subArray, graph, "WrappedArrayElement")
					WAVE subArray        = subArrayWrapped
				endif
			else
				// multi dataset
				[out, outT] = SF_ExecutorCreateOrCheckTextual(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
				WAVE subArray = SFH_GetOutputForExecutor(genericElement, graph, "WrappedArrayElement")
			endif

			SFH_ASSERT(numpnts(subArray), "Encountered subArray with zero size.")
			SFH_ASSERT(WaveDims(subArray) < MAX_DIMENSION_COUNT, "Encountered 4d sub array at " + jsonPath)

			// Promote WaveNote with meta data if topArray is 1 point.
			// The single topArray element is object or array at this point
			if(WaveExists(out) && numpnts(out) == 1)
				Note/K out, note(subArray)
			endif
			if(WaveExists(outT) && numpnts(outT) == 1)
				Note/K outT, note(subArray)
			endif

			// do expand array dimensionality if
			// - original source was a array
			// - original source was not: a string that resolved to a scalar datum (the source string can refer to a variable that was resolved)
			// - original source was not: a object (aka operation) that resolved to a scalar datum
			if(types[index] == JSON_ARRAY || !((types[index] == JSON_STRING || types[index] == JSON_OBJECT || types[index] == JSON_NUMERIC) && WaveDims(subArray) == 1 && numpnts(subArray) == 1))
				// subArray will be inserted into the current array, thus the dimension will be WaveDims(subArray) + 1
				// Thus, [1, [2]] returns the correct wave of size (2, 1) with {{1, 2}}.
				effectiveArrayDimCount = max(effectiveArrayDimCount, WaveDims(subArray) + 1)
			endif

			// If the whole JSON array consists of STRING or NUMERIC types then topArraySize already is of the correct size.
			// If we encounter an Object aka operation it could return an array that is larger than a single element,
			// then we might have to resize beyond the original topArraySize.
			// Increase 4D array size tracking according to new data
			topArraySize[1, *] = max(topArraySize[p], DimSize(subArray, p - 1))
			WAVE outCombinedType = SelectWave(WaveExists(outT), out, outT)
			// resize data according to new topArraySize adapted by sub array size and fill new elements with NaN
			if((DimSize(outCombinedType, COLS) < topArraySize[1]) ||   \
			   (DimSize(outCombinedType, LAYERS) < topArraySize[2]) || \
			   (DimSize(outCombinedType, CHUNKS) < topArraySize[3]))

				if(WaveExists(out))
					Duplicate/FREE out, outTmp
					Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3]) outTmp
					FastOp outTmp = (NaN)
					Multithread outTmp[0, DimSize(out, ROWS) - 1][0, DimSize(out, COLS) - 1][0, DimSize(out, LAYERS) - 1][0, DimSize(out, CHUNKS) - 1] = out[p][q][r][s]
					WAVE out = outTmp
				endif
				if(WaveExists(outT))
					Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3]) outT
				endif
			endif
			if(WaveExists(out))
				SF_PlaceSubArrayAt(out, subArray, index)
			else
				SF_PlaceSubArrayAt(outT, subArray, index)
			endif

			// Save indices of operation/subArray evaluations that returned scalar results
			if(numpnts(subArray) == 1)
				EnsureLargeEnoughWave(indicesOfOperationsWithScalarResult, indexShouldExist = operationsWithScalarResultCount)
				indicesOfOperationsWithScalarResult[operationsWithScalarResultCount] = index
				operationsWithScalarResultCount                                     += 1
			endif
		endfor
		Redimension/N=(operationsWithScalarResultCount) indicesOfOperationsWithScalarResult

		// SCALAR EXTENSION
		// Find all indices that are not subArray or objects but either string or numeric, depending on final type determined above
		// As the first element is string or numeric, the array element itself is a skalar.
		// We also consider operations/subArrays that returned a scalar result that we gathered above.
		// The non-skalar case:
		// If from object elements (operations) the topArraySize is increased and as example one operations returns a 3x3 array
		// and another operation a 2x2 array, then for the first operation the topArraySize increase happens, the data from the
		// second operation is just filled in the array with remaining "untouched" elements in that row. These elements stay with the fill
		// value NaN or "".
		arrayElemJSONType = WaveExists(outT) ? JSON_STRING : JSON_NUMERIC
		EXTRACT/FREE/INDX types, indices, types[p] == arrayElemJSONType
		Concatenate/FREE/NP {indicesOfOperationsWithScalarResult}, indices
		if(WaveExists(outT))
			for(index : indices)
				Multithread outT[index][][][] = outT[index][0][0][0]
			endfor
		else
			for(index : indices)
				Multithread out[index][][][] = out[index][0][0][0]
			endfor
		endif

		// out can be text or numeric, afterwards if following code has no type expectations
		if(WaveExists(outT))
			WAVE out = outT
		endif
		// shrink data to actual array size
		for(dim = effectiveArrayDimCount; dim < MAX_DIMENSION_COUNT; dim += 1)
			ASSERT(topArraySize[dim] == 1, "Inconsistent array dimension size")
			topArraySize[dim] = 0
		endfor
		Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])/E=1 out
		return SFH_GetOutputForExecutorSingle(out, graph, "ExecutorArrayReturn")
	endif

	// operation evaluation
	SFH_ASSERT(JSONtype == JSON_OBJECT, "Topmost element needs to be an object", jsonId = jsonId)
	WAVE/T operations = JSON_GetKeys(jsonID, jsonPath)
	SFH_ASSERT(DimSize(operations, ROWS) == 1, "Only one operation is allowed", jsonId = jsonId)
	jsonPath += "/" + SF_EscapeJsonPath(operations[0])
	SFH_ASSERT(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY, "An array is required to hold the operands of the operation.", jsonId = jsonId)

	opName = LowerStr(operations[0])
#ifdef AUTOMATED_TESTING
	strswitch(opName)
		case SF_OP_MINUS: // fallthrough
		case SF_OP_PLUS: // fallthrough
		case SF_OP_DIV: // fallthrough
		case SF_OP_MULT: // fallthrough
		case SF_OP_RANGESHORT:
			break
		default:
			WAVE ops = SF_GetNamedOperations()
			ASSERT(GetRowIndex(ops, str = opName) >= 0, "List of operations with long name is out of date as the following is missing: " + opName)
			break
	endswitch
#endif // AUTOMATED_TESTING

	/// @name SweepFormulaOperations
	///@{
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
		case SF_OP_RANGE: // fallthrough
		case SF_OP_RANGESHORT:
			WAVE out = SF_OperationRange(jsonId, jsonPath, graph)
			break
		case SF_OP_CONCAT:
			WAVE out = SF_OperationConcat(jsonId, jsonPath, graph)
			break
		case SF_OP_MIN:
			WAVE out = SF_OperationMin(jsonId, jsonPath, graph)
			break
		case SF_OP_MAX:
			WAVE out = SF_OperationMax(jsonId, jsonPath, graph)
			break
		case SF_OP_AVG: // fallthrough
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
		case SF_OP_TIME: // fallthrough
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
		case SF_OP_SELECTCHANNELS:
			WAVE out = SF_OperationSelectChannels(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSWEEPS:
			WAVE out = SF_OperationSelectSweeps(jsonId, jsonPath, graph)
			break
		case SF_OP_DATA:
			WAVE out = SF_OperationData(jsonId, jsonPath, graph)
			break
		case SF_OP_LABNOTEBOOK:
			WAVE out = SF_OperationLabnotebook(jsonId, jsonPath, graph)
			break
		case SF_OP_ANAFUNCPARAM:
			WAVE out = SF_OperationAnaFuncParam(jsonId, jsonPath, graph)
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
		case SF_OP_POWERSPECTRUM:
			WAVE out = SF_OperationPowerSpectrum(jsonId, jsonPath, graph)
			break
		case SF_OP_TPSS:
			WAVE out = SF_OperationTPSS(jsonId, jsonPath, graph)
			break
		case SF_OP_TPINST:
			WAVE out = SF_OperationTPInst(jsonId, jsonPath, graph)
			break
		case SF_OP_TPBASE:
			WAVE out = SF_OperationTPBase(jsonId, jsonPath, graph)
			break
		case SF_OP_TPFIT:
			WAVE out = SF_OperationTPFit(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX:
			WAVE out = PSX_Operation(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_KERNEL:
			WAVE out = PSX_OperationKernel(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_STATS:
			WAVE out = PSX_OperationStats(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_RISETIME:
			WAVE out = PSX_OperationRiseTime(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_PREP:
			WAVE out = PSX_OperationPrep(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_DECONV_FILTER:
			WAVE out = PSX_OperationDeconvFilter(jsonId, jsonPath, graph)
			break
		case SF_OP_MERGE:
			WAVE out = SF_OperationMerge(jsonId, jsonPath, graph)
			break
		case SF_OP_FIT:
			WAVE out = SF_OperationFit(jsonId, jsonPath, graph)
			break
		case SF_OP_FITLINE:
			WAVE out = SF_OperationFitLine(jsonId, jsonPath, graph)
			break
		case SF_OP_DATASET:
			WAVE out = SF_OperationDataset(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTVIS:
			WAVE out = SF_OperationSelectVis(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTEXP:
			WAVE out = SF_OperationSelectExperiment(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTDEV:
			WAVE out = SF_OperationSelectDevice(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTEXPANDSCI:
			WAVE out = SF_OperationSelectExpandSCI(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTEXPANDRAC:
			WAVE out = SF_OperationSelectExpandRAC(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSETCYCLECOUNT:
			WAVE out = SF_OperationSelectSetCycleCount(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSETSWEEPCOUNT:
			WAVE out = SF_OperationSelectSetSweepCount(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSCIINDEX:
			WAVE out = SF_OperationSelectSCIIndex(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTRACINDEX:
			WAVE out = SF_OperationSelectRACIndex(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTCM:
			WAVE out = SF_OperationSelectCM(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSTIMSET:
			WAVE out = SF_OperationSelectStimset(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTIVSCCSWEEPQC:
			WAVE out = SF_OperationSelectIVSCCSweepQC(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTIVSCCSETQC:
			WAVE out = SF_OperationSelectIVSCCSetQC(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTRANGE:
			WAVE out = SF_OperationSelectRange(jsonId, jsonPath, graph)
			break
		default:
			SFH_FATAL_ERROR("Undefined Operation", jsonId = jsonId)
	endswitch
	///@}

	return out
End

static Function [WAVE/WAVE formulaResults, STRUCT SF_PlotMetaData plotMetaData] SF_GatherFormulaResults(string xFormula, string yFormula, string graph)

	variable i, numResultsY, numResultsX
	variable useXLabel, addDataUnitsInAnnotation
	string dataUnits, dataUnitCheck

	WAVE/WAVE formulaResults = GetFormulaGatherWave()

	WAVE/Z/WAVE wvXRef = $""
	if(!IsEmpty(xFormula))
		WAVE/WAVE wvXRef = SF_ExecuteFormula(xFormula, graph, useVariables = 0)
		SFH_ASSERT(WaveExists(wvXRef), "x part of formula returned no result.")
	endif
	WAVE/WAVE wvYRef = SF_ExecuteFormula(yFormula, graph, useVariables = 0)
	SFH_ASSERT(WaveExists(wvYRef), "y part of formula returned no result.")
	numResultsY = DimSize(wvYRef, ROWS)
	if(WaveExists(wvXRef))
		numResultsX = DimSize(wvXRef, ROWS)
		SFH_ASSERT(numResultsX == numResultsY || numResultsX == 1, "X-Formula data not fitting to Y-Formula.")
	endif

	useXLabel                = 1
	addDataUnitsInAnnotation = 1
	Redimension/N=(numResultsY, -1) formulaResults

	if(DimSize(wvYRef, ROWS) > 0 && DimSize(formulaResults, ROWS) > 0)
		CopyDimLabels/ROWS=(ROWS) wvYRef, formulaResults
	endif

	Note/K formulaResults, note(wvYRef)

	for(i = 0; i < numResultsY; i += 1)
		WAVE/Z wvYdata = wvYRef[i]
		if(WaveExists(wvYdata))
			if(WaveExists(wvXRef))
				if(numResultsX == 1)
					WAVE/Z wvXdata = wvXRef[0]
					if(WaveExists(wvXdata) && DimSize(wvXdata, ROWS) == numResultsY && numpnts(wvYdata) == 1 && numpnts(wvXdata) != 1)
						Duplicate/FREE/T/RMD=[i] wvXdata, wvXnewData
						formulaResults[i][%FORMULAX] = wvXnewData
					else
						formulaResults[i][%FORMULAX] = wvXRef[0]
					endif
				else
					formulaResults[i][%FORMULAX] = wvXRef[i]
				endif

				WAVE/Z wvXdata = formulaResults[i][%FORMULAX]
				if(WaveExists(wvXdata))
					useXLabel = 0
				endif
			endif

			dataUnits = WaveUnits(wvYdata, -1)
			if(IsNull(dataUnitCheck))
				dataUnitCheck = dataUnits
			elseif(CmpStr(dataUnitCheck, dataUnits))
				addDataUnitsInAnnotation = 0
			endif

			formulaResults[i][%FORMULAY] = wvYdata
		endif
	endfor

	dataUnits = ""
	if(!IsNull(dataUnitCheck))
		dataUnits = SelectString(addDataUnitsInAnnotation && !IsEmpty(dataUnitCheck), "", SF_FormatUnit(dataUnitCheck))
	endif

	plotMetaData.dataType      = JWN_GetStringFromWaveNote(wvYRef, SF_META_DATATYPE)
	plotMetaData.opStack       = JWN_GetStringFromWaveNote(wvYRef, SF_META_OPSTACK)
	plotMetaData.argSetupStack = JWN_GetStringFromWaveNote(wvYRef, SF_META_ARGSETUPSTACK)
	plotMetaData.xAxisLabel    = SelectString(useXLabel, SF_XLABEL_USER, JWN_GetStringFromWaveNote(wvYRef, SF_META_XAXISLABEL))
	plotMetaData.yAxisLabel    = JWN_GetStringFromWaveNote(wvYRef, SF_META_YAXISLABEL) + dataUnits

	return [formulaResults, plotMetaData]
End

static Function/S SF_FormatUnit(string unit)

	return "(" + unit + ")"
End

static Function/S SF_GetAnnotationPrefix(string dataType)

	strswitch(dataType)
		case SF_DATATYPE_EPOCHS:
			return "Epoch "
		case SF_DATATYPE_SWEEP:
			return ""
		case SF_DATATYPE_TP:
			return "TP "
		case SF_DATATYPE_LABNOTEBOOK:
			return "LB "
		case SF_DATATYPE_ANAFUNCPARAM:
			return "AFP "
		default:
			FATAL_ERROR("Invalid dataType")
	endswitch
End

static Function/S SF_GetTraceAnnotationText(STRUCT SF_PlotMetaData &plotMetaData, WAVE data)

	variable channelNumber, channelType, sweepNo, isAveraged
	string channelId, prefix, legendPrefix
	string traceAnnotation, annotationPrefix

	prefix = RemoveEnding(ReplaceString(";", plotMetaData.opStack, " "), " ")

	strswitch(plotMetaData.dataType)
		case SF_DATATYPE_EPOCHS: // fallthrough
		case SF_DATATYPE_SWEEP: // fallthrough
		case SF_DATATYPE_LABNOTEBOOK: // fallthrough
		case SF_DATATYPE_ANAFUNCPARAM: // fallthrough
		case SF_DATATYPE_TP:
			sweepNo      = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPNO)
			legendPrefix = JWN_GetStringFromWaveNote(data, SF_META_LEGEND_LINE_PREFIX)

			if(!IsEmpty(legendPrefix))
				legendPrefix = " " + legendPrefix + " "
			endif

			sprintf annotationPrefix, "%s%s", SF_GetAnnotationPrefix(plotMetaData.dataType), legendPrefix

			if(IsValidSweepNumber(sweepNo))
				channelNumber = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELNUMBER)
				channelType   = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELTYPE)
				channelId     = StringFromList(channelType, XOP_CHANNEL_NAMES) + num2istr(channelNumber)
				sprintf traceAnnotation, "%sSweep %d %s", annotationPrefix, sweepNo, channelId
			else
				sprintf traceAnnotation, "%s", annotationPrefix
			endif
			break
		default:
			if(WhichListItem(SF_OP_DATA, plotMetaData.opStack) == -1)
				sprintf traceAnnotation, "%s", prefix
			else
				channelNumber = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELNUMBER)
				channelType   = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELTYPE)
				if(IsNaN(channelNumber) || IsNaN(channelType))
					return ""
				endif
				isAveraged = JWN_GetNumberFromWaveNote(data, SF_META_ISAVERAGED)
				if(IsNaN(isAveraged) || !isAveraged)
					sweepNo = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPNO)
					if(IsNaN(sweepNo))
						return ""
					endif
				endif
				channelId = StringFromList(channelType, XOP_CHANNEL_NAMES) + num2istr(channelNumber)
				if(isAveraged)
					sprintf traceAnnotation, "%s Sweep(s) averaged %s", prefix, channelId
				else
					sprintf traceAnnotation, "%s Sweep %d %s", prefix, sweepNo, channelId
				endif
			endif
			break
	endswitch

	return traceAnnotation
End

static Function/S SF_GetMetaDataAnnotationText(STRUCT SF_PlotMetaData &plotMetaData, WAVE data, string traceName)

	return "\\s(" + traceName + ") " + SF_GetTraceAnnotationText(plotMetaData, data) + "\r"
End

static Function/WAVE SF_GenerateTraceColors(WAVE colorGroups)

	variable numUniqueColors, i
	string lbl

	WAVE uniqueColorGroups = GetUniqueEntries(colorGroups)
	numUniqueColors = DimSize(uniqueColorGroups, ROWS)
	WAVE traceColors = GetColorWave(numUniqueColors)

	for(i = 0; i < numUniqueColors; i += 1)
		[STRUCT RGBColor s] = GetTraceColorAlternative(i)

		lbl = num2str(uniqueColorGroups[i])
		SetDimLabel ROWS, i, $lbl, traceColors

		traceColors[i][%Red]   = s.red
		traceColors[i][%Green] = s.green
		traceColors[i][%Blue]  = s.blue
	endfor

	return traceColors
End

/// @brief Return an Nx3 wave with one color triplett for each unique trace color group
static Function/WAVE SF_GetGroupColors(WAVE/WAVE formulaResults)

	variable numFormulas, i, numUniqueColors, refColorGroup, constantChannelNumAndType
	string lbl

	numFormulas = DimSize(formulaResults, ROWS)

	if(numFormulas == 0)
		return $""
	endif

	WAVE/Z data = formulaResults[0][%FORMULAY]

	if(!WaveExists(data))
		return $""
	endif

	refColorGroup = JWN_GetNumberFromWaveNote(data, SF_META_COLOR_GROUP)

	if(IsNaN(refColorGroup))
		return $""
	endif

	Make/FREE/N=(numFormulas)/D colorGroups = JWN_GetNumberFromWaveNote(formulaResults[p][%FORMULAY], SF_META_COLOR_GROUP)

	if(numFormulas == 1)
		return SF_GenerateTraceColors(colorGroups)
	endif

	// check if the data in the y formulas is from the same channel type and number
	Make/FREE/N=(numFormulas) channelNumbers = JWN_GetNumberFromWaveNote(formulaResults[p][%FORMULAY], SF_META_CHANNELNUMBER)
	Make/FREE/N=(numFormulas) channelTypes = JWN_GetNumberFromWaveNote(formulaResults[p][%FORMULAY], SF_META_CHANNELTYPE)

	constantChannelNumAndType = IsConstant(channelNumbers, channelNumbers[0], ignoreNaN = 0) \
	                            && IsConstant(channelTypes, channelTypes[0], ignoreNaN = 0)

	if(!constantChannelNumAndType)
		return $""
	endif

	return SF_GenerateTraceColors(colorGroups)
End

Function [STRUCT RGBColor s] SF_GetTraceColor(string graph, string opStack, WAVE data, WAVE/Z traceGroupColors)

	variable i, channelNumber, channelType, sweepNo, headstage, numDoInh, minVal, isAveraged, mapIndex
	variable colorGroup, idx

	if(WaveExists(traceGroupColors))
		// Operations with trace group color support:
		// - data/epochs/tp/psxKernel (via SFH_GetSweepsForFormula)
		// - labnotebook
		// - anaFuncParam

		colorGroup = JWN_GetNumberFromWaveNote(data, SF_META_COLOR_GROUP)
		ASSERT(IsFinite(colorGroup), "Invalid color group")

		idx = FindDimLabel(traceGroupColors, ROWS, num2str(colorGroup))
		ASSERT(idx >= 0, "Invalid color group index")

		s.red   = traceGroupColors[idx][%Red]
		s.green = traceGroupColors[idx][%Green]
		s.blue  = traceGroupColors[idx][%Blue]

		return [s]
	endif

	s.red   = 0xFFFF
	s.green = 0x0000
	s.blue  = 0x0000

	Make/FREE/T stopInheritance = {SF_OPSHORT_MINUS, SF_OPSHORT_PLUS, SF_OPSHORT_DIV, SF_OPSHORT_MULT}
	Make/FREE/T doInheritance = {SF_OP_DATA, SF_OP_TP, SF_OP_PSX, SF_OP_PSX_STATS, SF_OP_EPOCHS, SF_OP_LABNOTEBOOK, SF_OP_ANAFUNCPARAM}

	WAVE/T opStackW = ListToTextWave(opStack, ";")
	numDoInh = DimSize(doInheritance, ROWS)
	Make/FREE/N=(numDoInh) findPos
	for(i = 0; i < numDoInh; i += 1)
		FindValue/TEXT=doInheritance[i]/TXOP=4 opStackW
		findPos[i] = (V_Value == -1) ? NaN : V_Value
	endfor
	minVal = WaveMin(findPos)
	if(IsNaN(minVal))
		return [s]
	endif

	Redimension/N=(minVal) opStackW
	WAVE/Z/T common = GetSetIntersection(opStackW, stopInheritance)
	if(WaveExists(common))
		return [s]
	endif

	isAveraged = JWN_GetNumberFromWaveNote(data, SF_META_ISAVERAGED)
	if(isAveraged)
		[s] = GetTraceColorForAverage()
		return [s]
	endif

	channelNumber = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELNUMBER)
	channelType   = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELTYPE)
	mapIndex      = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPMAPINDEX)
	sweepNo       = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPNO)
	if(!IsValidSweepNumber(sweepNo))
		return [s]
	endif

	WAVE/Z numericalValues = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_VALUES)
	if(!WaveExists(numericalValues))
		return [s]
	endif
	if(channelType == XOP_CHANNEL_TYPE_TTL)
		[s] = GetHeadstageColor(NaN, channelType = channelType, channelNumber = channelNumber)
	else
		headstage = GetHeadstageForChannel(numericalValues, sweepNo, channelType, channelNumber, DATA_ACQUISITION_MODE)
		[s]       = GetHeadstageColor(headstage)
	endif

	return [s]
End

/// @brief Generate `numTraces` trace names for the given input
///
/// Generates the trace names required for a single formula in the plotter and
/// therefore the trace names range from `traceCnt` to `traceCnt + numTraces - 1`.
///
/// @retval traces   generated trace names
/// @retval traceCnt total count of all traces (input *and* output)
static Function [WAVE/T traces, variable traceCnt] SF_CreateTraceNames(variable numTraces, variable dataNum, STRUCT SF_PlotMetaData &plotMetaData, WAVE data)

	string traceAnnotation

	if(!numTraces)
		return [$"", traceCnt]
	endif

	traceAnnotation = SF_GetTraceAnnotationText(plotMetaData, data)
	traceAnnotation = ReplaceString(" ", traceAnnotation, "_")
	traceAnnotation = CleanupName(traceAnnotation, 0)

	Make/T/N=(numTraces)/FREE traces

	traces[] = GetTraceNamePrefix(traceCnt + p) + "d" + num2istr(dataNum) + "_" + traceAnnotation

	return [traces, traceCnt + numTraces]
End

/// Reduces a multi line legend to a single line if only the sweep number changes.
/// Returns the original annotation if more changes or the legend text does not follow the exected format
static Function/S SF_ShrinkLegend(string annotation)

	string str, tracePrefix, opPrefix, sweepNum, suffix
	string opPrefixOld, suffixOld, tracePrefixOld, shrunkAnnotation
	string   sweepList
	variable multipleSweeps

	string expr = "(\\\\s\\([\\s\\S]+\\)) ([\\s\\S]*Sweep) (\\d+) ([\\s\\S]*)"

	WAVE/T lines = ListToTextWave(annotation, "\r")
	if(DimSize(lines, ROWS) < 2)
		return annotation
	endif

	shrunkAnnotation = ""

	tracePrefixOld = ""
	suffixOld      = ""
	opPrefixOld    = ""
	sweepList      = ""

	for(line : lines)
		SplitString/E=expr line, tracePrefix, opPrefix, sweepNum, suffix
		if(V_flag != 4)
			return annotation
		endif

		if(IsEmpty(tracePrefixOld) && IsEmpty(opPrefixOld) && IsEmpty(suffixOld))
			tracePrefixOld = tracePrefix
			opPrefixOld    = opPrefix
			suffixOld      = suffix
			sweepList      = ""
		endif

		if(CmpStr(suffixOld, suffix, 2))
			return annotation
		endif

		if(CmpStr(opPrefixOld, opPrefix, 2))
			multipleSweeps    = ItemsInList(sweepList, ",") > 1
			sweepList         = CompressNumericalList(sweepList, ",")
			shrunkAnnotation += tracePrefixOld + opPrefixOld + SelectString(multipleSweeps, "", "s") + " " + sweepList + " " + suffixOld + "\r"

			tracePrefixOld = tracePrefix
			opPrefixOld    = opPrefix
			suffixOld      = suffix
			sweepList      = ""
		endif

		sweepList = AddListItem(sweepNum, sweepList, ",", Inf)
	endfor

	if(!IsEmpty(sweepList))
		multipleSweeps    = ItemsInList(sweepList, ",") > 1
		sweepList         = CompressNumericalList(sweepList, ",")
		shrunkAnnotation += tracePrefixOld + opPrefixOld + SelectString(multipleSweeps, "", "s") + " " + sweepList + " " + suffixOld
	endif

	return shrunkAnnotation
End

static Function [WAVE/T plotGraphs, WAVE/WAVE infos] SF_PreparePlotter(string winNameTemplate, string graph, variable winDisplayMode, variable numGraphs)

	variable i, guidePos, restoreCursorInfo
	string panelName, guideName1, guideName2, win

	ASSERT(numGraphs > 0, "Can not prepare plotter window for zero graphs")

	Make/FREE/T/N=(numGraphs) plotGraphs
	Make/FREE/WAVE/N=(numGraphs, 3) infos
	SetDimensionLabels(infos, "axes;cursors;annotations", COLS)

	// collect infos
	for(i = 0; i < numGraphs; i += 1)
		if(winDisplayMode == SF_DM_NORMAL)
			win = winNameTemplate + num2istr(i)
		elseif(winDisplayMode == SF_DM_SUBWINDOWS)
			win = winNameTemplate + "#" + "Graph" + num2istr(i)
		endif

		if(WindowExists(win))
			WAVE/Z/T axes     = GetAxesProperties(win)
			WAVE/Z/T cursors  = GetCursorInfos(win)
			WAVE/Z/T annoInfo = GetAnnotationInfo(win)

			if(WaveExists(cursors) && winDisplayMode == SF_DM_SUBWINDOWS)
				restoreCursorInfo = 1
			endif

			infos[i][%axes]        = axes
			infos[i][%cursors]     = cursors
			infos[i][%annotations] = annoInfo
		endif
	endfor

	if(winDisplayMode == SF_DM_NORMAL)
		for(i = 0; i < numGraphs; i += 1)
			win = winNameTemplate + num2istr(i)

			if(!WindowExists(win))
				Display/N=$win/K=1/W=(150, 400, 1000, 700) as win
				win = S_name
			endif

			SF_CommonWindowSetup(win, graph)

			plotGraphs[i] = win
		endfor
	elseif(winDisplayMode == SF_DM_SUBWINDOWS)

		win = winNameTemplate
		if(WindowExists(win))
			TUD_Clear(win, recursive = 1)

			WAVE/T allWindows = ListToTextWave(GetAllWindows(win), ";")

			for(subWindow : allWindows)
				if(IsSubwindow(subWindow))
					// in complex hierarchies we might kill more outer subwindows first
					// so the inner ones might later not exist anymore
					KillWindow/Z $subWindow
				endif
			endfor

			RemoveAllControls(win)
			RemoveAllDrawLayers(win)
		else
			NewPanel/N=$win/K=1/W=(150, 400, 1000, 700)
			win = S_name

			SF_CommonWindowSetup(win, graph)
		endif

		// now we have an open panel without any subwindows

		if(restoreCursorInfo)
			ShowInfo/W=$win
		endif

		// create horizontal guides (one more than graphs)
		for(i = 0; i < (numGraphs + 1); i += 1)
			guideName1 = SF_PLOTTER_GUIDENAME + num2istr(i)
			guidePos   = i / numGraphs
			DefineGuide/W=$win $guideName1={FT, guidePos, FB}
		endfor

		DefineGuide/W=$win customLeft={FL, 0.0, FR}
		DefineGuide/W=$win customRight={FL, 1.0, FR}

		// and now the subwindow graphs
		for(i = 0; i < numGraphs; i += 1)
			guideName1 = SF_PLOTTER_GUIDENAME + num2istr(i)
			guideName2 = SF_PLOTTER_GUIDENAME + num2istr(i + 1)
			Display/HOST=$win/FG=(customLeft, $guideName1, customRight, $guideName2)/N=$("Graph" + num2str(i))
			plotGraphs[i] = winNameTemplate + "#" + S_name
		endfor
	endif

	for(win : plotGraphs)
		RemoveTracesFromGraph(win)
		ModifyGraph/W=$win swapXY=0
	endfor

	return [plotGraphs, infos]
End

static Function SF_CommonWindowSetup(string win, string graph)

	string newTitle

	NVAR JSONid = $GetSettingsJSONid()
	PS_InitCoordinates(JSONid, win, "sweepformula_" + win)

	SetWindow $win, hook(resetScaling)=IH_ResetScaling, userData($SFH_USER_DATA_BROWSER)=graph

	newTitle = BSP_GetFormulaGraphTitle(graph)
	DoWindow/T $win, newTitle
End

static Function SF_GatherAxisLabels(WAVE/WAVE formulaResults, string explicitLbl, string formulaLabel, WAVE/T axisLabels)

	variable i, size, numData
	string unit

	size = DimSize(axisLabels, ROWS)
	if(!isEmpty(explicitLbl))
		Redimension/N=(size + 1) axisLabels
		axisLabels[size] = explicitLbl
		return NaN
	endif

	numData = DimSize(formulaResults, ROWS)
	Redimension/N=(size + numData) axisLabels

	for(i = 0; i < numData; i += 1)
		WAVE/Z wvResultY = formulaResults[i][%FORMULAY]
		if(!WaveExists(wvResultY))
			continue
		endif

		strswitch(formulaLabel)
			case "FORMULAY":
				unit = WaveUnits(wvResultY, COLS)
				break
			case "FORMULAX":
				WAVE/Z wvResultX = formulaResults[i][%FORMULAX]
				if(WaveExists(wvResultX))
					unit = WaveUnits(wvResultX, ROWS)
				else
					unit = WaveUnits(wvResultY, ROWS)
				endif
				break
			default:
				FATAL_ERROR("Unsupported formulaLabel: " + formulaLabel)
				break
		endswitch

		// fallback to the unit if present
		if(!IsEmpty(unit))
			axisLabels[size] = SF_FormatUnit(unit)
			size            += 1
		endif
	endfor

	Redimension/N=(size) axisLabels
End

static Function/S SF_CombineAxisLabels(WAVE/T axisLabels)

	WAVE/T unique = GetUniqueEntries(axisLabels, dontDuplicate = 1)

	return TextWaveToList(unique, " / ", trailSep = 0)
End

static Function SF_CheckNumTraces(string graph, variable numTraces)

	string bsPanel, msg

	bsPanel = BSP_GetPanel(GetMainWindow(graph))
	if(numTraces > SF_NUMTRACES_ERROR_THRESHOLD)
		if(!AlreadyCalledOnce(CO_SF_TOO_MANY_TRACES))
			printf "If you really need the feature to plot more than %d traces in the SweepFormula plotter\r", SF_NUMTRACES_ERROR_THRESHOLD
			printf "create an new issue on our development platform. Simply select \"Report an issue\" in the \"Mies Panels\" menu.\r"
		endif

		sprintf msg, "Attempt to plot too many traces (%d).", numTraces
		SFH_FATAL_ERROR(msg)
	endif
	if(numTraces > SF_NUMTRACES_WARN_THRESHOLD)
		sprintf msg, "Plotting %d traces...", numTraces
		SF_SetOutputState(msg, SF_MSG_WARN)
		DoUpdate/W=$bsPanel
	endif
End

static Function SF_CleanUpPlotWindowsOnFail(WAVE/T plotGraphs)

	for(str : plotGraphs)
		WAVE/Z wv = WaveRefIndexed(str, 0, 1)
		if(!WaveExists(wv))
			KillWindow/Z $str
		endif
	endfor
End

static Function SF_KillWorkingDF(string graph)

	DFREF dfrWork = SFH_GetWorkingDF(graph)
	KillOrMoveToTrash(dfr = dfrWork)
End

/// @brief Return the X or Y wave for the sweep formula
static Function/WAVE GetSweepFormula(DFREF dfr, variable graphNr, variable forAxis)

	if(forAxis == SF_SWEEPFORMULA_AXIS_X)
		return GetSweepFormulaX(dfr, graphNr)
	elseif(forAxis == SF_SWEEPFORMULA_AXIS_Y)
		return GetSweepFormulaY(dfr, graphNr)
	endif

	FATAL_ERROR("Unknown SF axis")
End

static Function/WAVE SF_PrepareResultWaveForPlotting(DFREF dfr, WAVE wvResult, variable dataCnt, variable forAxis)

	variable mXn
	string   fullWavePath

	WAVE wv = GetSweepFormula(dfr, dataCnt, forAxis)
	fullWavePath = GetWavesDataFolder(wv, 2)
	if(WaveType(wvResult, 1) != WaveType(wv, 1))
		KillOrMoveToTrash(wv = wv)
	endif
	Duplicate/O wvResult, $fullWavePath

	WAVE plotWave = GetSweepFormula(dfr, dataCnt, forAxis)

	mXn = max(1, DimSize(plotWave, COLS)) * max(1, DimSize(plotWave, LAYERS))
	Redimension/N=(-1, mXn)/E=1 plotWave

	return plotWave
End

/// @brief  Plot the formula using the data from graph
///
/// @param graph  graph to pass to SF_FormulaExecutor
/// @param formula formula to plot
/// @param dmMode  [optional, default DM_SUBWINDOWS] display mode that defines how multiple sweepformula graphs are arranged
static Function SF_FormulaPlotter(string graph, string formula, [variable dmMode])

	string trace, customLegend
	variable i, j, k, l, numTraces, splitTraces, splitY, splitX, numGraphs, numWins, numData, dataCnt, traceCnt
	variable winDisplayMode, showLegend, tagCounter, overrideMarker
	variable xMxN, yMxN, xPoints, yPoints, keepUserSelection, numAnnotations, formulasAreDifferent, postPlotPSX
	variable formulaCounter, gdIndex, markerCode, lineCode, lineStyle, traceToFront, isCategoryAxis
	string win, wList, winNameTemplate, exWList, wName, annotation, xAxisLabel, yAxisLabel, wvName, info, xAxis
	string formulasRemain, yAndXFormula, xFormula, yFormula, tagText, name, winHook
	STRUCT SF_PlotMetaData plotMetaData
	STRUCT RGBColor        color

	winDisplayMode = ParamIsDefault(dmMode) ? SF_DM_SUBWINDOWS : dmMode
	ASSERT(winDisplaymode == SF_DM_NORMAL || winDisplaymode == SF_DM_SUBWINDOWS, "Invalid display mode.")

	DFREF dfr = SF_GetBrowserDF(graph)

	WAVE/T graphCode = SF_SplitCodeToGraphs(formula)

	SVAR lastCode = $GetLastSweepFormulaCode(dfr)
	keepUserSelection = !cmpstr(lastCode, formula)

	numGraphs       = DimSize(graphCode, ROWS)
	wList           = ""
	winNameTemplate = SF_GetFormulaWinNameTemplate(graph)

	[WAVE/T plotGraphs, WAVE/WAVE infos] = SF_PreparePlotter(winNameTemplate, graph, winDisplayMode, numGraphs)

	for(j = 0; j < numGraphs; j += 1)

		traceCnt       = 0
		numAnnotations = 0
		postPlotPSX    = 0
		showLegend     = 1
		formulaCounter = 0
		WAVE/Z wvX = $""

		Make/FREE/T/N=0 xAxisLabels, yAxisLabels

		formulasRemain = graphCode[j]

		win   = plotGraphs[j]
		wList = AddListItem(win, wList)

		Make/FREE=1/T/N=(MINIMUM_WAVE_SIZE) wAnnotations, formulaArgSetup
		Make/FREE=1/WAVE/N=(MINIMUM_WAVE_SIZE) collPlotFormData

		do

			WAVE/WAVE plotFormData = SF_CreatePlotFormulaDataWave()
			gdIndex    = 0
			annotation = ""

			SplitString/E=SF_SWEEPFORMULA_WITH_REGEXP formulasRemain, yAndXFormula, formulasRemain
			if(!V_flag)
				break
			endif

			[xFormula, yFormula] = SF_SplitGraphsToFormula(yAndXFormula)
			SFH_ASSERT(!IsEmpty(yFormula), "Could not determine y [vs x] formula pair.")

			WAVE/Z/WAVE formulaResults = $""
			try
				[formulaResults, plotMetaData] = SF_GatherFormulaResults(xFormula, yFormula, graph)
			catch
				SF_CleanUpPlotWindowsOnFail(plotGraphs)
				Abort
			endtry

			SF_GatherAxisLabels(formulaResults, plotMetaData.xAxisLabel, "FORMULAX", xAxisLabels)
			SF_GatherAxisLabels(formulaResults, plotMetaData.yAxisLabel, "FORMULAY", yAxisLabels)

			if(!cmpstr(plotMetaData.dataType, SF_DATATYPE_PSX))
				PSX_Plot(win, graph, formulaResults, plotMetaData)
				postPlotPSX = 1
				continue
			endif

			SF_FormulaPlotterExtendResultsIfCompatible(formulaResults)

			WAVE/Z traceGroupColors = SF_GetGroupColors(formulaResults)

			numData = DimSize(formulaResults, ROWS)
			for(k = 0; k < numData; k += 1)

				WAVE/Z wvResultX = formulaResults[k][%FORMULAX]
				WAVE/Z wvResultY = formulaResults[k][%FORMULAY]
				if(!WaveExists(wvResultY))
					continue
				endif
				if(JWN_GetNumberFromWaveNote(wvResultY, SF_META_DONOTPLOT) == 1)
					continue
				endif

				SFH_ASSERT(!(IsTextWave(wvResultY) && WaveDims(wvResultY) > 1), "Plotter got 2d+ text wave as y data.")

				[color] = SF_GetTraceColor(graph, plotMetaData.opStack, wvResultY, traceGroupColors)

				if(!WaveExists(wvResultX) && !IsEmpty(plotMetaData.xAxisLabel))
					WAVE/Z wvResultX = JWN_GetNumericWaveFromWaveNote(wvResultY, SF_META_XVALUES)

					if(!WaveExists(wvResultX))
						WAVE/Z wvResultX = JWN_GetTextWaveFromWaveNote(wvResultY, SF_META_XVALUES)
					endif
				endif

				if(WaveExists(wvResultX))
					SFH_ASSERT(!(IsTextWave(wvResultX) && WaveDims(wvResultX) > 1), "Plotter got 2d+ text wave as x data.")
					WAVE wvX = SF_PrepareResultWaveForPlotting(dfr, wvResultX, dataCnt, SF_SWEEPFORMULA_AXIS_X)
					xPoints = DimSize(wvX, ROWS)
					xMxN    = DimSize(wvX, COLS)
				endif

				WAVE wvY = SF_PrepareResultWaveForPlotting(dfr, wvResultY, dataCnt, SF_SWEEPFORMULA_AXIS_Y)
				yPoints = DimSize(wvY, ROWS)
				yMxN    = DimSize(wvY, COLS)

				SFH_ASSERT(!(IsTextWave(wvY) && (WaveExists(wvX) && IsTextWave(wvX))), "One wave needs to be numeric for plotting")

				if(IsTextWave(wvY))
					SFH_ASSERT(WaveExists(wvX), "Cannot plot a single text wave")
					ModifyGraph/W=$win swapXY=1
					WAVE dummy = wvY
					WAVE wvY   = wvX
					WAVE wvX   = dummy
				endif

				if(!WaveExists(wvX))
					numTraces = yMxN
					SF_CheckNumTraces(graph, numTraces)
					[WAVE/T traces, traceCnt] = SF_CreateTraceNames(numTraces, k, plotMetaData, wvResultY)

					for(i = 0; i < numTraces; i += 1)
						SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
						AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][i]/TN=$traces[i]
						annotation += SF_GetMetaDataAnnotationText(plotMetaData, wvResultY, traces[i])
					endfor
				elseif((xMxN == 1) && (yMxN == 1)) // 1D
					if(yPoints == 1) // 0D vs 1D
						numTraces = xPoints
						SF_CheckNumTraces(graph, numTraces)
						[WAVE/T traces, traceCnt] = SF_CreateTraceNames(numTraces, k, plotMetaData, wvResultY)

						for(i = 0; i < numTraces; i += 1)
							SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
							AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][0]/TN=$traces[i] vs wvX[i][]
							annotation += SF_GetMetaDataAnnotationText(plotMetaData, wvResultY, traces[i])
						endfor
					elseif(xPoints == 1) // 1D vs 0D
						numTraces = yPoints
						SF_CheckNumTraces(graph, numTraces)
						[WAVE/T traces, traceCnt] = SF_CreateTraceNames(numTraces, k, plotMetaData, wvResultY)

						for(i = 0; i < numTraces; i += 1)
							SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
							AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[i][]/TN=$traces[i] vs wvX[][0]
							annotation += SF_GetMetaDataAnnotationText(plotMetaData, wvResultY, traces[i])
						endfor
					else // 1D vs 1D
						splitTraces = min(yPoints, xPoints)
						numTraces   = floor(max(yPoints, xPoints) / splitTraces)
						SF_CheckNumTraces(graph, numTraces)
						[WAVE/T traces, traceCnt] = SF_CreateTraceNames(numTraces, k, plotMetaData, wvResultY)

						if(mod(max(yPoints, xPoints), splitTraces) == 0)
							DebugPrint("Unmatched Data Alignment in ROWS.")
						endif

						for(i = 0; i < numTraces; i += 1)
							if(WindowExists(win) && WhichListItem("bottom", AxisList(win)) >= 0)
								info           = AxisInfo(win, "bottom")
								isCategoryAxis = NumberByKey("ISCAT", info) == 1

								if(isCategoryAxis)
									DFREF              catDFR       = $StringByKey("CATWAVEDF", info)
									WAVE/Z/SDFR=catDFR categoryWave = $StringByKey("CATWAVE", info)
									ASSERT(WaveExists(categoryWave), "Expected category axis")

									if(EqualWaves(categoryWave, wvX, EQWAVES_DATA))
										// we can't, but also don't need, to append the same category axis again
										// so let's just reuse the existing one
										WAVE wvX = categoryWave
									endif
								endif
							endif

							SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
							splitY = SF_SplitPlotting(wvY, ROWS, i, splitTraces)
							splitX = SF_SplitPlotting(wvX, ROWS, i, splitTraces)
							AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[splitY, splitY + splitTraces - 1][0]/TN=$traces[i] vs wvX[splitX, splitX + splitTraces - 1][0]
							annotation += SF_GetMetaDataAnnotationText(plotMetaData, wvResultY, traces[i])
						endfor
					endif
				elseif(yMxN == 1) // 1D vs 2D
					numTraces = xMxN
					SF_CheckNumTraces(graph, numTraces)
					[WAVE/T traces, traceCnt] = SF_CreateTraceNames(numTraces, k, plotMetaData, wvResultY)

					for(i = 0; i < numTraces; i += 1)
						SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
						AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][0]/TN=$traces[i] vs wvX[][i]
						annotation += SF_GetMetaDataAnnotationText(plotMetaData, wvResultY, traces[i])
					endfor
				elseif(xMxN == 1) // 2D vs 1D or 0D
					if(xPoints == 1) // 2D vs 0D -> extend X to 1D with constant value
						Redimension/N=(yPoints) wvX
						xPoints = yPoints
						wvX     = wvX[0]
					endif
					numTraces = yMxN
					SF_CheckNumTraces(graph, numTraces)
					[WAVE/T traces, traceCnt] = SF_CreateTraceNames(numTraces, k, plotMetaData, wvResultY)

					for(i = 0; i < numTraces; i += 1)
						SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
						AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][i]/TN=$traces[i] vs wvX
						annotation += SF_GetMetaDataAnnotationText(plotMetaData, wvResultY, traces[i])
					endfor
				else // 2D vs 2D
					numTraces = WaveExists(wvX) ? max(1, max(yMxN, xMxN)) : max(1, yMxN)
					SF_CheckNumTraces(graph, numTraces)
					[WAVE/T traces, traceCnt] = SF_CreateTraceNames(numTraces, k, plotMetaData, wvResultY)

					if(yPoints != xPoints)
						DebugPrint("Size mismatch in data rows for plotting waves.")
					endif
					if(DimSize(wvY, COLS) != DimSize(wvX, COLS))
						DebugPrint("Size mismatch in entity columns for plotting waves.")
					endif
					for(i = 0; i < numTraces; i += 1)
						SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
						if(WaveExists(wvX))
							AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][min(yMxN - 1, i)]/TN=$traces[i] vs wvX[][min(xMxN - 1, i)]
						else
							AppendTograph/W=$win/C=(color.red, color.green, color.blue) wvY[][i]/TN=$traces[i]
						endif
						annotation += SF_GetMetaDataAnnotationText(plotMetaData, wvResultY, traces[i])
					endfor
				endif

				showLegend = showLegend && SF_GetShowLegend(wvY)

				dataCnt += 1
			endfor

			if(!IsEmpty(annotation))
				EnsureLargeEnoughWave(wAnnotations, indexShouldExist = numAnnotations)
				wAnnotations[numAnnotations] = annotation
				EnsureLargeEnoughWave(formulaArgSetup, indexShouldExist = numAnnotations)
				formulaArgSetup[numAnnotations] = plotMetaData.argSetupStack
				numAnnotations                 += 1
			endif

			EnsureLargeEnoughWave(collPlotFormData, indexShouldExist = formulaCounter)
			WAVE/T    tracesInGraph = plotFormData[0]
			WAVE/WAVE dataInGraph   = plotFormData[1]
			Redimension/N=(gdIndex, -1) tracesInGraph, dataInGraph
			collPlotFormData[formulaCounter] = plotFormData
			formulaCounter                  += 1
		while(1)

		if(showLegend)
			customLegend = JWN_GetStringFromWaveNote(formulaResults, SF_META_CUSTOM_LEGEND)

			if(!IsEmpty(customLegend))
				annotation = customLegend
			elseif(numAnnotations > 0)
				annotation = ""
				for(k = 0; k < numAnnotations; k += 1)
					wAnnotations[k] = SF_ShrinkLegend(wAnnotations[k])
				endfor
				Redimension/N=(numAnnotations) wAnnotations, formulaArgSetup
				formulasAreDifferent = SFH_EnrichAnnotations(wAnnotations, formulaArgSetup)
				annotation           = TextWaveToList(wAnnotations, "\r")
				annotation           = UnPadString(annotation, char2num("\r"))
			endif

			if(!IsEmpty(annotation))
				Legend/W=$win/C/N=metadata/F=2 annotation
			endif
		endif

		WAVE/Z xTickLabelsAsFree    = JWN_GetTextWaveFromWaveNote(formulaResults, SF_META_XTICKLABELS)
		WAVE/Z xTickPositionsAsFree = JWN_GetNumericWaveFromWaveNote(formulaResults, SF_META_XTICKPOSITIONS)

		if(WaveExists(xTickLabelsAsFree) && WaveExists(xTickPositionsAsFree))
			DFREF dfrWork = SFH_GetWorkingDF(graph)
			wvName = "xTickLabels_" + win + "_" + NameOfWave(formulaResults)
			WAVE xTickLabels = MoveFreeWaveToPermanent(xTickLabelsAsFree, dfrWork, wvName)

			wvName = "xTickPositions_" + win + "_" + NameOfWave(formulaResults)
			WAVE xTickPositions = MoveFreeWaveToPermanent(xTickPositionsAsFree, dfrWork, wvName)

			ModifyGraph/Z/W=$win userticks(bottom)={xTickPositions, xTickLabels}
		endif

		WAVE/Z yTickLabelsAsFree    = JWN_GetTextWaveFromWaveNote(formulaResults, SF_META_YTICKLABELS)
		WAVE/Z yTickPositionsAsFree = JWN_GetNumericWaveFromWaveNote(formulaResults, SF_META_YTICKPOSITIONS)

		if(WaveExists(yTickLabelsAsFree) && WaveExists(yTickPositionsAsFree))
			DFREF dfrWork = SFH_GetWorkingDF(graph)
			wvName = "yTickLabels_" + win + "_" + NameOfWave(formulaResults)
			WAVE yTickLabels = MoveFreeWaveToPermanent(yTickLabelsAsFree, dfrWork, wvName)

			wvName = "yTickPositions_" + win + "_" + NameOfWave(formulaResults)
			WAVE yTickPositions = MoveFreeWaveToPermanent(yTickPositionsAsFree, dfrWork, wvName)

			ModifyGraph/Z/W=$win userticks(left)={yTickPositions, yTickLabels}

			Make/FREE yTickPositionsWorkaround = {0, 1}
			if(EqualWaves(yTickPositions, yTickPositionsWorkaround, EQWAVES_DATA))
				// @todo workaround bug 4531 so that we get tick labels even with only constant y values
				SetAxis/W=$win/Z left, 0, 1
			endif
		endif

		winHook = JWN_GetStringFromWaveNote(formulaResults, SF_META_WINDOW_HOOK)
		if(!IsEmpty(winHook))
			SetWindow $win, tooltipHook(SweepFormulaTraceValue)=$winHook
		endif

		for(k = 0; k < formulaCounter; k += 1)
			WAVE/WAVE plotFormData  = collPlotFormData[k]
			WAVE/T    tracesInGraph = plotFormData[0]
			WAVE/WAVE dataInGraph   = plotFormData[1]
			numTraces  = DimSize(tracesInGraph, ROWS)
			markerCode = formulasAreDifferent ? k : 0
			markerCode = SFH_GetPlotMarkerCodeSelection(markerCode)
			lineCode   = formulasAreDifferent ? k : 0
			lineCode   = SFH_GetPlotLineCodeSelection(lineCode)
			for(l = 0; l < numTraces; l += 1)

				WAVE/Z wvX = dataInGraph[l][%WAVEX]
				WAVE   wvY = dataInGraph[l][%WAVEY]
				trace = tracesInGraph[l]

				info           = AxisInfo(win, "left")
				isCategoryAxis = (NumberByKey("ISCAT", info) == 1)

				if(isCategoryAxis)
					WAVE traceColorHolder = wvX
				else
					WAVE traceColorHolder = wvY
				endif

				WAVE/Z traceColor = JWN_GetNumericWaveFromWaveNote(traceColorHolder, SF_META_TRACECOLOR)
				if(WaveExists(traceColor))
					switch(DimSize(traceColor, ROWS))
						case 3:
							ModifyGraph/W=$win rgb($trace)=(traceColor[0], traceColor[1], traceColor[2])
							break
						case 4:
							ModifyGraph/W=$win rgb($trace)=(traceColor[0], traceColor[1], traceColor[2], traceColor[3])
							break
						default:
							FATAL_ERROR("Invalid size of trace color wave")
					endswitch
				endif

				tagText = JWN_GetStringFromWaveNote(wvY, SF_META_TAG_TEXT)
				if(!IsEmpty(tagText))
					name = "tag" + num2str(tagCounter++)
					Tag/C/N=$name/W=$win/F=0/L=0/X=0.00/Y=0.00 $trace, 0, tagText
				endif

				ModifyGraph/W=$win mode($trace)=SF_DeriveTraceDisplayMode(wvX, wvY)

				lineStyle = JWN_GetNumberFromWaveNote(wvY, SF_META_LINESTYLE)
				if(IsValidTraceLineStyle(lineStyle))
					ModifyGraph/W=$win lStyle($trace)=lineStyle
				elseif(formulasAreDifferent)
					ModifyGraph/W=$win lStyle($trace)=lineCode
				endif

				WAVE/Z customMarkerAsFree = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_MOD_MARKER)
				if(WaveExists(customMarkerAsFree))
					DFREF dfrWork = SFH_GetWorkingDF(graph)
					wvName = "customMarker_" + NameOfWave(wvY)
					WAVE customMarker = MoveFreeWaveToPermanent(customMarkerAsFree, dfrWork, wvName)
					ASSERT(DimSize(wvY, ROWS) == DimSize(customMarker, ROWS), "Marker size mismatch")
					ModifyGraph/W=$win zmrkNum($trace)={customMarker}
				else
					overrideMarker = JWN_GetNumberFromWaveNote(wvY, SF_META_MOD_MARKER)

					if(!IsNaN(overrideMarker))
						markerCode = overrideMarker
					endif

					ModifyGraph/W=$win marker($trace)=markerCode
				endif

				traceToFront = JWN_GetNumberFromWaveNote(wvY, SF_META_TRACETOFRONT)
				traceToFront = IsNaN(traceToFront) ? 0 : !!traceToFront
				if(traceToFront)
					ReorderTraces/W=$win _front_, {$trace}
				endif

			endfor
		endfor

		if(traceCnt > 0)
			xAxisLabel = SF_CombineAxisLabels(xAxisLabels)
			if(!IsEmpty(xAxisLabel))
				Label/W=$win bottom, xAxisLabel
				ModifyGraph/W=$win tickUnit(bottom)=1
			endif

			yAxisLabel = SF_CombineAxisLabels(yAxisLabels)
			if(!IsEmpty(yAxisLabel))
				Label/W=$win left, yAxisLabel
				ModifyGraph/W=$win tickUnit(left)=1
			endif

			ModifyGraph/W=$win zapTZ(bottom)=1
		endif

		if(postPlotPSX)
			PSX_PostPlot(win)
		endif

		if(keepUserSelection)
			WAVE/Z cursorInfos    = infos[j][%cursors]
			WAVE/Z axesProperties = infos[j][%axes]
			WAVE/Z annoInfos      = infos[j][%annotations]

			if(WaveExists(cursorInfos))
				RestoreCursors(win, cursorInfos)
			endif

			if(WaveExists(axesProperties))
				SetAxesProperties(win, axesProperties)
			endif

			if(WaveExists(annoInfos))
				WAVE/T annoInfosFiltered = FilterAnnotations(annoInfos, "^tag.*$")
				RestoreAnnotationPositions(win, annoInfosFiltered)
			endif
		endif
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

static Function SF_DeriveTraceDisplayMode(WAVE/Z wvX, WAVE wvY)

	variable traceMode, numYPoints

	numYPoints = DimSize(wvY, ROWS)
	traceMode  = JWN_GetNumberFromWaveNote(wvY, SF_META_TRACE_MODE)
	if(IsValidTraceDisplayMode(traceMode))
		if(traceMode == TRACE_DISPLAY_MODE_LINES)
			if(numYPoints > 1)
				return traceMode
			endif

			return TRACE_DISPLAY_MODE_MARKERS
		endif

		return traceMode
	endif

	if(numYPoints < SF_MAX_NUMPOINTS_FOR_MARKERS                \
	   && (!WaveExists(wvX)                                     \
	       || DimSize(wvx, ROWS) < SF_MAX_NUMPOINTS_FOR_MARKERS))
		return TRACE_DISPLAY_MODE_MARKERS
	endif

	return TRACE_DISPLAY_MODE_LINES
End

static Function SF_GetShowLegend(WAVE wv)

	variable showLegend

	showLegend = JWN_GetNumberFromWaveNote(wv, SF_META_SHOW_LEGEND)

	if(IsFinite(showLegend))
		return !!showLegend
	endif

	return 1
End

/// @brief utility function for @c SF_FormulaPlotter
///
/// split dimension @p dim of wave @p wv into slices of size @p split and get
/// the starting index @p i
///
static Function SF_SplitPlotting(WAVE wv, variable dim, variable i, variable split)

	return min(i, floor(DimSize(wv, dim) / split) - 1) * split
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
	destUnit   = WaveUnits(dest, dimDest)

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
			FATAL_ERROR("Invalid dimDest")
	endswitch
End

/// @brief Return the matching indices of sweepMap, if expName or device is an emtpy string then it is ignored
static Function/WAVE SF_GetSweepMapIndices(WAVE/T sweepMap, variable sweepNo, string expName, string device, [string colLabel, string wildCardPattern])

	variable mapSize

	if(!ParamIsDefault(colLabel))
		ASSERT(!IsEmpty(wildCardPattern), "Need a valid wildcard pattern")
		mapSize = GetNumberFromWaveNote(sweepMap, NOTE_INDEX)
		return FindIndizes(sweepMap, colLabel = colLabel, endRow = mapSize, str = wildCardPattern, prop = PROP_WILDCARD)
	endif

	WAVE/Z sweepIndices = FindIndizes(sweepMap, colLabel = "Sweep", var = sweepNo)
	if(!WaveExists(sweepIndices))
		return $""
	endif
	if(IsEmpty(expName) && IsEmpty(device))
		return sweepIndices
	endif

	if(!IsEmpty(expName))
		WAVE/Z/D expIndices = FindIndizes(sweepMap, colLabel = "FileName", str = expName)
		if(!WaveExists(expIndices))
			return $""
		endif
	endif
	if(!IsEmpty(device))
		WAVE/Z/D devIndices = FindIndizes(sweepMap, colLabel = "Device", str = device)
		if(!WaveExists(devIndices))
			return $""
		endif
	endif

	if(WaveExists(expIndices) && WaveExists(devIndices))
		WAVE/Z set1 = GetSetIntersection(sweepIndices, expIndices)
		if(!WaveExists(set1))
			return $""
		endif

		return GetSetIntersection(set1, devIndices)
	elseif(WaveExists(expIndices))
		return GetSetIntersection(sweepIndices, expIndices)
	endif

	return GetSetIntersection(sweepIndices, devIndices)
End

static Function/WAVE SF_MakeSweepPropertiesDisplayed(variable numTraces)

	Make/FREE/D/N=(numTraces, SWEEPPROP_END) sweepPropertiesDisplayed

	return sweepPropertiesDisplayed
End

static Function/WAVE SF_MakeSweepLNBsDisplayed(variable numTraces)

	Make/FREE/WAVE/N=(numTraces, 2) wv
	SetDimLabel COLS, 0, NUMERICAL, wv
	SetDimLabel COLS, 1, TEXTUAL, wv

	return wv
End

/// @brief Use the labnotebook information to return the active channel numbers
///        for a given set of sweeps
///
/// @param graph  DataBrowser or SweepBrowser reference graph
/// @param filter filled SF_SelectParameters structure
///
/// @return a selectData style wave with three columns
///         containing sweepNumber, channelType and channelNumber
static Function/WAVE SF_GetSelectData(string graph, STRUCT SF_SelectParameters &filter)

	variable i, j, k, l, channelType, channelNumber, sweepNo, sweepNoT, outIndex
	variable numSweeps, numInChannels, numActiveChannels, index
	variable isSweepBrowser
	variable dimPosSweep, dimPosChannelNumber, dimPosChannelType, dimPosSweepMapIndex
	variable dimPosTSweep, dimPosTChannelNumber, dimPosTChannelType, dimPosTClampMode, dimPosTExpName, dimPosTDevice, dimPosTSweepMapIndex
	variable dimPosTNumericalValues, dimPosTTextualValues
	variable numTraces, fromDisplayed, clampCode, smIndexCounter, mapIndex, setCycleCount, setSweepCount, doStimsetMatching
	string msg, device, singleSweepDFStr, expName, dataFolder
	variable mapSize   = 1
	DFREF    deviceDFR = $""

	WAVE/Z sweeps   = filter.sweeps
	WAVE/Z channels = filter.channels

	if(!WaveExists(sweeps) || !WaveExists(channels))
		return $""
	endif

	fromDisplayed  = !CmpStr(filter.vis, SF_OP_SELECTVIS_DISPLAYED)
	isSweepBrowser = BSP_IsSweepBrowser(graph)

	if(!(DimSize(filter.stimsets, ROWS) == 1 && !CmpStr(filter.stimsets[0], SF_OP_SELECT_STIMSETS_ALL)))
		WAVE/Z indizes = FindIndizes(filter.stimsets, str = SF_OP_SELECT_STIMSETS_ALL)
		doStimsetMatching = !WaveExists(indizes)
	endif

	if(fromDisplayed)
		WAVE/Z/T traces = GetTraceInfos(graph)
		if(!WaveExists(traces))
			return $""
		endif
		numTraces    = DimSize(traces, ROWS)
		dimPosTSweep = FindDimLabel(traces, COLS, "sweepNumber")
		Make/FREE/D/N=(numTraces) displayedSweeps = str2num(traces[p][dimPosTSweep])
		WAVE displayedSweepsUnique = GetUniqueEntries(displayedSweeps, dontDuplicate = 1)
		MatrixOp/FREE sweepsDP = fp64(sweeps)
		WAVE/Z sweepsIntersect = GetSetIntersection(sweepsDP, displayedSweepsUnique)
		if(!WaveExists(sweepsIntersect))
			return $""
		endif
		WAVE sweeps = sweepsIntersect
		numSweeps = DimSize(sweeps, ROWS)

		WAVE      selectDisplayed          = SFH_NewSelectDataWave(numTraces, 1)
		WAVE      sweepPropertiesDisplayed = SF_MakeSweepPropertiesDisplayed(numTraces)
		WAVE/WAVE sweepLNBsDisplayed       = SF_MakeSweepLNBsDisplayed(numTraces)
		dimPosSweep         = FindDimLabel(selectDisplayed, COLS, "SWEEP")
		dimPosChannelType   = FindDimLabel(selectDisplayed, COLS, "CHANNELTYPE")
		dimPosChannelNumber = FindDimLabel(selectDisplayed, COLS, "CHANNELNUMBER")
		dimPosSweepMapIndex = FindDimLabel(selectDisplayed, COLS, "SWEEPMAPINDEX")

		dimPosTChannelType     = FindDimLabel(traces, COLS, "channelType")
		dimPosTChannelNumber   = FindDimLabel(traces, COLS, "GUIChannelNumber")
		dimPosTClampMode       = FindDimLabel(traces, COLS, "clampMode")
		dimPosTExpName         = FindDimLabel(traces, COLS, "Experiment")
		dimPosTDevice          = FindDimLabel(traces, COLS, "Device")
		dimPosTSweepMapIndex   = FindDimLabel(traces, COLS, "SweepMapIndex")
		dimPosTNumericalValues = FindDimLabel(traces, COLS, "numericalValues")
		dimPosTTextualValues   = FindDimLabel(traces, COLS, "textualValues")
		for(i = 0; i < numSweeps; i += 1)
			sweepNo = sweeps[i]
			for(j = 0; j < numTraces; j += 1)
				sweepNoT = str2num(traces[j][dimPosTSweep])
				if(sweepNo == sweepNoT)
					if(isSweepBrowser)
						if(!IsEmpty(filter.experimentName) && CmpStr(filter.experimentName, traces[j][dimPosTExpName]))
							continue
						endif
						if(!IsEmpty(filter.device) && CmpStr(filter.device, traces[j][dimPosTDevice]))
							continue
						endif
					endif
					channelType   = WhichListItem(traces[j][dimPosTChannelType], XOP_CHANNEL_NAMES)
					channelNumber = str2num(traces[j][dimPosTChannelNumber])
					WAVE numericalValues = $traces[j][dimPosTNumericalValues]
					WAVE textualValues   = $traces[j][dimPosTTextualValues]
					if(!IsNaN(filter.setCycleCount))
						[WAVE setting, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "Set Cycle Count", channelNumber, channelType, DATA_ACQUISITION_MODE)
						setCycleCount         = WaveExists(setting) ? setting[index] : NaN
					else
						setCycleCount = NaN
					endif
					if(!IsNaN(filter.setSweepCount))
						[WAVE setting, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "Set Sweep Count", channelNumber, channelType, DATA_ACQUISITION_MODE)
						setSweepCount         = WaveExists(setting) ? setting[index] : NaN
					else
						setSweepCount = NaN
					endif

					selectDisplayed[outIndex][dimPosSweep]                      = sweepNo
					selectDisplayed[outIndex][dimPosChannelType]                = channelType
					selectDisplayed[outIndex][dimPosChannelNumber]              = channelNumber
					selectDisplayed[outIndex][dimPosSweepMapIndex]              = str2num(traces[j][dimPosTSweepMapIndex])
					sweepPropertiesDisplayed[outIndex][SWEEPPROP_CLAMPMODE]     = str2num(traces[j][dimPosTClampMode])
					sweepPropertiesDisplayed[outIndex][SWEEPPROP_SETCYCLECOUNT] = setCycleCount
					sweepPropertiesDisplayed[outIndex][SWEEPPROP_SETSWEEPCOUNT] = setSweepCount
					sweepLNBsDisplayed[outIndex][%NUMERICAL]                    = numericalValues
					sweepLNBsDisplayed[outIndex][%TEXTUAL]                      = textualValues
					outIndex                                                   += 1
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
		Redimension/N=(outIndex, -1) sweepPropertiesDisplayed
		Redimension/N=(outIndex, -1) sweepLNBsDisplayed
		numTraces = outIndex

		outIndex = 0
	elseif(isSweepBrowser)
		WAVE/T sweepMap = SB_GetSweepMap(graph)
	else
		DFREF deviceDFR = DB_GetDeviceDF(graph)
	endif

	// search sweeps for active channels
	numSweeps     = DimSize(sweeps, ROWS)
	numInChannels = DimSize(channels, ROWS)

	WAVE selectData = SFH_NewSelectDataWave(numSweeps, NUM_DA_TTL_CHANNELS + NUM_AD_CHANNELS + NUM_DA_TTL_CHANNELS)
	if(!fromDisplayed)
		dimPosSweep         = FindDimLabel(selectData, COLS, "SWEEP")
		dimPosChannelType   = FindDimLabel(selectData, COLS, "CHANNELTYPE")
		dimPosChannelNumber = FindDimLabel(selectData, COLS, "CHANNELNUMBER")
		dimPosSweepMapIndex = FindDimLabel(selectData, COLS, "SWEEPMAPINDEX")
	endif

	for(i = 0; i < numSweeps; i += 1)
		sweepNo = sweeps[i]

		if(!IsValidSweepNumber(sweepNo))
			continue
		endif

		if(!fromDisplayed)
			if(isSweepBrowser)
				WAVE/Z mapIndices = SF_GetSweepMapIndices(sweepMap, sweepNo, filter.experimentName, filter.device)
				if(!WaveExists(mapIndices))
					continue
				endif
				mapSize = DimSize(mapIndices, ROWS)
			elseif(DB_SplitSweepsIfReq(graph, sweepNo))
				continue
			endif
		endif

		for(smIndexCounter = 0; smIndexCounter < mapSize; smIndexCounter += 1)
			if(!fromDisplayed)
				mapIndex = isSweepBrowser ? mapIndices[smIndexCounter] : NaN
				DFREF sweepDFR
				[WAVE numericalValues, WAVE textualValues, sweepDFR] = SFH_GetLabNoteBooksAndDFForSweep(graph, sweepNo, mapIndex)
				if(!WaveExists(numericalValues) || !WaveExists(textualValues) || !DataFolderExistsDFR(sweepDFR))
					continue
				endif
			endif

			for(j = 0; j < numInChannels; j += 1)

				channelType   = channels[j][%channelType]
				channelNumber = channels[j][%channelNumber]

				if(IsNaN(channelType))
					Make/FREE/D channelTypes = {XOP_CHANNEL_TYPE_DAC, XOP_CHANNEL_TYPE_ADC, XOP_CHANNEL_TYPE_TTL}
				else
					sprintf msg, "Unhandled channel type %g in channels() at position %d", channelType, j
					SFH_ASSERT(channelType == XOP_CHANNEL_TYPE_DAC || channelType == XOP_CHANNEL_TYPE_ADC || channelType == XOP_CHANNEL_TYPE_TTL, msg)
					Make/FREE/D channelTypes = {channelType}
				endif

				for(channelType : channelTypes)

					if(fromDisplayed)
						for(l = 0; l < numTraces; l += 1)

							clampCode = SF_MapClampModeToSelectCM(sweepPropertiesDisplayed[l][SWEEPPROP_CLAMPMODE])
							if(!SF_IsValidSingleSelection(filter, sweepLNBsDisplayed[l][%NUMERICAL], sweepLNBsDisplayed[l][%TEXTUAL], sweepNo, channelNumber, channelType, selectDisplayed[l][dimPosSweep], selectDisplayed[l][dimPosChannelNumber], selectDisplayed[l][dimPosChannelType], clampCode, sweepPropertiesDisplayed[l][SWEEPPROP_SETCYCLECOUNT], sweepPropertiesDisplayed[l][SWEEPPROP_SETSWEEPCOUNT], doStimsetMatching))
								continue
							endif

							selectData[outIndex][dimPosSweep]         = sweepNo
							selectData[outIndex][dimPosChannelType]   = channelType
							selectData[outIndex][dimPosChannelNumber] = selectDisplayed[l][dimPosChannelNumber]
							selectData[outIndex][dimPosSweepMapIndex] = selectDisplayed[l][dimPosSweepMapIndex]
							outIndex                                 += 1
						endfor
					else
						WAVE/Z activeChannels = GetActiveChannels(numericalValues, textualValues, sweepNo, channelType)
						if(!WaveExists(activeChannels))
							continue
						endif
						// faster than ZapNaNs due to no mem alloc
						numActiveChannels = DimSize(activeChannels, ROWS)
						for(l = 0; l < numActiveChannels; l += 1)
							if(IsNan(activeChannels[l]))
								continue
							endif

							if(SF_FilterByClampModeEnabled(filter.clampMode, channelType))
								[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, CLAMPMODE_ENTRY_KEY, l, channelType, DATA_ACQUISITION_MODE)
								clampCode             = WaveExists(setting) ? SF_MapClampModeToSelectCM(setting[index]) : SF_OP_SELECT_CLAMPCODE_NONE
							endif
							if(!IsNaN(filter.setCycleCount))
								[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "Set Cycle Count", l, channelType, DATA_ACQUISITION_MODE)
								setCycleCount         = WaveExists(setting) ? setting[index] : NaN
							endif
							if(!IsNaN(filter.setSweepCount))
								[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "Set Sweep Count", l, channelType, DATA_ACQUISITION_MODE)
								setSweepCount         = WaveExists(setting) ? setting[index] : NaN
							endif

							if(!SF_IsValidSingleSelection(filter, numericalValues, textualValues, sweepNo, channelNumber, channelType, sweepNo, l, channelType, clampCode, setCycleCount, setSweepCount, doStimsetMatching))
								continue
							endif

							selectData[outIndex][dimPosSweep]         = sweepNo
							selectData[outIndex][dimPosChannelType]   = channelType
							selectData[outIndex][dimPosChannelNumber] = l
							selectData[outIndex][dimPosSweepMapIndex] = mapIndex
							outIndex                                 += 1
						endfor
					endif

				endfor
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

static Function SF_IsValidSingleSelection(STRUCT SF_SelectParameters &filter, WAVE numericalValues, WAVE textualValues, variable filtSweepNo, variable filtChannelNumber, variable filtChannelType, variable sweepNo, variable channelNumber, variable channelType, variable clampMode, variable setCycleCount, variable setSweepCount, variable doStimsetMatching)

	variable sweepQC, setQC
	string setName

	if(filtSweepNo != sweepNo)
		return 0
	endif

	if(!IsNaN(filtChannelNumber) && filtChannelNumber != channelNumber)
		return 0
	endif

	if(filtChannelType != channelType)
		return 0
	endif

	if(SF_FilterByClampModeEnabled(filter.clampMode, channelType) && !(filter.clampMode & clampMode))
		return 0
	endif

	if(doStimsetMatching)
		setName = SFH_GetStimsetName(numericalValues, textualValues, sweepNo, channelNumber, channelType)
		if(!MatchAgainstWildCardPatterns(filter.stimsets, setName))
			return 0
		endif
	endif

	if(filter.sweepQC != SF_OP_SELECT_IVSCCSWEEPQC_IGNORE)
		sweepQC = (SFH_IsSweepQCPassed(numericalValues, textualValues, sweepNo, channelNumber, channelType) == 1) ? SF_OP_SELECT_IVSCCSWEEPQC_PASSED : SF_OP_SELECT_IVSCCSWEEPQC_FAILED
		if(!(filter.sweepQC & sweepQC))
			return 0
		endif
	endif

	if(filter.setQC != SF_OP_SELECT_IVSCCSETQC_IGNORE)
		setQC = (SFH_IsSetQCPassed(numericalValues, textualValues, sweepNo, channelNumber, channelType) == 1) ? SF_OP_SELECT_IVSCCSETQC_PASSED : SF_OP_SELECT_IVSCCSETQC_FAILED
		if(!(filter.setQC & setQC))
			return 0
		endif
	endif

	if(!IsNaN(filter.setCycleCount) && setCycleCount != filter.setCycleCount)
		return 0
	endif

	if(!IsNaN(filter.setSweepCount) && setSweepCount != filter.setSweepCount)
		return 0
	endif

	return 1
End

static Function SF_MapClampModeToSelectCM(variable clampMode)

	if(IsNaN(clampMode))
		return SF_OP_SELECT_CLAMPCODE_NONE
	endif

	switch(clampMode)
		case V_CLAMP_MODE:
			return SF_OP_SELECT_CLAMPCODE_VC
			break
		case I_CLAMP_MODE:
			return SF_OP_SELECT_CLAMPCODE_IC
			break
		case I_EQUAL_ZERO_MODE:
			return SF_OP_SELECT_CLAMPCODE_IZERO
			break
		default:
			FATAL_ERROR("Unknown clamp mode")
	endswitch
End

static Function/WAVE SF_SortSelectData(WAVE selectData)

	variable dimPosSweep, dimPosChannelType, dimPosChannelNumber

	if(DimSize(selectData, ROWS) >= 1)
		dimPosSweep         = FindDimLabel(selectData, COLS, "SWEEP")
		dimPosChannelType   = FindDimLabel(selectData, COLS, "CHANNELTYPE")
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

	formula    = NormalizeToEOL(formula, SF_CHAR_CR)
	endsWithCR = StringEndsWith(formula, SF_CHAR_CR)

	WAVE/T lines = ListToTextWave(formula, SF_CHAR_CR)
	lines[] = StringFromList(0, lines[p], SF_CHAR_COMMENT)
	lines[] = RemoveEndingRegExp(lines[p], "[[:space:]]+$")
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
	variable errState

	switch(ba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(ba.win)
			bsPanel   = BSP_GetPanel(mainPanel)

			if(!BSP_HasBoundDevice(bsPanel))
				DebugPrint("Unbound device in DataBrowser")
				break
			endif

			formula_nb = BSP_GetSFFormula(ba.win)
			formula    = GetNotebookText(formula_nb, mode = 2)

			NVAR jsonID = $GetSweepFormulaJSONid(SF_GetBrowserDF(mainPanel))
			SF_ClearSFOutputState()
			SF_DisplayOutputStateInGUI(bsPanel)

			try
				SF_CheckInputCode(formula, mainPanel)
			catch
#ifdef DEBUGGING_ENABLED
				SFP_SaveParserStateLog()
#endif // DEBUGGING_ENABLED
				JSON_Release(jsonID, ignoreErr = 1)
				jsonID = NaN
			endtry
			SF_DisplayOutputStateInGUI(bsPanel)

			json_nb = BSP_GetSFJSON(mainPanel)
			if(JSON_IsValid(jsonID))
				text = JSON_Dump(jsonID, indent = 2, ignoreErr = 1)
				text = NormalizeToEOL(text, "\r")
				ReplaceNotebookText(json_nb, text)
			else
				ReplaceNotebookText(json_nb, "")
			endif

			break
		default:
			break
	endswitch

	return 0
End

static Function SF_ClearSFOutputState()

	SVAR result = $GetSweepFormulaOutputMessage()
	result = ""
	NVAR severity = $GetSweepFormulaOutputSeverity()
	severity = SF_MSG_OK
End

Function SF_DisplayOutputStateInGUI(string databrowser)

	variable        severity
	string          error
	STRUCT RGBColor s

	string nb = BSP_GetSFOutputState(databrowser)

	severity = ROVar(GetSweepFormulaOutputSeverity())
	ASSERT(severity == SF_MSG_ERROR || severity == SF_MSG_OK || severity == SF_MSG_WARN, "Unknown severity for SF error")
	error = ROStr(GetSweepFormulaOutputMessage())

	ReplaceNotebookText(nb, error)
	[s] = SF_GetErrorColorsFromSeverity(severity)
	Notebook $nb, selection={startOfFile, endOfFile}, font="Lucida Console", textRGB=(s.red, s.green, s.blue)
	NotebookSelectionAtEnd(nb)
End

/// @brief Checks input code, sets globals for jsonId and error string
static Function SF_CheckInputCode(string code, string graph)

	variable i, numGraphs, jsonIDy, jsonIDx, subFormulaCnt
	string jsonPath, xFormula, yFormula, formulasRemain, subPath, yAndXFormula

	NVAR jsonID = $GetSweepFormulaJSONid(SF_GetBrowserDF(graph))
	JSON_Release(jsonID, ignoreErr = 1)
	jsonID = JSON_New()
	JSON_AddObjects(jsonID, "")

	code = SF_CheckVariableAssignments(code, jsonID)

	WAVE/T graphCode = SF_SplitCodeToGraphs(SF_PreprocessInput(code))

	numGraphs = DimSize(graphCode, ROWS)
	for(i = 0; i < numGraphs; i += 1)
		subFormulaCnt  = 0
		formulasRemain = graphCode[i]
		sprintf jsonPath, "/graph_%d", i
		JSON_AddObjects(jsonID, jsonPath)

		do
			SplitString/E=SF_SWEEPFORMULA_WITH_REGEXP formulasRemain, yAndXFormula, formulasRemain
			if(!V_flag)
				break
			endif

			[xFormula, yFormula] = SF_SplitGraphsToFormula(yAndXFormula)
			SFH_ASSERT(!IsEmpty(yFormula), "Could not determine y [vs x] formula pair.")

			sprintf subPath, "%s/pair_%d", jsonPath, subFormulaCnt
			JSON_AddTreeObject(jsonID, subPath)

			sprintf subPath, "%s/pair_%d/formula_y", jsonPath, subFormulaCnt
			jsonIDy = SFP_ParseFormulaToJSON(yFormula)
			JSON_AddJSON(jsonID, subPath, jsonIDy)
			JSON_Release(jsonIDy)

			if(!IsEmpty(xFormula))
				jsonIDx = SFP_ParseFormulaToJSON(xFormula)

				sprintf subPath, "%s/pair_%d/formula_x", jsonPath, subFormulaCnt
				JSON_AddJSON(jsonID, subPath, jsonIDx)
				JSON_Release(jsonIDx)
			endif

			subFormulaCnt += 1
		while(1)
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
	code       = GetNotebookText(formula_nb, mode = 2)

	return [code, SF_PreprocessInput(code)]
End

Function SF_button_sweepFormula_display(STRUCT WMButtonAction &ba) : ButtonControl

	string mainPanel, rawCode, bsPanel, preProcCode

	switch(ba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(ba.win)
			bsPanel   = BSP_GetPanel(mainPanel)

			[rawCode, preProcCode] = SF_GetCode(mainPanel)
			if(IsEmpty(preProcCode))
				break
			endif

			if(!BSP_HasBoundDevice(bsPanel))
				DebugPrint("Databrowser has unbound device")
				break
			endif

			SF_KillWorkingDF(mainPanel)
			SF_ClearSFOutputState()
			SF_DisplayOutputStateInGUI(bsPanel)

			// catch Abort from SFH_ASSERT
			try
				preProcCode = SF_ExecuteVariableAssignments(mainPanel, preProcCode)
				if(IsEmpty(preProcCode))
					break
				endif
				SF_FormulaPlotter(mainPanel, preProcCode)

				DFREF dfr      = SF_GetBrowserDF(mainPanel)
				SVAR  lastCode = $GetLastSweepFormulaCode(dfr)
				lastCode = preProcCode

				[WAVE/T keys, WAVE/T values] = SFH_CreateResultsWaveWithCode(mainPanel, rawCode)

				ED_AddEntriesToResults(values, keys, UNKNOWN_MODE)
			catch
#ifdef DEBUGGING_ENABLED
				SFP_SaveParserStateLog()
#endif // DEBUGGING_ENABLED
			endtry
			SF_DisplayOutputStateInGUI(bsPanel)

			break
		default:
			break
	endswitch

	return 0
End

Function SF_TabProc_Formula(STRUCT WMTabControlAction &tca) : TabControl

	string mainPanel, bsPanel, json_nb, text, helpNotebook
	variable jsonID

	switch(tca.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(tca.win)
			bsPanel   = BSP_GetPanel(mainPanel)
			if(tca.tab == 1)
				PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_check")
			elseif(tca.tab == 2)
				helpNotebook = BSP_GetSFHELP(mainPanel)
				BSP_UpdateHelpNotebook(helpNotebook)
			endif

			if(!BSP_HasBoundDevice(bsPanel))
				DebugPrint("Databrowser has unbound device")
				break
			endif

			break
		default:
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
		SFH_ASSERT(IsFinite(index), "ignored TP index is non-finite")
		SFH_ASSERT(index >= 0 && index < DimSize(epochs, ROWS), "ignored TP index is out of range")
		DeletePoints/M=(ROWS) index, 1, epochs
	endfor

	if(DimSize(epochs, ROWS) == 0)
		return $""
	endif

	return epochs
End

// tpss()
static Function/WAVE SF_OperationTPSS(variable jsonId, string jsonPath, string graph)

	variable numArgs, outType
	string opShort = SF_OP_TPSS

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs == 0, "tpss has no arguments")

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TPSS)

	return SFH_GetOutputForExecutor(output, graph, opShort)
End

// tpinst()
static Function/WAVE SF_OperationTPInst(variable jsonId, string jsonPath, string graph)

	variable numArgs, outType
	string opShort = SF_OP_TPINST

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs == 0, "tpinst has no arguments")

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TPINST)

	return SFH_GetOutputForExecutor(output, graph, opShort)
End

// tpbase()
static Function/WAVE SF_OperationTPBase(variable jsonId, string jsonPath, string graph)

	variable numArgs, outType
	string opShort = SF_OP_TPBASE

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs == 0, "tpbase has no arguments")

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TPBASE)

	return SFH_GetOutputForExecutor(output, graph, opShort)
End

// tpfit()
static Function/WAVE SF_OperationTPFit(variable jsonId, string jsonPath, string graph)

	variable numArgs, outType
	string func, retVal
	variable maxTrailLength
	string opShort = SF_OP_TPFIT

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs >= 2 && numArgs <= 3, "tpfit has two or three arguments")

	WAVE/T wFitType = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_TPFIT, 0, checkExist = 1)
	SFH_ASSERT(IsTextWave(wFitType), "TPFit function argument must be textual.")
	SFH_ASSERT(DimSize(wFitType, ROWS) == 1, "TPFit function argument must be a single string.")
	func = wFitType[0]
	SFH_ASSERT(!CmpStr(func, SF_OP_TPFIT_FUNC_EXP) || !CmpStr(func, SF_OP_TPFIT_FUNC_DEXP), "Fit function must be exp or doubleexp")

	WAVE/T wReturn = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_TPFIT, 1, checkExist = 1)
	SFH_ASSERT(IsTextWave(wReturn), "TPFit return what argument must be textual.")
	SFH_ASSERT(DimSize(wReturn, ROWS) == 1, "TPFit return what argument must be a single string.")
	retVal = wReturn[0]
	SFH_ASSERT(!CmpStr(retVal, SF_OP_TPFIT_RET_TAULARGE) || !CmpStr(retVal, SF_OP_TPFIT_RET_TAUSMALL) || !CmpStr(retVal, SF_OP_TPFIT_RET_AMP) || !CmpStr(retVal, SF_OP_TPFIT_RET_MINAMP) || !CmpStr(retVal, SF_OP_TPFIT_RET_FITQUALITY), "TP fit result must be tau, tausmall, amp, minabsamp, fitq")

	maxTrailLength = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_TPFIT, 2, defValue = 250)

	Make/FREE/T fitSettingsT = {func, retVal}
	SetDimLabel ROWS, 0, FITFUNCTION, fitSettingsT
	SetDimLabel ROWS, 1, RETURNWHAT, fitSettingsT
	Make/FREE/D fitSettings = {maxTrailLength}
	SetDimLabel ROWS, 0, MAXTRAILLENGTH, fitSettings

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 2)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TPFIT)

	output[0] = fitSettingsT
	output[1] = fitSettings

	return SFH_GetOutputForExecutor(output, graph, opShort)
End

// tp(string type[, array selectData[, array ignoreTPs]])
static Function/WAVE SF_OperationTP(variable jsonId, string jsonPath, string graph)

	variable numArgs, outType
	string dataType, allowedTypes

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs >= 1 || numArgs <= 3, "tp requires 1 to 3 arguments")

	if(numArgs == 3)
		WAVE ignoreTPs = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_TP, 2, checkExist = 1)
		SFH_ASSERT(WaveDims(ignoreTPs) == 1, "ignoreTPs must be one-dimensional.")
		SFH_ASSERT(IsNumericWave(ignoreTPs), "ignoreTPs parameter must be numeric")
	else
		WAVE/Z ignoreTPs
	endif

	WAVE/Z selectData = SFH_GetArgumentSelect(jsonID, jsonPath, graph, SF_OP_TP, 1)

	WAVE/WAVE wMode = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 0)
	dataType = JWN_GetStringFromWaveNote(wMode, SF_META_DATATYPE)

	allowedTypes = AddListItem(SF_DATATYPE_TPSS, "")
	allowedTypes = AddListItem(SF_DATATYPE_TPINST, allowedTypes)
	allowedTypes = AddListItem(SF_DATATYPE_TPBASE, allowedTypes)
	allowedTypes = AddListItem(SF_DATATYPE_TPFIT, allowedTypes)
	SFH_ASSERT(WhichListItem(dataType, allowedTypes) >= 0, "Unknown TP mode.")

	WAVE/Z/WAVE output = SF_OperationTPIterate(graph, wMode, selectData, ignoreTPs, SF_OP_TP)
	if(!WaveExists(output))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_TP, 0)
	endif

	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TP)
	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_TP, ""))

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_TP)
End

static Function SF_GetTPFitQuality(WAVE residuals, WAVE sweepData, variable beginTrail, variable endTrail)

	variable beginTrailIndex
	variable endTrailIndex

	beginTrailIndex = ScaleToIndex(sweepData, beginTrail, ROWS)
	endTrailIndex   = ScaleToIndex(sweepData, endTrail, ROWS)
	Multithread residuals = residuals[p]^2

	return sum(residuals, beginTrail, endTrail) / (endTrailIndex - beginTrailIndex)
End

static Function/WAVE SF_OperationTPIterate(string graph, WAVE/WAVE mode, WAVE/Z/WAVE selectDataArray, WAVE/Z ignoreTPs, string opShort)

	if(!WaveExists(selectDataArray))
		return $""
	endif

	WAVE/Z/WAVE result = $""

	for(WAVE/Z/WAVE selectDataComp : selectDataArray)

		if(!WaveExists(selectDataComp))
			continue
		endif

		WAVE/Z      selectData = selectDataComp[%SELECTION]
		WAVE/Z/WAVE sweepData  = SF_OperationTPImpl(graph, mode, selectData, ignoreTPs, opShort)
		if(!WaveExists(sweepData))
			continue
		endif

		if(!WaveExists(result))
			WAVE/WAVE result = sweepData
			continue
		endif

		Concatenate/FREE/WAVE/NP {sweepData}, result
	endfor

	return result
End

static Function/WAVE SF_OperationTPImpl(string graph, WAVE/WAVE mode, WAVE/Z selectDataPreFilter, WAVE/Z ignoreTPs, string opShort)

	variable i, j, numSelected, sweepNo, chanNr, chanType, dacChannelNr, settingsIndex, headstage, tpBaseLinePoints, index, err, maxTrailLength
	string unitKey, epShortName, baselineUnit, xAxisLabel, yAxisLabel, debugGraph, dataType
	string fitFunc, retWhat, epBaselineTrail, allowedReturns

	variable numTPs, beginTrail, endTrail, endTrailZero, endTrailIndex, beginTrailIndex, fitResult
	variable debugMode, mapIndex

	STRUCT TPAnalysisInput tpInput
	string epochTPRegExp = "^(U_)?TP[[:digit:]]*$"

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		debugMode = 1
	endif
#endif // DEBUGGING_ENABLED

	WAVE/Z selectData = SFH_FilterSelect(selectDataPreFilter, XOP_CHANNEL_TYPE_ADC)
	if(!WaveExists(selectData))
		return $""
	endif

	dataType = JWN_GetStringFromWaveNote(mode, SF_META_DATATYPE)
	if(!CmpStr(dataType, SF_DATATYPE_TPFIT))
		WAVE/T fitSettingsT = mode[0]
		fitFunc = fitSettingsT[%FITFUNCTION]
		retWhat = fitSettingsT[%RETURNWHAT]
		WAVE fitSettings = mode[1]
		maxTrailLength = fitSettings[%MAXTRAILLENGTH]

		allowedReturns = AddListItem(SF_OP_TPFIT_RET_TAULARGE, "")
		allowedReturns = AddListItem(SF_OP_TPFIT_RET_TAUSMALL, allowedReturns)
		allowedReturns = AddListItem(SF_OP_TPFIT_RET_AMP, allowedReturns)
		allowedReturns = AddListItem(SF_OP_TPFIT_RET_MINAMP, allowedReturns)
		allowedReturns = AddListItem(SF_OP_TPFIT_RET_FITQUALITY, allowedReturns)
		SFH_ASSERT(WhichListItem(retWhat, allowedReturns) >= 0, "Unknown return value requested.")
	endif

	numSelected = DimSize(selectData, ROWS)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numSelected)

	WAVE/Z settings
	for(i = 0; i < numSelected; i += 1)

		sweepNo = selectData[i][%SWEEP]
		if(!IsValidSweepNumber(sweepNo))
			continue
		endif
		chanNr   = selectData[i][%CHANNELNUMBER]
		chanType = selectData[i][%CHANNELTYPE]
		mapIndex = selectData[i][%SWEEPMAPINDEX]
		DFREF sweepDFR
		[WAVE numericalValues, WAVE textualValues, sweepDFR] = SFH_GetLabNoteBooksAndDFForSweep(graph, sweepNo, mapIndex)
		if(!WaveExists(numericalValues) || !WaveExists(textualValues))
			continue
		endif
		SFH_ASSERT(DataFolderExistsDFR(sweepDFR), "Could not determine sweepDFR")

		WAVE/WAVE singleSelect = SFH_GetSingleSelect(graph, opShort, sweepNo, chanType, chanNr, mapIndex)
		WAVE/WAVE sweepDataRef = SFH_GetSweepsForFormula(graph, singleSelect, SF_OP_TP)
		SFH_ASSERT(DimSize(sweepDataRef, ROWS) == 1, "Could not retrieve sweep data for " + num2istr(sweepNo))
		WAVE/Z sweepData = sweepDataRef[0]
		SFH_ASSERT(WaveExists(sweepData), "No sweep data for " + num2istr(sweepNo) + " found.")

		unitKey      = ""
		baselineUnit = ""
		if(chanType == XOP_CHANNEL_TYPE_DAC)
			unitKey = "DA unit"
		elseif(chanType == XOP_CHANNEL_TYPE_ADC)
			unitKey = "AD unit"
		endif
		if(!IsEmpty(unitKey))
			[WAVE settings, settingsIndex] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, unitKey, chanNr, chanType, DATA_ACQUISITION_MODE)
			SFH_ASSERT(WaveExists(settings), "Failed to retrieve channel unit from LBN")
			WAVE/T settingsT = settings
			baselineUnit = settingsT[settingsIndex]
		endif

		headstage = GetHeadstageForChannel(numericalValues, sweepNo, chanType, chanNr, DATA_ACQUISITION_MODE)
		SFH_ASSERT(IsAssociatedChannel(headstage), "Associated headstage must not be NaN")
		[WAVE settings, settingsIndex] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "DAC", chanNr, chanType, DATA_ACQUISITION_MODE)
		SFH_ASSERT(WaveExists(settings), "Failed to retrieve DAC channels from LBN")
		dacChannelNr = settings[headstage]
		SFH_ASSERT(IsFinite(dacChannelNr), "DAC channel number must be finite")

		WAVE/Z epochMatchesAll = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epochTPRegExp, sweepDFR = sweepDFR)

		// drop TPs which should be ignored
		// relies on ascending sorting of start times in epochMatches
		WAVE/Z/T epochMatches = SF_FilterEpochs(epochMatchesAll, ignoreTPs)

		if(!WaveExists(epochMatches))
			continue
		endif

		if(!CmpStr(dataType, SF_DATATYPE_TPFIT))

			if(debugMode)
				JWN_SetNumberInWaveNote(sweepData, SF_META_SWEEPNO, sweepNo)
				JWN_SetNumberInWaveNote(sweepData, SF_META_CHANNELTYPE, chanType)
				JWN_SetNumberInWaveNote(sweepData, SF_META_CHANNELNUMBER, chanNr)
				output[index] = sweepData
				index        += 1
			endif

			numTPs = DimSize(epochMatches, ROWS)
			Make/FREE/D/N=(numTPs) fitResults

#ifdef AUTOMATED_TESTING
			Make/FREE/D/N=(numTPs) beginTrails, endTrails
			beginTrails = NaN
			endTrails   = NaN
#endif // AUTOMATED_TESTING
			for(j = 0; j < numTPs; j += 1)

				epBaselineTrail = EP_GetShortName(epochMatches[j][EPOCH_COL_TAGS]) + "_B1"
				WAVE/Z/T epochTPBaselineTrail = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epBaselineTrail, sweepDFR = sweepDFR)
				SFH_ASSERT(WaveExists(epochTPBaselineTrail) && DimSize(epochTPBaselineTrail, ROWS) == 1, "No TP trailing baseline epoch found for TP epoch")
				WAVE/Z/T nextEpoch = EP_GetNextEpoch(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epBaselineTrail, 1)

				beginTrail   = str2numSafe(epochTPBaselineTrail[0][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
				endTrailZero = str2numSafe(epochTPBaselineTrail[0][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI
				if(WaveExists(nextEpoch) && EP_GetEpochAmplitude(nextEpoch[0][EPOCH_COL_TAGS]) == 0)
					endTrail = str2numSafe(nextEpoch[0][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI
				else
					endTrail = endTrailZero
				endif
				endTrail = min(endTrail, endTrailZero + maxTrailLength)
				SFH_ASSERT(endTrail > beginTrail, "maxTrailLength specified is before TP_B1 start")

#ifdef AUTOMATED_TESTING
				beginTrails[j] = beginTrail
				endTrails[j]   = endTrail
#endif // AUTOMATED_TESTING

				if(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
					Duplicate/FREE sweepData, residuals
				endif

				if(debugMode)
					Duplicate/FREE sweepData, wFitResult
					FastOp wFitResult = (NaN)
					Note/K wFitResult
				endif

				if(!CmpStr(fitFunc, SF_OP_TPFIT_FUNC_EXP))
					Make/FREE/D/N=3 coefWave

					if(debugMode)
						CurveFit/Q/K={beginTrail} exp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail)/D=wFitResult; err = getRTError(1)
						if(!err)
							EnsureLargeEnoughWave(output, indexShouldExist = index)
							output[index] = wFitResult
							index        += 1
							continue
						endif
					else
						fitResult = NaN
						if(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
							CurveFit/Q/K={beginTrail} exp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail)/R=residuals; err = getRTError(1)
							if(!err)
								fitResult = SF_GetTPFitQuality(residuals, sweepData, beginTrail, endTrail)
							endif
						else
							CurveFit/Q/K={beginTrail} exp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail); err = getRTError(1)
						endif
						if(!err)
							if(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAULARGE) || !CmpStr(retWhat, SF_OP_TPFIT_RET_TAUSMALL))
								fitResult = coefWave[2]
							elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_AMP) || !CmpStr(retWhat, SF_OP_TPFIT_RET_MINAMP))
								fitResult = coefWave[1]
							endif
						endif
					endif
				elseif(!CmpStr(fitFunc, SF_OP_TPFIT_FUNC_DEXP))
					Make/FREE/D/N=5 coefWave

					if(debugMode)
						CurveFit/Q/K={beginTrail} dblexp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail)/D=wFitResult; err = getRTError(1)
						if(!err)
							EnsureLargeEnoughWave(output, indexShouldExist = index)
							output[index] = wFitResult
							index        += 1
							continue
						endif
					else
						if(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
							CurveFit/Q/K={beginTrail} dblexp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail)/R=residuals; err = getRTError(1)
							if(!err)
								fitResult = SF_GetTPFitQuality(residuals, sweepData, beginTrail, endTrail)
							endif
						else
							CurveFit/Q/K={beginTrail} dblexp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail); err = getRTError(1)
						endif
						if(!err)
							if(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAULARGE))
								fitResult = max(coefWave[2], coefWave[4])
							elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAUSMALL))
								fitResult = min(coefWave[2], coefWave[4])
							elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_AMP))
								fitResult = (max(abs(coefWave[1]), abs(coefWave[3])) == abs(coefWave[1])) ? coefWave[1] : coefWave[3]
							elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_MINAMP))
								fitResult = (min(abs(coefWave[1]), abs(coefWave[3])) == abs(coefWave[1])) ? coefWave[1] : coefWave[3]
							endif
						endif
					endif
				endif
				fitResults[j] = fitResult
			endfor

			MakeWaveFree($"W_sigma")
			MakeWaveFree($"W_fitConstants")

#ifdef AUTOMATED_TESTING
			JWN_SetWaveInWaveNote(fitResults, "/begintrails", beginTrails)
			JWN_SetWaveInWaveNote(fitResults, "/endtrails", endTrails)
#endif // AUTOMATED_TESTING

			if(!debugMode)
				WAVE/D out = fitResults
				if(!CmpStr(retWhat, SF_OP_TPFIT_RET_AMP) || !CmpStr(retWhat, SF_OP_TPFIT_RET_MINAMP))
					SetScale d, 0, 0, WaveUnits(sweepData, -1), out
				elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAULARGE) || !CmpStr(retWhat, SF_OP_TPFIT_RET_TAUSMALL))
					SetScale d, 0, 0, WaveUnits(sweepData, ROWS), out
				elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
					SetScale d, 0, 0, "", out
				endif
			endif

		else
			// Use first TP as reference for pulse length and baseline
			epShortName = EP_GetShortName(epochMatches[0][EPOCH_COL_TAGS])
			WAVE/Z/T epochTPPulse = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epShortName + "_P", sweepDFR = sweepDFR)
			SFH_ASSERT(WaveExists(epochTPPulse) && DimSize(epochTPPulse, ROWS) == 1, "No TP Pulse epoch found for TP epoch")
			WAVE/Z/T epochTPBaseline = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epShortName + "_B0", sweepDFR = sweepDFR)
			SFH_ASSERT(WaveExists(epochTPBaseline) && DimSize(epochTPBaseline, ROWS) == 1, "No TP Baseline epoch found for TP epoch")
			tpBaseLinePoints = (str2num(epochTPBaseline[0][EPOCH_COL_ENDTIME]) - str2num(epochTPBaseline[0][EPOCH_COL_STARTTIME])) * ONE_TO_MILLI / DimDelta(sweepData, ROWS)

			// Assemble TP data
			WAVE tpInput.data = SF_AverageTPFromSweep(epochMatches, sweepData)
			tpInput.tpLengthPointsADC    = DimSize(tpInput.data, ROWS)
			tpInput.samplingIntervalADC  = DimDelta(tpInput.data, ROWS)
			tpInput.pulseLengthPointsADC = (str2num(epochTPPulse[0][EPOCH_COL_ENDTIME]) - str2num(epochTPPulse[0][EPOCH_COL_STARTTIME])) * ONE_TO_MILLI / DimDelta(sweepData, ROWS)
			tpInput.baselineFrac         = TP_CalculateBaselineFraction(tpInput.pulseLengthPointsADC, tpInput.pulseLengthPointsADC + 2 * tpBaseLinePoints)

			[WAVE settings, settingsIndex] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, CLAMPMODE_ENTRY_KEY, dacChannelNr, XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
			SFH_ASSERT(WaveExists(settings), "Failed to retrieve TP Clamp Mode from LBN")
			tpInput.clampMode = settings[settingsIndex]

			tpInput.clampAmp = NumberByKey("Amplitude", epochTPPulse[0][EPOCH_COL_TAGS], "=")
			SFH_ASSERT(IsFinite(tpInput.clampAmp), "Could not find amplitude entry in epoch tags")

			// values not required for calculation result
			tpInput.device        = graph
			tpInput.sendTPMessage = 0

			DFREF dfrTPAnalysis      = TP_PrepareAnalysisDF(graph, tpInput)
			DFREF dfrTPAnalysisInput = dfrTPAnalysis:input
			DFREF dfr                = TP_TSAnalysis(dfrTPAnalysisInput)
			WAVE  tpOutData          = dfr:tpData

			// handle waves sent out when TP_ANALYSIS_DEBUGGING is defined
			if(WaveExists(dfr:data) && WaveExists(dfr:colors))
				Duplicate/O dfr:data, root:data/WAVE=data
				Duplicate/O dfr:colors, root:colors/WAVE=colors

				debugGraph = "DebugTPRanges"
				if(!WindowExists(debugGraph))
					Display/N=$debugGraph/K=1
					AppendToGraph/W=$debugGraph data
					ModifyGraph/W=$debugGraph zColor(data)={colors, *, *, Rainbow, 1}
				endif
			endif

			strswitch(dataType)
				case SF_DATATYPE_TPSS:
					Make/FREE/D out = {tpOutData[%STEADYSTATERES]}
					SetScale d, 0, 0, "MΩ", out
					break
				case SF_DATATYPE_TPINST:
					Make/FREE/D out = {tpOutData[%INSTANTRES]}
					SetScale d, 0, 0, "MΩ", out
					break
				case SF_DATATYPE_TPBASE:
					Make/FREE/D out = {tpOutData[%BASELINE]}
					SetScale d, 0, 0, baselineUnit, out
					break
				default:
					SFH_FATAL_ERROR("tp: Unknown type.")
					break
			endswitch
		endif

		if(!debugMode)
			JWN_SetWaveInWaveNote(out, SF_META_XVALUES, {sweepNo})
			JWN_SetNumberInWaveNote(out, SF_META_SWEEPNO, sweepNo)
			JWN_SetNumberInWaveNote(out, SF_META_CHANNELTYPE, chanType)
			JWN_SetNumberInWaveNote(out, SF_META_CHANNELNUMBER, chanNr)

			output[index] = out
			index        += 1
		endif
	endfor
	if(!index)
		return $""
	endif
	Redimension/N=(index) output

	if(debugMode)
		return output
	endif

	strswitch(dataType)
		case SF_DATATYPE_TPSS:
			yAxisLabel = "steady state resistance"
			break
		case SF_DATATYPE_TPINST:
			yAxisLabel = "instantaneous resistance"
			break
		case SF_DATATYPE_TPBASE:
			yAxisLabel = "baseline level"
			break
		case SF_DATATYPE_TPFIT:
			if(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAULARGE) || !CmpStr(retWhat, SF_OP_TPFIT_RET_TAUSMALL))
				yAxisLabel = "tau"
			elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_AMP) || !CmpStr(retWhat, SF_OP_TPFIT_RET_MINAMP))
				yAxisLabel = ""
			elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
				yAxisLabel = "fitQuality"
			endif
			break
		default:
			SFH_FATAL_ERROR("tp: Unknown mode.")
			break
	endswitch

	xAxisLabel = "Sweeps"

	JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, xAxisLabel)
	JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, yAxisLabel)

	return output
End

// epochs(string shortName[, array selectData, [string type]])
// returns 2xN waves for range and 1xN otherwise, where N is the number of epochs
static Function/WAVE SF_OperationEpochs(variable jsonId, string jsonPath, string graph)

	variable numArgs, epType

	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)
	SFH_ASSERT(numArgs >= 1 && numArgs <= 3, "epochs requires at least 1 and at most 3 arguments")

	if(numArgs == 3)
		WAVE/T epochType = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_EPOCHS, 2, checkExist = 1)
		SFH_ASSERT(DimSize(epochType, ROWS) == 1, "Epoch type must be a single value.")
		SFH_ASSERT(IsTextWave(epochType), "Epoch type argument must be textual")
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

		SFH_ASSERT(epType != EPOCHS_TYPE_INVALID, "Epoch type must be either " + SF_OP_EPOCHS_TYPE_RANGE + ", " + SF_OP_EPOCHS_TYPE_NAME + " or " + SF_OP_EPOCHS_TYPE_TREELEVEL)
	else
		epType = EPOCHS_TYPE_RANGE
	endif

	WAVE/Z/WAVE selectData      = $""
	WAVE/Z/WAVE selectDataArray = SFH_GetArgumentSelect(jsonID, jsonPath, graph, SF_OP_EPOCHS, 1)
	if(WaveExists(selectDataArray))
		SFH_ASSERT(DimSize(selectDataArray, ROWS) == 1, "Expected a single select specification")
		WAVE/Z/WAVE selectDataComp = selectDataArray[0]
		if(WaveExists(selectDataComp))
			WAVE/Z selectData = selectDataComp[%SELECTION]
		endif
	endif

	WAVE/T epochPatterns = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_EPOCHS, 0, checkExist = 1)
	SFH_ASSERT(IsTextWave(epochPatterns), "Epoch pattern argument must be textual")

	WAVE/WAVE output = SF_OperationEpochsImpl(graph, epochPatterns, selectData, epType, SF_OP_EPOCHS)

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_EPOCHS)
End

static Function/WAVE SF_OperationEpochsImpl(string graph, WAVE/T epochPatterns, WAVE/Z selectData, variable epType, string opShort)

	variable i, j, numSelected, sweepNo, chanNr, chanType, index, numEpochs, epIndex, settingsIndex, numPatterns, numEntries
	variable hasValidData, colorGroup
	string epName, epShortName, epEntry, yAxisLabel, epAxisName

	ASSERT(WindowExists(graph), "graph window does not exist")

	if(!WaveExists(selectData))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_EPOCHS)
		return output
	endif

	numSelected = DimSize(selectData, ROWS)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numSelected)

	epAxisName = TextWaveToList(epochPatterns, "/")
	if(epType == EPOCHS_TYPE_NAME)
		yAxisLabel = "epoch " + epAxisName + " name"
	elseif(epType == EPOCHS_TYPE_TREELEVEL)
		yAxisLabel = "epoch " + epAxisName + " tree level"
	else
		yAxisLabel = "epoch " + epAxisName + " range"
	endif

	numPatterns = DimSize(epochPatterns, ROWS)
	for(i = 0; i < numSelected; i += 1)

		sweepNo = selectData[i][%SWEEP]
		if(!IsValidSweepNumber(sweepNo))
			continue
		endif
		chanNr   = selectData[i][%CHANNELNUMBER]
		chanType = selectData[i][%CHANNELTYPE]

		DFREF sweepDFR
		[WAVE numericalValues, WAVE textualValues, sweepDFR] = SFH_GetLabNoteBooksAndDFForSweep(graph, sweepNo, selectData[i][%SWEEPMAPINDEX])
		if(!WaveExists(numericalValues) || !WaveExists(textualValues))
			continue
		endif
		SFH_ASSERT(DataFolderExistsDFR(sweepDFR), "Could not determine sweepDFR")

		WAVE/Z/T epochInfo = EP_FetchEpochs(numericalValues, textualValues, sweepNo, sweepDFR, chanNr, chanType)
		if(!WaveExists(epochInfo))
			continue
		endif

		WAVE/T epNames   = SFH_GetEpochNamesFromInfo(epochInfo)
		WAVE/Z epIndices = SFH_GetEpochIndicesByWildcardPatterns(epNames, epochPatterns)
		if(!WaveExists(epIndices))
			continue
		endif

		numEntries = DimSize(epIndices, ROWS)
		for(j = 0; j < numEntries; j += 1)
			epIndex = epIndices[j]
			if(epType == EPOCHS_TYPE_NAME)
				Make/FREE/T wt = {epNames[epIndex]}
				WAVE out = wt
			elseif(epType == EPOCHS_TYPE_TREELEVEL)
				Make/FREE/D wv = {str2num(epochInfo[epIndex][EPOCH_COL_TREELEVEL])}
				WAVE out = wv
			else
				Make/FREE/D wv = {str2num(epochInfo[epIndex][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI, str2num(epochInfo[epIndex][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI}
				WAVE out = wv
			endif

			if(!WaveExists(output[i]))
				output[i] = out
			else
				WAVE target = output[i]
				Concatenate {out}, target
			endif
		endfor

		JWN_SetNumberInWaveNote(output[i], SF_META_SWEEPNO, sweepNo)
		JWN_SetNumberInWaveNote(output[i], SF_META_CHANNELTYPE, chanType)
		JWN_SetNumberInWaveNote(output[i], SF_META_CHANNELNUMBER, chanNr)
		JWN_SetWaveInWaveNote(output[i], SF_META_XVALUES, {sweepNo})

		colorGroup = GetUniqueInteger()
		JWN_SetNumberInWaveNote(output[i], SF_META_COLOR_GROUP, colorGroup)

		hasValidData = 1
	endfor

	if(!hasValidData)
		Redimension/N=(0) output
	endif

	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_EPOCHS)
	JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, "Sweeps")
	JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, yAxisLabel)

	SFH_AddOpToOpStack(output, "", SF_OP_EPOCHS)

	return output
End

static Function SF_AssertOnMismatchedWaves(WAVE data0, WAVE data1, string opShort)

	string msg, size0Str, size1Str
	variable ret

	ret = EqualWaves(data0, data1, EQWAVES_DIMSIZE)

	if(ret)
		return NaN
	endif

	WAVE size0 = GetWaveDimensions(data0)
	WAVE size1 = GetWaveDimensions(data1)

	size0Str = NumericWaveToList(size0, ", ", trailSep = 0)
	size1Str = NumericWaveToList(size1, ", ", trailSep = 0)
	sprintf msg, "%s: wave size mismatch [%s] vs [%s]", opShort, size0Str, size1Str

	SFH_ASSERT(ret, msg)
End

static Function/WAVE SF_OperationMinus(variable jsonId, string jsonPath, string graph)

	WAVE output = SF_IndexOverDataSetsForPrimitiveOperation(jsonId, jsonpath, graph, SF_OPSHORT_MINUS)

	return SFH_GetOutputForExecutor(output, graph, SF_OPSHORT_MINUS)
End

static Function/WAVE SF_OperationMinusImplDataSets(WAVE/Z data0, WAVE/Z data1)

	variable minusConst

	if(!WaveExists(data0) || !WaveExists(data1))
		return $""
	endif
	SFH_ASSERT(IsNumericWave(data0) && IsNumericWave(data1), "Operand for - must be numeric.")

	if(numpnts(data1) == 1)
		minusConst = data1[0]
		MatrixOp/FREE result = data0 - minusConst
		CopyScales data0, result
		return result
	endif
	if(numpnts(data0) == 1)
		minusConst = data0[0]
		MatrixOp/FREE result = minusConst - data1
		CopyScales data1, result
		return result
	endif
	SF_AssertOnMismatchedWaves(data0, data1, SF_OPSHORT_MINUS)

	MatrixOp/FREE result = data0 - data1
	CopyScales data0, result
	return result
End

static Function/WAVE SF_OperationPlus(variable jsonId, string jsonPath, string graph)

	WAVE output = SF_IndexOverDataSetsForPrimitiveOperation(jsonId, jsonpath, graph, SF_OPSHORT_PLUS)

	return SFH_GetOutputForExecutor(output, graph, SF_OPSHORT_PLUS)
End

static Function/WAVE SF_OperationPlusImplDataSets(WAVE/Z data0, WAVE/Z data1)

	variable addConst

	if(!WaveExists(data0) || !WaveExists(data1))
		return $""
	endif
	SFH_ASSERT(IsNumericWave(data0) && IsNumericWave(data1), "Operand for + must be numeric.")

	if(numpnts(data1) == 1)
		addConst = data1[0]
		MatrixOp/FREE result = data0 + addConst
		CopyScales data0, result
		return result
	endif
	if(numpnts(data0) == 1)
		addConst = data0[0]
		MatrixOp/FREE result = addConst + data1
		CopyScales data1, result
		return result
	endif
	SF_AssertOnMismatchedWaves(data0, data1, SF_OPSHORT_PLUS)

	MatrixOp/FREE result = data0 + data1
	CopyScales data0, result
	return result
End

static Function/WAVE SF_IndexOverDataSetsForPrimitiveOperation(variable jsonId, string jsonPath, string graph, string opShort)

	variable numArgs, dataSetNum0, dataSetNum1
	string errMsg, type1, type2, resultType

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	ASSERT(numArgs == 2, "Number of arguments must be 2 for " + opShort)

	WAVE/WAVE arg0 = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	WAVE/WAVE arg1 = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 1)
	dataSetNum0 = DimSize(arg0, ROWS)
	dataSetNum1 = DimSize(arg1, ROWS)
	SFH_ASSERT(dataSetNum0 > 0 && dataSetNum1 > 0, "No input data for " + opShort)
	if(dataSetNum0 == dataSetNum1)
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, dataSetNum0)
		WAVE/WAVE input  = arg0
		strswitch(opShort)
			case SF_OPSHORT_DIV:
				output[] = SF_OperationDivImplDataSets(arg0[p], arg1[p])
				break
			case SF_OPSHORT_PLUS:
				output[] = SF_OperationPlusImplDataSets(arg0[p], arg1[p])
				break
			case SF_OPSHORT_MINUS:
				output[] = SF_OperationMinusImplDataSets(arg0[p], arg1[p])
				break
			case SF_OPSHORT_MULT:
				output[] = SF_OperationMultImplDataSets(arg0[p], arg1[p])
				break
			default:
				FATAL_ERROR("Unsupported primitive operation")
		endswitch
	elseif(dataSetNum1 == 1)
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, dataSetNum0)
		WAVE/WAVE input  = arg0
		strswitch(opShort)
			case SF_OPSHORT_DIV:
				output[] = SF_OperationDivImplDataSets(arg0[p], arg1[0])
				break
			case SF_OPSHORT_PLUS:
				output[] = SF_OperationPlusImplDataSets(arg0[p], arg1[0])
				break
			case SF_OPSHORT_MINUS:
				output[] = SF_OperationMinusImplDataSets(arg0[p], arg1[0])
				break
			case SF_OPSHORT_MULT:
				output[] = SF_OperationMultImplDataSets(arg0[p], arg1[0])
				break
			default:
				FATAL_ERROR("Unsupported primitive operation")
		endswitch
	elseif(dataSetNum0 == 1)
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, dataSetNum1)
		WAVE/WAVE input  = arg1
		strswitch(opShort)
			case SF_OPSHORT_DIV:
				output[] = SF_OperationDivImplDataSets(arg0[0], arg1[p])
				break
			case SF_OPSHORT_PLUS:
				output[] = SF_OperationPlusImplDataSets(arg0[0], arg1[p])
				break
			case SF_OPSHORT_MINUS:
				output[] = SF_OperationMinusImplDataSets(arg0[0], arg1[p])
				break
			case SF_OPSHORT_MULT:
				output[] = SF_OperationMultImplDataSets(arg0[0], arg1[p])
				break
			default:
				FATAL_ERROR("Unsupported primitive operation")
		endswitch
	else
		sprintf errMsg, "Can not apply %s on mixed number of datasets.", opShort
		SFH_FATAL_ERROR(errMsg)
	endif

	type1 = JWN_GetStringFromWaveNote(arg0, SF_META_DATATYPE)
	type2 = JWN_GetStringFromWaveNote(arg1, SF_META_DATATYPE)
	if(!CmpStr(type1, type2))
		if(!CmpStr(opShort, SF_OPSHORT_PLUS) || !CmpStr(opShort, SF_OPSHORT_MINUS))
			resultType = type1
		else
			resultType = ""
		endif
	elseif(!IsEmpty(type1) && IsEmpty(type2))
		resultType = type1
	elseif(IsEmpty(type1) && !IsEmpty(type2))
		resultType = type2
	else
		// either both empty or of different type
		resultType = ""
	endif

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, opShort, resultType)

	SFH_CleanUpInput(arg0)
	SFH_CleanUpInput(arg1)

	return output
End

static Function/WAVE SF_OperationDiv(variable jsonId, string jsonPath, string graph)

	WAVE output = SF_IndexOverDataSetsForPrimitiveOperation(jsonId, jsonpath, graph, SF_OPSHORT_DIV)

	return SFH_GetOutputForExecutor(output, graph, SF_OPSHORT_DIV)
End

static Function/WAVE SF_OperationDivImplDataSets(WAVE/Z data0, WAVE/Z data1)

	variable divConst

	if(!WaveExists(data0) || !WaveExists(data1))
		return $""
	endif
	SFH_ASSERT(IsNumericWave(data0) && IsNumericWave(data1), "Operand for / must be numeric.")

	if(numpnts(data1) == 1)
		divConst = data1[0]
		MatrixOp/FREE result = data0 / divConst
		CopyScales data0, result
		return result
	endif
	if(numpnts(data0) == 1)
		divConst = data0[0]
		MatrixOp/FREE result = divConst / data1
		CopyScales data1, result
		return result
	endif
	SF_AssertOnMismatchedWaves(data0, data1, SF_OPSHORT_DIV)

	MatrixOp/FREE result = data0 / data1
	CopyScales data0, result
	return result
End

static Function/WAVE SF_OperationMult(variable jsonId, string jsonPath, string graph)

	WAVE output = SF_IndexOverDataSetsForPrimitiveOperation(jsonId, jsonpath, graph, SF_OPSHORT_MULT)

	return SFH_GetOutputForExecutor(output, graph, SF_OPSHORT_MULT)
End

static Function/WAVE SF_OperationMultImplDataSets(WAVE/Z data0, WAVE/Z data1)

	variable multConst

	if(!WaveExists(data0) || !WaveExists(data1))
		return $""
	endif
	SFH_ASSERT(IsNumericWave(data0) && IsNumericWave(data1), "Operand for * must be numeric.")

	if(numpnts(data1) == 1)
		multConst = data1[0]
		MatrixOp/FREE result = data0 * multConst
		CopyScales data0, result
		return result
	endif
	if(numpnts(data0) == 1)
		multConst = data0[0]
		MatrixOp/FREE result = multConst * data1
		CopyScales data1, result
		return result
	endif
	SF_AssertOnMismatchedWaves(data0, data1, SF_OPSHORT_MULT)

	MatrixOp/FREE result = data0 * data1
	CopyScales data0, result
	return result
End

/// range (start[, stop[, step]])
static Function/WAVE SF_OperationRange(variable jsonId, string jsonPath, string graph)

	variable start, stop, step, stopDefault

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_RANGE, 1, maxArgs = 3)

	start = SFH_GetArgumentAsNumeric(jsonId, jsonpath, graph, SF_OP_RANGE, 0)
	stop  = SFH_GetArgumentAsNumeric(jsonId, jsonpath, graph, SF_OP_RANGE, 1, defValue = NaN)
	step  = SFH_GetArgumentAsNumeric(jsonId, jsonpath, graph, SF_OP_RANGE, 2, defValue = 1)

	if(IsNaN(stop))
		stop        = 0
		stopDefault = 1
	endif

	Make/FREE/D/N=(ceil(abs((start - stop) / step))) range

	if(stopDefault)
		MultiThread range[] = p * step
	else
		MultiThread range[] = start + p * step
	endif

	return SFH_GetOutputForExecutorSingle(range, graph, SF_OP_RANGE, dataType = SF_DATATYPE_RANGE)
End

/// concat(array0, array1, array2, ...)
static Function/WAVE SF_OperationConcat(variable jsonId, string jsonPath, string graph)

	variable numArgs, i, err, majorType, sliceMajorType
	variable constantDataType
	string refDataType, dataType, wvNote, errMsg

	numArgs = SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_CONCAT, 1)

	WAVE result = SFH_GetArgumentAsWave(jsonId, jsonpath, graph, SF_OP_CONCAT, 0, copy = 1, singleResult = 1, wvNote = wvNote)
	majorType = WaveType(result, 1)

	refDataType      = JWN_GetStringFromNote(wvNote, SF_META_DATATYPE)
	dataType         = refDataType
	constantDataType = !IsEmpty(refDataType)
	Note/K result

	AssertOnAndClearRTError()
	for(i = 1; i < numArgs; i += 1)
		WAVE slice = SFH_GetArgumentAsWave(jsonId, jsonpath, graph, SF_OP_CONCAT, i, singleResult = 1, wvNote = wvNote)
		sliceMajorType = WaveType(slice, 1)

		if(majorType != sliceMajorType)
			sprintf errMsg, "Concatenate failed as the wave types of the first argument and #%d don't match: %s vs %s", i, WaveTypeToStringSelectorOne(majorType), WaveTypeToStringSelectorOne(sliceMajorType)
			SFH_FATAL_ERROR(errMsg)
		endif

		dataType         = JWN_GetStringFromNote(wvNote, SF_META_DATATYPE)
		constantDataType = constantDataType && !CmpStr(refDataType, dataType)

		Concatenate/FREE/NP {slice}, result; errMsg = GetRTErrMessage(); err = GetRTError(1)
		SFH_ASSERT(!err, "Error concatenating waves: " + errMsg)
	endfor

	dataType = SelectString(constantDataType, SF_DATATYPE_CONCAT, dataType)
	return SFH_GetOutputForExecutorSingle(result, graph, SF_OP_CONCAT, discardOpStack = 1, dataType = dataType)
End

static Function/WAVE SF_OperationMin(variable jsonId, string jsonPath, string graph)

	WAVE/WAVE input  = SF_GetNumericVarArgs(jsonId, jsonPath, graph, SF_OP_MIN)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_MIN, DimSize(input, ROWS))

	output[] = SF_OperationMinImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_MIN, SF_DATATYPE_MIN)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_MIN, clear = input)
End

static Function/WAVE SF_OperationMinImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "min requires numeric data as input")
	SFH_ASSERT(WaveDims(input) <= 2, "min accepts only upto 2d data")
	SFH_ASSERT(DimSize(input, ROWS) > 0, "min requires at least one data point")
	MatrixOP/FREE out = minCols(input)^t
	CopyScales input, out
	SetScale/P x, DimOffset(out, ROWS), DimDelta(out, ROWS), "", out

	SF_FormulaWaveScaleTransfer(input, out, COLS, ROWS)

	return out
End

static Function/WAVE SF_OperationMax(variable jsonId, string jsonPath, string graph)

	WAVE/WAVE input  = SF_GetNumericVarArgs(jsonId, jsonPath, graph, SF_OP_MAX)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_MAX, DimSize(input, ROWS))

	output[] = SF_OperationMaxImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_MAX, SF_DATATYPE_MAX)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_MAX, clear = input)
End

static Function/WAVE SF_OperationMaxImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "max requires numeric data as input")
	SFH_ASSERT(WaveDims(input) <= 2, "max accepts only upto 2d data")
	SFH_ASSERT(DimSize(input, ROWS) > 0, "max requires at least one data point")
	MatrixOP/FREE out = maxCols(input)^t
	CopyScales input, out
	SetScale/P x, DimOffset(out, ROWS), DimDelta(out, ROWS), "", out
	SF_FormulaWaveScaleTransfer(input, out, COLS, ROWS)

	return out
End

static Function/WAVE SF_OperationAvg(variable jsonId, string jsonPath, string graph)

	variable numArgs
	string   mode
	string opShort = SF_OP_AVG

	numArgs = SFH_CheckArgumentCount(jsonID, jsonPath, opShort, 1, maxArgs = 2)

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 0)
	mode = SFH_GetArgumentAsText(jsonId, jsonPath, graph, opShort, 1, defValue = SF_OP_AVG_INSWEEPS, allowedValues = {SF_OP_AVG_INSWEEPS, SF_OP_AVG_OVERSWEEPS})

	strswitch(mode)
		case SF_OP_AVG_INSWEEPS:
			WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, DimSize(input, ROWS))
			output[] = SF_OperationAvgImplIn(input[p])
			SFH_TransferFormulaDataWaveNoteAndMeta(input, output, opShort, SF_DATATYPE_AVG)
			return SFH_GetOutputForExecutor(output, graph, opShort, clear = input)

		case SF_OP_AVG_OVERSWEEPS:
			return SF_OperationAvgImplOver(input, graph, opShort)

		default:
			FATAL_ERROR("Unknown avg operation mode")
	endswitch

End

static Function/WAVE SF_OperationAvgImplOver(WAVE/WAVE input, string graph, string opShort)

	variable        idx
	STRUCT RGBColor s

	Duplicate/FREE/WAVE input, avgSet

	for(data : input)
		if(WaveExists(data))
			SFH_ASSERT(IsNumericWave(data), "avg requires numeric data as input")
			SFH_ASSERT(DimSize(data, ROWS) > 0, "avg requires at least one data point")
			avgSet[idx] = data
			idx        += 1
		endif
	endfor
	if(!idx)
		return SFH_GetOutputForExecutorSingle($"", graph, opShort, discardOpStack = 1)
	endif
	Redimension/N=(idx) avgSet

	WAVE/WAVE avg     = MIES_fWaveAverage(avgSet, 1, IGOR_TYPE_64BIT_FLOAT)
	WAVE      avgData = avg[0]

	[s] = GetTraceColorForAverage()
	Make/FREE/W/U traceColor = {s.red, s.green, s.blue}
	JWN_SetWaveInWaveNote(avgData, SF_META_TRACECOLOR, traceColor)
	JWN_SetNumberInWaveNote(avgData, SF_META_TRACETOFRONT, 1)
	JWN_SetNumberInWaveNote(avgData, SF_META_LINESTYLE, 0)

	return SFH_GetOutputForExecutorSingle(avgData, graph, opShort, discardOpStack = 1)
End

// averages each column, 1d waves are treated like 1 column (n,1)
static Function/WAVE SF_OperationAvgImplIn(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "avg requires numeric data as input")
	SFH_ASSERT(WaveDims(input) <= 2, "avg accepts only upto 2d data")
	SFH_ASSERT(DimSize(input, ROWS) > 0, "avg requires at least one data point")
	MatrixOP/FREE out = averageCols(input)^t
	CopyScales input, out
	SetScale/P x, DimOffset(out, ROWS), DimDelta(out, ROWS), "", out
	SF_FormulaWaveScaleTransfer(input, out, COLS, ROWS)

	return out
End

static Function/WAVE SF_OperationRMS(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "rms requires at least one argument")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_RMS)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_RMS, DimSize(input, ROWS))

	output[] = SF_OperationRMSImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_RMS, SF_DATATYPE_RMS)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_RMS, clear = input)
End

static Function/WAVE SF_OperationRMSImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "rms requires numeric data as input")
	SFH_ASSERT(WaveDims(input) <= 2, "rms accepts only upto 2d data")
	SFH_ASSERT(DimSize(input, ROWS) > 0, "rms requires at least one data point")
	MatrixOP/FREE out = sqrt(averageCols(magsqr(input)))^t
	SF_FormulaWaveScaleTransfer(input, out, COLS, ROWS)

	return out
End

static Function/WAVE SF_OperationVariance(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "variance requires at least one argument")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_VARIANCE)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_VARIANCE, DimSize(input, ROWS))

	output[] = SF_OperationVarianceImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_VARIANCE, SF_DATATYPE_VARIANCE)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_VARIANCE, clear = input)
End

static Function/WAVE SF_OperationVarianceImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "variance requires numeric data as input")
	SFH_ASSERT(WaveDims(input) <= 2, "variance accepts only upto 2d data")
	SFH_ASSERT(DimSize(input, ROWS) > 0, "variance requires at least one data point")
	MatrixOP/FREE out = (sumCols(magSqr(input - rowRepeat(averageCols(input), numRows(input)))) / (numRows(input) - 1))^t
	SF_FormulaWaveScaleTransfer(input, out, COLS, ROWS)

	return out
End

static Function/WAVE SF_OperationStdev(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "stdev requires at least one argument")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_STDEV)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_STDEV, DimSize(input, ROWS))

	output[] = SF_OperationStdevImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_STDEV, SF_DATATYPE_STDEV)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_STDEV, clear = input)
End

static Function/WAVE SF_OperationStdevImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "stdev requires numeric data as input")
	SFH_ASSERT(WaveDims(input) <= 2, "stdev accepts only upto 2d data")
	SFH_ASSERT(DimSize(input, ROWS) > 0, "stdev requires at least one data point")
	MatrixOP/FREE out = (sqrt(sumCols(powR(input - rowRepeat(averageCols(input), numRows(input)), 2)) / (numRows(input) - 1)))^t
	SF_FormulaWaveScaleTransfer(input, out, COLS, ROWS)

	return out
End

static Function/WAVE SF_OperationDerivative(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_DERIVATIVE)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_DERIVATIVE, DimSize(input, ROWS))

	output[] = SF_OperationDerivativeImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_DERIVATIVE, SF_DATATYPE_DERIVATIVE)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_DERIVATIVE, clear = input)
End

static Function/WAVE SF_OperationDerivativeImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "derivative requires numeric input data.")
	SFH_ASSERT(DimSize(input, ROWS) > 1, "Can not differentiate single point waves")
	WAVE out = NewFreeWave(IGOR_TYPE_64BIT_FLOAT, 0)
	Differentiate/DIM=(ROWS) input/D=out
	CopyScales input, out
	SetScale/P x, DimOffset(out, ROWS), DimDelta(out, ROWS), "d/dx", out

	return out
End

static Function/WAVE SF_OperationIntegrate(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_INTEGRATE)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_INTEGRATE, DimSize(input, ROWS))

	output[] = SF_OperationIntegrateImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_INTEGRATE, SF_DATATYPE_INTEGRATE)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_INTEGRATE, clear = input)
End

static Function/WAVE SF_OperationIntegrateImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "integrate requires numeric input data.")
	SFH_ASSERT(DimSize(input, ROWS) > 0, "integrate input must have at least one data point")
	WAVE out = NewFreeWave(IGOR_TYPE_64BIT_FLOAT, 0)
	Integrate/METH=1/DIM=(ROWS) input/D=out
	CopyScales input, out
	SetScale/P x, DimOffset(out, ROWS), DimDelta(out, ROWS), "dx", out

	return out
End

static Function/WAVE SF_OperationArea(variable jsonId, string jsonPath, string graph)

	variable zero, numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs >= 1, "area requires at least one argument.")
	SFH_ASSERT(numArgs <= 2, "area requires at most two arguments.")

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 0)

	zero = !!SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_AREA, 1, defValue = 1)

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_AREA, DimSize(input, ROWS))

	output[] = SF_OperationAreaImpl(input[p], zero)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_AREA, SF_DATATYPE_AREA)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_AREA, clear = input)
End

static Function/WAVE SF_OperationAreaImpl(WAVE/Z input, variable zero)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "area requires numeric input data.")
	if(zero)
		SFH_ASSERT(DimSize(input, ROWS) >= 3, "Requires at least three points of data.")
		WAVE out_differentiate = NewFreeWave(IGOR_TYPE_64BIT_FLOAT, 0)
		Differentiate/DIM=(ROWS)/EP=1 input/D=out_differentiate
		Integrate/DIM=(ROWS) out_differentiate
		WAVE input = out_differentiate
	endif
	SFH_ASSERT(DimSize(input, ROWS) >= 1, "integrate requires at least one data point.")

	WAVE out_integrate = NewFreeWave(IGOR_TYPE_64BIT_FLOAT, 0)
	Integrate/METH=1/DIM=(ROWS) input/D=out_integrate
	Make/FREE/N=(max(1, DimSize(out_integrate, COLS)), DimSize(out_integrate, LAYERS)) out
	Multithread out = out_integrate[DimSize(input, ROWS) - 1][p][q]

	return out
End

/// `butterworth(data, lowPassCutoff, highPassCutoff, order)`
static Function/WAVE SF_OperationButterworth(variable jsonId, string jsonPath, string graph)

	variable lowPassCutoff, highPassCutoff, order

	SFH_CheckArgumentCount(jsonID, jsonPath, SF_OP_BUTTERWORTH, 4, maxArgs = 4)

	WAVE/WAVE input = SFH_GetArgumentAsWave(jsonID, jsonPath, graph, SF_OP_BUTTERWORTH, 0, copy = 1)
	lowPassCutoff  = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_BUTTERWORTH, 1)
	highPassCutoff = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_BUTTERWORTH, 2)
	order          = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_BUTTERWORTH, 3)

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_BUTTERWORTH, DimSize(input, ROWS))

	output[] = SF_OperationButterworthImpl(input[p], lowPassCutoff, highPassCutoff, order)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_BUTTERWORTH, SF_DATATYPE_BUTTERWORTH)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_BUTTERWORTH, clear = input)
End

static Function/WAVE SF_OperationButterworthImpl(WAVE/Z input, variable lowPassCutoff, variable highPassCutoff, variable order)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "butterworth requires numeric input data.")
	FilterIIR/HI=(highPassCutoff / WAVEBUILDER_MIN_SAMPINT_HZ)/LO=(lowPassCutoff / WAVEBUILDER_MIN_SAMPINT_HZ)/ORD=(order)/DIM=(ROWS) input
	SFH_ASSERT(V_flag == 0, "FilterIIR returned error")

	return input
End

static Function/WAVE SF_OperationXValues(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "xvalues requires at least one argument.")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_XVALUES)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_XVALUES, DimSize(input, ROWS))

	output[] = SF_OperationXValuesImpl(input[p])

	return SFH_GetOutputForExecutor(output, graph, SF_OP_XVALUES, clear = input)
End

static Function/WAVE SF_OperationXValuesImpl(WAVE/Z input)

	variable offset, delta

	if(!WaveExists(input))
		return $""
	endif

	Make/FREE/D/N=(DimSize(input, ROWS), DimSize(input, COLS), DimSize(input, LAYERS), DimSize(input, CHUNKS)) output
	offset = DimOffset(input, ROWS)
	delta  = DimDelta(input, ROWS)
	Multithread output = offset + p * delta

	return output
End

static Function/WAVE SF_OperationText(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "text requires at least one argument.")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_TEXT)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_TEXT, DimSize(input, ROWS))

	output[] = SF_OperationTextImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_TEXT, JWN_GetStringFromWaveNote(input, SF_META_DATATYPE))

	return SFH_GetOutputForExecutor(output, graph, SF_OP_TEXT, clear = input)
End

static Function/WAVE SF_OperationTextImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "text requires numeric input data.")
	Make/FREE/T/N=(DimSize(input, ROWS), DimSize(input, COLS), DimSize(input, LAYERS), DimSize(input, CHUNKS)) output
	Multithread output = num2strHighPrec(input[p][q][r][s], precision = 7)
	CopyScales input, output

	return output
End

/// `setscale(data, dim, [dimOffset, [dimDelta[, unit]]])`
static Function/WAVE SF_OperationSetScale(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs < 6, "Maximum number of arguments exceeded.")
	SFH_ASSERT(numArgs > 1, "At least two arguments.")
	WAVE/WAVE dataRef   = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 0)
	WAVE/T    dimension = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_SETSCALE, 1, checkExist = 1)
	SFH_ASSERT(IsTextWave(dimension), "Expected d, x, y, z or t as dimension.")
	SFH_ASSERT(DimSize(dimension, ROWS) == 1 && GrepString(dimension[0], "[d,x,y,z,t]"), "undefined input for dimension")

	if(numArgs >= 3)
		WAVE offset = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_SETSCALE, 2, checkExist = 1)
		SFH_ASSERT(IsNumericWave(offset) && DimSize(offset, ROWS) == 1, "Expected a number as offset.")
	else
		Make/FREE/N=1 offset = {0}
	endif
	if(numArgs >= 4)
		WAVE delta = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_SETSCALE, 3, checkExist = 1)
		SFH_ASSERT(IsNumericWave(delta) && DimSize(delta, ROWS) == 1, "Expected a number as delta.")
	else
		Make/FREE/N=1 delta = {1}
	endif
	if(numArgs == 5)
		WAVE/T unit = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_SETSCALE, 4, checkExist = 1)
		SFH_ASSERT(IsTextWave(unit) && DimSize(unit, ROWS) == 1, "Expected a string as unit.")
	else
		Make/FREE/N=1/T unit = {""}
	endif

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_SETSCALE, DimSize(dataRef, ROWS))

	output[] = SF_OperationSetScaleImpl(dataRef[p], dimension[0], offset[0], delta[0], unit[0])

	return SFH_GetOutputForExecutor(output, graph, SF_OP_SETSCALE, clear = dataRef)
End

static Function/WAVE SF_OperationSetScaleImpl(WAVE/Z input, string dim, variable offset, variable delta, string unit)

	if(!WaveExists(input))
		return $""
	endif

	if(CmpStr(dim, "d") && delta == 0)
		delta = 1
	endif

	strswitch(dim)
		case "d":
			SetScale d, offset, delta, unit, input
			break
		case "x":
			SetScale/P x, offset, delta, unit, input
			ASSERT(DimDelta(input, ROWS) == delta, "Encountered Igor Bug.")
			break
		case "y":
			SetScale/P y, offset, delta, unit, input
			ASSERT(DimDelta(input, COLS) == delta, "Encountered Igor Bug.")
			break
		case "z":
			SetScale/P z, offset, delta, unit, input
			ASSERT(DimDelta(input, LAYERS) == delta, "Encountered Igor Bug.")
			break
		case "t":
			SetScale/P t, offset, delta, unit, input
			ASSERT(DimDelta(input, CHUNKS) == delta, "Encountered Igor Bug.")
			break
		default:
			FATAL_ERROR("Invalid dimension mode")
			break
	endswitch

	return input
End

static Function/WAVE SF_OperationWave(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_WAVE, 0, maxArgs = 1)

	WAVE/Z output = $SFH_GetArgumentAsText(jsonID, jsonPath, graph, SF_OP_WAVE, 0, defValue = "")

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_WAVE, discardOpStack = 1)
End

/// `selchannels([str name]+)` converts a named channel from string to numbers.
///
/// returns [[channelName, channelNumber]+]
static Function/WAVE SF_OperationSelectChannels(variable jsonId, string jsonPath, string graph)

	variable numArgs, i, channelType
	string channelName, channelNumber
	string regExp = "^(?i)(" + ReplaceString(";", XOP_CHANNEL_NAMES, "|") + ")([0-9]+)?$"

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	WAVE channels = SF_NewChannelsWave(numArgs ? numArgs : 1)
	for(i = 0; i < numArgs; i += 1)
		channelName = ""
		WAVE chanSpec = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, SF_OP_SELECTCHANNELS, i, singleResult = 1)
		if(IsNumericWave(chanSpec))
			channels[i][%channelNumber] = chanSpec[0]
		elseif(IsTextWave(chanSpec))
			WAVE/T chanSpecT = chanSpec
			SplitString/E=regExp chanSpecT[0], channelName, channelNumber
			if(V_flag == 0)
				SFH_FATAL_ERROR("Unknown channel: " + chanSpecT[0])
			endif
			channels[i][%channelNumber] = str2num(channelNumber)
		else
			SFH_FATAL_ERROR("Unsupported arg type for selchannels.")
		endif
		SFH_ASSERT(!isFinite(channels[i][%channelNumber]) || channels[i][%channelNumber] < NUM_MAX_CHANNELS, "Maximum Number Of Channels exceeded.")
		if(!IsEmpty(channelName))
			channelType = WhichListItem(channelName, XOP_CHANNEL_NAMES, ";", 0, 0)
			if(channelType >= 0)
				channels[i][%channelType] = channelType
			endif
		endif
	endfor

	return SFH_GetOutputForExecutorSingle(channels, graph, SF_OP_SELECTCHANNELS, discardOpStack = 1, dataType = SF_DATATYPE_CHANNELS)
End

/// `selsweeps()`, `selsweeps(1,2,3, [4...6])`
/// returns all possible sweeps as 1d array
static Function/WAVE SF_OperationSelectSweeps(variable jsonId, string jsonPath, string graph)

	variable i, numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	if(!numArgs)
		WAVE/Z/D sweeps = OVS_GetSelectedSweeps(graph, OVS_SWEEP_ALL_SWEEPNO)
	else
		for(i = 0; i < numArgs; i += 1)
			WAVE data = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, SF_OP_SELECTSWEEPS, i, singleResult = 1, expectedMinorType = IGOR_TYPE_64BIT_FLOAT)
			SFH_ASSERT(!DimSize(data, COLS), "Argument of selsweeps must be a number or a 1d numeric array")
			Concatenate/FREE/D/NP {data}, sweeps
		endfor
	endif
	if(WaveExists(sweeps))
		WAVE uniqueSweeps = GetUniqueEntries(sweeps)
	else
		WAVE/ZZ uniqueSweeps
	endif

	return SFH_GetOutputForExecutorSingle(uniqueSweeps, graph, SF_OP_SELECTSWEEPS, discardOpStack = 1, dataType = SF_DATATYPE_SWEEPNO)
End

static Function/WAVE SF_OperationPowerSpectrum(variable jsonId, string jsonPath, string graph)

	variable i, doAvg, debugVal
	string unit, avg, winFunc
	variable cutoff, ratioFreq

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_POWERSPECTRUM, 1, maxArgs = 6)

	WAVE/WAVE input = SFH_GetArgumentAsWave(jsonID, jsonPath, graph, SF_OP_POWERSPECTRUM, 0, copy = 1)
	unit      = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_POWERSPECTRUM, 1, defValue = SF_POWERSPECTRUM_UNIT_DEFAULT, allowedValues = {SF_POWERSPECTRUM_UNIT_DEFAULT, SF_POWERSPECTRUM_UNIT_DB, SF_POWERSPECTRUM_UNIT_NORMALIZED})
	avg       = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_POWERSPECTRUM, 2, defValue = SF_POWERSPECTRUM_AVG_OFF, allowedValues = {SF_POWERSPECTRUM_AVG_ON, SF_POWERSPECTRUM_AVG_OFF})
	ratioFreq = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_POWERSPECTRUM, 3, defValue = 0, checkFunc = IsNullOrPositiveAndFinite)
	cutoff    = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_POWERSPECTRUM, 4, defValue = 1000, checkFunc = IsStrictlyPositiveAndFinite)
	WAVE/T allowedWinFuncs = ListToTextWave(AddListItem(SF_POWERSPECTRUM_WINFUNC_NONE, FFT_WINF), ";")
	winFunc = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_POWERSPECTRUM, 5, defValue = FFT_WINF_DEFAULT, allowedValues = allowedWinFuncs)
	if(!CmpStr(winFunc, SF_POWERSPECTRUM_WINFUNC_NONE))
		winFunc = ""
	endif

	for(data : input)
		if(!WaveExists(data))
			continue
		endif
		SFH_ASSERT(IsNumericWave(data), "powerspectrum requires numeric input data.")
	endfor
	Make/FREE/N=(DimSize(input, ROWS)) indexHelper
	MultiThread indexHelper[] = SF_RemoveEndOfSweepNaNs(input[p])

	doAvg  = !CmpStr(avg, "avg")
	cutOff = (ratioFreq == 0) ? cutOff : NaN

	if(doAvg)
		Make/FREE/WAVE/N=(DimSize(input, ROWS)) output
	else
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_POWERSPECTRUM, DimSize(input, ROWS))
	endif

	MultiThread output[] = SF_OperationPowerSpectrumImpl(input[p], unit, cutoff, winFunc)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_POWERSPECTRUM, SF_DATATYPE_POWERSPECTRUM)

	if(doAvg)
		WAVE/WAVE outputAvg   = SF_AverageDataOverSweeps(output)
		WAVE/WAVE outputAvgPS = SFH_CreateSFRefWave(graph, SF_OP_POWERSPECTRUM, DimSize(outputAvg, ROWS))
		JWN_SetStringInWaveNote(outputAvgPS, SF_META_DATATYPE, SF_DATATYPE_POWERSPECTRUM)
		JWN_SetStringInWaveNote(outputAvgPS, SF_META_OPSTACK, JWN_GetStringFromWaveNote(output, SF_META_OPSTACK))
		outputAvgPS[] = outputAvg[p]
		WAVE/WAVE output = outputAvgPS
	endif

	if(ratioFreq)
		Duplicate/FREE/WAVE output, inputRatio
#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForCaller())
			debugVal = DimSize(output, ROWS)
			Redimension/N=(debugVal * 2) output, inputRatio
			for(i = 0; i < debugVal; i += 1)
				Duplicate/FREE inputRatio[i], wv
				inputRatio[debugVal + i] = wv
			endfor
			output[0, debugVal - 1] = SF_PowerSpectrumRatio(inputRatio[p], ratioFreq, SF_POWERSPECTRUM_RATIO_DELTAHZ, fitData = inputRatio[p + debugVal])
			output[debugVal,]       = inputRatio[p]
		endif
#else
		output[] = SF_PowerSpectrumRatio(inputRatio[p], ratioFreq, SF_POWERSPECTRUM_RATIO_DELTAHZ)
#endif // DEBUGGING_ENABLED
	endif

	return SFH_GetOutputForExecutor(output, graph, SF_OP_POWERSPECTRUM, clear = input)
End

static Function/WAVE SF_PowerSpectrumRatio(WAVE/Z input, variable ratioFreq, variable deltaHz, [WAVE fitData])

	string sLeft, sRight, maxSigma, minAmp
	variable err, left, right, minFreq, maxFreq, endFreq, base

	if(!WaveExists(input))
		return $""
	endif

	endFreq   = IndexToScale(input, DimSize(input, ROWS) - SF_POWERSPECTRUM_RATIO_GAUSS_NUMCOEFS - 1, ROWS)
	ratioFreq = limit(ratioFreq, 0, endFreq)
	minFreq   = limit(ratioFreq - deltaHz, 0, endFreq)
	maxFreq   = limit(ratioFreq + deltaHz, 0, endFreq)

	Make/FREE/D wCoef = {0, 0, 1, ratioFreq, SF_POWERSPECTRUM_RATIO_MAXFWHM * SF_POWERSPECTRUM_RATIO_GAUSS_SIGMA2FWHM}

	left     = ratioFreq - SF_POWERSPECTRUM_RATIO_EPSILONHZ
	right    = ratioFreq + SF_POWERSPECTRUM_RATIO_EPSILONHZ
	sLeft    = "K3 > " + num2str(left, "%.2f")
	sRight   = "K3 < " + num2str(right, "%.2f")
	maxSigma = "K4 < " + num2str(SF_POWERSPECTRUM_RATIO_MAXFWHM / SF_POWERSPECTRUM_RATIO_GAUSS_SIGMA2FWHM, "%f")
	minAmp   = "K2 >= 0"
	Make/FREE/T wConstraints = {minAmp, sLeft, sRight, maxSigma}

	AssertOnAndClearRTError()
#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		FuncFit/Q SF_LineNoiseFit, kwCWave=wCoef, input(minFreq, maxFreq)/C=wConstraints/D=fitData; err = GetRTError(1)
		Duplicate/FREE/R=(minFreq, maxFreq) fitData, fitDataRanged
		Redimension/N=(DimSize(fitDataRanged, ROWS)) fitData
		CopyScales/P fitDataRanged, fitData
		if(err)
			FastOp fitData = (NaN)
		else
			fitData[] = fitDataRanged[p]
		endif
	endif
#else
	FuncFit/Q SF_LineNoiseFit, kwCWave=wCoef, input(minFreq, maxFreq)/C=wConstraints; err = GetRTError(1)
#endif // DEBUGGING_ENABLED
	MakeWaveFree($"W_sigma")

	Redimension/N=1 input
	input[0] = 0

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		SetScale/P x, ratioFreq, 1, WaveUnits(input, ROWS), input
	endif
#else
	SetScale/P x, wCoef[3], 1, WaveUnits(input, ROWS), input
#endif // DEBUGGING_ENABLED

	SetScale/P d, 0, 1, "power ratio", input

	if(err)
		return input
	endif

	base   = wCoef[0] + wCoef[1] * wCoef[3]
	left  -= SF_POWERSPECTRUM_RATIO_EPSILONPOSFIT
	right += SF_POWERSPECTRUM_RATIO_EPSILONPOSFIT
	if(base <= 0 || wCoef[3] < left || wCoef[3] > right || wCoef[2] < 0)
		return input
	endif

	input[0] = (wCoef[2] + base) / base
#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		printf "PS ratio, peak position, baseline, peak amplitude : %f %f %f %f\r", input[0], wCoef[3], base, wCoef[2]
	endif
#endif // DEBUGGING_ENABLED
	return input
End

Function SF_LineNoiseFit(WAVE w, variable x) : FitFunc

	// Formula: linear + gauss fit
	// y0 + m * x + A * exp(-((x - x0) / sigma)^2)
	// Coefficients:
	// 0: offset, y0
	// 1: slope, m
	// 2: amplitude, A
	// 3: peak position, x0
	// 4: sigma, sigma
	return w[0] + w[1] * x + w[2] * exp(-((x - w[3]) / w[4])^2)
End

threadsafe static Function/WAVE SF_OperationPowerSpectrumImpl(WAVE/Z input, string unit, variable cutoff, string winFunc)

	variable size, m

	if(!WaveExists(input))
		return $""
	endif

	if(!IsFloatingPointWave(input))
		Redimension/D input
	endif

	ZeroWaveImpl(input)

	if(!CmpStr(WaveUnits(input, ROWS), "ms"))
		SetScale/P x, DimOffset(input, ROWS) * MILLI_TO_ONE, DimDelta(input, ROWS) * MILLI_TO_ONE, "s", input
	endif

	if(IsEmpty(winFunc))
		WAVE wFFT = DoFFT(input)
	else
		WAVE wFFT = DoFFT(input, winFunc = winFunc)
	endif
	size = IsNaN(cutOff) ? DimSize(wFFT, ROWS) : min(ScaleToIndex(wFFT, cutoff, ROWS), DimSize(wFFT, ROWS))

	Make/FREE/N=(size) output
	CopyScales/P wFFT, output
	if(!CmpStr(unit, SF_POWERSPECTRUM_UNIT_DEFAULT))
		MultiThread output[] = magsqr(wFFT[p])
		SetScale/I y, 0, 1, WaveUnits(input, -1) + "^2", output
	elseif(!CmpStr(unit, SF_POWERSPECTRUM_UNIT_DB))
		MultiThread output[] = 10 * log(magsqr(wFFT[p]))
		SetScale/I y, 0, 1, "dB", output
	elseif(!CmpStr(unit, SF_POWERSPECTRUM_UNIT_NORMALIZED))
		MultiThread output[] = magsqr(wFFT[p])
		m = mean(output)
		MultiThread output[] = output[p] / m
		SetScale/I y, 0, 1, "mean(" + WaveUnits(input, -1) + "^2)", output
	endif

	return output
End

/// `selvis(mode)` // mode can be `all` or `displayed`
///
/// returns a one element text wave with either SF_OP_SELECTVIS_ALL or SF_OP_SELECTVIS_DISPLAYED
static Function/WAVE SF_OperationSelectVis(variable jsonId, string jsonPath, string graph)

	string vis

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTVIS, 0, maxArgs = 1)

	vis = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTVIS, 0, allowedValues = {SF_OP_SELECTVIS_DISPLAYED, SF_OP_SELECTVIS_ALL}, defValue = SF_OP_SELECTVIS_DISPLAYED)
	Make/FREE/T output = {vis}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTVIS, discardOpStack = 1, dataType = SF_DATATYPE_SELECTVIS)
End

/// `selexp(expName)` // expName is a string with optional wildcards
///
/// returns a one element text wave
static Function/WAVE SF_OperationSelectExperiment(variable jsonId, string jsonPath, string graph)

	string expName

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTEXP, 1, maxArgs = 1)

	expName = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTEXP, 0)
	Make/FREE/T output = {expName}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTEXP, discardOpStack = 1, dataType = SF_DATATYPE_SELECTEXP)
End

/// `selexpandsci()` // no arguments
///
/// returns a one element numeric wave
static Function/WAVE SF_OperationSelectExpandSCI(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTEXPANDSCI, 0, maxArgs = 0)

	Make/FREE/D output = {1}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTEXPANDSCI, discardOpStack = 1, dataType = SF_DATATYPE_SELECTEXPANDSCI)
End

/// `selexpandrac()` // no arguments
///
/// returns a one element numeric wave
static Function/WAVE SF_OperationSelectExpandRAC(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTEXPANDRAC, 0, maxArgs = 0)

	Make/FREE/D output = {1}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTEXPANDRAC, discardOpStack = 1, dataType = SF_DATATYPE_SELECTEXPANDRAC)
End

/// `selsetcyclecount(x)` // one numeric argument
///
/// returns a one element numeric wave
static Function/WAVE SF_OperationSelectSetCycleCount(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSETCYCLECOUNT, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTSETCYCLECOUNT, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSETCYCLECOUNT, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSETCYCLECOUNT)
End

/// `selsetsweepcount(x)` // one numeric argument
///
/// returns a one element numeric wave
static Function/WAVE SF_OperationSelectSetSweepCount(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSETSWEEPCOUNT, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTSETSWEEPCOUNT, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSETSWEEPCOUNT, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSETSWEEPCOUNT)
End

/// `selsciindex(x)` // one numeric argument
///
/// returns a one element numeric wave
static Function/WAVE SF_OperationSelectSCIIndex(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSCIINDEX, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTSCIINDEX, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSCIINDEX, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSCIINDEX)
End

/// `selracindex(x)` // one numeric argument
///
/// returns a one element numeric wave
static Function/WAVE SF_OperationSelectRACIndex(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTRACINDEX, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTRACINDEX, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTRACINDEX, discardOpStack = 1, dataType = SF_DATATYPE_SELECTRACINDEX)
End

/// `seldev(device)` // device is a string with optional wildcards
///
/// returns a one element text wave
static Function/WAVE SF_OperationSelectDevice(variable jsonId, string jsonPath, string graph)

	string expName

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTDEV, 1, maxArgs = 1)

	expName = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTDEV, 0)
	Make/FREE/T output = {expName}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTDEV, discardOpStack = 1, dataType = SF_DATATYPE_SELECTDEV)
End

/// `selcm(mode, mode, ...)` // mode can be `ic`, `vc`, `izero`, `all`
/// see @ref SFClampModeStrings
///
/// returns a one element numeric wave with SF_OP_SELECTCM_CLAMPMODE_* ORed together from all arguments, see @ref SFClampcodeConstants
static Function/WAVE SF_OperationSelectCM(variable jsonId, string jsonPath, string graph)

	variable numArgs, i, mode
	string clampMode

	numArgs = SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTCM, 0)
	if(!numArgs)
		mode = SF_OP_SELECT_CLAMPCODE_ALL
	else
		for(i = 0; i < numArgs; i += 1)
			clampMode = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTCM, i, allowedValues = {SF_OP_SELECTCM_CLAMPMODE_ALL, SF_OP_SELECTCM_CLAMPMODE_NONE, SF_OP_SELECTCM_CLAMPMODE_IZERO, SF_OP_SELECTCM_CLAMPMODE_IC, SF_OP_SELECTCM_CLAMPMODE_VC}, defValue = SF_OP_SELECTCM_CLAMPMODE_ALL)

			strswitch(clampMode)
				case SF_OP_SELECTCM_CLAMPMODE_ALL:
					mode = mode | SF_OP_SELECT_CLAMPCODE_ALL
					break
				case SF_OP_SELECTCM_CLAMPMODE_NONE:
					mode = mode | SF_OP_SELECT_CLAMPCODE_NONE
					break
				case SF_OP_SELECTCM_CLAMPMODE_IZERO:
					mode = mode | SF_OP_SELECT_CLAMPCODE_IZERO
					break
				case SF_OP_SELECTCM_CLAMPMODE_IC:
					mode = mode | SF_OP_SELECT_CLAMPCODE_IC
					break
				case SF_OP_SELECTCM_CLAMPMODE_VC:
					mode = mode | SF_OP_SELECT_CLAMPCODE_VC
					break
				default:
					FATAL_ERROR("Unsupported mode")
			endswitch
		endfor
	endif

	Make/FREE output = {mode}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTCM, discardOpStack = 1, dataType = SF_DATATYPE_SELECTCM)
End

/// `selstimset(stimsetName, stimsetName, ...)`
///
/// returns a N element text wave with stimset names
static Function/WAVE SF_OperationSelectStimset(variable jsonId, string jsonPath, string graph)

	variable numArgs, i

	numArgs = SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSTIMSET, 0)

	if(!numArgs)
		Make/FREE/T output = {SF_OP_SELECT_STIMSETS_ALL}
	else
		Make/FREE/T/N=(numArgs) output
		for(i = 0; i < numArgs; i += 1)
			output[i] = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTSTIMSET, i)
		endfor
	endif

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSTIMSET, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSTIMSET)
End

/// `SelIVSCCSweepQC(passed | failed)`
///
/// returns a one element numeric wave with either SF_OP_SELECT_IVSCCSWEEPQC_PASSED or SF_OP_SELECT_IVSCCSWEEPQC_FAILED
static Function/WAVE SF_OperationSelectIVSCCSweepQC(variable jsonId, string jsonPath, string graph)

	variable mode
	string   arg

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTIVSCCSWEEPQC, 1, maxArgs = 1)

	arg  = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTIVSCCSWEEPQC, 0, allowedValues = {SF_OP_SELECT_IVSCCQC_PASSED, SF_OP_SELECT_IVSCCQC_FAILED})
	mode = !CmpStr(arg, SF_OP_SELECT_IVSCCQC_PASSED) ? SF_OP_SELECT_IVSCCSWEEPQC_PASSED : SF_OP_SELECT_IVSCCSWEEPQC_FAILED

	Make/FREE output = {mode}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTIVSCCSWEEPQC, discardOpStack = 1, dataType = SF_DATATYPE_SELECTIVSCCSWEEPQC)
End

/// `SelIVSCCSetQC(passed | failed)`
///
/// returns a one element numeric wave with either SF_OP_SELECT_IVSCCSETQC_PASSED or SF_OP_SELECT_IVSCCSETQC_FAILED
static Function/WAVE SF_OperationSelectIVSCCSetQC(variable jsonId, string jsonPath, string graph)

	variable mode
	string   arg

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTIVSCCSETQC, 1, maxArgs = 1)

	arg  = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTIVSCCSETQC, 0, allowedValues = {SF_OP_SELECT_IVSCCQC_PASSED, SF_OP_SELECT_IVSCCQC_FAILED})
	mode = !CmpStr(arg, SF_OP_SELECT_IVSCCQC_PASSED) ? SF_OP_SELECT_IVSCCSETQC_PASSED : SF_OP_SELECT_IVSCCSETQC_FAILED

	Make/FREE output = {mode}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTIVSCCSETQC, discardOpStack = 1, dataType = SF_DATATYPE_SELECTIVSCCSETQC)
End

/// `selrange(rangespec)`
///
/// returns 1 dataset with range specification (either text or 2 point numerical wave)
static Function/WAVE SF_OperationSelectRange(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTRANGE, 0, maxArgs = 1)
	if(!numArgs)
		WAVE/WAVE range = SFH_AsDataSet(SFH_GetFullRange())
	else
		WAVE/WAVE range = SFH_EvaluateRange(jsonId, jsonPath, graph, SF_OP_SELECTRANGE, 0)
	endif

	return SFH_GetOutputForExecutorSingle(range, graph, SF_OP_SELECTRANGE, discardOpStack = 1, dataType = SF_DATATYPE_SELECTRANGE)
End

static Function SF_InitSelectFilterUninitalized(STRUCT SF_SelectParameters &s)

	WAVE/Z s.selects  = $""
	WAVE/Z s.channels = $""
	WAVE/Z s.sweeps   = $""
	s.sweepsSet = 0
	s.vis       = ""
	s.clampMode = NaN
	WAVE/Z/T    s.stimsets = $""
	WAVE/Z/WAVE s.ranges   = $""
	s.sweepQC       = NaN
	s.setQC         = NaN
	s.expandSCI     = NaN
	s.expandRAC     = NaN
	s.setCycleCount = NaN
	s.setSweepCount = NaN
	s.sciIndex      = NaN
	s.racIndex      = NaN
End

/// `select(selectFilterOp...)`
///
/// returns 2 datasets, main wave typed SF_DATATYPE_SELECTCOMP
/// dataset 0: N x 3 with columns [sweepNr][channelType][channelNr], typed SF_DATATYPE_SELECT
/// dataset 1: WaveRef wave with range specifications, typed SF_DATATYPE_SELECTRANGE
static Function/WAVE SF_OperationSelect(variable jsonId, string jsonPath, string graph)

	STRUCT SF_SelectParameters filter
	variable i, numArgs, selectArgPresent
	string type, vis
	string expName = ""
	string device  = ""

	SF_InitSelectFilterUninitalized(filter)

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	for(i = 0; i < numArgs; i += 1)
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, i)
		SFH_ASSERT(DimSize(input, ROWS) >= 1, "Expected at least one dataset")
		type = JWN_GetStringFromWaveNote(input, SF_META_DATATYPE)
		WAVE/Z arg = input[0]
		if(!(!CmpStr(SF_DATATYPE_SELECTCOMP, type) || !CmpStr(SF_DATATYPE_SWEEPNO, type)))
			// all regular select filters return data from a typed wave from their respective operation, that as sanity check must have valid data
			// except data from select, where arg is a selection result that can also be a null wave
			// and data from selsweeps
			ASSERT(WaveExists(arg), "Expected argument with content")
		endif
		strswitch(type)
			case SF_DATATYPE_SELECTSCIINDEX:
				if(IsNaN(filter.sciIndex))
					filter.sciIndex = arg[0]
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTSCIINDEX + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTRACINDEX:
				if(IsNaN(filter.racIndex))
					filter.racIndex = arg[0]
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTRACINDEX + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTSETCYCLECOUNT:
				if(IsNaN(filter.setCycleCount))
					filter.setCycleCount = arg[0]
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTSETCYCLECOUNT + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTSETSWEEPCOUNT:
				if(IsNaN(filter.setSweepCount))
					filter.setSweepCount = arg[0]
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTSETSWEEPCOUNT + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTEXPANDSCI:
				if(IsNaN(filter.expandSCI))
					filter.expandSCI = 1
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTEXPANDSCI + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTEXPANDRAC:
				if(IsNaN(filter.expandRAC))
					filter.expandRAC = 1
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTEXPANDRAC + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTDEV:
				if(IsEmpty(device))
					device = WaveText(arg, row = 0)
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTDEV + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTEXP:
				if(IsEmpty(expName))
					expName = WaveText(arg, row = 0)
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTEXP + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTVIS:
				if(IsEmpty(filter.vis))
					filter.vis = WaveText(arg, row = 0)
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTVIS + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTCM:
				if(IsNaN(filter.clampMode))
					filter.clampMode = arg[0]
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTCM + " argument.")
				endif
				break
			case SF_DATATYPE_CHANNELS:
				if(!WaveExists(filter.channels))
					WAVE filter.channels = arg
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTCHANNELS + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTSTIMSET:
				if(!WaveExists(filter.stimsets))
					WAVE/T filter.stimsets = arg
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTSTIMSET + " argument.")
				endif
				break
			case SF_DATATYPE_SWEEPNO:
				if(!filter.sweepsSet)
					WAVE/Z filter.sweeps = arg
					filter.sweepsSet = 1
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTSWEEPS + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTIVSCCSWEEPQC:
				if(IsNaN(filter.sweepQC))
					filter.sweepQC = arg[0]
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTIVSCCSWEEPQC + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTIVSCCSETQC:
				if(IsNaN(filter.setQC))
					filter.setQC = arg[0]
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTIVSCCSETQC + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTRANGE:
				if(!WaveExists(filter.ranges))
					WAVE filter.ranges = arg
				else
					SFH_FATAL_ERROR("select allows only a single " + SF_OP_SELECTRANGE + " argument.")
				endif
				break
			case SF_DATATYPE_SELECTCOMP:
				selectArgPresent = 1
				if(!WaveExists(filter.selects))
					WAVE/Z filter.selects = arg
				else
					WAVE/Z filter.selects = SF_GetSetIntersectionSelect(filter.selects, arg)
				endif
				break
			default:
				SFH_FATAL_ERROR("Unsupported select argument")
		endswitch
	endfor

	SF_SetSelectionFilterDefaults(graph, filter, selectArgPresent)

	if(!IsEmpty(expName))
		filter.experimentName = SF_GetSelectionExperiment(graph, expName)
	endif
	if(!IsEmpty(device))
		filter.device = SF_GetSelectionDevice(graph, device)
	endif

	WAVE/Z selectData = SF_GetSelectData(graph, filter)
	if(WaveExists(selectData))
		if(!IsNaN(filter.racIndex))
			WAVE/Z racSelectData = SF_GetSelectDataWithRACorSCIIndex(graph, selectData, filter.racIndex, SELECTDATA_MODE_RAC)
			WAVE/Z selectData    = racSelectData
		endif
		if(!IsNaN(filter.sciIndex))
			WAVE/Z sciSelectData = SF_GetSelectDataWithRACorSCIIndex(graph, selectData, filter.sciIndex, SELECTDATA_MODE_SCI)
			WAVE/Z selectData    = sciSelectData
		endif
		// SCI is a subset of RAC, thus if RAC and SCI is enabled then it is sufficient to extend through RAC
		if(filter.expandRAC)
			WAVE selectWithRACFilledUp = SF_GetSelectDataWithSCIorRAC(graph, selectData, filter, SELECTDATA_MODE_RAC)
			WAVE selectData            = selectWithRACFilledUp
		elseif(filter.expandSCI)
			WAVE selectWithSCIFilledUp = SF_GetSelectDataWithSCIorRAC(graph, selectData, filter, SELECTDATA_MODE_SCI)
			WAVE selectData            = selectWithSCIFilledUp
		endif
		if(filter.expandSCI || filter.expandRAC)
			WAVE sortedSelectData = SF_SortSelectData(selectData)
			WAVE selectData       = sortedSelectData
		endif
	endif

	if(!WaveExists(selectData))
		// case: select from added filter arguments leaves empty selection, then result is empty as intersection with any other selection would yield also empty result
		WAVE/Z selectResult = $""
	elseif(WaveExists(filter.selects))
		// case: select argument(s) present, selection from argument is intersected with select from added filter arguments
		WAVE/Z selectResult = SF_GetSetIntersectionSelect(filter.selects, selectData)
	elseif(selectArgPresent)
		// case: select argument(s) present, but selection from argument(s) is empty
		WAVE/Z selectResult = $""
	else
		// case: no select argument and select results from filter arguments
		WAVE selectResult = selectData
	endif

	WAVE/WAVE output = GetSFSelectDataComp(graph, SF_OP_SELECT)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_SELECTCOMP)
	JWN_SetStringInWaveNote(filter.ranges, SF_META_DATATYPE, SF_DATATYPE_SELECTRANGE)
	if(WaveExists(selectResult))
		JWN_SetStringInWaveNote(selectResult, SF_META_DATATYPE, SF_DATATYPE_SELECT)
		JWN_SetStringInWaveNote(output, SF_META_CUSTOM_LEGEND, SFH_CreateLegendFromRanges(selectResult, filter.ranges))
	endif
	JWN_SetNumberInWaveNote(filter.ranges, SF_META_DONOTPLOT, 1)

	output[%SELECTION] = selectResult
	output[%RANGE]     = filter.ranges

	return SFH_GetOutputForExecutor(output, graph, SF_OP_SELECT)
End

static Function [STRUCT SF_SelectParameters filterDup] SF_DuplicateSelectFilter(STRUCT SF_SelectParameters &filter)

	WAVE/Z filterDup.selects  = filter.selects
	WAVE/Z filterDup.channels = filter.channels
	WAVE/Z filterDup.sweeps   = filter.sweeps
	filterDup.vis       = filter.vis
	filterDup.clampMode = filter.clampMode
	WAVE/Z/T filterDup.stimsets = filter.stimsets
	WAVE/Z   filterDup.ranges   = filter.ranges
	filterDup.sweepQC        = filter.sweepQC
	filterDup.setQC          = filter.setQC
	filterDup.experimentName = filter.experimentName
	filterDup.device         = filter.device
	filterDup.expandSCI      = filter.expandSCI
	filterDup.expandRAC      = filter.expandRAC
	filterDup.setCycleCount  = filter.setCycleCount
	filterDup.setSweepCount  = filter.setSweepCount
	filterDup.racIndex       = filter.racIndex
	filterDup.sciIndex       = filter.sciIndex

	return [filterDup]
End

static Function/WAVE SF_RestoreSelectDataFromText(WAVE/T selectText)

	WAVE selectData = SFH_NewSelectDataWave(DimSize(selectText, ROWS), 1)
	MultiThread selectData[][%SWEEP] = SF_ParseSelectText(selectText, selectData, p)

	return selectData
End

threadsafe static Function SF_ParseSelectText(WAVE/T selectText, WAVE selectData, variable index)

	variable sweepNo, channelNumber, channelType, mapIndex

	sscanf selectText[index], SF_GETSETINTERSECTIONSELECT_FORMAT, sweepNo, channelType, channelNumber, mapIndex
	ASSERT_TS(V_flag == 4, "Failed parsing selectText")
	selectData[index][%SWEEP]         = sweepNo
	selectData[index][%CHANNELNUMBER] = channelNumber
	selectData[index][%CHANNELTYPE]   = channelType
	selectData[index][%SWEEPMAPINDEX] = mapIndex

	return sweepNo
End

static Function/WAVE SF_GetUniqueSelectData(WAVE selectData)

	WAVE/T selectText       = SF_CreateSelectWaveRowIds(selectData)
	WAVE/T selectTextUnique = GetUniqueEntries(selectText)
	return SF_RestoreSelectDataFromText(selectTextUnique)
End

threadsafe static Function/S SF_CreateSweepMapRowId(string experiment, string datafolder, string device, string sweep)

	string id

	sprintf id, "%s|%s|%s|%s", experiment, datafolder, device, sweep

	return id
End

threadsafe static Function/S SF_GetSweepMapRowId(WAVE/T sweepMap, variable index)

	return SF_CreateSweepMapRowId(sweepMap[index][%FileName], sweepMap[index][%DataFolder], sweepMap[index][%Device], sweepMap[index][%Sweep])
End

threadsafe static Function SF_GetSweepMapIndexFromIds(WAVE/T sweepMapIds, string experiment, string datafolder, string device, variable sweepNo)

	string id

	id = SF_CreateSweepMapRowId(experiment, datafolder, device, num2istr(sweepNo))
	FindValue/TXOP=4/TEXT=id sweepMapIds
	ASSERT_TS(V_row >= 0, "SweepMap id not found")

	return V_row
End

static Function/WAVE SF_GetSelectDataWithRACorSCIIndex(string graph, WAVE selectData, variable index, variable mode)

	variable i, numSelected, mapIndex, outIndex, headstage
	variable sweepNo, channelNumber, channelType
	variable isSweepBrowser = BSP_IsSweepBrowser(graph)

	if(IsSweepBrowser)
		WAVE/T sweepMap = SB_GetSweepMap(graph)
	endif

	numSelected = DimSize(selectData, ROWS)
	// get CycleIds per select
	Make/FREE/D/N=(numSelected) cycleIds
	FastOp cycleIds = (NaN)
	if(mode == SELECTDATA_MODE_SCI)
		Make/FREE/D/N=(numSelected) headStages
		FastOp headStages = (NaN)
	endif

	for(i = 0; i < numSelected; i += 1)
		sweepNo  = selectData[i][%SWEEP]
		mapIndex = selectData[i][%SWEEPMAPINDEX]
		WAVE numericalValues = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_VALUES)
		ASSERT(WaveExists(numericalValues), "Could not resolve numerical LNB")
		if(mode == SELECTDATA_MODE_RAC)
			cycleIds[i] = GetLastSettingIndep(numericalValues, sweepNo, RA_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE, defValue = NaN)
		elseif(mode == SELECTDATA_MODE_SCI)
			channelNumber              = selectData[i][%CHANNELNUMBER]
			channelType                = selectData[i][%CHANNELTYPE]
			[WAVE settings, headstage] = GetLastSettingChannel(numericalValues, $"", sweepNo, STIMSET_ACQ_CYCLE_ID_KEY, channelNumber, channelType, DATA_ACQUISITION_MODE)
			if(WaveExists(settings))
				cycleIds[i]   = settings[headstage]
				headStages[i] = headstage
			endif
		endif
	endfor

	// remove selections with no cycleId
	for(i = 0; i < numSelected; i += 1)
		if(!IsNaN(cycleIds[i]))
			selectData[outIndex][] = selectData[i][q]
			outIndex              += 1
		endif
	endfor
	if(!outIndex)
		return $""
	endif
	Redimension/N=(outIndex, -1) selectData
	WAVE cycleIdsZapped = ZapNaNs(cycleIds)
	if(mode == SELECTDATA_MODE_SCI)
		WAVE headStagesZapped = ZapNaNs(headStages)
	endif

	switch(mode)
		case SELECTDATA_MODE_RAC:
			return SF_GetSelectDataWithRACIndex(selectData, cycleIdsZapped, sweepMap, index)
		case SELECTDATA_MODE_SCI:
			return SF_GetSelectDataWithSCIIndex(selectData, cycleIdsZapped, headStagesZapped, sweepMap, index)
		default:
			FATAL_ERROR("Unknown mode")
	endswitch
End

static Function/WAVE SF_GetSelectDataWithRACIndex(WAVE selectData, WAVE cycleIds, WAVE/Z/T sweepMap, variable index)

	variable i, outIndex, numSelected, currIndex

	numSelected = DimSize(selectData, ROWS)

	// Sort
	Make/FREE/T/N=(numSelected) expNames, sortKeySweep, sortKeyChannelType, sortKeyChannelNumber
	if(WaveExists(sweepMap))
		expNames[] = sweepMap[selectData[p][%SWEEPMAPINDEX]][%FileName]
	else
		expNames[] = DB_EXPNAME_DUMMY
	endif
	sortKeySweep[]         = num2str(selectData[p][%SWEEP], "%06d")
	sortKeyChannelType[]   = num2str(selectData[p][%CHANNELTYPE], "%02d")
	sortKeyChannelNumber[] = num2str(selectData[p][%CHANNELNUMBER], "%02d")
	SortColumns keyWaves={expNames, sortKeySweep, sortKeyChannelType, sortKeyChannelNumber}, sortWaves={selectData, expNames, cycleIds}

	// filter by index
	for(i = 0; i < numSelected; i += 1)
		if(i > 0)
			if(CmpStr(expNames[i], expNames[i - 1], 2))
				currIndex = 0
			elseif(cycleIds[i] != cycleIds[i - 1])
				currIndex += 1
			endif
		endif

		if(currIndex < index)
			continue
		endif
		if(currIndex > index)
			break
		endif

		selectData[outIndex][] = selectData[i][q]
		outIndex              += 1
	endfor
	if(!outIndex)
		return $""
	endif
	Redimension/N=(outIndex, -1) selectData

	return selectData
End

static Function/WAVE SF_GetSelectDataWithSCIIndex(WAVE selectData, WAVE cycleIds, WAVE headstages, WAVE/Z/T sweepMap, variable index)

	variable i, headstage, outIndex, numSelected, currIndex, hsIndex, hsIndexPrev

	numSelected = DimSize(selectData, ROWS)

	// Sort
	Make/FREE/T/N=(numSelected) expNames, sortKeySweep, sortKeyChannelType, sortKeyChannelNumber
	if(WaveExists(sweepMap))
		expNames[] = sweepMap[selectData[p][%SWEEPMAPINDEX]][%FileName]
	else
		expNames[] = DB_EXPNAME_DUMMY
	endif
	sortKeySweep[]         = num2str(selectData[p][%SWEEP], "%06d")
	sortKeyChannelType[]   = num2str(selectData[p][%CHANNELTYPE], "%02d")
	sortKeyChannelNumber[] = num2str(selectData[p][%CHANNELNUMBER], "%02d")
	SortColumns keyWaves={expNames, sortKeySweep, sortKeyChannelType, sortKeyChannelNumber}, sortWaves={selectData, expNames, cycleIds, headstages}

	Duplicate/FREE selectData, selectDataTgt

	WAVE uniqueHS = GetUniqueEntries(headstages)
	for(headstage : uniqueHS)
		currIndex   = 0
		hsIndex     = NaN
		hsIndexPrev = NaN
		for(i = 0; i < numSelected; i += 1)
			if(headstage != headstages[i])
				continue
			endif

			if(IsNaN(hsIndexPrev))
				hsIndexPrev = i
			elseif(IsNaN(hsIndex))
				hsIndex = i
			else
				hsIndexPrev = hsIndex
				hsIndex     = i
			endif

			if(!IsNaN(hsIndex))
				if(CmpStr(expNames[hsIndex], expNames[hsIndexPrev], 2))
					currIndex = 0
				elseif(cycleIds[hsIndex] != cycleIds[hsIndexPrev])
					currIndex += 1
				endif
			endif

			if(currIndex < index)
				continue
			endif
			if(currIndex > index)
				break
			endif

			selectDataTgt[outIndex][] = selectData[i][q]
			outIndex                 += 1
		endfor
	endfor
	if(!outIndex)
		return $""
	endif
	Redimension/N=(outIndex, -1) selectDataTgt

	return selectDataTgt
End

static Function/WAVE SF_GetAdditionalSweepsWithSameSCIorRAC(WAVE numericalValues, variable mode, variable sweepNo, variable channelType, variable channelNumber)

	variable headstage

	if(mode == SELECTDATA_MODE_SCI)
		headstage = GetHeadstageForChannel(numericalValues, sweepNo, channelType, channelNumber, DATA_ACQUISITION_MODE)
		if(!IsValidHeadstage(headstage))
			return $""
		endif
		WAVE/Z additionalSweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
	elseif(mode == SELECTDATA_MODE_RAC)
		WAVE/Z additionalSweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	endif
	if(!WaveExists(additionalSweeps))
		return $""
	endif
	if(DimSize(additionalSweeps, ROWS) == 1)
		return $""
	endif

	// Need to work on a copy if we modify it or we corrupt the cached wave
	Duplicate/FREE additionalSweeps, additionalSweepsDup
	FindValue/V=(sweepNo)/UOFV additionalSweepsDup
	ASSERT(V_row >= 0, "Expected to find original sweep number")
	DeleteWavePoint(additionalSweepsDup, ROWS, index = V_row)

	return additionalSweepsDup
End

/// @brief Takes input selections and extends them. The extension of the selection is chosen through mode, one of SELECTDATA_MODE_*
///        For RAC: For each input selection adds all selections of the same repeated acquisition cycle
///        For SCI: For each input selection adds all selections of the same stimset cycle id and headstage
///        Returns all resulting unique selections.
static Function/WAVE SF_GetSelectDataWithSCIorRAC(string graph, WAVE selectData, STRUCT SF_SelectParameters &filter, variable mode)

	variable i, j, isSweepBrowser, numSelected
	variable sweepNo, channelType, channelNumber, mapIndex
	variable addSweepNo

	ASSERT(mode == SELECTDATA_MODE_SCI || mode == SELECTDATA_MODE_RAC, "Unknown SCI/RAC mode")

	[STRUCT SF_SelectParameters filterDup] = SF_DuplicateSelectFilter(filter)
	filterDup.vis                          = SF_OP_SELECTVIS_ALL

	isSweepBrowser = BSP_IsSweepBrowser(graph)
	if(isSweepBrowser)
		WAVE/T sweepMap = SB_GetSweepMap(graph)
		if(mode == SELECTDATA_MODE_SCI)
			Make/FREE/T/N=(GetNumberFromWaveNote(sweepMap, NOTE_INDEX)) sweepMapIds
			MultiThread sweepMapIds[] = SF_GetSweepMapRowId(sweepMap, p)
		endif
	else
		filterDup.experimentName = GetExperimentName()
		filterDup.device         = DB_GetDevice(graph)
	endif

	numSelected = DimSize(selectData, ROWS)
	for(i = 0; i < numSelected; i += 1)
		sweepNo  = selectData[i][%SWEEP]
		mapIndex = selectData[i][%SWEEPMAPINDEX]
		WAVE numericalValues = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_VALUES)
		if(!WaveExists(numericalValues))
			continue
		endif

		channelNumber = selectData[i][%CHANNELNUMBER]
		channelType   = selectData[i][%CHANNELTYPE]
		WAVE/Z additionalSweeps = SF_GetAdditionalSweepsWithSameSCIorRAC(numericalValues, mode, sweepNo, channelType, channelNumber)
		if(!WaveExists(additionalSweeps))
			continue
		endif

		if(isSweepBrowser)
			filterDup.experimentName = sweepMap[mapIndex][%FileName]
			filterDup.device         = sweepMap[mapIndex][%Device]
		endif

		if(mode == SELECTDATA_MODE_SCI)
			// SCI is headstage specific, we add exact the same channelType and channelNumber as the requested one
			WAVE selectDataAdd = SFH_NewSelectDataWave(DimSize(additionalSweeps, ROWS), 1)
			selectDataAdd[][%SWEEP]         = additionalSweeps[p]
			selectDataAdd[][%CHANNELNUMBER] = channelNumber
			selectDataAdd[][%CHANNELTYPE]   = channelType
			if(isSweepBrowser)
				MultiThread selectDataAdd[][%SWEEPMAPINDEX] = SF_GetSweepMapIndexFromIds(sweepMapIds, filterDup.experimentName, sweepMap[mapIndex][%DataFolder], filterDup.device, additionalSweeps[p])
			else
				selectDataAdd[][%SWEEPMAPINDEX] = NaN
			endif
		else
			WAVE   filterDup.sweeps = additionalSweeps
			WAVE/Z selectDataAdd    = SF_GetSelectData(graph, filterDup)
			if(!WaveExists(selectDataAdd))
				continue
			endif
		endif
		Concatenate/FREE/NP=(ROWS) {selectDataAdd}, selectDataCollect
	endfor

	if(!WaveExists(selectDataCollect))
		return selectData
	endif

	Concatenate/FREE/NP=(ROWS) {selectData}, selectDataCollect

	return SF_GetUniqueSelectData(selectDataCollect)
End

static Function/S SF_GetSelectionExperiment(string graph, string expName)

	string currentExperimentName

	if(BSP_IsDataBrowser(graph))
		currentExperimentName = GetExperimentName()
		SFH_ASSERT(stringmatch(currentExperimentName, expName), "Selected experiment does not exist")

		return currentExperimentName
	endif
	if(BSP_IsSweepBrowser(graph))
		return SF_MatchSweepMapColumn(graph, expName, "FileName", SF_OP_SELECTEXP)
	endif

	FATAL_ERROR("Unknown browser type")
End

static Function/S SF_GetSelectionDevice(string graph, string device)

	string deviceDB

	if(BSP_IsDataBrowser(graph))
		deviceDB = DB_GetDevice(graph)
		SFH_ASSERT(!IsEmpty(deviceDB), "DataBrowser has no locked device")
		SFH_ASSERT(stringmatch(deviceDB, device), "Selected device does not exist")

		return deviceDB
	endif
	if(BSP_IsSweepBrowser(graph))
		return SF_MatchSweepMapColumn(graph, device, "Device", SF_OP_SELECTDEV)
	endif

	FATAL_ERROR("Unknown browser type")
End

/// @brief sets uninitialized fields of the selection filter
static Function SF_SetSelectionFilterDefaults(string graph, STRUCT SF_SelectParameters &filter, variable includeAll)

	includeAll = !!includeAll

	if(!WaveExists(filter.channels))
		WAVE filter.channels = SF_ExecuteFormula("selchannels()", graph, singleResult = 1, checkExist = 1, useVariables = 0)
	endif
	if(!filter.sweepsSet)
		WAVE/Z filter.sweeps = SF_ExecuteFormula("selsweeps()", graph, singleResult = 1, useVariables = 0)
	endif
	if(IsEmpty(filter.vis))
		filter.vis = SelectString(includeAll, SF_OP_SELECTVIS_DISPLAYED, SF_OP_SELECTVIS_ALL)
	endif
	if(IsNaN(filter.clampMode))
		filter.clampMode = SF_OP_SELECT_CLAMPCODE_ALL
	endif
	if(!WaveExists(filter.stimsets))
		Make/FREE/T allStimsets = {SF_OP_SELECT_STIMSETS_ALL}
		WAVE/T filter.stimsets = allStimsets
	endif
	if(IsNaN(filter.sweepQC))
		filter.sweepQC = SF_OP_SELECT_IVSCCSWEEPQC_IGNORE
	endif
	if(IsNaN(filter.setQC))
		filter.setQC = SF_OP_SELECT_IVSCCSETQC_IGNORE
	endif
	if(!WaveExists(filter.ranges))
		WAVE/WAVE filter.ranges = SFH_AsDataSet(SFH_GetFullRange())
	endif
	if(numtype(strlen(filter.experimentName)) == 2)
		filter.experimentName = ""
	endif
	if(numtype(strlen(filter.device)) == 2)
		filter.device = ""
	endif
	if(IsNaN(filter.expandSCI))
		filter.expandSCI = 0
	endif
	if(IsNaN(filter.expandRAC))
		filter.expandRAC = 0
	endif
	// setCycleCount, setSweepCount same as uninitialied values
End

/// `data(array range[, array selectData])`
///
/// returns [sweepData][sweeps][channelTypeNumber] for all sweeps selected by selectData
static Function/WAVE SF_OperationData(variable jsonId, string jsonPath, string graph)

	variable i, numArgs

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_DATA, 0, maxArgs = 1)
	WAVE/WAVE selectData = SFH_GetArgumentSelect(jsonID, jsonPath, graph, SF_OP_DATA, 0)

	WAVE/WAVE output = SFH_GetSweepsForFormula(graph, selectData, SF_OP_DATA)
	if(!DimSize(output, ROWS))
		DebugPrint("Call to SFH_GetSweepsForFormula returned no results")
	endif

	SFH_AddOpToOpStack(output, "", SF_OP_DATA)
	SFH_ResetArgSetupStack(output, SF_OP_DATA)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_DATA)
End

static Function/WAVE SF_OperationAnaFuncParam(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonID, jsonPath, SF_OP_ANAFUNCPARAM, 0, maxArgs = 2)

	WAVE/T names      = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, SF_OP_ANAFUNCPARAM, 0, singleResult = 1)
	WAVE/Z selectData = SFH_GetArgumentSelect(jsonID, jsonPath, graph, SF_OP_DATA, 1)

	WAVE/WAVE output = SF_OperationAnaFuncParamIterate(graph, names, selectData, SF_OP_ANAFUNCPARAM)

	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_ANAFUNCPARAM, ""))
	JWN_SetStringInWaveNote(output, SF_META_WINDOW_HOOK, "TraceValueDisplayHook")

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_ANAFUNCPARAM)
End

static Function/WAVE SF_OperationAnaFuncParamIterate(string graph, WAVE/T names, WAVE/Z/WAVE selectDataArray, string opShort)

	if(!WaveExists(selectDataArray))
		return $""
	endif

	WAVE/Z/WAVE result = $""

	for(WAVE/Z/WAVE selectDataComp : selectDataArray)

		if(!WaveExists(selectDataComp))
			continue
		endif

		WAVE/Z    selectData = selectDataComp[%SELECTION]
		WAVE/WAVE sweepData  = SF_OperationAnaFuncParamImpl(graph, names, selectData, opShort)
		if(!WaveExists(sweepData))
			continue
		endif

		if(!WaveExists(result))
			WAVE/WAVE result = sweepData
			continue
		endif

		Concatenate/FREE/WAVE/NP {sweepData}, result
	endfor

	return result
End

/// Gather all requested analysis function parameters with wildcard support
///
/// @param names     requested analysis function parameter names, can include wildcards
/// @param lbnParams wave reference wave, one wave per selectData entry, with
///                  the analysis function parameter data from the labnotebook including JWN
///                  metadata
///
/// @return expanded analysis function parameter names (i.e. without wildcards) which match at least in one selectData entry
static Function/WAVE SF_OperationAnaFuncParamImplAllNames(WAVE/T names, WAVE/WAVE lbnParams)

	variable i, numAvailableParams, j, numRequestedParams
	string params, reqName, namesPerLBNEntry, gatheredNames

	numAvailableParams = DimSize(lbnParams, ROWS)
	numRequestedParams = DimSize(names, ROWS)

	for(i = 0; i < numAvailableParams; i += 1)
		WAVE/T paramsSingle = lbnParams[i]
		params = JWN_GetStringFromWaveNote(paramsSingle, SF_META_TAG_TEXT)

		gatheredNames = AFH_GetListOfAnalysisParamNames(params)

		for(j = 0; j < numRequestedParams; j += 1)
			reqName = names[j]

			namesPerLBNEntry = ListMatch(gatheredNames, reqName)

			if(IsEmpty(namesPerLBNEntry))
				continue
			endif

			WAVE wv = ListToTextWave(namesPerLBNEntry, ";")

			Concatenate/NP=(ROWS)/FREE {wv}, allNames
		endfor
	endfor

	if(!WaveExists(allNames))
		return $""
	endif

	return GetUniqueEntries(allNames)
End

static Function/WAVE SF_OperationAnaFuncParamImpl(string graph, WAVE/T names, WAVE/Z selectData, string opShort)

	variable numReqNames, numFoundParams, i, j, idx, sweepNo, chanType, chanNr, colorGroup, colorGroupFound, nextFreeIndex, marker
	string params, name, type

	if(!WaveExists(selectData))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_ANAFUNCPARAM)
		return output
	endif

	WAVE/WAVE allParams   = SF_OperationLabnotebookImpl(graph, {ANALYSIS_FUNCTION_PARAMS_LBN}, selectData, DATA_ACQUISITION_MODE, opShort)
	WAVE/Z/T  allReqNames = SF_OperationAnaFuncParamImplAllNames(names, allParams)

	if(!WaveExists(allReqNames))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_ANAFUNCPARAM)
		return output
	endif

	numFoundParams = DimSize(allParams, ROWS)
	numReqNames    = DimSize(allReqNames, ROWS)

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numReqNames * numFoundParams)

	for(i = 0; i < numReqNames; i += 1)
		name       = allReqNames[i]
		colorGroup = GetUniqueInteger()

		marker = SFH_GetPlotMarkerCodeSelection(i)

		for(j = 0; j < numFoundParams; j += 1)
			WAVE/T paramsSingle = allParams[j]
			params = JWN_GetStringFromWaveNote(paramsSingle, SF_META_TAG_TEXT)
			type   = AFH_GetAnalysisParamType(name, params, typeCheck = 0)

			strswitch(type)
				case "variable":
					Make/FREE/D out = {AFH_GetAnalysisParamNumerical(name, params)}
					break
				case "string": // fallthrough
				case "wave": // fallthrough
				case "textwave":
					Make/FREE/D out = {0.0}
					JWN_SetWaveInWaveNote(out, SF_META_TRACECOLOR, {0, 0, 0, 0})
					JWN_SetStringInWaveNote(out, SF_META_TAG_TEXT, PrepareListForDisplay(AFH_GetAnalysisParameterAsText(name, params)))
					break
				case "":
					// unknown name or labnotebook entry not present
					Make/FREE/D out = {NaN}
					break
				default:
					FATAL_ERROR("Unsupported parameter type: " + type)
			endswitch

			sweepNo  = JWN_GetNumberFromWaveNote(paramsSingle, SF_META_SWEEPNO)
			chanType = JWN_GetNumberFromWaveNote(paramsSingle, SF_META_CHANNELTYPE)
			chanNr   = JWN_GetNumberFromWaveNote(paramsSingle, SF_META_CHANNELNUMBER)

			JWN_SetNumberInWaveNote(out, SF_META_SWEEPNO, sweepNo)
			JWN_SetNumberInWaveNote(out, SF_META_CHANNELTYPE, chanType)
			JWN_SetNumberInWaveNote(out, SF_META_CHANNELNUMBER, chanNr)
			JWN_SetWaveInWaveNote(out, SF_META_XVALUES, {sweepNo})

			JWN_SetStringInWaveNote(out, SF_META_LEGEND_LINE_PREFIX, name)
			JWN_SetNumberInWaveNote(out, SF_META_COLOR_GROUP, colorGroup)
			JWN_SetNumberInWaveNote(out, SF_META_MOD_MARKER, marker)

			output[idx] = out
			idx        += 1
		endfor
	endfor

	Redimension/N=(idx) output

	JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, "Analysis function parameters")
	JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, "Sweeps")
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_ANAFUNCPARAM)

	return output
End

/// `labnotebook(array keys[, array selectData [, string entrySourceType]])`
///
/// return lab notebook @p key for all @p sweeps that belong to the channels @p channels
static Function/WAVE SF_OperationLabnotebook(variable jsonId, string jsonPath, string graph)

	variable numArgs, mode
	string lbnKey, modeTxt

	SFH_CheckArgumentCount(jsonID, jsonPath, SF_OP_LABNOTEBOOK, 1, maxArgs = 3)

	Make/FREE/T allowedValuesMode = {"UNKNOWN_MODE", "DATA_ACQUISITION_MODE", "TEST_PULSE_MODE", "NUMBER_OF_LBN_DAQ_MODES"}
	modeTxt = SFH_GetArgumentAsText(jsonID, jsonPath, graph, SF_OP_LABNOTEBOOK, 2, allowedValues = allowedValuesMode, defValue = "DATA_ACQUISITION_MODE")
	mode    = ParseLogbookMode(modeTxt)

	WAVE/Z selectData = SFH_GetArgumentSelect(jsonID, jsonPath, graph, SF_OP_LABNOTEBOOK, 1)

	WAVE/T lbnKeys = SFH_GetArgumentAsWave(jsonID, jsonPath, graph, SF_OP_LABNOTEBOOK, 0, expectedMajorType = IGOR_TYPE_TEXT_WAVE, singleResult = 1)

	WAVE/Z/WAVE output = SF_OperationLabnotebookIterate(graph, lbnKeys, selectData, mode, SF_OP_LABNOTEBOOK)
	if(!WaveExists(output))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_LABNOTEBOOK, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_LABNOTEBOOK)
	endif

	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_LABNOTEBOOK, ""))
	JWN_SetStringInWaveNote(output, SF_META_WINDOW_HOOK, "TraceValueDisplayHook")

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_LABNOTEBOOK)
End

static Function/WAVE SF_OperationLabnotebookIterate(string graph, WAVE/T lbnKeys, WAVE/Z/WAVE selectDataArray, variable mode, string opShort)

	if(!WaveExists(selectDataArray))
		return $""
	endif

	WAVE/Z/WAVE result = $""

	for(WAVE/Z/WAVE selectDataComp : selectDataArray)

		if(!WaveExists(selectDataComp))
			continue
		endif

		WAVE/Z    selectData = selectDataComp[%SELECTION]
		WAVE/WAVE lbnData    = SF_OperationLabnotebookImpl(graph, lbnKeys, selectData, mode, opShort)
		if(!WaveExists(lbnData))
			continue
		endif

		if(!WaveExists(result))
			WAVE/WAVE result = lbnData
			continue
		endif

		Concatenate/FREE/WAVE/NP {lbnData}, result
	endfor

	return result
End

static Function/WAVE SF_OperationLabnotebookImpl(string graph, WAVE/T LBNKeys, WAVE/Z selectData, variable mode, string opShort)

	variable i, numSelected, idx, lbnIndex
	variable numOutputWaves, colorGroup, marker
	string lbnKey, refUnit, unitString

	if(!WaveExists(selectData))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_LABNOTEBOOK)
		return output
	endif

	WAVE/Z/T allLBNKeys = SFH_OperationLabnotebookExpandKeys(graph, LBNKeys, selectData, mode)

	if(!WaveExists(allLBNKeys))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_LABNOTEBOOK)
		return output
	endif

	numSelected    = DimSize(selectData, ROWS)
	numOutputWaves = numSelected * DimSize(allLBNKeys, ROWS)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numOutputWaves)

	for(lbnKey : allLBNKeys)
		colorGroup = GetUniqueInteger()
		marker     = SFH_GetPlotMarkerCodeSelection(lbnIndex)
		lbnIndex  += 1

		for(i = 0; i < numSelected; i += 1)
			WAVE out = SF_OperationLabnotebookImplGetEntry(graph, selectData, i, lbnKey, mode)

			JWN_SetNumberInWaveNote(out, SF_META_COLOR_GROUP, colorGroup)
			JWN_SetNumberInWaveNote(out, SF_META_MOD_MARKER, marker)

			output[idx] = out
			idx        += 1
		endfor
	endfor

	WAVE/T units = SF_GetLabnotebookEntryUnits(graph, allLBNKeys, selectData)

	if(DimSize(units, ROWS) == 1)
		refUnit = units[0]

		if(!cmpstr(refUnit, LABNOTEBOOK_BINARY_UNIT))
			WAVE/Z/T matches = GrepTextWave(allLBNKeys, "^.* QC$")

			Make/FREE/D yTickPositions = {0, 1}
			Make/FREE/T/N=2 yTickLabels

			if(WaveExists(matches) && DimSize(matches, ROWS) == DimSize(allLBNKeys, ROWS))
				yTickLabels[] = UpperCaseFirstChar(ToPassFail(yTickPositions[p]))
			else
				yTickLabels[] = UpperCaseFirstChar(ToOnOff(yTickPositions[p]))
			endif

			JWN_SetWaveInWaveNote(output, SF_META_YTICKPOSITIONS, yTickPositions)
			JWN_SetWaveInWaveNote(output, SF_META_YTICKLABELS, yTickLabels)
		else
			// other specializations on labnotebook units

			if(!IsEmpty(refUnit))
				sprintf unitString, "Unit (%s)", refUnit
				JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, unitString)
			endif
		endif
	endif

	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_LABNOTEBOOK)
	JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, "Sweeps")

	SF_SetSweepXAxisTickLabels(output, selectData)

	return output
End

static Function/WAVE SF_OperationLabnotebookImplGetEntry(string graph, WAVE selectData, variable index, string lbnKey, variable mode)

	variable sweepNo, chanNr, chanType, settingsIndex, result, col, mapIndex
	string entry

	sweepNo  = selectData[index][%SWEEP]
	chanNr   = selectData[index][%CHANNELNUMBER]
	chanType = selectData[index][%CHANNELTYPE]
	mapIndex = selectData[index][%SWEEPMAPINDEX]

	Make/FREE/D out = {NaN}

	JWN_SetNumberInWaveNote(out, SF_META_SWEEPNO, sweepNo)
	JWN_SetNumberInWaveNote(out, SF_META_CHANNELTYPE, chanType)
	JWN_SetNumberInWaveNote(out, SF_META_CHANNELNUMBER, chanNr)
	JWN_SetNumberInWaveNote(out, SF_META_SWEEPMAPINDEX, mapIndex)
	JWN_SetWaveInWaveNote(out, SF_META_XVALUES, {sweepNo})
	JWN_SetStringInWaveNote(out, SF_META_LEGEND_LINE_PREFIX, lbnKey)

	if(!IsValidSweepNumber(sweepNo))
		return out
	endif

	WAVE numericalValues = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_VALUES)
	WAVE textualValues   = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_TEXTUAL_VALUES)

	[WAVE settings, settingsIndex] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, lbnKey, chanNr, chanType, mode)
	if(!WaveExists(settings))
		return out
	endif

	if(IsNumericWave(settings))
		out[0] = {settings[settingsIndex]}
	elseif(IsTextWave(settings))
		out[0] = {0.0}
		WAVE/T settingsT = settings

		entry = PrepareListForDisplay(settingsT[settingsIndex])

		JWN_SetWaveInWaveNote(out, SF_META_TRACECOLOR, {0, 0, 0, 0})
		JWN_SetStringInWaveNote(out, SF_META_TAG_TEXT, entry)
	else
		FATAL_ERROR("Invalid type")
	endif

	return out
End

static Function/S SF_GetLabnotebookEntryUnits_Impl(WAVE numericalKeys, WAVE textualKeys, string entry)

	variable result, col
	string unit

	[result, unit, col] = LBN_GetEntryProperties(numericalKeys, entry)

	if(!result)
		return unit
	endif

	[result, unit, col] = LBN_GetEntryProperties(textualKeys, entry)

	if(!result)
		return unit
	endif

	return ""
End

static Function/WAVE SF_GetLabnotebookEntryUnits(string graph, WAVE/T allLBNKeys, WAVE selectData)

	variable sweepNo, mapIndex

	sweepNo  = selectData[0][%SWEEP]
	mapIndex = selectData[0][%SWEEPMAPINDEX]

	WAVE numericalKeys = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_KEYS)
	WAVE textualKeys   = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_TEXTUAL_KEYS)

	Make/FREE/T/N=(DimSize(allLBNKeys, ROWS)) units = SF_GetLabnotebookEntryUnits_Impl(numericalKeys, textualKeys, allLBNKeys[p])

	WAVE/Z/T unitsUnique = GetUniqueEntries(units)

	return unitsUnique
End

static Function/WAVE SFH_OperationLabnotebookExpandKeys(string graph, WAVE/T LBNKeys, WAVE selectData, variable mode)

	variable i, j, numSelected, numKeys, sweepNo
	string key

	numKeys = DimSize(LBNKeys, ROWS)

	Make/FREE/N=(numKeys) hasWC = HasWildcardSyntax(LBNKeys[p])

	if(IsConstant(hasWC, 0))
		return LBNKeys
	endif

	numSelected = DimSize(selectData, ROWS)
	for(i = 0; i < numSelected; i += 1)
		sweepNo = selectData[i][%SWEEP]

		WAVE/Z textualValues   = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)
		WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)

		WAVE/Z/T entries = LBV_GetAllLogbookParamNames(textualValues, numericalValues)

		if(!WaveExists(entries))
			continue
		endif

		for(j = 0; j < numKeys; j += 1)
			key = LBNKeys[j]
			WAVE/Z indizes = FindIndizes(entries, str = key, prop = PROP_WILDCARD)

			if(WaveExists(indizes))
				Make/FREE/N=(DimSize(indizes, ROWS))/T matches = entries[indizes[p]]
				Concatenate/NP=(ROWS)/T/FREE {matches}, allLBNKeys
			endif
		endfor
	endfor

	if(!WaveExists(allLBNKeys))
		return $""
	endif

	WAVE allLBNKeysUnique = GetUniqueEntries(allLBNKeys)

	return allLBNKeysUnique
End

static Function SF_SetSweepXAxisTickLabels(WAVE output, WAVE/Z selectDataPlainOrArray)

	variable numSelected

	if(!WaveExists(selectDataPlainOrArray))
		return NaN
	endif

	if(IsWaveRefWave(selectDataPlainOrArray))
		if(DimSize(selectDataPlainOrArray, ROWS) > 1)
			return NaN
		endif

		WAVE/WAVE selectDataArray = selectDataPlainOrArray

		WAVE/WAVE singleSelectData = selectDataArray[0]
		WAVE/Z    selectData       = singleSelectData[%SELECTION]

		if(!WaveExists(selectData))
			return NaN
		endif
	else
		WAVE selectData = selectDataPlainOrArray
	endif

	numSelected = DimSize(selectData, ROWS)

	Make/FREE/N=(numSelected) xTickPositions = selectData[p][%SWEEP]
	Make/T/FREE/N=(numSelected) xTickLabels = num2str(selectData[p][%SWEEP])

	JWN_SetWaveInWaveNote(output, SF_META_XTICKPOSITIONS, xTickPositions)
	JWN_SetWaveInWaveNote(output, SF_META_XTICKLABELS, xTickLabels)
End

static Function/WAVE SF_OperationLog(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_LOG)
	elseif(numArgs == 1)
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	else
		WAVE/WAVE input = SFH_CreateSFRefWave(graph, SF_OP_LOG, 0)
	endif

	for(w : input)
		SF_OperationLogImpl(w)
	endfor

	SFH_TransferFormulaDataWaveNoteAndMeta(input, input, SF_OP_LOG, JWN_GetStringFromWaveNote(input, SF_META_DATATYPE))

	return SFH_GetOutputForExecutor(input, graph, SF_OP_LOG)
End

static Function SF_OperationLogImpl(WAVE/Z input)

	if(!WaveExists(input))
		return NaN
	endif

	if(!DimSize(input, ROWS))
		return NaN
	endif

	if(IsTextWave(input))
		WAVE/T wt = input
		print wt[0]
	elseif(IsWaveRefWave(input))
		for(WAVE elem : input)
			SF_OperationLogImpl(elem)
		endfor
	else
		print input[0]
	endif
End

static Function/WAVE SF_OperationLog10(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_LOG10)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_LOG10, DimSize(input, ROWS))

	output[] = SF_OperationLog10Impl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_LOG10, JWN_GetStringFromWaveNote(input, SF_META_DATATYPE))

	return SFH_GetOutputForExecutor(output, graph, SF_OP_LOG10, clear = input)
End

static Function/WAVE SF_OperationLog10Impl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif
	SFH_ASSERT(IsNumericWave(input), "log10 requires numeric input data.")
	MatrixOP/FREE output = log(input)
	SF_FormulaWaveScaleTransfer(input, output, SF_TRANSFER_ALL_DIMS, NaN)

	return output
End

static Function/WAVE SF_OperationCursors(variable jsonId, string jsonPath, string graph)

	variable i
	string   info
	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)
	if(!numArgs)
		Make/FREE/T wvT = {"A", "B"}
		numArgs = 2
	else
		Make/FREE/T/N=(numArgs) wvT
		for(i = 0; i < numArgs; i += 1)
			WAVE/T csrName = SFH_ResolveDatasetElementFromJSON(jsonId, jsonPath, graph, SF_OP_CURSORS, i, checkExist = 1)
			SFH_ASSERT(IsTextWave(csrName), "cursors argument at " + num2istr(i) + " must be textual.")
			wvT[i] = csrName[0]
		endfor
	endif
	Make/FREE/N=(numArgs)/D out = NaN
	for(i = 0; i < numArgs; i += 1)
		SFH_ASSERT(GrepString(wvT[i], "^(?i)[A-J]$"), "Invalid Cursor Name")
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

	return SFH_GetOutputForExecutorSingle(out, graph, SF_OP_CURSORS, discardOpStack = 1)
End

// findlevel(data, level, [edge])
static Function/WAVE SF_OperationFindLevel(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)
	SFH_ASSERT(numArgs <= 3, "Findlevel has 3 arguments at most.")
	SFH_ASSERT(numArgs > 1, "Findlevel needs at least two arguments.")
	WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 0)
	WAVE      level = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_FINDLEVEL, 1, checkExist = 1)
	SFH_ASSERT(DimSize(level, ROWS) == 1, "Too many input values for parameter level")
	SFH_ASSERT(IsNumericWave(level), "level parameter must be numeric")
	if(numArgs == 3)
		WAVE edge = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, SF_OP_FINDLEVEL, 2, checkExist = 1)
		SFH_ASSERT(DimSize(edge, ROWS) == 1, "Too many input values for parameter edge")
		SFH_ASSERT(IsNumericWave(edge), "edge parameter must be numeric")
		SFH_ASSERT(edge[0] == FINDLEVEL_EDGE_BOTH || edge[0] == FINDLEVEL_EDGE_INCREASING || edge[0] == FINDLEVEL_EDGE_DECREASING, "edge parameter is invalid")
	else
		Make/FREE edge = {FINDLEVEL_EDGE_BOTH}
	endif

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_FINDLEVEL, DimSize(input, ROWS))
	output = FindLevelWrapper(input[p], level[0], edge[0], FINDLEVEL_MODE_SINGLE)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_FINDLEVEL, SF_DATATYPE_FINDLEVEL)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_FINDLEVEL)
End

// apfrequency(data, [frequency calculation method], [spike detection crossing level], [result value type], [normalize], [x-axis type])
static Function/WAVE SF_OperationApFrequency(variable jsonId, string jsonPath, string graph)

	variable i, numArgs, keepX, method, level, normValue
	string xLabel, methodStr, timeFreq, normalize, xAxisType
	string   opShort    = SF_OP_APFREQUENCY
	variable numArgsMin = 1
	variable numArgsMax = 6

	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)
	SFH_ASSERT(numArgs <= numArgsMax, "ApFrequency has " + num2istr(numArgsMax) + " arguments at most.")
	SFH_ASSERT(numArgs >= numArgsMin, "ApFrequency needs at least " + num2istr(numArgsMin) + " argument(s).")

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 0)
	method    = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, opShort, 1, defValue = SF_APFREQUENCY_FULL, allowedValues = {SF_APFREQUENCY_FULL, SF_APFREQUENCY_INSTANTANEOUS, SF_APFREQUENCY_APCOUNT, SF_APFREQUENCY_INSTANTANEOUS_PAIR})
	level     = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, opShort, 2, defValue = 0)
	timeFreq  = SFH_GetArgumentAsText(jsonId, jsonPath, graph, opShort, 3, defValue = SF_OP_APFREQUENCY_Y_FREQ, allowedValues = {SF_OP_APFREQUENCY_Y_TIME, SF_OP_APFREQUENCY_Y_FREQ})
	normalize = SFH_GetArgumentAsText(jsonId, jsonPath, graph, opShort, 4, defValue = SF_OP_APFREQUENCY_NONORM, allowedValues = {                                      \
	                                                                                                                             SF_OP_APFREQUENCY_NONORM,             \
	                                                                                                                             SF_OP_APFREQUENCY_NORMOVERSWEEPSMIN,  \
	                                                                                                                             SF_OP_APFREQUENCY_NORMOVERSWEEPSMAX,  \
	                                                                                                                             SF_OP_APFREQUENCY_NORMOVERSWEEPSAVG,  \
	                                                                                                                             SF_OP_APFREQUENCY_NORMWITHINSWEEPMIN, \
	                                                                                                                             SF_OP_APFREQUENCY_NORMWITHINSWEEPMAX, \
	                                                                                                                             SF_OP_APFREQUENCY_NORMWITHINSWEEPAVG  \
	                                                                                                                            })
	xAxisType = SFH_GetArgumentAsText(jsonId, jsonPath, graph, opShort, 5, defValue = SF_OP_APFREQUENCY_X_TIME, allowedValues = {SF_OP_APFREQUENCY_X_TIME, SF_OP_APFREQUENCY_X_COUNT})

	WAVE/T argSetup = SFH_GetNewArgSetupWave(numArgsMax - 1)

	argSetup[0][%KEY]   = "Method"
	argSetup[0][%VALUE] = SF_OperationApFrequencyMethodToString(method)
	argSetup[1][%KEY]   = "Level"
	argSetup[1][%VALUE] = num2str(level)
	argSetup[2][%KEY]   = "ResultType"
	argSetup[2][%VALUE] = timeFreq
	argSetup[3][%KEY]   = "Normalize"
	argSetup[3][%VALUE] = normalize
	argSetup[4][%KEY]   = "XAxisType"
	argSetup[4][%VALUE] = xAxisType

	normValue = NaN
	Make/FREE/D/N=0 normMean
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, DimSize(input, ROWS))
	output = SF_OperationApFrequencyImpl(input[p], level, method, timeFreq, normalize, xAxisType, normValue, normMean)
	if(!CmpStr(normalize, SF_OP_APFREQUENCY_NORMOVERSWEEPSAVG) && DimSize(normMean, ROWS))
		normValue = mean(normMean)
		SF_OperationApFrequencyNormalizeOverSweeps(output, normValue)
	elseif((!CmpStr(normalize, SF_OP_APFREQUENCY_NORMOVERSWEEPSMIN) || !CmpStr(normalize, SF_OP_APFREQUENCY_NORMOVERSWEEPSMAX)) && !IsNaN(normValue))
		SF_OperationApFrequencyNormalizeOverSweeps(output, normValue)
	endif

	if(method == SF_APFREQUENCY_INSTANTANEOUS_PAIR)
		keepX  = 1
		xLabel = SelectString(!CmpStr(xAxisType[0], SF_OP_APFREQUENCY_X_COUNT), "ms", "peak number")
		JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, xLabel)
	endif

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, opShort, SF_DATATYPE_APFREQUENCY, keepX = keepX, argSetup = argSetup)

	return SFH_GetOutputForExecutor(output, graph, opShort)
End

static Function SF_OperationApFrequencyNormalizeOverSweeps(WAVE/WAVE output, variable normValue)

	Make/FREE/D/N=(DimSize(output, ROWS)) idxHelper
	idxHelper = SF_OperationApFrequencyNormalizeOverSweepsImpl(output[p], normValue)
End

static Function SF_OperationApFrequencyNormalizeOverSweepsImpl(WAVE/Z data, variable normValue)

	if(!WaveExists(data))
		return NaN
	endif

	MultiThread data /= normValue
End

static Function/WAVE SF_OperationApFrequencyImpl(WAVE/Z data, variable level, variable method, string yStr, string normStr, string xAxisTypeStr, variable &normOSValue, WAVE normMean)

	variable numPeaks, yModeTime, xAxisCount, normalize, normISValue
	string yUnit

	if(!WaveExists(data))
		return $""
	endif

	yModeTime  = !CmpStr(yStr, SF_OP_APFREQUENCY_Y_TIME)
	xAxisCount = !CmpStr(xAxisTypeStr, SF_OP_APFREQUENCY_X_COUNT)
	normalize  = CmpStr(normStr, SF_OP_APFREQUENCY_NONORM)

	WAVE peaksAt = FindLevelWrapper(data, level, FINDLEVEL_EDGE_INCREASING, FINDLEVEL_MODE_MULTI)
	numPeaks = str2num(GetDimLabel(peaksAt, ROWS, 0))
	Redimension/N=(1, numPeaks) peaksAt

	// @todo we assume that the x-axis of data has a ms scale for FULL/INSTANTANEOUS
	switch(method)
		case SF_APFREQUENCY_FULL:
			// number_of_peaks / sweep_length
			Make/FREE/D outD = {numPeaks / (DimDelta(data, ROWS) * DimSize(data, ROWS) * MILLI_TO_ONE)}
			yUnit = SelectString(normalize, "Hz [Full]", "normalized frequency [Full]")
			SetScale/P y, DimOffset(outD, ROWS), DimDelta(outD, ROWS), yUnit, outD
			break
		case SF_APFREQUENCY_INSTANTANEOUS:
			if(numPeaks <= 1)
				return $""
			endif

			Make/FREE/D outD = {SF_ApFrequencyInstantaneous(peaksAt)}
			yUnit = SelectString(normalize, "Hz [Instantaneous]", "normalized frequency [Instantaneous]")
			SetScale/P y, DimOffset(outD, ROWS), DimDelta(outD, ROWS), yUnit, outD
			break
		case SF_APFREQUENCY_INSTANTANEOUS_PAIR:
			if(numPeaks <= 1)
				return $""
			endif

			WAVE outD = SF_ApFrequencyInstantaneousPairs(peaksAt, yModeTime, xAxisCount)
			if(yModeTime)
				yUnit = SelectString(normalize, "s [inst pairs]", "normalized time [inst pairs]")
			else
				yUnit = SelectString(normalize, "Hz [inst pairs]", "normalized frequency [inst pairs]")
			endif
			SetScale/P y, DimOffset(outD, ROWS), DimDelta(outD, ROWS), yUnit, outD
			break
		case SF_APFREQUENCY_APCOUNT:
			Make/FREE/D outD = {numPeaks}
			SetScale/P y, DimOffset(outD, ROWS), DimDelta(outD, ROWS), "peaks [APCount]", outD
			break
		default:
			FATAL_ERROR("Unsupported method")
			break
	endswitch

	if(normalize)
		if(!CmpStr(normStr, SF_OP_APFREQUENCY_NORMWITHINSWEEPMIN))
			normISValue = WaveMin(outD)
			MultiThread outD /= normISValue
		elseif(!CmpStr(normStr, SF_OP_APFREQUENCY_NORMWITHINSWEEPMAX))
			normISValue = WaveMax(outD)
			MultiThread outD /= normISValue
		elseif(!CmpStr(normStr, SF_OP_APFREQUENCY_NORMWITHINSWEEPAVG))
			normISValue = mean(outD)
			MultiThread outD /= normISValue
		elseif(!CmpStr(normStr, SF_OP_APFREQUENCY_NORMOVERSWEEPSMIN))
			normOSValue = IsNaN(normOSValue) ? WaveMin(outD) : min(normOSValue, WaveMin(outD))
		elseif(!CmpStr(normStr, SF_OP_APFREQUENCY_NORMOVERSWEEPSMAX))
			normOSValue = IsNaN(normOSValue) ? WaveMax(outD) : max(normOSValue, WaveMax(outD))
		elseif(!CmpStr(normStr, SF_OP_APFREQUENCY_NORMOVERSWEEPSAVG))
			Concatenate/FREE/NP {outD}, normMean
		else
			FATAL_ERROR("Unknown normalization method")
		endif
	endif

	return outD
End

static Function/S SF_OperationApFrequencyMethodToString(variable method)

	switch(method)
		case SF_APFREQUENCY_FULL:
			return "Full"
		case SF_APFREQUENCY_INSTANTANEOUS:
			return "Instantaneous"
		case SF_APFREQUENCY_INSTANTANEOUS_PAIR:
			return "Instantaneous Pair"
		case SF_APFREQUENCY_APCOUNT:
			return "APCount"
		default:
			FATAL_ERROR("Unknown apfrequency method")
	endswitch
End

static Function SF_ApFrequencyInstantaneous(WAVE peaksAt)

	variable numPeaks

	numPeaks = DimSize(peaksAt, COLS)
	ASSERT(numPeaks > 1, "Number of peaks must be greater than 1 to calculate pairs.")

	Make/FREE/D/N=(numPeaks - 1) distances
	distances[0, numPeaks - 2] = peaksAt[0][p + 1] - peaksAt[0][p]
	return 1.0 / (mean(distances) * MILLI_TO_ONE)
End

static Function/WAVE SF_ApFrequencyInstantaneousPairs(WAVE peaksAt, variable yModeTime, variable xAxisIsCounts)

	variable numPeaks

	numPeaks = DimSize(peaksAt, COLS)
	ASSERT(numPeaks > 1, "Number of peaks must be greater than 1 to calculate pairs.")

	Make/FREE/D/N=(numPeaks - 1) result, xAxisvalues

	xAxisvalues = xAxisIsCounts ? p : peaksAt[0][p]
	JWN_SetWaveInWaveNote(result, SF_META_XVALUES, xAxisvalues)

	result = (peaksAt[0][p + 1] - peaksAt[0][p]) * MILLI_TO_ONE
	if(!yModeTime)
		FastOp result = 1.0 / result
	endif

	return result
End

// `store(name, ...)`
static Function/WAVE SF_OperationStore(variable jsonId, string jsonPath, string graph)

	string rawCode, preProcCode, name
	variable maxEntries, numEntries

	SFH_ASSERT(SFH_GetNumberOfArguments(jsonID, jsonPath) == 2, "Function accepts only two arguments")

	name = SFH_GetArgumentAsText(jsonID, jsonPath, graph, SF_OP_STORE, 0)

	WAVE/WAVE dataRef = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 1)

	[rawCode, preProcCode] = SF_GetCode(graph)

	[WAVE/T keys, WAVE/T values] = SFH_CreateResultsWaveWithCode(graph, rawCode, data = dataRef, name = name, resultType = SFH_RESULT_TYPE_STORE)

	ED_AddEntriesToResults(values, keys, SWEEP_FORMULA_RESULT)

	// return second argument unmodified
	return SFH_GetOutputForExecutor(dataRef, graph, SF_OP_STORE)
End

static Function/WAVE SF_SplitCodeToGraphs(string code)

	string group0, group1
	variable graphCount, size

	WAVE/T graphCode = GetYvsXFormulas()

	do
		SplitString/E=SF_SWEEPFORMULA_GRAPHS_REGEXP code, group0, group1
		if(!IsEmpty(group0))
			EnsureLargeEnoughWave(graphCode, dimension = ROWS, indexShouldExist = graphCount)
			graphCode[graphCount] = group0
			graphCount           += 1
			code                  = group1
		endif
	while(!IsEmpty(group1))
	Redimension/N=(graphCount) graphCode

	return graphCode
End

static Function [string xFormula, string yFormula] SF_SplitGraphsToFormula(string graphCode)

	variable numFormulae

	SplitString/E=SF_SWEEPFORMULA_REGEXP graphCode, yFormula, xFormula
	numFormulae = V_Flag

	if(numFormulae != 1 && numFormulae != 2)
		return ["", ""]
	endif

	xFormula = SelectString(numFormulae == 2, "", xFormula)

	return [xFormula, yFormula]
End

static Function/S SF_GetFormulaWinNameTemplate(string mainWindow)

	return BSP_GetFormulaGraph(mainWindow) + "_"
End

Function SF_button_sweepFormula_tofront(STRUCT WMButtonAction &ba) : ButtonControl

	string winNameTemplate, wList, wName
	variable numWins, i

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here
			winNameTemplate = SF_GetFormulaWinNameTemplate(GetMainWindow(ba.win))
			wList           = WinList(winNameTemplate + "*", ";", "WIN:65")
			numWins         = ItemsInList(wList)
			for(i = 0; i < numWins; i += 1)
				wName = StringFromList(i, wList)
				DoWindow/F $wName
				DoIgorMenu "Control", "Retrieve Window"
			endfor

			break
		default:
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

static Function/WAVE SF_AverageTPFromSweep(WAVE/T epochMatches, WAVE sweepData)

	variable numTPEpochs, tpDataSizeMin, tpDataSizeMax, sweepDelta

	numTPEpochs = DimSize(epochMatches, ROWS)
	sweepDelta  = DimDelta(sweepData, ROWS)
	Make/FREE/D/N=(numTPEpochs) tpStart = trunc(str2num(epochMatches[p][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI / sweepDelta)
	Make/FREE/D/N=(numTPEpochs) tpDelta = trunc(str2num(epochMatches[p][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI / sweepDelta) - tpStart[p]
	[tpDataSizeMin, tpDataSizeMax] = WaveMinAndMax(tpDelta)
	SFH_ASSERT((tpDataSizeMax - tpDataSizeMin) <= 1, "TP data size from TP epochs mismatch within sweep.")

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

	WAVE/Z/T entries = SF_GetAllOldCode()

	if(!WaveExists(entries))
		return $""
	endif

	entries[] = num2str(p) + ": " + ElideText(ReplaceString("\n", entries[p], " "), 60)

	WAVE/Z/T splittedMenu = PEXT_SplitToSubMenus(entries, method = PEXT_SUBSPLIT_ALPHA)

	PEXT_GenerateSubMenuNames(splittedMenu)

	return splittedMenu
End

static Function/WAVE SF_GetAllOldCode()

	WAVE/T textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)

	return GetUniqueSettings(textualResultsValues, "Sweep Formula code")
End

Function SF_PopMenuProc_OldCode(STRUCT WMPopupAction &pa) : PopupMenuControl

	string sweepFormulaNB, bsPanel, code
	variable index

	switch(pa.eventCode)
		case 2: // mouse up
			if(!cmpstr(pa.popStr, NONE))
				break
			endif

			bsPanel        = BSP_GetPanel(pa.win)
			sweepFormulaNB = BSP_GetSFFormula(bsPanel)
			WAVE/Z/T entries = SF_GetAllOldCode()
			// -2 as we have NONE
			index = str2num(pa.popStr)
			code  = entries[index]

			// translate back from \n to \r
			code = ReplaceString("\n", code, "\r")

			ReplaceNotebookText(sweepFormulaNB, code)
			PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display", val = CHECKBOX_SELECTED)
			break
		default:
			break
	endswitch

	return 0
End

// Returns a RGB color for a severity values
static Function [STRUCT RGBColor s] SF_GetErrorColorsFromSeverity(variable severity)

	WAVE sfColors = GetSFErrorColorWave()
	switch(severity)
		case SF_MSG_OK:
			s.red   = sfColors[%OK][%R]
			s.green = sfColors[%OK][%G]
			s.blue  = sfColors[%OK][%B]
			break
		case SF_MSG_WARN:
			s.red   = sfColors[%WARN][%R]
			s.green = sfColors[%WARN][%G]
			s.blue  = sfColors[%WARN][%B]
			break
		case SF_MSG_ERROR:
			s.red   = sfColors[%ERROR][%R]
			s.green = sfColors[%ERROR][%G]
			s.blue  = sfColors[%ERROR][%B]
			break
		default:
			FATAL_ERROR("Unknown Severity")
	endswitch
End

// Use this function from within SF to set an error state
Function SF_SetOutputState(string error, variable severity)

	ASSERT(!IsNull(error), "Error can not be a null string")
	ASSERT(severity == SF_MSG_ERROR || severity == SF_MSG_OK || severity == SF_MSG_WARN, "Unknown severity for SF error")

	NVAR sfSeverity = $GetSweepFormulaOutputSeverity()
	sfSeverity = severity

	SVAR sfError = $GetSweepFormulaOutputMessage()
	sfError = error

#ifdef DEBUGGING_ENABLED
	SFP_LogParserErrorState(error)
#endif // DEBUGGING_ENABLED
End

// Sets a formula in the SweepFormula notebook of the given data/sweepbrowser
Function SF_SetFormula(string databrowser, string formula)

	string nb = BSP_GetSFFormula(databrowser)
	ReplaceNotebookText(nb, formula)
End

/// @brief Executes a given formula without changing the current SweepFormula notebook
///        supports by default variable assignments
///        does not support "with" and "and" keywords
/// @param formula formula string to execute
/// @param graph name of databrowser window
/// @param singleResult [optional, default 0], if set then the first dataSet is retrieved from the waveRef wave and returned, the waveRef wave is disposed
/// @param checkExist [optional, default 0], only valid if singleResult=1, if set then the data wave in the single dataSet retrieved must exist
/// @param useVariables [optional, default 1], when not set, hint the function that the formula string contains only an expression and no variable definitions
Function/WAVE SF_ExecuteFormula(string formula, string graph, [variable singleResult, variable checkExist, variable useVariables])

	variable jsonId

	singleResult = ParamIsDefault(singleResult) ? 0 : !!singleResult
	checkExist   = ParamIsDefault(checkExist) ? 0 : !!checkExist
	useVariables = ParamIsDefault(useVariables) ? 1 : !!useVariables

	formula = SF_PreprocessInput(formula)
	if(useVariables)
		formula = SF_ExecuteVariableAssignments(graph, formula)
	endif
	jsonId = SFP_ParseFormulaToJSON(formula)
	WAVE/Z result = SF_FormulaExecutor(graph, jsonId)
	JSON_Release(jsonId, ignoreErr = 1)

	WAVE/WAVE out = SF_ResolveDataset(result)
	if(singleResult)
		SFH_ASSERT(DimSize(out, ROWS) == 1, "Expected only a single dataSet")
		WAVE/Z data = out[0]
		SFH_ASSERT(!(checkExist && !WaveExists(data)), "No data in dataSet returned from executed formula.")
		SFH_CleanUpInput(out)
		return data
	endif

	return out
End

static Function SF_ConvertAllReturnDataToPermanent(WAVE/WAVE output, string win, string opShort)

	string   wName
	variable i

	for(data : output)
		if(WaveExists(data) && IsFreeWave(data))
			DFREF dfrWork = SFH_GetWorkingDF(win)
			wName = UniqueWaveName(dfrWork, opShort + "_return_arg" + num2istr(i) + "_")
			MoveWave data, dfrWork:$wName
		endif
		i += 1
	endfor
End

/// @brief Executes the complete arguments of the JSON and parses the resulting data to a waveRef type
///        @deprecated: executing all arguments e.g. as array in the executor poses issues as soon as data types get mixed.
///                    e.g. operation(0, A, [1, 2, 3]) fails as [0, A, [1, 2, 3]] can not be converted to an Igor wave.
///                    Thus, it is strongly recommended to parse each argument separately.
static Function/WAVE SF_GetArgumentTop(variable jsonId, string jsonPath, string graph, string opShort)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)
	if(numArgs > 0)
		WAVE wv = SF_FormulaExecutor(graph, jsonID, jsonPath = jsonPath)
	else
		Make/FREE/N=0 data
		WAVE wv = SFH_GetOutputForExecutorSingle(data, graph, opShort + "_zeroSizedInput")
	endif

	WAVE/WAVE input = SF_ResolveDataset(wv)

	return input
End

static Function/WAVE SF_GetNumericVarArgs(variable jsonId, string jsonPath, string graph, string opShort)

	variable numArgs

	numArgs = SFH_CheckArgumentCount(jsonId, jsonPath, opShort, 1)
	if(numArgs == 1)
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	else
		WAVE      wv    = SF_FormulaExecutor(graph, jsonID, jsonPath = jsonPath)
		WAVE/WAVE input = SF_ResolveDataset(wv)
		SFH_ASSERT(DimSize(input, ROWS) == 1, "Expected a single data set")
		WAVE wNum = input[0]
		SFH_ASSERT(IsNumericWave(wNum), "Expected numeric wave")
	endif

	return input
End

static Function/WAVE SF_AverageDataOverSweeps(WAVE/WAVE input)

	variable i, channelNumber, channelType, sweepNo, pos, size, numGroups, numInputs
	variable isSweepData
	string   lbl

	numInputs = DimSize(input, ROWS)
	Make/FREE/N=(numInputs) groupIndexCount
	Make/FREE/WAVE/N=(MINIMUM_WAVE_SIZE) groupWaves
	for(data : input)
		if(!WaveExists(data))
			continue
		endif

		channelNumber = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELNUMBER)
		channelType   = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELTYPE)
		sweepNo       = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPNO)

		isSweepData = !IsNaN(channelNumber) && !IsNaN(channelType) && !IsNaN(sweepNo)
		if(isSweepData)
			lbl = num2istr(channelType) + "_" + num2istr(channelNumber)
		else
			lbl = SF_AVERAGING_NONSWEEPDATA_LBL
		endif

		pos = FindDimLabel(groupWaves, ROWS, lbl)
		if(pos == -2)
			size = DimSize(groupWaves, ROWS)
			if(size == numGroups)
				Redimension/N=(size + MINIMUM_WAVE_SIZE) groupWaves
			endif
			SetDimLabel ROWS, numGroups, $lbl, groupWaves
			pos = numGroups

			Make/FREE/WAVE/N=(numInputs) group
			if(isSweepData)
				JWN_SetNumberInWaveNote(group, SF_META_CHANNELNUMBER, channelNumber)
				JWN_SetNumberInWaveNote(group, SF_META_CHANNELTYPE, channelType)
			endif
			groupWaves[pos] = group

			numGroups += 1
		endif

		WAVE group = groupWaves[pos]
		size                  = groupIndexCount[pos]
		group[size]           = data
		groupIndexCount[pos] += 1
	endfor
	Redimension/N=(numGroups) groupWaves
	for(i = 0; i < numGroups; i += 1)
		WAVE group = groupWaves[i]
		Redimension/N=(groupIndexCount[i]) group
	endfor

	numGroups = DimSize(groupWaves, ROWS)
	Make/FREE/WAVE/N=(numGroups) output
	MultiThread output[] = SF_SweepAverageHelper(groupWaves[p])
	for(i = 0; i < numGroups; i += 1)
		WAVE wData = output[i]
		JWN_SetNumberInWaveNote(wData, SF_META_ISAVERAGED, 1)
		JWN_SetNumberInWaveNote(wData, SF_META_TRACE_MODE, TRACE_DISPLAY_MODE_LINES)
		if(CmpStr(GetDimLabel(groupWaves, ROWS, i), SF_AVERAGING_NONSWEEPDATA_LBL))
			WAVE group = groupWaves[i]
			JWN_SetNumberInWaveNote(wData, SF_META_CHANNELNUMBER, JWN_GetNumberFromWaveNote(group, SF_META_CHANNELNUMBER))
			JWN_SetNumberInWaveNote(wData, SF_META_CHANNELTYPE, JWN_GetNumberFromWaveNote(group, SF_META_CHANNELTYPE))
		endif
	endfor

	return output
End

threadsafe static Function/WAVE SF_SweepAverageHelper(WAVE/WAVE group)

	WAVE/WAVE avgResult = MIES_fWaveAverage(group, 0, IGOR_TYPE_32BIT_FLOAT)

	return avgResult[0]
End

threadsafe static Function SF_RemoveEndOfSweepNaNs(WAVE/Z input)

	if(!WaveExists(input))
		return NaN
	endif

	FindValue/Z/FNAN input
	if(V_Value >= 0)
		Redimension/N=(V_Value) input
	endif
End

static Function/WAVE SF_CreatePlotFormulaDataWave()

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE) tracesInGraph
	Make/FREE/WAVE/N=(MINIMUM_WAVE_SIZE, 2) dataInGraph
	SetDimLabel COLS, 0, WAVEX, dataInGraph
	SetDimLabel COLS, 1, WAVEY, dataInGraph
	Make/FREE/WAVE/N=2 graphData
	graphData[0] = tracesInGraph
	graphData[1] = dataInGraph

	return graphData
End

static Function SF_CollectTraceData(variable &index, WAVE/WAVE graphData, string traceName, WAVE/Z wx, WAVE wy)

	WAVE/T    tracesInGraph = graphData[0]
	WAVE/WAVE dataInGraph   = graphData[1]
	EnsureLargeEnoughWave(tracesInGraph, indexShouldExist = index)
	EnsureLargeEnoughWave(dataInGraph, indexShouldExist = index)
	tracesInGraph[index]       = traceName
	dataInGraph[index][%WAVEX] = wx
	dataInGraph[index][%WAVEY] = wy
	index                     += 1
End

static Function [string varName, string formula] SF_SplitVariableAssignment(string line)

	string regex = "^(?i)\\s*([A-Z]{1}[A-Z0-9_]*)\\s*=(.+)$"

	SplitString/E=regex line, varName, formula
	if(V_flag != 2)
		return ["", ""]
	endif

	return [varName, formula]
End

static Function [WAVE/T varAssignments, string code] SF_GetVariableAssignments(string preProcCode)

	variable i, numLines, varCnt, dimVarName
	string line, varName, formula
	string lineEnd = "\r"
	string varPart = ""

	WAVE/T varAssignments = GetSFVarAssignments()
	dimVarName = FindDimlabel(varAssignments, COLS, "VARNAME")

	numLines = ItemsInList(preProcCode, lineEnd)
	for(i = 0; i < numLines; i += 1)
		line = StringFromList(i, preProcCode, lineEnd)
		if(IsEmpty(line))
			varPart += lineEnd
			continue
		endif
		[varName, formula] = SF_SplitVariableAssignment(line)
		if(IsEmpty(varName))
			break
		endif
		SFH_ASSERT(IsValidObjectName(varName), "Invalid SF variable name")
		varPart += line + lineEnd

		EnsureLargeEnoughWave(varAssignments, indexShouldExist = varCnt)
		varAssignments[varCnt][dimVarName]  = varName
		varAssignments[varCnt][%EXPRESSION] = formula

		varCnt += 1
	endfor
	if(!varCnt)
		return [$"", preProcCode]
	endif
	Redimension/N=(varCnt, -1) varAssignments

	if(varCnt > 1)
		Duplicate/FREE/RMD=[][dimVarName] varAssignments, dupCheck
		FindDuplicates/FREE/CI/DT=dups dupCheck
		SFH_ASSERT(!DimSize(dups, ROWS), "Duplicate variable name.")
	endif

	return [varAssignments, ReplaceString(varPart, preProcCode, "")]
End

static Function/S SF_CheckVariableAssignments(string preProcCode, variable jsonId)

	variable i, numAssignments, jsonIdFormula
	string code, jsonPath

	[WAVE/T varAssignments, code] = SF_GetVariableAssignments(preProcCode)
	if(!WaveExists(varAssignments))
		return code
	endif

	numAssignments = DimSize(varAssignments, ROWS)
	for(i = 0; i < numAssignments; i += 1)
		jsonIdFormula = SFP_ParseFormulaToJSON(varAssignments[i][%EXPRESSION])
		jsonPath      = "/variable:" + varAssignments[i][%VARNAME]
		JSON_AddJSON(jsonID, jsonPath, jsonIdFormula)
		JSON_Release(jsonIdFormula)
	endfor

	return code
End

static Function/S SF_ExecuteVariableAssignments(string graph, string preProcCode)

	variable i, numAssignments, jsonId
	string code

	WAVE/WAVE varStorage = GetSFVarStorage(graph)
	RemoveAllDimLabels(varStorage)
	Redimension/N=(0, -1) varStorage

	[WAVE/T varAssignments, code] = SF_GetVariableAssignments(preProcCode)
	if(!WaveExists(varAssignments))
		return code
	endif

	numAssignments = DimSize(varAssignments, ROWS)
	Redimension/N=(numAssignments) varStorage

	for(i = 0; i < numAssignments; i += 1)
		jsonId = SFP_ParseFormulaToJSON(varAssignments[i][%EXPRESSION])
		WAVE dataRef = SF_FormulaExecutor(graph, jsonId)
		WAVE data    = SF_ResolveDataset(dataRef)
		JWN_SetNumberInWaveNote(data, SF_VARIABLE_MARKER, 1)
		varStorage[i] = dataRef
		SetDimLabel ROWS, i, $varAssignments[i][%VARNAME], varStorage
		JSON_Release(jsonId)
	endfor

	return code
End

Function/DF SF_GetBrowserDF(string graph)

	return BSP_GetFolder(graph, MIES_BSP_PANEL_FOLDER)
End

/// @brief Executes the part of the argument part of the JSON and parses the resulting data to a waveRef type
Function/WAVE SF_ResolveDatasetFromJSON(variable jsonId, string jsonPath, string graph, variable argNum, [variable copy])

	copy = ParamIsDefault(copy) ? 0 : !!copy

	WAVE wv = SF_FormulaExecutor(graph, jsonID, jsonPath = jsonPath + "/" + num2istr(argNum))

	WAVE dataset = SF_ResolveDataset(wv)

	return SFH_CopyDataIfRequired(copy, dataset, dataset)
End

static Function/WAVE SF_ResolveDataset(WAVE input)

	ASSERT(IsTextWave(input) && DimSize(input, ROWS) == 1 && DimSize(input, COLS) == 0, "Unknown SF argument input format")

	WAVE/Z resolve = SFH_AttemptDatasetResolve(WaveText(input, row = 0))
	ASSERT(WaveExists(resolve), "Could not resolve dataset from wave element")

	return resolve
End

Function/S SF_GetDefaultFormula()

	return "trange = [0, inf]\r"                                            + \
	       "sel = select(selrange($trange),selchannels(AD), selsweeps())\r" + \
	       "dat = data($sel)\r"                                             + \
	       "\r"                                                             + \
	       "$dat"
End

// merge(array data1, array data2, ...)
Function/WAVE SF_OperationMerge(variable jsonId, string jsonPath, string graph)

	variable numElements, numOutputDatasets, wvType

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_MERGE, 1, maxArgs = 1)
	WAVE/WAVE inputWithNull = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 0)

	WAVE/ZZ/WAVE input = ZapNullRefs(inputWithNull)
	WaveClear inputWithNull

	numElements = WaveExists(input) ? DimSize(input, ROWS) : 0

	numOutputDatasets = (numElements > 0)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_MERGE, numOutputDatasets)

	if(!numOutputDatasets)
		return SFH_GetOutputForExecutor(output, graph, SF_OP_MERGE)
	endif

	Make/FREE/N=(numElements) waveTypes = WaveType(input[p])
	wvType = waveTypes[0]
	SFH_ASSERT(IsConstant(waveTypes, wvType, ignoreNaN = 0), "Datasets must not differ in type")

	Make/FREE/N=(numElements) waveSizes = numpnts(input[p])
	SFH_ASSERT(IsConstant(waveSizes, 1, ignoreNaN = 0), "Datasets must have only one element")

	Make/FREE/N=(numElements)/Y=(wvType) content

	if(wvType != 0)
		content[] = WaveRef(input[p])[0]
	else
		WAVE/T contentTxt = content
		contentTxt[] = WaveText(WaveRef(input[p]), row = 0)
	endif

	output[0] = content

	return SFH_GetOutputForExecutor(output, graph, SF_OP_MERGE)
End

// dataset(array data1, array data2, ...)
Function/WAVE SF_OperationDataset(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_DATASET, numArgs)

	output[] = SFH_GetArgumentAsWave(jsonID, jsonPath, graph, SF_OP_DATASET, p, singleResult = 1)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_DATASET)
End

static Function [WAVE/D holdWave, WAVE/D initialValues] SF_ParseFitConstraints(WAVE/Z/T constraints, variable numParameters)

	variable i, numElements, index, value
	string indexStr, valueStr, entry

	Make/FREE/N=(numParameters)/D holdWave = 0, initialValues = NaN

	numElements = WaveExists(constraints) ? DimSize(constraints, ROWS) : 0
	SFH_ASSERT(numElements <= numParameters, "The constraints wave can only have up to " + num2str(numParameters) + " entries")

	for(i = 0; i < numElements; i += 1)
		entry = constraints[i]

		SplitString/E="^K([[:digit:]]+)=(.*)$" entry, indexStr, valueStr
		SFH_ASSERT(V_flag == 2, "Invalid constraints wave")

		index = str2numSafe(indexStr)
		SFH_ASSERT(index >= 0 && index < numParameters, "Invalid coefficient index in constraints entry")

		value = str2numSafe(valueStr)
		SFH_ASSERT(!IsNaN(value), "Invalid value in constraints entry")

		holdWave[index]      = 1
		initialValues[index] = value
	endfor

	return [holdWave, initialValues]
End

Function/WAVE SF_OperationFitLine(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_FITLINE, 0, maxArgs = 1)

	WAVE/Z/T constraints = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, SF_OP_FITLINE, 0, defWave = $"", singleResult = 1)

	[WAVE holdWave, WAVE initialValues] = SF_ParseFitConstraints(constraints, 2)

	Make/FREE/T entry = {"line"}

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_FITLINE, 3)
	SetDimensionLabels(output, "fitType;holdWave;initialValues", ROWS)
	output[0] = entry
	output[1] = holdWave
	output[2] = initialValues

	return SFH_GetOutputForExecutor(output, graph, SF_OP_FITLINE)
End

Function/WAVE SF_OperationFit(variable jsonId, string jsonPath, string graph)

	variable numElements
	string   functionName

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_FIT, 3, maxArgs = 3)
	WAVE/WAVE xData = SFH_GetArgumentAsWave(jsonID, jsonPath, graph, SF_OP_FIT, 0)
	WAVE/WAVE yData = SFH_GetArgumentAsWave(jsonID, jsonPath, graph, SF_OP_FIT, 1)
	SFH_ASSERT(DimSize(xData, ROWS) == DimSize(YData, ROWS), "Mismatched number of datasets")

	WAVE/WAVE fitOp = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, SF_OP_FIT, 2)
	SFH_ASSERT(DimSize(fitOp, ROWS) == 3, "Invalid fit operation parameters")

	WAVE/T fitType       = fitOp[%fitType]
	WAVE   holdWave      = fitOp[%holdWave]
	WAVE   initialValues = fitOp[%initialValues]

	numElements = DimSize(yData, ROWS)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_FIT, numElements)

	output[] = SF_OperationFitImpl(xData[p], yData[p], fitType[0], holdWave, initialValues)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_FIT)
End

Function/WAVE SF_OperationFitImpl(WAVE xData, WAVE yData, string fitFunc, WAVE holdWave, WAVE initialValues)

	variable err
	string   holdString

	strswitch(fitFunc)
		case "line":
			Make/FREE/D/N=2 coefWave
			holdString = num2str(holdWave[0]) + num2str(holdWave[1])
			coefWave[] = initialValues[p]
			CurveFit/Q/N=1/NTHR=1/M=0/W=2/G/H=holdString line, kwCWave=coefWave, yData[*][0]/X=xData[*][0]/D; err = GetRTError(1)
			Make/T/FREE params = {"Offset;Slope"}
			break
		default:
			SFH_FATAL_ERROR("Invalid fit function: " + fitFunc)
	endswitch

	if(err)
		return $""
	endif

	WAVE W_sigma = MakeWaveFree($"W_sigma")
	WAVE fit     = MakeWaveFree($"fit__free_")

	JWN_CreatePath(fit, SF_META_USER_GROUP + SF_META_FIT_PARAMETER)
	JWN_SetWaveInWaveNote(fit, SF_META_USER_GROUP + SF_META_FIT_PARAMETER, params)

	JWN_CreatePath(fit, SF_META_USER_GROUP + SF_META_FIT_COEFF)
	JWN_SetWaveInWaveNote(fit, SF_META_USER_GROUP + SF_META_FIT_COEFF, coefWave)

	JWN_CreatePath(fit, SF_META_USER_GROUP + SF_META_FIT_SIGMA)
	JWN_SetWaveInWaveNote(fit, SF_META_USER_GROUP + SF_META_FIT_SIGMA, W_sigma)

	JWN_SetWaveInWaveNote(fit, SF_META_TRACECOLOR, {0, 0, 0}) // black
	JWN_SetNumberInWaveNote(fit, SF_META_TRACE_MODE, TRACE_DISPLAY_MODE_LINES)

	return fit
End

static Function/WAVE SF_ConvertNonFiniteElements(WAVE/T subArray)

	Make/FREE/D/N=(DimSize(subArray, ROWS), DimSize(subArray, COLS), DimSize(subArray, LAYERS), DimSize(subArray, CHUNKS)) convert
	MultiThread convert[][][][] = SF_ConvertNonFiniteElementsImpl(subArray[p][q][r][s])
	if(HasOneFiniteEntry(convert))
		return $""
	endif

	return convert
End

threadsafe static Function SF_ConvertNonFiniteElementsImpl(string element)

	if(!CmpStr(element, "inf"))
		return Inf
	elseif(!CmpStr(element, "-inf"))
		return -Inf
	elseif(!CmpStr(element, "NaN"))
		return NaN
	elseif(!CmpStr(element, "-NaN"))
		return NaN
	endif

	return 0
End

static Function [WAVE outNum, WAVE/T outText] SF_ExecutorCreateOrCheckNumeric(WAVE/Z/D out, WAVE/Z/T outT, variable size0, variable size1, variable size2, variable size3)

	SFH_ASSERT(!WaveExists(outT), "mixed array types")
	if(!WaveExists(out))
		Make/FREE/D/N=(size0, size1, size2, size3) out
	endif

	return [out, outT]
End

static Function [WAVE outNum, WAVE/T outText] SF_ExecutorCreateOrCheckTextual(WAVE/Z out, WAVE/Z/T outT, variable size0, variable size1, variable size2, variable size3)

	SFH_ASSERT(!WaveExists(out), "mixed array types")
	if(!WaveExists(outT))
		Make/FREE/T/N=(size0, size1, size2, size3) outT
	endif

	return [out, outT]
End

/// @brief This function extends formulaResults if possible. For each result from a Y formula it is attempted to move datasets from inside an array outside in the form
///        [dataset(1, 2), dataset(3, 4)] -> dataset([1, 3], [3, 4])
///        because the plotter can iterate over datasets only at the outermost occurrence.
///        As result the inside elements may be plottable after this transformation.
///        algorithm details:
///        Each Y formula result is 'repackaged' in an array and attempted to be transformed
///        Case 1: On a failed transformation the initial array is returned.
///        Case 2: On a successful transformation a dataset with one or more elements is returned
///        Regarding the plotter the array of case 1 is treated as a single dataset.
///        All the results from case 1 and case 2 are gathered in a waveref wave collectY.
///        The X formula results are associated multiple times for case 2 if multiple datasets were returned and are
///        gathered in a waveref wave collectX that grows identical to collectY.
///        The formulaResults wave gets modified to store the new transformed results.
static Function SF_FormulaPlotterExtendResultsIfCompatible(WAVE/WAVE formulaResults)

	variable i, numResults

	numResults = DimSize(formulaResults, ROWS)
	if(!numResults)
		return NaN
	endif

	WAVE/ZZ/WAVE collectX, collectY
	for(i = 0; i < numResults; i += 1)

		WAVE/Z wvResultX = formulaResults[i][%FORMULAX]
		WAVE/Z wvResultY = formulaResults[i][%FORMULAY]
		if(!WaveExists(wvResultY))
			continue
		endif
		Make/FREE/WAVE array = {wvResultY}
		WAVE/WAVE extended = SFH_MoveDatasetHigherIfCompatible(array)
		if(!WaveExists(collectY))
			WAVE/WAVE collectY = extended
			Duplicate/FREE/WAVE extended, collectX
			collectX[] = wvResultX
		else
			Concatenate/FREE/NP/WAVE {extended}, collectY
			extended[] = wvResultX
			Concatenate/FREE/NP/WAVE {extended}, collectX
		endif
	endfor

	if(!WaveExists(collectY))
		return NaN
	endif
	Redimension/N=(DimSize(collectY, ROWS), -1, -1, -1) formulaResults
	formulaResults[][%FORMULAX] = collectX[p]
	formulaResults[][%FORMULAY] = collectY[p]
End

threadsafe static Function/S SF_GetSelectRowId(WAVE select, variable row)

	string str

	sprintf str, SF_GETSETINTERSECTIONSELECT_FORMAT, select[row][%SWEEP], select[row][%CHANNELTYPE], select[row][%CHANNELNUMBER], select[row][%SWEEPMAPINDEX]
	return str
End

static Function/WAVE SF_CreateSelectWaveRowIds(WAVE select)

	Make/FREE/T/N=(DimSize(select, ROWS)) selectRowId
	Multithread selectRowId[] = SF_GetSelectRowId(select, p)

	return selectRowId
End

/// @brief Returns the set intersection of two select waves from operation select
static Function/WAVE SF_GetSetIntersectionSelect(WAVE select1, WAVE select2)

	WAVE rowId1 = SF_CreateSelectWaveRowIds(select1)
	WAVE rowId2 = SF_CreateSelectWaveRowIds(select2)

	WAVE/Z intersect = GetSetIntersection(rowId1, rowId2, getIndices = 1)
	if(!WaveExists(intersect))
		return $""
	endif

	WAVE output = SFH_NewSelectDataWave(DimSize(intersect, ROWS), 1)
	MultiThread output[][] = select1[intersect[p]][q]

	return output
End

static Function SF_FilterByClampModeEnabled(variable clampModeFilter, variable channelType)

	return clampModeFilter != SF_OP_SELECT_CLAMPCODE_ALL && (channelType == XOP_CHANNEL_TYPE_DAC || channelType == XOP_CHANNEL_TYPE_ADC)
End

static Function/S SF_MatchSweepMapColumn(string graph, string match, string colLabel, string opShort)

	variable col

	WAVE/T sweepMap = SB_GetSweepMap(graph)
	WAVE/Z indices  = SF_GetSweepMapIndices(sweepMap, NaN, "", "", colLabel = colLabel, wildCardPattern = match)
	SFH_ASSERT(WaveExists(indices), "No match found in sweepMap in operation " + opShort)

	col = FindDimlabel(sweepMap, COLS, colLabel)
	Make/FREE/T/N=(DimSize(indices, ROWS)) entries
	MultiThread entries[] = sweepMap[indices[p]][col]

	WAVE/T uniqueEntries = GetUniqueEntries(entries)
	SFH_ASSERT(DimSize(uniqueEntries, ROWS) < 2, "Multiple matches found in sweepMap in operation " + opShort)
	SFH_ASSERT(DimSize(uniqueEntries, ROWS) == 1, "No match found in sweepMap in operation " + opShort)

	return uniqueEntries[0]
End

Function TraceValueDisplayHook(STRUCT WMTooltipHookStruct &s)

	string name, msg, allTraces, trace, tooltip, match, options, win, valueStr, tagText
	variable numTraces, i

	// traceName is set only for graphs and only if the mouse hovered near a trace
	if(IsEmpty(s.traceName))
		return 0
	endif

	win = s.winName

	tooltip   = ""
	allTraces = TraceNameList(win, ";", 1 + 2)

	numTraces = ItemsInList(allTraces)
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, allTraces)

		sprintf options, "WINDOW:%s;ONLY:%s;DELTAX:24;DELTAY:24", win, trace
		match = TraceFromPixel(s.mouseLoc.h, s.mouseLoc.v, options)

		if(IsEmpty(match))
			continue
		endif

		WAVE wv = TraceNameToWaveRef(win, trace)

		name = JWN_GetStringFromWaveNote(wv, SF_META_LEGEND_LINE_PREFIX)

		if(IsEmpty(name))
			// not a labnotebook/analysis function parameter
			continue
		endif

		if(IsNumericWave(wv))
			tagText = JWN_GetStringFromWaveNote(wv, SF_META_TAG_TEXT)
			if(IsEmpty(tagText))
				valueStr = num2str(wv[s.row][s.column][s.layer][s.chunk])
			else
				valueStr = ReplaceString("\r", tagText, "\r" + ReplicateString(" ", strlen(name) + 2))
			endif
		elseif(IsTextWave(wv))
			WAVE/T wvText = wv
			valueStr = wvText[s.row][s.column][s.layer][s.chunk]
		endif

		sprintf msg, "%s: %s\r", name, valueStr
		tooltip += msg
	endfor

	if(!IsEmpty(tooltip))
		s.tooltip = "<pre>" + RemoveEnding(tooltip, "\r") + "</pre>"
		s.isHtml  = 1
		return 1
	endif

	return 0
End
