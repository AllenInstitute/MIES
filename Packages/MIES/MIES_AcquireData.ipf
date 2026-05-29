#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_ACD
#endif // AUTOMATED_TESTING

/// @file MIES_AcquireData.ipf
/// @brief __ACD__ Helpers for data acquisition used for testing and replay feature

static Function ACD_EnsureMCCIsOpen()

	AI_FindConnectedAmps()

	WAVE ampMCC = GetAmplifierMultiClamps()
	WAVE ampTel = GetAmplifierTelegraphServers()

	ASSERT(DimSize(ampMCC, ROWS) == 2, "Could not find exactly two connected amplifiers")
	ASSERT(DimSize(ampTel, ROWS) == 2, "Could not find exactly two connected amplifiers")
End

Function ACD_CALLABLE_PROTO(string device)

	FATAL_ERROR("Can not call prototype function")
End

static Function/S ACD_AcquireDataSelectFunction(string module, string funcName)

	string funcWithModule

	funcWithModule = module + "#" + funcName

	FUNCREF ACD_CALLABLE_PROTO func = $funcWithModule

	if(FuncRefIsAssigned(FuncRefInfo(func)))
		return funcWithModule
	endif

	return "ACD_AcquireDataDoNothing"
End

Function ACD_AcquireDataDoNothing(string device)

#ifdef AUTOMATED_TESTING
	PASS()
#endif // AUTOMATED_TESTING
End

/// @brief Open a DAEphys panel and lock it to the given device
///
/// In case unlockedDevice is given, no new panel is created.
Function ACD_CreateLockedDAEphys(string device, [string unlockedDevice])

	if(ParamIsDefault(unlockedDevice))
		unlockedDevice = DAP_CreateDAEphysPanel()
	endif

	PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str = device)
	PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")
	ASSERT(WindowExists(device), "Missing locked DAephys panel")
End

Function ACD_CreateLockedDatabrowser(string device)

	string win, bsPanel

	win     = DB_OpenDatabrowser()
	bsPanel = BSP_GetPanel(win)
	PGC_SetAndActivateControl(bsPanel, "popup_DB_lockedDevices", str = device)
End

static Function ACD_OpenDatabrowser()

	string win, bsPanel

	win     = DB_OpenDatabrowser()
	bsPanel = BSP_GetPanel(win)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = 1)
End

// assumes that the caller of the caller is an UTF test case
static Function ACD_FetchCustomizationFunctions(STRUCT ACD_DAQSettings &s)

	string funcName, stacktrace, module, testcaseInfo, preInitFunc, preAcquireFunc

	stacktrace   = GetRTStackInfo(3)
	testcaseInfo = StringFromList(ItemsInList(stacktrace, ";") - 3, stacktrace, ";")

	funcName = StringFromList(0, testcaseInfo, ",")
	ASSERT(!IsEmpty(funcName), "Could not get calling function's name.")

	module = StringByKey("MODULE", FunctionInfo(funcName, StringFromList(1, testcaseInfo, ",")))
	ASSERT(!IsEmpty(module), "Could not get calling function's module name.")

	FUNCREF ACD_CALLABLE_PROTO s.globalPreAcquireFunc = $ACD_AcquireDataSelectFunction(module, "GlobalPreAcq")
	FUNCREF ACD_CALLABLE_PROTO s.globalPreInitFunc    = $ACD_AcquireDataSelectFunction(module, "GlobalPreInit")

	FUNCREF ACD_CALLABLE_PROTO s.preAcquireFunc = $ACD_AcquireDataSelectFunction(module, funcName + "_PreAcq")
	FUNCREF ACD_CALLABLE_PROTO s.preInitFunc    = $ACD_AcquireDataSelectFunction(module, funcName + "_PreInit")
End

static Function ACD_ParseNumber(string str, string name, [variable defValue])

	string   output
	variable var

	SplitString/E=(name + "([[:digit:]]+(\.[[:digit:]]+)?)(?=_|$)") str, output

	if(V_Flag == 1)
		var = str2num(output)
		AssertOnAndClearRTError()
		return var
	endif

	if(ParamIsDefault(defValue))
		FATAL_ERROR("Missing defValue")
	endif

	return defValue
End

