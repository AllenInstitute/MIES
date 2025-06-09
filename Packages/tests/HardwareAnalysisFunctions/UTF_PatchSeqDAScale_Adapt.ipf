#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = PatchSeqTestDAScaleAdapt

/// Test matrix
/// @rst
///
/// .. Column order: test overrides, labnotebook entries, analysis parameters
///
///============= ==================== ============================ ============================== ========================= ====================== ================================== ============ ================== ================== ====================== ============================== ========== ============= =============== ================= ========================= ============================== =========================== ============================= ========================= =================== ============================= ==============================
///  Test case    Baseline chunk0 QC   Baseline chunk [1, inf] QC   Enough rheobase/supra sweeps   Passing rheobase sweeps   Passing supra sweeps   Initial f-I data is dense enough   Failed f-I   Neg f-I slope QC   Fit f-I slope QC   Enough f-I points QC   Measured all future DAScales   Async QC   Sampling QC   Fillin QC       SlopePercentage   NumSweepsWithSaturation   DAScaleRangeFactor             MaxFrequencyChangePercent   DaScaleStepWidthMinMaxRatio   AbsFrequencyMinDistance   SamplingFrequency   DAScaleNegativeSlopePercent   MinimumSpikeCountForMaxSlope
///============= ==================== ============================ ============================== ========================= ====================== ================================== ============ ================== ================== ====================== ============================== ========== ============= =============== ================= ========================= ============================== =========================== ============================= ========================= =================== ============================= ==============================
///  PS_DS_AD1    -                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  -                  ✓                      ✓                              -          ✓             -               def               2                         def                            5                           3                             2                         def                 def                           0
///  PS_DS_AD1a   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  -                  ✓                      ✓                              [✓,-,✓]    ✓             [✓ ,-,-]        def               3                         def                            5                           3                             2                         def                 def                           0
///  PS_DS_AD2    ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  ✓                  ✓                      ✓                              ✓          ✓             -               def               1                         def                            25                          3                             2                         def                 def                           0
///  PS_DS_AD2a   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  ✓                  ✓                      ✓                              ✓          ✓             -               def               2                         def                            25                          3                             2                         def                 10                            0
///  PS_DS_AD2b   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            [-,✓]              ✓                  ✓                      ✓                              ✓          ✓             -               def               2                         def                            25                          1.5                           2                         def                 10                            0
///  PS_DS_AD3    [-,✓,✓]              ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  [-,✓,✓]            ✓                      [✓,-,✓]                        ✓          ✓             -               def               2                         def                            25                          3                             2                         def                 def                           0
///  PS_DS_AD4    ✓                    ✓                            ✓                              ✓                         -                      ✓                                  ✓            -                  ✓                  ✓                      ✓                              ✓          ✓             -               def               2                         def                            25                          3                             2                         def                 def                           0
///  PS_DS_AD4a   ✓                    ✓                            ✓                              -                         ✓                      ✓                                  ✓            -                  ✓                  ✓                      ✓                              ✓          ✓             -               def               2                         def                            25                          3                             2                         def                 def                           0
///  PS_DS_AD5    ✓                    ✓                            -                              ✓                         ✓                      ✓                                  ✓            -                  ✓                  ✓                      ✓                              ✓          ✓             -               def               2                         def                            25                          3                             2                         def                 def                           0
///  PS_DS_AD6    ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            ✓                  ✓                  ✓                      ✓                              ✓          ✓             -               def               1                         def                            25                          3                             2                         def                 def                           0
///  PS_DS_AD7    ✓                    ✓                            ✓                              ✓                         ✓                      -                                  ✓            [-,-,✓]            [✓,-,✓]            ✓                      [-,-,✓]                        ✓          ✓             [✓,✓ ,-]        def               1                         def                            10                          1.1                           2                         def                 def                           0
///  PS_DS_AD8    ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  ✓                  ✓                      ✓                              ✓          ✓             -               def               1                         def                            25                          3                             2                         def                 def                           0
///  PS_DS_AD10   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  -                  ✓                      -                              ✓          ✓             -               def               2                         def                            25                          1.2                           2                         def                 def                           0
///  PS_DS_AD12   [✓,-,✓,✓,✓,✓]        ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            [-,-,✓,-,✓,-,]     [-,-,✓,-,-,-,]     ✓                      [-,✓,-,-,-,✓]                  ✓          ✓             [-,-,-,✓,-,✓]   def               2                         def                            25                          3                             1.1                       def                 def                           0
///  PS_DS_AD13   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  -                  ✓                      ✓                              ✓          -             -               def               2                         def                            25                          3                             0.5                       def                 def                           0
///  PS_DS_AD14   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  [-,✓ ]       -                  [-,-,✓]            ✓                      [-,-,✓]                        ✓          ✓             -               def               1                         def                            25                          3                             2                         def                 def                           0
///  PS_DS_AD15   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  [-,✓ ]       -                  ✓                  ✓                      -                              ✓          ✓             [-,-,✓ ]        def               1                         def                            25                          3                             2                         def                 def                           0
///  PS_DS_AD16   ✓                    [-,-,✓,-,✓]                  ✓                              ✓                         ✓                      ✓                                  ✓            -                  [-,-,✓,✓,✓]        ✓                      [✓,✓,-,✓,✓]                    ✓          ✓             -               def               2                         def                            25                          3                             1.1                       def                 def                           0
///  PS_DS_AD17   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  -                  ✓                      ✓                              ✓          ✓             -               def               2                         def                            25                          3                             1.1                       def                 def                           0
///  PS_DS_AD18   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  -                  ✓                      ✓                              ✓          ✓             -               def               3                         def                            25                          3                             1.1                       def                 def                           0
///  PS_DS_AD19   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            ✓                  -                  ✓                      ✓                              ✓          ✓             -               def               def                       def                            def                         def                           def                       def                 def                           0
///  PS_DS_AD20   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            ✓                  -                  ✓                      ✓                              ✓          ✓             -               def               3                         def                            25                          def                           1.1                       def                 def                           0
///  PS_DS_AD21   [✓,✓,-]              ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            ✓                  -                  ✓                      ✓                              ✓          ✓             [-,-,✓ ]        def               3                         def                            25                          def                           1.1                       def                 def                           0
///  PS_DS_AD22   ✓                    ✓                            ✓                              ✓                         ✓                      ✓                                  ✓            -                  ✓                  ✓                      ✓                              ✓          ✓             -               def               3                         def                            25                          def                           1.1                       def                 def                           10
///============= ==================== ============================ ============================== ========================= ====================== ================================== ============ ================== ================== ====================== ============================== ========== ============= =============== ================= ========================= ============================== =========================== ============================= ========================= =================== ============================= ==============================
///
/// @endrst

static Function [STRUCT DAQSettings s] PS_GetDAQSettings(string device)

	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DB1"                                                         + \
	                             "__HS" + num2str(PSQ_TEST_HEADSTAGE) + "_DA0_AD0_CM:IC:_ST:PSQ_DaScale_Adapt_DA_0:")
	return [s]
End

static Function GlobalPreInit(string device)

	ST_SetStimsetParameter("PSQ_DaScale_Adapt_DA_0", "Analysis function (generic)", str = "PSQ_DAScale")
	ST_SetStimsetParameter("PSQ_DaScale_Adapt_DA_0", "Total number of steps", var = 3)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "OperationMode", str = PSQ_DS_ADAPT)

	AdjustAnalysisParamsForPSQ(device, "PSQ_DaScale_Adapt_DA_0")

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MinimumSpikeCountForMaxSlope", var = 0)

	// Ensure that PRE_SET_EVENT already sees the test override as enabled
	Make/O/N=(0) root:overrideResults/WAVE=overrideResults
	Note/K overrideResults
