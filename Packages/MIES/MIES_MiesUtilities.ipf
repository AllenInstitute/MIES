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

	ASSERT(IsValidConfigWave(config, version=0), "Invalid config wave")

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

/// @brief Returns the number of given mode channels from channelType wave
///
/// @param chanTypes a 1D wave containing @ref DaqChannelTypeConstants, returned by GetADCTypesFromConfig()
///
/// @param type to count, one of @ref DaqChannelTypeConstants
///
/// @return number of types present in chanTypes
Function GetNrOfTypedChannels(chanTypes, type)
	WAVE chanTypes
	variable type

	variable i, numChannels, count

	ASSERT(type == DAQ_CHANNEL_TYPE_UNKOWN || type == DAQ_CHANNEL_TYPE_DAQ || type == DAQ_CHANNEL_TYPE_TP, "Invalid type")
	numChannels = DimSize(chanTypes, ROWS)
	for(i = 0; i < numChannels; i += 1)
		if(chanTypes[i] == type)
			count += 1
		endif
	endfor

	return count
End

/// @brief Return a types of the AD channels from the ITC config
Function/WAVE GetTTLTypesFromConfig(config)
	WAVE config

	return GetTypeListFromITCConfig(config, ITC_XOP_CHANNEL_TYPE_TTL)
End

/// @brief Return a types of the AD channels from the ITC config
Function/WAVE GetADCTypesFromConfig(config)
	WAVE config

	return GetTypeListFromITCConfig(config, ITC_XOP_CHANNEL_TYPE_ADC)
End

/// @brief Return a types of the DA channels from the ITC config
Function/WAVE GetDACTypesFromConfig(config)
	WAVE config

	return GetTypeListFromITCConfig(config, ITC_XOP_CHANNEL_TYPE_DAC)
End

/// @brief Return a wave with all active channels
///
/// @todo change to return a 0/1 wave with constant size a la DAG_GetChannelState
///
/// @param config       ITCChanConfigWave as passed to the ITC XOP
/// @param channelType  DA/AD/TTL constants, see @ref ChannelTypeAndControlConstants
static Function/WAVE GetTypeListFromITCConfig(config, channelType)
	WAVE config
	variable channelType

	variable numRows, i, j

	ASSERT(IsValidConfigWave(config, version=2), "Invalid config wave")

	numRows = DimSize(config, ROWS)
	Make/U/B/FREE/N=(numRows) activeChannels

	for(i = 0; i < numRows; i += 1)
		if(channelType == config[i][%ChannelType])
			activeChannels[j] = config[i][%DAQChannelType]
			j += 1
		endif
	endfor

	Redimension/N=(j) activeChannels

	return activeChannels
End

/// @brief Checks if a channel of TP type exists on ADCs
///
/// @param panelTitle device
///
/// @return 1 if TP type present, 0 otherwise
Function GotTPChannelsOnADCs(panelTitle)
	string panelTitle

	WAVE config = GetITCChanConfigWave(panelTitle)
	WAVE ADCmode = GetADCTypesFromConfig(config)
	FindValue/I=(DAQ_CHANNEL_TYPE_TP) ADCmode
	return (V_Value != -1)
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

			// we don't have an entry source type in the labnotebook set
			// throw away entries which are obviously from a different (guessed) entry source type
			if(!WaveExists(indizesSourceType))
				if(entrySourceType == DATA_ACQUISITION_MODE)

					// "TP Peak Resistance" introduced in 666d761a (TP documenting is implemented using David Reid's documenting functions, 2014-07-28)
					if(FindDimLabel(wv, COLS, "TP Peak Resistance") >= 0)
						WAVE/Z indizesDefinitlyTP = FindIndizes(wv, colLabel="TP Peak Resistance", prop=PROP_NON_EMPTY, startRow = WaveMin(indizesSetting), endRow = WaveMax(indizesSetting), startLayer = 0, endLayer = LABNOTEBOOK_LAYER_COUNT - 1)
						if(WaveExists(indizesDefinitlyTP) && WaveExists(indizesSetting))
							WAVE/Z indizesSettingRemoved = GetSetDifference(indizesSetting, indizesDefinitlyTP)
							WAVE/Z indizesSetting = indizesSettingRemoved
						endif
					endif

					// "TP Baseline Fraction" introduced in 4f4649a2 (Document the testpulse settings in the labnotebook, 2015-07-28)
					if(FindDimLabel(wv, COLS, "TP Baseline Fraction") >= 0)
						WAVE/Z indizesDefinitlyTP = FindIndizes(wv, colLabel="TP Baseline Fraction", prop=PROP_NON_EMPTY, startRow = WaveMin(indizesSetting), endRow = WaveMax(indizesSetting), startLayer = 0, endLayer = LABNOTEBOOK_LAYER_COUNT - 1)
						if(WaveExists(indizesDefinitlyTP) && WaveExists(indizesSetting))
							WAVE/Z indizesSettingRemoved = GetSetDifference(indizesSetting, indizesDefinitlyTP)
							WAVE/Z indizesSetting = indizesSettingRemoved
						endif
					endif
				endif
			endif
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

	// Old label prior to 4caea03f
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

/// @brief Return a numerical or text setting for the given channel
///
/// @return the wave containing the setting and the index into it.
///
/// @ingroup LabnotebookQueryFunctions
/// @sa GetLastSettingChannelInternal()
Function [WAVE/Z settings, variable index] GetLastSettingChannel(WAVE numericalValues, WAVE/T/Z textualValues, variable sweepNo, string setting, variable channelNumber, variable channelType, variable entrySourceType)

	[settings, index] = GetLastSettingChannelInternal(numericalValues, numericalValues, sweepNo, setting, channelNumber, channelType, entrySourceType)
	if(WaveExists(settings))
		if(IsNaN(settings[index]))
			return [settings, GetIndexForHeadstageIndepData(numericalValues)]
		else
			return [settings, index]
		endif
	endif

	if(!WaveExists(textualValues))
		return [$"", NaN]
	endif

	[settings, index] = GetLastSettingChannelInternal(numericalValues, textualValues, sweepNo, setting, channelNumber, channelType, entrySourceType)
	if(WaveExists(settings))
		WAVE/T settingsT = settings
		if(!cmpstr(settingsT[index], ""))
			return [settingsT, GetIndexForHeadstageIndepData(textualValues)]
		else
			return [settingsT, index]
		endif
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
/// @param channelType     channel type, one of @ref ItcXopChannelConstants
/// @param entrySourceType type of the labnotebook entry, one of @ref DataAcqModes.
///                        If you don't care about the entry source type pass #UNKNOWN_MODE.
///
/// @return A tuple of the result wave and the index into it.
///
/// @sa GetLastSettingChannel
static Function [WAVE/Z wv, variable index] GetLastSettingChannelInternal(WAVE numericalValues, WAVE values, variable sweepNo, string setting, variable channelNumber, variable channelType, variable entrySourceType)
	string entryName

	switch(channelType)
		case ITC_XOP_CHANNEL_TYPE_DAC:
			entryName = "DAC"
			break
		case ITC_XOP_CHANNEL_TYPE_ADC:
			entryName = "ADC"
			break
		default:
			ASSERT(0, "Unsupported channelType")
	endswitch

	WAVE/Z activeChannels = GetLastSetting(numericalValues, sweepNo, entryName, entrySourceType)

	if(WaveExists(activeChannels))
		WAVE/Z indizes = FindIndizes(activeChannels, col=0, var=channelNumber)
		if(WaveExists(indizes))
			// associated entry
			ASSERT(DimSize(indizes, ROWS) == 1, "Unexpected size")

			WAVE/Z settings = GetLastSetting(values, sweepNo, setting, entrySourceType)

			if(WaveExists(settings))
				return [settings, indizes[0]]
			endif

			return [$"", NaN]
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
						status[] = numericalValues[i][pulseDurationCol][p]
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
							blockType = TEST_PULSE_MODE
							testpulseBlockLength = 1
						else
							blockType = DATA_ACQUISITION_MODE
						endif
					else // no match, maybe old format
						status[] = numericalValues[i][peakResistanceCol][p]
						if(HasOneValidEntry(status))
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
	ASSERT(IsNumericWave(numericalValues), "Can only work with numeric waves")

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
	ASSERT(IsTextWave(textualValues), "Can only work with text waves")

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
///        which were locked at some point
Function/S GetAllDevices()

	variable i, j, numEntries, numNumbers
	string folder, number, device, folders
	string path, list = ""

	DFREF devicesFolder = GetITCDevicesFolder()

	numNumbers = ItemsInList(DEVICE_NUMBERS)

	folders = GetListOfObjects(devicesFolder, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER)
	numEntries = ItemsInList(folders)
	for(i = 0; i < numEntries; i += 1)
		folder = StringFromList(i, folders)

		if(GrepString(folder, "^ITC.*"))
			// ITC hardware is in a specific subfolder
			for(j = 0; j < numNumbers ; j += 1)
				number = StringFromList(j, DEVICE_NUMBERS)
				device = BuildDeviceString(folder, number)
				path   = GetDevicePathAsString(device)

				if(DataFolderExists(path))
					DFREF dfr = $path
					NVAR/SDFR=dfr/Z ITCDeviceIDGlobal

					if(NVAR_Exists(ITCDeviceIDGlobal))
						list = AddListItem(device, list, ";", inf)
					endif
				endif
			endfor
		else
			// other hardware has no subfolder
			device = folder
			path = GetDevicePathAsString(device)

			if(DataFolderExists(path))
				DFREF dfr = $path
				NVAR/SDFR=dfr/Z ITCDeviceIDGlobal

				if(NVAR_Exists(ITCDeviceIDGlobal))
					list = AddListItem(device, list, ";", inf)
				endif
			endif
		endif
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

	deviceList = GetAllDevices()

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
threadsafe Function KillOrMoveToTrash([wv, dfr])
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
threadsafe Function KillOrMoveToTrashPath(path)
	string path

	string dest

	if(DataFolderExists(path))
		KillDataFolder/Z $path

		if(!V_flag)
			return NaN
		endif

		MoveToTrash(dfr = $path)
	elseif(WaveExists($path))
		KillWaves/Z $path

		WAVE/Z wv = $path
		if(!WaveExists(wv))
			return NaN
		endif

		MoveToTrash(wv = wv)
	else
		DEBUGPRINT_TS("Ignoring the datafolder/wave as it does not exist", str=path)
	endif
End

threadsafe Function MoveToTrash([wv, dfr])
	WAVE/Z wv
	DFREF dfr

	string dest

	if(!ParamIsDefault(wv) && WaveExists(wv))
		DFREF tmpDFR = GetUniqueTempPath()
		MoveWave wv, tmpDFR
	endif

	if(!ParamIsDefault(dfr) && DataFolderExistsDFR(dfr))
		DFREF tmpDFR = GetUniqueTempPath()
		dest = RemoveEnding(GetDataFolder(1, tmpDFR), ":")
		MoveDataFolder dfr, $dest
	endif
End

/// @brief Return a wave reference wave with all single column waves of the given channel type
///
/// Holds invalid wave refs for non-existing entries.
///
/// @param sweepDFR    datafolder reference with 1D sweep data
/// @param channelType One of @ref ItcXopChannelConstants
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
/// @param channelType   One of @ref ItcXopChannelConstants
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
	WAVE sweepWave

	WAVE/SDFR=GetWavesDataFolderDFR(sweepWave) config = $GetConfigWaveName(ExtractSweepNumber(NameOfWave(sweepWave)))

	return config
End

