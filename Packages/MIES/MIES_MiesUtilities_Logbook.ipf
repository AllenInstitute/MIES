#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MIESUTILS_LOGBOOK
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_Logbook.ipf
/// @brief This file holds MIES utility functions for working with the various Logbooks.

static Constant GET_LB_MODE_NONE  = 0
static Constant GET_LB_MODE_READ  = 1
static Constant GET_LB_MODE_WRITE = 2

static StrConstant LBN_UNASSOC_REGEXP_LEGACY = "^(.*) UNASSOC_[[:digit:]]+$"
static StrConstant LBN_UNASSOC_REGEXP        = "^(.*) u_(AD|DA)[[:digit:]]+$"

static StrConstant PSQ_PB_LBN_PREFIX = "Pipette in Bath"
static StrConstant PSQ_CR_LBN_PREFIX = "Chirp"
static StrConstant PSQ_SP_LBN_PREFIX = "Squ. Pul."
static StrConstant PSQ_DS_LBN_PREFIX = "DA Scale"
static StrConstant PSQ_RB_LBN_PREFIX = "Rheobase"
static StrConstant PSQ_RA_LBN_PREFIX = "Ramp"
static StrConstant PSQ_SE_LBN_PREFIX = "Seal evaluation"
static StrConstant PSQ_VM_LBN_PREFIX = "True Rest Memb."
static StrConstant PSQ_AR_LBN_PREFIX = "Access Res. Smoke"

static StrConstant MSQ_FRE_LBN_PREFIX = "F Rheo E"
static StrConstant MSQ_DS_LBN_PREFIX  = "Da Scale"
static StrConstant MSQ_SC_LBN_PREFIX  = "Spike Control"

/// @brief Return the logbook type, one of @ref LogbookTypes
Function GetLogbookType(WAVE wv)

	string name

	name = NameOfWave(wv)

	if(GrepString(name, TP_STORAGE_REGEXP))
		return LBT_TPSTORAGE
	elseif(GrepString(name, "(?i)(numerical|textual)(Keys|Values)"))
		return LBT_LABNOTEBOOK
	elseif(GrepString(name, "(?i)(numerical|textual)Results(Keys|Values)"))
		return LBT_RESULTS
	endif

	FATAL_ERROR("Unrecognized wave: " + name)
End

/// @brief Return the logbook waves
///
/// @param device          [optional only for LBT_RESULTS] device
/// @param logbookType     one of @ref LogbookTypes
/// @param logbookWaveType one of @ref LabnotebookWaveTypes
Function/WAVE GetLogbookWaves(variable logbookType, variable logbookWaveType, [string device])

	switch(logbookType)
		case LBT_TPSTORAGE:
			ASSERT(logbookWaveType == LBN_NUMERICAL_VALUES, "Invalid logbookDataType")
			ASSERT(!ParamIsDefault(device), "Invalid device parameter")

			return GetTPStorage(device)
		case LBT_LABNOTEBOOK:
			ASSERT(!ParamIsDefault(device), "Invalid device parameter")

			switch(logbookWaveType)
				case LBN_NUMERICAL_KEYS:
					FUNCREF DAQ_LBN_GETTER_PROTO func = GetLBNumericalKeys
					break
				case LBN_NUMERICAL_VALUES:
					FUNCREF DAQ_LBN_GETTER_PROTO func = GetLBNumericalValues
					break
				case LBN_TEXTUAL_KEYS:
					FUNCREF DAQ_LBN_GETTER_PROTO func = GetLBTextualKeys
					break
				case LBN_TEXTUAL_VALUES:
					FUNCREF DAQ_LBN_GETTER_PROTO func = GetLBTextualValues
					break
				default:
					FATAL_ERROR("Invalid type")
			endswitch

			return func(device)
		case LBT_RESULTS:
			// ignore device parameter to ease call sites

			switch(logbookWaveType)
				case LBN_NUMERICAL_KEYS:
					return GetNumericalResultsKeys()
				case LBN_NUMERICAL_VALUES:
					return GetNumericalResultsValues()
				case LBN_TEXTUAL_KEYS:
					return GetTextualResultsKeys()
				case LBN_TEXTUAL_VALUES:
					return GetTextualResultsValues()
				default:
					FATAL_ERROR("Invalid type")
			endswitch
			break
		default:
			FATAL_ERROR("Invalid logbook type")
	endswitch
End

/// @brief Extract a date/time slice of the logbook wave
Function/WAVE ExtractLogbookSliceTimeStamp(WAVE logbook)

	variable colOrLayer, logbookType

	logbookType = GetLogbookType(logbook)

	switch(logbookType)
		case LBT_LABNOTEBOOK: // fallthrough
		case LBT_RESULTS:
			colOrLayer = 1
			break
		case LBT_TPSTORAGE:
			colOrLayer = FindDimLabel(logbook, LAYERS, "TimeStampSinceIgorEpochUTC")
			break
		default:
			FATAL_ERROR("Invalid logbook type")
	endswitch

	return ExtractLogbookSlice(logbook, logbookType, colOrLayer, "Dat")
End

/// @brief Extract the delta time slice of the logbook wave
Function/WAVE ExtractLogbookSliceDeltaTime(WAVE logbook)

	variable colOrLayer, logbookType

	logbookType = GetLogbookType(logbook)

	switch(logbookType)
		case LBT_LABNOTEBOOK: // fallthrough
		case LBT_RESULTS:
			FATAL_ERROR("Unsupported")
			break
		case LBT_TPSTORAGE:
			colOrLayer = FindDimLabel(logbook, LAYERS, "DeltaTime")
			break
		default:
			FATAL_ERROR("Invalid logbook type")
	endswitch

	return ExtractLogbookSlice(logbook, logbookType, colOrLayer, "DeltaTime")
End

/// @brief Extract the sweep number slice of the labnotebook values wave
Function/WAVE ExtractLogbookSliceSweep(WAVE values)

	return ExtractLogbookSlice(values, GetLogbookType(values), 0, "Sweep")
End

/// @brief Extract a slice of the logbook wave and makes it empty
Function/WAVE ExtractLogbookSliceEmpty(WAVE values)

	WAVE wv = ExtractLogbookSlice(values, GetLogbookType(values), 0, "Null")
	wv = 0

	return wv
End

/// @brief Extract a single column/layer of the labnotebook/TPStorage values wave
///
/// This is useful if you want to plot values against e.g time and let
/// Igor do the formatting of the date/time values.
/// Always returns a numerical wave.
///
/// The slice is returned as-is if it exists already. Callers which modify the
/// logbook are responsible to resize the slice as well.
static Function/WAVE ExtractLogbookSlice(WAVE logbook, variable logbookType, variable colOrLayer, string suffix)

	string name, entryName
	variable col, layer

	// we can't use the GetDevSpecLabNBTempFolder getter as we are
	// called from the analysisbrowser as well.
	DFREF dfr = createDFWithAllParents(GetWavesDataFolder(logbook, 1) + "Temp")

	name = NameOfWave(logbook) + CleanupName(suffix, 0)
	WAVE/Z/SDFR=dfr slice = $name

	if(WaveExists(slice))
		return slice
	endif

	switch(logbookType)
		case LBT_LABNOTEBOOK: // fallthrough
		case LBT_RESULTS:
			entryName = GetDimLabel(logbook, COLS, colOrLayer)
			col       = colOrLayer
			layer     = -1
			break
		case LBT_TPSTORAGE:
			entryName = GetDimLabel(logbook, LAYERS, colOrLayer)
			col       = -1
			layer     = colOrLayer
			break
		default:
			FATAL_ERROR("Invalid logbook type")
	endswitch

	Duplicate/O/R=[0, DimSize(logbook, ROWS)][col][layer][-1] logbook, dfr:$name/WAVE=slice

	// we want to have a pure 1D wave without any columns or layers, this is currently not possible with Duplicate
	Redimension/N=-1 slice

	Note/K slice

	if(!cmpstr(entryName, "TimeStamp") || !cmpstr(entryName, "TimeStampSinceIgorEpochUTC"))
		SetScale d, 0, 0, "dat", slice
	endif

	ASSERT(!isEmpty(entryName), "entryName must not be empty")
	SetDimLabel ROWS, -1, $entryName, slice

	if(IsTextWave(slice))
		WAVE/T sliceFree = MakeWaveFree(slice)
		Make/O/D/N=(DimSize(sliceFree, ROWS), DimSize(sliceFree, COLS), DimSize(sliceFree, LAYERS), DimSize(sliceFree, CHUNKS)) dfr:$name/WAVE=sliceFromText
		CopyScales sliceFree, sliceFromText
		sliceFromText = str2num(sliceFree)
		return sliceFromText
	endif

	return slice
End

