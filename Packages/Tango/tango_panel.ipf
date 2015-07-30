#pragma rtGlobals = 1
#pragma version = 1.0
#pragma IgorVersion = 6.0

//==============================================================================
// tango_panel.ipf
//------------------------------------------------------------------------------
// N.Leclercq - SOLEIL
//==============================================================================

//==============================================================================
// DEPENDENCIES
//==============================================================================
#include "tango"
#include "tango_monitor"
#include "tango_code_generator"

//==============================================================================
// CONSTS
//==============================================================================
static strconstant kDSERVER_PREFIX = "dserver/"
static strconstant kSTARTER_PREFIX = "tango/admin/"
static strconstant kSYSTEM_PREFIX  = "sys/"
//------------------------------------------------------------------------------
static constant kTAB_ATTR	= 0
static constant kTAB_CMD	= 1
static constant kTAB_PROP	= 2
static constant kTAB_BBOX	= 3
//------------------------------------------------------------------------------

//==============================================================================
//  tango_panel
//==============================================================================
window tango_panel() : Panel
	PauseUpdate; Silent 1		// building window...
	tp_build()
endMacro
//==============================================================================
function tp_build() 
   String wl = WinList("tango_panel", ";", "WIN:64")
   if (strlen(wl))
		DoWindow /F tango_panel
		return kNO_ERROR
	endif
	String empty_list_name = tango_get_global_obj("empty_list", k1DTWAV)
	WAVE/T empty_list = $empty_list_name	
	DoWindow /K tango_panel
	NewPanel /K=1 /W=(140,130,1088,550) /N=tango_panel
	DoWindow /C tango_panel
	DoWindow /T tango_panel "TANGO - Database Browser" 
	ModifyPanel /W=tango_panel  fixedSize=1
	TabControl tab,win=tango_panel,pos={336,71},size={596,336}
	TabControl tab,win=tango_panel,font=$kLB_FONT, fsize=kLB_FONTSIZE
	TabControl tab,win=tango_panel,tabLabel(kTAB_CMD)="Commands"
	TabControl tab,win=tango_panel,tabLabel(kTAB_ATTR)="Attributes"
	TabControl tab,win=tango_panel,tabLabel(kTAB_PROP)="Properties"
	TabControl tab,win=tango_panel,tabLabel(kTAB_BBOX)="Blackbox"
	TabControl tab,win=tango_panel,value=kTAB_ATTR, proc=tp_ctrlproc_tab
	ListBox dev_list,win=tango_panel,pos={15,34},size={306,310}, frame=2,listwave=empty_list
	ListBox dev_list,win=tango_panel,mode=2, proc=tp_ctrlproc_device_listbox
	ListBox dev_list,win=tango_panel,font=$kLB_FONT, fsize=kLB_FONTSIZE
	ListBox dev_list,win=tango_panel,userColumnResize=1
	ListBox err_list,win=tango_panel,pos={344,102},size={580,293}, frame=2
	ListBox err_list,win=tango_panel,mode=2, font=$kLB_FONT, fsize=kLB_FONTSIZE
	ListBox err_list,win=tango_panel,disable=1,listwave=empty_list,userColumnResize=1
	ListBox cmd_list,win=tango_panel,pos={344,102},size={580,293}, frame=2
	ListBox cmd_list,win=tango_panel,mode=2, font=$kLB_FONT, fsize=kLB_FONTSIZE
	ListBox cmd_list,win=tango_panel,proc=tp_ctrlproc_cmd_listbox,listwave=empty_list
	ListBox cmd_list,win=tango_panel,userColumnResize=1
	ListBox attr_list,win=tango_panel,disable=1,pos={344,102},size={580,293}, frame=2
	ListBox attr_list,win=tango_panel,mode=2, font=$kLB_FONT, fsize=kLB_FONTSIZE
	ListBox attr_list,win=tango_panel,proc=tp_ctrlproc_attr_listbox,listwave=empty_list
	ListBox attr_list,win=tango_panel,userColumnResize=1
	ListBox bb_list,win=tango_panel,disable=1,pos={344,102},size={580,293}, frame=2
	ListBox bb_list,win=tango_panel,mode=2, font=$kLB_FONT, fsize=kLB_FONTSIZE,listwave=empty_list
	ListBox bb_list,win=tango_panel,userColumnResize=1
	ListBox prop_list,win=tango_panel,pos={344,102},size={580,293}, frame=2
	ListBox prop_list,win=tango_panel,mode=2, font=$kLB_FONT, fsize=kLB_FONTSIZE
	ListBox prop_list,win=tango_panel,proc=tp_ctrlproc_prop_listbox,listwave=empty_list
	ListBox prop_list,win=tango_panel,userColumnResize=1
	Button dev_update_but,win=tango_panel,pos={13,382},size={309,25}, title="Update Devices List"
	Button dev_update_but,win=tango_panel,font=$kLB_FONT, fsize=kLB_FONTSIZE, proc=tp_ctrlproc_update_list_but
	SetVariable version_sv,win=tango_panel,pos={334,15},size={80,16}, title="Version"
	SetVariable version_sv,win=tango_panel,font=$kLB_FONT, limits={0,0,0}, noedit=1
	SetVariable class_sv,win=tango_panel,pos={423,15},size={150,16}, title="Class"
	SetVariable class_sv,win=tango_panel,font=$kLB_FONT, limits={0,0,0}, noedit=1
	SetVariable url_sv,win=tango_panel,pos={335,42},size={540,16}, title="URL"
	SetVariable url_sv,win=tango_panel,font=$kLB_FONT, limits={0,0,0}, noedit=1
	SetVariable host_sv,win=tango_panel,pos={581,15},size={352,16}, title="Host"
	SetVariable host_sv,win=tango_panel,font=$kLB_FONT, limits={0,0,0}, noedit= 1
	Button open_url_but,win=tango_panel,pos={885,42},size={47,17}
	Button open_url_but,win=tango_panel,font=$kLB_FONT, fsize=kLB_FONTSIZE
	Button open_url_but,win=tango_panel,proc=tp_open_url, title="Open"
	CheckBox sa_cb,win=tango_panel,pos={64,14},size={81,14}, proc=tp_ctrlproc_sacb
	CheckBox sa_cb,win=tango_panel,font=$kLB_FONT, title="Show Aliases",value=1
	CheckBox sc_cb,win=tango_panel,pos={180,14},size={84,14},proc=tp_ctrlproc_sccb
	CheckBox sc_cb,win=tango_panel,font=$kLB_FONT,title="Show Classes",value=0
	SVAR wc = $tango_get_global_obj("wild_card", kSVAR, svalue = "dev=*")
	SetVariable wild_card,win=tango_panel,pos={13,355},size={309,16},title="Filter"
	SetVariable wild_card,win=tango_panel,font=$kLB_FONT, proc=tp_ctrlproc_wc
	SetVariable wild_card,value=wc,help={"Device list filter: [dev, class or alias] = my-wildcard (e.g. class=profibus*)"}
	tp_disable_items()
	DoUpdate
	tp_ctrlproc_update_list_but("dummy")
end 
//==============================================================================
// function:  tp_enable_items
//==============================================================================
function tp_enable_items ( )
	Button open_url_but, disable=0
	Button tab, disable=0
end
//==============================================================================
// function:  tp_disable_devlist
//==============================================================================
function tp_disable_devlist ( )
	String empty_list_name = tango_get_global_obj("empty_list", k1DTWAV)
	String empty_selw_name = tango_get_global_obj("empty_selw", k1DNWAV)
	WAVE/T empty_list = $empty_list_name	
	WAVE/T empty_selw = $empty_selw_name	
	ListBox dev_list, win=tango_panel, listWave=empty_list
	ListBox dev_list, win=tango_panel, selWave=empty_selw
