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

	string win, panelList
	variable i, numEntries

	panelList = WinList("DB_*", ";", "WIN:1")
	numEntries = ItemsInList(panelList)

	for(i = 0; i < numEntries; i += 1)
		win = StringFromList(i, panelList)
		AD_Update(win)
	endfor
End

/// @brief Update the dashboards of the given databrowser
Function AD_Update(win)
	string win

	string device, mainPanel
	variable numEntries, refTime

	refTime = DEBUG_TIMER_START()

	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	WAVE colorWave  = GetAnaFuncDashboardColorWave(dfr)
	WAVE selWave    = GetAnaFuncDashboardselWave(dfr)
	WAVE/T listWave = GetAnaFuncDashboardListWave(dfr)
	WAVE/T infoWave = GetAnaFuncDashboardInfoWave(dfr)

	device = BSP_GetDevice(win)
	numEntries = AD_FillWaves(device, listWave, infoWave)
	Redimension/N=(numEntries, -1, -1) selWave, listWave, infoWave

	if(numEntries > 0)
		selWave[][][%foreColors] = cmpstr(listWave[p][%Result], "Pass") == 0 ? 2 : 1

		mainPanel = BSP_GetPanel(win)
		EnableControls(mainPanel, "list_dashboard;check_BrowserSettings_DB_Failed;check_BrowserSettings_DB_Passed")
	endif

	DEBUGPRINT_ELAPSED(refTime)
End

/// @brief Get result list of analysis function runs
static Function AD_FillWaves(panelTitle, list, info)
	string panelTitle
	WAVE/T list, info

	variable lastSweep, i, j, headstage, passed, sweepNo, numEntries
	variable index, anaFuncType, stimsetCycleID, firstValid, lastValid
	string key, anaFunc, stimset, msg

	lastSweep = AFH_GetLastSweepAcquired(panelTitle)

	if(isNan(lastSweep))
		return 0
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues   = GetLBTextualValues(panelTitle)

	index = GetNumberFromWaveNote(list, NOTE_INDEX)

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/Z sweepsWithGenericFunc = GetSweepsWithSetting(textualValues, key)

	if(!WaveExists(sweepsWithGenericFunc))
		return 0
	endif

	numEntries = DimSize(sweepsWithGenericFunc, ROWS)
	for(i = 0; i < numEntries; i += 1)

		sweepNo = sweepsWithGenericFunc[i]

		key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
		WAVE/Z/T anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)

		if(!WaveExists(anaFuncs))
			continue
		endif

		Make/N=(LABNOTEBOOK_LAYER_COUNT)/FREE anaFuncTypes = MapAnaFuncToConstant(anaFuncs[p])

		if(!HasOneValidEntry(anaFuncTypes))
			continue
		endif

		WAVE/Z headstages = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)

		// present since 602debb9 (Record the active headstage in the settingsHistory, 2014-11-04)
		if(!WaveExists(headstages))
			continue
		endif

		for(j = 0; j < NUM_HEADSTAGES; j += 1)

			headstage = j

			if(IsNaN(headstages[headstage]))
				continue
			endif

			anaFuncType = anaFuncTypes[headstage]
			anaFunc = anaFuncs[headstage]

			if(IsNaN(anaFuncType)) // unsupported analysis function
				continue
			endif

			WAVE/Z stimsetCycleIDs = GetLastSetting(numericalValues, sweepNo, STIMSET_ACQ_CYCLE_ID_KEY, DATA_ACQUISITION_MODE)

			if(!WaveExists(stimsetCycleIDs)) // TP during DAQ
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

			key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SET_PASS, query = 1)
			passed = GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

			if(isNaN(passed))
				// the set is not yet finished
				continue
			endif

			if(passed)
				msg = "Pass"
			else
				anaFuncType = MapAnaFuncToConstant(anaFunc)
				ASSERT(IsFinite(anaFuncType), "Invalid analysis function type")

				// PSQ_DA, PSQ_RB, PSQ_RA, PSQ_SP
				// PSQ_FMT_LBN_BL_QC_PASS

				// MSQ_DA
				// - always passes

				// MSQ_FRE
				// - MSQ_FMT_LBN_DASCALE_EXC present (optional)
				// - Not enough sweeps

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
						msg = "Failure"
						break
					case MSQ_FAST_RHEO_EST:
						msg = AD_GetFastRheoEst(numericalValues, sweepNo, headstage)
						break
					case PSQ_DA_SCALE:
						msg = AD_GetDaScaleFailMsg(numericalValues, textualValues, sweepNo, headstage)
						break
					case PSQ_RAMP:
						msg = AD_GetRampFailMsg(numericalValues, sweepNo, headstage)
						break
					case PSQ_RHEOBASE:
						msg = AD_GetRheobaseFailMsg(numericalValues, sweepNo, headstage)
						break
					case PSQ_SQUARE_PULSE:
						msg = AD_GetSquarePulseFailMsg(numericalValues, sweepNo, headstage)
						break
					default:
						ASSERT(0, "Unsupported analysis function")
				endswitch
			endif

			EnsureLargeEnoughWave(list, dimension = ROWS, minimumSize = index)
			EnsureLargeEnoughWave(info, dimension = ROWS, minimumSize = index)

			list[index][0] = stimset
			list[index][1] = anaFunc
			list[index][2] = msg

			// get the passing/failing sweeps
			// PSQ_DA PSQ_RA, PSQ_SP, MSQ_DA, MSQ_FRE: use PSQ_FMT_LBN_SWEEP_PASS
			// PSQ_RB: If passed use last spiking/non-spiking duo
			//     If not passed, all are failing

			WAVE sweeps = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

			switch(anaFuncType)
				case PSQ_DA_SCALE:
				case PSQ_RAMP:
				case PSQ_SQUARE_PULSE:
				case MSQ_DA_SCALE:
				case MSQ_FAST_RHEO_EST:
					key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
					WAVE sweepPass = GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
					ASSERT(DimSize(sweeps, ROWS) == DimSize(sweepPass, ROWS), "Unexpected wave sizes")

					Duplicate/FREE sweeps, passingSweeps, failingSweeps
					passingSweeps[] = sweepPass[p]  ? sweeps[p] : NaN
					failingSweeps[] = !sweepPass[p] ? sweeps[p] : NaN

					WaveTransform/O zapNaNs, passingSweeps
					WaveTransform/O zapNaNs, failingSweeps

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
						Make/FREE/N=0 passingSweeps
					endif
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
		WaveTransform/O zapNaNs, spikeWithDAScaleZero
		if(DimSize(spikeWithDAScaleZero, ROWS) == 3)
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
	WaveTransform/O zapNaNs, daScaleExc

	if(Sum(daScaleExc) > 0)
		return "Max DA scale exceeded failure"
	endif

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_RB_LIMITED_RES, query = 1)
	WAVE/Z limitedResolution = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	ASSERT(WaveExists(limitedResolution), "Missing limited resolution labnotebook entry")
	WaveTransform/O zapNaNs, limitedResolution

	if(Sum(limitedResolution) > 0)
		return "Failure due to limited resolution"
	endif

	key = CreateAnaFuncLBNKey(PSQ_RHEOBASE, PSQ_FMT_LBN_SPIKE_DETECT, query = 1)
	WAVE/Z spikeDetect = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	sprintf msg, "Failure as we were not able to find the correct on/off spike pattern (%s)", RemoveEnding(NumericWaveToList(spikeDetect, ", ", format="%g"), ", ")
	return msg
