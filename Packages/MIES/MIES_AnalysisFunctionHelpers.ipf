#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_AFH
#endif // AUTOMATED_TESTING

/// @file MIES_AnalysisFunctionHelpers.ipf
/// @brief __AFH__ Helper functions for analysis function writers
///
/// Additionally the following functions might be useful
///
/// Function                      | Return value
/// ------------------------------|------------------------------------------------------
/// GetADCListFromConfig()        | Free wave with all active AD channels as entries
/// GetDACListFromConfig()        | Free wave with all active DA channels as entries
/// GetLBNumericalValues()        | Wave reference to the labnotebook (numerical version)
/// GetLBTextualValues()          | Wave reference to the labnotebook (textual version)
/// GetLastSetting()              | Last documented value for headstages of a specific setting in the labnotebook for a given sweep number.
/// GetLastSweepWithSetting()     | Last documented numerical value for headstages of a specific setting in the labnotebook and the sweep number it was set last.
/// GetLastSweepWithSettingText() | Last documented textual value for headstages of a specific setting in the labnotebook and the sweep number it was set last.
/// ED_AddEntryToLabnotebook()    | Add a user entry to the numerical/textual labnotebook

/// @brief Return the headstage the AD channel is assigned to
///
/// @param device device
/// @param AD         AD channel in the range [0,8[ or [0,16[
///                   depending on the hardware
///
/// @return headstage or NaN (for non-associated channels)
Function AFH_GetHeadstageFromADC(string device, variable AD)

	WAVE channelClampMode = GetChannelClampMode(device)

	return channelClampMode[AD][%ADC][%Headstage]
End

/// @brief Return the headstage the DA channel is assigned to
///
/// @param device device
/// @param DA         DA channel in the range [0,4[ or [0,8[
///                   depending on the hardware
///
/// @return headstage or NaN (for non-associated channels)
Function AFH_GetHeadstageFromDAC(string device, variable DA)

	WAVE channelClampMode = GetChannelClampMode(device)

	return channelClampMode[DA][%DAC][%Headstage]
End

/// @brief Return the AD channel assigned to the headstage
///
/// @param device device
/// @param headstage  headstage in the range [0,8[
///
/// @return AD channel or NaN (for non-associated channels)
Function AFH_GetADCFromHeadstage(string device, variable headstage)

	variable i, retHeadstage

	for(i = 0; i < NUM_AD_CHANNELS; i += 1)
		retHeadstage = AFH_GetHeadstageFromADC(device, i)
		if(isFinite(retHeadstage) && retHeadstage == headstage)
			return i
		endif
	endfor

	return NaN
End

/// @brief Return the DA channel assigned to the headstage
///
/// @param device device
/// @param headstage  headstage in the range [0,8[
///
/// @return DA channel or NaN (for non-associated channels)
Function AFH_GetDACFromHeadstage(string device, variable headstage)

	variable i, retHeadstage

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		retHeadstage = AFH_GetHeadstageFromDAC(device, i)
		if(isFinite(retHeadstage) && retHeadstage == headstage)
			return i
		endif
	endfor

	return NaN
End

/// @brief Return the column index into `DAQDataWave` for the given channel/type
///        combination
///
/// @param DAQConfigWave DAQ configuration wave, most users need to call
///                      `GetDAQConfigWave(device)` to get that wave.
/// @param channelNumber hardware channel number
/// @param channelType   channel type, one of @ref XopChannelConstants
threadsafe Function AFH_GetDAQDataColumn(WAVE DAQConfigWave, variable channelNumber, variable channelType)

	variable numRows, i

	ASSERT_TS(IsFinite(channelNumber), "Non-finite channel number")

	numRows = DimSize(DAQConfigWave, ROWS)
	for(i = 0; i < numRows; i += 1)

		if(channelType != DAQConfigWave[i][0])
			continue
		endif

		if(channelNumber != DAQConfigWave[i][1])
			continue
		endif

		return i
	endfor

	DEBUGPRINT_TS("Could not find the column")
	DEBUGPRINT_TS("Channel number", var = channelNumber)
	DEBUGPRINT_TS("Channel type", var = channelType)

	return NaN
End

/// @brief Return all channel units as free text wave
///
/// @param DAQConfigWave DAQ configuration wave, most users need to call
///                      `GetDAQConfigWave(device)` to get that wave.
threadsafe Function/WAVE AFH_GetChannelUnits(WAVE DAQConfigWave)

	string units

	if(IsValidConfigWave(DAQConfigWave, version = 1))
		units = GetStringFromWaveNote(DAQConfigWave, CHANNEL_UNIT_KEY, keySep = "=")
		return ListToTextWave(units, ",")
	endif

	units = note(DAQConfigWave)
	return ListToTextWave(units, ";")
End

/// @brief Return the channel unit
///
/// @param DAQConfigWave DAQ configuration wave, most users need to call
///                      `GetDAQConfigWave(device)` to get that wave.
/// @param channelNumber hardware channel number
/// @param channelType   channel type, one of @ref XopChannelConstants
Function/S AFH_GetChannelUnit(WAVE DAQConfigWave, variable channelNumber, variable channelType)

	variable idx

	idx = AFH_GetDAQDataColumn(DAQConfigWave, channelNumber, channelType)
	WAVE/T units = AFH_GetChannelUnits(DAQConfigWave)

	if(idx >= DimSize(units, ROWS))
		return ""
	endif

	return units[idx]
End

