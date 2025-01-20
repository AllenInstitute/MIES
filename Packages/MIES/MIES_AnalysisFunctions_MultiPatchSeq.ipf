#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MSQ
#endif

/// @file MIES_AnalysisFunctions_MultiPatchSeq.ipf
/// @brief __MSQ__ Analysis functions for multi patch sequence
///
/// The Multi Patch Seq analysis functions store various results in the labnotebook.
///
/// For orientation the following table shows their relation. All labnotebook
/// keys can and should be created via CreateAnaFuncLBNKey().
///
/// \rst
///
/// ================================ ==================================================================== ============= ============ ============= ======= =========== =========== ================ ===================
/// Naming constant                  Description                                                          Unit          Labnotebook  Analysis      Per     Headstage   List?       Key-Value pairs? Values are lists?
///                                                                                                                                  function      chunk?  dependent?  (semicolon) (colon)          (comma)
/// ================================ ==================================================================== ============= ============ ============= ======= =========== =========== ================ ===================
/// MSQ_FMT_LBN_SPIKE_DETECT         The required number of spikes were detected on the sweep             ms            Numerical    FRE           No      Yes         No          No                No
/// MSQ_FMT_LBN_STEPSIZE             Current DAScale step size                                            (none)        Numerical    FRE           No      Yes         No          No                No
/// MSQ_FMT_LBN_FINAL_SCALE          Final DAScale of the given headstage, only set on success            (none)        Numerical    FRE           No      Yes         No          No                No
/// MSQ_FMT_LBN_HEADSTAGE_PASS       Pass/fail state of the headstage                                     On/Off        Numerical    FRE, DS, SC   No      Yes         No          No                No
/// MSQ_FMT_LBN_SWEEP_PASS           Pass/fail state of the complete sweep                                On/Off        Numerical    FRE, DS, SC   No      No          No          No                No
/// MSQ_FMT_LBN_SET_PASS             Pass/fail state of the complete set                                  On/Off        Numerical    FRE, DS, SC   No      No          No          No                No
/// MSQ_FMT_LBN_ACTIVE_HS            Active headstages in pre set event                                   On/Off        Numerical    FRE, DS       No      Yes         No          No                No
/// MSQ_FMT_LBN_DASCALE_EXC          Allowed DAScale exceeded given limit                                 (none)        Numerical    FRE           No      Yes         No          No                No
/// MSQ_FMT_LBN_DASCALE_OOR          Future DAScale value is out of range                                 On/Off        Numerical    FRE, DS, SC   No      Yes         No          No
/// MSQ_FMT_LBN_PULSE_DUR            Square pulse duration                                                ms            Numerical    FRE           No      Yes         No          No                No
/// MSQ_FMT_LBN_SPIKE_POSITIONS      Spike positions with ``P{1}_R{2}``, pulse index (``{1}``) and        (none)        Textual      SC            No      Yes         Yes         Yes               Yes
///                                  region (``{2}``), as key and the spike positions as value in pulse
///                                  active coordinate system (0 - 100)
/// MSQ_FMT_LBN_SPIKE_COUNTS         Spike count with ``P{1}_R{2}``, pulse index (``{1}``) and            (none)        Textual      SC            No      Yes         Yes         Yes               No
///                                  region (``{2}``), as key and the spike counts as value
/// MSQ_FMT_LBN_SPIKE_POSITION_PASS  Pass/fail state of the spike positions                               On/Off        Numerical    SC            No      Yes         No          No                No
/// MSQ_FMT_LBN_SPIKE_COUNTS_STATE   Result of the spike count check:                                     (none)        Textual      SC            No      Yes         No          No                No
///                                  ``Too few``/``Too many``/``Pass``/``Mixed``
/// MSQ_FMT_LBN_SPONT_SPIKE_PASS     Pass/fail state of the complete baseline                             On/Off        Numerical    SC            No      Yes         No          No                No
/// MSQ_FMT_LBN_IDEAL_SPIKE_COUNTS   Ideal number of spikes (-1 for not present)                          (none)        Numerical    SC            No      No          No          No                No
/// MSQ_FMT_LBN_FAILED_PULSE_LEVEL   Failed pulse level                                                   (none)        Numerical    SC            No      No          No          No                No
/// MSQ_FMT_LBN_RERUN_TRIAL          Number of repetitions of given stimulus set sweep due to relevant    (none)        Numerical    SC            No      Yes         No          No                No
///                                  QC failures (spike count or baseline)
/// MSQ_FMT_LBN_RERUN_TRIAL_EXC      Number of repetitions was exceeded for that stimulus sweep set count On/Off        Numerical    SC            No      Yes         No          No                No
/// FMT_LBN_ANA_FUNC_VERSION         Integer version of the analysis function                             (none)        Numerical    All           No      Yes         No          No                No
/// ================================ ==================================================================== ============= ============ ============= ======= =========== =========== ================ ===================
///
/// \endrst
///
/// Query the standard STIMSET_SCALE_FACTOR_KEY entry from labnotebook for getting the DAScale.

static Constant MSQ_BL_PRE_PULSE  = 0x0
static Constant MSQ_BL_POST_PULSE = 0x1

static Constant MSQ_RMS_SHORT_TEST = 0x0
static Constant MSQ_RMS_LONG_TEST  = 0x1
static Constant MSQ_TARGETV_TEST   = 0x2

