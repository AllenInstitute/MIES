#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS
#endif

#include <Axis Utilities>

/// @file MIES_MiesUtilities.ipf
/// @brief This file holds utility functions which need to know about MIES internals.

static StrConstant LABNOTEBOOK_BOTTOM_AXIS_TIME  = "Timestamp (a. u.)"
static StrConstant LABNOTEBOOK_BOTTOM_AXIS_SWEEP = "Sweep Number (a. u.)"

static Constant GRAPH_DIV_SPACING   = 0.03
static Constant ADC_SLOT_MULTIPLIER = 4
static Constant NUM_CHANNEL_TYPES   = 3

static Constant GET_LB_MODE_NONE  = 0
static Constant GET_LB_MODE_READ  = 1

static Constant GET_LB_MODE_WRITE = 2

Menu "GraphMarquee"
	"Horiz Expand (VisX)", HorizExpandWithVisX()
End

/// @brief Custom graph marquee
///
/// Requires an existing marquee and a graph as current top window
Function HorizExpandWithVisX()

	string graph, list, axis, str
	variable numEntries, i, orientation

	graph = GetCurrentWindow()

	list = AxisList(graph)
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)

		axis = StringFromList(i, list)

		GetAxis/Q/W=$graph $axis
		if(V_flag)
			// axis does not exist
			continue
		endif

		orientation = GetAxisOrientation(graph, axis)
		if(orientation == AXIS_ORIENTATION_LEFT || orientation == AXIS_ORIENTATION_RIGHT)
			// no horizontal axis
			continue
		endif

		GetMarquee/Z/W=$graph $axis
		if(!V_flag)
			// no marquee on axis
			continue
		endif

		if(V_left < V_min || V_right > V_max)
			// marquee does not lie completely in the axis
			continue
		endif

		graph = S_marqueeWin

		sprintf str, "graph=%s, axis=%s, left=%d, right=%d", graph, axis, V_left, V_right
		DEBUGPRINT(str)

		SetAxis/W=$graph $axis, V_left, V_right
		AutoscaleVertAxisVisXRange(graph)
	endfor

	GetMarquee/K/W=$graph
End

/// @brief Extract the date/time column of the labnotebook values wave
Function/WAVE ExtractLBColumnTimeStamp(values)
	WAVE values

	return ExtractLBColumn(values, 1, "Dat")
End

/// @brief Extract the sweep number column of the labnotebook values wave
Function/WAVE ExtractLBColumnSweep(values)
	WAVE values

	return ExtractLBColumn(values, 0, "Sweep")
End

/// @brief Extract a column of the labnotebook values wave and makes it empty
Function/WAVE ExtractLBColumnEmpty(values)
	WAVE values

	WAVE wv = ExtractLBColumn(values, 0, "Null")
	wv = 0

	return wv
End

/// @brief Extract a single column of the labnotebook values wave
///
/// This is useful if you want to plot values against e.g time and let
/// Igor do the formatting of the date/time values.
/// Always returns a numerical wave.
static Function/WAVE ExtractLBColumn(values, col, suffix)
	WAVE values
	variable col
	string suffix

	string name, colName
	variable nextRowIndex

	// we can't use the GetDevSpecLabNBTempFolder getter as we are
	// called from the analysisbrowser as well.
	DFREF dfr = createDFWithAllParents(GetWavesDataFolder(values, 1) + "Temp")
	colName = GetDimLabel(values, COLS, col)
	ASSERT(!isEmpty(colName), "colName must not be empty")
	name = NameOfWave(values) + suffix
	WAVE/Z/SDFR=dfr singleColumn = $name

	nextRowIndex = GetNumberFromWaveNote(values, NOTE_INDEX)

	if(!WaveExists(singleColumn) || DimSize(singleColumn, ROWS) != DimSize(values, ROWS) || DimSize(singleColumn, ROWS) < nextRowIndex || (nextRowIndex > 0 && !IsFinite(singleColumn[nextRowIndex - 1])))
		KillOrMoveToTrash(wv=singleColumn)
		Duplicate/O/R=[0, DimSize(values, ROWS)][col][-1][-1] values, dfr:$name/Wave=singleColumn
		// we want to have a pure 1D wave without any columns or layers, this is currently not possible with Duplicate
		Redimension/N=-1 singleColumn

		// redimension has the odd behaviour to change a wave with zero rows to one with 1 row and then initializes that point to zero
		// we need to fix that
		if(DimSize(singleColumn, ROWS) == 1 && !IsTextWave(singleColumn))
			singleColumn = NaN
		endif

		if(!cmpstr(colName, "TimeStamp"))
			SetScale d, 0, 0, "dat" singleColumn
		endif

		SetDimLabel ROWS, -1, $colName, singleColumn
	endif

	if(IsTextWave(singleColumn))
		WAVE/T singleColumnFree = MakeWaveFree(singleColumn)
		Make/O/D/N=(DimSize(singleColumnFree, ROWS), DimSize(singleColumnFree, COLS), DimSize(singleColumnFree, LAYERS), DimSize(singleColumnFree, CHUNKS)) dfr:$name/Wave=singleColumnFromText
		CopyScales singleColumnFree, singleColumnFromText
		singleColumnFromText = str2num(singleColumnFree)
		return singleColumnFromText
	endif

	return singleColumn
End

/// @brief Return a list of the AD channels from the ITC config
Function/WAVE GetADCListFromConfig(config)
	WAVE config

	return GetChanneListFromITCConfig(config, ITC_XOP_CHANNEL_TYPE_ADC)
End

/// @brief Return a list of the DA channels from the ITC config
Function/WAVE GetDACListFromConfig(config)
	WAVE config

	return GetChanneListFromITCConfig(config, ITC_XOP_CHANNEL_TYPE_DAC)
End

/// @brief Return a list of the TTL channels from the ITC config
Function/WAVE GetTTLListFromConfig(config)
	WAVE config

	return GetChanneListFromITCConfig(config, ITC_XOP_CHANNEL_TYPE_TTL)
End

/// @brief Return a wave with all active channels
///
/// @todo change to return a 0/1 wave with constant size a la DAG_GetChannelState
///
/// @param config       ITCChanConfigWave as passed to the ITC XOP
/// @param channelType  DA/AD/TTL constants, see @ref ChannelTypeAndControlConstants
static Function/WAVE GetChanneListFromITCConfig(config, channelType)
	WAVE config
	variable channelType

	variable numRows, i, j

	ASSERT(IsValidConfigWave(config), "Invalid config wave")

	numRows = DimSize(config, ROWS)
	Make/U/B/FREE/N=(numRows) activeChannels

	for(i = 0; i < numRows; i += 1)
		if(channelType == config[i][0])
			activeChannels[j] = config[i][1]
			j += 1
		endif
	endfor

	Redimension/N=(j) activeChannels

	return activeChannels
End

/// @brief Return the dimension label for the special, aka non-unique, controls
Function/S GetSpecialControlLabel(channelType, controlType)
	variable channelType, controlType

	return RemoveEnding(GetPanelControl(0, channelType, controlType), "_00")
End

/// @brief Returns the name of a control from the DA_EPHYS panel
///
/// Constants are defined at @ref ChannelTypeAndControlConstants
Function/S GetPanelControl(channelIndex, channelType, controlType)
	variable channelIndex, channelType, controlType

	string ctrl

	if(channelType == CHANNEL_TYPE_HEADSTAGE)
		ctrl = "DataAcqHS"
	elseif(channelType == CHANNEL_TYPE_DAC)
		ctrl = "DA"
	elseif(channelType == CHANNEL_TYPE_ADC)
		ctrl = "AD"
	elseif(channelType == CHANNEL_TYPE_TTL)
		ctrl = "TTL"
	elseif(channelType == CHANNEL_TYPE_ALARM)
		ctrl = "AsyncAlarm"
	elseif(channelType == CHANNEL_TYPE_ASYNC)
		ctrl = "AsyncAD"
	else
		ASSERT(0, "Invalid channelType")
	endif

	if(controlType == CHANNEL_CONTROL_WAVE)
		ctrl = "Wave_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_INDEX_END)
		ctrl = "IndexEnd_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_UNIT)
		ctrl = "Unit_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_GAIN)
		ctrl = "Gain_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_SCALE)
		ctrl = "Scale_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_CHECK)
		ctrl = "Check_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_ALARM_MIN)
		ctrl = "Min_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_ALARM_MAX)
		ctrl = "Max_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_SEARCH)
		ctrl = "Search_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_TITLE)
		ctrl = "Title_" + ctrl
	else
		ASSERT(0, "Invalid controlType")
	endif

	if(channelIndex == CHANNEL_INDEX_ALL)
		ctrl += "_All"
	elseif(channelIndex == CHANNEL_INDEX_ALL_V_CLAMP)
		ctrl += "_AllVClamp"
	elseif(channelIndex == CHANNEL_INDEX_ALL_I_CLAMP)
		ctrl += "_AllIClamp"
	else
		ASSERT(channelIndex >= 0 && channelIndex < 100, "invalid channelIndex")
		sprintf ctrl, "%s_%02d", ctrl, channelIndex
	endif

	return ctrl
End

/// @brief Find the first and last point index of a consecutive range of
/// values in the labnotebook
///
/// @param[in]  wv                wave to search
/// @param[in]  col               column to look for
/// @param[in]  val               value to search
/// @param[in]  forwardORBackward find the first(1) or last(0) range
/// @param[in]  entrySourceType   type of the labnotebook entry, one of @ref DataAcqModes
/// @param[out] first             point index of the beginning of the range
/// @param[out] last              point index of the end of the range
Function FindRange(wv, col, val, forwardORBackward, entrySourceType, first, last)
	WAVE wv
	variable col, val, forwardORBackward, entrySourceType
	variable &first, &last

	variable numRows, i, sourceTypeCol

	first = NaN
	last  = NaN

	// still correct without startLayer/endLayer coordinates
	// as we always have sweepNumber/etc. in the first layer
	if(IsNaN(val))
		WAVE/Z indizesSetting = FindIndizes(wv, col=col, prop=PROP_EMPTY)
	else
		WAVE/Z indizesSetting = FindIndizes(wv, col=col, var=val)
	endif

	if(!WaveExists(indizesSetting))
		return NaN
	endif

	if(IsFinite(entrySourceType))
		sourceTypeCol = FindDimLabel(wv, COLS, "EntrySourceType")

		if(sourceTypeCol >= 0) // labnotebook has a entrySourceType column
			WAVE/Z indizesSourceType = FindIndizes(wv, col=sourceTypeCol, var=entrySourceType, startRow = WaveMin(indizesSetting), endRow = WaveMax(indizesSetting))
		endif
	endif

	if(WaveExists(indizesSourceType)) // entrySourceType could be found
		WAVE/Z indizes = GetSetIntersection(indizesSetting, indizesSourceType)
		if(!WaveExists(indizes))
			return NaN
		endif
	else
		WAVE indizes = indizesSetting
	endif

	numRows = DimSize(indizes, ROWS)

	if(numRows == 1)
		first = indizes[0]
		last  = indizes[0]
		return NaN
	endif

	if(forwardORBackward)

		first = indizes[0]
		last  = indizes[0]

		for(i = 1; i < numRows; i += 1)
			// a forward search stops after the end of the first sequence
			if(indizes[i] > last + 1)
				return NaN
			endif

			last = indizes[i]
		endfor
	else

		first = indizes[numRows - 1]
		last  = indizes[numRows - 1]

		for(i = numRows - 2; i >= 0; i -= 1)
			// a backward search stops when the beginning of the last sequence was found
			if(indizes[i] < first - 1)
				return NaN
			endif

			first = indizes[i]
		endfor
	endif
End

/// @brief Returns the numerical index for the sweep number column
/// in the settings history waves (numeric and text)
Function GetSweepColumn(labnotebookValues)
	Wave labnotebookValues

	variable sweepCol

	// new label
	sweepCol = FindDimLabel(labnotebookValues, COLS, "SweepNum")

	if(sweepCol >= 0)
		return sweepCol
	endif

	// Old label prior to 276b5cf6
	// was normally overwritten by SweepNum later in the code
	// but not always as it turned out
	sweepCol = FindDimLabel(labnotebookValues, COLS, "SweepNumber")

	if(sweepCol >= 0)
		return sweepCol
	endif

	// text documentation waves
	sweepCol = FindDimLabel(labnotebookValues, COLS, "Sweep #")

	if(sweepCol >= 0)
		return sweepCol
	endif

	DEBUGPRINT("Could not find sweep number dimension label, trying with column zero")

	return 0
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
Function GetLastSettingIndep(numericalValues, sweepNo, setting, entrySourceType, [defValue])
	Wave numericalValues
	variable sweepNo
	string setting
	variable defValue, entrySourceType

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, setting, entrySourceType)

	if(WaveExists(settings))
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	else
		DEBUGPRINT("Missing setting in labnotebook", str=setting)
		return defValue
	endif
End

/// @brief Return a headstage independent setting from the textual labnotebook
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
Function/S GetLastSettingTextIndep(textualValues, sweepNo, setting, entrySourceType, [defValue])
	Wave/T textualValues
	variable sweepNo
	string setting, defValue
	variable entrySourceType

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/T/Z settings = GetLastSetting(textualValues, sweepNo, setting, entrySourceType)

	if(WaveExists(settings))
		return settings[GetIndexForHeadstageIndepData(textualValues)]
	else
		DEBUGPRINT("Missing setting in labnotebook", str=setting)
		return defValue
	endif
End

/// @brief Return a headstage independent setting from the numerical
///        labnotebook of the sweeps in the same RA cycle
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
Function GetLastSettingIndepRAC(numericalValues, sweepNo, setting, entrySourceType, [defValue])
	Wave numericalValues
	variable sweepNo
	string setting
	variable defValue, entrySourceType

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z settings = GetLastSettingRAC(numericalValues, sweepNo, setting, entrySourceType)

	if(WaveExists(settings))
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	else
		DEBUGPRINT("Missing setting in labnotebook", str=setting)
		return defValue
	endif
End

/// @brief Return a headstage independent setting from the numerical
///        labnotebook of the sweeps in the same RA cycle
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSetting()
Function GetLastSettingIndepSCI(numericalValues, sweepNo, setting, headstage, entrySourceType, [defValue])
	Wave numericalValues
	variable sweepNo
	string setting
	variable defValue, headstage, entrySourceType

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z settings = GetLastSettingSCI(numericalValues, sweepNo, setting, headstage, entrySourceType)

	if(WaveExists(settings))
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	else
		DEBUGPRINT("Missing setting in labnotebook", str=setting)
		return defValue
	endif
End

