#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_SF
#endif // AUTOMATED_TESTING

// to enable debug mode with more persistent data
// #define SWEEPFORMULA_DEBUG

/// @file MIES_SweepFormula.ipf
///
/// @brief __SF__ Sweep formula allows to do analysis on sweeps with a
/// dedicated formula language

/// Regular expression which extracts both formulas from `$a vs $b`
static StrConstant SF_SWEEPFORMULA_REGEXP = "^(.+?)(?:\\bvs\\b(.+))?$"
/// Regular expression which extracts formulas pairs from `$a vs $b\rand\r$c vs $d\rand\r...`
static StrConstant SF_SWEEPFORMULA_GRAPHS_REGEXP = "^(.+?)(?:\\r[ \t]*and[ \t]*\\r(.*))?$"
/// Regular expression which extracts y-formulas from `$a\rwith\r$b\rwith\r$c\r...`
static StrConstant SF_SWEEPFORMULA_WITH_REGEXP = "^(.+?)(?:\\r[ \t]*with[ \t]*\\r(.*))?$"

static Constant SF_MAX_NUMPOINTS_FOR_MARKERS = 1000

static StrConstant SF_PLOTTER_GUIDENAME = "HOR"

static StrConstant SF_XLABEL_USER = ""

static Constant SF_NUMTRACES_ERROR_THRESHOLD = 10000
static Constant SF_NUMTRACES_WARN_THRESHOLD  = 1000

static Constant SF_SWEEPFORMULA_AXIS_X = 0
static Constant SF_SWEEPFORMULA_AXIS_Y = 1

static StrConstant SF_UDATA_TABLEFORMULAS = "formulas"

static Structure SF_PlotterGraphStruct

	/// Name of the sweep formula graph this struct is associated with
	string graph
	/// Name of the window in which the plot/table is displayed
	string win
	/// Number of traces currently plotted
	variable traceCnt
	/// flag to call PSX plot creation when evaluated formulas contained psx operation
	variable postPlotPSX
	/// Non-zero if the legend should be shown for this plot
	variable showLegend
	/// Counter tracking how many formulas have been processed
	variable formulaCounter
	/// Wave holding x-axis labels used for the plotted data
	WAVE xAxisLabels
	/// Wave holding y-axis labels used for the plotted data
	WAVE yAxisLabels
	/// Text wave storing annotations to be displayed
	WAVE/T wAnnotations
	/// Text wave describing the argument setup for each formula
	WAVE/T formulaArgSetup
	/// Text wave containing the formulas for data displayed in tables
	WAVE/T tableFormulas
	/// Wave of waves storing collected plot formatting data for each formula
	WAVE/WAVE collPlotFormData
	/// Wave tracking which panels (graph/table) have been created
	WAVE panelsCreated
	/// Wave of waves with the evaluation results of a formula
	WAVE/WAVE formulaResults
	/// Text wave holding meta data about the plotted formulas and traces
	WAVE/T plotMetaData
	/// Wave assigning color groups to plotted traces
	WAVE colorGroups
EndStructure

Menu "GraphPopup"
	"Bring browser to front", /Q, SF_BringBrowserToFront()
End

Menu "TablePopup"
	"Bring browser to front", /Q, SF_BringBrowserToFront()
	"Copy formulas", /Q, SF_PutFormulasToClipboard()
End

Function SF_PutFormulasToClipboard()

	string table, txt, jsonTxt, formula

	table = ROStr(GetSweepFormulaLastRightClickedDisplayWindow())
	ASSERT(!IsEmpty(table), "Expected window name")

	jsonTxt = GetUserData(table, "", SF_UDATA_TABLEFORMULAS)
	if(!IsEmpty(jsonTxt))
		WAVE/T formulas = JSONToWave(jsonTxt)
		txt = ""
		for(formula : formulas)
			txt += TrimString(formula) + "\rwith\r"
		endfor
		txt = RemoveEnding(txt, "\rwith\r")
		PutScrapText txt
	endif
End

Function SF_BringBrowserToFront()

	string browser, graph

	graph   = GetMainWindow(GetCurrentWindow())
	browser = SFH_GetBrowserForFormulaGraph(graph)

	if(IsEmpty(browser))
		print "This menu option only applies to SweepFormula plots."
		return NaN
	elseif(!WindowExists(browser))
		printf "The browser %s does not exist anymore.\r", browser
		return NaN
	endif

	DoWindow/F $browser
End

Function/WAVE SF_GetNamedOperations()

	Make/FREE/T wt = {SF_OP_RANGE, SF_OP_MIN, SF_OP_MAX, SF_OP_AVG, SF_OP_MEAN, SF_OP_RMS, SF_OP_VARIANCE, SF_OP_STDEV,                 \
	                  SF_OP_DERIVATIVE, SF_OP_INTEGRATE, SF_OP_TIME, SF_OP_XVALUES, SF_OP_TEXT, SF_OP_LOG,                              \
	                  SF_OP_LOG10, SF_OP_APFREQUENCY, SF_OP_CURSORS, SF_OP_SELECTSWEEPS, SF_OP_AREA, SF_OP_SETSCALE, SF_OP_BUTTERWORTH, \
	                  SF_OP_SELECTCHANNELS, SF_OP_DATA, SF_OP_LABNOTEBOOK, SF_OP_WAVE, SF_OP_FINDLEVEL, SF_OP_EPOCHS, SF_OP_TP,         \
	                  SF_OP_STORE, SF_OP_SELECT, SF_OP_POWERSPECTRUM, SF_OP_TPSS, SF_OP_TPBASE, SF_OP_TPINST, SF_OP_TPFIT,              \
	                  SF_OP_PSX, SF_OP_PSX_KERNEL, SF_OP_PSX_STATS, SF_OP_PSX_RISETIME, SF_OP_PSX_PREP, SF_OP_PSX_DECONV_BP_FILTER,     \
	                  SF_OP_PSX_SWEEP_BP_FILTER,                                                                                        \
	                  SF_OP_MERGE, SF_OP_FIT, SF_OP_FITLINE, SF_OP_DATASET, SF_OP_SELECTVIS, SF_OP_SELECTCM, SF_OP_SELECTSTIMSET,       \
	                  SF_OP_SELECTIVSCCSWEEPQC, SF_OP_SELECTIVSCCSETQC, SF_OP_SELECTRANGE, SF_OP_SELECTEXP, SF_OP_SELECTDEV,            \
	                  SF_OP_SELECTEXPANDSCI, SF_OP_SELECTEXPANDRAC, SF_OP_SELECTSETCYCLECOUNT, SF_OP_SELECTSETSWEEPCOUNT,               \
	                  SF_OP_SELECTSCIINDEX, SF_OP_SELECTRACINDEX, SF_OP_ANAFUNCPARAM, SF_OP_CONCAT, SF_OP_TABLE, SF_OP_EXTRACT,         \
	                  SF_OP_IVSCCAPFREQUENCY, SF_OP_PREPAREFIT}
#ifdef AUTOMATED_TESTING
	Make/FREE/T wtTest = {SF_OP_TESTOP}
	Concatenate/NP/T {wtTest}, wt
#endif // AUTOMATED_TESTING

	return wt
End

Function/WAVE SF_GetFormulaKeywords()

	// see also SF_SWEEPFORMULA_REGEXP and SF_SWEEPFORMULA_GRAPHS_REGEXP
	Make/FREE/T wt = {"vs", "and", "with"}

	return wt
End

/// @brief add escape characters to a path element
Function/S SF_EscapeJsonPath(string str)

	return ReplaceString("/", str, "~1")
End

/// @brief transfer the wave scaling from one wave to another
///
/// Note: wave scale transfer requires wave units for the first wave or second wave
///
/// @param source    Wave whos scaling should get transferred
/// @param dest      Wave that accepts the new scaling
/// @param dimSource dimension of the source wave, if SF_TRANSFER_ALL_DIMS is used then all scales and units are transferred on the same dimensions,
///                  dimDest is ignored in that case, no unit check is applied in that case
/// @param dimDest   dimension of the destination wave
Function SF_FormulaWaveScaleTransfer(WAVE source, WAVE dest, variable dimSource, variable dimDest)

	string sourceUnit, destUnit

	if(dimSource == SF_TRANSFER_ALL_DIMS)
		CopyScales/P source, dest
		return NaN
	endif

	if(!(WaveDims(source) > dimSource && dimSource >= 0) || !(WaveDims(dest) > dimDest && dimDest >= 0))
		return NaN
	endif

	sourceUnit = WaveUnits(source, dimSource)
	destUnit   = WaveUnits(dest, dimDest)

	if(IsEmpty(sourceUnit) && IsEmpty(destUnit))
		return NaN
	endif

	switch(dimDest)
		case ROWS:
			SetScale/P x, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		case COLS:
			SetScale/P y, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		case LAYERS:
			SetScale/P z, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		case CHUNKS:
			SetScale/P t, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		default:
			FATAL_ERROR("Invalid dimDest")
	endswitch
End

/// @brief Retrieves the plot meta data from the JSON wave note or other sources and stores it in the plotMetaData wave
static Function/WAVE SF_FillPlotMetaData(WAVE wvYRef, variable useXLabel, string dataUnits)

	WAVE/T plotMetaData = GetSFPlotMetaData()
	plotMetaData[%DATATYPE]      = JWN_GetStringFromWaveNote(wvYRef, SF_META_DATATYPE)
	plotMetaData[%OPSTACK]       = JWN_GetStringFromWaveNote(wvYRef, SF_META_OPSTACK)
	plotMetaData[%ARGSETUPSTACK] = JWN_GetStringFromWaveNote(wvYRef, SF_META_ARGSETUPSTACK)
	plotMetaData[%XAXISLABEL]    = SelectString(useXLabel, SF_XLABEL_USER, JWN_GetStringFromWaveNote(wvYRef, SF_META_XAXISLABEL))
	plotMetaData[%YAXISLABEL]    = JWN_GetStringFromWaveNote(wvYRef, SF_META_YAXISLABEL) + dataUnits
	plotMetaData[%XAXISOFFSET]   = num2str(JWN_GetNumberFromWaveNote(wvYRef, SF_META_XAXISOFFSET), "%f")
	plotMetaData[%YAXISOFFSET]   = num2str(JWN_GetNumberFromWaveNote(wvYRef, SF_META_YAXISOFFSET), "%f")
	plotMetaData[%XAXISPERCENT]  = num2str(JWN_GetNumberFromWaveNote(wvYRef, SF_META_XAXISPERCENT), "%f")
	plotMetaData[%YAXISPERCENT]  = num2str(JWN_GetNumberFromWaveNote(wvYRef, SF_META_YAXISPERCENT), "%f")

	return plotMetaData
End

static Function [WAVE/WAVE formulaResults, WAVE/T plotMetaData] SF_FillFormulaResults(WAVE/Z/WAVE wvYRef, WAVE/Z/WAVE wvXRef, string yFormula)

	variable i, numResultsY, numResultsX
	variable useXLabel, addDataUnitsInAnnotation
	string dataUnits, dataUnitCheck

	SFH_ASSERT(WaveExists(wvYRef), "y part of formula returned no result.")

	numResultsY = DimSize(wvYRef, ROWS)
	if(WaveExists(wvXRef))
		numResultsX = DimSize(wvXRef, ROWS)
		SFH_ASSERT(numResultsX == numResultsY || numResultsX == 1, "X-Formula data not fitting to Y-Formula.")
	endif

	useXLabel                = 1
	addDataUnitsInAnnotation = 1
	WAVE/WAVE formulaResults = GetFormulaGatherWave()
	Redimension/N=(numResultsY, -1) formulaResults

	if(DimSize(wvYRef, ROWS) > 0 && DimSize(formulaResults, ROWS) > 0)
		CopyDimLabels/ROWS=(ROWS) wvYRef, formulaResults
	endif

	Note/K formulaResults, note(wvYRef)

	for(i = 0; i < numResultsY; i += 1)
		WAVE/Z wvYdata = wvYRef[i]
		if(WaveExists(wvYdata))
			if(WaveExists(wvXRef))
				if(numResultsX == 1)
					WAVE/Z wvXdata = wvXRef[0]
					if(WaveExists(wvXdata) && DimSize(wvXdata, ROWS) == numResultsY && numpnts(wvYdata) == 1 && numpnts(wvXdata) != 1)
						Duplicate/FREE/T/RMD=[i] wvXdata, wvXnewData
						formulaResults[i][%FORMULAX] = wvXnewData
					else
						formulaResults[i][%FORMULAX] = wvXRef[0]
					endif
				else
					formulaResults[i][%FORMULAX] = wvXRef[i]
				endif

				WAVE/Z wvXdata = formulaResults[i][%FORMULAX]
				if(WaveExists(wvXdata))
					useXLabel = 0
				endif
			endif

			dataUnits = WaveUnits(wvYdata, -1)
			if(IsNull(dataUnitCheck))
				dataUnitCheck = dataUnits
			elseif(CmpStr(dataUnitCheck, dataUnits))
				addDataUnitsInAnnotation = 0
			endif

			formulaResults[i][%FORMULAY] = wvYdata
			JWN_SetStringInWaveNote(wvYdata, SF_META_FORMULA, yFormula)
		endif
	endfor

	dataUnits = ""
	if(!IsNull(dataUnitCheck))
		dataUnits = SelectString(addDataUnitsInAnnotation && !IsEmpty(dataUnitCheck), "", SF_FormatUnit(dataUnitCheck))
	endif

	WAVE/T plotMetaData = SF_FillPlotMetaData(wvyRef, useXLabel, dataUnits)

	return [formulaResults, plotMetaData]
End

static Function [WAVE/WAVE formulaResults, WAVE/T plotMetaData] SF_GatherFormulaResults(string xFormula, string yFormula, string graph, variable lineNr, variable offset)

	WAVE/Z/WAVE wvXRef = $""
	if(!IsEmpty(xFormula))
		WAVE/WAVE wvXRef = SFE_ExecuteFormula(xFormula, graph, useVariables = 0, line = lineNr, offset = offset)
		SFH_ASSERT(WaveExists(wvXRef), "x part of formula returned no result.")
	endif
	WAVE/WAVE wvYRef = SFE_ExecuteFormula(yFormula, graph, useVariables = 0, line = lineNr, offset = 0)

	[WAVE/WAVE formulaResults, WAVE/T plotMetaData] = SF_FillFormulaResults(wvYRef, wvXRef, yFormula)

	return [formulaResults, plotMetaData]
End

static Function/S SF_FormatUnit(string unit)

	return "(" + unit + ")"
End

static Function/S SF_GetAnnotationPrefix(string dataType)

	strswitch(dataType)
		case SF_DATATYPE_EPOCHS:
			return "Epoch "
		case SF_DATATYPE_SWEEP:
			return ""
		case SF_DATATYPE_TP:
			return "TP "
		case SF_DATATYPE_LABNOTEBOOK:
			return "LB "
		case SF_DATATYPE_ANAFUNCPARAM:
			return "AFP "
		default:
			FATAL_ERROR("Invalid dataType")
	endswitch
End

