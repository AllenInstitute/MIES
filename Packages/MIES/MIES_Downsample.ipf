#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_DOWN
#endif // AUTOMATED_TESTING

/// @file MIES_Downsample.ipf
/// @brief Panel for downsampling acquired data
///
/// Folders and waves managed by code in this file
/// Object type  |  Name                      | Purpose                                                                | Function
///--------------|----------------------------|------------------------------------------------------------------------|----------
/// DFREF        |  $dataPath                 | location of all the GUI and temporary data                             | GetDownsampleDataFolder()
/// Wave         |  $dataPath:dataRef         | Holds wave references to all waves currently displayed in the list box | GetDownsampleDataRefWave()
/// Wave         |  $dataPath:rateWave        | Holds all rates in kHz for each wave.                                  | GetDownsampleRateWave()
/// Wave         |  $dataPath:sweepProperties | Used by the list box to show the properties of each sweep              | GetDownsampleListWave()

static StrConstant checkbox_equalize      = "checkbox_equalize_id"
static StrConstant checkbox_downsample    = "checkbox_downsample_id"
static StrConstant popup_targetrate       = "popup_targetrate_id"
static StrConstant checkbox_interpolation = "checkbox_interpolation_id"
static StrConstant popup_windowfunction   = "popup_windowfunction_id"
static StrConstant popup_decimationmethod = "popup_decimationmethod_id"
static StrConstant popup_deviceselection  = "popup_deviceselection_id"
static StrConstant checkbox_backupwaves   = "checkbox_backupwaves_id"
static StrConstant valdisp_estimatedsize  = "valdisp_estimatedsize_id"
static StrConstant valdisp_currentsize    = "valdisp_currentsize_id"
static StrConstant listbox_waves          = "listbox_waves_id"
static StrConstant button_doit            = "button_doit_id"
static StrConstant button_restorebackup   = "button_restorebackup_id"

static StrConstant dataPath = "root:MIES:postExperimentProcedures:downsample:"
static StrConstant panel    = "Downsampling"

static Function/DF GetDownsampleDataFolder()

	return createDFWithAllParents(dataPath)
End

static Function/WAVE GetDownsampleDataRefWave()

	DFREF dfr = GetDownsampleDataFolder()
	WAVE/Z/WAVE/SDFR=dfr dataRef

	if(WaveExists(dataRef))
		return dataRef
	endif

	Make/WAVE/N=(0) dfr:dataRef/WAVE=dataRef

	return dataRef
End

static Function/WAVE GetDownsampleRateWave()

	DFREF dfr = GetDownsampleDataFolder()
	WAVE/Z/SDFR=dfr rate

	if(WaveExists(rate))
		return rate
	endif

	Make/N=(0) dfr:rate/WAVE=rate

	return rate
End

static Function/WAVE GetDownsampleListWave()

	DFREF dfr = GetDownsampleDataFolder()
	WAVE/Z/T/SDFR=dfr sweepProperties

	if(WaveExists(sweepProperties))
		return sweepProperties
	endif

	Make/T/N=(0, 3) dfr:sweepProperties/WAVE=sweepProperties

	SetDimLabel COLS, 0, Device, sweepProperties
	SetDimLabel COLS, 1, Name, sweepProperties
	SetDimLabel COLS, 2, $"Rate (kHz)", sweepProperties

	return sweepProperties
End

/// @brief Create a list of all devices with acquired data
///
/// @returns list of all devices with data in the format ITC18USB_Dev_1;ITC1600_Dev_1
Function/S GetPopupMenuDeviceListWithData()

	variable i, j, k
	string path, deviceType, deviceNumber
	string list = ""
	string deviceString

	variable numDeviceTypes = ItemsInList(DEVICE_TYPES_ITC)
	variable numDevices     = ItemsInList(DEVICE_NUMBERS)

	// @todo: Does not know about NI devices and should probably prefer GetAllDevicesWithContent

	for(i = 0; i < numDeviceTypes; i += 1)
		deviceType = StringFromList(i, DEVICE_TYPES_ITC)
		path       = GetDeviceTypePathAsString(deviceType)

		if(!DataFolderExists(path))
			continue
		endif

		for(j = 0; j < numDevices; j += 1)
			deviceNumber = StringFromList(j, DEVICE_NUMBERS)
			deviceString = HW_ITC_BuildDeviceString(deviceType, deviceNumber)
			path         = GetDevicePathAsString(deviceString)

			if(!DataFolderExists(path))
				continue
			endif

			list = AddListItem(deviceString, list, ";", Inf)
		endfor
	endfor

	if(isEmpty(list))
		return "No devices with data found"
	endif

	return list
