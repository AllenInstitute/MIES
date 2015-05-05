#pragma rtGlobals = 1
#pragma version = 1.0
#pragma IgorVersion = 6.0

//==============================================================================
// tango.ipf
//------------------------------------------------------------------------------
// N.Leclercq - SOLEIL
//==============================================================================

//==============================================================================
// DEPENDENCIES
//==============================================================================
#include "tango_tools"

//==============================================================================
// CONSTS
//==============================================================================
// TANGO DEVICE STATES
//------------------------------------------------------------------------------
constant kDeviceStateON      = 0
constant kDeviceStateOFF     = 1
constant kDeviceStateCLOSE   = 2
constant kDeviceStateOPEN    = 3
constant kDeviceStateINSERT  = 4 
constant kDeviceStateEXTRACT = 5
constant kDeviceStateMOVING  = 6
constant kDeviceStateSTANDBY = 7
constant kDeviceStateFAULT   = 8
constant kDeviceStateINIT    = 9
constant kDeviceStateRUNNING = 10
constant kDeviceStateALARM   = 11
constant kDeviceStateDISABLE = 12
constant kDeviceStateUNKNOWN = 13
//------------------------------------------------------------------------------
// TANGO ATTRIBUTE QUALITIES
//------------------------------------------------------------------------------
constant kAttrQualityUNKNOWN 		= -1
constant kAttrQualityVALID 		=  0
constant kAttrQualityINVALID		=  1
constant kAttrQualityALARM		=  2
constant kAttrQualityCHANGING		=  3
constant kAttrQualityWARNING		=  4
//------------------------------------------------------------------------------
// TANGO ATTRIBUTE ACCESS
//------------------------------------------------------------------------------
constant kREAD 				= 0x0
constant kREAD_WITH_WRITE = 0x1
constant kWRITE				= 0x2
constant kREAD_WRITE 		= 0x3
//------------------------------------------------------------------------------
// TANGO ATTRIBUTE FORMATS
//------------------------------------------------------------------------------
constant kSCALAR		= 0 	
constant kSPECTRUM	= 1
constant kIMAGE    	= 2	
//------------------------------------------------------------------------------
// TANGO DATA TYPES
//------------------------------------------------------------------------------
constant kDEVVOID                 = 0
constant kDEVBOOLEAN              = 1
constant kDEVSHORT                = 2
constant kDEVLONG                 = 3
constant kDEVFLOAT                = 4
constant kDEVDOUBLE               = 5
constant kDEVUSHORT               = 6
constant kDEVULONG                = 7
constant kDEVSTRING               = 8
constant kDEVVARCHARARRAY         = 9
constant kDEVVARSHORTARRAY        = 10
constant kDEVVARLONGARRAY         = 11
constant kDEVVARFLOATARRAY        = 12
constant kDEVVARDOUBLEARRAY       = 13
constant kDEVVARUSHORTARRAY       = 14
constant kDEVVARULONGARRAY        = 15
constant kDEVVARSTRINGARRAY       = 16
constant kDEVVARLONGSTRINGARRAY   = 17
constant kDEVVARDOUBLESTRINGARRAY = 18
constant kDEVSTATE                = 19
constant kCONSTDEVSTRING          = 20
constant kDEVVARBOOLEANARRAY      = 21
constant kDEVUCHAR                = 22
//------------------------------------------------------------------------------
// TANGO BINDING ERROR CODES
//------------------------------------------------------------------------------
constant kERROR		= -1	
constant kNO_ERROR	=  0
//------------------------------------------------------------------------------
// REMAINING CONST ARE PRIVATE, OPAQUE FOR USER! 
//------------------------------------------------------------------------------
constant kSTRING  = 0x00
constant kCHAR    = 0x08
constant kBOOL    = 0x08
constant kUCHAR   = 0x48		
constant kSHORT   = 0x10	
constant kUSHORT  = 0x50	
constant kLONG    = 0x20
constant kULONG   = 0x60
constant kLONG64  = 0xFF
constant kULONG64 = 0xFF
constant kFLOAT   = 0x02
constant kDOUBLE  = 0x04
constant kUNSUPPORTED_TYPE = 0xFF
//------------------------------------------------------------------------------
constant kSVAR = 0x00	
constant kNVAR = 0x01
constant k1DTWAV = 0x02
constant k2DTWAV = 0x03
constant k1DNWAV = 0x04
constant k2DNWAV = 0x05
//------------------------------------------------------------------------------
static constant kATTR_LABEL_COL       	= 6
static constant kATTR_UNIT_COL        	= 7
static constant kATTR_STD_UNIT_COL    	= 8
static constant kATTR_DISP_UNIT_COL   	= 9
static constant kATTR_DISP_FORMAT_COL	= 10
static constant kATTR_DESC_COL			= 15
static constant kATTR_WATTR_COL			= 16
//------------------------------------------------------------------------------
strconstant kLB_FONT = "MS Sans Serif" 
//------------------------------------------------------------------------------
constant kLB_FONTSIZE = 12
//------------------------------------------------------------------------------
strconstant kNAME_SEP = "#"
//------------------------------------------------------------------------------
strconstant kWORKING_DF = "root:tango:tmp"
//------------------------------------------------------------------------------
// structure TangoBindingPrefs
//------------------------------------------------------------------------------
Structure TangoBindingPrefs
 //- preferences structure version number (100 means 1.0.0)
 uint32	version
 //- default polling peroid for tango monitor
 double tmon_default_pp
 //- the tango host (database device name)
 char tango_host[100]
 //- reserved 
 uint32 reserved[100]
EndStructure
//------------------------------------------------------------------------------
// structure CmdArgIO
//------------------------------------------------------------------------------
Structure CmdArgIO
	//- command argin or argout for DevString 
	String str_val
	//- command argin or argout for any TANGO scalar type except DevString  
	Variable var_val
	//-  path to argin or argout for any TANGO scalar type
	String val_path
	//- path to the argin or argout wave for any TANGO numeric array type or 
	//- numeric part of a DevVar[Long,Double]StringArray
	String num_wave_path 
	//- path to the argin or argout wave for for TANGO DevVarStringArray or 
	//- text part of a DevVar[Long,Double]StringArray
	String str_wave_path  
EndStructure

//------------------------------------------------------------------------------
// structure AttributeValue : used to to read or write an attribute  
//------------------------------------------------------------------------------
Structure AttributeValue
	//------------------------------------------------------------------------
	//- struct member: dev
	//- desc: device name
	//------------------------------------------------------------------------
	String dev 
	//------------------------------------------------------------------------
	//- struct member: attr
	//- desc: attribute name
	//------------------------------------------------------------------------
	String attr
	//------------------------------------------------------------------------
	//- struct member: format 
	//- desc: attribute data format - 0:kSCALAR, 1:kSPECTRUM or 2:kIMAGE
	//- set when attribute is read (in order to ease data processing)
	//- no need to set this member when writting the attribute
	//------------------------------------------------------------------------
	int16 format 
	//------------------------------------------------------------------------
	//- struct member: type 
	//- desc: attribute data type - 0:kSTRING, ..., 0x04:kDOUBLE (see constants)
	//- set when attribute is read (in order to ease data processing)
	//- no need to set this member when writting the attribute
	//------------------------------------------------------------------------
	int16 type  
	//------------------------------------------------------------------------ 
	//- struct member: ts
	//- desc: timestamp in seconds since Igor's time reference (01/01/1970)
	//------------------------------------------------------------------------
	double ts
	//------------------------------------------------------------------------ 
	//- struct member: qlt
	//- desc: attribute quality (see previous definitions for possible values)
	//------------------------------------------------------------------------
	int16 quality
	//------------------------------------------------------------------------ 
	//- struct member: str_val
	//- desc: attribute value for string Scalar attributes
	//------------------------------------------------------------------------
	//- valid if format = kSCALAR and type = kSTRING - undefined otherwise 
	//- undefined in case of error during attribute reading - it means that you 
	//- should always check the error code returned by tango_read_attr before 
	//- trying to access this string
	//------------------------------------------------------------------------
	String str_val
	//-------------------------------------------------------------------------
	//- struct member: var_val 
	//- desc: attribute value for Scalar attributes
	//-------------------------------------------------------------------------
	//- valid if format = kSCALAR and type != kSTRING - undefined otherwise 
	//- undefined in case of error during attribute reading - it means that you 
	//- should always check the error code returned by tango_read_attr 
	//- before trying to access this variable
	//------------------------------------------------------------------------
	Variable var_val
	//-------------------------------------------------------------------------
	//-------------------------------------------------------------------------
	//- struct member: val_path
	//- desc: full path to the data - fully qualified path (from root:) to the 
	//- datafolder into which the attribute value is stored. Use this to retrieve 
	//- the associated wave of a SPECTRUM or IMAGE attribute wave is stored. 
	//- this member is also valid for a SCALAR attribute. In this case it will
	//- contain the full path to the associated variable or string.
	//-------------------------------------------------------------------------
	String val_path
EndStructure
//------------------------------------------------------------------------------
//- maximum num of attributes than can be read in one call using tango_read_attrs
constant kMAX_NUM_ATTR = 16
//------------------------------------------------------------------------------
Structure AttributeValues
	//- the name of device on which the nattrs attributes should be read
	String dev
	//- actual the num of attributes to read - must be <= kMAX_NUM_ATTR
	//- should obviously equal the num of valid AttributeValue in the values member
	int16 nattrs
	//- full path to the data folder in which attribute values should be placed in 
	//- case "val_path" is not specified in the associated AttributeValue. see the
	//- <test_tango_read_attrs> example in <tutorial.ipf> for important details.
	String df
	//- an array of kMAX_NUM_ATTR AttributeValue - if you want to be able to read
	//- more than kMAX_NUM_ATTR attributes in one call just increase the value of
	//- the kMAX_NUM_ATTR constant
	STRUCT AttributeValue vals[kMAX_NUM_ATTR]
EndStructure
//------------------------------------------------------------------------------

//==============================================================================
// tango_init_cmd_argio
//==============================================================================
function tango_init_cmd_argio (argio, [nv, sv, v_path, nw_path, sw_path])
	Struct CmdArgIO &argio
	Variable nv
	String sv
	String v_path
	String nw_path
	String sw_path
	if (ParamIsDefault(nv))
		argio.var_val = NAN
	else
		argio.var_val = nv
	endif
	if (ParamIsDefault(sv))
		argio.str_val = ""
	else
		argio.str_val = sv
	endif
	if (ParamIsDefault(v_path))
		argio.val_path = ""
	else
		argio.val_path = v_path
	endif
	if (ParamIsDefault(nw_path))
		argio.num_wave_path = ""
	else
		argio.num_wave_path = nw_path
	endif
	if (ParamIsDefault(sw_path))
		argio.str_wave_path = ""
	else
		argio.str_wave_path = sw_path
	endif