/// @brief Return a headstage independent setting from the numerical
///        labnotebook of the sweeps in the same RA cycle
///
/// @return the headstage independent setting or `defValue`
///
/// @ingroup LabnotebookQueryFunctions
Function/S GetLastSettingTextIndepRAC(numericalValues, textualValues, sweepNo, setting, entrySourceType, [defValue])
	WAVE numericalValues
	wAVE/T textualValues
	variable sweepNo
	string setting, defValue
	variable entrySourceType

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/T/Z settings = GetLastSettingTextRAC(numericalValues, textualValues, sweepNo, setting, entrySourceType)

	if(WaveExists(settings))
		return settings[GetIndexForHeadstageIndepData(textualValues)]
	else
		DEBUGPRINT("Missing setting in labnotebook", str=setting)
		return defValue
	endif
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
Function/WAVE GetLastSetting(values, sweepNo, setting, entrySourceType)
	wAVE values
	variable sweepNo
	string setting
	variable entrySourceType

	variable first, last, rowIndex, entrySourceTypeIndex, settingCol

	// entries before the first sweep have sweepNo == NaN
	// we can't cache that
	if(IsNaN(sweepNo))
		return GetLastSettingNoCache(values, sweepNo, setting, entrySourceType)
	elseif(!IsValidSweepNumber(sweepNo))
		return $""
	endif

	settingCol = FindDimLabel(values, COLS, setting)

	if(settingCol < 0)
		return $""
	endif

	entrySourceTypeIndex = EntrySourceTypeMapper(entrySourceType)

	if(entrySourceTypeIndex >= NUMBER_OF_LBN_DAQ_MODES)
		return $""
	endif

	WAVE indexWave = GetLBIndexCache(values)

	EnsureLargeEnoughWave(indexWave, minimumSize = sweepNo, dimension = ROWS, initialValue = LABNOTEBOOK_UNCACHED_VALUE)
	EnsureLargeEnoughWave(indexWave, minimumSize = settingCol, dimension = COLS, initialValue = LABNOTEBOOK_UNCACHED_VALUE)
	rowIndex = indexWave[sweepNo][settingCol][entrySourceTypeIndex]

	if(rowIndex >= 0) // entry available and present
		if(IsTextWave(values))
			WAVE/T valuesText = values
			Make/T/FREE/N=(DimSize(values, LAYERS)) statusText = valuesText[rowIndex][settingCol][p]
			return statusText
		else
			Make/D/FREE/N=(DimSize(values, LAYERS)) status = values[rowIndex][settingCol][p]
			return status
		endif
	elseif(rowIndex == LABNOTEBOOK_UNCACHED_VALUE)
		// need to search for it
		WAVE rowCache = GetLBRowCache(values)
		EnsureLargeEnoughWave(rowCache, minimumSize = sweepNo, dimension = ROWS, initialValue = LABNOTEBOOK_GET_RANGE)

		first = rowCache[sweepNo][%first][entrySourceTypeIndex]
		last  = rowCache[sweepNo][%last][entrySourceTypeIndex]

		WAVE/Z settings = GetLastSettingNoCache(values, sweepNo, setting, entrySourceType, \
												first = first, last = last, rowIndex = rowIndex)

		if(WaveExists(settings))
			ASSERT(first >= 0 && last >= 0 && rowIndex >= 0, "invalid return combination from GetLastSettingNoCache")
			rowCache[sweepNo][%first][entrySourceTypeIndex] = first
			rowCache[sweepNo][%last][entrySourceTypeIndex]  = last

			indexWave[sweepNo][settingCol][entrySourceTypeIndex] = rowIndex
		else
			ASSERT(first < 0 || last < 0 || rowIndex < 0, "invalid return combination from GetLastSettingNoCache")
			indexWave[sweepNo][settingCol][entrySourceTypeIndex] = LABNOTEBOOK_MISSING_VALUE
		endif

		return settings
	elseif(rowIndex == LABNOTEBOOK_MISSING_VALUE)
		return $""
	endif

	ASSERT(0, "Unexpected type")
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
///
/// @return a free wave with #LABNOTEBOOK_LAYER_COUNT rows. In case
/// the setting could not be found an invalid wave reference is returned.
///
/// @ingroup LabnotebookQueryFunctions
Function/WAVE GetLastSettingNoCache(values, sweepNo, setting, entrySourceType, [first, last, rowIndex])
	Wave values
	variable sweepNo
	string setting
	variable entrySourceType
	variable &first, &last, &rowIndex

	variable settingCol, numLayers, i, sweepCol, numEntries
	variable firstValue, lastValue, sourceTypeCol, peakResistanceCol, pulseDurationCol
	variable testpulseBlockLength, blockType, hasValidTPPulseDurationEntry
	variable mode

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
			ASSERT(0, "Invalid params")
		endif
	else
		ASSERT(0, "Invalid params")
	endif

	numLayers = DimSize(values, LAYERS)
	settingCol = FindDimLabel(values, COLS, setting)

	if(settingCol <= 0)
		DEBUGPRINT("Could not find the setting", str=setting)
		return $""
	endif

	if(mode == GET_LB_MODE_NONE || mode == GET_LB_MODE_WRITE)
		sweepCol = GetSweepColumn(values)
		FindRange(values, sweepCol, sweepNo, 0, entrySourceType, firstValue, lastValue)

		if(!IsFinite(firstValue) && !IsFinite(lastValue)) // sweep number is unknown
			return $""
		endif
	elseif(mode == GET_LB_MODE_READ)
		firstValue = first
		lastValue  = last
	endif

	ASSERT(firstValue <= lastValue, "Invalid value range")

	if(mode == GET_LB_MODE_WRITE)
		first = firstValue
		last  = lastValue
	endif

	if(IsTextWave(values))
		WAVE/T textualValues = values
		Make/FREE/N=(numLayers)/T statusText
		Make/FREE/N=(numLayers) lengths

		for(i = lastValue; i >= firstValue; i -= 1)
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
					DEBUGPRINT("Skipping the given row as sourceType is available and not matching: ", var=i)
					continue
				endif
			endif

			statusText[] = textualValues[i][settingCol][p]
			lengths[]	= strlen(statusTexT[p])

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

			if(IsFinite(entrySourceType))
				if(!sourceTypeCol)
					sourceTypeCol = FindDimLabel(numericalValues, COLS, "EntrySourceType")
				endif

				if(sourceTypeCol < 0 || !IsFinite(numericalValues[i][sourceTypeCol][0]))
					// no source type information available but it is requested
					// use a heuristic
					//
					// Since 60f4a9d9 (TP documenting is implemented using David
					// Reid's documenting functions, 2014-07-28) we have one
					// row for the testpulse which holds "TP Peak Resistance".
					// Since dd49bf47 (Document the testpulse settings in the
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
						status[] = numericalValues[i][pulseDurationCol][p]
						WaveStats/Q/M=1 status
						hasValidTPPulseDurationEntry = (V_numNaNs != numLayers)
					else
						hasValidTPPulseDurationEntry = 0
					endif

					// Since dd49bf47 (Document the testpulse settings in the
					// labnotebook, 2015-07-28) we can have a "TP Pulse Duration"
					// entry but no "TP Peak Resistance" entry iff the user only
					// acquired sweep data but never TP.
					if(peakResistanceCol < 0)
						blockType = DATA_ACQUISITION_MODE
					elseif(hasValidTPPulseDurationEntry)
						// if the previous row has a "TP Peak Resistance" entry we know that this is a testpulse block
						status[] = numericalValues[i - 1][peakResistanceCol][p]
						WaveStats/Q/M=1 status
						if(V_numNaNs != numLayers)
							blockType = TEST_PULSE_MODE
							testpulseBlockLength = 1
						else
							blockType = DATA_ACQUISITION_MODE
						endif
					else // no match, maybe old format
						status[] = numericalValues[i][peakResistanceCol][p]
						WaveStats/Q/M=1 status
						if(V_numNaNs != numLayers)
							blockType = TEST_PULSE_MODE
							testpulseBlockLength = 0
						else
							blockType = DATA_ACQUISITION_MODE
						endif
					endif

					if(entrySourceType == DATA_ACQUISITION_MODE && blockType == TEST_PULSE_MODE)
						// testpulse block starts but DAQ was requested
						// two row long testpulse block, skip it
						i -= testpulseBlockLength
						DEBUGPRINT("Skipping the testpulse block as DAQ is requested, testpulseBlockLength:", var=testPulseBlockLength)
						continue
					elseif(entrySourceType == TEST_PULSE_MODE && blockType == DATA_ACQUISITION_MODE)
						// sweep block starts but TP was requested
						// as the sweep block occupies always the first blocks
						// we now know that we did not find the entries
						DEBUGPRINT("Skipping the DAQ block as testpulse is requested, as this is the last block, we can also return.")
						return $""
					endif
				elseif(entrySourceType != numericalValues[i][sourceTypeCol][0])
					// labnotebook has entrySourceType and it is not matching
					DEBUGPRINT("Skipping the given row as sourceType is available and not matching: ", var=i)
					continue
				endif
			endif

			status[] = numericalValues[i][settingCol][p]
			WaveStats/Q/M=1 status

			// return if at least one entry is not NaN
			if(V_numNaNs != numLayers)
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
Function/WAVE GetLastSettingTextRAC(numericalValues, textualValues, sweepNo, setting, entrySourceType)
	WAVE numericalValues
	WAVE/T textualValues
	variable sweepNo
	string setting
	variable entrySourceType

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
Function/WAVE GetLastSettingRAC(numericalValues, sweepNo, setting, entrySourceType)
	WAVE numericalValues
	variable sweepNo
	string setting
	variable entrySourceType

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
Function/WAVE GetLastSettingIndepEachRAC(numericalValues, sweepNo, setting, entrySourceType, [defValue])
	WAVE numericalValues
	variable sweepNo
	string setting
	variable entrySourceType, defValue

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

	WaveStats/Q/M=1 result
	if(V_numNaNs == numSweeps)
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
Function/WAVE GetLastSettingTextIndepEachRAC(numericalValues, textualValues, sweepNo, setting, entrySourceType, [defValue])
	WAVE numericalValues
	WAVE/T textualValues
	variable sweepNo
	string setting
	variable entrySourceType
	string defValue

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
Function/WAVE GetLastSettingEachRAC(numericalValues, sweepNo, setting, headstage, entrySourceType)
	WAVE numericalValues
	variable sweepNo
	string setting
	variable headstage, entrySourceType

	variable i, numSweeps

	ASSERT(headstage >= 0 && headstage < NUM_HEADSTAGES, "Invalid headstage")

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

	WaveStats/Q/M=1 result
	if(V_numNaNs == numSweeps)
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
Function/WAVE GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, setting, headstage, entrySourceType)
	WAVE numericalValues
	WAVE/T textualValues
	variable sweepNo
	string setting
	variable headstage, entrySourceType

	variable i, numSweeps

	ASSERT(headstage >= 0 && headstage < NUM_HEADSTAGES, "Invalid headstage")

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
Function/WAVE GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, setting, headstage, entrySourceType)
	WAVE numericalValues
	WAVE/T textualValues
	variable sweepNo
	string setting
	variable headstage, entrySourceType

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
Function/WAVE GetLastSettingSCI(numericalValues, sweepNo, setting, headstage, entrySourceType)
	WAVE numericalValues
	variable sweepNo
	string setting
	variable headstage, entrySourceType

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
Function/WAVE GetLastSettingIndepEachSCI(numericalValues, sweepNo, setting, headstage, entrySourceType, [defValue])
	WAVE numericalValues
	variable sweepNo
	string setting
	variable headstage, entrySourceType, defValue

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

	WaveStats/Q/M=1 result
	if(V_numNaNs == numSweeps)
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
Function/WAVE GetLastSettingTextIndepEachSCI(numericalValues, textualValues, sweepNo, headstage, setting, entrySourceType, [defValue])
	WAVE numericalValues
	WAVE/T textualValues
	variable sweepNo
	string setting
	variable headstage, entrySourceType
	string defValue

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
Function/WAVE GetLastSettingEachSCI(numericalValues, sweepNo, setting, headstage, entrySourceType)
	WAVE numericalValues
	variable sweepNo
	string setting
	variable headstage, entrySourceType

	variable i, numSweeps

	ASSERT(headstage >= 0 && headstage < NUM_HEADSTAGES, "Invalid headstage")

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

	WaveStats/Q/M=1 result
	if(V_numNaNs == numSweeps)
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
Function/WAVE GetLastSettingTextEachSCI(numericalValues, textualValues, sweepNo, setting, headstage, entrySourceType)
	WAVE numericalValues
	WAVE/T textualValues
	variable sweepNo
	string setting
	variable headstage, entrySourceType

	variable i, numSweeps

	ASSERT(headstage >= 0 && headstage < NUM_HEADSTAGES, "Invalid headstage")

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
static Function/WAVE GetNonEmptyLBNRows(labnotebookValues, setting)
   WAVE labnotebookValues
   string setting

   variable col

   col = FindDimLabel(labnotebookValues, COLS, setting)

   if(col < 0)
	   return $""
   endif

   return FindIndizes(labnotebookValues, col = col, prop = PROP_NON_EMPTY, \
					  startLayer = 0, endLayer = DimSize(labnotebookValues, LAYERS) - 1)
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
Function/WAVE GetSweepsWithSetting(labnotebookValues, setting)
	WAVE labnotebookValues
	string setting

	variable sweepCol

	WAVE/Z indizes = GetNonEmptyLBNRows(labnotebookValues, setting)
	if(!WaveExists(indizes))
		return $""
	endif

	sweepCol = GetSweepColumn(labnotebookValues)

	Make/FREE/N=(DimSize(indizes, ROWS)) sweeps = labnotebookValues[indizes[p]][sweepCol][0]

	return DeleteDuplicates(sweeps)
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
Function/WAVE GetLastSweepWithSetting(numericalValues, setting, sweepNo)
	WAVE numericalValues
	string setting
	variable &sweepNo

	variable idx

	sweepNo = NaN
	ASSERT(WaveType(numericalValues), "Can only work with numeric waves")

	WAVE/Z indizes = GetNonEmptyLBNRows(numericalValues, setting)
	if(!WaveExists(indizes))
		return $""
	endif

	idx = indizes[DimSize(indizes, ROWS) - 1]
	Make/FREE/N=(DimSize(numericalValues, LAYERS)) data = numericalValues[idx][%$setting][p]
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
Function GetLastSweepWithSettingIndep(numericalValues, setting, sweepNo, [defValue])
	WAVE numericalValues
	string setting
	variable &sweepNo
	variable defValue

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z settings = GetLastSweepWithSetting(numericalValues, setting, sweepNo)

	if(WaveExists(settings))
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	else
		DEBUGPRINT("Missing setting in labnotebook", str=setting)
		return defValue
	endif
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
Function/WAVE GetLastSweepWithSettingText(textualValues, setting, sweepNo)
	WAVE/T textualValues
	string setting
	variable &sweepNo

	variable idx

	sweepNo = NaN
	ASSERT(!WaveType(textualValues), "Can only work with text waves")

	WAVE/Z indizes = GetNonEmptyLBNRows(textualValues, setting)
	if(!WaveExists(indizes))
		return $""
	endif

	idx = indizes[DimSize(indizes, ROWS) - 1]
	Make/FREE/T/N=(DimSize(textualValues, LAYERS)) data = textualValues[idx][%$setting][p]
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
Function/S GetLastSweepWithSettingTextI(numericalValues, setting, sweepNo, [defValue])
	WAVE numericalValues
	string setting
	variable &sweepNo
	string defValue

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/T/Z settings = GetLastSweepWithSettingText(numericalValues, setting, sweepNo)

	if(WaveExists(settings))
		return settings[GetIndexForHeadstageIndepData(numericalValues)]
	else
		DEBUGPRINT("Missing setting in labnotebook", str=setting)
		return defValue
	endif
End

/// @brief Returns a list of all devices, e.g. "ITC18USB_Dev_0;..."
///
/// @param activeOnly [optional, defaults to false] restrict the list to devices
///                   with an existing datafolder returned by `GetDevicePathAsString(device)`
Function/S GetAllDevices([activeOnly])
	variable activeOnly

	variable i, j, numTypes, numNumbers
	string type, number, device
	string path, list = ""

	if(ParamIsDefault(activeOnly))
		activeOnly = 0
	else
		activeOnly = !!activeOnly
	endif

	path = GetITCDevicesFolderAsString()

	if(!DataFolderExists(path))
		return ""
	endif

	numTypes   = ItemsInList(DEVICE_TYPES_ITC)
	numNumbers = ItemsInList(DEVICE_NUMBERS)
	for(i = 0; i < numTypes; i += 1)
		type = StringFromList(i, DEVICE_TYPES_ITC)

		for(j = 0; j < numNumbers ; j += 1)
			number = StringFromList(j, DEVICE_NUMBERS)
			device = BuildDeviceString(type, number)
			path   = GetDevicePathAsString(device)

			if(!activeOnly || DataFolderExists(path))
				list = AddListItem(device, list, ";", inf)
			endif
		endfor
	endfor

	return list
End

/// @brief Returns a list of all devices, e.g. "ITC18USB_Dev_0;", which have acquired data.
///
/// @param contentType [optional, defaults to CONTENT_TYPE_SWEEP] type of
///                    content to look for, one of @ref CONTENT_TYPES
Function/S GetAllDevicesWithContent([contentType])
	variable contentType

	variable i, numDevices
	string deviceList, device, dataPath, testPulsePath
	string list = ""

	if(ParamIsDefault(contentType))
		contentType = CONTENT_TYPE_SWEEP
	endif

	deviceList = GetAllDevices(activeOnly = 1)

	numDevices = ItemsInList(deviceList)
	for(i = 0; i < numDevices; i += 1)
		device        = StringFromList(i, deviceList)
		dataPath      = GetDeviceDataPathAsString(device)
		testPulsePath = GetDeviceTestPulseAsString(device)

		if(contentType & CONTENT_TYPE_SWEEP                   \
		   && DataFolderExists(dataPath)                      \
		   && CountObjects(dataPath, COUNTOBJECTS_WAVES) > 0)
			list = AddListItem(device, list, ";", inf)
			continue
		endif

		if(contentType & CONTENT_TYPE_TPSTORAGE                                     \
		   && DataFolderExists(testPulsePath)                                       \
		   && ItemsInList(GetListOfObjects($testPulsePath, TP_STORAGE_REGEXP)) > 0)
			list = AddListItem(device, list, ";", inf)
			continue
		endif
	endfor

	return list
End

/// @brief Convenience wrapper for KillOrMoveToTrashPath()
Function KillOrMoveToTrash([wv, dfr])
	WAVE/Z wv
	DFREF dfr

	if(!ParamIsDefault(wv) && WaveExists(wv))
		KillOrMoveToTrashPath(GetWavesDataFolder(wv, 2))
	endif

	if(!ParamIsDefault(dfr) && DataFolderExistsDFR(dfr))
		KillOrMoveToTrashPath(GetDataFolder(1, dfr))
	endif
End

/// @brief Delete a datafolder or wave. If this is not possible, because Igor
/// has locked the file, the wave or datafolder is moved into a trash folder
/// named `root:mies:trash_$digit`.
///
/// The trash folders will be removed, if possible, from KillTemporaries().
///
/// @param path absolute path to a datafolder or wave
Function KillOrMoveToTrashPath(path)
	string path

	string dest

	if(DataFolderExists(path))
		KillDataFolder/Z $path

		if(!V_flag)
			return NaN
		endif

		DFREF tmpDFR = GetUniqueTempPath()
		dest = RemoveEnding(GetDataFolder(1, tmpDFR), ":")
		MoveDataFolder $path, $dest
	elseif(WaveExists($path))
		KillWaves/F/Z $path

		WAVE/Z wv = $path
		if(!WaveExists(wv))
			return NaN
		endif

		DFREF tmpDFR = GetUniqueTempPath()
		MoveWave wv, tmpDFR
	else
		DEBUGPRINT("Ignoring the datafolder/wave as it does not exist", str=path)
	endif
End

/// @brief Return a wave reference wave with all single column waves of the given channel type
///
/// Holds invalid wave refs for non-existing entries.
///
/// @param sweepDFR    datafolder reference with 1D sweep data
/// @param channelType One of @ref ITC_XOP_CHANNEL_CONSTANTS
///
/// @see GetITCDataSingleColumnWave() or SplitSweepIntoComponents()
Function/WAVE GetITCDataSingleColumnWaves(sweepDFR, channelType)
	DFREF sweepDFR
	variable channelType

	Make/FREE/WAVE/N=(GetNumberFromType(itcVar=channelType)) matches = GetITCDataSingleColumnWave(sweepDFR, channelType, p)

	return matches
End

/// @brief Return a 1D data wave previously created by SplitSweepIntoComponents()
///
/// Returned wave reference can be invalid.
///
/// @param sweepDFR      datafolder holding 1D waves
/// @param channelType   One of @ref ITC_XOP_CHANNEL_CONSTANTS
/// @param channelNumber channel number
/// @param splitTTLBits  [optional, defaults to false] return a single bit of the TTL wave
/// @param ttlBit        [optional] number specifying the TTL bit
Function/WAVE GetITCDataSingleColumnWave(sweepDFR, channelType, channelNumber, [splitTTLBits, ttlBit])
	DFREF sweepDFR
	variable channelType, channelNumber
	variable splitTTLBits, ttlBit

	string wvName

	if(ParamIsDefault(splitTTLBits))
		splitTTLBits = 0
	else
		splitTTLBits = !!splitTTLBits
	endif

	ASSERT(ParamIsDefault(splitTTLBits) + ParamIsDefault(ttlBit) != 1, "Expected both or none of splitTTLBits and ttlBit")
	ASSERT(channelNumber < GetNumberFromType(itcVar=channelType), "Invalid channel index")

	wvName = StringFromList(channelType, ITC_CHANNEL_NAMES) + "_" + num2str(channelNumber)

	if(channelType == ITC_XOP_CHANNEL_TYPE_TTL && splitTTLBits)
		wvName += "_" + num2str(ttlBit)
	endif

	WAVE/Z/SDFR=sweepDFR wv = $wvName

	return wv
End

