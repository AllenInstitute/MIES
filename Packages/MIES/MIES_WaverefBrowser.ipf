#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_WRB
#endif // AUTOMATED_TESTING

/// @file MIES_WaverefBrowser.ipf
/// @brief __WRB__ Wavereference Wave Browser

static StrConstant WIN_NAME      = "WaverefBrowser"
static StrConstant WAVEINFO_NAME = "WrefBrowserWaveInfo"

Function WRB_AddDataBrowserButton()

	CreateBrowser
	ModifyBrowser appendUserButton={BrowseWref, "WRB_EvaluateDataBrowserSelection()", 1}
End

Function WRB_EvaluateDataBrowserSelection()

	string   sel
	variable idx

	WAVE wRef = GetWaverefBRowserReferenceWave()
	Redimension/N=(0) wRef

	for(;;)
		sel = GetBrowserSelection(idx++)
		if(IsEmpty(sel))
			break
		endif
		WAVE/Z/WAVE wv = $sel
		if(!WaveExists(wv))
			continue
		endif
		if(!IsWaverefWave(wv))
			break
		endif
		WRB_ShowWrefBrowser(wv)
	endfor
End

Function WRB_RecreateWrefBrowser()

	string nbName

	HideTools/W=$WIN_NAME/A
	StoreCurrentPanelsResizeInfo(WIN_NAME)

	SearchForInvalidControlProcs(WIN_NAME)
	ListBox wrefList, win=$WIN_NAME, selRow=0, listWave=$"", selWave=$"", colorWave=$""
	nbName = WIN_NAME + "#" + WAVEINFO_NAME
	ReplaceNotebookText(nbName, "")

	Execute/P/Z "DoWindow/R " + WIN_NAME
	Execute/P/Q/Z "COMPILEPROCEDURES "
	CleanupOperationQueueResult()
End

Function WRB_ShowWrefBrowser(WAVE/WAVE wv)

	variable listSize, refSize
	string wName

	WAVE/T    listWave  = GetWaverefBRowserListWave()
	WAVE      selWave   = GetWaverefBRowserSelectionWave()
	WAVE      colorWave = GetWaverefBRowserColorWave()
	WAVE/WAVE wRef      = GetWaverefBRowserReferenceWave()

	listSize = DimSize(wv, ROWS)
	Redimension/N=(listSize) listWave
	Redimension/N=(listSize, -1, -1) selWave

	refSize = DimSize(wRef, ROWS) + 1
	Redimension/N=(refSize) wRef
	wRef[refSize - 1] = wv

	WRB_UpdateListboxWave()

	if(!WindowExists(WIN_NAME))
		Execute "WaverefBrowser()"
	else
		DoWindow/F $WIN_NAME
	endif
	ListBox wrefList, win=$WIN_NAME, listWave=listWave, selWave=selWave, colorWave=colorWave
	SetWindow $WIN_NAME, hook(windowCoordinateSaving)=StoreWindowCoordinatesHook
	SetWindow $WIN_NAME, hook(cleanup)=WRB_BrowserWindowHook
	if(IsFreeWave(wv))
		wName = "Free wave ->" + NameOfWave(wv)
	else
		wName = GetWavesDataFolder(wv, 2)
	endif
	DoWindow/T $WIN_NAME, wName

	if(refSize == 1)
		DisableControl(WIN_NAME, "BackWrefWave")
	else
		EnableControl(WIN_NAME, "BackWrefWave")
	endif

	WRB_UpdateWaveInfo(0)
	DoUpdate/W=$WIN_NAME
	ModifyControl wrefList, win=$WIN_NAME, activate
End

Function WRB_UpdateListboxWave()

	variable listSize, i, majorType

	WAVE/WAVE wRef = GetWaverefBRowserReferenceWave()
	if(!DimSize(wRef, ROWS))
		return NaN
	endif
	WAVE/T listWave = GetWaverefBRowserListWave()
	WAVE   selWave  = GetWaverefBRowserSelectionWave()

	WAVE/WAVE wv = wRef[DimSize(wRef, ROWS) - 1]
	listSize = DimSize(wv, ROWS)
	Redimension/N=(listSize) listWave
	Redimension/N=(listSize, -1, -1) selWave

	for(i = 0; i < listSize; i += 1)
		majorType = WaveType(wv[i], 1)
		if(majorType == IGOR_TYPE_NUMERIC_WAVE)
			selWave[i][0][%$LISTBOX_LAYER_BACKGROUND] = 1
			listWave[i]                               = "NUM"
		elseif(majorType == IGOR_TYPE_TEXT_WAVE)
			selWave[i][0][%$LISTBOX_LAYER_BACKGROUND] = 2
			listWave[i]                               = "TEXT"
		elseif(majorType == IGOR_TYPE_DFREF_WAVE)
			selWave[i][0][%$LISTBOX_LAYER_BACKGROUND] = 3
			listWave[i]                               = "DFREF"
		elseif(majorType == IGOR_TYPE_WAVEREF_WAVE)
			selWave[i][0][%$LISTBOX_LAYER_BACKGROUND] = 4
			listWave[i]                               = "WREF"
		elseif(majorType == IGOR_TYPE_NULL_WAVE)
			selWave[i][0][%$LISTBOX_LAYER_BACKGROUND] = 0
			listWave[i]                               = "_null_"
		endif
	endfor
