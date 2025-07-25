#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MIESUTILS_UPLOADS
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_Uploads.ipf
/// @brief This file holds MIES utility functions for data upload

static StrConstant EXPCONFIG_JSON_HWDEVBLOCK = "DAQHardwareDevices"
static StrConstant UPLOAD_BLOCK_USERPING     = "UserPing"

/// @brief Call UploadCrashDumps() if we haven't called it since at least a day.
Function UploadCrashDumpsDaily()

	variable lastWrite

#ifdef AUTOMATED_TESTING
	return NaN
#endif // AUTOMATED_TESTING

	AssertOnAndClearRTError()
	try
		NVAR JSONid = $GetSettingsJSONid()

		lastWrite = ParseISO8601TimeStamp(JSON_GetString(jsonID, "/diagnostics/last upload"))

		if((lastWrite + SECONDS_PER_DAY) > DateTimeInUTC())
			// nothing to do
			return NaN
		endif

		UploadCrashDumps()

		JSON_SetString(jsonID, "/diagnostics/last upload", GetIso8601TimeStamp())
		AbortOnRTE
	catch
		ClearRTError()
		BUG("Could not upload crash dumps!")
	endtry
End

/// @brief Call UploadLogFiles() if we haven't called it since at least a day.
Function UploadLogFilesDaily()

	string ts
	variable lastWrite, now, first, last

#ifdef AUTOMATED_TESTING
	return NaN
#endif // AUTOMATED_TESTING

	AssertOnAndClearRTError()
	try
		NVAR JSONid = $GetSettingsJSONid()

		ts        = JSON_GetString(jsonID, "/logfiles/last upload")
		lastWrite = ParseISO8601TimeStamp(ts)
		now       = DateTimeInUTC()

		if((lastWrite + SECONDS_PER_DAY) > now)
			// nothing to do
			return NaN
		endif

		// Algorithm:
		// Upload everything from yesterday and the last time we tried to
		// upload taking the earliest time of each day. Borders included.

		// earliest time of the day of the last upload
		if(IsEmpty(ts))
			first = 0
		else
			first = ParseISO8601TimeStamp(ts[0, 9] + "T00:00:00Z")
			ASSERT(IsFinite(first), "Could not parse ts")
		endif

		// earliest time today
		last = ParseISO8601TimeStamp(Secs2Date(now, -2) + "T00:00:00Z")
		ASSERT(IsFinite(last), "Could not parse now")

		UploadLogFiles(verbose = 0, firstDate = first, lastDate = last)

		JSON_SetString(jsonID, "/logfiles/last upload", GetIso8601TimeStamp())
		AbortOnRTE
	catch
		ClearRTError()
		FATAL_ERROR("Could not upload logfiles!")
	endtry
End

Function UploadPingPeriodically()

	variable lastPing, now, today, lastWeekDay

#ifdef AUTOMATED_TESTING
	return NaN
#endif // AUTOMATED_TESTING

	if(!GetUserPingEnabled())
		return NaN
	endif

	now      = DateTimeInUTC()
	lastPing = ParseISO8601TimeStamp(GetUserPingTimestamp())
	if((now - lastPing) < (SECONDS_PER_DAY * 7))
		today       = GetDayOfWeek(now)
		lastWeekDay = GetDayOfWeek(lastPing)
		if(today == lastWeekDay ||                          \
		   (today > lastWeekDay && lastWeekDay > SUNDAY) || \
		   (today < lastWeekDay && today < MONDAY))
			return NaN
		endif
	endif

	if(!UploadPing())
		SetUserPingTimestamp(now)
	endif
End

static Function UploadPing()

	variable jsonID, jsonID2, err
	string payLoad, jsonPath

	jsonId2  = JSON_GetIgorInfo()
	jsonPath = "/" + EXPCONFIG_JSON_HWDEVBLOCK
	JSON_AddTreeObject(jsonId2, jsonPath)
	WAVE/T NIDevices = ListToTextWave(DAP_GetNIDeviceList(), ";")
	JSON_AddWave(jsonId2, jsonPath + "/NI", NIDevices)
	WAVE/T ITCDevices = ListToTextWave(DAP_GetITCDeviceList(), ";")
	JSON_AddWave(jsonId2, jsonPath + "/ITC", ITCDevices)
	WAVE/T SUDevices = ListToTextWave(DAP_GetSUDeviceList(), ";")
	JSON_AddWave(jsonId2, jsonPath + "/SU", SUDevices)

	payLoad = JSON_Dump(jsonId2, indent = 2)
	JSON_Release(jsonId2)

	jsonID = GenerateJSONTemplateForUpload()
	AddPayloadEntries(jsonID, {UPLOAD_BLOCK_USERPING}, {payload}, isBinary = 0)
	UploadJSONPayloadAsync(jsonID)

	return err
