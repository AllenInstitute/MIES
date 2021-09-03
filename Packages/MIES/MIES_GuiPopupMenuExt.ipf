#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_GUIPOPUPEXT
#endif

/// @file MIES_GuiPopupMenuExt.ipf
/// @brief Helper functions related to GUI controls
///
/// @anchor PopupMenuExtensionShortDescription
///
/// These procedures provide a way to replace popup menus with many entries with context menus.
/// Context menus can provide submenus, that allow better organization of menu entries.
///
/// Example:
///
/// \rst
/// .. code-block:: igorpro
///
///    Function SetupPopupMenuExt()
///        KillWindow/Z panel0
///        NewPanel/N=$"panel0"/K=1
///        Button popupext_menu1, pos={3.00, 20.00}, size={200,20},proc=PEXT_ButtonProc,title="DropDownMenu1 ▼", userdata($PEXT_UDATA_POPUPPROC)="DemoProc", userdata($PEXT_UDATA_ITEMGETTER)="GetMenuList1"
///        Button popupext_menu2, pos={3.00, 55.00}, size={200,20},proc=PEXT_ButtonProc,title="DropDownMenu2 ▼", userdata($PEXT_UDATA_POPUPPROC)="DemoProc", userdata($PEXT_UDATA_ITEMGETTER)="GetMenuList2"
///        Button popupext_menu3, pos={3.00, 90.00}, size={200,20},proc=PEXT_ButtonProc,title="DropDownMenu3 ▼", userdata($PEXT_UDATA_POPUPPROC)="DemoProc", userdata($PEXT_UDATA_ITEMGETTER)="GetMenuList3"
///    End
///
///    Function DemoProc(pa) : PopupMenuControl
///        STRUCT WMPopupAction &pa
///
///        print "EventCode/Win/Selected/ctrlName: ", pa.eventCode, pa.win, pa.popStr, pa.ctrlName
///    End
///
///    Function/S GetMenuList1()
///
///        Make/FREE/T/N=300 testItems = num2char(97 + mod(p, 26)) + "_" + num2str(p)
///        return TextWaveToList(testItems, ";")
///    End
///
///    Function/WAVE GetMenuList2(panelTitle)
///        string panelTitle
///
///        Make/FREE/T/N=(2) menus
///        menus[0] = "Kriemhild;Brünhild"
///        menus[1] = "Siegfried;Gunther"
///        SetDimLabel ROWS, 0, $"Women", menus
///        SetDimLabel ROWS, 1, $"Men", menus
///
///        return menus
///    End
///
///    Function/WAVE GetMenuList3(panelTitle)
///        string panelTitle
///
///        Make/FREE/T menus = {"Kriemhild", "Brünhild", "Siegfried", "Gunther"}
///        WAVE/T splitMenu = PEXT_SplitToSubMenus(menus, method = PEXT_SUBSPLIT_ALPHA)
///        PEXT_GenerateSubMenuNames(splitMenu)
///        return splitMenu
///    End
/// \endrst
///
/// The original popupmenu has to be replaced by a button with the PEXT_ButtonProc as procedure. The userdata of the
/// button stores as list with key value pairs a function that returns the menu item list and a function that is the
/// PopupMenuControl procecure of the former popupmenu. The function for the menu item list corresponds to the function
/// given for a popupmenu as e.g. value=GetMenuList1() that returns a string with semicolon separated list of menu items.
/// The names for the submenus are generated automatically in that case.
/// If one wants to disable the menu, return "" as menu item list. Then a disabled "_none_" is shown that can not be selected.
///
///
/// The constants PEXT_UDATA_ITEMGETTER and PEXT_UDATA_POPUPPROC were defined for the keys in the userdata string.
///
/// When a user selects an entry in the context menu the PopupMenuControl control defined through PEXT_UDATA_POPUPPROC is called.
/// So the proc of the previous popupmenu can be used without further adaptations.
///
/// User defined sub menus:
///
/// User defined submenus can be created as well. Therefore an extension was added to the function that returns the menu items.
/// Instead of a string as described before a function can be defined that returns a 1D text wave, e.g. GetMenuList2() in the example.
/// Each element contains a semicolon separated list of menu items. Each rows DimLabel is used as submenu name, where the elements
/// menu items are put. The DimLabels must not be empty. The wave can have up to MAX_SUBMENUS elements.
/// The button popupext_menu2 shows this extension in the example.
///
/// Half automatic generation:
///
/// Example 3 from Button popupext_menu3 shows how a menu is created by defining a wave with menu items first.
/// Then the menu items are split to sub menus with PEXT_SplitToSubMenus using the method PEXT_SUBSPLIT_ALPHA.
/// In the second step the sub menu named are generated with the default algorithm by calling PEXT_GenerateSubMenuNames.
///
/// Method Description
///
/// PEXT_SUBSPLIT_DEFAULT
///
/// In each sub menu up to NUM_SUBENTRIES menu items are placed.
/// If MAX_SUBMENUS number of sub menus are reached then the remaining menu items are placed in the last sub menu.
///
/// PEXT_SUBSPLIT_ALPHA
///
/// In each sub menu up to NUM_SUBENTRIES menu items are placed. If the beginning letter of the last menu item in the sub menu differs from the
/// beginning letter of the first menu item then the menu items in the sub menu get reduced. All menu item beginning with the letter of the last menu item
/// are moved to the next sub menu.
/// If the beginning letters match then no menu items get moved.
/// If MAX_SUBMENUS number of sub menus are reached then the remaining menu items are placed in the last sub menu.
///
/// PEXT_SUBNAMEGEN_DEFAULT
///
/// In a sub menu from the first and last menu item the number of letters from the beginning is counted until the letters do not match. This part of the
/// menu item is used and taken as a sub menu name in a range notation: Alfons, Aluminium -> Alf .. Alu
/// This is also applied between different sub menus, so the last menu item and the first menu item of the next sub menu.
/// If in the previous sub menu the number of letters determined for the last menu item is higher then for the first name component the higher amount is taken:
/// e.g. Balalaika, Cembalo -> B .. C -> Bal .. C (because Alu were three letters)

