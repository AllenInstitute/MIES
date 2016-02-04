# Igor Pro module for writing NeurodataWithoutBorder files

This modules allows to easily create valid NeurodataWithoutBorder style HDF5
files. It encapsulates most of the specification in easy to use functions.

Compliant to NeurodataWithoutBorders specification 1.0.x.

Example code:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~{.ipf}
Function NWBWriterExample()

	variable fileID
	string contents

	// Open a dialog for selecting an HDF5 file name
	HDF5CreateFile fileID as ""

	// If you open an existing NWB file to append to, use the following command
	// to add an modification time entry
	// IPNWB#AddModificationTimeEntry(locationID)

	// fill gi/ti/si with appropriate data for your lab and experiment
	// if you don't care about that info just pass the initialized structures
	STRUCT IPNWB#GeneralInfo gi
	STRUCT IPNWB#ToplevelInfo ti
	STRUCT IPNWB#SubjectInfo si

	// takes care of initializing
	IPNWB#InitToplevelInfo(ti)
	IPNWB#InitGeneralInfo(gi)
	IPNWB#InitSubjectInfo(si)

	IPNWB#CreateCommonGroups(fileID, toplevelInfo=ti, generalInfo=gi, subjectInfo=si)

	// use the following if you do intracellular ephys
	// IPNWB#CreateIntraCellularEphys(fileID)
	// sprintf contents, "Electrode %d", params.ElectrodeNumber
	// IPNWB#AddElectrode(fileID, params.ElectrodeNumber, contents)

	// 1D waves from your measurement program
	// we use fake data here
	Make/FREE AD = (sin(p) + cos(p/10)) * enoise(0.1)

	// write AD data to the file
	STRUCT IPNWB#WriteChannelParams params
	IPNWB#InitWriteChannelParams(params)

	params.device          = "My Hardware"
	params.clampMode       = 0 // 0 for V_CLAMP_MODE 1 for I_CLAMP_MODE
	params.channelSuffix   = ""
	params.sweep           = 123
	params.electrodeNumber = 1
	params.stimset         = "My fancy sine curve"
	params.channelType     = 0 // @see IPNWB_ChannelTypes
	WAVE params.data       = AD

	// calculate the timepoint of the first wave point relative to the session_start_time
	params.startingTime  = NumberByKeY("MODTIME", WaveInfo(AD, 0)) - date2secs(-1, -1, -1) // last time the wave was modified (UTC)
	params.startingTime -= ti.session_start_time // relative to the start of the session
	params.startingTime -= DimSize(AD, 0) / 1000 // we want the timestamp of the beginning of the measurement, assumes "ms" as wave units

	IPNWB#AddDevice(fileID, "Device name", "My hardware specs")

	STRUCT IPNWB#TimeSeriesProperties tsp
	IPNWB#InitTimeSeriesProperties(tsp, params.channelType, params.clampMode)

	// all values not added are written into the missing_fields dataset
	IPNWB#AddProperty(tsp, "capacitance_fast", 1.0)
	IPNWB#AddProperty(tsp, "capacitance_slow", 1.0)

	// setting chunkedLayout to zero makes writing faster but increases the final filesize
	IPNWB#WriteSingleChannel(fileID, "/acquisition/timeseries", params, tsp, chunkedLayout=0)

	// write DA, stimulus presentation and stimulus template accordingly
	// ...

	// close file
	HDF5CloseFile fileID
End
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

###Online Resources
* https://neurodatawithoutborders.github.io
* https://crcns.org/NWB
* http://nwb.org
