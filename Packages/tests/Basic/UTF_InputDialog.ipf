#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = InputDialogTest

/// The tests run with a non-interactive GetInteractiveMode(), see
/// AdditionalExperimentCleanup(). ID_AskUserForSettings() therefore skips
/// `PauseForUser`, copies `mock` into `data` and presses `Continue` itself. The
/// cancel path, and with it a return value of 1, requires a real user
/// interaction and can not be tested here.

/// @brief Number of entries of the popup menu dialog waves created here
///
/// Must be kept in sync with `DataGenerators#InputDialogPopupEntryIndizes`.
static Constant ID_TEST_NUM_POPUP_ENTRIES = 3

static StrConstant ID_TEST_POPUP_ENTRIES = "alpha;beta;gamma"

/// @brief Maximum number of key/value pairs the dialog can display
///
/// Must be kept in sync with the number of `setvar_` controls in
/// `IDM_KVPairs_Panel()`, with the loop bounds in ID_AskUserForSettings() and
/// with `DataGenerators#InputDialogKVPairsEntryCounts`.
static Constant ID_TEST_MAX_KVPAIRS_ENTRIES = 10

/// @brief Return a new permanent and otherwise empty datafolder as required by
///        ID_AskUserForSettings()
static Function/DF GetDialogFolder_IGNORE()

	return UniqueDataFolder(GetDataFolderDFR(), "dialog")
End

static Function/S GetPanelList_IGNORE()

	return WinList("*", ";", "WIN:64")
End

/// @brief Kill all panels which were created after `panelsBefore` was queried
///
/// Required for the code paths which assert only after the dialog panel was
/// already created.
static Function KillNewPanels_IGNORE(string panelsBefore)

	string   win
	variable i

	string   panelsAfter = GetPanelList_IGNORE()
	variable numPanels   = ItemsInList(panelsAfter)

	for(i = 0; i < numPanels; i += 1)
		win = StringFromList(i, panelsAfter)

		if(WhichListItem(win, panelsBefore) == -1)
			KillWindow/Z $win
		endif
	endfor
End

/// @brief Create a permanent key/value pairs dialog wave with `numEntries` entries
///
/// The row dimension labels hold the keys, the wave contents the values.
static Function/WAVE GetKVPairsWave_IGNORE(DFREF dfr, variable numEntries)

	variable i
	string keys = ""

	Make/T/N=(numEntries) dfr:data/WAVE=data
	data[] = "value" + num2istr(p)

	for(i = 0; i < numEntries; i += 1)
		keys = AddListItem("key" + num2istr(i), keys, ";", Inf)
	endfor

	SetDimensionLabels(data, keys, ROWS)

	return data
End

/// ID_AskUserForSettings
/// @{

static Function IDA_HeadstageSettingsWorks()

	variable ret
	string panelsBefore, panelsAfter, leftOverVariables

	DFREF dfr = GetDialogFolder_IGNORE()

	Make/D/N=(LABNOTEBOOK_LAYER_COUNT) dfr:data/WAVE=data
	data[] = p

	Duplicate/FREE data, mock
	mock[] = data[p] + 10

	panelsBefore = GetPanelList_IGNORE()

	ret = ID_AskUserForSettings(ID_HEADSTAGE_SETTINGS, "Autobias V", data, mock)
	CHECK_EQUAL_VAR(ret, 0)

	CHECK_EQUAL_WAVES(data, mock, mode = WAVE_DATA)

	// the dialog closes itself and does not leave its state variable behind
	panelsAfter = GetPanelList_IGNORE()
	CHECK_EQUAL_STR(panelsBefore, panelsAfter)

	leftOverVariables = GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_VAR)
	CHECK_EMPTY_STR(leftOverVariables)

	KillOrMoveToTrash(dfr = dfr)
End