static Constant MAX_SUBMENUS = 12
static StrConstant WAVE_NOTE_PROCNAME = "PROC"
static StrConstant WAVE_NOTE_WINDOWNAME = "WINNAME"
static StrConstant WAVE_NOTE_CTRLNAME = "CTRLNAME"
static StrConstant MENUNAME_UNUSED = "*** bug, report to dev ***"
static StrConstant MENU_DISABLE_SPECIAL = "\\M0"
static StrConstant LSEP = ";"

/// @brief Menu definition templates for up to MAX_SUBMENUS sub menus.
///        The constant MAX_SUBMENUS stores the number of these definitions
///        and must be updated if more definitions are added.
///
Menu "PopupExt1", contextualmenu, dynamic
	PEXT_PopupMenuItems(0), /Q, ;
End

Menu "PopupExt2", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
End

Menu "PopupExt3", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
End

Menu "PopupExt4", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
	SubMenu PEXT_SubMenuName(3)
		PEXT_PopupMenuItems(3), /Q, ;
	End
End

Menu "PopupExt5", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
	SubMenu PEXT_SubMenuName(3)
		PEXT_PopupMenuItems(3), /Q, ;
	End
	SubMenu PEXT_SubMenuName(4)
		PEXT_PopupMenuItems(4), /Q, ;
	End
End

Menu "PopupExt6", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
	SubMenu PEXT_SubMenuName(3)
		PEXT_PopupMenuItems(3), /Q, ;
	End
	SubMenu PEXT_SubMenuName(4)
		PEXT_PopupMenuItems(4), /Q, ;
	End
	SubMenu PEXT_SubMenuName(5)
		PEXT_PopupMenuItems(5), /Q, ;
	End
End

Menu "PopupExt7", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
	SubMenu PEXT_SubMenuName(3)
		PEXT_PopupMenuItems(3), /Q, ;
	End
	SubMenu PEXT_SubMenuName(4)
		PEXT_PopupMenuItems(4), /Q, ;
	End
	SubMenu PEXT_SubMenuName(5)
		PEXT_PopupMenuItems(5), /Q, ;
	End
	SubMenu PEXT_SubMenuName(6)
		PEXT_PopupMenuItems(6), /Q, ;
	End
End

