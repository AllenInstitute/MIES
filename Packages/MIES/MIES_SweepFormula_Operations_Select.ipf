#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_SFOS
#endif // AUTOMATED_TESTING

// to enable debug mode with more persistent data
// #define SWEEPFORMULA_DEBUG

/// @file MIES_SweepFormula_Operations_Select.ipf
///
/// @brief __SFOS__ Sweep Formula Operations Select

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

static StrConstant DB_EXPNAME_DUMMY = "|DataBrowserExperiment|"

/// `select(selectFilterOp...)`
///
/// returns 2 datasets, main wave typed SF_DATATYPE_SELECTCOMP
/// dataset 0: N x 3 with columns [sweepNr][channelType][channelNr], typed SF_DATATYPE_SELECT
/// dataset 1: WaveRef wave with range specifications, typed SF_DATATYPE_SELECTRANGE
Function/WAVE SFOS_OperationSelect(variable jsonId, string jsonPath, string graph)

	STRUCT SF_SelectParameters filter
	variable i, numArgs, selectArgPresent
	string type, vis
	string expName = ""
	string device  = ""

	SFOS_InitSelectFilterUninitalized(filter)

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
					WAVE/Z filter.selects = SFOS_GetSetIntersectionSelect(filter.selects, arg)
				endif
				break
			default:
				SFH_FATAL_ERROR("Unsupported select argument")
		endswitch
	endfor

	SFOS_SetSelectionFilterDefaults(graph, filter, selectArgPresent)

	if(!IsEmpty(expName))
		filter.experimentName = SFOS_GetSelectionExperiment(graph, expName)
	endif
	if(!IsEmpty(device))
		filter.device = SFOS_GetSelectionDevice(graph, device)
	endif

	WAVE/Z selectData = SFOS_GetSelectData(graph, filter)
	if(WaveExists(selectData))
		if(!IsNaN(filter.racIndex))
			WAVE/Z racSelectData = SFOS_GetSelectDataWithRACorSCIIndex(graph, selectData, filter.racIndex, SELECTDATA_MODE_RAC)
			WAVE/Z selectData    = racSelectData
		endif
		if(!IsNaN(filter.sciIndex))
			WAVE/Z sciSelectData = SFOS_GetSelectDataWithRACorSCIIndex(graph, selectData, filter.sciIndex, SELECTDATA_MODE_SCI)
			WAVE/Z selectData    = sciSelectData
		endif
		// SCI is a subset of RAC, thus if RAC and SCI is enabled then it is sufficient to extend through RAC
		if(filter.expandRAC)
			WAVE selectWithRACFilledUp = SFOS_GetSelectDataWithSCIorRAC(graph, selectData, filter, SELECTDATA_MODE_RAC)
			WAVE selectData            = selectWithRACFilledUp
		elseif(filter.expandSCI)
			WAVE selectWithSCIFilledUp = SFOS_GetSelectDataWithSCIorRAC(graph, selectData, filter, SELECTDATA_MODE_SCI)
			WAVE selectData            = selectWithSCIFilledUp
		endif
		if(filter.expandSCI || filter.expandRAC)
			WAVE sortedSelectData = SFOS_SortSelectData(selectData)
			WAVE selectData       = sortedSelectData
		endif
	endif

	if(!WaveExists(selectData))
		// case: select from added filter arguments leaves empty selection, then result is empty as intersection with any other selection would yield also empty result
		WAVE/Z selectResult = $""
	elseif(WaveExists(filter.selects))
		// case: select argument(s) present, selection from argument is intersected with select from added filter arguments
		WAVE/Z selectResult = SFOS_GetSetIntersectionSelect(filter.selects, selectData)
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
Function/WAVE SFOS_OperationSelectChannels(variable jsonId, string jsonPath, string graph)

	variable numArgs, i, channelType
	string channelName, channelNumber
	string regExp = "^(?i)(" + ReplaceString(";", XOP_CHANNEL_NAMES, "|") + ")([0-9]+)?$"

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)
	WAVE channels = SFOS_NewChannelsWave(numArgs ? numArgs : 1)
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
Function/WAVE SFOS_OperationSelectCM(variable jsonId, string jsonPath, string graph)

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
Function/WAVE SFOS_OperationSelectDevice(variable jsonId, string jsonPath, string graph)

	string expName

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTDEV, 1, maxArgs = 1)

	expName = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTDEV, 0)
	Make/FREE/T output = {expName}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTDEV, discardOpStack = 1, dataType = SF_DATATYPE_SELECTDEV)
