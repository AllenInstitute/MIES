#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// third party includes
#include ":ACL_TabUtilities"
#include ":ACL_UserdataEditor"
#include ":FixScrolling"

// our includes
#include ":TJ_MIES_Constants"
#include ":TJ_MIES_Debugging"
#include ":TJ_MIES_GlobalStringAndVariableAccess"
#include ":TJ_MIES_GuiUtilities"
#include ":TJ_MIES_MiesUtilities"
#include ":TJ_MIES_Utilities"
#include ":TJ_MIES_WaveDataFolderGetters"

Menu "Mies Panels", dynamic
		"Data Browser", /Q, Execute "DataBrowser()"
End

static Constant GRAPH_DIV_SPACING       = 0.03
static StrConstant LAST_SWEEP_USER_DATA = "lastSweep"

static Function/DF DB_GetDataPath(panelTitle)
	string panelTitle

	return $GetUserData(panelTitle, "", "DataFolderPath") + ":Data"
End

static Function/S DB_GetNotebookSubWindow(panelTitle)
	string panelTitle

	return panelTitle + "#WaveNoteDisplay"
End

static Function/S DB_GetMainGraph(panelTitle)
	string panelTitle

	return panelTitle + "#DataBrowserGraph"
End

static Function/S DB_GetLabNoteBookGraph(panelTitle)
	string panelTitle

	return panelTitle + "#Labnotebook"
End

static Function DB_LockDBPanel(panelTitle)
	string panelTitle

	string panelTitleNew, device

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	if(!CmpStr(device,NONE))
		panelTitleNew = "DataBrowser"

		if(windowExists(panelTitleNew))
			panelTitleNew = UniqueName("DataBrowser", 9, 1)
		endif

		print "Please choose a device assignment for the data browser"
		DoWindow/W=$panelTitle/C $panelTitleNew
		PopupMenu popup_labenotebookViewableCols, win=$panelTitleNew, value=#("\"" + NONE + "\"")
		return NaN
	endif

	panelTitleNew = UniqueName("DB_" + device, 9, 0)
	DoWindow/W=$panelTitle/C $panelTitleNew

	SetWindow $panelTitleNew, userdata(DataFolderPath) = GetDevicePathAsString(device)
	PopupMenu popup_labenotebookViewableCols, win=$panelTitleNew, value=#("DB_GetLabNotebookViewAbleCols(\"" + panelTitleNew + "\")")
	DB_PlotSweep(panelTitleNew, 0, 0)
End