/// @brief Return the sweep number of the last acquired sweep
///
/// @return a non-negative integer sweep number or NaN if there is no data
Function AFH_GetLastSweepAcquired(string device)

	WAVE/Z sweeps = AFH_GetSweeps(device)

	if(!WaveExists(sweeps))
		return NaN
	endif

	return sweeps[Inf]
End

/// @brief Return a numeric wave with all acquired sweep numbers, $"" if there is none
Function/WAVE AFH_GetSweeps(string device)

	string list

	DFREF dfr = GetDeviceDataPath(device)

	list = GetListOfObjects(dfr, DATA_SWEEP_REGEXP)

	if(IsEmpty(list))
		return $""
	endif

	Make/FREE/R/N=(ItemsInList(list)) sweeps = ExtractSweepNumber(StringFromList(p, list))
	Sort sweeps, sweeps

	return sweeps
End

/// @brief Return the sweep wave of the last acquired sweep
///
/// @return an existing sweep wave or an invalid wave reference if there is no data
Function/WAVE AFH_GetLastSweepWaveAcquired(string device)

	return GetSweepWave(device, AFH_GetLastSweepAcquired(device))
End

/// @brief Return the stimset for the given channel
///
/// @param device      device
/// @param chanNo      channel number (0-based)
/// @param channelType one of the type constants from @ref ChannelTypeAndControlConstants
///
/// @return an existing stimulus set name for a DA channel
Function/S AFH_GetStimSetName(string device, variable chanNo, variable channelType)

	string ctrl

	ctrl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_WAVE)

	return DAG_GetTextualValue(device, ctrl, index = chanNo)
End

/// @brief Convenience wrapper for AFH_GetStimSetName
Function/S AFH_GetStimSetNameForHeadstage(string device, variable headstage)

	variable DAC

	DAC = AFH_GetDACFromHeadstage(device, headstage)
	ASSERT(IsFinite(DAC), "Can't work with unassociated channels")

	return AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
End

/// @brief Return a free wave with all sweep numbers (in ascending order) which
///        belong to the same RA cycle. Uncached version, general users should prefer
///        AFH_GetSweepsFromSameRACycle().
///
/// Return an invalid wave reference if not all required labnotebook entries are available
threadsafe static Function/WAVE AFH_GetSweepsFromSameRACycleNC(WAVE numericalValues, variable sweepNo)

	variable sweepCol, raCycleID

	raCycleID = GetLastSettingIndep(numericalValues, sweepNo, RA_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE, defValue = NaN)

	if(!isFinite(raCycleID))
		return $""
	endif

	WAVE/Z indizes = FindIndizes(numericalValues, colLabel = RA_ACQ_CYCLE_ID_KEY, var = raCycleID, \
	                             startLayer = INDEP_HEADSTAGE, endLayer = INDEP_HEADSTAGE)
	ASSERT_TS(WaveExists(indizes), "Expected at least one match")

	sweepCol = GetSweepColumn(numericalValues)
	Make/FREE/D/N=(DimSize(indizes, ROWS)) sweeps = numericalValues[indizes[p]][sweepCol][0]

	return sweeps
End

/// @brief Return a free wave with all sweep numbers (in ascending order) which
///        belong to the same RA cycle
///
/// Return an invalid wave reference if not all required labnotebook entries are available
threadsafe Function/WAVE AFH_GetSweepsFromSameRACycle(WAVE numericalValues, variable sweepNo)

	if(!IsValidSweepNumber(sweepNo))
		return $""
	endif

	WAVE/WAVE cache = GetLBNidCache(numericalValues)
	EnsureLargeEnoughWave(cache, indexShouldExist = sweepNo, dimension = ROWS)

	WAVE/Z sweeps = cache[sweepNo][%$RA_ACQ_CYCLE_ID_KEY][0]
	if(WaveExists(sweeps))
		if(DimSize(sweeps, ROWS) > 0) // valid cached entry
			ChangeWaveLock(sweeps, 1)
			return sweeps
		endif

		// non-existant entry
		return $""
	endif

	// uncached entry
	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycleNC(numericalValues, sweepNo)

	if(WaveExists(sweeps))
		cache[sweepNo][%$RA_ACQ_CYCLE_ID_KEY][0] = sweeps
	else // non-existant entry
		Make/FREE/N=0 empty
		cache[sweepNo][%$RA_ACQ_CYCLE_ID_KEY][0] = empty
	endif

	return sweeps
End

/// @brief Return a free wave with all sweep numbers (in ascending order) which
///        belong to the same stimset cycle
///
/// Return an invalid wave reference if not all required labnotebook entries are available
threadsafe Function/WAVE AFH_GetSweepsFromSameSCI(WAVE numericalValues, variable sweepNo, variable headstage)

	if(!IsValidSweepNumber(sweepNo))
		return $""
	endif

	WAVE/WAVE cache = GetLBNidCache(numericalValues)
	EnsureLargeEnoughWave(cache, indexShouldExist = sweepNo, dimension = ROWS)

	WAVE/Z sweeps = cache[sweepNo][%$STIMSET_ACQ_CYCLE_ID_KEY][headstage]
	if(WaveExists(sweeps))
		if(DimSize(sweeps, ROWS) > 0) // valid cached entry
			ChangeWaveLock(sweeps, 1)
			return sweeps
		endif

		// non-existant entry
		return $""
	endif

	// uncached entry
	WAVE/Z sweeps = AFH_GetSweepsFromSameSCINC(numericalValues, sweepNo, headstage)

	if(WaveExists(sweeps))
		cache[sweepNo][%$STIMSET_ACQ_CYCLE_ID_KEY][headstage] = sweeps
	else // non-existant entry
		Make/FREE/N=0 empty
		cache[sweepNo][%$STIMSET_ACQ_CYCLE_ID_KEY][headstage] = empty
	endif

	return sweeps
