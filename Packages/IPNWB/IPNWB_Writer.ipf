#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.3
#pragma IndependentModule=IPNWB
#pragma version=0.1

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

	H5_WriteTextDataset(locationID, "neurodata_version", str=NWB_VERSION)
	H5_WriteTextDataset(locationID, "identifier", str=Hash(GetISO8601TimeStamp() + num2str(enoise(1, 2)), 1))
	// file_create_date needs to be appendable for the modified timestamps, and that is equivalent to having chunked layout
	H5_WriteTextDataset(locationID, "file_create_date", str=GetISO8601TimeStamp(), chunkedLayout=1)
	H5_WriteTextDataset(locationID, "session_start_time", str=GetISO8601TimeStamp(secondsSinceIgorEpoch=ti.session_start_time))
	H5_WriteTextDataset(locationID, "session_description", str=ti.session_description)

	H5_CreateGroupsRecursively(locationID, "/general", groupID=groupID)

	H5_WriteTextDataset(groupID, "session_id"            , str=gi.session_id)
	H5_WriteTextDataset(groupID, "experimenter"          , str=gi.experimenter)
	H5_WriteTextDataset(groupID, "institution"           , str=gi.institution)
	H5_WriteTextDataset(groupID, "lab"                   , str=gi.lab)
	H5_WriteTextDataset(groupID, "related_publications"  , str=gi.related_publications)
	H5_WriteTextDataset(groupID, "notes"                 , str=gi.notes)
	H5_WriteTextDataset(groupID, "experiment_description", str=gi.experiment_description)
	H5_WriteTextDataset(groupID, "data_collection"       , str=gi.data_collection)
	H5_WriteTextDataset(groupID, "stimulus"              , str=gi.stimulus)
	H5_WriteTextDataset(groupID, "pharmacology"          , str=gi.pharmacology)
	H5_WriteTextDataset(groupID, "surgery"               , str=gi.surgery)
	H5_WriteTextDataset(groupID, "protocol"              , str=gi.protocol)
	H5_WriteTextDataset(groupID, "virus"                 , str=gi.virus)
	H5_WriteTextDataset(groupID, "slices"                , str=gi.slices)

	HDF5CloseGroup/Z groupID

	H5_CreateGroupsRecursively(locationID, "/general/subject", groupID=groupID)

	H5_WriteTextDataset(groupID, "subject_id" , str=si.subject_id)
	H5_WriteTextDataset(groupID, "description", str=si.description)
	H5_WriteTextDataset(groupID, "species"    , str=si.species)
	H5_WriteTextDataset(groupID, "genotype"   , str=si.genotype)
	H5_WriteTextDataset(groupID, "sex"        , str=si.sex)
	H5_WriteTextDataset(groupID, "age"        , str=si.age)
	H5_WriteTextDataset(groupID, "weight"     , str=si.weight)

	HDF5CloseGroup/Z groupID

	H5_CreateGroupsRecursively(locationID, "/general/devices")
	H5_CreateGroupsRecursively(locationID, "/stimulus/templates")
	H5_CreateGroupsRecursively(locationID, "/stimulus/presentation")
	H5_CreateGroupsRecursively(locationID, "/acquisition/timeseries")
	H5_CreateGroupsRecursively(locationID, "/acquisition/images")
	H5_CreateGroupsRecursively(locationID, "/epochs")
	H5_CreateGroupsRecursively(locationID, "/processing")
	H5_CreateGroupsRecursively(locationID, "/analysis")
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
	H5_WriteTextDataset(groupID, "filtering" , str=filtering)
End

/// @brief Add an entry for the device `name` with contents `data`
Function AddDevice(locationID, name, data)
	variable locationID
	string name, data

	string path

	sprintf path, "/general/devices/device_%s", name
	H5_WriteTextDataset(locationID, path, str=data, skipIfExists=1)
End

/// @brief Add an entry for the electrode `number` with contents `data`
Function AddElectrode(locationID, number, data)
	variable locationID, number
	string data

	string path

	sprintf path, "/general/intracellular_ephys/electrode_%d", number
	H5_WriteTextDataset(locationID, path, str=data, skipIfExists=1)
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

	// AddProperty() will remove the entries on addition of values
	if(channelType == CHANNEL_TYPE_ADC)
		if(clampMode == V_CLAMP_MODE)
			// VoltageClampSeries
			 tsp.missing_fields = "gain;capacitance_fast;capacitance_slow;resistance_comp_bandwidth;resistance_comp_correction;resistance_comp_prediction;whole_cell_capacitance_comp;whole_cell_series_resistance_comp"
		elseif(clampMode == I_CLAMP_MODE)
			// CurrentClampSeries
			 tsp.missing_fields = "gain;bias_current;bridge_balance;capacitance_compensation"
		else
			 ASSERT(0, "Unknown clamp mode")
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

