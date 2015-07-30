#pragma rtGlobals = 1
#pragma version = 1.0
#pragma IgorVersion = 6.0

//==============================================================================
// tango_monitor.ipf
//------------------------------------------------------------------------------
// N.Leclercq - SOLEIL
//==============================================================================

//==============================================================================
// DEPENDENCIES
//==============================================================================
#include "tango"
#include "tango_tools"

//==============================================================================
// CONSTS
//==============================================================================
static constant kTMON_RUNNING	 = 1
static constant kTMON_PAUSED	 = 0
//------------------------------------------------------------------------------
static constant kTMON_MIN_TYPE	= 0
static constant kTMON_SCALAR		= 0
static constant kTMON_SPECTRUM	= 1
static constant kTMON_IMAGE		= 2
static constant kTMON_IMAGE_XP	= 3
static constant kTMON_IMAGE_YP	= 4
static constant kTMON_IMAGE_FP	= 5
static constant kTMON_MAX_TYPE	= 5
//------------------------------------------------------------------------------
static strconstant ksDATA_EXT	 = "_wv" 
static strconstant ksTMST_EXT	 = "_sw"
//------------------------------------------------------------------------------
static strconstant kTMON_MAGIC_WIN_NAME = "_tmon_"
//------------------------------------------------------------------------------
static constant kMIN_PP     = 0.1
static constant kMAX_PP     = 30
static constant kSTEP_PP    = 0.1
static constant kDEFAULT_PP = 0.5 
//------------------------------------------------------------------------------
static strconstant kTYPE		= "TYPE"
static strconstant kDEV		= "DEV"
static strconstant kATTR		= "ATTR"
static strconstant kWIN		= "WIN"
static strconstant kDEP		= "DEP"
static strconstant kVAL		= "VAL"
static strconstant kVAL_PATH	= "VALPATH"
static strconstant kTMS_PATH	= "TMSPATH"
static strconstant kQLT_PATH	= "QLTPATH"
static strconstant kWDATA		= "WDATA"
static strconstant kWTMS		= "WTMS"
static strconstant kWRT_ATTR	= "WRTATTR"
static strconstant kWRT_VAL	= "WRTVAL"
static strconstant kXP			= "XP"
static strconstant kXP_DEP	= "XPDEP"
static strconstant kXP_WIN	= "XPWIN"
static strconstant kYP			= "YP"
static strconstant kYP_DEP	= "YPDEP"
static strconstant kYP_WIN	= "YPWIN"
static strconstant kFP			= "FP"
static strconstant kFP_DEP	= "FPDEP"
static strconstant kXYP_UV	= "XYPUV"
static strconstant kFP_UV		= "FPUV"
static strconstant kFP_WIN	= "FPWIN"
static strconstant kDF			= "DF"
static strconstant kPP_PATH	= "PPPATH"
static strconstant kFORMAT	= "FORMAT"
static strconstant kACCESS	= "ACCESS"
static strconstant kSTATUS	= "STATUS"
static strconstant kCLTID		= "CLTID"
static strconstant kPATTACH	= "PATTACH"
static strconstant kSTATE_CID	= "STATECID"
static strconstant kSTATE_DEP= "STATEDEP"
static strconstant kKILL_WIN = "KILLWIN"
//------------------------------------------------------------------------------
static constant kTAB_PROJ    = 0
static constant kTAB_COLORS  = 1
static constant kTAB_MONCTRL = 2
//------------------------------------------------------------------------------
static constant kCSR_A = 65 // i.e. char2num("A")
static constant kCSR_B = 66 // i.e. char2num("B")
static constant kCSR_C = 67 // i.e. char2num("C")
static constant kCSR_D = 68 // i.e. char2num("D")
//------------------------------------------------------------------------------
Structure TMonWinNote
	Variable cid
	Variable type
	Variable status
	String dev
	String attr
	Variable format 
	Variable access
	String win
	String dep
	String val
	String val_path
	String tms_path
	String qlt_path
	String wdata
	String wtms
	String wrt_attr
	String wrt_val
	String xp
	String xp_dep
	String xp_win
	String yp
	String yp_dep
	String yp_win
	String fp
	String fp_dep
	String fp_win
	String xyp_uv 
	String fp_uv 
	String df
	String pp_path
	Variable pattached
	Variable dev_state_cid
	String dev_state_dep
	Variable kill_win
Endstructure
//==============================================================================
// tmon_create
//==============================================================================
function tmon_create (dev, attr)
	String dev
	String attr
	Variable type = tango_get_attr_type(dev, attr)
	if (type == kSTRING)
		tango_display_error_str("Can't monitor string attribute.")
		return kERROR
	endif 
	if (type == kUNSUPPORTED_TYPE)
		String msg = "Attribute <" + dev + "/" + attr + "> has an unsupported Tango data type."
	       tango_display_error_str(msg)
		return kERROR
	endif 
	String tmon_win_name = tmon_find(dev, attr)
	if (strlen(tmon_win_name))
		DoWindow/F $tmon_win_name
		return kNO_ERROR
	endif
	String ldf
	tango_enter_attr_df(dev, attr, prev_df=ldf)
	Struct TMonWinNote wns
	tmon_init_win_note_struct (wns)
	wns.df = GetDataFolder(1) + "monitor:"
	tools_df_make(":monitor", 1)
	wns.status = kTMON_RUNNING
	wns.dev = dev
	wns.attr = attr
	wns.format = tango_get_attr_format(dev, attr)
	wns.access = tango_get_attr_access(dev, attr)
	wns.val = UniqueName("attr_", 3, 0)
	wns.val_path = wns.df + wns.val
	wns.tms_path = wns.val_path + "_ts"
	wns.qlt_path = wns.val_path + "_qlt"
	wns.wdata = wns.val_path
	wns.wtms = wns.tms_path
	wns.win = UniqueName(wns.val + kTMON_MAGIC_WIN_NAME, 6, 0) 
	wns.dep = wns.val_path + "_dv"
	wns.pp_path = wns.val_path + "_pp"
	Variable/G $wns.dep = 0
	NVAR default_pp = $tango_get_global_obj("tmon_default_pp", kNVAR, value = kDEFAULT_PP)
	Variable/G $wns.pp_path = default_pp
	String win_title = dev + "/" + attr
	String wrt_val = ""
	Variable has_state_attr = tango_dev_attr_exists(wns.dev, "State")
	if (has_state_attr)
		Variable r,g,b
		tango_get_state_color(kDeviceStateUNKNOWN, r, g, b)
		wns.dev_state_dep = wns.val_path + "_state_dep"
		Variable/G $wns.dev_state_dep
	endif
	switch (wns.format) 
		case kSCALAR:
			wns.type = kTMON_SCALAR
			wns.wdata = wns.val_path + "_dw"
			wns.wtms = wns.val_path + "_tw"
			Variable n = 120
			Make /O /N=(n) /D $wns.wdata = NAN
			Make /O /N=(n) /D $wns.wtms = NAN
			Variable/G $wns.val_path
			if (wns.access == kREAD_WRITE || wns.access == kREAD_WITH_WRITE || wns.access == kWRITE)
				wrt_val = UniqueName("wrtv_", 3, 0)
				Variable/G $wrt_val = 0
				wns.wrt_attr = tango_get_wattr(dev, attr)
				wns.wrt_val = wrt_val 
			endif
			tmon_display_scalar(wns, win_title)
			String formula_str = "tmon_scalar_func" 
			formula_str += "(" + wns.val_path + ",\"" + wns.val_path + "\",\"" + wns.wdata
			formula_str += "\",\"" + wns.wtms + "\",\"" + wns.win + "\")"
			SetFormula $wns.dep, formula_str
			if (has_state_attr)
				TitleBox dev_status_tb, win=$wns.win, pos={480,23}
			endif
			break
		case kSPECTRUM:
			wns.type = kTMON_SPECTRUM
			Make /O /N=1 /Y=(type) $wns.val_path = 0
			tmon_display_spectrum(wns, win_title)
			SetVariable pp,win=$wns.win,proc=tmon_setvar_proc_pp
			formula_str = "tmon_spectrum_func" 
			formula_str += "(" + wns.val_path + ",\"" + wns.val_path + "\",\"" + wns.win + "\")"
			SetFormula $wns.dep, formula_str
			if (has_state_attr)
				TitleBox dev_status_tb, win=$wns.win, pos={370,23}, size={66,21}
			endif
			break
		case kIMAGE:
			wns.type = kTMON_IMAGE 
			Make /O /N=(1,1) /Y=(type) $wns.val_path = 0
			tmon_display_image(wns.win, win_title, wns.val, wns.val_path)
			SetVariable pp,win=$wns.win,proc=tmon_setvar_proc_pp
			formula_str = "tmon_image_func" 
			formula_str += "(" + wns.val_path + ",\"" + wns.val_path + "\",\"" + wns.win + "\")"
			SetFormula $wns.dep, formula_str
			if (has_state_attr)
				TitleBox dev_status_tb, win=$wns.win, pos={431,23}, size={66,21}
			endif
	endswitch
	if (has_state_attr)
		Variable cid = NAN
		String current_state_path
		String current_state_str_path
		tmon_start_dev_state_monitor (wns.dev, cid, current_state_path)
		wns.dev_state_cid = cid 
		TitleBox dev_status_tb, win=$wns.win, fStyle=1, frame=5
		TitleBox dev_status_tb, win=$wns.win, labelBack=(r,g,b)
		TitleBox dev_status_tb, win=$wns.win, title="UNKNOWN"
		TitleBox dev_status_tb, win=$wns.win, anchor=RT
		SetFormula $wns.dev_state_dep, "tmon_dev_state_changed(" + current_state_path + ",\"" + wns.win + "\")"
		SetWindow $wns.win, userData(last_dev_state)=num2str(kDeviceStateUNKNOWN)
	endif
	SetVariable pp, win=$wns.win, value=$wns.pp_path
	wns.cid = tango_monitor_start(dev, attr, wns.val_path, default_pp * 1000)
	if (wns.cid == kERROR)
		tango_display_error()
		return kERROR
	endif 
	tmon_set_win_note(wns.win, wns)
	tango_leave_df(ldf)
	return kNO_ERROR
end
//==============================================================================
// function : tmon_kill
//==============================================================================
static function tmon_kill (win_name, [kill_win])
	String win_name
	Variable kill_win 
	if (ParamIsDefault(kill_win))
		kill_win = 1
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(win_name, wns)
	if (wns.type == kTMON_IMAGE)
		if (strlen(wns.xp_win))
			//- will call the dedicated win hook
			DoWindow/K $wns.xp_win
		endif
		if (strlen(wns.yp_win))
			//- will call the dedicated win hook
			DoWindow/K $wns.yp_win
		endif
		if (strlen(wns.fp_win))
			//- will call the dedicated win hook
			DoWindow/K $wns.fp_win
		endif
	endif
	tango_monitor_stop(wns.dev, wns.attr, cid=wns.cid)
	tmon_stop_dev_state_monitor (wns.dev, wns.dev_state_cid)
	String ldf
	tango_enter_attr_df(wns.dev, wns.attr, prev_df=ldf)
	SetDataFolder :monitor
	if (kill_win)
		wns.kill_win = 1
		tmon_set_win_note (wns.win, wns)
		DoWindow/K $wns.win
		wns.win = ""
	endif
	String dep_var_name = tools_full_obj_path_to_obj_name(wns.dep)
	NVAR/Z dep_var = $dep_var_name
	if (NVAR_Exists(dep_var))
		SetFormula dep_var, ""
		KillVariables/Z $dep_var_name
	endif
	dep_var_name = tools_full_obj_path_to_obj_name(wns.dev_state_dep)
	NVAR/Z dev_state_dep_var = $dep_var_name
	if (NVAR_Exists(dev_state_dep_var))
		SetFormula dev_state_dep_var, ""
		KillVariables/Z $dep_var_name
	endif
	KillVariables /A
	KillStrings /A
	KillWaves /A 
	String mon_df = GetDataFolder(1)
	tango_leave_df(ldf) 
	KillDataFolder $mon_df
	return kNO_ERROR 
end 
//==============================================================================
// function : tmon_find_dp
//==============================================================================
static function/S tmon_find_dp (dev)
	String dev
	String attr
	String pattern = "*" + kTMON_MAGIC_WIN_NAME + "*"
	String wl = WinList(pattern, ";", "WIN:1")
	if (strlen(wl) == 0)
		return ""
	endif
	Variable i = 0
	do 
		String wn = StringFromList(i, wl)
		if (strlen(wn) == 0)
			break
		endif
		if (cmpstr(GetUserData(wn, "", "dev"), dev) == 0)
			return wn		
		endif
		i += 1
	while (1)
	return ""
end 
//==============================================================================
// function : tmon_find
//==============================================================================
static function/S tmon_find (dev, attr)
	String dev
	String attr
	String pattern = "*" + kTMON_MAGIC_WIN_NAME + "*"
	String wl = WinList(pattern, ";", "WIN:1")
	if (strlen(wl) == 0)
		return ""
	endif
	Variable i = 0
	do 
		String wn = StringFromList(i, wl)
		if (strlen(wn) == 0)
			break
		endif
		if (cmpstr(tmon_get_dev(wn), dev) == 0 && cmpstr(tmon_get_attr(wn), attr) == 0)
			return wn		
		endif
		i += 1
	while (1)
	return ""
end 
//==============================================================================
// function : tmon_scalar_func 
//==============================================================================
function tmon_scalar_func (val, val_path, dat_wav_path, tms_wav_path, win_name)
	Variable val
	String val_path
	String dat_wav_path
	String tms_wav_path
	String win_name
	NVAR/Z ts = $(val_path + "_ts")
	NVAR/Z qlt = $(val_path + "_qlt")
	if (! NVAR_Exists(ts) || ! NVAR_Exists(qlt))
		return kNO_ERROR 
	endif
	NVAR/Z last_qlt = $(val_path + "_saved_qlt")
	if (! NVAR_Exists(last_qlt))
		Variable/G $(val_path + "_saved_qlt")
		NVAR/Z last_qlt = $(val_path + "_saved_qlt")
		last_qlt = kAttrQualityUNKNOWN
	endif
	WAVE/Z dat_wav = $dat_wav_path
	WAVE/Z tms_wav = $tms_wav_path
	if (! WaveExists(dat_wav) || ! WaveExists(tms_wav))
		print "Tango-Binding::fatal error in tmon_scalar_func [wave missing]"
		tmon_abort ()
		return kNO_ERROR 
	endif
	Rotate -1, dat_wav                
	Rotate -1, tms_wav
   Variable i = numpnts(dat_wav) - 1
	if (numtype(val) == 2)
		SetDrawLayer /W=$win_name /K ProgFront
		SetDrawEnv /W=$win_name fsize=16, fstyle=1, textxjust=1, textrgb=(65280,0,0), xcoord=prel, ycoord=prel
		DrawText /W=$win_name 0.5, 0.5, "ERROR READING ATTRIBUTE"
		dat_wav[i] = NAN
		tms_wav[i] = ts
	else
		if (last_qlt != qlt)
			SetDrawLayer /W=$win_name /K ProgFront
		endif
   		dat_wav[i] = val
		tms_wav[i] = ts
	endif
	if (last_qlt != qlt)
		Variable r, g, b
		tango_get_attr_qlt_color(qlt, r, g, b)
		ValDisplay current_value,win=$win_name,labelBack=(r,g,b)
		last_qlt = qlt
		SetDrawLayer /W=$win_name /K ProgFront
	endif
	return kNO_ERROR