end
//==============================================================================
// function:  tp_disable_items
//==============================================================================
function tp_disable_items ( )
	String empty_list_name = tango_get_global_obj("empty_list", k1DTWAV)
	String empty_selw_name = tango_get_global_obj("empty_selw", k1DNWAV)
	WAVE/T empty_list = $empty_list_name	
	WAVE/T empty_selw = $empty_selw_name	
	TabControl tab, win=tango_panel,disable=2
	TabControl tab,win=tango_panel,tabLabel(kTAB_CMD)="Commands"
	TabControl tab,win=tango_panel,tabLabel(kTAB_ATTR)="Attributes"
	TabControl tab,win=tango_panel,tabLabel(kTAB_PROP)="Properties"
	TabControl tab,win=tango_panel,tabLabel(kTAB_BBOX)="Blackbox"
	ListBox err_list, win=tango_panel, listWave=empty_list, disable=1
	ListBox cmd_list, win=tango_panel, listWave=empty_list, disable=1
	ListBox attr_list, win=tango_panel, listWave=empty_list, disable=1
	ListBox bb_list, win=tango_panel, listWave=empty_list, disable=1
	ListBox prop_list, win=tango_panel, listWave=empty_list, disable=1
	String empty_var = tango_get_global_obj("empty_var", kSVAR)
	SetVariable version_sv, win=tango_panel, value=$empty_var
	SetVariable class_sv, win=tango_panel, value=$empty_var
	SetVariable host_sv, win=tango_panel, value=$empty_var
	SetVariable url_sv, win=tango_panel, value=$empty_var
	Button open_url_but, disable=2
end
//==============================================================================
// function:  tp_show_error
//==============================================================================
function tp_show_error ( )
	tango_get_error_stack()
	WAVE/T/Z error_stack = root:tango:common:error_stack
	if (WaveExists(error_stack) == 0 || numpnts(error_stack) == 0)
		return kNO_ERROR
	endif
	TabControl tab, win=tango_panel, tabLabel(kTAB_CMD)="ERROR"
	TabControl tab, win=tango_panel, tabLabel(kTAB_ATTR)="ERROR"
	TabControl tab, win=tango_panel, tabLabel(kTAB_PROP)="ERROR"
	TabControl tab, win=tango_panel, tabLabel(kTAB_BBOX)="ERROR"
	ListBox err_list, win=tango_panel, disable=0
	SetDimLabel 1, 0, Severity, error_stack
	SetDimLabel 1, 1, Reason, error_stack
	SetDimLabel 1, 2, Description, error_stack
	SetDimLabel 1, 3, Origin, error_stack
	Make/O/N=(dimsize(error_stack, 1)) ww
	Variable min_wd = FontSizeStringWidth("MS Shell Dlg", kLB_FONTSIZE, 0, "Severity")
	WAVE/T es = root:tango:common:error_stack
	tools_get_listbox_colwidths(es, ww, min_wd)
	ListBox err_list,win=tango_panel,widths={ww[0],ww[1],ww[2],ww[3],ww[4]}
	ListBox err_list,win=tango_panel,listWave=error_stack
	KillWaves/Z ww   
end
//==============================================================================
// function:  tp_hide_error
//==============================================================================
function tp_hide_error ( )
	ListBox err_list, win=tango_panel, disable=1
	TabControl tab,win=tango_panel,tabLabel(kTAB_CMD)="Commands"
	TabControl tab,win=tango_panel,tabLabel(kTAB_ATTR)="Attributes"
	TabControl tab,win=tango_panel,tabLabel(kTAB_PROP)="Properties"
	TabControl tab,win=tango_panel,tabLabel(kTAB_BBOX)="Blackbox"
