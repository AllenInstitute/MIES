#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_PSXM
#endif // AUTOMATED_TESTING

Window PSXPanel() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(27, 1010, 1281, 1490) as "SweepFormula plot from <Browser >"
	SetDrawLayer UserBack
	SetDrawEnv pop
	DrawText 47, 475, "UI"
	SetDrawEnv fname="Lucida Console"
	SetDrawEnv push
	Button button_load, pos={17.00, 46.00}, size={50.00, 20.00}, proc=PSX_ButtonProc_LoadEvents
	Button button_load, title="Load"
	Button button_load, help={"Load the event data from the results wave and redo SweepFormula evaluation\rto update possible psxStats plots."}
	Button button_load, userdata(ResizeControlsInfo)=A"!!,BA!!#>F!!#>V!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_store, pos={17.00, 16.00}, size={50.00, 20.00}, proc=PSX_ButtonProc_StoreEvents
	Button button_store, title="Store"
	Button button_store, help={"Store the event data in the results wave."}
	Button button_store, userdata(ResizeControlsInfo)=A"!!,BA!!#<8!!#>V!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_store, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_store, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_jump_first_undet, pos={74.00, 32.00}, size={50.00, 20.00}, proc=PSX_ButtonProcJumpFirstUndet
	Button button_jump_first_undet, title="Jump"
	Button button_jump_first_undet, help={"Jump to the first event with undetermined state"}
	Button button_jump_first_undet, userdata(ResizeControlsInfo)=A"!!,EN!!#=c!!#>V!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_jump_first_undet, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_jump_first_undet, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_show_deconv_lines, pos={20.00, 73.00}, size={115.00, 15.00}, proc=PSX_UpdateVisualizationHelpers
	CheckBox checkbox_show_deconv_lines, title="Show Deconv lines"
	CheckBox checkbox_show_deconv_lines, help={"Show the x position of the peak in the deconvolution wave"}
	CheckBox checkbox_show_deconv_lines, userdata(ResizeControlsInfo)=A"!!,BY!!#?K!!#@J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_show_deconv_lines, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkbox_show_deconv_lines, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_show_deconv_lines, value=1
	Button button_psx_info, pos={18.00, 458.00}, size={19.00, 19.00}, proc=PSX_CopyHelpToClipboard
	Button button_psx_info, title="i", help={"<pre></pre>"}, userdata="- none -\r\n"
	Button button_psx_info, userdata(ResizeControlsInfo)=A"!!,BI!!#CJ!!#<P!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_psx_info, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_psx_info, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_UI, pos={45.00, 458.00}, size={20.00, 22.00}
	GroupBox group_UI, help={"<html><pre>The following keyboard shortcuts work for either the psx or the psxstats graphs.\rAll of them require that the cursor A is located on an event, which is by default\rthe case for the psx graph. The current direction for automatic advancement defaults to left-to-right.\r    ↑ (up): Accept the current event, changing both event and fit state to accept,\r            and advance the cursor to the next event in the current direction\r    ↓ (down): Reject the current event, changing both event and fit state to reject,\r              and advance the cursor to the next event in the current direction\r    → (right): Move the cursor to the next event on the right\r    ← (left): Move the cursor to the previous event on the left\r    (space): Toggle the event and fit state of the current event without any movement\r    r: Reverse the current direction\r    c: Center the x-axis around the current event\r    e: Toggle the event state\r    f: Toggle the fit state\r    z: Accept the event state but reject the fit state\r</pre><html>"}
	GroupBox group_UI, userdata(ResizeControlsInfo)=A"!!,DC!!#CJ!!#<X!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_UI, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_UI, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_UI, font="Lucida Console"
	ListBox listbox_select_combo, pos={16.00, 154.00}, size={109.00, 295.00}, proc=PSX_ListBoxSelectCombo
	ListBox listbox_select_combo, help={"Select the combination (concatenated string of: range, sweep, channel, device) for doing QC data on."}
	ListBox listbox_select_combo, userdata(ResizeControlsInfo)=A"!!,B9!!#A)!!#@>!!#BMJ,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ListBox listbox_select_combo, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listbox_select_combo, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listbox_select_combo, row=26, mode=2, selRow=0
	CheckBox checkbox_show_peak_lines, pos={20.00, 92.00}, size={100.00, 15.00}, proc=PSX_UpdateVisualizationHelpers
	CheckBox checkbox_show_peak_lines, title="Show Peak lines"
	CheckBox checkbox_show_peak_lines, help={"Show the x position of the peak in the offsetted and filtered data wave"}
	CheckBox checkbox_show_peak_lines, userdata(ResizeControlsInfo)=A"!!,BY!!#?q!!#@,!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_show_peak_lines, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkbox_show_peak_lines, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_show_peak_lines, value=0
	CheckBox checkbox_show_baseline_lines, pos={20.00, 110.00}, size={118.00, 15.00}, proc=PSX_UpdateVisualizationHelpers
	CheckBox checkbox_show_baseline_lines, title="Show Baseline lines"
	CheckBox checkbox_show_baseline_lines, help={"Show the x position of the baseline in the offsetted and filtered data wave"}
	CheckBox checkbox_show_baseline_lines, userdata(ResizeControlsInfo)=A"!!,BY!!#@@!!#@P!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_show_baseline_lines, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkbox_show_baseline_lines, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_show_baseline_lines, value=0
	CheckBox checkbox_suppress_update, pos={20.00, 133.00}, size={104.00, 15.00}, proc=PSX_CheckboxProcSuppressUpdate
	CheckBox checkbox_suppress_update, title="Suppress Update"
	CheckBox checkbox_suppress_update, help={"Suppress updating the single/all event graphs on state changes"}
	CheckBox checkbox_suppress_update, userdata(ResizeControlsInfo)=A"!!,BY!!#@i!!#@4!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_suppress_update, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkbox_suppress_update, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_suppress_update, value=0
	SetWindow kwTopWin, hook(resetScaling)=IH_ResetScaling
	SetWindow kwTopWin, hook(ctrl)=PSX_PlotInteractionHook
	SetWindow kwTopWin, hook(traceUserDataCleanup)=TUD_RemoveUserDataWave
	SetWindow kwTopWin, userdata(JSONSettings_WindowGroup)="psxpanel"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#EW^]6akzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={820,360,inf,inf}" // sizeLimit requires Igor 7 or later
	NewPanel/HOST=#/EXT=3/W=(0, 360, 820, 0)/K=2 as " "
	ModifyPanel fixedSize=0
	SetDrawLayer UserBack
	CheckBox checkbox_single_events_accept, pos={21.00, 33.00}, size={53.00, 15.00}, proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_single_events_accept, title="Accept"
	CheckBox checkbox_single_events_accept, help={"Show accepted events in all events plot"}
	CheckBox checkbox_single_events_accept, value=1
	CheckBox checkbox_single_events_reject, pos={21.00, 54.00}, size={48.00, 15.00}, proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_single_events_reject, title="Reject"
	CheckBox checkbox_single_events_reject, help={"Show rejected events in all events plot"}
	CheckBox checkbox_single_events_reject, value=1
	CheckBox checkbox_single_events_undetermined, pos={21.00, 72.00}, size={48.00, 15.00}, proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_single_events_undetermined, title="Undet"
	CheckBox checkbox_single_events_undetermined, help={"Show undetermined events in all events plot"}
	CheckBox checkbox_single_events_undetermined, value=1
	GroupBox group_average, pos={91.00, 14.00}, size={76.00, 98.00}, title="Average"
	GroupBox group_average, help={"Toggle the display of the average traces"}
	CheckBox checkbox_average_events_undetermined, pos={104.00, 72.00}, size={48.00, 15.00}, proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_average_events_undetermined, title="Undet"
	CheckBox checkbox_average_events_undetermined, help={"Show average of the undetermined events in all events plot"}
	CheckBox checkbox_average_events_undetermined, value=0
	CheckBox checkbox_average_events_reject, pos={104.00, 53.00}, size={48.00, 15.00}, proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_average_events_reject, title="Reject"
	CheckBox checkbox_average_events_reject, help={"Show average of the rejected events in all events plot"}
	CheckBox checkbox_average_events_reject, value=0
	CheckBox checkbox_average_events_accept, pos={104.00, 33.00}, size={53.00, 15.00}, proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_average_events_accept, title="Accept"
	CheckBox checkbox_average_events_accept, help={"Show average of the accepted events in all events plot"}
	CheckBox checkbox_average_events_accept, value=0
	CheckBox checkbox_average_events_all, pos={104.00, 91.00}, size={30.00, 15.00}, proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_average_events_all, title="All"
	CheckBox checkbox_average_events_all, help={"Show average of all events in all events graph"}
	CheckBox checkbox_average_events_all, value=0
	CheckBox checkbox_restrict_events_to_current_combination, pos={14.00, 116.00}, size={97.00, 15.00}, proc=PSX_CheckboxProcChangeRestrictCurrentCombo
	CheckBox checkbox_restrict_events_to_current_combination, title="Current combo"
	CheckBox checkbox_restrict_events_to_current_combination, help={"Show event traces from only the current combination (checked) instead of all combinations (unchecked).\r The current combination can be set in the ListBox below."}
	CheckBox checkbox_restrict_events_to_current_combination, value=0
	PopupMenu popupmenu_state_type, pos={14.00, 134.00}, size={80.00, 19.00}, proc=PSX_PopupMenuState
	PopupMenu popupmenu_state_type, help={"Select which state is used for plotting. Can be either \"event\" or \"fit\" state."}
	PopupMenu popupmenu_state_type, mode=1, popvalue="Event State", value=#"PSX_GetEventStateNames()"
	CheckBox checkbox_events_fit_accept, pos={181.00, 33.00}, size={14.00, 14.00}, proc=PSX_CheckboxProcFitAverage
	CheckBox checkbox_events_fit_accept, title=""
	CheckBox checkbox_events_fit_accept, help={"Fit the accept average and store the outcome in the results wave"}
	CheckBox checkbox_events_fit_accept, value=0
	Button button_fit_results_accept, pos={199.00, 32.00}, size={18.00, 16.00}, proc=PSX_CopyHelpToClipboard
	Button button_fit_results_accept, title="i", help={"<pre>- none -</pre>"}
	Button button_fit_results_accept, userdata="- none -"
	GroupBox group_event, pos={14.00, 13.00}, size={67.00, 99.00}, title="Event"
	GroupBox group_event, help={"Toggle the display of the event traces"}
	SetVariable setvar_event_block_size, pos={14.00, 205.00}, size={120.00, 18.00}, bodyWidth=44, proc=PSX_SetVarBlockSize
	SetVariable setvar_event_block_size, title="Block size [%]"
	SetVariable setvar_event_block_size, help={"Allows to restrict the all event graph to only a percentage of the events."}
	SetVariable setvar_event_block_size, limits={0, 100, 1}, value=_NUM:100
	PopupMenu popup_block, pos={14.00, 228.00}, size={82.00, 19.00}, bodyWidth=50, proc=PSX_PopupMenuBlockNumber
	PopupMenu popup_block, title="Block"
	PopupMenu popup_block, help={"Select which of the event blocks to display"}
	PopupMenu popup_block, userdata(NumberOfBlocks)="1"
	PopupMenu popup_block, mode=1, popvalue="", value=#"\"\""
	PopupMenu popupmenu_event_offset, pos={14.00, 157.00}, size={53.00, 19.00}, proc=PSX_PopupMenuState
	PopupMenu popupmenu_event_offset, help={"Select the time point in x direction for aligning the single event traces in the all event graph"}
	PopupMenu popupmenu_event_offset, mode=1, popvalue="Onset", value=#"\"Onset;Peak;Slew\""
	SetVariable setvar_fit_start_amplitude, pos={14.00, 182.00}, size={144.00, 18.00}, bodyWidth=44, proc=PSX_FitStartAmplitude
	SetVariable setvar_fit_start_amplitude, title="Fit start amplitude"
	SetVariable setvar_fit_start_amplitude, help={"Percentage of the amplitude used to define the fit start point."}
	SetVariable setvar_fit_start_amplitude, limits={0, 100, 1}, value=_NUM:20
	GroupBox group_fit, pos={172.00, 14.00}, size={54.00, 98.00}, title="Fit"
	Button button_fit_results_reject, pos={199.00, 52.00}, size={18.00, 16.00}, proc=PSX_CopyHelpToClipboard
	Button button_fit_results_reject, title="i", help={"<pre>- none -</pre>"}
	Button button_fit_results_reject, userdata="- none -"
	CheckBox checkbox_events_fit_reject, pos={181.00, 53.00}, size={14.00, 14.00}, proc=PSX_CheckboxProcFitAverage
	CheckBox checkbox_events_fit_reject, title=""
	CheckBox checkbox_events_fit_reject, help={"Fit the reject average and store the outcome in the results wave"}
	CheckBox checkbox_events_fit_reject, value=0
	Button button_fit_results_undetermined, pos={199.00, 70.00}, size={18.00, 16.00}, proc=PSX_CopyHelpToClipboard
	Button button_fit_results_undetermined, title="i", help={"<pre>- none -</pre>"}
	Button button_fit_results_undetermined, userdata="- none -"
	CheckBox checkbox_events_fit_undetermined, pos={181.00, 72.00}, size={14.00, 14.00}, proc=PSX_CheckboxProcFitAverage
	CheckBox checkbox_events_fit_undetermined, title=""
	CheckBox checkbox_events_fit_undetermined, help={"Fit the undet average and store the outcome in the results wave"}
	CheckBox checkbox_events_fit_undetermined, value=0
	Button button_fit_results_all, pos={199.00, 90.00}, size={18.00, 16.00}, proc=PSX_CopyHelpToClipboard
	Button button_fit_results_all, title="i", help={"<pre>- none -</pre>"}
	Button button_fit_results_all, userdata="- none -"
	CheckBox checkbox_events_fit_all, pos={181.00, 91.00}, size={14.00, 14.00}, proc=PSX_CheckboxProcFitAverage
	CheckBox checkbox_events_fit_all, title=""
	CheckBox checkbox_events_fit_all, help={"Fit the all average and store the outcome in the results wave"}
	CheckBox checkbox_events_fit_all, value=0
	DefineGuide leftMenu={FL, 0.214995, FR}, horizCenter={leftMenu, 0.5, FR}
	SetWindow kwTopWin, hook(resetScaling)=IH_ResetScaling
	SetWindow kwTopWin, hook(ctrl)=PSX_AllEventGraphHook
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={820,200.25,inf,inf}" // sizeLimit requires Igor 7 or later
	Display/W=(225, 62, 675, 188)/FG=(horizCenter, FT, FR, FB)/HOST=#
	RenameWindow #, Single
	SetActiveSubwindow ##
	Display/W=(287, 62, 675, 188)/FG=(leftMenu, FT, horizCenter, FB)/HOST=#
	RenameWindow #, All
	SetActiveSubwindow ##
	RenameWindow #, SpecialEventPanel
	SetActiveSubwindow ##
EndMacro
