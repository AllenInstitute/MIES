#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "tango"
#include "HDF Utilities"
#include "HDF5 Browser"

Menu "Mies Panels"
		"Start Polling WSE queue", StartTestTask()
		"Stop Polling WSE queue", StopTestTask()
End

Function writeLog(logMessage)
	String logMessage
	
	//- function arg: the name of the device on which the commands will be executed 
	String dev_name = "logger_device/LoggerDevice/test"
	
	//- verbose
	print "\rStarting <Tango-API::tango_cmd_io> test...\r"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "log"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = logMessage
  
	Variable mst_ref = StartMSTimer
  
	Variable mst_dt  
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)		
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> cmd passed\r"
	
End

Function initLog(dev)
	//- function arg: the name of the device on which the commands will be executed 
	String dev
	
  
	//- verbose
	print "\rStarting <Tango-API::tango_cmd_io> test...\r"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "Init"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = "hello world"
  
	Variable mst_ref = StartMSTimer
  
  	Variable mst_dt
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> cmd passed\r"
	
End

Function readImage(dev_name)
//- function arg: the name of the device on which the attributes will be read
	String dev_name
  
	//- verbose
	print "\rStarting <Tango-API::tango_read_attr> test...\r"
  
   	//- create a root:tmp datafolder and make it the current datafolder
  	//- this function is kind enough to create all the datafolders along
  	//- the speciifed path in case they don't exist. great, isn't it?
  	tools_df_make("root:tmp", 1)
  	
	//- let's declare our <AttributeValue> structure. 
	//- be aware that <av> will be overwritten (and reset) each time we read
	//- an attribute. it means that you must use another <AttributeValue> if case 
	//- you want to store more than one attribue value at a time. here we reuse 
	//- <av> for each attribute reading 
	Struct AttributeValue av
  
	//- for 'technical reasons', the AttributeValue must be initialized 
	//- this ensures that everything is properly setup 
	tango_init_attr_val(av)
  
	//- populate attr_val: <dev> struct member
	//- the name of the device on which the attribute will be read
	//- NB: since the attributes will be read on the same device (i.e. dev_name), 
	//- we set the <AttributeValue.dev> struct member only once (i.e. no need to 
	//- set it not each time we read a attribute)  
	av.dev = dev_name
	
	av.attr = "image"
	av.val_path=""
	Variable mst_ref = StartMSTimer 
	Variable mst_dt
	if (tango_read_attr (av) == -1)
		tango_display_error()
		mst_dt = StopMSTimer(mst_ref)
		return kERROR
	endif
 	mst_dt = StopMSTimer(mst_ref)
	tango_dump_attribute_value (av)
	print "\t-read took......." + num2str(mst_dt / 1000) + " ms to complete"
	
		//- no error - great!
	print "\r<Tango-API::tango_read_attr> : TEST PASSED\r"
	
	//- for test purpose will delete any datafolder created in this function
	//tools_df_delete("root:tmp")
	
	return kNO_ERROR
end

Function throwError(dev_name)
	String dev_name
	
	//- verbose
	print "\rStarting <Tango-API::tango_cmd_io> test...\r"
  
	//- let's declare our <argin> and <argout> structures. 
	//- be aware that <argout> will be overwritten (and reset) each time we execute a 
	//- command it means that you must use another <CmdArgOut> if case you want to 
	//- store more than one command result at a time. here we reuse both argin and 
	//- argout for each command.

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "throw"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = "Invalid Mies command"
  
	Variable mst_ref = StartMSTimer
  	Variable mst_dt
  	
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> throw cmd passed\r"
	
End	

