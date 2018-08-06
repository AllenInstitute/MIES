#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_HD
#endif

/// @file MIES_HDF5Ops.ipf
/// @brief __HD__ Loading and saving into/from HDF5 files

/// @brief Save all data as HDF5 file...must be passed a saveFilename with full path...with double \'s...ie "c:\\test.h5"
Function HD_TangoHDF5Save(saveFilename)
	string saveFilename

	HD_Convert_To_HDF5(saveFilename)
End

/// @brief dump all experiment data to HDF5 file
Static Function HD_Convert_To_HDF5(filename)
    String filename
    Variable root_id, h5_id
    
    // save the present data folder
    string savedDataFolder = GetDataFolder(1)
    
    SetDataFolder root:
    HDF5CreateFile /O /Z h5_id as filename
    if (V_Flag != 0 ) // HDF5CreateFile failed
    	print "HDF5Create File failed for ", filename
    	print "Check file name format..."
    	
    	// restore the data folder
    	SetDataFolder savedDataFolder
    	
    	return -1
    endif
    HDF5CreateGroup /Z h5_id, "/", root_id
    HDF5SaveGroup /O /R  :, root_id, "/"
    HDF5CloseGroup root_id
    HDF5CloseFile h5_id
    print "HDF5 file save complete for ", filename
    
    // restore the data folder
    SetDataFolder savedDataFolder
    
end

/// @brief creates high-level group structure of HDF5 file
Static Function HD_HDF5_Structure(h5_id)
	Variable h5_id
	Variable root_id, grp_id
	// initialize HDF5 format
	HDF5CreateGroup /Z h5_id, "/", root_id
	HDF5CreateGroup /Z root_id, "acquisition", grp_id
	HDF5CreateGroup /Z root_id, "acquisition/data", grp_id
	HDF5CreateGroup /Z root_id, "acquisition/stimulus", grp_id
	HDF5CreateGroup /Z root_id, "analysis", grp_id
	// store version info
	Make/n=1/O vers = 1.0
	HDF5SaveData /O /Z vers, root_id
	if (V_flag != 0)
		print "HDF5SaveData failed (version)"
		return -1
	endif
End

/// @brief creates dataset for saving the entire MIES dataspace
Static Function HD_Create_Dataset(h5_id, sweep_name, data)
	Variable h5_id
	String sweep_name
	Wave data
	Variable grp_id, sweep_id
	// create group for this sweep
	String group = "/acquisition/data/" + sweep_name
	HDF5CreateGroup /Z h5_id, group, sweep_id
	// pull raw data from Igor, making separate voltage and current waves
	duplicate/o/r=[][0] data, current_0
	duplicate/o/r=[][1] data, v_0
	Wave /Z current_0, v_0
	// create sweep's ephys group
	HDF5CreateGroup /Z sweep_id, "ephys", grp_id
	// write voltage data
	HDF5SaveData /O /Z V_0, grp_id
	if (V_flag != 0)
		print "HDF5SaveData failed (voltage)"
		return -1
	endif
	// create sweep's stim group
	HDF5CreateGroup /Z sweep_id, "stim", grp_id
	// write current data to stim group
	HDF5SaveData /O /Z current_0, grp_id
	if (V_flag != 0)
		print "HDF5SaveData failed (current)"
		return -1
	endif
	// fetch metadata and calculate/store dt
	String cfg_name = "Config_" + sweep_name
	Wave cfg = $cfg_name
	Make /FREE /N=1 dt = 1e-6 * cfg[0][2][0]
	HDF5SaveData /O /Z dt, sweep_id
	if (V_flag != 0)
		print "HDF5SaveData failed (dt)"
		return -1
	endif
	// categorize stimulus and save that data
	Make /n=5 /o stim_characteristics
	HD_Ident_Stimulus(current_0, dt[0], stim_characteristics)
	HDF5SaveData /O /Z stim_characteristics, grp_id
	if (V_flag != 0)
		print "HDF5SaveData failed (stim_characteristics)"
		return -1
	endif
	// calculate and store Hz
	Make /FREE /N=1 rate = (1.0 / dt)
	HDF5SaveData /O /Z rate, sweep_id
	if (V_flag != 0)
		print "HDF5SaveData failed (rate)"
		return -1
	endif
	// calculate and store sweep duration
	Make /FREE /N=1 duration = (dt * (DimSize(v_0, 0)-1))
	HDF5SaveData /O /Z duration, sweep_id
	if (V_flag != 0)
		print "HDF5SaveData failed (duration)"
		return -1
	endif
End

/// @name Stimulus type constants
/// @{
static Constant TYPE_UNKNOWN = 0
static Constant TYPE_NULL    = 1
static Constant TYPE_STEP    = 2
static Constant TYPE_PULSE   = 3 // pulse defined as step that lasts less than 20ms
static Constant TYPE_RAMP    = 4
/// @}