/// @brief Check if the given sweep number is valid
Function IsValidSweepNumber(sweepNo)
	variable sweepNo

	return IsInteger(sweepNo) && sweepNo >= 0
End

/// @brief Check if the given epoch number is valid
Function IsValidEpochNumber(epochNo)
	variable epochNo

	return IsInteger(epochNo) && epochNo >= 0 && epochNo <= SEGMENT_TYPE_WAVE_LAST_IDX
End

/// @brief Returns the config wave for a given sweep wave
Function/Wave GetConfigWave(sweepWave)
	Wave sweepWave

	string name = "Config_" + NameOfWave(sweepWave)
	Wave/SDFR=GetWavesDataFolderDFR(sweepWave) config = $name
	ASSERT(IsValidConfigWave(config),"Invalid config wave")

	return config
End

/// @brief Returns the, possibly non existing, sweep data wave for the given sweep number
Function/Wave GetSweepWave(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	Wave/Z/SDFR=GetDeviceDataPath(panelTitle) wv = $GetSweepWaveName(sweepNo)

	return wv
End

/// @brief Return the sweep wave name
Function/S GetSweepWaveName(sweepNo)
	variable sweepNo

	return "Sweep_" + num2str(sweepNo)
End

/// @brief Returns the sampling interval of the sweep
/// in microseconds (1e-6s)
Function GetSamplingInterval(config)
	Wave config

	ASSERT(IsValidConfigWave(config), "Expected a valid config wave")

	// from ITCConfigAllChannels help file:
	// Third Column  = SamplingInterval:  integer value for sampling interval in microseconds (minimum value - 5 us)
	Duplicate/D/R=[][2]/FREE config samplingInterval

	// The sampling interval is the same for all channels
	ASSERT(WaveMax(samplingInterval) == WaveMin(samplingInterval),"Expected constant sample interval for all channels")
	return samplingInterval[0]
End

/// @brief Returns the data offset of the sweep in points
Function GetDataOffset(config)
	Wave config

	ASSERT(IsValidConfigWave(config),"Expected a valid config wave")

	Duplicate/D/R=[][4]/FREE config, offsets

	// The data offset is the same for all channels
	ASSERT(WaveMax(offsets) == WaveMin(offsets), "Expected constant data offset for all channels")
	return offsets[0]
End

/// @brief Write the given property to the config wave
///
/// @note Please add new properties as required
/// @param config configuration wave
/// @param samplingInterval sampling interval in microseconds (1e-6s)
Function UpdateSweepConfig(config, [samplingInterval])
	Wave config
	variable samplingInterval

	ASSERT(IsFinite(samplingInterval), "samplingInterval must be finite")
	config[][2] = samplingInterval
End

/// @brief Parse a device string of the form X_DEV_Y, where X is from @ref DEVICE_TYPES_ITC
/// and Y from @ref DEVICE_NUMBERS.
///
/// Returns the result in deviceType and deviceNumber.
/// Currently the parsing is successfull if X and Y are non-empty.
/// @param[in]  device       input device string X_DEV_Y
/// @param[out] deviceType   returns the device type X
/// @param[out] deviceNumber returns the device number Y
/// @returns one on successfull parsing, zero on error
threadsafe Function ParseDeviceString(device, deviceType, deviceNumber)
	string device
	string &deviceType, &deviceNumber

	if(isEmpty(device))
		return 0
	endif

	deviceType   = StringFromList(0,device,"_")
	deviceNumber = StringFromList(2,device,"_")

	return !isEmpty(deviceType) && !isEmpty(deviceNumber)
End

/// @brief Builds the common device string X_DEV_Y, e.g. ITC1600_DEV_O and friends
Function/S BuildDeviceString(deviceType, deviceNumber)
	string deviceType, deviceNumber

	ASSERT(!isEmpty(deviceType) && !isEmpty(deviceNumber), "empty device type or number");
	return deviceType + "_Dev_" + deviceNumber
End

/// @brief Create a vertically tiled graph for displaying AD and DA channels
///
/// For preservering the axis scaling callers should do the following:
/// \rst
/// .. code-block:: igorpro
///
/// 	WAVE ranges = GetAxesRanges(graph)
///
/// 	CreateTiledChannelGraph()
///
///		SetAxesRanges(graph, ranges)
///	\endrst
///
/// @param graph           window
/// @param config          ITC config wave
/// @param sweepNo         number of the sweep
/// @param numericalValues numerical labnotebook wave
/// @param textualValues   textual labnotebook wave
/// @param tgs             settings for tuning the display, see @ref TiledGraphSettings
/// @param sweepDFR        top datafolder to splitted 1D sweep waves
/// @param axisLabelCache  store existing vertical axis labels
/// @param traceIndex      [internal use only] set to zero on the first call in a row of successive calls
/// @param channelSelWave  [optional] channel selection wave
Function CreateTiledChannelGraph(graph, config, sweepNo, numericalValues,  textualValues, tgs, sweepDFR, axisLabelCache, traceIndex, [channelSelWave])
	string graph
	WAVE config
	variable sweepNo
	WAVE numericalValues
	WAVE/T textualValues
	STRUCT TiledGraphSettings &tgs
	DFREF sweepDFR
	WAVE/T axisLabelCache
	variable &traceIndex
	WAVE/Z channelSelWave

	variable red, green, blue, axisIndex, numChannels, offset
	variable numDACs, numADCs, numTTLs, i, j, k, hasPhysUnit, slotMult
	variable moreData, low, high, step, spacePerSlot, chan, numSlots, numHorizWaves, numVertWaves, idx
	variable numTTLBits, colorIndex, totalVertBlocks, headstage
	variable delayOnsetUser, delayOnsetAuto, delayTermination, delaydDAQ, dDAQEnabled, oodDAQEnabled
	variable stimSetLength, samplingInt, xRangeStart, xRangeEnd, first, last, count
	variable numDACsOriginal, numADCsOriginal, numTTLsOriginal, numRegions, numEntries, numRangesPerEntry
	variable totalXRange = NaN

	string trace, traceType, channelID, axisLabel, entry, range
	string unit, name, str, vertAxis, oodDAQRegionsAll, dDAQActiveHeadstageAll, horizAxis

	ASSERT(!isEmpty(graph), "Empty graph")
	ASSERT(IsFinite(sweepNo), "Non-finite sweepNo")

	WAVE ADCs = GetADCListFromConfig(config)
	WAVE DACs = GetDACListFromConfig(config)
	WAVE TTLs = GetTTLListFromConfig(config)

	Duplicate/FREE ADCs, ADCsOriginal
	Duplicate/FREE DACs, DACsOriginal
	Duplicate/FREE TTLs, TTLsOriginal
	numDACsOriginal = DimSize(DACs, ROWS)
	numADCsOriginal = DimSize(ADCs, ROWS)
	numTTLsOriginal = DimSize(TTLs, ROWS)

	RemoveDisabledChannels(channelSelWave, ADCs, DACs, numericalValues, sweepNo)
	numDACs = DimSize(DACs, ROWS)
	numADCs = DimSize(ADCs, ROWS)
	numTTLs = DimSize(TTLs, ROWS)

	WAVE/Z statusHS           = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)
	WAVE/Z ttlRackZeroChannel = GetLastSetting(numericalValues, sweepNo, "TTL rack zero bits", DATA_ACQUISITION_MODE)
	WAVE/Z ttlRackOneChannel  = GetLastSetting(numericalValues, sweepNo, "TTL rack one bits", DATA_ACQUISITION_MODE)

	if(tgs.splitTTLBits && numTTLs > 0)
		if(!WaveExists(ttlRackZeroChannel) && !WaveExists(ttlRackOneChannel))
			print "Turning off tgs.splitTTLBits as some labnotebook entries could not be found"
			ControlWindowToFront()
			tgs.splitTTLBits = 0
		elseif(tgs.overlayChannels)
			print "Turning off tgs.splitTTLBits as it is overriden by tgs.overlayChannels"
			ControlWindowToFront()
			tgs.splitTTLBits = 0
		endif

		if(tgs.splitTTLBits)
			idx = GetIndexForHeadstageIndepData(numericalValues)
			if(WaveExists(ttlRackZeroChannel))
				numTTLBits += PopCount(ttlRackZeroChannel[idx])
			 endif
			if(WaveExists(ttlRackOneChannel))
				numTTLBits += PopCount(ttlRackOneChannel[idx])
			 endif
		endif
	endif

	// The display order from top to bottom is DA/AD/TTL
	// with increasing channel number
	//
	// idea:
	// - we have 100% space for all axes
	// - AD axes should occupy four times the space of DA/TTL channels.
	// - So DA/TTL occupy one slot, AD occupy four slots
	// - between each axes we want GRAPH_DIV_SPACING clear space
	// - Count the number of vertical blocks (= number of vertical axis in the first column) and slots to be used
	// - Derive the space per slot
	// - For overlay channels we reserve only one slot times slot multiplier
	//   per channel
	if(tgs.displayDAC && numDACs > 0)
		if(tgs.overlayChannels)
			numSlots        += 1
			totalVertBlocks += 1
		else
			numSlots        += numDACs
			totalVertBlocks += numDACs
		endif
	endif
	if(tgs.displayADC && numADCs > 0)

		if(tgs.overlayChannels)
			numSlots        += ADC_SLOT_MULTIPLIER
			totalVertBlocks += 1
		else
			numSlots        += ADC_SLOT_MULTIPLIER * numADCs
			totalVertBlocks += numADCs
		endif
	endif
	if(tgs.displayTTL && numTTLs > 0)
		if(tgs.overlayChannels)
			numSlots        += 1
			totalVertBlocks += 1
		else
			if(tgs.splitTTLBits)
				numSlots += numTTLBits
				totalVertBlocks += numTTLBits
			else
				numSlots += numTTLs
				totalVertBlocks += numTTLs
			endif
		endif
	endif

	spacePerSlot = (1.0 - (totalVertBlocks - 1) * GRAPH_DIV_SPACING) / numSlots

	sprintf str, "numSlots=%d, totalVertBlocks=%d, spacePerSlot=%g", numSlots, totalVertBlocks, spacePerSlot
	DEBUGPRINT(str)

	high = 1.0

	dDAQEnabled   = GetLastSettingIndep(numericalValues, sweepNo, "Distributed DAQ", DATA_ACQUISITION_MODE, defValue=0)
	oodDAQEnabled = GetLastSettingIndep(numericalValues, sweepNo, "Optimized Overlap dDAQ", DATA_ACQUISITION_MODE, defValue=0)

	if(tgs.dDAQDisplayMode && !(dDAQEnabled || oodDAQEnabled))
		printf "Distributed DAQ display mode turned off as no dDAQ data could be found.\r"
		tgs.dDAQDisplayMode = 0
	endif

	WAVE/Z/T oodDAQRegions = GetLastSetting(textualValues, sweepNo, "oodDAQ regions", DATA_ACQUISITION_MODE)

	if(tgs.dDAQDisplayMode && oodDAQEnabled && !WaveExists(oodDAQRegions))
		printf "Distributed DAQ display mode turned off as no oodDAQ regions could be found in the labnotebook.\r"
		tgs.dDAQDisplayMode = 0
	endif

	if(tgs.dDAQDisplayMode)
		stimSetLength = GetLastSettingIndep(numericalValues, sweepNo, "Stim set length", DATA_ACQUISITION_MODE)
		DEBUGPRINT("Stim set length (labnotebook, NaN for oodDAQ)", var=stimSetLength)

		samplingInt = GetSamplingInterval(config) * 1e-3

		// dDAQ data taken with versions prior to
		// 125a5407 (DC_PlaceDataInITCDataWave: Document all other settings from the DAQ groupbox, 2015-11-26)
		// does not have the delays stored in the labnotebook
		delayOnsetUser   = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE, defValue=0) / samplingInt
		delayOnsetAuto   = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE, defValue=0) / samplingInt
		delayTermination = GetLastSettingIndep(numericalValues, sweepNo, "Delay termination", DATA_ACQUISITION_MODE, defValue=0) / samplingInt
		delaydDAQ        = GetLastSettingIndep(numericalValues, sweepNo, "Delay distributed DAQ", DATA_ACQUISITION_MODE, defValue=0) / samplingInt

		sprintf str, "delayOnsetUser=%g, delayOnsetAuto=%g, delayTermination=%g, delaydDAQ=%g", delayOnsetUser, delayOnsetAuto, delayTermination, delaydDAQ
		DEBUGPRINT(str)

		if(oodDAQEnabled)
			numEntries = DimSize(oodDAQRegions, ROWS)
			oodDAQRegionsAll = ""
			totalXRange = 0

			for(i = 0; i < numEntries; i += 1)
				// use only the selected region if requested
				if(tgs.dDAQHeadstageRegions >= 0 && tgs.dDAQHeadstageRegions < NUM_HEADSTAGES && tgs.dDAQHeadstageRegions != i)
					continue
				endif

				entry = RemoveEnding(oodDAQRegions[i], ";")
				numRangesPerEntry = ItemsInList(entry)
				for(j = 0; j < numRangesPerEntry; j += 1)
					range = StringFromList(j, entry)
					oodDAQRegionsAll = AddListItem(range, oodDAQRegionsAll, ";", Inf)

					xRangeStart = str2num(StringFromList(0, range, "-"))
					xRangeEnd = str2num(StringFromList(1, range, "-"))
					totalXRange += (xRangeEnd - XRangeStart) / samplingInt
				endfor
			endfor

			numRegions = ItemsInList(oodDAQRegionsAll)
			sprintf str, "oodDAQRegions (%d) concatenated: _%s_, totalRange=%g", numRegions, oodDAQRegionsAll, totalXRange
			DEBUGPRINT(str)
		else
			dDAQActiveHeadstageAll = ""

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHS[i])
					continue
				endif

				if(tgs.dDAQHeadstageRegions >= 0 && tgs.dDAQHeadstageRegions < NUM_HEADSTAGES && tgs.dDAQHeadstageRegions != i)
					continue
				endif

				dDAQActiveHeadstageAll = AddListItem(num2str(i), dDAQActiveHeadstageAll, ";", Inf)
			endfor

			numRegions = ItemsInList(dDAQActiveHeadstageAll)
			sprintf str, "dDAQRegions (%d) concatenated: _%s_", numRegions, dDAQActiveHeadstageAll
			DEBUGPRINT(str)
		endif
	endif

	WAVE clampModes  = GetLastSetting(numericalValues, sweepNo, "Clamp Mode", DATA_ACQUISITION_MODE)
	WAVE/Z statusDAC = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z statusADC = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)

	MAKE/FREE/B/N=(NUM_CHANNEL_TYPES) channelTypes
	channelTypes[0] = ITC_XOP_CHANNEL_TYPE_DAC
	channelTypes[1] = ITC_XOP_CHANNEL_TYPE_ADC
	channelTypes[2] = ITC_XOP_CHANNEL_TYPE_TTL

	MAKE/FREE/B/N=(NUM_CHANNEL_TYPES) activeChanCount = 0

	do
		moreData = 0
		// iterate over all channel types in order DA, AD, TTL
		// and take the first active channel from the list of channels per type
		for(i = 0; i < NUM_CHANNEL_TYPES; i += 1)
			switch(channelTypes[i])
				case ITC_XOP_CHANNEL_TYPE_DAC:
					if(!tgs.displayDAC)
						continue
					endif

					WAVE/Z status    = statusDAC
					WAVE channelList = DACs
					channelID        = "DA"
					hasPhysUnit      = 1
					slotMult         = 1
					numHorizWaves    = tgs.dDAQDisplayMode ? numRegions : 1
					numVertWaves     = 1
					numChannels      = numDACs
					break
				case ITC_XOP_CHANNEL_TYPE_ADC:
					if(!tgs.displayADC)
						continue
					endif

					WAVE/Z status    = statusADC
					WAVE channelList = ADCs
					channelID        = "AD"
					hasPhysUnit      = 1
					slotMult         = ADC_SLOT_MULTIPLIER
					numHorizWaves    = tgs.dDAQDisplayMode ? numRegions : 1
					numVertWaves     = 1
					numChannels      = numADCs
					break
				case ITC_XOP_CHANNEL_TYPE_TTL:
					if(!tgs.displayTTL)
						continue
					endif

					WAVE/Z status    = $""
					WAVE channelList = TTLs
					channelID        = "TTL"
					hasPhysUnit      = 0
					slotMult         = 1
					numHorizWaves    = 1
					numVertWaves     = tgs.splitTTLBits ? NUM_TTL_BITS_PER_RACK : 1
					numChannels      = numTTLs
					break
			endswitch

			if(DimSize(channelList, ROWS) == 0)
				continue
			endif

			moreData = 1
			chan = channelList[0]
			DeletePoints/M=(ROWS) 0, 1, channelList

			if(WaveExists(status))
				headstage = GetRowIndex(status, val=chan)
			else
				headstage = NaN
			endif

			// number of vertically distributed
			// waves per channel type
			for(j = 0; j < numVertWaves; j += 1)

				if(!cmpstr(channelID, "TTL") && tgs.splitTTLBits)
					name = channelID + num2str(chan) + "_" + num2str(j)
				else
					name = channelID + num2str(chan)
				endif

				DFREF singleSweepDFR = GetSingleSweepFolder(sweepDFR, sweepNo)

				ASSERT(DataFolderExistsDFR(singleSweepDFR), "Missing singleSweepDFR")

				WAVE/Z wv = GetITCDataSingleColumnWave(singleSweepDFR, channelTypes[i], chan, splitTTLBits=tgs.splitTTLBits, ttlBit=j)
				if(!WaveExists(wv))
					continue
				endif

				DEBUGPRINT("")
				first = 0

				// number of horizontally distributed
				// waves per channel type
				for(k = 0; k < numHorizWaves; k += 1)

					vertAxis = VERT_AXIS_BASE_NAME + num2str(j) + "_" + HORIZ_AXIS_BASE_NAME + num2str(k) + "_" + channelID

					if(!tgs.overlayChannels)
						vertAxis   += "_" + num2str(chan)
						traceType   = name
					else
						traceType   = channelID
					endif

					if(tgs.dDAQDisplayMode && channelTypes[i] != ITC_XOP_CHANNEL_TYPE_TTL) // TTL channels don't have dDAQ mode

						if(dDAQEnabled)
							// fallback to manual calculation
							// for versions prior to 17b49b63 (DC_PlaceDataInITCDataWave: Document stim set length, 2016-05-12)
							if(!IsFinite(stimSetLength))
								stimSetLength = (DimSize(wv, ROWS) - (delayOnsetUser + delayOnsetAuto + delayTermination + delaydDAQ * (numADCs - 1))) /  numADCs
								DEBUGPRINT("Stim set length (manually calculated)", var=stimSetLength)
							endif

							xRangeStart = delayOnsetUser + delayOnsetAuto + str2num(StringFromList(k, dDAQActiveHeadstageAll)) * (stimSetLength + delaydDAQ)
							xRangeEnd   = xRangeStart + stimSetLength

							// initial total x range once, the stimsets have all the same length for dDAQ
							if(!IsFinite(totalXRange))
								totalXRange = (xRangeEnd - XRangeStart) * numHorizWaves
							endif
						elseif(oodDAQEnabled)
							/// @sa GetSweepSettingsTextKeyWave for the format
							/// we need points here with taking the onset delays into account
							xRangeStart = str2num(StringFromList(0, StringFromList(k, oodDAQRegionsAll, ";"), "-"))
							xRangeEnd   = str2num(StringFromList(1, StringFromList(k, oodDAQRegionsAll, ";"), "-"))

							sprintf str, "begin[ms] = %g, end[ms] = %g", xRangeStart, xRangeEnd
							DEBUGPRINT(str)

							xRangeStart = delayOnsetUser + delayOnsetAuto + xRangeStart / samplingInt
							xRangeEnd   = delayOnsetUser + delayOnsetAuto + xRangeEnd / samplingInt
						endif
					else
						xRangeStart = NaN
						xRangeEnd   = NaN
					endif

					if(tgs.dDAQDisplayMode && oodDAQEnabled && channelTypes[i] != ITC_XOP_CHANNEL_TYPE_TTL)
						offset = -(delayOnsetUser + delayOnsetAuto) * samplingInt
					else
						offset = 0.0
					endif

					if(DimOffset(wv, ROWS) != offset)
						SetScale/P x, offset, DimDelta(wv, ROWS), WaveUnits(wv, ROWS), wv
					endif

					trace = "trace" + num2str(traceIndex)
					traceIndex += 1
					sprintf str, "i=%d, j=%d, k=%d, vertAxis=%s, traceType=%s, name=%s", i, j, k, vertAxis, traceType, name
					DEBUGPRINT(str)

					if(!IsFinite(xRangeStart) && !IsFinite(XRangeEnd))
						AppendToGraph/W=$graph/L=$vertAxis wv[][0]/TN=$trace
					else
						horizAxis = vertAxis + "_b"
						AppendToGraph/W=$graph/L=$vertAxis/B=$horizAxis wv[xRangeStart, xRangeEnd][0]/TN=$trace
						first = first
						last  = first + (xRangeEnd - xRangeStart) / totalXRange
						ModifyGraph/W=$graph axisEnab($horizAxis)={first, min(last, 1.0)}
						first += (xRangeEnd - xRangeStart) / totalXRange

						sprintf str, "horiz axis: stimset=[%d, %d] aka (%g, %g)", xRangeStart, xRangeEnd, pnt2x(wv,xRangeStart), pnt2x(wv,xRangeEnd)
						DEBUGPRINT(str)
					endif

					ModifyGraph/W=$graph tickUnit($vertAxis)=1

					if(activeChanCount[i] == 0 || !tgs.OverlayChannels)
						low = max(high - slotMult * spacePerSlot, 0)
						sprintf str, "vert axis=[%g, %g]", low, high
						DEBUGPRINT(str)
						ModifyGraph/W=$graph axisEnab($vertAxis) = {low, high}
					endif

					if(k == 0) // first column, add labels
						if(hasPhysUnit)
							unit = AFH_GetChannelUnit(config, chan, channelTypes[i])
						else
							unit = "a.u."
						endif

						axisLabel = traceType + "\r(" + unit + ")"

						FindValue/TXOP=4/TEXT=(vertAxis) axisLabelCache
						axisIndex = V_Value
						if(axisIndex != -1 && cmpstr(axisLabelCache[axisIndex][%Lbl], axisLabel))
							axisLabel =  channelID + "?\r(a. u.)"
							axisLabelCache[axisIndex][1] = axisLabel
						endif

						Label/W=$graph $vertAxis, axisLabel

						if(axisIndex == -1) // create new entry
							count = GetNumberFromWaveNote(axisLabelCache, NOTE_INDEX)
							EnsureLargeEnoughWave(axisLabelCache, minimumSize=count)
							axisLabelCache[count][%Axis] = vertAxis
							axisLabelCache[count][%Lbl]  = axisLabel
							SetNumberInWaveNote(axisLabelCache, NOTE_INDEX, count + 1)
						endif

						ModifyGraph/W=$graph lblPosMode = 1, standoff($vertAxis) = 0, freePos($vertAxis) = 0
					else
						Label/W=$graph $vertAxis, "\\u#2"
					endif

					if(tgs.dDAQDisplayMode)
						ModifyGraph/W=$graph axRGB($vertAxis)=(65535,65535,65535), tlblRGB($vertAxis)=(65535,65535,65535)
						ModifyGraph/W=$graph axThick($vertAxis)=0
						if(!IsEmpty(horizAxis))
							ModifyGraph/W=$graph axRGB($horizAxis)=(65535,65535,65535), tlblRGB($horizAxis)=(65535,65535,65535)
							ModifyGraph/W=$graph alblRGB($horizAxis)=(65535,65535,65535), axThick($horizAxis)=0
							ModifyGraph/W=$graph freePos($vertAxis)={1 / numHorizWaves * k,kwFraction}, freePos($horizAxis)={0,$vertAxis}
						endif
					endif

					// Color scheme:
					// 0-7:   Different headstages
					// 8:     Unknown headstage
					// 9:     Averaged trace
					// 10:    TTL bits (sum) rack zero
					// 11-14: TTL bits (single) rack zero
					// 15:    TTL bits (sum) rack one
					// 16-19: TTL bits (single) rack one
					if(WaveExists(status) && IsFinite(headstage))
						colorIndex = headstage
					elseif(!cmpstr(channelID, "TTL"))
						colorIndex = 10 + activeChanCount[i] * 5 + j
					else
						colorIndex = NUM_HEADSTAGES
					endif

					GetTraceColor(colorIndex, red, green, blue)
					ModifyGraph/W=$graph hideTrace($trace)=(tgs.hideSweep), rgb($trace)=(red, green, blue), userData($trace)={channelType, 0, channelID}, userData($trace)={channelNumber, 0, num2str(chan)}, userData($trace)={sweepNumber, 0, num2str(sweepNo)}, userData($trace)={headstage, 0, num2str(headstage)}, userData($trace)={textualValues, 0, GetWavesDataFolder(textualValues, 2)}, userData($trace)={numericalValues, 0, GetWavesDataFolder(numericalValues, 2)}, userData($trace)={clampMode, 0, num2str(IsFinite(headstage) ? clampModes[headstage] : NaN)}

					sprintf str, "colorIndex=%d", colorIndex
					DEBUGPRINT(str)

					if(tgs.highlightSweep == 0)
						ModifyGraph/W=$graph rgb($trace)=(red, green, blue, 0.05 * 65535)
					endif
				endfor

				if(!tgs.OverlayChannels || activeChanCount[i] == 0)
					high -= slotMult * spacePerSlot + GRAPH_DIV_SPACING
				endif
			endfor

			activeChanCount[i] += 1
		endfor
	while(moreData)

	if(tgs.dDAQDisplayMode)
		ModifyGraph/W=$graph margin(left)=28, margin(bottom)=1
	else
		ModifyGraph/W=$graph margin(left)=0, margin(bottom)=0
	endif
