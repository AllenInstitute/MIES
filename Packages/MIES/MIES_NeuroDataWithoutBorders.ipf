#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_NeuroDataWithoutBorders.ipf
/// @brief __NWB__ Functions related to MIES data export into the NeuroDataWithoutBorders format

/// @todo
/// - use IPNWB#CHANNEL_TYPE_OTHER instead of -1 if possible

/// @brief Return the HDF5 file identifier referring to an open NWB file
///        for export
///
///        Open one if it does not exist yet.
static Function NWB_GetFileForExport()
	string expName, fileName, filePath
	variable fileID, refNum

	NVAR fileIDExport = $GetNWBFileIDExport()

	if(IPNWB#H5_IsFileOpen(fileIDExport))
		return fileIDExport
	endif

	SVAR filePathExport = $GetNWBFilePathExport()
	filePath = filePathExport

	if(isEmpty(filePath)) // need to derive a new NWB filename
		expName = GetExperimentName()

		if(!cmpstr(expName, UNTITLED_EXPERIMENT))
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
			ASSERT(0, "Could not store HDF5 dataset to file")
		endif

		fileIDExport   = fileID
		filePathExport = filePath
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

		IPNWB#CreateCommonGroups(fileID)
		IPNWB#CreateIntraCellularEphys(fileID)

		// update NWB session start time
		NVAR sessionStartTime = $GetSessionStartTime()
		sessionStartTime = DateTimeInUTC()

		fileIDExport   = fileID
		filePathExport = filePath

		NWB_ExportAllData()
	endif

	DEBUGPRINT("fileIDExport", var=fileIDExport, format="%15d")
	DEBUGPRINT("filePathExport", str=filePathExport)

	return fileIDExport
End

static Function NWB_AddDeviceSpecificData(locationID, panelTitle, [chunkedLayout])
	variable locationID
	string panelTitle
	variable chunkedLayout

	variable groupID, i, numEntries, refTime
	string path, list, name, contents

	refTime = DEBUG_TIMER_START()

	chunkedLayout = ParamIsDefault(chunkedLayout) ? 0 : !!chunkedLayout

	sprintf contents, "ITC hardware: %s", panelTitle
	IPNWB#AddDevice(locationID, panelTitle, contents)

	WAVE settingsHistory           = GetNumDocWave(panelTitle)
	WAVE/T settingsHistoryKeys     = GetNumDocKeyWave(panelTitle)
	WAVE/T settingsHistoryText     = GetTextDocWave(panelTitle)
	WAVE/T settingsHistoryTextKeys = GetTextDocKeyWave(panelTitle)

	path = "/general/labnotebook/" + panelTitle
	IPNWB#H5_CreateGroupsRecursively(locationID, path, groupID=groupID)

	IPNWB#H5_WriteDataset(groupID, "numericalValues", wv=settingsHistory, overwrite=1, chunkedLayout=chunkedLayout)
	IPNWB#H5_WriteTextDataset(groupID, "numericalKeys", wvText=settingsHistoryKeys, overwrite=1, chunkedLayout=chunkedLayout)
	IPNWB#H5_WriteTextDataset(groupID, "textualValues", wvText=settingsHistoryText, overwrite=1, chunkedLayout=chunkedLayout)
	IPNWB#H5_WriteTextDataset(groupID, "textualKeys", wvText=settingsHistoryTextKeys, overwrite=1, chunkedLayout=chunkedLayout)

	HDF5CloseGroup/Z groupID
	DEBUGPRINT_ELAPSED(refTime)

	path = "/general/user_comment/" + panelTitle
	IPNWB#H5_CreateGroupsRecursively(locationID, path, groupID=groupID)

	SVAR userComment = $GetUserComment(panelTitle)
	IPNWB#H5_WriteTextDataset(groupID, "userComment", str=userComment, overwrite=1, chunkedLayout=chunkedLayout)

	HDF5CloseGroup/Z groupID
	DEBUGPRINT_ELAPSED(refTime)

	path = "/general/testpulse/" + panelTitle
	IPNWB#H5_CreateGroupsRecursively(locationID, path, groupID=groupID)

	DFREF dfr = GetDeviceTestPulse(panelTitle)
	list = GetListOfWaves(dfr, TP_STORAGE_REGEXP)
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		WAVE/SDFR=dfr wv = $name
		IPNWB#H5_WriteDataset(groupID, name, wv=wv, overwrite=1, chunkedLayout=chunkedLayout)
	endfor

	HDF5CloseGroup/Z groupID
	DEBUGPRINT_ELAPSED(refTime)
End

Function NWB_ExportAllData()
	string devicesWithData, panelTitle, list, name
	variable i, j, numEntries, locationID, sweep, numWaves

	devicesWithData = GetAllDevicesWithData()

	if(isEmpty(devicesWithData))
		print "No devices with data found for NWB export"
		return NaN
	endif

	print "Please be patient while we export all existing data of all devices to NWB"

	locationID = NWB_GetFileForExport()
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

Function NWB_AddMiesVersion(locationID)
	variable locationID

	SVAR miesVersion = $GetMiesVersion()

	IPNWB#H5_WriteTextDataset(locationID, "/general/version", str=miesVersion, overwrite=1)
	IPNWB#MarkAsCustomEntry(locationID, "/general/version")
End

Function NWB_AppendSweep(panelTitle, ITCDataWave, ITCChanConfigWave, sweep)
	string panelTitle
	WAVE ITCDataWave, ITCChanConfigWave
	variable sweep

	variable locationID

	locationID = NWB_GetFileForExport()
	if(!IsFinite(locationID))
		return NaN
	endif

	NWB_AddMiesVersion(locationID)
	IPNWB#AddModificationTimeEntry(locationID)
	NWB_AddDeviceSpecificData(locationID, panelTitle)
	NWB_AppendSweepLowLevel(locationID, panelTitle, ITCDataWave, ITCChanConfigWave, sweep)
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

	NVAR session_start_time = $GetSessionStartTime()

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

	// starting time of the dataset
	ASSERT(!cmpstr(WaveUnits(ITCDataWave, ROWS), "ms"), "Expected ms as wave units")
	params.startingTime  = NumberByKeY("MODTIME", WaveInfo(ITCDataWave, 0)) - date2secs(-1, -1, -1) // last time the wave was modified (UTC)
	params.startingTime -= session_start_time // relative to the start of the session
	params.startingTime -= DimSize(ITCDataWave, ROWS) / 1000 // we want the timestamp of the beginning of the measurement

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

		NWB_WriteStimsetTemplateWaves(locationID, stimSets[i], params, chunkedLayout)
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

			NWB_WriteStimsetTemplateWaves(locationID, name, params, chunkedLayout)
		endfor
	endfor

	DEBUGPRINT_ELAPSED(refTime)
End

static Function NWB_WriteStimsetTemplateWaves(locationID, setName, params, chunkedLayout)
	variable locationID
	string setName
	STRUCT IPNWB#WriteChannelParams &params
	variable chunkedLayout

	STRUCT IPNWB#TimeSeriesProperties tsp
	string stimSet

	stimSet = params.stimSet

	params.channelNumber = NaN
	params.channelType   = -1
	WAVE params.data     = WB_CreateAndGetStimset(setName)
	NWB_GetTimeSeriesProperties(params, tsp)
	IPNWB#WriteSingleChannel(locationID, "/stimulus/templates", params, tsp, chunkedLayout=chunkedLayout)

	// write also the stim set parameter waves if all three exist
	WAVE/Z WP  = WB_GetWaveParamForSet(setName)
	WAVE/Z WPT = WB_GetWaveTextParamForSet(setName)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)

	if(!WaveExists(WP) && !WaveExists(WPT) && !WaveExists(SegWvType))
		// don't need to write the stimset parameter waves
		return NaN
	endif

	ASSERT(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType) , "Some stim set parameter waves are missing")

	params.stimSet = stimSet + "_WP"
	WAVE params.data = WP
	IPNWB#WriteSingleChannel(locationID, "/stimulus/templates", params, tsp, chunkedLayout=chunkedLayout)

	params.stimSet = stimSet + "_WPT"
	WAVE params.data = WPT
	IPNWB#WriteSingleChannel(locationID, "/stimulus/templates", params, tsp, chunkedLayout=chunkedLayout)

	params.stimSet = stimSet + "_SegWvType"
	WAVE params.data = SegWvType
	IPNWB#WriteSingleChannel(locationID, "/stimulus/templates", params, tsp, chunkedLayout=chunkedLayout)
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
