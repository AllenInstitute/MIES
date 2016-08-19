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
