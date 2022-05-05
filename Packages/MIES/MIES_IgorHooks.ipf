#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_IH
#endif

/// @file MIES_IgorHooks.ipf
/// @brief __IH__ Various hooks which influence the behaviour at certain global events

/// @brief Remove all strings/variables/waves which should not
/// survive experiment reload/quit/saving
///
/// Mainly useful for temporaries which you want to recreate on initialization
static Function IH_KillTemporaries()

	string trashFolders, path, allFolders, list
	variable numFolders, i

	DFREF dfr = GetMiesPath()

	KillStrings/Z dfr:version

	DFREF dfrHW = GetDAQDevicesFolder()

	KillStrings/Z dfrHW:NIDeviceList
	KillStrings/Z dfrHW:ITCDeviceList

	// try to delete all trash folders
	trashFolders = GetListOfObjects(dfr, TRASH_FOLDER_PREFIX + ".*", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath=1)

	numFolders = ItemsInList(trashFolders)
	for(i = 0; i < numFolders; i += 1)
		path = StringFromList(i, trashFolders)
		KillDataFolder/Z $path
	endfor

	RemoveEmptyDataFolder(dfr)

	DFREF dfr = GetWaveBuilderDataPath()
	list = GetListOfObjects(dfr, SEGMENTWAVE_SPECTRUM_PREFIX + ".*", fullPath=1)
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, list)
End

/// @brief Remove the amplifier connection waves
Function IH_RemoveAmplifierConnWaves()

	KillOrMoveToTrash(wv=GetAmplifierTelegraphServers())
	KillOrMoveToTrash(wv=GetAmplifierMultiClamps())
End

/// @brief Delete all wavebuilder stim sets to save memory
static Function IH_KillStimSets()

	string list, path

	ST_GetStimsetList(channelType = CHANNEL_TYPE_DAC, WBstimSetList=list)
	path = GetDataFolder(1, GetWBSvdStimSetDAPath())
	list = AddPrefixToEachListItem(path, list)
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, list)

	ST_GetStimsetList(channelType = CHANNEL_TYPE_TTL, WBstimSetList=list)
	path = GetDataFolder(1, GetWBSvdStimSetTTLPath())
	list = AddPrefixToEachListItem(path, list)
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, list)
End

/// @brief Write the current JSON settings to disc
///
/// We also invalidate the stored json ID, so that on the next access
/// it is read again.
static Function IH_SerializeSettings()
	NVAR JSONid = $GetSettingsJSONid()

	PS_SerializeSettings(PACKAGE_MIES, JSONid)

	JSONid = NaN
End

// Support not saving the experiments at all
// the *only* use case is for mass converting PXPs to NWBv2 from a read-only filesystem

#ifdef MIES_PXP_NWB_CONVERSION_SKIP_SAVING

static Function IgorBeforeNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	ExperimentModified 0

	return 0
End

static Function IgorStartOrNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	ExperimentModified 0

	return 0
End

static Function BeforeExperimentSaveHook(rN, fileName, path, type, creator, kind)
	Variable rN, kind
	String fileName, path, type, creator

	ExperimentModified 0

	return 0
End

static Function IgorBeforeQuitHook(unsavedExp, unsavedNotebooks, unsavedProcedures)
	variable unsavedExp, unsavedNotebooks, unsavedProcedures

	ExperimentModified 0

	return 0
End

#else

static Function BeforeExperimentSaveHook(rN, fileName, path, type, creator, kind)
	Variable rN, kind
	String fileName, path, type, creator

	// don't try cleaning up if the user never used MIES
	if(!DataFolderExists(GetMiesPathAsString()))
		return NaN
	endif

	LOG_AddEntry(PACKAGE_MIES, "start")

	DAP_SerializeAllCommentNBs()
	IH_SerializeSettings()

	IH_KillTemporaries()

	NVAR fileIDExport = $GetNWBFileIDExport()

	if(H5_IsFileOpen(fileIDExport))
		NWB_Flush(fileIDExport)
	endif

	LOG_AddEntry(PACKAGE_MIES, "end")
End

/// @brief Cleanup before closing or starting a new experiment
///
/// Takes care of unlocking the hardware, removing any data which is stale on
/// reload anyway (amplifier connection details) and removes temporary waves.
static Function IH_Cleanup()

	variable debuggerState, err

	// don't try cleaning up if the user never used MIES
	if(!DataFolderExists(GetMiesPathAsString()))
		return NaN
	endif

	LOG_AddEntry(PACKAGE_MIES, "start")

	debuggerState = DisableDebugger()

	// catch all error conditions, asserts and aborts
	// and ignore them
	AssertOnAndClearRTError()
	try
		DAP_UnlockAllDevices(); AbortOnRTE
		IH_RemoveAmplifierConnWaves(); AbortOnRTE
		IH_KillTemporaries(); AbortOnRTE
		IH_KillStimSets(); AbortOnRTE
		CA_FlushCache(); AbortOnRTE
		IH_SerializeSettings(); AbortOnRTE

		DFREF dfrNWB = GetNWBFolder()
		KilLVariables/Z dfrNWB:histRefNumber
	catch
		ClearRTError()
		BUG("Caught runtime error or assertion: " + num2istr(err))
	endtry

	ResetDebuggerState(debuggerState)

	LOG_AddEntry(PACKAGE_MIES, "end")