static Function/S DB_GetListOfSweepWaves(panelTitle)
	string panelTitle

	dfref dfr = DB_GetDataPath(panelTitle)

	if(!DataFolderExistsDFR(dfr))
		return ""
	endif

	return GetListOfWaves(dfr, DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
End

static Function DB_FirstAndLastSweepAcquired(panelTitle, first, last)
	string panelTitle
	variable &first, &last

	string list

	first = 0
	last  = 0

	list = DB_GetListOfSweepWaves(panelTitle)

	if(!isEmpty(list))
		first = NumberByKey("Sweep", list, "_")
		last = ItemsInList(list) - 1 + first
	endif

	SetValDisplaySingleVariable(panelTitle, "valdisp_DataBrowser_LastSweep", last)
	SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {first, last, 1}
End

static Function DB_ClipSweepNumber(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	variable firstSweep, lastSweep

	DB_FirstAndLastSweepAcquired(panelTitle, firstSweep, lastSweep)

	// handles situation where data sweep number starts at a value greater than the controls number
	// usually occurs after locking when control is set to zero
	if(sweepNo < firstSweep)
		sweepNo = firstSweep
	elseif(sweepNo > lastSweep)
		sweepNo = lastSweep
	endif

	return sweepNo
End

static Function DB_PlotSweep(panelTitle, currentSweep, newSweep)
	string panelTitle
	variable currentSweep, newSweep

	string subWindow = DB_GetNotebookSubWindow(panelTitle)
	string graph = DB_GetMainGraph(panelTitle)

	string traceList, trace
	variable numTraces, i, sweepNo
	variable firstSweep, lastSweep
	variable newWaveDisplayed, currentWaveDisplayed

	DFREF dfr = DB_GetDataPath(panelTitle)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	newSweep = DB_ClipSweepNumber(panelTitle, newSweep)

	// With overlay enabled:
	// if the last plotted sweep is already on the graph remove it and return
	// otherwise clear the plot
	if(GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))

		WAVE/Z/SDFR=dfr newSweepWave = $("Sweep_" + num2str(newSweep))
		WAVE/Z/SDFR=dfr currentSweepWave = $("Sweep_" + num2str(currentSweep))

		newWaveDisplayed     = IsWaveDisplayedOnGraph(graph, newSweepWave)
		currentWaveDisplayed = IsWaveDisplayedOnGraph(graph, currentSweepWave)

		if(newWaveDisplayed && currentWaveDisplayed && !WaveRefsEqual(newSweepWave, currentSweepWave))
			RemoveTracesFromGraph(graph, wv=currentSweepWave)
			sweepNo = DB_ClipSweepNumber(panelTitle, newSweep)
			SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", sweepNo)
			DB_SetFormerSweepNumber(panelTitle, sweepNo)
			return NaN
		elseif(newWaveDisplayed)
			return NaN
		endif
	endif

	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", newSweep)
	Wave/Z/SDFR=dfr wv = $("Sweep_" + num2str(newSweep))

	if(!GetCheckBoxState(panelTitle, "check_DataBrowser_Overlay")) // normal plotting
		if(WaveExists(wv))
			DB_TilePlotForDataBrowser(panelTitle, wv, newSweep)
			Notebook $subWindow selection={startOfFile, endOfFile} // select entire contents of notebook
			Notebook $subWindow text = "Sweep note: \r " + note(wv) // replaces selected notebook content with new wave note.
			DB_SetFormerSweepNumber(panelTitle, newSweep)
		else
			Notebook $subWindow selection={startOfFile, endOfFile}
			Notebook $subWindow text = "Sweep does not exist."
			if(!GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
				RemoveTracesFromGraph(DB_GetMainGraph(panelTitle))
			endif			
		endif		
	else
		DEBUGPRINT("channel overlay - not yet implemented")
	endif
End

static Function DB_GetRowIndex(wv, value)
	Wave wv
	variable value

	FindValue/V=(value) wv

	if(V_Value == -1)
		return NaN
	endif

	return V_Value
End

static Function DB_TilePlotForDataBrowser(panelTitle, sweep, sweepNo)
	string panelTitle
	wave sweep
	variable sweepNo

	dfref dfr = DB_GetDataPath(panelTitle)
	if(!DataFolderExistsDFR(dfr))
		printf "Datafolder for %s does not exist\r", panelTitle
		return NaN
	endif

	Wave/SDFR=dfr config = GetConfigWave(sweep)
	string ADChannelList = GetADCListFromConfig(config)
	string DAChannelList = GetDACListFromConfig(config)
	variable NumberOfDAchannels = ItemsInList(DAChannelList)
	variable NumberOfADchannels = ItemsInList(ADChannelList)
	// the max allows for uneven number of AD and DA channels
	variable numChannels = max(NumberOfDAchannels, NumberOfADchannels)
	variable DisplayDAChan
	variable ADYaxisLow, ADYaxisHigh, ADYaxisSpacing, DAYaxisSpacing, DAYaxisLow, DAYaxisHigh, YaxisHigh, YaxisLow
	variable headstage, red, green, blue, i
	string axis, trace, adc, dac
	string configNote = note(config)
	string unit
	string graph = DB_GetMainGraph(panelTitle)

	Wave ranges = GetAxesRanges(graph)

	if(!GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
		RemoveTracesFromGraph(graph)
	endif

	DisplayDAChan = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayDAchan")
	if(DisplayDAChan)
		ADYaxisSpacing = 0.8 / numChannels
		DAYaxisSpacing = 0.2 / numChannels
	else
		ADYaxisSpacing = 1 / NumberOfADchannels
	endif

	if(DisplayDAChan)
		DAYaxisHigh = 1
		DAYaxisLow  = DAYaxisHigh - DAYaxisSpacing + GRAPH_DIV_SPACING
		ADYaxisHigh = DAYaxisLow - GRAPH_DIV_SPACING
		ADYaxisLow  = ADYaxisHigh - ADYaxisSpacing + GRAPH_DIV_SPACING
	else
		ADYaxisHigh = 1
		ADYaxisLow  = 1 - ADYaxisSpacing + GRAPH_DIV_SPACING
	endif

	Wave settingsHistory = DB_GetSettingsHistory(panelTitle)

	WAVE statusDAC = GetLastSetting(settingsHistory, sweepNo, "DAC")
	WAVE statusADC = GetLastSetting(settingsHistory, sweepNo, "ADC")

	for(i = 0; i < numChannels; i += 1)
		if(DisplayDAChan && i < NumberOfDAchannels)
			YaxisHigh = DAYaxisHigh
			YaxisLow = DAYaxisLow
			dac = StringFromList(i, DAChannelList)
			axis = "DA" + dac
			trace = axis

			AppendToGraph/W=$graph/L=$axis sweep[][i]/TN=$trace
			ModifyGraph/W=$graph axisEnab($axis) = {YaxisLow, YaxisHigh}
			unit = StringFromList(i, configNote)
			Label/W=$graph $axis, axis + "\r(" + unit + ")"
			ModifyGraph/W=$graph lblPosMode = 1
			ModifyGraph/W=$graph standoff($axis) = 0, freePos($axis) = 0

			headstage = DB_GetRowIndex(statusDAC, str2num(dac))
			if(!IsFinite(headstage))
				// use a different color to tell the user that we can't query the headstage information
				GetTraceColor(NUM_HEADSTAGES, red, green, blue)
			else
				GetTraceColor(headstage, red, green, blue)
			endif

			ModifyGraph/W=$graph rgb($trace)=(red, green, blue)
		endif

		//AD wave to plot
		YaxisHigh = ADYaxisHigh
		YaxisLow  = ADYaxisLow

		if(i < NumberOfADchannels)
			adc = StringFromList(i, ADChannelList)
			axis = "AD" + adc
			trace = axis

			AppendToGraph/W=$graph/L=$axis sweep[][i + NumberOfDAchannels]/TN=$trace
			ModifyGraph/W=$graph axisEnab($axis) = {YaxisLow, YaxisHigh}
			unit = StringFromList(i + NumberOfDAchannels, configNote)
			Label/W=$graph $axis, axis + "\r(" + unit + ")"
			ModifyGraph/W=$graph lblPosMode = 1
			ModifyGraph/W=$graph standoff($axis) = 0, freePos($axis) = 0

			headstage = DB_GetRowIndex(statusADC, str2num(adc))
			if(!IsFinite(headstage))
				// use a different color to tell the user that we can't query the headstage information
				GetTraceColor(NUM_HEADSTAGES, red, green, blue)
			else
				GetTraceColor(headstage, red, green, blue)
			endif

			ModifyGraph/W=$graph rgb($trace)=(red, green, blue)
		endif

		if(i >= NumberOfDAchannels)
			DAYaxisSpacing = 0
		endif

		if(i >= NumberOfADchannels)
			ADYaxisSpacing = 0
		endif

		if(DisplayDAChan)
			DAYAxisHigh -= ADYaxisSpacing + DAYaxisSpacing
			DAYaxisLow  -= ADYaxisSpacing + DAYaxisSpacing
		endif

		ADYAxisHigh -= ADYaxisSpacing + DAYaxisSpacing
		ADYaxisLow  -= ADYaxisSpacing + DAYaxisSpacing
	endfor

	SetAxesRanges(graph, ranges)
End

static Function/S DB_GetNextFreeAxisName(graph, axesBaseName)
	string graph, axesBaseName

	variable numAxes

	numAxes = ItemsInList(ListMatch(AxisList(graph), axesBaseName + "*"))

	return "col" + num2str(numAxes)
End

static Function DB_EvenlySpaceAxes(graph, axisBaseName)
	string graph, axisBaseName

	variable numAxes, axisInc, axisStart, axisEnd, i
	string axes, axis

	axes    = ListMatch(AxisList(graph), axisBaseName + "*")
	numAxes = ItemsInList(axes)
	axisInc = 1 / numAxes

	for(i = numAxes - 1; i >= 0; i -= 1)
		axis = StringFromList(i, axes)
		axisStart = GRAPH_DIV_SPACING + axisInc * i
		axisEnd   = (i == numAxes - 1 ? 1 : axisInc * (i + 1) - GRAPH_DIV_SPACING)
		ModifyGraph/W=$graph axisEnab($axis) = {axisStart, axisEnd}
	endfor
End

static Function DB_UpdateLegend(graph, [traceList])
	string graph, traceList

	string str
	variable numEntries, i

	if(!windowExists(graph))
		return NaN
	endif

	if(ParamIsDefault(traceList))
		TextBox/C/W=$graph/N=text0/F=0 ""
		return NaN
	endif

	str = "\\JCHeadstage\r"

	numEntries = ItemsInList(traceList)
	for(i = 0 ; i < numEntries; i += 1)
		str += "\\s(" + PossiblyQuoteName(StringFromList(i, traceList)) + ") " + num2str(i + 1)
		if(mod(i, 2))
			str += "\r"
		endif
	endfor

	str = RemoveEnding(str, "\r")
	TextBox/C/W=$graph/N=text0/F=2 str
End

static Function DB_XAxisOfTracesIsTime(graph)
	string graph

	string list, trace, dataUnits

	list = TraceNameList(graph, ";", 0 + 1)

	// default is time axis
	if(isEmpty(list))
		return 1
	endif

	trace = StringFromList(0, list)
	dataUnits = WaveUnits(XWaveRefFromTrace(graph, trace), -1)

	return !cmpstr(dataUnits, "dat")
End

static Function DB_GetKeyWaveParameterAndUnit(panelTitle, entry, parameter, unit, col)
	string panelTitle, entry
	string &parameter, &unit
	variable &col

	variable row, numRows
	string device

	parameter = ""
	unit      = ""
	col       = NaN

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	Wave/Z/T/SDFR=GetDevSpecLabNBSettKeyFolder(device) keyWave

	if(!WaveExists(keyWave))
		printf "Could not find keyWave of %s\r", panelTitle
		return 1
	endif

	FindValue/TXOP=4/TEXT=entry keyWave

	numRows = DimSize(keywave, ROWS)
	col = floor(V_value / numRows)
	row = V_value - col * numRows

	if(V_Value == -1 || row != FindDimLabel(keyWave, ROWS, "Parameter"))
		printf "Could not find %s in keyWave\r", entry
		return 1
	endif

	parameter = keyWave[%Parameter][col]
	unit      = keyWave[%Units][col]

	return 0
End

static Function DB_ClearGraph(panelTitle)
	string panelTitle

	string graph = DB_GetLabNoteBookGraph(panelTitle)
	RemoveTracesFromGraph(graph)
	DB_UpdateLegend(graph)
End

static Function/WAVE DB_GetSettingsHistory(panelTitle)
	string panelTitle

	string device

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	WAVE/SDFR=GetDevSpecLabNBSettHistFolder(device) settingsHistory

	return settingsHistory
End

/// @brief Set the appropriate label for the bottom axis
///
/// Assumes that wave data units are equal for all traces
static Function DB_SetLabNotebookBottomLabel(graph)
	string graph

	if(DB_XAxisOfTracesIsTime(graph))
		Label/W=$graph bottom LABNOTEBOOK_BOTTOM_AXIS_TIME
	else
		Label/W=$graph bottom LABNOTEBOOK_BOTTOM_AXIS_SWEEP
	endif
End

Window dataBrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(14,118,1227,838) as "DataBrowser"
	SetDrawLayer UserBack
	Button button_DataBrowser_NextSweep,pos={628,628},size={395,36},proc=DB_ButtonProc_Sweep,title="Next Sweep \\W649"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo)= A"!!,J.!!#D-!!#C*J,hnIz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_NextSweep,fSize=20
	Button button_DataBrowser_PrevSweep,pos={18,626},size={425,43},proc=DB_ButtonProc_Sweep,title="\\W646 Previous Sweep"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo)= A"!!,BI!!#D,J,hsdJ,hnez!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_PrevSweep,fSize=20
	ValDisplay valdisp_DataBrowser_LastSweep,pos={531,634},size={86,30},bodyWidth=60,title="of"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo)= A"!!,Ij^]6bDJ,hp;!!#=Sz!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataBrowser_LastSweep,fSize=24,frame=2,fStyle=1
	ValDisplay valdisp_DataBrowser_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_LastSweep,value= #"0"
	ValDisplay valdisp_DataBrowser_LastSweep,barBackColor= (56576,56576,56576)
	CheckBox check_DataBrowser_DisplayDAchan,pos={20,6},size={116,14},proc=DB_CheckProc_DADisplay,title="Display DA channels"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo)= A"!!,BY!!#:\"!!#@L!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayDAchan,value= 0
	CheckBox check_DataBrowser_Overlay,pos={429,6},size={101,14},title="Overlay Channels"
	CheckBox check_DataBrowser_Overlay,userdata(ResizeControlsInfo)= A"!!,I<J,hjM!!#@.!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_Overlay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_Overlay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_Overlay,fColor=(65280,43520,0),value= 0
	CheckBox check_DataBrowser_ChanBaseline,pos={451,22},size={87,14},title="Baseline offset"
	CheckBox check_DataBrowser_ChanBaseline,userdata(ResizeControlsInfo)= A"!!,IGJ,hm>!!#?g!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_ChanBaseline,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_ChanBaseline,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_ChanBaseline,value= 0
	TitleBox ListBox_DataBrowser_NoteDisplay,pos={1759,75},size={197,39}
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo)= A"!!,LBhuH*0!!#AT!!#>*z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox ListBox_DataBrowser_NoteDisplay,labelBack=(62208,62208,62208),fSize=8
	TitleBox ListBox_DataBrowser_NoteDisplay,frame=0
	CheckBox check_DataBrowser_SweepOverlay,pos={205,6},size={95,14},title="Overlay Sweeps"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo)= A"!!,G]!!#:\"!!#@\"!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_SweepOverlay,value= 0
	SetVariable setvar_DataBrowser_OverlaySkip,pos={223,22},size={87,30},title="Every\rsweeps"
	SetVariable setvar_DataBrowser_OverlaySkip,userdata(ResizeControlsInfo)= A"!!,Go!!#<h!!#?g!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_OverlaySkip,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataBrowser_OverlaySkip,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_OverlaySkip,limits={1,inf,1},value= _NUM:1
	CheckBox check_DataBrowser_AutoUpdate,pos={602,6},size={149,14},title="Display last sweep acquired"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo)= A"!!,J'J,hjM!!#A$!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AutoUpdate,fColor=(65280,43520,0),value= 0
	CheckBox check_DataBrowser_SweepBaseline,pos={222,53},size={87,14},title="Baseline offset"
	CheckBox check_DataBrowser_SweepBaseline,userdata(ResizeControlsInfo)= A"!!,Gn!!#>b!!#?g!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_SweepBaseline,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_SweepBaseline,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_SweepBaseline,fColor=(65280,43520,0),value= 0
	CheckBox Check_DataBrowser_StimulusWaves,pos={795,8},size={186,14},title="Display DAC or TTL stimulus waves"
	CheckBox Check_DataBrowser_StimulusWaves,userdata(ResizeControlsInfo)= A"!!,JW^]6Y#!!#AI!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataBrowser_StimulusWaves,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataBrowser_StimulusWaves,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataBrowser_StimulusWaves,fColor=(65280,43520,0),value= 0
	CheckBox check_DataBrowser_Scroll,pos={997,9},size={137,14},title="Scrolling during aquisition"
	CheckBox check_DataBrowser_Scroll,userdata(ResizeControlsInfo)= A"!!,K55QF(]!!#@m!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_Scroll,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_Scroll,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_Scroll,fColor=(65280,43520,0),value= 0
	PopupMenu popup_DB_lockedDevices,pos={639,673},size={266,21},bodyWidth=170,title="Device assingment:"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,J0^]6bN5QF0*!!#<`z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<!(TR7zzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<!(TR7zzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue="- none -",value= DB_GetAllDevicesWithData()
	Button Button_dataBrowser_lockBrowser,pos={949,673},size={70,20},proc=DB_ButtonProc_LockDBtoDevice,title="Lock"
	Button Button_dataBrowser_lockBrowser,userdata(ResizeControlsInfo)= A"!!,K)5QF2#5QF-0!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button Button_dataBrowser_lockBrowser,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button Button_dataBrowser_lockBrowser,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_DB_DispTTLChan,pos={21,30},size={122,14},title="Display TTL Channels"
	CheckBox check_DB_DispTTLChan,userdata(ResizeControlsInfo)= A"!!,Ba!!#=S!!#@X!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DB_DispTTLChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DB_DispTTLChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DB_DispTTLChan,fColor=(65280,43520,0),value= 0
	CheckBox check_DB_DispADChan,pos={21,52},size={117,14},title="Display AD Channels"
	CheckBox check_DB_DispADChan,userdata(ResizeControlsInfo)= A"!!,Ba!!#>^!!#@N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DB_DispADChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DB_DispADChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DB_DispADChan,fColor=(65280,43520,0),value= 0
	Button button_DataBrowser_setaxis,pos={20,681},size={150,23},proc=DB_ButtonProc_AutoScale,title="Autoscale"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)= A"!!,BY!!#D:5QF.e!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepNo,pos={454,634},size={74,32},proc=DB_SetVarProc_SweepNo
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo)= A"!!,II!!#D.J,hp#!!#=cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepNo,fSize=24
	SetVariable setvar_DataBrowser_SweepNo,limits={0,0,1},value= _NUM:0,live= 1
	PopupMenu popup_labenotebookViewableCols,pos={1045,455},size={150,21},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo)= A"!!,K>TE%@>J,hqP!!#<`z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_labenotebookViewableCols,mode=1,popvalue="- none -",value= #"\"- none -\""
	Button button_clearlabnotebookgraph,pos={1072,495},size={80,20},proc=DB_ButtonProc_ClearGraph,title="Clear graph"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)= A"!!,KB!!#C\\J,hp/!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	GroupBox group_labnotebook_ctrls,pos={1036,439},size={169,47},title="Settings History Column"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo)= A"!!,K=J,hskJ,hqc!!#>Jz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_switchxaxis,pos={1074,522},size={80,20},proc=DB_ButtonProc_SwitchXAxis,title="Switch X-axis"
	Button button_switchxaxis,userdata(ResizeControlsInfo)= A"!!,KB5QF1RJ,hp/!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	DefineGuide UGV0={FR,-200},UGH1={FT,0.584722,FB},UGH0={UGH1,0.662207,FB}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#ERTE%A:zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGH1;UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<n4&A^O8Q88W:-(*`0f(m]<CoSI0fhd%4%E:B6q&jl4&SL@:et\"]<(Tk\\3\\<*@0KT"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)= A":-hTC3`S[@0frH.:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(3e0fqm*8OQ!%3_!(17o`,K75?nn69A(69MeM`8Q88W:-(']2)mEO1,:o"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(9f3BK`28OQ!%3`S[@0fqm*8OQ!&3^uFt;FO8U:K'ha8P`)B0J57A1,:OB3r"
	Display/W=(18,72,1039,362)/FG=(,,UGV0,UGH1)/HOST=#
	RenameWindow #,DataBrowserGraph
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=WaveNoteDisplay /W=(1052,72,1220,341)/FG=(UGV0,,FR,UGH1) /HOST=# /OPTS=10
	Notebook kwTopWin, defaultTab=36, statusWidth=0, autoSave=1, showRuler=0, rulerUnits=1
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,127}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)ts!b+VAAccFQf<WF*6ioh3ac'6&\":'pGblu%.:d-YZK%8.G#03I^`#KnXR/m<e<!k&"
	Notebook kwTopWin, zdataEnd= 1
	RenameWindow #,WaveNoteDisplay
	SetActiveSubwindow ##
	Display/W=(17,427,1051,614)/FG=(,UGH1,UGV0,UGH0)/HOST=#
	ModifyGraph margin(right)=74
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	RenameWindow #,LabNoteBook
	SetActiveSubwindow ##