static Function/S ACD_ParseString(string str, string name, [string defValue])

	string output, trailingSep

	SplitString/E=(name + ":([^:]+)(:)(?=_|$)") str, output, trailingSep

	if(V_Flag == 1)
		FATAL_ERROR("Missing trailing colon: name=" + name + ", str=" + str)
	elseif(V_Flag == 2)
		return output
	endif

	if(ParamIsDefault(defValue))
		FATAL_ERROR("Missing defValue")
	endif

	return defValue
End

/// @brief Fill the #ACD_DAQSettings structure from a specially crafted string
Function ACD_InitDAQSettingsFromString(STRUCT ACD_DAQSettings &s, string str)

	variable md, ra, idx, lidx, bkg_daq, res, headstage, clampMode, ttl
	string elem, output

	sscanf str, "MD%d_RA%d_I%d_L%d_BKG%d", md, ra, idx, lidx, bkg_daq
	ASSERT(V_Flag >= 5, "Expected at least the five basic entries")

	s.md      = md
	s.ra      = ra
	s.idx     = idx
	s.lidx    = lidx
	s.bkg_daq = bkg_daq

	s.res = ACD_ParseNumber(str, "_RES", defValue = 0)

	s.db = ACD_ParseNumber(str, "_DB", defValue = 0)

	s.dDAQ = ACD_ParseNumber(str, "_dDAQ", defValue = 0)

	s.oodDAQ = ACD_ParseNumber(str, "_oodDAQ", defValue = 0)

	s.DDL = ACD_ParseNumber(str, "_DDL", defValue = 0)

	s.od = ACD_ParseNumber(str, "_OD", defValue = 0)

	s.td = ACD_ParseNumber(str, "_TD", defValue = 0)

	s.daq = ACD_ParseNumber(str, "_DAQ", defValue = NaN)

	s.tp = ACD_ParseNumber(str, "_TP", defValue = NaN)

	s.stp = ACD_ParseNumber(str, "_STP", defValue = 0)

	s.tbp = ACD_ParseNumber(str, "_TBP", defValue = NaN)

	// default to DAQ if nothing is choosen
	if(IsNaN(s.daq) && IsNaN(s.tp))
		s.daq = 1
		s.tp  = 0
	elseif(IsNaN(s.daq))
		s.daq = 0
	elseif(IsNaN(s.tp))
		s.tp = 0
	endif

	s.amp = ACD_ParseNumber(str, "_AMP", defValue = 1)

	s.iti = ACD_ParseNumber(str, "_ITI", defValue = NaN)

	s.gsi = ACD_ParseNumber(str, "_GSI", defValue = 1)

	s.tpi = ACD_ParseNumber(str, "_TPI", defValue = 1)

	s.itp = ACD_ParseNumber(str, "_ITP", defValue = 1)

	s.far = ACD_ParseNumber(str, "_FAR", defValue = 1)

	s.sim = ACD_ParseNumber(str, "_SIM", defValue = 1)

	s.ffr = ACD_ParseString(str, "_FFR", defValue = NONE)

	s.tpd = ACD_ParseNumber(str, "_TPD", defValue = NaN)

	WAVE/Z/T hsConfig = ListToTextWave(str, "__")

	if(WaveExists(hsConfig))
		// Throw away first element as that is not a hsConfig element
		DeletePoints ROWS, 1, hsConfig

		Make/FREE/N=(NUM_HEADSTAGES) s.hs = 0
		Make/FREE/N=(NUM_HEADSTAGES) s.ttl = 0
		Make/FREE/N=(NUM_HEADSTAGES) s.ad = NaN
		Make/FREE/N=(NUM_HEADSTAGES) s.da = NaN
		Make/FREE/N=(NUM_HEADSTAGES) s.cm = NaN
		Make/FREE/N=(NUM_HEADSTAGES) s.aso = NaN
		Make/FREE/T/N=(NUM_HEADSTAGES) s.st, s.ist, s.af, s.st_ttl, s.iaf

		for(elem : hsConfig)
			// no __ prefix as we have splitted it above at two __

			if(GrepString(elem, "^TTL"))
				ttl        = ACD_ParseNumber(elem, "TTL")
				s.ttl[ttl] = 1

				s.st_ttl[ttl] = ACD_ParseString(elem, "_ST", defValue = "")
				continue
			endif

			headstage = ACD_ParseNumber(elem, "HS")
			ASSERT(IsValidHeadstage(headstage), "Invalid headstage")

			s.hs[headstage] = 1

			s.da[headstage] = ACD_ParseNumber(elem, "_DA")

			s.ad[headstage] = ACD_ParseNumber(elem, "_AD")

			output = ACD_ParseString(elem, "_CM")

			strswitch(output)
				case "IC":
					clampMode = I_CLAMP_MODE
					break
				case "VC":
					clampMode = V_CLAMP_MODE
					break
				case "I=0":
					clampMode = I_EQUAL_ZERO_MODE
					break
				default:
					FATAL_ERROR("")
			endswitch

			s.cm[headstage] = clampMode

			s.st[headstage]  = ACD_ParseString(elem, "_ST", defValue = "")
			s.ist[headstage] = ACD_ParseString(elem, "_IST", defValue = "")
			s.af[headstage]  = ACD_ParseString(elem, "_AF", defValue = "")
			s.iaf[headstage] = ACD_ParseString(elem, "_IAF", defValue = "")

			s.aso[headstage] = ACD_ParseNumber(elem, "_ASO", defValue = 1)
		endfor
	endif