End

Function WRB_BrowserWindowHook(STRUCT WMWinHookStruct &s)

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_ACTIVATE:
			WRB_UpdateListboxWave()
			WRB_UpdateWaveInfo(WRB_GetSelectedIndex())
			break
		case EVENT_WINDOW_HOOK_KILL:
			WAVE/WAVE wRef = GetWaverefBRowserReferenceWave()
			Redimension/N=(0) wRef
			break
		default:
			break
	endswitch

	return 0
End

Function WRB_ListBoxProc_WrefBrowser(STRUCT WMListboxAction &lba) : ListBoxControl

	switch(lba.eventCode)
		case 3:
			WRB_ShowWrefWave()
			break
		case 4:
			WRB_UpdateWaveInfo(lba.row)
			break
		default:
			break
	endswitch

	return 0
End

static Function/S WRB_GetWaveTypeAsString(WAVE wv)

	variable type
	string   typeStr
	string prefix = ""

	switch(WaveType(wv, 1))
		case IGOR_TYPE_NULL_WAVE:
			return "NULL"
		case IGOR_TYPE_TEXT_WAVE:
			return "TEXT"
		case IGOR_TYPE_DFREF_WAVE:
			return "DFREF"
		case IGOR_TYPE_WAVEREF_WAVE:
			return "WAVEREF"
		case IGOR_TYPE_NUMERIC_WAVE:
			type = WaveType(wv)
			if(type & 0x01)
				prefix += "Complex "
			endif
			if(type & 0x40)
				prefix += "Unsigned "
			endif
			if(type & 0x02)
				typeStr = "single precision floating point"
			elseif(type & 0x04)
				typeStr = "double precision floating point"
			elseif(type & 0x08)
				typeStr = "8-bit integer"
			elseif(type & 0x10)
				typeStr = "16-bit integer"
			elseif(type & 0x20)
				typeStr = "32-bit integer"
			elseif(type & 0x80)
				typeStr = "64-bit integer"
			endif
			return prefix + typeStr
		default:
			break
	endswitch

	FATAL_ERROR("Unknown type")
End

static Function WRB_CountNotebookParagraphs(string nbName)

	variable para

	string txt = GetNotebookText(nbName, mode = 2)

	WAVE/T tmp = ListToTextWave(txt, "\r")
	para = DimSize(tmp, ROWS) - 1
	if(para < 0)
		return NaN
	endif

	return para
End

static Function WRB_AppendToNotebookWithRuler(string nbName, string txt, string ruler)

	variable para

	para = WRB_CountNotebookParagraphs(nbName)
	AppendToNotebookText(nbName, txt)
	if(IsNaN(para))
		Notebook $nbName, selection={startOfFile, endOfFile}, ruler=$ruler
	else
		Notebook $nbName, selection={(para, Inf), endOfFile}, ruler=$ruler
	endif
End

static Function WRB_ScrollToNotebookStart(string nbName)

	Notebook $nbName, selection={startOfFile, startOfFile}, findText={"", 1}
End

