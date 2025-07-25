#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_SFO
#endif // AUTOMATED_TESTING

// to enable debug mode with more persistent data
// #define SWEEPFORMULA_DEBUG

/// @file MIES_SweepFormula_Operations.ipf
///
/// @brief __SFO__ Sweep Formula Operations

static Constant SF_APFREQUENCY_FULL               = 0x0
static Constant SF_APFREQUENCY_INSTANTANEOUS      = 0x1
static Constant SF_APFREQUENCY_APCOUNT            = 0x2
static Constant SF_APFREQUENCY_INSTANTANEOUS_PAIR = 0x3

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

static StrConstant SF_OP_EPOCHS_TYPE_RANGE     = "range"
static StrConstant SF_OP_EPOCHS_TYPE_NAME      = "name"
static StrConstant SF_OP_EPOCHS_TYPE_TREELEVEL = "treelevel"

static Constant EPOCHS_TYPE_INVALID   = -1
static Constant EPOCHS_TYPE_RANGE     = 0
static Constant EPOCHS_TYPE_NAME      = 1
static Constant EPOCHS_TYPE_TREELEVEL = 2

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

static Constant SELECTDATA_MODE_SCI = 1
static Constant SELECTDATA_MODE_RAC = 2

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

static StrConstant SF_OP_SELECT_STIMSETS_ALL = "*"

static StrConstant SF_OP_SELECTVIS_ALL       = "all"
static StrConstant SF_OP_SELECTVIS_DISPLAYED = "displayed"

static StrConstant SF_GETSETINTERSECTIONSELECT_FORMAT = "%d_%d_%d_%f"

static Constant SWEEPPROP_CLAMPMODE     = 0
static Constant SWEEPPROP_SETCYCLECOUNT = 1
static Constant SWEEPPROP_SETSWEEPCOUNT = 2
static Constant SWEEPPROP_END           = 3

static StrConstant SF_AVERAGING_NONSWEEPDATA_LBL = "NOSWEEPDATA"

static StrConstant DB_EXPNAME_DUMMY = "|DataBrowserExperiment|"

Function/WAVE SFO_OperationAnaFuncParam(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonID, jsonPath, SF_OP_ANAFUNCPARAM, 0, maxArgs = 2)

	WAVE/T names      = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, SF_OP_ANAFUNCPARAM, 0, singleResult = 1)
	WAVE/Z selectData = SFH_GetArgumentSelect(jsonID, jsonPath, graph, SF_OP_DATA, 1)

	WAVE/WAVE output = SFO_OperationAnaFuncParamIterate(graph, names, selectData, SF_OP_ANAFUNCPARAM)

	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_ANAFUNCPARAM, ""))
	JWN_SetStringInWaveNote(output, SF_META_WINDOW_HOOK, "TraceValueDisplayHook")

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_ANAFUNCPARAM)
End

Function/WAVE SFO_OperationAnaFuncParamIterate(string graph, WAVE/T names, WAVE/Z/WAVE selectDataArray, string opShort)

	if(!WaveExists(selectDataArray))
		return $""
	endif

	WAVE/Z/WAVE result = $""

	for(WAVE/Z/WAVE selectDataComp : selectDataArray)

		if(!WaveExists(selectDataComp))
			continue
		endif

		WAVE/Z    selectData = selectDataComp[%SELECTION]
		WAVE/WAVE sweepData  = SFO_OperationAnaFuncParamImpl(graph, names, selectData, opShort)
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

static Function/WAVE SFO_OperationAnaFuncParamImpl(string graph, WAVE/T names, WAVE/Z selectData, string opShort)

	variable numReqNames, numFoundParams, i, j, idx, sweepNo, chanType, chanNr, colorGroup, colorGroupFound, nextFreeIndex, marker
	string params, name, type

	if(!WaveExists(selectData))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_ANAFUNCPARAM)
		return output
	endif

	WAVE/WAVE allParams   = SFO_OperationLabnotebookImpl(graph, {ANALYSIS_FUNCTION_PARAMS_LBN}, selectData, DATA_ACQUISITION_MODE, opShort)
	WAVE/Z/T  allReqNames = SFO_OperationAnaFuncParamImplAllNames(names, allParams)

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

/// Gather all requested analysis function parameters with wildcard support
///
/// @param names     requested analysis function parameter names, can include wildcards
/// @param lbnParams wave reference wave, one wave per selectData entry, with
///                  the analysis function parameter data from the labnotebook including JWN
///                  metadata
///
/// @return expanded analysis function parameter names (i.e. without wildcards) which match at least in one selectData entry
static Function/WAVE SFO_OperationAnaFuncParamImplAllNames(WAVE/T names, WAVE/WAVE lbnParams)

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

// apfrequency(data, [frequency calculation method], [spike detection crossing level], [result value type], [normalize], [x-axis type])
Function/WAVE SFO_OperationApFrequency(variable jsonId, string jsonPath, string graph)

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
	argSetup[0][%VALUE] = SFO_OperationApFrequencyMethodToString(method)
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
	output = SFO_OperationApFrequencyImpl(input[p], level, method, timeFreq, normalize, xAxisType, normValue, normMean)
	if(!CmpStr(normalize, SF_OP_APFREQUENCY_NORMOVERSWEEPSAVG) && DimSize(normMean, ROWS))
		normValue = mean(normMean)
		SFO_OperationApFrequencyNormalizeOverSweeps(output, normValue)
	elseif((!CmpStr(normalize, SF_OP_APFREQUENCY_NORMOVERSWEEPSMIN) || !CmpStr(normalize, SF_OP_APFREQUENCY_NORMOVERSWEEPSMAX)) && !IsNaN(normValue))
		SFO_OperationApFrequencyNormalizeOverSweeps(output, normValue)
	endif

	if(method == SF_APFREQUENCY_INSTANTANEOUS_PAIR)
		keepX  = 1
		xLabel = SelectString(!CmpStr(xAxisType[0], SF_OP_APFREQUENCY_X_COUNT), "ms", "peak number")
		JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, xLabel)
	endif

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, opShort, SF_DATATYPE_APFREQUENCY, keepX = keepX, argSetup = argSetup)

	return SFH_GetOutputForExecutor(output, graph, opShort)
End

static Function SFO_OperationApFrequencyNormalizeOverSweeps(WAVE/WAVE output, variable normValue)

	Make/FREE/D/N=(DimSize(output, ROWS)) idxHelper
	idxHelper = SFO_OperationApFrequencyNormalizeOverSweepsImpl(output[p], normValue)
End

static Function SFO_OperationApFrequencyNormalizeOverSweepsImpl(WAVE/Z data, variable normValue)

	if(!WaveExists(data))
		return NaN
	endif

	MultiThread data /= normValue
End

static Function/WAVE SFO_OperationApFrequencyImpl(WAVE/Z data, variable level, variable method, string yStr, string normStr, string xAxisTypeStr, variable &normOSValue, WAVE normMean)

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

			Make/FREE/D outD = {SFO_ApFrequencyInstantaneous(peaksAt)}
			yUnit = SelectString(normalize, "Hz [Instantaneous]", "normalized frequency [Instantaneous]")
			SetScale/P y, DimOffset(outD, ROWS), DimDelta(outD, ROWS), yUnit, outD
			break
		case SF_APFREQUENCY_INSTANTANEOUS_PAIR:
			if(numPeaks <= 1)
				return $""
			endif

			WAVE outD = SFO_ApFrequencyInstantaneousPairs(peaksAt, yModeTime, xAxisCount)
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

