#pragma rtGlobals=3

#include <Axis Utilities>

/// @file MIES_MiesUtilities.ipf
/// @brief This file holds utility functions which need to know about MIES internals.

static StrConstant LABNOTEBOOK_BOTTOM_AXIS_TIME  = "Timestamp (a. u.)"
static StrConstant LABNOTEBOOK_BOTTOM_AXIS_SWEEP = "Sweep Number (a. u.)"

static Constant GRAPH_DIV_SPACING   = 0.03
static Constant ADC_SLOT_MULTIPLIER = 4
static Constant NUM_CHANNEL_TYPES   = 3

/// @brief Extracts the date/time column of the numericalValues wave
///
/// This is useful if you want to plot values against the time and let
/// Igor do the formatting of the date/time values
Function/WAVE GetLBNumericalValuesDat(numericalValues)
	WAVE numericalValues

	DFREF dfr = GetWavesDataFolderDFR(numericalValues)
	WAVE/Z/SDFR=dfr numericalValuesDat
	variable nextRowIndex = GetNumberFromWaveNote(numericalValues, NOTE_INDEX)

	if(!WaveExists(numericalValuesDat) || DimSize(numericalValuesDat, ROWS) != DimSize(numericalValues, ROWS) || DimSize(numericalValuesDat, ROWS) < nextRowIndex || (nextRowIndex > 0 && !IsFinite(numericalValuesDat[nextRowIndex - 1])))
		Duplicate/O/R=[0, DimSize(numericalValues, ROWS)][1][-1][-1] numericalValues, dfr:numericalValuesDat/Wave=numericalValuesDat
		// we want to have a pure 1D wave without any columns or layers, this is currently not possible with Duplicate
		Redimension/N=-1 numericalValuesDat
		// redimension has the odd behaviour to change a wave with zero rows to one with 1 row and then initializes that point to zero
		// we need to fix that
		if(DimSize(numericalValuesDat, ROWS) == 1)
			numericalValuesDat = NaN
		endif
		SetScale d, 0, 0, "dat" numericalValuesDat
		SetDimLabel ROWS, -1, TimeStamp, numericalValuesDat
	endif

	return numericalValuesDat
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
/// @todo change to return a 0/1 wave with constant size a la DC_ControlStatusWave
///
/// @param config       ITCChanConfigWave as passed to the ITC XOP
/// @param channelType  DA/AD/TTL constants, see @ref ChannelTypeAndControlConstants
static Function/WAVE GetChanneListFromITCConfig(config, channelType)
	WAVE config
	variable channelType

	variable numRows, numCols, itcChan, i, j

	numRows = DimSize(config, ROWS)
	numCols = DimSize(config, COLS)

	ASSERT(numRows > 0, "Can not handle wave with zero rows")
	ASSERT(numCols == 4, "Expected a wave with 4 columns")

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
	else
		ASSERT(0, "Invalid controlType")
	endif

	if(channelIndex == CHANNEL_INDEX_ALL)
		ctrl += "_All"
	else
		ASSERT(channelIndex >= 0 && channelIndex < 100, "invalid channelIndex")
		sprintf ctrl, "%s_%02d", ctrl, channelIndex
	endif

	return ctrl
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

/// @brief Return a headstage independent setting from the numerical labnotebook
///
/// @return the headstage independent setting or `defValue`
Function GetLastSettingIndep(numericalValues, sweepNo, setting, [defValue])
	Wave numericalValues
	variable sweepNo
	string setting
	variable defValue

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, setting)

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
Function/S GetLastSettingTextIndep(textualValues, sweepNo, setting, [defValue])
	Wave/T textualValues
	variable sweepNo
	string setting, defValue

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	WAVE/T/Z settings = GetLastSettingText(textualValues, sweepNo, setting)

	if(WaveExists(settings))
		return settings[GetIndexForHeadstageIndepData(textualValues)]
	else
		DEBUGPRINT("Missing setting in labnotebook", str=setting)
		return defValue
	endif
End

/// @brief Returns a wave with the latest value of a setting from the history wave
/// for a given sweep number.
///
/// @return a free wave with #LABNOTEBOOK_LAYER_COUNT rows. In case
/// the setting could not be found an invalid wave reference is returned.
Function/WAVE GetLastSetting(numericalValues, sweepNo, setting)
	Wave numericalValues
	variable sweepNo
	string setting

	variable settingCol, numLayers, i, sweepCol, numEntries
	variable first, last

	ASSERT(WaveType(numericalValues), "Can only work with numeric waves")
	numLayers = DimSize(numericalValues, LAYERS)
	settingCol = FindDimLabel(numericalValues, COLS, setting)

	if(settingCol <= 0)
		DEBUGPRINT("Could not find the setting", str=setting)
		return $""
	endif

	sweepCol = GetSweepColumn(numericalValues)
	FindRange(numericalValues, sweepCol, sweepNo, 0, first, last)

	if(!IsFinite(first) && !IsFinite(last)) // sweep number is unknown
		return $""
	endif

	Make/FREE/N=(numLayers) status

	for(i = last; i >= first; i -= 1)

		status[] = numericalValues[i][settingCol][p]
		WaveStats/Q/M=1 status

		// return if at least one entry is not NaN
		if(V_numNaNs != numLayers)
			return status
		endif
	endfor
	
	return $""
End

