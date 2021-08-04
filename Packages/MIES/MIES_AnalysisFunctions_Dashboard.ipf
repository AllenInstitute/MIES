#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AD
#endif

/// @file MIES_AnalysisFunctions_Dashboard.ipf
/// @brief __AD__ Dashboard for pass/fail style analysis functions

/// @brief Update the dashboards of all databrowsers
Function AD_UpdateAllDatabrowser()

	string win, panelList, browserType
	variable i, numEntries

	panelList = WinList("DB_*", ";", "WIN:1")
	numEntries = ItemsInList(panelList)

	for(i = 0; i < numEntries; i += 1)
		win = StringFromList(i, panelList)
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
Function AD_Update(win)
	string win

	string mainPanel
	variable numEntries, refTime

	refTime = DEBUG_TIMER_START()

	mainPanel = BSP_GetPanel(win)

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE/T helpWave = GetAnaFuncDashboardHelpWave(dfr)
	WAVE colorWave  = GetAnaFuncDashboardColorWave(dfr)
	WAVE selWave    = GetAnaFuncDashboardselWave(dfr)
	WAVE/T listWave = GetAnaFuncDashboardListWave(dfr)
	WAVE/T infoWave = GetAnaFuncDashboardInfoWave(dfr)

	if(BSP_IsActive(mainPanel, MIES_BSP_DS))
		numEntries = AD_FillWaves(win, listWave, infoWave)
	endif

	Redimension/N=(numEntries, -1, -1) selWave, listWave, infoWave, helpWave

	if(numEntries > 0)
		selWave[][][%foreColors] = AD_GetColorForResultMessage(listWave[p][%Result])

		helpWave[] = "Result: " + listWave[p][%Result]

		EnableControls(mainPanel, "check_BrowserSettings_DB_Failed;check_BrowserSettings_DB_Passed")
	else
		SetNumberInWaveNote(listWave, NOTE_INDEX, 0)
		DisableControls(mainPanel, "check_BrowserSettings_DB_Failed;check_BrowserSettings_DB_Passed")
	endif

	DEBUGPRINT_ELAPSED(refTime)
End

static Function/S AD_GetResultMessage(variable anaFuncType, variable passed, WAVE numericalValues, WAVE/T textualValues, variable sweepNo, variable headstage)

	if(passed)
		return "Pass"
	endif

	// PSQ_DA, PSQ_RB, PSQ_RA, PSQ_SP, PSQ_CR
	// PSQ_FMT_LBN_BL_QC_PASS

	// MSQ_DA
	// - always passes

	// MSQ_FRE
	// - MSQ_FMT_LBN_DASCALE_EXC present (optional)
	// - Not enough sweeps

	// MSQ_SC
	// - MSQ_FMT_LBN_RERUN_TRIALS_EXC present
	// - Spike counts state
	// - Spontaneous spiking check
	// - Not enough sweeps

	// PSQ_CR
	// - needs at least PSQ_CR_NUM_SWEEPS_PASS passing sweeps with the same to-full-pA rounded DAScale

	// PSQ_DA
	// - needs at least $NUM_DA_SCALES passing sweeps
	//   and for supra mode if the FinalSlopePercent parameter is present this has to be reached as well

	// PSQ_RA
	// - needs at least PSQ_RA_NUM_SWEEPS_PASS passing sweeps

	// PSQ_RB
	// - Difference to initial DAScale larger than 60pA?
	// - Not enough sweeps

	// PSQ_SP
	// - only reached PSQ_FMT_LBN_STEPSIZE step size and not PSQ_SP_INIT_AMP_p10 with a spike

	switch(anaFuncType)
		case MSQ_DA_SCALE:
			BUG("Unknown reason for failure")
			return "Failure"
		case MSQ_FAST_RHEO_EST:
			return AD_GetFastRheoEstFailMsg(numericalValues, sweepNo, headstage)
		case PSQ_CHIRP:
			return AD_GetChirpFailMsg(numericalValues, sweepNo, headstage)
		case PSQ_DA_SCALE:
			return AD_GetDaScaleFailMsg(numericalValues, textualValues, sweepNo, headstage)
		case PSQ_RAMP:
			return AD_GetRampFailMsg(numericalValues, sweepNo, headstage)
		case PSQ_RHEOBASE:
			return AD_GetRheobaseFailMsg(numericalValues, sweepNo, headstage)
		case PSQ_SQUARE_PULSE:
			return AD_GetSquarePulseFailMsg(numericalValues, sweepNo, headstage)
		case SC_SPIKE_CONTROL:
			return AD_GetSpikeControlFailMsg(numericalValues, textualValues, sweepNo, headstage)
		case INVALID_ANALYSIS_FUNCTION:
			return NOT_AVAILABLE
		default:
			ASSERT(0, "Unsupported analysis function")
	endswitch
