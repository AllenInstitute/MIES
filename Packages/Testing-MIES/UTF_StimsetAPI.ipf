#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=StimsetAPITests

static Function TEST_CASE_BEGIN_OVERRIDE(string name)

	AdditionalExperimentCleanup()
End

// ST_GetStimsetList
static Function GetStimSetListWorks()

	string list, ref
	string thirdPartyStimSetList, WBstimSetList

	// create STIMSET_TP_WHILE_DAQ to check that no duplicates are returned
	GetTestPulse()

	list = ST_GetStimsetList()
	ref  = "Testpulse;"
	CHECK_EQUAL_STR(list, ref)

	list = ST_GetStimsetList(channelType = CHANNEL_TYPE_DAC)
	ref  = "Testpulse;"
	CHECK_EQUAL_STR(list, ref)

	list = ST_GetStimsetList(channelType = CHANNEL_TYPE_TTL)
	ref  = ""
	CHECK_EQUAL_STR(list, ref)

	list = ST_GetStimsetList(channelType = CHANNEL_TYPE_DAC, searchString = "Test*")
	ref  = "Testpulse;"
	CHECK_EQUAL_STR(list, ref)

	list = ST_GetStimsetList(channelType = CHANNEL_TYPE_DAC, searchString = "I_DONT_EXIST*")
	ref  = ""
	CHECK_EQUAL_STR(list, ref)

	// create stimsets
	ST_CreateStimSet("setA", CHANNEL_TYPE_DAC)
	ST_CreateStimSet("setB", CHANNEL_TYPE_TTL)

	// third party stimset
	DFREF dfr = GetSetFolder(CHANNEL_TYPE_DAC)
	Make dfr:setC_DA_0

	list = ST_GetStimsetList(channelType = CHANNEL_TYPE_DAC, WBstimSetList = WBstimSetList, thirdPartyStimSetList = thirdPartyStimSetList)
	ref  = "Testpulse;setA_DA_0;setC_DA_0;"
	CHECK_EQUAL_STR(list, ref)
	ref = "setA_DA_0;"
	CHECK_EQUAL_STR(WBstimSetList, ref)
	ref = "setC_DA_0;"
	CHECK_EQUAL_STR(thirdPartyStimSetList, ref)

	list = ST_GetStimsetList(channelType = CHANNEL_TYPE_TTL, WBstimSetList = WBstimSetList, thirdPartyStimSetList = thirdPartyStimSetList)
	ref  = "setB_TTL_0;"
	CHECK_EQUAL_STR(list, ref)
	ref = "setB_TTL_0;"
	CHECK_EQUAL_STR(WBstimSetList, ref)
	ref = ""
	CHECK_EQUAL_STR(thirdPartyStimSetList, ref)
End

// ST_CreateStimSet
static Function CreateStimSetWorks()
	string name, returned, ref

	name = "setA"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	name += "_DA_0"
	CHECK_EQUAL_STR(name, returned)
	CHECK(WB_ParameterWavesExist(returned))
	CHECK(WB_StimsetExists(returned))

	name = "setB"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_TTL)
	name += "_TTL_0"
	CHECK_EQUAL_STR(name, returned)
	CHECK(WB_ParameterWavesExist(returned))
	CHECK(WB_StimsetExists(returned))

	// fixes up invalid names
	name = "set B"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	name += "_DA_0"
	CHECK_NEQ_STR(name, returned)
	CHECK(!WB_ParameterWavesExist(name))
	CHECK(WB_ParameterWavesExist(returned))
	CHECK(WB_StimsetExists(returned))

	// uses setNumber
	name = "setC"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC, setNumber = 1)
	name += "_DA_1"
	CHECK_EQUAL_STR(name, returned)
	CHECK(WB_ParameterWavesExist(returned))
	CHECK(WB_StimsetExists(returned))

	// does not allow saving builtin stimsets out of the box
	name = "MIES_setD"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	ref = ""
	CHECK_EQUAL_STR(ref, returned)
	CHECK(!WB_ParameterWavesExist(returned))
	CHECK(!WB_StimsetExists(returned))

	// but it does if one passes saveAsBuiltin == 1
	name = "MIES_setD"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC, saveAsBuiltin = 1)
	name += "_DA_0"
	CHECK_EQUAL_STR(name, returned)
	CHECK(WB_ParameterWavesExist(returned))
	CHECK(WB_StimsetExists(returned))
End

// ST_RemoveStimSet
static Function RemoveStimSetWorks()
	string name, returned

	name = "setA"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	name += "_DA_0"
	CHECK_EQUAL_STR(name, returned)
	CHECK(WB_ParameterWavesExist(returned))
	CHECK(WB_StimsetExists(returned))

	ST_RemoveStimSet(returned)
	CHECK(!WB_ParameterWavesExist(returned))
	CHECK(!WB_StimsetExists(returned))
