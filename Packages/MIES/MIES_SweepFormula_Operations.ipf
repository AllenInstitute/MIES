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

static StrConstant SF_OP_IVSCCAPFREQUENCY_FIRST = "first"
static StrConstant SF_OP_IVSCCAPFREQUENCY_MIN   = "min"
static StrConstant SF_OP_IVSCCAPFREQUENCY_MAX   = "max"
static StrConstant SF_OP_IVSCCAPFREQUENCY_NONE  = "none"

static StrConstant SF_OP_AVG_INSWEEPS   = "in"
static StrConstant SF_OP_AVG_OVERSWEEPS = "over"
static StrConstant SF_OP_AVG_GROUPS     = "group"
static StrConstant SF_OP_AVG_BINS       = "bins"
static StrConstant SF_OP_AVG_BINS2      = "bins2"

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

static StrConstant SF_AVERAGING_NONSWEEPDATA_LBL = "NOSWEEPDATA"

static Constant SF_IVSCC_APFREQUENCY_OPACITY = 13107 // 0.2 * 65535

static StrConstant SF_PREPAREFIT_NOFUNC    = "none"

static Constant SF_FIT2_MAX_ITERATIONS = 40

Function/WAVE SFO_OperationAnaFuncParam(STRUCT SF_ExecutionData &exd)

	SFH_CheckArgumentCount(exd, SF_OP_ANAFUNCPARAM, 0, maxArgs = 2)

	WAVE/T names      = SFH_GetArgumentAsWave(exd, SF_OP_ANAFUNCPARAM, 0, singleResult = 1)
	WAVE/Z selectData = SFH_GetArgumentSelect(exd, 1)

	WAVE/WAVE output = SFO_OperationAnaFuncParamIterate(exd.graph, names, selectData, SF_OP_ANAFUNCPARAM)

	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_ANAFUNCPARAM, ""))
	JWN_SetStringInWaveNote(output, SF_META_WINDOW_HOOK, "TraceValueDisplayHook")

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_ANAFUNCPARAM)
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
	variable mapIndex
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
			mapIndex = JWN_GetNumberFromWaveNote(paramsSingle, SF_META_SWEEPMAPINDEX)

			JWN_SetNumberInWaveNote(out, SF_META_SWEEPNO, sweepNo)
			JWN_SetNumberInWaveNote(out, SF_META_CHANNELTYPE, chanType)
			JWN_SetNumberInWaveNote(out, SF_META_CHANNELNUMBER, chanNr)
			JWN_SetNumberInWaveNote(out, SF_META_SWEEPMAPINDEX, mapIndex)
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

static Function [variable method, variable level, string timeFreq, string normalize, string xAxisType] SFO_GetApFrequencyArguments(STRUCT SF_ExecutionData &exd, string opShort, variable offset)

	method    = SFH_GetArgumentAsNumeric(exd, opShort, offset, defValue = SF_APFREQUENCY_FULL, allowedValues = {SF_APFREQUENCY_FULL, SF_APFREQUENCY_INSTANTANEOUS, SF_APFREQUENCY_APCOUNT, SF_APFREQUENCY_INSTANTANEOUS_PAIR})
	level     = SFH_GetArgumentAsNumeric(exd, opShort, offset + 1, defValue = 0)
	timeFreq  = SFH_GetArgumentAsText(exd, opShort, offset + 2, defValue = SF_OP_APFREQUENCY_Y_FREQ, allowedValues = {SF_OP_APFREQUENCY_Y_TIME, SF_OP_APFREQUENCY_Y_FREQ})
	normalize = SFH_GetArgumentAsText(exd, opShort, offset + 3, defValue = SF_OP_APFREQUENCY_NONORM, allowedValues = {                                      \
	                                                                                                                  SF_OP_APFREQUENCY_NONORM,             \
	                                                                                                                  SF_OP_APFREQUENCY_NORMOVERSWEEPSMIN,  \
	                                                                                                                  SF_OP_APFREQUENCY_NORMOVERSWEEPSMAX,  \
	                                                                                                                  SF_OP_APFREQUENCY_NORMOVERSWEEPSAVG,  \
	                                                                                                                  SF_OP_APFREQUENCY_NORMWITHINSWEEPMIN, \
	                                                                                                                  SF_OP_APFREQUENCY_NORMWITHINSWEEPMAX, \
	                                                                                                                  SF_OP_APFREQUENCY_NORMWITHINSWEEPAVG  \
	                                                                                                                 })
	xAxisType = SFH_GetArgumentAsText(exd, opShort, offset + 4, defValue = SF_OP_APFREQUENCY_X_TIME, allowedValues = {SF_OP_APFREQUENCY_X_TIME, SF_OP_APFREQUENCY_X_COUNT})

	return [method, level, timeFreq, normalize, xAxisType]
End

// apfrequency(data, [frequency calculation method], [spike detection crossing level], [result value type], [normalize], [x-axis type])
Function/WAVE SFO_OperationApFrequency(STRUCT SF_ExecutionData &exd)

	variable i, numArgs, keepX, method, level, normValue
	string xLabel, methodStr, timeFreq, normalize, xAxisType
	string   opShort    = SF_OP_APFREQUENCY
	variable numArgsMin = 1
	variable numArgsMax = 6

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs <= numArgsMax, "ApFrequency has " + num2istr(numArgsMax) + " arguments at most.")
	SFH_ASSERT(numArgs >= numArgsMin, "ApFrequency needs at least " + num2istr(numArgsMin) + " argument(s).")

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	[method, level, timeFreq, normalize, xAxisType] = SFO_GetApFrequencyArguments(exd, opShort, 1)

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
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, DimSize(input, ROWS))
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

	return SFH_GetOutputForExecutor(output, exd.graph, opShort)
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

Function/WAVE SFO_OperationArea(STRUCT SF_ExecutionData &exd)

	variable zero, numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs >= 1, "area requires at least one argument.")
	SFH_ASSERT(numArgs <= 2, "area requires at most two arguments.")

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)

	zero = !!SFH_GetArgumentAsNumeric(exd, SF_OP_AREA, 1, defValue = 1)

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_AREA, DimSize(input, ROWS))

	output[] = SFO_OperationAreaImpl(input[p], zero)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_AREA, SF_DATATYPE_AREA)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_AREA, clear = input)
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

Function/WAVE SFO_OperationAvg(STRUCT SF_ExecutionData &exd)

	variable numArgs, binWidth
	string mode
	string opShort = SF_OP_AVG

	numArgs = SFH_CheckArgumentCount(exd, opShort, 1, maxArgs = 5)

	mode = SFH_GetArgumentAsText(exd, opShort, 1, defValue = SF_OP_AVG_INSWEEPS, allowedValues = {SF_OP_AVG_INSWEEPS, SF_OP_AVG_OVERSWEEPS, SF_OP_AVG_GROUPS, SF_OP_AVG_BINS, SF_OP_AVG_BINS2})
	if(!CmpStr(mode, SF_OP_AVG_INSWEEPS) || !CmpStr(mode, SF_OP_AVG_OVERSWEEPS))
		WAVE/WAVE input = SFH_GetArgumentAsWave(exd, opShort, 0, resolveSelect = 1)
		strswitch(mode)
			case SF_OP_AVG_INSWEEPS:
				WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, DimSize(input, ROWS))
				output[] = SFO_OperationAvgImplIn(input[p])
				SFH_TransferFormulaDataWaveNoteAndMeta(input, output, opShort, SF_DATATYPE_AVG)
				return SFH_GetOutputForExecutor(output, exd.graph, opShort, clear = input)

			case SF_OP_AVG_OVERSWEEPS:
				return SFO_OperationAvgImplOver(input, exd.graph, opShort)

			default:
				FATAL_ERROR("Unhandled avg operation mode")
		endswitch
	elseif(!CmpStr(mode, SF_OP_AVG_GROUPS))
		WAVE/WAVE dataFromEachGroup = SFH_GetDatasetArrayAsResolvedWaverefs(exd, 0, resolveSelect = 1)
		WAVE/WAVE averagedGroup     = SFO_OperationAvgImplSweepGroups(dataFromEachGroup, exd.graph, opShort)

		return SFH_GetOutputForExecutor(averagedGroup, exd.graph, opShort)
	elseif(!CmpStr(mode, SF_OP_AVG_BINS))
		WAVE/WAVE dataFromEachGroup = SFH_GetDatasetArrayAsResolvedWaverefs(exd, 0, resolveSelect = 1)
		WAVE/WAVE wTmp              = SFH_GetArgumentAsWave(exd, opShort, 2)
		WAVE      binRange          = wTmp[0]
		SFH_ASSERT(DimSize(binRange, ROWS) == 2, "Expected range in the form of [start, end]")
		SFH_ASSERT(binRange[1] > binRange[0], "The end of the bin range must be greater than the start")
		binWidth = SFH_GetArgumentAsNumeric(exd, opShort, 3, checkFunc = IsStrictlyPositiveAndFinite)
		WAVE/WAVE binData = SFH_GetDatasetArrayAsResolvedWaverefs(exd, 4, resolveSelect = 1)
		SFH_ASSERT(DimSize(dataFromEachGroup, ROWS) == DimSize(binData, ROWS), "input data and bin data must have the same number of groups")
		WAVE/WAVE averagedBins = SFO_OperationAvgImplBins(dataFromEachGroup, exd.graph, opShort, binData, binRange, binWidth)
		return SFH_GetOutputForExecutor(averagedBins, exd.graph, opShort)
	elseif(!CmpStr(mode, SF_OP_AVG_BINS2))
		WAVE/WAVE dataFromEachGroup = SFH_GetDatasetArrayAsResolvedWaverefs(exd, 0, resolveSelect = 1)
		WAVE/WAVE binData           = SFH_GetDatasetArrayAsResolvedWaverefs(exd, 2, resolveSelect = 1)
		SFH_ASSERT(DimSize(dataFromEachGroup, ROWS) == DimSize(binData, ROWS), "input data and bin data must have the same number of groups")
		WAVE/WAVE averagedBins = SFO_OperationAvgImplBins2(dataFromEachGroup, exd.graph, opShort, binData)
		return SFH_GetOutputForExecutor(averagedBins, exd.graph, opShort)
	endif
End