/// @brief Helper structure for WriteSingleChannel()
Structure WriteChannelParams
	string device            ///< name of the measure device, e.g. "ITC18USB_Dev_0"
	string stimSet           ///< name of the template simulus set
	string channelSuffix     ///< custom channel suffix, in case the channel number is ambiguous
	variable samplingRate    ///< sampling rate in Hz
	variable startingTime    ///< timestamp since Igor Pro epoch in UTC of the start of this measurement
	variable sweep           ///< running number for each measurement
	variable channelType     ///< channel type, one of @ref IPNWB_ChannelTypes
	variable channelNumber   ///< running number of the channel
	variable electrodeNumber ///< electrode identifier the channel was acquired with
	variable clampMode       ///< clamp mode, one of @ref IPNWB_ClampModes
	WAVE data                ///< channel data
EndStructure

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

	variable groupID, numPlaces, nwbDataCounter, numEntries, i
	string ancestry, str, source, channelTypeStr, group

	chunkedLayout = ParamIsDefault(chunkedLayout) ? 0 : !!chunkedLayout

	if(p.channelType == CHANNEL_TYPE_OTHER)
		channelTypeStr = "stimset"
		sprintf group, "%s/%s", path, p.stimSet
	else
		HDF5ListGroup/F/TYPE=(2^0) locationID, path
		nwbDataCounter = ItemsInList(S_HDF5ListGroup)

		channelTypeStr = StringFromList(p.channelType, CHANNEL_NAMES)
		ASSERT(!IsEmpty(channelTypeStr), "invalid channel type string")
		ASSERT(IsFinite(p.channelNumber), "invalid channel number")

		numPlaces = max(5, ceil(log(nwbDataCounter)))
		sprintf group, "%s/data_%0*d_%s%d%s", path, numPlaces, nwbDataCounter, channelTypeStr, p.channelNumber, p.channelSuffix
	endif

	H5_CreateGroupsRecursively(locationID, group, groupID=groupID)
	H5_WriteTextAttribute(groupID, "description", group, str=PLACEHOLDER, overwrite=1)

	if(isFinite(p.channelNumber))
		sprintf str, "%s=%d", channelTypeStr, p.channelNumber
	else
		sprintf str, "%s", channelTypeStr
	endif

	sprintf source, "Device=%s;Sweep=%d;%s;ElectrodeNumber=%d", p.device, p.sweep, str, p.electrodeNumber
	H5_WriteTextAttribute(groupID, "source", group, list=source, overwrite=1)

	if(p.channelType != CHANNEL_TYPE_OTHER)
		H5_WriteTextAttribute(groupID, "comment", group, str=note(p.data), overwrite=1) // human readable version of description
	endif

	if(p.channelType == CHANNEL_TYPE_ADC)
		sprintf str, "electrode_%d", p.electrodeNumber
		H5_WriteTextDataset(groupID, "electrode_name", str=str, overwrite=1)

		if(p.clampMode == V_CLAMP_MODE)
			ancestry = "TimeSeries;PatchClampSeries;VoltageClampSeries"
		elseif(p.clampMode == I_CLAMP_MODE)
			ancestry = "TimeSeries;PatchClampSeries;CurrentClampSeries"
		else
			ancestry = "TimeSeries;PatchClampSeries"
		endif
	elseif(p.channelType == CHANNEL_TYPE_DAC)
		sprintf str, "electrode_%d", p.electrodeNumber
		H5_WriteTextDataset(groupID, "electrode_name", str=str, overwrite=1)

		if(p.clampMode == V_CLAMP_MODE)
			ancestry = "TimeSeries;PatchClampSeries;VoltageClampStimulusSeries"
		elseif(p.clampMode == I_CLAMP_MODE)
			ancestry = "TimeSeries;PatchClampSeries;CurrentClampStimulusSeries"
		else
			ancestry = "TimeSeries;PatchClampSeries"
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

	if(p.channelType == CHANNEL_TYPE_ADC || p.channelType == CHANNEL_TYPE_TTL)
		// custom data not specified by NWB spec
		H5_WriteTextDataset(groupID, "stimulus_description", str=p.stimSet, overwrite=1)
		MarkAsCustomEntry(groupID, "stimulus_description")
	endif

	HDF5CloseGroup groupID
End
