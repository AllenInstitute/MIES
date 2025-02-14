#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AD
#endif // AUTOMATED_TESTING

/// @file MIES_AnalysisFunctions_Dashboard.ipf
/// @brief __AD__ Dashboard for pass/fail style analysis functions

static StrConstant AD_OOR_DASCALE_MSG = "Failure as the future DAScale would be out of range"

/// @brief Update the dashboards of all databrowsers
Function AD_UpdateAllDatabrowser()

	string win, panelList, browserType
	variable i, numEntries

	panelList  = WinList("DB_*", ";", "WIN:1")
	numEntries = ItemsInList(panelList)

	for(i = 0; i < numEntries; i += 1)
		win         = StringFromList(i, panelList)
		browserType = BSP_GetBrowserType(win)
		if(!IsEmpty(browserType))
			AD_Update(win)
		endif
	endfor
End

static Function AD_GetColorForResultMessage(string result)

	strswitch(result)
		case DASHBOARD_PASSING_MESSAGE:
			return 2
		case NOT_AVAILABLE:
			return 0
		default:
			return 1
	endswitch
End

/// @brief Update the dashboards of the given sweepbrowser/databrowser
Function AD_Update(string win)

	string mainPanel
	variable numEntries, refTime

	refTime = DEBUG_TIMER_START()

	mainPanel = BSP_GetPanel(win)

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE/T helpWave  = GetAnaFuncDashboardHelpWave(dfr)
	WAVE   colorWave = GetAnaFuncDashboardColorWave(dfr)
	WAVE   selWave   = GetAnaFuncDashboardselWave(dfr)
	WAVE/T listWave  = GetAnaFuncDashboardListWave(dfr)
	WAVE/T infoWave  = GetAnaFuncDashboardInfoWave(dfr)

	if(BSP_IsActive(mainPanel, MIES_BSP_DS))
		numEntries = AD_FillWaves(win, listWave, infoWave)
	endif

	Redimension/N=(numEntries, -1, -1) selWave, listWave, infoWave, helpWave

	if(numEntries > 0)
		selWave[][][%$LISTBOX_LAYER_FOREGROUND] = AD_GetColorForResultMessage(listWave[p][%Result])

		helpWave[] = "Result:\r" + listWave[p][%Result]

		ScrollListboxIntoView(mainPanel, "list_dashboard", Inf)
	else
		SetNumberInWaveNote(listWave, NOTE_INDEX, 0)
	endif

	DEBUGPRINT_ELAPSED(refTime)
End

static Function/S AD_GetResultMessage(variable anaFuncType, variable passed, WAVE numericalValues, WAVE/T textualValues, variable sweepNo, DFREF sweepDFR, variable headstage, variable ongoingDAQ, variable waMode)

	variable stopReason

	if(passed)
		return "Pass"
	endif

	if(ongoingDAQ)
		// introduced in 87f9cbfa (DAQ: Add stopping reason to the labnotebook, 2021-05-13)
		stopReason = GetLastSettingIndepSCI(numericalValues, sweepNo, "DAQ stop reason", headstage, UNKNOWN_MODE, defValue = NaN)

		if(IsNaN(stopReason))
			return "Sweep not yet finished"
		endif
	endif

	// MSQ_DA
	// - Out of range DAScale

	// MSQ_FRE
	// - MSQ_FMT_LBN_DASCALE_EXC present (optional)
	// - Out of range DAScale
	// - Not enough sweeps

	// MSQ_SC
	// - MSQ_FMT_LBN_RERUN_TRIALS_EXC present
	// - Spike counts state
	// - Spontaneous spiking check
	// - Not enough sweeps
	// - Out of range DAScale

	// PSQ_AR
	// - baseline QC
	// - access resistance QC
	// - resistance ratio QC

	// PSQ_CR
	// - baseline QC
	// - needs at least PSQ_CR_NUM_SWEEPS_PASS passing sweeps with the same to-full-pA rounded DAScale
	// - spike found while none expected (optional)
	// - Out of range DAScale

	// PSQ_DA
	// - baseline QC
	// - Out of range DAScale
	// - SUB/SUPRA: needs at least $NUM_DA_SCALES passing sweeps
	// - SUPRA: if the FinalSlopePercent parameter is present this has to be reached as well
	// - ADAPT: - fewer than $NumInvalidSlopeSweepsAllowed invalid f-I slopes
	//          - fISlopeReached QC or initial f-I slope QC was invalid
	//          - measured all future DAScale values
	//          - enough points for Fit QC

	// PSQ_PB
	// - baseline QC
	// - pipette resistance QC

	// PSQ_RA
	// - baseline QC
	// - needs at least PSQ_RA_NUM_SWEEPS_PASS passing sweeps

	// PSQ_RB
	// - baseline QC
	// - Difference to initial DAScale larger than 60pA?
	// - Out of range DAScale
	// - Not enough sweeps

	// PSQ_SE
	// - baseline QC
	// - seal threshold QC

	// PSQ_SP
	// - Out of range DAScale
	// - only reached PSQ_FMT_LBN_STEPSIZE step size and not PSQ_SP_INIT_AMP_p10 with a spike

	// PSQ_VM
	// - baseline QC
	// - spike pass QC
	// - full average QC

	switch(anaFuncType)
		case MSQ_DA_SCALE:
			return AD_GetMultiDAScaleFailMsg(numericalValues, sweepNo, headstage)
		case MSQ_FAST_RHEO_EST:
			return AD_GetFastRheoEstFailMsg(numericalValues, sweepNo, headstage)
		case PSQ_ACC_RES_SMOKE:
			return AD_GetPerSweepFailMessage(PSQ_ACC_RES_SMOKE, numericalValues, textualValues, sweepNo, sweepDFR, headstage, numRequiredPasses = PSQ_AR_NUM_SWEEPS_PASS)
		case PSQ_CHIRP:
			return AD_GetChirpFailMsg(numericalValues, textualValues, sweepNo, sweepDFR, headstage)
		case PSQ_DA_SCALE:
			return AD_GetDaScaleFailMsg(numericalValues, textualValues, sweepNo, sweepDFR, headstage)
		case PSQ_RAMP:
			return AD_GetPerSweepFailMessage(PSQ_RAMP, numericalValues, textualValues, sweepNo, sweepDFR, headstage, numRequiredPasses = PSQ_RA_NUM_SWEEPS_PASS)
		case PSQ_PIPETTE_BATH:
			return AD_GetPerSweepFailMessage(PSQ_PIPETTE_BATH, numericalValues, textualValues, sweepNo, sweepDFR, headstage, numRequiredPasses = PSQ_PB_NUM_SWEEPS_PASS)
		case PSQ_RHEOBASE:
			return AD_GetRheobaseFailMsg(numericalValues, textualValues, sweepNo, sweepDFR, headstage)
		case PSQ_SEAL_EVALUATION:
			return AD_GetPerSweepFailMessage(PSQ_SEAL_EVALUATION, numericalValues, textualValues, sweepNo, sweepDFR, headstage, numRequiredPasses = PSQ_SE_NUM_SWEEPS_PASS)
		case PSQ_TRUE_REST_VM:
			return AD_GetPerSweepFailMessage(PSQ_TRUE_REST_VM, numericalValues, textualValues, sweepNo, sweepDFR, headstage, numRequiredPasses = PSQ_VM_NUM_SWEEPS_PASS)
		case PSQ_SQUARE_PULSE:
			return AD_GetSquarePulseFailMsg(numericalValues, sweepNo, headstage, waMode)
		case SC_SPIKE_CONTROL:
			return AD_GetSpikeControlFailMsg(numericalValues, textualValues, sweepNo, headstage)
