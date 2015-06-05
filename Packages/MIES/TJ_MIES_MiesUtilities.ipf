#pragma rtGlobals=3

/// @file TJ_MIES_MiesUtilities.ipf
/// This file holds utility functions which need to know about MIES internals.

static StrConstant LABNOTEBOOK_BOTTOM_AXIS_TIME  = "Timestamp (a. u.)"
static StrConstant LABNOTEBOOK_BOTTOM_AXIS_SWEEP = "Sweep Number (a. u.)"

static Constant GRAPH_DIV_SPACING                = 0.03

/// @brief Extracts the date/time column of the settingsHistory wave
///
/// This is useful if you want to plot values against the time and let
/// Igor do the formatting of the date/time values
Function/WAVE GetSettingsHistoryDateTime(settingsHistory)
	WAVE settingsHistory

	DFREF dfr = GetWavesDataFolderDFR(settingsHistory)
	WAVE/Z/SDFR=dfr settingsHistoryDat
	variable nextRowIndex = GetNumberFromWaveNote(settingsHistory, NOTE_INDEX)

	if(!WaveExists(settingsHistoryDat) || DimSize(settingsHistoryDat, ROWS) != DimSize(settingsHistory, ROWS) || DimSize(settingsHistoryDat, ROWS) < nextRowIndex || !IsFinite(settingsHistoryDat[nextRowIndex - 1]))
		Duplicate/O/R=[0, DimSize(settingsHistory, ROWS)][1][-1][-1] settingsHistory, dfr:settingsHistoryDat/Wave=settingsHistoryDat
		// we want to have a pure 1D wave without any columns or layers, this is currently not possible with Duplicate
		Redimension/N=-1 settingsHistoryDat
		// redimension has the odd behaviour to change a wave with zero rows to one with 1 row and then initializes that point to zero
		// we need to fix that
		if(DimSize(settingsHistoryDat, ROWS) == 1)
			settingsHistoryDat = NaN
		endif
		SetScale d, 0, 0, "dat" settingsHistoryDat
		SetDimLabel ROWS, -1, TimeStamp, settingsHistoryDat
	endif

	return settingsHistoryDat
End

/// @brief Returns a list of all active DA channels
/// @todo change function to return a numeric wave of variable length
/// and merge with GetADCListFromConfig
Function/S GetDACListFromConfig(ITCChanConfigWave)
	Wave ITCChanConfigWave

	return RefToPullDatafrom2DWave(1, 0, 1, ITCChanConfigWave)
End

/// @brief Returns a list of all active AD channels
Function/S GetADCListFromConfig(ITCChanConfigWave)
	Wave ITCChanConfigWave

	return RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
End

/// @brief Returns the data from the data column based on matched values in the ref column
///
/// For ITCDataWave 0 (value) in Ref column = AD channel, 1 = DA channel
static Function/s RefToPullDatafrom2DWave(refValue, refColumn, dataColumn, twoDWave)
	wave twoDWave
	variable refValue, refColumn, dataColumn

	variable i, numRows
	string list = ""

	numRows = DimSize(twoDWave, ROWS)
	for(i = 0; i < numRows; i += 1)
		if(TwoDwave[i][refColumn] == refValue)
			list = AddListItem(num2str(TwoDwave[i][DataColumn]), list, ";", i)
		endif
	endfor

	return list
End

/// @brief Returns the name of a control from the DA_EPHYS panel
///
/// Constants are defined at @ref ChannelTypeAndControlConstants
Function/S GetPanelControl(panelTitle, idx, channelType, controlType)
	string panelTitle
	variable idx, channelType, controlType

	string ctrl

	if(channelType == CHANNEL_TYPE_DAC)
		ctrl = "DA"
	elseif(channelType == CHANNEL_TYPE_ADC)
		ctrl = "AD"
	elseif(channelType == CHANNEL_TYPE_TTL)
		ctrl = "TTL"
	else
		ASSERT(0, "Invalid channelType")
	endif

	if(controlType == CHANNEL_CONTROL_WAVE)
		ctrl = "Wave_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_INDEX_END)
		ctrl = "Popup_" + ctrl + "_IndexEnd"
	elseif(controlType == CHANNEL_CONTROL_UNIT)
		ctrl = "Unit_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_GAIN)
		ctrl = "Gain_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_SCALE)
		ctrl = "Scale_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_CHECK)
		ctrl = "Check_" + ctrl
	else
		ASSERT(0, "Invalid controlType")
	endif

	ASSERT(idx >= 0 && idx < 100, "invalid idx")
	sprintf ctrl, "%s_%02d", ctrl, idx

	return ctrl
End