static Function WRB_UpdateWaveInfo(variable idx)

	string nbName, str
	variable level

	WAVE/WAVE wRef = GetWaverefBRowserReferenceWave()
	level = DimSize(wRef, ROWS)
	if(!level)
		return NaN
	endif
	WAVE/WAVE tgtWave = wRef[level - 1]

	nbName = WIN_NAME + "#" + WAVEINFO_NAME
	ReplaceNotebookText(nbName, "")

	Notebook $nbName, newRuler=rulIndex, rulerDefaults={"Consolas", 12, 1, (0, 0, 0)}
	Notebook $nbName, newRuler=rulType, rulerDefaults={"Consolas", 12, 0, (0, 0, 192 << 8)}
	Notebook $nbName, newRuler=rulDim, rulerDefaults={"Consolas", 12, 0, (0, 128 << 8, 0)}
	Notebook $nbName, newRuler=rulNote, rulerDefaults={"Courier", 12, 0, (0, 0, 240 << 8)}

	if(!DimSize(tgtWave, ROWS))
		WRB_AppendToNotebookWithRuler(nbName, "Wave reference wave is empty.", "rulIndex")
		WRB_ScrollToNotebookStart(nbName)
		DisableControl(WIN_NAME, "ShowWrefWave")
		return NaN
	endif

	if(idx >= DimSize(tgtWave, ROWS))
		return NaN
	endif

	WAVE/Z wv = tgtWave[idx]

	str = "Index: " + num2istr(idx) + " / " + num2istr(DimSize(tgtWave, ROWS)) + "\r"
	WRB_AppendToNotebookWithRuler(nbName, str, "rulIndex")
	if(!WaveExists(wv))
		WRB_AppendToNotebookWithRuler(nbName, "Null Wave\r", "rulType")
	else
		str = WRB_GetWaveTypeAsString(wv) + "\r"
		WRB_AppendToNotebookWithRuler(nbName, str, "rulType")

		sprintf str, "0: %6d\r1: %6d\r2: %6d\r3: %6d\r", DimSize(wv, ROWS), DimSize(wv, COLS), DimSize(wv, LAYERS), DimSize(wv, CHUNKS)
		WRB_AppendToNotebookWithRuler(nbName, str, "rulDim")

		str = note(wv)
		WRB_AppendToNotebookWithRuler(nbName, str, "rulNote")
	endif

	WRB_ScrollToNotebookStart(nbName)

	if(WaveType(wv, 1) == 0)
		DisableControl(WIN_NAME, "ShowWrefWave")
	else
		EnableControl(WIN_NAME, "ShowWrefWave")
	endif
End

static Function WRB_GetSelectedIndex()

	ControlInfo/W=$WIN_NAME wrefList
	if(V_value == -1)
		return NaN
	endif

	return V_value
End

static Function WRB_ShowWrefWave()

	string wName, tableWinName
	variable size, i, idx

	idx = WRB_GetSelectedIndex()
	if(IsNaN(idx))
		return NaN
	endif

	WAVE/WAVE wRef    = GetWaverefBRowserReferenceWave()
	WAVE/WAVE tgtWave = wRef[DimSize(wRef, ROWS) - 1]
	if(!DimSize(tgtWave, ROWS))
		return NaN
	endif

	WAVE/Z showWave = tgtWave[idx]
	if(!WaveExists(showWave))
		return NaN
	endif

	if(IsWaverefWave(showWave))
		WRB_ShowWrefBrowser(showWave)
		return NaN
	endif

	DFREF dfr = GetTempPath()
	wName        = CreateDataObjectName(dfr, "tmpBrowserWave", 1, 0, 0)
	tableWinName = GetUnusedWindowName("WaverefBrowserTable")

	if(WaveType(showWave, 1) == IGOR_TYPE_DFREF_WAVE)
		size = DimSize(showWave, ROWS)
		Make/T/N=(size) dfr:$wName/WAVE=dfrNameWave
		WAVE/DF showWaveDF = showWave
		for(i = 0; i < size; i += 1)
			if(!DataFolderExistsDFR(showWaveDF[i]))
				dfrNameWave[i] = "_null_"
				continue
			endif
			dfrNameWave[i] = SelectString(IsFreeDataFolder(showWaveDF[i]), GetDataFolder(1, showWaveDF[i]), "_free_")
		endfor

		Edit/K=1/N=$tableWinName dfrNameWave as "DataFolderReferences"
		SetWindow $tableWinName, hook(cleanup)=WRB_TableWindowHook, userdata(wvName)=GetWavesDataFolder(dfrNameWave, 2)
	elseif(IsFreeWave(showWave))
		Duplicate showWave, dfr:$wName
		WAVE wv = dfr:$wName
		Edit/K=1/N=$tableWinName wv as "Duplicate of Wave"
		SetWindow $tableWinName, hook(cleanup)=WRB_TableWindowHook, userdata(wvName)=GetWavesDataFolder(wv, 2)
	else
		Edit/K=1/N=$tableWinName showWave
	endif
End

Function WRB_TableWindowHook(STRUCT WMWinHookStruct &s)

	string wName

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KILL:
			wName = GetUserData(s.winName, "", "wvName")
			WAVE wv = $wName
			KillOrMoveToTrash(wv = wv)
			break
		default:
			break
	endswitch

	return 0
End

Function WRB_ButtonProc_WrefBrowserShow(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2:
			WRB_ShowWrefWave()
			break
		default:
			break
	endswitch

	return 0
End

Function WRB_ButtonProc_WrefBrowserBack(STRUCT WMButtonAction &ba) : ButtonControl

	variable size

	switch(ba.eventCode)
		case 2:
			WAVE/WAVE wRef = GetWaverefBRowserReferenceWave()
			size = DimSize(wRef, ROWS)
			ASSERT(size > 1, "Unexpected size")
			WAVE/WAVE tgtWave = wRef[size - 2]
			Redimension/N=(size - 2) wRef
			WRB_ShowWrefBrowser(tgtWave)
			break
		default:
			break
	endswitch

	return 0
End
