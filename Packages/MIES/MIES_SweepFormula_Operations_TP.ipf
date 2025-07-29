#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_SFOTP
#endif // AUTOMATED_TESTING

// to enable debug mode with more persistent data
// #define SWEEPFORMULA_DEBUG

/// @file MIES_SweepFormula_Operations_TP.ipf
///
/// @brief __SFOTP__ Sweep Formula Operations for TP

static StrConstant SF_OP_TP_TYPE_BASELINE = "base"
static StrConstant SF_OP_TP_TYPE_INSTANT  = "inst"
static StrConstant SF_OP_TP_TYPE_STATIC   = "ss"

static StrConstant SF_OP_TPFIT_FUNC_EXP       = "exp"
static StrConstant SF_OP_TPFIT_FUNC_DEXP      = "doubleexp"
static StrConstant SF_OP_TPFIT_RET_TAULARGE   = "tau"
static StrConstant SF_OP_TPFIT_RET_TAUSMALL   = "tausmall"
static StrConstant SF_OP_TPFIT_RET_AMP        = "amp"
static StrConstant SF_OP_TPFIT_RET_MINAMP     = "minabsamp"
static StrConstant SF_OP_TPFIT_RET_FITQUALITY = "fitq"

// tp(string type[, array selectData[, array ignoreTPs]])
Function/WAVE SFOTP_OperationTP(STRUCT SF_ExecutionData &exd)

	variable numArgs, outType
	string dataType, allowedTypes

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs >= 1 || numArgs <= 3, "tp requires 1 to 3 arguments")

	if(numArgs == 3)
		WAVE ignoreTPs = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_TP, 2, checkExist = 1)
		SFH_ASSERT(WaveDims(ignoreTPs) == 1, "ignoreTPs must be one-dimensional.")
		SFH_ASSERT(IsNumericWave(ignoreTPs), "ignoreTPs parameter must be numeric")
	else
		WAVE/Z ignoreTPs
	endif

	WAVE/Z selectData = SFH_GetArgumentSelect(exd, SF_OP_TP, 1)

	WAVE/WAVE wMode = SF_ResolveDatasetFromJSON(exd, 0)
	dataType = JWN_GetStringFromWaveNote(wMode, SF_META_DATATYPE)

	allowedTypes = AddListItem(SF_DATATYPE_TPSS, "")
	allowedTypes = AddListItem(SF_DATATYPE_TPINST, allowedTypes)
	allowedTypes = AddListItem(SF_DATATYPE_TPBASE, allowedTypes)
	allowedTypes = AddListItem(SF_DATATYPE_TPFIT, allowedTypes)
	SFH_ASSERT(WhichListItem(dataType, allowedTypes) >= 0, "Unknown TP mode.")

	WAVE/Z/WAVE output = SFOTP_OperationTPIterate(exd.graph, wMode, selectData, ignoreTPs, SF_OP_TP)
	if(!WaveExists(output))
		WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, SF_OP_TP, 0)
	endif

	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TP)
	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_TP, ""))

	SF_SetSweepXAxisTickLabels(output, selectData)

	return SFH_GetOutputForExecutor(output, exd.graph, SF_OP_TP)
End

static Function SFOTP_GetTPFitQuality(WAVE residuals, WAVE sweepData, variable beginTrail, variable endTrail)

	variable beginTrailIndex
	variable endTrailIndex

	beginTrailIndex = ScaleToIndex(sweepData, beginTrail, ROWS)
	endTrailIndex   = ScaleToIndex(sweepData, endTrail, ROWS)
	Multithread residuals = residuals[p]^2

	return sum(residuals, beginTrail, endTrail) / (endTrailIndex - beginTrailIndex)
End

