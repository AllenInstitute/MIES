#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

#include "MIES_Include"

static Function/S GetSavePath()

	string folder, pathName

	folder = GetFolder(FunctionPath("")) + "ScreenShots"
	CreateFolderOnDisk(folder)
	pathName = GetUniqueSymbolicPath()
	NewPath/O/Q $pathName, folder

	return pathName
End

Function run()

	// the created graph needs some manual adaptation
	// and the colors are not likely to change in this millenia
	// CreateRelevantColorsGraph()

	ScreenShotsForDataBrowser()
//
//	ScreenShotsForAnalysisBrowser()

//	ScreenShotsForWaveBuilder()

//	ScreenShotsForDAEphys()
End

Function RestrictScreenshotToControl(string path, string filename, string panel, string control)

	// cut out the tab control
	ImageLoad/O/N=image/P=$path filename
	WAVE/Z image = $StringFromList(0, S_waveNames)
	ASSERT(WaveExists(image), "Could not load image")
	ControlInfo/W=$panel $control
	ASSERT(V_flag != 0, "Missing control")
	Duplicate/FREE/RMD=[V_left, V_left + V_width][V_top, V_top + V_height][] image, cut
	ImageSave/O/T="png"/P=$path cut as filename
End

static Function ScreenShotsForAnalysisBrowser()

	string path, panel, entry, filename
	variable i

	path = GetSavePath()

	panel = AB_OpenAnalysisBrowser()

	SavePICT/E=-5/P=$path/Win=$panel/SNAP=1/O as "AnalysisBrowser.png"
End

static Function ScreenShotsForWaveBuilder()

	string path, panel, entry, filename
	variable i

	path = GetSavePath()

	panel = WBP_CreateWaveBuilderPanel()
	KillWindow/Z $panel
	panel = WBP_CreateWaveBuilderPanel()

	SavePICT/E=-5/P=$path/Win=$panel/SNAP=1/O as "Wavebuilder.png"

	for(i = 0; i < EPOCH_TYPES_TOTAL_NUMBER; i += 1)
		entry = WB_ToEpochTypeString(i)
		PGC_SetAndActivateControl(panel, "WBP_WaveType", val = i)
		DoUpdate
		sprintf filename, "WaveBuilder-%s.png", entry
		filename = SanitizeFilename(filename)
		SavePICT/E=-5/P=$path/Win=$panel/SNAP=1/O as filename

		RestrictScreenshotToControl(path, filename, panel, "WBP_WaveType")
	endfor

	PGC_SetAndActivateControl(panel, "button_toggle_params")
	SavePICT/E=-5/P=$path/Win=$(panel + "#AnalysisParamGUI")/SNAP=1/O as "Wavebuilder-AnalysisParameterPanel.png"
End

static Function	ScreenShotsForDAEphys()

	string folder, path, entry, filename, panel, scope
	variable i, numEntries

	path = GetSavePath()

	panel = DAP_CreateDAEphysPanel()

	scope = SCOPE_GetPanel(panel)
	KillWindow/Z $scope

	Make/T/FREE tabs = {"Data Acquisition", "DA", "AD", "TTL", "Asynchonous", "Settings", "Hardware"}

	numEntries = DimSize(tabs, ROWS)
	for(i = 0; i < numEntries; i += 1)
		entry = tabs[i]
		PGC_SetAndActivateControl(panel, "ADC", val = i)
		DoUpdate
		sprintf filename, "DAEphys-%s.png", entry
		filename = SanitizeFilename(filename)
		SavePICT/E=-5/P=$path/Win=$panel/SNAP=1/O as filename
	endfor
End

static Function ScreenShotsForDataBrowser()

	string folder, browser, bspanel, pulseTracePlot, pulseImagePlot, pulseImagePlotCS
	string sweepControl, path, entry, filename, settingsHistoryPanel
	variable i, numEntries

	path = GetSavePath()

	browser = "SweepBrowser1"
	ASSERT(WindowExists(browser), "Missing Sweepbrowser")
	HideTools/W=$browser/A

	// apply settings
	bsPanel = BSP_GetPanel(browser)

	Make/T/FREE tabs = {"Settings", "Overlay-Sweeps", "ChannelSelection", "Artefact-Removal", "PA-plot", "Sweepformula", "Note", "Dashboard"}

	numEntries = DimSize(tabs, ROWS)
	for(i = 0; i < numEntries; i += 1)
		entry = tabs[i]
		PGC_SetAndActivateControl(bsPanel, "Settings", val = i)
		DoUpdate
		sprintf filename, "BrowserSettingsPanel-%s.png", entry
		filename = SanitizeFilename(filename)
		SavePICT/E=-5/P=$path/Win=$bsPanel/SNAP=1/O as filename
	endfor

	// PA graphs
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_PA", val = 1)
	PGC_SetAndActivateControl(bsPanel, "check_pulseAver_searchFailedPulses", val = 0)
	PGC_SetAndActivateControl(bsPanel, "check_pulseAver_deconv", val = 0)

	PGC_SetAndActivateControl(bsPanel, "check_pulseAver_ShowImage", val = 1)
	PGC_SetAndActivateControl(bsPanel, "check_pulseAver_showTraces", val = 1)

	DoUpdate

	// Experiment X2020_06_24_151931_compressed.nwb
	// Sweeps: 37-53 dropping HS2 of 48 and 49
	pulseTracePlot = browser + "_PulseAverage_traces"
	pulseImagePlot = browser + "_PulseAverage_images"
	pulseImagePlotCS = pulseImagePlot + "#P0#G0"

	SavePICT/TRAN=0/B=(2*72)/E=-5/P=$path/Win=$pulseImagePlot/O as "PulseAverage_images.png"
	SavePICT/TRAN=0/B=(2*72)/E=-5/P=$path/Win=$pulseImagePlotCS/O as "PulseAverage_images_colorscales.png"
	SavePICT/TRAN=0/B=(2*72)/E=-5/P=$path/Win=$pulseTracePlot/O as "PulseAverage_traces.png"

	SavePICT/TRAN=0/B=(2*72)/E=-5/P=$path/Win=$pulseTracePlot/O as "PulseAverage_traces.png"

	SavePICT/TRAN=0/B=(2*72)/E=-5/P=$path/Win=RelevantColors/O as "RelevantColors.png"

	browser = "DB_ITC1600_Dev_0"

	DoUpdate
	SavePICT/E=-5/P=$path/Win=$browser/SNAP=1/O as "Browser-Graph.png"

	sweepControl = BSP_GetSweepControlsPanel(browser)
	DoUpdate
	SavePICT/E=-5/P=$path/Win=$sweepControl/SNAP=1/O as "Browser-SweepControl.png"

	settingsHistoryPanel = DB_GetSettingsHistoryPanel(browser)

	PGC_SetAndActivateControl(settingsHistoryPanel, "button_clearlabnotebookgraph")

	STRUCT WMPopupAction pa
	pa.win = settingsHistoryPanel
	pa.eventCode = 2

	pa.popStr = "Stim Scale Factor"
	DB_PopMenuProc_LabNotebook(pa)

	DoUpdate
	SavePICT/E=-5/P=$path/Win=$settingsHistoryPanel/SNAP=1/O as "Browser-SettingsHistory.png"

	AssembleOneDataBrowserImage(path)