End

/// @brief Return a free wave with all sweep numbers (in ascending order) which
///        belong to the same stimset cycle id. Uncached version, general users should prefer
///        AFH_GetSweepsFromSameSCI().
///
/// Return an invalid wave reference if not all required labnotebook entries are available
threadsafe static Function/WAVE AFH_GetSweepsFromSameSCINC(WAVE numericalValues, variable sweepNo, variable headstage)

	variable sweepCol

	WAVE/Z stimsetCycleIDs = GetLastSetting(numericalValues, sweepNo, STIMSET_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE)

	if(!WaveExists(stimsetCycleIDs) || IsNaN(stimsetCycleIDs[headstage]))
		return $""
	endif

	WAVE/Z indizes = FindIndizes(numericalValues, colLabel = STIMSET_ACQ_CYCLE_ID_KEY, var = stimsetCycleIDs[headstage], \
	                             startLayer = headstage, endLayer = headstage)
	ASSERT_TS(WaveExists(indizes), "Expected at least one match")

	sweepCol = GetSweepColumn(numericalValues)
	Make/FREE/D/N=(DimSize(indizes, ROWS)) sweeps = numericalValues[indizes[p]][sweepCol][0]

	return sweeps
End

/// @brief Return a free 1D wave from the given sweep
///
/// Extract the AD channel data from headstage 1:
///
/// \rst
/// .. code-block:: igorpro
///
/// 	variable sweepNo = 5
/// 	WAVE sweep = GetSweepWave(device, sweepNo)
/// 	variable headstage = 1
/// 	WAVE data = AFH_ExtractOneDimDataFromSweep(device, sweep, headstage, XOP_CHANNEL_TYPE_ADC)
/// \endrst
///
/// Extract the TTL channel 1:
///
/// \rst
/// .. code-block:: igorpro
///
/// 	variable sweepNo = 6
/// 	WAVE sweep = GetSweepWave(device, sweepNo)
/// 	variable ttlChannel = 1
/// 	WAVE data = AFH_ExtractOneDimDataFromSweep(device, sweep, ttlChannel, XOP_CHANNEL_TYPE_TTL)
/// \endrst
///
/// @param device            device
/// @param sweep                 sweep wave
/// @param headstageOrChannelNum headstage [0, NUM_HEADSTAGES[ or channel number for TTL channels [0, NUM_DA_TTL_CHANNELS]
/// @param channelType           One of @ref XopChannelConstants
/// @param config                [optional, defaults to config wave of the sweep returned by GetConfigWave()] config wave
Function/WAVE AFH_ExtractOneDimDataFromSweep(string device, WAVE sweep, variable headstageOrChannelNum, variable channelType, [WAVE config])

	variable channelNum, col

	if(ParamIsDefault(config))
		WAVE config = GetConfigWave(sweep)
	endif

	switch(channelType)
		case XOP_CHANNEL_TYPE_DAC:
			channelNum = AFH_GetDACFromHeadstage(device, headstageOrChannelNum)
			break
		case XOP_CHANNEL_TYPE_ADC:
			channelNum = AFH_GetADCFromHeadstage(device, headstageOrChannelNum)
			break
		case XOP_CHANNEL_TYPE_TTL:
			channelNum = headstageOrChannelNum
			break
		default:
			FATAL_ERROR("Invalid channeltype")
	endswitch

	col = AFH_GetDAQDataColumn(config, channelNum, channelType)
	ASSERT(IsFinite(col), "invalid headstage and/or channelType")

	return ExtractOneDimDataFromSweep(config, sweep, col)
End

/// @brief Get list of possible analysis functions
///
/// @param versionBitMask       bitmask of different analysis function versions which should be returned, one
///                             of @ref AnalysisFunctionVersions
/// @param includeUserFunctions include analysis functions defined in "UserAnalysisFunctions.ipf"
Function/S AFH_GetAnalysisFunctions(variable versionBitMask, [variable includeUserFunctions])

	string funcList, func, list, procWin
	string funcListClean = ""
	variable numEntries, i, valid_f1, valid_f2, valid_f3

	if(ParamIsDefault(includeUserFunctions))
		includeUserFunctions = 1
	else
		includeUserFunctions = !!includeUserFunctions
	endif

	if(includeUserFunctions)
		funcList = FunctionList("*", ";", "KIND:2,WIN:UserAnalysisFunctions.ipf")
	else
		funcList = ""
	endif

	// gather all analysis functions from these files
	list       = WinList("MIES_AnalysisFunctions*.ipf", ";", "WIN:128")
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		procWin   = StringFromList(i, list)
		funcList += FunctionList("*", ";", "KIND:2,WIN:" + procWin)
	endfor

	numEntries = ItemsInList(funcList)
	for(i = 0; i < numEntries; i += 1)
		func = StringFromList(i, funcList)

		// assign each function to the function reference of type AFP_ANALYSIS_FUNC_V*
		// this allows to check if the signature of func is the same as the one of AFP_ANALYSIS_FUNC_V*
		FUNCREF AFP_ANALYSIS_FUNC_V1 f1 = $func
		FUNCREF AFP_ANALYSIS_FUNC_V2 f2 = $func
		FUNCREF AFP_ANALYSIS_FUNC_V3 f3 = $func

		valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
		valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))
		valid_f3 = FuncRefIsAssigned(FuncRefInfo(f3))

		if((valid_f1 && (versionBitMask & ANALYSIS_FUNCTION_VERSION_V1))    \
		   || (valid_f2 && (versionBitMask & ANALYSIS_FUNCTION_VERSION_V2)) \
		   || (valid_f3 && (versionBitMask & ANALYSIS_FUNCTION_VERSION_V3)))
			funcListClean = AddListItem(func, funcListClean, ";", Inf)
		endif
	endfor

	return funcListClean