End

/// @brief Configuration management for executing tests which require hardware
///
/// Setting up data acquisition is a tedious task. We have therefore developed a configuration management to speed that up.
///
/// Example:
///
/// \rst
/// .. code-block:: igorpro
///
///		/// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
/// 	static Function MyTest([string str])
///
///			struct ACD_DAQSettings s
///			ACD_InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"             + \
/// 	                                 "__HS0_DA0_AD0_CM:IC:_ST:ABCD:")
///
///			ACD_AcquireData(s, md.s0)
/// 	End
///
/// 	static Function MyTest_REENTRY([string str])
/// 	    // ...
/// 	End
/// \endrst
///
/// This starts data acquisition with one active headstage (HS0) in current clamp (:IC:) on DA0 and AD0 with stimulus set ABCD.
/// As a rule of thumb new entries should be added here if we have more than three users of a setting.
///
/// Numeric parameters are directly passed after the name, string parameters are enclosed in colons (`:`).
///
/// Required:
/// - MultiDevice (MD: 1/0)
/// - Repeated Acquisition (RA: 1/0)
/// - Indexing (I: 1/0)
/// - Locked Indexing (L: 1/0)
/// - Background Data acquisition (BKG: 1/0)
///
/// Optional:
/// - Use amplifier: (amp: 1/0)
/// - Distributed data acquisition: (dDAQ: 1/0)
/// - Optimized overlap distributed data acquisition: (oodDAQ: 1/0)
/// - Repeat Sets (RES: [1, inf])
/// - Open Databrowser (DB: 1/0)
/// - Onset user delay (OD: > 0)
/// - Termination delay (TD: > 0)
/// - dDAQ delay (DDL: > 0)
/// - Run testpulse instead (TP: 1/0)
/// - Run data acquisition (DAQ: 1/0). Running data acquisition is the default. Setting `_TP0_DAQ0`
///   allows to not start anything.
/// - Set the ITI (ITI: > 0)
/// - Get/Set ITI checkbox (GSI: 1/0)
/// - TP during ITI checkbox (TPI: 1/0)
/// - Inserted TP checkbox (ITP: 1/0)
/// - Fail on Abort/RTE: (FAR: 1/0), defaults to 1
/// - Sampling interval multiplier (SIM: 1, 2, 4, ..., 64), defaults to 1
/// - Save TP: (STP: 1/0), defaults to 0
/// - TP Baseline Percentage: (TBP: [25, 49])
/// - Fixed frequency acquisition: (FFR: see @ref DAP_GetSamplingFrequencies() for available values)
/// - TP Duration: (TPD: [5, inf[)
///
/// HeadstageConfig:
/// - Full specification: __HSXX_ADXX_DAXX_CM:XX:_ST:XX:_IST:XX:_AF:XX:_IAF:XX:_ASOXX
///   Required:
///      - HS
///      - AD
///      - DA
///      - CM (VC/IC/IZ): clamp mode
///   Optional:
///      - ST: stimulus set
///      - IST: indexing stimulus set
///      - AF: analysis function for stimulus set
///      - IAF: analysis function for indexing stimulus set
///      - ASO (1/0): severes the amplifier connection and disables the headstage again after configuration, thus making the
///                   DA and AD channels unassociated
///
/// TTLConfig:
/// - Full specification: __TTLXX_ST:XX:
///   Required:
///      - TTL
///   Optional:
///      - ST: TTL stimulus set
///
/// For tweaking data acquisition with full flexibility we also support
/// customization functions before initialization, preInit aka before the DAEphys
/// panel is created, and before acquisition, preAcq aka before the Start DAQ/TP
/// button is pressed. The global functions, which are still per test suite,
/// must be called `GlobalPreAcq`/`GlobalPreInit` and the per test case ones
/// `${testcase}_PreAcq`/`${testcase}_PreInit`. They must all be static. The
/// global functions are called *before* the per test case functions. This
/// allows to override the global ones.
Function ACD_AcquireData(STRUCT ACD_DAQSettings &s, string device)

	string ctrl
	variable i, activeHS

	if(s.amp)
		ACD_EnsureMCCIsOpen()
	endif

	ACD_FetchCustomizationFunctions(s)

	s.globalPreInitFunc(device)
	s.preInitFunc(device)

	ACD_CreateLockedDAEphys(device)

