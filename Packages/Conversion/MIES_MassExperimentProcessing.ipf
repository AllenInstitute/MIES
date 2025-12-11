#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MEP
#endif // AUTOMATED_TESTING

/// @file MIES_MassExperimentProcessing.ipf
/// @brief __MEP__ Process multiple MIES pxps to convert data into NWBv2
///
/// Installation:
/// - Stop Igor Pro
/// - Install MIES from the installer
/// - Create a shortcut to this file and place it in the `Igor Procedures` folder
/// - Ensure that only MIES is installed and no other Igor Pro packages
/// - In the MIES installation folder (All Users: `C:\Program Files\MIES`, User: `C:\Users\$User\Documents\MIES`)
///   create an empty file named `UserConfig.txt`.
/// - Execute CreateEmptyFiles() to create required empty files in `User Procedures`
/// - If the files are on a Windows/SMB network share, create a drive letter
///   via `net use Z: \\$Server\$Share` as UNC paths don't work everywhere in IP.
///
/// Running:
/// - Start Igor Pro
/// - Select "Macros" -> "Mass convert PXPs to NWBv2"
/// - Enter an input and output folder for the conversion
/// - Wait until it's done
///
/// In the output folder there will be a `conversion.json` file with results of
/// the conversion process. Search for the `error` key for failed conversions.

// #define MEP_DEBUGGING

#ifdef MEP_DEBUGGING

static StrConstant INPUT_FOLDER  = "E:tim-data:pxp_examples_for_nwb_2:"
static StrConstant OUTPUT_FOLDER = "E:tim-data:output:"

#else

static StrConstant INPUT_FOLDER  = ""
static StrConstant OUTPUT_FOLDER = ""

#endif // MEP_DEBUGGING

Menu "Macros"
	"Mass convert PXPs to NWBv2", /Q, StartMultiExperimentProcess()
End

static StrConstant kPackageName         = "MIES PXP to NWBv2"
static StrConstant kPreferencesFileName = "ProcessPrefsMIESNWBv2.bin"
static Constant    kPrefsRecordID       = 0 // The recordID is a unique number identifying a record within the preference file.

static Structure MultiExperimentProcessPrefs
	uint32 version // Prefs version
	uint32 processRunning // Truth that we are running the mult-experiment process
	char settingsFile[256]
EndStructure

// In version 101 of the prefs structure we increased folderPath from 100 to 256 bytes
static Constant kPrefsVersionNumber = 102

//  Loads preferences into our structure.
static Function LoadPackagePrefs(STRUCT MultiExperimentProcessPrefs &prefs)

	variable currentPrefsVersion = kPrefsVersionNumber

	// This loads preferences from disk if they exist on disk.
	LoadPackagePreferences/MIS=1 kPackageName, kPreferencesFileName, kPrefsRecordID, prefs
	// Printf "%d byte loaded\r", V_bytesRead

	// If error or prefs not found or not valid, initialize them.
	if(V_flag != 0 || V_bytesRead == 0 || prefs.version != currentPrefsVersion)
		prefs.version = currentPrefsVersion

		prefs.processRunning = 0
		prefs.settingsFile   = ""

		SavePackagePrefs(prefs) // Create default prefs file.
	endif
End

//  Saves our structure to preferences.
static Function SavePackagePrefs(STRUCT MultiExperimentProcessPrefs &prefs)

	SavePackagePreferences kPackageName, kPreferencesFileName, kPrefsRecordID, prefs
End