Menu "PopupExt8", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
	SubMenu PEXT_SubMenuName(3)
		PEXT_PopupMenuItems(3), /Q, ;
	End
	SubMenu PEXT_SubMenuName(4)
		PEXT_PopupMenuItems(4), /Q, ;
	End
	SubMenu PEXT_SubMenuName(5)
		PEXT_PopupMenuItems(5), /Q, ;
	End
	SubMenu PEXT_SubMenuName(6)
		PEXT_PopupMenuItems(6), /Q, ;
	End
	SubMenu PEXT_SubMenuName(7)
		PEXT_PopupMenuItems(7), /Q, ;
	End
End

Menu "PopupExt9", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
	SubMenu PEXT_SubMenuName(3)
		PEXT_PopupMenuItems(3), /Q, ;
	End
	SubMenu PEXT_SubMenuName(4)
		PEXT_PopupMenuItems(4), /Q, ;
	End
	SubMenu PEXT_SubMenuName(5)
		PEXT_PopupMenuItems(5), /Q, ;
	End
	SubMenu PEXT_SubMenuName(6)
		PEXT_PopupMenuItems(6), /Q, ;
	End
	SubMenu PEXT_SubMenuName(7)
		PEXT_PopupMenuItems(7), /Q, ;
	End
	SubMenu PEXT_SubMenuName(8)
		PEXT_PopupMenuItems(8), /Q, ;
	End
End

Menu "PopupExt10", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
	SubMenu PEXT_SubMenuName(3)
		PEXT_PopupMenuItems(3), /Q, ;
	End
	SubMenu PEXT_SubMenuName(4)
		PEXT_PopupMenuItems(4), /Q, ;
	End
	SubMenu PEXT_SubMenuName(5)
		PEXT_PopupMenuItems(5), /Q, ;
	End
	SubMenu PEXT_SubMenuName(6)
		PEXT_PopupMenuItems(6), /Q, ;
	End
	SubMenu PEXT_SubMenuName(7)
		PEXT_PopupMenuItems(7), /Q, ;
	End
	SubMenu PEXT_SubMenuName(8)
		PEXT_PopupMenuItems(8), /Q, ;
	End
	SubMenu PEXT_SubMenuName(9)
		PEXT_PopupMenuItems(9), /Q, ;
	End
End

Menu "PopupExt11", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
	SubMenu PEXT_SubMenuName(3)
		PEXT_PopupMenuItems(3), /Q, ;
	End
	SubMenu PEXT_SubMenuName(4)
		PEXT_PopupMenuItems(4), /Q, ;
	End
	SubMenu PEXT_SubMenuName(5)
		PEXT_PopupMenuItems(5), /Q, ;
	End
	SubMenu PEXT_SubMenuName(6)
		PEXT_PopupMenuItems(6), /Q, ;
	End
	SubMenu PEXT_SubMenuName(7)
		PEXT_PopupMenuItems(7), /Q, ;
	End
	SubMenu PEXT_SubMenuName(8)
		PEXT_PopupMenuItems(8), /Q, ;
	End
	SubMenu PEXT_SubMenuName(9)
		PEXT_PopupMenuItems(9), /Q, ;
	End
	SubMenu PEXT_SubMenuName(10)
		PEXT_PopupMenuItems(10), /Q, ;
	End
End

Menu "PopupExt12", contextualmenu, dynamic
	SubMenu PEXT_SubMenuName(0)
		PEXT_PopupMenuItems(0), /Q, ;
	End
	SubMenu PEXT_SubMenuName(1)
		PEXT_PopupMenuItems(1), /Q, ;
	End
	SubMenu PEXT_SubMenuName(2)
		PEXT_PopupMenuItems(2), /Q, ;
	End
	SubMenu PEXT_SubMenuName(3)
		PEXT_PopupMenuItems(3), /Q, ;
	End
	SubMenu PEXT_SubMenuName(4)
		PEXT_PopupMenuItems(4), /Q, ;
	End
	SubMenu PEXT_SubMenuName(5)
		PEXT_PopupMenuItems(5), /Q, ;
	End
	SubMenu PEXT_SubMenuName(6)
		PEXT_PopupMenuItems(6), /Q, ;
	End
	SubMenu PEXT_SubMenuName(7)
		PEXT_PopupMenuItems(7), /Q, ;
	End
	SubMenu PEXT_SubMenuName(8)
		PEXT_PopupMenuItems(8), /Q, ;
	End
	SubMenu PEXT_SubMenuName(9)
		PEXT_PopupMenuItems(9), /Q, ;
	End
	SubMenu PEXT_SubMenuName(10)
		PEXT_PopupMenuItems(10), /Q, ;
	End
	SubMenu PEXT_SubMenuName(11)
		PEXT_PopupMenuItems(11), /Q, ;
	End