End

/// @brief Return the list of required/optional analysis function
///        parameters, possibly including the type, as specified by the function
///        `$func_GetParams`
///
/// @param func Analysis function `V3` which must be valid and existing
/// @param mode Bit mask values from @ref GetListOfParamsModeFlags
Function/S AFH_GetListOfAnalysisParams(string func, variable mode)

	string params, re

	FUNCREF AFP_PARAM_GETTER_V3 f = $(func + "_GetParams")

	if(!FuncRefIsAssigned(FuncRefInfo(f))) // no such getter functions
		return ""
	endif

	params = f()

	ASSERT(strsearch(params, ";", 0) == -1, "Entries must be separated with ,")

	re = "\[.+\]"

	if((mode & REQUIRED_PARAMS) && (mode & OPTIONAL_PARAMS))
		return ReplaceString("[", ReplaceString("]", params, ""), "")
	elseif(mode & REQUIRED_PARAMS)
		return GrepList(params, re, 1, ",")
	elseif(mode & OPTIONAL_PARAMS)
		params = GrepList(params, re, 0, ",")
		return ReplaceString("[", ReplaceString("]", params, ""), "")
	else
		FATAL_ERROR("Invalid mode value")
	endif
End

/// @brief Get help string from optional `$func_GetHelp`
///
/// @param func Analysis function `V3`
/// @param name Parameter name
Function/S AFH_GetHelpForAnalysisParameter(string func, string name)

	FUNCREF AFP_PARAM_HELP_GETTER_V3 f = $(func + "_GetHelp")

	if(!FuncRefIsAssigned(FuncRefInfo(f)))
		return ""
	endif

	AssertOnAndClearRTError()
	try
		return f(name); AbortOnRTE
	catch
		ClearRTError()
		// ignoring errors here
	endtry

	return ""
End

/// @defgroup AnalysisFunctionParameterHelpers Analysis Helper functions for dealing with user parameters

/// @brief Return a semicolon separated list of user parameters
///
/// @ingroup AnalysisFunctionParameterHelpers
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
Function/S AFH_GetListOfAnalysisParamNames(string params)

	string entry, name
	string list = ""
	variable i, numEntries, pos

	numEntries = ItemsInList(params, ",")
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, params, ",")

		pos = strsearch(entry, ":", 0)
		if(pos != -1)
			name = entry[0, pos - 1]
		else
			name = entry
		endif

		list = AddListItem(name, list, ";", Inf)
	endfor

	return list
End

/// @brief Check if the given analysis parameter is present
///
/// @param name   parameter name
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
///
/// @ingroup AnalysisFunctionParameterHelpers
///
/// @return one if present, zero otherwise
Function AFH_IsParameterPresent(string name, string params)

	return WhichListItem(name, AFH_GetListOfAnalysisParamNames(params), ";", 0, 0) >= 0
End

/// @brief Return the type of the user parameter
///
/// @param name         parameter name
/// @param params       serialized parameters, usually just #AnalysisFunction_V3.params
/// @param typeCheck    [optional, defaults to true] Check with an assertion that
///                     the readout type is one of @ref ANALYSIS_FUNCTION_PARAMS_TYPES
/// @param expectedType [optional, defaults to nothing] Expected type, one of @ref ANALYSIS_FUNCTION_PARAMS_TYPES,
///                     aborts if the type does not match. Implies `typeCheck = true`.
/// @ingroup AnalysisFunctionParameterHelpers
/// @return one of @ref AnalysisFunctionParameterTypes or an empty string
Function/S AFH_GetAnalysisParamType(string name, string params, [variable typeCheck, string expectedType])

	string typeAndValue
	string type = ""
	variable pos

	if(ParamIsDefault(expectedType))
		expectedType = ""
	else
		typeCheck = 1
		ASSERT(AFH_IsValidAnalysisParamType(expectedType), "Invalid expectedType")
	endif

	if(ParamIsDefault(typeCheck))
		typeCheck = 1
	else
		typeCheck = !!typeCheck
	endif

	typeAndValue = StringByKey(name, params, ":", ",", 0)

	pos = strsearch(typeAndValue, "=", 0)
	if(pos != -1)
		type = typeAndValue[0, pos - 1]
	else
		type = typeAndValue
	endif

	if(typeCheck)
		ASSERT(AFH_IsValidAnalysisParamType(type), "Invalid type")
	endif

	if(!IsEmpty(expectedType))
		ASSERT(!cmpstr(type, expectedType), "Requested parameter is not of type: " + expectedType)
	endif

	return type
End

/// @brief Return a numerical user parameter
///
/// @param name     parameter name
/// @param params   serialized parameters, usually just #AnalysisFunction_V3.params
/// @param defValue [optional, defaults to `NaN`] return this value if the parameter could not be found
///
/// @ingroup AnalysisFunctionParameterHelpers
Function AFH_GetAnalysisParamNumerical(string name, string params, [variable defValue])

	string contents

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")

	if(!AFH_IsParameterPresent(name, params))
		if(ParamIsDefault(defValue))
			return NaN
		endif

		return defValue
	endif

	contents = AFH_GetAnalysisParameter(name, params, expectedType = "variable")

	return str2num(contents)