static Function IDA_HeadstageSettingsWorksWithDisabledEntries()

	variable ret, i

	DFREF dfr = GetDialogFolder_IGNORE()

	Make/D/N=(LABNOTEBOOK_LAYER_COUNT) dfr:data/WAVE=data
	data[] = (p < 2) ? -70 : NaN

	Duplicate/FREE data, mock
	mock[] = data[p] + 1

	ret = ID_AskUserForSettings(ID_HEADSTAGE_SETTINGS, "Autobias V", data, mock)
	CHECK_EQUAL_VAR(ret, 0)

	for(i = 0; i < LABNOTEBOOK_LAYER_COUNT; i += 1)
		if(i < 2)
			CHECK_EQUAL_VAR(data[i], -69)
		else
			CHECK_EQUAL_VAR(data[i], NaN)
		endif
	endfor

	KillOrMoveToTrash(dfr = dfr)
End

// UTF_TD_GENERATOR DataGenerators#InputDialogPopupEntryIndizes
static Function IDA_PopupMenuSettingsWorks([variable var])

	variable ret
	string panelsBefore, panelsAfter, leftOverVariables

	REQUIRE_EQUAL_VAR(ItemsInList(ID_TEST_POPUP_ENTRIES), ID_TEST_NUM_POPUP_ENTRIES)
	REQUIRE_GE_VAR(var, 0)
	REQUIRE_LT_VAR(var, ID_TEST_NUM_POPUP_ENTRIES)

	DFREF dfr = GetDialogFolder_IGNORE()

	// the row dimension labels fill the popup menu
	Make/D/N=(ID_TEST_NUM_POPUP_ENTRIES) dfr:data/WAVE=data
	SetDimensionLabels(data, ID_TEST_POPUP_ENTRIES, ROWS)

	Duplicate/FREE data, mock
	mock[]    = 0
	mock[var] = 1

	panelsBefore = GetPanelList_IGNORE()

	ret = ID_AskUserForSettings(ID_POPUPMENU_SETTINGS, "Stimulus set to load", data, mock)
	CHECK_EQUAL_VAR(ret, 0)

	CHECK_EQUAL_WAVES(data, mock, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(Sum(data), 1)
	CHECK_EQUAL_VAR(GetRowIndex(data, val = 1), var)

	panelsAfter = GetPanelList_IGNORE()
	CHECK_EQUAL_STR(panelsBefore, panelsAfter)

	leftOverVariables = GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_VAR)
	CHECK_EMPTY_STR(leftOverVariables)

	KillOrMoveToTrash(dfr = dfr)
End

// UTF_TD_GENERATOR DataGenerators#InputDialogKVPairsEntryCounts
static Function IDA_KVPairsSettingsWorks([variable var])

	variable ret
	string panelsBefore, panelsAfter, leftOverVariables

	REQUIRE_GE_VAR(var, 1)
	REQUIRE_LE_VAR(var, ID_TEST_MAX_KVPAIRS_ENTRIES)

	DFREF dfr = GetDialogFolder_IGNORE()

	WAVE/T data = GetKVPairsWave_IGNORE(dfr, var)

	Duplicate/FREE/T data, mock
	mock[] = data[p] + "_edited"

	panelsBefore = GetPanelList_IGNORE()

	ret = ID_AskUserForSettings(ID_KVPAIRS_SETTINGS, "Metadata", data, mock)
	CHECK_EQUAL_VAR(ret, 0)

	// only the values are written back, the keys are untouched
	CHECK_EQUAL_TEXTWAVES(data, mock, mode = WAVE_DATA)

	Make/FREE/T/N=(var) keys = GetDimLabel(data, ROWS, p)
	Make/FREE/T/N=(var) refKeys = "key" + num2istr(p)
	CHECK_EQUAL_TEXTWAVES(keys, refKeys, mode = WAVE_DATA)

	// the dialog closes itself and does not leave its state variable behind
	panelsAfter = GetPanelList_IGNORE()
	CHECK_EQUAL_STR(panelsBefore, panelsAfter)

	leftOverVariables = GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_VAR)
	CHECK_EMPTY_STR(leftOverVariables)

	KillOrMoveToTrash(dfr = dfr)