End

/// @brief Return a sorted list of all keys in the labnotebook key wave
Function/S GetLabNotebookSortedKeys(keyWave)
	WAVE/Z/T keyWave

	string list = ""
	variable numCols, i

	if(!WaveExists(keyWave))
		return list
	endif

	numCols = DimSize(keyWave, COLS)
	for(i = INITIAL_KEY_WAVE_COL_COUNT; i < numCols; i += 1)
		list = AddListItem(keyWave[%Parameter][i], list, ";", Inf)
	endfor

	return SortList(list)
End

/// @brief Check if the x wave belonging to the first trace in the
/// graph has a date/time scale. Returns false if no traces have been found.
Function CheckIfXAxisIsTime(graph)
	string graph

	string list, trace, dataUnits

	list = TraceNameList(graph, ";", 0 + 1)

	// default is sweep axis
	if(isEmpty(list))
		return 0
	endif

	trace = StringFromList(0, list)
	dataUnits = WaveUnits(XWaveRefFromTrace(graph, trace), -1)

	return !cmpstr(dataUnits, "dat")
End

/// @brief Queries the parameter and unit from a labnotebook key wave
///
/// @param keyWave   labnotebook key wave
/// @param key       key to look for
/// @param parameter name of the result [empty if not found]
/// @param unit      unit of the result [empty if not found]
/// @param col       column of the result into the keyWave [NaN if not found]
/// @returns one on error, zero otherwise
Function GetKeyWaveParameterAndUnit(keyWave, key, parameter, unit, col)
	WAVE/T/Z keyWave
	string key
	string &parameter, &unit
	variable &col

	variable row, numRows
	string device

	parameter = ""
	unit      = ""
	col       = NaN

	if(!WaveExists(keyWave))
		return 1
	endif

	FindValue/TXOP=4/TEXT=key keyWave

	numRows = DimSize(keywave, ROWS)
	col     = floor(V_value / numRows)
	row     = V_value - col * numRows

	if(V_Value == -1 || row != FindDimLabel(keyWave, ROWS, "Parameter"))
		printf "Could not find %s in keyWave\r", key
		col = NaN
		return 1
	endif

	parameter = keyWave[%Parameter][col]
	unit      = keyWave[%Units][col]

	return 0
End

/// @brief Set the appropriate label for the bottom axis of the graph created by CreateTiledChannelGraph
///
/// Assumes that wave data units are equal for all traces
Function SetLabNotebookBottomLabel(graph, isTimeAxis)
	string graph
	variable isTimeAxis

	if(isTimeAxis)
		Label/W=$graph bottom LABNOTEBOOK_BOTTOM_AXIS_TIME
	else
		Label/W=$graph bottom LABNOTEBOOK_BOTTOM_AXIS_SWEEP
	endif
End

/// @brief Space the matching axis in an equal manner
///
/// @param graph           graph
/// @param axisRegExp      [optional, defaults to ".*"] regular expression matching the axes names
/// @param axisOrientation [optional, defaults to all] allows to apply equalization to all axis of one orientation
/// @param sortOrder       [optional, defaults to no sorting (NaN)] apply different sorting
///                        schemes to list of axes, see sortingOrder parameter of `SortList`
/// @param listForBegin    [optional, defaults to an empty list] list of axes to move to the front of the sorted axis list
/// @param listForEnd      [optional, defaults to an empty list] list of axes to move to the end of the sorted axis list
Function EquallySpaceAxis(graph, [axisRegExp, axisOrientation, sortOrder, listForBegin, listForEnd])
	string graph, axisRegExp, listForBegin, listForEnd
	variable axisOrientation, sortOrder

	variable numAxes, axisInc, axisStart, axisEnd, i, spacing
	string axes, axis, list
	string adaptedList = ""

	if(ParamIsDefault(axisRegExp))
		axisRegExp = ".*"
	endif

	if(ParamIsDefault(axisOrientation))
		list = AxisList(graph)
	else
		list = GetAllAxesWithOrientation(graph, axisOrientation)
	endif

	axes    = GrepList(list, axisRegExp)
	numAxes = ItemsInList(axes)

	if(ParamIsDefault(listForEnd))
		listForEnd = ""
	else
		listForEnd = RemoveEnding(listForEnd, ";")
	endif

	if(ParamIsDefault(listForBegin))
		listForBegin = ""
	else
		listForBegin = RemoveEnding(listForBegin, ";")
	endif

	if(ParamIsDefault(sortOrder) || !IsFinite(sortOrder))
		list = SortAxisList(graph, list)
	else
		axes         = SortList(axes, ";", sortOrder)
		listForEnd   = SortList(listForEnd, ";", sortOrder)
		listForBegin = SortList(listForBegin, ";", sortOrder)
	endif

	if(!IsEmpty(listForBegin) || !IsEmpty(listForEnd))
		for(i = 0; i < numAxes; i += 1)
			axis = StringFromList(i, axes)

			if(WhichListItem(axis, listForBegin) == -1 && WhichListItem(axis, listForEnd) == -1)
				adaptedList = AddListItem(axis, adaptedList, ";", inf)
			endif
		endfor

		// adaptedList now holds all axes which are neither in listForBegin nor listForEnd
		if(!IsEmpty(listForBegin))
			adaptedList = AddListItem(listForBegin, adaptedList, ";", 0)
		endif

		if(!IsEmpty(listForEnd))
			adaptedList = AddListItem(listForEnd, adaptedList, ";", inf)
		endif
	else
		adaptedList = axes
	endif

	numAxes = ItemsInList(adaptedList)
	axisInc = 1 / numAxes

	if(axisInc < GRAPH_DIV_SPACING)
		spacing = axisInc/5
	else
		spacing = GRAPH_DIV_SPACING
	endif

	for(i = numAxes - 1; i >= 0; i -= 1)
		axis = StringFromList(i, adaptedList)
		axisStart = (i == 0 ? 0 : spacing + axisInc * i)
		axisEnd   = (i == numAxes - 1 ? 1 : axisInc * (i + 1) - spacing)
		ModifyGraph/W=$graph axisEnab($axis) = {axisStart, axisEnd}
	endfor
End

/// @brief Update the legend in the labnotebook graph
///
/// Passing traceList is required if you just added traces
/// to the graph as these can not be immediately queried using
/// `TraceNameList` as that would require an `DoUpdate` call before.
///
/// Assumes that the traceList displays information from the labnotebook. All entries
/// with indizes equal or higher than #NUM_HEADSTAGES will be labeled as `all` denoting that
/// the information is headstage independent and therefore valid for all headstages.
///
/// @param graph       name of the graph
/// @param traceList   list of traces in the graph
Function UpdateLBGraphLegend(graph, [traceList])
	string graph, traceList

	string str
	variable numEntries, i

	if(!windowExists(graph))
		return NaN
	endif

	if(FindListItem("text0", AnnotationList(graph)) == -1)
		return NaN
	endif

	if(ParamIsDefault(traceList) || ItemsInList(traceList) == 0)
		TextBox/C/W=$graph/N=text0/F=0 ""
		return NaN
	endif

	str = "\\JCHeadstage\r"

	numEntries = ItemsInList(traceList)
	for(i = 0 ; i < numEntries; i += 1)
		str += "\\s(" + PossiblyQuoteName(StringFromList(i, traceList)) + ") "

		if(i < NUM_HEADSTAGES)
			str += num2str(i + 1)
		else
			str += "all"
		endif

		if(mod(i, 2))
			str += "\r"
		endif
	endfor

	str = RemoveEnding(str, "\r")
	TextBox/C/W=$graph/N=text0/F=2 str
End

/// @brief Add a trace to the labnotebook graph
///
/// @param graph  name of the graph
/// @param keys   labnotebook keys wave (numerical or text)
/// @param values labnotebook values wave (numerical or text)
/// @param key    name of the key to add
Function AddTraceToLBGraph(graph, keys, values, key)
	string graph
	WAVE values, keys
	string key

	string unit, lbl, axis, trace, text, tagString
	string traceList = ""
	variable i, j, numEntries, row, col, numRows, sweepCol
	variable red, green, blue, isTimeAxis, isTextData, xPos

	if(GetKeyWaveParameterAndUnit(keys, key, lbl, unit, col))
		return NaN
	endif

	lbl = LineBreakingIntoParWithMinWidth(lbl)

	WAVE valuesDat = ExtractLBColumnTimeStamp(values)

	isTimeAxis = CheckIfXAxisIsTime(graph)
	isTextData = IsTextWave(values)
	sweepCol   = GetSweepColumn(values)

	axis = GetNextFreeAxisName(graph, VERT_AXIS_BASE_NAME)

	numRows    = DimSize(values, ROWS)
	numEntries = DimSize(values, LAYERS)

	if(IsTextData)
		WAVE valuesNull  = ExtractLBColumnEmpty(values)
		WAVE valuesSweep = ExtractLBColumnSweep(values)
	endif

	for(i = 0; i < numEntries; i += 1)

		trace = CleanupName(lbl[0, MAX_OBJECT_NAME_LENGTH_IN_BYTES - 5] + " (" + num2str(i + 1) + ")", 1) // +1 because the headstage number is 1-based
		traceList = AddListItem(trace, traceList, ";", inf)

		if(isTextData)
			if(isTimeAxis)
				AppendToGraph/W=$graph/L=$axis valuesNull/TN=$trace vs valuesDat
			else
				AppendToGraph/W=$graph/L=$axis valuesNull/TN=$trace vs valuesSweep
			endif

			ModifyGraph/W=$graph nticks($axis)=0, axRGB($axis)=(65535,65535,65535)
		else
			if(isTimeAxis)
				AppendToGraph/W=$graph/L=$axis values[][col][i]/TN=$trace vs valuesDat
			else
				AppendToGraph/W=$graph/L=$axis values[][col][i]/TN=$trace vs values[][sweepCol][0]
			endif
		endif

		ModifyGraph/W=$graph userData($trace)={key, 0, key}

		GetTraceColor(i, red, green, blue)
		ModifyGraph/W=$graph rgb($trace)=(red, green, blue), marker($trace)=i
		SetAxis/W=$graph/A=2 $axis
	endfor

	if(isTextData)
		WAVE/T valuesText = values
		for(i = 0; i < numRows; i += 1)
			if(isTimeAxis)
				xPos = valuesDat[i]
			else
				xPos = valuesSweep[i]
			endif

			if(!IsFinite(xPos))
				continue
			endif

			tagString = ""
			for(j = 0; j < numEntries; j += 1)
				text = valuesText[i][col][j]

				if(IsEmpty(text))
					continue
				endif

				GetTraceColor(j, red, green, blue)
				sprintf text, "\\K(%d, %d, %d)%d:\\K(0, 0, 0)%s\r", red, green, blue, j + 1, text
				tagString += text
			endfor

			if(IsEmpty(tagString))
				continue
			endif

			Tag/W=$graph/F=0/L=0/X=0.00/Y=0.00/O=90 $trace, i, RemoveEnding(tagString, "\r")
		endfor
	endif

	if(!isEmpty(unit))
		lbl += "\r(" + unit + ")"
	endif

	Label/W=$graph $axis lbl

	ModifyGraph/W=$graph lblPosMode = 1, standoff($axis) = 0, freePos($axis) = 0
	ModifyGraph/W=$graph mode = 3
	ModifyGraph/W=$graph nticks(bottom) = 10, manTick(bottom) = {0,1,0,0}, manMinor(bottom) = {0,50}

	if(!cmpstr(unit, LABNOTEBOOK_BINARY_UNIT))
		ModifyGraph/W=$graph manTick($axis)={0,1,0,0}, manMinor($axis)={0,50}, zapTZ($axis)=1
	endif

	SetLabNotebookBottomLabel(graph, isTimeAxis)
	EquallySpaceAxis(graph, axisRegExp=VERT_AXIS_BASE_NAME + ".*")
	UpdateLBGraphLegend(graph, traceList=traceList)
