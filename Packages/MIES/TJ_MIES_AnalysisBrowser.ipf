#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_AnalysisBrowser.ipf
/// This file holds the main analysis browser code and has no dependencies on any hardware related functions

// stock igor
#include <Resize Controls>

// third party includes
#include ":ACL_TabUtilities"
#include ":ACL_UserdataEditor"
#include ":FixScrolling"

// our includes
#include ":TJ_MIES_Constants"
#include ":TJ_MIES_Debugging"
#include ":TJ_MIES_GlobalStringAndVariableAccess"
#include ":TJ_MIES_GuiUtilities"
#include ":TJ_MIES_MiesUtilities"
#include ":TJ_MIES_Utilities"
#include ":TJ_MIES_WaveDataFolderGetters"

#include ":TJ_MIES_AnalysisBrowser_LabNotebookTPStorageBrowser"
#include ":TJ_MIES_AnalysisBrowser_SweepBrowser"

static Constant EXPERIMENT_TREEVIEW_COLUMN = 0
static Constant DEVICE_TREEVIEW_COLUMN     = 2

Menu "Mies Panels"
	"Experiment Browser", AB_OpenExperimentBrowser()
	"Labnotebook Browser", LBN_OpenLabnotebookBrowser()
End

static Function AB_ResetSelectionWave()

	variable col, val
	val = LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED

	WAVE expBrowserSel    = GetExperimentBrowserGUISel()
	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	expBrowserSel = 0

	col = FindDimLabel(expBrowserList, COLS, "experiment")
	ASSERT(col >= 0, "invalid column index")
	expBrowserSel[][col - 1] = !cmpstr(expBrowserList[p][col], "") ? 0 : val

	col = FindDimLabel(expBrowserList, COLS, "device")
	ASSERT(col >= 0, "invalid column index")
	expBrowserSel[][col - 1] = !cmpstr(expBrowserList[p][col], "") ? 0 : val
End

/// @brief Clear all waves of the main experiment browser
static Function AB_ClearWaves()

	WAVE/T experimentMap = GetExperimentMap()
	experimentMap = ""
	SetNumberInWaveNote(experimentMap, NOTE_INDEX, 0)

	WAVE/T list = GetExperimentBrowserGUIList()
	list = ""
	SetNumberInWaveNote(list, NOTE_INDEX, 0)

	WAVE sel = GetExperimentBrowserGUISel()
	sel = NaN
End

static Function/S AB_DeriveExperimentFolder(expFilePath)
	string expFilePath

	string fileNameWOExtension

	DFREF anaDFR = GetAnalysisFolder()

	fileNameWOExtension = GetBaseName(expFilePath)
	return CleanupName(fileNameWOExtension, 0)
End

static Function AB_AddExperimentMapEntry(expFilePath)
	string expFilePath

	variable index
	string fileName, expFolderName
	WAVE/T experimentMap = GetExperimentMap()

	index = GetNumberFromWaveNote(experimentMap, NOTE_INDEX)

	EnsureLargeEnoughWave(experimentMap, minimumSize=index, dimension=ROWS)
	experimentMap[index][%ExperimentDiscLocation] = expFilePath

	fileName = ParseFilePath(0, expFilePath, ":", 1, 0)
	experimentMap[index][%ExperimentName] = fileName

	expFolderName = AB_DeriveExperimentFolder(expFilePath)
	experimentMap[index][%ExperimentFolder] = expFolderName

	index += 1
	SetNumberInWaveNote(experimentMap, NOTE_INDEX, index)

	return index - 1
End

static Function AB_AddExperimentFile(expFilePath)
	string expFilePath

	variable mapIndex
	variable firstMapped, lastMapped

	WAVE/T list = GetExperimentBrowserGUIList()

	mapIndex = AB_AddExperimentMapEntry(expFilePath)

	firstMapped = GetNumberFromWaveNote(list, NOTE_INDEX)
	AB_LoadLabNotebookFromFile(expFilePath)
	lastMapped = GetNumberFromWaveNote(list, NOTE_INDEX) - 1

	if(lastMapped > firstMapped)
		list[firstMapped, lastMapped][%experiment][1] = num2str(mapIndex)
	endif
End

static Function/S AB_GetSettingNumFiniteVals(wv, device, sweepNo, name)
	Wave wv
	variable sweepNo
	string name, device

	variable numRows

	WAVE/Z settings = GetLastSetting(wv, sweepNo, name)
	if(!WaveExists(settings))
		printf "Could not query the labnotebook of device %s for the setting %s\r", device, name
		return "unknown"
	else
		WaveStats/Q/M=1 settings
		return num2str(V_npnts)
	endif
End