static Function/WAVE SFOTP_OperationTPIterate(string graph, WAVE/WAVE mode, WAVE/Z/WAVE selectDataArray, WAVE/Z ignoreTPs, string opShort)

	if(!WaveExists(selectDataArray))
		return $""
	endif

	WAVE/Z/WAVE result = $""

	for(WAVE/Z/WAVE selectDataComp : selectDataArray)

		if(!WaveExists(selectDataComp))
			continue
		endif

		WAVE/Z      selectData = selectDataComp[%SELECTION]
		WAVE/Z/WAVE sweepData  = SFOTP_OperationTPImpl(graph, mode, selectData, ignoreTPs, opShort)
		if(!WaveExists(sweepData))
			continue
		endif

		if(!WaveExists(result))
			WAVE/WAVE result = sweepData
			continue
		endif

		Concatenate/FREE/WAVE/NP {sweepData}, result
	endfor

	return result
End

static Function/WAVE SFOTP_OperationTPImpl(string graph, WAVE/WAVE mode, WAVE/Z selectDataPreFilter, WAVE/Z ignoreTPs, string opShort)

	variable i, j, numSelected, sweepNo, chanNr, chanType, dacChannelNr, settingsIndex, headstage, tpBaseLinePoints, index, err, maxTrailLength
	string unitKey, epShortName, baselineUnit, xAxisLabel, yAxisLabel, debugGraph, dataType
	string fitFunc, retWhat, epBaselineTrail, allowedReturns

	variable numTPs, beginTrail, endTrail, endTrailZero, endTrailIndex, beginTrailIndex, fitResult
	variable debugMode, mapIndex

	STRUCT TPAnalysisInput tpInput
	string epochTPRegExp = "^(U_)?TP[[:digit:]]*$"

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		debugMode = 1
	endif