static Function/S SFO_OperationApFrequencyMethodToString(variable method)

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

static Function SFO_ApFrequencyInstantaneous(WAVE peaksAt)

	variable numPeaks

	numPeaks = DimSize(peaksAt, COLS)
	ASSERT(numPeaks > 1, "Number of peaks must be greater than 1 to calculate pairs.")

	Make/FREE/D/N=(numPeaks - 1) distances
	distances[0, numPeaks - 2] = peaksAt[0][p + 1] - peaksAt[0][p]
	return 1.0 / (mean(distances) * MILLI_TO_ONE)
End

static Function/WAVE SFO_ApFrequencyInstantaneousPairs(WAVE peaksAt, variable yModeTime, variable xAxisIsCounts)

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

Function/WAVE SFO_OperationArea(variable jsonId, string jsonPath, string graph)

	variable zero, numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs >= 1, "area requires at least one argument.")
	SFH_ASSERT(numArgs <= 2, "area requires at most two arguments.")

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 0)

	zero = !!SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_AREA, 1, defValue = 1)

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_AREA, DimSize(input, ROWS))

	output[] = SFO_OperationAreaImpl(input[p], zero)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_AREA, SF_DATATYPE_AREA)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_AREA, clear = input)
End

static Function/WAVE SFO_OperationAreaImpl(WAVE/Z input, variable zero)

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

Function/WAVE SFO_OperationAvg(variable jsonId, string jsonPath, string graph)

	variable numArgs
	string   mode
	string opShort = SF_OP_AVG

	numArgs = SFH_CheckArgumentCount(jsonID, jsonPath, opShort, 1, maxArgs = 2)

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonID, jsonPath, graph, 0)
	mode = SFH_GetArgumentAsText(jsonId, jsonPath, graph, opShort, 1, defValue = SF_OP_AVG_INSWEEPS, allowedValues = {SF_OP_AVG_INSWEEPS, SF_OP_AVG_OVERSWEEPS})

	strswitch(mode)
		case SF_OP_AVG_INSWEEPS:
			WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, DimSize(input, ROWS))
			output[] = SFO_OperationAvgImplIn(input[p])
			SFH_TransferFormulaDataWaveNoteAndMeta(input, output, opShort, SF_DATATYPE_AVG)
			return SFH_GetOutputForExecutor(output, graph, opShort, clear = input)

		case SF_OP_AVG_OVERSWEEPS:
			return SFO_OperationAvgImplOver(input, graph, opShort)

		default:
			FATAL_ERROR("Unknown avg operation mode")
	endswitch

End

static Function/WAVE SFO_OperationAvgImplOver(WAVE/WAVE input, string graph, string opShort)

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
static Function/WAVE SFO_OperationAvgImplIn(WAVE/Z input)

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

/// `butterworth(data, lowPassCutoff, highPassCutoff, order)`
Function/WAVE SFO_OperationButterworth(variable jsonId, string jsonPath, string graph)

	variable lowPassCutoff, highPassCutoff, order

	SFH_CheckArgumentCount(jsonID, jsonPath, SF_OP_BUTTERWORTH, 4, maxArgs = 4)

	WAVE/WAVE input = SFH_GetArgumentAsWave(jsonID, jsonPath, graph, SF_OP_BUTTERWORTH, 0, copy = 1)
	lowPassCutoff  = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_BUTTERWORTH, 1)
	highPassCutoff = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_BUTTERWORTH, 2)
	order          = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_BUTTERWORTH, 3)

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_BUTTERWORTH, DimSize(input, ROWS))

	output[] = SFO_OperationButterworthImpl(input[p], lowPassCutoff, highPassCutoff, order)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_BUTTERWORTH, SF_DATATYPE_BUTTERWORTH)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_BUTTERWORTH, clear = input)
End

static Function/WAVE SFO_OperationButterworthImpl(WAVE/Z input, variable lowPassCutoff, variable highPassCutoff, variable order)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "butterworth requires numeric input data.")
	FilterIIR/HI=(highPassCutoff / WAVEBUILDER_MIN_SAMPINT_HZ)/LO=(lowPassCutoff / WAVEBUILDER_MIN_SAMPINT_HZ)/ORD=(order)/DIM=(ROWS) input
	SFH_ASSERT(V_flag == 0, "FilterIIR returned error")

	return input
End

/// concat(array0, array1, array2, ...)
Function/WAVE SFO_OperationConcat(variable jsonId, string jsonPath, string graph)

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

Function/WAVE SFO_OperationCursors(variable jsonId, string jsonPath, string graph)

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

/// `data(array range[, array selectData])`
///
/// returns [sweepData][sweeps][channelTypeNumber] for all sweeps selected by selectData
Function/WAVE SFO_OperationData(variable jsonId, string jsonPath, string graph)

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

// dataset(array data1, array data2, ...)
Function/WAVE SFO_OperationDataset(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_DATASET, numArgs)

	output[] = SFH_GetArgumentAsWave(jsonID, jsonPath, graph, SF_OP_DATASET, p, singleResult = 1)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_DATASET)
End

Function/WAVE SFO_OperationDerivative(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_DERIVATIVE)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_DERIVATIVE, DimSize(input, ROWS))

	output[] = SFO_OperationDerivativeImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_DERIVATIVE, SF_DATATYPE_DERIVATIVE)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_DERIVATIVE, clear = input)
End

static Function/WAVE SFO_OperationDerivativeImpl(WAVE/Z input)

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

Function/WAVE SFO_OperationDiv(variable jsonId, string jsonPath, string graph)

	WAVE output = SFO_IndexOverDataSetsForPrimitiveOperation(jsonId, jsonpath, graph, SF_OPSHORT_DIV)

	return SFH_GetOutputForExecutor(output, graph, SF_OPSHORT_DIV)
End

static Function/WAVE SFO_OperationDivImplDataSets(WAVE/Z data0, WAVE/Z data1)

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
	SFO_AssertOnMismatchedWaves(data0, data1, SF_OPSHORT_DIV)

	MatrixOp/FREE result = data0 / data1
	CopyScales data0, result
	return result
End

// epochs(string shortName[, array selectData, [string type]])
// returns 2xN waves for range and 1xN otherwise, where N is the number of epochs
Function/WAVE SFO_OperationEpochs(variable jsonId, string jsonPath, string graph)

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

	WAVE/WAVE output = SFO_OperationEpochsImpl(graph, epochPatterns, selectData, epType, SF_OP_EPOCHS)

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_EPOCHS)
End

static Function/WAVE SFO_OperationEpochsImpl(string graph, WAVE/T epochPatterns, WAVE/Z selectData, variable epType, string opShort)

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

// findlevel(data, level, [edge])
Function/WAVE SFO_OperationFindLevel(variable jsonId, string jsonPath, string graph)

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

Function/WAVE SFO_OperationFit(variable jsonId, string jsonPath, string graph)

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

	output[] = SFO_OperationFitImpl(xData[p], yData[p], fitType[0], holdWave, initialValues)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_FIT)
End

Function/WAVE SFO_OperationFitImpl(WAVE xData, WAVE yData, string fitFunc, WAVE holdWave, WAVE initialValues)

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

Function/WAVE SFO_OperationFitLine(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_FITLINE, 0, maxArgs = 1)

	WAVE/Z/T constraints = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, SF_OP_FITLINE, 0, defWave = $"", singleResult = 1)

	[WAVE holdWave, WAVE initialValues] = SFO_ParseFitConstraints(constraints, 2)

	Make/FREE/T entry = {"line"}

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_FITLINE, 3)
	SetDimensionLabels(output, "fitType;holdWave;initialValues", ROWS)
	output[0] = entry
	output[1] = holdWave
	output[2] = initialValues

	return SFH_GetOutputForExecutor(output, graph, SF_OP_FITLINE)
