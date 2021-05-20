#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=TestNWBExportV2

static Constant NWB_VERSION = 2

 // This file does not hold test suites
static Function NoTestSuite()
	FAIL()
End

// We want to check that the stored specification versions are the correct ones compared to the
// `/nwb_version` attribute and the path components in `/specifications/core/X.Y.Z` and `/specifications/hdmf-common/A.B.C`
//
// In case that fails here check NWB_SPEC_VERSION, HDMF_SPEC_VERSION, NWB_VERSION in IPNWB
static Function TestSpecVersions(fileID)
	variable fileID

	string groups, expected, version, group, groupVersion, namespaceVersion, globalVersion
	string path, spec
	variable numEntries, i, jsonID

	globalVersion = IPNWB#ReadTextAttributeAsString(fileID, "/", "nwb_version")

	groups = IPNWB#H5_ListGroups(fileID, "/specifications")
	groups = SortList(groups)
	expected = "core;hdmf-common;ndx-mies;"
	CHECK_EQUAL_STR(groups, expected)

	numEntries = ItemsInList(groups)
	for(i = 0; i < numEntries; i += 1)
		group = StringFromList(i, groups)

		path = "/specifications/" + group
		groupVersion = IPNWB#H5_ListGroups(fileID, path)
		groupVersion = RemoveEnding(groupVersion, ";")

		if(!cmpstr(group, "core"))
			CHECK_EQUAL_STR(groupVersion, globalVersion)
		endif

		path += "/" + groupVersion + "/namespace"
		spec = IPNWB#ReadTextDataSetAsString(fileID, path)
		jsonID = JSON_Parse(spec)
		namespaceVersion = JSON_GetString(jsonID, "/namespaces/0/version")
		CHECK_EQUAL_STR(groupVersion, namespaceVersion)
		JSON_Release(jsonID)
	endfor
End

static Function TestHistory(fileID)
	variable fileID

	WAVE/Z/T history = IPNWB#H5_LoadDataSet(fileID, "/general/data_collection")
	CHECK_WAVE(history, TEXT_WAVE)
	CHECK(DimSize(history, ROWS) > 0)

	WAVE/Z/T matches = GrepTextWave(history, LOGFILE_NWB_MARKER)
	CHECK_WAVE(history, TEXT_WAVE)
End

static Function TestLabnotebooks(fileID, device)
	variable fileID
	string device

	string lbnDevices, prefix

	WAVE numericalValues = RemoveUnusedRows(GetLBNumericalValues(device))
	WAVE/T numericalKeys = GetLBNumericalKeys(device)
	WAVE/T textualValues = RemoveUnusedRows(GetLBTextualValues(device))
	WAVE/T textualKeys = GetLBTextualKeys(device)

	lbnDevices = RemoveEnding(IPNWB#ReadLabNoteBooks(fileID), ";")
	WARN_EQUAL_STR(lbnDevices, device)
	lbnDevices = StringFromList(0, lbnDevices)
	CHECK_EQUAL_STR(lbnDevices, device)

	prefix = "/general/labnotebook/" + device + "/"

	WAVE/Z numericalKeysNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "numericalKeys")
	CHECK_EQUAL_WAVES(numericalKeysNWB, numericalKeys)
	WAVE/Z numericalValuesNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "numericalValues")
	CHECK_EQUAL_WAVES(numericalValuesNWB, numericalValues)
	WAVE/Z textualKeysNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "textualKeys")
	CHECK_EQUAL_WAVES(textualKeysNWB, textualKeys)
	WAVE/Z textualValuesNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "textualValues")
	CHECK_EQUAL_WAVES(textualValuesNWB, textualValues)
End

static Function TestTPStorage(fileID, device)
	variable fileID
	string device

	string prefix

	prefix = "/general/testpulse/" + device + "/"
	WAVE/Z TPStorageNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "TPStorage")
	WAVE/Z TPStorage = RemoveUnusedRows(GetTPStorage(device))

	if(!WaveExists(TPStorageNWB) && !WaveExists(TPStorage))
		PASS()
	else
		CHECK_EQUAL_WAVES(TPStorageNWB, TPStorage)
	endif
End

