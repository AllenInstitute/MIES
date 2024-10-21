#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PSQ
#endif

/// @file MIES_AnalysisFunctions_PatchSeq.ipf
/// @brief __PSQ__ Analysis functions for patch sequence
///
/// The stimsets with the analysis functions attached are executed in the following order:
/// - PSQ_PipetteInBath `PB`
/// - PSQ_SealEvaluation `SE`
/// - PSQ_AccessResistanceSmoke `AR`
/// - PSQ_TrueRestingMembranePotential `VM`
/// - PSQ_DaScale (sub threshold) `DA (sub)`
/// - PSQ_SquarePulse (long pulse) `SP`
/// - PSQ_Rheobase (long pulse) `RB`
/// - PSQ_DaScale (supra threshold) `DA (supra)`
/// - PSQ_DaScale (adaptive threshold) `DA (adaptive)`
/// - PSQ_SquarePulse (short pulse) `SP`
/// - PSQ_Rheobase (short pulse) `RB`
/// - PSQ_Ramp `RA`
/// - PSQ_Chirp `CR`
///
/// See GetAbbreviationForAnalysisFunction() for a generating the abbreviation of each analysis function.
///
/// The Patch Seq analysis functions store various results in the labnotebook.
///
/// For orientation the following table shows their relation. All labnotebook
/// keys can and should be created via CreateAnaFuncLBNKey().
///
/// \rst
///
/// ========================================== ============================================================= ======== ============ ==================================== ============ ======================
///  Naming constant                            Description                                                   Unit     Labnotebook  Analysis function                    Per Chunk?   Headstage dependent?
/// ========================================== ============================================================= ======== ============ ==================================== ============ ======================
///  PSQ_FMT_LBN_SPIKE_DETECT                   The required number of spikes were detected on the sweep      On/Off   Numerical    SP, RB, RA, DA (Supra)               No           Yes
///  PSQ_FMT_LBN_SPIKE_POSITIONS                Spike positions                                               ms       Numerical    RA, VM                               No           Yes
///  PSQ_FMT_LBN_SPIKE_COUNT                    Spike count                                                   (none)   Numerical    DA (Supra)                           No           Yes
///  PSQ_FMT_LBN_STEPSIZE                       Current DAScale step size                                     (none)   Numerical    SP, RB                               No           No
///  PSQ_FMT_LBN_STEPSIZE_FUTURE                Future DAScale step size                                      (none)   Numerical    RB                                   No           No
///  PSQ_FMT_LBN_RB_DASCALE_EXC                 Range for valid DAScale values is exceeded                    On/Off   Numerical    RB                                   No           Yes
///  PSQ_FMT_LBN_DASCALE_OOR                    Future DAScale value is out of range                          On/Off   Numerical    CR,XXX                               Yes          Yes
///  PSQ_FMT_LBN_RB_LIMITED_RES                 Failed due to limited DAScale resolution                      On/Off   Numerical    RB                                   No           Yes
///  PSQ_FMT_LBN_FINAL_SCALE                    Final DAScale of the given headstage, only set on success     (none)   Numerical    SP, RB                               No           No
///  PSQ_FMT_LBN_SPIKE_DASCALE_ZERO             Sweep spiked with DAScale of 0                                On/Off   Numerical    SP                                   No           No
///  PSQ_FMT_LBN_INITIAL_SCALE                  Initial DAScale                                               (none)   Numerical    RB, CR                               No           No
///  PSQ_FMT_LBN_RMS_SHORT_PASS                 Short RMS baseline QC result                                  On/Off   Numerical    DA, RB, RA, CR, SE, VM, AR           Yes          Yes
///  PSQ_FMT_LBN_RMS_SHORT_THRESHOLD            Short RMS baseline threshold                                  V        Numerical    DA, RB, RA, CR, SE, VM, AR           No           Yes
///  PSQ_FMT_LBN_RMS_LONG_PASS                  Long RMS baseline QC result                                   On/Off   Numerical    DA, RB, RA, CR, SE, VM, AR           Yes          Yes
///  PSQ_FMT_LBN_RMS_LONG_THRESHOLD             Long RMS baseline threshold                                   V        Numerical    DA, RB, RA, CR, SE, VM, AR           No           Yes
///  PSQ_FMT_LBN_TARGETV                        Target voltage baseline                                       Volt     Numerical    DA, RB, RA, CR                       Yes          Yes
///  PSQ_FMT_LBN_TARGETV_PASS                   Target voltage baseline QC result                             On/Off   Numerical    DA, RB, RA, CR                       Yes          Yes
///  PSQ_FMT_LBN_TARGETV_THRESHOLD              Target voltage threshold                                      V        Numerical    DA, RB, RA, CR                       No           Yes
///  PSQ_FMT_LBN_LEAKCUR                        Leak current                                                  Amperes  Numerical    PB, VM, AR                           Yes          Yes
///  PSQ_FMT_LBN_LEAKCUR_PASS                   Leak current QC result                                        On/Off   Numerical    PB, VM, AR                           Yes          Yes
///  PSQ_FMT_LBN_AVERAGEV                       Average voltage                                               Volt     Numerical    VM                                   Yes          Yes
///  PSQ_FMT_LBN_CHUNK_PASS                     Which chunk passed/failed baseline QC                         On/Off   Numerical    DA, RB, RA, CR, PB, SE, VM, AR       Yes          Yes
///  PSQ_FMT_LBN_BL_QC_PASS                     Pass/fail state of the complete baseline                      On/Off   Numerical    DA, RB, RA, CR, PB, SE, VM, AR       No           Yes
///  PSQ_FMT_LBN_SWEEP_PASS                     Pass/fail state of the complete sweep                         On/Off   Numerical    DA, SP, RA, CR, PB, SE, VM, AR       No           No
///  PSQ_FMT_LBN_SET_PASS                       Pass/fail state of the complete set                           On/Off   Numerical    DA, RB, RA, SP, CR, PB, SE, VM, AR   No           No
///  PSQ_FMT_LBN_SAMPLING_PASS                  Pass/fail state of the sampling interval check                On/Off   Numerical    DA, RB, RA, SP, CR, PB, SE, VM, AR   No           No
///  PSQ_FMT_LBN_PULSE_DUR                      Pulse duration as determined experimentally                   ms       Numerical    RB, DA, CR                           No           Yes
///  PSQ_FMT_LBN_SPIKE_PASS                     Pass/fail state of the spike search (No spikes → Pass)        On/Off   Numerical    CR, VM                               No           Yes
///  PSQ_FMT_LBN_DA_fI_SLOPE                    Fitted slope in the f-I plot                                  % Hz/pA  Numerical    DA (Supra, Adapt)                    No           Yes
///  PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS       Fitted slope in the f-I plot exceeds target value             On/Off   Numerical    DA (Supra, Adapt)                    No           No
///  PSQ_FMT_LBN_DA_AT_FI_OFFSET                Fitted offset in the f-I plot                                 Hz       Numerical    DA (Adapt)                           No           Yes
///  PSQ_FMT_LBN_DA_AT_FREQ                     AP frequency                                                  Hz       Numerical    DA (Adapt)                           No           Yes
///  PSQ_FMT_LBN_DA_AT_RSA_FREQ                 AP frequencies from previous sweep reevaluation               Hz       Textual      DA (Adapt)                           No           Yes
///  PSQ_FMT_LBN_DA_AT_RSA_DASCALE              DAScale values from previous sweep reevaluation               (none)   Textual      DA (Adapt)                           No           Yes
///  PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES            Slopes in the f-I plot from previous sweep reevaluation       % Hz/pA  Textual      DA (Adapt)                           No           Yes
///  PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES_PASS       Slope QCs in the f-I plot from previous sweep reevaluation    On/Off   Textual      DA (Adapt)                           No           No
///  PSQ_FMT_LBN_DA_AT_RSA_VALID_SLOPE_PASS     Valid slope from f-I plot QC of supra sweep reevaluation      On/Off   Numerical    DA (Adapt)                           No           Yes
///  PSQ_FMT_LBN_SWEEP_PASS                     Pass/fail state from previous sweep reevaluation              On/Off   Numerical    DA (Adapt)                           No           No
///  PSQ_FMT_LBN_DA_AT_MAX_SLOPE                Maximum encountered f-I plot slope in the SCI                 % Hz/pA  Numerical    DA (Adapt)                           No           Yes
///  PSQ_FMT_LBN_DA_AT_VALID_SLOPE_PASS         Valid slope from f-I plot QC                                  On/Off   Numerical    DA (Adapt)                           No           Yes
///  PSQ_FMT_LBN_DA_AT_ENOUGH_FI_POINTS_PASS    Enough f-I pairs for line fit QC                              On/Off   Numerical    DA (Adapt)                           No           No
///  PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES          DAScale values left to acquire                                (none)   Textual      DA (Adapt)                           No           Yes
///  PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES_PASS     Measured all DAScale values                                   On/Off   Numerical    DA (Adapt)                           No           No
///  PSQ_FMT_LBN_DA_AT_MIN_DASCALE_NORM         Minimum DAScale step width (normalized)                       (none)   Numerical    DA (Adapt)                           No           No
///  PSQ_FMT_LBN_DA_AT_MAX_DASCALE_NORM         Maximum DAScale step width (normalized)                       (none)   Numerical    DA (Adapt)                           No           No
///  PSQ_FMT_LBN_DA_OPMODE                      Operation Mode: One of PSQ_DS_SUB/PSQ_DS_SUPRA/PSQ_DS_ADAPT   (none)   Textual      DA                                   No           No
///  PSQ_FMT_LBN_CR_INSIDE_BOUNDS               AD response is inside the given bands                         On/Off   Numerical    CR                                   No           No
///  PSQ_FMT_LBN_CR_RESISTANCE                  Calculated resistance from DAScale sub threshold              Ohm      Numerical    CR                                   No           No
///  PSQ_FMT_LBN_CR_BOUNDS_ACTION               Action according to min/max positions                         (none)   Numerical    CR                                   No           No
///  PSQ_FMT_LBN_CR_BOUNDS_STATE                Upper and Lower bounds state according to min/max pos.        (none)   Textual      CR                                   No           No
///  PSQ_FMT_LBN_CR_SPIKE_CHECK                 Spike check was enabled/disabled                              (none)   Numerical    CR                                   No           No
///  PSQ_FMT_LBN_CR_INIT_UOD                    Initial user onset delay                                      ms       Numerical    CR                                   No           No
///  PSQ_FMT_LBN_CR_INIT_LPF                    Initial MCC low pass filter                                   Hz       Numerical    CR                                   No           No
///  PSQ_FMT_LBN_CR_STIMSET_QC                  Stimset valid/invalid QC state                                On/Off   Numerical    CR                                   No           No
///  FMT_LBN_ANA_FUNC_VERSION                   Integer version of the analysis function                      (none)   Numerical    All                                  No           Yes
///  PSQ_FMT_LBN_PB_RESISTANCE                  Pipette Resistance                                            Ohm      Numerical    PB                                   No           No
///  PSQ_FMT_LBN_PB_RESISTANCE_PASS             Pipette Resistance QC                                         On/Off   Numerical    PB                                   No           No
///  PSQ_FMT_LBN_SE_TP_GROUP_SEL                Selected Testpulse groups: One of Both/First/Second           (none)   Textual      SE                                   No           No
///  PSQ_FMT_LBN_SE_RESISTANCE_A                Seal Resistance of TPs in group A                             Ω        Numerical    SE                                   No           No
///  PSQ_FMT_LBN_SE_RESISTANCE_B                Seal Resistance of TPs in group B                             Ω        Numerical    SE                                   No           No
///  PSQ_FMT_LBN_SE_RESISTANCE_MAX              Maximum Seal Resistance of TPs in both groups                 Ω        Numerical    SE                                   No           No
///  PSQ_FMT_LBN_SE_RESISTANCE_PASS             Seal Resistance QC                                            On/Off   Numerical    SE                                   No           No
///  PSQ_FMT_LBN_VM_FULL_AVG                    Average voltage of all baseline chunks                        Volt     Numerical    VM                                   No           No
///  PSQ_FMT_LBN_VM_FULL_AVG_ADIFF              Average voltage absolute difference                           Volt     Numerical    VM                                   No           No
///  PSQ_FMT_LBN_VM_FULL_AVG_ADIFF_PASS         Average voltage absolute difference QC                        On/Off   Numerical    VM                                   No           No
///  PSQ_FMT_LBN_VM_FULL_AVG_RDIFF              Average voltage relative difference                           (none)   Numerical    VM                                   No           No
///  PSQ_FMT_LBN_VM_FULL_AVG_RDIFF_PASS         Average voltage relative difference QC                        On/Off   Numerical    VM                                   No           No
///  PSQ_FMT_LBN_VM_FULL_AVG_PASS               Full average voltage QC result                                On/Off   Numerical    VM                                   No           No
///  PSQ_FMT_LBN_AR_ACCESS_RESISTANCE           Access resistance of all TPs in the stimset                   Ω        Numerical    AR                                   No           No
///  PSQ_FMT_LBN_AR_ACCESS_RESISTANCE_PASS      Access resistance QC                                          On/Off   Numerical    AR                                   No           No
///  PSQ_FMT_LBN_AR_STEADY_STATE_RESISTANCE     Steady state resistance of all TPs in the stimset             Ω        Numerical    AR                                   No           No
///  PSQ_FMT_LBN_AR_RESISTANCE_RATIO            Ratio of access resistance to steady state                    (none)   Numerical    AR                                   No           No
///  PSQ_FMT_LBN_AR_RESISTANCE_RATIO_PASS       Ratio of access resistance to steady state QC                 On/Off   Numerical    AR                                   No           No
///  PSQ_FMT_LBN_ASYNC_PASS                     Combined alarm state of all async channels                    On/Off   Numerical    All                                  No           No
///  LBN_DELTA_I                                Delta current in pulse                                        Amperes  Numerical    RV, AD, DA (Sub)                     No           Yes
///  LBN_DELTA_V                                Delta voltage in pulse                                        Volts    Numerical    RV, AD, DA (Sub)                     No           Yes
///  LBN_RESISTANCE_FIT                         Fitted resistance from pulse                                  Ohm      Numerical    RV, AD, DA (Sub)                     No           Yes
///  LBN_RESISTANCE_FIT_ERR                     Error of fitted resistance from pulse                         Ohm      Numerical    RV, AD, DA (Sub)                     No           Yes
///  LBN_AUTOBIAS_TARGET_DIAG                   Autobias target voltage from dialog                           mV       Numerical    RV                                   No           Yes
/// ========================================== ============================================================= ======== ============ ==================================== ============ ======================
///
/// Query the standard STIMSET_SCALE_FACTOR_KEY entry from labnotebook for getting the DAScale.
///
/// \endrst
///
/// The following table lists the user epochs which are added during data acquisition:
///
/// \rst
///
/// ========================================================== ========== =========================== ========================================================== =======
/// Tags                                                       Short Name Analysis function           Description                                                Level
/// ========================================================== ========== =========================== ========================================================== =======
/// Name=Baseline Chunk;Index=x                                U_BLCx     DA, RB, RA, CR, SE, VM, AR  Baseline QC evaluation chunks                               -1
/// Name=Baseline Chunk QC Selection;Index=x                   U_BLSx     SE, VM, AR                  Selects the chunk for Baseline QC evaluation                -1
/// Name=DA Suppression                                        U_RA_DS    RA                          DA was suppressed in this time interval                     -1
/// Name=Unacquired DA data                                    U_RA_UD    RA                          Interval of unacquired data                                 -1
/// Type=Testpulse Like;Index=x                                U_TPx      PB, SE, AR                  Testpulse like region in stimset                            -1
/// Type=Testpulse Like;SubType=Baseline;Index=x               U_TPx_B0   PB, SE, AR                  Pre pulse baseline of testpulse                             -1
/// Type=Testpulse Like;SubType=Pulse;Amplitude=y;Index=x      U_TPx_P    PB, SE, AR                  Pulse of testpulse                                          -1
/// Type=Testpulse Like;SubType=Baseline;Index=x               U_TPx_B1   PB, SE, AR                  Post pulse baseline of testpulse                            -1
/// Type=Chirp Cycle Evaluation                                U_CR_CE    CR                          Evaluation chunk for bounds state                           -1
/// Type=Chirp Spike Evaluation                                U_CR_SE    CR                          Evaluation chunk for spike check                            -1
/// ========================================================== ========== =========================== ========================================================== =======
///
/// The tag entry ``Index=x`` is a zero-based index, which tracks how often the specific type of user epoch appears. So for different
/// epoch types duplicated index entries are to be expected.
///
/// See also :ref:`epoch_time_specialities`.
/// \endrst
///
/// Textual results entries stored by the sweep formula `store` operation with the names `Sweep Formula store [XXX]`:
///
/// \rst
///
/// .. List of names generated via `git grep -hPiIo '(?U)\bstore\(\\"\K.*(?=\\")' MIES_AnalysisFunctions_*`
///
/// ==================================== ==================
/// Name                                 Analysis function
/// ==================================== ==================
/// Steady state resistance              PB
/// Steady state resistance (group A)    PB
/// Steady state resistance (group B)    PB
/// Average U_BLS0                       VM
/// Average U_BLS1                       VM
/// Steady state resistance              AR
/// Peak resistance                      AR
/// ==================================== ==================
///
/// \endrst

static Constant PSQ_BL_PRE_PULSE  = 0x0
static Constant PSQ_BL_POST_PULSE = 0x1
static Constant PSQ_BL_GENERIC    = 0x2

static Constant PSQ_RMS_SHORT_TEST = 0x0
static Constant PSQ_RMS_LONG_TEST  = 0x1
static Constant PSQ_TARGETV_TEST   = 0x2
static Constant PSQ_LEAKCUR_TEST   = 0x3

static Constant PSQ_DEFAULT_SAMPLING_MULTIPLIER = 4

static Constant PSQ_RHEOBASE_DURATION = 500

static Constant PSQ_DA_FALLBACK_DASCALE_RANGE_FAC = 1.5

/// @name Type constants for PSQ_DS_GetLabnotebookData
/// @anchor PSQDAScaleAdaptiveLBNTypeConstants
///@{
static Constant PSQ_DS_FI_SLOPE              = 0x1
static Constant PSQ_DS_FI_SLOPE_REACHED_PASS = 0x2
static Constant PSQ_DS_FI_OFFSET             = 0x3
static Constant PSQ_DS_SWEEP_PASS            = 0x4
static Constant PSQ_DS_SWEEP                 = 0x5
static Constant PSQ_DS_APFREQ                = 0x6
static Constant PSQ_DS_DASCALE               = 0x7
///@}

/// @brief Fills `s` according to the analysis function type
Function PSQ_GetPulseSettingsForType(type, s)
	variable                  type
	STRUCT PSQ_PulseSettings &s

	string msg

	s.usesBaselineChunkEpochs = 0

	switch(type)
		case PSQ_DA_SCALE:
			s.prePulseChunkLength  = PSQ_BL_EVAL_RANGE
			s.postPulseChunkLength = PSQ_BL_EVAL_RANGE
			s.pulseDuration        = NaN
			break
		case PSQ_RHEOBASE:
		case PSQ_RAMP:
		case PSQ_CHIRP: // fallthrough-by-design
			s.prePulseChunkLength  = PSQ_BL_EVAL_RANGE
			s.postPulseChunkLength = PSQ_BL_EVAL_RANGE
			s.pulseDuration        = NaN
			break
		case PSQ_PIPETTE_BATH:
			s.prePulseChunkLength  = PSQ_BL_EVAL_RANGE
			s.postPulseChunkLength = NaN
			s.pulseDuration        = NaN
			break
		case PSQ_SEAL_EVALUATION:
		case PSQ_TRUE_REST_VM:
		case PSQ_ACC_RES_SMOKE: // fallthrough-by-design
			s.prePulseChunkLength     = NaN
			s.postPulseChunkLength    = NaN
			s.pulseDuration           = NaN
			s.usesBaselineChunkEpochs = 1
			break
		default:
			ASSERT(0, "unsupported type")
			break
	endswitch

	sprintf msg, "postPulseChunkLength %d, prePulseChunkLength %d, pulseDuration %g, usesBaselineChunkEpochs %g", s.postPulseChunkLength, s.prePulseChunkLength, s.pulseDuration, s.usesBaselineChunkEpochs
	DEBUGPRINT(msg)
End

/// Return the pulse durations from the labnotebook or calculate them before if required in ms.
/// For convenience unused headstages will have 0 instead of NaN in the returned wave.
///
/// We recalculate the durations on every sweep again as we can not assume that
/// it is constant for the whole stimulus set.
static Function/WAVE PSQ_GetPulseDurations(device, type, sweepNo, totalOnsetDelay, [forceRecalculation])
	string device
	variable type, sweepNo, totalOnsetDelay, forceRecalculation

	string key

	if(ParamIsDefault(forceRecalculation))
		forceRecalculation = 0
	else
		forceRecalculation = !!forceRecalculation
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_PULSE_DUR, query = 1)
	WAVE/Z durations = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(!WaveExists(durations) || forceRecalculation)
		WAVE durations = PSQ_DeterminePulseDuration(device, sweepNo, type, totalOnsetDelay)

		key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_PULSE_DUR)
		ED_AddEntryToLabnotebook(device, key, durations, unit = "ms", overrideSweepNo = sweepNo)
	endif

	durations[] = IsNaN(durations[p]) ? 0 : durations[p]

	return durations
End

/// @brief Determine the pulse duration on each headstage
///
/// Returns the labnotebook wave as well.
static Function/WAVE PSQ_DeterminePulseDuration(device, sweepNo, type, totalOnsetDelay)
	string device
	variable sweepNo, type, totalOnsetDelay

	variable i

	WAVE/Z sweepWave = GetSweepWave(device, sweepNo)

	if(!WaveExists(sweepWave))
		WAVE sweepWave = GetScaledDataWave(device)
		WAVE config    = GetDAQConfigWave(device)
	else
		WAVE config = GetConfigWave(sweepWave)
	endif

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	Make/FREE/WAVE/N=(NUM_HEADSTAGES) allSingleDA

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		allSingleDA[i] = AFH_ExtractOneDimDataFromSweep(device, sweepWave, i, XOP_CHANNEL_TYPE_DAC, config = config)
	endfor

	WAVE durations = PSQ_DeterminePulseDurationFinder(statusHS, allSingleDA, type, totalOnsetDelay)

	return durations
End

Function/WAVE PSQ_DeterminePulseDurationFinder(WAVE statusHS, WAVE/WAVE allSingleDA, variable type, variable totalOnsetDelay)

	variable i, first, last, level, duration

	WAVE durations = LBN_GetNumericWave()
	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		WAVE singleDA = allSingleDA[i]

		if(type == PSQ_CHIRP)
			// search something above/below zero from front and back
			FindLevel/Q/R=(totalOnsetDelay, Inf) singleDA, 0
			ASSERT(!V_Flag, "Could not find an edge")
			first = V_LevelX

			FindLevel/Q/R=(Inf, totalOnsetDelay) singleDA, 0
			ASSERT(!V_Flag, "Could not find an edge")
			last = V_LevelX
		else
			level = WaveMin(singleDA, totalOnsetDelay, Inf) + GetMachineEpsilon(WaveType(singleDA))

			// search a square pulse
			FindLevel/Q/R=(totalOnsetDelay, Inf)/EDGE=1 singleDA, level
			ASSERT(!V_Flag, "Could not find a rising edge")
			first = V_LevelX

			FindLevel/Q/R=(totalOnsetDelay, Inf)/EDGE=2 singleDA, level
			ASSERT(!V_Flag, "Could not find a falling edge")
			last = V_LevelX
		endif

		if(level > 0 || type == PSQ_CHIRP)
			duration = last - first - DimDelta(singleDA, ROWS)
		else
			duration = first - last + DimDelta(singleDA, ROWS)
		endif

		ASSERT(duration > 0, "Duration must be strictly positive")

		durations[i] = duration
	endfor

	return durations
End

/// @brief Return the baseline RMS short/long and target V thresholds in mV
static Function [variable rmsShortThreshold, variable rmsLongThreshold, variable targetVThreshold] PSQ_GetBaselineThresholds(string params)

	rmsShortThreshold = AFH_GetAnalysisParamNumerical("BaselineRMSShortThreshold", params, defValue = PSQ_RMS_SHORT_THRESHOLD)
	rmsLongThreshold  = AFH_GetAnalysisParamNumerical("BaselineRMSLongThreshold", params, defValue = PSQ_RMS_LONG_THRESHOLD)
	targetVThreshold  = AFH_GetAnalysisParamNumerical("BaselineTargetVThreshold", params, defValue = PSQ_TARGETV_THRESHOLD)

	return [rmsShortThreshold, rmsLongThreshold, targetVThreshold]
End

static Function PSQ_StoreThresholdsInLabnotebook(string device, variable type, variable sweepNo, variable headstage, variable rmsShortThreshold, variable rmsLongThreshold, variable targetVThreshold)
	string key

	WAVE values = LBN_GetNumericWave()

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_RMS_SHORT_THRESHOLD)
	// mV -> V
	values[headstage] = rmsShortThreshold * MILLI_TO_ONE
	ED_AddEntryToLabnotebook(device, key, values, unit = "V", overrideSweepNo = sweepNo)

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_RMS_LONG_THRESHOLD)
	// mV -> V
	values[headstage] = rmsLongThreshold * MILLI_TO_ONE
	ED_AddEntryToLabnotebook(device, key, values, unit = "V", overrideSweepNo = sweepNo)

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_TARGETV_THRESHOLD)
	// mV -> V
	values[headstage] = targetVThreshold * MILLI_TO_ONE
	ED_AddEntryToLabnotebook(device, key, values, unit = "V", overrideSweepNo = sweepNo)
End

static Function PSQ_EvaluateBaselinePassed(string device, variable type, variable sweepNo, variable headstage, variable chunk, variable ret)
	variable baselineQCPassed
	string key, msg

	baselineQCPassed = (ret == 0)

	sprintf msg, "BL QC %s, last evaluated chunk %d returned with %g\r", ToPassFail(baselineQCPassed), chunk, ret
	DEBUGPRINT(msg)

	// document BL QC results
	WAVE result = LBN_GetNumericWave()
	result[headstage] = baselineQCPassed

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_BL_QC_PASS)
	ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	return baselineQCPassed ? ANALYSIS_FUNC_RET_EARLY_STOP : ret
End

static Function [variable ret, variable chunk] PSQ_EvaluateBaselineChunks(string device, variable type, STRUCT AnalysisFunction_V3 &s)

	variable numBaselineChunks, i, totalOnsetDelay, fifoInStimsetTime

	numBaselineChunks = PSQ_GetNumberOfChunks(device, s.sweepNo, s.headstage, type, s.sampleIntervalDA)

	if(type == PSQ_CHIRP)
		ASSERT(numBaselineChunks >= 3, "Unexpected number of baseline chunks")
	elseif(type == PSQ_PIPETTE_BATH || type == PSQ_TRUE_REST_VM || type == PSQ_ACC_RES_SMOKE)
		ASSERT(numBaselineChunks == 1, "Unexpected number of baseline chunks")
	endif

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)

	fifoInStimsetTime = AFH_GetFifoInStimsetTime(device, s)

	for(i = 0; i < numBaselineChunks; i += 1)

		ret = PSQ_EvaluateBaselineProperties(device, s, type, i, fifoInStimsetTime, totalOnsetDelay)

		if(type == PSQ_SEAL_EVALUATION)
			ASSERT(IsFinite(ret), "Unexpected unfinished baseline chunk")

			continue
		endif

		if(IsNaN(ret))
			// NaN: not enough data for check

			// last chunk was only partially present and so can never pass
			if(i == numBaselineChunks - 1 && s.lastKnownRowIndexAD == s.lastValidRowIndexAD)
				ret = PSQ_BL_FAILED
			endif

			break
		elseif(ret)
			// != 0: failed with special mid sweep return value (on first failure) or PSQ_BL_FAILED
			if(type == PSQ_TRUE_REST_VM || type == PSQ_ACC_RES_SMOKE)
				// every failed chunk is fatal
				break
			elseif(i == 0)
				// pre pulse baseline
				// fail sweep
				break
			else
				// post pulse baseline
				// try next chunk
				continue
			endif
		else
			// 0: passed
			if(i == 0)
				// pre pulse baseline
				// try next chunks, or for PSQ_PIPETTE_BATH/PSQ_TRUE_REST_VM/PSQ_ACC_RES_SMOKE we are done
				continue
			else
				// post baseline
				// we're done!
				break
			endif
		endif
	endfor

	return [ret, i]
End

/// @brief Calculates the baseline chunk times
Function [variable chunkStartTimeMax, variable chunkLengthTime] PSQ_GetBaselineChunkTimes(variable chunk, STRUCT PSQ_PulseSettings &ps, variable totalOnsetDelayMS, WAVE/Z durations)

	ASSERT(!chunk || (chunk && WaveExists(durations)), "Need durations wave")
	chunkLengthTime = chunk ? ps.postPulseChunkLength : ps.prePulseChunkLength
	// for chunk > 0: skip onset delay, the pulse itself and one chunk of post pulse baseline
	chunkStartTimeMax = chunk ? (totalOnsetDelayMS + ps.prePulseChunkLength + WaveMax(durations)) + chunk * ps.postPulseChunkLength : totalOnsetDelayMS

	return [chunkStartTimeMax, chunkLengthTime]
End

/// @brief Evaluate one chunk of the baseline
///
/// @param device        device
/// @param s                 AnalysisFunction_V3 struct
/// @param type              analysis function type, one of @ref PatchSeqAnalysisFunctionTypes
/// @param chunk             chunk number, `chunk == 0` -> Pre pulse baseline chunk, `chunk >= 1` -> Post pulse baseline
///                          for traditional baseline evaluation if PSQ_PulseSettings#usesBaselineChunkEpochs is false.
/// @param fifoInStimsetTime Fifo position in ms *relative* to the start of the stimset (therefore ignoring the totalOnsetDelay)
/// @param totalOnsetDelay   total onset delay in ms
///
/// @return
/// pre pulse baseline: 0 if the chunk passes, one of the possible @ref AnalysisFuncReturnTypesConstants values otherwise
/// post pulse baseline: 0 if the chunk passes, PSQ_BL_FAILED if it does not pass
/// generic baseline: 0 if the chunk passes, PSQ_BL_FAILED if it does not pass
static Function PSQ_EvaluateBaselineProperties(string device, STRUCT AnalysisFunction_V3 &s, variable type, variable chunk, variable fifoInStimsetTime, variable totalOnsetDelay)

	variable headstage, evalStartTime, evalRangeTime
	variable i, DAC, ADC, ADcol, chunkStartTimeMax, chunkStartTime
	variable targetV, index
	variable rmsShortPassedAll, rmsLongPassedAll, chunkPassed
	variable targetVPassedAll, baselineType, chunkLengthTime
	variable leakCurPassedAll, maxLeakCurrent, targetVThreshold
	variable rmsShortThreshold, rmsLongThreshold
	variable chunkPassedRMSShortOverride, chunkPassedRMSLongOverride, chunkPassedTargetVOverride, chunkPassedLeakCurOverride
	string msg, adUnit, ctrl, key

	STRUCT PSQ_PulseSettings ps
	PSQ_GetPulseSettingsForType(type, ps)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	if(!ps.usesBaselineChunkEpochs)
		if(chunk)
			// post pulse baseline
			ASSERT(type != PSQ_PIPETTE_BATH, "Unexpected analysis function")

			if(type == PSQ_DA_SCALE || type == PSQ_RHEOBASE || type == PSQ_RAMP || type == PSQ_CHIRP)
				WAVE durations = PSQ_GetPulseDurations(device, type, s.sweepNo, totalOnsetDelay)
			else
				WAVE durations = LBN_GetNumericWave()
				durations = ps.pulseDuration
			endif
		endif
		[chunkStartTimeMax, chunkLengthTime] = PSQ_GetBaselineChunkTimes(chunk, ps, totalOnsetDelay, durations)
		baselineType = chunk ? PSQ_BL_POST_PULSE : PSQ_BL_PRE_PULSE
	else
		WAVE numericalValues = GetLBNumericalValues(device)
		WAVE textualValues   = GetLBTextualValues(device)

		if(type == PSQ_TRUE_REST_VM || type == PSQ_ACC_RES_SMOKE)
			WAVE epochsWave = GetEpochsWave(device)
		else
			// trick to use midSweep = 0 mode of EP_GetEpochs
			WAVE/ZZ epochsWave = $""
		endif

		ASSERT(Sum(statusHS) == 1, "Does only work with one active headstage")
		headstage = GetRowIndex(statusHS, val = 1)
		DAC       = AFH_GetDACFromHeadstage(device, headstage)
		ASSERT(IsFinite(DAC), "Non-finite DAC")

		WAVE/T/Z userChunkEpochs = EP_GetEpochs(numericalValues, textualValues, s.sweepNo, XOP_CHANNEL_TYPE_DAC, DAC, PSQ_BASELINE_SELECTION_SHORT_NAME_RE_MATCHER, treelevel = EPOCH_USER_LEVEL, epochsWave = epochsWave)
		ASSERT(WaveExists(userChunkEpochs), "Could not find baseline chunk selection user epochs")

		if(chunk >= DimSize(userChunkEpochs, ROWS))
			return PSQ_BL_FAILED
		endif

		// s -> ms
		chunkStartTimeMax = str2num(userChunkEpochs[chunk][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
		chunkLengthTime   = (str2num(userChunkEpochs[chunk][EPOCH_COL_ENDTIME]) - str2num(userChunkEpochs[chunk][EPOCH_COL_STARTTIME])) * ONE_TO_MILLI
		baselineType      = PSQ_BL_GENERIC
	endif

	// not enough data to evaluate
	if(fifoInStimsetTime + totalOnsetDelay < chunkStartTimeMax + chunkLengthTime)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	key         = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk, query = 1)
	chunkPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE, defValue = NaN)

	if(IsFinite(chunkPassed)) // already evaluated
		return !chunkPassed
	endif

	[rmsShortThreshold, rmsLongThreshold, targetVThreshold] = PSQ_GetBaselineThresholds(s.params)

	// Rows: baseline types
	// - 0: pre pulse
	// - 1: post pulse
	// - 2: generic
	//
	// Cols: checks
	// - 0: short RMS
	// - 1: long RMS
	// - 2: average voltage
	// - 3: leak current
	//
	// Contents:
	//  0: skip test
	//  1: perform test
	Make/FREE/N=(3, 4) testMatrix

	if(type == PSQ_ACC_RES_SMOKE)
		testMatrix[PSQ_BL_GENERIC][PSQ_RMS_SHORT_TEST] = 1
		testMatrix[PSQ_BL_GENERIC][PSQ_RMS_LONG_TEST]  = 1
		testMatrix[PSQ_BL_GENERIC][PSQ_LEAKCUR_TEST]   = 1

		maxLeakCurrent = AFH_GetAnalysisParamNumerical("MaxLeakCurrent", s.params)
	elseif(type == PSQ_PIPETTE_BATH)
		testMatrix[PSQ_BL_PRE_PULSE][PSQ_RMS_SHORT_TEST] = 1
		testMatrix[PSQ_BL_PRE_PULSE][PSQ_RMS_LONG_TEST]  = 1
		testMatrix[PSQ_BL_PRE_PULSE][PSQ_LEAKCUR_TEST]   = 1

		maxLeakCurrent = AFH_GetAnalysisParamNumerical("MaxLeakCurrent", s.params)
	elseif(type == PSQ_SEAL_EVALUATION)
		testMatrix[PSQ_BL_GENERIC][PSQ_RMS_SHORT_TEST] = 1
		testMatrix[PSQ_BL_GENERIC][PSQ_RMS_LONG_TEST]  = 1

		maxLeakCurrent = NaN
	elseif(type == PSQ_TRUE_REST_VM)
		ASSERT(chunk == 0, "Unexpected chunk")
		testMatrix[PSQ_BL_GENERIC][PSQ_RMS_SHORT_TEST] = 1
		testMatrix[PSQ_BL_GENERIC][PSQ_RMS_LONG_TEST]  = 1

		maxLeakCurrent = NaN
	else
		// pre pulse: all except leak current
		testMatrix[PSQ_BL_PRE_PULSE][PSQ_RMS_SHORT_TEST] = 1
		testMatrix[PSQ_BL_PRE_PULSE][PSQ_RMS_LONG_TEST]  = 1
		testMatrix[PSQ_BL_PRE_PULSE][PSQ_TARGETV_TEST]   = 1

		// post pulse: only targetV
		testMatrix[PSQ_BL_POST_PULSE][PSQ_TARGETV_TEST] = 1

		maxLeakCurrent = NaN
	endif

	sprintf msg, "We have some data to evaluate in chunk %d [%g, %g]:  %gms\r", chunk, chunkStartTimeMax, chunkStartTimeMax + chunkLengthTime, fifoInStimsetTime + totalOnsetDelay
	DEBUGPRINT(msg)

	WAVE config = GetDAQConfigWave(device)

	WAVE rmsShort       = LBN_GetNumericWave()
	WAVE rmsShortPassed = LBN_GetNumericWave()
	WAVE rmsLong        = LBN_GetNumericWave()
	WAVE rmsLongPassed  = LBN_GetNumericWave()
	WAVE avgVoltage     = LBN_GetNumericWave()
	WAVE targetVPassed  = LBN_GetNumericWave()
	WAVE avgCurrent     = LBN_GetNumericWave()
	WAVE leakCurPassed  = LBN_GetNumericWave()

	targetV = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

	// BEGIN TEST
	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		NVAR count           = $GetCount(device)
		chunkPassedRMSShortOverride = overrideResults[chunk][count][0][PSQ_RMS_SHORT_TEST]
		chunkPassedRMSLongOverride  = overrideResults[chunk][count][0][PSQ_RMS_LONG_TEST]
		chunkPassedTargetVOverride  = overrideResults[chunk][count][0][PSQ_TARGETV_TEST]
		chunkPassedLeakCurOverride  = overrideResults[chunk][count][0][PSQ_LEAKCUR_TEST]
	endif
	// END TEST

	WAVE/T epochWave = GetEpochsWave(device)
	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DAC = AFH_GetDACFromHeadstage(device, i)
		ASSERT(IsFinite(DAC), "Could not determine DAC channel number for HS " + num2istr(i) + " for device " + device)
		PSQ_AddBaselineEpoch(epochWave, DAC, chunk, chunkStartTimeMax, chunkLengthTime)

		if(chunk == 0)
			// store baseline RMS short/long tartget V analysis parameters in labnotebook on first use
			PSQ_StoreThresholdsInLabnotebook(device, type, s.sweepNo, i, rmsShortThreshold, rmsLongThreshold, targetVThreshold)
		endif

		switch(baselineType)
			case PSQ_BL_PRE_PULSE:
				chunkStartTime = totalOnsetDelay
				break
			case PSQ_BL_POST_PULSE:
				ASSERT(WaveExists(durations) && durations[i] != 0, "Invalid calculated durations")
				chunkStartTime = (totalOnsetDelay + ps.prePulseChunkLength + durations[i]) + chunk * ps.postPulseChunkLength
				break
			case PSQ_BL_GENERIC:
				chunkStartTime = chunkStartTimeMax
				break
			default:
				ASSERT(0, "Invalid baselineType")
		endswitch

		ADC = AFH_GetADCFromHeadstage(device, i)
		ASSERT(IsFinite(ADC), "This analysis function does not work with unassociated AD channels")
		ADcol = AFH_GetDAQDataColumn(config, ADC, XOP_CHANNEL_TYPE_ADC)

		ADunit = DAG_GetTextualValue(device, GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT), index = ADC)

		if(type == PSQ_PIPETTE_BATH || type == PSQ_SEAL_EVALUATION || type == PSQ_ACC_RES_SMOKE) // Vclamp
			ASSERT(!cmpstr(ADunit, "pA"), "Unexpected AD Unit")
		else // Iclamp
			ASSERT(!cmpstr(ADunit, "mV"), "Unexpected AD Unit")
		endif

		if(testMatrix[baselineType][PSQ_RMS_SHORT_TEST])

			evalStartTime = chunkStartTime + chunkLengthTime - 1.5
			evalRangeTime = 1.5

			// check 1: RMS of the last 1.5ms of the baseline should be below 0.07mV
			rmsShort[i] = PSQ_Calculate(s.scaledDACWave, ADCol, evalStartTime, evalRangeTime, PSQ_CALC_METHOD_RMS)

			if(TestOverrideActive())
				rmsShortPassed[i] = chunkPassedRMSShortOverride
			else
				rmsShortPassed[i] = rmsShort[i] < rmsShortThreshold
			endif

			sprintf msg, "RMS noise short: %g (%s)\r", rmsShort[i], ToPassFail(rmsShortPassed[i])
			DEBUGPRINT(msg)
		else
			sprintf msg, "RMS noise short: (%s)\r", "skipped"
			DEBUGPRINT(msg)
			rmsShortPassed[i] = -1
		endif

		if(!rmsShortPassed[i])
			continue
		endif

		if(testMatrix[baselineType][PSQ_RMS_LONG_TEST])

			evalStartTime = chunkStartTime
			evalRangeTime = chunkLengthTime

			// check 2: RMS of the last 500ms of the baseline should be below 0.50mV
			rmsLong[i] = PSQ_Calculate(s.scaledDACWave, ADCol, evalStartTime, evalRangeTime, PSQ_CALC_METHOD_RMS)

			if(TestOverrideActive())
				rmsLongPassed[i] = chunkPassedRMSLongOverride
			else
				rmsLongPassed[i] = rmsLong[i] < rmsLongThreshold
			endif

			sprintf msg, "RMS noise long: %g (%s)", rmsLong[i], ToPassFail(rmsLongPassed[i])
			DEBUGPRINT(msg)
		else
			sprintf msg, "RMS noise long: (%s)\r", "skipped"
			DEBUGPRINT(msg)
			rmsLongPassed[i] = -1
		endif

		if(!rmsLongPassed[i])
			continue
		endif

		if(testMatrix[baselineType][PSQ_TARGETV_TEST])

			evalStartTime = chunkStartTime
			evalRangeTime = chunkLengthTime

			// check 3: Average voltage within 1mV of auto bias target voltage
			avgVoltage[i] = PSQ_Calculate(s.scaledDACWave, ADCol, evalStartTime, evalRangeTime, PSQ_CALC_METHOD_AVG)

			if(TestOverrideActive())
				targetVPassed[i] = chunkPassedTargetVOverride
			else
				targetVPassed[i] = abs(avgVoltage[i] - targetV) <= targetVThreshold
			endif

			sprintf msg, "Average voltage of %gms: %g (%s)", evalRangeTime, avgVoltage[i], ToPassFail(targetVPassed[i])
			DEBUGPRINT(msg)
		else
			sprintf msg, "Average voltage: (%s)\r", "skipped"
			DEBUGPRINT(msg)
			targetVPassed[i] = -1
		endif

		if(!targetVPassed[i])
			continue
		endif

		if(testMatrix[baselineType][PSQ_LEAKCUR_TEST])
			ASSERT(!cmpstr(ADunit, "pA"), "Unexpected AD Unit")

			evalStartTime = chunkStartTime
			evalRangeTime = chunkLengthTime

			// check 3: leak current is smaller than MaxLeakCurrent
			avgCurrent[i] = PSQ_Calculate(s.scaledDACWave, ADCol, evalStartTime, evalRangeTime, PSQ_CALC_METHOD_AVG)

			if(TestOverrideActive())
				leakCurPassed[i] = chunkPassedLeakCurOverride
			else
				leakCurPassed[i] = abs(avgCurrent[i]) <= maxLeakCurrent
			endif

			sprintf msg, "Average leak current of %gms: %g (%s)", evalRangeTime, avgCurrent[i], ToPassFail(leakCurPassed[i])
			DEBUGPRINT(msg)
		else
			sprintf msg, "Average leak current: (%s)\r", "skipped"
			DEBUGPRINT(msg)
			leakCurPassed[i] = -1
		endif

		if(!leakCurPassed[i])
			continue
		endif

		// more tests can be added here
	endfor

	if(HasOneValidEntry(avgVoltage))
		// mV -> V
		avgVoltage[] *= MILLI_TO_ONE
		key           = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_TARGETV, chunk = chunk)
		ED_AddEntryToLabnotebook(device, key, avgVoltage, unit = "Volt", overrideSweepNo = s.sweepNo)
	endif

	if(HasOneValidEntry(avgCurrent))
		// pA -> A
		avgCurrent[] *= PICO_TO_ONE
		key           = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_LEAKCUR, chunk = chunk)
		ED_AddEntryToLabnotebook(device, key, avgCurrent, unit = "Amperes", overrideSweepNo = s.sweepNo)
	endif

	// document results per headstage and chunk
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(device, key, rmsShortPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(device, key, rmsLongPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_TARGETV_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(device, key, targetVPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)
	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(device, key, leakCurPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

	if(testMatrix[baselineType][PSQ_RMS_SHORT_TEST])
		rmsShortPassedAll = WaveMin(rmsShortPassed) == 1
	else
		rmsShortPassedAll = -1
	endif

	if(testMatrix[baselineType][PSQ_RMS_LONG_TEST])
		rmsLongPassedAll = WaveMin(rmsLongPassed) == 1
	else
		rmsLongPassedAll = -1
	endif

	if(testMatrix[baselineType][PSQ_TARGETV_TEST])
		targetVPassedAll = WaveMin(targetVPassed) == 1
	else
		targetVPassedAll = -1
	endif

	if(testMatrix[baselineType][PSQ_LEAKCUR_TEST])
		leakCurPassedAll = WaveMin(leakCurPassed) == 1
	else
		leakCurPassedAll = -1
	endif

	ASSERT(rmsShortPassedAll != -1 || rmsLongPassedAll != -1 || targetVPassedAll != -1 || leakCurPassedAll != -1, "Skipping all tests is not supported.")

	chunkPassed = rmsShortPassedAll && rmsLongPassedAll && targetVPassedAll && leakCurPassedAll

	sprintf msg, "Chunk %d %s", chunk, ToPassFail(chunkPassed)
	DEBUGPRINT(msg)

	// document chunk results
	WAVE result = LBN_GetNumericWave()
	result[INDEP_HEADSTAGE] = chunkPassed
	key                     = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk)
	ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

	if(baselineType == PSQ_BL_PRE_PULSE)
		if(!rmsShortPassedAll)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		elseif(!rmsLongPassedAll)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		elseif(!targetVPassedAll)
			if(type == PSQ_CHIRP)
				NVAR repurposedTime = $GetRepurposedSweepTime(device)
				repurposedTime = 6 - LeftOverSweepTime(device, fifoInStimsetTime + totalOnsetDelay)
			else
				NVAR repurposedTime = $GetRepurposedSweepTime(device)
				repurposedTime = 10
			endif

#ifdef AUTOMATED_TESTING
			repurposedTime = 0.5
#endif
			return ANALYSIS_FUNC_RET_REPURP_TIME
		elseif(!leakCurPassedAll)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		else
			ASSERT(chunkPassed, "logic error")
		endif
	elseif(baselineType == PSQ_BL_POST_PULSE || baselineType == PSQ_BL_GENERIC)
		if(chunkPassed)
			return 0
		else
			if(type == PSQ_ACC_RES_SMOKE)
				return ANALYSIS_FUNC_RET_EARLY_STOP
			else
				return PSQ_BL_FAILED
			endif
		endif
	else
		ASSERT(0, "unknown baseline type")
	endif
End

/// @brief Add base line epoch to user epochs
///
/// @param epochWave         4D epochs wave
/// @param DAC               DAC channel number
/// @param chunk             number of evaluated chunk
/// @param chunkStartTimeMax start time of chunk in ms
/// @param chunkLengthTime   time length of chunk in ms
Function PSQ_AddBaselineEpoch(WAVE epochWave, variable DAC, variable chunk, variable chunkStartTimeMax, variable chunkLengthTime)

	string epName, epShortName

	epName      = "Name=Baseline Chunk;Index=" + num2istr(chunk)
	epShortName = PSQ_BASELINE_CHUNK_SHORT_NAME_PREFIX + num2istr(chunk)
	EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, chunkStartTimeMax * MILLI_TO_ONE, (chunkStartTimeMax + chunkLengthTime) * MILLI_TO_ONE, epName, shortname = epShortName)
End

/// @brief Return the number of chunks
///
/// A chunk is #PSQ_BL_EVAL_RANGE [ms] of baseline.
///
/// For calculating the number of chunks we ignore the one chunk after the pulse which we don't evaluate!
static Function PSQ_GetNumberOfChunks(string device, variable sweepNo, variable headstage, variable type, variable sampleIntervalAD)

	variable length, nonBL, totalOnsetDelay

	WAVE DAQDataWave         = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(device)

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)

	length = stopCollectionPoint * sampleIntervalAD

	switch(type)
		case PSQ_DA_SCALE: // fallthrough-by-design
		case PSQ_RHEOBASE:
		case PSQ_RAMP:
		case PSQ_CHIRP:
			WAVE durations = PSQ_GetPulseDurations(device, type, sweepNo, totalOnsetDelay)
			ASSERT(durations[headstage] != 0, "Pulse duration can not be zero")
			nonBL = totalOnsetDelay + durations[headstage] + PSQ_BL_EVAL_RANGE
			return DEBUGPRINTv(floor((length - nonBL - PSQ_BL_EVAL_RANGE) / PSQ_BL_EVAL_RANGE) + 1)
		case PSQ_PIPETTE_BATH:
			return DEBUGPRINTv(floor(PSQ_PB_GetPrePulseBaselineDuration(device, headstage) / PSQ_BL_EVAL_RANGE))
		case PSQ_SEAL_EVALUATION:
			// upper limit
			return 2
		case PSQ_TRUE_REST_VM:
		case PSQ_ACC_RES_SMOKE:
			return 1
		default:
			ASSERT(0, "unsupported type")
	endswitch
End

// @brief Calculate a value from `startTime` spanning
//        `rangeTime` milliseconds according to `method`
static Function PSQ_Calculate(wv, column, startTime, rangeTime, method)
	WAVE wv
	variable column, startTime, rangeTime, method

	variable rangePoints, startPoints

	WAVE channel = AFH_GetChannelFromSweepOrScaledWave(wv, column)

	startPoints = trunc(startTime / DimDelta(channel, ROWS))
	rangePoints = max(trunc(rangeTime / DimDelta(channel, ROWS)), 1)

	if(startPoints + rangePoints >= DimSize(channel, ROWS))
		rangePoints = max(trunc(DimSize(channel, ROWS) - startPoints - 1), 1)
	endif

	MatrixOP/FREE data = subRange(channel, startPoints, startPoints + rangePoints - 1, 0, 0)

	switch(method)
		case PSQ_CALC_METHOD_AVG:
			MatrixOP/FREE result = mean(data)
			break
		case PSQ_CALC_METHOD_RMS:
			// This differs from what WaveStats returns in `V_sdev` as we divide by
			// `N` but WaveStats by `N -1`
			MatrixOP/FREE avg = mean(data)
			MatrixOP/FREE result = sqrt(sumSqr(data - avg[0]) / numRows(data))
			break
		default:
			ASSERT(0, "Unknown method")
	endswitch

	ASSERT(IsFinite(result[0]), "result must be finite")

	return result[0]
End

/// @brief Return the number of already acquired sweeps from the given
///        stimset cycle
static Function PSQ_NumAcquiredSweepsInSet(device, sweepNo, headstage)
	string device
	variable sweepNo, headstage

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

	if(!WaveExists(sweeps)) // very unlikely
		return 0
	endif

	return DimSize(sweeps, ROWS)
End

/// @brief Return the number of passed sweeps in all sweeps from the given
///        stimset cycle
Function PSQ_NumPassesInSet(numericalValues, type, sweepNo, headstage)
	WAVE numericalValues
	variable type, sweepNo, headstage

	string key

	key = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	WAVE/Z passes = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE, defValue = 0)

	if(!WaveExists(passes))
		return NaN
	endif

	return sum(passes)
End

/// @brief Return the DA stimset length in ms of the given headstage
///
/// @return stimset length or -1 on error
static Function PSQ_GetDAStimsetLength(device, headstage)
	string   device
	variable headstage

	string   setName
	variable DAC

	DAC     = AFH_GetDACFromHeadstage(device, headstage)
	setName = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)

	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	if(!WaveExists(stimset))
		return -1
	endif

	return DimSize(stimset, ROWS) * DimDelta(stimset, ROWS)
End

/// @brief Create the overrides results wave for CI testing
///
/// #PSQ_SQUARE_PULSE:
///
/// Rows:
/// - Only one
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: x position in ms where the spike is in each sweep/step
///   For convenience the values `0` always means no spike and `1` spike detected (at the appropriate position).
/// - 1: async channel QC
///
/// #PSQ_RHEOBASE/#PSQ_RAMP:
///
/// Rows:
/// - chunk indizes
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: x position in ms where the spike is in each sweep/step
///      For convenience the values `0` always means no spike and `1` spike detected (at the appropriate position).
/// - 2: async channel QC
///
/// Chunks (only for layer 0):
/// - 0: RMS short baseline QC
/// - 1: RMS long baseline QC
/// - 2: target voltage baseline QC
/// - 3: leak current baseline QC
///
/// #PSQ_DA_SCALE (Sub and Supra):
///
/// Rows:
/// - chunk indizes
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: x position in ms where the spike is in each sweep/step
///      For convenience the values `0` always means no spike and `1` spike detected (at the appropriate position).
/// - 2: Number of spikes
/// - 3: Async channel QC
///
/// Chunks (only for layer 0):
/// - 0: RMS short baseline QC
/// - 1: RMS long baseline QC
/// - 2: target voltage baseline QC
/// - 3: leak current baseline QC
///
/// #PSQ_DA_SCALE (Adaptive):
///
/// Rows:
/// - chunk indizes
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: APFrequency
/// - 2: Async channel QC
///
/// Chunks (only for layer 0):
/// - 0: RMS short baseline QC
/// - 1: RMS long baseline QC
/// - 2: target voltage baseline QC
/// - 3: leak current baseline QC
///
/// JSON-Wavenote:
/// - "APFrequenciesRhSuAd": List of frequencies from the previous passing rheobase/supra/adaptive SCI
/// - "DAScalesRhSuAd": List of DAScale values from previous passing rheobase/supra/adaptive SCI
/// - "PassingSupraSweep": Sweep with passing supra set QC
/// - "PassingRheobaseSweep": Sweep with passing rheobase set QC
/// - "PassingRhSuAdSweeps": List of passing rheobase/supra/adaptive SCI sweeps
/// - "FailingAdaptiveSweep": Failing adaptive sweep, the very last one, of the previous SCI (*written* by PSQ_DaScale)
///
/// #PSQ_CHIRP:
///
/// Rows:
/// - chunk indizes
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: maximum of AD data in chirp region [first row only,
///      others are ignored], use NaN to use the real values
/// - 2: minimum of AD data in chirp region [first row only,
///      others are ignored], use NaN to use the real values
/// - 3: passing spike check in chirp region or not [first row only,
///      others are ignored]
/// - 4: async channel QC
///
/// Chunks (only for layer 0):
/// - 0: RMS short baseline QC
/// - 1: RMS long baseline QC
/// - 2: target voltage baseline QC
/// - 3: leak current baseline QC
///
/// #PSQ_PIPETTE_BATH:
///
/// Rows:
/// - chunk indizes
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: averaged steady state resistance [MΩ]
/// - 2: async channel QC
///
/// Chunks (only for layer 0):
/// - 0: RMS short baseline QC
/// - 1: RMS long baseline QC
/// - 2: target voltage baseline QC
/// - 3: leak current baseline QC
///
/// #PSQ_SEAL_EVALUATION:
///
/// Rows:
/// - chunk indizes (only selected chunks via user epoch, sorted by ascending chunk start time)
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: Resistance A [MΩ]
/// - 2: Resistance B [MΩ]
/// - 3: Async Channel QC
///
/// Chunks (only for layer 0):
/// - 0: RMS short baseline QC
/// - 1: RMS long baseline QC
/// - 2: target voltage baseline QC
/// - 3: leak current baseline QC
///
/// #PSQ_TRUE_REST_VM:
///
/// Rows:
/// - chunk indizes (only selected chunks via user epoch, sorted by ascending chunk start time)
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: number of spikes (QC passes with 0)
/// - 2: average voltage [mV]
/// - 3: async channel QC
///
/// Chunks (only for row/layer 0):
/// - 0: RMS short baseline QC
/// - 1: RMS long baseline QC
/// - 2: target voltage baseline QC (unused)
/// - 3: leak current baseline QC (unused)
///
/// #PSQ_ACC_RES_SMOKE:
///
/// Rows:
/// - chunk indizes (only selected chunks via user epoch, sorted by ascending chunk start time)
///
/// Cols:
/// - sweeps/steps
///
/// Layers:
/// - 0: 1 if the chunk has passing baseline QC or not
/// - 1: Access Resistance [MΩ]
/// - 2: Steady State Resistance [MΩ]
/// - 3: Async Channel QC
///
/// Chunks (only for layer 0):
/// - 0: RMS short baseline QC
/// - 1: RMS long baseline QC
/// - 2: target voltage baseline QC
/// - 3: leak current baseline QC
Function/WAVE PSQ_CreateOverrideResults(string device, variable headstage, variable type, [string opMode])

	variable DAC, numCols, numRows, numLayers, numChunks, sampleIntervalDA
	string stimset
	string layerDimLabels = ""

	WAVE config = GetDAQConfigWave(device)

	sampleIntervalDA = config[0][%SamplingInterval] * MICRO_TO_MILLI

	DAC     = AFH_GetDACFromHeadstage(device, headstage)
	stimset = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
	WAVE/Z stimsetWave = WB_CreateAndGetStimSet(stimset)
	ASSERT(WaveExists(stimsetWave), "Stimset does not exist")

	if(type == PSQ_DA_SCALE)
		ASSERT(!ParamIsDefault(opMode) && PSQ_DS_IsValidMode(opMode), "Expected valid opMode")
	endif

	switch(type)
		case PSQ_RAMP:
		case PSQ_RHEOBASE:
			numChunks      = 4
			numRows        = PSQ_GetNumberOfChunks(device, 0, headstage, type, sampleIntervalDA)
			numCols        = IDX_NumberOfSweepsInSet(stimset)
			layerDimLabels = "BaselineQC;SpikePositionAndQC;AsyncQC"
			break
		case PSQ_DA_SCALE:
			numChunks = 4
			numRows   = PSQ_GetNumberOfChunks(device, 0, headstage, type, sampleIntervalDA)
			numCols   = IDX_NumberOfSweepsInSet(stimset)

			strswitch(opMode)
				case PSQ_DS_SUB:
				case PSQ_DS_SUPRA:
					layerDimLabels = "BaselineQC;SpikePosition;NumberOfSpikes;AsyncQC"
					break
				case PSQ_DS_ADAPT:
					layerDimLabels = "BaselineQC;APFrequency;AsyncQC"
					break
				default:
					ASSERT(0, "Invalid opMode")
			endswitch
			break
		case PSQ_SQUARE_PULSE:
			numRows        = 1
			numCols        = IDX_NumberOfSweepsInSet(stimset)
			layerDimLabels = "SpikePositionAndQC;AsyncQC"
			break
		case PSQ_CHIRP:
			numChunks      = 4
			numRows        = PSQ_GetNumberOfChunks(device, 0, headstage, type, sampleIntervalDA)
			numCols        = IDX_NumberOfSweepsInSet(stimset)
			layerDimLabels = "BaselineQC;MaxInChirp;MinInChirp;SpikeQC;AsyncQC"
			break
		case PSQ_PIPETTE_BATH:
			numChunks      = 4
			numRows        = PSQ_GetNumberOfChunks(device, 0, headstage, type, sampleIntervalDA)
			numCols        = IDX_NumberOfSweepsInSet(stimset)
			layerDimLabels = "BaselineQC;SteadyStateResistance;AsyncQC"
			break
		case PSQ_SEAL_EVALUATION:
			numChunks      = 4
			numRows        = 2                                            // upper limit
			numCols        = IDX_NumberOfSweepsInSet(stimset)
			layerDimLabels = "BaselineQC;ResistanceA;ResistanceB;AsyncQC"
			break
		case PSQ_TRUE_REST_VM:
			numChunks      = 4
			numRows        = 2
			numCols        = IDX_NumberOfSweepsInSet(stimset)
			layerDimLabels = "BaselineQC;NumberOfSpikes;AverageVoltage;AsyncQC"
			break
		case PSQ_ACC_RES_SMOKE:
			numChunks      = 4
			numRows        = 1
			numCols        = IDX_NumberOfSweepsInSet(stimset)
			layerDimLabels = "BaselineQC;AccessResistance;SteadyStateResistance;AsyncQC"
			break
		default:
			ASSERT(0, "invalid type")
	endswitch

	WAVE/D/Z wv = GetOverrideResults()
	numLayers = ItemsInList(layerDimLabels, ";")

	if(WaveExists(wv))
		ASSERT(IsNumericWave(wv), "overrideResults wave must be numeric here")
		Redimension/D/N=(numRows, numCols, numLayers, numChunks) wv
	else
		Make/D/N=(numRows, numCols, numLayers, numChunks) root:overrideResults/WAVE=wv
	endif

	wv[] = 0

	SetDimensionLabels(wv, layerDimLabels, LAYERS)

	return wv
End

/// @brief Store the step size in the labnotebook
static Function PSQ_StoreStepSizeInLBN(device, type, sweepNo, stepsize, [future])
	string device
	variable type, sweepNo, stepsize, future

	string key

	if(ParamIsDefault(future))
		future = 0
	else
		future = !!future
	endif

	WAVE values = LBN_GetNumericWave()
	values[INDEP_HEADSTAGE] = stepsize
	key                     = CreateAnaFuncLBNKey(type, SelectString(future, PSQ_FMT_LBN_STEPSIZE, PSQ_FMT_LBN_STEPSIZE_FUTURE))
	ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = sweepNo)
End

/// @brief Search the AD channel of the given headstage for spikes from the
/// pulse onset until the end of the sweep or `searchEnd` if given
///
/// @param[in] device            device
/// @param[in] type                  One of @ref PatchSeqAnalysisFunctionTypes
/// @param[in] sweepWave             sweep wave with acquired data
/// @param[in] headstage             headstage in the range [0, NUM_HEADSTAGES[
/// @param[in] offset                offset in ms where the spike search should start, commonly the totalOnsetDelay
/// @param[in] level                 set the level for the spike search
/// @param[in] searchEnd             [optional, defaults to inf] total length in ms of the spike search, relative to sweepWave start
/// @param[in] numberOfSpikesReq     [optional, defaults to one] number of spikes to look for
///                                  Positive finite value: Return value is 1 iff at least `numberOfSpikes` were found
///                                  Inf: Return value is 1 if at least 1 spike was found
/// @param[out] spikePositions       [optional] returns the position of the first `numberOfSpikes` found on success in ms
/// @param[out] numberOfSpikesFound  [optional] returns the number of spikes found
///
/// @return labnotebook value wave suitable for ED_AddEntryToLabnotebook()
static Function/WAVE PSQ_SearchForSpikes(device, type, sweepWave, headstage, offset, level, [searchEnd, numberOfSpikesReq, spikePositions, numberOfSpikesFound])
	string   device
	variable type
	WAVE     sweepWave
	variable headstage, offset, level, searchEnd
	variable  numberOfSpikesReq
	WAVE      spikePositions
	variable &numberOfSpikesFound

	variable first, last, overrideValue, rangeSearchLevel
	variable minVal, maxVal, numSpikesFoundOverride
	string msg

	WAVE spikeDetection = LBN_GetNumericWave()
	spikeDetection = (p == headstage ? 0 : NaN)

	WAVE config = AFH_GetConfigWave(device, sweepWave)

	if(ParamIsDefault(searchEnd))
		searchEnd = Inf
	endif

	if(ParamIsDefault(numberOfSpikesReq))
		numberOfSpikesReq = 1
	else
		ASSERT(numberOfSpikesReq > 0, "Invalid numberOfSpikesFound")
		numberOfSpikesReq = trunc(numberOfSpikesReq)
	endif

	if(!ParamIsDefault(numberOfSpikesFound))
		numberOfSpikesFound = NaN
	endif

	sprintf msg, "Type %d, headstage %d, offset %g, numberOfSpikesReq %d", type, headstage, offset, numberOfSpikesReq
	DEBUGPRINT(msg)

	if(type == PSQ_CHIRP || type == PSQ_TRUE_REST_VM)
		first = offset
		last  = searchEnd
	else
		// search pulse in DA and use the pulse as search region
		WAVE singleDA = AFH_ExtractOneDimDataFromSweep(device, sweepWave, headstage, XOP_CHANNEL_TYPE_DAC, config = config)
		[minVal, maxVal] = WaveMinAndMax(singleDA, offset, Inf)

		if(minVal == 0 && maxVal == 0)
			if(type == PSQ_SQUARE_PULSE)
				first = 0
				last  = searchEnd
			else
				return spikeDetection
			endif
		else
			rangeSearchLevel = minVal + GetMachineEpsilon(WaveType(singleDA))

			Make/FREE/D levels
			FindLevels/R=(offset, Inf)/Q/N=2/DEST=levels singleDA, rangeSearchLevel
			ASSERT(V_LevelsFound == 2, "Could not find two levels")
			first = levels[0]

			if(type == PSQ_DA_SCALE)
				last = levels[1]
			else
				last = searchEnd
			endif
		endif
	endif

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		NVAR count           = $GetCount(device)

		switch(type)
			case PSQ_TRUE_REST_VM:
				overrideValue          = overrideResults[0][count][1]
				numSpikesFoundOverride = overrideValue
				break
			case PSQ_CHIRP:
				overrideValue          = !overrideResults[0][count][3]
				numSpikesFoundOverride = overrideValue > 0
				break
			case PSQ_RHEOBASE:
				overrideValue          = overrideResults[0][count][1]
				numSpikesFoundOverride = overrideValue > 0
				break
			case PSQ_SQUARE_PULSE:
				overrideValue          = overrideResults[0][count][0]
				numSpikesFoundOverride = overrideValue > 0
				break
			case PSQ_RAMP:
				overrideValue          = overrideResults[0][count][1]
				numSpikesFoundOverride = overrideValue > 0
				break
			case PSQ_DA_SCALE:
				overrideValue = overrideResults[0][count][1]
				if(overrideValue > 0)
					numSpikesFoundOverride = overrideResults[0][count][2]
				else
					numSpikesFoundOverride = 0
				endif
				break
			default:
				ASSERT(0, "unsupported type")
		endswitch

		if(overrideValue == 0 || overrideValue == 1)
			spikeDetection[headstage] = overrideValue
		else
			spikeDetection[headstage] = overrideValue >= first && overrideValue <= last
		endif

		if(!ParamIsDefault(spikePositions))
			ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
			Redimension/D/N=(numSpikesFoundOverride) spikePositions
			spikePositions[] = overrideValue
		endif

		if(!ParamIsDefault(numberOfSpikesFound))
			numberOfSpikesFound = numSpikesFoundOverride
		endif
	else

		WAVE singleAD = AFH_ExtractOneDimDataFromSweep(device, sweepWave, headstage, XOP_CHANNEL_TYPE_ADC, config = config)
		ASSERT(!cmpstr(WaveUnits(singleAD, -1), "mV"), "Unexpected AD Unit")

		if(type == PSQ_CHIRP)
			// use PA plot logic
			Duplicate/R=(first, last)/FREE singleAD, chirpChunk

			ASSERT(numberOfSpikesReq == Inf, "Unexpected value of numberOfSpikesReq")
			WAVE spikePositionsResult = PA_SpikePositionsForNonVC(chirpChunk, level)

			spikeDetection[headstage] = DimSize(spikePositionsResult, ROWS) > 0

			if(!ParamIsDefault(numberOfSpikesFound))
				numberOfSpikesFound = DimSize(spikePositionsResult, ROWS)
			endif
		else
			if(numberOfSpikesReq == 1)
				// search the spike from the start till the end
				FindLevel/Q/R=(first, last)/B=3 singleAD, level
				spikeDetection[headstage] = !V_flag

				if(!ParamIsDefault(spikePositions))
					ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
					Redimension/D/N=(numberOfSpikesReq) spikePositions
					spikePositions[0] = V_LevelX
				endif

				if(!ParamIsDefault(numberOfSpikesFound))
					numberOfSpikesFound = spikeDetection[headstage]
				endif
			elseif(numberOfSpikesReq > 1)
				Make/D/FREE/N=0 crossings
				FindLevels/Q/R=(first, last)/N=(numberOfSpikesReq)/DEST=crossings/EDGE=1/B=3 singleAD, level
				spikeDetection[headstage] = IsFinite(numberOfSpikesReq) ? (!V_flag) : (V_LevelsFound > 0)

				if(!ParamIsDefault(spikePositions))
					ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
					Redimension/D/N=(V_LevelsFound) spikePositions

					if(spikeDetection[headstage])
						spikePositions[] = crossings[p]
					endif
				endif

				if(!ParamIsDefault(numberOfSpikesFound))
					numberOfSpikesFound = V_LevelsFound
				endif
			else
				ASSERT(0, "Invalid number of spikes value")
			endif
		endif
	endif

	ASSERT(IsFinite(spikeDetection[headstage]), "Expected finite result")

	return DEBUGPRINTw(spikeDetection)
End

/// @brief Return a sweep number of an existing sweep matching the following conditions
///
/// - Acquired with Rheobase analysis function
/// - Set QC passed for this SCI
/// - Pulse duration was longer than `duration`
/// - Spiked
///
/// And as usual we want the *last* matching sweep.
///
/// @return existing sweep number or INVALID_SWEEP_NUMBER in case no such sweep could be found
static Function PSQ_GetLastPassingLongRHSweep(string device, variable headstage, variable duration)
	string key
	variable i, j, setSweep, numSetSweeps, numEntries, sweepNo, setQC, numPassingSweeps

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()

		WAVE/Z passingRheobaseSweep = JWN_GetNumericWaveFromWaveNote(overrideResults, "PassingRheobaseSweep")

		if(WaveExists(passingRheobaseSweep))
			return passingRheobaseSweep[0]
		endif
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, key)

	if(!WaveExists(sweeps))
		return INVALID_SWEEP_NUMBER
	endif

	// sweeps hold all which have a Set QC entry
	numEntries = DimSize(sweeps, ROWS)
	for(i = numEntries - 1; i >= 0; i -= 1)
		sweepNo = sweeps[i]

		setQC = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

		if(!setQC)
			// set QC failed
			continue
		endif

		// check that the pulse duration was long enough
		key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_PULSE_DUR, query = 1)
		WAVE/Z setting = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

		if(!WaveExists(setting) || setting[headstage] < duration)
			continue
		endif

		// now fetch all sweeps from that SCI
		WAVE/Z setSweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
		ASSERT(WaveExists(setSweeps), "Passing set but without sweeps is implausible")

		numSetSweeps = DimSize(setSweeps, ROWS)
		for(j = numSetSweeps - 1; j >= 0; j -= 1)
			setSweep = setSweeps[j]
			key      = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
			WAVE/Z spikeDetect = GetLastSetting(numericalValues, setSweep, key, UNKNOWN_MODE)

			// and return the last spiking one
			if(WaveExists(spikeDetect) && spikeDetect[headstage] == 1)
				return setSweep
			endif
		endfor
	endfor

	return INVALID_SWEEP_NUMBER
End

/// @brief Return the previously acquired sweep number
///
/// But only when it fullfills all of the following conditions:
/// - DAScale supra adaptive analysis function was run
/// - failing set QC
/// - all analysis parameters are the same
/// - used same targetV autobias value
static Function PSQ_GetPreviousSetQCFailingAdaptive(string device, variable headstage, string params)

	variable sweepNo, setQC, currentAutoBiasV
	string key, opMode

	sweepNo = AFH_GetLastSweepAcquired(device)

	if(!IsValidSweepNumber(sweepNo))
		return INVALID_SWEEP_NUMBER
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	key    = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_OPMODE, query = 1)
	opMode = GetLastSettingTextIndep(textualValues, sweepNo, key, UNKNOWN_MODE)

	if(cmpstr(opMode, PSQ_DS_ADAPT))
		return INVALID_SWEEP_NUMBER
	endif

	key   = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	setQC = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE, defValue = 0)

	if(setQC)
		return INVALID_SWEEP_NUMBER
	endif

	WAVE/T previousAnalysisParams = GetLastSetting(textualValues, sweepNo, ANALYSIS_FUNCTION_PARAMS_LBN, DATA_ACQUISITION_MODE)

	if(cmpstr(previousAnalysisParams[headstage], params))
		return INVALID_SWEEP_NUMBER
	endif

	currentAutoBiasV = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

	WAVE autoBiasV = GetLastSetting(numericalValues, sweepNo, "Autobias Vcom", DATA_ACQUISITION_MODE)

	if(!CheckIfClose(autoBiasV[headstage], currentAutoBiasV, tol = 1e-2))
		return INVALID_SWEEP_NUMBER
	endif

	return sweepNo
End

/// @brief Return the truth that str is a valid PSQ_DAScale operation mode
Function PSQ_DS_IsValidMode(string str)
	return !cmpstr(str, PSQ_DS_SUB) || !cmpstr(str, PSQ_DS_SUPRA) || !cmpstr(str, PSQ_DS_ADAPT)
End

/// @brief Return the sweep number of the last sweep using the PSQ_DaScale()
///        analysis function, where the set passes and was in the given mode
static Function PSQ_GetLastPassingDAScale(string device, variable headstage, string opMode)
	variable numEntries, sweepNo, i, setQC
	string key, modeKey

	ASSERT(PSQ_DS_IsValidMode(opMode), "Invalid opMode")

	if(TestOverrideActive() && !cmpstr(opMode, PSQ_DS_SUPRA))
		WAVE overrideResults = GetOverrideResults()

		WAVE/Z passingSupraSweep = JWN_GetNumericWaveFromWaveNote(overrideResults, "PassingSupraSweep")

		if(WaveExists(passingSupraSweep))
			return passingSupraSweep[0]
		endif
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	// PSQ_DaScale with set QC
	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, key)

	if(!WaveExists(sweeps))
		return INVALID_SWEEP_NUMBER
	endif

	numEntries = DimSize(sweeps, ROWS)
	for(i = numEntries - 1; i >= 0; i -= 1)
		sweepNo = sweeps[i]

		setQC = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

		if(!setQC)
			// set QC failed
			continue
		endif

		// check for subthreshold operation mode
		modeKey = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_OPMODE, query = 1)

		WAVE/T/Z setting = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, modeKey, headstage, UNKNOWN_MODE)

		if(WaveExists(setting) && !cmpstr(setting[INDEP_HEADSTAGE], opMode))
			return sweepNo
		endif
	endfor

	return INVALID_SWEEP_NUMBER
End

/// @brief Return the sweep number of the last sweep using the PSQ_TrueRestingMembranePotential()
///        analysis function
static Function PSQ_GetLastPassingTrueRMP(string device, variable headstage)
	variable numEntries, sweepNo, i, setQC
	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	// PSQ_CHIRP with set QC
	key = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_SET_PASS, query = 1)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, key)

	if(!WaveExists(sweeps))
		return INVALID_SWEEP_NUMBER
	endif

	numEntries = DimSize(sweeps, ROWS)
	for(i = numEntries - 1; i >= 0; i -= 1)
		sweepNo = sweeps[i]

		setQC = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

		if(!setQC)
			// set QC failed
			continue
		endif

		return sweepNo
	endfor

	return INVALID_SWEEP_NUMBER
End

/// @brief Return the DAScale offset for PSQ_DaScale()
///
/// @return DAScale value in pA or NaN on error
static Function PSQ_DS_GetDAScaleOffset(device, headstage, opMode)
	string device, opMode
	variable headstage

	variable sweepNo

	strswitch(opMode)
		case PSQ_DS_SUPRA:
			if(TestOverrideActive())
				return PSQ_DS_OFFSETSCALE_FAKE
			endif

			sweepNo = PSQ_GetLastPassingLongRHSweep(device, headstage, PSQ_RHEOBASE_DURATION)
			if(!IsValidSweepNumber(sweepNo))
				return NaN
			endif

			WAVE   numericalValues = GetLBNumericalValues(device)
			WAVE/Z setting         = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
			ASSERT(WaveExists(setting), "Could not find DAScale value of matching rheobase sweep")
			return setting[headstage]
		case PSQ_DS_SUB:
		// fallthrough-by-design
		case PSQ_DS_ADAPT:
			return 0
		default:
			ASSERT(0, "unknown opMode")
	endswitch
End

/// @brief Check if the given sweep has at least one "spike detected" entry in
///        the labnotebook
///
/// @return 1 if found at least one, zero if none and `NaN` if no such entry
/// could be found
static Function PSQ_FoundAtLeastOneSpike(device, sweepNo)
	string   device
	variable sweepNo

	string key

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(!WaveExists(settings))
		return NaN
	endif

	return Sum(settings) > 0
End

static Function PSQ_GetDefaultSamplingFrequency(string device, variable type)

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			switch(type)
				case PSQ_CHIRP:
				case PSQ_DA_SCALE:
				case PSQ_RAMP:
				case PSQ_RHEOBASE:
				case PSQ_SQUARE_PULSE:
					return 50
				case PSQ_PIPETTE_BATH:
				case PSQ_SEAL_EVALUATION:
				case PSQ_TRUE_REST_VM:
				case PSQ_ACC_RES_SMOKE:
					return 200
				default:
					ASSERT(0, "Unknown analysis function")
			endswitch
		case HARDWARE_NI_DAC:
			switch(type)
				case PSQ_CHIRP:
				case PSQ_DA_SCALE:
				case PSQ_RAMP:
				case PSQ_RHEOBASE:
				case PSQ_SQUARE_PULSE:
					return 50
				case PSQ_PIPETTE_BATH:
				case PSQ_SEAL_EVALUATION:
				case PSQ_TRUE_REST_VM:
				case PSQ_ACC_RES_SMOKE:
					return 250
				default:
					ASSERT(0, "Unknown analysis function")
			endswitch
		case HARDWARE_SUTTER_DAC:
			switch(type)
				case PSQ_CHIRP:
				case PSQ_DA_SCALE:
				case PSQ_RAMP:
				case PSQ_RHEOBASE:
				case PSQ_SQUARE_PULSE:
					return 50
				case PSQ_PIPETTE_BATH:
				case PSQ_SEAL_EVALUATION:
				case PSQ_TRUE_REST_VM:
				case PSQ_ACC_RES_SMOKE:
					return 50
				default:
					ASSERT(0, "Unknown analysis function")
			endswitch
		default:
			ASSERT(0, "Unknown hardware type")
	endswitch
End

/// @brief Returns the sampling frequency in kHz of our supported NI and ITC
/// hardware for one active headstage and no TTL channels.
Function PSQ_GetDefaultSamplingFrequencyForSingleHeadstage(string device)

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			return 50
		case HARDWARE_NI_DAC:
			return 125
		case HARDWARE_SUTTER_DAC:
			return 50
		default:
			ASSERT(0, "Unknown hardware")
	endswitch
End

/// @brief Return the QC state of the sampling interval/frequency check and store it also in the labnotebook
static Function PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(string device, variable type, STRUCT AnalysisFunction_V3 &s)

	variable samplingFrequency, expected, actual, samplingFrequencyPassed, defaultFreq
	string key

	defaultFreq       = PSQ_GetDefaultSamplingFrequency(device, type)
	samplingFrequency = AFH_GetAnalysisParamNumerical("SamplingFrequency", s.params, defValue = defaultFreq)

	WAVE config    = AFH_GetConfigWave(device, s.scaledDACWave)
	WAVE channelAD = AFH_GetChannelFromSweepOrScaledWave(s.scaledDACWave, GetFirstADCChannelIndex(config))
	ASSERT(!cmpstr(StringByKey("XUNITS", WaveInfo(channelAD, 0)), "ms"), "Unexpected wave x unit")

#ifdef EVIL_KITTEN_EATING_MODE
	actual = PSQ_GetDefaultSamplingFrequencyForSingleHeadstage(device) * KILO_TO_ONE
#else
	// dimension delta [ms]
	actual = 1.0 / (s.sampleIntervalAD * MILLI_TO_ONE)
#endif

	// samplingFrequency [kHz]
	expected = samplingFrequency * KILO_TO_ONE

	samplingFrequencyPassed = CheckIfClose(expected, actual, tol = 1)

	WAVE result = LBN_GetNumericWave()
	result[INDEP_HEADSTAGE] = samplingFrequencyPassed
	key                     = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_SAMPLING_PASS)
	ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

	return samplingFrequencyPassed
End

/// @brief Return the duration of the given epoch in the stimulus set
///
/// Does not require epoch info, and also supports combine epochs which don't
/// have a "Duration" parameter.
static Function PSQ_DS_GatherEpochDuration(string setName, variable epochIndex)

	variable length
	string key, wvNote

	key = "Duration"

	length = ST_GetStimsetParameterAsVariable(setName, key, epochIndex = epochIndex)
	if(IsNaN(length))
		WAVE stimset = WB_CreateAndGetStimSet(setName)
		wvNote = note(stimset)
		length = WB_GetWaveNoteEntryAsNumber(wvNote, EPOCH_ENTRY, key = key, sweep = 0, epoch = epochIndex)
	endif

	ASSERT(IsFinite(length), "Invalid length")

	length *= MILLI_TO_ONE

	return length
End

static Function [variable start, variable stop] PSQ_DS_GetFrequencyEvalRangeForRhSuAd(string device, variable headstage, variable sweepNo)

	variable supraEpochLength, adaptiveEpochLength
	string setName

	setName = AFH_GetStimSetNameForHeadstage(device, headstage)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE     DACs   = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	WAVE/T/Z epochs = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, DACs[headstage], "^E1$")
	ASSERT(WaveExists(epochs), "Could not find E1 epoch")
	ASSERT(DimSize(epochs, ROWS) == 1, "Expected exactly one epoch")
	supraEpochLength    = str2num(epochs[0][EPOCH_COL_ENDTIME]) - str2num(epochs[0][EPOCH_COL_STARTTIME])
	adaptiveEpochLength = PSQ_DS_GatherEpochDuration(setName, 1)
	ASSERT(adaptiveEpochLength < supraEpochLength || CheckIfClose(adaptiveEpochLength, supraEpochLength, tol = 1e-6), "Adaptive epoch 1 length must be shorter than the one from supra")

	start = str2num(epochs[0][EPOCH_COL_STARTTIME])
	stop  = start + adaptiveEpochLength

	return [start, stop]
End

static Function [variable start, variable stop] PSQ_DS_GetFrequencyEvalRange(string device, variable headstage, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE     DACs   = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	WAVE/T/Z epochs = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, DACs[headstage], "^E1$")
	ASSERT(WaveExists(epochs), "Could not find E1 epoch")
	ASSERT(DimSize(epochs, ROWS) == 1, "Expected exactly one epoch")

	start = str2num(epochs[0][EPOCH_COL_STARTTIME])
	stop  = str2num(epochs[0][EPOCH_COL_ENDTIME])

	return [start, stop]
End

/// @brief Use SweepFormula to gather the AP frequency and DAScale data from the given sweeps
///
/// @param device                    DAC hardware device
/// @param sweepNo                   current sweep
/// @param headstage                 headstage
/// @param sweeps                    wave of sweep numbers to gather the data from
/// @param fromRhSuAd [optional, defaults to off] called for rheobase/supra/previous adaptive data (on) or adaptive data (off)
///
/// @retval apfreq  AP frequency data
/// @retval DAScale DAScale data
static Function [WAVE apfreq, WAVE DAScale] PSQ_DS_GatherFrequencyCurrentData(string device, variable sweepNo, variable headstage, WAVE sweeps, [variable fromRhSuAd])

	variable ADC, start, stop, refSweepNo
	string code, databrowser, key, ctrl, setName
	string str         = ""
	string freqDataKey = "Frequency data"
	string daScaleKey  = "DAScale data"

	if(ParamIsDefault(fromRhSuAd))
		fromRhSuAd = 0
	else
		fromRhSuAd = !!fromRhSuAd
	endif

	if(fromRhSuAd)
		refSweepNo = PSQ_GetLastPassingDAScale(device, headstage, PSQ_DS_SUPRA)
		[start, stop] = PSQ_DS_GetFrequencyEvalRangeForRhSuAd(device, headstage, refSweepNo)
	else
		refSweepNo = sweepNo
		[start, stop] = PSQ_DS_GetFrequencyEvalRange(device, headstage, refSweepNo)
	endif

	start *= ONE_TO_MILLI
	stop  *= ONE_TO_MILLI

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE/Z ADCs = GetLastSetting(numericalValues, refSweepNo, "ADC", DATA_ACQUISITION_MODE)
	ASSERT(WaveExists(ADCs), "Could not find the ADC labnotebook entry")
	ADC = ADCs[headstage]
	ASSERT(IsFinite(ADC), "Could not find an ADC for the headstage")

	sprintf code, "trange = [%g, %g]\r", start, stop
	str += code
	sprintf code, "sweepr = [%s]\r", NumericWaveToList(sweeps, ",", trailSep = 0)
	str += code
	sprintf code, "sel = select(selchannels(AD%d), selsweeps($sweepr), selvis(all))\r", ADC
	str += code
	sprintf code, "dat = data(select(selrange($trange), $sel))\r"
	str += code
	sprintf code, "freq = merge(apfrequency($dat, 0))\r" // 0 == FULL
	str += code
	sprintf code, "xData = merge(labnotebook(\"Stim Scale Factor\", $sel, DATA_ACQUISITION_MODE))\r"
	str += code
	sprintf code, "\r"
	str += code
	sprintf code, "store(\"%s\", $freq)\r", freqDataKey
	str += code
	sprintf code, "vs\r"
	str += code
	sprintf code, "store(\"%s\", $xData)\r", daScaleKey
	str += code

	databrowser = PSQ_ExecuteSweepFormula(device, str)

	WAVE/T textualResultsValues = BSP_GetLogbookWave(databrowser, LBT_RESULTS, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)

	sprintf key, "Sweep Formula store [%s]", freqDataKey
	WAVE apfreq = PSQ_GetSweepFormulaResultWave(textualResultsValues, key)

	sprintf key, "Sweep Formula store [%s]", daScaleKey
	WAVE DaScale = PSQ_GetSweepFormulaResultWave(textualResultsValues, key)

	ASSERT(EqualWaves(apfreq, DAScale, EQWAVES_DIMSIZE), "Non-matching dimension sizes when calculating APFrequency")

	return [apfreq, DaScale]
End

/// @brief Filter duplicated AP frequencies out
///
/// @param apfreq   AP frequencies
/// @param DAScales DA scale values
///
/// @retval apfreqFiltered   AP frequencies with neighbouring duplicates removed
/// @retval DAScalesFiltered DScales values with intact indices
/// @retval deletedIndizes   Possibly non-existing wave with the removed indizes
/// @retval numPoints        Number of points in the apfreq/DAScales waves after filtering
static Function [WAVE apfreqFiltered, WAVE DAScalesFiltered, WAVE deletedIndizes, variable numPoints] PSQ_DS_FilterFrequencyCurrentData(WAVE apfreq, WAVE DAScales)

	numPoints = DimSize(apfreq, ROWS)
	ASSERT(numPoints == DimSize(DaScales, ROWS), "Non-matching wave sizes")

	if(numPoints < PSQ_DA_NUM_POINTS_LINE_FIT)
		return [$"", $"", $"", 0]
	endif

	WAVE/Z indizes = FindNeighbourDuplicates(apfreq)

	if(!WaveExists(indizes))
		return [apfreq, DAScales, $"", numPoints]
	endif

	if(DimSize(indizes, ROWS) == (numPoints - 1))
		// we can't do any fitting with only a single point left
		// but as the original data was all the same we can
		// just take the first PSQ_DA_NUM_POINTS_LINE_FIT points
		Duplicate/FREE/RMD=[0, PSQ_DA_NUM_POINTS_LINE_FIT - 1] apFreq, apFreqFiltered
		Duplicate/FREE/RMD=[0, PSQ_DA_NUM_POINTS_LINE_FIT - 1] DAScales, DAScalesFiltered

		Redimension/N=(numPoints - PSQ_DA_NUM_POINTS_LINE_FIT) indizes
		indizes[] = p + PSQ_DA_NUM_POINTS_LINE_FIT
	else
		Duplicate/FREE apFreq, apFreqFiltered
		Duplicate/FREE DAScales, DAScalesFiltered

		DeleteWavePoint(apFreqFiltered, ROWS, indices = indizes)
		DeleteWavePoint(DAScalesFiltered, ROWS, indices = indizes)
	endif

	WaveClear apFreq, DASCales

	numPoints = DimSize(apfreqFiltered, ROWS)

	return [apfreqFiltered, DASCalesFiltered, indizes, numPoints]
End

/// @brief Fit the AP frequency and DAScale data with a line fit and return the fit results (offsets and slopes)
///
/// @param device              DAC hardware device
/// @param sweepNo             current sweep
/// @param apfreq              AP frequency data
/// @param DAScales            DAScale data
/// @param singleFit           [optional, defaults to false] if only a single fit should be done
///
/// @retval fitOffset offsets of all line fits
/// @retval fitSlope  slopes of all line fits
/// @retval errMsg    error message if both `fitOffset` and `fitSlope` are null
static Function [WAVE/D fitOffset, WAVE/D fitSlope, string errMsg] PSQ_DS_FitFrequencyCurrentData(string device, variable sweepNo, WAVE/Z apfreq, WAVE/Z DAScales, [variable singleFit])

	variable i, numPoints, numFits, first, last, hasEnoughPoints, initialFit, idx, elem
	string line, databrowser, key
	string str = ""

	if(ParamIsDefault(singleFit))
		singleFit = 0
	else
		singleFit = !!singleFit
	endif

	if(!WaveExists(apFreq) && !WaveExists(DAScales))
		return [$"", $"", "No apfreq/DAScales data"]
	endif

	// original data:
	// apfreq:  {5,  8,   9,   9,   15}
	// DAScale: {50, 100, 130, 160, 200}
	// numPoints = 5
	//
	// after filtering:
	// apfreq:  {5,  8,   9,   15}
	// DAScale: {50, 100, 130, 200}
	// deletedIndizes: {3}
	// numPoints = 4
	[WAVE apfreqFiltered, WAVE DAScalesFiltered, WAVE deletedIndizes, numPoints] = PSQ_DS_FilterFrequencyCurrentData(apfreq, DAScales)
	WaveClear apfreq, DAScales

	hasEnoughPoints = (numPoints >= PSQ_DA_NUM_POINTS_LINE_FIT)

	if(singleFit && hasEnoughPoints)
		DeletePoints/M=(ROWS) 0, (numPoints - PSQ_DA_NUM_POINTS_LINE_FIT), apFreqFiltered, DAScalesFiltered
		numPoints = PSQ_DA_NUM_POINTS_LINE_FIT
	endif

	WAVE hasEnoughPointsLBN = LBN_GetNumericWave()
	key                                 = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_ENOUGH_FI_POINTS_PASS)
	hasEnoughPointsLBN[INDEP_HEADSTAGE] = hasEnoughPoints
	ED_AddEntryToLabnotebook(device, key, hasEnoughPointsLBN, overrideSweepNo = sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

	if(!hasEnoughPoints)
		return [$"", $"", "Not enough points for fit"]
	endif

	numFits = (numPoints - PSQ_DA_NUM_POINTS_LINE_FIT) + 1

	// output variables
	for(i = 0; i < numFits; i += 1)
		first = i
		last  = (i + PSQ_DA_NUM_POINTS_LINE_FIT) - 1

		WAVE apfreqSlice = DuplicateSubRange(apfreqFiltered, first, last)
		/// @todo prefer %f over %g due to https://github.com/AllenInstitute/MIES/issues/1863
		sprintf line, "freq%d = [%s]\r", i, NumericWaveToList(apfreqSlice, ",", format = PERCENT_F_MAX_PREC, trailSep = 0)
		str += line

		WAVE DaScalesSlice = DuplicateSubRange(DAScalesFiltered, first, last)
		sprintf line, "dascale%d = [%s]\r", i, NumericWaveToList(DaScalesSlice, ",", format = PERCENT_F_MAX_PREC, trailSep = 0)
		str += line
	endfor

	str += "\r"

	// formulas
	for(i = 0; i < numFits; i += 1)
		sprintf line, "store(\"Fit result %d\", fit($dascale%d, $freq%d, fitline()))\r", i, i, i
		str += line
		sprintf line, "with\r"
		str += line
		sprintf line, "$freq%d\r", i
		str += line
		sprintf line, "vs\r"
		str += line
		sprintf line, "$dascale%d\r", i
		str += line

		if(i < (numFits - 1))
			sprintf line, "and\r"
			str += line
		endif
	endfor

	databrowser = PSQ_ExecuteSweepFormula(device, str)

	WAVE/T textualResultsValues = BSP_GetLogbookWave(databrowser, LBT_RESULTS, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)

	Make/FREE/D/N=(numFits) fitOffset, fitSlope
	for(i = 0; i < numFits; i += 1)
		sprintf key, "Sweep Formula store [Fit result %d]", i
		WAVE/Z fitResult = PSQ_GetSweepFormulaResultWave(textualResultsValues, key)

		if(!WaveExists(fitResult))
			return [$"", $"", "Fit failed due to missing fitResult wave"]
		endif

		WAVE/Z fitCoeff = JWN_GetNumericWaveFromWaveNote(fitResult, SF_META_USER_GROUP + SF_META_FIT_COEFF)

		if(!WaveExists(fitCoeff))
			return [$"", $"", "Fit failed due to missing fitCoeff wave"]
		endif

		WAVE/Z fitParams = JWN_GetTextWaveFromWaveNote(fitResult, SF_META_USER_GROUP + SF_META_FIT_PARAMETER)
		ASSERT(WaveExists(fitParams), "Expected fit parameter wave")
		SetDimensionLabels(fitCoeff, TextWaveToList(fitParams, ";"), ROWS)

		fitOffset[i] = fitCoeff[%Offset]
		fitSlope[i]  = fitCoeff[%Slope] / ONE_TO_PICO * ONE_TO_PERCENT // % Hz / pA
	endfor

	// readd NaN entries for filtered out apFreq/DAScale
	if(!singleFit && WaveExists(deletedIndizes))
		Sort/A deletedIndizes, deletedIndizes
		for(elem : deletedIndizes)
			idx = floor(elem / PSQ_DA_NUM_POINTS_LINE_FIT)
			InsertPoints/M=(ROWS)/V=(PSQ_DS_SKIPPED_FI_SLOPE) idx, 1, fitOffset, fitSlope
		endfor
	endif

	if(!HasOneValidEntry(fitOffset) && !HasOneValidEntry(fitSlope))
		return [$"", $"", "All fit results are NaN"]
	endif

	return [fitOffset, fitSlope, ""]
End

static Function PSQ_DS_CreateSurveyPlotForUser(string device, variable sweepNo, variable headstage, [variable fromRhSuAd])

	variable emptySCI
	string   line
	string str = ""

	if(ParamIsDefault(fromRhSuAd))
		fromRhSuAd = 0
	else
		fromRhSuAd = !!fromRhSuAd
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	[WAVE apfreq, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_APFREQ, filterPassing = 1, fromRhSuAd = fromRhSuAd)
	[WAVE DAScale, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_DASCALE, filterPassing = 1, fromRhSuAd = fromRhSuAd)

	/// PSQ_FMT_LBN_DA_AT_RSA_FREQ
	/// PSQ_FMT_LBN_DA_AT_RSA_DASCALE
	///
	/// (both are already filtered for passing sweeps)
	///
	/// plus
	///
	/// PSQ_FMT_LBN_DA_AT_FREQ
	/// \"Stim Scale Factor\"
	///
	/// from full SCI filtered for passing
	sprintf line, "freq = [%s]\r", NumericWaveToList(apfreq, ",", format = PERCENT_F_MAX_PREC, trailSep = 0)
	str += line

	sprintf line, "daScale = [%s]\r", NumericWaveToList(DAScale, ",", format = PERCENT_F_MAX_PREC, trailSep = 0)
	str += line

	DeletePoints/M=(ROWS) 0, 1, DAScale
	sprintf line, "daScaleWithoutFirst = [%s]\r", NumericWaveToList(DAScale, ",", format = PERCENT_F_MAX_PREC, trailSep = 0)
	str += line

	[WAVE fitSlopes, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_FI_SLOPE, filterPassing = 1, fromRhSuAd = fromRhSuAd)

	/// PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES
	///
	/// (already filtered for passing sweeps)
	///
	/// plus
	///
	/// PSQ_FMT_LBN_DA_fI_SLOPE
	///
	/// from full SCI filtered for passing
	sprintf line, "fitSlopes = [%s]\r", NumericWaveToList(fitSlopes, ",", format = PERCENT_F_MAX_PREC, trailSep = 0)
	str += line

	str += "\r"

	str += "$freq\r"
	str += "vs\r"
	str += "$daScale\r\r"

	str += "and\r\r"

	str += "$fitSlopes\r"
	str += "vs\r"
	str += "$daScaleWithoutFirst\r\r"

	PSQ_ExecuteSweepFormula(device, str)
End

/// @brief Check if the fit results from PSQ_DS_FitFrequencyCurrentData are valid
///
/// @param device                    DAC hardware device
/// @param sweepNo                   current sweep
/// @param headstage                 headstage
/// @param fitOffset                 fit offsets
/// @param fitSlope                  fit slopes
/// @param fromRhSuAd [optional, defaults to false] if the fit offset/slope data is from the rheobase/supra threshold sweeps or not
static Function PSQ_DS_AreFitResultsValid(string device, variable sweepNo, variable headstage, WAVE/Z fitOffset, WAVE/Z fitSlope, [variable fromRhSuAd])

	variable numFits, validFit
	string key

	if(ParamIsDefault(fromRhSuAd))
		fromRhSuAd = 0
	else
		fromRhSuAd = !!fromRhSuAd
	endif

	if(WaveExists(fitOffset) && WaveExists(fitSlope))
		numFits = DimSize(fitOffset, ROWS)
		ASSERT(numFits == DimSize(fitSlope, ROWS), "Non-matching fitOffset/fitSlope waves sizes")

		Make/FREE/N=(numFits) validFitAll = !IsNaN(fitSlope[p])
		validFit = (Sum(validFitAll) == numFits)
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE validFitLBN     = LBN_GetNumericWave()
	validFitLBN[headstage] = validFit

	if(fromRhSuAd)
		key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_RSA_VALID_SLOPE_PASS)
	else
		key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_VALID_SLOPE_PASS)
	endif

	ED_AddEntryToLabnotebook(device, key, validFitLBN, overrideSweepNo = sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

	return validFit
End

Function [variable daScaleStepMinNorm, variable daScaleStepMaxNorm] PSQ_DS_GetDAScaleStepsNorm(string device, variable sweepNo, variable headstage)

	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	key                = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_MIN_DASCALE_NORM, query = 1)
	daScaleStepMinNorm = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	ASSERT(IsFinite(daScaleStepMinNorm), "Expected finite daScaleStepMinNorm")

	key                = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_MAX_DASCALE_NORM, query = 1)
	daScaleStepMaxNorm = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	ASSERT(IsFinite(daScaleStepMaxNorm), "Expected finite daScaleStepMaxNorm")

	ASSERT(daScaleStepMinNorm < daScaleStepMaxNorm, "Invalid daScaleStepMinNorm/daScaleStepMaxNorm ordering")

	return [daScaleStepMinNorm, daScaleStepMaxNorm]
End

/// @brief Calculate a list of DAScale values which need to be acquired in
///        addition so that the AP frequency differences between consecutive points is
///        smaller than `maxFrequencyChangePercent`.
static Function/WAVE PSQ_DS_GatherOvershootCorrection(STRUCT PSQ_DS_DAScaleParams &cdp, WAVE apfreqParam, WAVE DAScalesParam, WAVE/Z futureDAScalesHistoric)

	variable numEntries, numIterations, x, xp, y, yp, idx, i, xm, xs, frac
	variable maxFreqRelCond, minDaScaleCond, minFreqDistCond, alreadyMeasured, newDAScaleValue, DAScaleStepMin
	string msg

	ASSERT(PSQ_DS_DAScaleParamsAreFinite(cdp), "Invalid cdp values")

	Duplicate/FREE apfreqParam, apfreq
	WaveClear apfreqParam
	Duplicate/FREE DAScalesParam, DAScales
	WaveClear DAScalesParam

	numEntries = DimSize(apfreq, ROWS)
	ASSERT(numEntries == DimSize(DAScales, ROWS), "Non matching wave sizes")

	Make/FREE/D/N=(MINIMUM_WAVE_SIZE) results

	// ensure increasing values
	Sort apfreq, apfreq, DAScales

	ASSERT(numEntries > 1, "Expected at least two entries")
	numIterations = numEntries - 1
	for(i = 0; i < numIterations; i += 1)
		y  = apfreq[i]
		yp = apfreq[i + 1]
		x  = DAScales[i]
		xp = DAScales[i + 1]
		xs = (xp - x) / 2
		xm = x + xs

		frac           = yp / y - 1
		DAScaleStepMin = cdp.daScaleStepMinNorm * y

		maxFreqRelCond  = frac > (cdp.maxFrequencyChangePercent * PERCENT_TO_ONE)
		minFreqDistCond = abs(yp - y) > cdp.absFrequencyMinDistance
		minDaScaleCond  = xs > DAScaleStepMin
		alreadyMeasured = WaveExists(futureDAScalesHistoric) && !IsNaN(GetRowIndex(futureDAScalesHistoric, val = xm))

		newDAScaleValue = maxFreqRelCond && minFreqDistCond && minDaScaleCond && !alreadyMeasured

		sprintf msg, "DAScale entry %s: xm=%g, [x, xp]=[%g, %g], [y, yp]=[%g, %g], frac=%g, maxFreqChangePerc=%g, DAScaleStepMin=%g, idx=%g, maxFreqRelCond=%s, minDaScaleCond=%s, minFreqDistCond=%s, alreadyMeasured=%s", SelectString(newDAScaleValue, "not added", "added"), xm, x, xp, y, yp, frac, cdp.maxFrequencyChangePercent, DAScaleStepMin, idx, ToTrueFalse(maxFreqRelCond), ToTrueFalse(minDaScaleCond), ToTrueFalse(minFreqDistCond), ToTrueFalse(alreadyMeasured)
		DEBUGPRINT(msg)

		if(newDAScaleValue)
			EnsureLargeEnoughWave(results, indexShouldExist = idx)
			ASSERT(yp > y, "Incorrect data ordering")

			results[idx] = xm
			idx         += 1
		endif
	endfor

	if(idx == 0)
		return $""
	endif

	Redimension/N=(idx) results

	return results
End

/// @brief Calculate the new DAScale value for adaptive threshold using linear extrapolation
///
/// @param cdp calculation parameters
/// @param a   offset of the f-I straight line fit [Hz]
/// @param m   its slope [% Hz/pA]
/// @param x   DAScale of last acquired sweep [pA]
/// @param y   frequency value of last acquired sweep [Hz]
///
/// @return new DAScale value [pA]
static Function PSQ_DS_CalculateDAScale(STRUCT PSQ_DS_DAScaleParams &cdp, variable a, variable m, variable x, variable y)

	variable yp, xp
	variable absDAScaleStepMin, absDAScaleStepMax
	string msg

	ASSERT(PSQ_DS_DAScaleParamsAreFinite(cdp), "Invalid cdp values")

	absDAScaleStepMin = cdp.daScaleStepMinNorm * y
	absDAScaleStepMax = cdp.daScaleStepMaxNorm * y

	m = m / PICO_TO_ONE * PERCENT_TO_ONE

	ASSERT(cdp.maxFrequencyChangePercent > PSQ_DS_MAX_FREQ_OFFSET, "Invalid PSQ_DS_MAX_FREQ_OFFSET")
	yp = y * (1 + (cdp.maxFrequencyChangePercent - PSQ_DS_MAX_FREQ_OFFSET) * PERCENT_TO_ONE)
	xp = (yp - a) / (m)

	sprintf msg, "result %g with a=%g, m=%g, [x, xp]=[%g, %g], [y, yp]=[%g, %g], maxFrequencyChangePercent=%g, absDAScaleStepMin=%g, absDAScaleStepMax=%g\r", xp, a, m, x, xp, y, yp, cdp.maxFrequencyChangePercent, absDAScaleStepMin, absDAScaleStepMax
	DEBUGPRINT(msg)

	if(CheckIfSmall(m) || abs(x - xp) > absDAScaleStepMax)
		// avoid excessive too large values
		xp = x + absDAScaleStepMax

		sprintf msg, "corrected result: %g\r", xp
		DEBUGPRINT(msg)
	elseif(abs(y - yp) < cdp.absFrequencyMinDistance)
		// or too small values
		xp = x + absDAScaleStepMin

		sprintf msg, "corrected result: %g\r", xp
		DEBUGPRINT(msg)
	endif

	ASSERT(IsFinite(xp), "Invalid calculated DaScale value")

	return xp
End

static Function PSQ_DS_GatherAndWriteFrequencyToLabnotebook(string device, variable sweepNo, variable headstage)

	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE baselineQC = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(IsFinite(baselineQC[headstage]) && !baselineQC[headstage])
		return NaN
	endif

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		NVAR count           = $GetCount(device)

		Make/D/FREE apFreqCurrent = {overrideResults[0][count][%APFrequency]}
		WAVE/Z setting = GetLastSetting(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
		ASSERT(WaveExists(setting), "Missing DAScale LBN entry")
		Make/D/FREE DAScalesCurrent = {setting[headstage]}
	else
		[WAVE/D apFreqCurrent, WAVE/D DAScalesCurrent] = PSQ_DS_GatherFrequencyCurrentData(device, sweepNo, headstage, {sweepNo})
	endif

	WAVE apFreqLBN = LBN_GetNumericWave()
	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_FREQ)
	ASSERT(DimSize(apFreqCurrent, ROWS) == 1, "Invalid apFreqCurrent sizes")
	apFreqLBN[headstage] = apFreqCurrent[0]
	ED_AddEntryToLabnotebook(device, key, apFreqLBN, overrideSweepNo = sweepNo, unit = "Hz")
End

static Function [variable maxSlope, WAVE fitSlopes, WAVE DAScales] PSQ_DS_CalculateMaxSlopeAndWriteToLabnotebook(string device, variable sweepNo, variable headstage, variable fitSlope)

	string key
	variable idx, emptySCI

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	[WAVE fitSlopes, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_FI_SLOPE)
	[WAVE DAScales, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_DASCALE)

	if(IsNaN(fitSlope))
		return [NaN, fitSlopes, DAScales]
	endif

	maxSlope = max(WaveMax(fitSlopes), fitSlope)

	WAVE maxSlopeLBN = LBN_GetNumericWave()
	maxSlopeLBN[headstage] = maxSlope
	key                    = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_MAX_SLOPE)
	ED_AddEntryToLabnotebook(device, key, maxSlopeLBN, overrideSweepNo = sweepNo, unit = "% of Hz/pA")

	return [maxSlope, fitSlopes, DAScales]
End

/// @brief Determine the f-I slope QC
///
/// For a passing we need all of the following to be true:
/// - valid fit
/// - finite slope and not PSQ_DS_SKIPPED_FI_SLOPE
/// - slope must be slopePercentage smaller than the maximum slope
/// - slope must be acquired with a larger DAScale value than maximum slope
static Function PSQ_DS_CalculateReachedFinalSlope(variable validFit, WAVE fitSlopes, WAVE DAScales, variable fitSlope, variable maxSlope, variable slopePercentage)

	return validFit                                                                 \
	       && IsFinite(fitSlope)                                                    \
	       && IsFinite(maxSlope)                                                    \
	       && (fitSlope < maxSlope * (1 - (slopePercentage * PERCENT_TO_ONE)))      \
	       && PSQ_DS_IsValidFitSlopePosition(fitSlopes, DAScales, fitSlope, maxSlope)
End

static Function PSQ_DS_CalculateReachedFinalSlopeAndWriteToLabnotebook(string device, variable sweepNo, WAVE fitSlopes, WAVE DAScales, variable fitSlope, variable maxSlope, variable slopePercentage, variable validFit)

	variable reachedFinalSlope
	string   key

	reachedFinalSlope = PSQ_DS_CalculateReachedFinalSlope(validFit, fitSlopes, DAScales, fitSlope, maxSlope, slopePercentage)

	WAVE finalSlopeLBN = LBN_GetNumericWave()
	finalSlopeLBN[INDEP_HEADSTAGE] = reachedFinalSlope
	key                            = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
	ED_AddEntryToLabnotebook(device, key, finalSlopeLBN, overrideSweepNo = sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)
End

/// @brief Check if the given fitSlope is a suitable candidate for maxSlope
///
/// The condition is that the fitSlope is not acquired earlier than maxSlope as
/// we want to find the case there it drops off and not where it starts to
/// rise. We do use the DAScales values for this to ensure that measurements
/// from overshoot correction (aka fill-in) don't have a chance of interfering.
static Function PSQ_DS_IsValidFitSlopePosition(WAVE fitSlopes, WAVE DAScales, variable fitSlope, variable maxSlope)

	variable idxMax, idxSlope

	idxMax = GetRowIndex(fitSlopes, val = maxSlope, reverseSearch = 1)
	ASSERT(IsFinite(idxMax), "Could not find maxSlope in fitSlopes")

	idxSlope = GetRowIndex(fitSlopes, val = fitSlope, reverseSearch = 1)
	ASSERT(IsFinite(idxSlope), "Could not find fitSlope in fitSlopes")

	return DAScales[idxSlope] > DAScales[idxMax]
End

/// @brief Evaluate the complete adaptive supra threshold sweep
///
/// - Gather AP frequency and DAscale data
/// - Fetch the same data from the passing rheobase/supra sweeps and previous adaptive sweeps from the same SCI
/// - Create a new line fit for the last two points with differing AP frequency
/// - Check if the resulting fit slope is smaller than `slopePercentage`
///
/// @retval futureDAScales future DAScale values including the historic ones, @see PSQ_DS_GatherFutureDAScalesAndFrequency
static Function [WAVE futureDAScales] PSQ_DS_EvaluateAdaptiveThresholdSweep(string device, variable sweepNo, variable headstage, STRUCT PSQ_DS_DAScaleParams &cdp)

	string key, errMsg
	variable maxSlope, validFit, fitOffset, fitSlope

	WAVE textualValues   = GetLBTextualValues(device)
	WAVE numericalValues = GetLBNumericalValues(device)

	PSQ_DS_GatherAndWriteFrequencyToLabnotebook(device, sweepNo, headstage)

	[WAVE futureDAScales, WAVE apfreqs, WAVE DAScales] = PSQ_DS_GatherFutureDAScalesAndFrequency(device, sweepNo, headstage, cdp)

	[WAVE fitOffsetAll, WAVE fitSlopeAll, errMsg] = PSQ_DS_FitFrequencyCurrentData(device, sweepNo, apfreqs, DAScales, singleFit = 1)

	validFit = PSQ_DS_AreFitResultsValid(device, sweepNo, headstage, fitOffsetAll, fitSlopeAll)

	if(WaveExists(fitOffsetAll) && WaveExists(fitSlopeAll))
		ASSERT(DimSize(fitOffsetAll, ROWS) == 1 && DimSize(fitSlopeAll, ROWS) == 1, "Expected only one fit slope/offset")
		fitOffset = fitOffsetAll[0]
		fitSlope  = fitSlopeAll[0]

		WAVE fitOffsetLBN = LBN_GetNumericWave()
		fitOffsetLBN[headstage] = fitOffset
		key                     = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_FI_OFFSET)
		ED_AddEntryToLabnotebook(device, key, fitOffsetLBN, overrideSweepNo = sweepNo, unit = "Hz")

		WAVE fitSlopeLBN = LBN_GetNumericWave()
		fitSlopeLBN[headstage] = fitSlope
		key                    = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_FI_SLOPE)
		ED_AddEntryToLabnotebook(device, key, fitSlopeLBN, overrideSweepNo = sweepNo, unit = "% of Hz/pA")
	else
		fitOffset = NaN
		fitSlope  = NaN
	endif

	[maxSlope, WAVE fitSlopesAll, WAVE DAScalesAll] = PSQ_DS_CalculateMaxSlopeAndWriteToLabnotebook(device, sweepNo, headstage, fitSlope)

	PSQ_DS_CalculateReachedFinalSlopeAndWriteToLabnotebook(device, sweepNo, fitSlopesAll, DAScalesAll, fitSlope, maxSlope, cdp.slopePercentage, validFit)

	return [futureDAScales]
End

/// @brief Determine from the POST_SWEEP_EVENT if the set is already finished
///
/// We don't check here for passing/failing set QC but only if we need to continue acquisition.
static Function PSQ_DS_AdaptiveDetermineSweepQCResults(string device, variable sweepNo, variable headstage, variable numInvalidSlopeSweepsAllowed, variable numSweepsWithSaturation)

	string key
	variable numInvalidSlopes, samplingFrequencyPassed

	WAVE numericalValues = GetLBNumericalValues(device)

	// first error conditions
	key                     = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SAMPLING_PASS, query = 1)
	samplingFrequencyPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
	ASSERT(IsFinite(samplingFrequencyPassed), "Sampling frequency QC is missing")

	if(!samplingFrequencyPassed)
		PSQ_ForceSetEvent(device, headstage)
		RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
		return PSQ_RESULTS_DONE
	endif

	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_ENOUGH_FI_POINTS_PASS, query = 1)
	WAVE hasEnoughPoints = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(!IsConstant(hasEnoughPoints, 1))
		PSQ_ForceSetEvent(device, headstage)
		RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
		return PSQ_RESULTS_DONE
	endif

	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_VALID_SLOPE_PASS, query = 1)
	WAVE validSlopePasses = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	numInvalidSlopes = DimSize(validSlopePasses, ROWS) - Sum(validSlopePasses)
	ASSERT(IsNullOrPositiveAndFinite(numInvalidSlopes), "Invalid number of failed sweeps")

	if(numInvalidSlopes >= numInvalidSlopeSweepsAllowed)
		PSQ_ForceSetEvent(device, headstage)
		RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
		return PSQ_RESULTS_DONE
	endif

	if(PSQ_DS_AdaptiveIsFinished(device, sweepNo, headstage, numSweepsWithSaturation))
		PSQ_ForceSetEvent(device, headstage)
		RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
		return PSQ_RESULTS_DONE
	endif

	return PSQ_RESULTS_CONT
End

/// @brief Helper function for PSQ_DS_GetLabnotebookData
///
/// @param type One of @ref PSQDAScaleAdaptiveLBNTypeConstants
///
/// @retval currentSCI               labnotebook string (PSQ_FMT_XXX or stock entry) for data from the current SCI
/// @retval RhSuAd                   labnotebook PSQ_FMT_XXX string for RhSuAd data
/// @retval headstageContingencyMode One of HCM_INDEP/HCM_DEPEND
static Function [string currentSCI, string RhSuAd, variable headstageContingencyMode] PSQ_DS_GetLabnotebookKeyConstants(variable type)

	switch(type)
		case PSQ_DS_FI_SLOPE:
			return [PSQ_FMT_LBN_DA_fI_SLOPE, PSQ_FMT_LBN_DA_AT_RSA_fI_SLOPES, HCM_DEPEND]
		case PSQ_DS_FI_SLOPE_REACHED_PASS:
			return [PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS, PSQ_FMT_LBN_DA_AT_RSA_fI_SLOPES_PASS, HCM_INDEP]
		case PSQ_DS_FI_OFFSET:
			return [PSQ_FMT_LBN_DA_AT_FI_OFFSET, PSQ_FMT_LBN_DA_AT_RSA_FI_OFFSETS, HCM_DEPEND]
		case PSQ_DS_SWEEP_PASS:
			return [PSQ_FMT_LBN_SWEEP_PASS, PSQ_FMT_LBN_DA_AT_RSA_SWEEPS, HCM_INDEP]
		case PSQ_DS_SWEEP:
			return [NONE, PSQ_FMT_LBN_DA_AT_RSA_SWEEPS, HCM_INDEP]
		case PSQ_DS_APFREQ:
			return [PSQ_FMT_LBN_DA_AT_FREQ, PSQ_FMT_LBN_DA_AT_RSA_FREQ, HCM_DEPEND]
		case PSQ_DS_DASCALE:
			return ["Stim Scale Factor", PSQ_FMT_LBN_DA_AT_RSA_DASCALE, HCM_DEPEND]
		default:
			ASSERT(0, "Invalid type: " + num2str(type))
	endswitch
End

/// @brief Return some labnotebook entries for all passing sweeps from RhSuAd and the current SCI
static Function [WAVE data, variable emptySCI] PSQ_DS_GetLabnotebookData(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable headstage, variable type, [variable filterPassing, variable beforeSweepQCResult, variable fromRhSuAd])

	string key, keyCurrentSCI, keyRhSuAd
	variable hcmMode, idx

	if(ParamIsDefault(fromRhSuAd))
		fromRhSuAd = 0
	else
		fromRhSuAd = !!fromRhSuAd
	endif

	if(ParamIsDefault(beforeSweepQCResult))
		beforeSweepQCResult = 0
	else
		beforeSweepQCResult = !!beforeSweepQCResult
	endif

	if(ParamIsDefault(filterPassing))
		filterPassing = 0
	else
		filterPassing = !!filterPassing
	endif

	[keyCurrentSCI, keyRhSuAd, hcmMode] = PSQ_DS_GetLabnotebookKeyConstants(type)

	if(fromRhSuAd)
		key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, keyRhSuAd, query = 1)
		WAVE/T dataRhSuAdLBN = GetLastSetting(textualValues, sweepNo, key, UNKNOWN_MODE)

		Make/FREE/N=0 dataCurrentSCI
	else
		key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, keyRhSuAd, query = 1)
		WAVE/T dataRhSuAdLBN = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, key, headstage, UNKNOWN_MODE)

		switch(type)
			case PSQ_DS_SWEEP:
				WAVE/Z dataCurrentSCI = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
				break
			default:
				key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, keyCurrentSCI, query = 1)

				if(IsEmpty(key))
					// stock LBN entry
					key = keyCurrentSCI
				endif

				switch(hcmMode)
					case HCM_DEPEND:
						WAVE/Z dataCurrentSCI = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
						break
					case HCM_INDEP:
						WAVE/Z dataCurrentSCI = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
						break
					default:
						ASSERT(0, "Unsupported headstageContigencyMode")
				endswitch
				break
		endswitch

		if(!WaveExists(dataCurrentSCI))
			Make/FREE/N=0 dataCurrentSCI
		endif
	endif

	switch(hcmMode)
		case HCM_DEPEND:
			idx = headstage
			break
		case HCM_INDEP:
			idx = INDEP_HEADSTAGE
			break
		default:
			ASSERT(0, "Unsupported headstageContigencyMode")
	endswitch

	WAVE dataRhSuAd = ListToNumericWave(dataRhSuAdLBN[idx], ";")
	WaveClear dataRhSuAdLBN
	ASSERT(DimSize(dataRhSuAd, ROWS) > 0, "dataRhSuAd must not be empty")

	switch(type)
		case PSQ_DS_SWEEP_PASS:
			// we store the sweep number of the passing sweeps for RhSuAd
			// but actually only need if passing or not
			dataRhSuAd[] = !!dataRhSuAd[p]
			break
	endswitch

	if(filterPassing)
		ASSERT(type != PSQ_DS_SWEEP_PASS, "Does not make sense to filter passing sweeps")

		// we only store passing data for RhSuAd
		WAVE dataRhSuAdFiltered = dataRhSuAd

		if(fromRhSuAd)
			// and dataCurrentSCI is empty
			WAVE dataCurrentSCIFiltered = dataCurrentSCI
		else
			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
			WAVE/Z sweepPassed = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

			if(beforeSweepQCResult)
				if(!WaveExists(sweepPassed))
					// first sweep of SCI
					Make/FREE/N=1 sweepPassed
				endif

				key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
				WAVE baselinePassed = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

				// for the current sweep we don't yet have sweep QC values, but instead we just look at the baseline QC result
				sweepPassed[Inf] = baselinePassed[Inf]
			else
				ASSERT(WaveExists(sweepPassed), "Missing sweepPassed")
			endif

			WAVE/Z dataCurrentSCIFiltered = PSQ_DS_FilterPassingData(dataCurrentSCI, sweepPassed)

			if(!WaveExists(dataCurrentSCIFiltered))
				Make/FREE/N=0 dataCurrentSCIFiltered
			endif
		endif
	else
		WAVE dataRhSuAdFiltered     = dataRhSuAd
		WAVE dataCurrentSCIFiltered = dataCurrentSCI
	endif

	if(DimSize(dataCurrentSCIFiltered, ROWS) == 0)
		return [dataRhSuAdFiltered, 1]
	endif

	Concatenate/FREE/NP=(ROWS) {dataRhSuAdFiltered, dataCurrentSCIFiltered}, dataAll

	return [dataAll, 0]
End

static Function PSQ_DS_AdaptiveIsFinished(string device, variable sweepNo, variable headstage, variable numSweepsWithSaturation, [variable fromRhSuAd])

	string key
	variable measuredAllFutureDAScales, numFound, i, numSlopes, emptySCI

	if(ParamIsDefault(fromRhSuAd))
		fromRhSuAd = 0
	else
		fromRhSuAd = !!fromRhSuAd
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	if(!fromRhSuAd)
		key                       = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES_PASS, query = 1)
		measuredAllFutureDAScales = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
		ASSERT(IsFinite(measuredAllFutureDAScales), "Invalid measured all future DAScales QC")

		// still work to do
		if(!measuredAllFutureDAScales)
			return 0
		endif

		// pass conditions
		key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_RSA_VALID_SLOPE_PASS, query = 1)
		WAVE initialFISlopeValid = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

		if(!initialFISlopeValid[headstage])
			return 1
		endif
	endif

	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DASCALE_OOR, query = 1)
	WAVE/Z DAScaleOOR = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(WaveExists(DAScaleOOR) && DAScaleOOR[headstage])
		return 1
	endif

	[WAVE sweepPassed, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_SWEEP_PASS, fromRhSuAd = fromRhSuAd)

	if(DimSize(sweepPassed, ROWS) < numSweepsWithSaturation)
		return 0
	endif

	[WAVE fitSlopeReached, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_FI_SLOPE_REACHED_PASS, fromRhSuAd = fromRhSuAd)

	// slope is determined between sweeps so we have always one sweep more than slopes
	ASSERT(DimSize(sweepPassed, ROWS) == (DimSize(fitSlopeReached, ROWS) + 1), "Unmatched sweepPassed and fitSlopeReached waves")

	// we want numSweepsWithSaturation sweeps with passing f-I slope QC and sweep QC
	// and there should not be sweeps with failing f-I slope QC in between
	numSlopes = DimSize(fitSlopeReached, ROWS)
	for(i = 0; i < numSlopes; i += 1)
		// fiSlopeReached[i] holds the f-I slope QC value between sweep i and i + 1
		if(!sweepPassed[i + 1])
			continue
		endif

		// from here on all sweeps pass
		if(!fitSlopeReached[i])
			numFound = 0
			continue
		endif

		numFound += 1
	endfor

	// numFound > numSweepsWithSaturation can happen if we have futureDAScales left to measure
	return numFound >= numSweepsWithSaturation
End

static Function [WAVE futureDAScales, WAVE apfreq, WAVE DAScales] PSQ_DS_GatherFutureDAScalesAndFrequency(string device, variable sweepNo, variable headstage, STRUCT PSQ_DS_DAScaleParams &cdp)

	string   key
	variable emptySCI

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES, query = 1)
	WAVE/T/Z futureDAScalesHistoricLBN = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(WaveExists(futureDAScalesHistoricLBN))
		WAVE/D/Z futureDAScalesHistoric = ListToNumericWave(futureDAScalesHistoricLBN[headstage], ";")
	else
		Make/FREE/D/N=0 futureDAScalesHistoric
	endif

	[WAVE DAScales, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_DASCALE, filterPassing = 1, beforeSweepQCResult = 1)
	[WAVE apfreq, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_APFREQ, filterPassing = 1, beforeSweepQCResult = 1)

	if(!emptySCI)
		WAVE/D/Z futureDAScalesFromLastSweep = PSQ_DS_GatherOvershootCorrection(cdp, apfreq, DAScales, futureDAScalesHistoric)

		if(WaveExists(futureDAScalesFromLastSweep))
			Concatenate/FREE/NP=(ROWS) {futureDAScalesFromLastSweep}, futureDAScalesHistoric
		endif
	else
		WaveClear apfreq, DAScales
	endif

	WAVE futureDAScales = futureDAScalesHistoric
	WaveClear futureDAScalesHistoric, futureDAScalesFromLastSweep

	return [futureDAScales, apfreq, DAScales]
End

static Function PSQ_DS_CalcFutureDAScalesAndStoreInLBN(string device, variable sweepNo, variable headstage, WAVE futureDAScales)

	variable measuredAllFutureDAScales, index
	string key, msg

	WAVE/T futureDAScalesLBN = LBN_GetTextWave()
	futureDAScalesLBN[headstage] = NumericWaveToList(futureDAScales, ";", format = "%.15g")
	key                          = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES)
	ED_AddEntryToLabnotebook(device, key, futureDAScalesLBN, overrideSweepNo = sweepNo)

	WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(device)
	index = DAScalesIndex[headstage]

	sprintf msg, "futureDAScales = %s, index = %g", futureDAScalesLBN[headstage], index
	DEBUGPRINT(msg)

	measuredAllFutureDAScales = (DimSize(futureDAScales, ROWS) == 0) || (DimSize(futureDAScales, ROWS) == (index + 1))

	WAVE measuredAllFutureDAScalesLBN = LBN_GetNumericWave()
	measuredAllFutureDAScalesLBN[INDEP_HEADSTAGE] = measuredAllFutureDAScales
	key                                           = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES_PASS)
	ED_AddEntryToLabnotebook(device, key, measuredAllFutureDAScalesLBN, overrideSweepNo = sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)
End

/// @brief Return the entries of data which have passing state in booleanQC.
///
/// Both data and booleanQC are usually from the full SCI.
static Function/WAVE PSQ_DS_FilterPassingData(WAVE/Z data, WAVE/Z booleanQC, [variable inBetween])

	if(!WaveExists(data) || DimSize(data, ROWS) == 0)
		return $""
	endif

	if(ParamIsDefault(inBetween))
		inBetween = 0
	else
		inBetween = !!inBetween
	endif

	ASSERT(WaveExists(booleanQC), "Expected booleanQC wave when having a valid data wave")

	Duplicate/FREE data, indices

	if(inBetween)
		ASSERT(DimSize(data, ROWS) + 1 == DimSize(booleanQC, ROWS), "Umatched wave sizes for inBetween")
		indices[] = booleanQC[p + 1] == 1 ? NaN : p
	else
		ASSERT(DimSize(data, ROWS) == DimSize(booleanQC, ROWS), "Umatched wave sizes for inBetween")
		indices[] = booleanQC[p] == 1 ? NaN : p
	endif

	WAVE/Z indicesToRemove = ZapNaNs(indices)

	Duplicate/FREE data, passingData

	if(!WaveExists(indicesToRemove))
		return passingData
	endif

	DeleteWavePoint(passingData, ROWS, indices = indicesToRemove)

	if(DimSize(passingData, ROWS) == 0)
		return $""
	endif

	return passingData
End

static Function/WAVE PSQ_DS_GetPassingDAScaleSweeps(WAVE numericalValues, variable passingSweep, variable headstage)

	string key

	if(!IsValidSweepNumber(passingSweep))
		return $""
	endif

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, passingSweep, headstage)
	ASSERT(WaveExists(sweeps), "Missing sweeps from passing DAScale SCI")

	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	WAVE sweepsQC = GetLastSettingIndepEachSCI(numericalValues, passingSweep, key, headstage, UNKNOWN_MODE)

	WAVE/Z passingSweeps = PSQ_DS_FilterPassingData(sweeps, sweepsQC)

	return passingSweeps
End

static Function/WAVE PSQ_DS_GetPassingRheobaseSweeps(WAVE numericalValues, variable passingRheobaseSweep, variable headstage)
	string key

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, passingRheobaseSweep, headstage)
	ASSERT(WaveExists(sweeps), "Missing sweeps from passing rheobase SCI")

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE baselineQC = GetLastSettingEachSCI(numericalValues, passingRheobaseSweep, key, headstage, UNKNOWN_MODE)

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_ASYNC_PASS, query = 1)
	WAVE asyncQC = GetLastSettingIndepEachSCI(numericalValues, passingRheobaseSweep, key, headstage, UNKNOWN_MODE)

	ASSERT(DimSize(baselineQC, ROWS) == DimSize(asyncQC, ROWS), "Mismatched row sizes")
	Duplicate/FREE baselineQC, allQC

	// we don't need to check PSQ_FMT_LBN_SAMPLING_PASS here as failing that always makes the whole SCI fail
	allQC[] = baselineQC[p] && asyncQC[p]

	WAVE passingSweeps = PSQ_DS_FilterPassingData(sweeps, allQC)

	return passingSweeps
End

static Function/WAVE PSQ_DS_GetPassingRhSuAdSweepsAndStoreInLBN(string device, variable sweepNo, variable headstage, string params)

	variable passingSupraSweep, passingRheobaseSweep, failingAdaptiveSweep
	string key

	passingSupraSweep = PSQ_GetLastPassingDAScale(device, headstage, PSQ_DS_SUPRA)

	if(!IsValidSweepNumber(passingSupraSweep))
		printf "(%s): Could not find a passing set QC from previous DAScale runs in \"Supra\" mode.\r", device
		ControlWindowToFront()
		return $""
	endif

	passingRheobaseSweep = PSQ_GetLastPassingLongRHSweep(device, headstage, PSQ_RHEOBASE_DURATION)

	if(!IsValidSweepNumber(passingRheobaseSweep))
		printf "(%s): Could not find a passing set QC from previous Rheobase runs.\r", device
		ControlWindowToFront()
		return $""
	endif

	failingAdaptiveSweep = PSQ_GetPreviousSetQCFailingAdaptive(device, headstage, params)

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		WAVE sweeps          = JWN_GetNumericWaveFromWaveNote(overrideResults, "/PassingRhSuAdSweeps")
		JWN_SetNumberInWaveNote(overrideResults, "/FailingAdaptiveSweep", failingAdaptiveSweep)

		// consistency checks
		WAVE DAScalesRhSuAd = JWN_GetNumericWaveFromWaveNote(overrideResults, "/DAScalesRhSuAd")
		ASSERT(DimSize(DAScalesRhSuAd, ROWS) == DimSize(sweeps, ROWS), "Mismatched sizes between DAScalesRhSuAd and PassingRhSuAdSweeps")
		WAVE APFreqRhSuAd = JWN_GetNumericWaveFromWaveNote(overrideResults, "/APFrequenciesRhSuAd")
		ASSERT(DimSize(APFreqRhSuAd, ROWS) == DimSize(sweeps, ROWS), "Mismatched sizes between APFreqRhSuAd and PassingRhSuAdSweeps")
	else
		WAVE numericalValues = GetLBNumericalValues(device)

		WAVE   passingRheobaseSweeps = PSQ_DS_GetPassingRheobaseSweeps(numericalValues, passingRheobaseSweep, headstage)
		WAVE   passingSupraSweeps    = PSQ_DS_GetPassingDAScaleSweeps(numericalValues, passingSupraSweep, headstage)
		WAVE/Z passingAdaptiveSweeps = PSQ_DS_GetPassingDAScaleSweeps(numericalValues, failingAdaptiveSweep, headstage)

		if(!WaveExists(passingAdaptiveSweeps))
			Make/N=0/FREE passingAdaptiveSweeps
		endif

		Concatenate/NP=(ROWS)/FREE {passingRheobaseSweeps, passingSupraSweeps, passingAdaptiveSweeps}, sweeps
	endif

	WAVE/T RhSuAdSweepsLBN = LBN_GetTextWave()
	RhSuAdSweepsLBN[INDEP_HEADSTAGE] = NumericWaveToList(sweeps, ";", format = "%d")
	key                              = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_RSA_SWEEPS)
	ED_AddEntryToLabnotebook(device, key, RhSuAdSweepsLBN, overrideSweepNo = sweepNo)

	return sweeps
End

/// @brief Calculate the minimum and maximum step widths for DAScale normalized
///
/// Stored in the labnotebook.
///
/// Multiply by `AP Frequency` to get scaled values.
static Function [variable daScaleStepMinNorm, variable daScaleStepMaxNorm] PSQ_DS_CalculateAndStoreDAScaleStepWidths(string device, variable sweepNo, WAVE apfreqRhSuAd, WAVE DAScalesRhSuAd, variable maxFrequencyChangePercent, variable dascaleStepWidthMinMaxRatio, variable fallbackDAScaleRangeFac)

	variable daScaleMinStepWidth, daScaleMaxStepWidth, minimum, maximum
	string code, databrowser, fitKey, key
	string str = ""

	fitKey = "Fit result rheobase and supra"

	sprintf code, "freq = [%s]\r", NumericWaveToList(apfreqRhSuAd, ",", format = PERCENT_F_MAX_PREC, trailSep = 0)
	str += code
	sprintf code, "dascale = [%s]\r", NumericWaveToList(DAScalesRhSuAd, ",", format = PERCENT_F_MAX_PREC, trailSep = 0)
	str += code
	sprintf code, "result = fit($dascale, $freq, fitline())\r"
	str += code
	sprintf code, "store(\"%s\", $result)", fitKey
	str += code

	databrowser = PSQ_ExecuteSweepFormula(device, str)

	WAVE/T textualResultsValues = BSP_GetLogbookWave(databrowser, LBT_RESULTS, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)

	sprintf key, "Sweep Formula store [%s]", fitKey
	WAVE/Z fitResult = PSQ_GetSweepFormulaResultWave(textualResultsValues, key)
	ASSERT(WaveExists(fitResult), "Missing fitResult")

	WAVE/Z fitCoeff = JWN_GetNumericWaveFromWaveNote(fitResult, SF_META_USER_GROUP + SF_META_FIT_COEFF)
	ASSERT(WaveExists(fitCoeff), "Missing fitResult")

	WAVE/Z fitParams = JWN_GetTextWaveFromWaveNote(fitResult, SF_META_USER_GROUP + SF_META_FIT_PARAMETER)
	ASSERT(WaveExists(fitParams), "Expected fit parameter wave")
	SetDimensionLabels(fitCoeff, TextWaveToList(fitParams, ";"), ROWS)

	// Condition for freq:
	// y_2 = y_1 * (1 + mfcp)
	//
	// two points: x_1, y_1 and x_2, y_2 with slope m and offset d
	// dy = y_2 - y_1
	// dx = x_2 - x_1
	// m = dy / dx
	//
	// -> dx = dy / m = (y_2 - y_1) / m = (y_1 * (1 + mfcp) - y_1) / m = y1 * mfcp/m
	//
	// so for unity y (APFrequency) this gives:
	// dx = mfcp / m
	// we use the absolute value here to cope with a negative slope
	if(!CheckIfSmall(fitCoeff[%Slope]))
		daScaleMinStepWidth = (maxFrequencyChangePercent * PERCENT_TO_ONE) / abs(fitCoeff[%Slope])
	else
		[minimum, maximum] = WaveMinAndMax(DAScalesRhSuAd)
		daScaleMinStepWidth = fallbackDAScaleRangeFac * (maximum - minimum)
	endif

	ASSERT(IsFinite(daScaleMinStepWidth), "Minimum DAScale stepwidth must be finite")

	daScaleMaxStepWidth = daScaleMinStepWidth * dascaleStepWidthMinMaxRatio
	ASSERT(daScaleMinStepWidth < daScaleMaxStepWidth, "Minimum DAScale stepwidth must be smaller than maximum")

	WAVE minStepWidth = LBN_GetNumericWave()
	minStepWidth[INDEP_HEADSTAGE] = daScaleMinStepWidth
	key                           = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_MIN_DASCALE_NORM)
	ED_AddEntryToLabnotebook(device, key, minStepWidth, overrideSweepNo = sweepNo, unit = LABNOTEBOOK_NO_UNIT)

	WAVE maxStepWidth = LBN_GetNumericWave()
	maxStepWidth[INDEP_HEADSTAGE] = daScaleMaxStepWidth
	key                           = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_MAX_DASCALE_NORM)
	ED_AddEntryToLabnotebook(device, key, maxStepWidth, overrideSweepNo = sweepNo, unit = LABNOTEBOOK_NO_UNIT)

	return [daScaleMinStepWidth, daScaleMaxStepWidth]
End

static Function [variable fitOffset, variable fitSlope, variable DAScale, variable apfreq] PSQ_DS_GetValuesOfLargestDAScale(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, variable headstage)

	variable emptySCI, offset, i, numEntries, maxValue, maxLoc

	[WAVE apfreqAll, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_APFREQ, filterPassing = 1)
	ASSERT(!emptySCI, "Unexpected emptySCI")
	[WAVE fitSlopeAll, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_FI_SLOPE, filterPassing = 1)
	ASSERT(!emptySCI, "Unexpected emptySCI")
	[WAVE fitOffsetAll, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_FI_OFFSET, filterPassing = 1)
	ASSERT(!emptySCI, "Unexpected emptySCI")
	[WAVE DAScaleAll, emptySCI] = PSQ_DS_GetLabnotebookData(numericalValues, textualValues, sweepNo, headstage, PSQ_DS_DASCALE, filterPassing = 1)
	ASSERT(!emptySCI, "Unexpected emptySCI")

	// get the largest value with the highest index
	maxValue   = -Inf
	numEntries = DimSize(DAScaleAll, ROWS)
	for(i = numEntries - 1; i >= 0; i -= 1)
		if(DAScaleAll[i] > maxValue)
			maxValue = DAScaleAll[i]
			maxLoc   = i
		endif
	endfor

	// highest DAScale/APFreq is at maxloc
	apfreq  = apfreqAll[maxLoc]
	DAScale = DAScaleAll[maxLoc]

	// find the rest by indexing relative from the end as we have fewer fitOffset/fitSlope entries in total
	// but a 1:1 correspondence in the SCI data which is at the end
	offset = DimSize(DAScaleAll, ROWS) - maxLoc

	fitOffset = fitOffsetAll[DimSize(fitOffsetAll, ROWS) - offset]
	fitSlope  = fitSlopeAll[DimSize(fitSlopeAll, ROWS) - offset]

	return [fitOffset, fitSlope, DAScale, apfreq]
End

static Structure PSQ_DS_DAScaleParams
	variable absFrequencyMinDistance, maxFrequencyChangePercent
	variable daScaleStepMinNorm, daScaleStepMaxNorm, slopePercentage
EndStructure

static Function PSQ_DS_DAScaleParamsAreFinite(STRUCT PSQ_DS_DAScaleParams &cdp)

	return IsFinite(cdp.absFrequencyMinDistance)      \
	       && IsFinite(cdp.maxFrequencyChangePercent) \
	       && IsFinite(cdp.daScaleStepMinNorm)        \
	       && IsFinite(cdp.daScaleStepMaxNorm)        \
	       && IsFinite(cdp.slopePercentage)
End

static Function PSQ_DS_InitDAScaleParams(STRUCT PSQ_DS_DAScaleParams &cdp)

	cdp.absFrequencyMinDistance   = NaN
	cdp.maxFrequencyChangePercent = NaN
	cdp.daScaleStepMinNorm        = NaN
	cdp.daScaleStepMaxNorm        = NaN
	cdp.slopePercentage           = NaN
End

/// @brief Help strings for common parameters
///
/// Not every analysis function uses every parameter though.
static Function/S PSQ_GetHelpCommon(variable type, string name)

	string freqITC, freqNI, freqSU

	strswitch(name)
		case "AsyncQCChannels":
			return "List of asynchronous channels with alarm enabled, which must *not* be in alarm state."
		case "BaselineChunkLength":
			return "Length of a baseline QC chunk to evaluate (defaults to " + num2str(PSQ_BL_EVAL_RANGE) + ")"
		case "BaselineRMSLongThreshold":
			return "Threshold value in mV for the long RMS baseline QC check (defaults to " + num2str(PSQ_RMS_LONG_THRESHOLD) + ")"
		case "BaselineRMSShortThreshold":
			return "Threshold value in mV for the short RMS baseline QC check (defaults to " + num2str(PSQ_RMS_SHORT_THRESHOLD) + ")"
		case "BaselineTargetVThreshold":
			return "Threshold value in mV for the target V baseline QC check (defaults to " + num2str(PSQ_TARGETV_THRESHOLD) + ")"
		case "FailedLevel":
			return "Absolute level for spike search"
		case "MaxLeakCurrent":
			return "Maximum current [pA] which is allowed in the pre pulse baseline"
		case "NextIndexingEndStimSetName":
			return "Next indexing end stimulus set which should be set in case of success.\r Also enables indexing."
		case "NextStimSetName":
			return "Next stimulus set which should be set in case of success"
		case "NumberOfFailedSweeps":
			return "Number of failed sweeps which marks the set as failed."
		case "NumberOfTestpulses":
			return "Expected number of testpulses in the stimset"
		case "SamplingFrequency":
			freqITC = num2str(PSQ_GetDefaultSamplingFrequency("ITC16", type))
			freqNI  = num2str(PSQ_GetDefaultSamplingFrequency("Dev1", type))
			freqSU  = num2str(PSQ_GetDefaultSamplingFrequency(DEVICE_SUTTER_NAME_START_CLEAN + "1", type))
			return "Required sampling frequency for the acquired data [kHz]. Defaults to ITC:" + freqITC + " NI:" + freqNI + " Sutter:" + freqSU + "."
		case "SamplingMultiplier":
			return "Sampling multiplier, use 1 for no multiplier"
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

static Function/S PSQ_CheckParamCommon(string name, STRUCT CheckParametersStruct &s, [variable maxThreshold])
	variable val
	string   str

	if(ParamIsDefault(maxThreshold))
		maxThreshold = 20
	else
		ASSERT(IsFinite(maxThreshold), "Invalid value")
	endif

	strswitch(name)
		case "AsyncQCChannels":
			WAVE/Z wv = AFH_GetAnalysisParamWave(name, s.params)
			if(!WaveExists(wv))
				return "Empty wave"
			endif

			Make/FREE/N=(NUM_ASYNC_CHANNELS)/D validValues = p
			WAVE/Z diff = GetSetDifference(wv, validValues)

			if(WaveExists(diff))
				return "Invalid entries in wave: " + NumericWaveToList(wv, ";")
			endif
			break
		case "BaselineChunkLength":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0))
				return "Invalid value " + num2str(val)
			endif
			break
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "BaselineTargetVThreshold":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0 && val <= maxThreshold))
				return "Invalid value " + num2str(val)
			endif
			break
		case "DAScaleOperator":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(cmpstr(str, "+") && cmpstr(str, "*"))
				return "Invalid string " + str
			endif
			break
		case "DAScaleModifier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 1000))
				return "Not a precentage"
			endif
			break
		case "FailedLevel":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val))
				return "Must be a finite value"
			endif
			break
		case "NextStimSetName":
		case "NextIndexingEndStimSetName":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			WAVE/Z stimset = WB_CreateAndGetStimSet(str)
			if(!WaveExists(stimset))
				return "The specified stimset cannot be found"
			endif
			break
		case "NumberOfFailedSweeps":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val) || !IsInteger(val) || val <= 0 || val > IDX_NumberOfSweepsInSet(s.setName))
				return "Must be a finite non-zero integer and smaller or equal to the number of sweeps in the stimset"
			endif
			break
		case "NumberOfTestpulses":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0 && val <= 100))
				return "Invalid value " + num2str(val)
			endif
			break
		case "MaxLeakCurrent":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0 && val <= 1000))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingFrequency":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 1000))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SamplingMultiplier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsValidSamplingMultiplier(val))
				return "Invalid value " + num2str(val)
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

/// @brief Require parameters from stimset
Function/S PSQ_DAScale_GetParams()
	return "[AbsFrequencyMinDistance:variable],"      + \
	       "AsyncQCChannels:wave,"                    + \
	       "[BaselineRMSLongThreshold:variable],"     + \
	       "[BaselineRMSShortThreshold:variable],"    + \
	       "[BaselineTargetVThreshold:variable],"     + \
	       "[DAScaleRangeFactor:variable],"           + \
	       "[DAScaleModifier:variable],"              + \
	       "[DaScaleStepWidthMinMaxRatio:variable],"  + \
	       "DAScales:wave,"                           + \
	       "[FinalSlopePercent:variable],"            + \
	       "[MaximumSpikeCount:variable],"            + \
	       "[MinimumSpikeCount:variable],"            + \
	       "[OffsetOperator:string],"                 + \
	       "OperationMode:string,"                    + \
	       "[SamplingFrequency:variable],"            + \
	       "SamplingMultiplier:variable,"             + \
	       "[ShowPlot:variable],"                     + \
	       "[SlopePercentage:variable],"              + \
	       "[NumInvalidSlopeSweepsAllowed:variable]," + \
	       "[MaxFrequencyChangePercent:variable],"    + \
	       "[NumSweepsWithSaturation:variable]"
End

Function/S PSQ_DAScale_GetHelp(string name)

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "BaselineTargetVThreshold":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_GetHelpCommon(PSQ_DA_SCALE, name)
		case "DAScaleModifier":
			return "Percentage how the DAScale value is adapted if it is outside of the " \
			       + "MinimumSpikeCount\"/\"MaximumSpikeCount\" band. Only for \"Supra\"."
		case "DAScaleRangeFactor":
			return "Fallback factor to apply to the input DAScale range for calculating "                                   \
			       + "the DAScale minimum step width when all previous f-I data from Rheobase/Supra/Adaptive is constant. " \
			       + "Only for \"AdaptiveSupra\"."
		case "DaScaleStepWidthMinMaxRatio":
			return "Number of times the maximum DAScale step width is larger than the calculated minimum. " + \
			       "Only for \"AdaptiveSupra\"."
		case "DAScales":
			return "DA Scale Factors in pA"
		case "AbsFrequencyMinDistance":
			return "Minimum absolute frequency distance for DAScale estimation. Only for \"AdaptiveSupra\"."
		case "MaxFrequencyChangePercent":
			return "The maximum allowed difference for the frequency for two consecutive measurements. "           \
			       + "In case this value is overshot, we redo the measurement with a fitting DAScale in-between. " \
			       + "Only for \"AdaptiveSupra\"."
		case "NumSweepsWithSaturation":
			return "Number of required consecutive passing sweeps to have passing sweep QC and f-I slope QC, defaults to 2. " + \
			       "Only for \"AdaptiveSupra\"."
		case "NumInvalidSlopeSweepsAllowed":
			return "Number of allowed sweeps with invalid f-I fit slope. Only for \"AdaptiveSupra\"."
		case "SlopePercentage":
			return "Once the slope of the f-I fit is x percentage smaller "                                     \
			       + "compared with the maximum slope, the stimset cycle is stopped. Only for \"AdaptiveSupra\"."
		case "FinalSlopePercent":
			return "As additional passing criteria the slope of the f-I plot must be larger than this value. " \
			       + "Note: The slope is used in percent. Only for \"Supra\"."
		case "MaximumSpikeCount":
			return "The upper limit of the number of spikes. Only for \"Supra\"."
		case "MinimumSpikeCount":
			return "The lower limit of the number of spikes. Only for \"Supra\"."
		case "OffsetOperator":
			return "Set the math operator to use for "                                    \
			       + "combining the rheobase DAScale value from the previous run and "    \
			       + "the DAScales values. Valid strings are \"+\" (addition) and \"*\" " \
			       + "(multiplication). Only for \"Supra\" and defaults to \"+\"."
		case "OperationMode":
			return "Operation mode of the analysis function. Can be either \"Sub\"/\"Supra\"/\"AdaptiveSupra\"."
		case "ShowPlot":
			return "Show the resistance (\"Sub\") or the f-I (\"Supra\") plot, defaults to true."
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_DAScale_CheckParam(string name, STRUCT CheckParametersStruct &s)

	variable val
	string   str

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "BaselineTargetVThreshold":
		case "DAScaleModifier":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_CheckParamCommon(name, s)
		case "DAScales":
			WAVE/D/Z wv = AFH_GetAnalysisParamWave(name, s.params)
			if(!WaveExists(wv))
				return "Wave must exist"
			endif

			WaveStats/Q/M=1 wv
			if(V_numNans > 0 || V_numInfs > 0)
				return "Wave must neither have NaNs nor Infs"
			elseif(V_npnts == 0)
				return "Wave must have at least one entry"
			endif
			break
		case "AbsFrequencyMinDistance":
		case "MaxFrequencyChangePercent":
		case "DAScaleRangeFactor":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsNullOrPositiveAndFinite(val))
				return "Invalid value"
			endif
			break
		case "DaScaleStepWidthMinMaxRatio":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(IsFinite(val) && val > 1.0))
				return "Invalid value"
			endif
			break
		case "NumInvalidSlopeSweepsAllowed":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= IDX_NumberOfSweepsInSet(s.setName)))
				return "Invalid range"
			endif
			break
		case "NumSweepsWithSaturation":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 1))
				return "Invalid range"
			endif
			break
		case "OperationMode":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(!PSQ_DS_IsValidMode(str))
				return "Invalid string " + str
			endif
			break
		case "OffsetOperator":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(cmpstr(str, "+") && cmpstr(str, "*"))
				return "Invalid string " + str
			endif
			break
		case "ShowPlot":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(val != 0 && val != 1)
				return "Invalid string " + num2str(val)
			endif
			break
		case "SlopePercentage":
		case "FinalSlopePercent":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 100))
				return "Not a precentage"
			endif
			break
		case "MinimumSpikeCount":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0))
				return "Not a positive integer or zero"
			endif
			break
		case "MaximumSpikeCount":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0))
				return "Not a positive integer or zero"
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch

	// check ordering of min/max
	strswitch(name)
		case "MinimumSpikeCount":
		case "MaximumSpikeCount":
			if(AFH_GetAnalysisParamNumerical("MinimumSpikeCount", s.params)   \
			   >= AFH_GetAnalysisParamNumerical("MaximumSpikeCount", s.params))
				return "The minimum/maximum spike counts are not ordered properly"
			endif
			break
	endswitch

	// check that all three are present
	strswitch(name)
		case "MinimumSpikeCount":
		case "MaximumSpikeCount":
		case "DAScaleModifier":
			if(IsNaN(AFH_GetAnalysisParamNumerical("MinimumSpikeCount", s.params))    \
			   || IsNaN(AFH_GetAnalysisParamNumerical("MaximumSpikeCount", s.params)) \
			   || IsNaN(AFH_GetAnalysisParamNumerical("DAScaleModifier", s.params)))
				return "One of MinimumSpikeCount/MaximumSpikeCount/DAScaleModifier is not present"
			endif
			break
	endswitch

	return ""
End

/// @brief Patch Seq Analysis function to find a suitable DAScale
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has 500ms of pre pulse baseline, a non-zero pulse and at least 1000ms post pulse baseline.
/// - Each 500ms (#PSQ_BL_EVAL_RANGE) of the baseline is a chunk
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the override wave,
/// @see PSQ_CreateOverrideResults().
///
/// Reading the results from the labnotebook:
///
/// \rst
/// .. code-block:: igorpro
///
///    WAVE numericalValues = GetLBNumericalValues(device)
///
///    // set properties
///
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS, query = 1)
///    setPassed = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
///
///    if(setPassed)
///      // set passed
///    else
///      // set did not pass
///    endif
///
///    // single sweep properties
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
///    sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // chunk (500ms portions of the baseline) properties
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_CHUNK_PASS, chunk = chunk, query = 1)
///    chunkPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // single test properties
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_RMS_SHORT_PASS, chunk = chunk, query = 1)
///    rmsShortPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_RMS_LONG_PASS, chunk = chunk, query = 1)
///    rmsLongPassed  = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///    key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_TARGETV_PASS, chunk = chunk, query = 1)
///    targetVPassed  = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
///
///    // get fitted resistance from last passing sweep
///    // resistance for the first headstage can be found in resistanceFitted[0]
///    WAVE/Z resistanceFitted = GetLastSettingSCI(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_RESISTANCE_FIT, headstage, UNKNOWN_MODE)
/// \endrst
///
/// Decision logic flowchart:
///
/// \rst
/// .. image:: /dot/patch-seq-dascale.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with inserted TP, pre pulse baseline (-), pulse (*), and post pulse baseline (-).
///
///  |-|                 ***********************************
///  | |                 |                                 |
///  | |                 |                      \WWW/      |
///  | |                 |                      /   \      |
///  | |                 |                     /wwwww\     |
///  | |                 |                   _|  o_o  |_   |
///  | |                 |      \WWWWWWW/   (_   / \   _)  |
///  | |                 |    _/`  o_o  `\_   |  \_/  |    |
///  | |                 |   (_    (_)    _)  : ~~~~~ :    |
///  | |                 |     \ '-...-' /     \_____/     |
///  | |                 |     (`'-----'`)     [     ]     |
///  | |                 |      `"""""""`      `"""""`     |
///  | |                 |                                 |
/// -| |-----------------|                                 |--------------------------------------------
///
/// ascii art image from: http://ascii.co.uk/art/erniebert
///
/// @endverbatim
///
Function PSQ_DAScale(device, s)
	string                      device
	STRUCT AnalysisFunction_V3 &s

	variable val, totalOnsetDelay, DAScale, baselineQCPassed, passingSupraSweep
	variable i, numberOfSpikes, samplingFrequencyPassed, numPoints, numFailedSweeps
	variable index, ret, showPlot, V_AbortCode, V_FitError, err, enoughSweepsPassed
	variable sweepPassed, setPassed, length, minLength, reachedFinalSlope, fitOffset, fitSlope, apfreq, enoughFIPointsPassedQC
	variable minimumSpikeCount, maximumSpikeCount, daScaleModifierParam, measuredAllFutureDAScales, fallbackDAScaleRangeFac
	variable sweepsInSet, passesInSet, acquiredSweepsInSet, multiplier, asyncAlarmPassed, supraStimsetCycle
	variable daScaleStepMinNorm, daScaleStepMaxNorm, maxSlope, validFit, emptySCI, DAScaleOORQC, limitCheck, retCheckDAScale
	string msg, stimset, key, opMode, offsetOp, textboxString, str, errMsg
	variable daScaleOffset
	variable finalSlopePercent = NaN
	variable daScaleModifier, chunk
	variable numSweepsPass                = NaN
	variable slopePercentage              = NaN
	variable numInvalidSlopeSweepsAllowed = NaN
	variable maxFrequencyChangePercent    = NaN
	variable numSweepsWithSaturation      = NaN
	variable dascaleStepWidthMinMaxRatio  = NaN
	variable absFrequencyMinDistance      = NaN

	opMode     = AFH_GetAnalysisParamTextual("OperationMode", s.params)
	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

	WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(device)

	strswitch(opMode)
		case PSQ_DS_SUPRA:
			offsetOp          = AFH_GetAnalysisParamTextual("OffsetOperator", s.params, defValue = "+")
			finalSlopePercent = AFH_GetAnalysisParamNumerical("FinalSlopePercent", s.params, defValue = NaN)

			WAVE/D DAScales = AFH_GetAnalysisParamWave("DAScales", s.params)
			numSweepsPass = DimSize(DAScales, ROWS)

			break
		case PSQ_DS_SUB:
			offsetOp        = "+"
			daScaleOffset   = 0
			daScaleModifier = 0

			WAVE/D DAScales = AFH_GetAnalysisParamWave("DAScales", s.params)
			numSweepsPass = DimSize(DAScales, ROWS)

			break
		case PSQ_DS_ADAPT:
			offsetOp        = "+"
			daScaleOffset   = 0
			daScaleModifier = 0

			numSweepsPass = NaN

			slopePercentage              = AFH_GetAnalysisParamNumerical("SlopePercentage", s.params, defValue = PSQ_DA_SLOPE_PERCENTAGE_DEFAULT)
			numSweepsWithSaturation      = AFH_GetAnalysisParamNumerical("NumSweepsWithSaturation", s.params, defValue = PSQ_DA_NUM_SWEEPS_SATURATION)
			numInvalidSlopeSweepsAllowed = AFH_GetAnalysisParamNumerical("NumInvalidSlopeSweepsAllowed", s.params, defValue = PSQ_DA_NUM_INVALID_SLOPE_SWEEPS_ALLOWED)
			maxFrequencyChangePercent    = AFH_GetAnalysisParamNumerical("MaxFrequencyChangePercent", s.params, defValue = PSQ_DA_MAX_FREQUENCY_CHANGE_PERCENT)
			dascaleStepWidthMinMaxRatio  = AFH_GetAnalysisParamNumerical("DaScaleStepWidthMinMaxRatio", s.params, defValue = PSQ_DA_DASCALE_STEP_WITH_MIN_MAX_FACTOR)
			absFrequencyMinDistance      = AFH_GetAnalysisParamNumerical("AbsFrequencyMinDistance", s.params, defValue = PSQ_DA_ABS_FREQUENCY_MIN_DISTANCE)
			fallbackDAScaleRangeFac      = AFH_GetAnalysisParamNumerical("DAScaleRangeFactor", s.params, defValue = PSQ_DA_FALLBACK_DASCALE_RANGE_FAC)

			STRUCT PSQ_DS_DAScaleParams cdp
			PSQ_DS_InitDAScaleParams(cdp)
			cdp.maxFrequencyChangePercent = maxFrequencyChangePercent
			cdp.absFrequencyMinDistance   = absFrequencyMinDistance
			cdp.slopePercentage           = slopePercentage
			break
		default:
			ASSERT(0, "Invalid opMode")
	endswitch

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			length    = PSQ_GetDAStimsetLength(device, s.headstage)
			minLength = 3 * PSQ_BL_EVAL_RANGE
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", device, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", device
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_DA_SCALE, s.headstage, s.sweepNo)

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			DAScalesIndex[s.headstage] = 0

			strswitch(opMode)
				case PSQ_DS_SUB:
				case PSQ_DS_SUPRA:

					daScaleOffset = PSQ_DS_GetDAScaleOffset(device, s.headstage, opMode)
					if(!IsFinite(daScaleOffset))
						printf "(%s): Could not find a valid DAScale threshold value from previous rheobase runs with long pulses.\r", device
						ControlWindowToFront()
						return 1
					endif

					KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaI(device))
					KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaV(device))
					KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleRes(device))
					KillWindow/Z $RESISTANCE_GRAPH
					KillWindow/Z $SPIKE_FREQ_GRAPH

					break
				case PSQ_DS_ADAPT:
					WAVE/Z RhSuAdSweeps = PSQ_DS_GetPassingRhSuAdSweepsAndStoreInLBN(device, s.sweepNo, s.headstage, s.params)

					if(!WaveExists(RhSuAdSweeps))
						return 1
					endif

					if(TestOverrideActive())
						WAVE   overrideResults = GetOverrideResults()
						WAVE/Z apfreqRhSuAd    = JWN_GetNumericWaveFromWaveNote(overrideResults, "/APFrequenciesRhSuAd")
						WAVE/Z DAScalesRhSuAd  = JWN_GetNumericWaveFromWaveNote(overrideResults, "/DAScalesRhSuAd")
					else
						[WAVE apfreqRhSuAd, WAVE DAScalesRhSuAd] = PSQ_DS_GatherFrequencyCurrentData(device, s.sweepNo, s.headstage, RhSuAdSweeps, fromRhSuAd = 1)
					endif

					ASSERT(WaveExists(apfreqRhSuAd) && WaveExists(DAScalesRhSuAd), "Missing apfreq/DAScales wave from rheobase, supra, adaptive")

					numPoints = DimSize(apfreqRhSuAd, ROWS)
					ASSERT(numPoints == DimSize(DAScalesRhSuAd, ROWS), "Non-matching wave sizes")

					WAVE/T apfreqLBN = LBN_GetTextWave()
					apfreqLBN[s.headstage] = NumericWaveToList(apfreqRhSuAd, ";", format = "%.15g")
					key                    = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_RSA_FREQ)
					ED_AddEntryToLabnotebook(device, key, apfreqLBN, overrideSweepNo = s.sweepNo, unit = "Hz")

					WAVE/T DAScalesTextLBN = LBN_GetTextWave()
					DAScalesTextLBN[s.headstage] = NumericWaveToList(DAScalesRhSuAd, ";", format = "%.15g")
					key                          = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_RSA_DASCALE)
					ED_AddEntryToLabnotebook(device, key, DAScalesTextLBN, overrideSweepNo = s.sweepNo)

					[WAVE fitOffsetFromRhSuAd, WAVE fitSlopeFromRhSuAd, errMsg] = PSQ_DS_FitFrequencyCurrentData(device, s.sweepNo,          \
					                                                                                             apfreqRhSuAd, DAScalesRhSuAd)

					if(!WaveExists(fitOffsetFromRhSuAd) || !WaveExists(fitSlopeFromRhSuAd))
						printf "The f-I fit of the rheobase/supra data failed due to: \"%s\"\r", errMsg
						ControlWindowToFront()
						return 1
					endif

					[daScaleStepMinNorm, daScaleStepMaxNorm] = PSQ_DS_CalculateAndStoreDAScaleStepWidths(device, s.sweepNo, apfreqRhSuAd, DAScalesRhSuAd,                               \
					                                                                                     maxFrequencyChangePercent, dascaleStepWidthMinMaxRatio, fallbackDAScaleRangeFac)

					cdp.daScaleStepMinNorm = daScaleStepMinNorm
					cdp.daScaleStepMaxNorm = daScaleStepMaxNorm

					WAVE/T fitOffsetLBN = LBN_GetTextWave()
					fitOffsetLBN[s.headstage] = NumericWaveToList(fitOffsetFromRhSuAd, ";", format = "%.15g")
					key                       = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_RSA_FI_OFFSETS)
					ED_AddEntryToLabnotebook(device, key, fitOffsetLBN, overrideSweepNo = s.sweepNo, unit = "Hz")

					WAVE/T fitSlopeLBN = LBN_GetTextWave()
					fitSlopeLBN[s.headstage] = NumericWaveToList(fitSlopeFromRhSuAd, ";", format = "%.15g")
					key                      = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES)
					ED_AddEntryToLabnotebook(device, key, fitSlopeLBN, overrideSweepNo = s.sweepNo, unit = "% of Hz/pA")

					PSQ_DS_CreateSurveyPlotForUser(device, s.sweepNo, s.headstage, fromRhSuAd = 1)

					WAVE/D/Z futureDAScales = PSQ_DS_GatherOvershootCorrection(cdp, apfreqRhSuAd, DAScalesRhSuAd, $"")

					validFit = PSQ_DS_AreFitResultsValid(device, s.sweepNo, s.headstage, fitOffsetFromRhSuAd, fitSlopeFromRhSuAd, fromRhSuAd = 1)

					WAVE maxSlopeLBN = LBN_GetNumericWave()
					maxSlope                 = WaveMax(fitSlopeFromRhSuAd)
					maxSlopeLBN[s.headstage] = maxSlope
					key                      = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_MAX_SLOPE)
					ED_AddEntryToLabnotebook(device, key, maxSlopeLBN, overrideSweepNo = s.sweepNo, unit = "% of Hz/pA")

					Make/FREE/N=(DimSize(fitSlopeFromRhSuAd, ROWS)) fitSlopeQCfromRhSuAd = PSQ_DS_CalculateReachedFinalSlope(validFit, fitSlopeFromRhSuAd, DAScalesRhSuAd, fitSlopeFromRhSuAd[p], maxSlope, cdp.slopePercentage)

					WAVE/T fitSlopeQCLBN = LBN_GetTextWave()
					fitSlopeQCLBN[INDEP_HEADSTAGE] = NumericWaveToList(fitSlopeQCfromRhSuAd, ";", format = "%d")
					key                            = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES_PASS)
					ED_AddEntryToLabnotebook(device, key, fitSlopeQCLBN, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

					if(validFit)

						if(!WaveExists(futureDAScales))
							if(PSQ_DS_AdaptiveIsFinished(device, s.sweepNo, s.headstage, numSweepsWithSaturation, fromRhSuAd = 1))
								PSQ_ForceSetEvent(device, s.headstage)
								RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)

								WAVE/ZZ DAScales
								break
							endif
						endif

						dascale = PSQ_DS_CalculateDAScale(cdp, fitOffsetFromRhSuAd[Inf], fitSlopeFromRhSuAd[Inf], DAScalesRhSuAd[Inf], apfreqRhSuAd[Inf])

						Make/FREE/D DAScaleNew = {dascale}
						Concatenate/FREE/NP=(ROWS) {DAScaleNew}, futureDAScales
					else
						// when the fits from RhSuAd are not valid we are already done
					endif

					if(WaveExists(futureDAScales))
						PSQ_DS_CalcFutureDAScalesAndStoreInLBN(device, s.sweepNo, s.headstage, futureDAScales)
					endif

					WAVE/ZZ DAScales = futureDAScales
					break
			endswitch

			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			break
		case PRE_SWEEP_CONFIG_EVENT:
			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			ret = PSQ_CheckThatAlarmIsEnabled(device, asyncChannels)
			if(ret)
				return 1
			endif
			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			WAVE/T opModeLBN = LBN_GetTextWave()
			opModeLBN[INDEP_HEADSTAGE] = opMode
			key                        = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_OPMODE)
			ED_AddEntryToLabnotebook(device, key, opModeLBN, overrideSweepNo = s.sweepNo)

			daScaleOffset = PSQ_DS_GetDAScaleOffset(device, s.headstage, opMode)

			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(WaveExists(baselineQCPassedLBN), "Expected BL QC passed LBN entry")

			samplingFrequencyPassed = PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(device, PSQ_DA_SCALE, s)

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			asyncAlarmPassed = PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(device, PSQ_DA_SCALE, s.sweepNo, asyncChannels)

			strswitch(opMode)
				case PSQ_DS_SUB:
				case PSQ_DS_SUPRA:
					sweepPassed = baselineQCPassedLBN[s.headstage] && samplingFrequencyPassed && asyncAlarmPassed
					break
				case PSQ_DS_ADAPT:
					[daScaleStepMinNorm, daScaleStepMaxNorm] = PSQ_DS_GetDAScaleStepsNorm(device, s.sweepNo, s.headstage)

					cdp.daScaleStepMinNorm = daScaleStepMinNorm
					cdp.daScaleStepMaxNorm = daScaleStepMaxNorm

					[WAVE futureDAScales] = PSQ_DS_EvaluateAdaptiveThresholdSweep(device, s.sweepNo, s.headstage, cdp)

					// prepare wave for setting DAScale; DAScalesIndex is incremented when required below
					WAVE/ZZ DAScales = futureDAScales

					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_VALID_SLOPE_PASS, query = 1)
					WAVE validSlopePassedQC = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

					key                    = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_ENOUGH_FI_POINTS_PASS, query = 1)
					enoughFIPointsPassedQC = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

					sweepPassed = baselineQCPassedLBN[s.headstage] && samplingFrequencyPassed && asyncAlarmPassed \
					              && validSlopePassedQC[s.headstage] && enoughFIPointsPassedQC
					break
				default:
					ASSERT(0, "Invalid opMode")
			endswitch

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = sweepPassed
			key                     = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			sprintf msg, "SamplingFrequency %s, Sweep %s\r", ToPassFail(samplingFrequencyPassed), ToPassFail(sweepPassed)
			DEBUGPRINT(msg)

			WAVE fISlope = LBN_GetNumericWave()

			if(sweepPassed)

				showPlot = AFH_GetAnalysisParamNumerical("ShowPlot", s.params, defValue = 1)

				WAVE/Z sweep = GetSweepWave(device, s.sweepNo)
				ASSERT(WaveExists(sweep), "Expected a sweep for evaluation")

				if(!cmpstr(opMode, PSQ_DS_SUB))
					WAVE deltaV     = LBN_GetNumericWave()
					WAVE deltaI     = LBN_GetNumericWave()
					WAVE resistance = LBN_GetNumericWave()

					CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)

					ED_AddEntryToLabnotebook(device, LBN_DELTA_I, deltaI, unit = "A")
					ED_AddEntryToLabnotebook(device, LBN_DELTA_V, deltaV, unit = "V")

					FitResistance(device, s.headstage, showPlot = showPlot, anaFuncType = PSQ_DA_SCALE)

				elseif(!cmpstr(opMode, PSQ_DS_SUPRA))
					totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)

					WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_DA_SCALE, sweep, s.headstage, totalOnsetDelay,                       \
					                                          PSQ_DS_SPIKE_LEVEL, numberOfSpikesReq = Inf, numberOfSpikesFound = numberOfSpikes)
					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SPIKE_DETECT)
					ED_AddEntryToLabnotebook(device, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

					WAVE numberOfSpikesLBN = LBN_GetNumericWave()
					numberOfSpikesLBN[s.headstage] = numberOfSpikes
					key                            = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SPIKE_COUNT)
					ED_AddEntryToLabnotebook(device, key, numberOfSpikesLBN, overrideSweepNo = s.sweepNo)

					minimumSpikeCount    = AFH_GetAnalysisParamNumerical("MinimumSpikeCount", s.params)
					maximumSpikeCount    = AFH_GetAnalysisParamNumerical("MaximumSpikeCount", s.params)
					daScaleModifierParam = AFH_GetAnalysisParamNumerical("DAScaleModifier", s.params) * PERCENT_TO_ONE
					if(!IsNaN(daScaleModifierParam))
						if(numberOfSpikes < minimumSpikeCount)
							daScaleModifier = +daScaleModifierParam
						elseif(numberOfSpikes > maximumSpikeCount)
							daScaleModifier = -daScaleModifierParam
						endif
					endif

					sprintf msg, "Spike detection: result %d, number of spikes %d\r", spikeDetection[s.headstage], numberOfSpikesLBN[s.headstage]
					DEBUGPRINT(msg)

					acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(device, s.sweepNo, s.headstage)

					ASSERT(acquiredSweepsInSet > 0, "Unexpected number of acquired sweeps")
					WAVE spikeFrequencies = GetAnalysisFuncDAScaleSpikeFreq(device, s.headstage)
					Redimension/N=(acquiredSweepsInSet) spikeFrequencies

					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SPIKE_COUNT, query = 1)
					WAVE spikeCount = GetLastSettingEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
					ASSERT(DimSize(spikeCount, ROWS) == acquiredSweepsInSet, "Mismatched row count")

					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_PULSE_DUR, query = 1)
					WAVE pulseDuration = GetLastSettingEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
					ASSERT(DimSize(pulseDuration, ROWS) == acquiredSweepsInSet, "Mismatched row count")

					spikeFrequencies[] = str2num(FloatWithMinSigDigits(spikeCount[p] / (pulseDuration[p] * MILLI_TO_ONE), numMinSignDigits = 2))

					WAVE DAScalesPlot = GetAnalysisFuncDAScales(device, s.headstage)
					Redimension/N=(acquiredSweepsInSet) DAScalesPlot

					WAVE DAScalesLBN = GetLastSettingEachSCI(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, \
					                                         s.headstage, DATA_ACQUISITION_MODE)
					ASSERT(DimSize(DAScalesLBN, ROWS) == acquiredSweepsInSet, "Mismatched row count")
					DAScalesPlot[] = DAScalesLBN[p] * PICO_TO_ONE

					sprintf msg, "Spike frequency %.2W1PHz, DAScale %.2W1PA", spikeFrequencies[acquiredSweepsInSet - 1], DAScalesPlot[acquiredSweepsInSet - 1]
					DEBUGPRINT(msg)

					AssertOnAndClearRTError()
					try
						V_FitError  = 0
						V_AbortCode = 0

						Make/FREE/D/N=2 coefWave
						CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, spikeFrequencies[]/D/X=DAScalesPlot[]; AbortOnRTE

						WAVE/D/Z W_sigma = MakeWaveFree($"W_sigma")

						if(!WaveExists(W_sigma))
							Make/FREE/D/N=2 W_sigma = NaN
						endif

						fISlope[s.headstage] = coefWave[1] / ONE_TO_PICO * ONE_TO_PERCENT // % Hz/pA

						WAVE fitWave = $(CleanupName("fit_" + NameOfWave(spikeFrequencies), 0))

						WAVE curveFitWave = GetAnalysisFuncDAScaleFreqFit(device, i)
						Duplicate/O fitWave, curveFitWave

						if(showPlot)
							if(WindowExists(SPIKE_FREQ_GRAPH))
								RemoveFromGraph/Z/W=$SPIKE_FREQ_GRAPH $NameOfWave(fitWave)
							else
								Display/K=1/N=$SPIKE_FREQ_GRAPH spikeFrequencies vs DAScalesPlot
								ModifyGraph/W=$SPIKE_FREQ_GRAPH mode=3, zapTZ(left)=1

								AppendToGraph/W=$SPIKE_FREQ_GRAPH curveFitWave

								Label/W=$SPIKE_FREQ_GRAPH left, "Spike Frequency (\\U)"
								Label/W=$SPIKE_FREQ_GRAPH bottom, "DAScale (\\U)"
							endif

							sprintf str, "\\s(%s) Spike Frequency\r", NameOfWave(spikeFrequencies)
							textBoxString = str

							sprintf str, "\\s(%s) Linear Regression\r", NameOfWave(curveFitWave)
							textBoxString += str

							sprintf str, "Fit parameters:\r"
							textBoxString += str

							sprintf str, "a = %.3g +/- %.3g Hz\r", coefWave[0], W_sigma[0]
							textBoxString += str

							sprintf str, "b = %.3g +/- %.3g Hz/pA\r", coefWave[1] / ONE_TO_PICO, W_sigma[1] / ONE_TO_PICO
							textBoxString += str

							sprintf str, "Fitted Slope: %.0W1P%%\r", fISlope[s.headstage]
							textBoxString += str
							TextBox/A=RB/C/N=text/W=$SPIKE_FREQ_GRAPH RemoveEnding(textBoxString, "\r")

							MakeWaveFree(fitWave)
						endif
					catch
						err = ClearRTError()
						DEBUGPRINT("CurveFit failed with " + num2str(err))
					endtry
				elseif(!cmpstr(opMode, PSQ_DS_ADAPT))
					// nothing to do
				else
					ASSERT(0, "Invalid opMode")
				endif
			endif

			strswitch(opMode)
				case PSQ_DS_SUB:
				case PSQ_DS_SUPRA:
					sprintf msg, "Fitted Slope: %.0W1P%%\r", fISlope[s.headstage]
					DEBUGPRINT(msg)

					key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE)
					ED_AddEntryToLabnotebook(device, key, fISlope, unit = "% of Hz/pA")

					WAVE result = LBN_GetNumericWave()
					result[INDEP_HEADSTAGE] = IsFinite(finalSlopePercent) && fiSlope[s.headstage] >= finalSlopePercent
					key                     = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS)
					ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

					ret = PSQ_DetermineSweepQCResults(device, PSQ_DA_SCALE, s.sweepNo, s.headstage, numSweepsPass, Inf)

					if(ret == PSQ_RESULTS_DONE)
						break
					elseif(sweepPassed && ret == PSQ_RESULTS_CONT)
						DAScalesIndex[s.headstage] += 1
					endif
					break
				case PSQ_DS_ADAPT:
					PSQ_DS_CalcFutureDAScalesAndStoreInLBN(device, s.sweepNo, s.headstage, futureDAScales)

					ret = PSQ_DS_AdaptiveDetermineSweepQCResults(device, s.sweepNo, s.headstage, numInvalidSlopeSweepsAllowed, numSweepsWithSaturation)
					if(ret == PSQ_RESULTS_DONE)
						// do nothing
					elseif(ret == PSQ_RESULTS_CONT)

						key                       = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES_PASS, query = 1)
						measuredAllFutureDAScales = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
						ASSERT(IsFinite(measuredAllFutureDAScales), "Invalid measuredAllFutureDAScales")

						if(sweepPassed)
							if(measuredAllFutureDAScales)
								[fitOffset, fitSlope, DAScale, apfreq] = PSQ_DS_GetValuesOfLargestDAScale(numericalValues, textualValues, s.sweepNo, s.headstage)

								dascale = PSQ_DS_CalculateDAScale(cdp, fitOffset, fitSlope, DAScale, apfreq)
								Make/FREE/D DAScaleNew = {dascale}
								Concatenate/NP=(ROWS) {DAScaleNew}, futureDAScales

								PSQ_DS_CalcFutureDAScalesAndStoreInLBN(device, s.sweepNo, s.headstage, futureDAScales)
							endif

							DAScalesIndex[s.headstage] += 1
						endif
					else
						ASSERT(0, "Unknown PSQ_RESULTS_XXX state")
					endif

					PSQ_DS_CreateSurveyPlotForUser(device, s.sweepNo, s.headstage)

					break
				default:
					ASSERT(0, "Invalid opMode")
			endswitch

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			enoughSweepsPassed = PSQ_NumPassesInSet(numericalValues, PSQ_DA_SCALE, s.sweepNo, s.headstage) >= numSweepsPass

			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DASCALE_OOR, query = 1)
			WAVE/Z DAScaleOOR = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			DAScaleOORQC = !WaveExists(DAScaleOOR)

			strswitch(opMode)
				case PSQ_DS_SUB:
					setPassed = enoughSweepsPassed && DAScaleOORQC
					break
				case PSQ_DS_SUPRA:
					if(IsFinite(finalSlopePercent))
						key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS, query = 1)
						WAVE fISlopeReached = GetLastSettingIndepEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
						ASSERT(WaveExists(fISlopeReached), "Missing fiSlopeReached LBN entry")

						setPassed = enoughSweepsPassed && Sum(fISlopeReached) > 0 && DAScaleOORQC
					else
						sprintf msg, "Final slope percentage not present\r"
						DEBUGPRINT(msg)

						setPassed = enoughSweepsPassed && DAScaleOORQC
					endif
					break
				case PSQ_DS_ADAPT:
					setPassed = PSQ_DS_AdaptiveIsFinished(device, s.sweepNo, s.headstage, numSweepsWithSaturation)
					break
				default:
					ASSERT(0, "Invalid opMode")
			endswitch

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = setPassed
			key                     = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType == PRE_SET_EVENT || s.eventType == POST_SWEEP_EVENT)
		WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			if(!statusHS[i])
				continue
			endif

			if(!WaveExists(DAScales))
				ASSERT(!cmpstr(opMode, PSQ_DS_ADAPT), "Invalid opMode")
				// edge-case for adaptive suprathreshold:
				// - initial data from supra had a failing fit
				// - but was dense enough not to violate the maxFrequencyChangePercent requirement
				// - or we already have NumSweepsWithSaturation sweeps in RhSuAd with passing f-I slope
				// so we would be actually done, but we have to acquire at least one sweep so that we can attach data to it
				// and in that case we just reuse the same DAScale value and then finish successfully
				break
			endif

			index = DAScalesIndex[i]

			// index equals the number of sweeps in the stimset on the last call (*post* sweep event)
			if(index > DimSize(DAScales, ROWS))
				printf "(%s): The stimset has too many sweeps, increase the size of DAScales.\r", GetRTStackInfo(1)
				continue
			elseif(index < DimSize(DAScales, ROWS))
				ASSERT(IsFinite(daScaleOffset), "DAScale offset is non-finite")
				ASSERT(IsFinite(daScaleModifier), "DAScale modifier is non-finite")

				strswitch(offsetOp)
					case "+":
						DAScale = DAScales[index] * (1 + daScaleModifier) + daScaleOffset
						break
					case "*":
						DAScale = DAScales[index] * (1 + daScaleModifier) * daScaleOffset
						break
					default:
						ASSERT(0, "Invalid case")
						break
				endswitch

				limitCheck      = (s.eventType == POST_SWEEP_EVENT)
				retCheckDAScale = SetDAScale(device, i, s.sweepNo, absolute = DAScale * PICO_TO_ONE, limitCheck = limitCheck)

				if(limitCheck && retCheckDAScale)
					ComplainOutOfRangeDAScale(device, s.sweepNo, MSQ_DA_SCALE)
					break
				endif
			endif
		endfor
	endif

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

	if(baselineQCPassed) // already done
		return NaN
	endif

	[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_DA_SCALE, s)

	return PSQ_EvaluateBaselinePassed(device, PSQ_DA_SCALE, s.sweepNo, s.headstage, chunk, ret)
End

/// @brief Return a list of required parameters
Function/S PSQ_SquarePulse_GetParams()
	return "AsyncQCChannels:wave,"         + \
	       "[SamplingFrequency:variable]," + \
	       "SamplingMultiplier:variable"
End

Function/S PSQ_SquarePulse_GetHelp(string name)

	strswitch(name)
		case "AsyncQCChannels":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_GetHelpCommon(PSQ_SQUARE_PULSE, name)
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_SquarePulse_CheckParam(string name, STRUCT CheckParametersStruct &s)

	variable val

	strswitch(name)
		case "AsyncQCChannels":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_CheckParamCommon(name, s)
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

/// @brief Analysis function to find the smallest DAScale where the cell spikes
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has a pulse
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the override wave,
/// @see PSQ_CreateOverrideResults().
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-squarepulse.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with pre pulse baseline (-), pulse (*), and post pulse baseline (-).
///
///    *******
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
/// ---|     |--------------------------------------------
///
/// @endverbatim
Function PSQ_SquarePulse(device, s)
	string                      device
	STRUCT AnalysisFunction_V3 &s

	variable stepsize, DAScale, totalOnsetDelay, setPassed, sweepPassed, multiplier
	variable val, samplingFrequencyPassed, asyncAlarmPassed, ret, retCheckDAScale
	string key, msg

	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_SQUARE_PULSE, s.headstage, s.sweepNo)

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 0)
			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 0)

			PSQ_StoreStepSizeInLBN(device, PSQ_SQUARE_PULSE, s.sweepNo, PSQ_SP_INIT_AMP_p100)
			SetDAScale(device, s.headstage, s.sweepNo, absolute = PSQ_SP_INIT_AMP_p100, limitCheck = 0)

			return 0

			break
		case PRE_SWEEP_CONFIG_EVENT:
			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			ret = PSQ_CheckThatAlarmIsEnabled(device, asyncChannels)
			if(ret)
				return 1
			endif
			break
		case POST_SWEEP_EVENT:
			WAVE sweepWave       = GetSweepWave(device, s.sweepNo)
			WAVE numericalValues = GetLBNumericalValues(device)

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)

			WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_SQUARE_PULSE, sweepWave, s.headstage, \
			                                          totalOnsetDelay, PSQ_SPIKE_LEVEL)
			key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(device, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT)

			key      = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_STEPSIZE, query = 1)
			stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			WAVE DAScalesLBN = GetLastSetting(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
			DAScale = DAScalesLBN[s.headstage] * PICO_TO_ONE

			samplingFrequencyPassed = PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(device, PSQ_SQUARE_PULSE, s)

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			asyncAlarmPassed = PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(device, PSQ_SQUARE_PULSE, s.sweepNo, asyncChannels)

			sweepPassed = 0

			sprintf msg, "DAScale %g, stepSize %g", DAScale, stepSize
			DEBUGPRINT(msg)

			if(spikeDetection[s.headstage]) // headstage spiked
				if(CheckIfSmall(DAScale, tol = 1e-14))
					WAVE value = LBN_GetNumericWave()
					value[INDEP_HEADSTAGE] = 1
					key                    = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO)
					ED_AddEntryToLabnotebook(device, key, value, unit = LABNOTEBOOK_BINARY_UNIT)

					key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
					WAVE spikeWithDAScaleZero        = GetLastSettingIndepEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
					WAVE spikeWithDAScaleZeroReduced = ZapNaNs(spikeWithDAScaleZero)
					if(DimSize(spikeWithDAScaleZeroReduced, ROWS) == PSQ_SP_MAX_DASCALE_ZERO)
						PSQ_ForceSetEvent(device, s.headstage)
						RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
					endif
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_m50))
					retCheckDAScale = SetDAScale(device, s.headstage, s.sweepNo, absolute = DAScale + stepsize)
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p10))
					WAVE value = LBN_GetNumericWave()
					value[INDEP_HEADSTAGE] = DAScale
					key                    = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE)
					ED_AddEntryToLabnotebook(device, key, value)

					sweepPassed = samplingFrequencyPassed && asyncAlarmPassed

					if(sweepPassed)
						PSQ_ForceSetEvent(device, s.headstage)
						RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
					endif
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p100))
					PSQ_StoreStepSizeInLBN(device, PSQ_SQUARE_PULSE, s.sweepNo, PSQ_SP_INIT_AMP_m50)
					stepsize        = PSQ_SP_INIT_AMP_m50
					retCheckDAScale = SetDAScale(device, s.headstage, s.sweepNo, absolute = DAScale + stepsize)
				else
					ASSERT(0, "Unknown stepsize")
				endif
			else // headstage did not spike
				if(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_m50))
					PSQ_StoreStepSizeInLBN(device, PSQ_SQUARE_PULSE, s.sweepNo, PSQ_SP_INIT_AMP_p10)
					stepsize = PSQ_SP_INIT_AMP_p10
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p10))
					// do nothing
				elseif(CheckIfClose(stepSize, PSQ_SP_INIT_AMP_p100))
					// do nothing
				else
					ASSERT(0, "Unknown stepsize")
				endif

				retCheckDAScale = SetDAScale(device, s.headstage, s.sweepNo, absolute = DAScale + stepsize)
			endif

			if(retCheckDAScale)
				ComplainOutOfRangeDAScale(device, s.sweepNo, PSQ_RAMP)
				sweepPassed = 0
			endif

			sprintf msg, "Sweep has %s\r", ToPassFail(sweepPassed)
			DEBUGPRINT(msg)

			WAVE value = LBN_GetNumericWave()
			value[INDEP_HEADSTAGE] = sweepPassed
			key                    = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, value, unit = LABNOTEBOOK_BINARY_UNIT)

			if(!samplingFrequencyPassed)
				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
			endif

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_SQUARE_PULSE, s.sweepNo, s.headstage) >= PSQ_SP_NUM_SWEEPS_PASS

			if(!setPassed)
				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)
			endif

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = setPassed
			key                     = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
		default:
			// do nothing
			break
	endswitch

	return NaN
End

/// @brief Return a list of required parameters
Function/S PSQ_Rheobase_GetParams()
	return "AsyncQCChannels:wave,"                 + \
	       "[BaselineRMSLongThreshold:variable],"  + \
	       "[BaselineRMSShortThreshold:variable]," + \
	       "[BaselineTargetVThreshold:variable],"  + \
	       "[SamplingFrequency:variable],"         + \
	       "SamplingMultiplier:variable"
End

Function/S PSQ_Rheobase_GetHelp(string name)

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "BaselineTargetVThreshold":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_GetHelpCommon(PSQ_RHEOBASE, name)
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_Rheobase_CheckParam(string name, STRUCT CheckParametersStruct &s)

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "BaselineTargetVThreshold":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_CheckParamCommon(name, s)
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

/// @brief Analysis function for finding the exact DAScale value between spiking and non-spiking
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has a pulse of non-zero and arbitrary length
/// - Pre pulse baseline length is #PSQ_BL_EVAL_RANGE
/// - Post pulse baseline length a multiple of #PSQ_BL_EVAL_RANGE
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the override wave,
/// @see PSQ_CreateOverrideResults().
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-rheobase.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with pre pulse baseline (-), pulse (*), and post pulse baseline (-).
///
///    *******
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
///    |     |
/// ---|     |--------------------------------------------
///
/// @endverbatim
Function PSQ_Rheobase(device, s)
	string                      device
	STRUCT AnalysisFunction_V3 &s

	variable DAScale, val, numSweeps, currentSweepHasSpike, lastSweepHasSpike, setPassed, diff
	variable baselineQCPassed, finalDAScale, initialDAScale, stepSize, previousStepSize, samplingFrequencyPassed
	variable totalOnsetDelay, asyncAlarmPassed, retCheckDAScale
	variable i, ret, numSweepsWithSpikeDetection, sweepNoFound, length, minLength, multiplier, chunk
	string key, msg

	multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = 1)
			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			length    = PSQ_GetDAStimsetLength(device, s.headstage)
			minLength = PSQ_BL_EVAL_RANGE + 2 * PSQ_BL_EVAL_RANGE
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", device, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", device
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_RHEOBASE, s.headstage, s.sweepNo)

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 4)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)

			WAVE numericalValues = GetLBNumericalValues(device)
			key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
			finalDAScale = GetLastSweepWithSettingIndep(numericalValues, key, sweepNoFound)

			if(!IsFinite(finalDAScale) || CheckIfSmall(finalDAScale, tol = 1e-14) || !IsValidSweepNumber(sweepNoFound))
				printf "(%s): Could not find final DAScale value from one of the previous analysis functions.\r", device
				if(TestOverrideActive())
					finalDASCale = PSQ_GetFinalDAScaleFake()
				else
					ControlWindowToFront()
					return 1
				endif
			endif

			SetDAScale(device, s.headstage, s.sweepNo, absolute = finalDAScale, limitCheck = 0)

			return 0

			break
		case PRE_SWEEP_CONFIG_EVENT:
			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			ret = PSQ_CheckThatAlarmIsEnabled(device, asyncChannels)
			if(ret)
				return 1
			endif
			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE sweeps          = AFH_GetSweepsFromSameSCI(numericalValues, s.sweepNo, s.headstage)

			numSweeps = DimSize(sweeps, ROWS)

			if(numSweeps == 1)
				// query the initial DA scale from the previous sweep (which is from a different RAC)
				key          = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_FINAL_SCALE, query = 1)
				finalDAScale = GetLastSweepWithSettingIndep(numericalValues, key, sweepNoFound)
				if(TestOverrideActive())
					finalDAScale = PSQ_GetFinalDAScaleFake()
				else
					ASSERT(IsFinite(finalDAScale) && IsValidSweepNumber(sweepNoFound), "Could not find final DAScale value from previous analysis function")
				endif

				// and set it as the initial DAScale for this SCI
				WAVE result = LBN_GetNumericWave()
				result[INDEP_HEADSTAGE] = finalDAScale
				key                     = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE)
				ED_AddEntryToLabnotebook(device, key, result)

				PSQ_StoreStepSizeInLBN(device, PSQ_RHEOBASE, s.sweepNo, PSQ_RB_DASCALE_STEP_LARGE, future = 1)
			endif

			// store the future step size as the step size of the current sweep
			key      = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE_FUTURE, query = 1)
			stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			PSQ_StoreStepSizeInLBN(device, PSQ_RHEOBASE, s.sweepNo, stepSize)

			samplingFrequencyPassed = PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(device, PSQ_RHEOBASE, s)

			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCPassedWave = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

			baselineQCPassed = WaveExists(baselineQCPassedWave) && baselineQCPassedWave[s.headstage]

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			asyncAlarmPassed = PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(device, PSQ_RHEOBASE, s.sweepNo, asyncChannels)

			sprintf msg, "numSweeps %d, baselineQCPassed %d, samplingFrequencyPassed %d, asyncAlarmPassed %d", numSweeps, baselineQCPassed, samplingFrequencyPassed, asyncAlarmPassed
			DEBUGPRINT(msg)

			if(!samplingFrequencyPassed)
				WAVE result = LBN_GetNumericWave()
				key                     = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
				result[INDEP_HEADSTAGE] = 0
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
				break
			endif
			if(!baselineQCPassed || !asyncAlarmPassed)
				break
			endif

			// search for spike and store result
			WAVE sweepWave       = GetSweepWave(device, s.sweepNo)
			WAVE numericalValues = GetLBNumericalValues(device)

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)

			WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_RHEOBASE, sweepWave, s.headstage, totalOnsetDelay, \
			                                          PSQ_SPIKE_LEVEL)
			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(device, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT)

			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
			WAVE spikeDetectionRA = GetLastSettingEachSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			DEBUGPRINT("spikeDetectionRA: ", wv = spikeDetectionRA)

			numSweepsWithSpikeDetection = DimSize(spikeDetectionRA, ROWS)
			currentSweepHasSpike        = spikeDetectionRA[numSweepsWithSpikeDetection - 1]

			WAVE DAScalesLBN = GetLastSetting(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
			DAScale = DAScalesLBN[s.headstage] * PICO_TO_ONE

			if(numSweepsWithSpikeDetection >= 2)
				lastSweepHasSpike = spikeDetectionRA[numSweepsWithSpikeDetection - 2]

				key              = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE, query = 1)
				stepSize         = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
				previousStepSize = GetLastSettingIndep(numericalValues, s.sweepNo - 1, key, UNKNOWN_MODE)

				if(IsFinite(currentSweepHasSpike) && IsFinite(lastSweepHasSpike) \
				   && (currentSweepHasSpike != lastSweepHasSpike)                \
				   && (CheckIfClose(stepSize, previousStepSize)))

					key      = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE_FUTURE, query = 1)
					stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

					if(DAScale <= PSQ_RB_DASCALE_SMALL_BORDER && CheckIfClose(stepSize, PSQ_RB_DASCALE_STEP_LARGE))
						PSQ_StoreStepSizeInLBN(device, PSQ_RHEOBASE, s.sweepNo, PSQ_RB_DASCALE_STEP_SMALL, future = 1)
					else
						// mark the set as passed
						// we can't mark each sweep as passed/failed as it is not possible
						// to add LBN entries to other sweeps than the last one
						WAVE result = LBN_GetNumericWave()
						key                     = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
						result[INDEP_HEADSTAGE] = 1
						ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)
						PSQ_ForceSetEvent(device, s.headstage)
						RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)

						DEBUGPRINT("Sweep has passed")
						break
					endif
				endif
			endif

			// fetch the future step size
			key      = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE_FUTURE, query = 1)
			stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			if(currentSweepHasSpike)
				DAScale -= stepSize
			else
				DAScale += stepSize
			endif

			if(CheckIfSmall(DaScale, tol = 1e-14) && currentSweepHasSpike)
				// future DAScale would be zero
				if(CheckIfClose(stepSize, PSQ_RB_DASCALE_STEP_SMALL))
					// mark set as failure
					WAVE result = LBN_GetNumericWave()
					key                     = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
					result[INDEP_HEADSTAGE] = 0
					ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

					key                 = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_LIMITED_RES)
					result              = NaN
					result[s.headstage] = 1
					ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)

					DEBUGPRINT("Set has failed")
					break
				elseif(CheckIfClose(stepSize, PSQ_RB_DASCALE_STEP_LARGE))
					// retry with much smaller values
					PSQ_StoreStepSizeInLBN(device, PSQ_RHEOBASE, s.sweepNo, PSQ_RB_DASCALE_STEP_SMALL, future = 1)

					key      = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_STEPSIZE_FUTURE, query = 1)
					stepSize = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

					DAScale = PSQ_RB_DASCALE_STEP_SMALL
				else
					ASSERT(0, "Unknown step size")
				endif
			endif

			key            = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_INITIAL_SCALE, query = 1)
			initialDAScale = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			diff = abs(DAScale - initialDAScale)
			if(diff > PSQ_RB_MAX_DASCALE_DIFF || CheckIfClose(diff, PSQ_RB_MAX_DASCALE_DIFF))
				// mark set as failure
				WAVE result = LBN_GetNumericWave()
				key                     = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
				result[INDEP_HEADSTAGE] = 0
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				result              = NaN
				result[s.headstage] = 1

				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC)
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)

				DEBUGPRINT("Set has failed")
				break
			endif

			retCheckDAScale = SetDAScale(device, s.headstage, s.sweepNo, absolute = DAScale)

			if(retCheckDAScale)
				ComplainOutOfRangeDAScale(device, s.sweepNo, PSQ_RHEOBASE)

				WAVE result = LBN_GetNumericWave()
				key                     = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
				result[INDEP_HEADSTAGE] = 0
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)
			endif
			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			key       = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS, query = 1)
			setPassed = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			// if we don't have an entry yet for the set passing, it has failed
			if(!IsFinite(setPassed))
				key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SET_PASS)
				WAVE result = LBN_GetNumericWave()
				result[INDEP_HEADSTAGE] = 0
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)

				DEBUGPRINT("Set has failed")
			endif

			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC, query = 1)
			WAVE/Z rangeExceeded = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(!WaveExists(rangeExceeded))
				WAVE result = LBN_GetNumericWave()
				result[s.headstage] = 0
				key                 = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC)
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)
			endif

			key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_LIMITED_RES, query = 1)
			WAVE/Z limitedResolution = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(!WaveExists(limitedResolution))
				WAVE result = LBN_GetNumericWave()
				result[s.headstage] = 0
				key                 = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_LIMITED_RES)
				ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)
			endif

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

	if(baselineQCPassed)
		return NaN
	endif

	[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_RHEOBASE, s)

	return PSQ_EvaluateBaselinePassed(device, PSQ_RHEOBASE, s.sweepNo, s.headstage, chunk, ret)
End

Function PSQ_GetFinalDAScaleFake()

	variable daScale

	ASSERT(TestOverrideActive(), "Should not be called in production.")

	WAVE overrideResults = GetOverrideResults()
	ASSERT(WaveExists(overrideResults), "overrideResults wave must exist")

	daScale = GetNumberFromWaveNote(overrideResults, PSQ_RB_FINALSCALE_FAKE_KEY)
	ASSERT(IsFinite(daScale), "Missing fake DAScale for PatchSeq Rheobase")
	return daScale
End

/// @brief Return a list of required parameters
Function/S PSQ_Ramp_GetParams()
	return "AsyncQCChannels:wave,"                 + \
	       "[BaselineRMSLongThreshold:variable],"  + \
	       "[BaselineRMSShortThreshold:variable]," + \
	       "[BaselineTargetVThreshold:variable],"  + \
	       "NumberOfSpikes:variable,"              + \
	       "[SamplingFrequency:variable],"         + \
	       "SamplingMultiplier:variable"
End

Function/S PSQ_Ramp_GetHelp(string name)

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "BaselineTargetVThreshold":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_GetHelpCommon(PSQ_RAMP, name)
		case "NumberOfSpikes":
			return "Number of spikes required to be found after the pulse onset " \
			       + "in order to label the cell as having \"spiked\"."
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_Ramp_CheckParam(string name, STRUCT CheckParametersStruct &s)

	variable val

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "BaselineTargetVThreshold":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_CheckParamCommon(name, s)
		case "NumberOfSpikes":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0))
				return "Invalid value " + num2str(val)
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

/// @brief Analysis function for applying a ramp stim set and finding the position were it spikes.
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has a ramp of non-zero and arbitrary length
/// - Pre pulse baseline length is #PSQ_BL_EVAL_RANGE
/// - Post pulse baseline length is at least two times #PSQ_BL_EVAL_RANGE
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the override wave,
/// @see PSQ_CreateOverrideResults().
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-ramp.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with pre pulse baseline (-), ramp (/|), and post pulse baseline (-).
///
///                 /|
///                / |
///               /  |
///              /   |
///             /    |
///            /     |
///           /      |
///          /       |
///         /        |
///        /         |
///       /          |
///      /           |
///     /            |
/// ---/             |--------------------------------------------
///
/// @endverbatim
Function PSQ_Ramp(device, s)
	string                      device
	STRUCT AnalysisFunction_V3 &s

	variable DAScale, val, numSweeps, currentSweepHasSpike, setPassed
	variable baselineQCPassed, finalDAScale, initialDAScale, samplingFrequencyPassed
	variable lastFifoPos, totalOnsetDelay, fifoInStimsetTime
	variable i, ret, numSweepsWithSpikeDetection, sweepNoFound, length, minLength, asyncAlarmPassed
	variable DAC, sweepPassed, sweepsInSet, passesInSet, acquiredSweepsInSet, enoughSpikesFound
	variable pulseStart, pulseDuration, fifoPos, fifoOffset, numberOfSpikes, multiplier, chunk
	string key, msg, stimset
	string   fifoname
	variable hardwareType

	numberOfSpikes = AFH_GetAnalysisParamNumerical("NumberOfSpikes", s.params)
	multiplier     = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			length    = PSQ_GetDAStimsetLength(device, s.headstage)
			minLength = 3 * PSQ_BL_EVAL_RANGE
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", device, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", device
				ControlWindowToFront()
				return 1
			endif

			DAC     = AFH_GetDACFromHeadstage(device, s.headstage)
			stimset = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
			if(IDX_NumberOfSweepsInSet(stimset) < PSQ_RA_NUM_SWEEPS_PASS)
				printf "(%s): The stimset must have at least %d sweeps\r", device, PSQ_RA_NUM_SWEEPS_PASS
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_RAMP, s.headstage, s.sweepNo)

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 0)
			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			SetDAScale(device, s.headstage, s.sweepNo, absolute = PSQ_RA_DASCALE_DEFAULT * PICO_TO_ONE, limitCheck = 0)

			return 0

			break
		case PRE_SWEEP_CONFIG_EVENT:
			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			ret = PSQ_CheckThatAlarmIsEnabled(device, asyncChannels)
			if(ret)
				return 1
			endif
			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE baselinePassed = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

			samplingFrequencyPassed = PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(device, PSQ_RAMP, s)

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			asyncAlarmPassed = PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(device, PSQ_RAMP, s.sweepNo, asyncChannels)

			sweepPassed = baselinePassed[s.headstage] && samplingFrequencyPassed && asyncAlarmPassed

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = sweepPassed
			key                     = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			ret = PSQ_DetermineSweepQCResults(device, PSQ_RAMP, s.sweepNo, s.headstage, PSQ_RA_NUM_SWEEPS_PASS, Inf)

			if(ret == PSQ_RESULTS_DONE)
				break
			endif

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_RAMP, s.sweepNo, s.headstage) >= PSQ_RA_NUM_SWEEPS_PASS

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = setPassed
			key                     = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()

			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

	enoughSpikesFound = PSQ_FoundAtLeastOneSpike(device, s.sweepNo)

	sprintf msg, "enoughSpikesFound %g, baselineQCPassed %d", enoughSpikesFound, baselineQCPassed
	DEBUGPRINT(msg)

	if(IsFinite(enoughSpikesFound) && baselineQCPassed) // spike already found/definitly not found and baseline QC passed
		return NaN
	endif

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)

	fifoInStimsetTime = AFH_GetFifoInStimsetTime(device, s)

	WAVE durations = PSQ_GetPulseDurations(device, PSQ_RAMP, s.sweepNo, totalOnsetDelay)
	pulseStart    = PSQ_BL_EVAL_RANGE
	pulseDuration = durations[s.headstage]

	if(IsNaN(enoughSpikesFound) && fifoInStimsetTime >= pulseStart) // spike search was inconclusive up to now
		// and we are after the pulse onset

		Make/FREE/D spikePos
		WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_RAMP, s.scaledDACWave, s.headstage,                                                \
		                                          totalOnsetDelay, PSQ_SPIKE_LEVEL, spikePositions = spikePos, numberOfSpikesReq = numberOfSpikes)

		if(spikeDetection[s.headstage]                                                                    \
		   && ((TestOverrideActive() && (fifoInStimsetTime > WaveMax(spikePos))) || !TestOverrideActive()))

			enoughSpikesFound = 1

			key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(device, key, spikeDetection, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

			WAVE/T resultTxT = LBN_GetTextWave()
			resultTxT[s.headstage] = NumericWaveToList(spikePos, ";")
			key                    = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_POSITIONS)
			ED_AddEntryToLabnotebook(device, key, resultTxT, overrideSweepNo = s.sweepNo, unit = "ms")

			NVAR      deviceID           = $GetDAQDeviceID(device)
			NVAR      ADChannelToMonitor = $GetADChannelToMonitor(device)
			WAVE      daqDataWave        = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
			WAVE/WAVE scaledDataWave     = GetScaledDataWave(device)

			hardwareType = GetHardwareType(device)
			if(hardwareType == HARDWARE_ITC_DAC)

				// stop DAQ, set DA to zero from now to the end and start DAQ again

				// fetch the very last fifo position immediately before we stop it
				NVAR tgID = $GetThreadGroupIDFIFO(device)
				fifoOffset = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
				TFH_StopFIFODaemon(HARDWARE_ITC_DAC, deviceID)
				HW_StopAcq(HARDWARE_ITC_DAC, deviceID)
				HW_ITC_PrepareAcq(deviceID, DATA_ACQUISITION_MODE, offset = fifoOffset)

				sprintf msg, "DA black out: [%g, %g]\r", fifoOffset, Inf
				DEBUGPRINT(msg)

				Multithread daqDataWave[fifoOffset, Inf][0, ADChannelToMonitor - 1] = 0

				PSQ_Ramp_AddEpoch(device, s.headstage, daqDataWave, "Name=DA Suppression", "RA_DS", fifoOffset, DimSize(daqDataWave, ROWS) - 1)

				HW_StartAcq(HARDWARE_ITC_DAC, deviceID)
				TFH_StartFIFOStopDaemon(HARDWARE_ITC_DAC, deviceID)

				// fetch newest fifo position, blocks until it gets a valid value
				// its zero is now fifoOffset
				NVAR tgID = $GetThreadGroupIDFIFO(device)
				fifoPos = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
				ASSERT(fifoPos > 0, "Invalid fifo position, has the thread died?")

				// wait until the hardware is finished with writing this chunk
				// this is to avoid that two threads write simultaneously into the DAQDataWave
				for(;;)
					val = TS_GetNewestFromThreadQueue(tgID, "fifoPos")

					if(val > fifoPos)
						break
					endif
				endfor

				sprintf msg, "AD black out: [%g, %g]\r", fifoOffset, (fifoOffset + fifoPos)
				DEBUGPRINT(msg)

				Multithread daqDataWave[fifoOffset, fifoOffset + fifoPos][ADChannelToMonitor, Inf] = 0

				// only need to adapt DA in scaledDataWave, AD channels will be updated by SCOPE_ITC_UpdateOscilloscope
				// as soon as it gets a higher fifoPos, because it will copy from the last known fifoPos to the current from
				// daqDataWave to scaledDataWave
				WAVE scaledChannelDA = scaledDataWave[0]
				if(fifoOffset < DimSize(scaledChannelDA, ROWS))
					ChangeWaveLock(scaledChannelDA, 0)
					MultiThread scaledChannelDA[fifoOffset,] = 0
					ChangeWaveLock(scaledChannelDA, 1)
				endif

				PSQ_Ramp_AddEpoch(device, s.headstage, daqDataWave, "Name=Unacquired DA data", "RA_UD", fifoOffset, fifoOffset + fifoPos)

			elseif(hardwareType == HARDWARE_NI_DAC)
				// DA output runs on the AD tasks clock source ai
				// we stop DA and set the analog out to 0, the AD task keeps on running

				WAVE config = GetDAQConfigWave(device)
				fifoName = GetNIFIFOName(deviceID)

				HW_NI_StopDAC(deviceID)
				HW_NI_ZeroDAC(deviceID)

				DoXOPIdle
				FIFOStatus/Q $fifoName
				WAVE/WAVE NIDataWave     = daqDataWave
				WAVE/WAVE scaledDataWave = GetScaledDataWave(device)
				// As only one AD and DA channel is allowed for this function, at index 0 the setting for first DA channel are expected
				WAVE NIChannel       = NIDataWave[0]
				WAVE scaledChannelDA = scaledDataWave[0]
				if(V_FIFOChunks < DimSize(NIChannel, ROWS))
					MultiThread NIChannel[V_FIFOChunks,] = 0
					ChangeWaveLock(scaledChannelDA, 0)
					MultiThread scaledChannelDA[V_FIFOChunks,] = 0
					ChangeWaveLock(scaledChannelDA, 1)

					PSQ_Ramp_AddEpoch(device, s.headstage, NIChannel, "Name=DA Suppression", "RA_DS", V_FIFOChunks, DimSize(NIChannel, ROWS) - 1)
				endif
			elseif(hardwareType == HARDWARE_SUTTER_DAC)
				// the sutter XOP might prefetch upto 4096 samples

				WAVE      config         = GetDAQConfigWave(device)
				WAVE/WAVE SUDataWave     = daqDataWave
				WAVE/WAVE scaledDataWave = GetScaledDataWave(device)
				// As only one AD and DA channel is allowed for this function, at index 0 the setting for first DA channel are expected
				WAVE channelDA       = SUDataWave[0]
				WAVE scaledChannelDA = scaledDataWave[0]
				fifoPos = HW_GetDAFifoPosition(device, DATA_ACQUISITION_MODE)
				if(fifoPos < DimSize(channelDA, ROWS))
					MultiThread channelDA[fifoPos,] = 0
					ChangeWaveLock(scaledChannelDA, 0)
					MultiThread scaledChannelDA[fifoPos,] = 0
					ChangeWaveLock(scaledChannelDA, 1)

					PSQ_Ramp_AddEpoch(device, s.headstage, scaledChannelDA, "Name=DA Suppression", "RA_DS", fifoPos, DimSize(channelDA, ROWS) - 1)
				endif
			else
				ASSERT(0, "Unknown hardware type")
			endif

			// recalculate pulse duration
			PSQ_GetPulseDurations(device, PSQ_RAMP, s.sweepNo, totalOnsetDelay, forceRecalculation = 1)
		elseif(fifoInStimsetTime > pulseStart + pulseDuration)
			// we are past the pulse and have not found a spike
			// write the results into the LBN
			key = CreateAnaFuncLBNKey(PSQ_RAMP, PSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(device, key, spikeDetection, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)
		endif
	endif

	if(!baselineQCPassed)
		[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_RAMP, s)

		if(IsFinite(ret))
			baselineQCPassed = (ret == 0)

			// we can return here as we either:
			// - failed pre pulse BL QC and we don't need to search for a spike
			// - or passed post pulse BL QC and already searched for a spike
			enoughSpikesFound = PSQ_FoundAtLeastOneSpike(device, s.sweepNo)

			ASSERT(!baselineQCPassed || (baselineQCPassed && isFinite(enoughSpikesFound)), "We missed searching for a spike")
			return PSQ_EvaluateBaselinePassed(device, PSQ_RAMP, s.sweepNo, s.headstage, chunk, ret)
		endif
	endif
End

static Function PSQ_Ramp_AddEpoch(string device, variable headstage, WAVE wv, string tags, string shortName, variable first, variable last)

	variable DAC

	DAC = AFH_GetDACFromHeadstage(device, headstage)
	WAVE/T epochWave = GetEpochsWave(device)

	PSQ_Ramp_AddEpochImpl(epochWave, wv, DAC, tags, shortName, first, last)
End

/// @brief device independent implementation of @ref PSQ_Ramp_AddEpoch
Function PSQ_Ramp_AddEpochImpl(WAVE/T epochWave, WAVE wv, variable DAC, string tags, string shortName, variable first, variable last)

	variable epBegin, epEnd

	ASSERT(!cmpstr(WaveUnits(wv, ROWS), "ms"), "Unexpected x unit")
	epBegin = IndexToScale(wv, first, ROWS) * MILLI_TO_ONE
	epEnd   = IndexToScale(wv, last, ROWS) * MILLI_TO_ONE

	EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)
End

/// @brief Determine if we have three passing sweeps with the same DAScale value
///
/// @returns result        set passing state (0/1)
/// @returns maxOccurences maximum number of passing sets with the same DASCale value
Function [variable result, variable maxOccurences] PSQ_CR_SetHasPassed(WAVE numericalValues, variable sweepNo, variable headstage)
	variable i, numEntries, scaleFactor, index, maxValue
	string key

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	WAVE sweepPassedSCI = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	WAVE scaleFactorSCI = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, headstage, DATA_ACQUISITION_MODE)
	numEntries = DimSize(sweepPassedSCI, ROWS)
	ASSERT(numEntries == DimSize(scaleFactorSCI, ROWS), "Mismatching sizes")

	Make/I/FREE/N=(numEntries) numberOfOccurences, scaleFactors

	for(i = 0; i < numEntries; i += 1)

		if(!sweepPassedSCI[i])
			continue
		endif

		scaleFactor = round(scaleFactorSCI[i])

		FindValue/I=(scaleFactor) scaleFactors
		if(V_Value == -1)
			scaleFactors[index]       = scaleFactor
			numberOfOccurences[index] = 1
			index                    += 1
		else
			numberOfOccurences[V_Value] += 1

			if(numberOfOccurences[V_Value] == PSQ_CR_NUM_SWEEPS_PASS)
				return [1, PSQ_CR_NUM_SWEEPS_PASS]
			endif
		endif
	endfor

	if(!index)
		return [0, 0]
	endif

	// keep only NumberOfOccurences column
	maxValue = WaveMax(numberOfOccurences)
	ASSERT(maxValue < PSQ_CR_NUM_SWEEPS_PASS, "Should have exited earlier!")

	return [0, maxValue]
End

/// @brief Returns the two letter states "AA", "BB" and "BA" for the value and
/// the scaling factors to reach min/center/max
///
/// We need the real baseline value (measured), whereas
/// the center between minimum/maximum would be targetV, which the user
/// entered together with an allowed ± range.
static Function [STRUCT ChirpBoundsInfo s] PSQ_CR_DetermineBoundsState(variable baseline, variable minimum, variable maximum, variable value)

	variable center

	ASSERT(minimum < maximum, "Invalid ordering")

	minimum -= baseline
	maximum -= baseline
	value   -= baseline

	s.minimumFac = minimum / value
	s.maximumFac = maximum / value
	center       = minimum + (maximum - minimum) / 2
	s.centerFac  = center / value

	if(value >= maximum)
		s.state = "AA"
	elseif(value <= minimum)
		s.state = "BB"
	else
		s.state = "BA"
	endif

	return [s]
End

Function/S PSQ_CR_BoundsActionToString(variable boundsAction)

	switch(boundsAction)
		case PSQ_CR_PASS:
			return "PSQ_CR_PASS"
		case PSQ_CR_INCREASE:
			return "PSQ_CR_INCREASE"
		case PSQ_CR_DECREASE:
			return "PSQ_CR_DECREASE"
		case PSQ_CR_RERUN:
			return "PSQ_CR_RERUN"
		default:
			ASSERT(0, "Invalid case")
	endswitch
End

static Function PSQ_CR_DetermineBoundsActionHelper(WAVE wv, string state, variable action)

	variable index = GetNumberFromWaveNote(wv, NOTE_INDEX)
	SetDimLabel ROWS, index, $state, wv
	wv[index] = action
	SetNumberInWaveNote(wv, NOTE_INDEX, ++index)
End

/// @brief Returns an action depending on the upper and lower states, see @ref ChirpBoundsAction
static Function PSQ_CR_DetermineBoundsActionFromState(string upperState, string lowerState)

	variable action

	Make/FREE/N=15 comb
	SetNumberInWaveNote(comb, NOTE_INDEX, 0)

	// symmetric
	PSQ_CR_DetermineBoundsActionHelper(comb, "BA" + "BA", PSQ_CR_PASS)
	PSQ_CR_DetermineBoundsActionHelper(comb, "AA" + "BA", PSQ_CR_DECREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BA" + "BB", PSQ_CR_DECREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "AA" + "BB", PSQ_CR_DECREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BB" + "BA", PSQ_CR_INCREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BA" + "AA", PSQ_CR_INCREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BB" + "AA", PSQ_CR_INCREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "AA" + "AA", PSQ_CR_RERUN)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BB" + "BB", PSQ_CR_RERUN)

	// hyperpolarized
	PSQ_CR_DetermineBoundsActionHelper(comb, "__" + "BA", PSQ_CR_PASS)
	PSQ_CR_DetermineBoundsActionHelper(comb, "__" + "AA", PSQ_CR_INCREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "__" + "BB", PSQ_CR_DECREASE)

	// depolarized
	PSQ_CR_DetermineBoundsActionHelper(comb, "BA" + "__", PSQ_CR_PASS)
	PSQ_CR_DetermineBoundsActionHelper(comb, "AA" + "__", PSQ_CR_DECREASE)
	PSQ_CR_DetermineBoundsActionHelper(comb, "BB" + "__", PSQ_CR_INCREASE)

	action = comb[%$(upperState + lowerState)]
	ASSERT(IsFinite(action), "Invalid action")
	return action
End

/// @brief Determine the scaling factor for DAScale which is required for being inside the bounds
static Function PSQ_CR_DetermineScalingFactor(STRUCT ChirpBoundsInfo &lowerInfo, STRUCT ChirpBoundsInfo &upperInfo, variable boundsEvaluationMode)

	switch(boundsEvaluationMode)
		case PSQ_CR_BEM_SYMMETRIC:
			return (lowerInfo.centerFac + upperInfo.centerFac) / 2
		case PSQ_CR_BEM_HYPERPOLARIZED:
			return lowerInfo.centerFac
		case PSQ_CR_BEM_DEPOLARIZED:
			return upperInfo.centerFac
		default:
			ASSERT(0, "Invalid case")
	endswitch
End

/// @brief Determine the bounds action given the requested chirp slice
///
/// @param device               device
/// @param scaledDACWave        DAQ data wave with correct units and scaling
/// @param headstage            headstage
/// @param sweepNo              sweep number
/// @param chirpStart           x-position relative to stimset start where the chirp starts
/// @param cycleEnd             x-position relative to stimset start where the requested number of cycles finish
/// @param innerRelativeBound   analysis parameter
/// @param outerRelativeBound   analysis parameter
/// @param boundsEvaluationMode bounds evaluation mode, one of @ref PSQChirpBoundsEvaluationMode
///
/// @return boundsAction, one of @ref ChirpBoundsAction
/// @return scalingFactorDAScale, scaling factor to be inside the bounds for actions PSQ_CR_INCREASE/PSQ_CR_DECREASE
static Function [variable boundsAction, variable scalingFactorDAScale] PSQ_CR_DetermineBoundsAction(string device, WAVE scaledDACWave, variable headstage, variable sweepNo, variable chirpStart, variable cycleEnd, variable innerRelativeBound, variable outerRelativeBound, variable boundsEvaluationMode)

	variable targetV, lowerValue, upperValue, upperMax, upperMin, lowerMax, lowerMin
	variable lowerValueOverride, upperValueOverride, totalOnsetDelay, scalingFactor, baselineVoltage
	string msg, str, graph, key

	WAVE config   = GetDAQConfigWave(device)
	WAVE singleAD = AFH_ExtractOneDimDataFromSweep(device, scaledDACWave, headstage, XOP_CHANNEL_TYPE_ADC, config = config)

	[lowerValue, upperValue] = WaveMinAndMax(singleAD, chirpStart, cycleEnd)

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()

		NVAR count = $GetCount(device)
		upperValueOverride = overrideResults[0][count][1]
		lowerValueOverride = overrideResults[0][count][2]

		if(!IsNaN(lowerValueOverride))
			lowerValue = lowerValueOverride
		endif
		if(!IsNaN(upperValueOverride))
			upperValue = upperValueOverride
		endif
	endif

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)

	if(TestOverrideActive())
		baselineVoltage = PSQ_CR_BASELINE_V_FAKE
	else
		key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_TARGETV, chunk = 0, query = 1)
		WAVE   numericalValues = GetLBNumericalValues(device)
		WAVE/Z baselineLBN     = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
		ASSERT(WaveExists(baselineLBN), "Missing targetV from LBN")
		baselineVoltage = baselineLBN[headstage] * ONE_TO_MILLI
		ASSERT(IsFinite(baselineVoltage), "Invalid baseline voltage")
	endif

	sprintf msg, "boundsEvaluationMode %s, baselineVoltage %g, lowerValue %g, upperValue %g", PSQ_CR_BoundsEvaluationModeToString(boundsEvaluationMode), baselineVoltage, lowerValue, upperValue
	DEBUGPRINT(msg)

	// See the bounds actions sketch at PSQ_Chirp for an explanation regarding the naming

	upperMax = baselineVoltage + outerRelativeBound
	upperMin = baselineVoltage + innerRelativeBound
	lowerMax = baselineVoltage - innerRelativeBound
	lowerMin = baselineVoltage - outerRelativeBound

	STRUCT ChirpBoundsInfo upperInfo
	STRUCT ChirpBoundsInfo lowerInfo

	[upperInfo] = PSQ_CR_DetermineBoundsState(baselineVoltage, upperMin, upperMax, upperValue)
	[lowerInfo] = PSQ_CR_DetermineBoundsState(baselineVoltage, lowerMin, lowerMax, lowerValue)

	switch(boundsEvaluationMode)
		case PSQ_CR_BEM_SYMMETRIC:
			// do nothing
			break
		case PSQ_CR_BEM_HYPERPOLARIZED:
			// only look at Lower
			upperInfo.state = "__"
			break
		case PSQ_CR_BEM_DEPOLARIZED:
			// only look at Upper
			lowerInfo.state = "__"
			break
		default:
			ASSERT(0, "Invalid case")
	endswitch

	boundsAction = PSQ_CR_DetermineBoundsActionFromState(upperInfo.state, lowerInfo.state)

	sprintf msg, "upper: value %g, info: min %g, center %g, max %g, state %s", upperValue, upperInfo.minimumFac, upperInfo.centerFac, upperInfo.maximumFac, upperInfo.state
	DEBUGPRINT(msg)

	sprintf msg, "lower: value %g, info: min %g, center %g, max %g, state %s", lowerValue, lowerInfo.minimumFac, lowerInfo.centerFac, lowerInfo.maximumFac, lowerInfo.state
	DEBUGPRINT(msg)

	WAVE/T resultText = LBN_GetTextWave()
	resultText[INDEP_HEADSTAGE] = upperInfo.state + lowerInfo.state
	key                         = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_BOUNDS_STATE)
	ED_AddEntryToLabnotebook(device, key, resultText, overrideSweepNo = sweepNo)

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		Make/O/N=7/D $("chirpVisDebug_" + num2str(sweepNo))/WAVE=chirpVisDebug
		Make/O/N=7/D $("chirpVisDebugX_" + num2str(sweepNo))/WAVE=chirpVisDebugX

		chirpVisDebug  = NaN
		chirpVisDebugX = 0

		switch(boundsEvaluationMode)
			case PSQ_CR_BEM_SYMMETRIC:
				chirpVisDebug[0] = lowerMin
				chirpVisDebug[1] = lowerMax
				chirpVisDebug[2] = upperMin
				chirpVisDebug[3] = upperMax
				chirpVisDebug[4] = lowerValue
				chirpVisDebug[5] = upperValue

				break
			case PSQ_CR_BEM_HYPERPOLARIZED:
				// only look at Lower
				chirpVisDebug[0] = lowerMin
				chirpVisDebug[1] = lowerMax
				chirpVisDebug[4] = lowerValue

				break
			case PSQ_CR_BEM_DEPOLARIZED:
				// only look at Upper
				chirpVisDebug[2] = upperMin
				chirpVisDebug[3] = upperMax
				chirpVisDebug[5] = upperValue

				break
			default:
				ASSERT(0, "Invalid case")
		endswitch

		graph = "ChirpVisDebugGraph_" + num2str(sweepNo)
		KillWindow/Z $graph
		Display/N=$graph chirpVisDebug/TN=chirpVisDebug vs chirpVisDebugX
		ModifyGraph/W=$graph mode=3, marker(chirpVisDebug[4])=19, marker(chirpVisDebug[5])=19, nticks(bottom)=0, rgb(chirpVisDebug[5])=(0, 0, 65535), grid(left)=1, nticks(left)=10
		sprintf str, "State: Upper %s, Lower %s\r\\s(chirpVisDebug) borders\r\n\\s(chirpVisDebug[5]) upperValue\r\\s(chirpVisDebug[4]) lowerValue", upperInfo.state, lowerInfo.state
		Legend/C/N=text2/J str
		SetAxis/A/E=1/W=$graph left
	endif
#endif // DEBUGGING_ENABLED

	switch(boundsAction)
		case PSQ_CR_RERUN:
			ASSERT(boundsEvaluationMode == PSQ_CR_BEM_SYMMETRIC, "Invalid bounds action")
		case PSQ_CR_PASS:
			scalingFactor = NaN
			// do nothing
			break
		case PSQ_CR_INCREASE:
		case PSQ_CR_DECREASE:
			scalingFactor = PSQ_CR_DetermineScalingFactor(lowerInfo, upperInfo, boundsEvaluationMode)
			if(!IsFinite(scalingFactor) || scalingFactor == 0)
				// unlikely edge case
				boundsAction  = PSQ_CR_Rerun
				scalingFactor = NaN
			endif
			break
		default:
			ASSERT(0, "impossible case")
	endswitch

	WAVE result = LBN_GetNumericWave()
	result[INDEP_HEADSTAGE] = boundsAction
	key                     = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_BOUNDS_ACTION)
	ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = sweepNo)

	sprintf msg, "boundsAction %s, scalingFactor %g", PSQ_CR_BoundsActionToString(boundsAction), scalingFactor
	DEBUGPRINT(msg)

	return [boundsAction, scalingFactor]
End

static Function/S PSQ_CR_BoundsEvaluationModeToString(variable val)
	switch(val)
		case PSQ_CR_BEM_SYMMETRIC:
			return "Symmetric"
		case PSQ_CR_BEM_HYPERPOLARIZED:
			return "Hyperpolarized"
		case PSQ_CR_BEM_DEPOLARIZED:
			return "Depolarized"
		default:
			ASSERT(0, "Invalid value: " + num2str(val))
	endswitch
End

static Function PSQ_CR_ParseBoundsEvaluationModeString(string str)
	strswitch(str)
		case "Symmetric":
			return PSQ_CR_BEM_SYMMETRIC
		case "Hyperpolarized":
			return PSQ_CR_BEM_HYPERPOLARIZED
		case "Depolarized":
			return PSQ_CR_BEM_DEPOLARIZED
		default:
			ASSERT(0, "Invalid value: " + str)
	endswitch
End

static Function PSQ_SetAutobiasTargetVIfPresent(string device, variable headstage, string params, string name)
	variable value

	value = AFH_GetAnalysisParamNumerical(name, params)

	if(IsNaN(value))
		// not present
		return NaN
	endif

	PSQ_SetAutobiasTargetV(device, headstage, value)
End

static Function PSQ_SetAutobiasTargetV(string device, variable headstage, variable value)
	variable preActiveHS

	preActiveHS = GetSliderPositionIndex(device, "slider_DataAcq_ActiveHeadstage")

	if(preActiveHS != headstage)
		PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = headstage)
	endif

	if(!DAG_GetNumericalValue(device, "check_DataAcq_AutoBias"))
		PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	endif

	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = value)

	if(preActiveHS != headstage)
		PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = preActiveHS)
	endif
End

/// @brief Set autobias target V from the average voltage of a passing PSQ_TrueRestingMembranePotential() sweep
///
/// @return 0 on success, 1 otherwise
static Function PSQ_CR_SetAutobiasTargetVFromTrueRMP(string device, variable headstage, string params)
	variable useTrueRestingMembPot, averageVoltage, sweepNo
	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	useTrueRestingMembPot = AFH_GetAnalysisParamNumerical("UseTrueRestingMembranePotentialVoltage", params, defValue = PSQ_CR_USE_TRUE_RMP_DEF)

	if(!useTrueRestingMembPot)
		return 1
	endif

	sweepNo = PSQ_GetLastPassingTrueRMP(device, headstage)
	if(!IsValidSweepNumber(sweepNo))
		print "Warning: Could not find a passing set with \"PSQ_TrueRestingMembranePotential\" analysis function."
		ControlWindowToFront()
		return 1
	endif

	key            = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_VM_FULL_AVG, query = 1)
	averageVoltage = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE) * ONE_TO_MILLI
	ASSERT(IsFinite(averageVoltage), "Invalid full average voltage")

	PSQ_SetAutobiasTargetV(device, headstage, averageVoltage)

	return 0
End

Function/S PSQ_Chirp_GetHelp(string name)

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "BaselineTargetVThreshold":
		case "FailedLevel":
		case "NumberOfFailedSweeps":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_GetHelpCommon(PSQ_CHIRP, name)
		case "AmpBesselFilter":
			return "Applies a bessel filter to the primary output.\r Defaults to 10e3 [Hz]," \
			       + "pass \"" + num2str(LPF_BYPASS, "%g") + "\" to select \"Bypass\"."
		case "AmpBesselFilterRestore":
			return "Restores the previously active bessel filter in POST_SET_EVENT. Defaults to ON."
		case "AutobiasTargetV":
			return "Autobias targetV [mV] value set in PRE_SET_EVENT"
		case "AutobiasTargetVAtSetEnd":
			return "Autobias targetV [mV] value set in POST_SET_EVENT (only set if set QC passes)."
		case "BoundsEvaluationMode":
			return "Select the bounds evaluation mode: Symmetric (Lower and Upper), Depolarized (Upper) or Hyperpolarized (Lower)"
		case "DAScaleOperator":
			return "Set the math operator to use for combining the DAScale and the "          \
			       + "modifier. Valid strings are \"+\" (addition) and \"*\" (multiplication)."
		case "DAScaleModifier":
			return "Modifier value to the DA Scale of headstages with spikes during chirp"
		case "InnerRelativeBound":
			return "Lower bound of a confidence band for the acquired data relative to the pre pulse baseline in mV. Must be positive."
		case "NumberOfChirpCycles":
			return "Number of acquired chirp cycles before the bounds evaluation starts. Defaults to 1."
		case "OuterRelativeBound":
			return "Upper bound of a confidence band for the acquired data relative to the pre pulse baseline in mV. Must be positive."
		case "SpikeCheck":
			return "Toggle spike check during the chirp. Defaults to off."
		case "UserOnsetDelay":
			return "Will be set as user onset delay in PRE_SET_EVENT, the current value will be set back in POST_SET_EVENT."
		case "UseTrueRestingMembranePotentialVoltage":
			return "Use the average voltage of a passing True RMS voltage set as Autobias targetV [mV] " + \
			       "instead of \"AutobiasTargetVAtSetEnd\" in POST_SET_EVENT. Defaults to on."
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

Function/S PSQ_Chirp_CheckParam(string name, STRUCT CheckParametersStruct &s)
	variable val
	string   str

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "BaselineTargetVThreshold":
		case "DAScaleOperator":
		case "DAScaleModifier":
		case "FailedLevel":
		case "NumberOfFailedSweeps":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_CheckParamCommon(name, s)
		case "AmpBesselFilter":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val) || val <= 0)
				return "Must be a positive value."
			endif
			break
		case "AmpBesselFilterRestore":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val))
				return "Must be a finite value"
			endif
			break
		case "AutobiasTargetV":
		case "AutobiasTargetVAtSetEnd":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val) || val == 0)
				return "Invalid value " + num2str(val)
			endif
			break
		case "BoundsEvaluationMode":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(WhichListItem(str, PSQ_CR_BEM) == -1)
				return "Invalid value " + str
			endif
			break
		case "InnerRelativeBound":
			if(AFH_GetAnalysisParamNumerical("InnerRelativeBound", s.params) >= AFH_GetAnalysisParamNumerical("OuterRelativeBound", s.params))
				return "InnerRelativeBound must be smaller than OuterRelativeBound"
			endif
		case "OuterRelativeBound": // fallthrough-by-design
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val) || val < PSQ_CR_LIMIT_BAND_LOW || val > PSQ_CR_LIMIT_BAND_HIGH)
				return "Out of bounds with value " + num2str(val)
			endif
			break
		case "NumberOfChirpCycles":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val) || !IsInteger(val) || val <= 0)
				return "Must be a finite non-zero integer"
			endif
			break
		case "SpikeCheck":
		case "UseTrueRestingMembranePotentialVoltage": // fallthrough-by-design
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val))
				return "Must be a finite value"
			endif
			break
		case "UserOnsetDelay":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val) || val < 0)
				return "Must be a finite value"
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

/// @brief Return a list of required analysis functions for PSQ_Chirp()
Function/S PSQ_Chirp_GetParams()
	return "[AmpBesselFilter:variable],"                   + \
	       "[AmpBesselFilterRestore:variable],"            + \
	       "AsyncQCChannels:wave,"                         + \
	       "[AutobiasTargetV:variable],"                   + \
	       "[AutobiasTargetVAtSetEnd:variable],"           + \
	       "[BaselineRMSLongThreshold:variable],"          + \
	       "[BaselineRMSShortThreshold:variable],"         + \
	       "[BaselineTargetVThreshold:variable],"          + \
	       "BoundsEvaluationMode:string,"                  + \
	       "[DAScaleModifier:variable],"                   + \
	       "[DAScaleOperator:string],"                     + \
	       "[FailedLevel:variable],"                       + \
	       "InnerRelativeBound:variable,"                  + \
	       "[NumberOfChirpCycles:variable],"               + \
	       "NumberOfFailedSweeps:variable,"                + \
	       "OuterRelativeBound:variable,"                  + \
	       "[SamplingFrequency:variable],"                 + \
	       "SamplingMultiplier:variable,"                  + \
	       "[SpikeCheck:variable],"                        + \
	       "[UserOnsetDelay:variable],"                    + \
	       "[UseTrueRestingMembranePotentialVoltage:variable]"
End

/// @brief Analysis function for determining the impedance of the cell using a sine chirp stim set
///
/// Prerequisites:
/// - Does only work for one headstage
/// - Assumes that the stimset has a chirp of non-zero and arbitrary length
/// - Pre pulse baseline length is #PSQ_BL_EVAL_RANGE
/// - Post pulse baseline length is at least two times #PSQ_BL_EVAL_RANGE
///
/// Testing:
/// For testing the range detection logic, the results can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-chirp.svg
/// \endrst
///
/// The bounds action for Symmetric (Upper and Lower) is derived from the state according to the following sketch:
///
/// \rst
///	.. image:: ../patch-seq-chirp-bounds-state-action.png
///
/// Depolarized (Upper only):
///
/// ======= ==========
///  State   Action
/// ======= ==========
///  BA      Pass
///  AA      Decrease
///  BB      Increase
/// ======= ==========
///
/// Hyperpolarized (Lower only):
///
/// ======= ==========
///  State   Action
/// ======= ==========
///  BA      Pass
///  AA      Increase
///  BB      Decrease
/// ======= ==========
///
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with pre pulse baseline (-), sine chirp (~), and post pulse baseline (-).
///
///
///
///                     ~               ~
///                   ~  ~             ~ ~
///                  ~    ~           ~   ~
///                 ~      ~         ~     ~
/// ---------------~        ~       ~       ~--------------------------------
///                          ~     ~
///                           ~   ~
///                             ~
///
/// @endverbatim
Function PSQ_Chirp(device, s)
	string                      device
	STRUCT AnalysisFunction_V3 &s

	variable InnerRelativeBound, OuterRelativeBound, sweepPassed, setPassed, boundsAction, failsInSet, leftSweeps, chunk, multiplier
	variable length, minLength, DAC, resistance, passingDaScaleSweep, sweepsInSet, passesInSet, acquiredSweepsInSet, samplingFrequencyPassed
	variable targetVoltage, initialDAScale, baselineQCPassed, insideBounds, scalingFactorDAScale, initLPF, ampBesselFilter
	variable fifoTime, i, ret, range, chirpStart, chirpDuration, userOnsetDelay, asyncAlarmPassed
	variable numberOfChirpCycles, cycleEnd, maxOccurences, level, numberOfSpikesFound, abortDueToSpikes, spikeCheck, besselFilterRestore
	variable spikeCheckPassed, daScaleModifier, chirpEnd, numSweepsFailedAllowed, boundsEvaluationMode, stimsetPass, retCheckDAScale
	string setName, key, msg, stimset, str, daScaleOperator

	innerRelativeBound     = AFH_GetAnalysisParamNumerical("InnerRelativeBound", s.params)
	numberOfChirpCycles    = AFH_GetAnalysisParamNumerical("NumberOfChirpCycles", s.params, defValue = 1)
	outerRelativeBound     = AFH_GetAnalysisParamNumerical("OuterRelativeBound", s.params)
	numSweepsFailedAllowed = AFH_GetAnalysisParamNumerical("NumberOfFailedSweeps", s.params)
	multiplier             = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)
	boundsEvaluationMode   = PSQ_CR_ParseBoundsEvaluationModeString(AFH_GetAnalysisParamTextual("BoundsEvaluationMode", s.params))

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			length    = PSQ_GetDAStimsetLength(device, s.headstage)
			minLength = 3 * PSQ_BL_EVAL_RANGE
			if(length < minLength)
				printf "(%s) Stimset of headstage %d is too short, it must be at least %g ms long.\r", device, s.headstage, minLength
				ControlWindowToFront()
				return 1
			endif

			DAC     = AFH_GetDACFromHeadstage(device, s.headstage)
			setName = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
			if(IDX_NumberOfSweepsInSet(setName) < PSQ_CR_NUM_SWEEPS_PASS)
				printf "(%s): The stimset must have at least %d sweeps\r", device, PSQ_CR_NUM_SWEEPS_PASS
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_CHIRP, s.headstage, s.sweepNo)

			PSQ_SetAutobiasTargetVIfPresent(device, s.headstage, s.params, "AutobiasTargetV")

			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 0)
			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			if(s.eventType == PRE_SET_EVENT)
				spikeCheck = !!AFH_GetAnalysisParamNumerical("SpikeCheck", s.params, defValue = PSQ_CR_SPIKE_CHECK_DEFAULT)

				// if spikeCheck is enabled we also need the other analysis parameters
				// which are now not optional anymore
				if(spikeCheck)
					if(!PSQ_CR_FindDependentAnalysisParameter(device, "FailedLevel", s.params))
						return 1
					elseif(!PSQ_CR_FindDependentAnalysisParameter(device, "DAScaleModifier", s.params))
						return 1
					elseif(!PSQ_CR_FindDependentAnalysisParameter(device, "DAScaleOperator", s.params))
						return 1
					endif
				endif

				WAVE values = LBN_GetNumericWave()
				values[INDEP_HEADSTAGE] = spikeCheck
				key                     = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_SPIKE_CHECK)
				ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

				if(TestOverrideActive())
					resistance = PSQ_CR_RESISTANCE_FAKE * GIGA_TO_ONE
				else
					passingDaScaleSweep = PSQ_GetLastPassingDAScale(device, s.headstage, PSQ_DS_SUB)

					if(!IsValidSweepNumber(passingDaScaleSweep))
						printf "(%s): We could not find a passing sweep with DAScale analysis function in Subthreshold mode.\r", device
						ControlWindowToFront()
						return 1
					endif

					// predates CreateAnaFuncLBNKey(), so we have to use a hardcoded name
					WAVE/Z resistanceFromFit = GetLastSetting(numericalValues, passingDaScaleSweep, LABNOTEBOOK_USER_PREFIX + LBN_RESISTANCE_FIT, UNKNOWN_MODE)

					if(!WaveExists(resistanceFromFit))
						printf "(%s): The Resistance labnotebook entry could not be found.\r", device
						ControlWindowToFront()
						return 1
					endif

					resistance = resistanceFromFit[s.headstage]
				endif

				sprintf msg, "Resistance: %g [Ω]\r", resistance
				DEBUGPRINT(msg)

				WAVE result = LBN_GetNumericWave()
				result[INDEP_HEADSTAGE] = resistance

				key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_RESISTANCE)
				ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = s.sweepNo, unit = "Ohm")

				targetVoltage  = ((outerRelativeBound + innerRelativeBound) / 2) * MILLI_TO_ONE
				initialDAScale = targetVoltage / resistance

				sprintf msg, "Initial DAScale: %g [Amperes]\r", initialDAScale
				DEBUGPRINT(msg)

				WAVE result = LBN_GetNumericWave()
				key                     = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_INITIAL_SCALE)
				result[INDEP_HEADSTAGE] = initialDAScale
				ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = s.sweepNo)

				// not checking DAScale limits as we can't do that in PRE_SET_EVENT
				SetDAScale(device, s.headstage, s.sweepNo, absolute = initialDAScale, roundTopA = 1, limitCheck = 0)

				WAVE result = LBN_GetNumericWave()
				key                     = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INIT_UOD)
				result[INDEP_HEADSTAGE] = DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser")
				ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = s.sweepNo, unit = "ms")

				userOnsetDelay = AFH_GetAnalysisParamNumerical("UserOnsetDelay", s.params)
				if(IsFinite(userOnsetDelay))
					PGC_SetAndActivateControl(device, "setvar_DataAcq_OnsetDelayUser", val = userOnsetDelay)
				endif

				WAVE result = LBN_GetNumericWave()
				initLPF = AI_SendToAmp(device, s.headstage, I_CLAMP_MODE, MCC_GETPRIMARYSIGNALLPF_FUNC, NaN)
				ASSERT(IsFinite(initLPF), "Queried LPF value from MCC amp is non-finite")
				result[INDEP_HEADSTAGE] = initLPF
				key                     = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INIT_LPF)
				ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = s.sweepNo, unit = "Hz")

				ampBesselFilter = AFH_GetAnalysisParamNumerical("AmpBesselFilter", s.params, defValue = PSQ_CR_DEFAULT_LPF)

				ret = AI_SendToAmp(device, s.headstage, I_CLAMP_MODE, MCC_SETPRIMARYSIGNALLPF_FUNC, ampBesselFilter, selectAmp = 0)
				ASSERT(!ret, "Could not set LPF in MCC")
			endif
			break
		case PRE_SWEEP_CONFIG_EVENT:
			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			ret = PSQ_CheckThatAlarmIsEnabled(device, asyncChannels)
			if(ret)
				return 1
			endif
			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			// if we don't have a PSQ_FMT_LBN_BL_QC_PASS entry this means it did not pass
			baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

			key          = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INSIDE_BOUNDS, query = 1)
			insideBounds = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE, defValue = 0)

			key        = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_SPIKE_CHECK, query = 1)
			spikeCheck = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			ASSERT(IsFinite(spikeCheck), "Invalid spikeCheck value")

			key         = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_STIMSET_QC, query = 1)
			stimsetPass = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(IsFinite(stimsetPass), "Invalid stimsetPass value")

			key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SPIKE_PASS, query = 1)
			WAVE/Z spikeCheckPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			spikeCheckPassed = WaveExists(spikeCheckPassedLBN) ? spikeCheckPassedLBN[s.headstage] : 0

			samplingFrequencyPassed = PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(device, PSQ_CHIRP, s)

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			asyncAlarmPassed = PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(device, PSQ_CHIRP, s.sweepNo, asyncChannels)

			sweepPassed = (baselineQCPassed == 1 && insideBounds == 1 && samplingFrequencyPassed == 1 && asyncAlarmPassed == 1 && stimsetPass == 1)

			if(spikeCheck)
				sweepPassed = (sweepPassed == 1 && spikeCheckPassed == 1)
			endif

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = sweepPassed
			key                     = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			WAVE/T stimsets = GetLastSetting(textualValues, s.sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			stimset = stimsets[s.headstage]

			sweepsInSet         = IDX_NumberOfSweepsInSet(stimset)
			passesInSet         = PSQ_NumPassesInSet(numericalValues, PSQ_CHIRP, s.sweepNo, s.headstage)
			acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(device, s.sweepNo, s.headstage)
			failsInSet          = acquiredSweepsInSet - passesInSet
			leftSweeps          = sweepsInSet - acquiredSweepsInSet

			[setPassed, maxOccurences] = PSQ_CR_SetHasPassed(numericalValues, s.sweepNo, s.headstage)

			if(setPassed)
				PSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
			else
				if((maxOccurences + leftSweeps) < PSQ_CR_NUM_SWEEPS_PASS)
					// not enough sweeps left to pass the set
					// we need PSQ_CR_NUM_SWEEPS_PASS with the same
					// DAScale value
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)
				elseif(failsInSet >= numSweepsFailedAllowed)
					// failed too many sweeps
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)
				elseif(!samplingFrequencyPassed)
					PSQ_ForceSetEvent(device, s.headstage)
					RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)
				endif
			endif

			sprintf msg, "Sweep %s, Set %s, total sweeps %g, acquired sweeps %g, sweeps passed %g, sweeps passed with same DAScale %g, spike check performed %g, spike check %s\r", ToPassFail(sweepPassed), ToPassFail(setPassed), sweepsInSet, acquiredSweepsInSet, passesInSet, maxOccurences, spikeCheck, ToPassFail(spikeCheckPassed)
			DEBUGPRINT(msg)

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			[setPassed, maxOccurences] = PSQ_CR_SetHasPassed(numericalValues, s.sweepNo, s.headstage)

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = setPassed
			key                     = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			if(setPassed)
				ret = PSQ_CR_SetAutobiasTargetVFromTrueRMP(device, s.headstage, s.params)

				if(ret)
					PSQ_SetAutobiasTargetVIfPresent(device, s.headstage, s.params, "AutobiasTargetVAtSetEnd")
				endif
			endif

			key            = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INIT_UOD, query = 1)
			userOnsetDelay = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			ASSERT(IsFinite(userOnsetDelay), "Expected finite value for user onset delay")
			PGC_SetAndActivateControl(device, "setvar_DataAcq_OnsetDelayUser", val = userOnsetDelay)

			besselFilterRestore = !!AFH_GetAnalysisParamNumerical("AmpBesselFilterRestore", s.params, defValue = 1)
			if(besselFilterRestore)
				key             = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INIT_LPF, query = 1)
				ampBesselFilter = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
				ASSERT(IsFinite(ampBesselFilter), "Expected finite value for the amplifier bessel filter")
				ret = AI_SendToAmp(device, s.headstage, I_CLAMP_MODE, MCC_SETPRIMARYSIGNALLPF_FUNC, ampBesselFilter)
				ASSERT(IsFinite(ret), "Can not set LPF value in MCC amp")
			endif

			AD_UpdateAllDatabrowser()
			break
		case POST_DAQ_EVENT:
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	fifoTime = s.lastKnownRowIndexAD * s.sampleIntervalAD

	spikeCheck = !!AFH_GetAnalysisParamNumerical("SpikeCheck", s.params, defValue = PSQ_CR_SPIKE_CHECK_DEFAULT)

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SPIKE_PASS, query = 1)
	WAVE/Z spikeCheckPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	spikeCheckPassed = WaveExists(spikeCheckPassedLBN) ? spikeCheckPassedLBN[s.headstage] : NaN

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : NaN

	key          = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INSIDE_BOUNDS, query = 1)
	insideBounds = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

	sprintf msg, "Midsweep: insideBounds %g, baselineQCPassed %g, spikeCheck %g, spikeCheckPassed %g", insideBounds, baselineQCPassed, spikeCheck, spikeCheckPassed
	DEBUGPRINT(msg)

	if(IsFinite(insideBounds) && IsFinite(baselineQCPassed) && (!spikeCheck || (spikeCheck && IsFinite(spikeCheckPassed) && spikeCheckPassed)))
		// nothing more to do if we did inside bounds check and baseline QC and either did not do spike checking or spike checking passed
		return NaN
	endif

	[chirpStart, cycleEnd] = PSQ_CR_GetChirpEvaluationRange(device, s.sweepNo, s.headstage, numberOfChirpCycles)

	sprintf msg, "chirpStart %g, fifoTime %g, cycleEnd %g", chirpStart, fifoTime, cycleEnd
	DEBUGPRINT(msg)

	if(IsNaN(chirpStart) || IsNaN(chirpEnd))
		// error calculating chirp evaluation user epoch
		PSQ_ForceSetEvent(device, s.headstage)
		RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)

		return ANALYSIS_FUNC_RET_EARLY_STOP
	endif

	if(spikeCheck && IsNaN(spikeCheckPassed))
		[chirpStart, chirpEnd] = PSQ_CR_GetSpikeEvaluationRange(device, s.sweepNo, s.headstage)

		sprintf msg, "Spike check: chirpStart (relative to zero) %g, chirpEnd %g, fifoTime %g", chirpStart, chirpEnd, fifoTime
		DEBUGPRINT(msg)

		if(fifoTime > chirpStart)
			level = AFH_GetAnalysisParamNumerical("FailedLevel", s.params)

			WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_CHIRP, s.scaledDACWave, s.headstage, chirpStart, level, searchEnd = chirpEnd, \
			                                          numberOfSpikesFound = numberOfSpikesFound, numberOfSpikesReq = Inf)
			WaveClear spikeDetection

			if(numberOfSpikesFound > 0)
				WAVE spikePass = LBN_GetNumericWave()
				spikePass[s.headstage] = 0
			elseif(fifoTime > chirpEnd)
				// beyond chirp and we found nothing, so we passed
				WAVE spikePass = LBN_GetNumericWave()
				spikePass[s.headstage] = 1
			endif

			if(WaveExists(spikePass))
				key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SPIKE_PASS)
				ED_AddEntryToLabnotebook(device, key, spikePass, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

				spikeCheckPassed = spikePass[s.headstage]
			endif
		endif
	endif

	// no early return here because we want to do baseline QC checks (and chunk creation) always

	if(IsNaN(baselineQCPassed))
		[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_CHIRP, s)

		if(IsFinite(ret))
			baselineQCPassed = (ret == 0)

			PSQ_EvaluateBaselinePassed(device, PSQ_CHIRP, s.sweepNo, s.headstage, chunk, ret)
		endif
	endif

	if(spikeCheck && IsFinite(spikeCheckPassed) && !spikeCheckPassed)
		// adapt DAScale and finish
		daScaleModifier = AFH_GetAnalysisParamNumerical("DAScaleModifier", s.params)
		daScaleOperator = AFH_GetAnalysisParamTextual("DAScaleOperator", s.params)
		retCheckDAScale = SetDAScaleModOp(device, s.headstage, s.sweepNo, daScaleModifier, daScaleOperator, roundTopA = 1)

		if(retCheckDAScale)
			ComplainOutOfRangeDAScale(device, s.sweepNo, PSQ_CHIRP)
		endif

		return ANALYSIS_FUNC_RET_EARLY_STOP
	endif

	if((IsNaN(baselineQCPassed) || baselineQCPassed) && IsNaN(insideBounds) && fifoTime >= cycleEnd)
		// inside bounds search was inconclusive up to now
		// and we have acquired enough cycles
		// and baselineQC is not failing

		[boundsAction, scalingFactorDaScale] = PSQ_CR_DetermineBoundsAction(device, s.scaledDACWave, s.headstage, s.sweepNo, chirpStart, cycleEnd, innerRelativeBound, outerRelativeBound, boundsEvaluationMode)
		insideBounds = (boundsAction == PSQ_CR_PASS)
		WAVE result = LBN_GetNumericWave()
		result[INDEP_HEADSTAGE] = insideBounds
		key                     = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_INSIDE_BOUNDS)
		ED_AddEntryToLabnotebook(device, key, result, overrideSweepNo = s.sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)

		switch(boundsAction)
			case PSQ_CR_PASS:
			case PSQ_CR_RERUN: // fallthrough-by-design
				// nothing to do
				break
			case PSQ_CR_INCREASE:
			case PSQ_CR_DECREASE: // fallthrough-by-design
				retCheckDAScale = SetDAScale(device, s.headstage, s.sweepNo, relative = scalingFactorDAScale, roundTopA = 1)

				if(retCheckDAScale)
					ComplainOutOfRangeDAScale(device, s.sweepNo, PSQ_CHIRP)
					return ANALYSIS_FUNC_RET_EARLY_STOP
				endif
				break
			default:
				ASSERT(0, "impossible case")
		endswitch
	endif

	if(IsFinite(baselineQCPassed) && baselineQCPassed)
		ASSERT(IsFinite(insideBounds), "Must be already checked")
		return ANALYSIS_FUNC_RET_EARLY_STOP
	elseif(IsFinite(baselineQCPassed) && !baselineQCPassed)
		return ret
	elseif(!insideBounds)
		return ANALYSIS_FUNC_RET_EARLY_STOP
	endif

	return NaN
End

static Function PSQ_CR_FindDependentAnalysisParameter(string device, string name, string params)

	string strRep = AFH_GetAnalysisParameter(name, params)

	if(IsEmpty(strRep))
		printf "(%s): The analysis parameter \"%s\" is missing, but it is not optional when \"SpikeCheck\" is enabled.\r", device, name
		ControlWindowToFront()
		return 0
	endif

	return 1
End

/// @brief Return the begin/start [ms] of the spike bounds evaluation range
///
/// Zero is the DA/AD wave zero.
static Function [variable epBegin, variable epEnd] PSQ_CR_GetSpikeEvaluationRange(string device, variable sweepNo, variable headstage)
	variable DAC, totalOnsetDelay

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	DAC = AFH_GetDACFromHeadstage(device, headstage)

	WAVE epochsWave = GetEpochsWave(device)

	WAVE/T/Z evaluationEpoch = EP_GetEpochs(numericalValues, textualValues, NaN, XOP_CHANNEL_TYPE_DAC, DAC,   \
	                                        "^U_CR_SE$", treelevel = EPOCH_USER_LEVEL, epochsWave = epochsWave)

	if(WaveExists(evaluationEpoch))
		ASSERT(DimSize(evaluationEpoch, ROWS) == 1, "Invalid spike evaluation wave size")
		epBegin = str2num(evaluationEpoch[0][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
		epEnd   = str2num(evaluationEpoch[0][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI
		return [epBegin, epEnd]
	endif

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)

	WAVE durations = PSQ_GetPulseDurations(device, PSQ_CHIRP, sweepNo, totalOnsetDelay)

	[epBegin, epEnd] = PSQ_CR_AddSpikeEvaluationEpoch(epochsWave, DAC, headstage, durations, totalOnsetDelay)

	return [epBegin * ONE_TO_MILLI, epEnd * ONE_TO_MILLI]
End

/// @brief Adds PSQ_Chirp spike evaluation epoch
///
/// @param epochsWave        4d epochs wave
/// @param DAC               DAC number
/// @param headstage         headstage number
/// @param durations         pulse duration wave
/// @param totalOnsetDelayMS totalOnsetDelay in ms
///
/// @retval epBegin epoch begin in s
/// @retval epEnd   epoch end in s
Function [variable epBegin, variable epEnd] PSQ_CR_AddSpikeEvaluationEpoch(WAVE/T epochsWave, variable DAC, variable headstage, WAVE durations, variable totalOnsetDelayMS)

	variable chirpStart, chirpEnd
	string tags, shortName

	chirpStart = totalOnsetDelayMS + PSQ_BL_EVAL_RANGE
	chirpEnd   = chirpStart + durations[headstage]

	epBegin = chirpStart * MILLI_TO_ONE
	epEnd   = chirpEnd * MILLI_TO_ONE

	sprintf tags, "Type=Chirp spike evaluation"
	sprintf shortName, "CR_SE"

	EP_AddUserEpoch(epochsWave, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)

	return [epBegin, epEnd]
End

/// @brief Return the begin/start [ms] of the chirp bounds evaluation range
///
/// Zero is the DA/AD wave zero.
static Function [variable epBegin, variable epEnd] PSQ_CR_GetChirpEvaluationRange(string device, variable sweepNo, variable headstage, variable requestedCycles)

	variable DAC, stimsetQC
	string name, tags, shortname, key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	DAC = AFH_GetDACFromHeadstage(device, headstage)

	WAVE epochsWave = GetEpochsWave(device)

	WAVE/T/Z evaluationEpoch = EP_GetEpochs(numericalValues, textualValues, NaN, XOP_CHANNEL_TYPE_DAC, DAC,   \
	                                        "^U_CR_CE$", treelevel = EPOCH_USER_LEVEL, epochsWave = epochsWave)

	if(WaveExists(evaluationEpoch))
		ASSERT(DimSize(evaluationEpoch, ROWS) == 1, "Invalid chirp evaluation wave size")
		epBegin = str2num(evaluationEpoch[0][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
		epEnd   = str2num(evaluationEpoch[0][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI
		return [epBegin, epEnd]
	endif

	WAVE/Z/T fullCycleEpochs = PSQ_CR_GetFullCycleEpochs(numericalValues, textualValues, DAC, epochsWave, requestedCycles)
	if(!WaveExists(fullCycleEpochs))
		printf "Could not find chirp cycles in epoch 1.\r"
		ControlWindowToFront()
		stimsetQC = 0
	elseif(requestedCycles > 1 && DimSize(fullCycleEpochs, ROWS) == 1)
		printf "Could not find enough chirp cycles in epoch 1 as %d number of cycles were requested.\r", requestedCycles
		ControlWindowToFront()
		stimsetQC = 0
	else
		stimsetQC = 1
	endif

	WAVE result = LBN_GetNumericWave()
	result[INDEP_HEADSTAGE] = stimsetQC
	key                     = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_STIMSET_QC)
	ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	if(!stimsetQC)
		return [NaN, NaN]
	endif

	[epBegin, epEnd] = PSQ_CR_AddCycleEvaluationEpoch(epochsWave, fullCycleEpochs, DAC)

	return [epBegin * ONE_TO_MILLI, epEnd * ONE_TO_MILLI]
End

/// @brief Add PSQ_Chirp cycle evaluation epoch
///
/// @param epochsWave      4d epoch wave
/// @param fullCycleEpochs 2d epoch wave with epochs of full cycles (sorted)
/// @param DAC             DAC number
///
/// @retval epBegin epoch begin in s
/// @retval epEnd   epoch end in s
Function [variable epBegin, variable epEnd] PSQ_CR_AddCycleEvaluationEpoch(WAVE/T epochsWave, WAVE/T fullCycleEpochs, variable DAC)

	string tags, shortName

	epBegin = str2num(fullCycleEpochs[0][EPOCH_COL_STARTTIME])
	epEnd   = str2num(fullCycleEpochs[DimSize(fullCycleEpochs, ROWS) - 1][EPOCH_COL_ENDTIME])

	sprintf tags, "Type=Chirp cycles evaluation"
	sprintf shortName, "CR_CE"

	EP_AddUserEpoch(epochsWave, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)

	return [epBegin, epEnd]
End

Function/WAVE PSQ_CR_GetFullCycleEpochs(WAVE numericalValues, WAVE/T textualValues, variable DAC, WAVE/T epochsWave, variable requestedCycles)

	string regexp

	sprintf regexp, "^(E1_TG_C%d|E1_TG_C%d)$", 0, requestedCycles - 1
	WAVE/T/Z fullCycleEpochs = EP_GetEpochs(numericalValues, textualValues, NaN, XOP_CHANNEL_TYPE_DAC, DAC, \
	                                        regexp, treelevel = 2, epochsWave = epochsWave)

	return fullCycleEpochs
End

/// @brief Manually force the pre/post set events
///
/// Required to do before skipping sweeps.
/// @todo this hack must go away.
static Function PSQ_ForceSetEvent(device, headstage)
	string   device
	variable headstage

	variable DAC

	WAVE setEventFlag = GetSetEventFlag(device)
	DAC = AFH_GetDACFromHeadstage(device, headstage)

	setEventFlag[DAC][%PRE_SET_EVENT]  = 1
	setEventFlag[DAC][%POST_SET_EVENT] = 1
End

/// @brief Execute `code` in the SweepFormula notebook
static Function/S PSQ_ExecuteSweepFormula(string device, string code)
	string databrowser, bsPanel, sfNotebook

	databrowser = DB_GetBoundDataBrowser(device, mode = BROWSER_MODE_AUTOMATION)

	SF_SetFormula(databrowser, code)

	bsPanel = BSP_GetPanel(databrowser)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_SF", val = 1)
	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display", val = NaN)

	return databrowser
End

static Function PSQ_SetSamplingIntervalMultiplier(string device, variable multiplier)

	string multiplierAsString = num2str(multiplier)

	PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str = multiplierAsString)
	ASSERT(!cmpstr(DAG_GetTextualValue(device, "Popup_Settings_SampIntMult"), multiplierAsString), "Sampling interval multiplier could not be set")
End

static Function PSQ_SetStimulusSets(string device, variable headstage, string params)
	string ctrl, stimset, stimsetIndex
	variable DAC, type, enableIndexing, tabID

	stimset      = AFH_GetAnalysisParamTextual("NextStimSetName", params, defValue = NONE)
	stimsetIndex = AFH_GetAnalysisParamTextual("NextIndexingEndStimSetName", params, defValue = NONE)

	if(!cmpstr(stimset, NONE) && !cmpstr(stimsetIndex, NONE))
		return NaN
	endif

	tabID = GetTabID(device, "ADC")

	DAC = AFH_GetDACFromHeadstage(device, headstage)

	if(cmpstr(stimset, NONE))
		ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		PGC_SetAndActivateControl(device, ctrl, str = stimset, switchTab = 1)
	endif

	if(cmpstr(stimsetIndex, NONE))
		ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
		PGC_SetAndActivateControl(device, ctrl, str = stimsetIndex, switchTab = 1)

		PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = 1)
	endif

	if(tabID != GetTabID(device, "ADC"))
		PGC_SetAndActivateControl(device, "ADC", val = tabID)
	endif
End

Function/S PSQ_PipetteInBath_CheckParam(string name, STRUCT CheckParametersStruct &s)
	variable val
	string   str

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "MaxLeakCurrent":
		case "NextIndexingEndStimSetName":
		case "NextStimSetName":
		case "NumberOfFailedSweeps":
		case "NumberOfTestpulses":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_CheckParamCommon(name, s)
		case "MinPipetteResistance":
		case "MaxPipetteResistance":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0 && val <= 20))
				return "Invalid value " + num2str(val)
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_PipetteInBath_GetHelp(string name)

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "MaxLeakCurrent":
		case "NextIndexingEndStimSetName":
		case "NextStimSetName":
		case "NumberOfFailedSweeps":
		case "NumberOfTestpulses":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_GetHelpCommon(PSQ_PIPETTE_BATH, name)
		case "MinPipetteResistance":
			return "Minimum allowed pipette resistance [MΩ]"
		case "MaxPipetteResistance":
			return "Maximum allowed pipette resistance [MΩ]"
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_PipetteInBath_GetParams()
	return "AsyncQCChannels:wave,"                 + \
	       "[BaselineRMSLongThreshold:variable],"  + \
	       "[BaselineRMSShortThreshold:variable]," + \
	       "MaxLeakCurrent:variable,"              + \
	       "MaxPipetteResistance:variable,"        + \
	       "MinPipetteResistance:variable,"        + \
	       "[NextIndexingEndStimSetName:string],"  + \
	       "[NextStimSetName:string],"             + \
	       "NumberOfFailedSweeps:variable,"        + \
	       "NumberOfTestpulses:variable,"          + \
	       "[SamplingFrequency:variable],"         + \
	       "SamplingMultiplier:variable"
End

Function PSQ_PipetteInBath_GetNumberOfTestpulses(string params)

	return AFH_GetAnalysisParamNumerical("NumberOfTestpulses", params, defValue = 3)
End

/// @brief Analysis function for determining the pipette resistance while that is located in the bath
///
/// Prerequisites:
/// - Does only work for one headstage
/// - We expect three epochs per test pulse in the stimset, plus one epoch before all TPs, and at the very end
/// - Assumes that the stimset has `NumberOfTestpulses` test pulses
/// - Pre pulse baseline length is #PSQ_BL_EVAL_RANGE
/// - Post pulse baseline is not evaluated
///
/// Testing:
/// For testing the range detection logic, the results can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-pipette-bath.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with three test pulse like epochs
///
///                    +-----+       +-----+       +-----+
///                    |     |       |     |       |     |
///                    |     |       |     |       |     |
///                    |     |       |     |       |     |
/// -------------------+     +-------+     +-------+     +------------------------
///
/// Epoch borders
/// -------------
///
///       0        | 1 |  2  | 3 | 4 |  5  | 6 | 7 |  8  | 9 |     10
///
/// @endverbatim
Function PSQ_PipetteInBath(string device, STRUCT AnalysisFunction_V3 &s)
	variable multiplier, chunk, baselineQCPassed, ret, DAC, pipetteResistanceQCPassed, samplingFrequencyQCPassed, asyncAlarmPassed
	variable sweepsInSet, passesInSet, acquiredSweepsInSet, sweepPassed, setPassed, numSweepsFailedAllowed, failsInSet
	variable maxPipetteResistance, minPipetteResistance, expectedNumTestpulses, numTestPulses, pipetteResistance
	string key, ctrl, stimset, msg, databrowser, formula

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			if(DAG_GetHeadstageMode(device, s.headstage) != V_CLAMP_MODE)
				printf "(%s) Clamp mode must be voltage clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = s.headstage)
			PGC_SetAndActivateControl(device, "button_DataAcq_AutoPipOffset_VC", val = 1)
			PGC_SetAndActivateControl(device, "check_DatAcq_HoldEnableVC", val = 0)

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_PIPETTE_BATH, s.headstage, s.sweepNo)

			multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)
			PSQ_SetSamplingIntervalMultiplier(device, multiplier)
			break
		case PRE_SWEEP_CONFIG_EVENT:
			expectedNumTestpulses = PSQ_PipetteInBath_GetNumberOfTestpulses(s.params)
			ret                   = PSQ_CreateTestpulseEpochs(device, s.headstage, expectedNumTestpulses)
			if(ret)
				return 1
			endif

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			ret = PSQ_CheckThatAlarmIsEnabled(device, asyncChannels)
			if(ret)
				return 1
			endif

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			key = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(WaveExists(baselineQCPassedLBN), "Missing baseline QC")
			baselineQCPassed = baselineQCPassedLBN[s.headstage]

			sprintf formula, "store(\"Steady state resistance\", tp(tpss(), select(selchannels(AD), selsweeps(%d), selvis(all)), [0]))", s.sweepNo
			databrowser = PSQ_ExecuteSweepFormula(device, formula)

			minPipetteResistance = AFH_GetAnalysisParamNumerical("MinPipetteResistance", s.params)
			maxPipetteResistance = AFH_GetAnalysisParamNumerical("MaxPipetteResistance", s.params)

			WAVE/T textualResultsValues = BSP_GetLogbookWave(databrowser, LBT_RESULTS, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)

			pipetteResistance = PSQ_GetSweepFormulaResult(textualResultsValues, "Sweep Formula store [Steady state resistance]")

			// BEGIN TEST
			if(TestOverrideActive())
				WAVE overrideResults = GetOverrideResults()
				NVAR count           = $GetCount(device)
				pipetteResistance = overrideResults[0][count][1]
			endif
			// END TEST

			WAVE resistance = LBN_GetNumericWave()
			resistance[INDEP_HEADSTAGE] = pipetteResistance * MEGA_TO_ONE
			key                         = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_PB_RESISTANCE)
			ED_AddEntryToLabnotebook(device, key, resistance, unit = "Ω", overrideSweepNo = s.sweepNo)

			pipetteResistanceQCPassed = (pipetteResistance >= minPipetteResistance) && (pipetteResistance <= maxPipetteResistance)

			WAVE pipetteResistanceQC = LBN_GetNumericWave()
			pipetteResistanceQC[INDEP_HEADSTAGE] = pipetteResistanceQCPassed
			key                                  = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_PB_RESISTANCE_PASS)
			ED_AddEntryToLabnotebook(device, key, pipetteResistanceQC, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			samplingFrequencyQCPassed = PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(device, PSQ_PIPETTE_BATH, s)

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			asyncAlarmPassed = PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(device, PSQ_PIPETTE_BATH, s.sweepNo, asyncChannels)

			sweepPassed = baselineQCPassed && samplingFrequencyQCPassed && pipetteResistanceQCPassed && asyncAlarmPassed

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = sweepPassed
			key                     = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			numSweepsFailedAllowed = AFH_GetAnalysisParamNumerical("NumberOfFailedSweeps", s.params)
			ret                    = PSQ_DetermineSweepQCResults(device, PSQ_PIPETTE_BATH, s.sweepNo, s.headstage, PSQ_PB_NUM_SWEEPS_PASS, numSweepsFailedAllowed)

			if(ret == PSQ_RESULTS_DONE)
				break
			endif

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_PIPETTE_BATH, s.sweepNo, s.headstage) >= PSQ_PB_NUM_SWEEPS_PASS

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = setPassed
			key                     = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			PUB_PipetteInBath(device, s.sweepNo, s.headstage)

			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
		case POST_DAQ_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			key       = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_SET_PASS, query = 1)
			setPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(IsFinite(setPassed), "Missing setQC labnotebook entry")

			if(setPassed)
				PSQ_SetStimulusSets(device, s.headstage, s.params)
			endif

			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : NaN

	if(IsFinite(baselineQCPassed)) // already done
		return NaN
	endif

	[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_PIPETTE_BATH, s)

	// if baseline QC failed, we are done, otherwise we continue

	if(IsFinite(ret))
		PSQ_EvaluateBaselinePassed(device, PSQ_PIPETTE_BATH, s.sweepNo, s.headstage, chunk, ret)

		if(ret != 0)
			// baselineQC failed
			key = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0, query = 1)
			WAVE/Z leakCurQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			if(WaveExists(leakCurQCPassedLBN) && !leakCurQCPassedLBN[s.headstage])
				PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = s.headstage)
				PGC_SetAndActivateControl(device, "button_DataAcq_AutoPipOffset_VC", val = 1)
			endif

			return ret
		endif
	endif
End

/// @brief Return entries from the textual result wave written using `store` with the given `key`
///
/// Note: This function always returns the last entry, so this needs to be
///       called directly after PSQ_ExecuteSweepFormula without giving control back to Igor Pro.
static Function/WAVE PSQ_GetSweepFormulaResultWave(WAVE/T textualResultsValues, string key)
	string valueStr

	valueStr = GetLastSettingTextIndep(textualResultsValues, NaN, key, SWEEP_FORMULA_RESULT)

	if(IsEmpty(valueStr))
		return $""
	endif

	WAVE/WAVE container = JSONToWave(valueStr)
	ASSERT(DimSize(container, ROWS) == 1, "Invalid number of entries in return wave from Sweep Formula store")

	WAVE/Z wv = container[0]

	return wv
End

static Function PSQ_GetSweepFormulaResult(WAVE/T textualResultsValues, string key)

	WAVE/Z wv = PSQ_GetSweepFormulaResultWave(textualResultsValues, key)

	if(!WaveExists(wv))
		return NaN
	endif

	ASSERT(DimSize(wv, ROWS) == 1, "Invalid number of entries in wave from Sweep Formula")

	return wv[0]
End

static Function PSQ_PB_GetPrePulseBaselineDuration(string device, variable headstage)

	string setName

	setName = AFH_GetStimSetNameForHeadstage(device, headstage)

	return ST_GetStimsetParameterAsVariable(setName, "Duration", epochIndex = 0)
End

/// @brief Create user epochs for the testpulse like shapes in the stimset
///
/// Assumes that all sweeps in the stimset are the same.
///
/// @return 0 on success, 1 on failure
static Function PSQ_CreateTestpulseEpochs(string device, variable headstage, variable numTestPulses)

	variable DAC, totalOnsetDelay, DAScale
	string setName

	DAC             = AFH_GetDACFromHeadstage(device, headstage)
	setName         = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)
	DAScale         = DAG_GetNumericalValue(device, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), index = DAC)
	WAVE/T epochWave = GetEpochsWave(device)

	return PSQ_CreateTestpulseEpochsImpl(epochWave, DAC, setName, totalOnsetDelay, DAScale, numTestPulses)
End

/// @brief Device independent implementation function for @ref PSQ_CreateTestpulseEpochs
///
/// Assumes that all sweeps in the stimset are the same.
///
/// @return 0 on success, 1 on failure
Function PSQ_CreateTestpulseEpochsImpl(WAVE/T epochWave, variable DAC, string setName, variable totalOnsetDelay, variable DAScale, variable numTestPulses)

	variable prePulseTP, tpIndex
	variable offset, numEpochs, i, idx, requiredEpochs

	numEpochs      = ST_GetStimsetParameterAsVariable(setName, "Total number of epochs")
	requiredEpochs = numTestPulses * 3 + 2

	if(numEpochs < requiredEpochs)
		printf "For the requested number of test pulses (%g) we need at least %g epochs, but the stimset only has %g.\r", numTestpulses, requiredEpochs, numEpochs
		ControlWindowToFront()
		return 1
	endif

	offset = (totalOnsetDelay + ST_GetStimsetParameterAsVariable(setName, "Duration", epochIndex = 0)) * MILLI_TO_ONE

	// 0: pre pulse baseline chunk
	// 1: testpulse pre baseline
	// 2: testpulse signal
	// 3: testpulse post baseline
	// ...
	// 1 + n * 3: post pulse baseline
	for(i = 0; i < numTestPulses; i += 1)
		// first TP epoch
		idx = 1 + i * numTestPulses

		offset = PSQ_CreateTestpulseLikeEpoch(epochWave, DAC, setName, DAScale, offset, idx, tpIndex++)
	endfor

	return 0
End

static Function PSQ_CreateTestpulseLikeEpoch(WAVE/T epochWave, variable DAC, string setName, variable DAScale, variable start, variable epochIndex, variable tpIndex)
	variable prePulseTP, signalTP, postPulseTP
	variable amplitude, epBegin, epEnd
	string shortName, tags

	prePulseTP = ST_GetStimsetParameterAsVariable(setName, "Duration", epochIndex = epochIndex) * MILLI_TO_ONE
	amplitude  = ST_GetStimsetParameterAsVariable(setName, "Amplitude", epochIndex = epochIndex)
	ASSERT(amplitude == 0, "Invalid amplitude, expected zero for pre TP pulse BL")

	signalTP  = ST_GetStimsetParameterAsVariable(setName, "Duration", epochIndex = epochIndex + 1) * MILLI_TO_ONE
	amplitude = ST_GetStimsetParameterAsVariable(setName, "Amplitude", epochIndex = epochIndex + 1)
	ASSERT(amplitude != 0, "Invalid amplitude, expected non-zero for TP pulse")

	postPulseTP = ST_GetStimsetParameterAsVariable(setName, "Duration", epochIndex = epochIndex + 2) * MILLI_TO_ONE
	amplitude   = ST_GetStimsetParameterAsVariable(setName, "Amplitude", epochIndex = epochIndex + 2)
	ASSERT(amplitude == 0, "Invalid amplitude, expected zero for post TP pulse BL")

	// full TP
	epBegin = start
	epEnd   = epBegin + prePulseTP + signalTP + postPulseTP
	sprintf tags, "Type=Testpulse Like;Index=%d", tpIndex
	sprintf shortName, "TP%d", tpIndex

	EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)

	// pre TP baseline
	// same epBegin as full TP
	epEnd = epBegin + prePulseTP
	sprintf tags, "Type=Testpulse Like;SubType=Baseline;Index=%d;", tpIndex
	sprintf shortName, "TP%d_B0", tpIndex

	EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)

	// pulse TP
	epBegin   = epEnd
	epEnd     = epBegin + signalTP
	amplitude = ST_GetStimsetParameterAsVariable(setName, "Amplitude", epochIndex = epochIndex + 1) * DAScale
	sprintf tags, "Type=Testpulse Like;SubType=Pulse;Amplitude=%g;Index=%d;", amplitude, tpIndex
	sprintf shortName, "TP%d_P", tpIndex

	EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)

	// post TP baseline
	epBegin = epEnd
	epEnd   = epBegin + postPulseTP
	sprintf tags, "Type=Testpulse Like;SubType=Baseline;Index=%d;", tpIndex
	sprintf shortName, "TP%d_B1", tpIndex

	EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)

	return epEnd
End

Function/S PSQ_SealEvaluation_CheckParam(string name, STRUCT CheckParametersStruct &s)
	variable val
	string   str

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineChunkLength":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "NextIndexingEndStimSetName":
		case "NextStimSetName":
		case "NumberOfFailedSweeps":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_CheckParamCommon(name, s, maxThreshold = 100)
		case "SealThreshold":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0))
				return "Invalid value " + num2str(val)
			endif
			break
		case "TestPulseGroupSelector":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(WhichListItem(str, "Both;First;Second") == -1)
				return "Invalid value " + str
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_SealEvaluation_GetHelp(string name)

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineChunkLength":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "NextIndexingEndStimSetName":
		case "NextStimSetName":
		case "NumberOfFailedSweeps":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_GetHelpCommon(PSQ_SEAL_EVALUATION, name)
		case "SealThreshold":
			return "Minimum required seal threshold [GΩ]"
		case "TestPulseGroupSelector":
			return "Group(s) which have their resistance evaluated: One of Both/First/Second, defaults to Both"
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_SealEvaluation_GetParams()
	return "AsyncQCChannels:wave,"                 + \
	       "[BaselineChunkLength:variable],"       + \
	       "[BaselineRMSLongThreshold:variable],"  + \
	       "[BaselineRMSShortThreshold:variable]," + \
	       "[NextIndexingEndStimSetName:string],"  + \
	       "[NextStimSetName:string],"             + \
	       "NumberOfFailedSweeps:variable,"        + \
	       "[SamplingFrequency:variable],"         + \
	       "SamplingMultiplier:variable,"          + \
	       "SealThreshold:variable,"               + \
	       "[TestPulseGroupSelector:string]"
End

/// @brief Analysis function for checking the seal resistance
///
/// Prerequisites:
/// - Does only work for one headstage
/// - See below for the stimset layout
/// - The dedicated baseline epochs before each testpulse group (epoch 0 and 11)
///   and must be at least as large as the given `BaselineChunkLength` analysis
///   parameter
///
/// Testing:
/// For testing the range detection logic, the results can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-seal-evaluation.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of the stimset
///
///                    +-----+       +-----+       +-----+                                    +-----+       +-----+       +-----+
///                    |     |       |     |       |     |                                    |     |       |     |       |     |
///                    |     |       |     |       |     |                                    |     |       |     |       |     |
///                    |     |       |     |       |     |                                    |     |       |     |       |     |
/// -------------------+     +-------+     +-------+     +------------------------------------+     +-------+     +-------+     +------------
///
/// Epoch borders
/// -------------
///
///       0        | 1 |  2  | 3 | 4 |  5  | 6 | 7 |  8  | 9 |             10    |     11 | 12| 13  | 14| 15| 16  | 17|18 | 19  | 20 |  21  |
///
/// We always expect PSQ_SE_REQUIRED_EPOCHS (22) epochs even if the user only chose `First` or `Second` on testpulse selection.
///
///    BEGIN group A
/// 0: baselineQC chunk with length `BaselineChunkLength` or longer before group A
/// 1-3: 1. TP
/// 4-6: 2. TP
/// 7-9: 3. TP
///    END group A
/// 10: empty space, can be zero points long, but is always present
///    BEGIN group B
/// 11: baselineQC chunk with length `BaselineChunkLength` or longer before group B
/// 12-14: 1. TP
/// 15-17: 2. TP
/// 18-20: 3. TP
///    END group B
/// 21: trailing empty space
///
/// @endverbatim
Function PSQ_SealEvaluation(string device, STRUCT AnalysisFunction_V3 &s)
	variable multiplier, chunk, baselineQCPassed, ret, DAC, samplingFrequencyQCPassed, sealResistanceMax
	variable sweepsInSet, passesInSet, acquiredSweepsInSet, sweepPassed, setPassed, numSweepsFailedAllowed, failsInSet, asyncAlarmPassed
	variable expectedNumTestpulses, numTestPulses, sealResistanceA, sealResistanceB, sealResistanceQCPassed, testpulseGroupSel, sealThreshold
	string key, ctrl, stimset, msg, databrowser, formula, pipetteResistanceStr, sweepStr
	string sealResistanceGroupAStr, sealResistanceGroupBStr, str

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			if(DAG_GetHeadstageMode(device, s.headstage) != V_CLAMP_MODE)
				printf "(%s) Clamp mode must be voltage clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_SEAL_EVALUATION, s.headstage, s.sweepNo)

			multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)
			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			testpulseGroupSel = PSQ_SE_GetTestpulseGroupSelection(s.params)

			WAVE testpulseGroupSelLBN = LBN_GetNumericWave()
			testpulseGroupSelLBN[INDEP_HEADSTAGE] = testpulseGroupSel

			key = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SE_TESTPULSE_GROUP)
			ED_AddEntryToLabnotebook(device, key, testpulseGroupSelLBN, overrideSweepNo = s.sweepNo)

			break
		case PRE_SWEEP_CONFIG_EVENT:
			ret = PSQ_SE_CreateEpochs(device, s.headstage, s.params)
			if(ret)
				return 1
			endif

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			ret = PSQ_CheckThatAlarmIsEnabled(device, asyncChannels)
			if(ret)
				return 1
			endif

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			testpulseGroupSel = PSQ_SE_GetTestpulseGroupSelection(s.params)

			// inserted TP: 0
			// group A: 1, 2, 3
			// group B: 4, 5, 6
			// and `tp` takes the *ignored* list
			switch(testpulseGroupSel)
				case PSQ_SE_TGS_BOTH:
					formula = ""
					sprintf str, "store(\"Steady state resistance (group A)\", tp(tpss(), select(selchannels(AD), selsweeps(%d), selvis(all)), [0, 4, 5, 6]))\r", s.sweepNo
					formula += str
					formula += "and\r"
					sprintf str, "store(\"Steady state resistance (group B)\", tp(tpss(), select(selchannels(AD), selsweeps(%d), selvis(all)), [0, 1, 2, 3]))", s.sweepNo
					formula += str
					break
				case PSQ_SE_TGS_FIRST:
					sprintf formula, "store(\"Steady state resistance (group A)\", tp(tpss(), select(selchannels(AD), selsweeps(%d), selvis(all)), [0]))", s.sweepNo
					break
				case PSQ_SE_TGS_SECOND:
					sprintf formula, "store(\"Steady state resistance (group B)\", tp(tpss(), select(selchannels(AD), selsweeps(%d), selvis(all)), [0]))", s.sweepNo
					break
				default:
					ASSERT(0, "Invalid testpulseGroupSel: " + num2str(testpulseGroupSel))
			endswitch

			databrowser = PSQ_ExecuteSweepFormula(device, formula)

			[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_SEAL_EVALUATION, s)

			key = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_CHUNK_PASS, query = 1, chunk = 0)
			WAVE/Z baselineQCPassedChunk0LBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

			key = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_CHUNK_PASS, query = 1, chunk = 1)
			WAVE/Z baselineQCPassedChunk1LBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

			testpulseGroupSel = PSQ_SE_GetTestpulseGroupSelection(s.params)

			// custom version of PSQ_EvaluateBaselinePassed
			switch(testpulseGroupSel)
				case PSQ_SE_TGS_FIRST:
					ASSERT(WaveExists(baselineQCPassedChunk0LBN), "Missing baseline QC Chunk 0")
					baselineQCPassed = baselineQCPassedChunk0LBN[INDEP_HEADSTAGE]
					break
				case PSQ_SE_TGS_SECOND:
					// chunk indizes start 0 even if we only look at the second testpulse group
					ASSERT(WaveExists(baselineQCPassedChunk0LBN), "Missing baseline QC Chunk 0")
					baselineQCPassed = baselineQCPassedChunk0LBN[INDEP_HEADSTAGE]
					break
				case PSQ_SE_TGS_BOTH:
					ASSERT(WaveExists(baselineQCPassedChunk0LBN), "Missing baseline QC Chunk 0")
					ASSERT(WaveExists(baselineQCPassedChunk1LBN), "Missing baseline QC Chunk 1")
					baselineQCPassed = baselineQCPassedChunk0LBN[INDEP_HEADSTAGE] && baselineQCPassedChunk1LBN[INDEP_HEADSTAGE]
					break
				default:
					ASSERT(0, "Invalid testpulseGroupSel")
			endswitch

			ASSERT(IsFinite(baselineQCPassed), "Invalid baselineQCpassed")

			// document BL QC results
			WAVE baselineQCPassedLBN = LBN_GetNumericWave()
			baselineQCPassedLBN[s.headstage] = baselineQCPassed

			key = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_BL_QC_PASS)
			ED_AddEntryToLabnotebook(device, key, baselineQCPassedLBN, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			sprintf msg, "BL QC %s, last evaluated chunk %d returned with %g\r", ToPassFail(baselineQCPassed), chunk, ret
			DEBUGPRINT(msg)

			WAVE/T textualResultsValues = BSP_GetLogbookWave(databrowser, LBT_RESULTS, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)

			sealResistanceA = PSQ_GetSweepFormulaResult(textualResultsValues, "Sweep Formula store [Steady state resistance (group A)]")
			sealResistanceB = PSQ_GetSweepFormulaResult(textualResultsValues, "Sweep Formula store [Steady state resistance (group B)]")

			// BEGIN TEST
			if(TestOverrideActive())
				WAVE overrideResults = GetOverrideResults()
				NVAR count           = $GetCount(device)

				sealResistanceA = NaN
				sealResistanceB = NaN

				switch(testpulseGroupSel)
					case PSQ_SE_TGS_FIRST:
						sealResistanceA = overrideResults[0][count][1]
						break
					case PSQ_SE_TGS_SECOND:
						sealResistanceB = overrideResults[0][count][2]
						break
					case PSQ_SE_TGS_BOTH:
						sealResistanceA = overrideResults[0][count][1]
						sealResistanceB = overrideResults[0][count][2]
						break
					default:
						ASSERT(0, "Invalid testpulseGroupSel")
				endswitch
			endif
			// END TEST

			WAVE sealResistanceALBN = LBN_GetNumericWave()
			sealResistanceALBN[INDEP_HEADSTAGE] = sealResistanceA * MEGA_TO_ONE
			key                                 = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SE_RESISTANCE_A)
			ED_AddEntryToLabnotebook(device, key, sealResistanceALBN, unit = "Ω", overrideSweepNo = s.sweepNo)

			WAVE sealResistanceBLBN = LBN_GetNumericWave()
			sealResistanceBLBN[INDEP_HEADSTAGE] = sealResistanceB * MEGA_TO_ONE
			key                                 = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SE_RESISTANCE_B)
			ED_AddEntryToLabnotebook(device, key, sealResistanceBLBN, unit = "Ω", overrideSweepNo = s.sweepNo)

			switch(testpulseGroupSel)
				case PSQ_SE_TGS_FIRST:
					sealResistanceMax = sealResistanceA
					break
				case PSQ_SE_TGS_SECOND:
					sealResistanceMax = sealResistanceB
					break
				case PSQ_SE_TGS_BOTH:
					sealResistanceMax = max(sealResistanceA, sealResistanceB)
					break
				default:
					ASSERT(0, "Invalid testpulseGroupSel")
			endswitch

			WAVE sealResistanceMaxLBN = LBN_GetNumericWave()
			sealResistanceMaxLBN[INDEP_HEADSTAGE] = sealResistanceMax * MEGA_TO_ONE
			key                                   = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SE_RESISTANCE_MAX)
			ED_AddEntryToLabnotebook(device, key, sealResistanceMaxLBN, unit = "Ω", overrideSweepNo = s.sweepNo)

			// GΩ-> MΩ
			sealThreshold = AFH_GetAnalysisParamNumerical("SealThreshold", s.params) * GIGA_TO_MEGA

			switch(testpulseGroupSel)
				case PSQ_SE_TGS_FIRST:
					sealResistanceQCPassed = sealResistanceA >= sealThreshold
					break
				case PSQ_SE_TGS_SECOND:
					sealResistanceQCPassed = sealResistanceB >= sealThreshold
					break
				case PSQ_SE_TGS_BOTH:
					sealResistanceQCPassed = (sealResistanceA >= sealThreshold) || (sealResistanceB >= sealThreshold)
					break
				default:
					ASSERT(0, "Invalid testpulseGroupSel")
			endswitch

			WAVE sealResistanceQCLBN = LBN_GetNumericWave()
			sealResistanceQCLBN[INDEP_HEADSTAGE] = sealResistanceQCPassed

			key = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SE_RESISTANCE_PASS)
			ED_AddEntryToLabnotebook(device, key, sealResistanceQCLBN, unit = LABNOTEBOOK_BINARY_UNIT)

			samplingFrequencyQCPassed = PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(device, PSQ_SEAL_EVALUATION, s)

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			asyncAlarmPassed = PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(device, PSQ_SEAL_EVALUATION, s.sweepNo, asyncChannels)

			sweepPassed = baselineQCPassed && samplingFrequencyQCPassed && sealResistanceQCPassed && asyncAlarmPassed

			WAVE sweepPassedLBN = LBN_GetNumericWave()
			sweepPassedLBN[INDEP_HEADSTAGE] = sweepPassed
			key                             = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, sweepPassedLBN, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			numSweepsFailedAllowed = AFH_GetAnalysisParamNumerical("NumberOfFailedSweeps", s.params)
			ret                    = PSQ_DetermineSweepQCResults(device, PSQ_SEAL_EVALUATION, s.sweepNo, s.headstage, PSQ_SE_NUM_SWEEPS_PASS, numSweepsFailedAllowed)

			if(ret == PSQ_RESULTS_DONE)
				break
			endif

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_SEAL_EVALUATION, s.sweepNo, s.headstage) >= PSQ_SE_NUM_SWEEPS_PASS

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = setPassed
			key                     = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			PUB_SealEvaluation(device, s.sweepNo, s.headstage)

			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
		case POST_DAQ_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			key       = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SET_PASS, query = 1)
			setPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(IsFinite(setPassed), "Missing setQC labnotebook entry")

			if(setPassed)
				PSQ_SetStimulusSets(device, s.headstage, s.params)
			endif

			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch
End

/// @brief Create user epochs
///
/// Assumes that all sweeps in the stimset are the same.
///
/// @return 0 on success, 1 on failure
static Function PSQ_SE_CreateEpochs(string device, variable headstage, string params)
	variable DAC, userEpochIndexBLC, userEpochTPIndexBLC, chunkLength, testpulseGroupSel
	variable amplitude, numEpochs, i, epBegin, epEnd, totalOnsetDelay, duration, DAScale, wbBegin, wbEnd
	string setName, shortName, tags

	setName = AFH_GetStimSetNameForHeadstage(device, headstage)

	numEpochs = ST_GetStimsetParameterAsVariable(setName, "Total number of epochs")

	if(numEpochs != PSQ_SE_REQUIRED_EPOCHS)
		printf "The number of present (%g) and expected (%g) stimulus set epochs differs.", numEpochs, PSQ_SE_REQUIRED_EPOCHS
		ControlWindowToFront()
		return 1
	endif

	testpulseGroupSel = PSQ_SE_GetTestpulseGroupSelection(params)

	DAC     = AFH_GetDACFromHeadstage(device, headstage)
	DAScale = DAG_GetNumericalValue(device, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE), index = DAC)

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)

	chunkLength = AFH_GetAnalysisParamNumerical("BaselineChunkLength", params, defValue = PSQ_BL_EVAL_RANGE) * MILLI_TO_ONE

	WAVE/T epochWave = GetEpochsWave(device)
	return PSQ_SE_CreateEpochsImpl(epochWave, DAC, totalOnsetDelay, setName, testpulseGroupSel, DAScale, numEpochs, chunkLength)
End

Function PSQ_SE_CreateEpochsImpl(WAVE/T epochWave, variable DAC, variable totalOnsetDelayMS, string setName, variable testpulseGroupSel, variable DAScale, variable numEpochs, variable chunkLength)

	variable i, wbBegin, wbEnd, epBegin, epEnd, duration, amplitude
	variable userEpochIndexBLC, userEpochTPIndexBLC
	string tags, shortName

	wbBegin = 0
	wbEnd   = totalOnsetDelayMS * MILLI_TO_ONE
	for(i = 0; i < numEpochs; i += 1)
		duration = ST_GetStimsetParameterAsVariable(setName, "Duration", epochIndex = i) * MILLI_TO_ONE

		wbBegin = wbEnd
		wbEnd   = wbBegin + duration

		if(!(testpulseGroupSel & PSQ_SE_TGS_FIRST) && i >= 0 && i < 10)
			// group A was not selected
			continue
		elseif(!(testpulseGroupSel & PSQ_SE_TGS_SECOND) && i > 10 && i < 21)
			// group B was not selected
			continue
		endif

		if(i == 0 || i == 11) // BLC_Sx
			amplitude = ST_GetStimsetParameterAsVariable(setName, "Amplitude", epochIndex = i)
			ASSERT(amplitude == 0, "Invalid amplitude")

			if(duration < chunkLength)
				printf "The length of epoch %d is %g s but that is smaller than the required %g s by \"BaselineChunkLength\".\r", i, duration, chunkLength
				ControlWindowToFront()
				return 1
			endif

			// BLS epochs are only chunkLength long
			epBegin = wbBegin
			epEnd   = epBegin + chunkLength

			[tags, shortName] = PSQ_CreateBaselineChunkSelectionStrings(userEpochIndexBLC)
			EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)
			userEpochIndexBLC += 1
		elseif(i == 1 || i == 4 || i == 7 || i == 12 || i == 15 || i == 18)
			epBegin = wbBegin
			epEnd   = wbEnd

			// TPs start with TPx_B0
			PSQ_CreateTestpulseLikeEpoch(epochWave, DAC, setName, DAScale, epBegin, i, userEpochTPIndexBLC++)
		endif
	endfor

	return 0
End

Function PSQ_SE_GetTestpulseGroupSelection(string params)
	string str = AFH_GetAnalysisParamTextual("TestPulseGroupSelector", params, defValue = "Both")

	return PSQ_SE_ParseTestpulseGroupSelection(str)
End

static Function PSQ_SE_ParseTestpulseGroupSelection(string str)

	strswitch(str)
		case "Both":
			return PSQ_SE_TGS_BOTH
		case "First":
			return PSQ_SE_TGS_FIRST
		case "Second":
			return PSQ_SE_TGS_SECOND
		default:
			ASSERT(0, "Invalid value: " + str)
	endswitch
End

Function/S PSQ_TrueRestingMembranePotential_CheckParam(string name, STRUCT CheckParametersStruct &s)
	variable val
	string   str

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineChunkLength":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "FailedLevel":
		case "NextIndexingEndStimSetName":
		case "NextStimSetName":
		case "NumberOfFailedSweeps":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_CheckParamCommon(name, s)
		case "AbsoluteVoltageDiff":
		case "RelativeVoltageDiff":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0)) // +inf is allowed as well
				return "Invalid value " + num2str(val)
			endif
			break
		case "InterTrialInterval":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0 && val <= 60))
				return "Invalid value " + num2str(val)
			endif
			break
		case "SpikeFailureIgnoredTime":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 3 && val <= 20))
				return "Invalid value " + num2str(val)
			endif
			break
		case "UserOffsetTargetVAutobias":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val <= -1 && val >= -20))
				return "Invalid value " + num2str(val)
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_TrueRestingMembranePotential_GetHelp(string name)

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineChunkLength":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "FailedLevel":
		case "NextIndexingEndStimSetName":
		case "NextStimSetName":
		case "NumberOfFailedSweeps":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_GetHelpCommon(PSQ_TRUE_REST_VM, name)
		case "AbsoluteVoltageDiff":
			return "Maximum absolute allowed difference of the baseline membrane potentials [mV].\r Set to `inf` to disable this check."
		case "RelativeVoltageDiff":
			return "Maximum relative allowed difference of the baseline membrane potentials [%].\r Set to `inf` to disable this check."
		case "UserOffsetTargetVAutobias":
			return "Offset value for the autobias target voltage in case spikes were found"
		case "SpikeFailureIgnoredTime":
			return "Time [ms] to ignore around spikes for average calculation.\r Half of this value before and after each spike."
		case "InterTrialInterval":
			return "Inter trial interval to set, defaults to 10 [s]"
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
	endswitch
End

Function/S PSQ_TrueRestingMembranePotential_GetParams()
	return "AsyncQCChannels:wave,"                 + \
	       "AbsoluteVoltageDiff:variable,"         + \
	       "[BaselineChunkLength:variable],"       + \
	       "[BaselineRMSLongThreshold:variable],"  + \
	       "[BaselineRMSShortThreshold:variable]," + \
	       "FailedLevel:variable,"                 + \
	       "[InterTrialInterval:variable],"        + \
	       "[NextIndexingEndStimSetName:string],"  + \
	       "[NextStimSetName:string],"             + \
	       "NumberOfFailedSweeps:variable,"        + \
	       "RelativeVoltageDiff:variable,"         + \
	       "[SamplingFrequency:variable],"         + \
	       "SamplingMultiplier:variable,"          + \
	       "SpikeFailureIgnoredTime:variable,"     + \
	       "UserOffsetTargetVAutobias:variable"
End

/// @brief Analysis function for determining the mean potential of a stimset
///
/// Prerequisites:
/// - Does only work for one headstage
/// - See below for the stimset layout
///
/// Testing:
/// For testing the range detection logic, the results can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-true-resting.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of the stimset
///
/// --------------------------------------------
///
/// Epoch borders
/// -------------
///
/// |         0          | 1 |        2        |
///
/// We always expect PSQ_VM_REQUIRED_EPOCHS (3) epochs.
///
/// 0: baselineQC chunk with length `BaselineChunkLength` or larger
/// 1: empty space, can be zero points long, but is always present
/// 2: baselineQC chunk with length `BaselineChunkLength` or larger
///
/// @endverbatim
Function PSQ_TrueRestingMembranePotential(string device, STRUCT AnalysisFunction_V3 &s)
	variable multiplier, ret, preActiveHS, chunk, baselineQCPassed, spikeQCPassed, IsFinished, targetV, iti
	variable averageVoltageQCPassed, samplingFrequencyQCPassed, setPassed, sweepPassed, DAC, level, totalOnsetDelay, ignoredTime
	variable numSweepsFailedAllowed, averageVoltage, numSpikes, position, midsweepReturnValue, asyncAlarmPassed
	string key, msg, stimset, nextIndexingEndStimSetName, ctrl

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			if(DAG_GetHeadstageMode(device, s.headstage) != I_CLAMP_MODE)
				printf "(%s) Clamp mode must be current clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_TRUE_REST_VM, s.headstage, s.sweepNo)

			multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)
			PSQ_SetSamplingIntervalMultiplier(device, multiplier)

			preActiveHS = GetSliderPositionIndex(device, "slider_DataAcq_ActiveHeadstage")

			if(preActiveHS != s.headstage)
				PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = s.headstage)
			endif

			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 0)
			PGC_SetAndActivateControl(device, "check_DatAcq_HoldEnable", val = 0)
			PGC_SetAndActivateControl(device, "check_DatAcq_CNEnable", val = 1)
			PGC_SetAndActivateControl(device, "check_DatAcq_BBEnable", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 1)

			if(preActiveHS != s.headstage)
				PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = preActiveHS)
			endif

			break
		case PRE_SWEEP_CONFIG_EVENT:
			ret = PSQ_CreateBaselineChunkSelectionEpochs(device, s.headstage, s.params, {0, 2}, numRequiredEpochs = PSQ_VM_REQUIRED_EPOCHS)
			if(ret)
				return 1
			endif

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			ret = PSQ_CheckThatAlarmIsEnabled(device, asyncChannels)
			if(ret)
				return 1
			endif

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			key = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(WaveExists(baselineQCPassedLBN), "baselineQCPassedLBN does not exist")

			baselineQCPassed = baselineQCPassedLBN[s.headstage]

			level = AFH_GetAnalysisParamNumerical("FailedLevel", s.params)

			[spikeQCPassed, WAVE spikePositions] = PSQ_VM_CheckForSpikes(device, s.sweepNo, s.headstage, s.scaledDACWave, level)

			averageVoltageQCPassed = PSQ_VM_EvaluateAverageVoltage(device, s.sweepNo, s.headstage, s.params, baselineQCPassed)

			samplingFrequencyQCPassed = PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(device, PSQ_TRUE_REST_VM, s)

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			asyncAlarmPassed = PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(device, PSQ_TRUE_REST_VM, s.sweepNo, asyncChannels)

			sweepPassed = baselineQCPassed && samplingFrequencyQCPassed && spikeQCPassed && averageVoltageQCPassed && asyncAlarmPassed

			WAVE sweepPassedLBN = LBN_GetNumericWave()
			sweepPassedLBN[INDEP_HEADSTAGE] = sweepPassed
			key                             = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, sweepPassedLBN, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			if(spikeQCPassed)
				PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 1)
			else
				PSQ_VM_HandleFailingSpikeQC(device, s, spikePositions)
			endif

			numSweepsFailedAllowed = AFH_GetAnalysisParamNumerical("NumberOfFailedSweeps", s.params)
			ret                    = PSQ_DetermineSweepQCResults(device, PSQ_TRUE_REST_VM, s.sweepNo, s.headstage, PSQ_VM_NUM_SWEEPS_PASS, numSweepsFailedAllowed)

			if(ret == PSQ_RESULTS_DONE)
				break
			endif

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_TRUE_REST_VM, s.sweepNo, s.headstage) >= PSQ_VM_NUM_SWEEPS_PASS

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = setPassed
			key                     = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			PUB_TrueRestingMembranePotential(device, s.sweepNo, s.headstage)

			if(setPassed)
				key            = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_VM_FULL_AVG, query = 1)
				averageVoltage = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE) * ONE_TO_MILLI

				PSQ_SetAutobiasTargetV(device, s.headstage, averageVoltage)
			endif

			PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = 1)

			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
		case POST_DAQ_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			key       = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_SET_PASS, query = 1)
			setPassed = GetLastSettingIndepSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(setPassed)
				PSQ_SetStimulusSets(device, s.headstage, s.params)
			endif

			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

	if(baselineQCPassed) // already done
		return NaN
	endif

	[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_TRUE_REST_VM, s)

	PSQ_EvaluateBaselinePassed(device, PSQ_TRUE_REST_VM, s.sweepNo, s.headstage, chunk, ret)

	return NaN
End

static Function [string tags, string shortName] PSQ_CreateBaselineChunkSelectionStrings(variable index)
	sprintf tags, "Type=Baseline Chunk QC Selection;Index=%d", index
	sprintf shortName, "BLS%d", index
End

/// @brief Create baseline selection epochs
///
/// Assumes that all sweeps in the stimset are the same.
///
/// @param device            device
/// @param headstage         headstage
/// @param params            analysis function parameters
/// @param epochIndizes      indizes of stimset epochs for which we should create BLS epochs
/// @param numRequiredEpochs number of required epochs in the stimset, use
///
/// @return 0 on success, 1 on failure
static Function PSQ_CreateBaselineChunkSelectionEpochs(string device, variable headstage, string params, WAVE epochIndizes, [variable numRequiredEpochs])
	variable DAC, index, chunkLength
	variable amplitude, numEpochs, i, epBegin, epEnd, totalOnsetDelay, duration, wbBegin, wbEnd
	string setName, shortName, tags

	DAC     = AFH_GetDACFromHeadstage(device, headstage)
	setName = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)

	numEpochs = ST_GetStimsetParameterAsVariable(setName, "Total number of epochs")
	ASSERT(numEpochs > 0, "Invalid number of epochs")

	if(!ParamIsDefault(numRequiredEpochs))
		ASSERT(IsFinite(numRequiredEpochs), "numRequiredEpochs must be finite")

		if(numEpochs != numRequiredEpochs)
			printf "The number of present (%g) and expected (%g) stimulus set epochs differs.", numEpochs, numRequiredEpochs
			ControlWindowToFront()
			return 1
		endif
	endif

	if(WaveMax(epochIndizes) >= numEpochs)
		printf "epochIndizes (%s) has entries which are larger than the number of present epochs (%g)\r", NumericWaveToList(epochIndizes, ";"), numEpochs
		ControlWindowToFront()
		return 1
	endif

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)
	WAVE/T epochWave = GetEpochsWave(device)

	chunkLength = AFH_GetAnalysisParamNumerical("BaselineChunkLength", params, defValue = PSQ_BL_EVAL_RANGE) * MILLI_TO_ONE
	ASSERT(IsFinite(chunkLength), "BaselineChunkLength must be finite")

	return PSQ_CreateBaselineChunkSelectionEpochs_AddEpochs(epochWave, DAC, totalOnsetDelay, setName, epochIndizes, numEpochs, chunkLength)
End

Function PSQ_CreateBaselineChunkSelectionEpochs_AddEpochs(WAVE/T epochWave, variable DAC, variable totalOnsetDelayMS, string setName, WAVE epochIndizes, variable numEpochs, variable chunkLength)

	variable i, wbBegin, wbEnd, duration, amplitude, epBegin, epEnd, index
	string tags, shortName

	wbBegin = 0
	wbEnd   = totalOnsetDelayMS * MILLI_TO_ONE
	for(i = 0; i < numEpochs; i += 1)
		duration = ST_GetStimsetParameterAsVariable(setName, "Duration", epochIndex = i) * MILLI_TO_ONE

		wbBegin = wbEnd
		wbEnd   = wbBegin + duration

		if(IsNaN(GetRowIndex(epochIndizes, val = i)))
			continue
		endif

		amplitude = ST_GetStimsetParameterAsVariable(setName, "Amplitude", epochIndex = i)
		ASSERT(amplitude == 0, "Invalid amplitude")

		if(duration < chunkLength)
			printf "The length of epoch %d is %g s but that is smaller than the required %g s by \"BaselineChunkLength\".\r", i, duration, chunkLength
			ControlWindowToFront()
			return 1
		endif

		// BLS epochs are only chunkLength long
		epBegin = wbBegin
		epEnd   = epBegin + chunkLength

		[tags, shortName] = PSQ_CreateBaselineChunkSelectionStrings(index)
		EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, epBegin, epEnd, tags, shortName = shortName)
		index += 1
	endfor

	return 0
End

/// @brief Check if we need to act on the now available sweep QC state
///
/// @param device                 device
/// @param type                   analysis function type
/// @param sweepNo                sweep number
/// @param headstage              headstage
/// @param requiredPassesInSet    number of passes in set which makes the set pass
/// @param numSweepsFailedAllowed number of failures in set which makes the set fail
///
/// @return One of @ref DetermineSweepQCReturns
static Function PSQ_DetermineSweepQCResults(string device, variable type, variable sweepNo, variable headstage, variable requiredPassesInSet, variable numSweepsFailedAllowed)
	variable DAC, sweepsInSet, passesInSet, acquiredSweepsInSet, sweepPassed, samplingFrequencyPassed, failsInSet
	string stimset, key, msg

	DAC     = AFH_GetDACFromHeadstage(device, headstage)
	stimset = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)

	WAVE numericalValues = GetLBNumericalValues(device)

	key         = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

	sweepsInSet         = IDX_NumberOfSweepsInSet(stimset)
	passesInSet         = PSQ_NumPassesInSet(numericalValues, type, sweepNo, headstage)
	acquiredSweepsInSet = PSQ_NumAcquiredSweepsInSet(device, sweepNo, headstage)
	failsInSet          = acquiredSweepsInSet - passesInSet

	sprintf msg, "Sweep %s, total sweeps %d, acquired sweeps %d, passed sweeps %d, required passes %d, accepted failures %d\r", ToPassFail(sweepPassed), sweepsInSet, acquiredSweepsInSet, passesInSet, requiredPassesInSet, numSweepsFailedAllowed
	DEBUGPRINT(msg)

	if(!sweepPassed)
		// not enough sweeps left to pass the set
		if((sweepsInSet - acquiredSweepsInSet) < (requiredPassesInSet - passesInSet))
			PSQ_ForceSetEvent(device, headstage)
			RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)
			return PSQ_RESULTS_DONE
		elseif(failsInSet >= numSweepsFailedAllowed)
			// failed too many sweeps
			PSQ_ForceSetEvent(device, headstage)
			RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)
			return PSQ_RESULTS_DONE
		endif

		key                     = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_SAMPLING_PASS, query = 1)
		samplingFrequencyPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
		ASSERT(IsFinite(samplingFrequencyPassed), "Sampling frequency QC is missing")

		if(!samplingFrequencyPassed)
			PSQ_ForceSetEvent(device, headstage)
			RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)
			return PSQ_RESULTS_DONE
		endif
	else
		if(passesInSet >= requiredPassesInSet)
			PSQ_ForceSetEvent(device, headstage)
			RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
			return PSQ_RESULTS_DONE
		endif
	endif

	return PSQ_RESULTS_CONT
End

static Function PSQ_VM_EvaluateAverageVoltage(string device, variable sweepNo, variable headstage, string params, variable baselineQCPassed)
	variable absoluteDiff, absoluteDiffAllowed, relativeDiff, relativeDiffAllowed, voltage
	variable averageQCPassed, averageAbsoluteQCPassed, averageRelativeQCPassed, avgChunk0, avgChunk1
	string key, databrowser, formula, str

	if(baselineQCPassed)
		formula = ""
		sprintf str, "store(\"Average U_BLS0\", avg(data(select(selrange(U_BLS0),selchannels(AD), selsweeps(%d), selvis(all)))))\r", sweepNo
		formula += str
		formula += "and\r"
		sprintf str, "store(\"Average U_BLS1\", avg(data(select(selrange(U_BLS1),selchannels(AD), selsweeps(%d), selvis(all)))))\r", sweepNo
		formula += str

		databrowser = PSQ_ExecuteSweepFormula(device, formula)

		WAVE/T textualResultsValues = BSP_GetLogbookWave(databrowser, LBT_RESULTS, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)

		avgChunk0 = PSQ_GetSweepFormulaResult(textualResultsValues, "Sweep Formula store [Average U_BLS0]")
		avgChunk1 = PSQ_GetSweepFormulaResult(textualResultsValues, "Sweep Formula store [Average U_BLS1]")

		if(TestOverrideActive())
			WAVE overrideResults = GetOverrideResults()
			NVAR count           = $GetCount(device)

			avgChunk0 = overrideResults[0][count][2]
			avgChunk1 = overrideResults[1][count][2]
		endif
	else
		avgChunk0 = NaN
		avgChunk1 = NaN
	endif

	WAVE voltageChunk0LBN = LBN_GetNumericWave()
	voltageChunk0LBN[headstage] = avgChunk0 * MILLI_TO_ONE
	key                         = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_AVERAGEV, chunk = 0)
	ED_AddEntryToLabnotebook(device, key, voltageChunk0LBN, unit = "V", overrideSweepNo = sweepNo)

	WAVE voltageChunk1LBN = LBN_GetNumericWave()
	voltageChunk1LBN[headstage] = avgChunk1 * MILLI_TO_ONE
	key                         = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_AVERAGEV, chunk = 1)
	ED_AddEntryToLabnotebook(device, key, voltageChunk1LBN, unit = "V", overrideSweepNo = sweepNo)

	voltage      = (voltageChunk0LBN[headstage] + voltageChunk1LBN[headstage]) / 2
	absoluteDiff = voltageChunk0LBN[headstage] - voltageChunk1LBN[headstage]
	relativeDiff = (voltageChunk0LBN[headstage] - voltageChunk1LBN[headstage]) / voltageChunk0LBN[headstage]

	absoluteDiffAllowed = AFH_GetAnalysisParamNumerical("AbsoluteVoltageDiff", params) * MILLI_TO_ONE
	relativeDiffAllowed = AFH_GetAnalysisParamNumerical("RelativeVoltageDiff", params) * PERCENT_TO_ONE

	averageAbsoluteQCPassed = abs(absoluteDiff) <= absoluteDiffAllowed
	averageRelativeQCPassed = abs(relativeDiff) <= relativeDiffAllowed

	averageQCPassed = averageAbsoluteQCPassed && averageRelativeQCPassed

	WAVE averageLBN = LBN_GetNumericWave()
	averageLBN[INDEP_HEADSTAGE] = voltage
	key                         = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_VM_FULL_AVG)
	ED_AddEntryToLabnotebook(device, key, averageLBN, unit = "Volt", overrideSweepNo = sweepNo)

	WAVE absoluteDiffLBN = LBN_GetNumericWave()
	absoluteDiffLBN[INDEP_HEADSTAGE] = absoluteDiff
	key                              = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_VM_FULL_AVG_ADIFF)
	ED_AddEntryToLabnotebook(device, key, absoluteDiffLBN, unit = "Volt", overrideSweepNo = sweepNo)

	WAVE averageAbsoluteQCPassedLBN = LBN_GetNumericWave()
	averageAbsoluteQCPassedLBN[INDEP_HEADSTAGE] = averageAbsoluteQCPassed
	key                                         = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_VM_FULL_AVG_ADIFF_PASS)
	ED_AddEntryToLabnotebook(device, key, averageAbsoluteQCPassedLBN, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	WAVE relativeDiffLBN = LBN_GetNumericWave()
	relativeDiffLBN[INDEP_HEADSTAGE] = relativeDiff
	key                              = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_VM_FULL_AVG_RDIFF)
	ED_AddEntryToLabnotebook(device, key, relativeDiffLBN, overrideSweepNo = sweepNo)

	WAVE averageRelativeQCPassedLBN = LBN_GetNumericWave()
	averageRelativeQCPassedLBN[INDEP_HEADSTAGE] = averageRelativeQCPassed
	key                                         = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_VM_FULL_AVG_RDIFF_PASS)
	ED_AddEntryToLabnotebook(device, key, averageRelativeQCPassedLBN, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	WAVE averageQCPassedLBN = LBN_GetNumericWave()
	averageQCPassedLBN[INDEP_HEADSTAGE] = averageQCPassed
	key                                 = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_VM_FULL_AVG_PASS)
	ED_AddEntryToLabnotebook(device, key, averageQCPassedLBN, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	return averageQCPassed
End

static Function [variable spikeQCPassed, WAVE spikePositions] PSQ_VM_CheckForSpikes(string device, variable sweepNo, variable headstage, WAVE scaledDACWave, variable level)
	variable totalOnsetDelay, numberOfSpikesFound
	string key

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)

	Make/FREE/N=0 spikePositions
	WAVE spikeDetection = PSQ_SearchForSpikes(device, PSQ_TRUE_REST_VM, scaledDACWave, headstage, totalOnsetDelay,       \
	                                          level, numberOfSpikesFound = numberOfSpikesFound, numberOfSpikesReq = Inf, \
	                                          spikePositions = spikePositions)
	WaveClear spikeDetection

	spikeQCPassed = (numberOfSpikesFound == 0)

	WAVE spikeQCPassedLBN = LBN_GetNumericWave()
	spikeQCPassedLBN[headstage] = spikeQCPassed
	key                         = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_SPIKE_PASS)
	ED_AddEntryToLabnotebook(device, key, spikeQCPassedLBN, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	WAVE/T spikePositionsLBN = LBN_GetTextWave()
	spikePositionsLBN[headstage] = NumericWaveToList(spikePositions, ";")
	key                          = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_SPIKE_POSITIONS)
	ED_AddEntryToLabnotebook(device, key, spikePositionsLBN, unit = "ms", overrideSweepNo = sweepNo)

	return [spikeQCPassed, spikePositions]
End

static Function PSQ_VM_HandleFailingSpikeQC(string device, STRUCT AnalysisFunction_V3 &s, WAVE spikePositions)
	variable first, last, totalOnsetDelay, ignoredTime, targetV, position, numRows, iti

	WAVE sweepWave = GetSweepWave(device, s.sweepNo)
	WAVE config    = GetConfigWave(sweepWave)
	WAVE singleAD  = AFH_ExtractOneDimDataFromSweep(device, sweepWave, s.headstage, XOP_CHANNEL_TYPE_ADC, config = config)

	totalOnsetDelay = GetTotalOnsetDelayFromDevice(device)

	ignoredTime = AFH_GetAnalysisParamNumerical("SpikeFailureIgnoredTime", s.params)

	ASSERT(DimSize(spikePositions, ROWS) > 0, "Expected some spike positions")

	// ignore inserted TP and offset
	first                 = 0
	last                  = ScaleToIndex(singleAD, totalOnsetDelay, ROWS)
	singleAD[first, last] = 0

	numRows = DimSize(singleAD, ROWS)

	for(position : spikePositions)
		first                 = limit(ScaleToIndex(spikePositions, position - ignoredTime / 2.0, ROWS), 0, numRows - 1)
		last                  = limit(ScaleToIndex(spikePositions, position + ignoredTime / 2.0, ROWS), 0, numRows - 1)
		singleAD[first, last] = 0
	endfor

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		NVAR count           = $GetCount(device)

		targetV = (overrideResults[0][count][2] + overrideResults[1][count][2]) / 2
	else
		targetV = Mean(singleAD)
	endif

	targetV += AFH_GetAnalysisParamNumerical("UserOffsetTargetVAutobias", s.params)
	PSQ_SetautobiasTargetV(device, s.headstage, targetV)

	iti = AFH_GetAnalysisParamNumerical("InterTrialInterval", s.params, defValue = 10)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = iti)
	PGC_SetAndActivateControl(device, "Check_DataAcq_Get_Set_ITI", val = CHECKBOX_UNSELECTED)
End

static Function PSQ_CheckThatAlarmIsEnabled(string device, WAVE asyncChannels)
	variable chan, alarmEnabled, enabled
	string ctrl

	for(chan : asyncChannels)

		ctrl    = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK)
		enabled = DAG_GetNumericalValue(device, ctrl, index = chan)

		if(!enabled)
			printf "The async channel %d is not enabled.\r", chan
			ControlWindowToFront()
			return 1
		endif

		ctrl         = GetSpecialControlLabel(CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
		alarmEnabled = DAG_GetNumericalValue(device, ctrl, index = chan)

		if(!alarmEnabled)
			printf "The async channel %d does not have the alarm enabled.\r", chan
			ControlWindowToFront()
			return 1
		endif
	endfor
End

static Function PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(string device, variable type, variable sweepNo, WAVE asyncChannels)
	variable chan, alarmState, alarmPassed
	string key

	WAVE numericalValues = GetLBNumericalValues(device)

	alarmPassed = 1
	for(chan : asyncChannels)
		sprintf key, "Async Alarm %d State", chan
		alarmState = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)
		ASSERT(IsFinite(alarmState), "Invalid alarm state")

		alarmPassed = alarmPassed && !alarmState
	endfor

	WAVE result = LBN_GetNumericWave()
	key                     = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_ASYNC_PASS)
	result[INDEP_HEADSTAGE] = alarmPassed
	ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	return alarmPassed
End

Function/S PSQ_AccessResistanceSmoke_CheckParam(string name, STRUCT CheckParametersStruct &s)
	variable val

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineChunkLength":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "MaxLeakCurrent":
		case "NextStimSetName":
		case "NextIndexingEndStimSetName":
		case "NumberOfFailedSweeps":
		case "NumberOfTestpulses":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_CheckParamCommon(name, s)
		case "MaxAccessResistance":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val > 0))
				return "Invalid value " + num2str(val)
			endif
			break
		case "MaxAccessToSteadyStateResistanceRatio":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0) && (val <= 100))
				return "Invalid value " + num2str(val)
			endif
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

Function/S PSQ_AccessResistanceSmoke_GetHelp(string name)

	strswitch(name)
		case "AsyncQCChannels":
		case "BaselineChunkLength":
		case "BaselineRMSLongThreshold":
		case "BaselineRMSShortThreshold":
		case "MaxLeakCurrent":
		case "NextStimSetName":
		case "NextIndexingEndStimSetName":
		case "NumberOfFailedSweeps":
		case "NumberOfTestpulses":
		case "SamplingFrequency":
		case "SamplingMultiplier":
			return PSQ_GetHelpCommon(PSQ_DA_SCALE, name)
		case "MaxAccessResistance":
			return "Maximum allowed acccess resistance [MΩ]"
		case "MaxAccessToSteadyStateResistanceRatio":
			return "Maximum allowed ratio of access to steady state resistance [%]"
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

Function/S PSQ_AccessResistanceSmoke_GetParams()
	return "AsyncQCChannels:wave,"                           + \
	       "[BaselineChunkLength:variable],"                 + \
	       "[BaselineRMSLongThreshold:variable],"            + \
	       "[BaselineRMSShortThreshold:variable],"           + \
	       "MaxAccessResistance:variable,"                   + \
	       "MaxAccessToSteadyStateResistanceRatio:variable," + \
	       "MaxLeakCurrent:variable,"                        + \
	       "[NextStimSetName:string],"                       + \
	       "[NextIndexingEndStimSetName:string],"            + \
	       "NumberOfFailedSweeps:variable,"                  + \
	       "NumberOfTestpulses:variable,"                    + \
	       "[SamplingFrequency:variable],"                   + \
	       "SamplingMultiplier:variable"
End

Function PSQ_AccessResistanceSmoke_GetNumberOfTestpulses(string params)

	return AFH_GetAnalysisParamNumerical("NumberOfTestpulses", params, defValue = 3)
End

/// @brief Analysis function for determining the TP resistances and their ratio
///
/// Prerequisites:
/// - Does only work for one headstage
/// - We expect three epochs per test pulse in the stimset, plus one epoch before all TPs, and at the very end
/// - Assumes that the stimset has `NumberOfTestpulses` test pulses
/// - Pre pulse baseline length is given by `BaselineChunkLength`
/// - Post pulse baseline is not evaluated
///
/// Testing:
/// For testing the range detection logic, the results can be defined in the wave
/// root:overrideResults. @see PSQ_CreateOverrideResults()
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/patch-seq-access-resistance-smoke.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with three test pulse like epochs
///
///                    +-----+       +-----+       +-----+
///                    |     |       |     |       |     |
///                    |     |       |     |       |     |
///                    |     |       |     |       |     |
/// -------------------+     +-------+     +-------+     +------------------------
///
/// Epoch borders
/// -------------
///
///        0       | 1 |  2  | 3 | 4 |  5  | 6 | 7 |  8  | 9 |      10
///
/// So for this stimset we have two epochs at the very beginning and end, plus
/// three epochs per test pulse and three test pulses, which gives eleven in
/// total.
///
/// @endverbatim
Function PSQ_AccessResistanceSmoke(string device, STRUCT AnalysisFunction_V3 &s)
	variable multiplier, numTestpulses, expectedNumTestpulses, ret, accessResistance, steadyStateResistance, chunk, baselineQCPassed, numSweepsFailedAllowed
	variable accessResistanceQC, steadyStateResistanceQC, resistanceRatioQC, sweepPassed, setPassed, baselinePassed, samplingFrequencyPassed, midsweepReturnValue
	variable asyncAlarmPassed
	string cmd, str, key, msg, databrowser

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			if(sum(statusHS) != 1)
				printf "(%s) Analysis function only supports one headstage.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			if(DAG_GetHeadstageMode(device, s.headstage) != V_CLAMP_MODE)
				printf "(%s) Clamp mode must be voltage clamp.\r", device
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = s.headstage)

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, PSQ_ACC_RES_SMOKE, s.headstage, s.sweepNo)

			multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)
			PSQ_SetSamplingIntervalMultiplier(device, multiplier)
			break
		case PRE_SWEEP_CONFIG_EVENT:
			expectedNumTestpulses = PSQ_AccessResistanceSmoke_GetNumberOfTestpulses(s.params)
			ret                   = PSQ_CreateTestpulseEpochs(device, s.headstage, expectedNumTestpulses)
			if(ret)
				return 1
			endif

			ret = PSQ_CreateBaselineChunkSelectionEpochs(device, s.headstage, s.params, {0})
			if(ret)
				return 1
			endif

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			ret = PSQ_CheckThatAlarmIsEnabled(device, asyncChannels)
			if(ret)
				return 1
			endif

			break
		case POST_SWEEP_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			key = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQCLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(WaveExists(baselineQCLBN), "Missing baseline QC")
			baselinePassed = baselineQCLBN[s.headstage]

			if(baselinePassed)
				cmd = ""
				sprintf str, "store(\"Steady state resistance\", tp(tpss(), select(selchannels(AD), selsweeps(%d), selvis(all)), [0]))", s.sweepNo
				cmd += str
				cmd += "\r and \r"
				sprintf str, "store(\"Peak resistance\", tp(tpinst(), select(selchannels(AD), selsweeps(%d), selvis(all)), [0]))", s.sweepNo
				cmd += str

				databrowser = PSQ_ExecuteSweepFormula(device, cmd)

				WAVE/T textualResultsValues = BSP_GetLogbookWave(databrowser, LBT_RESULTS, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)

				accessResistance      = PSQ_GetSweepFormulaResult(textualResultsValues, "Sweep Formula store [Peak resistance]")
				steadyStateResistance = PSQ_GetSweepFormulaResult(textualResultsValues, "Sweep Formula store [Steady state resistance]")

				if(TestOverrideActive())
					WAVE overrideResults = GetOverrideResults()
					NVAR count           = $GetCount(device)

					accessResistance      = overrideResults[0][count][1]
					steadyStateResistance = overrideResults[0][count][2]
				endif
			else
				accessResistance      = NaN
				steadyStateResistance = NaN
			endif

			WAVE accessResistanceLBN = LBN_GetNumericWave()
			accessResistanceLBN[INDEP_HEADSTAGE] = accessResistance * MEGA_TO_ONE
			key                                  = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_AR_ACCESS_RESISTANCE)
			ED_AddEntryToLabnotebook(device, key, accessResistanceLBN, unit = "Ω", overrideSweepNo = s.sweepNo)

			WAVE steadyStateResistanceLBN = LBN_GetNumericWave()
			steadyStateResistanceLBN[INDEP_HEADSTAGE] = steadyStateResistance * MEGA_TO_ONE
			key                                       = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_AR_STEADY_STATE_RESISTANCE)
			ED_AddEntryToLabnotebook(device, key, steadyStateResistanceLBN, unit = "Ω", overrideSweepNo = s.sweepNo)

			WAVE resistanceRatioLBN = LBN_GetNumericWave()
			resistanceRatioLBN[INDEP_HEADSTAGE] = accessResistanceLBN[INDEP_HEADSTAGE] / steadyStateResistanceLBN[INDEP_HEADSTAGE]
			key                                 = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_AR_RESISTANCE_RATIO)
			ED_AddEntryToLabnotebook(device, key, resistanceRatioLBN, overrideSweepNo = s.sweepNo)

			accessResistanceQC = accessResistanceLBN[INDEP_HEADSTAGE] < (AFH_GetAnalysisParamNumerical("MaxAccessResistance", s.params) * MEGA_TO_ONE)

			WAVE accessResistanceQCLBN = LBN_GetNumericWave()
			accessResistanceQCLBN[INDEP_HEADSTAGE] = accessResistanceQC
			key                                    = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_AR_ACCESS_RESISTANCE_PASS)
			ED_AddEntryToLabnotebook(device, key, accessResistanceQCLBN, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			resistanceRatioQC = resistanceRatioLBN[INDEP_HEADSTAGE] < (AFH_GetAnalysisParamNumerical("MaxAccessToSteadyStateResistanceRatio", s.params) * PERCENT_TO_ONE)

			WAVE resistanceRatioQCLBN = LBN_GetNumericWave()
			resistanceRatioQCLBN[INDEP_HEADSTAGE] = resistanceRatioQC
			key                                   = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_AR_RESISTANCE_RATIO_PASS)
			ED_AddEntryToLabnotebook(device, key, resistanceRatioQCLBN, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			samplingFrequencyPassed = PSQ_CheckADSamplingFrequencyAndStoreInLabnotebook(device, PSQ_ACC_RES_SMOKE, s)

			WAVE asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", s.params)
			asyncAlarmPassed = PSQ_CheckAsyncAlarmStateAndStoreInLabnotebook(device, PSQ_ACC_RES_SMOKE, s.sweepNo, asyncChannels)

			sprintf msg, "SamplingFrequency %s, Sweep %s, BL QC %s, Access Resistance QC %s, Resistance Ratio QC %s, Async alarm %s\r", ToPassFail(samplingFrequencyPassed), ToPassFail(sweepPassed), ToPassFail(baselinePassed), ToPassFail(accessResistanceQC), ToPassFail(resistanceRatioQC), ToPassFail(asyncAlarmPassed)
			DEBUGPRINT(msg)
			sweepPassed = baselinePassed && samplingFrequencyPassed && accessResistanceQC && resistanceRatioQC && asyncAlarmPassed

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = sweepPassed
			key                     = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			numSweepsFailedAllowed = AFH_GetAnalysisParamNumerical("NumberOfFailedSweeps", s.params)
			ret                    = PSQ_DetermineSweepQCResults(device, PSQ_ACC_RES_SMOKE, s.sweepNo, s.headstage, PSQ_AR_NUM_SWEEPS_PASS, numSweepsFailedAllowed)

			if(ret == PSQ_RESULTS_DONE)
				return NaN
			endif

			break
		case POST_SET_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)
			setPassed = PSQ_NumPassesInSet(numericalValues, PSQ_ACC_RES_SMOKE, s.sweepNo, s.headstage) >= PSQ_PB_NUM_SWEEPS_PASS

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = setPassed
			key                     = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			PUB_AccessResistanceSmoke(device, s.sweepNo, s.headstage)

			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
		case POST_DAQ_EVENT:
			WAVE numericalValues = GetLBNumericalValues(device)

			key       = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_SET_PASS, query = 1)
			setPassed = GetLastSettingIndep(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
			ASSERT(IsFinite(setPassed), "Missing setQC labnotebook entry")

			if(setPassed)
				PSQ_SetStimulusSets(device, s.headstage, s.params)
			endif

			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			AD_UpdateAllDatabrowser()
			break
	endswitch

	if(s.eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	key = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
	WAVE/Z baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)
	baselineQCPassed = WaveExists(baselineQCPassedLBN) ? baselineQCPassedLBN[s.headstage] : 0

	if(baselineQCPassed) // already done
		return NaN
	endif

	[ret, chunk] = PSQ_EvaluateBaselineChunks(device, PSQ_ACC_RES_SMOKE, s)

	midsweepReturnValue = PSQ_EvaluateBaselinePassed(device, PSQ_ACC_RES_SMOKE, s.sweepNo, s.headstage, chunk, ret)

	WAVE baselineQCPassedLBN = GetLastSetting(numericalValues, s.sweepNo, key, UNKNOWN_MODE)

	if(baselineQCPassedLBN[s.headstage])
		return NaN
	endif

	return midsweepReturnValue
End