End

/// @brief Get result list of analysis function runs
static Function AD_FillWaves(win, list, info)
	string win
	WAVE/T list, info

	variable i, j, headstage, passed, sweepNo, numEntries
	variable index, anaFuncType, stimsetCycleID, firstValid, lastValid
	string key, anaFunc, stimset, msg

	WAVE/Z totalSweepsPresent = GetPlainSweepList(win)

	// as many sweeps as entries in numericalValuesWave/textualValuesWave
	WAVE/WAVE/Z numericalValuesWave = BSP_GetLBNWave(win, LBN_NUMERICAL_VALUES)
	WAVE/WAVE/Z textualValuesWave   = BSP_GetLBNWave(win, LBN_TEXTUAL_VALUES)

	if(!WaveExists(numericalValuesWave) || !WaveExists(textualValuesWave) || !WaveExists(totalSweepsPresent))
		return 0
	endif

	index = GetNumberFromWaveNote(list, NOTE_INDEX)

	numEntries = DimSize(totalSweepsPresent, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweepNo = totalSweepsPresent[i]

		WAVE textualValues   = textualValuesWave[i]
		WAVE numericalValues = numericalValuesWave[i]

		key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
		WAVE/Z/T anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)

		if(WaveExists(anaFuncs))
			Make/N=(LABNOTEBOOK_LAYER_COUNT)/FREE anaFuncTypes = MapAnaFuncToConstant(anaFuncs[p])
		else
			Make/N=(LABNOTEBOOK_LAYER_COUNT)/FREE/T anaFuncs = NOT_AVAILABLE
			Make/N=(LABNOTEBOOK_LAYER_COUNT)/FREE anaFuncTypes = INVALID_ANALYSIS_FUNCTION
		endif

		WAVE/Z headstages = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)

		// present since 602debb9 (Record the active headstage in the settingsHistory, 2014-11-04)
		if(!WaveExists(headstages))
			continue
		endif

		for(j = 0; j < NUM_HEADSTAGES; j += 1)

			headstage = j

			if(headstages[headstage] != 1)
				continue
			endif

			anaFuncType = anaFuncTypes[headstage]
			anaFunc = anaFuncs[headstage]

			WAVE/Z stimsetCycleIDs = GetLastSetting(numericalValues, sweepNo, STIMSET_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE)

			if(!WaveExists(stimsetCycleIDs)) // TP during DAQ or data before d6046561 (Add a stimset acquisition cycle ID, 2018-05-30)
				continue
			endif

			stimsetCycleID = stimsetCycleIDs[headstage]

			FindValue/RMD=[][0]/TXOP=4/TEXT=AD_FormatListKey(stimsetCycleID, headstage) info
			if(V_Value >= 0) // already included
				continue
			endif

			WAVE/Z/T stimsets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			ASSERT(WaveExists(stimsets), "No stimsets found")

			stimset = stimsets[headstage]

			if(anaFuncType != INVALID_ANALYSIS_FUNCTION)
				key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SET_PASS, query = 1)
				passed = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

				if(isNaN(passed))
					// the set is not yet finished
					continue
				endif
			endif

			msg = AD_GetResultMessage(anaFuncType, passed, numericalValues, textualValues, sweepNo, headstage)

			EnsureLargeEnoughWave(list, dimension = ROWS, minimumSize = index)
			EnsureLargeEnoughWave(info, dimension = ROWS, minimumSize = index)

			list[index][0] = stimset
			list[index][1] = anaFunc
			list[index][2] = num2str(headstage)
			list[index][3] = msg

			// get the passing/failing sweeps
			// PSQ_CR, PSQ_DA, PSQ_RA, PSQ_SP, MSQ_DA, MSQ_FRE, MSQ_SC: use PSQ_FMT_LBN_SWEEP_PASS
			// PSQ_RB: If passed use last spiking/non-spiking duo
			//     If not passed, all are failing

			WAVE sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

			switch(anaFuncType)
				case PSQ_CHIRP:
				case PSQ_DA_SCALE:
				case PSQ_RAMP:
				case PSQ_SQUARE_PULSE:
				case MSQ_DA_SCALE:
				case MSQ_FAST_RHEO_EST:
				case SC_SPIKE_CONTROL:
					key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
					WAVE sweepPass = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
					ASSERT(DimSize(sweeps, ROWS) == DimSize(sweepPass, ROWS), "Unexpected wave sizes")

					Duplicate/FREE sweeps, passingSweepsAll, failingSweepsAll
					passingSweepsAll[] = sweepPass[p]  ? sweeps[p] : NaN
					failingSweepsAll[] = !sweepPass[p] ? sweeps[p] : NaN

					WAVE/Z passingSweeps = ZapNaNs(passingSweepsAll)
					WAVE/Z failingSweeps = ZapNaNs(failingSweepsAll)

					break
				case PSQ_RHEOBASE:
					key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
					if(passed)
						WAVE spikeDetection = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
						ASSERT(DimSize(sweeps, ROWS) == DimSize(spikeDetection, ROWS), "Unexpected wave sizes")

						firstValid = DimSize(spikeDetection, ROWS) - 2
						lastValid  = DimSize(spikeDetection, ROWS) - 1
						ASSERT(Sum(spikeDetection, firstValid, lastValid) == 1, "Unexpected spike/non-spike duo")
						Duplicate/FREE/R=[firstValid, lastValid] sweeps, passingSweeps
						Duplicate/FREE/R=[0, firstValid - 1] sweeps, failingSweeps
					else
						Duplicate/FREE sweeps, failingSweeps
						WAVE/Z passingSweeps
					endif
					break
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
			info[index][%$"Passing Sweeps"] = NumericWaveToList(passingSweeps, ";")
			info[index][%$"Failing Sweeps"] = NumericWaveToList(failingSweeps, ";")

			SetNumberInWaveNote(list, NOTE_INDEX, ++index)
		endfor
	endfor

	return index