End

// ST_GetStimsetParameters
/// @{
static Function GetStimsetParametersWorksGlobal()
	string name, returned

	name = "setA"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	name += "_DA_0"
	CHECK_EQUAL_STR(name, returned)

	WAVE/Z globalParams = ST_GetStimsetParameters(name)
	CHECK_WAVE(globalParams, TEXT_WAVE)

	FindValue/TXOP=4/TEXT="Flip time axis" globalParams
	CHECK_GE_VAR(V_Value, 0)

	FindValue/TXOP=4/TEXT="Analysis function (generic)" globalParams
	CHECK_GE_VAR(V_Value, 0)
End

static Function GetStimsetParametersWorksPerEpoch()
	string name, returned, entry
	variable i

	name = "setA"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	name += "_DA_0"
	CHECK_EQUAL_STR(name, returned)

	for(i = 0; i < EPOCH_TYPES_TOTAL_NUMBER; i += 1)
		WAVE/Z perEpochParams = ST_GetStimsetParameters(name, epochType = i)
		CHECK_WAVE(perEpochParams, TEXT_WAVE)
		CHECK_GT_VAR(DimSize(perEpochParams, ROWS), 0)

		if(i == EPOCH_TYPE_COMBINE)
			entry = "Combine epoch formula"
		elseif(i == EPOCH_TYPE_SQUARE_PULSE)
			entry = "Duration"
		else
			entry = "Offset"
		endif

		FindValue/TXOP=4/TEXT=entry perEpochParams
		CHECK_GE_VAR(V_Value, 0)
	endfor

	// returns null for invalid epoch
	WAVE/Z result = ST_GetStimsetParameters(name, epochType = NaN)
	CHECK_WAVE(result, NULL_WAVE)

	WAVE/Z result = ST_GetStimsetParameters(name, epochType = -1)
	CHECK_WAVE(result, NULL_WAVE)

	WAVE/Z result = ST_GetStimsetParameters(name, epochType = EPOCH_TYPES_TOTAL_NUMBER)
	CHECK_WAVE(result, NULL_WAVE)
End
/// @}

// ST_GetStimsetParameterAsVariable
static Function GetStimsetParameterAsVariableWorks()
	string name, returned

	name = "setA"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	name += "_DA_0"
	CHECK_EQUAL_STR(name, returned)

	// fetch SegWvType entries
	WAVE SegWvType = WB_GetSegWvTypeForSet(name)
	SegWvType[%$("Total number of epochs")] = 3
	SegWvType[%$("Type of Epoch 0")]        = EPOCH_TYPE_SQUARE_PULSE
	SegWvType[%$("Type of Epoch 1")]        = EPOCH_TYPE_NOISE
	SegWvType[%$("Type of Epoch 2")]        = EPOCH_TYPE_RAMP

	CHECK_EQUAL_VAR(ST_GetStimsetParameterAsVariable(name, "Type of Epoch 0"), EPOCH_TYPE_SQUARE_PULSE)
	CHECK_EQUAL_VAR(ST_GetStimsetParameterAsVariable(name, "Type of Epoch 1"), EPOCH_TYPE_NOISE)
	CHECK_EQUAL_VAR(ST_GetStimsetParameterAsVariable(name, "Type of Epoch 2"), EPOCH_TYPE_RAMP)

	// fetch WP entries
	WAVE WP = WB_GetWaveParamForSet(name)
	CHECK_WAVE(WP, NUMERIC_WAVE)

	WP[%$("Duration")][0][%$("Square Pulse")] = 123
	WP[%$("Duration")][1][%$("Noise")]        = 456
	WP[%$("Duration")][2][%$("Ramp")]         = 789

	CHECK_EQUAL_VAR(ST_GetStimsetParameterAsVariable(name, "Duration", epochIndex = 0), 123)
	CHECK_EQUAL_VAR(ST_GetStimsetParameterAsVariable(name, "Duration", epochIndex = 1), 456)
	CHECK_EQUAL_VAR(ST_GetStimsetParameterAsVariable(name, "Duration", epochIndex = 2), 789)
End