#endif // DEBUGGING_ENABLED

	WAVE/Z selectData = SFH_FilterSelect(selectDataPreFilter, XOP_CHANNEL_TYPE_ADC)
	if(!WaveExists(selectData))
		return $""
	endif

	dataType = JWN_GetStringFromWaveNote(mode, SF_META_DATATYPE)
	if(!CmpStr(dataType, SF_DATATYPE_TPFIT))
		WAVE/T fitSettingsT = mode[0]
		fitFunc = fitSettingsT[%FITFUNCTION]
		retWhat = fitSettingsT[%RETURNWHAT]
		WAVE fitSettings = mode[1]
		maxTrailLength = fitSettings[%MAXTRAILLENGTH]

		allowedReturns = AddListItem(SF_OP_TPFIT_RET_TAULARGE, "")
		allowedReturns = AddListItem(SF_OP_TPFIT_RET_TAUSMALL, allowedReturns)
		allowedReturns = AddListItem(SF_OP_TPFIT_RET_AMP, allowedReturns)
		allowedReturns = AddListItem(SF_OP_TPFIT_RET_MINAMP, allowedReturns)
		allowedReturns = AddListItem(SF_OP_TPFIT_RET_FITQUALITY, allowedReturns)
		SFH_ASSERT(WhichListItem(retWhat, allowedReturns) >= 0, "Unknown return value requested.")
	endif

	numSelected = DimSize(selectData, ROWS)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numSelected)

	WAVE/Z settings
	for(i = 0; i < numSelected; i += 1)

		sweepNo = selectData[i][%SWEEP]
		if(!IsValidSweepNumber(sweepNo))
			continue
		endif
		chanNr   = selectData[i][%CHANNELNUMBER]
		chanType = selectData[i][%CHANNELTYPE]
		mapIndex = selectData[i][%SWEEPMAPINDEX]
		DFREF sweepDFR
		[WAVE numericalValues, WAVE textualValues, sweepDFR] = SFH_GetLabNoteBooksAndDFForSweep(graph, sweepNo, mapIndex)
		if(!WaveExists(numericalValues) || !WaveExists(textualValues))
			continue
		endif
		SFH_ASSERT(DataFolderExistsDFR(sweepDFR), "Could not determine sweepDFR")

		WAVE/WAVE singleSelect = SFH_GetSingleSelect(graph, opShort, sweepNo, chanType, chanNr, mapIndex)
		WAVE/WAVE sweepDataRef = SFH_GetSweepsForFormula(graph, singleSelect, SF_OP_TP)
		SFH_ASSERT(DimSize(sweepDataRef, ROWS) == 1, "Could not retrieve sweep data for " + num2istr(sweepNo))
		WAVE/Z sweepData = sweepDataRef[0]
		SFH_ASSERT(WaveExists(sweepData), "No sweep data for " + num2istr(sweepNo) + " found.")

		unitKey      = ""
		baselineUnit = ""
		if(chanType == XOP_CHANNEL_TYPE_DAC)
			unitKey = "DA unit"
		elseif(chanType == XOP_CHANNEL_TYPE_ADC)
			unitKey = "AD unit"
		endif
		if(!IsEmpty(unitKey))
			[WAVE settings, settingsIndex] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, unitKey, chanNr, chanType, DATA_ACQUISITION_MODE)
			SFH_ASSERT(WaveExists(settings), "Failed to retrieve channel unit from LBN")
			WAVE/T settingsT = settings
			baselineUnit = settingsT[settingsIndex]
		endif

		headstage = GetHeadstageForChannel(numericalValues, sweepNo, chanType, chanNr, DATA_ACQUISITION_MODE)
		SFH_ASSERT(IsAssociatedChannel(headstage), "Associated headstage must not be NaN")
		[WAVE settings, settingsIndex] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "DAC", chanNr, chanType, DATA_ACQUISITION_MODE)
		SFH_ASSERT(WaveExists(settings), "Failed to retrieve DAC channels from LBN")
		dacChannelNr = settings[headstage]
		SFH_ASSERT(IsFinite(dacChannelNr), "DAC channel number must be finite")

		WAVE/Z epochMatchesAll = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epochTPRegExp, sweepDFR = sweepDFR)

		// drop TPs which should be ignored
		// relies on ascending sorting of start times in epochMatches
		WAVE/Z/T epochMatches = SFOTP_FilterEpochs(epochMatchesAll, ignoreTPs)

		if(!WaveExists(epochMatches))
			continue
		endif

		if(!CmpStr(dataType, SF_DATATYPE_TPFIT))

			if(debugMode)
				JWN_SetNumberInWaveNote(sweepData, SF_META_SWEEPNO, sweepNo)
				JWN_SetNumberInWaveNote(sweepData, SF_META_CHANNELTYPE, chanType)
				JWN_SetNumberInWaveNote(sweepData, SF_META_CHANNELNUMBER, chanNr)
				output[index] = sweepData
				index        += 1
			endif

			numTPs = DimSize(epochMatches, ROWS)
			Make/FREE/D/N=(numTPs) fitResults

#ifdef AUTOMATED_TESTING
			Make/FREE/D/N=(numTPs) beginTrails, endTrails
			beginTrails = NaN
			endTrails   = NaN