End

static Function/S AD_FormatListKey(variable stimsetCycleID, variable headstage)

	return num2str(stimsetCycleID) + "_HS" + num2str(headstage)
End

static Function AD_LabnotebookEntryExistsAndIsTrue(WAVE/Z data)

	if(!WaveExists(data))
		return 0
	endif

	WAVE/Z reduced = ZapNaNs(data)

	return WaveExists(reduced) && Sum(reduced) > 0
End

/// @brief Return an appropriate error message for why #PSQ_SQUARE_PULSE failed
///
/// @param numericalValues Numerical labnotebook
/// @param sweepNo         Sweep number
/// @param headstage       Headstage
static Function/S AD_GetSquarePulseFailMsg(numericalValues, sweepNo, headstage)
	variable sweepNo
	WAVE numericalValues
	variable headstage

	string msg, key
	variable stepSize

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DASCALE_ZERO, query = 1)
	WAVE/Z spikeWithDAScaleZero = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	// Prior to 1e2f38ba (Merge pull request #1073 in ENG/mies-igor from
	// ~THOMASB/mies-igor:feature/larger-fifo-for-NI to master, 2019-02-09)
	// this labnotebook key does not exist
	if(WaveExists(spikeWithDAScaleZero))
		WAVE spikeWithDAScaleZeroReduced = ZapNaNs(spikeWithDAScaleZero)
		if(DimSize(spikeWithDAScaleZeroReduced, ROWS) == 3)
			return "Failure as we did had three spikes with a DAScale of 0.0pA."
		endif
	endif

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_STEPSIZE, query = 1)
	stepSize = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	ASSERT(IsFinite(stepSize), "Missing DAScale stepsize LBN entry")

	if(stepSize != PSQ_SP_INIT_AMP_p10)
		sprintf msg, "Failure as we did not reach the desired DAScale step size of %.0W0PA but only %.0W0PA", PSQ_SP_INIT_AMP_p10, stepSize
		return msg
	endif

	key = CreateAnaFuncLBNKey(PSQ_SQUARE_PULSE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	WAVE/Z spikeDetection = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(!spikeDetection[headstage])
		sprintf msg, "Failure as we reached the desired DAScale step size of %.0W0PA but we ran out of sweeps as it did not spike.", PSQ_SP_INIT_AMP_p10
		return msg
	endif

	BUG("Unknown reason for failure")
	return "Failure"
End

/// @brief Return an appropriate error message for why #PSQ_DA_SCALE failed
///
/// @param numericalValues Numerical labnotebook
/// @param textualValues   Textual labnotebook
/// @param sweepNo         Sweep number
/// @param headstage       Headstage
static Function/S AD_GetDAScaleFailMsg(numericalValues, textualValues, sweepNo, headstage)
	WAVE numericalValues
	WAVE/T textualValues
	variable sweepNo
	variable headstage

	string msg, key, fISlopeStr
	variable numPasses, numRequiredPasses, finalSlopePercent

	numPasses = PSQ_NumPassesInSet(numericalValues, PSQ_DA_SCALE, sweepNo, headstage)

	WAVE/T/Z params = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, "Function params (encoded)", headstage, DATA_ACQUISITION_MODE)

	// fallback to old names
	if(!WaveExists(params))
		WAVE/T params = GetLastSettingTextSCI(numericalValues, textualValues, sweepNo, "Function params", headstage, DATA_ACQUISITION_MODE)
	endif

	WAVE/Z DAScales = AFH_GetAnalysisParamWave("DAScales", params[headstage])
	ASSERT(WaveExists(DASCales), "analysis function parameters don't have a DAScales entry")
	numRequiredPasses = DimSize(DAScales, ROWS)

	if(numPasses < numRequiredPasses)
		sprintf msg, "Failure as we ran out of sweeps (%d passed but we needed %d)", numPasses, numRequiredPasses
		return msg
	endif

	key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE_REACHED, query = 1)
	WAVE/Z fISlopeReached = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	ASSERT(WaveExists(fiSlopeReached), "Missing fI Slope reached LBN entry")

	if(Sum(fISlopeReached) == 0)
		key = CreateAnaFuncLBNKey(PSQ_DA_SCALE, PSQ_FMT_LBN_DA_fI_SLOPE, query = 1)
		WAVE fISlope = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
		fISlopeStr = RemoveEnding(NumericWaveToList(fISlope, "%, ", format = "%.15g"), "%, ")

		finalSlopePercent = AFH_GetAnalysisParamNumerical("FinalSlopePercent", params[headstage])

		sprintf msg, "Failure as we did not reach the required fI slope (target: %g%% reached: %s%%)", finalSlopePercent, fISlopeStr
		return msg
	endif

	BUG("Unknown reason for failure")
	return "Failure"
