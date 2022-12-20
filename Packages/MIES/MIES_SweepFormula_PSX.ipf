#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PSX
#endif

/// @file MIES_SweepFormula_PSX.ipf
///
/// @brief __PSX__ Sweep formula related code for PSP/PSC (-> PSX) detection and classification
///
/// GUI layout
///
/// @verbatim
///
/// +---+-----------+-----------+
/// |   | All event | Single    |
/// |   | graph     | event     |
/// |   |           | graph     |
/// |   |           |           |
/// +------+-------------------------------+
/// |      |  PSX graph                    |
/// |      |                               |
/// |      |-------------------------------|
/// |      |  PSX stats graph              |
/// |      |                               |
/// |      |-------------------------------|
/// |      | ...                           |
/// +------+-------------------------------+
///
/// @endverbatim
///
/// Related functions:
/// - PSX_GetSpecialPanel()
/// - PSX_GetAllEventGraph()
/// - PSX_GetSingleEventGraph()
/// - PSX_GetPSXGraph()
///
/// To find the sweep/data browser use SFH_GetBrowserForFormulaGraph() and for the reverse direction use SFH_GetFormulaGraphForBrowser.

static Constant PSX_DEFAULT_FILTER_HIGH = 0   // [Hz]
static Constant PSX_DEFAULT_FILTER_LOW  = 550 // [Hz]

static Constant PSX_COLOR_ACCEPT_R = 0
static Constant PSX_COLOR_ACCEPT_G = 65535
static Constant PSX_COLOR_ACCEPT_B = 0

static Constant PSX_COLOR_REJECT_R = 65535
static Constant PSX_COLOR_REJECT_G = 0
static Constant PSX_COLOR_REJECT_B = 0

static Constant PSX_COLOR_UNDET_R = 48059
static Constant PSX_COLOR_UNDET_G = 48059
static Constant PSX_COLOR_UNDET_B = 48059

static Constant PSX_KEYBOARD_DIR_RL = 0
static Constant PSX_KEYBOARD_DIR_LR = 1

static Constant PSX_NUM_PEAKS_MAX = 2000

static Constant PSX_PLOT_DEFAULT_X_RANGE = 200

static Constant PSX_DEFAULT_DECAY_FIT_LENGTH = 30
static Constant PSX_DEFAULT_X_START_OFFSET = 2

static StrConstant USER_DATA_KEYBOARD_DIR = "keyboard_direction"

static StrConstant PSX_USER_DATA_WORKING_FOLDER = "psxFolder"

static StrConstant PSX_X_DATA_UNIT = "X_DATA_UNIT"
static StrConstant PSX_Y_DATA_UNIT = "Y_DATA_UNIT"

static StrConstant PSX_EVENT_DIMENSION_LABELS = "sweepData;sweepDataFiltOff;sweepDataFiltOffDeconv;peakX;peakY;psxEvent;eventFit"

static Constant PSX_KERNEL_OUTPUTWAVES_PER_ENTRY     = 3
static Constant PSX_OPERATION_OUTPUT_WAVES_PER_ENTRY = 7

static StrConstant PSX_SPECIAL_EVENT_PANEL    = "SpecialEventPanel"
static StrConstant PSX_SINGLE_EVENT_SUB_GRAPH = "Single"
static StrConstant PSX_ALL_EVENT_SUB_GRAPH    = "All"

static StrConstant PSX_CURSOR_TRACE = "peakY"

static StrConstant PSX_USER_DATA_TYPE = "type"
static StrConstant PSX_USER_DATA_PSX = "PSX"

static StrConstant PSX_JWN_COMBO_KEYS_NAME = "ComboKeys"
static StrConstant PSX_JWN_PARAMETERS      = "Parameters"
static StrConstant PSX_JWN_STATS_POST_PROC = "PostProcessing"

static StrConstant PSX_TUD_EVENT_INDEX_KEY  = "eventIndex"

/// @name State types
/// @anchor SpecialEventPanelEventTypes
/// @{
static StrConstant PSX_TUD_FIT_STATE_KEY    = "Fit State"
static StrConstant PSX_TUD_EVENT_STATE_KEY  = "Event State"
/// @}
///
static StrConstant PSX_TUD_TRACE_HIDDEN_KEY = "traceHidden"
static StrConstant PSX_TUD_TYPE_KEY         = "type"

/// @name Trace types
/// @anchor AllEventGraphTraceType
/// @{
static StrConstant PSX_TUD_TYPE_SINGLE      = "single"
static StrConstant PSX_TUD_TYPE_AVERAGE     = "average"
/// @}

static StrConstant PSX_TUD_COMBO_KEY        = "comboKey"
static StrConstant PSX_TUD_COMBO_INDEX      = "comboIndex"

static Constant PSX_GUI_SETTINGS_VERSION = 1

static StrConstant PSX_GUI_SETTINGS_PSX = "GuiSettingsPSX"

static Constant PSX_MAX_NUM_EVENTS = 1e6

static StrConstant PSX_GLOBAL_AVERAGE_SUFFIX     = "_global"
static StrConstant PSX_TUD_AVERAGE_ALL_COMBO_KEY = "allCombos"
static Constant PSX_TUD_AVERAGE_ALL_COMBO_INDEX  = NaN

static Constant PSX_DEFAULT_PEAK_SEARCH_RANGE_MS = 5

Menu "GraphMarquee"
	"PSX: Accept Event && Fit", /Q, PSX_MouseEventSelection(PSX_ACCEPT, PSX_STATE_EVENT | PSX_STATE_FIT)
	"PSX: Reject Event && Fit", /Q, PSX_MouseEventSelection(PSX_REJECT, PSX_STATE_EVENT | PSX_STATE_FIT)
	"PSX: Accept Fit", /Q, PSX_MouseEventSelection(PSX_ACCEPT, PSX_STATE_FIT)
	"PSX: Reject Fit", /Q, PSX_MouseEventSelection(PSX_REJECT, PSX_STATE_FIT)
	"PSX: Jump to Events", /Q, PSX_JumpToEvents()
End

static Function/S PSX_GetUserDataForWorkingFolder()
	return PSX_USER_DATA_WORKING_FOLDER
End

/// @brief Return the working folder for the `psx` operation
///
/// Can be null in case the operation was not executed in this sweep formula panel
static Function/DF PSX_GetWorkingFolder(string win)

	string mainWindow = GetMainWindow(win)

	return $GetUserData(mainWindow, "", PSX_USER_DATA_WORKING_FOLDER)
End

static Function/S PSX_GetSpecialPanel(string win)

	return GetMainWindow(win) + "#" + PSX_SPECIAL_EVENT_PANEL
End

static Function/S PSX_GetSingleEventGraph(string win)

	return PSX_GetSpecialPanel(win) + "#" + PSX_SINGLE_EVENT_SUB_GRAPH
End

static Function/S PSX_GetAllEventGraph(string win)

	return PSX_GetSpecialPanel(win) + "#" + PSX_ALL_EVENT_SUB_GRAPH
End

/// @brief Return a wave with the checkbox states, single or average, of the special event panel
///
/// Can be indexed with the state as dimension label.
///
/// @param win windows
/// @param traceType One of @ref AllEventGraphTraceType
static Function/WAVE PSX_GetCheckboxStatesFromSpecialPanel(string win, string traceType)

	string specialEventPanel, ctrlPrefix
	variable last

	WAVE states = PSX_GetStates(withAllState = 1)
	Make/FREE/N=(DimSize(states, ROWS))/T lbls = PSX_StateToString(states[p])
	SetDimensionLabels(states, TextWaveToList(lbls, ";"), ROWS)

	strswitch(traceType)
		case PSX_TUD_TYPE_AVERAGE:
			ctrlPrefix = "checkbox_average_events_"
			last = DimSize(states, ROWS) - 1
			break
		case PSX_TUD_TYPE_SINGLE:
			ctrlPrefix = "checkbox_single_events_"
			states[%all] = 0
			last = DimSize(states, ROWS) - 2
			break
	endswitch

	specialEventPanel = PSX_GetSpecialPanel(win)
	states[,last] = GetCheckboxState(specialEventPanel, ctrlPrefix + lbls[p])

	return states
End

/// @brief Return the state type (fit or event) state from the special event panel
///
/// @brief One of @ref SpecialEventPanelEventTypes
static Function/S PSX_GetStateTypeFromSpecialPanel(string win)

	string specialEventPanel

	specialEventPanel = PSX_GetSpecialPanel(win)
	return GetPopupMenuString(specialEventPanel, "popupmenu_state_type")
End

static Function PSX_GetRestrictEventsToCurrentCombo(string win)

	string specialEventPanel

	specialEventPanel = PSX_GetSpecialPanel(win)
	return GetCheckBoxState(specialEventPanel, "checkbox_restrict_events_to_current_combination")
End

/// @brief Filter the sweep data
///
/// @param sweepData data from a single sweep and channel *without* inserted TP
/// @param high      high cutoff [Hz]
/// @param low       low cutoff [Hz]
static Function/WAVE PSX_FilterSweepData(WAVE sweepData, variable low, variable high)

	variable samp, err

	samp = 1 / (deltax(sweepData) * MILLI_TO_ONE)

	ASSERT(low > high, "Expected a band pass filter with low > high")

	Duplicate/FREE sweepData, filtered

	FilterIIR/ENDV=(filtered[0])/LO=(low / samp)/HI=(high / samp)/DIM=(ROWS) filtered; err = GetRTError(1)
	SFH_ASSERT(!err, "Error filtering the data, msg: " + GetErrMessage(err))

	return filtered
End

/// @brief Create a histogram of the sweep data
///
/// @param sweepData data from a single sweep and channel *without* inserted TP
/// @param bin_start [optional, defaults to data's minimum] first histogram bin
/// @param bin_end   [optional, defaults to data's maximum] last histogram bin
/// @param bin_width [optional, defaults to 0.1] width of a histogram bin
static Function/WAVE PSX_CreateHistogram(WAVE sweepData, [variable bin_start, variable bin_end, variable bin_width])

	variable minimum, maximum, n_bins, err

	[minimum, maximum] = WaveMinAndMax(sweepData)

	if(ParamIsDefault(bin_start))
		bin_start = floor(minimum)
	endif

	if(ParamIsDefault(bin_end))
		bin_end = ceil(maximum)
	endif

	if(ParamIsDefault(bin_width))
		bin_width = 0.1
	endif

	n_bins = ceil((bin_end - bin_start) / bin_width)

	AssertOnAndClearRTError()
	Make/FREE/R/N=0 output
	Histogram/B={bin_start, bin_width, n_bins}/DEST=output sweepData; err = GetRTError(1)

	if(err)
		return $""
	endif

	return output
end

/// @brief Offset sweepData by X
///
/// X is calculated as the x coordinate of histogram's maximum taken of sweepData.
///
/// The result is that the histogram maximum of the offsetted trace is at zero.
static Function [WAVE sweepDataOff, variable offset] PSX_OffsetSweepData(WAVE sweepData)

	WAVE/Z hist = PSX_CreateHistogram(sweepData)

	if(!WaveExists(hist))
		return [$"", NaN]
	endif

	WaveStats/Q/M=1 hist
	offset = V_maxLoc

	Duplicate/FREE sweepData, output
	output -= offset

	return [output, offset]
End

/// @brief Return the deconvoluted sweep data
///
/// @param sweepData data from a single sweep and channel *without* inserted TP
/// @param psxKernelFFT FFT'ed kernel from PSX_CreatePSXKernel()
static Function/WAVE PSX_DeconvoluteSweepData(WAVE sweepData, WAVE/C psxKernelFFT)

	variable numPoints, fftSize

	numPoints = DimSize(sweepData, ROWS)
	fftSize = DimSize(psxKernelFFT, ROWS)

	// no window function on purpose
	WAVE/C outputFFT = DoFFT(sweepData, padSize = numPoints)

	Multithread outputFFT[] = outputFFT[p] / psxKernelFFT[p]

	IFFT/DEST=Deconv/FREE outputFFT

	FindValue/UOFV/FNAN Deconv
	ASSERT(V_Value == -1, "Can not handle NaN in the deconvoluted wave")

	CopyScales sweepData, Deconv

	FilterFIR/ENDV={3}/LO={0.002, 0.004, 101} Deconv

	return Deconv
end

/// @brief Creates a histogram of the deconvoluted sweep data
static function/WAVE PSX_CreateHistogramOfDeconvSweepData(WAVE deconvSweepData, [variable bin_start, variable bin_end, variable bin_width])

	variable n_bins, tmp

	StatsQuantiles/Q deconvSweepData

	variable q75 = V_Q75

	if(ParamIsDefault(bin_start))
		bin_start = q75 * -3
	endif

	if(ParamIsDefault(bin_end))
		bin_end = q75 * 3
	endif

	if(ParamIsDefault(bin_width))
		bin_width = 0.0005
	endif

	if(bin_start > bin_end)
		tmp = bin_end
		bin_end = bin_start
		bin_start = tmp
	endif

	n_bins = ceil((bin_end - bin_start) / bin_width)

	SFH_ASSERT(n_bins > 1, "Histogram creation failed due to too few data points")

	Make/FREE/N=0 hist
	Histogram/B={bin_start, bin_width, n_bins}/DEST=hist deconvSweepData

	return hist
end

/// Fit the given wave with a gaussian where K0, y offset, is fixed at zero.
static Function/WAVE PSX_FitHistogram(WAVE input)

	Make/D/FREE/N=4 coefWave
	K0 = 0
	CurveFit/H="1000"/Q gauss, kwCWave=coefWave, input/D

	return coefWave
end

/// Full analysis cycle:
/// - filtering
/// - offsetting
/// - deconvolution
/// - histogram of deconvolution
/// - gaussian fit of histogram
static Function [WAVE sweepDataFiltOff, WAVE sweepDataFiltOffDeconv] PSX_Analysis(WAVE sweepData, WAVE selectData, WAVE psxKernelFFT, variable filterLow, variable filterHigh, variable index, WAVE psxAnalysis)

	variable offset, sweepNo

	WAVE sweepDataFilt = PSX_FilterSweepData(sweepData, filterLow, filterHigh)

	WAVE/ZZ sweepDataFiltOff
	[sweepDataFiltOff, offset] = PSX_OffsetSweepData(sweepDataFilt)

	if(!WaveExists(sweepDataFiltOff))
		return [$"", $""]
	endif

	WAVE sweepDataFiltOffDeconv = PSX_DeconvoluteSweepData(sweepDataFiltOff, psxKernelFFT)

	WAVE hist = PSX_CreateHistogramOfDeconvSweepData(sweepDataFiltOffDeconv)

	WAVE fitCoefWave = PSX_FitHistogram(hist)

	sweepNo = selectData[0][%SWEEP]

	SetDimLabel ROWS, index, $("SWEEP_" + num2str(sweepNo)), psxAnalysis
	psxAnalysis[index][%sweep]    = sweepNo
	psxAnalysis[index][%sigma]    = fitCoefWave[3]
	psxAnalysis[index][%baseline] = offset

	return [sweepDataFiltOff, sweepDataFiltOffDeconv]
end

/// Searches for peaks in sweepData
///
/// @param sweepDataFiltOffDeconv 1D wave
/// @param threshold              FindPeak parameter
/// @param numPeaksMax            maximum number of peaks to search
/// @param start                  [optional, defaults first point] start x value
/// @param stop                   [optional, defaults last point] end x value
///
/// @retval peakX x-coordinates of peaks
/// @retval peakY y-coordinates of peaks
static function [WAVE/D peakX, WAVE/D peakY] PSX_FindPeaks(WAVE sweepDataFiltOffDeconv, variable threshold, [variable numPeaksMax, variable start, variable stop])

	variable i

	if(ParamIsDefault(numPeaksMax))
		numPeaksMax = PSX_NUM_PEAKS_MAX
	endif

	if(ParamIsDefault(start))
		start = leftx(sweepDataFiltOffDeconv)
	endif

	if(ParamIsDefault(stop))
		stop = rightx(sweepDataFiltOffDeconv)
	endif

	Make/FREE/D/N=(numPeaksMax) peakX, peakY

	for(i = 0; i < numPeaksMax; i += 1)
		FindPeak/B=10/M=(threshold)/Q/R=(start,stop) sweepDataFiltOffDeconv

		if(V_Flag != 0)
			break
		elseif(IsNaN(V_TrailingEdgeLoc))
			break
		endif

		peakX[i] = V_peakLoc
		peakY[i] = V_PeakVal

		start = V_TrailingEdgeLoc
	endfor

	if(i == 0)
		return [$"", $""]
	endif

	Redimension/N=(i) peakX, peakY

	return [peakX, peakY]
end

/// @brief Analyze the peaks
static Function PSX_AnalyzePeaks(WAVE sweepDataFiltOffDeconv, WAVE sweepDataFiltOff, WAVE peakX, WAVE peakY, variable kernelAmp, variable index, WAVE psxAnalysis, WAVE psxEvent, WAVE eventFit)

	variable i, i_time, h_time, i_amp, dc_amp, dc_peak_t, isi, i_peak, i_peak_t, pre_min, pre_min_t, numCrossings
	variable avg_amp, avg_isi, peak_end_search

	numCrossings = DimSize(peakX, ROWS)
	for(i = 0; i < numCrossings; i += 1)

		i_time = peakX[i]
		dc_amp = peakY[i]

		if(i < numCrossings - 1)
			peak_end_search = min(i_time + PSX_DEFAULT_PEAK_SEARCH_RANGE_MS, peakX[i + 1])
		else
			peak_end_search = i_time + PSX_DEFAULT_PEAK_SEARCH_RANGE_MS
		endif

		WaveStats/M=1/Q/R=(i_time, peak_end_search) sweepDataFiltOff

		if(kernelAmp > 0)
			i_peak   = V_max
			i_peak_t = V_maxloc
		elseif(kernelAmp < 0)
			i_peak   = V_min
			i_peak_t = V_minloc
		else
			ASSERT(0, "Can't handle kernelAmp of zero")
		endif

		EnsureLargeEnoughWave(psxEvent, indexShouldExist = i)

		psxEvent[i][%i_peak] = i_peak
		psxEvent[i][%i_peak_t] = i_peak_t

		if(i == 0)
			isi = NaN
			h_time = NaN
			pre_min = NaN
			pre_min_t = NaN
		else
			h_time = peakX[i - 1] // previous event's time of peak
			isi = i_time - h_time
			h_time = psxEvent[i - 1][3] // update previous events time to be time of i peak
			WaveStats/Q/R=(i_time - 2, i_time) sweepDataFiltOff
			pre_min = V_max
			pre_min_t = V_maxloc
			WaveStats/Q/R=(pre_min_t - 0.1, pre_min_t + 0.1) sweepDataFiltOff
			pre_min = V_avg
		endif

		psxEvent[i][%index] = i
		psxEvent[i][%dc_peak_time] = i_time
		psxEvent[i][%dc_amp] = dc_amp

		psxEvent[i][%pre_min] = pre_min
		psxEvent[i][%pre_min_t] = pre_min_t
		psxEvent[i][%i_amp] = i_peak-pre_min
		psxEvent[i][%isi] = isi
	endfor

	Redimension/N=(i, -1) eventFit, psxEvent

	if(!numCrossings)
		avg_amp = NaN
		avg_isi = NaN
	else
		// safe defaults
		psxEvent[][%$"Event manual QC call"] = PSX_UNDET
		psxEvent[][%$"Fit manual QC call"]   = PSX_UNDET
		psxEvent[][%$"Fit result"]           = 0

		psxEvent[][%tau] = PSX_FitEventDecay(sweepDataFiltOff, psxEvent, eventFit, p)

		WaveStats/Q/RMD=[][6] psxEvent
		avg_amp = V_avg

		WaveStats/Q/RMD=[][7] psxEvent
		avg_isi = V_avg
	endif

	psxAnalysis[index][%avgAmp] = avg_amp
	psxAnalysis[index][%avgIsi] = avg_isi
	psxAnalysis[index][%crossing] = numCrossings