#ifdef TESTS_WITH_SUTTER_HARDWARE
	Duplicate/FREE s.hs, sutterRequirementCheck
	sutterRequirementCheck[] = s.aso[p] == 1 && s.hs[p] == 1
	if(!(sum(sutterRequirementCheck) == 1 && sutterRequirementCheck[0] == 1))
		INFO("SUTTER hardware currently supports only 1 HS")
		SKIP_TESTCASE()
	endif

	WAVE deviceInfo = GetDeviceInfoWave(device)
#endif // TESTS_WITH_SUTTER_HARDWARE

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		PGC_SetAndActivateControl(device, "Popup_Settings_Headstage", val = i)

		if(s.hs[i] == 0)
#ifndef TESTS_WITH_SUTTER_HARDWARE
			PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")
#endif // !TESTS_WITH_SUTTER_HARDWARE
			continue
		endif

		if(IsEmpty(s.st[i]))
			ASSERT(s.TP, "Expected TP to be set without stimset")
		else
			ctrl = GetPanelControl(s.da[i], CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
			PGC_SetAndActivateControl(device, ctrl, str = s.st[i])
		endif

#ifndef TESTS_WITH_SUTTER_HARDWARE
		PGC_SetAndActivateControl(device, "Popup_Settings_VC_DA", str = num2str(s.da[i]))
		PGC_SetAndActivateControl(device, "Popup_Settings_IC_DA", str = num2str(s.da[i]))
		PGC_SetAndActivateControl(device, "Popup_Settings_VC_AD", str = num2str(s.ad[i]))
		PGC_SetAndActivateControl(device, "Popup_Settings_IC_AD", str = num2str(s.ad[i]))
#endif // !TESTS_WITH_SUTTER_HARDWARE

		if(s.aso[i] != 1)
#ifdef TESTS_WITH_SUTTER_HARDWARE
			INFO("Unassociated channel %d is setup on an existing HS", n0 = i)
			CHECK_GT_VAR(i + 1, deviceInfo[%DA])
#endif // TESTS_WITH_SUTTER_HARDWARE
#ifndef TESTS_WITH_SUTTER_HARDWARE
			PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")
#endif // !TESTS_WITH_SUTTER_HARDWARE
			ctrl = GetPanelControl(s.da[i], CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
			PGC_SetAndActivateControl(device, ctrl, val = 1)
			ctrl = GetPanelControl(s.da[i], CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
			PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)
			ctrl = GetPanelControl(s.da[i], CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
			PGC_SetAndActivateControl(device, ctrl, str = "V")
			ctrl = GetPanelControl(s.ad[i], CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
			PGC_SetAndActivateControl(device, ctrl, val = 1)
			ctrl = GetPanelControl(s.ad[i], CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
			PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)
			ctrl = GetPanelControl(s.ad[i], CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
			PGC_SetAndActivateControl(device, ctrl, str = "V")

			continue
		endif
		// associated HS below here
		ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED, switchTab = 1)

#ifdef TESTS_WITH_SUTTER_HARDWARE
		INFO("Associated HS %d does not exist on this Sutter HW setup", n0 = i)
		CHECK_LT_VAR(i, deviceInfo[%DA])
		INFO("Requested DA channel %d for HS %d does not match fixed DA channel of Sutter HW setup", n0 = s.da[i], n1 = i)
		CHECK_EQUAL_VAR(i, s.da[i])
		INFO("Requested AD channel %d for HS %d does not match fixed AD channel of Sutter HW setup", n0 = s.ad[i], n1 = i)
		CHECK_EQUAL_VAR(i, s.ad[i])
#endif // TESTS_WITH_SUTTER_HARDWARE

		if(s.amp && activeHS < 2)
			// first entry is none
			PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", val = 1 + activeHS)

			PGC_SetAndActivateControl(device, "button_Hardware_AutoGainAndUnit")
		endif

		if(!IsEmpty(s.ist[i]))
			ctrl = GetPanelControl(s.da[i], CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
			PGC_SetAndActivateControl(device, ctrl, str = s.ist[i])

			if(!IsEmpty(s.iaf[i]))
				ST_SetStimsetParameter(s.ist[i], "Analysis function (Generic)", str = s.iaf[i])
			endif
		endif

		if(!IsEmpty(s.af[i]))
			ST_SetStimsetParameter(s.st[i], "Analysis function (Generic)", str = s.af[i])
		endif

		ctrl = DAP_GetClampModeControl(s.cm[i], i)
		PGC_SetAndActivateControl(device, ctrl, val = 1)
		DoUpdate/W=$device

		activeHS += 1
	endfor

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!s.ttl[i])
			continue
		endif

		if(i >= NUM_ITC_TTL_BITS_PER_RACK                 \
		   && GetHardwareType(device) == HARDWARE_ITC_DAC \
		   && HW_ITC_GetNumberOfRacks(device) < 2)
			// ignore unavailable TTLs on single-rack ITC setup
			continue
		endif

		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(device, ctrl, val = s.ttl[i])

		if(!IsEmpty(s.st_ttl[i]))
			ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
			PGC_SetAndActivateControl(device, ctrl, str = s.st_ttl[i])
		endif
	endfor

	PGC_SetAndActivateControl(device, "check_Settings_RequireAmpConn", val = (s.amp ? CHECKBOX_SELECTED : CHECKBOX_UNSELECTED))
	PGC_SetAndActivateControl(device, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = s.LIDX)

	PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = s.dDAQ)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = s.oodDAQ)

	PGC_SetAndActivateControl(device, "setvar_DataAcq_OnsetDelayUser", val = s.od)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_TerminationDelay", val = s.td)
	PGC_SetAndActivateControl(device, "Setvar_DataAcq_dDAQDelay", val = s.ddl)

	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = s.gsi)

	PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str = num2str(s.sim))

	if(cmpstr(s.ffr, NONE))
		PGC_SetAndActivateControl(device, "Popup_Settings_FixedFreq", str = s.ffr)
	endif

	// these don't have good defaults
	if(IsFinite(s.iti))
		PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = s.iti)
	endif

	if(IsFinite(s.tpd))
		PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPDuration", val = s.tpd)
	endif

	PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = s.tpi)

	PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = s.itp)

	if(!s.MD)
		PGC_SetAndActivateControl(device, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	else
		ASSERT(s.BKG_DAQ == 1, "Only supports background DAQ with multi device support")
	endif

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(device, "check_Settings_TP_SaveTP", val = s.STP)

	if(IsFinite(s.TBP))
		PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = s.TBP)
	endif

	s.globalPreAcquireFunc(device)
	s.preAcquireFunc(device)

	if(s.DB)
		ACD_OpenDatabrowser()
	endif

	AssertOnAndClearRTError()
	try
		if(s.TP && !s.DAQ)
			PGC_SetAndActivateControl(device, "StartTestPulseButton")
		elseif(!s.TP && s.DAQ)
			PGC_SetAndActivateControl(device, "DataAcquireButton")
		endif
	catch
		if(s.FAR)
			// fail hard on aborts, most likely due to memory error on HW_ITC_StartAcq
			FATAL_ERROR("Requested abort on errors")
		endif

		Abort
	endtry
End
