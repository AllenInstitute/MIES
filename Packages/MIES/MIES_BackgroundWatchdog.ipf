#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IndependentModule=BkgWatcher

/// @file MIES_BackgroundWatchdog.ipf
/// @brief __BW__ Panel for inspecting the state of the MIES DAQ/TP background functions

/// @cond DOXYGEN_IGNORES_THIS

// stock igor
#include <Readback ModifyStr>

#include ":ACL_TabUtilities"

#include ":MIES_Constants"
#include ":MIES_Debugging"
#include ":MIES_GuiUtilities"
#include ":MIES_Structures"
#include ":MIES_Utilities"
/// @endcond

static StrConstant PANEL            = "BW_MiesBackgroundWatchPanel"
static StrConstant TASK             = "BW_BackgroundWatchdog"
static StrConstant CONTROL_PREFIX   = "bckrdw"
static Constant    INVALIDATE_STATE = -1
static Constant    NUM_TASKS = 15
static Constant    XGRID = 20
static Constant    XOFFS = 240
static Constant    YGRID = 20

Window BW_MiesBackgroundWatchPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(400,264,900,600) as "MIES Background Watcher Panel"
	String base, s
	variable xoffs = 240
	variable xgrid = 20
	variable ygrid = 20
	variable ypos
	variable i
	do
		ypos = 2 * ygrid + i * ygrid
		base = "bckrdw" + num2str(i)
		s = base + "_PERIOD"
		ValDisplay $s,pos={3 * xgrid + xoffs, ypos},size={50.00,YGRID},title="Period"
		ValDisplay $s,value= #"0"
		s = base + "_NEXT"
		ValDisplay $s,pos={6 * xgrid + xoffs, ypos},size={60.00,YGRID},title="Next"
		ValDisplay $s,value= #"0"
		i += 1
	while(i < 15)
	Button button_start_bkg,pos={76.00,13.00},size={50.00,20.00},proc=BkgWatcher#BW_ButtonProc_StartTask,title="Start"
	Button button_start_bkg,help={"Start the background task for updating the traffic light style controls"}
	Button button_stop_bkg_task,pos={150.00,13.00},size={50.00,20.00},proc=BkgWatcher#BW_ButtonProc_StopTask,title="Stop"
	Button button_stop_bkg_task,help={"Stop the background task"}
	SetWindow kwTopWin,hook(mainHook)=BkgWatcher#BW_WindowHook
	ModifyPanel fixedSize=1
EndMacro

Function BW_StartPanel()

	DoWindow/F $PANEL
	if(V_Flag)
		return NaN
	endif

	Execute PANEL + "()"
	BW_StartTask()
End

Function BW_StartTask()
	CtrlNamedBackground $TASK, period=30, proc=$(GetIndependentModuleName() + "#BW_BackgroundWatchdog"), start
End

Function BW_StopTask()
	CtrlNamedBackground $TASK, stop
	BW_PanelUpdate()
End

Function BW_PanelUpdate()
	String taskinfo, ctrl, base
	CtrlNamedBackground _all_, status
	variable state, ypos
	variable colr, colg, colb
	variable tasks = min(ItemsInList(S_Info, "\r"), NUM_TASKS)
	variable i
	for(i = 0; i < tasks; i += 1)
		ypos = (2 + i) * YGRID
		taskinfo = StringFromList(i, S_Info, "\r")
		base = CONTROL_PREFIX + num2str(i)

		if(str2num(StringByKey("RUN", taskinfo)))
			colr = 0
			colg = 65535
			colb = 0
		else
			colr = 65535
			colg = 0
			colb = 0
		endif
		ctrl = base + "_NAME"
		TitleBox $ctrl win=$PANEL ,pos={0, ypos}, fixedsize=1, size={120, YGRID}, labelBack=(colr, colg, colb), title=StringByKey("NAME", taskinfo)
		ctrl = base + "_PROCESS"
		Button $ctrl win=$PANEL ,pos={120, ypos}, size={180, YGRID}, fColor=(colr, colg, colb), title=StringByKey("PROC", taskinfo), proc=BW_ButtonProc_ShowTask
		state = str2num(StringByKey("PERIOD", taskinfo))
		ctrl = base + "_PERIOD"
		SetValDisplay(PANEL, ctrl, var=state)
		state = str2num(StringByKey("NEXT", taskinfo))
		ctrl = base + "_NEXT"
		SetValDisplay(PANEL, ctrl, var=state)

		if(str2num(StringByKey("QUIT", taskinfo)))
			colr = 0
			colg = 65535
			colb = 0
		else
			colr = 65535
			colg = 0
			colb = 0
		endif
		ctrl = base + "_QUIT"
		Button $ctrl win=$PANEL ,pos={9 * XGRID + XOFFS, ypos}, size={40, YGRID}, fColor=(colr, colg, colb), title="QUIT", proc=BW_ButtonProc_QuitTask

		if(str2num(StringByKey("FUNCERR", taskinfo)))
			colr = 65535
			colg = 0
			colb = 0
		else
			colr = 32000
			colg = 32000
			colb = 32000
		endif
		ctrl = base + "_ERROR"
		TitleBox $ctrl win=$PANEL ,pos={11 * XGRID + XOFFS, ypos}, size={40, YGRID}, labelBack=(colr, colg, colb), title="ERROR"
	endfor
End

/// @brief Helper background task for debugging
///
/// @ingroup BackgroundFunctions
Function BW_BackgroundWatchdog(s)
	STRUCT WMBackgroundStruct &s

	// stop background task if the panel was killed
	DoWindow $PANEL
	if(!V_flag)
		return 1
	endif

	BW_PanelUpdate()
	return 0
End

Function BW_ButtonProc_ShowTask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			variable num
			String numstr
			numstr = ba.ctrlName
			numstr = numstr[strlen(CONTROL_PREFIX), Inf]
			numstr = numstr[0, strsearch(numstr, "_", 0) - 1]
			num=str2num(numstr)
			String taskinfo, taskname
			CtrlNamedBackground _all_, status
			taskinfo = StringFromList(num, S_Info, "\r")
			taskname = StringByKey("PROC", taskinfo)
			if(strsearch(taskinfo, "#", 0) < 0)
				taskname = "ProcGlobal#" + taskname
			endif
			DisplayProcedure taskname
			break
	endswitch

	return 0
End

Function BW_ButtonProc_QuitTask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			variable num
			String numstr
			numstr = ba.ctrlName
			numstr = numstr[strlen(CONTROL_PREFIX), Inf]
			numstr = numstr[0, strsearch(numstr, "_", 0) - 1]
			num=str2num(numstr)
			String taskinfo, taskname
			CtrlNamedBackground _all_, status
			taskinfo = StringFromList(num, S_Info, "\r")
			taskname = StringByKey("NAME", taskinfo)
			CtrlNamedBackground $taskname, stop
			BW_PanelUpdate()
			break
	endswitch

	return 0
End

Function BW_WindowHook(s)
	STRUCT WMWinHookStruct &s

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
	endswitch

	return hookResult
End

Function BW_ButtonProc_StartTask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			BW_StartTask()
			// click code here
			break
	endswitch

	return 0
End

Function BW_ButtonProc_StopTask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			BW_StopTask()
			break
	endswitch

	return 0
End