/// @defgroup LabnotebookQueryFunctions Labnotebook Query Functions
///
/// The labnotebook querying functions can be categorized into the following categories:
///
/// Return the stored settings of a *single* sweep. The functions return a
/// wave with #LABNOTEBOOK_LAYER_COUNT rows, where the first #NUM_HEADSTAGES
/// hold headstage dependent data and the row returned by GetIndexForHeadstageIndepData()
/// the headstage independent data.
/// - GetLastSetting()
///
/// Return the *headstage independent* data of a single sweep. Trimmed down
/// a special default value in case the setting could not be found.
/// - GetLastSettingIndep()
/// - GetLastSettingTextIndep()
///
/// If you want to query the information on a per-channel basis the following
/// functions are helpful. They also take care of unassociated channels
/// automatically.
/// - GetLastSettingChannel()
///
/// Return the data of *one* of the sweeps of a repeated acquistion cycle
/// (RAC). The functions return only the *first* valid setting searching the
/// sweeps from the end to the begin of the RAC.
/// - GetLastSettingTextRAC()
/// - GetLastSettingTextIndepRAC()
/// - GetLastSettingIndepRAC()
/// - GetLastSettingRAC()
///
/// Return the data of *all* sweeps of a repeated acquistion cycle (RAC) with the following functions:
/// - GetLastSettingTextEachRAC()
/// - GetLastSettingTextIndepEachRAC()
/// - GetLastSettingIndepEachRAC()
/// - GetLastSettingEachRAC()
///
/// All the above functions are concerned with querying data from the
/// labnotebook where the sweep number is known. In case you are looking for
/// data from an arbitrary sweep use one of the following functions:
/// - GetLastSweepWithSetting()
/// - GetLastSweepWithSettingText()
/// - GetLastSweepWithSettingTextI()
/// - GetLastSweepWithSettingIndep()
/// - GetSweepsWithSetting()

/// @brief Return a headstage independent setting from the numerical labnotebook
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function GetLastSettingIndep(WAVE numericalValues, variable sweepNo, string setting, variable entrySourceType, [variable defValue])

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, setting, entrySourceType)

	if(WaveExists(settings))
		EnforceIndependentSetting(settings)
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	endif

	return defValue
End

/// @brief Return a headstage independent setting from the textual labnotebook
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/S GetLastSettingTextIndep(WAVE/T textualValues, variable sweepNo, string setting, variable entrySourceType, [string defValue])

	ASSERT_TS(IsTextWave(textualValues), "Can only work with text waves")

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/Z/T settings = GetLastSetting(textualValues, sweepNo, setting, entrySourceType)

	if(WaveExists(settings))
		EnforceIndependentSetting(settings)
		return settings[GetIndexForHeadstageIndepData(textualValues)]
	endif

	return defValue
End

/// @brief Return a headstage independent setting from the numerical
///        labnotebook of the sweeps in the same RA cycle
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function GetLastSettingIndepRAC(WAVE numericalValues, variable sweepNo, string setting, variable entrySourceType, [variable defValue])

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z settings = GetLastSettingRAC(numericalValues, sweepNo, setting, entrySourceType)

	if(WaveExists(settings))
		EnforceIndependentSetting(settings)
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	endif

	return defValue
End

/// @brief Return a headstage independent setting from the numerical
///        labnotebook of the sweeps in the same SCI cycle
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function GetLastSettingIndepSCI(WAVE numericalValues, variable sweepNo, string setting, variable headstage, variable entrySourceType, [variable defValue])

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z settings = GetLastSettingSCI(numericalValues, sweepNo, setting, headstage, entrySourceType)

	if(WaveExists(settings))
		EnforceIndependentSetting(settings)
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	endif

	return defValue
End

/// @brief Return a headstage independent setting from the textual
///        labnotebook of the sweeps in the same SCI cycle
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/S GetLastSettingTextIndepSCI(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, string setting, variable headstage, variable entrySourceType, [string defValue])

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/Z/T settings = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, setting, headstage, entrySourceType)

	if(WaveExists(settings))
		EnforceIndependentSetting(settings)
		return settings[GetIndexForHeadstageIndepData(textualValues)]
	endif

	return defValue
End

/// @brief Return a headstage independent setting from the numerical
///        labnotebook of the sweeps in the same RA cycle
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
threadsafe Function/S GetLastSettingTextIndepRAC(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, string setting, variable entrySourceType, [string defValue])

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/Z/T settings = GetLastSettingTextRAC(numericalValues, textualValues, sweepNo, setting, entrySourceType)

	if(WaveExists(settings))
		EnforceIndependentSetting(settings)
		return settings[GetIndexForHeadstageIndepData(textualValues)]
	endif

	return defValue
End

/// @brief Return a numerical or text setting for the given channel
///
/// It also returns headstage independent entries when the given channel refers to an active channel.
///
/// @return the wave containing the setting and the index into it.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSettingChannelInternal()
threadsafe Function [WAVE/Z settings, variable index] GetLastSettingChannel(WAVE numericalValues, WAVE/Z/T textualValues, variable sweepNo, string setting, variable channelNumber, variable channelType, variable entrySourceType)

	[settings, index] = GetLastSettingChannelInternal(numericalValues, numericalValues, sweepNo, setting, channelNumber, channelType, entrySourceType)

	if(WaveExists(settings))
		return [settings, index]
	endif

	if(!WaveExists(textualValues))
		return [$"", NaN]
	endif

	[settings, index] = GetLastSettingChannelInternal(numericalValues, textualValues, sweepNo, setting, channelNumber, channelType, entrySourceType)

	if(WaveExists(settings))
		return [settings, index]
	endif

	return [$"", NaN]
End

/// @brief Return a numerical/textual setting for the given channel
///
/// The function takes care of associated/unassociated channel properties and
/// all other internals.
///
/// @param numericalValues numerical labnotebook
/// @param values          labnotebook to read data from, either numerical or textual
/// @param sweepNo         sweep number
/// @param setting         name of the labnotebook entry to search
/// @param channelNumber   channel number
/// @param channelType     channel type, one of @ref XopChannelConstants
/// @param entrySourceType type of the labnotebook entry, one of @ref DataAcqModes.
///                        If you don't care about the entry source type pass #UNKNOWN_MODE.
///
/// @return A tuple of the result wave and the index into it.
///
/// @sa GetLastSettingChannel
threadsafe static Function [WAVE/Z wv, variable index] GetLastSettingChannelInternal(WAVE numericalValues, WAVE values, variable sweepNo, string setting, variable channelNumber, variable channelType, variable entrySourceType)

	string entryName, settingTTL
	variable headstage, indep

	switch(channelType)
		case XOP_CHANNEL_TYPE_DAC:
			entryName = "DAC"
			break
		case XOP_CHANNEL_TYPE_ADC:
			entryName = "ADC"
			break
		case XOP_CHANNEL_TYPE_TTL:
			settingTTL = CreateTTLChannelLBNKey(setting, channelNumber)
			WAVE/Z settings = GetLastSetting(values, sweepNo, settingTTL, entrySourceType)
			if(WaveExists(settings))
				return [settings, INDEP_HEADSTAGE]
			endif

			WAVE/Z settings = GetLastSetting(values, sweepNo, setting, entrySourceType)
			if(WaveExists(settings))
				return [settings, INDEP_HEADSTAGE]
			endif

			return [$"", NaN]

			break
		default:
			FATAL_ERROR("Unsupported channelType")
	endswitch

	WAVE/Z activeChannels = GetLastSetting(numericalValues, sweepNo, entryName, entrySourceType)

	if(WaveExists(activeChannels))
		headstage = GetRowIndex(activeChannels, val = channelNumber)

		if(IsAssociatedChannel(headstage))

			WAVE/Z settings = GetLastSetting(values, sweepNo, setting, entrySourceType)

			if(!WaveExists(settings))
				// but the setting does not exist
				return [$"", NaN]
			endif

			indep = GetIndexForHeadstageIndepData(values)

			WAVE/T settingsT = settings
			if(IsNumericWave(settings))
				if(!IsNaN(settings[headstage]))
					// numerical assoc setting
					return [settings, headstage]
				elseif(!IsNaN(settings[indep]))
					// ... unassoc ...
					return [settings, indep]
				endif

				// happens with querying associated entries
				// which are only set for other headstages
				// e.g. DA0, DA1 is active and only DA0 has an entry,
				// then for DA1 settings[headstage] == NaN,
				// but settings exist because for DA0 settings[headstage] != NaN
			elseif(IsTextWave(settingsT))
				if(cmpstr(settingsT[headstage], ""))
					// textual assoc setting
					return [settingsT, headstage]
				elseif(cmpstr(settingsT[indep], ""))
					// ... unassoc ...
					return [settingsT, indep]
				endif

				// same as above
			else
				FATAL_ERROR("Invalid wave type")
			endif
		endif
	endif

	// new style unassociated entry
	WAVE/Z settings = GetLastSetting(values, sweepNo,                                          \
	                                 CreateLBNUnassocKey(setting, channelNumber, channelType), \
	                                 entrySourceType)

	if(WaveExists(settings))
		return [settings, GetIndexForHeadstageIndepData(values)]
	endif

	// old style unassociated entry
	WAVE/Z settings = GetLastSetting(values, sweepNo,                                  \
	                                 CreateLBNUnassocKey(setting, channelNumber, NaN), \
	                                 entrySourceType)

	if(WaveExists(settings))
		return [settings, GetIndexForHeadstageIndepData(values)]
	endif

	return [$"", NaN]