/// @brief Returns the numerical index for the sweep number column
/// in the settings history wave
Function GetSweepColumn(settingsHistory)
	Wave settingsHistory

	variable sweepCol

	// new label
	sweepCol = FindDimLabel(settingsHistory, COLS, "SweepNum")

	if(sweepCol >= 0)
		return sweepCol
	endif

	// Old label prior to 276b5cf6
	// was normally overwritten by SweepNum later in the code
	// but not always as it turned out
	sweepCol = FindDimLabel(settingsHistory, COLS, "SweepNumber")

	if(sweepCol >= 0)
		return sweepCol
	endif

	// text documentation waves
	sweepCol = FindDimLabel(settingsHistory, COLS, "Sweep #")

	if(sweepCol >= 0)
		return sweepCol
	endif

	DEBUGPRINT("Could not find sweep number dimension label, trying with column zero")

	return 0
End

/// @brief Returns a wave with the latest value of a setting from the history wave
/// for a given sweep number.
///
/// @returns a wave with the value for each headstage in a row. In case
/// the setting could not be found an invalid wave reference is returned.
Function/WAVE GetLastSetting(history, sweepNo, setting)
	Wave history
	variable sweepNo
	string setting

	variable settingCol, numLayers, i, sweepCol, numEntries
	variable first, last

	ASSERT(WaveType(history), "Can only work with numeric waves")
	numLayers = DimSize(history, LAYERS)
	settingCol = FindDimLabel(history, COLS, setting)

	if(settingCol <= 0)
		DEBUGPRINT("Could not find the setting", str=setting)
		return $""
	endif

	sweepCol = GetSweepColumn(history)
	FindRange(history, sweepCol, sweepNo, 0, first, last)

	if(!IsFinite(first) && !IsFinite(last)) // sweep number is unknown
		return $""
	endif

	Make/FREE/N=(numLayers) status

	for(i = last; i >= first; i -= 1)

		status[] = history[i][settingCol][p]
		WaveStats/Q/M=1 status

		// return if at least one entry is not NaN
		if(V_numNaNs != numLayers)
			return status
		endif
	endfor

	return $""
End

/// @brief Returns a wave with latest value of a setting from the history wave
/// for a given sweep number.
///
/// Text wave version of `GetLastSetting`.
///
/// @returns a wave with the value for each headstage in a row. In case
/// the setting could not be found an invalid wave reference is returned.
Function/WAVE GetLastSettingText(history, sweepNo, setting)
	Wave/T history
	variable sweepNo
	string setting

	variable settingCol, numLayers, i, sweepCol
	variable first, last

	ASSERT(!WaveType(history), "Can only work with text waves")
	numLayers = DimSize(history, LAYERS)
	settingCol = FindDimLabel(history, COLS, setting)

	if(settingCol <= 0)
		DEBUGPRINT("Could not find the setting", str=setting)
		return $""
	endif

	sweepCol = GetSweepColumn(history)
	FindRange(history, sweepCol, sweepNo, 0, first, last)

	if(!IsFinite(first) && !IsFinite(last)) // sweep number is unknown
		return $""
	endif

	Make/FREE/N=(numLayers)/T status
	Make/FREE/N=(numLayers) lengths

	for(i = last; i >= first; i -= 1)

		status[] = history[i][settingCol][p]
		lengths[] = strlen(status[p])

		// return if we have at least one non-empty entry
		if(Sum(lengths) > 0)
			return status
		endif
	endfor

	return $""
End

/// @brief Returns a list of all devices, e.g. "ITC18USB_Dev_0;", with an existing datafolder returned by ´GetDevicePathAsString(device)´
Function/S GetAllActiveDevices()

	variable i, j, numTypes, numNumbers
	string type, number, device
	string path, list = ""

	path = GetITCDevicesFolderAsString()

	if(!DataFolderExists(path))
		return ""
	endif

	numTypes   = ItemsInList(DEVICE_TYPES)
	numNumbers = ItemsInList(DEVICE_NUMBERS)
	for(i = 0; i < numTypes; i += 1)
		type = StringFromList(i, DEVICE_TYPES)

		path = GetDeviceTypePathAsString(type)

		if(!DataFolderExists(path))
			continue
		endif

		for(j = 0; j < numNumbers ; j += 1)
			number = StringFromList(j, DEVICE_NUMBERS)
			device = BuildDeviceString(type, number)
			path   = GetDevicePathAsString(device)

			if(!DataFolderExists(path))
				continue
			endif

			list = AddListItem(device, list, ";", inf)
		endfor
	endfor

	return list
End

/// @brief Returns a list of all devices, e.g. "ITC18USB_Dev_0;", which have acquired data.
Function/S GetAllDevicesWithData()

	variable i, numDevices
	string deviceList, device, path
	string list = ""

	deviceList = GetAllActiveDevices()

	numDevices = ItemsInList(deviceList)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, deviceList)
		path   = GetDeviceDataPathAsString(device)

		if(!DataFolderExists(path))
			continue
		endif

		if(CountObjects(path, COUNTOBJECTS_WAVES) == 0)
			continue
		endif

		list = AddListItem(device, list, ";", inf)
	endfor

	return list
End

/// @brief Delete a datafolder or wave. If this is not possible, because Igor
/// has locked the file, the wave or datafolder is moved into a trash folder
/// named `root:mies:trash_$digit`.
///
/// The trash folders will be removed, if possible, from KillTemporaries().
///
/// @param path absolute path to a datafolder or wave
Function KillOrMoveToTrash(path)
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