End

static Function GlobalPreAcq(string device)

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = 70)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPBaselinePerc", val = 25)
End

static Function/WAVE GetResultsSingleEntry_IGNORE(string name)

	variable nameCol, typeCol

	WAVE/T textualResultsValues = GetTextualResultsValues()

	[WAVE indizesName, nameCol] = GetNonEmptyLBNRows(textualResultsValues, name)
	[WAVE indizesType, typeCol] = GetNonEmptyLBNRows(textualResultsValues, "EntrySourceType")

	if(!WaveExists(indizesName) || !WaveExists(indizesType))
		return $""
	endif

	indizesType[] = (str2numSafe(textualResultsValues[indizesType[p]][typeCol][INDEP_HEADSTAGE]) == SWEEP_FORMULA_RESULT) ? indizesType[p] : NaN

	WAVE/Z indizesTypeClean = ZapNaNs(indizesType)

	if(!WaveExists(indizesTypeClean))
		return $""
	endif

	WAVE/Z indizes = GetSetIntersection(indizesName, indizesTypeClean)

	if(!WaveExists(indizes))
		return $""
	endif

	Make/FREE/T/N=(DimSize(indizes, ROWS)) entries = textualResultsValues[indizes[p]][nameCol][INDEP_HEADSTAGE]

	return entries
End