/// @brief Categorize stimulus and extract some features
Static Function HD_Ident_Stimulus(current, dt, stim_characteristics)
	Wave current
	variable dt
	Wave stim_characteristics

	ASSERT(DimSize(current,ROWS) > 0,"expected non-empty wave")
	ASSERT(DimSize(stim_characteristics,ROWS) > 5,"expected wave with at least 5 rows")

	// variables to track stimulus characteristics
	variable polarity // >0 when i increasing; <0 when i decreasing
	variable flips // number of polarity shifts
	variable changes // number of changes in i
	variable peak // peak current
	variable start 
	variable stop 
	variable last = current[0]

	// characterize stimulus, using current polarity and amplitude changes
	variable n = DimSize(current, 0)
	variable i, cur
	for (i=0; i<n; i+=1)
		cur = current[i]
		if (cur == last)
			continue
		endif
		changes += 1
		if (polarity == 0)
			// stimulus just started - assign initial polarity
			if (cur > 0)
				polarity = 1
			else
				polarity = -1
			endif
		elseif (polarity == -1)
		// current was decreasing
			if (cur > last)
			// current now on upswing - record polarity shift
				polarity = 1
				flips += 1
			endif
		else // polarity == 1
		// current has been increasing
			if (cur < last)
			// current now decreasing - record polarity shift
				polarity = -1
				flips += 1
			endif
		endif
		if ((start == 0) && (changes == 3))
			start = i
		endif
		if ((start > 0) && (abs(cur) > abs(peak)))
			peak = cur
		endif
		if ((cur == 0) && (last != 0))
		// current returned to zero - store this as potential end
		// of stimulus
			stop = i
		endif
		last = cur
	endfor

	variable t = (n-1) * dt
	variable dur = (stop - start) * dt
	variable onset = start * dt
	variable type = TYPE_UNKNOWN // default to unknown

	if (changes == 4)
		if (dur < 0.020)
			type = TYPE_PULSE
		else
			type = TYPE_STEP
		endif
	elseif (flips == 3)
		// too many current changes for step, but only one flip
		// this must be a ramp
		type = TYPE_RAMP
	elseif ((flips == 1) && (changes == 2))
		// no stimulus
		type = TYPE_NULL
	endif

	// store results in vector - this is more friendly for hdf5 storage
	stim_characteristics[0] = type
	stim_characteristics[1] = t
	stim_characteristics[2] = onset
	stim_characteristics[3] = dur
	stim_characteristics[4] = peak
End

///@brief Save stim sets to HDF5 file
Function HD_SaveStimSet([cmdID])
	string cmdID
	
	string filename
	string fileLocation
	string dateTimeStamp
	variable root_id, h5_id
	string fileLocationResponseString
	    	
 	// build up the filename using the time and date functions
 	fileLocation = "C:\\MiesHDF5Files\\SavedStimSets\\"
    	
	// Call this new function to insure that the folder actually exists on the disk
	CreateFolderOnDisk(fileLocation)
    	
    	dateTimeStamp = GetTimeStamp()
    	
    	sprintf filename, "%sstimProtocol_%s.h5", fileLocation, dateTimeStamp
    	print "filename: ", filename
	    	 
	HDF5CreateFile  h5_id as filename
	if (V_Flag != 0 ) // HDF5CreateFile failed
		print "HDF5Create File failed for ", filename
		print "Check file name format..."
		
		// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
		if(!ParamIsDefault(cmdID))
			HD_WriteAckWrapper(cmdID, TI_WRITEACK_FAILURE)
		endif	
		return 0		
	endif
	    	
	// Set the data folder for saving all the Wave Builder stuff
	DFREF dfr = GetWBSvdStimSetPath() 
	HDF5CreateGroup /Z h5_id, "/SavedStimulusSets", root_id
	HDF5SaveGroup /O /R dfr, root_id, "/SavedStimulusSets" 
	HDF5CloseGroup root_id
	    	
	// Now the data folder for saving the SavedStimulusSetParameters
	dfr = GetWBSvdStimSetParamPath()	
	HDF5CreateGroup /Z h5_id, "/SavedStimulusSetParameters", root_id	
	HDF5SaveGroup /O /R  dfr, root_id, "/SavedStimulusSetParameters"
	HDF5CloseGroup root_id 
	    	
	HDF5CloseFile h5_id
	print "HDF5 file save complete..."
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		// build up the response string containing the file location for passing back to the WSE
		sprintf fileLocationResponseString "stimFile:%s", filename 
		HD_WriteAsyncResponseWrapper(cmdID, fileLocationResponseString)
	endif
End