static Function AB_FillListWave(expFolder, expName, device)
	string expFolder, expName, device

	variable index, numWaves, i, j, sweepNo, numRows, numCols, setCount

	string str, name, listOfSweepConfigWaves

	DFREF expDataDFR = GetAnalysisDeviceConfigFolder(expFolder, device)
	DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)
	WAVE/SDFR=dfr numericValues, textValues
	WAVE/T list = GetExperimentBrowserGUIList()

	index = GetNumberFromWaveNote(list, NOTE_INDEX)
	EnsureLargeEnoughWave(list, minimumSize=index, dimension=ROWS)
	list[index][%experiment][0] = expName
	index += 1

	EnsureLargeEnoughWave(list, minimumSize=index, dimension=ROWS)
	list[index][%device][0] = device

	listOfSweepConfigWaves = SortList(GetListOfWaves(expDataDFR, ".*"), ";", 16)
	numWaves = ItemsInList(listOfSweepConfigWaves)

	list[index][%'#sweeps'][0] = num2istr(numWaves)
	index += 1

	for(i = 0; i < numWaves; i += 1)
		name = StringFromList(i, listOfSweepConfigWaves)
		EnsureLargeEnoughWave(list, minimumSize=index, dimension=ROWS)

		sscanf name, "Config_Sweep_%d" , sweepNo
		ASSERT(V_flag == 1, "Mismatched sscanf invocation")

		list[index][%sweep][0] = num2str(sweepNo)

		str = AB_GetSettingNumFiniteVals(numericValues, device, sweepNo, "DAC")
		list[index][%'#DAC'][0] = str

		str = AB_GetSettingNumFiniteVals(numericValues, device, sweepNo, "ADC")
		list[index][%'#ADC'][0] = str

		WAVE/Z settings = GetLastSetting(numericValues, sweepNo, "Headstage Active")
		numRows = WaveExists(settings) ? DimSize(settings, ROWS) : 0
		if(numRows > 0)
			list[index][%'#headstages'][0] = num2str(Sum(settings))
		else
			list[index][%'#headstages'][0] = "unknown"
		endif

		WAVE/T/Z settingsText = GetLastSettingText(textValues, sweepNo, "Stim Wave Name")
		numRows = WaveExists(settingsText) ? DimSize(settingsText, ROWS) : 0

		if(!numRows)
			list[index][%'stim sets'][0] = "unknown"
			list[index][%'set count'][0] = "-"
			index += 1
		else
			for(j = 0; j < numRows; j += 1)
				str = settingsText[j]

				if(isEmpty(str))
					continue
				endif

				EnsureLargeEnoughWave(list, minimumSize=index, dimension=ROWS)
				list[index][%'stim sets'][0] = str

				WAVE/Z settings = GetLastSetting(numericValues, sweepNo, "Set Sweep Count")
				numRows = WaveExists(settings) ? DimSize(settings, ROWS) : 0
				if(numRows > 0)
					setCount = settings[j]

					if(setCount == 0)
						list[index][%'set count'][0] = "-"
					else
						// start showing the set count if we only have more than one set
						if(setCount == 1)
							list[index - 1][%'set count'][0] = "0"
						endif

						list[index][%'set count'][0] = num2istr(settings[j])
					endif
				else
					list[index][%'set count'][0] = "-"
				endif

				index += 1
			endfor
		endif
	endfor

	SetNumberInWaveNote(list, NOTE_INDEX, index)
End

/// @brief Load waves from a packed/unpacked experiment file
///
/// This function is special as it does change the CDF!
///
/// @param tmpDFR		  Temporary work folder, function returns with that folder as CDF
/// @param expFilePath    full path to the experiment file on disc
/// @param datafolderPath igor datafolder to look for the waves inside the experiment
/// @param listOfWaves    list of waves to load
///
/// @returns number of loaded waves
static Function AB_LoadDataWrapper(tmpDFR, expFilePath, datafolderPath, listOfWaves)
	DFREF tmpDFR
	string expFilePath, datafolderPath, listOfWaves

	variable err
	string cdf, fileNameWOExtension, baseFolder, extension, expFileOrFolder

	ASSERT(DataFolderExistsDFR(tmpDFR), "tmpDFR does not exist")
	ASSERT(!isEmpty(expFilePath), "empty path")
	ASSERT(!isEmpty(dataFolderPath), "empty datafolder path")
	ASSERT(strlen(listOfWaves) < 1000, "LoadData limit for listOfWaves length reached")

	fileNameWOExtension = GetBaseName(expFilePath)
	baseFolder          = ParseFilePath(1, expFilePath, ":", 1, 0)
	extension           = ParseFilePath(4, expFilePath, ":", 1, 0)

	/// @todo this is not 100% correct as users might choose a different name for the unpacked experiment folder
	if(!cmpstr(extension, "uxp"))
		expFileOrFolder = baseFolder + fileNameWOExtension  + " Folder"
	else
		expFileOrFolder = expFilePath
	endif

	// LoadData does not accept the root: prefix, as that might be already a subfolder
	dataFolderPath = RemovePrefix(dataFolderPath, startStr = "root:")
	SetDataFolder tmpDFR

	// also with "/Q" LoadData still complains if the subfolder path does not exist
	try
		GetFileFolderInfo/Q/Z expFileOrFolder
		if(V_isFile)
			LoadData/Q/R/L=1/S=dataFolderPath/J=listOfWaves/O=1 expFileOrFolder; AbortOnRTE
		elseif(V_isFolder)
			LoadData/Q/D/R/L=1/J=listOfWaves/O=1 expFileOrFolder + ":" + dataFolderPath; AbortOnRTE
		else
			ASSERT(0, "Unknown return from GetFileFolderInfo")
			return 0
		endif
	catch
		err = GetRTError(1)
		printf "Could not query the waves from %s\r", expFileOrFolder
		return 0
	endtry

	return V_flag
