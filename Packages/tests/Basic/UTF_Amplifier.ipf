#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = Amplifier

static Function TestFuncMapping()

	string text, funcStr, name, ctrl
	variable func, clampMode, funcBack, modeBack

	WAVE/Z/T content = ListToTextWave(ProcedureText("", 0, "MIES_Constants.ipf"), "\r")
	CHECK_WAVE(content, TEXT_WAVE)

	WAVE/Z/T results = GrepTextWave(content, "(?i)Constant[[:space:]]*MCC_(Set|Auto)")
	CHECK_WAVE(results, TEXT_WAVE)

	for(entry : results)
		SplitString/E="([[:digit:]]+)$" entry, funcStr
		CHECK_EQUAL_VAR(V_Flag, 1)
		func = str2num(funcStr)
		CHECK(IsInteger(func))

		Make/FREE modes = {V_CLAMP_MODE, I_CLAMP_MODE}

		for(clampMode : modes)

			ctrl = AI_MapFunctionConstantToControl(func, clampMode)
			INFO("entry: %s, ctrl: %s", s0 = entry, s1 = ctrl)

			if(IsEmpty(ctrl))
				continue
			endif

			if(GrepString(ctrl, "button.*"))
				continue
			endif

			CHECK_PROPER_STR(ctrl)

			INFO("entry: %s, ctrl: %s", s0 = entry, s1 = ctrl)
			name = AI_MapFunctionConstantToName(func, clampMode)
			CHECK_PROPER_STR(name)

			INFO("entry: %s, ctrl: %s, name: %s", s0 = entry, s1 = ctrl, s2 = name)
			funcBack = MIES_AI#AI_MapNameToFunctionConstant(name)
			CHECK_EQUAL_VAR(func, funcBack)

			CHECK_EQUAL_STR(MIES_AI#AI_AmpStorageControlToRowLabel(ctrl), AI_MapFunctionConstantToName(func, clampMode))

			[funcBack, modeBack] = AI_MapControlNameToFunctionConstant(ctrl)

			INFO("entry: %s, ctrl: %s", s0 = entry, s1 = ctrl)
			CHECK_EQUAL_VAR(func, funcBack)

			if(AI_IsControlFromClampMode(ctrl, clampMode))
				INFO("entry: %s, ctrl: %s", s0 = entry, s1 = ctrl)
				CHECK_EQUAL_VAR(modeBack, clampMode)
			endif
		endfor
	endfor
End

// UTF_TD_GENERATOR DataGenerators#GetClampModesWithoutIZero
static Function TestAmplifierUnits([variable clampMode])

	string unit, prefix, unitWithPrefix
	variable func, numPrefix

	WAVE/Z funcs = AI_GetFunctionConstantForClampMode(clampMode)
	CHECK_WAVE(funcs, FREE_WAVE | NUMERIC_WAVE)

	CHECK_GT_VAR(DimSize(funcs, ROWS), 0)
	for(func : funcs)

		unitWithPrefix = AI_GetUnitForFunctionConstant(func, clampMode)
		CHECK_PROPER_STR(unitWithPrefix)

		strswitch(unitWithPrefix)
			case "On/Off": // fallthrough
			case "%":
				PASS()
				break
			default:
				INFO("unitWithPrefix = %s", s0 = unitWithPrefix)
				// ParseUnit asserts out on invalid units
				ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
				PASS()
				break
		endswitch
	endfor
End

static Function TestAmplifierStorageLabels()

	variable clampMode, numFuncs

	WAVE clampModes = DataGenerators#GetClampModesWithoutIZero()

	for(clampMode : clampModes)
		WAVE aiFuncs = AI_GetFunctionConstantForClampMode(clampMode)
		numFuncs = DimSize(aiFuncs, ROWS)
		Make/FREE/T/N=(numFuncs) ctrlNames, ampLabels

		ctrlNames[] = AI_MapFunctionConstantToControl(aiFuncs[p], clampMode)
		ampLabels[] = MIES_AI#AI_AmpStorageControlToRowLabel(ctrlNames[p])

		Concatenate/FREE/NP=(ROWS)/T {ampLabels}, allAmpLabels
	endfor

	FindDuplicates/FREE/Z/DT=dupAmpLabels allAmpLabels

	WAVE/Z/T dupAmpLabelsUnique = GetUniqueEntries(dupAmpLabels)

	// all duplicated entries are empty
	CHECK_EQUAL_TEXTWAVES(dupAmpLabelsUnique, {""})

	WAVE ampStorageWave = GetAmplifierParamStorageWave("RandomDeviceName")

	WAVE/T allAmpLabelsNoEmpty = GetSetDifference(allAmpLabels, dupAmpLabels)
	Make/FREE/N=(DimSize(allAmpLabelsNoEmpty, ROWS)) rows = FindDimLabel(ampStorageWave, ROWS, allAmpLabelsNoEmpty[p])

	CHECK_GE_VAR(WaveMin(rows), 0)
End

static Function TestChanAmpAssignLayout()

	variable row
	string   lbl

	WAVE/Z chanAmpAssign = GetChanAmpAssign("RandomDeviceName")
	CHECK_WAVE(chanAmpAssign, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(chanAmpAssign, COLS), NUM_HEADSTAGES)

	Make/FREE/T labels = {"VC_DA", "VC_DAGain", "VC_AD", "VC_ADGain", "IC_DA", "IC_DAGain", "IC_AD", "IC_ADGain", "AmpSerialNo", "AmpChannelID", "AmpType"}
	for(lbl : labels)
		INFO("label: %s", s0 = lbl)
		CHECK_GE_VAR(FindDimLabel(chanAmpAssign, ROWS, lbl), 0)
	endfor

	// defaults of a new wave
	Make/FREE/T gainLabels = {"VC_DAGain", "VC_ADGain", "IC_DAGain", "IC_ADGain"}
	for(lbl : gainLabels)
		INFO("label: %s", s0 = lbl)
		row = FindDimLabel(chanAmpAssign, ROWS, lbl)
		Duplicate/FREE/RMD=[row][] chanAmpAssign, gains
		CHECK_EQUAL_VAR(IsConstant(gains, 1, ignoreNaN = 0), 1)
	endfor

	Make/FREE/T ampLabels = {"AmpSerialNo", "AmpChannelID"}
	for(lbl : ampLabels)
		INFO("label: %s", s0 = lbl)
		row = FindDimLabel(chanAmpAssign, ROWS, lbl)
		Duplicate/FREE/RMD=[row][] chanAmpAssign, ampEntries
		CHECK_EQUAL_VAR(IsConstant(ampEntries, NaN, ignoreNaN = 0), 1)
	endfor

	row = FindDimLabel(chanAmpAssign, ROWS, "AmpType")
	Duplicate/FREE/RMD=[row][] chanAmpAssign, ampTypes
	CHECK_EQUAL_VAR(IsConstant(ampTypes, AMPLIFIER_TYPE_NONE, ignoreNaN = 0), 1)
End

static Function TestChanAmpAssignUpgradeToAmplifierType()

	variable row

	WAVE chanAmpAssign = GetChanAmpAssign("RandomDeviceName")

	// create a version 3 layout
	Redimension/N=(10, -1) chanAmpAssign
	MIES_WAVEGETTERS#SetWaveVersion(chanAmpAssign, 3)

	// headstage 0: MCC amplifier
	chanAmpAssign[%AmpSerialNo][0]  = 123
	chanAmpAssign[%AmpChannelID][0] = 1
	// headstage 1: incomplete amplifier assignment
	chanAmpAssign[%AmpSerialNo][1]  = 456
	chanAmpAssign[%AmpChannelID][1] = NaN
	// all other headstages: no amplifier
	chanAmpAssign[%AmpSerialNo][2, *]  = NaN
	chanAmpAssign[%AmpChannelID][2, *] = NaN

	Duplicate/FREE chanAmpAssign, chanAmpAssignOld

	WAVE chanAmpAssign = GetChanAmpAssign("RandomDeviceName")
	CHECK_GT_VAR(GetWaveVersion(chanAmpAssign), 3)

	CHECK_EQUAL_VAR(chanAmpAssign[%AmpType][0], AMPLIFIER_TYPE_MCC)
	CHECK_EQUAL_VAR(chanAmpAssign[%AmpType][1], AMPLIFIER_TYPE_NONE)

	row = FindDimLabel(chanAmpAssign, ROWS, "AmpType")
	Duplicate/FREE/RMD=[row][2, *] chanAmpAssign, ampTypes
	CHECK_EQUAL_VAR(IsConstant(ampTypes, AMPLIFIER_TYPE_NONE, ignoreNaN = 0), 1)

	// existing entries are kept
	Duplicate/FREE/RMD=[0, 9][] chanAmpAssign, chanAmpAssignKept
	CHECK_EQUAL_WAVES(chanAmpAssignKept, chanAmpAssignOld, mode = WAVE_DATA)
End

static Function TestAmplifierTypeAccessors()

	string device = "RandomDeviceName"

	WAVE chanAmpAssign = GetChanAmpAssign(device)

	CHECK_EQUAL_VAR(AI_GetAmplifierType(device, 0), AMPLIFIER_TYPE_NONE)
	CHECK_EQUAL_VAR(AI_HasAmplifier(device, 0), 0)

	chanAmpAssign[%AmpType][1] = AMPLIFIER_TYPE_MCC
	CHECK_EQUAL_VAR(AI_GetAmplifierType(device, 1), AMPLIFIER_TYPE_MCC)
	CHECK_EQUAL_VAR(AI_HasAmplifier(device, 1), 1)

	chanAmpAssign[%AmpType][NUM_HEADSTAGES - 1] = AMPLIFIER_TYPE_SUTTER
	CHECK_EQUAL_VAR(AI_GetAmplifierType(device, NUM_HEADSTAGES - 1), AMPLIFIER_TYPE_SUTTER)
	CHECK_EQUAL_VAR(AI_HasAmplifier(device, NUM_HEADSTAGES - 1), 1)

	try
		AI_GetAmplifierType(device, NUM_HEADSTAGES)
		FAIL()
	catch
		PASS()
	endtry
End
