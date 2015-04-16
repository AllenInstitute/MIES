#pragma rtGlobals = 1
#pragma version = 1.0
#pragma IgorVersion = 6.0

//==============================================================================
// tango_tools.ipf
//------------------------------------------------------------------------------
// N.Leclercq - SOLEIL
//==============================================================================

//==============================================================================
// CONSTANTES
//==============================================================================
static strconstant kTERM = "\r\n"
//------------------------------------------------------------------------------
static strconstant kTYPE = "TYPE"
static strconstant kVAL  = "VAL"		
static strconstant kDIM0 = "DIM0"
static strconstant kDIM1 = "DIM1"
static strconstant kDIM2 = "DIM2"
static strconstant kDIM3 = "DIM3"
static strconstant kPATH = "PATH"
//------------------------------------------------------------------------------
static strconstant kSWAV = "SWAV"
static strconstant kNWAV = "NWAV" 
static strconstant kSVAR = "SVAR" 
static strconstant kNVAR = "NVAR" 
//==============================================================================
// fonction : tools_nearest_multiple
//------------------------------------------------------------------------------
// Retourne le multiple de <resol> le plus proche de <val>
//==============================================================================
function tools_nearest_multiple (val, resol)
	Variable val
	Variable resol
	Variable base_val = val / resol
	Variable int_part = trunc(base_val)
	if (abs(base_val - int_part) > 0.5)
		int_part += (val < 0) ? -1 : 1
	endif
	return int_part * resol
end
//==============================================================================
// fonction : tools_swap
//==============================================================================
function tools_swap (a, b)
	Variable &a
	Variable &b
	if (a > b)
		Variable temp = a
		a = b
		b = temp
	endif
end
//==============================================================================
// fonction : tools_full_obj_path_to_obj_name
//==============================================================================
function/S tools_full_obj_path_to_obj_name (fop)
	String fop
	String on = "" 
	String token = ""
	Variable i = 0
	do 
		token = StringFromList(i, fop, ":")
		if (strlen(token) == 0)
			return on
		endif
		on = token
		i += 1
	while(1)
end
//==============================================================================
// fonction : tools_split_obj_path
//==============================================================================
function tools_split_obj_path (fop, on)
	String &fop
	String &on
	do
		if (StrSearch(fop, ":", 0) == 0)
			fop = fop[1, strlen(fop)]
		else
			break
		endif
	while (1)
	on = ""
	String token = ""
	Variable i = 0
	do 
		token = StringFromList(i, fop, ":")
		if (Strlen(token) == 0)
			Variable pos = StrSearch(fop, on, 0)
			fop = fop[0, pos - 1]
			break
		endif
		on = token
		i += 1
	while(1)
end
//==============================================================================
// fonction : tools_path_remove_quotes
//==============================================================================
function tools_path_remove_quotes (path)
	String &path
	do
		Variable from = strsearch(path, "'", 0)
		if (from == -1)
			break
		endif
		Variable to = strsearch(path, "'", from + 1) 
		if (from != -1 && to != -1)
			path = path[0, from -1] + path[from + 1, to - 1] + path[to + 1, strlen(path)]
		endif
	while (1)
end
//==============================================================================
// fonction : tools_df_make
//==============================================================================
function tools_df_make (p, s)
	String p
	Variable s
	if (DataFolderExists(p))
		if (s)
			SetDataFolder $p
		endif
		return kNO_ERROR
	endif
	String cur_df = GetDataFolder(1)
	if (StrSearch(p, "::", 0) != -1)
		if (s == 0)
			print "ERROR:tools_make_df:invalid datafolder syntax [contains '::']"
			SetDataFolder cur_df
		endif
		return kERROR
	endif
	if (StrSearch(p, "root", 0) == 0)
		p = p[StrSearch(p, ":", 0) + 1, strlen(p)]
		SetDataFolder root:
	endif
	do
		if (StrSearch(p, ":", 0) == 0)
			p = p[1, strlen(p)]
		else
			break
		endif
	while (1)
	if (strlen(p) == 0)
		if (s == 0)
			SetDataFolder cur_df
		endif
		return kNO_ERROR
	endif
	String token
	Variable i = 0
	do 
		token = StringFromList(i, p, ":")
		if (Strlen(token) == 0)
			break
		endif
		if (DataFolderExists(token) == 0)
			NewDataFolder/O/S $token 
		else
			SetDataFolder $token 
		endif
		i += 1
	while(1)
	if (! s)
		SetDataFolder cur_df
	endif
	return kNO_ERROR