static Function/S SF_GetTraceAnnotationText(WAVE/T plotMetaData, WAVE data)

	variable channelNumber, channelType, sweepNo, isAveraged
	string channelId, prefix, legendPrefix
	string traceAnnotation, annotationPrefix

	prefix       = RemoveEnding(ReplaceString(";", plotMetaData[%OPSTACK], " "), " ")
	legendPrefix = JWN_GetStringFromWaveNote(data, SF_META_LEGEND_LINE_PREFIX)

	strswitch(plotMetaData[%DATATYPE])
		case SF_DATATYPE_EPOCHS: // fallthrough
		case SF_DATATYPE_SWEEP: // fallthrough
		case SF_DATATYPE_LABNOTEBOOK: // fallthrough
		case SF_DATATYPE_ANAFUNCPARAM: // fallthrough
		case SF_DATATYPE_TP:
			sweepNo = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPNO)

			if(!IsEmpty(legendPrefix))
				legendPrefix = " " + legendPrefix + " "
			endif

			sprintf annotationPrefix, "%s%s", SF_GetAnnotationPrefix(plotMetaData[%DATATYPE]), legendPrefix

			if(IsValidSweepNumber(sweepNo))
				channelNumber = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELNUMBER)
				channelType   = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELTYPE)
				channelId     = StringFromList(channelType, XOP_CHANNEL_NAMES) + num2istr(channelNumber)
				sprintf traceAnnotation, "%sSweep %d %s", annotationPrefix, sweepNo, channelId
			else
				sprintf traceAnnotation, "%s", annotationPrefix
			endif
			break
		default:
			if(WhichListItem(SF_OP_DATA, plotMetaData[%OPSTACK]) == -1)
				sprintf traceAnnotation, "%s %s", prefix, legendPrefix
				traceAnnotation = TrimString(traceAnnotation)
			else
				channelNumber = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELNUMBER)
				channelType   = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELTYPE)
				if(IsNaN(channelNumber) || IsNaN(channelType))
					return ""
				endif
				isAveraged = JWN_GetNumberFromWaveNote(data, SF_META_ISAVERAGED)
				if(IsNaN(isAveraged) || !isAveraged)
					sweepNo = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPNO)
					if(IsNaN(sweepNo))
						return ""
					endif
				endif
				channelId = StringFromList(channelType, XOP_CHANNEL_NAMES) + num2istr(channelNumber)
				if(isAveraged)
					sprintf traceAnnotation, "%s Sweep(s) averaged %s", prefix, channelId
				else
					sprintf traceAnnotation, "%s Sweep %d %s", prefix, sweepNo, channelId
				endif
			endif
			break
	endswitch

	return traceAnnotation
End

static Function/S SF_GetMetaDataAnnotationText(WAVE/T plotMetaData, WAVE data, string traceName)

	return "\\s(" + traceName + ") " + SF_GetTraceAnnotationText(plotMetaData, data) + "\r"
End

static Function/WAVE SF_GenerateTraceColors(WAVE colorGroups)

	variable numUniqueColors, i
	string lbl

	WAVE uniqueColorGroups = GetUniqueEntries(colorGroups)
	numUniqueColors = DimSize(uniqueColorGroups, ROWS)
	WAVE traceColors = GetColorWave(numUniqueColors)

	for(i = 0; i < numUniqueColors; i += 1)
		[STRUCT RGBColor s] = GetTraceColorAlternative(i)

		lbl = num2istr(uniqueColorGroups[i])
		SetDimLabel ROWS, i, $lbl, traceColors

		traceColors[i][%Red]   = s.red
		traceColors[i][%Green] = s.green
		traceColors[i][%Blue]  = s.blue
	endfor

	return traceColors
End

/// @brief Add the color groups from the formulaResults to colorGroups and return it
static Function/WAVE SF_GetColorGroups(WAVE/WAVE formulaResults, WAVE/Z colorGroups)

	variable numFormulas, i, numUniqueColors, refColorGroup, constantChannelNumAndType
	string lbl

	numFormulas = DimSize(formulaResults, ROWS)

	if(numFormulas == 0)
		return colorGroups
	endif

	WAVE/Z data = formulaResults[0][%FORMULAY]

	if(!WaveExists(data))
		return colorGroups
	endif

	refColorGroup = JWN_GetNumberFromWaveNote(data, SF_META_COLOR_GROUP)

	if(IsNaN(refColorGroup))
		// current formula does not use color groups
		return $""
	endif

	Make/FREE/N=(numFormulas)/D newColorGroups = JWN_GetNumberFromWaveNote(formulaResults[p][%FORMULAY], SF_META_COLOR_GROUP)

	if(WaveExists(colorGroups))
		Concatenate/FREE/NP=(ROWS) {colorGroups, newColorGroups}, allColorGroups
	else
		WAVE allColorGroups = newColorGroups
	endif

	if(numFormulas == 1)
		return allColorGroups
	endif

	// check if the data in the y formulas is from the same channel type and number
	Make/FREE/N=(numFormulas) channelNumbers = JWN_GetNumberFromWaveNote(formulaResults[p][%FORMULAY], SF_META_CHANNELNUMBER)
	Make/FREE/N=(numFormulas) channelTypes = JWN_GetNumberFromWaveNote(formulaResults[p][%FORMULAY], SF_META_CHANNELTYPE)

	constantChannelNumAndType = IsConstant(channelNumbers, channelNumbers[0], ignoreNaN = 0) \
	                            && IsConstant(channelTypes, channelTypes[0], ignoreNaN = 0)

	if(!constantChannelNumAndType)
		return colorGroups
	endif

	return allColorGroups
End

Function [STRUCT RGBColor s] SF_GetTraceColor(string graph, string opStack, WAVE data, WAVE/Z colorGroups)

	variable i, channelNumber, channelType, sweepNo, headstage, numDoInh, minVal, isAveraged, mapIndex
	variable colorGroup, idx

	if(WaveExists(colorGroups))
		WAVE traceGroupColors = SF_GenerateTraceColors(colorGroups)

		// Operations with trace group color support:
		// - data/epochs/tp/psxKernel (via SFH_GetSweepsForFormula)
		// - labnotebook
		// - anaFuncParam

		colorGroup = JWN_GetNumberFromWaveNote(data, SF_META_COLOR_GROUP)
		ASSERT(IsFinite(colorGroup), "Invalid color group")

		idx = FindDimLabel(traceGroupColors, ROWS, num2istr(colorGroup))
		ASSERT(idx >= 0, "Invalid color group index")

		s.red   = traceGroupColors[idx][%Red]
		s.green = traceGroupColors[idx][%Green]
		s.blue  = traceGroupColors[idx][%Blue]

		return [s]
	endif

	s.red   = 0xFFFF
	s.green = 0x0000
	s.blue  = 0x0000

	Make/FREE/T stopInheritance = {SF_OPSHORT_MINUS, SF_OPSHORT_PLUS, SF_OPSHORT_DIV, SF_OPSHORT_MULT}
	Make/FREE/T doInheritance = {SF_OP_DATA, SF_OP_TP, SF_OP_PSX, SF_OP_PSX_STATS, SF_OP_EPOCHS, SF_OP_LABNOTEBOOK, SF_OP_ANAFUNCPARAM}

	WAVE/T opStackW = ListToTextWave(opStack, ";")
	numDoInh = DimSize(doInheritance, ROWS)
	Make/FREE/N=(numDoInh) findPos
	for(i = 0; i < numDoInh; i += 1)
		FindValue/TEXT=doInheritance[i]/TXOP=4 opStackW
		findPos[i] = (V_Value == -1) ? NaN : V_Value
	endfor
	minVal = WaveMin(findPos)
	if(IsNaN(minVal))
		return [s]
	endif

	Redimension/N=(minVal) opStackW
	WAVE/Z/T common = GetSetIntersection(opStackW, stopInheritance)
	if(WaveExists(common))
		return [s]
	endif

	isAveraged = JWN_GetNumberFromWaveNote(data, SF_META_ISAVERAGED)
	if(isAveraged)
		[s] = GetTraceColorForAverage()
		return [s]
	endif

	channelNumber = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELNUMBER)
	channelType   = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELTYPE)
	mapIndex      = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPMAPINDEX)
	sweepNo       = JWN_GetNumberFromWaveNote(data, SF_META_SWEEPNO)
	if(!IsValidSweepNumber(sweepNo))
		return [s]
	endif

	WAVE/Z numericalValues = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_VALUES)
	if(!WaveExists(numericalValues))
		return [s]
	endif
	if(channelType == XOP_CHANNEL_TYPE_TTL)
		[s] = GetHeadstageColor(NaN, channelType = channelType, channelNumber = channelNumber)
	else
		headstage = GetHeadstageForChannel(numericalValues, sweepNo, channelType, channelNumber, DATA_ACQUISITION_MODE)
		[s]       = GetHeadstageColor(headstage)
	endif

	return [s]
End

/// @brief Generate `numTraces` trace names for the given input
///
/// Generates the trace names required for a single formula in the plotter and
/// therefore the trace names range from `traceCnt` to `traceCnt + numTraces - 1`.
///
/// @retval traces   generated trace names
/// @retval traceCnt total count of all traces (input *and* output)
static Function [WAVE/T traces, STRUCT SF_PlotterGraphStruct pg] SF_CreateTraceNames(variable numTraces, variable dataNum, WAVE/T plotMetaData, WAVE data)

	string traceAnnotation

	if(!numTraces)
		return [$"", pg]
	endif

	traceAnnotation = SF_GetTraceAnnotationText(plotMetaData, data)
	traceAnnotation = ReplaceString(" ", traceAnnotation, "_")
	traceAnnotation = CleanupName(traceAnnotation, 0)

	Make/T/N=(numTraces)/FREE traces

	traces[]     = GetTraceNamePrefix(pg.traceCnt + p) + "d" + num2istr(dataNum) + "_" + traceAnnotation
	pg.traceCnt += numTraces

	return [traces, pg]
End

/// Reduces a multi line legend to a single line if only the sweep number changes.
/// Returns the original annotation if more changes or the legend text does not follow the exected format
static Function/S SF_ShrinkLegend(string annotation)

	string str, tracePrefix, opPrefix, sweepNum, suffix
	string opPrefixOld, suffixOld, tracePrefixOld, shrunkAnnotation
	string   sweepList
	variable multipleSweeps

	string expr = "(\\\\s\\([\\s\\S]+\\)) ([\\s\\S]*Sweep) (\\d+) ([\\s\\S]*)"

	WAVE/T lines = ListToTextWave(annotation, "\r")
	if(DimSize(lines, ROWS) < 2)
		return annotation
	endif

	shrunkAnnotation = ""

	tracePrefixOld = ""
	suffixOld      = ""
	opPrefixOld    = ""
	sweepList      = ""

	for(line : lines)
		SplitString/E=expr line, tracePrefix, opPrefix, sweepNum, suffix
		if(V_flag != 4)
			return annotation
		endif

		if(IsEmpty(tracePrefixOld) && IsEmpty(opPrefixOld) && IsEmpty(suffixOld))
			tracePrefixOld = tracePrefix
			opPrefixOld    = opPrefix
			suffixOld      = suffix
			sweepList      = ""
		endif

		if(CmpStr(suffixOld, suffix, 2))
			return annotation
		endif

		if(CmpStr(opPrefixOld, opPrefix, 2))
			multipleSweeps    = ItemsInList(sweepList, ",") > 1
			sweepList         = CompressNumericalList(sweepList, ",")
			shrunkAnnotation += tracePrefixOld + opPrefixOld + SelectString(multipleSweeps, "", "s") + " " + sweepList + " " + suffixOld + "\r"

			tracePrefixOld = tracePrefix
			opPrefixOld    = opPrefix
			suffixOld      = suffix
			sweepList      = ""
		endif

		sweepList = AddListItem(sweepNum, sweepList, ",", Inf)
	endfor

	if(!IsEmpty(sweepList))
		multipleSweeps    = ItemsInList(sweepList, ",") > 1
		sweepList         = CompressNumericalList(sweepList, ",")
		shrunkAnnotation += tracePrefixOld + opPrefixOld + SelectString(multipleSweeps, "", "s") + " " + sweepList + " " + suffixOld
	endif

	return shrunkAnnotation
End

static Function SF_ClearPlotPanel(string win)

	string   subWindow
	variable wType

	TUD_Clear(win, recursive = 1)

	WAVE/T allWindows = ListToTextWave(GetAllWindows(win), ";")

	for(subWindow : allWindows)
		if(IsSubwindow(subWindow))
			// in complex hierarchies we might kill more outer subwindows first
			// so the inner ones might later not exist anymore
			KillWindow/Z $subWindow
		endif
	endfor

	RemoveAllControls(win)
	wType = WinType(win)
	if(wType == WINTYPE_PANEL || wType == WINTYPE_GRAPH)
		RemoveAllDrawLayers(win)
	endif
End

/// @brief Creates a new panel for sweepformula display of graph or table and returns the actual window name
///
/// @param[in] templateName base name of new window
/// @param[in] graph        name of sweepbrowser/databrowser window
/// @param[in] winType      [optional, default WINTYPE_PANEL] specifies window type
/// @returns name of created window
static Function/S SF_NewSweepFormulaBaseWindow(string templateName, string graph, [variable winType])

	string win

	winType = ParamIsDefault(winType) ? WINTYPE_PANEL : winType

	win = templateName
	if(WindowExists(win))
		SF_ClearPlotPanel(win)
	else
		if(winType == WINTYPE_GRAPH)
			Display/N=$win/K=1/W=(150, 400, 1000, 700)
		elseif(winType == WINTYPE_PANEL)
			NewPanel/N=$win/K=1/W=(150, 400, 1000, 700)
		elseif(winType == WINTYPE_TABLE)
			Edit/N=$win/K=1/W=(150, 400, 1000, 700)
			SF_AddTableExtrasSub(S_name)
		else
			FATAL_ERROR("Unsupported window type")
		endif
		win = S_name

		SF_CommonWindowSetup(win, graph)
	endif

	return win
End

static Function SF_AddTableExtrasSub(string win)

	SetWindow $win, tooltipHook(sfTableTooltip)=SF_TableTooltipHook
End

static Function SF_AddTableExtrasMain(string win)

	SetWindow $win, hook(sfTableGetWindowName)=SF_TableWindowHook
End

static Function/S SF_GetDataDisplayWindowName(string graph, variable type, variable mode, variable idx)

	string suffix          = ""
	string winNameTemplate = SF_GetFormulaWinNameTemplate(graph)

	if(type == SF_DISPLAYTYPE_TABLE)
		suffix = SF_WINNAME_SUFFIX_TABLE
	elseif(type == SF_DISPLAYTYPE_GRAPH)
		suffix = SF_WINNAME_SUFFIX_GRAPH
	else
		FATAL_ERROR("Unknown display type")
	endif

	if(mode == SF_DM_NORMAL)
		return winNameTemplate + suffix + num2istr(idx)
	endif

	if(mode == SF_DM_SUBWINDOWS)
		return winNameTemplate + suffix + "#" + suffix + num2istr(idx)
	endif

	FATAL_ERROR("Unknown display mode")
End

/// @brief Store window properties of previous graph (if existed)
static Function SF_CollectPreviousPlotProperties(string win, WAVE/WAVE prevPlotProperties, variable mode)

	variable restoreCursorInfo, idx

	if(WindowExists(win))
		Make/FREE/T name = {win}
		WAVE/Z/T axes     = GetAxesProperties(win)
		WAVE/Z/T cursors  = GetCursorInfos(win)
		WAVE/Z/T annoInfo = GetAnnotationInfo(win)

		if(WaveExists(cursors) && mode == SF_DM_SUBWINDOWS)
			restoreCursorInfo = 1
		endif

		idx = GetNumberFromWaveNote(prevPlotProperties, NOTE_INDEX)
		EnsureLargeEnoughWave(prevPlotProperties, indexShouldExist = idx)
		prevPlotProperties[idx][%NAME]        = name
		prevPlotProperties[idx][%AXES]        = axes
		prevPlotProperties[idx][%CURSORS]     = cursors
		prevPlotProperties[idx][%ANNOTATIONS] = annoInfo
		SetNumberInWaveNote(prevPlotProperties, NOTE_INDEX, idx + 1)
	endif

	return restoreCursorInfo