End

threadsafe static Function GetLogbookSettingsColumn(WAVE values, string key)

	[WAVE/T sortedKeys, WAVE indices] = GetLogbookSortedKeys(values)

	return GetLogbookSettingsColumnFromSorted(sortedKeys, indices, key)
End

threadsafe static Function GetLogbookSettingsColumnFromSorted(WAVE/T sortedKeys, WAVE indices, string key)

	variable index = BinarySearchText(sortedKeys, key)
	return IsNaN(index) ? -2 : indices[index]
End

/// @brief Return a numeric/textual wave with the latest value of a setting
///        from the numerical/labnotebook labnotebook for the given sweep number.
///
/// @param values          numerical/textual labnotebook
/// @param sweepNo         sweep number
/// @param setting         name of the setting to query
/// @param entrySourceType type of the labnotebook entry, one of @ref DataAcqModes.
///                        If you don't care about the entry source type pass #UNKNOWN_MODE.
///
/// @return a free wave with #LABNOTEBOOK_LAYER_COUNT rows. In case
/// the setting could not be found an invalid wave reference is returned.
///
/// @ingroup LabnotebookQueryFunctions
threadsafe Function/WAVE GetLastSetting(WAVE values, variable sweepNo, string setting, variable entrySourceType)

	variable first, last, rowIndex, entrySourceTypeIndex, settingCol

	// entries before the first sweep have sweepNo == NaN
	// we can't cache that
	if(!IsValidSweepNumber(sweepNo) && !IsNaN(sweepNo))
		return $""
	endif

	settingCol = GetLogbookSettingsColumn(values, setting)
	if(settingCol < 0)
		return $""
	endif
	if(IsNaN(sweepNo))
		return GetLastSettingNoCache(values, sweepNo, setting, entrySourceType, settingCol = settingCol)
	endif

	entrySourceTypeIndex = EntrySourceTypeMapper(entrySourceType)

	if(entrySourceTypeIndex >= NUMBER_OF_LBN_DAQ_MODES)
		return $""
	endif

	WAVE indexWave = GetLBIndexCache(values)

	EnsureLargeEnoughWave(indexWave, indexShouldExist = sweepNo, dimension = ROWS, initialValue = LABNOTEBOOK_UNCACHED_VALUE)
	EnsureLargeEnoughWave(indexWave, indexShouldExist = settingCol, dimension = COLS, initialValue = LABNOTEBOOK_UNCACHED_VALUE)
	rowIndex = indexWave[sweepNo][settingCol][entrySourceTypeIndex]

	if(rowIndex >= 0) // entry available and present
		if(IsTextWave(values))
			WAVE/T valuesText = values
			Make/T/FREE/N=(DimSize(values, LAYERS)) statusText = valuesText[rowIndex][settingCol][p]
			return statusText
		endif

		Make/D/FREE/N=(DimSize(values, LAYERS)) status = values[rowIndex][settingCol][p]
		return status
	elseif(rowIndex == LABNOTEBOOK_UNCACHED_VALUE)
		// need to search for it
		WAVE rowCache = GetLBRowCache(values)
		EnsureLargeEnoughWave(rowCache, indexShouldExist = sweepNo, dimension = ROWS, initialValue = LABNOTEBOOK_GET_RANGE)

		first = rowCache[sweepNo][%first][entrySourceTypeIndex]
		last  = rowCache[sweepNo][%last][entrySourceTypeIndex]

		WAVE/Z settings = GetLastSettingNoCache(values, sweepNo, setting, entrySourceType,                              \
		                                        first = first, last = last, rowIndex = rowIndex, settingCol = settingCol)

		if(WaveExists(settings))
			ASSERT_TS(first >= 0 && last >= 0 && rowIndex >= 0, "invalid return combination from GetLastSettingNoCache")
			rowCache[sweepNo][%first][entrySourceTypeIndex] = first
			rowCache[sweepNo][%last][entrySourceTypeIndex]  = last

			indexWave[sweepNo][settingCol][entrySourceTypeIndex] = rowIndex
		else
			ASSERT_TS(first < 0 || last < 0 || rowIndex < 0, "invalid return combination from GetLastSettingNoCache")
			indexWave[sweepNo][settingCol][entrySourceTypeIndex] = LABNOTEBOOK_MISSING_VALUE
		endif

		return settings
	elseif(rowIndex == LABNOTEBOOK_MISSING_VALUE)
		return $""
	endif

	FATAL_ERROR("Unexpected type")
End

/// @brief Return a wave with the latest value of a setting from the
///        numerical/textual labnotebook for the given sweep number.
///        Uncached version, general users should prefer GetLastSetting().
///
/// @param values          numerical/textual labnotebook
/// @param sweepNo         sweep number
/// @param setting         name of the setting to query
/// @param entrySourceType type of the labnotebook entry, one of @ref DataAcqModes
/// @param[in, out] first  [optional] Can be used to query and return the labnotebook row range. Useful for routines which must make a
///                        lot of queries to the same sweep and want to avoid the overhead of calculating `first` and `last`.
///                        Passing #LABNOTEBOOK_GET_RANGE will set the calculated values of `first` and `last` after the function returns.
///                        Passing a value greater or equal zero will use these values instead.
/// @param[in, out] last   [optional] see `first`
/// @param[out] rowIndex   [optional] return the row where the setting could be
///                        found, otherwise it is set to #LABNOTEBOOK_MISSING_VALUE
/// @param settingCol      [optional, default: determined by function] if the caller has already determined the setting column, it can set this argument
///                        then GetLastSettingNoCache saves the find
///
/// @return a free wave with #LABNOTEBOOK_LAYER_COUNT rows. In case
/// the setting could not be found an invalid wave reference is returned.
///
/// @ingroup LabnotebookQueryFunctions
threadsafe Function/WAVE GetLastSettingNoCache(WAVE values, variable sweepNo, string setting, variable entrySourceType, [variable &first, variable &last, variable &rowIndex, variable settingCol])

	variable numLayers, i, sweepCol, numEntries
	variable firstValue, lastValue, sourceTypeCol, peakResistanceCol, pulseDurationCol
	variable testpulseBlockLength, blockType, hasValidTPPulseDurationEntry
	variable mode, sweepNoInLNB

	if(!ParamIsDefault(rowIndex))
		rowIndex = LABNOTEBOOK_MISSING_VALUE
	endif

	if(ParamIsDefault(first) && ParamIsDefault(last))
		mode = GET_LB_MODE_NONE
	elseif(!ParamIsDefault(first) && !ParamIsDefault(last))
		if(first == LABNOTEBOOK_GET_RANGE && last == LABNOTEBOOK_GET_RANGE)
			mode = GET_LB_MODE_WRITE
		elseif(first >= 0 && last >= 0)
			mode = GET_LB_MODE_READ
		else
			FATAL_ERROR("Invalid params")
		endif
	else
		FATAL_ERROR("Invalid params")
	endif

	settingCol = ParamIsDefault(settingCol) ? FindDimLabel(values, COLS, setting) : settingCol
	if(settingCol <= 0)
		return $""
	endif

	numLayers = DimSize(values, LAYERS)
	sweepCol  = GetSweepColumn(values)
	if(mode == GET_LB_MODE_NONE || mode == GET_LB_MODE_WRITE)
		FindRange(values, sweepCol, sweepNo, entrySourceType, firstValue, lastValue)

		if(!IsFinite(firstValue) && !IsFinite(lastValue)) // sweep number is unknown
			return $""
		endif
	elseif(mode == GET_LB_MODE_READ)
		firstValue = first
		lastValue  = last
	endif

	ASSERT_TS(firstValue <= lastValue, "Invalid value range")

	if(mode == GET_LB_MODE_WRITE)
		first = firstValue
		last  = lastValue
	endif

	if(IsTextWave(values))
		WAVE/T textualValues = values
		Make/FREE/N=(numLayers)/T statusText
		Make/FREE/N=(numLayers) lengths

		for(i = lastValue; i >= firstValue; i -= 1)

			sweepNoInLNB = str2num(textualValues[i][sweepCol][0])
			if(!IsNaN(sweepNoInLNB) && sweepNoInLNB != sweepNo)
				continue
			endif

			if(IsFinite(entrySourceType))
				if(!sourceTypeCol)
					sourceTypeCol = FindDimLabel(textualValues, COLS, "EntrySourceType")
				endif

				if(sourceTypeCol < 0 || !IsFinite(str2num(textualValues[i][sourceTypeCol][0])))
					// before the sourceType entries we never had any testpulse
					// entries in the textualValues labnotebook wave
					if(entrySourceType == TEST_PULSE_MODE)
						return $""
					endif
				elseif(entrySourceType != str2num(textualValues[i][sourceTypeCol][0]))
					// labnotebook has entrySourceType and it is not matching
					DEBUGPRINT_TS("Skipping the given row as sourceType is available and not matching: ", var = i)
					continue
				endif
			endif

			AssertOnAndClearRTError()
			statusText[] = textualValues[i][settingCol][p]; AbortOnRTE

			lengths[] = strlen(statusTexT[p])

			// return if we have at least one non-empty entry
			if(Sum(lengths) > 0)
				if(!ParamIsDefault(rowIndex))
					rowIndex = i
				endif

				return statusText
			endif
		endfor
	else
		WAVE numericalValues = values
		Make/D/FREE/N=(numLayers) status

		for(i = lastValue; i >= firstValue; i -= 1)

			if(!IsNaN(sweepNo) && numericalValues[i][sweepCol][0] != sweepNo)
				continue
			endif

			if(IsFinite(entrySourceType))
				if(!sourceTypeCol)
					sourceTypeCol = FindDimLabel(numericalValues, COLS, "EntrySourceType")
				endif

				if(sourceTypeCol < 0 || !IsFinite(numericalValues[i][sourceTypeCol][0]))
					// no source type information available but it is requested
					// use a heuristic
					//
					// Since 666d761a (TP documenting is implemented using David
					// Reid's documenting functions, 2014-07-28) we have one
					// row for the testpulse which holds "TP Peak Resistance".
					// Since 4f4649a2 (Document the testpulse settings in the
					// labnotebook, 2015-07-28) we have two rows; starting with
					// "TP Peak Resistance" and ending with "TP Pulse Duration".
					if(!pulseDurationCol)
						pulseDurationCol = FindDimLabel(numericalValues, COLS, "TP Pulse Duration")
					endif

					if(!peakResistanceCol)
						peakResistanceCol = FindDimLabel(numericalValues, COLS, "TP Peak Resistance")
					endif

					blockType = UNKNOWN_MODE

					if(pulseDurationCol > 0)
						status[]                     = numericalValues[i][pulseDurationCol][p]
						hasValidTPPulseDurationEntry = HasOneValidEntry(status)
					else
						hasValidTPPulseDurationEntry = 0
					endif

					// Since 4f4649a2 (Document the testpulse settings in the
					// labnotebook, 2015-07-28) we can have a "TP Pulse Duration"
					// entry but no "TP Peak Resistance" entry iff the user only
					// acquired sweep data but never TP.
					if(peakResistanceCol < 0)
						blockType = DATA_ACQUISITION_MODE
					elseif(hasValidTPPulseDurationEntry)
						// if the previous row has a "TP Peak Resistance" entry we know that this is a testpulse block
						status[] = numericalValues[i - 1][peakResistanceCol][p]
						if(HasOneValidEntry(status))
							blockType            = TEST_PULSE_MODE
							testpulseBlockLength = 1
						else
							blockType = DATA_ACQUISITION_MODE
						endif
					else // no match, maybe old format
						status[] = numericalValues[i][peakResistanceCol][p]
						if(HasOneValidEntry(status))
							blockType            = TEST_PULSE_MODE
							testpulseBlockLength = 0
						else
							blockType = DATA_ACQUISITION_MODE
						endif
					endif

					if(entrySourceType == DATA_ACQUISITION_MODE && blockType == TEST_PULSE_MODE)
						// testpulse block starts but DAQ was requested
						// two row long testpulse block, skip it
						i -= testpulseBlockLength
						DEBUGPRINT_TS("Skipping the testpulse block as DAQ is requested, testpulseBlockLength:", var = testPulseBlockLength)
						continue
					elseif(entrySourceType == TEST_PULSE_MODE && blockType == DATA_ACQUISITION_MODE)
						// sweep block starts but TP was requested
						// as the sweep block occupies always the first blocks
						// we now know that we did not find the entries
						DEBUGPRINT_TS("Skipping the DAQ block as testpulse is requested, as this is the last block, we can also return.")
						return $""
					endif
				elseif(entrySourceType != numericalValues[i][sourceTypeCol][0])
					// labnotebook has entrySourceType and it is not matching
					DEBUGPRINT_TS("Skipping the given row as sourceType is available and not matching: ", var = i)
					continue
				endif
			endif

			AssertOnAndClearRTError()
			status[] = numericalValues[i][settingCol][p]; AbortOnRTE

			if(HasOneValidEntry(status))
				if(!ParamIsDefault(rowIndex))
					rowIndex = i
				endif

				return status
			endif
		endfor
	endif

	return $""
