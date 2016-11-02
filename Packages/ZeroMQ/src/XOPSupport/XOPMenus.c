// This file contains utilities for XOPs that add menu items or entire menus to IGOR.

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

/*	XOP Menu Compatibility

	Most XOPs either add no menus or menu items to Igor or add just a single
	menu item to an existing Igor menu. Such XOPs do not need to use any of
	XOP Toolkit menu support routines. Consequently for most XOPs, the issue
	discussed here is of no concern.
	
	If your XOP adds menus to Igor's main menu bar, shows and hides menus,
	adds and removes menu items, changes the text of menu items, enables
	and disables menu items or checks and unchecks menu items then you need
	to understand this material.

	In Igor Pro 6 and before support for XOP menus and menu items is based on
	the Macintosh Menu Manager and emulation of it provided on Windows by the
	IGOR.lib file.
	
	In Igor Pro 7 the implementation of menus is completely changed. For compatibility
	with Igor7 a new set of menu support routines was added to the XOP Toolkit.
	The new routines, defined in this file, were added in XOP Toolkit 6.40 but work
	with Igor Pro 6 and later.
	
	The new routines use a new type - XOPMenuRef, instead of MenuHandle.
	
	New code must use the new routines and existing code must be updated to
	use the new routines.
	
	See the MenuXOP1 XOP for examples using the new routines.
	
	The new Igor7-compatible routines are:
		XOPMenuRef XOPActualMenuIDToMenuRef(int actualMenuID);													// Replaces GetMenuHandle
		XOPMenuRef XOPResourceMenuIDToMenuRef(int resourceMenuID);												// Replaces ResourceMenuIDToMenuHandle
		int XOPGetMenuInfo(XOPMenuRef menuRef, int* actualMenuID, char* menuTitle, int* isVisible, void* reserved1, void* reserved2)	// Replaces GetMenuID
		int XOPCountMenuItems(XOPMenuRef menuRef);																// Replaces CountMItems
		int XOPShowMainMenu(XOPMenuRef menuRef, int beforeMenuID);												// Replaces WMInsertMenu followed by WMDrawMenuBar
		int XOPHideMainMenu(XOPMenuRef menuRef);																// Replaces WMDeleteMenu followed by WMDrawMenuBar
		int XOPGetMenuItemInfo(XOPMenuRef menuRef, int itemNumber, int* enabled, int* checked, void* reserved1, void* reserved2);		// Requires Igor Pro 6.32 or later
		int XOPGetMenuItemText(XOPMenuRef menuRef, int itemNumber, char text[256]);								// Replaces getmenuitemtext
		int XOPSetMenuItemText(XOPMenuRef menuRef, int itemNumber, const char* text);							// Replaces setmenuitemtext
		int XOPAppendMenuItem(XOPMenuRef menuRef, const char* text);											// Replaces appendmenu
		int XOPInsertMenuItem(XOPMenuRef menuRef, int afterItemNumber, const char* text);						// Replaces insertmenuitem
		int XOPDeleteMenuItem(XOPMenuRef menuRef, int itemNumber);												// Replaces DeleteMenuItem
		int XOPDeleteMenuItemRange(XOPMenuRef menuRef, int first, int last);									// Replaces WMDeleteMenuItems
		int XOPEnableMenuItem(XOPMenuRef menuRef, int itemNumber);												// Replaces EnableItem
		int XOPDisableMenuItem(XOPMenuRef menuRef, int itemNumber);												// Replaces DisableItem
		int XOPCheckMenuItem(XOPMenuRef menuRef, int itemNumber, int state);									// Replaces CheckItem
		int XOPFillMenu(XOPMenuRef menuRef, int afterItemNumber, const char* itemList);							// Replaces FillMenu
		int XOPFillMenuNoMeta(XOPMenuRef menuRef, int afterItemNumber, const char* itemList);					// Replaces FillMenuNoMeta
		int XOPFillWaveMenu(XOPMenuRef menuRef, const char* match, const char* options, int afterItemNumber);	// Replaces FillWaveMenu
		int XOPFillPathMenu(XOPMenuRef menuRef, const char* match, const char* options, int afterItemNumber);	// Replaces FillPathMenu
		int XOPFillWinMenu(XOPMenuRef menuRef, const char* match, const char* options, int afterItemNumber);	// Replaces FillWinMenu

	The following routines were removed from XOP Toolkit 7:
		GetMenuHandle					// Use XOPActualMenuIDToMenuRef
		ResourceMenuIDToMenuHandle		// Use XOPResourceMenuIDToMenuRef
		WMGetMenuFromModule				// No replacement
		GetMenuID						// Use XOPGetMenuInfo
		SetMenuID						// No replacement
		CountMItems						// Use XOPCountMenuItems
		WMDrawMenuBar					// Use XOPShowMainMenu and XOPHideMainMenu
		WMInsertMenu					// Use XOPShowMainMenu	
		WMDeleteMenu					// Use XOPHideMainMenu	
		appendmenu						// Use XOPAppendMenuItem
		insertmenuitem					// Use XOPInsertMenuItem
		DeleteMenuItem					// Use XOPDeleteMenuItem
		WMDeleteMenuItems				// Use XOPDeleteMenuItemRange
		getmenuitemtext					// Use XOPGetMenuItemText
		setmenuitemtext					// Use XOPSetMenuItemText
		EnableItem						// Use XOPEnableMenuItem
		DisableItem						// Use XOPDisableMenuItem
		CheckItem						// Use XOPMarkMenuItem
		FillMenu						// Use XOPFillMenu
		FillMenuNoMeta					// Use XOPFillMenuNoMeta
		FillWaveMenu					// Use XOPFillWaveMenu
		FillPathMenu					// Use XOPFillPathMenu
		FillWinMenu						// Use XOPFillWinMenu

	The old calls use MenuHandles while the new calls use XOPMenuRefs.
	A MenuHandle is a Mac OS type that is emulated on Windows by IGOR.lib.
	When running with Igor Pro 6 a XOPMenuRef is a MenuHandle but when running with
	Igor Pro 7 it is a different type. Consequently your code must treat XOPMenuRef
	as an opaque type and must not assume that it is equivalent to a MenuHandle.
	Therefore you must not pass a XOPMenuRef to a Mac OS call or an IGOR.lib call that
	emulates a Mac OS call and you must not pass a MenuHandle that you received from
	Mac OS to Igor as if it were a XOPMenuRef. To guarantee that you observe these rules
	change your code to use the new menu API and do not use any OS menu routines.
	
	Here is a procedure for converting an XOP to use the new API:
		1. Change all occurrences of MenuHandle to XOPMenuRef.
		2. Compile. Each use of a XOPMenuRef in an old call will generate an error.
		3. Replace the old call with the corresponding new call.
*/