End

/// @brief Returns sub menu names for all PEXT sub menus
///        This is called on each menu click/compilation for all dynamic defined Menus
///        where PEXT_SubMenuName is used.
///
/// @param subMenuNr number of current sub menu
Function/S PEXT_SubMenuName(subMenuNr)
	variable subMenuNr

	string s

	WAVE/T itemListWave = GetPopupExtMenuWave()
	variable subMenuCnt = DimSize(itemListWave, ROWS)

	if(subMenuNr >= subMenuCnt)
		return MENUNAME_UNUSED
	endif

	s = GetDimLabel(itemListWave, ROWS, subMenuNr)
	if(IsEmpty(s))
		return MENUNAME_UNUSED
	endif

	return MENU_DISABLE_SPECIAL + s
End

/// @brief Returns menu items for all PEXT menus
///        This is called on each menu click/compilation for all dynamic defined Menus
///        where PEXT_PopupMenuItems is used.
///
/// @param subMenuNr number of current sub menu
Function/S PEXT_PopupMenuItems(subMenuNr)
	variable subMenuNr

	WAVE/T itemListWave = GetPopupExtMenuWave()
	variable subMenuCnt = DimSize(itemListWave, ROWS)

	if(subMenuNr >= subMenuCnt)
		return ""
	endif

	return itemListWave[subMenuNr]
End

/// @brief This callback is executed when the user selected a PEXT dynamic menu item.
///        It is not called if the user aborted the menu by clicking somewhere else.
///
/// @param popupStr popup string
/// @param text selected menu item text
/// @param itemNum selected item index in submenu
Function PEXT_Callback(string popupStr,string text,variable itemNum)

	STRUCT WMPopupAction pa

	WAVE/T itemListWave = GetPopupExtMenuWave()

	if(IsEmpty(text) && itemNum == 0)
		Redimension/N=0 itemListWave
		return 0
	endif

	pa.ctrlName = GetStringFromWaveNote(itemListWave, WAVE_NOTE_CTRLNAME)
	pa.eventCode = 2
	pa.eventMod = 0
	pa.popNum = NaN
	pa.popStr = text
	pa.win = GetStringFromWaveNote(itemListWave, WAVE_NOTE_WINDOWNAME)

	FUNCREF PEXT_POPUPACTION_PROTO popupAction = $GetStringFromWaveNote(itemListWave, WAVE_NOTE_PROCNAME)
	note/K itemListWave
	ASSERT(FuncRefIsAssigned(FuncRefInfo(popupAction)), "Popup extension action has wrong function template format")

	popupAction(pa)
End

/// @brief Prototype for the menu item getter that allows user defined
///        sub menu attribution of menu items
///
Function/S PEXT_ITEMGETTER_LIST_PROTO()
End

/// @brief Prototype for the menu item getter that is compatible with the
///        former popupmenu value=procedure definition.
///
Function/WAVE PEXT_ITEMGETTER_WAVE_PROTO(panelTitle)
	string panelTitle
End

