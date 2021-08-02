#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict Wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_STAPI
#endif

/// @file MIES_StimsetAPI.ipf
/// @brief __ST__ Stimulus set API
/// @name Functions for manipulating stimulus sets

/// @defgroup StimsetAPIFunctions Stimset API
///
/// Code example:
/// \rst
/// .. literalinclude:: ../ipf/example-stimulus-set-api.ipf
///    :language: igor
///    :dedent:
///    :tab-width: 4
/// \endrst

///@cond HIDDEN_SYMBOL

static Function ST_UpgradeStimset(string setName)

	// upgrade all parameter waves
	// old stimsets then know about the new parameter names
	return WB_StimsetIsFromThirdParty(setName)
End

static Function/WAVE ST_GetStimsetParametersGlobal(string setName)

	variable numEntries

	WAVE SegWvType = WB_GetSegWvTypeForSet(setName)

	// SegWvType
	numEntries = DimSize(SegWvType, ROWS) - (SEGMENT_TYPE_WAVE_LAST_IDX + 1)
	Make/FREE/N=(numEntries)/T SegWvTypeNames = GetDimLabel(SegWvType, ROWS, SEGMENT_TYPE_WAVE_LAST_IDX + 1 + p)

	// SegWvType, only output one for Type of Epoch XX
	Make/FREE/T types = {"Type of Epoch XX"}

	// WPT
	// "Analysis function (generic)"
	// "Inter trial interval ldel"
	// "Analysis function params (encoded)" is not included as that is set via AFH_AddAnalysisParameter()
	Make/FREE/T WPTNames = {"Analysis function (generic)", "Inter trial interval ldel"}
	Concatenate/FREE/NP=(ROWS) {SegWvTypeNames, WPTNames, types}, all

	Sort/LOC all, all

	return all
End

static Function/WAVE ST_GetStimsetParametersEpochType(string setName, variable epochType)

	if(!IsInteger(epochType) || epochType < 0 || epochType >= EPOCH_TYPES_TOTAL_NUMBER)
		printf "The epoch type %g is invalid.\r", epochType
		ControlWindowToFront()
		return $""
	endif

	WAVE/T epochParameterNames = GetEpochParameterNames()

	Duplicate/FREE/T/RMD=[epochType][*] epochParameterNames, wv

	// remove empty elements from the end
	FindValue/TEXT=""/TXOP=4 wv
	Redimension/N=(V_Value >= 0 ? V_Value : numpnts(wv)) wv

	return wv
End

static Function [variable resultColumn, variable resultLayer] ST_GetResultWaveCoordinates(string setName, string entry, WAVE resultWave, variable epochIndex)
	variable numEpochs, epochType, idx

	WAVE SegWvType = WB_GetSegWvTypeForSet(setName)

	if(IsNaN(epochIndex))
		if(IsTextWave(resultWave))
			resultColumn = FindDimLabel(resultWave, COLS, "Set")
			resultLayer  = INDEP_EPOCH_TYPE
		elseif(IsNumericWave(resultWave))
			resultColumn = 0
			resultLayer  = 0
		endif
	else
		numEpochs = SegWvType[%$("Total number of epochs")]

		if(!IsInteger(epochIndex) || epochIndex >= numEpochs)
			printf "The epoch %d does not exist in the stimset as that only has %d epochs.\r", epochIndex, numEpochs
			ControlWindowToFront()
			return [NaN, NaN]
		endif

		epochType = SegWvType[epochIndex]
		WAVE/T/Z existingParams = ST_GetStimsetParametersEpochType(setName, epochType)

		if(!WaveExists(existingParams))
			// no such epoch type
			return [NaN, NaN]
		endif

		idx = GetRowIndex(existingParams, str = entry)
		if(IsNaN(idx))
			// epoch type does not have a parameter "entry"
			return [NaN, NaN]
		endif

		resultColumn = epochIndex
		resultLayer = epochType
	endif
End

