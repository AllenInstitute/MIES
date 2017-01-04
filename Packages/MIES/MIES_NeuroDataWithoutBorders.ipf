#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

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
		list = GetListOfObjects(dfr, DATA_SWEEP_REGEXP)
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

	if(!ParamIsDefault(overrideFilePath))
		filePath = overrideFilePath
	elseif(isEmpty(filePath)) // need to derive a new NWB filename
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
		fileID = IPNWB#H5_OpenFile(filePath, write = 1)

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

		NWB_AddGeneratorString(fileID)

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

Function NWB_AddGeneratorString(fileID)
	variable fileID

	Make/FREE/T/N=(5, 2) props

	props[0][0] = "Program"
#if defined(IGOR64)
	props[0][1] = "Igor Pro 64bit"
#else
	props[0][1] = "Igor Pro 32bit"
#endif

	props[1][0] = "Program Version"
	props[1][1] = StringByKey("IGORFILEVERSION", IgorInfo(3))

	props[2][0] = "Package"
	props[2][1] = "MIES"

	props[3][0] = "Package Version"
	SVAR miesVersion = $GetMiesVersion()
	props[3][1] = miesVersion

	props[4][0] = "Labnotebook Version"
	props[4][1] = num2str(LABNOTEBOOK_VERSION)

	IPNWB#H5_WriteTextDataset(fileID, "/general/generated_by", wvText=props)
	IPNWB#MarkAsCustomEntry(fileID, "/general/generated_by")
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

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE/T numericalKeys = GetLBNumericalKeys(panelTitle)
	WAVE/T textualValues = GetLBTextualValues(panelTitle)
	WAVE/T textualKeys   = GetLBTextualKeys(panelTitle)

	path = "/general/labnotebook/" + panelTitle
	IPNWB#H5_CreateGroupsRecursively(locationID, path, groupID=groupID)

	IPNWB#MarkAsCustomEntry(locationID, "/general/labnotebook")

	IPNWB#H5_WriteDataset(groupID, "numericalValues", wv=numericalValues, writeIgorAttr=1, overwrite=1, chunkedLayout=chunkedLayout)
	IPNWB#H5_WriteTextDataset(groupID, "numericalKeys", wvText=numericalKeys, writeIgorAttr=1, overwrite=1, chunkedLayout=chunkedLayout)
	IPNWB#H5_WriteTextDataset(groupID, "textualValues", wvText=textualValues, writeIgorAttr=1, overwrite=1, chunkedLayout=chunkedLayout)
	IPNWB#H5_WriteTextDataset(groupID, "textualKeys", wvText=textualKeys, writeIgorAttr=1, overwrite=1, chunkedLayout=chunkedLayout)

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
	list = GetListOfObjects(dfr, TP_STORAGE_REGEXP)
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

	IPNWB#AddModificationTimeEntry(locationID)

	numEntries = ItemsInList(devicesWithData)
	for(i = 0; i < numEntries; i += 1)
		panelTitle = StringFromList(i, devicesWithData)
		NWB_AddDeviceSpecificData(locationID, panelTitle, chunkedLayout=1)

		DFREF dfr = GetDeviceDataPath(panelTitle)
		list = GetListOfObjects(dfr, DATA_SWEEP_REGEXP)
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

