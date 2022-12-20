#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SFH_HELPERS
#endif

/// @file MIES_SweepFormula_Helpers.ipf
///
/// @brief __SFH__ Sweep formula related helper code

static StrConstant SFH_WORKING_DF = "FormulaData"

/// @brief Executes the part of the argument part of the JSON and parses the resulting data to a waveRef type
Function/WAVE SFH_GetArgument(variable jsonId, string jsonPath, string graph, string opShort, variable argNum)

	string opSpec, argStr

	argStr = num2istr(argNum)
	WAVE wv = SF_FormulaExecutor(graph, jsonID, jsonPath = jsonPath + "/" + argStr)
	opSpec = "_arg" + argStr
	WAVE/WAVE input = SFH_ParseArgument(graph, wv, opShort + opSpec)

	return input
End

Function/WAVE SFH_ParseArgument(string win, WAVE input, string opShort)

	string wName, tmpStr

	ASSERT(IsTextWave(input) && DimSize(input, ROWS) == 1 && DimSize(input, COLS) == 0, "Unknown SF argument input format")

	WAVE/T wvt = input
	ASSERT(strsearch(wvt[0], SF_WREF_MARKER, 0) == 0, "Marker not found in SF argument")

	tmpStr = wvt[0]
	wName = tmpStr[strlen(SF_WREF_MARKER), Inf]
	WAVE/Z out = $wName
	ASSERT(WaveExists(out), "Referenced wave not found: " + wName)

	return out
End

/// @brief Assertion for sweep formula
///
/// This assertion does *not* indicate a genearl programmer error but a
/// sweep formula user error.
///
/// All programmer error checks must still use ASSERT().
Function SFH_ASSERT(variable condition, string message[, variable jsonId])

	if(!condition)
		if(!ParamIsDefault(jsonId))
			JSON_Release(jsonId, ignoreErr=1)
		endif
		SVAR error = $GetSweepFormulaParseErrorMessage()
		error = message
#ifdef AUTOMATED_TESTING_DEBUGGING
		Debugger
#endif
		Abort
	endif
End

Function/WAVE SFH_GetEmptyRange()

	Make/FREE/D range = {NaN, NaN}

	return range
End

Function SFH_IsEmptyRange(WAVE range)

	ASSERT(IsNumericWave(range), "Invalid Range wave")
	WAVE rangeRef = SFH_GetEmptyRange()

	return	EqualWaves(rangeRef, range, 1)
End