#endif // AUTOMATED_TESTING
			for(j = 0; j < numTPs; j += 1)

				epBaselineTrail = EP_GetShortName(epochMatches[j][EPOCH_COL_TAGS]) + "_B1"
				WAVE/Z/T epochTPBaselineTrail = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epBaselineTrail, sweepDFR = sweepDFR)
				SFH_ASSERT(WaveExists(epochTPBaselineTrail) && DimSize(epochTPBaselineTrail, ROWS) == 1, "No TP trailing baseline epoch found for TP epoch")
				WAVE/Z/T nextEpoch = EP_GetNextEpoch(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epBaselineTrail, 1)

				beginTrail   = str2numSafe(epochTPBaselineTrail[0][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
				endTrailZero = str2numSafe(epochTPBaselineTrail[0][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI
				if(WaveExists(nextEpoch) && EP_GetEpochAmplitude(nextEpoch[0][EPOCH_COL_TAGS]) == 0)
					endTrail = str2numSafe(nextEpoch[0][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI
				else
					endTrail = endTrailZero
				endif
				endTrail = min(endTrail, endTrailZero + maxTrailLength)
				SFH_ASSERT(endTrail > beginTrail, "maxTrailLength specified is before TP_B1 start")

#ifdef AUTOMATED_TESTING
				beginTrails[j] = beginTrail
				endTrails[j]   = endTrail
#endif // AUTOMATED_TESTING

				if(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
					Duplicate/FREE sweepData, residuals
				endif

				if(debugMode)
					Duplicate/FREE sweepData, wFitResult
					FastOp wFitResult = (NaN)
					Note/K wFitResult
				endif

				if(!CmpStr(fitFunc, SF_OP_TPFIT_FUNC_EXP))
					Make/FREE/D/N=3 coefWave

					if(debugMode)
						CurveFit/Q/K={beginTrail} exp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail)/D=wFitResult; err = getRTError(1)
						if(!err)
							EnsureLargeEnoughWave(output, indexShouldExist = index)
							output[index] = wFitResult
							index        += 1
							continue
						endif
					else
						fitResult = NaN
						if(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
							CurveFit/Q/K={beginTrail} exp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail)/R=residuals; err = getRTError(1)
							if(!err)
								fitResult = SFOTP_GetTPFitQuality(residuals, sweepData, beginTrail, endTrail)
							endif
						else
							CurveFit/Q/K={beginTrail} exp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail); err = getRTError(1)
						endif
						if(!err)
							if(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAULARGE) || !CmpStr(retWhat, SF_OP_TPFIT_RET_TAUSMALL))
								fitResult = coefWave[2]
							elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_AMP) || !CmpStr(retWhat, SF_OP_TPFIT_RET_MINAMP))
								fitResult = coefWave[1]
							endif
						endif
					endif
				elseif(!CmpStr(fitFunc, SF_OP_TPFIT_FUNC_DEXP))
					Make/FREE/D/N=5 coefWave

					if(debugMode)
						CurveFit/Q/K={beginTrail} dblexp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail)/D=wFitResult; err = getRTError(1)
						if(!err)
							EnsureLargeEnoughWave(output, indexShouldExist = index)
							output[index] = wFitResult
							index        += 1
							continue
						endif
					else
						if(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
							CurveFit/Q/K={beginTrail} dblexp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail)/R=residuals; err = getRTError(1)
							if(!err)
								fitResult = SFOTP_GetTPFitQuality(residuals, sweepData, beginTrail, endTrail)
							endif
						else
							CurveFit/Q/K={beginTrail} dblexp_XOffset, kwCWave=coefWave, sweepData(beginTrail, endTrail); err = getRTError(1)
						endif
						if(!err)
							if(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAULARGE))
								fitResult = max(coefWave[2], coefWave[4])
							elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAUSMALL))
								fitResult = min(coefWave[2], coefWave[4])
							elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_AMP))
								fitResult = (max(abs(coefWave[1]), abs(coefWave[3])) == abs(coefWave[1])) ? coefWave[1] : coefWave[3]
							elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_MINAMP))
								fitResult = (min(abs(coefWave[1]), abs(coefWave[3])) == abs(coefWave[1])) ? coefWave[1] : coefWave[3]
							endif
						endif
					endif
				endif
				fitResults[j] = fitResult
			endfor

			MakeWaveFree($"W_sigma")
			MakeWaveFree($"W_fitConstants")

#ifdef AUTOMATED_TESTING
			JWN_SetWaveInWaveNote(fitResults, "/begintrails", beginTrails)
			JWN_SetWaveInWaveNote(fitResults, "/endtrails", endTrails)