/// @brief Returns a wave with latest value of a setting from the textualValues wave
/// for a given sweep number.
///
/// Text wave version of GetLastSetting().
///
/// @return a free wave with #LABNOTEBOOK_LAYER_COUNT rows. In case
/// the setting could not be found an invalid wave reference is returned.
Function/WAVE GetLastSettingText(textualValues, sweepNo, setting)
	Wave/T textualValues
	variable sweepNo
	string setting

	variable settingCol, numLayers, i, sweepCol
	variable first, last

	ASSERT(!WaveType(textualValues), "Can only work with text waves")
	numLayers = DimSize(textualValues, LAYERS)
	settingCol = FindDimLabel(textualValues, COLS, setting)

	if(settingCol <= 0)
		DEBUGPRINT("Could not find the setting", str=setting)
		return $""
	endif

	sweepCol = GetSweepColumn(textualValues)
	FindRange(textualValues, sweepCol, sweepNo, 0, first, last)

	if(!IsFinite(first) && !IsFinite(last)) // sweep number is unknown
		return $""
	endif

	Make/FREE/N=(numLayers)/T status
	Make/FREE/N=(numLayers) lengths

	for(i = last; i >= first; i -= 1)

		status[] = textualValues[i][settingCol][p]
		lengths[] = strlen(status[p])

		// return if we have at least one non-empty entry
		if(Sum(lengths) > 0)
			return status
		endif
	endfor

	return $""
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
Function/WAVE GetLastSweepWithSetting(numericalValues, setting, sweepNo)
	WAVE numericalValues
	string setting
	variable &sweepNo

	variable idx

	sweepNo = NaN
	ASSERT(WaveType(numericalValues), "Can only work with numeric waves")

	WAVE/Z indizes = FindIndizes(wv=numericalValues, colLabel=setting, prop=PROP_NON_EMPTY)
	if(!WaveExists(indizes))
		return $""
	endif

	idx = indizes[DimSize(indizes, ROWS) - 1]
	Make/FREE/N=(DimSize(numericalValues, LAYERS)) data = numericalValues[idx][%$setting][p]
	sweepNo = numericalValues[idx][GetSweepColumn(numericalValues)][0]

	return data
End

/// @brief Return the last textual value of a setting from the labnotebook
///        and the sweep it was set.
///
/// @param[in]  numericalValues  numerical labnotebook
/// @param[in]  setting  name of the value to search
/// @param[out] sweepNo  sweep number the value was last set
///
/// @return a free wave with #LABNOTEBOOK_LAYER_COUNT rows. In case
/// the setting could not be found an invalid wave reference is returned.
Function/WAVE GetLastSweepWithSettingText(numericalValues, setting, sweepNo)
	WAVE/T numericalValues
	string setting
	variable &sweepNo

	variable idx

	sweepNo = NaN
	ASSERT(!WaveType(numericalValues), "Can only work with text waves")

	WAVE/Z indizes = FindIndizes(wvText=numericalValues, colLabel=setting, prop=PROP_NON_EMPTY)
	if(!WaveExists(indizes))
		return $""
	endif

	idx = indizes[DimSize(indizes, ROWS) - 1]
	Make/FREE/T/N=(DimSize(numericalValues, LAYERS)) data = numericalValues[idx][%$setting][p]
	sweepNo = str2num(numericalValues[idx][GetSweepColumn(numericalValues)][0])

	return data
End

/// @brief Returns a list of all devices, e.g. "ITC18USB_Dev_0;", with an existing datafolder returned by `GetDevicePathAsString(device)`
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
Function GetSamplingInterval(config)
	Wave config

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

static Function RemoveDisabledChannels(channelSelWave, ADCs, DACs, configNote)
	WAVE/Z channelSelWave
	WAVE ADCs, DACs
	string &configNote

	variable numADCs, numDACs, i

	if(!WaveExists(channelSelWave))
		return NaN
	endif

	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)

	// start at the end of the config wave
	// we always have the order DA/AD/TTLs
	for(i = numADCs - 1; i >= 0; i -= 1)
		if(!channelSelWave[ADCs[i]][%AD])
			DeletePoints/M=(ROWS) i, 1, ADCs
			configNote = RemoveListItem(numDACs + i, configNote)
		endif
	endfor

	for(i = numDACs - 1; i >= 0; i -= 1)
		if(!channelSelWave[DACs[i]][%DA])
			DeletePoints/M=(ROWS) i, 1, DACs
			configNote = RemoveListItem(i, configNote)
		endif
	endfor
End