end
//==============================================================================
// function : tmon_spectrum_func 
//==============================================================================
function tmon_spectrum_func (dat_wav_path, val_path, win_name)
	Wave& dat_wav_path
	String val_path
	String win_name
	NVAR/Z qlt = $(val_path + "_qlt")
	if (! NVAR_Exists(qlt))
		Variable/G $(val_path + "_qlt") = kAttrQualityUNKNOWN
		NVAR qlt = $(val_path + "_qlt")
		return 0
	endif
	NVAR/Z last_qlt = $(val_path + "_saved_qlt")
	if (! NVAR_Exists(last_qlt))
		Variable/G $(val_path + "_saved_qlt")
		NVAR/Z last_qlt = $(val_path + "_saved_qlt")
		last_qlt = kAttrQualityUNKNOWN
	endif
	if (WaveExists(dat_wav_path) == 0 || numpnts(dat_wav_path) == 0)
		SetDrawLayer /W=$win_name /K ProgFront
		SetDrawEnv /W=$win_name fsize=16, fstyle=1, textxjust=1, textrgb=(65280,0,0), xcoord=prel, ycoord=prel
		DrawText /W=$win_name 0.5, 0.5, "ERROR READING ATTRIBUTE"
	elseif (last_qlt != qlt)
		SetDrawLayer /W=$win_name /K ProgFront
	endif
	if (last_qlt != qlt)
		Variable r, g, b
		tango_get_attr_qlt_color(qlt, r, g, b)
		TitleBox/Z attr_qlt_tb, win=$win_name, title=tango_get_attr_quality_str(qlt)
		TitleBox/Z attr_qlt_tb, win=$win_name, labelBack=(r,g,b), fStyle=1, frame=5, anchor=RT
		tmon_adjust_titleboxes_pos(win_name)
		last_qlt = qlt
	endif
	return kNO_ERROR
end
//==============================================================================
// function : tmon_image_func 
//==============================================================================
function tmon_image_func (dat_wav_path, val_path, win_name)
	Wave& dat_wav_path
	String val_path
	String win_name
	NVAR/Z qlt = $(val_path + "_qlt")
	if (! NVAR_Exists(qlt))
		Variable/G $(val_path + "_qlt") = kAttrQualityUNKNOWN
		NVAR qlt = $(val_path + "_qlt")
		return 0
	endif
	NVAR/Z last_qlt = $(val_path + "_saved_qlt")
	if (! NVAR_Exists(last_qlt))
		Variable/G $(val_path + "_saved_qlt")
		NVAR/Z last_qlt = $(val_path + "_saved_qlt")
		last_qlt = kAttrQualityUNKNOWN
	endif
	if (WaveExists(dat_wav_path) == 0 || numpnts(dat_wav_path) == 1)
		SetDrawLayer /W=$win_name /K ProgFront
		SetDrawEnv /W=$win_name fsize=16, fstyle=1, textxjust=1, textrgb=(65280,0,0), xcoord=prel, ycoord=prel
		DrawText /W=$win_name 0.5, 0.5, "ERROR READING ATTRIBUTE"
	elseif (last_qlt != qlt)
		SetDrawLayer /W=$win_name /K ProgFront
		Variable np = DimSize(dat_wav_path, 0)
		Variable nq = DimSize(dat_wav_path, 1)
		ModifyGraph /W=$win_name width={Aspect, np/nq}
	endif
	if (last_qlt != qlt)
		Variable r, g, b
		tango_get_attr_qlt_color(qlt, r, g, b)
		TitleBox/Z  attr_qlt_tb, win=$win_name, title=tango_get_attr_quality_str(qlt)
		TitleBox/Z  attr_qlt_tb, win=$win_name, labelBack=(r,g,b), fStyle=1, frame=5, anchor=RT
		tmon_adjust_titleboxes_pos(win_name)
		last_qlt = qlt
	endif
	return kNO_ERROR
end
//==============================================================================
// function : tmon_display_scalar 
//==============================================================================
static function tmon_display_scalar (wns, win_title)
	Struct TMonWinNote& wns
	String win_title
	SetScale d 0,0,"dat", $wns.wtms
	tmon_display (wns.win, win_title, wns.wdata, wns.wtms,  1)
	Label /W=$wns.win bottom "\\u#2Timestamp"
	ModifyGraph /W=$wns.win dateInfo(bottom)={0,0,0}
	TabControl tab_ctrl,win=$wns.win,pos={0,0},size={2000,50}
	TabControl tab_ctrl,win=$wns.win,proc=tmon_image_tab_proc
	TabControl tab_ctrl,win=$wns.win,font="MS Sans Serif",fSize=8
	Variable tab_id = 0
	if (wns.access == kREAD_WRITE || wns.access == kREAD_WITH_WRITE || wns.access == kWRITE)
		tab_id = 1
	endif
	TabControl tab_ctrl,win=$wns.win,tabLabel(tab_id)="Monitor Ctrl."
	TabControl tab_ctrl,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	TabControl tab_ctrl,win=$wns.win,value=0,disable=0
	TabControl tab_ctrl,win=$wns.win,proc=tmon_scalar_tab_proc
	Button reset_but,win=$wns.win,pos={8,24},size={50,20}
	Button reset_but,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button reset_but,win=$wns.win,proc=tmon_but_proc_reset,title="Reset"
	Button pause_but,win=$wns.win,pos={65,24},size={50,20},disable=0
	Button pause_but,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button pause_but,win=$wns.win,proc=tmon_but_proc_pause,title="Pause"
	Button kill_but,win=$wns.win,pos={122,24},size={50,20},title="Kill"
	Button kill_but,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button kill_but,win=$wns.win,proc=tmon_but_proc_kill
	SetVariable pp,win=$wns.win,pos={180,26},size={116,16}
	SetVariable pp,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	SetVariable pp,win=$wns.win,title="Update every",format="%g s"
	SetVariable pp,win=$wns.win,limits={kMIN_PP, kMAX_PP, kSTEP_PP}
	SetVariable pp,win=$wns.win,proc=tmon_setvar_proc_pp
	SetVariable pp,win=$wns.win, proc=tmon_setvar_proc_pp
	String attr_unit = tango_get_attr_unit(wns.dev, wns.attr)
	ValDisplay current_value,win=$wns.win,title="Current Value",format="%g " + attr_unit
	ValDisplay current_value,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	ValDisplay current_value,win=$wns.win,labelBack=(0,65280,0),frame=0,mode=2
	Execute /Q /Z "ValDisplay current_value,win=" + wns.win + ",value=#\"" + wns.val_path + "\""
	if (wns.access == kREAD_WRITE || wns.access == kREAD_WITH_WRITE || wns.access == kWRITE)
	  TabControl tab_ctrl,win=$wns.win,tabLabel(0)="Write"
	  ValDisplay current_value,pos={9,26},size={150,15}
	  SetVariable write_attr,win=$wns.win,pos={167,26},size={125,16}
	  SetVariable write_attr,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	  SetVariable write_attr,win=$wns.win,title="Write value",format="%g " + attr_unit
	  SetVariable write_attr,win=$wns.win,limits={-Inf,Inf,1},value=$wns.wrt_val
	  Button write_but,win=$wns.win,pos={300,24},size={100,20},title="Write Attribute"
	  Button write_but,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	  Button write_but,win=$wns.win,proc=tmon_but_proc_write_attr 
	  Button reset_but,win=$wns.win,disable=1
	  Button pause_but,win=$wns.win,disable=1
	  Button kill_but,win=$wns.win,disable=1
	  SetVariable pp,win=$wns.win,disable=1
	else
	  TabControl tab_ctrl,win=$wns.win,value=0,disable=2
	  ValDisplay current_value,win=$wns.win,pos={306,26},size={150,15}
	  Button reset_but,win=$wns.win,disable=0
	  Button pause_but,win=$wns.win,disable=0
	  Button kill_but,win=$wns.win,disable=0
	  SetVariable pp,win=$wns.win,disable=0
	endif
	TabControl tab_ctrl,win=$wns.win,value=0
	SetWindow $wns.win hook(main)=tmon_win_hook_scalar
	DoUpdate
end
//==============================================================================
// function : tmon_display_spectrum 
//==============================================================================
static function tmon_display_spectrum (wns, win_title)
	Struct TMonWinNote& wns
	String win_title
	tmon_display (wns.win, win_title, wns.wdata, "", 0)
	TabControl tab_ctrl,win=$wns.win,pos={0,0},size={2000,50}
	TabControl tab_ctrl,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	TabControl tab_ctrl,win=$wns.win,tabLabel(0)="Monitor Ctrl."
	TabControl tab_ctrl,win=$wns.win,value=0,disable=2
	Button pause_but,win=$wns.win,pos={6,24},size={50,20},disable=0
	Button pause_but,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button pause_but,win=$wns.win,proc=tmon_but_proc_pause,title="Pause"
	Button kill_but,win=$wns.win,pos={63,24},size={50,20},title="Kill"
	Button kill_but,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button kill_but,win=$wns.win,proc=tmon_but_proc_kill
	SetVariable pp,win=$wns.win,pos={121,26},size={116,16}
	SetVariable pp,win=$wns.win,font=$kLB_FONT,fSize=kLB_FONTSIZE
	SetVariable pp,win=$wns.win,title="Update every",format="%g s"
	SetVariable pp,win=$wns.win,limits={kMIN_PP, kMAX_PP, kSTEP_PP}
	SetVariable pp,win=$wns.win, proc=tmon_setvar_proc_pp
	SetWindow $wns.win hook(main)=tmon_win_hook_spectrum	
	DoUpdate
end
//==============================================================================
// function : tmon_display (for SCALAR & SPECTRUM ATTRS)
//==============================================================================
static function tmon_display (win_name, win_title, ywav_name, xwav_name, show_reset_but)
	String win_name
	String win_title
	String ywav_name
	String xwav_name
	Variable show_reset_but
	DoWindow/K $win_name
	if (strlen(xwav_name) != 0) 
		Display /K=1 /N=$win_name /W=(0,0,450,230) $ywav_name vs $xwav_name
	else
		Display /K=1 /N=$win_name /W=(0,0,450,230) $ywav_name
	endif
	DoWindow/T $win_name, win_title
	ModifyGraph /W=$win_name margin(top)=55,gfSize=10
	ModifyGraph /W=$win_name wbRGB=(56797,56797,56797), gbRGB=(0,0,0)
	ModifyGraph /W=$win_name rgb=(0,65280,0), gridRGB=(21760,21760,21760)
	ModifyGraph /W=$win_name grid=1, mirror=1,  minor(bottom)=1
	ModifyGraph /W=$win_name font="Arial",fSize=8
	ModifyGraph /W=$win_name axOffset(left)=-2.57143
end
//==============================================================================
// function : tmon_display_image (for IMAGE ATTRS)
//==============================================================================
static function tmon_display_image (win_name, win_title, img, img_path)
	String win_name
	String win_title
	String img
	String img_path
	DoWindow/K $win_name
	Display /K=1 /W=(0,0,400,400) /N=$win_name
	DoWindow/F $win_name
	AppendImage /W=$win_name $img_path
	ModifyImage /W=$win_name $img ctab={*,*,PlanetEarth,0}
	ModifyGraph /W=$win_name margin(top)=55,margin(right)=57
	ModifyGraph /W=$win_name axOffset(left)=-2.33333
	ModifyGraph /W=$win_name wbRGB=(56797,56797,56797),gbRGB=(0,0,0)
	ModifyGraph /W=$win_name mirror=1, minor=1
	ModifyGraph /W=$win_name font="Arial", fSize=8
	ModifyGraph /W=$win_name tickUnit(bottom)=1, tickUnit(left)=1
	DoWindow/T $win_name, win_title
	SetAxis/A/R left
	ColorScale /W=$win_name /C /N=text0 /F=0 /S=3 /B=1 /A=MC /X=44.69 /Y=-2.62 /E
	ColorScale /W=$win_name /N=text0 /E /C image=$img, heightPct=100
	String cmd_str = "ColorScale /W=" + win_name
	cmd_str += "/C/N=text0 width=7,font=\"Small Fonts\",fsize=6,minor=1"
	Execute(cmd_str)
	AppendText "\\F'Arial'\\F'Arial'\\Z08\\Z06\\Z10\\F'Arial'\\Z10\\U"
	SetWindow $win_name hook(main)=tmon_win_hook_image
	TabControl tab_ctrl,win=$win_name,pos={0,0},size={2000,50}
	TabControl tab_ctrl,win=$win_name,proc=tmon_image_tab_proc
	TabControl tab_ctrl,win=$win_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	TabControl tab_ctrl,win=$win_name,tabLabel(kTAB_PROJ)="Profiles"
	TabControl tab_ctrl,win=$win_name,tabLabel(kTAB_COLORS)="Colors"
	TabControl tab_ctrl,win=$win_name,tabLabel(kTAB_MONCTRL)="Monitor Ctrl."
	TabControl tab_ctrl,win=$win_name,value=kTAB_MONCTRL
	Button pause_but,win=$win_name,pos={7,24},size={50,20},disable=0
	Button pause_but,win=$win_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button pause_but,win=$win_name,proc=tmon_but_proc_pause,title="Pause"
	Button kill_but,win=$win_name,pos={65,24},size={50,20},title="Kill"
	Button kill_but,win=$win_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button kill_but,win=$win_name,proc=tmon_but_proc_kill,disable=0
	SetVariable pp,win=$win_name,pos={122,26},size={116,16}
	SetVariable pp,win=$win_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	SetVariable pp,win=$win_name,title="Update every",format="%g s"
	SetVariable pp,win=$win_name,limits={kMIN_PP, kMAX_PP, kSTEP_PP}
	SetVariable pp,win=$win_name,proc=tmon_setvar_proc_pp,disable=0
	Button snapshot_but,win=$win_name,pos={251,24},size={65,20},title="Snapshot"
	Button snapshot_but,win=$win_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button snapshot_but,win=$win_name,proc=tmon_but_proc_snapshot
	PopupMenu color_table_popup,win=$win_name,pos={9,24},size={139,21},bodyWidth=80
	PopupMenu color_table_popup,win=$win_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	PopupMenu color_table_popup,win=$win_name,mode=7,value= #"\"*COLORTABLEPOPNONAMES*\""
	PopupMenu color_table_popup,win=$win_name,proc=tmon_popup_proc_ctable,title="Color Table",disable=1
	CheckBox reverse_ct_cb,win=$win_name,pos={157,28},size={58,14}
	CheckBox reverse_ct_cb,win=$win_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	CheckBox reverse_ct_cb,win=$win_name,title="Reverse",value=0 
	CheckBox reverse_ct_cb,win=$win_name,proc=tmon_cb_proc_reverse,disable=1
	CheckBox profile_cb,win=$win_name,pos={10,28},size={88,14}
	CheckBox profile_cb,win=$win_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	CheckBox profile_cb,win=$win_name,title="Enable Profiles",value=0 
	CheckBox profile_cb,win=$win_name,proc=tmon_cb_proc_profiles,disable=1
	CheckBox attach_profile_cb,win=$win_name,pos={108,28},size={88,14}
	CheckBox attach_profile_cb,win=$win_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	CheckBox attach_profile_cb,win=$win_name,title="Attach Profiles ",value=1 
	CheckBox attach_profile_cb,win=$win_name,proc=tmon_cb_proc_attach_profiles,disable=1
	DoUpdate