static Function/WAVE SFO_OperationAvgImplBins2(WAVE/WAVE input, string graph, string opShort, WAVE/WAVE binData)

	variable i, j, maxBins, numGroups, numDataSets, idx, numBins, numEntries, size, xValue, xSdev, ySdev
	string          unit
	STRUCT RGBColor s

	printf "avg in bins2 mode:\r"

	[s] = GetTraceColorForAverage()
	Make/FREE/W/U traceColor = {s.red, s.green, s.blue}

	numGroups = DimSize(input, ROWS)

	// Sort
	Make/FREE/WAVE/N=(numGroups) sortedDatasetGroups, sortedBinDatasets
	for(i = 0; i < numGroups; i += 1)
		WAVE/WAVE dataSets    = input[i]
		WAVE/WAVE binDataSets = binData[i]

		numDataSets = DimSize(dataSets, ROWS)
		printf "Group %d, num datasets %d\r", i, numDataSets
		SFH_ASSERT(numDataSets == DimSize(binDataSets, ROWS), "The number of datasets of the input and bins are not the same for group " + num2istr(i))
		Make/FREE/D/N=(numDataSets) sortedKey
		for(j = 0; j < numDataSets; j += 1)
			SFH_ASSERT(WaveExists(binDataSets[j]), "A bin dataset is null")
			SFH_ASSERT(IsNumericWave(binDataSets[j]), "A bin dataset must be numeric")
			SFH_ASSERT(DimSize(binDataSets[j], ROWS) == 1, "A bin dataset must have exactly one value")
			sortedKey[j] = WaveRef(binDataSets, row = j)[0]
			if(IsNull(unit))
				unit = WaveUnits(binDataSets[j], ROWS)
			endif
		endfor

		Duplicate/FREE/WAVE dataSets, sortedDatasets
		Sort sortedKey, sortedKey, sortedDatasets
		sortedDatasetGroups[i] = sortedDatasets
		sortedBinDatasets[i]   = sortedKey
		maxBins                = max(maxBins, numDataSets)
	endfor

	// Gather
	Make/FREE/WAVE/N=(maxBins) filledBins, xValuesBin
	for(i = 0; i < numGroups; i += 1)
		WAVE/WAVE sortedDatasets = sortedDatasetGroups[i]
		WAVE      binXValues     = sortedBinDatasets[i]
		numDataSets = DimSize(sortedDatasets, ROWS)
		for(j = 0; j < numDataSets; j += 1)
			if(!WaveExists(sortedDatasets[j]))
				continue
			endif
			// Add to bin
			WAVE/Z/WAVE wavesInBin = filledBins[j]
			if(!WaveExists(wavesInBin))
				Make/FREE/WAVE wavesInBin = {sortedDatasets[j]}
				SetNumberInWaveNote(wavesInBin, NOTE_INDEX, 1)
				filledBins[j] = wavesInBin
				Make/FREE/D xValues = {binXValues[j]}
				SetNumberInWaveNote(xValues, NOTE_INDEX, 1)
				xValuesBin[j] = xValues
				printf "Group %d, Bin %d, add at index %d\r", i, j, 0
				continue
			endif
			idx = GetNumberFromWaveNote(wavesInBin, NOTE_INDEX)
			printf "Group %d, Bin %d, add at index %d\r", i, j, idx
			WAVE xValues = xValuesBin[j]
			EnsureLargeEnoughWave(wavesInBin, indexShouldExist = idx)
			EnsureLargeEnoughWave(xValues, indexShouldExist = idx)
			wavesInBin[idx] = sortedDatasets[j]
			xValues[idx]    = binXValues[j]
			SetNumberInWaveNote(wavesInBin, NOTE_INDEX, idx + 1)
			SetNumberInWaveNote(xValues, NOTE_INDEX, idx + 1)
		endfor
	endfor

	for(i = 0; i < maxBins; i += 1)
		if(WaveExists(filledBins[i]))
			printf "Bin %d, filling %d\r", i, GetNumberFromWaveNote(filledBins[i], NOTE_INDEX)
		else
			printf "Bin %d, filling %d\r", i, 0
		endif
	endfor

	// Cutoff
	for(i = 0; i < maxBins; i += 1)
		if(!WaveExists(filledBins[i]))
			break
		endif
		if(GetNumberFromWaveNote(filledBins[i], NOTE_INDEX) < 2)
			break
		endif
	endfor
	numBins = i
	printf "Cutoff after bin %d\r", i - 1
	Redimension/N=(numBins) filledBins, xValuesBin

	// avg same bins
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numBins)
	for(i = 0; i < numBins; i += 1)
		WAVE/WAVE wavesInBin = filledBins[i]
		numEntries = GetNumberFromWaveNote(wavesInBin, NOTE_INDEX)
		Redimension/N=(numEntries) wavesInBin

		WAVE/WAVE avg = MIES_fWaveAverage(wavesInBin, 1, IGOR_TYPE_64BIT_FLOAT)
		output[i] = avg[0]

		size = DimSize(wavesInBin, ROWS)
		Make/FREE/D/N=(size) valuesFromBin = WaveRef(wavesInBin, row = p)[0]
		WaveStats/Q valuesFromBin
		ySdev = V_sdev

		WAVE xValues = xValuesBin[i]
		Redimension/N=(numEntries) xValues
		xValue = mean(xValues)
		WaveStats/Q xValues
		xSdev = V_sdev

		WAVE wTmp = output[i]
		printf "Bin: %d Avg result: %f, xValue: %f, ySdev: %f, xSdev: %f\r", i, wTmp[0], xValue, ySdev, xSdev

		JWN_SetWaveInWaveNote(output[i], SF_META_TRACECOLOR, traceColor)
		JWN_SetNumberInWaveNote(output[i], SF_META_TRACETOFRONT, 1)
		JWN_SetNumberInWaveNote(output[i], SF_META_LINESTYLE, 0)
		JWN_SetWaveInWaveNote(output[i], SF_META_XVALUES, {xValue})
		JWN_SetWaveInWaveNote(output[i], SF_META_ERRORBARYPLUS, {ySdev})
		JWN_SetWaveInWaveNote(output[i], SF_META_ERRORBARYMINUS, {ySdev})
		JWN_SetWaveInWaveNote(output[i], SF_META_ERRORBARXPLUS, {xSdev})
		JWN_SetWaveInWaveNote(output[i], SF_META_ERRORBARXMINUS, {xSdev})
	endfor

	if(IsEmpty(unit))
		unit = "x"
	endif
	JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, unit)

	return output
End

static Function/WAVE SFO_OperationAvgImplBins(WAVE/WAVE input, string graph, string opShort, WAVE/WAVE binData, WAVE binRange, variable binWidth)

	variable i, j, numBins, binStart, binEnd, numGroups, numDataSets, binValue, binPos, idx
	STRUCT RGBColor s

	printf "avg in bins mode:\r"

	[s] = GetTraceColorForAverage()
	Make/FREE/W/U traceColor = {s.red, s.green, s.blue}

	numGroups = DimSize(input, ROWS)
	binStart  = binRange[0]
	binEnd    = binRange[1]
	numBins   = ceil((binEnd - binStart) / binWidth)
	SFH_ASSERT(numBins < 1E6, "Maximum number of bins is 1E6.")

	// Gather
	Make/FREE/WAVE/N=(numBins, numGroups) binnedPerGroup
	for(i = 0; i < numGroups; i += 1)
		WAVE/WAVE dataSets    = input[i]
		WAVE/WAVE binDataSets = binData[i]
		numDataSets = DimSize(dataSets, ROWS)
		SFH_ASSERT(numDataSets == DimSize(binDataSets, ROWS), "The number of datasets of the input and bins are not the same for group " + num2istr(i))
		for(j = 0; j < numDataSets; j += 1)
			if(!WaveExists(dataSets[j]))
				continue
			endif
			SFH_ASSERT(WaveExists(binDataSets[j]), "A bin dataset is null")
			SFH_ASSERT(IsNumericWave(binDataSets[j]), "A bin dataset must be numeric")
			SFH_ASSERT(DimSize(binDataSets[j], ROWS) == 1, "A bin dataset must have exactly one value")
			binValue = WaveRef(binDataSets, row = j)[0]
			if(binValue < binStart || binValue >= binEnd)
				continue
			endif
			binPos = floor((binValue - binStart) / binWidth)
			// Add to bin
			WAVE/Z/WAVE wavesInBin = binnedPerGroup[binPos][i]
			if(!WaveExists(wavesInBin))
				Make/FREE/WAVE wavesInBin = {dataSets[j]}
				SetNumberInWaveNote(wavesInBin, NOTE_INDEX, 1)
				binnedPerGroup[binPos][i] = wavesInBin
				continue
			endif
			idx = GetNumberFromWaveNote(wavesInBin, NOTE_INDEX)
			EnsureLargeEnoughWave(wavesInBin, indexShouldExist = idx)
			wavesInBin[idx] = dataSets[j]
			SetNumberInWaveNote(wavesInBin, NOTE_INDEX, idx + 1)
		endfor
	endfor
	printf "Averaging bins:\r"
	// avg bins with multiple filling
	for(i = 0; i < numBins; i += 1)
		for(j = 0; j < numGroups; j += 1)
			if(!WaveExists(binnedPerGroup[i][j]))
				continue
			endif
			WAVE/WAVE wavesInBin = binnedPerGroup[i][j]
			idx = GetNumberFromWaveNote(wavesInBin, NOTE_INDEX)
			Redimension/N=(idx) wavesInBin
			printf "Bin %d, Group %d, NumWaves %d, ", i, j, idx
			if(idx == 1)
				WAVE wTmp = wavesInBin[0]
				print "Result:", wTmp[0]

				continue
			endif
			WAVE/WAVE avg = MIES_fWaveAverage(wavesInBin, 1, IGOR_TYPE_64BIT_FLOAT)
			Redimension/N=(1) wavesInBin
			wavesInBin[0] = avg[0]

			WAVE wTmp = avg[0]
			print "Result:", wTmp[0]

		endfor
	endfor
	// avg same bins
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numBins)
	for(i = 0; i < numBins; i += 1)
		Make/FREE/WAVE/N=(numGroups) sameBin
		idx = 0
		for(j = 0; j < numGroups; j += 1)
			if(!WaveExists(binnedPerGroup[i][j]))
				continue
			endif
			WAVE/WAVE wavesInBin = binnedPerGroup[i][j]
			sameBin[idx] = wavesInBin[0]
			idx         += 1
		endfor
		printf "Bin %d, NumWaves/TotalGroups %d/%d:\r", i, idx, numGroups
		if(idx == 0)
			Make/FREE/D tmp = {NaN}
			output[i] = tmp
		else
			Redimension/N=(idx) sameBin
			WAVE/WAVE avg = MIES_fWaveAverage(sameBin, 1, IGOR_TYPE_64BIT_FLOAT)
			output[i] = avg[0]

			WAVE wTmp = output[i]
			printf "Avg result: %f\r", wTmp[0]
		endif
		JWN_SetWaveInWaveNote(output[i], SF_META_TRACECOLOR, traceColor)
		JWN_SetNumberInWaveNote(output[i], SF_META_TRACETOFRONT, 1)
		JWN_SetNumberInWaveNote(output[i], SF_META_LINESTYLE, 0)
	endfor

	return output
End