End

/// @brief Switch the labnotebook graph x axis type (time <-> sweep numbers)
Function SwitchLBGraphXAxis(graph, numericalValues, textualValues)
	string graph
	WAVE numericalValues, textualValues

	string trace, dataUnits, list, wvName
	variable i, numEntries, isTimeAxis, sweepCol

	list = TraceNameList(graph, ";", 0 + 1)

	if(isEmpty(list))
		return NaN
	endif

	isTimeAxis = CheckIfXAxisIsTime(graph)
	sweepCol   = GetSweepColumn(numericalValues)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		trace = StringFromList(i, list)

		// instance does not matter as all instances use the same xwave
		wvName = StringByKey("XWAVE", TraceInfo(graph, trace, 0))

		if(StringMatch(wvName, "numericalValues*"))
			WAVE valuesDat     = ExtractLBColumnTimeStamp(numericalValues)
			WAVE/Z valuesSweep = $""
		else
			WAVE valuesDat   = ExtractLBColumnTimeStamp(textualValues)
			WAVE valuesSweep = ExtractLBColumnSweep(textualValues)
		endif

		// change from timestamps to sweepNums
		if(isTimeAxis)
			if(!WaveExists(valuesSweep))
				ReplaceWave/W=$graph/X trace=$trace, numericalValues[][sweepCol][0]
			else
				ReplaceWave/W=$graph/X trace=$trace, valuesSweep
			endif
		else // other direction
			ReplaceWave/W=$graph/X trace=$trace, valuesDat
		endif
	endfor

	SetLabNotebookBottomLabel(graph, !isTimeAxis)

	// autoscale all axis after a switch
	list = AxisList(graph)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		SetAxis/W=$graph/A $StringFromList(i, list)
	endfor
End

/// @brief Save the current experiment under a new name and clear all/some data
/// @param mode mode for generating the experiment name, one of @ref SaveExperimentModes
Function SaveExperimentSpecial(mode)
	variable mode

	variable numDevices, i, ret, pos
	variable zeroSweepCounter, keepOtherData, showSaveDialog, useNewNWBFile
	string path, devicesWithData, activeDevices, device, expLoc, list, refNum
	string expName, substr

	if(mode == SAVE_AND_CLEAR)
		zeroSweepCounter = 1
		keepOtherData    = 0
		showSaveDialog   = 1
		useNewNWBFile    = 1
	elseif(mode == SAVE_AND_SPLIT)
		zeroSweepCounter = 0
		keepOtherData    = 1
		showSaveDialog   = 0
		useNewNWBFile    = 0
	else
		ASSERT(0, "Unknown mode")
	endif

	// We want never to loose data so we do the following:
	// Case 1: Unitled experiment
	// - Save (with dialog if requested) without fileNameSuffix suffix
	// - Save (with dialog if requested) with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// Case 2: Experiment with name
	// - Save without dialog
	// - Save (with dialog if requested) with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// User aborts in the save dialogs always results in a complete abort

	expName = GetExperimentName()

	if(!cmpstr(expName, UNTITLED_EXPERIMENT))
		ret = SaveExperimentWrapper("", "_" + GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX, overrideInteractiveMode = showSaveDialog)

		if(ret)
			return NaN
		endif

		// the user might have changed the experiment name in the dialog
		expName = GetExperimentName()
	else
		SaveExperiment
	endif

	if(mode == SAVE_AND_SPLIT)
		expName = CleanupExperimentName(expName) + SIBLING_FILENAME_SUFFIX
	elseif(mode == SAVE_AND_CLEAR)
		expName = "_" + GetTimeStamp()
	endif

	// saved experiments are stored in the symbolic path "home"
	expLoc  = "home"
	expName = UniqueFile(expLoc, expName, PACKED_FILE_EXPERIMENT_SUFFIX)

	ret = SaveExperimentWrapper(expLoc, expName, overrideInteractiveMode = showSaveDialog)

	if(ret)
		return NaN
	endif

	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE killFunc = KillOrMoveToTrashPath

	// remove sweep data from all devices with data
	devicesWithData = GetAllDevicesWithContent()
	numDevices = ItemsInList(devicesWithData)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, devicesWithData)

		path = GetDeviceDataPathAsString(device)
		killFunc(path)

		if(windowExists(device) && zeroSweepCounter)
			PGC_SetAndActivateControl(device, "SetVar_Sweep", val = 0)
		endif
	endfor

	if(!keepOtherData)
		// remove labnotebook
		path = GetLabNotebookFolderAsString()
		killFunc(path)

		path = GetCacheFolderAS()
		killFunc(path)

		list = GetListOfLockedDevices()
		CallFunctionForEachListItem(DAP_ClearCommentNotebook, list)

		DB_ClearAllGraphs()

		// remove other waves from active devices
		activeDevices = GetAllDevices(activeOnly = 1)
		numDevices = ItemsInList(activeDevices)
		for(i = 0; i < numDevices; i += 1)
			device = StringFromList(i, activeDevices)

			DFREF dfr = GetDevicePath(device)
			list = GetListOfObjects(dfr, "ChanAmpAssign_Sweep_*", fullPath=1)
			CallFunctionForEachListItem(killFunc, list)

			DFREF dfr = GetDeviceTestPulse(device)
			list = GetListOfObjects(dfr, "TPStorage_*", fullPath=1)
			CallFunctionForEachListItem(killFunc, list)

			path = GetDeviceDataBrowserPathAS(device)
			killFunc(path)

			RemoveTracesFromGraph(SCOPE_GetGraph(device))
		endfor
	endif

	SaveExperiment

	if(useNewNWBFile)
		// reset history capturing
		NVAR historyRefnum = $GetHistoryRefNumber()
		historyRefnum = NaN

		CloseNWBFile()
	endif
End

/// @brief Cleanup the experiment name
Function/S CleanupExperimentName(expName)
	string expName

	// Remove the following suffixes:
	// - sibling
	// - time stamp
	// - numerical suffixes added to prevent overwriting files
	expName  = RemoveEndingRegExp(expName, "_[[:digit:]]{4}_[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{6}") // example: 2015_03_25_213219
	expName  = RemoveEndingRegExp(expName, "_[[:digit:]]{1,5}") // example: _1, _123
	expName  = RemoveEnding(expName, SIBLING_FILENAME_SUFFIX)

	return expName
End

/// @brief Return the maximum count of the given type
///
/// @param var    numeric channel types
/// @param str    string channel types
/// @param itcVar numeric ITC XOP channel types
Function GetNumberFromType([var, str, itcVar])
	variable var
	string str
	variable itcVar

	ASSERT(ParamIsDefault(var) + ParamIsDefault(str) + ParamIsDefault(itcVar) == 2, "Expected exactly one parameter")

	if(!ParamIsDefault(str))
		strswitch(str)
			case "AsyncAD":
				return NUM_ASYNC_CHANNELS
				break
			case "DA":
			case "TTL":
				return NUM_DA_TTL_CHANNELS
				break
			case "DataAcqHS":
				return NUM_HEADSTAGES
				break
			case "AD":
				return NUM_AD_CHANNELS
				break
			case "Async_Alarm":
				return NUM_ASYNC_CHANNELS
				break
			default:
				ASSERT(0, "invalid type")
				break
		endswitch
	elseif(!ParamIsDefault(var))
		switch(var)
			case CHANNEL_TYPE_ASYNC:
			case CHANNEL_TYPE_ALARM:
				return NUM_ASYNC_CHANNELS
				break
			case CHANNEL_TYPE_TTL:
			case CHANNEL_TYPE_DAC:
				return NUM_DA_TTL_CHANNELS
				break
			case CHANNEL_TYPE_HEADSTAGE:
				return NUM_HEADSTAGES
				break
			case CHANNEL_TYPE_ADC:
				return NUM_AD_CHANNELS
				break
			default:
				ASSERT(0, "invalid type")
				break
		endswitch
	elseif(!ParamIsDefault(itcVar))
		switch(itcVar)
			case ITC_XOP_CHANNEL_TYPE_ADC:
				return NUM_AD_CHANNELS
				break
			case ITC_XOP_CHANNEL_TYPE_DAC:
			case ITC_XOP_CHANNEL_TYPE_TTL:
				return NUM_DA_TTL_CHANNELS
				break
			default:
				ASSERT(0, "Invalid type")
				break
		endswitch
	endif
End

/// @brief Extract an one dimensional wave from the given ITC wave and column
///
/// @param config ITC config wave
/// @param sweep  ITC sweep wave
/// @param column column index into `sweep`, can be queried with #AFH_GetITCDataColumn
///
/// @returns a reference to a free wave with the single channel data
Function/Wave ExtractOneDimDataFromSweep(config, sweep, column)
	WAVE config
	WAVE sweep
	variable column

	ASSERT(IsValidSweepAndConfig(sweep, config), "Sweep and config are not compatible")
	ASSERT(column < DimSize(sweep, COLS), "The column is out of range")

	MatrixOP/FREE data = col(sweep, column)
	SetScale/P x, DimOffset(sweep, ROWS), DimDelta(sweep, ROWS), WaveUnits(sweep, ROWS), data
	WAVE/T units = AFH_GetChannelUnits(config)
	if(column < DimSize(units, ROWS))
		SetScale d, 0, 0, units[column], data
	endif

	Note data, note(sweep)

	return data
End

/// @brief Perform common transformations on the graphs traces
///
/// Keeps track of all internal details wrt. to the order of
/// the operations, backups, etc.
///
/// @param graph graph with sweep traces
/// @param pps   settings
Function PostPlotTransformations(graph, pps)
	string graph
	STRUCT PostPlotSettings &pps

	string traceList, trace, crsA, crsB
	variable numTraces, i

	crsA = CsrInfo(A, graph)
	crsB = CsrInfo(B, graph)

	WAVE/T traces = ListToTextWave(GetAllSweepTraces(graph), ";")

	ZeroTracesIfReq(graph, traces, pps.zeroTraces)
	if(pps.timeAlignment)
		TimeAlignmentIfReq(graph, traces, pps.timeAlignMode, pps.timeAlignRefTrace, pps.timeAlignLevel)
	endif

	AverageWavesFromSameYAxisIfReq(graph, traces, pps.averageTraces, pps.averageDataFolder,pps.hideSweep)
	AR_HighlightArtefactsEntry(graph)
	PA_ShowPulses(graph, pps.averageDataFolder, pps.pulseAverSett)

	RestoreCursor(graph, crsA)
	RestoreCursor(graph, crsB)

	pps.finalUpdateHook(graph)
End

/// @brief Replace all waves from the traces in the graph with their backup
Function ReplaceAllWavesWithBackup(graph, traceList)
	string graph
	string traceList

	variable numTraces, i
	string trace

	numTraces = ItemsInList(traceList)
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)
		WAVE wv = TraceNameToWaveRef(graph, trace)
		ReplaceWaveWithBackup(wv, nonExistingBackupIsFatal=0)
	endfor
End

/// @brief Return all traces with real sweep data.
///
/// The traces must have correct user data as created by CreateTiledChannelGraph().
///
/// @param graph graph
/// @param channelType [optional, defaults to all] restrict the returned traces
///                    to the given channel type
Function/S GetAllSweepTraces(graph, [channelType])
	string graph
	variable channelType

	string traceList, trace, channelTypeAct, channelTypeRef
	string traceListClean = ""
	variable numTraces, i

	traceList = TraceNameList(graph, ";", 0+1)
	traceList = ListMatch(traceList, "!average*")

	if(ParamIsDefault(channelType))
		return traceList
	endif

	channelTypeRef = StringFromList(channelType, ITC_CHANNEL_NAMES)
	ASSERT(!IsEmpty(channelTypeRef), "Invalid channelType")

	numTraces = ItemsInList(traceList)
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)
		channelTypeAct = GetUserData(graph, trace, "channelType")

		if(!cmpstr(channelTypeAct, channelTypeRef))
			traceListClean = AddListItem(trace, traceListClean, ";", inf)
		endif
	endfor

	return traceListClean
End

/// @brief Average traces in the graph from the same y-axis and append them to the graph
///
/// @param graph             graph with traces create by #CreateTiledChannelGraph
/// @param traces            all traces of the graph except suplimentary ones like the average trace
/// @param averagingEnabled  switch if averaging is enabled or not
/// @param averageDataFolder permanent datafolder where the average waves can be stored
/// @param hideSweep         are normal channel traces hidden or not
static Function AverageWavesFromSameYAxisIfReq(graph, traces, averagingEnabled, averageDataFolder, hideSweep)
	string graph
	WAVE/T traces
	variable averagingEnabled
	DFREF averageDataFolder
	variable hideSweep

	variable referenceTime, traceIndex
	string averageWaveName, listOfWaves, listOfChannelTypes, listOfChannelNumbers, listOfHeadstages
	string xRange, listOfXRanges, firstXAxis, listOfClampModes
	variable i, j, k, l, numAxes, numTraces, numWaves, ret
	variable red, green, blue, column, first, last, orientation
	string axis, trace, axList, baseName, clampMode, traceName, headstage
	string channelType, channelNumber, fullPath, panel

	referenceTime = DEBUG_TIMER_START()

	if(!averagingEnabled)
		listOfWaves = GetListOfObjects(averageDataFolder, "average.*", fullPath=1)
		CallFunctionForEachListItem(KillOrMoveToTrashPath, listOfWaves)
		RemoveEmptyDataFolder(averageDataFolder)
		return NaN
	endif

	axList = AxisList(graph)
	numAxes = ItemsInList(axList)
	numTraces = DimSize(traces, ROWS)

	// precompute traceInfo data
	Make/FREE/T/N=(numTraces) allTraceInfo = TraceInfo(graph, traces[p], 0)

	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)
		listOfWaves          = ""
		listOfChannelTypes   = ""
		listOfChannelNumbers = ""
		listOfXRanges        = ""
		listOfClampModes     = ""
		listOfHeadstages     = ""
		firstXAxis           = ""

		orientation = GetAxisOrientation(graph, axis)
		if(orientation == AXIS_ORIENTATION_BOTTOM || orientation == AXIS_ORIENTATION_TOP)
			continue
		endif

		for(j = 0; j < numTraces; j += 1)
			if(!cmpstr(axis, StringByKey("YAXIS", allTraceInfo[j])))
				trace = traces[j]

				fullPath      = GetWavesDataFolder(TraceNameToWaveRef(graph, trace), 2)
				channelType   = GetUserData(graph, trace, "channelType")
				channelNumber = GetUserData(graph, trace, "channelNumber")
				clampMode     = GetUserData(graph, trace, "clampMode")
				headstage     = GetUserData(graph, trace, "headstage")
				xRange        = StringByKey("YRANGE", allTraceInfo[j])

				listOfWaves          = AddListItem(fullPath, listOfWaves, ";", Inf)
				listOfChannelTypes   = AddListItem(channelType, listOfChannelTypes, ";", Inf)
				listOfChannelNumbers = AddListItem(channelNumber, listOfChannelNumbers, ";", Inf)
				listOfXRanges        = AddListItem(xRange, listOfXRanges, "_", Inf)
				listOfClampModes     = AddListItem(clampMode, listOfClampModes, ";", Inf)
				listOfHeadstages     = AddListItem(headstage, listOfHeadstages, ";", Inf)

				if(IsEmpty(firstXAxis))
					firstXAxis = StringByKey("XAXIS", allTraceInfo[j])
				endif
			endif
		endfor

		numWaves = ItemsInList(listOfWaves)
		if(numWaves <= 1)
			continue
		endif

		if(WaveListHasSameWaveNames(listOfWaves, baseName))
			// add channel type suffix if they are all equal
			if(ListHasOnlyOneUniqueEntry(listOfChannelTypes))
				sprintf averageWaveName, "average_%s", baseName
			else
				sprintf averageWaveName, "average_%s_%d", baseName, k
				k += 1
			endif
		elseif(StringMatch(axis, VERT_AXIS_BASE_NAME + "*"))
			averageWaveName = "average" + RemovePrefix(axis, startStr=VERT_AXIS_BASE_NAME)
		else
			sprintf averageWaveName, "average_%d", k
			k += 1
		endif

		traceName = averageWaveName + "_" + num2str(traceIndex)
		traceIndex += 1

		WAVE ranges = ExtractFromSubrange(listOfXRanges, ROWS)

		// convert ranges from points to ms
		Redimension/D ranges

		MatrixOP/FREE rangeStart = col(ranges, 0)
		MatrixOP/FREE rangeStop  = col(ranges, 1)

		rangeStart[] = IndexToScale($StringFromList(p, listOfWaves), rangeStart[p], ROWS)
		rangeStop[]  = IndexToScale($StringFromList(p, listOfWaves), rangeStop[p], ROWS)

		if(WaveMin(rangeStart) != -1 && WaveMin(rangeStop) != -1)
			first = WaveMin(rangeStart)
			last  = WaveMax(rangeStop)
		else
			first = NaN
			last  = Nan
		endif
		WaveClear rangeStart, rangeStop

		WAVE averageWave = CalculateAverage(listOfWaves, averageDataFolder, averageWaveName)

		if(IsFinite(first) && IsFinite(last))
			// and now convert it back to points in the average wave
			first = ScaleToIndex(averageWave, first, ROWS)
			last  = ScaleToIndex(averageWave, last, ROWS)

			AppendToGraph/Q/W=$graph/L=$axis/B=$firstXAxis averageWave[first, last]/TN=$traceName
		else
			AppendToGraph/Q/W=$graph/L=$axis/B=$firstXAxis averageWave/TN=$traceName
		endif

		if(ListHasOnlyOneUniqueEntry(listOfClampModes))
			ModifyGraph/W=$graph userData($traceName)={clampMode, 0, StringFromList(0, listOfClampModes)}
		endif

		if(WaveListHasSameWaveNames(listOfHeadstages, headstage)&& hideSweep)
			GetTraceColor(str2num(headstage), red, green, blue)
		else
			GetTraceColor(NUM_HEADSTAGES + 1, red, green, blue)
		endif

		ModifyGraph/W=$graph rgb($traceName)=(red, green, blue, 0.80 * 65535)
	endfor

	DEBUGPRINT_ELAPSED(referenceTime)