/// @brief Load stim sets from HDF5 file and replace all of the current stimulus waves
Function HD_LoadReplaceStimSet([incomingFileName, cmdID, incomingFileDirectory])
	string incomingFileName
	string cmdID
	string incomingFileDirectory

	variable fileID, waveCounter
	string dataSet
	string dataFolderString
	string stimSetType
	string stimName
	string savedDataFolder
	string groupList
	variable groupItems

	// save the present data folder
	savedDataFolder = GetDataFolder(1)

	if(ParamIsDefault(incomingFileName))
		if(ParamIsDefault(incomingFileDirectory))
			NewPath/O miesHDF5StimStorage, "C:\\MiesHDF5Files\\SavedStimSets"
			HDF5OpenFile /R /Z /P=miesHDF5StimStorage fileID as ""	 // Displays a dialog
			KillPath/Z miesHDF5StimStorage
			if(V_flag == 0)				 // User selected a file?
				HDF5ListGroup /R=1 /TYPE=3 fileID, "/"
			else
				print "File load cancelled..."
				return 0
			endif
		else
			NewPath/O miesHDF5StimStorage, incomingFileDirectory
			ASSERT(V_flag == 0, "Stim set directory does not exist or is not connected/accessible if mapped drive")
			HDF5OpenFile /R /Z /P=miesHDF5StimStorage fileID as ""	 // Displays a dialog
			KillPath/Z miesHDF5StimStorage
			if(V_flag == 0)				 // User selected a file?
				HDF5ListGroup /R=1 /TYPE=3 fileID, "/"
			else
				print "File load cancelled..."
				return 0
			endif
		endif
	else
		if(StringMatch(incomingFileName, "*stim*") != 1)
			print "Not a valid stim set file....exiting..."
			// determine if the cmdID was provided
			if(!ParamIsDefault(cmdID))
				HD_WriteAckWrapper(cmdID,TI_WRITEACK_FAILURE)
			endif
			return 0
		else
			HDF5OpenFile /R /Z fileID as incomingFileName // reads the incoming filename
			HDF5ListGroup /R=1 /TYPE=3 fileID, "/"
		endif
	endif

	groupList =  S_HDF5ListGroup

	// Need to clear out the previously loaded wave sets
	SetDataFolder GetWBSvdStimSetParamDAPath()
	KillWaves/A/Z
	SetDataFolder GetWBSvdStimSetParamTTLPath()
	KillWaves/A/Z
	SetDataFolder GetWBSvdStimSetDAPath()
	KillWaves/A/Z
	SetDataFolder GetWBSvdStimSetTTLPath()
	KillWaves/A/Z

	groupItems = ItemsInList(groupList)
	for(waveCounter = 0; waveCounter < groupItems; waveCounter += 1)
		dataSet = StringFromList(waveCounter, groupList)
		if (StringMatch(dataSet,"SavedStimulusSetParameters/DA/*"))
			// load into the DA folder
			SetDataFolder GetWBSvdStimSetParamDAPath()
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet,"SavedStimulusSetParameters/TTL/*"))
			// load into the TTL folder
			SetDataFolder GetWBSvdStimSetParamTTLPath()
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet,"SavedStimulusSets/DA/*"))
			// loading into the DA folder
			SetDataFolder GetWBSvdStimSetDAPath()
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet,"SavedStimulusSets/TTL/*"))
			// loading into the TTL folder
			SetDataFolder GetWBSvdStimSetTTLPath()
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		endif
	endfor

	HDF5CloseFile fileID
	print "Stimulus Set Loaded..."

	WBP_UpdateITCPanelPopUps()

	// restore the data folder
	SetDataFolder savedDataFolder

	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		HD_WriteAckWrapper(cmdID, TI_WRITEACK_SUCCESS)  // send a 0 for success
	endif
End