static Function/WAVE SFO_OperationAvgImplSweepGroups(WAVE/WAVE sweepsFromEachSelection, string graph, string opShort)

	variable numData, numMaxSweeps, numGroups, i, j, maxIdx
	STRUCT RGBColor s

	[s] = GetTraceColorForAverage()
	Make/FREE/W/U traceColor = {s.red, s.green, s.blue}

	numGroups = DimSize(sweepsFromEachSelection, ROWS)
	Make/FREE/D/N=(numGroups) sweepCnts = DimSize(sweepsFromEachSelection[p], ROWS)
	WaveStats/Q/M=1 sweepCnts
	numMaxSweeps = V_max
	maxIdx       = V_maxRowLoc
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numMaxSweeps)
	for(i = 0; i < numMaxSweeps; i += 1)
		Make/FREE/WAVE/N=(numGroups) avgSet
		numData = 0
		for(j = 0; j < numGroups; j += 1)
			if(DimSize(sweepsFromEachSelection[j], ROWS) > i)
				avgSet[numData] = WaveRef(sweepsFromEachSelection[j], row = i)
				numData        += 1
			endif
		endfor
		Redimension/N=(numData) avgSet
		WAVE/WAVE avg = MIES_fWaveAverage(avgSet, 1, IGOR_TYPE_64BIT_FLOAT)
		output[i] = avg[0]
		JWN_SetWaveInWaveNote(output[i], SF_META_TRACECOLOR, traceColor)
		JWN_SetNumberInWaveNote(output[i], SF_META_TRACETOFRONT, 1)
		JWN_SetNumberInWaveNote(output[i], SF_META_LINESTYLE, 0)
	endfor
	SFH_TransferFormulaDataWaveNoteAndMeta(sweepsFromEachSelection[maxIdx], output, opShort, SF_DATATYPE_AVG)

	return output
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
Function/WAVE SFO_OperationButterworth(STRUCT SF_ExecutionData &exd)

	variable lowPassCutoff, highPassCutoff, order

	SFH_CheckArgumentCount(exd, SF_OP_BUTTERWORTH, 4, maxArgs = 4)

	WAVE/WAVE input = SFH_GetArgumentAsWave(exd, SF_OP_BUTTERWORTH, 0, copy = 1)
	lowPassCutoff  = SFH_GetArgumentAsNumeric(exd, SF_OP_BUTTERWORTH, 1)
	highPassCutoff = SFH_GetArgumentAsNumeric(exd, SF_OP_BUTTERWORTH, 2)
	order          = SFH_GetArgumentAsNumeric(exd, SF_OP_BUTTERWORTH, 3)

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_BUTTERWORTH, DimSize(input, ROWS))

	output[] = SFO_OperationButterworthImpl(input[p], lowPassCutoff, highPassCutoff, order)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_BUTTERWORTH, SF_DATATYPE_BUTTERWORTH)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_BUTTERWORTH, clear = input)
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
Function/WAVE SFO_OperationConcat(STRUCT SF_ExecutionData &exd)

	variable numArgs, i, err, majorType, sliceMajorType
	variable constantDataType
	string refDataType, dataType, wvNote, errMsg

	numArgs = SFH_CheckArgumentCount(exd, SF_OP_CONCAT, 1)

	WAVE result = SFH_GetArgumentAsWave(exd, SF_OP_CONCAT, 0, copy = 1, singleResult = 1, wvNote = wvNote)
	majorType = WaveType(result, 1)

	refDataType      = JWN_GetStringFromNote(wvNote, SF_META_DATATYPE)
	dataType         = refDataType
	constantDataType = !IsEmpty(refDataType)
	Note/K result

	AssertOnAndClearRTError()
	for(i = 1; i < numArgs; i += 1)
		WAVE slice = SFH_GetArgumentAsWave(exd, SF_OP_CONCAT, i, singleResult = 1, wvNote = wvNote)
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
	return SFH_GetOutputForExecutorSingle(result, exd.graph, SF_OP_CONCAT, discardOpStack = 1, dataType = dataType)
End

Function/WAVE SFO_OperationCursors(STRUCT SF_ExecutionData &exd)

	variable i
	string   info
	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	if(!numArgs)
		Make/FREE/T wvT = {"A", "B"}
		numArgs = 2
	else
		Make/FREE/T/N=(numArgs) wvT
		for(i = 0; i < numArgs; i += 1)
			WAVE/T csrName = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_CURSORS, i, checkExist = 1)
			SFH_ASSERT(IsTextWave(csrName), "cursors argument at " + num2istr(i) + " must be textual.")
			wvT[i] = csrName[0]
		endfor
	endif
	Make/FREE/N=(numArgs)/D out = NaN
	for(i = 0; i < numArgs; i += 1)
		SFH_ASSERT(GrepString(wvT[i], "^(?i)[A-J]$"), "Invalid Cursor Name")
		if(IsEmpty(exd.graph))
			out[i] = xcsr($wvT[i])
		else
			info = CsrInfo($wvT[i], exd.graph)
			if(IsEmpty(info))
				continue
			endif
			out[i] = xcsr($wvT[i], exd.graph)
		endif
	endfor

	return SFH_GetOutputForExecutorSingle(out, exd.graph, SF_OP_CURSORS, discardOpStack = 1)
End

/// `data(array range[, array selectData])`
///
/// returns [sweepData][sweeps][channelTypeNumber] for all sweeps selected by selectData
Function/WAVE SFO_OperationData(STRUCT SF_ExecutionData &exd)

	variable i, numArgs

	SFH_CheckArgumentCount(exd, SF_OP_DATA, 0, maxArgs = 1)
	WAVE/WAVE selectData = SFH_GetArgumentSelect(exd, 0)

	WAVE output = SFH_GetDataFromSelect(exd.graph, selectData)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_DATA)
End

// dataset(array data1, array data2, ...)
Function/WAVE SFO_OperationDataset(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_DATASET, numArgs)

	output[] = SFH_GetArgumentAsWave(exd, SF_OP_DATASET, p, singleResult = 1)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_DATASET)
End

// extract(<dataset>, index)
Function/WAVE SFO_OperationExtract(STRUCT SF_ExecutionData &exd)

	variable idx
	string opShort = SF_OP_EXTRACT

	SFH_CheckArgumentCount(exd, opShort, 2, maxArgs = 2)

	WAVE/WAVE datasets = SFH_GetArgumentAsWave(exd, opShort, 0)
	idx = SFH_GetArgumentAsNumeric(exd, opShort, 1)
	SFH_ASSERT(idx >= 0 && idx < DimSize(datasets, ROWS), "index out of range")

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, 1)
	output[0] = datasets[idx]

	return SFH_GetOutputForExecutor(output, exd.graph, opShort)
End

Function/WAVE SFO_OperationDerivative(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(exd, SF_OP_DERIVATIVE)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_DERIVATIVE, DimSize(input, ROWS))

	output[] = SFO_OperationDerivativeImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_DERIVATIVE, SF_DATATYPE_DERIVATIVE)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_DERIVATIVE, clear = input)
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

Function/WAVE SFO_OperationDiv(STRUCT SF_ExecutionData &exd)

	WAVE output = SFO_IndexOverDataSetsForPrimitiveOperation(exd, SF_OPSHORT_DIV)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OPSHORT_DIV)
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
Function/WAVE SFO_OperationEpochs(STRUCT SF_ExecutionData &exd)

	variable numArgs, epType

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs >= 1 && numArgs <= 3, "epochs requires at least 1 and at most 3 arguments")

	if(numArgs == 3)
		WAVE/T epochType = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_EPOCHS, 2, checkExist = 1)
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
	WAVE/Z/WAVE selectDataArray = SFH_GetArgumentSelect(exd, 1)
	if(WaveExists(selectDataArray))
		SFH_ASSERT(DimSize(selectDataArray, ROWS) == 1, "Expected a single select specification")
		WAVE/Z/WAVE selectDataComp = selectDataArray[0]
		if(WaveExists(selectDataComp))
			WAVE/Z selectData = selectDataComp[%SELECTION]
		endif
	endif

	WAVE/T epochPatterns = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_EPOCHS, 0, checkExist = 1)
	SFH_ASSERT(IsTextWave(epochPatterns), "Epoch pattern argument must be textual")

	WAVE/WAVE output = SFO_OperationEpochsImpl(exd.graph, epochPatterns, selectData, epType, SF_OP_EPOCHS)

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_EPOCHS)
End

static Function/WAVE SFO_OperationEpochsImpl(string graph, WAVE/T epochPatterns, WAVE/Z selectData, variable epType, string opShort)

	variable i, j, numSelected, sweepNo, chanNr, chanType, index, numEpochs, epIndex, settingsIndex, numPatterns, numEntries
	variable hasValidData, colorGroup, mapIndex
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
		mapIndex = selectData[i][%SWEEPMAPINDEX]

		DFREF sweepDFR
		[WAVE numericalValues, WAVE textualValues, sweepDFR] = SFH_GetLabNoteBooksAndDFForSweep(graph, sweepNo, mapIndex)
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
		JWN_SetNumberInWaveNote(output[i], SF_META_SWEEPMAPINDEX, mapIndex)
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
Function/WAVE SFO_OperationFindLevel(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs <= 3, "Findlevel has 3 arguments at most.")
	SFH_ASSERT(numArgs > 1, "Findlevel needs at least two arguments.")
	WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	WAVE      level = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_FINDLEVEL, 1, checkExist = 1)
	SFH_ASSERT(DimSize(level, ROWS) == 1, "Too many input values for parameter level")
	SFH_ASSERT(IsNumericWave(level), "level parameter must be numeric")
	if(numArgs == 3)
		WAVE edge = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_FINDLEVEL, 2, checkExist = 1)
		SFH_ASSERT(DimSize(edge, ROWS) == 1, "Too many input values for parameter edge")
		SFH_ASSERT(IsNumericWave(edge), "edge parameter must be numeric")
		SFH_ASSERT(edge[0] == FINDLEVEL_EDGE_BOTH || edge[0] == FINDLEVEL_EDGE_INCREASING || edge[0] == FINDLEVEL_EDGE_DECREASING, "edge parameter is invalid")
	else
		Make/FREE edge = {FINDLEVEL_EDGE_BOTH}
	endif

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_FINDLEVEL, DimSize(input, ROWS))
	output = FindLevelWrapper(input[p], level[0], edge[0], FINDLEVEL_MODE_SINGLE)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_FINDLEVEL, SF_DATATYPE_FINDLEVEL)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_FINDLEVEL)
End

Function/WAVE SFO_OperationFit(STRUCT SF_ExecutionData &exd)

	variable numElements
	string   functionName

	SFH_CheckArgumentCount(exd, SF_OP_FIT, 3, maxArgs = 3)
	WAVE/WAVE xData = SFH_GetArgumentAsWave(exd, SF_OP_FIT, 0)
	WAVE/WAVE yData = SFH_GetArgumentAsWave(exd, SF_OP_FIT, 1)
	SFH_ASSERT(DimSize(xData, ROWS) == DimSize(YData, ROWS), "Mismatched number of datasets")

	WAVE/WAVE fitOp = SFH_GetArgumentAsWave(exd, SF_OP_FIT, 2)
	SFH_ASSERT(DimSize(fitOp, ROWS) == 3, "Invalid fit operation parameters")

	WAVE/T fitType       = fitOp[%fitType]
	WAVE   holdWave      = fitOp[%holdWave]
	WAVE   initialValues = fitOp[%initialValues]

	numElements = DimSize(yData, ROWS)
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_FIT, numElements)

	output[] = SFO_OperationFitImpl(xData[p], yData[p], fitType[0], holdWave, initialValues)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_FIT)
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

Function/WAVE SFO_OperationFitLine(STRUCT SF_ExecutionData &exd)

	SFH_CheckArgumentCount(exd, SF_OP_FITLINE, 0, maxArgs = 1)

	WAVE/Z/T constraints = SFH_GetArgumentAsWave(exd, SF_OP_FITLINE, 0, defWave = $"", singleResult = 1)

	[WAVE holdWave, WAVE initialValues] = SFO_ParseFitConstraints(constraints, 2)

	Make/FREE/T entry = {"line"}

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_FITLINE, 3)
	SetDimensionLabels(output, "fitType;holdWave;initialValues", ROWS)
	output[0] = entry
	output[1] = holdWave
	output[2] = initialValues

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_FITLINE)
End

