#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_UTILS_SYSTEM
#endif // AUTOMATED_TESTING

/// @file MIES_Utilities_System.ipf
/// @brief utility functions for system operations

static Constant UPLOAD_MIN_RATE     = 2e6 ///< Minimum upload rate in bit/s, slower uploads time out
static Constant UPLOAD_BASE_TIMEOUT = 15  ///< Timeout in s which is added for the connection overhead

static Constant URLREQUEST_TIMEOUT_ERROR = 8028 ///< Igor error code of URLRequest for "The network library timeout was reached."
static Constant HTTP_STATUS_OK           = 200

/// @brief Return the name of the experiment without the file suffix
threadsafe Function/S GetExperimentName()

	return IgorInfo(1)
End

/// @brief Return the experiment file type
threadsafe Function/S GetExperimentFileType()

	return IgorInfo(11)

End

/// @brief Return the modified state of the experiment
Function GetExperimentModified()

	ExperimentModified
	return V_flag
End

/// @brief Mark the experiment as unmodified if it was unmodified before, see GetExperimentModified()
Function RestoreExperimentModified(variable modifiedBefore)

	if(!modifiedBefore)
		ExperimentModified 0
	endif
End

/// @brief Return the amount of free memory in GB
///
/// Due to memory fragmentation you can not assume that you can still create a wave
/// occupying as much space as returned.
threadsafe Function GetFreeMemory()

	variable freeMem

#if defined(IGOR64)
	freeMem = NumberByKey("PHYSMEM", IgorInfo(0)) - NumberByKey("USEDPHYSMEM", IgorInfo(0))
#else
	freeMem = NumberByKey("FREEMEM", IgorInfo(0))
#endif

	return freeMem / 1024 / 1024 / 1024
End

/// @brief Check wether the given background task is currently running
///
/// Note:
/// Background functions which are currently waiting for their
/// period to be reached are also running.
///
/// @param task Named background task identifier, this is *not* the function set with `proc=`
Function IsBackgroundTaskRunning(string task)

	CtrlNamedBackground $task, status
	return NumberByKey("RUN", s_info)
End

/// @brief Query a numeric option settable with `SetIgorOption`
///
/// @param name         name of the keyword/setting
/// @param globalSymbol [optional, defaults to false] `name` refers to a global
///                     symbol set via `poundDefine`
Function QuerySetIgorOption(string name, [variable globalSymbol])

	string   cmd
	variable result

	if(ParamIsDefault(globalSymbol))
		globalSymbol = 0
	else
		globalSymbol = !!globalSymbol
	endif

	DFREF dfr = GetDataFolderDFR()

	// we remove V_flag as the existence of it determines
	// if the operation was successfull
	KillVariables/Z V_Flag

	if(globalSymbol)
		sprintf cmd, "SetIgorOption poundDefine=%s?", name
	else
		sprintf cmd, "SetIgorOption %s=?", name
	endif

	Execute/Q/Z cmd

	NVAR/Z/SDFR=dfr flag = V_Flag
	if(!NVAR_Exists(flag))
		return NaN
	endif

	result = flag
	KillVariables/Z flag

	return result
End

/// @brief Force recompilation of all procedure files
///
/// Uses the "Operation Queue".
Function ForceRecompile()

	Execute/P/Q "Silent 100"
End

/// @brief Return the disc folder name where the XOPs are located
///
/// Distinguishes between i386 and x64 Igor versions
Function/S GetIgorExtensionFolderName()

#if defined(IGOR64)
	return "Igor Extensions (64-bit)"
#else
	return "Igor Extensions"
#endif
End

/// @brief Return an Igor-style path to the Igor Pro executable
Function/S GetIgorExecutable()

	string path = SpecialDirPath("Igor Executable", 0, 0, 0)

#ifdef IGOR64
	return path + "Igor64.exe"
#else
	return path + "Igor.exe"
#endif // IGOR64
End

/// @brief Return the folder "Python Scripts" usable with Igor Pro 10 or higher
Function/S GetPythonScriptsFolder()

	string path = SpecialDirPath("Igor Pro User Files", 0, 0, 0) + "Python Scripts:"
	CreateFolderOnDisk(path)

	return path
