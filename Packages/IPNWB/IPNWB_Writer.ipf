#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IgorVersion=6.3
#pragma IndependentModule=IPNWB
#pragma version=0.15

/// @file IPNWB_Writer.ipf
/// @brief Generic functions related to export into the NeuroDataWithoutBorders format

/// @brief Structure to hold all properties of the NWB file directly below `/general`
Structure GeneralInfo
	string session_id
	string experimenter
	string institution
	string lab
	string related_publications
	string notes
	string experiment_description
	string data_collection
	string stimulus
	string pharmacology
	string surgery
	string protocol
	string virus
	string slices
EndStructure

/// @brief Initialization routine for GeneralInfo
Function InitGeneralInfo(gi)
	STRUCT GeneralInfo &gi

	gi.session_id             = PLACEHOLDER
	gi.experimenter           = PLACEHOLDER
	gi.institution            = PLACEHOLDER
	gi.lab                    = PLACEHOLDER
	gi.related_publications   = PLACEHOLDER
	gi.notes                  = PLACEHOLDER
	gi.experiment_description = PLACEHOLDER
	gi.data_collection        = PLACEHOLDER
	gi.stimulus               = PLACEHOLDER
	gi.pharmacology           = PLACEHOLDER
	gi.surgery                = PLACEHOLDER
	gi.protocol               = PLACEHOLDER
	gi.virus                  = PLACEHOLDER
	gi.slices                 = PLACEHOLDER
End

/// @brief Structure to hold all properties of the NWB file directly below `/general/subject`
Structure SubjectInfo
	string subject_id
	string description
	string species
	string genotype
	string sex
	string age
	string weight
EndStructure

/// @brief Initialization routine for SubjectInfo
Function InitSubjectInfo(si)
	STRUCT SubjectInfo &si

	si.subject_id  = PLACEHOLDER
	si.description = PLACEHOLDER
	si.species     = PLACEHOLDER
	si.genotype    = PLACEHOLDER
	si.sex         = PLACEHOLDER
	si.age         = PLACEHOLDER
	si.weight      = PLACEHOLDER
End

/// @brief Structure to hold all properties of the NWB file directly below `/`
Structure ToplevelInfo
	string session_description
	/// timestamp in seconds since Igor Pro epoch, UTC timezone
	variable session_start_time
EndStructure

/// @brief Initialization routine for ToplevelInfo
Function InitToplevelInfo(ti)
	STRUCT ToplevelInfo &ti

	ti.session_description = PLACEHOLDER
	ti.session_start_time  = DateTimeInUTC()
End