end
//==============================================================================
// function : tmon_display_profile
//==============================================================================
static function tmon_display_profile (iwin_name, pwin_name, win_title, wav_path, ptype)
	String iwin_name
	String pwin_name
	String win_title
	String wav_path
	Variable ptype
	GetWindow $iwin_name wsize
	Variable l, r, t, b 
	Variable hh = (V_bottom - V_top) / 3 
	switch (ptype)
		case kTMON_IMAGE_XP:
			l = V_right + 5
			t = V_top
			r = V_right + 390
			b = V_top + hh - 15
			break
		case kTMON_IMAGE_YP:
			l = V_right + 5
			t = V_top + hh + 5
			r = V_right + 390
			b = V_top +  2 * hh - 10
			break
		case kTMON_IMAGE_FP:
			l = V_right + 5
			t = V_top + 2 * hh + 10 
			r = V_right + 390
			b = V_top +  3 * hh
			break
	endswitch
	Display /K=1 /W=(l, t, r, b) /N=$pwin_name $wav_path
	DoWindow/T $pwin_name, win_title
	ModifyGraph /W=$pwin_name gfSize=10,wbRGB=(56797,56797,56797)
	switch (ptype)
		case kTMON_IMAGE_XP:
		case kTMON_IMAGE_YP:
			ModifyGraph /W=$pwin_name rgb=(0,0,40000)
			break
		case kTMON_IMAGE_FP:
			ModifyGraph /W=$pwin_name rgb=(0,40000,0)
			break
	endswitch			
	ModifyGraph /W=$pwin_name grid=1, mirror=1, font="Arial", minor(bottom)=1
	ModifyGraph /W=$pwin_name fSize=8, axOffset(left)=-2.57143,axOffset(bottom)=-1.23077
	ModifyGraph /W=$pwin_name gridRGB=(56576,56576,56576)
	ControlBar /W=$pwin_name 25
	PopupMenu fit_popup,win=$pwin_name,pos={72,1},size={143,21},title="Fit Type"
	PopupMenu fit_popup,win=$pwin_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	PopupMenu fit_popup,win=$pwin_name,mode=1,bodyWidth= 100,popvalue="Gaussian"
	PopupMenu fit_popup,win=$pwin_name,value= #"\"Gaussian;Lorentzian\""
	Button fit_but,win=$pwin_name,pos={225,1},size={50,21},title="Fit"
	Button fit_but,win=$pwin_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button fit_but,win=$pwin_name,proc=tmon_but_proc_fit
	Button rem_fit_but,win=$pwin_name,pos={285,1},size={80,21},title="Remove Fit"
	Button rem_fit_but,win=$pwin_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button rem_fit_but,win=$pwin_name,proc=tmon_but_proc_remove_fit
	Button pause_but,win=$pwin_name,pos={2,1},size={60,21},title="Pause"
	Button pause_but,win=$pwin_name,font=$kLB_FONT,fSize=kLB_FONTSIZE
	Button pause_but,win=$pwin_name,proc=tmon_but_proc_pause
	SetWindow $pwin_name hook(main)=tmon_win_hook_profile
	DoUpdate
end
//==============================================================================
// function : tmon_pmenu_proc_ctable
//==============================================================================
function tmon_popup_proc_ctable (pua)
	STRUCT WMPopupAction &pua
	if (pua.eventCode != 2)
		return kNO_ERROR
	endif
	String image = tmon_get_value_name(pua.win)
	ControlInfo /W=$pua.win reverse_ct_cb
	ModifyImage /W=$pua.win $image ctab={*, *, $pua.popStr, V_Value}
end
//==============================================================================
// function : tmon_cb_proc_reverse
//==============================================================================
function tmon_cb_proc_reverse (cba)
	STRUCT WMCheckboxAction &cba
	if (cba.eventCode != 2)
		return kNO_ERROR
	endif
	String image = tmon_get_value_name(cba.win)
	Variable mode = cba.checked
	ControlInfo /W=$cba.win reverse_ct_cb
	ModifyImage /W=$cba.win $image ctab={*, *, $S_Value, mode}
end
//==============================================================================
// function : tmon_cb_proc_profiles
//==============================================================================
function tmon_cb_proc_profiles (cba)
	STRUCT WMCheckboxAction &cba
	if (cba.eventCode != 2)
		return kNO_ERROR
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(cba.win, wns)
	if (cba.checked)
		Checkbox attach_profile_cb, win=$cba.win, disable=0
		tmon_open_profiles(cba.win)
	else
		Checkbox attach_profile_cb, win=$cba.win, disable=1
		tmon_kill_profiles(cba.win)
	endif
end
//==============================================================================
// function : tmon_cb_proc_attach_profiles
//==============================================================================
function tmon_cb_proc_attach_profiles (cba)
	STRUCT WMCheckboxAction &cba
	if (cba.eventCode != 2)
		return kNO_ERROR
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(cba.win, wns)
	wns.pattached = cba.checked
	tmon_set_win_note(cba.win, wns)
	tmon_attach_profiles(cba.win)
end
//==============================================================================
// function : tmon_open_profiles
//==============================================================================
function tmon_open_profiles (win_name)
	String win_name
	Struct TMonWinNote wns
	tmon_get_win_note(win_name, wns)
	String wl_xp = WinList(wns.xp_win, ";", "WIN:1")
	String wl_yp = WinList(wns.xp_win, ";", "WIN:1")
	if (strlen(wl_xp) || strlen(wl_yp))
		tmon_kill_profiles(win_name)
	endif
	Variable nx = DimSize($wns.val_path, 0)
	Variable ny = DimSize($wns.val_path, 1)
	if (nx == 1 && ny == 1)
		print "Tango-Binding::can't open profile tools till the monitor update the image!"
		Checkbox profile_cb, win=$win_name, value=0
		return 0
	endif
	tango_monitor_suspend(wns.dev, wns.attr, cid = wns.cid)
	String ldf
	tango_enter_attr_df (wns.dev, wns.attr, prev_df=ldf)
	SetDataFolder :monitor
	wns.xp = wns.val_path + "_xp"
	Make/O/D/N=0 $wns.xp
	wns.xp_dep = wns.xp + "_dv"
	Variable/G $wns.xp_dep
	wns.yp = wns.val_path + "_yp"
	Make/O/D/N=0 $wns.yp
	wns.yp_dep = wns.yp + "_dv"
	Variable/G $wns.yp_dep
	wns.fp = wns.val_path + "_fp"
	Make/O/D/N=0 $wns.fp
	wns.fp_dep = wns.fp + "_dv"
	Variable/G $wns.fp_dep
	wns.xyp_uv = wns.val_path + "_xyp_uv"
	Variable/G $wns.xyp_uv
	wns.fp_uv = wns.val_path + "_fp_uv"
	Variable/G $wns.fp_uv
	String xp_formula
	xp_formula = "tmon_xprofile(" + wns.val_path + ",\"" + wns.xp + "\",\"" + win_name + "\"," + wns.xyp_uv + ")"
	String yp_formula
	yp_formula = "tmon_yprofile(" + wns.val_path + ",\"" + wns.yp + "\",\"" + win_name + "\"," + wns.xyp_uv + ")"
	String fp_formula
	fp_formula = "tmon_fprofile(" + wns.val_path + ",\"" + wns.fp + "\",\"" + win_name + "\"," + wns.fp_uv + ")"
	String win_title_base =wns.dev + "/" +wns.attr
	String xpwin_name = wns.val + "_xp_mon"
	xpwin_name = UniqueName(xpwin_name, 6, 0)
	wns.xp_win = xpwin_name
	tmon_display_profile(win_name, xpwin_name, win_title_base + "::x-profile", wns.xp, kTMON_IMAGE_XP)
	String ypwin_name = wns.val + "_yp_mon"
	ypwin_name = UniqueName(ypwin_name, 6, 0)
	wns.yp_win = ypwin_name
	tmon_display_profile(win_name, ypwin_name, win_title_base + "::y-profile", wns.yp, kTMON_IMAGE_YP)
	String fpwin_name = wns.val + "_fp_mon"
	fpwin_name = UniqueName(fpwin_name, 6, 0)
	wns.fp_win = fpwin_name
	tmon_display_profile(win_name, fpwin_name, win_title_base + "::f-profile", wns.fp, kTMON_IMAGE_FP)
	wns.type = kTMON_IMAGE
	tmon_set_win_note(win_name, wns)
	wns.type = kTMON_IMAGE_XP
	tmon_set_win_note(xpwin_name, wns)
	wns.type = kTMON_IMAGE_YP
	tmon_set_win_note(ypwin_name, wns)
	wns.type = kTMON_IMAGE_FP
	tmon_set_win_note(fpwin_name, wns)
	Cursor /I/A=1/C=(65535,0,0)/H=1/L=1/P/S=1/W=$win_name A, $wns.val, 0.025 * nx , 0.025 * ny
	Cursor /I/A=1/C=(65535,0,0)/H=1/L=1/P/S=1/W=$win_name B, $wns.val, 0.975 * nx , 0.975 * ny
	Cursor /I/A=1/C=(0,65535,0)/H=0/L=1/P/S=1/W=$win_name C, $wns.val, 0.100 * nx , 0.500 * ny
	Cursor /I/A=1/C=(0,65535,0)/H=0/L=1/P/S=1/W=$win_name D, $wns.val, 0.900 * nx , 0.500 * ny
	ShowInfo /W=$win_name
	DoWindow/F $win_name
	SetFormula $wns.xp_dep, xp_formula
	SetFormula $wns.yp_dep, yp_formula
	SetFormula $wns.fp_dep, fp_formula
	tmon_draw_profiles_tools(win_name)
	DoUpdate
	if (wns.status == kTMON_RUNNING)
		tango_monitor_resume(wns.dev, wns.attr, cid = wns.cid)
	endif
	tango_leave_df(ldf)
end
//==============================================================================
// function : tmon_kill_profiles
//==============================================================================
function tmon_kill_profiles (win_name)
	String win_name
	tmon_kill_fprofile(win_name, kill_win = 1)
	tmon_kill_yprofile(win_name, kill_win = 1)
	tmon_kill_xprofile(win_name, kill_win = 1)
	SetDrawLayer /W=$win_name /K UserFront
	CheckBox profile_cb, win=$win_name, value=0
	CheckBox attach_profile_cb, win=$win_name, disable=1
	HideInfo /W=$win_name
end	
//==============================================================================
// function : tmon_kill_xprofile
//==============================================================================
function tmon_kill_xprofile (win_name, [kill_win])
	String win_name
	Variable kill_win 
	if (ParamIsDefault(kill_win))
		kill_win = 1
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(win_name, wns)
	tango_monitor_suspend(wns.dev, wns.attr, cid = wns.cid)
	String ldf
	tango_enter_attr_df (wns.dev, wns.attr, prev_df=ldf)
	SetDataFolder :monitor
	String dep_var_name = tools_full_obj_path_to_obj_name (wns.xp_dep)
	NVAR/Z xp_dep_var = $dep_var_name
	if (NVAR_Exists(xp_dep_var))
		SetFormula xp_dep_var, ""
		KillVariables/Z $dep_var_name
	endif
	KillWaves/Z $wns.xp
	wns.xp = ""
	wns.xp_dep = ""
	String xp_win = wns.xp_win
	wns.xp_win = ""
	tmon_set_win_note(wns.win, wns)
	if (kill_win && strlen(WinList(xp_win, ";", "WIN:1")))
		DoWindow/K $xp_win
	endif
	Variable has_yp = strlen(wns.yp_win) > 0
	if (! has_yp)
		KillVariables/Z $wns.xyp_uv
		wns.xyp_uv = ""
		Cursor /W=$win_name/K A
		Cursor /W=$win_name/K B
		tmon_draw_profiles_tools(win_name)
	endif
	if (wns.status == kTMON_RUNNING)
		tango_monitor_resume(wns.dev, wns.attr, cid = wns.cid)
	endif
	tango_leave_df(ldf)
end
//==============================================================================
// function : tmon_kill_yprofile
//==============================================================================
function tmon_kill_yprofile (win_name, [kill_win])
	String win_name
	Variable kill_win 
	if (ParamIsDefault(kill_win))
		kill_win = 1
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(win_name, wns)
	tango_monitor_suspend(wns.dev, wns.attr, cid = wns.cid)
	String ldf
	tango_enter_attr_df (wns.dev, wns.attr, prev_df=ldf)
	SetDataFolder :monitor
	String dep_var_name = tools_full_obj_path_to_obj_name (wns.yp_dep)
	NVAR/Z yp_dep_var = $dep_var_name
	if (NVAR_Exists(yp_dep_var))
		SetFormula yp_dep_var, ""
		KillVariables/Z $dep_var_name
	endif
	KillWaves/Z $wns.yp
	wns.yp = ""
	wns.yp_dep = ""
	String yp_win = wns.yp_win
	wns.yp_win = ""
	tmon_set_win_note(wns.win, wns)
	if (kill_win && strlen(WinList(yp_win, ";", "WIN:1")))
		DoWindow/K $yp_win
	endif
	Variable has_xp = strlen(wns.xp_win) > 0
	if (! has_xp)
		KillVariables/Z $wns.xyp_uv
		wns.xyp_uv = ""
		Cursor /W=$win_name/K A
		Cursor /W=$win_name/K B
		tmon_draw_profiles_tools(win_name)
	endif
	if (wns.status == kTMON_RUNNING)
		tango_monitor_resume(wns.dev, wns.attr, cid = wns.cid)
	endif
	tango_leave_df(ldf)
end
//==============================================================================
// function : tmon_kill_fprofile
//==============================================================================
function tmon_kill_fprofile (win_name, [kill_win])
	String win_name
	Variable kill_win 
	if (ParamIsDefault(kill_win))
		kill_win = 1
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(win_name, wns)
	tango_monitor_suspend(wns.dev, wns.attr, cid = wns.cid)
	String ldf
	tango_enter_attr_df (wns.dev, wns.attr, prev_df=ldf)
	SetDataFolder :monitor
	String dep_var_name = tools_full_obj_path_to_obj_name (wns.fp_dep)
	NVAR/Z fp_dep_var = $dep_var_name
	if (NVAR_Exists(fp_dep_var))
		SetFormula fp_dep_var, ""
		KillVariables/Z $dep_var_name
	endif
	KillWaves/Z $wns.fp
	KillVariables/Z $wns.fp_uv
	wns.fp = ""
	wns.fp_dep = ""
	wns.fp_uv = ""
	String fp_win = wns.fp_win
	wns.fp_win = ""
	tmon_set_win_note(wns.win, wns)
	if (kill_win && strlen(WinList(fp_win, ";", "WIN:1")))
		DoWindow/K $fp_win
	endif
	Cursor /W=$win_name /K C
	Cursor /W=$win_name /K D
	tmon_draw_profiles_tools(win_name)
	if (wns.status == kTMON_RUNNING)
		tango_monitor_resume(wns.dev, wns.attr, cid = wns.cid)
	endif
	tango_leave_df(ldf)
