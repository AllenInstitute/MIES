#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_WRB
#endif // AUTOMATED_TESTING

/// @file MIES_WaverefBrowser.ipf
/// @brief __WRB__ Wavereference Wave Browser

static StrConstant WIN_NAME      = "WaverefBrowser"
static StrConstant TABLE_NAME    = "dupTable"
static StrConstant PANEL_NAME    = "panel"
static StrConstant WAVEINFO_NAME = "WrefBrowserWaveInfo"
static Constant    PREVIEW_COUNT = 10

// From ModifyTable elements
static Constant TABLE_ELEMENTS_ROW = -2
static Constant TABLE_ELEMENTS_COL = -3

// Regex for the ModifyTable property elements(waveName)=(num,num,num,num)
static StrConstant TABLE_RECREATION_ELEMENTS = "elements\(.+?\)=\(([^,\)]+),([^,\)]+)(?:,([^,\)]+))?(?:,([^,\)]+))?\)"

Menu "TablePopup", dynamic
	WRB_ContextualTableMenuItem(), /Q, WRB_ShowWrefBrowserFromContext()
End

Menu "DataBrowserObjectsPopup", dynamic
	WRB_DisplayDBMenuItemString(), /Q, WRB_EvaluateDataBrowserSelection()
End

Function/S WRB_DisplayDBMenuItemString()

	string   sel
	variable idx

	if(IsEmpty(GetBrowserSelection(-1)))
		return ""
	endif

	for(;;)
		sel = GetBrowserSelection(idx++)
		if(IsEmpty(sel))
			break
		endif
		WAVE/Z/WAVE wv = $sel
		if(!WaveExists(wv))
			continue
		endif
		if(!IsWaveRefWave(wv))
			break
		endif
		return "Browse WREF"
	endfor

	return ""
End

Function/S WRB_ContextualTableMenuItem()

	GetLastUserMenuInfo
	WAVE/Z wv = $S_firstColumnPath
	if(WaveExists(wv) && IsWaveRefWave(wv))
		return "Open WRB for column"
	endif

	return ""
End

Function WRB_ShowWrefBrowserFromContext()

	GetLastUserMenuInfo
	WAVE/Z wv = $S_firstColumnPath
	ASSERT(WaveExists(wv) && IsWaveRefWave(wv), "Expected existing Waveref Wave")

	WRB_ClearWaverefBRowserReferenceWave()
	WRB_ShowWrefBrowser(wv)
End

Function WRB_AddDataBrowserButton()

	string menuItem

	CreateBrowser
	ModifyBrowser appendUserButton={BrowseWref, "WRB_EvaluateDataBrowserSelection()", 1}

	menuItem = "Show Column Info Tags"
	Edit
	DoIgorMenu/OVRD "Table", menuItem
	if(CmpStr(S_value, menuItem))
		DoIgorMenu/OVRD "Table", menuItem
	endif
	KillWindow/Z $S_name
End

Function WRB_EvaluateDataBrowserSelection()

	string   sel
	variable idx

	if(IsEmpty(GetBrowserSelection(-1)))
		return NaN
	endif

	WRB_ClearWaverefBRowserReferenceWave()

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

static Function WRB_ClearWaverefBRowserReferenceWave()

	WAVE wRef = GetWaverefBRowserReferenceWave()
	Redimension/N=(0) wRef
End

// Steps to recreate the macro:
//
// - Enable the Databrowser menu via `MIES Panels->Advanced->Panels->Enable Enhanced Databrowser`
// - Create a wave reference wave with `make/o/wave d = {NewFreeWave(0, 1)}`
// - Select the wave reference wave in the databrowser and choose "BrowseWref"
// - Execute `WRB_StartupSettings()`
Function WRB_StartupSettings()

	string nbName

	HideTools/W=$WIN_NAME/A
	StoreCurrentPanelsResizeInfo(WIN_NAME)

	SearchForInvalidControlProcs(WIN_NAME)
	ListBox wrefList, win=$WIN_NAME, selRow=0, listWave=$"", selWave=$"", colorWave=$""
	nbName = WIN_NAME + "#" + WAVEINFO_NAME
	ReplaceNotebookText(nbName, "")

	DoWindow/T $WIN_NAME, "Waveref Wave Browser"

	PS_RemoveCoordinateSaving(WIN_NAME)

	Execute/P/Z "DoWindow/R " + WIN_NAME
	Execute/P/Q/Z "COMPILEPROCEDURES "
	CleanupOperationQueueResult()