/// @brief Returns the config wave for a given sweep wave
Function/Wave GetConfigWave(sweepWave)
	Wave sweepWave

	string name = "Config_" + NameOfWave(sweepWave)
	Wave/SDFR=GetWavesDataFolderDFR(sweepWave) config = $name
	ASSERT(DimSize(config,COLS)==4,"Unexpected number of columns")
	return config
End

/// @brief Returns the, possibly non existing, sweep data wave for the given sweep number
Function/Wave GetSweepWave(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	Wave/Z/SDFR=GetDeviceDataPath(panelTitle) wv = $("Sweep_" + num2str(sweepNo))

	return wv
End

/// @brief Returns the sampling interval of the sweep
/// in microseconds (1e-6s)
Function GetSamplingInterval(sweepWave)
	Wave sweepWave

	Wave config = GetConfigWave(sweepWave)

	// from ITCConfigAllChannels help file:
	// Third Column  = SamplingInterval:  integer value for sampling interval in microseconds (minimum value - 5 us)
	Duplicate/D/R=[][2]/FREE config samplingInterval

	// The sampling interval is the same for all channels
	ASSERT(numpnts(samplingInterval),"Expected non-empty wave")
	ASSERT(WaveMax(samplingInterval) == WaveMin(samplingInterval),"Expected constant sample interval for all channels")
	return samplingInterval[0]
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

/// @brief Parse a device string of the form X_DEV_Y, where X is from @ref DEVICE_TYPES
/// and Y from @ref DEVICE_NUMBERS.
///
/// Returns the result in deviceType and deviceNumber.
/// Currently the parsing is successfull if X and Y are non-empty.
/// @param[in]  device       input device string X_DEV_Y
/// @param[out] deviceType   returns the device type X
/// @param[out] deviceNumber returns the device number Y
/// @returns one on successfull parsing, zero on error
Function ParseDeviceString(device, deviceType, deviceNumber)
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
/// Passing in sweepWave assumes the old format of the sweep data (all data in one wave as received by the ITC XOP)
/// Passing in sweepDFR assumes the new format of split waves, one wave for each AD, DA, TTL channel, with one dimension
///
/// @param graph                window
/// @param config               ITC config wave
/// @param sweepNo              number of the sweep
/// @param settingsHistory      numerical labnotebook wave
/// @param displayDAC           display the DA channel, yes or no
/// @param overlaySweep         overlay the sweeps, yes or no
/// @param overlayChannels      use a separate axis for each DA/AD channel, yes or no
/// @param sweepDFR [optional]  datafolder with 1D waves extracted from the sweep wave
/// @param sweepWave [optional] sweep wave with multiple columns
Function CreateTiledChannelGraph(graph, config, sweepNo, settingsHistory, displayDAC, overlaySweep, overlayChannels, [sweepDFR, sweepWave])
	string graph
	WAVE config
	variable sweepNo
	WAVE settingsHistory
	variable displayDAC, overlaySweep, overlayChannels
	DFREF sweepDFR
	WAVE/Z sweepWave

	ASSERT(!isEmpty(graph), "Empty graph")
	ASSERT(IsFinite(sweepNo), "Non-finite sweepNo")
	ASSERT(ParamIsDefault(sweepDFR) + ParamIsDefault(sweepWave), "Caller must supply exactly one of sweepDFR and sweepWave")

	string ADChannelList = GetADCListFromConfig(config)
	string DAChannelList = GetDACListFromConfig(config)
	variable NumberOfDAchannels = ItemsInList(DAChannelList)
	variable NumberOfADchannels = ItemsInList(ADChannelList)
	// the max allows for uneven number of AD and DA channels
	variable numChannels = max(NumberOfDAchannels, NumberOfADchannels)
	variable ADYaxisLow, ADYaxisHigh, ADYaxisSpacing, DAYaxisSpacing, DAYaxisLow, DAYaxisHigh
	variable headstage, red, green, blue, i, axisIndex, splitSweepMode
	variable firstDAC = 1
	variable firstADC = 1

	string axis, trace, adc, dac, traceType
	string configNote = note(config)
	string unit

	if(!ParamIsDefault(sweepDFR))
		splitSweepMode = 1
	endif

	WAVE ranges = GetAxesRanges(graph)

	if(!overlaySweep)
		RemoveTracesFromGraph(graph)
	endif

	if(displayDAC)
		ADYaxisSpacing = 0.8
		DAYaxisSpacing = 0.2

		if(!overlayChannels)
			ADYaxisSpacing /= numChannels
			DAYaxisSpacing /= numChannels
		endif
	else
		ADYaxisSpacing = 1

		if(!overlayChannels)
			ADYaxisSpacing /= NumberOfADchannels
		endif
	endif

	if(displayDAC)
		DAYaxisHigh = 1
		DAYaxisLow  = DAYaxisHigh - DAYaxisSpacing + GRAPH_DIV_SPACING
		ADYaxisHigh = DAYaxisLow - GRAPH_DIV_SPACING
		ADYaxisLow  = ADYaxisHigh - ADYaxisSpacing + GRAPH_DIV_SPACING
	else
		ADYaxisHigh = 1
		ADYaxisLow  = 1 - ADYaxisSpacing + GRAPH_DIV_SPACING
	endif

	WAVE/Z statusDAC = GetLastSetting(settingsHistory, sweepNo, "DAC")
	WAVE/Z statusADC = GetLastSetting(settingsHistory, sweepNo, "ADC")

	for(i = 0; i < numChannels; i += 1)
		if(displayDAC && i < NumberOfDAchannels)
			dac = StringFromList(i, DAChannelList)
			traceType = "DA" + dac
			trace = UniqueTraceName(graph, traceType)

			if(overlayChannels)
				axis = AXIS_BASE_NAME + "_DA"
			else
				axis = AXIS_BASE_NAME + num2str(axisIndex)
				axisIndex += 1
			endif

			if(splitSweepMode)
				WAVE/SDFR=sweepDFR wv = $("DA_" + dac)
				AppendToGraph/W=$graph/L=$axis wv/TN=$trace
			else
				AppendToGraph/W=$graph/L=$axis sweepWave[][i]/TN=$trace
			endif

			if(firstDAC || !overlayChannels)
				ModifyGraph/W=$graph axisEnab($axis) = {DAYaxisLow, DAYaxisHigh}
				unit = StringFromList(i, configNote)
				Label/W=$graph $axis, traceType + "\r(" + unit + ")"
				ModifyGraph/W=$graph lblPosMode = 1
				ModifyGraph/W=$graph standoff($axis) = 0, freePos($axis) = 0
				firstDAC = 0
			endif

			headstage = WaveExists(statusDAC) ? GetRowIndex(statusDAC, str=dac) : NaN
			// use a different color if we can't query the headstage
			GetTraceColor(IsFinite(headstage) ? headstage : NUM_HEADSTAGES, red, green, blue)
			ModifyGraph/W=$graph rgb($trace)=(red, green, blue)
			ModifyGraph/W=$graph userData($trace)={channelType, 0, "DA"}
			ModifyGraph/W=$graph userData($trace)={channelNumber, 0, dac}
			ModifyGraph/W=$graph userData($trace)={sweepNumber, 0, num2str(sweepNo)}
		endif

		if(i < NumberOfADchannels)
			adc = StringFromList(i, ADChannelList)
			traceType = "AD" + adc
			trace = UniqueTraceName(graph, traceType)

			if(overlayChannels)
				axis = AXIS_BASE_NAME + "_AD"
			else
				axis = AXIS_BASE_NAME + num2str(axisIndex)
				axisIndex += 1
			endif

			if(splitSweepMode)
				WAVE/Z/SDFR=sweepDFR wv = $("AD_" + adc)
				if(WaveExists(wv))
					AppendToGraph/W=$graph/L=$axis wv/TN=$trace
				else
					printf "BUG: ADC %s to plot does not exist\r", adc
					continue
				endif
			else
				AppendToGraph/W=$graph/L=$axis sweepWave[][i + NumberOfDAchannels]/TN=$trace
			endif

			if(firstADC || !overlayChannels)
				ModifyGraph/W=$graph axisEnab($axis) = {ADYaxisLow, ADYaxisHigh}
				unit = StringFromList(i + NumberOfDAchannels, configNote)
				Label/W=$graph $axis, traceType + "\r(" + unit + ")"
				ModifyGraph/W=$graph lblPosMode = 1
				ModifyGraph/W=$graph standoff($axis) = 0, freePos($axis) = 0
				firstADC = 0
			endif

			headstage = WaveExists(statusADC) ? GetRowIndex(statusADC, str=adc) : NaN
			// use a different color if we can't query the headstage
			GetTraceColor(IsFinite(headstage) ? headstage : NUM_HEADSTAGES, red, green, blue)
			ModifyGraph/W=$graph rgb($trace)=(red, green, blue)
			ModifyGraph/W=$graph userData($trace)={channelType, 0, "AD"}
			ModifyGraph/W=$graph userData($trace)={channelNumber, 0, adc}
			ModifyGraph/W=$graph userData($trace)={sweepNumber, 0, num2str(sweepNo)}
		endif

		if(!overlayChannels)
			if(i >= NumberOfDAchannels)
				DAYaxisSpacing = 0
			endif

			if(i >= NumberOfADchannels)
				ADYaxisSpacing = 0
			endif

			if(displayDAC)
				DAYAxisHigh -= ADYaxisSpacing + DAYaxisSpacing
				DAYaxisLow  -= ADYaxisSpacing + DAYaxisSpacing
			endif

			ADYAxisHigh -= ADYaxisSpacing + DAYaxisSpacing
			ADYaxisLow  -= ADYaxisSpacing + DAYaxisSpacing
		endif
	endfor

	SetAxesRanges(graph, ranges)
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
/// graph has a date/time scale. Returns true if no traces have been found.
Function CheckIfXAxisIsTime(graph)
	string graph

	string list, trace, dataUnits

	list = TraceNameList(graph, ";", 0 + 1)

	// default is time axis
	if(isEmpty(list))
		return 1
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
Function EquallySpaceAxis(graph, axisBaseName)
	string graph, axisBaseName

	variable numAxes, axisInc, axisStart, axisEnd, i
	string axes, axis

	axes    = ListMatch(AxisList(graph), axisBaseName + "*")
	numAxes = ItemsInList(axes)

	if(numAxes == 0)
		return NaN
	endif

	axisInc = 1 / numAxes

	for(i = numAxes - 1; i >= 0; i -= 1)
		axis = StringFromList(i, axes)
		axisStart = GRAPH_DIV_SPACING + axisInc * i
		axisEnd   = (i == numAxes - 1 ? 1 : axisInc * (i + 1) - GRAPH_DIV_SPACING)
		ModifyGraph/W=$graph axisEnab($axis) = {axisStart, axisEnd}
	endfor
End

/// @brief Update the legend in the labnotebook graph
///
/// Passing traceList is required if you just added traces
/// to the graph as these can not be immediately queried using
/// `TraceNameList` as that would require an `DoUpdate` call before.
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
		str += "\\s(" + PossiblyQuoteName(StringFromList(i, traceList)) + ") " + num2str(i + 1)
		if(mod(i, 2))
			str += "\r"
		endif
	endfor

	str = RemoveEnding(str, "\r")
	TextBox/C/W=$graph/N=text0/F=2 str
End

/// @brief Add a trace to the labnotebook graph
///
/// @param graph name of the graph
/// @param settingsKey labnotebook numerical key wave
/// @param settingsHistory labnotebook numerical wave
/// @param key name of the key to add
Function AddTraceToLBGraph(graph, settingsKey, settingsHistory, key)
	string graph
	WAVE/T settingsKey
	WAVE settingsHistory
	string key

	string unit, lbl, axis, trace, panelTitle, device
	string traceList = ""
	variable sweepNo, i, numEntries, row, col
	variable red, green, blue, isTimeAxis, sweepCol

	if(GetKeyWaveParameterAndUnit(settingsKey, key, lbl, unit, col))
		return NaN
	endif

	lbl = LineBreakingIntoParWithMinWidth(lbl)

	WAVE settingsHistoryDat = GetSettingsHistoryDateTime(settingsHistory)
	isTimeAxis = CheckIfXAxisIsTime(graph)
	sweepCol   = GetSweepColumn(settingsHistory)

	axis = GetNextFreeAxisName(graph, AXIS_BASE_NAME)

	numEntries = DimSize(settingsHistory, LAYERS)
	for(i = 0; i < numEntries; i += 1)

		trace = CleanupName(lbl + " (" + num2str(i + 1) + ")", 1) // +1 because the headstage number is 1-based
		traceList = AddListItem(trace, traceList, ";", inf)

		if(isTimeAxis)
			AppendToGraph/W=$graph/L=$axis settingsHistory[][col][i]/TN=$trace vs settingsHistoryDat
		else
			AppendToGraph/W=$graph/L=$axis settingsHistory[][col][i]/TN=$trace vs settingsHistory[][sweepCol][0]
		endif

		ModifyGraph/W=$graph userData($trace)={key, 0, key}

		GetTraceColor(i, red, green, blue)
		ModifyGraph/W=$graph rgb($trace)=(red, green, blue)
	endfor

	if(!isEmpty(unit))
		lbl += "\r(" + unit + ")"
	endif

	Label/W=$graph $axis lbl

	ModifyGraph/W=$graph lblPosMode = 1, standoff($axis) = 0, freePos($axis) = 0
	ModifyGraph/W=$graph mode = 3
	ModifyGraph/W=$graph nticks(bottom) = 10

	SetLabNotebookBottomLabel(graph, isTimeAxis)
	EquallySpaceAxis(graph, AXIS_BASE_NAME)
	UpdateLBGraphLegend(graph, traceList=traceList)
End

/// @brief Switch the labnotebook graph x axis type (time <-> sweep numbers)
Function SwitchLBGraphXAxis(graph, settingsHistory)
	string graph
	WAVE settingsHistory

	string trace, dataUnits, list
	variable i, numEntries, isTimeAxis, sweepCol

	list = TraceNameList(graph, ";", 0 + 1)

	if(isEmpty(list))
		return NaN
	endif

	isTimeAxis = CheckIfXAxisIsTime(graph)
	sweepCol   = GetSweepColumn(settingsHistory)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		trace = StringFromList(i, list)

		// change from timestamps to sweepNums
		if(isTimeAxis)
			ReplaceWave/W=$graph/X trace=$trace, settingsHistory[][sweepCol][0]
		else // other direction
			Wave xWave = GetSettingsHistoryDateTime(settingsHistory)
			ReplaceWave/W=$graph/X trace=$trace, xWave
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
	variable zeroSweeps, keepOtherData
	string path, devicesWithData, activeDevices, device, expLoc, list, refNum
	string expName, substr

	if(mode == SAVE_AND_CLEAR)
		zeroSweeps    = 1
		keepOtherData = 0
	elseif(mode == SAVE_AND_SPLIT)
		zeroSweeps    = 0
		keepOtherData = 1
	else
		ASSERT(0, "Unknown mode")
	endif

	// We want never to loose data so we do the following:
	// Case 1: Unitled experiment
	// - Save with dialog without fileNameSuffix suffix
	// - Save with dialog with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// Case 2: Experiment with name
	// - Save without dialog
	// - Save with dialog with fileNameSuffix suffix
	// - Clear data
	// - Save without dialog
	//
	// User aborts in the save dialogs always results in a complete abort

	expName = GetExperimentName()

	if(!cmpstr(expName, UNTITLED_EXPERIMENT))
		ret = SaveExperimentWithDialog("", "_" + GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX)

		if(ret)
			return NaN
		endif

		// the user might have changed the experimet name in the dialog
		expName = GetExperimentName()
	else
		SaveExperiment
	endif

	if(mode == SAVE_AND_SPLIT)
		// Remove the following suffixes:
		// - sibling
		// - time stamp
		// - numerical suffixes added to prevent overwriting files
		expName  = RemoveEnding(expName, "_" + SIBLING_FILENAME_SUFFIX)
		expName  = RemoveEndingRegExp(expName, "_[[:digit:]]{4}_[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{6}") // example: 2015_03_25_213219
		expName  = RemoveEndingRegExp(expName, "_[[:digit:]]+") // example: _1, _123
		expName += SIBLING_FILENAME_SUFFIX
	elseif(mode == SAVE_AND_CLEAR)
		expName = "_" + GetTimeStamp()
	endif

	// saved experiments are stored in the symbolic path "home"
	expLoc  = "home"
	expName = UniqueFile(expLoc, expName, PACKED_FILE_EXPERIMENT_SUFFIX)

	ret = SaveExperimentWithDialog(expLoc, expName)

	if(ret)
		return NaN
	endif

	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE killFunc = KillOrMoveToTrash

	// remove sweep data from all devices with data
	devicesWithData = GetAllDevicesWithData()
	numDevices = ItemsInList(devicesWithData)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, devicesWithData)

		path = GetDeviceDataPathAsString(device)
		killFunc(path)

		if(windowExists(device) && zeroSweeps)
			SetSetVariable(device, "SetVar_Sweep", 0)
		endif
	endfor

	if(!keepOtherData)
		// remove labnotebook
		path = GetLabNotebookFolderAsString()
		killFunc(path)

		list = DAP_ListOfLockedDevs()
		CallFunctionForEachListItem(DAP_ClearCommentNotebook, list)

		// remove other waves from active devices
		activeDevices = GetAllActiveDevices()
		numDevices = ItemsInList(activeDevices)
		for(i = 0; i < numDevices; i += 1)
			device = StringFromList(i, activeDevices)

			DFREF dfr = GetDevicePath(device)
			list = GetListOfWaves(dfr, "ChanAmpAssign_Sweep_*", fullPath=1)
			CallFunctionForEachListItem(killFunc, list)

			DFREF dfr = GetDeviceTestPulse(device)
			list = GetListOfWaves(dfr, "TPStorage_*", fullPath=1)
			CallFunctionForEachListItem(killFunc, list)
		endfor
	endif

	SaveExperiment