// ST_GetStimsetParameterAsString
static Function GetStimsetParameterAsStringWorks()
	string name, returned, str, ref

	name = "setA"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	name += "_DA_0"
	CHECK_EQUAL_STR(name, returned)

	// fetch SegWvType entries
	WAVE SegWvType = WB_GetSegWvTypeForSet(name)
	SegWvType[%$("Total number of epochs")] = 3
	SegWvType[%$("Type of Epoch 0")]        = EPOCH_TYPE_SQUARE_PULSE
	SegWvType[%$("Type of Epoch 1")]        = EPOCH_TYPE_NOISE
	SegWvType[%$("Type of Epoch 2")]        = EPOCH_TYPE_RAMP

	WAVE WP = WB_GetWaveParamForSet(name)
	CHECK_WAVE(WP, NUMERIC_WAVE)

	// 1 == Pink
	// internally stored as numeric, but with the API as string for better readability
	WP[%$("Noise Type [White, Pink, Brown]")][1][%$("Noise")] = 1

	str = ST_GetStimsetParameterAsString(name, "Noise Type [White, Pink, Brown]", epochIndex = 1)
	ref = "Pink"
	CHECK_EQUAL_STR(str, ref)

	WAVE/T WPT = WB_GetWaveTextParamForSet(name)
	CHECK_WAVE(WPT, TEXT_WAVE)

	WPT[%$("Inter trial interval ldel")][%Set][INDEP_EPOCH_TYPE] = "abcd"

	str = ST_GetStimsetParameterAsString(name, "Inter trial interval ldel")
	ref = "abcd"
	CHECK_EQUAL_STR(str, ref)
End

// ST_SetStimsetParameter
static Function SetStimsetParameterWorks()
	string name, returned, str, ref

	name = "setA"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	name += "_DA_0"
	CHECK_EQUAL_STR(name, returned)

	ST_SetStimsetParameter(name, "Total number of epochs", var = 3)
	ST_SetStimsetParameter(name, "Type of Epoch 0", var = EPOCH_TYPE_SQUARE_PULSE)
	ST_SetStimsetParameter(name, "Type of Epoch 1", var = EPOCH_TYPE_NOISE)
	ST_SetStimsetParameter(name, "Type of Epoch 2", var = EPOCH_TYPE_RAMP)

	// SegWvType entries
	WAVE SegWvType = WB_GetSegWvTypeForSet(name)
	CHECK_EQUAL_VAR(SegWvType[%$("Total number of epochs")], 3)
	CHECK_EQUAL_VAR(SegWvType[%$("Type of Epoch 0")], EPOCH_TYPE_SQUARE_PULSE)
	CHECK_EQUAL_VAR(SegWvType[%$("Type of Epoch 1")], EPOCH_TYPE_NOISE)
	CHECK_EQUAL_VAR(SegWvType[%$("Type of Epoch 2")], EPOCH_TYPE_RAMP)

	WAVE WP = WB_GetWaveParamForSet(name)
	CHECK_WAVE(WP, NUMERIC_WAVE)

	// string given but stored as numeric
	ST_SetStimsetParameter(name, "Noise Type [White, Pink, Brown]", epochIndex = 1, str = "Brown")
	CHECK_EQUAL_VAR(WP[%$("Noise Type [White, Pink, Brown]")][1][%$("Noise")], 2)

	// really stored numerical, per epoch
	ST_SetStimsetParameter(name, "Duration", epochIndex = 0, var = 123)
	ST_SetStimsetParameter(name, "Duration", epochIndex = 1, var = 456)
	ST_SetStimsetParameter(name, "Duration", epochIndex = 2, var = 789)

	CHECK_EQUAL_VAR(WP[%$("Duration")][0][%$("Square Pulse")], 123)
	CHECK_EQUAL_VAR(WP[%$("Duration")][1][%$("Noise")], 456)
	CHECK_EQUAL_VAR(WP[%$("Duration")][2][%$("Ramp")], 789)

	// really stored as string, global
	ST_SetStimsetParameter(name, "Inter trial interval ldel", str = "abcd")

	WAVE/T WPT = WB_GetWaveTextParamForSet(name)
	CHECK_WAVE(WPT, TEXT_WAVE)

	str = WPT[%$("Inter trial interval ldel")][%Set][INDEP_EPOCH_TYPE]
	ref = "abcd"
	CHECK_EQUAL_STR(str, ref)

	// really stored as string, per epoch
	ST_SetStimsetParameter(name, "Amplitude ldel", str = "efgh", epochIndex = 0)

	str = WPT[%$("Amplitude ldel")][0][EPOCH_TYPE_SQUARE_PULSE]
	ref = "efgh"
	CHECK_EQUAL_STR(str, ref)

	// set analysis function
	ST_SetStimsetParameter(name, "Analysis function (generic)", str = "TestAnalysisFunction_V3")

	str = WPT[%$("Analysis function (generic)")][%Set][INDEP_EPOCH_TYPE]
	ref = "TestAnalysisFunction_V3"
	CHECK_EQUAL_STR(str, ref)