Function/WAVE SFO_OperationIntegrate(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(exd, SF_OP_INTEGRATE)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_INTEGRATE, DimSize(input, ROWS))

	output[] = SFO_OperationIntegrateImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_INTEGRATE, SF_DATATYPE_INTEGRATE)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_INTEGRATE, clear = input)
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
Function/WAVE SFO_OperationLabnotebook(STRUCT SF_ExecutionData &exd)

	variable numArgs, mode
	string lbnKey, modeTxt

	SFH_CheckArgumentCount(exd, SF_OP_LABNOTEBOOK, 1, maxArgs = 3)

	Make/FREE/T allowedValuesMode = {"UNKNOWN_MODE", "DATA_ACQUISITION_MODE", "TEST_PULSE_MODE"}
	modeTxt = SFH_GetArgumentAsText(exd, SF_OP_LABNOTEBOOK, 2, allowedValues = allowedValuesMode, defValue = "DATA_ACQUISITION_MODE")
	mode    = ParseLogbookMode(modeTxt)

	WAVE/Z selectData = SFH_GetArgumentSelect(exd, 1)

	WAVE/T lbnKeys = SFH_GetArgumentAsWave(exd, SF_OP_LABNOTEBOOK, 0, expectedMajorType = IGOR_TYPE_TEXT_WAVE, singleResult = 1)

	WAVE/Z/WAVE output = SFO_OperationLabnotebookIterate(exd.graph, lbnKeys, selectData, mode, SF_OP_LABNOTEBOOK)
	if(!WaveExists(output))
		WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_LABNOTEBOOK, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_LABNOTEBOOK)
	endif

	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_LABNOTEBOOK, ""))
	JWN_SetStringInWaveNote(output, SF_META_WINDOW_HOOK, "TraceValueDisplayHook")

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_LABNOTEBOOK)
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
	string lbnKey, refUnit, unitString, msg

	if(!WaveExists(selectData))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_LABNOTEBOOK)
		return output
	endif

	WAVE/Z/T allLBNKeys = SFO_OperationLabnotebookExpandKeys(graph, LBNKeys, selectData, mode)

	if(!WaveExists(allLBNKeys))
		sprintf msg, "labnotebook: Could not find labnotebook keys for wildcard: \"%s\".", TextWaveToList(LBNKeys, ";", trailSep = 0)
		SF_SetOutputState(msg, SF_MSG_WARN)

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
	string entry, msg

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
		switch(mode)
			case UNKNOWN_MODE:
				sprintf msg, "labnotebook: Could not find labnotebook key \"%s\".", lbnKey
				SF_SetOutputState(msg, SF_MSG_WARN)

				return out
			case DATA_ACQUISITION_MODE: // fallthrough
			case TEST_PULSE_MODE:

				[WAVE settings, settingsIndex] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, lbnKey, chanNr, chanType, UNKNOWN_MODE)
				if(!WaveExists(settings))
					sprintf msg, "labnotebook: Could not find labnotebook key \"%s\".", lbnKey
					SF_SetOutputState(msg, SF_MSG_WARN)

					return out
				endif

				sprintf msg, "labnotebook: Could not find labnotebook key \"%s\" with mode \"%s\", but using \"%s\" succeeded.", lbnKey, StringifyLogbookMode(mode), StringifyLogbookMode(UNKNOWN_MODE)
				SF_SetOutputState(msg, SF_MSG_WARN)
				break
			default:
				FATAL_ERROR("Unsupported mode")
		endswitch
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

Function/WAVE SFO_OperationLog(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(exd, SF_OP_LOG)
	elseif(numArgs == 1)
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	else
		WAVE/WAVE input = SFH_CreateSFRefWave(exd.graph, SF_OP_LOG, 0)
	endif

	for(w : input)
		SFO_OperationLogImpl(w)
	endfor

	SFH_TransferFormulaDataWaveNoteAndMeta(input, input, SF_OP_LOG, JWN_GetStringFromWaveNote(input, SF_META_DATATYPE))

	return SFH_GetOutputForExecutor(input, exd.graph, SF_OP_LOG)
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

Function/WAVE SFO_OperationLog10(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(exd, SF_OP_LOG10)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_LOG10, DimSize(input, ROWS))

	output[] = SFO_OperationLog10Impl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_LOG10, JWN_GetStringFromWaveNote(input, SF_META_DATATYPE))

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_LOG10, clear = input)
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

Function/WAVE SFO_OperationMax(STRUCT SF_ExecutionData &exd)

	WAVE/WAVE input  = SFO_GetNumericVarArgs(exd, SF_OP_MAX)
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_MAX, DimSize(input, ROWS))

	output[] = SFO_OperationMaxImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_MAX, SF_DATATYPE_MAX)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_MAX, clear = input)
End

static Function/WAVE SFO_OperationMaxImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "max requires numeric data as input")
	SFH_ASSERT(WaveDims(input) <= 2, "max accepts only upto 2d data")
	SFH_ASSERT(DimSize(input, ROWS) > 0, "max requires at least one data point")
	MatrixOP/FREE out = maxCols(input)^t
	SF_FormulaWaveScaleTransfer(input, out, COLS, ROWS)

	return out
End

// merge(array data1, array data2, ...)
Function/WAVE SFO_OperationMerge(STRUCT SF_ExecutionData &exd)

	variable numElements, numOutputDatasets, wvType
	string errorTag

	SFH_CheckArgumentCount(exd, SF_OP_MERGE, 1, maxArgs = 1)
	WAVE/WAVE inputWithNull = SF_ResolveDatasetFromJSON(exd, 0)

	WAVE/ZZ/WAVE input = ZapNullRefs(inputWithNull)
	WaveClear inputWithNull

	numElements = WaveExists(input) ? DimSize(input, ROWS) : 0

	numOutputDatasets = (numElements > 0)
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_MERGE, numOutputDatasets)

	if(!numOutputDatasets)
		return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_MERGE)
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

	WAVE/Z mergedX = SFO_OperationMergeXValues(input)
	if(WaveExists(mergedX))
		JWN_SetWaveInWaveNote(content, SF_META_XVALUES, mergedX)
	endif
	Make/FREE/T errorBarTags = {SF_META_ERRORBARYPLUS, SF_META_ERRORBARYMINUS, SF_META_ERRORBARXPLUS, SF_META_ERRORBARXMINUS}
	for(string errorTag : errorBarTags)
		WAVE/Z errorbarMerged = SFO_OperationMergeErrorBars(input, errorTag)
		if(WaveExists(errorbarMerged))
			JWN_SetWaveInWaveNote(content, errorTag, errorbarMerged)
		endif
	endfor

	output[0] = content

	SFH_CopyPlotMetaData(input[0], output[0])

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_MERGE)
End

static Function/WAVE SFO_OperationMergeXValues(WAVE/WAVE input)

	variable numElements, i

	numElements = DimSize(input, ROWS)

	SFH_ASSERT(DimSize(input, ROWS) > 0, "input must have at least one dataset")
	WAVE/Z xWave = JWN_GetNumericWaveFromWaveNote(input[0], SF_META_XVALUES)
	if(!WaveExists(xWave))
		return $""
	endif

	SFH_ASSERT(DimSize(xWave, ROWS) == 1, "xValues must be only a one element")
	Make/FREE/D/N=(numElements) mergedX
	mergedX[0] = xWave[0]
	if(numElements > 1)
		for(i = 1; i < numElements; i += 1)
			WAVE/Z xWave = JWN_GetNumericWaveFromWaveNote(input[i], SF_META_XVALUES)
			SFH_ASSERT(WaveExists(xWave), "Can not merge xValues because only some datasets have xValues")
			SFH_ASSERT(DimSize(xWave, ROWS) == 1, "xValues must be only a one element")
			mergedX[i] = xWave[0]
		endfor
	endif

	return mergedX
End

static Function/WAVE SFO_OperationMergeErrorBars(WAVE/WAVE input, string metaTag)

	variable numElements, i

	numElements = DimSize(input, ROWS)

	SFH_ASSERT(DimSize(input, ROWS) > 0, "input must have at least one dataset")

	Make/FREE/D/N=(numElements) mergedError
	FastOp mergedError = (NaN)
	for(i = 0; i < numElements; i += 1)

		WAVE/Z errorbar = JWN_GetNumericWaveFromWaveNote(input[i], metaTag)
		if(WaveExists(errorbar))
			SFH_ASSERT(DimSize(errorbar, ROWS) == 1, "errorBar wave must be only a one element")
			mergedError[i] = errorbar[0]
		endif
	endfor
	if(!HasOneFiniteEntry(mergedError))
		return $""
	endif

	return mergedError
End

Function/WAVE SFO_OperationMin(STRUCT SF_ExecutionData &exd)

	WAVE/WAVE input  = SFO_GetNumericVarArgs(exd, SF_OP_MIN)
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_MIN, DimSize(input, ROWS))

	output[] = SFO_OperationMinImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_MIN, SF_DATATYPE_MIN)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_MIN, clear = input)
End

static Function/WAVE SFO_OperationMinImpl(WAVE/Z input)

	if(!WaveExists(input))
		return $""
	endif

	SFH_ASSERT(IsNumericWave(input), "min requires numeric data as input")
	SFH_ASSERT(WaveDims(input) <= 2, "min accepts only upto 2d data")
	SFH_ASSERT(DimSize(input, ROWS) > 0, "min requires at least one data point")
	MatrixOP/FREE out = minCols(input)^t

	SF_FormulaWaveScaleTransfer(input, out, COLS, ROWS)

	return out
End

Function/WAVE SFO_OperationMinus(STRUCT SF_ExecutionData &exd)

	WAVE output = SFO_IndexOverDataSetsForPrimitiveOperation(exd, SF_OPSHORT_MINUS)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OPSHORT_MINUS)
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

Function/WAVE SFO_OperationMult(STRUCT SF_ExecutionData &exd)

	WAVE output = SFO_IndexOverDataSetsForPrimitiveOperation(exd, SF_OPSHORT_MULT)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OPSHORT_MULT)
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

Function/WAVE SFO_OperationPlus(STRUCT SF_ExecutionData &exd)

	WAVE output = SFO_IndexOverDataSetsForPrimitiveOperation(exd, SF_OPSHORT_PLUS)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OPSHORT_PLUS)
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

Function/WAVE SFO_OperationPowerSpectrum(STRUCT SF_ExecutionData &exd)

	variable i, doAvg, debugVal
	string unit, avg, winFunc
	variable cutoff, ratioFreq

	SFH_CheckArgumentCount(exd, SF_OP_POWERSPECTRUM, 1, maxArgs = 6)

	WAVE/WAVE input = SFH_GetArgumentAsWave(exd, SF_OP_POWERSPECTRUM, 0, copy = 1)
	unit      = SFH_GetArgumentAsText(exd, SF_OP_POWERSPECTRUM, 1, defValue = SF_POWERSPECTRUM_UNIT_DEFAULT, allowedValues = {SF_POWERSPECTRUM_UNIT_DEFAULT, SF_POWERSPECTRUM_UNIT_DB, SF_POWERSPECTRUM_UNIT_NORMALIZED})
	avg       = SFH_GetArgumentAsText(exd, SF_OP_POWERSPECTRUM, 2, defValue = SF_POWERSPECTRUM_AVG_OFF, allowedValues = {SF_POWERSPECTRUM_AVG_ON, SF_POWERSPECTRUM_AVG_OFF})
	ratioFreq = SFH_GetArgumentAsNumeric(exd, SF_OP_POWERSPECTRUM, 3, defValue = 0, checkFunc = IsNullOrPositiveAndFinite)
	cutoff    = SFH_GetArgumentAsNumeric(exd, SF_OP_POWERSPECTRUM, 4, defValue = 1000, checkFunc = IsStrictlyPositiveAndFinite)
	WAVE/T allowedWinFuncs = ListToTextWave(AddListItem(SF_POWERSPECTRUM_WINFUNC_NONE, FFT_WINF), ";")
	winFunc = SFH_GetArgumentAsText(exd, SF_OP_POWERSPECTRUM, 5, defValue = FFT_WINF_DEFAULT, allowedValues = allowedWinFuncs)
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
		WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_POWERSPECTRUM, DimSize(input, ROWS))
	endif

	MultiThread output[] = SFO_OperationPowerSpectrumImpl(input[p], unit, cutoff, winFunc)

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_POWERSPECTRUM, SF_DATATYPE_POWERSPECTRUM)

	if(doAvg)
		WAVE/WAVE outputAvg   = SFO_AverageDataOverSweeps(output)
		WAVE/WAVE outputAvgPS = SFH_CreateSFRefWave(exd.graph, SF_OP_POWERSPECTRUM, DimSize(outputAvg, ROWS))
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

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_POWERSPECTRUM, clear = input)
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
Function/WAVE SFO_OperationRange(STRUCT SF_ExecutionData &exd)

	variable start, stop, step, stopDefault

	SFH_CheckArgumentCount(exd, SF_OP_RANGE, 1, maxArgs = 3)

	start = SFH_GetArgumentAsNumeric(exd, SF_OP_RANGE, 0)
	stop  = SFH_GetArgumentAsNumeric(exd, SF_OP_RANGE, 1, defValue = NaN)
	step  = SFH_GetArgumentAsNumeric(exd, SF_OP_RANGE, 2, defValue = 1)

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

	return SFH_GetOutputForExecutorSingle(range, exd.graph, SF_OP_RANGE, dataType = SF_DATATYPE_RANGE)