End

/// @brief Return JSON text with default entries for upload
///
/// Caller is responsible for releasing JSON text.
Function GenerateJSONTemplateForUpload([string timeStamp])

	variable jsonID

	if(ParamIsDefault(timeStamp))
		timeStamp = GetISO8601TimeStamp()
	endif

	jsonID = JSON_New()

	JSON_AddString(jsonID, "/computer", GetEnvironmentVariable("COMPUTERNAME"))
	JSON_AddString(jsonID, "/user", IgorInfo(7))
	JSON_AddString(jsonID, "/timestamp", timeStamp)
	AddPayloadEntries(jsonID, {"version.txt"}, {ROStr(GetMiesVersion())}, isBinary = 1)

	return jsonID
End

/// @brief Convert the Igor Pro crash dumps and the report file to JSON and upload them
///
/// Does nothing if none of these files exists.
///
/// The uploaded files are moved out of the way afterwards.
///
/// See `tools/http-upload/upload-json-payload-v1.php` for the JSON format description.
Function UploadCrashDumps()

	string diagSymbPath, basePath, diagPath
	variable jsonID, numFiles, numLogs, referenceTime

	referenceTime = DEBUG_TIMER_START()

	diagSymbPath = GetSymbolicPathForDiagnosticsDirectory()

	WAVE/Z/T files = GetAllFilesRecursivelyFromPath(diagSymbPath, regex = "(?i)\.dmp$")
	WAVE/Z/T logs  = GetAllFilesRecursivelyFromPath(diagSymbPath, regex = "(?i)\.txt$")

	numFiles = WaveExists(files) ? DimSize(files, ROWS) : 0
	numLogs  = WaveExists(logs) ? DimSize(logs, ROWS) : 0

	if(!numFiles && !numLogs)
		return NaN
	endif

	jsonID = GenerateJSONTemplateForUpload()

	AddPayloadEntriesFromFiles(jsonID, files, isBinary = 1)
	AddPayloadEntriesFromFiles(jsonID, logs, isBinary = 1)

	PathInfo $diagSymbPath
	diagPath = S_path

	basePath = GetUniqueSymbolicPath()
	NewPath/Q/O/Z $basePath, diagPath + ":"

#ifdef DEBUGGING_ENABLED
	SaveTextFile(JSON_dump(jsonID, indent = 4), diagPath + ":" + UniqueFileOrFolder(basePath, "crash-dumps", suffix = ".json"))
#endif // DEBUGGING_ENABLED

	UploadJSONPayloadAsync(jsonID)

#ifndef DEBUGGING_ENABLED
	MoveFolder/P=$basePath "Diagnostics" as UniqueFileOrFolder(basePath, "Diagnostics_old")
#endif // !DEBUGGING_ENABLED

	DEBUGPRINT_ELAPSED(referenceTime)

	printf "Uploading %d crash dumps and log files is in progress in the background.\r", numFiles + numLogs
	ControlWindowToFront()
End