/// @brief Settings structure filled by MSQ_GetPulseSettingsForType()
static Structure MSQ_PulseSettings
	variable prePulseChunkLength // ms
	variable pulseDuration // ms
	variable postPulseChunkLength // ms
EndStructure

/// @brief Fills `s` according to the analysis function type
static Function MSQ_GetPulseSettingsForType(variable type, STRUCT MSQ_PulseSettings &s)

	string msg

	switch(type)
		default:
			ASSERT(0, "unsupported type")
			break
	endswitch

	sprintf msg, "postPulseChunkLength %d, prePulseChunkLength %d, pulseDuration %g", s.postPulseChunkLength, s.prePulseChunkLength, s.pulseDuration
	DEBUGPRINT(msg)
End

/// Return the pulse durations from the labnotebook or calculate them before if required.
/// For convenience unused headstages will have 0 instead of NaN in the returned wave.
static Function/WAVE MSQ_GetPulseDurations(string device, variable type, variable sweepNo, variable totalOnsetDelay, variable headstage, [variable useSCI, variable forceRecalculation])

	string key

	if(ParamIsDefault(forceRecalculation))
		forceRecalculation = 0
	else
		forceRecalculation = !!forceRecalculation
	endif

	if(ParamIsDefault(useSCI))
		useSCI = 0
	else
		useSCI = !!useSCI
	endif

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(type, MSQ_FMT_LBN_PULSE_DUR, query = 1)

	if(useSCI)
		WAVE/Z durations = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	else
		WAVE/Z durations = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	endif

	if(!WaveExists(durations) || forceRecalculation)
		WAVE durations = MSQ_DeterminePulseDuration(device, sweepNo, totalOnsetDelay)

		key = CreateAnaFuncLBNKey(type, MSQ_FMT_LBN_PULSE_DUR)
		ED_AddEntryToLabnotebook(device, key, durations, unit = "ms", overrideSweepNo = sweepNo)
	endif

	durations[] = IsNaN(durations[p]) ? 0 : durations[p]

	return durations
End

/// @brief Determine the pulse duration on each headstage
///
/// Returns the labnotebook wave as well.
static Function/WAVE MSQ_DeterminePulseDuration(string device, variable sweepNo, variable totalOnsetDelay)

	variable i, level, first, last, duration
	string key

	WAVE/Z sweepWave = GetSweepWave(device, sweepNo)

	if(!WaveExists(sweepWave))
		WAVE sweepWave = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
		WAVE config    = GetDAQConfigWave(device)
	else
		WAVE config = GetConfigWave(sweepWave)
	endif

	WAVE statusHS  = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	WAVE durations = LBN_GetNumericWave()

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		WAVE singleDA = AFH_ExtractOneDimDataFromSweep(device, sweepWave, i, XOP_CHANNEL_TYPE_DAC, config = config)
		level = WaveMin(singleDA, totalOnsetDelay, Inf) + GetMachineEpsilon(WaveType(singleDA))

		FindLevel/Q/R=(totalOnsetDelay, Inf)/EDGE=1 singleDA, level
		ASSERT(!V_Flag, "Could not find a rising edge")
		first = V_LevelX

		FindLevel/Q/R=(totalOnsetDelay, Inf)/EDGE=2 singleDA, level
		ASSERT(!V_Flag, "Could not find a falling edge")
		last = V_LevelX

		if(level > 0)
			duration = last - first - DimDelta(singleDA, ROWS)
		else
			duration = first - last + DimDelta(singleDA, ROWS)
		endif

		ASSERT(duration > 0, "Duration must be strictly positive")

		durations[i] = duration
	endfor

	return durations
End

/// @brief Return the number of already acquired sweeps
///        of the given stimset cycle ID
static Function MSQ_NumAcquiredSweepsInSet(string device, variable sweepNo, variable headstage)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

	if(!WaveExists(sweeps)) // very unlikely
		return 0
	endif

	return DimSize(sweeps, ROWS)
End

/// @brief Return the number of passed sweeps in all sweeps from the given
///        repeated acquisition cycle.
static Function MSQ_NumPassesInSet(WAVE numericalValues, variable type, variable sweepNo, variable headstage)

	string key

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

	if(!WaveExists(sweeps)) // very unlikely
		return NaN
	endif

	Make/FREE/N=(DimSize(sweeps, ROWS)) passes
	key      = CreateAnaFuncLBNKey(type, MSQ_FMT_LBN_SWEEP_PASS, query = 1)
	passes[] = GetLastSettingIndep(numericalValues, sweeps[p], key, UNKNOWN_MODE)

	return sum(passes)
End

/// @brief Return the DA stimset length in ms of the given headstage
///
/// @return stimset length or -1 on error
static Function MSQ_GetDAStimsetLength(string device, variable headstage)

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