/// @brief Create a vertically tiled graph for displaying AD and DA channels
///
/// Passing in sweepWave assumes the old format of the sweep data (all data in one wave as received by the ITC XOP)
/// Passing in sweepDFR assumes the new format of split waves, one wave for each AD, DA, TTL channel, with one dimension
///
/// @param graph                window
/// @param config               ITC config wave
/// @param sweepNo              number of the sweep
/// @param numericalValues      numerical labnotebook wave
/// @param textualValues        textual labnotebook wave
/// @param tgs                  settings for tuning the display, see @ref TiledGraphSettings
/// @param sweepDFR [optional]  datafolder with 1D waves extracted from the sweep wave
/// @param sweepWave [optional] sweep wave with multiple columns
/// @param channelSelWave [optional] channel selection wave
Function CreateTiledChannelGraph(graph, config, sweepNo, numericalValues,  textualValues, tgs, [sweepDFR, sweepWave, channelSelWave])
	string graph
	WAVE config
	variable sweepNo
	WAVE numericalValues
	WAVE/T textualValues
	STRUCT TiledGraphSettings &tgs
	DFREF sweepDFR
	WAVE/Z sweepWave
	WAVE/Z channelSelWave

	variable headstage, red, green, blue, splitSweepMode, axisIndex, numChannels
	variable numDACs, numADCs, numTTLs, i, j, k, channelOffset, hasPhysUnit, slotMult
	variable moreData, low, high, step, spacePerSlot, chan, numSlots, numHorizWaves, numVertWaves, idx
	variable numTTLBits, colorIndex, totalVertBlocks
	variable delayOnsetUser, delayOnsetAuto, delayTermination, delaydDAQ, dDAQEnabled
	variable stimSetLength, samplingInt, xRangeStart, xRangeEnd, left
	variable numDACsOriginal, numADCsOriginal, numTTLsOriginal

	string trace, traceType, channelID, axisLabel, existingLabel
	string unit, configNote, name, wvName, str, vertAxis

	ASSERT(!isEmpty(graph), "Empty graph")
	ASSERT(IsFinite(sweepNo), "Non-finite sweepNo")
	ASSERT(ParamIsDefault(sweepDFR) + ParamIsDefault(sweepWave), "Caller must supply exactly one of sweepDFR and sweepWave")

	WAVE ADCs = GetADCListFromConfig(config)
	WAVE DACs = GetDACListFromConfig(config)
	WAVE TTLs = GetTTLListFromConfig(config)
	configNote = note(config)

	Duplicate/FREE ADCs, ADCsOriginal
	Duplicate/FREE DACs, DACsOriginal
	Duplicate/FREE TTLs, TTLsOriginal
	numDACsOriginal = DimSize(DACs, ROWS)
	numADCsOriginal = DimSize(ADCs, ROWS)
	numTTLsOriginal = DimSize(TTLs, ROWS)

	RemoveDisabledChannels(channelSelWave, ADCs, DACs, configNote)
	numDACs = DimSize(DACs, ROWS)
	numADCs = DimSize(ADCs, ROWS)
	numTTLs = DimSize(TTLs, ROWS)

	if(!ParamIsDefault(sweepDFR))
		splitSweepMode = 1
	endif

	WAVE ranges = GetAxesRanges(graph)

	if(!tgs.overlaySweep)
		RemoveTracesFromGraph(graph)
	endif

	WAVE/Z ttlRackZeroChannel = GetLastSetting(numericalValues, sweepNo, "TTL rack zero bits")
	WAVE/Z ttlRackOneChannel  = GetLastSetting(numericalValues, sweepNo, "TTL rack one bits")

	if(tgs.splitTTLBits && numTTLs > 0)
		if(!WaveExists(ttlRackZeroChannel) && !WaveExists(ttlRackOneChannel))
			print "Turning off tgs.splitTTLBits as some labnotebook entries could not be found"
			tgs.splitTTLBits = 0
		elseif(!splitSweepMode)
			print "Turning off tgs.splitTTLBits as it is currently only supported for split sweep mode"
			tgs.splitTTLBits = 0
		elseif(tgs.overlayChannels)
			print "Turning off tgs.splitTTLBits as it is overriden by tgs.overlayChannels"
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

	dDAQEnabled = GetLastSettingIndep(numericalValues, sweepNo, "Distributed DAQ")

	if(tgs.dDAQDisplayMode && !dDAQEnabled)
		printf "Distributed DAQ display mode turned off as no dDAQ data could be found.\r"
	endif

	tgs.dDAQDisplayMode = tgs.dDAQDisplayMode && dDAQEnabled

	if(tgs.dDAQDisplayMode)
		stimSetLength = GetLastSettingIndep(numericalValues, sweepNo, "Stim set length")
		DEBUGPRINT("Stim set length (labnotebook)", var=stimSetLength)

		samplingInt = GetSamplingInterval(config) * 1e-3

		// dDAQ data taken with versions prior to
		// 125a5407 (DC_PlaceDataInITCDataWave: Document all other settings from the DAQ groupbox, 2015-11-26)
		// does not have the delays stored in the labnotebook
		delayOnsetUser   = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", defValue=0) / samplingInt
		delayOnsetAuto   = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", defValue=0) / samplingInt
		delayTermination = GetLastSettingIndep(numericalValues, sweepNo, "Delay termination", defValue=0) / samplingInt
		delaydDAQ        = GetLastSettingIndep(numericalValues, sweepNo, "Delay distributed DAQ", defValue=0) / samplingInt

		sprintf str, "delayOnsetUser=%g, delayOnsetAuto=%g, delayTermination=%g, delaydDAQ=%g", delayOnsetUser, delayOnsetAuto, delayTermination, delaydDAQ
		DEBUGPRINT(str)
	endif

	WAVE/Z statusDAC = GetLastSetting(numericalValues, sweepNo, "DAC")
	WAVE/Z statusADC = GetLastSetting(numericalValues, sweepNo, "ADC")

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
					channelOffset    = 0
					hasPhysUnit      = 1
					slotMult         = 1
					numHorizWaves    = tgs.dDAQDisplayMode ? numDACsOriginal : 1
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
					channelOffset    = numDACs
					hasPhysUnit      = 1
					slotMult         = ADC_SLOT_MULTIPLIER
					numHorizWaves    = tgs.dDAQDisplayMode ? numADCsOriginal : 1
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
					channelOffset    = numDACs + numADCs
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

			// number of vertically distributed
			// waves per channel type
			for(j = 0; j < numVertWaves; j += 1)

				if(!cmpstr(channelID, "TTL") && tgs.splitTTLBits)
					name   = channelID + num2str(chan) + "_" + num2str(j)
					wvName = channelID + "_" + num2str(chan) + "_" + num2str(j)
				else
					name   = channelID + num2str(chan)
					wvName = channelID + "_" + num2str(chan)
				endif

				if(splitSweepMode)
					WAVE/Z/SDFR=sweepDFR wv = $wvName
					if(!WaveExists(wv))
						continue
					endif
					idx = 0
				else
					idx = activeChanCount[i] + channelOffset
					WAVE wv = sweepWave
				endif

				if(!tgs.overlayChannels)
					axisIndex += 1
				endif

				// number of horizontally distributed
				// waves per channel type
				for(k = 0; k < numHorizWaves; k += 1)

					vertAxis = VERT_AXIS_BASE_NAME + num2str(j) + "_" + HORIZ_AXIS_BASE_NAME + num2str(k)

					if(tgs.overlayChannels)
						vertAxis   +=  "_" + channelID
						traceType   = channelID
					else
						vertAxis   += "_" + num2str(axisIndex)
						traceType   = name
					endif

					if(tgs.dDAQDisplayMode && channelTypes[i] != ITC_XOP_CHANNEL_TYPE_TTL) // TTL channels don't have dDAQ mode

						// fallback to manual calculation
						// for versions prior to 17b49b63 (DC_PlaceDataInITCDataWave: Document stim set length, 2016-05-12)
						if(!IsFinite(stimSetLength))
							stimSetLength = (DimSize(wv, ROWS) - (delayOnsetUser + delayOnsetAuto + delayTermination + delaydDAQ * (numADCs - 1))) /  numADCs
							DEBUGPRINT("Stim set length (manually calculated)", var=stimSetLength)
						endif

						xRangeStart = delayOnsetUser + delayOnsetAuto + k * (stimSetLength + delaydDAQ)
						xRangeEnd   = xRangeStart + stimSetLength
					else
						xRangeStart = NaN
						xRangeEnd   = NaN
					endif

					trace = UniqueTraceName(graph, name)

					sprintf str, "i=%d, j=%d, k=%d, vertAxis=%s, traceType=%s, name=%s", i, j, k, vertAxis, traceType, name
					DEBUGPRINT(str)

					if(!IsFinite(xRangeStart) && !IsFinite(XRangeEnd))
						AppendToGraph/W=$graph/L=$vertAxis wv[][idx]/TN=$trace
					else
						AppendToGraph/W=$graph/L=$vertAxis wv[xRangeStart, xRangeEnd][idx]/TN=$trace

						left  = 1/numHorizWaves * k

						if(left != 0.0)
							left += GRAPH_DIV_SPACING
						endif

						ModifyGraph/W=$graph freePos($vertAxis)={left,kwFraction}, axisOnTop($vertAxis) = 1
						sprintf str, "horiz axis offset=[%g], stimset=[%d, %d]", left, xRangeStart, xRangeEnd
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
							unit = StringFromList(idx, configNote)
						else
							unit = "a.u."
						endif

						axisLabel = traceType + "\r(" + unit + ")"

						existingLabel = AxisLabelText(graph, vertAxis, SuppressEscaping=1)
						// AxisLabelText's SuppressEscaping does only work for Igor commands
						// and not for standard escape sequences
						existingLabel = ReplaceString("\\r", existingLabel, "\r")

						if(!isEmpty(existingLabel) && cmpstr(existingLabel, axisLabel))
							axisLabel =  channelID + "?\r(a. u.)"
						endif

						Label/W=$graph $vertAxis, axisLabel
						ModifyGraph/W=$graph lblPosMode = 1, standoff($vertAxis) = 0, freePos($vertAxis) = 0
					else
						Label/W=$graph $vertAxis, "\\u#2"
					endif

					// Color scheme:
					// 0-7:   Different headstages
					// 8:     Unknown headstage
					// 9:     Averaged trace
					// 10:    TTL bits (sum) rack zero
					// 11-14: TTL bits (single) rack zero
					// 15:    TTL bits (sum) rack one
					// 16-19: TTL bits (single) rack one
					if(WaveExists(status))
						colorIndex = GetRowIndex(status, val=chan)
					elseif(!cmpstr(channelID, "TTL"))
						colorIndex = 10 + activeChanCount[i] * 5 + j
					else
						colorIndex = NUM_HEADSTAGES
					endif

					GetTraceColor(colorIndex, red, green, blue)
					ModifyGraph/W=$graph rgb($trace)=(red, green, blue)
					ModifyGraph/W=$graph userData($trace)={channelType, 0, channelID}
					ModifyGraph/W=$graph userData($trace)={channelNumber, 0, num2str(chan)}
					ModifyGraph/W=$graph userData($trace)={sweepNumber, 0, num2str(sweepNo)}

					sprintf str, "colorIndex=%d", colorIndex
					DEBUGPRINT(str)
				endfor

				if(!tgs.OverlayChannels || activeChanCount[i] == 0)
					high -= slotMult * spacePerSlot + GRAPH_DIV_SPACING
				endif
			endfor

			activeChanCount[i] += 1
		endfor
	while(moreData)

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
/// @param graph name of the graph
/// @param numericalKeys labnotebook numerical key wave
/// @param numericalValues labnotebook numerical wave
/// @param key name of the key to add
Function AddTraceToLBGraph(graph, numericalKeys, numericalValues, key)
	string graph
	WAVE/T numericalKeys
	WAVE numericalValues
	string key

	string unit, lbl, axis, trace, panelTitle, device
	string traceList = ""
	variable sweepNo, i, numEntries, row, col
	variable red, green, blue, isTimeAxis, sweepCol

	if(GetKeyWaveParameterAndUnit(numericalKeys, key, lbl, unit, col))
		return NaN
	endif

	lbl = LineBreakingIntoParWithMinWidth(lbl)

	WAVE numericalValuesDat = GetLBNumericalValuesDat(numericalValues)
	isTimeAxis = CheckIfXAxisIsTime(graph)
	sweepCol   = GetSweepColumn(numericalValues)

	axis = GetNextFreeAxisName(graph, VERT_AXIS_BASE_NAME)

	numEntries = DimSize(numericalValues, LAYERS)
	for(i = 0; i < numEntries; i += 1)

		trace = CleanupName(lbl + " (" + num2str(i + 1) + ")", 1) // +1 because the headstage number is 1-based
		traceList = AddListItem(trace, traceList, ";", inf)

		if(isTimeAxis)
			AppendToGraph/W=$graph/L=$axis numericalValues[][col][i]/TN=$trace vs numericalValuesDat
		else
			AppendToGraph/W=$graph/L=$axis numericalValues[][col][i]/TN=$trace vs numericalValues[][sweepCol][0]
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
	EquallySpaceAxis(graph, VERT_AXIS_BASE_NAME)
	UpdateLBGraphLegend(graph, traceList=traceList)