/// @brief Returns a range from a epochName
///
/// @param graph name of databrowser graph
/// @param epochName name epoch
/// @param sweep number of sweep
/// @param channel number of DA channel
/// @returns a 1D wave with two elements, [startTime, endTime] in ms, if no epoch could be resolved [NaN, NaN] is returned
Function/WAVE SFH_GetRangeFromEpoch(string graph, string epochName, variable sweep, variable channel)

	string regex
	variable numEpochs

	WAVE range = SFH_GetEmptyRange()
	if(IsEmpty(epochName) || !IsValidSweepNumber(sweep))
		return range
	endif

	WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweep)
	if(!WaveExists(numericalValues))
		return range
	endif

	WAVE/Z textualValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweep)
	if(!WaveExists(textualValues))
		return range
	endif

	regex = "^" + epochName + "$"
	WAVE/T/Z epochs = EP_GetEpochs(numericalValues, textualValues, sweep, XOP_CHANNEL_TYPE_DAC, channel, regex)
	if(!WaveExists(epochs))
		return range
	endif
	numEpochs = DimSize(epochs, ROWS)
	SFH_ASSERT(numEpochs <= 1, "Found several fitting epochs. Currently only a single epoch is supported")
	if(numEpochs == 0)
		return range
	endif

	range[0] = str2num(epochs[0][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
	range[1] = str2num(epochs[0][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI

	return range
End

Function SFH_GetDAChannel(string graph, variable sweep, variable channelType, variable channelNumber)

	variable DAC, index

	WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweep)
	if(!WaveExists(numericalValues))
		return NaN
	endif
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweep, "DAC", channelNumber, channelType, DATA_ACQUISITION_MODE)
	if(WaveExists(settings))
		DAC = settings[index]
		ASSERT(IsFinite(DAC) && index < NUM_HEADSTAGES, "Only associated channels are supported.")
		return DAC
	endif

	return NaN
End

Function/WAVE SFH_GetSweepsForFormula(string graph, WAVE range, WAVE/Z selectData, string opShort)

	variable i, j, rangeStart, rangeEnd, DAChannel, sweepNo
	variable chanNr, chanType, cIndex, isSweepBrowser
	variable numSelected, index, numEpochPatterns, numRanges, numEpochs, epIndex
	string dimLabel, device, dataFolder
	string	allEpochsRegex = "^.*$"

	ASSERT(WindowExists(graph), "graph window does not exist")

	SFH_ASSERT(DimSize(range, COLS) == 0, "Range must be a 1d wave.")
	if(IsTextWave(range))
		SFH_ASSERT(DimSize(range, ROWS) > 0, "Epoch range can not be empty.")
		WAVE/T epochNames = range
		numEpochPatterns = DimSize(epochNames, ROWS)
	else
		SFH_ASSERT(DimSize(range, ROWS) == 2, "A numerical range is must have two rows for range start and end.")
		numEpochPatterns = 1
	endif
	if(!WaveExists(selectData))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_SWEEP)
		return output
	endif
	SFH_ASSERT(DimSize(selectData, COLS) == 3, "Select data must have 3 columns.")

	numSelected = DimSize(selectData, ROWS)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numSelected)

	isSweepBrowser = BSP_IsSweepBrowser(graph)

	if(isSweepBrowser)
		DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
		WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)
	else
		SFH_ASSERT(BSP_HasBoundDevice(graph), "No device bound.")
		device = BSP_GetDevice(graph)
		DFREF deviceDFR = GetDeviceDataPath(device)
	endif

	for(i = 0; i < numSelected; i += 1)

		sweepNo = selectData[i][%SWEEP]
		chanNr = selectData[i][%CHANNELNUMBER]
		chanType = selectData[i][%CHANNELTYPE]

		if(isSweepBrowser)
			cIndex = FindDimLabel(sweepMap, COLS, "Sweep")
			FindValue/RMD=[][cIndex]/TEXT=num2istr(sweepNo)/TXOP=4 sweepMap
			if(V_value == -1)
				continue
			endif
			dataFolder = sweepMap[V_row][%DataFolder]
			device     = sweepMap[V_row][%Device]
			DFREF deviceDFR  = GetAnalysisSweepPath(dataFolder, device)
		else
			if(DB_SplitSweepsIfReq(graph, sweepNo))
				continue
			endif
		endif

		DFREF sweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)

		WAVE/Z sweep = GetDAQDataSingleColumnWave(sweepDFR, chanType, chanNr)
		if(!WaveExists(sweep))
			continue
		endif

		if(WaveExists(epochNames))
			DAChannel = SFH_GetDAChannel(graph, sweepNo, chanType, chanNr)
			WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
			WAVE/Z textualValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)
			SFH_ASSERT(WaveExists(textualValues) && WaveExists(numericalValues), "LBN not found for sweep " + num2istr(sweepNo))
			WAVE/T/Z epochInfo = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, DAChannel, allEpochsRegex)
			if(!WaveExists(epochInfo))
				continue
			endif
			WAVE/T allEpNames = SFH_GetEpochNamesFromInfo(epochInfo)
			WAVE/Z epIndices = SFH_GetEpochIndicesByWildcardPatterns(allEpNames, epochNames)
			if(!WaveExists(epIndices))
				continue
			endif
			numEpochs = DimSize(epIndices, ROWS)
			WAVE range = SFH_GetEmptyRange()
			Redimension/N=(-1, numEpochs) range
			for(j = 0; j < numEpochs; j += 1)
				epIndex = epIndices[j]
				range[0][j] = str2num(epochInfo[epIndex][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
				range[1][j] = str2num(epochInfo[epIndex][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI
			endfor
		else
			Redimension/N=(-1, 1) range
		endif

		numRanges = DimSize(range, COLS)
		for(j = 0; j < numRanges; j += 1)
			rangeStart = range[0][j]
			rangeEnd = range[1][j]

			SFH_ASSERT(!SFH_IsEmptyRange(range), "Specified range not valid.")
			SFH_ASSERT(rangeStart == -inf || (IsFinite(rangeStart) && rangeStart >= leftx(sweep) && rangeStart < rightx(sweep)), "Specified starting range not inside sweep " + num2istr(sweepNo) + ".")
			SFH_ASSERT(rangeEnd == inf || (IsFinite(rangeEnd) && rangeEnd >= leftx(sweep) && rangeEnd < rightx(sweep)), "Specified ending range not inside sweep " + num2istr(sweepNo) + ".")
			Duplicate/FREE/R=(rangeStart, rangeEnd) sweep, rangedSweepData

			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_SWEEPNO, sweepNo)
			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_CHANNELTYPE, chanType)
			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_CHANNELNUMBER, chanNr)

			EnsureLargeEnoughWave(output, minimumSize=index)
			output[index] = rangedSweepData
			index += 1
		endfor
	endfor
	Redimension/N=(index) output

	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_SWEEP)

	return output