/// @brief Returns the, possibly non existing, sweep data wave for the given sweep number
Function/Wave GetSweepWave(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	Wave/Z/SDFR=GetDeviceDataPath(panelTitle) wv = $GetSweepWaveName(sweepNo)

	return wv
End

/// @brief Return the config wave name
Function/S GetConfigWaveName(sweepNo)
	variable sweepNo

	return "Config_" + GetSweepWaveName(sweepNo)
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

	ASSERT(IsValidConfigWave(config, version=0), "Expected a valid config wave")

	// from ITCConfigAllChannels help file:
	// Third Column  = SamplingInterval:  integer value for sampling interval in microseconds (minimum value - 5 us)
	Duplicate/D/R=[][2]/FREE config samplingInterval

	// The sampling interval is the same for all channels
	ASSERT(WaveMax(samplingInterval) == WaveMin(samplingInterval),"Expected constant sample interval for all channels")
	return samplingInterval[0]
End

/// @brief Returns the data offset of the sweep in points
threadsafe Function GetDataOffset(config)
	Wave config

	ASSERT_TS(IsValidConfigWave(config, version=1),"Expected a valid config wave")

	Duplicate/D/R=[][4]/FREE config, offsets

	// The data offset is the same for all channels
	ASSERT_TS(WaveMax(offsets) == WaveMin(offsets), "Expected constant data offset for all channels")
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

/// @brief Return the hardware type of the device
///
/// @return One of @ref HardwareDACTypeConstants
threadsafe Function GetHardwareType(panelTitle)
	string panelTitle

	string deviceType, deviceNumber
	ASSERT_TS(ParseDeviceString(panelTitle, deviceType, deviceNumber), "Error parsing device string!")

	if(WhichListItem(deviceType, DEVICE_TYPES_ITC) != -1)
		return HARDWARE_ITC_DAC
	elseif(IsEmpty(deviceNumber))
		return HARDWARE_NI_DAC
	endif

	return HARDWARE_UNSUPPORTED_DAC
End

/// @brief Parse a device string:
/// for ITC devices of the form X_DEV_Y, where X is from @ref DEVICE_TYPES_ITC
/// and Y from @ref DEVICE_NUMBERS.
/// for NI devices of the form X, where X is from DAP_GetNIDeviceList()
///
/// Returns the result in deviceType and deviceNumber.
/// Currently the parsing is successfull if
/// for ITC devices X and Y are non-empty.
/// for NI devices X is non-empty.
/// deviceNumber is empty for NI devices as it does not apply
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

	if(strsearch(device, "_Dev_", 0, 2) == -1)
		// NI device
		deviceType = device
		deviceNumber = ""
		return !isEmpty(deviceType) && cmpstr(deviceType, "DA")
	else
		// ITC device notation with X_Dev_Y
		deviceType   = StringFromList(0,device,"_")
		deviceNumber = StringFromList(2,device,"_")
		return !isEmpty(deviceType) && !isEmpty(deviceNumber) && cmpstr(deviceType, "DA")
	endif
End

/// @brief Builds device string
Function/S BuildDeviceString(deviceType, deviceNumber)
	string deviceType, deviceNumber

	ASSERT(!isEmpty(deviceType) && !isEmpty(deviceNumber), "empty device type or number");
// check what device we have
	if(FindListItem(deviceType, DAP_GetNIDeviceList()) > -1)
		return deviceType
	elseif(FindListItem(deviceType, DEVICE_TYPES_ITC) > -1)
		return deviceType + "_Dev_" + deviceNumber
	else
		ASSERT(0, "No NI or ITC device with this name found");
	endif
End

/// @brief Layout the DataBrowser/SweepBrowser graph
///
/// Takes also care of adding free axis for the headstage display.
///
/// Concept:
/// - Block [#]: One axis with surrounded GRAPH_DIV_SPACING space
/// - Slot [#]: Unit of vertical space, a block can occupy multiple slots
/// - We have 100% space for all axes
/// - AD axes should occupy four times the space of DA/TTL channels
/// - So DA/TTL occupy one slot, AD occupy four slots
/// - Between each axes we want GRAPH_DIV_SPACING clear space
/// - Count the number of vertical blocks and slots to be used
/// - Derive the space per slot
/// - For overlay channels we reserve only one slot times slot multiplier
///   per channel
///
/// The display order from top to bottom:
/// - Associated channels (above: DA, below: AD) with increasing headstage number
/// - Unassociated channels (above: DA, below: AD)
/// - TTL channels
///
/// For overlayed channels we have up to three blocks (DA, AD, TTL) in that order.
Function LayoutGraph(string win, STRUCT TiledGraphSettings &tgs)

	variable i, numSlots, headstage,  numBlocksTTL, numBlocks, spacePerSlot
	variable numBlocksDA, numBlocksAD, first, firstFreeAxis, lastFreeAxis, orientation
	variable numBlocksUnassocDA, numBlocksUnassocAD, numBlocksHS
	string graph, regex, freeAxis, axis
	variable last = 1.0

	graph = GetMainWindow(win)
	RemoveFreeAxisFromGraph(graph)

	WAVE/T/Z allVerticalAxesNonUnique = TUD_GetUserDataAsWave(graph, "YAXIS")

	if(!WaveExists(allVerticalAxesNonUnique))
		// empty graph
		return NaN
	endif

	WAVE/T allVerticalAxes = GetUniqueEntries(allVerticalAxesNonUnique)

	WAVE/T allHorizontalAxesNonUnique = TUD_GetUserDataAsWave(graph, "XAXIS")
	WAVE/T allHorizontalAxes = GetUniqueEntries(allHorizontalAxesNonUnique)

	if(tgs.overLayChannels)
		// up to three blocks

		regex = ".*DA$"
		WAVE/T/Z DAaxes = GrepWave(allVerticalAxes, regex)
		numBlocksDA = WaveExists(DAaxes) ? DimSize(DAaxes, ROWS) : 0

		regex = ".*AD$"
		WAVE/T/Z ADaxes = GrepWave(allVerticalAxes, regex)
		numBlocksAD = WaveExists(ADaxes) ? DimSize(ADaxes, ROWS) : 0

		regex = ".*TTL$"
		WAVE/T/Z TTLaxes = GrepWave(allVerticalAxes, regex)
		numBlocksTTL = WaveExists(TTLaxes) ? DimSize(TTLaxes, ROWS) : 0

		numBlocks = numBlocksAD + numBlocksDA + numBlocksTTL
		numSlots = ADC_SLOT_MULTIPLIER * numBlocksAD + numBlocksDA + numBlocksTTL

		spacePerSlot = (1.0 - (numBlocks - 1) * GRAPH_DIV_SPACING) / numSlots

		if(WaveExists(DAaxes))
			EnableAxis(graph, DAaxes, spacePerSlot, first, last)
		endif

		if(WaveExists(ADaxes))
			EnableAxis(graph, ADaxes, ADC_SLOT_MULTIPLIER * spacePerSlot, first, last)
		endif

		if(WaveExists(TTLaxes))
			EnableAxis(graph, TTLaxes, spacePerSlot, first, last)
		endif

		ASSERT(first < 1e-15, "Left over space")
		TweakAxes(graph, tgs, allVerticalAxes, allHorizontalAxes)

		return NaN
	endif

	// unassociated DA

	WAVE/T/Z unassocDANonUnique = TUD_GetUserDataAsWave(graph, "channelNumber", keys = {"channelType", "headstage"}, values = {"DA", "NaN"})
	if(WaveExists(unassocDANonUnique))
		WAVE/Z unassocDA = ConvertToUniqueNumber(unAssocDANonUnique, doSort = 1)
	endif

	numBlocksUnassocDA = WaveExists(unassocDA) ? DimSize(unassocDA, ROWS) : 0

	// unassociated AD

	WAVE/T/Z unassocADNonUnique = TUD_GetUserDataAsWave(graph, "channelNumber", keys = {"channelType", "headstage"}, values = {"AD", "NaN"})
	if(WaveExists(unassocADNonUnique))
		WAVE/Z unassocAD = ConvertToUniqueNumber(unassocADNonUnique, doSort = 1)
	endif

	numBlocksUnassocAD = WaveExists(unassocAD) ? DimSize(unassocAD, ROWS) : 0

	// number of headstages
	WAVE/T/Z headstagesNonUnique = TUD_GetUserDataAsWave(graph, "headstage")
	WAVE/Z headstages = ConvertToUniqueNumber(headstagesNonUnique, zapNaNs = 1, doSort = 1)

	numBlocksHS = WaveExists(headstages) ? DimSize(headstages, ROWS) : 0

	// associated DA channels
	regex = ".*col0_DA_(?:[[:digit:]]{1,2})_HS_(?:[[:digit:]]{1,2})$"
	WAVE/T/Z axes = GrepWave(allVerticalAxes, regex)
	numBlocksDA = WaveExists(axes) ? DimSize(axes, ROWS) : 0

	// associated AD channels
	regex = ".*col0_AD_(?:[[:digit:]]{1,2})_HS_(?:[[:digit:]]{1,2})$"
	WAVE/T/Z axes = GrepWave(allVerticalAxes, regex)
	numBlocksAD = WaveExists(axes) ? DimSize(axes, ROWS) : 0

	// create a text wave with all plotted TTL data in the form `TTL_$channel(_$ttlBit)?`
	WAVE/Z TTLsIndizes = TUD_GetUserDataAsWave(graph, "channelNumber", keys = {"channelType"}, values = {"TTL"}, returnIndizes = 1)

	if(WaveExists(TTLsIndizes))
		WAVE/T graphUserData = GetGraphUserData(graph)
		Make/FREE/T/N=(DimSize(TTLsIndizes, ROWS)) ttlsWithBitsUnsorted = "TTL_" + graphUserData[TTLsIndizes[p]][%channelNumber] + \
					                                                      "_" + graphUserData[TTLsIndizes[p]][%TTLBit]
		WAVE/T ttlsWithBits = GetUniqueEntries(ttlsWithBitsUnsorted)
	endif

	numBlocksTTL = WaveExists(ttlsWithBits) ? DimSize(ttlsWithBits, ROWS) : 0

	// Headstage: 5 slots
	// Unassoc DA: 1 slot
	// Unassoc DA: 4 slots
	// TTL: 1 slot per ttlsWithBits

	numBlocks = numBlocksAD + numBlocksDA + numBlocksUnassocDA + numBlocksUnassocAD + numBlocksTTL
	numSlots = ADC_SLOT_MULTIPLIER * numBlocksAD + numBlocksDA + numBlocksUnassocDA + ADC_SLOT_MULTIPLIER * numBlocksUnassocAD + numBlocksTTL

	spacePerSlot = (1.0 - (numBlocks - 1) * GRAPH_DIV_SPACING) / numSlots

	// starting from the top
	// headstages with associated channels
	for(i = 0; i < numBlocksHS; i += 1)
		headstage = headstages[i]
		regex = ".*DA_(?:[[:digit:]]{1,2})_HS_" + num2str(headstage)
		WAVE/T/Z axes = GrepWave(allVerticalAxes, regex)

		lastFreeAxis = last

		if(WaveExists(axes))
			EnableAxis(graph, axes, spacePerSlot, first, last)
		endif

		regex = ".*AD_(?:[[:digit:]]{1,2})_HS_" + num2str(headstage)
		WAVE/T/Z axes = GrepWave(allVerticalAxes, regex)
		if(WaveExists(axes))
			EnableAxis(graph, axes, ADC_SLOT_MULTIPLIER * spacePerSlot, first, last)
		endif

		firstFreeAxis = first

		freeAxis = "freeaxis_hs" + num2str(headstage)
		NewFreeAxis/W=$graph $freeAxis
		ModifyGraph/W=$graph standoff($freeAxis)=0, lblPosMode($freeAxis)=2, axRGB($freeAxis)=(65535,65535,65535,0), tlblRGB($freeAxis)=(65535,65535,65535,0), alblRGB($freeAxis)=(0,0,0), lblMargin($freeAxis)=0, lblLatPos($freeAxis)=0
		ModifyGraph/W=$graph axisEnab($freeAxis)={firstFreeAxis, lastFreeAxis}
		Label/W=$graph $freeAxis "HS" + num2str(headstage)
	endfor

	// unassoc DA
	for(i = 0; i < numBlocksUnassocDA; i += 1)
		regex = ".*DA_" + num2str(unassocDA[i]) + "_HS_NaN"
		WAVE/T/Z axes = GrepWave(allVerticalAxes, regex)
		ASSERT(WaveExists(axes), "Unexpected number of matches")
		EnableAxis(graph, axes, spacePerSlot, first, last)
	endfor

	// unassoc AD
	for(i = 0; i < numBlocksUnassocAD; i += 1)
		regex = ".*AD_" + num2str(unassocAD[i]) + "_HS_NaN"
		WAVE/T/Z axes = GrepWave(allVerticalAxes, regex)
		ASSERT(WaveExists(axes), "Unexpected number of matches")
		EnableAxis(graph, axes, ADC_SLOT_MULTIPLIER * spacePerSlot, first, last)
	endfor

	// TTLs
	for(i = 0; i < numBlocksTTL; i += 1)
		regex = ttlsWithBits[i]
		WAVE/T/Z axes = GrepWave(allVerticalAxes, regex)
		ASSERT(WaveExists(axes), "Unexpected number of matches")
		EnableAxis(graph, axes, spacePerSlot, first, last)

		if(tgs.splitTTLBits)
			axis = axes[0]
			ModifyGraph/W=$graph nticks($axis)=2, manTick($axis)={0,1,0,0}, manMinor($axis)={0,50}
		endif
	endfor

	ASSERT(first < 1e-15, "Left over space")
	TweakAxes(graph, tgs, allVerticalAxes, allHorizontalAxes)
End

static Function TweakAxes(string graph, STRUCT TiledGraphSettings &tgs, WAVE/T allVerticalAxes, WAVE/T allHorizontalAxes)

	variable i, numAxes
	string axis

	numAxes = DimSize(allVerticalAxes, ROWS)
	for(i = 0; i < numAxes; i += 1)
		axis = allVerticalAxes[i]

		ModifyGraph/W=$graph tickUnit($axis) = 1
		ModifyGraph/W=$graph lblPosMode($axis) = 2, standoff($axis) = 0, freePos($axis) = 0
		ModifyGraph/W=$graph lblLatPos($axis) = 3, lblMargin($axis) = 15

		if(tgs.dDAQDisplayMode)
			ModifyGraph/W=$graph freePos($axis) = 20
		endif
	endfor

	if(tgs.dDAQDisplayMode)
		numAxes = DimSize(allHorizontalAxes, ROWS)
		for(i = 0; i < numAxes; i += 1)
			axis = allHorizontalAxes[i]

			ModifyGraph/W=$graph alblRGB($axis)=(65535,65535,65535)
			Label/W=$graph $axis, "\u#2"
		endfor

		ModifyGraph/W=$graph axRGB=(65535,65535,65535), tlblRGB=(65535,65535,65535)
		ModifyGraph/W=$graph axThick=0
		ModifyGraph/W=$graph margin(left)=40, margin(bottom)=1
	else
		ModifyGraph/W=$graph margin(left)=0, margin(bottom)=0
	endif
End

/// @brief Helper function for LayoutGraph()
///
/// Enables the given axis between [last - spacePerSlot, last] and updates both on return.
/// Expects `last` to be 1.0 on the first call.
static Function EnableAxis(string graph, WAVE/T axes, variable spacePerSlot, variable &first, variable &last)

	string axis
	variable i, numAxes

	first = last - spacePerSlot

	first = max(0.0, first)
	last  = min(1.0, last)

	ASSERT(first < last, "Invalid order")

	numAxes = DimSize(axes, ROWS)
	ASSERT(numAxes >= 0, "Invalid number of axes")
	for(i = 0; i < numAxes; i += 1)
		ModifyGraph/W=$graph axisEnab($axes[i])={first, last}
	endfor

	last = first - GRAPH_DIV_SPACING
End

/// @brief Helper function for CreateTiledChannelGraph and friends
///
/// Return the next trace index for a graph which uses our trace data storage
/// wave.
Function GetNextTraceIndex(string graph)

	variable traceCount, traceIndex
	string lastTraceName

	traceCount = TUD_GetTraceCount(graph)

	if(traceCount == 0)
		return 0
	endif

	WAVE/T graphUserData = GetGraphUserData(graph)
	lastTraceName = graphUserData[traceCount - 1][%traceName]
	traceIndex = str2num(lastTraceName[1, inf]) + 1
	ASSERT(IsFinite(traceIndex), "Non finite trace index")

	return traceIndex
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
/// @param experiment      name of the experiment the sweep stems from
/// @param channelSelWave  channel selection wave
Function CreateTiledChannelGraph(graph, config, sweepNo, numericalValues,  textualValues, tgs, sweepDFR, axisLabelCache, traceIndex, experiment, channelSelWave)
	string graph
	WAVE config
	variable sweepNo
	WAVE numericalValues
	WAVE/T textualValues
	STRUCT TiledGraphSettings &tgs
	DFREF sweepDFR
	WAVE/T axisLabelCache
	variable &traceIndex
	string experiment
	WAVE channelSelWave

	variable red, green, blue, axisIndex, numChannels, offset
	variable numDACs, numADCs, numTTLs, i, j, k, hasPhysUnit, hardwareType
	variable moreData, chan, numHorizWaves, numVertWaves, idx
	variable numTTLBits, colorIndex, headstage
	variable delayOnsetUser, delayOnsetAuto, delayTermination, delaydDAQ, dDAQEnabled, oodDAQEnabled
	variable stimSetLength, samplingInt, xRangeStart, xRangeEnd, first, last, count, ttlBit
	variable numRegions, numEntries, numRangesPerEntry
	variable totalXRange = NaN

	string trace, traceType, channelID, axisLabel, entry, range, traceRange, traceColor
	string unit, name, str, vertAxis, oodDAQRegionsAll, dDAQActiveHeadstageAll, horizAxis, freeAxis

	ASSERT(!isEmpty(graph), "Empty graph")
	ASSERT(IsFinite(sweepNo), "Non-finite sweepNo")

	Make/T/FREE userDataKeys = {"fullPath", "channelType", "channelNumber", "sweepNumber", "headstage",               \
			  					"textualValues", "numericalValues", "clampMode", "TTLBit", "experiment", "traceType", \
								"occurence", "XAXIS", "YAXIS", "YRANGE", "TRACECOLOR"}

	WAVE ADCs = GetADCListFromConfig(config)
	WAVE DACs = GetDACListFromConfig(config)
	WAVE TTLs = GetTTLListFromConfig(config)

	BSP_RemoveDisabledChannels(channelSelWave, ADCs, DACs, numericalValues, sweepNo)

	numDACs = DimSize(DACs, ROWS)
	numADCs = DimSize(ADCs, ROWS)
	numTTLs = DimSize(TTLs, ROWS)

	// introduced in db531d20 (DC_PlaceDataInITCDataWave: Document the digitizer hardware type, 2018-07-30)
	// before that we only had ITC hardware
	hardwareType           = GetLastSettingIndep(numericalValues, sweepNo, "Digitizer Hardware Type", DATA_ACQUISITION_MODE, defValue = HARDWARE_ITC_DAC)
	WAVE/Z statusHS        = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)
	WAVE/Z ttlRackZeroBits = GetLastSetting(numericalValues, sweepNo, "TTL rack zero bits", DATA_ACQUISITION_MODE)
	WAVE/Z ttlRackOneBits  = GetLastSetting(numericalValues, sweepNo, "TTL rack one bits", DATA_ACQUISITION_MODE)
	WAVE/Z/T ttlChannels   = GetLastSetting(textualValues, sweepNo, "TTL channels", DATA_ACQUISITION_MODE)

	if(tgs.splitTTLBits && numTTLs > 0)
		if(!WaveExists(ttlRackZeroBits) && !WaveExists(ttlRackOneBits) && hardwareType == HARDWARE_ITC_DAC)
			print "Turning off tgs.splitTTLBits as some labnotebook entries could not be found"
			ControlWindowToFront()
			tgs.splitTTLBits = 0
		elseif(WaveExists(ttlChannels))
			// NI hardware does use one channel per bit so we don't need that here
			tgs.splitTTLBits = 0
		endif

		if(tgs.splitTTLBits)
			idx = GetIndexForHeadstageIndepData(numericalValues)
			if(WaveExists(ttlRackZeroBits))
				numTTLBits += PopCount(ttlRackZeroBits[idx])
			 endif
			if(WaveExists(ttlRackOneBits))
				numTTLBits += PopCount(ttlRackOneBits[idx])
			 endif
		endif
	endif

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
		// 778969b0 (DC_PlaceDataInITCDataWave: Document all other settings from the DAQ groupbox, 2015-11-26)
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

			// Fixup buggy entries introduced since 88323d8d (Replacement of oodDAQ offset calculation routines, 2019-06-13)
			// The regions from the second active headstage are duplicated into the
			// first region in case we had more than two active headstages taking part in oodDAQ.
			WAVE/Z indizes = FindIndizes(oodDAQRegions, col=0, prop=PROP_NON_EMPTY)
			if(WaveExists(indizes) && DimSize(indizes, ROWS) > 2)
				oodDAQRegions[indizes[0]] = ReplaceString(oodDAQRegions[indizes[1]], oodDAQRegions[indizes[0]], "")
			endif

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

	// Added in a2220e9f (Add the clamp mode to the labnotebook for acquired data, 2015-04-26)
	WAVE/Z clampModes = GetLastSetting(numericalValues, sweepNo, "Clamp Mode", DATA_ACQUISITION_MODE)

	if(!WaveExists(clampModes))
		WAVE/Z clampModes = GetLastSetting(numericalValues, sweepNo, "Operating Mode", DATA_ACQUISITION_MODE)
		ASSERT(WaveExists(clampModes), "Labnotebook is too old for display.")
	endif

	WAVE/Z statusDAC = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z statusADC = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)

	// introduced in 18e1406b (Labnotebook: Add DA/AD ChannelType, 2019-02-15)
	WAVE/Z daChannelType = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	WAVE/Z adChannelType = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)

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
					numHorizWaves    = tgs.dDAQDisplayMode ? numRegions : 1
					numVertWaves     = 1
					numChannels      = numADCs
					break
				case ITC_XOP_CHANNEL_TYPE_TTL:
					if(!tgs.displayTTL                                      \
					   || (tgs.displayDAC && numDACs != activeChanCount[0]) \
					   || (tgs.displayADC && numADCs != activeChanCount[1]))
						continue
					endif

					WAVE/Z status    = $""
					WAVE channelList = TTLs
					channelID        = "TTL"
					hasPhysUnit      = 0
					numHorizWaves    = 1

					if(hardwareType == HARDWARE_ITC_DAC)
						numVertWaves = tgs.splitTTLBits ? NUM_ITC_TTL_BITS_PER_RACK : 1
					else
						numVertWaves = 1
					endif

					numChannels = numTTLs
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

			// ignore TP during DAQ channels
			if(WaveExists(status) && IsFinite(headstage))
				if(channelTypes[i] == ITC_XOP_CHANNEL_TYPE_DAC          \
				   && WaveExists(daChannelType)                         \
				   && daChannelType[headstage] != DAQ_CHANNEL_TYPE_DAQ)
						continue
				elseif(channelTypes[i] == ITC_XOP_CHANNEL_TYPE_ADC          \
				       && WaveExists(adChannelType)                         \
				       && adChannelType[headstage] != DAQ_CHANNEL_TYPE_DAQ)
						continue
				endif
			endif

			// number of vertically distributed
			// waves per channel type
			for(j = 0; j < numVertWaves; j += 1)

				if(!cmpstr(channelID, "TTL") && tgs.splitTTLBits)
					ttlBit = j
					name = channelID + num2str(chan) + "_" + num2str(ttlBit)
				else
					ttlBit = NaN
					name = channelID + num2str(chan)
				endif

				DFREF singleSweepDFR = GetSingleSweepFolder(sweepDFR, sweepNo)

				ASSERT(DataFolderExistsDFR(singleSweepDFR), "Missing singleSweepDFR")

				WAVE/Z wv = GetITCDataSingleColumnWave(singleSweepDFR, channelTypes[i], chan, splitTTLBits=tgs.splitTTLBits, ttlBit=j)
				if(!WaveExists(wv))
					continue
				endif

				// Color scheme:
				// 0-7:   Different headstages
				// 8:     Unknown headstage
				// 9:     Averaged trace
				// 10:    TTL bits (sum) rack zero
				// 11-14: TTL bits (single) rack zero
				// 15:    TTL bits (sum) rack one
				// 16-19: TTL bits (single) rack one
				if(IsFinite(headstage))
					colorIndex = headstage
				elseif(!cmpstr(channelID, "TTL"))
					colorIndex = 10 + activeChanCount[i] * 5 + j
				else
					colorIndex = NUM_HEADSTAGES
				endif

				GetTraceColor(colorIndex, red, green, blue)

				sprintf str, "colorIndex=%d", colorIndex
				DEBUGPRINT(str)

				DEBUGPRINT("")
				first = 0

				// number of horizontally distributed
				// waves per channel type
				for(k = 0; k < numHorizWaves; k += 1)

					vertAxis = VERT_AXIS_BASE_NAME + num2str(j) + "_" + HORIZ_AXIS_BASE_NAME + num2str(k) + "_" + channelID

					if(!tgs.overlayChannels)
						vertAxis   += "_" + num2str(chan)
						traceType   = name
						if(!cmpstr(channelID, "TTL"))
							if(tgs.splitTTLBits)
								vertAxis += "_" + num2str(j)
							else
								vertAxis += "_NaN"
							endif
						endif
					else
						traceType   = channelID
					endif

					if(!tgs.overlayChannels)
						vertAxis += "_HS_" + num2str(headstage)
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

					sprintf trace, "T%0*d", TRACE_NAME_NUM_DIGITS, traceIndex
					traceIndex += 1

					sprintf str, "i=%d, j=%d, k=%d, vertAxis=%s, traceType=%s, name=%s", i, j, k, vertAxis, traceType, name
					DEBUGPRINT(str)

					sprintf traceColor, "(%d, %d, %d, %d)", red, green, blue, 65535

					if(!IsFinite(xRangeStart) && !IsFinite(XRangeEnd))
						horizAxis = "bottom"
						traceRange = "[][0]"
						AppendToGraph/W=$graph/B=$horizAxis/L=$vertAxis/C=(red, green, blue, 65535) wv[][0]/TN=$trace
					else
						horizAxis = vertAxis + "_b"
						sprintf traceRange, "[%g,%g][0]", xRangeStart, xRangeEnd
						AppendToGraph/W=$graph/L=$vertAxis/B=$horizAxis/C=(red, green, blue, 65535) wv[xRangeStart, xRangeEnd][0]/TN=$trace
						first = first
						last  = first + (xRangeEnd - xRangeStart) / totalXRange
						ModifyGraph/W=$graph axisEnab($horizAxis)={first, min(last, 1.0)}
						first += (xRangeEnd - xRangeStart) / totalXRange

						sprintf str, "horiz axis: stimset=[%d, %d] aka (%g, %g)", xRangeStart, xRangeEnd, pnt2x(wv,xRangeStart), pnt2x(wv,xRangeEnd)
						DEBUGPRINT(str)
					endif

					if(k == 0) // first column, add labels
						if(hasPhysUnit)
							unit = AFH_GetChannelUnit(config, chan, channelTypes[i])
						else
							unit = "a.u."
						endif

						axisLabel = "\Z08"+ traceType + "\r(" + unit + ")"

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
					else
						Label/W=$graph $vertAxis, "\\u#2"
					endif

					if(tgs.dDAQDisplayMode)
						ModifyGraph/W=$graph freePos($vertAxis)={1 / numHorizWaves * k,kwFraction}, freePos($horizAxis)={0,$vertAxis}
					endif

					if(tgs.hideSweep)
						ModifyGraph/W=$graph hideTrace($trace)=1
					endif

					TUD_SetUserDataFromWaves(graph, trace, userDataKeys,                                                                   \
					                         {GetWavesDataFolder(wv, 2), channelID, num2str(chan), num2str(sweepNo), num2str(headstage),   \
					                          GetWavesDataFolder(textualValues, 2), GetWavesDataFolder(numericalValues, 2),                \
								              num2str(IsFinite(headstage) ? clampModes[headstage] : NaN), num2str(ttlBit), experiment, "Sweep",             \
												  num2str(k), horizAxis, vertAxis, traceRange, traceColor})
				endfor
			endfor

			activeChanCount[i] += 1
		endfor
	while(moreData)
