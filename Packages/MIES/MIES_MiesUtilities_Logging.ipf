#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_LOGGING
#endif

/// @file MIES_MiesUtilities_Logging.ipf
/// @brief This file holds MIES utility functions for logging

static Constant    ARCHIVE_SIZETHRESHOLD = 52428800
static StrConstant ARCHIVEDLOG_SUFFIX    = "_old_"

/// @brief Return the disc location of the (possibly non-existing) ZeroMQ-XOP logfile
Function/S GetZeroMQXOPLogfile()

	// one down and up to "ZeroMQ"
	return PS_GetSettingsFolder(PACKAGE_MIES) + ":ZeroMQ:Log.jsonl"
End

/// @brief Return the disc location of the (possibly non-existing) ITCXOP2 logfile
Function/S GetITCXOP2Logfile()

	// one down and up to "ITCXOP2"
	return PS_GetSettingsFolder(PACKAGE_MIES) + ":ITCXOP2:Log.jsonl"
End

Function [WAVE/T filtered, variable lastIndex] FilterByDate(WAVE/T entries, variable first, variable last)

	variable firstIndex

	ASSERT(!IsNaN(first) && !IsNaN(last), "first and last can not be NaN.")
	ASSERT(first >= 0 && last >= 0 && first < last, "first and last must not be negative and first < last.")

	firstIndex = FindFirstLogEntryElementByDate(entries, first)
	lastIndex  = FindLastLogEntryElementByDate(entries, last)
	if(lastIndex < firstIndex)
		return [$"", NaN]
	endif

	Duplicate/FREE/T/RMD=[firstIndex, lastIndex] entries, filtered

	return [filtered, lastIndex]
End

/// @brief Find the index of the first log file line that is from a time greater or equal than timeStamp
///        The algorithm is a binary search that requires ascending order of time stamps of the log file entries.
///        entries is a text wave where each line contains a log file entry as JSON.
///        This JSON can contain a timestamp but can also contain no or an invalid timestamp.
///        If the binary search hits an invalid timestamp the current search index is moved by a linear search
///        to lower indices until a valid timestamp or the lower boundary is reached.
///
/// @param entries   text wave where each line contains a log file entry as serialized JSON with ascending order of time stamps
/// @param timeStamp time stamp that is searched
/// @returns index + 1 of the last entry with a time stamp lower than timeStamp
static Function FindFirstLogEntryElementByDate(WAVE/T entries, variable timeStamp)

	variable l, r, m, ts

	r = DimSize(entries, ROWS)
	for(; l < r;)
		m  = trunc((l + r) / 2)
		ts = ParseISO8601TimeStamp(GetDateOfLogEntry(entries[m]))
		if(IsNaN(ts))
			for(m = m - 1; m > l; m -= 1)
				ts = ParseISO8601TimeStamp(GetDateOfLogEntry(entries[m]))
				if(!IsNaN(ts))
					break
				endif
			endfor
		endif
		if(ts < timeStamp)
			l = m + 1
		else
			r = m
		endif
	endfor

	return l
End

/// @brief Find the index of the last log file line that is from a time smaller or equal than timeStamp
///        The algorithm is a binary search that requires ascending order of time stamps of the log file entries.
///        entries is a text wave where each line contains a log file entry as JSON.
///        This JSON can contain a timestamp but can also contain no or an invalid timestamp.
///        If the binary search hits an invalid timestamp the current search index is moved by a linear search
///        to higher indices until a valid timestamp or the higher boundary is reached.
///
/// @param entries   text wave where each line contains a log file entry as serialized JSON with ascending order of time stamps
/// @param timeStamp time stamp that is searched
/// @returns index - 1 of the first entry with a time stamp greater than timeStamp
static Function FindLastLogEntryElementByDate(WAVE/T entries, variable timeStamp)

	variable l, r, m, ts

	r = DimSize(entries, ROWS)
	for(; l < r;)
		m  = trunc((l + r) / 2)
		ts = ParseISO8601TimeStamp(GetDateOfLogEntry(entries[m]))
		if(IsNaN(ts))
			for(m = m + 1; m < r; m += 1)
				ts = ParseISO8601TimeStamp(GetDateOfLogEntry(entries[m]))
				if(!IsNaN(ts))
					break
				endif
			endfor
		endif
		if(ts > timeStamp)
			r = m
		else
			l = m + 1
		endif
	endfor

	return r - 1
End

Function ArchiveLogFilesOnceAndKeepMonth()

	string file
	variable lastIndex, firstDate, lastDate, fSize

	if(AlreadyCalledOnce(CO_ARCHIVE_ONCE))
		return NaN
	endif

	WAVE/T files = GetLogFileNames()
	Redimension/N=(-1) files

	firstDate = 0
	// subtract 1/12 of a year as approximation for one month
	lastDate = DateTimeInUTC() - 365 * 24 * 60 * 60 / 12

	for(file : files)

		if(!FileExists(file))
			continue
		endif
		fSize = GetFileSize(file)
		if(fSize < ARCHIVE_SIZETHRESHOLD)
			continue
		endif
		if(fSize > 512 * 1024 * 1024)
			printf "Just a moment, archiving log file %s.\rThis is only done once.\r", file
		endif

		WAVE/Z/T logData = LoadTextFileToWave(file, LOG_FILE_LINE_END)
		if(WaveExists(logData))
			[WAVE/T partData, lastIndex] = FilterByDate(logData, firstDate, lastDate)
			ArchiveLogFile(logData, file, lastIndex)
		endif
	endfor
