#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_NWB
#endif

/// @file MIES_NeuroDataWithoutBorders.ipf
/// @brief __NWB__ Functions related to MIES data export into the NeuroDataWithoutBorders format

/// @brief Return the starting time, in fractional seconds since Igor Pro epoch in UTC, of the given sweep
///
/// For existing sweeps with #HIGH_PREC_SWEEP_START_KEY labnotebook entries we use the sweep wave's modification time.
/// The sweep wave can be either an `DAQDataWave` or a `Sweep_$num` wave. Passing the `DAQDataWave` is more accurate.
static Function NWB_GetStartTimeOfSweep(panelTitle, sweepNo, sweepWave)
	string panelTitle
	variable sweepNo
	WAVE sweepWave

	variable startingTime
	string timestamp

	WAVE/T textualValues = GetLBTextualValues(panelTitle)
	timestamp = GetLastSettingTextIndep(textualValues, sweepNo, HIGH_PREC_SWEEP_START_KEY, DATA_ACQUISITION_MODE)

	if(!isEmpty(timestamp))
		return ParseISO8601TimeStamp(timestamp)
	endif

	// fallback mode for old sweeps
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
	variable numEntries, numWaves, sweepNo, i, j
	variable oldest = Inf

	devicesWithData = GetAllDevicesWithContent()

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
			sweepNo = ExtractSweepNumber(name)
			ASSERT(IsValidSweepNumber(sweepNo), "Could not extract sweep number")
			WAVE/SDFR=dfr sweepWave = $name

			oldest = min(oldest, NWB_GetStartTimeOfSweep(panelTitle, sweepNo, sweepWave))
		endfor
	endfor

	return oldest
End