end

/// @brief Return the x-axis range useful for displaying and extracting a single event
///
/// x-zero is taken from sweepData
static Function [variable first, variable last] PSX_GetSingleEventRange(WAVE psxEvent, variable index)

	variable numEvents

	numEvents = DimSize(psxEvent, ROWS)

	index = limit(index, 0, numEvents - 1)

	if(index == numEvents - 1)
		first = psxEvent[index][%dc_peak_time] - PSX_DEFAULT_X_START_OFFSET
		last  = psxEvent[index][%i_peak_t] + PSX_DEFAULT_DECAY_FIT_LENGTH
	else
		first = psxEvent[index][%dc_peak_time] - PSX_DEFAULT_X_START_OFFSET
		last  = psxEvent[index + 1][%dc_peak_time] - 0.5
	endif

	return [first, last]
End

/// @brief Return the x-axis range for single event fitting
///
/// x-zero is taken from sweepData
static Function [variable start, variable stop] PSX_GetEventFitRange(WAVE sweepDataFiltOff, WAVE psxEvent, variable eventIndex)

	variable i_peak_t, n_min_t

	i_peak_t = psxEvent[eventIndex][%i_peak_t]

	if(eventIndex == (DimSize(psxEvent, ROWS) - 1))
		n_min_t = min(i_peak_t + PSX_DEFAULT_DECAY_FIT_LENGTH, IndexToScale(sweepDataFiltOff, DimSize(sweepDataFiltOff, ROWS), ROWS))
	else
		n_min_t = psxEvent[eventIndex + 1][%pre_min_t]
	endif

	return [i_peak_t, n_min_t]
End

/// @brief Return the decay coefficient tau by fitting the filtered and
/// offsetted sweep data with an offsetted exponential
///
/// \rst
///
/// exp_XOffset: :math:`y = K0 + K1 \cdot exp(-(x - x0)/K2)`
///
/// \endrst
static Function PSX_FitEventDecay(WAVE sweepDataFiltOff, WAVE psxEvent, WAVE/WAVE eventFit, variable eventIndex)

	variable i_peak_t, n_min_t, err

	[i_peak_t, n_min_t] = PSX_GetEventFitRange(sweepDataFiltOff, psxEvent, eventIndex)

// Avoid crash with local wave, see WM #4328
//	DFREF currDFR = GetDataFolderDFR()
//	SetDataFolder NewFreeDataFolder()

	// require a converging exponential
	Make/FREE/T constraints = {"K2 > 0"}

	Make/FREE/D/N=3 coefWave

	AssertOnAndClearRTError()
	CurveFit/Q/N=1/NTHR=1/M=0/W=2 exp_XOffset, kwCWave=coefWave, sweepDataFiltOff(i_peak_t, n_min_t)/D/C=constraints; err = GetRTError(1)
	WAVE/Z fit = fit__free_

//	SetDataFolder currDFR

	if(err)
		psxEvent[eventIndex][%$"Fit manual QC call"] = PSX_REJECT
		psxEvent[eventIndex][%$"Fit result"] = 0
		return NaN
	endif

	MakeWaveFree(fit)
	ChangeFreeWaveName(fit, "expoffset_fit_event_" + num2str(eventIndex))

	eventFit[eventIndex] = fit
	psxEvent[eventIndex][%$"Fit result"] = 1
	psxEvent[eventIndex][%$"Fit manual QC call"] = PSX_UNDET

	return coefWave[2]
end

/// @brief Restore the event state from the results wave
///
/// @param[in,out] psxEvent psx event wave
/// @param[in]     comboKey results key
static Function PSX_RestoreEventState(WAVE psxEvent, string comboKey)

	// now we need to grab the cache event data to get the user set accepted/rejected state for event/fit
	WAVE/Z eventsFromResults = PSX_LoadEventsFromCache(comboKey)

	if(WaveExists(eventsFromResults) && DimSize(psxEvent, ROWS) == DimSize(eventsFromResults, ROWS))
		Multithread psxEvent[][%$"Event manual QC call"] = eventsFromResults[p][%$"Event manual QC call"]
		Multithread psxEvent[][%$"Fit manual QC call"]   = eventsFromResults[p][%$"Fit manual QC call"]
	endif
End

/// @brief Implementation of psx operation
///
/// @return 1 if data could be extracted, zero if not
static Function PSX_OperationImpl(string graph, WAVE/WAVE psxKernelDataset, variable peakThresh, variable filterLow, variable filterHigh, variable kernelAmp, variable readIndex, variable writeIndex, WAVE/WAVE output, WAVE psxAnalysis)

	string comboKey, key

	WAVE psxEvent = GetPSXEventWaveAsFree()
	WAVE eventFit  = GetPSXEventFitWaveAsFree()

	key = PSX_GenerateKey("psxKernelFFT", readIndex)
	WAVE psxKernelFFT = psxKernelDataset[%$key]

	key = PSX_GenerateKey("sweepData", readIndex)
	WAVE sweepData = psxKernelDataset[%$key]

	[WAVE selectData, WAVE range] = SFH_ParseToSelectDataWaveAndRange(sweepData)

	[WAVE sweepDataFiltOff, WAVE sweepDataFiltOffDeconv] = PSX_Analysis(sweepData, selectData, psxKernelFFT, filterLow, filterHigh, writeIndex, psxAnalysis)

	if(!WaveExists(sweepDataFiltOff) || !WaveExists(sweepDataFiltOffDeconv))
		return 0
	endif

	[WAVE peakX, WAVE peakY] = PSX_FindPeaks(sweepDataFiltOffDeconv, peakThresh)

	if(!WaveExists(peakX) || !WaveExists(peakY))
		return 0
	endif

	WAVE/T labels = ListToTextWave(PSX_EVENT_DIMENSION_LABELS, ";")
	ASSERT(DimSize(labels, ROWS) == PSX_OPERATION_OUTPUT_WAVES_PER_ENTRY, "Mismatched label wave")

	labels[] = PSX_GenerateKey(labels[p], writeIndex)
	SetDimensionLabels(output, TextWaveToList(labels, ";"), ROWS, startPos = writeIndex * PSX_OPERATION_OUTPUT_WAVES_PER_ENTRY)

	PSX_AnalyzePeaks(sweepDataFiltOffDeconv, sweepDataFiltOff, peakX, peakY, kernelAmp, writeIndex, psxAnalysis, psxEvent, eventFit)

	comboKey = PSX_GenerateComboKey(graph, selectData, range)
	JWN_SetStringInWaveNote(psxEvent, PSX_EVENTS_COMBO_KEY_WAVE_NOTE, comboKey)
	JWN_SetStringInWaveNote(psxEvent, PSX_X_DATA_UNIT, WaveUnits(sweepData, ROWS))
	JWN_SetStringInWaveNote(psxEvent, PSX_Y_DATA_UNIT, WaveUnits(sweepData, -1))

	PSX_RestoreEventState(psxEvent, comboKey)

	key = PSX_GenerateKey("sweepData", writeIndex)
	output[%$key] = sweepData

	key = PSX_GenerateKey("sweepDataFiltOff", writeIndex)
	output[%$key] = sweepDataFiltOff

	key = PSX_GenerateKey("sweepDataFiltOffDeconv", writeIndex)
	output[%$key] = sweepDataFiltOffDeconv

	key = PSX_GenerateKey("peakX", writeIndex)
	output[%$key] = peakX

	key = PSX_GenerateKey("peakY", writeIndex)
	output[%$key] = peakY

	key = PSX_GenerateKey("psxEvent", writeIndex)
	output[%$key] = psxEvent

	key = PSX_GenerateKey("eventFit", writeIndex)
	output[%$key] = eventFit

	return 1
End

/// @brief Generate the dimension label for the output wave reference waves
///
/// Used for `psx` and `psxKernel` as both hold
/// #PSX_KERNEL_OUTPUTWAVES_PER_ENTRY` and #PSX_OPERATION_OUTPUT_WAVES_PER_ENTRY
/// entries per input range/sweep combination.
static Function/S PSX_GenerateKey(string name, variable index)

	return name + "_" + num2istr(index)
End

/// @brief Return the PSX kernel from the cache or create it
static Function/WAVE PSX_GetPSXKernel(variable riseTau, variable decayTau, variable amp, variable numPoints, variable dt, WAVE range)
	string key

	key = CA_PSXKernelKey(riseTau, decayTau, amp, numPoints, dt, range)

	WAVE/WAVE/Z result = CA_TryFetchingEntryFromCache(key)

	if(WaveExists(result))
		return result
	endif

	[WAVE psx_kernel, WAVE kernel_fft] = PSX_CreatePSXKernel(riseTau, decayTau, amp, numPoints, dt)
	Make/FREE/WAVE result = {psx_kernel, kernel_fft}

	CA_StoreEntryIntoCache(key, result)

	return result
End

/// Create the psx_kernel waves
///
/// @param riseTau      time constant
/// @param decayTau      time constant
/// @param amp       amplitude [no unit]
/// @param numPoints number of data points
/// @param dt        time constant for normalisation
///
/// from Ken Burke's deconvolution code
///
/// The time units are abitrary but fixed for all three components.
static Function [WAVE kernel, WAVE kernelFFT] PSX_CreatePSXKernel(variable riseTau, variable decayTau, variable amp, variable numPoints, variable dt)

	variable riseTau_p, decayTau_p, kernel_window, amp_prime

	riseTau_p        = riseTau / dt
	decayTau_p        = decayTau / dt
	kernel_window = decayTau_p * 4
	amp_prime     = (decayTau_p / riseTau_p)^(riseTau_p / (riseTau_p - decayTau_p)) // normalization factor

	Make/FREE/N=(kernel_window) timeIndex = p
	SetScale/P x, 0, dt, timeIndex

	Make/FREE/N=(kernel_window) kernel = (amp / amp_prime) * (-exp(-timeIndex / riseTau_p) + exp(-timeIndex / decayTau_p))
	SetScale/P x, 0, dt, kernel

	// no window function on purpose
	WAVE kernelFFT = DoFFT(kernel, padSize = numPoints)

	return [kernel, kernelFFT]
end

/// @brief Return the data/index/marker/comboKeys of the events matching the given state and property
static Function [WAVE/D results, WAVE eventIndex, WAVE marker, WAVE/T comboKeys] PSX_GetStatsResults(WAVE allEvents, WAVE/T allComboKeys, variable state, string prop)

	string stateType

	// use the correct event/fit state for the property
	strswitch(prop)
		case "i_amp":
		case "dc_peak_time":
		case "isi":
		case "Event manual QC call":
			stateType = "Event manual QC call"
			break
		case "Fit result":
		case "tau":
		case "Fit manual QC call":
			stateType = "Fit manual QC call"
			break
		default:
			ASSERT(0, "Unknown prop")
	endswitch

	WAVE/Z indizes = FindIndizes(allEvents, var = state, colLabel = stateType, prop = PROP_MATCHES_VAR_BIT_MASK)

	if(!WaveExists(indizes))
		return [$"", $"", $"", $""]
	endif

	Make/D/FREE/N=(Dimsize(indizes, ROWS)) results
	Make/FREE/N=(Dimsize(indizes, ROWS)) marker, eventIndex
	Make/FREE/N=(Dimsize(indizes, ROWS))/T comboKeys

	Multithread results[]    = allEvents[indizes[p]][%$prop]
	Multithread eventIndex[] = allEvents[indizes[p]][%index]
	MultiThread comboKeys[]  = allComboKeys[indizes[p]]
	Multithread marker[]     = PSX_SelectMarker(allEvents[indizes[p]][%$stateType])

	return [results, eventIndex, marker, comboKeys]
End

/// @brief Build the dimension label used for the sweep equivalence wave
static Function/S PSX_BuildSweepEquivKey(variable chanType, variable chanNr)

	string str

	sprintf str, "ChanType%d_ChanNr%d", chanType, chanNr

	return str
End

/// @brief Return the triplett channel number, channel type and sweep number from the sweep equivalence wave located in the given row/col
static Function [variable chanNr, variable chanType, variable sweepNo] PSX_GetSweepEquivKeyAndSweep(WAVE sweepEquiv, variable row, variable col)

	string str,  chanTypeStr, chanNrStr

	str = GetDimLabel(sweepEquiv, ROWS, row)
	ASSERT(strlen(str) > 0, "Unexpected empty row label")

	SplitString/E="ChanType([[:digit:]]+)_ChanNr([[:digit:]]+)" str,  chanTypeStr, chanNrStr

	chanType = str2num(chanTypeStr)
	chanNr   = str2num(chanNrStr)

	return [chanNr, chanType, sweepEquiv[row][col]]
End

/// @brief Generate the equivalence classes of selectData
///
/// All selections which have the same channel number and type are in one equivalence class.
///
/// The returned 2D wave has row labels from PSX_BuildSweepEquivKey() and the sweep numbers in the columns.
static Function/WAVE PSX_GenerateSweepEquiv(WAVE selectData)

	variable numSelect, idx, i, nextFreeRow, maxCol
	string key

	numSelect = DimSize(selectData, ROWS)
	ASSERT(numSelect > 0, "Expected at least one entry in sweepData")

	Make/N=(numSelect, numSelect)/FREE=1 sweepEquiv = NaN

	for(i = 0; i < numSelect; i += 1)
		key = PSX_BuildSweepEquivKey(selectData[i][%CHANNELTYPE], selectData[i][%CHANNELNUMBER])
		idx = FindDimLabel(sweepEquiv, ROWS, key)

		if(idx == -2)
			SetDimLabel ROWS, nextFreeRow, $key, sweepEquiv
			idx = nextFreeRow
			nextFreeRow += 1
		endif

		FindValue/FNAN/RMD=[idx][] sweepEquiv
		ASSERT(V_col >= 0, "Not enough space")
		maxCol = max(maxCol, V_col)

		sweepEquiv[idx][V_col] = selectData[i][%SWEEP]
	endfor

	ASSERT(nextFreeRow > 0, "Could not build sweep equivalence classes")

	Redimension/N=(nextFreeRow, maxCol + 1) sweepEquiv

	return sweepEquiv
End