#endif // AUTOMATED_TESTING

			if(!debugMode)
				WAVE/D out = fitResults
				if(!CmpStr(retWhat, SF_OP_TPFIT_RET_AMP) || !CmpStr(retWhat, SF_OP_TPFIT_RET_MINAMP))
					SetScale d, 0, 0, WaveUnits(sweepData, -1), out
				elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAULARGE) || !CmpStr(retWhat, SF_OP_TPFIT_RET_TAUSMALL))
					SetScale d, 0, 0, WaveUnits(sweepData, ROWS), out
				elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
					SetScale d, 0, 0, "", out
				endif
			endif

		else
			// Use first TP as reference for pulse length and baseline
			epShortName = EP_GetShortName(epochMatches[0][EPOCH_COL_TAGS])
			WAVE/Z/T epochTPPulse = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epShortName + "_P", sweepDFR = sweepDFR)
			SFH_ASSERT(WaveExists(epochTPPulse) && DimSize(epochTPPulse, ROWS) == 1, "No TP Pulse epoch found for TP epoch")
			WAVE/Z/T epochTPBaseline = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, dacChannelNr, epShortName + "_B0", sweepDFR = sweepDFR)
			SFH_ASSERT(WaveExists(epochTPBaseline) && DimSize(epochTPBaseline, ROWS) == 1, "No TP Baseline epoch found for TP epoch")
			tpBaseLinePoints = (str2num(epochTPBaseline[0][EPOCH_COL_ENDTIME]) - str2num(epochTPBaseline[0][EPOCH_COL_STARTTIME])) * ONE_TO_MILLI / DimDelta(sweepData, ROWS)

			// Assemble TP data
			WAVE tpInput.data = SFOTP_AverageTPFromSweep(epochMatches, sweepData)
			tpInput.tpLengthPointsADC    = DimSize(tpInput.data, ROWS)
			tpInput.samplingIntervalADC  = DimDelta(tpInput.data, ROWS)
			tpInput.pulseLengthPointsADC = (str2num(epochTPPulse[0][EPOCH_COL_ENDTIME]) - str2num(epochTPPulse[0][EPOCH_COL_STARTTIME])) * ONE_TO_MILLI / DimDelta(sweepData, ROWS)
			tpInput.baselineFrac         = TP_CalculateBaselineFraction(tpInput.pulseLengthPointsADC, tpInput.pulseLengthPointsADC + 2 * tpBaseLinePoints)

			[WAVE settings, settingsIndex] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, CLAMPMODE_ENTRY_KEY, dacChannelNr, XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
			SFH_ASSERT(WaveExists(settings), "Failed to retrieve TP Clamp Mode from LBN")
			tpInput.clampMode = settings[settingsIndex]

			tpInput.clampAmp = NumberByKey("Amplitude", epochTPPulse[0][EPOCH_COL_TAGS], "=")
			SFH_ASSERT(IsFinite(tpInput.clampAmp), "Could not find amplitude entry in epoch tags")

			// values not required for calculation result
			tpInput.device        = graph
			tpInput.sendTPMessage = 0

			DFREF dfrTPAnalysis      = TP_PrepareAnalysisDF(graph, tpInput)
			DFREF dfrTPAnalysisInput = dfrTPAnalysis:input
			DFREF dfr                = TP_TSAnalysis(dfrTPAnalysisInput)
			WAVE  tpOutData          = dfr:tpData

			// handle waves sent out when TP_ANALYSIS_DEBUGGING is defined
			if(WaveExists(dfr:data) && WaveExists(dfr:colors))
				Duplicate/O dfr:data, root:data/WAVE=data
				Duplicate/O dfr:colors, root:colors/WAVE=colors

				debugGraph = "DebugTPRanges"
				if(!WindowExists(debugGraph))
					Display/N=$debugGraph/K=1
					AppendToGraph/W=$debugGraph data
					ModifyGraph/W=$debugGraph zColor(data)={colors, *, *, Rainbow, 1}
				endif
			endif

			strswitch(dataType)
				case SF_DATATYPE_TPSS:
					Make/FREE/D out = {tpOutData[%STEADYSTATERES]}
					SetScale d, 0, 0, "MΩ", out
					break
				case SF_DATATYPE_TPINST:
					Make/FREE/D out = {tpOutData[%INSTANTRES]}
					SetScale d, 0, 0, "MΩ", out
					break
				case SF_DATATYPE_TPBASE:
					Make/FREE/D out = {tpOutData[%BASELINE]}
					SetScale d, 0, 0, baselineUnit, out
					break
				default:
					SFH_FATAL_ERROR("tp: Unknown type.")
					break
			endswitch
		endif

		if(!debugMode)
			JWN_SetWaveInWaveNote(out, SF_META_XVALUES, {sweepNo})
			JWN_SetNumberInWaveNote(out, SF_META_SWEEPNO, sweepNo)
			JWN_SetNumberInWaveNote(out, SF_META_CHANNELTYPE, chanType)
			JWN_SetNumberInWaveNote(out, SF_META_CHANNELNUMBER, chanNr)

			output[index] = out
			index        += 1
		endif
	endfor
	if(!index)
		return $""
	endif
	Redimension/N=(index) output

	if(debugMode)
		return output
	endif

	strswitch(dataType)
		case SF_DATATYPE_TPSS:
			yAxisLabel = "steady state resistance"
			break
		case SF_DATATYPE_TPINST:
			yAxisLabel = "instantaneous resistance"
			break
		case SF_DATATYPE_TPBASE:
			yAxisLabel = "baseline level"
			break
		case SF_DATATYPE_TPFIT:
			if(!CmpStr(retWhat, SF_OP_TPFIT_RET_TAULARGE) || !CmpStr(retWhat, SF_OP_TPFIT_RET_TAUSMALL))
				yAxisLabel = "tau"
			elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_AMP) || !CmpStr(retWhat, SF_OP_TPFIT_RET_MINAMP))
				yAxisLabel = ""
			elseif(!CmpStr(retWhat, SF_OP_TPFIT_RET_FITQUALITY))
				yAxisLabel = "fitQuality"
			endif
			break
		default:
			SFH_FATAL_ERROR("tp: Unknown mode.")
			break
	endswitch

	xAxisLabel = "Sweeps"

	JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, xAxisLabel)
	JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, yAxisLabel)

	return output