End

Function WRB_ShowWrefBrowser(WAVE/WAVE wv)

	variable listSize, refSize
	string wName, tableName, panelName

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
		NVAR JSONid = $GetSettingsJSONid()
		PS_InitCoordinates(JSONid, WIN_NAME)
	else
		DoWindow/F $WIN_NAME
	endif
	ListBox wrefList, win=$WIN_NAME, listWave=listWave, selWave=selWave, colorWave=colorWave
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

	WAVE ttLoc = GetWaverefBrowserLastTooltipLocation()
	ttLoc[] = NaN

	DFREF dfr = GetTempPath()
	wName = CreateDataObjectName(dfr, "previewDuplicate", 1, 0, 0)
	Duplicate wv, dfr:$wName
	WAVE tableWave = dfr:$wName

	panelName = WIN_NAME + "#" + PANEL_NAME
	if(!WindowExists(WIN_NAME + "#" + PANEL_NAME))
		NewPanel/HOST=$WIN_NAME/EXT=0/W=(0, 0, 500, 500)/N=$PANEL_NAME as " "
		ModifyPanel/W=$panelName fixedSize=0
	endif
	tableName = panelName + "#" + TABLE_NAME
	KillWindow/Z $tableName
	Edit/HOST=$panelName/FG=(FL, FT, FR, FB)/N=$TABLE_NAME tableWave as "Duplicate of wave"
	SetWindow $tableName, tooltipHook(myHook)=WRB_TableTooltipHook
	SetWindow $tableName, hook(cleanup)=WRB_TableWindowHook, userdata(wvName)=GetWavesDataFolder(tableWave, 2)
	SetWindow $panelName, hook(MyHook)=WRB_TableWindowHookNav
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
		majorType = WaveType(wv[i][0][0][0], 1)
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
	Notebook $nbName, newRuler=rulPreview, rulerDefaults={"Courier", 12, 0, (0, 0, 140 << 8)}

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
		str = WRB_GetWaveTypeStr(wv) + " -> " + GetWavesDataFolder(wv, 2) + "\r"
		WRB_AppendToNotebookWithRuler(nbName, str, "rulType")

		sprintf str, "0: %6d\r1: %6d\r2: %6d\r3: %6d\r", DimSize(wv, ROWS), DimSize(wv, COLS), DimSize(wv, LAYERS), DimSize(wv, CHUNKS)
		WRB_AppendToNotebookWithRuler(nbName, str, "rulDim")

		str = note(wv)
		WRB_AppendToNotebookWithRuler(nbName, str, "rulNote")

		str = "---\r" + WRB_GetPreviewStr(wv)
		WRB_AppendToNotebookWithRuler(nbName, str, "rulPreview")
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

