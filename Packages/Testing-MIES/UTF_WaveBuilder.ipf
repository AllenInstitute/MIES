#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=WB_Testing

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	KillDataFolder/Z GetWBSvdStimSetDAPath()

	KillDataFolder/Z GetWBSvdStimSetParamDAPath()
	DuplicateDataFolder root:wavebuilder_misc:DAParameterWaves, $GetWBSvdStimSetParamDAPathAS()
End

// Copy stimset parameter waves into our own permanent location
Function CopyParamWaves_IGNORE()
	KillDataFolder/Z root:wavebuilder_misc:DAParameterWaves
	DuplicateDataFolder $GetWBSvdStimSetParamDAPathAS(), root:wavebuilder_misc:DAParameterWaves
End

// Copy stimsets into our own permanent location
Function CopyWaves_IGNORE()
	KillDataFolder/Z root:wavebuilder_misc:DAWaves
	DuplicateDataFolder $GetWBSvdStimSetDAPathAsString(), root:wavebuilder_misc:DAWaves
End

Function WB_RegressionTest()

	variable i, numEntries
	string list, stimset

	DFREF ref = root:wavebuilder_misc:DAWaves
	DFREF dfr = GetWBSvdStimSetParamDAPath()
	list = GetListOfObjects(dfr, "WP_.*")

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		stimset = ReplaceString("WP_", StringFromList(i, list), "")
		// stock MIES stimset
		CHECK(!WB_StimsetIsFromThirdParty(stimset))

		// can be rebuilt
		WAVE/Z wv = WB_CreateAndGetStimSet(stimset)
		CHECK_WAVE(wv, NUMERIC_WAVE, minorType = FLOAT_WAVE)

		// parameter waves were upgraded
		WAVE WP = WB_GetWaveParamForSet(stimset)
		CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(WP), MIES_WAVEGETTERS#GetWPVersion())

		WAVE WPT = WB_GetWaveTextParamForSet(stimset)
		CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(WPT), MIES_WAVEGETTERS#GetWPTVersion())

		WAVE SegWvType = WB_GetSegWvTypeForSet(stimset)
		CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(SegWvType), MIES_WAVEGETTERS#GetSegWvTypeVersion())

		// check against our stimset generated with earlier versions
		WAVE/SDFR=ref refWave = $stimset
		CHECK_EQUAL_WAVES(refWave, wv, mode = WAVE_DATA | WAVE_DATA_TYPE | WAVE_SCALING | DIMENSION_LABELS | DIMENSION_UNITS | DIMENSION_SIZES | DATA_UNITS | DATA_FULL_SCALE)
	endfor
End
