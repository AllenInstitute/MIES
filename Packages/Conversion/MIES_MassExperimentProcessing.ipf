#pragma rtGlobals=3 // Use modern global access method.

/// @file MIES_MassExperimentProcessing.ipf
/// @brief __MEP__ Process multiple MIES pxps to convert data into NWBv2
///
/// Installation:
/// - Stop Igor Pro
/// - Create a shortcut to this file and place it in the `Igor Procedures` folder
/// - Ensure that only MIES is installed and no other Igor Pro packages
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

static StrConstant INPUT_FOLDER  = "C:tim-data:pxp_examples_for_nwb_2:"
static StrConstant OUTPUT_FOLDER = "C:tim-data:output:"

#else

static StrConstant INPUT_FOLDER  = ""
static StrConstant OUTPUT_FOLDER = ""

#endif

Menu "Macros"
	"Mass convert PXPs to NWBv2", /Q, StartMultiExperimentProcess()
End

// NOTE: If you use these procedures for your own purposes, change the package name
// to a distinctive name so that you don't clash with other people's preferences.
static StrConstant kPackageName = "MIES PXP to NWBv2"
static StrConstant kPreferencesFileName = "ProcessPrefsMIESNWBv2.bin"
static Constant kPrefsRecordID = 0    // The recordID is a unique number identifying a record within the preference file.
// In this example we store only one record in the preference file.

// The structure stored in preferences to keep track of what experiment to load next.
// If you add, remove or change fields you must delete your old prefs file. See the help
// topic "Saving Package Preferences" for details.
static Structure MultiExperimentProcessPrefs
	uint32 version          // Prefs version
	uint32 processRunning   // Truth that we are running the mult-experiment process
	char settingsFile[256]
EndStructure

// In version 101 of the prefs structure we increased folderPath from 100 to 256 bytes
static Constant kPrefsVersionNumber = 102

//  Loads preferences into our structure.
static Function LoadPackagePrefs(prefs)
	STRUCT MultiExperimentProcessPrefs &prefs

	Variable currentPrefsVersion = kPrefsVersionNumber

	// This loads preferences from disk if they exist on disk.
	LoadPackagePreferences /MIS=1 kPackageName, kPreferencesFileName, kPrefsRecordID, prefs
	// Printf "%d byte loaded\r", V_bytesRead

	// If error or prefs not found or not valid, initialize them.
	if (V_flag!=0 || V_bytesRead==0 || prefs.version!=currentPrefsVersion)
		prefs.version = currentPrefsVersion

		prefs.processRunning = 0
		prefs.settingsFile   = ""

		SavePackagePrefs(prefs)    // Create default prefs file.
	endif
End

//  Saves our structure to preferences.
static Function SavePackagePrefs(prefs)
	STRUCT MultiExperimentProcessPrefs &prefs

	SavePackagePreferences kPackageName, kPreferencesFileName, kPrefsRecordID, prefs
End

//  This is the routine that you would need to change to use this procedure file for your own purposes.
//  See comments about labeled "TO USE FOR YOUR OWN PURPOSES".
static Function ProcessCurrentExperiment(prefs)
	STRUCT MultiExperimentProcessPrefs &prefs

	variable jsonID, index
	string outputFilePath, inputFile, outputFolder

	jsonID = GetJSON(prefs)

	if(IsAppropriateExperiment())

		outputFolder = JSON_GetString(jsonID, "/outputFolder")

		PathInfo home
		inputFile = S_path + GetExperimentName() + ".pxp"

		outputFilePath = outputFolder + S_path + GetExperimentName() + ".nwb"

		index = JSON_GetVariable(jsonID, "/index")
		JSON_AddString(jsonID, "/log/" + num2str(index) + "/from", inputFile)
		JSON_AddString(jsonID, "/log/" + num2str(index) + "/to", outputFilePath)

		DoWindow/K HistoryCarbonCopy
		NewNotebook/V=0/F=0 /N=HistoryCarbonCopy

		try
			PerformMiesTasks(outputFilePath); AbortOnRTE
		catch
			print "Caught an RTE"
			JSON_AddBoolean(jsonID, "/log/" + num2str(index) + "/error", 1)
			JSON_SetVariable(jsonID, "/errors", JSON_GetVariable(jsonID, "/errors") + 1)
		endtry

		Notebook HistoryCarbonCopy getData=1
		JSON_AddString(jsonID, "/log/" + num2str(index) + "/output", trimstring(S_Value))

		JSON_SetVariable(jsonID, "/processed", JSON_GetVariable(jsonID, "/processed") + 1)
	else
		JSON_SetVariable(jsonID, "/skipped", JSON_GetVariable(jsonID, "/skipped") + 1)
	endif

	JSON_SetVariable(jsonID, "/index", JSON_GetVariable(jsonID, "/index") + 1)

	StoreJSON(prefs, jsonID)
