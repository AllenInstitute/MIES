#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.

Function CheckInstallation()

   CHECK_EQUAL_VAR(CHI_CheckInstallation(), 0)
End

Function TestLocking()

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)

	try
		PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")
		REQUIRE(WindowExists(DEVICE))
	catch
		FAIL()
	endtry
End