/// @brief Helper function of the `psxStats` operation
static Function/WAVE PSX_OperationStatsImpl(string graph, WAVE rangeParam, WAVE selectData, string prop, string stateAsStr, string postProc)

	string propLabel, propLabelAxis, comboKey
	variable numRows, numCols, i, j, k, index, sweepNo, chanNr, chanType, state, numRanges

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_PSX_STATS, MINIMUM_WAVE_SIZE)

	// create equivalence classes where chanNr/chanType are the same and only the sweep number differs
	WAVE selectDataEquiv = PSX_GenerateSweepEquiv(selectData)

	numRows = DimSize(selectDataEquiv, ROWS)
	numCols = DimSize(selectDataEquiv, COLS)

	// see also SFH_EvaluateRange()
	if(IsNumericWave(rangeParam))
		numRanges = 1
		Make/FREE/WAVE allRanges = {rangeParam}
	elseif(IsTextWave(rangeParam))
		numRanges = DimSize(rangeParam, ROWS)
		WAVE/T rangeParamText = rangeParam
		Make/FREE/WAVE/N=(numRanges) allRanges = ListToTextWave(rangeParamText[p], ";")
		WaveClear rangeParamText
	endif
	WaveClear rangeParam

	WAVE allEvents = GetPSXEventWaveAsFree()
	Make/FREE/T/N=(0) allComboKeys

	// iteration order: different chanType/chanNr (equivalence classes), range, sweepNo
	for(i = 0; i < numRows; i += 1)
		for(j = 0; j < numRanges; j += 1)
			WAVE range = alLRanges[j]

			for(k = 0; k < numCols; k += 1)

				[chanNr, chanType, sweepNo] = PSX_GetSweepEquivKeyAndSweep(selectDataEquiv, i, k)

				if(!IsValidSweepNumber(sweepNo))
					break
				endif

				WAVE singleSelectData = SFH_NewSelectDataWave(1, 1)

				singleSelectData[0][%SWEEP]         = sweepNo
				singleSelectData[0][%CHANNELNUMBER] = chanNr
				singleSelectData[0][%CHANNELTYPE]   = chanType

				comboKey = PSX_GenerateComboKey(graph, singleSelectData, range)
				WAVE/Z events = PSX_GetEventsFromResults(comboKey)

				if(!WaveExists(events))
					// prefer data from local folder iff no results data could be found
					WAVE/Z events = PSX_GetEventsFromDataFolder(graph, comboKey)
				endif

				if(!WaveExists(events))
					// still nothing let's skip it
					continue
				endif

				if(DimSize(allEvents, ROWS) == 0)
					Note/K allEvents, note(events)
				endif

				ASSERT(DimSize(events, COLS) == DimSize(allEvents, COLS), "Mismatched columns")
				Concatenate/FREE/NP=(ROWS) {events}, allEvents

				Make/FREE/T/N=(DimSize(events, ROWS)) comboKeys = comboKey
				Concatenate/FREE/NP=(ROWS)/T {comboKeys}, allComboKeys

				WaveClear events, comboKeys
			endfor

			ASSERT(DimSize(allEvents, ROWS) == DimSize(allComboKeys, ROWS), "Unmatched all events/combo sizes")

			SFH_ASSERT(DimSize(allEvents, ROWS) > 0, "Could not find any PSX events for all given combinations.")

			strswitch(prop)
				case "amp":
					propLabel     = "i_amp"
					propLabelAxis = "Amplitude" + " (" + JWN_GetStringFromWaveNote(allEvents, PSX_Y_DATA_UNIT) + ")"
					break
				case "xpos":
					propLabel     = "dc_peak_time"
					propLabelAxis = "Event time" + " (" + JWN_GetStringFromWaveNote(allEvents, PSX_X_DATA_UNIT) + ")"
					break
				case "xinterval":
					propLabel     = "isi"
					propLabelAxis = "Event interval" + " (" + JWN_GetStringFromWaveNote(allEvents, PSX_X_DATA_UNIT) + ")"
					break
				case "tau":
					propLabel     = "tau"
					propLabelAxis = "Decay tau" + " (" + JWN_GetStringFromWaveNote(allEvents, PSX_X_DATA_UNIT) + ")"
					break
				case "estate":
					propLabel     = "Event manual QC call"
					propLabelAxis = "Event manual QC" + " (enum)"
					break
				case "fstate":
					propLabel     = "Fit manual QC call"
					propLabelAxis = "Fit manual QC" + " (enum)"
					break
				case "fitresult":
					propLabel     = "Fit result"
					propLabelAxis = "Fit result" + " (0/1)"
					break
				default:
					ASSERT(0, "Impossible prop")
			endswitch

			if(!cmpstr(stateAsStr, "every"))
				WAVE allStates = PSX_GetStates()
			else
				Make/FREE allStates = {PSX_ParseState(stateAsStr)}
			endif

			for(state : allStates)

				[WAVE resultsRaw, WAVE eventIndex, WAVE marker, WAVE/T comboKeys] = PSX_GetStatsResults(allEvents, allComboKeys, state, propLabel)

				if(!WaveExists(resultsRaw))
					continue
				endif

				strswitch(postProc)
					case "nothing":
						WAVE/D results = resultsRaw

						JWN_SetWaveInWaveNote(results, SF_META_XVALUES, eventIndex)
						break
					case "avg":
						MatrixOp/FREE results = mean(resultsraw)
						break
					case "count":
						MatrixOP/FREE results = numRows(resultsRaw)
						break
					case "hist":
						Make/FREE/N=0/D results
						Histogram/DP/B=5/DEST=results resultsRaw
						break
					case "log10":
						MatrixOp/FREE results = log(resultsRaw)

						JWN_SetWaveInWaveNote(results, SF_META_XVALUES, eventIndex)
						break
					default:
						ASSERT(0, "Impossible postProc state")
				endswitch

				JWN_SetWaveInWaveNote(results, SF_META_RANGE, range)
				// passing in sweepNo is not correct when combining data from multiple sweeps
				// but we need it to be set to something valid so that the headstage colors work
				// we assume therefore that all sweeps use the same active HS/AD/DAC settings
				JWN_SetNumberInWaveNote(results, SF_META_SWEEPNO, sweepNo)
				JWN_SetNumberInWaveNote(results, SF_META_CHANNELTYPE, chanType)
				JWN_SetNumberInWaveNote(results, SF_META_CHANNELNUMBER, chanNr)

				ASSERT(DimSize(results, ROWS) <= DimSize(marker, ROWS), "results wave got larger unexpectedly")
				Redimension/N=(DimSize(results, ROWS)) marker, comboKeys

				JWN_SetWaveInWaveNote(results, SF_META_MOD_MARKER, marker)

				JWN_CreatePath(results, SF_META_USER_GROUP + PSX_JWN_COMBO_KEYS_NAME)
				JWN_SetWaveInWaveNote(results, SF_META_USER_GROUP + PSX_JWN_COMBO_KEYS_NAME, comboKeys)

				JWN_CreatePath(results, SF_META_USER_GROUP + PSX_JWN_STATS_POST_PROC)
				JWN_SetStringInWaveNote(results, SF_META_USER_GROUP + PSX_JWN_STATS_POST_PROC, postProc)

				JWN_SetNumberInWaveNote(results, SF_META_SHOW_LEGEND, 0)

				EnsureLargeEnoughWave(output, indexShouldExist = index)
				output[index] = results
				index += 1
			endfor
		endfor
	endfor

	Redimension/N=(index) output

	// PSX_MouseEventSelection works for "nothing" and "log10" post processing

	// we assume here that all event waves have the same X/Y data units
	strswitch(postProc)
		case "nothing":
			JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, "Event")
			JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, propLabelAxis)
			break
		case "avg":
			JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, "NA")
			JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, "Averaged " + LowerStr(propLabelAxis))
			break
		case "count":
			JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, "NA")
			JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, "Count")
			break
		case "hist":
			JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, propLabelAxis)
			JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, "Event count")
			break
		case "log10":
			JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, "Event")
			JWN_SetStringInWaveNote(output, SF_META_YAXISLABEL, "Log10 " + LowerStr(propLabelAxis))
			break
		default:
			ASSERT(0, "Impossible state")
	endswitch

	return output
End

/// @brief Return all possible fit/event states
///
/// @param withAllState [optional, defaults to false] choose to include #PSX_ALL (true) or not (false)
static Function/WAVE PSX_GetStates([variable withAllState])

	if(ParamIsDefault(withAllState))
		withAllState = 0
	else
		withAllState = !!withAllState
	endif

	ASSERT(PSX_UNDET == PSX_LAST, "state wave is incomplete")

	if(withAllState)
		Make/FREE states = {PSX_ACCEPT, PSX_REJECT, PSX_UNDET, PSX_ALL}
	else
		Make/FREE states = {PSX_ACCEPT, PSX_REJECT, PSX_UNDET}
	endif

	return states
End

static Function PSX_ParseState(string state)

	strswitch(state)
		case "Accept":
			return PSX_ACCEPT
		case "Reject":
			return PSX_REJECT
		case "Undetermined":
			return PSX_UNDET
		case "All":
			return PSX_ACCEPT | PSX_REJECT | PSX_UNDET
		default:
			ASSERT(0, "Impossible state")
	endswitch
End

Function/S PSX_StateToString(variable state)

	switch(state)
		case PSX_ACCEPT:
			return "Accept"
		case PSX_REJECT:
			return "Reject"
		case PSX_UNDET:
			return "Undetermined"
		case PSX_ALL:
			return "All"
		default:
			ASSERT(0, "invalid state")
	endswitch
End

static Function PSX_UpdateAllEventGraph(string win, [variable forceSingleEventUpdate, variable forceAverageUpdate])

	if(ParamIsDefault(forceSingleEventUpdate))
		forceSingleEventUpdate = 0
	else
		forceSingleEventUpdate = !!forceSingleEventUpdate
	endif

	if(ParamIsDefault(forceAverageUpdate))
		forceAverageUpdate = 0
	else
		forceAverageUpdate = !!forceAverageUpdate
	endif

	PSX_UpdateHideStateInAllEventGraph(win)
	PSX_AdaptColorsInAllEventGraph(win, forceSingleEventUpdate = forceSingleEventUpdate, forceAverageUpdate = forceAverageUpdate)
End

/// @brief Update the single event graph
static Function PSX_UpdateSingleEventGraph(string win, variable index)

	string extSingleGraph
	variable first, last

	if(PSX_EventGraphSuppressUpdate(win))
		return NaN
	endif

	DFREF comboDFR = PSX_GetCurrentComboFolder(win)

	WAVE psxEvent = GetPSXEventWaveFromDFR(comboDFR)
	[first, last] = PSX_GetSingleEventRange(psxEvent, index)

	extSingleGraph = PSX_GetSingleEventGraph(win)

	SetAxis/W=$extSingleGraph bottom, first, last
	SetAxis/W=$extSingleGraph/A=2 left

	PSX_UpdateDisplayedFit(comboDFR, index)

	PSX_UpdateSingleEventTextbox(extSingleGraph, eventIndex = index)
End

/// @brief Update the displayed fit in the single event graph
static Function PSX_UpdateDisplayedFit(DFREF comboDFR, variable index)

 	WAVE/WAVE eventFit = GetPSXEventFitWaveFromDFR(comboDFR)

	WAVE/Z singleEventFitFree = eventFit[index]

	WAVE singleEventFit = GetPSXSingleEventFitWaveFromDFR(comboDFR)

	if(WaveExists(singleEventFitFree))
		Redimension/N=(DimSize(singleEventFitFree, ROWS)) singleEventFit
		singleEventFit[] = singleEventFitFree[p]
		CopyScales/P singleEventFitFree, singleEventFit
	else
		FastOp singleEventFit = (NaN)
	endif
End

/// @brief Update trace colors in all event graph
///
/// This needs to be done every time an event changes its state.
///
/// @param win                     window
/// @param forceAverageUpdate      [optional, defaults to false] perform an average
///                                wave update regardless if required or not.
/// @param forceSingleEventUpdate [optional, defaults to false] update every single event trace regardless of its old state
static Function PSX_AdaptColorsInAllEventGraph(string win, [variable forceAverageUpdate, variable forceSingleEventUpdate])

	string extAllGraph, trace, stateType
	variable i, numWaves, stateMatchPattern, numCombos, stateColumn
	variable idx, averageUpdateRequired, numSingleEventTraces

	if(ParamIsDefault(forceAverageUpdate))
		forceAverageUpdate = 0
	else
		forceAverageUpdate = !!forceAverageUpdate
	endif

	if(ParamIsDefault(forceSingleEventUpdate))
		forceSingleEventUpdate = 0
	else
		forceSingleEventUpdate = !!forceSingleEventUpdate
	endif

	extAllGraph = PSX_GetAllEventGraph(win)

	if(!WindowExists(extAllGraph))
		return NaN
	endif

	if(PSX_EventGraphSuppressUpdate(win))
		return NaN
	endif

	DFREF workDFR = PSX_GetWorkingFolder(win)

	WAVE/DF/Z comboFolders = PSX_GetAllCombinationFolders(workDFR)

	if(!WaveExists(comboFolders))
		return NaN
	endif

	numCombos = DimSize(comboFolders, ROWS)

	[WAVE/T keys, WAVE/T values] = PSX_GetTraceSelectionWaves(win, PSX_TUD_TYPE_SINGLE)

	// two indizes are used here:
	// i: index to iterate over trace user data waves (traceNames and XXXFromTraces)
	// indexMapper[i]: psx event index used inside a specific combo (psxEventRefWave and psxColorsRefWave)

	// all indexed by i
	WAVE/T/Z traceNames = TUD_GetUserDataAsWave(extAllGraph, "tracename", keys = keys, values = values)
	ASSERT(WaveExists(traceNames), "Expected at least one entry")

	WAVE/T hideTracesFromTraces   = TUD_GetUserDataAsWave(extAllGraph, PSX_TUD_TRACE_HIDDEN_KEY, keys = keys, values = values)
	WAVE/T eventStateFromTraces   = TUD_GetUserDataAsWave(extAllGraph, PSX_TUD_EVENT_STATE_KEY,  keys = keys, values = values)
	WAVE/T fitStateFromTraces     = TUD_GetUserDataAsWave(extAllGraph, PSX_TUD_FIT_STATE_KEY,  keys = keys, values = values)
	WAVE/T eventIndexFromTraces   = TUD_GetUserDataAsWave(extAllGraph, PSX_TUD_EVENT_INDEX_KEY,  keys = keys, values = values)
	WAVE/T comboIndizesFromTraces = TUD_GetUserDataAsWave(extAllGraph, PSX_TUD_COMBO_INDEX,  keys = keys, values = values)
	numSingleEventTraces = DimSize(eventIndexFromTraces, ROWS)

	// wave reference wave with psxEvents wave indexed by *comboIndex*
	// the waves therein must be indexed via indexMapper[i]
	Make/N=(numCombos)/FREE/WAVE psxEventRefWave = GetPSXEventWaveFromDFR(comboFolders[p])
	Make/N=(numCombos)/FREE/WAVE psxColorsRefWave = GetPSXEventColorsWaveFromDFR(comboFolders[p])

	WAVE checkboxActive = PSX_GetCheckboxStatesFromSpecialPanel(win, PSX_TUD_TYPE_SINGLE)

	stateMatchPattern = PSX_GetStateMatchPattern(checkboxActive)

	// all indexed by i
	Make/FREE/N=(numSingleEventTraces) hideTracesNew, eventStateNew, fitStateNew, differentHideState, differentEventState, indexMapper
	Make/FREE/N=(numSingleEventTraces, 4) colorsNew

	MultiThread indexMapper = str2num(eventIndexFromTraces[p])

	stateColumn = FindDimLabel(psxEventRefWave[0], COLS, "Event manual QC call")
	MultiThread eventStateNew = WaveRef(psxEventRefWave, row = str2num(comboIndizesFromTraces[p]))[indexMapper[p]][stateColumn]

	stateColumn = FindDimLabel(psxEventRefWave[0], COLS, "Fit manual QC call")
	MultiThread fitStateNew = WaveRef(psxEventRefWave, row = str2num(comboIndizesFromTraces[p]))[indexMapper[p]][stateColumn]

	stateType = PSX_GetStateTypeFromSpecialPanel(win)

	strswitch(stateType)
		case PSX_TUD_FIT_STATE_KEY:
			WAVE stateNew   = fitStateNew
			WAVE/T stateOld = fitStateFromTraces
			break
		case PSX_TUD_EVENT_STATE_KEY:
			WAVE stateNew   = eventStateNew
			WAVE/T stateOld = eventStateFromTraces
			break
		default:
			ASSERT(0, "Invalid state type")
	endswitch

	[WAVE acceptColors, WAVE rejectColors, WAVE undetColors] = PSX_GetEventColors()

	MultiThread hideTracesNew[] = (stateNew[p] & stateMatchPattern) == 0
	MultiThread colorsNew[][]   = PSX_SelectColor(stateNew[p], acceptColors, rejectColors, undetColors)[q]

	if(forceSingleEventUpdate)

		ACC_HideTracesAndColor(extAllGraph, traceNames, numSingleEventTraces, hideTracesNew, colorsNew)

		WAVE indexHelper = hideTracesNew
		indexHelper[] = TUD_SetUserDataFromWaves(extAllGraph, traceNames[i],                                                     \
		                                         {PSX_TUD_FIT_STATE_KEY, PSX_TUD_EVENT_STATE_KEY, PSX_TUD_TRACE_HIDDEN_KEY},     \
		                                         {num2str(fitStateNew[p]), num2str(eventStateNew[p]), num2str(hideTracesNew[p])})

	else
		MultiThread differentHideState  = (str2num(hideTracesFromTraces[p]) != hideTracesNew[p])
		MultiThread differentEventState = (str2num(stateOld[p]) != stateNew[p])

		for(i = 0; i < numSingleEventTraces; i += 1)
			if(!differentHideState[i] && !differentEventState[i])
				// nothing to do
				continue
			endif

			trace = traceNames[i]

			// printf "Trace %s changed, differentHideState %d, differentEventState %d, new state %s\r", trace, differentHideState[i], differentEventState[i], PSX_StateToString(stateNew[i])

			if(differentHideState[i] && differentEventState[i])
				averageUpdateRequired = 1

				ModifyGraph/W=$extAllGraph hideTrace($trace)=(hideTracesNew[i]), rgb($trace)=(colorsNew[i][0], colorsNew[i][1], colorsNew[i][2], colorsNew[i][3])

				TUD_SetUserDataFromWaves(extAllGraph, trace,                                                             \
				                         {PSX_TUD_FIT_STATE_KEY, PSX_TUD_EVENT_STATE_KEY, PSX_TUD_TRACE_HIDDEN_KEY},     \
				                         {num2str(fitStateNew[i]), num2str(eventStateNew[i]), num2str(hideTracesNew[i])})

			elseif(differentHideState[i])
				ModifyGraph/W=$extAllGraph hideTrace($trace)=(hideTracesNew[i])

				TUD_SetUserDataFromWaves(extAllGraph, trace,         \
				                         {PSX_TUD_TRACE_HIDDEN_KEY}, \
				                         {num2str(hideTracesNew[i])})
			elseif(differentEventState[i])
				averageUpdateRequired = 1

				WAVE color = PSX_SelectColor(stateNew[i], acceptColors, rejectColors, undetColors)

				ModifyGraph/W=$extAllGraph rgb($trace)=(colorsNew[i][0], colorsNew[i][1], colorsNew[i][2], colorsNew[i][3])

				TUD_SetUserDataFromWaves(extAllGraph, trace,                                  \
				                         {PSX_TUD_FIT_STATE_KEY, PSX_TUD_EVENT_STATE_KEY},    \
				                         {num2str(fitStateNew[i]), num2str(eventStateNew[i])})
			else
				ASSERT(0, "Impossible case")
			endif
		endfor
	endif

	if(averageUpdateRequired || forceAverageUpdate)
		PSX_UpdateAverageTraces(win, eventIndexFromTraces, comboIndizesFromTraces, stateNew, indexMapper, comboFolders)
	endif
End

/// @brief Update the contents of the average waves for the all event graph
static Function PSX_UpdateAverageTraces(string win, WAVE/T eventIndexFromTraces, WAVE/T comboIndizesFromTraces, WAVE stateNew, WAVE indexMapper, WAVE/DF comboFolders)

	variable i, idx, numEvents, eventState
	variable acceptIndex, rejectIndex, undetIndex
	string extAllGraph, name

	extAllGraph = PSX_GetAllEventGraph(win)

	numEvents = DimSize(eventIndexFromTraces, ROWS)

	Make/WAVE/FREE/N=(numEvents) contAverageAll, contAverageAccept, contAverageReject, contAverageUndet

	for(i = 0; i < numEvents; i += 1)
		idx = str2num(eventIndexFromTraces[i])

		DFREF singleEventDFR = GetPSXSingleEventFolder(comboFolders[str2num(comboIndizesFromTraces[i])])

		name = PSX_FormatSingleEventWaveName(idx)

		WAVE/SDFR=singleEventDFR singleEvent = $name

		switch(stateNew[i])
			case PSX_ACCEPT:
				contAverageAccept[acceptIndex] = singleEvent
				acceptIndex += 1
				break
			case PSX_REJECT:
				contAverageReject[rejectIndex] = singleEvent
				rejectIndex += 1
				break
			case PSX_UNDET:
				contAverageUndet[undetIndex] = singleEvent
				undetIndex += 1
				break
			default:
				ASSERT(0, "impossible state")
		endswitch

		contAverageAll[i] = singleEvent
	endfor

	DFREF averageDFR = PSX_GetAverageFolder(win)

	PSX_UpdateAverageWave(contAverageAccept, acceptIndex, averageDFR, PSX_ACCEPT)
	PSX_UpdateAverageWave(contAverageReject, rejectIndex, averageDFR, PSX_REJECT)
	PSX_UpdateAverageWave(contAverageUndet, undetIndex, averageDFR, PSX_UNDET)
	PSX_UpdateAverageWave(contAverageAll, numEvents, averageDFR, PSX_ALL)
End

/// @brief Helper function to update the average waves for the all event graph
static Function PSX_UpdateAverageWave(WAVE/WAVE sourceWaves, variable numFilledSourceWaves, DFREF averageDFR, variable state)

	Redimension/N=(numFilledSourceWaves) sourceWaves
	WAVE average = GetPSXAverageWave(averageDFR, state)
	if(numFilledSourceWaves > 0)
		CalculateAverage(sourceWaves, GetWavesDataFolderDFR(average), NameOfWave(average), skipCRC = 1, writeSourcePaths = 0)
	else
		FastOp average = (NaN)
	endif
End

static Function/DF PSX_GetAverageFolder(string win)

	if(PSX_GetRestrictEventsToCurrentCombo(win))
		return PSX_GetCurrentComboFolder(win)
	else
		return PSX_GetWorkingFolder(win)
	endif