End

// tpbase()
Function/WAVE SFOTP_OperationTPBase(STRUCT SF_ExecutionData &exd)

	variable numArgs, outType
	string opShort = SF_OP_TPBASE

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs == 0, "tpbase has no arguments")

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, 0)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TPBASE)

	return SFH_GetOutputForExecutor(output, exd.graph, opShort)
End

// tpfit()
Function/WAVE SFOTP_OperationTPFit(STRUCT SF_ExecutionData &exd)

	variable numArgs, outType
	string func, retVal
	variable maxTrailLength
	string opShort = SF_OP_TPFIT

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs >= 2 && numArgs <= 3, "tpfit has two or three arguments")

	WAVE/T wFitType = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_TPFIT, 0, checkExist = 1)
	SFH_ASSERT(IsTextWave(wFitType), "TPFit function argument must be textual.")
	SFH_ASSERT(DimSize(wFitType, ROWS) == 1, "TPFit function argument must be a single string.")
	func = wFitType[0]
	SFH_ASSERT(!CmpStr(func, SF_OP_TPFIT_FUNC_EXP) || !CmpStr(func, SF_OP_TPFIT_FUNC_DEXP), "Fit function must be exp or doubleexp")

	WAVE/T wReturn = SFH_ResolveDatasetElementFromJSON(exd, SF_OP_TPFIT, 1, checkExist = 1)
	SFH_ASSERT(IsTextWave(wReturn), "TPFit return what argument must be textual.")
	SFH_ASSERT(DimSize(wReturn, ROWS) == 1, "TPFit return what argument must be a single string.")
	retVal = wReturn[0]
	SFH_ASSERT(!CmpStr(retVal, SF_OP_TPFIT_RET_TAULARGE) || !CmpStr(retVal, SF_OP_TPFIT_RET_TAUSMALL) || !CmpStr(retVal, SF_OP_TPFIT_RET_AMP) || !CmpStr(retVal, SF_OP_TPFIT_RET_MINAMP) || !CmpStr(retVal, SF_OP_TPFIT_RET_FITQUALITY), "TP fit result must be tau, tausmall, amp, minabsamp, fitq")

	maxTrailLength = SFH_GetArgumentAsNumeric(exd, SF_OP_TPFIT, 2, defValue = 250)

	Make/FREE/T fitSettingsT = {func, retVal}
	SetDimLabel ROWS, 0, FITFUNCTION, fitSettingsT
	SetDimLabel ROWS, 1, RETURNWHAT, fitSettingsT
	Make/FREE/D fitSettings = {maxTrailLength}
	SetDimLabel ROWS, 0, MAXTRAILLENGTH, fitSettings

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, 2)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TPFIT)

	output[0] = fitSettingsT
	output[1] = fitSettings

	return SFH_GetOutputForExecutor(output, exd.graph, opShort)