End

/// @brief Return a textual user parameter
///
/// @param name           parameter name
/// @param params         serialized parameters, usually just #AnalysisFunction_V3.params
/// @param defValue       [optional, defaults to an empty string] return this value if the parameter could not be found
/// @param percentDecoded [optional, defaults to true] if the return value should be percent decoded or not.
///
/// @ingroup AnalysisFunctionParameterHelpers
Function/S AFH_GetAnalysisParamTextual(string name, string params, [string defValue, variable percentDecoded])

	string contents

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")

	if(ParamIsDefault(percentDecoded))
		percentDecoded = 1
	else
		percentDecoded = !!percentDecoded
	endif

	if(!AFH_IsParameterPresent(name, params))
		if(ParamIsDefault(defValue))
			return ""
		endif

		return defValue
	endif

	contents = AFH_GetAnalysisParameter(name, params, expectedType = "string")

	if(percentDecoded)
		return URLDecode(contents)
	endif

	return contents
End

/// @brief Return a numerical wave user parameter
///
/// @param name     parameter name
/// @param params   serialized parameters, usually just #AnalysisFunction_V3.params
/// @param defValue [optional, defaults to an invalid wave ref] return this value if the parameter could not be found
///
/// @ingroup AnalysisFunctionParameterHelpers
///
/// @return wave reference to free numeric wave, or invalid wave ref in case the
/// parameter could not be found.
Function/WAVE AFH_GetAnalysisParamWave(string name, string params, [WAVE defValue])

	string contents

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")

	if(!AFH_IsParameterPresent(name, params))
		if(ParamIsDefault(defValue))
			return $""
		endif

		return defValue
	endif

	contents = AFH_GetAnalysisParameter(name, params, expectedType = "wave")

	return ListToNumericWave(contents, "|")
End

/// @brief Return a textual wave user parameter
///
/// @param name           parameter name
/// @param params         serialized parameters, usually just #AnalysisFunction_V3.params
/// @param defValue       [optional, defaults to an invalid wave ref] return this value if the parameter could not be found
/// @param percentDecoded [optional, defaults to true] if the return value should be percent decoded or not.
///
/// @ingroup AnalysisFunctionParameterHelpers
///
/// @return wave reference to free text wave, or invalid wave ref in case the
/// parameter could not be found.
Function/WAVE AFH_GetAnalysisParamTextWave(string name, string params, [WAVE/T defValue, variable percentDecoded])

	string contents

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")

	if(ParamIsDefault(percentDecoded))
		percentDecoded = 1
	else
		percentDecoded = !!percentDecoded
	endif

	if(!AFH_IsParameterPresent(name, params))
		if(ParamIsDefault(defValue))
			return $""
		endif

		return defValue
	endif

	contents = AFH_GetAnalysisParameter(name, params, expectedType = "textwave")

	WAVE/T wv = ListToTextWave(contents, "|")

	if(percentDecoded)
		wv[] = URLDecode(wv[p])
		return wv
	endif

	return wv
End

/// @brief Check if the given name is a valid user parameter name
///
/// @ingroup AnalysisFunctionParameterHelpers
Function AFH_IsValidAnalysisParameter(string name)

	return IsValidObjectName(name)
End

/// @brief Check if the given type is a valid user parameter type
///
/// @ingroup AnalysisFunctionParameterHelpers
Function AFH_IsValidAnalysisParamType(string type)

	return !IsEmpty(type) && WhichListItem(type, ANALYSIS_FUNCTION_PARAMS_TYPES, ";", 0, 0) != -1
End

/// @brief Return an user parameter's value as string
///
/// @param name         parameter name
/// @param params       serialized parameters, usually just #AnalysisFunction_V3.params
/// @param expectedType [optional, defaults to nothing] Expected type, one of @ref ANALYSIS_FUNCTION_PARAMS_TYPES,
///                     aborts if the type does not match.
///
/// @ingroup AnalysisFunctionParameterHelpers
Function/S AFH_GetAnalysisParameter(string name, string params, [string expectedType])

	string type, value

	if(ParamIsDefault(expectedType))
		type = AFH_GetAnalysisParamType(name, params, typeCheck = 0)
	else
		type = AFH_GetAnalysisParamType(name, params, expectedType = expectedType)
	endif

	return StringByKey(name + ":" + type, params, "=", ",", 0)
End

/// @brief Delete the given user parameter name
///
/// @param name   parameter name
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
///
/// @ingroup AnalysisFunctionParameterHelpers
///
/// @return serialized parameters with `name` removed
Function/S AFH_RemoveAnalysisParameter(string name, string params)

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a valid analysis parameter")
	return GrepList(params, "(?i)\\Q" + name + "\\E" + ":.*", 1, ",")
End

