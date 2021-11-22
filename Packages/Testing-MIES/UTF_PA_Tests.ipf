#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PA_Tests

// The functions are enclosed in this define to be able to acquire data for tests in
// a non-test environment. So commenting AUTOMATED_TESTING in the experiment procedure
// switches off the testing environment and thus these tests must be removed from compilation as well.
// The module names for specific procedure files are only available in the testing environment and
// compilation would fail.
#ifdef AUTOMATED_TESTING

// Test: PAT_BasicStartUpCheck
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep
//- for each trace:
//  - trace exists with correct name from channel, region, pulse number
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range set fits to the data shown
//  - pulse data fits to expected data
//  - pulse wave note fits to setting of PA panel

// Test: PAT_BasicAverageCheck
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep + number of average traces
//- number of average traces equals expected number for given layout
//- average traces are shown as frontmost traces
//- for each average trace:
//  - trace exists with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range set fits to the data shown
//  - average data fits to expected data
//  - average wave note fits to average data (wavemax)

// Test: PAT_BasicDeconvCheck
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep + number of average traces + number of deconv traces
//- number of deconv traces equals expected number for given layout
//- deconv traces are shown as frontmost traces
//- for each deconv trace:
//  - trace exists with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range in X fits to the data shown
//  - deconv data fits to reference data

// Test: PAT_BasicDeconvOnlyCheck
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep + number of average traces + number of deconv traces
//- number of deconv traces equals expected number for given layout
//- deconv traces are shown as frontmost traces
//- for each deconv trace:
//  - trace exists with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range in X fits to the data shown
//  - deconv data fits to reference data

// Test: PAT_ZeroPulses
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep
//- for each trace:
//  - trace exists with correct name from channel, region, pulse number
//  - axes range set fits to the data shown
//  - pulse data is zeroed
//  - pulse wave note fits to setting of PA panel

// Test: PAT_TimeAlignment
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep
//- for each trace:
//  - trace exists with correct name from channel, region, pulse number
//  - check if timeAlignment is set in wave note of pulse
//  - check if time alignment values are correct in note of pulse
//  - check if time alignment values are set as DimOffset

// Test: PAT_MultipleGraphs
// checked:
//- PA plot window opens
//- number of traces in PA plot windows equals one
//- for each trace:
//  - trace exists with correct name from channel, region, pulse number
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range set fits to the data shown
//  - pulse data fits to expected data
//  - pulse wave note fits to setting of PA panel

// Test: PAT_DontShowIndividualPulses
// checked:
//- PA plot window opens
//After disabling "Show Individual Pulses"
//- number of traces in PA plot windows equals zero
//After enabling "Show Average"
//- number of traces in PA plot windows equals 4
//After enabling "Show Individual Pulses"
//- check if average traces are front most
//After disabling "Show Individual Pulses"
//After enabling "Show Deconvolution"
//- number of traces in PA plot windows equals 4 + 2
//After enabling "Show Individual Pulses"
//- check if deconvolution traces are front most

// Test: PAT_ExtendedDeconvCheckTau
// With the new PA it should not be necessary to enable average to get deconv traces
// checked:
//- PA plot window opens
//After changing tau parameter:
//  - number of traces in PA plot equals expected number for sweep + number of average traces + number of deconv traces
//  - number of deconv traces equals expected number for given layout
//  - deconv traces are shown as frontmost traces
//  - wave data is different from reference data with tau = 15

// Test: PAT_ExtendedDeconvCheckSmooth
// With the new PA it should not be necessary to enable average to get deconv traces
// checked:
//- PA plot window opens
//After changing smooth parameter:
//  - number of traces in PA plot equals expected number for sweep + number of average traces + number of deconv traces
//  - number of deconv traces equals expected number for given layout
//  - deconv traces are shown as frontmost traces
//  - wave data is different from reference data with smooth = 1

// Test: PAT_ExtendedDeconvCheckDisplay
// With the new PA it should not be necessary to enable average to get deconv traces
// checked:
//- PA plot window opens
//After changing Display parameter:
//  - number of traces in PA plot equals expected number for sweep + number of average traces + number of deconv traces
//  - number of deconv traces equals expected number for given layout
//  - deconv traces are shown as frontmost traces
//  - wave data is different from reference data with Display = 500

// Test: PAT_BasicOVSCheck
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep 0 + 3
//- for each trace of sweep 0 and 3:
//  - trace exists with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range set fits to the data shown
//  - pulse data fits to expected data
//  - pulse wave note fits to pulse data

// Test: PAT_BasicOVSAverageCheck
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep 0 + 3
//- for each average trace:
//  - trace exists with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range set fits to the data shown
//  - traces are at the front in each block
//  - average data fits to expected data from own avg calculation
//  - pulse wave note fits to pulse data

// Test: PAT_FailedPulseCheck1
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep 0 + 3
//- for each trace of sweep 0 and 3:
//  - trace exists with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range set fits to the data shown
//  - pulse data fits to expected data
//  - pulse wave note fits to pulse data

// Test: PAT_FailedPulseCheck2
// checked:
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep 0 + 3
//- for each trace of sweep 0 and 3:
//  - trace exists with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range set fits to the data shown
//  - pulse data fits to expected data
//  - pulse wave note fits to pulse data

// Test: PAT_FailedPulseCheck3
// checked with partly hidden traces:
/// TRACES
/// 0 1 1
/// 0 1 1
/// 0 1 1
/// AVG
/// - 1 1
/// - 1 1
/// - 1 1
/// DECONV
/// - 1 1
/// - - 1
/// - 1 -
//- PA plot window opens
//- number of traces in PA plot equals expected number for sweep 0 + 5
//- number of average traces in PA plot equals expected number, considering hidden traces
//- number of deconv traces in PA plot equals expected number, considering hidden traces
//- for each average trace:
//  - trace exists or not with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - wave note is as expected for average trace
//- for each deconvolution trace:
//  - trace exists or not with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - trace is frontmost

// Test: PAT_FailedPulseCheck4
// checked with partly hidden traces, no individual pulses, deconv only:
// First setup:
/// TRACES
/// 0 1 1
/// 0 1 1
/// 0 1 1
/// AVG
/// - 1 1
/// - 1 1
/// - 1 1
/// DECONV
/// - 1 1
/// - - 1
/// - 1 -
/// then disable individual traces and average, which leaves deconvolution traces only
//- PA plot window opens
//- number of traces in PA plot equals expected number for deconv = 4 (considering failed pulse traces)
//- for each deconvolution trace:
//  - trace exists or not with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - trace is frontmost

// Test: PAT_MultiSweep1
// First setup with sweep 0 + 5:
/// numTRACES
/// R-5-1-3
/// 0|1 1 1
/// 1|1 2 2
/// 3|1 2 2
/// then disable individual traces and average, which leaves deconvolution traces only
//- PA plot window opens
//- number of traces in PA plot equals expected number for deconv = 4 (considering failed pulse traces)
//- for each deconvolution trace:
//  - trace exists or not with correct name from channel, region
//  - axes for trace have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - trace is frontmost

// Test: PAT_MultiSweep2
// This test runs through several states until it reaches the same state as PAT_BasicStartUpCheck
// The follow up tests are the same
// State changes:
// - OVS is enabled -> 2x2 plot with sweep 0
// - sweep 0 is disabled -> panel empty
// - sweep 5 is enabled -> 3x3 plot with sweep 5
// - sweep 0 is enabled -> 3x3 plot with sweep 0
// - sweep 5 is disabled -> 2x2 plot with sweep 0

// Test: PAT_MultiSweepAvg
// This test runs through several states until it checks average and deconvolution traces
// The follow up tests are the same
// State changes:
// - OVS is enabled -> 2x2 plot with sweep 0
// - Show Average -> 2x2 plot with average traces
// - Show Deconvolution -> 2x2 plot with average and deconvolution traces
// - sweep 3 is enabled -> 2x2 plot with average and deconvolution traces
// Tested:
//   - sum trace number is correct
//   for each block:
//     - trace number of average plots and deconvolution traces in block is correct
//     - axes name, units and layout position is correct

// Test: PAT_BasicImagePlot
// This test checks basic image plot properties
// Image plot opens and contains expected number of images
// For each image:
// - image has expected names of axes
// - image axes in x, y has expected units
// - image axes are positioned correctly in layout
// - range of y axis is as expected
// - pulse data part of image has correct data
// - image wave note entries are in line with image properties
//
// Checks if subwindow with graph exists
// Checks if in subwindow graph are size + 1 annotations

// Test: PAT_BasicImagePlotAverage
// This test checks basic image plot properties
// Image plot opens and contains expected number of images
// For each image:
// - average part of image has expected values

// Test: PAT_BasicImagePlotDeconvolution
// This test checks basic image plot properties
// Image plot opens and contains expected number of images
// For each image:
// - deconvolution part of image has expected values

// Test: PAT_ImagePlotMultiSweep0
// This test checks basic image plot properties
// Image plot opens and contains expected number of images
// For each image:
// - image has expected names of axes
// - image axes in x, y has expected units
// - image axes are positioned correctly in layout
// - range of x, y axis is as expected
// - pulse data parts of images has correct data
// - image wave note entries are in line with image properties

// Test: PAT_ImagePlotAverageExtended
// This test checks extended image plot properties, sweep 0 and 3 are on and the average validity is checked
// Image plot opens and contains expected number of images
// For each image:
// - average part of image has expected values

// Test: PAT_ImagePlotMultiSweep1
// This test checks image plot with multi sweep with layout change displayed
// Image plot opens and contains expected number of images
// For each image:
// - image has expected names of axes
// - image axes in x, y has expected units
// - image axes are positioned correctly in layout
// - pulse data parts of images have correct data
// NOTE: this fails already from the start (when sweep5 is selected) and the test verification is pending !

// Test: PAT_ImagePlotFailedPulses
// This test checks if failed pulses are marked/hidden correctly
// Image plot opens and contains expected number of images
// For each image:
// - image has expected names of axes
// - image axes in x, y has expected units
// - image axes are positioned correctly in layout
// - range of x, y axis is as expected
// - pulse from sweep 4 is marked as failed
// For each image:
// - pulse from sweep 4 is marked as hidden

// Test: PAT_ImagePlotMultipleGraphs
// checked:
//- Multiple PA plot windows opens
//- for each window:
//  - image exists with correct name from channel, region
//  - axes for image have the correct name from active channel, active region
//  - axes have the correct units
//  - axes are layouted at the correct position
//  - axes range set fits to the data shown
//  - pulse data fits to expected data
//  - pulse wave note fits to setting of PA panel


// Test: PAT_IncrementalSweepAdd
// With most analysis functions sweeps are added incremental in various orders.
// The sum number of traces plotted is checked as well as if any pulse was plotted twice,
// which would be an error. This might happen if the indexing into properties is wrong.

// Test: PAT_IncrementalSweepAddPartial
// First a sweep is shown that has 2 regions.
// Then a second sweep is added that has one region (same channel association as first sweep).
// Thus there are three sub plots that are not affected by the new sweep and where the new sweep does not
// contribute new data. The test checks if the incremental average is kept in the sub plots where no new data was contributed.
// (incremental average with partially no new data)

// Test: PAT_ImagePlotPartialFullFail
// This test creates an image plot that contains failed pulses. In some sub plots all pulses are failed.
// It is tested if the information in the interval where the failed pulses are marked is correct.
// There are four different sub images:
// - all pulses failed, where only failed pulses (Inf) and NaNs for avg, deconv is present
// - some pulses failed, where failed pulses (Inf) and finite for other pulses, avg, deconv is present
// 		- some pulses failed but diagonal position, where failed pulses (Inf) and finite for other pulses, avg and NaN for deconv is present
// - no pulse failed, where finite for other pulses, avg, deconv is present