End

/// @brief Return a wave with all keys in the labnotebook key wave
Function/WAVE GetLabNotebookKeys(keyWave)
	WAVE/Z/T keyWave

	variable numCols

	if(!WaveExists(keyWave))
		return $""
	endif

	numCols = DimSize(keyWave, COLS) - INITIAL_KEY_WAVE_COL_COUNT
	if(numCols <= 0)
		return $""
	endif

	Make/FREE/T/N=(numCols) keys
	keys[] = keyWave[%Parameter][INITIAL_KEY_WAVE_COL_COUNT + p]

	return keys
End

/// @brief Return a sorted wave with all keys in the labnotebook key wave
Function/WAVE GetLabNotebookSortedKeys(keyWave)
	WAVE/Z/T keyWave

	if(!WaveExists(keyWave))
		return $""
	endif

	WAVE/Z/T keys = GetLabNotebookKeys(keyWave)
	if(!WaveExists(keys))
		return $""
	endif

	Sort/A keys, keys

	return keys
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
/// @param[in]  keyWave   labnotebook key wave
/// @param[in]  key       key to look for
/// @param[out] parameter name of the result [empty if not found]
/// @param[out] unit      unit of the result [empty if not found]
/// @param[out] col       column of the result into the keyWave [NaN if not found]
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
/// @param axisOffset      [optional, defaults to 0] offset of first axis in parts of total width
/// @param axisOrientation [optional, defaults to all] allows to apply equalization to all axis of one orientation
/// @param sortOrder       [optional, defaults to no sorting (NaN)] apply different sorting
///                        schemes to list of axes, see sortingOrder parameter of `SortList`
/// @param listForBegin    [optional, defaults to an empty list] list of axes to move to the front of the sorted axis list
/// @param listForEnd      [optional, defaults to an empty list] list of axes to move to the end of the sorted axis list
Function EquallySpaceAxis(graph, [axisRegExp, axisOffset, axisOrientation, sortOrder, listForBegin, listForEnd])
	string graph, axisRegExp, listForBegin, listForEnd
	variable axisOffset, axisOrientation, sortOrder

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

	if(ParamIsDefault(axisOffset))
		axisOffset = 0
	else
		ASSERT(axisOffset >=0 && axisOffset <= 1.0, "Invalid axis offset")
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
	axisInc = (1.0 - axisOffset) / numAxes

	if(axisInc < GRAPH_DIV_SPACING)
		spacing = axisInc/5
	else
		spacing = GRAPH_DIV_SPACING
	endif

	for(i = numAxes - 1; i >= 0; i -= 1)
		axis = StringFromList(i, adaptedList)
		axisStart = (i == 0 ? axisOffset : spacing + axisInc * i)
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

	string unit, lbl, axis, trace, text, tagString, tmp
	string traceList = ""
	variable i, j, numEntries, row, col, numRows, sweepCol
	variable red, green, blue, isTimeAxis, isTextData, xPos

	if(GetKeyWaveParameterAndUnit(keys, key, lbl, unit, col))
		return NaN
	endif

	lbl = LineBreakingIntoPar(lbl)

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

		ModifyGraph/W=$graph userData($trace)={key, USERDATA_MODIFYGRAPH_REPLACE, key}

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
				sprintf tmp, "\\K(%d, %d, %d)%d:\\K(0, 0, 0)", red, green, blue, j + 1
				tagString = tagString + tmp + text + "\r"
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
	expName = UniqueFileOrFolder(expLoc, expName, suffix = PACKED_FILE_EXPERIMENT_SUFFIX)

	ret = SaveExperimentWrapper(expLoc, expName, overrideInteractiveMode = showSaveDialog)

	if(ret)
		return NaN
	endif

	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE_TS killFunc = KillOrMoveToTrashPath

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
		activeDevices = GetAllDevices()
		numDevices = ItemsInList(activeDevices)
		for(i = 0; i < numDevices; i += 1)
			device = StringFromList(i, activeDevices)

			DFREF dfr = GetDevicePath(device)
			list = GetListOfObjects(dfr, "ChanAmpAssign_Sweep_*", fullPath=1)
			CallFunctionForEachListItem_TS(killFunc, list)

			DFREF dfr = GetDeviceTestPulse(device)
			list = GetListOfObjects(dfr, "TPStorage_*", fullPath=1)
			CallFunctionForEachListItem_TS(killFunc, list)

			DFREF dfr = GetDevicePath(device)
			list = GetListOfObjects(dfr, "Databrowser*", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath=1)
			CallFunctionForEachListItem_TS(killFunc, list)

			RemoveTracesFromGraph(SCOPE_GetGraph(device))
		endfor
	endif

	SaveExperiment

	if(useNewNWBFile)

		KillWindow/Z HistoryCarbonCopy
		CreateHistoryNotebook()

		CloseNWBFile()

		NVAR sesssionStartTime = $GetSessionStartTime()
		sesssionStartTime = DateTimeInUTC()
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
			case "Headstage":
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