End

Function/WAVE SFO_OperationRMS(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs > 0, "rms requires at least one argument")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(exd, SF_OP_RMS)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_RMS, DimSize(input, ROWS))

	output[] = SFO_OperationRMSImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_RMS, SF_DATATYPE_RMS)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_RMS, clear = input)
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

/// `setscale(data, dim, [dimOffset, [dimDelta[, unit]]])`
Function/WAVE SFO_OperationSetScale(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs < 6, "Maximum number of arguments exceeded.")
	SFH_ASSERT(numArgs > 1, "At least two arguments.")
	WAVE/WAVE dataRef   = SF_ResolveDatasetFromJSON(exd, 0)
	WAVE/T    dimension = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_SETSCALE, 1, checkExist = 1)
	SFH_ASSERT(IsTextWave(dimension), "Expected d, x, y, z or t as dimension.")
	SFH_ASSERT(DimSize(dimension, ROWS) == 1 && GrepString(dimension[0], "[d,x,y,z,t]"), "undefined input for dimension")

	if(numArgs >= 3)
		WAVE offset = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_SETSCALE, 2, checkExist = 1)
		SFH_ASSERT(IsNumericWave(offset) && DimSize(offset, ROWS) == 1, "Expected a number as offset.")
	else
		Make/FREE/N=1 offset = {0}
	endif
	if(numArgs >= 4)
		WAVE delta = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_SETSCALE, 3, checkExist = 1)
		SFH_ASSERT(IsNumericWave(delta) && DimSize(delta, ROWS) == 1, "Expected a number as delta.")
	else
		Make/FREE/N=1 delta = {1}
	endif
	if(numArgs == 5)
		WAVE/T unit = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_SETSCALE, 4, checkExist = 1)
		SFH_ASSERT(IsTextWave(unit) && DimSize(unit, ROWS) == 1, "Expected a string as unit.")
	else
		Make/FREE/N=1/T unit = {""}
	endif

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_SETSCALE, DimSize(dataRef, ROWS))

	output[] = SFO_OperationSetScaleImpl(dataRef[p], dimension[0], offset[0], delta[0], unit[0])

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_SETSCALE, clear = dataRef)
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

Function/WAVE SFO_OperationStdev(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs > 0, "stdev requires at least one argument")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(exd, SF_OP_STDEV)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_STDEV, DimSize(input, ROWS))

	output[] = SFO_OperationStdevImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_STDEV, SF_DATATYPE_STDEV)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_STDEV, clear = input)
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
Function/WAVE SFO_OperationStore(STRUCT SF_ExecutionData &exd)

	string rawCode, preProcCode, name
	variable maxEntries, numEntries

	SFH_ASSERT(SFH_GetNumberOfArguments(exd) == 2, "Function accepts only two arguments")

	name = SFH_GetArgumentAsText(exd, SF_OP_STORE, 0)

	WAVE/WAVE dataRef = SF_ResolveDatasetFromJSON(exd, 1)

	[rawCode, preProcCode] = SF_GetCode(exd.graph)

	[WAVE/T keys, WAVE/T values] = SFH_CreateResultsWaveWithCode(exd.graph, rawCode, data = dataRef, name = name, resultType = SFH_RESULT_TYPE_STORE)

	ED_AddEntriesToResults(values, keys, SWEEP_FORMULA_RESULT)

	// return second argument unmodified
	return SFH_GetOutputForExecutor(dataRef, exd.graph, SF_OP_STORE)
End

Function/WAVE SFO_OperationText(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs > 0, "text requires at least one argument.")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(exd, SF_OP_TEXT)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_TEXT, DimSize(input, ROWS))

	output[] = SFO_OperationTextImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_TEXT, JWN_GetStringFromWaveNote(input, SF_META_DATATYPE))

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_TEXT, clear = input)
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

Function/WAVE SFO_OperationVariance(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs > 0, "variance requires at least one argument")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(exd, SF_OP_VARIANCE)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_VARIANCE, DimSize(input, ROWS))

	output[] = SFO_OperationVarianceImpl(input[p])

	SFH_TransferFormulaDataWaveNoteAndMeta(input, output, SF_OP_VARIANCE, SF_DATATYPE_VARIANCE)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_VARIANCE, clear = input)
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

Function/WAVE SFO_OperationWave(STRUCT SF_ExecutionData &exd)

	SFH_CheckArgumentCount(exd, SF_OP_WAVE, 0, maxArgs = 1)

	WAVE/Z output = $SFH_GetArgumentAsText(exd, SF_OP_WAVE, 0, defValue = "")

	return SFH_GetOutputForExecutorSingle(output, exd.graph, SF_OP_WAVE, discardOpStack = 1)
End

Function/WAVE SFO_OperationXValues(STRUCT SF_ExecutionData &exd)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs > 0, "xvalues requires at least one argument.")
	if(numArgs > 1)
		WAVE/WAVE input = SF_GetArgumentTop(exd, SF_OP_XVALUES)
	else
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	endif
	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_XVALUES, DimSize(input, ROWS))

	output[] = SFO_OperationXValuesImpl(input[p])

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_XVALUES, clear = input)
End

static Function/WAVE SFO_OperationXValuesImpl(WAVE/Z input)

	variable offset, delta

	if(!WaveExists(input))
		return $""
	endif

	WAVE/Z xValues = JWN_GetNumericWaveFromWaveNote(input, SF_META_XVALUES)
	if(WaveExists(xValues))
		return xValues
	endif
	WAVE/Z/T xValuesT = JWN_GetTextWaveFromWaveNote(input, SF_META_XVALUES)
	if(WaveExists(xValuesT))
		return xValuesT
	endif

	Make/FREE/D/N=(DimSize(input, ROWS), DimSize(input, COLS), DimSize(input, LAYERS), DimSize(input, CHUNKS)) output
	offset = DimOffset(input, ROWS)
	delta  = DimDelta(input, ROWS)
	Multithread output = offset + p * delta

	return output
End

static Function/WAVE SFO_IndexOverDataSetsForPrimitiveOperation(STRUCT SF_ExecutionData &exd, string opShort)

	variable numArgs, dataSetNum0, dataSetNum1
	string errMsg, type1, type2, resultType

	numArgs = SFH_GetNumberOfArguments(exd)
	ASSERT(numArgs == 2, "Number of arguments must be 2 for " + opShort)

	WAVE/WAVE arg0 = SF_ResolveDatasetFromJSON(exd, 0)
	WAVE/WAVE arg1 = SF_ResolveDatasetFromJSON(exd, 1)
	dataSetNum0 = DimSize(arg0, ROWS)
	dataSetNum1 = DimSize(arg1, ROWS)
	if(dataSetNum0 == 0 && dataSetNum1 == 0)
		WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, 0)
		return output
	endif
	SFH_ASSERT(dataSetNum0 > 0 && dataSetNum1 > 0, "No input data on one side for " + opShort)
	if(dataSetNum0 == dataSetNum1)
		WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, dataSetNum0)
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
		WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, dataSetNum0)
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
		WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, dataSetNum1)
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

static Function/WAVE SFO_GetNumericVarArgs(STRUCT SF_ExecutionData &exd, string opShort)

	variable numArgs

	numArgs = SFH_CheckArgumentCount(exd, opShort, 1)
	if(numArgs == 1)
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(exd, 0)
	else
		WAVE      wv    = SFE_FormulaExecutor(exd)
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

/// table(expression)
Function/WAVE SFO_OperationTable(STRUCT SF_ExecutionData &exd)

	SFH_CheckArgumentCount(exd, SF_OP_TABLE, 1, maxArgs = 1)

	WAVE output = SFH_GetArgumentAsWave(exd, SF_OP_TABLE, 0)

	JWN_SetNumberInWaveNote(output, SF_PROPERTY_TABLE, 1)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_TABLE)
End

#ifdef AUTOMATED_TESTING
Function/WAVE SFO_OperationTestop_PROTO(STRUCT SF_ExecutionData &exd)

	INFO("TestOp PROTO function was called. A proper implementation function for testop must be registered by setting the SVAR from GetSFTestopName")
	FAIL()
End

/// testop(...)
Function/WAVE SFO_OperationTestop(STRUCT SF_ExecutionData &exd)

	string funcName = ROStr(GetSFTestopName(exd.graph))

	REQUIRE_PROPER_STR(funcName)

	FUNCREF SFO_OperationTestop_PROTO func = $funcName
	WAVE                              wv   = func(exd)

	return wv
End
#endif // AUTOMATED_TESTING

/// @brief Sets the plot meta data for the ivscc_apfrequency operation
static Function SFO_OperationIVSCCApFrequencySetPlotProperties(WAVE wvY, variable xAxisPercentage, variable yAxisPercentage)

	JWN_SetNumberInWaveNote(wvY, SF_META_XAXISPERCENT, xAxisPercentage)
	JWN_SetNumberInWaveNote(wvY, SF_META_YAXISPERCENT, yAxisPercentage)
End