end
//==============================================================================
// tango_cmd_inout
//==============================================================================
function tango_cmd_inout (dev, cmd, [arg_in, arg_out])
	String dev
	String cmd
	Struct CmdArgIO &arg_in
	Struct CmdArgIO &arg_out
	String cur_df = GetDataFolder(1)
	if (tango_enter_tmp_df(dev, prev_df=cur_df) == kERROR)
		tango_leave_tmp_df(cur_df)
		return kERROR
	endif
	Variable argin_type = tango_get_cmd_argin_type(dev, cmd)
	if (ParamIsDefault(arg_in) && argin_type != kDEVVOID)
		String txt = "TANGO API ERROR in function 'tango_cmd_inout' - "
		txt += "CmdArgIO expected for argin [command argin type is not VOID]"
		print txt
		tango_leave_tmp_df(cur_df)
		return kERROR
	endif
	Variable argout_type = tango_get_cmd_argout_type(dev, cmd)
	if (ParamIsDefault(arg_out) && argout_type != kDEVVOID)
		txt = "TANGO API ERROR in function 'tango_cmd_inout' - "
		txt += "CmdArgIO expected for argout [command argout type is not VOID]"
		print txt
		tango_leave_tmp_df(cur_df)
		return kERROR
	endif
	String argin_str
	switch (argin_type)
		case kDEVVOID:
			argin_str = ""
			break
		case kDEVSTATE:
		case kDEVBOOLEAN:
		case kDEVSHORT:
		case kDEVLONG:
		case kDEVFLOAT:
		case kDEVDOUBLE:
		case kDEVUSHORT:
		case kDEVULONG:
		case kDEVUCHAR:
			if (! strlen(arg_in.val_path))
				Variable/G var_in_tmp_ = arg_in.var_val
				argin_str = "var_in_tmp_";
			else
				argin_str = arg_in.val_path
			endif
			break
		case kDEVSTRING:
			if (! strlen(arg_in.val_path))
				String/G str_in_tmp_ = arg_in.str_val
				argin_str = "str_in_tmp_";
			else
				argin_str = arg_in.val_path
			endif
			break
		case kDEVVARCHARARRAY:
		case kDEVVARSHORTARRAY:
		case kDEVVARLONGARRAY:
		case kDEVVARFLOATARRAY:
		case kDEVVARDOUBLEARRAY:
		case kDEVVARUSHORTARRAY:
		case kDEVVARULONGARRAY:
		case kDEVVARBOOLEANARRAY:
			argin_str = arg_in.num_wave_path
			break
		case kDEVVARSTRINGARRAY:
			argin_str = arg_in.str_wave_path
			break
		case kDEVVARLONGSTRINGARRAY:
		case kDEVVARDOUBLESTRINGARRAY:
			argin_str = arg_in.num_wave_path + kNAME_SEP + arg_in.str_wave_path
			break
		default:
			txt = "TANGO API ERROR in function 'tango_cmd_inout' - "
			txt += "Unexpected/supported data type for command arg-in"
			print txt
			tango_leave_df(cur_df)
			return kERROR
			break
	endswitch    
	String  argout_str
	switch (argout_type)
		case kDEVVOID:
			argout_str = ""
			break
		case kDEVSTATE:
		case kDEVBOOLEAN:
		case kDEVSHORT:
		case kDEVLONG:
		case kDEVFLOAT:
		case kDEVDOUBLE:
		case kDEVUSHORT:
		case kDEVULONG:
		case kDEVUCHAR:
		case kDEVSTRING:
			if (strlen(arg_out.val_path))
				argout_str = arg_out.val_path
			else
				argout_str = LowerStr(cmd) + "_out";
				arg_out.val_path = GetDataFolder(1) + argout_str
			endif
			break
		case kDEVVARCHARARRAY:
		case kDEVVARSHORTARRAY:
		case kDEVVARLONGARRAY:
		case kDEVVARFLOATARRAY:
		case kDEVVARDOUBLEARRAY:
		case kDEVVARUSHORTARRAY:
		case kDEVVARULONGARRAY:
		case kDEVVARBOOLEANARRAY:
			if (strlen(arg_out.num_wave_path))
				argout_str = arg_out.num_wave_path
			else
				argout_str = LowerStr(cmd) + "_out";
				arg_out.num_wave_path = GetDataFolder(1) + argout_str
			endif
			break
		case kDEVVARSTRINGARRAY:
			if (strlen(arg_out.str_wave_path))
				argout_str = arg_out.str_wave_path
			else
				argout_str = LowerStr(cmd) + "_out";
				arg_out.str_wave_path = GetDataFolder(1) + argout_str
			endif
			break
		case kDEVVARLONGSTRINGARRAY:
		case kDEVVARDOUBLESTRINGARRAY:
			if (strlen(arg_out.num_wave_path) && strlen(arg_out.str_wave_path))
				argout_str = arg_out.num_wave_path + kNAME_SEP + arg_out.str_wave_path
			else
				argout_str = LowerStr(cmd) + "_nout" + kNAME_SEP + LowerStr(cmd) + "_sout"
				arg_out.num_wave_path = GetDataFolder(1) + LowerStr(cmd) + "_nout";
				arg_out.str_wave_path = GetDataFolder(1) + LowerStr(cmd) + "_sout";
			endif
			break
		default:
			txt = "TANGO API ERROR in function 'tango_cmd_inout' - "
			txt += "Unexpected/supported data type for command arg-out."
			print txt
			tango_leave_df(cur_df)
			return kERROR
			break
	endswitch  
	if (tango_command_inout(dev, cmd, argin_str, argout_str) == kERROR)
		tango_leave_tmp_df(cur_df)
		return kERROR
	endif
	switch (argout_type)
		case kDEVVOID:
			break
		case kDEVSTATE:
		case kDEVBOOLEAN:
		case kDEVSHORT:
		case kDEVLONG:
		case kDEVFLOAT:
		case kDEVDOUBLE:
		case kDEVUSHORT:
		case kDEVULONG:
		case kDEVUCHAR:
			NVAR/Z var_out_tmp = $argout_str
			if (! NVAR_Exists(var_out_tmp))
				txt = "TANGO API ERROR in function 'tango_cmd_inout' - "
				txt += "Could not retrieve the command argout!"
				print txt
				tango_leave_tmp_df(cur_df)
				return kERROR
			endif
			arg_out.var_val = var_out_tmp
			arg_out.str_val = ""
			arg_out.val_path = argout_str
			arg_out.num_wave_path = ""
			arg_out.str_wave_path = ""
			break
		case kDEVSTRING:
			SVAR/Z str_out_tmp = $argout_str
			if (! SVAR_Exists(str_out_tmp))
				txt = "TANGO API ERROR in function 'tango_cmd_inout' - "
				txt += "Could not retrieve the command argout!"
				print txt
				tango_leave_tmp_df(cur_df)
				return kERROR
			endif
			arg_out.str_val = str_out_tmp
			arg_out.var_val = NAN
			arg_out.val_path = argout_str
			arg_out.num_wave_path = ""
			arg_out.str_wave_path = ""
			break
		case kDEVVARCHARARRAY:
		case kDEVVARSHORTARRAY:
		case kDEVVARLONGARRAY:
		case kDEVVARFLOATARRAY:
		case kDEVVARDOUBLEARRAY:
		case kDEVVARUSHORTARRAY:
		case kDEVVARULONGARRAY:
		case kDEVVARBOOLEANARRAY:
			arg_out.str_val = ""
			arg_out.var_val = NAN
			arg_out.str_wave_path = ""
			break
		case kDEVVARSTRINGARRAY:
			arg_out.str_val = ""
			arg_out.var_val = NAN
			arg_out.num_wave_path = "" 
			break
		case kDEVVARLONGSTRINGARRAY:
		case kDEVVARDOUBLESTRINGARRAY:
			arg_out.str_val = ""
			arg_out.var_val = NAN
			break
	endswitch
	tango_leave_tmp_df(cur_df)
	return kNO_ERROR
end
//==============================================================================
// tango_cleanup_path
//==============================================================================
static function tango_cleanup_path (p)
	String &p
 	Variable start_pos = strlen(p) - 1
	if (strsearch(p, ":", start_pos) != -1)
		p = p[0, start_pos - 1] 		
	endif
end		
//==============================================================================
// tango_init_attr_val
//==============================================================================
function tango_init_attr_val (attr_val_io, [dev, attr, nval, sval, path])
	Struct AttributeValue &attr_val_io
	String dev
	String attr
	Variable nval
	String sval
	String path
	if (ParamIsDefault(dev))
		attr_val_io.dev = ""
	else
		attr_val_io.dev = dev
	endif
	if (ParamIsDefault(attr))
		attr_val_io.attr = ""
	else
		attr_val_io.attr = attr
	endif
	if (ParamIsDefault(sval))
		attr_val_io.str_val = ""
	else
		attr_val_io.str_val = sval
	endif
	if (ParamIsDefault(nval))
		attr_val_io.var_val = NAN
	else
		attr_val_io.var_val = nval
	endif
	if (ParamIsDefault(path))
		attr_val_io.val_path = ""
	else
		attr_val_io.val_path = path
	endif
	attr_val_io.format = -1
	attr_val_io.type = -1  
	attr_val_io.quality = -1  
	attr_val_io.ts = 0
end
//==============================================================================
// tango_init_attr_vals
//==============================================================================
function tango_init_attr_vals (attr_vals_io, [nattrs, dev, path])
	Struct AttributeValues &attr_vals_io
	Variable nattrs
	String dev
	String path
	if (ParamIsDefault(nattrs) == 0)
		if (nattrs <= 0 || nattrs >= kMAX_NUM_ATTR)
			String txt = "TANGO API ERROR in function 'tango_read_attrs'\n"
			txt += "Invalid number of attributes specified [optional 'nattrs' is invalid]"
			print txt
			return kERROR
		endif
		attr_vals_io.nattrs = nattrs
	endif
	if (ParamIsDefault(dev))
		attr_vals_io.dev = ""
	else
		attr_vals_io.dev = dev
	endif
	if (ParamIsDefault(path))
		attr_vals_io.df = ""
	else
		attr_vals_io.df = path
	endif
	Variable i 
	Variable max_i = ParamIsDefault(nattrs) ? kMAX_NUM_ATTR : nattrs
	for (i = 0; i < max_i; i += 1)
		tango_init_attr_val(attr_vals_io.vals[i])	
	endfor
end
//==============================================================================
// tango_read_attr
//==============================================================================
function tango_read_attr (attr_val_io)
	Struct AttributeValue &attr_val_io
	//- get current datafolder
	String cur_df = GetDataFolder(1)
	//- name of attr value (i.e. var, string or wave name) defaults to attr name 
	String result_name = attr_val_io.attr
	//- path hell...
	String path = attr_val_io.val_path
	if (strlen(path))
		//- is it an existing path?
		if (DataFolderExists(path))
			//- yes it is!
			//- user did not provide full path to value (i.e. no var or wave name)
			//- ok, no problem here, name of attr value will be attr name (the default) 	
			SetDataFolder $path
		else
			//- no it isn't an existing datafolder!
			//- does it ends with a ':'
			if (cmpstr(path[strlen(path) - 1], ":") == 0)
				//- yes it ends with a ':'
				//- here, we use attr name for result name but may have to build the df
				if (tools_df_make(path, 1) == kERROR)
					String txt = "TANGO API ERROR in function 'tango_read_attr'\n"
					txt += "Could not create datafolder: " + path
					print txt
					return kERROR
				endif
			else
				//- no it doesn't end with a ':'
				//- so, it is supposed to be the full path to the result
				//- separate path and result name
				tools_split_obj_path(path, result_name)
				//- enter 'path' datafolder (create it if it doesn't exist)
				if (tools_df_make(path, 1) == kERROR)
					txt = "TANGO API ERROR in function 'tango_read_attr'\n"
					txt += "Could not create datafolder: " + path
					print txt
					return kERROR
				endif
			endif
		endif
	endif
	//- read the attribute
	//- result will be placed into the current datafolder and named "$result_name" 
	if (tango_read_attribute(attr_val_io.dev, attr_val_io.attr, result_name) == kERROR)
		tango_leave_df(cur_df)
		return kERROR
	endif
	attr_val_io.type = tango_get_attr_type(attr_val_io.dev, attr_val_io.attr)
	attr_val_io.format = tango_get_attr_format(attr_val_io.dev, attr_val_io.attr)
	switch (attr_val_io.format)
		case kSCALAR:
			if (attr_val_io.type == kSTRING)
				SVAR scalar_txt_result = $result_name
				attr_val_io.str_val = scalar_txt_result
				attr_val_io.var_val = NAN
				KillStrings /Z $result_name
			else
				NVAR/C scalar_num_result = $result_name
				attr_val_io.var_val = scalar_num_result
				attr_val_io.str_val = ""
				KillVariables /Z $result_name
			endif
			attr_val_io.val_path = ""
			break
		case kIMAGE:
		case kSPECTRUM:
			attr_val_io.var_val = NAN
			attr_val_io.str_val = ""
			attr_val_io.val_path = GetDataFolder(1) + result_name
			break
	endswitch
	NVAR/Z ts = $(result_name + "_ts")
	attr_val_io.ts = NVAR_Exists(ts) ? ts : datetime
	KillVariables /Z $(result_name + "_ts")
	NVAR/Z qlt = $(result_name + "_qlt")
	attr_val_io.quality = NVAR_Exists(qlt) ? qlt : kAttrQualityUNKNOWN
	KillVariables /Z $(result_name + "_qlt")
	tango_leave_df(cur_df)
	return kNO_ERROR