// Test: PAT_ImagePlotIncrementalPartial
// Displays a second sweep on top of another one, where the second sweep fits inside the first without layout change.
// Thus, where the second sweep contributes data the images must show more lines that the other images.

// Test: PAT_HSRemoval1
// Sweeps 0 and 4 are displayed in OVS, then for Sweep 0 HS 1 is removed.
// It is checked if sweep 4 is displayed in all sub plots.
// It is checked that sweep 0 is not displayed in the sub plots related to HS1 of sweep 0.
// Currently the test is marked as expected failure until https://github.com/AllenInstitute/MIES/issues/729 is fixed.

// Test: PAT_ImagePlotSortOrder
// Sweep 7 and 8 are shown with OVS enabled in the image.
// Both sweeps have 5 pulses (where 4 are shown), where the
// with: pulse amplitude sweep 7 = 100
//       pulse amplitude sweep 8 = 50
// It is checked if in sweep sorting order the first four pulses in the image have ampl. 100
// and the last four pulses in the image have ampl. 50
// In PulseIndex sorting order it is checked if the amplitude alternates, starting with 100 from
// sweep 7.

// Test: PAT_ExtendedAverageCheck
// Sweep 0 and 1 are shown with OVS, average and time alignment is enabled
// It is checked if the expected numer of traces is shown
// For the average trace of the upper left sub plot it is checked if the
// data is properly NaNed on the left and right edge.
static Constant PA_TEST_FP_EPSILON = 1E-6

// use copy of mies folder and restore it each time
Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	variable err
	string miesPath

	ModifyBrowser close; err = GetRTError(1)

	AdditionalExperimentCleanup()

	miesPath = GetMiesPathAsString()
	DuplicateDataFolder/O=1 root:MIES_backup, $miesPath

	// monkey patch the labnotebook to claim it holds IC data instead of VC
	WAVE numericalValues = root:MIES:LabNoteBook:Dev1:numericalValues
	MultiThread numericalValues[][%$"Clamp Mode"][] = (numericalValues[p][%$"Clamp Mode"][r] == V_CLAMP_MODE ? I_CLAMP_MODE : numericalValues[p][%$"Clamp Mode"][r])
End

static Function [string bspName, string graph] PAT_StartDataBrowser_IGNORE()

	string win, panel

	win = DB_OpenDataBrowser()
	bspName = BSP_GetPanel(win)

	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_PA", val = 1)
	graph = win + "_PulseAverage_traces"
	CHECK(WindowExists(graph))

	return [bspName, graph]
End

static Function [string bspName, string imageWin] PAT_StartDataBrowserImage_IGNORE()

	string win, panel

	win = DB_OpenDataBrowser()
	bspName = BSP_GetPanel(win)

	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_PA", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showTraces", val = 0)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_ShowImage", val = 1)
	imageWin = win + "_PulseAverage_images"
	CHECK(WindowExists(imageWin))

	return [bspName, imageWin]
End

static Function/S PAT_GetPulseTraceSuffix(variable channel, variable region, variable pulse)

	return "AD" + num2str(channel) + "_R" + num2str(region) + "_P" + num2str(pulse)
End

static Function/S PAT_GetImageSuffix(variable channel, variable region)

	return "AD" + num2str(channel) + "_R" + num2str(region)
End

static Function/S PAT_GetAvgDeconvTraceSuffix(variable channel, variable region)

	return "AD" + num2str(channel) + "_HS" + num2str(region)
End

static Function/S PAT_FindTraceNames(string traceList, variable channel, variable region, variable pulse)

	variable traceNum, i
	string traceName
	string traceNames = ""

	traceNum = ItemsInList(traceList)
	for(i = 0; i < traceNum; i += 1)
		traceName = StringFromList(i, traceList)
		if(StringEndsWith(traceName, PAT_GetPulseTraceSuffix(channel, region, pulse)))
			traceNames = AddListItem(traceName, traceNames, ";", Inf)
		endif
	endfor

	REQUIRE_PROPER_STR(traceNames)

	if(ItemsInList(traceNames) == 1)
		traceNames = StringFromList(0, traceNames)
	endif

	return traceNames
End

static Function/S PAT_FindImageNames(string imageList, variable channel, variable region)

	variable imageNum, i
	string imageName
	string imageNames = ""

	imageNum = ItemsInList(imageList)
	for(i = 0; i < imageNum; i += 1)
		imageName = StringFromList(i, imageList)
		if(StringEndsWith(imageName, PAT_GetImageSuffix(channel, region)))
			imageNames = AddListItem(imageName, imageNames, ";", Inf)
		endif
	endfor

	REQUIRE(!IsEmpty(imageNames))

	if(ItemsInList(imageNames) == 1)
		imageNames = StringFromList(0, imageNames)
	endif

	return imageNames
End

static Function/S PAT_FindTraceNameAvgDeconv(string traceList, variable channel, variable region, [variable checkForNoTrace])

	variable traceNum, i
	string traceName

	checkForNoTrace = ParamIsDefault(checkForNoTrace) ? 0 : checkForNoTrace

	PASS()

	traceNum = ItemsInList(traceList)
	for(i = 0; i < traceNum; i += 1)
		traceName = StringFromList(i, traceList)
		if(StringEndsWith(traceName, PAT_GetAvgDeconvTraceSuffix(channel, region)))
			if(checkForNoTrace)
				FAIL()
			endif

			return traceName
		endif
	endfor

	if(!checkForNoTrace)
		FAIL()
	endif
End

static Function PAT_VerifyImageAxes(string graph, string traceName, variable achan, variable aregion, STRUCT PA_Test &patest, [variable multiGraphMode])

	string tInfo, xaxis, yaxis, ref_xaxis, ref_yaxis, aInfo
	string xunits, yunits, ref_xunits, ref_yunits
	variable from, to, ref_from, ref_to, layoutSize, xLayoutCoord, yLayoutCoord
	variable region, channel

	multiGraphMode = ParamIsDefault(multiGraphMode) ? 0 : !!multiGraphMode

	region = patest.regions[aregion - 1]
	channel = patest.channels[achan - 1]

	tInfo = ImageInfo(graph, traceName, 0)
	xaxis = StringByKey("XAXIS", tInfo)
	yaxis = StringByKey("YAXIS", tInfo)
	if(multiGraphMode)
		ref_xaxis = "bottom"
		ref_yaxis = "left"
	else
		ref_xaxis = "bottom_R" + num2str(region)
		ref_yaxis = "left_R" + num2str(region) + "_C" + num2str(channel)
	endif

	CHECK_EQUAL_STR(xaxis, ref_xaxis)
	CHECK_EQUAL_STR(yaxis, ref_yaxis)

	aInfo = AxisInfo(graph, xaxis)
	xunits = StringByKey("UNITS", aInfo)
	ref_xunits = patest.xUnit
	CHECK_EQUAL_STR(xunits, ref_xunits)

	aInfo = AxisInfo(graph, yaxis)
	yunits = StringByKey("UNITS", aInfo)
	ref_yunits = ""
	CHECK_EQUAL_STR(yunits, ref_yunits)

	layoutSize = multiGraphMode ? 1 : patest.layoutSize
	xLayoutCoord = multiGraphMode ? 0 : aregion - 1
	yLayoutCoord = multiGraphMode ? 0 : achan - 1

	ref_from = xLayoutCoord * 100 / sqrt(layoutSize)
	ref_to = (xLayoutCoord + 1) * 100 / sqrt(layoutSize)
	[from, to] = PAT_GetAxisLayout(graph, xaxis)
	CHECK_GE_VAR(from, ref_from)
	CHECK_LE_VAR(to, ref_to)

	ref_to = 100 - yLayoutCoord * 100 / sqrt(layoutSize)
	ref_from = 100 - (yLayoutCoord + 1) * 100 / sqrt(layoutSize)
	[from, to] = PAT_GetAxisLayout(graph, yaxis)
	CHECK_GE_VAR(from, ref_from)
	CHECK_LE_VAR(to, ref_to)
End

static Function PAT_VerifyTraceAxes(string graph, string traceName, variable achan, variable aregion, STRUCT PA_Test &patest, [variable multiGraphMode])

	string tInfo, xaxis, yaxis, ref_xaxis, ref_yaxis, aInfo
	string xunits, yunits, ref_xunits, ref_yunits
	variable from, to, ref_from, ref_to, layoutSize, xLayoutCoord, yLayoutCoord
	variable region, channel

	multiGraphMode = ParamIsDefault(multiGraphMode) ? 0 : !!multiGraphMode

	region = patest.regions[aregion - 1]
	channel = patest.channels[achan - 1]

	tInfo = TraceInfo(graph, traceName, 0)
	xaxis = StringByKey("XAXIS", tInfo)
	yaxis = StringByKey("YAXIS", tInfo)
	if(multiGraphMode)
		ref_xaxis = "bottom"
		ref_yaxis = "left"
	else
		ref_xaxis = "bottom_R" + num2str(region)
		ref_yaxis = "left_R" + num2str(region) + "_C" + num2str(channel)
	endif

	CHECK_EQUAL_STR(xaxis, ref_xaxis)
	CHECK_EQUAL_STR(yaxis, ref_yaxis)

	aInfo = AxisInfo(graph, xaxis)
	xunits = StringByKey("UNITS", aInfo)
	ref_xunits = patest.xUnit
	CHECK_EQUAL_STR(xunits, ref_xunits)

	aInfo = AxisInfo(graph, yaxis)
	yunits = StringByKey("UNITS", aInfo)
	ref_yunits = patest.yUnit
	CHECK_EQUAL_STR(yunits, ref_yunits)

	layoutSize = multiGraphMode ? 1 : patest.layoutSize
	xLayoutCoord = multiGraphMode ? 0 : aregion - 1
	yLayoutCoord = multiGraphMode ? 0 : achan - 1

	ref_from = xLayoutCoord * 100 / sqrt(layoutSize)
	ref_to = (xLayoutCoord + 1) * 100 / sqrt(layoutSize)
	[from, to] = PAT_GetAxisLayout(graph, xaxis)
	// TOOD rewrite using PAT_CHECKSmallOrClose or CHECK_SMALL_VAR/CHECK_CLOSE_VAR
	CHECK_GE_VAR(from, ref_from)
	CHECK_LE_VAR(to, ref_to)

	ref_to = 100 - yLayoutCoord * 100 / sqrt(layoutSize)
	ref_from = 100 - (yLayoutCoord + 1) * 100 / sqrt(layoutSize)
	[from, to] = PAT_GetAxisLayout(graph, yaxis)
	// TOOD rewrite using PAT_CHECKSmallOrClose or CHECK_SMALL_VAR/CHECK_CLOSE_VAR
	CHECK_GE_VAR(from, ref_from)
	CHECK_LE_VAR(to, ref_to)
End

static Function PAT_VerifyImageAxesRange(string imageWin, string imageName, STRUCT PA_Test &patest)

	string tInfo, xaxis, yaxis

	tInfo = ImageInfo(imageWin, imageName, 0)
	xaxis = StringByKey("XAXIS", tInfo)
	DoUpdate/W=$imageWin

	GetAxis/W=$imageWin/Q $xaxis
	PAT_CheckSmallOrClose(patest.xMin, V_min, patest.xTol)
	PAT_CheckSmallOrClose(patest.xMax, V_max, patest.xTol)