/// @brief Extract an one dimensional wave from the given sweep/hardware data wave and column
///
/// @param config config wave
/// @param sweep  sweep wave or hardware data wave from all hardware types
/// @param index  index into `sweep`, can be queried with #AFH_GetITCDataColumn
///
/// @returns a reference to a free wave with the single channel data
Function/Wave ExtractOneDimDataFromSweep(config, sweep, index)
	WAVE config
	WAVE sweep
	variable index

	ASSERT(IsValidSweepAndConfig(sweep, config, configVersion = 0), "Sweep and config are not compatible")

	if(IsWaveRefWave(sweep))
		ASSERT(index < DimSize(sweep, ROWS), "The index is out of range")
		WAVE/WAVE sweepRef = sweep
		Duplicate/FREE sweepRef[index], data
	else
		ASSERT(index < DimSize(sweep, COLS), "The index is out of range")
		MatrixOP/FREE data = col(sweep, index)
	endif

	SetScale/P x, DimOffset(sweep, ROWS), DimDelta(sweep, ROWS), WaveUnits(sweep, ROWS), data
	WAVE/T units = AFH_GetChannelUnits(config)
	if(index < DimSize(units, ROWS))
		SetScale d, 0, 0, units[index], data
	endif

	Note data, note(sweep)

	return data
End

/// @brief Perform common transformations on the graphs traces
///
/// Keeps track of all internal details wrt. to the order of
/// the operations, backups, etc.
///
/// Needs to be called after adding/removing/updating sweeps via
/// AddSweepToGraph(), RemoveSweepFromGraph(), UpdateSweepInGraph().
///
/// @param win graph with sweep traces
Function PostPlotTransformations(string win)
	STRUCT TiledGraphSettings tgs
	string graph

	graph = GetMainWindow(win)

	WAVE/T/Z traces = GetAllSweepTraces(graph, prefixTraces = 0)

	if(!WaveExists(traces))
		return NaN
	endif

	STRUCT PostPlotSettings pps
	InitPostPlotSettings(graph, pps)

	ZeroTracesIfReq(graph, traces, pps.zeroTraces)
	TimeAlignMainWindow(graph, pps)

	AverageWavesFromSameYAxisIfReq(graph, traces, pps.averageTraces, pps.averageDataFolder, pps.hideSweep)
	AR_HighlightArtefactsEntry(graph)
	PA_Update(graph)
	BSP_ScaleAxes(graph)

	[tgs] = BSP_GatherTiledGraphSettings(graph)
	LayoutGraph(graph, tgs)
End

static Function InitPostPlotSettings(win, pps)
	string win
	STRUCT PostPlotSettings &pps

	string bsPanel = BSP_GetPanel(win)

	pps.averageDataFolder = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	pps.averageTraces     = GetCheckboxState(bsPanel, "check_Calculation_AverageTraces")
	pps.zeroTraces        = GetCheckBoxState(bsPanel, "check_Calculation_ZeroTraces")
	pps.hideSweep         = GetCheckBoxState(bsPanel, "check_SweepControl_HideSweep")

	pps.timeAlignment     = GetCheckBoxState(bsPanel, "check_BrowserSettings_TA")
	pps.timeAlignMode     = GetPopupMenuIndex(bsPanel, "popup_TimeAlignment_Mode")
	pps.timeAlignLevel    = GetSetVariable(bsPanel, "setvar_TimeAlignment_LevelCross")
	pps.timeAlignRefTrace = GetPopupMenuString(bsPanel, "popup_TimeAlignment_Master")
	pps.timeAlignment     = GetCheckBoxState(bsPanel, "check_BrowserSettings_TA")
End

/// @brief Time Alignment for the BrowserSettingsPanel
///
/// This function should work for any given reference trace in
/// pps.timeAlignRefTrace in the popup menu. (DB and SB)
///
/// @param graph graph with sweep traces
/// @param pps   settings
Function TimeAlignMainWindow(graph, pps)
	string graph
	STRUCT PostPlotSettings &pps

	variable csrAx, csrBx

	if(pps.timeAlignment)
		GetCursorXPositionAB(graph, csrAx, csrBx)
		TimeAlignmentIfReq(pps.timeAlignRefTrace, pps.timeAlignMode, pps.timeAlignLevel, csrAx, csrBx, force = 1)
	endif
End

/// @brief return a list of all traces relevant for TimeAlignment
Function/S TimeAlignGetAllTraces(graph)
	string graph

	WAVE/T/Z traces = GetAllSweepTraces(graph)

	if(!WaveExists(traces))
		return ""
	endif

	return TextWaveToList(traces, ";")
End

/// @brief return a list of all graphs included in TimeAlignment
Function/S TimeAlignGetAllGraphs(graph)
	string graph

	string graphs

	graphs = AddListItem(graph, "")
	if(PA_IsActive(graph))
		graphs += PA_GetAverageGraphs(graph)
	endif

	return graphs
End

/// @brief Adds or removes the cursors from the graphs depending on the
///        panel settings
///
/// @param win  main DB/SB graph or any subwindow panel.
Function TimeAlignHandleCursorDisplay(win)
	string win

	string graphtrace, graph, graphs, trace, traceList, bsPanel, csrA, csrB
	variable length, posA, posB

	win     = GetMainWindow(win)
	bsPanel = BSP_GetPanel(win)

	traceList = TimeAlignGetAllTraces(win)
	if(isEmpty(traceList))
		return NaN
	endif

	graphs = TimeAlignGetAllGraphs(win)

	// deactivate cursor
	if(!GetCheckBoxState(bsPanel, "check_BrowserSettings_TA"))
		KillCursorInGraphs(graphs, "A")
		KillCursorInGraphs(graphs, "B")
		return 0
	endif

	// save cursor and kill all available A,B cursors
	graph = FindCursorInGraphs(graphs, "A")
	if(!isempty(graph))
		csrA = CsrInfo(A, graph)
		KillCursorInGraphs(graphs, "A")
		csrB = CsrInfo(B, graph)
		KillCursorInGraphs(graphs, "B")
	endif

	// ensure that trace is really on the graph
	graphtrace = GetPopupMenuString(bsPanel, "popup_TimeAlignment_Master")
	if(FindListItem(graphtrace, traceList) == -1)
		graphtrace = StringFromList(0, traceList)
	endif
	graph = StringFromList(0, graphtrace, "#")
	trace = StringFromList(1, graphtrace, "#")

	// set cursor to trace
	if(isEmpty(csrA) || isEmpty(csrB))
		length = DimSize(TraceNameToWaveRef(graph, trace), ROWS)
		posA = length / 3
		posB = length * 2 / 3
	else
		posA = NumberByKey("POINT", csrA)
		posB = NumberByKey("POINT", csrB)
	endif
	Cursor/W=$graph/A=1/N=1/P A $trace posA
	Cursor/W=$graph/A=1/N=1/P B $trace posB
End

/// @brief Enable/Disable TimeAlignment Controls and Cursors
Function TimeAlignUpdateControls(win)
	string win
	variable alignMode

	string bsPanel, graph

	bsPanel = BSP_GetPanel(win)
	graph = GetMainWindow(win)

	if(GetCheckBoxState(bsPanel, "check_BrowserSettings_TA"))
		EnableControls(bsPanel, "popup_TimeAlignment_Mode;setvar_TimeAlignment_LevelCross;popup_TimeAlignment_Master;button_TimeAlignment_Action")

		alignMode = GetPopupMenuIndex(bsPanel, "popup_TimeAlignment_Mode")
		if(alignMode == TIME_ALIGNMENT_LEVEL_RISING || alignMode == TIME_ALIGNMENT_LEVEL_FALLING)
			EnableControl(bsPanel, "setvar_TimeAlignment_LevelCross")
		else
			DisableControl(bsPanel, "setvar_TimeAlignment_LevelCross")
		endif

		ControlUpdate/W=$bsPanel popup_TimeAlignment_Master
	else
		DisableControls(bsPanel, "popup_TimeAlignment_Mode;setvar_TimeAlignment_LevelCross;popup_TimeAlignment_Master;button_TimeAlignment_Action")
	endif

	TimeAlignHandleCursorDisplay(graph)
End

Function TimeAlignCursorMovedHook(s)
	STRUCT WMWinHookStruct &s

	string trace, graphtrace, graphtraces, xAxis, yAxis, bsPanel, mainPanel
	variable numTraces, i

	strswitch(s.eventName)
		case "cursormoved":
			trace = s.traceName
			if(isEmpty(trace))
				return 0
			endif

			bsPanel = BSP_GetPanel(s.winName)
			if(!windowExists(bsPanel))
				// check if hook was called from a PA graph
				if(WhichListItem(s.winName, PA_GetAverageGraphs(bsPanel)) == -1)
					return 0
				endif
				bsPanel = BSP_GetPanel(GetUserData(s.winName, "", MIES_BSP_PA_MAINPANEL))
				if(!windowExists(bsPanel))
					return 0
				endif
			endif

			if(!GetCheckBoxState(bsPanel, "check_BrowserSettings_TA"))
				return 0
			endif

			mainPanel = GetMainWindow(bsPanel)
			graphtrace = s.winName + "#" + trace
			graphtraces = TimeAlignGetAllTraces(mainPanel)
			if(FindListItem(graphtrace, graphtraces) == -1)
				xAxis = TUD_GetUserData(s.winName, trace, "XAXIS")
				yAxis = TUD_GetUserData(s.winName, trace, "YAXIS")

				WAVE/T traces = TUD_GetUserDataAsWave(s.winName, "tracename", keys = {"XAXIS", "YAXIS"}, \
				                                      values = {xAxis, yAxis})

				numTraces = DimSize(traces, ROWS)
				for(i = 0; i < numTraces; i += 1)
					trace = traces[i]
					graphtrace = s.winName + "#" + trace

					if(FindListItem(graphtrace, graphtraces) != -1)
						break
					endif
				endfor
			endif

			PGC_SetAndActivateControl(bsPanel, "popup_TimeAlignment_Master", str = graphtrace)
			break
	endswitch

	return 0
End

/// @brief Replace all waves from the traces in the graph with their backup
Function ReplaceAllWavesWithBackup(graph, tracePaths)
	string graph
	WAVE/T/Z tracePaths

	variable numTraces, i

	if(!WaveExists(tracePaths))
		return NaN
	endif

	numTraces = DimSize(tracePaths, ROWS)

	for(i = 0; i < numTraces; i += 1)
		WAVE wv = $tracePaths[i]
		ReplaceWaveWithBackup(wv, nonExistingBackupIsFatal=0)
	endfor
End

/// @brief Get a textwave of all traces from a list of graphs
///
/// @param graphs       semicolon separated list of graph names
/// @param region       [optional] return only traces with the specified region
///                     userdata entry
/// @param channelType  [optional] return only the traces with the given channel type
/// @param prefixTraces [optional, defaults to true] prefix the traces names with the graph name and a `#`
///
/// @returns graph#trace named patterns
Function/WAVE GetAllSweepTraces(string graphs, [variable region, variable channelType, variable prefixTraces])
	string graph
	variable i, idx, numGraphs

	if(ParamIsDefault(prefixTraces))
		prefixTraces = 1
	else
		prefixTraces = !!prefixTraces
	endif

	numGraphs = ItemsInList(graphs)

	Make/FREE/N=(numGraphs)/WAVE resultWave

	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)
		if(ParamIsDefault(region) && ParamIsDefault(channelType))
			WAVE/Z/T traces = GetSweepUserData(graph, "traceName")
		elseif(!ParamIsDefault(region))
			WAVE/Z/T traces = GetSweepUserData(graph, "traceName", region = region)
		elseif(!ParamIsDefault(channelType))
			WAVE/Z/T traces = GetSweepUserData(graph, "traceName", channelType = channelType)
		elseif(!ParamIsDefault(region) && !ParamIsDefault(channelType))
			WAVE/Z/T traces = GetSweepUserData(graph, "traceName", channelType = channelType, region = region)
		endif

		if(!WaveExists(traces))
			continue
		endif

		if(prefixTraces)
			traces[] = graph + "#" + traces[p]
		endif

		resultWave[idx++] = traces
	endfor

	if(idx == 0)
		return $""
	elseif(idx == 1)
		return resultWave[0]
	endif

	Redimension/N=(idx) resultWave

	Concatenate/FREE/NP {resultWave}, graphTraces

	return graphTraces
End