#ifdef AUTOMATED_TESTING
		case TEST_ANALYSIS_FUNCTION: // fallthrough-by-design
#endif
		case INVALID_ANALYSIS_FUNCTION:
			return NOT_AVAILABLE
		default:
			ASSERT(0, "Unsupported analysis function")
	endswitch
End

/// @brief Get result list of analysis function runs
static Function AD_FillWaves(string win, WAVE/T list, WAVE/T info)

	variable i, j, headstage, passed, sweepNo, numEntries, ongoingDAQ, acqState
	variable index, anaFuncType, stimsetCycleID, waMode
	string key, anaFunc, stimset, msg, device, opMode

	WAVE/Z totalSweepsPresent = GetPlainSweepList(win)

	// as many sweeps as entries in numericalValuesWave/textualValuesWave
	WAVE/Z/WAVE numericalValuesWave = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES)
	WAVE/Z/WAVE textualValuesWave   = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES)

	if(!WaveExists(numericalValuesWave) || !WaveExists(textualValuesWave) || !WaveExists(totalSweepsPresent))
		return 0
	endif

	if(BSP_IsDataBrowser(win))
		device   = BSP_GetDevice(win)
		acqState = ROVar(GetAcquisitionState(device))
		DFREF sweepDFR = GetDeviceDataPath(device)
	else
		acqState = AS_INACTIVE
		DFREF  sweepBrowserDFR = SB_GetSweepBrowserFolder(win)
		WAVE/T sweepMap        = GetSweepBrowserMap(sweepBrowserDFR)
	endif

	index = GetNumberFromWaveNote(list, NOTE_INDEX)

	numEntries = DimSize(totalSweepsPresent, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweepNo = totalSweepsPresent[i]

		WAVE textualValues   = textualValuesWave[i]
		WAVE numericalValues = numericalValuesWave[i]

		WAVE/Z headstages = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)

		// present since 602debb9 (Record the active headstage in the settingsHistory, 2014-11-04)
		if(!WaveExists(headstages))
			continue
		endif

		WAVE/Z stimsetCycleIDs = GetLastSetting(numericalValues, sweepNo, STIMSET_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE)

		if(!WaveExists(stimsetCycleIDs)) // TP during DAQ or data before d6046561 (Add a stimset acquisition cycle ID, 2018-05-30)
			continue
		endif

		WAVE/Z lastSweepStimsetCycleIDs = GetLastSetting(numericalValues, WaveMax(totalSweepsPresent), STIMSET_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE)

		key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
		WAVE/Z/T anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)

		WAVE anaFuncTypes = LBN_GetNumericWave(defValue = INVALID_ANALYSIS_FUNCTION)

		if(WaveExists(anaFuncs))
			if(GetLastSettingIndep(numericalValues, sweepNo, "Skip analysis functions", DATA_ACQUISITION_MODE, defValue = 0))
				anaFuncs[] = anaFuncs[p] + " (Skipped)"
			else
				anaFuncTypes[] = MapAnaFuncToConstant(anaFuncs[p])
			endif
		else
			WAVE/T anaFuncs = LBN_GetTextWave(defValue = NOT_AVAILABLE)
		endif

		WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
		ASSERT(WaveExists(stimsets), "No stimsets found")

		for(j = 0; j < NUM_HEADSTAGES; j += 1)

			headstage = j

			if(headstages[headstage] != 1)
				continue
			endif

			stimsetCycleID = stimsetCycleIDs[headstage]

			FindValue/RMD=[][0]/TXOP=4/TEXT=(AD_FormatListKey(stimsetCycleID, headstage)) info
			if(V_Value >= 0)
				if(!cmpstr(info[V_Value][%$"Ongoing DAQ"], "1"))
					// if DAQ was ongoing we want to overwrite this entry and all later entries
					index              = V_Value
					info[index, Inf][] = ""
				else
					// otherwise we want to keep it
					continue
				endif
			endif

			[anaFuncType, waMode] = AD_GetAnalysisFunctionType(numericalValues, anaFuncTypes, sweepNo, headstage)
			anaFunc               = anaFuncs[headstage]
			stimset               = stimsets[headstage]

			if(anaFuncType == INVALID_ANALYSIS_FUNCTION)
				passed = NaN
				// current sweep is from the same SCI than the last acquired sweep and DAQ is not inactive
				ASSERT(WaveExists(lastSweepStimsetCycleIDs), "Missing last sweep SCIs")
				ongoingDAQ = (lastSweepStimsetCycleIDs[headstage] == stimsetCycleID) && (acqState != AS_INACTIVE)
			else
				key        = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SET_PASS, query = 1, waMode = waMode)
				passed     = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
				ongoingDAQ = IsNaN(passed) && (acqState != AS_INACTIVE)
			endif

			if(BSP_IsSweepBrowser(win))
				DFREF sweepDFR = SB_GetSweepDataFolder(sweepMap, sweepNo = sweepNo)
			endif

			msg = AD_GetResultMessage(anaFuncType, passed, numericalValues, textualValues, sweepNo, sweepDFR, headstage, ongoingDAQ, waMode)

			EnsureLargeEnoughWave(list, dimension = ROWS, indexShouldExist = index)
			EnsureLargeEnoughWave(info, dimension = ROWS, indexShouldExist = index)

			// decorate the analysis function name with the operation mode if present
			if(anaFuncType == PSQ_DA_SCALE)
				opMode = AD_GetDAScaleOperationMode(numericalValues, textualValues, sweepNo, headstage)

				if(PSQ_DS_IsValidMode(opMode))
					anaFunc += " (" + opMode + ")"
				endif
			endif

			list[index][0] = stimset
			list[index][1] = anaFunc
			list[index][2] = num2str(headstage)
			list[index][3] = msg

			// get the passing/failing sweeps
			// PSQ_VM, PSQ_SE, PSQ_PB, PSQ_CR, PSQ_DA, PSQ_RA, PSQ_SP, MSQ_DA, MSQ_FRE, MSQ_SC: use PSQ_FMT_LBN_SWEEP_PASS
			// PSQ_RB: If passed use last spiking/non-spiking duo
			//         If not passed, all are failing

			WAVE sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

			switch(anaFuncType)
				case PSQ_ACC_RES_SMOKE:
				case PSQ_CHIRP:
				case PSQ_DA_SCALE:
				case PSQ_PIPETTE_BATH:
				case PSQ_RAMP:
				case PSQ_SQUARE_PULSE:
				case PSQ_SEAL_EVALUATION:
				case MSQ_DA_SCALE:
				case MSQ_FAST_RHEO_EST:
				case SC_SPIKE_CONTROL:
				case PSQ_TRUE_REST_VM:
					key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SWEEP_PASS, query = 1, waMode = waMode)
					WAVE/Z sweepPass = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE, defValue = 0)

					if(!WaveExists(sweepPass))
						Duplicate/FREE sweeps, sweepPass
						sweepPass = 0
					else
						ASSERT(DimSize(sweeps, ROWS) == DimSize(sweepPass, ROWS), "Unexpected wave sizes")
					endif

					Duplicate/FREE sweeps, passingSweepsAll, failingSweepsAll
					passingSweepsAll[] = sweepPass[p] ? sweeps[p] : NaN
					failingSweepsAll[] = !sweepPass[p] ? sweeps[p] : NaN

					WAVE/Z passingSweeps = ZapNaNs(passingSweepsAll)
					WAVE/Z failingSweeps = ZapNaNs(failingSweepsAll)

					break
				case PSQ_RHEOBASE:
					[WAVE passingSweeps, WAVE failingSweeps] = AFH_GetRheobaseSweepsSCISweepQCSplitted(numericalValues, sweepNo, headstage, sweeps, passed)
					break