end
//==============================================================================
// function:  tp_ctrlproc_wc
//==============================================================================
function tp_ctrlproc_wc (ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr	
	String varName	
	tp_ctrlproc_update_list_but("dummy")
end
//==============================================================================
// function:  tp_ctrlproc_sacb
//==============================================================================
Function tp_ctrlproc_sacb (ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	tp_ctrlproc_update_list_but ("dummy")
End
//==============================================================================
// function:  tp_ctrlproc_sccb
//==============================================================================
Function tp_ctrlproc_sccb (ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	tp_ctrlproc_update_list_but ("dummy")
End
//==============================================================================
// function:  tp_ctrlproc_tab
//==============================================================================
function tp_ctrlproc_tab (name, tab)
	String name
	Variable tab
	Variable disable_ctrl
	ListBox cmd_list, win=tango_panel, disable=(tab!=kTAB_CMD)
	ListBox attr_list, win=tango_panel, disable=(tab!=kTAB_ATTR)
	ListBox prop_list, win=tango_panel, disable=(tab!=kTAB_PROP)
	ListBox bb_list, win=tango_panel, disable=(tab!=kTAB_BBOX)
	ControlInfo /W=tango_panel dev_list
	WAVE/T list = $(S_DataFolder + S_Value)
	if (V_Value == -1)
		return kNO_ERROR
	endif
	String ldf
	if (tango_enter_device_df(list[V_Value][1], prev_df=ldf) == kERROR)
		return kERROR
	endif
	switch (tab)
		case kTAB_CMD:
			tp_update_cmd_list(list[V_Value][1])
			break
		case kTAB_ATTR:
			tp_update_attr_list(list[V_Value][1])
			break
		case kTAB_PROP:
			tp_update_prop_list(list[V_Value][1])
			break
		case kTAB_BBOX:
			tp_update_bb_list(list[V_Value][1])
			break
	endswitch
	tango_leave_df(ldf)
end
//==============================================================================
//  tp_ctrlproc_update_list_but
//==============================================================================
function tp_ctrlproc_update_list_but (ctrlName) : ButtonControl
	String ctrlName
	tp_disable_items()
	tp_disable_devlist()
	ControlInfo /W=tango_panel sa_cb
	Variable show_aliases = V_Value
	ControlInfo /W=tango_panel sc_cb
	Variable show_classes = V_Value
	SetDrawLayer /W=tango_panel UserFront
	DrawText /W=tango_panel 481,251,"Contacting the TANGO database..."
	String db_wc = "*"
	String user_wc = "*"
	String criteria = "dev"
	SVAR wc = $tango_get_global_obj("wild_card", kSVAR, svalue = "dev=*")
	if (strlen(wc) != 0)
		criteria = StringFromList(0, wc, "=")
		user_wc = StringFromList(1, wc, "=")
		if (strlen(user_wc) == 0)
			user_wc = "*"
			db_wc = "*"
			wc = criteria + "=" + user_wc
		endif
	endif
	Variable criteria_code = 0
	strswitch(lowerstr(criteria))
		case "alias":
			show_aliases = 1
			CheckBox sa_cb, win=tango_panel, value=1
			criteria_code = 1
			db_wc = "*"
			break
		case "class":
			show_classes = 1
			CheckBox sa_cb, win=tango_panel, value=1
			criteria_code = 2
			db_wc = "*"
			break
		case "dev":
			criteria_code = 0
			db_wc = user_wc
			break
		default:
			print "Tango-Binding::could not interpret the device list filter - using dev=*"
			criteria_code = 0
			db_wc = "*"
			wc = "dev=*"
			break
	endswitch
	SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
	if (strlen(tango_host) == 0)
		SetDrawLayer /W=tango_panel /K UserFront
		tango_display_error_str("ERROR! SVAR root:tango:common:tango_host is not defined!")
		return kERROR
	endif
	String ldf
	do
		if (tango_enter_device_df(tango_host, prev_df=ldf) == kERROR)
			SetDrawLayer /W=tango_panel /K UserFront
			tp_show_error()
			String err_txt = "The TANGO database " + tango_host + " is unreachable.\n\n"
			err_txt += "Edit 'root:tango:common:tango_host' ?" 
			DoAlert 1, err_txt;
			if (V_flag == 2)
				return kERROR
			endif
			String db = tango_host
			Prompt db, "Enter your TANGO database device name..."
			DoPrompt "Tango Database", db
			if (V_flag == 1)
				return kERROR
			endif
			tango_host = db
			tango_save_prefs()
		else 
			break
		endif
	while(1)
	String temp_var = tango_device_to_df_name(tango_host) + ":tmp_dlist"
	if (tango_command_inout(tango_host, "DbGetDeviceExportedList", db_wc, temp_var) == -1)
		SetDrawLayer /W=tango_panel /K UserFront
		tp_show_error()
		KillStrings/Z temp_var 
		return kNO_ERROR
	endif
	SetDrawLayer /W=tango_panel /K UserFront
	String empty_list_name = tango_get_global_obj("empty_list", k1DTWAV)
	String empty_selw_name = tango_get_global_obj("empty_selw", k1DNWAV)
	WAVE/T empty_list = $empty_list_name
	WAVE/T empty_selw = $empty_selw_name
	WAVE/Z/T tmp_dlist = $temp_var
	NVAR show_admin_devices = $tango_get_global_obj("show_admin_devices", kNVAR)
	if (! show_admin_devices)
		Duplicate /O /T tmp_dlist, tmp_dlist_cpy
		Variable i = 0, n_removed = 0
		Variable max_i = Dimsize(tmp_dlist_cpy, 0)
		Variable is_admin_device = 0
		for (; i < max_i; i += 1)
			if (strsearch(tmp_dlist_cpy[i], kDSERVER_PREFIX, 0) != -1)
				is_admin_device = 1
			elseif (strsearch(tmp_dlist_cpy[i], kSTARTER_PREFIX, 0) != -1)
				is_admin_device = 1
			elseif (strsearch(tmp_dlist_cpy[i], kSYSTEM_PREFIX, 0) != -1)
				is_admin_device = 1
			else
				is_admin_device = 0
			endif
			if (is_admin_device)
				DeletePoints /M=0 (i - n_removed), 1, tmp_dlist
				n_removed += 1
			endif
		endfor
	endif
	ListBox dev_list, selRow = -1
	Variable n = dimsize(tmp_dlist,0)
	if (WAVEExists(tmp_dlist) == 0 || n == 0)	
		Make /O /B /U /N=(numpnts(empty_list),1,1) dlist_sw = 0
		Make /O /W /U dlist_colors = {{0,0,0},{65535,0,0}}
		MatrixTranspose dlist_colors
		ListBox dev_list, win=tango_panel, listWave=empty_list, disable=0
		ListBox dev_list, win=tango_panel, selWave=empty_selw
		ListBox dev_list, win=tango_panel, colorWave=dlist_colors
		ListBox cmd_list, win=tango_panel, listWave=empty_list, disable=0
		ListBox attr_list, win=tango_panel, listWave=empty_list, disable=1
		ListBox bb_list, win=tango_panel, listWave=empty_list, disable=1
		KillWaves/Z tmp_dlist, tmp_dlist_cpy
		KillStrings/Z temp_var 
		tango_leave_df(ldf)
		return kNO_ERROR
	endif 
	tp_sort_list(tmp_dlist)
	Make /O /N=(numpnts(tmp_dlist),3) /T dlist = "--"
	dlist[][1] = tmp_dlist[p]
	Make /O /N=(2,1) ww	
	if (show_aliases)
		SetDrawLayer /W=tango_panel /K UserFront
		DrawText /W=tango_panel 461,251,"Updating aliases from TANGO database..."
		DoUpdate
		tp_get_dev_aliases (dlist)
		SetDrawLayer /W=tango_panel /K UserFront
		if (criteria_code == 1)
			SetDrawLayer /W=tango_panel /K UserFront
			DrawText /W=tango_panel 461,251,"Applying alias filter..."
			DoUpdate
			Duplicate /O /T /R=[] dlist, tmp_dlist
			max_i = Dimsize(dlist, 0)
			n_removed = 0
			for (i = 0; i < max_i; i += 1)
				if (stringmatch(lowerstr(dlist[i][0]), lowerstr(user_wc)) == 0)
					DeletePoints /M=0 (i - n_removed), 1, tmp_dlist
					n_removed += 1
				endif
			endfor
			Redimension /N=(Dimsize(tmp_dlist, 0), Dimsize(tmp_dlist, 1), 0, 0) dlist
			dlist = tmp_dlist
			if (Dimsize(dlist, 0) == 0)	
				Make /O /B /U /N=(numpnts(empty_list),1,1) dlist_sw = 0
				Make /O /W /U dlist_colors = {{0,0,0},{65535,0,0}}
				MatrixTranspose dlist_colors
				ListBox dev_list, win=tango_panel, listWave=empty_list, disable=0
				ListBox dev_list, win=tango_panel, selWave=empty_selw
				ListBox dev_list, win=tango_panel, colorWave=dlist_colors
				ListBox cmd_list, win=tango_panel, listWave=empty_list, disable=0
				ListBox attr_list, win=tango_panel, listWave=empty_list, disable=1
				ListBox bb_list, win=tango_panel, listWave=empty_list, disable=1
				KillWaves/Z tmp_dlist, tmp_dlist_cpy, ww
				KillStrings/Z temp_var 
				tango_leave_df(ldf)
				return kNO_ERROR
			endif 
		endif
	endif
	if (show_classes)
		SetDrawLayer /W=tango_panel /K UserFront
		DrawText /W=tango_panel 461,251,"Updating classes from TANGO database..."
		DoUpdate
		tp_get_dev_classes(dlist)
		SetDrawLayer /W=tango_panel /K UserFront
		if (criteria_code == 2)
			SetDrawLayer /W=tango_panel /K UserFront
			DrawText /W=tango_panel 461,251,"Applying class filter..."
			DoUpdate
			Duplicate /O /T /R=[] dlist, tmp_dlist
			max_i = Dimsize(dlist, 0)
			n_removed = 0
			for (i = 0; i < max_i; i += 1)
				if (stringmatch(lowerstr(dlist[i][2]), lowerstr(user_wc)) == 0)
					DeletePoints /M=0 (i - n_removed), 1, tmp_dlist
					n_removed += 1
				endif
			endfor
			Redimension /N=(Dimsize(tmp_dlist, 0), Dimsize(tmp_dlist, 1), 0, 0) dlist
			dlist = tmp_dlist
		endif
		if (Dimsize(dlist, 0) == 0)	
			Make /O /B /U /N=(numpnts(empty_list),1,1) dlist_sw = 0
			Make /O /W /U dlist_colors = {{0,0,0},{65535,0,0}}
			MatrixTranspose dlist_colors
			ListBox dev_list, win=tango_panel, listWave=empty_list, disable=0
			ListBox dev_list, win=tango_panel, selWave=empty_selw
			ListBox dev_list, win=tango_panel, colorWave=dlist_colors
			ListBox cmd_list, win=tango_panel, listWave=empty_list, disable=0
			ListBox attr_list, win=tango_panel, listWave=empty_list, disable=1
			ListBox bb_list, win=tango_panel, listWave=empty_list, disable=1
			KillWaves/Z tmp_dlist, tmp_dlist_cpy, ww
			KillStrings/Z temp_var 
			tango_leave_df(ldf)
			return kNO_ERROR
		endif 
	endif
	Variable min_w = FontSizeStringWidth("MS Shell Dlg", kLB_FONTSIZE, 0, "Device")
	tools_get_listbox_colwidths(dlist, ww, min_w, f="MS Shell Dlg", fs=kLB_FONTSIZE)
	Variable w0 = show_aliases ? ww[0] : 0
	Variable w1 = show_classes ? ww[1] : (4 * ww[1])
	Variable w2 = show_classes ? ww[2] : 0
	ListBox dev_list, win=tango_panel, widths={w0,w1,w2}
	SetDimLabel 1, 0, Alias, dlist 
	SetDimLabel 1, 1, Device, dlist 
	SetDimLabel 1, 2, Class, dlist 
	Make /O /B /U /N=(DimSize(dlist, 0),2,2) dlist_sw = 0
	SetDimLabel 2, 0, foreColors, dlist_sw
	Make /O /W /U dlist_colors = {{0,0,0},{65535,0,0}}
	MatrixTranspose dlist_colors
	ListBox dev_list, win=tango_panel, selWave=dlist_sw
	ListBox dev_list, win=tango_panel, colorWave=dlist_colors
	ListBox dev_list, win=tango_panel, listWave=dlist
	ListBox dev_list, win=tango_panel, row=0, selRow=-1 
	KillWaves/Z ww
	ListBox attr_list, win=tango_panel, listWave=empty_list, disable=1
	ListBox bb_list, win=tango_panel, listWave=empty_list, disable=1
	ListBox cmd_list, win=tango_panel, listWave=empty_list, disable=0
	KillStrings/Z temp_var 
	KillWaves/Z tmp_dlist, tmp_dlist_cpy
	tango_leave_df(ldf)
end
//==============================================================================
//  tp_get_dev_aliases [PRIVATE]
//==============================================================================
static function tp_get_dev_aliases (dlist)
	Wave/T dlist
	Make/O/T aliases
	if (tango_db_get_dev_aliases(aliases) == kERROR)
		KillWaves/Z aliases
		return kERROR
	endif
	Variable n = DimSize(aliases, 0)
	Make/O/T/N=(n, 3) aliased_dev 
	Variable i
	for (i = 0; i < n; i += 1)
	   String dev
		if (tango_db_get_alias_dev (aliases[i], dev) == kERROR)
			KillWaves/Z aliases, aliased_dev 
			return kERROR
		endif
		aliased_dev[i][0] = aliases[i]
		aliased_dev[i][1] = dev
	endfor
	KillWaves/Z aliases
	Variable j
	Variable m = DimSize(dlist, 0)
	Variable aliased_count = 0
	for (j = 0; j < m; j += 1)
		for (i = 0; i < n; i += 1)
			if (! cmpstr(aliased_dev[i][1], dlist[j][1]))
				dlist[j][0] = aliased_dev[i][0]
				aliased_count += 1
				break		
			endif
		endfor
		if (aliased_count == n)
			break
		endif
	endfor
	KillWaves/Z aliased_dev 
end
//==============================================================================
//  tp_get_dev_classes [PRIVATE]
//==============================================================================
static function tp_get_dev_classes (dlist)
	Wave/T dlist
	Variable n = DimSize(dlist, 0)
	Variable i
	for (i = 0; i < n; i += 1)
	   String class
		if (tango_db_get_dev_class(dlist[i][1], class) == kERROR)
			return kERROR
		endif
		dlist[i][2] = class
	endfor
end
//==============================================================================
// fonction : tp_edit_device_alias [PRIVATE]
//==============================================================================
static function tp_edit_device_alias (device, alias)
	String device
	String& alias
	String alert =  "About to change the alias of '" + device + "'.\n"
	alert += "Code making use of the current alias may produce errors!\n" 
	alert += "Continue anyway?"
	DoAlert 1, alert
	if (V_flag == 2)
		return kNO_ERROR
	endif
	if (tango_db_get_dev_alias(device, alias) == kERROR)
		return kERROR
	endif
	String prompt_str = "Enter new alias for '" + device + "'"
	String new_alias = alias
	Prompt new_alias, prompt_str
	DoPrompt "Edit Device Alias...", new_alias
	if (V_flag == 1)
		return kNO_ERROR
	endif
	if (tango_db_set_dev_alias(device, new_alias) == kERROR)
		return kERROR
	endif
	alias = new_alias
	return kNO_ERROR
end
//==============================================================================
//  tp_ctrlproc_device_listbox
//==============================================================================
function tp_ctrlproc_device_listbox (lba)
	Struct WMListboxAction& lba
	if (lba.row < 0)
		lba.row = 0
		ListBox dev_list, win=tango_panel, selRow=lba.row, row=lba.row
	elseif (lba.row >= DimSize(lba.listWave, 0))
		lba.row = DimSize(lba.listWave, 0) - 1
		ListBox dev_list, win=tango_panel, selRow=lba.row
	endif
	NVAR xptm = $tango_get_global_obj("xptm", kNVAR)
	switch (lba.eventCode)
		case 1:
			if (lba.eventMod & 0x10)
				String popup_str = "Print State/Status in History;\M1-;"
				popup_str += "\M1(Open Device Panel;\M1-;" 
				if (! xptm)
					popup_str += "\M1("
				endif
				popup_str += "Edit Alias...;\M1-;Reload Device Interface;\M1-;Kill Monitors;\M1-;"
				if (! xptm)
					popup_str += "\M1("
				endif
				popup_str += "Generate Device Interface...;"
				if (! xptm)
					popup_str += "\M1("
				endif
				popup_str += "Generate Class Interface...;"
				popup_str += "\M1-;Copy Device Name to Clipboard"
				PopupContextualMenu popup_str
				switch (V_Flag)
					case 1:
						tango_dump_dev_status(lba.listWave[lba.row][1])
						break
					case 3:
						//-disabled: tango_dp(lba.listWave[lba.row][1])
						break
					case 5:
						String alias = lba.listWave[lba.row][0]
						if (! tp_edit_device_alias(lba.listWave[lba.row][1], alias))
							lba.listWave[lba.row][0] = alias
						endif
						break
					case 7:
						String alert =  "About to reload '" + lba.listWave[lba.row][1] + "' interface.\n"
						alert += "This will kill all running device monitor!\n" 
						alert += "Continue anyway?"
						DoAlert 1, alert
						if (V_flag == 2)
							return kNO_ERROR
						endif
						tmon_kill_dev_monitors(lba.listWave[lba.row][1])
						tango_close_device(lba.listWave[lba.row][1])
						tools_kill_df(tango_device_to_df_name(lba.listWave[lba.row][1]))
						lba.eventMod = 0
						tp_ctrlproc_device_listbox(lba)
						break
					case 9:
						tmon_kill_dev_monitors(lba.listWave[lba.row][1])
						break
					case 11:
						tango_gen_device_interface(0, dev_name=lba.listWave[lba.row][1])
						break
					case 12:
						tango_gen_device_interface(1, dev_name=lba.listWave[lba.row][1])
						break
					case 14:
					       PutScrapText lba.listWave[lba.row][1]
						break
					default:
						break
				endswitch	
			else
				ControlInfo /W=tango_panel tab
				Variable current_tab = V_Value
				tp_disable_items()
				SetDrawLayer /W=tango_panel UserFront
				DrawText /W=tango_panel 481,251,"Contacting " + lba.listWave[lba.row][1] + "..."
				String ldf
				if (tango_enter_device_df(lba.listWave[lba.row][1], prev_df=ldf) == kERROR)
					SetDrawLayer /W=tango_panel /K UserFront
					tp_device_error(lba.row)
					return kERROR
				endif
				Variable err = 0
				switch (current_tab)
					case kTAB_CMD:
						err = tp_update_cmd_list(lba.listWave[lba.row][1])
						break
					case kTAB_ATTR:	
						err = tp_update_attr_list(lba.listWave[lba.row][1])
						break
					case kTAB_PROP:	
						err = tp_update_prop_list(lba.listWave[lba.row][1])
						break 
					case kTAB_BBOX:	
						err = tp_update_bb_list(lba.listWave[lba.row][1])
						break 
				endswitch
				SetDrawLayer /W=tango_panel /K UserFront
				tp_update_dev_info(lba.listWave[lba.row][1])
				TabControl tab, win=tango_panel, value=current_tab
				if (err == -1)
					tp_device_error(lba.row)
				else
					tp_device_noerror(lba.row)
				endif
				tango_leave_df(ldf)
			endif
			break
		//- double click
		case 3: 
			if (lba.eventMod & 0x10)
				return kNO_ERROR
			endif
			//-disabled: tango_dp(lba.listWave[lba.row][1])
			break
		default:
			break
	endswitch	
	return kNO_ERROR
end
//==============================================================================
//  tp_ctrlproc_cmd_listbox
//==============================================================================
function tp_ctrlproc_cmd_listbox (lba)
	Struct WMListboxAction& lba
	if (lba.eventCode == -1)
		return kNO_ERROR
	endif
	ControlInfo /W=tango_panel dev_list
	if (V_Value == -1)
		return kNO_ERROR
	endif
	WAVE/T dlist = $(S_DataFolder + S_Value)
	String dev = dlist[V_Value][1]
	String cmd = lba.listWave[lba.row][0]
	NVAR xptm = $tango_get_global_obj("xptm", kNVAR)
	switch (lba.eventCode)
		//- double click
		case 3: 
			if (lba.eventMod & 0x10)
				return kNO_ERROR
			endif
			break
		//- mouse down + right click
		case 4:
			String popup_str = ""
			if (! (lba.eventMod & 0x10))
				return kNO_ERROR
			endif
			popup_str = "Print Device State/Status in History;\M1-;Execute...;\M1-;"
		   if (! xptm)
		   		popup_str += "\M1(Generate Execute Function to Clipboard" 
		   else
		   		popup_str += "Generate Execute Function to Clipboard" 
		   endif
			PopupContextualMenu popup_str
			switch (V_Flag)
				//- state & status
				case 1:
					tango_dump_dev_status(dev)
					return kNO_ERROR
					break
				//- execute
				case 3:
					break
				//- gen exec function to clipboard
				case 5:
					tango_gen_cmd_func_to_scrap(dev, cmd)
					return kNO_ERROR
					break
				//- default behaviour
				default:
					return kNO_ERROR
					break
			endswitch
			break
		default:
			return kNO_ERROR
			break
	endswitch	
	String argin_type = lba.listWave[lba.row][1]
	String argin_note = lba.listWave[lba.row][2]
	if (cmpstr(argin_note, "-") == 0 || cmpstr(argin_note, "Uninitialised") == 0)
		argin_note = ""
	endif
	String wlist = ""
	String argout_type = lba.listWave[lba.row][3]
	String ldf
	tango_enter_tmp_df (dev, prev_df=ldf)
	String win_title = "Execute " + dev + "::" + cmd
	String user_input = ""
	String argin_name = "argin"
	String prompt_str = ""
	strswitch(argin_type)
		case "-":
			break
		case "String":
			String argin_str = ""
			prompt_str = "Enter "
			if (strlen(argin_note) > 0)
				prompt_str += lowerStr(argin_note)
			else
				prompt_str += "input argument [string]"
			endif
			prompt_str += ":"
			Prompt argin_str, prompt_str
			DoPrompt win_title, argin_str
			if (V_Flag)
				SetDataFolder(ldf)
				return kNO_ERROR
			endif
			user_input = argin_str
			String/G $argin_name = argin_str
			break
		case "Variable":
			Variable argin_val = 0
			prompt_str = "Enter "
			if (strlen(argin_note) > 0)
				prompt_str += "<" + argin_note + ">"
			else
				prompt_str += "input argument [variable]"
			endif
			prompt_str += ":"
			Prompt argin_val, prompt_str
			DoPrompt win_title, argin_val
			if (V_Flag)
				SetDataFolder(ldf)
				return kNO_ERROR
			endif
			user_input = num2str(argin_val)
			Variable/G $argin_name = argin_val
			break
		case "Wave":
		case "Wave/T":
		case "Wave/B":
		case "Wave/W":
		case "Wave/I":
		case "Wave/D":
		case "Wave/U/B":
		case "Wave/U/W":
		case "Wave/U/I":
			Variable type = 2
			strswitch(argin_type)
				case "Wave/T":
					type = 0x00
					break
				case "Wave/B":
					type = 0x08
					break
				case "Wave/W":
					type = 0x10
					break
				case "Wave/I":
					type = 0x20
					break
				case "Wave/D":
					type = 0x04
					break
				case "Wave/U/B":
					type = 0x08 | 0x40
					break
				case "Wave/U/W":
					type = 0x10 | 0x40
					break
				case "Wave/U/I":
					type = 0x20 | 0x40
					break
			endswitch
			String argin_wave = "argin_w_"
			if (WaveExists($argin_wave))
				KillWaves $argin_wave
			endif
			Make /O /N=1 /Y=(type) $argin_wave
			Edit/K=1 $argin_wave
			String table_name = uniquename("input", 7, 0)
			DoWindow/C $table_name
			DoWindow/T $table_name, dev + "::" + cmd
			Execute("Modifytable alignment=1, font=\"Courier New\"")
			PauseForUser $table_name
			user_input = argin_wave
			String/G $argin_name = argin_wave
			break
		case "Wave/I:Wave/T":
		case "Wave/D:Wave/T":
			strswitch(argin_type)
				case "Wave/I:Wave/T":
					type = 0x20
					break
				case "Wave/D:Wave/T":
					type = 0x04
					break
			endswitch
			String argin_nwave = "argin_nw_"
			if (WaveExists($argin_nwave))
				KillWaves $argin_nwave
			endif
			Make /O /N=1 /Y=(type) $argin_nwave
			String argin_twave = "argin_tw_"
			if (WaveExists($argin_twave))
				KillWaves $argin_twave
			endif
			Make /O /N=1 /Y=(0) $argin_twave
			Edit/K=1 $argin_nwave, $argin_twave
			table_name = uniquename("input", 7, 0)
			DoWindow/C $table_name
			DoWindow/T $table_name, dev + "::" + cmd
			Execute("Modifytable alignment=1, font=\"Courier New\"")
			PauseForUser $table_name
			user_input = argin_nwave + kNAME_SEP + argin_twave
			argin_name = argin_nwave + kNAME_SEP + argin_twave
			break
		default:
			SetDataFolder(ldf)
			return kNO_ERROR
			break
	endswitch
	String argout_name = "argout"
	strswitch(argout_type)
		case "String":
			argout_name += "_str_"
			break
		case "Variable":
		case "Variable/C":
			argout_name += "_val_"
			break
		case "Wave/T":
			argout_name += "_tw_"
			break
		case "Wave/I:Wave/T":
		case "Wave/D:Wave/T":
			String argout_nwave = argout_name + "_nw_" 
			String argout_twave = argout_name + "_tw_" 
			argout_name = argout_nwave + kNAME_SEP + argout_twave 
			break
		default:
			argout_name += "_nw_"
			break
	endswitch
	String exec_cmd = dev + "::" + cmd + "(" + user_input + ")"
	print exec_cmd
	String prefix = "\t\t'-> "
	if (tango_command_inout(dev, cmd, argin_name, argout_name) == -1)
		tango_display_error()
		KillStrings/Z $argin_name
		KillVariables/Z $argin_name
		SetDataFolder(ldf)
		print prefix + "[error: " + tango_get_error_str() + "]"
		return kERROR
	endif
	KillStrings/Z $argin_name
	KillVariables/Z $argin_name
	strswitch(argout_type)
		case "-":
			print prefix + "completed successfully"
			break
		case "String":
			SVAR arg_out_str = $argout_name
			if (strlen(arg_out_str))
				print prefix + "returned: " + arg_out_str
			else
				print prefix + "valid but empty string received from device"
			endif
			KillStrings/Z argout_name
			break
		case "Variable":
			NVAR arg_out_val = $argout_name
			print prefix + " returned: " + num2str(arg_out_val)
			KillVariables/Z argout_name
			break
		case "Variable/C":
			NVAR arg_out_val = $argout_name
			print prefix + "returned - read: " + num2str(real(arg_out_val))
			print prefix + "returned - last write: " + num2str(imag(arg_out_val))
			KillVariables/Z argout_name
			break
		case "Wave/I:Wave/T":
		case "Wave/D:Wave/T":
			WAVE argout_nw = $argout_nwave
			WAVE/T argout_tw = $argout_twave
			Variable np = max(numpnts(argout_nw), numpnts(argout_tw))
			if (np == 0)
				print prefix + "valid but empty waves received from device"
				break
			endif
			if (np < 5 && numpnts(argout_nw) == numpnts(argout_tw)) 
				Variable i
				for (i= 0; i < np; i += 1)
					print prefix + "cmd-reply[" + num2str(i) + "]= " + num2str(argout_nw[i]) + " : "  + argout_tw[i]
				endfor
			else 
				Edit/K=1 $argout_nwave, $argout_twave 
				table_name = uniquename("result", 7, 0)
				DoWindow/C $table_name
				DoWindow/T $table_name, exec_cmd
				Execute("Modifytable alignment=1, font=\"Courier New\"")
				print prefix + "num. part stored in " + GetDataFolder(1) + argout_nwave
				print prefix + "txt. part stored in " + GetDataFolder(1) + argout_twave
			endif
			break
		default:
			np = numpnts($argout_name)
			if (np == 0)
				print prefix + "returned: valid but empty wave received from device"
			else
				print prefix + "returned: a wave containing " + num2str(np) + " elements"
				if (np < 5)
					if (WaveType($argout_name) != 0)
						WAVE argout_nw = $argout_name
						for (i= 0; i < np; i += 1)
							print prefix + "cmd-reply[" + num2str(i) + "]= " + num2str(argout_nw[i])
						endfor
					else 
						WAVE/T argout_tw = $argout_name
						for (i= 0; i < np; i += 1)
							print prefix +  "cmd-reply[" + num2str(i) + "]= " + argout_tw[i]
						endfor
					endif
				else
					Edit/K=1 $argout_name 
					table_name = uniquename("result", 7, 0)
					DoWindow/C $table_name
					DoWindow/T $table_name, exec_cmd
					Execute("Modifytable alignment=1, font=\"Courier New\"")
					print prefix + "result stored in " + GetDataFolder(1) + argout_name
				endif
			endif
			break
	endswitch
	SetDataFolder(ldf)
	return kNO_ERROR
end
//==============================================================================
//  tp_ctrlproc_attr_listbox
//==============================================================================
function tp_ctrlproc_attr_listbox (action)
	Struct WMListboxAction& action
	if (action.eventCode == -1)
		return kNO_ERROR
	endif
	ControlInfo /W=tango_panel dev_list
	if (V_Value == -1)
		return kNO_ERROR
	endif
	WAVE/T dlist = $(S_DataFolder + S_Value)
	String dev = dlist[V_Value][1]
	ControlInfo /W=tango_panel attr_list
	WAVE/T alist = $(S_DataFolder + S_Value)
	String attr = alist[V_Value][0] 
	Variable access = tango_get_attr_access(dev, attr)
	Variable type = tango_get_attr_type(dev, attr)
	Variable format = tango_get_attr_format(dev, attr)
	String wattr = lowerstr(alist[V_Value][16])
	NVAR xptm = $tango_get_global_obj("xptm", kNVAR)
	switch (action.eventCode)
		//- double click
		case 3: 
			if (action.eventMod & 0x10)
				return kNO_ERROR
			endif
			tmon_create(dev, attr)
			break
		//- mouse down + right click
		case 4:
			String popup_str = "Print Device State/Status in History;\M1-;"
			if (action.eventMod & 0x10)
				switch (format)
					case kSCALAR:
						switch (type)
							case kSTRING:
								switch (access)
									case kREAD:
										popup_str += "\M1(Monitor...;Read;\M1-;\M1(Write...;"
										break
									default:
										popup_str += "\M1(Monitor...;Read;\M1-;Write...;"
										break
								endswitch
								break
							default:
								switch (access)
									case kREAD:
										popup_str += "Monitor...;Read;\M1-;\M1(Write...;"
										break
									default:
										popup_str += "Monitor...;Read;\M1-;Write...;"
										break
								endswitch
								break
								break
						endswitch
						break
					case kSPECTRUM:
					case kIMAGE:
						switch (type)
							case kSTRING:
								switch (access)
									case kREAD:
										popup_str += "\M1(Monitor...;Read;\M1-;\M1(Write...;"
										break
									default:
										popup_str += "\M1(Monitor...;Read;\M1-;Write...;"
										break
								endswitch
								break
							default:
								switch (access)
									default:
										popup_str += "Monitor...;Read;\M1-;\M1(Write...;"
										break
								endswitch
								break
								break
						endswitch
						break
					default:
						break
				endswitch
				popup_str += "\M1-;"
				switch (access)
					case kREAD:
						if (! xptm)
							popup_str += "\M1(Generate Read Function to Clipboard;"
						else
							popup_str += "Generate Read Function to Clipboard;"
						endif
						break
					case kWRITE:
					case kREAD_WRITE:
					case kREAD_WITH_WRITE: 
						if (! xptm)
							popup_str += "\M1(Generate Read Function to Clipboard;"
							popup_str += "\M1(Generate Write Function to Clipboard;"
						else
							popup_str += "Generate Read Function to Clipboard;"
							popup_str += "Generate Write Function to Clipboard;"
						endif
						break
				endswitch
				popup_str += "\M1-;Copy Attribute Name to Clipboard"
				Struct AttributeValue av
				tango_init_attr_val(av, dev = dev, attr = attr)
				av.type = type
				av.format = format
				PopupContextualMenu popup_str
				switch (V_Flag)
					//- dump state & status
					case 1:
						tango_dump_dev_status (dev)
						break
					//- monitor
					case 3:
						tmon_create(dev, attr)
						break
					//- read
					case 4:
						String cur_df = GetDataFolder(1)
						if (tools_df_make("root:tmp", 1) == kERROR)
							return kERROR
						endif
						KillWaves/Z $attr
						KillVariables/Z $attr
						KillStrings/Z $attr
						av.val_path = "root:tmp:" + attr
						if (tango_read_attr(av) == kERROR)
							tango_display_error()
							SetDataFolder $cur_df
							return kERROR
						endif
						tango_dump_attribute_value(av)
						SetDataFolder $cur_df
						break
					//- write 
					case 6:
						switch (type)
							case kSTRING:
								String str_value = "<place value between quotes>"
								Prompt str_value, "Enter attribute value"
								DoPrompt "Write Scalar String Attribute", str_value
								if (V_flag == 1)
									return kNO_ERROR
								endif
								av.str_val = str_value
								break
							default:
								Variable var_value = 0
								Prompt var_value, "Enter attribute value"
								DoPrompt "Write Scalar String Attribute", var_value
								if (V_flag == 1)
									return kNO_ERROR
								endif
								av.var_val = var_value
								break
						endswitch
						if (tango_write_attr(av) == kERROR)
							tango_display_error()
							return kERROR
						endif
						print "Tango-Binding::write operation completed successfully for " + av.dev + "/" + av.attr
						break
					//- gen read to clipboard
					case 8:
						tango_get_attr_func_to_scrap(dev, attr)
						break
					//- gen write to clipboard
					case 9:
						tango_set_attr_func_to_scrap(dev, attr)
						break
					//- copy attr name to clipboard
					case 10:
					case 11:
						PutScrapText attr
						break
					default:
						break
				endswitch	
			endif
			break
		default:
			break
	endswitch	
	return kNO_ERROR
end
//==============================================================================
//  tp_ctrlproc_prop_listbox
//==============================================================================
function tp_ctrlproc_prop_listbox (action)
	Struct WMListboxAction& action
	if (action.eventCode == -1)
		return kNO_ERROR
	endif
	ControlInfo /W=tango_panel dev_list
	if (V_Value == -1)
		return kNO_ERROR
	endif
	WAVE/T dlist = $(S_DataFolder + S_Value)
	String dev = dlist[V_Value][1]
	ControlInfo /W=tango_panel prop_list
	WAVE/T plist = $(S_DataFolder + S_Value)
	String prop = plist[V_Value][0] 
	return kNO_ERROR
end
//==============================================================================
// tp_sort_list
//==============================================================================
function tp_sort_list (source)
   Wave/T &source
	Duplicate/O source, tmp_cpy
	Wave/T tmp_copy = tmp_cpy
	Variable len = DimSize(source,0)
	Make/O/T/N=(len) tmp = source[p][0] 
	Make/O/N=(len) tmp_index = 0 
	MakeIndex/A tmp, tmp_index
	Variable i = 0
	for (; i < len; i += 1)
		source[i] = tmp_copy[tmp_index[i]]
	endfor
	KillWaves/Z tmp, tmp_cpy, tmp_index
end
//==============================================================================
//  tp_update_dev_info
//==============================================================================
function tp_update_dev_info (device_name)
	String device_name
	String info_df = tango_device_to_df_name (device_name) + ":info:"
	if (DataFolderExists(info_df))
		SetVariable version_sv, win=tango_panel, value=$(info_df + "version")
		SetVariable class_sv, win=tango_panel, value=$(info_df + "class")
		SetVariable host_sv, win=tango_panel, value=$(info_df + "host")
		SetVariable url_sv, win=tango_panel, value=$(info_df + "doc_url")
	endif 
	return kNO_ERROR
end
//==============================================================================
//  tp_update_cmd_list
//==============================================================================
function tp_update_cmd_list (device_name)
	String device_name
	String ldf
	tango_enter_cmds_df(device_name, prev_df=ldf)
	String/G temp_var = "clist"
	String empty_list_name = tango_get_global_obj("empty_list", k1DTWAV)
	WAVE/T empty_list = $empty_list_name	
	ListBox cmd_list, win=tango_panel, listWave=empty_list
	if (tango_get_dev_cmd_list(device_name, temp_var) == -1)
		KillStrings temp_var 
		tango_leave_df(ldf)
		String empty_var = tango_get_global_obj("empty_var", kSVAR)
		SetVariable version_sv, win=tango_panel, value=$empty_var
		SetVariable class_sv, win=tango_panel, value=$empty_var
		SetVariable host_sv, win=tango_panel, value=$empty_var
		SetVariable url_sv, win=tango_panel, value=$empty_var
		return kERROR
	endif
	WAVE/T clist = $temp_var
	if (WAVEExists(clist) == 0 || dimsize(clist,0) == 0)
		KillStrings temp_var 
		tango_leave_df(ldf)
		return kNO_ERROR
	endif 
	tp_sort_list(clist)
	SetDimLabel 1, 0, Name, clist
	SetDimLabel 1, 1, Argin, clist
	SetDimLabel 1, 2, Argin_Note, clist
	SetDimLabel 1, 3, Argout, clist
	SetDimLabel 1, 4, Argout_Note, clist
	Make /O /N=(5) ww
	Variable min_wd = FontSizeStringWidth("MS Shell Dlg", kLB_FONTSIZE, 0, "Argin_note")
	tools_get_listbox_colwidths(clist, ww, min_wd)
	ListBox cmd_list, win=tango_panel, widths={ww[0],ww[1],ww[2],ww[3],ww[4]}
	ListBox cmd_list, win=tango_panel, listWave=clist, row=0, selRow=-1 
	KillWaves/Z ww   
	KillStrings temp_var 
	tango_leave_df(ldf)
	return kNO_ERROR
end
//==============================================================================
//  tp_update_attr_list
//==============================================================================
function tp_update_attr_list (device_name)
	String device_name
	String ldf
	tango_enter_attrs_df(device_name, prev_df=ldf)
	String/G temp_var = "alist"
	String empty_list_name = tango_get_global_obj("empty_list", k1DTWAV)
	WAVE/T empty_list = $empty_list_name		
	ListBox attr_list, win=tango_panel, listWave=empty_list
	if (tango_get_dev_attr_list(device_name, temp_var) == -1)
		KillStrings temp_var 
		tango_leave_df(ldf)
		return kERROR
	endif
	WAVE/Z/T alist = $temp_var
	if (WAVEExists(alist) == 0 || dimsize(alist,0) == 0)
		KillStrings temp_var 
		tango_leave_df(ldf)
		return kNO_ERROR
	endif 
	tp_sort_list(alist)
	SetDimLabel 1, 0, Name, alist
	SetDimLabel 1, 1, Access, alist
	SetDimLabel 1, 2, Format, alist
	SetDimLabel 1, 3, Type, alist
	SetDimLabel 1, 4, DimX, alist
	SetDimLabel 1, 5, DimY, alist
	SetDimLabel 1, 6, Label, alist
	SetDimLabel 1, 7, Unit, alist
	SetDimLabel 1, 8, StdUnit, alist
	SetDimLabel 1, 9, DispUnit, alist
	SetDimLabel 1,10, Format, alist
	SetDimLabel 1,11, minValue, alist
	SetDimLabel 1,12, maxValue, alist
	SetDimLabel 1,13, minAlarm, alist
	SetDimLabel 1,14, maxAlarm, alist
	SetDimLabel 1,15, Desc, alist
	SetDimLabel 1,16, WAttrName, alist
	Make /O /N=(17) ww
	Variable min_w = FontSizeStringWidth("MS Shell Dlg", kLB_FONTSIZE, 0, "WAttrName")
	tools_get_listbox_colwidths(alist, ww, min_w, f="MS Shell Dlg", fs=kLB_FONTSIZE)
	ListBox attr_list, win=tango_panel, widths={ww[0],ww[1],ww[2],ww[3],ww[4],ww[5],ww[6],ww[7],ww[8]}
	ListBox attr_list, win=tango_panel, widths+={ww[9],ww[10],ww[11],ww[12],ww[13],ww[14],ww[15],ww[16]}
	ListBox attr_list, win=tango_panel, listWave=alist, row=0, selRow=-1 
	KillWaves/Z ww
	KillStrings/Z temp_var 
	tango_leave_df(ldf)
	return kNO_ERROR
end
//==============================================================================
//  tp_update_bb_list
//==============================================================================
function tp_update_bb_list (device_name)
	String device_name
	String ldf
	tango_enter_tmp_df (device_name, prev_df=ldf)
	String/G temp_var = "bblist"
	String empty_list_name = tango_get_global_obj("empty_list", k1DTWAV)
	WAVE/T empty_list = $empty_list_name		
	ListBox bb_list, win=tango_panel, listWave=empty_list
	if (tango_get_dev_black_box(device_name, temp_var, 128) == -1)
		KillStrings temp_var 
		tango_leave_df(ldf)
		return kERROR
	endif
	WAVE/Z/T bblist = $temp_var
	if (WAVEExists(bblist) == 0 || dimsize(bblist,0) == 0)
		return kNO_ERROR
	endif 
	Make /O /N=2 ww
	tools_get_listbox_colwidths(bblist, ww, 256)
	ListBox bb_list, win=tango_panel, widths={ww[0]}
	ListBox bb_list, win=tango_panel, listWave=bblist, row=0, selRow=-1 
	KillStrings/Z temp_var 
	KillWaves/Z ww
	tango_leave_df(ldf)
	return kNO_ERROR
end
//==============================================================================
//  tp_update_prop_list
//==============================================================================
function tp_update_prop_list (device_name)
	String device_name
	String ldf
	tango_enter_tmp_df (device_name, prev_df=ldf)
	String empty_list_name = tango_get_global_obj("empty_list", k1DTWAV)
	WAVE/T empty_list = $empty_list_name		
	ListBox prop_list, win=tango_panel, listWave=empty_list
	String db_path = tango_get_global_obj ("tango_host", kSVAR)
	SVAR/Z db = $db_path
	if (! SVAR_Exists(db))
		return kERROR
	endif
	Make/O/N=2/T argin_w
	argin_w[0] = device_name
	argin_w[1] = "*"
	if (tango_command_inout(db, "DbGetDevicePropertyList", "argin_w", "argout_plw") == kERROR)
		return kERROR
	endif
	WAVE/T argout_plw = argout_plw
	Variable num_prop = DimSize(argout_plw, 0)
	if (num_prop)
		Redimension/N=(num_prop + 1) argin_w
		argin_w[0] = device_name
		Variable p
		for (p = 0; p < num_prop; p += 1)
			argin_w[p + 1] = argout_plw[p]
		endfor
		if (tango_command_inout(db, "DbGetDeviceProperty", "argin_w", "argout_pvw") == kERROR)
			return kERROR
		endif
		WAVE/T argout_pvw = argout_pvw
		String cur_df
		if (tango_enter_device_df(device_name, prev_df=cur_df) == kERROR)
			return kERROR
		endif
		tools_df_make("properties", 1)
		Make/O/T/N=(num_prop, 2) plist
		Variable k, v, num_val
		String str_val
		for (p = 0, k = 2; p < num_prop; p += 1)
			plist[p][0] = argout_pvw[k]
			k += 1
			num_val = str2num(argout_pvw[k])
			if (num_val > 1) 
				str_val = "["
			else
				str_val = ""
			endif
			k +=1
			for (v = 0; v < num_val; v += 1, k +=1)
				str_val = argout_pvw[k]
				if ((num_val > 1) && (v < (num_val - 1)))
					str_val += ";"
				endif
			endfor
			if (num_val > 1)
				str_val += "]"
			endif
			plist[p][1] = str_val
		endfor
		tp_sort_list(plist)
		SetDimLabel 1, 0, Name, plist
		SetDimLabel 1, 1, Value, plist
		Make/O/N=2 ww
		Variable min_wd = FontSizeStringWidth("MS Shell Dlg", kLB_FONTSIZE, 0, "Value")
		tools_get_listbox_colwidths(plist, ww, min_wd, f="MS Shell Dlg", fs=kLB_FONTSIZE)
		ListBox prop_list, win=tango_panel, widths={ww[0],ww[1]}
		ListBox prop_list, win=tango_panel, listWave=plist, row=0, selRow=-1 
		KillWaves/Z ww 
		KillWaves/Z argout_pvw 
	endif
	KillWaves/Z argout_plw
	tango_leave_df(ldf)
	return kNO_ERROR
end
//==============================================================================
//  tp_open_url
//==============================================================================
function tp_open_url (ctrlname) : ButtonControl
	String ctrlname
	ControlInfo /W=tango_panel dev_list
	WAVE/T list = $(S_DataFolder + S_Value)
	String ldf
	if (tango_enter_device_df(list[V_Value][1], prev_df=ldf) == kERROR)
		return kERROR
	endif
	SVAR/Z url = :info:doc_url
	if (SVAR_exists(url))
		BrowseURL/Z url
	endif
	tango_leave_df(ldf)
	return kNO_ERROR
end
//==============================================================================
// tp_device_error
//==============================================================================
function tp_device_error (idx)
	Variable idx
	tp_disable_items()
	SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
	if (strlen(tango_host) == 0)
		tango_display_error_str("ERROR! SVAR root:tango:common:tango_host is not defined!")
		return kERROR
	endif
	String ldf
	if (tango_enter_device_df(tango_host, prev_df=ldf) == kERROR)
		return kERROR
	endif
	WAVE/Z dlist_sw
	if (WaveExists(dlist_sw))
		dlist_sw[idx][0][0] = 1
		dlist_sw[idx][1][0] = 1
	endif
	tango_leave_df(ldf)
	tp_show_error()
	return kNO_ERROR
end
//==============================================================================
// tp_device_noerror
//==============================================================================
function tp_device_noerror (idx)
	Variable idx
	tp_hide_error()
	ControlInfo/W=tango_panel tab
	TabControl tab,win=tango_panel,tabLabel(kTAB_CMD)="Commands"
	TabControl tab,win=tango_panel,tabLabel(kTAB_ATTR)="Attributes"
	TabControl tab,win=tango_panel,tabLabel(kTAB_PROP)="Properties"
	TabControl tab,win=tango_panel,tabLabel(kTAB_BBOX)="Blackbox"
	TabControl tab, win=tango_panel, disable=0
	ListBox cmd_list, win=tango_panel, disable=(V_Value != kTAB_CMD)
	ListBox attr_list, win=tango_panel, disable=(V_Value != kTAB_ATTR)
	ListBox prop_list, win=tango_panel, disable=(V_Value != kTAB_PROP)
	ListBox bb_list, win=tango_panel, disable=(V_Value != kTAB_BBOX)
	Button open_url_but, win=tango_panel, disable=0
	SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
	if (strlen(tango_host) == 0)
		tango_display_error_str("ERROR! SVAR root:tango:common:tango_host is not defined!")
		return kERROR
	endif
	String ldf
	if (tango_enter_device_df(tango_host, prev_df=ldf) == kERROR)
		return kERROR
	endif
	WAVE/Z dlist_sw
	if (WaveExists(dlist_sw))
		dlist_sw[idx][0][0] = 0
		dlist_sw[idx][1][0] = 0
	endif
	tango_leave_df(ldf)
end
//==============================================================================
// tp_fit_to_win -- NOT USED -- IN PROGRESS
//==============================================================================
function tp_fit_to_win (win, ctrlName)
	String win, ctrlName
	GetWindow $win wsize
	Variable winH = V_bottom - V_top	 // points
	winH *= ScreenResolution / 72	 // points to pixels
	ControlInfo/W=$win $ctrlName
	if( V_Flag )
		String posInfo = StringByKey("pos", S_recreation,"=",",")
		Variable xpos = str2num(posInfo[1,inf])	// pixels
		String sizeInfo= StringByKey("size", S_recreation,"=",",")	
		Variable width = str2num(sizeInfo[1,inf])	// pixels
		ListBox $ctrlName, pos={xpos,4}, size={width, winH}
	endif
end
//==============================================================================
// tp_min_win_size -- NOT USED -- IN PROGRESS
//==============================================================================
function tp_min_win_size (winName, minw, minh)
	String winName
	Variable minw, minh
	GetWindow $winName wsize
	Variable width= max(V_right-V_left,minw)
	Variable height= max(V_bottom-V_top,minh)
	MoveWindow/W=$winName V_left, V_top, V_left+width, V_top+height
end
//==============================================================================
// tp_hook 
//=============================================================================
function tp_hook (infoStr)
	String infoStr
	return kNO_ERROR
end