end
//==============================================================================
// function : tmon_xprofile
//==============================================================================
function tmon_xprofile (src, dest_path, iwin, uv)
	Wave src
	String dest_path
	String iwin
	Variable uv
	if (strlen(dest_path) == 0)
		print "Tango-Binding::fatal error in tmon_xprofile [empty string]"
		tmon_abort ()
		return kNO_ERROR
	endif
	Wave/Z dest = $dest_path
	if (GetRTError(0) || WaveExists(dest) == 0)
		print "Tango-Binding::fatal error in tmon_xprofile [wave missing]"
		tmon_abort ()
		return kNO_ERROR
	endif
	if (WaveExists(src) == 0 || numpnts(src) == 0)
		dest = NAN
		return 0
	endif
	Variable csrA_x, csrA_y
	if (! strlen(CsrWave(A, iwin)))
		csrA_x = 0
		csrA_y = 0
	else
		csrA_x = pcsr(A, iwin)
		csrA_y = qcsr(A, iwin)
	endif
	Variable csrB_x, csrB_y
	if (! strlen(CsrWave(B, iwin)))
		csrB_x = DimSize(src, 0)
		csrB_y = DimSize(src, 1)
	else
		csrB_x = pcsr(B, iwin)
		csrB_y = qcsr(B, iwin)
	endif
	if (tango_compute_image_proj(src, dest, 0, csrA_x, csrA_y, csrB_x, csrB_y) == -1)
		tango_print_error()
		return kERROR
	endif 
	return kNO_ERROR
end
//==============================================================================
// function : tmon_yprofile
//==============================================================================
function tmon_yprofile (src, dest_path, iwin, uv)
	Wave src
	String dest_path
	String iwin
	Variable uv
	if (strlen(dest_path) == 0)
		print "Tango-Binding::fatal error in tmon_xprofile [empty string]"
		tmon_abort ()
		return kNO_ERROR
	endif
	Wave/Z dest = $dest_path
	if (GetRTError(0) || WaveExists(dest) == 0)
		print "Tango-Binding::fatal error in tmon_xprofile [wave missing]"
		tmon_abort ()
		return kNO_ERROR
	endif
	if (WaveExists(src) == 0 || numpnts(src) == 0)
		dest = NAN
		return 0
	endif
	Variable csrA_x, csrA_y
	if (! strlen(CsrWave(A, iwin)))
		csrA_x = 0
		csrA_y = 0
	else
		csrA_x = pcsr(A, iwin)
		csrA_y = qcsr(A, iwin)
	endif
	Variable csrB_x, csrB_y
	if (! strlen(CsrWave(B, iwin)))
		csrB_x = DimSize(src, 0)
		csrB_y = DimSize(src, 1)
	else
		csrB_x = pcsr(B, iwin)
		csrB_y = qcsr(B, iwin)
	endif
	Variable min_x = min(csrA_x, csrB_x)
	Variable max_x = max(csrA_x, csrB_x)
	Variable min_y = min(csrA_y, csrB_y)
	Variable max_y = max(csrA_y, csrB_y)
	if (tango_compute_image_proj(src, dest, 1, min_x, min_y, max_x, max_y) == -1)
		tango_print_error()
		return kERROR
	endif 
	return kNO_ERROR
end
//==============================================================================
// function : tmon_fprofile
//==============================================================================
function tmon_fprofile (src, dest_path, iwin, uv)
	Wave src
	String dest_path
	String iwin
	Variable uv
	if (strlen(dest_path) == 0)
		print "Tango-Binding::fatal error in tmon_xprofile [empty string]"
		tmon_abort ()
		return kNO_ERROR
	endif
	Wave/Z dest = $dest_path
	if (GetRTError(0) || WaveExists(dest) == 0)
		print "Tango-Binding::fatal error in tmon_xprofile [wave missing]"
		tmon_abort ()
		return kNO_ERROR
	endif
	if (WaveExists(src) == 0 || numpnts(src) == 0)
		dest = NAN
		return 0
	endif
	Variable csrC_x, csrC_y
	if (! strlen(CsrWave(C, iwin)))
		dest = NAN
		return 0
	else
		csrC_x = pcsr(C, iwin)
		csrC_y = qcsr(C, iwin)
	endif
	Variable csrD_x, csrD_y
	if (! strlen(CsrWave(D, iwin)))
		dest = NAN
		return 0
	else
		csrD_x = pcsr(D, iwin)
		csrD_y = qcsr(D, iwin)
	endif
	Variable csr_min_x = min(csrC_x, csrD_x)
	Variable csr_max_x = max(csrC_x, csrD_x)
	Variable csr_min_y = min(csrC_y, csrD_y)
	Variable csr_max_y = max(csrC_y, csrD_y)
	Make/O/N=2 xtrace={csr_min_x,csr_max_x}, ytrace={csr_min_y,csr_max_y}
	ImageLineProfile srcWave=src, xWave=xtrace, yWave=ytrace, width=1
	KillWaves/Z xtrace, ytrace
	Wave/Z profile = W_ImageLineProfile
	if (! WaveExists(profile))
		dest = 0
		return 0
	endif
	Duplicate /O profile, dest
	KillWaves/Z W_ImageLineProfile, W_LineProfileX, W_LineProfileY
	return kNO_ERROR
end
//==============================================================================
// function : tmon_scalar_tab_proc
//==============================================================================
function tmon_scalar_tab_proc (tca)
	Struct WMTabControlAction &tca
	switch (tca.tab)
		case 0:
			ValDisplay current_value,win=$tca.win,pos={9,26},size={150,15}
			SetVariable write_attr,win=$tca.win,disable=0
	  		Button write_but,win=$tca.win,disable=0
	  		Button reset_but,win=$tca.win,disable=1
	  		Button pause_but,win=$tca.win,disable=1
	  		Button kill_but,win=$tca.win,disable=1
	  		SetVariable pp,win=$tca.win,disable=1
			break
		case 1:
	 		ValDisplay current_value,win=$tca.win,pos={306,26},size={150,15}
	 		SetVariable write_attr,win=$tca.win,disable=1
	  		Button write_but,win=$tca.win,disable=1
	  		Button reset_but,win=$tca.win,disable=0
	  		Button pause_but,win=$tca.win,disable=0
	  		Button kill_but,win=$tca.win,disable=0
	  		SetVariable pp,win=$tca.win,disable=0
			break
	endswitch
end
//==============================================================================
// function : tmon_image_tab_proc
//==============================================================================
function tmon_image_tab_proc (tca)
	Struct WMTabControlAction &tca
	switch (tca.tab)
		case kTAB_PROJ:
			Button pause_but, win=$tca.win, disable=1
			Button kill_but, win=$tca.win, disable=1
			SetVariable pp, win=$tca.win, disable=1
			Button snapshot_but, win=$tca.win, disable=1
			PopupMenu color_table_popup, win=$tca.win, disable=1
			CheckBox reverse_ct_cb, win=$tca.win, disable=1
			CheckBox profile_cb, win=$tca.win, disable=0
			CheckBox attach_profile_cb, win=$tca.win, disable=0
			ControlInfo /W=$tca.win profile_cb
			Variable but_state = (V_Value == 1) ? 0 : 1
			CheckBox attach_profile_cb, win=$tca.win, disable=0
			break
		case kTAB_COLORS:
			Button pause_but, win=$tca.win, disable=1
			Button kill_but, win=$tca.win, disable=1
			SetVariable pp, win=$tca.win, disable=1
			Button snapshot_but, win=$tca.win, disable=1
			PopupMenu color_table_popup, win=$tca.win, disable=0
			CheckBox reverse_ct_cb, win=$tca.win, disable=0
			CheckBox profile_cb, win=$tca.win, disable=1
			CheckBox attach_profile_cb, win=$tca.win, disable=1
			break
		case kTAB_MONCTRL:
			Button pause_but, win=$tca.win, disable=0
			Button kill_but, win=$tca.win, disable=0
			SetVariable pp, win=$tca.win, disable=0
			Button snapshot_but, win=$tca.win, disable=0
			PopupMenu color_table_popup, win=$tca.win, disable=1
			CheckBox reverse_ct_cb, win=$tca.win, disable=1
			CheckBox profile_cb, win=$tca.win, disable=1
			CheckBox attach_profile_cb, win=$tca.win, disable=1
			break
	endswitch
end
//==============================================================================
// function : tmon_but_proc_fit
//==============================================================================
function tmon_but_proc_fit(ba)
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return kNO_ERROR
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(ba.win, wns)
	tango_monitor_suspend(wns.dev, wns.attr, cid = wns.cid)
	String ldf
	tango_enter_attr_df(wns.dev, wns.attr, prev_df=ldf)
	SetDataFolder :monitor
	String pt_str
	String target_wave_path
	switch (wns.type)
		case kTMON_IMAGE_XP:
	  		pt_str = "X Profile"
	  		target_wave_path = wns.xp
	  		break
		case kTMON_IMAGE_YP:
	  		pt_str = "Y Profile"
	  		target_wave_path = wns.yp
	  		break
		case kTMON_IMAGE_FP:
	  		pt_str = "F Profile"
	  		target_wave_path = wns.fp
	  		break
	  	default:
	  		return kNO_ERROR
	  		break
	endswitch
	print "Tango-Binding::fitting " + pt_str + " of " + wns.dev + "/" + wns.attr + " ****"
	ControlInfo /W=$ba.win fit_popup
	if (V_Value == 1)
		CurveFit /W=0 /N gauss $target_wave_path /D 
	else
		CurveFit /W=0 /N lor $target_wave_path /D
	endif
	String tl = TraceNameList(ba.win, ";", 1)
	String profile_trace = StringFromList(0, tl)
	String fit_trace = StringFromList(1, tl)
	String legend_str = "\\Z08" 
	legend_str += "\\s(" + profile_trace + ")" + pt_str + "\r"
	if (V_Value == 1)
		Wave wcoef = :W_coef
		legend_str += "\\s(" + fit_trace + ")Gaussian Fit : W=" + num2str(2 * wcoef[3])
	else
		legend_str += "\\s(" + fit_trace + ")Lorentzian Fit"
	endif	
	Legend /A=LT /W=$ba.win /C /N=tlegend /X=2 /Y=2 legend_str	
	if (tmon_get_status(wns.win) == kTMON_RUNNING)
		tango_monitor_resume(wns.dev, wns.attr, cid = wns.cid)
	endif
	KillWaves/Z :W_coef, :W_sigma 
	tango_leave_df(ldf)
	return kNO_ERROR
end
//==============================================================================
// function : tmon_but_proc_remove_fit
//==============================================================================
function tmon_but_proc_remove_fit (ba)
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return kNO_ERROR
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(ba.win, wns)
	String ldf
	tango_enter_attr_df(wns.dev, wns.attr, prev_df=ldf)
	SetDataFolder :monitor
	String profile_wave_name 
	switch (wns.type)
		case kTMON_IMAGE_XP:
	  		profile_wave_name = wns.xp
	  		break
		case kTMON_IMAGE_YP:
			profile_wave_name = wns.yp
			break
		case kTMON_IMAGE_FP:
	  		profile_wave_name = wns.fp
	  		break
	  	default:
	  		return kNO_ERROR
	  		break
	endswitch
	Wave profile_wave = $profile_wave_name
	String fit_wname = "fit_" + NameOfWave(profile_wave)
	RemoveFromGraph /W=$ba.win /Z $fit_wname
	Legend /K /W=$ba.win /N=tlegend
	tango_leave_df(ldf)
end
//==============================================================================
// function : tmon_but_proc_reset
//==============================================================================
function tmon_but_proc_reset (ba)
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return kNO_ERROR
	endif
	Variable attr_format = tmon_get_format(ba.win)
	if (attr_format != kSCALAR)
		return kNO_ERROR
	endif
	WAVE/Z w = $tmon_get_data_wave(ba.win)
	if (WAVEExists(w) == 0)
		return kNO_ERROR
	endif
	w = NAN
	WAVE/Z ts = $tmon_get_timestamp_wave(ba.win)
	if (WAVEExists(ts))
		ts = NAN	
	endif
end
//==============================================================================
// function : tmon_but_proc_pause 
//==============================================================================
function tmon_but_proc_pause (ba)
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return kNO_ERROR
	endif
	String ldf
	Struct TMonWinNote wns
	tmon_get_win_note(ba.win, wns)
	if (tango_enter_device_df(wns.dev, prev_df=ldf) == kERROR)
		return kERROR
	endif
	if (tmon_get_status(ba.win) == kTMON_PAUSED)
		tango_monitor_resume(wns.dev, wns.attr, cid = wns.cid)
		if (strlen(wns.win) && strlen(WinList(wns.win, ";", "WIN:1")))
			Button pause_but, win=$wns.win, title="Pause"
			tmon_set_status(wns.win, kTMON_RUNNING)
		endif
		if (strlen(wns.xp_win)&& strlen(WinList(wns.xp_win, ";", "WIN:1")))
			Button pause_but, win=$wns.xp_win, title="Pause"
			tmon_set_status(wns.xp_win, kTMON_RUNNING)
		endif
		if (strlen(wns.yp_win) && strlen(WinList(wns.yp_win, ";", "WIN:1")))
			Button pause_but, win=$wns.yp_win, title="Pause"
			tmon_set_status(wns.yp_win, kTMON_RUNNING)
		endif
		if (strlen(wns.fp_win) && strlen(WinList(wns.fp_win, ";", "WIN:1")))
			Button pause_but, win=$wns.fp_win, title="Pause"
			tmon_set_status(wns.fp_win, kTMON_RUNNING)
		endif
	else
		tango_monitor_suspend(wns.dev, wns.attr, cid = wns.cid)
		if (strlen(wns.win) && strlen(WinList(wns.win, ";", "WIN:1")))
			Button pause_but, win=$wns.win, title="Resume"
			tmon_set_status(wns.win, kTMON_PAUSED)
		endif
		if (strlen(wns.xp_win)&& strlen(WinList(wns.xp_win, ";", "WIN:1")))
			Button pause_but, win=$wns.xp_win, title="Resume"
			tmon_set_status(wns.xp_win, kTMON_PAUSED)
		endif
		if (strlen(wns.yp_win) && strlen(WinList(wns.yp_win, ";", "WIN:1")))
			Button pause_but, win=$wns.yp_win, title="Resume"
			tmon_set_status(wns.yp_win, kTMON_PAUSED)
		endif
		if (strlen(wns.fp_win) && strlen(WinList(wns.fp_win, ";", "WIN:1")))
			Button pause_but, win=$wns.fp_win, title="Resume"
			tmon_set_status(wns.fp_win, kTMON_PAUSED)
		endif
	endif	
	tango_leave_df(ldf)
end
//==============================================================================
// function : tmon_but_proc_snapshot
//==============================================================================
function tmon_but_proc_snapshot (ba)
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return kNO_ERROR
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(ba.win, wns)
	String cur_df = GetDataFolder(1) 
	tools_df_make("root:snapshots:" + wns.dev, 1)
	String dest_wave_name = UniqueName(wns.attr + "_", 1, 0) 
	Duplicate $wns.val_path, $dest_wave_name
	print "Tango-Binding::monitor snapshot::data saved to " + GetDataFolder(1) + dest_wave_name
	SetDataFolder cur_dF
end
//==============================================================================
// function : tmon_but_proc_kill 
//==============================================================================
function tmon_but_proc_kill (ba)
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return kNO_ERROR
	endif
	SetWindow $ba.win, hook=$"", hookevents=0
	tmon_kill(ba.win, kill_win = 1)