/// @brief Check the analysis parameters
///
/// The following checks are made:
/// - Valid and matching types
/// - Non-empty waves supplied
/// - All required parameters are present
/// - No additional parameters are present if some are required/optional
/// - Valid names
/// - Check function passes if present
///
/// @param genericFunc Name of an analysis V3 function
/// @param s           struct CheckParametersStruct with additional info
///
/// @return multiline error messages, an empty string on success
Function/S AFH_CheckAnalysisParameter(string genericFunc, STRUCT CheckParametersStruct &s)

	string allNames, presentNames, message, name
	string reqNamesAndTypesFromFunc, reqNames
	string optNamesAndTypesFromFunc, optNames
	variable index, numParams, i, valid_f1, valid_f2, isOpt, isReq, hasParamsInfo
	string header, text, namesAndTypesFromFunc, reqType, suppType

	FUNCREF AFP_PARAM_CHECK_V1 f1 = $(genericFunc + "_CheckParam")
	FUNCREF AFP_PARAM_CHECK_V2 f2 = $(genericFunc + "_CheckParam")

	valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
	valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))

	reqNamesAndTypesFromFunc = AFH_GetListOfAnalysisParams(genericFunc, REQUIRED_PARAMS)
	reqNames                 = AFH_GetListOfAnalysisParamNames(reqNamesAndTypesFromFunc)

	optNamesAndTypesFromFunc = AFH_GetListOfAnalysisParams(genericFunc, OPTIONAL_PARAMS)
	optNames                 = AFH_GetListOfAnalysisParamNames(optNamesAndTypesFromFunc)

	hasParamsInfo = !IsEmpty(optNames) || !IsEmpty(reqNames)

	presentNames = AFH_GetListOfAnalysisParamNames(s.params)

	allNames = GetUniqueTextEntriesFromList(optNames + reqNames + presentNames)

	numParams = ItemsInList(allNames)
	Make/FREE/T/N=(numParams) errorMessages

	for(i = 0; i < numParams; i += 1)
		name = StringFromList(i, allNames)

		if(!AFH_IsValidAnalysisParameter(name))
			errorMessages[index++] = name + ": has an invalid name."
			continue
		endif

		isOpt = (WhichListItem(name, optNames, ";", 0, 0) != -1)
		isReq = (WhichListItem(name, reqNames, ";", 0, 0) != -1)

		if(WhichListItem(name, presentNames, ";", 0, 0) == -1)
			if(isOpt)
				// non present optional parameters should not be checked
				continue
			endif

			// non present required parameters are an error
			if(isReq)
				errorMessages[index++] = name + ": is required but missing"
				continue
			endif
		else
			// present parameter is neither a required nor an optional parameter
			if(!isOpt && !isReq && hasParamsInfo)
				errorMessages[index++] = name + ": is present but neither required nor optional."
				continue
			endif
		endif

		if(hasParamsInfo)
			if(isReq)
				namesAndTypesFromFunc = reqNamesAndTypesFromFunc
			elseif(isOpt)
				namesAndTypesFromFunc = optNamesAndTypesFromFunc
			else
				FATAL_ERROR("Invalid case")
			endif

			// empty type specifications are allowed
			reqType = AFH_GetAnalysisParamType(name, namesAndTypesFromFunc, typeCheck = 0)
			if(!IsEmpty(reqType))
				// invalid types are not allowed
				if(WhichListItem(reqType, ANALYSIS_FUNCTION_PARAMS_TYPES) == -1)
					errorMessages[index++] = name + ": has an invalid type."
					continue
				endif

				// non-matching type
				suppType = AFH_GetAnalysisParamType(name, s.params, typeCheck = 0)
				if(cmpstr(reqType, suppType))
					errorMessages[index++] = name + ": has an differing types (" + reqType + " vs " + suppType + ")."
					continue
				endif

				strswitch(reqType)
					case "wave":
						WAVE/Z wv = AFH_GetAnalysisParamWave(name, s.params)
						if(!WaveExists(wv) || DimSize(wv, ROWS) == 0)
							errorMessages[index++] = name + ": has a non-existing or empty numeric wave."
							continue
						endif
						break
					case "textwave":
						WAVE/Z wv = AFH_GetAnalysisParamTextWave(name, s.params)
						if(!WaveExists(wv) || DimSize(wv, ROWS) == 0)
							errorMessages[index++] = name + ": has a non-existing or empty text wave."
							continue
						endif
						break
					default:
						// do nothing
						break
				endswitch
			endif
		endif

		AssertOnAndClearRTError()
		try
			if(valid_f1)
				message = f1(name, s.params); AbortOnRTE
			elseif(valid_f2)
				message = f2(name, s); AbortOnRTE
			else
				// no check function present
				message = ""
			endif

			// allow null return string meaning no error
			if(!IsNull(message) && !IsEmpty(message))
				errorMessages[index++] = name + ": " + trimstring(message)
			endif
		catch
			ClearRTError()
			errorMessages[index++] = name + ": Check was aborted"
		endtry
	endfor

	if(!index)
		return ""
	endif

	Redimension/N=(index) errorMessages

	sprintf header, "The error message%s are:\r", SelectString(index != 1, "", "s")
	wfprintf text, "\t- %s\r", errorMessages

	return header + text
End

/// @brief Add an analysis function parameter to the given stimset
///
/// This function adds the parameter to the `WPT` wave and checks that it is valid.
///
/// Exactly one of `var`/`str`/`wv` must be given.
///
/// @param setName stimset name
/// @param name    name of the parameter
/// @param var     [optional] numeric parameter
/// @param str     [optional] string parameter
/// @param wv      [optional] wave parameter can be numeric or text
Function AFH_AddAnalysisParameter(string setName, string name, [variable var, string str, WAVE wv])

	WAVE/Z/T WPT = WB_GetWaveTextParamForSet(setName)
	ASSERT(WaveExists(WPT), "Missing stimset")

	ASSERT((ParamIsDefault(var) + ParamIsDefault(str) + ParamIsDefault(wv)) == 2, "Expected one of var, str or wv")

	if(!ParamIsDefault(var))
		return WB_AddAnalysisParameterIntoWPT(WPT, name, var = var)
	elseif(!ParamIsDefault(str))
		return WB_AddAnalysisParameterIntoWPT(WPT, name, str = str)
	elseif(!ParamIsDefault(wv))
		return WB_AddAnalysisParameterIntoWPT(WPT, name, wv = wv)
	endif