static Function TestStoredTestPulses(fileID, device)
	variable fileID
	string device

	string prefix, datasets, dataset, idxstr
	variable numPulses, i, numEntries, idx

	WAVE/WAVE storedTestPulses = GetStoredTestPulseWave(device)
	numPulses = GetNumberFromWaveNote(storedTestPulses, NOTE_INDEX)

	prefix = "/general/testpulse/" + device + "/"

	datasets = IPNWB#H5_ListGroupMembers(fileID, prefix)
	// remove TPStorage entries
	datasets = GrepList(datasets, TP_STORAGE_REGEXP, 1)

	numEntries = ItemsInList(datasets)
	CHECK_EQUAL_VAR(numEntries, numPulses)

	for(i = 0; i < numEntries; i += 1)
		dataset = StringFromList(i, datasets)

		WAVE/Z TestPulseNWB = IPNWB#H5_LoadDataSet(fileID, prefix + dataset)

		SplitString/E=STORED_TESTPULSES_REGEXP dataset, idxStr
		CHECK_EQUAL_VAR(V_Flag, 1)

		idx = str2num(idxStr)
		CHECK(idx >= 0)

		WAVE/Z TestPulsePXP = storedTestPulses[idx]
		CHECK_EQUAL_WAVES(TestPulseNWB, TestPulsePXP)
	endfor
End

static Function TestStimsetParamWaves(fileID, device, sweeps)
	variable fileID
	string device
	WAVE sweeps

	variable i, j, numEntries, sweep
	string stimsetParamsNWB, stimset, prefix, name

	WAVE/T textualValues = GetLBTextualValues(device)

	stimsetParamsNWB = IPNWB#H5_ListGroupMembers(fileID, "/general/stimsets")
	CHECK(ItemsInList(stimsetParamsNWB) > 0)

	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweep = sweeps[i]

		if(!IsValidSweepNumber(sweep))
			break
		endif

		WAVE/T/Z stimsets = GetLastSetting(textualValues, sweep, "Stim Wave Name", DATA_ACQUISITION_MODE)
		CHECK_WAVE(stimsets, TEXT_WAVE)

		for(j = 0; j < NUM_HEADSTAGES; j += 1)
			stimset = stimsets[j]

			if(IsEmpty(stimset))
				break
			endif

			if(!cmpstr(stimset, STIMSET_TP_WHILE_DAQ))
				continue
			endif

			WAVE/Z WP  = WB_GetWaveParamForSet(stimset)
			WAVE/Z WPT = WB_GetWaveTextParamForSet(stimset)
			WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimset)

			prefix = "/general/stimsets/"

			name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP, nwbFormat = 1)
			WAVE/Z WP_NWB = IPNWB#H5_LoadDataSet(fileID, prefix + name)
			CHECK_EQUAL_WAVES(WP_NWB, WP)

			name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT, nwbFormat = 1)
			WAVE/Z WPT_NWB = IPNWB#H5_LoadDataSet(fileID, prefix + name)
			CHECK_EQUAL_WAVES(WPT_NWB, WPT)

			name =  WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE, nwbFormat = 1)
			WAVE/Z SegWvType_NWB = IPNWB#H5_LoadDataSet(fileID, prefix + name)
			CHECK_EQUAL_WAVES(SegWvType_NWB, SegWvType)
		endfor
	endfor
End

static Function TestTimeSeriesProperties(groupID, channel)
	variable groupID
	string channel

	variable numEntries, i, value, channelGroupID

	channelGroupID = IPNWB#H5_OpenGroup(groupID, channel)

	// TimeSeries properties
	STRUCT IPNWB#TimeSeriesProperties tsp
	IPNWB#ReadTimeSeriesProperties(groupID, channel, tsp)

	numEntries = DimSize(tsp.names, ROWS)
	for(i = 0; i < numEntries; i += 1)
		value = IPNWB#ReadDatasetAsNumber(channelGroupID, tsp.names[i])
		CHECK_EQUAL_VAR(value, tsp.data[i])
	endfor

	HDF5CloseGroup/Z channelGroupID
End