End

/// @brief Return an appropriate error message for why #PSQ_RAMP failed
///
/// @param numericalValues Numerical labnotebook
/// @param sweepNo         Sweep number
/// @param headstage       Headstage
static Function/S AD_GetRampFailMsg(numericalValues, sweepNo, headstage)
	variable sweepNo
	WAVE numericalValues
	variable headstage

	string msg
	variable numPasses

	msg = AD_GetBaselineFailMsg(PSQ_RAMP, numericalValues, sweepNo, headstage)

	if(!IsEmpty(msg))
		return msg
	endif

	numPasses = PSQ_NumPassesInSet(numericalValues, PSQ_RAMP, sweepNo, headstage)
	if(numPasses < PSQ_RA_NUM_SWEEPS_PASS)
		sprintf msg, "Failure as we ran out of sweeps (%d passed but we needed %d)", numPasses, PSQ_RA_NUM_SWEEPS_PASS
		return msg
	endif

	BUG("Unknown reason for failure")
	return "Failure"
End

/// @brief Return an appropriate error message for why #PSQ_RHEOBASE failed
///
/// @param numericalValues Numerical labnotebook
/// @param sweepNo         Sweep number
/// @param headstage       Headstage
static Function/S AD_GetRheobaseFailMsg(numericalValues, sweepNo, headstage)
	variable sweepNo
	WAVE numericalValues
	variable headstage

	string key, msg

	msg = AD_GetBaselineFailMsg(PSQ_RHEOBASE, numericalValues, sweepNo, headstage)

	if(!IsEmpty(msg))
		return msg
	endif

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_DASCALE_EXC, query = 1)
	WAVE/Z daScaleExc = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	ASSERT(WaveExists(daScaleExc), "Missing DAScale exceeded LBN entry")

	if(AD_LabnotebookEntryExistsAndIsTrue(daScaleExc))
		return "Max DA scale exceeded failure"
	endif

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_LIMITED_RES, query = 1)
	WAVE/Z limitedResolution = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	ASSERT(WaveExists(limitedResolution), "Missing limited resolution labnotebook entry")

	if(AD_LabnotebookEntryExistsAndIsTrue(limitedResolution))
		return "Failure due to limited resolution"
	endif

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	WAVE/Z spikeDetect = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	sprintf msg, "Failure as we were not able to find the correct on/off spike pattern (%s)", RemoveEnding(NumericWaveToList(spikeDetect, ", ", format="%g"), ", ")
	return msg