End

static Function PSX_StoreIntoResultsWave(string browser, variable resultType, WAVE data, string name)

	string lastBrowser
	string rawCode = NONE

	ASSERT(!IsWaveRefWave(data), "Expected a plain wave")

	WAVE/T formulaGraphs = SFH_GetFormulaGraphs()

	if(DimSize(formulaGraphs, ROWS) > 1)
		WAVE/T textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)
		lastBrowser = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula browser", SWEEP_FORMULA_PSX)

		if(cmpstr(browser, lastBrowser))
			// don't add an entry as the last entry was from another sweepbrowser/formula graph
			printf "There are multiple sweep/databrowsers open but only one instance can write into the results wave.\r"
			printf "The last instance to write was \"%s\".\r", lastBrowser
			ControlWindowToFront()
			return NaN
		endif
	endif

	Make/N=1/WAVE/FREE container = {data}

	[WAVE/T keys, WAVE/T values] = SFH_CreateResultsWaveWithCode(browser, rawCode,        \
	                                                             resultType = resultType, \
	                                                             data = container,        \
	                                                             name = name)

	ED_AddEntriesToResults(values, keys, SWEEP_FORMULA_PSX)
End

Function/S CA_PSXEventsKey(string key)

	return key + ":Version 1"
End

static Function PSX_StoreEventsIntoCache(WAVE psxEvent)
	string key, comboKey

	comboKey = JWN_GetStringFromWaveNote(psxEvent, PSX_EVENTS_COMBO_KEY_WAVE_NOTE)
	key = CA_PSXEventsKey(comboKey)
	CA_StoreEntryIntoCache(key, psxEvent)
End

static Function/WAVE PSX_LoadEventsFromCache(string comboKey)
	string key

	key = CA_PSXEventsKey(comboKey)

	WAVE/Z psxEvent = CA_TryFetchingEntryFromCache(key)

	if(!WaveExists(psxEvent))
		return $""
	endif

	UpgradePSXEventWave(psxEvent)

	return psxEvent
End

/// @brief Return the trace user data keys/values wave for the given trace type
static Function [WAVE/T keys, WAVE/T values] PSX_GetTraceSelectionWaves(string win, string traceType)

	string comboKey

	if(PSX_GetRestrictEventsToCurrentCombo(win))
		DFREF comboDFR = PSX_GetCurrentComboFolder(win)
		comboKey = PSX_GetComboKeyFromDFR(comboDFR)

		Make/FREE/T keys   = {PSX_TUD_TYPE_KEY, PSX_TUD_COMBO_KEY}
		Make/FREE/T values = {traceType, comboKey}
	else
		strswitch(traceType)
			case PSX_TUD_TYPE_SINGLE:
				Make/FREE/T keys   = {PSX_TUD_TYPE_KEY}
				Make/FREE/T values = {traceType}
				break
			case PSX_TUD_TYPE_AVERAGE:
				// only gather the gobal average waves
				Make/FREE/T keys   = {PSX_TUD_TYPE_KEY, PSX_TUD_COMBO_KEY}
				Make/FREE/T values = {traceType, PSX_TUD_AVERAGE_ALL_COMBO_KEY}
				break
			default:
				ASSERT(0, "Invalid state type")
		endswitch
	endif

	return [keys, values]
End

/// @brief Update the hide state of all traces in the all event graph
static Function PSX_UpdateHideStateInAllEventGraph(string win)

	string extAllGraph

	if(PSX_EventGraphSuppressUpdate(win))
		return NaN
	endif

	extAllGraph = PSX_GetAllEventGraph(win)

	// hide all traces
	ModifyGraph/W=$extAllGraph hideTrace=1

	PSX_UpdateHideStateInAllEventGraphImpl(win, PSX_TUD_TYPE_SINGLE)
	PSX_UpdateHideStateInAllEventGraphImpl(win, PSX_TUD_TYPE_AVERAGE)
End

static Function PSX_UpdateHideStateInAllEventGraphImpl(string win, string traceType)

	variable numEntries, stateMatchPattern, allSelected
	string extAllGraph, stateType, comboKey

	WAVE states = PSX_GetStates(withAllState = 1)

	[WAVE/T keys, WAVE/T values] = PSX_GetTraceSelectionWaves(win, traceType)

	WAVE checkboxActive = PSX_GetCheckboxStatesFromSpecialPanel(win, traceType)

	stateMatchPattern = PSX_GetStateMatchPattern(checkboxActive)

	extAllGraph = PSX_GetAllEventGraph(win)

	WAVE/T/Z traceNames = TUD_GetUserDataAsWave(extAllGraph, "tracename", keys = keys, values = values)
	ASSERT(WaveExists(traceNames), "Expected at least one entry")

	numEntries = DimSize(traceNames, ROWS)

	stateType = PSX_GetStateTypeFromSpecialPanel(win)

	WAVE/T currentState = TUD_GetUserDataAsWave(extAllGraph, stateType, keys = keys, values = values)

	allSelected = checkboxActive[%all]

	Make/FREE/N=(numEntries) hideState
	MultiThread/NT=(numEntries < 128) hideState[] = !((str2num(currentState[p]) == PSX_ALL ? allSelected : (stateMatchPattern & str2num(currentState[p]))))

	ACC_HideTracesPerTrace(extAllGraph, traceNames, numEntries, hideState)

	Make/FREE/N=(numEntries) indexHelper

	indexHelper[] = TUD_SetUserData(extAllGraph, traceNames[p], PSX_TUD_TRACE_HIDDEN_KEY, num2str(hideState))
End

/// @brief Return a bit pattern to match fit/event state
///
/// @param active Wave with at least 3 entries denoting which states are active
static Function PSX_GetStateMatchPattern(WAVE active)

	ASSERT(PSX_LAST == 0x04, "Code needs adaptation")

	return (active[%accept] ? PSX_ACCEPT : 0) | (active[%reject] ? PSX_REJECT : 0) | (active[%undetermined] ? PSX_UNDET : 0)
End

/// @brief Add the total number of required traces to the all event graph
///
/// The number of average waves is 4 due to the number of different states, see @ref PSXStates.
///
/// - Single event traces for all combinations
/// - 4 average waves for *each* combination
/// - 4 average waves for the global average across all combinations
static Function PSX_AppendTracesToAllEventGraph(string win)

	variable i, numEvents, state, idx, comboIndex
	string trace, extAllGraph, comboKey

	extAllGraph = PSX_GetAllEventGraph(win)

	WAVE states = PSX_GetStates(withAllState = 1)

	[WAVE acceptColors, WAVE rejectColors, WAVE undetColors] = PSX_GetEventColors()

	DFREF workDFR = PSX_GetWorkingFolder(win)
	WAVE/DF/Z comboFolders = PSX_GetAllCombinationFolders(workDFR)

	if(!WaveExists(comboFolders))
		return NaN
	endif

	Make/FREE/T traceUserDataKeys = {PSX_TUD_EVENT_INDEX_KEY, PSX_TUD_FIT_STATE_KEY, PSX_TUD_EVENT_STATE_KEY, PSX_TUD_TRACE_HIDDEN_KEY, PSX_TUD_TYPE_KEY, PSX_TUD_COMBO_KEY, PSX_TUD_COMBO_INDEX}

	for(DFREF comboDFR : comboFolders)

		WAVE eventColors = GetPSXEventColorsWaveFromDFR(comboDFR)

		WAVE psxEvent = GetPSXEventWaveFromDFR(comboDFR)
		numEvents = DimSize(psxEvent, ROWS)

		comboKey   = PSX_GetComboKeyFromDFR(comboDFR)
		comboIndex = PSX_GEtComboIndexFromDFR(comboDFR)

		DFREF singleEventDFR = GetPSXSingleEventFolder(comboDFR)

		for(i = 0; i < numEvents; i += 1)
			WAVE/SDFR=singleEventDFR/Z singleEvent = $GetIndexedObjNameDFR(singleEventDFR, COUNTOBJECTS_WAVES, i)
			ASSERT(WaveExists(singleEvent), "Non-existing single event wave")

			trace = GetTraceNamePrefix(idx)
			AppendToGraph/W=$extAllGraph/C=(eventColors[i][0], eventColors[i][1], eventColors[i][2], eventColors[i][3]) singleEvent/TN=$trace

			TUD_SetUserDataFromWaves(extAllGraph, trace,                                                                                                                                                                   \
			                         traceUserDataKeys,                                                                                                                                                                    \
			                         {num2str(psxEvent[i][%index]), num2str(psxEvent[i][%$"Fit manual QC call"]), num2str(psxEvent[i][%$"Event manual QC call"]), "0", PSX_TUD_TYPE_SINGLE, comboKey, num2str(comboIndex)})

			idx += 1
		endfor

		idx = PSX_AppendAverageTraces(extAllGraph, comboDFR, "", idx, comboKey, comboIndex, traceUserDataKeys, states, acceptColors, rejectColors, undetColors)
	endfor

	idx = PSX_AppendAverageTraces(extAllGraph, workDFR, PSX_GLOBAL_AVERAGE_SUFFIX, idx, PSX_TUD_AVERAGE_ALL_COMBO_KEY, PSX_TUD_AVERAGE_ALL_COMBO_INDEX, traceUserDataKeys, states, acceptColors, rejectColors, undetColors)
End

/// @brief Helper function to append the average traces to the all event graph
///
/// `traceSuffix` determines if the add the per-combo or the global average waves
static Function PSX_AppendAverageTraces(string extAllGraph, DFREF comboDFR, string traceSuffix, variable idx, string comboKey, variable comboIndex, WAVE traceUserDataKeys, WAVE states, WAVE acceptColors, WAVE rejectColors, WAVE undetColors)

	variable state
	string trace

	for(state : states)

		if(state == PSX_ALL)
			Make/FREE/N=4 colors = {1, 1, 1, 1}
		else
			Make/FREE/N=4 colors = PSX_SelectColor(state, acceptColors, rejectColors, undetColors)[p]
		endif

		WAVE average = GetPSXAverageWave(comboDFR, state)
		sprintf trace, "%s_%s%s%s", GetTraceNamePrefix(idx), NameOfWave(average), SelectString(IsFinite(comboIndex), "",  "_ComboIndex" + num2str(comboIndex)), traceSuffix

		// don't use any transparency for the average
		AppendToGraph/W=$extAllGraph/C=(colors[0], colors[1], colors[2]) average/TN=$trace

		TUD_SetUserDataFromWaves(extAllGraph, trace,                                                                              \
	   	                         traceUserDataKeys,                                                                               \
	   	                         {"NaN", num2str(state), num2str(state), "0", PSX_TUD_TYPE_AVERAGE, comboKey, num2str(comboIndex)})
	   	idx += 1
	endfor

	return idx
End

/// @brief Return the event index where cursor A is currently placed in the psx plot
///
/// @return event index of the current combination or NaN if there is no psx plot or valid cursor position
static Function PSX_GetCurrentEventIndex(string win)

	string psxGraph, info

	psxGraph = PSX_GetPSXGraph(win)
	info = PSX_GetCursorInfo(psxGraph)

	if(IsEmpty(info))
		return NaN
	endif

	return NumberByKey("POINT", info)
End

/// @brief Update the textbox in the single event graph
static Function PSX_UpdateSingleEventTextbox(string win, [variable eventIndex])

	string yUnit, trace, extSingleGraph, info, graph, str

	extSingleGraph = PSX_GetSingleEventGraph(win)

	if(!WindowExists(extSingleGraph))
		return NaN
	endif

	if(PSX_EventGraphSuppressUpdate(win))
		return NaN
	endif

	if(ParamIsDefault(eventIndex))
		eventIndex = PSX_GetCurrentEventIndex(win)

		if(IsNaN(eventIndex))
			return NaN
		endif
	endif

	trace = StringFromList(0, TraceNameList(extSingleGraph, ";", 0))
	WAVE wv = TraceNameToWaveRef(extSingleGraph, trace)
	yUnit = WaveUnits(wv, -1)

	if(IsEmpty(yUnit))
		yUnit = "NA"
	endif

	DFREF comboDFR = PSX_GetCurrentComboFolder(win)
	WAVE psxEvent = GetPSXEventWaveFromDFR(comboDFR)

	Make/FREE/T/N=(7, 2) input

	input[0][0] = {"Event State:", "Fit State:", "Event:", "Position:", "IsI:", "Amp (rel.):", "Tau:"}
	input[0][1] = {PSX_StateToString(psxEvent[eventIndex][%$"Event manual QC call"]), \
				   PSX_StateToString(psxEvent[eventIndex][%$"Fit manual QC call"]),   \
				   num2istr(eventIndex),                                              \
				   num2str(psxEvent[eventIndex][%dc_peak_time], "%8.02f") + " [ms]", \
				   num2str(psxEvent[eventIndex][%isi], "%8.02f") + " " + yUnit,      \
				   num2str(psxEvent[eventIndex][%i_amp], "%8.02f") + " " + yUnit,    \
				   num2str(psxEvent[eventIndex][%tau], "%8.02f") + " [ms]"}

	str = "\F'Consolas'" + FormatTextWaveForLegend(input)

	Textbox/W=$extSingleGraph/C/N=description/X=61/Y=-6/A=LB str
End

/// @brief Return the cursor info of cursor A from the psxGraph
///
/// Checks also that the cursor is on the expected trace
static Function/S PSX_GetCursorInfo(string psxGraph)

	string info, trace
	variable index

	info = CsrInfo(A, psxGraph)

	if(IsEmpty(info))
		return ""
	endif

	trace = StringByKey("TNAME", info)

	if(cmpstr(trace, PSX_CURSOR_TRACE))
		return ""
	endif

	return info
End

/// @brief Adjust the axis ranges of the psx graph so that the cursor is visible
///
/// @param win           window
/// @param leftIndex     event index to bring in axis range
/// @param constantWidth determine if the covered x-axis range should stay constant or not
/// @param rightIndex    [optional, defaults to none] additional event index to bring in x-axis range
static Function PSX_CenterCursor(string win, variable leftIndex, variable constantWidth, [variable rightIndex])

	variable left, right, leftBorder, rightBorder, range

	constantWidth = !!constantWidth

	if(ParamIsDefault(rightIndex))
		rightIndex = leftIndex
	else
		ASSERT(constantWidth == 0, "Can not be combined with constant width")
		ASSERT(rightIndex > leftIndex, "Invalid index ordering as rightIndex must be larger than leftIndex")
	endif

	DFREF comboDFR = PSX_GetCurrentComboFolder(win)

	WAVE refWave = GetPSXPeakXWaveFromDFR(comboDFR)

	leftBorder  = refWave[0] - PSX_PLOT_DEFAULT_X_RANGE / 2
	rightBorder = refWave[inf] + PSX_PLOT_DEFAULT_X_RANGE / 2

	// keep the x-axis range constant if requested
	if(constantWidth)
		GetAxis/Q/W=$win bottom
		range = V_max - V_min

		if(!IsFinite(range) || range == 0)
			range = PSX_PLOT_DEFAULT_X_RANGE
		endif
	else
		range = PSX_PLOT_DEFAULT_X_RANGE
	endif

	leftIndex  = limit(leftIndex, 0, DimSize(refWave, ROWS) - 1)
	rightIndex = limit(rightIndex, 0, DimSize(refWave, ROWS) - 1)

	left  = limit(refWave[leftIndex] - range/2, leftBorder, rightBorder)
	right = limit(refWave[rightIndex] + range/2, leftBorder, rightBorder)

	SetAxis/W=$win/A=0 bottom, left, right

	SetAxis/W=$win/A=2 leftFiltOff
	SetAxis/W=$win/A=2 leftFiltOffDeconv

	DoUpdate/W=$win
End

/// @brief Move the cursor A to the event `index + direction`
///
/// The window `win` can either be the `psx` graph or one of the `psxStats` graphs.
/// The function wraps around on both ends and selects the previous/next combo if required.
///
/// @return event index (clipped)
static Function PSX_MoveCursor(string win, string trace, variable index, variable direction)

	variable waveSize, comboIndex, numCombos, newComboIndex, minWrapAround, maxWrapAround
	string mainWindow

	DFREF comboDFR = PSX_GetCurrentComboFolder(win)

	WAVE/Z yWave = TraceNameToWaveRef(win, trace)
	ASSERT(WaveExists(yWave), "Missing wave for trace")

	waveSize = DimSize(yWave, ROWS)

	minWrapAround = direction < 0 && index == 0
	maxWrapAround = direction > 0 && index == (waveSize - 1)

	if(minWrapAround || maxWrapAround)

		DFREF workDFR = PSX_GetWorkingFolder(win)
		WAVE/DF/Z comboFolders = PSX_GetAllCombinationFolders(workDFR)
		ASSERT(WaveExists(comboFolders), "Missing comboFolders")

		comboIndex = PSX_GetCurrentComboIndex(win)
		numCombos = DimSize(comboFolders, ROWS)
		newComboIndex = mod(comboIndex + direction + numCombos, numCombos)

		mainWindow = GetMainWindow(win)
		PGC_SetAndActivateControl(mainWindow, "listbox_select_combo", val = newComboIndex)

		DoUpdate

		WAVE/Z yWave = TraceNameToWaveRef(win, trace)
		ASSERT(WaveExists(yWave), "Missing wave for trace")

		waveSize = DimSize(yWave, ROWS)

		if(minWrapAround)
			index = waveSize - 1
		elseif(maxWrapAround)
			index = 0
		endif

		PSX_MoveCursorHelper(win, trace, index)

		return index
	endif

	index = limit(index + direction, 0, waveSize - 1)
	PSX_MoveCursorHelper(win, trace, index)

	return index
End

Function PSX_MoveCursorHelper(string win, string trace, variable index)

	Cursor/W=$win/P A $trace index
End

/// @brief Move and center cursor
///
/// @sa PSX_MoveCursor
/// @sa PSX_CenterCursor
static Function PSX_MoveAndCenterCursor(string win, variable index, [variable direction, variable constantWidth])

	if(ParamIsDefault(direction))
		direction = 0
	else
		ASSERT(IsFinite(direction), "Invalid direction")
	endif

	if(ParamIsDefault(constantWidth))
		constantWidth = 1
	else
		ASSERT(IsFinite(constantWidth), "Invalid constantWidth")
	endif

	index = PSX_MoveCursor(win, PSX_CURSOR_TRACE, index, direction)

	PSX_CenterCursor(win, index, constantWidth)
	PSX_UpdateSingleEventGraph(win, index)
End

/// @brief Get the keyboard direction stored in user data in the psx graph
static Function PSX_GetKeyboardDirection(string psxGraph)
	return str2num(GetUserData(psxGraph, "", USER_DATA_KEYBOARD_DIR))
End

/// @brief Set the keyboard direction in user data in the psx graph
static Function PSX_SetKeyboardDirection(string psxGraph, variable direction)
	SetWindow $psxGraph, userdata($USER_DATA_KEYBOARD_DIR)=num2str(direction)