End

/// @brief Return the last textual value of the sweeps in the same RA cycle
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingTextRAC(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, string setting, variable entrySourceType)

	variable i, numSweeps

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	for(i = numSweeps - 1; i >= 0; i -= 1)
		WAVE/Z settings = GetLastSetting(textualValues, sweeps[i], setting, entrySourceType)

		if(WaveExists(settings))
			return settings
		endif
	endfor

	return $""
End

/// @brief Return the last numerical value of the sweeps in the same RA cycle
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingRAC(WAVE numericalValues, variable sweepNo, string setting, variable entrySourceType)

	variable i, numSweeps

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	for(i = numSweeps - 1; i >= 0; i -= 1)
		WAVE/Z settings = GetLastSetting(numericalValues, sweeps[i], setting, entrySourceType)

		if(WaveExists(settings))
			return settings
		endif
	endfor

	return $""
End

/// @brief Return the last numerical value for the given setting of *each*
///        sweep in the same RA cycle.
///
/// The returned wave will have `NaN` for sweeps which do not have that entry.
/// This is done in order to keep the indizes intact.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingIndepEachRAC(WAVE numericalValues, variable sweepNo, string setting, variable entrySourceType, [variable defValue])

	variable settings, numSweeps

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)

	Make/FREE/D/N=(numSweeps) result = GetLastSettingIndep(numericalValues, sweeps[p], setting, entrySourceType, defValue = defValue)

	if(!HasOneValidEntry(result))
		return $""
	endif

	return result
End

/// @brief Return the last textual value for the given setting of *each* sweep
///        in the same RA cycle.
///
/// The returned wave will have `NaN` for sweeps which do not have that entry.
/// This is done in order to keep the indizes intact.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingTextIndepEachRAC(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, string setting, variable entrySourceType, [string defValue])

	variable settings, numSweeps

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	Make/FREE/T/N=(numSweeps) result = GetLastSettingTextIndep(textualValues, sweeps[p], setting, entrySourceType, defValue = defValue)

	Make/N=(numSweeps)/FREE lengths = strlen(result[p])
	if(Sum(lengths) == 0)
		return $""
	endif

	return result
End

/// @brief Return the last numerical value for the given setting of *each*
///        sweep for a given headstage in the same RA cycle.
///
/// The returned wave will have `NaN` for sweeps which do not have that entry.
/// This is done in order to keep the indizes intact.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting
threadsafe Function/WAVE GetLastSettingEachRAC(WAVE numericalValues, variable sweepNo, string setting, variable headstage, variable entrySourceType)

	variable i, numSweeps

	ASSERT_TS(IsValidHeadstage(headstage), "Invalid headstage")

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	Make/FREE/D/N=(numSweeps) result = NaN

	for(i = 0; i < numSweeps; i += 1)
		WAVE/Z settings = GetLastSetting(numericalValues, sweeps[i], setting, entrySourceType)

		if(WaveExists(settings))
			result[i] = settings[headstage]
		endif
	endfor

	if(!HasOneValidEntry(result))
		return $""
	endif

	return result
End

/// @brief Return the last textual value for the given setting of *each* sweep
///        for a given headstage in the same RA cycle.
///
/// The returned wave will have `NaN` for sweeps which do not have that entry.
/// This is done in order to keep the indizes intact.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingTextEachRAC(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, string setting, variable headstage, variable entrySourceType)

	variable i, numSweeps

	ASSERT_TS(IsValidHeadstage(headstage), "Invalid headstage")

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	Make/FREE/T/N=(numSweeps) result

	for(i = 0; i < numSweeps; i += 1)
		WAVE/Z/T settings = GetLastSetting(textualValues, sweeps[i], setting, entrySourceType)

		if(WaveExists(settings))
			result[i] = settings[headstage]
		endif
	endfor

	Make/N=(numSweeps)/FREE lengths = strlen(result[p])
	if(Sum(lengths) == 0)
		return $""
	endif

	return result
End

/// @brief Return the last textual value of the sweeps in the same stimset cycle
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingTextSCI(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, string setting, variable headstage, variable entrySourceType)

	variable i, numSweeps

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	for(i = numSweeps - 1; i >= 0; i -= 1)
		WAVE/Z settings = GetLastSetting(textualValues, sweeps[i], setting, entrySourceType)

		if(WaveExists(settings))
			return settings
		endif
	endfor

	return $""
End

/// @brief Return the last numerical value of the sweeps in the same stimset cycle
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingSCI(WAVE numericalValues, variable sweepNo, string setting, variable headstage, variable entrySourceType)

	variable i, numSweeps

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	for(i = numSweeps - 1; i >= 0; i -= 1)
		WAVE/Z settings = GetLastSetting(numericalValues, sweeps[i], setting, entrySourceType)

		if(WaveExists(settings))
			return settings
		endif
	endfor

	return $""
End