End

Function/WAVE SFO_OperationIntegrate(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_INTEGRATE)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_INTEGRATE, DimSize(input, ROWS))

	output[] = SFO_OperationIntegrateImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_INTEGRATE, SF_DATATYPE_INTEGRATE)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_INTEGRATE, clear = input)
End

static Function/WAVE SFO_OperationIntegrateImpl(WAVE/Z input)

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

/// `labnotebook(array keys[, array selectData [, string entrySourceType]])`
///
/// return lab notebook @p key for all @p sweeps that belong to the channels @p channels
Function/WAVE SFO_OperationLabnotebook(variable jsonId, string jsonPath, string graph)

	variable numArgs, mode
	string lbnKey, modeTxt

	SFH_CheckArgumentCount(jsonID, jsonPath, SF_OP_LABNOTEBOOK, 1, maxArgs = 3)

	Make/FREE/T allowedValuesMode = {"UNKNOWN_MODE", "DATA_ACQUISITION_MODE", "TEST_PULSE_MODE", "NUMBER_OF_LBN_DAQ_MODES"}
	modeTxt = SFH_GetArgumentAsText(jsonID, jsonPath, graph, SF_OP_LABNOTEBOOK, 2, allowedValues = allowedValuesMode, defValue = "DATA_ACQUISITION_MODE")
	mode    = ParseLogbookMode(modeTxt)

	WAVE/Z selectData = SFH_GetArgumentSelect(jsonID, jsonPath, graph, SF_OP_LABNOTEBOOK, 1)

	WAVE/T lbnKeys = SFH_GetArgumentAsWave(jsonID, jsonPath, graph, SF_OP_LABNOTEBOOK, 0, expectedMajorType = IGOR_TYPE_TEXT_WAVE, singleResult = 1)

	WAVE/Z/WAVE output = SFO_OperationLabnotebookIterate(graph, lbnKeys, selectData, mode, SF_OP_LABNOTEBOOK)
	if(!WaveExists(output))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_LABNOTEBOOK, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_LABNOTEBOOK)
	endif

	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_LABNOTEBOOK, ""))
	JWN_SetStringInWaveNote(output, SF_META_WINDOW_HOOK, "TraceValueDisplayHook")

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_LABNOTEBOOK)
End

static Function/WAVE SFO_OperationLabnotebookIterate(string graph, WAVE/T lbnKeys, WAVE/Z/WAVE selectDataArray, variable mode, string opShort)

	if(!WaveExists(selectDataArray))
		return $""
	endif

	WAVE/Z/WAVE result = $""

	for(WAVE/Z/WAVE selectDataComp : selectDataArray)

		if(!WaveExists(selectDataComp))
			continue
		endif

		WAVE/Z    selectData = selectDataComp[%SELECTION]
		WAVE/WAVE lbnData    = SFO_OperationLabnotebookImpl(graph, lbnKeys, selectData, mode, opShort)
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

static Function/WAVE SFO_OperationLabnotebookImpl(string graph, WAVE/T LBNKeys, WAVE/Z selectData, variable mode, string opShort)

	variable i, numSelected, idx, lbnIndex
	variable numOutputWaves, colorGroup, marker
	string lbnKey, refUnit, unitString

	if(!WaveExists(selectData))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_LABNOTEBOOK)
		return output
	endif

	WAVE/Z/T allLBNKeys = SFO_OperationLabnotebookExpandKeys(graph, LBNKeys, selectData, mode)

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
			WAVE out = SFO_OperationLabnotebookImplGetEntry(graph, selectData, i, lbnKey, mode)

			JWN_SetNumberInWaveNote(out, SF_META_COLOR_GROUP, colorGroup)
			JWN_SetNumberInWaveNote(out, SF_META_MOD_MARKER, marker)

			output[idx] = out
			idx        += 1
		endfor
	endfor

	WAVE/T units = SFO_GetLabnotebookEntryUnits(graph, allLBNKeys, selectData)

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

static Function/WAVE SFO_OperationLabnotebookImplGetEntry(string graph, WAVE selectData, variable index, string lbnKey, variable mode)

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

static Function/S SFO_GetLabnotebookEntryUnits_Impl(WAVE numericalKeys, WAVE textualKeys, string entry)

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

static Function/WAVE SFO_GetLabnotebookEntryUnits(string graph, WAVE/T allLBNKeys, WAVE selectData)

	variable sweepNo, mapIndex

	sweepNo  = selectData[0][%SWEEP]
	mapIndex = selectData[0][%SWEEPMAPINDEX]

	WAVE numericalKeys = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_KEYS)
	WAVE textualKeys   = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_TEXTUAL_KEYS)

	Make/FREE/T/N=(DimSize(allLBNKeys, ROWS)) units = SFO_GetLabnotebookEntryUnits_Impl(numericalKeys, textualKeys, allLBNKeys[p])

	WAVE/Z/T unitsUnique = GetUniqueEntries(units)

	return unitsUnique
End

static Function/WAVE SFO_OperationLabnotebookExpandKeys(string graph, WAVE/T LBNKeys, WAVE selectData, variable mode)

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

Function/WAVE SFO_OperationLog(variable jsonId, string jsonPath, string graph)

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
		SFO_OperationLogImpl(w)
	endfor

	SFH_TransferFormulaDataWaveNoteAndMeta(input, input, SF_OP_LOG, JWN_GetStringFromWaveNote(input, SF_META_DATATYPE))

	return SFH_GetOutputForExecutor(input, graph, SF_OP_LOG)
End

static Function SFO_OperationLogImpl(WAVE/Z input)

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
			SFO_OperationLogImpl(elem)
		endfor
	else
		print input[0]
	endif
End

Function/WAVE SFO_OperationLog10(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_LOG10)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_LOG10, DimSize(input, ROWS))

	output[] = SFO_OperationLog10Impl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_LOG10, JWN_GetStringFromWaveNote(input, SF_META_DATATYPE))

	return SFH_GetOutputForExecutor(output, graph, SF_OP_LOG10, clear = input)
End

static Function/WAVE SFO_OperationLog10Impl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif
	SFH_ASSERT(IsNumericWave(input), "log10 requires numeric input data.")
	MatrixOP/FREE output = log(input)
	SF_FormulaWaveScaleTransfer(input, output, SF_TRANSFER_ALL_DIMS, NaN)

	return output
End

Function/WAVE SFO_OperationMax(variable jsonId, string jsonPath, string graph)

	WAVE/WAVE input  = SFO_GetNumericVarArgs(jsonId, jsonPath, graph, SF_OP_MAX)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_MAX, DimSize(input, ROWS))

	output[] = SFO_OperationMaxImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_MAX, SF_DATATYPE_MAX)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_MAX, clear = input)
End

static Function/WAVE SFO_OperationMaxImpl(WAVE/Z input)

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

// merge(array data1, array data2, ...)
Function/WAVE SFO_OperationMerge(variable jsonId, string jsonPath, string graph)

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

Function/WAVE SFO_OperationMin(variable jsonId, string jsonPath, string graph)

	WAVE/WAVE input  = SFO_GetNumericVarArgs(jsonId, jsonPath, graph, SF_OP_MIN)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_MIN, DimSize(input, ROWS))

	output[] = SFO_OperationMinImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_MIN, SF_DATATYPE_MIN)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_MIN, clear = input)
