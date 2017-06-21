#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IndependentModule=IPNWB
#pragma version=0.17

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

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

/// @brief Loader structure analog to #IPNWB::WriteChannelParams
Structure ReadChannelParams
	string   device           ///< name of the measure device, e.g. "ITC18USB_Dev_0"
	string   channelSuffix    ///< custom channel suffix, in case the channel number is ambiguous
	variable sweep            ///< running number for each measurement
	variable channelType      ///< channel type, one of @ref IPNWB_ChannelTypes
	variable channelNumber    ///< running number of the channel
	variable electrodeNumber  ///< electrode identifier the channel was acquired with
	variable groupIndex       ///< constant for all channels in this measurement.
	variable ttlBit           ///< unambigous ttl-channel-number
EndStructure

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
	string nwb_version ///< NWB specification version
	string identifier
	WAVE/T file_create_date
EndStructure

/// @brief Initialization routine for ToplevelInfo
Function InitToplevelInfo(ti)
	STRUCT ToplevelInfo &ti

	ti.session_description = PLACEHOLDER
	ti.session_start_time  = DateTimeInUTC()
	ti.nwb_version         = NWB_VERSION
	ti.identifier          = Hash(GetISO8601TimeStamp() + num2str(enoise(1, NOISE_GEN_MERSENNE_TWISTER)), 1)

	Make/N=1/T/FREE file_create_date = GetISO8601TimeStamp()
	WAVE/T ti.file_create_date = file_create_date
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
///
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