End

/// @brief Get the move direction as +/- 1 from the keyboard direction
static Function PSX_GetMoveDirection(string psxGraph)

	variable direction

	direction = PSX_GetKeyboardDirection(psxGraph)

	switch(direction)
		case PSX_KEYBOARD_DIR_RL:
			return -1
		case PSX_KEYBOARD_DIR_LR:
			return +1
		default:
			ASSERT(0, "Unsupported direction")
	endswitch
End

/// @brief Return the appropriate color wave for the given fit/event state
threadsafe static Function/WAVE PSX_SelectColor(variable state, WAVE acceptColors, WAVE rejectColors, WAVE undetColors)

	switch(state)
		case PSX_ACCEPT:
			return acceptColors
		case PSX_REJECT:
			return rejectColors
		case PSX_UNDET:
			return undetColors
		default:
			ASSERT_TS(0, "Invalid state")
	endswitch
End

/// @brief Return a marker for the given fit/event state
threadsafe static Function PSX_SelectMarker(variable state)

	switch(state)
		case PSX_ACCEPT:
			return PSX_MARKER_ACCEPT
		case PSX_REJECT:
			return PSX_MARKER_REJECT
		case PSX_UNDET:
			return PSX_MARKER_UNDET
		default:
			ASSERT_TS(0, "Invalid state")
	endswitch
End

/// @brief Update all event related waves
///
/// One of `val` or `toggle` has to be supplied.
///
/// If neither `index` nor `indizes` is supplied all event indizes are set.
///
/// @param win        window
/// @param val        [optional] new state, one of @ref PSXStates
/// @param index      [optional] event index to set
/// @param toggle     [optional] switch event state from accepted <-> rejected
/// @param indizes    [optional] event indizes to set
/// @param writeState [optional, defaults to true] set the event state itself
/// @param stateType  [optional, defaults to #PSX_STATE_EVENT] one of @ref PSXStateTypes
/// @param comboIndex [optional, defaults to listbox selection] select/range combination to update the events for
static Function PSX_UpdateEventWaves(string win, [variable val, variable index, variable toggle, WAVE/Z indizes, variable writeState, variable stateType, variable comboIndex])

	variable start, stop, idx, stateCol0, stateCol1, oldStateCol, checkCol0, checkCol1

	ASSERT(ParamIsDefault(val) + ParamIsDefault(toggle) == 1, "Expected exactly one of val/toggle.")

	if(ParamIsDefault(comboIndex))
		DFREF comboDFR = PSX_GetCurrentComboFolder(win)
	else
		DFREF workDFR = PSX_GetWorkingFolder(win)

		DFREF comboDFR = GetPSXFolderForCombo(workDFR, comboIndex)
	endif

	ASSERT(DataFolderExistsDFR(comboDFR), "Missing combo folder")

	if(ParamIsDefault(stateType))
		stateType = PSX_STATE_EVENT
	else
		ASSERT(stateType == PSX_STATE_EVENT || stateType == PSX_STATE_FIT || stateType == PSX_STATE_BOTH, "Invalid state type")
	endif

	if(ParamIsDefault(toggle))
		toggle = 0
	else
		toggle = !!toggle
	endif

	if(ParamIsDefault(writeState))
		writeState = 1
	else
		writeState = !!writeState
	endif

	if(ParamIsDefault(index) && ParamIsDefault(indizes))
		start = 0
		stop  = inf
	elseif(!ParamIsDefault(index))
		start = index
		stop  = index
	elseif(!ParamIsDefault(indizes))
		ASSERT(DimSize(indizes, COLS) <= 1, "Expected 1D wave")
		start = NaN
		stop  = NaN
	endif

	WAVE eventColors = GetPSXEventColorsWaveFromDFR(comboDFR)
	WAVE eventMarker = GetPSXEventMarkerWaveFromDFR(comboDFR)
	WAVE psxEvent   = GetPSXEventWaveFromDFR(comboDFR)

	// stateColX is the psxEvent column we want to read/write
	// checkColX denotes if there is a corresponding check column which
	// determines if the stateColX is allowed to be written. NaN if not available.
	switch(stateType)
		case PSX_STATE_EVENT:
			checkCol0   = NaN
			stateCol0   = FindDimLabel(psxEvent, COLS, "Event manual QC call")
			stateCol1   = NaN
			oldStateCol = stateCol0
			break
		case PSX_STATE_FIT:
			checkCol0   = FindDimLabel(psxEvent, COLS, "Fit result")
			stateCol0   = FindDimLabel(psxEvent, COLS, "Fit manual QC call")
			checkCol1   = NaN
			stateCol1   = NaN
			oldStateCol = stateCol0
			break
		case PSX_STATE_BOTH:
			checkCol0   = NaN
			stateCol0   = FindDimLabel(psxEvent, COLS, "Event manual QC call")
			checkCol1   = FindDimLabel(psxEvent, COLS, "Fit result")
			stateCol1   = FindDimLabel(psxEvent, COLS, "Fit manual QC call")
			oldStateCol = stateCol0
			break
		default:
			ASSERT(0, "Unknown state type")
	endswitch

	if(toggle)
		switch(psxEvent[index][oldStateCol])
			case PSX_UNDET:
				val = PSX_ACCEPT
				break
			case PSX_ACCEPT:
				val = PSX_REJECT
				break
			case PSX_REJECT:
				val = PSX_UNDET
				break
			default:
				ASSERT(0, "Unknown state")
		endswitch
	endif

	ASSERT(val == PSX_ACCEPT || val == PSX_REJECT || val == PSX_UNDET, "Invalid new event state")

	[WAVE acceptColors, WAVE rejectColors, WAVE undetColors] = PSX_GetEventColors()

	if(IsNaN(start) && IsNaN(stop))
		for(idx : indizes)
			if(writeState)

				if(IsNaN(checkCol0) || psxEvent[idx][checkCol0] == 1)
					psxEvent[idx][stateCol0] = val
				endif

				if(IsFinite(stateCol1))
					if(IsNaN(checkCol1) || psxEvent[idx][checkCol1] == 1)
						psxEvent[idx][stateCol1] = val
					endif
				endif
			endif

			Multithread eventColors[idx][] = PSX_SelectColor(psxEvent[p][%$"Event manual QC call"], acceptColors, rejectColors, undetColors)[q]
		endfor

		/// @todo Multithread does not work with index waves
		eventMarker[indizes] = PSX_SelectMarker(psxEvent[p][%$"Event manual QC call"])
	else
		if(writeState)
			psxEvent[start, stop][stateCol0] = (IsNaN(checkCol0) || psxEvent[p][checkCol0] == 1) ? val : psxEvent[p][stateCol0]

			if(IsFinite(stateCol1))
				psxEvent[start, stop][stateCol1] = (IsNaN(checkCol1) || psxEvent[p][checkCol1] == 1) ? val : psxEvent[p][stateCol1]
			endif
		endif

		Multithread eventMarker[start, stop]   = PSX_SelectMarker(psxEvent[p][%$"Event manual QC call"])
		MultiThread eventColors[start, stop][] = PSX_SelectColor(psxEvent[p][%$"Event manual QC call"], acceptColors, rejectColors, undetColors)[q]
	endif

	PSX_UpdateSingleEventTextbox(win)

	if(writeState)
		PSX_AdaptColorsInAllEventGraph(win)
	endif
End

/// @brief Return RGBA waves with the colors for the three event states
static Function [WAVE acceptColors, WAVE rejectColors, WAVE undetColors] PSX_GetEventColors()

	Make/FREE acceptColors = {PSX_COLOR_ACCEPT_R, PSX_COLOR_ACCEPT_G, PSX_COLOR_ACCEPT_B, 0.2 * 65535}
	Make/FREE rejectColors = {PSX_COLOR_REJECT_R, PSX_COLOR_REJECT_G, PSX_COLOR_REJECT_B, 0.2 * 65535}
	Make/FREE undetColors  = {PSX_COLOR_UNDET_R,  PSX_COLOR_UNDET_G,  PSX_COLOR_UNDET_B, 0.2 * 65535}
End

/// @brief Generate the unique combination key made up from `selectData` and `range`
///
/// This is used in the results wave, the listbox for selection and is attached
/// to the wave note of `psxEvent`.
static Function/S PSX_GenerateComboKey(string graph, WAVE selectData, WAVE range)

	variable sweepNo, channel, chanType
	string device, key, datafolder, rangeStr

	ASSERT(DimSize(selectData, ROWS) == 1, "Expected selectData with only one entry")

	sweepNo  = selectData[0][%SWEEP]
	channel  = selectData[0][%CHANNELNUMBER]
	chanType = selectData[0][%CHANNELTYPE]

	WAVE/T textualValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)

	// Introduced in 7e903ed8 (GetSweepSettingsTextWave: Add device as entry, 2023-01-03)
	device = GetLastSettingTextIndep(textualValues, sweepNo, "Device", DATA_ACQUISITION_MODE)

	if(IsEmpty(device))
		if(BSP_IsDataBrowser(graph))
			device = BSP_GetDevice(graph)
		else
			// datafolder looks like: root:MIES:Analysis:my_experiment:ITC18USB_Dev_0:labnotebook
			datafolder = GetWavesDataFolder(textualValues, 1)
			device = StringFromList(4, datafolder, ":")
		endif
	endif

	ASSERT(!IsEmpty(device), "Could not find the device of the given selectData")

	if(IsNumericWave(range))
		sprintf rangeStr, "%g, %g", range[0], range[1]
	elseif(IsTextWave(range))
		ASSERT(DimSize(range, ROWS) == 1, "Expected only a single epoch in the textual range")
		WAVE/T rangeText = range
		rangeStr = rangeText[0]
	else
		ASSERT(0, "Unexpected wave type")
	endif

	sprintf key, "Range[%s], Sweep [%d], Channel [%s%d], Device [%s]", rangeStr, sweepNo, StringFromList(chanType, XOP_CHANNEL_NAMES), channel, device
	ASSERT(strsearch(key, ":", 0) == -1, "Can't use a colon")

	return key
End

/// @brief Return a datafolder reference wave with all psx combination folders
static Function/WAVE PSX_GetAllCombinationFolders(DFREF workDFR)

	string list

	if(!DataFolderExistsDFR(workDFR))
		// no psx operation was executed
		return $""
	endif

	list = GetListOfObjects(workDFR, "^combo_[[:digit:]]+$", typeflag = COUNTOBJECTS_DATAFOLDER, fullPath = 1, exprType = MATCH_REGEXP)

	if(IsEmpty(list))
		return $""
	endif

	Make/FREE/DF/N=(ItemsInList(list)) folders = $StringFromList(p, list)

	return folders
End

/// @brief Return the psxEvent wave identified by `comboKey` from one of the psx combination folders
static Function/WAVE PSX_GetEventsFromDataFolder(string graph, string comboKey)

	string key, win

	win = SFH_GetFormulaGraphForBrowser(graph)

	if(IsEmpty(win))
		// no psx operation active
		return $""
	endif

	DFREF workDFR = PSX_GetWorkingFolder(win)

	WAVE/DF/Z comboFolders = PSX_GetAllCombinationFolders(workDFR)

	if(!WaveExists(comboFolders))
		return $""
	endif

	for(DFREF comboDFR : comboFolders)
		WAVE psxEvent = GetPSXEventWaveFromDFR(comboDFR)

		key = JWN_GetStringFromWaveNote(psxEvent, PSX_EVENTS_COMBO_KEY_WAVE_NOTE)
		if(!cmpstr(comboKey, key))
			// correct data
			return psxEvent
		endif
	endfor

	return $""
End

/// @brief Return the psxEvent wave from the results wave for the given comboKey
static Function/WAVE PSX_GetEventsFromResults(string comboKey)

	string entry, name

	WAVE/T textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)

	sprintf name, "Sweep Formula psx [%s]", comboKey

	entry = GetLastSettingTextIndep(textualResultsValues, NaN, name, SWEEP_FORMULA_PSX)

	if(IsEmpty(entry))
		// read old data from a development version with entry type UNKNOWN_MODE
		// and no wave reference wave stored but the data directly
		entry = GetLastSettingTextIndep(textualResultsValues, NaN, name, UNKNOWN_MODE)

		if(IsEmpty(entry))
			return $""
		endif

		WAVE/Z psxEvent = JSONToWave(entry)
	else
		WAVE/WAVE/Z container = JSONToWave(entry)
		ASSERT(WaveExists(container), "Could not parse stored results as JSON")
		ASSERT(DimSize(container, ROWS) == 1, "Expected exactly one element")
		WAVE/Z psxEvent = container[0]
	endif

	ASSERT(WaveExists(psxEvent), "Missing psxEvent")

	UpgradePSXEventWave(psxEvent)

	return psxEvent
End

/// @brief Return the psx graph
///
/// Searches all subwindows of `win`.
static Function/S PSX_GetPSXGraph(string win)

	string elem, ud, mainWindow

	mainWindow = GetMainWindow(win)
	WAVE/T windows = ListToTextWave(GetAllWindows(mainWindow), ";")

	for(elem : windows)

		ud = GetUserData(elem, "", PSX_USER_DATA_TYPE)
		if(!cmpstr(ud, PSX_USER_DATA_PSX))
			return elem
		endif
	endfor

	ASSERT(0, "Could not find an psx graph as part of the window hierarchy")
End

static Function/WAVE PSX_GetEventsInsideAxisRange(string win, string traceName, variable first, variable last, WAVE xCrds)
	WAVE data = TraceNameToWaveRef(win, traceName)

	Make/FREE/N=(DimSize(xCrds, ROWS)) subMatches = (data(xCrds[p]) >= first && data(xCrds[p]) <= last) ? p : NaN

	return subMatches
End

/// @brief Return the combo key from the combo datafolder
static Function/S PSX_GetComboKeyFromDFR(DFREF comboDFR)

	WAVE psxEvent = GetPSXEventWaveFromDFR(comboDFR)

	return JWN_GetStringFromWaveNote(psxEvent, PSX_EVENTS_COMBO_KEY_WAVE_NOTE)
End

static Function/WAVE PSX_GetSpecialEventPanelCheckboxes(string specialEventPanel)

	return ListToTextWave(ControlNameList(specialEventPanel, ";", "checkbox*"), ";")
End

/// @brief Store the PSX panel GUI state in the window user data of `browser`
static Function PSX_StoreGuiState(string win, string browser)

	variable jsonID, childID
	string specialEventPanel, mainWindow, ctrl, extAllGraph

	if(!WindowExists(browser))
		return NaN
	endif

	specialEventPanel = PSX_GetSpecialPanel(win)

	jsonID = JSON_New()

	JSON_SetVariable(jsonID, "/version", PSX_GUI_SETTINGS_VERSION)

	JSON_AddTreeObject(jsonID, "/specialEventPanel/axesRanges")
	JSON_AddTreeObject(jsonID, "/mainPanel")

	WAVE/T checkboxes = PSX_GetSpecialEventPanelCheckboxes(specialEventPanel)

	for(ctrl : checkboxes)
		JSON_SetVariable(jsonID, "/specialEventPanel/" + ctrl, GetCheckBoxState(specialEventPanel, ctrl))
	endfor

	JSON_SetVariable(jsonID, "/specialEventPanel/popupmenu_state_type", GetPopupMenuIndex(specialEventPanel, "popupmenu_state_type"))

	mainWindow = GetMainWindow(win)
	JSON_SetVariable(jsonID, "/mainPanel/checkbox_suppress_update", GetCheckBoxState(mainWindow, "checkbox_suppress_update"))
	JSON_SetVariable(jsonID, "/mainPanel/listbox_select_combo", GetListBoxSelRow(mainWindow, "listbox_select_combo"))

	extAllGraph = PSX_GetAllEventGraph(win)

	WAVE axesProps = GetAxesProperties(extAllGraph)
	childID = JSON_Parse(WaveToJSON(axesProps))
	JSON_AddTreeObject(jsonID, "/specialEventPanel/axesProps")
	JSON_SetJSON(jsonID, "/specialEventPanel/axesProps", childID)
	JSON_Release(childID)

	SetWindow $browser, userdata($PSX_GUI_SETTINGS_PSX)=JSON_Dump(jsonID)
	JSON_Release(jsonID)
End

/// @brief Restore the PSX panel GUI state from the window user data of `browser`
static Function PSX_RestoreGuiState(string win)

	string browser, specialEventPanel, mainWindow, ctrl, jsonDoc, extAllGraph
	variable jsonID, lastActiveCombo

	browser = SFH_GetBrowserForFormulaGraph(win)

	jsonDoc = GetUserData(browser, "", PSX_GUI_SETTINGS_PSX)
	jsonID = JSON_Parse(jsonDoc, ignoreErr = 1)

	if(IsNaN(jsonID))
		// no valid GUI settings found
		return NaN
	endif

	if(JSON_GetVariable(jsonID, "/version") != PSX_GUI_SETTINGS_VERSION)
		// stored data too old, ignore it
		return NaN
	endif

	specialEventPanel = PSX_GetSpecialPanel(win)

	WAVE/T controls = PSX_GetSpecialEventPanelCheckboxes(specialEventPanel)

	for(ctrl : controls)
		SetCheckBoxState(specialEventPanel, ctrl, JSON_GetVariable(jsonID, "/specialEventPanel/" + ctrl))
	endfor

	PGC_SetAndActivateControl(specialEventPanel, "popupmenu_state_type", val = JSON_GetVariable(jsonID, "/specialEventPanel/popupmenu_state_type"))

	mainWindow = GetMainWindow(win)
	SetCheckBoxState(mainWindow, "checkbox_suppress_update", JSON_GetVariable(jsonID, "/mainPanel/checkbox_suppress_update"))

	lastActiveCombo = JSON_GetVariable(jsonID, "/mainPanel/listbox_select_combo")

	DFREF workDFR = PSX_GetWorkingFolder(win)
	WAVE comboListBox = GetPSXComboListBox(workDFR)

	PGC_SetAndActivateControl(mainWindow, "listbox_select_combo", val = limit(lastActiveCombo,0, DimSize(comboListBox, ROWS) - 1))

	WAVE axesProps = JSONToWave(jsonDoc, path = "/specialEventPanel/axesProps")

	extAllGraph = PSX_GetAllEventGraph(win)

	SetAxesProperties(extAllGraph, axesProps)

	JSON_Release(jsonID)
End

/// @brief Return the currently in the listbox selected combination folder
static Function/DF PSX_GetCurrentComboFolder(string win)

	variable comboIndex
	string mainWindow

	mainWindow = GetMainWindow(win)

	if(!ControlExists(mainWindow, "listbox_select_combo"))
		return $""
	endif

	DFREF workDFR = PSX_GetWorkingFolder(mainWindow)
	comboIndex = PSX_GetCurrentComboIndex(mainWindow)

	return GetPSXFolderForCombo(workDFR, comboIndex)
End