/// @brief Return the last numerical value for the given setting of *each*
///        sweep in the same stimset cycle.
///
/// The returned wave will have `NaN` for sweeps which do not have that entry.
/// This is done in order to keep the indizes intact.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingIndepEachSCI(WAVE numericalValues, variable sweepNo, string setting, variable headstage, variable entrySourceType, [variable defValue])

	variable settings, numSweeps

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)

	Make/FREE/D/N=(numSweeps) result = GetLastSettingIndep(numericalValues, sweeps[p], setting, entrySourceType, defValue = defValue)

	if(!HasOneValidEntry(result))
		return $""
	endif

	return result
End

/// @brief Return the last textual value for the given setting of *each* sweep
///        in the same stimset cycle.
///
/// The returned wave will have `NaN` for sweeps which do not have that entry.
/// This is done in order to keep the indizes intact.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingTextIndepEachSCI(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, variable headstage, string setting, variable entrySourceType, [string defValue])

	variable settings, numSweeps

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	Make/FREE/T/N=(numSweeps) result = GetLastSettingTextIndep(textualValues, sweeps[p], setting, entrySourceType, defValue = defValue)

	Make/N=(numSweeps)/FREE lengths = strlen(result[p])
	if(Sum(lengths) == 0)
		return $""
	endif

	return result
End

/// @brief Return the last numerical value for the given setting of *each*
///        sweep for a given headstage in the same stimset cycle.
///
/// The returned wave will have `NaN` for sweeps which do not have that entry.
/// This is done in order to keep the indizes intact.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting
threadsafe Function/WAVE GetLastSettingEachSCI(WAVE numericalValues, variable sweepNo, string setting, variable headstage, variable entrySourceType)

	variable i, numSweeps

	ASSERT_TS(IsValidHeadstage(headstage), "Invalid headstage")

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	Make/FREE/D/N=(numSweeps) result = NaN

	for(i = 0; i < numSweeps; i += 1)
		WAVE/Z settings = GetLastSetting(numericalValues, sweeps[i], setting, entrySourceType)

		if(WaveExists(settings))
			result[i] = settings[headstage]
		endif
	endfor

	if(!HasOneValidEntry(result))
		return $""
	endif

	return result
End

/// @brief Return the last textual value for the given setting of *each* sweep
///        for a given headstage in the same stimset cycle.
///
/// The returned wave will have `NaN` for sweeps which do not have that entry.
/// This is done in order to keep the indizes intact.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
threadsafe Function/WAVE GetLastSettingTextEachSCI(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, string setting, variable headstage, variable entrySourceType)

	variable i, numSweeps

	ASSERT_TS(IsValidHeadstage(headstage), "Invalid headstage")

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
	if(!WaveExists(sweeps) || DimSize(sweeps, ROWS) == 0)
		return $""
	endif

	numSweeps = DimSize(sweeps, ROWS)
	Make/FREE/T/N=(numSweeps) result

	for(i = 0; i < numSweeps; i += 1)
		WAVE/Z/T settings = GetLastSetting(textualValues, sweeps[i], setting, entrySourceType)

		if(WaveExists(settings))
			result[i] = settings[headstage]
		endif
	endfor

	Make/N=(numSweeps)/FREE lengths = strlen(result[p])
	if(Sum(lengths) == 0)
		return $""
	endif

	return result
End

/// @brief Return a wave with all labnotebook rows which have a non-empty entry for setting
threadsafe Function [WAVE indizes, variable settingsCol] GetNonEmptyLBNRows(WAVE labnotebookValues, string setting)

	settingsCol = GetLogbookSettingsColumn(labnotebookValues, setting)

	if(settingsCol < 0)
		return [$"", NaN]
	endif

	WAVE/Z indizes = FindIndizes(labnotebookValues, col = settingsCol, prop = PROP_EMPTY | PROP_NOT, \
	                             startLayer = 0, endLayer = DimSize(labnotebookValues, LAYERS) - 1)

	return [indizes, settingsCol]
End

/// @brief Test helper to enforce that every query done for an INDEP_HEADSTAGE setting
/// does not search an entry which is HEADSTAGE dependent. The additional check that not all
/// entries are the same is for really old legacy entries which are INDEP but set for all headstages.
///
/// Does nothing outside of CI.
threadsafe static Function EnforceIndependentSetting(WAVE settings)

#ifdef AUTOMATED_TESTING
	Duplicate/FREE/RMD=[0, NUM_HEADSTAGES - 1] settings, settingsHS
	ASSERT_TS(!HasOneValidEntry(settingsHS) || IsConstant(settings, settings[0]), "The labnotebook query asked for independent headstage setting, but the entry has headstage dependent settings.")
#endif // AUTOMATED_TESTING
End

/// @brief Find the first and last point index of a consecutive range of
/// values in the labnotebook, searches the range from the back
///
/// @param[in]  wv                wave to search
/// @param[in]  col               column to look for
/// @param[in]  val               value to search
/// @param[in]  entrySourceType   type of the labnotebook entry, one of @ref DataAcqModes
/// @param[out] first             point index of the beginning of the range
/// @param[out] last              point index of the end of the range
threadsafe Function FindRange(WAVE wv, variable col, variable val, variable entrySourceType, variable &first, variable &last)

	variable numRows, i, j, sourceTypeCol, firstRow, lastRow, isNumeric, index, startRow, endRow

	first     = NaN
	last      = NaN
	isNumeric = IsNumericWave(wv)

	startRow = 0
	endRow   = GetNumberFromWaveNote(wv, NOTE_INDEX) - 1

	if(IsNaN(endRow))
		endRow = DimSize(wv, ROWS) - 1
	endif

	if(endRow < 0)
		// empty labnotebook
		return NaN
	endif

	// still correct without startLayer/endLayer coordinates
	// as we always have sweepNumber/etc. in the first layer
	if(IsNaN(val) && isNumeric)
		WAVE/Z indizesSetting = FindIndizes(wv, col = col, prop = PROP_EMPTY, startRow = startRow, endRow = endRow)
	else
		WAVE/Z indizesSetting = FindIndizes(wv, col = col, var = val, startRow = startRow, endRow = endRow)
	endif

	if(!WaveExists(indizesSetting))
		return NaN
	endif

	sourceTypeCol = FindDimLabel(wv, COLS, "EntrySourceType")
	if(IsFinite(entrySourceType))

		if(sourceTypeCol >= 0) // labnotebook has a entrySourceType column
			[firstRow, lastRow] = WaveMinAndMax(indizesSetting)
			WAVE/Z indizesSourceType = FindIndizes(wv, col = sourceTypeCol, var = entrySourceType, startRow = firstRow, endRow = lastRow)

			// we don't have an entry source type in the labnotebook set
			// throw away entries which are obviously from a different (guessed) entry source type
			if(!WaveExists(indizesSourceType))
				if(entrySourceType == DATA_ACQUISITION_MODE)

					// "TP Peak Resistance" introduced in 666d761a (TP documenting is implemented using David Reid's documenting functions, 2014-07-28)
					if(FindDimLabel(wv, COLS, "TP Peak Resistance") >= 0)
						WAVE/Z indizesDefinitlyTP = FindIndizes(wv, colLabel = "TP Peak Resistance", prop = PROP_EMPTY | PROP_NOT, startRow = firstRow, endRow = lastRow, startLayer = 0, endLayer = LABNOTEBOOK_LAYER_COUNT - 1)
						if(WaveExists(indizesDefinitlyTP) && WaveExists(indizesSetting))
							WAVE/Z indizesSettingRemoved = GetSetDifference(indizesSetting, indizesDefinitlyTP)
							WAVE/Z indizesSetting        = indizesSettingRemoved
						endif
					endif

					// "TP Baseline Fraction" introduced in 4f4649a2 (Document the testpulse settings in the labnotebook, 2015-07-28)
					if(FindDimLabel(wv, COLS, "TP Baseline Fraction") >= 0)
						WAVE/Z indizesDefinitlyTP = FindIndizes(wv, colLabel = "TP Baseline Fraction", prop = PROP_EMPTY | PROP_NOT, startRow = firstRow, endRow = lastRow, startLayer = 0, endLayer = LABNOTEBOOK_LAYER_COUNT - 1)
						if(WaveExists(indizesDefinitlyTP) && WaveExists(indizesSetting))
							WAVE/Z indizesSettingRemoved = GetSetDifference(indizesSetting, indizesDefinitlyTP)
							WAVE/Z indizesSetting        = indizesSettingRemoved
						endif
					endif
				endif
			endif
		endif
	endif

	if(WaveExists(indizesSourceType)) // entrySourceType could be found
		WAVE/Z indizes = GetSetIntersection(indizesSetting, indizesSourceType)
	else
		WAVE/Z indizes = indizesSetting
	endif

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)

	if(numRows == 1)
		first = indizes[0]
		last  = indizes[0]
		return NaN
	endif

	if(!IsNumeric)
		WAVE/T wt = wv
	endif

	first = indizes[numRows - 1]
	last  = indizes[numRows - 1]

	for(i = numRows - 2; i >= 0; i -= 1)
		index = indizes[i]
		// a backward search stops when the beginning of the last sequence was found
		if(index < (first - 1) && sourceTypeCol >= 0)
			if(IsNumeric)
				for(j = index + 1; j < first; j += 1)
					if(!IsNaN(wv[j][sourceTypeCol][0]))
						return NaN
					endif
				endfor
			else
				for(j = index + 1; j < first; j += 1)
					if(!IsEmpty(wt[j][sourceTypeCol][0]))
						return NaN
					endif
				endfor
			endif
		endif
		first = index
	endfor