static Function/WAVE GetLBNSingleEntry_IGNORE(string device, variable sweepNo, string name)

	variable val, type
	string key, str

	CHECK(IsValidSweepNumber(sweepNo))
	CHECK_LE_VAR(sweepNo, AFH_GetLastSweepAcquired(device))

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	type = PSQ_DA_SCALE

	strswitch(name)
		case PSQ_FMT_LBN_SWEEP_PASS:
		case PSQ_FMT_LBN_SWEEP_EXCEPT_BL_PP_PASS:
		case PSQ_FMT_LBN_SAMPLING_PASS:
		case PSQ_FMT_LBN_ASYNC_PASS:
		case PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES_PASS:
		case PSQ_FMT_LBN_DA_AT_FILLIN_PASS:
		case PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS:
		case PSQ_FMT_LBN_DA_AT_FI_NEG_SLOPE_PASS:
		case PSQ_FMT_LBN_DA_AT_ENOUGH_FI_POINTS_PASS:
		case PSQ_FMT_LBN_DA_AT_MIN_DASCALE_NORM:
		case PSQ_FMT_LBN_DA_AT_MAX_DASCALE_NORM:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_DA_AT_FREQ:
		case PSQ_FMT_LBN_DA_AT_MAX_SLOPE:
		case PSQ_FMT_LBN_DA_AT_FI_OFFSET:
		case PSQ_FMT_LBN_DA_AT_FI_SLOPE:
		case PSQ_FMT_LBN_DA_AT_FI_OFFSET_DASCALE:
		case PSQ_FMT_LBN_DA_AT_FI_SLOPE_DASCALE:
		case PSQ_FMT_LBN_BL_QC_PASS:
		case PSQ_FMT_LBN_DASCALE_OOR:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_SET_PASS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			val = GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			Make/D/FREE wv = {val}
			return wv
		case PSQ_FMT_LBN_RMS_SHORT_PASS:
		case PSQ_FMT_LBN_RMS_LONG_PASS:
			key = CreateAnaFuncLBNKey(type, name, chunk = 0, query = 1)
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			return GetLastSettingTextEachSCI(numericalValues, textualValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
		case PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES:
		case PSQ_FMT_LBN_DA_AT_RSA_FI_OFFSETS:
		case PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES_DASCALE:
		case PSQ_FMT_LBN_DA_AT_RSA_FI_OFFSETS_DASCALE:
		case PSQ_FMT_LBN_DA_AT_RSA_FREQ:
		case PSQ_FMT_LBN_DA_AT_RSA_DASCALE:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			WAVE/Z/T settings = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)

			if(!WaveExists(settings))
				return $""
			endif

			return ListToNumericWave(settings[PSQ_TEST_HEADSTAGE], ";")
		case PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES_PASS:
		case PSQ_FMT_LBN_DA_AT_RSA_FI_NEG_SLOPES_PASS:
		case PSQ_FMT_LBN_DA_AT_RSA_FILLIN_PASS:
		case PSQ_FMT_LBN_DA_AT_RSA_SWEEPS:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			WAVE/T settings = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			return ListToNumericWave(settings[INDEP_HEADSTAGE], ";")
		case STIMSET_SCALE_FACTOR_KEY:
			return GetLastSettingEachSCI(numericalValues, sweepNo, name, PSQ_TEST_HEADSTAGE, DATA_ACQUISITION_MODE)
		case PSQ_FMT_LBN_DA_OPMODE:
			key = CreateAnaFuncLBNKey(type, name, query = 1)
			str = GetLastSettingTextIndepSCI(numericalValues, textualValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
			Make/T/FREE wvTxt = {str}
			return wvTxt
		default:
			INFO("Missing case statement for LBN entry %s", s0 = name)
			FAIL()
	endswitch
End

static Function/WAVE GetWave_IGNORE()

	string list = "sweepPass;sweepPassExceptBL;setPass;rmsShortPass;"          + \
	              "rmsLongPass;baselinePass;samplingPass;asyncPass;"           + \
	              "fillinPass;"                                                + \
	              "futureDAScalesPass;fiSlopeReachedPass;fiNegSlopePass;"      + \
	              "enoughFIPointsPass;"                                        + \
	              "opMode;apFreq;maxSlope;fiSlope;fiOffset;futureDAScales;"    + \
	              "fiSlopesFromRhSuAd;fiNegSlopesPassFromRhSuAd;"              + \
	              "fiOffsetsFromRhSuAd;sweepPassFromRhSuAd;"                   + \
	              "fiSlopeReachedPassFromRhSuAd;fillinPassFromRhSuAd;daScale;" + \
	              "apFreqFromRhSuAd;dascaleFromRhSuAd;minDaScaleNorm;"         + \
	              "maxDAScaleNorm;oorDAScale;"                                 + \
	              "fiSlopesDAScaleFromRhSuAd;fiOffsetsDAScaleFromRhSuAd;"      + \
	              "fiSlopeDAScale;fiOffsetDAScale;"

	Make/FREE/WAVE/N=(ItemsInList(list)) wv
	SetDimensionLabels(wv, list, ROWS)

	return wv
End

static Function/WAVE GetEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/WAVE wv = GetWave_IGNORE()

	wv[%sweepPass]         = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SWEEP_PASS)
	wv[%sweepPassExceptBL] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SWEEP_EXCEPT_BL_PP_PASS)
	wv[%setPass]           = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SET_PASS)
	wv[%samplingPass]      = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_SAMPLING_PASS)
	wv[%asyncPass]         = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_ASYNC_PASS)

	wv[%rmsShortPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_SHORT_PASS)
	wv[%rmsLongPass]  = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_RMS_LONG_PASS)
	wv[%baselinePass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_BL_QC_PASS)

	wv[%opMode]                       = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_OPMODE)
	wv[%apFreq]                       = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_FREQ)
	wv[%maxSlope]                     = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_MAX_SLOPE)
	wv[%fiSlope]                      = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_FI_SLOPE)
	wv[%fiOffset]                     = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_FI_OFFSET)
	wv[%fiSlopeDAScale]               = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_FI_SLOPE_DASCALE)
	wv[%fiOffsetDAScale]              = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_FI_OFFSET_DASCALE)
	wv[%fiNegSlopePass]               = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_FI_NEG_SLOPE_PASS)
	wv[%futureDAScales]               = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES)
	wv[%fillinPass]                   = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_FILLIN_PASS)
	wv[%fiSlopesFromRhSuAd]           = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES)
	wv[%fiOffsetsFromRhSuAd]          = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_FI_OFFSETS)
	wv[%fiSlopesDAScaleFromRhSuAd]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES_DASCALE)
	wv[%fiOffsetsDAScaleFromRhSuAd]   = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_FI_OFFSETS_DASCALE)
	wv[%fiNegSlopesPassFromRhSuAd]    = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_FI_NEG_SLOPES_PASS)
	wv[%sweepPassFromRhSuAd]          = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_SWEEPS)
	wv[%fiSlopeReachedPassFromRhSuAd] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES_PASS)
	wv[%fillinPassFromRhSuAd]         = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_FILLIN_PASS)
	wv[%dascale]                      = GetLBNSingleEntry_IGNORE(device, sweepNo, STIMSET_SCALE_FACTOR_KEY)
	wv[%apFreqFromRhSuAd]             = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_FREQ)
	wv[%dascaleFromRhSuAd]            = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_RSA_DASCALE)
	wv[%minDaScaleNorm]               = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_MIN_DASCALE_NORM)
	wv[%maxDaScaleNorm]               = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_MAX_DASCALE_NORM)
	wv[%oorDAScale]                   = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DASCALE_OOR)

	wv[%futureDAScalesPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES_PASS)
	wv[%fiSlopeReachedPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	wv[%enoughFIPointsPass] = GetLBNSingleEntry_IGNORE(device, sweepNo, PSQ_FMT_LBN_DA_AT_ENOUGH_FI_POINTS_PASS)

	Make/FREE/N=(DimSize(wv, ROWS)) junk
	junk[] = WaveExists(wv[p]) ? ChangeFreeWaveName(wv[p], GetDimLabel(wv, ROWS, p)) : NaN

	return wv
End

static Function CheckSurveyPlot(string device, WAVE/WAVE entries)

	string databrowser, sfgraph, allGraphs, traceList, graph
	variable i, numGraphs

	databrowser = DB_FindDatabrowser(device, mode = BROWSER_MODE_AUTOMATION)
	CHECK(WindowExists(databrowser))

	sfgraph = SFH_GetFormulaGraphForBrowser(databrowser)
	CHECK(WindowExists(sfgraph))

	allGraphs = GetAllWindows(sfGraph)

	Duplicate/FREE entries[%sweepPassFromRhSuAd], sweepPassFromRhSuAddQC
	sweepPassFromRhSuAddQC[] = 1

	Concatenate/FREE/NP=(ROWS) {entries[%dascaleFromRhSuAd], entries[%dascale]}, DAScale
	Concatenate/FREE/NP=(ROWS) {sweepPassFromRhSuAddQC, entries[%sweepPass]}, sweepPass

	if(WaveExists(entries[%fiSlope]))
		Concatenate/FREE/NP=(ROWS) {entries[%fiSlopesFromRhSuAd], entries[%fiSlope]}, fISlope

		WAVE fISlopeFiltered = MIES_PSQ#PSQ_DS_FilterPassingData(fISlope, sweepPass, inbetween = 1)
		WaveClear fISlope
	else
		WAVE fISlopeFiltered = entries[%fiSlopesFromRhSuAd]
	endif

	if(WaveExists(entries[%apfreq]))
		Concatenate/FREE/NP=(ROWS) {entries[%apFreqFromRhSuAd], entries[%apfreq]}, apFreq

		WAVE ApFreqFiltered = MIES_PSQ#PSQ_DS_FilterPassingData(apFreq, sweepPass)
		WaveClear ApFreq
	else
		WAVE apFreqFiltered = entries[%apFreqFromRhSuAd]
	endif

	WAVE DAScaleFiltered = MIES_PSQ#PSQ_DS_FilterPassingData(DAScale, sweepPass)
	WaveClear DAScale

	Duplicate/FREE DAScaleFiltered, DAScaleFilteredWithoutFirstPoint
	DeletePoints/M=(ROWS) 0, 1, DAScaleFilteredWithoutFirstPoint

	numGraphs = ItemsInList(allGraphs)
	for(i = 0; i < numGraphs; i += 1)
		graph     = StringFromList(i, allGraphs, ";")
		traceList = TraceNameList(graph, ";", 1 + 2)

		if(!isEmpty(traceList))
			WAVE traces = ListToTextWave(traceList, ";")
			CHECK_EQUAL_VAR(DimSize(traces, ROWS), 1)

			WAVE/ZZ yWave = WaveRefIndexed(graph, 0, 1)
			CHECK_WAVE(yWave, NUMERIC_WAVE)
			Redimension/E=1/N=(-1, 0) yWave

			WAVE/ZZ xWave = WaveRefIndexed(graph, 0, 2)
			CHECK_WAVE(xWave, NUMERIC_WAVE)
			Redimension/E=1/N=(-1, 0) xWave

			if(strsearch(graph, "Graph0", 0) >= 0)
				// frequency vs DAScale
				CHECK_EQUAL_WAVES(DAScaleFiltered, xWave, mode = WAVE_DATA, tol = 1e-6)
				CHECK_EQUAL_WAVES(apFreqFiltered, yWave, mode = WAVE_DATA, tol = 1e-6)
			elseif(strsearch(graph, "Graph1", 0) >= 0)
				// f-I slopes vs DAScale
				CHECK_EQUAL_WAVES(DAScaleFilteredWithoutFirstPoint, xWave, mode = WAVE_DATA, tol = 1e-6)
				CHECK_EQUAL_WAVES(fISlopeFiltered, yWave, mode = WAVE_DATA, tol = 1e-6)
			else
				FATAL_ERROR("Unexpected graph name")
			endif
		endif
	endfor
End

static Function [WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] ExtractRefValuesFromOverride(variable sweepNo, [WAVE baselineQC])

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)

	Duplicate/FREE/RMD=[0][0, sweepNo][FindDimLabel(overrideResults, LAYERS, "APFrequency")] overrideResults, apFreqRef
	Redimension/N=(DimSize(apFreqRef, COLS)) apFreqRef

	WAVE/Z apFreqFromRhSuAd      = JWN_GetNumericWaveFromWaveNote(overrideResults, "/APFrequenciesRhSuAd")
	WAVE/Z DAScalesFromRhSuAd    = JWN_GetNumericWaveFromWaveNote(overrideResults, "/DAScalesRhSuAd")
	WAVE/Z sweepPassedFRomRhSuAd = JWN_GetNumericWaveFromWaveNote(overrideResults, "/PassingRhSuAdSweeps")

	if(!ParamIsDefault(baselineQC))
		apFreqRef[] = (baselineQC[p] == 1) ? apFreqRef[p] : NaN

		if(!HasOneValidEntry(apFreqRef))
			WaveClear apFreqRef
		endif
	endif

	return [apFreqRef, apFreqFromRhSuAd, DAScalesFromRhSuAd, sweepPassedFRomRhSuAd]
End

