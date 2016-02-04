#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_NeuroDataWithoutBorders.ipf
/// @brief __NWB__ Functions related to MIES data export into the NeuroDataWithoutBorders format
///
/// @todo
/// - use IPNWB#CHANNEL_TYPE_OTHER instead of -1 if possible

/// @brief Return the starting time, in seconds since Igor Pro epoch in UTC, of the given sweep
static Function NWB_GetStartTimeOfSweep(sweepWave)
	WAVE sweepWave

	variable startingTime

	ASSERT(!cmpstr(WaveUnits(sweepWave, ROWS), "ms"), "Expected ms as wave units")
	// last time the wave was modified (UTC)
	startingTime  = NumberByKeY("MODTIME", WaveInfo(sweepWave, 0)) - date2secs(-1, -1, -1)
	// we want the timestamp of the beginning of the measurement
	startingTime -= DimSize(sweepWave, ROWS) * DimDelta(sweepWave, ROWS) / 1000

	return startingTime
End

/// @brief Return the creation time, in seconds since Igor Pro epoch in UTC, of the oldest sweep wave for all devices
///
/// Return NaN if no sweeps could be found
static Function NWB_FirstStartTimeOfAllSweeps()

	string devicesWithData, panelTitle, list, name
	variable numEntries, numWaves, i, j
	variable oldest = Inf

	devicesWithData = GetAllDevicesWithData()

	if(isEmpty(devicesWithData))
		return NaN
	endif

	numEntries = ItemsInList(devicesWithData)
	for(i = 0; i < numEntries; i += 1)
		panelTitle = StringFromList(i, devicesWithData)

		DFREF dfr = GetDeviceDataPath(panelTitle)
		list = GetListOfWaves(dfr, DATA_SWEEP_REGEXP)
		numWaves = ItemsInList(list)
		for(j = 0; j < numWaves; j += 1)
			name = StringFromList(j, list)
			WAVE/SDFR=dfr sweepWave = $name

			oldest = min(oldest, NWB_GetStartTimeOfSweep(sweepWave))
		endfor
	endfor

	return oldest
End

