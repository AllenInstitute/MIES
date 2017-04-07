#pragma rtGlobals=3
#pragma version=1.06
#pragma TextEncoding="UTF-8"

// Licensed under 3-Clause BSD, see License.txt

/// Creates a notebook with the special name "HistoryCarbonCopy"
/// which will hold a copy of the history
Function CreateHistoryLog([recreate])
	variable recreate

	if(ParamIsDefault(recreate))
		recreate = 1
	endif
	DoWindow HistoryCarbonCopy
	if (V_flag)
		if (recreate)
			DoWindow/K HistoryCarbonCopy
			NewNotebook/V=0/F=0 /N=HistoryCarbonCopy
		endif
	else
		NewNotebook/V=0/F=0 /N=HistoryCarbonCopy
	endif
End

/// Hook function which is executed after opening a file
///
/// This function calls the user supplied run routine if
/// - the opened file is an igor experiment
/// - the file DO_AUTORUN.TXT exists in the igor home path
static Function AfterFileOpenHook(refNum, file, pathName, type, creator, kind)
	variable refNum, kind
	string file, pathName, type, creator

	// do nothing if the opened file was not an Igor packed/unpacked experiment
	if(kind != 1 && kind != 2)
		return 0
	endif

	// return if the state file does not exist
	GetFileFolderInfo/Q/Z/P=home "DO_AUTORUN.TXT"
	if(V_flag != 0)
		return 0
	endif

	string funcList = FunctionList("run", ";", "KIND:2,NPARAMS:0")
	if(ItemsInList(funcList) != 1)
		Abort "The requested autorun mode is not possible because the function run() does not exist in ProcGlobal context"
	endif

	FuncRef AUTORUN_MODE_PROTO f = $StringFromList(0, funcList)

	// state file exists, call the run routine and quit Igor afterwards
	CreateHistoryLog(recreate=0)
	f()

	Execute/P "SaveHistoryLog(); Quit/N"
End

/// resets a global filename template string for output
Function ClearBaseFilename()
	dfref dfr = GetPackageFolder()
	string/G dfr:baseFilename = ""
End

/// creates a new filename template, if template already present return current
Function/S GetBaseFilename()
	dfref dfr = GetPackageFolder()
	SVAR/Z/SDFR=dfr baseFilename

	if(!SVAR_Exists(baseFilename))
		string/G dfr:baseFilename = ""
		SVAR/SDFR=dfr baseFilename
	endif

	if(strlen(baseFilename))
		return baseFilename
	endif
	sprintf baseFilename, "%s_%s_%s", IgorInfo(1), Secs2Date(DateTime, -2), ReplaceString(":", Secs2Time(DateTime, 1), "-")
	return baseFilename
End

/// Save the contents of the history notebook on disk
/// in the same folder as this experiment as timestamped file "run_*_*.log"
Function SaveHistoryLog()

	string historyLog
	historyLog = GetBaseFilename() + ".log"

	DoWindow HistoryCarbonCopy
	if(V_flag == 0)
		print "No log notebook found, please call CreateHistoryLog() before."
		return NaN
	endif

	PathInfo home
	historyLog = getUnusedFileName(S_path + historyLog)
	if(!strlen(historyLog))
		printf "Error: Unable to determine unused file name for History Log output in path %s !", S_path
		return NaN
	endif

	SaveNoteBook/S=3/P=home HistoryCarbonCopy as historyLog
End