End

static Function PAT_CheckSmallOrClose(variable ref, variable val, variable tolerance)

	if(ref == 0)
		CHECK_SMALL_VAR(val, tol = tolerance)
	else
		CHECK_CLOSE_VAR(val, ref, tol = tolerance)
	endif
End

static Function PAT_VerifyTraceAxesRange(string graph, string traceName, STRUCT PA_Test &patest, [variable xOnly])

	string tInfo, xaxis, yaxis

	xOnly = ParamIsDefault(xOnly) ? 0 : !!xOnly

	tInfo = TraceInfo(graph, traceName, 0)
	xaxis = StringByKey("XAXIS", tInfo)
	yaxis = StringByKey("YAXIS", tInfo)
	DoUpdate/W=$graph

	GetAxis/W=$graph/Q $xaxis
	PAT_CheckSmallOrClose(patest.xMin, V_min, patest.xTol)
	PAT_CheckSmallOrClose(patest.xMax, V_max, patest.xTol)

	if(!xOnly)
		GetAxis/W=$graph/Q $yaxis
		PAT_CheckSmallOrClose(patest.yMin, V_min, patest.yTol)
		PAT_CheckSmallOrClose(patest.yMax, V_max, patest.yTol)
	endif
End

static Function/S PAT_GetTraceColor(string tInfo)

	string colorInfo

	sprintf colorInfo, "(%d,%d,%d)", GetNumFromModifyStr(tInfo, "rgb", "(", 0), GetNumFromModifyStr(tInfo, "rgb", "(", 1), GetNumFromModifyStr(tInfo, "rgb", "(", 2)

	return colorInfo
End

static Function PAT_CheckIfTraceIsRed(string graph, string traceName, variable isRed)

	string tInfo, colorInfo, refColorInfo

	isRed = !!isRed

	refColorInfo = "(65535,0,0)"
	tInfo = TraceInfo(graph, traceName, 0)
	colorInfo = PAT_GetTraceColor(tInfo)

	if(isRed)
		CHECK_EQUAL_STR(colorInfo, refColorInfo)
	else
		CHECK_NEQ_STR(colorInfo, refColorInfo)
	endif
End

static Function PAT_CheckIfTraceIsHidden(string graph, string traceName, variable isHidden)

	string tInfo
	variable hiddenInfo

	isHidden = !!isHidden

	tInfo = TraceInfo(graph, traceName, 0)
	hiddenInfo = GetNumFromModifyStr(tInfo, "hideTrace", "", 0)

	if(isHidden)
		CHECK(hiddenInfo)
	else
		CHECK(!hiddenInfo)
	endif
End

static Function [variable from, variable to] PAT_GetAxisLayout(string graph, string axisName)

	string layoutLine

	layoutLine = AxisInfo(graph, axisName)

	if(IsEmpty(layoutLine))
		return [0, 100]
	endif

	from = GetNumFromModifyStr(layoutLine, "axisEnab", "{", 0) * 100
	to   = GetNumFromModifyStr(layoutLine, "axisEnab", "{", 1) * 100

	return [from, to]
End

// This function assumes that the trace names in the list are unique per list
static Function PAT_CheckIfTracesAreFront(string allTraces, string frontTraces, variable channel, variable region, variable pulse)

	variable numTraces, numBlockTraces, numFrontTraces, i, pos
	string traceName
	string tracesInBlock = ""

	numTraces = ItemsInList(allTraces)
	for(i = 0; i < numTraces; i += 1)
		traceName = StringFromList(i, allTraces)
		if(StringEndsWith(traceName, PAT_GetPulseTraceSuffix(channel, region, pulse)))
			tracesInBlock = AddListItem(traceName, tracesInBlock, ";", Inf)
		endif
		if(StringEndsWith(traceName, PAT_GetAvgDeconvTraceSuffix(channel, region)))
			tracesInBlock = AddListItem(traceName, tracesInBlock, ";", Inf)
		endif
	endfor

	numFrontTraces = ItemsInList(frontTraces)
	numBlockTraces = ItemsInList(tracesInBlock)

	for(i = 0; i < numFrontTraces; i += 1)
		pos = WhichListItem(StringFromList(i, frontTraces), tracesInBlock)
		if(pos < numBlockTraces - numFrontTraces)
			return 0
		endif
	endfor

	return 1
End

static Function/S PAT_GetTraces(string graph, variable layoutSize)

	string traceList

	traceList = TraceNameList(graph, ";", 1)
	CHECK_EQUAL_VAR(ItemsInList(traceList), layoutSize)

	return traceList
End

static Function/S PAT_GetImages(string imageWin, variable layoutSize)

	string imageList

	imageList = ImageNameList(imageWin, ";")
	CHECK_EQUAL_VAR(ItemsInList(imageList), layoutSize)

	return imageList
End

static Function PAT_CheckFailedPulse(string win, WAVE pulse, variable isDiagonal, variable testExpect, variable numSpikes, [string spikePositions])

	STRUCT PulseAverageSettings s
	variable setting
	string str

	isDiagonal = !!isDiagonal
	testExpect = !!testExpect

	MIES_PA#PA_GatherSettings(win, s)

	if(isDiagonal)
		setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_PULSE_HAS_FAILED)
		CHECK_EQUAL_VAR(setting, testExpect)

		setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_PULSE_FOUND_SPIKES)
		CHECK_EQUAL_VAR(setting, numSpikes)

		str = PAT_GetStringFromPulseWaveNote(pulse, NOTE_KEY_PULSE_SPIKE_POSITIONS)

		if(!ParamIsDefault(spikePositions))
			CHECK_EQUAL_STR(str, spikePositions)
		endif

		if(numSpikes == 0)
			CHECK_EMPTY_STR(str)
		endif
	endif

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_FAILED_PULSE_LEVEL)
	CHECK_EQUAL_VAR(setting, s.failedPulsesLevel)
End

static Function/S PAT_GetStringFromPulseWaveNote(WAVE pulse, string key)

	string wName

	wName = GetWavesDataFolder(pulse, 2) + PULSEWAVE_NOTE_SUFFIX
	WAVE noteWave = $wName

	return GetStringFromWaveNote(noteWave, key)
End

static Function PAT_GetNumberFromPulseWaveNote(WAVE pulse, string key)

	string wName

	wName = GetWavesDataFolder(pulse, 2) + PULSEWAVE_NOTE_SUFFIX
	WAVE noteWave = $wName

	return GetNumberFromWaveNote(noteWave, key)
End

static Function PAT_CheckPulseWaveNote(string win, WAVE pulse)

	STRUCT PulseAverageSettings s
	variable setting, minimum, first, last

	MIES_PA#PA_GatherSettings(win, s)

	// TODO this should remove the inspected keys from the list of all keys found
	// and check in the end that we have inspected all keys
	// in that way the tests fail if we add new keys

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_SEARCH_FAILED_PULSE)
	CHECK_EQUAL_VAR(setting, s.searchFailedPulses)

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_NUMBER_OF_SPIKES)
	CHECK_EQUAL_VAR(setting, s.failedNumberOfSpikes)

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_TIMEALIGN)
	CHECK_EQUAL_VAR(setting, s.autoTimeAlignment)

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_ZEROED)
	CHECK_EQUAL_VAR(setting, s.zeroPulses)

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_WAVE_MINIMUM)
	CHECK_CLOSE_VAR(setting, WaveMin(pulse), tol = PA_TEST_FP_EPSILON)

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_WAVE_MAXIMUM)
	CHECK_CLOSE_VAR(setting, WaveMax(pulse), tol = PA_TEST_FP_EPSILON)

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_PULSE_LENGTH)
	CHECK_EQUAL_VAR(setting, DimSize(pulse, ROWS))

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_PULSE_START)
	CHECK(IsFinite(setting))
	CHECK_GE_VAR(setting, 0)

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_PULSE_END)
	CHECK(IsFinite(setting))
	CHECK_GT_VAR(setting, 0)

	first = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_PULSE_START)
	last  = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_PULSE_END)
	CHECK_LT_VAR(first, last)

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_CLAMP_MODE)
	CHECK(IsFinite(setting))
	CHECK((setting == V_CLAMP_MODE || setting == I_CLAMP_MODE || setting == I_EQUAL_ZERO_MODE))

	// no zeros inside the pulse
	// this requires that the DA and AD channels on the hardware are connected directly when acquiring this data
	// ditch the first and last 0.1 ms to avoid any decimation issues
	minimum = WaveMin(pulse, first + 0.1, last - 0.1)
	CHECK_GT_VAR(minimum, 0)
End

static Function PAT_CheckImageWaveNote(string win, WAVE iData, STRUCT PA_Test &patest)

	variable ySize, setting
	// This assumption is true for a small number of pulses shown
	variable specialEntryHeight = 1


	ySize = 2 * specialEntryHeight + patest.pulseCnt
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(iData, NOTE_INDEX), ySize)

	Duplicate/FREE/RMD=[][0, patest.pulseCnt - 1] iData, pulseData

	setting = GetNumberFromWaveNote(iData, NOTE_KEY_IMG_PMIN)
	CHECK_CLOSE_VAR(setting, WaveMin(pulseData), tol = PA_TEST_FP_EPSILON)

	setting = GetNumberFromWaveNote(iData, NOTE_KEY_IMG_PMAX)
	CHECK_CLOSE_VAR(setting, WaveMax(pulseData), tol = PA_TEST_FP_EPSILON)
End

static Function PAT_CheckAverageWaveNote(WAVE avg)

	variable setting

	setting = GetNumberFromWaveNote(avg, NOTE_KEY_WAVE_MAXIMUM)
	CHECK_CLOSE_VAR(setting, WaveMax(avg), tol = PA_TEST_FP_EPSILON)
End

static Function PAT_CheckPulseWaveNoteTA(WAVE pulse, WAVE pulseDiag, variable achan, variable aregion)

	variable setting, setting2
	string wName

	wName = GetWavesDataFolder(pulseDiag, 2) + WAVE_BACKUP_SUFFIX
	WAVE pulseBak = $wName

	setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_TIMEALIGN)
	CHECK_EQUAL_VAR(setting, 1)
	if(achan == aregion)
		WaveStats/Q/M=1 pulse
		CHECK_EQUAL_VAR(V_maxLoc, 0)

		setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_TIMEALIGN_FEATURE_POS)
		WaveStats/Q/M=1 pulseBak
		CHECK_CLOSE_VAR(setting, V_maxLoc, tol = PA_TEST_FP_EPSILON)

		setting2 = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_TIMEALIGN_TOTAL_OFFSET)
		CHECK_EQUAL_VAR(setting, -setting2)
		CHECK_CLOSE_VAR(setting2, DimOffset(pulse, ROWS), tol = PA_TEST_FP_EPSILON)
	else
		setting = PAT_GetNumberFromPulseWaveNote(pulse, NOTE_KEY_TIMEALIGN_TOTAL_OFFSET)
		WaveStats/Q/M=1 pulseBak
		CHECK_SMALL_VAR(V_maxLoc + setting, tol = PA_TEST_FP_EPSILON)
		CHECK_EQUAL_VAR(setting, DimOffset(pulse, ROWS))
	endif
End

static Structure PA_Test
	variable pulseCnt
	string xUnit
	string yUnit
	variable xMin
	variable xMax
	variable xTol
	variable yMin
	variable yMax
	variable yTol
	variable layoutSize
	variable xLayoutPos
	variable yLayoutPos
	variable dataLength
	WAVE refData
	WAVE channels
	WAVE regions
	variable eqWaveTol
EndStructure