End

/// @brief Return the number of bits of the architecture
///        Igor Pro was built for.
Function GetArchitectureBits()

#if defined(IGOR64)
	return 64
#else
	return 32
#endif
End

/// @brief Return the given IgorInfo (cached)
///
/// This is faster than calling `IgorInfo` everytime.
threadsafe Function/S GetIgorInfo(variable selector)

	string key

	key = CA_IgorInfoKey(selector)
	WAVE/Z/T result = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(!WaveExists(result))
		Make/FREE/T result = {IgorInfo(selector)}
		CA_StoreEntryIntoCache(key, result, options = CA_OPTS_NO_DUPLICATE)
	endif

	return result[0]
End

/// @brief Return the Igor Pro version string
threadsafe Function/S GetIgorProVersion()

	return StringByKey("IGORFILEVERSION", GetIgorInfo(3))
End

/// @brief Return the major Igor Pro version
threadsafe Function GetIgorProMajorVersion()

	return floor(IgorVersion())
End

/// @brief Return the Igor Pro build version string
///
/// This allows to distinguish different builds from the same major/minor
/// version.
threadsafe Function/S GetIgorProBuildVersion()

	return StringByKey("BUILD", GetIgorInfo(0))
End

/// @brief Return the user name of the running user
Function/S GetSystemUserName()

	variable numElements
	string   path

	// example: C:Users:thomas:AppData:Roaming:WaveMetrics:Igor Pro 7:Packages:
	path        = SpecialDirPath("Packages", 0, 0, 0)
	numElements = ItemsInList(path, ":")
	ASSERT(numElements > 3, "Unexpected format")

	return StringFromList(2, path, ":")
End

/// @brief Bring the control window (the window with the command line) to the
///        front of the desktop
Function ControlWindowToFront()

	DoWindow/H
End

/// @brief Execute a list of functions via the Operation Queue
///
/// Special purpose function. Not intended for normal use.
Function ExecuteListOfFunctions(string funcList)

	variable i, numEntries
	string func

	numEntries = ItemsInList(funcList)
	for(i = 0; i < numEntries; i += 1)
		func = StringFromList(i, funcList)

		if(IsEmpty(func))
			continue
		endif

		Execute/P/Q func
	endfor
End

/// @brief High precision version of the builtin Sleep command
///
/// @param var time in seconds to busy-sleep (current precision is around 0.1ms)
Function SleepHighPrecision(variable var)

	ASSERT(var >= 0, "Invalid duration")

	variable refTime = RelativeNowHighPrec() + var
	for(;;)
		if(abs(RelativeNowHighPrec() - refTime) < 100e-6)
			break
		endif
	endfor
End

/// @brief Return the machine epsilon for the given wave type
///
/// Experimentally determined with Igor Pro 7.08
Function GetMachineEpsilon(variable type)

	type = ClearBit(type, IGOR_TYPE_UNSIGNED)
	ASSERT((type & IGOR_TYPE_COMPLEX) == 0, "Complex waves are not supported")

	switch(type)
		case IGOR_TYPE_64BIT_FLOAT:
			return 2^-52
		case IGOR_TYPE_32BIT_FLOAT:
			return 2^-23
		case IGOR_TYPE_64BIT_INT: // fallthrough
		case IGOR_TYPE_32BIT_INT: // fallthrough
		case IGOR_TYPE_16BIT_INT: // fallthrough
		case IGOR_TYPE_8BIT_INT:
			return 1
		default:
			FATAL_ERROR("Unsupported wave type")
	endswitch
End

/// @brief Create the special Notebook "HistoryCarbonCopy" which will hold
///        a readable copy of the history starting from the time of the
///        notebook creation.
Function CreateHistoryNotebook()

	NewNotebook/K=2/V=0/F=0/N=HistoryCarbonCopy
End

/// @brief Return the text of the history notebook
Function/S GetHistoryNotebookText()

	if(!WindowExists("HistoryCarbonCopy"))
		return ""
	endif

	return GetNotebookText("HistoryCarbonCopy")