#ifdef AUTOMATED_TESTING
				case TEST_ANALYSIS_FUNCTION: // fallthrough-by-design
#endif
				case INVALID_ANALYSIS_FUNCTION:
					// all sweeps are both passing and failing
					Duplicate/FREE sweeps, failingSweeps
					Duplicate/FREE sweeps, passingSweeps
					break
				default:
					ASSERT(0, "Unsupported analysis function")
					break
			endswitch

			info[index][%$STIMSET_ACQ_CYCLE_ID_KEY] = AD_FormatListKey(stimsetCycleID, headstage)
			info[index][%$"Passing Sweeps"]         = NumericWaveToList(passingSweeps, ";")
			info[index][%$"Failing Sweeps"]         = NumericWaveToList(failingSweeps, ";")
			info[index][%$"Ongoing DAQ"]            = num2str(ongoingDAQ)

			SetNumberInWaveNote(list, NOTE_INDEX, ++index)
		endfor
	endfor

	return index
End

/// @brief Return the analysis function type and a bit-mask of possible workarounds for CreateAnaFuncLBNKey()
///
/// @param numericalValues numeric labnotebook
/// @param anaFuncTypes    wave with the analysis function types as derived from MapAnaFuncToConstant()
/// @param sweepNo         sweep number
/// @param headstage       headstage
Function [variable anaFuncType, variable waMode] AD_GetAnalysisFunctionType(WAVE numericalValues, WAVE anaFuncTypes, variable sweepNo, variable headstage)

	string   key
	variable passed

	anaFuncType = anaFuncTypes[headstage]

	if(anaFuncType == PSQ_SQUARE_PULSE)
		// querying the analysis function version would have been a more generic choice
		// but that is only available since c2b1e0fb (Add a version labnotebook entry for
		// all PSQ/MSQ analysis functions, 2021-06-18)
		key    = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SET_PASS, query = 1)
		passed = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

		if(IsNaN(passed))
			// labnotebook entries of PSQ_SquarePulse are stored with PSQ_SEAL_EVALUATION name, see
			// be830309 (CreateAnaFuncLBNKey: Add missing break after PSQ_SQUARE_PULSE, 2022-05-20)
			return [anaFuncType, PSQ_LBN_WA_SP_SE]
		endif
	endif

	return [anaFuncType, PSQ_LBN_WA_NONE]
End

static Function/S AD_FormatListKey(variable stimsetCycleID, variable headstage)

	return num2strHighPrec(stimsetCycleID, shorten = 1) + "_HS" + num2str(headstage)
End

static Function AD_LabnotebookEntryExistsAndIsTrue(WAVE/Z data)

	if(!WaveExists(data))
		return 0
	endif

	WAVE/Z reduced = ZapNaNs(data)

	return WaveExists(reduced) && Sum(reduced) > 0
End

static Function/S AD_GetSquarePulseFailMsg(WAVE numericalValues, variable sweepNo, variable headstage, variable waMode)

	string msg, key
	variable stepSize

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1, waMode = waMode)
	WAVE/Z spikeWithDAScaleZero = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	// Prior to 1e2f38ba (Merge pull request #1073 in ENG/mies-igor from
	// ~THOMASB/mies-igor:feature/larger-fifo-for-NI to master, 2019-02-09)
	// this labnotebook key does not exist
	if(WaveExists(spikeWithDAScaleZero))
		WAVE spikeWithDAScaleZeroReduced = ZapNaNs(spikeWithDAScaleZero)
		if(DimSize(spikeWithDAScaleZeroReduced, ROWS) == PSQ_SP_MAX_DASCALE_ZERO)
			return "Failure as we did had three spikes with a DAScale of 0.0pA."
		endif
	endif

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_DASCALE_OOR, query = 1)
	WAVE/Z oorDASCale = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(oorDASCale))
		return AD_OOR_DASCALE_MSG
	endif

	key      = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_STEPSIZE, query = 1, waMode = waMode)
	stepSize = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	if(!IsFinite(stepSize))
		BUG("Missing DAScale stepsize LBN entry")
		return "Failure"
	endif

	if(stepSize != PSQ_SP_INIT_AMP_p10)
		sprintf msg, "Failure as we did not reach the desired DAScale step size of %.0W0PA but only %.0W0PA", PSQ_SP_INIT_AMP_p10, stepSize
		return msg
	endif

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1, waMode = waMode)
	WAVE/Z spikeDetection = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(!spikeDetection[headstage])
		sprintf msg, "Failure as we reached the desired DAScale step size of %.0W0PA but we ran out of sweeps as it did not spike.", PSQ_SP_INIT_AMP_p10
		return msg
	endif

	BUG("Unknown reason for failure")
	return "Failure"
End

static Function/S AD_GetDAScaleOperationMode(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, variable headstage)

	WAVE/Z/T params = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, "Function params (encoded)", headstage, DATA_ACQUISITION_MODE)

	// fallback to old names
	if(!WaveExists(params))
		WAVE/T params = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, "Function params", headstage, DATA_ACQUISITION_MODE)
	endif

	// present since 0ef300da (PSQ_DaScale: Add new operation mode, 2018-02-15)
	return AFH_GetAnalysisParamTextual("OperationMode", params[headstage])