// @brief Return a 1D text wave with the given property of all sweep waves without duplicates
Function/WAVE GetSweepUserData(string graph, string key, [variable channelType, variable region])

	if(ParamIsDefault(channelType) && ParamIsDefault(region))
		return TUD_GetUserDataAsWave(graph, key, keys = {"traceType", "occurence"}, values = {"sweep", "0"})
	elseif(!ParamIsDefault(channelType))
		return TUD_GetUserDataAsWave(graph, key, keys = {"traceType", "occurence", "channelType"},            \
		                             values = {"sweep", "0", StringFromList(channelType, ITC_CHANNEL_NAMES)})
	elseif(!ParamIsDefault(region))
		return TUD_GetUserDataAsWave(graph, key, keys = {"traceType", "occurence", "region"}, \
		                             values = {"sweep", "0", num2str(region)})
	endif
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
	string range, listOfRanges, firstXAxis, listOfClampModes, xAxis, yAxis
	variable i, j, k, l, numAxes, numTraces, numWaves, ret
	variable red, green, blue, column, first, last, orientation
	string axis, trace, axList, baseName, clampMode, traceName, headstage
	string channelType, channelNumber, fullPath, panel

	referenceTime = DEBUG_TIMER_START()

	if(!averagingEnabled)
		listOfWaves = GetListOfObjects(averageDataFolder, "average.*", fullPath=1)
		CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, listOfWaves)
		RemoveEmptyDataFolder(averageDataFolder)
		return NaN
	endif

	axList = AxisList(graph)
	numAxes = ItemsInList(axList)
	numTraces = DimSize(traces, ROWS)

	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)
		listOfWaves          = ""
		listOfChannelTypes   = ""
		listOfChannelNumbers = ""
		listOfRanges         = ""
		listOfClampModes     = ""
		listOfHeadstages     = ""
		firstXAxis           = ""

		orientation = GetAxisOrientation(graph, axis)
		if(orientation == AXIS_ORIENTATION_BOTTOM || orientation == AXIS_ORIENTATION_TOP)
			continue
		endif

		for(j = 0; j < numTraces; j += 1)
			trace = traces[j]
			yAxis = TUD_GetUserData(graph, trace, "YAXIS")

			if(cmpstr(axis, yaxis))
				continue
			endif

			fullPath      = TUD_GetUserData(graph, trace, "fullPath")
			channelType   = TUD_GetUserData(graph, trace, "channelType")
			channelNumber = TUD_GetUserData(graph, trace, "channelNumber")
			clampMode     = TUD_GetUserData(graph, trace, "clampMode")
			headstage     = TUD_GetUserData(graph, trace, "headstage")
			range         = TUD_GetUserData(graph, trace, "YRANGE")

			listOfWaves          = AddListItem(fullPath, listOfWaves, ";", Inf)
			listOfChannelTypes   = AddListItem(channelType, listOfChannelTypes, ";", Inf)
			listOfChannelNumbers = AddListItem(channelNumber, listOfChannelNumbers, ";", Inf)
			listOfRanges         = AddListItem(range, listOfRanges, "_", Inf)
			listOfClampModes     = AddListItem(clampMode, listOfClampModes, ";", Inf)
			listOfHeadstages     = AddListItem(headstage, listOfHeadstages, ";", Inf)

			if(IsEmpty(firstXAxis))
				firstXAxis = TUD_GetUserData(graph, trace, "XAXIS")
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

		sprintf traceName, "T%0*d%s", TRACE_NAME_NUM_DIGITS, (numTraces + traceIndex), averageWaveName
		traceIndex += 1

		WAVE ranges = ExtractFromSubrange(listOfRanges, ROWS)

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

		if(WaveListHasSameWaveNames(listOfHeadstages, headstage)&& hideSweep)
			GetTraceColor(str2num(headstage), red, green, blue)
		else
			GetTraceColor(NUM_HEADSTAGES + 1, red, green, blue)
		endif

		if(IsFinite(first) && IsFinite(last))
			// and now convert it back to points in the average wave
			first = ScaleToIndex(averageWave, first, ROWS)
			last  = ScaleToIndex(averageWave, last, ROWS)

			AppendToGraph/Q/W=$graph/L=$axis/B=$firstXAxis/C=(red, green, blue, 0.80 * 65535) averageWave[first, last]/TN=$traceName
		else
			AppendToGraph/Q/W=$graph/L=$axis/B=$firstXAxis/C=(red, green, blue, 0.80 * 65535) averageWave/TN=$traceName
		endif

		if(ListHasOnlyOneUniqueEntry(listOfClampModes))
			TUD_SetUserData(graph, traceName, "clampMode", StringFromList(0, listOfClampModes))
			TUD_SetUserData(graph, traceName, "fullPath", GetWavesDataFolder(averageWave, 2))
			TUD_SetUserData(graph, traceName, "traceType", "Average")
			TUD_SetUserData(graph, traceName, "XAXIS", firstXAxis)
			TUD_SetUserData(graph, traceName, "YAXIS", axis)
		endif
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
/// @param skipCRC           [optional, defaults to false] Add the average wave CRC as suffix to its name
///
/// @return wave reference to the average wave
Function/WAVE CalculateAverage(listOfWaves, averageDataFolder, averageWaveName, [skipCRC])
	string listOfWaves
	DFREF averageDataFolder
	string averageWaveName
	variable skipCRC

	variable ret, crc
	string key, wvName, dataUnit

	skipCRC = ParamIsDefault(skipCRC) ? 0 : !!skipCRC

	WAVE waveRefs = ListToWaveRefWave(listOfWaves, 1)
	key = CA_AveragingKey(waveRefs)

	WAVE/Z freeAverageWave = CA_TryFetchingEntryFromCache(key)
	if(WaveExists(freeAverageWave)) // found in the cache
		wvName = averageWaveName
		if(!skipCRC)
			wvName += "_" + num2istr(GetNumberFromWaveNote(freeAverageWave, "DataCRC"))
		endif

		WAVE/Z/SDFR=averageDataFolder permAverageWave = $wvName
		if(!WaveExists(permAverageWave))
			MoveWave freeAverageWave, averageDataFolder:$wvName
		else
			Duplicate/O freeAverageWave averageDataFolder:$wvName
		endif

		WAVE/SDFR=averageDataFolder permAverageWave = $wvName
		return permAverageWave
	endif

	ret = MIES_fWaveAverage(listOfWaves, "", 0, 0, GetDataFolder(1, averageDataFolder) + averageWaveName, "")
	ASSERT(ClearRTError() == 0, "Unexpected RTE")
	ASSERT(ret != -1, "Wave averaging failed")

	WAVE/SDFR=averageDataFolder averageWave = $averageWaveName

	dataUnit = WaveUnits($StringFromList(0, listOfWaves), -1)
	SetScale d, 0, 0, dataUnit, averageWave

	wvName = averageWaveName

	if(!skipCRC)
		crc = WaveCRC(0, averageWave)
		wvName += "_" + num2istr(crc)

		WAVE/Z/SDFR=averageDataFolder averageWaveToDelete = $wvName
		KillOrMoveToTrash(wv=averageWaveToDelete)
		MoveWave averageWave, averageDataFolder:$wvName
		SetNumberInWaveNote(averageWave, "DataCRC", crc)
	endif

	AddEntryIntoWaveNoteAsList(averageWave, "SourceWavesForAverage", str=ReplaceString(";", listOfWaves, "|"))
	SetNumberInWaveNote(averageWave, "WaveMaximum", WaveMax(averageWave), format = "%.15f")
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
		WAVE wv = $TUD_GetUserData(graph, trace, "fullPath")
		CreateBackupWave(wv)
		ZeroWave(wv)
	endfor
End

/// @brief Perform time alignment of features in the sweep traces
///
/// PA time alignment:
/// - Get the feature position of the reference trace and store it in `refPos`
/// - Get them also for all pulses which belong to the same set. Store these
///   feature positions using their sweep number and pulse index as key.
/// - Now shift *all* pulses in all sets from the same region by `- (refPos +
///   featurePos)` where `featurePos` is used from the same sweep and pulse index.
///
/// @param graphtrace reference trace in the form of graph#trace
/// @param mode       time alignment mode
/// @param level      level input to the @c FindLevel operation in @see CalculateFeatureLoc
/// @param pos1x      specify start range for feature position
/// @param pos2x      specify end range for feature position
/// @param force      [optional, defaults to false] redo time aligment regardless of wave note
Function TimeAlignmentIfReq(graphtrace, mode, level, pos1x, pos2x, [force])
	string graphtrace
	variable mode, level, pos1x, pos2x, force

	if(ParamIsDefault(force))
		force = 0
	else
		force = !!force
	endif

	string str, refAxis, axis
	string trace, refTrace, graph, refGraph, paGraphs, refRegion, browserGraph
	variable offset, refPos
	variable first, last, pos, numTraces, i, idx
	string sweepNo, pulseIndexStr, indexStr

	if(mode == TIME_ALIGNMENT_NONE) // nothing to do
		return NaN
	endif

	refGraph = StringFromList(0, graphtrace, "#")
	refTrace = StringFromList(1, graphtrace, "#")
	ASSERT(windowExists(refGraph), "Graph must exist")

	[first, last] = MinMax(pos1x, pos2x)

	sprintf str, "first=%g, last=%g", first, last
	DEBUGPRINT(str)

	// now determine the feature's time position
	// using the traces from the same axis as the reference trace
	refAxis = TUD_GetUserData(refGraph, refTrace, "YAXIS")

	browserGraph = GetUserData(refGraph, "", MIES_BSP_PA_MAINPANEL)
	paGraphs = PA_GetAverageGraphs(browserGraph)
	if(WhichListItem(refGraph, paGraphs) == -1)
		WAVE/T graphtraces = GetAllSweepTraces(refGraph)
	else
		// only do PA for sweeps with same region
		refRegion = TUD_GetUserData(refGraph, refTrace, "region")
		ASSERT(!isEmpty(refRegion), "region is empty. Set \"region\" in userData entry for trace.")
		WAVE/T graphtraces = GetAllSweepTraces(paGraphs, region = str2num(refRegion))
	endif

	refPos = NaN

	numTraces = DimSize(graphtraces, ROWS)
	MAKE/FREE/D/N=(numTraces) featurePos = NaN, sweepNumber = NaN
	MAKE/FREE/T/N=(numTraces) refIndex
	for(i = 0; i < numTraces; i += 1)
		graph = StringFromList(0, graphtraces[i], "#")
		trace = StringFromList(1, graphtraces[i], "#")
		axis = TUD_GetUserData(graph, trace, "YAXIS")

		if(cmpstr(axis, refAxis) || cmpstr(graph, refGraph))
			continue
		endif

		WAVE wv = $TUD_GetUserData(graph, trace, "fullPath")

		pos = CalculateFeatureLoc(wv, mode, level, first, last)

		if(!IsFinite(pos))
			printf "The alignment of trace %s could not be performed, aborting\r", trace
			return NaN
		endif

		if(!cmpstr(refTrace, trace))
			refPos = pos
		endif

		featurePos[i]  = pos
		sweepNo = TUD_GetUserData(graph, trace, "sweepNumber")
		ASSERT(!isEmpty(sweepNo), "Sweep number is empty. Set \"sweepNumber\" userData entry for trace.")
		sweepNumber[i] = str2num(sweepNo)
		pulseIndexStr = TUD_GetUserData(graph, trace, "pulseIndex")
		refIndex[i] = sweepNo + ":" + pulseIndexStr
	endfor

	// now shift all traces from all sweeps according to their relative offsets
	// to the reference position
	for(i = 0; i < numTraces; i += 1)
		graph = StringFromList(0, graphtraces[i], "#")
		trace = StringFromList(1, graphtraces[i], "#")
		WAVE/Z wv = $TUD_GetUserData(graph, trace, "fullPath")
		ASSERT(WaveExists(wv), "Could not resolve trace to wave")

		if(GetNumberFromWaveNote(wv, NOTE_KEY_TIMEALIGN) == 1 && force == 0)
			continue
		endif

		sweepNo = TUD_GetUserData(graph, trace, "sweepNumber")
		pulseIndexStr = TUD_GetUserData(graph, trace, "pulseIndex")
		indexStr = sweepNo + ":" + pulseIndexStr
		idx = GetRowIndex(refIndex, str = indexStr)

		if(IsNaN(idx))
			continue
		endif

		WAVE backup = CreateBackupWave(wv)
		offset = - (refPos + featurePos[idx])
		DEBUGPRINT("trace", str=trace)
		DEBUGPRINT("old DimOffset", var=DimOffset(wv, ROWS))
		DEBUGPRINT("new DimOffset", var=DimOffset(wv, ROWS) + offset)
		SetScale/P x, DimOffset(wv, ROWS) + offset, DimDelta(wv, ROWS), wv
		SetNumberInWaveNote(wv, "TimeAlignmentTotalOffset", offset)
		SetNumberInWaveNote(wv, NOTE_KEY_TIMEALIGN, 1)
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

	string axList, axis, trace
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

	WAVE/T/Z traces = TUD_GetUserDataAsWave(graph, "traceName")

	if(!WaveExists(traces))
		return NaN
	endif

	numTraces = DimSize(traces, ROWS)
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
			trace = traces[j]
			if(cmpstr(axis, TUD_GetUserData(graph, trace, "YAXIS")))
				continue
			endif

			WAVE wv = $TUD_GetUserData(graph, trace, "fullPath")

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

			clampMode = str2num(TUD_GetUserData(graph, trace, "clampMode"))

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

	SVAR list = $GetDevicePanelTitleList()
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
/// @param channel         TTL hardware channel
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
/// Before dfe2d862 (Make the function AB_SplitTTLWaveIntoComponents available for all, 2015-10-07)
/// we stored headstage independent data in either all entries or only the first one.
/// Since that commit we store the data in `INDEP_HEADSTAGE`.
Function GetIndexForHeadstageIndepData(values)
	WAVE values

	return DimSize(values, LAYERS) == NUM_HEADSTAGES ? 0 : INDEP_HEADSTAGE
End

/// @brief Return a list of TTL stimsets which are indexed by DAEphys TTL channels
///
/// The indexing here is **hardware independent**.
/// For ITC hardware the assertion "log(ttlBit)/log(2) == DAEphys TTL channel" holds.
///
/// @param numericalValues Numerical labnotebook values
/// @param textualValues   Text labnotebook values
/// @param sweep           Sweep number
Function/WAVE GetTTLStimSets(numericalValues, textualValues, sweep)
	WAVE numericalValues, textualValues
	variable sweep

	variable index

	index = GetIndexForHeadstageIndepData(numericalValues)

	WAVE/T/Z ttlStimsets = GetLastSetting(textualValues, sweep, "TTL stim sets", DATA_ACQUISITION_MODE)
	WAVE/T/Z ttlStimsetsRackZero = GetLastSetting(textualValues, sweep, "TTL rack zero stim sets", DATA_ACQUISITION_MODE)
	WAVE/T/Z ttlStimsetsRackOne = GetLastSetting(textualValues, sweep, "TTL rack one stim sets", DATA_ACQUISITION_MODE)

	if(WaveExists(ttlStimsets))
		// NI hardware
		WAVE/T ttlStimsets = GetLastSetting(textualValues, sweep, "TTL stim sets", DATA_ACQUISITION_MODE)
		return ListToTextWave(ttlStimsets[index], ";")
	elseif(WaveExists(ttlStimsetsRackZero) || WaveExists(ttlStimsetsRackOne))
		// ITC hardware
		Make/FREE/T/N=(NUM_DA_TTL_CHANNELS) entries
		if(WaveExists(ttlStimsetsRackZero))
			entries += StringFromList(p, ttlStimsetsRackZero[index])
		endif

		if(WaveExists(ttlStimsetsRackOne))
			entries += StringFromList(p, ttlStimsetsRackOne[index])
		endif

		return entries
	endif

	// no TTL entries
	return $""
End

/// @brief Return a sorted list of all DA/TTL stim set waves
///
/// @param channelType              #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
/// @param searchString             search string in wildcard syntax
/// @param WBstimSetList            [optional] returns the list of stim sets built with the wavebuilder
/// @param thirdPartyStimSetList    [optional] returns the list of third party stim sets not built with the wavebuilder
Function/S ReturnListOfAllStimSets(channelType, searchString, [WBstimSetList, thirdPartyStimSetList])
	variable channelType
	string searchString
	string &WBstimSetList
	string &thirdPartyStimSetList

	string list, listInternal, listThirdParty

	// fetch stim sets created with the WaveBuilder
	DFREF dfr = GetSetParamFolder(channelType)

	list = GetListOfObjects(dfr, "WP_" + searchString, exprType = MATCH_WILDCARD)
	listInternal = RemovePrefixFromListItem("WP_", list)

	// fetch third party stim sets
	DFREF dfr = GetSetFolder(channelType)

	list = GetListOfObjects(dfr, searchString, exprType = MATCH_WILDCARD)
	listThirdParty = GetListDifference(list,listInternal)

	if(!ParamIsDefault(WBstimSetList))
		WBstimSetList = SortList(listInternal,";",16)
	endif

	if(!ParamIsDefault(thirdPartyStimSetList))
		thirdPartyStimSetList = SortList(listThirdParty,";",16)
	endif

	list = SortList(listInternal + listThirdParty, ";", 16)

	if(channelType == CHANNEL_TYPE_DAC)
		list = AddListItem(STIMSET_TP_WHILE_DAQ, list, ";", 0)
	endif

	return list
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

	string eventName

	eventName = StringFromList(eventType, EVENT_NAME_LIST)
	ASSERT(!IsEmpty(eventName), "Unknown event type")

	return WB_GetWaveNoteEntry(note(stimset), STIMSET_ENTRY, key = eventName)
End

/// @brief Return the analysis function parameters as comma (`,`) separated list
///
/// @sa GetWaveBuilderWaveTextParam() for the exact format.
Function/S ExtractAnalysisFunctionParams(stimSet)
	WAVE stimSet

	return WB_GetWaveNoteEntry(note(stimset), STIMSET_ENTRY, key = ANALYSIS_FUNCTION_PARAMS_STIMSET)
End