static Function PrintSomeValues(WAVE/WAVE entries)

	WAVE wv = entries[%maxSlope]
	print/D wv

	WAVE wv = entries[%fiSlope]
	print/D wv

	WAVE/Z wv = entries[%fiSlopeDAScale]
	print/D wv

	WAVE wv = entries[%fiOffset]
	print/D wv

	WAVE/Z wv = entries[%fiOffsetDAScale]
	print/D wv

	WAVE wv = entries[%futureDAScales]
	print/D wv

	WAVE wv = entries[%fiSlopesFromRhSuAd]
	print/D wv

	WAVE wv = entries[%fiOffsetsFromRhSuAd]
	print/D wv

	WAVE wv = entries[%dascale]
	print/D wv

	WAVE wv = entries[%apfreq]
	print/D wv
End

static Function/WAVE VariousInputForHasRequiredQCOrder()

	// IPT_FORMAT_OFF

	// all zero
	Make/FREE firstQC      = {0, 0, 0, 0}
	Make/FREE checkQCFirst = {0, 0, 0}
	Make/FREE lastQC       = {0, 0, 0, 0}
	Make/FREE checkQCLast  = {0, 0, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv0 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// only first
	Make/FREE firstQC      = {0, 0, 0, 0}
	Make/FREE checkQCFirst = {1, 1, 1}
	Make/FREE lastQC       = {0, 0, 0, 0}
	Make/FREE checkQCLast  = {0, 0, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv1 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// only last
	Make/FREE firstQC      = {0, 0, 0, 0}
	Make/FREE checkQCFirst = {0, 0, 0}
	Make/FREE lastQC       = {0, 0, 0, 0}
	Make/FREE checkQCLast  = {1, 1, 1}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv2 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// wrong order
	Make/FREE firstQC      = {0, 1, 1, 0}
	Make/FREE checkQCFirst = {0, 1, 0}
	Make/FREE lastQC       = {0, 1, 1, 0}
	Make/FREE checkQCLast  = {1, 0, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv3 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// correct order
	Make/FREE firstQC      = {0, 1, 1, 0}
	Make/FREE checkQCFirst = {1, 0, 0}
	Make/FREE lastQC       = {0, 1, 1, 0}
	Make/FREE checkQCLast  = {0, 1, 0}
	Make/FREE result       = {1}

	Make/FREE/WAVE wv4 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// correct order but last sweep failed
	Make/FREE firstQC      = {0, 1, 0, 0}
	Make/FREE checkQCFirst = {1, 0, 0}
	Make/FREE lastQC       = {0, 1, 0, 0}
	Make/FREE checkQCLast  = {0, 1, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv5 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// correct order but first sweep failed
	Make/FREE firstQC      = {0, 0, 0, 0}
	Make/FREE checkQCFirst = {1, 0, 0}
	Make/FREE lastQC       = {0, 0, 1, 0}
	Make/FREE checkQCLast  = {0, 1, 0}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv6 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// passes with fail gap
	Make/FREE firstQC      = {0, 0, 1, 0, 0}
	Make/FREE checkQCFirst = {0, 1, 0, 0}
	Make/FREE lastQC       = {0, 0, 0, 0, 1}
	Make/FREE checkQCLast  = {0, 0, 0, 1}
	Make/FREE result       = {1}

	Make/FREE/WAVE wv7 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// fails due to gap with firstQC passing
	Make/FREE firstQC      = {0, 0, 1, 1, 0}
	Make/FREE checkQCFirst = {0, 1, 0, 0}
	Make/FREE lastQC       = {0, 0, 0, 0, 1}
	Make/FREE checkQCLast  = {0, 0, 0, 1}
	Make/FREE result       = {0}

	Make/FREE/WAVE wv8 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	// fails due to gap with lastQC passing
	Make/FREE firstQC      = {0, 1, 0, 0, 0}
	Make/FREE checkQCFirst = {1, 0, 0, 0}
	Make/FREE lastQC       = {0, 0, 1, 1, 0}
	Make/FREE checkQCLast  = {0, 0, 1, 0}
	Make/FREE result       = {0}

	// IPT_FORMAT_ON

	Make/FREE/WAVE wv9 = {firstQC, checkQCFirst, lastQC, checkQCLast, result}

	Make/FREE/WAVE wv = {wv0, wv1, wv2, wv3, wv4, wv5, wv6, wv7, wv8, wv9}

	return wv
End

/// UTF_TD_GENERATOR w0:VariousInputForHasRequiredQCOrder
static Function HasRequiredQCOrderWorks([STRUCT IUTF_mData &m])

	variable ret

	WAVE/WAVE entries = m.w0
	CHECK_EQUAL_VAR(DimSize(entries, ROWS), 5)

	WAVE firstQC      = entries[0]
	WAVE checkQCFirst = entries[1]
	WAVE lastQC       = entries[2]
	WAVE checkQCLast  = entries[3]

	WAVE container = entries[4]
	CHECK_EQUAL_VAR(DimSize(container, ROWS), 1)
	ret = container[0]

	CHECK_EQUAL_VAR(MIES_PSQ#PSQ_DS_HasRequiredQCOrder(firstQC, checkQCFirst, lastQC, checkQCLast), ret)
End

static Function/WAVE VariousInputForCalculateFillinQC()

	// all constant
	Make/FREE DAScales = {1, 1, 1, 1}
	Make/FREE ref = {0, 0, 0, 0}

	Make/FREE/WAVE wv0 = {DAScales, ref}

	// sorted
	Make/FREE DAScales = {1, 2, 3, 4}
	Make/FREE ref = {0, 0, 0, 0}

	Make/FREE/WAVE wv1 = {DAScales, ref}

	// reverse sorted
	Make/FREE DAScales = {4, 3, 2, 1}
	Make/FREE ref = {0, 1, 1, 1}

	Make/FREE/WAVE wv2 = {DAScales, ref}

	// first is largest
	Make/FREE DAScales = {8, 4, 7, 6, 5}
	Make/FREE ref = {0, 1, 1, 1, 1}

	Make/FREE/WAVE wv3 = {DAScales, ref}

	// complicated, smallest first
	Make/FREE DAScales = {1, 4, 3, 6, 5}
	Make/FREE ref = {0, 0, 1, 0, 1}

	Make/FREE/WAVE wv4 = {DAScales, ref}

	// complicated, middle one first
	Make/FREE DAScales = {3, 4, 1, 6, 5}
	Make/FREE ref = {0, 0, 1, 0, 1}

	Make/FREE/WAVE wv5 = {DAScales, ref}

	Make/FREE/WAVE wv = {wv0, wv1, wv2, wv3, wv4, wv5}

	return wv
End

/// UTF_TD_GENERATOR w0:VariousInputForCalculateFillinQC
static Function CalculateFillinQCWorks([STRUCT IUTF_mData &m])

	WAVE/WAVE entries = m.w0
	CHECK_EQUAL_VAR(DimSize(entries, ROWS), 2)

	WAVE DAScales = entries[0]
	WAVE ref      = entries[1]

	Make/N=(DimSize(DAScales, ROWS))/FREE result = MIES_PSQ#PSQ_DS_CalculateFillinQC(DAScales, DAScales[p])
	CHECK_EQUAL_WAVES(ref, result)
End

static Function PS_DS_AD1_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "FailingAdaptiveSCIRange", var = Inf)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 5)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD1([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// all tests fail
	wv[][][%APFrequency] = 20 + 5 * (1 + q)^2
	wv[][][%AsyncQC]     = 0
	wv[][][%BaselineQC]  = 0
End

static Function PS_DS_AD1_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%rmsLongPass], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.025, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {.075, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_WAVE(apFreqRef, NULL_WAVE)
	CHECK_WAVE(entries[%apfreq], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {300, NaN, NaN}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:5;", \
	                                 "RegRhSuAd:5;", \
	                                 "RegRhSuAd:5;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {100, 200, 300}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, 7, 4}
	Make/FREE/D DAScalesRef = {5, 5, 5}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_WAVE(entries[%fiSlope], NULL_WAVE)
	CHECK_WAVE(entries[%fiOffset], NULL_WAVE)
	CHECK_WAVE(entries[%fiSlopeDAScale], NULL_WAVE)
	CHECK_WAVE(entries[%fiOffsetDAScale], NULL_WAVE)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%fiSlopesDAScaleFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsDAScaleFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)

	// start again to check that PSQ_GetPreviousSetQCFailingAdaptive is working correctly
	PGC_SetAndActivateControl(str, "DataAcquireButton")

	RegisterReentryFunction("PatchSeqTestDAScaleAdapt#" + GetRTStackInfo(1))
End

static Function PS_DS_AD1_REENTRY_REENTRY([string str])

	variable sweepNo
	sweepNo = 5

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	WAVE/Z passingAdSweepsFailSet = JWN_GetNumericWaveFromWaveNote(overrideResults, "PassingAdaptiveSweepFromFailingSet")

	Make/FREE/D/N=0 empty
	CHECK_EQUAL_WAVES(passingAdSweepsFailSet, empty)
End

static Function PS_DS_AD1a_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 3)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "FailingAdaptiveSCIRange", var = 2)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 5)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {10, 20, 30, 40}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD1a([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// async QC passes for first sweep and third sweep only
	wv                      = 0
	wv[][][%APFrequency]    = 17 + 0.1 * q
	wv[][0, 2; 2][%AsyncQC] = 1
	wv[][][%BaselineQC]     = 1
End

static Function PS_DS_AD1a_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {1, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.25, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.75, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {80, 80, 80}
	Make/FREE/D fiSlopeRef = {80, 27.5, 30}
	Make/FREE/D fiOffsetRef = {-11, 4.999999999999986, 4.000000000000009}

	Make/FREE/T futureDAScalesRef = {"FillinRhSuAd:35;RegRhSuAd:44;",      \
	                                 "FillinRhSuAd:35;RegRhSuAd:44;",      \
	                                 "FillinRhSuAd:35;RegRhSuAd:44;Reg:49;"}
	Make/FREE/D fiSlopesFromRhSuAdRef = {10, 20, 30}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, 7, 4}
	Make/FREE/D DAScalesRef = {35, 44, 44}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%fiSlopeDAScale], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetDAScale], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%fiSlopesDAScaleFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsDAScaleFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	WAVE/Z passingAdSweepsFailSet = JWN_GetNumericWaveFromWaveNote(overrideResults, "PassingAdaptiveSweepFromFailingSet")

	Make/FREE/D/N=0 empty
	CHECK_EQUAL_WAVES(passingAdSweepsFailSet, empty)

	PGC_SetAndActivateControl(str, "DataAcquireButton")
	RegisterReentryFunction("PatchSeqTestDAScaleAdapt#" + GetRTStackInfo(1))
End

static Function PS_DS_AD1a_REENTRY_REENTRY([string str])

	variable sweepNo

	sweepNo = 5

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	WAVE/Z passingAdSweepsFailSet = JWN_GetNumericWaveFromWaveNote(overrideResults, "PassingAdaptiveSweepFromFailingSet")

	CHECK_EQUAL_WAVES(passingAdSweepsFailSet, {0, 2}, mode = WAVE_DATA)

	PGC_SetAndActivateControl(str, "DataAcquireButton")
	RegisterReentryFunction("PatchSeqTestDAScaleAdapt#" + GetRTStackInfo(1))
End

static Function PS_DS_AD1a_REENTRY_REENTRY_REENTRY([string str])

	variable sweepNo

	sweepNo = 8

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	WAVE/Z passingAdSweepsFailSet = JWN_GetNumericWaveFromWaveNote(overrideResults, "PassingAdaptiveSweepFromFailingSet")

	CHECK_EQUAL_WAVES(passingAdSweepsFailSet, {0, 2, 3, 5}, mode = WAVE_DATA)

	PGC_SetAndActivateControl(str, "DataAcquireButton")
	RegisterReentryFunction("PatchSeqTestDAScaleAdapt#" + GetRTStackInfo(1))
End

static Function PS_DS_AD1a_REENTRY_REENTRY_REENTRY_REENTRY([string str])

	variable sweepNo

	sweepNo = 9

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	WAVE/Z passingAdSweepsFailSet = JWN_GetNumericWaveFromWaveNote(overrideResults, "PassingAdaptiveSweepFromFailingSet")

	// "FailingAdaptiveSCIRange" equals two so we don't look further back
	CHECK_EQUAL_WAVES(passingAdSweepsFailSet, {3, 5, 6, 8}, mode = WAVE_DATA)
End

static Function PS_DS_AD2_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 1)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD2([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// all tests pass
	wv[][][%APFrequency] = 16.1
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
End

static Function PS_DS_AD2_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.125}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.375}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {300}
	Make/FREE/D fiSlopeRef = {10}
	Make/FREE/D fiOffsetRef = {15.59999999999999}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:5;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {100, 200, 300}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, 7, 4}
	Make/FREE/D DAScalesRef = {5}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%fiSlopeDAScale], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetDAScale], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%fiSlopesDAScaleFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsDAScaleFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_WAVE(entries[%oorDAScale], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD2a_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DAScaleNegativeSlopePercent", var = 10)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD2a([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// all tests pass
	wv[][][%APFrequency] = 16.1 + (0.5 * q) / (q + 1)
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
End

static Function PS_DS_AD2a_REENTRY([string str])

	variable sweepNo

	sweepNo = 1

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.125, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.375, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {300, 300}
	Make/FREE/D fiSlopeRef = {10, 3.571428571428571}
	Make/FREE/D fiOffsetRef = {15.59999999999999, 15.92142857142857}
	Make/FREE/D fiSlopeDAScaleRef = {10, 3.571428571428571}
	Make/FREE/D fiOffsetDAScaleRef = {15.59999999999999, 15.92142857142857}

	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:5;Reg:12;", "RegRhSuAd:5;Reg:12;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {100, 200, 300}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, 7, 4}
	Make/FREE/D DAScalesRef = {5, 12}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%fiSlopeDAScale], fiSlopeDAScaleRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetDAScale], fiOffsetDAScaleRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%fiSlopesDAScaleFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsDAScaleFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD2b_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 1.5)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DAScaleNegativeSlopePercent", var = 10)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD2b([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// all tests pass
	wv[][][%APFrequency] = 16.1 - 1 * q
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
End