End

/// @brief Switch the labnotebook graph x axis type (time <-> sweep numbers)
Function SwitchLBGraphXAxis(graph, numericalValues)
	string graph
	WAVE numericalValues

	string trace, dataUnits, list
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

		// change from timestamps to sweepNums
		if(isTimeAxis)
			ReplaceWave/W=$graph/X trace=$trace, numericalValues[][sweepCol][0]
		else // other direction
			Wave xWave = GetLBNumericalValuesDat(numericalValues)
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
		ret = SaveExperimentWrapper("", "_" + GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX)

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

	ret = SaveExperimentWrapper(expLoc, expName)

	if(ret)
		return NaN
	endif

	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE killFunc = KillOrMoveToTrashPath

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

		list = GetListOfLockedDevices()
		// funcref definition as string
		// allows to reference the function if it does not exist
		CallFunctionForEachListItem($"DAP_ClearCommentNotebook", list)

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

	CloseNWBFile()
End

/// @brief Return the maximum count of the given type
Function GetNumberFromType([var, str])
	variable var
	string str

	ASSERT(ParamIsDefault(var) + ParamIsDefault(str) == 1, "Expected exactly one parameter")

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
	endif
End

/// @brief Report ITC/ITCXOP errors in a user friendly manner and abort
Function ReportAndAbortOnITCErrors()

	string cmd
	NVAR/Z ITCError, ITCXOPError
	ASSERT(NVAR_EXISTS(ITCError) && NVAR_EXISTS(ITCXOPError), "The global variables ITCError and ITCXOPError must exist in the CDF")

	// we only need the lower 32bits of the error
	ITCError = ITCError & 0x00000000ffffffff

	if(ITCError != 0)
		printf "The ITC XOP returned the following errors: ITCError=%#x, ITCXOPError=%#x\r", ITCError, ITCXOPError

		Make/I/O/N=1 errorCode   = 0
		Make/T/O/N=2 errorString = ""
		Execute "ITCGetLastError/Z=1 ErrorCode"
		sprintf cmd, "ITCGetErrorString/Z=1/X=3 %d, ErrorString", ErrorCode[0]
		Execute cmd

		print errorString[0]
		print errorString[1]
		print "Some hints you might want to try!"
		print "- Is the correct ITC device type selected?"
		print "- Is your ITC Device connected to a power socket?"
		print "- Is your ITC Device connected to your computer?"
		print "- Have you tried unlocking/locking the device already?"
		print "- Reseating all connections between the DAC and the computer has also helped in the past."
		Abort
	elseif(ITCXOPError != 0)
		printf "The ITC XOP returned the following errors: ITCError=%#x, ITCXOPError=%#x\r", ITCError, ITCXOPError
		printf "The ITC XOP was called incorrectly, please inform the MIES developers!\r"
		printf "Call stack: %s\r", GetRTStackInfo(3)
		Abort
	endif

	return 0
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
	// we only need the lower 32bits of the error
	ITCError = ITCError & 0x00000000ffffffff
	sprintf msg, "ITCError=%#x, ITCXOPError=%#x", ITCError, ITCXOPError
	DEBUGPRINT("Result:", str=msg)

	return ITCError != 0 || ITCXOPError != 0