/// @brief Load stim sets from HDF5 file and add to the current stimulus waves.  If there is a wave with a matching name already present, it will be overwritten and replaced
Function HD_LoadAdditionalStimSet([incomingFileName, cmdID])
	string incomingFileName
	string cmdID
	    
	variable fileID, waveCounter
	string dataSet
	string dataFolderString
	string stimSetType
	string stimName
	string savedDataFolder
	string groupList 
	variable groupItems
    	
	// save the present data folder
	savedDataFolder = GetDataFolder(1)
	
	if(ParamIsDefault(incomingFileName))
		NewPath/O miesHDF5StimStorage, "C:\\MiesHDF5Files\\SavedStimSets"
		HDF5OpenFile /R /Z /P=miesHDF5StimStorage fileID as ""	 // Displays a dialog
		KillPath/Z miesHDF5StimStorage
		if(V_flag == 0)				 // User selected a file?
			HDF5ListGroup /R=1 /TYPE=3 fileID, "/"
		else
			print "File load cancelled..."
			return 0
		endif
	else
		if(StringMatch(incomingFileName, "*stim*") != 1)
			print "Not a valid stim set file....exiting..."
			// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
			if(!ParamIsDefault(cmdID))
				HD_WriteAckWrapper(cmdID, TI_WRITEACK_FAILURE)
			endif
			return 0
		else
			HDF5OpenFile /R /Z fileID as incomingFileName // reads the incoming filename
			HDF5ListGroup /R=1 /TYPE=3 fileID, "/"	
		endif
	endif
    	
	groupList =  S_HDF5ListGroup
	
	groupItems = ItemsInList(groupList)
	for(waveCounter = 0; waveCounter < groupItems; waveCounter += 1)
		dataSet = StringFromList(waveCounter, groupList)
		if (StringMatch(dataSet,"SavedStimulusSetParameters/DA/*"))
			// load into the DA folder
			SetDataFolder GetWBSvdStimSetParamDAPath()
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet,"SavedStimulusSetParameters/TTL/*"))
			// load into the TTL folder
			SetDataFolder GetWBSvdStimSetParamTTLPath()
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet,"SavedStimulusSets/DA/*"))
			// loading into the DA folder
			SetDataFolder GetWBSvdStimSetDAPath()
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet,"SavedStimulusSets/TTL/*"))
			// loading into the TTL folder
			SetDataFolder GetWBSvdStimSetTTLPath()
			HDF5LoadData /O /IGOR=-1 fileID, dataSet			
		endif
	endfor

	HDF5CloseFile fileID
	print "Stimulus Set Loaded..."
	
	// restore the data folder
	SetDataFolder savedDataFolder

	WBP_UpdateITCPanelPopUps()
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		HD_WriteAckWrapper(cmdID, TI_WRITEACK_SUCCESS)
	endif   	
End

///@brief Routine for saving the sweep data in hdf5 format.  This will allow for saving data in a smaller file size.
Function HD_SaveSweepData([cmdID])
	string cmdID
	
	// get the names of all the devices that have data present, regardless of being locked or not
	string dataPresentDevList = GetAllDevicesWithContent()
	variable noDataPresentDevs = ItemsInList(dataPresentDevList)

	string win, control
	variable value
	string currentPanel
	string groupString
	string fileLocation
	string savedDataFolder
	string dateTimeStamp
	String filename
	Variable root_id, h5_id
	variable i
	string fileLocationResponseString
	
	 // build up the filename using the time and date functions
 	fileLocation = "C:\\MiesHDF5Files\\SavedDataSets\\"
    	
	// Call this new function to insure that the folder actually exists on the disk
	CreateFolderOnDisk(fileLocation)
    	
    	dateTimeStamp = GetTimeStamp()
    	
    	// save the present data folder
	savedDataFolder = GetDataFolder(1)

	// build up the filename using the time and date functions
	sprintf filename, "%ssavedData_%s.h5", fileLocation, dateTimeStamp

	HDF5CreateFile h5_id as filename
	if (V_Flag != 0 ) // HDF5CreateFile failed
		print "HDF5Create File failed for ", filename
		print "Check file name format..."
		// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
		if(!ParamIsDefault(cmdID))
			HD_WriteAckWrapper(cmdID, TI_WRITEACK_FAILURE)
		endif
		return 0
	endif

	// Save the list of devices with dataPresent
	Make/O/T/N=1 dataPresentList = dataPresentDevList

	// run through all of the devices that have data present
	for (i = 0; i<noDataPresentDevs; i+= 1)
		currentPanel = StringFromList(i, dataPresentDevList)

		print "Saving data set for ", currentPanel

		// Set the data folder for the device specific lab notebook
		SetDataFolder GetDevSpecLabNBFolder(currentPanel)

		sprintf groupString "/%s_savedLabNotebook", currentPanel
		HDF5CreateGroup /Z h5_id, groupString, root_id
		HDF5SaveGroup /O /R  :, root_id, groupString
		HDF5CloseGroup root_id

		// Set the data folder to grab the device specific data sets
		SetDataFolder GetDeviceDataPath(currentPanel)

		sprintf groupString "/%s_savedDataSets", currentPanel
		HDF5CreateGroup /Z h5_id, groupString, root_id
		HDF5SaveGroup /O /R  :, root_id, groupString
		HDF5CloseGroup root_id

		print "Data set saved for ", currentPanel
	endfor

	// save the data present list
	HDF5SaveData /Z /O  dataPresentList, h5_id

	// and now kill the dataPresentList so its not floating around in the Mies dataspace
	KillWaves dataPresentList

	HDF5CloseFile h5_id
	print "HDF5 file save complete..."

	// restore the data folder
	SetDataFolder savedDataFolder
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		// build up the response string containing the file location for passing back to the WSE
		sprintf fileLocationResponseString "dataFile:%s", filename 
		HD_WriteAsyncResponseWrapper(cmdID, fileLocationResponseString)
	endif
