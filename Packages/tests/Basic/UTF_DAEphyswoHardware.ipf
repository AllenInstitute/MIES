#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=DAEphysTestsWithoutHardware

static Function TEST_CASE_BEGIN_OVERRIDE(string testname)

	TestCaseBeginCommon(testname)
End

static Function/S HAH_FillMockGuiStateWave(WAVE statusHS, WAVE clampModes)

	string device

	device = DAP_CreateDAEphysPanel()

	WAVE GUIState = GetDA_EphysGuiStateNum(device)

	GUIState[0, NUM_HEADSTAGES - 1][0]       = statusHS[p]
	GUIState[0, NUM_HEADSTAGES - 1][%HSMode] = clampModes[p]

	return device
End

/// @name DAG_HeadstageIsHighestActive
///
/// @{
Function HAH_ReturnsZero()

	string device
	Make/FREE/N=(NUM_HEADSTAGES) statusHS = 0
	Make/FREE/N=(NUM_HEADSTAGES) clampModes = NaN

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
End

Function HAH_Works1()

	string device
	Make/FREE/N=(NUM_HEADSTAGES) statusHS = 0
	Make/FREE/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[0] = 1

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p)
	CHECK_EQUAL_WAVES(isHighestActive, {1, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
End

Function HAH_Works2()

	string device
	Make/FREE/N=(NUM_HEADSTAGES) statusHS = 0
	Make/FREE/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[6] = 1

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 0, 0, 0, 0, 0, 1, 0}, mode = WAVE_DATA)
End

Function HAH_ChecksClampMode()

	string device
	Make/FREE/N=(NUM_HEADSTAGES) statusHS = 1
	Make/FREE/N=(NUM_HEADSTAGES) clampModes = NaN

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
	Make/FREE/N=(NUM_HEADSTAGES) statusHS = 0
	Make/FREE/N=(NUM_HEADSTAGES) clampModes = NaN

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
End

Function HAH_WorksWithClampMode1()

	string device
	Make/FREE/N=(NUM_HEADSTAGES) statusHS = 0
	Make/FREE/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[1, 2] = 1
	clampModes[1]  = I_CLAMP_MODE

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p, clampMode = I_CLAMP_MODE)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 1, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)
End

Function HAH_WorksWithClampMode2()

	string device
	Make/FREE/N=(NUM_HEADSTAGES) statusHS = 0
	Make/FREE/N=(NUM_HEADSTAGES) clampModes = NaN

	statusHS[1, 6] = 1
	clampModes[]   = I_CLAMP_MODE
	clampModes[6]  = V_CLAMP_MODE

	device = HAH_FillMockGuiStateWave(statusHS, clampModes)

	Make/FREE/N=(NUM_HEADSTAGES) isHighestActive, expected

	isHighestActive[] = DAG_HeadstageIsHighestActive(device, p, clampMode = V_CLAMP_MODE)
	CHECK_EQUAL_WAVES(isHighestActive, {0, 0, 0, 0, 0, 0, 1, 0}, mode = WAVE_DATA)
End
/// @}

static Function/WAVE GetStimsetFromUserData(string device, string ctrl)

	return ListToTextWave(RemoveFromList(STIMSET_TP_WHILE_DAQ, GetUserData(device, ctrl, USER_DATA_MENU_EXP)), ";")
End

/// UTF_TD_GENERATOR v1:GetChannelTypes
/// UTF_TD_GENERATOR v0:GetChannelNumbersForDATTL
Function CheckStimsetUpdateAndSearch([STRUCT IUTF_mData &m])

	string device, expected, ctrlWave, ctrlSearch
	variable channelType, channelNumber

	channelNumber = m.v0
	channelType   = m.v1

	// TTL only has the ALL control and not the IC/VC ALL ones
	if(channelType == CHANNEL_TYPE_TTL && channelNumber < 0 && channelNumber != CHANNEL_INDEX_ALL)
		PASS()
		return NaN
	endif

	device = DAP_CreateDAEphysPanel()

	WAVE/T stimsetsEmpty = ListToTextWave(RemoveFromList(STIMSET_TP_WHILE_DAQ, ST_GetStimsetList()), ";")
	Make/T/FREE/N=0 refStimsets
	CHECK_EQUAL_TEXTWAVES(stimsetsEmpty, refStimsets)

	// create some thirdparty stimsets
	DFREF dfr = GetSetFolder(channelType)
	ctrlWave = GetPanelControl(channelNumber, channelType, CHANNEL_CONTROL_WAVE)

	WAVE/T stimsetsFromMenu = GetStimsetFromUserData(device, ctrlWave)
	CHECK_EQUAL_TEXTWAVES(stimsetsEmpty, stimsetsFromMenu)

	Make dfr:stimsetA
	Make dfr:stimsetB
	Make dfr:stimsetC

	WAVE/T stimsets = ListToTextWave(RemoveFromList(STIMSET_TP_WHILE_DAQ, ST_GetStimsetList()), ";")
	Make/T/FREE refStimsets = {"stimsetA", "stimsetB", "stimsetC"}
	CHECK_EQUAL_TEXTWAVES(stimsets, refStimsets)

	// not yet updated
	WAVE/T stimsetsFromMenu = GetStimsetFromUserData(device, ctrlWave)
	CHECK_EQUAL_TEXTWAVES(stimsetsEmpty, stimsetsFromMenu)

	WB_UpdateChangedStimsets(device = device)

	// updated
	WAVE/T stimsetsFromMenu = GetStimsetFromUserData(device, ctrlWave)
	CHECK_EQUAL_TEXTWAVES(stimsets, stimsetsFromMenu)

	// update search box
	ctrlSearch = GetPanelControl(channelNumber, channelType, CHANNEL_CONTROL_SEARCH)
	PGC_SetAndActivateControl(device, ctrlSearch, str = "*D")

	// no hits
	WAVE/T stimsetsFromMenu = GetStimsetFromUserData(device, ctrlWave)
	CHECK_EQUAL_TEXTWAVES(stimsetsEmpty, stimsetsFromMenu)

	// add another stimset and update
	Make dfr:stimsetD

	WB_UpdateChangedStimsets(device = device)

	WAVE/T stimsetsFromMenu = GetStimsetFromUserData(device, ctrlWave)
	CHECK_EQUAL_TEXTWAVES({"stimsetD"}, stimsetsFromMenu)
End

/// DAP_GetRAAcquisitionCycleID
/// @{

static StrConstant device = "ITC18USB_DEV_0"

Function AssertOnInvalidSeed()

	NVAR rngSeed = $GetRNGSeed(device)
	rngSeed = NaN

	try
		MIES_DAP#DAP_GetRAAcquisitionCycleID(device)
		FAIL()
	catch
		PASS()
	endtry
End

Function CreatesReproducibleResults()

	NVAR rngSeed = $GetRNGSeed(device)

	// Use GetNextRandomNumberForDevice directly
	// as we don't have a locked device

	rngSeed = 1
	Make/FREE/N=1024/L dataInt = GetNextRandomNumberForDevice(device)
	CHECK_EQUAL_VAR(2932874867, WaveCRC(0, dataInt))

	rngSeed = 1
	Make/FREE/N=1024/D dataDouble = GetNextRandomNumberForDevice(device)

	CHECK_EQUAL_WAVES(dataInt, dataDouble, mode = WAVE_DATA)
End
/// @}