static Function PA_InitSweep0(STRUCT PA_Test &patest)

	patest.xUnit = "ms"
	patest.yUnit = "pA"
	patest.xMin = 0
	patest.xMax = 1000
	patest.xTol = 0.005
	patest.yMin = 0
	patest.yMax = 100
	patest.yTol = 4
	patest.pulseCnt = 1
	patest.layoutSize = 4
	patest.eqWaveTol = 130000
	patest.dataLength = 250000

	Make/FREE/N=(250000) refPulseData
	refPulseData[2, 125002] = 100
	WAVE patest.refData = refPulseData

	Make/FREE channels = {1, 3}
	WAVE patest.channels = channels
	Make/FREE regions = {1, 3}
	WAVE patest.regions = regions
End

static Function PA_InitSweep3(STRUCT PA_Test &patest)

	patest.xUnit = "ms"
	patest.yUnit = "pA"
	patest.xMin = 0
	patest.xMax = 1000
	patest.xTol = 0.005
	patest.yMin = 0
	patest.yMax = 100
	patest.yTol = 4
	patest.pulseCnt = 1
	patest.layoutSize = 4
	patest.eqWaveTol = 130000
	patest.dataLength = 250000

	Make/FREE/N=(250000) refPulseData
	refPulseData[2, 62502] = 100
	WAVE patest.refData = refPulseData

	Make/FREE channels = {1, 3}
	WAVE patest.channels = channels
	Make/FREE regions = {1, 3}
	WAVE patest.regions = regions
End

static Function PA_InitSweep4(STRUCT PA_Test &patest)

	patest.xUnit = "ms"
	patest.yUnit = "pA"
	patest.xMin = 0
	patest.xMax = 1000
	patest.xTol = 0.005
	patest.yMin = 0
	patest.yMax = 100
	patest.yTol = 4
	patest.pulseCnt = 1
	patest.layoutSize = 4
	patest.eqWaveTol = 130000
	patest.dataLength = 250000

	Make/FREE/N=(250000) refPulseData
	refPulseData[2, 62502] = 50
	WAVE patest.refData = refPulseData

	Make/FREE channels = {1, 3}
	WAVE patest.channels = channels
	Make/FREE regions = {1, 3}
	WAVE patest.regions = regions
End

static Function PA_InitSweep5(STRUCT PA_Test &patest)
	// This is only set partially for the values that are constant for all pulses
	patest.xUnit = "ms"
	patest.yUnit = "pA"
	patest.xMin = 0
	patest.xMax = 1000
	patest.xTol = 0.005
	patest.pulseCnt = 1
	patest.layoutSize = 9

	patest.dataLength = 166667

	Make/FREE channels = {0, 1, 3}
	WAVE patest.channels = channels
	Make/FREE regions = {5, 1, 3}
	WAVE patest.regions = regions
End

static Function PA_InitSweep7(STRUCT PA_Test &patest)
	// This is only set partially for the values that are constant for all pulses
	patest.xUnit = "ms"
	patest.yUnit = "pA"
	patest.xMin = 0
	patest.xMax = 200
	patest.xTol = 0.005
	patest.pulseCnt = 3
	patest.layoutSize = 4

	patest.dataLength = 33333

	Make/FREE channels = {1, 3}
	WAVE patest.channels = channels
	Make/FREE regions = {1, 3}
	WAVE patest.regions = regions
End

static Function PA_InitSweep8(STRUCT PA_Test &patest)
	// This is only set partially for the values that are constant for all pulses
	patest.xUnit = "ms"
	patest.yUnit = "pA"
	patest.xMin = 0
	patest.xMax = 200
	patest.xTol = 0.005
	patest.pulseCnt = 3
	patest.layoutSize = 4

	patest.dataLength = 33333

	Make/FREE channels = {1, 3}
	WAVE patest.channels = channels
	Make/FREE regions = {1, 3}
	WAVE patest.regions = regions
End

/// Test Functions below

static Function PAT_BasicStartUpCheck()

	string bspName, graph
	STRUCT PA_Test patest

	string traceList, traceName
	variable traceNum, i, j, k, size

	PA_InitSweep0(patest)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()

	traceList = PAT_GetTraces(graph, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			for(k = 0; k < patest.pulseCnt; k += 1)
				traceName = PAT_FindTraceNames(traceList, patest.channels[i], patest.regions[j], k)
				// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
				PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
				PAT_VerifyTraceAxesRange(graph, traceName, patest)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				CHECK_EQUAL_WAVES(patest.refData, pData, mode = WAVE_DATA, tol = patest.eqWaveTol)
				PAT_CheckPulseWaveNote(bspName, pData)
			endfor
		endfor
	endfor
End

static Function PAT_BasicAverageCheck()

	string bspName, graph
	STRUCT PA_Test patest

	string traceListAll, traceList, traceName
	variable traceNum, i, j, size

	PA_InitSweep0(patest)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)

	traceListAll = PAT_GetTraces(graph, patest.layoutSize + patest.layoutSize)

	traceList = GrepList(traceListAll, PA_AVERAGE_WAVE_PREFIX)
	traceNum = ItemsInList(traceList)
	CHECK_EQUAL_VAR(traceNum, patest.layoutSize)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[i], patest.regions[j])
			CHECK(PAT_CheckIfTracesAreFront(traceListAll, traceName, patest.channels[i], patest.regions[j], 0))
			// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
			PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
			PAT_VerifyTraceAxesRange(graph, traceName, patest)
			WAVE pData = TraceNameToWaveRef(graph, traceName)
			CHECK_EQUAL_WAVES(patest.refData, pData, mode = WAVE_DATA, tol = patest.eqWaveTol)
			PAT_CheckAverageWaveNote(pData)
		endfor
	endfor
End

static Function PAT_ExtendedAverageCheck()

	string bspName, graph
	STRUCT PA_Test patest

	string traceListAll, traceList, traceName
	variable traceNum

	PA_InitSweep0(patest)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_timeAlign", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 1)

	Make/FREE/N=323286 refData = 1
	refData[73287, 249999] = 0

	traceListAll = PAT_GetTraces(graph, 3 * patest.layoutSize)

	traceList = GrepList(traceListAll, PA_AVERAGE_WAVE_PREFIX)
	traceNum = ItemsInList(traceList)
	CHECK_EQUAL_VAR(traceNum, patest.layoutSize)

	traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[0], patest.regions[0])
	WAVE pData = TraceNameToWaveRef(graph, traceName)
	Duplicate/FREE pData, compData
	compData[] = IsNaN(compData[p])

	CHECK_EQUAL_WAVES(refData, compData, mode = WAVE_DATA)
End

static Function PAT_BasicDeconvCheck()

	string bspName, graph
	STRUCT PA_Test patest

	string traceListAll, traceList, traceName
	variable traceNum, i, j, size

	PA_InitSweep0(patest)
	Make/FREE/WAVE/N=(2, 2) refData
	refData[0][1] = root:pa_test_deconv_ref2
	refData[1][0] = root:pa_test_deconv_ref1

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)

	traceListAll = PAT_GetTraces(graph, patest.layoutSize + patest.layoutSize / 2)

	traceList = GrepList(traceListAll, PA_DECONVOLUTION_WAVE_PREFIX)
	traceNum = ItemsInList(traceList)
	CHECK_EQUAL_VAR(traceNum, patest.layoutSize / 2)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			if(i == j)
				traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[i], patest.regions[j], checkForNoTrace = 1)
				continue
			endif
			traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[i], patest.regions[j])
			CHECK(PAT_CheckIfTracesAreFront(traceListAll, traceName, patest.channels[i], patest.regions[j], 0))
			// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
			PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
			PAT_VerifyTraceAxesRange(graph, traceName, patest, xOnly = 1)
			WAVE pData = TraceNameToWaveRef(graph, traceName)
			CHECK_EQUAL_WAVES(refData[i][j], pData, mode = WAVE_DATA)
		endfor
	endfor
End

static Function PAT_BasicDeconvOnlyCheck()

	string bspName, graph
	STRUCT PA_Test patest

	string traceListAll, traceList, traceName
	variable traceNum, i, j, size

	PA_InitSweep0(patest)
	Make/FREE/WAVE/N=(2, 2) refData
	refData[0][1] = root:pa_test_deconv_ref2
	refData[1][0] = root:pa_test_deconv_ref1

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 0)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_indPulses", val = 0)

	traceListAll = PAT_GetTraces(graph, patest.layoutSize / 2)

	traceList = GrepList(traceListAll, PA_DECONVOLUTION_WAVE_PREFIX)
	traceNum = ItemsInList(traceList)
	CHECK_EQUAL_VAR(traceNum, patest.layoutSize / 2)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			if(i == j)
				traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[i], patest.regions[j], checkForNoTrace = 1)
				continue
			endif
			traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[i], patest.regions[j])
			CHECK(PAT_CheckIfTracesAreFront(traceListAll, traceName, patest.channels[i], patest.regions[j], 0))
			// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
			PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
			PAT_VerifyTraceAxesRange(graph, traceName, patest, xOnly = 1)
			WAVE pData = TraceNameToWaveRef(graph, traceName)
			CHECK_EQUAL_WAVES(refData[i][j], pData, mode = WAVE_DATA)
		endfor
	endfor
End