end
//==============================================================================
// tango_read_attrs
//==============================================================================
function tango_read_attrs (attr_vals_io)
	Struct AttributeValues &attr_vals_io
	if (attr_vals_io.nattrs <= 0 || attr_vals_io.nattrs >= kMAX_NUM_ATTR)
		String txt = "TANGO API ERROR in function 'tango_read_attrs'\n"
		txt += "Invalid AttributesValues.nattrs specified. Must be in [1, " + num2str(kMAX_NUM_ATTR) + "]"
		print txt
		return kERROR
	endif
	String cur_df = GetDataFolder(1)
	//- build the attribute list
	String attr_list = ""
	Variable n;
	for (n = 0; n < attr_vals_io.nattrs; n += 1)
		if (strlen(attr_vals_io.vals[n].val_path))
			attr_list = tango_attr_val_list_add(attr_list, attr_vals_io.vals[n].attr, attr_vals_io.vals[n].val_path)
		else
			attr_list = tango_attr_val_list_add(attr_list, attr_vals_io.vals[n].attr, attr_vals_io.vals[n].attr)
		endif
	endfor
	//- create the destination datafolder from the attribute for which no 'val_path' is 
	//- specifed it means that within reading call, several attributes may be placed into 
	//- a specific datafolder while others will have their value created into the current 
	//- datafolder or the datafolder specified by 'attr_vals_io.df' (if not empty)    
	if (strlen(attr_vals_io.df))
		if (tools_df_make(attr_vals_io.df, 1) == kERROR)
			txt = "TANGO API ERROR in function 'tango_read_attrs'\n"
			txt += "Could not create datafolder: " +  attr_vals_io.df
			print txt
			tango_leave_df(cur_df)
			return kERROR
		endif
	endif
	if (tango_read_attributes(attr_vals_io.dev, attr_list) == kERROR)
		tango_leave_df(cur_df)
		return kERROR
	endif
	String val_name
	for (n = 0; n < attr_vals_io.nattrs; n += 1)
		if (strlen(attr_vals_io.vals[n].val_path))
			val_name = attr_vals_io.vals[n].val_path
		else
			val_name = attr_vals_io.vals[n].attr
		endif
		attr_vals_io.vals[n].type = tango_get_attr_type(attr_vals_io.dev, attr_vals_io.vals[n].attr)
		attr_vals_io.vals[n].format = tango_get_attr_format(attr_vals_io.dev, attr_vals_io.vals[n].attr)
		attr_vals_io.vals[n].dev = attr_vals_io.dev 
		switch (attr_vals_io.vals[n].format)
			case kSCALAR:
				if (attr_vals_io.vals[n].type == kSTRING)
					SVAR scalar_txt_result = $val_name
					attr_vals_io.vals[n].str_val = scalar_txt_result
					attr_vals_io.vals[n].var_val = NAN
					if (! strlen(attr_vals_io.vals[n].val_path))
						attr_vals_io.vals[n].val_path = ""
						KillStrings /Z $val_name
					endif
				else
					NVAR/C scalar_num_result = $val_name
					attr_vals_io.vals[n].var_val = scalar_num_result
					attr_vals_io.vals[n].str_val = ""
					if (! strlen(attr_vals_io.vals[n].val_path))
						attr_vals_io.vals[n].val_path = ""
						KillVariables /Z $val_name
					endif
				endif
				break
			case kIMAGE:
			case kSPECTRUM:
				attr_vals_io.vals[n].var_val = NAN
				attr_vals_io.vals[n].str_val = ""
				if (strlen(attr_vals_io.vals[n].val_path))
					attr_vals_io.vals[n].val_path = val_name
				else
					attr_vals_io.vals[n].val_path = GetDataFolder(1) + val_name
				endif
				break
		endswitch
		NVAR/Z ts = $(val_name + "_ts")
		attr_vals_io.vals[n].ts = NVAR_Exists(ts) ? ts : datetime
		KillVariables /Z $(val_name + "_ts")
		NVAR/Z qlt = $(val_name + "_qlt")
		attr_vals_io.vals[n].quality = NVAR_Exists(qlt) ? qlt : kAttrQualityUNKNOWN
		KillVariables /Z $(val_name + "_qlt")
	endfor
	tango_leave_df(cur_df)
	return kNO_ERROR
end
//==============================================================================
// tango_read_attrs_list
//==============================================================================
function tango_read_attrs_list (dev_name, user_attr_list)
	String dev_name
	Wave/T user_attr_list
	//- be sure the text wave exists
	if (WaveExists(user_attr_list) == 0)
		String txt = "TANGO API ERROR in function 'tango_read_attrs'\n"
		txt += "Invalid attribute list specified [1D or 2D TEXT wave expected]"
		print txt
		return kERROR
	endif
	//- convert user to tango binding attribute list
	String tango_attr_list
	user_wave_alist_to_tango_alist (user_attr_list, tango_attr_list)
	//- read attributes
	if (tango_read_attributes(dev_name,  tango_attr_list) == kERROR)
		return kERROR
	endif
	//- populate each Attribute Value (attach value to each attribute)
	Variable n 
	for (n = 0; n < DimSize(user_attr_list, 0); n += 1)
		String result_name
		if (WaveDims(user_attr_list) == 2)
			if (strlen(user_attr_list[n][1]))
				result_name = user_attr_list[n][1]
			else
				result_name = user_attr_list[n][0]
			endif
		else
			result_name = user_attr_list[n]
		endif
		KillVariables /Z $(result_name + "_ts")
	endfor
	return kNO_ERROR
end
//==============================================================================
// user_wave_alist_to_tango_alist
//==============================================================================
static function user_wave_alist_to_tango_alist (wave_alist, tango_attr_list)
	WAVE/T wave_alist
	String &tango_attr_list
	if (WaveExists(wave_alist) == 0 || WaveType(wave_alist) != 0 || WaveDims(wave_alist) > 2)
		String txt = "TANGO API ERROR in function 'user_wave_alist_to_tango_alist'\n"
		txt += "Invalid attribute list specified [1D or 2D TEXT wave expected]"
		print txt
		return kERROR
	endif
	Variable n = DimSize(wave_alist, 0)
	if (n == 0)
		txt = "TANGO API ERROR in function 'user_wave_alist_to_tango_alist'\n"
		txt += "Empty attribute list specified. Should contains at least one attribute"
		print txt
		return kERROR
	endif 
	tango_attr_list = "" 
	Variable i
	Variable attr_name_valid
	for (i = 0; i < n; i += 1)
		if (WaveDims(wave_alist) == 1)
			attr_name_valid = strlen(wave_alist[i]) ? 1 : 0
		else
			attr_name_valid = strlen(wave_alist[i][0]) ? 1 : 0
		endif
		if (attr_name_valid)
			if (i) 
				tango_attr_list += ";"
			endif
			tango_attr_list += wave_alist[i][0] + kNAME_SEP
			if (WaveDims(wave_alist) == 2)
				if (strlen(wave_alist[i][1]))
					tango_attr_list += wave_alist[i][1]
				else
					tango_attr_list += wave_alist[i][0]
				endif
			else
				tango_attr_list += wave_alist[i]
			endif
		endif
	endfor
	return kNO_ERROR
end
//==============================================================================
// user_wave_alist_to_avals
//==============================================================================
static function user_wave_alist_to_avals (dev_name, wave_alist, attr_vals_io)
	String dev_name
	WAVE/T wave_alist
	Struct AttributeValues &attr_vals_io
	if (WaveExists(wave_alist) == 0 || WaveType(wave_alist) != 0 || WaveDims(wave_alist) > 2)
		String txt = "TANGO API ERROR in function 'user_wave_alist_to_avals'\n"
		txt += "Invalid attribute list specified [1D or 2D TEXT wave expected]"
		print txt
		return kERROR
	endif
	Variable n = DimSize(wave_alist, 0)
	if (n == 0)
		txt = "TANGO API ERROR in function 'user_wave_alist_to_avals'\n"
		txt += "Empty attribute list specified. Should contains at least one attribute"
		print txt
		return kERROR
	endif 
	attr_vals_io.dev = dev_name
	attr_vals_io.nattrs = n
	attr_vals_io.df = ""
	Variable i
	for (i = 0; i < n; i += 1)
		if (WaveDims(wave_alist) == 1)
			attr_vals_io.vals[i].attr = wave_alist[i]
		else
			attr_vals_io.vals[i].attr = wave_alist[i][0]	
		endif
	endfor
	return kNO_ERROR
end
//==============================================================================
// tango_write_attr
//==============================================================================
function tango_write_attr (attr_val_io)
	Struct AttributeValue &attr_val_io
	Variable type = tango_get_attr_type(attr_val_io.dev, attr_val_io.attr)
	Variable format = tango_get_attr_format(attr_val_io.dev, attr_val_io.attr)
	switch (format)
		case kSCALAR:
			switch(type)
				case kSTRING:
					if (tango_write_attribute(attr_val_io.dev, attr_val_io.attr, attr_val_io.str_val) == kERROR)
						return kERROR
					endif
					break
				default:
					Variable/G var_tmp_ = attr_val_io.var_val
					if (tango_write_attribute(attr_val_io.dev, attr_val_io.attr, "var_tmp_") == kERROR)
						KillVariables/Z var_tmp_
						return kERROR
					endif
					KillVariables/Z var_tmp_
					break	
			endswitch
			break
		default:
			if (tango_write_attribute(attr_val_io.dev, attr_val_io.attr, attr_val_io.val_path) == kERROR)
				return kERROR
			endif
			break
	endswitch
	return kNO_ERROR
end
//==============================================================================
// tango_write_attrs
//==============================================================================
function tango_write_attrs (attr_vals_io)
	Struct AttributeValues &attr_vals_io
	String cur_df
	if (tango_enter_tmp_df(attr_vals_io.dev, prev_df=cur_df))
		tango_leave_tmp_df(cur_df)
		return kERROR
	endif
	if (attr_vals_io.nattrs <= 0 || attr_vals_io.nattrs >= kMAX_NUM_ATTR)
		String txt = "TANGO API ERROR in function 'tango_write_attrs' - "
		txt += "Invalid AttributesValues.nattrs specified. Must be in [1, " + num2str(kMAX_NUM_ATTR) + "]"
		print txt
		tango_leave_tmp_df(cur_df)
		return kERROR
	endif
	String attr_list = "", val_name = ""
	Variable n, attr_type, attr_format;
	for (n = 0; n < attr_vals_io.nattrs; n += 1)
		attr_type = tango_get_attr_type(attr_vals_io.dev, attr_vals_io.vals[n].attr)
		attr_format = tango_get_attr_format(attr_vals_io.dev, attr_vals_io.vals[n].attr)
		switch (attr_format)
			case kSCALAR:
				val_name = attr_vals_io.vals[n].attr
				switch(attr_type)
					case kSTRING:
						String/G $val_name 
						SVAR str_val = $val_name
						str_val = attr_vals_io.vals[n].str_val
						break
					default:
						Variable/G $val_name 
						NVAR var_val = $val_name
						var_val = attr_vals_io.vals[n].var_val
						break
				endswitch
				attr_list = tango_attr_val_list_add(attr_list, attr_vals_io.vals[n].attr, val_name)
				break
			default:
				attr_list = tango_attr_val_list_add(attr_list, attr_vals_io.vals[n].attr, attr_vals_io.vals[n].val_path)
				break
		endswitch
	endfor
	if (tango_write_attributes(attr_vals_io.dev, attr_list) == kERROR) 
		tango_leave_tmp_df(cur_df)
		return kERROR
	endif
	tango_leave_tmp_df(cur_df)
	return kNO_ERROR