static Function/S WRB_GetWaveTypeStr(WAVE/Z wv)

	variable type
	string typeStr = ""

	if(!WaveExists(wv))
		return "NULL"
	endif
	type = WaveType(wv)
	if(type == IGOR_TYPE_TEXT_WREF_DFR)
		type = WaveType(wv, 1)
		if(type == IGOR_TYPE_TEXT_WAVE)
			typeStr = "TEXT"
		elseif(type == IGOR_TYPE_DFREF_WAVE)
			typeStr = "DFREF"
		elseif(type == IGOR_TYPE_WAVEREF_WAVE)
			typeStr = "WAVE"
		else
			typeStr = "unknown"
		endif

		return typeStr
	endif

	if(type & IGOR_TYPE_COMPLEX)
		typeStr += "CMPLX "
	endif
	if(type & IGOR_TYPE_UNSIGNED)
		typeStr += "U"
	endif
	if(type & IGOR_TYPE_32BIT_FLOAT)
		typeStr += "SP"
	elseif(type & IGOR_TYPE_64BIT_FLOAT)
		typeStr += "DP"
	elseif(type & IGOR_TYPE_8BIT_INT)
		typeStr += "INT8"
	elseif(type & IGOR_TYPE_16BIT_INT)
		typeStr += "INT16"
	elseif(type & IGOR_TYPE_32BIT_INT)
		typeStr += "INT32"
	elseif(type & IGOR_TYPE_64BIT_INT)
		typeStr += "INT64"
	else
		typeStr = "unknown"
	endif

	return typeStr
End

static Function/S WRB_GetPreviewStr(WAVE/Z wv, [variable useHtml])

	variable i
	string   sizeStr
	string str = ""

	useHtml = ParamIsDefault(useHtml) ? 0 : !!useHtml

	for(i = 0; i < PREVIEW_COUNT; i += 1)
		if(DimSize(wv, ROWS) == i)
			break
		endif

		if(IsWaveRefWave(wv))
			WAVE/WAVE subWave = wv
			str += num2istr(i) + " : " + WRB_GetWaveTypeStr(subWave[i])
			if(WaveExists(subWave[i]))
				WAVE subSubWave = subWave[i]
				sprintf sizeStr, "(%d,%d,%d,%d)", DimSize(subSubWave, ROWS), DimSize(subSubWave, COLS), DimSize(subSubWave, LAYERS), DimSize(subSubWave, CHUNKS)
				str += " " + sizeStr + " -> " + GetWavesDataFolder(subSubWave, 2)
			endif
		elseif(IsTextWave(wv))
			WAVE/T subWaveTxt = wv
			str += num2istr(i) + " : " + SelectString(useHtml, subWaveTxt[i], WRB_EscapeHTML(subWaveTxt[i]))
		elseif(IsNumericWave(wv))
			str += num2istr(i) + " : " + num2str(wv[i])
		elseif(WaveType(wv, 1) == IGOR_TYPE_DFREF_WAVE)
			WAVE/DF wvdf = wv
			DFREF   dfr  = wvdf[i]
			str += num2istr(i) + " : "
			if(DataFolderExistsDFR(dfr))
				str += GetDataFolder(1, wvdf[i])
			else
				str += "_null_"
			endif
		endif
		if(useHtml)
			str += "<br>"
		else
			str += "\r"
		endif

	endfor
	str += "..."

	return str
End

static Function/WAVE WRB_GetTableElements(string win)

	string recMacro, res0, res1, res2, res3

	recMacro = WinRecreation(win, 0)
	SplitString/E=TABLE_RECREATION_ELEMENTS recMacro, res0, res1, res2, res3

	if(V_flag == 0)
		Make/FREE wv = {ROWS, COLS}
		return wv
	endif
	if(V_flag == 1)
		FATAL_ERROR("Unexpected result")
	endif

	Make/FREE results = {str2numSafe(res0), str2numSafe(res1), str2numSafe(res2), str2numSafe(res3)}
	WAVE/Z rowDim = FindIndizes(results, var = TABLE_ELEMENTS_ROW)
	WAVE/Z colDim = FindIndizes(results, var = TABLE_ELEMENTS_COL)
	ASSERT(WaveExists(rowDim) && WaveExists(colDim), "Expected a row and col result")
	ASSERT(DimSize(rowDim, ROWS) == 1 && DimSize(colDim, ROWS) == 1, "Expected a single row and col result")
	Make/FREE wv = {rowDim[0], colDim[0]}

	return wv
End

static Function/S WRB_EscapeHTML(string str)

	str = ReplaceString("&", str, "&amp;")
	str = ReplaceString(">", str, "&gt;")
	str = ReplaceString("<", str, "&lt;")

	return str
End