EndMacro

Function DB_DataBrowserStartupSettings()

	string allCheckBoxes, panelTitle, subWindow
	variable i, numCheckBoxes

	panelTitle = "DataBrowser"
	subWindow  = DB_GetNotebookSubWindow(panelTitle)

	if(!windowExists(panelTitle))
		print "A panel named \"DataBrowser\" does not exist"
		return NaN
	endif

	// remove tools
	HideTools/A/W=$panelTitle

	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", 0)
	SetVariable setvar_DataBrowser_SweepNo, win=$panelTitle, limits={0, 0, 1}
	SetValDisplaySingleVariable(panelTitle, "valdisp_DataBrowser_LastSweep", 0)

	RemoveTracesFromGraph(DB_GetMainGraph(panelTitle))
	RemoveTracesFromGraph(DB_GetLabNotebookGraph(panelTitle))

	Notebook $subWindow selection={startOfFile, endOfFile}
	Notebook $subWindow text = ""
	SetPopupMenuIndex(panelTitle, "popup_DB_lockedDevices", 0)
	SetSetVariable(panelTitle, "setvar_DataBrowser_OverlaySkip", 1)

	SetWindow $panelTitle, userdata(DataFolderPath) = ""
	DB_SetFormerSweepNumber(panelTitle, NaN)

	allCheckBoxes = ControlNameList(panelTitle, ";", "check*")

	numCheckBoxes = ItemsInList(allCheckBoxes)
	for(i = 0; i < numCheckBoxes; i += 1)
		SetCheckBoxState(panelTitle, StringFromList(i, allCheckBoxes), CHECKBOX_UNSELECTED)
	endfor

	DB_ClearGraph(panelTitle)
	SetPopupMenuIndex(panelTitle, "popup_labenotebookViewableCols", 0)