/*	XOPActualMenuIDToMenuRef(actualMenuID)

	Given the actual menu ID of an Igor or XOP menu in memory, returns the menu reference for the XOP menu.
	
	Use XOPActualMenuIDToMenuRef to get an menu reference for an Igor menu. This is almost
	never needed.
	
	If you are trying to get a menu reference for a menu added to Igor by your XOP
	use XOPResourceMenuIDToMenuRef instead of XOPActualMenuIDToMenuRef. 

	Always check the returned menu reference for NULL before using it.
	
	NOTE:	XOPActualMenuIDToMenuRef returns NULL if actualMenuID is not valid.
			
	NOTE:	When running with Igor Pro 6 XOPActualMenuIDToMenuRef returns NULL
			for main menu bar menus that are hidden (e.g., via XOPHideMainMenu).
			With Igor Pro 7 it returns the menu reference whether the menu is hidden or not.
	
	XOPResourceMenuIDToMenuRef returns your menu reference whether it is hidden or not.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces GetMenuHandle.
	
	Thread Safety: XOPActualMenuIDToMenuRef is not thread-safe.
*/
XOPMenuRef
XOPActualMenuIDToMenuRef(int actualMenuID)
{
	if (!CheckRunningInMainThread("XOPActualMenuIDToMenuRef"))
		return NULL;

	if (igorVersion >= 632) {
		XOPMenuRef menuRef = (XOPMenuRef)CallBack1(XOP_ACTUAL_MENUID_TO_MENUREF, XOP_CALLBACK_INT(actualMenuID));
		return menuRef;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#if defined(MACIGOR) && defined(IGOR64)		// Compiling 64-bit Macintosh XOP?
			// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
			// The Mac OS Menu Manager does not exist in 64 bits.
			return NULL;
		#else
			// GetMenuHandle is a Mac OS Menu Manager call on Macintosh and is emulated by IGOR.lib on Windows.
			XOPMenuRef menuRef = (XOPMenuRef)GetMenuHandle(actualMenuID);
			return menuRef;
		#endif
	}
}

/*	XOPResourceMenuIDToMenuRef(resourceMenuID)

	Given the ID of a MENU resource in the XOP's resource fork, returns the
	menu reference for that menu. You can use this reference with other XOP menu
	routines to modify the menu.

	Always check the returned menu reference for NULL before using it.
	
	NOTE:	XOPResourceMenuIDToMenuRef returns NULL if XOP did not add this menu.
	
	Unlike XOPActualMenuIDToMenuRef, XOPResourceMenuIDToMenuRef returns the
	menu reference even if it is a hidden main menu bar menu.

	Always check the returned menu reference for NULL before using it.
	
	Thread Safety: XOPResourceMenuIDToMenuRef is not thread-safe.
*/
XOPMenuRef
XOPResourceMenuIDToMenuRef(int resourceMenuID)
{
	if (!CheckRunningInMainThread("XOPResourceMenuIDToMenuRef"))
		return NULL;
	
	return (XOPMenuRef)CallBack1(XOPMENUHANDLE, XOP_CALLBACK_INT(resourceMenuID));
}