End

/// @brief Returns the highest referenced sweep number from the labnotebook
static Function GetHighestPossibleSweepNumber(numericValues)
	WAVE numericValues

	variable sweepCol = GetSweepColumn(numericValues)
	MatrixOP/FREE sweepNums = col(numericValues, sweepCol)
	WaveStats/M=1/Q sweepNums

	return V_max
End

static Function/S AB_LoadLabNotebookFromFile(expFilePath)
	string expFilePath

	string labNotebookWaves, labNotebookPath, type, number, path, basepath, device, cdf, str
	string expName, expFolder
	string deviceList = ""
	variable numDevices, numTypes, i, j, err, numWavesLoaded, highestSweepNumber

	WAVE/T experimentMap = GetExperimentMap()

	FindValue/TXOP=4/TEXT=(expFilePath) experimentMap
	ASSERT(V_Value >= 0, "invalid index")
	expName   = experimentMap[V_Value][%ExperimentName]
	expFolder = experimentMap[V_Value][%ExperimentFolder]

	labNotebookWaves = "settingsHistory;keyWave;txtDocWave;txtDocKeyWave"
	labNotebookPath  = GetLabNotebookFolderAsString()
	DFREF saveDFR = GetDataFolderDFR()
	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")
	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, labNotebookPath, labNotebookWaves)

	if(numWavesLoaded <= 0)
		return ""
	endif

	cdf = GetDataFolder(1)

	numDevices = ItemsInList(DEVICE_NUMBERS)
	numTypes   = ItemsInList(DEVICE_TYPES)

	for(i = 0; i < numTypes; i += 1)
		type = StringFromList(i, DEVICE_TYPES)
		path = cdf + type

		if(!DataFolderExists(path))
			continue
		endif

		for(j = 0; j < numDevices; j += 1)
			number = StringFromList(j, DEVICE_NUMBERS)
			path = cdf + type + ":Device" + number

			if(!DataFolderExists(path))
				continue
			endif

			basepath = path + ":KeyWave"
			Wave/Z/SDFR=$basepath keyWave

			basepath = path + ":settingsHistory"
			Wave/Z/SDFR=$basepath settingsHistory

			basepath = path + ":TextDocKeyWave"
			Wave/Z/SDFR=$basepath txtDocKeyWave

			basepath = path + ":textDocumentation"
			Wave/Z/SDFR=$basepath txtDocWave

			device = BuildDeviceString(type, number)

			if(!WaveExists(keyWave) || !WaveExists(settingsHistory) || !WaveExists(txtDocKeyWave) || !WaveExists(txtDocWave))
				printf "Could not find all four labnotebook waves, dropping all data from device %s\r", device
				continue
			endif

			DEBUGPRINT("Found labnotebook for device: ", str=device)

			deviceList = AddListItem(device, deviceList, ";", inf)

			DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)

			Duplicate/O keyWave, dfr:numericKeys/Wave=numericKeys
			Duplicate/O settingsHistory, dfr:numericValues/Wave=numericValues
			Duplicate/O txtDocKeyWave, dfr:textKeys/Wave=textKeys
			Duplicate/O txtDocWave, dfr:textValues/Wave=textValues

			// add some forgotten dimension labels in older versions of MIES
			// and overwrite invalid dim labels (labnotebook waves created with versions prior to a8f0f43)
			str = GetDimLabel(textValues, COLS, 0)
			if(isEmpty(str) || !cmpstr(str, "dimLabelText"))
				SetDimensionLabels(textKeys, textValues)
			endif

			str = GetDimLabel(numericKeys, COLS, 0)
			if(isEmpty(str) || !cmpstr(str, "dimLabelText"))
				SetDimensionLabels(numericKeys, numericValues)
			endif

			highestSweepNumber = GetHighestPossibleSweepNumber(numericValues)

			AB_LoadSweepConfigData(expFilePath, expFolder, device, highestSweepNumber)
			AB_FillListWave(expFolder, expName, device)
		endfor
	endfor

	SetDataFolder saveDFR
	KillDataFolder newDFR

	return deviceList
End

static Constant LOAD_CONFIG_CHUNK_SIZE = 50