End

/// @brief Add an analysis parameter to the given `params` string
///
/// Exactly one of `var`/`str`/`wv` must be given.
///
/// @param[in, out] params stimset name
/// @param[in]      name   name of the parameter
/// @param[in]      var    [optional] numeric parameter
/// @param[in]      str    [optional] string parameter
/// @param[in]      wv     [optional] wave parameter can be numeric or text
Function AFH_AddAnalysisParameterToParams(string &params, string name, [variable var, string str, WAVE wv])

	string type, value

	ASSERT((ParamIsDefault(var) + ParamIsDefault(str) + ParamIsDefault(wv)) == 2, "Expected one of var, str or wv")

	if(!ParamIsDefault(var))
		type = "variable"
		// numbers never need URL encoding
		value = num2str(var)
	elseif(!ParamIsDefault(str))
		type  = "string"
		value = URLEncode(str)
	elseif(!ParamIsDefault(wv))
		ASSERT(DimSize(wv, ROWS) > 0, "Expected non-empty wave")
		if(IsTextWave(wv))
			type = "textwave"
			Duplicate/T/FREE wv, wvText
			wvText = UrlEncode(wvText)
			value  = TextWaveToList(wvText, "|")
		else
			type = "wave"
			// numbers never need URL encoding
			value = NumericWaveToList(wv, "|", format = "%.15g")
		endif
	endif

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")
	ASSERT(!GrepString(value, "[=:,;]+"), "Broken URL encoding. Written entry contains invalid characters (one of `=:,;`)")
	ASSERT(AFH_IsValidAnalysisParamType(type), "Invalid type")

#ifndef AUTOMATED_TESTING
	if(WhichListItem(name, AFH_GetListOfAnalysisParamNames(params)) != -1)
		printf "Parameter \"%s\" is already present and will be overwritten!\r", name
	endif
#endif // !AUTOMATED_TESTING

	params = ReplaceStringByKey(name, params, type + "=" + value, ":", ",", 0)
End

/// @brief Return a stringified version of the analysis parameter value
///
/// @param name name of the parameter
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
Function/S AFH_GetAnalysisParameterAsText(string name, string params)

	string   type
	variable numericValue

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")

	type = AFH_GetAnalysisParamType(name, params, typeCheck = 0)

	strswitch(type)
		case "variable":
			numericValue = AFH_GetAnalysisParamNumerical(name, params)
			if(!IsNan(numericValue))
				return num2str(numericValue)
			endif
			break
		case "string":
			return AFH_GetAnalysisParamTextual(name, params)
			break
		case "wave":
			WAVE/Z wv = AFH_GetAnalysisParamWave(name, params)
			if(WaveExists(wv))
				return NumericWaveToList(wv, ";")
			endif
			break
		case "textwave":
			WAVE/Z wv = AFH_GetAnalysisParamTextWave(name, params)
			if(WaveExists(wv))
				return TextWaveToList(wv, ";")
			endif
			break
		case "": // unknown name
			break
		default:
			FATAL_ERROR("invalid type")
	endswitch

	return ""
End

/// @brief Return the headstage from the given active AD count
///
/// @param statusADC     channel status as returned by GetLastSetting()
/// @param activeADCount running number of active ADC's, starting at zero
///
/// @return headstage in the range [0, NUM_HEADSTAGES], or NaN if nothing could be found
Function AFH_GetHeadstageFromActiveADC(WAVE/Z statusADC, variable activeADCount)

	variable i, s

	ASSERT(DimSize(statusADC, ROWS) == LABNOTEBOOK_LAYER_COUNT, "Invalid number of rows")
	ASSERT(activeADCount >= 0 && activeADCount < NUM_AD_CHANNELS && IsInteger(activeADCount), "Invalid activeADCount")

	if(!WaveExists(statusADC))
		return NaN
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(IsFinite(statusADC[i]) && s == activeADCount)
			return i
		endif

		s += IsFinite(statusADC[i])
	endfor

	return NaN
End

/// @brief returns the correct config wave depending on the fact if sweepwave is
///        either a scaledDataWave from a currently running acquisition or
///        sweep wave from a finished acquisition
Function/WAVE AFH_GetConfigWave(string device, WAVE sweepWave)

	if(WaveRefsEqual(sweepWave, GetScaledDataWave(device)))
		WAVE config = GetDAQConfigWave(device)
	else
		WAVE config = GetConfigWave(sweepWave)
	endif

	return config
End

/// @brief Some analysis function like PSQ_Ramp and PSQ_EvaluateBaselineChunks need the current acquisition time
///        within the stimset (where the fifo is currently). This function wraps this calculation and returns the
///        time in ms. The stimset begin is the reference point and 0 ms on that time scale.
/// @param device device name
/// @param s analysis function structure V3
/// @returns point in time where the current fifo is within the stimset in ms
Function AFH_GetFifoInStimsetTime(string device, STRUCT AnalysisFunction_V3 &s)

	variable fifoInStimsetPoint

	fifoInStimsetPoint = s.lastKnownRowIndexAD - GetTotalOnsetDelayFromDevice(device) / s.sampleIntervalAD

	return fifoInStimsetPoint * s.sampleIntervalAD
End