End

/// @brief Searches for sweep waves from all devices
///
/// @param list		    ListBox wave, see GetDownsampleListWave() for the format
/// @param dataRef	    wave with wave references to all data waves
/// @param rate		    wave with the sampling rates in kHz of all data waves
/// @param startIndex   first unused index into the passed waves
/// @param deviceType   device type
/// @param deviceNumber device number
/// @returns			index of the last valid entry into the passed waves
static Function AppendEntries(WAVE/T list, WAVE/WAVE dataRef, WAVE rate, variable startIndex, string deviceType, string deviceNumber)

	string listOfDataWaves, name
	variable numWaves, i, idx, convrate, samplingInterval
	DFREF deviceDFR = GetDeviceDataPath(HW_ITC_BuildDeviceString(deviceType, deviceNumber))

	listOfDataWaves = GetListOfObjects(deviceDFR, DATA_SWEEP_REGEXP)
	numWaves        = ItemsInList(listOfDataWaves)
	idx             = startIndex

	for(i = 0; i < numWaves; i += 1, idx += 1)
		name = StringFromList(i, listOfDataWaves)
		WAVE/SDFR=deviceDFR wv     = $name
		WAVE                config = GetConfigWave(wv)
		samplingInterval = GetSamplingInterval(config, XOP_CHANNEL_TYPE_ADC)

		EnsureLargeEnoughWave(list, indexShouldExist = idx)
		EnsureLargeEnoughWave(dataRef, indexShouldExist = idx)
		EnsureLargeEnoughWave(rate, indexShouldExist = idx)

		convRate = ConvertSamplingIntervalToRate(samplingInterval)

		dataRef[idx] = wv
		rate[idx]    = convRate
		list[idx][0] = deviceNumber
		list[idx][1] = name
		list[idx][2] = num2str(convRate)
	endfor

	return idx
End

/// @brief Updates all waves holding acquired data info
static Function UpdateDataWaves(string deviceType, string deviceNumber)

	variable i, idx

	WAVE/T    list    = GetDownsampleListWave()
	WAVE/WAVE dataRef = GetDownsampleDataRefWave()
	WAVE      rate    = GetDownsampleRateWave()

	idx = 0
	Redimension/N=(idx, -1) list, dataRef, rate

	idx = AppendEntries(list, dataRef, rate, idx, deviceType, deviceNumber)

	Redimension/N=(idx, -1) list, dataRef, rate
End

static Function UpdateCurrentSize(string win)

	WAVE/WAVE dataRef = GetDownsampleDataRefWave()
	variable i
	variable size     = 0
	variable numWaves = DimSize(dataRef, ROWS)

	for(i = 0; i < numWaves; i += 1)
		size += GetWaveSize(dataRef[i])
	endfor

	if(size != 0)
		size = max(1, ConvertFromBytesToMiB(size))
	endif

	SetValDisplay(win, valdisp_currentsize, var = size, format = "%3.0f")
End

static Function GetTargetRate(string win)

	string str

	str = GetPopupMenuString(win, popup_targetrate)

	if(!cmpstr(str, NONE))
		return NaN
	endif

	return str2num(str)
End