/// @brief Load all `Config_Sweep_*` waves from the given experiment file or folder and the given device
///
/// The implementation here tries to load `LOAD_CONFIG_CHUNK_SIZE` number of config sweep waves at a time
/// until there could not be loaded at least one config sweep wave and we have reached highestSweepNumber.
///
/// The size of `LOAD_CONFIG_CHUNK_SIZE` is limited by a limitation of LoadData as this operations accepts
/// only a stringlist of waves shorter than 400 characters.
static Function AB_LoadSweepConfigData(expFilePath, expFolder, device, highestSweepNumber)
	string expFilePath, expFolder, device
	variable highestSweepNumber

	string dataFolderPath, listOfWaves
	variable numWavesLoaded, totalNumWavesLoaded
	variable start, step, stop, i

	DFREF targetDFR = GetAnalysisDeviceConfigFolder(expFolder, device)
	dataFolderPath = GetDeviceDataPathAsString(device)
	DFREF saveDFR = GetDataFolderDFR()

	step  = 1
	for(i = 0;; i += 1)
		start = i * LOAD_CONFIG_CHUNK_SIZE
		stop  = (i + 1) * LOAD_CONFIG_CHUNK_SIZE

		listOfWaves = BuildList("Config_Sweep_%d", start, step, stop)
		numWavesLoaded = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, listOfWaves)

		if(numWavesLoaded <= 0 && stop >= highestSweepNumber)
			break
		endif

		totalNumWavesLoaded += numWavesLoaded
	endfor

	SetDataFolder saveDFR
	return totalNumWavesLoaded
End

/// @brief Expand all tree views in the given column
static Function AB_ExpandListColumn(col)
	variable col

	variable numRows, row, i, mask

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	WAVE selBits = AB_ReturnAndClearGUISelBits()
	WAVE/Z indizes = FindIndizes(wv=expBrowserSel, col=col, var=LISTBOX_TREEVIEW)
	AB_SetGUISelBits(selBits)

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)
	for(i = numRows - 1; i >= 0; i -= 1)

		row = indizes[i]
		mask = expBrowserSel[row][col]
		if(mask & LISTBOX_TREEVIEW_EXPANDED)
			continue
		endif

		AB_ExpandListEntry(row, col)
		expBrowserSel[row][col] = SetBit(mask, LISTBOX_TREEVIEW_EXPANDED)
	endfor
End

/// @brief Collapse all tree views in the given column
static Function AB_CollapseListColumn(col)
	variable col

	variable numRows, row, i, mask

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	WAVE selBits = AB_ReturnAndClearGUISelBits()
	WAVE/Z indizes = FindIndizes(wv=expBrowserSel, col=col, var=LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED)
	AB_SetGUISelBits(selBits)

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)
	for(i = numRows - 1; i >= 0; i -= 1)

		row = indizes[i]
		mask = expBrowserSel[row][col]
		if(mask & LISTBOX_TREEVIEW_EXPANDED)
			AB_CollapseListEntry(row, col)
			expBrowserSel[row][col] = ClearBit(mask, LISTBOX_TREEVIEW_EXPANDED)
		endif
	endfor
End

/// @brief Set the selection bits of the experiment browser ListBox selection wave
///
/// @param selBits wave returned by AB_ReturnAndClearGUISelBits
static Function AB_SetGUISelBits(selBits)
	WAVE selBits

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[][0] = expBrowserSel[p][0] | selBits[p]
End

/// @brief Return the selection bits from the experiment browser ListBox selection wave and clear them
static Function/Wave AB_ReturnAndClearGUISelBits()

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	Make/FREE/N=(DimSize(expBrowserSel, ROWS)) selBits = expBrowserSel[p][0] & LISTBOX_SELECTED
	expBrowserSel[][0] = expBrowserSel[p][0] & ~LISTBOX_SELECTED

	return selBits
End

/// @brief Collapse the given treeview
Function AB_CollapseListEntry(row, col)
	variable row, col

	variable mask, last, length
	string str

	WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
	WAVE expBrowserSel       = GetExperimentBrowserGUISel()
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
	WAVE expBrowserSelBak    = CreateBackupWave(expBrowserSel)

	mask = expBrowserSel[row][col]
	ASSERT(mask & LISTBOX_TREEVIEW && mask & LISTBOX_TREEVIEW_EXPANDED, "listbox entry is not a treeview expansion node or is already collapsed")

	// contract the list by deleting all rows between the current one
	// and one before the next one which has a tree view icon in the same column or lower columns
	last  = AB_GetRowWithNextTreeView(expBrowserSel, row, col)
	last -= 1

	row += 1
	length = last - row + 1

	sprintf str, "range=[%d, %d], length=%d", row, last, length
	DEBUGPRINT("contract listbox:", str=str)

	DeletePoints/M=(ROWS) row, length, expBrowserList, expBrowserSel
End

