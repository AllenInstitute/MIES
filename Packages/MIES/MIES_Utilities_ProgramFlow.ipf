#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_PROGRAMFLOW
#endif

/// @file MIES_Utilities_ProgramFlow.ipf
/// @brief utility functions for program flow

/// @brief Helper function to ensure that there is no pending RTE before entering a critical section.
///        If there is a pending RTE then a BUG message is output (which is a CI error).
///
///        Not catching any pending RTE would clear this condition silently and valid errors would be
///        suppressed. This is dangerous in regards of data consistency.
///
///        Not clearing the RTE before calling `AbortOnRTE` will always trigger the
///        RTE no matter what you do in that line. Any call to GetRTErrMessage() must
///        be done prior to clearing the runtime error in the catch block.
///
/// Usage:
/// \rst
/// .. code-block:: igorpro
///
/// 	AssertOnAndClearRTError()
///    try
///      CriticalFunc(); AbortOnRTE
///    catch
///      msg = GetRTErrMessage()
///      err = ClearRTError()
///    endtry
///
/// \endrst
///
/// UTF_NOINSTRUMENTATION
threadsafe Function AssertOnAndClearRTError()

	string   msg
	variable err

	msg = GetRTErrMessage()
	err = ClearRTError()

	if(err)
		BUG_TS("Encountered pending RTE: " + num2istr(err) + ", " + msg)
	endif
End

/// @brief Helper function to unconditionally clear a RTE condition
///	        It is generally strongly recommended to use @sa AssertOnAndClearRTError
///        before critical code sections. For detailed description of the implications @sa AssertOnAndClearRTError
///
/// UTF_NOINSTRUMENTATION
threadsafe Function ClearRTError()

	return GetRTError(1)
End

/// @brief Return true if the calling function is called recursively, i.e. it
///        is present multiple times in the call stack
threadsafe Function IsFunctionCalledRecursively()
	return ItemsInList(ListMatch(GetRTStackInfo(0), GetRTStackInfo(2))) > 1
End

/// @brief Wrapper function for `Abort` which honours our interactive mode setting
Function DoAbortNow(msg)
	string msg

	DEBUGPRINTSTACKINFO()

	if(IsEmpty(msg))
		Abort
	endif

	NVAR/Z interactiveMode = $GetInteractiveMode()

	if(NVAR_Exists(interactiveMode) && interactiveMode)
		Abort msg
	else
		printf "Abort: %s\r", RemoveEnding(msg, "\r")
		Abort
	endif
End

/// @brief Return a nicely formatted multiline stacktrace
threadsafe Function/S GetStackTrace([prefix])
	string prefix

	string stacktrace, entry, func, line, file, str
	string output
	variable i, numCallers

	if(ParamIsDefault(prefix))
		prefix = ""
	endif

	stacktrace = GetRTStackInfo(3)
	numCallers = ItemsInList(stacktrace)

	if(numCallers < 3)
		// our caller was called directly
		return "Not available"
	endif

	if(IsEmpty(prefix))
		output = prefix
	else
		output = prefix + "\r"
	endif

	for(i = 0; i < numCallers - 2; i += 1)
		entry = StringFromList(i, stacktrace)
		func  = StringFromList(0, entry, ",")
		file  = StringFromList(1, entry, ",")
		line  = StringFromList(2, entry, ",")
		sprintf str, "%s%s(...)#L%s [%s]\r", prefix, func, line, file
		output += str
	endfor

	return output
End

/// @brief Low overhead function to check assertions
///
/// @param var            if zero an error message is printed into the history and procedure execution is aborted,
///                       nothing is done otherwise.  If the debugger is enabled, it also steps into it.
/// @param errorMsg       error message to output in failure case
/// @param extendedOutput [optional, defaults to true] Output additional information on failure
///
/// Example usage:
/// \rst
/// .. code-block:: igorpro
///
/// 	ControlInfo/W = $device popup_MoreSettings_DeviceType
/// 	ASSERT(V_flag > 0, "Non-existing control or window")
/// 	do something with S_value
/// \endrst
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
Function ASSERT(variable var, string errorMsg, [variable extendedOutput])
	string stracktrace, miesVersionStr, lockedDevicesStr, device
	string stacktrace = ""
	variable i, numLockedDevices, doCallDebugger

	try
		AbortOnValue var == 0, 1
	catch
		if(ParamIsDefault(extendedOutput))
			extendedOutput = 1
		else
			extendedOutput = !!extendedOutput
		endif

		doCallDebugger = 1

#ifdef AUTOMATED_TESTING
		doCallDebugger = 0
		extendedOutput = 0
#ifdef AUTOMATED_TESTING_DEBUGGING
		doCallDebugger = 1
		extendedOutput = 1