End

static Function/WAVE SFO_OperationMinImpl(WAVE/Z input)

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

Function/WAVE SFO_OperationMinus(variable jsonId, string jsonPath, string graph)

	WAVE output = SFO_IndexOverDataSetsForPrimitiveOperation(jsonId, jsonpath, graph, SF_OPSHORT_MINUS)

	return SFH_GetOutputForExecutor(output, graph, SF_OPSHORT_MINUS)
End

static Function/WAVE SFO_OperationMinusImplDataSets(WAVE/Z data0, WAVE/Z data1)

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
	SFO_AssertOnMismatchedWaves(data0, data1, SF_OPSHORT_MINUS)

	MatrixOp/FREE result = data0 - data1
	CopyScales data0, result
	return result
End

Function/WAVE SFO_OperationMult(variable jsonId, string jsonPath, string graph)

	WAVE output = SFO_IndexOverDataSetsForPrimitiveOperation(jsonId, jsonpath, graph, SF_OPSHORT_MULT)

	return SFH_GetOutputForExecutor(output, graph, SF_OPSHORT_MULT)
End

static Function/WAVE SFO_OperationMultImplDataSets(WAVE/Z data0, WAVE/Z data1)

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
	SFO_AssertOnMismatchedWaves(data0, data1, SF_OPSHORT_MULT)

	MatrixOp/FREE result = data0 * data1
	CopyScales data0, result
	return result
End

Function/WAVE SFO_OperationPlus(variable jsonId, string jsonPath, string graph)

	WAVE output = SFO_IndexOverDataSetsForPrimitiveOperation(jsonId, jsonpath, graph, SF_OPSHORT_PLUS)

	return SFH_GetOutputForExecutor(output, graph, SF_OPSHORT_PLUS)
End

static Function/WAVE SFO_OperationPlusImplDataSets(WAVE/Z data0, WAVE/Z data1)

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
	SFO_AssertOnMismatchedWaves(data0, data1, SF_OPSHORT_PLUS)

	MatrixOp/FREE result = data0 + data1
	CopyScales data0, result
	return result
End

Function/WAVE SFO_OperationPowerSpectrum(variable jsonId, string jsonPath, string graph)

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
	MultiThread indexHelper[] = SFO_RemoveEndOfSweepNaNs(input[p])

	doAvg  = !CmpStr(avg, "avg")
	cutOff = (ratioFreq == 0) ? cutOff : NaN

	if(doAvg)
		Make/FREE/WAVE/N=(DimSize(input, ROWS)) output
	else
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_POWERSPECTRUM, DimSize(input, ROWS))
	endif

	MultiThread output[] = SFO_OperationPowerSpectrumImpl(input[p], unit, cutoff, winFunc)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_POWERSPECTRUM, SF_DATATYPE_POWERSPECTRUM)

	if(doAvg)
		WAVE/WAVE outputAvg   = SFO_AverageDataOverSweeps(output)
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
			output[0, debugVal - 1] = SFO_PowerSpectrumRatio(inputRatio[p], ratioFreq, SF_POWERSPECTRUM_RATIO_DELTAHZ, fitData = inputRatio[p + debugVal])
			output[debugVal,]       = inputRatio[p]
		endif
#else
		output[] = SFO_PowerSpectrumRatio(inputRatio[p], ratioFreq, SF_POWERSPECTRUM_RATIO_DELTAHZ)
#endif // DEBUGGING_ENABLED
	endif

	return SFH_GetOutputForExecutor(output, graph, SF_OP_POWERSPECTRUM, clear = input)
End

static Function/WAVE SFO_PowerSpectrumRatio(WAVE/Z input, variable ratioFreq, variable deltaHz, [WAVE fitData])

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
		FuncFit/Q SFO_LineNoiseFit, kwCWave=wCoef, input(minFreq, maxFreq)/C=wConstraints/D=fitData; err = GetRTError(1)
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
	FuncFit/Q SFO_LineNoiseFit, kwCWave=wCoef, input(minFreq, maxFreq)/C=wConstraints; err = GetRTError(1)
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

Function SFO_LineNoiseFit(WAVE w, variable x) : FitFunc

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

threadsafe static Function/WAVE SFO_OperationPowerSpectrumImpl(WAVE/Z input, string unit, variable cutoff, string winFunc)

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

/// range (start[, stop[, step]])
Function/WAVE SFO_OperationRange(variable jsonId, string jsonPath, string graph)

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

Function/WAVE SFO_OperationRMS(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "rms requires at least one argument")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_RMS)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_RMS, DimSize(input, ROWS))

	output[] = SFO_OperationRMSImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_RMS, SF_DATATYPE_RMS)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_RMS, clear = input)
End

static Function/WAVE SFO_OperationRMSImpl(WAVE/Z input)

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

/// `select(selectFilterOp...)`
///
/// returns 2 datasets, main wave typed SF_DATATYPE_SELECTCOMP
/// dataset 0: N x 3 with columns [sweepNr][channelType][channelNr], typed SF_DATATYPE_SELECT
/// dataset 1: WaveRef wave with range specifications, typed SF_DATATYPE_SELECTRANGE
Function/WAVE SFO_OperationSelect(variable jsonId, string jsonPath, string graph)

	STRUCT SF_SelectParameters filter
	variable i, numArgs, selectArgPresent
	string type, vis
	string expName = ""
	string device  = ""

	SFO_InitSelectFilterUninitalized(filter)

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
					WAVE/Z filter.selects = SFO_GetSetIntersectionSelect(filter.selects, arg)
				endif
				break
			default:
				SFH_FATAL_ERROR("Unsupported select argument")
		endswitch
	endfor

	SFO_SetSelectionFilterDefaults(graph, filter, selectArgPresent)

	if(!IsEmpty(expName))
		filter.experimentName = SFO_GetSelectionExperiment(graph, expName)
	endif
	if(!IsEmpty(device))
		filter.device = SFO_GetSelectionDevice(graph, device)
	endif

	WAVE/Z selectData = SFO_GetSelectData(graph, filter)
	if(WaveExists(selectData))
		if(!IsNaN(filter.racIndex))
			WAVE/Z racSelectData = SFO_GetSelectDataWithRACorSCIIndex(graph, selectData, filter.racIndex, SELECTDATA_MODE_RAC)
			WAVE/Z selectData    = racSelectData
		endif
		if(!IsNaN(filter.sciIndex))
			WAVE/Z sciSelectData = SFO_GetSelectDataWithRACorSCIIndex(graph, selectData, filter.sciIndex, SELECTDATA_MODE_SCI)
			WAVE/Z selectData    = sciSelectData
		endif
		// SCI is a subset of RAC, thus if RAC and SCI is enabled then it is sufficient to extend through RAC
		if(filter.expandRAC)
			WAVE selectWithRACFilledUp = SFO_GetSelectDataWithSCIorRAC(graph, selectData, filter, SELECTDATA_MODE_RAC)
			WAVE selectData            = selectWithRACFilledUp
		elseif(filter.expandSCI)
			WAVE selectWithSCIFilledUp = SFO_GetSelectDataWithSCIorRAC(graph, selectData, filter, SELECTDATA_MODE_SCI)
			WAVE selectData            = selectWithSCIFilledUp
		endif
		if(filter.expandSCI || filter.expandRAC)
			WAVE sortedSelectData = SFO_SortSelectData(selectData)
			WAVE selectData       = sortedSelectData
		endif
	endif

	if(!WaveExists(selectData))
		// case: select from added filter arguments leaves empty selection, then result is empty as intersection with any other selection would yield also empty result
		WAVE/Z selectResult = $""
	elseif(WaveExists(filter.selects))
		// case: select argument(s) present, selection from argument is intersected with select from added filter arguments
		WAVE/Z selectResult = SFO_GetSetIntersectionSelect(filter.selects, selectData)
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