/*	XOPGetMenuInfo(menuRef, actualMenuID, menuTitle, isVisible, reserved1, reserved2)

	Returns information about the menu specified by menuRef.
	
	*actualMenuID is set to the actual menu ID of the menu. You can pass NULL
	if you don't care about this value.
	
	menuTitle is a pointer to a 256 byte array of chars. You can pass NULL
	if you don't care about this value. This feature requires Igor Pro 6.32 or later.
	When running with earlier versions *menuTitle is set to 0.
	
	*isVisible is set to the truth that the menu is visible in the menu bar. This returns
	0 for hidden main menu bar menus and 1 for visible main menu bar menus. You can pass NULL
	if you don't care about this value. This feature requires Igor Pro 6.32 or later.
	When running with earlier versions *isVisible is set to -1.
	
	reserved1 and reserved2 are reserved for future use. Pass NULL for these parameters.
	
	The function result is 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32. When running with earlier versions only the actualMenuID
	parameter is supported.
	
	Replaces GetMenuID.
	
	Thread Safety: XOPGetMenuInfo is not thread-safe.
*/
int
XOPGetMenuInfo(XOPMenuRef menuRef, int* actualMenuID, char* menuTitle, int* isVisible, void* reserved1, void* reserved2)
{
	if (!CheckRunningInMainThread("XOPGetMenuInfo"))
		return NOT_IN_THREADSAFE;
	
	if (menuRef == NULL)
		return GENERAL_BAD_VIBS;

	if (igorVersion >= 632) {
		int result = (int)CallBack6(XOP_GET_MENU_INFO, menuRef, XOP_CALLBACK_INT(actualMenuID), (void*)menuTitle, XOP_CALLBACK_INT(isVisible), reserved1, reserved2);
		return result;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#if defined(MACIGOR) && defined(IGOR64)		// Compiling 64-bit Macintosh XOP?
			// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
			// The Mac OS Menu Manager does not exist in 64 bits.
			return 0;
		#else
			if (actualMenuID != NULL)
				*actualMenuID = (int)GetMenuID((MenuHandle)menuRef);	// GetMenuID is a Mac OS Menu Manager call on Macintosh and is emulated by IGOR.lib on Windows.
			if (menuTitle != NULL)
				*menuTitle = 0;				// This feature requires Igor Pro 6.32 or later.
			if (isVisible != NULL)
				*isVisible = -1;			// This feature requires Igor Pro 6.32 or later.
			return 0;
		#endif
	}
}

/*	XOPCountMenuItems(menuRef)

	Returns the number of items in the menu.
	
	See MenuXOP1.cpp for an example.
	
	Added in Igor Pro 6.32 but works with any version.
	
	Replaces CountMItems.
	
	Thread Safety: XOPCountMenuItems is not thread-safe.
*/
int
XOPCountMenuItems(XOPMenuRef menuRef)
{
	if (!CheckRunningInMainThread("XOPCountMenuItems"))
		return 0;

	if (igorVersion >= 632) {
		int numMenuItems = (int)CallBack1(XOP_COUNT_MENU_ITEMS, menuRef);
		return numMenuItems;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// CountMenuItems is a Mac OS Menu Manager routine
				int numMenuItems = CountMenuItems((MenuHandle)menuRef);
				return numMenuItems;
			#endif
		#endif
		#ifdef WINIGOR
			// CountMItems is provided by IGOR.lib on Windows
			int numMenuItems = CountMItems((MenuHandle)menuRef);
			return numMenuItems;
		#endif
	}
}