static Function PAT_ZeroPulses()

	string bspName, graph
	STRUCT PA_Test patest

	string traceList, traceName
	variable traceNum, i, j, k, size

	PA_InitSweep0(patest)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_zero", val = 1)

	traceList = PAT_GetTraces(graph, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			for(k = 0; k < patest.pulseCnt; k += 1)
				traceName = PAT_FindTraceNames(traceList, patest.channels[i], patest.regions[j], k)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				patest.yMax = WaveMax(pData)
				patest.yMin = WaveMin(pData)
				PAT_VerifyTraceAxesRange(graph, traceName, patest)
				CHECK_SMALL_VAR(pData[0], tol = PA_TEST_FP_EPSILON)
				PAT_CheckPulseWaveNote(bspName, pData)
			endfor
		endfor
	endfor
End

static Function PAT_TimeAlignment()

	string bspName, graph
	STRUCT PA_Test patest

	string traceList, traceName, traceNameDiag
	variable traceNum, i, j, k, size

	PA_InitSweep0(patest)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_timeAlign", val = 1)

	traceList = PAT_GetTraces(graph, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceName = PAT_FindTraceNames(traceList, patest.channels[i], patest.regions[j], 0)
			traceNameDiag = PAT_FindTraceNames(traceList, patest.channels[j], patest.regions[j], 0)
			WAVE pData = TraceNameToWaveRef(graph, traceName)
			WAVE pDataDiag = TraceNameToWaveRef(graph, traceNameDiag)
			PAT_CheckPulseWaveNoteTA(pData, pDataDiag, i + 1, j + 1)
		endfor
	endfor
End

static Function PAT_MultipleGraphs()

	string bspName, graph
	STRUCT PA_Test patest

	string traceList, traceName, graphName
	variable traceNum, i, j, k, size

	PA_InitSweep0(patest)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_multGraphs", val = 1)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			// If this way of name generation is correct is under review
			graphName = graph + "_AD" + num2str(patest.channels[i]) + "_R" + num2str(j + 1)
			traceList = PAT_GetTraces(graphName, 1)
			for(k = 0; k < patest.pulseCnt; k += 1)
				traceName = PAT_FindTraceNames(traceList, patest.channels[i], patest.regions[j], k)
				// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
				PAT_VerifyTraceAxes(graphName, traceName, i + 1, j + 1, patest, multiGraphMode = 1)
				PAT_VerifyTraceAxesRange(graphName, traceName, patest)
				WAVE pData = TraceNameToWaveRef(graphName, traceName)
				CHECK_EQUAL_WAVES(patest.refData, pData, mode = WAVE_DATA, tol = patest.eqWaveTol)
				PAT_CheckPulseWaveNote(bspName, pData)
			endfor
		endfor
	endfor
End

static Function PAT_DontShowIndividualPulses()

	string bspName, graph
	STRUCT PA_Test patest

	string traceName, traceList, traceListAvg, traceListDeconv
	variable size, i, j

	PA_InitSweep0(patest)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_indPulses", val = 0)

	traceList = PAT_GetTraces(graph, 0)

	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	traceList = PAT_GetTraces(graph, patest.layoutSize)

	PGC_SetAndActivateControl(bspName, "check_pulseAver_indPulses", val = 1)
	traceListAvg = GrepList(traceList, PA_AVERAGE_WAVE_PREFIX)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceName = PAT_FindTraceNameAvgDeconv(traceListAvg, patest.channels[i], patest.regions[j])
			CHECK(PAT_CheckIfTracesAreFront(traceList, traceName, patest.channels[i], patest.regions[j], 0))
		endfor
	endfor
	PGC_SetAndActivateControl(bspName, "check_pulseAver_indPulses", val = 0)

	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)
	traceList = PAT_GetTraces(graph, patest.layoutSize + patest.layoutSize / 2)

	PGC_SetAndActivateControl(bspName, "check_pulseAver_indPulses", val = 1)
	traceListDeconv = GrepList(traceList, PA_DECONVOLUTION_WAVE_PREFIX)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			if(i == j)
				continue
			endif
			traceName = PAT_FindTraceNameAvgDeconv(traceListDeconv, patest.channels[i], patest.regions[j])
			CHECK(PAT_CheckIfTracesAreFront(traceList, traceName, patest.channels[i], patest.regions[j], 0))
		endfor
	endfor
End

static Function PAT_ExtendedDeconvCheckTau()

	string bspName, graph
	STRUCT PA_Test patest

	string traceListAll, traceList, traceName
	variable traceNum, i, j, size

	PA_InitSweep0(patest)
	Make/FREE/WAVE/N=(2, 2) refData
	refData[0][1] = root:pa_test_deconv_ref2
	refData[1][0] = root:pa_test_deconv_ref1

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_deconv_tau", val = 0)

	traceListAll = PAT_GetTraces(graph, patest.layoutSize + patest.layoutSize +  + patest.layoutSize / 2)

	traceList = GrepList(traceListAll, PA_DECONVOLUTION_WAVE_PREFIX)
	traceNum = ItemsInList(traceList)
	CHECK_EQUAL_VAR(traceNum, patest.layoutSize / 2)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			if(i == j)
				continue
			endif
			traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[i], patest.regions[j])
			CHECK(PAT_CheckIfTracesAreFront(traceListAll, traceName, patest.channels[i], patest.regions[j], 0))
			// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
			WAVE pData = TraceNameToWaveRef(graph, traceName)
			CHECK(!EqualWaves(refData[i][j], pData, 1, 10))
		endfor
	endfor
End

static Function PAT_ExtendedDeconvCheckSmooth()

	string bspName, graph
	STRUCT PA_Test patest

	string traceListAll, traceList, traceName
	variable traceNum, i, j, size

	PA_InitSweep0(patest)
	Make/FREE/WAVE/N=(2, 2) refData
	refData[0][1] = root:pa_test_deconv_ref2
	refData[1][0] = root:pa_test_deconv_ref1

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_deconv_smth", val = 1)

	traceListAll = PAT_GetTraces(graph, patest.layoutSize + patest.layoutSize +  + patest.layoutSize / 2)

	traceList = GrepList(traceListAll, PA_DECONVOLUTION_WAVE_PREFIX)
	traceNum = ItemsInList(traceList)
	CHECK_EQUAL_VAR(traceNum, patest.layoutSize / 2)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			if(i == j)
				continue
			endif
			traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[i], patest.regions[j])
			CHECK(PAT_CheckIfTracesAreFront(traceListAll, traceName, patest.channels[i], patest.regions[j], 0))
			// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
			WAVE pData = TraceNameToWaveRef(graph, traceName)
			CHECK(!EqualWaves(refData[i][j], pData, 1, 10))
		endfor
	endfor
End

static Function PAT_ExtendedDeconvCheckDisplay()

	string bspName, graph
	STRUCT PA_Test patest

	string traceListAll, traceList, traceName
	variable traceNum, i, j, size

	variable range = 400
	variable dataSize = 100000 // 400 ms * 250000 pts / 1000 ms

	PA_InitSweep0(patest)
	Make/FREE/WAVE/N=(2, 2) refData
	Duplicate/FREE root:pa_test_deconv_ref2, deconvDataRef2
	Redimension/N=(dataSize) deconvDataRef2
	refData[0][1] = deconvDataRef2
	Duplicate/FREE root:pa_test_deconv_ref1, deconvDataRef1
	Redimension/N=(dataSize) deconvDataRef1
	refData[1][0] = deconvDataRef1

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_deconv_range", val = range)

	traceListAll = PAT_GetTraces(graph, patest.layoutSize + patest.layoutSize +  + patest.layoutSize / 2)

	traceList = GrepList(traceListAll, PA_DECONVOLUTION_WAVE_PREFIX)
	traceNum = ItemsInList(traceList)
	CHECK_EQUAL_VAR(traceNum, patest.layoutSize / 2)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			if(i == j)
				continue
			endif
			traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[i], patest.regions[j])
			CHECK(PAT_CheckIfTracesAreFront(traceListAll, traceName, patest.channels[i], patest.regions[j], 0))
			// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
			WAVE pData = TraceNameToWaveRef(graph, traceName)
			CHECK_EQUAL_VAR(DimSize(pData, ROWS), dataSize)
			CHECK_EQUAL_WAVES(refData[i][j], pData, mode = WAVE_DATA, tol = dataSize)
		endfor
	endfor
End

static Function PAT_BasicOVSCheck()

	string bspName, graph
	STRUCT PA_Test patest0
	STRUCT PA_Test patest3
	STRUCT PA_Test patest

	string traceListAll, traceList, traceNames, traceName
	variable traceNum, i, j, k, size

	PA_InitSweep0(patest0)
	PA_InitSweep3(patest3)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 3)

	traceListAll = PAT_GetTraces(graph, 2 * patest0.layoutSize)

	size = sqrt(patest0.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceNames = PAT_FindTraceNames(traceListAll, patest0.channels[i], patest0.regions[j], 0)
			traceNum = ItemsInList(traceNames)
			CHECK_EQUAL_VAR(traceNum, 2)
			for(k = 0; k < traceNum; k += 1)
				if(k == 1)
					patest = patest3
				else
					patest = patest0
				endif
				traceName = StringFromList(k, traceNames)
				if(k == 1)
					CHECK(PAT_CheckIfTracesAreFront(traceListAll, traceName, patest.channels[i], patest.regions[j], 0))
				endif
				// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
				PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
				PAT_VerifyTraceAxesRange(graph, traceName, patest)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				CHECK_EQUAL_WAVES(patest.refData, pData, mode = WAVE_DATA, tol = patest.eqWaveTol)
				PAT_CheckPulseWaveNote(bspName, pData)
			endfor
		endfor
	endfor
End

static Function PAT_BasicOVSAverageCheck()

	string bspName, graph
	STRUCT PA_Test patest
	STRUCT PA_Test patest3

	string traceListAll, traceList, traceName
	variable traceNum, i, j, k, size

	PA_InitSweep0(patest)
	PA_InitSweep3(patest3)

	Duplicate/FREE patest.refData, avgRefData
	avgRefData = (patest.refData + patest3.refData) / 2

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 3)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)

	traceListAll = PAT_GetTraces(graph, 3 * patest.layoutSize)

	traceList = GrepList(traceListAll, PA_AVERAGE_WAVE_PREFIX)
	traceNum = ItemsInList(traceList)
	CHECK_EQUAL_VAR(traceNum, patest.layoutSize)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceName = PAT_FindTraceNameAvgDeconv(traceList, patest.channels[i], patest.regions[j])
			CHECK(PAT_CheckIfTracesAreFront(traceListAll, traceName, patest.channels[i], patest.regions[j], 0))
			// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
			PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
			PAT_VerifyTraceAxesRange(graph, traceName, patest)
			WAVE pData = TraceNameToWaveRef(graph, traceName)
			CHECK_EQUAL_WAVES(avgRefData, pData, mode = WAVE_DATA, tol = patest.eqWaveTol)
			PAT_CheckAverageWaveNote(pData)
		endfor
	endfor
End