static Function UpdateEstimatedSizeAfterwards(string win)

	WAVE/WAVE dataRef = GetDownsampleDataRefWave()
	WAVE      rate    = GetDownsampleRateWave()
	variable i
	variable size       = 0
	variable numWaves   = DimSize(dataRef, ROWS)
	variable targetRate = GetTargetRate(win)

	for(i = 0; i < numWaves; i += 1)
		size += GetWaveSize(dataRef[i]) * targetRate / rate[i]
	endfor

	size = max(1, ConvertFromBytesToMiB(size))

	if(numWaves == 0)
		size = NaN
	endif

	SetValDisplay(win, valdisp_estimatedsize, var = size, format = "%3.0f")
End

/// @brief Disable the equalize checkbox if all data waves have the same rate
static Function ApplyConstantRateChanges(string win)

	variable minimumRate, maximumRate

	WAVE rate = GetDownsampleRateWave()

	[minimumRate, maximumRate] = WaveMinAndMax(rate)

	if(minimumRate == maximumRate)
		DisableControl(win, checkbox_equalize)
		UpdateCheckBoxes(win, checkbox_equalize, CHECKBOX_UNSELECTED)
	else
		EnableControl(win, checkbox_equalize)
	endif
End

/// @brief Returns a list of values 1/k*var with k = {1..10} or k = {2..10} if constantRates == 1.
/// @param win 			 panel name
/// @param var			 variable to expand
/// @param constantRates boolean switch, defaults to false
static Function/S ExpandRateToList(string win, variable var, [variable constantRates])

	variable i
	variable count = 10
	string   list  = ""

	if(ParamIsDefault(constantRates))
		constantRates = 0
	else
		constantRates = 1
	endif

	if(GetCheckBoxState(win, checkbox_equalize))
		return num2str(var)
	endif

	for(i = constantRates ? 2 : 1; i <= count; i += 1)
		list = AddListItem(num2str(var / i), list, ";", Inf)
	endfor

	return list
End

/// @brief Returns a list of all possible equalize/downsampling rates
Function/S GetPopupMenuRates()

	variable maximum, minimum
	WAVE rates = GetDownsampleRateWave()

	if(!DimSize(rates, ROWS))
		return NONE
	endif

	[minimum, maximum] = WaveMinAndMax(rates)

	if(minimum == maximum)
		return ExpandRateToList(panel, minimum, constantRates = 1)
	endif

	variable interpolation = GetCheckBoxState(panel, checkbox_interpolation)

	if(interpolation)
		return ExpandRateToList(panel, minimum)
	endif

	WAVE uniqueRates = GetUniqueEntries(rates)

	uniqueRates[] = maximum / uniqueRates[p]

	return ExpandRateToList(panel, maximum / CalculateLCMOfWave(uniqueRates))
End

static Function GetDecimationMethod(string win)

	// we niftly exploit the fact that the indizes of the popup
	// and the DECIMATION_BY_* constants have a mathematical relation
	return 2^GetPopupMenuIndex(win, popup_decimationMethod)
End

static Function UpdateCheckBoxes(string win, string control, variable state)

	variable low, high, inc

	ASSERT(state == 0 || state == 1, "Invalid state")

	if(CmpStr(control, checkbox_equalize) == 0)
		SetCheckBoxState(win, checkbox_equalize, state)
		SetCheckBoxState(win, checkbox_downsample, !state)
	elseif(CmpStr(control, checkbox_downsample) == 0)
		SetCheckBoxState(win, checkbox_equalize, !state)
		SetCheckBoxState(win, checkbox_downsample, state)
	else
		FATAL_ERROR("Invalid control")
	endif

	UpdatePopupMenuTargetRate(win)
	UpdateEstimatedSizeAfterwards(win)
End

static Function UpdatePopupMenuWindowFunction(string win, [variable decimationMethod])

	if(ParamIsDefault(decimationMethod))
		decimationMethod = GetDecimationMethod(win)
	endif

	if(decimationMethod == DECIMATION_BY_SMOOTHING)
		EnableControl(win, popup_windowfunction)
	else
		DisableControl(win, popup_windowfunction)
	endif
End