End

static Function/S AD_GetDAScaleFailMsg(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, DFREF sweepDFR, variable headstage)

	string msg, key, fISlopeStr, opMode
	variable numPasses, numRequiredPasses, finalSlopePercent, slopePercentage, measuredAllFutureDAScales
	variable numInvalidSlopeSweepsAllowed, numFailedSweeps, numRequiredFISlopeReached, numFISlopeReached

	numPasses = PSQ_NumPassesInSet(numericalValues, PSQ_DA_SCALE, sweepNo, headstage)

	WAVE/Z/T params = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, "Function params (encoded)", headstage, DATA_ACQUISITION_MODE)

	// fallback to old names
	if(!WaveExists(params))
		WAVE/T params = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, "Function params", headstage, DATA_ACQUISITION_MODE)
	endif

	key = CreateAnaFuncLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_DASCALE_OOR, query = 1)
	WAVE/Z oorDASCale = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(oorDASCale))
		return AD_OOR_DASCALE_MSG
	endif

	opMode = AFH_GetAnalysisParamTextual("OperationMode", params[headstage])

	strswitch(opMode)
		case "": // handle data prior to 0ef300da (PSQ_DaScale: Add new operation mode, 2018-02-15)
		case PSQ_DS_SUB:
		case PSQ_DS_SUPRA:

			WAVE/Z DAScales = AFH_GetAnalysisParamWave("DAScales", params[headstage])
			ASSERT(WaveExists(DASCales), "analysis function parameters don't have a DAScales entry")
			numRequiredPasses = DimSize(DAScales, ROWS)

			msg = AD_GetPerSweepFailMessage(PSQ_DA_SCALE, numericalValues, textualValues, sweepNo, sweepDFR, headstage, numRequiredPasses = numRequiredPasses)

			if(!IsEmpty(msg))
				return msg
			endif

			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED_PASS, query = 1)
			WAVE/Z fISlopeReached = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
			ASSERT(WaveExists(fiSlopeReached), "Missing fI Slope reached LBN entry")

			numFISlopeReached         = Sum(fISlopeReached)
			numRequiredFISlopeReached = 1

			if(numFISlopeReached < numRequiredFISlopeReached)
				key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE, query = 1)
				WAVE fISlope = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
				fISlopeStr = NumericWaveToList(fISlope, "%, ", format = "%.15g", trailSep = 0)

				finalSlopePercent = AFH_GetAnalysisParamNumerical("FinalSlopePercent", params[headstage])
				sprintf msg, "Failure as we did not reach the required fI slope (target: %g%% reached: %s%%)", finalSlopePercent, fISlopeStr
			endif

			if(!IsEmpty(msg))
				return msg
			endif

			break
		case PSQ_DS_ADAPT:
			msg = AD_GetPerSweepFailMessage(PSQ_DA_SCALE, numericalValues, textualValues, sweepNo, sweepDFR, headstage)

			if(!IsEmpty(msg))
				return msg
			endif

			key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_VALID_SLOPE_PASS, query = 1)
			WAVE slopePasses = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
			numFailedSweeps = DimSize(slopePasses, ROWS) - Sum(slopePasses)

			numInvalidSlopeSweepsAllowed = AFH_GetAnalysisParamNumerical("NumInvalidSlopeSweepsAllowed", params[headstage], defValue = PSQ_DA_NUM_INVALID_SLOPE_SWEEPS_ALLOWED)

			if(numFailedSweeps >= numInvalidSlopeSweepsAllowed)
				sprintf msg, "Encountered %g sweeps with invalid slopes, but only %g are allowed.", numFailedSweeps, numInvalidSlopeSweepsAllowed
			endif

			if(!IsEmpty(msg))
				return msg
			endif

			numRequiredFISlopeReached = AFH_GetAnalysisParamNumerical("NumSweepsWithSaturation", params[headstage], defValue = PSQ_DA_NUM_SWEEPS_SATURATION)

			if(numFISlopeReached < numRequiredFISlopeReached)
				sprintf msg, "Failure as we did not reach enough sweeps with passing fISlope QC (target: %d reached: %d)", numRequiredFISlopeReached, numFISlopeReached
			endif

			if(!IsEmpty(msg))
				return msg
			endif

			key                       = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES_PASS, query = 1)
			measuredAllFutureDAScales = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

			if(!measuredAllFutureDAScales)
				sprintf msg, "Could not acquire all requested future DAScale values"
			endif

			if(!IsEmpty(msg))
				return msg
			endif

			break
		default:
			ASSERT(0, "Invalid opMode")
	endswitch

	BUG("Unknown reason for failure")
	return "Failure"
End

static Function/S AD_GetMultiDAScaleFailMsg(WAVE numericalValues, variable sweepNo, variable headstage)

	string key

	key = CreateAnaFuncLBNKey(MSQ_DA_SCALE, MSQ_FMT_LBN_DASCALE_OOR, query = 1)
	WAVE/Z oorDASCale = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(oorDASCale))
		return AD_OOR_DASCALE_MSG
	endif

	BUG("Unknown reason for failure")
	return "Failure"
End

static Function/S AD_GetRheobaseFailMsg(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, DFREF sweepDFR, variable headstage)

	string key, prefix, msg, pattern

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_DASCALE_OOR, query = 1)
	WAVE/Z oorDASCale = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(oorDASCale))
		return AD_OOR_DASCALE_MSG
	endif

	prefix = AD_GetPerSweepFailMessage(PSQ_RHEOBASE, numericalValues, textualValues, sweepNo, sweepDFR, headstage)

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	WAVE/Z spikeDetect = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	pattern = NumericWaveToList(spikeDetect, ", ", format = "%g", trailSep = 0)
	pattern = SelectString(IsEmpty(pattern), pattern, "n.a.")

	sprintf msg, "%s\rWe were not able to find the correct on/off spike pattern (%s)", prefix, pattern
	return msg
End

static Function/S AD_GetFastRheoEstFailMsg(WAVE numericalValues, variable sweepNo, variable headstage)

	string key

	key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_EXC, query = 1)
	WAVE/Z daScaleExc = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(daScaleExc))
		return "Max DA scale exceeded failure"
	endif

	key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_OOR, query = 1)
	WAVE/Z oorDASCale = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(oorDASCale))
		return AD_OOR_DASCALE_MSG
	endif

	return "Failure as we ran out of sweeps"
End