/// MSQ_PSQ_CreateOverrideResults("ITC18USB_DEV_0", 0, $type) where type is one of:
///
/// #MSQ_FAST_RHEO_EST
///
/// Type:
/// - Double wave
///
/// Value:
/// - x position in ms where the spike is in each sweep/step
///   For convenience the values `0` always means no spike and `1` spike detected (at the appropriate position).
///
/// Rows:
/// - Sweeps in set
///
/// Cols:
/// - IC headstages
///
/// #MSQ_DA_SCALE
///
/// Nothing
///
/// #SC_SPIKE_CONTROL
///
/// Type:
/// - Text wave
///
/// Value:
/// - Key-Valuse pairs in format `key1:value1;key2:value2;` where value can be a comma separated list
/// - `SpontaneousSpikeMax`: single value denoting the maximum value for the spontaneous spiking check
/// - `SpikePosition_ms`: comma separated list with the spike positions in ms. Zero is the start of each pulse
///
/// Rows:
/// - Sweeps in set
///
/// Cols (NUM_HEADSTAGES):
/// - Headstage
///
/// Layers (10):
/// - Pulse index, 0-based
///
/// Chunks (10):
/// - Region, 0-based
Function/WAVE MSQ_CreateOverrideResults(string device, variable headstage, variable type)

	variable DAC, numCols, numRows, numLayers, numChunks, typeOfWave
	string stimset

	DAC = AFH_GetDACFromHeadstage(device, headstage)

	stimset = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
	WAVE/Z wv = WB_CreateAndGetStimSet(stimset)
	ASSERT(WaveExists(wv), "Stimset does not exist")

	switch(type)
		case MSQ_FAST_RHEO_EST:
			numRows = IDX_NumberOfSweepsInSet(stimset)
			WAVE activeHS = DAG_GetActiveHeadstages(device, I_CLAMP_MODE)
			numCols    = Sum(activeHS)
			numLayers  = 0
			numChunks  = 0
			typeOfWave = IGOR_TYPE_64BIT_FLOAT
		case MSQ_DA_SCALE:
			// nothing to set
			break
		case SC_SPIKE_CONTROL:
			// safe upper default
			numRows    = 100
			numCols    = NUM_HEADSTAGES
			numLayers  = 10
			numChunks  = 10
			typeOfWave = 0 // text wave
			break
		default:
			ASSERT(0, "invalid type")
	endswitch

	KillOrMoveToTrash(wv = GetOverrideResults())
	Make/Y=(typeOfWave)/N=(numRows, numCols, numLayers, numChunks) root:overrideResults/WAVE=overrideResults

	return overrideResults
End

/// @brief Search the AD channel of the given headstage for spikes from the
/// pulse onset until the end of the sweep
///
/// @param[in]  device      device
/// @param[in]  type            One of @ref MultiPatchSeqAnalysisFunctionTypes
/// @param[in]  sweepWave       sweep wave with acquired data
/// @param[in]  headstage       headstage in the range [0, NUM_HEADSTAGES[
/// @param[in]  totalOnsetDelay total delay in ms until the stimset data starts
/// @param[in]  numberOfSpikes  [optional, defaults to one] number of spikes to look for
/// @param[out] spikePositions  [optional] returns the position of the first `numberOfSpikes` found on success in ms
/// @param[in]  defaultValue    [optiona, defaults to `NaN`] the value of the other headstages in the returned wave
///
/// @return labnotebook value wave suitable for ED_AddEntryToLabnotebook()
static Function/WAVE MSQ_SearchForSpikes(string device, variable type, WAVE sweepWave, variable headstage, variable totalOnsetDelay, [variable numberOfSpikes, variable defaultValue, WAVE spikePositions])

	variable level, first, last, overrideValue
	variable minVal, maxVal
	string msg

	WAVE config = AFH_GetConfigWave(device, sweepWave)

	if(ParamIsDefault(numberOfSpikes))
		numberOfSpikes = 1
	else
		numberOfSpikes = trunc(numberOfSpikes)
	endif

	if(ParamIsDefault(defaultValue))
		defaultValue = NaN
	endif

	WAVE spikeDetection = LBN_GetNumericWave()
	spikeDetection = (p == headstage ? 0 : defaultValue)

	sprintf msg, "Type %d, headstage %d, totalOnsetDelay %g, numberOfSpikes %d", type, headstage, totalOnsetDelay, numberOfSpikes
	DEBUGPRINT(msg)

	WAVE singleDA = AFH_ExtractOneDimDataFromSweep(device, sweepWave, headstage, XOP_CHANNEL_TYPE_DAC, config = config)
	[minVal, maxVal] = WaveMinAndMax(singleDA, totalOnsetDelay, Inf)

	if(minVal == 0 && maxVal == 0)
		return spikeDetection
	endif

	level = minVal + GetMachineEpsilon(WaveType(singleDA))

	Make/FREE/D levels
	FindLevels/R=(totalOnsetDelay, Inf)/Q/N=2/DEST=levels singleDA, level
	ASSERT(V_LevelsFound == 2, "Could not find two levels")
	first = levels[0]
	last  = Inf

	WAVE singleAD = AFH_ExtractOneDimDataFromSweep(device, sweepWave, headstage, XOP_CHANNEL_TYPE_ADC, config = config)
	ASSERT(!cmpstr(WaveUnits(singleAD, -1), "mV"), "Unexpected AD Unit")

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		NVAR count           = $GetCount(device)

		switch(type)
			case MSQ_FAST_RHEO_EST:
				overrideValue = overrideResults[count][headstage]
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
			Redimension/D/N=(numberOfSpikes) spikePositions
			spikePositions[] = overrideValue
		endif
	else
		// scale with SWS_GetChannelGains(device) when called during mid sweep event
		level = MSQ_SPIKE_LEVEL

		if(numberOfSpikes == 1)
			// search the spike from the rising edge till the end of the wave
			FindLevel/Q/R=(first, last) singleAD, level
			spikeDetection[headstage] = !V_flag

			if(!ParamIsDefault(spikePositions))
				ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
				Redimension/D/N=(numberOfSpikes) spikePositions
				spikePositions[0] = V_LevelX
			endif
		elseif(numberOfSpikes > 1)
			Make/D/FREE/N=0 crossings
			FindLevels/Q/R=(first, last)/N=(numberOfSpikes)/DEST=crossings/EDGE=1 singleAD, level
			spikeDetection[headstage] = !V_flag

			if(!ParamIsDefault(spikePositions))
				ASSERT(WaveExists(spikePositions), "Wave spikePositions must exist")
				Redimension/D/N=(V_LevelsFound) spikePositions

				if(!V_flag && V_LevelsFound > 0)
					spikePositions[] = crossings[p]
				endif
			endif
		else
			ASSERT(0, "Invalid number of spikes value")
		endif
	endif

	ASSERT(IsFinite(spikeDetection[headstage]), "Expected finite result")

	return DEBUGPRINTw(spikeDetection)