/// @brief Expand the given treeview
Function AB_ExpandListEntry(row, col)
	variable row, col

	variable mask, last, length, sourceRow, targetRow
	string str

	WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
	WAVE expBrowserSel       = GetExperimentBrowserGUISel()
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
	WAVE expBrowserSelBak    = CreateBackupWave(expBrowserSel)

	mask = expBrowserSel[row][col]
	ASSERT(mask & LISTBOX_TREEVIEW && !(mask & LISTBOX_TREEVIEW_EXPANDED) , "listbox entry is not a treeview expansion node or already expanded")

	// expand the list
	// - search the backup wave for the row index (sourceRow) with the same contents as row for the contracted list
	// - search the next tree view icon in the same or lower columns in the backup selection wave
	// - calculate the required new rows and insert them
	// - copy the contents from the backup waves
	targetRow = row + 1
	sourceRow = GetRowWithSameContent(expBrowserListBak, expBrowserList, row)

	last = AB_GetRowWithNextTreeView(expBrowserSelBak, sourceRow, col)
	last -= 1

	sourceRow += 1
	length = last - sourceRow + 1

	sprintf str, "sourceRow=%d, targetRow=%d, last=%d", sourceRow, targetRow, last
	DEBUGPRINT("expand listbox:", str=str)

	InsertPoints/M=(ROWS) targetRow, length, expBrowserList, expBrowserSel
	expBrowserList[targetRow, targetRow + length - 1][][] = expBrowserListBak[sourceRow - targetRow + p][q][r]
	expBrowserSel[targetRow, targetRow + length - 1][]    = expBrowserSelBak[sourceRow - targetRow + p][q]
End

/// @returns 0 if at least one sweep could be loaded, 1 otherwise
static Function AB_LoadSweepsFromExpandedRange(sweepBrowser, row, subSectionColumn)
	DFREF sweepBrowser
	variable row, subSectionColumn

	variable j, endRow, mapIndex, ret, sweep, oneValidSweep
	string device, expFolder, expFilePath, expName

	WAVE expBrowserSel    = GetExperimentBrowserGUISel()
	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	WAVE/T experimentMap  = GetExperimentMap()

	ASSERT(subSectionColumn == EXPERIMENT_TREEVIEW_COLUMN || subSectionColumn == DEVICE_TREEVIEW_COLUMN, "Invalid subsection column")
	if(!(expBrowserSel[row][subSectionColumn] & LISTBOX_TREEVIEW))
		// entry is not a tree view
		return 1
	endif

	endRow = AB_GetRowWithNextTreeView(expBrowserSel, row, subSectionColumn)

	for(j = row; j < endRow; j += 1)
		if(expBrowserSel[j][0] & LISTBOX_TREEVIEW || expBrowserSel[j][2] & LISTBOX_TREEVIEW)
			// ignore rows with tree view icons, we have them already in our list
			continue
		endif

		sweep = str2num(expBrowserList[j][%sweep])

		// sweeps with multiple DA channels occupy multiple rows,
		// ignore them as they all stem from the same sweep
		if(!IsFinite(sweep))
			continue
		endif

		device      = GetLastNonEmptyEntry(expBrowserList, "device", j)
		mapIndex    = str2num(expBrowserList[j][%experiment][1])
		expName     = experimentMap[mapIndex][%ExperimentName]
		expFolder   = experimentMap[mapIndex][%ExperimentFolder]
		expFilePath = experimentMap[mapIndex][%ExperimentDiscLocation]

		if(AB_LoadSweepAndRelated(expFilePath, expFolder, device, sweep) == 1)
			continue
		endif

		oneValidSweep = 1
		SB_AddToSweepBrowser(sweepBrowser, expName, expFolder, device, sweep)
	endfor

	if(oneValidSweep)
		return 0
	else
		return 1
	endif
End

/// @brief Return the row with treeview in the column col starting from startRow
static Function AB_GetRowWithNextTreeView(selWave, startRow, col)
	Wave selWave
	variable startRow, col

	variable numRows, i
	Make/FREE/N=(DimSize(selWave, COLS)) status

	numRows = DimSize(selWave, ROWS)
	for(i = startRow + 1; i < numRows; i += 1)
		status[] = (selWave[i][p] & LISTBOX_TREEVIEW ? 1 : 0)

		if(Sum(status, 0, col) > 0)
			return i
		endif
	endfor

	return numRows
End