static Function PAT_FailedPulseCheck1()

	string bspName, graph
	STRUCT PA_Test patest0
	STRUCT PA_Test patest4
	STRUCT PA_Test patest

	string traceListAll, traceList, traceNames, traceName, spikePositions
	variable traceNum, i, j, k, size, numSpikes, pulseHasFailed

	PA_InitSweep0(patest0)
	PA_InitSweep4(patest4)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 4)

	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 5)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_searchFailedPulses", val = 1)

	traceListAll = PAT_GetTraces(graph, 2 * patest0.layoutSize)

	size = sqrt(patest0.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceNames = PAT_FindTraceNames(traceListAll, patest0.channels[i], patest0.regions[j], 0)
			traceNum = ItemsInList(traceNames)
			CHECK_EQUAL_VAR(traceNum, 2)
			for(k = 0; k < traceNum; k += 1)
				if(k == 1)
					patest = patest4
				else
					patest = patest0
				endif

				pulseHasFailed = 0
				numSpikes = 1

				traceName = StringFromList(k, traceNames)
				if(k == 1)
					CHECK(PAT_CheckIfTracesAreFront(traceListAll, traceName, patest.channels[i], patest.regions[j], 0))
				endif
				// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
				PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
				PAT_VerifyTraceAxesRange(graph, traceName, patest)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				CHECK_EQUAL_WAVES(patest.refData, pData, mode = WAVE_DATA, tol = patest.eqWaveTol)
				PAT_CheckPulseWaveNote(bspName, pData)
				PAT_CheckFailedPulse(bspName, pData, i == j, pulseHasFailed, numSpikes)
			endfor
		endfor
	endfor

	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 75)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_numberOfSpikes", val = NaN)

	traceListAll = PAT_GetTraces(graph, 2 * patest0.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceNames = PAT_FindTraceNames(traceListAll, patest0.channels[i], patest0.regions[j], 0)
			traceNum = ItemsInList(traceNames)
			for(k = 0; k < traceNum; k += 1)
				if(k == 1)
					patest = patest4
				else
					patest = patest0
				endif

				pulseHasFailed = k > 0
				numSpikes = k == 0 && i == j

				if(numSpikes == 1)
					if(i == 0 && j == 0)
						spikePositions = "0.0213333,"
					else
						spikePositions = "0.02,"
					endif
				else
					spikePositions = ""
				endif

				traceName = StringFromList(k, traceNames)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				PAT_CheckPulseWaveNote(bspName, pData)
				PAT_CheckFailedPulse(bspName, pData, i == j, pulseHasFailed, numSpikes, spikePositions = spikePositions)
				PAT_CheckIfTraceIsRed(graph, traceName, k == 1)
			endfor
		endfor
	endfor

	// now with Number of Spikes set to the correct value
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 75)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_numberOfSpikes", val = 1)

	traceListAll = PAT_GetTraces(graph, 2 * patest0.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceNames = PAT_FindTraceNames(traceListAll, patest0.channels[i], patest0.regions[j], 0)
			traceNum = ItemsInList(traceNames)
			for(k = 0; k < traceNum; k += 1)
				if(k == 1)
					patest = patest4
				else
					patest = patest0
				endif

				pulseHasFailed = k > 0
				numSpikes = k == 0 && i == j

				if(numSpikes == 1)
					if(i == 0 && j == 0)
						spikePositions = "0.0213333,"
					else
						spikePositions = "0.02,"
					endif
				else
					spikePositions = ""
				endif

				traceName = StringFromList(k, traceNames)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				PAT_CheckPulseWaveNote(bspName, pData)
				PAT_CheckFailedPulse(bspName, pData, i == j, pulseHasFailed, numSpikes, spikePositions = spikePositions)
				PAT_CheckIfTraceIsRed(graph, traceName, k == 1)
			endfor
		endfor
	endfor

	// now with Number of Spikes set too large
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 75)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_numberOfSpikes", val = 2)

	traceListAll = PAT_GetTraces(graph, 2 * patest0.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceNames = PAT_FindTraceNames(traceListAll, patest0.channels[i], patest0.regions[j], 0)
			traceNum = ItemsInList(traceNames)
			for(k = 0; k < traceNum; k += 1)
				if(k == 1)
					patest = patest4
				else
					patest = patest0
				endif

				pulseHasFailed = 1
				numSpikes = k == 0 && i == j

				if(numSpikes == 1)
					if(i == 0 && j == 0)
						spikePositions = "0.0213333,"
					else
						spikePositions = "0.02,"
					endif
				else
					spikePositions = ""
				endif

				traceName = StringFromList(k, traceNames)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				PAT_CheckPulseWaveNote(bspName, pData)
				PAT_CheckFailedPulse(bspName, pData, i == j, pulseHasFailed, numSpikes, spikePositions = spikePositions)
				PAT_CheckIfTraceIsRed(graph, traceName, pulseHasFailed)
			endfor
		endfor
	endfor
End

Function PAT_FailedPulseCheckVC()
	string bspName, graph
	STRUCT PA_Test patest0
	STRUCT PA_Test patest4
	STRUCT PA_Test patest

	string traceListAll, traceList, traceNames, traceName, spikePositions
	variable traceNum, i, j, k, size, numSpikes, pulseHasFailed

	PA_InitSweep0(patest0)
	PA_InitSweep4(patest4)

	// now with VC data again
	WAVE numericalValues = root:MIES:LabNoteBook:Dev1:numericalValues
	MultiThread numericalValues[][%$"Clamp Mode"][] = (numericalValues[p][%$"Clamp Mode"][r] == I_CLAMP_MODE ? V_CLAMP_MODE : numericalValues[p][%$"Clamp Mode"][r])

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 4)

	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 5)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_searchFailedPulses", val = 1)

	traceListAll = PAT_GetTraces(graph, 2 * patest0.layoutSize)

	size = sqrt(patest0.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			traceNames = PAT_FindTraceNames(traceListAll, patest0.channels[i], patest0.regions[j], 0)
			traceNum = ItemsInList(traceNames)
			CHECK_EQUAL_VAR(traceNum, 2)
			for(k = 0; k < traceNum; k += 1)
				if(k == 1)
					patest = patest4
				else
					patest = patest0
				endif

				pulseHasFailed = 0
				numSpikes = 0

				traceName = StringFromList(k, traceNames)

				// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
				PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
				PAT_VerifyTraceAxesRange(graph, traceName, patest)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				CHECK_EQUAL_WAVES(patest.refData, pData, mode = WAVE_DATA, tol = patest.eqWaveTol)
				PAT_CheckPulseWaveNote(bspName, pData)
				PAT_CheckFailedPulse(bspName, pData, i == j, pulseHasFailed, numSpikes)
			endfor
		endfor
	endfor
End

static Function PAT_FailedPulseCheck2()

	string bspName, graph
	STRUCT PA_Test patest5

	string traceListAll, traceList, traceNames, traceName
	variable traceNum, i, j, size, region, pulseHasFailed, numSpikes

	PA_InitSweep5(patest5)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 0, sweepNo = 0)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 5)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_searchFailedPulses", val = 1)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 20)

	size = sqrt(patest5.layoutSize)
	traceListAll = PAT_GetTraces(graph, patest5.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			region = patest5.regions[j]
			traceName = PAT_FindTraceNames(traceListAll, patest5.channels[i], region, 0)

			pulseHasFailed = (region == 5)
			numSpikes = (i == 0 && j == 0) ? 0 : 1

			WAVE pData = TraceNameToWaveRef(graph, traceName)
			PAT_CheckPulseWaveNote(bspName, pData)
			PAT_CheckFailedPulse(bspName, pData, i == j, pulseHasFailed, numSpikes)
			PAT_CheckIfTraceIsRed(graph, traceName, region == 5)
		endfor
	endfor

	PGC_SetAndActivateControl(bspName, "check_pulseAver_hideFailedPulses", val = 1)
	traceListAll = PAT_GetTraces(graph, patest5.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			region = patest5.regions[j]
			traceName = PAT_FindTraceNames(traceListAll, patest5.channels[i], region, 0)

			pulseHasFailed = (region == 5)

			WAVE pData = TraceNameToWaveRef(graph, traceName)
			PAT_CheckIfTraceIsHidden(graph, traceName, pulseHasFailed)
		endfor
	endfor
End

static Function PAT_FailedPulseCheck3()

	string bspName, graph
	STRUCT PA_Test patest5

	string traceListAll, traceListAvg, traceListDeconv, traceNames, traceName
	variable traceNum, i, j, size, region, avgTraceNum, deconvTraceNum

	PA_InitSweep5(patest5)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 0, sweepNo = 0)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 5)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_searchFailedPulses", val = 1)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_hideFailedPulses", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)

	size = sqrt(patest5.layoutSize)
	avgTraceNum = 3
	deconvTraceNum = 2

	traceListAll = PAT_GetTraces(graph, patest5.layoutSize + avgTraceNum + deconvTraceNum)

	traceListAvg = GrepList(traceListAll, PA_AVERAGE_WAVE_PREFIX)
	traceNum = ItemsInList(traceListAvg)
	CHECK_EQUAL_VAR(traceNum, avgTraceNum)

	traceListDeconv = GrepList(traceListAll, PA_DECONVOLUTION_WAVE_PREFIX)
	traceNum = ItemsInList(traceListDeconv)
	CHECK_EQUAL_VAR(traceNum, deconvTraceNum)

	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			region = patest5.regions[j]
			if(region == 3)
				traceName = PAT_FindTraceNameAvgDeconv(traceListAvg, patest5.channels[i], region)
				PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest5)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				PAT_CheckAverageWaveNote(pData)
			else
				traceName = PAT_FindTraceNameAvgDeconv(traceListAvg, patest5.channels[i], region, checkForNoTrace = 1)
			endif

			if(region == 3 && i != j)
				traceName = PAT_FindTraceNameAvgDeconv(traceListDeconv, patest5.channels[i], region)
				PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest5)
				CHECK(PAT_CheckIfTracesAreFront(traceListDeconv, traceName, patest5.channels[i], patest5.regions[j], 0))
			else
				traceName = PAT_FindTraceNameAvgDeconv(traceListDeconv, patest5.channels[i], region, checkForNoTrace = 1)
			endif
		endfor
	endfor
End

static Function PAT_FailedPulseCheck4()

	string bspName, graph
	STRUCT PA_Test patest5

	string traceListAll, traceListDeconv, traceNames, traceName
	variable traceNum, i, j, size, region, deconvTraceNum

	PA_InitSweep5(patest5)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 0, sweepNo = 0)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 5)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_searchFailedPulses", val = 1)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_hideFailedPulses", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 0)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_indPulses", val = 0)

	size = sqrt(patest5.layoutSize)
	deconvTraceNum = 2

	traceListAll = PAT_GetTraces(graph, deconvTraceNum)

	traceListDeconv = GrepList(traceListAll, PA_DECONVOLUTION_WAVE_PREFIX)
	traceNum = ItemsInList(traceListDeconv)
	CHECK_EQUAL_VAR(traceNum, deconvTraceNum)

	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			region = patest5.regions[j]
			if(region == 3 && i != j)
				traceName = PAT_FindTraceNameAvgDeconv(traceListDeconv, patest5.channels[i], region)
				PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest5)
				CHECK(PAT_CheckIfTracesAreFront(traceListDeconv, traceName, patest5.channels[i], patest5.regions[j], 0))
			else
				traceName = PAT_FindTraceNameAvgDeconv(traceListDeconv, patest5.channels[i], region, checkForNoTrace = 1)
			endif
		endfor
	endfor
End

static Function PAT_MultiSweep1()

	string bspName, graph
	STRUCT PA_Test patest
	STRUCT PA_Test patest0
	STRUCT PA_Test patest5

	string traceListAll, traceNames, traceName
	variable traceNum, i, j, k, size, channel, region, combinedLayoutSize

	PA_InitSweep0(patest0)
	PA_InitSweep5(patest5)
	Make/FREE combinedChannels = {0, 1, 3}
	Make/FREE combinedRegions = {5, 1, 3}
	combinedLayoutSize = 9
	WAVE patest0.channels = combinedChannels
	WAVE patest0.regions = combinedRegions
	WAVE patest5.channels = combinedChannels
	WAVE patest5.regions = combinedRegions

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 5)

	traceListAll = PAT_GetTraces(graph, patest5.layoutSize + patest0.layoutSize)

	patest0.layoutSize = combinedLayoutSize
	patest5.layoutSize = combinedLayoutSize
	size = DimSize(combinedChannels, ROWS)
	for(i = 0; i < size; i += 1)
		channel = combinedChannels[i]
		for(j = 0; j < size; j += 1)
			region = combinedRegions[j]
			if(region != 5 && channel != 0)
				traceNames = PAT_FindTraceNames(traceListAll, channel, region, 0)
				traceNum = ItemsInList(traceNames)
				CHECK_EQUAL_VAR(traceNum, 2)
				for(k = 0; k < traceNum; k += 1)
					if(k == 1)
						patest = patest5
					else
						patest = patest0
					endif
					patest.layoutSize = size * size
					traceName = StringFromList(k, traceNames)
					PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
					if(k == 0)
						WAVE pData = TraceNameToWaveRef(graph, traceName)
						CHECK_EQUAL_WAVES(patest.refData, pData, mode = WAVE_DATA, tol = patest.eqWaveTol)
					endif
				endfor
			else
				traceNames = PAT_FindTraceNames(traceListAll, channel, region, 0)
				traceNum = ItemsInList(traceNames)
				CHECK_EQUAL_VAR(traceNum, 1)

				PAT_VerifyTraceAxes(graph, traceNames, i + 1, j + 1, patest5)
			endif
		endfor
	endfor
End