End

static Function IDA_KVPairsAssertsOnNumericDataWave()

	string panelsBefore

	DFREF dfr = GetDialogFolder_IGNORE()

	Make/D/N=(ID_TEST_MAX_KVPAIRS_ENTRIES) dfr:data/WAVE=data
	Duplicate/FREE data, mock

	panelsBefore = GetPanelList_IGNORE()

	try
		ID_AskUserForSettings(ID_KVPAIRS_SETTINGS, "Metadata", data, mock)
		FAIL()
	catch
		PASS()
	endtry

	KillNewPanels_IGNORE(panelsBefore)

	KillOrMoveToTrash(dfr = dfr)
End

static Function IDA_KVPairsAssertsOnEmptyKey()

	string panelsBefore

	DFREF dfr = GetDialogFolder_IGNORE()

	// without row dimension labels the entries have no keys
	Make/T/N=(ID_TEST_MAX_KVPAIRS_ENTRIES) dfr:data/WAVE=data
	Duplicate/FREE/T data, mock

	panelsBefore = GetPanelList_IGNORE()

	try
		ID_AskUserForSettings(ID_KVPAIRS_SETTINGS, "Metadata", data, mock)
		FAIL()
	catch
		PASS()
	endtry

	KillNewPanels_IGNORE(panelsBefore)

	KillOrMoveToTrash(dfr = dfr)
End

static Function IDA_AssertsOnFreeDataWave()

	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT) data
	Duplicate/FREE data, mock

	try
		ID_AskUserForSettings(ID_HEADSTAGE_SETTINGS, "Autobias V", data, mock)
		FAIL()
	catch
		PASS()
	endtry
End

static Function IDA_AssertsOnMismatchedDimensionSize()

	DFREF dfr = GetDialogFolder_IGNORE()

	Make/D/N=(LABNOTEBOOK_LAYER_COUNT) dfr:data/WAVE=data
	Make/FREE/D/N=(LABNOTEBOOK_LAYER_COUNT - 1) mock

	try
		ID_AskUserForSettings(ID_HEADSTAGE_SETTINGS, "Autobias V", data, mock)
		FAIL()
	catch
		PASS()
	endtry

	KillOrMoveToTrash(dfr = dfr)
End

static Function IDA_AssertsOnMismatchedDataType()

	DFREF dfr = GetDialogFolder_IGNORE()

	Make/D/N=(LABNOTEBOOK_LAYER_COUNT) dfr:data/WAVE=data
	Make/FREE/T/N=(LABNOTEBOOK_LAYER_COUNT) mock

	try
		ID_AskUserForSettings(ID_HEADSTAGE_SETTINGS, "Autobias V", data, mock)
		FAIL()
	catch
		PASS()
	endtry

	KillOrMoveToTrash(dfr = dfr)
End

// UTF_TD_GENERATOR DataGenerators#InvalidInputDialogModes
static Function IDA_AssertsOnInvalidMode([variable var])

	DFREF dfr = GetDialogFolder_IGNORE()

	Make/D/N=(LABNOTEBOOK_LAYER_COUNT) dfr:data/WAVE=data
	Duplicate/FREE data, mock

	try
		ID_AskUserForSettings(var, "Autobias V", data, mock)
		FAIL()
	catch
		PASS()
	endtry

	KillOrMoveToTrash(dfr = dfr)
End

static Function IDA_AssertsOnEmptyDataWave()

	DFREF dfr = GetDialogFolder_IGNORE()

	Make/D/N=0 dfr:data/WAVE=data
	Duplicate/FREE data, mock

	try
		ID_AskUserForSettings(ID_HEADSTAGE_SETTINGS, "Autobias V", data, mock)
		FAIL()
	catch
		PASS()
	endtry

	KillOrMoveToTrash(dfr = dfr)
End

/// @}