end

//==============================================================================
// fonction : tools_df_delete
//==============================================================================
function tools_df_delete (df_to_delete)
	String df_to_delete
	tools_kill_df_graphs(df_to_delete)
	tools_kill_df_dep(df_to_delete)
	tools_kill_df(df_to_delete)
end
//==============================================================================
// fonction : tools_kill_df_graphs
//------------------------------------------------------------------------------
// close any graph, layout, table ou XOP window containing a wave located in 
// the specified datafolder (df) or one of its subdatafolder.
//==============================================================================
function tools_kill_df_graphs (df)
	String df
	if (strlen(df) == 0 || DataFolderExists(df) == 0)
		return kNO_ERROR
	endif
	String previous_df = GetDataFolder(1)
	SetDataFolder df
	String sub_df
	Variable index = 0
	do
		sub_df = GetIndexedObjName(df, 4, index)
		if (strlen(sub_df) == 0)
			break
		endif
		tools_kill_df_graphs(df + ":" + sub_df)
		index += 1
	while(1)
	String current_df_wav_list = WaveList("*",";","")
	if (strlen(current_df_wav_list) == 0) 
		SetDataFolder previous_df
		return kNO_ERROR
	endif 
	String windows_type = "WIN:" + num2str(1+2+4+4096)
	String win_list = WinList("*",";",windows_type)
	if (strlen(win_list) == 0) 
		if (DataFolderExists(previous_df))
			SetDataFolder previous_df
		endif
		return kNO_ERROR
	endif 
	String win_name
	String win_wav_list
	String target_win
	Variable win_type
	Variable i = 0
	do
		win_name = StringFromList(i, win_list)
		if (strlen(win_name) == 0)
			break
		endif
		win_type = WinType(win_name)
		if (win_type != 0 && win_type != 13)
			target_win = "WIN:" + win_name
			if (strlen(WaveList("*",";",target_win)) != 0) 
				DoWindow/K $win_name
			endif
		elseif (win_type == 13)
			DoWindow/K $win_name
		endif
		i += 1
	while (1)
	SetDataFolder previous_df
	return kNO_ERROR
end
//==============================================================================
// fonction : tools_kill_df_dep
//------------------------------------------------------------------------------
// kills any dependency (i.e. formula) involving a variable, string or wave 
// located into the specified datafolder or one of its subdatafolders.
//==============================================================================
function tools_kill_df_dep (df)
	String df
	if (strlen(df) == 0 || DataFolderExists(df) == 0)
		return kNO_ERROR
	endif
	String previous_df = GetDataFolder(1)
	SetDataFolder df
	String sub_df
	Variable index = 0
	do
		sub_df = GetIndexedObjName(df, 4, index)
		if (strlen(sub_df) == 0)
			break
		endif
		tools_kill_df_dep(df + ":" + sub_df)
		index += 1
	while(1)
	String obj
	index = 0
	do 
		obj = GetIndexedObjName(df, 1, index)
		if (strlen(obj) == 0)
			break
		endif
		SetFormula $obj,""
		index += 1
	while (1)
	index = 0
	do 
		obj = GetIndexedObjName(df, 2, index)
		if (strlen(obj) == 0)
			break
		endif
		SetFormula $obj,""
		index += 1
	while (1)
	index = 0
	do 
		obj = GetIndexedObjName(df, 3, index)
		if (strlen(obj) == 0)
			break
		endif
		SetFormula $obj,""
		index += 1
	while (1)
	SetDataFolder previous_df
	return kNO_ERROR
end
//==============================================================================
// fonction : tools_kill_df
//------------------------------------------------------------------------------
// delete the specified datafolder (and its subdatafolder)
//==============================================================================
function tools_kill_df (df)
	String df
	if (strlen(df) == 0 || DataFolderExists(df) == 0)
		return kNO_ERROR
	endif
	String previous_df = GetDataFolder(1)
	SetDataFolder df
	String sub_df
	do
		sub_df = GetIndexedObjName(df, 4, 0)
		if (strlen(sub_df) == 0)
			break
		endif
		tools_kill_df(df + ":'" + sub_df + "'")
	while(1)
	KillDataFolder df
	if (DataFolderExists(previous_df))
		SetDataFolder previous_df
	endif
	return kNO_ERROR