/// `selchannels([str name]+)` converts a named channel from string to numbers.
///
/// returns [[channelName, channelNumber]+]
Function/WAVE SFO_OperationSelectChannels(variable jsonId, string jsonPath, string graph)

	variable numArgs, i, channelType
	string channelName, channelNumber
	string regExp = "^(?i)(" + ReplaceString(";", XOP_CHANNEL_NAMES, "|") + ")([0-9]+)?$"

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	WAVE channels = SFO_NewChannelsWave(numArgs ? numArgs : 1)
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

/// `selcm(mode, mode, ...)` // mode can be `ic`, `vc`, `izero`, `all`
/// see @ref SFClampModeStrings
///
/// returns a one element numeric wave with SF_OP_SELECTCM_CLAMPMODE_* ORed together from all arguments, see @ref SFClampcodeConstants
Function/WAVE SFO_OperationSelectCM(variable jsonId, string jsonPath, string graph)

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

/// `seldev(device)` // device is a string with optional wildcards
///
/// returns a one element text wave
Function/WAVE SFO_OperationSelectDevice(variable jsonId, string jsonPath, string graph)

	string expName

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTDEV, 1, maxArgs = 1)

	expName = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTDEV, 0)
	Make/FREE/T output = {expName}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTDEV, discardOpStack = 1, dataType = SF_DATATYPE_SELECTDEV)
End

/// `selexpandrac()` // no arguments
///
/// returns a one element numeric wave
Function/WAVE SFO_OperationSelectExpandRAC(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTEXPANDRAC, 0, maxArgs = 0)

	Make/FREE/D output = {1}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTEXPANDRAC, discardOpStack = 1, dataType = SF_DATATYPE_SELECTEXPANDRAC)
End

/// `selexpandsci()` // no arguments
///
/// returns a one element numeric wave
Function/WAVE SFO_OperationSelectExpandSCI(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTEXPANDSCI, 0, maxArgs = 0)

	Make/FREE/D output = {1}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTEXPANDSCI, discardOpStack = 1, dataType = SF_DATATYPE_SELECTEXPANDSCI)
End

/// `selexp(expName)` // expName is a string with optional wildcards
///
/// returns a one element text wave
Function/WAVE SFO_OperationSelectExperiment(variable jsonId, string jsonPath, string graph)

	string expName

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTEXP, 1, maxArgs = 1)

	expName = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTEXP, 0)
	Make/FREE/T output = {expName}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTEXP, discardOpStack = 1, dataType = SF_DATATYPE_SELECTEXP)
End

/// `SelIVSCCSetQC(passed | failed)`
///
/// returns a one element numeric wave with either SF_OP_SELECT_IVSCCSETQC_PASSED or SF_OP_SELECT_IVSCCSETQC_FAILED
Function/WAVE SFO_OperationSelectIVSCCSetQC(variable jsonId, string jsonPath, string graph)

	variable mode
	string   arg

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTIVSCCSETQC, 1, maxArgs = 1)

	arg  = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTIVSCCSETQC, 0, allowedValues = {SF_OP_SELECT_IVSCCQC_PASSED, SF_OP_SELECT_IVSCCQC_FAILED})
	mode = !CmpStr(arg, SF_OP_SELECT_IVSCCQC_PASSED) ? SF_OP_SELECT_IVSCCSETQC_PASSED : SF_OP_SELECT_IVSCCSETQC_FAILED

	Make/FREE output = {mode}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTIVSCCSETQC, discardOpStack = 1, dataType = SF_DATATYPE_SELECTIVSCCSETQC)
End

/// `SelIVSCCSweepQC(passed | failed)`
///
/// returns a one element numeric wave with either SF_OP_SELECT_IVSCCSWEEPQC_PASSED or SF_OP_SELECT_IVSCCSWEEPQC_FAILED
Function/WAVE SFO_OperationSelectIVSCCSweepQC(variable jsonId, string jsonPath, string graph)

	variable mode
	string   arg

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTIVSCCSWEEPQC, 1, maxArgs = 1)

	arg  = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTIVSCCSWEEPQC, 0, allowedValues = {SF_OP_SELECT_IVSCCQC_PASSED, SF_OP_SELECT_IVSCCQC_FAILED})
	mode = !CmpStr(arg, SF_OP_SELECT_IVSCCQC_PASSED) ? SF_OP_SELECT_IVSCCSWEEPQC_PASSED : SF_OP_SELECT_IVSCCSWEEPQC_FAILED

	Make/FREE output = {mode}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTIVSCCSWEEPQC, discardOpStack = 1, dataType = SF_DATATYPE_SELECTIVSCCSWEEPQC)
End

/// `selracindex(x)` // one numeric argument
///
/// returns a one element numeric wave
Function/WAVE SFO_OperationSelectRACIndex(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTRACINDEX, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTRACINDEX, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTRACINDEX, discardOpStack = 1, dataType = SF_DATATYPE_SELECTRACINDEX)
End

/// `selrange(rangespec)`
///
/// returns 1 dataset with range specification (either text or 2 point numerical wave)
Function/WAVE SFO_OperationSelectRange(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTRANGE, 0, maxArgs = 1)
	if(!numArgs)
		WAVE/WAVE range = SFH_AsDataSet(SFH_GetFullRange())
	else
		WAVE/WAVE range = SFH_EvaluateRange(jsonId, jsonPath, graph, SF_OP_SELECTRANGE, 0)
	endif

	return SFH_GetOutputForExecutorSingle(range, graph, SF_OP_SELECTRANGE, discardOpStack = 1, dataType = SF_DATATYPE_SELECTRANGE)
End

/// `selsciindex(x)` // one numeric argument
///
/// returns a one element numeric wave
Function/WAVE SFO_OperationSelectSCIIndex(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSCIINDEX, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTSCIINDEX, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSCIINDEX, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSCIINDEX)
End

/// `selsetcyclecount(x)` // one numeric argument
///
/// returns a one element numeric wave
Function/WAVE SFO_OperationSelectSetCycleCount(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSETCYCLECOUNT, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTSETCYCLECOUNT, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSETCYCLECOUNT, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSETCYCLECOUNT)
End

/// `selsetsweepcount(x)` // one numeric argument
///
/// returns a one element numeric wave
Function/WAVE SFO_OperationSelectSetSweepCount(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSETSWEEPCOUNT, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTSETSWEEPCOUNT, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSETSWEEPCOUNT, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSETSWEEPCOUNT)
End

/// `selstimset(stimsetName, stimsetName, ...)`
///
/// returns a N element text wave with stimset names
Function/WAVE SFO_OperationSelectStimset(variable jsonId, string jsonPath, string graph)

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

/// `selsweeps()`, `selsweeps(1,2,3, [4...6])`
/// returns all possible sweeps as 1d array
Function/WAVE SFO_OperationSelectSweeps(variable jsonId, string jsonPath, string graph)

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

