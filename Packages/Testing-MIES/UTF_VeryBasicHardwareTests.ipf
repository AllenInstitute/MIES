#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function TEST_BEGIN_OVERRIDE(name)
	string name

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0
End

Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	ITCCloseAll2
End

Function TestLocking()
	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_DeviceType", val=5)

	try
		PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")
		REQUIRE(WindowExists("ITC18USB_DEV_0"))
	catch
		FAIL()
	endtry
End