/// @returns 0 if the sweeps could be loaded, or already exists, and 1 on error
Function AB_LoadSweepAndRelated(expFilePath, expFolder, device, sweep)
	string expFilePath, expFolder, device
	variable sweep

	variable numWavesLoaded
	string sweepWaveName, dataPath, sweepFolder, msg
	sweepWaveName = "sweep_" + num2str(sweep)

	ASSERT(!isEmpty(expFilePath), "Empty expFileOrFolder")
	ASSERT(!isEmpty(expFolder), "Empty expFolder")
	ASSERT(!isEmpty(device), "Empty device")
	ASSERT(isFinite(sweep), "Non-finite sweep")

	sweepFolder = GetAnalysisSweepDataPathAS(expFolder, device, sweep)

	// sweep already loaded
	if(DataFolderExists(sweepFolder))
		return 0
	endif

	dataPath = GetDeviceDataPathAsString(device)
	DFREF saveDFR = GetDataFolderDFR()
	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")
	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataPath, sweepWaveName)

	if(numWavesLoaded <= 0)
		printf "Could not load sweep %d of device %s and %s\r", sweep, device, expFilePath
		SetDataFolder saveDFR
		KillDataFolder newDFR
		return 1
	endif

	Wave sweepWave = $sweepWaveName
	DFREF sweepDataDFR = createDFWithAllParents(sweepFolder)
	MoveWave sweepWave, sweepDataDFR
	SetDataFolder saveDFR
	KillDataFolder newDFR

	sprintf msg, "Loaded sweep %d of device %s and %s\r", sweep, device, expFilePath
	DEBUGPRINT(msg)

	if(AB_SplitSweepIntoComponents(expFolder, device, sweep, sweepWave))
		KillDataFolder sweepDataDFR
		return 1
	endif

	if(AB_LoadStimSet(expFilePath, expFolder, device, sweep))
		return 1
	endif

	return 0
End

/// @brief Load the stim set for the given sweep
///
/// @returns 1 on error, 0 otherwise
static Function AB_LoadStimSet(expFilePath, expFolder, device, sweep)
	string expFilePath, expFolder, device
	variable sweep

	variable numWavesLoaded, numEntries, i
	string dataPath, stimsetWaveName, msg

	DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)
	DFREF stimsetdfr = GetAnalysisStimSetPath(expFolder, device)

	WAVE/SDFR=dfr textValues

	WAVE/T/Z settings = GetLastSettingText(textValues, sweep, "Stim Wave Name")

	if(!WaveExists(settings))
		printf "Could not find the stim sets in the labnotebook of %s with device %s and sweep %d\r", expFolder, device, sweep
		return 1
	endif

	numEntries = DimSize(settings, ROWS)
	for(i = 0; i < numEntries; i += 1)

		stimsetWaveName = settings[i]
		if(isEmpty(stimsetWaveName))
			continue
		endif

		WAVE/Z/SDFR=stimsetdfr stimset = $stimsetWaveName

		if(WaveExists(stimset))
			continue
		endif

		dataPath = GetWBSvdStimSetDAPathAsString()
		DFREF saveDFR = GetDataFolderDFR()
		DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")
		numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataPath, stimsetWaveName)

		if(numWavesLoaded <= 0)
			printf "Could not load stimset %s of sweep %d, device %s and %s\r", stimsetWaveName, sweep, device, expFilePath
			SetDataFolder saveDFR
			KillDataFolder newDFR
			return 1
		endif

		WAVE stimset = $stimsetWaveName
		MoveWave stimset, stimsetdfr
		SetDataFolder saveDFR
		KillDataFolder newDFR

		sprintf msg, "Loaded stimset %s of sweep %d, device %s and %s\r", stimsetWaveName, sweep, device, expFilePath
		DEBUGPRINT(msg)
	endfor

	return 0
End

static Function AB_SplitSweepIntoComponents(expFolder, device, sweep, sweepWave)
	string expFolder, device
	variable sweep
	Wave sweepWave

	variable numRows, i, channelNumber
	string channelType, str, channelUnit

	DFREF sweepFolder = GetAnalysisSweepDataPath(expFolder, device, sweep)
	Wave config = GetAnalysisConfigWave(expFolder, device, sweep)
	if(DimSize(config, ROWS) != DimSize(sweepWave, COLS))
		printf "The sweep %d of device %s in experiment %s does not match its configuration data. Therefore we ignore it.\r", sweep, device, expFolder
		return 1
	endif

	numRows = DimSize(config, ROWS)
	for(i = 0; i < numRows; i += 1)
		channelType   = StringFromList(config[i][0], ITC_CHANNEL_NAMES)
		ASSERT(!isEmpty(channelType), "empty channel type")
		channelNumber = config[i][1]
		ASSERT(IsFinite(channelNumber), "non-finite channel number")
		str = channelType + "_" + num2istr(channelNumber)

		MatrixOP sweepFolder:$str = col(sweepWave, i)

		Wave/SDFR=sweepFolder data = $str
		SetScale/P x, DimOffset(sweepWave, ROWS), DimDelta(sweepWave, ROWS), WaveUnits(sweepWave, ROWS), data
		channelUnit = StringFromList(i, note(config))
		SetScale d, 0, 0, channelUnit, data
	endfor

	string/G sweepFolder:note = note(sweepWave)
	KillWaves sweepWave

	return 0
End