Function CreateDownsamplePanel()

	if(windowExists(panel))
		DoWindow/F $panel
		return NaN
	endif

	NewPanel/N=$panel/W=(283, 389, 847, 643)/K=1
	ASSERT(CmpStr(panel, S_name) == 0, "window already exists")
	SetWindow $panel, hook(cleanup)=DownsampleWindowHook
	SetWindow kwTopWin, userdata(JSONSettings_WindowGroup)="downsample"

	PopupMenu popup_deviceselection_id, pos={28, 13}, size={214, 21}, bodyWidth=130, proc=PopupMenuDeviceSelection, title="Device Selection"
	PopupMenu popup_deviceselection_id, mode=1, value=#"GetPopupMenuDeviceListWithData()"
	PopupMenu popup_deviceselection_id, help={"List of devices having acquired data."}

	PopupMenu popup_decimationmethod_id, pos={29, 126}, size={206, 21}, bodyWidth=111, proc=PopupMenuDecimationMethod, title="Decimation Method"
	PopupMenu popup_decimationmethod_id, mode=1, popvalue="Omission", value=#"\"Omission;Smoothing;Averaging\""
	PopupMenu popup_decimationmethod_id, help={"Different methods on how to resample the data. See the section about \"Resample\" in the Igor Pro manual."}

	PopupMenu popup_windowfunction_id, pos={42, 152}, size={194, 21}, bodyWidth=111, disable=2, title="Window function"
	PopupMenu popup_windowfunction_id, mode=11, popvalue=FFT_WINF_DEFAULT, value=#"FFT_WINF"
	PopupMenu popup_windowfunction_id, help={"Window functions for the Smooting-Method of resampling."}

	CheckBox checkbox_equalize_id, pos={21, 55}, size={58, 14}, proc=CheckBoxEqualizeDown, title="Equalize"
	CheckBox checkbox_equalize_id, value=1, mode=1
	CheckBox checkbox_equalize_id, help={"Resamples all data to the greatest common divisor of all rates."}

	CheckBox checkbox_downsample_id, pos={20, 77}, size={79, 14}, proc=CheckBoxEqualizeDown, title="Downsample"
	CheckBox checkbox_downsample_id, value=0, mode=1
	CheckBox checkbox_downsample_id, help={"Resamples all data to a lower rate."}

	PopupMenu popup_targetrate_id, pos={110, 62}, size={143, 21}, bodyWidth=60, proc=PopupMenuTargetRate, title="Target rate (kHz)"
	PopupMenu popup_targetrate_id, mode=1, value=#"GetPopupMenuRates()"
	PopupMenu popup_targetrate_id, help={"Available rates for downsampling."}

	CheckBox checkbox_backupwaves_id, pos={25, 199}, size={115, 14}, title="Backup original data"
	CheckBox checkbox_backupwaves_id, value=1
	CheckBox checkbox_backupwaves_id, help={"Should the original data be backuped before performing the downsampling?"}

	Button button_restorebackup_id, pos={155, 196}, size={90, 20}, proc=ButtonRestoreBackup, title="Restore backup"
	Button button_restorebackup_id, help={"Replace the data and config waves with its backup."}

	ValDisplay valdisp_currentsize_id, pos={298, 178}, size={180, 14}, title="Current size:"
	ValDisplay valdisp_currentsize_id, format="%25g MiB", frame=0
	ValDisplay valdisp_currentsize_id, valueBackColor=(60928, 60928, 60928)
	ValDisplay valdisp_currentsize_id, limits={0, 0, 0}, barmisc={0, 1000}, value=#"nan"
	ValDisplay valdisp_currentsize_id, help={"Current size of all data waves from the device"}

	ValDisplay valdisp_estimatedsize_id, pos={297, 198}, size={180, 14}, title="Estimated size afterwards:"
	ValDisplay valdisp_estimatedsize_id, format="%4g MiB", frame=0
	ValDisplay valdisp_estimatedsize_id, valueBackColor=(60928, 60928, 60928)
	ValDisplay valdisp_estimatedsize_id, limits={0, 0, 0}, barmisc={0, 1000}
	ValDisplay valdisp_estimatedsize_id, value=#"nan"
	ValDisplay valdisp_estimatedsize_id, help={"Approximated size of all data waves after resampling."}

	ListBox listbox_waves_id, pos={297, 23}, size={241, 148}
	ListBox listbox_waves_id, listWave=GetDownsampleListWave()
	ListBox listbox_waves_id, widths={45, 68, 58}

	Button button_doit_id, pos={227, 230}, size={90, 20}, proc=ButtonDoIt, title="Do It"
	Button button_doit_id, help={"Perform the resampling."}

	CheckBox checkbox_interpolation_id, pos={89, 101}, size={103, 14}, proc=CheckBoxInterpolation, title="Allow interpolation"
	CheckBox checkbox_interpolation_id, value=1
	CheckBox checkbox_interpolation_id, help={"Allow also upsampling to reach the target rate. Especially useful if all possible rates are present."}

	GroupBox group0, pos={276, 11}, size={276, 211}
	GroupBox group1, pos={11, 43}, size={252, 137}
	GroupBox group2, pos={11, 190}, size={253, 32}

	NVAR JSONid = $GetSettingsJSONid()
	PS_InitCoordinates(JSONid, panel, addHook = 0)

	UpdatePanel(panel)
	UpdatePopupMenuWindowFunction(panel)