// for avgMode: bins
// ivscc_apfrequency([xaxisOffset, yaxisOffset, xAxisPercentage, yAxisPercentage, prepFit, avgMode, binRange, binWidth, method, level, timeFreq, normalize, xAxisType])
//
// for avgMode: bins2
// ivscc_apfrequency([xaxisOffset, yaxisOffset, xAxisPercentage, yAxisPercentage, prepFit, avgMode, method, level, timeFreq, normalize, xAxisType])
Function/WAVE SFO_OperationIVSCCApFrequency(STRUCT SF_ExecutionData &exd)

	string   opShort    = SF_OP_IVSCCAPFREQUENCY
	variable numArgsMin = 0
	variable numArgsMax = 13
	string formula, expr
	variable i, numArgs, col, size, numExp
	variable xAxisPercentage, yAxisPercentage
	string xaxisOffset, yaxisOffset
	variable method, level, binWidth, numBins
	string timeFreq, normalize, xAxisType, freqList, currentList, expList, binList, avgMode
	STRUCT RGBColor s

	SFH_ASSERT(BSP_IsSweepBrowser(exd.graph), "ivscc_apfrequency only works with sweepbrowser")

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs <= numArgsMax, "ivscc_apfrequency has " + num2istr(numArgsMax) + " arguments at most.")
	SFH_ASSERT(numArgs >= numArgsMin, "ivscc_apfrequency needs at least " + num2istr(numArgsMin) + " argument(s).")

	xaxisOffset     = SFH_GetArgumentAsText(exd, opShort, 0, defValue = SF_OP_IVSCCAPFREQUENCY_MIN, allowedValues = {SF_OP_IVSCCAPFREQUENCY_FIRST, SF_OP_IVSCCAPFREQUENCY_MIN, SF_OP_IVSCCAPFREQUENCY_MAX, SF_OP_IVSCCAPFREQUENCY_NONE})
	yaxisOffset     = SFH_GetArgumentAsText(exd, opShort, 1, defValue = SF_OP_IVSCCAPFREQUENCY_MIN, allowedValues = {SF_OP_IVSCCAPFREQUENCY_FIRST, SF_OP_IVSCCAPFREQUENCY_MIN, SF_OP_IVSCCAPFREQUENCY_MAX, SF_OP_IVSCCAPFREQUENCY_NONE})
	xAxisPercentage = SFH_GetArgumentAsNumeric(exd, opShort, 2, defValue = 100, checkFunc = BetweenZeroAndOneHoundred)
	yAxisPercentage = SFH_GetArgumentAsNumeric(exd, opShort, 3, defValue = 100, checkFunc = BetweenZeroAndOneHoundred)
	WAVE/WAVE prepFit = SFH_GetArgumentAsWave(exd, opShort, 4, defOp = "preparefit()")

	avgMode         = SFH_GetArgumentAsText(exd, opShort, 5, defValue = SF_OP_AVG_BINS, allowedValues = {SF_OP_AVG_BINS, SF_OP_AVG_BINS2})

	if(!CmpStr(avgMode, SF_OP_AVG_BINS))
		WAVE/WAVE wTmp     = SFH_GetArgumentAsWave(exd, opShort, 6)
		WAVE      binRange = wTmp[0]
		binWidth                                        = SFH_GetArgumentAsNumeric(exd, opShort, 7, checkFunc = IsStrictlyPositiveAndFinite)
		[method, level, timeFreq, normalize, xAxisType] = SFO_GetApFrequencyArguments(exd, opShort, 8)
	else
		// SF_OP_AVG_BINS2
		[method, level, timeFreq, normalize, xAxisType] = SFO_GetApFrequencyArguments(exd, opShort, 6)
	endif

	// create and evaluate variables
	WAVE/T sweepMap = SB_GetSweepMap(exd.graph)
	col  = FindDimlabel(sweepMap, COLS, "FileName")
	size = GetNumberFromWaveNote(sweepMap, NOTE_INDEX)
	SFH_ASSERT(size > 0, "No sweep data loaded")
	Duplicate/FREE/RMD=[0, size - 1][col] sweepMap, fileNames
	WAVE/T uniqueFiles = GetUniqueEntries(fileNames, dontDuplicate = 1)
	Sort uniqueFiles, uniqueFiles
	numExp = DimSize(uniqueFiles, ROWS)
	SFH_ASSERT(numExp > 0, "ivscc_apfrequency: data from at least one experiment has to be loaded")

	formula = "sel = select(selsweeps(), selstimset(\"*LP_Rheo*\", \"*supra*\"), selvis(all), selivsccsweepqc(passed))\r"
	for(i = 0; i < numExp; i += 1)
		sprintf expr, "selexpAD%d = select(selexp(\"%s\"), $sel, selchannels(AD0), selrange(E1))", i, uniqueFiles[i]
		formula = SF_AddExpressionToFormula(formula, expr)
		sprintf expr, "selexpDA%d = select(selexp(\"%s\"), $sel, selchannels(DA0), selrange(E1))", i, uniqueFiles[i]
		formula = SF_AddExpressionToFormula(formula, expr)
		sprintf expr, "freq%d = apfrequency(data($selexpAD%d), %d, %f, %s, %s, %s)", i, i, method, level, timeFreq, normalize, xAxisType
		formula = SF_AddExpressionToFormula(formula, expr)
		sprintf expr, "current%d = max(data($selexpDA%d))", i, i
		formula = SF_AddExpressionToFormula(formula, expr)
		if(!CmpStr(xaxisOffset, SF_OP_IVSCCAPFREQUENCY_FIRST))
			sprintf expr, "currentNorm%d = $current%d - extract($current%d, 0)", i, i, i
		elseif(!CmpStr(xaxisOffset, SF_OP_IVSCCAPFREQUENCY_MIN))
			sprintf expr, "currentNorm%d = $current%d - min(merge($current%d))", i, i, i
		elseif(!CmpStr(xaxisOffset, SF_OP_IVSCCAPFREQUENCY_MAX))
			sprintf expr, "currentNorm%d = $current%d - max(merge($current%d))", i, i, i
		else // SF_OP_IVSCCAPFREQUENCY_NONE
			sprintf expr, "currentNorm%d = $current%d", i, i
		endif
		formula = SF_AddExpressionToFormula(formula, expr)
	endfor

	Make/FREE/T/N=(numExp) freqs, currents, exps
	freqs[]     = "$freq" + num2istr(p)
	freqList    = TextWaveToList(freqs, ",", trailSep = 0)
	currents[]  = "$currentNorm" + num2istr(p)
	currentList = TextWaveToList(currents, ",", trailSep = 0)
	exps[]      = "\"" + uniqueFiles[p] + "\""
	expList     = TextWaveToList(exps, ",", trailSep = 0)

	sprintf expr, "ivscc_apfrequency_explist = [%s]", expList
	formula = SF_AddExpressionToFormula(formula, expr)

	if(!CmpStr(avgMode, SF_OP_AVG_BINS))
		sprintf expr, "ivsccavg = avg([%s], bins, [%f,%f],%f,[%s])", freqList, binRange[0], binRange[1], binWidth, currentList
		formula = SF_AddExpressionToFormula(formula, expr)
		sprintf expr, "ivscccurrentavg = avg([%s], bins, [%f,%f],%f,[%s])", currentList, binRange[0], binRange[1], binWidth, currentList
		formula = SF_AddExpressionToFormula(formula, expr)

		if(!CmpStr(xaxisOffset, SF_OP_IVSCCAPFREQUENCY_FIRST))
			expr = "ivsccavg_norm_x = merge($ivscccurrentavg - extract($ivscccurrentavg, 0))"
		elseif(!CmpStr(xaxisOffset, SF_OP_IVSCCAPFREQUENCY_MIN))
			expr = "ivsccavg_norm_x = merge($ivscccurrentavg - min(merge($ivscccurrentavg)))"
		elseif(!CmpStr(xaxisOffset, SF_OP_IVSCCAPFREQUENCY_MAX))
			expr = "ivsccavg_norm_x = merge($ivscccurrentavg - max(merge($ivscccurrentavg)))"
		else // SF_OP_IVSCCAPFREQUENCY_NONE
			expr = "ivsccavg_norm_x = merge($ivscccurrentavg)"
		endif
		formula = SF_AddExpressionToFormula(formula, expr)
	else
		// SF_OP_AVG_BINS2
		sprintf expr, "ivsccavg = avg([%s], bins2, [%s])", freqList, currentList
		formula = SF_AddExpressionToFormula(formula, expr)
		expr = "ivsccavg_xvalues = xvalues(merge($ivsccavg))"
		formula = SF_AddExpressionToFormula(formula, expr)

		if(!CmpStr(xaxisOffset, SF_OP_IVSCCAPFREQUENCY_FIRST))
			//	expr = "ivsccavg_norm_x = merge($ivscccurrentavg - extract($ivscccurrentavg, 0, 0))"
		elseif(!CmpStr(xaxisOffset, SF_OP_IVSCCAPFREQUENCY_MIN))
			expr = "ivsccavg_norm_x = $ivsccavg_xvalues - min($ivsccavg_xvalues)"
		elseif(!CmpStr(xaxisOffset, SF_OP_IVSCCAPFREQUENCY_MAX))
			expr = "ivsccavg_norm_x = $ivsccavg_xvalues - max($ivsccavg_xvalues)"
		else // SF_OP_IVSCCAPFREQUENCY_NONE
			expr = "ivsccavg_norm_x = $ivsccavg_xvalues"
		endif
		formula = SF_AddExpressionToFormula(formula, expr)
	endif
	if(!CmpStr(yaxisOffset, SF_OP_IVSCCAPFREQUENCY_FIRST))
		expr = "ivsccavg_norm_y = merge($ivsccavg - extract($ivsccavg, 0))"
	elseif(!CmpStr(yaxisOffset, SF_OP_IVSCCAPFREQUENCY_MIN))
		expr = "ivsccavg_norm_y = merge($ivsccavg - min(merge($ivsccavg)))"
	elseif(!CmpStr(yaxisOffset, SF_OP_IVSCCAPFREQUENCY_MAX))
		expr = "ivsccavg_norm_y = merge($ivsccavg - max(merge($ivsccavg)))"
	else // SF_OP_IVSCCAPFREQUENCY_NONE
		expr = "ivsccavg_norm_y = merge($ivsccavg)"
	endif
	formula = SF_AddExpressionToFormula(formula, expr)

	WAVE/WAVE varStorage = GetSFVarStorage(exd.graph)
	Duplicate/FREE varStorage, varBackup
	SFE_ExecuteVariableAssignments(exd.graph, formula, allowEmptyCode=1)

	SFH_AddVariableToStorage(exd.graph, "pfit", SFH_GetOutputForExecutor(prepFit, exd.graph, opShort))
	WAVE/WAVE fitResult = SFH_AddVariableToStorageByFormula(exd.graph, "ivscc_apfrequency_fit", "fit2($ivsccavg_norm_y, $ivsccavg_norm_x, $pfit)", opShort)

	// build plot tree
	WAVE/WAVE varStorageOp = GetSFVarStorage(exd.graph)
	WAVE      wvResult     = varStorageOp[%ivscc_apfrequency_explist]

	WAVE/WAVE plotAND = SFH_CreateSFRefWave(exd.graph, opShort, 1)
	Make/FREE/WAVE/N=(numExp + 2, 2) plotWITH
	SetDimlabel COLS, 0, FORMULAX, plotWITH
	SetDimlabel COLS, 1, FORMULAY, plotWITH
	plotAND[0] = plotWITH

	// apfrequency traces
	for(i = 0; i < numExp; i += 1)
		if(!CmpStr(yaxisOffset, SF_OP_IVSCCAPFREQUENCY_FIRST))
			sprintf formula, "merge($freq%d - extract($freq%d, 0))", i, i
		elseif(!CmpStr(yaxisOffset, SF_OP_IVSCCAPFREQUENCY_MIN))
			sprintf formula, "merge($freq%d - min(merge($freq%d)))", i, i
		elseif(!CmpStr(yaxisOffset, SF_OP_IVSCCAPFREQUENCY_MAX))
			sprintf formula, "merge($freq%d - max(merge($freq%d)))", i, i
		else // SF_OP_IVSCCAPFREQUENCY_NONE
			sprintf formula, "merge($freq%d)", i
		endif
		WAVE/WAVE wvY = SFE_ExecuteFormula(formula, exd.graph, preProcess = 0)
		if(DimSize(wvY, ROWS) > 0)
			[s] = GetTraceColorNonHeadstage(i)
			Make/FREE/W/U traceColor = {s.red, s.green, s.blue, SF_IVSCC_APFREQUENCY_OPACITY}
			JWN_SetWaveInWaveNote(wvY[0], SF_META_TRACECOLOR, traceColor)
			JWN_SetNumberInWaveNote(wvY[0], SF_META_MOD_MARKER, 19)
			JWN_SetStringInWaveNote(wvY[0], SF_META_LEGEND_LINE_PREFIX, uniqueFiles[i])
		endif
		plotWITH[i][%FORMULAY] = wvY
		SFO_OperationIVSCCApFrequencySetPlotProperties(plotWITH[i][%FORMULAY], xAxisPercentage, yAxisPercentage)
		sprintf formula, "merge($currentNorm%d)", i
		plotWITH[i][%FORMULAX] = SFE_ExecuteFormula(formula, exd.graph, preProcess = 0)
	endfor

	// avg trace
	formula = "$ivsccavg_norm_y"
	WAVE/WAVE wvY = SFE_ExecuteFormula(formula, exd.graph, preProcess = 0)
	if(DimSize(wvY, ROWS) > 0)
		JWN_SetStringInWaveNote(wvY[0], SF_META_LEGEND_LINE_PREFIX, "ivscc_apfrequency avg " + avgMode)
	endif
	JWN_SetStringInWaveNote(wvY, SF_META_XAXISLABEL, "x value") // activates x values
	plotWITH[numExp][%FORMULAY] = wvY
	SFO_OperationIVSCCApFrequencySetPlotProperties(plotWITH[numExp][%FORMULAY], xAxisPercentage, yAxisPercentage)

	formula = "$ivsccavg_norm_x"
	plotWITH[numExp][%FORMULAX] = SFE_ExecuteFormula(formula, exd.graph, preProcess = 0)

	numExp += 1
	// fit trace
	formula = "$ivscc_apfrequency_fit"
	WAVE/WAVE wvY = SFE_ExecuteFormula(formula, exd.graph, preProcess = 0)
	if(DimSize(wvY, ROWS) > 0)
		JWN_SetStringInWaveNote(wvY[0], SF_META_LEGEND_LINE_PREFIX, "ivscc_apfrequency fit")
	endif
	plotWITH[numExp][%FORMULAY] = wvY

	Duplicate/O varBackup, varStorage
	SFH_AddVariableToStorage(exd.graph, "ivscc_apfrequency_explist", wvResult)
	SFH_AddVariableToStorage(exd.graph, "ivscc_apfrequency_fit", SFH_GetOutputForExecutor(fitResult, exd.graph, opShort))

	JWN_SetNumberInWaveNote(plotAND, SF_META_PLOT, 1)

	return SFH_GetOutputForExecutor(plotAND, exd.graph, opShort)
