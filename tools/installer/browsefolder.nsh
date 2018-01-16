!include LogicLib.nsh
!include WinMessages.nsh ; WM_USER
!define TV_FIRST  0x1100
!define /math TVM_GETNEXTITEM ${TV_FIRST} + 10
!define /math TVM_SELECTITEM ${TV_FIRST} + 11
!define /math TVM_ENSUREVISIBLE ${TV_FIRST} + 20
!define TVGN_FIRSTVISIBLE 0x5
!define TVGN_CARET 0x9
!define BFFM_INITIALIZED 1
!define BFFM_VALIDATEFAILEDA 3
!define BFFM_VALIDATEFAILEDW 4
!if "${NSIS_CHAR_SIZE}" > 1
!define BFFM_VALIDATEFAILED ${BFFM_VALIDATEFAILEDW}
!define /math BFFM_SETSELECTION ${WM_USER} + 103
!else
!define BFFM_VALIDATEFAILED ${BFFM_VALIDATEFAILEDA}
!define /math BFFM_SETSELECTION ${WM_USER} + 102
!endif


Function SHParseDisplayName ; NSIS 2.51+ INPUT:Path OUTPUT:Pidl
Exch $1
Push $2
System::Call 'SHELL32::SHParseDisplayName(w r1, p 0, *p 0r2, i 0, *i 0)i'
${If} $2 P= 0 ; SHParseDisplayName is XP+, this works everywhere but is not as clever
	Push $3
	System::Call 'SHELL32::SHGetDesktopFolder(*p.r3)' ; We leak this interface and don't care
	System::Call '$3->3(p0, p0, wr1, *i, *p.r2, *i0)'
	Pop $3
${EndIf}
StrCpy $1 $2
Pop $2
Exch $1
FunctionEnd

Function BrowseForFolder ; NSIS 2.51+ INPUT:RootPath, HeadingText, InitialPathSelection OUTPUT:Path
System::Store S
Pop $3 ; InitialPathSelection or ""
Pop $2 ; HeadingText
Pop $1 ; RootPath or ""
!macro BrowseForFolder_PathToPidl Path Pidl
StrCpy ${Pidl} ""
${If} "${Path}" != ""
	Push "${Path}"
	Call SHParseDisplayName
	Pop ${Pidl}
${EndIf}
!macroend
!insertmacro BrowseForFolder_PathToPidl $1 $6
System::Call SHLWAPI::IsOS(i0x25)i.r5
${IfThen} $5 <> 0 ${|} !insertmacro BrowseForFolder_PathToPidl $3 $5 ${|} ; Only do the callback on Vista+
!if "${NSIS_PTR_SIZE}" > 4 ; Callbacks currently not supported on AMD64
StrCpy $4 "p0"
StrCpy $R8 ""
StrCpy $R9 0
!else
System::Get "(p.R1, i.R2, p, p.R3)i R8R8" ; BFFCALLBACK
Pop $R9
StrCpy $4 "kR9"
!endif
System::Call '*(&t261 "")p.r7' ; pszDisplayName buffer
System::Call '*(p $hwndparent, pr6, pr7, t r2, i 0x41, $4, pr5, i)p.r8' ; BROWSEINFO struct
!if "${NSIS_CHAR_SIZE}" > 1
System::Call 'SHELL32::SHBrowseForFolderW(pr8)p.r9'
!else
System::Call 'SHELL32::SHBrowseForFolderA(pr8)p.r9'
!endif
BFFCALLBACK_loop:
	StrCpy $R8 $R8 8 ; HACKHACK: Working around 2.x bug where the callback IDs are never released
	StrCmp $R8 "callback" 0 BFFCALLBACK_done
	${If} $R2 = ${BFFM_INITIALIZED}
	${AndIf} $R3 P<> 0
		SendMessage $R1 ${BFFM_SETSELECTION} 0 $R3
		System::Store S
		StrCpy $2 0
		StrCpy $3 0
		loop: ; BFFM_SETSELECTION is buggy and does not scroll to the new item so we find the treeview and do it manually
			FindWindow $2 "" "" $R1 $2 ; Assuming SysTreeView32 is a grandchild when using BIF_NEWDIALOGSTYLE
			IntCmp 0 $2 done
			FindWindow $3 "SysTreeView32" "" $2
			IntCmp 0 $3 loop
			SendMessage $3 ${TVM_GETNEXTITEM} ${TVGN_CARET} 0 $4
			IntCmp 0 $3 done
			System::Call 'USER32::PostMessage(p$3,i${TVM_ENSUREVISIBLE},p0,p$4)'
		done:
		System::Store L
	${EndIf}
	StrCpy $R8 0 ; Yep, the return value is in the same place as the callback id
	${IfThen} $R2 = ${BFFM_VALIDATEFAILED} ${|} StrCpy $R8 1 ${|}
	System::Call $R9
	goto BFFCALLBACK_loop
BFFCALLBACK_done:
System::Free $R9
System::Free $7
System::Free $8
System::Call 'OLE32::CoTaskMemFree(p r5)'
System::Call 'OLE32::CoTaskMemFree(p r6)'
${If} $9 Z<> 0
	System::Call 'SHELL32::SHGetPathFromIDList(p r9, t.s)i'
	System::Call 'OLE32::CoTaskMemFree(p r9)'
${Else}
	Push "" ; Error/cancel, return empty string
${EndIf}
System::Store L
FunctionEnd