End

/// @brief Calculate the average of a list of waves, wrapper for MIES_fWaveAverage().
///
/// For performance enhancements:
/// - The average waves are cached
/// - References to existing average waves are returned in case they already exist
///
/// @param listOfWaves       list of 1D waves to average
/// @param averageDataFolder folder where the data is to be stored
/// @param averageWaveName   base name of the averaged data
///
/// @return wave reference to the average wave
Function/WAVE CalculateAverage(listOfWaves, averageDataFolder, averageWaveName)
	string listOfWaves
	DFREF averageDataFolder
	string averageWaveName

	variable ret, crc
	string key, wvName

	WAVE waveRefs = ListToWaveRefWave(listOfWaves, 1)
	key = CA_AveragingKey(waveRefs)

	WAVE/Z freeAverageWave = CA_TryFetchingEntryFromCache(key)

	if(WaveExists(freeAverageWave)) // found in the cache
		wvName = averageWaveName + "_" + num2istr(GetNumberFromWaveNote(freeAverageWave, "DataCRC"))
		WAVE/Z/SDFR=averageDataFolder permAverageWave = $wvName

		if(!WaveExists(permAverageWave))
			MoveWave freeAverageWave, averageDataFolder:$wvName
			WAVE/SDFR=averageDataFolder permAverageWave = $wvName
		endif

		return permAverageWave
	endif

	ret = MIES_fWaveAverage(listOfWaves, "", 0, 0, GetDataFolder(1, averageDataFolder) + averageWaveName, "")
	ASSERT(ret != -1, "Wave averaging failed")

	WAVE/SDFR=averageDataFolder averageWave = $averageWaveName

	crc = WaveCRC(0, averageWave)
	wvName = averageWaveName + "_" + num2istr(crc)

	WAVE/Z/SDFR=averageDataFolder averageWaveToDelete = $wvName
	KillOrMoveToTrash(wv=averageWaveToDelete)
	MoveWave averageWave, averageDataFolder:$wvName

	SetNumberInWaveNote(averageWave, "DataCRC", crc)
	AddEntryIntoWaveNoteAsList(averageWave, "SourceWavesForAverage", str=ReplaceString(";", listOfWaves, "|"))
	CA_StoreEntryIntoCache(key, averageWave)

	return averageWave
End

/// @brief Zero all given traces
static Function ZeroTracesIfReq(graph, traces, zeroTraces)
	string graph
	variable zeroTraces
	WAVE/T traces

	string trace
	variable numTraces, i

	if(!zeroTraces)
		return NaN
	endif

	numTraces = DimSize(traces, ROWS)
	for(i = 0; i < numTraces; i += 1)
		trace = traces[i]

		WAVE wv = TraceNameToWaveRef(graph, trace)

		if(HasEntryInWaveNoteList(wv, NOTE_KEY_ZEROED, "true"))
			continue
		endif

		WAVE backup = CreateBackupWave(wv)
		ZeroWave(wv)
		Note wv, note(backup) + "\r"
		AddEntryIntoWaveNoteAsList(wv, NOTE_KEY_ZEROED, str="true", replaceEntry=1)
	endfor
End

/// @brief Perform time alignment of features in the sweep traces
static Function TimeAlignmentIfReq(panel, traces, mode, refTrace, level)
	string panel
	WAVE/T traces
	string refTrace
	variable mode, level

	string csrA, csrB, str, axList, refAxis, axis
	string trace, graph
	variable offset
	variable csrAx, csrBx, first, last, pos, numTraces, i, j

	ASSERT(windowExists(panel), "Graph must exist")
	graph = GetMainWindow(panel)

	if(mode == TIME_ALIGNMENT_NONE) // nothing to do
		return NaN
	endif

	csrA = CsrInfo(A, graph)
	csrB = CsrInfo(B, graph)

	if(isEmpty(csrA) || isEmpty(csrB))
		return NaN
	endif

	csrAx = xcsr(A, graph)
	csrBx = xcsr(B, graph)

	first = min(csrAx, csrBx)
	last  = max(csrAx, csrBx)

	sprintf str, "first=%g, last=%g", first, last
	DEBUGPRINT(str)

	// now determine the feature's time position
	// using the traces from the same axis as the reference trace
	axList  = AxisList(graph)
	refAxis = StringByKey("YAXIS", TraceInfo(graph, refTrace, 0))

	numTraces = DimSize(traces, ROWS)
	MAKE/FREE/D/N=(numTraces) featurePos = NaN, sweepNumber = NaN
	for(i = 0; i < numTraces; i += 1)
		trace = traces[i]
		axis = StringByKey("YAXIS", TraceInfo(graph, trace, 0))

		if(cmpstr(axis, refAxis))
			continue
		endif

		WAVE wv = TraceNameToWaveRef(graph, trace)
		pos = CalculateFeatureLoc(wv, mode, level, first, last)

		if(!IsFinite(pos))
			printf "The alignment of trace %s could not be performed, aborting\r", trace
			return NaN
		endif

		featurePos[i]  = pos
		sweepNumber[i] = str2num(GetUserData(graph, trace, "sweepNumber"))
	endfor

	// now shift all traces from all sweeps according to their relative offsets
	// to the reference position
	for(i = 0; i < numTraces; i += 1)
		trace = traces[i]
		WAVE wv = TraceNameToWaveRef(graph, trace)

		j = GetRowIndex(sweepNumber, str=GetUserData(graph, trace, "sweepNumber"))
		ASSERT(IsFinite(j), "Could not find sweep number")
		WAVE backup = CreateBackupWave(wv)
		offset = DimOffset(wv, ROWS) - featurePos[j]
		DEBUGPRINT("trace", str=trace)
		DEBUGPRINT("old DimOffset", var=DimOffset(wv, ROWS))
		DEBUGPRINT("new DimOffset", var=offset)
		SetScale/P x, offset, DimDelta(wv, ROWS), wv
		offset = DimOffset(backup, ROWS) - DimOffset(wv, ROWS)
		AddEntryIntoWaveNoteAsList(wv, "TimeAlignmentTotalOffset", var=offset, replaceEntry=1)
	endfor
End

/// @brief Find the given feature in the given wave range
/// `first` and `last` are in x coordinates and clipped to valid values
static Function CalculateFeatureLoc(wv, mode, level, first, last)
	Wave wv
	variable mode, level, first, last

	variable edgeType

	ASSERT(mode == TIME_ALIGNMENT_NONE || mode == TIME_ALIGNMENT_LEVEL_RISING || mode == TIME_ALIGNMENT_LEVEL_FALLING || mode == TIME_ALIGNMENT_MIN || mode == TIME_ALIGNMENT_MAX, "Invalid mode")

	first = max(first, leftx(wv))
	last  = min(last, rightx(wv))

	if(mode == TIME_ALIGNMENT_MIN || mode == TIME_ALIGNMENT_MAX)
		WaveStats/M=1/Q/R=(first, last) wv

		if(mode == TIME_ALIGNMENT_MAX)
			return V_maxLoc
		else
			return V_minLoc
		endif
	elseif(mode == TIME_ALIGNMENT_LEVEL_RISING || mode == TIME_ALIGNMENT_LEVEL_FALLING)
		if(mode == TIME_ALIGNMENT_LEVEL_RISING)
			edgeType = 1
		else
			edgeType = 2
		endif
		FindLevel/Q/R=(first, last)/EDGE=(edgeType) wv, level
		if(V_Flag) // found no level
			return NaN
		endif
		return V_LevelX
	endif
End

/// @brief Equalize all vertical axes ranges so that they cover the same range
///
/// @param graph                       graph
/// @param ignoreAxesWithLevelCrossing [optional, defaults to false] ignore all vertical axis which
///                                    cross the given level in the visible range
/// @param level                       [optional, defaults to zero] level to be used for `ignoreAxesWithLevelCrossing=1`
/// @param rangePerClampMode           [optional, defaults to false] use separate Y ranges per clamp mode
Function EqualizeVerticalAxesRanges(graph, [ignoreAxesWithLevelCrossing, level, rangePerClampMode])
	string graph
	variable ignoreAxesWithLevelCrossing
	variable level, rangePerClampMode

	string axList, axis, traceList, trace, info
	variable i, j, numAxes, axisOrient, xRangeBegin, xRangeEnd
	variable beginY, endY, clampMode
	variable maxYRange, numTraces , range, refClampMode, err

	if(ParamIsDefault(ignoreAxesWithLevelCrossing))
		ignoreAxesWithLevelCrossing = 0
	else
		ignoreAxesWithLevelCrossing = !!ignoreAxesWithLevelCrossing
	endif

	if(ParamIsDefault(rangePerClampMode))
		rangePerClampMode = 0
	else
		rangePerClampMode = !!rangePerClampMode
	endif

	if(ParamIsDefault(level))
		level = 0
	else
		ASSERT(ignoreAxesWithLevelCrossing, "Optional argument level makes only sense if ignoreAxesWithLevelCrossing is enabled")
	endif

	GetAxis/W=$graph/Q bottom; err = GetRTError(1)
	if(!V_Flag)
		xRangeBegin = V_min
		xRangeEnd   = V_max
	else
		xRangeBegin = NaN
		xRangeEnd   = NaN
	endif

	traceList = GetAllSweepTraces(graph)
	numTraces = ItemsInList(traceList)
	axList = AxisList(graph)
	numAxes = ItemsInList(axList)

	Make/FREE/D/N=(NUM_CLAMP_MODES + 1) maxYRangeClampMode = 0
	Make/FREE/D/N=(numAxes) axisClampMode = Nan
	Make/FREE/D/N=(numAxes, 2) YValues = inf

	SetDimLabel COLS, 0, minimum, YValues
	SetDimLabel COLS, 1, maximum, YValues

	YValues[][%minimum] =  inf
	YValues[][%maximum] = -inf

	// collect the y ranges of the visible x range of all vertical axis
	// respecting ignoreAxesWithLevelCrossing
	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)

		axisOrient = GetAxisOrientation(graph, axis)
		if(axisOrient != AXIS_ORIENTATION_LEFT && axisOrient != AXIS_ORIENTATION_RIGHT)
			continue
		endif

		refClampMode = NaN

		for(j = 0; j < numTraces; j += 1)
			trace = StringFromList(j, traceList)
			info = TraceInfo(graph, trace, 0)
			if(cmpstr(axis, StringByKey("YAXIS", info)))
				continue
			endif

			WAVE wv = TraceNameToWaveRef(graph, trace)

			if(!IsFinite(xRangeBegin) || !IsFinite(xRangeEnd))
				xRangeBegin = leftx(wv)
				xRangeEnd   = rightx(wv)
			endif

			if(ignoreAxesWithLevelCrossing)
				FindLevel/Q/R=(xRangeBegin, xRangeEnd) wv, level
				if(!V_flag)
					continue
				endif
			endif

			clampMode = str2num(GetUserData(graph, trace, "clampMode"))

			if(!IsFinite(clampMode))
				// TTL data has NaN for the clamp mode, map that to something which
				// can be used as an index into maxYRangeClampMode.
				clampMode = NUM_CLAMP_MODES
			endif

			if(!IsFinite(refClampMode))
				refClampMode = clampMode
			else
				axisClampMode[i] = refClampMode == clampMode ? clampMode : -1
			endif

			WaveStats/M=2/Q/R=(xRangeBegin, xRangeEnd) wv
			YValues[i][%minimum] = min(V_min, YValues[i][%minimum])
			YValues[i][%maximum] = max(V_max, YValues[i][%maximum])

			range = abs(YValues[i][%maximum] - YValues[i][%minimum])
			if(range > maxYRange)
				maxYRange = range
			endif

			if(rangePerClampMode && range > maxYRangeClampMode[clampMode])
				maxYRangeClampMode[clampMode] = range
			endif
		endfor
	endfor

	if(maxYRange == 0) // too few traces
		return NaN
	endif

	// and now set vertical axis ranges to the maximum
	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)

		axisOrient = GetAxisOrientation(graph, axis)
		if(axisOrient != AXIS_ORIENTATION_LEFT && axisOrient != AXIS_ORIENTATION_RIGHT)
			continue
		endif

		if(!IsFinite(YValues[i][%minimum]) || !IsFinite(YValues[i][%minimum]))
			continue
		endif

		beginY = YValues[i][%minimum]

		if(rangePerClampMode && axisClampMode[i] >= 0)
			endY = beginY + maxYRangeClampMode[axisClampMode[i]]
		else
			endY = beginY + maxYRange
		endif

		DebugPrint("Setting new axis ranges for:", str=axis)
		DebugPrint("beginY:", var=beginY)
		DebugPrint("endY:", var=endY)

		SetAxis/W=$graph $axis, beginY, endY
	endfor
End

/// @brief Extract the sweep number from a `$something_*` string
threadsafe Function ExtractSweepNumber(str)
	string str

	return str2num(StringFromList(ItemsInList(str, "_") - 1, str, "_"))
End

/// @brief Return the list of unlocked `DA_Ephys` panels
Function/S GetListOfUnlockedDevices()

	return WinList("DA_Ephys*", ";", "WIN:64")
End

/// @brief Return the list of locked devices
Function/S GetListOfLockedDevices()

	SVAR/Z/SDFR=GetITCDevicesFolder() list = ITCPanelTitleList
	if(!SVAR_Exists(list))
		return ""
	endif

	return list
End

/// @brief Return the list of locked ITC1600 devices
Function/S GetListOfLockedITC1600Devices()
	return ListMatch(GetListOfLockedDevices(), "ITC1600*")
End

/// @brief Return the type, #CHANNEL_TYPE_DAC, #CHANNEL_TYPE_TTL or #CHANNEL_TYPE_UNKNOWN, of the stimset
Function GetStimSetType(setName)
	string setName

	string type

	type = StringFromList(ItemsInList(setName, "_") - 2, setName, "_")

	if(!cmpstr(type, "DA"))
		return CHANNEL_TYPE_DAC
	elseif(!cmpstr(type, "TTL"))
		return CHANNEL_TYPE_TTL
	else
		return CHANNEL_TYPE_UNKNOWN
	endif
End

/// @brief Return the stimset folder from the numeric channelType, #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
///
/// @returns Data Folder reference to Stimset dataFolder
Function/DF GetSetFolder(channelType)
	variable channelType

	if(channelType == CHANNEL_TYPE_DAC)
		return GetWBSvdStimSetDAPath()
	elseif(channelType == CHANNEL_TYPE_TTL)
		return GetWBSvdStimSetTTLPath()
	else
		ASSERT(0, "unknown channelType")
	endif
End

/// @brief Return the stimset folder from the numeric channelType, #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
///
/// @returns String with full path to Stimset dataFolder
Function/S GetSetFolderAsString(channelType)
	variable channelType

	if(channelType == CHANNEL_TYPE_DAC)
		return GetWBSvdStimSetDAPathAsString()
	elseif(channelType == CHANNEL_TYPE_TTL)
		return GetWBSvdStimSetTTLPathAsString()
	else
		ASSERT(0, "unknown channelType")
	endif
End

/// @brief Get the stimset parameter folder
///
/// @param channelType #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
///
/// @returns dataFolder as DFREF
Function/DF GetSetParamFolder(channelType)
	variable channelType

	if(channelType == CHANNEL_TYPE_DAC)
		return GetWBSvdStimSetParamDAPath()
	elseif(channelType == CHANNEL_TYPE_TTL)
		return GetWBSvdStimSetParamTTLPath()
	else
		ASSERT(0, "unknown channelType")
	endif
End

/// @brief Get the stimset parameter folder
///
/// @param channelType #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
///
/// @returns dataFolder as String
Function/S GetSetParamFolderAsString(channelType)
	variable channelType

	if(channelType == CHANNEL_TYPE_DAC)
		return GetWBSvdStimSetParamPathAS() + ":DA"
	elseif(channelType == CHANNEL_TYPE_TTL)
		return GetWBSvdStimSetParamPathAS() + ":TTL"
	else
		ASSERT(0, "unknown channelType")
	endif
End

/// @brief Return a search string, suitable for `WaveList`, for
/// the given channelType
Function/S GetSearchStringForChannelType(channelType)
	variable channelType

	if(channelType == CHANNEL_TYPE_DAC)
		return CHANNEL_DA_SEARCH_STRING
	elseif(channelType == CHANNEL_TYPE_TTL)
		return CHANNEL_TTL_SEARCH_STRING
	else
		ASSERT(0, "Unexpected channel type")
	endif
End

/// @brief Get the TTL bit mask from the labnotebook
/// @param numericalValues Numerical labnotebook values
/// @param sweep           Sweep number
/// @param channel         TTL channel
Function GetTTLBits(numericalValues, sweep, channel)
	WAVE numericalValues
	variable sweep, channel

	variable index = GetIndexForHeadstageIndepData(numericalValues)

	WAVE/Z ttlRackZeroChannel = GetLastSetting(numericalValues, sweep, "TTL rack zero channel", DATA_ACQUISITION_MODE)
	WAVE/Z ttlRackOneChannel  = GetLastSetting(numericalValues, sweep, "TTL rack one channel", DATA_ACQUISITION_MODE)

	if(WaveExists(ttlRackZeroChannel) && ttlRackZeroChannel[index] == channel)
		WAVE ttlBits = GetLastSetting(numericalValues, sweep, "TTL rack zero bits", DATA_ACQUISITION_MODE)
	elseif(WaveExists(ttlRackOneChannel) && ttlRackOneChannel[index] == channel)
		WAVE ttlBits = GetLastSetting(numericalValues, sweep, "TTL rack one bits", DATA_ACQUISITION_MODE)
	else
		return NaN
	endif

	return ttlBits[index]
End