/// @brief Create and fill common HDF5 groups and datasets
/// @param locationID                                               HDF5 identifier
/// @param toplevelInfo [optional, see ToplevelInfo() for defaults] datasets directly below `/`
/// @param generalInfo [optional, see GeneralInfo() for defaults]   datasets directly below `/general`
/// @param subjectInfo [optional, see SubjectInfo() for defaults]   datasets below `/general/subject`
Function CreateCommonGroups(locationID, [toplevelInfo, generalInfo, subjectInfo])
	variable locationID
	STRUCT ToplevelInfo &toplevelInfo
	STRUCT GeneralInfo &generalInfo
	STRUCT SubjectInfo &subjectInfo

	variable groupID

	STRUCT GeneralInfo gi
	STRUCT SubjectInfo si
	STRUCT TopLevelInfo ti

	if(ParamIsDefault(generalInfo))
		InitGeneralInfo(gi)
	else
		gi = generalInfo
	endif

	if(ParamIsDefault(subjectInfo))
		InitSubjectInfo(si)
	else
		si = subjectInfo
	endif

	if(ParamIsDefault(toplevelInfo))
		InitToplevelInfo(ti)
	else
		ti = toplevelInfo
	endif

	WriteTextDatasetIfSet(locationID, "nwb_version", NWB_VERSION)
	WriteTextDatasetIfSet(locationID, "identifier", Hash(GetISO8601TimeStamp() + num2str(enoise(1, NOISE_GEN_MERSENNE_TWISTER)), 1))
	// file_create_date needs to be appendable for the modified timestamps, and that is equivalent to having chunked layout
	WriteTextDatasetIfSet(locationID, "file_create_date", GetISO8601TimeStamp(), chunkedLayout=1)
	WriteTextDatasetIfSet(locationID, "session_start_time", GetISO8601TimeStamp(secondsSinceIgorEpoch=ti.session_start_time))
	H5_WriteTextDataset(locationID, "session_description", str=ti.session_description)

	H5_CreateGroupsRecursively(locationID, "/general", groupID=groupID)

	WriteTextDatasetIfSet(groupID, "session_id"            , gi.session_id)
	WriteTextDatasetIfSet(groupID, "experimenter"          , gi.experimenter)
	WriteTextDatasetIfSet(groupID, "institution"           , gi.institution)
	WriteTextDatasetIfSet(groupID, "lab"                   , gi.lab)
	WriteTextDatasetIfSet(groupID, "related_publications"  , gi.related_publications)
	WriteTextDatasetIfSet(groupID, "notes"                 , gi.notes)
	WriteTextDatasetIfSet(groupID, "experiment_description", gi.experiment_description)
	WriteTextDatasetIfSet(groupID, "data_collection"       , gi.data_collection)
	WriteTextDatasetIfSet(groupID, "stimulus"              , gi.stimulus)
	WriteTextDatasetIfSet(groupID, "pharmacology"          , gi.pharmacology)
	WriteTextDatasetIfSet(groupID, "surgery"               , gi.surgery)
	WriteTextDatasetIfSet(groupID, "protocol"              , gi.protocol)
	WriteTextDatasetIfSet(groupID, "virus"                 , gi.virus)
	WriteTextDatasetIfSet(groupID, "slices"                , gi.slices)

	HDF5CloseGroup/Z groupID

	H5_CreateGroupsRecursively(locationID, "/general/subject", groupID=groupID)

	WriteTextDatasetIfSet(groupID, "subject_id" , si.subject_id)
	WriteTextDatasetIfSet(groupID, "description", si.description)
	WriteTextDatasetIfSet(groupID, "species"    , si.species)
	WriteTextDatasetIfSet(groupID, "genotype"   , si.genotype)
	WriteTextDatasetIfSet(groupID, "sex"        , si.sex)
	WriteTextDatasetIfSet(groupID, "age"        , si.age)
	WriteTextDatasetIfSet(groupID, "weight"     , si.weight)

	HDF5CloseGroup/Z groupID

	H5_CreateGroupsRecursively(locationID, "/general/devices")
	H5_CreateGroupsRecursively(locationID, "/stimulus/templates")
	H5_CreateGroupsRecursively(locationID, "/stimulus/presentation")
	H5_CreateGroupsRecursively(locationID, "/acquisition/timeseries")
	H5_CreateGroupsRecursively(locationID, "/acquisition/images")
	H5_CreateGroupsRecursively(locationID, "/epochs")
	H5_WriteTextAttribute(locationID, "tags", "/epochs", list="")
	H5_CreateGroupsRecursively(locationID, "/processing")
	H5_CreateGroupsRecursively(locationID, "/analysis")

	IPNWB#H5_CreateGroupsRecursively(locationID, "/general/stimsets")
	MarkAsCustomEntry(locationID, "/general/stimsets")
End

/// @brief Create the HDF5 group for intracellular ephys
///
/// @param locationID                                    HDF5 identifier
/// @param filtering [optional, defaults to PLACEHOLDER] filtering information
Function CreateIntraCellularEphys(locationID, [filtering])
	variable locationID
	string filtering

	variable groupID

	if(ParamIsDefault(filtering))
		filtering = PLACEHOLDER
	endif

	H5_CreateGroupsRecursively(locationID, "/general/intracellular_ephys", groupID=groupID)
	H5_WriteTextDataset(groupID, "filtering" , str=filtering, overwrite=1)
	HDF5CloseGroup groupID
End

