#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SBEM
#endif // AUTOMATED_TESTING

Window ExportSettingsPanel() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(367, 800, 605, 1282) as "Export settings"
	SetVariable setvar_sweep_export_datafolder, pos={18.00, 303.00}, size={199.00, 18.00}, bodyWidth=140, title="Datafolder"
	SetVariable setvar_sweep_export_datafolder, value=_STR:"myFolder"
	SetVariable setvar_sweep_export_x_range_beg, pos={18.00, 109.00}, size={170.00, 18.00}, bodyWidth=50, title="Manual X range begin"
	SetVariable setvar_sweep_export_x_range_beg, value=_NUM:NaN
	SetVariable setvar_sweep_export_x_range_end, pos={18.00, 132.00}, size={160.00, 18.00}, bodyWidth=50, title="Manual X range end"
	SetVariable setvar_sweep_export_x_range_end, value=_NUM:NaN
	CheckBox checkbox_sweep_export_cursor, pos={18.00, 85.00}, size={160.00, 15.00}, title="Duplicate only cursor range"
	CheckBox checkbox_sweep_export_cursor, value=0, side=1
	CheckBox checkbox_sweep_export_resetOff, pos={18.00, 62.00}, size={197.00, 15.00}, title="Reset the wave's dim offset to zero"
	CheckBox checkbox_sweep_export_resetOff, value=0, side=1
	PopupMenu popup_sweep_export_graph, pos={18.00, 276.00}, size={192.00, 19.00}, bodyWidth=120, proc=SBE_PopMenu_ExportTargetGraph, title="Target Graph"
	PopupMenu popup_sweep_export_graph, mode=1, popvalue="New", value=#"SBE_ListOfGraphsAndNew()"
	PopupMenu popup_sweep_export_x_axis, pos={43.00, 329.00}, size={154.00, 19.00}, bodyWidth=120, proc=SBE_PopMenu_ExportTargetAxis, title="X Axis"
	PopupMenu popup_sweep_export_x_axis, mode=1, popvalue="New", value=#"SBE_GetSelectedAxis(\"popup_sweep_export_graph\", 1)"
	PopupMenu popup_sweep_export_y_axis, pos={43.00, 380.00}, size={154.00, 19.00}, bodyWidth=120, proc=SBE_PopMenu_ExportTargetAxis, title="Y Axis"
	PopupMenu popup_sweep_export_y_axis, mode=1, popvalue="New", value=#"SBE_GetSelectedAxis(\"popup_sweep_export_graph\", 2)"
	Button button_sweep_export_doIt, pos={79.00, 454.00}, size={81.00, 23.00}, proc=SBE_ButtonProc_PerformExport, title="Do It"
	GroupBox group_sweep_export_input, pos={10.00, 8.00}, size={217.00, 40.00}
	PopupMenu popup_sweep_export_source_graph, pos={14.00, 16.00}, size={194.00, 19.00}, bodyWidth=120, title="Source Graph"
	PopupMenu popup_sweep_export_source_graph, mode=1, popvalue="SweepBrowser1", value=#"SBE_ListOfSweepGraphs()"
	GroupBox group_sweep_export_input1, pos={12.00, 54.00}, size={214.00, 397.00}
	SetVariable setvar_sweep_export_new_x_name, pos={16.00, 352.00}, size={200.00, 18.00}, bodyWidth=140, title="New X axis"
	SetVariable setvar_sweep_export_new_x_name, value=_STR:"bottom"
	SetVariable setvar_sweep_export_new_y_name, pos={17.00, 403.00}, size={200.00, 18.00}, bodyWidth=140, title="New Y axis"
	SetVariable setvar_sweep_export_new_y_name, value=_STR:"left"
	CheckBox checkbox_sweep_export_equalY, pos={21.00, 427.00}, size={54.00, 15.00}, title="Equal Y"
	CheckBox checkbox_sweep_export_equalY, help={"Set the y ranges of all vertical axes to the maximum per clamp mode"}
	CheckBox checkbox_sweep_export_equalY, value=1, side=1
	CheckBox checkbox_sweep_export_redistAx, pos={85.00, 427.00}, size={105.00, 15.00}, title="Redistribute Axes"
	CheckBox checkbox_sweep_export_redistAx, help={"Redistribute the axes in the target graph so that no axes overlap. Needs to be off for dDAQ view mode."}
	CheckBox checkbox_sweep_export_redistAx, value=1, side=1
	GroupBox group_pulse_settings, pos={20.00, 155.00}, size={197.00, 118.00}
	CheckBox checkbox_sweep_export_pulse_set, pos={26.00, 162.00}, size={181.00, 15.00}, proc=SBE_CheckProc_UsePulseForXRange, title="Use pulses for X range selection"
	CheckBox checkbox_sweep_export_pulse_set, value=0, side=1
	PopupMenu popup_sweep_export_pulse_AD, pos={28.00, 181.00}, size={69.00, 19.00}, bodyWidth=50, disable=2, proc=SBE_PopMenuProc_PulsesADTrace, title="AD"
	PopupMenu popup_sweep_export_pulse_AD, mode=1, popvalue="0", value="0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15"
	SetVariable setvar_sweep_export_num_pulses, pos={28.00, 205.00}, size={148.00, 18.00}, bodyWidth=50, disable=2, title="Number of pulses"
	SetVariable setvar_sweep_export_num_pulses, limits={0, 12, 1}, value=_NUM:1
	SetVariable setvar_sweep_export_pulse_pre, pos={28.00, 227.00}, size={172.00, 18.00}, bodyWidth=50, disable=2, title="Time before first pulse"
	SetVariable setvar_sweep_export_pulse_pre, value=_NUM:0, help={"Positive values increase the x range, negative values decrease it."}
	SetVariable setvar_sweep_export_pulse_post, pos={28.00, 250.00}, size={160.00, 18.00}, bodyWidth=50, disable=2, title="Time after last pulse"
	SetVariable setvar_sweep_export_pulse_post, value=_NUM:0, help={"Positive values increase the x range, negative values decrease it."}
EndMacro