End

Function DB_ButtonProc_Sweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle, ctrl
	variable currentSweep, newSweep, direction
	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			panelTitle = ba.win
			ctrl       = ba.ctrlName

			currentSweep = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo")

			if(!cmpstr(ctrl, "button_DataBrowser_PrevSweep"))
				direction = -1
			elseif(!cmpstr(ctrl, "button_DataBrowser_NextSweep"))
				direction = +1
			else
				ASSERT(0, "unhandled control name")
			endif

			if(GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
				newSweep = currentSweep + direction * GetSetVariable(panelTitle, "setvar_DataBrowser_OverlaySkip")
			else
				newSweep = currentSweep + direction
			endif

			DB_PlotSweep(panelTitle, currentSweep, newSweep)
			break
	endswitch

	return 0
End

Function DB_ButtonProc_AutoScale(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle
	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			panelTitle = ba.win
			SetAxis/A/W=$DB_GetMainGraph(panelTitle)
			SetAxis/A/W=$DB_GetLabNotebookGraph(panelTitle)
			break
	endswitch

	return 0
End

Function DB_CheckProc_DADisplay(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	variable sweepNo
	string panelTitle

	switch(cba.eventCode)
		case EVENT_MOUSE_UP:
			panelTitle = cba.win

			sweepNo = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo")
			DB_PlotSweep(panelTitle, sweepNo, sweepNo)
			break
	endswitch

	return 0
End

Function DB_ButtonProc_LockDBtoDevice(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			DB_LockDBPanel(ba.win)
			break
	endswitch

	return 0
End

static StrConstant axisBaseName = "col"

Function DB_PopMenuProc_LabNotebook(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string graph, unit, lbl, axis, trace, popStr, panelTitle
	string traceList = ""
	variable sweepNo, i, numEntries, row, col
	variable red, green, blue, isTimeAxis, sweepCol

	switch(pa.eventCode)
		case 2: // mouse up
			panelTitle = pa.win
			graph      = DB_GetLabNoteBookGraph(panelTitle)
			popStr     = pa.popStr

			if(!CmpStr(popStr, NONE))
				break
			endif

			if(DB_GetKeyWaveParameterAndUnit(panelTitle, popStr, lbl, unit, col))
				break
			endif

			lbl = LineBreakingIntoParWithMinWidth(lbl)

			Wave settingsHistory = DB_GetSettingsHistory(panelTitle)
			WAVE settingsHistoryDat = GetSettingsHistoryDateTime(settingsHistory)
			isTimeAxis = DB_XAxisOfTracesIsTime(graph)
			sweepCol   = GetSweepColumn(settingsHistory)

			axis = DB_GetNextFreeAxisName(graph, axisBaseName)

			numEntries = DimSize(settingsHistory, LAYERS)
			for(i = 0; i < numEntries; i += 1)

				trace = CleanupName(lbl + " (" + num2str(i + 1) + ")", 1) // +1 because the headstage number is 1-based
				traceList = AddListItem(trace, traceList, ";", inf)

				if(isTimeAxis)
					AppendToGraph/W=$graph/L=$axis settingsHistory[][col][i]/TN=$trace vs settingsHistoryDat
				else
					AppendToGraph/W=$graph/L=$axis settingsHistory[][col][i]/TN=$trace vs settingsHistory[][sweepCol][0]
				endif

				GetTraceColor(i, red, green, blue)
				ModifyGraph/W=$graph rgb($trace)=(red, green, blue)
			endfor

			if(!isEmpty(unit))
				lbl += "\r(" + unit + ")"
			endif

			Label/W=$graph $axis lbl

			ModifyGraph/W=$graph lblPosMode = 1, standoff($axis) = 0, freePos($axis) = 0
			ModifyGraph/W=$graph mode = 3
			ModifyGraph/W=$graph nticks(bottom) = 10

			DB_SetLabNotebookBottomLabel(graph)
			DB_EvenlySpaceAxes(graph, axisBaseName)
			DB_UpdateLegend(graph, traceList=traceList)
		break
	endswitch

	return 0
End

static StrConstant LABNOTEBOOK_BOTTOM_AXIS_TIME  = "Timestamp (a. u.)"
static StrConstant LABNOTEBOOK_BOTTOM_AXIS_SWEEP = "Sweep Number (a. u.)"

static Function DB_SetFormerSweepNumber(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	SetControlUserData(panelTitle, "setvar_DataBrowser_SweepNo", LAST_SWEEP_USER_DATA, num2str(sweepNo))
End

static Function DB_GetFormerSweepNumber(panelTitle)
	string panelTitle

	return str2num(GetUserData(panelTitle, "setvar_DataBrowser_SweepNo", LAST_SWEEP_USER_DATA))
End

Function DB_SetVarProc_SweepNo(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string panelTitle
	variable firstSweep, lastSweep, formerSweep, sweepNo

	switch(sva.eventCode)
		case 1: // mouse up - when the scroll wheel is used on the mouse - "up or down"
		case 2: // Enter key - when a number is manually entered
		case 3: // Live update - happens when you hit the arrow keys associated with the set variable
			sweepNo = sva.dval
			paneltitle = sva.win

			DB_FirstAndLastSweepAcquired(panelTitle, firstSweep, lastSweep)

			if(GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
				formerSweep = DB_GetFormerSweepNumber(panelTitle)

				if(sweepNo > formerSweep)
					SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {sweepNo, lastSweep , 1}
					ControlUpdate/W=$panelTitle setvar_DataBrowser_SweepNo
				elseif(sweepNo < formerSweep)
					SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {firstSweep, sweepNo , 1}
				endif
			else
				SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {firstSweep, lastSweep , 1}
			endif

			DB_PlotSweep(panelTitle, formerSweep, sweepNo )
			break
	endswitch

	return 0
End

Function DB_ButtonProc_ClearGraph(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			DB_ClearGraph(ba.win)
			break
	endswitch

	return 0
End

Function/S DB_GetLabNotebookViewAbleCols(panelTitle)
	string panelTitle

	string device, list = NONE
	variable numCols, i

	if(!windowExists(panelTitle))
		return list
	endif

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	if(!CmpStr(device, NONE))
		return list
	endif

	Wave/T/Z/SDFR=GetDevSpecLabNBSettKeyFolder(device) keyWave

	if(!WaveExists(keyWave))
		return list
	endif

	numCols = DimSize(keyWave, COLS)
	// 2 is the first column in keyWave with data we want to plot
	for(i = 2; i < numCols; i += 1)
		list = AddListItem(keyWave[%Parameter][i], list, ";", inf)
	endfor

	return SortList(list)
End

Function/S DB_GetAllDevicesWithData()

	return AddListItem(NONE, GetAllDevicesWithData(), ";", 0)
End

Function DB_ButtonProc_SwitchXAxis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle, graph, trace, dataUnits, list
	variable i, numEntries, isTimeAxis, sweepCol

	switch(ba.eventCode)
		case 2: // mouse up
			panelTitle = ba.win
			graph      = DB_GetLabNoteBookGraph(panelTitle)

			list = TraceNameList(graph, ";", 0 + 1)

			if(isEmpty(list))
				break
			endif

			WAVE settingsHistory = DB_GetSettingsHistory(panelTitle)
			isTimeAxis = DB_XAxisOfTracesIsTime(graph)
			sweepCol   = GetSweepColumn(settingsHistory)

			numEntries = ItemsInList(list)
			for(i = 0; i < numEntries; i += 1)
				trace = StringFromList(i, list)

				// change from timestamps to sweepNums
				if(isTimeAxis)
					ReplaceWave/W=$graph/X trace=$trace, settingsHistory[][sweepCol][0]
				else // other direction
					Wave xWave = GetSettingsHistoryDateTime(settingsHistory)
					ReplaceWave/W=$graph/X trace=$trace, xWave
				endif
			endfor

			DB_SetLabNotebookBottomLabel(graph)

			// autoscale all axis after a switch
			list = AxisList(graph)

			numEntries = ItemsInList(list)
			for(i = 0; i < numEntries; i += 1)
				SetAxis/W=$graph/A $StringFromList(i, list)
			endfor

			break
	endswitch

	return 0
End
