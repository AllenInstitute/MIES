﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function TestLocking()

	Initialize_IGNORE()

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_DeviceType", val=5)

	try
		PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")
		REQUIRE(WindowExists("ITC18USB_DEV_0"))
	catch
		FAIL()
	endtry
End