End

/// @brief Parses list of controls from the DA_Ephys panel and removes the
/// variables associated with Amp settings and should not be saved or loaded
/// with other config settings
Static Function/S HD_GetConfigList(panelTitle)
	string panelTitle

	string list = controlNameList(panelTitle)
	string trimmedList, ampSettings
	variable i

	ampSettings = "Gain_DA_*;Unit_DA_*;Scale_DA_*;Gain_AD_*;Unit_AD_*;SetVar_Settings_*;SetVar_Hardware_*;" + \
				  "setvar_Settings_*;setvar_DataAcq_Hold_*;setvar_DataAcq_WC*;setvar_DataAcq_Rs*;"          + \
				  "setvar_DataAcq_PipetteOffset*;setvar_DataAcq_BB*"

	for(i=0;i<itemsinlist(ampSettings);i+=1)
		trimmedList = ListMatch(list, stringfromlist(i, ampSettings))
		list = removefromlist(trimmedList, list)
	endfor

	return list
End

///@brief Routine for saving all gui settings/switches/check boxes
Function HD_SaveConfiguration([cmdID])
	string cmdID

	// define variables
	string lockedDevList
	variable noLockedDevs
	string win, control
	string value
	String filename
	Variable root_id, h5_id
	string savedDataFolder
	String fileLocation
	string dateTimeStamp
	variable n, controlCounter, numControls
	string currentPanel
	string groupString
	string panelControlsList
	string currentControl
	string controlState
	variable configWaveSize
	string fileLocationResponseString

	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs = ItemsInList(lockedDevList)

	// save the present data folder
	savedDataFolder = GetDataFolder(1)

	// build up the filename using the time and date functions
	fileLocation = "c:\\MiesHDF5Files\\SavedConfigFiles\\"

	// Call this new function to insure that the folder actually exists on the disk
	CreateFolderOnDisk(fileLocation)

	dateTimeStamp = GetTimeStamp()
	sprintf filename, "%ssavedConfig_%s.h5", fileLocation, dateTimeStamp

	// run through the open and locked da_ephys panels
	// if no locked devices are found, don't save the configuration
	if (noLockedDevs == 0)
		print "No Locked Devices found...configuration settings not saved"

		// restore the data folder
		SetDataFolder savedDataFolder

		// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
		if(!ParamIsDefault(cmdID))
			HD_WriteAckWrapper(cmdID, TI_WRITEACK_FAILURE)
		endif
		return 0
	else
		HDF5CreateFile h5_id as filename
		if (V_Flag != 0 ) // HDF5CreateFile failed
			print "HDF5Create File failed for ", filename
			print "Check file name format..."

			// restore the data folder
			SetDataFolder savedDataFolder

			// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
			if(!ParamIsDefault(cmdID))
				HD_WriteAckWrapper(cmdID,TI_WRITEACK_FAILURE)
			endif
			return 0
		endif

		for (n = 0; n<noLockedDevs; n+= 1)
			currentPanel = StringFromList(n, lockedDevList)

			wave/T configWave = GetConfigSettingsWaveRef(currentPanel)

			print "Saving Configuration for ", currentPanel

			//Put the version string in the first column of the configWave
			// Version #
			SVAR versionString = $GetMiesVersion()
			configWave[0][0] = "Version #"
			configWave[1][0] = versionString

			// Now get the list of the control names for the current panel
			panelControlsList = HD_GetConfigList(currentPanel)
			numControls = ItemsInList(panelControlsList)
			for (controlCounter = 0; controlCounter<numControls;controlCounter+=1)
				currentControl = StringFromList(controlCounter, panelControlsList)			
				controlState = GetGuiControlState(currentPanel, currentControl)
				if(str2num(controlState) != 3)
					value = GetGuiControlValue(currentPanel, currentControl)
					if (!IsEmpty(value))
						// get the current configWaveSize
						configWaveSize = DimSize(configWave, 1)

						// now extend the wave by 1 to accomodate
						Redimension/N = (-1, configWaveSize + 1) configWave

						// and now stuff the info in the right place
						configWave[%settingName][configWaveSize] = currentControl
						configWave[%settingValue][configWaveSize] = value
						configWave[%controlState][configWaveSize] = controlState
					endif
				endif
			endfor

			// Set the data folder for saving the config settings stuff
			SetDataFolder GetDevSpecConfigSttngsWavePath(currentPanel)
			sprintf groupString "/%s", currentPanel
			HDF5CreateGroup /Z h5_id, groupString, root_id
			HDF5SaveGroup /O /R  :, root_id, groupString
			HDF5CloseGroup root_id

			print "Configuration saved for ", currentPanel

			// Now kill the configWave....since its only used for saving the configuration settings to hdf5, don't need it floating around anymore
			KillWaves ConfigWave
		endfor

		HDF5CloseFile h5_id
		print "HDF5 configuration saved to: ", filename
	endif

	// restore the data folder
	SetDataFolder savedDataFolder

	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		// build up the response string containing the file location for passing back to the WSE
		sprintf fileLocationResponseString "configFile:%s", filename
		HD_WriteAsyncResponseWrapper(cmdID, fileLocationResponseString)
	endif