end
//==============================================================================
// tango_get_global_obj
//==============================================================================
function/S tango_get_global_obj (obj_name, obj_type, [row, column, value, svalue])
	String obj_name
	Variable obj_type
	Variable row
	Variable column
	Variable value
	String svalue
	String tango_root = "root:tango:common"
	if (DataFolderExists(tango_root) == 0)
		DoAlert 0, "TANGO root datafolder has been deleted!"
		return ""
	endif
	Variable rows = 0
	if (! ParamIsDefault(row))
		rows = row	
	endif		
	Variable columns = 0
	if (! ParamIsDefault(column))
		columns = column	
	endif	
	String obj_full_name = tools_path_build("root:tango:common", obj_name)
	switch (obj_type)
		case kSVAR:
			SVAR/Z str_obj = $obj_full_name
			if (! SVAR_Exists(str_obj))
				String/G $obj_full_name = ""
				if (! ParamIsDefault(svalue))
					SVAR/Z str_obj = $obj_full_name
					str_obj = svalue 
				endif
			endif
			break
		case kNVAR:
			NVAR/Z num_obj = $obj_full_name
			if (! NVAR_Exists(num_obj))
				Variable/G $obj_full_name = ParamIsDefault(value) ? 0 : value
			endif
			break
		case k1DTWAV:
			WAVE/T/Z twav_obj = $obj_full_name
			if (! WAVEExists(twav_obj))
				Make/O/N=(rows)/T $obj_full_name = ""
				if (! ParamIsDefault(svalue))
					WAVE/T/Z twav_obj = $obj_full_name
					twav_obj = svalue 
				endif
			endif
			break
		case k2DTWAV:
			WAVE/T/Z twav_obj = $obj_full_name
			if (WAVEExists(twav_obj) == 0)
				Make/O/N=(rows,columns)/T $obj_full_name = ""
				if (! ParamIsDefault(svalue))
					WAVE/T/Z twav_obj = $obj_full_name
					twav_obj = svalue 
				endif
			endif
			break
		case k1DNWAV:
			WAVE/Z nwav_obj = $obj_full_name
			if (WAVEExists(nwav_obj) == 0)
				Make/O/N=(rows) $obj_full_name = ParamIsDefault(value) ? 0 : value
			endif
			break
		case k2DNWAV:
			WAVE/Z nwav_obj = $obj_full_name
			if (WAVEExists(nwav_obj) == 0)
				Make/O/N=(rows,columns) $obj_full_name = ParamIsDefault(value) ? 0 : value
			endif
			break
	endswitch
	return obj_full_name
end
//==============================================================================
// fonction : tango_error
//==============================================================================
function tango_error ( )
	NVAR/Z error = root:tango:common:error
	return NVAR_Exists(error) ? error : 0
end
//==============================================================================
// fonction : tango_display_error
//==============================================================================
function tango_display_error ( )
	tep_open(0)
end
//==============================================================================
// fonction : tep_open
//==============================================================================
static function tep_open (show_err_stack)
	Variable show_err_stack
	DoWindow/K tep_modal
	if (! show_err_stack)
		tango_get_error_stack()
	endif		
	WAVE/T error_stack = root:tango:common:error_stack
	if (WaveExists(error_stack) == 0 || numpnts(error_stack) == 0)
		return kNO_ERROR
	endif
	SetDimLabel 1, 0, Severity, error_stack
	SetDimLabel 1, 1, Reason, error_stack
	SetDimLabel 1, 2, Description, error_stack
	SetDimLabel 1, 3, Origin, error_stack
	Make /O /N=(dimsize(error_stack,1)) ww
	Variable min_w = FontSizeStringWidth("MS Shell Dlg", kLB_FONTSIZE, 0, "Severity")
	Wave/T es = root:tango:common:error_stack
	tools_get_listbox_colwidths(es, ww, min_w)
	if (show_err_stack)
		NewPanel /K=1 /N=tep_modal /W=(129,122.75,879.75,530)
	else
		NewPanel /K=1 /N=tep_modal /W=(129,122.75,879.75,311)
	endif
	DoWindow/C tep_modal
	DoWindow/T tep_modal, "*** TANGO Error Panel ***" 
	ModifyPanel/W=tep_modal fixedSize=1
	GroupBox grp_box,win=tep_modal,pos={17,6},size={716,138}
	GroupBox grp_box,win=tep_modal,title="Main Error",font="MS Shell Dlg"
	ListBox err_list,win=tep_modal,pos={18,167},size={715,189},frame=2,disable=1
	ListBox err_list,win=tep_modal,mode=2, font="MS Shell Dlg",fsize=kLB_FONTSIZE
	ListBox err_list,win=tep_modal,widths={ww[0],ww[1],ww[2],ww[3],ww[4]}
	ListBox err_list,win=tep_modal,listWave=error_stack
	KillWaves/Z ww   
	Variable ctrl_enable = (show_err_stack) ? 0 : 1
	ListBox err_list,win=tep_modal,disable=ctrl_enable,userColumnResize=1
	String ldf = GetDataFolder(1)
	SetDataFolder root:tango:common
	String/G reason = error_stack[0][1]
	SetVariable reason,win=tep_modal,pos={77,30},size={651,18},title="Reason:"
	SetVariable reason,win=tep_modal,font="Courier New",fsize=12
	SetVariable reason,win=tep_modal,limits={0,0,0},noedit=1,frame=0
	SetVariable reason,win=tep_modal,value=reason
	String/G desc = error_stack[0][2]
	SetVariable desc,win=tep_modal,pos={42,51},size={686,18},title="Description:"
	SetVariable desc,win=tep_modal,font="Courier New",fsize=12
	SetVariable desc,win=tep_modal,limits={0,0,0},noedit=1,frame=0
	SetVariable desc,win=tep_modal,value=desc
	String/G init_err = error_stack[dimsize(error_stack,0)-1][2]
	SetVariable initial,win=tep_modal,pos={28,72},size={701,18},title="Initial Error:"
	SetVariable initial,win=tep_modal,font="Courier New",fsize=12
	SetVariable initial,win=tep_modal,limits={0,0,0},noedit=1,frame=0
	SetVariable initial,win=tep_modal,value=init_err
	String/G severity = error_stack[dimsize(error_stack,0)-1][0]
	SetVariable severity,win=tep_modal,pos={63,93},size={666,18},title="Severity:"
	SetVariable severity,win=tep_modal,font="Courier New",fsize=12
	SetVariable severity,win=tep_modal,limits={0,0,0},noedit=1,frame=0
	SetVariable severity,win=tep_modal,value=severity
	String/G origin = error_stack[dimsize(error_stack,0)-1][3]
	SetVariable origin,win=tep_modal,pos={77,114},size={653,18},title="Origin:"
	SetVariable origin,win=tep_modal,font="Courier New",fsize=12
	SetVariable origin,win=tep_modal,limits={0,0,0},noedit=1,frame=0
	SetVariable origin,win=tep_modal,value=origin
	String bt = "Close"
	Button close_but_1,win=tep_modal,pos={673,156},size={60,22}
	Button close_but_1,win=tep_modal,proc=tep_close_but_proc,title=bt
	ctrl_enable = (show_err_stack) ? 1 : 0
	Button close_but_1,win=tep_modal,disable=ctrl_enable
	Button close_but_2,win=tep_modal,pos={338,371},size={60,22}, disable=1
	Button close_but_2,win=tep_modal,proc=tep_close_but_proc,title=bt
	ctrl_enable = (show_err_stack) ? 0 : 1
	Button close_but_2,win=tep_modal,disable=ctrl_enable
	Button err_stack_but,win=tep_modal,pos={17,156},size={120,22}
	Button err_stack_but,win=tep_modal,proc=tep_error_stack_but_proc
	Button err_stack_but,win=tep_modal,title="Show Error Stack"
	ctrl_enable = (show_err_stack) ? 1 : 0
	Button err_stack_but,win=tep_modal,disable=ctrl_enable
	SetDataFolder ldf
	return kNO_ERROR
end
//==============================================================================
function tep_close_but_proc (ctrlName)
	String ctrlName
	DoWindow/K tep_modal
end
//==============================================================================
function tep_error_stack_but_proc (ctrlName)
	String ctrlName
	tep_open(1)
end
//==============================================================================
// fonction : tango_print_error
//==============================================================================
function tango_print_error ([print_full_stack])
	Variable print_full_stack
	if (ParamIsDefault(print_full_stack))
		print_full_stack = 0
	endif
	tango_get_error_stack()
	WAVE/T error_stack = root:tango:common:error_stack
	if (WaveExists(error_stack) && dimsize(error_stack, 0))
		if (print_full_stack)
			Variable i
			print "\t\t'------------------------------------------------------"
			for (i = 0; i < dimsize(error_stack, 0); i += 1)
				print "\tTANGO ERROR STACK:LEVEL[" + num2str(i) + "]:"
				print "\t\t'-> SEVERITY........" + error_stack[dimsize(error_stack,0)-1][0]
				print "\t\t'-> REASON.........." + error_stack[i][1]
				print "\t\t'-> DESC............" + error_stack[i][2]
				print "\t\t'-> INITIAL ERROR..." + error_stack[dimsize(error_stack,0)-1][2]
				print "\t\t'-> ORIGIN.........." + error_stack[dimsize(error_stack,0)-1][3]
				print "\t\t'------------------------------------------------------"
				print "\t\t'-> LOCATION........" + GetRTStackInfo(2)
				print "\t\t'-> CALL STACK......" + GetRTStackInfo(3)
				print "\t\t'------------------------------------------------------"
			endfor
		else
			print "\t'-----------------------------------------------------------"
			print "\t'-> TIMESTAMP...." + Date() + " - " + Time()
			print "\t'-> REASON......." + error_stack[dimsize(error_stack,0)-1][1]
			print "\t'-> DESC........." + error_stack[dimsize(error_stack,0)-1][2]
			print "\t'-> ORIGIN......." + error_stack[dimsize(error_stack,0)-1][3]
			print "\t'-----------------------------------------------------------"
			print "\t'-> CALL STACK..."
			Variable t = 0
			String cur_token = "", call_stack = ""
			String full_call_stack = GetRTStackInfo(3)  
			do
				cur_token = StringFromList(t, full_call_stack, ";")
				if (strsearch(cur_token, "tango_print_error", 0) != -1)
					break
				endif
				print "\t'\t\t'-> " + cur_token 
				t += 1
			while (1)
			print "\t'-----------------------------------------------------------"
		endif
	endif
end
//==============================================================================
// fonction : tango_get_error_str
//==============================================================================
function/S tango_get_error_str ( )
	tango_get_error_stack()
	WAVE/T/Z error_stack = root:tango:common:error_stack
	if (WaveExists(error_stack) != 0 && numpnts(error_stack) != 0)
		WAVE/T error_stack = root:tango:common:error_stack
		SetDimLabel 1, 0, Severity, error_stack
		SetDimLabel 1, 1, Reason, error_stack
		SetDimLabel 1, 2, Description, error_stack
		SetDimLabel 1, 3, Origin, error_stack
		return error_stack[dimsize(error_stack,1)][%Description]
	endif
	return ""
end		
//==============================================================================
// fonction : tango_display_error_str
//==============================================================================
function tango_display_error_str (err_str)
	String err_str
	DoAlert 0, err_str
end
//==============================================================================
// fonction : tango_device_to_df_name
//==============================================================================
function/S tango_device_to_df_name (device_name)
	String device_name
	Variable cpos = 0
	Variable lpos = 0
	device_name[0] = "'"
	do 
		cpos = strsearch(device_name, "/", lpos)
		if (cpos == kERROR) 
			break
		endif
		device_name[cpos] = "'"
		cpos += 1
		device_name[cpos, cpos] = ":"
		cpos += 1
		device_name[cpos] = "'"
		lpos = cpos + 1
	while (1)
	cpos = strlen(device_name)
	device_name[cpos, cpos] = "'"
	return "root:tango:devices:" + device_name