End

// tpinst()
Function/WAVE SFOTP_OperationTPInst(STRUCT SF_ExecutionData &exd)

	variable numArgs, outType
	string opShort = SF_OP_TPINST

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs == 0, "tpinst has no arguments")

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, 0)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TPINST)

	return SFH_GetOutputForExecutor(output, exd.graph, opShort)
End

// tpss()
Function/WAVE SFOTP_OperationTPSS(STRUCT SF_ExecutionData &exd)

	variable numArgs, outType
	string opShort = SF_OP_TPSS

	numArgs = SFH_GetNumberOfArguments(exd)
	SFH_ASSERT(numArgs == 0, "tpss has no arguments")

	WAVE/WAVE output = SFH_CreateSFRefWave(exd.graph, opShort, 0)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_TPSS)

	return SFH_GetOutputForExecutor(output, exd.graph, opShort)
End

static Function/WAVE SFOTP_FilterEpochs(WAVE/Z epochs, WAVE/Z ignoreTPs)

	variable i, numEntries, index

	if(!WaveExists(epochs))
		return $""
	elseif(!WaveExists(ignoreTPs))
		return epochs
	endif

	// descending sort
	SortColumns/KNDX={0}/R sortWaves={ignoreTPs}

	numEntries = DimSize(ignoreTPs, ROWS)
	for(i = 0; i < numEntries; i += 1)
		index = ignoreTPs[i]
		SFH_ASSERT(IsFinite(index), "ignored TP index is non-finite")
		SFH_ASSERT(index >= 0 && index < DimSize(epochs, ROWS), "ignored TP index is out of range")
		DeletePoints/M=(ROWS) index, 1, epochs
	endfor

	if(DimSize(epochs, ROWS) == 0)
		return $""
	endif

	return epochs
End

static Function/WAVE SFOTP_AverageTPFromSweep(WAVE/T epochMatches, WAVE sweepData)

	variable numTPEpochs, tpDataSizeMin, tpDataSizeMax, sweepDelta

	numTPEpochs = DimSize(epochMatches, ROWS)
	sweepDelta  = DimDelta(sweepData, ROWS)
	Make/FREE/D/N=(numTPEpochs) tpStart = trunc(str2num(epochMatches[p][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI / sweepDelta)
	Make/FREE/D/N=(numTPEpochs) tpDelta = trunc(str2num(epochMatches[p][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI / sweepDelta) - tpStart[p]
	[tpDataSizeMin, tpDataSizeMax] = WaveMinAndMax(tpDelta)
	SFH_ASSERT((tpDataSizeMax - tpDataSizeMin) <= 1, "TP data size from TP epochs mismatch within sweep.")

	Make/FREE/D/N=(tpDataSizeMin) tpData
	CopyScales/P sweepData, tpData
	tpDelta = SFOTP_AverageTPFromSweepImpl(tpData, tpStart, sweepData, p)
	if(numTPEpochs > 1)
		MultiThread tpData /= numTPEpochs
	endif

	return tpData
End

static Function SFOTP_AverageTPFromSweepImpl(WAVE tpData, WAVE tpStart, WAVE sweepData, variable i)

	MultiThread tpData += sweepData[tpStart[i] + p]
End