End

static Function/S AD_GetFastRheoEst(WAVE numericalValues, variable sweepNo, variable headstage)

	string key

	key = CreateAnaFuncLBNKey(MSQ_FAST_RHEO_EST, MSQ_FMT_LBN_DASCALE_EXC, query = 1)
	WAVE/Z daScaleExc = GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)

	if(WaveExists(daScaleExc))
		WaveTransform/O zapNaNs, daScaleExc
		if(Sum(daScaleExc) > 0)
			return "Max DA scale exceeded failure"
		endif
	endif

	return "Failure as we ran out of sweeps"
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
			key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_BL_QC_PASS, query = 1)
			WAVE/Z baselineQC = GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
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

	Make/D/N=0/FREE sweeps
	if(GetCheckBoxState(bspPanel, "check_BrowserSettings_DB_Passed"))
		list = info[index][%$"Passing Sweeps"]

		if(!IsEmpty(list))
			WAVE wv = ListToNumericWave(list, ";")
			Concatenate/NP {wv}, sweeps
		endif
	endif

	if(GetCheckBoxState(bspPanel, "check_BrowserSettings_DB_Failed"))
		list = info[index][%$"Failing Sweeps"]

		if(!IsEmpty(list))
			WAVE wv = ListToNumericWave(list, ";")
			Concatenate/NP {wv}, sweeps
		endif
	endif

	numEntries = DimSize(sweeps, ROWS)

	WAVE/T ovsListWave = GetOverlaySweepsListWave(dfr)
	WAVE ovsSelWave    = GetOverlaySweepsListSelWave(dfr)

	if(!GetCheckBoxState(bspPanel,"check_BrowserSettings_OVS"))
		PGC_SetAndActivateControl(bspPanel, "check_BrowserSettings_OVS", val = 1)
	else
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

	ovsSelWave[][%$"Sweep"] = ClearBit(ovsSelWave[p][%$"Sweep"], LISTBOX_CHECKBOX_SELECTED)

	for(i = 0; i < numEntries;i += 1)
		WAVE/Z indizes = FindIndizes(ovsListWave, col = 0, var = sweeps[i])
		ASSERT(WaveExists(indizes), "Could not find sweep")
		ASSERT(DimSize(indizes, ROWS) == 1, "Invalid number of matches")
		ovsSelWave[indizes[0]][%$"Sweep"] = SetBit(ovsSelWave[indizes[0]][%$"Sweep"], LISTBOX_CHECKBOX_SELECTED)
	endfor

	UpdateSweepPlot(win)
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