/// @brief Add an entry for the device `name` with contents `data`
Function AddDevice(locationID, name, data)
	variable locationID
	string name, data

	string path

	sprintf path, "/general/devices/device_%s", name
	H5_WriteTextDataset(locationID, path, str=data, skipIfExists=1)
End

/// @brief Add an entry for the electrode `name` with contents `data`
Function AddElectrode(locationID, name, data, device)
	variable locationID
	string name, data, device

	string path
	variable groupID

	ASSERT(H5_IsValidIdentifier(name), "The electrode name must be a valid HDF5 identifier")

	sprintf path, "/general/intracellular_ephys/electrode_%s", name
	H5_CreateGroupsRecursively(locationID, path, groupID=groupID)
	H5_WriteTextDataset(groupID, "description", str=data, overwrite=1)
	H5_WriteTextDataset(groupID, "device", str=device, overwrite=1)

	HDF5CloseGroup groupID
End

/// @brief Add a modification timestamp to the NWB file
Function AddModificationTimeEntry(locationID)
	variable locationID

	Make/FREE/T/N=1 data = GetISO8601TimeStamp()
	HDF5SaveData/Q/IGOR=0/APND=(ROWS)/Z data, locationID, "/file_create_date"

	if(V_flag)
		HDF5DumpErrors/CLR=1
		HDF5DumpState
		ASSERT(0, "Could not append to the HDF5 dataset")
	endif
End

/// @brief Mark a dataset/group as custom
///
/// According to the NWB spec everything not required should be specifically
/// marked.
///
/// @param locationID HDF5 identifier
/// @param name       dataset or group name
Function MarkAsCustomEntry(locationID, name)
	variable locationID
	string name

	H5_WriteTextAttribute(locationID, "neurodata_type", name, str="Custom", overwrite=1)
End

/// @brief Add unit and resolution to TimeSeries dataset
///
/// @param locationID                                            HDF5 identifier
/// @param fullAbsPath                                           absolute path to the TimeSeries dataset
/// @param unitWithPrefix                                        unit with optional prefix of the data in the TimeSeries, @see ParseUnit
/// @param resolution [optional, defaults to `NaN` for unknown]  experimental resolution
/// @param overwrite [optional, defaults to false] 				 should existing attributes be overwritten
Function AddTimeSeriesUnitAndRes(locationID, fullAbsPath, unitWithPrefix, [resolution, overwrite])
	variable locationID
	string fullAbsPath, unitWithPrefix
	variable resolution, overwrite

	string prefix, unit
	variable numPrefix

	if(ParamIsDefault(resolution))
		resolution = NaN
	endif

	overwrite = ParamIsDefault(overwrite) ? 0 : !!overwrite

	if(isEmpty(unitWithPrefix))
		numPrefix = 1
		unit      = "a.u."
	else
		ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
	endif

	H5_WriteTextAttribute(locationID, "unit"      , fullAbsPath, str=unit)
	H5_WriteAttribute(locationID    , "conversion", fullAbsPath, numPrefix, IGOR_TYPE_32BIT_FLOAT)
	H5_WriteAttribute(locationID    , "resolution", fullAbsPath, resolution, IGOR_TYPE_32BIT_FLOAT)
End

/// @brief Holds class specific entries for TimeSeries objects
///
/// Usage:
/// @code
/// STRUCT TimeSeriesProperties tsp
/// InitTimeSeriesProperties(tsp, channelType, clampMode)
/// AddProperty(tsp, "gain", 1.23456)
/// // more calls tp AddProperty()
/// WriteSingleChannel(locationID, path, p, tsp)
/// @endcode
Structure TimeSeriesProperties
	WAVE/T names
	WAVE   data
	WAVE   isCustom ///< 1 if the entry should be marked as NWB custom
	string missing_fields
EndStructure

