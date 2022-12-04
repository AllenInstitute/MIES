#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=DAEphysTestsWithoutHardware

static Function TEST_CASE_BEGIN_OVERRIDE(string testname)

	AdditionalExperimentCleanup()
End

static Function/S HAH_FillMockGuiStateWave(WAVE statusHS, WAVE clampModes)

	string device

	device = DAP_CreateDAEphysPanel()

	WAVE GUIState = GetDA_EphysGuiStateNum(device)

	GUIState[0, NUM_HEADSTAGES - 1][0] = statusHS[p]
	GUIState[0, NUM_HEADSTAGES - 1][%HSMode] = clampModes[p]

	return device
End

/// @name DAG_HeadstageIsHighestActive
///
/// @{
Function HAH_ReturnsZero()

	string device
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
End

Function HAH_Works1()

	string device
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[0] = 1

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p)
	CHECK_EQUAL_WAVES(isHighestActive, {1, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
End

Function HAH_Works2()

	string device
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[6] = 1

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 0, 0, 0, 0, 0, 1, 0}, mode = WAVE_DATA)
End

Function HAH_ChecksClampMode()

	string device
	Make/O/N=(NUM_HEADSTAGES) statusHS = 1
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	try
		DAG_HeadstageIsHighestActive(device, 0, clampMode = NaN); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function HAH_ReturnsZeroWithClampMode()

	string device
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
End

Function HAH_WorksWithClampMode1()

	string device
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[1, 2] = 1
	clampModes[1] = I_CLAMP_MODE

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p, clampMode = I_CLAMP_MODE)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 1, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
End

Function HAH_WorksWithClampMode2()

	string device
	Make/O/N=(NUM_HEADSTAGES) statusHS = 0
	Make/O/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[1, 6] = 1
	clampModes[] = I_CLAMP_MODE
	clampModes[6] = V_CLAMP_MODE

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p, clampMode = V_CLAMP_MODE)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 0, 0, 0, 0, 0, 1, 0}, mode = WAVE_DATA)
End
/// @}