end
//==============================================================================
// fonction : tango_enter_device_df 
//==============================================================================
function tango_enter_device_df (device_name, [prev_df])
	String device_name
	String &prev_df
	String device_df = tango_device_to_df_name(device_name)
	String cur_df = GetDataFolder(1)
	if (! ParamIsDefault(prev_df))
		prev_df = cur_df
	endif
	if (! cmpstr(device_df, cur_df))
		return kNO_ERROR
	endif 
	if (! DataFolderExists(device_df))
		if (tango_open_device(device_name) == kERROR)
			return kERROR
		endif
	endif
	SetDataFolder $device_df
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_enter_df
//==============================================================================
function tango_enter_df (df, [prev_df])
	String df
	String &prev_df
	String cur_df = GetDataFolder(1)
	if (! ParamIsDefault(prev_df))
		prev_df = cur_df
	endif
	if (tools_df_make(df, 1) == kERROR)
		String txt = "TANGO API ERROR in function 'tango_enter_df'\n"
		txt += "Could not create datafolder: " + df
		print txt
		return kERROR
	endif
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_enter_attrs_df 
//==============================================================================
function tango_enter_attrs_df  (dev, [prev_df])
	String dev
	String &prev_df
	String local_prev_df
	if (tango_enter_device_df(dev, prev_df = local_prev_df) == kERROR)
		return kERROR
	endif
	if (! ParamIsDefault(prev_df))
		prev_df = local_prev_df
	endif
	String attrs_df = GetDataFolder(1) + "attributes"
	if (! DataFolderExists(attrs_df))
		if (tango_open_device(dev) == kERROR)
			return kERROR
		endif
	endif
	SetDataFolder $attrs_df
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_enter_attr_df 
//==============================================================================
function tango_enter_attr_df  (dev, attr, [prev_df])
	String dev
	String attr
	String &prev_df
	String local_prev_df
	if (tango_enter_device_df(dev, prev_df = local_prev_df) == kERROR)
		return kERROR
	endif
	if (! ParamIsDefault(prev_df))
		prev_df = local_prev_df
	endif
	String cur_df = GetDataFolder(1)
	String target_attr_df = cur_df + "attributes:" + attr
	if (! DataFolderExists(target_attr_df))
		if (tango_get_attr_df_by_name(dev, attr, target_attr_df) == kERROR)
			String txt = "FATAL ERROR in function 'tango_enter_attr_df'\n"
			txt += "Could not find the attribut datafolder. Aborting procedure..."
			print txt
			return kERROR
		endif
	endif
	SetDataFolder $target_attr_df
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_enter_cmds_df 
//==============================================================================
function tango_enter_cmds_df (dev, [prev_df])
	String dev
	String &prev_df
	String local_prev_df
	if (tango_enter_device_df(dev, prev_df = local_prev_df) == kERROR)
		return kERROR
	endif
	if (! ParamIsDefault(prev_df))
		prev_df = local_prev_df
	endif
	String cur_df = GetDataFolder(1)
	String cmds_df = cur_df + "commands"
	if (! DataFolderExists(cmds_df))
		if (tango_open_device(dev) == kERROR)
			return kERROR
		endif
	endif
	SetDataFolder $cmds_df
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_enter_cmd_df 
//==============================================================================
function tango_enter_cmd_df (dev, cmd, [prev_df])
	String dev
	String cmd
	String &prev_df
	String local_prev_df
	if (tango_enter_device_df(dev, prev_df = local_prev_df) == kERROR)
		return kERROR
	endif
	if (! ParamIsDefault(prev_df))
		prev_df = local_prev_df
	endif
	String cur_df = GetDataFolder(1)
	String target_cmd_df = cur_df + ":commands:" + cmd
	if (! DataFolderExists(target_cmd_df))
		if (tango_get_cmd_df_by_name(dev, cmd, target_cmd_df) == kERROR)
			String txt = "FATAL ERROR in function 'tango_enter_cmd_df'\n"
			txt += "'" + cmd + "' doesn't seem to be valid command of '" + dev
			print txt
			return kERROR
		endif
	endif
	SetDataFolder $target_cmd_df
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_enter_tmp_df
//==============================================================================
function tango_enter_tmp_df (dev, [prev_df])
	String dev
	String &prev_df
	String local_prev_df
	if (tango_enter_device_df(dev, prev_df = local_prev_df) == kERROR)
		return kERROR
	endif
	if (! ParamIsDefault(prev_df))
		prev_df = local_prev_df
	endif
	String tmp_df = GetDataFolder(1) + "tmp"
	if (DataFolderExists(tmp_df) == 0)
		NewDataFolder/O/S $tmp_df
	else
		SetDataFolder $tmp_df
	endif
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_leave_df 
//==============================================================================
function tango_leave_df (last_df)
	String last_df
	if (DataFolderExists(last_df))
		SetDataFolder last_df
	endif
end
//==============================================================================
// fonction : tango_leave_tmp_df 
//==============================================================================
static function tango_leave_tmp_df  (last_df)
	String last_df
	KillVariables /A /Z
	KillStrings /A /Z 
	if (DataFolderExists(last_df))
		SetDataFolder last_df
	endif
end
//==============================================================================
// fonction : tango_get_attr_format
//==============================================================================
function tango_get_attr_format (dev, attr)
	String dev
	String attr
	String ldf
	if (tango_enter_attr_df(dev, attr, prev_df = ldf) == kERROR)
   		return kERROR
	endif
	NVAR/Z v = :format
	if (NVAR_Exists(v))
		tango_leave_df(ldf)
		return v	
	endif
	Variable format = NumVarOrDefault(":format", -1)
	tango_leave_df(ldf)
	return kERROR
end
//==============================================================================
// fonction : tango_get_attr_format_str
//==============================================================================
function/S tango_get_attr_format_str (format)
	Variable format
	switch (format)
		case kSCALAR:
			return "SCALAR"
			break
		case kSPECTRUM:
			return "SPECTRUM"
			break
		case kIMAGE:
			return "IMAGE"
			break
	endswitch
	return "UNKNOWN"
end
//==============================================================================
// fonction : tango_dev_attr_exists 
//==============================================================================
function tango_dev_attr_exists (dev, attr)
	String dev
	String attr
	String dev_df = tango_device_to_df_name(dev)
	if (DataFolderExists(dev_df) == 0)
		if (tango_open_device(dev) == kERROR)
			tango_print_error()
			return 0
		endif
	endif
	Wave/T alist = $(dev_df + ":attributes:alist")
	if (!WaveExists(alist))
		return 0
	endif
	Variable i = 0
	Variable n = DimSize(alist, 0)
	for (; i< n; i += 1)
		if (cmpstr(alist[i][0], attr) == 0)
			return 1
		endif
	endfor
	return 0
end
//==============================================================================
// fonction : tango_get_device_class
//==============================================================================
function/S tango_get_device_class (dev)
	String dev
	String ldf 
	if (tango_enter_device_df(dev, prev_df=ldf) != kERROR)
		SVAR/Z v = :info:class
		if (SVAR_Exists(v))
			tango_leave_df(ldf)
			return v	
		endif
	endif
	String class = StrVarOrDefault(":info:class", "unknown")
	tango_leave_df(ldf)
	return class
end
//==============================================================================
// fonction : tango_get_attr_access
//==============================================================================
function tango_get_attr_access (dev, attr)
	String dev
	String attr
	String ldf 
	if (tango_enter_attr_df(dev, attr, prev_df=ldf) == kERROR)
		return kERROR 
	endif
	NVAR/Z v = :access
	if (NVAR_Exists(v))
		tango_leave_df(ldf)
		return v	
	endif
	tango_leave_df(ldf)
	return kERROR
end
//==============================================================================
// fonction : tango_get_attr_access_str
//==============================================================================
function/S tango_get_attr_access_str (access)
	Variable access
	switch (access)
		case kREAD:
			return "READ"
			break
		case kREAD_WITH_WRITE:
			return "READ-WITH-WRITE"
			break
		case kWRITE:
			return "WRITE"
			break
		case kREAD_WRITE:
			return "READ-WRITE"
			break
	endswitch
	return "UNKNOWN"
end
//==============================================================================
// fonction : tango_get_attr_quality_str
//==============================================================================
function/S tango_get_attr_quality_str (quality)
	Variable quality
	switch (quality)
		case kAttrQualityVALID:
			return "VALID"
			break
		case kAttrQualityINVALID:
			return "INVALID"
			break
		case kAttrQualityALARM:
			return "ALARM"
			break
		case kAttrQualityCHANGING:
			return "CHANGING"
			break
		case kAttrQualityWARNING:
			return "WARNING"
			break
	endswitch
	return "UNKNOWN"
end
//==============================================================================
// fonction : tango_get_attr_type
//==============================================================================
function tango_get_attr_type (dev, attr)
	String dev
	String attr
	String ldf
	if (tango_enter_attr_df(dev, attr, prev_df=ldf) == kERROR)
		return kERROR 
	endif
	NVAR/Z v = :type
	if (NVAR_Exists(v))
		tango_leave_df(ldf)
		return v	
	endif
	tango_leave_df(ldf)
	return kERROR
end
//==============================================================================
// fonction : tango_get_attr_type_str
//==============================================================================
function/S tango_get_attr_type_str (format, type)
	Variable format
	Variable type
	switch (type)
		case kSTRING:
			switch (format)
				case kSCALAR:
					return "string scalar [Igor String]"
					break
				case kSPECTRUM:
					return "string spectrum [Igor 1D Wave/T]"
					break
				case kIMAGE:
					return "string image [Igor 2D Wave/T]"
					break
			endswitch
			break
		case kCHAR:
		case kBOOL:
			switch (format)
				case kSCALAR:
					return "char or boolean scalar (8-bits integer) [Igor Variable]"
					break
				case kSPECTRUM:
					return "char or boolean spectrum (8-bits integers) [Igor 1D Wave/B]"
					break
				case kIMAGE:
					return "char or boolean image (8-bits integers) [Igor 2D Wave/B]"
					break
			endswitch
			break
		case kUCHAR:
			switch (format)
				case kSCALAR:
					return "unsigned char scalar (8-bits integer) [Igor Variable]"
					break
				case kSPECTRUM:
					return "unsigned char spectrum (8-bits integers) [Igor 1D Wave/U/B]"
					break
				case kIMAGE:
					return "unsigned char image (8-bits integers) [Igor 2D Wave/U/B]"
					break
			endswitch
			break
		case kSHORT:
			switch (format)
				case kSCALAR:
					return "short scalar (16-bits integer) [Igor Variable]"
					break
				case kSPECTRUM:
					return "short spectrum (16-bits integers) [Igor 1D Wave/W]"
					break
				case kIMAGE:
					return "short image (16-bits integers) [Igor 2D Wave/W]"
					break
			endswitch
			break
		case kUSHORT:
			switch (format)
				case kSCALAR:
					return "unsigned short scalar (16-bits integer) [Igor Variable]"
					break
				case kSPECTRUM:
					return "unsigned short spectrum (16-bits integers) [Igor 1D Wave/U/W]"
					break
				case kIMAGE:
					return "unsigned short image (16-bits integers) [Igor 2D Wave/U/W]"
					break
			endswitch
			break
		case kLONG:
			switch (format)
				case kSCALAR:
					return "long scalar (32-bits integer) [Igor Variable]"
					break
				case kSPECTRUM:
					return "long spectrum (32-bits integers) [Igor 1D Wave/I]"
					break
				case kIMAGE:
					return "long image (32-bits integers) [Igor 2D Wave/I]"
					break
			endswitch
			break
		case kULONG:
			switch (format)
				case kSCALAR:
					return "unsigned long scalar (32-bits integer) [Igor Variable]"
					break
				case kSPECTRUM:
					return "unsigned long spectrum (32-bits integers) [Igor 1D Wave/U/I]"
					break
				case kIMAGE:
					return "unsigned long image (32-bits integers) [Igor 2D Wave/U/I]"
					break
			endswitch
			break
		case kLONG64:
			switch (format)
				case kSCALAR:
					return "long64 scalar (64-bits integer) [unsupported Tango data type]"
					break
				case kSPECTRUM:
					return "long64 spectrum (64-bits integer) [unsupported Tango data type]"
					break
				case kIMAGE:
					return "long64 image (64-bits integer) [unsupported Tango data type]"
					break
			endswitch
			break
		case kULONG64:
			switch (format)
				case kSCALAR:
					return "unsigned long64 scalar (64-bits integer) [unsupported Tango data type]"
					break
				case kSPECTRUM:
					return "unsigned long64 spectrum (64-bits integer) [unsupported Tango data type]"
					break
				case kIMAGE:
					return "unsigned long64 image (64-bits integer) [unsupported Tango data type]"
					break
			endswitch
			break
		case kFLOAT:
			switch (format)
				case kSCALAR:
					return "float scalar (32-bits float) [Igor Variable]"
					break
				case kSPECTRUM:
					return "float spectrum (32-bits floats) [Igor 1D Wave]"
					break
				case kIMAGE:
					return "float image (32-bits floats) [Igor 2D Wave]"
					break
			endswitch
			break
		case kDOUBLE:
			switch (format)
				case kSCALAR:
					return "double scalar (64-bits float) [Igor Variable]"
					break
				case kSPECTRUM:
					return "double spectrum (64-bits floats) [Igor 1D Wave/D]"
					break
				case kIMAGE:
					return "double image (64-bits floats) [Igor 2D Wave/D]"
					break
			endswitch
			break
	endswitch
	return "UNKNOWN/UNSUPPORTED TANGO DATA TYPE"