End

/// @brief Returns the process id of this process
Function GetProcessId()

	ExecuteScriptText/B/Z "powershell.exe -nologo -noprofile -command \"(gwmi win32_process | ? processid -eq  $pid).parentprocessid\""
	ASSERT(!V_flag, "Error executing process")

	return str2num(S_Value)
End

/// @brief Return the per application setting of ASLR for the Igor Pro executable
///
/// See https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-exploit-guard/enable-exploit-protection
/// for the powershell cmdlet documentation.
///
/// @returns 0 or 1
Function GetASLREnabledState()

	string cmd, entry, list, setting
	variable procId

	sprintf cmd, "powershell.exe -nologo -noprofile -command \"Get-ProcessMitigation -Id %d\"", GetProcessId()

	ExecuteScriptText/B/Z cmd

	ASSERT(!V_flag, "Error executing process mitigation querying script.")

	if(IsEmpty(S_Value))
		return 1 // assuming system default is on
	endif

	entry = GrepList(S_value, "^[[:space:]]*BottomUp", 0, "\r\n")
	ASSERT(ItemsInList(entry, "\r\n") == 1, "Expected results only for a single process")

	SplitString/E="^[[:space:]]*BottomUp[[:space:]]*: ([[:alnum:]]+)$" trimstring(entry), setting
	ASSERT(V_flag == 1, "Unexpected string")

	return !cmpstr(setting, "OFF") ? 0 : 1
End

/// @brief Turn off ASLR
///
/// Requires administrative privileges via UAC. Only required once for ITC hardware.
Function TurnOffASLR()

	string cmd, path

	path = GetFolder(FunctionPath("")) + ":ITCXOP2:tools:Disable-ASLR-for-Igor64.ps1"
	ASSERT(FileExists(path), "Could not locate powershell script")
	sprintf cmd, "powershell.exe -ExecutionPolicy Bypass \"%s\"", GetWindowsPath(path)
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_flag, "Error executing ASLR script")

	printf "Please restart Igor Pro as normal user and execute \"Mies Panels\"->\"Check installation\" to see if ASLR is now turned off or not.\r See also https://github.com/AllenInstitute/ITCXOP2#windows-10 for further manual instructions.\r"
End

/// @brief Check if we are running on Windows 10/11
Function IsWindows10Or11()

	string info, os

	info = IgorInfo(3)
	os   = StringByKey("OS", info)
	return GrepString(os, "^(Microsoft )?Windows 1[01]? ")
End

Function UploadJSONPayloadAsync(variable jsonID)

	DFREF threadDFR = ASYNC_PrepareDF("UploadJSONPayloadAsyncWorker", "UploadJSONPayloadAsyncReadout", WORKLOADCLASS_URL, inOrder = 0)

	ASYNC_AddParam(threadDFR, var = jsonID, name = "jsonID")

	ASYNC_Execute(threadDFR)
End

threadsafe Function/DF UploadJSONPayloadAsyncWorker(DFREF threadDFR)

	variable jsonID, err
	string msg, uploadID

	jsonID = ASYNC_FetchVariable(threadDFR, "jsonID")

	[err, msg, uploadID] = UploadJSONPayload(jsonID)

	DFREF      dfrOut          = NewFreeDataFolder()
	variable/G dfrOut:err      = err
	string/G   dfrOut:msg      = msg
	string/G   dfrOut:uploadID = uploadID

	return dfrOut
End

Function UploadJSONPayloadAsyncReadout(STRUCT ASYNC_ReadOutStruct &ar)

	PerformSubsystemEntry()

	if(ar.rtErr)
		BUG("Uploading the JSON payload finished with RTE: " + ar.rtErrMsg)
		return NaN
	endif

	if(ar.abortCode)
		BUG("Uploading the JSON payload finished with Abort: " + num2str(ar.abortCode))
		return NaN
	endif

	NVAR/SDFR=ar.dfr err
	SVAR/SDFR=ar.dfr msg, uploadID

	if(err)
		BUG("Uploading the JSON payload failed with error " + num2str(err) + ": " + msg, keys = {"uploadID"}, values = {uploadID})
	endif