End

/// @brief Load config settings from HDF5 file
Function HD_LoadConfigSet([incomingFileName, cmdID])
	string incomingFileName
	string cmdID
	    	    
	Variable fileID, waveCounter
	string dataSet
	string savedDataFolder
	string groupList
	variable groupItems
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	string panelControlsList
	variable numRemainingControls
	string currentControl
	variable configWaveSize
	variable controlCounter
	variable controlType
	
	// save the present data folder
	savedDataFolder = GetDataFolder(1)
	
	if( ParamIsDefault(incomingFileName) )
		NewPath/O miesHDF5ConfigStorage, "C:\\MiesHDF5Files\\SavedConfigFiles\\"
		HDF5OpenFile /R /Z /P=miesHDF5ConfigStorage fileID as ""	 // Displays a dialog
		KillPath/Z miesHDF5ConfigStorage
		if(V_flag == 0)				 // User selected a file?
			HDF5ListGroup /R=1 /TYPE=3 fileID, "/"
		else
			print "File load cancelled..."
			
			// restore the data folder
			SetDataFolder savedDataFolder
			return 0
		endif
	else
		if (StringMatch(incomingFileName, "c:\\MiesHDF5Files\\SavedConfigFiles\\savedConfig*") != 1)
			print "Not a valid config settings file....exiting..."
			
			// restore the data folder
			SetDataFolder savedDataFolder
			
			// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
			if(!ParamIsDefault(cmdID))
				HD_WriteAckWrapper(cmdID, TI_WRITEACK_FAILURE)
			endif
			return 0
		else
			HDF5OpenFile /R /Z fileID as incomingFileName // reads the incoming filename
			HDF5ListGroup /R=1 /TYPE=3 fileID, "/"	
		endif
	endif
    	
	groupList =  S_HDF5ListGroup 
	groupItems = ItemsInList(groupList)
	for(waveCounter = 0; waveCounter < groupItems; waveCounter += 1)
		dataSet = StringFromList(waveCounter, groupList)
		if (StringMatch(dataSet,"ITC*/*"))
			// get the da_ephys panel names
			lockedDevList = GetListOfLockedDevices()
			noLockedDevs = ItemsInList(lockedDevList)
			for (n = 0; n<noLockedDevs; n+= 1)
				currentPanel = StringFromList(n, lockedDevList)
				
				// Now get the list of the control names for the current panel...Now doing a trimmed list of controls...will not restore MCC amp settings
				panelControlsList = HD_GetConfigList(currentPanel)
				
				// load into the DA folder
				SetDataFolder GetDevSpecConfigSttngsWavePath(currentPanel)
				HDF5LoadData /O /IGOR=-1 fileID, dataSet
				
				wave/T configWave = GetConfigSettingsWaveRef(currentPanel)
				
				// Version #
				SVAR versionString = $GetMiesVersion()
				if (StringMatch(versionString, configWave[%settingValue][%version]) != 1)
					print "MIES Versions do not match....proceed with caution..."
				endif			
				
				configWaveSize = DimSize(configWave, 1)
				for (controlCounter = 1; controlCounter<configWaveSize;controlCounter+=1) // start at column 1...column zero is the version number
					// Some times the values saved are blanks...so need to send the value as a string and let the SetGuiControlValue decide what to do with it
					SetGuiControlValue(currentPanel, configWave[%settingName][controlCounter],configWave[%settingValue][controlCounter])
					// also set the control state
					SetGuiControlState(currentPanel, configWave[%settingName][controlCounter], configWave[%controlState][controlCounter])
					
					// Now remove that control name from the panelsControlList
					panelControlsList = RemoveFromList(configWave[%settingName][controlCounter], panelControlsList)
				endfor
				
				// Go through the remaining controls not restored, and see if they are a valid control...or one that we shouldn't worry about, like the tab or somethign similar
				numRemainingControls = ItemsInList(panelControlsList)
				print "The following controls were not restored"
				for (n = 0;n<numRemainingControls;n+=1)
					currentControl = StringFromList(n, panelControlsList)
					ControlInfo/W=$currentPanel $currentControl
					ASSERT(V_flag != 0, "Non-existing control or window")
					controlType = abs(V_flag)
					if((controlType == 2) || (controlType == 5) || (controlType == 7))
						print "Control: ", currentControl
					endif
				endfor			
			endfor				
		endif
	endfor
	
	HDF5CloseFile fileID
	print "Configuration Settings Loaded..."
	
	// Now kill the configWave....since its only used for saving the configuration settings to hdf5, don't need it floating around anymore
	KillWaves ConfigWave
	
	// restore the data folder
	SetDataFolder savedDataFolder
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		HD_WriteAckWrapper(cmdID,TI_WRITEACK_SUCCESS)
	endif		   	