End

/// @brief Execute a given ITC XOP operation and abort on error
///
/// Includes debug output.
Function ExecuteITCOperationAbortOnError(cmd)
	string &cmd

	string msg

	sprintf msg, "Executing ITC command for %s: \"%s\"", GetRTStackInfo(2), cmd
	DEBUGPRINT("", str=msg)
	Execute cmd

	NVAR ITCError, ITCXOPError
	// we only need the lower 32bits of the error
	ITCError = ITCError & 0x00000000ffffffff
	sprintf msg, "ITCError=%#x, ITCXOPError=%#x", ITCError, ITCXOPError
	DEBUGPRINT("Result:", str=msg)

	ReportAndAbortOnITCErrors()

	return 0
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

/// @brief Execute a given ITC XOP operation and abort on error
Function ExecuteITCOperationAbortOnError(cmd)
	string &cmd

	Execute cmd

	ReportAndAbortOnITCErrors()

	return 0
End

#endif

/// @brief Append the MIES version to the wave's note
Function AppendMiesVersionToWaveNote(wv)
	Wave wv

	SVAR miesVersion = $GetMiesVersion()
	Note wv, "MiesVersion: " + miesVersion
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

	ASSERT(column < DimSize(sweep, COLS), "The column is out of range")

	MatrixOP/FREE data = col(sweep, column)
	SetScale/P x, DimOffset(sweep, ROWS), DimDelta(sweep, ROWS), WaveUnits(sweep, ROWS), data
	SetScale d, 0, 0, StringFromList(column, note(config)), data

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

	traceList = GetAllSweepTraces(graph)

	if(!pps.timeAlignment)
		// switch all waves back to their backup so
		// that we have a clean start again
		numTraces = ItemsInList(traceList)
		for(i = 0; i < numTraces; i += 1)
			trace = StringFromList(i, traceList)
			WAVE wv = TraceNameToWaveRef(graph, trace)
			ReplaceWaveWithBackup(wv, nonExistingBackupIsFatal=0)
		endfor
	endif

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

	variable referenceTime
	string averageWaveName, listOfWaves, listOfWaves1D, listOfChannelTypes, listOfChannelNumbers
	string xRange, listOfXRanges
	string averageWaves = ""
	variable i, j, k, l, numAxes, numTraces, numWaves, ret
	variable red, green, blue, column, first, last
	string axis, trace, axList, baseName
	string channelType, channelNumber, fullPath, panel

	referenceTime = DEBUG_TIMER_START()

	if(!averagingEnabled)
		listOfWaves = GetListOfWaves(averageDataFolder, "average.*", fullPath=1)
		numWaves = ItemsInList(listOfWaves)
		for(i = 0; i < numWaves; i += 1)
			WAVE wv = $StringFromList(i, listOfWaves)
			RemoveTracesFromGraph(graph, wv=wv)
		endfor
		CallFunctionForEachListItem(KillOrMoveToTrashPath, listOfWaves)
		RemoveEmptyDataFolder(averageDataFolder)
		return NaN
	endif

	axList = AxisList(graph)
	axList = RemoveFromList("bottom", axList)
	numAxes = ItemsInList(axList)
	numTraces = ItemsInList(traceList)

	// precompute traceInfo data
	Make/FREE/T/N=(numTraces) allTraceInfo = TraceInfo(graph, StringFromList(p, traceList), 0)

	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)
		listOfWaves          = ""
		listOfChannelTypes   = ""
		listOfChannelNumbers = ""
		listOfXRanges        = ""
		for(j = 0; j < numTraces; j += 1)
			trace = StringFromList(j, traceList)
			if(!cmpstr(axis, StringByKey("YAXIS", allTraceInfo[j])))
				fullPath      = GetWavesDataFolder(TraceNameToWaveRef(graph, trace), 2)
				channelType   = GetUserData(graph, trace, "channelType")
				channelNumber = GetUserData(graph, trace, "channelNumber")
				xRange        = StringByKey("YRANGE", allTraceInfo[j])

				listOfWaves          = AddListItem(fullPath, listOfWaves, ";", Inf)
				listOfChannelTypes   = AddListItem(channelType, listOfChannelTypes, ";", Inf)
				listOfChannelNumbers = AddListItem(channelNumber, listOfChannelNumbers, ";", Inf)
				listOfXRanges        = AddListItem(xRange, listOfXRanges, "_", Inf)
			endif
		endfor

		numWaves = ItemsInList(listOfWaves)
		if(numWaves <= 1)
			continue
		endif

		/// @todo Use WaveStats/RMD once IP7 is mandatory
		WAVE ranges = ExtractFromSubrange(listOfXRanges, ROWS)
		MatrixOP/FREE rangeStart = col(ranges, 0)
		MatrixOP/FREE rangeStop  = col(ranges, 1)

		if(WaveMin(rangeStart) != -1 && WaveMin(rangeStop) != -1)
			first = WaveMin(rangeStart)
			last  = WaveMax(rangeStop)
		else
			first = NaN
			last  = Nan
		endif
		WaveClear rangeStart, rangeStop

		if(WaveListHasSameWaveNames(listOfWaves, baseName))
			// add channel type suffix if they are all equal
			if(ListHasOnlyOneUniqueEntry(listOfChannelTypes))
				sprintf averageWaveName, "average_%s_%s", baseName, channelType
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

		if(WhichListItem(averageWaveName, averageWaves) != -1)
			averageWaveName = UniqueWaveName(averageDataFolder,averageWaveName)
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

				column = AFH_GetITCDataColumn(config, str2num(channelNumber), WhichListItem(channelType, ITC_CHANNEL_NAMES))
				WAVE singleChannel = ExtractOneDimDataFromSweep(config, sweep, column)
				MoveWave singleChannel, tmpDFR:$("data" + num2str(l))
				listOfWaves1D = AddListItem(GetWavesDataFolder(singleChannel, 2), listOfWaves1D, ";", Inf)
			else
				listOfWaves1D = AddListItem(fullPath, listOfWaves1D, ";", Inf)
			endif
		endfor

		/// @todo for dDaQ mode we could cache the result of the first column
		/// @todo change to fWaveAverage as soon as IP 6.37 is released
		/// as this will solve the need for our own copy.
		ret = MIES_fWaveAverage(listOfWaves1D, "", 0, 0, GetDataFolder(1, averageDataFolder) + averageWaveName, "")
		ASSERT(ret != -1, "Wave averaging failed")

		WAVE/SDFR=averageDataFolder averageWave = $averageWaveName
		RemoveTracesFromGraph(graph, wv=averageWave)

		if(IsFinite(first) && IsFinite(last))
			AppendToGraph/Q/W=$graph/L=$axis averageWave[first, last]
		else
			AppendToGraph/Q/W=$graph/L=$axis averageWave
		endif

		averageWaves = AddListItem(averageWaveName, averageWaves, ";", Inf)

		GetTraceColor(NUM_HEADSTAGES + 1, red, green, blue)
		ModifyGraph/W=$graph rgb($averageWaveName)=(red, green, blue)

		AddEntryIntoWaveNoteAsList(averageWave, "SourceWavesForAverage", str=listOfWaves)
		KillOrMoveToTrash(dfr=tmpDFR)
	endfor

	DEBUGPRINT_ELAPSED(referenceTime)
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
		WAVE backup = CreateBackupWave(wv)
		ZeroWave(wv)
		Note wv, note(backup) + "\r"
		AddEntryIntoWaveNoteAsList(wv, "Zeroed", str="true", replaceEntry=1)
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
/// @param graph graph
/// @param ignoreAxesWithLevelCrossing [optional, defaults to false] ignore all vertical axis which
/// cross the given level in the visible range
/// @param level [optional, defaults to zero] level to be used for `ignoreAxesWithLevelCrossing=1`
Function EqualizeVerticalAxesRanges(graph, [ignoreAxesWithLevelCrossing, level])
	string graph
	variable ignoreAxesWithLevelCrossing
	variable level

	string axList, axis, traceList, trace, info
	variable i, j, numAxes, axisOrient, xRangeBegin, xRangeEnd, axisWithMaxYRange
	variable beginY, endY
	variable maxYRange, numTraces

	if(ParamIsDefault(ignoreAxesWithLevelCrossing))
		ignoreAxesWithLevelCrossing = 0
	else
		ignoreAxesWithLevelCrossing = !!ignoreAxesWithLevelCrossing
	endif

	if(ParamIsDefault(level))
		level = 0
	else
		ASSERT(ignoreAxesWithLevelCrossing, "Optional argument level makes only sense if ignoreAxesWithLevelCrossing is enabled")
	endif

	GetAxis/W=$graph/Q bottom
	ASSERT(!V_flag, "Axis bottom expected to be used in the graph")
	xRangeBegin = V_min
	xRangeEnd   = V_max

	traceList = GetAllSweepTraces(graph)
	numTraces = ItemsInList(traceList)
	axList = AxisList(graph)
	numAxes = ItemsInList(axList)

	Make/FREE/D/N=(numAxes, 2) YValues = NaN
	SetDimLabel COLS, 0, minimum, YValues
	SetDimLabel COLS, 1, maximum, YValues

	// collect the y ranges of the visible x range of all vertical axis
	// respecting ignoreAxesWithLevelCrossing
	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)

		axisOrient = GetAxisOrientation(graph, axis)
		if(axisOrient != AXIS_ORIENTATION_LEFT && axisOrient != AXIS_ORIENTATION_RIGHT)
			continue
		endif

		for(j = 0; j < numTraces; j += 1)
			trace = StringFromList(j, traceList)
			info = TraceInfo(graph, trace, 0)
			if(cmpstr(axis, StringByKey("YAXIS", info)))
				continue
			endif

			WAVE wv = TraceNameToWaveRef(graph, trace)

			if(ignoreAxesWithLevelCrossing)
				FindLevel/Q/R=(xRangeBegin, xRangeEnd) wv, level
				if(!V_flag)
					continue
				endif
			endif

			WaveStats/M=2/Q/R=(xRangeBegin, xRangeEnd) wv
			YValues[i][%minimum] = V_min
			YValues[i][%maximum] = V_max
			if(abs(V_max - V_min) > maxYRange)
				maxYRange = abs(V_max - V_min)
				axisWithMaxYRange = i
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
		endY   = YValues[i][%minimum] + maxYRange
		DebugPrint("Setting new axis ranges for:", str=axis)
		DebugPrint("beginY:", var=beginY)
		DebugPrint("endY:", var=endY)

		SetAxis/W=$graph $axis, beginY, endY
	endfor