End

/// `selexpandrac()` // no arguments
///
/// returns a one element numeric wave
Function/WAVE SFOS_OperationSelectExpandRAC(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTEXPANDRAC, 0, maxArgs = 0)

	Make/FREE/D output = {1}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTEXPANDRAC, discardOpStack = 1, dataType = SF_DATATYPE_SELECTEXPANDRAC)
End

/// `selexpandsci()` // no arguments
///
/// returns a one element numeric wave
Function/WAVE SFOS_OperationSelectExpandSCI(variable jsonId, string jsonPath, string graph)

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTEXPANDSCI, 0, maxArgs = 0)

	Make/FREE/D output = {1}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTEXPANDSCI, discardOpStack = 1, dataType = SF_DATATYPE_SELECTEXPANDSCI)
End

/// `selexp(expName)` // expName is a string with optional wildcards
///
/// returns a one element text wave
Function/WAVE SFOS_OperationSelectExperiment(variable jsonId, string jsonPath, string graph)

	string expName

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTEXP, 1, maxArgs = 1)

	expName = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTEXP, 0)
	Make/FREE/T output = {expName}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTEXP, discardOpStack = 1, dataType = SF_DATATYPE_SELECTEXP)
End

/// `SelIVSCCSetQC(passed | failed)`
///
/// returns a one element numeric wave with either SF_OP_SELECT_IVSCCSETQC_PASSED or SF_OP_SELECT_IVSCCSETQC_FAILED
Function/WAVE SFOS_OperationSelectIVSCCSetQC(variable jsonId, string jsonPath, string graph)

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
Function/WAVE SFOS_OperationSelectIVSCCSweepQC(variable jsonId, string jsonPath, string graph)

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
Function/WAVE SFOS_OperationSelectRACIndex(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTRACINDEX, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTRACINDEX, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTRACINDEX, discardOpStack = 1, dataType = SF_DATATYPE_SELECTRACINDEX)
End

/// `selrange(rangespec)`
///
/// returns 1 dataset with range specification (either text or 2 point numerical wave)
Function/WAVE SFOS_OperationSelectRange(variable jsonId, string jsonPath, string graph)

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
Function/WAVE SFOS_OperationSelectSCIIndex(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSCIINDEX, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTSCIINDEX, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSCIINDEX, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSCIINDEX)
End

/// `selsetcyclecount(x)` // one numeric argument
///
/// returns a one element numeric wave
Function/WAVE SFOS_OperationSelectSetCycleCount(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSETCYCLECOUNT, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTSETCYCLECOUNT, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSETCYCLECOUNT, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSETCYCLECOUNT)
End

/// `selsetsweepcount(x)` // one numeric argument
///
/// returns a one element numeric wave
Function/WAVE SFOS_OperationSelectSetSweepCount(variable jsonId, string jsonPath, string graph)

	variable value

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTSETSWEEPCOUNT, 1, maxArgs = 1)

	value = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, SF_OP_SELECTSETSWEEPCOUNT, 0)
	Make/FREE/D output = {value}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTSETSWEEPCOUNT, discardOpStack = 1, dataType = SF_DATATYPE_SELECTSETSWEEPCOUNT)
End