End

/// @brief Returns the numerical index for the sweep number column
/// in the settings history waves (numeric and text)
threadsafe Function GetSweepColumn(WAVE labnotebookValues)

	variable sweepCol

	// new label
	sweepCol = GetLogbookSettingsColumn(labnotebookValues, "SweepNum")
	if(sweepCol >= 0)
		return sweepCol
	endif

	// Old label prior to 4caea03f
	// was normally overwritten by SweepNum later in the code
	// but not always as it turned out
	sweepCol = GetLogbookSettingsColumn(labnotebookValues, "SweepNumber")
	if(sweepCol >= 0)
		return sweepCol
	endif

	// text documentation waves
	sweepCol = GetLogbookSettingsColumn(labnotebookValues, "Sweep #")
	if(sweepCol >= 0)
		return sweepCol
	endif

	return 0
End

/// @brief Return a wave with all sweep numbers which have a non-empty entry for setting
///
/// @param labnotebookValues numerical/textual labnotebook
/// @param setting           name of the value to search
///
/// @return a 1D free wave with the matching sweep numbers. In case
/// the setting could not be found an invalid wave reference is returned.
///
/// @ingroup LabnotebookQueryFunctions
threadsafe Function/WAVE GetSweepsWithSetting(WAVE labnotebookValues, string setting)

	variable sweepCol, settingsCol

	[WAVE indizes, settingsCol] = GetNonEmptyLBNRows(labnotebookValues, setting)
	if(!WaveExists(indizes))
		return $""
	endif

	sweepCol = GetSweepColumn(labnotebookValues)

	if(IsTextWave(labnotebookValues))
		WAVE/T labnotebookValuesText = labnotebookValues
		Make/FREE/N=(DimSize(indizes, ROWS)) sweeps = str2num(labnotebookValuesText[indizes[p]][sweepCol][0])
	else
		Make/FREE/N=(DimSize(indizes, ROWS)) sweeps = labnotebookValues[indizes[p]][sweepCol][0]
	endif

	WAVE/Z cleanSweeps = ZapNaNs(sweeps)

	if(!WaveExists(cleanSweeps))
		return $""
	endif

	return GetUniqueEntries(sweeps)
End

/// @brief Return a unique list of labnotebook entries of the given setting
///
/// @param values  numerical logbook wave
/// @param setting name of the value to search
threadsafe Function/WAVE GetUniqueSettings(WAVE values, string setting)

	variable numMatches, settingsCol

	[WAVE indizes, settingsCol] = GetNonEmptyLBNRows(values, setting)
	if(!WaveExists(indizes))
		return $""
	endif

	numMatches = DimSize(indizes, ROWS)

	if(IsNumericWave(values))
		Make/D/FREE/N=(numMatches, LABNOTEBOOK_LAYER_COUNT) data

		Multithread data[][] = values[indizes[p]][settingsCol][q]

		Redimension/N=(numMatches * LABNOTEBOOK_LAYER_COUNT)/E=1 data

		WAVE dataUnique = GetUniqueEntries(data)

		return ZapNaNs(dataUnique)
	elseif(IsTextWave(values))
		Make/T/FREE/N=(numMatches, LABNOTEBOOK_LAYER_COUNT) dataTxt

		WAVE/T valuesTxt = values

		Multithread dataTxt[][] = valuesTxt[indizes[p]][settingsCol][q]

		Redimension/N=(numMatches * LABNOTEBOOK_LAYER_COUNT)/E=1 dataTxt

		WAVE dataUnique = GetUniqueEntries(dataTxt)

		RemoveTextWaveEntry1D(dataUnique, "")

		return dataUnique
	endif

	FATAL_ERROR("Unsupported wave type")
End

/// @brief Return the last numerical value of a setting from the labnotebook
///        and the sweep it was set.
///
/// @param[in]  numericalValues  numerical labnotebook
/// @param[in]  setting  name of the value to search
/// @param[out] sweepNo  sweep number the value was last set
///
/// @return a free wave with #LABNOTEBOOK_LAYER_COUNT rows. In case
/// the setting could not be found an invalid wave reference is returned.
///
/// @ingroup LabnotebookQueryFunctions
threadsafe Function/WAVE GetLastSweepWithSetting(WAVE numericalValues, string setting, variable &sweepNo)

	variable idx, settingsCol

	sweepNo = NaN
	ASSERT_TS(IsNumericWave(numericalValues), "Can only work with numeric waves")

	[WAVE indizes, settingsCol] = GetNonEmptyLBNRows(numericalValues, setting)
	if(!WaveExists(indizes))
		return $""
	endif

	idx = indizes[DimSize(indizes, ROWS) - 1]
	Make/FREE/N=(DimSize(numericalValues, LAYERS)) data = numericalValues[idx][settingsCol][p]
	sweepNo = numericalValues[idx][GetSweepColumn(numericalValues)][0]

	return data
End

/// @brief Return the last numerical value of a headstage independent
///        setting from the labnotebook and the sweep it was set.
///
/// @param[in]  numericalValues  numerical labnotebook
/// @param[in]  setting          name of the value to search
/// @param[out] sweepNo          sweep number the value was last set
/// @param[in]  defValue         [optional, defaults to `NaN`] value
///                              to return in case nothing could be found
///
/// @ingroup LabnotebookQueryFunctions
threadsafe Function GetLastSweepWithSettingIndep(WAVE numericalValues, string setting, variable &sweepNo, [variable defValue])

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z settings = GetLastSweepWithSetting(numericalValues, setting, sweepNo)

	if(WaveExists(settings))
		EnforceIndependentSetting(settings)
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	endif

	return defValue
End

/// @brief Return the last textual value of a setting from the labnotebook
///        and the sweep it was set.
///
/// @param[in]  textualValues  textual labnotebook
/// @param[in]  setting  name of the value to search
/// @param[out] sweepNo  sweep number the value was last set
///
/// @return a free wave with #LABNOTEBOOK_LAYER_COUNT rows. In case
/// the setting could not be found an invalid wave reference is returned.
///
/// @ingroup LabnotebookQueryFunctions
threadsafe Function/WAVE GetLastSweepWithSettingText(WAVE/T textualValues, string setting, variable &sweepNo)

	variable idx, settingsCol

	sweepNo = NaN
	ASSERT_TS(IsTextWave(textualValues), "Can only work with text waves")

	[WAVE indizes, settingsCol] = GetNonEmptyLBNRows(textualValues, setting)
	if(!WaveExists(indizes))
		return $""
	endif

	idx = indizes[DimSize(indizes, ROWS) - 1]
	Make/FREE/T/N=(DimSize(textualValues, LAYERS)) data = textualValues[idx][settingsCol][p]
	sweepNo = str2num(textualValues[idx][GetSweepColumn(textualValues)][0])

	return data
End

/// @brief Return the last textual value of a headstage independent
///        setting from the labnotebook and the sweep it was set.
///
/// @param[in]  numericalValues  numerical labnotebook
/// @param[in]  setting          name of the value to search
/// @param[out] sweepNo          sweep number the value was last set
/// @param[in]  defValue         [optional, defaults to an empty string] value
///                              to return in case nothing could be found
///
/// @ingroup LabnotebookQueryFunctions
threadsafe Function/S GetLastSweepWithSettingTextI(WAVE numericalValues, string setting, variable &sweepNo, [string defValue])

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/Z/T settings = GetLastSweepWithSettingText(numericalValues, setting, sweepNo)

	if(WaveExists(settings))
		EnforceIndependentSetting(settings)
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	endif

	return defValue
End

/// @brief Return the index for headstage independent data
///
/// Before dfe2d862 (Make the function AB_SplitTTLWaveIntoComponents available for all, 2015-10-07)
/// we stored headstage independent data in either all entries or only the first one.
/// Since that commit we store the data in `INDEP_HEADSTAGE`.
threadsafe Function GetIndexForHeadstageIndepData(WAVE values)

	return (DimSize(values, LAYERS) == NUM_HEADSTAGES) ? 0 : INDEP_HEADSTAGE
End

/// @brief Create a labnotebook key for unassociated channels
///
/// We support two types of unassociated keys. Old style, prior to 403c8ec2
/// (Merge pull request #370 from AllenInstitute/feature/sweepformula_enable,
/// 2019-11-13) but after its introduction in ad8dc8ec (Allow AD/DA channels
/// not associated with a headstage again, 2015-10-22) are written as "$Name UNASSOC_$ChannelNumber".
///
/// New style have the format "$Name u_(AD|DA)$ChannelNumber", these include
/// the channel type to make them more self explaining.
threadsafe Function/S CreateLBNUnassocKey(string setting, variable channelNumber, variable channelType)

	ASSERT_TS(!IsEmpty(setting), "Expected non empty string")
	ASSERT_TS(IsFinite(channelNumber), "Expected finite channel number")

	string key

	if(IsNaN(channelType))
		sprintf key, "%s UNASSOC_%d", setting, channelNumber
	else
		ASSERT_TS(channelType == XOP_CHANNEL_TYPE_DAC || channelType == XOP_CHANNEL_TYPE_ADC, "Invalid channel type")
		ASSERT_TS(IsInteger(channelNumber) && channelNumber >= 0 && channelNumber < GetNumberFromType(xopVar = channelType), "channelNumber is out of range")
		sprintf key, "%s u_%s%d", setting, StringFromList(channelType, XOP_CHANNEL_NAMES), channelNumber
	endif

	return key