End

/// @brief Return the maximum count of the given channel type
Function GetNumberFromChannelType(channelType)
	string channelType

	strswitch(channelType)
		case "AsyncAD":
			return NUM_ASYNC_CHANNELS
			break
		case "DA":
		case "TTL":
			return NUM_DA_TTL_CHANNELS
			break
		case "DataAcq_HS":
			return NUM_HEADSTAGES
			break
		case "AD":
			return NUM_AD_CHANNELS
			break
		default:
			ASSERT(0, "invalid type")
			break
	endswitch
End

#if defined(DEBUGGING_ENABLED)

/// @brief Execute a given ITC XOP operation
///
/// Includes debug output.
///
/// @return 0 if sucessfull, 1 on error
Function ExecuteITCOperation(cmd)
	string &cmd

	string msg

	sprintf msg, "Executing ITC command for %s: \"%s\"", GetRTStackInfo(2), cmd
	DEBUGPRINT("", str=msg)
	Execute cmd

	NVAR ITCError, ITCXOPError
	sprintf msg, "ITCError=%#X, ITCXOPError=%#X", ITCError, ITCXOPError
	DEBUGPRINT("Result:", str=msg)

	return ITCError != 0 || ITCXOPError != 0
End

#else

/// @brief Execute a given ITC XOP operation
///
/// @return 0 if sucessfull, 1 on error
Function ExecuteITCOperation(cmd)
	string &cmd

	Execute cmd

	NVAR ITCError, ITCXOPError
	return ITCError != 0 || ITCXOPError != 0