End

static Function/S GetDateOfLogEntry(string entry)

	variable jsonId
	string   dat

	jsonID = JSON_Parse(entry, ignoreErr = 1)
	if(!JSON_IsValid(jsonID))
		// include invalid entries
		return ""
	endif

	dat = JSON_GetString(jsonID, "ts", ignoreErr = 1)
	JSON_Release(jsonID)

	return dat
End

static Function ArchiveLogFile(WAVE/T logData, string fullFilePath, variable index)

	string fileFolder, fileBase, fileSuffix, filePrefix, newFullFilePath, lastFileExists, numPart
	string format, strData
	variable partIdx, numParts, fNum, sizeLeft, fileIndex

	if(!index)
		return NaN
	endif

	fileFolder = GetFolder(fullFilePath)
	fileBase   = GetBaseName(fullFilePath)
	fileSuffix = GetFileSuffix(fullFilePath)
	filePrefix = fileFolder + fileBase + ARCHIVEDLOG_SUFFIX

	lastFileExists = LastArchivedLogFile(fullFilePath)
	if(!IsEmpty(lastFileExists))
		sizeLeft = LOG_ARCHIVING_SPLITSIZE - GetFileSize(lastFileExists)
		if(sizeLeft > LOG_MAX_LINESIZE)
			WAVE/WAVE logParts = SplitLogDataBySize(logData, LOG_FILE_LINE_END, LOG_ARCHIVING_SPLITSIZE, lastIndex = index, firstPartSize = sizeLeft)
			Open/Z/A fnum as lastFileExists
			ASSERT(!V_flag, "Could not open file for writing! " + lastFileExists)

			WAVE/T logPart = logParts[0]
			format = "%s" + LOG_FILE_LINE_END
			wfprintf fNum, format, logPart
			Close fnum
			partIdx += 1
		endif

		numPart   = ReplaceString(filePrefix, lastFileExists, "")
		fileIndex = str2num(RemoveEnding(numPart, fileSuffix)) + 1
	else
		WAVE/WAVE logParts = SplitLogDataBySize(logData, LOG_FILE_LINE_END, LOG_ARCHIVING_SPLITSIZE, lastIndex = index)
	endif

	format   = "%s%s" + ARCHIVEDLOG_SUFFIX + "%04d.%s"
	numParts = DimSize(logParts, ROWS)
	for(partIdx = partIdx; partIdx < numParts; partIdx += 1)
		sprintf newFullFilePath, format, fileFolder, fileBase, fileIndex, fileSuffix
		strData = TextWaveToList(logParts[partIdx], LOG_FILE_LINE_END)
		SaveTextFile(strData, newFullFilePath)
		fileIndex += 1
	endfor

	SaveRemainingLog(logData, index, fullFilePath)
End

static Function SaveRemainingLog(WAVE/T logData, variable index, string fullFilePath)

	string format
	variable flags, isZMQLogFile, fNum

	isZMQLogFile = !CmpStr(GetZeroMQXOPLogfile(), fullFilePath)
	if(isZMQLogFile)
		flags = ZeroMQ_SET_FLAGS_DEFAULT
		zeromq_set(flags)
	endif

	if(index == DimSize(logData, ROWS) - 1)
		DeleteFile fullFilePath
		return NaN
	endif

	format = "%s" + LOG_FILE_LINE_END
	Open fnum as fullFilePath
	wfprintf fNum, format/R=[index + 1, Inf], logData
	Close fNum

	if(isZMQLogFile)
		flags = GetZeroMQXOPFlags()
		zeromq_set(flags)
	endif
End

static Function/S LastArchivedLogFile(string fullFilePath)

	string pathName, fileFolder, fileBase, fileSuffix, allFilesList, allArchivedFiles, regex
	variable err

	fileFolder = GetFolder(fullFilePath)
	fileBase   = GetBaseName(fullFilePath)
	fileSuffix = GetFileSuffix(fullFilePath)

	pathName = GetUniqueSymbolicPath()
	NewPath/Q/O $pathName, fileFolder

	AssertOnAndClearRTError()
	allFilesList = IndexedFile($pathName, -1, "." + fileSuffix, "????", FILE_LIST_SEP); err = GetRTError(1)
	KillPath/Z $pathName

	regex            = "^" + fileBase + ARCHIVEDLOG_SUFFIX + "[0-9]{4}." + fileSuffix
	allArchivedFiles = GrepList(allFilesList, regex, 0, FILE_LIST_SEP)
	if(IsEmpty(allArchivedFiles))
		return ""
	endif

	return fileFolder + StringFromList(0, SortList(allArchivedFiles, FILE_LIST_SEP, 1), FILE_LIST_SEP)
End