End

/// @brief Extract the sweep number from a `Sweep_*` or `Config_Sweep_*` wave
Function ExtractSweepNumber(sweepOrConfig)
	string sweepOrConfig

	return str2num(StringFromList(ItemsInList(sweepOrConfig, "_") - 1, sweepOrConfig, "_"))
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

/// @brief Return the stimset parameter folder from the numeric channelType, #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
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

	WAVE/Z ttlRackZeroChannel = GetLastSetting(numericalValues, sweep, "TTL rack zero channel")
	WAVE/Z ttlRackOneChannel  = GetLastSetting(numericalValues, sweep, "TTL rack one channel")

	if(WaveExists(ttlRackZeroChannel) && ttlRackZeroChannel[index] == channel)
		WAVE ttlBits = GetLastSetting(numericalValues, sweep, "TTL rack zero bits")
	elseif(WaveExists(ttlRackOneChannel) && ttlRackOneChannel[index] == channel)
		WAVE ttlBits = GetLastSetting(numericalValues, sweep, "TTL rack one bits")
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

	WAVE/Z ttlRackZeroChannel = GetLastSetting(numericalValues, sweep, "TTL rack zero channel")
	WAVE/Z ttlRackOneChannel  = GetLastSetting(numericalValues, sweep, "TTL rack one channel")

	if(WaveExists(ttlRackZeroChannel) && ttlRackZeroChannel[index] == channel)
		WAVE/T ttlStimsets = GetLastSettingText(textualValues, sweep, "TTL rack zero stim sets")
	elseif(WaveExists(ttlRackOneChannel) && ttlRackOneChannel[index] == channel)
		WAVE/T ttlStimsets = GetLastSettingText(textualValues, sweep, "TTL rack one stim sets")
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
		if(FindListItem(item, listInternal) == -1)
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

