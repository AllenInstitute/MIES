#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file UTF_TestingWithHardware.ipf Implement MIES testing with real world hardware
///
/// Due to the fact that DAQ/TP uses background functions makes the test suite
/// execution rather complicated.
///
/// Testing here is a three step process:
/// - Start testsuite with the testcase which acquires data
/// - Start background function to wait until DAQ is done
/// - If DAQ is done, start testsuite with testcase for checking the result
///
/// Usage:
/// Call SetupTestCases_IGNORE() with a list of testcases. The testcase which
/// acquire data and testcases which test the results should be interleaved.

StrConstant DEVICE = "ITC18USB_dev_0"

Function TEST_BEGIN_OVERRIDE(name)
	string name

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0
End

Function SetupTestCases_IGNORE(testCaseList)
	string testCaseList

	WAVE/T testCases = ListToTextWave(testCaseList, ";")
	Duplicate/O testCases, root:testCases

	variable/G root:testCaseIndex = 0
End

Function ExecuteNextTestCase_IGNORE()

	NVAR/SDFR=root: testCaseIndex
	WAVE/T/SDFR=root: testCases

	if(testCaseIndex >= DimSize(testCases, ROWS))
		if(GetAutorunMode() == AUTORUN_PLAIN)
			Execute/P "Quit/N"
		endif

		return NaN
	endif

	Execute/P/Q "runtest(\"UTF_BasicHardwareTests.ipf;UTF_PatchSeqSubThreshold.ipf;UTF_PatchSeqSquarePulse.ipf\", testCase=\"" + testCases[testCaseIndex] + "\", enableJU = 1)"

	testCaseIndex += 1
End

/// @brief Kill all panels and remove the MIES folder
Function Initialize_IGNORE()

	variable numWindows, i
	string list

	list = WinList("*", ";", "WIN:67") // Panels, Graphs and tables

	numWindows = ItemsInList(list)
	for(i = 0; i < numWindows; i += 1)
		KillWindow $StringFromList(i, list)
	endfor

	KillOrMoveToTrash(dfr=root:MIES)

	GetMiesPath()
	DuplicateDataFolder	root:WaveBuilder, root:MIES:WaveBuilder
	REQUIRE(DataFolderExists("root:MIES:WaveBuilder:SavedStimulusSetParameters:DA"))

	ITCCLoseAll2
End

/// @brief Background function to wait until DAQ is finished.
///
/// If it is finished prepares the next two, one DAQ and the corresponding `Test`, testcases to the queue
Function WaitUntilDAQDone_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	NVAR dataAcqRunMode = $GetDataAcqRunMode(DEVICE)

	if(dataAcqRunMode == DAQ_NOT_RUNNING)
		ExecuteNextTestCase_IGNORE()
		ExecuteNextTestCase_IGNORE()
		return 1
	endif

	return 0
End

/// @brief Structure to hold various common DAQ DAQSettings
///
/// MultiDevice (MD: 1/0)
/// Repeated Acquisition (RA: 1/0)
/// Indexing (IDX: 1/0)
/// Locked Indexing (LIDX: 1/0)
/// Background Data acquisition (BKG_DAQ: 1/0)
/// Repeat Sets (RES: [1, inf])
Structure DAQSettings
	variable MD, RA, IDX, LIDX, BKG_DAQ, RES
EndStructure

/// @brief Fill the #DAQSetttings structure from a specially crafted string
Function InitDAQSettingsFromString(s, str)
	STRUCT DAQSettings& s
	string str

	variable md, ra, idx, lidx, bkg_daq, res

	sscanf str, "DAQ_MD%d_RA%d_IDX%d_LIDX%d_BKG_%d_RES_%d", md, ra, idx, lidx, bkg_daq, res
	REQUIRE(V_Flag >= 5)

	s.md        = md
	s.ra        = ra
	s.idx       = idx
	s.lidx      = lidx
	s.bkg_daq   = bkg_daq
	s.res       = limit(res, 1, inf)
End

/// @brief Similiar to InitDAQSettingsFromString() but uses the function name of the caller
Function InitSettings(s)
	STRUCT DAQSettings& s

	string caller = GetRTStackInfo(2)
	InitDAQSettingsFromString(s, caller)
End