static Function PAT_MultiSweep2()

	string bspName, graph
	STRUCT PA_Test patest
	string traceList, traceName
	variable i, j, k, size

	PA_InitSweep0(patest)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 0, sweepNo = 0)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 5)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 0)
	OVS_ChangeSweepSelectionState(bspName, 0, sweepNo = 5)

	traceList = PAT_GetTraces(graph, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			for(k = 0; k < patest.pulseCnt; k += 1)
				traceName = PAT_FindTraceNames(traceList, patest.channels[i], patest.regions[j], k)
				// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
				PAT_VerifyTraceAxes(graph, traceName, i + 1, j + 1, patest)
				PAT_VerifyTraceAxesRange(graph, traceName, patest)
				WAVE pData = TraceNameToWaveRef(graph, traceName)
				CHECK_EQUAL_WAVES(patest.refData, pData, mode = WAVE_DATA, tol = patest.eqWaveTol)
				PAT_CheckPulseWaveNote(bspName, pData)
			endfor
		endfor
	endfor
End

static Function PAT_MultiSweepAvg()

	string bspName, graph
	STRUCT PA_Test patest

	string traceListAll, traceNames, traceName, traceListAvg, traceListDeconv
	variable traceNum, i, j, k, size, avgTraceNum, deconvTraceNum

	PA_InitSweep0(patest)

	avgTraceNum = 4
	deconvTraceNum = 2

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 3)

	traceListAll = PAT_GetTraces(graph, patest.layoutSize + patest.layoutSize + avgTraceNum + deconvTraceNum)

	traceListAvg = GrepList(traceListAll, PA_AVERAGE_WAVE_PREFIX)
	traceNum = ItemsInList(traceListAvg)
	CHECK_EQUAL_VAR(traceNum, avgTraceNum)

	traceListDeconv = GrepList(traceListAll, PA_DECONVOLUTION_WAVE_PREFIX)
	traceNum = ItemsInList(traceListDeconv)
	CHECK_EQUAL_VAR(traceNum, deconvTraceNum)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			if(i == j)
				traceNames = PAT_FindTraceNameAvgDeconv(traceListDeconv, patest.channels[i], patest.regions[j], checkForNoTrace = 1)
			else
				traceNames = PAT_FindTraceNameAvgDeconv(traceListDeconv, patest.channels[i], patest.regions[j])
				traceNum = ItemsInList(traceNames)
				CHECK_EQUAL_VAR(traceNum, 1)
				PAT_VerifyTraceAxes(graph, traceNames, i + 1, j + 1, patest)
			endif
			traceNames = PAT_FindTraceNameAvgDeconv(traceListAvg, patest.channels[i], patest.regions[j])
			traceNum = ItemsInList(traceNames)
			CHECK_EQUAL_VAR(traceNum, 1)
			PAT_VerifyTraceAxes(graph, traceNames, i + 1, j + 1, patest)
		endfor
	endfor
End

static Function/WAVE PAT_IncrementalSweepAdd_Generator()

	Make/FREE/WAVE/N=4 w

	Make/FREE sweeps = {0, 1, 2, 3, 4, 5}
	w[0] = sweeps
	Make/FREE sweeps = {5, 4, 3, 2, 1, 0}
	w[1] = sweeps
	Make/FREE sweeps = {2, 1, 5, 3, 4, 0}
	w[2] = sweeps
	Make/FREE sweeps = {4, 3, 5, 0, 1, 2}
	w[3] = sweeps

	return w
End
// UTF_TD_GENERATOR PAT_IncrementalSweepAdd_Generator
static Function PAT_IncrementalSweepAdd([WAVE wv])

	string bspName, graph

	string traceListAll
	variable i, numSweeps

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_zero", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_searchFailedPulses", val = 1)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 75)
	OVS_ChangeSweepSelectionState(bspName, 0, sweepNo = 0)

	wv = OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = wv[p])

	traceListAll = PAT_GetTraces(graph, 26 + 6 + 4)
	// The traces are numbered by the index position in properties, if any are displayed twice
	// then we get identical names and igor adds auto numbering at the end with a hash as delimeter.
	CHECK_EQUAL_VAR(strsearch(traceListAll, "#", 0), -1)
End

static Function PAT_IncrementalSweepAddPartialAvgCheck()

	string bspName, graph

	string traceListAll, traceList
	variable traceNum

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)

	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 2)

	traceListAll = PAT_GetTraces(graph, 5 + 4)
	traceList = GrepList(traceListAll, PA_AVERAGE_WAVE_PREFIX)
	traceNum = ItemsInList(traceList)
	CHECK_EQUAL_VAR(traceNum, 4)
End