End

// returns number of operation arguments
Function SFH_GetNumberOfArguments(variable jsonId, string jsonPath)

	variable size

	size = JSON_GetArraySize(jsonID, jsonPath)
	if(!size)
		return size
	endif

	return JSON_GetType(jsonId, jsonPath + "/0") == JSON_NULL ? 0 : size
End

Function/DF SFH_GetWorkingDF(string win)

	DFREF dfr = BSP_GetFolder(GetMainWindow(win), MIES_BSP_PANEL_FOLDER)

	return createDFWithAllParents(GetDataFolder(1, dfr) + SFH_WORKING_DF)
End

Function/WAVE SFH_CreateSFRefWave(string win, string opShort, variable size)

	string wName

	DFREF dfrWork = SFH_GetWorkingDF(win)
	wName = UniqueWaveName(dfrWork, opShort + "_output_")

	Make/WAVE/N=(size) dfrWork:$wName/WAVE=wv

	return wv
End

Function SFH_CleanUpInput(WAVE input)

#ifndef SWEEPFORMULA_DEBUG
	KillOrMoveToTrash(wv = input)
#endif
End

static Function SFH_AddOpToOpStack(WAVE w, string oldStack, string opShort)

	JWN_SetStringInWaveNote(w, SF_META_OPSTACK, AddListItem(opShort, oldStack))
End

Function/WAVE SFH_GetOutputForExecutorSingle(WAVE/Z data, string graph, string opShort[, string opStack, WAVE clear])

	if(!ParamIsDefault(clear))
		SFH_CleanUpInput(clear)
	endif

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 1)
	if(WaveExists(data))
		output[0] = data
	endif

	if(!ParamIsDefault(opStack))
		SFH_AddOpToOpStack(output, opStack, opShort)
	endif

	return SFH_GetOutputForExecutor(output, graph, opShort)
End

Function/WAVE SFH_GetOutputForExecutor(WAVE output, string win, string opShort[, WAVE clear])

	if(!ParamIsDefault(clear))
		SFH_CleanUpInput(clear)
	endif
	Make/FREE/T wRefPath = {SF_WREF_MARKER + GetWavesDataFolder(output, 2)}

#ifdef SWEEPFORMULA_DEBUG
	SFH_ConvertAllReturnDataToPermanent(output, win, opShort)
#endif

	return wRefPath
End

static Function SFH_ConvertAllReturnDataToPermanent(WAVE/WAVE output, string win, string opShort)

	string wName
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

/// @brief Retrieves from an argument the first dataset and disposes the argument
Function/WAVE SFH_GetArgumentSingle(variable jsonId, string jsonPath, string graph, string opShort, variable argNum[, variable checkExist])

	checkExist = ParamIsDefault(checkExist) ? 0 : !!checkExist

	WAVE/WAVE input = SFH_GetArgument(jsonId, jsonPath, graph, opShort, argNum)
	SFH_ASSERT(DimSize(input, ROWS) == 1, "Expected only a single dataSet")
	WAVE/Z data = input[0]
	SFH_ASSERT(!(checkExist && !WaveExists(data)), "No data in dataSet at operation " + opShort + " arg num " + num2istr(argNum))
	SFH_CleanUpInput(input)

	return data
End