end
//==============================================================================
// fonction : tango_get_attr_df_by_name
//==============================================================================
function tango_get_attr_df_by_name (dev, attr, attr_df)
	String dev
	String attr
	String &attr_df
	String ldf
	attr_df = ""
	if (tango_enter_attrs_df(dev, prev_df=ldf) == kERROR)
		return kERROR
	endif
	Variable index = 0
	String tmp_attr_df
	String dev_attrs_df = GetDataFolder(1)
	do
		tmp_attr_df = GetIndexedObjName(dev_attrs_df, 4, index)
		if (strlen(tmp_attr_df) == 0)
			break
		endif
		String str_name_path =  dev_attrs_df + tmp_attr_df + ":name"
		SVAR/Z attr_name = $str_name_path
		if (SVAR_Exists(attr_name) == 0)
			tango_leave_df(ldf)
			return kERROR
		endif
		if (cmpstr(attr_name, attr) == 0)
			tango_leave_df(ldf)
			attr_df = dev_attrs_df + tmp_attr_df
			break
		endif
		index += 1
	while(1)
	tango_leave_df(ldf)
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_get_attr_desc
//==============================================================================
function/S tango_get_attr_desc (dev, attr)
	String dev
	String attr
	String ldf 
	if (tango_enter_attrs_df(dev, prev_df=ldf) == kERROR)
		return "error while getting attr. desc."
	endif
	WAVE/T alist = alist
	String attr_desc = ""
	Variable i = 0
	Variable nrows = DimSize(alist, 0)
	do
		if (cmpstr(alist[i][0], attr) == 0)
			attr_desc = alist[i][kATTR_DESC_COL]
			break
		endif 
		i += 1
	while (i < nrows)
	tango_leave_df(ldf)
	return attr_desc
end
//==============================================================================
// fonction : tango_get_attr_label
//==============================================================================
function/S tango_get_attr_label (dev, attr)
	String dev
	String attr
	String ldf
	if (tango_enter_attrs_df(dev, prev_df=ldf) == kERROR)
		return "error while getting attr. label"
	endif
	WAVE/T alist = alist
	String attr_label = ""
	Variable i = 0
	Variable nrows = DimSize(alist, 0)
	do
		if (cmpstr(alist[i][0], attr) == 0)
			attr_label = alist[i][kATTR_LABEL_COL]
			break
		endif 
		i += 1
	while (i < nrows)
	tango_leave_df(ldf)
	if (! strlen(attr_label))
		return attr
	endif
	return attr_label
end
//==============================================================================
// fonction : tango_get_attr_unit
//==============================================================================
function/S tango_get_attr_unit (dev, attr)
	String dev
	String attr
	String ldf
	if (tango_enter_attrs_df(dev, prev_df=ldf) == kERROR)
		return "error while getting attr. unit"
	endif
	WAVE/T alist = alist
	String attr_unit = ""
	Variable i = 0
	Variable nrows = DimSize(alist, 0)
	do
		if (cmpstr(alist[i][0], attr) == 0)
			attr_unit = alist[i][kATTR_UNIT_COL]
			break
		endif 
		i += 1
	while (i < nrows)
	tango_leave_df(ldf)
	if (! cmpstr(attr_unit, "No unit"))
		attr_unit = ""
	endif
	return attr_unit
end
//==============================================================================
// fonction : tango_get_attr_std_unit
//==============================================================================
function/S tango_get_attr_std_unit (dev, attr)
	String dev
	String attr
	String ldf
	if (tango_enter_attrs_df(dev, prev_df=ldf) == kERROR)
		return "error while getting attr. std. unit"
	endif
	WAVE/T alist = alist
	String attr_std_unit = ""
	Variable i = 0
	Variable nrows = DimSize(alist, 0)
	do
		if (cmpstr(alist[i][0], attr) == 0)
			attr_std_unit = alist[i][kATTR_STD_UNIT_COL]
			break
		endif 
		i += 1
	while (i < nrows)
	tango_leave_df(ldf)
	if (! cmpstr(attr_std_unit, "No standard unit"))
		attr_std_unit = ""
	endif
	return attr_std_unit
end
//==============================================================================
// fonction : tango_get_attr_display_unit
//==============================================================================
function/S tango_get_attr_display_unit (dev, attr)
	String dev
	String attr
	String ldf
	if (tango_enter_attrs_df(dev, prev_df=ldf) == kERROR)
		return "error while getting attr. disp. unit"
	endif
	WAVE/T alist = alist
	String attr_disp_unit = ""
	Variable i = 0
	Variable nrows = DimSize(alist, 0)
	do
		if (cmpstr(alist[i][0], attr) == 0)
			attr_disp_unit = alist[i][kATTR_STD_UNIT_COL]
			break
		endif 
		i += 1
	while (i < nrows)
	tango_leave_df(ldf)
	if (! cmpstr(attr_disp_unit, "No display unit"))
		attr_disp_unit = ""
	endif
	return attr_disp_unit
end
//==============================================================================
// fonction : tango_get_attr_display_format
//==============================================================================
function/S tango_get_attr_display_format (dev, attr)
	String dev
	String attr
	String ldf
	if (tango_enter_attrs_df(dev, prev_df=ldf) == kERROR)
		return "error while getting attr. disp. format"
	endif
	WAVE/T alist = alist
	String attr_disp_format = ""
	Variable i = 0
	Variable nrows = DimSize(alist, 0)
	do
		if (cmpstr(alist[i][0], attr) == 0)
			attr_disp_format = alist[i][kATTR_DISP_UNIT_COL]
			break
		endif 
		i += 1
	while (i < nrows)
	tango_leave_df(ldf)
	if (! strlen(attr_disp_format))
		attr_disp_format = "%g"
	endif
	return attr_disp_format
end
//==============================================================================
// fonction : tango_get_wattr
//==============================================================================
function/S tango_get_wattr (dev, attr)
	String dev
	String attr
	String ldf
	if (tango_enter_attrs_df(dev, prev_df=ldf) == kERROR)
		return "error while getting attr. write attr."
	endif
	WAVE/T alist = alist
	String wattr = ""
	Variable i = 0
	Variable nrows = DimSize(alist, 0)
	do
		if (cmpstr(alist[i][0], attr) == 0)
			wattr = alist[i][kATTR_WATTR_COL]
			break
		endif 
		i += 1
	while (i < nrows)
	tango_leave_df(ldf)
	if (cmpstr(lowerstr(wattr),"none") == 0)
		wattr = ""
	endif
	return wattr
end
//==============================================================================
// fonction : tango_get_cmd_argin_type
//==============================================================================
function tango_get_cmd_argin_type (dev, cmd)
	String dev
	String cmd
	String ldf
	if (tango_enter_cmd_df(dev, cmd, prev_df=ldf) == kERROR)
		return kERROR
	endif
	NVAR/Z v = :argin_type
	if (NVAR_Exists(v))
		tango_leave_df(ldf)
		return v	
	endif
	Variable type = NumVarOrDefault(":argin_type", -1)
	tango_leave_df(ldf)
	return type
end
//==============================================================================
// fonction : tango_get_cmd_argout_type
//==============================================================================
function tango_get_cmd_argout_type (dev, cmd)
	String dev
	String cmd
	String ldf
	if (tango_enter_cmd_df(dev, cmd, prev_df=ldf) == kERROR)
		return kERROR
	endif
	NVAR/Z v = :argout_type
	if (NVAR_Exists(v))
		tango_leave_df(ldf)
		return v	
	endif
	Variable type = NumVarOrDefault(":argout_type", -1)
	tango_leave_df(ldf)
	return type
end
//==============================================================================
// fonction : tango_get_cmd_argio_type_str
//==============================================================================
function/S tango_get_cmd_argio_type_str (type)
	Variable type
	switch (type)
		case kDEVVOID:
			return "None"
			break
		case kDEVBOOLEAN:
			return "Boolean (8-bit integer) [Igor Variable]"
			break
		case kDEVUCHAR:
			return "Unsigned Char (8-bit integer) [Igor Variable]"
			break
		case kDEVUSHORT:
			return "Unsigned Short (16-bit integer) [Igor Variable]"
			break
		case kDEVSHORT:
			return "Short (16-bit integer) [Igor Variable]"
			break
		case kDEVULONG:
			return "Unsigned Long (32-bit integer) [Igor Variable]"
			break
		case kDEVLONG:
			return "Long (32-bit integer) [Igor Variable]"
			break
		case kDEVFLOAT:
			return "Float (32-bit float) [Igor Variable]"
			break
		case kDEVDOUBLE:
			return "Double (64-bit float) [Igor Variable]"
			break
		case kDEVSTRING:
			return "String [Igor String]"
			break
		case kDEVVARBOOLEANARRAY:
			return "Boolean Array (8-bit integer) [Igor 1D Wave/B]"
			break
		case kDEVVARCHARARRAY:
			return "Char Array (8-bits integers) [Igor 1D Wave/B]"
			break
		case kDEVVARUSHORTARRAY:
			return "Unsigned Short Array (16-bits integers) [Igor 1D Wave/U/W]"
			break
		case kDEVVARSHORTARRAY:
			return "Short Array (16-bits integers) [Igor 1D Wave/W]"
			break
		case kDEVVARULONGARRAY:
			return "Unsigned Long Array (32-bits integers) [Igor 1D Wave/U/I]"
			break
		case kDEVVARLONGARRAY:
			return "Long Array (32-bits integers) [Igor 1D Wave/I]"
			break
		case kDEVVARFLOATARRAY:
			return "Float Array (32-bits floats) [Igor 1D Wave]"
			break
		case kDEVVARDOUBLEARRAY:
			return "Double Array (64-bits floats) [Igor 1D Wave/D]"
			break
		case kDEVVARSTRINGARRAY:
			return "String Array [Igor 1D Wave/T]"
			break
		case kDEVVARLONGSTRINGARRAY:
			return "Long Array & String Array [Igor 1D Wave/I & 1D Wave/T]"
			break
		case kDEVVARDOUBLESTRINGARRAY:
			return "Double Array & String Array [Igor 1D Wave/D & 1D Wave/T]"
			break
		case kDEVSTATE:
			return "Device State [Igor Variable]"
			break
		case kCONSTDEVSTRING:
			return "String [Igor String]"
			break
	endswitch
	return "UNKNOWN"
end
//==============================================================================
// fonction : tango_get_cmd_df_by_name
//==============================================================================
function tango_get_cmd_df_by_name (dev, cmd, cmd_df)
	String dev
	String cmd
	String &cmd_df
	cmd_df = ""
	String ldf
	if (tango_enter_cmds_df(dev, prev_df=ldf) == kERROR)
		return kERROR
	endif
	Variable index = 0
	String dev_cmds_df = GetDataFolder(1)
	do
		cmd_df = GetIndexedObjName(dev_cmds_df, 4, index)
		if (strlen(cmd_df) == 0)
			break
		endif
		String str_name_path =  dev_cmds_df + cmd_df + ":name"
		SVAR/Z cmd_name = $str_name_path
		if (SVAR_Exists(cmd_name) == 0)
			return kERROR
		endif
		if (cmpstr(cmd_name, cmd) == 0)
			cmd_df = dev_cmds_df + cmd_df
			return kNO_ERROR
		endif
		index += 1
	while(1)
	tango_leave_df(ldf)
	return kERROR