Function/WAVE AFH_GetChannelFromSweepOrScaledWave(WAVE sweepOrScaled, variable channelIndex)

	if(IsWaveRefWave(sweepOrScaled))
		WAVE/WAVE scaled = sweepOrScaled
		return scaled[channelIndex]
	elseif(IsTextWave(sweepOrScaled))
		return ResolveSweepChannel(sweepOrScaled, channelIndex)
	endif

	FATAL_ERROR("Unknown Data format")
End

/// @brief Returns the DA and AD sample intervals of the given sweep. The sweep data input can be
///        text sweep wave, 2D numeric sweep wave or waveRef sweep wave (including e.g. scaledDataWave)
Function [variable sampleIntDA, variable sampleIntAD] AFH_GetSampleIntervalsFromSweep(WAVE sweep, WAVE config)

	if(IsTextWave(sweep))
		WAVE channel = ResolveSweepChannel(sweep, 0)
		sampleIntDA = DimDelta(channel, ROWS)
		WAVE channel = ResolveSweepChannel(sweep, GetFirstADCChannelIndex(config))
		sampleIntAD = DimDelta(channel, ROWS)
		return [sampleIntDA, sampleIntAD]
	endif

	if(IsWaveRefWave(sweep))
		WAVE/WAVE sweepRef = sweep
		WAVE      channel  = sweepRef[0]
		sampleIntDA = DimDelta(channel, ROWS)
		WAVE channel = sweepRef[GetFirstADCChannelIndex(config)]
		sampleIntAD = DimDelta(channel, ROWS)
		return [sampleIntDA, sampleIntAD]
	endif

	sampleIntDA = DimDelta(sweep, ROWS)

	return [sampleIntDA, sampleIntDA]
End

/// @brief Only for PSQ_RHEOBASE, returns a wave with passing and failing sweep numbers for sweepQC with all sweep numbers of the same SCI range
///        This is a workaround and uses a different approach as for other analysis functions.
///
/// @param numericalValues numerical LNB
/// @param sweepNo         sweep number
/// @param headstage       headstage number
/// @param sweepsSCI       numerical wave with all sweep numbers from the SCI where sweepNo is part of, @ref AFH_GetSweepsFromSameSCI
/// @param passedSetQC     flag that indicates if for this sweepNo the setQC passed, @ref GetLastSettingIndepSCI for PSQ_FMT_LBN_SET_PASS
///
/// @retval passingSweeps numerical wave containing the sweep numbers of the sweeps from this SCI that passed the sweepQC
/// @retval failingSweeps numerical wave containing the sweep numbers of the sweeps from this SCI that failed the sweepQC
Function [WAVE passingSweeps, WAVE failingSweeps] AFH_GetRheobaseSweepsSCISweepQCSplitted(WAVE numericalValues, variable sweepNo, variable headstage, WAVE sweepsSCI, variable passedSetQC)

	variable firstValid, lastValid
	string key

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	if(passedSetQC)
		WAVE spikeDetection = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
		ASSERT(DimSize(sweepsSCI, ROWS) == DimSize(spikeDetection, ROWS), "Unexpected wave sizes")

		firstValid = DimSize(spikeDetection, ROWS) - 2
		lastValid  = DimSize(spikeDetection, ROWS) - 1
		ASSERT(Sum(spikeDetection, firstValid, lastValid) == 1, "Unexpected spike/non-spike duo")
		Duplicate/FREE/R=[firstValid, lastValid] sweepsSCI, passingSweeps
		WAVE/Z failingSweeps = GetSetDifference(sweepsSCI, passingSweeps)
	else
		Duplicate/FREE sweepsSCI, failingSweeps
		WAVE/Z passingSweeps
	endif

	return [passingSweeps, failingSweeps]
End

/// @brief Return 1 if we are currently acquiring the last sweep in the stimulus set,
///        0 if not and NaN if it is not possible to determine
Function AFH_LastSweepInSet(string device, variable sweepNo, variable headstage, variable eventType)

	variable DAC, sweepsInSet, nextStimsetColumn, sweepOffset

	switch(eventType)
		case PRE_DAQ_EVENT: // fallthrough
		case PRE_SWEEP_CONFIG_EVENT:
			// no valid setup yet
			return NaN
		case PRE_SET_EVENT: // fallthrough
		case MID_SWEEP_EVENT:
			// we need to look at the last acquired sweep
			sweepNo    -= 1
			sweepOffset = 1
			break
		default:
			// do nothing
			break
	endswitch

	DAC         = AFH_GetDACFromHeadstage(device, headstage)
	sweepsInSet = IDX_NumberOfSweepsInSet(AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC))

	WAVE numericalValues = GetLBNumericalValues(device)

	nextStimsetColumn = AFH_GetNextSweepSetCount(numericalValues, sweepNo, headstage)

	return (nextStimsetColumn + sweepOffset) >= sweepsInSet
End

/// @brief Return the set count of the next sweep
///
/// No checking is done on the number of sweeps in the stimulus set
Function AFH_GetNextSweepSetCount(WAVE numericalValues, variable sweepNo, variable headstage)

	variable setCount, skipCountExisting

	WAVE/Z sweepSetCount = GetLastSetting(numericalValues, sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)

	if(!WaveExists(sweepSetCount))
		setCount = 0
	else
		setCount = sweepSetCount[headstage]
	endif

	skipCountExisting = GetLastSettingIndep(numericalValues, sweepNo, SKIP_SWEEPS_KEY, UNKNOWN_MODE, defValue = 0)

	return setCount + skipCountExisting + 1
End
