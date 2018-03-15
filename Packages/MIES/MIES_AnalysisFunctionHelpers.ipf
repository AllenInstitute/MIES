#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
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
/// GetLastSetting()              | Last documented numerical value for headstages of a specific setting in the labnotebook for a given sweep number.
/// GetLastSettingText()          | Last documented textual value for headstages of a specific setting in the labnotebook for a given sweep number.
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

	variable i, row, entries

	WAVE ChanAmpAssign = GetChanAmpAssign(panelTitle)
	WAVE ChannelClampMode = GetChannelClampMode(panelTitle)

	entries = DimSize(ChanAmpAssign, COLS)
	row = ChannelClampMode[AD][%ADC] == V_CLAMP_MODE ? 2 : 2 + 4
	for(i = 0; i < entries; i += 1)
		if(chanAmpAssign[row][i] == AD)
			return i
		endif
	endfor

	return NaN
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

	variable i, row, entries

	WAVE ChanAmpAssign = GetChanAmpAssign(panelTitle)
	WAVE channelClampMode = GetChannelClampMode(panelTitle)

	entries = DimSize(chanAmpAssign, COLS)
	row = channelClampMode[DA][%DAC] == V_CLAMP_MODE ? 0 : 0 + 4

	for(i = 0; i < entries; i += 1)
		if(chanAmpAssign[row][i] == DA)
			return i
		endif
	endfor

	return NaN
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

/// @brief Return the column index into `ITCDataWave` for the given channel/type
///        combination
///
/// @param ITCChanConfigWave ITC configuration wave, most users need to call
///                          `GetITCChanConfigWave(panelTitle)` to get that wave.
/// @param channelNumber     channel number (0-based)
/// @param channelType       channel type, one of @ref ITC_XOP_CHANNEL_CONSTANTS
Function AFH_GetITCDataColumn(ITCChanConfigWave, channelNumber, channelType)
	WAVE ITCChanConfigWave
	variable channelNumber, channelType

	variable numRows, i

	ASSERT(IsFinite(channelNumber), "Non-finite channel number")

	numRows = DimSize(ITCChanConfigWave, ROWS)
	for(i = 0; i < numRows; i += 1)

		if(channelType != ITCChanConfigWave[i][0])
			continue
		endif

		if(channelNumber != ITCChanConfigWave[i][1])
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
/// @param ITCChanConfigWave ITC configuration wave, most users need to call
///                          `GetITCChanConfigWave(panelTitle)` to get that wave.
Function/WAVE AFH_GetChannelUnits(ITCChanConfigWave)
	WAVE ITCChanConfigWave

	string units

	if(IsLatestConfigWaveVersion(ITCChanConfigWave))
		units = GetStringFromWaveNote(ITCChanConfigWave, CHANNEL_UNIT_KEY, keySep = "=")
		return ListToTextWave(units, ",")
	else
		units = note(ITCChanConfigWave)
		return ListToTextWave(units, ";")
	endif
End