/// `selstimset(stimsetName, stimsetName, ...)`
///
/// returns a N element text wave with stimset names
Function/WAVE SFOS_OperationSelectStimset(variable jsonId, string jsonPath, string graph)

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
Function/WAVE SFOS_OperationSelectSweeps(variable jsonId, string jsonPath, string graph)

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
Function/WAVE SFOS_OperationSelectVis(variable jsonId, string jsonPath, string graph)

	string vis

	SFH_CheckArgumentCount(jsonId, jsonPath, SF_OP_SELECTVIS, 0, maxArgs = 1)

	vis = SFH_GetArgumentAsText(jsonId, jsonPath, graph, SF_OP_SELECTVIS, 0, allowedValues = {SF_OP_SELECTVIS_DISPLAYED, SF_OP_SELECTVIS_ALL}, defValue = SF_OP_SELECTVIS_DISPLAYED)
	Make/FREE/T output = {vis}

	return SFH_GetOutputForExecutorSingle(output, graph, SF_OP_SELECTVIS, discardOpStack = 1, dataType = SF_DATATYPE_SELECTVIS)
End

static Function SFOS_InitSelectFilterUninitalized(STRUCT SF_SelectParameters &s)

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

/// @brief Returns the set intersection of two select waves from operation select
static Function/WAVE SFOS_GetSetIntersectionSelect(WAVE select1, WAVE select2)

	WAVE rowId1 = SFOS_CreateSelectWaveRowIds(select1)
	WAVE rowId2 = SFOS_CreateSelectWaveRowIds(select2)

	WAVE/Z intersect = GetSetIntersection(rowId1, rowId2, getIndices = 1)
	if(!WaveExists(intersect))
		return $""
	endif

	WAVE output = SFH_NewSelectDataWave(DimSize(intersect, ROWS), 1)
	MultiThread output[][] = select1[intersect[p]][q]

	return output
End

/// @brief sets uninitialized fields of the selection filter
static Function SFOS_SetSelectionFilterDefaults(string graph, STRUCT SF_SelectParameters &filter, variable includeAll)

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

static Function/S SFOS_GetSelectionExperiment(string graph, string expName)

	string currentExperimentName

	if(BSP_IsDataBrowser(graph))
		currentExperimentName = GetExperimentName()
		SFH_ASSERT(stringmatch(currentExperimentName, expName), "Selected experiment does not exist")

		return currentExperimentName
	endif
	if(BSP_IsSweepBrowser(graph))
		return SFOS_MatchSweepMapColumn(graph, expName, "FileName", SF_OP_SELECTEXP)
	endif

	FATAL_ERROR("Unknown browser type")
End