End

/// @brief Create a LBN key for TTL channels
threadsafe Function/S CreateTTLChannelLBNKey(string entry, variable channelNumber)

	if(IsNaN(channelNumber))
		return "TTL " + entry
	endif

	sprintf entry, "TTL %s Channel %d", entry, channelNumber

	return entry
End

/// @brief Check if the given labnotebook entry is from an unassociated DA/AD channel
threadsafe Function IsUnassocLBNKey(string name)

	return GrepString(name, LBN_UNASSOC_REGEXP_LEGACY) || GrepString(name, LBN_UNASSOC_REGEXP)
End

/// @brief Remove the unassociated, old and new, prefix of the given labnotebook entry name
///
/// @sa CreateLBNUnassocKey()
Function/S RemoveUnassocLBNKeySuffix(string name)

	string result, suffix

	SplitString/E=(LBN_UNASSOC_REGEXP) name, result, suffix
	if(V_flag == 2)
		return result
	endif

	SplitString/E=(LBN_UNASSOC_REGEXP_LEGACY) name, result, suffix
	if(V_flag == 2)
		return result
	endif

	return name
End

/// @brief Maps the labnotebook entry source type, one of @ref DataAcqModes, to
///        a valid wave index.
///
/// UTF_NOINSTRUMENTATION
threadsafe Function EntrySourceTypeMapper(variable entrySourceType)

	return IsFinite(entrySourceType) ? ++entrySourceType : 0
End

/// @brief Rerverse the effect of EntrySourceTypeMapper()
///
/// UTF_NOINSTRUMENTATION
threadsafe Function ReverseEntrySourceTypeMapper(variable mapped)

	return ((mapped == 0) ? NaN : --mapped)
End

/// @brief Tests if the LBN value wave supports the EntrySourceType column
///        Only used in UpgradeLabNotebook
///        returns 0 if not, 1 is yes
Function HasLBNEntrySourceTypeCapability(WAVE values)

	variable entryCol

	entryCol = FindDimLabel(values, COLS, "EntrySourceType")
	if(entryCol == -2)
		return 0
	endif

	if(!DimSize(values, ROWS))
		return 1
	endif

	if(IsNumericWave(values))
		WaveStats/Q/M=1/RMD=[][entryCol][] values
		return !IsNaN(V_max)
	endif

	Duplicate/FREE/RMD=[][entryCol][] values, entrySourceTypeValues
	return HasOneValidEntry(entrySourceTypeValues)
End

/// @brief Returns a labnotebook capability
///
/// @param values        LBN values wave
/// @param capabilityKey Capabilities key, one of @ref LabnotebookCapabilityKeys
///
/// @returns capability value
threadsafe Function GetLBNCapability(WAVE values, string capabilityKey)

	variable cap

	WAVE/Z keys = GetLogbookKeysFromValues(values)
	ASSERT_TS(WaveExists(keys), "Can not resolve LBN keys wave")
	cap = GetNumberFromWaveNote(keys, capabilityKey)
	// Triggers if LBN was not correctly upgraded in UpgradeLabNotebook
	ASSERT_TS(!IsNaN(cap), "Requested LBN capability not found: " + capabilityKey)

	return cap
End

/// @brief Return labnotebook keys for patch seq analysis functions
///
/// @param type                                One of @ref SpecialAnalysisFunctionTypes
/// @param formatString                        One of  @ref PatchSeqLabnotebookFormatStrings or @ref MultiPatchSeqLabnotebookFormatStrings
/// @param chunk [optional]                    Some format strings expect a chunk number
/// @param query [optional, defaults to false] If the key is to be used for setting or querying the labnotebook
/// @param waMode [optional, defaults to PSQ_LBN_WA_NONE] One of @ref LBNWorkAroundFlags
Function/S CreateAnaFuncLBNKey(variable type, string formatString, [variable chunk, variable query, variable waMode])

	if(ParamIsDefault(waMode))
		waMode = PSQ_LBN_WA_NONE
	else
		ASSERT(waMode == PSQ_LBN_WA_NONE || waMode == PSQ_LBN_WA_SP_SE, "Invalid waMode")
	endif

	string str, prefix

	switch(type)
		case MSQ_DA_SCALE:
			prefix = MSQ_DS_LBN_PREFIX
			break
		case MSQ_FAST_RHEO_EST:
			prefix = MSQ_FRE_LBN_PREFIX
			break
		case SC_SPIKE_CONTROL:
			prefix = MSQ_SC_LBN_PREFIX
			break
		case PSQ_ACC_RES_SMOKE:
			prefix = PSQ_AR_LBN_PREFIX
			break
		case PSQ_CHIRP:
			prefix = PSQ_CR_LBN_PREFIX
			break
		case PSQ_DA_SCALE:
			prefix = PSQ_DS_LBN_PREFIX
			break
		case PSQ_RAMP:
			prefix = PSQ_RA_LBN_PREFIX
			break
		case PSQ_RHEOBASE:
			prefix = PSQ_RB_LBN_PREFIX
			break
		case PSQ_SQUARE_PULSE:
			if(waMode == PSQ_LBN_WA_SP_SE)
				prefix = PSQ_SE_LBN_PREFIX
			else
				prefix = PSQ_SP_LBN_PREFIX
			endif
			break
		case PSQ_SEAL_EVALUATION:
			prefix = PSQ_SE_LBN_PREFIX
			break
		case PSQ_PIPETTE_BATH:
			prefix = PSQ_PB_LBN_PREFIX
			break
		case PSQ_TRUE_REST_VM:
			prefix = PSQ_VM_LBN_PREFIX
			break
#ifdef AUTOMATED_TESTING
		case TEST_ANALYSIS_FUNCTION:
			prefix = "test analysis function"
			break
#endif
		default:
			return ""
			break
	endswitch

	if(!GrepString(formatString, "%s"))
		return ""
	endif

	if(ParamIsDefault(chunk))
		sprintf str, formatString, prefix
	else
		sprintf str, formatString, prefix, chunk
	endif

	if(ParamIsDefault(query))
		query = 0
	else
		query = !!query
	endif

	if(query)
		return LABNOTEBOOK_USER_PREFIX + str
	endif

	return str
End

/// @brief Add a labnotebook entry denoting the analysis function version
Function SetAnalysisFunctionVersion(string device, variable type, variable headstage, variable sweepNo)

	string key

	key = CreateAnaFuncLBNKey(type, FMT_LBN_ANA_FUNC_VERSION)
	WAVE values = LBN_GetNumericWave()
	values[headstage] = GetAnalysisFunctionVersion(type)
	ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = sweepNo, tolerance = 0.1)
End

/// @brief Returns the active headstage for a given sweep, channelType, channelNumber from the LBN
///
/// @param numericalValues LBN wave with numerical values
/// @param sweep           sweep number
/// @param channelType     channel type number
/// @param channelNumber   channel number
/// @param entrySourceType type of the labnotebook entry, one of @ref DataAcqModes
/// @return headstage number or NaN if no headstage was found
Function GetHeadstageForChannel(WAVE numericalValues, variable sweep, variable channelType, variable channelNumber, variable entrySourceType)

	variable index

	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweep, "Headstage Active", channelNumber, channelType, entrySourceType)
	if(WaveExists(settings) && settings[index] == 1)
		return index
	endif

	// fallback for LBN before
	// 602debb9 (Record the active headstage in the settingsHistory, 2014-11-04)
	return GetHeadstageFromOldLBN(numericalValues, sweep, channelType, channelNumber, entrySourceType)
End

/// @brief Return a list of TTL stimsets which are indexed by DAEphys TTL channels
///
/// The indexing here is **hardware independent**.
/// For ITC hardware the assertion "log(ttlBit)/log(2) == DAEphys TTL channel" holds.
///
/// @param textualValues   Text labnotebook values
/// @param name            One of @ref LabnotebookTTLNames
/// @param sweep           Sweep number
threadsafe Function/WAVE GetTTLLabnotebookEntry(WAVE/T textualValues, string name, variable sweep)

	variable index

	index = GetIndexForHeadstageIndepData(textualValues)

	WAVE/Z/T ttlEntry         = GetLastSetting(textualValues, sweep, "TTL " + name, DATA_ACQUISITION_MODE)
	WAVE/Z/T ttlEntryRackZero = GetLastSetting(textualValues, sweep, "TTL rack zero " + name, DATA_ACQUISITION_MODE)
	WAVE/Z/T ttlEntryRackOne  = GetLastSetting(textualValues, sweep, "TTL rack one " + name, DATA_ACQUISITION_MODE)

	if(WaveExists(ttlEntry))
		// NI hardware
		return ListToTextWave(ttlEntry[index], ";")
	elseif(WaveExists(ttlEntryRackZero) || WaveExists(ttlEntryRackOne))
		// ITC hardware
		Make/FREE/T/N=(NUM_DA_TTL_CHANNELS) entries
		if(WaveExists(ttlEntryRackZero))
			entries += StringFromList(p, ttlEntryRackZero[index])
		endif

		if(WaveExists(ttlEntryRackOne))
			entries[NUM_ITC_TTL_BITS_PER_RACK, Inf] += StringFromList(p - NUM_ITC_TTL_BITS_PER_RACK, ttlEntryRackOne[index])
		endif

		return entries
	endif

	// no TTL entries
	return $""