/// @brief Return the HDF5 file identifier referring to an open NWB file
///        for export
///
/// Open one if it does not exist yet.
///
/// @param[in]  nwbVersion         Set NWB version if new file is created. default: latest version
/// @param[in]  overrideFilePath   [optional] file path for new files to override the internal
///                                generation algorithm
/// @param[out] createdNewNWBFile  [optional] a new NWB file was created (1) or an existing opened (0)
static Function NWB_GetFileForExport(nwbVersion, [overrideFilePath, createdNewNWBFile])
	variable nwbVersion
	string overrideFilePath
	variable &createdNewNWBFile

	string expName, fileName, filePath
	variable fileID, refNum, oldestData

	NVAR fileIDExport = $GetNWBFileIDExport()
	NVAR sessionStartTimeReadBack = $GetSessionStartTimeReadBack()

	SVAR filePathExport = $GetNWBFilePathExport()
	filePath = filePathExport

	if(ParamIsDefault(overrideFilePath))
		if(IPNWB#H5_IsFileOpen(fileIDExport))
			return fileIDExport
		endif

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
				filePath = S_path + CleanupExperimentName(expName) + ".nwb"
			endif
		endif
	else
		filePath = overrideFilePath
	endif

	ASSERT(!IsEmpty(filePath), "filePath can not be empty")

	if(FileExists(filePath))
		fileID = IPNWB#H5_OpenFile(filePath, write = 1)
		ASSERT(IPNWB#GetNWBMajorVersion(IPNWB#ReadNWBVersion(fileID)) == nwbVersion, "NWB_GetFileForExport: NWB version of the selected NWB file differs.")

		sessionStartTimeReadBack = NWB_ReadSessionStartTime(fileID)

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
			return NWB_GetFileForExport(nwbVersion)
		endif

		STRUCT IPNWB#ToplevelInfo ti
		IPNWB#InitToplevelInfo(ti, nwbVersion)

		NVAR sessionStartTime = $GetSessionStartTime()

		if(!IsFinite(sessionStartTime))
			sessionStartTime = DateTimeInUTC()
		endif

		oldestData = NWB_FirstStartTimeOfAllSweeps()

		// adjusting the session start time, as older sweeps than the
		// timestamp of the last device locking are to be exported
		// not adjusting it would result in negative starting times for the lastest sweep
		if(IsFinite(oldestData))
			// workaround "Save and Clear" not resetting the sessionStartTime
			// fixed since previous commit (SaveExperimentSpecial: Reset session start
			// time in "Save and clear" mode, 2020-05-28)
			// we ignore session start times which are older (45min) than oldestData
			// as these are most probably due to the above bug. It is very
			// unlikely that the time between device locking (session start
			// time) and first data acquisition is larger than 45min.
			if((oldestData - sessionStartTime) > 0.75 * 3600)
				ti.session_start_time = floor(oldestData)
			else
				ti.session_start_time = min(sessionStartTime, floor(oldestData))
			endif
		endif

		IPNWB#CreateCommonGroups(fileID, ti)

		NWB_AddGeneratorString(fileID, nwbVersion)
		NWB_AddSpecifications(fileID, nwbVersion)

		sessionStartTimeReadBack = NWB_ReadSessionStartTime(fileID)
		ASSERT(ti.session_start_time == sessionStartTimeReadBack, "Buggy timestamp handling")

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

static Function NWB_AddGeneratorString(fileID, nwbVersion)
	variable fileID, nwbVersion

	IPNWB#EnsureValidNWBVersion(nwbVersion)

	Make/FREE/T/N=(6, 2) props

	props[0][0] = "Program"
	props[0][1] = "Igor Pro " + num2str(GetArchitectureBits()) + "bit"

	props[1][0] = "Program Version"
	props[1][1] = GetIgorProVersion()

	props[2][0] = "Program Build Version"
	props[2][1] = GetIgorProBuildVersion()

	props[3][0] = "Package"
	props[3][1] = "MIES"

	props[4][0] = "Package Version"
	props[4][1] = GetMIESVersionAsString()

	props[5][0] = "Labnotebook Version"
	props[5][1] = num2str(LABNOTEBOOK_VERSION)

	if(nwbVersion == 1)
		IPNWB#H5_WriteTextDataset(fileID, "/general/generated_by", wvText=props)
		IPNWB#MarkAsCustomEntry(fileID, "/general/generated_by")
	elseif(nwbVersion == 2)
		IPNWB#H5_WriteTextDataset(fileID, "/general/generated_by", wvText=props)
		IPNWB#WriteNeuroDataType(fileID, "/general/generated_by", "GeneratedBy")
		IPNWB#H5_WriteTextDataset(fileID, "/general/source_script", str=props[3][1])
		IPNWB#H5_WriteTextAttribute(fileID, "file_name", "/general/source_script", str=IgorInfo(1))
	endif
End

static Function NWB_AddSpecifications(fileID, nwbVersion)
	variable fileID, nwbVersion

	IPNWB#EnsureValidNWBVersion(nwbVersion)
	if(nwbVersion == 1)
		return NaN
	endif

	IPNWB#WriteSpecifications(fileID)
End

static Function NWB_ReadSessionStartTime(fileID)
	variable fileID

	string str = IPNWB#ReadTextDataSetAsString(fileID, "/session_start_time")

	ASSERT(cmpstr(str, IPNWB_PLACEHOLDER), "Could not read session_start_time back from the NWB file")

	return ParseISO8601TimeStamp(str)
End

static Function/S NWB_GenerateDeviceDescription(panelTitle)
	string panelTitle

	string deviceType, deviceNumber, desc

	ASSERT(ParseDeviceString(panelTitle, deviceType, deviceNumber), "Could not parse panelTitle")

	/// @todo handle NI Hardware
	sprintf desc, "Harvard Bioscience (formerly HEKA/Instrutech) Model: %s", deviceType
	return desc
End

static Function NWB_AddDeviceSpecificData(locationID, panelTitle, nwbVersion, [compressionMode, writeStoredTestPulses])
	variable locationID
	string panelTitle
	variable nwbVersion, compressionMode, writeStoredTestPulses

	variable groupID, i, numEntries, refTime, compressionModeStoredTP
	string path, list, name, contents

	refTime = DEBUG_TIMER_START()

	if(ParamIsDefault(writeStoredTestPulses))
		writeStoredTestPulses = 0
	else
		writeStoredTestPulses = !!writeStoredTestPulses
	endif

	if(ParamIsDefault(compressionMode))
		compressionMode = IPNWB#GetNoCompression()
	endif

	IPNWB#AddDevice(locationID, panelTitle, nwbVersion, NWB_GenerateDeviceDescription(panelTitle))

	// keys getter functions handle labnotebook wave upgrades
	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE/T numericalKeys = GetLBNumericalKeys(panelTitle)
	WAVE/T textualValues = GetLBTextualValues(panelTitle)
	WAVE/T textualKeys   = GetLBTextualKeys(panelTitle)

	path = "/general/labnotebook/" + panelTitle

	IPNWB#H5_CreateGroupsRecursively(locationID, path)
	groupID = IPNWB#H5_OpenGroup(locationID, path)

	if(nwbVersion == 1)
		IPNWB#MarkAsCustomEntry(locationID, "/general/labnotebook")
	elseif(nwbVersion == 2)
		IPNWB#WriteNeuroDataType(locationID, "/general/labnotebook", "LabNotebook")
		IPNWB#WriteNeuroDataType(locationID, path, "LabNotebookDevice")
	endif

	WAVE/Z numericalValuesTrimmed = RemoveUnusedRows(numericalValues)
	if(WaveExists(numericalValuesTrimmed))
		IPNWB#H5_WriteDataset(groupID, "numericalValues", wv=numericalValuesTrimmed, writeIgorAttr=1, overwrite=1, compressionMode = compressionMode)
	endif
	IPNWB#H5_WriteTextDataset(groupID, "numericalKeys", wvText=numericalKeys, writeIgorAttr=1, overwrite=1, compressionMode = compressionMode)

	WAVE/Z textualValuesTrimmed = RemoveUnusedRows(textualValues)
	if(WaveExists(textualValuesTrimmed))
		IPNWB#H5_WriteTextDataset(groupID, "textualValues", wvText=textualValuesTrimmed, writeIgorAttr=1, overwrite=1, compressionMode = compressionMode)
	endif

	IPNWB#H5_WriteTextDataset(groupID, "textualKeys", wvText=textualKeys, writeIgorAttr=1, overwrite=1, compressionMode = compressionMode)

	if(nwbVersion == 2)
		IPNWB#WriteNeuroDataType(groupID, "numericalValues", "LabNotebookNumericalValues")
		IPNWB#WriteNeuroDataType(groupID, "numericalKeys", "LabNotebookNumericalKeys")
		IPNWB#WriteNeuroDataType(groupID, "textualValues", "LabNotebookTextualValues")
		IPNWB#WriteNeuroDataType(groupID, "textualKeys", "LabNotebookTextualKeys")
	endif

	HDF5CloseGroup/Z groupID
	DEBUGPRINT_ELAPSED(refTime)

	path = "/general/user_comment/" + panelTitle

	IPNWB#H5_CreateGroupsRecursively(locationID, path)
	groupID = IPNWB#H5_OpenGroup(locationID, path)

	SVAR userComment = $GetUserComment(panelTitle)
	IPNWB#H5_WriteTextDataset(groupID, "userComment", str=userComment, overwrite=1, compressionMode = compressionMode)

	if(nwbVersion == 1)
		IPNWB#MarkAsCustomEntry(locationID, "/general/user_comment")
	elseif(nwbVersion == 2)
		IPNWB#WriteNeuroDataType(locationID, "/general/user_comment", "UserComment")
		IPNWB#WriteNeuroDataType(locationID, path, "UserCommentDevice")
		IPNWB#WriteNeuroDataType(groupID, "userComment", "UserCommentString")
	endif

	HDF5CloseGroup/Z groupID
	DEBUGPRINT_ELAPSED(refTime)

	path = "/general/testpulse/" + panelTitle

	IPNWB#H5_CreateGroupsRecursively(locationID, path)
	groupID = IPNWB#H5_OpenGroup(locationID, path)

	if(nwbVersion == 1)
		IPNWB#MarkAsCustomEntry(locationID, "/general/testpulse")
	elseif(nwbVersion == 2)
		IPNWB#WriteNeuroDataType(locationID, "/general/testpulse", "Testpulse")
		IPNWB#WriteNeuroDataType(locationID, path, "TestpulseDevice")
	endif

	if(compressionMode == IPNWB#GetNoCompression())
		compressionModeStoredTP = compressionMode
	else
		compressionModeStoredTP = IPNWB#GetSingleChunkCompression()
	endif

	DFREF dfr = GetDeviceTestPulse(panelTitle)
	list = GetListOfObjects(dfr, TP_STORAGE_REGEXP)
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		WAVE/SDFR=dfr wv = $name

		WAVE/Z wvTrimmed = RemoveUnusedRows(wv)
		if(WaveExists(wvTrimmed))
			IPNWB#H5_WriteDataset(groupID, name, wv=wvTrimmed, writeIgorAttr=1, overwrite=1, compressionMode = compressionMode)

			if(nwbVersion == 2)
				IPNWB#WriteNeuroDataType(groupID, name, "TestpulseMetadata")
			endif
		endif
	endfor

	if(writeStoredTestPulses)
		NWB_AppendStoredTestPulses(panelTitle, nwbVersion, groupID, compressionModeStoredTP)
	endif

	HDF5CloseGroup/Z groupID
	DEBUGPRINT_ELAPSED(refTime)
End

Function NWB_ExportAllData(nwbVersion, [overrideFilePath, writeStoredTestPulses, writeIgorHistory, compressionMode])
	variable nwbVersion
	string overrideFilePath
	variable writeStoredTestPulses, writeIgorHistory, compressionMode

	string devicesWithContent, panelTitle, list, name
	variable i, j, numEntries, locationID, sweep, numWaves, firstCall, deviceID
	string stimsetList = ""

	devicesWithContent = GetAllDevicesWithContent(contentType = CONTENT_TYPE_ALL)

	if(IsEmpty(devicesWithContent))
		print "No devices with acquired content found for NWB export"
		ControlWindowToFront()
		return NaN
	endif

	if(ParamIsDefault(writeStoredTestPulses))
		writeStoredTestPulses = 0
	else
		writeStoredTestPulses = !!writeStoredTestPulses
	endif

	if(ParamIsDefault(writeIgorHistory))
		writeIgorHistory = 1
	else
		writeIgorHistory = !!writeIgorHistory
	endif

	if(!ParamIsDefault(overrideFilePath))
		locationID = NWB_GetFileForExport(nwbVersion, overrideFilePath=overrideFilePath)
	else
		locationID = NWB_GetFileForExport(nwbVersion)
	endif

	if(ParamIsDefault(compressionMode))
		compressionMode = IPNWB#GetChunkedCompression()
	endif

	if(!IsFinite(locationID))
		return NaN
	endif

	IPNWB#AddModificationTimeEntry(locationID, nwbVersion)

	print "Please be patient while we export all existing acquired content of all devices to NWB"
	ControlWindowToFront()

	firstCall = 1
	numEntries = ItemsInList(devicesWithContent)
	for(i = 0; i < numEntries; i += 1)
		panelTitle = StringFromList(i, devicesWithContent)
		NWB_AddDeviceSpecificData(locationID, panelTitle, nwbVersion, compressionMode = compressionMode, writeStoredTestPulses = writeStoredTestPulses)

		DFREF dfr = GetDeviceDataPath(panelTitle)
		list = GetListOfObjects(dfr, DATA_SWEEP_REGEXP)
		numWaves = ItemsInList(list)
		for(j = 0; j < numWaves; j += 1)
			if(firstCall)
				IPNWB#CreateIntraCellularEphys(locationID)
				firstCall = 0
			endif

			name = StringFromList(j, list)
			WAVE/SDFR=dfr sweepWave = $name
			WAVE/Z configWave = GetConfigWave(sweepWave)

			sweep = ExtractSweepNumber(name)

			if(!WaveExists(configWave))
				printf "Sweep %d can not be exported as the config wave is missing.", sweep
				ControlWindowToFront()
				continue
			endif

			NWB_AppendSweepLowLevel(locationID, nwbVersion, panelTitle, sweepWave, configWave, sweep, compressionMode = compressionMode)
			stimsetList += NWB_GetStimsetFromPanel(panelTitle, sweep)
		endfor
	endfor

	NWB_AppendStimset(nwbVersion, locationID, stimsetList, compressionMode)

	if(writeIgorHistory)
		NWB_AppendIgorHistory(nwbVersion, locationID)
	endif
End

Function NWB_ExportAllStimsets(nwbVersion, [overrideFilePath])
	variable nwbVersion
	string overrideFilePath

	variable locationID
	string stimsets

	stimsets = ReturnListOfAllStimSets(CHANNEL_TYPE_DAC, CHANNEL_DA_SEARCH_STRING) + ReturnListOfAllStimSets(CHANNEL_TYPE_TTL, CHANNEL_TTL_SEARCH_STRING)

	if(IsEmpty(stimsets))
		print "No stimsets found for NWB export"
		ControlWindowToFront()
		return NaN
	endif

	if(!ParamIsDefault(overrideFilePath))
		locationID = NWB_GetFileForExport(nwbVersion, overrideFilePath=overrideFilePath)
	else
		locationID = NWB_GetFileForExport(nwbVersion)
	endif

	if(!IsFinite(locationID))
		return NaN
	endif

	IPNWB#AddModificationTimeEntry(locationID, nwbVersion)

	print "Please be patient while we export all existing stimsets to NWB"
	ControlWindowToFront()

	NWB_AppendStimset(nwbVersion, locationID, stimsets, IPNWB#GetChunkedCompression())
	CloseNWBFile()
End

/// @brief Export all data into NWB using compression
///
/// Ask the file location from the user
///
/// @param exportType Export all data and referenced stimsets
///                   (#NWB_EXPORT_DATA) or all stimsets (#NWB_EXPORT_STIMSETS)
/// @param nwbVersion [optional, defaults to latest version] major NWB version
Function NWB_ExportWithDialog(exportType, [nwbVersion])
	variable exportType, nwbVersion

	string expName, path, filename
	variable refNum, pathNeedsKilling

	if(ParamIsDefault(nwbVersion))
		nwbVersion = IPNWB#GetNWBVersion()
	endif

	expName = GetExperimentName()

	if(!cmpstr(expName, UNTITLED_EXPERIMENT))
		PathInfo Desktop
		if(!V_flag)
			NewPath/Q Desktop, SpecialDirPath("Desktop", 0, 0, 0)
		endif
		path = "Desktop"
		pathNeedsKilling = 1

		filename = "UntitledExperiment-" + GetTimeStamp()
	else
		path     = "home"
		filename = expName
	endif

	filename += "-compressed.nwb"

	Open/D/M="Export into NWB"/F="NWB Files:.nwb;"/P=$path refNum as filename

	if(pathNeedsKilling)
		KillPath/Z $path
	endif

	if(isEmpty(S_filename))
		return NaN
	endif

	// user already acknowledged the overwriting
	CloseNWBFile()
	DeleteFile/Z S_filename

	if(exportType == NWB_EXPORT_DATA)
		NWB_ExportAllData(nwbVersion, overrideFilePath=S_filename, writeStoredTestPulses = 1, writeIgorHistory = 1)
	elseif(exportType == NWB_EXPORT_STIMSETS)
		NWB_ExportAllStimsets(nwbVersion, overrideFilePath=S_filename)
	else
		ASSERT(0, "unexpected exportType")
	endif

	CloseNWBFile()
End

/// @brief Write the stored test pulses to the NWB file
static Function NWB_AppendStoredTestPulses(panelTitle, nwbVersion, locationID, compressionMode)
	string panelTitle
	variable locationID, nwbVersion, compressionMode

	variable index, numZeros, i
	string name

	WAVE/WAVE storedTP = GetStoredTestPulseWave(panelTitle)
	index = GetNumberFromWaveNote(storedTP, NOTE_INDEX)

	if(!index)
		// nothing to store
		return NaN
	endif

	for(i = 0; i < index; i += 1)
		sprintf name, "StoredTestPulses_%d", i
		IPNWB#H5_WriteDataset(locationID, name, wv = storedTP[i], compressionMode = compressionMode, overwrite = 1, writeIgorAttr = 1)

		if(nwbVersion == 2)
			IPNWB#WriteNeuroDataType(locationID, name, "TestpulseRawData")
		endif
	endfor
End

/// @brief Export given stimsets to NWB file
///
/// @param nwbVersion      major NWB version
/// @param locationID      Identifier of open hdf5 group or file
/// @param stimsets        Single stimset as string
///                        or list of stimsets sparated by ;
/// @param compressionMode Type of compression to use, one of @ref CompressionMode
static Function NWB_AppendStimset(nwbVersion, locationID, stimsets, compressionMode)
	variable nwbVersion, locationID, compressionMode
	string stimsets

	variable i, numStimsets, numWaves

	stimsets = GrepList(stimsets, "(?i)\\Q" + STIMSET_TP_WHILE_DAQ + "\\E", 1)

	// process stimsets and dependent stimsets
	stimsets = WB_StimsetRecursionForList(stimsets)
	numStimsets = ItemsInList(stimsets)
	for(i = 0; i < numStimsets; i += 1)
		NWB_WriteStimsetTemplateWaves(nwbVersion, locationID, StringFromList(i, stimsets), compressionMode)
	endfor

	// process custom waves
	WAVE/WAVE wv = WB_CustomWavesFromStimSet(stimsetList = stimsets)
	numWaves = DimSize(wv, ROWS)
	for(i = 0; i < numWaves; i += 1)
		NWB_WriteStimsetCustomWave(nwbVersion, locationID, wv[i], compressionMode)
	endfor
End

/// @brief Prepare everything for sweep-by-sweep NWB export
Function NWB_PrepareExport(nwbVersion, [createdNewNWBFile])
	variable nwbVersion
	variable &createdNewNWBFile

	variable locationID, createdNewNWBFileLocal

	locationID = NWB_GetFileForExport(nwbVersion, createdNewNWBFile = createdNewNWBFileLocal)

	if(!ParamIsDefault(createdNewNWBFile))
		createdNewNWBFile = createdNewNWBFileLocal
	endif

	if(!IsFinite(locationID))
		return NaN
	endif

	if(createdNewNWBFileLocal)
		NWB_ExportAllData(nwbVersion)
	endif

	return locationID
End

Function NWB_AppendSweep(panelTitle, DAQDataWave, DAQConfigWave, sweep, nwbVersion)
	string panelTitle
	WAVE DAQDataWave, DAQConfigWave
	variable sweep, nwbVersion

	variable locationID, deviceID, createdNewNWBFile
	string stimsets

	locationID = NWB_PrepareExport(nwbVersion, createdNewNWBFile = createdNewNWBFile)

	// in case we created a new NWB file we already exported everyting so we are done
	if(!IsFinite(locationID) || createdNewNWBFile)
		return NaN
	endif

	IPNWB#AddModificationTimeEntry(locationID, nwbVersion)
	IPNWB#CreateIntraCellularEphys(locationID)
	NWB_AddDeviceSpecificData(locationID, panelTitle, nwbVersion)
	NWB_AppendSweepLowLevel(locationID, nwbVersion, panelTitle, DAQDataWave, DAQConfigWave, sweep)
	stimsets = NWB_GetStimsetFromPanel(panelTitle, sweep)
	NWB_AppendStimset(nwbVersion, locationID, stimsets, IPNWB#GetChunkedCompression())

	NVAR nwbThreadID = $GetNWBThreadID()
	if(IsFinite(nwbThreadID) && !TS_ThreadGroupFinished(nwbThreadID))
		TS_ThreadGroupPutVariable(nwbThreadID, "flushID", locationID)
	endif
End

/// @brief Get stimsets by analysing currently loaded sweep
///
/// numericalValues and textualValues are generated from panelTitle
///
/// @returns list of stimsets
static Function/S NWB_GetStimsetFromPanel(panelTitle, sweep)
	string panelTitle
	variable sweep

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE/T textualValues = GetLBTextualValues(panelTitle)

	return NWB_GetStimsetFromSweepGeneric(sweep, numericalValues, textualValues)
End

/// @brief Get stimsets by analysing dataFolder of loaded sweep
///
/// numericalValues and textualValues are generated from previously loaded data.
/// used in the context of loading from a stored experiment file.
/// on load a sweep is stored in a device/dataFolder hierarchy.
///
/// @returns list of stimsets
Function/S NWB_GetStimsetFromSpecificSweep(dataFolder, device, sweep)
	string dataFolder, device
	variable sweep

	DFREF dfr = GetAnalysisLabNBFolder(dataFolder, device)
	WAVE/SDFR=dfr   numericalValues
	WAVE/SDFR=dfr/T textualValues

	return NWB_GetStimsetFromSweepGeneric(sweep, numericalValues, textualValues)
End

/// @brief Get related Stimsets by corresponding sweep
///
/// input numerical and textual values storage waves for current sweep
///
/// @returns list of stimsets
static Function/S NWB_GetStimsetFromSweepGeneric(sweep, numericalValues, textualValues)
	variable sweep
	WAVE numericalValues
	WAVE/T textualValues

	variable i, j, numEntries
	string ttlList, name
	string stimsetList = ""

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweep, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	if(!WaveExists(stimsets))
		return ""
	endif

	// handle AD/DA channels
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		name = stimsets[i]
		if(isEmpty(name))
			continue
		endif
		stimsetList = AddListItem(name, stimsetList)
	endfor

	WAVE/Z/T ttlStimSets = GetTTLstimSets(numericalValues, textualValues, sweep)

	// handle TTL channels
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!WaveExists(ttlStimsets))
			break
		endif

		name = ttlStimSets[i]
		if(isEmpty(name))
			continue
		endif
		stimsetList = AddListItem(name, stimsetList)
	endfor

	return stimsetList
End

static Function NWB_AppendSweepLowLevel(locationID, nwbVersion, panelTitle, DAQDataWave, DAQConfigWave, sweep, [compressionMode])
	variable locationID, nwbVersion
	string panelTitle
	WAVE DAQDataWave, DAQConfigWave
	variable sweep, compressionMode

	variable groupID, numEntries, i, j, ttlBits, dac, adc, col, refTime
	variable ttlBit, hardwareType, DACUnassoc, ADCUnassoc, index
	string group, path, list, name, stimset, key
	string channelSuffix, listOfStimsets, contents

	refTime = DEBUG_TIMER_START()

	if(ParamIsDefault(compressionMode))
		compressionMode = IPNWB#GetNoCompression()
	endif

	NVAR session_start_time = $GetSessionStartTimeReadBack()

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE/T numericalKeys = GetLBNumericalKeys(panelTitle)
	WAVE/T textualValues = GetLBTextualValues(panelTitle)
	WAVE/T textualKeys   = GetLBTextualKeys(panelTitle)

	Make/FREE/N=(DimSize(DAQDataWave, COLS)) writtenDataColumns = 0

	// comment denotes the introducing comment of the labnotebook entry
	// a2220e9f (Add the clamp mode to the labnotebook for acquired data, 2015-04-26)
	WAVE/Z clampMode = GetLastSetting(numericalValues, sweep, "Clamp Mode", DATA_ACQUISITION_MODE)

	if(!WaveExists(clampMode))
		WAVE/Z clampMode = GetLastSetting(numericalValues, sweep, "Operating Mode", DATA_ACQUISITION_MODE)
		ASSERT(WaveExists(clampMode), "Labnotebook is too old for NWB export.")
	endif

	// 5872e556 (Modified files: DR_MIES_TangoInteract:  changes recommended by Thomas ..., 2014-09-11)
	WAVE/Z DACs = GetLastSetting(numericalValues, sweep, "DAC", DATA_ACQUISITION_MODE)
	ASSERT(WaveExists(DACs), "Labnotebook is too old for NWB export.")

	// 5872e556 (Modified files: DR_MIES_TangoInteract:  changes recommended by Thomas ..., 2014-09-11)
	WAVE/D/Z ADCs = GetLastSetting(numericalValues, sweep, "ADC", DATA_ACQUISITION_MODE)

	if(!WaveExists(ADCs))
		WAVE/D/Z statusHS = GetLastSetting(numericalValues, sweep, "Headstage Active", DATA_ACQUISITION_MODE)
		ASSERT(WaveExists(statusHS), "Labnotebook is too old for NWB export (ADCs is missing and statusHS fixup is also broken.")

		WAVE configADCs = GetADCListFromConfig(DAQConfigWave)
		WAVE configDACs = GetDACListFromConfig(DAQConfigWave)

		if(DimSize(configADCs, ROWS) == 1 && DimSize(configDACs, ROWS) == 1 && Sum(statusHS, 0, NUM_HEADSTAGES - 1) == 1)
			// we have excactly one active headstage with one DA/AD, so we can fix things up
			index = GetRowIndex(statusHS, val=1)

			Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) ADCs = NaN
			ADCs[index] = configADCs[0]

			printf "Encountered an incorrect ADC state HS %d in sweep %d. Fixing it up locally.\r", index, sweep
			ControlWindowToFront()
		endif
	endif


	// 602debb9 (Record the active headstage in the settingsHistory, 2014-11-04)
	WAVE/D/Z statusHS = GetLastSetting(numericalValues, sweep, "Headstage Active", DATA_ACQUISITION_MODE)
	if(!WaveExists(statusHS))
		Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) statusHS = IsFinite(ADCs[p]) && IsFinite(DACs[p])
	endif

	// Turn on inadvertently turned off headstages again, see also
	// a4958aec (NWB_AppendSweepLowLevel: Fixup buggy active headstage states, 2019-02-28)
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(statusHS[i])
			// we don't fixup this case
			continue
		endif

		// check that the headstage is really turned off
		if(IsNaN(ADCs[i]) && IsNaN(DACs[i]))
			// no AD/DA channels for that headstage
			continue
		endif

		// only one channel is associated with a headstage
		if(IsNaN(ADCs[i]) || IsNaN(DACs[i]))
			// let's just export it as unassociated channel
			continue
		endif

		// now if the headstage is turned off but one of the AD/DA entries exist
		// this can be a buggy headstage state
		// we know that these AD/DA entries really belong to that headstate
		// if no unassociated entry exists
		key = CreateLBNUnassocKey("DAC", DACs[i], NaN)
		DACUnassoc = GetLastSettingIndep(numericalValues, sweep, key, DATA_ACQUISITION_MODE)

		key = CreateLBNUnassocKey("ADC", ADCs[i], NaN)
		ADCUnassoc = GetLastSettingIndep(numericalValues, sweep, key, DATA_ACQUISITION_MODE)

		if(IsNaN(DACUnassoc) && IsNan(ADCUnassoc))
			printf "Encountered an incorrect headstage state for HS %d in sweep %d. Turning that HS now on for the export.\r", i, sweep
			ControlWindowToFront()
			statusHS[i] = 1
		endif
	endfor

	ASSERT(Sum(statusHS, 0, NUM_HEADSTAGES - 1) >= 1, "Expected at least one active headstage.")

	// 1a4b8e59 (Changes to Tango Interact, 2014-09-03)
	WAVE/T/Z stimSets = GetLastSetting(textualValues, sweep, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	ASSERT(WaveExists(stimSets), "Labnotebook is too old for NWB export.")

	// 95402da6 (NWB: Allow documenting the physical electrode, 2016-08-05)
	WAVE/Z/T electrodeNames = GetLastSetting(textualValues, sweep, "Electrode", DATA_ACQUISITION_MODE)
	if(!WaveExists(electrodeNames))
		Make/FREE/T/N=(NUM_HEADSTAGES) electrodeNames = GetDefaultElectrodeName(p)
	else
		WAVE/Z nonEmptyElectrodes = FindIndizes(electrodeNames, col=0, prop=PROP_NON_EMPTY)
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
	params.startingTime = NWB_GetStartTimeOfSweep(panelTitle, sweep, DAQDataWave) - session_start_time
	ASSERT(params.startingTime > 0, "TimeSeries starting time can not be negative")

	params.samplingRate = ConvertSamplingIntervalToRate(GetSamplingInterval(DAQConfigWave)) * 1000

	DEBUGPRINT_ELAPSED(refTime)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		STRUCT IPNWB#TimeSeriesProperties tsp

		sprintf contents, "Headstage %d", i
		IPNWB#AddElectrode(locationID, electrodeNames[i], nwbVersion, contents, panelTitle)

		adc                    = ADCs[i]
		dac                    = DACs[i]
		params.electrodeNumber = i
		params.electrodeName   = electrodeNames[i]
		params.clampMode       = clampMode[i]
		params.stimset         = stimSets[i]

		if(IsFinite(adc))
			path                    = IPNWB#GetNWBgroupPatchClampSeries(nwbVersion)
			params.channelNumber    = ADCs[i]
			params.channelType      = XOP_CHANNEL_TYPE_ADC
			col                     = AFH_GetDAQDataColumn(DAQConfigWave, params.channelNumber, params.channelType)
			writtenDataColumns[col] = 1
			WAVE params.data        = ExtractOneDimDataFromSweep(DAQConfigWave, DAQDataWave, col)
			NWB_GetTimeSeriesProperties(nwbVersion, params, tsp)
			params.groupIndex    = IsFinite(params.groupIndex) ? params.groupIndex : IPNWB#GetNextFreeGroupIndex(locationID, path)
			IPNWB#WriteSingleChannel(locationID, path, nwbVersion, params, tsp, compressionMode = compressionMode)
		endif

		DEBUGPRINT_ELAPSED(refTime)

		if(IsFinite(dac))
			path                    = "/stimulus/presentation"
			params.channelNumber    = DACs[i]
			params.channelType      = XOP_CHANNEL_TYPE_DAC
			col                     = AFH_GetDAQDataColumn(DAQConfigWave, params.channelNumber, params.channelType)
			writtenDataColumns[col] = 1
			WAVE params.data        = ExtractOneDimDataFromSweep(DAQConfigWave, DAQDataWave, col)
			NWB_GetTimeSeriesProperties(nwbVersion, params, tsp)
			params.groupIndex    = IsFinite(params.groupIndex) ? params.groupIndex : IPNWB#GetNextFreeGroupIndex(locationID, path)
			IPNWB#WriteSingleChannel(locationID, path, nwbVersion, params, tsp, compressionMode = compressionMode)
		endif

		NWB_ClearWriteChannelParams(params)

		DEBUGPRINT_ELAPSED(refTime)
	endfor

	NWB_ClearWriteChannelParams(params)

	DEBUGPRINT_ELAPSED(refTime)

	// introduced in db531d20 (DC_PlaceDataInITCDataWave: Document the digitizer hardware type, 2018-07-30)
	// before that we only had ITC hardware
	hardwareType = GetLastSettingIndep(numericalValues, sweep, "Digitizer Hardware Type", DATA_ACQUISITION_MODE, defValue = HARDWARE_ITC_DAC)
	WAVE/Z/T ttlStimsets = GetTTLStimSets(numericalValues, textualValues, sweep)

	// i has the following meaning:
	// - ITC hardware: hardware channel
	// - NI hardware: DAEphys TTL channel
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!WaveExists(ttlStimsets))
			break
		endif

		if(hardwareType == HARDWARE_ITC_DAC)
			ttlBits = GetTTLBits(numericalValues, sweep, i)
			if(!IsFinite(ttlBits))
				continue
			endif

		elseif(hardwareType == HARDWARE_NI_DAC)
			ttlBits = NaN

			stimset = ttlStimsets[i]
			if(IsEmpty(stimset))
				continue
			endif
		else
			ASSERT(0, "unsupported hardware type")
		endif

		params.clampMode        = NaN
		params.channelNumber    = i
		params.channelType      = XOP_CHANNEL_TYPE_TTL
		params.electrodeNumber  = NaN
		params.electrodeName    = ""
		col                     = AFH_GetDAQDataColumn(DAQConfigWave, params.channelNumber, params.channelType)
		writtenDataColumns[col] = 1

		WAVE data = ExtractOneDimDataFromSweep(DAQConfigWave, DAQDataWave, col)

		if(hardwareType == HARDWARE_ITC_DAC)
			DFREF dfr = NewFreeDataFolder()
			SplitTTLWaveIntoComponents(data, ttlBits, dfr, "_", TTL_RESCALE_OFF)

			list = GetListOfObjects(dfr, ".*")
			numEntries = ItemsInList(list)
			for(j = 0; j < numEntries; j += 1)
				name = StringFromList(j, list)
				ttlBit = 2^str2num(name[1,inf])
				ASSERT((ttlBit & ttlBits) == ttlBit, "Invalid ttlBit")
				WAVE/SDFR=dfr params.data = $name
				path                 = "/stimulus/presentation"
				params.channelSuffix = num2str(ttlBit)
				params.channelSuffixDesc = NWB_SOURCE_TTL_BIT
				params.stimset       = ttlStimsets[log(ttlBit)/log(2)]
				NWB_GetTimeSeriesProperties(nwbVersion, params, tsp)
				params.groupIndex    = IsFinite(params.groupIndex) ? params.groupIndex : IPNWB#GetNextFreeGroupIndex(locationID, path)
				IPNWB#WriteSingleChannel(locationID, path, nwbVersion, params, tsp, compressionMode = compressionMode)
			endfor
		elseif(hardwareType == HARDWARE_NI_DAC)
			WAVE params.data     = data
			path                 = "/stimulus/presentation"
			params.stimset       = stimset
			NWB_GetTimeSeriesProperties(nwbVersion, params, tsp)
			params.groupIndex    = IsFinite(params.groupIndex) ? params.groupIndex : IPNWB#GetNextFreeGroupIndex(locationID, path)
			IPNWB#WriteSingleChannel(locationID, path, nwbVersion, params, tsp, compressionMode = compressionMode)
		endif

		NWB_ClearWriteChannelParams(params)
	endfor

	NWB_ClearWriteChannelParams(params)

	DEBUGPRINT_ELAPSED(refTime)

	numEntries = DimSize(writtenDataColumns, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(writtenDataColumns[i])
			continue
		endif

		// unassociated channel data
		params.clampMode       = NaN
		params.electrodeNumber = NaN
		params.electrodeName   = ""
		params.channelType     = DAQConfigWave[i][0]
		params.channelNumber   = DAQConfigWave[i][1]
		params.stimSet         = IPNWB_PLACEHOLDER

		switch(params.channelType)
			case XOP_CHANNEL_TYPE_ADC:
				path = IPNWB#GetNWBgroupPatchClampSeries(nwbVersion)
				break
			case XOP_CHANNEL_TYPE_DAC:
				path = "/stimulus/presentation"
				break
			default:
				ASSERT(0, "Unexpected channel type")
				break
		endswitch

		NWB_GetTimeSeriesProperties(nwbVersion, params, tsp)
		WAVE params.data       = ExtractOneDimDataFromSweep(DAQConfigWave, DAQDataWave, i)
		params.groupIndex      = IsFinite(params.groupIndex) ? params.groupIndex : IPNWB#GetNextFreeGroupIndex(locationID, path)
		IPNWB#WriteSingleChannel(locationID, path, nwbVersion, params, tsp, compressionMode = compressionMode)
		NWB_ClearWriteChannelParams(params)
	endfor

	DEBUGPRINT_ELAPSED(refTime)
End

/// @brief Clear all entries which are channel specific
static Function NWB_ClearWriteChannelParams(s)
	STRUCT IPNWB#WriteChannelParams &s

	string device
	variable sweep, startingTime, samplingRate, groupIndex

	// all entries except device and sweep will be cleared
	if(strlen(s.device) > 0)
		device = s.device
	endif

	sweep        = s.sweep
	startingTime = s.startingTime
	samplingRate = s.samplingRate
	groupIndex   = s.groupIndex

	// Clear wave elements before overwriting with a default initialized structure.
	// This avoids a memory leak. (Reported to WM)
	WaveClear s.data

	STRUCT IPNWB#WriteChannelParams defaultValues

	s = defaultValues

	if(strlen(device) > 0)
		s.device = device
	endif

	s.sweep        = sweep
	s.startingTime = startingTime
	s.samplingRate = samplingRate
	s.groupIndex   = groupIndex
End

/// @brief Save Custom Wave (from stimset) in NWB file
///
/// @param nwbVersion                                             major NWB version
/// @param locationID		                                      Open HDF5 group or file identifier
/// @param custom_wave		                                      Wave reference to the wave that is to be saved
/// @param compressionMode [optional, defaults to NO_COMPRESSION] Type of compression to use, one of @ref CompressionMode
static Function NWB_WriteStimsetCustomWave(nwbVersion, locationID, custom_wave, compressionMode)
	variable nwbVersion, locationID, compressionMode
	WAVE custom_wave

	variable groupID, i, numEntries
	string pathInNWB, custom_wave_name, path

	// build path for NWB file
	pathInNWB = GetWavesDataFolder(custom_wave, 1)
	pathInNWB = RemoveEnding(pathInNWB, ":")
	pathInNWB = RemovePrefix(pathInNWB, start = "root")
	pathInNWB = ReplaceString(":", pathInNWB, "/")
	pathInNWB = "/general/stimsets/referenced" + pathInNWB

	custom_wave_name = NameOfWave(custom_wave)

	IPNWB#H5_CreateGroupsRecursively(locationID, pathInNWB)
	groupID = IPNWB#H5_OpenGroup(locationID, pathInNWB)

	IPNWB#H5_WriteDataset(groupID, custom_wave_name, wv=custom_wave, compressionMode = compressionMode, overwrite=1, writeIgorAttr=1)

	if(nwbVersion == 2)
		IPNWB#WriteNeuroDataType(locationID, "/general/stimsets/referenced", "StimulusSetReferenced")

		path = ""
		numEntries = ItemsInList(pathInNWB, "/")
		for(i = 4; i < numEntries; i += 1)
			path += StringFromList(i, pathInNWB, "/")
			IPNWB#WriteNeuroDataType(locationID, "/general/stimsets/referenced/" + path, "StimulusSetReferencedFolder")
			path += "/"
		endfor

		IPNWB#WriteNeuroDataType(groupID, custom_wave_name, "StimulusSetReferencedWaveform")
	endif

	HDF5CloseGroup groupID
End

static Function NWB_WriteStimsetTemplateWaves(nwbVersion, locationID, stimSet, compressionMode)
	variable nwbVersion, locationID
	string stimSet
	variable compressionMode

	variable groupID
	string name, path

	path = "/general/stimsets"
	IPNWB#H5_CreateGroupsRecursively(locationID, path)
	groupID = IPNWB#H5_OpenGroup(locationID, path)

	if(nwbVersion == 1)
		IPNWB#MarkAsCustomEntry(locationID, path)
	elseif(nwbVersion == 2)
		IPNWB#WriteNeuroDataType(locationID, path, "StimulusSets")
	endif

	// write the stim set parameter waves only if all three exist
	if(WB_StimsetIsFromThirdParty(stimSet))
		WAVE/Z stimSetWave = WB_CreateAndGetStimSet(stimSet)

		if(!WaveExists(stimSetWave))
			printf "The stimset \"%s\" can not be exported as it can not be recreated.\r", stimset
			ControlWindowToFront()
			HDF5CloseGroup groupID
			return NaN
		endif

		stimset = NameOfWave(stimSetWave)
		IPNWB#H5_WriteDataset(groupID, stimset, wv=stimSetWave, compressionMode = compressionMode, overwrite=1, writeIgorAttr=1)

		if(nwbVersion == 2)
			IPNWB#WriteNeuroDataType(groupID, stimset, "StimulusSetWaveform")
		endif

		HDF5CloseGroup groupID
		return NaN
	endif

	WAVE WP  = WB_GetWaveParamForSet(stimSet)
	WAVE WPT = WB_GetWaveTextParamForSet(stimSet)
	WAVE SegWvType = WB_GetSegWvTypeForSet(stimSet)

	name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP, nwbFormat = 1)
	IPNWB#H5_WriteDataset(groupID, name, wv=WP, compressionMode = compressionMode, overwrite=1, writeIgorAttr=1)
	if(nwbVersion == 2)
		IPNWB#WriteNeuroDataType(groupID, name, "StimulusSetWavebuilderParameter")
	endif

	name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT, nwbFormat = 1)
	IPNWB#H5_WriteDataset(groupID, name, wv=WPT, compressionMode = compressionMode, overwrite=1, writeIgorAttr=1)
	if(nwbVersion == 2)
		IPNWB#WriteNeuroDataType(groupID, name, "StimulusSetWavebuilderParameterText")
	endif

	name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE, nwbFormat = 1)
	IPNWB#H5_WriteDataset(groupID, name, wv=SegWVType, compressionMode = compressionMode, overwrite=1, writeIgorAttr=1)
	if(nwbVersion == 2)
		IPNWB#WriteNeuroDataType(groupID, name, "StimulusSetWavebuilderSegmentTypes")
	endif

	HDF5CloseGroup groupID
