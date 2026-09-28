#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = IPAControlTesting

/// @file UTF_IPAControl.ipf
/// @brief __IPAT__ Tests for the Sutter amplifier control package IPA_Control.ipf
///
/// The test cases use the package directly. They restore the amplifier settings at the end
/// and discard the package without saving its preferences.

static Constant    IPA_PROBE          = 1
static StrConstant IPA_PACKAGE_FOLDER = "root:SutterIPAControl"

// IPA_Control.ipf is only included with the Sutter XOP, see MIES_Include.ipf
#if defined(TESTS_WITH_SUTTER_HARDWARE) && exists("SutterDAQScanWave")

/// @brief Initialize the package and connect it to the amplifiers
///
/// Skips the test case without connected IPA.
///
/// @returns the package state for RestoreIPA_IGNORE()
static Function/S InitIPA_IGNORE()

	STRUCT IPASeries SIPA

	CHECK_EQUAL_VAR(DataFolderExists(IPA_PACKAGE_FOLDER), 0)
	REQUIRE_EQUAL_VAR(IPA_Initialize(), 1)

	IPAControl#GetStructure(SIPA)
	if(!cmpstr(SIPA.amp[0].serialNum, "demo"))
		KillDataFolder $IPA_PACKAGE_FOLDER
		INFO("Requires a connected IPA")
		SKIP_TESTCASE()
	endif

	// the package stays in demo mode until connected, see IPA_OkToSendCommand()
	NVAR SD_USB       = $(IPA_PACKAGE_FOLDER + ":SD_USB")
	NVAR demo_amptype = $(IPA_PACKAGE_FOLDER + ":demo_amptype")
	SD_USB       = SIPA.numAmps
	demo_amptype = -1 // live mode
	REQUIRE_EQUAL_VAR(IPA_OkToSendCommand(), 1)

	return ROStr(IPA_PACKAGE_FOLDER + ":SD_Struct")
End

/// @brief Restore the package state, send it to the amplifiers and discard the package
static Function RestoreIPA_IGNORE(string state)

	variable probe, numProbes

	SVAR SD_Struct = $(IPA_PACKAGE_FOLDER + ":SD_Struct")
	SD_Struct = state

	numProbes = IPA_GetValue(IPA_PROBE, IPA_SET_NUM_PROBES)
	for(probe = 1; probe <= numProbes; probe += 1)
		// the mode switch sends the settings of the probe
		if(IPA_GetValue(probe, IPA_SET_VC_MODE))
			IPA_SetValue(probe, IPA_SET_VC_MODE, 1)
		else
			IPA_SetValue(probe, IPA_SET_CC_MODE, 1)
		endif
	endfor

	KillDataFolder $IPA_PACKAGE_FOLDER
End

static Function IPABridgeOnState()

	string state = InitIPA_IGNORE()

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_BRIDGE_ON, 1), 1)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, IPA_SET_BRIDGE_ON), 1)

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_BRIDGE_ON, 0), 1)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, IPA_SET_BRIDGE_ON), 0)

	RestoreIPA_IGNORE(state)
End

static Function IPAECompMagCurrentClamp()

	string state = InitIPA_IGNORE()

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_CC_MODE, 1), 1)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_E_COMP_MAG, 5e-12), 1)
	CHECK_CLOSE_VAR(IPA_GetValue(IPA_PROBE, IPA_SET_E_COMP_MAG), 5e-12, tol = 1e-15)

	RestoreIPA_IGNORE(state)
End

static Function IPAVHoldOnCurrentClamp()

	string state = InitIPA_IGNORE()

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_VC_MODE, 1), 1)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_V_HOLD, 0.01), 1)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, IPA_SET_V_HOLD_ON), 1)

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_CC_MODE, 1), 1)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_V_HOLD_ON, 0), 1)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, IPA_SET_V_HOLD_ON), 0)

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_VC_MODE, 1), 1)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, IPA_SET_V_HOLD_ON), 0)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, IPA_SET_V_HOLD), 0)

	RestoreIPA_IGNORE(state)
End

/// Requires the model cell in position "Cell", with an open input the automatic offset does not
/// change the offset
static Function IPAAutoOffset()

	variable offset, startOffset
	string state = InitIPA_IGNORE()

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_VC_MODE, 1), 1)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_OFFSET_LOCK, 0), 1)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_OFFSET, 0.05), 1)
	startOffset = IPA_GetValue(IPA_PROBE, IPA_SET_OFFSET)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, IPA_SET_AUTO_OFFSET, 1), 1)

	offset = IPA_GetValue(IPA_PROBE, IPA_SET_OFFSET)
	CHECK_NEQ_VAR(offset, startOffset)
	CHECK_LT_VAR(abs(offset), 0.2)

	RestoreIPA_IGNORE(state)
End

#else

static Function IPARequiresSutterHardware()

	INFO("Requires Sutter hardware and the Sutter XOP")
	SKIP_TESTCASE()
End

#endif // defined(TESTS_WITH_SUTTER_HARDWARE) && exists("SutterDAQScanWave")