static Function/S SFOS_GetSelectionDevice(string graph, string device)

	string deviceDB

	if(BSP_IsDataBrowser(graph))
		deviceDB = DB_GetDevice(graph)
		SFH_ASSERT(!IsEmpty(deviceDB), "DataBrowser has no locked device")
		SFH_ASSERT(stringmatch(deviceDB, device), "Selected device does not exist")

		return deviceDB
	endif
	if(BSP_IsSweepBrowser(graph))
		return SFOS_MatchSweepMapColumn(graph, device, "Device", SF_OP_SELECTDEV)
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
static Function/WAVE SFOS_GetSelectData(string graph, STRUCT SF_SelectParameters &filter)

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
		WAVE      sweepPropertiesDisplayed = SFOS_MakeSweepPropertiesDisplayed(numTraces)
		WAVE/WAVE sweepLNBsDisplayed       = SFOS_MakeSweepLNBsDisplayed(numTraces)
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
				WAVE/Z mapIndices = SFOS_GetSweepMapIndices(sweepMap, sweepNo, filter.experimentName, filter.device)
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

							clampCode = SFOS_MapClampModeToSelectCM(sweepPropertiesDisplayed[l][SWEEPPROP_CLAMPMODE])
							if(!SFOS_IsValidSingleSelection(filter, sweepLNBsDisplayed[l][%NUMERICAL], sweepLNBsDisplayed[l][%TEXTUAL], sweepNo, channelNumber, channelType, selectDisplayed[l][dimPosSweep], selectDisplayed[l][dimPosChannelNumber], selectDisplayed[l][dimPosChannelType], clampCode, sweepPropertiesDisplayed[l][SWEEPPROP_SETCYCLECOUNT], sweepPropertiesDisplayed[l][SWEEPPROP_SETSWEEPCOUNT], doStimsetMatching))
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

							if(SFOS_FilterByClampModeEnabled(filter.clampMode, channelType))
								[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, CLAMPMODE_ENTRY_KEY, l, channelType, DATA_ACQUISITION_MODE)
								clampCode             = WaveExists(setting) ? SFOS_MapClampModeToSelectCM(setting[index]) : SF_OP_SELECT_CLAMPCODE_NONE
							endif
							if(!IsNaN(filter.setCycleCount))
								[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "Set Cycle Count", l, channelType, DATA_ACQUISITION_MODE)
								setCycleCount         = WaveExists(setting) ? setting[index] : NaN
							endif
							if(!IsNaN(filter.setSweepCount))
								[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "Set Sweep Count", l, channelType, DATA_ACQUISITION_MODE)
								setSweepCount         = WaveExists(setting) ? setting[index] : NaN
							endif

							if(!SFOS_IsValidSingleSelection(filter, numericalValues, textualValues, sweepNo, channelNumber, channelType, sweepNo, l, channelType, clampCode, setCycleCount, setSweepCount, doStimsetMatching))
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
	WAVE out = SFOS_SortSelectData(selectData)

	return out
End

static Function/WAVE SFOS_GetSelectDataWithRACorSCIIndex(string graph, WAVE selectData, variable index, variable mode)

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
			return SFOS_GetSelectDataWithRACIndex(selectData, cycleIdsZapped, sweepMap, index)
		case SELECTDATA_MODE_SCI:
			return SFOS_GetSelectDataWithSCIIndex(selectData, cycleIdsZapped, headStagesZapped, sweepMap, index)
		default:
			FATAL_ERROR("Unknown mode")
	endswitch
End

static Function/WAVE SFOS_GetSelectDataWithRACIndex(WAVE selectData, WAVE cycleIds, WAVE/Z/T sweepMap, variable index)

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

static Function/WAVE SFOS_GetSelectDataWithSCIIndex(WAVE selectData, WAVE cycleIds, WAVE headstages, WAVE/Z/T sweepMap, variable index)

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

static Function/WAVE SFOS_GetAdditionalSweepsWithSameSCIorRAC(WAVE numericalValues, variable mode, variable sweepNo, variable channelType, variable channelNumber)

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

static Function/WAVE SFOS_SortSelectData(WAVE selectData)

	variable dimPosSweep, dimPosChannelType, dimPosChannelNumber

	if(DimSize(selectData, ROWS) >= 1)
		dimPosSweep         = FindDimLabel(selectData, COLS, "SWEEP")
		dimPosChannelType   = FindDimLabel(selectData, COLS, "CHANNELTYPE")
		dimPosChannelNumber = FindDimLabel(selectData, COLS, "CHANNELNUMBER")

		SortColumns/KNDX={dimPosSweep, dimPosChannelType, dimPosChannelNumber} sortWaves=selectData
	endif

	return selectData
End

static Function/WAVE SFOS_CreateSelectWaveRowIds(WAVE select)

	Make/FREE/T/N=(DimSize(select, ROWS)) selectRowId
	Multithread selectRowId[] = SFOS_GetSelectRowId(select, p)

	return selectRowId
End

static Function/WAVE SFOS_GetUniqueSelectData(WAVE selectData)

	WAVE/T selectText       = SFOS_CreateSelectWaveRowIds(selectData)
	WAVE/T selectTextUnique = GetUniqueEntries(selectText)
	return SFOS_RestoreSelectDataFromText(selectTextUnique)
