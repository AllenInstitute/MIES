#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IndependentModule=BkgWatcher

/// @file MIES_BackgroundWatchdog.ipf
/// @brief __BW__ Panel for inspecting the state of the MIES DAQ/TP background functions

static StrConstant PANEL            = "BW_MiesBackgroundWatchPanel"
static StrConstant TASK             = "BW_BackgroundWatchdog"
static StrConstant CONTROL_PREFIX   = "bckrdw"
static Constant    INVALIDATE_STATE = -1
static Constant    XGRID            = 20
static Constant    XOFFS            = 240
static Constant    YGRID            = 20

static Constant CONTROL_TYPE_VALDISPLAY = 4

static Function ASSERT(variable var, string errorMsg)

	string stracktrace, miesVersionStr, lockedDevicesStr, device
	string stacktrace = ""
	variable i, numLockedDevices

	try
		AbortOnValue var == 0, 1
	catch
		Abort
	endtry
End

static Function SetValDisplay(string win, string control, [variable var, string str, string format])

	string formattedString

	if(!ParamIsDefault(format))
		ASSERT(ParamIsDefault(str), "Unexpected parameter combination")
		ASSERT(!ParamIsDefault(var), "Unexpected parameter combination")
		sprintf formattedString, format, var
	elseif(!ParamIsDefault(var))
		ASSERT(ParamIsDefault(str), "Unexpected parameter combination")
		ASSERT(ParamIsDefault(format), "Unexpected parameter combination")
		sprintf formattedString, "%g", var
	elseif(!ParamIsDefault(str))
		ASSERT(ParamIsDefault(var), "Unexpected parameter combination")
		ASSERT(ParamIsDefault(format), "Unexpected parameter combination")
		formattedString = str
	else
		ASSERT(0, "Unexpected parameter combination")
	endif

	// Don't update if the content does not change, prevents flickering
	if(CmpStr(GetValDisplayAsString(win, control), formattedString) == 0)
		return NaN
	endif

	ValDisplay $control, win=$win, value=#formattedString
End

static Function/S GetValDisplayAsString(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_VALDISPLAY, "Control is not a val display")
	return S_value
End

static Function IsBackgroundTaskRunning(string task)

	CtrlNamedBackground $task, status
	return NumberByKey("RUN", s_info)
End

Function BW_StartPanel()

	DoWindow/F $PANEL
	if(V_Flag)
		return NaN
	endif

	BW_CreatePanel()
	BW_StartTask()
	Execute/P/Q "SetIgorOption IndependentModuleDev=1"
End

Function BW_CreatePanel()

	NewPanel/K=1/N=$PANEL/W=(400, 264, 0, 0) as "MIES Background Watcher Panel"
	SetWindow kwTopWin, hook(mainHook)=BkgWatcher#BW_WindowHook
	ModifyPanel fixedSize=1
End

Function BW_StartTask()

	CtrlNamedBackground $TASK, period=30, proc=$(GetIndependentModuleName() + "#BW_BackgroundWatchdog"), start
	Button button_startstop_bkg, pos={0, 0}, size={14 * XGRID + XOFFS, YGRID}, proc=BkgWatcher#BW_ButtonProc_StopTask, title="Stop"
	Button button_startstop_bkg, help={"Start/Stop the background task for updating the traffic light style controls"}
End

Function BW_StopTask()

	CtrlNamedBackground $TASK, stop
	BW_PanelUpdate()
	Button button_startstop_bkg, proc=BkgWatcher#BW_ButtonProc_StartTask, title="Start (currently stopped)"
End