/// @brief Return the current combo index as selected in the listbox
static Function PSX_GetCurrentComboIndex(string win)

	string mainWindow

	mainWindow = GetMainWindow(win)

	return GetListBoxSelRow(mainWindow, "listbox_select_combo")
End

/// @brief Return the combo index for the given comboKey
static Function PSX_GetComboIndexForComboKey(string win, string comboKey)

	variable i

	DFREF workDFR = PSX_GetWorkingFolder(win)

	WAVE/DF comboFolders = PSX_GetAllCombinationFolders(workDFR)

	for(DFREF comboDFR : comboFolders)

		if(!cmpstr(PSX_GetComboKeyFromDFR(comboDFR), comboKey))
			return i
		endif

		i += 1
	endfor

	ASSERT(0, "Could not find a combo folder")
End

/// @brief Return the combo index from the given comboDFR
///
/// The combo folder is created by GetPSXFolderForCombo()
static Function PSX_GetComboIndexFromDFR(DFREF comboDFR)

	string path, comboIndexStr
	variable comboIndex

	path = GetDataFolder(1, comboDFR)

	SplitString/E="combo_([[:digit:]]+):$" path, comboIndexStr
	ASSERT(V_Flag == 1, "Unexpected number of matches")

	comboIndex = str2num(comboIndexStr)
	ASSERT(IsInteger(comboIndex), "Expected an integer combo index")

	return comboIndex
End

/// @brief Write all psx data from results in the combination folders
///
/// Takes care of existing combination data due to other `psx` calls in the same code
static Function PSX_MoveWavesToDataFolders(DFREF workDFR, WAVE/WAVE/Z results, variable offset, variable numCombos)

	variable i, j, numEvents
	string key

	WAVE/Z/SDFR=workDFR psxAnalysis

	if(!WaveExists(psxAnalysis))
		MoveWave results[%psxAnalysis][1], workDFR:psxAnalysis
		WAVE/Z/SDFR=workDFR psxAnalysis
	else
		Concatenate/NP=(ROWS) {results[%psxAnalysis][1]}, psxAnalysis
	endif

	for(i = 0; i < numCombos; i += 1)

		DFREF dfr = GetPSXFolderForCombo(workDFR, offset + i)

		key = PSX_GenerateKey("sweepData", i)
		MoveWave results[%$key][1], dfr:sweepData
		WAVE/SDFR=dfr sweepData

		key = PSX_GenerateKey("sweepDataFiltOff", i)
		MoveWave results[%$key][1], dfr:sweepDataFiltOff
		WAVE/SDFR=dfr sweepDataFiltOff

		key = PSX_GenerateKey("sweepDataFiltOffDeconv", i)
		MoveWave results[%$key][1], dfr:sweepDataFiltOffDeconv
		WAVE/SDFR=dfr sweepDataFiltOffDeconv

		key = PSX_GenerateKey("peakX", i)
		MoveWave results[%$key][1], dfr:peakX
		WAVE/SDFR=dfr peakX

		key = PSX_GenerateKey("peakY", i)
		MoveWave results[%$key][1], dfr:peakY
		WAVE/SDFR=dfr peakY

		ASSERT(DimSize(peakX, ROWS) == DimSize(peakY, ROWS), "Mismatched peak sizes")

		key = PSX_GenerateKey("psxEvent", i)
		MoveWave results[%$key][1], dfr:psxEvent
		WAVE/SDFR=dfr psxEvent

		numEvents = DimSize(psxEvent, ROWS)

		key = PSX_GenerateKey("eventFit", i)
		MoveWave results[%$key][1], dfr:eventFit

		WAVE/SDFR=dfr eventFit

		WAVE eventColors = GetPSXEventColorsWaveAsFree(numEvents)
		MoveWave eventColors, dfr:eventColors

		WAVE eventMarker = GetPSXEventMarkerWaveAsFree(numEvents)
		MoveWave eventMarker, dfr:eventMarker

		Duplicate peakY, dfr:peakYAtFilt/WAVE=peakYAtFilt
		peakYAtFilt[] = sweepDataFiltOff(peakX[p])

		Make/T/N=(numEvents, 2) dfr:eventLocationLabels/WAVE=eventLocationLabels
		SetDimLabel COLS, 1, $"Tick Type", eventLocationLabels
		eventLocationLabels[][1] = "Major"

		Make/D/N=(numEvents) dfr:eventLocationTicks/WAVE=eventLocationTicks
		eventLocationTicks[] = peakX[p]

		PSX_CreateSingleEventWaves(dfr, psxEvent, sweepDataFiltOff)
	endfor
End

/// @brief Extract a single wave for each event from sweepDataFiltOff
static Function PSX_CreateSingleEventWaves(DFREF comboDFR, WAVE psxEvent, WAVE sweepDataFiltOff)

	variable i, numEvents, first, last, offset, eventOnset
	string name

	numEvents = DimSize(psxEvent, ROWS)

	DFREF singleEventDFR = GetPSXSingleEventFolder(comboDFR)

	for(i = 0; i < numEvents; i += 1)

		[first, last] = PSX_GetSingleEventRange(psxEvent, i)

		Duplicate/FREE/R=(first, last) sweepDataFiltOff, singleEvent
		// zero in x direction
		SetScale/P x, 0, DimDelta(singleEvent, ROWS), singleEvent

		// remove baseline from event onset position
		offset = sweepDataFiltOff(psxEvent[i][%dc_peak_time])
		MultiThread singleEvent[] = singleEvent[p] - offset

		Note/K singleEvent

		name = PSX_FormatSingleEventWaveName(i)

		MoveWave singleEvent, singleEventDFR:$name
	endfor
End

/// @brief Generate a wave name for single event waves
static Function/S PSX_FormatSingleEventWaveName(variable i)

	string name

	sprintf name, "SE%0*d", (ceil(log(PSX_MAX_NUM_EVENTS)) + 1), i

	return name
End

static Function PSX_EventGraphSuppressUpdate(string win)

	return GetCheckboxState(GetMainWindow(win), "checkbox_suppress_update") == 1
End

Function/S PSX_GetEventStateNames()

	return PSX_TUD_EVENT_STATE_KEY + ";" + PSX_TUD_FIT_STATE_KEY
End

/// @brief Create the PSX graph together with all subwindows (all event graph, single event graph)
///
/// This is only called for the very first `psx` operation output, subsequent
/// `psx` operation outputs are just added as additional combos.
static Function PSX_CreatePSXGraphAndSubwindows(string win, string graph, STRUCT SF_PlotMetaData &plotMetaData)

	string mainWin, extSubWin, extSingleGraph, extAllGraph

	mainWin = GetMainWindow(win)

	DFREF workDFR = PSX_GetWorkingFolder(win)
	DFREF comboDFR = GetPSXFolderForCombo(workDFR, 0)

	// make space on the left hand side
	DefineGuide/W=$mainWin customLeft = {FL, 0.15, FR}

	// add store button
	Button button_store,win=$mainWin,pos={16.00,16.00},size={50.00,20.00},proc=PSX_ButtonProc_StoreEvents
	Button button_store,win=$mainWin,title="Store"
	Button button_store,win=$mainWin,help={"Store the event data in the results wave and redo SweepFormula evaluation\rto update possible psxStats plots."}

	// and jump button
	Button button_jump_first_undet,win=$mainWin,pos={16.00,47.00},size={50.00,20.00},proc=PSX_ButtonProcJumpFirstUndet
	Button button_jump_first_undet,win=$mainWin,title="Jump"
	Button button_jump_first_undet,win=$mainWin,help={"Jump to the first event with undetermined state"}

	// add suppress event graph update checkbox
	CheckBox checkbox_suppress_update,win=$mainWin,pos={23.00,81.00},size={40.00,15.00},proc=PSX_CheckboxProcSuppressUpdate
	CheckBox checkbox_suppress_update,win=$mainWin,value=0,title="Suppress Update",help={"Suppress updating the single/all event graphs on state changes"}

	Button button_psx_info,win=$mainWin,pos={76.00,18.00},size={19.00,19.00},title="i",proc=PSX_CopyHelpToClipboard

	WAVE combos = GetPSXComboListBox(workDFR)
	ListBox listbox_select_combo,win=$mainWin,pos={16.00,108.00},size={108.00,341.00},proc=PSX_ListBoxSelectCombo
	ListBox listbox_select_combo,win=$mainWin,mode=2,selRow=0,listWave=combos,helpWave=combos

	WAVE peakX                  = GetPSXPeakXWaveFromDFR(comboDFR)
	WAVE peakY                  = GetPSXPeakYWaveFromDFR(comboDFR)
	WAVE peakYAtFilt            = GetPSXPeakYAtFiltWaveFromDFR(comboDFR)
	WAVE sweepData              = GetPSXSweepDataWaveFromDFR(comboDFR)
	WAVE sweepDataFiltOff       = GetPSXSweepDataFiltOffWaveFromDFR(comboDFR)
	WAVE sweepDataFiltOffDeconv = GetPSXSweepDataFiltOffDeconvWaveFromDFR(comboDFR)

	[STRUCT RGBColor color] = SF_GetTraceColor(graph, plotMetaData.opStack, sweepData)

	AppendToGraph/W=$win/C=(color.red, color.green, color.blue)/L=leftFiltOff sweepDataFiltOff
	AppendToGraph/W=$win/L=leftFiltOff peakYAtFilt vs peakX

	AppendToGraph/W=$win/C=(color.red, color.green, color.blue)/L=leftFiltOffDeconv sweepDataFiltOffDeconv
	AppendToGraph/W=$win/L=leftFiltOffDeconv peakY vs peakX

	ModifyGraph/W=$win msize(peakY)=10, msize(peakYAtFilt)=10

	ModifyGraph/W=$win axisEnab(leftFiltOff)={0.51,1},lblPos(leftFiltOff)=70,freePos(leftFiltOff)=0
	ModifyGraph/W=$win axisEnab(leftFiltOffDeconv)={0,0.49},lblPos(leftFiltOffDeconv)=70,freePos(leftFiltOffDeconv)=0

	PSX_MarkGraphForPSX(win)

	WAVE eventLocationLabels = GetPSXEventLocationLabels(comboDFR)
	WAVE eventLocationTicks = GetPSXEventLocationTicks(comboDFR)
	WAVE eventColors = GetPSXEventColorsWaveFromDFR(comboDFR)
	WAVE eventMarker = GetPSXEventMarkerWaveFromDFR(comboDFR)

	NewFreeAxis/W=$win/O/T eventLocAxis
	ModifyFreeAxis/W=$win/Z eventLocAxis,master=bottom
	ModifyGraph/W=$win grid(eventLocAxis)=1
	ModifyGraph/W=$win tick(eventLocAxis)=3
	ModifyGraph/W=$win lblPos(eventLocAxis)=43
	ModifyGraph/W=$win noLabel(eventLocAxis)=2
	ModifyGraph/W=$win freePos(eventLocAxis)={0,kwFraction}
	Label/W=$win eventLocAxis "\\u#2"

	ModifyGraph/W=$win zColor(peakYAtFilt)={eventColors,*,*,directRGB,0}
	ModifyGraph/W=$win mode(peakYAtFilt)=3
	ModifyGraph/W=$win zmrkNum(peakYAtFilt)={eventMarker}

	ModifyGraph/W=$win zColor(peakY)={eventColors,*,*,directRGB,0}
	ModifyGraph/W=$win mode(peakY)=3
	ModifyGraph/W=$win zmrkNum(peakY)={eventMarker}

	HideInfo/W=$mainWin
	SetWindow $mainWin, hook(ctrl)=PSX_PlotInteractionHook

	// special event panel
	NewPanel/HOST=$mainWin/EXT=3/W=(0,250,900,0)/N=$PSX_SPECIAL_EVENT_PANEL/K=2 as " "
	ASSERT(!cmpstr(PSX_SPECIAL_EVENT_PANEL, S_name), "Invalid name")
	extSubWin = PSX_GetSpecialPanel(mainWin)
	SetWindow $extSubWin hook(resetScaling)=IH_ResetScaling

	// set the active subwindow so that we can C&P the control code below which does not have a win statement
	SetActiveSubwindow $extSubWin

	CheckBox checkbox_single_events_accept,pos={11.00,7.00},size={53.00,15.00},proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_single_events_accept,title="Accept"
	CheckBox checkbox_single_events_accept,help={"Show accepted events in all events plot"}
	CheckBox checkbox_single_events_accept,value=1
	CheckBox checkbox_single_events_reject,pos={11.00,30.00},size={48.00,15.00},proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_single_events_reject,title="Reject"
	CheckBox checkbox_single_events_reject,help={"Show rejected events in all events plot"}
	CheckBox checkbox_single_events_reject,value=1
	CheckBox checkbox_single_events_undetermined,pos={11.00,54.00},size={48.00,15.00},proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_single_events_undetermined,title="Undet"
	CheckBox checkbox_single_events_undetermined,help={"Show undetermined events in all events plot"}
	CheckBox checkbox_single_events_undetermined,value=1
	GroupBox group_average,pos={7.00,69.00},size={77.00,123.00},title="Average"
	GroupBox group_average,help={"Toggle the display of the average traces"}
	CheckBox checkbox_average_events_undetermined,pos={20.00,128.00},size={48.00,15.00},proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_average_events_undetermined,title="Undet"
	CheckBox checkbox_average_events_undetermined,help={"Show average of the undetermined events in all events plot"}
	CheckBox checkbox_average_events_undetermined,value=0
	CheckBox checkbox_average_events_reject,pos={20.00,109.00},size={48.00,15.00},proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_average_events_reject,title="Reject"
	CheckBox checkbox_average_events_reject,help={"Show average of the rejected events in all events plot"}
	CheckBox checkbox_average_events_reject,value=0
	CheckBox checkbox_average_events_accept,pos={20.00,89.00},size={53.00,15.00},proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_average_events_accept,title="Accept"
	CheckBox checkbox_average_events_accept,help={"Show average of the accepted events in all events plot"}
	CheckBox checkbox_average_events_accept,value=0
	CheckBox checkbox_average_events_all,pos={20.00,148.00},size={30.00,15.00},proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_average_events_all,title="All"
	CheckBox checkbox_average_events_all,help={"Show average of all events in all events graph"}
	CheckBox checkbox_average_events_all,value=0
	CheckBox checkbox_restrict_events_to_current_combination,pos={11.00,190.00},size={56.00,30.00},proc=PSX_CheckboxProcAllEventPlotUpdate
	CheckBox checkbox_restrict_events_to_current_combination,title="Current\rcombo"
	CheckBox checkbox_restrict_events_to_current_combination,help={"Show event traces from only the current combination (checked) instead of all combinations (unchecked).\r The current combination can be set in the ListBox below."}
	CheckBox checkbox_restrict_events_to_current_combination,value=0
	PopupMenu popupmenu_state_type,pos={6.00,223.00},size={80.00,19.00},proc=PSX_PopupMenuState
	PopupMenu popupmenu_state_type,mode=1,popvalue="Event State",value=#"PSX_GetEventStateNames()"

	ModifyPanel/W=$extSubWin fixedSize=0

	DefineGuide/W=$extSubWin leftMenu = {FL, 0.10, FR}
	DefineGuide/W=$extSubWin horizCenter = {leftMenu, 0.5, FR}

	// single events view
	Display/FG=(horizCenter,FT,FR,FB)/HOST=$extSubWin/N=$PSX_SINGLE_EVENT_SUB_GRAPH
	ASSERT(!cmpstr(PSX_SINGLE_EVENT_SUB_GRAPH, S_name), "Invalid name")
	extSingleGraph = PSX_GetSingleEventGraph(mainWin)

	ModifyGraph/W=$extSingleGraph margin(right)=220
	AppendToGraph/W=$extSingleGraph/C=(color.red, color.green, color.blue) sweepDataFiltOff

	AppendToGraph/W=$extSingleGraph peakYAtFilt vs peakX
	SetAxis/A=2/W=$extSingleGraph left

	ModifyGraph/W=$extSingleGraph zColor(peakYAtFilt)={eventColors,*,*,directRGB,0}
	ModifyGraph/W=$extSingleGraph mode(peakYAtFilt)=3
	ModifyGraph/W=$extSingleGraph zmrkNum(peakYAtFilt)={eventMarker}
	ModifyGraph/W=$extSingleGraph msize(peakYAtFilt)=10

	WAVE singleEventFit = GetPSXSingleEventFitWaveFromDFR(comboDFR)
	AppendToGraph/W=$extSingleGraph singleEventFit

	// all events view
	Display/FG=(leftMenu,FT,horizCenter,FB)/HOST=$extSubWin/N=$PSX_ALL_EVENT_SUB_GRAPH
	ASSERT(!cmpstr(PSX_ALL_EVENT_SUB_GRAPH, S_name), "Invalid name")
	extAllGraph = PSX_GetAllEventGraph(mainWin)
	TUD_Init(extAllGraph)

	SetWindow $extSubWin, hook(ctrl)=PSX_AllEventGraphHook
End

/// @brief Mark `win` as being an psx graph
static Function PSX_MarkGraphForPSX(string win)

	SetWindow $win, userData($PSX_USER_DATA_TYPE) = PSX_USER_DATA_PSX
End

/// @brief Apply plot properties which have to be reapplied on every combo index change
static Function PSX_ApplySpecialPlotProperties(string win, WAVE eventLocationTicks, WAVE eventLocationLabels)

	ModifyGraph/W=$win userticks(eventLocAxis)={eventLocationTicks, eventLocationLabels}

	if(PSX_GetRestrictEventsToCurrentCombo(win))
		PSX_AdaptColorsInAllEventGraph(win, forceAverageUpdate = 1)
		PSX_UpdateHideStateInAllEventGraph(win)
	endif
End

/// @brief Read the user JWN from results and create a legend from all operation parameters
static Function PSX_AddLegend(string win, WAVE/WAVE results)

	variable jsonID, value, type, i, j, numOperations, numParameters
	string line, op, param, prefix, opNice, mainWindow, jsonPathOp, jsonPathParam, htmlStr
	string str = ""
	string sep = ", "

	jsonID = JWN_GetWaveNoteAsJSON(results)

	Make/T/FREE/N=(1, 0) input

	WAVE/T operations = JSON_GetKeys(jsonID, SF_META_USER_GROUP + PSX_JWN_PARAMETERS)
	numOperations = DimSize(operations, ROWS)

	Redimension/N=(-1, numOperations) input

	for(i = 0; i < numOperations; i += 1)
		op = operations[i]
		opNice = op + ": "

		jsonPathOp = SF_META_USER_GROUP + PSX_JWN_PARAMETERS + "/" + op
		WAVE/T parameters = JSON_GetKeys(jsonID, jsonPathOp)
		numParameters = DimSize(parameters, ROWS)

		Redimension/N=(max(DimSize(input, ROWS), numParameters), -1) input

		for(j = 0; j < numParameters; j += 1)
			param = parameters[j]

			if(j == 0)
				prefix = opNice
			else
				prefix = PadString("", strlen(opNice), 0x20)
			endif

			jsonPathParam = jsonPathOp + "/" + param
			type = JSON_GetType(jsonID, jsonPathParam)

			switch(type)
				case JSON_NUMERIC:
					value = JSON_GetVariable(jsonID, jsonPathParam)
					sprintf line, "%s: %g", param, value
					break
				case JSON_ARRAY:
					WAVE/T/Z wvText = JSON_GetTextWave(jsonID, jsonPathParam, ignoreErr = 1)
					if(WaveExists(wvText))
						str = TextWaveToList(wvText, sep)
						WaveClear wvText
					else
						WAVE wv = JSON_GetWave(jsonID, jsonPathParam)
						ASSERT(IsNumericWave(wv), "Expected numeric wave")
						str = NumericWaveToList(wv, sep)
						WaveClear wv
					endif

					sprintf line, "%s: %s", param, RemoveEnding(str, ", ")
					break
				default:
					ASSERT(0, "Unsupported type")
			endswitch

			input[j][i] = prefix + line
		endfor
	endfor

	JSON_Release(jsonID)

	str = FormatTextWaveForLegend(input)
	htmlStr = "<pre>" + str + "</pre>"

	mainWindow = GetMainWindow(win)
	// use the unnamed userdata here as that is passed into the GUI control procedure
	// see PSX_CopyHelpToClipboard
	Button button_psx_info win=$mainWindow,help={htmlStr},userdata=str