Function readSequenceQueue(dev_name)
	String dev_name
	
	//-verbose
	print "\rStarting Tango based interface to Sequencing Queue...\r"

	//- argin
	Struct CmdArgIO argin
	tango_init_cmd_argio (argin)
	
	//- argout 
	Struct CmdArgIO argout
	tango_init_cmd_argio (argout)	
	
	//- populate argin: <CmdArgIn.cmd> struct member
	//- name of the command to be executed on <argin.dev> 
	String cmd = "get"

	//- verbose
	print "\rexecuting <" + cmd + ">...\r"
  
	//- since the command argin is a string scalar (i.e. single string), we stored its its value 
	//- into the <str> member of the <CmdArgIn> structure. 
	argin.str_val = "hello world"
  
	Variable mst_ref = StartMSTimer
	Variable mst_dt
	
	//- actual cmd execution
	//- if an error occurs during command execution, argout is undefined (null or empty members)
	//- ALWAYS CHECK THE CMD RESULT BEFORE TRYING TO ACCESS ARGOUT: 0 means NO_ERROR, -1 means ERROR
	if (tango_cmd_inout(dev_name, cmd, arg_in = argin, arg_out = argout) == -1)
		//- the cmd failed, display error...
		print "cmd failed..."
		tango_display_error()
		//- ... then return error
		mst_dt = StopMSTimer(mst_ref)
		return kERROR
	endif
  
	mst_dt = StopMSTimer(mst_ref)
	print "\t'-> took " + num2str(mst_dt / 1000) + " ms to complete"
	
	//- <argout> is populated (i.e. filled) by <tango_cmd_inout> uppon return of the command.
	//- since the command ouput argument is a string scalar (i.e. single string), it is stored 
	//- in the <str> member of the <CmdArgOut> structure.

	//- as previously explained, we are testing our TANGO binding on a TangoTest device. 
	//- consequently, we check that <argin.str == argout.str> in order to be sure that everything is ok
	
	print "Command found: " + argout.str_val
	string cmdToRun = argout.str_val

	if (cmpStr(cmdToRun, "NONE") == 1)
		print "No Mies command found on Messaging queue..."
	else
		Execute/Z cmdToRun
		if (V_Flag != 0)
			print "Unable to run command....check command syntax..."
			throwError("mies_device/MiesDevice/test")
			writeLog("improper Mies Command requested...")
		else
			print "Command ran successfully..."
			writeLog("Mies command ran successfully....")
		endif
	endif
	
//	if (cmpstr(argin.str_val, argout.str_val) != 0)
//		//- the cmd failed, display error...
//		print "cmd failed...display error"
//		tango_display_error_str("ERROR:DevString:unexpected cmd result - aborting test")
//		//- ... then return error
//		return kERROR
//	endif
  
	//- verbose
	print "\t'-> cmd passed\r"
	
End

Function sequenceTask(s)											// This is the function that will be called periodically
	STRUCT WMBackgroundStruct &s
	
	Printf "Task %s called, ticks=%d\r", s.name, s.curRunTicks
	readSequenceQueue("mies_device/MiesDevice/test")
	return 0	// Continue background task
End

Function StartTestTask()
	Variable numTicks = 10 * 60		// Run every ten seconds (600 ticks)
	CtrlNamedBackground Test, period=numTicks, proc=sequenceTask
	CtrlNamedBackground Test, start
End

Function StopTestTask()
	print "Ending polling task..."
	CtrlNamedBackground Test, stop
End

// function to save Mies Experiment as a packed experiment
Function TangoSave(saveFileName)
	string saveFileName
	
	Variable result = 0
	string dfPath = "."
	string uxtFileName = saveFileName + ".uxt"
	//first, save as unpacked experiment
	if (stringMatch(uxtFileName, "*.uxt") == 1)		
		SaveExperiment/C/F={1,"",2}/P=home as uxtFileName
		print "Packed Experiment Save Success!"
	else
		print "File Name must end with .uxt!  Please re-enter and try again!"
	endif
End

Function TangoHDF5Save(saveFilename)
	string saveFileName
	
	string hd5FileName = saveFileName + ".h5"
	print "hd5FileName: ", hd5FileName
	
	convert_to_hdf5(hd5FileName)
	
End