/// @brief Upload the MIES and ZeroMQ logfiles
///
/// @param verbose   [optional, defaults to true] Only in verbose mode the ticket ID is output to the history
/// @param firstDate [optional, defaults to false] Allows to filter the logfiles to include entries within the given dates.
///                  Both `firstDate` and `lastDate` must be present for filtering. The timestamps are in seconds since Igor Pro epoch.
/// @param lastDate  [optional, defaults to false] See `firstDate`
Function UploadLogFiles([variable verbose, variable firstDate, variable lastDate])

	string logPartStr, fNamePart, file, ticket, timeStamp
	string path, location, basePath, out
	variable jsonID, numFiles, i, j, doFilter, isBinary, lastIndex, jsonIndex, partCnt, sumSize, fSize

	isBinary = 1
	verbose  = ParamIsDefault(verbose) ? 1 : !!verbose

	if(ParamIsDefault(firstDate) && ParamIsDefault(lastDate))
		doFilter = 0
	elseif(!ParamIsDefault(firstDate) && !ParamIsDefault(lastDate))
		doFilter = 1
	else
		FATAL_ERROR("Invalid firstDate/lastDate combination")
	endif

	UploadLogFilesPrint("Just a moment, Uploading log files to improve MIES... (only once per day)\r", verbose)

	WAVE/T files = GetLogFileNames()
	timeStamp = GetISO8601TimeStamp()
	ticket    = GenerateRFC4122UUID()
	Make/FREE/N=(MINIMUM_WAVE_SIZE) jsonIDs

	numFiles = DimSize(files, ROWS)
	for(i = 0; i < numFiles; i += 1)
		file = files[i][%FILENAME]

		fSize = GetFileSize(file)
		WAVE/Z/T logData = $""
		if(!IsNaN(fSize))
			sprintf out, "Loading %s (%.1f MB)", files[i][%DESCRIPTION], fSize / MEGABYTE
			UploadLogFilesPrint(out, verbose)
			WAVE/Z/T logData = LoadTextFileToWave(file, LOG_FILE_LINE_END)
		endif
		if(!WaveExists(logData))
			jsonID = GenerateJSONTemplateForUpload(timeStamp = timeStamp)
			AddPayloadEntries(jsonID, {"ticket.txt"}, {ticket}, isBinary = isBinary)
			AddPayloadEntries(jsonID, {file}, {files[i][%NOTEXISTTEXT]}, isBinary = isBinary)
			EnsureLargeEnoughWave(jsonIDs, indexShouldExist = jsonIndex)
			jsonIDs[jsonIndex] = jsonID
			jsonIndex         += 1
			continue
		endif

		if(doFilter)
			UploadLogFilesPrint(" -> Filtering", verbose)
			[WAVE/T uploadData, lastIndex] = FilterByDate(logData, firstDate, lastDate)
			if(!WaveExists(uploadData))
				UploadLogFilesPrint(" -> No new entries to upload here.\r", verbose)
				continue
			endif
		else
			WAVE/T uploadData = logData
			lastIndex = DimSize(logData, ROWS) - 1
		endif

		UploadLogFilesPrint(" -> Splitting", verbose)
		WAVE/WAVE splitContents = SplitLogDataBySize(uploadData, LOG_FILE_LINE_END, LOGUPLOAD_PAYLOAD_SPLITSIZE)
		partCnt = 0
		for(logPart : splitContents)
			jsonID = GenerateJSONTemplateForUpload(timeStamp = timeStamp)
			AddPayloadEntries(jsonID, {"ticket.txt"}, {ticket}, isBinary = isBinary)
			if(doFilter)
				AddPayloadEntries(jsonID, {"firstDate.txt"}, {GetISO8601TimeStamp(secondsSinceIgorEpoch = firstDate)}, isBinary = isBinary)
				AddPayloadEntries(jsonID, {"lastDate.txt"}, {GetISO8601TimeStamp(secondsSinceIgorEpoch = lastDate)}, isBinary = isBinary)
			endif

			logPartStr = TextWaveToList(logPart, "\n")
			logPartStr = ReplaceString("{}" + LOG_FILE_LINE_END + "{}" + LOG_FILE_LINE_END, logPartStr, "")
			sprintf fNamePart, "%s_part%03d.%s", GetBaseName(file), partCnt, GetFileSuffix(file)

			AddPayloadEntries(jsonID, {fNamePart}, {logPartStr}, isBinary = isBinary)
			sumSize += strlen(logPartStr)
			EnsureLargeEnoughWave(jsonIDs, indexShouldExist = jsonIndex)
			jsonIDs[jsonIndex] = jsonID
			jsonIndex         += 1
			partCnt           += 1
			UploadLogFilesPrint(".", verbose)
		endfor
		UploadLogFilesPrint("\r", verbose)
	endfor
	Redimension/N=(jsonIndex) jsonIDs

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		basePath = GetUniqueSymbolicPath()
		path     = SpecialDirPath("Temporary", 0, 0, 1) + "MIES:"
		NewPath/C/Q/O/Z $basePath, path

		for(jsonID : jsonIDs)
			location = path + UniqueFileOrFolder(basePath, "logfiles", suffix = ".json")
			SaveTextFile(JSON_dump(jsonID, indent = 4), location)

			printf "Stored the logfile JSON in %s.\r", location
		endfor
	endif
#endif // DEBUGGING_ENABLED

	if(DimSize(jsonIDs, ROWS))
		sumsize = Base64EncodeSize(sumSize)
		sprintf out, "Uploading %.0f MB (~%d Bytes)", sumSize / MEGABYTE, sumSize
		UploadLogFilesPrint(out, verbose)
		for(jsonID : jsonIDs)
			UploadJSONPayloadAsync(jsonID)

			UploadLogFilesPrint(".", verbose)
		endfor
		UploadLogFilesPrint("\r", verbose)
	endif

	sprintf out, "Uploading the MIES, ZeroMQ-XOP and ITCXOP2 logfiles is in progress in the background. Please mention your ticket \"%s\" if you are contacting support.\r", ticket
	UploadLogFilesPrint(out, verbose)
End

static Function UploadLogFilesPrint(string str, variable verbose)

	if(verbose)
		printf "%s", str
	endif
End