End

/// @brief Return the current event and combo index
///
/// @param win window, can be an `psx` graph or an `psxStats` graph.
static Function [variable eventIndex, variable waveIndex, variable comboIndex] PSX_GetCurrentEventIndexAndComboIndex(string win)

	string psxGraph, info, trace
	variable idx, yPointNumber

	psxGraph = PSX_GetPSXGraph(win)

	if(!cmpstr(win, psxGraph))
		idx = PSX_GetCurrentEventIndex(psxGraph)
		return [idx, idx, PSX_GetCurrentComboIndex(win)]
	endif

	// other graph, most likely psxStats plot

	if(WinType(win) != WINTYPE_GRAPH)
		return [NaN, NaN, NaN]
	endif

	info = CsrInfo(A, win)

	if(IsEmpty(info))
		return [NaN, NaN, NaN]
	endif

	trace = StringByKey("TNAME", info)

	if(IsEmpty(trace))
		return [NaN, NaN, NaN]
	endif

	yPointNumber = NumberByKey("POINT", info)

	if(IsNaN(yPointNumber))
		return [NaN, NaN, NaN]
	endif

	WAVE/Z yWave = TraceNameToWaveRef(win, trace)

	if(!WaveExists(yWave))
		return [NaN, NaN, NaN]
	endif

	WAVE/Z xWave = XWaveRefFromTrace(win, trace)

	if(!WaveExists(xWave))
		return [NaN, NaN, NaN]
	endif

	WAVE/T comboKeys = JWN_GetTextWaveFromWaveNote(yWave, SF_META_USER_GROUP + PSX_JWN_COMBO_KEYS_NAME)

	eventIndex = xWave[yPointNumber]
	comboIndex = PSX_GetComboIndexForComboKey(win, comboKeys[yPointNumber])

	return [eventIndex, yPointNumber, comboIndex]
End

/// @brief Window hook responsible for keyboard and mouse support
///
/// Works with `psx` and `psxStats` graphs.
Function PSX_PlotInteractionHook(STRUCT WMWinHookStruct &s)

	variable direction, pntIndex, loc, comboIndex, keyboardDir, waveIndex
	string psxGraph, info, msg, browser, win, mainWindow, trace

	switch(s.eventCode)
		case 7: // cursor moved

			if(cmpstr(s.cursorName, "A"))
				// not our cursor
				break
			endif

			win = s.winName
			pntIndex = s.pointNumber

			psxGraph = PSX_GetPSXGraph(win)

			if(!cmpstr(win, psxGraph))
				PSX_UpdateSingleEventGraph(psxGraph, pntIndex)
			else
				[pntIndex, waveIndex, comboIndex] = PSX_GetCurrentEventIndexAndComboIndex(win)

				if(IsNaN(pntIndex) || IsNaN(waveIndex) || IsNaN(comboIndex))
					break
				endif

				if(PSX_GetCurrentComboIndex(win) != comboIndex)
					mainWindow = GetMainWindow(win)
					PGC_SetAndActivateControl(mainWindow, "listbox_select_combo", val = comboIndex)
				endif

				PSX_MoveAndCenterCursor(psxGraph, pntIndex)

				trace = StringByKey("TNAME", CsrInfo(A, win))

				// x-coordinates are not unique in a stats graph as we can have multiple combos
				PSX_MoveCursor(win, trace, waveIndex, 0)
			endif

			return 1
		case 11: // keyboard event

			win = s.winName

			// workaround IP bug where the currently selected graph is not in s.winName
			GetWindow $win activeSW
			win = S_value

			psxGraph = PSX_GetPSXGraph(win)

			[pntIndex, waveIndex, comboIndex] = PSX_GetCurrentEventIndexAndComboIndex(win)

			if(IsNaN(pntIndex) || IsNaN(waveIndex) || IsNaN(comboIndex))
				break
			endif

			if(PSX_GetCurrentComboIndex(win) != comboIndex)
				mainWindow = GetMainWindow(win)
				PGC_SetAndActivateControl(mainWindow, "listbox_select_combo", val = comboIndex)
				PSX_MoveAndCenterCursor(psxGraph, waveIndex)
			endif

			direction = PSX_ReactToKeyPress(psxGraph, s.keyCode, comboIndex, pntIndex, waveIndex, moveCursor = 1)

			if(cmpstr(win, psxGraph) && direction != 0)
				trace = StringByKey("TNAME", CsrInfo(A, win))

				if(!IsEmpty(trace))
					PSX_MoveCursor(win, trace, waveIndex, direction)
				endif
			endif

			return 1
		case 5: // mouse up
			win = s.winName

			if(WinType(win) != WINTYPE_GRAPH)
				break
			endif

			// psxGraph
			if((s.eventMod & WINDOW_HOOK_EMOD_CTRLKEYDOWN) == WINDOW_HOOK_EMOD_CTRLKEYDOWN)
				DEBUGPRINT("Left mouse click and CTRL")

				psxGraph = PSX_GetPSXGraph(win)

				DFREF comboDFR = PSX_GetCurrentComboFolder(psxGraph)

				WAVE peakX = GetPSXPeakXWaveFromDFR(comboDFR)

				loc = AxisValFromPixel(psxGraph, "bottom", s.mouseLoc.h)

				FindValue/V=(loc)/T=(1) peakX
				if(V_row >= 0)
					PSX_UpdateEventWaves(psxGraph, toggle = 1, index = V_row)
				endif
			endif

			return 1
		case 17: // killVote
			win = s.winName
			browser = SFH_GetBrowserForFormulaGraph(s.winName)
			PSX_StoreGuiState(win, browser)
			return 0
	endswitch

	return 0
End

Function PSX_AllEventGraphHook(STRUCT WMWinHookStruct &s)

	string win, extAllGraph, trace, info
	variable comboIndex, eventIndex, isHidden

	switch(s.eventCode)
		case 11: // keyboard event
			win         = s.winName
			extAllGraph = PSX_GetAllEventGraph(win)

			info = TraceFromPixel(s.mouseloc.h, s.mouseloc.v, "WINDOW:" + extAllGraph)

			if(IsEmpty(info))
				break
			endif

			trace = StringByKey("TRACE", info)

			WAVE/T tud = TUD_GetAllUserData(extAllGraph, trace)
			isHidden = !!str2num(tud[%$PSX_TUD_TRACE_HIDDEN_KEY])

			if(isHidden)
				break
			endif

			comboIndex = str2num(tud[%$PSX_TUD_COMBO_INDEX])
			eventIndex = str2num(tud[%$PSX_TUD_EVENT_INDEX_KEY])

			if(IsNaN(comboIndex) || IsNaN(eventIndex))
				// average wave, don't do anything
				break
			endif

			PSX_ReactToKeyPress(extAllGraph, s.keyCode, comboIndex, eventIndex, eventIndex)

			return 1
			break
	endswitch
End

/// @brief React to keyboard presses
///
/// @return Return the direction of cursor movement (+1/-1) or 0 if the cursor was not moved
static Function PSX_ReactToKeyPress(string win, variable keyCode, variable comboIndex, variable eventIndex, variable waveIndex, [variable moveCursor])

	variable direction, keyboardDir
	string psxGraph

	if(ParamIsDefault(moveCursor))
		moveCursor = 0
	else
		moveCursor = !!moveCursor
	endif

	switch(keycode)
		case LEFT_KEY:
			DEBUGPRINT("left")

			if(moveCursor)
				direction = -1
				PSX_MoveAndCenterCursor(win, waveIndex, direction = direction)
			endif
			break
		case RIGHT_KEY:
			DEBUGPRINT("right")

			if(moveCursor)
				direction = +1
				PSX_MoveAndCenterCursor(win, waveIndex, direction = direction)
			endif
			break
		case UP_KEY:
			DEBUGPRINT("up")

			PSX_UpdateEventWaves(win, val = PSX_ACCEPT, index = eventIndex, stateType = PSX_STATE_BOTH, comboIndex = comboIndex)

			if(moveCursor)
				psxGraph = PSX_GetPSXGraph(win)
				direction = PSX_GetMoveDirection(psxGraph)
				PSX_MoveAndCenterCursor(win, waveIndex, direction = direction)
			endif

			break
		case DOWN_KEY:
			DEBUGPRINT("down")

			if(moveCursor)
				psxGraph = PSX_GetPSXGraph(win)
				direction = PSX_GetMoveDirection(psxGraph)
				PSX_MoveAndCenterCursor(win, waveIndex, direction = direction)
			endif

			PSX_UpdateEventWaves(win, val = PSX_REJECT, index = eventIndex, stateType = PSX_STATE_BOTH, comboIndex = comboIndex)

			break
		case SPACE_KEY:
			DEBUGPRINT("space")

			PSX_UpdateEventWaves(win, toggle = 1, index = eventIndex, stateType = PSX_STATE_BOTH, comboIndex = comboIndex)
			break
		case C_KEY:
			DEBUGPRINT("center (c)")

			if(moveCursor)
				PSX_CenterCursor(win, waveIndex, 1)
			endif
			break
		case E_KEY:
			DEBUGPRINT("toggle event state (e)")

			PSX_UpdateEventWaves(win, toggle = 1, index = eventIndex, stateType = PSX_STATE_EVENT, comboIndex = comboIndex)
			break
		case F_KEY:
			DEBUGPRINT("toggle fit state (f)")

			PSX_UpdateEventWaves(win, toggle = 1, index = eventIndex, stateType = PSX_STATE_FIT, comboIndex = comboIndex)
			break
		case R_KEY:
			DEBUGPRINT("reverse direction (c)")

			if(moveCursor)
				keyboardDir = PSX_GetKeyboardDirection(win)

				switch(keyboardDir)
					case PSX_KEYBOARD_DIR_RL:
						keyboardDir = PSX_KEYBOARD_DIR_LR
						break
					case PSX_KEYBOARD_DIR_LR:
						keyboardDir = PSX_KEYBOARD_DIR_RL
						break
					default:
						ASSERT(0, "Unknown direction")
				endswitch

				PSX_SetKeyboardDirection(win, keyboardDir)
			endif
			break
		case Z_KEY:
			DEBUGPRINT("accept event and fail fit (z)")

			PSX_UpdateEventWaves(win, val = PSX_ACCEPT, index = eventIndex, stateType = PSX_STATE_EVENT, comboIndex = comboIndex)
			PSX_UpdateEventWaves(win, val = PSX_REJECT, index = eventIndex, stateType = PSX_STATE_FIT, comboIndex = comboIndex)
			break
		default:
			// unsupported key
			break
	endswitch

	return direction
End

/// @brief Return a free text wave with all combo keys
Function/WAVE PSX_CreateCombinationsListBoxWaveAsFree(DFREF workDFR)

	WAVE/DF comboFolders = PSX_GetAllCombinationFolders(workDFR)

	Make/T/N=(DimSize(comboFolders, ROWS))/FREE wv = PSX_GetComboKeyFromDFR(comboFolders[p])

	return wv
End

/// @brief High-level function responsible for `psx` data and plot management
Function PSX_Plot(string win, string graph, WAVE/WAVE/Z results, STRUCT SF_PlotMetaData &plotMetaData)

	variable numCombos, i, offset, firstOp

	if(!WaveExists(results))
		return NaN
	endif

	DFREF workDFR = PSX_GetWorkingFolder(win)

	if(!DataFolderExistsDFR(workDFR))
		firstOp = 1
		DFREF sweepFormulaDFR = SFH_GetWorkingDF(graph)
		DFREF workDFR = UniqueDataFolder(sweepFormulaDFR, "psx")
		BSP_SetFolder(win, workDFR, PSX_USER_DATA_WORKING_FOLDER)
	else
		WAVE comboFolders = PSX_GetAllCombinationFolders(workDFR)
		offset = DimSize(comboFolders, ROWS)
	endif

	numCombos = (DimSize(results, ROWS) - 1) / PSX_OPERATION_OUTPUT_WAVES_PER_ENTRY
	ASSERT(IsInteger(numCombos), "Invalid number of input sets")

	if(!numCombos)
		// nothing to do
		return NaN
	endif

	PSX_MoveWavesToDataFolders(workDFR, results, offset, numCombos)

	// write, and possibly fetch, the initial event/fit states
	for(i = 0; i <  numCombos ; i += 1)
		PSX_UpdateEventWaves(win, val = PSX_ACCEPT, writeState = 0, comboIndex = offset + i)
	endfor

	if(firstOp)
		PSX_CreatePSXGraphAndSubwindows(win, graph, plotMetaData)

		PSX_AddLegend(win, results)
	else
		WAVE combos = GetPSXComboListBox(workDFR)
		WAVE updatedCombos = PSX_CreateCombinationsListBoxWaveAsFree(workDFR)

		Duplicate/O updatedCombos, combos
	endif
End

/// @brief Init the psx plot after filling it with data
Function PSX_PostPlot(string win)

	DFREF workDFR = PSX_GetWorkingFolder(win)
	WAVE/DF/Z comboFolders = PSX_GetAllCombinationFolders(workDFR)

	if(!WaveExists(comboFolders))
		return NaN
	endif

	PSX_SetKeyboardDirection(win, PSX_KEYBOARD_DIR_LR)

	PSX_MoveAndCenterCursor(win, 0, constantWidth = 0)

	PSX_AppendTracesToAllEventGraph(win)

	PSX_RestoreGuiState(win)

	PSX_UpdateHideStateInAllEventGraph(win)

	PSX_AdaptColorsInAllEventGraph(win, forceAverageUpdate = 1)

	DFREF comboDFR = PSX_GetCurrentComboFolder(win)
	WAVE eventLocationLabels = GetPSXEventLocationLabels(comboDFR)
	WAVE eventLocationTicks = GetPSXEventLocationTicks(comboDFR)

	PSX_ApplySpecialPlotProperties(win, eventLocationTicks, eventLocationLabels)
End

/// @brief Implementation of the `psx` operation
///
// Returns a SweepFormula dataset with n * PSX_OPERATION_OUTPUT_WAVES_PER_ENTRY + 1
// entries where n denotes the number of range/channel/sweep combinations
//
// Output[0] = sweepData(0)
// Output[1] = sweepDataFiltOff(0)
// Output[2] = sweepDataFiltOffDeconv(0)
// Output[3] = peakX(0)
// Output[4] = peakY(0)
// Output[5] = psxEvent(0)
// Output[6] = psxFit(0)
// Output[0] = sweepData(1)
// Output[1] = sweepDataFiltOff(1)
// ...
// Output[x] = psxAnalysis
Function/WAVE PSX_Operation(variable jsonId, string jsonPath, string graph)

	variable peakThresh, filterLow, filterHigh, kernelParameterJSONid, numCombos, i, writeIndex, readIndex, addedData, kernelAmp
	string parameterPath

	WAVE/WAVE psxKernelDataset = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, SF_OP_PSX, 0,  defOp = "psxKernel()")

	try
		peakThresh  = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_PSX, 1, defValue = 0.01)
		filterLow   = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_PSX, 2, defValue = PSX_DEFAULT_FILTER_LOW)
		filterHigh  = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_PSX, 3, defValue = PSX_DEFAULT_FILTER_HIGH)

		numCombos = DimSize(psxKernelDataset, ROWS) / PSX_KERNEL_OUTPUTWAVES_PER_ENTRY
		ASSERT(IsInteger(numCombos) && numCombos > 0, "Invalid number of input sets from psxKernel()")

		WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_PSX, numCombos * PSX_OPERATION_OUTPUT_WAVES_PER_ENTRY + 1)

		WAVE psxAnalysis = GetPSXAnalysisWaveAsFree()
		EnsureLargeEnoughWave(psxAnalysis, indexShouldExist = numCombos)

		kernelAmp = JWN_GetNumberFromWaveNote(psxKernelDataset, SF_META_USER_GROUP + PSX_JWN_PARAMETERS + "/" + SF_OP_PSX_KERNEL + "/amp")
		ASSERT(IsFinite(kernelAmp), "psxKernel amplitude must be finite")

		for(i = 0; i < numCombos; i += 1)
			readIndex = i
			addedData = PSX_OperationImpl(graph, psxKernelDataset, peakThresh, filterLow, filterHigh, kernelAmp, readIndex, writeIndex, output, psxAnalysis)
			writeIndex += addedData
		endfor

		Redimension/N=(writeIndex * PSX_OPERATION_OUTPUT_WAVES_PER_ENTRY + 1) output
		Redimension/N=(writeIndex, -1), psxAnalysis
	catch
		if(WaveExists(output))
			SFH_CleanUpInput(output)
		endif

		SFH_CleanUpInput(psxKernelDataset)
		Abort
	endtry

	SetDimensionLabels(output, "psxAnalysis", ROWS, startPos = writeIndex * PSX_OPERATION_OUTPUT_WAVES_PER_ENTRY)
	output[%psxAnalysis] = psxAnalysis

	// set PSXkernel parameters as initial JSON wave note
	kernelParameterJSONid = JWN_GetWaveNoteAsJSON(psxKernelDataset)
	SFH_CleanUpInput(psxKernelDataset)

	JWN_SetWaveNoteFromJSON(output, kernelParameterJSONid)
	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_PSX)
	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_PSX, ""))

	parameterPath = SF_META_USER_GROUP + PSX_JWN_PARAMETERS + "/" + SF_OP_PSX
	JWN_CreatePath(output, parameterPath)
	JWN_SetNumberInWaveNote(output, parameterPath + "/peakThres", peakThresh)
	JWN_SetNumberInWaveNote(output, parameterPath + "/filterLow", filterLow)
	JWN_SetNumberInWaveNote(output, parameterPath + "/filterHigh", filterHigh)

	return SFH_GetOutputForExecutor(output, graph, SF_OP_PSX)