/// @brief Prototype for the former popupaction procedure, that is only
///        called virtually now through the PopupContextualMenu callback.
///
/// @param pa WMPopupAction structure
Function PEXT_POPUPACTION_PROTO(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
End

/// @brief Generic procedure for button actions from popup extension controls
///        Fills the global popupExtMenuInfo wave with current menu setup information
///        retrieved from the function defined in the buttons userdata through PEXT_UDATA_ITEMGETTER key.
///        This getter function can either return a string or 1D text wave.
///
/// @param ba WMButtonAction structure
Function PEXT_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string itemGetter, itemList

	switch(ba.eventCode)
		case 2:

			WAVE/T itemListWave = GetPopupExtMenuWave()
			SetStringInWaveNote(itemListWave, WAVE_NOTE_WINDOWNAME, ba.win)

			SetStringInWaveNote(itemListWave, WAVE_NOTE_PROCNAME, GetUserData(ba.win, ba.ctrlName, PEXT_UDATA_POPUPPROC))
			SetStringInWaveNote(itemListWave, WAVE_NOTE_CTRLNAME, ba.ctrlName)

			itemGetter = GetUserData(ba.win, ba.ctrlName, PEXT_UDATA_ITEMGETTER)
			FUNCREF PEXT_ITEMGETTER_LIST_PROTO GetItemList = $itemGetter
			if(FuncRefIsAssigned(FuncRefInfo(GetItemList)))
				itemList = GetItemList()
				ASSERT(!IsNull(itemList), "Popup Extension got menu item list that is null.")
				WAVE/T itemWave = ListToTextWave(itemList, ";")
				WAVE/T splitMenu = PEXT_SplitToSubMenus(itemWave)
				PEXT_GenerateSubMenuNames(splitMenu)
				PEXT_VerifyAndSetMenuWave(splitMenu)
			else
				FUNCREF PEXT_ITEMGETTER_WAVE_PROTO GetItemWave = $itemGetter
				ASSERT(FuncRefIsAssigned(FuncRefInfo(GetItemWave)), "Popup extension item getter has wrong function template format")
				WAVE/T/Z itemWave = GetItemWave(ba.win)
				PEXT_VerifyAndSetMenuWave(itemWave)
			endif

			PopupContextualMenu/N/ASYN=PEXT_Callback "PopupExt" + num2str(DimSize(itemListWave, ROWS))
			break
	endswitch
	return 0
End

/// @brief Verifies menu data input wave and transfers it to global
static Function PEXT_VerifyAndSetMenuWave(menuWave)
	WAVE/T/Z menuWave

	variable subMenuCnt, i
	string subItem

	if(!WaveExists(menuWave))
		PEXT_SetDisabledMenu()
	else
		subMenuCnt = DimSize(menuWave, ROWS)
		if(!subMenuCnt)
			PEXT_SetDisabledMenu()
		else
			ASSERT(subMenuCnt <= MAX_SUBMENUS, "Menu definition wave has too many submenu entries.")

			WAVE/T itemListWave = GetPopupExtMenuWave()
			Redimension/N=(subMenuCnt) itemListWave

			for(i = 0; i < subMenuCnt; i++)
				subItem = GetDimLabel(menuWave, ROWS, i)
				ASSERT(!IsEmpty(subItem), "Defined sub menu entry is empty")
				SetDimLabel ROWS, i, $subItem, itemListWave
			endfor
			multithread itemListWave[] = MENU_DISABLE_SPECIAL + ReplaceString(LSEP, menuWave[p], LSEP + MENU_DISABLE_SPECIAL)
		endif
	endif
End

/// @brief Sets the menu to show a non selectable "_none_" entry.
static Function PEXT_SetDisabledMenu()

	WAVE/T itemListWave = GetPopupExtMenuWave()
	Redimension/N=1 itemListWave
	itemListWave = ""
	SetDimLabel ROWS, 0, $MENUNAME_UNUSED, itemListWave
End

/// @brief Automatically splits a 1D text wave with menu items to submenus
///        This function does not name submenus
///
/// @param[in] menuList 1d text wave with menu items
/// @param[in] method [optional, default = PEXT_SUBSPLIT_DEFAULT] sets how the menu items are split to sub menus @sa PEXT_SubMenuSplitting
/// @returns 1d text wave where each element contains a list of menu items. Each element represents a sub menu.
Function/WAVE PEXT_SplitToSubMenus(menuList[, method])
	WAVE/T/Z menuList
	variable method

	variable subMenuCnt, beginitem, endItem, i, j, numPerSubEntry
	variable numItems, remainItems, menuPos, subIndex, subMenuLength
	string begEntry, endEntry, checkEntry

	if(!WaveExists(menuList))
		return $""
	endif

	numItems = DimSize(menuList, ROWS)

	// we have up to MAX_SUBMENUS submenues
	// - more submenues with fewer entries are better than only a few ones with many entries
	numPerSubEntry = ceil(numItems / MAX_SUBMENUS / 10) * 10

	method = ParamIsDefault(method) ? PEXT_SUBSPLIT_DEFAULT : method

	if(method == PEXT_SUBSPLIT_DEFAULT)
		Sort/A menuList, menuList
		subMenuCnt = trunc(DimSize(menuList, ROWS) / numPerSubEntry) + 1
		subMenuCnt = subMenuCnt > MAX_SUBMENUS ? MAX_SUBMENUS : subMenuCnt

		Make/FREE/T/N=(subMenuCnt) splitMenu

		for(i = 0; i < subMenuCnt; i++)
			beginItem = i * numPerSubEntry
			endItem = i == subMenuCnt - 1 ? DimSize(menuList, ROWS) - 1 : beginItem + numPerSubEntry - 1

			for(j = beginitem; j < enditem; j++)
				splitMenu[i] = AddListItem(menuList[j], splitMenu[i], ";", Inf)
			endfor
		endfor

	elseif(method == PEXT_SUBSPLIT_ALPHA)
		Sort/A menuList, menuList

		Make/FREE/T/N=(MAX_SUBMENUS) splitMenu
		do
			remainItems = DimSize(menuList, ROWS) - menuPos
			if(remainItems < numPerSubEntry || subIndex == MAX_SUBMENUS - 1)
				subMenuLength = remainItems
			else
				begEntry = menuList[menuPos]
				endEntry = menuList[menuPos + numPerSubEntry - 1]
				if(!CmpStr(begEntry[0], endEntry[0]))
					subMenuLength = numPerSubEntry
				else
					subMenuLength = numPerSubEntry - 1
					do
						subMenuLength--
						checkEntry = menuList[menuPos + subMenuLength]
					while(!CmpStr(endEntry[0], checkEntry[0]))
					subMenuLength++
				endif
			endif

			for(i = 0; i < subMenuLength; i++)
				splitMenu[subIndex] = AddListItem(menuList[menuPos + i], splitMenu[subIndex], ";", Inf)
			endfor

			subIndex++;
			menuPos += subMenuLength
		while(menuPos < numItems)

		Redimension/N=(subIndex) splitMenu
	else
		ASSERT(0, "Unknown method for automatically splitting to submenus")
	endif

	return splitMenu
End

/// @brief Automatically generates submenu names and applies them on the given wave
///
/// @param[in] splitMenu 1d text wave with menu item lists for sub menus as returned by PEXT_SplitToSubMenus()
/// @param[in] method [optional, default = PEXT_SUBNAMEGEN_DEFAULT] sets how the sub menu names are generated @sa PEXT_SubMenuNameGeneration
Function PEXT_GenerateSubMenuNames(splitMenu[, method])
	WAVE/T/Z splitMenu
	variable method

	string subItemList, subItem
	variable subMenuCnt, i, j
	variable beginItem, endItem, endLen, minLen
	string begEntry, endEntry, s1, s2

	if(!WaveExists(splitMenu))
		return 0
	endif
	subMenuCnt = DimSize(splitMenu, ROWS)
	if(!subMenuCnt)
		return 0
	endif
	method = ParamIsDefault(method) ? PEXT_SUBNAMEGEN_DEFAULT : method

	if(method == PEXT_SUBNAMEGEN_DEFAULT)
		Make/FREE/T/N=(subMenuCnt * 2) subMenuBoundary, subMenuShort
		for(i = 0; i < subMenuCnt; i++)
			subItemList = splitMenu[i]
			ASSERT(!IsEmpty(subItemList), "menu item list for submenu is empty in splitMenu wave")
			subMenuBoundary[2 * i] = StringFromList(0, subItemList)
			subMenuBoundary[2 * i + 1] = StringFromList(ItemsInList(subItemList) - 1, subItemList)
		endfor

		minLen = 0
		for(i = 0; i < 2 * subMenuCnt - 1; i++)
			begEntry = subMenuBoundary[i]
			endEntry = subMenuBoundary[i + 1]
			endLen = min(strlen(begEntry), strlen(endEntry))
			s1 = ""
			s2 = ""

			for(j = 0; j < endLen; j++)
				s1 = s1 + begEntry[j]
				s2 = s2 + endEntry[j]
				if(CmpStr(s1, s2))
					break
				endif
			endfor
			if(j < minLen)
				s1 = begEntry[j, minLen]
			endif

			minLen = j
			subMenuShort[i] = s1
			if(i == 2 * subMenuCnt - 2)
				subMenuShort[i + 1] = s2
			endif
		endfor

		for(i = 0; i < subMenuCnt; i++)
			subItem = subMenuShort[2 * i] + " .. " + subMenuShort[2 * i + 1]
			SetDimLabel ROWS, i, $subItem, splitMenu
		endfor

	else
		ASSERT(0, "Unknown method for automatically generating submenus")
	endif
End
