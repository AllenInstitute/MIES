#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IndependentModule=BkgWatcher

/// @file MIES_BackgroundWatchdog.ipf
/// @brief __BW__ Panel for inspecting the state of the MIES DAQ/TP background functions

/// @cond DOXYGEN_IGNORES_THIS
#include ":ACL_TabUtilities"

#include ":MIES_Constants"
#include ":MIES_Debugging"
#include ":MIES_GuiUtilities"
#include ":MIES_Structures"
#include ":MIES_Utilities"
/// @endcond

static StrConstant PANEL            = "BW_MiesBackgroundWatchPanel"
static StrConstant TASK             = "BW_BackgroundWatchdog"
static StrConstant CONTROL_PREFIX   = "valdisp_"
static Constant    INVALIDATE_STATE = -1

Window BW_MiesBackgroundWatchPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(452,264,718,446) as "MIES Background Watcher Panel"
	ValDisplay valdisp_TestPulseMD,pos={46.00,45.00},size={93.00,20.00},bodyWidth=20,title="TestPulseMD"
	ValDisplay valdisp_TestPulseMD,help={"Green = task is running, Red = task is not running, black = background watcher is not running"}
	ValDisplay valdisp_TestPulseMD,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (2,39321,1),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay valdisp_TestPulseMD,value= #"0"
	ValDisplay valdisp_TestPulse,pos={185.00,43.00},size={74.00,20.00},bodyWidth=20,title="TestPulse"
	ValDisplay valdisp_TestPulse,help={"Green = task is running, Red = task is not running, black = background watcher is not running"}
	ValDisplay valdisp_TestPulse,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (2,39321,1),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay valdisp_TestPulse,value= #"0"
	ValDisplay valdisp_ITC_FIFOMonitorMD,pos={6.00,102.00},size={133.00,20.00},bodyWidth=20,title="ITC_FIFOMonitorMD"
	ValDisplay valdisp_ITC_FIFOMonitorMD,help={"Green = task is running, Red = task is not running, black = background watcher is not running"}
	ValDisplay valdisp_ITC_FIFOMonitorMD,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (2,39321,1),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay valdisp_ITC_FIFOMonitorMD,value= #"0"
	ValDisplay valdisp_ITC_TimerMD,pos={42.00,74.00},size={97.00,20.00},bodyWidth=20,title="ITC_TimerMD"
	ValDisplay valdisp_ITC_TimerMD,help={"Green = task is running, Red = task is not running, black = background watcher is not running"}
	ValDisplay valdisp_ITC_TimerMD,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (2,39321,1),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay valdisp_ITC_TimerMD,value= #"0"
	ValDisplay valdisp_ITC_Timer,pos={181.00,73.00},size={78.00,20.00},bodyWidth=20,title="ITC_Timer"
	ValDisplay valdisp_ITC_Timer,help={"Green = task is running, Red = task is not running, black = background watcher is not running"}
	ValDisplay valdisp_ITC_Timer,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (2,39321,1),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay valdisp_ITC_Timer,value= #"0"
	ValDisplay valdisp_ITC_FIFOMonitor,pos={145.00,103.00},size={114.00,20.00},bodyWidth=20,title="ITC_FIFOMonitor"
	ValDisplay valdisp_ITC_FIFOMonitor,help={"Green = task is running, Red = task is not running, black = background watcher is not running"}
	ValDisplay valdisp_ITC_FIFOMonitor,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (2,39321,1),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay valdisp_ITC_FIFOMonitor,value= #"0"
	Button button_start_bkg,pos={76.00,13.00},size={50.00,20.00},proc=BkgWatcher#BW_ButtonProc_StartTask,title="Start"
	Button button_start_bkg,help={"Start the background task for updating the traffic light style controls"}
	Button button_stop_bkg_task,pos={150.00,13.00},size={50.00,20.00},proc=BkgWatcher#BW_ButtonProc_StopTask,title="Stop"
	Button button_stop_bkg_task,help={"Stop the background task"}
	ValDisplay valdisp_P_NI_FIFOMonitor,pos={85.00,131.00},size={120.00,20.00},bodyWidth=20,title="P_NI_FIFOMonitor"
	ValDisplay valdisp_P_NI_FIFOMonitor,help={"Green = task is running, Red = task is not running, black = background watcher is not running"}
	ValDisplay valdisp_P_NI_FIFOMonitor,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (2,39321,1),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay valdisp_P_NI_FIFOMonitor,value= #"0"
	ValDisplay valdisp_P_ITC_FIFOMonitor,pos={80.00,157.00},size={126.00,20.00},bodyWidth=20,title="P_ITC_FIFOMonitor"
	ValDisplay valdisp_P_ITC_FIFOMonitor,help={"Green = task is running, Red = task is not running, black = background watcher is not running"}
	ValDisplay valdisp_P_ITC_FIFOMonitor,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (2,39321,1),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay valdisp_P_ITC_FIFOMonitor,value= #"0"
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
	BW_InvalidateValDisplays()
End

Function BW_InvalidateValDisplays()

	string list, ctrl
	variable numControls, i

	list = ControlNameList(PANEL, ";", CONTROL_PREFIX + "*")
	numControls = ItemsInList(list)

	for(i = 0; i < numControls; i += 1)
		ctrl = StringFromList(i, list)
		SetValDisplay(PANEL, ctrl, var=INVALIDATE_STATE)
	endfor
End

Function BW_BackgroundWatchdog(s)
	STRUCT WMBackgroundStruct &s

	variable i, state, numControls
	string list, ctrl, bkg

	// stop background task if the panel was killed
	DoWindow $PANEL
	if(!V_flag)
		return 1
	endif

	list = ControlNameList(PANEL, ";", CONTROL_PREFIX + "*")
	numControls = ItemsInList(list)

	// should not happen
	if(numControls == 0)
		return 1
	endif

	for(i = 0; i < numControls; i += 1)
		ctrl = StringFromList(i, list)
		bkg  = ctrl[strlen(CONTROL_PREFIX), Inf]

		state = IsBackgroundTaskRunning(bkg)
		SetValDisplay(PANEL, ctrl, var=state)
	endfor

	return 0
End

Function BW_WindowHook(s)
	STRUCT WMWinHookStruct &s

	variable hookResult

	switch(s.eventCode)
		case 0: // activate
			if(!IsBackgroundTaskRunning(TASK))
				BW_InvalidateValDisplays()
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