End

#endif

/// @brief Append the MIES version to the wave's note
Function AppendMiesVersionToWaveNote(wv)
	Wave wv

	SVAR miesVersion = $GetMiesVersion()
	Note wv, "MiesVersion: " + miesVersion
End

/// @brief Extract an one dimensional wave with channel data from the ITC sweep wave
///
/// @param config        ITC configuration wave
/// @param sweep         ITC sweep wave
/// @param channelType   channel type, one item of #ITC_CHANNEL_NAMES
/// @param channelNumber 0-based index of the channel
///
/// @returns a reference to a free wave with the single channel data
Function/Wave ExtractOneDimDataFromSweep(config, sweep, channelType, channelNumber)
	Wave config, sweep
	string channelType
	variable channelNumber

	variable numRows, i
	string channelUnit

	ASSERT(IsFinite(channelNumber), "Non-finite channel number")
	ASSERT(WhichListItem(channelType, ITC_CHANNEL_NAMES) != -1, "Unknown channel type")

	numRows = DimSize(config, ROWS)
	for(i = 0; i < numRows; i += 1)

		if(cmpstr(channelType, StringFromList(config[i][0], ITC_CHANNEL_NAMES)))
			continue
		endif

		if(channelNumber != config[i][1])
			continue
		endif

		MatrixOP/FREE data = col(sweep, i)

		SetScale/P x, DimOffset(sweep, ROWS), DimDelta(sweep, ROWS), WaveUnits(sweep, ROWS), data
		channelUnit = StringFromList(i, note(config))
		SetScale d, 0, 0, channelUnit, data

		return data
	endfor

	ASSERT(0, "Could not find the given channelType and/or channelNumber")
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

	traceList = GetAllSweepTraces(graph)

	if(!pps.timeAlignment)
		// switch all waves back to their backup so
		// that we have a clean start again
		numTraces = ItemsInList(traceList)
		for(i = 0; i < numTraces; i += 1)
			trace = StringFromList(i, traceList)
			WAVE wv = TraceNameToWaveRef(graph, trace)
			ReplaceWaveWithBackup(wv, nonExistingBackupIsFatal=0)
			Note/K wv
		endfor
	endif

	SVAR miesVersion = $GetMiesVersion()

	numTraces = ItemsInList(traceList)
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)

		WAVE wv = TraceNameToWaveRef(graph, trace)
		Note/K wv
		AddEntryIntoWaveNoteAsList(wv, "MiesVersion", str=miesVersion)
	endfor

	ZeroTracesIfReq(graph, traceList, pps.zeroTraces)
	if(pps.timeAlignment)
		TimeAlignmentIfReq(graph, traceList, pps.timeAlignMode, pps.timeAlignRefTrace, pps.timeAlignLevel)
	endif
	AverageWavesFromSameYAxisIfReq(graph, traceList, pps.averageTraces, pps.averageDataFolder)

	RestoreCursor(graph, crsA)
	RestoreCursor(graph, crsB)

	pps.finalUpdateHook(graph)