End

static Function PerformMiesTasks(outputFilePath)
	string outputFilePath

	string folder, message
	variable nwbVersion, error

	printf "Free Memory: %g GB\r", GetFreeMemory()

	if(FileExists(outputFilePath))
		print "Output file already exists, skipping!"
		return 0
	endif

	folder = GetFolder(outputFilePath)

	if(!FolderExists(folder))
		CreateFolderOnDisk(folder)
	endif

	ClearRTError()

	nwbVersion = 2
	NWB_ExportAllData(nwbVersion, overrideFilePath=outputFilePath)
	HDF5CloseFile/A/Z 0

	message = GetRTErrMessage()
	error = GetRTError(1)
	ASSERT(error == 0, "Encountered lingering RTE of " + num2str(error) + "(message: " + message + ") after executing NWB_ExportAllData.")
End

static Function IsAppropriateExperiment()

	return ItemsInList(GetAllDevicesWithContent()) > 0
End

// Returns full path to the next experiment file to be loaded or "" if we are finished.
static Function/S FindNextExperiment(prefs)
	STRUCT MultiExperimentProcessPrefs &prefs

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
static Function GetJSON(prefs)
	STRUCT MultiExperimentProcessPrefs &prefs

	string data, fname

	[data, fname] = LoadTextFile(prefs.settingsFile)

	return JSON_Parse(data)
End

// json will be released
static Function StoreJSON(prefs, jsonID)
	STRUCT MultiExperimentProcessPrefs &prefs
	variable jsonID

	string data = JSON_Dump(jsonID, indent=2)

	SaveTextFile(data, prefs.settingsFile)

	ASSERT(!JSON_Release(jsonID), "Could not release json")
End

// Posts commands to Igor's operation queue to close the current experiment and open the next one.
// Igor executes operation queue commands when it is idling - that is, when it is not running a
// function or operation.
static Function PostLoadNextExperiment(nextExperimentFullPath)
	String nextExperimentFullPath

	ASSERT(FileExists(nextExperimentFullPath), "Experiment must exist")

	Execute/P/Q "NEWEXPERIMENT "        // Post command to close this experiment.

	Execute/P/Q "SetIgorOption poundDefine=MIES_PXP_NWB_CONVERSION_SKIP_SAVING"

	// Post command to open next experiment.
	String cmd
	sprintf cmd "Execute/P/Q \"LOADFILE %s\"", nextExperimentFullPath
	Execute/Q cmd
End