End

Structure ParamModCounts
	string stimSet
	variable modCountWP
	variable modCountWPT
	variable modCountSegWvType
EndStructure

static Function InitParamModCounts_IGNORE(string stimSet, STRUCT ParamModCounts &s)

	s.stimSet = stimSet

	WAVE/Z WP = WB_GetWaveParamForSet(s.stimSet)
	CHECK_WAVE(WP, NORMAL_WAVE)

	WAVE/Z WPT = WB_GetWaveTextParamForSet(s.stimSet)
	CHECK_WAVE(WPT, NORMAL_WAVE)

	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(s.stimSet)
	CHECK_WAVE(SegWvType, NORMAL_WAVE)

	s.modCountWP        = WaveModCount(WP)
	s.modCountWPT       = WaveModCount(WPT)
	s.modCountSegWvType = WaveModCount(SegWvType)
End

static Function ParameterWavesAreUnchanged_IGNORE(STRUCT ParamModCounts &s)

	WAVE/Z WP = WB_GetWaveParamForSet(s.stimSet)
	CHECK_WAVE(WP, NORMAL_WAVE)

	WAVE/Z WPT = WB_GetWaveTextParamForSet(s.stimSet)
	CHECK_WAVE(WPT, NORMAL_WAVE)

	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(s.stimSet)
	CHECK_WAVE(SegWvType, NORMAL_WAVE)

	CHECK_EQUAL_VAR(WaveModCount(WP), s.modCountWP)
	CHECK_EQUAL_VAR(WaveModCount(WPT), s.modCountWPT)
	CHECK_EQUAL_VAR(WaveModCount(SegWvType), s.modCountSegWvType)
End

static Function SetStimsetParameterChecksInput()
	string name, returned
	variable ret

	name = "setA"
	returned = ST_CreateStimSet(name, CHANNEL_TYPE_DAC)
	name += "_DA_0"
	CHECK_EQUAL_STR(name, returned)

	STRUCT ParamModCounts s

	ST_SetStimsetParameter(name, "Total number of epochs", var = 2)
	ST_SetStimsetParameter(name, "Type of Epoch 0", var = EPOCH_TYPE_SQUARE_PULSE)
	ST_SetStimsetParameter(name, "Type of Epoch 1", var = EPOCH_TYPE_NOISE)

	InitParamModCounts_IGNORE(name, s)

	// missing stimset
	ret = ST_SetStimsetParameter("I DON'T EXIST", "Type of Epoch 0", var = EPOCH_TYPE_SQUARE_PULSE)
	CHECK_EQUAL_VAR(ret, 1)
	ParameterWavesAreUnchanged_IGNORE(s)

	// missing var
	ret = ST_SetStimsetParameter(name, "Type of Epoch 0")
	CHECK_EQUAL_VAR(ret, 1)
	ParameterWavesAreUnchanged_IGNORE(s)

	// string instead of var
	ret = ST_SetStimsetParameter(name, "Total number of epochs", str = "abcd")
	CHECK_EQUAL_VAR(ret, 1)
	ParameterWavesAreUnchanged_IGNORE(s)

	// var instead of string
	ret = ST_SetStimsetParameter(name, "Inter trial interval ldel", var = 123)
	CHECK_EQUAL_VAR(ret, 1)
	ParameterWavesAreUnchanged_IGNORE(s)

	// global parameter but epochIndex given
	ret = ST_SetStimsetParameter(name, "Total number of epochs", epochIndex = 0)
	CHECK_EQUAL_VAR(ret, 1)
	ParameterWavesAreUnchanged_IGNORE(s)

	// epoch parameter but epochIndex missing
	ret = ST_SetStimsetParameter(name, "Duration")
	CHECK_EQUAL_VAR(ret, 1)
	ParameterWavesAreUnchanged_IGNORE(s)

	// epoch index out of range
	ST_SetStimsetParameter(name, "Duration", epochIndex = 100, var = 123)
	CHECK_EQUAL_VAR(ret, 1)
	ParameterWavesAreUnchanged_IGNORE(s)

	// indexed epoch does not have that parameter
	ST_SetStimsetParameter(name, "Noise Type [White, Pink, Brown]", epochIndex = 0, str = "Brown")
	CHECK_EQUAL_VAR(ret, 1)
	ParameterWavesAreUnchanged_IGNORE(s)

	// translated string parameter with invalid string
	ST_SetStimsetParameter(name, "Noise Type [White, Pink, Brown]", epochIndex = 1, str = "I DON'T EXIST")
	CHECK_EQUAL_VAR(ret, 1)
	ParameterWavesAreUnchanged_IGNORE(s)
End