/// @brief Initialization of TimeSeriesProperties
/// @param[out] tsp         structure to initialize
/// @param[in]  channelType one of @ref IPNWB_ChannelTypes
/// @param[in]  clampMode   one of @ref IPNWB_ClampModes
Function InitTimeSeriesProperties(tsp, channelType, clampMode)
	STRUCT TimeSeriesProperties &tsp
	variable channelType
	variable clampMode

	Make/FREE/T names = ""
	WAVE/T tsp.names = names

	Make/FREE data = NaN
	WAVE tsp.data = data

	Make/FREE isCustom = 0
	WAVE tsp.isCustom = isCustom

	// AddProperty() will remove the entries on addition of values
	if(channelType == CHANNEL_TYPE_ADC)
		if(clampMode == V_CLAMP_MODE)
			// VoltageClampSeries
			 tsp.missing_fields = "gain;capacitance_fast;capacitance_slow;resistance_comp_bandwidth;resistance_comp_correction;resistance_comp_prediction;whole_cell_capacitance_comp;whole_cell_series_resistance_comp"
		elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
			// CurrentClampSeries
			 tsp.missing_fields = "gain;bias_current;bridge_balance;capacitance_compensation"
		else
			// unassociated channel
			tsp.missing_fields = ""
		endif
	elseif(channelType == CHANNEL_TYPE_DAC)
		tsp.missing_fields = "gain"
	else
		tsp.missing_fields = ""
	endif
End

/// @brief Add a TimeSeries property to the `names` and `data` waves and removes it from `missing_fields` list
Function AddProperty(tsp, nwbProp, value)
	STRUCT TimeSeriesProperties &tsp
	string nwbProp
	variable value

	ASSERT(FindListItem(nwbProp, tsp.missing_fields) != -1, "incorrect missing_fields")
	tsp.missing_fields = RemoveFromList(nwbProp, tsp.missing_fields)

	WAVE/T propNames = tsp.names
	WAVE propData    = tsp.data

	FindValue/TEXT=""/TXOP=(4) propNames
	ASSERT(V_Value != -1, "Could not find space for new entry")
	ASSERT(!IsFinite(propData[V_Value]), "data row already filled")

	propNames[V_value] = nwbProp
	propData[V_value]  = value
End

/// @brief Add a custom TimeSeries property to the `names` and `data` waves
Function AddCustomProperty(tsp, nwbProp, value)
	STRUCT TimeSeriesProperties &tsp
	string nwbProp
	variable value

	WAVE/T propNames = tsp.names
	WAVE propData    = tsp.data
	WAVE isCustom    = tsp.isCustom

	FindValue/TEXT=""/TXOP=(4) propNames
	ASSERT(V_Value != -1, "Could not find space for new entry")
	ASSERT(!IsFinite(propData[V_Value]), "data row already filled")

	propNames[V_value] = nwbProp
	propData[V_value]  = value
	isCustom[V_value]  = 1
End

/// @brief Return the next free group index of the format `data_$NUM`
Function GetNextFreeGroupIndex(locationID, path)
	variable locationID
	string path

	string str, list
	variable idx

	HDF5ListGroup/TYPE=(2^0) locationID, path

	list = S_HDF5ListGroup

	if(IsEmpty(list))
		return 0
	endif

	list = SortList(list, ";", 16)

	str = StringFromList(ItemsInList(list) - 1, list)
	sscanf str, "data_%d.*", idx
	ASSERT(V_Flag == 1, "Could not find running data index")

	return idx + 1
End

/// @brief Helper structure for WriteSingleChannel()
Structure WriteChannelParams
	string device            ///< name of the measure device, e.g. "ITC18USB_Dev_0"
	string stimSet           ///< name of the template simulus set
	string channelSuffix     ///< custom channel suffix, in case the channel number is ambiguous
	string channelSuffixDesc ///< description of the channel suffix, will be added to the `source` attribute
	variable samplingRate    ///< sampling rate in Hz
	variable startingTime    ///< timestamp since Igor Pro epoch in UTC of the start of this measurement
	variable sweep           ///< running number for each measurement
	variable channelType     ///< channel type, one of @ref IPNWB_ChannelTypes
	variable channelNumber   ///< running number of the channel
	variable electrodeNumber ///< electrode identifier the channel was acquired with
	string electrodeName     ///< electrode identifier the channel was acquired with (string version)
	variable clampMode       ///< clamp mode, one of @ref IPNWB_ClampModes
	variable groupIndex      ///< Should be filled with the result of GetNextFreeGroupIndex(locationID, path) before
							 ///  the first call and must stay constant for all channels for this measurement.
							 ///  If `NaN` an automatic solution is provided.
	WAVE data                ///< channel data