End

static Function/S AD_GetFastRheoEstFailMsg(WAVE numericalValues, variable sweepNo, variable headstage)

	string key

	key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_EXC, query = 1)
	WAVE/Z daScaleExc = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(AD_LabnotebookEntryExistsAndIsTrue(daScaleExc))
		return "Max DA scale exceeded failure"
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

	return "Failure as we ran out of sweeps"
End

/// @brief Return an appropriate error message for why #PSQ_CHIRP failed
///
/// @param numericalValues Numerical labnotebook
/// @param sweepNo         Sweep number
/// @param headstage       Headstage
static Function/S AD_GetChirpFailMsg(numericalValues, sweepNo, headstage)
	WAVE numericalValues
	variable sweepNo
	variable headstage

	string key, msg, str
	string text = ""
	variable numPasses, i, numEntries, setPassed, maxOccurences

	msg = AD_GetBaselineFailMsg(PSQ_CHIRP, numericalValues, sweepNo, headstage)

	if(!IsEmpty(msg))
		return msg
	endif

	numPasses = PSQ_NumPassesInSet(numericalValues, PSQ_CHIRP, sweepNo, headstage)
	if(numPasses < PSQ_CR_NUM_SWEEPS_PASS)
		sprintf msg, "Failure as we ran out of sweeps (%d passed but we needed %d)", numPasses, PSQ_CR_NUM_SWEEPS_PASS
		return msg
	endif

	[setPassed, maxOccurences] = PSQ_CR_SetHasPassed(numericalValues, sweepNo, headstage)

	if(!setPassed)

		key = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
		WAVE sweepPass = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

		WAVE DAScales = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, headstage, DATA_ACQUISITION_MODE)
		ASSERT(DimSize(sweepPass, ROWS) == DimSize(DAScales, ROWS), "Unexpected sizes")

		for(i = 0; i < numEntries; i += 1)
			sprintf str, "%g:%d, ", DAScales[i], sweepPass[i]

			text += str
		endfor

		text = RemoveEnding(text, ", ")

		sprintf msg, "Failure as we did not have enough passing sweeps with the same DAScale value (maximum #%g), \"DAScale:SweepQC\" -> (%s)", maxOccurences, text
		return msg
	endif

	BUG("Unknown reason for failure")
	return "Failure"
End

/// @brief Return an appropriate error message if the baseline QC failed, or an empty string otherwise
///
/// @param anaFuncType     One of @ref PatchSeqAnalysisFunctionTypes
/// @param numericalValues Numerical labnotebook
/// @param sweepNo         Sweep number
/// @param headstage       Headstage
static Function/S AD_GetBaselineFailMsg(anaFuncType, numericalValues, sweepNo, headstage)
	variable anaFuncType, sweepNo
	WAVE numericalValues
	variable headstage

	variable i, chunkQC
	string key, msg

	switch(anaFuncType)
		case PSQ_DA_SCALE:
		case PSQ_RHEOBASE:
		case PSQ_RAMP:
		case PSQ_CHIRP:
			key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQC = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

			if(anaFuncType == PSQ_CHIRP && !WaveExists(baselineQC))
				// we did not evaluate the baseline completely but aborted earlier
				return ""
			endif

			ASSERT(WaveExists(baselineQC), "Missing baseline QC LBN entry")

			if(!baselineQC[headstage])
				for(i = 0; ;i += 1)
					key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_CHUNK_PASS, query = 1, chunk = i)
					chunkQC = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

					if(IsNaN(chunkQC))
						// no more chunks
						break
					endif

					if(!chunkQC)
						sprintf msg, "Failed due to Baseline QC failure in chunk %d", i
						return msg
					endif
				endfor

				ASSERT(!IsEmpty(msg), "Could not find a failing chunk")
			endif
			break
	endswitch

	return ""