static Function [WAVE wv, variable row, variable col, variable layer] ST_GetStimsetParameterWaveIndexTuple(string setName, string entry, variable epochIndex)
	ST_UpgradeStimset(setName)

	WAVE SegWvType = WB_GetSegWvTypeForSet(setName)

	row = FindDimLabel(SegWvType, ROWS, entry)

	if(row >= 0)
		[col, layer] = ST_GetResultWaveCoordinates(setName, entry, SegWvType, epochIndex)

		if(IsNaN(col) || IsNaN(layer))
			return [$"", NaN, NaN, NaN]
		endif

		return [SegWvType, row, col, layer]
	endif

	WAVE WP = WB_GetWaveParamForSet(setName)

	row = FindDimLabel(WP, ROWS, entry)

	if(row >= 0)
		[col, layer] = ST_GetResultWaveCoordinates(setName, entry, WP, epochIndex)

		if(IsNaN(col) || IsNaN(layer))
			return [$"", NaN, NaN, NaN]
		endif

		return [WP, row, col, layer]
	endif

	WAVE/T WPT = WB_GetWaveTextParamForSet(setName)

	row = FindDimLabel(WPT, ROWS, entry)

	if(row >= 0)
		[col, layer] = ST_GetResultWaveCoordinates(setName, entry, WPT, epochIndex)

		if(IsNaN(col) || IsNaN(layer))
			return [$"", NaN, NaN, NaN]
		endif

		return [WPT, row, col, layer]
	endif

	return [$"", NaN, NaN, NaN]
End

static Function/S ST_ParameterStringValues(string entry)
	// translate passed string values which are numeric internally
	//                                  WBP_GetDeltaModes() WBP_GetNoiseTypes()               WBP_GetNoiseBuildResolution() WBP_GetTriggerTypes()             WBP_GetPulseTypes()
	Make/FREE/T translateableEntries = {"^.* op$",          "Noise Type: White, Pink, Brown", "Build resolution (index)",   "Trigonometric function Sin/Cos", "Pulse train type (index)"}

	if(GrepString(entry, translateableEntries[0]))
		return WBP_GetDeltaModes()
	elseif(!cmpstr(entry, translateableEntries[1]))
		return  WBP_GetNoiseTypes()
	elseif(!cmpstr(entry, translateableEntries[2]))
		return  WBP_GetNoiseBuildResolution()
	elseif(!cmpstr(entry, translateableEntries[3]))
		return  WBP_GetTriggerTypes()
	elseif(!cmpstr(entry, translateableEntries[4]))
		return  WBP_GetPulseTypes()
	endif

	return ""
End

///@endcond // HIDDEN_SYMBOL

/// @brief Return a sorted list of all DA/TTL stim set waves
///
/// @param[in] channelType               [optional, defaults to all] #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
/// @param[in] searchString              [optional, defaults to "*"] search string in wildcard syntax
/// @param[out] WBstimSetList            [optional] returns the list of stim sets built with the wavebuilder
/// @param[out] thirdPartyStimSetList    [optional] returns the list of third party stim sets not built with the wavebuilder
///
/// @ingroup StimsetAPIFunctions
Function/S ST_GetStimsetList([variable channelType, string searchString, string &WBstimSetList, string &thirdPartyStimSetList])
	string listAll = ""
	string listInternal = ""
	string listThirdParty = ""
	string list
	variable i, numEntries

	if(ParamIsDefault(channelType))
		Make/FREE channelTypes = {CHANNEL_TYPE_DAC, CHANNEL_TYPE_TTL}
	else
		Make/FREE channelTypes = {channelType}
	endif

	if(ParamIsDefault(searchString))
		searchString = "*"
	endif

	if(!ParamIsDefault(WBstimSetList))
		WBstimSetList = ""
	endif

	if(!ParamIsDefault(thirdPartyStimSetList))
		thirdPartyStimSetList = ""
	endif

	numEntries = DimSize(channelTypes, ROWS)
	for(i = 0; i < numEntries; i += 1)
		channelType = channelTypes[i]

		// fetch stim sets created with the WaveBuilder
		DFREF dfr = GetSetParamFolder(channelTypes[i])

		list = GetListOfObjects(dfr, "WP_" + searchString, exprType = MATCH_WILDCARD)
		listInternal = RemovePrefixFromListItem("WP_", list)

		// fetch third party stim sets
		DFREF dfr = GetSetFolder(channelType)

		list = GetListOfObjects(dfr, searchString, exprType = MATCH_WILDCARD)

		// remove testpulse as it is not always present, and will be added later on
		list = RemoveFromList(STIMSET_TP_WHILE_DAQ, list, ";")

		listThirdParty = GetListDifference(list, listInternal)

		if(!ParamIsDefault(WBstimSetList))
			WBstimSetList += SortList(listInternal, ";", 16)
		endif

		if(!ParamIsDefault(thirdPartyStimSetList))
			thirdPartyStimSetList += SortList(listThirdParty, ";", 16)
		endif

		listAll += SortList(listInternal + listThirdParty, ";", 16)

		if(channelType == CHANNEL_TYPE_DAC && stringmatch(STIMSET_TP_WHILE_DAQ, searchString))
			listAll = AddListItem(STIMSET_TP_WHILE_DAQ, listAll, ";", 0)
		endif
	endfor

	return listAll