Function AB_OpenExperimentBrowser()

	string panel = "ExperimentBrowser"

	if(windowExists(panel))
		DoWindow/F $panel
		return NaN
	endif

	WAVE/T list = GetExperimentBrowserGUIList()
	list = ""
	WAVE   sel  = GetExperimentBrowserGUISel()
	sel = 0

	Execute "ExperimentBrowser()"
	GetMiesVersion()
End

Window ExperimentBrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(180,275,1057,764)
	ShowTools/A
	Button button_base_folder_scan,pos={6,41},size={100,20},proc=AB_ButtonProc_ScanFolder,title="Scan folder"
	Button button_base_folder_scan,userdata(ResizeControlsInfo)= A"!!,@#!!#>2!!#@,!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_base_folder_scan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_base_folder_scan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_baseFolder,pos={118,17},size={338,16}
	SetVariable setvar_baseFolder,userdata(ResizeControlsInfo)= A"!!,FQ!!#<@!!#Bc!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_baseFolder,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_baseFolder,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_baseFolder,value= _STR:"H:tim-data:Data:",noedit= 1
	ListBox list_experiment_contents,pos={119,44},size={748,429},proc=AB_ListBoxProc_ExpBrowser
	ListBox list_experiment_contents,userdata(ResizeControlsInfo)= A"!!,FS!!#>>!!#D1J,hs7J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_experiment_contents,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_experiment_contents,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_experiment_contents,listWave=root:MIES:analysis:expBrowserList
	ListBox list_experiment_contents,selWave=root:MIES:analysis:expBrowserSel,row= 1
	ListBox list_experiment_contents,mode= 4
	ListBox list_experiment_contents,widths={33,260,24,137,55,45,75,130,45,63}
	ListBox list_experiment_contents,userColumnResize= 1,hScroll= 3
	Button button_select_same_stim_sets,pos={6,67},size={101,33},proc=AB_ButtonProc_SelectStimSets,title="Select same\rstim set sweeps"
	Button button_select_same_stim_sets,userdata(ResizeControlsInfo)= A"!!,@#!!#??!!#@.!!#=gz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_select_same_stim_sets,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_select_same_stim_sets,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_select_directory,pos={6,14},size={100,20},proc=AB_ButtonProc_SelectDirectory,title="Select directory"
	Button button_select_directory,userdata(ResizeControlsInfo)= A"!!,@#!!#;m!!#@,!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_select_directory,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_select_directory,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_collapse_all,pos={8,123},size={98,23},proc=AB_ButtonProc_CollapseAll,title="Collapse all"
	Button button_expand_all,pos={6,157},size={100,19},proc=AB_ButtonProc_ExpandAll,title="Expand all"
	Button button_load_selection,pos={8,190},size={97,25},proc=AB_ButtonProc_LoadSelection,title="Load Selection"
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#DQ^]6a@J,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
EndMacro