/// @brief Return the index for headstage independent data
///
/// Before 4ada04a2 (Make the function AB_SplitTTLWaveIntoComponents available for all, 2015-10-07)
/// we stored headstage independent data in either all entries or only the first one.
/// Since that commit we store the data in `INDEP_HEADSTAGE`.
Function GetIndexForHeadstageIndepData(numericalValues)
	WAVE numericalValues

	return DimSize(numericalValues, LAYERS) == NUM_HEADSTAGES ? 0 : INDEP_HEADSTAGE
End

/// @brief Get the TTL stim sets from the labnotebook
/// @param numericalValues Numerical labnotebook values
/// @param textualValues   Text labnotebook values
/// @param sweep           Sweep number
/// @param channel         TTL channel
///
/// @return list of stim sets, empty entries for non active TTL bits
Function/S GetTTLStimSets(numericalValues, textualValues, sweep, channel)
	WAVE numericalValues
	WAVE/T textualValues
	variable sweep, channel

	variable index = GetIndexForHeadstageIndepData(numericalValues)

	WAVE/Z ttlRackZeroChannel = GetLastSetting(numericalValues, sweep, "TTL rack zero channel", DATA_ACQUISITION_MODE)
	WAVE/Z ttlRackOneChannel  = GetLastSetting(numericalValues, sweep, "TTL rack one channel", DATA_ACQUISITION_MODE)

	if(WaveExists(ttlRackZeroChannel) && ttlRackZeroChannel[index] == channel)
		WAVE/T ttlStimsets = GetLastSetting(textualValues, sweep, "TTL rack zero stim sets", DATA_ACQUISITION_MODE)
	elseif(WaveExists(ttlRackOneChannel) && ttlRackOneChannel[index] == channel)
		WAVE/T ttlStimsets = GetLastSetting(textualValues, sweep, "TTL rack one stim sets", DATA_ACQUISITION_MODE)
	else
		return ""
	endif

	return ttlStimSets[index]
End

/// @brief Return a sorted list of all DA/TTL stim set waves
///
/// @param DAorTTL                  #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
/// @param searchString             search string in wildcard syntax
/// @param WBstimSetList            [optional] returns the list of stim sets built with the wavebuilder
/// @param thirdPartyStimSetList    [optional] returns the list of third party stim sets not built with the wavebuilder
Function/S ReturnListOfAllStimSets(DAorTTL, searchString, [WBstimSetList, thirdPartyStimSetList])
	variable DAorTTL
	string searchString
	string &WBstimSetList
	string &thirdPartyStimSetList

	variable i, numWaves
	string list, item
	string listInternal   = ""
	string listThirdParty = ""

	DFREF saveDFR = GetDataFolderDFR()

	// fetch stim sets created with the WaveBuilder
	if(!DAorTTL)
		SetDataFolder GetWBSvdStimSetParamDAPath()
	else
		SetDataFolder GetWBSvdStimSetParamTTLPath()
	endif

	list = Wavelist("WP_" + searchstring, ";", "")

	numWaves = ItemsInList(list)
	for(i = 0; i < numWaves; i += 1)
		listInternal = AddListItem(RemovePrefix(StringFromList(i, list), startStr="WP_"), listInternal, ";", Inf)
	endfor

	// fetch third party stim sets
	if(!DAorTTL)
		SetDataFolder GetWBSvdStimSetDAPath()
	else
		SetDataFolder GetWBSvdStimSetTTLPath()
	endif

	list = Wavelist(searchstring, ";", "")
	numWaves = ItemsInList(list)
	for(i = 0; i < numWaves; i += 1)
		item = StringFromList(i, list)
		if(FindListItem(item, listInternal, ";", 0, 0) == -1)
			listThirdParty = AddListItem(item, listThirdParty, ";", Inf)
		endif
	endfor

	SetDataFolder saveDFR

	if(!ParamIsDefault(WBstimSetList))
		WBstimSetList = SortList(listInternal,";",16)
	endif

	if(!ParamIsDefault(thirdPartyStimSetList))
		thirdPartyStimSetList = SortList(listThirdParty,";",16)
	endif

	return SortList(listInternal + listThirdParty, ";", 16)
End

/// @brief Return the name short String of the Parameter Wave used in the WaveBuilder
///
/// @param type One of @ref ParameterWaveTypes
///
/// @return name as string
Function/S GetWaveBuilderParameterTypeName(type)
	variable type

	string shortname

	switch(type)
		case STIMSET_PARAM_WP:
			shortname = "WP"
			break
		case STIMSET_PARAM_WPT:
			shortname = "WPT"
			break
		case STIMSET_PARAM_SEGWVTYPE:
			shortname = "SegWvType"
			break
		default:
			break
	endswitch

	return shortname
End

/// @brief Returns the mode of all setVars in the DA_Ephys panel of a controlType
Function/Wave GetAllDAEphysSetVarNum(panelTitle, channelType, controlType)
	string panelTitle
	variable channelType, controlType
	
	variable CtrlNum = GetNumberFromType(var=channelType)
	string ctrl
	make/FREE/n=(CtrlNum) Wv
	variable i
	for(i = 0; i < CtrlNum; i+=1)
		ctrl = GetPanelControl(i, channelType, controlType)
		wv[i] = GetSetVariable(panelTitle, ctrl)
	endfor
	return wv
End

/// @brief Returns the mode of all setVars in the DA_Ephys panel of a controlType
Function/Wave GetAllDAEphysSetVarTxT(panelTitle, channelType, controlType)
	string panelTitle
	variable channelType, controlType

	variable CtrlNum = GetNumberFromType(var=channelType)
	string ctrl
	make/FREE/n=(CtrlNum)/T Wv
	variable i
	for(i = 0; i < CtrlNum; i+=1)
		ctrl = GetPanelControl(i, channelType, controlType)
		wv[i] = GetSetVariableString(panelTitle, ctrl)
	endfor
	return wv
End

/// @brief Returns the index of all popupmenus in the DA_Ephys panel of a controlType
Function/Wave GetAllDAEphysPopMenuIndex(panelTitle, channelType, controlType)
	string panelTitle
	variable channelType, controlType
	
	variable CtrlNum = GetNumberFromType(var=channelType)
	string ctrl
	make/FREE/n=(CtrlNum) Wv
	variable i
	for(i = 0; i < CtrlNum; i+=1)
		ctrl = GetPanelControl(i, channelType, controlType)
		wv[i] = GetPopupMenuIndex(panelTitle, ctrl)
	endfor
	return wv
End

/// @brief Returns the string contents of all popupmenus in the DA_Ephys panel of a controlType
Function/Wave GetAllDAEphysPopMenuString(panelTitle, channelType, controlType)
	string panelTitle
	variable channelType, controlType

	variable CtrlNum = GetNumberFromType(var=channelType)
	string ctrl
	make/FREE/n=(CtrlNum)/T Wv
	variable i
	for(i = 0; i < CtrlNum; i+=1)
		ctrl = GetPanelControl(i, channelType, controlType)
		wv[i] = GetPopupMenuString(panelTitle, ctrl)
	endfor
	return wv
End

/// @brief Extract the analysis function name from the wave note of the stim set
/// @return Analysis function for the given event type, empty string if none is set
Function/S ExtractAnalysisFuncFromStimSet(stimSet, eventType)
	WAVE stimSet
	variable eventType

	string eventName, wvNote

	wvnote = note(stimSet)
	wvnote = ReplaceString(" = ", wvnote, "=")

	eventName = StringFromList(eventType, EVENT_NAME_LIST)
	ASSERT(!IsEmpty(eventName), "Unknown event type")

	return StringByKey(eventName, wvnote, "=", ";")
End

/// @brief Return the analysis function parameters as comma (`,`) separated list
///
/// @sa WBP_AddAnalysisParameter() for the exact format.
Function/S ExtractAnalysisFunctionParams(stimSet)
	WAVE stimSet

	return GetStringFromWaveNote(stimSet, ANALYSIS_FUNCTION_PARAMS_LBN, keySep = "=", listSep = ";")
End

/// @brief Split TTL data into a single wave for each channel
/// @param data       1D channel data extracted by #ExtractOneDimDataFromSweep
/// @param ttlBits    bit mask of the active TTL channels form e.g. #GetTTLBits
/// @param targetDFR  datafolder where to put the waves, can be a free datafolder
/// @param wavePrefix prefix of the created wave names
Function SplitTTLWaveIntoComponents(data, ttlBits, targetDFR, wavePrefix)
	WAVE data
	variable ttlBits
	DFREF targetDFR
	string wavePrefix

	variable i, bit

	if(!IsFinite(ttlBits))
		return NaN
	endif

	for(i = 0; i < NUM_TTL_BITS_PER_RACK; i += 1)

		bit = 2^i
		if(!(ttlBits & bit))
			continue
		endif

		Duplicate data, targetDFR:$(wavePrefix + num2str(i))/Wave=dest
		MultiThread dest[] = dest[p] & bit
	endfor
End

#if exists("HDF5CloseFile")

/// @brief Close a possibly open export-into-NWB file
Function CloseNWBFile()
	NVAR fileID = $GetNWBFileIDExport()

	if(IsFinite(fileID))
		HDF5CloseFile/Z fileID
		DEBUGPRINT("Trying to close the NWB file using HDF5CloseFile returned: ", var=V_flag)
		if(!V_flag) // success
			fileID = NaN
			SVAR filePath = $GetNWBFilePathExport()
			filepath = ""
		endif
	endif
End

#else

Function CloseNWBFile()
	DEBUGPRINT("HDF5 XOP could not be found, not closing any NWB files")
End

#endif

/// @brief Check wether the given background task is running and that the
///        device is active in multi device mode.
Function IsDeviceActiveWithBGTask(panelTitle, task)
	string panelTitle, task

	if(!IsBackgroundTaskRunning(task))
		return 0
	endif

	strswitch(task)
		case "TestPulseMD":
			WAVE deviceIDList = GetActiveDevicesTPMD()
			break
		case "ITC_TimerMD":
			WAVE/Z/SDFR=GetActiveITCDevicesTimerFolder() deviceIDList = ActiveDevTimeParam
			break
		case "ITC_FIFOMonitorMD":
			WAVE/Z/SDFR=GetActiveITCDevicesFolder() deviceIDList = ActiveDeviceList
			break
		case "TestPulse":
		case "ITC_Timer":
		case "ITC_FIFOMonitor":
			// single device tasks, nothing more to do
			return 1
			break
		default:
			DEBUGPRINT("Querying unknown task: " + task)
			break
	endswitch

	if(!WaveExists(deviceIDList))
		DEBUGPRINT("Inconsistent state encountered in IsDeviceActiveWithBGTask")
		return 1
	endif

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	// running in multi device mode
	Duplicate/FREE/R=[][0] deviceIDList, deviceIDs
	FindValue/V=(ITCDeviceIDGlobal) deviceIDs
	return V_Value != -1
End

/// @brief Calculate a cryptographic hash for the file contents of path
///
/// @param path   absolute path to a file
/// @param method [optional, defaults to SHA-2 with 256 bytes]
///               Type of cryptographic hash function
Function/S CalcHashForFile(path, [method])
	string path
	variable method

	variable refNum
	string contents = ""

	if(ParamIsDefault(method))
		method = 1
	endif

	GetFileFolderInfo/Q path
	ASSERT(V_IsFile, "Expected a file")

	Open/R refNum as path

	contents = PadString(contents, V_logEOF, 0)

	FBinRead refNum, contents
	Close refNum

	return Hash(contents, method)
End

/// @brief Check if the file paths referenced in `list` are pointing
///        to identical files
Function CheckIfPathsRefIdenticalFiles(list)
	string list

	variable i, numEntries
	string path, refHash, newHash

	if(ItemsInList(list, "|") <= 1)
		return 1
	endif

	numEntries = ItemsInList(list, "|")
	for(i = 0; i < numEntries; i += 1)
		path = StringFromList(i, list, "|")

		if(i == 0)
			refHash = CalcHashForFile(path)
			continue
		endif

		newHash = CalcHashForFile(path)

		if(cmpstr(newHash, refHash))
			return 0
		endif
	endfor

	return 1
End

/// @brief Remove traces from a graph and optionally try to kill their waves
///
/// @param graph                            graph
/// @param kill [optional, default: false]  try to kill the wave after it has been removed
/// @param trace [optional, default: all]   remove the given trace only
/// @param wv [optional, default: ignored]  remove all traces which stem from the given wave
/// @param dfr [optional, default: ignored] remove all traces which stem from one of the waves in dfr
///
/// Only one of trace/wv/dfr may be supplied.
///
/// @return number of traces/waves removed from the graph
Function RemoveTracesFromGraph(graph, [kill, trace, wv, dfr])
	string graph
	variable kill
	string trace
	WAVE/Z wv
	DFREF dfr

	variable i, numEntries, removals, tryKillingTheWave, numOptArgs
	string traceList, refTrace

	if(ParamIsDefault(kill))
		kill = 0
	endif

	numOptArgs = ParamIsDefault(trace) + ParamIsDefault(wv) + ParamIsDefault(dfr)
	ASSERT(numOptArgs == 3 || numOptArgs == 2, "Can only accept one of the trace/wv/dfr parameters")

	if(!ParamIsDefault(wv) && !WaveExists(wv) || !ParamIsDefault(dfr) && !DataFolderExistsDFR(dfr))
		return 0
	endif

	if(!ParamIsDefault(dfr))
		WAVE candidates = ConvertListOfWaves(GetListOfObjects(dfr, ".*", fullpath=1))
	endif

	traceList  = TraceNameList(graph, ";", 1 )
	numEntries = ItemsInList(traceList)

	// iterating backwards is required, see http://www.igorexchange.com/node/1677#comment-2315
	for(i = numEntries - 1; i >= 0; i -= 1)
		refTrace = StringFromList(i, traceList)

		Wave/Z refWave = TraceNameToWaveRef(graph, refTrace)

		if(ParamIsDefault(trace) && ParamIsDefault(wv) && ParamIsDefault(dfr))
			RemoveFromGraph/W=$graph $refTrace
			removals += 1
			tryKillingTheWave = 1
		elseif(!ParamIsDefault(trace))
			if(!cmpstr(refTrace, trace))
				RemoveFromGraph/W=$graph $refTrace
				removals += 1
				tryKillingTheWave = 1
			endif
		elseif(!ParamIsDefault(wv))
			if(WaveRefsEqual(refWave, wv))
				RemoveFromGraph/W=$graph $refTrace
				removals += 1
				tryKillingTheWave = 1
			endif
		elseif(!ParamIsDefault(dfr))
			if(GetRowIndex(candidates, refWave=refWave) >= 0)
				RemoveFromGraph/W=$graph $refTrace
				removals += 1
				tryKillingTheWave = 1
			endif
		endif

		if(kill && tryKillingTheWave)
			KillOrMoveToTrash(wv=refWave)
		endif

		tryKillingTheWave = 0
	endfor

	return removals
End

/// @brief Create a backup of the wave wv if it does not already
/// exist or if `forceCreation` is true.
///
/// The backup wave will be located in the same data folder and
/// its name will be the original name with #WAVE_BACKUP_SUFFIX
/// appended.
Function/Wave CreateBackupWave(wv, [forceCreation])
	Wave wv
	variable forceCreation

	string backupname
	dfref dfr

	ASSERT(WaveExists(wv), "missing wave")
	backupname = NameOfWave(wv) + WAVE_BACKUP_SUFFIX
	dfr        = GetWavesDataFolderDFR(wv)

	if(ParamIsDefault(forceCreation))
		forceCreation = 0
	else
		forceCreation = !!forceCreation
	endif

	Wave/Z/SDFR=dfr backup = $backupname

	if(WaveExists(backup) && !forceCreation)
		return backup
	endif

	Duplicate/O wv, dfr:$backupname/Wave=backup

	return backup
End

/// @brief Return a wave reference to the possibly not existing backup wave
Function/WAVE GetBackupWave(wv)
	WAVE wv

	string backupname

	ASSERT(WaveExists(wv), "Found no original wave")

	backupname = NameOfWave(wv) + WAVE_BACKUP_SUFFIX
	DFREF dfr  = GetWavesDataFolderDFR(wv)

	WAVE/Z/SDFR=dfr backup = $backupname

	return backup
End

/// @brief Replace the wave wv with its backup. If possible the backup wave will be killed afterwards.
///
/// @param wv                       wave to replace by its backup
/// @param nonExistingBackupIsFatal [optional, defaults to true] behaviour for the case that there is no backup.
///                                 Passing a non-zero value will abort if the backup wave does not exist, with
///                                 zero it will just do nothing.
/// @returns wave reference to the restored data, in case of no backup an invalid wave reference
Function/Wave ReplaceWaveWithBackup(wv, [nonExistingBackupIsFatal])
	Wave wv
	variable nonExistingBackupIsFatal

	if(ParamIsDefault(nonExistingBackupIsFatal))
		nonExistingBackupIsFatal = 1
	endif

	WAVE/Z backup = GetBackupWave(wv)

	if(!WaveExists(backup))
		if(nonExistingBackupIsFatal)
			DoAbortNow("Backup wave does not exist")
		endif

		return $""
	endif

	Duplicate/O backup, wv
	KillOrMoveToTrash(wv=backup)

	return wv
End

/// @brief Returns 1 if the user cancelled, zero if SaveExperiment was called
///
/// It is currently not possible to check if SaveExperiment was successfull
/// (E-Mail from Howard Rodstein WaveMetrics, 30 Jan 2015)
///
/// @param path                    Igor symbolic path where the experiment should be stored
/// @param filename 			   filename of the experiment *including* suffix, usually #PACKED_FILE_EXPERIMENT_SUFFIX
/// @param overrideInteractiveMode [optional, defaults to GetInteractiveMode()] Overrides the current setting of
///                                the interactive mode
Function SaveExperimentWrapper(path, filename, [overrideInteractiveMode])
	string path, filename
	variable overrideInteractiveMode

	variable refNum, pathNeedsKilling

	if(ParamIsDefault(overrideInteractiveMode))
		NVAR interactiveMode = $GetInteractiveMode()
		overrideInteractiveMode = interactiveMode
	else
		overrideInteractiveMode = !!overrideInteractiveMode
	endif

	if(overrideInteractiveMode)
		Open/D/M="Save experiment"/F="All Files:.*;"/P=$path refNum as filename

		if(isEmpty(S_fileName))
			return 1
		endif
	else
		if(isEmpty(path))
			PathInfo Desktop
			if(!V_flag)
				NewPath/Q Desktop, SpecialDirPath("Desktop", 0, 0, 0)
			endif
			path = "Desktop"
			pathNeedsKilling = 1
		endif
		Open/Z/P=$path refNum as filename

		if(pathNeedsKilling)
			KillPath/Z $path
		endif

		if(V_flag != 0)
			return 1
		endif

		Close refNum
	endif

	SaveExperiment as S_fileName
	return 0