End

/// @brief Load specified stimset from Stimset Group
///
/// @param locationID   id of an open hdf5 group containing the stimsets
/// @param stimset      string of stimset
/// @param verbose      [optional] set to get more output to the command line
/// @param overwrite    indicate whether the stored stimsets should be deleted if they exist
///
/// @return 1 on error
static Function NWB_LoadStimset(locationID, stimset, overwrite, [verbose])
	variable locationID, overwrite, verbose
	string stimset

	variable stimsetType
	string NWBstimsets, WP_name, WPT_name, SegWvType_name

	if(ParamIsDefault(verbose))
		verbose = 0
	endif

	// check if parameter waves exist
	if(!overwrite && WB_ParameterWavesExist(stimset))
		if(verbose > 0)
			printf "stimmset %s exists with parameter waves\r", stimset
			ControlWindowToFront()
		endif
		return 0
	endif

	// check if custom stimset exists
	if(!overwrite && WB_StimsetExists(stimset))
		WB_KillParameterWaves(stimset)
		if(verbose > 0)
			printf "stimmset %s exists as third party stimset\r", stimset
			ControlWindowToFront()
		endif
		return 0
	endif

	WB_KillParameterWaves(stimset)
	WB_KillStimset(stimset)

	// load stimsets with parameter waves
	stimsetType = GetStimSetType(stimset)
	DFREF paramDFR = GetSetParamFolder(stimsetType)

	// convert stimset name to upper case
	NWBstimsets = IPNWB#H5_ListGroupMembers(locationID, "./")
	WP_name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP, nwbFormat = 1)
	WP_name = StringFromList(WhichListItem(WP_name, NWBstimsets, ";", 0, 0), NWBstimsets)
	WPT_name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT, nwbFormat = 1)
	WPT_name = StringFromList(WhichListItem(WPT_name, NWBstimsets, ";", 0, 0), NWBstimsets)
	SegWvType_name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE, nwbFormat = 1)
	SegWvType_name = StringFromList(WhichListItem(SegWvType_name, NWBstimsets, ";", 0, 0), NWBstimsets)

	WAVE/Z   WP        = IPNWB#H5_LoadDataset(locationID, WP_name)
	WAVE/Z/T WPT       = IPNWB#H5_LoadDataset(locationID, WPT_name)
	WAVE/Z   SegWVType = IPNWB#H5_LoadDataset(locationID, SegWvType_name)
	if(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType))
		MoveWave WP,        paramDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP))
		MoveWave WPT,       paramDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT))
		MoveWave SegWVType, paramDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE))
	endif

	if(WB_ParameterWavesExist(stimset))
		return 0
	endif

	// load custom stimset if previous load failed
	WB_KillParameterWaves(stimset)

	if(IPNWB#H5_DatasetExists(locationID, stimset))
		WAVE/Z wv = IPNWB#H5_LoadDataset(locationID, stimset)
		if(!WaveExists(wv))
			DFREF setDFR = GetSetParamFolder(stimsetType)
			MoveWave wv setDFR
			return 0
		endif
	endif

	printf "Could not load stimset %s from NWB file.\r", stimset
	ControlWindowToFront()

	return 1
End

/// @brief Load a custom wave from NWB file
///
/// loads waves that were saved by NWB_WriteStimsetCustomWave
///
/// @param locationID  open file or group from nwb file
/// @param fullPath    full Path in igor notation to custom wave
/// @param overwrite   indicate whether the stored custom wave should be deleted if it exists
///
/// @return 1 on error and 0 on success
Function NWB_LoadCustomWave(locationID, fullPath, overwrite)
	variable locationID, overwrite
	string fullPath

	string pathInNWB

	WAVE/Z wv = $fullPath
	if(WaveExists(wv))
		if(overwrite)
			KillOrMoveToTrash(wv=wv)
		else
			return 0
		endif
	endif

	pathInNWB = RemovePrefix(fullPath, start = "root:")
	pathInNWB = ReplaceString(":", pathInNWB, "/")
	pathInNWB = "/general/stimsets/referenced/" + pathInNWB

	if(!IPNWB#H5_DatasetExists(locationID, pathInNWB))
		printf "custom wave \t%s not found in current NWB file on location \t%s\r", fullPath, pathInNWB
		return 1
	endif

	WAVE wv = IPNWB#H5_LoadDataset(locationID, pathInNWB)
	DFREF dfr = createDFWithAllParents(GetFolder(fullPath))
	MoveWave wv dfr

	return 0
End

/// @brief Load all stimsets from specified HDF5 file.
///
/// @param fileName         [optional, shows a dialog on default] provide full file name/path for loading stimset
/// @param overwrite        [optional, defaults to false] indicate if the stored stimset should be deleted before the load.
/// @param loadOnlyBuiltins [optional, defaults to false] load only builtin stimsets
/// @return 1 on error and 0 on success
Function NWB_LoadAllStimsets([overwrite, fileName, loadOnlyBuiltins])
	variable overwrite
	string fileName
	variable loadOnlyBuiltins

	variable fileID, groupID, error, numStimsets, i, refNum
	string stimsets, stimset, suffix, fullPath
	string loadedStimsets = ""

	if(ParamIsDefault(overwrite))
		overwrite = 0
	else
		overwrite = !!overwrite
	endif

	if(ParamIsDefault(loadOnlyBuiltins))
		loadOnlyBuiltins = 0
	else
		loadOnlyBuiltins = !!loadOnlyBuiltins
	endif

	if(ParamIsDefault(fileName))
		Open/D/R/M="Load all stimulus sets"/F="NWB Files:*.nwb;All Files:.*;" refNum

		if(IsEmpty(S_fileName))
			return NaN
		endif

		fullPath = S_fileName
	else
		fullPath = fileName
	endif

	fileID = IPNWB#H5_OpenFile(fullPath)

	if(!IPNWB#StimsetPathExists(fileID))
		printf "no stimsets present in %s\r", fullPath
		IPNWB#H5_CloseFile(fileID)
		return 1
	endif

	stimsets = IPNWB#ReadStimsets(fileID)
	if(ItemsInList(stimsets) == 0)
		IPNWB#H5_CloseFile(fileID)
		return 0
	endif

	// merge stimset Parameter Waves to one unique entry in stimsets list
	sprintf suffix, "_%s;", GetWaveBuilderParameterTypeName(STIMSET_PARAM_WP)
	stimsets = ReplaceString(suffix, stimsets, ";")
	sprintf suffix, "_%s;", GetWaveBuilderParameterTypeName(STIMSET_PARAM_WPT)
	stimsets = ReplaceString(suffix, stimsets, ";")
	sprintf suffix, "_%s;", GetWaveBuilderParameterTypeName(STIMSET_PARAM_SEGWVTYPE)
	stimsets = ReplaceString(suffix, stimsets, ";")
	stimsets = GetUniqueTextEntriesFromList(stimsets, caseSensitive=0)

	groupID = IPNWB#OpenStimset(fileID)
	numStimsets = ItemsInList(stimsets)
	for(i = 0; i < numStimsets; i += 1)
		stimset = StringFromList(i, stimsets)

		if(loadOnlyBuiltins && !WBP_IsBuiltinStimset(stimset))
			continue
		endif

		if(NWB_LoadStimset(groupID, stimset, overwrite, verbose = 1))
			printf "error loading stimset %s\r", stimset
			error = 1
			continue
		endif

		loadedStimsets = AddListItem(stimset, loadedStimsets)
	endfor

	NWB_LoadCustomWaves(groupID, loadedStimsets, overwrite)
	HDF5CloseGroup/Z groupID
	IPNWB#H5_CloseFile(fileID)

	WBP_UpdateDaEphysStimulusSetPopups()

	return error
End

/// @brief Load specified stimsets and their dependencies from NWB file
///
/// see AB_LoadStimsets() for similar structure
///
/// @param groupID           Open Stimset Group of HDF5 File. See IPNWB#OpenStimset()
/// @param stimsets          ";" separated list of all stimsets of the current sweep.
/// @param processedStimsets [optional] the list indicates which stimsets were already loaded.
///                          on recursion this parameter avoids duplicate circle references.
/// @param overwrite         indicate whether the stored stimsets should be deleted if they exist
///
/// @return 1 on error and 0 on success
Function NWB_LoadStimsets(groupID, stimsets, overwrite, [processedStimsets])
	variable groupID, overwrite
	string stimsets, processedStimsets

	string stimset, totalStimsets, newStimsets, oldStimsets
	variable numBefore, numMoved, numAfter, numNewStimsets, i

	if(ParamIsDefault(processedStimsets))
		processedStimsets = ""
	endif

	totalStimsets = stimsets + processedStimsets
	numBefore = ItemsInList(totalStimsets)

	// load first order stimsets
	numNewStimsets = ItemsInList(stimsets)
	for(i = 0; i < numNewStimsets; i += 1)
		stimset = StringFromList(i, stimsets)
		if(NWB_LoadStimset(groupID, stimset, overwrite))
			if(ItemsInList(processedStimsets) == 0)
				continue
			endif
			return 1
		endif
		numMoved += WB_StimsetFamilyNames(totalStimsets, parent = stimset)
	endfor
	numAfter = ItemsInList(totalStimsets)

	// load next order stimsets
	numNewStimsets = numAfter - numBefore + numMoved
	if(numNewStimsets > 0)
		newStimsets = ListFromList(totalStimsets, 0, numNewStimsets - 1)
		oldStimsets = ListFromList(totalStimsets, numNewStimsets, inf)
		return NWB_LoadStimsets(groupID, newStimsets, overwrite, processedStimsets = oldStimsets)
	endif

	return 0
End

/// @brief Load custom waves for specified stimset from Igor experiment file
///
/// see AB_LoadCustomWaves() for similar structure
///
/// @return 1 on error and 0 on success
Function NWB_LoadCustomWaves(groupID, stimsets, overwrite)
	variable groupID, overwrite
	string stimsets

	string custom_waves
	variable numWaves, i

	stimsets = WB_StimsetRecursionForList(stimsets)
	WAVE/T cw = WB_CustomWavesPathFromStimSet(stimsetList = stimsets)

	numWaves = DimSize(cw, ROWS)
	for(i = 0; i < numWaves; i += 1)
		if(NWB_LoadCustomWave(groupID, cw[i], overwrite))
			return 1
		endif
	endfor

	return 0
End

static Function NWB_GetTimeSeriesProperties(nwbVersion, p, tsp)
	variable nwbVersion
	STRUCT IPNWB#WriteChannelParams &p
	STRUCT IPNWB#TimeSeriesProperties &tsp

	WAVE/T numericalKeys = GetLBNumericalKeys(p.device)
	WAVE numericalValues = GetLBNumericalValues(p.device)

	IPNWB#InitTimeSeriesProperties(tsp, p.channelType, p.clampMode)

	// unassociated channel
	if(!IsFinite(p.clampMode))
		return NaN
	endif

	if(strlen(tsp.missing_fields) > 0)
		ASSERT(IsFinite(p.electrodeNumber), "Expected finite electrode number with non empty \"missing_fields\"")
	endif

	if(p.channelType == XOP_CHANNEL_TYPE_ADC)
		if(p.clampMode == V_CLAMP_MODE)
			// VoltageClampSeries: datasets
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "Fast compensation capacitance", "capacitance_fast", p.electrodeNumber, tsp)
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "Slow compensation capacitance", "capacitance_slow", p.electrodeNumber, tsp)
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "RsComp Bandwidth", "resistance_comp_bandwidth", p.electrodeNumber, tsp, factor=1e3, enabledProp="RsComp Enable")
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "RsComp Correction", "resistance_comp_correction", p.electrodeNumber, tsp, enabledProp="RsComp Enable")
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "RsComp Prediction", "resistance_comp_prediction", p.electrodeNumber, tsp, enabledProp="RsComp Enable")
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "Whole Cell Comp Cap", "whole_cell_capacitance_comp", p.electrodeNumber, tsp, factor=1e-12, enabledProp="Whole Cell Comp Enable")
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "Whole Cell Comp Resist", "whole_cell_series_resistance_comp", p.electrodeNumber, tsp, factor=1e6, enabledProp="Whole Cell Comp Enable")
		elseif(p.clampMode == I_CLAMP_MODE)
			// CurrentClampSeries: datasets
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "I-Clamp Holding Level", "bias_current", p.electrodeNumber, tsp, enabledProp="I-Clamp Holding Enable")
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "Bridge Bal Value", "bridge_balance", p.electrodeNumber, tsp, enabledProp="Bridge Bal Enable")
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "Neut Cap Value", "capacitance_compensation", p.electrodeNumber, tsp, enabledProp="Neut Cap Enabled")
		elseif(p.clampMode == I_EQUAL_ZERO_MODE)
			// IZeroClampSeries: datasets
			IPNWB#AddProperty(tsp, "bias_current", 0.0, unit = "A")
			IPNWB#AddProperty(tsp, "bridge_balance", 0.0, unit = "Ohm")
			IPNWB#AddProperty(tsp, "capacitance_compensation", 0.0, unit = "F")
		endif

		// PatchClampSeries
		if(WhichListItem("PatchClampSeries", IPNWB#DetermineDataTypeRefTree(IPNWB#DetermineDataTypeFromProperties(p.channelType, p.clampMode))) != -1)
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "AD Gain", "gain", p.electrodeNumber, tsp)
		endif
	elseif(p.channelType == XOP_CHANNEL_TYPE_DAC)
		// PatchClampSeries
		if(WhichListItem("PatchClampSeries", IPNWB#DetermineDataTypeRefTree(IPNWB#DetermineDataTypeFromProperties(p.channelType, p.clampMode))) != -1)
			NWB_AddSweepDataSets(numericalKeys, numericalValues, p.sweep, "DA Gain", "gain", p.electrodeNumber, tsp)
		endif

		if(nwbVersion == 1)
			WAVE/Z values = GetLastSetting(numericalValues, p.sweep, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
			if(WaveExists(values) || IsFinite(values[p.electrodeNumber]))
				IPNWB#AddCustomProperty(tsp, "scale", values[p.electrodeNumber])
			endif
		endif
	endif
End

static Function NWB_AddSweepDataSets(numericalKeys, numericalValues, sweep, settingsProp, nwbProp, headstage, tsp, [factor, enabledProp])
	WAVE/T numericalKeys
	WAVE numericalValues
	variable sweep
	string settingsProp, nwbProp
	variable headstage
	STRUCT IPNWB#TimeSeriesProperties &tsp
	variable factor
	string enabledProp

	string lbl, unit
	variable col

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

	if(GetKeyWaveParameterAndUnit(numericalKeys, settingsProp, lbl, unit, col))
		IPNWB#AddProperty(tsp, nwbProp, values[headstage] * factor)
	else
		IPNWB#AddProperty(tsp, nwbProp, values[headstage] * factor, unit = unit)
	endif
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

/// @brief Flushes the contents of the NWB file to disc
Function NWB_Flush()
	SVAR filePathExport = $GetNWBFilePathExport()
	NVAR fileIDExport   = $GetNWBFileIDExport()

	if(!IsFinite(fileIDExport) || !IPNWB#H5_IsFileOpen(fileIDExport))
		return NaN
	endif

	fileIDExport = IPNWB#H5_FlushFile(fileIDExport, filePathExport, write = 1)
End

static Function NWB_AppendIgorHistory(nwbVersion, locationID)
	variable nwbVersion, locationID

	variable groupID
	string history, name

	IPNWB#EnsureValidNWBVersion(nwbVersion)
	ASSERT(IPNWB#GetNWBMajorVersion(IPNWB#ReadNWBVersion(locationID)) == nwbVersion, "NWB version of the selected file differs.")

	history = GetHistoryNotebookText()

	if(nwbVersion == 1)
		name = "history"
	elseif(nwbVersion == 2)
		name = "data_collection"
	endif

	groupID = IPNWB#H5_OpenGroup(locationID, "/general")
	ASSERT(!IsNaN(groupID), "IPNWB#CreateCommonGroups() needs to be called prior to this call")
	history = NormalizeToEOL(history, "\n")
	IPNWB#H5_WriteTextDataset(groupID, name, str=history, compressionMode = IPNWB#GetChunkedCompression(), overwrite=1, writeIgorAttr=0)

	if(nwbVersion == 1)
		IPNWB#MarkAsCustomEntry(groupID, name)
	endif

	HDF5CloseGroup/Z groupID
End

/// @brief Start the thread group responsible for interacting with the NWB file
Function NWB_StartThreadGroup()
	string panelTitle

	NVAR tgID = $GetNWBThreadID()

	TS_StopThreadGroup(tgID)
	tgID = ThreadGroupCreate(1)

	ThreadStart tgID, 0, NWB_SendFlush()
End

/// @brief Worker function for the NWB thread group
///
/// Actions for variables in the input queue:
/// - `abort`: worker function will quit
/// - `flushID`: HDF5FlushFile will be called and the contents of the variable
///              treated as HDF5 fileID
threadsafe Function NWB_SendFlush()
	for(;;)
		DFREF dfr = ThreadGroupGetDFR(MAIN_THREAD, 100)

		if(!DataFolderExistsDFR(dfr))
			continue
		endif

		NVAR/Z/SDFR=dfr abort

		if(NVAR_Exists(abort))
			DEBUGPRINT_TS("NWB_SendFlush: stopping")
			break
		endif

		NVAR/Z/SDFR=dfr flushID
		ASSERT_TS(NVAR_Exists(flushID), "Missing flush variable")

		HDF5FlushFile flushID; AbortOnRTE
		DEBUGPRINT_TS("NWB_SendFlush: flushing")
	endfor
End