end
//==============================================================================
// fonction : tools_get_parent_df
//------------------------------------------------------------------------------
// returns the parent of the specified datafolder
//==============================================================================
function/S tools_get_parent_df (df)
	String df
	if (strlen(df) == 0)
		return ""
	endif
	Variable len = strlen(df)
	Variable end_pos = len
	if (char2num(df[end_pos]) != char2num(":"))
		end_pos -= 1
	endif
	do
		end_pos -= 1
	while (char2num(df[end_pos]) != char2num(":"))
	return df[0, end_pos]
end
//==============================================================================
// fonction : tools_path_build
//==============================================================================
function/S tools_path_build (prefix, sufix, [add_sc])
	String prefix
	String sufix
	Variable add_sc
	if (ParamIsDefault(add_sc))
		add_sc = 0
	endif
	Variable len = strlen(prefix)
	if (len == 0)
		return sufix
	endif
	String path
	if (char2num(prefix[len - 1]) == char2num(":"))
		path = prefix + sufix
	else
		path = prefix + ":" +  sufix
	endif
	if (add_sc)
		path += ":"
	endif
	return path
end
//==============================================================================
// fonction : tools_df_select
//==============================================================================
function/S tools_df_select ([no_sc])
	Variable no_sc
	if (ParamIsDefault(no_sc))
		no_sc = 0
	endif
	String previous_df = GetDataFolder(1)
	String pstr = "prompt=\"Use the red arrow to select the target folder.\""
	String boptions = ",showWaves=1,showVars=0,showStrs=0"
	Execute "CreateBrowser " + pstr + boptions
	String target_df = GetDataFolder(1)
	NVAR V_Flag = $tools_path_build(previous_df, "V_Flag")
	if (V_Flag == 0)
		target_df = ""
	endif
	SetDataFolder previous_df
	KillVariables/Z V_Flag
	KillStrings/Z S_BrowserList
	if (no_sc)
		target_df = tools_df_remove_last_sc(target_df)
	endif
	return target_df
end
//==============================================================================
// fonction : tools_df_remove_last_sc
//==============================================================================
function/S tools_df_remove_last_sc (df_path)
	String df_path
	if (strlen(df_path) == 0)
		return df_path
	endif
	if (char2num(df_path[strlen(df_path) - 1]) != char2num(":"))
		return df_path
	endif
	df_path = df_path[0, strlen(df_path) - 2]
	return df_path
end
//==============================================================================
// static fonction : tools_df_object_type
//==============================================================================
static function/S tools_df_object_type (str)
	String str
	return StringByKey(kTYPE, str)
end
//==============================================================================
// static fonction : tools_df_object_path
//==============================================================================
static function/S tools_df_object_path (str)
	String str
	return StringByKey(kPATH, str)
end
//==============================================================================
// static fonction : tools_df_str_object_val
//==============================================================================
static function/S tools_df_str_object_val (str)
	String str
	return StringByKey(kVAL, str)
end
//==============================================================================
// static fonction : tools_df_num_object_val
//==============================================================================
static function tools_df_num_object_val (str)
	String str
	return NumberByKey(kVAL, str)
end
//==============================================================================
// static fonction : tools_df_wave_object_dim0
//==============================================================================
static function tools_df_wave_object_dim0 (str)
	String str
	return NumberByKey(kDIM0, str)
end
//==============================================================================
// static fonction : tools_df_wave_object_dim1
//==============================================================================
static function tools_df_wave_object_dim1 (str)
	String str
	return NumberByKey(kDIM1, str)
end
//==============================================================================
// static fonction : tools_df_wave_object_dim2
//==============================================================================
static function tools_df_wave_object_dim2 (str)
	String str
	return NumberByKey(kDIM2, str)
end
//==============================================================================
// static fonction : wave_object_dim3
//==============================================================================
static function tools_df_wave_object_dim3 (str)
	String str
	return NumberByKey(kDIM3, str)
end
//==============================================================================
// fonction : tools_df_save_to_file 
//==============================================================================
function tools_df_save_to_file (df, [path])
	String df
	String path
	Variable refNum
	if (! ParamIsDefault(path))
		Open refNum as path
	else
		Open refNum
	endif
	if (refNum == 0)
		return kERROR
	endif
	tools_df_write_objets_to_file(df, refNum)
	Close refNum
	return kNO_ERROR