End

/// @brief Return true if one of the entries is true for the given headstage. False otherwise.
///        Searches in the complete SCI and assumes that the entries are either 0/1/NaN.
///
/// @todo merge with LBN functions once these are reworked.
Function MSQ_GetLBNEntryForHSSCIBool(WAVE numericalValues, variable sweepNo, variable type, string str, variable headstage)

	string key

	key = CreateAnaFuncLBNKey(type, str, query = 1)
	WAVE/Z values = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(!WaveExists(values))
		return 0
	endif

	WAVE/Z reduced = ZapNaNs(values)

	return WaveExists(reduced) && Sum(reduced) >= 1
End

/// @brief Return the last entry for a given headstage from the full SCI.
///
/// This differs from GetLastSettingSCI as specifically the setting for the
/// passed headstage must be valid.
///
/// @todo merge with LBN functions once these are reworked.
static Function MSQ_GetLBNEntryForHeadstageSCI(WAVE numericalValues, variable sweepNo, variable type, string str, variable headstage)

	string   key
	variable numEntries

	key = CreateAnaFuncLBNKey(type, str, query = 1)
	WAVE/Z values = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(!WaveExists(values))
		return NaN
	endif

	WAVE/Z reduced = ZapNans(values)

	if(!WaveExists(reduced))
		return NaN
	endif

	return reduced[DimSize(reduced, ROWS) - 1]
End

/// @brief Return a list of required parameters for MSQ_FastRheoEst()
Function/S MSQ_FastRheoEst_GetParams()

	return "MaximumDAScale:variable,"            + \
	       "PostDAQDAScale:variable,"            + \
	       "PostDAQDAScaleFactor:variable,"      + \
	       "PostDAQDAScaleForFailedHS:variable," + \
	       "PostDAQDAScaleMinOffset:variable,"   + \
	       "SamplingMultiplier:variable"
End

Function/S MSQ_FastRheoEst_GetHelp(string name)

	strswitch(name)
		case "SamplingMultiplier":
			return "Sampling multiplier, use 1 for no multiplier"
			break
		case "MaximumDAScale":
			return "Maximum allowed DAScale, set to NaN to turn the check off [pA]"
			break
		case "PostDAQDAScaleMinOffset":
			return "Mininum absolute offset value applied to the found DAScale [pA]"
			break
		case "PostDAQDAScaleForFailedHS":
			return "Failed headstages will be set to this DAScale value [pA] in the post set event"
			break
		case "PostDAQDAScale":
			return "If true the found DAScale value will be set at the end of the set"
			break
		case "PostDAQDAScaleFactor":
			return "Scaling factor for setting the DAScale of passed headstages at the end of the set"
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

Function/S MSQ_FastRheoEst_CheckParam(string name, STRUCT CheckParametersStruct &s)

	variable val

	strswitch(name)
		case "PostDAQDAScaleMinOffset":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!(val >= 0))
				return "Must be zero or positive."
			endif
			break
		case "PostDAQDAScaleForFailedHS":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val))
				return "Must be finite."
			endif
			break
		case "SamplingMultiplier":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsValidSamplingMultiplier(val))
				return "Not valid."
			endif
			break
	endswitch

	// other parameters are not checked
	return ""
End