static Function PS_DS_AD2b_REENTRY([string str])

	variable sweepNo

	sweepNo = 1

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.125, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.1875, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {300, 300}
	Make/FREE/D fiSlopeRef = {10, -25}
	Make/FREE/D fiOffsetRef = {15.59999999999999, 17.35}
	Make/FREE/D fiSlopeDAScaleRef = {10, 10}
	Make/FREE/D fiOffsetDAScaleRef = {15.59999999999999, 15.59999999999999}
	// no fillin for negative slope because the DAScale was already acquired
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:5;Reg:9;", "RegRhSuAd:5;Reg:9;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {100, 200, 300}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, 7, 4}
	Make/FREE/D DAScalesRef = {5, 9}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%fiSlopeDAScale], fiSlopeDAScaleRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetDAScale], fiOffsetDAScaleRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%fiSlopesDAScaleFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsDAScaleFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD3_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD3([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// 0: BL fails
	// 1-2: sweep QC passes and fiSlope reached
	wv[][][%APFrequency]  = 16.1 + (0.5 * q) / (q + 1)
	wv[][][%AsyncQC]      = 1
	wv[][1,][%BaselineQC] = 1
End

static Function PS_DS_AD3_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {0, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {NaN, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {1, 0, 1}, mode = WAVE_DATA)
	// first sweep fails, so we redo the fit with only the supra data and that
	// does not result in fit slope reached QC
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.125, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.375, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {300, 300, 300}
	Make/FREE/D fiSlopeRef = {NaN, 35.00000000000014, 1.190476190476152}
	Make/FREE/D fiOffsetRef = {NaN, 14.59999999999999, 16.29047619047619}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:5;", "RegRhSuAd:5;Reg:12;", "RegRhSuAd:5;Reg:12;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {100, 200, 300}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, 7, 4}
	Make/FREE/D DAScalesRef = {5, 5, 12}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD4_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	Make/O/N=0 root:overrideResults

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD4([string str])

	variable ref, sweepNo
	string historyText

	ref = CaptureHistoryStart()

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	historyText = CaptureHistory(ref, 1)
	CHECK_GE_VAR(strsearch(historyText, "Could not find a passing set QC from previous DAScale runs in \"Supra\" mode.", 1), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function PS_DS_AD4a_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	Make/O/N=0 root:overrideResults

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD4a([string str])

	variable ref, sweepNo
	string historyText

	ref = CaptureHistoryStart()

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	historyText = CaptureHistory(ref, 1)
	CHECK_GE_VAR(strsearch(historyText, "Could not find a passing set QC from previous Rheobase runs.", 1), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function PS_DS_AD5_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4})

	Make/FREE/D DAScalesFromRhSuAd = {1}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD5([string str])

	variable ref, sweepNo
	string historyText

	ref = CaptureHistoryStart()

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	historyText = CaptureHistory(ref, 1)
	CHECK_GE_VAR(strsearch(historyText, "The f-I fit of the rheobase/supra data failed due to: \"Not enough points for fit\"", 1), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function PS_DS_AD6_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 1)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	// NaN f-I slope QC in RhSuAd data
	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 3}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 15}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD6([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// all tests pass
	wv[][][%APFrequency] = 7 - 5 * q
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
End

static Function PS_DS_AD6_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.1195652173913044}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.3586956521739131}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {200}
	Make/FREE/D fiSlopeRef = {-266.6666666666666}
	Make/FREE/D fiOffsetRef = {23}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:6;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {100, 200, NaN}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, 7, NaN}
	Make/FREE/D DAScalesRef = {6}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_WAVE(entries[%oorDAScale], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD7_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 1)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 1.1)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 10)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {10, 20, 30, 30}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	// not dense enough
	Make/FREE/D apFrequenciesFromRhSuAd = {5, 8, 13, 15}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD7([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// all tests pass and 6.5 is somewhere between 5 and 8
	wv[][][%APFrequency] = 6.5 + (0.5 * q) / (q + 1)
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
End

static Function PS_DS_AD7_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {1, 1, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.2156862745098039, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.2372549019607843, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {50, 50, 50}
	Make/FREE/D fiSlopeRef = {30, -25, -204.1666666666667}
	Make/FREE/D fiOffsetRef = {2, 13, 76.25000000000001}
	Make/FREE/T futureDAScalesRef = {"FillinRhSuAd:15;FillinRhSuAd:25;RegRhSuAd:34;", \
	                                 "FillinRhSuAd:15;FillinRhSuAd:25;RegRhSuAd:34;", \
	                                 "FillinRhSuAd:15;FillinRhSuAd:25;RegRhSuAd:34;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {30, 50, NaN}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {2, -2, NaN}
	Make/FREE/D DAScalesRef = {15, 25, 34}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD8_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 1)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5})

	Make/FREE/D DAScalesFromRhSuAd = {1, 1}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD8([string str])

	variable ref, sweepNo
	string historyText

	ref = CaptureHistoryStart()

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	historyText = CaptureHistory(ref, 1)
	CHECK_GE_VAR(strsearch(historyText, "The f-I fit of the rheobase/supra data failed due to: \"All fit results are NaN\"", 1), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function PS_DS_AD10_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 1.2)

	// SamplingMultiplier, SamplingFrequency use defaults

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {10, 20, 30, 40}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD10([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// not dense enough and we are running out of sweeps
	wv[][][%APFrequency] = 25 + 15 * q
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
End

static Function PS_DS_AD10_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {1, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {1.2, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {90, 300, 750}
	Make/FREE/D fiSlopeRef = {90, 300, 750}
	Make/FREE/D fiOffsetRef = {-20, -125, -372.5}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:50;Reg:55;", "RegRhSuAd:50;Reg:55;Reg:57;", "RegRhSuAd:50;Reg:55;Reg:57;Reg:58;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {10, 20, 30}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, 7, 4}
	Make/FREE/D DAScalesRef = {50, 55, 57}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD12_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	ST_SetStimsetParameter("PSQ_DaScale_Adapt_DA_0", "Total number of steps", var = 7)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 1.1)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 1.5, 2.5, 3.5}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 14}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD12([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	wv[][0][%APFrequency] = 25   // sweep passes at DAScale 7
	wv[][1][%APFrequency] = 21   // future DAScale (9) but BL fails
	wv[][2][%APFrequency] = 21   // redoing future DAScale (9), passed f-I neg slope QC (1.)
	wv[][3][%APFrequency] = 21.1 // no slope QC passing
	wv[][4][%APFrequency] = 15   // fillin again (6)
	wv[][5][%APFrequency] = 10   // passed f-I neg slope (2.)

	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
	wv[][1][%BaselineQC] = 0
End

static Function PS_DS_AD12_REENTRY([string str])

	variable sweepNo

	sweepNo = 5

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 0, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 0, 1, 1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 0, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, NaN, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 0, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0, 0, 1, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0, 1, 0, 0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0, 0, 1, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0, 1, 0, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.1536458333333333, NaN, NaN, NaN, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.4609374999999999, NaN, NaN, NaN, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {314.2857142857143, 314.2857142857143, 314.2857142857143, 314.2857142857143, 314.2857142857143, 314.2857142857143}
	Make/FREE/D fiSlopeRef = {314.2857142857143, 314.2857142857143, -200, 284, -120, -1500}
	Make/FREE/D fiOffsetRef = {3, 3, 39, 4.060000000000002, 31.8, 130}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:7;Reg:9;",                                                \
	                                 "RegRhSuAd:7;Reg:9;",                                                \
	                                 "RegRhSuAd:7;Reg:9;Fillin:6;",                                       \
	                                 "RegRhSuAd:7;Reg:9;Fillin:6;RegPosNegSlope:14;",                     \
	                                 "RegRhSuAd:7;Reg:9;Fillin:6;RegPosNegSlope:14;FillinPosNegSlope:8;", \
	                                 "RegRhSuAd:7;Reg:9;Fillin:6;RegPosNegSlope:14;FillinPosNegSlope:8;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {200, 200, 100}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {8, 8, 10.5}
	Make/FREE/D DAScalesRef = {7, 9, 9, 6, 14, 8}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD13_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 0.5)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// SamplingMultiplier use defaults
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "SamplingFrequency", var = 10)

	// defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5})

	Make/FREE/D DAScalesFromRhSuAd = {1, 1.2}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {5, 15}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD13([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// all tests pass, but sampling interval check fails
	wv[][][%APFrequency] = 20
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
End

static Function PS_DS_AD13_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.005}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.015}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {4999.99999999999}
	Make/FREE/D fiSlopeRef = {-2500}
	Make/FREE/D fiOffsetRef = {45.00000000000023}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:1;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {4999.99999999999}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {-44.9999999999999}
	Make/FREE/D DAScalesRef = {1}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_WAVE(entries[%fiSlope], NULL_WAVE)
	CHECK_WAVE(entries[%fiOffset], NULL_WAVE)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_WAVE(entries[%oorDAScale], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD14_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 1)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	ST_SetStimsetParameter("PSQ_DaScale_Adapt_DA_0", "Total number of steps", var = 5)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 16}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD14([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// fit error on first sweep, passes on second sweep
	wv[][0][%APFrequency]  = NaN
	wv[][1,][%APFrequency] = 16.1 + (0.5 * q) / (q + 1)

	wv[][][%AsyncQC]    = 1
	wv[][][%BaselineQC] = 1
End

static Function PS_DS_AD14_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.125, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.375, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {300, NaN, 300}
	Make/FREE/D fiSlopeRef = {NaN, NaN, 4.166666666666608}
	Make/FREE/D fiOffsetRef = {NaN, NaN, 16.1}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:5;Fallback:6;",            \
	                                 "RegRhSuAd:5;Fallback:6;Fallback:8;", \
	                                 "RegRhSuAd:5;Fallback:6;Fallback:8;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {100, 200, 300}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, 7, 4}
	Make/FREE/D DAScalesRef = {5, 6, 8}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD15_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 2)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DAScaleRangeFactor", var = 2)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 5)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	// use constant input data
	Make/FREE/D apFrequenciesFromRhSuAd = {1, 1, 1, 1}

	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD15([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	wv[][][%APFrequency] = 5 // number of spikes
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
End

static Function PS_DS_AD15_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	// range of DAScalesFromRhSuAd times 2
	Make/FREE/D minDAScaleNormRef = {6}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {18}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {44.44444444444444}
	Make/FREE/D fiSlopeRef = {44.44444444444444}
	Make/FREE/D fiOffsetRef = {-0.7777777777777777}
	Make/FREE/T futureDAScalesRef = {"FinishedRhSuAd:13;Reg:43;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {0, 0, 0}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {1, 1, 1}
	Make/FREE/D DAScalesRef = {13}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_WAVE(entries[%oorDAScale], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD16_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 1.1)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 3)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	ST_SetStimsetParameter("PSQ_DaScale_Adapt_DA_0", "Total number of steps", var = 5)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 1.5, 2.5, 3.5}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 14}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD16([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	wv[][0][%APFrequency] = 14.2
	wv[][1][%APFrequency] = 14.3
	wv[][2][%APFrequency] = 14.4
	wv[][3][%APFrequency] = 14.5
	wv[][4][%APFrequency] = 14.6

	wv[][][%AsyncQC]           = 1
	wv[][][%BaselineQC]        = 1
	wv[1, Inf][0][%BaselineQC] = 0
	wv[1, Inf][1][%BaselineQC] = 0
	wv[1, Inf][3][%BaselineQC] = 0
End

static Function PS_DS_AD16_REENTRY([string str])

	variable sweepNo

	sweepNo = 4

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0, 0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 0, 1, 1, 1}, mode = WAVE_DATA)

	// we are querying chunk0
	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {0, 0, 1, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {1, 1, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0, 0, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, NaN, 1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.1536458333333333, NaN, NaN, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.4609374999999999, NaN, NaN, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {200, NaN, 200, 200, 200}
	Make/FREE/D fiSlopeRef = {NaN, NaN, 11.4285714285714, 11.4285714285714, 2.85714285714287}
	Make/FREE/D fiOffsetRef = {NaN, NaN, 13.6, 13.6, 14.2}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:7;", "RegRhSuAd:7;", "RegRhSuAd:7;Reg:14;", "RegRhSuAd:7;Reg:14;", "RegRhSuAd:7;Reg:14;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {200, 200, 100}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {8, 8, 10.5}
	Make/FREE/D DAScalesRef = {7, 7, 7, 14, 14}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD17_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 1.1)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {8})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7, 8})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 2.1, 2.2, 2.3}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11, 13, 14, 15}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD17([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	wv[][][%APFrequency] = 15
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 0
End

static Function PS_DS_AD17_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%rmsLongPass], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.07609890109890098}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.2282967032967029}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_WAVE(entries[%apfreq], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {2000}

	Make/FREE/D fiSlopesFromRhSuAdRef = {100, 2000, 1000, 1000}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9, -29.0000000000021, -7.99999999999741, -8.00000000000008}
	Make/FREE/T futureDAScalesRef = {"FinishedRhSuAd:4;"}
	Make/FREE/D DAScalesRef = {4}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_WAVE(entries[%fiSlope], NULL_WAVE)
	CHECK_WAVE(entries[%fiOffset], NULL_WAVE)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_WAVE(entries[%oorDAScale], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD18_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 1.1)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 3)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	ST_SetStimsetParameter("PSQ_DaScale_Adapt_DA_0", "Total number of steps", var = 1)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {8})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 11}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD18([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	wv[][][%APFrequency] = 15
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 0
End

static Function PS_DS_AD18_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {0}, mode = WAVE_DATA)
	CHECK_WAVE(entries[%rmsLongPass], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.25}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.75}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_WAVE(entries[%apfreq], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {100}
	Make/FREE/D fiSlopeRef = {1}
	Make/FREE/D fiOffsetRef = {1}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:5;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {100}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {9}
	Make/FREE/D DAScalesRef = {5}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_WAVE(entries[%fiSlope], NULL_WAVE)
	CHECK_WAVE(entries[%fiOffset], NULL_WAVE)
	CHECK_EQUAL_WAVES(entries[%futureDAScales], futureDAScalesRef)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_WAVE(entries[%oorDAScale], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD19_preAcq(string device)

	// use defaults

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {7})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1000, 1500, 2500, 3000}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD19([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	wv[][][%APFrequency] = 16 + p
	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
End

static Function PS_DS_AD19_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {142.8571428571429}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {428.5714285714286}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo)

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {2.097902097902098}
	Make/FREE/D fiSlopeRef = {2.097902097902098}
	Make/FREE/D fiOffsetRef = {-58.93706293706293}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:3572;Reg:5858;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {0.2, 0.1, 0.2}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {-1, 0.5, -2}
	Make/FREE/D DAScalesRef = {3572}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_TEXTWAVES(entries[%futureDAScales], futureDAScalesRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {1}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD20_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 1.1)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 3)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	ST_SetStimsetParameter("PSQ_DaScale_Adapt_DA_0", "Total number of steps", var = 2)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {8})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {10, 9}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD20([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	// fI neg slope in RhSuAd (1.)
	wv[][0][%APFrequency] = 8 // fI neg slope (2.), without pos/neg fillin as there is no positive fI slope

	wv[][][%AsyncQC]    = 1
	wv[][][%BaselineQC] = 1
End

static Function PS_DS_AD20_REENTRY([string str])

	variable sweepNo

	sweepNo = 0

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.25}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.75}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {-33.3333333333333}
	Make/FREE/D fiSlopeRef = {-33.3333333333333}
	Make/FREE/D fiOffsetRef = {9.666666666666666}
	Make/FREE/T futureDAScalesRef = {"RegPosNegSlopeRhSuAd:5;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {-100}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {11}
	Make/FREE/D DAScalesRef = {5}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%futureDAScales], futureDAScalesRef)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_WAVE(entries[%oorDAScale], NULL_WAVE)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD21_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 1.1)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 3)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {8})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5})

	Make/FREE/D DAScalesFromRhSuAd = {10, 20}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {40, 41}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD21([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	wv[][0][%APFrequency] = 39 // neg slope passing
	wv[][1][%APFrequency] = 5  // neg slope passing, triggers fillin
	wv[][2][%APFrequency] = 20 // fillin

	wv[][][%AsyncQC]     = 1
	wv[][][%BaselineQC]  = 1
	wv[][2][%BaselineQC] = 0 // fails for fillin
End

static Function PS_DS_AD21_REENTRY([string str])

	variable sweepNo

	sweepNo = 2

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 1, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, 1, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0, 0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {2.5, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {7.5, NaN, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {10, 10, 10}
	Make/FREE/D fiSlopeRef = {-2.127659574468085, -23.28767123287671, -23.28767123287671}
	Make/FREE/D fiOffsetRef = {41.42553191489362, 65.54794520547945, 65.54794520547945}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:114;RegPosNegSlope:260;",                      \
	                                 "RegRhSuAd:114;RegPosNegSlope:260;FillinPosNegSlope:15;", \
	                                 "RegRhSuAd:114;RegPosNegSlope:260;FillinPosNegSlope:15;"}

	Make/FREE/D fiSlopesFromRhSuAdRef = {10}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {39}
	Make/FREE/D DAScalesRef = {114, 260, 15}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%futureDAScales], futureDAScalesRef)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, 0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End

static Function PS_DS_AD22_preAcq(string device)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSLongThreshold", var = 0.5)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "BaselineRMSShortThreshold", var = 0.07)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AbsFrequencyMinDistance", var = 1.1)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "NumSweepsWithSaturation", var = 2)
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "DaScaleStepWidthMinMaxRatio", var = 3)

	// SamplingMultiplier, SamplingFrequency use defaults

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MaxFrequencyChangePercent", var = 25)

	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "MinimumSpikeCountForMaxSlope", var = 10)

	// use defaults for the rest

	Make/FREE asyncChannels = {2, 4}
	AFH_AddAnalysisParameter("PSQ_DaScale_Adapt_DA_0", "AsyncQCChannels", wv = asyncChannels)

	SetAsyncChannelProperties(device, asyncChannels, -1e6, +1e6)

	WAVE/Z overrideResults = GetOverrideResults()
	CHECK_WAVE(overrideResults, NUMERIC_WAVE)
	JWN_SetWaveInWaveNote(overrideResults, "PassingRheobaseSweep", {5})
	JWN_SetWaveInWaveNote(overrideResults, "PassingSupraSweep", {8})
	JWN_SetWaveInWaveNote(overrideResults, "PassingRhSuAdSweeps", {4, 5, 6, 7})

	Make/FREE/D DAScalesFromRhSuAd = {1, 2, 3, 4}
	JWN_SetWaveInWaveNote(overrideResults, "DAScalesRhSuAd", DAScalesFromRhSuAd)

	Make/FREE/D apFrequenciesFromRhSuAd = {0, 9, 10, 12}
	JWN_SetWaveInWaveNote(overrideResults, "APFrequenciesRhSuAd", apFrequenciesFromRhSuAd)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function PS_DS_AD22([string str])

	[STRUCT DAQSettings s] = PS_GetDAQSettings(str)
	AcquireData_NG(s, str)

	WAVE wv = PSQ_CreateOverrideResults(str, PSQ_TEST_HEADSTAGE, PSQ_DA_SCALE, opMode = PSQ_DS_ADAPT)

	wv[][0][%APFrequency] = 12.1
	wv[][1][%APFrequency] = 12.2

	wv[][][%AsyncQC]    = 1
	wv[][][%BaselineQC] = 1