End

Function SFO_OperationPrepareFit_PROTO(WAVE w, variable x)
	FATAL_ERROR("Prototype function called")
End

/// preparefit([fitFuncName, coefs, holdStr, range, constraints])
Function/WAVE SFO_OperationPrepareFit(STRUCT SF_ExecutionData &exd)

	string opShort = SF_OP_PREPAREFIT
	variable numArgs, numCoefs
	string fitfuncName, holdStr, checkStr

	SFH_CheckArgumentCount(exd, opShort, 0, maxArgs = 4)

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, 1)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_PREPAREFIT)

	WAVE/WAVE prepFit = GetSFPrepareFitWave()
	output[0] = prepFit

	WAVE/T fitArgs = prepFit[%FITARGS]

	numArgs = SFH_GetNumberOfArguments(exd)
	if(numArgs == 0)
		fitArgs[%FITFUNCNAME] = SF_PREPAREFIT_NOFUNC
		return SFH_GetOutputForExecutor(output, exd.graph, opShort)
	endif

	fitfuncName = SFH_GetArgumentAsText(exd, opShort, 0)
	if(IsIntegratedFitFunction(fitFuncName))
		WAVE/Z/WAVE coefsArray = SFH_GetArgumentAsWave(exd, opShort, 1, defWave=$"")
		if(WaveExists(coefsArray))
			SFH_ASSERT(SFH_IsArray(coefsArray), "Expected array at coefs arg position")
			WAVE coefs = coefsArray[0]
		else
			WAVE/Z coefs = $""
			numCoefs = GetIntegratedFitFunctionCoefficientNumber(fitFuncName)
		endif
	else
		FUNCREF SFO_OperationPrepareFit_PROTO func = $fitfuncName
		SFH_ASSERT(FuncRefIsAssigned(FuncRefInfo(func)), "The specified user fit function does not exist: " + fitfuncName)
		WAVE/WAVE coefsArray = SFH_GetArgumentAsWave(exd, opShort, 1)
		SFH_ASSERT(SFH_IsArray(coefsArray), "Expected array at coefs arg position")
		WAVE coefs = coefsArray[0]
	endif
	fitArgs[%FITFUNCNAME] = fitfuncName

	if(WaveExists(coefs))
		SFH_ASSERT(IsNumericWave(coefs), "Expected numeric wave for coefs argument")
		numCoefs = DimSize(coefs, ROWS)
	endif
	prepFit[%COEFS] = coefs

	holdStr = PadString("", numCoefs, char2num("O"))
	holdStr = SFH_GetArgumentAsText(exd, opShort, 2, defValue = holdStr, checkFunc = IsSFPrepareFitHoldString)
	SFH_ASSERT(strlen(holdStr) == numCoefs, "Number of coefficients does not match number of characters in hold string.")
	holdStr           = ReplaceString(SF_PREPAREFIT_HOLDCHAR_HOLD, holdStr, "1")
	holdStr           = ReplaceString(SF_PREPAREFIT_HOLDCHAR_FREE, holdStr, "0")
	fitArgs[%HOLDSTR] = holdStr

	WAVE/Z/WAVE rangeArray = SFH_GetArgumentAsWave(exd, opShort, 3, defWave = $"")
	if(WaveExists(rangeArray))
		SFH_ASSERT(SFH_IsArray(rangeArray), "Expected array at range arg position")
		WAVE range = rangeArray[0]
		SFH_ASSERT(IsNumericWave(range), "Expected numeric wave for range argument")
		SFH_ASSERT(DimSize(range, ROWS) == 2, "Expected range wave to have two entries")
		SFH_ASSERT(range[0] >= 0, "First range element must be >= 0")
		SFH_ASSERT(range[1] <= 0, "Second range element must be <= 0")
		prepFit[%RANGE] = range
	endif

	WAVE/Z/WAVE constraintsArray = SFH_GetArgumentAsWave(exd, opShort, 4, defWave = $"")
	if(WaveExists(constraintsArray))
		SFH_ASSERT(SFH_IsArray(constraintsArray), "Expected array at constraints arg position")
		WAVE/T constraints = constraintsArray[0]
		SFH_ASSERT(IsTextWave(constraints), "Expected text wave for constraints argument")
		prepFit[%CONSTRAINTS] = constraints
	endif

	return SFH_GetOutputForExecutor(output, exd.graph, opShort)
End

/// fit2(wvY, wvX, preparefit(...))
Function/WAVE SFO_OperationFit2(STRUCT SF_ExecutionData &exd)

	string opShort = SF_OP_FIT2
	string   dataType
	variable numDatasets

	SFH_CheckArgumentCount(exd, opShort, 2, maxArgs = 3)
	WAVE/WAVE datasetsWvY = SFH_GetArgumentAsWave(exd, opShort, 0)
	WAVE/WAVE datasetsWvX = SFH_GetArgumentAsWave(exd, opShort, 1)
	numDatasets = DimSize(datasetsWvY, ROWS)
	dataType    = JWN_GetStringFromWaveNote(datasetsWvX, SF_META_DATATYPE)
	if(!CmpStr(dataType, SF_DATATYPE_PREPAREFIT))
		WAVE/WAVE prepFit = datasetsWvX[0]
		Make/WAVE/FREE/N=(numDatasets) datasetsWvX
	else
		SFH_ASSERT(numDatasets == DimSize(datasetsWvX, ROWS), "number of datasets for wvY must equal number of datasets for wvX")
		WAVE/WAVE prepFitRef = SFH_GetArgumentAsWave(exd, opShort, 2)
		dataType = JWN_GetStringFromWaveNote(prepFitRef, SF_META_DATATYPE)
		SFH_ASSERT(!CmpStr(dataType, SF_DATATYPE_PREPAREFIT), "Expected argument of type preparefit")
		WAVE/WAVE prepFit = prepFitRef[0]
	endif

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, numDatasets)

	output[] = SFO_OperationFit2Impl(datasetsWvY[p], datasetsWvX[p], prepFit)

	JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, "x value") // activates x values

	return SFH_GetOutputForExecutor(output, exd.graph, opShort)
End

static Function/S SFO_OperationFit2GetFitStatusMessage(variable fitError, variable fitQuitReason, variable fitNumIters)

	string msg = ""

	if(FitError == 0)
		msg += "Fit Ok.\r"
	endif
	if((FitError & FIT_ERROR_ANY) == FIT_ERROR_ANY)
		msg += "Fit Error.\r"
	endif
	if((FitError & FIT_ERROR_SINGULARMATRIX) == FIT_ERROR_SINGULARMATRIX)
		msg += "Singular Matrix.\r"
	endif
	if((FitError & FIT_ERROR_OUTOFMEMORY) == FIT_ERROR_OUTOFMEMORY)
		msg += "Out of memory.\r"
	endif
	if((FitError & FIT_ERROR_RETURNEDNANORINF) == FIT_ERROR_RETURNEDNANORINF)
		msg += "Fit function returned NaN or Inf.\r"
	endif
	if((FitError & FIT_ERROR_FUNCREQUESTEDSTOP) == FIT_ERROR_FUNCREQUESTEDSTOP)
		msg += "Function requested stop.\r"
	endif
	if((FitError & FIT_ERROR_REENTRANT_FIT) == FIT_ERROR_REENTRANT_FIT)
		msg += "Reentrant fit function call encountered.\r"
	endif
	if((FitQuitReason & FIT_QUITREASON_ITERATIONLIMITREACHED) == FIT_QUITREASON_ITERATIONLIMITREACHED)
		msg += "Iteration limit reached.\r"
	endif
	if((FitQuitReason & FIT_QUITREASON_STOPPEDBYUSER) == FIT_QUITREASON_STOPPEDBYUSER)
		msg += "User stopped fit.\r"
	endif
	if((FitQuitReason & FIT_QUITREASON_NOCHISQUAREDECREASE) == FIT_QUITREASON_NOCHISQUAREDECREASE)
		msg += "chiSquare did not decrease in last 9 iterations.\r"
	endif
	msg += "Iterations run: " + num2istr(fitNumIters)

	return msg
End

static Function/WAVE SFO_OperationFit2CalculateWeights(WAVE/Z wMinus, WAVE/Z wPlus)

	if(!WaveExists(wMinus) && !WaveExists(wPlus))
		return $""
	endif

	if(!WaveExists(wPlus))
		Make/FREE/D/N=(DimSize(wMinus, ROWS)) weight
		MultiThread weight[] = abs(wMinus[p])
	elseif(!WaveExists(wMinus))
		Make/FREE/D/N=(DimSize(wPlus, ROWS)) weight
		MultiThread weight[] = abs(wPlus[p])
	else
		Make/FREE/D/N=(DimSize(wMinus, ROWS)) weight
		MultiThread weight[] = (abs(wPlus[p]) + abs(wMinus[p])) / 2
	endif

	return weight
End