/// @brief Analysis function to find the smallest DAScale where the cell spikes
///
/// Prerequisites:
/// - Assumes that the stimset has a square pulse
///
/// Testing:
/// For testing the spike detection logic, the results can be defined in the override wave,
/// @see MSQ_CreateOverrideResults().
///
/// Decision logic flowchart:
///
/// \rst
///	.. image:: /dot/multi-patch-seq-fast-rheo-estimate.svg
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with pre pulse baseline (-), square pulse (*), and post pulse baseline (-).
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
Function MSQ_FastRheoEst(string device, STRUCT AnalysisFunction_V3 &s)

	variable totalOnsetDelay, setPassed, sweepPassed, multiplier, newDAScaleValue, found, val, limitCheck
	variable i, postDAQDAScale, postDAQDAScaleFactor, DAC, maxDAScale, allHeadstagesExceeded, minRheoOffset
	string key, msg, ctrl
	string stimsets = ""

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			return MSQ_CommonPreDAQ(device, s.headstage)

			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, MSQ_FAST_RHEO_EST, s.headstage, s.sweepNo)

			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				break
			endif

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHSIC = DAG_GetActiveHeadstages(device, I_CLAMP_MODE)

			if(Sum(statusHSIC) == 0)
				printf "(%s) At least one active headstage must have IC clamp mode.\r", device
				ControlWindowToFront()
				return 1
			endif

			multiplier = AFH_GetAnalysisParamNumerical("SamplingMultiplier", s.params)

			PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str = num2str(multiplier))

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHSIC[i])
					continue
				endif

				DAC = AFH_GetDACFromHeadstage(device, i)
				ASSERT(IsFinite(DAC), "Unexpected unassociated DAC")
				stimsets = AddListItem(AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC), stimsets, ";", Inf)
			endfor

			if(ItemsInList(GetUniqueTextEntriesFromList(stimsets)) > 1)
				printf "(%s): Not all IC headstages have the same stimset.\r", device
				ControlWindowToFront()
				return 1
			endif

			minRheoOffset = AFH_GetAnalysisParamNumerical("PostDAQDAScaleMinOffset", s.params)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHSIC[i])
					continue
				endif

				SetDAScale(device, s.sweepNo, i, absolute = MSQ_FRE_INIT_AMP_p100, limitCheck = 0)
			endfor

			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 0)
			PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = 0.1)
			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 0)
			PGC_SetAndActivateControl(device, "setvar_DataAcq_OnsetDelayUser", val = 0)
			PGC_SetAndActivateControl(device, "setvar_DataAcq_TerminationDelay", val = 0)

			WAVE values = LBN_GetNumericWave()
			values[0, NUM_HEADSTAGES - 1] = statusHSIC[p] ? MSQ_FRE_INIT_AMP_p100 : NaN
			key                           = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_STEPSIZE)
			ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = s.sweepNo)

			WAVE values = LBN_GetNumericWave()
			values[0, NUM_HEADSTAGES - 1] = statusHSIC[p] ? 0 : NaN
			key                           = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_EXC)
			ED_AddEntryToLabnotebook(device, key, values, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

			key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_ACTIVE_HS)
			WAVE values = LBN_GetNumericWave()
			values[0, NUM_HEADSTAGES - 1] = statusHS[p]
			ED_AddEntryToLabnotebook(device, key, values, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)
				if(statusHS[i] && !statusHSIC[i]) // active non-IC headstage
					ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
					PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_UNSELECTED, mode = PGC_MODE_FORCE_ON_DISABLED)
				endif
			endfor

			break
		case POST_SWEEP_EVENT:

			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				break
			endif

			WAVE sweepWave       = GetSweepWave(device, s.sweepNo)
			WAVE numericalValues = GetLBNumericalValues(device)

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)

			MSQ_GetPulseDurations(device, MSQ_FAST_RHEO_EST, s.sweepNo, totalOnsetDelay, s.headstage, useSCI = 1)

			WAVE spikeDetection   = LBN_GetNumericWave()
			WAVE headstagePassed  = LBN_GetNumericWave()
			WAVE finalDAScale     = LBN_GetNumericWave()
			WAVE rangeExceededNew = LBN_GetNumericWave()
			WAVE oorDAScale       = LBN_GetNumericWave()

			key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_STEPSIZE, query = 1)
			WAVE stepSize = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)
			WAVE DAScale  = GetLastSetting(numericalValues, s.sweepNo, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
			DAScale[] *= PICO_TO_ONE

			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, s.sweepNo)
			WAVE statusHSIC = DAG_GetActiveHeadstages(device, I_CLAMP_MODE)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHSIC[i])
					continue
				endif

				found = MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo, MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_EXC, i)
				if(found)
					continue
				endif

				found = MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo, MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_HEADSTAGE_PASS, i)
				if(found)
					stepSize[i] = NaN
					continue
				endif

				WAVE spikeDetectionAll = MSQ_SearchForSpikes(device, MSQ_FAST_RHEO_EST, sweepWave, i, totalOnsetDelay)
				spikeDetection[i] = spikeDetectionAll[i]

				ASSERT(IsFinite(stepSize[i]), "Unexpected step size value")
				ASSERT(IsFinite(DaScale[i]), "Unexpected DAScale value")

				headstagePassed[i] = 0
				newDAScaleValue    = NaN

				if(spikeDetection[i])
					if(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_m50))
						newDAScaleValue = DAScale[i] + stepSize[i]
					elseif(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_p10))
						finalDAScale[i]    = DAScale[i]
						headstagePassed[i] = 1
						newDAScaleValue    = 0
					elseif(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_p100))
						stepSize[i]     = MSQ_FRE_INIT_AMP_m50
						newDAScaleValue = DAScale[i] + stepSize[i]
					else
						ASSERT(0, "Unknown stepsize")
					endif
				else // headstage did not spike
					if(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_m50))
						stepSize[i]     = MSQ_FRE_INIT_AMP_p10
						newDAScaleValue = DAScale[i] + stepSize[i]
					elseif(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_p10))
						newDAScaleValue = DAScale[i] + stepSize[i]
					elseif(CheckIfClose(stepSize[i], MSQ_FRE_INIT_AMP_p100))
						newDAScaleValue = DAScale[i] + stepSize[i]
					else
						ASSERT(0, "Unknown stepsize")
					endif
				endif

				sprintf msg, "Headstage %d: spikeDetection %g, stepSize %g, DAScale %g: Has %s\r", i, spikeDetection[i], stepSize[i], DAScale[i], ToPassFail(headstagePassed[i])
				DEBUGPRINT(msg)

				ASSERT(IsFinite(newDAScaleValue), "Unexpected newDAScaleValue")

				maxDAScale = AFH_GetAnalysisParamNumerical("MaximumDAScale", s.params) * PICO_TO_ONE

				if(IsFinite(maxDAScale) && newDAScaleValue > maxDAScale)
					rangeExceededNew[i] = 1
					ASSERT(headstagePassed[i] != 1, "Unexpected headstage passing")
					headstagePassed[i] = 0
				else
					limitCheck    = !AFH_LastSweepInSet(device, s.sweepNo, s.headstage, s.eventType)
					oorDAScale[i] = SetDAScale(device, s.sweepNo, i, absolute = newDAScaleValue, limitCheck = limitCheck)
				endif
			endfor

			ReportOutOfRangeDAScale(device, s.sweepNo, MSQ_FAST_RHEO_EST, oorDAScale)

			key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_SPIKE_DETECT)
			ED_AddEntryToLabnotebook(device, key, spikeDetection, unit = LABNOTEBOOK_BINARY_UNIT)

			key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_HEADSTAGE_PASS)
			ED_AddEntryToLabnotebook(device, key, headstagePassed, unit = LABNOTEBOOK_BINARY_UNIT)

			if(HasOneValidEntry(finalDAScale))
				key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_FINAL_SCALE)
				ED_AddEntryToLabnotebook(device, key, finalDAScale)
			endif

			if(HasOneValidEntry(rangeExceededNew))
				key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_EXC)
				ED_AddEntryToLabnotebook(device, key, rangeExceededNew, unit = LABNOTEBOOK_BINARY_UNIT)
			endif

			key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_STEPSIZE)
			ED_AddEntryToLabnotebook(device, key, stepSize)

			Make/D/FREE/N=(NUM_HEADSTAGES) totalRangeExceeded = 0
			sweepPassed = 1

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHSIC[i])
					continue
				endif

				totalRangeExceeded[i] = MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo, MSQ_FAST_RHEO_EST, \
				                                                    MSQ_FMT_LBN_DASCALE_EXC, i)

				sweepPassed = sweepPassed                                                                                                  \
				              && MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo, MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_HEADSTAGE_PASS, i) \
				              && !MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo, MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_OOR, i)
			endfor

			allHeadstagesExceeded = Sum(totalRangeExceeded) == Sum(statusHSIC)

			WAVE value = LBN_GetNumericWave()
			ASSERT((sweepPassed && !allHeadstagesExceeded) || !sweepPassed, "Invalid sweepPassed and allHeadstagesExceeded combination.")
			value[INDEP_HEADSTAGE] = sweepPassed
			key                    = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, value, unit = LABNOTEBOOK_BINARY_UNIT)

			if(sweepPassed || allHeadstagesExceeded)
				MSQ_ForceSetEvent(device, s.headstage)
				RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
			endif

			sprintf msg, "Sweep has %s\r", ToPassFail(sweepPassed)
			DEBUGPRINT(msg)

			break
		case POST_SET_EVENT:

			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				break
			endif

			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			WAVE numericalValues = GetLBNumericalValues(device)

			Make/N=(NUM_HEADSTAGES)/FREE oorDAScale = MSQ_GetLBNEntryForHSSCIBool(numericalValues, s.sweepNo,             \
			                                                                      MSQ_DA_SCALE, MSQ_FMT_LBN_DASCALE_OOR, p)

			// assuming that all headstages have the same sweeps in their SCI
			setPassed = MSQ_NumPassesInSet(numericalValues, MSQ_FAST_RHEO_EST, s.sweepNo, s.headstage) >= 1 \
			            && Sum(oorDAScale) == 0

			sprintf msg, "Set has %s\r", ToPassFail(setPassed)
			DEBUGPRINT(msg)

			WAVE result = LBN_GetNumericWave()
			result[INDEP_HEADSTAGE] = setPassed
			key                     = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, result, unit = LABNOTEBOOK_BINARY_UNIT)

			postDAQDAScale = AFH_GetAnalysisParamNumerical("PostDAQDAScale", s.params)

			if(postDAQDAScale)
				postDAQDAScaleFactor = AFH_GetAnalysisParamNumerical("PostDAQDAScaleFactor", s.params)

				minRheoOffset = AFH_GetAnalysisParamNumerical("PostDAQDAScaleMinOffset", s.params)

				key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_FINAL_SCALE, query = 1)
				WAVE statusHSIC = DAG_GetActiveHeadstages(device, I_CLAMP_MODE)

				for(i = 0; i < NUM_HEADSTAGES; i += 1)

					if(!statusHSIC[i])
						continue
					endif

					WAVE/Z finalDAScaleAll = GetLastSettingEachSCI(numericalValues, s.sweepNo, key, i, UNKNOWN_MODE)
					if(WaveExists(finalDAScaleAll))
						WAVE finalDAScale = ZapNaNs(finalDAScaleAll)
						ASSERT(DimSize(finalDAScale, ROWS) == 1, "Unexpected finalDAScale")
						val = max(postDAQDAScaleFactor * finalDAScale[0], minRheoOffset * PICO_TO_ONE + finalDAScale[0])
					else
						val = AFH_GetAnalysisParamNumerical("PostDAQDAScaleForFailedHS", s.params) * PICO_TO_ONE
					endif

					// we can't check this here, as we don't know the next stimset
					SetDAScale(device, s.sweepNo, i, absolute = val, limitCheck = 0)
				endfor
			endif

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

			key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_ACTIVE_HS, query = 1)

			WAVE/Z previousActiveHS = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(WaveExists(previousActiveHS))
				for(i = 0; i < NUM_HEADSTAGES; i += 1)
					if(previousActiveHS[i] && !statusHS[i])
						ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
						PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED, mode = PGC_MODE_FORCE_ON_DISABLED)
					endif
				endfor
			endif

			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			AD_UpdateAllDatabrowser()
			break
		case POST_DAQ_EVENT:

			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				break
			endif

			AD_UpdateAllDatabrowser()
			break
		default:
			// do nothing
			break
	endswitch

	return NaN