// This is the hook function that Igor calls whenever a file is opened. We use it to
// detect the opening of an experiment and to call our ProcessCurrentExperiment function.
static Function AfterFileOpenHook(refNum,file,pathName,type,creator,kind)
	Variable refNum,kind
	String file,pathName,type,creator

	STRUCT MultiExperimentProcessPrefs prefs

	LoadPackagePrefs(prefs)            // Load our prefs into our structure
	if (prefs.processRunning == 0)
		return 0                  // Process not yet started.
	endif

	// Check file type
	if (CmpStr(type,"IGsU") != 0)
		return 0    // This is not a packed experiment file
	endif

	ProcessCurrentExperiment(prefs)

	// See if there are more experiments to process.
	String nextExperimentFullPath = FindNextExperiment(prefs)
	if (strlen(nextExperimentFullPath) == 0)
		// Process is finished
		prefs.processRunning = 0    // Flag process is finished.
		Execute/P "NEWEXPERIMENT "              // Post command to close this experiment.
		print "Multi-experiment process is finished."
	else
		// Load the next experiment in the designated folder, if any.
		PostLoadNextExperiment(nextExperimentFullPath)    // Post operation queue commands to load next experiment
	endif

	SavePackagePrefs(prefs)

	return 0  // Tell Igor to handle file in default fashion.
End

// This function enables our special Igor hooks which skip saving the experiment
Function StartMultiExperimentProcess()

	Execute/P/Q "SetIgorOption poundDefine=MIES_PXP_NWB_CONVERSION_SKIP_SAVING"
	Execute/P/Q "COMPILEPROCEDURES "
	Execute/P/Q "StartMultiExperimentProcessWrapper()"
End

// Allow user to choose the folder containing the experiment files and start the process.
Function StartMultiExperimentProcessWrapper()

	string message, settingsFile, inputFolder, outputFolder, files
	variable jsonID

	STRUCT MultiExperimentProcessPrefs prefs
	LoadPackagePrefs(prefs)

	message = "Choose input folder with MIES pxps"
	if(!cmpstr(INPUT_FOLDER, ""))
		NewPath/O/Q/M=message MultiExperimentInputFolder
	else
		NewPath/O/Q/M=message MultiExperimentInputFolder, INPUT_FOLDER
	endif

	if (V_flag != 0)
		return -1                      // User canceled from New Path dialog
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

	if (V_flag != 0)
		return -1                      // User canceled from New Path dialog
	endif

	PathInfo MultiExperimentOutputFolder
	outputFolder = S_Path
	ASSERT(V_flag, "Invalid path")

	files = GetAllFilesRecursivelyFromPath("MultiExperimentInputFolder", extension=".pxp")

	// 16: Case-insensitive alphanumeric sort that sorts wave0 and wave9 before wave10.
	// ...
	// 64: Ignore + and - in the alphanumeric sort so that "Text-09" sorts before "Text-10". Set options to 80 or 81.
	files = SortList(files, "|", 80)

	WAVE/T/Z inputPXPs = ListToTextWave(files, "|")

	jsonID = JSON_New()
	JSON_AddWave(jsonID, "/inputFiles", inputPXPs)
	JSON_AddString(jsonID, "/inputFolder", inputFolder)
	JSON_AddString(jsonID, "/outputFolder", outputFolder)
	JSON_AddVariable(jsonID, "/index", 0)
	JSON_AddVariable(jsonID, "/processed", 0)
	JSON_AddVariable(jsonID, "/errors", 0)
	JSON_AddVariable(jsonID, "/skipped", 0)
	JSON_AddVariable(jsonID, "/total", DimSize(inputPXPs, ROWS))

	JSON_AddTreeArray(jsonID, "/log")
	JSON_AddObjects(jsonID, "/log", objCount = DimSize(inputPXPs, ROWS))

	prefs.settingsFile = outputFolder + "conversion.json"
	StoreJSON(prefs, jsonID)

	prefs.processRunning = 1                // Flag process is started.

	// Start the process off by loading the first experiment.
	String nextExperimentFullPath = FindNextExperiment(prefs)
	PostLoadNextExperiment(nextExperimentFullPath)    // Start the process off

	SavePackagePrefs(prefs)

	return 0
End

#ifdef MEP_DEBUGGING

Function TestMe()

	STRUCT MultiExperimentProcessPrefs prefs

	LoadPackagePrefs(prefs)
	ProcessCurrentExperiment(prefs)
End

#endif