//////////////////////////////////
Function convert_to_hdf5(filename)
	String filename
	Variable num_dirs, i, j, h5_id
	String dir_name, wave_list, wave_name, path
	// move down folder structure looking for where data is stored
	// assume that hardware device name starts with "I"
	SetDataFolder root:
	num_dirs = CountObjects(":", 4)
	print "num_dirs: ", num_dirs
	for (i=0; i<num_dirs; i+=1)
		dir_name = GetIndexedObjName(":", 4, i)
		print "dir_name: ", dir_name
		if (stringmatch(dir_name[0], "I"))
			break
		endif
	endfor
	path = "root:" + dir_name + ":ITCDevices:ITC18USB:Device0:Data:"
	//print "dir_name: ", dir_name
	//print "hdf5 path: ", path
	
	SetDataFolder path
	print "about to create hdf5..."
	
	HDF5CreateFile /O /Z h5_id as filename
	if (V_flag != 0)
		print "HDF5CreateFile failed"
		return -1
	endif
	hdf5_structure(h5_id)
	// foreach wave, extract data from project and write to hdf5 file
	wave_list = WaveList("Sweep_*", ";", "")
	j = strlen(wave_list)
	for (i=0; i<j; i+=1)
		wave_name = StringFromList(i, wave_list)
		if(isEmpty(wave_name))
			break
		endif
		// ignore DA0 and AD0
		if ((strsearch(wave_name, "AD0", 0) > 0) || (strsearch(wave_name, "DA0", 0) > 0))
			continue
		endif
		Wave data = $wave_name
		print("Processing " + wave_name)
		create_dataset(h5_id, wave_name, data)
	endfor
	HDF5CloseFile h5_id
	print "HDF5 save complete..."
End	

// creates high-level group structure of HDF5 file
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

//////////////////////////////////
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
	Make /O /N=1 dt = 1e-6 * cfg[0][2][0]
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
	Make /O /N=1 rate = (1.0 / dt)
	HDF5SaveData /O /Z rate, sweep_id
	if (V_flag != 0)
		print "HDF5SaveData failed (rate)"
		return -1
	endif
	// calculate and store sweep duration
	Make /O /N=1 duration = (dt * (DimSize(v_0, 0)-1))
	HDF5SaveData /O /Z duration, sweep_id
	if (V_flag != 0)
		print "HDF5SaveData failed (duration)"
		return -1
	endif
End

// categorize stimulus and extract some features
Function ident_stimulus(current, dt, stim_characteristics)
	Wave current
	Variable dt
	Wave stim_characteristics
	
	ASSERT(DimSize(current,ROWS) > 0,"expected non-empty wave")
	ASSERT(DimSize(stim_characteristics,ROWS) > 5,"expected wave with at least 5 rows")
	
	///////////////////////////
	// stimulus type constants
	// TODO move these to a better location
	Variable TYPE_UNKNOWN = 0
	Variable TYPE_NULL = 1
	Variable TYPE_STEP = 2
	Variable TYPE_PULSE = 3	// pulse defined as step that lasts less than 20ms
	Variable TYPE_RAMP = 4
	//////////////////////////
	// variables to track stimulus characteristics
	Variable polarity = 0	// >0 when i increasing; <0 when i decreasing
	Variable flips = 0	// number of polarity shifts
	Variable changes = 0	// number of changes in i
	Variable peak = 0	// peak current
	Variable start = 0
	Variable stop = 0
	Variable last = current[0]
	//////////////////////////
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
			// stimulus just started -- assign initial polarity
			if (cur > 0)
				polarity = 1
			else
				polarity = -1
			endif
			start = i
		elseif (polarity == -1)
			// current was decreasing
			if (cur > last)
				// current now on upswing -- record polarity shift
				polarity = 1
				flips += 1
			endif
		else	// polarity == 1
			// current has been increasing
			if (cur < last)
				// current now decreasing -- record polarity shift
				polarity = -1
				flips += 1
			endif
		endif
		if (abs(cur) > abs(peak))
			peak = cur
		endif
		if ((cur == 0) && (last != 0))
			// current returned to zero -- store this as potential end
			//   of stimulus
			stop = i
		endif
		last = cur
	endfor
	Variable t = (n-1) * dt
	Variable dur = (stop - start) * dt
	Variable onset = start * dt
	Variable type = TYPE_UNKNOWN // default to unknown
	if (changes == 2)
		if (dur < 0.020)
			type = TYPE_PULSE
		else
			type = TYPE_STEP
		endif
	elseif (flips == 1)
		// too many current changes for step, but only one flip
		// this must be a ramp
		type = TYPE_RAMP
	elseif ((flips == 0) && (changes == 0))
		// no stimulus
		type = TYPE_NULL
	endif
	// store results in vector -- this is more friendly for hdf5 storage
	stim_characteristics[0] = type
	stim_characteristics[1] = t
	stim_characteristics[2] = onset
	stim_characteristics[3] = dur
	stim_characteristics[4] = peak
End