End

/// @brief Return the DAScale offset [pA] for MSQ_DaScale()
///
/// @return wave with #LABNOTEBOOK_LAYER_COUNT entries, each holding the final DA Scale entry
///         from the previous fast rheo estimate run.
static Function/WAVE MSQ_DS_GetDAScaleOffset(string device, variable headstage)

	variable sweepNo, i

	WAVE values = LBN_GetNumericWave()

	if(TestOverrideActive())
		values[] = MSQ_DS_OFFSETSCALE_FAKE
		return values
	endif

	sweepNo = MSQ_GetLastPassingLongRHSweep(device, headstage)
	if(!IsValidSweepNumber(sweepNo))
		return values
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	values[0, NUM_HEADSTAGES - 1] = MSQ_GetLBNEntryForHeadstageSCI(numericalValues, sweepNo, MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_FINAL_SCALE, p) * ONE_TO_PICO

	return values
End

/// @brief Return a sweep number of an existing sweep matching the following conditions
///
/// - Acquired with Rheobase analysis function
/// - Sweep set was passing
/// - Pulse duration was longer than 500ms
///
/// And as usual we want the *last* matching sweep.
///
/// @return existing sweep number or -1 in case no such sweep could be found
static Function MSQ_GetLastPassingLongRHSweep(string device, variable headstage)

	string key
	variable i, numEntries, sweepNo, sweepCol

	if(TestOverrideActive())
		return MSQ_DS_SWEEP_FAKE
	endif

	WAVE numericalValues = GetLBNumericalValues(device)

	// rheobase sweeps passing
	key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_SET_PASS, query = 1)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, key)

	if(!WaveExists(sweeps))
		return -1
	endif

	// pulse duration
	key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_PULSE_DUR, query = 1)

	numEntries = DimSize(sweeps, ROWS)
	for(i = numEntries - 1; i >= 0; i -= 1)
		sweepNo = sweeps[i]
		WAVE/Z setting = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

		if(WaveExists(setting) && setting[headstage] > 500)
			return sweepNo
		endif
	endfor

	return -1