static Function/WAVE SFO_OperationFit2Impl(WAVE wvY, WAVE/Z wvX, WAVE/WAVE prepFit)

	string fitFuncName, holdStr, fitStatus
	variable V_FitError, V_FitQuitReason, V_FitNumIters, V_ChiSq, V_FitMaxIters
	variable numPoints, xErrorsOut, haveConstraints

	V_FitMaxIters = SF_FIT2_MAX_ITERATIONS

	numPoints = DimSize(wvY, ROWS)

	if(WaveExists(wvX))
		WAVE/D xWave = wvX
	else
		WAVE/Z/D xWave = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_XVALUES)
		if(WaveExists(xWave))
			SFH_ASSERT(IsNumericWave(xWave), "Require wvX to be numeric")
		else
			Make/FREE/D/N=(numPoints) xWave
			Multithread xWave[] = IndexToScale(wvY, p, ROWS)
		endif
	endif
	SFH_ASSERT(numPoints == DimSize(xWave, ROWS), "Number of points in xWave must equal number of points in y-wave")

	WAVE/T fitArgs = prepFit[%FITARGS]
	fitFuncName = fitArgs[%FITFUNCNAME]
	if(!CmpStr(fitFuncName, SF_PREPAREFIT_NOFUNC))
		return $""
	endif

	holdStr = fitArgs[%HOLDSTR]
	WAVE/Z   coefs       = prepFit[%COEFS]
	WAVE/Z/T constraints = prepFit[%CONSTRAINTS]
	haveConstraints = WaveExists(constraints)
	if(!haveConstraints)
		// use always a constraints wave to reduce flag combinations for CurveFit
		Make/FREE/T/N=0 constraints
	endif

	WAVE/Z/D errorbarYPlus = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_ERRORBARYPLUS)
	if(WaveExists(errorbarYPlus))
		SFH_ASSERT(numPoints == DimSize(errorbarYPlus, ROWS), "number of points in errorbar must equal the number of points from y-wave")
	endif
	WAVE/Z/D errorbarYMinus = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_ERRORBARYMINUS)
	if(WaveExists(errorbarYMinus))
		SFH_ASSERT(numPoints == DimSize(errorbarYMinus, ROWS), "number of points in errorbar must equal the number of points from y-wave")
	endif
	WAVE/Z/D errorbarXPlus = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_ERRORBARXPLUS)
	if(WaveExists(errorbarXPlus))
		SFH_ASSERT(numPoints == DimSize(errorbarXPlus, ROWS), "number of points in errorbar must equal the number of points from y-wave")
	endif
	WAVE/Z/D errorbarXMinus = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_ERRORBARXMINUS)
	if(WaveExists(errorbarXMinus))
		SFH_ASSERT(numPoints == DimSize(errorbarXMinus, ROWS), "number of points in errorbar must equal the number of points from y-wave")
	endif

	WAVE/Z/D weightY = SFO_OperationFit2CalculateWeights(errorbarYMinus, errorbarYPlus)
	WAVE/Z/D weightX = SFO_OperationFit2CalculateWeights(errorbarXMinus, errorbarXPlus)
	xErrorsOut = WaveExists(weightX)

	if(!WaveExists(weightY))
		// use always a weight wave for Y to reduce flag combinations for CurveFit
		Make/FREE/D/N=(numPoints) weightY
		FastOp weightY = 1
	endif

	Make/FREE/D/N=(numPoints) fitOutput, yResiduals, xResiduals, xOutput, mask

	FastOp mask = 1
	WAVE/Z range = prepFit[%RANGE]
	if(WaveExists(range))
		if(range[0] > 0)
			mask[0, limit(range[0] - 1, 0, numPoints - 1)] = 0
		endif
		if(range[1] < 0)
			mask[limit(numPoints + range[1], 0, numPoints - 1), Inf] = 0
		endif
	endif

	DFREF dfrSave = GetDataFolderDFR()
	DFREF dfr     = NewFreeDataFolder()
	SetDataFolder dfr

	if(!IsIntegratedFitFunction(fitFuncName))
		// FuncFit
		ASSERT(WaveExists(coefs), "For user fit function coefs must exist")
		if(xErrorsOut)
			// ODR fit
			FuncFit/C/Q/M=2/H=holdStr $fitFuncName, coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
		else
			FuncFit/C/Q/M=2/H=holdStr $fitFuncName, coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
		endif
	else
		// CurveFit
		strswitch(fitFuncName)
			case "gauss":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 gauss, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr gauss, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 gauss, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr gauss, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "lor":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 lor, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr lor, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 lor, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr lor, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "Voigt":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 Voigt, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr Voigt, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 Voigt, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr Voigt, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "exp":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 exp, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr exp, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 exp, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr exp, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "dblexp":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 dblexp, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr dblexp, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 dblexp, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr dblexp, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "exp_XOffset":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 exp_XOffset, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr exp_XOffset, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 exp_XOffset, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr exp_XOffset, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "dblexp_XOffset":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 dblexp_XOffset, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr dblexp_XOffset, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 dblexp_XOffset, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr dblexp_XOffset, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "dblexp_peak":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 dblexp_peak, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr dblexp_peak, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 dblexp_peak, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr dblexp_peak, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "sin":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 sin, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr sin, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 sin, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr sin, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "line":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 line, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr line, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 line, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr line, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly 1":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly 1, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly 1, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly 1, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly 1, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly 2":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly 2, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly 2, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly 2, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly 2, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly 3":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly 3, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly 3, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly 3, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly 3, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly 4":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly 4, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly 4, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly 4, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly 4, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly_XOffset 1":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly_XOffset 1, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly_XOffset 1, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly_XOffset 1, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly_XOffset 1, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly_XOffset 2":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly_XOffset 2, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly_XOffset 2, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly_XOffset 2, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly_XOffset 2, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly_XOffset 3":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly_XOffset 3, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly_XOffset 3, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly_XOffset 3, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly_XOffset 3, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly_XOffset 4":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly_XOffset 4, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly_XOffset 4, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly_XOffset 4, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly_XOffset 4, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "hillequation":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 hillequation, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr hillequation, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 hillequation, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr hillequation, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "sigmoid":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 sigmoid, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr sigmoid, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 sigmoid, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr sigmoid, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "power":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 power, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr power, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 power, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr power, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "lognormal":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 lognormal, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr lognormal, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 lognormal, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr lognormal, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "log":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 log, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr log, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 log, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr log, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "gauss2D":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 gauss2D, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr gauss2D, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 gauss2D, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr gauss2D, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly2D 1":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly2D 1, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly2D 1, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly2D 1, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly2D 1, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly2D 2":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly2D 2, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly2D 2, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly2D 2, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly2D 2, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly2D 3":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly2D 3, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly2D 3, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly2D 3, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly2D 3, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			case "poly2D 4":
				if(WaveExists(coefs))
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly2D 4, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly2D 4, kwCWave=coefs, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				else
					if(xErrorsOut)
						CurveFit/C/Q/M=2/H=holdStr/ODR=2 poly2D 4, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/XW=weightX/XD=xOutput/XR=xResiduals/I=1/M=mask
					else
						CurveFit/C/Q/M=2/H=holdStr poly2D 4, wvY/X=xWave/D=fitOutput/C=constraints/W=weightY/A=0/R=yResiduals/I=1/M=mask
					endif
				endif
				break
			default:
				SFH_FATAL_ERROR("Unsupported integrated fit function")
		endswitch
	endif
	if(!WaveExists(coefs))
		WAVE coefs = W_coef
	endif
	if(haveConstraints)
		WAVE/Z mFitConstraints = M_FitConstraint
		WAVE/Z wFitConstraints = W_FitConstraint
	endif

	WAVE/Z wSigma = W_Sigma
	WAVE/Z mCovar = M_Covar

	SetDataFolder dfrSave

	fitStatus = SFO_OperationFit2GetFitStatusMessage(V_FitError, V_FitQuitReason, V_FitNumIters)

	JWN_CreatePath(fitOutput, SF_SERIALIZE)
	if(V_FitError)
		Make/FREE/D/N=0 fitOutput
		JWN_SetNumberInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITERROR, V_FitError)
		JWN_SetNumberInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITQUITREASON, V_FitQuitReason)
		JWN_SetNumberInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITNUMITERS, V_FitNumIters)
	endif

	JWN_SetStringInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITSTATUSMESSAGE, fitStatus)
	JWN_SetStringInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITFUNC, fitFuncName)

	if(V_FitError)
		return fitOutput
	endif

	JWN_SetWaveInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITCOEFS, coefs)
	JWN_SetWaveInWaveNote(fitOutput, SF_META_ERRORBARYPLUS, yResiduals)
	JWN_SetWaveInWaveNote(fitOutput, SF_META_ERRORBARYMINUS, yResiduals)
	if(xErrorsOut)
		JWN_SetWaveInWaveNote(fitOutput, SF_META_ERRORBARXPLUS, xResiduals)
		JWN_SetWaveInWaveNote(fitOutput, SF_META_ERRORBARXMINUS, xResiduals)
		JWN_SetWaveInWaveNote(fitOutput, SF_META_XVALUES, xOutput)
	else
		JWN_SetWaveInWaveNote(fitOutput, SF_META_XVALUES, xWave)
	endif

	// Possible more fit data: V_npnts, V_nterms, V_nheld
	JWN_SetNumberInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITCHISQUARE, V_ChiSq)
	if(WaveExists(wSigma))
		JWN_SetWaveInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITWSIGMA, wSigma)
	endif
	if(WaveExists(mCovar))
		JWN_SetWaveInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITMCOVAR, mCovar)
	endif
	if(WaveExists(mFitConstraints))
		JWN_SetWaveInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITMFITCONSTRAINT, mFitConstraints)
	endif
	if(WaveExists(wFitConstraints))
		JWN_SetWaveInWaveNote(fitOutput, SF_SERIALIZE + SF_META_FITWFITCONSTRAINT, wFitConstraints)
	endif

	SFH_SetTraceStyleForFit(fitOutput)

	return fitOutput
End

/// getmeta(data, [keyStr, datasetNumber]
Function/WAVE SFO_OperationGetMeta(STRUCT SF_ExecutionData &exd)

	string opShort = SF_OP_GETMETA
	string key, str, path, serStr
	variable dsNum, numDatasets, val

	SFH_CheckArgumentCount(exd, opShort, 0, maxArgs = 3)
	WAVE/WAVE datasets = SFH_GetArgumentAsWave(exd, opShort, 0)
	key = SFH_GetArgumentAsText(exd, opShort, 1, defValue="")
	dsNum = SFH_GetArgumentAsNumeric(exd, opShort, 2, defValue=0)

	numDatasets = DimSize(datasets, ROWS)
	SFH_ASSERT(dsNum < numDatasets, "Dataset with given number does not exist in input data")
	WAVE/Z data = datasets[dsNum]

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, 1)
	if(!WaveExists(data))
		return SFH_GetOutputForExecutor(output, exd.graph, opShort)
	endif

	if(IsEmpty(key))
		WAVE/Z/T keys = JWN_GetKeysAt(data, SF_SERIALIZE)
		serStr = ""
		for(string key : keys)
			path = SF_SERIALIZE + "/" + key
			val = JWN_GetNumberFromWaveNote(data, path)
			if(!IsNaN(val))
				serStr += key + ": " + num2str(val, "%f") + "\r"
				continue
			endif
			str = JWN_GetStringFromWaveNote(data, path)
			if(!IsEmpty(str))
				serStr += key + ":\r" + str + "\r"
				continue
			endif
			WAVE/Z wvn = JWN_GetNumericWaveFromWaveNote(data, path)
			if(WaveExists(wvn))
				str = NumericWaveToList(wvn, "\r")
				serStr += key + ":\r" + str
				continue
			endif
			WAVE/Z/T wt = JWN_GetTextWaveFromWaveNote(data, path)
			if(WaveExists(wt))
				str = TextWaveToList(wt, "\r")
				serStr += key + ":\r" + str
				continue
			endif
		endfor
		serStr = RemoveEnding(serStr, "\r")
		Make/FREE/T wvt = {serStr}
		output[0] = wvt
	else
		path = SF_SERIALIZE + "/" + key
		val = JWN_GetNumberFromWaveNote(data, path)
		if(!IsNaN(val))
			Make/FREE/D wv = {val}
			SetDimLabel ROWS, 0, $key, wv
			output[0] = wv
		endif
		str = JWN_GetStringFromWaveNote(data, path)
		if(!IsEmpty(str))
			Make/FREE/T wvt = {str}
			SetDimLabel ROWS, 0, $key, wvt
			output[0] = wvt
		endif
		WAVE/Z wvn = JWN_GetNumericWaveFromWaveNote(data, path)
		if(WaveExists(wvn))
			output[0] = wvn
		endif
		WAVE/Z/T wvt = JWN_GetTextWaveFromWaveNote(data, path)
		if(WaveExists(wvt))
			output[0] = wvt
		endif
	endif

	return SFH_GetOutputForExecutor(output, exd.graph, opShort)
End
