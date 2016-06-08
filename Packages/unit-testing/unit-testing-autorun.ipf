#pragma rtGlobals=3
#pragma version=1.03

// Author: Thomas Braun (c) 2015
// Email: thomas dot braun at byte-physics dott de

/// Creates a notebook with the special name "HistoryCarbonCopy"
/// which will hold a copy of the history
Function CreateHistoryLog()
	DoWindow/K HistoryCarbonCopy
	NewNotebook/V=0/F=0 /N=HistoryCarbonCopy
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
	CreateHistoryLog()
	f()

	Execute/P "SaveHistoryLog(); Quit/N"
End

/// Save the contents of the history notebook on disk
/// in the same folder as this experiment as timestamped file "run_*_*.log"
Function SaveHistoryLog()

	string historyLog
	sprintf historyLog, "%s_%s_%s.log", IgorInfo(1), Secs2Date(DateTime, -2), ReplaceString(":", Secs2Time(DateTime, 1), "-")

	DoWindow HistoryCarbonCopy
	if(V_flag == 0)
		print "No log notebook found, please call CreateHistoryLog() before."
		return NaN
	endif

	SaveNoteBook/S=3/P=home HistoryCarbonCopy as historyLog
End
