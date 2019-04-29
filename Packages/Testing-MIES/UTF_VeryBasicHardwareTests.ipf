#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=VeryBasicHardwareTesting

static Function CheckInstallation()

   CHECK_EQUAL_VAR(CHI_CheckInstallation(), 0)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function TestLocking([str])
	string str

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, str)

	try
		PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")
		REQUIRE(WindowExists(str))
	catch
		FAIL()
	endtry
End