/// @brief Return the HDF5 file identifier referring to an open NWB file
///        for export
///
/// Open one if it does not exist yet.
///
/// @param[in] overrideFilePath    [optional] file path for new files to override the internal
///                                generation algorithm
/// @param[out] createdNewNWBFile  [optional] a new NWB file was created (1) or an existing opened (0)
static Function NWB_GetFileForExport([overrideFilePath, createdNewNWBFile])
	string overrideFilePath
	variable &createdNewNWBFile

	string expName, fileName, filePath
	variable fileID, refNum, oldestData

	NVAR fileIDExport = $GetNWBFileIDExport()

	if(IPNWB#H5_IsFileOpen(fileIDExport))
		return fileIDExport
	endif

	NVAR sessionStartTimeReadBack = $GetSessionStartTimeReadBack()

	SVAR filePathExport = $GetNWBFilePathExport()
	filePath = filePathExport

	if(isEmpty(filePath)) // need to derive a new NWB filename
		expName = GetExperimentName()

		if(!ParamIsDefault(overrideFilePath))
			filePath = overrideFilePath
		elseif(!cmpstr(expName, UNTITLED_EXPERIMENT))
			fileName = "_" + GetTimeStamp() + ".nwb"
			Open/D/M="Save as NWB file"/F="NWB files (*.nwb):.nwb;" refNum as fileName

			if(isEmpty(S_fileName))
				return NaN
			endif
			filePath = S_fileName
		else
			PathInfo home
			filePath = S_path + expName + ".nwb"
		endif
	endif

	GetFileFolderInfo/Q/Z filePath
	if(!V_flag)
		HDF5OpenFile/Z fileID as filePath

		if(V_flag)
			HDf5DumpErrors/CLR=1
			HDF5DumpState
			ASSERT(0, "Could not open HDF5 file")
		endif

		sessionStartTimeReadBack = NWB_ReadSessionStartTime(fileID)
		ASSERT(IsFinite(sessionStartTimeReadBack), "Could not read session_start_time back from the NWB file")

		fileIDExport   = fileID
		filePathExport = filePath

		if(!ParamIsDefault(createdNewNWBFile))
			createdNewNWBFile = 0
		endif
	else // file does not exist
		HDF5CreateFile/Z fileID as filePath
		if(V_flag)
			// invalidate stored path and ID
			filePathExport = ""
			fileIDExport   = NaN
			DEBUGPRINT("Could not create HDF5 file")
			// and retry
			return NWB_GetFileForExport()
		endif

		STRUCT IPNWB#ToplevelInfo ti
		IPNWB#InitToplevelInfo(ti)

		NVAR sessionStartTime = $GetSessionStartTime()

		if(!IsFinite(sessionStartTime))
			sessionStartTime = DateTimeInUTC()
		endif

		oldestData = NWB_FirstStartTimeOfAllSweeps()

		// adjusting the session start time, as older sweeps than the
		// timestamp of the last device locking are to be exported
		// not adjusting it would result in negative starting times for the lastest sweep
		if(IsFinite(oldestData))
			ti.session_start_time = min(sessionStartTime, floor(oldestData))
		endif

		IPNWB#CreateCommonGroups(fileID, toplevelInfo=ti)
		IPNWB#CreateIntraCellularEphys(fileID)

		sessionStartTimeReadBack = NWB_ReadSessionStartTime(fileID)
		ASSERT(IsFinite(sessionStartTimeReadBack), "Could not read session_start_time back from the NWB file")

		fileIDExport   = fileID
		filePathExport = filePath

		if(!ParamIsDefault(createdNewNWBFile))
			createdNewNWBFile = 1
		endif
	endif

	DEBUGPRINT("fileIDExport", var=fileIDExport, format="%15d")
	DEBUGPRINT("filePathExport", str=filePathExport)

	return fileIDExport
End

static Function NWB_ReadSessionStartTime(fileID)
	variable fileID

	string str

	if(!IPNWB#H5_DatasetExists(fileID, "/session_start_time"))
		return NaN
	endif

	HDF5LoadData/O/Q/TYPE=2/Z fileID, "/session_start_time"

	if(V_flag)
		HDf5DumpErrors/CLR=1
		HDF5DumpState
		ASSERT(0, "Could not load the HDF5 dataset /session_start_time")
	endif

	ASSERT(ItemsInList(S_WaveNames) == 1, "Expected only one wave")
	WAVE/T wv = $StringFromList(0, S_WaveNames)
	ASSERT(WaveType(wv, 1) == 2, "Expected a dataset of type text")
	ASSERT(numpnts(wv) == 1, "Expected a wave with only one entry")

	str = wv[0]
	KillOrMoveToTrash(wv=wv)

	return ParseISO8601TimeStamp(str)
End

static Function/S NWB_GenerateDeviceDescription(panelTitle)
	string panelTitle

	string deviceType, deviceNumber, desc

	ASSERT(ParseDeviceString(panelTitle, deviceType, deviceNumber), "Could not parse panelTitle")

	sprintf desc, "Harvard Bioscience (formerly HEKA/Instrutech) Model: %s", deviceType

	return desc
End

static Function NWB_AddDeviceSpecificData(locationID, panelTitle, [chunkedLayout])
	variable locationID
	string panelTitle
	variable chunkedLayout

	variable groupID, i, numEntries, refTime
	string path, list, name, contents

	refTime = DEBUG_TIMER_START()

	chunkedLayout = ParamIsDefault(chunkedLayout) ? 0 : !!chunkedLayout

	IPNWB#AddDevice(locationID, panelTitle, NWB_GenerateDeviceDescription(panelTitle))

	WAVE settingsHistory           = GetNumDocWave(panelTitle)
	WAVE/T settingsHistoryKeys     = GetNumDocKeyWave(panelTitle)
	WAVE/T settingsHistoryText     = GetTextDocWave(panelTitle)
	WAVE/T settingsHistoryTextKeys = GetTextDocKeyWave(panelTitle)

	path = "/general/labnotebook/" + panelTitle
	IPNWB#H5_CreateGroupsRecursively(locationID, path, groupID=groupID)

	IPNWB#MarkAsCustomEntry(locationID, "/general/labnotebook")

	IPNWB#H5_WriteDataset(groupID, "numericalValues", wv=settingsHistory, writeIgorAttr=1, overwrite=1, chunkedLayout=chunkedLayout)
	IPNWB#H5_WriteTextDataset(groupID, "numericalKeys", wvText=settingsHistoryKeys, writeIgorAttr=1, overwrite=1, chunkedLayout=chunkedLayout)
	IPNWB#H5_WriteTextDataset(groupID, "textualValues", wvText=settingsHistoryText, writeIgorAttr=1, overwrite=1, chunkedLayout=chunkedLayout)
	IPNWB#H5_WriteTextDataset(groupID, "textualKeys", wvText=settingsHistoryTextKeys, writeIgorAttr=1, overwrite=1, chunkedLayout=chunkedLayout)

	HDF5CloseGroup/Z groupID
	DEBUGPRINT_ELAPSED(refTime)

	path = "/general/user_comment/" + panelTitle
	IPNWB#H5_CreateGroupsRecursively(locationID, path, groupID=groupID)

	IPNWB#MarkAsCustomEntry(locationID, "/general/user_comment")

	SVAR userComment = $GetUserComment(panelTitle)
	IPNWB#H5_WriteTextDataset(groupID, "userComment", str=userComment, overwrite=1, chunkedLayout=chunkedLayout)

	HDF5CloseGroup/Z groupID
	DEBUGPRINT_ELAPSED(refTime)

	path = "/general/testpulse/" + panelTitle
	IPNWB#H5_CreateGroupsRecursively(locationID, path, groupID=groupID)

	IPNWB#MarkAsCustomEntry(locationID, "/general/testpulse")

	DFREF dfr = GetDeviceTestPulse(panelTitle)
	list = GetListOfWaves(dfr, TP_STORAGE_REGEXP)
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		WAVE/SDFR=dfr wv = $name
		IPNWB#H5_WriteDataset(groupID, name, wv=wv, writeIgorAttr=1, overwrite=1, chunkedLayout=chunkedLayout)
	endfor

	HDF5CloseGroup/Z groupID
	DEBUGPRINT_ELAPSED(refTime)
End

Function NWB_ExportAllData([overrideFilePath])
	string overrideFilePath

	string devicesWithData, panelTitle, list, name
	variable i, j, numEntries, locationID, sweep, numWaves

	devicesWithData = GetAllDevicesWithData()

	if(isEmpty(devicesWithData))
		print "No devices with data found for NWB export"
		return NaN
	endif

	print "Please be patient while we export all existing data of all devices to NWB"

	if(!ParamIsDefault(overrideFilePath))
		locationID = NWB_GetFileForExport(overrideFilePath=overrideFilePath)
	else
		locationID = NWB_GetFileForExport()
	endif

	if(!IsFinite(locationID))
		return NaN
	endif

	NWB_AddMiesVersion(locationID)
	IPNWB#AddModificationTimeEntry(locationID)

	numEntries = ItemsInList(devicesWithData)
	for(i = 0; i < numEntries; i += 1)
		panelTitle = StringFromList(i, devicesWithData)
		NWB_AddDeviceSpecificData(locationID, panelTitle, chunkedLayout=1)

		DFREF dfr = GetDeviceDataPath(panelTitle)
		list = GetListOfWaves(dfr, DATA_SWEEP_REGEXP)
		numWaves = ItemsInList(list)
		for(j = 0; j < numWaves; j += 1)
			name = StringFromList(j, list)
			WAVE/SDFR=dfr sweepWave = $name
			WAVE configWave = GetConfigWave(sweepWave)
			sweep = ExtractSweepNumber(name)

			NWB_AppendSweepLowLevel(locationID, panelTitle, sweepWave, configWave, sweep, chunkedLayout=1)
		endfor
	endfor
End

static Function NWB_AddMiesVersion(locationID)
	variable locationID

	SVAR miesVersion = $GetMiesVersion()

	IPNWB#H5_WriteTextDataset(locationID, "/general/version", str=miesVersion, overwrite=1)
	IPNWB#MarkAsCustomEntry(locationID, "/general/version")
End

Function NWB_AppendSweep(panelTitle, ITCDataWave, ITCChanConfigWave, sweep)
	string panelTitle
	WAVE ITCDataWave, ITCChanConfigWave
	variable sweep

	variable locationID, createdNewNWBFile

	locationID = NWB_GetFileForExport(createdNewNWBFile=createdNewNWBFile)
	if(!IsFinite(locationID))
		return NaN
	endif

	if(createdNewNWBFile)
		NWB_ExportAllData()
	else
		NWB_AddMiesVersion(locationID)
		IPNWB#AddModificationTimeEntry(locationID)
		NWB_AddDeviceSpecificData(locationID, panelTitle)
		NWB_AppendSweepLowLevel(locationID, panelTitle, ITCDataWave, ITCChanConfigWave, sweep)
	endif
End

static Function NWB_AppendSweepLowLevel(locationID, panelTitle, ITCDataWave, ITCChanConfigWave, sweep, [chunkedLayout])
	variable locationID
	string panelTitle
	WAVE ITCDataWave, ITCChanConfigWave
	variable sweep, chunkedLayout

	variable groupID, numEntries, i, j, ttlBits, dac, adc, col, refTime
	string group, path, list, name
	string channelSuffix, listOfStimsets, contents

	refTime = DEBUG_TIMER_START()

	chunkedLayout = ParamIsDefault(chunkedLayout) ? 0 : !!chunkedLayout

	NVAR session_start_time = $GetSessionStartTimeReadBack()

	WAVE settingsHistory           = GetNumDocWave(panelTitle)
	WAVE/T settingsHistoryKeys     = GetNumDocKeyWave(panelTitle)
	WAVE/T settingsHistoryText     = GetTextDocWave(panelTitle)
	WAVE/T settingsHistoryTextKeys = GetTextDocKeyWave(panelTitle)

	WAVE clampMode   = GetLastSetting(settingsHistory, sweep, "Clamp Mode")
	WAVE statusHS    = GetLastSetting(settingsHistory, sweep, "Headstage Active")
	WAVE ADCs        = GetLastSetting(settingsHistory, sweep, "ADC")
	WAVE DACs        = GetLastSetting(settingsHistory, sweep, "DAC")
	WAVE/T stimSets  = GetLastSettingText(settingsHistoryText, sweep, STIM_WAVE_NAME_KEY)

	STRUCT IPNWB#WriteChannelParams params
	params.sweep = sweep

	params.device        = panelTitle
	params.channelSuffix = ""

	// starting time of the dataset, relative to the start of the session
	params.startingTime = NWB_GetStartTimeOfSweep(ITCDataWave) - session_start_time
	ASSERT(params.startingTime > 0, "TimeSeries starting time can not be negative")

	params.samplingRate = ConvertSamplingIntervalToRate(GetSamplingInterval(ITCChanConfigWave)) * 1000

	DEBUGPRINT_ELAPSED(refTime)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		STRUCT IPNWB#TimeSeriesProperties tsp

		sprintf contents, "Headstage %d", i
		IPNWB#AddElectrode(locationID, i, contents)

		adc                    = ADCs[i]
		dac                    = DACs[i]
		params.electrodeNumber = i
		params.clampMode       = clampMode[i]
		params.stimset         = stimSets[i]

		if(IsFinite(adc))
			params.channelNumber = ADCs[i]
			params.channelType   = ITC_XOP_CHANNEL_TYPE_ADC
			col                  = AFH_GetITCDataColumn(ITCChanConfigWave, params.channelNumber, params.channelType)
			WAVE params.data     = ExtractOneDimDataFromSweep(ITCChanConfigWave, ITCDataWave, col)
			NWB_GetTimeSeriesProperties(params, tsp)
			IPNWB#WriteSingleChannel(locationID, "/acquisition/timeseries", params, tsp, chunkedLayout=chunkedLayout)
		endif

		DEBUGPRINT_ELAPSED(refTime)

		if(IsFinite(dac))
			params.channelNumber = DACs[i]
			params.channelType   = ITC_XOP_CHANNEL_TYPE_DAC
			col                  = AFH_GetITCDataColumn(ITCChanConfigWave, params.channelNumber, params.channelType)
			WAVE params.data     = ExtractOneDimDataFromSweep(ITCChanConfigWave, ITCDataWave, col)
			NWB_GetTimeSeriesProperties(params, tsp)
			IPNWB#WriteSingleChannel(locationID, "/stimulus/presentation", params, tsp, chunkedLayout=chunkedLayout)
		endif

		DEBUGPRINT_ELAPSED(refTime)

		params.stimSet = stimSets[i]
		NWB_WriteStimsetTemplateWaves(locationID, params, chunkedLayout)
	endfor

	DEBUGPRINT_ELAPSED(refTime)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		ttlBits = GetTTLBits(settingsHistory, sweep, i)
		if(!IsFinite(ttlBits))
			continue
		endif

		listOfStimsets = GetTTLstimSets(settingsHistory, settingsHistoryText, sweep, i)

		params.clampMode     = NaN
		params.channelNumber = i
		params.channelType   = ITC_XOP_CHANNEL_TYPE_TTL
		col                  = AFH_GetITCDataColumn(ITCChanConfigWave, params.channelNumber, params.channelType)

		WAVE data = ExtractOneDimDataFromSweep(ITCChanConfigWave, ITCDataWave, col)
		DFREF dfr = NewFreeDataFolder()
		SplitTTLWaveIntoComponents(data, ttlBits, dfr, "_")

		list = GetListOfWaves(dfr, ".*")
		numEntries = ItemsInList(list)
		for(j = 0; j < numEntries; j += 1)
			name = StringFromList(j, list)
			WAVE/SDFR=dfr params.data = $name
			params.channelSuffix = name
			params.stimset       = StringFromList(str2num(name[1,inf]), listOfStimsets)
			NWB_GetTimeSeriesProperties(params, tsp)
			IPNWB#WriteSingleChannel(locationID, "/stimulus/presentation", params, tsp, chunkedLayout=chunkedLayout)
		endfor

		numEntries = ItemsInList(listOfStimsets)
		for(j = 0; j < numEntries; j += 1)
			name = StringFromList(j, listOfStimsets)

			// work around empty TTL stim set bug in labnotebook
			if(isEmpty(name))
				continue
			endif

			params.stimSet = name
			NWB_WriteStimsetTemplateWaves(locationID, params, chunkedLayout)
		endfor
	endfor

	DEBUGPRINT_ELAPSED(refTime)
End

static Function NWB_WriteStimsetTemplateWaves(locationID, params, chunkedLayout)
	variable locationID
	STRUCT IPNWB#WriteChannelParams &params
	variable chunkedLayout

	STRUCT IPNWB#TimeSeriesProperties tsp
	string stimSet, path

	stimSet = params.stimSet

	params.channelNumber = NaN
	params.channelType   = -1
	WAVE params.data     = WB_CreateAndGetStimset(stimSet)
	NWB_GetTimeSeriesProperties(params, tsp)
	path = "/stimulus/templates"
	IPNWB#WriteSingleChannel(locationID, path, params, tsp, chunkedLayout=chunkedLayout)

	// write also the stim set parameter waves if all three exist
	WAVE/Z WP  = WB_GetWaveParamForSet(stimSet)
	WAVE/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimSet)

	if(!WaveExists(WP) && !WaveExists(WPT) && !WaveExists(SegWvType))
		// don't need to write the stimset parameter waves
		return NaN
	endif

	ASSERT(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType) , "Some stim set parameter waves are missing")

	params.stimSet = stimSet + "_WP"
	WAVE params.data = WP
	IPNWB#WriteSingleChannel(locationID, path, params, tsp, chunkedLayout=chunkedLayout)

	params.stimSet = stimSet + "_WPT"
	WAVE params.data = WPT
	IPNWB#WriteSingleChannel(locationID, path, params, tsp, chunkedLayout=chunkedLayout)

	params.stimSet = stimSet + "_SegWvType"
	WAVE params.data = SegWvType
	IPNWB#WriteSingleChannel(locationID, path, params, tsp, chunkedLayout=chunkedLayout)