End

/// @brief Upload the given JSON document and release it
///
/// See `tools/http-upload/upload-json-payload-v1.php` for the JSON format description.
///
/// @retval err Igor error code of URLRequest or the HTTP status code of a failed request, zero on success
/// @retval msg      response of the server or the error message
/// @retval uploadID unique ID of the upload, which is also part of its log entries
threadsafe Function [variable err, string msg, string uploadID] UploadJSONPayload(variable jsonID)

	variable skip, timeout, payloadSize
	string payload

#ifdef AUTOMATED_TESTING
	WAVE/Z overrideResults = GetOverrideResults()
	skip = WaveExists(overrideResults) ? overrideResults[0] : 0
#endif // AUTOMATED_TESTING

	// allows to match the log entries of uploads running in parallel threads
	uploadID = GenerateRFC4122UUID()

	payload = JSON_Dump(jsonID)
	JSON_Release(jsonID)

	payloadSize = strlen(payload)
	// time in s for uploading the payload with the minimum upload rate plus the connection overhead
	timeout = payloadSize * 8 / UPLOAD_MIN_RATE + UPLOAD_BASE_TIMEOUT

	LOG_AddEntry(PACKAGE_MIES, "start", keys = {"size", "timeout", "uploadID"}, values = {num2str(payloadSize), num2str(timeout), uploadID})

	if(!skip)
		URLRequest/Z=1/TIME=(timeout)/DSTR=payload url="https://ai.customers.byte-physics.de/upload-json-payload-v1.php", method=put

		err = V_flag
		if(err == URLREQUEST_TIMEOUT_ERROR)
			sprintf S_ServerResponse, "The upload of %d bytes timed out after %g s, which allows for an upload rate of at least %g MBit/s and %g s for connecting and waiting for the server.", payloadSize, timeout, UPLOAD_MIN_RATE * ONE_TO_MEGA, UPLOAD_BASE_TIMEOUT
		elseif(!err && V_responseCode != HTTP_STATUS_OK)
			// V_responseCode is only valid without error
			err = V_responseCode
			sprintf S_ServerResponse, "The server responded with the HTTP status code %d: %s", V_responseCode, S_ServerResponse
		endif
	else
		err              = 1
		S_ServerResponse = "fake error"
	endif

	// failures are reported by the caller
	if(!err)
		LOG_AddEntry(PACKAGE_MIES, "end", keys = {"uploadID"}, values = {uploadID})
	endif

	return [err, S_ServerResponse, uploadID]
End

/// @brief Returns a hex string which is unique for the given Igor Pro session
///
/// It allows to distinguish multiple Igor instances, but is not globally unique.
threadsafe Function/S GetIgorInstanceID()

	return Hash(IgorInfo(-102), 1)
End

/// @brief Allows to remove V_flag which will be present after using the operation queue with `/Z`
///
/// Example usage:
/// \rst
/// .. code-block:: igorpro
///
/// 	Execute/P/Q/Z "SomeFunction()"
/// 	CleanupOperationQueueResult()
/// \endrst
///
Function CleanupOperationQueueResult()

	Execute/P/Q "KillVariables/Z V_flag"
End

/// @brief Remove the volatile part of the XOP error code
///
/// The result is constant and can therefore be compared with constants.
threadsafe Function ConvertXOPErrorCode(variable err)

	// error codes -1 to 9999 are Igor Pro error codes
	// for first loaded XOP -> xop error codes returned are in the range 10000+ up to max. 10999
	// for second+ loaded XOP -> xop error codes returned are offsetted by n x 0x10000 per XOP instead of 10000

	// Therefore, returning the code through RTE and directly through V_flag (SetOperationReturnValue):
	err = (err < 0xFFFF) ? err : ((err & 0xFFFF) + 10000)

	// Note: Getting the error message through GetRTErrMessage,
	// GetErrMessage(code) requires the original RTE code (does not work with directly return through  V_flag).
	return err
End
