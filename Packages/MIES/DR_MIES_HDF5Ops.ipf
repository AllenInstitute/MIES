#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "HDF Utilities"
#include "HDF5 Browser"

Menu "HDF5 Tools"
		"Open HDF5 Browser", CreateNewHDF5Browser()
		"Save HDF5 File", convert_to_hdf5("menuSaveFile.h5")	
End

/// @brief Save all data as HDF5 file...must be passed a saveFilename with full path...with double \'s...ie "c:\\test.h5"
Function TangoHDF5Save(saveFilename)
	string saveFilename

	convert_to_hdf5(saveFilename)
End

/// @brief dump all experiment data to HDF5 file
Function convert_to_hdf5(filename)
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
Function hdf5_structure(h5_id)
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
Function create_dataset(h5_id, sweep_name, data)
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
	ident_stimulus(current_0, dt[0], stim_characteristics)
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
Function ident_stimulus(current, dt, stim_characteristics)
	Wave current
	Variable dt
	Wave stim_characteristics

	ASSERT(DimSize(current,ROWS) > 0,"expected non-empty wave")
	ASSERT(DimSize(stim_characteristics,ROWS) > 5,"expected wave with at least 5 rows")

	// variables to track stimulus characteristics
	Variable polarity = 0 // >0 when i increasing; <0 when i decreasing
	Variable flips = 0 // number of polarity shifts
	Variable changes = 0 // number of changes in i
	Variable peak = 0 // peak current
	Variable start = 0
	Variable stop = 0
	Variable last = current[0]

	// characterize stimulus, using current polarity and amplitude changes
	Variable n = DimSize(current, 0)
	Variable i, cur
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

	Variable t = (n-1) * dt
	Variable dur = (stop - start) * dt
	Variable onset = start * dt
	Variable type = TYPE_UNKNOWN // default to unknown

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