static Function PAT_HSRemoval1()

	string bspName, graph
	STRUCT PA_Test patest4

	string traceListAll, traceNames
	variable traceNum, i, j, size, region, channel

	PA_InitSweep4(patest4)

	[bspName, graph] = PAT_StartDataBrowser_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 4)
	PGC_SetAndActivateControl(bspName, "check_overlaySweeps_disableHS", val = 1)
	MIES_OVS#OVS_AddToIgnoreList(bspName, 1, sweepNo = 0)

	traceListAll = PAT_GetTraces(graph, 1 + patest4.layoutSize)

	size = sqrt(patest4.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			region = patest4.regions[j]
			channel = patest4.channels[i]
			traceNames = PAT_FindTraceNames(traceListAll, channel, region, 0)
			traceNum = ItemsInList(traceNames)
			if(region == 3 && channel == 3)
				CHECK_EQUAL_VAR(traceNum, 2)
				if(traceNum == 2)
					WAVE pData = TraceNameToWaveRef(graph, StringFromList(0, traceNames))
					CHECK_NEQ_VAR(strsearch(GetWavesDataFolder(pData, 2), ":X_0:", 0), -1)
					WAVE pData = TraceNameToWaveRef(graph, StringFromList(1, traceNames))
					CHECK_NEQ_VAR(strsearch(GetWavesDataFolder(pData, 2), ":X_4:", 0), -1)
				endif
			else
				CHECK_EQUAL_VAR(traceNum, 1)
				if(traceNum == 1)
					WAVE pData = TraceNameToWaveRef(graph, traceNames)
					CHECK_NEQ_VAR(strsearch(GetWavesDataFolder(pData, 2), ":X_4:", 0), -1)
				endif
			endif
		endfor
	endfor
End


static Function PAT_BasicImagePlot()

	string bspName, imageWin
	STRUCT PA_Test patest

	string imageList, imageName, winL, annoL, subWin
	variable i, j, size

	PA_InitSweep0(patest)

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()

	imageList = PAT_GetImages(imageWin, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			imageName = PAT_FindImageNames(imageList, patest.channels[i], patest.regions[j])
			// layout note: channel is Y, region is X, low channels start on top at yPos to 100%
			PAT_VerifyImageAxes(imageWin, imageName, i + 1, j + 1, patest)
			PAT_VerifyImageAxesRange(imageWin, imageName, patest)

			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			Duplicate/FREE/RMD=[][0] iData, profileLine
			Redimension/N=(-1) profileLine
			CHECK_EQUAL_WAVES(patest.refData, profileLine, mode = WAVE_DATA, tol = patest.eqWaveTol)
			PAT_CheckImageWaveNote(bspName, iData, patest)
		endfor
	endfor

	winL = GetAllWindows(imageWin)
	CHECK_EQUAL_VAR(ItemsInList(winL), 3)
	CHECK_NEQ_VAR(WhichListItem(imageWin + "#P0", winL), -1)
	CHECK_NEQ_VAR(WhichListItem(imageWin + "#P0#G0", winL), -1)

	subWin = imageWin + "#P0#G0"
	annoL = AnnotationList(subWin)
	CHECK_EQUAL_VAR(ItemsInList(annoL), size + 1)
End

static Function PAT_BasicImagePlotAverage()

	string bspName, imageWin
	STRUCT PA_Test patest

	string imageList, imageName
	variable i, j, size

	PA_InitSweep0(patest)

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)

	imageList = PAT_GetImages(imageWin, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			imageName = PAT_FindImageNames(imageList, patest.channels[i], patest.regions[j])

			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			Duplicate/FREE/RMD=[][0] iData, avgData
			Redimension/N=(-1) avgData
			CHECK_EQUAL_WAVES(patest.refData, avgData, mode = WAVE_DATA, tol = patest.eqWaveTol)
		endfor
	endfor
End

static Function PAT_BasicImagePlotDeconvolution()

	string bspName, imageWin
	STRUCT PA_Test patest

	string imageList, imageName
	variable traceNum, i, j, size, singlePulseColumnOffset, vMin, vMax

	PA_InitSweep0(patest)
	Make/FREE/WAVE/N=(2, 2) refData
	refData[0][1] = root:pa_test_deconv_ref2
	refData[1][0] = root:pa_test_deconv_ref1

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)

	imageList = PAT_GetImages(imageWin, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			if(i != j)
				imageName = PAT_FindImageNames(imageList, patest.channels[i], patest.regions[j])

				WAVE iData = ImageNameToWaveRef(imageWin, imageName)
				vMin = GetNumberFromWaveNote(iData, NOTE_KEY_IMG_PMIN)
				vMax = GetNumberFromWaveNote(iData, NOTE_KEY_IMG_PMAX)
				Duplicate/FREE refData[i][j], adaptedRefData
				adaptedRefData = limit(adaptedRefData[p], vMin, vMax)

				// order is pulse, avg, deconv
				Duplicate/FREE/RMD=[][2] iData, deconvData
				Redimension/N=(DimSize(adaptedRefData, ROWS)) deconvData
				CHECK_EQUAL_WAVES(adaptedRefData, deconvData, mode = WAVE_DATA)
			endif
		endfor
	endfor
End

static Function PAT_ImagePlotMultiSweep0()

	string bspName, imageWin
	STRUCT PA_Test patest0
	STRUCT PA_Test patest3

	string imageList, imageName
	variable i, j, size

	PA_InitSweep0(patest0)
	PA_InitSweep3(patest3)

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 3)

	imageList = PAT_GetImages(imageWin, patest0.layoutSize)
	size = sqrt(patest0.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			imageName = PAT_FindImageNames(imageList, patest0.channels[i], patest0.regions[j])
			PAT_VerifyImageAxes(imageWin, imageName, i + 1, j + 1, patest0)
			PAT_VerifyImageAxesRange(imageWin, imageName, patest0)

			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			Duplicate/FREE/RMD=[][0] iData, profileLine0
			Redimension/N=(-1) profileLine0
			CHECK_EQUAL_WAVES(patest0.refData, profileLine0, mode = WAVE_DATA, tol = patest0.eqWaveTol)

			Duplicate/FREE/RMD=[][patest0.pulseCnt] iData, profileLine3
			Redimension/N=(-1) profileLine3
			CHECK_EQUAL_WAVES(patest3.refData, profileLine3, mode = WAVE_DATA, tol = patest3.eqWaveTol)
		endfor
	endfor
End

static Function PAT_ImagePlotAverageExtended()

	string bspName, imageWin
	STRUCT PA_Test patest
	STRUCT PA_Test patest3

	string imageList, imageName
	variable i, j, size

	PA_InitSweep0(patest)
	PA_InitSweep3(patest3)

	Duplicate/FREE patest.refData, avgRefData
	avgRefData = (patest.refData + patest3.refData) / 2

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 3)

	imageList = PAT_GetImages(imageWin, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			imageName = PAT_FindImageNames(imageList, patest.channels[i], patest.regions[j])

			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			// order is pulse, pulse, avg, deconv
			Duplicate/FREE/RMD=[][2] iData, avgData
			Redimension/N=(-1) avgData
			CHECK_EQUAL_WAVES(avgRefData, avgData, mode = WAVE_DATA, tol = patest.eqWaveTol)
		endfor
	endfor
End

static Function PAT_ImagePlotMultiSweep1()

	string bspName, imageWin
	STRUCT PA_Test patest0
	STRUCT PA_Test patest5

	string imageList, imageName
	variable i, j, size, combinedLayoutSize

	PA_InitSweep0(patest0)
	PA_InitSweep5(patest5)
	Make/FREE combinedChannels = {0, 1, 3}
	Make/FREE combinedRegions = {5, 1, 3}
	combinedLayoutSize = 9
	WAVE patest0.channels = combinedChannels
	WAVE patest0.regions = combinedRegions
	WAVE patest5.channels = combinedChannels
	WAVE patest5.regions = combinedRegions
	patest0.layoutSize = combinedLayoutSize
	patest5.layoutSize = combinedLayoutSize

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 5)

	imageList = PAT_GetImages(imageWin, patest5.layoutSize)
	size = sqrt(patest5.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			imageName = PAT_FindImageNames(imageList, combinedChannels[i], combinedRegions[j])
			if(i == 0) // AD0
				PAT_VerifyImageAxes(imageWin, imageName, i + 1, j + 1, patest5)

				Make/FREE/D/N=(patest5.dataLength) refData = 0

				WAVE iData = ImageNameToWaveRef(imageWin, imageName)
				Duplicate/FREE/RMD=[][0] iData, profileLine
				Redimension/N=(-1) profileLine
				CHECK_EQUAL_WAVES(refData, profileLine, mode = WAVE_DATA, tol = patest5.dataLength)
			endif
			if(j == 0 && i > 0) // R5 with AD1, AD3
				PAT_VerifyImageAxes(imageWin, imageName, i + 1, j + 1, patest5)

				Make/FREE/D/N=(patest5.dataLength) refData
				refData[1, patest5.dataLength / 2 + 1] = 100

				WAVE iData = ImageNameToWaveRef(imageWin, imageName)
				Duplicate/FREE/RMD=[][0] iData, profileLine
				Redimension/N=(-1) profileLine
				CHECK_EQUAL_WAVES(refData, profileLine, mode = WAVE_DATA, tol = patest5.dataLength)
			endif
			if(j > 0 && i > 0) // R1, R3 with AD1, AD3
				PAT_VerifyImageAxes(imageWin, imageName, i + 1, j + 1, patest0)

				WAVE iData = ImageNameToWaveRef(imageWin, imageName)
				Duplicate/FREE/RMD=[][0] iData, profileLine
				Redimension/N=(-1) profileLine
				CHECK_EQUAL_WAVES(patest0.refData, profileLine, mode = WAVE_DATA, tol = patest0.eqWaveTol)


				Make/FREE/D/N=(patest5.dataLength) refData
				refData[1, patest5.dataLength / 2 + 1] = 100
				Interpolate2/N=(patest0.dataLength)/T=1/Y=refDataInterp refData
				Duplicate/FREE/RMD=[][1] iData, profileLine
				Redimension/N=(-1) profileLine
				CHECK_EQUAL_WAVES(refDataInterp, profileLine, mode = WAVE_DATA, tol = patest0.dataLength)
			endif
		endfor
	endfor
End

static Function PAT_ImagePlotFailedPulses()

	string bspName, imageWin
	STRUCT PA_Test patest0
	STRUCT PA_Test patest4

	string imageList, imageName, winL, annoL, subWin
	variable i, j, size, singlePulseColumnOffset

	PA_InitSweep0(patest0)
	PA_InitSweep4(patest4)

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 4)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_searchFailedPulses", val = 1)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 75)

	imageList = PAT_GetImages(imageWin, patest0.layoutSize)
	size = sqrt(patest0.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			imageName = PAT_FindImageNames(imageList, patest0.channels[i], patest0.regions[j])
			PAT_VerifyImageAxes(imageWin, imageName, i + 1, j + 1, patest0)
			PAT_VerifyImageAxesRange(imageWin, imageName, patest0)

			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			Duplicate/FREE/RMD=[][patest0.pulseCnt] iData, profileLine
			Redimension/N=(-1) profileLine
			CHECK_EQUAL_VAR(profileLine[Inf], Inf)
		endfor
	endfor

	PGC_SetAndActivateControl(bspName, "check_pulseAver_hideFailedPulses", val = 1)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			imageName = PAT_FindImageNames(imageList, patest0.channels[i], patest0.regions[j])

			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			Duplicate/FREE/RMD=[][patest0.pulseCnt] iData, profileLine
			Redimension/N=(-1) profileLine
			Duplicate/FREE patest0.refData, refData
			refData = NaN
			CHECK_EQUAL_WAVES(profileLine, refData, mode = WAVE_DATA)
		endfor
	endfor
End

static Function PAT_ImagePlotMultipleGraphs()

	string bspName, imageWin
	STRUCT PA_Test patest

	string imageList, imageName, imageWinSingle
	variable i, j, size, singlePulseColumnOffset

	PA_InitSweep0(patest)

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_pulseAver_multGraphs", val = 1)

	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			imageWinSingle = imageWin + "_AD" + num2str(patest.channels[i]) + "_R" + num2str(j + 1)

			imageList = PAT_GetImages(imageWinSingle, 1)
			imageName = PAT_FindImageNames(imageList, patest.channels[i], patest.regions[j])
			PAT_VerifyImageAxes(imageWinSingle, imageName, i + 1, j + 1, patest, multiGraphMode = 1)
			PAT_VerifyImageAxesRange(imageWinSingle, imageName, patest)

			WAVE iData = ImageNameToWaveRef(imageWinSingle, imageName)
			Duplicate/FREE/RMD=[][0] iData, profileLine
			Redimension/N=(-1) profileLine
			CHECK_EQUAL_WAVES(patest.refData, profileLine, mode = WAVE_DATA, tol = patest.eqWaveTol)
			PAT_CheckImageWaveNote(bspName, iData, patest)
		endfor
	endfor
End

static Function PAT_ImagePlotPartialFullFail()

	string bspName, imageWin
	STRUCT PA_Test patest

	string imageList, imageName
	variable i, j, size, region, channel, numEntries, profilePos

	PA_InitSweep5(patest)

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_showAver", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_deconv", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_zero", val = 1)
	PGC_SetAndActivateControl(bspName, "check_pulseAver_searchFailedPulses", val = 1)
	PGC_SetAndActivateControl(bspName, "setvar_pulseAver_failedPulses_level", val = 90)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 5)

	imageList = PAT_GetImages(imageWin, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			region = patest.regions[j]
			channel = patest.channels[i]

			imageName = PAT_FindImageNames(imageList, channel, region)
			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			numEntries = GetNumberFromWaveNote(iData, NOTE_INDEX)
			profilePos = trunc(DimSize(iData, ROWS) * (PA_IMAGE_FAILEDMARKERSTART + (1 - PA_IMAGE_FAILEDMARKERSTART) / 2))

			Duplicate/FREE/RMD=[profilePos][0, numEntries - 1] iData, profileLine
			Redimension/E=1/N=(numEntries) profileLine
			Duplicate/FREE profileLine, result

			if(region == 5)
				// check only NaN, Inf present
				result = IsNaN(profileLine[p]) || (profileLine[p] == Inf)
				CHECK_EQUAL_VAR(sum(result), numEntries)
				continue
			endif

			if(channel == 0)
				// check only finite present
				result = IsFinite(profileLine[p])
				CHECK_EQUAL_VAR(sum(result), numEntries)
				continue
			endif

			if(channel == region) // == diagonal, i.e. deconv is NaN
				// check only NaN, Inf or finite
				result = IsFinite(profileLine[p]) || (profileLine[p] == Inf) || IsNaN(profileLine[p])
				CHECK_EQUAL_VAR(sum(result), numEntries)
			else
				// check only Inf and finite, non-diagonal, deconv is present
				result = IsFinite(profileLine[p]) || (profileLine[p] == Inf)
				CHECK_EQUAL_VAR(sum(result), numEntries)
			endif
		endfor
	endfor
End

static Function PAT_ImagePlotIncrementalPartial()

	string bspName, imageWin
	STRUCT PA_Test patest

	string imageList, imageName
	variable i, j, size, region, channel, numEntries

	PA_InitSweep5(patest)

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 0, sweepNo = 0)

	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 5)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 0)

	imageList = PAT_GetImages(imageWin, patest.layoutSize)
	size = sqrt(patest.layoutSize)
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			region = patest.regions[j]
			channel = patest.channels[i]

			imageName = PAT_FindImageNames(imageList, channel, region)
			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			numEntries = GetNumberFromWaveNote(iData, NOTE_INDEX)

			if(region == 5 || channel == 0)
				CHECK_EQUAL_VAR(1 + 2, numEntries)
			else
				CHECK_EQUAL_VAR(2 + 2, numEntries)
			endif
		endfor
	endfor
End

static Function PAT_ImagePlotSortOrder()

	string bspName, imageWin
	STRUCT PA_Test patest7
	STRUCT PA_Test patest8

	string imageList, imageName
	variable i, j, size, region, channel, numEntries, profilePos

	PA_InitSweep7(patest7)
	PA_InitSweep8(patest8)

	[bspName, imageWin] = PAT_StartDataBrowserImage_IGNORE()
	PGC_SetAndActivateControl(bspName, "check_BrowserSettings_OVS", val = 1)
	OVS_ChangeSweepSelectionState(bspName, 0, sweepNo = 0)

	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 7)
	OVS_ChangeSweepSelectionState(bspName, 1, sweepNo = 8)

	// S7P0, S8P0, S7P1, S8P1, S7P2, S8P2, S7P3, S8P3, then NaN for avg, deconv
	Make/FREE/D refDataPulseIndex = {100, 50, 100, 50, 100, 50, 100, 50, NaN, NaN}
	// S7P0, S7P1, S7P2, S7P3, S8P0, S8P1, S8P2, S8P3, then NaN for avg, deconv
	Make/FREE/D refDataSweep = {100, 100, 100, 100, 50, 50, 50, 50, NaN, NaN}

	imageList = PAT_GetImages(imageWin, patest7.layoutSize)
	size = sqrt(patest7.layoutSize)
	// Explicitly set it to another value before activating the selection that should be tested
	PGC_SetAndActivateControl(bspName, "popup_pulseAver_pulseSortOrder", str = "PulseIndex")
	PGC_SetAndActivateControl(bspName, "popup_pulseAver_pulseSortOrder", str = "Sweep")

	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			region = patest7.regions[j]
			channel = patest7.channels[i]

			imageName = PAT_FindImageNames(imageList, channel, region)
			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			numEntries = GetNumberFromWaveNote(iData, NOTE_INDEX)

			profilePos = trunc(DimSize(iData, ROWS) * 0.1)

			Duplicate/FREE/RMD=[profilePos][0, numEntries - 1] iData, profileLine
			Redimension/E=1/N=(numEntries) profileLine
			Duplicate/FREE profileLine, result

			CHECK_EQUAL_WAVES(profileLine, refDataSweep, mode = WAVE_DATA, tol = numEntries)
		endfor
	endfor

	PGC_SetAndActivateControl(bspName, "popup_pulseAver_pulseSortOrder", str = "PulseIndex")
	for(i = 0; i < size; i += 1)
		for(j = 0; j < size; j += 1)
			region = patest7.regions[j]
			channel = patest7.channels[i]

			imageName = PAT_FindImageNames(imageList, channel, region)
			WAVE iData = ImageNameToWaveRef(imageWin, imageName)
			numEntries = GetNumberFromWaveNote(iData, NOTE_INDEX)

			profilePos = trunc(DimSize(iData, ROWS) * 0.1)

			Duplicate/FREE/RMD=[profilePos][0, numEntries - 1] iData, profileLine
			Redimension/E=1/N=(numEntries) profileLine
			Duplicate/FREE profileLine, result

			CHECK_EQUAL_WAVES(profileLine, refDataPulseIndex, mode = WAVE_DATA, tol = numEntries)
		endfor
	endfor
End

#endif
