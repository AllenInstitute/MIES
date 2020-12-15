#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AFH
#endif

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
/// @param panelTitle device
/// @param AD         AD channel in the range [0,8[ or [0,16[
///                   depending on the hardware
///
/// @return headstage or NaN (for non-associated channels)
Function AFH_GetHeadstageFromADC(panelTitle, AD)
	string panelTitle
	variable AD

	WAVE channelClampMode = GetChannelClampMode(panelTitle)

	return channelClampMode[AD][%ADC][%Headstage]
End

/// @brief Return the headstage the DA channel is assigned to
///
/// @param panelTitle device
/// @param DA         DA channel in the range [0,4[ or [0,8[
///                   depending on the hardware
///
/// @return headstage or NaN (for non-associated channels)
Function AFH_GetHeadstageFromDAC(panelTitle, DA)
	string 	panelTitle
	variable DA

	WAVE channelClampMode = GetChannelClampMode(panelTitle)

	return channelClampMode[DA][%DAC][%Headstage]
End

/// @brief Return the AD channel assigned to the headstage
///
/// @param panelTitle device
/// @param headstage  headstage in the range [0,8[
///
/// @return AD channel or NaN (for non-associated channels)
Function AFH_GetADCFromHeadstage(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable i, retHeadstage

	for(i = 0; i < NUM_AD_CHANNELS; i += 1)
		retHeadstage = AFH_GetHeadstageFromADC(panelTitle, i)
		if(isFinite(retHeadstage) && retHeadstage == headstage)
			return i
		endif
	endfor

	return NaN
End

/// @brief Return the DA channel assigned to the headstage
///
/// @param panelTitle device
/// @param headstage  headstage in the range [0,8[
///
/// @return DA channel or NaN (for non-associated channels)
Function AFH_GetDACFromHeadstage(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable i, retHeadstage

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		retHeadstage = AFH_GetHeadstageFromDAC(panelTitle, i)
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
///                      `GetDAQConfigWave(panelTitle)` to get that wave.
/// @param channelNumber channel number (0-based)
/// @param channelType   channel type, one of @ref ItcXopChannelConstants
Function AFH_GetITCDataColumn(DAQConfigWave, channelNumber, channelType)
	WAVE DAQConfigWave
	variable channelNumber, channelType

	variable numRows, i

	ASSERT(IsFinite(channelNumber), "Non-finite channel number")

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

	DEBUGPRINT("Could not find the column")
	DEBUGPRINT("Channel number", var = channelNumber)
	DEBUGPRINT("Channel type", var = channelType)

	return NaN
End

/// @brief Return all channel units as free text wave
///
/// @param DAQConfigWave DAQ configuration wave, most users need to call
///                      `GetDAQConfigWave(panelTitle)` to get that wave.
Function/WAVE AFH_GetChannelUnits(DAQConfigWave)
	WAVE DAQConfigWave

	string units

	if(IsValidConfigWave(DAQConfigWave, version=1))
		units = GetStringFromWaveNote(DAQConfigWave, CHANNEL_UNIT_KEY, keySep = "=")
		return ListToTextWave(units, ",")
	else
		units = note(DAQConfigWave)
		return ListToTextWave(units, ";")
	endif
End

/// @brief Return the channel unit
///
/// @param DAQConfigWave DAQ configuration wave, most users need to call
///                      `GetDAQConfigWave(panelTitle)` to get that wave.
/// @param channelNumber channel number (0-based)
/// @param channelType   channel type, one of @ref ItcXopChannelConstants
Function/S AFH_GetChannelUnit(DAQConfigWave, channelNumber, channelType)
	WAVE DAQConfigWave
	variable channelNumber, channelType

	variable idx

	idx = AFH_GetITCDataColumn(DAQConfigWave, channelNumber, channelType)
	WAVE/T units = AFH_GetChannelUnits(DAQConfigWave)

	if(idx >= DimSize(units, ROWS))
		return ""
	endif

	return units[idx]
End

/// @brief Return the sweep number of the last acquired sweep
///
/// Handles sweep number rollback properly.
///
/// @return a non-negative integer sweep number or NaN if there is no data
Function AFH_GetLastSweepAcquired(panelTitle)
	string panelTitle

	string list, name
	variable numItems, i, sweep

	list = GetListOfObjects(GetDeviceDataPath(panelTitle), DATA_SWEEP_REGEXP)
	list = SortList(list, ";", 1 + 16) // descending and case-insensitive alphanumeric

	numItems = ItemsInList(list)
	for(i = 0; i < numItems; i += 1)
		name = StringFromList(i, list)
		sweep = ExtractSweepNumber(name)

		if(WaveExists(GetSweepWave(panelTitle, sweep)))
			return sweep
		endif
	endfor

	return NaN
End

/// @brief Return the sweep wave of the last acquired sweep
///
/// @return an existing sweep wave or an invalid wave reference if there is no data
Function/WAVE AFH_GetLastSweepWaveAcquired(panelTitle)
	string panelTitle

	return GetSweepWave(panelTitle, AFH_GetLastSweepAcquired(panelTitle))
End

/// @brief Return the stimset for the given channel
///
/// @param panelTitle device
/// @param chanNo	channel number (0-based)
/// @param channelType		one of the type constants from @ref ChannelTypeAndControlConstants
/// @return an existing stimulus set name for a DA channel
Function/S AFH_GetStimSetName(panelTitle, chanNo, channelType)
	string panelTitle
	variable chanNo
	variable channelType

	string ctrl, stimset
	ctrl = GetPanelControl(chanNo, channelType, CHANNEL_CONTROL_WAVE)
	ControlInfo/W=$panelTitle $ctrl
	stimset = S_Value

	ASSERT(!isEmpty(stimset), "Empty stimset")

	return stimset
End

/// @brief Return a free wave with all sweep numbers (in ascending order) which
///        belong to the same RA cycle. Uncached version, general users should prefer
///        AFH_GetSweepsFromSameRACycle().
///
/// Return an invalid wave reference if not all required labnotebook entries are available
static Function/WAVE AFH_GetSweepsFromSameRACycleNC(numericalValues, sweepNo)
	WAVE numericalValues
	variable sweepNo

	variable sweepCol, raCycleID

	raCycleID = GetLastSettingIndep(numericalValues, sweepNo, RA_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE, defValue = NaN)

	if(!isFinite(raCycleID))
		return $""
	endif

	WAVE/Z indizes = FindIndizes(numericalValues, colLabel = RA_ACQ_CYCLE_ID_KEY, var = raCycleID, \
								 startLayer = INDEP_HEADSTAGE, endLayer = INDEP_HEADSTAGE)
	ASSERT(WaveExists(indizes), "Expected at least one match")

	sweepCol = GetSweepColumn(numericalValues)
	Make/FREE/D/N=(DimSize(indizes, ROWS)) sweeps = numericalValues[indizes[p]][sweepCol][0]

	return sweeps
End

/// @brief Return a free wave with all sweep numbers (in ascending order) which
///        belong to the same RA cycle
///
/// Return an invalid wave reference if not all required labnotebook entries are available
Function/WAVE AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	WAVE numericalValues
	variable sweepNo

	if(!IsValidSweepNumber(sweepNo))
		return $""
	endif

	WAVE/WAVE cache = GetLBNidCache(numericalValues)
	EnsureLargeEnoughWave(cache, minimumSize = sweepNo, dimension = ROWS)

	WAVE/Z sweeps = cache[sweepNo][%$RA_ACQ_CYCLE_ID_KEY][0]
	if(WaveExists(sweeps))
		if(DimSize(sweeps, ROWS) > 0) // valid cached entry
			return sweeps
		else // non-existant entry
			return $""
		endif
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
Function/WAVE AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
	WAVE numericalValues
	variable sweepNo, headstage

	if(!IsValidSweepNumber(sweepNo))
		return $""
	endif

	WAVE/WAVE cache = GetLBNidCache(numericalValues)
	EnsureLargeEnoughWave(cache, minimumSize = sweepNo, dimension = ROWS)

	WAVE/Z sweeps = cache[sweepNo][%$STIMSET_ACQ_CYCLE_ID_KEY][headstage]
	if(WaveExists(sweeps))
		if(DimSize(sweeps, ROWS) > 0) // valid cached entry
			return sweeps
		else // non-existant entry
			return $""
		endif
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
static Function/WAVE AFH_GetSweepsFromSameSCINC(numericalValues, sweepNo, headstage)
	WAVE numericalValues
	variable sweepNo
	variable headstage

	variable sweepCol

	WAVE/Z stimsetCycleIDs = GetLastSetting(numericalValues, sweepNo, STIMSET_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE)

	if(!WaveExists(stimsetCycleIDs) || IsNaN(stimsetCycleIDs[headstage]))
		return $""
	endif

	WAVE/Z indizes = FindIndizes(numericalValues, colLabel = STIMSET_ACQ_CYCLE_ID_KEY, var = stimsetCycleIDs[headstage], \
								 startLayer = headstage, endLayer = headstage)
	ASSERT(WaveExists(indizes), "Expected at least one match")

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
/// 	WAVE sweep = GetSweepWave(panelTitle, sweepNo)
/// 	variable headstage = 1
/// 	WAVE data = AFH_ExtractOneDimDataFromSweep(panelTitle, sweep, headstage, ITC_XOP_CHANNEL_TYPE_ADC)
/// \endrst
///
/// Extract the TTL channel 1:
///
/// \rst
/// .. code-block:: igorpro
///
/// 	variable sweepNo = 6
/// 	WAVE sweep = GetSweepWave(panelTitle, sweepNo)
/// 	variable ttlChannel = 1
/// 	WAVE data = AFH_ExtractOneDimDataFromSweep(panelTitle, sweep, ttlChannel, ITC_XOP_CHANNEL_TYPE_TTL)
/// \endrst
///
/// @param panelTitle            device
/// @param sweep                 sweep wave
/// @param headstageOrChannelNum headstage [0, NUM_HEADSTAGES[ or channel number for TTL channels [0, NUM_DA_TTL_CHANNELS]
/// @param channelType           One of @ref ItcXopChannelConstants
/// @param config                [optional, defaults to config wave of the sweep returned by GetConfigWave()] config wave
Function/WAVE AFH_ExtractOneDimDataFromSweep(panelTitle, sweep, headstageOrChannelNum, channelType, [config])
	string panelTitle
	WAVE sweep
	variable headstageOrChannelNum, channelType
	WAVE config

	variable channelNum, col

	if(ParamIsDefault(config))
		WAVE config = GetConfigWave(sweep)
	endif

	switch(channelType)
		case ITC_XOP_CHANNEL_TYPE_DAC:
			channelNum = AFH_GetDACFromHeadstage(panelTitle, headstageOrChannelNum)
			break
		case ITC_XOP_CHANNEL_TYPE_ADC:
			channelNum = AFH_GetADCFromHeadstage(panelTitle, headstageOrChannelNum)
			break
		case ITC_XOP_CHANNEL_TYPE_TTL:
			channelNum = headstageOrChannelNum
			break
		default:
			ASSERT(0, "Invalid channeltype")
	endswitch

	col = AFH_GetITCDataColumn(config, channelNum, channelType)
	ASSERT(IsFinite(col), "invalid headstage and/or channelType")

	return ExtractOneDimDataFromSweep(config, sweep, col)
End

/// @brief Get list of possible analysis functions
///
/// @param versionBitMask bitmask of different analysis function versions which should be returned, one
///                       of @ref AnalysisFunctionVersions
Function/S AFH_GetAnalysisFunctions(versionBitMask)
	variable versionBitMask

	string funcList, func
	string funcListClean = ""
	variable numEntries, i, valid_f1, valid_f2, valid_f3

	funcList  = FunctionList("*", ";", "KIND:2,WIN:MIES_AnalysisFunctions.ipf")
	funcList += FunctionList("*", ";", "KIND:2,WIN:MIES_AnalysisFunctions_PatchSeq.ipf")
	funcList += FunctionList("*", ";", "KIND:2,WIN:MIES_AnalysisFunctions_MultiPatchSeq.ipf")
	funcList += FunctionList("*", ";", "KIND:2,WIN:UserAnalysisFunctions.ipf")

	numEntries = ItemsInList(funcList)
	for(i = 0; i < numEntries; i += 1)
		func = StringFromList(i, funcList)

		// assign each function to the function reference of type AF_PROTO_ANALYSIS_FUNC_V*
		// this allows to check if the signature of func is the same as the one of AF_PROTO_ANALYSIS_FUNC_V*
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f1 = $func
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V2 f2 = $func
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V3 f3 = $func

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
Function/S AFH_GetListOfAnalysisParams(func, mode)
	string func
	variable mode

	string params, re

	FUNCREF AF_PROTO_PARAM_GETTER_V3 f = $(func + "_GetParams")

	if(!FuncRefIsAssigned(FuncRefInfo(f))) // no such getter functions
		return ""
	endif

	params = f()

	ASSERT(strsearch(params, ";", 0) == -1, "Entries must be separated with ,")

	re = "\[.+\]"

	if(mode & REQUIRED_PARAMS && mode & OPTIONAL_PARAMS)
		return ReplaceString("[", ReplaceString("]", params, ""), "")
	elseif(mode & REQUIRED_PARAMS)
		return GrepList(params, re, 1, ",")
	elseif(mode & OPTIONAL_PARAMS)
		params = GrepList(params, re, 0, ",")
		return ReplaceString("[", ReplaceString("]", params, ""), "")
	else
		ASSERT(0, "Invalid mode value")
	endif
End

/// @defgroup AnalysisFunctionParameterHelpers Analysis Helper functions for dealing with user parameters

/// @brief Return a semicolon separated list of user parameters
///
/// @ingroup AnalysisFunctionParameterHelpers
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
Function/S AFH_GetListOfAnalysisParamNames(params)
	string params

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
Function/S AFH_GetAnalysisParamType(name, params, [typeCheck, expectedType])
	string name, params
	variable typeCheck
	string expectedType

	string typeAndValue
	string type = ""
	variable pos

	if(!ParamIsDefault(expectedType))
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
Function AFH_GetAnalysisParamNumerical(name, params, [defValue])
	string name, params
	variable defValue

	string contents

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")

	if(WhichListItem(name, AFH_GetListOfAnalysisParamNames(params)) == -1)
		if(ParamIsDefault(defValue))
			return NaN
		else
			return defValue
		endif
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
Function/S AFH_GetAnalysisParamTextual(name, params, [defValue, percentDecoded])
	string name, params
	string defValue
	variable percentDecoded

	string contents

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")

	if(ParamIsDefault(percentDecoded))
		percentDecoded = 1
	else
		percentDecoded = !!percentDecoded
	endif

	if(WhichListItem(name, AFH_GetListOfAnalysisParamNames(params)) == -1)
		if(ParamIsDefault(defValue))
			return ""
		else
			return defValue
		endif
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
Function/WAVE AFH_GetAnalysisParamWave(name, params, [defValue])
	string name, params
	WAVE defValue

	string contents

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")

	if(WhichListItem(name, AFH_GetListOfAnalysisParamNames(params)) == -1)
		if(ParamIsDefault(defValue))
			return $""
		else
			return defValue
		endif
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
Function/WAVE AFH_GetAnalysisParamTextWave(name, params, [defValue, percentDecoded])
	string name, params
	WAVE/T defValue
	variable percentDecoded

	string contents

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")

	if(ParamIsDefault(percentDecoded))
		percentDecoded = 1
	else
		percentDecoded = !!percentDecoded
	endif

	if(WhichListItem(name, AFH_GetListOfAnalysisParamNames(params)) == -1)
		if(ParamIsDefault(defValue))
			return $""
		else
			return defValue
		endif
	endif

	contents = AFH_GetAnalysisParameter(name, params, expectedType = "textwave")

	WAVE/T wv = ListToTextWave(contents, "|")

	if(percentDecoded)
		wv = URLDecode(wv)
		return wv
	endif

	return wv
End

/// @brief Check if the given name is a valid user parameter name
///
/// @ingroup AnalysisFunctionParameterHelpers
Function AFH_IsValidAnalysisParameter(name)
	string name

	return IsValidObjectName(name)
End

/// @brief Check if the given type is a valid user parameter type
///
/// @ingroup AnalysisFunctionParameterHelpers
Function AFH_IsValidAnalysisParamType(type)
	string type

	return !IsEmpty(type) && WhichListItem(type, ANALYSIS_FUNCTION_PARAMS_TYPES) != -1
End

/// @brief Return an user parameter's value as string
///
/// @param name         parameter name
/// @param params       serialized parameters, usually just #AnalysisFunction_V3.params
/// @param expectedType [optional, defaults to nothing] Expected type, one of @ref ANALYSIS_FUNCTION_PARAMS_TYPES,
///                     aborts if the type does not match.
///
/// @ingroup AnalysisFunctionParameterHelpers
Function/S AFH_GetAnalysisParameter(name, params, [expectedType])
	string name, params
	string expectedType

	string type, value

	if(ParamIsDefault(expectedType))
		type = AFH_GetAnalysisParamType(name, params)
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
Function/S AFH_RemoveAnalysisParameter(name, params)
	string name, params

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a valid analysis parameter")
	return GrepList(params, "(?i)\\Q" + name + "\\E" + ":.*", 1, ",")
End

/// @brief Check the analysis parameters according to the optionally present check function
///
/// @param genericFunc Name of an analysis V3 function
/// @param params      Analysis parameter (encoded)
///
/// @return multiline error messages, an empty string on success
Function/S AFH_CheckAnalysisParameter(genericFunc, params)
	string genericFunc, params

	string suggNames, presentNames, message, name
	string reqNamesAndTypesFromFunc, reqNames
	string optNamesAndTypesFromFunc, optNames
	variable index, numParams, i
	string header, text

	FUNCREF AF_PROTO_PARAM_CHECK f = $(genericFunc + "_CheckParam")

	if(!FuncRefIsAssigned(FuncRefInfo(f)))
		return ""
	endif

	reqNamesAndTypesFromFunc = AFH_GetListOfAnalysisParams(genericFunc, REQUIRED_PARAMS)
	reqNames = AFH_GetListOfAnalysisParamNames(reqNamesAndTypesFromFunc)

	optNamesAndTypesFromFunc = AFH_GetListOfAnalysisParams(genericFunc, OPTIONAL_PARAMS)
	optNames = AFH_GetListOfAnalysisParamNames(optNamesAndTypesFromFunc)

	suggNames = optNames + reqNames

	presentNames = AFH_GetListOfAnalysisParamNames(params)

	numParams = ItemsInList(suggNames)
	Make/FREE/T/N=(numParams) errorMessages

	for(i = 0; i < numParams; i += 1)
		name = StringFromList(i, suggNames)

		if(WhichListItem(name, presentNames) == -1)
			if(WhichListItem(name, optNames) != -1)
				// non present optional parameters should not be checked
				continue
			endif

			// non present required parameters are an error
			errorMessages[index++] = name + ": is required but missing"
			continue
		endif

		try
			ClearRTError()
			message = f(name, params); AbortOnRTE

			if(!IsEmpty(message))
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