end
//==============================================================================
// function :  tmon_but_proc_write_attr
//==============================================================================
function tmon_but_proc_write_attr (ba)
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return kNO_ERROR
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(ba.win, wns)
	String ldf
	tango_enter_attr_df(wns.dev, wns.attr, prev_df=ldf)
	SetDataFolder :monitor
	String attr = wns.attr
	if (wns.access == kREAD_WITH_WRITE)
		attr = wns.wrt_attr
	endif
	if (tango_write_attribute(wns.dev, attr, wns.wrt_val) == kERROR)
		tango_display_error()
	endif 
	tango_leave_df(ldf)
end
//==============================================================================
// function : tmon_but_proc_attach_profiles
//==============================================================================
function tmon_but_proc_attach_profiles (ba)
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return kNO_ERROR
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(ba.win, wns)
	tmon_attach_profiles(ba.win)
end
//==============================================================================
// function :  tmon_setvar_proc_pp 
//==============================================================================
function tmon_setvar_proc_pp (sva)
	STRUCT WMSetVariableAction &sva
	if (sva.eventCode != 1 && sva.eventCode != 2)
		return kNO_ERROR
	endif
	Struct TMonWinNote wns
	tmon_get_win_note(sva.win, wns)
	if (tango_monitor_set_period(wns.dev, wns.attr, 1.E3 * sva.dval, cid = wns.cid) == kERROR)
		tango_display_error()
	endif 
end
//==============================================================================
// function : tmon_win_hook_scalar
//==============================================================================
function tmon_win_hook_scalar (whs)
	STRUCT WMWinHookStruct &whs
	Variable evt_handled = 1
	switch (whs.eventCode)
		//- win killed
		case 2:
			Struct TMonWinNote wns
		   tmon_get_win_note (whs.winname, wns)
		   if (! wns.kill_win)
				tmon_kill(whs.winname, kill_win = 1)
			endif
			break
		//- win resized
		case 6:
			tmon_attach_profiles(whs.winname)
			tmon_win_set_last_evt(whs.winname, whs.eventCode)
			tmon_adjust_titleboxes_pos(whs.winname)
			break
		//- win resized or moved
		default:
			evt_handled = 0
			break
	endswitch
	return evt_handled				
end 
//==============================================================================
// function : tmon_win_hook_spectrum
//==============================================================================
function tmon_win_hook_spectrum (whs)
	STRUCT WMWinHookStruct &whs
	Variable evt_handled = 1
	switch (whs.eventCode)
		//- win killed
		case 2:
			Struct TMonWinNote wns
		   tmon_get_win_note (whs.winname, wns)
		   if (! wns.kill_win)
				tmon_kill(whs.winname, kill_win = 1)
			endif
			break
		//- win resized
		case 6:
			tmon_adjust_titleboxes_pos(whs.winname)
			break
		//- win resized or moved
		default:
			evt_handled = 0
			break
	endswitch
	return evt_handled				
end 
//==============================================================================
// function : tmon_win_hook_image
//==============================================================================
function tmon_win_hook_image (whs)
	STRUCT WMWinHookStruct &whs
	Variable evt_handled = 1
	switch (whs.eventCode)
		//- win activated
		case 0:
			if (tmon_win_get_last_evt(whs.winname) != 0)
				Struct TMonWinNote wns
				tmon_get_win_note (whs.winname, wns)
				Variable has_xp = strlen(wns.xp_win) > 0
				Variable has_yp = strlen(wns.yp_win) > 0
				Variable has_fp = strlen(wns.fp_win) > 0
				if (has_xp)
					DoWindow /F $wns.xp_win
				endif
				if (has_yp)
					DoWindow /F $wns.yp_win
				endif
				if (has_fp)
					DoWindow /F $wns.fp_win
				endif
				if (has_xp || has_yp || has_fp)
					DoWindow /F $whs.winname
					tmon_attach_profiles(whs.winname)
				endif
			endif
			tmon_win_set_last_evt(whs.winname, whs.eventCode)
			break
		//- win killed
		case 2:
		   tmon_get_win_note (whs.winname, wns)
		   if (! wns.kill_win)
				tmon_kill(whs.winname, kill_win = 1)
			endif
			break
		//- win  moved
		case 12:
			tmon_attach_profiles(whs.winname)
			tmon_win_set_last_evt(whs.winname, whs.eventCode)
			break
		//- win resized
		case 6:
			tmon_attach_profiles(whs.winname)
			tmon_win_set_last_evt(whs.winname, whs.eventCode)
			tmon_adjust_titleboxes_pos(whs.winname)
			break
		//- cursor moved
		case 7:
			if (tools_point_in_rect(whs.mouseLoc, whs.winRect) && tmon_draw_profiles_tools(whs.winname))
				tmon_get_win_note (whs.winname, wns)
				if (whs.cursorName[0] == kCSR_A || whs.cursorName[0] == kCSR_B)
					NVAR/Z xyp_uv = $wns.xyp_uv	
					if (NVAR_Exists(xyp_uv))
						xyp_uv += 1
					endif
				elseif (whs.cursorName[0] == kCSR_C || whs.cursorName[0] == kCSR_D)
					NVAR/Z fp_uv = $wns.fp_uv	
					if (NVAR_Exists(fp_uv))
						fp_uv += 1
					endif
				endif
				DoXOPIdle
				DoUpdate
			endif
			tmon_win_set_last_evt(whs.winname, whs.eventCode)
			break
		default:
			evt_handled = 0
			tmon_win_set_last_evt(whs.winname, whs.eventCode)
			break
	endswitch
	return evt_handled				
end 
//==============================================================================
// function : tmon_win_hook_profile
//==============================================================================
function tmon_win_hook_profile (whs)
	STRUCT WMWinHookStruct &whs
	Variable evt_handled = 1
	Struct TMonWinNote pwns
	tmon_get_win_note (whs.winName, pwns)
	Variable last_evt = tmon_win_get_last_evt(whs.winname)
	if (last_evt == 12 && whs.eventCode != 12)
		tmon_attach_profiles(pwns.win)
	endif
	switch (whs.eventCode)
		//- win killed
		case 2:
			Variable type = tmon_get_win_type(whs.winname)
			if (type == kTMON_IMAGE_XP)
				tmon_kill_xprofile(pwns.win)
			elseif (type == kTMON_IMAGE_YP)
				tmon_kill_yprofile(pwns.win)		
			elseif (type == kTMON_IMAGE_FP)
				tmon_kill_fprofile(pwns.win)		
			endif
			Struct TMonWinNote iwns
			tmon_get_win_note (pwns.win, iwns)
			Variable has_xp = strlen(iwns.xp_win) > 0
			Variable has_yp = strlen(iwns.yp_win) > 0
			Variable has_fp = strlen(iwns.fp_win) > 0
			if (has_xp || has_yp || has_fp)
				tmon_attach_profiles(iwns.win)
			else
				SetDrawLayer /W=$pwns.win /K UserFront
				CheckBox profile_cb, win=$pwns.win, value=0
				CheckBox attach_profile_cb, win=$pwns.win, disable=1
				HideInfo /W=$pwns.win
			endif
			break
		default:
			evt_handled = 0
			break
	endswitch
	if (whs.eventCode != 2)
		tmon_win_set_last_evt(whs.winname, whs.eventCode)
	endif
	return evt_handled				
end 
//==============================================================================
// function : tmon_attach_profiles
//==============================================================================
function tmon_attach_profiles (win, [force])
	String win
	Variable force
	if (ParamIsDefault(force))
		force = 0
	endif
	ControlInfo /W=$win profile_cb
	if (V_Value)
		Struct TMonWinNote wns
		tmon_get_win_note (win, wns)
		if (! wns.pattached && !force)
			return 0
		endif
		Variable has_xp = strlen(wns.xp_win) > 0
		Variable has_yp = strlen(wns.yp_win) > 0
		Variable has_fp = strlen(wns.fp_win) > 0
		Variable nwin = has_xp + has_yp + has_fp
		if (! nwin) 
			return 0
		endif
		GetWindow $win wsize
		Variable l, r, t, b 
		Variable hh = (V_bottom - V_top)
		if (nwin > 1)
			hh /= nwin
		endif
		l = V_right + 5
		t = V_top
		r = V_right + 390
		b = V_top + hh
		if (nwin == 2)
			b -= 10
		elseif (nwin == 3)
			b -= 15
		endif
		if (has_xp)
			MoveWindow /W=$wns.xp_win l, t, r, b
		elseif (has_yp)
			MoveWindow /W=$wns.yp_win l, t, r, b	
		else
			MoveWindow /W=$wns.fp_win l, t, r, b
		endif
		if (nwin > 1)
			l = V_right + 5
			t = V_top + hh
			if (nwin == 2)
				t += 10
			elseif (nwin == 3)
				t += 5
			endif
			r = V_right + 390
			b = V_top +  2 * hh
			if (nwin == 3)
				b -= 10
			endif
			if (has_xp && has_yp)
				MoveWindow /W=$wns.yp_win l, t, r, b
			else
				MoveWindow /W=$wns.fp_win l, t, r, b
			endif
		endif
		if (nwin > 2)
			l = V_right + 5
			t = V_top + 2 * hh + 10 
			r = V_right + 390
			b = V_top +  3 * hh
			MoveWindow /W=$wns.fp_win l, t, r, b
		endif
	endif
end		

//==============================================================================
// function : tmon_draw_profiles_tools
//==============================================================================
static function tmon_draw_profiles_tools (win)
	String win
	SetDrawLayer /W=$win /K UserFront
	ControlInfo /W=$win profile_cb
	Variable something_drawn = 0
	if (V_Value)
		Struct TMonWinNote wns
		tmon_get_win_note (win, wns)
		Variable has_xp = strlen(wns.xp_win) > 0
		Variable has_yp = strlen(wns.yp_win) > 0
		Variable has_fp = strlen(wns.fp_win) > 0
		SetDrawEnv /W=$win xcoord=bottom, ycoord=left, save
		if (has_xp || has_yp)
			GetAxis /W=$win /Q bottom
			Variable baxis_min = min(V_min, V_max)
			Variable baxis_max = max(V_min, V_max)
			GetAxis /W=$win /Q left
			Variable laxis_min = min(V_min, V_max)
			Variable laxis_max = max(V_min, V_max)
			Variable csrA_x, csrA_y
			if (! strlen(CsrWave(A, win)))
				csrA_x = baxis_min
				csrA_y = laxis_min
			else
				csrA_x = pcsr(A, win)
				csrA_y = qcsr(A, win)
			endif
			Variable csrB_x, csrB_y
			if (! strlen(CsrWave(B, win)))
				csrB_x = baxis_max
				csrB_y = laxis_max
			else
				csrB_x = pcsr(B, win)
				csrB_y = qcsr(B, win)
			endif
			Variable csr_min_x = min(csrA_x, csrB_x)
			Variable csr_max_x = max(csrA_x, csrB_x)
			Variable csr_min_y = min(csrA_y, csrB_y)
			Variable csr_max_y = max(csrA_y, csrB_y)
			SetDrawLayer /W=$win UserFront
			SetDrawEnv /W=$win fillpat=5, linethick=0, save
			DrawRect /W=$win baxis_min, laxis_min, baxis_max, csr_min_y
			DrawRect /W=$win baxis_min, csr_max_y, baxis_max, laxis_max
			DrawRect /W=$win baxis_min, laxis_min, csr_min_x, laxis_max
			DrawRect /W=$win csr_max_x, laxis_min, baxis_max, laxis_max
			something_drawn = 1
		endif
		if (has_fp)
			Variable csrC_x, csrC_y
			if (! strlen(CsrWave(C, win)))
				return something_drawn
			else
				csrC_x = pcsr(C, win)
				csrC_y = qcsr(C, win)
			endif
			Variable csrD_x, csrD_y
			if (! strlen(CsrWave(D, win)))
				return something_drawn
			else
				csrD_x = pcsr(D, win)
				csrD_y = qcsr(D, win)
			endif
			SetDrawEnv /W=$win linefgc=(0,65535,0), dash=9, linethick=1, save
			DrawLine /W=$win csrC_x, csrC_y, csrD_x, csrD_y
			something_drawn = 1
		endif
	endif
	return something_drawn
end	
//==============================================================================
//	tmon_win_name
//==============================================================================
static function/S tmon_win_name (dev, attr)
	String dev
	String attr
	return UniqueName("tmon_", 6, 0) 
end
//==============================================================================
//	tmon_abort
//==============================================================================
function tmon_abort ()
	tango_monitor_stop("*","*")
	String error_str = "Oops... there's something wrong!\r"
	error_str += "If you don't kill 'anything important' yourself, it means that "
	error_str += "there is a bug into the TANGO binding [monitors implementation]\r"
	error_str += "Killing all monitors to prevent more troubles..."
	tango_display_error_str(error_str)
	tmon_kill_all_monitors()
end
//==============================================================================
//	tmon_kill_all_monitors
//==============================================================================
function tmon_kill_all_monitors()
	String pattern = "*" + kTMON_MAGIC_WIN_NAME + "*"
	do
		String wl = WinList(pattern,";","WIN:1")
		if (strlen(wl) == 0)  
			break
		endif 
		String win_name = StringFromList(0, wl)
		if (tmon_is_tmon(win_name) && ! tmon_is_profile(win_name))
			Struct TMonWinNote wns
			tmon_get_win_note(win_name, wns)
			wns.kill_win = 1
			tmon_set_win_note(win_name, wns)
			tmon_kill(win_name, kill_win = 1)
		elseif (strlen(GetUserData(win_name, "" , "dev")))
			DoWindow/K $win_name
		endif
	while (1)
	return kNO_ERROR
end
//==============================================================================
//	tmon_kill_dev_monitors
//==============================================================================
function tmon_kill_dev_monitors(dev)
	String dev
	String pattern = "*" + kTMON_MAGIC_WIN_NAME + "*"
	String win_list = WinList(pattern,";","WIN:1")
	if (strlen(win_list) == 0) 
		return kNO_ERROR
	endif 
	tango_monitor_stop(dev, "*", cid=-1)
	String win_name
	Variable i = 0
	do
		win_name = StringFromList(i, win_list)
		if (strlen(win_name) == 0)
			break
		endif
		if (cmpstr(tmon_get_dev(win_name), dev) == 0)
			tmon_kill(win_name, kill_win = 1)
		elseif (cmpstr(GetUserData(win_name, "" , "dev"), dev) == 0)
			DoWindow/K $win_name
		endif
		i += 1
	while (1)
end
//==============================================================================
//	tmon_reset_error
//==============================================================================
static function tmon_reset_error (dev)
	String dev
	String pattern = "*" + kTMON_MAGIC_WIN_NAME + "*"
	String win_list = WinList(pattern,";","WIN:1")
	if (strlen(win_list) == 0) 
		return kNO_ERROR
	endif 
	String win_name
	String value_name
	Variable i = 0
	do
		win_name = StringFromList(i, win_list)
		if (strlen(win_name) == 0)
			break
		endif
		if (cmpstr(tmon_get_dev(win_name), dev) == 0)
			SetDrawLayer /W=$win_name /K ProgFront
		endif 
		i += 1
	while (1)