End

/// @brief Load previous data sets from HDF5 file for viewing with the wave browser.  If there is a data wave with a matching name already present, it will be overwritten and replaced
Function HD_LoadDataSet([incomingFileName, cmdID])
	string incomingFileName
	string cmdID
	
	variable fileID, waveCounter
	string dataSet
	string dataFolderString
	string savedDataFolder
	string groupList 
	variable groupItems
	string devName 
	string devNumber
	string restOfName
	string panelName
	variable dataObjectsPresent
	variable nextSweepNumber
	string advanceSweepNumberString
    	
	// save the present data folder
	savedDataFolder = GetDataFolder(1)
	
	if(ParamIsDefault(incomingFileName))
		NewPath/O miesHDF5DataStorage, "C:\\MiesHDF5Files\\SavedDataSets"
		HDF5OpenFile /R /Z /P=miesHDF5DataStorage fileID as ""	 // Displays a dialog
		KillPath/Z miesHDF5DataStorage
		if(V_flag != 0) // User cancelled the dialog
			print "File load cancelled..."
			return 0
		endif
	elseif(StringMatch(incomingFileName, "*savedData*") != 1)
		print "Not a valid data set file....exiting..."
		
		// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
		if(!ParamIsDefault(cmdID))
			HD_WriteAckWrapper(cmdID, TI_WRITEACK_FAILURE)
		endif
		return 0
	else
		HDF5OpenFile /R /Z fileID as incomingFileName // reads the incoming filename
	endif

	HDF5ListGroup /R=1 /TYPE=3 fileID, "/"
	groupList = S_HDF5ListGroup 
	
	groupList =  S_HDF5ListGroup	
	groupItems = ItemsInList(groupList)
	
	// check and make sure this is a saved data set
	if (FindListItem("dataPresentList", groupList) == -1)
		print "This is not a valid data set file.  Please select a valid data set file..."
		// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
		if(!ParamIsDefault(cmdID))
			HD_WriteAckWrapper(cmdID, TI_WRITEACK_FAILURE)
		endif
		return 0
	endif 

	for(waveCounter = 0; waveCounter < groupItems;waveCounter += 1)
		dataSet = StringFromList(waveCounter, groupList)
		if(StringMatch(dataSet, "*savedDataSets"))
			devName = StringFromList(0, dataSet, "_")
			devNumber = StringFromList(2, dataSet, "_")
			restOfName = StringFromList(3, dataSet, "_")
			panelName = BuildDeviceString(devName, devNumber)
			// Before restoring any of the saved sweeps, check to see if there has already been data collected.  
			// If there has been, pop up an alert window to make sure the user really wants to do this
			dataObjectsPresent = CountObjectsDFR(GetDeviceDataPath(panelName), 1)
			if(dataObjectsPresent > 0)
				DoAlert/T="Sweep Data Restore" 1, "Sweep Data has already been collected.  Restoring a Sweep Data Set will overwrite this data.  Do you wish to proceed with the Restore Sweep Data?"
				if(V_flag == 2)
					print "Sweep Data Restore cancelled..."
					// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
					if(!ParamIsDefault(cmdID))
						HD_WriteAckWrapper(cmdID, TI_WRITEACK_FAILURE)
					endif
					return 0
				else
					print "Sweep Data being restored..."
				endif
			endif
		elseif(StringMatch(dataSet, "*savedLabNotebook/settingsHistory"))
			devName = StringFromList(0, dataSet, "_")
			devNumber = StringFromList(2, dataSet, "_")
			restOfName = StringFromList(3, dataSet, "_")
			panelName = BuildDeviceString(devName, devNumber)
			// Also check to see if a test pulse has been run, without any data sweeps.  Restoring the saved data will overwrite the labNoteBook and the keyWave values for the testPulse already run
			dataObjectsPresent = CountObjectsDFR(GetDevSpecLabNBSettKeyFolder(panelName), 1)
			if(dataObjectsPresent > 0)
				DoAlert/T="Sweep Data Restore" 1, "Settings History Data has already been collected.  Restoring a Sweep Data Set will overwrite this data.  Do you wish to proceed with the Restore Sweep Data?"
				if(V_flag == 2)
					print "Sweep Data Restore cancelled..."
					// determine if the cmdID was provided.  If so, return the -1 error code to the WSE
					if(!ParamIsDefault(cmdID))
						HD_WriteAckWrapper(cmdID, TI_WRITEACK_FAILURE)
					endif
					return 0
				else
					print "Sweep Data being restored..."
				endif
			endif
		endif
	endfor
	
	// Now that we've checked about the existance of previously collected data, and made sure the user really wants to do this, we chug through the data sets and do the loadData stuff
	for(waveCounter = 0; waveCounter < groupItems;waveCounter += 1)
		dataSet = StringFromList(waveCounter, groupList)
		if(StringMatch(dataSet, "*savedDataSets/*"))
			SetDataFolder GetDeviceDataPath(panelName)
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet, "*savedLabNotebook/analysisSettings/*"))
			SetDataFolder GetDevSpecAnlyssSttngsWavePath(panelName)
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet, "*savedLabNotebook/KeyWave/*"))
			SetDataFolder GetDevSpecLabNBSettKeyFolder(panelName)
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif (StringMatch(dataSet, "*savedLabNotebook/settingsHistory/*"))
			SetDataFolder GetDevSpecLabNBSettHistFolder(panelName)
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet, "*savedLabNotebook/TextDocKeyWave/*"))
			SetDataFolder GetDevSpecLabNBTxtDocKeyFolder(panelName)
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet, "*savedLabNotebook/textDocumentation/*"))
			SetDataFolder GetDevSpecLabNBTextDocFolder(panelName)
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		elseif(StringMatch(dataSet, "*savedLabNotebook/*")) // has to be the last in the list
			SetDataFolder GetDevSpecLabNBFolder(panelName)
			HDF5LoadData /O /IGOR=-1 fileID, dataSet
		endif
	endfor	

	HDF5CloseFile fileID
	print "Data Set Loaded..."
	
	// Now ask the user if they want to advance the NextSweepNumber to append any new sweep data, rather then overwrite one of the sweeps just restored
	nextSweepNumber = AFH_GetLastSweepAcquired(panelName) + 1
	if(nextSweepNumber != GetSetVariable(panelName, "SetVar_Sweep"))	
		advanceSweepNumberString = "Advance Next Sweep Number to " + Num2Str(nextSweepNumber) + "?"
		DoAlert/T="Advance Sweep Number" 1, advanceSweepNumberString
		if(V_flag == 2)
			print "Sweep Number advance cancelled..."
		else
			print "Advancing Sweep Number"
			SetSetVariable(panelName, "SetVar_Sweep", nextSweepNumber)
		endif
	endif
	
	// restore the original data folder
	SetDataFolder savedDataFolder
	
	// determine if the cmdID was provided
	if(!ParamIsDefault(cmdID))
		HD_WriteAckWrapper(cmdID, TI_WRITEACK_SUCCESS)
	endif 