End

/// @brief Create a new empty stimset
///
/// @param baseName      user choosable part of the stimset name
/// @param stimulusType  one of #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
/// @param setNumber     [optional, defaults to 0] stimset number, allows for convenient alphabetic increasing names used in indexing
/// @param saveAsBuiltin [optional, defaults to false] allows to create builtin stimsets when enabled
///
/// @ingroup StimsetAPIFunctions
Function/S ST_CreateStimSet(string baseName, variable stimulusType, [variable setNumber, variable saveAsBuiltin])

	if(ParamIsDefault(setNumber))
		setNumber = 0
	else
		ASSERT(IsInteger(setNumber), "setNumber must be an integer")
	endif

	if(ParamIsDefault(saveAsBuiltin))
		saveAsBuiltin = 0
	else
		saveAsBuiltin = !!saveAsBuiltin
	endif

	WAVE WP        = GetWaveBuilderWaveParamAsFree()
	WAVE/T WPT     = GetWaveBuilderWaveTextParamAsFree()
	WAVE SegWvType = GetSegmentTypeWaveAsFree()

	return WB_SaveStimSet(baseName, stimulusType, SegWvType, WP, WPT, setNumber, saveAsBuiltin)
End

/// @brief Remove the given stimulus set and update all relevant GUIs
///
/// @ingroup StimsetAPIFunctions
Function ST_RemoveStimSet(string setName)
	variable i, numPanels, channelType
	string lockedDevices, panelTitle

	lockedDevices = GetListOfLockedDevices()
	if(IsEmpty(lockedDevices))
		DAP_DeleteStimulusSet(setName)
		return NaN
	endif

	numPanels = ItemsInList(lockedDevices)
	for(i = 0; i < numPanels; i += 1)
		panelTitle = StringFromList(i, lockedDevices)

		DAP_DeleteStimulusSet(setName, device = panelTitle)
	endfor
End

/// @brief Returns the available stimsets parameters
///
/// Return the epoch-independent parameters when epochType is not present.
///
/// @ingroup StimsetAPIFunctions
Function/WAVE ST_GetStimsetParameters(string setName, [variable epochType])

	if(ST_UpgradeStimset(setName))
		printf "The stimset %s does not exist or is a third-party stimset.\r", setName
		ControlWindowToFront()
		return $""
	endif

	if(ParamIsDefault(epochType))
		return ST_GetStimsetParametersGlobal(setName)
	else
		return ST_GetStimsetParametersEpochType(setName, epochType)
	endif
End

/// @brief Return the given stimset numeric parameter
///
/// @param setName    name of the stimset
/// @param entry      name of the parameter, can be global or epoch
/// @param epochIndex [optional, when not given this sets global parameters] epoch index (0-based)
///
/// @ingroup StimsetAPIFunctions
Function ST_GetStimsetParameterAsVariable(string setName, string entry, [variable epochIndex])
	variable row, col, layer

	if(ParamIsDefault(epochIndex))
		epochIndex = NaN
	endif

	if(ST_UpgradeStimset(setName))
		printf "The stimset %s does not exist\r." setName
		ControlwindowToFront()
		return NaN
	endif

	WAVE/Z wv
	[wv, row, col, layer] = ST_GetStimsetParameterWaveIndexTuple(setName, entry, epochIndex)

	if(WaveExists(wv) && IsNumericWave(wv))
		return wv[row][col][layer]
	endif

	return NaN
End