End

/// @brief Implementation of the `psxKernel` operation
///
// Returns a SweepFormula dataset with n * PSX_KERNEL_OUTPUTWAVES_PER_ENTRY
// entries where n denotes the number of range/channel/sweep combinations
//
// Output[0] = psx_kernel(0)
// Output[1] = kernel_fft(0)
// Output[2] = sweepData(0)
// Output[3] = psx_kernel(1)
// ...
Function/WAVE PSX_OperationKernel(variable jsonId, string jsonPath, string graph)

	variable riseTau, decayTau, amp, dt, numPoints, numCombos, i, offset
	string parameterPath, key

	WAVE range = SFH_EvaluateRange(jsonId, jsonPath, graph, SF_OP_PSX_KERNEL, 0)

	WAVE/Z selectData = SFH_GetArgumentSelect(jsonID, jsonPath, graph, SF_OP_PSX_KERNEL, 1)
	riseTau = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_PSX_KERNEL, 2, defValue = 1)
	decayTau = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_PSX_KERNEL, 3, defValue = 15)
	amp  = SFH_GetArgumentAsNumeric(jsonID, jsonPath, graph, SF_OP_PSX_KERNEL, 4, defValue = -5)

	WAVE/WAVE sweepDataRef = SFH_GetSweepsForFormula(graph, range, selectData, SF_OP_PSX_KERNEL)

	numCombos = DimSize(sweepDataRef, ROWS)

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, SF_OP_PSX_KERNEL, PSX_KERNEL_OUTPUTWAVES_PER_ENTRY * numCombos)

	Make/FREE/T rawLabels = {"psxKernel", "psxKernelFFT", "sweepData"}
	ASSERT(DimSize(rawLabels, ROWS) == PSX_KERNEL_OUTPUTWAVES_PER_ENTRY, "Mismatched rawLabels wave")

	for(i = 0; i < numCombos; i += 1)
		WAVE sweepData = sweepDataRef[i]
		numPoints = DimSize(sweepData, ROWS)
		dt = DimDelta(sweepData, ROWS)

		if(IsOdd(numPoints))
			// throw away one point so that FFT works
			Redimension/N=(--numPoints) sweepData
		endif

		WAVE/WAVE result = PSX_GetPSXKernel(riseTau, decayTau, amp, numPoints, dt, range)

		Duplicate/FREE/T rawLabels, labels
		labels[] = PSX_GenerateKey(rawLabels[p], i)
		SetDimensionLabels(output, TextWaveToList(labels, ";") , ROWS, startPos = i * PSX_KERNEL_OUTPUTWAVES_PER_ENTRY)

		key = PSX_GenerateKey("psxKernel", i)
		output[%$key] = result[0]
		key = PSX_GenerateKey("psxKernelFFT", i)
		output[%$key] = result[1]
		key = PSX_GenerateKey("sweepData", i)
		output[%$key] = sweepData
	endfor

	parameterPath = SF_META_USER_GROUP + PSX_JWN_PARAMETERS + "/" + SF_OP_PSX_KERNEL
	JWN_CreatePath(output, parameterPath)
	JWN_SetWaveInWaveNote(output, parameterPath + "/range", range)
	JWN_SetNumberInWaveNote(output, parameterPath + "/riseTau", riseTau)
	JWN_SetNumberInWaveNote(output, parameterPath + "/decayTau", decayTau)
	JWN_SetNumberInWaveNote(output, parameterPath + "/amp", amp)

	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_PSX_KERNEL, ""))

	return SFH_GetOutputForExecutor(output, graph, SF_OP_PSX_KERNEL)
End

Function/WAVE PSX_OperationStats(variable jsonId, string jsonPath, string graph)

	string stateAsStr, prop, postProc

	WAVE range = SFH_EvaluateRange(jsonId, jsonPath, graph, SF_OP_PSX_STATS, 0)

	WAVE/Z selectData = SFH_GetArgumentSelect(jsonID, jsonPath, graph, SF_OP_PSX_STATS, 1)
	SFH_Assert(WaveExists(selectData), "Missing select data")

	prop       = SFH_GetArgumentAsText(jsonID, jsonPath, graph, SF_OP_PSX_STATS, 2, allowedValues = {"amp", "xpos", "xinterval", "tau", "estate", "fstate", "fitresult"})
	stateAsStr = SFH_GetArgumentAsText(jsonID, jsonPath, graph, SF_OP_PSX_STATS, 3, allowedValues = {"accept", "reject", "undetermined", "all", "every"})
	postProc   = SFH_GetArgumentAsText(jsonID, jsonPath, graph, SF_OP_PSX_STATS, 4, defValue = "nothing", allowedValues = {"nothing", "avg", "count", "hist", "log10"})

	WAVE/WAVE output = PSX_OperationStatsImpl(graph, range, selectData, prop, stateAsStr, postProc)

	JWN_SetStringInWaveNote(output, SF_META_OPSTACK, AddListItem(SF_OP_PSX_STATS, ""))

	return SFH_GetOutputForExecutor(output, graph, SF_OP_PSX_STATS)
End

/// @brief Menu item for selecting event inside a marquee and changing their state
///
/// @param newState new state, one of @ref PSXStates
/// @param stateType state type, one of @ref PSXStateTypes
Function PSX_MouseEventSelection(variable newState, variable stateType)

	string win, bottomLabel, panel
	variable left, right, filtOffTop, filtOffBottom, filtOffDeconvTop, filtOffDeconvBottom, bottom, top
	variable numMatches, numEntries, i, needsUpdate

	[left, right] = GetMarqueeHelper("bottom", horiz = 1, doAssert = 1, win = win)

	DFREF comboDFR = PSX_GetCurrentComboFolder(win)

	if(!DataFolderExistsDFR(comboDFR))
		// not our window
		return NaN
	endif

	bottomLabel = AxisLabel(win, "bottom")

	strswitch(bottomLabel)
		// PSX decision plot
		// we match an empty string as well as AxisLabel returns that for auto labels (reported as #4353)
		case "ms":
		case "":
			WAVE peakX = GetPSXPeakXWaveFromDFR(comboDFR)

			Extract/INDX/FREE peakX, matches, peakX >= left && peakX <= right
			numMatches = DimSize(matches, ROWS)

			if(numMatches == 0)
				return NaN
			endif

			// now check wether the y-coordinates of the events are inside for either axis
			[filtOffBottom, filtOffTop] = GetMarqueeHelper("leftFiltOff", vert = 1, doAssert = 0)
			[filtOffDeconvBottom, filtOffDeconvTop] = GetMarqueeHelper("leftFiltOffDeconv", vert = 1, doAssert = 0, kill = 1)

			if(IsNaN(filtOffTop) || IsNaN(filtOffBottom) || IsNaN(filtOffDeconvTop) || IsNaN(filtOffDeconvBottom))
				return NaN
			endif

			Make/FREE/N=(numMatches) xCrds = peakX[matches[p]]

			WAVE filtOffMatch       = PSX_GetEventsInsideAxisRange(win, "sweepDataFiltOff", filtOffBottom, filtOffTop, xCrds)
			WAVE filtOffDeconvMatch = PSX_GetEventsInsideAxisRange(win, "sweepDataFiltOffDeconv", filtOffDeconvBottom, filtOffDeconvTop, xCrds)

			Redimension/S matches
			matches[] = (IsFinite(filtOffMatch[p]) || IsFinite(filtOffDeconvMatch[p])) ? matches[p] : NaN

			WAVE/Z matchesClean = ZapNaNs(matches)

			if(!WaveExists(matchesClean))
				return NaN
			endif

			PSX_UpdateEventWaves(win, indizes = matchesClean, val = newState, stateType = stateType)
			needsUpdate = 1
			break
		// PSX stats plot
		case "Event":
			[bottom, top] = GetMarqueeHelper("left", vert = 1, doAssert = 0, kill = 1)

			WAVE/WAVE/Z result = PSX_GetEventsInsideMarqueeForStatsPlot(win, left, top, right, bottom)

			if(!WaveExists(result))
				return NaN
			endif

			needsUpdate = 1

			numEntries = DimSize(result, ROWS)
			for(i = 0; i < numEntries; i += 1)
				WAVE eventIndizes = result[i][%eventIndizes]
				WAVE comboIndex   = result[i][%comboIndex]
				ASSERT(DimSize(comboIndex, ROWS) == 1, "Unexpected combo index size")

				PSX_UpdateEventWaves(win, indizes = eventIndizes, val = newState, stateType = stateType, comboIndex = comboIndex[0])
			endfor
			break
		default:
			// do nothing
			return NaN
	endswitch
End

/// @brief Returns a 2D wave reference wave with event indices/comboKey entries in each column
///
/// ROWS:
/// - Result for each trace
///
/// COLUMNS:
/// - 0 (eventIndizes):
///   Indizes of events which are in range
/// - 1 (comboIndex)
///   Combo index for the events in column 0
///   Always only one element!
static Function/WAVE PSX_GetEventsInsideMarqueeForStatsPlot(string win, variable left, variable top, variable right, variable bottom)

	string traces, comboKey, trace
	variable numTraces, i, idx

	traces = TraceNameList(win, ";", 1 + 2)
	numTraces = ItemsInList(traces)

	Make/FREE/WAVE/N=(MINIMUM_WAVE_SIZE, 2) result
	SetDimensionLabels(result, "eventIndizes;comboIndex", COLS)

	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traces)

		WAVE xWave = XWaveRefFromTrace(win, trace)

		// xWave holds event numbers
		// xWave, yWave and comboKeys have corresponding indices
		Extract/FREE/INDX xWave, matches, xWave >= left && xWave <= right

		if(DimSize(matches, ROWS) == 0)
			continue
		endif

		// matches now holds the indizes which are inside the horizontal marquee

		WAVE yAxisMatch = PSX_GetEventsInsideAxisRange(win, trace, bottom, top, matches)

		Redimension/S matches
		matches[] = IsFinite(yAxisMatch[p]) ? matches[p] : NaN

		WAVE/Z matchesClean = ZapNaNs(matches)

		if(!WaveExists(matchesClean))
			continue
		endif

		WAVE yWave = TraceNameToWaveRef(win, trace)

		WAVE/T comboKeys = JWN_GetTextWaveFromWaveNote(yWave, SF_META_USER_GROUP + PSX_JWN_COMBO_KEYS_NAME)
		// comboKeysMatches hold the comboKeys of all matches
		Make/T/FREE/N=(DimSize(matchesClean, ROWS)) comboKeysMatches = comboKeys[matchesClean[p]]
		WaveClear comboKeys

		WAVE/T uniqueComboKeysMatches = GetUniqueEntries(comboKeysMatches)

		// only iterate over all different comboKeys
		for(comboKey : uniqueComboKeysMatches)

			// now get all indizes from that comboKey
			WAVE indizes = FindIndizes(comboKeysMatches, str = comboKey)

			// now convert the matching indizes into matchesClean into an index into xWave and then into the xWave values themselves
			MatrixOP/FREE eventIndizes = waveMap(xWave, waveMap(matchesClean, indizes))

			EnsureLargeEnoughWave(result, indexShouldExist = idx)

			Make/FREE comboIndex = {PSX_GetComboIndexForComboKey(win, comboKey)}
			result[idx][%comboIndex]   = comboIndex
			result[idx][%eventIndizes] = eventIndizes

			idx += 1
		endfor
	endfor

	if(!idx)
		return $""
	endif

	Redimension/N=(idx, -1) result
	Note/K result

	return result
End

/// @brief Make the events inside the marquee visible in the `psx` plot
Function PSX_JumpToEvents()

	variable left, right, bottom, top, foundComboIndex, refComboIndex, currentComboIndex, numResults, i, numEvents
	variable lowest, highest
	string win, bottomLabel, mainWindow, psxGraph

	[left, right] = GetMarqueeHelper("bottom", horiz = 1, doAssert = 1, win = win)

	DFREF comboDFR = PSX_GetCurrentComboFolder(win)

	if(!DataFolderExistsDFR(comboDFR))
		// not our window
		return NaN
	endif

	bottomLabel = AxisLabel(win, "bottom")

	strswitch(bottomLabel)
		case "Event":
			[bottom, top] = GetMarqueeHelper("left", vert = 1, doAssert = 0, kill = 1)

			if(IsNaN(bottom) || IsNaN(top))
				return NaN
			endif

			WAVE/WAVE/Z result = PSX_GetEventsInsideMarqueeForStatsPlot(win, left, top, right, bottom)

			if(!WaveExists(result))
				return NaN
			endif

			numResults = DimSize(result, ROWS)

			mainWindow = GetMainWindow(win)

			Make/FREE/N=(numResults) combinations = WaveRef(result[p][%comboIndex])[0]

			if(IsConstant(combinations, combinations[0]))
				refComboIndex = combinations[0]
			else
				currentComboIndex = PSX_GetCurrentComboIndex(mainWindow)

				foundComboIndex = GetRowIndex(combinations, val = currentComboIndex)
				if(IsNaN(foundComboIndex))
					DoAbortNow("The selected events have mixed combinations but none of them is the current one.")
				endif

				refComboIndex = combinations[foundComboIndex]
			endif

			PGC_SetAndActivateControl(mainWindow, "listbox_select_combo", val = refComboIndex)

			Make/FREE/N=0 allEventIndizes
			for(i = 0; i < numResults; i += 1)
				WAVE entry = result[i][%comboIndex]
				if(entry[0] != refComboIndex)
					continue
				endif

				Concatenate/NP=(ROWS) {result[i][%eventIndizes]}, allEventIndizes
			endfor

			numEvents = DimSize(allEventIndizes, ROWS)
			ASSERT(numEvents > 0, "Unexpected number of events")

			psxGraph = PSX_GetPSXGraph(win)

			if(numEvents == 1)
				PSX_MoveAndCenterCursor(psxGraph, allEventIndizes[0])
			else
				[lowest, highest] = WaveMinAndMax(allEventIndizes)

				// move to lowest event index (this also centers but we don't care)
				PSX_MoveAndCenterCursor(psxGraph, lowest)
				// and bring the highest into range
				PSX_CenterCursor(psxGraph, lowest, 0, rightIndex = highest)
			endif

			break
		default:
			// do nothing
			break
	endswitch
End

/// @brief Change the current combination to `comboIndex`
static Function PSX_SetCombo(string win, variable comboIndex)

	string extSingleGraph, psxGraph
	variable eventIndex

	psxGraph = PSX_GetPSXGraph(win)

	DFREF workDFR = PSX_GetWorkingFolder(psxGraph)
	DFREF comboDFR = GetPSXFolderForCombo(workDFR, comboIndex)

	extSingleGraph = PSX_GetSingleEventGraph(psxGraph)

	DFREF currentDFR = GetDataFolderDFR()
	SetDataFolder comboDFR
	ReplaceWave/W=$psxGraph allinCDF
	ReplaceWave/W=$extSingleGraph allinCDF
	SetDataFolder currentDFR

	WAVE eventLocationTicks = GetPSXEventLocationTicks(comboDFR)
	WAVE eventLocationLabels = GetPSXEventLocationLabels(comboDFR)

	PSX_ApplySpecialPlotProperties(psxGraph, eventLocationTicks, eventLocationLabels)

	PSX_MoveAndCenterCursor(psxGraph, 0)
End

Function PSX_ButtonProc_StoreEvents(STRUCT WMButtonAction &ba) : ButtonControl

	string win, browser, name, bsPanel

	switch(ba.eventCode)
		case 2: // mouse up
			win     = GetMainWindow(ba.win)
			browser = SFH_GetBrowserForFormulaGraph(win)

			DFREF workDFR = PSX_GetWorkingFolder(win)

			WAVE/DF comboFolders = PSX_GetAllCombinationFolders(workDFR)

			for(DFREF comboDFR : comboFolders)
				WAVE psxEvent = GetPSXEventWaveFromDFR(comboDFR)
				name = JWN_GetStringFromWaveNote(psxEvent, PSX_EVENTS_COMBO_KEY_WAVE_NOTE)
				PSX_StoreIntoResultsWave(browser, SFH_RESULT_TYPE_PSX, psxEvent, name)
			endfor

			bsPanel = BSP_GetPanel(browser)
			PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display", val = NaN)
			break
	endswitch

	return 0
End

Function PSX_ButtonProcJumpFirstUndet(STRUCT WMButtonAction &ba) : ButtonControl

	string win, panel, psxGraph
	variable numCombos, i

	switch(ba.eventCode)
		case 2: // mouse up
			win = ba.win
			psxGraph = PSX_GetPSXGraph(win)

			DFREF workDFR = PSX_GetWorkingFolder(win)

			WAVE/Z/DF comboFolders = PSX_GetAllCombinationFolders(workDFR)
			ASSERT(WaveExists(comboFolders), "Missing comboFolders")
			numCombos = DimSize(comboFolders, ROWS)

			for(i = 0; i < numCombos; i += 1)
				WAVE psxEvent = GetPSXEventWaveFromDFR(comboFolders[i])

				FindValue/RMD=[][FindDimLabel(psxEvent, COLS, "Event manual QC call")]/V=(PSX_UNDET) psxEvent

				if(V_row >= 0)
					panel = GetMainWindow(win)
					PGC_SetAndActivateControl(panel, "listbox_select_combo", val = i)
					PSX_MoveAndCenterCursor(psxGraph, V_row)
					break
				endif
			endfor

			break
	endswitch
End

Function PSX_ListBoxSelectCombo(STRUCT WMListBoxAction &lba) : ListboxControl

	variable row

	switch(lba.eventCode)
		case 3: // double click (PGC_SetAndActivateControl uses that)
		case 4: // cell selection

			// workaround IP bug where lba.row can be out of range
			WAVE/T listWave = lba.listWave

			row = lba.row

			if(row < 0 || row >= DimSize(listWave, ROWS))
				break
			endif

			PSX_SetCombo(lba.win, row)
			break
	endswitch
End

Function PSX_CopyHelpToClipboard(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse down
			PutScrapText ba.userData
			break
	endswitch
End

Function PSX_CheckboxProcSuppressUpdate(STRUCT WMCheckboxAction &cba) : CheckboxControl

	switch(cba.eventCode)
		case 2: // mouse up
			if(!cba.checked)
				PSX_UpdateAllEventGraph(cba.win, forceAverageUpdate = 1, forceSingleEventUpdate = 1)
			endif
			break
	endswitch
End

Function PSX_PopupMenuState(STRUCT WMPopupAction &cba) : PopupMenuControl

	switch(cba.eventCode)
		case 2: // mouse up
			PSX_UpdateAllEventGraph(cba.win, forceSingleEventUpdate = 1, forceAverageUpdate = 1)
			break
	endswitch
End

Function PSX_CheckboxProcAllEventPlotUpdate(STRUCT WMCheckboxAction &cba) : CheckboxControl

	switch(cba.eventCode)
		case 2: // mouse up
			PSX_UpdateAllEventGraph(cba.win, forceAverageUpdate = 1)
			break
	endswitch
End