EndStructure

/// @brief Initialize WriteChannelParams structure
Function InitWriteChannelParams(p)
	STRUCT WriteChannelParams &p

	p.groupIndex = NaN
End

/// @brief Write the data of a single channel to the NWB file
///
/// @param locationID    HDF5 file identifier
/// @param path          absolute path in the HDF5 file where the data should be stored
/// @param p             filled WriteChannelParams structure
/// @param tsp           filled TimeSeriesProperties structure, see the comment of this function on
///                      how to easily create and fill that structure
/// @param chunkedLayout [optional, defaults to false] Use chunked layout with compression and shuffling.
Function WriteSingleChannel(locationID, path, p, tsp, [chunkedLayout])
	variable locationID
	string path
	STRUCT WriteChannelParams &p
	STRUCT TimeSeriesProperties &tsp
	variable chunkedLayout

	variable groupID, numPlaces, numEntries, i
	string ancestry, str, source, channelTypeStr, group, electrodeNumberStr

	chunkedLayout = ParamIsDefault(chunkedLayout) ? 0 : !!chunkedLayout

	if(p.channelType == CHANNEL_TYPE_OTHER)
		channelTypeStr = "stimset"
		sprintf group, "%s/%s", path, p.stimSet
	else
		if(!IsFinite(p.groupIndex))
			HDF5ListGroup/F/TYPE=(2^0) locationID, path
			p.groupIndex = ItemsInList(S_HDF5ListGroup)
		endif

		channelTypeStr = StringFromList(p.channelType, CHANNEL_NAMES)
		ASSERT(!IsEmpty(channelTypeStr), "invalid channel type string")
		ASSERT(IsFinite(p.channelNumber), "invalid channel number")

		if(strlen(p.channelSuffix) > 0)
			str = "_" + p.channelSuffix
		else
			str = ""
		endif

		numPlaces = max(5, ceil(log(p.groupIndex)))
		sprintf group, "%s/data_%0*d_%s%d%s", path, numPlaces, p.groupIndex, channelTypeStr, p.channelNumber, str
	endif

	// skip writing DA data with I=0 clamp mode (it will just be constant zero)
	if(p.channelType == CHANNEL_TYPE_DAC && p.clampMode == I_EQUAL_ZERO_MODE)
		return NaN
	endif

	H5_CreateGroupsRecursively(locationID, group, groupID=groupID)
	H5_WriteTextAttribute(groupID, "description", group, str=PLACEHOLDER, overwrite=1)

	if(isFinite(p.channelNumber))
		sprintf str, "%s=%d", channelTypeStr, p.channelNumber
	else
		sprintf str, "%s", channelTypeStr
	endif

	if(IsFinite(p.electrodeNumber))
		sprintf electrodeNumberStr, "%d", p.electrodeNumber
	else
		electrodeNumberStr = "NaN"
	endif

	sprintf source, "Device=%s;Sweep=%d;%s;ElectrodeNumber=%s;ElectrodeName=%s", p.device, p.sweep, str, electrodeNumberStr, p.electrodeName

	if(strlen(p.channelSuffixDesc) > 0 && strlen(p.channelSuffix) > 0)
		ASSERT(strsearch(p.channelSuffix, "=", 0) == -1, "channelSuffix must not contain an equals (=) symbol")
		ASSERT(strsearch(p.channelSuffixDesc, "=", 0) == -1, "channelSuffixDesc must not contain an equals (=) symbol")
		source += ";" + p.channelSuffixDesc + "=" + p.channelSuffix
	endif
	H5_WriteTextAttribute(groupID, "source", group, str=source, overwrite=1)

	if(p.channelType != CHANNEL_TYPE_OTHER)
		H5_WriteTextAttribute(groupID, "comment", group, str=note(p.data), overwrite=1) // human readable version of description
	endif

	// only write electrode_name for associated channels
	if(IsFinite(p.electrodeNumber) && (p.channelType == CHANNEL_TYPE_DAC || p.channelType == CHANNEL_TYPE_ADC))
		sprintf str, "electrode_%s", p.electrodeName
		H5_WriteTextDataset(groupID, "electrode_name", str=str, overwrite=1)
	endif

	if(p.channelType == CHANNEL_TYPE_ADC)
		if(p.clampMode == V_CLAMP_MODE)
			ancestry = "TimeSeries;PatchClampSeries;VoltageClampSeries"
		elseif(p.clampMode == I_CLAMP_MODE)
			ancestry = "TimeSeries;PatchClampSeries;CurrentClampSeries"
		elseif(p.clampMode == I_EQUAL_ZERO_MODE)
			ancestry = "TimeSeries;PatchClampSeries;CurrentClampSeries;IZeroClampSeries"
		else
			ancestry = "TimeSeries"
		endif
	elseif(p.channelType == CHANNEL_TYPE_DAC)
		if(p.clampMode == V_CLAMP_MODE)
			ancestry = "TimeSeries;PatchClampSeries;VoltageClampStimulusSeries"
		elseif(p.clampMode == I_CLAMP_MODE)
			ancestry = "TimeSeries;PatchClampSeries;CurrentClampStimulusSeries"
		else
			ancestry = "TimeSeries"
		endif
	else
		ancestry = "TimeSeries"
	endif

	numEntries = DimSize(tsp.names, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!cmpstr(tsp.names[i], ""))
			break
		endif

		H5_WriteDataset(groupID, tsp.names[i], var=tsp.data[i], varType=IGOR_TYPE_32BIT_FLOAT, overwrite=1)

		if(tsp.isCustom[i])
			MarkAsCustomEntry(groupID, tsp.names[i])
		endif
	endfor

	if(cmpstr(tsp.missing_fields, ""))
		H5_WriteTextAttribute(groupID, "missing_fields", group, list=tsp.missing_fields, overwrite=1)
	endif

	H5_WriteTextAttribute(groupID, "ancestry", group, list=ancestry, overwrite=1)
	H5_WriteTextAttribute(groupID, "neurodata_type", group, str="TimeSeries", overwrite=1)
	// no data_link and timestamp_link attribute as we keep all data in one file
	// skipping optional entry help

	H5_WriteDataset(groupID, "data", wv=p.data, chunkedLayout=chunkedLayout, overwrite=1, writeIgorAttr=1)

	// TimeSeries: datasets and attributes
	AddTimeSeriesUnitAndRes(groupID, group + "/data", WaveUnits(p.data, -1), overwrite=1)
	H5_WriteDataset(groupID, "num_samples", var=DimSize(p.data, ROWS), varType=IGOR_TYPE_32BIT_INT, overwrite=1)
	// no timestamps, control, control_description and sync

	if(p.channelType != CHANNEL_TYPE_OTHER)
		H5_WriteDataset(groupID, "starting_time", var=p.startingTime, varType=IGOR_TYPE_64BIT_FLOAT, overwrite=1)
		H5_WriteAttribute(groupID, "rate", group + "/starting_time", p.samplingRate, IGOR_TYPE_32BIT_FLOAT, overwrite=1)
		H5_WriteTextAttribute(groupID, "unit", group + "/starting_time", str="Seconds", overwrite=1)
	endif

	if(strlen(p.stimSet) > 0 && (p.channelType == CHANNEL_TYPE_ADC || p.channelType == CHANNEL_TYPE_TTL))
		// custom data not specified by NWB spec
		H5_WriteTextDataset(groupID, "stimulus_description", str=p.stimSet, overwrite=1)
		MarkAsCustomEntry(groupID, "stimulus_description")
	endif

	HDF5CloseGroup groupID
End