static Function/S AD_GetSpikeControlFailMsg(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable headstage)

	string key, msg

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_RERUN_TRIAL_EXC, query = 1)
	WAVE/Z trialsExceeded = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(trialsExceeded))
		return "Maximum number of rerun trials exceeded"
	endif

	key = CreateAnaFuncLBNKey(SC_SPIKE_CONTROL, MSQ_FMT_LBN_DASCALE_OOR, query = 1)
	WAVE/Z oorDASCale = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(oorDASCale))
		return AD_OOR_DASCALE_MSG
	endif

	return "Failure as we ran out of sweeps"
End

static Function/S AD_GetChirpFailMsg(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, DFREF sweepDFR, variable headstage)

	string key, msg, str
	string text = ""
	variable i, numSweeps, setPassed, maxOccurences

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_DASCALE_OOR, query = 1)
	WAVE/Z oorDASCale = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(oorDASCale))
		return AD_OOR_DASCALE_MSG
	endif

	msg = AD_GetPerSweepFailMessage(PSQ_CHIRP, numericalValues, textualValues, sweepNo, sweepDFR, headstage, numRequiredPasses = PSQ_CR_NUM_SWEEPS_PASS)

	if(!IsEmpty(msg))
		return msg
	endif

	// all sweeps passed, but the set did not pass
	[setPassed, maxOccurences] = PSQ_CR_SetHasPassed(numericalValues, sweepNo, headstage)

	if(!setPassed)
		key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
		WAVE sweepPass = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

		WAVE DAScales = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, headstage, DATA_ACQUISITION_MODE)
		ASSERT(DimSize(sweepPass, ROWS) == DimSize(DAScales, ROWS), "Unexpected sizes")

		numSweeps = DimSize(sweepPass, ROWS)
		for(i = 0; i < numSweeps; i += 1)
			sprintf str, "%g:%s, ", DAScales[i], ToPassFail(sweepPass[i])

			text += str
		endfor

		text = RemoveEnding(text, ", ")

		sprintf msg, "Failure as we did not have enough passing sweeps with the same DAScale value (maximum #%g), \"DAScale:SweepQC\" -> (%s)", maxOccurences, text
		return msg
	endif

	BUG("Unknown reason for failure")
	return "Failure"
End

/// @brief Return an appropriate error message if the baseline QC failed for the given sweep, or an empty string otherwise
///
/// @param anaFuncType     One of @ref PatchSeqAnalysisFunctionTypes
/// @param numericalValues Numerical labnotebook
/// @param sweepNo         Sweep number
/// @param headstage       Headstage
///
/// @retval qc  0/1 for failing or passing, NaN in case it could not be determined
/// @retval msg error message for the failure case
static Function [variable qc, string msg] AD_GetBaselineFailMsg(variable anaFuncType, WAVE numericalValues, variable sweepNo, variable headstage)

	variable i, chunkQC
	string key

	switch(anaFuncType)
		case PSQ_ACC_RES_SMOKE:
		case PSQ_DA_SCALE:
		case PSQ_PIPETTE_BATH:
		case PSQ_SEAL_EVALUATION:
		case PSQ_RHEOBASE:
		case PSQ_RAMP:
		case PSQ_CHIRP:
		case PSQ_TRUE_REST_VM:
			key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQC = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

			if(!WaveExists(baselineQC))
				return [NaN, ""]
			endif

			if(baselineQC[headstage])
				return [1, ""]
			endif

			for(i = 0;; i += 1)
				key     = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_CHUNK_PASS, query = 1, chunk = i)
				chunkQC = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(IsNaN(chunkQC))
					// no more chunks
					break
				endif

				if(!chunkQC)
					// baseline chunks fail due to one of the four QC tests failing:
					//
					// RMS short
					// RMS long
					// target voltage
					// leak current
					//
					// These are executed in order and failure of one of them results
					// the others ones not being executed.
					msg = AD_GetBaselineChunkFailMsg(anaFuncType, numericalValues, sweepNo, headstage, i, PSQ_FMT_LBN_RMS_SHORT_PASS, "RMS short")
					if(!IsEmpty(msg))
						return [0, msg]
					endif

					msg = AD_GetBaselineChunkFailMsg(anaFuncType, numericalValues, sweepNo, headstage, i, PSQ_FMT_LBN_RMS_LONG_PASS, "RMS long")
					if(!IsEmpty(msg))
						return [0, msg]
					endif

					msg = AD_GetBaselineChunkFailMsg(anaFuncType, numericalValues, sweepNo, headstage, i, PSQ_FMT_LBN_TARGETV_PASS, "target voltage")
					if(!IsEmpty(msg))
						return [0, msg]
					endif

					msg = AD_GetBaselineChunkFailMsg(anaFuncType, numericalValues, sweepNo, headstage, i, PSQ_FMT_LBN_LEAKCUR_PASS, "leak current")
					if(!IsEmpty(msg))
						return [0, msg]
					endif

					BUG("Unknown chunk test failed")
					return [NaN, ""]
				endif
			endfor

			if(IsEmpty(msg))
				BUG("Could not find a failing chunk")
			endif
			break
		default:
			BUG("No support for analysis function type: " + num2str(anaFuncType))
	endswitch

	return [NaN, ""]
End

static Function/S AD_GetBaselineChunkFailMsg(variable anaFuncType, WAVE numericalValues, variable sweepNo, variable headstage, variable chunk, string subkey, string testname)

	string key, msg
	variable check

	key = CreateAnaFuncLBNKey(anaFuncType, subkey, query = 1, chunk = chunk)
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(!WaveExists(settings))
		// check was not performed
		return ""
	endif

	check = settings[headstage]

	ASSERT(IsFinite(check), "Invalid QC value")

	if(check)
		// check passed
		return ""
	endif

	// check failed
	sprintf msg, "Baseline QC failure in chunk %d due to %s %s test.", chunk, ToPassFail(check), testname
	return msg
End