/// @brief Return the channel unit
///
/// @param ITCChanConfigWave ITC configuration wave, most users need to call
///                          `GetITCChanConfigWave(panelTitle)` to get that wave.
/// @param channelNumber     channel number (0-based)
/// @param channelType       channel type, one of @ref ITC_XOP_CHANNEL_CONSTANTS
Function/S AFH_GetChannelUnit(ITCChanConfigWave, channelNumber, channelType)
	WAVE ITCChanConfigWave
	variable channelNumber, channelType

	variable idx

	idx = AFH_GetITCDataColumn(ITCChanConfigWave, channelNumber, channelType)
	WAVE/T units = AFH_GetChannelUnits(ITCChanConfigWave)

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

	list = GetListOfObjects(GetDeviceDataPath(panelTitle), DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
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

/// @brief Return a free wave with all sweep numbers which belong to the same RA cycle
///
/// Return an invalid wave reference if not all required labnotebook entries are available
Function/WAVE AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	WAVE numericalValues
	variable sweepNo

	variable sweepCol, col, raCycleID

	raCycleID = GetLastSettingIndep(numericalValues, sweepNo, RA_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE, defValue = NaN)

	if(!isFinite(raCycleID))
		return $""
	endif

	col = FindDimLabel(numericalValues, COLS, RA_ACQ_CYCLE_ID_KEY)
	Duplicate/FREE/R=[][col][INDEP_HEADSTAGE] numericalValues, singleColLayer
	WAVE/Z indizes = FindIndizes(singleColLayer, col = 0, var = raCycleID)
	ASSERT(WaveExists(indizes), "Expected at least one match")

	sweepCol = GetSweepColumn(numericalValues)
	Make/FREE/D/N=(DimSize(indizes, ROWS)) sweeps = numericalValues[indizes[p]][sweepCol][0]

	return sweeps
End

/// @brief Return a free 1D wave from the given sweep
///
/// @param panelTitle  device
/// @param sweep       sweep wave
/// @param headstage   headstage [0, NUM_HEADSTAGES[
/// @param channelType One of @ref ITC_XOP_CHANNEL_CONSTANTS (currently only AD/DA types are supported)
/// @param config      [optional, defaults to config wave of the sweep returned by GetConfigWave()] config wave
Function/WAVE AFH_ExtractOneDimDataFromSweep(panelTitle, sweep, headstage, channelType, [config])
	string panelTitle
	WAVE sweep
	variable headstage, channelType
	WAVE config

	variable channelNum, col

	if(ParamIsDefault(config))
		WAVE config = GetConfigWave(sweep)
	endif

	switch(channelType)
		case ITC_XOP_CHANNEL_TYPE_DAC:
			channelNum = AFH_GetDACFromHeadstage(panelTitle, headStage)
			break
		case ITC_XOP_CHANNEL_TYPE_ADC:
			channelNum = AFH_GetADCFromHeadstage(panelTitle, headStage)
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

/// @brief Return the list of required analysis function
/// parameters as specified by the function `$func_GetParams`
///
/// @param func Analysis function `V3` which must be valid and existing
Function/S AFH_GetListOfReqAnalysisParams(func)
	string func

	FUNCREF AF_PROTO_PARAM_GETTER_V3 f = $(func + "_GetParams")

	if(!FuncRefIsAssigned(FuncRefInfo(f))) // no such getter functions
		return ""
	endif

	return f()
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
		pos  = strsearch(entry, ":", 0)
		ASSERT(pos != -1, "Invalid params format")
		name = entry[0, pos - 1]
		list = AddListItem(name, list, ";", Inf)
	endfor

	return list
End

/// @brief Return the type of the user parameter
///
/// @param name   parameter name
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
///
/// @ingroup AnalysisFunctionParameterHelpers
/// @return one of @ref AnalysisFunctionParameterTypes
Function/S AFH_GetAnalysisParamType(name, params)
	string name, params

	string typeAndValue, type
	variable pos

	typeAndValue = StringByKey(name , params, ":", ",", 0)

	pos = strsearch(typeAndValue, "=", 0)
	ASSERT(pos != -1, "Invalid params format")
	type = typeAndValue[0, pos - 1]
	ASSERT(!IsEmpty(type) && WhichListItem(type, ANALYSIS_FUNCTION_PARAMS_TYPES) != -1, "Invalid type")

	return typeAndValue[0, pos - 1]
End

/// @brief Return a numerical user parameter
///
/// @param name   parameter name
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
/// @ingroup AnalysisFunctionParameterHelpers
Function AFH_GetAnalysisParamNumerical(name, params)
	string name, params

	return NumberByKey(name + ":variable", params, "=", ",", 0)
End

/// @brief Return a textual user parameter
///
/// @param name   parameter name
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
/// @ingroup AnalysisFunctionParameterHelpers
Function/S AFH_GetAnalysisParamTextual(name, params)
	string name, params

	return StringByKey(name + ":string", params, "=", ",", 0)
End

/// @brief Return a numerical wave user parameter
///
/// @param name   parameter name
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
/// @ingroup AnalysisFunctionParameterHelpers
///
/// @return wave reference to free numeric wave, or invalid wave ref in case the
/// parameter could not be found.
Function/WAVE AFH_GetAnalysisParamWave(name, params)
	string name, params

	string contents = StringByKey(name + ":wave", params, "=", ",", 0)

	if(IsEmpty(contents))
		return $""
	endif

	return ListToNumericWave(contents, "|")
End

/// @brief Return a textual wave user parameter
///
/// @param name   parameter name
/// @param params serialized parameters, usually just #AnalysisFunction_V3.params
///
/// @ingroup AnalysisFunctionParameterHelpers
///
/// @return wave reference to free text wave, or invalid wave ref in case the
/// parameter could not be found.
Function/WAVE AFH_GetAnalysisParamTextWave(name, params)
	string name, params

	string contents = StringByKey(name + ":textwave", params, "=", ",", 0)

	if(IsEmpty(contents))
		return $""
	endif

	return ListToTextWave(contents, "|")
End