/// @brief Returns the mode of all setVars in the DA_Ephys panel of a controlType
Function/Wave GetAllDAEphysSetVar(panelTitle, channelType, controlType)
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

	/// @todo merge all these waves into one and add flags for what currently is performed
	strswitch(task)
		case "TestPulseMD":
			WAVE/Z/SDFR=GetActITCDevicesTestPulseFolder() deviceIDList = ActiveDeviceList
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
		WAVE candidates = ConvertListOfWaves(GetListOfWaves(dfr, ".*", fullpath=1))
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

/// @brief Replace the wave wv with its backup. If possible the backup wave will be killed afterwards.
///
/// @param wv                       wave to replace by its backup
/// @param nonExistingBackupIsFatal [optional, defaults to true] behaviour for the case that there is no backup. Passing a non-zero value
///                                 will abort if the backup wave does not exist, for zero it will just do nothing.
/// @returns one if the original wave was successfully replaced, zero otherwise.
Function ReplaceWaveWithBackup(wv, [nonExistingBackupIsFatal])
	Wave wv
	variable nonExistingBackupIsFatal

	string backupname
	dfref dfr

	if(ParamIsDefault(nonExistingBackupIsFatal))
		nonExistingBackupIsFatal = 1
	endif

	ASSERT(WaveExists(wv), "Found no original wave")

	backupname = NameOfWave(wv) + WAVE_BACKUP_SUFFIX
	dfr        = GetWavesDataFolderDFR(wv)

	Wave/Z/SDFR=dfr backup = $backupname

	if(!WaveExists(backup))
		if(nonExistingBackupIsFatal)
			Abort "Backup wave does not exist"
		endif
		return 0
	endif

	Duplicate/O backup, wv
	KillOrMoveToTrash(wv=backup)
	return 1