Function BW_PanelUpdate()

	string taskinfo, ctrl, base, title, helpstr
	variable tasks, state, ypos, i, runstate, colr, colg, colb, basecol

	basecol = 65535
	CtrlNamedBackground _all_, status
	tasks = ItemsInList(S_Info, "\r")
	for(i = 0; i < tasks; i += 1)
		ypos     = (1 + i) * YGRID
		taskinfo = StringFromList(i, S_Info, "\r")
		base     = CONTROL_PREFIX + num2str(i)

		runstate = NumberByKey("RUN", taskinfo)
		if(runstate)
			colr = 0
			colg = basecol
			colb = 0
		else
			colr = basecol
			colg = basecol * 0.4
			colb = basecol * 0.4
		endif
		ctrl = base + "_NAME"
		TitleBox $ctrl, win=$PANEL, pos={0, ypos}, anchor=lc, fixedsize=1, size={6 * XGRID, YGRID}, labelBack=(colr, colg, colb), title=StringByKey("NAME", taskinfo), help={"name of task\rgreen - currently running\rred - stopped"}
		ctrl = base + "_PROCESS"
		Button $ctrl, win=$PANEL, pos={6 * XGRID, ypos}, size={9 * XGRID, YGRID}, fColor=(colr, colg, colb), title=StringByKey("PROC", taskinfo), proc=BW_ButtonProc_ShowTask, help={"function of task\rpress to open code"}

		state = NumberByKey("PERIOD", taskinfo)
		ctrl  = base + "_PERIOD"
		ValDisplay $ctrl, win=$PANEL, format="%1d", pos={3 * xgrid + xoffs, ypos}, size={2.5 * XGRID, YGRID}, title="Period", value=#"0", help={"task is executed every period ticks"}

		SetValDisplay(PANEL, ctrl, var = state)
		state = NumberByKey("NEXT", taskinfo)
		ctrl  = base + "_NEXT"
		if(runstate)
			title   = "Next in"
			state  -= ticks
			colr    = basecol
			colg    = basecol
			colb    = basecol
			helpstr = "task is executed in <> ticks"
		else
			title   = "Last run"
			colr    = basecol * 0.9
			colg    = basecol * 0.9
			colb    = basecol
			helpstr = "task was last run at <> ticks"
		endif
		ValDisplay $ctrl, win=$PANEL, format="%1d", pos={6 * xgrid + xoffs, ypos}, size={3.5 * XGRID, YGRID}, valueBackColor=(colr, colg, colb), title=title, value=#"0", help={helpstr}
		SetValDisplay(PANEL, ctrl, var = state)

		if(NumberByKey("QUIT", taskinfo))
			colr = basecol
			colg = 0
			colb = 0
		else
			colr = basecol * 0.7
			colg = basecol * 0.7
			colb = basecol * 0.7
		endif
		ctrl = base + "_QUIT"
		Button $ctrl, win=$PANEL, pos={10 * XGRID + XOFFS, ypos}, size={2 * XGRID, YGRID}, fColor=(colr, colg, colb), title="QUIT", proc=BW_ButtonProc_QuitTask, help={"red - task returned nonzero value\rgrey - task returned zero (OK)"}

		if(NumberByKey("FUNCERR", taskinfo))
			colr = basecol
			colg = basecol * 0.4
			colb = basecol * 0.4
		else
			colr = basecol * 0.7
			colg = basecol * 0.7
			colb = basecol * 0.7
		endif
		ctrl = base + "_ERROR"
		TitleBox $ctrl, win=$PANEL, anchor=mc, fixedsize=1, pos={12 * XGRID + XOFFS, ypos}, size={2 * XGRID, YGRID}, labelBack=(colr, colg, colb), title="ERROR", help={"red - task function was not or could not be executed\rgrey - task function could be executed"}
	endfor
	GetWindow $PANEL, wsize
	MoveWindow/W=$PANEL V_Left, V_Top, V_Left + 14 * XGRID + XOFFS, V_Top + ypos + YGRID
End

/// @brief Helper background task for debugging
///
/// @ingroup BackgroundFunctions
Function BW_BackgroundWatchdog(STRUCT WMBackgroundStruct &s)

	// stop background task if the panel was killed
	DoWindow $PANEL
	if(!V_flag)
		return 1
	endif

	BW_PanelUpdate()
	return 0
End

Function BW_ButtonProc_ShowTask(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			variable num
			string numstr, taskinfo, taskname
			numstr = ba.ctrlName
			numstr = numstr[strlen(CONTROL_PREFIX), Inf]
			numstr = numstr[0, strsearch(numstr, "_", 0) - 1]
			num    = str2num(numstr)
			CtrlNamedBackground _all_, status
			taskinfo = StringFromList(num, S_Info, "\r")
			taskname = StringByKey("PROC", taskinfo)
			if(strsearch(taskinfo, "#", 0) < 0)
				taskname = "ProcGlobal#" + taskname
			endif
			DisplayProcedure taskname
			break
		default:
			break
	endswitch

	return 0
End

Function BW_ButtonProc_QuitTask(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			variable num
			string numstr, taskinfo, taskname
			numstr = ba.ctrlName
			numstr = numstr[strlen(CONTROL_PREFIX), Inf]
			numstr = numstr[0, strsearch(numstr, "_", 0) - 1]
			num    = str2num(numstr)
			CtrlNamedBackground _all_, status
			taskinfo = StringFromList(num, S_Info, "\r")
			taskname = StringByKey("NAME", taskinfo)
			CtrlNamedBackground $taskname, stop
			BW_PanelUpdate()
			break
		default:
			break
	endswitch

	return 0
End

Function BW_WindowHook(STRUCT WMWinHookStruct &s)

	variable hookResult

	switch(s.eventCode)
		case 0: // activate
			if(!IsBackgroundTaskRunning(TASK))
				BW_PanelUpdate()
			endif
			break
		case 2: // kill
			BW_StopTask()
			hookResult = 1
			break
		default:
			break
	endswitch

	return hookResult
End

Function BW_ButtonProc_StartTask(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			BW_StartTask()
			break
		default:
			break
	endswitch

	return 0
End

Function BW_ButtonProc_StopTask(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			BW_StopTask()
			break
		default:
			break
	endswitch

	return 0
End