/// `selvis(mode)` // mode can be `all` or `displayed`
///
/// returns a one element text wave with either SF_OP_SELECTVIS_ALL or SF_OP_SELECTVIS_DISPLAYED
Function/WAVE SFO_OperationSelectVis(variable jsonId, string jsonPath, string graph)

	string vis

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTVIS, 0, maxArgs = 1)

	vis = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTVIS, 0, allowedValues = {SF_OP_SELECTVIS_DISPLAYED, SF_OP_SELECTVIS_ALL}, defValue = SF_OP_SELECTVIS_DISPLAYED)
	Make/FREE/T output = {vis}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTVIS, discardOpStack = 1, dataType = SF_DATATYPE_SELECTVIS)
End

/// `setscale(data, dim, [dimOffset, [dimDelta[, unit]]])`
Function/WAVE SFO_OperationSetScale(variable jsonId, string jsonPath, string graph)

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

	output[] = SFO_OperationSetScaleImpl(dataRef[p], dimension[0], offset[0], delta[0], unit[0])

	return SFH_GetOutputForExecutor(output, graph, SF_OP_SETSCALE, clear = dataRef)
End

static Function/WAVE SFO_OperationSetScaleImpl(WAVE/Z input, string dim, variable offset, variable delta, string unit)

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

Function/WAVE SFO_OperationStdev(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "stdev requires at least one argument")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_STDEV)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_STDEV, DimSize(input, ROWS))

	output[] = SFO_OperationStdevImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_STDEV, SF_DATATYPE_STDEV)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_STDEV, clear = input)
End

static Function/WAVE SFO_OperationStdevImpl(WAVE/Z input)

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

// `store(name, ...)`
Function/WAVE SFO_OperationStore(variable jsonId, string jsonPath, string graph)

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

Function/WAVE SFO_OperationText(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "text requires at least one argument.")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_TEXT)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_TEXT, DimSize(input, ROWS))

	output[] = SFO_OperationTextImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_TEXT, JWN_GetStringFromWaveNote(input, SF_META_DATATYPE))

	return SFH_GetOutputForExecutor(output, graph, SF_OP_TEXT, clear = input)
End

static Function/WAVE SFO_OperationTextImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "text requires numeric input data.")
	Make/FREE/T/N=(DimSize(input, ROWS), DimSize(input, COLS), DimSize(input, LAYERS), DimSize(input, CHUNKS)) output
	Multithread output = num2strHighPrec(input[p][q][r][s], precision = 7)
	CopyScales input, output

	return output
End

Function/WAVE SFO_OperationVariance(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "variance requires at least one argument")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_VARIANCE)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_VARIANCE, DimSize(input, ROWS))

	output[] = SFO_OperationVarianceImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_VARIANCE, SF_DATATYPE_VARIANCE)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_VARIANCE, clear = input)
End

static Function/WAVE SFO_OperationVarianceImpl(WAVE/Z input)

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

Function/WAVE SFO_OperationWave(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_WAVE, 0, maxArgs = 1)

	WAVE/Z output = $SFH_GetArgumentAsText(jsonID, jsonPath, graph, SF_OP_WAVE, 0, defValue = "")

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_WAVE, discardOpStack = 1)
End

Function/WAVE SFO_OperationXValues(variable jsonId, string jsonPath, string graph)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	SFH_ASSERT(numArgs > 0, "xvalues requires at least one argument.")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(jsonId, jsonPath, graph, SF_OP_XVALUES)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_XVALUES, DimSize(input, ROWS))

	output[] = SFO_OperationXValuesImpl(input[p])

	return SFH_GetOutputForExecutor(output, graph, SF_OP_XVALUES, clear = input)
End

static Function/WAVE SFO_OperationXValuesImpl(WAVE/Z input)

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

static Function/WAVE SFO_IndexOverDataSetsForPrimitiveOperation(variable jsonId, string jsonPath, string graph, string opShort)

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
				output[] = SFO_OperationDivImplDataSets(arg0[p], arg1[p])
				break
			case SF_OPSHORT_PLUS:
				output[] = SFO_OperationPlusImplDataSets(arg0[p], arg1[p])
				break
			case SF_OPSHORT_MINUS:
				output[] = SFO_OperationMinusImplDataSets(arg0[p], arg1[p])
				break
			case SF_OPSHORT_MULT:
				output[] = SFO_OperationMultImplDataSets(arg0[p], arg1[p])
				break
			default:
				FATAL_ERROR("Unsupported primitive operation")
		endswitch
	elseif(dataSetNum1 == 1)
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, dataSetNum0)
		WAVE/WAVE input  = arg0
		strswitch(opShort)
			case SF_OPSHORT_DIV:
				output[] = SFO_OperationDivImplDataSets(arg0[p], arg1[0])
				break
			case SF_OPSHORT_PLUS:
				output[] = SFO_OperationPlusImplDataSets(arg0[p], arg1[0])
				break
			case SF_OPSHORT_MINUS:
				output[] = SFO_OperationMinusImplDataSets(arg0[p], arg1[0])
				break
			case SF_OPSHORT_MULT:
				output[] = SFO_OperationMultImplDataSets(arg0[p], arg1[0])
				break
			default:
				FATAL_ERROR("Unsupported primitive operation")
		endswitch
	elseif(dataSetNum0 == 1)
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, dataSetNum1)
		WAVE/WAVE input  = arg1
		strswitch(opShort)
			case SF_OPSHORT_DIV:
				output[] = SFO_OperationDivImplDataSets(arg0[0], arg1[p])
				break
			case SF_OPSHORT_PLUS:
				output[] = SFO_OperationPlusImplDataSets(arg0[0], arg1[p])
				break
			case SF_OPSHORT_MINUS:
				output[] = SFO_OperationMinusImplDataSets(arg0[0], arg1[p])
				break
			case SF_OPSHORT_MULT:
				output[] = SFO_OperationMultImplDataSets(arg0[0], arg1[p])
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

static Function SFO_AssertOnMismatchedWaves(WAVE data0, WAVE data1, string opShort)

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

static Function [WAVE/D holdWave, WAVE/D initialValues] SFO_ParseFitConstraints(WAVE/Z/T constraints, variable numParameters)

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

static Function/WAVE SFO_GetNumericVarArgs(variable jsonId, string jsonPath, string graph, string opShort)

	variable numArgs

	numArgs = SFH_CheckArgumentCount(jsonId, jsonPath, opShort, 1)
	if(numArgs == 1)
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, 0)
	else
		WAVE      wv    = SFE_FormulaExecutor(graph, jsonID, jsonPath = jsonPath)
		WAVE/WAVE input = SF_ResolveDataset(wv)
		SFH_ASSERT(DimSize(input, ROWS) == 1, "Expected a single data set")
		WAVE wNum = input[0]
		SFH_ASSERT(IsNumericWave(wNum), "Expected numeric wave")
	endif

	return input
End

threadsafe static Function SFO_RemoveEndOfSweepNaNs(WAVE/Z input)

	if(!WaveExists(input))
		return NaN
	endif

	FindValue/Z/FNAN input
	if(V_Value >= 0)
		Redimension/N=(V_Value) input
	endif
End

static Function/WAVE SFO_AverageDataOverSweeps(WAVE/WAVE input)

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
	MultiThread output[] = SFO_SweepAverageHelper(groupWaves[p])
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

threadsafe static Function/WAVE SFO_SweepAverageHelper(WAVE/WAVE group)

	WAVE/WAVE avgResult = MIES_fWaveAverage(group, 0, IGOR_TYPE_32BIT_FLOAT)

	return avgResult[0]
End

static Function SFO_InitSelectFilterUninitalized(STRUCT SF_SelectParameters &s)

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

