#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HistoricData

#include "UTF_HelperFunctions"

/// Adding new files:
/// - Assuming your new file is name `abcd.pxp`
/// - Copy `abcd.pxp` into the folder `Packages/tests/HistoricData/input`
/// - Adapt `files` in GetHistoricDataFiles()
/// - Verify that the test passes
/// - Compress the file by calling CompressFile("abcd.pxp"), takes a long time, so do something else in-between
/// - Upload `abcd.pxp.zst` to the FTP into the folder `MIES-HistoricData` (Account: `allentestdata`, ask Thomas if in doubt)
/// - Rename `abcd.pxp` to `abcd.pxp.tmp` in `Packages/tests/HistoricData/input`
/// - Verify that the test works, now with downloading and decompression of the file

// Data stored in this folder is subject to https://alleninstitute.org/terms-of-use
static StrConstant HTTP_FOLDER_URL = "https://www.byte-physics.de/Downloads/allensdk-test-data/MIES-HistoricData/"

// keep sorted
#include "UTF_HistoricDashboard"
#include "UTF_HistoricEpochClipping"

// Entry point for UTF
Function run()
	return RunWithOpts(instru = DoInstrumentation())
End

// Examples:
// - RunWithOpts()
// - RunWithOpts(testsuite = "UTF_Configuration.ipf")
// - RunWithOpts(testcase = "TestFindLevel")
Function RunWithOpts([string testcase, string testsuite, variable allowdebug, variable instru, string traceWinList, variable keepDataFolder, variable enableJU])

	variable debugMode
	string traceOptions
	string list = ""
	string name = GetTestName()

	// speeds up testing to start with a fresh copy
	KillWindow/Z HistoryCarbonCopy
	DisableDebugOutput()

	if(ParamIsDefault(allowdebug))
		debugMode = 0
	else
		debugMode = IUTF_DEBUG_FAILED_ASSERTION | IUTF_DEBUG_ENABLE | IUTF_DEBUG_ON_ERROR | IUTF_DEBUG_NVAR_SVAR_WAVE
	endif

	if(ParamIsDefault(testcase))
		testcase = ""
	endif

	if(ParamIsDefault(instru))
		instru = 0
	else
		instru = !!instru
	endif

	if(ParamIsDefault(traceWinList))
		traceWinList = "MIES_.*\.ipf"
	endif

	if(ParamIsDefault(keepDataFolder))
		keepDataFolder = 0
	else
		keepDataFolder = !!keepDataFolder
	endif

	if(ParamIsDefault(enableJU))
		enableJU = IsRunningInCI()
	else
		enableJU = !!enableJU
	endif

	if(!instru)
		traceWinList = ""
	endif

	traceOptions = GetDefaultTraceOptions()

	// sorted list
	list = AddListItem("UTF_HistoricDashboard.ipf", list, ";", inf)
	list = AddListItem("UTF_HistoricEpochClipping.ipf", list, ";", inf)

	if(ParamIsDefault(testsuite))
		testsuite = list
	else
		// do nothing
	endif

	if(IsEmpty(testcase))
		RunTest(testsuite, name = name, enableJU = enableJU, debugMode= debugMode, traceOptions=traceOptions, traceWinList=traceWinList, keepDataFolder = keepDataFolder)
	else
		RunTest(testsuite, name = name, enableJU = enableJU, debugMode= debugMode, testcase = testcase, traceOptions=traceOptions, traceWinList=traceWinList, keepDataFolder = keepDataFolder)
	endif
End

Function TEST_BEGIN_OVERRIDE(string name)
	TestBeginCommon()
End

Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	AdditionalExperimentCleanup()
End

Function TEST_CASE_END_OVERRIDE(string testcase)
	CheckForBugMessages()
End

Function DownloadFile(string file)

	string fullFilePath, url, folder

	folder = GetInputPath()
	fullFilePath = folder + file + ZSTD_SUFFIX
	url = HTTP_FOLDER_URL + URLEncode(file + ZSTD_SUFFIX)

	INFO("Download file %s", s0 = file)

	URLRequest/O/FILE=fullFilePath/Z=1/V=1 url=url
	CHECK(!V_Flag)

	DecompressFile(file)
End

Function/S GetInputPath()

	PathInfo home
	CHECK(V_Flag)

	return S_path + "input:"
End

/// @brief Compress `abcd.ext` to `abcd.ext.zst` both located in `Packages/tests/HistoricData/input`
///
/// @param file name of the uncompressed file
Function CompressFile(string file)

	string folder, cmd

	folder = GetInputPath()

	ASSERT(FileExists(folder + file), "Missing file for compression: " + folder + file)

	sprintf cmd, "cmd.exe /C %s..\\..\..\\..\\tools\\zstd.exe -f --check --ultra -22 -k %s -o %s", GetWindowsPath(folder), GetWindowsPath(folder + file), GetWindowsPath(folder + file + ZSTD_SUFFIX)
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_flag, "Compression error: " + S_Value)
End

/// @brief Decompress `abcd.ext.zst` to `abcd.ext` both located in `Packages/tests/HistoricData/input`
///
/// @param file name of the **uncompressed** file
Function DecompressFile(string file)

	string cmd, folder, compPath

	folder = GetInputPath()

	compPath = folder + file + ZSTD_SUFFIX
	ASSERT(FileExists(compPath), "Missing file for decompression: " + compPath)

	sprintf cmd, "cmd.exe /C %s..\\..\..\\..\\tools\\zstd.exe -f --check --decompress %s -o %s", GetWindowsPath(folder), GetWindowsPath(compPath), GetWindowsPath(folder + file)
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_flag, "Decompression error: " + S_Value)
End

Function/WAVE GetHistoricDataFiles()

	string path, fullFilePath, compFile, file
	variable i, numFiles, size, refSize

	Make/FREE/T files = {"C57BL6J-629713.05.01.02.pxp",                       \
	                     "Chat-IRES-Cre-neo;Ai14-582723.15.10.01.pxp",        \
	                     "Pvalb-IRES-Cre;Ai14-646904.13.03.02.pxp",           \
	                     "Sst-IRES-Cre;Ai14-554002.08.06.02.pxp",             \
								"Sst-IRES-Cre;Th-P2A-FlpO;Ai65-561491.09.09.02.pxp", \
								"epoch_clipping_2022_03_08_140256.pxp"}

	/// @TODO use hashes to verify files once IP supports strings > 2GB

	path = GetInputPath()

	numFiles = DimSize(files, ROWS)
	for(i = 0; i < numFiles; i += 1)
		file = files[i]
		fullFilePath = path + file

		if(FileExists(fullFilePath))
			continue
		endif

		DownloadFile(file)
	endfor

	Duplicate/FREE/T files, labels
	labels[] = CleanUpName(labels[p], 0)

	SetDimensionLabels(files, TextWaveToList(labels, ";"), ROWS)

	return files
End