end
//==============================================================================
// static fonction : tools_df_write_objets_to_file
//==============================================================================
static function tools_df_write_objets_to_file (df, refNum)
	String df
	Variable refNum
	String str
	if (strlen(df) == 0 || DataFolderExists(df) == 0)
		return kNO_ERROR
	endif
	String previous_df = GetDataFolder(1)
	SetDataFolder df
	String sub_df
	//--appels recursifs
	Variable index = 0
	do
		sub_df = GetIndexedObjName(df, 4, index)
		if (strlen(sub_df) == 0)
			break
		endif
		String next_df = df + ":" + sub_df
		if (! DataFolderExists(next_df))
			next_df = df + ":'" + sub_df + "'"	
		endif
		tools_df_write_objets_to_file(next_df, refNum)
		index += 1
	while(1)
	String obj
	//--sauvegarde des ondes (obj.type 1)
	index = 0
	do 
		obj = GetIndexedObjName(df, 1, index)
		if (strlen(obj) == 0)
			break
		endif
		WAVE wn = $tools_path_build(df, obj)
		Variable wave_type = WaveType(wn)
		String wave_type_str = kNWAV
		if (wave_type == 0)
			WAVE/T wt = $tools_path_build(df, obj)
			wave_type_str = kSWAV
		endif
		str  = "TYPE:" +  wave_type_str  + ";PATH:" + df  + ":" + obj
		str += ";DIM0:" + num2str(DimSize(wn, 0))
		str += ";DIM1:" + num2str(DimSize(wn, 1)) 
		str += ";DIM2:" + num2str(DimSize(wn, 2))
		str += ";DIM3:" + num2str(DimSize(wn, 3)) 
		str += ";" + kTERM
		fprintf refNum, "%s" str
		Variable i, j, k
		if (WaveDims(wn) == 3)
			for (k = 0; k < DimSize(wn, 0); k += 1)
				for (j = 0; j < DimSize(wn, 1); j += 1) 
					for (i = 0; i < DimSize(wn, 2); i += 1)
						if (wave_type == 0)
							String s = wt[k][j][i]
							do
								Variable pos = strsearch(s, "\r", 0)
								if (pos == -1)
									break
								endif
								s = s[0, pos -1] + s[pos + 1, strlen(s)]
							while (1)
							do
								pos = strsearch(s, "\n", 0)
								if (pos == -1)
									break
								endif
								s = s[0, pos -1] + s[pos + 1, strlen(s)]
							while (1)
							fprintf refNum, "%s:%s[%d][%d][%d]=\"%s\"\r\n" df, obj, j, i, k, s  
						else
							fprintf refNum, "%s:%s[%d][%d][%d]=%g\r\n" df, obj, j, i, k, wn[k][j][i]
						endif
					endfor
				endfor
			endfor
		elseif (WaveDims(wn) == 2)
			for (j = 0; j < DimSize(wn, 0); j += 1) 
				for (i = 0; i < DimSize(wn, 1); i += 1)
					if (wave_type == 0)
						s = wt[j][i] 
						do
							pos = strsearch(s, "\r", 0)
							if (pos == -1)
								break
							endif
							s = s[0, pos -1] + s[pos + 1, strlen(s)]
						while (1)
						do
							pos = strsearch(s, "\n", 0)
							if (pos == -1)
								break
							endif
							s = s[0, pos -1] + s[pos + 1, strlen(s)]
						while (1)
						fprintf refNum, "%s:%s[%d][%d]=\"%s\"\r\n" df, obj, j, i, s  
					else
						fprintf refNum, "%s:%s[%d][%d]=%g\r\n" df, obj, j, i, wn[j][i] 
					endif
				endfor
			endfor
		elseif (WaveDims(wn) == 1)
			for (i = 0; i < Numpnts(wn); i += 1)
				if (wave_type == 0)
					s = wt[i] 
					do
						pos = strsearch(s, "\r", 0)
						if (pos == -1)
							break
						endif
						s = s[0, pos -1] + s[pos + 1, strlen(s)]
					while (1)
					do
						pos = strsearch(s, "\n", 0)
						if (pos == -1)
							break
						endif
						s = s[0, pos -1] + s[pos + 1, strlen(s)]
					while (1)
					fprintf refNum, "%s:%s[%d]=\"%s\"\r\n" df, obj, i, s  
				else
					fprintf refNum, "%s:%s[%d]=%g\r\n" df, obj, i, wn[i]  
				endif
			endfor
		else
			//- error not > 2D wave not supported
		endif
		index += 1
	while (1)
	//--sauvegarde des variables (obj.type 2)
	index = 0
	do 
		obj = GetIndexedObjName(df, 2, index)
		if (strlen(obj) == 0)
			break
		endif
		NVAR val = $tools_path_build(df, obj)
		str = "TYPE:" + kNVAR + ";PATH:" + df  + ":"
		str += obj  + ";VAL:" + num2str(val) + ";" + kTERM
		fprintf refNum, "%s" str
		index += 1
	while (1)
	//--sauvegarde des chaines (obj.type 3)
	index = 0
	do 
		obj = GetIndexedObjName(df, 3, index)
		if (strlen(obj) == 0)
			break
		endif
		SVAR str_var = $tools_path_build(df, obj)
		str = "TYPE:" + kSVAR + ";PATH:" + df  + ":" 
		str += obj  + ";VAL:" + str_var + ";" + kTERM 
		fprintf refNum, "%s" str
		index += 1
	while (1)
	//--restore DF precedent
	SetDataFolder previous_df
	return kNO_ERROR