threadsafe static Function/S SFO_GetSelectRowId(WAVE select, variable row)

	string str

	sprintf str, SF_GETSETINTERSECTIONSELECT_FORMAT, select[row][%SWEEP], select[row][%CHANNELTYPE], select[row][%CHANNELNUMBER], select[row][%SWEEPMAPINDEX]
	return str
End

static Function/WAVE SFO_CreateSelectWaveRowIds(WAVE select)

	Make/FREE/T/N=(DimSize(select, ROWS)) selectRowId
	Multithread selectRowId[] = SFO_GetSelectRowId(select, p)

	return selectRowId
End

/// @brief Returns the set intersection of two select waves from operation select
static Function/WAVE SFO_GetSetIntersectionSelect(WAVE select1, WAVE select2)

	WAVE rowId1 = SFO_CreateSelectWaveRowIds(select1)
	WAVE rowId2 = SFO_CreateSelectWaveRowIds(select2)

	WAVE/Z intersect = GetSetIntersection(rowId1, rowId2, getIndices = 1)
	if(!WaveExists(intersect))
		return $""
	endif

	WAVE output = SFH_NewSelectDataWave(DimSize(intersect, ROWS), 1)
	MultiThread output[][] = select1[intersect[p]][q]

	return output
End

static Function/WAVE SFO_GetUniqueSelectData(WAVE selectData)

	WAVE/T selectText       = SFO_CreateSelectWaveRowIds(selectData)
	WAVE/T selectTextUnique = GetUniqueEntries(selectText)
	return SFO_RestoreSelectDataFromText(selectTextUnique)
End

/// @brief Takes input selections and extends them. The extension of the selection is chosen through mode, one of SELECTDATA_MODE_*
///        For RAC: For each input selection adds all selections of the same repeated acquisition cycle
///        For SCI: For each input selection adds all selections of the same stimset cycle id and headstage
///        Returns all resulting unique selections.
static Function/WAVE SFO_GetSelectDataWithSCIorRAC(string graph, WAVE selectData, STRUCT SF_SelectParameters &filter, variable mode)

	variable i, j, isSweepBrowser, numSelected
	variable sweepNo, channelType, channelNumber, mapIndex
	variable addSweepNo

	ASSERT(mode == SELECTDATA_MODE_SCI || mode == SELECTDATA_MODE_RAC, "Unknown SCI/RAC mode")

	[STRUCT SF_SelectParameters filterDup] = SFO_DuplicateSelectFilter(filter)
	filterDup.vis                          = SF_OP_SELECTVIS_ALL

	isSweepBrowser = BSP_IsSweepBrowser(graph)
	if(isSweepBrowser)
		WAVE/T sweepMap = SB_GetSweepMap(graph)
		if(mode == SELECTDATA_MODE_SCI)
			Make/FREE/T/N=(GetNumberFromWaveNote(sweepMap, NOTE_INDEX)) sweepMapIds
			MultiThread sweepMapIds[] = SFO_GetSweepMapRowId(sweepMap, p)
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
		WAVE/Z additionalSweeps = SFO_GetAdditionalSweepsWithSameSCIorRAC(numericalValues, mode, sweepNo, channelType, channelNumber)
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
				MultiThread selectDataAdd[][%SWEEPMAPINDEX] = SFO_GetSweepMapIndexFromIds(sweepMapIds, filterDup.experimentName, sweepMap[mapIndex][%DataFolder], filterDup.device, additionalSweeps[p])
			else
				selectDataAdd[][%SWEEPMAPINDEX] = NaN
			endif
		else
			WAVE   filterDup.sweeps = additionalSweeps
			WAVE/Z selectDataAdd    = SFO_GetSelectData(graph, filterDup)
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

	return SFO_GetUniqueSelectData(selectDataCollect)
End

/// @brief sets uninitialized fields of the selection filter
static Function SFO_SetSelectionFilterDefaults(string graph, STRUCT SF_SelectParameters &filter, variable includeAll)

	includeAll = !!includeAll

	if(!WaveExists(filter.channels))
		WAVE filter.channels = SFE_ExecuteFormula("selchannels()", graph, singleResult = 1, checkExist = 1, useVariables = 0)
	endif
	if(!filter.sweepsSet)
		WAVE/Z filter.sweeps = SFE_ExecuteFormula("selsweeps()", graph, singleResult = 1, useVariables = 0)
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

static Function/S SFO_GetSelectionExperiment(string graph, string expName)

	string currentExperimentName

	if(BSP_IsDataBrowser(graph))
		currentExperimentName = GetExperimentName()
		SFH_ASSERT(stringmatch(currentExperimentName, expName), "Selected experiment does not exist")

		return currentExperimentName
	endif
	if(BSP_IsSweepBrowser(graph))
		return SFO_MatchSweepMapColumn(graph, expName, "FileName", SF_OP_SELECTEXP)
	endif

	FATAL_ERROR("Unknown browser type")
End

static Function/S SFO_GetSelectionDevice(string graph, string device)

	string deviceDB

	if(BSP_IsDataBrowser(graph))
		deviceDB = DB_GetDevice(graph)
		SFH_ASSERT(!IsEmpty(deviceDB), "DataBrowser has no locked device")
		SFH_ASSERT(stringmatch(deviceDB, device), "Selected device does not exist")

		return deviceDB
	endif
	if(BSP_IsSweepBrowser(graph))
		return SFO_MatchSweepMapColumn(graph, device, "Device", SF_OP_SELECTDEV)
	endif

	FATAL_ERROR("Unknown browser type")
End

/// @brief Use the labnotebook information to return the active channel numbers
///        for a given set of sweeps
///
/// @param graph  DataBrowser or SweepBrowser reference graph
/// @param filter filled SF_SelectParameters structure
///
/// @return a selectData style wave with three columns
///         containing sweepNumber, channelType and channelNumber
static Function/WAVE SFO_GetSelectData(string graph, STRUCT SF_SelectParameters &filter)

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
		WAVE      sweepPropertiesDisplayed = SFO_MakeSweepPropertiesDisplayed(numTraces)
		WAVE/WAVE sweepLNBsDisplayed       = SFO_MakeSweepLNBsDisplayed(numTraces)
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
				WAVE/Z mapIndices = SFO_GetSweepMapIndices(sweepMap, sweepNo, filter.experimentName, filter.device)
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

							clampCode = SFO_MapClampModeToSelectCM(sweepPropertiesDisplayed[l][SWEEPPROP_CLAMPMODE])
							if(!SFO_IsValidSingleSelection(filter, sweepLNBsDisplayed[l][%NUMERICAL], sweepLNBsDisplayed[l][%TEXTUAL], sweepNo, channelNumber, channelType, selectDisplayed[l][dimPosSweep], selectDisplayed[l][dimPosChannelNumber], selectDisplayed[l][dimPosChannelType], clampCode, sweepPropertiesDisplayed[l][SWEEPPROP_SETCYCLECOUNT], sweepPropertiesDisplayed[l][SWEEPPROP_SETSWEEPCOUNT], doStimsetMatching))
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

							if(SFO_FilterByClampModeEnabled(filter.clampMode, channelType))
								[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, CLAMPMODE_ENTRY_KEY, l, channelType, DATA_ACQUISITION_MODE)
								clampCode             = WaveExists(setting) ? SFO_MapClampModeToSelectCM(setting[index]) : SF_OP_SELECT_CLAMPCODE_NONE
							endif
							if(!IsNaN(filter.setCycleCount))
								[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "Set Cycle Count", l, channelType, DATA_ACQUISITION_MODE)
								setCycleCount         = WaveExists(setting) ? setting[index] : NaN
							endif
							if(!IsNaN(filter.setSweepCount))
								[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "Set Sweep Count", l, channelType, DATA_ACQUISITION_MODE)
								setSweepCount         = WaveExists(setting) ? setting[index] : NaN
							endif

							if(!SFO_IsValidSingleSelection(filter, numericalValues, textualValues, sweepNo, channelNumber, channelType, sweepNo, l, channelType, clampCode, setCycleCount, setSweepCount, doStimsetMatching))
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
	WAVE out = SFO_SortSelectData(selectData)

	return out