End

Function AssembleOneDataBrowserImage(string path)

	variable firstRow, lastRow, firstCol, lastCol
	variable numRows, numCols

	// assemble one image with all external subwindows combined
	ImageLoad/O/N=settingsPic/P=$path "BrowserSettingsPanel-Settings.png"
	ImageLoad/O/N=graphPic/P=$path "Browser-Graph.png"
	ImageLoad/O/N=sweepControlPic/P=$path "Browser-SweepControl.png"
	ImageLoad/O/N=settingsHistoryPic/P=$path "Browser-SettingsHistory.png"

	WAVE settingsPic, graphPic, sweepControlPic, settingsHistoryPic
	Duplicate/O settingsPic, total

	numRows = DimSize(settingsPic, ROWS) + max(DimSize(graphPic, ROWS), DimSize(settingsHistoryPic, ROWS), DimSize(settingsHistoryPic, ROWS))
	numCols = DimSize(graphPic, COLS) + DimSize(sweepControlPic, COLS) + DimSize(settingsHistoryPic, COLS)
	Redimension/N=(numRows, numCols, -1) total
	total[][][] = NaN

	firstRow = 0
	lastRow  = firstRow + DimSize(settingsPic, ROWS) - 1
	firstCol = 0
	lastCol  = firstCol + DimSize(settingsPic, COLS) - 1
	total[firstRow, lastRow][firstCol, lastCol][] = settingsPic[p - firstRow][q - firstCol][r]

	firstRow = DimSize(settingsPic, ROWS)
	lastRow  = firstRow +  + DimSize(graphPic, ROWS) - 1
	firstCol = 0
	lastCol  = firstCol + DimSize(graphPic, COLS) - 1

	total[firstRow, lastRow][firstCol, lastCol][] = graphPic[p - firstRow][q - firstCol][r]

	firstRow = DimSize(settingsPic, ROWS)
	lastRow  = firstRow +  + DimSize(sweepControlPic, ROWS) - 1
	firstCol = DimSize(graphPic, COLS)
	lastCol  = firstCol + DimSize(sweepControlPic, COLS) - 1

	total[firstRow, lastRow][firstCol, lastCol][] = sweepControlPic[p - firstRow][q - firstCol][r]

	firstRow = DimSize(settingsPic, ROWS)
	lastRow  = firstRow + DimSize(settingsHistoryPic, ROWS) - 1
	firstCol = DimSize(graphPic, COLS) + DimSize(sweepControlPic, COLS)
	lastCol  = firstCol + DimSize(settingsHistoryPic, COLS) - 1

	total[firstRow, lastRow][firstCol, lastCol][] = settingsHistoryPic[p - firstRow][q - firstCol][r]

	ImageSave/O/T="png"/P=$path total as "Browser-all.png"
End

Function CreateRelevantColorsGraph()

	string str, contents, graph
	variable i, j

	STRUCT RGBColor s
	contents = "\\F'Arial'\\f01"
	Display
	graph = S_name

	// headstage colors
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		//[s] = GetHeadstageColor(i)
		sprintf str, "\\K(%d, %d , %d) Headstage %d\r", s.red, s.green, s.blue, i
		contents += str
	endfor

	contents += "\rTTL colors\r"

	for(i = 0; i < 2; i += 1)
		sprintf str, "\\K(0, 0, 0)Rack %s\r", SelectString(i, "Zero", "One")
		contents += str

		[s] = GetHeadstageColor(NaN, channelType = "TTL", activeChannelCount=i)
		sprintf str, "\\K(%d, %d , %d) Sum\r", s.red, s.green, s.blue
		contents += str
		for(j = 0; j < 4; j += 1)
			[s] = GetHeadstageColor(NaN, channelType = "TTL", activeChannelCount=i, channelSubNumber = j + 1)
			sprintf str, "\\K(%d, %d , %d) Single\r", s.red, s.green, s.blue
			contents += str

		endfor
	endfor

	Textbox/W=$graph contents
End