End

/// @brief Detects duplicate values in a 1d wave.
///
/// @return one if duplicates could be found, zero otherwise
Function SearchForDuplicates(wv)
	WAVE wv

	ASSERT(WaveExists(wv), "Missing wave")

	Make/FREE/U/I/N=0 idx
	FindDuplicates/Z/INDX=idx wv

	return DimSize(idx, ROWS) > 0
End

/// @brief Check that the device can act as a follower
Function DeviceCanFollow(panelTitle)
	string panelTitle

	string deviceType, deviceNumber
	if(!ParseDeviceString(panelTitle, deviceType, deviceNumber))
		return 0
	endif

	return !cmpstr(deviceType, "ITC1600")
End

/// @brief Check that the device is a follower
Function DeviceIsFollower(panelTitle)
	string panelTitle

	if(!DeviceCanFollow(panelTitle))
		return 0
	endif

	SVAR listOfFollowerDevices = $GetFollowerList(ITC1600_FIRST_DEVICE)

	return WhichListItem(panelTitle, listOfFollowerDevices) != -1
End

/// @brief Check that the device can act as a leader
Function DeviceCanLead(panelTitle)
	string panelTitle

	return !cmpstr(panelTitle, ITC1600_FIRST_DEVICE)
End

/// @brief Check that the device is a leader and has followers
Function DeviceHasFollower(panelTitle)
	string panelTitle

	if(!DeviceCanLead(panelTitle))
		return 0
	endif

	SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)

	return ItemsInList(listOfFollowerDevices) > 0
End

/// @brief Convenience wrapper for GetFollowerList()
///
/// For iterating over a list of all followers and the leader. Returns just
/// panelTitle if the device can not lead.
Function/S GetListofLeaderAndPossFollower(panelTitle)
	string panelTitle

	if(!DeviceCanLead(panelTitle))
		return panelTitle
	endif

	SVAR followerList = $GetFollowerList(panelTitle)
	return AddListItem(panelTitle, followerList, ";", 0)
End

/// @brief Return a path to the program folder with trailing dir separator
///
/// Hardcoded as Igor does not allow to query that information.
///
/// Distinguishes between i386 and x64 Igor versions
Function/S GetProgramFilesFolder()

#if defined(IGOR64)
	return "C:\\Program Files\\"
#else
	return "C:\\Program Files (x86)\\"
#endif
End

/// @brief Return the default name of a electrode
Function/S GetDefaultElectrodeName(headstage)
	variable headstage

	ASSERT(headstage >=0 && headstage < NUM_HEADSTAGES, "Invalid headstage")

	return num2str(headstage)
End

/// @brief Create a labnotebook key for unassociated channels
Function/S CreateLBNUnassocKey(setting, channelNumber)
	string setting
	variable channelNumber

	string key

	sprintf key, "%s UNASSOC_%d", setting, channelNumber

	return key
End

/// @brief Parse a control name for the "Channel Selection Panel" and return
///        its channel type and number.
Function ParseChannelSelectionControl(ctrl, channelType, channelNum)
	string ctrl
	string &channelType
	variable &channelNum

	sscanf ctrl, "check_channelSel_%[^_]_%d", channelType, channelNum
	ASSERT(V_flag == 2, "Unexpected control name format")
End

/// @brief Set the channel selection dialog controls according to the channel
///        selection wave
Function ChannelSelectionWaveToGUI(panel, channelSel)
	string panel
	WAVE channelSel

	string list, channelType, ctrl
	variable channelNum, numEntries, i

	list = ControlNameList(panel, ";", "check_channelSel_*")
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		ParseChannelSelectionControl(ctrl, channelType, channelNum)
		SetCheckBoxState(panel, ctrl, channelSel[channelNum][%$channelType])
	endfor
End

/// @brief Removes the disabled channels and headstages from `ADCs` and `DACs`
Function RemoveDisabledChannels(channelSel, ADCs, DACs, numericalValues, sweepNo)
	WAVE/Z channelSel
	WAVE ADCs, DACs, numericalValues
	variable sweepNo

	variable numADCs, numDACs, i

	if(!WaveExists(channelSel) || (WaveMin(channelSel) == 1 && WaveMax(channelSel) == 1))
		return NaN
	endif

	Duplicate/FREE channelSel, channelSelMod

	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)

	WAVE/Z statusDAC = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z statusADC = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)
	WAVE/Z statusHS  = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)

	// disable the AD/DA channels not wanted by the headstage setting first
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!channelSelMod[i][%HEADSTAGE] && statusHS[i])
			channelSelMod[statusADC[i]][%AD] = 0
			channelSelMod[statusDAC[i]][%DA] = 0
		endif
	endfor

	// start at the end of the config wave
	// we always have the order DA/AD/TTLs
	for(i = numADCs - 1; i >= 0; i -= 1)
		if(!channelSelMod[ADCs[i]][%AD])
			DeletePoints/M=(ROWS) i, 1, ADCs
		endif
	endfor

	for(i = numDACs - 1; i >= 0; i -= 1)
		if(!channelSelMod[DACs[i]][%DA])
			DeletePoints/M=(ROWS) i, 1, DACs
		endif
	endfor
End

/// @brief Start the ZeroMQ message handler
///
/// Debug note: Tracking the connection state can be done via
/// `netstat | grep $port`. The binded port only shows up *after* a
/// successfull connection with zeromq_client_connect() is established.
Function StartZeroMQMessageHandler()

	variable i, port, err

#if exists("zeromq_stop")

	zeromq_stop()

#if defined(DEBUGGING_ENABLED)
	zeromq_set(ZeroMQ_SET_FLAGS_DEBUG | ZeroMQ_SET_FLAGS_DEFAULT)
#else
	zeromq_set(ZeroMQ_SET_FLAGS_DEFAULT)
#endif

	for(i = 0; i < ZEROMQ_NUM_BIND_TRIALS; i += 1)
		port = ZEROMQ_BIND_REP_PORT + i
		zeromq_server_bind("tcp://127.0.0.1:" + num2str(port)); err = GetRTError(1)

		if(err != 0)
			DEBUGPRINT("The port is in use:", var=port)
			continue
		endif

		zeromq_handler_start(); err = GetRTError(1)
		if(err != 0)
			zeromq_stop() // restart from scratch
			continue
		endif

		DEBUGPRINT("Successfully listening on port:", var=port)
		return NaN
	endfor

	ASSERT(0, "Could not start ZeroMQ Message Handler!")

#else

	DEBUGPRINT("ZeroMQ XOP is not present")

#endif
End

/// @brief Split an ITCDataWave into one 1D-wave per channel/ttlBit
///
/// @param numericalValues numerical labnotebook
/// @param sweep           sweep number
/// @param sweepWave       ITCDataWave
/// @param configWave      ITCChanConfigWave
/// @param targetDFR       [optional, defaults to the sweep wave DFR] datafolder where to put the waves, can be a free datafolder
Function SplitSweepIntoComponents(numericalValues, sweep, sweepWave, configWave, [targetDFR])
	WAVE numericalValues, sweepWave, configWave
	variable sweep
	DFREF targetDFR

	variable numRows, i, channelNumber
	string channelType, str

	if(ParamIsDefault(targetDFR))
		DFREF targetDFR = GetWavesDataFolderDFR(sweepWave)
	endif

	ASSERT(DataFolderExistsDFR(targetDFR), "targetDFR must exist")
	ASSERT(IsFinite(sweep), "Sweep number must be finite")
	ASSERT(IsValidSweepAndConfig(sweepWave, configWave), "Sweep and config waves are not compatible")

	numRows = DimSize(configWave, ROWS)
	for(i = 0; i < numRows; i += 1)
		channelType = StringFromList(configWave[i][0], ITC_CHANNEL_NAMES)
		ASSERT(!isEmpty(channelType), "empty channel type")
		channelNumber = configWave[i][1]
		ASSERT(IsFinite(channelNumber), "non-finite channel number")
		str = channelType + "_" + num2istr(channelNumber)

		WAVE data = ExtractOneDimDataFromSweep(configWave, sweepWave, i)

		if(!cmpstr(channelType, "TTL"))
			SplitTTLWaveIntoComponents(data, GetTTLBits(numericalValues, sweep, channelNumber), targetDFR, str + "_")
		endif

		MoveWave data, targetDFR:$str
	endfor

	string/G targetDFR:note = note(sweepWave)
End

/// @brief Add user data "panelVersion" to the panel
Function AddVersionToPanel(win, version)
	string win
	variable version

	SetWindow $win, userData(panelVersion) = num2str(version)
End

/// @brief Return 1 if the panel is up to date, zero otherwise
Function HasPanelLatestVersion(win, expectedVersion)
	string win
	variable expectedVersion

	variable version

#ifdef EVIL_KITTEN_EATING_MODE
	return 1
#endif

	version = GetPanelVersion(win)

	return version == expectedVersion
End

/// @brief Get the user data "panelVersion"
///
/// @param win panel window as string
/// @returns numeric panel version greater 0 and -1 if no version is present
Function GetPanelVersion(win)
	string win

	variable version

	ASSERT(windowExists(win), "Non existent window")

	version = str2numSafe(GetUserData(win, "", "panelVersion"))
	version = abs(version)
	if(IsNaN(version))
		version = -1
	endif
	return version
End

Function UPDATESWEEPPLOT_PROTOTYPE(win, [optArg])
	string win
	variable optArg

	ASSERT(0, "Calling prototype functions is an error!")
End

Function UpdateSweepPlot(win)
	string win

	if(BSP_IsDataBrowser(win))
		FUNCREF UPDATESWEEPPLOT_PROTOTYPE f = $"DB_UpdateSweepPlot"
	else
		FUNCREF UPDATESWEEPPLOT_PROTOTYPE f = $"SB_UpdateSweepPlot"
	endif

	return f(GetMainWindow(win))
End

/// @brief Stringified short version of the clamp mode
Function/S ConvertAmplifierModeShortStr(mode)
	variable mode

	switch(mode)
		case V_CLAMP_MODE:
			return "VC"
			break
		case I_CLAMP_MODE:
			return "IC"
			break
		case I_EQUAL_ZERO_MODE:
			return "IZ"
			break
		default:
			return "Unknown mode (" + num2str(mode) + ")"
			break
	endswitch
End

/// @brief Stringified version of the clamp mode
Function/S ConvertAmplifierModeToString(mode)
	variable mode

	switch(mode)
		case V_CLAMP_MODE:
			return "V_CLAMP_MODE"
			break
		case I_CLAMP_MODE:
			return "I_CLAMP_MODE"
			break
		case I_EQUAL_ZERO_MODE:
			return "I_EQUAL_ZERO_MODE"
			break
		default:
			return "Unknown mode (" + num2str(mode) + ")"
			break
	endswitch
End

/// @brief Update the repurposed sweep time global variable
///
/// Currently only useful for handling mid sweep analysis functions.
Function UpdateLeftOverSweepTime(panelTitle, fifoPos)
	string panelTitle
	variable fifoPos

	string msg

	ASSERT(IsFinite(fifoPos), "Unexpected non-finite fifoPos")

	WAVE ITCDataWave         = GetHardwareDataWave(panelTitle)
	NVAR repurposedTime      = $GetRepurposedSweepTime(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)

	repurposedTime += max(0, IndexToScale(ITCDataWave, stopCollectionPoint - fifoPos, ROWS)) / 1e3

	sprintf msg, "Repurposed time in seconds due to premature sweep stopping: %g\r", repurposedTime
	DEBUGPRINT(msg)
End

/// @brief Calculate deltaI/deltaV from a testpulse like stimset in "Current Clamp" mode
/// @todo unify with TP_Delta code
/// @todo add support for evaluating "inserted TP" only
Function CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)
	WAVE numericalValues, textualValues, sweep, deltaI, deltaV, resistance

	variable i
	variable DAcol, ADcol, level, low, high, baseline, elevated, firstEdge, secondEdge, sweepNo
	variable totalOnsetDelay, first, last
	string msg

	sweepNo     = ExtractSweepNumber(NameofWave(sweep))
	WAVE config = GetConfigWave(sweep)

	totalOnsetDelay = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE) + \
					  GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE)

	WAVE ADCs = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)
	WAVE DACs = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)

	WAVE/T ADunit = GetLastSetting(textualValues, sweepNo, "AD Unit", DATA_ACQUISITION_MODE)
	WAVE/T DAunit = GetLastSetting(textualValues, sweepNo, "DA Unit", DATA_ACQUISITION_MODE)

	WAVE statusHS = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DAcol = AFH_GetITCDataColumn(config, DACs[i], ITC_XOP_CHANNEL_TYPE_DAC)
		ADcol = AFH_GetITCDataColumn(config, ADCs[i], ITC_XOP_CHANNEL_TYPE_ADC)

		WAVE DA = ExtractOneDimDataFromSweep(config, sweep, DACol)
		WAVE AD = ExtractOneDimDataFromSweep(config, sweep, ADcol)

		first = totalOnsetDelay
		last  = IndexToScale(DA, DimSize(DA, ROWS) - 1, ROWS)

		low  = WaveMin(DA, first, last)
		high = WaveMax(DA, first, last)

		level = low + 0.1 * (high - low)

		Make/FREE/D levels
		FindLevels/Q/P/DEST=levels/R=(first, last)/N=2 DA, level
		ASSERT(V_LevelsFound >= 2, "Could not find enough levels")

		firstEdge   = levels[0]
		secondEdge  = levels[1]

		low  = floor(firstEdge * 0.9)
		high = floor(firstEdge - 1)

		baseline = sum(AD, IndexToScale(AD, low, ROWS), IndexToScale(AD, high, ROWS)) / (high - low + 1)

		sprintf msg, "(%d) AD: low = %d (%g ms), high = %d (%g ms), baseline %g", i, low, IndexToScale(AD, low, ROWS), high, IndexToScale(AD, high, ROWS), baseline
		DEBUGPRINT(msg)

		low  = floor(secondEdge * 0.9)
		high = floor(secondEdge - 1)

		elevated = sum(AD, IndexToScale(AD, low, ROWS), IndexToScale(AD, high, ROWS)) / (high - low + 1)

		sprintf msg, "(%d) AD: low = %d (%g ms), high = %d (%g ms), elevated %g", i, low, IndexToScale(AD, low, ROWS),  high, IndexToScale(AD, high, ROWS), elevated
		DEBUGPRINT(msg)

		// convert from mv to V
		ASSERT(!cmpstr(ADunit[i], "mV"), "Unexpected AD Unit")

		deltaV[i] = (elevated - baseline) * 1e-3

		low  = floor(firstEdge * 0.9)
		high = floor(firstEdge - 1)

		baseline = sum(DA, IndexToScale(DA, low, ROWS), IndexToScale(DA, high, ROWS)) / (high - low + 1)

		sprintf msg, "(%d) DA: low = %d (%g ms), high = %d (%g ms), baseline %g", i, low, IndexToScale(DA, low, ROWS), high, IndexToScale(DA, high, ROWS), elevated
		DEBUGPRINT(msg)

		low  = floor(secondEdge * 0.9)
		high = floor(secondEdge - 1)

		elevated = sum(DA, IndexToScale(DA, low, ROWS), IndexToScale(DA, high, ROWS)) / (high - low + 1)

		sprintf msg, "(%d) DA: low = %d (%g ms), high = %d (%g ms), elevated %g", i, low, IndexToScale(DA, low, ROWS), high, IndexToScale(DA, high, ROWS), elevated
		DEBUGPRINT(msg)

		// convert from pA to A
		ASSERT(!cmpstr(DAunit[i], "pA"), "Unexpected DA Unit")
		deltaI[i] = (elevated - baseline) * 1e-12

		resistance[i] = deltaV[i] / deltaI[i]

		sprintf msg, "(%d): R = %.0W1PΩ, ΔU = %.0W1PV, ΔI = %.0W1PA", i, resistance[i], deltaV[i], deltaI[i]
		DEBUGPRINT(msg)
	endfor
End

/// @brief Move the source wave to the location of the given destination wave.
///        The destination wave must be a permanent wave.
///
///        Workaround for `MoveWave` having no `/O` flag.
///
/// @param dest permanent wave
/// @param src  wave (free or permanent)
Function/WAVE MoveWaveWithOverwrite(dest, src)
	WAVE dest, src

	string path

	ASSERT(WaveType(dest, 2) == 1, "dest must be a global/permanent wave")

	path = GetWavesDataFolder(dest, 2)

	KillOrMoveToTrash(wv=dest)
	MoveWave src, $path
End

/// @brief Check if the given wave is a valid ITCConfigWave
Function IsValidConfigWave(config)
	WAVE/Z config

	return WaveExists(config) &&        \
		   DimSize(config, ROWS) > 0 && \
		   DimSize(config, COLS) >= 4
End

/// @brief Check if the given wave is a valid ITCDataWave
Function IsValidSweepWave(sweep)
	WAVE/Z sweep

	return WaveExists(sweep) &&        \
		   DimSize(sweep, COLS) > 0 && \
		   DimSize(sweep, ROWS) > 0
End

/// @brief Check if the two waves are valid and compatible
Function IsValidSweepAndConfig(sweep, config)
	WAVE/Z sweep, config

	return IsValidConfigWave(config) &&                  \
		   IsValidSweepWave(sweep) &&                    \
		   DimSize(sweep, COLS) == DimSize(config, ROWS)
End

/// @brief Return the next random number using the device specific RNG seed
Function GetNextRandomNumberForDevice(panelTitle)
	string panelTitle

	NVAR rngSeed = $GetRNGSeed(panelTitle)
	ASSERT(IsFinite(rngSeed), "Invalid rngSeed")
	SetRandomSeed/BETR=1 rngSeed
	rngSeed += 1

	// scale to the available mantissa bits in a single precision variable
	return trunc(GetReproducibleRandom() * 2^23)
End

/// @brief Maps the labnotebook entry source type, one of @ref DataAcqModes, to
///        a valid wave index.
Function EntrySourceTypeMapper(entrySourceType)
	variable entrySourceType

	return IsFinite(entrySourceType) ? ++entrySourceType : 0
End