/// @brief Return the given stimset string parameter
///
/// @param setName    name of the stimset
/// @param entry      name of the parameter, can be global or epoch
/// @param epochIndex [optional, when not given this sets global parameters] epoch index (0-based)
///
/// @ingroup StimsetAPIFunctions
Function/S ST_GetStimsetParameterAsString(string setName, string entry, [variable epochIndex])
	variable row, col, layer
	string entryStringValues

	if(ParamIsDefault(epochIndex))
		epochIndex = NaN
	endif

	if(ST_UpgradeStimset(setName))
		printf "The stimset %s does not exist\r." setName
		ControlwindowToFront()
		return ""
	endif

	WAVE/Z wv
	[wv, row, col, layer] = ST_GetStimsetParameterWaveIndexTuple(setName, entry, epochIndex)

	WAVE/T/Z wvText = wv

	if(WaveExists(wvText))
		if(IsTextWave(wvText))
			return wvText[row][col][layer]
		else
			entryStringValues = ST_ParameterStringValues(entry)

			if(!IsEmpty(entryStringValues))
				return StringFromList(wv[row][col][layer], entryStringValues)
			endif
		endif
	endif

	return ""
End

/// @brief Set the given stimset parameter
///
/// If you use this function in analysis functions be sure to use an event which happens *before* the stimset is read,
/// for example `PRE_DAQ_EVENT`, `PRE_SET_EVENT` or `PRE_SWEEP_CONFIG_EVENT`. The last one is always called for each
/// sweep before it is configured.
///
/// @param setName    name of the stimset
/// @param entry      name of the parameter, can be global or epoch
/// @param epochIndex [optional, when not given this sets global parameters] epoch index (0-based)
/// @param var        [optional, one of `var`/`str` must be present] numeric parameter to set
/// @param str        [optional, one of `var`/`str` must be present] string parameter to set
///
/// @return 0 on success, 1 on error
///
/// @ingroup StimsetAPIFunctions
Function ST_SetStimsetParameter(string setName, string entry, [variable epochIndex, variable var, string str])
	variable numEpochs, epochType, row, col, layer, stimulusType
	variable strIsGiven, varIsGiven
	string entryStringValues

	if(ParamIsDefault(epochIndex))
		epochIndex = NaN
	endif

	strIsGiven = !ParamIsDefault(str)
	varIsGiven = !ParamIsDefault(var)

	if((varIsGiven + strIsGiven) != 1)
		printf "Only one of var and str must be given.\r"
		ControlWindowToFront()
		return 1
	endif

	if(ST_UpgradeStimset(setName))
		printf "The stimset %s does not exist\r." setName
		ControlwindowToFront()
		return 1
	endif

	WAVE/Z wv
	[wv, row, col, layer] = ST_GetStimsetParameterWaveIndexTuple(setName, entry, epochIndex)

	if(!WaveExists(wv))
		return 1
	endif

	if(IsTextWave(wv))
		if(varIsGiven)
			printf "The parameter %s is a string entry, but \"var\" was supplied.\r", entry
			ControlWindowToFront()
			return 1
		endif

		if(IsNaN(epochIndex) && !cmpstr("Analysis function (generic)", entry))
			ASSERT(GrepString(NameOfWave(wv), "^WPT_.*"), "Unexpected wave name")
			stimulusType = GetStimSetType(setName)
			return WB_SetAnalysisFunctionGeneric(stimulusType, str, wv)
		endif

		Wave/T wvText = wv
		wvText[row][col][layer] = str
	elseif(IsNumericWave(wv))
		if(strIsGiven)
			entryStringValues = ST_ParameterStringValues(entry)

			if(!IsEmpty(entryStringValues))
				strIsGiven = 0
				varIsGiven = 1

				var = WhichListItem(str, entryStringValues)
				if(var < 0)
					printf "The parameter %s could not be found.\r", entry
					ControlWindowToFront()
					return 1
				endif

				// invalidate it
				str= ""
			endif
		endif

		if(strIsGiven)
			printf "The parameter %s is a numeric entry, but \"str\" was supplied.\r", entry
			ControlWindowToFront()
			return 1
		endif

		wv[row][col][layer] = var
	else
		ASSERT(0, "Unexpected wave type")
	endif

	return 0
End