/// @brief Split TTL data into a single wave for each bit
///
/// This function is only for data from ITC hardware.
///
/// @param data       1D channel data extracted by #ExtractOneDimDataFromSweep
/// @param ttlBits    bit mask of the active TTL channels form e.g. #GetTTLBits
/// @param targetDFR  datafolder where to put the waves, can be a free datafolder
/// @param wavePrefix prefix of the created wave names
/// @param rescale    One of @ref TTLRescalingOptions. Rescales the data to be in the range [0, 1]
///                   when on, does no rescaling when off.
///
/// The created waves will be named `TTL_3_3` so the final suffix is the running TTL Bit.
Function SplitTTLWaveIntoComponents(data, ttlBits, targetDFR, wavePrefix, rescale)
	WAVE data
	variable ttlBits
	DFREF targetDFR
	string wavePrefix
	variable rescale

	variable i, bit

	if(!IsFinite(ttlBits))
		return NaN
	endif

	for(i = 0; i < NUM_ITC_TTL_BITS_PER_RACK; i += 1)

		bit = 2^i
		if(!(ttlBits & bit))
			continue
		endif

		Duplicate data, targetDFR:$(wavePrefix + num2str(i))/Wave=dest
		if(rescale == TTL_RESCALE_ON)
			MultiThread dest[] = (dest[p] & bit) / bit
		elseif(rescale == TTL_RESCALE_OFF)
			MultiThread dest[] = dest[p] & bit
		else
			ASSERT(0, "Invalid rescale parameter")
		endif
	endfor
End

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
			WAVE deviceIDList = GetDQMActiveDeviceList()
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

	string contents, loadedFilePath

	if(ParamIsDefault(method))
		method = 1
	endif

	ASSERT(FileExists(path), "Expected a file")

	[contents, loadedFilePath] = LoadTextFile(path)

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

/// @brief Remove all free axis from the given graph
Function RemoveFreeAxisFromGraph(graph)
	string graph

	string list, name, info
	variable i, numEntries

	list = AxisList(graph)
	numEntries = ItemsInList(list)

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		info = AxisInfo(graph, name)

		if(!NumberByKey("ISTFREE", info))
			continue
		endif

		KillFreeAxis/W=$graph $name
	endfor
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
Function RemoveTracesFromGraph(graph, [kill, trace, wv, dfr])
	string graph
	variable kill
	string trace
	WAVE/Z wv
	DFREF dfr

	variable i, numEntries, tryKillingTheWave, numOptArgs, remove_all_traces, debugOnError
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

	remove_all_traces = ParamIsDefault(trace) && ParamIsDefault(wv) && ParamIsDefault(dfr)

	// remove without calling TraceNameList or TraceNameToWaveRef
	if(!kill && remove_all_traces)
#if IgorVersion() >= 9.0
		RemoveFromGraph/ALL/W=$graph
		return NaN
#else
		debugOnError = DisableDebugOnError()
		do
			try
				ClearRTError()
				RemoveFromGraph/W=$graph $("#0"); AbortOnRTE
			catch
				ClearRTError()
				ResetDebugOnError(debugOnError)
				return NaN
			endtry
		while(1)
#endif
	endif

	traceList  = TraceNameList(graph, ";", 1 )
	numEntries = ItemsInList(traceList)

	// iterating backwards is required, see http://www.igorexchange.com/node/1677#comment-2315
	for(i = numEntries - 1; i >= 0; i -= 1)
		refTrace = StringFromList(i, traceList)

		Wave/Z refWave = TraceNameToWaveRef(graph, refTrace)

		if(remove_all_traces)
			RemoveFromGraph/W=$graph $refTrace
			tryKillingTheWave = 1
		elseif(!ParamIsDefault(trace))
			if(!cmpstr(refTrace, trace))
				RemoveFromGraph/W=$graph $refTrace
				tryKillingTheWave = 1
			endif
		elseif(!ParamIsDefault(wv))
			if(WaveRefsEqual(refWave, wv))
				RemoveFromGraph/W=$graph $refTrace
				tryKillingTheWave = 1
			endif
		elseif(!ParamIsDefault(dfr))
			if(GetRowIndex(candidates, refWave=refWave) >= 0)
				RemoveFromGraph/W=$graph $refTrace
				tryKillingTheWave = 1
			endif
		endif

		if(kill && tryKillingTheWave)
			KillOrMoveToTrash(wv=refWave)
		endif

		tryKillingTheWave = 0
	endfor

	return NaN
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

	ASSERT(IsGlobalWave(wv), "Wave Can Not Be A Null Wave Or A Free Wave")
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

	ASSERT(IsGlobalWave(wv), "Wave Can Not Be A Null Wave Or A Free Wave")

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
/// @param keepBackup               [optional, defaults to false] don't delete the backup after restoring from it
/// @returns wave reference to the restored data, in case of no backup an invalid wave reference
Function/Wave ReplaceWaveWithBackup(wv, [nonExistingBackupIsFatal, keepBackup])
	Wave wv
	variable nonExistingBackupIsFatal, keepBackup

	if(ParamIsDefault(nonExistingBackupIsFatal))
		nonExistingBackupIsFatal = 1
	endif

	if(ParamIsDefault(keepBackup))
		keepBackup = 0
	else
		keepBackup = !!keepBackup
	endif

	WAVE/Z backup = GetBackupWave(wv)

	if(!WaveExists(backup))
		if(nonExistingBackupIsFatal)
			DoAbortNow("Backup wave does not exist")
		endif

		return $""
	endif

	Duplicate/O backup, wv

	if(!keepBackup)
		KillOrMoveToTrash(wv=backup)
	endif

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

/// @brief Check that the device is of type ITC1600
Function IsITC1600(panelTitle)
	string panelTitle

	string deviceType, deviceNumber
	variable ret

	ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
	ASSERT(ret, "Could not parse panelTitle")

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
///
/// We support two types of unassociated keys. Old style, prior to 403c8ec2
/// (Merge pull request #370 from AllenInstitute/feature/sweepformula_enable,
/// 2019-11-13) but after its introduction in ad8dc8ec (Allow AD/DA channels
/// not associated with a headstage again, 2015-10-22) are written as "$Name UNASSOC_$ChannelNumber".
///
/// New style have the format "$Name u_(AD|DA)$ChannelNumber", these include
/// the channel type to make them more self explaining.
Function/S CreateLBNUnassocKey(setting, channelNumber, channelType)
	string setting
	variable channelNumber, channelType

	ASSERT(!IsEmpty(setting), "Expected non empty string")
	ASSERT(IsFinite(channelNumber), "Expected finite channel number")

	string key

	if(IsNaN(channelType))
		sprintf key, "%s UNASSOC_%d", setting, channelNumber
	else
		ASSERT(channelType == ITC_XOP_CHANNEL_TYPE_DAC || channelType == ITC_XOP_CHANNEL_TYPE_ADC, "Invalid channel type")
		ASSERT(IsInteger(channelNumber) && channelNumber >= 0 && channelNumber < GetNumberFromType(itcVar = channelType), "channelNumber is out of range")
		sprintf key, "%s u_%s%d", setting, StringFromList(channelType, ITC_CHANNEL_NAMES), channelNumber
	endif

	return key
End

/// @brief Start the ZeroMQ message handler
///
/// Debug note: Tracking the connection state can be done via
/// `netstat | grep $port`. The binded port only shows up *after* a
/// successfull connection with zeromq_client_connect() is established.
Function StartZeroMQMessageHandler()

	variable i, port, err

#if exists("zeromq_stop")

	// do nothing if we are already running
	zeromq_handler_start(); err = GetRTError(1)
	if(ConvertXOPErrorCode(err) == ZeroMQ_HANDLER_ALREADY_RUNNING)
		DEBUGPRINT("Already running, nothing to do.")
		return NaN
	endif

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
/// @param rescale         One of @ref TTLRescalingOptions
Function SplitSweepIntoComponents(numericalValues, sweep, sweepWave, configWave, rescale, [targetDFR])
	WAVE numericalValues, sweepWave, configWave
	variable sweep, rescale
	DFREF targetDFR

	variable numRows, i, channelNumber, ttlBits
	string channelType, str

	if(ParamIsDefault(targetDFR))
		DFREF targetDFR = GetWavesDataFolderDFR(sweepWave)
	endif

	ASSERT(DataFolderExistsDFR(targetDFR), "targetDFR must exist")
	ASSERT(IsFinite(sweep), "Sweep number must be finite")
	ASSERT(IsValidSweepAndConfig(sweepWave, configWave, configVersion = 0), "Sweep and config waves are not compatible")

	numRows = DimSize(configWave, ROWS)
	for(i = 0; i < numRows; i += 1)
		channelType = StringFromList(configWave[i][0], ITC_CHANNEL_NAMES)
		ASSERT(!isEmpty(channelType), "empty channel type")
		channelNumber = configWave[i][1]
		ASSERT(IsFinite(channelNumber), "non-finite channel number")
		str = channelType + "_" + num2istr(channelNumber)

		WAVE data = ExtractOneDimDataFromSweep(configWave, sweepWave, i)

		if(!cmpstr(channelType, "TTL"))
			ttlBits = GetTTLBits(numericalValues, sweep, channelNumber)

			if(IsFinite(ttlBits))
				SplitTTLWaveIntoComponents(data, ttlBits, targetDFR, str + "_", rescale)
			endif
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

	version = GetPanelVersion(GetMainWindow(win))

	return version == expectedVersion
End

/// @brief Get the user data "panelVersion"
///
/// @param win panel window as string
/// @returns numeric panel version greater 0 and -1 if no version is present
///          or -2 if the windows does not exist
Function GetPanelVersion(win)
	string win

	variable version

	if(!WindowExists(win))
		return -2
	endif

	version = str2numSafe(GetUserData(win, "", "panelVersion"))
	version = abs(version)

	if(IsNaN(version))
		return -1
	endif

	return version
End

Function UpdateSweepPlot(win)
	string win

	if(BSP_IsDataBrowser(win))
		DB_UpdateSweepPlot(win)
	else
		SB_UpdateSweepPlot(win)
	endif
End

/// @brief update of panel elements and related displayed graphs in BSP
Function UpdateSettingsPanel(win)
	string win

	string bsPanel

	bsPanel = BSP_GetPanel(win)

	TimeAlignUpdateControls(bsPanel)
	BSP_ScaleAxes(bsPanel)
End

Function/WAVE GetPlainSweepList(win)
	string win

	if(BSP_IsDataBrowser(win))
		return DB_GetPlainSweepList(win)
	else
		return SB_GetPlainSweepList(win)
	endif
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
/// \rst
/// See :ref:`CalculateTPLikePropsFromSweep_doc` for the full documentation.
/// \endrst
Function CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)
	WAVE numericalValues, textualValues, sweep, deltaI, deltaV, resistance

	variable i
	variable DAcol, ADcol, level, low, high, baseline, elevated, firstEdge, secondEdge, sweepNo
	variable totalOnsetDelay, first, last, onsetDelayPoint
	string msg

	sweepNo     = ExtractSweepNumber(NameofWave(sweep))
	WAVE config = GetConfigWave(sweep)

	totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)

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

		onsetDelayPoint = (totalOnsetDelay - DimOffset(DA, ROWS)) / DimDelta(DA, ROWS)

		first = totalOnsetDelay
		last  = IndexToScale(DA, DimSize(DA, ROWS) - 1, ROWS)

		low  = WaveMin(DA, first, last)
		high = WaveMax(DA, first, last)

		level = low + 0.1 * (high - low)

		Make/FREE/D levels
		FindLevels/Q/P/DEST=levels/R=(first, last)/N=2 DA, level
		ASSERT(V_LevelsFound >= 2, "Could not find enough levels")

		firstEdge   = trunc(levels[0])
		secondEdge  = trunc(levels[1])

		high = firstEdge - 1
		low  = high - (firstEdge - onsetDelayPoint) * 0.1

		baseline = mean(AD, IndexToScale(AD, low, ROWS), IndexToScale(AD, high, ROWS))

		sprintf msg, "(%d) AD: low = %g (%g ms), high = %g (%g ms), baseline %g", i, low, IndexToScale(AD, low, ROWS), high, IndexToScale(AD, high, ROWS), baseline
		DEBUGPRINT(msg)

		high = secondEdge - 1
		low  = high - (secondEdge - firstEdge) * 0.1

		elevated = mean(AD, IndexToScale(AD, low, ROWS), IndexToScale(AD, high, ROWS))

		sprintf msg, "(%d) AD: low = %g (%g ms), high = %g (%g ms), elevated %g", i, low, IndexToScale(AD, low, ROWS),  high, IndexToScale(AD, high, ROWS), elevated
		DEBUGPRINT(msg)

		// convert from mv to V
		ASSERT(!cmpstr(ADunit[i], "mV"), "Unexpected AD Unit")

		deltaV[i] = (elevated - baseline) * 1e-3

		high = firstEdge - 1
		low  = high - (firstEdge - onsetDelayPoint) * 0.1

		baseline = mean(DA, IndexToScale(DA, low, ROWS), IndexToScale(DA, high, ROWS))

		sprintf msg, "(%d) DA: low = %g (%g ms), high = %g (%g ms), baseline %g", i, low, IndexToScale(DA, low, ROWS), high, IndexToScale(DA, high, ROWS), elevated
		DEBUGPRINT(msg)

		high = secondEdge - 1
		low  = high - (secondEdge - firstEdge) * 0.1

		elevated = mean(DA, IndexToScale(DA, low, ROWS), IndexToScale(DA, high, ROWS))

		sprintf msg, "(%d) DA: low = %g (%g ms), high = %g (%g ms), elevated %g", i, low, IndexToScale(DA, low, ROWS), high, IndexToScale(DA, high, ROWS), elevated
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
/// @param recursive [optional, defaults to false] Overwrite referenced waves
///                                                in dest with the ones from src
///                                                (wave reference waves only with matching sizes)
Function MoveWaveWithOverwrite(dest, src, [recursive])
	WAVE dest, src
	variable recursive

	string path
	variable numEntries

	recursive = ParamIsDefault(recursive) ? 0 : !!recursive

	ASSERT(!WaveRefsEqual(dest, src), "dest and src must be distinct waves")
	ASSERT(!IsFreeWave(dest), "dest must be a global/permanent wave")

	if(IsWaveRefWave(dest) && IsWaveRefWave(src) && recursive)
		numEntries = numpnts(dest)
		ASSERT(numEntries == numpnts(src), "Unmatched sizes")
		Make/N=(numEntries)/FREE entries

		WAVE/WAVE destWaveRef = dest
		WAVE/WAVE srcWaveRef = src

		entries[] = MoveWaveWithOverWrite(destWaveRef[p], srcWaveRef[p], recursive = 1)
	endif

	path = GetWavesDataFolder(dest, 2)

	KillOrMoveToTrash(wv=dest)
	MoveWave src, $path
End