End

/// @brief Show the sweeps of the given `index` entry into the listbox
static Function AD_SelectResult(win, [index])
	string win
	variable index

	string bspPanel, list
	variable numEntries, i

	bspPanel = BSP_GetPanel(win)

	if(ParamIsDefault(index))
		index = GetListBoxSelRow(bspPanel, "list_dashboard")
	endif

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	WAVE/T info = GetAnaFuncDashboardInfoWave(dfr)

	if(!IsFinite(index) || index < 0 || index >= DimSize(info, ROWS))
		return NaN
	endif

	Make/N=0/FREE sweepsWithDuplicates
	if(GetCheckBoxState(bspPanel, "check_BrowserSettings_DB_Passed"))
		list = info[index][%$"Passing Sweeps"]

		if(!IsEmpty(list))
			WAVE wv = ListToNumericWave(list, ";")
			Concatenate/NP {wv}, sweepsWithDuplicates
		endif
	endif

	if(GetCheckBoxState(bspPanel, "check_BrowserSettings_DB_Failed"))
		list = info[index][%$"Failing Sweeps"]

		if(!IsEmpty(list))
			WAVE wv = ListToNumericWave(list, ";")
			Concatenate/NP {wv}, sweepsWithDuplicates
		endif
	endif

	if(IsNull(list))
		print "Select the Passed/Failed checkboxes to display these sweeps"
		ControlWindowToFront()
		return NaN
	endif

	WAVE sweeps = GetUniqueEntries(sweepsWithDuplicates)

	numEntries = DimSize(sweeps, ROWS)

	if(!numEntries)
		WaveClear sweeps
	endif

	if(!GetCheckBoxState(bspPanel,"check_BrowserSettings_OVS"))
		PGC_SetAndActivateControl(bspPanel, "check_BrowserSettings_OVS", val = 1)
	elseif(BSP_IsDataBrowser(win))
		WAVE/T ovsListWave = GetOverlaySweepsListWave(dfr)

		// update databrowser if required and not already done
		WAVE/Z indizes = FindIndizes(ovsListWave, col = 0, var = (numEntries > 0 ? sweeps[numEntries - 1] : -1))
		if(!WaveExists(indizes))
			DB_UpdateToLastSweep(win)
		endif
	endif

	if(!GetCheckBoxState(bspPanel,"check_BrowserSettings_ADC"))
		PGC_SetAndActivateControl(bspPanel, "check_BrowserSettings_ADC", val = 1)
	endif

	if(!GetCheckBoxState(bspPanel,"check_BrowserSettings_DAC"))
		PGC_SetAndActivateControl(bspPanel, "check_BrowserSettings_DAC", val = 1)
	endif

	if(!BSP_IsDataBrowser(win) && WaveExists(sweeps))
		WAVE allSweeps = GetPlainSweepList(win)
		WAVE/Z presentSweeps = GetSetIntersection(allSweeps, sweeps)
		if(!WaveExists(presentSweeps) || EqualWaves(presentSweeps, sweeps, 1) != 1)
			printf "Some requested sweeps can not be displayed, as they are not loaded into this sweepbrowser.\r"
			ControlWindowToFront()
		endif
	endif

	OVS_ChangeSweepSelectionState(win, 1, sweeps = sweeps, invertOthers = 1)
End

Function AD_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	switch(lba.eventCode)
		case 3: // double click
		case 4: // cell selection
			AD_SelectResult(lba.win, index = lba.row)
			break
	endswitch

	return 0
End

Function AD_CheckProc_PassedSweeps(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			AD_SelectResult(cba.win)
			break
	endswitch

	return 0
End

Function AD_CheckProc_FailedSweeps(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			AD_SelectResult(cba.win)
			break
	endswitch

	return 0
End

Function AD_CheckProc_Toggle(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			AD_Update(cba.win)
			break
	endswitch

	return 0
End
