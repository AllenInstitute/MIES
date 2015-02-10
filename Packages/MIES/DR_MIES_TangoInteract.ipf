#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "tango"

Menu "Mies Panels"
		"Start Polling WSE queue", StartTestTask()
		"Stop Polling WSE queue", StopTestTask()
End

/// @brief Save all data as HDF5 file...must be passed a saveFilename with full path...with double \'s...ie "c:\\test.h5"
Function TangoHDF5Save(saveFilename)
	string saveFilename

	convert_to_hdf5(saveFilename)
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

/// @brief Save Mies Experiment as a packed experiment
Function TangoSave(saveFileName)
	string saveFileName
	
	//save as packed experiment
	SaveExperiment/C/F={1,"",2}/P=home as saveFileName + ".pxp"
	print "Packed Experiment Save Success!"
End