End

/// @brief Takes input selections and extends them. The extension of the selection is chosen through mode, one of SELECTDATA_MODE_*
///        For RAC: For each input selection adds all selections of the same repeated acquisition cycle
///        For SCI: For each input selection adds all selections of the same stimset cycle id and headstage
///        Returns all resulting unique selections.
static Function/WAVE SFOS_GetSelectDataWithSCIorRAC(string graph, WAVE selectData, STRUCT SF_SelectParameters &filter, variable mode)

	variable i, j, isSweepBrowser, numSelected
	variable sweepNo, channelType, channelNumber, mapIndex
	variable addSweepNo

	ASSERT(mode == SELECTDATA_MODE_SCI || mode == SELECTDATA_MODE_RAC, "Unknown SCI/RAC mode")

	[STRUCT SF_SelectParameters filterDup] = SFOS_DuplicateSelectFilter(filter)
	filterDup.vis                          = SF_OP_SELECTVIS_ALL

	isSweepBrowser = BSP_IsSweepBrowser(graph)
	if(isSweepBrowser)
		WAVE/T sweepMap = SB_GetSweepMap(graph)
		if(mode == SELECTDATA_MODE_SCI)
			Make/FREE/T/N=(GetNumberFromWaveNote(sweepMap, NOTE_INDEX)) sweepMapIds
			MultiThread sweepMapIds[] = SFOS_GetSweepMapRowId(sweepMap, p)
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
		WAVE/Z additionalSweeps = SFOS_GetAdditionalSweepsWithSameSCIorRAC(numericalValues, mode, sweepNo, channelType, channelNumber)
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
				MultiThread selectDataAdd[][%SWEEPMAPINDEX] = SFOS_GetSweepMapIndexFromIds(sweepMapIds, filterDup.experimentName, sweepMap[mapIndex][%DataFolder], filterDup.device, additionalSweeps[p])
			else
				selectDataAdd[][%SWEEPMAPINDEX] = NaN
			endif
		else
			WAVE   filterDup.sweeps = additionalSweeps
			WAVE/Z selectDataAdd    = SFOS_GetSelectData(graph, filterDup)
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

	return SFOS_GetUniqueSelectData(selectDataCollect)
End

static Function/WAVE SFOS_NewChannelsWave(variable size)

	ASSERT(size >= 0, "Invalid wave size specified")

	Make/N=(size, 2)/FREE out = NaN
	SetDimLabel COLS, 0, channelType, out
	SetDimLabel COLS, 1, channelNumber, out

	return out
End

static Function/S SFOS_MatchSweepMapColumn(string graph, string match, string colLabel, string opShort)

	variable col

	WAVE/T sweepMap = SB_GetSweepMap(graph)
	WAVE/Z indices  = SFOS_GetSweepMapIndices(sweepMap, NaN, "", "", colLabel = colLabel, wildCardPattern = match)
	SFH_ASSERT(WaveExists(indices), "No match found in sweepMap in operation " + opShort)

	col = FindDimlabel(sweepMap, COLS, colLabel)
	Make/FREE/T/N=(DimSize(indices, ROWS)) entries
	MultiThread entries[] = sweepMap[indices[p]][col]

	WAVE/T uniqueEntries = GetUniqueEntries(entries)
	SFH_ASSERT(DimSize(uniqueEntries, ROWS) < 2, "Multiple matches found in sweepMap in operation " + opShort)
	SFH_ASSERT(DimSize(uniqueEntries, ROWS) == 1, "No match found in sweepMap in operation " + opShort)

	return uniqueEntries[0]
End

static Function/WAVE SFOS_MakeSweepPropertiesDisplayed(variable numTraces)

	Make/FREE/D/N=(numTraces, SWEEPPROP_END) sweepPropertiesDisplayed

	return sweepPropertiesDisplayed
End