end
//==============================================================================
// tmon_is_tmon
//==============================================================================
static function tmon_is_tmon (win_name)
	String win_name
	Variable type = tmon_get_win_type(win_name)
	if (numtype(type) != 0)
		return 0
	endif
	if (type < kTMON_MIN_TYPE || type > kTMON_MAX_TYPE)
		return 0
	endif
	return 1
end
//==============================================================================
// tmon_is_profile
//==============================================================================
static function tmon_is_profile (win_name)
	String win_name
	Variable type = tmon_get_win_type(win_name)
	if (numtype(type) != 0)
		return 0
	endif
	if (type == kTMON_IMAGE_XP || type == kTMON_IMAGE_YP)
		return 1
	endif
	return 0
end
//==============================================================================
// tmon_get_win_type
//==============================================================================
static function tmon_get_win_type (win_name)
	String win_name
	GetWindow $win_name note
	return NumberByKey(kTYPE, S_Value)
end
//==============================================================================
// tmon_get_dev
//==============================================================================
static function/S tmon_get_dev (win_name)
	String win_name
	GetWindow $win_name note
	return StringByKey(kDEV, S_Value)
end
//==============================================================================
// tmon_get_attr
//==============================================================================
static function/S tmon_get_attr (win_name)
	String win_name
	GetWindow $win_name note
	return StringByKey(kATTR, S_Value)
end
//==============================================================================
// tmon_get_format
//==============================================================================
static function tmon_get_format (win_name)
	String win_name
	GetWindow $win_name note
	return NumberByKey(kFORMAT, S_Value)
end
//==============================================================================
// tmon_get_access
//==============================================================================
static function tmon_get_access (win_name)
	String win_name
	GetWindow $win_name note
	return NumberByKey(kACCESS, S_Value)
end
//==============================================================================
// tmon_get_df
//==============================================================================
static function/S tmon_get_df (win_name)
	String win_name
	GetWindow $win_name note
	return StringByKey(kDF, S_Value)
end
//==============================================================================
// tmon_get_value_name_name
//==============================================================================
static function/S tmon_get_value_name (win_name)
	String win_name
	GetWindow $win_name note
	return StringByKey(kVAL, S_Value)
end
//==============================================================================
// tmon_get_value_path
//==============================================================================
static function/S tmon_get_value_path (win_name)
	String win_name
	GetWindow $win_name note
	return StringByKey(kVAL_PATH, S_Value)
end
//==============================================================================
//  tmon_get_data_wave
//==============================================================================
static function/S tmon_get_data_wave (win_name)
	String win_name
	GetWindow $win_name note
	return StringByKey(kWDATA, S_Value)
end
//==============================================================================
//  tmon_get_timestamp_wave
//==============================================================================
static function/S tmon_get_timestamp_wave (win_name)
	String win_name
	GetWindow $win_name note
	return StringByKey(kWTMS, S_Value)
end
//==============================================================================
// tmon_set_write_value
//==============================================================================
static function/S tmon_set_write_value (win_name, wrt_value)
	String win_name
	String wrt_value
	tools_win_note_set_str_val(win_name, kWRT_VAL, wrt_value)
end
//==============================================================================
// tmon_get_write_value
//==============================================================================
static function/S tmon_get_write_value (win_name)
	String win_name
	GetWindow $win_name note
	return StringByKey(kWRT_VAL, S_Value)
end
//==============================================================================
// tmon_set_write_atrr
//==============================================================================
static function tmon_set_write_attr (win_name, wrt_attr)
	String win_name
	String wrt_attr
	tools_win_note_set_str_val(win_name, kWRT_ATTR, wrt_attr)
end
//==============================================================================
// tmon_get_write_atrr
//==============================================================================
static function/S tmon_get_write_attr (win_name)
	String win_name
	GetWindow $win_name note
	return StringByKey(kWRT_ATTR, S_Value)
end
//==============================================================================
// tmon_set_status
//==============================================================================
static function tmon_set_status (win_name, status)
	String win_name
	variable status
	tools_win_note_set_num_val(win_name, kSTATUS, status)
end
//==============================================================================
// tmon_get_status
//==============================================================================
static function tmon_get_status (win_name)
	String win_name
	GetWindow $win_name note
	return NumberByKey(kSTATUS, S_Value)
end
//==============================================================================
// function : tmon_win_set_last_evt
//==============================================================================
static function tmon_win_set_last_evt (win, evt_code)
	String win
	Variable evt_code
	SetWindow $win userData(last_evt)=num2str(evt_code)
end
//==============================================================================
// function : tmon_win_get_last_evt
//==============================================================================
static function tmon_win_get_last_evt (win)
	String win
	String ud_str = GetUserData(win, "", "last_evt")
	if (strlen(ud_str))
		return str2num(ud_str)
	endif
	return -1
end
//==============================================================================
// tmon_init_win_note_struct
//==============================================================================
static function tmon_init_win_note_struct (wns)
	Struct TMonWinNote &wns
	wns.cid = -1
	wns.type = -1
	wns.status = -1
	wns.dev = ""
	wns.attr = ""
	wns.access = -1
	wns.format = -1
	wns.win = ""
	wns.dep = ""
	wns.val = ""
	wns.val_path = ""
	wns.tms_path = ""
	wns.qlt_path = ""
	wns.wdata = ""
	wns.wtms = ""
	wns.wrt_attr = ""
	wns.wrt_val = ""
	wns.xp = ""
	wns.xp_dep = ""
	wns.xp_win = ""
	wns.yp = ""
	wns.yp_dep = ""
	wns.yp_win = ""
	wns.fp = ""
	wns.fp_dep = ""
	wns.fp_win = ""
	wns.xyp_uv = ""
	wns.fp_uv = ""
	wns.df = ""
	wns.pp_path = ""
	wns.pattached = 1
	wns.dev_state_cid = NAN
	wns.dev_state_dep = ""
	wns.kill_win = 0
end
//==============================================================================
// tmon_set_win_note
//==============================================================================
static function tmon_set_win_note (win_name, wns)
	String win_name
	Struct TMonWinNote &wns
	String win_note = ""
	win_note = ReplaceStringByKey(kWIN, win_note, wns.win)
	win_note = ReplaceStringByKey(kDEV, win_note, wns.dev)
	win_note = ReplaceStringByKey(kATTR, win_note, wns.attr)
	win_note = ReplaceStringByKey(kVAL, win_note, wns.val)
	win_note = ReplaceStringByKey(kVAL_PATH, win_note, wns.val_path)
	win_note = ReplaceStringByKey(kTMS_PATH, win_note, wns.tms_path)
	win_note = ReplaceStringByKey(kQLT_PATH, win_note, wns.qlt_path)
	win_note = ReplaceStringByKey(kWDATA, win_note, wns.wdata)
	win_note = ReplaceStringByKey(kWTMS, win_note, wns.wtms)
	win_note = ReplaceStringByKey(kDEP, win_note, wns.dep)
	win_note = ReplaceStringByKey(kWRT_ATTR, win_note, wns.wrt_attr)
	win_note = ReplaceStringByKey(kWRT_VAL, win_note, wns.wrt_val)
	win_note = ReplaceStringByKey(kXP, win_note, wns.xp)
	win_note = ReplaceStringByKey(kXP_DEP, win_note, wns.xp_dep)
	win_note = ReplaceStringByKey(kXP_WIN, win_note, wns.xp_win)
	win_note = ReplaceStringByKey(kYP, win_note, wns.yp)
	win_note = ReplaceStringByKey(kYP_DEP, win_note, wns.yp_dep)
	win_note = ReplaceStringByKey(kYP_WIN, win_note, wns.yp_win)
	win_note = ReplaceStringByKey(kFP, win_note, wns.fp)
	win_note = ReplaceStringByKey(kFP_DEP, win_note, wns.fp_dep)
	win_note = ReplaceStringByKey(kFP_WIN, win_note, wns.fp_win)
	win_note = ReplaceStringByKey(kXYP_UV, win_note, wns.xyp_uv)
	win_note = ReplaceStringByKey(kFP_UV, win_note, wns.fp_uv)
	win_note = ReplaceStringByKey(kDF, win_note, wns.df)
	win_note = ReplaceNumberByKey(kACCESS, win_note, wns.access)
	win_note = ReplaceNumberByKey(kFORMAT, win_note, wns.format)
	win_note = ReplaceNumberByKey(kSTATUS, win_note, wns.status)
	win_note = ReplaceStringByKey(kPP_PATH, win_note, wns.pp_path)
	win_note = ReplaceNumberByKey(kTYPE, win_note, wns.type)
	win_note = ReplaceNumberByKey(kCLTID, win_note, wns.cid)
	win_note = ReplaceNumberByKey(kPATTACH, win_note, wns.pattached)
	win_note = ReplaceNumberByKey(kSTATE_CID, win_note, wns.dev_state_cid)
	win_note = ReplaceStringByKey(kSTATE_DEP, win_note, wns.dev_state_dep)
	win_note = ReplaceNumberByKey(kKILL_WIN, win_note, wns.kill_win)
	SetWindow $win_name note=win_note
end
//==============================================================================
// tmon_get_win_note
//==============================================================================
static function tmon_get_win_note (win_name, wns)
	String win_name
	Struct TMonWinNote &wns
	GetWindow $win_name note
	String win_note = S_Value
	wns.win = StringByKey(kWIN, win_note)
	wns.dev = StringByKey(kDEV, win_note)
	wns.attr = StringByKey(kATTR, win_note)
	wns.val = StringByKey(kVAL, win_note)
	wns.val_path = StringByKey(kVAL_PATH, win_note)
	wns.tms_path = StringByKey(kTMS_PATH, win_note)
	wns.qlt_path = StringByKey(kQLT_PATH, win_note)
	wns.wdata = StringByKey(kWDATA, win_note)
	wns.wtms = StringByKey(kWTMS, win_note)
	wns.dep = StringByKey(kDEP, win_note)
	wns.wrt_attr = StringByKey(kWRT_ATTR, win_note)
	wns.wrt_val = StringByKey(kWRT_VAL, win_note)
	wns.xp = StringByKey(kXP, win_note)
	wns.xp_dep = StringByKey(kXP_DEP, win_note)
	wns.xp_win = StringByKey(kXP_WIN, win_note)
	wns.yp = StringByKey(kYP, win_note)
	wns.yp_dep = StringByKey(kYP_DEP, win_note)
	wns.yp_win = StringByKey(kYP_WIN, win_note)
	wns.fp = StringByKey(kFP, win_note)
	wns.fp_dep = StringByKey(kFP_DEP, win_note)
	wns.fp_win = StringByKey(kFP_WIN, win_note)
	wns.xyp_uv = StringByKey(kXYP_UV, win_note)
	wns.fp_uv = StringByKey(kFP_UV, win_note)
	wns.df = StringByKey(kDF, win_note)
	wns.access = NumberByKey(kACCESS, win_note)
	wns.format = NumberByKey(kFORMAT, win_note)
	wns.status = NumberByKey(kSTATUS, win_note)
	wns.pp_path = StringByKey(kPP_PATH, win_note)
	wns.type = NumberByKey(kTYPE, win_note)
	wns.cid = NumberByKey(kCLTID, win_note)
	wns.pattached = NumberByKey(kPATTACH, win_note)
	wns.dev_state_cid = NumberByKey(kSTATE_CID, win_note)
	wns.dev_state_dep = StringByKey(kSTATE_DEP, win_note)
	wns.kill_win = NumberByKey(kKILL_WIN, win_note)
end
//==============================================================================
// tmon_start_dev_state_monitor
//==============================================================================
function tmon_start_dev_state_monitor (dev, cid, state_path)
	String dev
	Variable& cid
	String& state_path
	if (tango_dev_attr_exists(dev, "State") == 0)
		cid = NAN
		return -1
	endif
	String cur_df = GetDataFolder(1)
	String dev_df
	tango_enter_attr_df(dev, "State", prev_df=dev_df)
	NewDataFolder/O/S :monitor
	NVAR/Z current_state = :current_state
	if (! NVAR_Exists(current_state))
		Variable/G current_state = kDeviceStateUNKNOWN
	endif
	state_path = GetDataFolder(1) + "current_state"
	cid = tango_monitor_start(dev, "State", state_path, 500)
	SetDataFolder cur_df
	return 0
end
//==============================================================================
// tmon_stop_dev_state_monitor
//==============================================================================
function tmon_stop_dev_state_monitor (dev, cid)
	String dev
	Variable cid
	tango_monitor_stop(dev, "State", cid = cid)
	return 0
end
//==============================================================================
// tmon_dev_state_changed
//==============================================================================
function tmon_dev_state_changed (state, win_name)
	Variable state
	String win_name
	if (numtype(state) == 2)
		state = kDeviceStateUNKNOWN
	endif
	Variable last_dev_state = str2num(GetUserData(win_name, "", "last_dev_state"))
	if (last_dev_state == state)
		return 0
	endif
	Variable r, g, b
	tango_get_state_color(state, r, g, b)
	TitleBox/Z dev_status_tb, win=$win_name, labelBack=(r,g,b)
	TitleBox/Z dev_status_tb, win=$win_name, title=tango_get_state_str(state)
	tmon_adjust_titleboxes_pos(win_name)
	SetWindow $win_name, userData(last_dev_state)=num2str(state)
end
//==============================================================================
// tmon_adjust_titleboxes_pos
//==============================================================================
static function tmon_adjust_titleboxes_pos (win_name)
	String win_name
	ControlInfo /W=$win_name dev_status_tb 
	Variable dev_state_tb_vw = V_Width
	GetWindow $win_name wsizeDC
	Variable win_vr = V_right
	TitleBox/Z dev_status_tb, win=$win_name, pos={win_vr - dev_state_tb_vw - 5, 24}
	ControlInfo /W=$win_name attr_qlt_tb
	TitleBox/Z attr_qlt_tb, win=$win_name, pos={win_vr - dev_state_tb_vw - V_Width - 10, 24}	