/// @brief Gather per sweep failure information for some analysis function types
///
/// @param anaFuncType       analysis function type
/// @param numericalValues   numerical labnotebook
/// @param textualValues     textual labnotebook
/// @param refSweepNo        reference sweep number
/// @param sweepDFR          datafolder reference to the folder holding the sweep data
/// @param headstage         headstage
/// @param numRequiredPasses [optional, defaults to off] allows to determine the set failure state by not having reached enough passing sets
///
/// @sa AD_GetResultMessage()
static Function/S AD_GetPerSweepFailMessage(variable anaFuncType, WAVE numericalValues, WAVE/T textualValues, variable refSweepNo, DFREF sweepDFR, variable headstage, [variable numRequiredPasses])

	string key, msg, str
	string text = ""
	variable numPasses, i, numSweeps, sweepNo, boundsAction, spikeCheck, resistancePass, accessRestPass, resistanceRatio
	variable avgCheckPass, stopReason, stimsetQC, baselineQC, enoughFIPointsQC, oneFailingSweep
	string perSweepFailedMessage = ""

	if(!ParamIsDefault(numRequiredPasses))
		numPasses = PSQ_NumPassesInSet(numericalValues, anaFuncType, refSweepNo, headstage)

		if(numPasses >= numRequiredPasses)
			return ""
		endif
	endif

	key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	WAVE/Z sweepPass = GetLastSettingIndepEachSCI(numericalValues, refSweepNo, key, headstage, UNKNOWN_MODE)

	WAVE sweeps = AFH_GetSweepsFromSameSCI(numericalValues, refSweepNo, headstage)
	numSweeps = DimSize(sweeps, ROWS)

	for(i = 0; i < numSweeps; i += 1)
		sweepNo = sweeps[i]
		text    = ""

		if(WaveExists(sweepPass) && sweepPass[i])
			sprintf text, "Sweep %d passed", sweeps[i]
			perSweepFailedMessage += text + "\r"
			continue
		endif

		oneFailingSweep = 1

		stopReason = GetLastSettingIndep(numericalValues, sweepNo, "DAQ stop reason", UNKNOWN_MODE)
		if(!IsNaN(stopReason) && stopReason != DQ_STOP_REASON_FINISHED)
			if(stopReason == DQ_STOP_REASON_DAQ_BUTTON)
				msg = "DAQ was stopped early via button"
			else
				sprintf msg, "DAQ was stopped early (%#X)", stopReason
			endif
			sprintf text, "Sweep %d failed: %s", sweepNo, msg

			perSweepFailedMessage += text + "\r"
			continue
		endif

		switch(anaFuncType)
			case PSQ_ACC_RES_SMOKE:
				[baselineQC, msg] = AD_GetBaselineFailMsg(anaFuncType, numericalValues, sweepNo, headstage)

				if(!IsEmpty(msg))
					sprintf text, "Sweep %d failed: %s", sweepNo, msg
					break
				endif

				key            = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_AR_ACCESS_RESISTANCE_PASS, query = 1)
				accessRestPass = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(IsFinite(accessRestPass) && !accessRestPass)
					sprintf text, "Sweep %d failed: access resistance is out of range", sweepNo
					break
				endif

				key             = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_AR_RESISTANCE_RATIO_PASS, query = 1)
				resistanceRatio = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(IsFinite(resistanceRatio) && !resistanceRatio)
					sprintf text, "Sweep %d failed: resistance ratio is out of range", sweepNo
					break
				endif
				break
			case PSQ_CHIRP:
				key       = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_STIMSET_QC, query = 1)
				stimsetQC = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				// not available in ed5d20c7 (Merge pull request #1434 from
				// AllenInstitute/bugfix/1434-install-tuf-xop-with-release-package,
				// 2022-07-20) and earlier
				if(IsFinite(stimsetQC) && !stimsetQC)
					sprintf text, "Sweep %d failed: stimset is unsuitable", sweepNo
					break
				endif

				[baselineQC, msg] = AD_GetBaselineFailMsg(PSQ_CHIRP, numericalValues, sweepNo, headstage)

				if(!IsEmpty(msg))
					sprintf text, "Sweep %d failed: %s", sweepNo, msg
					break
				endif

				key          = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_BOUNDS_ACTION, query = 1)
				boundsAction = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(IsFinite(boundsAction) && boundsAction != PSQ_CR_PASS)
					sprintf text, "Sweep %d failed: bounds action %s", sweepNo, PSQ_CR_BoundsActionToString(boundsAction)
					break
				endif

				key        = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_CR_SPIKE_CHECK, query = 1)
				spikeCheck = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

				if(spikeCheck)
					key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SPIKE_PASS, query = 1)
					WAVE/Z spikePass = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

					if(WaveExists(spikePass) && !spikePass[headstage])
						sprintf text, "Sweep %d failed: found spikes", sweepNo
						break
					endif
				endif
				break
			case PSQ_DA_SCALE:
				[baselineQC, msg] = AD_GetBaselineFailMsg(anaFuncType, numericalValues, sweepNo, headstage)

				if(!IsEmpty(msg))
					sprintf text, "Sweep %d failed: %s", sweepNo, msg
					break
				endif

				key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_RB_DASCALE_EXC, query = 1)
				WAVE/Z daScaleExc = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(WaveExists(daScaleExc) && daScaleExc[headstage])
					sprintf text, "Sweep %d failed: Max DA scale exceeded failure", sweepNo
					break
				endif

				key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_RB_LIMITED_RES, query = 1)
				WAVE/Z limitedResolution = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(WaveExists(limitedResolution) && limitedResolution[headstage])
					sprintf text, "Sweep %d failed: Limited resolution", sweepNo
					break
				endif

				key              = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_DA_AT_ENOUGH_FI_POINTS_PASS, query = 1)
				enoughFIPointsQC = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(IsFinite(enoughFIPointsQC) && !enoughFIPointsQC)
					sprintf text, "Sweep %d failed: Not enough points for fit", sweepNo
					break
				endif

				key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_DA_AT_VALID_SLOPE_PASS, query = 1)
				WAVE/Z validFitSlope = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(WaveExists(validFitSlope) && !validFitSlope[headstage])
					sprintf text, "Sweep %d failed: Invalid fit slope", sweepNo
					break
				endif

				break
			case PSQ_PIPETTE_BATH:
				[baselineQC, msg] = AD_GetBaselineFailMsg(anaFuncType, numericalValues, sweepNo, headstage)

				if(!IsEmpty(msg))
					sprintf text, "Sweep %d failed: %s", sweepNo, msg
					break
				endif

				key            = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_PB_RESISTANCE_PASS, query = 1)
				resistancePass = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(IsFinite(resistancePass) && !resistancePass)
					sprintf text, "Sweep %d failed: Pipette resistance is out of range", sweepNo
					break
				endif
				break
			case PSQ_RAMP:
				[baselineQC, msg] = AD_GetBaselineFailMsg(anaFuncType, numericalValues, sweepNo, headstage)

				if(!IsEmpty(msg))
					sprintf text, "Sweep %d failed: %s", sweepNo, msg
					break
				endif
				break
			case PSQ_RHEOBASE:
				[baselineQC, msg] = AD_GetBaselineFailMsg(anaFuncType, numericalValues, sweepNo, headstage)

				if(!IsEmpty(msg))
					sprintf text, "Sweep %d failed: %s", sweepNo, msg
					break
				endif

				if(baselineQC == 1 && IsEmpty(msg))
					// Speciality: Rheobase does not have a Sweep QC entry and only
					//             baseline QC determines a passing sweep
					sprintf text, "Sweep %d passed", sweeps[i]
				endif
				break
			case PSQ_SEAL_EVALUATION:
				[baselineQC, msg] = AD_GetBaselineFailMsg(anaFuncType, numericalValues, sweepNo, headstage)

				if(!IsEmpty(msg))
					sprintf text, "Sweep %d failed: %s", sweepNo, msg
					break
				endif

				key            = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SE_RESISTANCE_PASS, query = 1)
				resistancePass = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(IsFinite(resistancePass) && !resistancePass)
					sprintf text, "Sweep %d failed: Seal resistance is out of range", sweepNo
					break
				endif
				break
			case PSQ_TRUE_REST_VM:
				[baselineQC, msg] = AD_GetBaselineFailMsg(anaFuncType, numericalValues, sweepNo, headstage)

				if(!IsEmpty(msg))
					sprintf text, "Sweep %d failed: %s", sweepNo, msg
					break
				endif

				key          = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_VM_FULL_AVG_PASS, query = 1)
				avgCheckPass = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(IsFinite(avgCheckPass) && !avgCheckPass)
					sprintf text, "Sweep %d failed: average QC check failed", sweepNo
					break
				endif

				key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SPIKE_PASS, query = 1)
				WAVE/Z spikePass = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(WaveExists(spikePass) && !spikePass[headstage])
					sprintf text, "Sweep %d failed: found spikes", sweepNo
					break
				endif

				break
			default:
				ASSERT(0, "Unsupported analysis function")
		endswitch

		if(IsEmpty(text))
			// check that we had the correct sampling interval
			key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SAMPLING_PASS, query = 1)
			WAVE/Z samplingIntervalQC = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
			if(WaveExists(samplingIntervalQC) && !samplingIntervalQC[INDEP_HEADSTAGE])
				msg = "The used sampling frequency did not match the \"SamplingFrequency\" analysis parameter."
				sprintf text, "Sweep %d failed: %s", sweepNo, msg
			endif
		endif

		if(IsEmpty(text))
			text = AD_HasAsyncQCFailed(numericalValues, textualValues, anaFuncType, sweepNo, headstage)
		endif

		if(IsNaN(stopReason) && IsEmpty(text))
			msg = AD_HasPrematureStopLegacy(numericalValues, textualValues, anaFuncType, sweepNo, sweepDFR, headstage)
			sprintf text, "Sweep %d failed: %s", sweepNo, msg
		endif

		if(IsEmpty(text))
			BUG("Unknown reason for failure")
			sprintf text, "Sweep %d failed: Unknown reasons", sweepNo
		endif

		perSweepFailedMessage += text + "\r"
	endfor

	if(!oneFailingSweep)
		return ""
	endif

	if(!ParamIsDefault(numRequiredPasses))
		sprintf msg, "Failure as we ran out of sweeps (%d passed but we needed %d).\r%s", numPasses, numRequiredPasses, perSweepFailedMessage
	else
		sprintf msg, "Failure as we ran out of sweeps.\r%s", perSweepFailedMessage
	endif

	return RemoveEnding(msg, "\r")