end
//==============================================================================
// fonction : tools_df_restore
//==============================================================================
function tools_df_restore ([path])
	String path
	Variable refNum
	if (! ParamIsDefault(path))
		Open/R/Z=1 refNum as path
		if (! refNum)
			return kERROR
		endif
	else
		Open/R refNum
		if (V_flag == kERROR || !strlen(S_fileName))
			return kERROR
		endif
	endif
	tools_df_read_objets_from_file(refNum)
	Close refNum
	return kNO_ERROR
end
//==============================================================================
// fonction : tools_df_read_objets_from_file
//==============================================================================
function tools_df_read_objets_from_file (refNum)
	// TODO: BUG if text contains come ctrl char such as \r,\n,...
	// TODO: the tangodatabase df produces the bug (some \n in cmd or attribute doc)
	Variable refNum
	String str
	String obj
	String path
	String obj_path
	Variable nobj_val
	String sobj_val
	do
		freadline refNum, str
		if (strlen(str) == 0)
			break
		endif
		obj_path = tools_df_object_path(str)
		path = obj_path
		tools_split_obj_path(path, obj)
		tools_path_remove_quotes(path)
		tools_df_make(path, 0)
		String type = tools_df_object_type(str)
		strswitch (type)
			case kNVAR:
				nobj_val = tools_df_num_object_val(str)
				Variable/G $obj_path = nobj_val
				break
			case kSVAR:
				sobj_val = tools_df_str_object_val(str)
				String/G $obj_path = sobj_val
				break
			case kNWAV:
			case kSWAV:
				Variable dim0 = tools_df_wave_object_dim0(str)
				Variable dim1 = tools_df_wave_object_dim1(str)
				Variable dim2 = tools_df_wave_object_dim2(str)
				Variable dim3 = tools_df_wave_object_dim3(str)
				if (! cmpstr(type, kSWAV))
					Make/T/O/N=(dim0,dim1,dim2,dim3) $obj_path 
				else
					Make/O/N=(dim0,dim1,dim2,dim3) $obj_path 
				endif
				Variable i
				Variable npnts = dim0 * (dim1 ? dim1 : 1) * (dim2 ? dim2 : 1) * (dim3 ? dim3 : 1) 
				for (i = 0; i < npnts; i += 1)
					freadline refNum, str
					execute(str)
				endfor
				break
		endswitch
	while (1)
	return kNO_ERROR
end
//==============================================================================
// tools_get_listbox_colwidths
//==============================================================================
function tools_get_listbox_colwidths (lw, ww, min_w, [f, fs])
	Wave/T lw
	Wave ww
	Variable min_w 
	String f
	Variable fs
	if (ParamIsDefault(f))
		f = "default"
	endif
	if (ParamIsDefault(fs))
		fs = kLB_FONTSIZE
	endif
	Variable nrow = dimsize(lw, 0)
	Variable ncol = dimsize(lw, 1)
	Redimension /N=(ncol) ww
	Variable i, j, len, max_len, max_len_idx, wd
	for (j = 0; j < ncol; j += 1)
		max_len = 0
		max_len_idx = 0
		for (i = 0; i < nrow; i += 1)
			len = strlen(lw[i][j])
			if (len > max_len)
				max_len = len
				max_len_idx = i 
			endif
		endfor
		max_len = FontSizeStringWidth(f, fs, 0, lw[max_len_idx][j])
		wd = max_len + ceil(0.15 * max_len)
		ww[j] = (wd > min_w) ? wd : min_w
	endfor