end
//------------------------------------------------------------------------
// SOME PRIVATE CONSTs
//------------------------------------------------------------------------
static constant kSCA_WIDGET_W			= 150
static constant kSCA_WIDGET_H			= 83
static constant kSCA_WIDGET_OFFSET	= 10 
//------------------------------------------------------------------------
static strconstant kCTRL_GBOX		= "ctrl_gb_" 
static strconstant kCTRL_SETVAL	= "ctrl_sval_"
static strconstant kCTRL_GETVAL	= "ctrl_gval_"
static strconstant kCTRL_APPVAL	= "ctrl_aval_"
static strconstant kCTRL_OSMON	= "ctrl_osmon_"
//==============================================================================
// function : tango_dp
//==============================================================================
function tango_dp (dev_name)
	String dev_name
	//- exists?
	String win_name = tmon_find_dp(dev_name)
	if (strlen(win_name))
		DoWindow /F $win_name
		return 0
	endif
	//- enter device attributes data folder
	String cur_df
	tango_enter_attrs_df(dev_name, prev_df=cur_df)
	//- get a ref to the attributes list
	WAVE/T/Z alist = :alist
	if (! WaveExists(alist))
		DoAlert 0, "Attribute list missing!\nCan't open panel for device " + dev_name + "."
		SetDataFolder $cur_df
		return -1
	endif
	//- open the graph/panel window, give it a name and a tittle
	win_name = UniqueName("dp_tmon_", 6, 0)
	Display /K=1 /W=(216,41.75,736.5,308.75) /N=$win_name as dev_name
	//- put a ctrl bar in the graph
	ControlBar 50
	//- num of attributes
	Variable n_attr = DimSize(alist, 0)
	//- for each attributes...
	Variable i, t = 0
	String sca_list = ""
	String spe_list = ""
	String img_list = ""
	String attr_name
	Variable sca_list_size = 0
	for (i = 0; i < n_attr; i += 1)
		//- get attribute name 
		attr_name = alist[i][0]
		//- get attribute format and type
		Variable format = tango_get_attr_format(dev_name, attr_name)		
		Variable type = tango_get_attr_type(dev_name, attr_name) 
		switch (format)
			case kSCALAR:
				sca_list += attr_name + ";"
				sca_list_size += 1
				break
			case kSPECTRUM:
				if (type == kSTRING)
					continue
				endif
				spe_list += attr_name + ";"
				break
			case kIMAGE:
				if (type == kSTRING)
					continue
				endif
				img_list += attr_name + ";"
				break
		endswitch
	endfor
	Variable has_sca_attr = strlen(sca_list)
	Variable has_spe_attr = strlen(spe_list)
	Variable has_img_attr = strlen(img_list)
	//- create the tab ctrl - one tab for each attribute format
	Variable tab_id = 0
	String tab_ids = ""
	TabControl attr_tab, win=$win_name, pos={0,0}, size={2000,50}, proc=tango_dp_tab_proc
	if (has_sca_attr)
	  	TabControl attr_tab, win=$win_name, tabLabel(tab_id)="Scalars"
	  	tab_ids += num2str(kSCALAR) + ";"
		tab_id += 1
	endif
	if (has_spe_attr)
		TabControl attr_tab, win=$win_name, tabLabel(tab_id)="Spectra"
	  	tab_ids += num2str(kSPECTRUM) + ";"
	  	tab_id += 1
	endif
	if (has_img_attr)
		TabControl attr_tab, win=$win_name, tabLabel(tab_id)="Images"
	  	tab_ids += num2str(kIMAGE) + ";"
	  	tab_id += 1
	endif
	//- which tab is selected by default?
	Variable first_tab = str2num(StringFromList(0,tab_ids))
	switch (first_tab)
		case kSCALAR:
			SetWindow $win_name, userData(tab)=num2str(kSCALAR)
			break
		case kSPECTRUM:
			SetWindow $win_name, userData(tab)=num2str(kSPECTRUM)
			break
		case kIMAGE:
			SetWindow $win_name, userData(tab)=num2str(kIMAGE)
			break
	endswitch
	TabControl attr_tab, win=$win_name, value=0
	TabControl attr_tab, win=$win_name, font=$kLB_FONT,fSize=kLB_FONTSIZE
	TabControl attr_tab, userData(tab_ids)=tab_ids
	//- create the attributes menu for scalar
	if (has_sca_attr)
		PopupMenu sca_ppm, win=$win_name, bodyWidth=180, pos={7,24}, size={219,21}, mode=1
		PopupMenu sca_ppm, win=$win_name, font=$kLB_FONT,fSize=kLB_FONTSIZE
		PopupMenu sca_ppm, win=$win_name, title="Display", proc=tango_dp_ppm_proc
		PopupMenu sca_ppm, win=$win_name, popvalue=StringFromList(0, sca_list)
		PopupMenu sca_ppm, win=$win_name, disable=1
		Execute "PopupMenu sca_ppm, win=" + win_name + ", value=\"" + sca_list + "\""
	endif
	//- create the attributes menu for spectra
	if (has_spe_attr)
		PopupMenu spe_ppm, win=$win_name, bodyWidth=180, pos={7,24}, size={219,21}, mode=1
		PopupMenu spe_ppm, win=$win_name, font=$kLB_FONT,fSize=kLB_FONTSIZE
		PopupMenu spe_ppm, win=$win_name, title="Display", proc=tango_dp_ppm_proc
		PopupMenu spe_ppm, win=$win_name, popvalue=StringFromList(0, spe_list)
		PopupMenu spe_ppm, win=$win_name, disable=(first_tab == kSPECTRUM) ? 0 : 1
		Execute "PopupMenu spe_ppm, win=" + win_name + ", value=\"" + spe_list + "\""
	endif
	//- create the attributes menu for spectra
	if (has_img_attr)
		PopupMenu img_ppm, win=$win_name, bodyWidth=180, pos={7,24}, size={219,21}, mode=1
		PopupMenu img_ppm, win=$win_name, font=$kLB_FONT,fSize=kLB_FONTSIZE
		PopupMenu img_ppm, win=$win_name, title="Display", proc=tango_dp_ppm_proc
		PopupMenu img_ppm, win=$win_name, popvalue=StringFromList(0, img_list)
		PopupMenu img_ppm, win=$win_name, disable=(first_tab == kIMAGE) ? 0 : 1
		Execute "PopupMenu img_ppm, win=" + win_name + ", value=\"" + img_list + "\""
	endif
	//- standalone monitor
	Button stdln_mon_but, win=$win_name, pos={235,24}, size={140,20}, font=$kLB_FONT, fSize=kLB_FONTSIZE
	Button stdln_mon_but, win=$win_name, title="Open Standalone Mon."
	Button stdln_mon_but, win=$win_name, disable=1, proc=tango_dp_stdln_mon_proc
	//- if dev has a "State" attribute then monitor it
	Variable has_state_attr = tango_dev_attr_exists(dev_name, "State")
	if (has_state_attr || has_sca_attr)
		String dp_df = UniqueName("dp", 11, 0) 
		tools_df_make(dp_df, 1)
		SetWindow $win_name, userData(dp_df)=GetDataFolder(1)
	else
		SetWindow $win_name, userData(dp_df)=""
	endif
	if (has_state_attr)
		Variable cid = NAN
		String dev_state_path
		tmon_start_dev_state_monitor(dev_name, cid, dev_state_path)	
		Variable r,g,b
		tango_get_state_color(kDeviceStateUNKNOWN, r, g, b)
		TitleBox dev_status_tb, win=$win_name, fStyle=1, frame=5
		TitleBox dev_status_tb, win=$win_name, labelBack=(r,g,b)
		TitleBox dev_status_tb, win=$win_name, title="UNKNOWN"
		TitleBox dev_status_tb, win=$win_name, pos={0,0}, size={0,0}
		TitleBox dev_status_tb, win=$win_name, anchor=RT
		Variable/G dev_state_dep
		SetFormula dev_state_dep, "tmon_dev_state_changed(" + dev_state_path + ",\"" + win_name + "\")"
		SetWindow $win_name, userData(dev_state_cid)=num2str(cid) 
		SetWindow $win_name, userData(dev_state_path)=dev_state_path 
		SetWindow $win_name, userData(last_dev_state)=num2str(kDeviceStateUNKNOWN)
	else
		SetWindow $win_name, userData(dev_state_cid)=num2str(-1) 
		SetWindow $win_name, userData(dev_state_path)=""
		SetWindow $win_name, userData(last_dev_state)=num2str(kDeviceStateUNKNOWN)
	endif
	//- attach some user data to the window
	SetWindow $win_name, userData(dev)=dev_name
	SetWindow $win_name, userData(sca_list_size)=num2str(sca_list_size)
	String selected_attr = ""
	if (has_sca_attr)
		selected_attr = StringFromList(0, sca_list)
		SetWindow $win_name, userData(sca_list)=sca_list
	elseif (has_spe_attr)
		selected_attr = StringFromList(0, spe_list)
	elseif (has_img_attr)
		selected_attr = StringFromList(0, img_list)
	endif
	SetWindow $win_name, userData(attr)=selected_attr
	//- simulate a change (displayed attribute)
	tango_dp_attr_changed(dev_name, "", selected_attr, win_name)
	//- set the window hook
	SetWindow $win_name, hook(main)=tango_dp_win_hook
	//- restore datafolder
	SetDataFolder $cur_df
	//- force update
	tmon_adjust_titleboxes_pos(win_name)
	DoUpdate