End

/// @brief Return all traces with real data
Function/S GetAllSweepTraces(graph)
	string graph

	string traceList

	traceList = TraceNameList(graph, ";", 0+1)
	return ListMatch(traceList, "!average*")
End

/// @brief Average traces in the graph from the same y-axis and append them to the graph
///
/// @param graph             graph with traces create by #CreateTiledChannelGraph
/// @param traceList         all traces of the graph except suplimentary ones like the average trace
/// @param averagingEnabled  switch if averaging is enabled or not
/// @param averageDataFolder permanent datafolder where the average waves can be stored
static Function AverageWavesFromSameYAxisIfReq(graph, traceList, averagingEnabled, averageDataFolder)
	string graph
	string traceList
	variable averagingEnabled
	DFREF averageDataFolder

	string averageWaveName, listOfWaves, listOfWaves1D, listOfChannelTypes, listOfChannelNumbers
	string averageWaves = ""
	variable i, j, k, l, numAxes, numTraces, numWaves, ret
	variable red, green, blue
	string info, axis, trace, axList, baseName
	string channelType, channelNumber, fullPath, panel

	if(!averagingEnabled)
		listOfWaves = GetListOfWaves(averageDataFolder, "average.*", fullPath=1)
		numWaves = ItemsInList(listOfWaves)
		for(i = 0; i < numWaves; i += 1)
			WAVE wv = $StringFromList(i, listOfWaves)
			RemoveTracesFromGraph(graph, wv=wv)
		endfor
		CallFunctionForEachListItem(KillOrMoveToTrash, listOfWaves)
		RemoveEmptyDataFolder(averageDataFolder)
		return NaN
	endif

	axList = AxisList(graph)
	axList = RemoveFromList("bottom", axList)
	numAxes = ItemsInList(axList)
	numTraces = ItemsInList(traceList)
	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)
		listOfWaves          = ""
		listOfChannelTypes   = ""
		listOfChannelNumbers = ""
		for(j = 0; j < numTraces; j += 1)
			trace = StringFromList(j, traceList)
			info = TraceInfo(graph, trace, 0)
			if(!cmpstr(axis, StringByKey("YAXIS", info)))
				fullPath             = GetWavesDataFolder(TraceNameToWaveRef(graph, trace), 2)
				listOfWaves          = AddListItem(fullPath, listOfWaves, ";", Inf)
				channelType          = GetUserData(graph, trace, "channelType")
				listOfChannelTypes   = AddListItem(channelType, listOfChannelTypes, ";", Inf)
				channelNumber        = GetUserData(graph, trace, "channelNumber")
				listOfChannelNumbers = AddListItem(channelNumber, listOfChannelNumbers, ";", Inf)
			endif
		endfor

		numWaves = ItemsInList(listOfWaves)
		if(numWaves <= 1)
			continue
		endif

		if(WaveListHasSameWaveNames(listOfWaves, baseName))
			// add channel type suffix if they are all equal
			if(ItemsInList(ListMatch(listOfChannelTypes, channelType)) == ItemsInList(listOfChannelTypes))
				sprintf averageWaveName, "average_%s_%s", baseName, channelType
			else
				sprintf averageWaveName, "average_%s_%d", baseName, k
				k += 1
			endif
		elseif(StringMatch(axis, AXIS_BASE_NAME + "*"))
			averageWaveName = "average" + RemovePrefix(axis, startStr=AXIS_BASE_NAME)
		else
			sprintf averageWaveName, "average_%d", k
			k += 1
		endif

		if(WhichListItem(averageWaveName, averageWaves) != -1)
			averageWaveName = UniqueName(GetDataFolder(1, averageDataFolder) + averageWaveName, 1, 0)
		endif

		ASSERT(numWaves == ItemsInList(listOfChannelTypes) && numWaves == ItemsInList(listOfChannelNumbers), "Non matching list sizes")

		DFREF tmpDFR = GetUniqueTempPath()
		listOfWaves1D = ""
		for(l = 0; l < numWaves; l += 1)
			fullPath = StringFromList(l, listOfWaves)
			WAVE sweep = $fullPath
			if(DimSize(sweep, COLS) > 1) // unsplitted 2D-data
				WAVE config = GetConfigWave(sweep)

				channelType   = StringFromList(l, listOfChannelTypes)
				channelNumber = StringFromList(l, listOfChannelNumbers)

				WAVE singleChannel = ExtractOneDimDataFromSweep(config, sweep, channelType, str2num(channelNumber))
				MoveWave singleChannel, tmpDFR:$("data" + num2str(l))
				listOfWaves1D = AddListItem(GetWavesDataFolder(singleChannel, 2), listOfWaves1D, ";", Inf)
			else
				listOfWaves1D = AddListItem(fullPath, listOfWaves1D, ";", Inf)
			endif
		endfor

		/// @todo change to fWaveAverage as soon as IP 6.37 is released
		/// as this will solve the need for our own copy.
		ret = MIES_fWaveAverage(listOfWaves1D, "", 0, 0, GetDataFolder(1, averageDataFolder) + averageWaveName, "")
		ASSERT(ret != -1, "Wave averaging failed")
		WAVE/SDFR=averageDataFolder averageWave = $averageWaveName
		RemoveTracesFromGraph(graph, wv=averageWave)
		AppendToGraph/W=$graph/L=$axis averageWave

		averageWaves = AddListItem(averageWaveName, averageWaves, ";", Inf)

		GetTraceColor(NUM_HEADSTAGES + 1, red, green, blue)
		ModifyGraph/W=$graph rgb($averageWaveName)=(red, green, blue)

		AddEntryIntoWaveNoteAsList(averageWave, "SourceWavesForAverage", str=listOfWaves)
		KillDataFolder tmpDFR
	endfor
End

/// @brief Zero all given traces
static Function ZeroTracesIfReq(graph, traceList, zeroTraces)
	string graph
	variable zeroTraces
	string traceList

	string trace
	variable numTraces, i

	if(!zeroTraces)
		return NaN
	endif

	numTraces = ItemsInList(traceList)
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)

		WAVE wv = TraceNameToWaveRef(graph, trace)
		CreateBackupWave(wv)
		ZeroWave(wv)
		AddEntryIntoWaveNoteAsList(wv, "Zeroed", str="true")
	endfor
End

/// @brief Perform time alignment of features in the sweep traces
static Function TimeAlignmentIfReq(panel, traceList, mode, refTrace, level)
	string panel
	string traceList, refTrace
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

	numTraces = ItemsInList(traceList)
	MAKE/FREE/D/N=(numTraces) featurePos = NaN, sweepNumber = NaN
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)
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
		trace = StringFromList(i, traceList)
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
		AddEntryIntoWaveNoteAsList(wv, "TimeAlignmentTotalOffset", var=offset)
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