static Function/S GetChannelNameFromChannelType(groupID, device, channel, sweep, params)
	variable groupID
	string device
	string channel
	variable sweep
	STRUCT IPNWB#ReadChannelParams &params

	WAVE numericalValues = GetLBNumericalValues(device)

	string channelName, key
	variable entry, index

	switch(params.channelType)
		case XOP_CHANNEL_TYPE_DAC:
			channelName = "DA"
			WAVE loadedFromNWB = IPNWB#LoadStimulus(groupID, channel)
			channelName += "_" + num2str(params.channelNumber)

			if(IsNaN(params.electrodeNumber))
				WAVE/Z settings
				[settings, index] = GetLastSettingChannel(numericalValues, $"", sweep, "DAC", params.channelNumber, params.channelType, DATA_ACQUISITION_MODE)
				entry = settings[index]
			else
				WAVE/Z settings = GetLastSetting(numericalValues, sweep, "DAC", DATA_ACQUISITION_MODE)
				CHECK_WAVE(settings, NUMERIC_WAVE)
				entry = settings[params.electrodeNumber]
			endif

			CHECK_EQUAL_VAR(entry, params.channelNumber)
			break
		case XOP_CHANNEL_TYPE_ADC:
			channelName = "AD"
			WAVE loadedFromNWB = IPNWB#LoadTimeseries(groupID, channel, NWB_VERSION)
			channelName += "_" + num2str(params.channelNumber)

			if(IsNaN(params.electrodeNumber))
				WAVE/Z settings
				[settings, index] = GetLastSettingChannel(numericalValues, $"", sweep, "ADC", params.channelNumber, params.channelType, DATA_ACQUISITION_MODE)
				entry = settings[index]
			else
				WAVE/Z settings = GetLastSetting(numericalValues, sweep, "ADC", DATA_ACQUISITION_MODE)
				CHECK_WAVE(settings, NUMERIC_WAVE)
				entry = settings[params.electrodeNumber]
			endif

			CHECK_EQUAL_VAR(entry, params.channelNumber)
			break
		case XOP_CHANNEL_TYPE_TTL:
			channelName  = "TTL"
			WAVE loadedFromNWB = IPNWB#LoadStimulus(groupID, channel)
			channelName += "_" + num2str(params.channelNumber)

			if(IsFinite(params.ttlBit))
				channelName += "_" + num2str(log(params.ttlBit)/log(2))
			endif

			CHECK_EQUAL_VAR(str2num(params.channelSuffix), params.ttlBit)
			break
		default:
			ASSERT(0, "unknown channel type " + num2str(params.channelType))
			break
	endswitch

	return channelName
End

static Function/WAVE LoadTimeSeries(groupID, channel, channelType)
	variable groupID, channelType
	string channel

	switch(channelType)
		case XOP_CHANNEL_TYPE_DAC:
			return IPNWB#LoadStimulus(groupID, channel)
			break
		case XOP_CHANNEL_TYPE_ADC:
			return IPNWB#LoadTimeseries(groupID, channel, NWB_VERSION)
			break
		case XOP_CHANNEL_TYPE_TTL:
			return IPNWB#LoadStimulus(groupID, channel)
			break
		default:
			ASSERT(0, "unknown channel type " + num2str(channelType))
			break
	endswitch
End