end
//==============================================================================
// function : tango_dp_tab_proc
//==============================================================================
function tango_dp_tab_proc (tca) : TabControl
	Struct WMTabControlAction &tca
	if (tca.eventCode != 2)
		return 0
	endif
	Variable cur_selected_tab = str2num(GetUserData(tca.win, "", "tab")) 
	Variable new_selected_tab = str2num(StringFromList(tca.tab, GetUserData(tca.win, tca.ctrlName, "tab_ids")))
	if (cur_selected_tab == new_selected_tab)
		return 0
	endif
	String cur_selected_attr = ""
	switch (cur_selected_tab)
		case kSCALAR:
			ControlInfo /W=$tca.win sca_ppm
			cur_selected_attr = S_Value
			break
		case kSPECTRUM:
			ControlInfo /W=$tca.win spe_ppm
			cur_selected_attr = S_Value
			break
		case kIMAGE:
			ControlInfo /W=$tca.win img_ppm
			cur_selected_attr = S_Value
			break
	endswitch
	String new_selected_attr = ""
	switch (new_selected_tab)
		case kSCALAR:
			ControlInfo /W=$tca.win sca_ppm
			new_selected_attr = S_Value
			break
		case kSPECTRUM:
			ControlInfo /W=$tca.win spe_ppm
			new_selected_attr = S_Value
			break
		case kIMAGE:
			ControlInfo /W=$tca.win img_ppm
			new_selected_attr = S_Value
			break
	endswitch
	//-PopupMenu sca_ppm, win=$tca.win, disable = (new_selected_tab == 0) ? 0 : 1
	PopupMenu spe_ppm, win=$tca.win, disable = (new_selected_tab == kSPECTRUM) ? 0 : 1
	PopupMenu img_ppm, win=$tca.win, disable = (new_selected_tab == kIMAGE) ? 0 : 1
	Button stdln_mon_but, win=$tca.win, disable = (new_selected_tab == kSPECTRUM || (new_selected_tab == kIMAGE) ? 0 : 1
	String dev = GetUserData(tca.win, "", "dev")
   tango_dp_attr_changed(dev, cur_selected_attr, new_selected_attr, tca.win)
 	switch (new_selected_tab)
		case 0:
			GetWindow $tca.win wsize
			MoveWindow V_left, V_top, V_left + (4 * kSCA_WIDGET_W + 10), V_top + (4 * kSCA_WIDGET_H - 10)
			break
		case 1:
			GetWindow $tca.win wsize
			MoveWindow V_left, V_top, V_left + 550, V_top + 250
			break
		case 2:
			GetWindow $tca.win wsize
			MoveWindow V_left, V_top, V_left + 400, V_top + 400
			break
	endswitch
	SetWindow $tca.win, userData(attr)=new_selected_attr
	SetWindow $tca.win, userData(tab)=num2str(new_selected_tab)
	DoUpdate
end
//==============================================================================
// function : tango_dp_ppm_proc
//==============================================================================
function tango_dp_ppm_proc(pa) : PopupMenuControl
	Struct WMPopupAction &pa
	if (pa.eventCode != 2)
		return 0
	endif
	String dev = GetUserData(pa.win, "", "dev")
	String cur_selected_attr = GetUserData(pa.win, "", "attr")
	tango_dp_attr_changed(dev, cur_selected_attr, pa.popStr, pa.win)
	return 0
end
//==============================================================================
// function : tango_dp_stdln_mon_proc
//==============================================================================
function tango_dp_stdln_mon_proc(ba) : ButtonControl
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif
	String dev = GetUserData(ba.win, "", "dev")
	String cur_selected_attr = GetUserData(ba.win, "", "attr")
	tmon_create(dev, cur_selected_attr);
	return 0
end
//==============================================================================
// function : tango_dp_win_hook
//==============================================================================
function tango_dp_win_hook (whs)
	Struct WMWinHookStruct &whs
	Variable evt_handled = 1
	switch (whs.eventCode)
		//- win killed
		case 2:
			String dev = GetUserData(whs.winname, "", "dev")
			String cur_selected_attr = GetUserData(whs.winname, "", "attr")
			tango_dp_attr_changed(dev, cur_selected_attr, "", whs.winname)
			Variable cid = str2num(GetUserData(whs.winname, "", "dev_state_cid"))
			if (cid != -1)
				tango_monitor_stop(dev, "State", cid = cid)
			endif
			String dp_df = GetUserData(whs.winname, "", "dp_df")
			if (DataFolderExists(dp_df))
				String cur_df = GetDataFolder(1)
				SetDataFolder dp_df
				NVAR/Z dev_state_dep = dev_state_dep
				if (NVAR_Exists(dev_state_dep))
					SetFormula dev_state_dep, ""
					KillVariables/Z dev_state_dep
				endif
				SetDataFolder $cur_df
				KillDataFolder $dp_df
			endif
			break
		//- resize 
		case 6:
			tmon_adjust_titleboxes_pos(whs.winname)
			break
		//- any other event
		default:
			evt_handled = 0
			break
	endswitch
	return evt_handled				
end 
//==============================================================================
// function : tango_dp_attr_changed
//==============================================================================
static function tango_dp_attr_changed (dev, cur_attr, new_attr, win_name)
	String dev
	String cur_attr
	String new_attr
	String win_name
	String cur_df = GetDataFolder(1)
	String dp_df = GetUserData(win_name, "", "dp_df")
	if (strlen(cur_attr))
		KillControl /W=$win_name attr_qlt_tb
		if (DataFolderExists(dp_df))		
			switch (tango_get_attr_format(dev, cur_attr))
				case kSCALAR:
					String sca_list = GetUserData(win_name, "", "sca_list")
					if (! strlen(sca_list))
						break
					endif
					Variable i = 0
					do
						String attr = StringFromList(i, sca_list)
						if (strlen(attr))
						   String attr_df = dp_df + "sca_attr_" + num2str(i)
						   SetDataFolder $attr_df
						  	NVAR/Z attr_val_cid = :attr_val_cid
							if (NVAR_Exists(attr_val_cid) && attr_val_cid != -1)
								tango_monitor_stop(dev, attr, cid = attr_val_cid)	
							endif
							tango_dp_kill_scalar_ctrls(dev, attr, i, win_name, attr_df)	
							KillVariables /A 
							KillStrings /A 
							SetDataFolder $cur_df
							KillDataFolder $attr_df
						else 
							break
						endif
						i += 1
					while (1)
					SetDataFolder $cur_df
					break
				case kSPECTRUM:
					attr_df = dp_df + "spe_attr"
					SetDataFolder attr_df
					NVAR/Z attr_val_cid = :attr_val_cid
					if (NVAR_Exists(attr_val_cid) && attr_val_cid != -1)
						tango_monitor_stop(dev, cur_attr, cid = attr_val_cid)	
					endif
					NVAR/Z dep_var = :attr_val_dep
					if (NVAR_Exists(dep_var))
						SetFormula dep_var, ""
					endif
					RemoveFromGraph /Z /W=$win_name attr_val
					KillWaves /Z :attr_val
					KillVariables /A 
					SetDataFolder $cur_df
					KillDataFolder $attr_df
					break
				case kIMAGE:
					attr_df = dp_df + "img_attr"
					SetDataFolder attr_df
					NVAR/Z attr_val_cid = :attr_val_cid
					if (NVAR_Exists(attr_val_cid) && attr_val_cid != -1)
						tango_monitor_stop(dev, cur_attr, cid = attr_val_cid)	
					endif
					NVAR/Z dep_var = :attr_val_dep
					if (NVAR_Exists(dep_var))
						SetFormula dep_var, ""
					endif
					RemoveImage /Z /W=$win_name attr_val
					KillWaves /Z :attr_val
					KillVariables /A 
					SetDataFolder $cur_df
					KillDataFolder $attr_df
					break 
			endswitch
		endif
	endif
	if (strlen(new_attr))
		String var_name	
		String dep_formula
		switch (tango_get_attr_format(dev, new_attr))
			case kSCALAR:
				SetDrawLayer /W=$win_name /K ProgFront
				ModifyGraph /W=$win_name gbRGB=(52797,52797,52797), width=0
				sca_list = GetUserData(win_name, "", "sca_list")
				if (! strlen(sca_list))
					SetWindow $win_name, userData(attr)=""
					return 0
				endif
				i = 0
				do
					attr = StringFromList(i, sca_list)
					if (strlen(attr))
						SetDataFolder $dp_df
						tools_df_make("sca_attr_" + num2str(i), 1)
						String attr_obj = "attr_val"
						Variable type = tango_get_attr_type(dev, attr)
						if (type == kSTRING)
							String/G $attr_obj = ""
						else
							Variable/G $attr_obj = 0
						endif
						tango_dp_show_scalar_ctrls(dev, attr, i, win_name, GetDataFolder(1))				
					else
						break
					endif
					i += 1
				while (1)
				DoUpdate
				i = 0
				do
					attr = StringFromList(i, sca_list)
					if (strlen(attr))
						SetDataFolder $(dp_df + "sca_attr_" + num2str(i))
						Variable cid = tango_monitor_start(dev, attr, GetDataFolder(1) + attr_obj, 500)
						var_name = attr_obj + "_cid"
						Variable/G $var_name = cid			
					else
						break
					endif
					i += 1
				while (1)
				SetWindow $win_name, userData(attr)=StringFromList(0, sca_list)
				break
			case kSPECTRUM:
				SetDataFolder $dp_df
				tools_df_make("spe_attr", 1)
				attr_obj = "attr_val"
				cid = tango_monitor_start(dev, new_attr, GetDataFolder(1) + attr_obj, 500)
				do 
					DoXOPIdle
					WAVE/Z dest_wave = $(GetDataFolder(1) + attr_obj)
				while (! WaveExists(dest_wave))
				var_name = attr_obj + "_cid"
				Variable/G $var_name = cid
				var_name = attr_obj + "_dep"
				Variable/G $var_name
				dep_formula = "tmon_spectrum_func" 
				dep_formula  += "(" + GetWavesDataFolder(dest_wave, 2) 
				dep_formula  += ",\"" + GetWavesDataFolder(dest_wave, 2) 
				dep_formula  += "\",\"" + win_name + "\")"
				SetFormula $var_name, dep_formula
				AppendToGraph /W=$win_name dest_wave
				ModifyGraph /W=$win_name width=0
				ModifyGraph /W=$win_name wbRGB=(56797,56797,56797), gbRGB=(0,0,0)
				ModifyGraph /W=$win_name rgb=(0,65280,0), gridRGB=(21760,21760,21760)
				ModifyGraph /W=$win_name grid=1, mirror=1, minor(bottom)=1
				ModifyGraph /W=$win_name font="Arial",fSize=8
				ModifyGraph /W=$win_name margin(top)=0,margin(right)=0
				SetWindow $win_name, userData(attr)=new_attr
				break
			case kIMAGE:
				SetDataFolder $dp_df
				tools_df_make("img_attr", 1)
				attr_obj = "attr_val"
				cid = tango_monitor_start(dev, new_attr, GetDataFolder(1) + attr_obj, 500)
				do 
					DoXOPIdle
					WAVE/Z dest_wave = $(GetDataFolder(1) + attr_obj)
				while (! WaveExists(dest_wave))
				var_name = attr_obj + "_cid"
				Variable/G $var_name = cid
				var_name = attr_obj + "_dep"
				Variable/G $var_name
				dep_formula = "tmon_image_func" 
				dep_formula  += "(" + GetWavesDataFolder(dest_wave, 2) 
				dep_formula  += ",\"" + GetWavesDataFolder(dest_wave, 2) 
				dep_formula  += "\",\"" + win_name + "\")"
				SetFormula $var_name, dep_formula
				AppendImage /W=$win_name dest_wave
				Variable np = DimSize(dest_wave, 0)
				Variable nq = DimSize(dest_wave, 1)
				ModifyGraph /W=$win_name width={Aspect, np/nq}
				ModifyImage /W=$win_name $attr_obj ctab={*,*,PlanetEarth,0}
				ModifyGraph /W=$win_name margin(top)=0,margin(right)=57
				ModifyGraph /W=$win_name axOffset(left)=-2.33333
				ModifyGraph /W=$win_name wbRGB=(56797,56797,56797),gbRGB=(0,0,0)
				ModifyGraph /W=$win_name mirror=1, minor=1
				ModifyGraph /W=$win_name font="Arial", fSize=8
				ModifyGraph /W=$win_name tickUnit(bottom)=1, tickUnit(left)=1
				SetAxis/A/R left
				ColorScale /W=$win_name /C /N=text0 /F=0 /S=3 /B=1 /A=MC /X=44.86 /Y=3.05 /E 
				ColorScale /W=$win_name /N=text0 /E /C image=$attr_obj, heightPct=100
				String cmd_str = "ColorScale /W=" + win_name
				cmd_str += "/C/N=text0 width=7,font=\"Small Fonts\",fsize=6,minor=1"
				Execute(cmd_str)
				SetWindow $win_name, userData(attr)=new_attr
				break 
		endswitch
	else
		SetWindow $win_name, userData(attr)=""
	endif
	SetDataFolder $cur_df
end
//------------------------------------------------------------------------
// tango_dp_show_scalar_ctrls
//------------------------------------------------------------------------
static function tango_dp_show_scalar_ctrls (dev_name, attr_name, attr_id, win_name, mon_df)
	String dev_name
	String attr_name
	Variable attr_id
	String win_name
	String mon_df
	String attr_id_str = num2str(attr_id)
	String user_data 
	Variable sca_list_size = str2num(GetUserData(win_name, "", "sca_list_size"))
	Variable f
	if (sca_list_size <= 6)
		f = 2
	elseif (sca_list_size <= 10)
		f = 3
	elseif (sca_list_size <= 16)
		f = 4
	elseif (sca_list_size <= 32)
		f = 6
	else
		f = 8
	endif
	Variable left_offset = trunc(attr_id /f) * (kSCA_WIDGET_W + kSCA_WIDGET_OFFSET)
	Variable top_offset = mod(attr_id, f) * (kSCA_WIDGET_H + kSCA_WIDGET_OFFSET)
	Variable pos_left = 10 + left_offset
	Variable pos_top = 55 + top_offset
	String ctrl_name = kCTRL_GBOX	 + attr_id_str
	GroupBox $ctrl_name, win=$win_name, pos={pos_left, pos_top}
	GroupBox $ctrl_name, win=$win_name, size={150,87}, fstyle=1
	String cbt
	if (strlen(attr_name) > 18)
		cbt = attr_name[0, 16] + "..."
	else
		cbt = attr_name
	endif
	GroupBox $ctrl_name, win=$win_name, title=cbt
	GroupBox $ctrl_name, win=$win_name, help={lowerstr(dev_name) + "/" + attr_name}
	pos_left = 25 + left_offset
	pos_top = 75 + top_offset
	ctrl_name = kCTRL_GETVAL + attr_id_str
	Variable type = tango_get_attr_type(dev_name, attr_name)
	if (type != kSTRING)
		NVAR attr_num_val = $(mon_df + "attr_val")
		String attr_units = "%g " + tango_get_attr_unit(dev_name, attr_name)
		ValDisplay $ctrl_name, win=$win_name, pos={pos_left, pos_top}
		ValDisplay $ctrl_name, win=$win_name, size={120,16}
		ValDisplay $ctrl_name, win=$win_name, labelBack=(0,65280,0),frame=0,mode=2
		ValDisplay $ctrl_name, win=$win_name, title=""
		ValDisplay $ctrl_name, win=$win_name, help={"Current attribute value"}
		ValDisplay $ctrl_name, win=$win_name, format=attr_units, limits={0,0,0}
		Execute "ValDisplay "  + ctrl_name + ", win=" + win_name + ", value=" + mon_df + "attr_val"
		String var_name = mon_df + "attr_val_dep"
		Variable/G $var_name
		String dep_formula = "tango_dp_sca_func" + "(" 
		dep_formula += mon_df + "attr_val"
		dep_formula += ",\"" + mon_df
		dep_formula += "\",\"" + win_name 
		dep_formula += "\",\"" + ctrl_name + "\")"
		SetFormula $var_name, dep_formula
		SetWindow $win_name, userData($ctrl_name)=num2str(kAttrQualityUNKNOWN)
	else
		SVAR attr_str_val = $(mon_df + "attr_val")
		SetVariable $ctrl_name, win=$win_name, pos={pos_left, pos_top}
		SetVariable $ctrl_name, win=$win_name, size={120,16}
		SetVariable $ctrl_name, win=$win_name, limits={-inf,+inf,1}
		SetVariable $ctrl_name, win=$win_name, title=" "
		SetVariable $ctrl_name, win=$win_name, help={"Set attribute value"}
		SetVariable $ctrl_name, win=$win_name, limits={0,0,0}, noedit=1
		SetVariable $ctrl_name, win=$win_name, value=attr_str_val
	endif
	Variable access = tango_get_attr_access(dev_name, attr_name)
	if (access == kREAD_WRITE || access == kREAD_WITH_WRITE || access == kWRITE)
		String wattr = tango_get_wattr(dev_name, attr_name)
		if (! strlen(wattr))
			wattr = attr_name
		endif
		pos_left = 25 + left_offset
		pos_top = 95 + top_offset
		ctrl_name = kCTRL_SETVAL + attr_id_str
		attr_units = "%g " + tango_get_attr_unit(dev_name, attr_name)
		SetVariable $ctrl_name, win=$win_name, pos={pos_left, pos_top}
		SetVariable $ctrl_name, win=$win_name, size={90,16}
		SetVariable $ctrl_name, win=$win_name, limits={-inf,+inf,1}
		SetVariable $ctrl_name, win=$win_name, title=" "
		SetVariable $ctrl_name, win=$win_name, help={"Set attribute value"}
		SetVariable $ctrl_name, win=$win_name, format=attr_units
		var_name = mon_df + "attr_val_set"
		if (type != kSTRING)
			Variable/G $var_name	
		else
			String/G $var_name	
		endif
		Execute "SetVariable "  + ctrl_name + ", win=" + win_name + ", value=" + var_name
		pos_left = 25 + left_offset
		pos_top = 95 + top_offset
		ctrl_name = kCTRL_APPVAL + attr_id_str
		Button $ctrl_name, win=$win_name, pos={pos_left + 92, pos_top}
		Button $ctrl_name, win=$win_name, size={26,15}
		Button $ctrl_name, win=$win_name, font=$kLB_FONT, fSize=kLB_FONTSIZE
		Button $ctrl_name, win=$win_name, title="Wrt"
		Button $ctrl_name, win=$win_name, userData(dev)=dev_name
		Button $ctrl_name, win=$win_name, userData(attr)=attr_name	
		Button $ctrl_name, win=$win_name, userData(set_var)=var_name
		Button $ctrl_name, win=$win_name, proc=tango_dp_setval_proc
	endif
	pos_left = 25 + left_offset
	pos_top = 115 + top_offset
	ctrl_name = kCTRL_OSMON + attr_id_str
	Button $ctrl_name, win=$win_name, pos={pos_left, pos_top}
	Button $ctrl_name, win=$win_name, size={119,17}
	Button $ctrl_name, win=$win_name, title="Open Standalone Mon."
	Button $ctrl_name, win=$win_name, font=$kLB_FONT, fSize=kLB_FONTSIZE
	Button $ctrl_name, win=$win_name, proc=tango_dp_sca_stdln_mon_proc
	Button $ctrl_name, win=$win_name, userData(dev)=dev_name
	Button $ctrl_name, win=$win_name, userData(attr)=attr_name
	Button $ctrl_name, win=$win_name, disable= (type != kSTRING) ? 0 : 2
 	return kNO_ERROR
end
//------------------------------------------------------------------------
// tango_dp_kill_scalar_ctrls
//------------------------------------------------------------------------
static function tango_dp_kill_scalar_ctrls (dev_name, attr_name, attr_id, win_name, mon_df)
	String dev_name
	String attr_name
	Variable attr_id
	String win_name
	String mon_df
	NVAR/Z dep_var = $(mon_df + "attr_val_dep")
	if (NVAR_Exists(dep_var))
		SetFormula dep_var, ""
		KillVariables dep_var
	endif
	String attr_id_str = num2str(attr_id)
	String user_data 
	String ctrl_name = kCTRL_GBOX	 + attr_id_str
	KillControl /W=$win_name $ctrl_name
	ctrl_name = kCTRL_GETVAL + attr_id_str
	KillControl /W=$win_name $ctrl_name
	ctrl_name = kCTRL_SETVAL + attr_id_str
	KillControl /W=$win_name $ctrl_name
	ctrl_name = kCTRL_APPVAL + attr_id_str
	KillControl /W=$win_name $ctrl_name
	ctrl_name = kCTRL_OSMON + attr_id_str
	KillControl /W=$win_name $ctrl_name
	return kNO_ERROR
end
//==============================================================================
// function : tango_dp_sca_stdln_mon_proc
//==============================================================================
function tango_dp_sca_stdln_mon_proc(ba) : ButtonControl
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif
	String dev = GetUserData(ba.win, ba.ctrlName, "dev")
	String attr = GetUserData(ba.win, ba.ctrlName, "attr")
	tmon_create(dev, attr);
	return 0
end
//==============================================================================
// function : tango_dp_setval_proc
//==============================================================================
function tango_dp_setval_proc(ba) : ButtonControl
	Struct WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif
	String dev = GetUserData(ba.win, ba.ctrlName, "dev")
	String attr = GetUserData(ba.win, ba.ctrlName, "attr")
	String set_var = GetUserData(ba.win, ba.ctrlName, "set_var") 
	String wattr = tango_get_wattr(dev, attr)
	if (! strlen(wattr))
		wattr = attr
	endif
	if (tango_write_attribute(dev, wattr, set_var) == kERROR)
		tango_display_error()
	endif 
	return 0
end

//==============================================================================
// function : tango_dp_sca_func 
//==============================================================================
function tango_dp_sca_func (val, mon_df, win_name, ctrl_name)
	Variable val
	String mon_df
	String win_name
	String ctrl_name
	NVAR/Z qlt = $(mon_df + "attr_val_qlt")
	if (! NVAR_Exists(qlt))
		return kNO_ERROR 
	endif
	String last_qlt_var_name = mon_df + "attr_val_saved_qlt"
	NVAR/Z last_qlt = $last_qlt_var_name
	if (! NVAR_Exists(last_qlt))
		Variable/G $last_qlt_var_name
		NVAR/Z last_qlt = $last_qlt_var_name
		last_qlt = kAttrQualityUNKNOWN
	endif
	if (last_qlt != qlt)
		Variable r, g, b
		tango_get_attr_qlt_color(qlt, r, g, b)
		ValDisplay $ctrl_name, win=$win_name, labelBack=(r,g,b)
		last_qlt = qlt
	endif
	return kNO_ERROR
end