static Function/WAVE SFOS_MakeSweepLNBsDisplayed(variable numTraces)

	Make/FREE/WAVE/N=(numTraces, 2) wv
	SetDimLabel COLS, 0, NUMERICAL, wv
	SetDimLabel COLS, 1, TEXTUAL, wv

	return wv
End

/// @brief Return the matching indices of sweepMap, if expName or device is an emtpy string then it is ignored
static Function/WAVE SFOS_GetSweepMapIndices(WAVE/T sweepMap, variable sweepNo, string expName, string device, [string colLabel, string wildCardPattern])

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

static Function SFOS_MapClampModeToSelectCM(variable clampMode)

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

static Function SFOS_IsValidSingleSelection(STRUCT SF_SelectParameters &filter, WAVE numericalValues, WAVE textualValues, variable filtSweepNo, variable filtChannelNumber, variable filtChannelType, variable sweepNo, variable channelNumber, variable channelType, variable clampMode, variable setCycleCount, variable setSweepCount, variable doStimsetMatching)

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

	if(SFOS_FilterByClampModeEnabled(filter.clampMode, channelType) && !(filter.clampMode & clampMode))
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

static Function SFOS_FilterByClampModeEnabled(variable clampModeFilter, variable channelType)

	return clampModeFilter != SF_OP_SELECT_CLAMPCODE_ALL && (channelType == XOP_CHANNEL_TYPE_DAC || channelType == XOP_CHANNEL_TYPE_ADC)
End

threadsafe static Function/S SFOS_GetSelectRowId(WAVE select, variable row)

	string str

	sprintf str, SF_GETSETINTERSECTIONSELECT_FORMAT, select[row][%SWEEP], select[row][%CHANNELTYPE], select[row][%CHANNELNUMBER], select[row][%SWEEPMAPINDEX]
	return str
End

static Function/WAVE SFOS_RestoreSelectDataFromText(WAVE/T selectText)

	WAVE selectData = SFH_NewSelectDataWave(DimSize(selectText, ROWS), 1)
	MultiThread selectData[][%SWEEP] = SFOS_ParseSelectText(selectText, selectData, p)

	return selectData
End

static Function [STRUCT SF_SelectParameters filterDup] SFOS_DuplicateSelectFilter(STRUCT SF_SelectParameters &filter)

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

threadsafe static Function/S SFOS_CreateSweepMapRowId(string experiment, string datafolder, string device, string sweep)

	string id

	sprintf id, "%s|%s|%s|%s", experiment, datafolder, device, sweep

	return id
End

threadsafe static Function/S SFOS_GetSweepMapRowId(WAVE/T sweepMap, variable index)

	return SFOS_CreateSweepMapRowId(sweepMap[index][%FileName], sweepMap[index][%DataFolder], sweepMap[index][%Device], sweepMap[index][%Sweep])
End

threadsafe static Function SFOS_GetSweepMapIndexFromIds(WAVE/T sweepMapIds, string experiment, string datafolder, string device, variable sweepNo)

	string id

	id = SFOS_CreateSweepMapRowId(experiment, datafolder, device, num2istr(sweepNo))
	FindValue/TXOP=4/TEXT=id sweepMapIds
	ASSERT_TS(V_row >= 0, "SweepMap id not found")

	return V_row
End

threadsafe static Function SFOS_ParseSelectText(WAVE/T selectText, WAVE selectData, variable index)

	variable sweepNo, channelNumber, channelType, mapIndex

	sscanf selectText[index], SF_GETSETINTERSECTIONSELECT_FORMAT, sweepNo, channelType, channelNumber, mapIndex
	ASSERT_TS(V_flag == 4, "Failed parsing selectText")
	selectData[index][%SWEEP]         = sweepNo
	selectData[index][%CHANNELNUMBER] = channelNumber
	selectData[index][%CHANNELTYPE]   = channelType
	selectData[index][%SWEEPMAPINDEX] = mapIndex

	return sweepNo
End