End

static Function IgorBeforeQuitHook(unsavedExp, unsavedNotebooks, unsavedProcedures)
	variable unsavedExp, unsavedNotebooks, unsavedProcedures

	LOG_AddEntry(PACKAGE_MIES, "start")

	IH_Cleanup()

	// save the experiment silently if it was saved before
	if(unsavedExp == 0 && cmpstr(UNTITLED_EXPERIMENT, GetExperimentName()))
		LOG_AddEntry(PACKAGE_MIES, "before save")
		SaveExperiment
		LOG_AddEntry(PACKAGE_MIES, "after save")
	endif

	LOG_AddEntry(PACKAGE_MIES, "end")

	return 0
End

static Function IgorQuitHook(igorApplicationNameStr)
	string igorApplicationNameStr

	LOG_AddEntry(PACKAGE_MIES, "start")

	IH_Cleanup()

	LOG_AddEntry(PACKAGE_MIES, "end")
End

/// Called before a new experiment is opened, in response to the New Experiment,
/// Revert Experiment, or Open Experiment menu items in the File menu.
static Function IgorBeforeNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	variable modifiedBefore, modifiedAfter

	LOG_AddEntry(PACKAGE_MIES, "start")

	ExperimentModified
	modifiedBefore = V_flag

	IH_Cleanup()

	ExperimentModified
	modifiedAfter = V_flag

	if(!modifiedBefore && modifiedAfter && cmpstr(UNTITLED_EXPERIMENT, GetExperimentName()))
		LOG_AddEntry(PACKAGE_MIES, "before save")
		SaveExperiment
		LOG_AddEntry(PACKAGE_MIES, "after save")
	endif

	StartZeroMQSockets()

	LOG_AddEntry(PACKAGE_MIES, "end")

	return 0
End

/// Called when Igor is first launched and then whenever a new experiment is being created.
static Function IgorStartOrNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	string miesVersion

	PS_FixPackageLocation(PACKAGE_MIES)

	LOG_MarkSessionStart(PACKAGE_MIES)
	UpdateZeroMQXOPLoggingTemplate()

	miesVersion = ROStr(GetMiesVersion())
	LOG_AddEntry(PACKAGE_MIES, "start", keys = {"version", "computername", "username", "igorinfo"}, \
	                                    values = {StringFromList(0, miesVersion, "\r"),             \
	                                              GetEnvironmentVariable("COMPUTERNAME"),           \
	                                              IgorInfo(7),                                      \
	                                              IgorInfo(0)})

	StartZeroMQSockets()

	LOG_AddEntry(PACKAGE_MIES, "end")

	return 0
End

static Function BeforeUncompiledHook(changeCode, procedureWindowTitleStr, textChangeStr)
	variable changeCode
	string procedureWindowTitleStr
	string textChangeStr

	LOG_AddEntry(PACKAGE_MIES, "start")

	// catch all error conditions, asserts and aborts
	// and ignore them
	AssertOnAndClearRTError()
	try
		DQ_StopOngoingDAQAllLocked(DQ_STOP_REASON_UNCOMPILED); AbortOnRTE
	catch
		ClearRTError()
	endtry

	// dito
	AssertOnAndClearRTError()
	try
		ASYNC_Stop(timeout=5); AbortOnRTE
	catch
		ClearRTError()
	endtry

	LOG_AddEntry(PACKAGE_MIES, "end")
End

static Function AfterCompiledHook()
	ClearRTError()

	variable modifiedBefore

	LOG_AddEntry(PACKAGE_MIES, "start")

	ExperimentModified
	modifiedBefore = V_flag

	ASYNC_Start(threadprocessorCount, disableTask=1)

	if(!modifiedBefore)
		ExperimentModified 0
	endif

	LOG_AddEntry(PACKAGE_MIES, "end")
End

#endif

Function IH_ResetScaling(struct WMWinHookStruct &s)
	string activeSW, graph, list, win
	variable i, numEntries

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KEYBOARD: // keyboard
			if(cmpstr(s.keyText, "A") || s.eventMod != WINDOW_HOOK_EMOD_CTRLKEYDOWN)
				break
			endif

			// Got Ctrl + A

			// first try if the selected window is a graph

			graph = GetMainWindow(s.winName)
			GetWindow $graph activeSW
			activeSW = S_Value

			if(WinType(activeSW) == WINTYPE_GRAPH)
				SetAxis/W=$activeSW/A
				break
			endif

			// if not we rescale all subgraphs
			list = GetAllWindows(graph)
			numEntries = ItemsInList(list)
			for(i = 0; i < numEntries; i += 1)
				win = StringFromList(i, list)

				if(WinType(win) != WINTYPE_GRAPH)
					continue
				endif

				SetAxis/W=$win/A
			endfor
			break
	endswitch

	// return zero so that other hooks are called as well
	return 0
End