End

static Function/S AD_HasAsyncQCFailed(WAVE numericalValues, WAVE/T textualValues, variable anaFuncType, variable sweepNo, variable headstage)

	string key, msg, str
	string text = ""
	variable chan, asyncAlarm

	key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_ASYNC_PASS, query = 1)
	WAVE/Z asyncChannelQC = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	if(WaveExists(asyncChannelQC) && asyncChannelQC[INDEP_HEADSTAGE])
		// passed
		return ""
	endif

	WAVE/T params        = GetLastSetting(textualValues, sweepNo, "Function params (encoded)", DATA_ACQUISITION_MODE)
	WAVE/Z asyncChannels = AFH_GetAnalysisParamWave("AsyncQCChannels", params[headstage])

	if(!WaveExists(asyncChannelQC))
		if(WaveExists(asyncChannels))
			// sweep finished early
			return ""
		endif

		// async labnotebook entries present since 3d450a44 (PSQ_AccessResistanceSmoke: Support async alarms, 2022-05-18)
		return ""
	endif

	for(chan : asyncChannels)
		sprintf key, "Async Alarm %d State", chan
		asyncAlarm = !GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)

		if(asyncAlarm)
			continue
		endif

		sprintf str, "%d:%s", chan, ToPassFail(asyncAlarm)
		text += str + ","
	endfor

	if(IsEmpty(text))
		BUG("Broken async QC calculation")
		text = "unknown"
	endif

	sprintf msg, "Sweep %d failed: The asynchronous channel QC check failed (%s).", sweepNo, RemoveEnding(text, ",")

	return msg
End

// Early stopped analysis functions prior to 87f9cbfa (DAQ: Add stopping reason to the labnotebook, 2021-05-13)
// need to be handled specially as we can only see if it was stopped early or not, but not why
static Function/S AD_HasPrematureStopLegacy(WAVE numericalValues, WAVE/T textualValues, variable anaFuncType, variable sweepNo, DFREF sweepDFR, variable headstage)

	variable once

	DFREF     singleSweepDFR = GetSingleSweepFolder(sweepDFR, sweepNo)
	WAVE/WAVE ADData         = GetDAQDataSingleColumnWaves(singleSweepDFR, XOP_CHANNEL_TYPE_ADC)

	for(WAVE/Z AD : ADData)
		if(WaveExists(AD))
			once = 1
			ASSERT(DimSize(AD, ROWS) > 0, "Empty sweepNo: " + num2istr(sweepNo))

			FindValue/FNAN/R AD

			if(V_Value >= 0)
				return DAQ_STOPPED_EARLY_LEGACY_MSG
			endif
		endif
	endfor

	ASSERT(once, "Expected at least one AD channel for sweepNo: " + num2istr(sweepNo))

	return ""
End

/// @brief Show the sweeps from the selected SCIs in the dashboard
static Function AD_SelectResult(string win)

	string bspPanel, list
	variable numEntries, i

	bspPanel = BSP_GetPanel(win)

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE selWave = GetAnaFuncDashboardselWave(dfr)

	Duplicate/FREE/RMD=[*][0] selWave, selection
	Make/FREE/T/N=(DimSize(selection, ROWS)) sweepList

	WAVE/T info = GetAnaFuncDashboardInfoWave(dfr)

	Make/N=0/FREE sweepsWithDuplicates
	if(GetCheckBoxState(bspPanel, "check_BrowserSettings_DB_Passed"))
		sweepList[] = SelectString(selection[p], "", info[p][%$"Passing Sweeps"])
		list        = TextWaveToList(sweepList, ";")

		if(!IsEmpty(list))
			WAVE wv = ListToNumericWave(list, ";")
			Concatenate/NP {wv}, sweepsWithDuplicates
		endif
	endif

	if(GetCheckBoxState(bspPanel, "check_BrowserSettings_DB_Failed"))
		sweepList[] = SelectString(selection[p], "", info[p][%$"Failing Sweeps"])
		list        = TextWaveToList(sweepList, ";")

		if(!IsEmpty(list))
			WAVE wv = ListToNumericWave(list, ";")
			Concatenate/NP {wv}, sweepsWithDuplicates
		endif
	endif

	WAVE/Z sweepsWithDuplicatesClean = ZapNans(sweepsWithDuplicates)

	if(!WaveExists(sweepsWithDuplicatesClean))
		print "Select the Passed/Failed checkboxes to display the sweeps"
		return NaN
	endif

	WAVE sweeps = GetUniqueEntries(sweepsWithDuplicatesClean)
	numEntries = DimSize(sweeps, ROWS)

	if(BSP_IsDataBrowser(win))
		WAVE/T ovsListWave = GetOverlaySweepsListWave(dfr)

		// update databrowser if required and not already done
		WAVE/Z indizes = FindIndizes(ovsListWave, var = sweeps[numEntries - 1])
		if(!WaveExists(indizes))
			DB_UpdateToLastSweep(win, force = 1)
		endif
	endif

	if(!BSP_IsDataBrowser(win) && WaveExists(sweeps))
		WAVE   allSweeps     = GetPlainSweepList(win)
		WAVE/Z presentSweeps = GetSetIntersection(allSweeps, sweeps)
		if(!WaveExists(presentSweeps) || EqualWaves(presentSweeps, sweeps, EQWAVES_DATA) != 1)
			printf "Some requested sweeps can not be displayed, as they are not loaded into this sweepbrowser.\r"
			ControlWindowToFront()
		endif
	endif

	OVS_ChangeSweepSelectionState(win, 1, sweeps = sweeps, invertOthers = 1)