End

Function DownsampleWindowHook(STRUCT WMWinHookStruct &s)

	string win

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KILL:
			win = s.winName

			NVAR JSONid = $GetSettingsJSONid()
			PS_StoreWindowCoordinate(JSONid, win)

			KillOrMoveToTrash(wv = GetDownsampleListWave())
			KillOrMoveToTrash(wv = GetDownsampleDataRefWave())
			KillOrMoveToTrash(wv = GetDownsampleRateWave())
			KillOrMoveToTrash(dfr = $dataPath)
			break
		default:
			break
	endswitch

	// return zero so that other hooks are called as well
	return 0
End

Function CheckBoxInterpolation(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string win
	switch(cba.eventCode)
		case 2: // mouse up
			win = cba.win
			ControlUpdate/W=$win $popup_targetrate
			UpdateEstimatedSizeAfterwards(win)
			break
		default:
			break
	endswitch

	return 0
End

Function PopupMenuTargetRate(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 1: // fallthrough
		case 2: // fallthrough
		case 3: // fallthrough
		case 4: // fallthrough
		case 5: // fallthrough
		case 6:
			UpdateEstimatedSizeAfterwards(pa.win)
			break
		default:
			break
	endswitch

	return 0
End

Function ButtonRestoreBackup(STRUCT WMButtonAction &ba) : ButtonControl

	string win
	variable numWaves, i, success

	switch(ba.eventCode)
		case 2: // mouse up
			win     = ba.win
			success = 1
			WAVE/WAVE dataRef = GetDownsampleDataRefWave()

			numWaves = DimSize(dataRef, ROWS)
			for(i = 0; i < numWaves; i += 1)

				WAVE sweep  = dataRef[i]
				WAVE config = GetConfigWave(sweep)

				if(WaveExists(GetBackupWave(sweep)) && WaveExists(GetBackupWave(config)))
					ReplaceWaveWithBackup(sweep, nonExistingBackupIsFatal = 0)
					ReplaceWaveWithBackup(config, nonExistingBackupIsFatal = 0)
				else
					success = 0
				endif
			endfor

			if(!success)
				Print "Restoring backups failed. At least one wave did not have a backup."
				ControlWindowToFront()
			endif

			UpdatePanel(win)
			break
		default:
			break
	endswitch

	return 0
End

Function ButtonDoIt(STRUCT WMButtonAction &ba) : ButtonControl

	variable backupWaves, decimationMethod, i, numWaves, downsampleFactor, upsampleFactor
	variable targetRate, channel, ret
	string win, name, winFunction
	DFREF dfr

	switch(ba.eventCode)
		case 2: // mouse up
			win              = ba.win
			backupWaves      = GetCheckBoxState(win, checkbox_backupwaves)
			decimationMethod = GetDecimationMethod(win)

			if(!backupWaves)
				DoAlert 1, "Are you sure you want to overwrite your original data?"
				if(V_flag != 1)
					return 0
				endif
			endif

			WAVE/WAVE dataRef = GetDownsampleDataRefWave()
			WAVE      rate    = GetDownsampleRateWave()
			WAVE/T    list    = GetDownsampleListWave()
			ASSERT(DimSize(dataRef, ROWS) == DimSize(rate, ROWS), "Unmatched wave sizes")
			ASSERT(DimSize(list, ROWS) == DimSize(rate, ROWS), "Unmatched wave sizes")

			targetRate = GetTargetRate(win)

			numWaves = DimSize(dataRef, ROWS)
			for(i = 0; i < numWaves; i += 1)
				RatioFromNumber/MERR=1e-2 (targetRate / rate[i])
				upsampleFactor   = V_numerator
				downsampleFactor = V_denominator
				WAVE data   = dataRef[i]
				WAVE config = GetConfigWave(data)

				if(backupWaves)
					CreateBackupWave(data)
					CreateBackupWave(config)
				endif

				// resample with window function
				if(decimationMethod == DECIMATION_BY_SMOOTHING)
					winFunction = GetPopupMenuString(win, popup_windowfunction)
					ret         = DownSample(data, downsampleFactor, upsampleFactor, decimationMethod, winFunction = winFunction)
				else
					ret = DownSample(data, downsampleFactor, upsampleFactor, decimationMethod)
				endif

				if(ret)
					return NaN
				endif

				UpdateSweepConfig(config, samplingInterval = ConvertRateToSamplingInterval(targetrate))
			endfor
			UpdatePanel(win)
			break
		default:
			break
	endswitch

	return 0
End

static Function UpdatePopupMenuTargetRate(string win)

	variable idx

	ControlUpdate/W=$win $popup_targetrate
	idx = GetPopupMenuIndex(win, popup_targetrate)
	if(idx >= ItemsInList(GetPopupMenuRates()))
		idx = 0
	endif
	SetPopupMenuIndex(win, popup_targetrate, idx)
End

static Function UpdatePanel(string win, [string deviceSelectionString])

	string deviceType, deviceNumber
	variable ret

	if(ParamIsDefault(deviceSelectionString))
		deviceSelectionString = GetPopupMenuString(win, popup_deviceselection)
	endif

	ret = ParseDeviceString(deviceSelectionString, deviceType, deviceNumber)
	if(!ret)
		return NaN
	endif

	UpdateDataWaves(deviceType, deviceNumber)
	UpdatePopupMenuTargetRate(win)
	ApplyConstantRateChanges(win)
	UpdateEstimatedSizeAfterwards(win)
	UpdateCurrentSize(win)
End

Function PopupMenuDeviceSelection(STRUCT WMPopupAction &pa) : PopupMenuControl

	string popStr, win
	switch(pa.eventCode)
		case 2: // mouse up
			win    = pa.win
			popStr = pa.popStr
			UpdatePanel(win, deviceSelectionString = popStr)
			break
		default:
			break
	endswitch

	return 0
End

Function PopupMenuDecimationMethod(STRUCT WMPopupAction &pa) : PopupMenuControl

	string win
	switch(pa.eventCode)
		case 2: // mouse up
			win = pa.win
			UpdatePopupMenuWindowFunction(win, decimationMethod = 2^(pa.popNum - 1))
			break
		default:
			break
	endswitch

	return 0
End

Function CheckBoxEqualizeDown(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	variable checked
	string   win
	string   control
	variable low, high, inc

	switch(cba.eventCode)
		case 2: // mouse up
			cba.blockreentry = 1
			checked          = cba.checked
			win              = cba.win
			control          = cba.ctrlName
			UpdateCheckBoxes(win, control, checked)
			break
		default:
			break
	endswitch

	return 0
End
