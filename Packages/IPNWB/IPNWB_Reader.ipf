#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.3
#pragma IndependentModule=IPNWB
#pragma version=0.15

/// @file IPNWB_Reader.ipf
/// @brief Generic functions related to import from the NeuroDataWithoutBorders format

/// @brief list devices in given hdf5 file
///
/// @param  fileID identifier of open HDF5 file
/// @return        comma separated list of devices
Function/S ReadDevices(fileID)
	Variable fileID

	return RemovePrefixFromListItem("device_", H5_ListGroupMembers(fileID, "/general/devices"))
End

/// @brief list all channels inside the file. Specifiy which type of channel by
///        optional arguments.
/// @param[in] locationID          identifier pointing to open HDF5 file or group
/// @param[in] acquisition         optional: select /acquisition/timeseries
/// @param[in] stimulus            optional: select /stimulus/presentation
/// @param[out] channelList        list of all channels
/// @param[out] groupID            optional: group with channels remains open and
///                                groupID will be filled with open group
Function/S ReadChannelList(locationID, [acquisition, stimulus])
	variable locationID
	variable acquisition, stimulus

	string path

	if(ParamIsDefault(acquisition))
		acquisition = 0
	endif
	if(ParamIsDefault(stimulus))
		stimulus = 0
	endif

	ASSERT((acquisition + stimulus) == 1, "Function takes exactly one optional parameter at once")

	if(acquisition)
		path = "/acquisition/timeseries"
	elseif(stimulus)
		path = "/stimulus/presentation"
	endif

	return H5_ListGroups(locationID, path)
End

/// @brief list groups inside /general/labnotebook
///
/// @param  fileID identifier of open HDF5 file
/// @return        list with name of all groups inside /general/labnotebook/*
Function/S ReadLabNoteBooks(fileID)
	Variable fileID

	return H5_ListGroups(fileID, "/general/labnotebook")
End

/// @brief check if the file can be handled by the IPNWB Read Procedures
///
/// @param   fileID  Open HDF5-File Identifier
/// @return  True:   All checks successful
///          False:  Error(s) occured.
///                  The result of the analysis is printed to history.
Function CheckIntegrity(fileID)
	variable fileID

	string deviceList
	variable integrity = 1

	deviceList = ReadDevices(fileID)
	if (cmpstr(deviceList, ReadLabNoteBooks(fileID)))
		print "labnotebook corrupt"
		integrity = 0
	endif

	return integrity
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
EndStructure

/// @brief Read parameters from source attribute
///
/// @param[in]  locationID   HDF5 group specified channel is a member of
/// @param[in]  channel      channel to load
/// @param[out] p            ReadChannelParams structure to get filled
Function LoadSourceAttribute(locationID, channel, p)
	variable locationID
	string channel
	STRUCT ReadChannelParams &p

	string attribute, property, value
	variable numStrings, i

	attribute = "source"
	ASSERT(!H5_DatasetExists(locationID, channel + "/" + attribute), "Could not find source attribute!")

	HDF5LoadData/O/A=(attribute)/TYPE=1/Q/Z locationID, channel
	if(V_flag)
		HDf5DumpErrors/CLR=1
		HDF5DumpState
		ASSERT(0, "Could not load the HDF5 dataset ./source")
	endif

	ASSERT(ItemsInList(S_WaveNames) == 1, "Expected only one wave")
	WAVE/T wv = $StringFromList(0, S_WaveNames)
	ASSERT(WaveType(wv, 1) == 2, "Expected a dataset of type text")

	numStrings = DimSize(wv, ROWS)

	// new format since eaa5e724 (H5_WriteTextAttribute: Force dataspace to SIMPLE
	// for lists, 2016-08-28)
	// source has now always one element
	if(numStrings == 1)
		WAVE/T list = ListToTextWave(wv[0], ";")
		numStrings = DimSize(list, ROWS)
	else
		WAVE/T list = wv
	endif

	for(i = 0; i < numStrings; i += 1)
		SplitString/E="(.*)=(.*)" list[i], property, value
		strswitch(property)
			case "Device":
				p.device = value
				break
			case "Sweep":
				p.sweep = str2num(value)
				break
			case "ElectrodeNumber":
				p.electrodeNumber = str2num(value)
				break
			case "AD":
				p.channelType = CHANNEL_TYPE_ADC
				p.channelNumber = str2num(value)
				break
			case "DA":
				p.channelType = CHANNEL_TYPE_DAC
				p.channelNumber = str2num(value)
				break
			case "TTL":
				p.channelType = CHANNEL_TYPE_TTL
				p.channelNumber = str2num(value)
				break
			default:
		endswitch
	endfor

	// from /acquisition/timeseries/data_*_*/source
	//sprintf group, "%s/data_%0*d_%s%d%s", path, numPlaces, p.groupIndex, channelTypeStr, p.channelNumber, p.channelSuffix
End

/// @brief Load data wave from specified path
///
/// @param locationID   id of an open hdf5 group containing channel
///                     id can also be of an open nwb file. In this case specify (optional) path.
/// @param channel      name of channel for which data attribute is loaded
/// @param path         use path to specify group inside hdf5 file where ./channel/data is located.
/// @return             reference to free wave containing loaded data
Function/Wave LoadDataWave(locationID, channel, [path])
	variable locationID
	string channel, path

	if(ParamIsDefault(path))
		path = "./"
	endif

	Assert(IPNWB#H5_GroupExists(locationID, path), "Path is not in nwb file")

	path += channel + "/data"
	HDF5LoadData/Q/IGOR=(-1) locationID, path

	Assert(!V_flag, "could not load data wave from specified path")
	Assert(ItemsInList(S_waveNames) == 1, "unspecified data format")

	wave data = $StringFromList(0, S_waveNames)
	MoveWave data $channel

	return MakeWaveFree(data)
End

/// @brief Load single channel data as a wave from /acquisition/timeseries
///
/// @param locationID   id of an open hdf5 group or file
/// @param channel      name of channel for which data attribute is loaded
/// @param dfr          dataFolder where data is saved
/// @return             reference to wave containing loaded data
Function/Wave LoadTimeseries(locationID, channel, [dfr])
	Variable locationID
	String channel
	DFREF dfr

	WAVE data = LoadDataWave(locationID, channel, path = "/acquisition/timeseries/")
	if(!ParamIsDefault(dfr))
		MoveAndRename(data, "AD" + NameOfWave(data), dfr = dfr)
	endif

	return data
End

/// @brief Load single channel data as a wave from /stimulus/presentation/
///
/// @param locationID   id of an open hdf5 group or file
/// @param channel      name of channel for which data attribute is loaded
/// @param dfr          dataFolder where data is saved
/// @return             reference to wave containing loaded data
Function/Wave LoadStimulus(locationID, channel, [dfr])
	Variable locationID
	String channel
	DFREF dfr

	WAVE data = LoadDataWave(locationID, channel, path = "/stimulus/presentation/")
	if(!ParamIsDefault(dfr))
		MoveAndRename(data, "DA" + NameOfWave(data), dfr = dfr)
	endif

	return data
End