End

/// @brief Plot the inner/outer bounds for `PSQ_CHIRP`
///
/// Requires that the sweep is displayed.
Function AD_PlotBounds(string browser, variable sweepNo)

	string key, graph, leftAxis
	variable outerRelativeBound, innerRelativeBound, baselineVoltage, lastX, headstage

	WAVE/Z   numericalValues = BSP_GetLogbookWave(browser, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
	WAVE/Z/T textualValues   = BSP_GetLogbookWave(browser, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)
	ASSERT(WaveExists(numericalValues) && WaveExists(textualValues), "Missing labnotebook")

	WAVE/Z statusHS = GetLastSetting(numericalValues, sweepNo, "Headstage Active", UNKNOWN_MODE)
	ASSERT(WaveExists(statusHS), "No active headstages")

	WAVE/Z indizes = FindIndizes(statusHS, var = 1)
	ASSERT(WaveExists(indizes) && DimSize(indizes, ROWS) == 1, "Could not find one valid entry.")
	headstage = indizes[0]

	WAVE/T stimsets = GetLastSetting(textualValues, sweepNo, stim_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	WAVE/T params   = GetLastSetting(textualValues, sweepNo, "Function params (encoded)", DATA_ACQUISITION_MODE)

	outerRelativeBound = AFH_GetAnalysisParamNumerical("OuterRelativeBound", params[headstage])
	innerRelativeBound = AFH_GetAnalysisParamNumerical("InnerRelativeBound", params[headstage])

	key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_TARGETV, query = 1, chunk = 0)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)

	if(!WaveExists(settings))
		printf "Could not find the baseline voltage (key: %s) of sweep %d.\r", key, sweepNo
		return NaN
	endif

	WAVE statusADC = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)

	graph = GetMainWindow(browser)

	WAVE/Z/T leftAxisMatches = TUD_GetUserDataAsWave(graph, "YAXIS",                                                 \
	                                                 keys = {"channelType", "channelNumber", "sweepNumber"},         \
	                                                 values = {"AD", num2str(statusADC[headstage]), num2str(sweepNo)})
	ASSERT(WaveExists(leftAxisMatches) && DimSize(leftAxisMatches, ROWS) >= 1, "Could not find sweep displayed")
	leftAxis = leftAxisMatches[0]

	baselineVoltage = settings[headstage]

	DFREF dfr = BSP_GetFolder(browser, MIES_BSP_PANEL_FOLDER)

	Make/O/N=2 dfr:chirpBoundUpperMax/WAVE=upperMax
	Make/O/N=2 dfr:chirpBoundUpperMin/WAVE=upperMin
	Make/O/N=2 dfr:chirpBoundLowerMax/WAVE=lowerMax
	Make/O/N=2 dfr:chirpBoundLowerMin/WAVE=lowerMin

	// V -> mV
	upperMax[] = baselineVoltage * ONE_TO_MILLI + outerRelativeBound
	upperMin[] = baselineVoltage * ONE_TO_MILLI + innerRelativeBound
	lowerMax[] = baselineVoltage * ONE_TO_MILLI - innerRelativeBound
	lowerMin[] = baselineVoltage * ONE_TO_MILLI - outerRelativeBound

	GetAxis/W=$graph/Q bottom
	lastX = V_max

	SetScale/I x, 0, lastX, "ms", upperMax, upperMin, lowerMax, lowerMin

	AppendToGraph/W=$graph/L=$leftAxis upperMax, upperMin, lowerMax, lowerMin
	ModifyGraph/W=$graph lstyle(chirpBoundUpperMax)=7, rgb(chirpBoundUpperMax)=(0, 0, 65535)
	ModifyGraph/W=$graph lstyle(chirpBoundUpperMin)=7, rgb(chirpBoundUpperMin)=(0, 0, 65535)
	ModifyGraph/W=$graph lstyle(chirpBoundLowerMax)=7, rgb(chirpBoundLowerMax)=(0, 0, 65535)
	ModifyGraph/W=$graph lstyle(chirpBoundLowerMin)=7, rgb(chirpBoundLowerMin)=(0, 0, 65535)
End

Function AD_ListBoxProc(STRUCT WMListboxAction &lba) : ListBoxControl

	switch(lba.eventCode)
		case 3: // double click
		case 4: // cell selection
		case 5: // cell selection plus Shift key
			AD_SelectResult(lba.win)
			break
		default:
			break
	endswitch

	return 0
End

Function AD_CheckProc_PassedSweeps(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up
			AD_SelectResult(cba.win)
			break
		default:
			break
	endswitch

	return 0
End

Function AD_CheckProc_FailedSweeps(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up
			AD_SelectResult(cba.win)
			break
		default:
			break
	endswitch

	return 0
End

Function AD_CheckProc_Toggle(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string win

	switch(cba.eventCode)
		case 2: // mouse up
			win = cba.win
			AD_Update(win)

			AdaptDependentControls(win, "check_BrowserSettings_OVS;check_BrowserSettings_ADC;check_BrowserSettings_DAC", CHECKBOX_UNSELECTED, cba.checked, DEP_CTRLS_SAME)

			if(cba.checked)
				EnableControls(win, "check_BrowserSettings_DB_Failed;check_BrowserSettings_DB_Passed")
			else
				DisableControls(win, "check_BrowserSettings_DB_Failed;check_BrowserSettings_DB_Passed")
			endif

			break
		default:
			break
	endswitch

	return 0
End