/// @brief Transfer wavenote from input data sets to output data sets
///        set a label for a x-axis and x-value(s) for data waves
Function SFH_TransferFormulaDataWaveNoteAndMeta(WAVE/WAVE input, WAVE/WAVE output, string opShort, string newDataType)

	variable sweepNo, numResults, i, setXLabel
	string opStack, inDataType, xLabel

	numResults = DimSize(input, ROWS)
	ASSERT(numResults == DimSize(output, ROWS), "Input and output must have the same size.")

	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, newDataType)

	opStack = JWN_GetStringFromWaveNote(input, SF_META_OPSTACK)
	SFH_AddOpToOpStack(output, opStack, opShort)

	inDataType = JWN_GetStringFromWaveNote(input, SF_META_DATATYPE)

	setXLabel = 1
	for(i = 0; i < numResults; i += 1)
		WAVE/Z inData = input[i]
		WAVE/Z outData = output[i]
		if(!WaveExists(inData) || !WaveExists(outData))
			continue
		endif

		Note/K outData, note(inData)

		strswitch(inDataType)
			case SF_DATATYPE_SWEEP:
				if(numpnts(outData) == 1 && IsEmpty(WaveUnits(outData, ROWS)))
					sweepNo = JWN_GetNumberFromWaveNote(outData, SF_META_SWEEPNO)
					JWN_SetWaveInWaveNote(outData, SF_META_XVALUES, {sweepNo})
				else
					setXLabel = 0
				endif
				break
			default:
				sweepNo = JWN_GetNumberFromWaveNote(outData, SF_META_SWEEPNO)
				if(numpnts(outData) == 1 && IsEmpty(WaveUnits(outData, ROWS)) && !IsNaN(sweepNo))
					JWN_SetWaveInWaveNote(outData, SF_META_XVALUES, {sweepNo})
				else
					setXLabel = 0
				endif
				break
		endswitch

	endfor

	xLabel = ""
	if(setXLabel)
		strswitch(inDataType)
			case SF_DATATYPE_SWEEP:
				xLabel = "Sweeps"
				break
			default:
				xLabel = "Sweeps"
				break
		endswitch
	endif

	JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, xLabel)
End

Function/WAVE SFH_GetArgumentSelect(variable jsonId, string jsonPath, string graph, string opShort, variable argNum)

	variable numArgs
	string msg

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)

	if(argNum < numArgs)
		WAVE/Z selectData = SFH_GetArgumentSingle(jsonID, jsonPath, graph, opShort, argNum)
	else
		WAVE/Z selectData = SF_ExecuteFormula("select()", graph, singleResult=1)
	endif

	if(WaveExists(selectData))
		sprintf msg, "Argument #%d of operation %s: input must have three columns", argNum, opShort
		SFH_ASSERT(DimSize(selectData, COLS) == 3, msg)

		sprintf msg, "Argument #%d of operation %s: Must be numeric ", argNum, opShort
		SFH_ASSERT(IsNumericWave(selectData), msg)
	endif

	return selectData
End

Function/WAVE SFH_GetEpochNamesFromInfo(WAVE/T epochInfo)

	string epName, epShortName
	variable i
	variable numEpochs = DimSize(epochInfo, ROWS)

	Make/FREE/T/N=(numEpochs) epNames
	for(i = 0; i < numEpochs; i += 1)
		epName = epochInfo[i][EPOCH_COL_TAGS]
		epShortName = EP_GetShortName(epName)
		epNames[i] = SelectString(IsEmpty(epShortName), epShortName, epName)
	endfor

	return epNames
End

Function/WAVE SFH_GetEpochIndicesByWildcardPatterns(WAVE/T epochNames, WAVE/T patterns)

	variable i
	variable numPatterns = DimSize(patterns, ROWS)

	for(i = 0; i < numPatterns; i += 1)
		WAVE/Z indices = FindIndizes(epochNames, str=patterns[i], prop=PROP_WILDCARD)
		if(!WaveExists(indices))
			continue
		endif
		Concatenate/FREE/NP {indices}, allIndices
	endfor
	if(!WaveExists(allIndices))
		return $""
	endif
	WAVE uniqueEntries = GetUniqueEntries(allIndices, dontDuplicate=1)

	return uniqueEntries
End