end 
//==============================================================================
// fonction : tools_wave_list
//==============================================================================
function tools_wave_list (df, list, type, dims)
	String df
	String &list
	Variable type
	Variable dims
	if (strlen(df) == 0 || DataFolderExists(df) == 0)
		return kNO_ERROR
	endif
	String previous_df = GetDataFolder(1)
	SetDataFolder df
	String sub_df
	Variable index = 0
	do
		sub_df = GetIndexedObjName(":", 4, index)
		if (strlen(sub_df) == 0)
			break
		endif
		tools_wave_list (sub_df, list, type, dims)
		index += 1
	while(1)
	String dims_option = ""
	if (dims > 0)
		dims_option = "DIMS:" + num2str(dims)
	endif
	String current_df_wav_list = WaveList("*",";",dims_option)
	if (strlen(current_df_wav_list) == 0) 
		SetDataFolder previous_df
		return kNO_ERROR
	endif 
	String wname
	Variable i = 0
	do
		wname = StringFromList(i, current_df_wav_list)
		if (strlen(wname) == 0)
			break
		endif
		if (type >= 0 && WaveType(wname) == type)
			list += GetDataFolder(1) + wname + ";"
		endif
		i += 1
	while (1)
	SetDataFolder previous_df
	return kNO_ERROR
end
//==============================================================================
// fonction : tools_wave_path - wave must be in the current datafolder
//==============================================================================
function/S tools_wave_path (w)
	WAVE &w
	return GetDataFolder(1) + NameOfWave(w)
end
//==============================================================================
// fonction : tools_str_list_add
//==============================================================================
function/S tools_str_list_add (item, list)
	String item
	String list
	if (strlen(list) != 0)
		list += ";" 
	endif
	list += item
	return list
end
//==============================================================================
// fonction : tools_str_list_remove
//==============================================================================
function/S tools_str_list_remove (item_tbr, list)
	String item_tbr
	String list
	String item
	Variable i = 0
	String new_list = ""
	do
		item = StringFromList(i, list)
		if (strlen(item) == 0)
			break
		endif
		if (cmpstr(item, item_tbr) != 0)
			new_list += item + ";" 
		endif
		i += 1
	while (1)
	return new_list
end
//==============================================================================
// tools_win_note_set
//==============================================================================
function tools_win_note_set (win_name, win_note)
	String win_name
	String win_note
	SetWindow $win_name note=win_note
end
//==============================================================================
// tools_win_note_get
//==============================================================================
function/S tools_win_note_get (win_name)
	String win_name
	GetWindow $win_name note
	return S_Value
end
//==============================================================================
// tools_win_note_set_num_val
//==============================================================================
function tools_win_note_set_num_val (win_name, key, new_value)
	String win_name
	String key
	Variable new_value
	GetWindow $win_name note
	String win_note = ReplaceNumberByKey(key, S_Value, new_value)
	SetWindow $win_name note=win_note
	return kNO_ERROR
end
//==============================================================================
// tools_win_note_get_num_val
//==============================================================================
function tools_win_note_get_num_val (win_name, key)
	String win_name
	String key
	GetWindow $win_name note
	return NumberByKey(key, S_Value)
end
//==============================================================================
// tools_win_note_set_str_val
//==============================================================================
function tools_win_note_set_str_val (win_name, key, new_str_value)
	String win_name
	String key
	String new_str_value
	GetWindow $win_name note
	String win_note = ReplaceStringByKey(key, S_Value, new_str_value)
	SetWindow $win_name note=win_note
	return kNO_ERROR
end
//==============================================================================
// tools_win_note_get_str_val
//==============================================================================
function/S tools_win_note_get_str_val (win_name, key)
	String win_name
	String key
	GetWindow $win_name note
	return StringByKey(key, S_Value)
end
//==============================================================================
// tools_win_note_dump
//==============================================================================
function tools_win_note_dump (win_name)
	String win_name
	GetWindow $win_name note
	print "Note of window " + win_name + ": " + S_Value
end
//==============================================================================
// tools_point_in_rect
//==============================================================================
function  tools_point_in_rect (p, r)
	Struct Point &p  
	Struct Rect &r 
	if ((p.h >= r.left) && (p.h <= r.right) && (p.v >= r.top) && (p.v <= r.bottom))
		return 1
	endif
	return 0
end