End

static Function SF_CommonWindowSetup(string win, string graph)

	string newTitle

	SetWindow $win, userData(JSONSettings_WindowGroup)="sweepformula"

	NVAR JSONid = $GetSettingsJSONid()
	PS_InitCoordinates(JSONid, win)

	SetWindow $win, hook(resetScaling)=IH_ResetScaling, userData($SFH_USER_DATA_BROWSER)=graph

	newTitle = BSP_GetFormulaGraphTitle(graph)
	DoWindow/T $win, newTitle
End

static Function SF_GatherAxisLabels(WAVE/WAVE formulaResults, string explicitLbl, string formulaLabel, WAVE/T axisLabels)

	variable i, size, numData
	string unit

	size = DimSize(axisLabels, ROWS)
	if(!isEmpty(explicitLbl))
		Redimension/N=(size + 1) axisLabels
		axisLabels[size] = explicitLbl
		return NaN
	endif

	numData = DimSize(formulaResults, ROWS)
	Redimension/N=(size + numData) axisLabels

	for(i = 0; i < numData; i += 1)
		WAVE/Z wvResultY = formulaResults[i][%FORMULAY]
		if(!WaveExists(wvResultY))
			continue
		endif

		strswitch(formulaLabel)
			case "FORMULAY":
				unit = WaveUnits(wvResultY, COLS)
				break
			case "FORMULAX":
				WAVE/Z wvResultX = formulaResults[i][%FORMULAX]
				if(WaveExists(wvResultX))
					unit = WaveUnits(wvResultX, ROWS)
				else
					unit = WaveUnits(wvResultY, ROWS)
				endif
				break
			default:
				FATAL_ERROR("Unsupported formulaLabel: " + formulaLabel)
				break
		endswitch

		// fallback to the unit if present
		if(!IsEmpty(unit))
			axisLabels[size] = SF_FormatUnit(unit)
			size            += 1
		endif
	endfor

	Redimension/N=(size) axisLabels
End

static Function/S SF_CombineAxisLabels(WAVE/T axisLabels)

	WAVE/T unique = GetUniqueEntries(axisLabels, dontDuplicate = 1)

	return TextWaveToList(unique, " / ", trailSep = 0)
End

static Function SF_CheckNumTraces(string graph, variable numTraces)

	string bsPanel, msg

	bsPanel = BSP_GetPanel(GetMainWindow(graph))
	if(numTraces > SF_NUMTRACES_ERROR_THRESHOLD)
		if(!AlreadyCalledOnce(CO_SF_TOO_MANY_TRACES))
			printf "If you really need the feature to plot more than %d traces in the SweepFormula plotter\r", SF_NUMTRACES_ERROR_THRESHOLD
			printf "create an new issue on our development platform. Simply select \"Report an issue\" in the \"Mies Panels\" menu.\r"
		endif

		sprintf msg, "Attempt to plot too many traces (%d).", numTraces
		SFH_FATAL_ERROR(msg)
	endif
	if(numTraces > SF_NUMTRACES_WARN_THRESHOLD)
		sprintf msg, "Plotting %d traces...", numTraces
		SF_SetOutputState(msg, SF_MSG_WARN)
		DoUpdate/W=$bsPanel
	endif
End

static Function SF_KillWindowAndParentsIfEmpty(string win)

	string subWindows

	KillWindow/Z $win
	for(;;)
		win = RemoveEnding(win, "#" + LastStringFromList(win, sep = "#"))
		if(WindowExists(win) && IsEmpty(ChildWindowList(win)))
			KillWindow/Z $win
		endif
		if(strsearch(win, "#", 0) == -1)
			break
		endif
	endfor
End

static Function SF_KillEmptyDataWindows(WAVE/T plotGraphs)

	for(str : plotGraphs)
		if(WindowExists(str))
			WAVE/Z wv = WaveRefIndexed(str, 0, 1)
			if(!WaveExists(wv))
				SF_KillWindowAndParentsIfEmpty(str)
			endif
		endif
	endfor
End

/// @brief Tiles the subwindows in the panels acording to existing data, requires SF_DM_SUBWINDOWS mode
static Function SF_TileExistingData(WAVE/WAVE outputWindows)

	variable numSubWins, numData, guidePos, subWindowIndex, posIndex, numRows
	string guideName, win

	for(WAVE/T typedOutputWins : outputWindows)
		numRows = GetNumberFromWaveNote(typedOutputWins, NOTE_INDEX)
		if(!numRows)
			continue
		endif

		win = typedOutputWins[0]
		win = RemoveEnding(win, "#" + LastStringFromList(win, sep = "#"))

		Make/FREE/N=(numRows) hasData
		hasData[] = WaveExists(WaveRefIndexed(typedOutputWins[p], 0, 1))

		WAVE/Z subWindowsWithData = FindIndizes(hasData, var = 1)
		if(!WaveExists(subWindowsWithData))
			KillWindow/Z $win
			continue
		endif

		numData  = DimSize(subWindowsWithData, ROWS)
		posIndex = 0
		for(subWindowIndex : subWindowsWithData)
			guideName = SF_PLOTTER_GUIDENAME + num2istr(subWindowIndex)
			guidePos  = posIndex / numData
			DefineGuide/W=$win $guideName={FT, guidePos, FB}

			guideName = SF_PLOTTER_GUIDENAME + num2istr(subWindowIndex + 1)
			guidePos  = (posIndex + 1) / numData
			DefineGuide/W=$win $guideName={FT, guidePos, FB}

			posIndex += 1
		endfor
	endfor
End

static Function SF_KillWorkingDF(string graph)

	DFREF dfrWork = SFH_GetWorkingDF(graph)
	KillOrMoveToTrash(dfr = dfrWork)
End

/// @brief Return the X or Y wave for the sweep formula
static Function/WAVE GetSweepFormula(DFREF dfr, variable graphNr, variable forAxis)

	if(forAxis == SF_SWEEPFORMULA_AXIS_X)
		return GetSweepFormulaX(dfr, graphNr)
	elseif(forAxis == SF_SWEEPFORMULA_AXIS_Y)
		return GetSweepFormulaY(dfr, graphNr)
	endif

	FATAL_ERROR("Unknown SF axis")
End

static Function/WAVE SF_PrepareResultWaveForPlotting(DFREF dfr, WAVE wvResult, variable dataCnt, variable forAxis)

	variable mXn
	string   fullWavePath

	WAVE wv = GetSweepFormula(dfr, dataCnt, forAxis)
	fullWavePath = GetWavesDataFolder(wv, 2)
	if(WaveType(wvResult, 1) != WaveType(wv, 1))
		KillOrMoveToTrash(wv = wv)
	endif
	Duplicate/O wvResult, $fullWavePath

	WAVE plotWave = GetSweepFormula(dfr, dataCnt, forAxis)

	mXn = max(1, DimSize(plotWave, COLS)) * max(1, DimSize(plotWave, LAYERS))
	Redimension/N=(-1, mXn)/E=1 plotWave

	return plotWave
End

/// @brief Returns 1 if the result is flagged as full plotting specification, 0 otherwise
static Function SF_IsDataForFullPlotting(WAVE wv)

	variable plot

	plot = JWN_GetNumberFromWaveNote(wv, SF_META_PLOT)

	return IsNaN(plot) ? 0 : !!plot
End

static Function SF_IsDataForTableDisplay(WAVE wvY)

	variable useTable

	useTable = JWN_GetNumberFromWaveNote(wvY, SF_PROPERTY_TABLE)

	return IsNaN(useTable) ? 0 : !!useTable
End

static Function [variable dataCnt, variable gdIndex, string annotation, variable formulaAddedOncePerDataset] SF_CreateTracesForResultsImpl(STRUCT SF_PlotterGraphStruct &pg, WAVE wvResultY, WAVE/Z wvResultX, variable dataNum, variable showInTable, WAVE plotFormData)

	STRUCT RGBColor color
	variable numTraces, yPoints, xPoints, yMxN, xMxN, idx, splitTraces
	variable i, isCategoryAxis, splitX, splitY
	variable rangeBeginX, rangeEndX, rangeBeginY, rangeEndY
	string info

	WAVE/Z wvX = $""

	SFH_ASSERT(!(IsTextWave(wvResultY) && WaveDims(wvResultY) > 1), "Plotter got 2d+ text wave as y data.")

	DFREF dfr = SF_GetBrowserDF(pg.graph)

	[color] = SF_GetTraceColor(pg.graph, pg.plotMetaData[%OPSTACK], wvResultY, pg.colorGroups)

	if(!WaveExists(wvResultX) && !IsEmpty(pg.plotMetaData[%XAXISLABEL]))
		WAVE/Z wvResultX = JWN_GetNumericWaveFromWaveNote(wvResultY, SF_META_XVALUES)

		if(!WaveExists(wvResultX))
			WAVE/Z wvResultX = JWN_GetTextWaveFromWaveNote(wvResultY, SF_META_XVALUES)
		endif
	endif

	if(WaveExists(wvResultX))
		SFH_ASSERT(!(IsTextWave(wvResultX) && WaveDims(wvResultX) > 1), "Plotter got 2d+ text wave as x data.")
		WAVE wvX = SF_PrepareResultWaveForPlotting(dfr, wvResultX, dataCnt, SF_SWEEPFORMULA_AXIS_X)
		xPoints = DimSize(wvX, ROWS)
		xMxN    = DimSize(wvX, COLS)
	endif

	WAVE wvY = SF_PrepareResultWaveForPlotting(dfr, wvResultY, dataCnt, SF_SWEEPFORMULA_AXIS_Y)
	yPoints = DimSize(wvY, ROWS)
	yMxN    = DimSize(wvY, COLS)

	SFH_ASSERT(!(IsTextWave(wvY) && (WaveExists(wvX) && IsTextWave(wvX))), "One wave needs to be numeric for plotting")

	if(showInTable)
		if(HasDimLabels(wvY, ROWS) || HasDimLabels(wvY, COLS))
			AppendToTable/W=$pg.win wvY.ld
		else
			AppendToTable/W=$pg.win wvY.d
		endif

		if(!formulaAddedOncePerDataset)
			idx = GetNumberFromWaveNote(pg.tableFormulas, NOTE_INDEX)
			EnsureLargeEnoughWave(pg.tableFormulas, indexShouldExist = idx)
			pg.tableFormulas[idx] = JWN_GetStringFromWaveNote(wvY, SF_META_FORMULA)
			SetNumberInWaveNote(pg.tableFormulas, NOTE_INDEX, idx + 1)
			formulaAddedOncePerDataset = 1
		endif

		dataCnt += 1
		return [dataCnt, gdIndex, annotation, formulaAddedOncePerDataset]
	endif

	if(IsTextWave(wvY))
		SFH_ASSERT(WaveExists(wvX), "Cannot plot a single text wave")
		ModifyGraph/W=$pg.win swapXY=1
		WAVE dummy = wvY
		WAVE wvY   = wvX
		WAVE wvX   = dummy
	endif

	if(!WaveExists(wvX))
		numTraces = yMxN
		SF_CheckNumTraces(pg.graph, numTraces)
		[WAVE/T traces, pg] = SF_CreateTraceNames(numTraces, dataNum, pg.plotMetaData, wvResultY)

		for(i = 0; i < numTraces; i += 1)
			SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
			AppendTograph/W=$pg.win/C=(color.red, color.green, color.blue) wvY[][i]/TN=$traces[i]
			annotation += SF_GetMetaDataAnnotationText(pg.plotMetaData, wvResultY, traces[i])
			SF_AddErrorBars(pg.graph, pg.win, wvY, traces[i])
		endfor
	elseif((xMxN == 1) && (yMxN == 1)) // 1D
		if(yPoints == 1) // 0D vs 1D
			numTraces = xPoints
			SF_CheckNumTraces(pg.graph, numTraces)
			[WAVE/T traces, pg] = SF_CreateTraceNames(numTraces, dataNum, pg.plotMetaData, wvResultY)

			for(i = 0; i < numTraces; i += 1)
				SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
				AppendTograph/W=$pg.win/C=(color.red, color.green, color.blue) wvY[][0]/TN=$traces[i] vs wvX[i][]
				annotation += SF_GetMetaDataAnnotationText(pg.plotMetaData, wvResultY, traces[i])
				SF_AddErrorBars(pg.graph, pg.win, wvY, traces[i], rangeBeginX = i, rangeEndX = i)
			endfor
		elseif(xPoints == 1) // 1D vs 0D
			numTraces = yPoints
			SF_CheckNumTraces(pg.graph, numTraces)
			[WAVE/T traces, pg] = SF_CreateTraceNames(numTraces, dataNum, pg.plotMetaData, wvResultY)

			for(i = 0; i < numTraces; i += 1)
				SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
				AppendTograph/W=$pg.win/C=(color.red, color.green, color.blue) wvY[i][]/TN=$traces[i] vs wvX[][0]
				annotation += SF_GetMetaDataAnnotationText(pg.plotMetaData, wvResultY, traces[i])
				SF_AddErrorBars(pg.graph, pg.win, wvY, traces[i], rangeBeginY = i, rangeEndY = i)
			endfor
		else // 1D vs 1D

			splitTraces = min(yPoints, xPoints)
			numTraces   = floor(max(yPoints, xPoints) / splitTraces)
			SF_CheckNumTraces(pg.graph, numTraces)
			[WAVE/T traces, pg] = SF_CreateTraceNames(numTraces, dataNum, pg.plotMetaData, wvResultY)

			if(mod(max(yPoints, xPoints), splitTraces) == 0)
				DebugPrint("Unmatched Data Alignment in ROWS.")
			endif

			for(i = 0; i < numTraces; i += 1)
				if(WindowExists(pg.win) && WhichListItem("bottom", AxisList(pg.win)) >= 0)
					info           = AxisInfo(pg.win, "bottom")
					isCategoryAxis = NumberByKey("ISCAT", info) == 1

					if(isCategoryAxis)
						DFREF              catDFR       = $StringByKey("CATWAVEDF", info)
						WAVE/Z/SDFR=catDFR categoryWave = $StringByKey("CATWAVE", info)
						ASSERT(WaveExists(categoryWave), "Expected category axis")

						if(EqualWaves(categoryWave, wvX, EQWAVES_DATA))
							// we can't, but also don't need, to append the same category axis again
							// so let's just reuse the existing one
							WAVE wvX = categoryWave
						endif
					endif
				endif

				SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
				splitY      = SF_SplitPlotting(wvY, ROWS, i, splitTraces)
				splitX      = SF_SplitPlotting(wvX, ROWS, i, splitTraces)
				rangeBeginX = splitX
				rangeEndX   = splitX + splitTraces - 1
				rangeBeginY = splitY
				rangeEndY   = splitY + splitTraces - 1
				AppendTograph/W=$pg.win/C=(color.red, color.green, color.blue) wvY[rangeBeginY, rangeEndY][0]/TN=$traces[i] vs wvX[rangeBeginX, rangeEndX][0]
				annotation += SF_GetMetaDataAnnotationText(pg.plotMetaData, wvResultY, traces[i])

				SF_AddErrorBars(pg.graph, pg.win, wvY, traces[i], rangeBeginX = rangeBeginX, rangeEndX = rangeEndX, rangeBeginY = rangeBeginY, rangeEndY = rangeEndY)
			endfor
		endif
	elseif(yMxN == 1) // 1D vs 2D
		numTraces = xMxN
		SF_CheckNumTraces(pg.graph, numTraces)
		[WAVE/T traces, pg] = SF_CreateTraceNames(numTraces, dataNum, pg.plotMetaData, wvResultY)

		for(i = 0; i < numTraces; i += 1)
			SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
			AppendTograph/W=$pg.win/C=(color.red, color.green, color.blue) wvY[][0]/TN=$traces[i] vs wvX[][i]
			annotation += SF_GetMetaDataAnnotationText(pg.plotMetaData, wvResultY, traces[i])
			SF_AddErrorBars(pg.graph, pg.win, wvY, traces[i])
		endfor
	elseif(xMxN == 1) // 2D vs 1D or 0D
		if(xPoints == 1) // 2D vs 0D -> extend X to 1D with constant value
			Redimension/N=(yPoints) wvX
			xPoints = yPoints
			wvX     = wvX[0]
		endif
		numTraces = yMxN
		SF_CheckNumTraces(pg.graph, numTraces)
		[WAVE/T traces, pg] = SF_CreateTraceNames(numTraces, dataNum, pg.plotMetaData, wvResultY)

		for(i = 0; i < numTraces; i += 1)
			SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
			AppendTograph/W=$pg.win/C=(color.red, color.green, color.blue) wvY[][i]/TN=$traces[i] vs wvX
			annotation += SF_GetMetaDataAnnotationText(pg.plotMetaData, wvResultY, traces[i])
			SF_AddErrorBars(pg.graph, pg.win, wvY, traces[i])
		endfor
	else // 2D vs 2D
		numTraces = WaveExists(wvX) ? max(1, max(yMxN, xMxN)) : max(1, yMxN)
		SF_CheckNumTraces(pg.graph, numTraces)
		[WAVE/T traces, pg] = SF_CreateTraceNames(numTraces, dataNum, pg.plotMetaData, wvResultY)

		if(yPoints != xPoints)
			DebugPrint("Size mismatch in data rows for plotting waves.")
		endif
		if(DimSize(wvY, COLS) != DimSize(wvX, COLS))
			DebugPrint("Size mismatch in entity columns for plotting waves.")
		endif
		for(i = 0; i < numTraces; i += 1)
			SF_CollectTraceData(gdIndex, plotFormData, traces[i], wvX, wvY)
			if(WaveExists(wvX))
				AppendTograph/W=$pg.win/C=(color.red, color.green, color.blue) wvY[][min(yMxN - 1, i)]/TN=$traces[i] vs wvX[][min(xMxN - 1, i)]
			else
				AppendTograph/W=$pg.win/C=(color.red, color.green, color.blue) wvY[][i]/TN=$traces[i]
			endif
			annotation += SF_GetMetaDataAnnotationText(pg.plotMetaData, wvResultY, traces[i])
			SF_AddErrorBars(pg.graph, pg.win, wvY, traces[i])
		endfor
	endif

	pg.showLegend = pg.showLegend && SF_GetShowLegend(wvY)

	dataCnt += 1

	return [dataCnt, gdIndex, annotation, formulaAddedOncePerDataset]