End

static Function PS_DS_AD22_REENTRY([string str])

	variable sweepNo

	sweepNo = 1

	WAVE/WAVE entries = GetEntries_IGNORE(str, sweepNo)

	CHECK_EQUAL_TEXTWAVES(entries[%opMode], {PSQ_DS_ADAPT}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%setPass], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassExceptBL], {1, 1}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%rmsShortPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%rmsLongPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%baselinePass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%asyncPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%samplingPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPass], {0, 0}, mode = WAVE_DATA)

	CHECK_EQUAL_WAVES(entries[%futureDAScalesPass], {0, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopePass], {0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%enoughFIPointsPass], {1, 1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiSlopeReachedPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fiNegSlopesPassFromRhSuAd], {0, 0, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%fillinPassFromRhSuAd], {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/D minDAScaleNormRef = {0.06756756756756756, NaN}
	CHECK_EQUAL_WAVES(entries[%minDaScaleNorm], minDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	Make/FREE/D maxDAScaleNormRef = {0.2027027027027027, NaN}
	CHECK_EQUAL_WAVES(entries[%maxDaScaleNorm], maxDAScaleNormRef, mode = WAVE_DATA, tol = 1e-24)

	[WAVE apFreqRef, WAVE apFreqFromRhSuAd, WAVE DAScalesFromRhSuAd, WAVE sweepPassedFRomRhSuAd] = ExtractRefValuesFromOverride(sweepNo, baselineQC = entries[%baselinePass])

	CHECK_EQUAL_WAVES(entries[%apfreq], apFreqRef, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%apFreqFromRhSuAd], apFreqFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%dascaleFromRhSuAd], DAScalesFromRhSuAd, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(entries[%sweepPassFromRhSuAd], sweepPassedFRomRhSuAd, mode = WAVE_DATA)

	Make/FREE/D maxSlopeRef = {200, 200}
	Make/FREE/D fiSlopeRef = {9.99999999999997, 3.3333333333333}
	Make/FREE/D fiOffsetRef = {11.6, 11.9333333333333}
	Make/FREE/T futureDAScalesRef = {"RegRhSuAd:5;Reg:8;", \
	                                 "RegRhSuAd:5;Reg:8;"}
	Make/FREE/D fiSlopesFromRhSuAdRef = {900, 100, 200}
	Make/FREE/D fiOffsetsFromRhSuAdRef = {-9, 7, 4}
	Make/FREE/D DAScalesRef = {5, 8}

	CHECK_EQUAL_WAVES(entries[%maxSlope], maxSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiSlope], fiSlopeRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffset], fiOffsetRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%futureDAScales], futureDAScalesRef)
	CHECK_EQUAL_WAVES(entries[%fiSlopesFromRhSuAd], fiSlopesFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-6)
	CHECK_EQUAL_WAVES(entries[%fiOffsetsFromRhSuAd], fiOffsetsFromRhSuAdRef, mode = WAVE_DATA, tol = 1e-24)
	CHECK_EQUAL_WAVES(entries[%dascale], DAScalesRef, mode = WAVE_DATA, tol = 1e-24)

	CHECK_EQUAL_WAVES(entries[%oorDAScale], {0, NaN}, mode = WAVE_DATA)

	CommonAnalysisFunctionChecks(str, sweepNo, entries[%setPass])
	CheckSurveyPlot(str, entries)
End