/// @brief Check if the given wave is a valid ITCConfigWave
///
/// The optional version parameter allows to check if the wave is at least comaptible with this version.
/// The function assumes that higher versions are compatible with lower versions which is for most callers true.
/// For a special case see AFH_GetChannelUnits.
///
/// @param config wave reference to a ITCConfigWave
///
/// @param version [optional, default=ITC_CONFIG_WAVE_VERSION], check against a specific version
///                current versions known are 0 (equals NaN), 1, 2
threadsafe Function IsValidConfigWave(config, [version])
	WAVE/Z config
	variable version

	variable waveVersion

	if(!WaveExists(config))
		return 0
	endif

	if(ParamIsDefault(version))
		version = ITC_CONFIG_WAVE_VERSION
	endif

	waveVersion = GetWaveVersion(config)

	// we know version NaN, 1 and 2, see GetITCChanConfigWave()
	if(version == 2 && waveVersion >= 2)
		return DimSize(config, ROWS) > 0 && DimSize(config, COLS) >= 6
	elseif(version == 1 && waveVersion >= 1)
		return DimSize(config, ROWS) > 0 && DimSize(config, COLS) >= 5
	elseif(version == 0 && (isNaN(waveVersion) || waveVersion >= 1))
		return DimSize(config, ROWS) > 0 && DimSize(config, COLS) >= 4
	endif

	return 0
End

/// @brief Check if the given wave is a valid HardwareDataWave
threadsafe Function IsValidSweepWave(sweep)
	WAVE/Z sweep

	if(IsWaveRefWave(sweep))
		if(WaveExists(sweep) && DimSize(sweep, ROWS) > 0)
			WAVE/Z/WAVE sweepWREF = sweep
			WAVE/Z channel = sweepWREF[0]
			return WaveExists(channel) && DimSize(channel, ROWS) > 0
		endif
	else
		return WaveExists(sweep) &&        \
			   DimSize(sweep, COLS) > 0 && \
			   DimSize(sweep, ROWS) > 0
	endif
	return 0
End

/// @brief Check if the two waves are valid and compatible
///
/// @param sweep         sweep wave
/// @param config        config wave
/// @param configVersion [optional, defaults to #ITC_CONFIG_WAVE_VERSION] minimum required version of the config wave
threadsafe Function IsValidSweepAndConfig(sweep, config, [configVersion])
	WAVE/Z sweep, config
	variable configVersion

	if(ParamIsDefault(configVersion))
		configVersion = ITC_CONFIG_WAVE_VERSION
	endif

	if(IsWaveRefWave(sweep))
		return IsValidConfigWave(config, version = configVersion) &&  \
				 IsValidSweepWave(sweep) &&                           \
				 DimSize(sweep, ROWS) == DimSize(config, ROWS)
	else
		return IsValidConfigWave(config, version = configVersion) &&  \
				 IsValidSweepWave(sweep) &&                           \
				 DimSize(sweep, COLS) == DimSize(config, ROWS)
	endif
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

/// @brief constructs a fifo name for NI device ADC operations from the deviceID
Function/S GetNIFIFOName(deviceID)
	variable deviceID

	return HARDWARE_NI_ADC_FIFO + num2str(deviceID)
End

/// @brief Return the total onset delay of the given sweep
Function GetTotalOnsetDelay(numericalValues, sweepNo)
	WAVE numericalValues
	variable sweepNo

	return GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE) + \
			GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE)
End

/// @brief Check if the given multiplier is a valid sampling interval multiplier
Function IsValidSamplingMultiplier(multiplier)
	variable multiplier

	return IsFinite(multiplier) && WhichListItem(num2str(multiplier), DAP_GetSamplingMultiplier()) != -1
End

///@brief Places paired checkboxes in opposite state
///
/// @param win     window name
/// @param checkBoxIn	ctrl checkbox ex. cba.ctrlName
/// @param checkBoxPartner	checkbox that will be placed in opposite state
/// @param checkBoxInState	state of the ctrl checkbox
Function ToggleCheckBoxes(win, checkBoxIn, checkBoxPartner, checkBoxInState)
	string win
	string checkBoxIn
	string checkBoxPartner
	variable checkBoxInState

	SetCheckBoxState(win, checkBoxIn, checkBoxInState)
	DAG_Update(win, checkBoxIn, val = checkBoxInState)
	SetCheckBoxState(win, checkBoxPartner, !checkBoxInState)
	DAG_Update(win, checkBoxPartner, val = !checkBoxInState)
End

///@brief Placed paired checkboxes in same state
///
/// @param win     window name
/// @param checkBoxIn	ctrl checkbox ex. cba.ctrlName
/// @param checkBoxPartner	checkbox that will be placed in the same state
/// @param checkBoxInState	state of the ctrl checkbox
Function EqualizeCheckBoxes(win, checkBoxIn, checkBoxPartner, checkBoxInState)
	string win
	string checkBoxIn
	string checkBoxPartner
	variable checkBoxInState

	SetCheckBoxState(win, checkBoxIn, checkBoxInState)
	DAG_Update(win, checkBoxIn, val = checkBoxInState)

	SetCheckBoxState(win, checkBoxPartner, checkBoxInState)
	DAG_Update(win, checkBoxPartner, val = checkBoxInState)
End

/// @brief Return the MIES version with canonical EOLs
Function/S GetMIESVersionAsString()

	SVAR miesVersion = $GetMiesVersion()
	return NormalizeToEOL(miesVersion, "\n")
End

// @brief Common setup routine for all MIES background tasks for DAQ, TP and pressure control
Function SetupBackgroundTasks()
	CtrlNamedBackground $TASKNAME_TIMERMD, period = 6, proc=DQM_Timer
	CtrlNamedBackground $TASKNAME_FIFOMONMD, period=1, proc=DQM_FIFOMonitor
	CtrlNamedBackground $TASKNAME_FIFOMON, period = 5, proc=DQS_FIFOMonitor
	CtrlNamedBackground $TASKNAME_TIMER, period = 5, proc=DQS_Timer
	CtrlNamedBackground $TASKNAME_TPMD, period=5, proc=TPM_BkrdTPFuncMD
	CtrlNamedBackground $TASKNAME_TP, period = 5, proc=TPS_TestPulseFunc
	CtrlNamedBackground P_ITC_FIFOMonitor, period = 10, proc=P_ITC_FIFOMonitorProc
End

/// @brief Zero the wave using differentiation and integration
///
/// Overwrites the input wave
/// Preserves the WaveNote and adds the entry NOTE_KEY_ZEROED
///
/// 2D waves are zeroed along each row
threadsafe Function ZeroWave(wv)
	WAVE wv

	string wavenote

	if(GetNumberFromWaveNote(wv, NOTE_KEY_ZEROED) == 1)
		return NaN
	endif

	wavenote = note(wv)

	Differentiate/DIM=0/EP=1 wv
	Integrate/DIM=0 wv

	Note/K wv, wavenote
	SetNumberInWaveNote(wv, NOTE_KEY_ZEROED, 1)
End

/// @name Decimation methods
/// @anchor DecimationMethods
/// @{
Constant DECIMATION_NONE   = 0x0
Constant DECIMATION_MINMAX = 0x1
/// @}

/// @brief Return the size of the decimated wave
///
/// Query that to create the output wave before calling DecimateWithMethod().
///
/// @param numRows 			number of rows in the input wave
/// @param decimationFactor decimation factor, must be an integer and larger than 1
/// @param method      	    one of @ref DecimationMethods
Function GetDecimatedWaveSize(numRows, decimationFactor, method)
	variable numRows, decimationFactor, method

	variable decimatedSize

	ASSERT(IsInteger(decimationFactor) && decimationFactor > 1, "decimationFactor must be an integer and larger as 1.")

	switch(method)
		case DECIMATION_NONE:
			return numRows
		case DECIMATION_MINMAX:
			decimatedSize = ceil(numRows / decimationFactor)
			// make it even
			decimatedSize = mod(decimatedSize, 2) == 0 ? decimatedSize : ++decimatedSize
			return decimatedSize
		default:
			ASSERT(0, "Invalid method")
			break
	endswitch
End

/// @brief Decimate the the given input wave
///
/// This allows to decimate a given input row range into output rows using the
/// given method. The columns of input/output can be different. The input row
/// coordinates can be used to do a chunked conversion, e.g. when receiving
/// data from hardware. Incomplete chunks will be redone when necessary.
///
/// Algorithm visualized:
///
/// \rst
/// .. code-block:: text
///
///    Input (16 entries): [ | | | | | | | | | | | | | | | ]
///    Decimation factor: 4
///    Method: MinMax
///    Output (4 entries): [ min(input[0, 7]) | max(input[0, 7]) | min(input[8, 15]) | max(input[8, 15]) ]
///
/// \endrst
///
/// @param input             wave to decimate
/// @param output            target wave which will be around `decimationFactor` smaller than input
/// @param decimationFactor  decimation factor, must be an integer and larger than 1
/// @param method            one of @ref DecimationMethods
/// @param firstRowInp       [optional, defaults to 0] first row *input* coordinates
/// @param lastRowInp        [optional, defaults to last element] last row in *input* coordinates
/// @param firstColInp       [optional, defaults to 0] first col in *input* coordinates
/// @param lastColInp        [optional, defaults to last element] last col in *input* coordinates
/// @param firstColOut       [optional, defaults to firstColInp] first col in *output* coordinates
/// @param lastColOut        [optional, defaults to lastColInp] last col in *output* coordinates
/// @param factor            [optional, defaults to none] factor which is applied to
///                          all input columns and written into the output columns
Function DecimateWithMethod(input, output, decimationFactor, method, [firstRowInp, lastRowInp, firstColInp, lastColInp, firstColOut, lastColOut, factor])
	WAVE input
	WAVE output
	variable decimationFactor, method
	variable firstRowInp, lastRowInp, firstColInp, lastColInp, firstColOut, lastColOut
	WAVE/Z factor

	variable numRowsInp, numColsInp, numRowsOut, numColsOut, targetFirst, targetLast,  numOutputPairs, usedColumns, usedRows
	variable numRowsDecimated, first, last
	string msg, key

	// BEGIN parameter checking

	numRowsInp = DimSize(input, ROWS)
	numColsInp = DimSize(input, COLS)

	numRowsOut = DimSize(output, ROWS)
	numColsOut = DimSize(output, COLS)

	if(ParamIsDefault(firstRowInp))
		firstRowInp = 0
	else
		ASSERT(firstRowInp >= 0 && firstRowInp < numRowsInp, "Invalid firstRowInp value")
	endif

	if(ParamIsDefault(lastRowInp))
		lastRowInp = numRowsInp - 1
	else
		ASSERT(lastRowInp >= 0 && lastRowInp < numRowsInp, "Invalid lastRowInp value")
	endif

	[firstRowInp, lastRowInp] = MinMax(firstRowInp, lastRowInp)

	usedRows = lastRowInp - firstRowInp + 1

	if(ParamIsDefault(firstColInp))
		firstColInp = 0
	else
		ASSERT(firstColInp >= 0 && (firstColInp < numColsInp || (firstColInp == 0 && numColsInp <= 1)), "Invalid firstColInp value")
	endif

	if(ParamIsDefault(lastColInp))
		lastColInp = max(numColsInp - 1, 0)
	else
		ASSERT(lastColInp >= 0 && (lastColInp < numColsInp || (lastColInp == 0 && numColsInp <= 1)), "Invalid lastColInp value")
	endif

	[firstColInp, lastColInp] = MinMax(firstColInp, lastColInp)

	usedColumns = lastColInp - firstColInp + 1

	if(ParamIsDefault(firstColOut))
		firstColOut = firstColInp
	else
		ASSERT(firstColOut >= 0 && (firstColOut < numColsOut || (firstColOut == 0 && numColsOut <= 1)), "Invalid firstColOut value")
	endif

	if(ParamIsDefault(lastColOut))
		lastColOut = lastColInp
	else
		ASSERT(lastColOut >= 0 && (lastColOut < numColsOut || (lastColOut == 0 && numColsOut <= 1)), "Invalid lastColOut value")
	endif

	[firstColOut, lastColOut] = MinMax(firstColOut, lastColOut)

	ASSERT(usedColumns == (lastColOut - firstColOut + 1), "Non-matching column ranges")

	if(!ParamIsDefault(factor))
		ASSERT(WaveExists(factor) && usedColumns == DimSize(factor, ROWS), "Invalid size of factor")
	endif

	// END parameter checking

	numRowsDecimated = GetDecimatedWaveSize(numRowsInp, decimationFactor, method)
	ASSERT(mod(numRowsDecimated, 2) == 0, "numRowsDecimated must be even")
	numOutputPairs = numRowsDecimated / 2

	ASSERT(DimSize(output, ROWS) == numRowsDecimated, "Output wave has the wrong size.")

	// This wave is only used to run the multithread assignment. We don't care about the values.

	key = CA_TemporaryWaveKey({numOutputPairs, usedColumns})
	WAVE/Z/B junkWave = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(!WaveExists(junkWave))
		Make/N=(numOutputPairs, usedColumns)/FREE/B junkWave
		CA_StoreEntryIntoCache(key, junkWave, options = CA_OPTS_NO_DUPLICATE)
	endif

	targetFirst = floor(firstRowInp / (decimationFactor * 2))
	targetLast  = min(ceil(lastRowInp / (decimationFactor * 2)), numOutputPairs - 1)

	if(targetFirst > targetLast)
		return NaN
	endif

	sprintf msg, "method %d, decFactor %d, numOutputPairs %d\r", method, decimationFactor, numOutputPairs
	DEBUGPRINT(msg)
	sprintf msg, "input[%08d][%08d], output[%08d][%08d]; rows [%08d, %08d] -> pairs [%08d, %08d]; cols [%d, %d] [%d, %d]\r", numRowsInp, numColsInp, DimSize(output, ROWS), DimSize(output, COLS), firstRowInp, lastRowInp, targetFirst, targetLast, firstColInp, lastColInp, firstColOut, lastColOut
	DEBUGPRINT(msg)

	switch(method)
		case DECIMATION_MINMAX:
			Multithread junkWave[targetFirst, targetLast][] = DecimateMinMax(input, output, p, firstRowInp, lastRowInp, firstColInp + q, firstColOut + q, decimationFactor)
			break
		default:
			ASSERT(0, "Unsupported method")
			break
	endswitch

	if(WaveExists(factor))
		// same formulas as in DecimateMinMax
		first = targetFirst * 2
		last  = targetLast * 2 + 1

		Multithread output[first, last][firstColOut, lastColOut] *= factor[q - firstColOut]
	endif
End

/// @brief Threadsafe helper function for DecimateWithMethod
///
/// @param input            input wave
/// @param output           output wave
/// @param idx              output pair index
/// @param firstRowInp      first row in *input* coordinates
/// @param lastRowInp       last row in *input* coordinates
/// @param colInp           column in *input* coordinates
/// @param colOut           column in *output* coordinates
/// @param decimationFactor decimation factor
threadsafe static Function DecimateMinMax(input, output, idx, firstRowInp, lastRowInp, colInp, colOut, decimationFactor)
	WAVE input, output
	variable idx, colInp, colOut, decimationFactor, firstRowInp, lastRowInp

	variable first, last, targetFirst, targetLast

	first = idx * decimationFactor * 2
	last  = (idx + 1) * decimationFactor * 2 - 1

	if(first > lastRowInp)
		return NaN
	endif

	last  = min(last, lastRowInp)

	targetFirst = idx * 2
	targetLast = (idx * 2) + 1

	WaveStats/Q/M=1/RMD=[first, last][colInp] input
	ASSERT_TS(V_numINFS == 0, "INFs are not supported.")
	ASSERT_TS(V_numNaNS == 0, "NaNs are not supported.")
	ASSERT_TS(last - first + 1 == V_npnts && V_npnts > 0, "Range got clipped")