end
//==============================================================================
// fonction : tango_get_cmd_argin_desc
//==============================================================================
function/S tango_get_cmd_argin_desc (dev, cmd)
	String dev
	String cmd
	String ldf
	tango_enter_cmds_df(dev, prev_df=ldf)
	WAVE/T clist = clist
	String desc = ""
	Variable i = 0
	Variable nrows = DimSize(clist, 0)
	do
		if (cmpstr(clist[i][0], cmd) == 0)
			desc = clist[i][2]
			break
		endif 
		i += 1
	while (i < nrows)
	tango_leave_df(ldf)
	return desc
end
//==============================================================================
// fonction : tango_get_cmd_argout_desc
//==============================================================================
function/S tango_get_cmd_argout_desc (dev, cmd)
	String dev
	String cmd
	String ldf
	tango_enter_cmds_df(dev, prev_df=ldf)
	WAVE/T clist = clist
	String desc = ""
	Variable i = 0
	Variable nrows = DimSize(clist, 0)
	do
		if (cmpstr(clist[i][0], cmd) == 0)
			desc = clist[i][2]
			break
		endif 
		i += 1
	while (i < nrows)
	tango_leave_df(ldf)
	return desc
end
//==============================================================================
// fonction : tango_argin_type_to_wave_type
//==============================================================================
function tango_argin_type_to_wave_type (dev, cmd)
	String dev
	String cmd
	Variable arg_type = tango_get_cmd_argin_type (dev, cmd)
	if (arg_type == kERROR)
		return kERROR
	endif
	Variable igor_type
	switch (arg_type)
		case kDEVVOID:
			return kERROR
			break
		case kDEVUCHAR:
		case kDEVBOOLEAN:
		case kDEVVARCHARARRAY:
		case kDEVVARBOOLEANARRAY:
			return kUCHAR
			break
		case kDEVSHORT:  
		case kDEVVARSHORTARRAY:
			return kSHORT
			break
		case kDEVFLOAT:
		case kDEVVARFLOATARRAY:
			return kFLOAT
			break
		case kDEVUSHORT:
		case kDEVVARUSHORTARRAY:
			return kUSHORT
			break
		case kDEVULONG: 
		case kDEVVARULONGARRAY:
			return kULONG
			break
		case kDEVSTRING:
		case kDEVVARSTRINGARRAY:
			return kSTRING
			break
		case kDEVLONG:
		case kDEVVARLONGARRAY:
		case kDEVVARLONGSTRINGARRAY:
			return kLONG
			break
		case kDEVDOUBLE:
		case kDEVVARDOUBLEARRAY:
		case kDEVVARDOUBLESTRINGARRAY:
			return kDOUBLE
			break
		default:
			String txt = "TANGO API ERROR in function 'tango_argin_type_to_wave_type'\n"
			txt += "Unexpected/supported data type for argout."
			print txt
			break
	endswitch  
	return kERROR
end
//==============================================================================
// fonction : tango_attr_val_list_add
//==============================================================================
function/S tango_attr_val_list_add (list, attr, val)
	String list
	String attr
	String val
	String tstmp
	String str_to_add = attr + kNAME_SEP + val + ";"
	Variable found = strsearch(list, str_to_add, 0)
	if (found != -1) 
		return list
	endif
	list += str_to_add
	return list
end
//==============================================================================
// fonction : tango_attr_val_list_remove
//==============================================================================
function/S tango_attr_val_list_remove (list, attr)
	String list
	String attr
	String str_to_remove = attr + kNAME_SEP
	if (strsearch(list, ";", 0) == kERROR)
		return list	
	endif
	Variable pos = 0, sep_pos = 0, start = 0, sep_start = 0
	do
		sep_pos = strsearch(list, ";", sep_start)
		pos = strsearch(list, attr + kNAME_SEP, start) 
		if (pos == kERROR)
			return list
		endif	
		if (pos == 0 || (pos - sep_pos == 1)) 
			start = pos
			break
		endif
		sep_start = start
		start = sep_pos + 1
	while (start < strlen(list))
	Variable stop = strsearch(list, ";", start)
	if (stop == kERROR)
		stop = strlen(list)
	endif
	String new_list = list[0, start - 1] + list[stop + 1, strlen(list) - 1]
	return new_list
end
//==============================================================================
// fonction : tango_attr_val_list_find
//==============================================================================
function tango_attr_val_list_find (list, attr)
	String list
	String attr
	Variable pos = 0, sep_pos = 0, start = 0
	do
		sep_pos = strsearch(list, ";", start)
		pos = strsearch(list, attr + kNAME_SEP, start) 
		if (pos == kERROR)
			return kNO_ERROR
		endif	
		if (pos == 0 || (pos - sep_pos == 1)) 
			return 1
		endif
		start = sep_pos + 1
	while (start < strlen(list))
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_get_attr_val_name
//==============================================================================
function/S tango_get_attr_val_name (list, attr)
	String list
	String attr
	String val
	Variable start = strsearch(list, attr + kNAME_SEP, 0)
	if (start == kERROR) 
		return ""
	endif
	start += strlen(attr + kNAME_SEP)
	Variable stop = strsearch(list, ";", start)
	if (stop == kERROR)
		stop = strlen(list)
	endif
	return list[start, stop - 1]
end
//==============================================================================
// fonction : tango_get_state_str
//==============================================================================
function/S tango_get_state_str (state)
	Variable state
	switch (state)
		case kDeviceStateON:
			return "ON"
			break
		case kDeviceStateOFF:
			return "OFF"
			break
		case kDeviceStateCLOSE:
			return "CLOSE"
			break
		case kDeviceStateOPEN:
			return "OPEN"
			break
		case kDeviceStateINSERT:
			return "INSERT"
			break
		case kDeviceStateEXTRACT:
			return "EXTRACT"
			break
		case kDeviceStateMOVING:
			return "MOVING"
			break
		case kDeviceStateSTANDBY:
			return "STANDBY"
			break
		case kDeviceStateFAULT:
			return "FAULT"
			break
		case kDeviceStateRUNNING:
			return "RUNNING"
			break
		case kDeviceStateINIT:
			return "INIT"
			break
		case kDeviceStateALARM:
			return "ALARM"
			break
	endswitch
	return "UNKNOWN"
end
//==============================================================================
// fonction : tango_get_state_color
//==============================================================================
function tango_get_state_color (state, r, g, b)
	Variable state, &r, &g, &b
	if (!WAVEExists(root:tango:common:state_color) && tango_make_state_color_wave() == kERROR)
		return kERROR
	endif
	WAVE/Z state_color = root:tango:common:state_color
	if (state < kDeviceStateON || state > kDeviceStateUNKNOWN)
		state = kDeviceStateUNKNOWN
	endif
	r = state_color[state][0]
	g = state_color[state][1]
	b = state_color[state][2]
	return kNO_ERROR
end
//==============================================================================
// fonction : tango_get_attr_qlt_color
//==============================================================================
function tango_get_attr_qlt_color (qlt, r, g, b)
	Variable qlt, &r, &g, &b
	switch (qlt)
		case kAttrQualityUNKNOWN:
			r = 39168
			g = 39168
			b = 39168
			break
		case kAttrQualityCHANGING:
			r = 0
			g = 34816
			b = 52224
			break
		case kAttrQualityALARM:
		case kAttrQualityWARNING:
			r = 65280
			g = 43520
			b = 0
			break
		case kAttrQualityINVALID:
			r = 65280
			g = 0
			b = 0
			break
		default:
			r = 0
			g = 65280
			b = 0
			break
	endswitch
end
//==============================================================================
// fonction : tango_make_state_color_wave
//==============================================================================
function tango_make_state_color_wave()
	String cur_df = GetDataFolder(1)
	SetDataFolder root:tango:common
	Make/O/U/W/N=(kDeviceStateUNKNOWN + 1 , 3) state_color
	Variable conv_factor = 257
	//-------------------------------------------------
	state_color[kDeviceStateON][0] = 0
	state_color[kDeviceStateON][1] = 65535
	state_color[kDeviceStateON][2] = 0
	//-------------------------------------------------
	state_color[kDeviceStateOFF][0] = 65535
	state_color[kDeviceStateOFF][1] = 65535
	state_color[kDeviceStateOFF][2] = 65535
	//-------------------------------------------------
	state_color[kDeviceStateCLOSE][0] = 65535
	state_color[kDeviceStateCLOSE][1] = 65535
	state_color[kDeviceStateCLOSE][2] = 65535
	//-------------------------------------------------
	state_color[kDeviceStateOPEN][0] = 0
	state_color[kDeviceStateOPEN][1] = 65535
	state_color[kDeviceStateOPEN][2] = 0
	//-------------------------------------------------
	state_color[kDeviceStateINSERT][0] = 65535
	state_color[kDeviceStateINSERT][1] = 65535
	state_color[kDeviceStateINSERT][2] = 65535
	//-------------------------------------------------
	state_color[kDeviceStateEXTRACT][0] = 0
	state_color[kDeviceStateEXTRACT][1] = 65535
	state_color[kDeviceStateEXTRACT][2] = 0
	//-------------------------------------------------
	state_color[kDeviceStateMOVING][0] = 32768
	state_color[kDeviceStateMOVING][1] = 40704
	state_color[kDeviceStateMOVING][2] = 65280
	//-------------------------------------------------
	state_color[kDeviceStateSTANDBY][0] = 65535
	state_color[kDeviceStateSTANDBY][1] = 65535
	state_color[kDeviceStateSTANDBY][2] = 0
	//-------------------------------------------------
	state_color[kDeviceStateFAULT][0] = 65535
	state_color[kDeviceStateFAULT][1] = 50 * conv_factor
	state_color[kDeviceStateFAULT][2] = 50 * conv_factor
	//-------------------------------------------------
	state_color[kDeviceStateINIT][0] = 204 * conv_factor
	state_color[kDeviceStateINIT][1] = 204 * conv_factor
	state_color[kDeviceStateINIT][2] = 122 * conv_factor
	//-------------------------------------------------
	state_color[kDeviceStateRUNNING][0] = 32768
	state_color[kDeviceStateRUNNING][1] = 40704
	state_color[kDeviceStateRUNNING][2] = 65280
	//-------------------------------------------------
	state_color[kDeviceStateALARM][0] = 65535
	state_color[kDeviceStateALARM][1] = 150 * conv_factor
	state_color[kDeviceStateALARM][2] = 0
	//-------------------------------------------------
	state_color[kDeviceStateDISABLE][0] = 65535
	state_color[kDeviceStateDISABLE][1] = 0
	state_color[kDeviceStateDISABLE][2] = 65535
	//-------------------------------------------------
	state_color[kDeviceStateUNKNOWN][0] = 160 * conv_factor
	state_color[kDeviceStateUNKNOWN][1] = 160 * conv_factor
	state_color[kDeviceStateUNKNOWN][2] = 160 * conv_factor
	//-------------------------------------------------
	SetDataFolder(cur_df)