static Function TestTimeSeries(fileID, filepath, device, groupID, channel, sweep, pxpSweepsDFR)
	variable fileID, groupID, sweep
	string filepath
	string channel, device
	DFREF pxpSweepsDFR

	variable channelGroupID, starting_time, session_start_time, actual
	variable clampMode, gain, gain_ref, resolution, conversion, headstage, rate_ref, rate, samplingInterval, samplingInterval_ref
	string stimulus, stimulus_expected, channelName, str, path, neurodata_type
	string electrode_name, electrode_name_ref, key, unit_ref, unit, base_unit_ref

	STRUCT IPNWB#ReadChannelParams params
	IPNWB#InitReadChannelParams(params)
	IPNWB#AnalyseChannelName(channel, params)

	channelGroupID = IPNWB#H5_OpenGroup(groupID, channel)

	string headstageDesc = IPNWB#ReadTextDataSetAsString(channelGroupID, "electrode/description")
	if(!cmpstr(headstageDesc, "PLACEHOLDER"))
		headstage = NaN
	else
		headstage = str2num(RemovePrefix(headstageDesc, start = "Headstage "))
		REQUIRE(headstage >= 0 && headstage < NUM_HEADSTAGES)
	endif

	params.electrodeNumber = headstage

	channelName = GetChannelNameFromChannelType(groupID, device, channel, sweep, params)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues = GetLBTextualValues(device)

	WAVE loadedFromNWB = LoadTimeSeries(groupID, channel, params.channelType)

	// starting_time
	starting_time = IPNWB#ReadDataSetAsNumber(channelGroupID, "starting_time")
	session_start_time = ParseISO8601Timestamp(IPNWB#ReadTextDataSetAsString(fileID, "/session_start_time"))
	actual = ParseISO8601Timestamp(GetLastSettingTextIndep(textualValues, sweep, HIGH_PREC_SWEEP_START_KEY, DATA_ACQUISITION_MODE))
	CHECK_EQUAL_VAR(session_start_time + starting_time, actual)

	// its attributes: unit
	unit = IPNWB#ReadTextAttributeAsString(groupID, channel + "/starting_time", "unit")
	unit_ref = "Seconds"
	CHECK_EQUAL_STR(unit, unit_ref)

	unit = WaveUnits(loadedFromNWB, ROWS)
	unit_ref = "ms"
	CHECK_EQUAL_STR(unit, unit_ref)

	// and rate
	rate = IPNWB#ReadAttributeAsNumber(groupID, channel + "/starting_time", "rate")
	rate_ref = 1 / (DimDelta(loadedFromNWB, ROWS)/1000)
	CHECK_CLOSE_VAR(rate, rate_ref, tol=1e-7)

	samplingInterval = GetLastSettingIndep(numericalValues, sweep, "Sampling interval", DATA_ACQUISITION_MODE)
	samplingInterval_ref = DimDelta(loadedFromNWB, ROWS)
	CHECK_CLOSE_VAR(samplingInterval, samplingInterval_ref, tol=1e-7)

	// stimulus_description
	stimulus = IPNWB#ReadTextAttributeAsString(channelGroupID, ".", "stimulus_description")
	if(params.channelType == XOP_CHANNEL_TYPE_DAC && IsNaN(params.electrodeNumber))
		stimulus_expected = "PLACEHOLDER"
	elseif(params.channelType == XOP_CHANNEL_TYPE_ADC && IsNaN(params.electrodeNumber)) // unassoc AD
		stimulus_expected = "PLACEHOLDER"
	elseif(params.channelType == XOP_CHANNEL_TYPE_TTL)
		WAVE/T/Z TTLStimsets = GetTTLStimSets(numericalValues, textualValues, sweep)
		CHECK_WAVE(TTLStimsets, TEXT_WAVE)

		if(IsNaN(params.ttlBit))
			stimulus_expected = TTLStimsets[params.channelNumber]
		else
			stimulus_expected = TTLStimsets[log(params.ttlBit)/log(2)]
		endif
	else
		WAVE/Z/T wvText = GetLastSetting(textualValues, sweep, "Stim Wave Name", DATA_ACQUISITION_MODE)
		CHECK_WAVE(wvText, TEXT_WAVE)
		stimulus_expected = wvText[params.electrodeNumber]
	endif
	CHECK_EQUAL_STR(stimulus, stimulus_expected)

	// electrode_name, only present for associated channels
	if(IsFinite(params.electrodeNumber))
		electrode_name = IPNWB#ReadElectrodeName(filePath, channel, NWB_VERSION)
		electrode_name_ref = num2str(params.electrodeNumber)
		CHECK_EQUAL_STR(electrode_name, electrode_name_ref)
	endif

	// neurodata_type
	WAVE/Z wv = GetLastSetting(numericalValues, sweep, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_WAVE(wv, NUMERIC_WAVE)

	clampMode = IsFinite(params.electrodeNumber) ? wv[params.electrodeNumber] : NaN

	neurodata_type = IPNWB#ReadNeuroDataType(groupID, channel)
	switch(clampMode)
		case V_CLAMP_MODE:
			if(params.channelType == XOP_CHANNEL_TYPE_ADC)
				str = "VoltageClampSeries"
				CHECK_EQUAL_STR(neurodata_type, str)
			elseif(params.channelType == XOP_CHANNEL_TYPE_DAC)
				str = "VoltageClampStimulusSeries"
				CHECK_EQUAL_STR(neurodata_type, str)
			else
				FAIL()
			endif
			break
		case  I_CLAMP_MODE:
			if(params.channelType == XOP_CHANNEL_TYPE_ADC)
				str = "CurrentClampSeries"
				CHECK_EQUAL_STR(neurodata_type, str)
			elseif(params.channelType == XOP_CHANNEL_TYPE_DAC)
				str = "CurrentClampStimulusSeries"
				CHECK_EQUAL_STR(neurodata_type, str)
			else
				FAIL()
			endif
			break
		case I_EQUAL_ZERO_MODE:
			if(params.channelType == XOP_CHANNEL_TYPE_ADC)
				str = "IZeroClampSeries"
				CHECK_EQUAL_STR(neurodata_type, str)
			else
				FAIL()
			endif
			break
		default:
			if(IsNaN(clampMode))
				str = "TimeSeries"
				CHECK_EQUAL_STR(neurodata_type, str)
			else
				ASSERT(0, "unknown clamp mode")
			endif
			break
	endswitch

	// gain
	if(IsFinite(params.electrodeNumber))
		REQUIRE_NEQ_VAR(params.channelType, NaN)
		key = StringFromList(params.channelType, XOP_CHANNEL_NAMES) + " Gain"
		WAVE/Z gains = GetLastSetting(numericalValues, sweep, key, DATA_ACQUISITION_MODE)
		CHECK_WAVE(gains, NUMERIC_WAVE)

		gain_ref = gains[params.electrodeNumber]
		gain = IPNWB#ReadDatasetAsNumber(channelGroupID, "gain")
		CHECK_CLOSE_VAR(gain, gain_ref, tol = 1e-6)
	endif

	// data.resolution
	resolution = IPNWB#ReadDatasetAsNumber(channelGroupID, "resolution")
	CHECK_EQUAL_VAR(resolution, NaN)

	// data.conversion
	// data.unit
	WAVE/Z/SDFR=pxpSweepsDFR pxpWave = $channelName
	REQUIRE_WAVE(pxpWave, NUMERIC_WAVE)
	unit_ref = WaveUnits(pxpWave, -1)

	if(!cmpstr(unit_ref, "pA"))
		conversion = IPNWB#ReadAttributeAsNumber(channelGroupID, "data", "conversion")
		CHECK_CLOSE_VAR(conversion, 1e-12)

		unit = IPNWB#ReadTextAttributeAsString(channelGroupID, "data", "unit")

		// translate back to hardcoded units
		base_unit_ref = "amperes"

		CHECK_EQUAL_STR(unit, base_unit_ref)
	elseif(!cmpstr(unit_ref, "mV"))
		conversion = IPNWB#ReadAttributeAsNumber(channelGroupID, "data", "conversion")
		CHECK_CLOSE_VAR(conversion, 1e-3, tol = 1e-5)

		unit = IPNWB#ReadTextAttributeAsString(channelGroupID, "data", "unit")

		// translate back to hardcoded units
		base_unit_ref = "volts"

		CHECK_EQUAL_STR(unit, base_unit_ref)
	elseif(IsEmpty(unit_ref)) // TTL data
		conversion = IPNWB#ReadAttributeAsNumber(channelGroupID, "data", "conversion")
		CHECK_CLOSE_VAR(conversion, 1)

		unit = IPNWB#ReadTextAttributeAsString(channelGroupID, "data", "unit")
		base_unit_ref = "a.u."
		CHECK_EQUAL_STR(unit, base_unit_ref)
	else
		FAIL()
	endif
End

static Function/DF TestSweepData(entry, device, sweep)
	WAVE/T entry
	string device
	variable sweep

	variable ret, i, numEntries, headstage
	string nwbSweeps, pxpSweeps, pxpSweepsClean, name, channelTypeStr, channelNumberStr, channelSuffix

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues = GetLBTextualValues(device)

	ret = MIES_AB#AB_LoadSweepFromFile(entry[%DiscLocation], entry[%DataFolder], entry[%FileType], device, sweep)
	CHECK_EQUAL_VAR(ret, 0)

	DFREF nwbSweepsDFR = GetAnalysisSweepDataPath(entry[%DataFolder], device, sweep)

	// sweep waves in the PXP
	WAVE/Z sweepWave = GetSweepWave(device, sweep)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	DFREF pxpSweepsDFR = UniqueDataFolder(GetDataFolderDFR(), "pxpSweeps")
	SplitSweepIntoComponents(numericalValues, sweep, sweepWave, configWave, TTL_RESCALE_OFF, targetDFR=pxpSweepsDFR)

	nwbSweeps = SortList(GetListOfObjects(nwbSweepsDFR, ".*"))
	pxpSweeps = SortList(GetListOfObjects(pxpSweepsDFR, ".*"))

	// remove backup waves
	nwbSweeps = GrepList(nwbSweeps, ".*\\Q" + WAVE_BACKUP_SUFFIX + "\\E$", 1)
	pxpSweeps = GrepList(pxpSweeps, ".*\\Q" + WAVE_BACKUP_SUFFIX + "\\E$", 1)

	// remove IZero DA channels as we don't save these in NWB
	pxpSweepsClean = ""
	numEntries = ItemsInList(pxpSweeps)
	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, pxpSweeps)

		SplitString/E="^([[:alpha:]]+)_([[:digit:]]+)(?:_.*)?$" name, channelTypeStr, channelNumberStr, channelSuffix
		CHECK_EQUAL_VAR(V_Flag, 2)

		WAVE DAC = GetLastSetting(numericalValues, sweep, "DAC", DATA_ACQUISITION_MODE)
		headstage = GetRowIndex(DAC, val=str2num(channelNumberStr))
		if(IsFinite(headstage))
			WAVE clampMode = GetLastSetting(numericalValues, sweep, "Clamp Mode", DATA_ACQUISITION_MODE)

			if(clampMode[headstage] == I_EQUAL_ZERO_MODE \
			   && !cmpstr(channelTypeStr, StringFromList(XOP_CHANNEL_TYPE_DAC, XOP_CHANNEL_NAMES)))
				continue
			endif
		endif

		pxpSweepsClean = AddListItem(name, pxpSweepsClean, ";", inf)
	endfor

	CHECK_EQUAL_STR(nwbSweeps, pxpSweepsClean)

	numEntries = ItemsInList(nwbSweeps)
	for(i = 0; i < numEntries; i += 1)
		WAVE/Z/SDFR=nwbSweepsDFR nwbWave = $StringFromList(i, nwbSweeps)
		CHECK_WAVE(nwbWave, NORMAL_WAVE)
		WAVE/Z/SDFR=pxpSweepsDFR pxpWave = $StringFromList(i, pxpSweepsClean)
		CHECK_WAVE(pxpWave, NORMAL_WAVE)
		CHECK_EQUAL_WAVES(nwbWave, pxpWave, mode = WAVE_DATA | WAVE_DATA_TYPE | WAVE_SCALING | DATA_UNITS | DIMENSION_UNITS | DIMENSION_LABELS | DATA_FULL_SCALE | DIMENSION_SIZES) // all except WAVE_NOTE
	endfor

	return pxpSweepsDFR
End

static Function/S TestFileExport()

	string baseFolder, nwbFile, discLocation

	[baseFolder, nwbFile] = GetUniqueNWBFileForExport(NWB_VERSION)
	discLocation = baseFolder + nwbFile

	HDF5CloseFile/Z/A 0
	KillOrMoveToTrash(dfr = GetAnalysisFolder())

	NWB_ExportAllData(NWB_VERSION, compressionMode = IPNWB#GetNoCompression(), writeStoredTestPulses = 1, overrideFilePath=discLocation)

	GetFileFolderInfo/Q/Z discLocation
	REQUIRE(V_IsFile)

	CHECK_EQUAL_VAR(MIES_AB#AB_AddFile(baseFolder, discLocation), 0)

	return discLocation
End

static Function TestListOfGroups(groupList, wv)
	string groupList
	WAVE/T wv

	variable index
	string list

	index = GetNumberFromWaveNote(wv, NOTE_INDEX)
	CHECK(index >= 1)

	groupList = SortList(groupList)

	Duplicate/FREE/T/R=[0, index - 1] wv, wvFilled
	wvFilled[] = RemoveEnding(wvFilled[p], ";")
	list = SortList(TextWaveToList(wvFilled, ";"))
	CHECK_EQUAL_STR(groupList, list)
End

Function TestNwbExportV2()
	string discLocation, device
	string channel
	variable fileID, numEntries, i, sweep, numGroups, j, groupID

	discLocation = TestFileExport()

	WAVE/T/Z entry = AB_GetMap(discLocation)
	CHECK_WAVE(entry, FREE_WAVE)

	WAVE/T/Z devices = GetAnalysisDeviceWave(entry[%DataFolder])
	CHECK_WAVE(devices, NORMAL_WAVE)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(devices, NOTE_INDEX), ItemsInList(Getalldevices()))
	WARN_EQUAL_VAR(GetNumberFromWaveNote(devices, NOTE_INDEX), 1)

	device = devices[0]

	WAVE/Z sweeps = GetAnalysisChannelSweepWave(entry[%DataFolder], device)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	CHECK(GetNumberFromWaveNote(sweeps, NOTE_INDEX) > 0)

	WAVE/Z/T acquisitions = GetAnalysisChannelAcqWave(entry[%DataFolder], device)
	CHECK_WAVE(acquisitions, TEXT_WAVE)

	WAVE/Z/T stimuluses = GetAnalysisChannelStimWave(entry[%DataFolder], device)
	CHECK_WAVE(stimuluses, TEXT_WAVE)

	fileID = IPNWB#H5_OpenFile(discLocation)
	CHECK_EQUAL_VAR(IPNWB#GetNWBMajorVersion(IPNWB#ReadNWBVersion(fileID)), NWB_VERSION)

	// check stored specification versions
	TestSpecVersions(fileID)

	// check history
	TestHistory(fileID)

	// check LBNs
	TestLabnotebooks(fileID, device)

	// check TPStorage
	TestTpStorage(fileID, device)

	// check stored test pulses (if available)
	TestStoredTestPulses(fileID, device)

	// check stimset parameter waves
	TestStimsetParamWaves(fileID, device, sweeps)

	// check all acquisitions
	TestListOfGroups(IPNWB#ReadAcquisition(fileID, NWB_VERSION), acquisitions)

	// check all stimulus
	TestListOfGroups(IPNWB#ReadStimulus(fileID), stimuluses)

	// check sweep data
	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweep = sweeps[i]

		if(!IsValidSweepNumber(sweep))
			break
		endif

		DFREF pxpSweepsDFR = TestSweepData(entry, device, sweep)

		// check acquisition TimeSeries of NWB
		numGroups = ItemsInList(acquisitions[i])
		for(j = 0; j < numGroups; j += 1)
			channel = StringFromList(j, acquisitions[i])
			groupID = IPNWB#OpenAcquisition(fileID, NWB_VERSION)

			// TimeSeries properties
			TestTimeSeriesProperties(groupID, channel)

			TestTimeSeries(fileID, discLocation, device, groupID, channel, sweep, pxpSweepsDFR)
		endfor

		// check presentation/stimulus TimeSeries of NWB
		numGroups = ItemsInList(stimuluses[i])
		for(j = 0; j < numGroups; j += 1)
			channel = StringFromList(j, stimuluses[i])
			groupID = IPNWB#OpenStimulus(fileID)

			// TimeSeries properties
			TestTimeSeriesProperties(groupID, channel)

			TestTimeSeries(fileID, discLocation, device, groupID, channel, sweep, pxpSweepsDFR)
		endfor
	endfor

	HDF5CloseFile/Z fileID
End

static Function/WAVE NWBVersionStrings()
	variable i, numEntries
	string name

	Make/T/FREE data = {"2.0b", "2.0.1", "2.1.0", "2.2.0"}
	return data
End

// UTF_TD_GENERATOR NWBVersionStrings
Function TestNWBVersionStrings([str])
	string str

	variable version0, version1, version2

	IPNWB#AnalyzeNWBVersion(str, version0, version1, version2)
	REQUIRE_NEQ_VAR(version0, NaN)
	IPNWB#EnsureValidNWBVersion(version0)

	REQUIRE_NEQ_VAR(version1, NaN)
End

static Function/WAVE NeuroDataRefTree()
	variable i, numEntries
	string name

	Make/T/FREE data = {"VoltageClampSeries:TimeSeries;PatchClampSeries;VoltageClampSeries;", \
						"CurrentClampSeries:TimeSeries;PatchClampSeries;CurrentClampSeries;", \
						"IZeroClampSeries:TimeSeries;PatchClampSeries;CurrentClampSeries;IZeroClampSeries;" \
						}
	return data
End

// UTF_TD_GENERATOR NeuroDataRefTree
Function TestNeuroDataRefTree([str])
	string str

	string neurodata_type, ancestry

	neurodata_type = StringFromList(0, str, ":")
	ancestry = StringFromList(1, str, ":")

	str = IPNWB#DetermineDataTypeRefTree(neurodata_type)
	REQUIRE_EQUAL_STR(ancestry, str)

	str = StringFromList(ItemsInList(ancestry) - 1, ancestry)
	REQUIRE_EQUAL_STR(neurodata_type, str)
End