// comment in for debugging
// #ifdef DEBUGGING_ENABLED
//   if(DP_DebuggingEnabledForFile(GetFile(FunctionPath(""))))
// 		printf "[%d, %d] -> [%d, %d]; min %g; max %g;\r", first, last, targetFirst, targetLast, V_min, V_max
//   endif
// #endif // DEBUGGING_ENABLED

	output[targetFirst][colOut] = V_min
	output[targetLast][colOut]  = V_max
End

/// @brief Starts with a new experiment.
///
/// You have to manually save before, see SaveExperimentWrapper()
Function NewExperiment()

	Execute/P/Q "NEWEXPERIMENT "
End

/// @brief Remove the volatile part of the XOP error code
///
/// The result is constant and can therefore be compared with constants.
///
///	 From http://www.igorexchange.com/node/7286
threadsafe Function ConvertXOPErrorCode(xopError)
	variable xopError

	return xopError == 0 ? 0 : ((xopError & 0xFFFF) + 10000)
End

/// @brief Extended version of `FindValue`
///
/// Allows to search only the specified column for a value
/// and returns all matching row indizes in a wave. By defaults only looks into the first layer
/// for backward compatibility reasons.
///
/// Exactly one of `var`/`str`/`prop` has to be given except for
/// `prop == PROP_MATCHES_VAR_BIT_MASK` and `prop == PROP_NOT_MATCHES_VAR_BIT_MASK`
/// which requires a `var`/`str` parameter as well.
///
/// Exactly one of `col`/`colLabel` has to be given.
///
/// @param numericOrTextWave   wave to search in
/// @param col [optional]      column to search in only
/// @param colLabel [optional] column label to search in only
/// @param var [optional]      numeric value to search
/// @param str [optional]      string value to search
/// @param prop [optional]     property to search, see @ref FindIndizesProps
/// @param startRow [optional] starting row to restrict the search to
/// @param endRow [optional]   ending row to restrict the search to
/// @param startLayer [optional, defaults to zero] starting layer to restrict search to
/// @param endLayer [optional, defaults to zero] ending layer to restrict search to
///
/// @returns A wave with the row indizes of the found values. An invalid wave reference if the
/// value could not be found.
Function/Wave FindIndizes(numericOrTextWave, [col, colLabel, var, str, prop, startRow, endRow, startLayer, endLayer])
	WAVE numericOrTextWave
	variable col, var, prop
	string str, colLabel
	variable startRow, endRow
	variable startLayer, endLayer

	variable numCols, numRows, numLayers
	string key

	ASSERT(ParamIsDefault(col) + ParamIsDefault(colLabel) == 1, "Expected exactly one col/colLabel argument")
	ASSERT(ParamIsDefault(prop) + ParamIsDefault(var) + ParamIsDefault(str) == 2              \
		   || (!ParamIsDefault(prop)                                                          \
			  && (prop == PROP_MATCHES_VAR_BIT_MASK || prop == PROP_NOT_MATCHES_VAR_BIT_MASK) \
			  && (ParamIsDefault(var) + ParamIsDefault(str)) == 1),                           \
			  "Invalid combination of var/str/prop arguments")

	ASSERT(WaveExists(numericOrTextWave), "numericOrTextWave does not exist")

	if(DimSize(numericOrTextWave, ROWS) == 0)
		return $""
	endif

	numRows   = DimSize(numericOrTextWave, ROWS)
	numCols   = DimSize(numericOrTextWave, COLS)
	numLayers = DimSize(numericOrTextWave, LAYERS)
	ASSERT(DimSize(numericOrTextWave, CHUNKS) <= 1, "No support for chunks")

	if(!ParamIsDefault(colLabel))
		col = FindDimLabel(numericOrTextWave, COLS, colLabel)
		ASSERT(col >= 0, "invalid column label")
	endif

	ASSERT(col == 0 || (col > 0 && col < numCols), "Invalid column")

	if(IsTextWave(numericOrTextWave))
		WAVE/T wvText = numericOrTextWave
		WAVE/Z wv     = $""
	else
		WAVE/T/Z wvText = $""
		WAVE wv         = numericOrTextWave
	endif

	if(!ParamIsDefault(prop))
		ASSERT(prop == PROP_NON_EMPTY                    \
			   || prop == PROP_EMPTY                     \
			   || prop == PROP_MATCHES_VAR_BIT_MASK      \
			   || prop == PROP_NOT_MATCHES_VAR_BIT_MASK, \
			   "Invalid property")

		if(prop == PROP_MATCHES_VAR_BIT_MASK || prop == PROP_NOT_MATCHES_VAR_BIT_MASK)
			if(ParamIsDefault(var))
				var = str2numSafe(str)
			elseif(ParamIsDefault(str))
				str = num2str(var)
			endif
		endif
	elseif(!ParamIsDefault(var))
		str = num2str(var)
	elseif(!ParamIsDefault(str))
		var = str2numSafe(str)
	endif

	if(ParamIsDefault(startRow))
		startRow = 0
	else
		ASSERT(startRow >= 0 && startRow < numRows, "Invalid startRow")
	endif

	if(ParamIsDefault(endRow))
		endRow = inf
	else
		ASSERT(endRow >= 0 && endRow < numRows, "Invalid endRow")
	endif

	ASSERT(startRow <= endRow, "endRow must be larger than startRow")

	if(ParamIsDefault(startLayer))
		startLayer = 0
	else
		ASSERT(startLayer >= 0 && (numLayers == 0 || startLayer < numLayers), "Invalid startLayer")
	endif

	if(ParamIsDefault(endLayer))
		// only look in the first layer by default
		endLayer = 0
	else
		ASSERT(endLayer >= 0 && (numLayers == 0 || endLayer < numLayers), "Invalid endLayer")
	endif

	ASSERT(startLayer <= endLayer, "endLayer must be larger than startLayer")

	// Algorithm:
	// * The matches wave has the same size as one column of the input wave
	// * -1 means no match, every value larger or equal than zero is the row index of the match
	// * There is no distinction between different layers matching
	// * After the matches have been calculated we take the maximum of the transposed matches
	//   wave in each colum transpose back and replace -1 with NaN
	// * This gives a 1D wave with NaN in the rows with no match, and the row index of the match otherwise
	// * Delete all NaNs in the wave and return it

	key = CA_TemporaryWaveKey({numRows, numLayers})
	WAVE/Z matches = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(!WaveExists(matches))
		Make/N=(numRows, numLayers)/FREE/R matches
		CA_StoreEntryIntoCache(key, matches, options = CA_OPTS_NO_DUPLICATE)
	endif

	FastOp matches = -1

	if(WaveExists(wv))
		if(!ParamIsDefault(prop))
			if(prop == PROP_EMPTY)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (numtype(wv[p][col][q]) == 2 ? p : -1)
			elseif(prop == PROP_NON_EMPTY)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (numtype(wv[p][col][q]) != 2 ? p : -1)
			elseif(prop == PROP_MATCHES_VAR_BIT_MASK)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (wv[p][col][q] & var ? p : -1)
			elseif(prop == PROP_NOT_MATCHES_VAR_BIT_MASK)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (!(wv[p][col][q] & var) ? p : -1)
			endif
		else
			ASSERT(!IsNaN(var), "Use PROP_EMPTY to search for NaN")
			MultiThread matches[startRow, endRow][startLayer, endLayer] = ((wv[p][col][q] == var) ? p : -1)
		endif
	else
		if(!ParamIsDefault(prop))
			if(prop == PROP_EMPTY)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (!cmpstr(wvText[p][col][q], "") ? p : -1)
			elseif(prop == PROP_NON_EMPTY)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (cmpstr(wvText[p][col][q], "") ? p : -1)
			elseif(prop == PROP_MATCHES_VAR_BIT_MASK)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (str2num(wvText[p][col][q]) & var ? p : -1)
			elseif(prop == PROP_NOT_MATCHES_VAR_BIT_MASK)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (!(str2num(wvText[p][col][q]) & var) ? p : -1)
			endif
		else
			MultiThread matches[startRow, endRow][startLayer, endLayer] = (!cmpstr(wvText[p][col][q], str) ? p : -1)
		endif
	endif

	endRow = numRows - 1
	MatrixOp/Free result = replace(maxCols(subRange(matches, startRow, endRow, startLayer, endLayer)^t)^t, -1, NaN)
	WaveTransform/O zapNaNs, result

	if(DimSize(result, ROWS) == 0)
		return $""
	endif

	return result
End

/// @brief Searches the column colLabel in wv for an non-empty
/// entry with a row number smaller or equal to endRow
///
/// Return an empty string if nothing could be found.
///
/// @param wv         text wave to search in
/// @param colLabel   column label from wv
/// @param endRow     maximum row index to consider
Function/S GetLastNonEmptyEntry(wv, colLabel, endRow)
	Wave/T wv
	string colLabel
	variable endRow

	WAVE/Z indizes = FindIndizes(wv, colLabel=colLabel, prop=PROP_NON_EMPTY, endRow=endRow)

	if(!WaveExists(indizes))
		return ""
	endif

	return wv[indizes[DimSize(indizes, ROWS) - 1]][%$colLabel]
End

/// @brief Generate a default settings file in JSON format
///
/// \rst
/// .. code-block:: json
///
/// 	{
/// 	  "diagnostics": {
/// 	    "last upload": "2020-03-05T13:43:32Z"
/// 	  },
/// 	  "version": 1
/// 	}
///
///	\endrst
///
/// Explanation:
/// - "version": Major version number to track breaking changes
/// - "diagnostics": Groups settings related to diagnostics and crash dump handling
/// - "diagnostics/last upload": ISO8601 timestamp when the last successfull
///                              upload of crash dumps was tried. This is also set
///                              when no crash dumps have been uploadad.
/// - "analysisbrowser": Groups settings related to the Analysisbrowser
/// - "analysisbrowser/directory": The directory initially opened for browsing existing NWB/PXP files
///
/// @return JSONid
///
/// Caller is responsible for releasing the document.
Function GenerateSettingsDefaults()

	variable JSONid

	JSONid = JSON_New()

	JSON_AddVariable(JSONid, "version", 1)
	JSON_AddTreeObject(JSONid, "/diagnostics")
	JSON_AddString(JSONid, "/diagnostics/last upload", GetIso8601TimeStamp(secondsSinceIgorEpoch=0))

	UpgradeSettings(JSONid)

	return JSONid
End

Function UpgradeSettings(JSONid)
	variable JSONid

	if(!JSON_Exists(JSONid, "/analysisbrowser"))
		JSON_AddTreeObject(JSONid, "/analysisbrowser")
		JSON_AddString(JSONid, "/analysisbrowser/directory", "C:")
	endif
End

/// @brief Call UploadCrashDumps() if we haven't called it since at least a day.
Function UploadCrashDumpsDaily()

	variable lastWrite

	try
		ClearRTError()
		NVAR JSONid = $GetSettingsJSONid()

		lastWrite = ParseISO8601TimeStamp(JSON_GetString(jsonID, "/diagnostics/last upload"))

		if((lastWrite + 24 * 3600) > DateTimeInUTC())
			// nothing to do
			return NaN
		endif

		if(UploadCrashDumps())
			printf "Crash dumps have been successfully uploaded.\r"
		endif

		JSON_SetString(jsonID, "/diagnostics/last upload", GetIso8601TimeStamp())
		AbortOnRTE
	catch
		ClearRTError()
		BUG("Could not upload crash dumps!")
	endtry
End

/// @brief Return the graph user data as 2D text wave
///
/// Only returns infos for sweep traces without duplicates.
/// Duplicates are present with oodDAQ display mode.
Function/WAVE GetTraceInfos(string graph)

	if(TUD_GetTraceCount(graph) == 0)
		return $""
	endif

	WAVE matches = TUD_GetUserDataAsWave(graph, "fullPath", returnIndizes = 1, keys = {"traceType", "occurence"}, values = {"Sweep", "0"})

	WAVE/T graphUserData = GetGraphUserData(graph)

	Make/FREE/T/N=(DimSize(matches, ROWS), DimSize(graphUserData, COLS)) graphUserDataSelection
	CopyDimLabels graphUserData, graphUserDataSelection
	Multithread graphUserDataSelection[][] = graphUserData[matches[p]][q]

	SortColumns/A/DIML/KNDX={2, 3, 4, 5} sortWaves=graphUserDataSelection

	return graphUserDataSelection
End

/// @brief Remove the given sweep from the Databrowser/Sweepbrowser
///
/// Needs a manual call to PostPlotTransformations() afterwards.
///
/// @param win              graph
/// @param index            overlay sweeps listbox index
Function RemoveSweepFromGraph(string win, variable index)
	string device, graph, dataFolder, experiment
	string trace
	variable sweepNo, i, numTraces

	graph = GetMainWindow(win)

	if(BSP_MainPanelNeedsUpdate(graph))
		DoAbortNow("Can not display data. The panel is too old to be usable. Please close it and open a new one.")
	endif

	if(!BSP_HasBoundDevice(graph))
		return NaN
	endif

	DEBUGPRINT("Removing sweep with index ", var = index)

	[sweepNo, experiment] = OVS_GetSweepAndExperiment(graph, index)

	WAVE/T/Z traces = TUD_GetUserDataAsWave(graph, "tracename", keys = {"traceType", "sweepNumber", "experiment"}, \
	                                        values = {"sweep", num2str(sweepNo), experiment})

	if(!WaveExists(traces))
		return NaN
	endif

	numTraces = DimSize(traces, ROWS)
	for(i = 0; i < numTraces; i += 1)
		trace = traces[i]

		RemoveFromGraph/W=$graph $trace
		TUD_RemoveUserData(graph, trace)
	endfor
End

/// @brief Add the given sweep to the Databrowser/Sweepbrowser
///
/// Needs a manual call to PostPlotTransformations() afterwards.
///
/// @param win   graph
/// @param index overlay sweeps listbox index
Function AddSweepToGraph(string win, variable index)

	if(BSP_MainPanelNeedsUpdate(win))
		DoAbortNow("Can not display data. The panel is too old to be usable. Please close it and open a new one.")
	endif

	if(!BSP_HasBoundDevice(win))
		return NaN
	endif

	DEBUGPRINT("Adding sweep with index ", var = index)

	if(BSP_IsDataBrowser(win))
		DB_AddSweepToGraph(win, index)
	else
		SB_AddSweepToGraph(win, index)
	endif
End

/// @brief Update the given sweep in the Databrowser/Sweepbrowser plot
///
/// Needs a manual call to PostPlotTransformations() afterwards.
///
/// @param win   graph
/// @param index overlay sweeps listbox index
Function UpdateSweepInGraph(string win, variable index)

	string graph

	graph = GetMainWindow(win)

	WAVE axesRanges = GetAxesRanges(graph)
	WAVE/T/Z cursorInfos = GetCursorInfos(graph)

	RemoveSweepFromGraph(win, index)
	AddSweepToGraph(win, index)

	RestoreCursors(graph, cursorInfos)
	SetAxesRanges(graph, axesRanges)
End