End

static Function NWB_GetTimeSeriesProperties(p, tsp)
	STRUCT IPNWB#WriteChannelParams &p
	STRUCT IPNWB#TimeSeriesProperties &tsp

	WAVE settingsHistory = GetNumDocWave(p.device)

	IPNWB#InitTimeSeriesProperties(tsp, p.channelType, p.clampMode)

	if(p.channelType == ITC_XOP_CHANNEL_TYPE_ADC)
		if(p.clampMode == V_CLAMP_MODE)
			// VoltageClampSeries: datasets
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "Fast compensation capacitance", "capacitance_fast", p.electrodeNumber, tsp)
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "Slow compensation capacitance", "capacitance_slow", p.electrodeNumber, tsp)
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "RsComp Bandwidth", "resistance_comp_bandwidth", p.electrodeNumber, tsp, factor=1e3, enabledProp="RsComp Enable")
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "RsComp Correction", "resistance_comp_correction", p.electrodeNumber, tsp, enabledProp="RsComp Enable")
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "RsComp Prediction", "resistance_comp_prediction", p.electrodeNumber, tsp, enabledProp="RsComp Enable")
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "Whole Cell Comp Cap", "whole_cell_capacitance_comp", p.electrodeNumber, tsp, factor=1e-12, enabledProp="Whole Cell Comp Enable")
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "Whole Cell Comp Resist", "whole_cell_series_resistance_comp", p.electrodeNumber, tsp, factor=1e6, enabledProp="Whole Cell Comp Enable")
		elseif(p.clampMode == I_CLAMP_MODE)
			// CurrentClampSeries: datasets
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "I-Clamp Holding Level", "bias_current", p.electrodeNumber, tsp, enabledProp="I-Clamp Holding Enable")
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "Bridge Bal Value", "bridge_balance", p.electrodeNumber, tsp, enabledProp="Bridge Bal Enable")
			NWB_AddSweepDataSets(settingsHistory, p.sweep, "Neut Cap Value", "capacitance_compensation", p.electrodeNumber, tsp, enabledProp="Neut Cap Enabled")
		endif

		NWB_AddSweepDataSets(settingsHistory, p.sweep, "AD Gain", "gain", p.electrodeNumber, tsp)
	elseif(p.channelType == ITC_XOP_CHANNEL_TYPE_DAC)
		NWB_AddSweepDataSets(settingsHistory, p.sweep, "DA Gain", "gain", p.electrodeNumber, tsp)
	endif
End

static Function NWB_AddSweepDataSets(settingsHistory, sweep, settingsProp, nwbProp, headstage, tsp, [factor, enabledProp])
	WAVE settingsHistory
	variable sweep
	string settingsProp, nwbProp
	variable headstage
	STRUCT IPNWB#TimeSeriesProperties &tsp
	variable factor
	string enabledProp

	if(ParamIsDefault(factor))
		factor = 1
	endif

	if(!ParamIsDefault(enabledProp))
		WAVE/Z enabled = GetLastSetting(settingsHistory, sweep, enabledProp)
		if(!WaveExists(enabled) || !enabled[headstage])
			return NaN
		endif
	endif

	WAVE/Z values = GetLastSetting(settingsHistory, sweep, settingsProp)
	if(!WaveExists(values) || !IsFinite(values[headstage]))
		return NaN
	endif

	IPNWB#AddProperty(tsp, nwbProp, values[headstage] * factor)
End