End

/// @brief Return the total onset delay from the given device during DAQ
///
/// @sa GetTotalOnsetDelay
///
/// UTF_NOINSTRUMENTATION
Function GetTotalOnsetDelayFromDevice(string device)

	WAVE TPSettingsCalculated = GetTPSettingsCalculated(device)

	return DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser") + TPSettingsCalculated[%totalLengthMS]
End

/// @brief Retrieve the analysis function that was run for a given sweep / channelNumber / channelType
///
/// @param numericalValues numerical labnotebook
/// @param textualValues   textual labnotebook
/// @param sweepNo         sweep number
/// @param channelNumber   channel number
/// @param channelType     channelType
///
/// @retval type      analysis function type @ref SpecialAnalysisFunctionTypes
/// @retval waMode    bit-mask of possible workarounds for CreateAnaFuncLBNKey()
/// @retval headstage headstage where the analysis function was run on
Function [variable type, variable waMode, variable headstage] GetAnalysisFunctionType(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, variable channelNumber, variable channelType)

	string key, anaFuncName
	variable index, DAC

	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "DAC", channelNumber, channelType, DATA_ACQUISITION_MODE)
	if(!WaveExists(settings))
		return [NaN, NaN, NaN]
	endif
	DAC = settings[index]

	key                    = "Generic function"
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, key, DAC, XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
	if(!WaveExists(settings))
		return [NaN, NaN, NaN]
	endif
	anaFuncName = WaveText(settings, row = index)

	headstage = GetHeadStageForChannel(numericalValues, sweepNo, channelType, channelNumber, DATA_ACQUISITION_MODE)
	if(!IsAssociatedChannel(headstage))
		return [NaN, NaN, NaN]
	endif

	WAVE anaFuncTypes = LBN_GetNumericWave(defValue = INVALID_ANALYSIS_FUNCTION)
	anaFuncTypes[headstage] = MapAnaFuncToConstant(anaFuncName)
	[type, waMode]          = AD_GetAnalysisFunctionType(numericalValues, anaFuncTypes, sweepNo, headstage)

	return [type, waMode, headstage]
End

// fallback for headstage retrievel for LBN before
// 602debb9 (Record the active headstage in the settingsHistory, 2014-11-04)
// The headstage is retrieved by evaluating the DAC/ADC entries of the LBN
static Function GetHeadstageFromOldLBN(WAVE numericalValues, variable sweepNo, variable channelType, variable channelNumber, variable dataAcqOrTP)

	string lbnEntry

	switch(channelType)
		case XOP_CHANNEL_TYPE_DAC:
			lbnEntry = "DAC"
			break
		case XOP_CHANNEL_TYPE_ADC:
			lbnEntry = "ADC"
			break
		case XOP_CHANNEL_TYPE_TTL:
			return NaN
		default:
			FATAL_ERROR("Unknown channel type")
	endswitch

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, lbnEntry, dataAcqOrTP)
	if(!WaveExists(settings))
		return NaN
	endif
	FindValue/V=(channelNumber) settings
	if(V_value == -1)
		return NaN
	endif
	if(V_row < NUM_HEADSTAGES)
		return V_row
	endif

	return NaN
End

Function ParseLogbookMode(string modeText)

	strswitch(modeText)
		case "UNKNOWN_MODE":
			return UNKNOWN_MODE
		case "DATA_ACQUISITION_MODE":
			return DATA_ACQUISITION_MODE
		case "TEST_PULSE_MODE":
			return TEST_PULSE_MODE
		default:
			FATAL_ERROR("Unsupported labnotebook mode")
			break
	endswitch
End

Function/S StringifyLogbookMode(variable mode)

	switch(mode)
		case UNKNOWN_MODE:
			return "UNKNOWN_MODE"
		case DATA_ACQUISITION_MODE:
			return "DATA_ACQUISITION_MODE"
		case TEST_PULSE_MODE:
			return "TEST_PULSE_MODE"
		default:
			FATAL_ERROR("Unsupported logbook mode")
			break
	endswitch
End

/// @brief Invalidates the row and index caches for all labnotebook and results wave
Function InvalidateLBIndexAndRowCaches()

	string device

	DFREF dfr = GetCacheFolder()

	if(IsDataFolderEmpty(dfr))
		return NaN
	endif

	WAVE/T devices = ListToTextWave(GetAllDevices(), ";")

	// labnotebook (numerical and textual) of all devices
	for(device : devices)
		Make/FREE/WAVE valuesWave = {GetLBNumericalValues(device), GetLBTextualValues(device)}

		for(WAVE values : valuesWave)
			InvalidateLBIndexAndRowCache(values)
		endfor
	endfor

	Make/FREE/WAVE valuesWave = {GetNumericalResultsValues(), GetTextualResultsValues()}

	for(WAVE values : valuesWave)
		InvalidateLBIndexAndRowCache(values)
	endfor
End

/// @brief Invalidates the row and index caches for a single numerical or textual logbook
Function InvalidateLBIndexAndRowCache(WAVE values)

	string key

	Make/FREE/T keys = {CA_CreateLBIndexCacheKey(values), CA_CreateLBRowCacheKey(values)}

	for(key : keys)
		CA_DeleteCacheEntry(key)
	endfor
End

Function InsertRecreatedEpochsIntoLBN(WAVE numericalValues, WAVE/T textualValues, string device, variable sweepNo)

	string epochList
	variable channelNumber, channelType, headstage, numChannelTypes, colCount, allocatedCols
	variable assocCol = NaN

	DFREF  deviceDFR = GetDeviceDataPath(device)
	DFREF  sweepDFR  = GetSingleSweepFolder(deviceDFR, sweepNo)
	WAVE/Z recEpochs = EP_RecreateEpochsFromLoadedData(numericalValues, textualValues, sweepDFR, sweepNo)
	if(!WaveExists(recEpochs))
		print "Could not recreate Epochs."
		return NaN
	endif

	Make/FREE channelTypes = {XOP_CHANNEL_TYPE_DAC, XOP_CHANNEL_TYPE_TTL}

	numChannelTypes = DimSize(channelTypes, ROWS)
	allocatedCols   = numChannelTypes * NUM_DA_TTL_CHANNELS
	Make/FREE/T/N=(1, allocatedCols) keys
	Make/FREE/T/N=(1, allocatedCols, LABNOTEBOOK_LAYER_COUNT) values

	for(channelType : channelTypes)
		for(channelNumber = 0; channelNumber < NUM_DA_TTL_CHANNELS; channelNumber += 1)

			epochList = EP_EpochWaveToStr(recEpochs, channelNumber, channelType)
			if(IsEmpty(epochList))
				continue
			endif

			if(channelType == XOP_CHANNEL_TYPE_TTL)
				keys[0][colCount]                    = CreateTTLChannelLBNKey(EPOCHS_ENTRY_KEY, channelNumber)
				values[0][colCount][INDEP_HEADSTAGE] = epochList
				colCount                            += 1
				continue
			endif

			headstage = GetHeadstageForChannel(numericalValues, sweepNo, channelType, channelNumber, DATA_ACQUISITION_MODE)
			if(IsAssociatedChannel(headstage))
				if(IsNaN(assocCol))
					assocCol          = colCount
					colCount         += 1
					keys[0][assocCol] = EPOCHS_ENTRY_KEY
				endif
				values[0][assocCol][headstage] = epochList
				continue
			endif

			values[0][colCount][INDEP_HEADSTAGE] = epochList
			keys[0][colCount]                    = CreateLBNUnassocKey(EPOCHS_ENTRY_KEY, channelNumber, channelType)
			colCount                            += 1
		endfor
	endfor
	if(!colCount)
		// No Epochs could be recreated for any channel
		return NaN
	endif

	Redimension/N=(-1, colCount) keys
	Redimension/N=(-1, colCount, -1) values
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE, insertAsPostProc = 1)

	Redimension/N=(-1, 1) keys
	keys[0][0] = SWEEP_EPOCH_VERSION_ENTRY_KEY
	Make/FREE/D/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) valuesNum
	FastOp valuesNum = (NaN)
	valuesNum[0][0][INDEP_HEADSTAGE] = SWEEP_EPOCH_VERSION
	ED_AddEntriesToLabnotebook(valuesNum, keys, sweepNo, device, DATA_ACQUISITION_MODE, insertAsPostProc = 1)
End