End

static Function SF_AddErrorBars(string graph, string win, WAVE wvY, string traceName, [variable rangeBeginX, variable rangeEndX, variable rangeBeginY, variable rangeEndY])

	rangeBeginX = ParamIsDefault(rangeBeginX) ? 0 : rangeBeginX
	rangeEndX   = ParamIsDefault(rangeEndX) ? Inf : rangeEndX
	rangeBeginY = ParamIsDefault(rangeBeginY) ? 0 : rangeBeginY
	rangeEndY   = ParamIsDefault(rangeEndY) ? Inf : rangeEndY

	DFREF dfr = SF_GetBrowserDF(graph)

	WAVE/Z errorbarYPlus = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_ERRORBARYPLUS)
	if(WaveExists(errorbarYPlus))
		WAVE wvYplusPermanent = GetSweepFormulaErrorbar(dfr, traceName, SF_META_ERRORBARYPLUS)
		Duplicate/O errorbarYPlus, wvYplusPermanent
	endif
	WAVE/Z errorbarYMinus = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_ERRORBARYMINUS)
	if(WaveExists(errorbarYMinus))
		WAVE wvYminusPermanent = GetSweepFormulaErrorbar(dfr, traceName, SF_META_ERRORBARYMINUS)
		Duplicate/O errorbarYMinus, wvYminusPermanent
	endif
	WAVE/Z errorbarXPlus = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_ERRORBARXPLUS)
	if(WaveExists(errorbarXPlus))
		WAVE wvXplusPermanent = GetSweepFormulaErrorbar(dfr, traceName, SF_META_ERRORBARXPLUS)
		Duplicate/O errorbarXPlus, wvXplusPermanent
	endif
	WAVE/Z errorbarXMinus = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_ERRORBARXMINUS)
	if(WaveExists(errorbarXMinus))
		WAVE wvXminusPermanent = GetSweepFormulaErrorbar(dfr, traceName, SF_META_ERRORBARXMINUS)
		Duplicate/O errorbarXMinus, wvXminusPermanent
	endif

	if(!WaveExists(errorbarYPlus) && !WaveExists(errorbarYMinus) && !WaveExists(errorbarXPlus) && !WaveExists(errorbarXMinus))
		return NaN
	endif

	if(WaveExists(errorbarYPlus) && WaveExists(errorbarYMinus) && WaveExists(errorbarXPlus) && WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, XY, wave=(wvXplusPermanent[rangeBeginX, rangeEndX], wvXminusPermanent[rangeBeginX, rangeEndX]), wave=(wvYplusPermanent[rangeBeginY, rangeEndY], wvYminusPermanent[rangeBeginY, rangeEndY])
	elseif(WaveExists(errorbarYPlus) && WaveExists(errorbarYMinus) && WaveExists(errorbarXPlus) && !WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, XY, wave=(wvXplusPermanent[rangeBeginX, rangeEndX],), wave=(wvYplusPermanent[rangeBeginY, rangeEndY], wvYminusPermanent[rangeBeginY, rangeEndY])
	elseif(WaveExists(errorbarYPlus) && WaveExists(errorbarYMinus) && !WaveExists(errorbarXPlus) && WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, XY, wave=(, wvXminusPermanent[rangeBeginX, rangeEndX]), wave=(wvYplusPermanent[rangeBeginY, rangeEndY], wvYminusPermanent[rangeBeginY, rangeEndY])
	elseif(WaveExists(errorbarYPlus) && WaveExists(errorbarYMinus) && !WaveExists(errorbarXPlus) && !WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, Y, wave=(wvYplusPermanent[rangeBeginY, rangeEndY], wvYminusPermanent[rangeBeginY, rangeEndY])
	elseif(WaveExists(errorbarYPlus) && !WaveExists(errorbarYMinus) && WaveExists(errorbarXPlus) && WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, XY, wave=(wvXplusPermanent[rangeBeginX, rangeEndX], wvXminusPermanent[rangeBeginX, rangeEndX]), wave=(wvYplusPermanent[rangeBeginY, rangeEndY],)
	elseif(WaveExists(errorbarYPlus) && !WaveExists(errorbarYMinus) && WaveExists(errorbarXPlus) && !WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, XY, wave=(wvXplusPermanent[rangeBeginX, rangeEndX],), wave=(wvYplusPermanent[rangeBeginY, rangeEndY],)
	elseif(WaveExists(errorbarYPlus) && !WaveExists(errorbarYMinus) && !WaveExists(errorbarXPlus) && !WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, Y, wave=(wvYplusPermanent[rangeBeginY, rangeEndY],)
	elseif(!WaveExists(errorbarYPlus) && WaveExists(errorbarYMinus) && WaveExists(errorbarXPlus) && WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, XY, wave=(wvXplusPermanent[rangeBeginX, rangeEndX], wvXminusPermanent[rangeBeginX, rangeEndX]), wave=(, wvYminusPermanent[rangeBeginY, rangeEndY])
	elseif(!WaveExists(errorbarYPlus) && WaveExists(errorbarYMinus) && WaveExists(errorbarXPlus) && !WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, XY, wave=(wvXplusPermanent[rangeBeginX, rangeEndX],), wave=(, wvYminusPermanent[rangeBeginY, rangeEndY])
	elseif(!WaveExists(errorbarYPlus) && WaveExists(errorbarYMinus) && !WaveExists(errorbarXPlus) && !WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, Y, wave=(wvYminusPermanent[rangeBeginY, rangeEndY],)
	elseif(!WaveExists(errorbarYPlus) && !WaveExists(errorbarYMinus) && WaveExists(errorbarXPlus) && WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, X, wave=(wvXplusPermanent[rangeBeginX, rangeEndX], wvXminusPermanent[rangeBeginX, rangeEndX])
	elseif(!WaveExists(errorbarYPlus) && !WaveExists(errorbarYMinus) && WaveExists(errorbarXPlus) && !WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, X, wave=(wvXplusPermanent[rangeBeginX, rangeEndX],)
	elseif(!WaveExists(errorbarYPlus) && !WaveExists(errorbarYMinus) && !WaveExists(errorbarXPlus) && WaveExists(errorbarXMinus))
		ErrorBars/W=$win $traceName, X, wave=(, wvXminusPermanent[rangeBeginX, rangeEndX])
	endif
End

static Function [variable dataCnt] SF_CreateTracesForResults(STRUCT SF_PlotterGraphStruct &pg)

	variable i, idx, showInTable, numData, formulaAddedOncePerDataset
	variable gdIndex // indexes in tracesInGraph wave and dataInGraph wave in SF_CollectTraceData(), both waves are stored in plotformData
	string annotation = ""

	WAVE/WAVE plotFormData = SF_CreatePlotFormulaDataWave()

	SF_FormulaPlotterExtendResultsIfCompatible(pg.formulaResults)

	if(WaveExists(pg.colorGroups))
		Duplicate/FREE pg.colorGroups, previousColorGroups
	else
		WAVE/ZZ previousColorGroups
	endif
	WAVE/Z pg.colorGroups = SF_GetColorGroups(pg.formulaResults, previousColorGroups)
	showInTable = SF_IsDataForTableDisplay(pg.formulaResults)

	numData = DimSize(pg.formulaResults, ROWS)
	for(i = 0; i < numData; i += 1)

		WAVE/Z wvResultX = pg.formulaResults[i][%FORMULAX]
		WAVE/Z wvResultY = pg.formulaResults[i][%FORMULAY]
		if(!WaveExists(wvResultY))
			continue
		endif
		if(JWN_GetNumberFromWaveNote(wvResultY, SF_META_DONOTPLOT) == 1)
			continue
		endif

		[dataCnt, gdIndex, annotation, formulaAddedOncePerDataset] = SF_CreateTracesForResultsImpl(pg, wvResultY, wvResultX, i, showInTable, plotFormData)
	endfor

	if(!IsEmpty(annotation))
		idx = GetNumberFromWaveNote(pg.wAnnotations, NOTE_INDEX)
		EnsureLargeEnoughWave(pg.wAnnotations, indexShouldExist = idx)
		pg.wAnnotations[idx] = annotation
		SetNumberInWaveNote(pg.wAnnotations, NOTE_INDEX, idx + 1)

		idx = GetNumberFromWaveNote(pg.formulaArgSetup, NOTE_INDEX)
		EnsureLargeEnoughWave(pg.formulaArgSetup, indexShouldExist = idx)
		pg.formulaArgSetup[idx] = pg.plotMetaData[%ARGSETUPSTACK]
		SetNumberInWaveNote(pg.formulaArgSetup, NOTE_INDEX, idx + 1)
	endif

	EnsureLargeEnoughWave(pg.collPlotFormData, indexShouldExist = pg.formulaCounter)
	WAVE/T    tracesInGraph = plotFormData[0]
	WAVE/WAVE dataInGraph   = plotFormData[1]
	Redimension/N=(gdIndex, -1) tracesInGraph, dataInGraph
	pg.collPlotFormData[pg.formulaCounter] = plotFormData

	return [dataCnt]
End

static Function SF_RestorePlotProperties(WAVE/WAVE prevPlotProperties)

	variable i, numPrevPlots
	string win

	numPrevPlots = GetNumberFromWaveNote(prevPlotProperties, NOTE_INDEX)
	for(i = 0; i < numPrevPlots; i += 1)
		WAVE/T plotName       = prevPlotProperties[i][%NAME]
		WAVE/Z cursorInfos    = prevPlotProperties[i][%CURSORS]
		WAVE/Z axesProperties = prevPlotProperties[i][%AXES]
		WAVE/Z annoInfos      = prevPlotProperties[i][%ANNOTATIONS]
		win = plotName[0]

		if(WaveExists(cursorInfos))
			RestoreCursors(win, cursorInfos)
		endif

		if(WaveExists(axesProperties))
			SetAxesProperties(win, axesProperties)
		endif

		if(WaveExists(annoInfos))
			WAVE/T annoInfosFiltered = FilterAnnotations(annoInfos, "^tag.*$")
			RestoreAnnotationPositions(win, annoInfosFiltered)
		endif
	endfor
End

static Function/S SF_CreateDataDisplayWindow(string graph, WAVE/WAVE formulaResults, WAVE/WAVE outputWindows, variable mode, WAVE prevPlotProperties)

	variable displayType, winIndex, restoreCursorInfo, winExists, isTableWindow
	string win, parentWin, subWin, guideName1, guideName2

	isTableWindow = SF_IsDataForTableDisplay(formulaResults)
	if(isTableWindow)
		displayType = SF_DISPLAYTYPE_TABLE
		WAVE/T winTables = outputWindows[%TABLE]
		winIndex = GetNumberFromWaveNote(winTables, NOTE_INDEX)
	else
		displayType = SF_DISPLAYTYPE_GRAPH
		WAVE/T winGraphs = outputWindows[%GRAPH]
		winIndex = GetNumberFromWaveNote(winGraphs, NOTE_INDEX)
	endif
	win = SF_GetDataDisplayWindowName(graph, displayType, mode, winIndex)
	if(!isTableWindow)
		restoreCursorInfo = SF_CollectPreviousPlotProperties(win, prevPlotProperties, mode)
	endif

	if(mode == SF_DM_NORMAL)
		if(displayType == SF_DISPLAYTYPE_TABLE)
			win = SF_NewSweepFormulaBaseWindow(win, graph, winType = WINTYPE_TABLE)
			SF_AddTableExtrasMain(win)
			EnsureLargeEnoughWave(winTables, indexShouldExist = winIndex)
			winTables[winIndex] = win
			SetNumberInWaveNote(winTables, NOTE_INDEX, winIndex + 1)
		elseif(displayType == SF_DISPLAYTYPE_GRAPH)
			win = SF_NewSweepFormulaBaseWindow(win, graph, winType = WINTYPE_GRAPH)
			EnsureLargeEnoughWave(winGraphs, indexShouldExist = winIndex)
			winGraphs[winIndex] = win
			SetNumberInWaveNote(winGraphs, NOTE_INDEX, winIndex + 1)
		else
			FATAL_ERROR("Unknown Display Type")
		endif
	elseif(mode == SF_DM_SUBWINDOWS)

		subWin    = LastStringFromList(win, sep = "#")
		parentWin = RemoveEnding(win, "#" + subWin)
		if(WindowExists(parentWin) && winIndex == 0)
			SF_ClearPlotPanel(parentWin)
		elseif(!WindowExists(parentWin))
			parentWin = SF_NewSweepFormulaBaseWindow(parentWin, graph)

			// base window setup if window did not exist before calling SF_NewSweepFormulaBaseWindow
			DefineGuide/W=$parentWin customLeft={FL, 0.0, FR}
			DefineGuide/W=$parentWin customRight={FL, 1.0, FR}

			if(displayType == SF_DISPLAYTYPE_TABLE)
				SF_AddTableExtrasMain(parentWin)
			endif
		endif

		if(restoreCursorInfo)
			ShowInfo/W=$parentWin
		endif

		if(winIndex == 0)
			guideName1 = SF_PLOTTER_GUIDENAME + num2istr(0)
			DefineGuide/W=$parentWin $guideName1={FT, 0, FB}
		endif

		guideName1 = SF_PLOTTER_GUIDENAME + num2istr(winIndex)
		guideName2 = SF_PLOTTER_GUIDENAME + num2istr(winIndex + 1)
		DefineGuide/W=$parentWin $guideName2={FT, 0, FB}

		if(displayType == SF_DISPLAYTYPE_TABLE)
			Edit/HOST=$parentWin/FG=(customLeft, $guideName1, customRight, $guideName2)/N=$subWin
			win = parentWin + "#" + S_name
			SF_AddTableExtrasSub(win)
			EnsureLargeEnoughWave(winTables, indexShouldExist = winIndex)
			winTables[winIndex] = win
			SetNumberInWaveNote(winTables, NOTE_INDEX, winIndex + 1)
		elseif(displayType == SF_DISPLAYTYPE_GRAPH)
			Display/HOST=$parentWin/FG=(customLeft, $guideName1, customRight, $guideName2)/N=$subWin
			win = parentWin + "#" + S_name
			EnsureLargeEnoughWave(winGraphs, indexShouldExist = winIndex)
			winGraphs[winIndex] = win
			SetNumberInWaveNote(winGraphs, NOTE_INDEX, winIndex + 1)
		else
			FATAL_ERROR("Unknown Display Type")
		endif
	else
		FATAL_ERROR("Unknown Window Mode")
	endif

	if(displayType == SF_DISPLAYTYPE_TABLE)
		RemoveAllColumnsFromTable(win)
	elseif(displayType == SF_DISPLAYTYPE_GRAPH)
		RemoveTracesFromGraph(win)
		ModifyGraph/W=$win swapXY=0
	else
		FATAL_ERROR("Unknown Display Type")
	endif

	return win
End

static Function [STRUCT SF_PlotterGraphStruct pg] SF_ResetPlotterGraphStruct(string graph)

	pg.graph = graph
	pg.win   = ""

	WAVE/Z pg.colorGroups = $""
	pg.traceCnt       = 0
	pg.postPlotPSX    = 0
	pg.showLegend     = 1
	pg.formulaCounter = 0

	Make/FREE/T/N=0 xAxisLabels, yAxisLabels
	WAVE pg.xAxisLabels = xAxisLabels
	WAVE pg.yAxisLabels = yAxisLabels

	Make/FREE=1/T/N=(MINIMUM_WAVE_SIZE) wAnnotations, formulaArgSetup, tableFormulas
	SetNumberInWaveNote(wAnnotations, NOTE_INDEX, 0)
	SetNumberInWaveNote(formulaArgSetup, NOTE_INDEX, 0)
	SetNumberInWaveNote(tableFormulas, NOTE_INDEX, 0)
	WAVE/T pg.wAnnotations    = wAnnotations
	WAVE/T pg.formulaArgSetup = formulaArgSetup
	WAVE/T pg.tableFormulas   = tableFormulas

	Make/FREE=1/WAVE/N=(MINIMUM_WAVE_SIZE) collPlotFormData
	WAVE pg.collPlotFormData = collPlotFormData

	Make/FREE=1/D/N=2 panelsCreated
	SetDimLabel ROWS, 0, GRAPH, panelsCreated
	SetDimLabel ROWS, 1, TABLE, panelsCreated
	WAVE pg.panelsCreated = panelsCreated

	WAVE/Z/WAVE pg.formulaResults = $""
	WAVE/Z/T    pg.plotMetaData   = $""

	return [pg]
End

/// @brief  Plot the formula using the data from graph
///
/// @param graph  graph to pass to SF_FormulaExecutor
/// @param formula formula to plot
/// @param dmMode  [optional, default DM_SUBWINDOWS] display mode that defines how multiple sweepformula graphs are arranged
/// @param lineVars  [optional, default NaN] number of lines in the SF notebook with variable assignments in front of the formula
static Function SF_FormulaPlotter(string graph, string formula, [variable dmMode, variable lineVars])

	variable i, j, k, dataCnt, numGraphs, numPlotAND, numPlotWITH
	variable winDisplayMode, line, lineGraph, lineGraphFormula, xFormulaOffset
	variable keepUserSelection, showInTable, isFullPlot
	string wList
	string formulasRemain, moreFormulas, yAndXFormula, xFormula, yFormula
	STRUCT SF_PlotterGraphStruct pg

	winDisplayMode = ParamIsDefault(dmMode) ? SF_DM_SUBWINDOWS : dmMode
	lineVars       = ParamIsDefault(lineVars) ? NaN : lineVars
	ASSERT(winDisplaymode == SF_DM_NORMAL || winDisplaymode == SF_DM_SUBWINDOWS, "Invalid display mode.")

	DFREF dfr = SF_GetBrowserDF(graph)

	WAVE/T graphCode = SF_SplitCodeToGraphs(formula)

	SVAR lastCode = $GetLastSweepFormulaCode(dfr)
	keepUserSelection = !CmpStr(lastCode, formula)

	numGraphs = DimSize(graphCode, ROWS)
	wList     = ""

	WAVE/WAVE outputWindows      = GetSFOutputWindowNames()
	WAVE/T    winTables          = outputWindows[%TABLE]
	WAVE/T    winGraphs          = outputWindows[%GRAPH]
	WAVE/WAVE prevPlotProperties = GetSFPlotProperties()

	for(i = 0; i < numGraphs; i += 1)

		formulasRemain = graphCode[i][%GRAPHCODE]
		lineGraph      = str2num(graphCode[i][%LINE])

		[pg] = SF_ResetPlotterGraphStruct(graph)

		do

			SplitString/E=SF_SWEEPFORMULA_WITH_REGEXP formulasRemain, yAndXFormula, moreFormulas
			if(!V_flag)
				break
			endif
			line             = lineVars + lineGraph + lineGraphFormula
			lineGraphFormula = SF_GetLineNumberOfRemainingCode(formulasRemain, moreFormulas)
			formulasRemain   = moreFormulas

			[xFormula, yFormula, xFormulaOffset] = SF_SplitGraphsToFormula(yAndXFormula)
			SFH_ASSERT(!IsEmpty(yFormula), "Could not determine y [vs x] formula pair.")

			try
				[WAVE/WAVE formulaResults, WAVE/T plotMetaData] = SF_GatherFormulaResults(xFormula, yFormula, graph, line, xFormulaOffset)
				WAVE/WAVE pg.formulaResults = formulaResults
				WAVE/T    pg.plotMetaData   = plotMetaData
			catch
				SF_KillEmptyDataWindows(winGraphs)
				SF_KillEmptyDataWindows(winTables)
				Abort
			endtry

			isFullPlot = SF_IsDataForFullPlotting(formulaResults)
			numPlotAND = isFullPlot ? DimSize(formulaResults, ROWS) : 1
			for(j = 0; j < numPlotAND; j += 1)
				if(isFullPlot)
					WAVE/WAVE plotsWITH = formulaResults[j][%FORMULAY]
				endif
				numPlotWITH = isFullPlot ? DimSize(plotsWITH, ROWS) : 1
				for(k = 0; k < numPlotWITH; k += 1)
					if(isFullPlot)
						WAVE/Z/WAVE wvYRef = plotsWITH[k][%FORMULAY]
						WAVE/Z/WAVE wvXRef = plotsWITH[k][%FORMULAX]
						[WAVE/WAVE formulaResultsInner, WAVE/T plotMetaDataInner] = SF_FillFormulaResults(wvYRef, wvXRef, yFormula)
						WAVE/WAVE pg.formulaResults = formulaResultsInner
						WAVE/T    pg.plotMetaData   = plotMetaDataInner
					endif

					SF_GatherAxisLabels(pg.formulaResults, pg.plotMetaData[%XAXISLABEL], "FORMULAX", pg.xAxisLabels)
					SF_GatherAxisLabels(pg.formulaResults, pg.plotMetaData[%YAXISLABEL], "FORMULAY", pg.yAxisLabels)

					showInTable = SF_IsDataForTableDisplay(pg.formulaResults)
					if(!pg.panelsCreated[%GRAPH] && !showInTable)
						pg.win                   = SF_CreateDataDisplayWindow(pg.graph, pg.formulaResults, outputWindows, winDisplayMode, prevPlotProperties)
						pg.panelsCreated[%GRAPH] = 1
						if(winDisplaymode == SF_DM_NORMAL)
							wList = AddListItem(pg.win, wList)
						endif
					elseif(!pg.panelsCreated[%TABLE] && showInTable)
						pg.win                   = SF_CreateDataDisplayWindow(pg.graph, pg.formulaResults, outputWindows, winDisplayMode, prevPlotProperties)
						pg.panelsCreated[%TABLE] = 1
						if(winDisplaymode == SF_DM_NORMAL)
							wList = AddListItem(pg.win, wList)
						endif
					elseif(!showInTable)
						pg.win = winGraphs[GetNumberFromWaveNote(winGraphs, NOTE_INDEX) - 1]
					else
						pg.win = winTables[GetNumberFromWaveNote(winTables, NOTE_INDEX) - 1]
					endif

					if(!cmpstr(pg.plotMetaData[%DATATYPE], SF_DATATYPE_PSX))
						PSX_Plot(pg.win, pg.graph, pg.formulaResults, pg.plotMetaData)
						pg.postPlotPSX = 1
						break
					endif

					[dataCnt]          = SF_CreateTracesForResults(pg)
					pg.formulaCounter += 1
				endfor

				if(j < (numPlotAND - 1))
					SF_FinishPlotWindow(pg, winGraphs)
					[pg] = SF_ResetPlotterGraphStruct(graph)
				endif
			endfor
		while(1)

		SF_FinishPlotWindow(pg, winGraphs)

	endfor

	if(keepUserSelection)
		SF_RestorePlotProperties(prevPlotProperties)
	endif

	if(winDisplayMode == SF_DM_SUBWINDOWS)
		SF_TileExistingData(outputWindows)
	endif
	SF_KillEmptyDataWindows(winGraphs)
	SF_KillEmptyDataWindows(winTables)

	SF_KillOldDataDisplayWindows(graph, winDisplayMode, wList, outputWindows)
End

/// @brief Sets axis properties for plots of the SF formula plotter. The properties are stored in the plotMetaData wave.
static Function SF_SetAxisProperties(STRUCT SF_PlotterGraphStruct &pg)

	variable xaxisOffset, yaxisOffset, xaxisPercent, yaxisPercent

	xaxisOffset = str2num(pg.plotMetaData[%XAXISOFFSET])
	if(!IsNaN(xaxisOffset))
		ModifyGraph/W=$pg.win axOffset(bottom)=xaxisOffset
	endif
	yaxisOffset = str2num(pg.plotMetaData[%YAXISOFFSET])
	if(!IsNaN(yaxisOffset))
		ModifyGraph/W=$pg.win axOffset(left)=yaxisOffset
	endif
	xaxisPercent = str2num(pg.plotMetaData[%XAXISPERCENT])
	if(!IsNaN(xaxisPercent))
		ModifyGraph/W=$pg.win axisEnab(bottom)={0, xaxisPercent * PERCENT_TO_ONE}
	endif
	yaxisPercent = str2num(pg.plotMetaData[%YAXISPERCENT])
	if(!IsNaN(yaxisPercent))
		ModifyGraph/W=$pg.win axisEnab(left)={0, yaxisPercent * PERCENT_TO_ONE}
	endif
End

static Function SF_FinishPlotWindow(STRUCT SF_PlotterGraphStruct &pg, WAVE/T winGraphs)

	variable formulasAreDifferent, numTableFormulas
	string winHook

	numTableFormulas = GetNumberFromWaveNote(pg.tableFormulas, NOTE_INDEX)
	if(numTableFormulas)
		Redimension/N=(numTableFormulas) pg.tableFormulas
		SetWindow $pg.win, userdata($SF_UDATA_TABLEFORMULAS)=WaveToJSON(pg.tableFormulas)
	endif

	if(pg.panelsCreated[%GRAPH])

		pg.win = winGraphs[GetNumberFromWaveNote(winGraphs, NOTE_INDEX) - 1]

		SF_SetAxisProperties(pg)

		if(pg.showLegend)
			formulasAreDifferent = SF_AddPlotLegend(pg)
		endif

		SF_AddPlotTicks(pg.graph, pg.win, pg.formulaResults)

		winHook = JWN_GetStringFromWaveNote(pg.formulaResults, SF_META_WINDOW_HOOK)
		if(!IsEmpty(winHook))
			SetWindow $pg.win, tooltipHook(SweepFormulaTraceValue)=$winHook
		endif

		SF_AddPlotTraceStyle(pg, formulasAreDifferent)

		if(pg.traceCnt > 0)
			SF_AddPlotLabels(pg.win, pg.xAxisLabels, pg.yAxisLabels)
		endif
	endif

	if(pg.postPlotPSX)
		PSX_PostPlot(pg.win)
	endif
End

static Function SF_AddPlotTraceStyle(STRUCT SF_PlotterGraphStruct &pg, variable formulasAreDifferent)

	variable i, j, numTraces, markerCode, lineCode, isCategoryAxis, tagCounter, lineStyle, overrideMarker, traceToFront
	string trace, info, tagText, name, wvName

	for(i = 0; i < pg.formulaCounter; i += 1)
		WAVE/WAVE plotFormData  = pg.collPlotFormData[i]
		WAVE/T    tracesInGraph = plotFormData[0]
		WAVE/WAVE dataInGraph   = plotFormData[1]
		numTraces  = DimSize(tracesInGraph, ROWS)
		markerCode = formulasAreDifferent ? i : 0
		markerCode = SFH_GetPlotMarkerCodeSelection(markerCode)
		lineCode   = formulasAreDifferent ? i : 0
		lineCode   = SFH_GetPlotLineCodeSelection(lineCode)
		for(j = 0; j < numTraces; j += 1)

			WAVE/Z wvX = dataInGraph[j][%WAVEX]
			WAVE   wvY = dataInGraph[j][%WAVEY]
			trace = tracesInGraph[j]

			info           = AxisInfo(pg.win, "left")
			isCategoryAxis = (NumberByKey("ISCAT", info) == 1)

			if(isCategoryAxis)
				WAVE traceColorHolder = wvX
			else
				WAVE traceColorHolder = wvY
			endif

			WAVE/Z traceColor = JWN_GetNumericWaveFromWaveNote(traceColorHolder, SF_META_TRACECOLOR)
			if(WaveExists(traceColor))
				switch(DimSize(traceColor, ROWS))
					case 3:
						ModifyGraph/W=$pg.win rgb($trace)=(traceColor[0], traceColor[1], traceColor[2])
						break
					case 4:
						ModifyGraph/W=$pg.win rgb($trace)=(traceColor[0], traceColor[1], traceColor[2], traceColor[3])
						break
					default:
						FATAL_ERROR("Invalid size of trace color wave")
				endswitch
			endif

			tagText = JWN_GetStringFromWaveNote(wvY, SF_META_TAG_TEXT)
			if(!IsEmpty(tagText))
				name = "tag" + num2str(tagCounter++)
				Tag/C/N=$name/W=$pg.win/F=0/L=0/X=0.00/Y=0.00 $trace, 0, tagText
			endif

			ModifyGraph/W=$pg.win mode($trace)=SF_DeriveTraceDisplayMode(wvX, wvY)

			lineStyle = JWN_GetNumberFromWaveNote(wvY, SF_META_LINESTYLE)
			if(IsValidTraceLineStyle(lineStyle))
				ModifyGraph/W=$pg.win lStyle($trace)=lineStyle
			elseif(formulasAreDifferent)
				ModifyGraph/W=$pg.win lStyle($trace)=lineCode
			endif

			WAVE/Z customMarkerAsFree = JWN_GetNumericWaveFromWaveNote(wvY, SF_META_MOD_MARKER)
			if(WaveExists(customMarkerAsFree))
				DFREF dfrWork = SFH_GetWorkingDF(pg.graph)
				wvName = "customMarker_" + NameOfWave(wvY)
				WAVE customMarker = MoveFreeWaveToPermanent(customMarkerAsFree, dfrWork, wvName)
				ASSERT(DimSize(wvY, ROWS) == DimSize(customMarker, ROWS), "Marker size mismatch")
				ModifyGraph/W=$pg.win zmrkNum($trace)={customMarker}
			else
				overrideMarker = JWN_GetNumberFromWaveNote(wvY, SF_META_MOD_MARKER)

				if(!IsNaN(overrideMarker))
					markerCode = overrideMarker
				endif

				ModifyGraph/W=$pg.win marker($trace)=markerCode
			endif

			traceToFront = JWN_GetNumberFromWaveNote(wvY, SF_META_TRACETOFRONT)
			traceToFront = IsNaN(traceToFront) ? 0 : !!traceToFront
			if(traceToFront)
				ReorderTraces/W=$pg.win _front_, {$trace}
			endif

		endfor
	endfor
End

static Function SF_AddPlotTicks(string graph, string win, WAVE formulaResults)

	string wvName

	WAVE/Z xTickLabelsAsFree    = JWN_GetTextWaveFromWaveNote(formulaResults, SF_META_XTICKLABELS)
	WAVE/Z xTickPositionsAsFree = JWN_GetNumericWaveFromWaveNote(formulaResults, SF_META_XTICKPOSITIONS)

	if(WaveExists(xTickLabelsAsFree) && WaveExists(xTickPositionsAsFree))
		DFREF dfrWork = SFH_GetWorkingDF(graph)
		wvName = "xTickLabels_" + win + "_" + NameOfWave(formulaResults)
		WAVE xTickLabels = MoveFreeWaveToPermanent(xTickLabelsAsFree, dfrWork, wvName)

		wvName = "xTickPositions_" + win + "_" + NameOfWave(formulaResults)
		WAVE xTickPositions = MoveFreeWaveToPermanent(xTickPositionsAsFree, dfrWork, wvName)

		ModifyGraph/Z/W=$win userticks(bottom)={xTickPositions, xTickLabels}
	endif

	WAVE/Z yTickLabelsAsFree    = JWN_GetTextWaveFromWaveNote(formulaResults, SF_META_YTICKLABELS)
	WAVE/Z yTickPositionsAsFree = JWN_GetNumericWaveFromWaveNote(formulaResults, SF_META_YTICKPOSITIONS)

	if(WaveExists(yTickLabelsAsFree) && WaveExists(yTickPositionsAsFree))
		DFREF dfrWork = SFH_GetWorkingDF(graph)
		wvName = "yTickLabels_" + win + "_" + NameOfWave(formulaResults)
		WAVE yTickLabels = MoveFreeWaveToPermanent(yTickLabelsAsFree, dfrWork, wvName)

		wvName = "yTickPositions_" + win + "_" + NameOfWave(formulaResults)
		WAVE yTickPositions = MoveFreeWaveToPermanent(yTickPositionsAsFree, dfrWork, wvName)

		ModifyGraph/Z/W=$win userticks(left)={yTickPositions, yTickLabels}

		Make/FREE yTickPositionsWorkaround = {0, 1}
		if(EqualWaves(yTickPositions, yTickPositionsWorkaround, EQWAVES_DATA))
			// @todo workaround bug 4531 so that we get tick labels even with only constant y values
			SetAxis/W=$win/Z left, 0, 1
		endif
	endif
End

static Function SF_AddPlotLegend(STRUCT SF_PlotterGraphStruct &pg)

	variable numAnnotations, formulasAreDifferent
	string customLegend
	string annotation = ""

	numAnnotations = GetNumberFromWaveNote(pg.wAnnotations, NOTE_INDEX)
	customLegend   = JWN_GetStringFromWaveNote(pg.formulaResults, SF_META_CUSTOM_LEGEND)

	if(!IsEmpty(customLegend))
		annotation = customLegend
	elseif(numAnnotations > 0)
		pg.wAnnotations[0, numAnnotations - 1] = SF_ShrinkLegend(pg.wAnnotations[p])
		Redimension/N=(numAnnotations) pg.wAnnotations, pg.formulaArgSetup
		formulasAreDifferent = SFH_EnrichAnnotations(pg.wAnnotations, pg.formulaArgSetup)
		annotation           = TextWaveToList(pg.wAnnotations, "")
		annotation           = TrimString(annotation)
	endif

	if(!IsEmpty(annotation))
		Legend/W=$pg.win/C/N=$SF_ANNOTATION_NAME/F=2 annotation
	endif

	return formulasAreDifferent
End

static Function SF_AddPlotLabels(string win, WAVE xAxisLabels, WAVE yAxisLabels)

	string xAxisLabel, yAxisLabel

	xAxisLabel = SF_CombineAxisLabels(xAxisLabels)
	if(!IsEmpty(xAxisLabel))
		Label/W=$win bottom, xAxisLabel
		ModifyGraph/W=$win tickUnit(bottom)=1
	endif

	yAxisLabel = SF_CombineAxisLabels(yAxisLabels)
	if(!IsEmpty(yAxisLabel))
		Label/W=$win left, yAxisLabel
		ModifyGraph/W=$win tickUnit(left)=1
	endif

	ModifyGraph/W=$win zapTZ(bottom)=1
End

/// @brief Kills sweepformula display windows (graph/table) that might be open from a previous formula plotter call
///        This function does not kill windows when the displaymodes is switched SF_DM_NORMAL <-> SF_DM_SUBWINDOWS in subsequent plotter calls.
static Function SF_KillOldDataDisplayWindows(string graph, variable mode, string wList, WAVE/WAVE outputWindows)

	variable i, wType, numWins
	string win, winNameTemplate, exWList

	if(mode == SF_DM_NORMAL)
		winNameTemplate = SF_GetFormulaWinNameTemplate(graph)
		wType           = WINDOWTYPE_GRAPH | WINDOWTYPE_TABLE
		exWList         = WinList(winNameTemplate + "*", ";", "WIN:" + num2istr(wType))
		numWins         = ItemsInList(exWList)
		for(i = 0; i < numWins; i += 1)
			win = StringFromList(i, exWList)
			if(WhichListItem(win, wList) == -1)
				KillWindow/Z $win
			endif
		endfor
	elseif(mode == SF_DM_SUBWINDOWS)
		WAVE/T winTables = outputWindows[%TABLE]
		numWins = GetNumberFromWaveNote(winTables, NOTE_INDEX)
		if(!numWins)
			win = SF_GetDataDisplayWindowName(graph, SF_DISPLAYTYPE_TABLE, SF_DM_SUBWINDOWS, 0)
			win = RemoveEnding(win, "#" + LastStringFromList(win, sep = "#"))
			KillWindow/Z $win
		endif
		WAVE/T winGraphs = outputWindows[%GRAPH]
		numWins = GetNumberFromWaveNote(winGraphs, NOTE_INDEX)
		if(!numWins)
			win = SF_GetDataDisplayWindowName(graph, SF_DISPLAYTYPE_GRAPH, SF_DM_SUBWINDOWS, 0)
			win = RemoveEnding(win, "#" + LastStringFromList(win, sep = "#"))
			KillWindow/Z $win
		endif
	endif
End

static Function SF_DeriveTraceDisplayMode(WAVE/Z wvX, WAVE wvY)

	variable traceMode, numYPoints

	numYPoints = DimSize(wvY, ROWS)
	traceMode  = JWN_GetNumberFromWaveNote(wvY, SF_META_TRACE_MODE)
	if(IsValidTraceDisplayMode(traceMode))
		if(traceMode == TRACE_DISPLAY_MODE_LINES)
			if(numYPoints > 1)
				return traceMode
			endif

			return TRACE_DISPLAY_MODE_MARKERS
		endif

		return traceMode
	endif

	if(numYPoints < SF_MAX_NUMPOINTS_FOR_MARKERS                \
	   && (!WaveExists(wvX)                                     \
	       || DimSize(wvx, ROWS) < SF_MAX_NUMPOINTS_FOR_MARKERS))
		return TRACE_DISPLAY_MODE_MARKERS
	endif

	return TRACE_DISPLAY_MODE_LINES
End

static Function SF_GetShowLegend(WAVE wv)

	variable showLegend

	showLegend = JWN_GetNumberFromWaveNote(wv, SF_META_SHOW_LEGEND)

	if(IsFinite(showLegend))
		return !!showLegend
	endif

	return 1
End

/// @brief utility function for @c SF_FormulaPlotter
///
/// split dimension @p dim of wave @p wv into slices of size @p split and get
/// the starting index @p i
///
static Function SF_SplitPlotting(WAVE wv, variable dim, variable i, variable split)

	return min(i, floor(DimSize(wv, dim) / split) - 1) * split
End

/// @brief Pre process code entered into the notebook
///        - unify line endings to CR
///        - remove comments at line ending
///        - cut off last CR from back conversion with TextWaveToList
Function/S SF_PreprocessInput(string formula)

	variable endsWithCR

	if(IsEmpty(formula))
		return ""
	endif

	formula    = NormalizeToEOL(formula, SF_CHAR_CR)
	endsWithCR = StringEndsWith(formula, SF_CHAR_CR)

	WAVE/T lines = ListToTextWave(formula, SF_CHAR_CR)
	lines[] = StringFromList(0, lines[p], SF_CHAR_COMMENT)
	lines[] = RemoveEndingRegExp(lines[p], "[[:space:]]+$")
	formula = TextWaveToList(lines, SF_CHAR_CR)
	if(IsEmpty(formula))
		return ""
	endif

	if(!endsWithCR)
		formula = formula[0, strlen(formula) - 2]
	endif

	return formula
End

Function SF_button_sweepFormula_check(STRUCT WMButtonAction &ba) : ButtonControl

	string mainPanel, bsPanel, formula_nb, json_nb, formula, errMsg, text
	variable errState

	switch(ba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(ba.win)
			bsPanel   = BSP_GetPanel(mainPanel)

			if(!BSP_HasBoundDevice(bsPanel))
				DebugPrint("Unbound device in DataBrowser")
				break
			endif

			formula_nb = BSP_GetSFFormula(ba.win)
			formula    = GetNotebookText(formula_nb, mode = 2)

			NVAR jsonID = $GetSweepFormulaJSONid(SF_GetBrowserDF(mainPanel))
			SF_ClearSFOutputState()
			SF_DisplayOutputStateInGUI(bsPanel)

			try
				SF_CheckInputCode(formula, mainPanel)
			catch
#ifdef DEBUGGING_ENABLED
				SFP_SaveParserStateLog()
#endif // DEBUGGING_ENABLED
				SF_MarkErrorLocationInNotebook(mainPanel)
				JSON_Release(jsonID, ignoreErr = 1)
				jsonID = NaN
			endtry
			SF_DisplayOutputStateInGUI(bsPanel)

			json_nb = BSP_GetSFJSON(mainPanel)
			if(JSON_IsValid(jsonID))
				text = JSON_Dump(jsonID, indent = 2, ignoreErr = 1)
				text = NormalizeToEOL(text, "\r")
				ReplaceNotebookText(json_nb, text)
			else
				ReplaceNotebookText(json_nb, "")
			endif

			break
		default:
			break
	endswitch

	return 0
End

static Function SF_ClearSFOutputState()

	SVAR result = $GetSweepFormulaOutputMessage()
	result = ""
	NVAR severity = $GetSweepFormulaOutputSeverity()
	severity = SF_MSG_OK
End

Function SF_DisplayOutputStateInGUI(string databrowser)

	variable        severity
	string          error
	STRUCT RGBColor s

	string nb = BSP_GetSFOutputState(databrowser)

	severity = ROVar(GetSweepFormulaOutputSeverity())
	ASSERT(severity == SF_MSG_ERROR || severity == SF_MSG_OK || severity == SF_MSG_WARN, "Unknown severity for SF error")
	error = ROStr(GetSweepFormulaOutputMessage())

	ReplaceNotebookText(nb, error)
	[s] = SF_GetErrorColorsFromSeverity(severity)
	Notebook $nb, selection={startOfFile, endOfFile}, font="Lucida Console", textRGB=(s.red, s.green, s.blue)
	NotebookSelectionAtEnd(nb)
End

Function [WAVE/T varAssignments, string code] SF_GetVariableAssignments(string preProcCode)

	variable i, numLines, varCnt, dimVarName
	string line, varName, formula
	string lineEnd = "\r"
	string varPart = ""

	WAVE/T varAssignments = GetSFVarAssignments()
	dimVarName = FindDimlabel(varAssignments, COLS, "VARNAME")

	numLines = ItemsInList(preProcCode, lineEnd)
	for(i = 0; i < numLines; i += 1)
		line = StringFromList(i, preProcCode, lineEnd)
		if(IsEmpty(line))
			varPart += lineEnd
			continue
		endif
		[varName, formula] = SF_SplitVariableAssignment(line)
		if(IsEmpty(varName))
			break
		endif
		SFH_ASSERT(IsValidObjectName(varName), "Invalid SF variable name")
		varPart += line + lineEnd

		EnsureLargeEnoughWave(varAssignments, indexShouldExist = varCnt)
		varAssignments[varCnt][dimVarName]  = varName
		varAssignments[varCnt][%EXPRESSION] = formula
		varAssignments[varCnt][%LINE]       = num2istr(i)
		varAssignments[varCnt][%OFFSET]     = num2istr(strsearch(line, "=", 0) + 1)

		varCnt += 1
	endfor
	if(!varCnt)
		return [$"", preProcCode]
	endif
	Redimension/N=(varCnt, -1) varAssignments

	if(varCnt > 1)
		Duplicate/FREE/RMD=[][dimVarName] varAssignments, dupCheck
		FindDuplicates/FREE/CI/DT=dups dupCheck
		SFH_ASSERT(!DimSize(dups, ROWS), "Duplicate variable name.")
	endif

	if(!cmpstr(RemoveEnding(varPart, lineEnd), RemoveEnding(preProcCode, lineEnd)))
		return [varAssignments, ""]
	endif

	return [varAssignments, ReplaceString(varPart, preProcCode, "")]
End

static Function/S SF_CheckVariableAssignments(string preProcCode, variable jsonId)

	variable i, numAssignments, jsonIdFormula, srcLocId, line, offset
	string code, jsonPath, formula

	[WAVE/T varAssignments, code] = SF_GetVariableAssignments(preProcCode)
	if(!WaveExists(varAssignments))
		return code
	endif

	numAssignments = DimSize(varAssignments, ROWS)
	for(i = 0; i < numAssignments; i += 1)
		formula = varAssignments[i][%EXPRESSION]
		line    = str2num(varAssignments[i][%LINE])
		offset  = str2num(varAssignments[i][%OFFSET])
		SFH_StoreAssertInfoParser(line, offset)
		[jsonIdFormula, srcLocId] = SFP_ParseFormulaToJSON(formula)
		jsonPath                  = "/variable:" + varAssignments[i][%VARNAME]
		JSON_AddJSON(jsonID, jsonPath, jsonIdFormula)
		SF_AddSourceInfoToJSON(jsonId, "/variables", jsonPath, srcLocId, formula, line, offset)
		JSON_Release(jsonIdFormula)
	endfor

	return code
End

/// @brief When preprocessing the SF notebook content there are occurances where a part at the front is split off
///        for further processing. For the source location tracking it is important to track the current line number.
///        Thus, the number of `<CR>` in the split off part need to be counted. This helper function counts these `<CR>`s.
///
/// @param all     full string content
/// @param endPart remaining string content (where all == split_off_part + endPart)
static Function SF_GetLineNumberOfRemainingCode(string all, string endPart)

	variable len1, len2
	string firstPart

	len1 = strlen(all)
	len2 = strlen(endPart)
	ASSERT(len1 >= len2, "endPart must be equal or smaller than the full string")
	firstPart = all[0, len1 - len2]
	WAVE/T tmp = ListToTextWave(firstPart, SF_CHAR_CR)

	return DimSize(tmp, ROWS) - 1
End

/// @brief Checks input code, sets globals for jsonId and error string
static Function SF_CheckInputCode(string code, string graph)

	variable i, numGraphs, jsonIDy, jsonIDx, subFormulaCnt, srcLocId, lineVars, lineGraphFormula, line, xFormulaOffset
	string jsonPath, xFormula, yFormula, formulasRemain, subPath, yAndXFormula, codeWithoutVariables, preProcCode, prefix
	string moreFormulas

	NVAR jsonID = $GetSweepFormulaJSONid(SF_GetBrowserDF(graph))
	JSON_Release(jsonID, ignoreErr = 1)
	jsonID = JSON_New()
	JSON_AddObjects(jsonID, "")

	preProcCode = SF_PreprocessInput(code)

	codeWithoutVariables = SF_CheckVariableAssignments(preProcCode, jsonID)
	lineVars             = SF_GetLineNumberOfRemainingCode(preProcCode, codeWithoutVariables)

	WAVE/T graphCode = SF_SplitCodeToGraphs(codeWithoutVariables)

	numGraphs = DimSize(graphCode, ROWS)
	for(i = 0; i < numGraphs; i += 1)
		subFormulaCnt  = 0
		formulasRemain = graphCode[i][%GRAPHCODE]
		sprintf jsonPath, "/graph_%d", i
		JSON_AddObjects(jsonID, jsonPath)

		do
			SplitString/E=SF_SWEEPFORMULA_WITH_REGEXP formulasRemain, yAndXFormula, moreFormulas
			if(!V_flag)
				break
			endif
			line             = lineVars + str2num(graphCode[i][%LINE]) + lineGraphFormula
			lineGraphFormula = SF_GetLineNumberOfRemainingCode(formulasRemain, moreFormulas)
			formulasRemain   = moreFormulas

			[xFormula, yFormula, xFormulaOffset] = SF_SplitGraphsToFormula(yAndXFormula)
			SFH_ASSERT(!IsEmpty(yFormula), "Could not determine y [vs x] formula pair.")

			sprintf subPath, "%s/pair_%d", jsonPath, subFormulaCnt
			JSON_AddTreeObject(jsonID, subPath)
			prefix = subPath

			SFH_StoreAssertInfoParser(line, 0)
			[jsonIDy, srcLocId] = SFP_ParseFormulaToJSON(yFormula)
			subPath             = prefix + "/formula_y"
			JSON_AddJSON(jsonID, subPath, jsonIDy)
			JSON_Release(jsonIDy)

			SF_AddSourceInfoToJSON(jsonId, prefix, "/formula_y", srcLocId, yFormula, line, 0)

			if(!IsEmpty(xFormula))
				SFH_StoreAssertInfoParser(line, xFormulaOffset)
				[jsonIDx, srcLocId] = SFP_ParseFormulaToJSON(xFormula)

				subPath = prefix + "/formula_x"
				JSON_AddJSON(jsonID, subPath, jsonIDx)
				JSON_Release(jsonIDx)

				SF_AddSourceInfoToJSON(jsonId, prefix, "/formula_x", srcLocId, xFormula, line, xFormulaOffset)
			endif

			subFormulaCnt += 1
		while(1)
	endfor
End

/// @brief Helper function to add base source location information to a JSON created for "check"
///        The full path is build from: jsonPath + "/source_location" + subPath + `<internalPathForElement>`
///        Internal paths are (path : content):
///        /source : formula
///        /line : line number
///        /start_offset : offset
///        /source_map : here JSON form srcLocId is added
///
///        srcLocId is created and returned by SFP_ParseFormulaToJSON
///
/// @param jsonId   JSON created for "check"
/// @param jsonPath the base JSON path for the specific formula set (from graph/pair) or variable
/// @param subPath  the sub JSON path for the specific formula or variable name
/// @param srcLocId the JSON with the source location information, it is released after adding it to the main JSON from jsonid
/// @param formula  formula string
/// @param line     line in the SF notebook where the formula is
/// @param offset   character offset of the formula in the line in the SF notebook
static Function SF_AddSourceInfoToJSON(variable jsonId, string jsonPath, string subPath, variable srcLocId, string formula, variable line, variable offset)

	string prefix

	prefix = jsonPath + "/source_location" + subPath
	JSON_AddTreeObject(jsonId, prefix)
	subPath = prefix + "/source"
	JSON_AddString(jsonID, subPath, formula)
	subPath = prefix + "/line"
	JSON_AddVariable(jsonID, subPath, line)
	subPath = prefix + "/start_offset"
	JSON_AddVariable(jsonID, subPath, offset)
	subPath = prefix + "/source_map"
	JSON_AddJSON(jsonID, subPath, srcLocId)
	JSON_Release(srcLocId)
End

Function SF_Update(string graph)

	string bsPanel = BSP_GetPanel(graph)

	if(!SF_IsActive(bsPanel))
		return NaN
	endif

	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")
End

/// @brief checks if SweepFormula (SF) is active.
Function SF_IsActive(string win)

	return BSP_IsActive(win, MIES_BSP_SF)
End

/// @brief Return the sweep formula code in raw and with all necessary preprocesssing
Function [string raw, string preProc] SF_GetCode(string win)

	string formula_nb, code

	formula_nb = BSP_GetSFFormula(win)
	code       = GetNotebookText(formula_nb, mode = 2)

	return [code, SF_PreprocessInput(code)]
End

Function SF_button_sweepFormula_display(STRUCT WMButtonAction &ba) : ButtonControl

	string mainPanel, rawCode, bsPanel, preProcCode, codeWithoutVariables
	variable lineVars

	switch(ba.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(ba.win)
			bsPanel   = BSP_GetPanel(mainPanel)

			[rawCode, preProcCode] = SF_GetCode(mainPanel)
			if(IsEmpty(preProcCode))
				break
			endif

			if(!BSP_HasBoundDevice(bsPanel))
				DebugPrint("Databrowser has unbound device")
				break
			endif

			SF_KillWorkingDF(mainPanel)
			SF_ClearSFOutputState()
			SF_DisplayOutputStateInGUI(bsPanel)

			// catch Abort from SFH_ASSERT
			try
				codeWithoutVariables = SFE_ExecuteVariableAssignments(mainPanel, preProcCode)
				if(IsEmpty(codeWithoutVariables))
					break
				endif
				lineVars = SF_GetLineNumberOfRemainingCode(preProcCode, codeWithoutVariables)
				SF_FormulaPlotter(mainPanel, codeWithoutVariables, lineVars = lineVars)

				DFREF dfr      = SF_GetBrowserDF(mainPanel)
				SVAR  lastCode = $GetLastSweepFormulaCode(dfr)
				lastCode = codeWithoutVariables

				[WAVE/T keys, WAVE/T values] = SFH_CreateResultsWaveWithCode(mainPanel, rawCode)

				ED_AddEntriesToResults(values, keys, UNKNOWN_MODE)
			catch
#ifdef DEBUGGING_ENABLED
				SFP_SaveParserStateLog()
#endif // DEBUGGING_ENABLED
				SF_MarkErrorLocationInNotebook(mainPanel)
			endtry
			SF_DisplayOutputStateInGUI(bsPanel)

			break
		default:
			break
	endswitch

	return 0
End

Function SF_TabProc_Formula(STRUCT WMTabControlAction &tca) : TabControl

	string mainPanel, bsPanel, json_nb, text, helpNotebook
	variable jsonID

	switch(tca.eventCode)
		case 2: // mouse up
			mainPanel = GetMainWindow(tca.win)
			bsPanel   = BSP_GetPanel(mainPanel)
			if(tca.tab == 1)
				PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_check")
			elseif(tca.tab == 2)
				helpNotebook = BSP_GetSFHELP(mainPanel)
				BSP_UpdateHelpNotebook(helpNotebook)
			endif

			if(!BSP_HasBoundDevice(bsPanel))
				DebugPrint("Databrowser has unbound device")
				break
			endif

			break
		default:
			break
	endswitch

	return 0
End

Function SF_SetSweepXAxisTickLabels(WAVE output, WAVE/Z selectDataPlainOrArray)

	variable numSelected

	if(!WaveExists(selectDataPlainOrArray))
		return NaN
	endif

	if(IsWaveRefWave(selectDataPlainOrArray))
		if(DimSize(selectDataPlainOrArray, ROWS) > 1)
			return NaN
		endif

		WAVE/WAVE selectDataArray = selectDataPlainOrArray

		WAVE/WAVE singleSelectData = selectDataArray[0]
		WAVE/Z    selectData       = singleSelectData[%SELECTION]

		if(!WaveExists(selectData))
			return NaN
		endif
	else
		WAVE selectData = selectDataPlainOrArray
	endif

	numSelected = DimSize(selectData, ROWS)

	Make/FREE/N=(numSelected) xTickPositions = selectData[p][%SWEEP]
	Make/T/FREE/N=(numSelected) xTickLabels = num2str(selectData[p][%SWEEP])

	JWN_SetWaveInWaveNote(output, SF_META_XTICKPOSITIONS, xTickPositions)
	JWN_SetWaveInWaveNote(output, SF_META_XTICKLABELS, xTickLabels)
End

static Function/WAVE SF_SplitCodeToGraphs(string code)

	string group0, group1
	variable graphCount, size, line

	WAVE/T graphCode = GetYvsXFormulas()

	do
		SplitString/E=SF_SWEEPFORMULA_GRAPHS_REGEXP code, group0, group1
		if(!IsEmpty(group0))
			EnsureLargeEnoughWave(graphCode, dimension = ROWS, indexShouldExist = graphCount + 1)
			graphCode[graphCount][%GRAPHCODE] = group0

			if(graphCount == 0)
				graphCode[0][%LINE] = num2istr(0)
			endif
			line                            += SF_GetLineNumberOfRemainingCode(code, group1)
			graphCode[graphCount + 1][%LINE] = num2istr(line)

			graphCount += 1
			code        = group1
		endif
	while(!IsEmpty(group1))
	Redimension/N=(graphCount, -1) graphCode

	return graphCode
End

static Function [string xFormula, string yFormula, variable offset] SF_SplitGraphsToFormula(string graphCode)

	variable numFormulae

	offset = NaN

	SplitString/E=SF_SWEEPFORMULA_REGEXP graphCode, yFormula, xFormula
	numFormulae = V_Flag

	if(numFormulae != 1 && numFormulae != 2)
		return ["", "", NaN]
	endif

	xFormula = SelectString(numFormulae == 2, "", xFormula)
	if(!IsEmpty(xFormula))
		offset = strsearch(graphCode, xFormula, Inf, 1)
	endif

	return [xFormula, yFormula, offset]
End

static Function/S SF_GetFormulaWinNameTemplate(string mainWindow)

	return BSP_GetFormulaGraph(mainWindow) + "_"
End

Function SF_button_sweepFormula_tofront(STRUCT WMButtonAction &ba) : ButtonControl

	string winNameTemplate, wList, wName
	variable numWins, i

	switch(ba.eventCode)
		case 2: // mouse up
			// click code here
			winNameTemplate = SF_GetFormulaWinNameTemplate(GetMainWindow(ba.win))
			wList           = WinList(winNameTemplate + "*", ";", "WIN:65")
			numWins         = ItemsInList(wList)
			for(i = 0; i < numWins; i += 1)
				wName = StringFromList(i, wList)
				DoWindow/F $wName
				DoIgorMenu "Control", "Retrieve Window"
			endfor

			break
		default:
			break
	endswitch

	return 0
End

Function/WAVE SF_GetAllOldCodeForGUI(string win) // parameter required for popup menu ext

	WAVE/Z/T entries = SF_GetAllOldCode()

	if(!WaveExists(entries))
		return $""
	endif

	entries[] = num2str(p) + ": " + ElideText(ReplaceString("\n", entries[p], " "), 60)

	WAVE/Z/T splittedMenu = PEXT_SplitToSubMenus(entries, method = PEXT_SUBSPLIT_ALPHA)

	PEXT_GenerateSubMenuNames(splittedMenu)

	return splittedMenu
End

static Function/WAVE SF_GetAllOldCode()

	WAVE/T textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)

	return GetUniqueSettings(textualResultsValues, "Sweep Formula code")
End

Function SF_PopMenuProc_OldCode(STRUCT WMPopupAction &pa) : PopupMenuControl

	string sweepFormulaNB, bsPanel, code
	variable index

	switch(pa.eventCode)
		case 2: // mouse up
			if(!cmpstr(pa.popStr, NONE))
				break
			endif

			bsPanel        = BSP_GetPanel(pa.win)
			sweepFormulaNB = BSP_GetSFFormula(bsPanel)
			WAVE/Z/T entries = SF_GetAllOldCode()
			// -2 as we have NONE
			index = str2num(pa.popStr)
			code  = entries[index]

			// translate back from \n to \r
			code = ReplaceString("\n", code, "\r")

			ReplaceNotebookText(sweepFormulaNB, code)
			PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display", val = CHECKBOX_SELECTED)
			break
		default:
			break
	endswitch

	return 0
End

// Returns a RGB color for a severity values
static Function [STRUCT RGBColor s] SF_GetErrorColorsFromSeverity(variable severity)

	WAVE sfColors = GetSFErrorColorWave()
	switch(severity)
		case SF_MSG_OK:
			s.red   = sfColors[%OK][%R]
			s.green = sfColors[%OK][%G]
			s.blue  = sfColors[%OK][%B]
			break
		case SF_MSG_WARN:
			s.red   = sfColors[%WARN][%R]
			s.green = sfColors[%WARN][%G]
			s.blue  = sfColors[%WARN][%B]
			break
		case SF_MSG_ERROR:
			s.red   = sfColors[%ERROR][%R]
			s.green = sfColors[%ERROR][%G]
			s.blue  = sfColors[%ERROR][%B]
			break
		default:
			FATAL_ERROR("Unknown Severity")
	endswitch
End

// Use this function from within SF to set an error state
Function SF_SetOutputState(string error, variable severity)

	ASSERT(!IsNull(error), "Error can not be a null string")
	ASSERT(severity == SF_MSG_ERROR || severity == SF_MSG_OK || severity == SF_MSG_WARN, "Unknown severity for SF error")

	NVAR sfSeverity = $GetSweepFormulaOutputSeverity()
	sfSeverity = severity

	SVAR sfError = $GetSweepFormulaOutputMessage()
	sfError = error

#ifdef DEBUGGING_ENABLED
	SFP_LogParserErrorState(error)
#endif // DEBUGGING_ENABLED
End

// Sets a formula in the SweepFormula notebook of the given data/sweepbrowser
Function SF_SetFormula(string databrowser, string formula)

	string nb = BSP_GetSFFormula(databrowser)
	ReplaceNotebookText(nb, formula)
End

static Function SF_ConvertAllReturnDataToPermanent(WAVE/WAVE output, string win, string opShort)

	string   wName
	variable i

	for(data : output)
		if(WaveExists(data) && IsFreeWave(data))
			DFREF dfrWork = SFH_GetWorkingDF(win)
			wName = UniqueWaveName(dfrWork, opShort + "_return_arg" + num2istr(i) + "_")
			MoveWave data, dfrWork:$wName
		endif
		i += 1
	endfor
End

/// @brief Executes the complete arguments of the JSON and parses the resulting data to a waveRef type
///        @deprecated: executing all arguments e.g. as array in the executor poses issues as soon as data types get mixed.
///                    e.g. operation(0, A, [1, 2, 3]) fails as [0, A, [1, 2, 3]] can not be converted to an Igor wave.
///                    Thus, it is strongly recommended to parse each argument separately.
Function/WAVE SF_GetArgumentTop(STRUCT SF_ExecutionData &exd, string opShort)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(exd)
	if(numArgs > 0)
		WAVE wv = SFE_FormulaExecutor(exd)
	else
		Make/FREE/N=0 data
		WAVE wv = SFH_GetOutputForExecutorSingle(data, exd.graph, opShort + "_zeroSizedInput")
	endif

	WAVE/WAVE input = SF_ResolveDataset(wv)

	return input
End

static Function/WAVE SF_CreatePlotFormulaDataWave()

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE) tracesInGraph
	Make/FREE/WAVE/N=(MINIMUM_WAVE_SIZE, 2) dataInGraph
	SetDimLabel COLS, 0, WAVEX, dataInGraph
	SetDimLabel COLS, 1, WAVEY, dataInGraph
	Make/FREE/WAVE/N=2 graphData
	graphData[0] = tracesInGraph
	graphData[1] = dataInGraph

	return graphData
End

static Function SF_CollectTraceData(variable &index, WAVE/WAVE graphData, string traceName, WAVE/Z wx, WAVE wy)

	WAVE/T    tracesInGraph = graphData[0]
	WAVE/WAVE dataInGraph   = graphData[1]
	EnsureLargeEnoughWave(tracesInGraph, indexShouldExist = index)
	EnsureLargeEnoughWave(dataInGraph, indexShouldExist = index)
	tracesInGraph[index]       = traceName
	dataInGraph[index][%WAVEX] = wx
	dataInGraph[index][%WAVEY] = wy
	index                     += 1
End

static Function [string varName, string formula] SF_SplitVariableAssignment(string line)

	string regex = "^(?i)\\s*(" + SF_VARNAME_REGEXP + ")\\s*=(.+)$"

	SplitString/E=regex line, varName, formula
	if(V_flag != 2)
		return ["", ""]
	endif

	return [varName, formula]
End

Function/DF SF_GetBrowserDF(string graph)

	return BSP_GetFolder(graph, MIES_BSP_PANEL_FOLDER)
End

/// @brief Executes the part of the argument part of the JSON and parses the resulting data to a waveRef type
Function/WAVE SF_ResolveDatasetFromJSON(STRUCT SF_ExecutionData &exd, variable argNum, [variable copy])

	STRUCT SF_ExecutionData exdarg

	copy = ParamIsDefault(copy) ? 0 : !!copy

	exdarg.jsonId   = exd.jsonId
	exdarg.graph    = exd.graph
	exdarg.jsonPath = exd.jsonPath + "/" + num2istr(argNum)
	WAVE wv = SFE_FormulaExecutor(exdarg)

	WAVE dataset = SF_ResolveDataset(wv)

	return SFH_CopyDataIfRequired(copy, dataset, dataset)
End

Function/WAVE SF_ResolveDataset(WAVE input)

	ASSERT(IsTextWave(input) && DimSize(input, ROWS) == 1 && DimSize(input, COLS) == 0, "Unknown SF argument input format")

	WAVE/Z resolve = SFH_AttemptDatasetResolve(WaveText(input, row = 0))
	ASSERT(WaveExists(resolve), "Could not resolve dataset from wave element")

	return resolve
End

Function/S SF_GetDefaultFormula()

	return "trange = [0, inf]\r"                                            + \
	       "sel = select(selrange($trange),selchannels(AD), selsweeps())\r" + \
	       "dat = data($sel)\r"                                             + \
	       "\r"                                                             + \
	       "$dat"
End

/// @brief This function extends formulaResults if possible. For each result from a Y formula it is attempted to move datasets from inside an array outside in the form
///        [dataset(1, 2), dataset(3, 4)] -> dataset([1, 3], [3, 4])
///        because the plotter can iterate over datasets only at the outermost occurrence.
///        As result the inside elements may be plottable after this transformation.
///        algorithm details:
///        Each Y formula result is 'repackaged' in an array and attempted to be transformed
///        Case 1: On a failed transformation the initial array is returned.
///        Case 2: On a successful transformation a dataset with one or more elements is returned
///        Regarding the plotter the array of case 1 is treated as a single dataset.
///        All the results from case 1 and case 2 are gathered in a waveref wave collectY.
///        The X formula results are associated multiple times for case 2 if multiple datasets were returned and are
///        gathered in a waveref wave collectX that grows identical to collectY.
///        The formulaResults wave gets modified to store the new transformed results.
static Function SF_FormulaPlotterExtendResultsIfCompatible(WAVE/WAVE formulaResults)

	variable i, numResults

	numResults = DimSize(formulaResults, ROWS)
	if(!numResults)
		return NaN
	endif

	WAVE/ZZ/WAVE collectX, collectY
	for(i = 0; i < numResults; i += 1)

		WAVE/Z wvResultX = formulaResults[i][%FORMULAX]
		WAVE/Z wvResultY = formulaResults[i][%FORMULAY]
		if(!WaveExists(wvResultY))
			continue
		endif
		Make/FREE/WAVE array = {wvResultY}
		WAVE/WAVE extended = SFH_MoveDatasetHigherIfCompatible(array)
		if(!WaveExists(collectY))
			WAVE/WAVE collectY = extended
			Duplicate/FREE/WAVE extended, collectX
			collectX[] = wvResultX
		else
			Concatenate/FREE/NP/WAVE {extended}, collectY
			extended[] = wvResultX
			Concatenate/FREE/NP/WAVE {extended}, collectX
		endif
	endfor

	if(!WaveExists(collectY))
		return NaN
	endif
	Redimension/N=(DimSize(collectY, ROWS), -1, -1, -1) formulaResults
	formulaResults[][%FORMULAX] = collectX[p]
	formulaResults[][%FORMULAY] = collectY[p]
End

Function TraceValueDisplayHook(STRUCT WMTooltipHookStruct &s)

	string name, msg, allTraces, trace, tooltip, match, options, win, valueStr, tagText
	variable numTraces, i

	// traceName is set only for graphs and only if the mouse hovered near a trace
	if(IsEmpty(s.traceName))
		return 0
	endif

	win = s.winName

	tooltip   = ""
	allTraces = TraceNameList(win, ";", 1 + 2)

	numTraces = ItemsInList(allTraces)
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, allTraces)

		sprintf options, "WINDOW:%s;ONLY:%s;DELTAX:24;DELTAY:24", win, trace
		match = TraceFromPixel(s.mouseLoc.h, s.mouseLoc.v, options)

		if(IsEmpty(match))
			continue
		endif

		WAVE wv = TraceNameToWaveRef(win, trace)

		name = JWN_GetStringFromWaveNote(wv, SF_META_LEGEND_LINE_PREFIX)

		if(IsEmpty(name))
			// not a labnotebook/analysis function parameter
			continue
		endif

		if(IsNumericWave(wv))
			tagText = JWN_GetStringFromWaveNote(wv, SF_META_TAG_TEXT)
			if(IsEmpty(tagText))
				valueStr = num2str(wv[s.row][s.column][s.layer][s.chunk])
			else
				valueStr = ReplaceString("\r", tagText, "\r" + ReplicateString(" ", strlen(name) + 2))
			endif
		elseif(IsTextWave(wv))
			WAVE/T wvText = wv
			valueStr = wvText[s.row][s.column][s.layer][s.chunk]
		endif

		sprintf msg, "%s: %s\r", name, valueStr
		tooltip += msg
	endfor

	if(!IsEmpty(tooltip))
		s.tooltip = "<pre>" + RemoveEnding(tooltip, "\r") + "</pre>"
		s.isHtml  = 1
		return 1
	endif

	return 0
End

/// @brief Utility function that is called in the process of calculating the error location in the SF notebook.
///        If the current error location points to a variable then the variable should be marked too.
///        Generally errors in variables can only happen in the execution phase.
///        This function checks if the last execution path pointed to a variable.
///        If it does it returns the variable name, an empty string otherwise.
static Function/S SF_IsExecutionErrorInVariable(string win)

	string exPath, varName
	variable sfStep, jsonId

	WAVE/T assertData = GetSFAssertData()
	sfStep = str2numSafe(assertData[%STEP])
	if(sfStep != SF_STEP_EXECUTOR)
		return ""
	endif

	exPath = ROStr(GetSweepFormulaJSONPathTracker())
	jsonId = str2num(assertData[%JSONID])
	if(JSON_GetType(jsonId, exPath) != JSON_STRING)
		return ""
	endif

	varName = JSON_GetString(jsonId, exPath)
	if(!SFE_IsStringVariable(varName))
		return ""
	endif

	return varName[1, Inf]
End

/// @brief calculate the error position within the sf notebook
///        In notebooks every paragraph ends with a CR. It is possible to navigate through paragraphs
///        and character offsets in these paragraphs.
///        As formula code can contain CR, these have to be accounted for in counting paragraphs.
///        Also the effective character offset in the NB paragraph needs to be calculated.
static Function [variable paragraph, variable charPosition] SF_CalculateErrorLocationInNotebook(string win)

	string sfWin, text
	variable line, i, lineNr, offset, lineOffset, numCR, formOffset, inFormOffset

	sfWin = BSP_GetSFFormula(win)
	text  = GetNotebookText(sfWin, mode = 2)
	text  = SF_PreprocessInput(text)
	WAVE/T wText = ListToTextWave(text, SF_CHAR_CR)

	WAVE/T info = GetSFAssertData()
	line = str2numSafe(info[%LINE])

	// find line in text and look how many CR are between 0 and offset
	for(i = 0; i < line; i += 1)
		lineOffset += strlen(wText[i]) + strlen(SF_CHAR_CR)
	endfor
	text = text[lineOffset, Inf]

	// handle CR in left of "vs" formula
	offset = str2numSafe(info[%OFFSET])
	if(offset > 0)
		formOffset = offset
		for(i = 0; i < offset; i += 1)
			if(!CmpStr(text[i], SF_CHAR_CR))
				numCR     += 1
				formOffset = offset - i - 1
			endif
		endfor
	endif

	// handle CR right of "vs" formula
	text         = text[offset, Inf]
	offset       = str2numSafe(info[%INFORMULAOFFSET])
	inFormOffset = offset
	for(i = 0; i < offset; i += 1)
		if(!CmpStr(text[i], SF_CHAR_CR))
			numCR       += 1
			formOffset   = 0
			inFormOffset = offset - i - 1
		endif
	endfor

	lineNr        = line + numCR
	inFormOffset += formOffset

	return [lineNr, inFormOffset]
End

/// @brief Mark the error location in red in the SF notebook
static Function SF_MarkErrorLocationInNotebook(string win)

	variable paragraph, offset, col
	string sfWin, varName, code, preProcCode

	[paragraph, offset] = SF_CalculateErrorLocationInNotebook(win)

	sfWin = BSP_GetSFFormula(win)
	Notebook $sfWin, selection={(paragraph, offset), (paragraph, offset + 1)}, textRGB=(65535, 0, 0)

	varName = SF_IsExecutionErrorInVariable(win)
	WAVE/T assertData = GetSFAssertData()
	JSON_Release(str2num(assertData[%JSONID]), ignoreErr = 1)
	if(IsEmpty(varName))
		return NaN
	endif

	[code, preProcCode]           = SF_GetCode(win)
	[WAVE/T varAssignments, code] = SF_GetVariableAssignments(preProcCode)
	col                           = FindDimLabel(varAssignments, COLS, "VARNAME")
	FindValue/TEXT=(varName)/TXOP=4/RMD=[][col] varAssignments
	ASSERT(V_row >= 0, "Variable not found")

	paragraph = str2num(varAssignments[V_row][%LINE])
	offset    = str2num(varAssignments[V_row][%OFFSET])
	Notebook $sfWin, selection={(paragraph, 0), (paragraph, offset - 1)}, textRGB=(65535, 0, 0)
End

/// @brief This function returns a list of JSON properties that are intended to be shown
///        in the tooltip for table display, when present
///        This allows to separate meta data for the user from internal meta information like plotting hints
static Function/WAVE SF_GetTableTooltipProperties()

	Make/FREE/T wv = {SF_META_FORMULA, SF_META_EXPERIMENT, SF_META_DEVICE, SF_META_SWEEPNO, SF_META_CHANNELTYPE, SF_META_CHANNELNUMBER}

	return wv
End

static Function/S SF_AppendTableTooltip(string s, string key, string value)

	return s + "<b>" + key + ": </b>" + value + "<br>"
End

Function SF_TableTooltipHook(STRUCT WMTooltipHookStruct &s)

	variable hookResult, val
	string str, prop, key

	if(WaveExists(s.yWave))
		hookResult = 1
		s.tooltip  = ""

		WAVE/T props = SF_GetTableTooltipProperties()
		for(prop : props)
			key = RemovePrefix(prop)
			str = JWN_GetStringFromWaveNote(s.yWave, prop)
			if(!IsEmpty(str))
				str       = ReplaceString("\r", str, "")
				s.tooltip = SF_AppendTableTooltip(s.tooltip, key, str)
				continue
			endif
			val = JWN_GetNumberFromWaveNote(s.yWave, prop)
			if(IsNaN(val))
				continue
			endif
			if(!CmpStr(prop, SF_META_CHANNELTYPE))
				s.tooltip = SF_AppendTableTooltip(s.tooltip, key, ChannelTypeToString(val))
				continue
			endif
			s.tooltip = SF_AppendTableTooltip(s.tooltip, key, num2str(val))
		endfor
		s.tooltip     = RemoveEnding(s.tooltip, "<br>")
		s.isHtml      = 1
		s.duration_ms = 600000
	endif

	return hookResult
End

Function SF_TableWindowHook(STRUCT WMWinHookStruct &s)

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_MOUSEDOWN:
			if(s.eventMod & WINDOW_HOOK_EMOD_RIGHTCLICK)
				SVAR win = $GetSweepFormulaLastRightClickedDisplayWindow()
				win = s.winName
			endif
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Adds an expression to a formula string with the proper termination character
Function/S SF_AddExpressionToFormula(string formula, string expr)

	return formula + expr + SF_CHAR_CR
End