Function AB_ButtonProc_ExpandAll(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case 2:
			AB_ExpandListColumn(EXPERIMENT_TREEVIEW_COLUMN)
			AB_ExpandListColumn(DEVICE_TREEVIEW_COLUMN)
			break
	endswitch

	return 0
End

Function AB_ButtonProc_CollapseAll(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2:
			AB_CollapseListColumn(EXPERIMENT_TREEVIEW_COLUMN)
			break
	endswitch

	return 0
End

Function AB_ButtonProc_LoadSelection(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable mapIndex, sweep, numRows, i, row, ret, oneValidSweep
	string expFolder, expName, expFilePath, device

	switch(ba.eventcode)
		case 2:
			WAVE expBrowserSel    = GetExperimentBrowserGUISel()
			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE/T experimentMap  = GetExperimentMap()

			// Our mode for the listbox stores the selection bit only in the first column
			WAVE/Z indizes = FindIndizes(wv=expBrowserSel, col=0, var=1, prop=PROP_MATCHES_VAR_BIT_MASK)

			if(!WaveExists(indizes))
				break
			endif

			DFREF sweepBrowserDFR = SB_CreateNewSweepBrowser()

			// the matches might include rows with devices or experiments only.
			// In that case we load everything from the experiment or device.
			numRows = DimSize(indizes, ROWS)
			for(i = 0; i < numRows; i += 1)
				row = indizes[i]

				if(!AB_LoadSweepsFromExpandedRange(sweepBrowserDFR, row, EXPERIMENT_TREEVIEW_COLUMN))
					oneValidSweep = 1
					continue
				endif

				if(!AB_LoadSweepsFromExpandedRange(sweepBrowserDFR, row, DEVICE_TREEVIEW_COLUMN))
					oneValidSweep = 1
					continue
				endif

				// selection is a plain sweep, the current row either holds the sweep number, or one of the previous ones
				sweep  = str2num(GetLastNonEmptyEntry(expBrowserList, "sweep", row))
				device = GetLastNonEmptyEntry(expBrowserList, "device", row)

				mapIndex    = str2num(expBrowserList[row][%experiment][1])
				expName     = experimentMap[mapIndex][%ExperimentName]
				expFolder   = experimentMap[mapIndex][%ExperimentFolder]
				expFilePath = experimentMap[mapIndex][%ExperimentDiscLocation]

				if(AB_LoadSweepAndRelated(expFilePath, expFolder, device, sweep))
					continue
				endif

				oneValidSweep = 1
				SB_AddToSweepBrowser(sweepBrowserDFR, expName, expFolder, device, sweep)
			endfor

			if(oneValidSweep)
				SB_PlotSweep(sweepBrowserDFR, 0, 0)
			else
				SVAR/SDFR=sweepBrowserDFR graph
				KillWindow $graph
			endif
			break
	endswitch

	return 0
End

Function AB_ButtonProc_ScanFolder(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string baseFolder, path, pxpList, uxpList, list
	variable i, numEntries
	string win

	switch(ba.eventCode)
		case 2: // mouse up
			win = ba.win
			baseFolder = GetSetVariableString(win, "setvar_baseFolder")
			path = UniqueName("scanfolder_path", 12, 1)
			NewPath/Q/Z $path, baseFolder

			if(V_flag != 0)
				printf "Could not create the symbolic path referencing %s, maybe the folder does not exist?\r", baseFolder
				break
			endif

			AB_ClearWaves()

			pxpList = GetFilesRecursively(path, ".pxp")
			uxpList = GetFilesRecursively(path, ".uxp")
			KillPath $path

			list = SortList(pxpList + uxpList)

			numEntries = ItemsInList(list)
			for(i = 0; i < numEntries; i += 1)
				AB_AddExperimentFile(StringFromList(i, list))
			endfor

			WAVE expBrowserList = GetExperimentBrowserGUIList()
			WAVE expBrowserSel  = GetExperimentBrowserGUISel()

			numEntries = GetNumberFromWaveNote(expBrowserList, NOTE_INDEX)
			Redimension/N=(numEntries, -1, -1, -1) expBrowserList, expBrowserSel

			AB_ResetSelectionWave()

			WAVE/T expBrowserSelBak = CreateBackupWave(expBrowserSel, forceCreation=1)
			WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList, forceCreation=1)
		break
	endswitch

	return 0
End

Function AB_ButtonProc_SelectDirectory(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string path
	switch(ba.eventCode)
		case 2: // mouse up
				GetFileFolderInfo/D/Q/Z=2

				if(V_flag == 0 && V_isFolder)
					SetSetVariableString(ba.win, "setvar_baseFolder", S_Path)
				endif
			break
	endswitch

	return 0
End

Function AB_ButtonProc_SelectStimSets(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable numEntries, i
	string selectedStimSet

	switch(ba.eventCode)
		case 2: // mouse up
			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE expBrowserSel    = GetExperimentBrowserGUISel()

			WAVE/Z indizes = FindIndizes(col=0, var=1, wv=expBrowserSel)

			if(!WaveExists(indizes) || DimSize(indizes, ROWS) != 1)
				print "Please select exactly one row to use this feature"
				break
			endif

			selectedStimSet = expBrowserList[indizes[0]][%$"stim sets"]

			if(isEmpty(selectedStimSet))
				print "Can not work with an empty stim set in the selection"
				break
			endif

			WAVE indizes = FindIndizes(colLabel="stim sets", str=selectedStimSet, wvText=expBrowserList)
			expBrowserSel[][] = expBrowserSel[p][q] & ~LISTBOX_SELECTED

			numEntries = DimSize(indizes, ROWS)
			for(i = 0; i < numEntries; i += 1)
				expBrowserSel[indizes[i]][] = expBrowserSel[p][q] | LISTBOX_SELECTED
			endfor

			break
	endswitch

	return 0
End

Function AB_ListBoxProc_ExpBrowser(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	variable mask ,last, length, sourceRow, targetRow, numRows, row, col
	variable i, sweepCol, sweep
	string str, expFolder, device

	switch(lba.eventCode)
		case 1: // mouse down
			row = lba.row
			col = lba.col
			lba.blockreentry = 1

			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE expBrowserSel = GetExperimentBrowserGUISel()
			WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
			WAVE expBrowserSelBak = CreateBackupWave(expBrowserSel)

			numRows = DimSize(expBrowserSel, ROWS)

			if(row < 0 || row >=  numRows || col < 0 || col >= DimSize(expBrowserSel, COLS))
				// clicked outside the list
				break
			endif

			mask = expBrowserSel[row][col]
			if(!(mask & LISTBOX_TREEVIEW)) // clicked cell is not a treeview expansion node
				break
			endif

			if(mask & LISTBOX_TREEVIEW_EXPANDED)
				AB_CollapseListEntry(row, col)
			else
				AB_ExpandListEntry(row, col)
			endif

			break
	endswitch

	return 0
End