End

/// @brief Manually force the pre/post set events
///
/// Required to do before skipping sweeps.
/// @todo this hack must go away.
static Function MSQ_ForceSetEvent(string device, variable headstage)

	variable DAC

	WAVE setEventFlag = GetSetEventFlag(device)
	DAC = AFH_GetDACFromHeadstage(device, headstage)

	setEventFlag[DAC][%PRE_SET_EVENT]  = 1
	setEventFlag[DAC][%POST_SET_EVENT] = 1
End

/// @brief Common pre DAQ calls for all multipatch analysis functions
Function MSQ_CommonPreDAQ(string device, variable headstage, [variable clampMode])

	if(ParamIsDefault(clampMode))
		if(!DAG_HeadstageIsHighestActive(device, headstage))
			return NaN
		endif
	else
		if(!DAG_HeadstageIsHighestActive(device, headstage, clampMode = clampMode))
			return NaN
		endif
	endif

	if(DAG_GetNumericalValue(device, "Check_DataAcq_Indexing")           \
	   && !DAG_GetNumericalValue(device, "Check_DataAcq1_IndexingLocked"))
		print "Only locked indexing is supported"
		ControlWindowToFront()
		return 1
	endif

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = 1)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)
End

/// @brief Require parameters from stimset
Function/S MSQ_DAScale_GetParams()

	return "DAScales:wave"
End

Function/S MSQ_DAScale_GetHelp(string name)

	strswitch(name)
		case "DAScales":
			return "DA Scale Factors in pA"
			break
		default:
			ASSERT(0, "Unimplemented for parameter " + name)
			break
	endswitch
End

Function/S MSQ_DAScale_CheckParam(string name, STRUCT CheckParametersStruct &s)

	strswitch(name)
		case "DAScales":
			WAVE/Z wv = AFH_GetAnalysisParamWave(name, s.params)
			if(!WaveExists(wv))
				return "Wave must exist"
			endif

			WaveStats/Q/M=1 wv
			if(V_numNans > 0 || V_numInfs > 0)
				return "Wave must neither have NaNs nor Infs"
			endif
			break
	endswitch

	// other parameters are not checked
	return ""
End