end
//==============================================================================
// function:  tango_dump_attribute_value
//==============================================================================
function tango_dump_attribute_value (av, [txt])
	Struct AttributeValue &av
	String txt
	if (ParamIsDefault(txt))
		print "Tango-Binding::AttributeValue"
	else
		print txt
	endif
	//- dump full attribute name
	print "\t '-> attr............" + av.dev + "/" + av.attr    
	//- dump attribute type and format...
	print "\t '-> attr type......." + tango_get_attr_type_str(av.format, av.type)
	//- dump attribute value timestamp...
	print "\t '-> timestamp......." + Secs2Date(av.ts,1) + " - " + Secs2Time(av.ts, 3, 2)
	//- dump attribute quality...
	print "\t '-> quality........." + tango_get_attr_quality_str(av.quality)
	//- dump actual value (this a numeric scalar attribute, its value is stored in av.var_val)
	String verbose_str = ""
	if (av.format == kSCALAR)
		if (av.type != kSTRING)
			verbose_str += num2str(av.var_val)
			if (cmpstr(av.attr, "State") == 0)
				verbose_str += " [" + tango_get_state_str(av.var_val) + "]"
			endif
		else
			verbose_str += "\"" + av.str_val + "\"" 
		endif
	else
		WAVE w = $av.val_path
		Variable np_x  = Dimsize(w, 0)
		Variable np_y  = Dimsize(w, 1)
		if (np_y == 0)
			np_y = 1
		endif
		print "\t '-> dims............" + "[" + num2str(np_x) + "x" + num2str(np_y) + "]" 
		if (av.format == kSPECTRUM)
			if (av.type != kSTRING)
				WAVE num_wave = $av.val_path
				verbose_str += "[" + num2str(num_wave[0]) + "," +  num2str(num_wave[1]) + "," +  num2str(num_wave[2]) + ",...]" 
			else
				WAVE/T txt_wave = $av.val_path
				verbose_str += "[" + txt_wave[0] + "," + txt_wave[1] + "," +  txt_wave[2] + ",...]" 
			endif
		else
			if (av.type != kSTRING)
				WAVE num_wave = $av.val_path
				verbose_str += "[0][" + num2str(num_wave[0][0]) + "," +  num2str(num_wave[0][1]) + "," +  num2str(num_wave[0][2]) + ",...]" 
			else
				WAVE/T txt_wave = $av.val_path
				verbose_str += "[0][" + txt_wave[0][0] + "," + txt_wave[0][1] + "," +  txt_wave[0][2] + ",...]" 
			endif
		endif
	endif
	print "\t '-> attr val........" + verbose_str + "\r"
	if (av.format == kSPECTRUM || av.format == kIMAGE)
		print "\t '-> attr val path..." + av.val_path + "\r"
	endif
end
//==============================================================================
// fonction : tango_monitor_start
//==============================================================================
function tango_monitor_start (dev, attr, path, pp)
	String dev
	String attr
	String path
	Variable pp
	return tango_start_attr_monitor(dev, attr, path, pp)
end
//==============================================================================
// fonction : tango_monitor_start_list
//==============================================================================
function tango_monitor_start_list (dev, attrs, path, pp, cids)
	String dev
	Wave/T attrs
	String path
	Variable pp
	Wave cids
	Variable np = numpnts(attrs)
	Variable nd = wavedims(attrs)
	Variable i
	Variable err = kNO_ERROR
	String full_path
	Redimension /N=(np) cids
	for (i = 0; i< np; i += 1)
		if (nd > 1)
			full_path = tools_path_build(path, attrs[i][1])
		else
			full_path = tools_path_build(path, attrs[i])
		endif
		cids[i] = tango_start_attr_monitor(dev, attrs[i], full_path, pp)	
		if (cids[i] == kERROR)
			err = kERROR
		endif
	endfor
	return err
end
//==============================================================================
// fonction : tango_monitor_stop
//==============================================================================
function tango_monitor_stop (dev, attr, [cid])
	String dev
	String attr
	Variable cid 
	if (ParamIsDefault(cid))
		cid = -1
	endif 
	return tango_stop_attr_monitor(dev, attr, cid)
end
//==============================================================================
// fonction : tango_monitor_stop_list
//==============================================================================
function tango_monitor_stop_list (dev, attrs, cids)
	String dev
	Wave/T attrs
	Wave cids
	Variable n = numpnts(attrs)
	Variable i = 0
	Variable err = kNO_ERROR
	Variable has_error = 0
	if (n != numpnts(cids))
		DoALert 0, "tango_monitor_stop_list error - waves must have the same length"
		return kERROR
	endif
	for (; i< n; i+= 1)
		if (tango_stop_attr_monitor(dev, attrs[i], cids[i]) == kERROR)
			has_error = 1
		endif
	endfor
	return has_error ? kERROR : kNO_ERROR
end
//==============================================================================
// fonction : tango_monitor_suspend
//==============================================================================
function tango_monitor_suspend (dev, attr, [cid])
	String dev
	String attr
	Variable cid 
	if (ParamIsDefault(cid))
		cid = -1
	endif 
	return tango_suspend_attr_monitor(dev, attr, cid)
end
//==============================================================================
// fonction : tango_monitor_resume
//==============================================================================
function tango_monitor_resume (dev, attr, [cid])
	String dev
	String attr
	Variable cid 
	if (ParamIsDefault(cid))
		cid = -1
	endif 
	return tango_resume_attr_monitor(dev, attr, cid)
end
//==============================================================================
// function:  tango_monitor_set_period
//==============================================================================
function tango_monitor_set_period (dev, attr, pp, [cid])
	String dev
	String attr
	Variable pp
	Variable cid 
	if (ParamIsDefault(cid))
		cid = -1
	endif 
	return tango_set_attr_monitor_period(dev, attr, pp, cid)
end
//==============================================================================
// function:  tango_db_get_dev_alias
//==============================================================================
function tango_db_get_dev_alias (dev, alias)
	String dev
	String& alias
	alias = "--"
	SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
	if (strlen(tango_host) == 0)
		tango_display_error_str("ERROR! SVAR root:tango:common:tango_host is not defined!")
		return kERROR
	endif
	Struct CmdArgIO cai
	tango_init_cmd_argio (cai)
	cai.str_val = dev
	Struct CmdArgIO cao
	tango_init_cmd_argio (cao)
	if (! tango_cmd_inout(tango_host, "DbGetDeviceAlias", arg_in = cai, arg_out = cao))
		alias = cao.str_val
	endif
	return kNO_ERROR
end
//==============================================================================
// function:  tango_db_set_dev_alias
//==============================================================================
function tango_db_set_dev_alias (dev, alias)
	String dev
	String alias
	SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
	if (strlen(tango_host) == 0)
		tango_display_error_str("ERROR! SVAR root:tango:common:tango_host is not defined!")
		return kERROR
	endif
	Make /O/T/N=(2) new_dev_alias = {dev, alias}
	Struct CmdArgIO cai
	tango_init_cmd_argio (cai)
	cai.str_wave_path = GetWavesDataFolder(new_dev_alias, 2)
	if (tango_cmd_inout(tango_host, "DbPutDeviceAlias", arg_in = cai) == kERROR)
		KillWaves/Z new_dev_alias
		tango_display_error()
		return kERROR
	endif
	KillWaves/Z new_dev_alias
	return kNO_ERROR
end
//==============================================================================
// function:  tango_db_get_alias_dev
//==============================================================================
function tango_db_get_alias_dev (alias, dev)
	String alias
	String& dev
	SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
	if (strlen(tango_host) == 0)
		tango_display_error_str("ERROR! SVAR root:tango:common:tango_host is not defined!")
		return kERROR
	endif
	Struct CmdArgIO cai
	tango_init_cmd_argio (cai)
	cai.str_val = alias
	Struct CmdArgIO cao
	tango_init_cmd_argio (cao)
	if (tango_cmd_inout(tango_host, "DbGetAliasDevice", arg_in = cai, arg_out = cao) == kERROR)
		tango_display_error()
		return kERROR
	endif
	dev = cao.str_val
	return kNO_ERROR
end
//==============================================================================
// function:  tango_db_get_dev_aliases
//==============================================================================
function tango_db_get_dev_aliases (dev_aliases)
	Wave& dev_aliases
	SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
	if (strlen(tango_host) == 0)
		tango_display_error_str("ERROR! SVAR root:tango:common:tango_host is not defined!")
		return kERROR
	endif
	Struct CmdArgIO cai
	tango_init_cmd_argio (cai)
	cai.str_val = "*"
	Struct CmdArgIO cao
	tango_init_cmd_argio (cao)
	cao.str_wave_path = GetWavesDataFolder(dev_aliases, 2)
	if (tango_cmd_inout(tango_host, "DbGetDeviceAliasList", arg_in = cai, arg_out = cao) == kERROR)
		tango_display_error()
		return kERROR
	endif
	return kNO_ERROR
end
//==============================================================================
// function:  tango_db_get_dev_class
//==============================================================================
function tango_db_get_dev_class (dev, class)
	String dev
	String& class
	SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
	if (strlen(tango_host) == 0)
		tango_display_error_str("ERROR! SVAR root:tango:common:tango_host is not defined!")
		return kERROR
	endif
	Struct CmdArgIO cai
	tango_init_cmd_argio (cai)
	cai.str_val = dev
	Struct CmdArgIO cao
	tango_init_cmd_argio (cao)
	if (tango_cmd_inout(tango_host, "DbGetClassForDevice", arg_in = cai, arg_out = cao) == kERROR)
		tango_display_error()
		return kERROR
	endif
	class = cao.str_val
	return kNO_ERROR
end
//==============================================================================
// function:  tango_dump_dev_status
//==============================================================================
function tango_dump_dev_status (dev)
	String dev
	Struct CmdArgIO ao
	tango_init_cmd_argio(ao)
	print "State & Status of " + dev
	if (tango_cmd_inout(dev, "State", arg_out = ao) == kERROR)
		print "\t'-> 'State' cmd failed with the following error..."
		tango_print_error(print_full_stack=0)
		return kError
	endif 
	print "\t'-> state...." + tango_get_state_str(ao.var_val)
	tango_init_cmd_argio(ao)
	if (tango_cmd_inout(dev, "Status", arg_out = ao) == kERROR)
		print "\t'-> 'Status' cmd failed with the following error..."
		tango_print_error(print_full_stack=0)
		return kError
	endif
	print "\t'-> status..." + ao.str_val
	return kNO_ERROR
end
//==============================================================================
// function:  tango_save_prefs
//==============================================================================
Function tango_save_prefs ([prefs])
	Struct TangoBindingPrefs& prefs
	if (ParamIsDefault(prefs))
		SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
		NVAR tmon_default_pp = $tango_get_global_obj("tmon_default_pp", kNVAR)
		Struct TangoBindingPrefs current_prefs
		current_prefs.version = 100
		current_prefs.tango_host = tango_host
		current_prefs.tmon_default_pp = tmon_default_pp
		SavePackagePreferences /FLSH=1 "TangoBinding", "TangoBinding", 0, current_prefs
	else
		SavePackagePreferences /FLSH=1 "TangoBinding", "TangoBinding", 0, prefs
	endif
	if (V_flag)
		print "Tango-Binding::preferences could not be saved!"
	else
		print "Tango-Binding::preferences successfully saved"
	endif
end
//==============================================================================
// function: tango_load_prefs
//==============================================================================
Function tango_load_prefs ()
	Struct TangoBindingPrefs prefs
	LoadPackagePreferences /MIS=1 "TangoBinding", "TangoBinding", 0, prefs
	if (! V_flag)
		print "Tango-Binding::preferences loaded"
	endif
	if (V_flag || V_bytesRead != V_structSize)
		print "Tango-Binding::preferences struct changed - applying default values"
   		print "Tango-Binding::preferences nbytes read: " + num2str(V_bytesRead)
		print "Tango-Binding::preferences struct size: " + num2str(V_structSize)
		prefs.version = 100
		prefs.tango_host = "sys/database/dbds1"
		prefs.tmon_default_pp = 0.5
		tango_save_prefs(prefs = prefs)
	endif
	print "Tango-Binding::preferences.version......" + num2str(prefs.version)
	print "Tango-Binding::preferences.tango-host..." + prefs.tango_host
	print "Tango-Binding::preferences.dft-mon-pp..." + num2str(prefs.tmon_default_pp) + " secs"
	SVAR tango_host = $tango_get_global_obj("tango_host", kSVAR)
	tango_host = prefs.tango_host
	NVAR tmon_default_pp = $tango_get_global_obj("tmon_default_pp", kNVAR)
	tmon_default_pp = prefs.tmon_default_pp
	print "Tango-Binding::preferences restored"
end
//==============================================================================
// function: tango_reload_device_interface
//==============================================================================
function tango_reload_device_interface (device_name)
	String device_name
	String cur_df = GetDataFolder(1)
	tmon_kill_dev_monitors(device_name)
	tango_close_device(device_name)
	tools_kill_df(tango_device_to_df_name(device_name))	
	tango_open_device(device_name)
	tango_enter_device_df (device_name)
	SetDataFolder cur_df
end