End

/// @brief Returns 1 if the user cancelled, zero if SaveExperiment was called
///
/// It is currently not possible to check if SaveExperiment was successfull
/// (E-Mail from Howard Rodstein WaveMetrics, 30 Jan 2015)
Function SaveExperimentWrapper(path, filename)
	string path, filename

	variable refNum
	NVAR interactiveMode = $GetInteractiveMode()

	if(interactiveMode)
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
		endif
		Open/Z/P=$path refNum as filename

		if(V_flag != 0)
			return 1
		endif

		Close refNum
	endif

	SaveExperiment as S_fileName
	return 0
End

#if (IgorVersion() >= 7.0)

/// @brief Detects duplicate values in a 1d wave.
///
/// @return one if duplicates could be found, zero otherwise
Function SearchForDuplicates(wv)
	WAVE wv

	variable sucess

	FindDuplicates/INDX=idx wv

	sucess = DimSize(idx, ROWS) > 0
	KillOrMoveToTrash(wv=idx)

	return sucess
End

#else

/// @brief Detects duplicate values in a 1d wave.
///
/// @return one if duplicates could be found, zero otherwise
Function SearchForDuplicates(wv)
	WAVE wv

	switch(WaveType(wv, 1))
		case 1:
			return SearchForDuplicatesNumeric(wv)
			break
		case 2:
			return SearchForDuplicatesText(wv)
			break
		default:
			ASSERT(0, "Can not work with this wave type")
	endswitch
End

/// @brief Detects duplicate values in a 1d numeric wave
///
/// @return one if duplicates could be found, zero otherwise
static Function SearchForDuplicatesNumeric(Wv)
	WAVE Wv
	ASSERT(WaveType(wv), "Expected numeric wave")
	ASSERT(dimsize(Wv,1) <= 1, (nameofwave(Wv) + " is not a 1D wave")) // make sure wave passed in is 1d
	ASSERT(dimSize(Wv,0) >= 2, (nameofwave(Wv) + " has less than two rows")) // make sure wave has at least two rows.

	Duplicate/FREE Wv WvCopyOne WvCopyTwo // make two copies. One to store duplicate search results, the other to sort and search for duplicates.
	variable Rows = dimSize(Wv,0) // create a variable so dimSize is only called once instead of twice.
	WvCopyOne[Rows- 1] = 0 // Set last point to 0 because if it by chance was 1, it would come up as a duplicate, even when the penultimate value in Wv was not 1
	Sort WvCopyTwo, WvCopyTwo // sort so that duplicates will be in adjacent rows
	WvCopyOne[0, Rows - 2] = WvCopyTwo[p] != WvCopyTwo[p + 1] ? 0 : 1 // could multithread but, MIES use case will be with short 1d waves.
	FindValue/V=1 WvCopyOne
	return V_value != -1
End

/// @brief Detects duplicate values in a 1d text wave
///
/// @return one if duplicates could be found, zero otherwise
static Function SearchForDuplicatesText(Wv)
	WAVE Wv

	ASSERT(WaveType(wv, 1) == 2, "Expected text wave")
	ASSERT(dimsize(Wv,1) <= 1, (nameofwave(Wv) + " is not a 1D wave")) // make sure wave passed in is 1d
	ASSERT(dimSize(Wv,0) >= 2, (nameofwave(Wv) + " has less than two rows")) // make sure wave has at least two rows.

	Duplicate/FREE/T Wv, WvCopyTwo
	variable Rows = dimSize(Wv,0) // create a variable so dimSize is only called once instead of twice.
	Make/FREE/N=(rows) hits = 0

	Sort WvCopyTwo, WvCopyTwo // sort so that duplicates will be in adjacent rows
	hits[0, Rows - 2] = !cmpstr(WvCopyTwo[p], WvCopyTwo[p + 1])
	FindValue/V=1 hits
	return V_value != -1
End

#endif

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

	SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)

	return DeviceCanLead(panelTitle) && ItemsInList(listOfFollowerDevices) > 0
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