/// @brief Analysis function to apply a list of DAScale values to a range of sweeps
///
/// Decision logic flowchart:
///
/// \rst
/// .. image:: /dot/multi-patch-seq-dascale.svg
/// \endrst
///
Function MSQ_DAScale(string device, STRUCT AnalysisFunction_V3 &s)

	variable i, index, ret, headstagePassed, val, sweepNo
	string msg, key, ctrl

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			return MSQ_CommonPreDAQ(device, s.headstage)

			break
		case PRE_SET_EVENT:
			SetAnalysisFunctionVersion(device, MSQ_DA_SCALE, s.headstage, s.sweepNo)

			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				return NaN
			endif

			PGC_SetAndActivateControl(device, "Popup_Settings_SampIntMult", str = "1")

			WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
			if(sum(statusTTL) != 0)
				printf "(%s) Analysis function does not support TTL channels.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE statusHS   = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
			WAVE statusHSIC = DAG_GetActiveHeadstages(device, I_CLAMP_MODE)

			key = CreateAnaFuncLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_ACTIVE_HS)
			WAVE values = LBN_GetNumericWave()
			values[0, NUM_HEADSTAGES - 1] = statusHS[p]
			ED_AddEntryToLabnotebook(device, key, values, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)

			WAVE numericalValues = GetLBNumericalValues(device)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(TestOverrideActive())
					headstagePassed = 1
				else
					headstagePassed = MSQ_GetLBNEntryForHSSCIBool(numericalValues, sweepNo, MSQ_DA_SCALE, MSQ_FMT_LBN_HEADSTAGE_PASS, i)
				endif

				if(statusHS[i] && (!statusHSIC[i] || !headstagePassed)) // active non-IC headstage or not passing in FastRheoEstimate
					ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
					PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_UNSELECTED)
				endif
			endfor

			WAVE statusHSIC = DAG_GetActiveHeadstages(device, I_CLAMP_MODE)

			if(Sum(statusHSIC) == 0)
				printf "(%s) At least one active headstage must have IC clamp mode.\r", device
				ControlWindowToFront()
				return 1
			endif

			WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(device)

			DAScalesIndex[] = 0

			WAVE daScaleOffset = MSQ_DS_GetDAScaleOffset(device, s.headstage)
			if(!HasOneValidEntry(daScaleOffset))
				printf "(%s): Could not find a valid DAScale threshold value from previous rheobase runs with long pulses.\r", device
				ControlWindowToFront()
				return 1
			endif

			val = DAG_GetNumericalValue(device, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", device
				ControlWindowToFront()
				return 1
			endif

			PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 1)

			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)
			PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)

			DisableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

			break
		case POST_SWEEP_EVENT:

			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				return NaN
			endif

			WAVE values     = LBN_GetNumericWave()
			WAVE statusHSIC = DAG_GetActiveHeadstages(device, I_CLAMP_MODE)
			values[0, NUM_HEADSTAGES - 1] = statusHSIC[p] ? 1 : NaN
			key                           = CreateAnaFuncLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_HEADSTAGE_PASS)
			ED_AddEntryToLabnotebook(device, key, values, unit = LABNOTEBOOK_BINARY_UNIT)

			WAVE values = LBN_GetNumericWave()
			values[INDEP_HEADSTAGE] = 1
			key                     = CreateAnaFuncLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_SWEEP_PASS)
			ED_AddEntryToLabnotebook(device, key, values, unit = LABNOTEBOOK_BINARY_UNIT)

			break
		case POST_SET_EVENT:

			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				return NaN
			endif

			WAVE values = LBN_GetNumericWave()
			values[INDEP_HEADSTAGE] = 1
			key                     = CreateAnaFuncLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_SET_PASS)
			ED_AddEntryToLabnotebook(device, key, values, unit = LABNOTEBOOK_BINARY_UNIT)

			AD_UpdateAllDatabrowser()
			break
		case POST_DAQ_EVENT:
			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				return NaN
			endif

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

			WAVE numericalValues = GetLBNumericalValues(device)

			key = CreateAnaFuncLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_ACTIVE_HS, query = 1)
			WAVE/Z previousActiveHS = GetLastSettingSCI(numericalValues, s.sweepNo, key, s.headstage, UNKNOWN_MODE)

			if(WaveExists(previousActiveHS))
				for(i = 0; i < NUM_HEADSTAGES; i += 1)
					if(previousActiveHS[i] && !statusHS[i])
						ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
						PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)
					endif
				endfor
			endif

			AD_UpdateAllDatabrowser()
			EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")
			break
		default:
			break
	endswitch

	if((s.eventType == PRE_SET_EVENT || s.eventType == POST_SWEEP_EVENT) && DAG_HeadstageIsHighestActive(device, s.headstage))

		WAVE DAScales      = AFH_GetAnalysisParamWave("DAScales", s.params)
		WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(device)

		WAVE daScaleOffset = MSQ_DS_GetDAScaleOffset(device, s.headstage)

		WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			if(!statusHS[i])
				continue
			endif

			index = mod(DAScalesIndex[i], DimSize(DAScales, ROWS))

			ASSERT(isFinite(daScaleOffset[i]), "DAScale offset is non-finite")
			SetDAScale(device, s.sweepNo, i, absolute = (DAScales[index] + daScaleOffset[i]) * PICO_TO_ONE)
			DAScalesIndex[i] += 1
		endfor
	endif
End