#endif // AUTOMATED_TESTING_DEBUGGING
#endif // AUTOMATED_TESTING

		// Recursion detection, if ASSERT appears multiple times in StackTrace
		if(IsFunctionCalledRecursively())

			// Happens e.g. when ASSERT is encounterd in cleanup functions
			print "Double Assertion Fail encountered !"
			print errorMsg
			print GetRTStackInfo(3)

			if(doCallDebugger)
				ControlWindowToFront()
				Debugger
			endif

			Abort
		endif

		print "!!! Assertion FAILED !!!"
		printf "Message: \"%s\"\r", RemoveEnding(errorMsg, "\r")

		if(extendedOutput)
			// hard coding the path here so that we don't depend on GetMiesVersion()
			// in MIES_GlobalStringAndVariableAccess.ipf
			SVAR/Z miesVersion = root:MIES:version

			if(SVAR_Exists(miesVersion))
				miesVersionStr = miesVersion
			else
				miesVersionStr = ""
			endif

			SVAR/Z lockedDevices = root:MIES:HardwareDevices:lockedDevices

			Make/FREE/T sweeps = {NONE}
			Make/FREE/T tpStates = {NONE}
			Make/FREE/T daqStates = {NONE}

			if(!SVAR_Exists(lockedDevices) || IsEmpty(lockedDevices))
				lockedDevicesStr = NONE
			else
				lockedDevicesStr = lockedDevices

				numLockedDevices = ItemsInList(lockedDevicesStr)

				Redimension/N=(numLockedDevices) sweeps, daqStates, tpStates

				for(i = 0; i < numLockedDevices; i += 1)
					device = StringFromList(i, lockedDevicesStr)
					NVAR runMode       = $GetDataAcqRunMode(device)
					NVAR testpulseMode = $GetTestpulseRunMode(device)

					sweeps[i]    = num2str(AFH_GetLastSweepAcquired(device))
					tpStates[i]  = TestPulseRunModeToString(testpulseMode)
					daqStates[i] = DAQRunModeToString(runMode)
				endfor
			endif

			print "Please provide the following information if you contact the MIES developers:"
			print "################################"
			print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

			stacktrace = GetStackTrace()
			print "Stacktrace:"
			print stacktrace

			print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			printf "Time: %s\r", GetIso8601TimeStamp(localTimeZone = 1)
			printf "Locked device: [%s]\r", RemoveEnding(lockedDevicesStr, ";")
			printf "Current sweep: [%s]\r", TextWaveToList(sweeps, ";", trailSep = 0)
			printf "DAQ: [%s]\r", TextWaveToList(daqStates, ";", trailSep = 0)
			printf "Testpulse: [%s]\r", TextWaveToList(tpStates, ";", trailSep = 0)
			printf "Experiment: %s (%s)\r", GetExperimentName(), GetExperimentFileType()
			printf "Igor Pro version: %s (%s)\r", GetIgorProVersion(), GetIgorProBuildVersion()
			print "MIES version:"
			print miesVersionStr
			print "################################"

			LOG_AddEntry(PACKAGE_MIES, LOG_ACTION_ASSERT, stacktrace = 1, keys = {LOG_MESSAGE_KEY}, values = {errorMsg})

			ControlWindowToFront()
		endif

		if(doCallDebugger)
			Debugger
		endif

		Abort
	endtry
End

/// @brief Low overhead function to check assertions (threadsafe variant)
///
/// @param var            if zero an error message is printed into the history and procedure
///                       execution is aborted, nothing is done otherwise.
/// @param errorMsg       error message to output in failure case
/// @param extendedOutput [optional, defaults to true] Output additional information on failure
///
/// Example usage:
/// \rst
///  .. code-block:: igorpro
///
///		ASSERT_TS(DataFolderExistsDFR(dfr), "dfr does not exist")
///		do something with dfr
/// \endrst
///
/// Unlike ASSERT() this function does not jump into the debugger (Igor Pro limitation).
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function ASSERT_TS(variable var, string errorMsg, [variable extendedOutput])
	string stacktrace

	try
		AbortOnValue var == 0, 1
	catch
		if(ParamIsDefault(extendedOutput))
			extendedOutput = 1
		else
			extendedOutput = !!extendedOutput
		endif

#ifdef AUTOMATED_TESTING
		extendedOutput = 0
#ifdef AUTOMATED_TESTING_DEBUGGING
		extendedOutput = 1
#endif // AUTOMATED_TESTING_DEBUGGING
#endif // AUTOMATED_TESTING

		// Recursion detection, if ASSERT_TS appears multiple times in StackTrace
		if(IsFunctionCalledRecursively())

			print "Double threadsafe assertion Fail encountered !"
			print errorMsg
			print GetRTStackInfo(3)

			AbortOnValue 1, 1
		endif

		print "!!! Threadsafe assertion FAILED !!!"
		printf "Message: \"%s\"\r", RemoveEnding(errorMsg, "\r")

		if(extendedOutput)
			print "Please provide the following information if you contact the MIES developers:"
			print "################################"
			print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			stacktrace = GetStackTrace()
			print "Stacktrace:"
			print stacktrace

			print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			printf "Time: %s\r", GetIso8601TimeStamp(localTimeZone = 1)
			printf "Experiment: %s (%s)\r", GetExperimentName(), GetExperimentFileType()
			printf "Igor Pro version: %s (%s)\r", GetIgorProVersion(), GetIgorProBuildVersion()
			print "################################"

			LOG_AddEntry(PACKAGE_MIES, LOG_ACTION_ASSERT, stacktrace = 1, keys = {LOG_MESSAGE_KEY}, values = {errorMsg})
		endif

		AbortOnValue 1, 1
	endtry
End

#ifdef MACINTOSH

threadsafe Function MU_RunningInMainThread()
	TUFXOP_RunningInMainThread

	return V_value
End

#endif