End

/// @brief Prototype function to allow HDF5 function to write async responses, with return strings, to the WSE
Function HD_WriteAsyncResponseProto(cmdID, returnString)
	string cmdID, returnString

	DoAbortNow("Impossible to find the function TI_WriteAsyncResponse\rWas the tango XOP and the includes loaded?")
End

/// @brief Wrapper for the optional tango related function #HD_WriteAsyncResponseWrapper
/// The approach here using a function reference and an interpreted string like `$""` allows
/// to convert the dependency on the function TI_WriteAsyncResponse from compile time to runtime.
/// This function will call TI_WriteAsyncResponse if it can be found, otherwise HD_WriteAsyncResponseProto is called.
Static Function HD_WriteAsyncResponseWrapper(cmdID, returnString)
	string cmdID, returnString

	FUNCREF HD_WriteAsyncResponseProto f = $"TI_WriteAsyncResponse"

	return f(cmdID, returnString)
End

/// @brief Prototype function to allow HDF5 functions to write ack responses to the WSE
Function HD_WriteAckProto(cmdID, returnValue)
	string cmdID
	variable returnValue

	DoAbortNow("Impossible to find the function TI_WriteAck\rWas the tango XOP and the includes loaded?")
End

/// @brief Wrapper for the optional tango related function #HD_WriteAckWrapper
/// The approach here using a function reference and an interpreted string like `$""` allows
/// to convert the dependency on the function TI_WriteAck from compile time to runtime.
/// This function will call TI_WriteAck if it can be found, otherwise HD_WriteAckProto is called.
Static Function HD_WriteAckWrapper(cmdID, returnValue)
	string cmdID
	variable returnValue

	FUNCREF HD_WriteAckProto f = $"TI_WriteAck"

	return f(cmdID, returnValue)
End