Function WRB_TableTooltipHook(STRUCT WMTooltipHookStruct &s)

	string str
	variable tRow, tCol, tLayer, tChunk, visPlaneRow, visPlaneCol

	if(!WaveExists(s.yWave))
		return 0
	endif

	WAVE shownPlane = WRB_GetTableElements(s.winName)
	tRow   = s.row
	tCol   = max(0, s.column)
	tLayer = max(0, s.layer)
	tChunk = max(0, s.chunk)
	Make/FREE coords = {tRow, tCol, tLayer, tChunk}
	visPlaneRow = coords[shownPlane[ROWS]]
	visPlaneCol = coords[shownPlane[COLS]]
	ModifyTable/W=$s.winName selection=(visPlaneRow, visPlaneCol, visPlaneRow, visPlaneCol, visPlaneRow, visPlaneCol)

	WAVE ttLoc = GetWaverefBrowserLastTooltipLocation()
	ttLoc = {tRow, tCol, tLayer, tChunk}

	s.isHtml      = 1
	s.duration_ms = 10000

	s.tooltip  = "<p style=\"font-family:'Courier New'\">"
	s.tooltip += GetWavesDataFolder(s.yWave, 2) + " @ "
	if(s.column < 0)
		sprintf str, "[%d]<br>", s.row
	elseif(s.layer < 0)
		sprintf str, "[%d,%d]<br>", s.row, s.column
	elseif(s.chunk < 0)
		sprintf str, "[%d,%d,%d]<br>", s.row, s.column, s.layer
	else
		sprintf str, "[%d,%d,%d,%d]<br>", s.row, s.column, s.layer, s.chunk
	endif
	s.tooltip += str

	if(IsWaveRefWave(s.yWave))
		WAVE/WAVE wref = s.yWave
		WAVE/Z    elem = wref[tRow][tCol][tLayer][tChunk]
		if(!WaveExists(elem))
			s.tooltip += "-> null Wave"
			s.tooltip += "</p>"
			return 1
		endif
		s.tooltip += "-> " + GetWavesDataFolder(elem, 2) + "<br>"
		sprintf str, "%s, (%d,%d,%d,%d)<br>", WRB_GetWaveTypeStr(elem), DimSize(elem, ROWS), DimSize(elem, COLS), DimSize(elem, LAYERS), DimSize(elem, CHUNKS)
		s.tooltip += str
		s.tooltip += "---<br>"
		s.tooltip += WRB_GetPreviewStr(elem, useHtml = 1)
		s.tooltip += "</p>"

		return 1
	endif
	if(WaveType(s.yWave, 1) == IGOR_TYPE_DFREF_WAVE)
		WAVE/DF wvdf = s.yWave
		DFREF   dfr  = wvdf[tRow][tCol][tLayer][tChunk]
		s.tooltip += "-> "
		if(DataFolderExistsDFR(dfr))
			s.tooltip += GetDataFolder(1, dfr)
		else
			s.tooltip += "_null_"
		endif
		s.tooltip += "<br></p>"

		return 1
	endif
	// content of text or numeric waves is already shown properly in the cells of the table
End

Function WRB_TableWindowHookNav(STRUCT WMWinHookStruct &s)

	string win, wName
	variable hookResult

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KEYBOARD:
			if(s.specialKeyCode != 200)
				break
			endif
			WAVE ttLoc = GetWaverefBrowserLastTooltipLocation()
			if(IsNaN(ttLoc[0]))
				return hookResult
			endif
			win   = WIN_NAME + "#" + PANEL_NAME + "#" + TABLE_NAME
			wName = GetUserData(win, "", "wvName")
			WAVE/WAVE wv = $wName

			WAVE/Z target = wv[ttLoc[0]][ttLoc[1]][ttLoc[2]][ttLoc[3]]
			if(WaveExists(target) && IsWaveRefWave(target))
				WRB_ShowWrefBrowser(target)
				hookResult = 1
			endif

			break
		default:
			break
	endswitch

	return hookResult
End