End

static Function/WAVE SFO_GetSelectDataWithRACorSCIIndex(string graph, WAVE selectData, variable index, variable mode)

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
			return SFO_GetSelectDataWithRACIndex(selectData, cycleIdsZapped, sweepMap, index)
		case SELECTDATA_MODE_SCI:
			return SFO_GetSelectDataWithSCIIndex(selectData, cycleIdsZapped, headStagesZapped, sweepMap, index)
		default:
			FATAL_ERROR("Unknown mode")
	endswitch
End

static Function/WAVE SFO_GetSelectDataWithRACIndex(WAVE selectData, WAVE cycleIds, WAVE/Z/T sweepMap, variable index)

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

static Function/WAVE SFO_GetSelectDataWithSCIIndex(WAVE selectData, WAVE cycleIds, WAVE headstages, WAVE/Z/T sweepMap, variable index)

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

static Function/WAVE SFO_GetAdditionalSweepsWithSameSCIorRAC(WAVE numericalValues, variable mode, variable sweepNo, variable channelType, variable channelNumber)

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

static Function/WAVE SFO_SortSelectData(WAVE selectData)

	variable dimPosSweep, dimPosChannelType, dimPosChannelNumber

	if(DimSize(selectData, ROWS) >= 1)
		dimPosSweep         = FindDimLabel(selectData, COLS, "SWEEP")
		dimPosChannelType   = FindDimLabel(selectData, COLS, "CHANNELTYPE")
		dimPosChannelNumber = FindDimLabel(selectData, COLS, "CHANNELNUMBER")

		SortColumns/KNDX={dimPosSweep, dimPosChannelType, dimPosChannelNumber} sortWaves=selectData
	endif

	return selectData
End

static Function/WAVE SFO_NewChannelsWave(variable size)

	ASSERT(size >= 0, "Invalid wave size specified")

	Make/N=(size, 2)/FREE out = NaN
	SetDimLabel COLS, 0, channelType, out
	SetDimLabel COLS, 1, channelNumber, out

	return out
End

threadsafe static Function SFO_ParseSelectText(WAVE/T selectText, WAVE selectData, variable index)

	variable sweepNo, channelNumber, channelType, mapIndex

	sscanf selectText[index], SF_GETSETINTERSECTIONSELECT_FORMAT, sweepNo, channelType, channelNumber, mapIndex
	ASSERT_TS(V_flag == 4, "Failed parsing selectText")
	selectData[index][%SWEEP]         = sweepNo
	selectData[index][%CHANNELNUMBER] = channelNumber
	selectData[index][%CHANNELTYPE]   = channelType
	selectData[index][%SWEEPMAPINDEX] = mapIndex

	return sweepNo
End

static Function/WAVE SFO_RestoreSelectDataFromText(WAVE/T selectText)

	WAVE selectData = SFH_NewSelectDataWave(DimSize(selectText, ROWS), 1)
	MultiThread selectData[][%SWEEP] = SFO_ParseSelectText(selectText, selectData, p)

	return selectData
End

static Function [STRUCT SF_SelectParameters filterDup] SFO_DuplicateSelectFilter(STRUCT SF_SelectParameters &filter)

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

threadsafe static Function/S SFO_CreateSweepMapRowId(string experiment, string datafolder, string device, string sweep)

	string id

	sprintf id, "%s|%s|%s|%s", experiment, datafolder, device, sweep

	return id
End

threadsafe static Function/S SFO_GetSweepMapRowId(WAVE/T sweepMap, variable index)

	return SFO_CreateSweepMapRowId(sweepMap[index][%FileName], sweepMap[index][%DataFolder], sweepMap[index][%Device], sweepMap[index][%Sweep])
End

threadsafe static Function SFO_GetSweepMapIndexFromIds(WAVE/T sweepMapIds, string experiment, string datafolder, string device, variable sweepNo)

	string id

	id = SFO_CreateSweepMapRowId(experiment, datafolder, device, num2istr(sweepNo))
	FindValue/TXOP=4/TEXT=id sweepMapIds
	ASSERT_TS(V_row >= 0, "SweepMap id not found")

	return V_row
End

static Function/S SFO_MatchSweepMapColumn(string graph, string match, string colLabel, string opShort)

	variable col

	WAVE/T sweepMap = SB_GetSweepMap(graph)
	WAVE/Z indices  = SFO_GetSweepMapIndices(sweepMap, NaN, "", "", colLabel = colLabel, wildCardPattern = match)
	SFH_ASSERT(WaveExists(indices), "No match found in sweepMap in operation " + opShort)

	col = FindDimlabel(sweepMap, COLS, colLabel)
	Make/FREE/T/N=(DimSize(indices, ROWS)) entries
	MultiThread entries[] = sweepMap[indices[p]][col]

	WAVE/T uniqueEntries = GetUniqueEntries(entries)
	SFH_ASSERT(DimSize(uniqueEntries, ROWS) < 2, "Multiple matches found in sweepMap in operation " + opShort)
	SFH_ASSERT(DimSize(uniqueEntries, ROWS) == 1, "No match found in sweepMap in operation " + opShort)

	return uniqueEntries[0]
End

static Function/WAVE SFO_MakeSweepPropertiesDisplayed(variable numTraces)

	Make/FREE/D/N=(numTraces, SWEEPPROP_END) sweepPropertiesDisplayed

	return sweepPropertiesDisplayed
End

static Function/WAVE SFO_MakeSweepLNBsDisplayed(variable numTraces)

	Make/FREE/WAVE/N=(numTraces, 2) wv
	SetDimLabel COLS, 0, NUMERICAL, wv
	SetDimLabel COLS, 1, TEXTUAL, wv

	return wv
End

/// @brief Return the matching indices of sweepMap, if expName or device is an emtpy string then it is ignored
static Function/WAVE SFO_GetSweepMapIndices(WAVE/T sweepMap, variable sweepNo, string expName, string device, [string colLabel, string wildCardPattern])

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

static Function SFO_MapClampModeToSelectCM(variable clampMode)

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

static Function SFO_IsValidSingleSelection(STRUCT SF_SelectParameters &filter, WAVE numericalValues, WAVE textualValues, variable filtSweepNo, variable filtChannelNumber, variable filtChannelType, variable sweepNo, variable channelNumber, variable channelType, variable clampMode, variable setCycleCount, variable setSweepCount, variable doStimsetMatching)

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

	if(SFO_FilterByClampModeEnabled(filter.clampMode, channelType) && !(filter.clampMode & clampMode))
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

static Function SFO_FilterByClampModeEnabled(variable clampModeFilter, variable channelType)

	return clampModeFilter != SF_OP_SELECT_CLAMPCODE_ALL && (channelType == XOP_CHANNEL_TYPE_DAC || channelType == XOP_CHANNEL_TYPE_ADC)
End