/*	XOPShowMainMenu(menuRef, beforeMenuID)

	menuRef is a reference to an XOP main menu bar menu. XOPShowMainMenu makes
	the menu appear in the menu bar if it was previously hidden.
	
	beforeMenuID is the actual menu ID of a menu in the menu bar or 0 to
	show the specified menu at the end of the menu bar. In most cases you
	should pass 0.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces WMInsertMenu followed by WMDrawMenuBar.
	
	Thread Safety: XOPShowMainMenu is not thread-safe.
*/
int
XOPShowMainMenu(XOPMenuRef menuRef, int beforeMenuID)
{
	if (!CheckRunningInMainThread("XOPShowMainMenu"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack2(XOP_SHOW_MAIN_MENU, menuRef, XOP_CALLBACK_INT(beforeMenuID));
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// InsertMenu and DrawMenuBar are Mac OS Menu Manager routines
				InsertMenu((MenuHandle)menuRef, (MenuID)beforeMenuID);
				DrawMenuBar();
				return 0;
			#endif
		#endif
		#ifdef WINIGOR
			// WMInsertMenu and WMDrawMenuBar are provided by IGOR.lib on Windows
			WMInsertMenu((MenuHandle)menuRef, (short)beforeMenuID);
			WMDrawMenuBar();
			return 0;
		#endif
	}
}

/*	XOPHideMainMenu(menuRef)

	menuRef is a reference to an XOP main menu bar menu. XOPHideMainMenu removes
	the menu from the menu bar if it was previously showing.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces WMDeleteMenu followed by WMDrawMenuBar.
	
	Thread Safety: XOPHideMainMenu is not thread-safe.
*/
int
XOPHideMainMenu(XOPMenuRef menuRef)
{
	if (!CheckRunningInMainThread("XOPHideMainMenu"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack1(XOP_HIDE_MAIN_MENU, menuRef);
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// GetMenuID, DeleteMenu and DrawMenuBar are Mac OS Menu Manager routines
				int actualMenuID = GetMenuID((MenuHandle)menuRef);
				DeleteMenu((MenuID)actualMenuID);
				DrawMenuBar();
				return 0;
			#endif
		#endif
		#ifdef WINIGOR
			// GetMenuID, WMDeleteMenu and WMDrawMenuBar are provided by IGOR.lib on Windows
			int actualMenuID = GetMenuID((MenuHandle)menuRef);
			WMDeleteMenu(actualMenuID);
			WMDrawMenuBar();
			return 0;
		#endif
	}
}

/*	XOPGetMenuItemInfo(menuRef, itemNumber, enabled, checked, reserved1, reserved2)

	XOPGetMenuItemInfo returns information about the menu item specified by menuRef
	and itemNumber.

	menuRef is a reference to an XOP menu.
	
	itemNumber is a 1-based item number.
	
	*enabled is set to the truth that the menu item is enabled. You can pass NULL
	if you don't want to know if the menu item is enabled.
	
	*checked is set to the truth that the menu item is checked. You can pass NULL
	if you don't want to know if the menu item is checked.
	
	reserved1 and reserved2 are reserved for future use. Pass NULL for these parameters.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32.
	
	This function requires Igor Pro 6.32 or later. With earlier versions it returns
	NOT_IMPLEMENTED and *enabled and *checked are set to -1.
	
	Thread Safety: XOPGetMenuItemInfo is not thread-safe.
*/
int
XOPGetMenuItemInfo(XOPMenuRef menuRef, int itemNumber, int* enabled, int* checked, void* reserved1, void* reserved2)
{
	if (!CheckRunningInMainThread("XOPGetMenuItemInfo"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack6(XOP_GET_MENU_ITEM_INFO, menuRef, XOP_CALLBACK_INT(itemNumber), XOP_CALLBACK_INT(enabled), XOP_CALLBACK_INT(checked), (void*)reserved1, (void*)reserved2);
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	if (enabled != NULL)
		*enabled = -1;
	if (checked != NULL)
		*checked = -1;
	return NOT_IMPLEMENTED;
}

/*	XOPGetMenuItemText(menuRef, itemNumber, text)

	XOPGetMenuItemText returns the text from an XOP menu item specified by menuRef
	and itemNumber.

	menuRef is a reference to an XOP menu.
	
	itemNumber is a 1-based item number.
	
	text must be able to hold 255 characters plus the null terminator.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces getmenuitemtext.
	
	Thread Safety: XOPGetMenuItemText is not thread-safe.
*/
int
XOPGetMenuItemText(XOPMenuRef menuRef, int itemNumber, char text[256])
{
	*text = 0;
	
	if (!CheckRunningInMainThread("XOPGetMenuItemText"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack3(XOP_GET_MENU_ITEM_TEXT, menuRef, XOP_CALLBACK_INT(itemNumber), text);
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// GetMenuItemText is a Mac OS Menu Manager routine
				unsigned char pItemString[256];
				GetMenuItemText((MenuHandle)menuRef, (MenuItemIndex)itemNumber, pItemString);
				CopyPascalStringToC(pItemString, text);
				return 0;
			#endif
		#endif
		#ifdef WINIGOR
			// getmenuitemtext is provided by IGOR.lib on Windows
			getmenuitemtext((MenuHandle)menuRef, (short)itemNumber, text);
			return 0;
		#endif
	}
}

/*	XOPSetMenuItemText(menuRef, itemNumber, text)

	XOPSetMenuItemText sets the text of an XOP menu item specified by menuRef
	and itemNumber.

	menuRef is a reference to an XOP menu.
	
	itemNumber is a 1-based item number.
	
	text is C string (null-terminated) of 255 characters or less.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces setmenuitemtext.
	
	Thread Safety: XOPSetMenuItemText is not thread-safe.
*/
int
XOPSetMenuItemText(XOPMenuRef menuRef, int itemNumber, const char* text)
{
	if (!CheckRunningInMainThread("XOPSetMenuItemText"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack3(XOP_SET_MENU_ITEM_TEXT, menuRef, XOP_CALLBACK_INT(itemNumber), (void*)text);
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// SetMenuItemText is a Mac OS Menu Manager routine
				unsigned char pItemString[256];
				CopyCStringToPascal(text, pItemString);
				SetMenuItemText((MenuHandle)menuRef, (MenuItemIndex)itemNumber, pItemString);
				return 0;
			#endif
		#endif
		#ifdef WINIGOR
			// setmenuitemtext is provided by IGOR.lib on Windows
			setmenuitemtext((MenuHandle)menuRef, (short)itemNumber, text);
			return 0;
		#endif
	}
}

/*	XOPAppendMenuItem(menuRef, text)

	XOPAppendMenuItem adds a menu item to the end of the XOP menu item specified by menuRef.

	menuRef is a reference to an XOP menu.
	
	text is C string (null-terminated) of 255 characters or less.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces appendmenu.
	
	Thread Safety: XOPAppendMenuItem is not thread-safe.
*/
int
XOPAppendMenuItem(XOPMenuRef menuRef, const char* text)
{
	if (!CheckRunningInMainThread("XOPAppendMenuItem"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack2(XOP_APPEND_MENU_ITEM, menuRef, (void*)text);
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// AppendMenuItemText is a Mac OS Menu Manager routine
				unsigned char pItemString[256];
				CopyCStringToPascal(text, pItemString);
				AppendMenuItemText((MenuHandle)menuRef, pItemString);
				return 0;
			#endif
		#endif
		#ifdef WINIGOR
			// appendmenu is provided by IGOR.lib on Windows
			appendmenu((MenuHandle)menuRef, text);
			return 0;
		#endif
	}
}

/*	XOPInsertMenuItem(menuRef, afterItemNumber, text)

	XOPInsertMenuItem inserts a menu item in the XOP menu specified by menuRef.

	menuRef is a reference to an XOP menu.
	
	afterItemNumber is a 1-based item number. Pass 0 to insert the menu item
	at the beginning of the menu. Pass n to insert the item after existing
	item n of the menu.
	
	text is C string (null-terminated) of 255 characters or less.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces insertmenuitem.
	
	Thread Safety: XOPInsertMenuItem is not thread-safe.
*/
int
XOPInsertMenuItem(XOPMenuRef menuRef, int afterItemNumber, const char* text)
{
	if (!CheckRunningInMainThread("XOPInsertMenuItem"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack3(XOP_INSERT_MENU_ITEM, menuRef, XOP_CALLBACK_INT(afterItemNumber), (void*)text);
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// InsertMenuItem is a Mac OS Menu Manager routine
				unsigned char pItemString[256];
				CopyCStringToPascal(text, pItemString);
				InsertMenuItem((MenuHandle)menuRef, pItemString, (MenuItemIndex)afterItemNumber);
				return 0;
			#endif
		#endif
		#ifdef WINIGOR
			// insertmenuitem is provided by IGOR.lib on Windows
			insertmenuitem((MenuHandle)menuRef, text, (short)afterItemNumber);
			return 0;
		#endif
	}
}

/*	XOPDeleteMenuItem(menuRef, itemNumber)

	XOPDeleteMenuItem removes the menu item specified by menuRef and itemNumber
	from an XOP menu.

	menuRef is a reference to an XOP menu.
	
	itemNumber is a 1-based item number.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces DeleteMenuItem.
	
	Thread Safety: XOPDeleteMenuItem is not thread-safe.
*/
int
XOPDeleteMenuItem(XOPMenuRef menuRef, int itemNumber)
{
	if (!CheckRunningInMainThread("XOPDeleteMenuItem"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack2(XOP_DELETE_MENU_ITEM, menuRef, XOP_CALLBACK_INT(itemNumber));
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#if defined(MACIGOR) && defined(IGOR64)		// Compiling 64-bit Macintosh XOP?
			// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
			// The Mac OS Menu Manager does not exist in 64 bits.
			return 0;
		#else
			// DeleteMenuItem is a Mac OS Menu Manager call on Macintosh and is emulated by IGOR.lib on Windows.
			DeleteMenuItem((MenuHandle)menuRef, (short)itemNumber);
			return 0;
		#endif
	}
}

/*	XOPDeleteMenuItemRange(menuRef, firstMenuItemNumber, lastMenuItemNumber)

	XOPDeleteMenuItemRange removes a range of menu items from an XOP menu.

	menuRef is a reference to an XOP menu.
	
	firstMenuItemNumber and lastMenuItemNumber are 1-based item numbers.
	They are clipped to the range of valid item numbers so you can pass 1
	for firstMenuItemNumber and 10000 for lastMenuItemNumber to delete all
	items from the menu.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces WMDeleteMenuItems.
	
	Thread Safety: XOPDeleteMenuItemRange is not thread-safe.
*/
int
XOPDeleteMenuItemRange(XOPMenuRef menuRef, int firstMenuItemNumber, int lastMenuItemNumber)
{
	if (!CheckRunningInMainThread("XOPDeleteMenuItemRange"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		// Igor clips firstMenuItemNumber lastMenuItemNumber to valid range
		int err = (int)CallBack3(XOP_DELETE_MENU_ITEM_RANGE, menuRef, XOP_CALLBACK_INT(firstMenuItemNumber), XOP_CALLBACK_INT(lastMenuItemNumber));
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#if defined(MACIGOR) && defined(IGOR64)		// Compiling 64-bit Macintosh XOP?
			// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
			// The Mac OS Menu Manager does not exist in 64 bits.
			return 0;
		#else
			int totalNumItemsInMenu, itemNumber;
			if (firstMenuItemNumber < 1)
				firstMenuItemNumber = 1;
			totalNumItemsInMenu = XOPCountMenuItems(menuRef);
			if (lastMenuItemNumber > totalNumItemsInMenu)
				lastMenuItemNumber = totalNumItemsInMenu;
			for(itemNumber=lastMenuItemNumber; itemNumber>=firstMenuItemNumber; itemNumber-=1)
				DeleteMenuItem((MenuHandle)menuRef, itemNumber);	// DeleteMenuItem is a Mac OS Menu Manager call on Macintosh and is emulated by IGOR.lib on Windows.
			return 0;
		#endif
	}
}

/*	XOPEnableMenuItem(menuRef, itemNumber)

	XOPEnableMenuItem enables the specified item.

	menuRef is a reference to an XOP menu or an Igor menu.
	
	itemNumber is a 1-based item number.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces EnableItem.
	
	Thread Safety: XOPEnableMenuItem is not thread-safe.
*/
int
XOPEnableMenuItem(XOPMenuRef menuRef, int itemNumber)
{
	if (!CheckRunningInMainThread("XOPEnableMenuItem"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack2(XOP_ENABLE_MENU_ITEM, menuRef, XOP_CALLBACK_INT(itemNumber));
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// EnableMenuItem is a Mac OS Menu Manager routine
				EnableMenuItem((MenuHandle)menuRef, (MenuItemIndex)itemNumber);
				return 0;
			#endif
		#endif
		#ifdef WINIGOR
			// EnableItem is provided by IGOR.lib on Windows
			EnableItem((MenuHandle)menuRef, (short)itemNumber);
			return 0;
		#endif
	}
}

/*	XOPDisableMenuItem(menuRef, itemNumber)

	XOPDisableMenuItem disables the specified item.

	menuRef is a reference to an XOP menu or an Igor menu.
	
	itemNumber is a 1-based item number.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces DisableItem.
	
	Thread Safety: XOPDisableMenuItem is not thread-safe.
*/
int
XOPDisableMenuItem(XOPMenuRef menuRef, int itemNumber)
{
	if (!CheckRunningInMainThread("XOPDisableMenuItem"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack2(XOP_DISABLE_MENU_ITEM, menuRef, XOP_CALLBACK_INT(itemNumber));
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// DisableMenuItem is a Mac OS Menu Manager routine
				DisableMenuItem((MenuHandle)menuRef, (MenuItemIndex)itemNumber);
				return 0;
			#endif
		#endif
		#ifdef WINIGOR
			// DisableItem is provided by IGOR.lib on Windows
			DisableItem((MenuHandle)menuRef, (short)itemNumber);
			return 0;
		#endif
	}
}

/*	XOPCheckMenuItem(menuRef, itemNumber, state)

	XOPCheckMenuItem adds or removes a checkmark from a menu item.

	menuRef is a reference to an XOP menu or an Igor menu.
	
	itemNumber is a 1-based item number.
	
	state is 1 for a checkmark or 0 to any checkmark.
	
	Returns 0 for success or an error code.
	
	See MenuXOP1.cpp for an example.

	Added in Igor Pro 6.32 but works with any version.
	
	Replaces CheckItem.
	
	Thread Safety: XOPCheckMenuItem is not thread-safe.
*/
int
XOPCheckMenuItem(XOPMenuRef menuRef, int itemNumber, int state)
{
	if (!CheckRunningInMainThread("XOPCheckMenuItem"))
		return NOT_IN_THREADSAFE;

	if (igorVersion >= 632) {
		int err = (int)CallBack3(XOP_CHECK_MENU_ITEM, menuRef, XOP_CALLBACK_INT(itemNumber), XOP_CALLBACK_INT(state));
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		#ifdef MACIGOR
			#ifdef IGOR64			// Compiling 64-bit XOP?
				// Can never execute because there was no 64-bit Igor Pro 6.31 or before.
				// The Mac OS Menu Manager does not exist in 64 bits.
				return 0;
			#else
				// CheckMenuItem is a Mac OS Menu Manager routine
				CheckMenuItem((MenuHandle)menuRef, (MenuItemIndex)itemNumber, state);
				return 0;
			#endif
		#endif
		#ifdef WINIGOR
			// CheckItem is provided by IGOR.lib on Windows
			CheckItem((MenuHandle)menuRef, (short)itemNumber, state);
			return 0;
		#endif
	}
}

/*	XOPFillMenu(menuRef, afterItemNumber, itemList)

	itemList is C string (null-terminated) containing a semicolon separated list
	of items to be put into the menu.

	afterItemNumber specifies where the items in itemList are to appear in the menu.
		afterItemNumber = 0				new items appear at beginning of menu
		afterItemNumber = 10000			new items appear at end of menu
		afterItemNumber = item number	new items appear after specified existing item number.

	XOPFillMenu supports Macintosh menu manager meta-characters in menu items. For example,
	if a "(" character appears in the item list, it will not be displayed in the corresponding
	menu item but instead will cause the item to be disabled. Use XOPFillMenuNoMeta if you don't
	want this behavior.
	
	Returns 0 or an error code.

	Thread Safety: XOPFillMenu is not thread-safe.
*/
int
XOPFillMenu(XOPMenuRef menuRef, int afterItemNumber, const char *itemList)
{
	if (!CheckRunningInMainThread("XOPFillMenu"))
		return NOT_IN_THREADSAFE;
	
	if (igorVersion >= 632) {
		int err;
		
		// HR, 2016-03-10, XOP Toolkit 7.00B02: This test was missing
		if (afterItemNumber >= 10000)
			afterItemNumber = XOPCountMenuItems(menuRef);
		
		err = (int)CallBack3(XOP_FILL_MENU, menuRef, XOP_CALLBACK_INT(afterItemNumber), (void*)itemList);
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		const char *p1;
		const char *p2;
		char item[256];
		int len, itemLen, itemListLen;

		// HR, 2016-03-10, XOP Toolkit 7.00B02: This test was missing
		if (afterItemNumber >= 10000)
			afterItemNumber = XOPCountMenuItems(menuRef);

		itemListLen = (int)strlen(itemList);
		p1 = itemList;
		while (itemListLen > 0) {
			if (p2 = strchr(p1, ';'))
				len = (int)(p2 - p1);
			else
				len = itemListLen;					/* last one */
			itemLen = len;
			if (itemLen > 255)
				itemLen = 255;
			strncpy(item, p1, itemLen);
			item[itemLen] = 0;
			XOPInsertMenuItem(menuRef, afterItemNumber, item);
			p1 += len+1;
			itemListLen -= len+1;
			afterItemNumber += 1;
		}
	}
	return 0;
}

/*	XOPFillMenuNoMeta(menuRef, afterItemNumber, itemList)

	XOPFillMenuNoMeta works exactly like XOPFillMenu except that it does not honor
	meta-characters.
	
	Meta-characters include the following:
		/				Creates a keyboard equivalent
		(				Disables a menu item

	Use XOPFillMenuNoMeta if you want these characters to appear in the menu item.
	XOPFillMenu interprets them as special characters.

	itemList is C string (null-terminated) containing a semicolon separated list
	of items to be put into the menu.

	afterItemNumber specifies where the items in itemList are to appear in the menu.
		afterItemNumber = 0				new items appear at beginning of menu
		afterItemNumber = 10000			new items appear at end of menu
		afterItemNumber = item number	new items appear after specified existing item number.
	
	Returns 0 or an error code.
	
	Thread Safety: XOPFillMenuNoMeta is not thread-safe.
*/
int
XOPFillMenuNoMeta(XOPMenuRef menuRef, int afterItemNumber, const char *itemList)
{
	if (!CheckRunningInMainThread("XOPFillMenuNoMeta"))
		return NOT_IN_THREADSAFE;
	
	if (igorVersion >= 632) {
		int err;
		
		// HR, 2016-03-10, XOP Toolkit 7.00B02: This test was missing
		if (afterItemNumber >= 10000)
			afterItemNumber = XOPCountMenuItems(menuRef);
		
		err = (int)CallBack3(XOP_FILL_MENU_NO_META, menuRef, XOP_CALLBACK_INT(afterItemNumber), (void*)itemList);
		return err;	
	}
	
	// Here if Igor is 6.31 or before
	{
		const char *p1;
		const char *p2;
		char itemText[256];
		int len, itemLen, itemListLen;
		int newItemNumber;
		
		newItemNumber = afterItemNumber + 1;
		if (newItemNumber > 10000)
			newItemNumber = XOPCountMenuItems(menuRef) + 1;

		itemListLen = (int)strlen(itemList);
		p1 = itemList;
		while (itemListLen > 0) {
			if (p2 = strchr(p1, ';'))
				len = (int)(p2 - p1);
			else
				len = itemListLen;									// Last one.
			itemLen = len;
			if (itemLen > 255)
				itemLen = 255;
			strncpy(itemText, p1, itemLen);
			itemText[itemLen] = 0;
			XOPInsertMenuItem(menuRef, afterItemNumber, "x");
			XOPSetMenuItemText(menuRef, newItemNumber, itemText);	// This call does not treat certain characters as meta-characters.
			p1 += len+1;
			itemListLen -= len+1;
			afterItemNumber += 1;
			newItemNumber += 1;
		}
	}
	return 0;
}

static int
NullTerminateHandle(Handle h)		// Adds null byte to end of handle
{
	int len;
	int err;
	
	len = (int)GetHandleSize(h);
	SetHandleSize(h, len+1);
	err = MemError();
	if (err != 0)
		return err;
	(*h)[len] = 0;					// Add null terminator
	return 0;
}

/*	XOPFillWaveMenu(menuRef, match, options, afterItemNumber)

	Puts names of waves into the menu.
	
	match and options are as for the Igor WaveList function:
		match = "*" for all waves
		options = "" for all waves
		options = "WIN:Graph0" for waves in graph0 only.
	
	afterItemNumber is as for XOPFillMenu, described above.
	
	Thread Safety: XOPFillWaveMenu is not thread-safe.
*/
int
XOPFillWaveMenu(XOPMenuRef menuRef, const char *match, const char *options, int afterItemNumber)
{
	Handle listHandle;
	int err;	
	
	if (!CheckRunningInMainThread("XOPFillWaveMenu"))
		return NOT_IN_THREADSAFE;
	
	listHandle = NewHandle(0L);
	err = WaveList(listHandle, match, ";", options);
	if (err != 0) {
		DisposeHandle(listHandle);
		return err;
	}
	
	// Convert to C string by adding null terminator
	err = NullTerminateHandle(listHandle);
	if (err != 0) {
		DisposeHandle(listHandle);
		return err;
	}
	
	XOPFillMenuNoMeta(menuRef, afterItemNumber, *listHandle);
	
	DisposeHandle(listHandle);
	
	return err;
}

/*	XOPFillPathMenu(menuRef, match, options, afterItemNumber)

	Puts names of Igor paths into the menu.
	
	match and options are as for the Igor PathList function:
		match = "*" for all paths
		options = "" for all paths
	
	afterItemNumber is as for FillMenu, described above.
	
	Thread Safety: XOPFillPathMenu is not thread-safe.
*/
int
XOPFillPathMenu(XOPMenuRef menuRef, const char *match, const char *options, int afterItemNumber)
{
	Handle listHandle;
	int err;	
	
	if (!CheckRunningInMainThread("XOPFillPathMenu"))
		return NOT_IN_THREADSAFE;
	
	listHandle = NewHandle(0L);
	err = PathList(listHandle, match, ";", options);
	if (err != 0) {
		DisposeHandle(listHandle);
		return err;
	}
	
	// Convert to C string by adding null terminator
	err = NullTerminateHandle(listHandle);
	if (err != 0) {
		DisposeHandle(listHandle);
		return err;
	}
	
	XOPFillMenuNoMeta(menuRef, afterItemNumber, *listHandle);
	
	DisposeHandle(listHandle);
	
	return err;
}

/*	XOPFillWinMenu(menuRef, match, options, afterItemNumber)

	Puts names of Igor windows into the menu.
	
	match and options are as for the Igor WinList function:
		match = "*" for all windows
		options = "" for all windows
		options = "WIN: 1" for all graphs		( bit 0 selects graphs)
		options = "WIN: 2" for all tables		( bit 1 selects graphs)
		options = "WIN: 4" for all layouts		( bit 2 selects graphs)
		options = "WIN: 3" for all graphs and tables
	
	afterItemNumber is as for FillMenu, described above.
	
	Thread Safety: FillWinMenu is not thread-safe.
*/
int
XOPFillWinMenu(XOPMenuRef menuRef, const char *match, const char *options, int afterItemNumber)
{
	Handle listHandle;
	int err;	
	
	if (!CheckRunningInMainThread("XOPFillPathMenu"))
		return NOT_IN_THREADSAFE;
	
	listHandle = NewHandle(0L);
	err = WinList(listHandle, match, ";", options);
	if (err != 0) {
		DisposeHandle(listHandle);
		return err;
	}
	
	// Convert to C string by adding null terminator
	err = NullTerminateHandle(listHandle);
	if (err != 0) {
		DisposeHandle(listHandle);
		return err;
	}
	
	XOPFillMenuNoMeta(menuRef, afterItemNumber, *listHandle);
	
	DisposeHandle(listHandle);
	
	return err;
}

/*	ResourceToActualMenuID(int resourceMenuID)

	Given the ID of a MENU resource in the XOP's resource fork, returns the
	actual menu ID of that menu in memory.
	
	Returns 0 if XOP did not add this menu to Igor menu.
	
	Thread Safety: ResourceToActualMenuID is not thread-safe.
*/
int
ResourceToActualMenuID(int resourceMenuID)
{
	if (!CheckRunningInMainThread("ResourceToActualMenuID"))
		return 0;
	
	return (int)CallBack1(ACTUALMENUID, XOP_CALLBACK_INT(resourceMenuID));
}
	
/*	ActualToResourceMenuID(int menuID)

	Given the ID of a menu in memory, returns the resource ID of the MENU resource
	in the XOP's resource fork.
	
	Returns 0 if XOP did not add this menu to Igor menu.
	
	Thread Safety: ActualToResourceMenuID is not thread-safe.
*/
int
ActualToResourceMenuID(int menuID)
{
	if (!CheckRunningInMainThread("ActualToResourceMenuID"))
		return 0;
	
	return (int)CallBack1(RESOURCEMENUID, XOP_CALLBACK_INT(menuID));
}

/*	ResourceToActualItem(igorMenuID, resourceItemNumber)

	Given the ID of a built-in Igor menu and the number of a menu item specification
	in the XMI1 resource in the XOP's resource fork, returns the actual item number
	of that item in the Igor menu.
	
	Item numbers start from 1.
	
	Returns 0 if XOP did not add this menu item to Igor menu.
	
	Thread Safety: ResourceToActualItem is not thread-safe.
*/
int
ResourceToActualItem(int igorMenuID, int resourceItemNumber)
{
	if (!CheckRunningInMainThread("ResourceToActualItem"))
		return 0;
	
	return (int)CallBack2(ACTUALITEMNUM, XOP_CALLBACK_INT(igorMenuID), XOP_CALLBACK_INT(resourceItemNumber));
}
	
/*	ActualToResourceItem(igorMenuID, actualItemNumber)

	Given the ID of a built-in Igor menu and the actual number of a menu item in the Igor menu,
	returns the number of the specification in the XMI1 resource in the XOP's resource fork
	for that item.
	
	Item numbers start from 1.
	
	Returns 0 if XOP did not add this menu item to Igor menu.
	
	Thread Safety: ActualToResourceItem is not thread-safe.
*/
int
ActualToResourceItem(int igorMenuID, int actualItemNumber)
{
	if (!CheckRunningInMainThread("ActualToResourceItem"))
		return 0;
	
	return (int)CallBack2(RESOURCEITEMNUM, XOP_CALLBACK_INT(igorMenuID), XOP_CALLBACK_INT(actualItemNumber));
}

/*	SetIgorMenuItem(message, enable, text, param)

	Enables or disables a built-in Igor menu item.
	
	message is a message code that Igor normally passes to the XOP, such as COPY, CUT, PASTE.
	enable is 1 to enable the corresponding item, 0 to disable.
	text is normally NULL.
	
	However, if the menu item text is variable and text is not NULL, Igor will set
	the item to the specified text.
	param is normally not used and should be 0.
	However, for the FIND message, param is as follows:
		1 to set the Find item
		2 to set the Find Same item
		3 to set the Find Selected Text item.
	
	The function result is 1 if there exists a built-in Igor menu item corresponding
	to the message or zero otherwise. Normally, you can ignore this result.
	
	Thread Safety: SetIgorMenuItem is not thread-safe.
*/
int
SetIgorMenuItem(int message, int enable, const char* text, int param)
{
	if (!CheckRunningInMainThread("SetIgorMenuItem"))
		return 0;
	
	return (int)CallBack4(SETIGORMENUITEM, XOP_CALLBACK_INT(message), XOP_CALLBACK_INT(enable), (void*)text, XOP_CALLBACK_INT(param));
}