static Function ProcessCurrentExperiment(STRUCT MultiExperimentProcessPrefs &prefs)

	variable jsonID, index, ref, error
	string outputFileTemplate, inputFile, outputFolder, history, path, message, file, regex

	jsonID = GetJSON(prefs)

	if(IsAppropriateExperiment())

		outputFolder = JSON_GetString(jsonID, "/outputFolder")

		PathInfo home
		inputFile = S_path + GetExperimentName() + ".pxp"

		outputFileTemplate = outputFolder + S_path + GetExperimentName()

		path = "/log/" + num2str(JSON_GetVariable(jsonID, "/index"))
		JSON_AddString(jsonID, path + "/from", inputFile)
		JSON_AddString(jsonID, path + "/to", outputFileTemplate)

		ref = CaptureHistoryStart()

		AssertOnAndClearRTError()
		try
			PerformMiesTasks(outputFileTemplate); AbortOnRTE
		catch
			message = GetRTErrMessage()
			error   = ClearRTError()

			if(error >= 0)
				printf "Encountered lingering RTE of %d (message: %s) after executing PerformMiesTasks.\r", error, message
			else
				printf "Encountered Abort with V_AbortCode: %d\r", V_AbortCode
			endif

			JSON_AddBoolean(jsonID, path + "/error", 1)
			JSON_SetVariable(jsonID, "/errors", JSON_GetVariable(jsonID, "/errors") + 1)
			HDF5CloseFile/A/Z 0

			regex = "\\Q" + outputFileTemplate + "\\E" + ".*\.nwb$"
			WAVE/Z/T files = GetAllFilesRecursivelyFromPath("home", regex = regex)

			if(WaveExists(files))
				for(file : files)
					DeleteFile/Z file
				endfor
			endif
		endtry

		history = CaptureHistory(ref, 1)

		JSON_AddString(jsonID, path + "/output", trimstring(history))

		JSON_SetVariable(jsonID, "/processed", JSON_GetVariable(jsonID, "/processed") + 1)
	else
		JSON_SetVariable(jsonID, "/skipped", JSON_GetVariable(jsonID, "/skipped") + 1)
	endif

	JSON_SetVariable(jsonID, "/index", JSON_GetVariable(jsonID, "/index") + 1)

	StoreJSON(prefs, jsonID)
End

static Function PerformMiesTasks(string outputFileTemplate)

	string folder

	printf "Free Memory: %g GB\r", GetFreeMemory()

	folder = GetFolder(outputFileTemplate)

	if(!FolderExists(folder))
		CreateFolderOnDisk(folder)
	endif

	NWB_ExportAllData(NWB_VERSION_LATEST, overrideFileTemplate = outputFileTemplate)
	HDF5CloseFile/A/Z 0
End

static Function IsAppropriateExperiment()

	return ItemsInList(GetAllDevicesWithContent()) > 0
End

// Returns full path to the next experiment file to be loaded or "" if we are finished.
static Function/S FindNextExperiment(STRUCT MultiExperimentProcessPrefs &prefs)

	variable jsonID, index

	jsonID = GetJSON(prefs)

	WAVE/T inputFiles = JSON_GetTextWave(jsonID, "inputFiles")
	index = JSON_GetVariable(jsonID, "/index")
	JSON_Release(jsonID)

	if(!(index >= DimSize(inputFiles, ROWS)))
		return inputFiles[index]
	endif

	return ""
End

// Caller needs to release json
static Function GetJSON(STRUCT MultiExperimentProcessPrefs &prefs)

	string data, fname

	[data, fname] = LoadTextFile(prefs.settingsFile)

	return JSON_Parse(data)
End

// json will be released
static Function StoreJSON(STRUCT MultiExperimentProcessPrefs &prefs, variable jsonID)

	string data = JSON_Dump(jsonID, indent = 2)

	SaveTextFile(data, prefs.settingsFile)

	ASSERT(!JSON_Release(jsonID), "Could not release json")
End

// Posts commands to Igor's operation queue to close the current experiment and open the next one.
// Igor executes operation queue commands when it is idling - that is, when it is not running a
// function or operation.
static Function PostLoadNextExperiment(string nextExperimentFullPath)

	ASSERT(FileExists(nextExperimentFullPath), "Experiment must exist")

	Execute/P/Q "NEWEXPERIMENT " // Post command to close this experiment.

	Execute/P/Q "SetIgorOption poundDefine=MIES_PXP_NWB_CONVERSION_SKIP_SAVING"

	// Post command to open next experiment.
	string cmd
	sprintf cmd, "Execute/P/Q \"LOADFILE %s\"", nextExperimentFullPath
	Execute/Q cmd
End

// This is the hook function that Igor calls whenever a file is opened. We use it to
// detect the opening of an experiment and to call our ProcessCurrentExperiment function.
static Function AfterFileOpenHook(variable refNum, string file, string pathName, string type, string creator, variable kind)

	STRUCT MultiExperimentProcessPrefs prefs

	LoadPackagePrefs(prefs) // Load our prefs into our structure
	if(prefs.processRunning == 0)
		return 0 // Process not yet started.
	endif

	// Check file type
	if(CmpStr(type, "IGsU") != 0)
		return 0 // This is not a packed experiment file
	endif

	ProcessCurrentExperiment(prefs)

	NextFile(prefs)

	return 0 // Tell Igor to handle file in default fashion.
End