/// @brief Export all data into NWB using compression
///
/// Ask the file location from the user
Function NWB_ExportWithDialog()

	string expName, path, filename
	variable refNum

	expName = GetExperimentName()

	if(!cmpstr(expName, UNTITLED_EXPERIMENT))
		PathInfo Desktop
		if(!V_flag)
			NewPath/Q Desktop, SpecialDirPath("Desktop", 0, 0, 0)
		endif
		path = "Desktop"

		filename = "UntitledExperiment-" + GetTimeStamp()
	else
		path     = "home"
		filename = expName
	endif

	filename += "-compressed.nwb"

	Open/D/M="Export into NWB"/F="NWB Files:.nwb;"/P=$path refNum as filename

	if(isEmpty(S_filename))
		return NaN
	endif

	// user already acknowledged the overwriting
	CloseNWBFile()
	DeleteFile/Z S_filename

	NWB_ExportAllData(overrideFilePath=S_filename)
	CloseNWBFile()
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

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE/T numericalKeys = GetLBNumericalKeys(panelTitle)
	WAVE/T textualValues = GetLBTextualValues(panelTitle)
	WAVE/T textualKeys   = GetLBTextualKeys(panelTitle)

	Make/FREE/N=(DimSize(ITCDataWave, COLS)) writtenDataColumns = 0

	// comment denotes the introducing comment of the labnotebook entry
	// 9b35fdad (Add the clamp mode to the labnotebook for acquired data, 2015-04-26)
	WAVE/Z clampMode = GetLastSetting(numericalValues, sweep, "Clamp Mode", DATA_ACQUISITION_MODE)

	if(!WaveExists(clampMode))
		WAVE/Z clampMode = GetLastSetting(numericalValues, sweep, "Operating Mode", DATA_ACQUISITION_MODE)
		ASSERT(WaveExists(clampMode), "Labnotebook is too old for NWB export.")
	endif

	// 3a94d3a4 (Modified files: DR_MIES_TangoInteract:  changes recommended by Thomas ..., 2014-09-11)
	WAVE/Z ADCs = GetLastSetting(numericalValues, sweep, "ADC", DATA_ACQUISITION_MODE)
	ASSERT(WaveExists(ADCs), "Labnotebook is too old for NWB export.")

	// dito
	WAVE DACs = GetLastSetting(numericalValues, sweep, "DAC", DATA_ACQUISITION_MODE)
	ASSERT(WaveExists(DACs), "Labnotebook is too old for NWB export.")

	// 9c8e1a94 (Record the active headstage in the settingsHistory, 2014-11-04)
	WAVE/Z statusHS = GetLastSetting(numericalValues, sweep, "Headstage Active", DATA_ACQUISITION_MODE)
	if(!WaveExists(statusHS))
		Duplicate/FREE ADCs, statusHS

		statusHS = (IsFinite(ADCs[p]) && IsFinite(DACs[p]))
		ASSERT(sum(statusHS) >= 1, "Headstage active workaround failed as there are no active headstages")
	endif

	// 296097c2 (Changes to Tango Interact, 2014-09-03)
	WAVE/T stimSets = GetLastSettingText(textualValues, sweep, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	ASSERT(WaveExists(stimSets), "Labnotebook is too old for NWB export.")

	// 95402da6 (NWB: Allow documenting the physical electrode, 2016-08-05)
	WAVE/Z/T electrodeNames = GetLastSettingText(textualValues, sweep, "Electrode", DATA_ACQUISITION_MODE)
	if(!WaveExists(electrodeNames))
		Make/FREE/T/N=(NUM_HEADSTAGES) electrodeNames = GetDefaultElectrodeName(p)
	else
		WAVE/Z nonEmptyElectrodes = FindIndizes(wvText=electrodeNames, col=0, prop=PROP_NON_EMPTY)
		if(!WaveExists(nonEmptyElectrodes)) // all are empty
			electrodeNames[] = GetDefaultElectrodeName(p)
		endif
	endif

	STRUCT IPNWB#WriteChannelParams params
	IPNWB#InitWriteChannelParams(params)

	params.sweep         = sweep
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
		IPNWB#AddElectrode(locationID, electrodeNames[i], contents, panelTitle)

		adc                    = ADCs[i]
		dac                    = DACs[i]
		params.electrodeName   = electrodeNames[i]
		params.clampMode       = clampMode[i]
		params.stimset         = stimSets[i]

		if(IsFinite(adc))
			path                    = "/acquisition/timeseries"
			params.channelNumber    = ADCs[i]
			params.channelType      = ITC_XOP_CHANNEL_TYPE_ADC
			col                     = AFH_GetITCDataColumn(ITCChanConfigWave, params.channelNumber, params.channelType)
			writtenDataColumns[col] = 1
			WAVE params.data        = ExtractOneDimDataFromSweep(ITCChanConfigWave, ITCDataWave, col)
			NWB_GetTimeSeriesProperties(params, tsp)
			params.groupIndex    = IsFinite(params.groupIndex) ? params.groupIndex : IPNWB#GetNextFreeGroupIndex(locationID, path)
			IPNWB#WriteSingleChannel(locationID, path, params, tsp, chunkedLayout=chunkedLayout)
		endif

		DEBUGPRINT_ELAPSED(refTime)

		if(IsFinite(dac))
			path                    = "/stimulus/presentation"
			params.channelNumber    = DACs[i]
			params.channelType      = ITC_XOP_CHANNEL_TYPE_DAC
			col                     = AFH_GetITCDataColumn(ITCChanConfigWave, params.channelNumber, params.channelType)
			writtenDataColumns[col] = 1
			WAVE params.data        = ExtractOneDimDataFromSweep(ITCChanConfigWave, ITCDataWave, col)
			NWB_GetTimeSeriesProperties(params, tsp)
			params.groupIndex    = IsFinite(params.groupIndex) ? params.groupIndex : IPNWB#GetNextFreeGroupIndex(locationID, path)
			IPNWB#WriteSingleChannel(locationID, path, params, tsp, chunkedLayout=chunkedLayout)
		endif

		DEBUGPRINT_ELAPSED(refTime)

		// don't output stimsets for I=0 mode
		if(params.clampMode != I_EQUAL_ZERO_MODE)
			NWB_WriteStimsetTemplateWaves(locationID, stimSets[i], chunkedLayout)
		endif
	endfor

	DEBUGPRINT_ELAPSED(refTime)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		ttlBits = GetTTLBits(numericalValues, sweep, i)
		if(!IsFinite(ttlBits))
			continue
		endif

		listOfStimsets = GetTTLstimSets(numericalValues, textualValues, sweep, i)

		params.clampMode        = NaN
		params.channelNumber    = i
		params.channelType      = ITC_XOP_CHANNEL_TYPE_TTL
		col                     = AFH_GetITCDataColumn(ITCChanConfigWave, params.channelNumber, params.channelType)
		writtenDataColumns[col] = 1

		WAVE data = ExtractOneDimDataFromSweep(ITCChanConfigWave, ITCDataWave, col)
		DFREF dfr = NewFreeDataFolder()
		SplitTTLWaveIntoComponents(data, ttlBits, dfr, "_")

		list = GetListOfObjects(dfr, ".*")
		numEntries = ItemsInList(list)
		for(j = 0; j < numEntries; j += 1)
			name = StringFromList(j, list)
			WAVE/SDFR=dfr params.data = $name
			path                 = "/stimulus/presentation"
			params.channelSuffix = name[1, inf]
			params.channelSuffixDesc = NWB_SOURCE_TTL_BIT
			params.stimset       = StringFromList(str2num(name[1,inf]), listOfStimsets)
			NWB_GetTimeSeriesProperties(params, tsp)
			params.groupIndex    = IsFinite(params.groupIndex) ? params.groupIndex : IPNWB#GetNextFreeGroupIndex(locationID, path)
			IPNWB#WriteSingleChannel(locationID, path, params, tsp, chunkedLayout=chunkedLayout)
		endfor

		numEntries = ItemsInList(listOfStimsets)
		for(j = 0; j < numEntries; j += 1)
			name = StringFromList(j, listOfStimsets)

			// work around empty TTL stim set bug in labnotebook
			if(isEmpty(name))
				continue
			endif

			NWB_WriteStimsetTemplateWaves(locationID, name, chunkedLayout)
		endfor
	endfor

	DEBUGPRINT_ELAPSED(refTime)

	numEntries = DimSize(writtenDataColumns, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(writtenDataColumns[i])
			continue
		endif

		// unassociated channel data
		// can currently be ADC only
		path                   = "/acquisition/timeseries"
		ASSERT(ITCChanConfigWave[i][0] == ITC_XOP_CHANNEL_TYPE_ADC, "Unexpected channel type")
		params.clampMode       = NaN
		params.electrodeNumber = NaN
		params.electrodeName   = ""
		params.channelType     = ITCChanConfigWave[i][0]
		params.channelNumber   = ITCChanConfigWave[i][1]
		params.stimSet         = ""
		NWB_GetTimeSeriesProperties(params, tsp)
		WAVE params.data       = ExtractOneDimDataFromSweep(ITCChanConfigWave, ITCDataWave, i)
		params.groupIndex      = IsFinite(params.groupIndex) ? params.groupIndex : IPNWB#GetNextFreeGroupIndex(locationID, path)
		IPNWB#WriteSingleChannel(locationID, path, params, tsp, chunkedLayout=chunkedLayout)
	endfor

	DEBUGPRINT_ELAPSED(refTime)
End

static Function NWB_WriteStimsetTemplateWaves(locationID, stimSet, chunkedLayout)
	variable locationID
	string stimSet
	variable chunkedLayout

	variable groupID
	string name

	ASSERT(IPNWB#H5_GroupExists(locationID, "/general/stimsets", groupID=groupID), "Missing group")

	// write also the stim set parameter waves if all three exist
	WAVE/Z WP  = WB_GetWaveParamForSet(stimSet)
	WAVE/Z WPT = WB_GetWaveTextParamForSet(stimSet)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimSet)

	if(!WaveExists(WP) && !WaveExists(WPT) && !WaveExists(SegWvType))
		// third party stim sets need to be written as we don't have parameter waves
		WAVE stimSetWave = WB_CreateAndGetStimSet(stimSet)
		name = stimSet
		IPNWB#H5_WriteDataset(groupID, name, wv=stimSetWave, chunkedLayout=chunkedLayout, overwrite=1, writeIgorAttr=1)
		// @todo remove once IP7 64bit is mandatory
		// save memory by deleting the stimset again
		KillOrMoveToTrash(wv=stimSetWave)

		HDF5CloseGroup groupID
		return NaN
	endif

	ASSERT(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType) , "Some stim set parameter waves are missing")

	name = stimSet + "_WP"
	IPNWB#H5_WriteDataset(groupID, name, wv=WP, chunkedLayout=chunkedLayout, overwrite=1, writeIgorAttr=1)

	name = stimSet + "_WPT"
	IPNWB#H5_WriteDataset(groupID, name, wv=WPT, chunkedLayout=chunkedLayout, overwrite=1, writeIgorAttr=1)

	name = stimSet + "_SegWvType"
	IPNWB#H5_WriteDataset(groupID, name, wv=SegWVType, chunkedLayout=chunkedLayout, overwrite=1, writeIgorAttr=1)

	HDF5CloseGroup groupID
End

static Function NWB_GetTimeSeriesProperties(p, tsp)
	STRUCT IPNWB#WriteChannelParams &p
	STRUCT IPNWB#TimeSeriesProperties &tsp

	WAVE numericalValues = GetLBNumericalValues(p.device)

	IPNWB#InitTimeSeriesProperties(tsp, p.channelType, p.clampMode)

	// unassociated channel
	if(!IsFinite(p.clampMode))
		return NaN
	endif

	if(strlen(tsp.missing_fields) > 0)
		ASSERT(IsFinite(p.electrodeNumber), "Expected finite electrode number with non empty \"missing_fields\"")
	endif

	if(p.channelType == ITC_XOP_CHANNEL_TYPE_ADC)
		if(p.clampMode == V_CLAMP_MODE)
			// VoltageClampSeries: datasets
			NWB_AddSweepDataSets(numericalValues, p.sweep, "Fast compensation capacitance", "capacitance_fast", p.electrodeNumber, tsp)
			NWB_AddSweepDataSets(numericalValues, p.sweep, "Slow compensation capacitance", "capacitance_slow", p.electrodeNumber, tsp)
			NWB_AddSweepDataSets(numericalValues, p.sweep, "RsComp Bandwidth", "resistance_comp_bandwidth", p.electrodeNumber, tsp, factor=1e3, enabledProp="RsComp Enable")
			NWB_AddSweepDataSets(numericalValues, p.sweep, "RsComp Correction", "resistance_comp_correction", p.electrodeNumber, tsp, enabledProp="RsComp Enable")
			NWB_AddSweepDataSets(numericalValues, p.sweep, "RsComp Prediction", "resistance_comp_prediction", p.electrodeNumber, tsp, enabledProp="RsComp Enable")
			NWB_AddSweepDataSets(numericalValues, p.sweep, "Whole Cell Comp Cap", "whole_cell_capacitance_comp", p.electrodeNumber, tsp, factor=1e-12, enabledProp="Whole Cell Comp Enable")
			NWB_AddSweepDataSets(numericalValues, p.sweep, "Whole Cell Comp Resist", "whole_cell_series_resistance_comp", p.electrodeNumber, tsp, factor=1e6, enabledProp="Whole Cell Comp Enable")
		elseif(p.clampMode == I_CLAMP_MODE)
			// CurrentClampSeries: datasets
			NWB_AddSweepDataSets(numericalValues, p.sweep, "I-Clamp Holding Level", "bias_current", p.electrodeNumber, tsp, enabledProp="I-Clamp Holding Enable")
			NWB_AddSweepDataSets(numericalValues, p.sweep, "Bridge Bal Value", "bridge_balance", p.electrodeNumber, tsp, enabledProp="Bridge Bal Enable")
			NWB_AddSweepDataSets(numericalValues, p.sweep, "Neut Cap Value", "capacitance_compensation", p.electrodeNumber, tsp, enabledProp="Neut Cap Enabled")
		endif

		NWB_AddSweepDataSets(numericalValues, p.sweep, "AD Gain", "gain", p.electrodeNumber, tsp)
	elseif(p.channelType == ITC_XOP_CHANNEL_TYPE_DAC)
		NWB_AddSweepDataSets(numericalValues, p.sweep, "DA Gain", "gain", p.electrodeNumber, tsp)

		WAVE/Z values = GetLastSetting(numericalValues, p.sweep, "Stim Scale Factor", DATA_ACQUISITION_MODE)
		if(WaveExists(values) || IsFinite(values[p.electrodeNumber]))
			IPNWB#AddCustomProperty(tsp, "scale", values[p.electrodeNumber])
		endif
	endif
End

static Function NWB_AddSweepDataSets(numericalValues, sweep, settingsProp, nwbProp, headstage, tsp, [factor, enabledProp])
	WAVE numericalValues
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
		WAVE/Z enabled = GetLastSetting(numericalValues, sweep, enabledProp, DATA_ACQUISITION_MODE)
		if(!WaveExists(enabled) || !enabled[headstage])
			return NaN
		endif
	endif

	WAVE/Z values = GetLastSetting(numericalValues, sweep, settingsProp, DATA_ACQUISITION_MODE)
	if(!WaveExists(values) || !IsFinite(values[headstage]))
		return NaN
	endif

	IPNWB#AddProperty(tsp, nwbProp, values[headstage] * factor)
End

/// @brief function saves contents of specified notebook to data folder
///
/// @param locationID id of nwb file or notebooks folder
/// @param notebook name of notebook to be loaded
/// @param dfr igor data folder where data should be loaded into
Function NWB_LoadLabNoteBook(locationID, notebook, dfr)
	Variable locationID
	String notebook
	DFREF dfr

	String deviceList, path

	if(!DataFolderExistsDFR(dfr))
		return 0
	endif

	path = "/general/labnotebook/" + notebook
	if(IPNWB#H5_GroupExists(locationID, path))
		HDF5LoadGroup/Z/IGOR=-1 dfr, locationID, path
		if(!V_flag)
			return ItemsInList(S_objectPaths)
		endif
	endif

	return 0
End