Function CreateEmptyFiles()

	string file
	string path = SpecialDirPath("Igor Pro User Files", 0, 0, 0) + "User Procedures:"

	Make/T/FREE files = {"MIES_Include.ipf",                \
	                     "TJ_MIES_AnalysisBrowser.ipf",     \
	                     "TJ_MIES_Include.ipf",             \
	                     "UTF_HardwareHelperFunctions.ipf", \
	                     "UTF_HardwareMain.ipf",            \
	                     "UserAnalysisFunctions.ipf",       \
	                     "tango_Panel.ipf",                 \
	                     "tango_loader.ipf",                \
	                     "unit-testing.ipf",                \
	                     "UserConfig.txt"}

	for(file : files)
		SaveTextFile("", path + file)
	endfor
End

// This function enables our special Igor hooks which skip saving the experiment
Function StartMultiExperimentProcess()

	Execute/P/Q "SetIgorOption poundDefine=MIES_PXP_NWB_CONVERSION_SKIP_SAVING"
	Execute/P/Q "COMPILEPROCEDURES "
	Execute/P/Q "StartMultiExperimentProcessWrapper()"
End

// Allow user to choose the folder containing the experiment files and start the process.
Function StartMultiExperimentProcessWrapper()

	string message, settingsFile, inputFolder, outputFolder
	variable jsonID

	STRUCT MultiExperimentProcessPrefs prefs
	LoadPackagePrefs(prefs)

	message = "Choose input folder with MIES pxps"
	if(!cmpstr(INPUT_FOLDER, ""))
		NewPath/O/Q/M=message MultiExperimentInputFolder
	else
		NewPath/O/Q/M=message MultiExperimentInputFolder, INPUT_FOLDER
	endif

	if(V_flag != 0)
		return -1 // User canceled from New Path dialog
	endif

	PathInfo MultiExperimentInputFolder
	inputFolder = S_Path
	ASSERT(V_flag, "Invalid path")

	message = "Choose output folder for NWBv2 files"
	if(!cmpstr(OUTPUT_FOLDER, ""))
		NewPath/O/Q/M=message MultiExperimentOutputFolder
	else
		NewPath/O/Q/M=message MultiExperimentOutputFolder, OUTPUT_FOLDER
	endif

	if(V_flag != 0)
		return -1 // User canceled from New Path dialog
	endif

	PathInfo MultiExperimentOutputFolder
	outputFolder = S_Path
	ASSERT(V_flag, "Invalid path")

	WAVE/Z/T files = GetAllFilesRecursivelyFromPath("MultiExperimentInputFolder", regex = "(?i)\.pxp$")

	if(WaveExists(files))
		Sort/A=2 files, files
	else
		Make/FREE/T/N=0 files
	endif

	jsonID = JSON_New()
	JSON_AddWave(jsonID, "/inputFiles", files)
	JSON_AddString(jsonID, "/inputFolder", inputFolder)
	JSON_AddString(jsonID, "/outputFolder", outputFolder)
	JSON_AddVariable(jsonID, "/index", 0)
	JSON_AddVariable(jsonID, "/processed", 0)
	JSON_AddVariable(jsonID, "/errors", 0)
	JSON_AddVariable(jsonID, "/skipped", 0)
	JSON_AddVariable(jsonID, "/total", DimSize(files, ROWS))

	JSON_AddTreeArray(jsonID, "/log")
	JSON_AddObjects(jsonID, "/log", objCount = DimSize(files, ROWS))

	prefs.settingsFile = outputFolder + "conversion.json"
	StoreJSON(prefs, jsonID)

	prefs.processRunning = 1 // Flag process is started.

	// Start the process off by loading the first experiment.
	string nextExperimentFullPath = FindNextExperiment(prefs)
	PostLoadNextExperiment(nextExperimentFullPath) // Start the process off

	SavePackagePrefs(prefs)

	return 0
End

Function NextFile(STRUCT MultiExperimentProcessPrefs &prefs)

	// See if there are more experiments to process.
	string nextExperimentFullPath = FindNextExperiment(prefs)
	if(strlen(nextExperimentFullPath) == 0)
		// Process is finished
		prefs.processRunning = 0 // Flag process is finished.
		Execute/P "NEWEXPERIMENT " // Post command to close this experiment.
		print "Multi-experiment process is finished."
	else
		// Load the next experiment in the designated folder, if any.
		PostLoadNextExperiment(nextExperimentFullPath) // Post operation queue commands to load next experiment
	endif

	SavePackagePrefs(prefs)
End

#ifdef MEP_DEBUGGING

Function TestMe()

	STRUCT MultiExperimentProcessPrefs prefs

	LoadPackagePrefs(prefs)
	ProcessCurrentExperiment(prefs)
	NextFile(prefs)
End

#endif // MEP_DEBUGGING
