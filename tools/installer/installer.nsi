!include "LogicLib.nsh"
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "setincnames.inc"
!include "${NSISVERSION}"

!define APPNAME "MIES"
!define COMPANYNAME "Allen Institute for Brain Science"
!define DESCRIPTION "Multipatch Intracellular Electrophysiology Data Acquisition"
!define APPICON "mies.ico"
# These will be displayed by the "Click here for support information" link in "Add/Remove Programs"
# It is possible to use "mailto:" links in here to open the email client
!define HELPURL "mailto:mies@alleninstitute.org" # "Support Information" link
!define UPDATEURL "mailto:mies@alleninstitute.org" # "Product Updates" link
!define ABOUTURL "http://www.alleninstitute.org" # "Publisher" link

# This is the size (in kB) of all the files copied to the HDD
!define INSTALLSIZE 77000

# Installation directory if installing as user
!define USERINSTDIR "$DOCUMENTS\${APPNAME}"

# This section defines paths
!define IGOR732EXTENSIONPATH "Igor Extensions"
!define IGOR764EXTENSIONPATH "Igor Extensions (64-bit)"
!define IGOR832EXTENSIONPATH "Igor Extensions"
!define IGOR864EXTENSIONPATH "Igor Extensions (64-bit)"
# Endings for Helpfiles- and Packages\HDF- folders
!define IGOR7DIRTEMPL "IP7"
!define IGOR8DIRTEMPL "IP8"
# source folder name for installation with XOPs
!define IGOR732XOPSOURCETEMPL "XOPs-IP7"
!define IGOR832XOPSOURCETEMPL "XOPs-IP8"
!define IGOR764XOPSOURCETEMPL "XOPs-IP7-64bit"
!define IGOR864XOPSOURCETEMPL "XOPs-IP8-64bit"
# source file names for HDF for installation without Hardware XOPs
!define IGOR732HDFXOPSOURCETEMPL "HDF5.xop - Shortcut"
!define IGOR832HDFXOPSOURCETEMPL "HDF5.xop - Shortcut"
!define IGOR764HDFXOPSOURCETEMPL "HDF5-64.xop - Shortcut"
!define IGOR864HDFXOPSOURCETEMPL "HDF5-64.xop - Shortcut"
# source file names for Utils for installation without Hardware XOPs
!define IGOR732UTILXOPSOURCETEMPL "MIESUtils.xop"
!define IGOR832UTILXOPSOURCETEMPL "MIESUtils.xop"
!define IGOR764UTILXOPSOURCETEMPL "MIESUtils-64.xop"
!define IGOR864UTILXOPSOURCETEMPL "MIESUtils-64.xop"
# source folder name for tango for installation with XOPs
!define IGOR732TANGOXOPSOURCETEMPL "XOP-tango"
!define IGOR764TANGOXOPSOURCETEMPL "XOP-tango-IP7-64bit"
!define IGOR832TANGOXOPSOURCETEMPL "XOP-tango"
!define IGOR864TANGOXOPSOURCETEMPL "XOP-tango-IP7-64bit"
# Default paths for Igor Installation where the installer looks automatically
!define IGOR7DEFPATH "$PROGRAMFILES64\WaveMetrics\Igor Pro 7 Folder"
!define IGOR8DEFPATH "$PROGRAMFILES64\WaveMetrics\Igor Pro 8 Folder"

#Unicode true
SetCompressor /SOLID lzma
!include "${NSISREQUEST}"
InstallDir "$PROGRAMFILES64\${APPNAME}"

# rtf or txt file - remember if it is txt, it must be in the DOS text format (\r\n)
LicenseData "..\..\LICENSE"
# This will be in the installer/uninstaller's title bar
Name "${COMPANYNAME} - ${APPNAME}"
Icon "${APPICON}"
UninstallIcon "${APPICON}"
!include "${NSISOUTFILE}"
XPStyle on

Page license
Page custom DialogAllCur
Page custom DialogXOP
Page custom DialogInstallFor78
Page directory
Page instfiles

Var IGOR64
Var IGOR32
Var IGOR64REGFILE
Var IGOR32REGFILE
Var IGOR64REGPATH
Var IGOR32REGPATH
Var ALLUSER
Var XOPINST
Var processFound
Var INSTALL_I732
Var INSTALL_I764
Var INSTALL_I7PATH
Var INSTALL_I832
Var INSTALL_I864
Var INSTALL_I8PATH
Var IGORBASEPATH
Var FILEHANDLE
Var LINESTR
Var ISADMIN

Var IGORDIRTEMPL
Var IGORBITDIRTEMPL
Var IGORHDFSOURCETEMPL
Var IGORUTILSOURCETEMPL
Var IGORTANGOSOURCETEMPL
Var IGOREXTENSIONPATH

#FindProc return value definitions
!define FindProc_NOT_FOUND 1
!define FindProc_FOUND 0

#GUI vars for All or Current User
Var NSD_AC_Dialog
Var NSD_AC_Label
Var NSD_AC_RB1
Var NSD_AC_RB2

#GUI vars for XOP Install
Var NSD_XOP_Dialog
Var NSD_XOP_Label
Var NSD_XOP_CB1

#GUI vars for InstallFor78
Var NSD_IF_Dialog
Var NSD_IF_Label
Var NSD_IF_CB1
Var NSD_IF_CB2
Var NSD_IF_CB3
Var NSD_IF_CB4

!include "browsefolder.nsh"

!macro PreventMultipleInstaller
  System::Call 'kernel32::CreateMutex(p 0, i 0, t "MIESINSTALLMutex") p .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +4
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
    Quit
!macroend

!macro PreventMultipleUninstaller
  System::Call 'kernel32::CreateMutex(p 0, i 0, t "MIESUNINSTALLMutex") p .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +4
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "The uninstaller is already running."
    Quit
!macroend

!macro FindProc result processName
  ExecCmd::exec "%SystemRoot%\System32\tasklist /NH /FI $\"IMAGENAME eq ${processName}$\" | %SystemRoot%\System32\find /I $\"${processName}$\""
  Pop $0 ; The handle for the process
  ExecCmd::wait $0
  Pop ${result} ; The exit code
!macroend

!macro CheckAllUninstalled
  StrCpy $2 "0"
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName"
  StrLen $1 $0
  ${If} $1 <> 0
    StrCpy $2 "1"
  ${EndIf}

  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName"
  StrLen $1 $0
  ${If} $1 <> 0
    StrCpy $2 "1"
  ${EndIf}

  IfFileExists "${USERINSTDIR}\uninstall.exe" 0 +2
    StrCpy $2 "1"

  IntCmp $2 0 +4
    ifSilent +2
      MessageBox MB_OK|MB_ICONSTOP "There is a already a installation of MIES present that was installed with administrative privileges. Uninstallation requires administrative privileges as well and can not be done with your current rights. Please contact an administrator to uninstall MIES through Add/Remove Programs first."
      Quit
!macroend

!macro UninstallAttemptAdmin
  IfSilent +3
    ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString"
    Goto +2
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString"
  StrLen $1 $0
  ${If} $1 <> 0
    ExecWait '$0'
  ${EndIf}
!macroend

!macro UninstallAttemptUser
# this check is just for compatibility with old installations
!define UODUID ${__LINE__}
  IfFileExists "${USERINSTDIR}\uninstall.exe" 0 UODUEnd_{UODUID}
    IfSilent +3
      ExecWait "${USERINSTDIR}\uninstall.exe"
      Goto +2
    ExecWait '"${USERINSTDIR}\uninstall.exe" /S'
  UODUEnd_{UODUID}:
!undef UODUID
  !insertmacro WaitForUninstaller

# this is the current check against registry
  IfSilent +3
    ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString"
    Goto +2
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString"
  StrLen $1 $0
  ${If} $1 <> 0
    ExecWait '$0'
  ${EndIf}
!macroend

!macro WaitForProc ProcName
!define WFPID ${__LINE__}
WFUWaitUninstA_${WFPID}:
    !insertmacro FindProc $processFound "${ProcName}"
    IntCmp $processFound ${FindProc_NOT_FOUND} WFUEndWaitUninstA_${WFPID}
      Sleep 100
      Goto WFUWaitUninstA_${WFPID}
WFUEndWaitUninstA_${WFPID}:
!undef WFPID
!macroend

!macro WaitForUninstaller
  !insertmacro WaitForProc "uninstall.exe"
  !insertmacro WaitForProc "Un_A.exe"
!macroend

!macro CheckIgor32
  StrCpy $IGOR32 "1"
  ReadRegStr $IGOR32REGPATH HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
  StrCpy $IGOR32REGFILE "$IGOR32REGPATH\Igor.exe"
  StrLen $0 $IGOR32REGPATH
  ${If} $0 = 0
    StrCpy $IGOR32 "0"
  ${EndIf}
!macroend

!macro CheckIgor64
  StrCpy $IGOR64 "1"
  ReadRegStr $IGOR64REGPATH HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor64.exe" "Path"
  StrCpy $IGOR64REGFILE "$IGOR64REGPATH\Igor64.exe"
  StrLen $0 $IGOR64REGPATH
  ${If} $0 = 0
    StrCpy $IGOR64 "0"
  ${EndIf}
!macroend

!macro StopOnIgor32
  !insertmacro FindProc $processFound "Igor.exe"
  IntCmp $processFound ${FindProc_NOT_FOUND} +4
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "Igor Pro is running. Please close it first" /SD IDOK
    Quit
!macroend

!macro StopOnIgor64
  !insertmacro FindProc $processFound "Igor64.exe"
  IntCmp $processFound ${FindProc_NOT_FOUND} +4
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "Igor Pro (64-bit) is running. Please close it first" /SD IDOK
    Quit
!macroend

#---Target User Dialog---

Function ClickedCurrentUser
  Pop $0
  ${NSD_GetState} $0 $1
  StrCpy $ALLUSER "0"
  IntCmp $1 ${BST_CHECKED} +2
    StrCpy $ALLUSER "1"
FunctionEnd

Function ClickedAllUser
  Pop $0
  ${NSD_GetState} $0 $1
  StrCpy $ALLUSER "1"
  IntCmp $1 ${BST_CHECKED} +2
    StrCpy $ALLUSER "0"
FunctionEnd

Function DialogAllCur
  nsDialogs::Create 1018
  Pop $NSD_AC_Dialog

  ${If} $NSD_AC_Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 90u 10u 100% 13u "Install for"
  Pop $NSD_AC_Label

  ${NSD_CreateRadioButton} 95u 35u 100% 13u "Current User"
  Pop $NSD_AC_RB1
  IntCmp $ALLUSER 1 +2
    ${NSD_Check} $NSD_AC_RB1
  ${NSD_OnClick} $NSD_AC_RB1 ClickedCurrentUser

  StrCpy $1 "All Users"
  UserInfo::GetAccountType
  pop $0
  ${If} $0 != "admin"
    StrCpy $1 "All Users (admin rights required)"
  ${EndIf}
  ${NSD_CreateRadioButton} 95u 48u 100% 13u $1
  Pop $NSD_AC_RB2
  IntCmp $ALLUSER 0 +2
    ${NSD_Check} $NSD_AC_RB2
  ${NSD_OnClick} $NSD_AC_RB2 ClickedAllUser

  IntCmp $ISADMIN 1 +2
    EnableWindow $NSD_AC_RB2 0
  nsDialogs::Show

  StrCpy $INSTDIR "$PROGRAMFILES64\${APPNAME}"
  IntCmp $ALLUSER 1 +2
    StrCpy $INSTDIR "${USERINSTDIR}"
FunctionEnd

#---Installation Type Dialog---

Function ClickedXOP
  Pop $0
  ${NSD_GetState} $0 $XOPINST
FunctionEnd

Function DialogXOP
  nsDialogs::Create 1018
  Pop $NSD_XOP_Dialog

  ${If} $NSD_XOP_Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 20u 0u 100% 12u "Select installation content"
  Pop $NSD_XOP_Label

  ${NSD_CreateCheckbox} 85u 13u 100% 13u "Include XOPs which require Hardware"
  Pop $NSD_XOP_CB1
  IntCmp $XOPINST 0 +2
    ${NSD_Check} $NSD_XOP_CB1
  ${NSD_OnClick} $NSD_XOP_CB1 ClickedXOP

  nsDialogs::Show
FunctionEnd

#---Install for Igor 7,8 Dialog---
!macro CheckIgorSel
!define CHECKIGSEL ${__LINE__}
  IntCmp $INSTALL_I732 1 EnableNext_${CHECKIGSEL}
    IntCmp $INSTALL_I764 1 EnableNext_${CHECKIGSEL}
      IntCmp $INSTALL_I832 1 EnableNext_${CHECKIGSEL}
        IntCmp $INSTALL_I864 1 EnableNext_${CHECKIGSEL}
          GetDlgItem $0 $HWNDPARENT 1
          EnableWindow $0 0
          Goto End_${CHECKIGSEL}
EnableNext_${CHECKIGSEL}:
  GetDlgItem $0 $HWNDPARENT 1
  EnableWindow $0 1
End_${CHECKIGSEL}:
!undef CHECKIGSEL
!macroend

Function ClickedIgor732
  Pop $0
  ${NSD_GetState} $0 $INSTALL_I732
  IntCmp $INSTALL_I732 0 EndSet
  StrLen $1 $INSTALL_I7PATH
  IntCmp $1 0 +2
    Goto EndSet
  MessageBox MB_OK "The installer can not find your Igor Pro 7 program folder. Please help."
  Push "" #Initial Pathselection
  Push "Choose Igor Pro 7 program folder" #Heading
  Push "$PROGRAMFILES64\WaveMetrics"  #Root Path
  Call BrowseForFolder
  Pop $1
  StrLen $2 $1
  IntCmp $2 0 BrowseCancel
    GetDLLVersion "$1\IgorBinaries_Win32\Igor.exe" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    IntCmp $R2 7 +3
      MessageBox MB_OK "Could not find the Igor Pro 7 executable. (at $1\IgorBinaries_Win32\Igor.exe)"
      Goto BrowseCancel
    StrCpy $INSTALL_I7PATH "$1"
    Goto EndSet
BrowseCancel:
  ${NSD_Uncheck} $0
  StrCpy $INSTALL_I732 "0"
EndSet:
  !insertmacro CheckIgorSel
FunctionEnd

Function ClickedIgor764
  Pop $0
  ${NSD_GetState} $0 $INSTALL_I764
  IntCmp $INSTALL_I764 0 EndSet
  StrLen $1 $INSTALL_I7PATH
  IntCmp $1 0 +2
    Goto EndSet
  MessageBox MB_OK "The installer can not find your Igor Pro 7 program folder. Please help."
  Push "" #Initial Pathselection
  Push "Choose Igor Pro 7 program folder" #Heading
  Push "$PROGRAMFILES64\WaveMetrics"  #Root Path
  Call BrowseForFolder
  Pop $1
  StrLen $2 $1
  IntCmp $2 0 BrowseCancel
    GetDLLVersion "$1\IgorBinaries_x64\Igor64.exe" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    IntCmp $R2 7 +3
      MessageBox MB_OK "Could not find the Igor Pro 7 executable. (at $1\IgorBinaries_x64\Igor64.exe)"
      Goto BrowseCancel
    StrCpy $INSTALL_I7PATH "$1"
    Goto EndSet
BrowseCancel:
  ${NSD_Uncheck} $0
  StrCpy $INSTALL_I764 "0"
EndSet:
  !insertmacro CheckIgorSel
FunctionEnd

Function ClickedIgor832
  Pop $0
  ${NSD_GetState} $0 $INSTALL_I832
  IntCmp $INSTALL_I832 0 EndSet
  StrLen $1 $INSTALL_I8PATH
  IntCmp $1 0 +2
    Goto EndSet
  MessageBox MB_OK "The installer can not find your Igor Pro 8 program folder. Please help."
  Push "" #Initial Pathselection
  Push "Choose Igor Pro 8 program folder" #Heading
  Push "$PROGRAMFILES64\WaveMetrics"  #Root Path
  Call BrowseForFolder
  Pop $1
  StrLen $2 $1
  IntCmp $2 0 BrowseCancel
    GetDLLVersion "$1\IgorBinaries_Win32\Igor.exe" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    IntCmp $R2 8 +3
      MessageBox MB_OK "Could not find the Igor Pro 8 executable. (at $1\IgorBinaries_Win32\Igor.exe)"
      Goto BrowseCancel
    StrCpy $INSTALL_I8PATH "$1"
    Goto EndSet
BrowseCancel:
  ${NSD_Uncheck} $0
  StrCpy $INSTALL_I832 "0"
EndSet:
  !insertmacro CheckIgorSel
FunctionEnd

Function ClickedIgor864
  Pop $0
  ${NSD_GetState} $0 $INSTALL_I864
  IntCmp $INSTALL_I864 0 EndSet
  StrLen $1 $INSTALL_I8PATH
  IntCmp $1 0 +2
    Goto EndSet
  MessageBox MB_OK "The installer can not find your Igor Pro 8 program folder. Please help."
  Push "" #Initial Pathselection
  Push "Choose Igor Pro 8 program folder" #Heading
  Push "$PROGRAMFILES64\WaveMetrics"  #Root Path
  Call BrowseForFolder
  Pop $1
  StrLen $2 $1
  IntCmp $2 0 BrowseCancel
    GetDLLVersion "$1\IgorBinaries_x64\Igor64.exe" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    IntCmp $R2 8 +3
      MessageBox MB_OK "Could not find the Igor Pro 8 executable. (at $1\IgorBinaries_x64\Igor64.exe)"
      Goto BrowseCancel
    StrCpy $INSTALL_I8PATH "$1"
    Goto EndSet
BrowseCancel:
  ${NSD_Uncheck} $0
  StrCpy $INSTALL_I864 "0"
EndSet:
  !insertmacro CheckIgorSel
FunctionEnd

Function DialogInstallFor78
  nsDialogs::Create 1018
  Pop $NSD_IF_Dialog

  ${If} $NSD_IF_Dialog == error
    Abort
  ${EndIf}

  !insertmacro CheckIgorSel
  ${NSD_CreateLabel} 20u 10u 100% 13u "Select Igor Pro version(s) where MIES should be included"
  Pop $NSD_IF_Label
  ${NSD_CreateCheckbox} 95u 23u 100% 13u "Igor Pro 7 32-bit"
  Pop $NSD_IF_CB1
  ${NSD_CreateCheckbox} 95u 36u 100% 13u "Igor Pro 7 64-bit"
  Pop $NSD_IF_CB2
  IntCmp $INSTALL_I732 0 NoIgor732
    ${NSD_Check} $NSD_IF_CB1
  NoIgor732:
  IntCmp $INSTALL_I764 0 NoIgor764
    ${NSD_Check} $NSD_IF_CB2
  NoIgor764:
  ${NSD_OnClick} $NSD_IF_CB1 ClickedIgor732
  ${NSD_OnClick} $NSD_IF_CB2 ClickedIgor764
  ${NSD_CreateCheckbox} 95u 49u 100% 13u "Igor Pro 8 32-bit"
  Pop $NSD_IF_CB3
  ${NSD_CreateCheckbox} 95u 62u 100% 13u "Igor Pro 8 64-bit"
  Pop $NSD_IF_CB4
  IntCmp $INSTALL_I832 0 NoIgor832
    ${NSD_Check} $NSD_IF_CB3
  NoIgor832:
  IntCmp $INSTALL_I864 0 NoIgor864
    ${NSD_Check} $NSD_IF_CB4
  NoIgor864:
  ${NSD_OnClick} $NSD_IF_CB3 ClickedIgor832
  ${NSD_OnClick} $NSD_IF_CB4 ClickedIgor864

  ${NSD_CreateLabel} 5u 88u 100% 26u "Using the 64-bit version is recommended as the 32-bit version will be discontinued at a later point."
  Pop $NSD_IF_Label

  nsDialogs::Show
FunctionEnd

function .onInit
  StrCpy $ALLUSER "0"
  StrCpy $XOPINST "1"

  StrCpy $ISADMIN "0"
  UserInfo::GetAccountType
  pop $0
  StrCmp $0 "admin" 0 +2
    StrCpy $ISADMIN "1"

  # Get Igor Path from Registry and check which version we have
  !insertmacro CheckIgor32
  IntCmp $IGOR32 0 NoRegIgor32
    GetDLLVersion "$IGOR32REGFILE" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    StrCpy $INSTALL_I732 "1"
    StrCpy $INSTALL_I832 "1"
    StrCpy $INSTALL_I7PATH $IGOR32REGPATH -17
    StrCpy $INSTALL_I8PATH $IGOR32REGPATH -17
    IntCmp $R2 7 CheckIgor832Path
      StrCpy $INSTALL_I732 "0"
      StrCpy $INSTALL_I7PATH ""
CheckIgor832Path:
    IntCmp $R2 8 NoRegIgor32
      StrCpy $INSTALL_I832 "0"
      StrCpy $INSTALL_I8PATH ""
NoRegIgor32:

  !insertmacro CheckIgor64
  IntCmp $IGOR64 0 NoRegIgor64
    GetDLLVersion "$IGOR64REGFILE" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    StrCpy $INSTALL_I764 "1"
    StrCpy $INSTALL_I864 "1"
    StrCpy $INSTALL_I7PATH $IGOR64REGPATH -17
    StrCpy $INSTALL_I8PATH $IGOR64REGPATH -17
    IntCmp $R2 7 CheckIgor864Path
      StrCpy $INSTALL_I764 "0"
      StrCpy $INSTALL_I7PATH ""
CheckIgor864Path:
    IntCmp $R2 8 NoRegIgor64
      StrCpy $INSTALL_I864 "0"
      StrCpy $INSTALL_I8PATH ""
NoRegIgor64:

# Look for Igor7,8 at default install folder, if not already known
  StrLen $0 $INSTALL_I7PATH
  IntCmp $0 0 +2
    Goto Igor7CheckEnd
  GetDLLVersion "${IGOR7DEFPATH}\IgorBinaries_x64\Igor64.exe" $R0 $R1
  IntOp $R2 $R0 / 0x00010000
  IntCmp $R2 7 +2
    Goto Igor764CheckEnd
  StrCpy $INSTALL_I7PATH "${IGOR7DEFPATH}"
  StrCpy $INSTALL_I764 "1"
Igor764CheckEnd:
  GetDLLVersion "${IGOR7DEFPATH}\IgorBinaries_Win32\Igor.exe" $R0 $R1
  IntOp $R2 $R0 / 0x00010000
  IntCmp $R2 7 +2
    Goto Igor7CheckEnd
  StrCpy $INSTALL_I7PATH "${IGOR7DEFPATH}"
  StrCpy $INSTALL_I732 "1"
Igor7CheckEnd:

  StrLen $0 $INSTALL_I8PATH
  IntCmp $0 0 +2
    Goto Igor8CheckEnd
  GetDLLVersion "${IGOR8DEFPATH}\IgorBinaries_x64\Igor64.exe" $R0 $R1
  IntOp $R2 $R0 / 0x00010000
  IntCmp $R2 8 +2
    Goto Igor864CheckEnd
  StrCpy $INSTALL_I8PATH "${IGOR8DEFPATH}"
  StrCpy $INSTALL_I864 "1"
Igor864CheckEnd:
  GetDLLVersion "${IGOR8DEFPATH}\IgorBinaries_Win32\Igor.exe" $R0 $R1
  IntOp $R2 $R0 / 0x00010000
  IntCmp $R2 8 +2
    Goto Igor8CheckEnd
  StrCpy $INSTALL_I8PATH "${IGOR8DEFPATH}"
  StrCpy $INSTALL_I832 "1"
Igor8CheckEnd:
# Prefer 64 bit
  IntCmp $INSTALL_I764 0 +2
    StrCpy $INSTALL_I732 "0"
  IntCmp $INSTALL_I864 0 +2
    StrCpy $INSTALL_I832 "0"

  !insertmacro PreventMultipleInstaller
  !insertmacro StopOnIgor32
  !insertmacro StopOnIgor64

  !insertmacro UninstallAttemptAdmin
  !insertmacro WaitForUninstaller

  !insertmacro UninstallAttemptUser
  !insertmacro WaitForUninstaller

  !insertmacro CheckAllUninstalled
functionEnd

!macro CheckLinkTarget LinkPath TargetName
!define CLTID ${__LINE__}
  StrCpy $5 "0"
  StrLen $3 "${TargetName}"
  FindFirst $1 $2 "${LinkPath}\*.lnk"
CLTLoop_${CLTID}:
  StrCmp $2 "" CLTDoneNotFound_${CLTID}
  ShellLink::GetShortCutTarget "${LinkPath}\$2"
  Pop $0
  StrLen $4 "$0"
  IntOp $4 $4 - $3
  StrCpy $0 "$0" $3 $4
  StrCmp $0 "${TargetName}" +1 CLTNotFound_${CLTID}
  StrCpy $5 "1"
  Push $5
  Goto CLTDone_${CLTID}
CLTNotFound_${CLTID}:
  FindNext $1 $2
  Goto CLTLoop_${CLTID}
CLTDoneNotFound_${CLTID}:
  Push $5
CLTDone_${CLTID}:
  FindClose $1
!undef CLTID
!macroend

!macro CheckMIESPresent Path NiceInfo
  !insertmacro CheckLinkTarget "${Path}\Igor Procedures" "MIES_Include.ipf"
  Pop $1
  IntCmp $1 0 +4
    IfSilent +2
      MessageBox MB_OK|MB_ICONSTOP "It appears that there is already MIES for ${NiceInfo} installed. Please remove MIES manually first."
    Quit
!macroend

!macro CreateIgorDirs
  CreateDirectory "$IGORBASEPATH\User Procedures"
  CreateDirectory "$IGORBASEPATH\Igor Procedures"
  CreateDirectory "$IGORBASEPATH\Igor Extensions"
  CreateDirectory "$IGORBASEPATH\Igor Extensions (64-bit)"
  CreateDirectory "$IGORBASEPATH\Igor Help Files"
!macroend

!macro CreateLinks
!define CREALNKSID ${__LINE__}
  !insertmacro CreateIgorDirs
  IntCmp $XOPINST 0 NoXOPInst__${CREALNKSID}
# All MIES XOPs linked by complete folder
    CreateShortCut "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORBITDIRTEMPL.lnk" "$INSTDIR\$IGORBITDIRTEMPL"
    FileWrite $FILEHANDLE "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORBITDIRTEMPL.lnk$\n"

    CreateShortCut "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORTANGOSOURCETEMPL.lnk" "$INSTDIR\$IGORTANGOSOURCETEMPL"
    FileWrite $FILEHANDLE "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORTANGOSOURCETEMPL.lnk$\n"
    Goto ProcInst_${CREALNKSID}
NoXOPInst__${CREALNKSID}:
# Link XOP files directly that are not Hardware XOPs
    StrLen $0 $IGORHDFSOURCETEMPL
    ${If} $0 != 0
      CreateShortCut "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORHDFSOURCETEMPL.lnk" "$INSTDIR\$IGORBITDIRTEMPL\$IGORHDFSOURCETEMPL"
      FileWrite $FILEHANDLE "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORHDFSOURCETEMPL.lnk$\n"
    ${EndIf}
    StrLen $0 $IGORUTILSOURCETEMPL
    ${If} $0 != 0
      CreateShortCut "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORUTILSOURCETEMPL.lnk" "$INSTDIR\$IGORBITDIRTEMPL\$IGORUTILSOURCETEMPL"
      FileWrite $FILEHANDLE "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORUTILSOURCETEMPL.lnk$\n"
    ${EndIf}

ProcInst_${CREALNKSID}:
    CreateShortCut "$IGORBASEPATH\Igor Procedures\MIES_Include.lnk" "$INSTDIR\Packages\MIES_Include.ipf"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Procedures\MIES_Include.lnk$\n"

    CreateShortCut "$IGORBASEPATH\User Procedures\Arduino.lnk" "$INSTDIR\Packages\Arduino"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\Arduino.lnk$\n"
    CreateShortCut "$IGORBASEPATH\User Procedures\IPNWB.lnk" "$INSTDIR\Packages\IPNWB"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\IPNWB.lnk$\n"
    CreateShortCut "$IGORBASEPATH\User Procedures\MIES.lnk" "$INSTDIR\Packages\MIES"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\MIES.lnk$\n"

    CreateShortCut "$IGORBASEPATH\User Procedures\Tango.lnk" "$INSTDIR\Packages\Tango"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\Tango.lnk$\n"

    CreateShortCut "$IGORBASEPATH\User Procedures\HDF-$IGORDIRTEMPL.lnk" "$INSTDIR\Packages\HDF-$IGORDIRTEMPL"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\HDF-$IGORDIRTEMPL.lnk$\n"

    CreateShortCut "$IGORBASEPATH\Igor Help Files\HelpFiles-$IGORDIRTEMPL.lnk" "$INSTDIR\HelpFiles-$IGORDIRTEMPL"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Help Files\HelpFiles-$IGORDIRTEMPL.lnk$\n"

!undef CREALNKSID
!macroend

Section "install"
  SetOutPath $INSTDIR

  IntCmp $INSTALL_I732 1 MIESCheck7
  IntCmp $INSTALL_I764 1 MIESCheck7
  Goto MIESCheck7End
MIESCheck7:
      StrLen $0 $INSTALL_I7PATH
      ${If} $0 = 0
        IfSilent +2
        MessageBox MB_OK "Bug: I have no Igor 7 Path."
        Quit
      ${EndIf}
      !insertmacro CheckMIESPresent "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files" "Igor Pro 7"
      !insertmacro CheckMIESPresent "$INSTALL_I7PATH" "Igor Pro 7"
MIESCheck7End:
  IntCmp $INSTALL_I832 1 MIESCheck8
  IntCmp $INSTALL_I864 1 MIESCheck8
  Goto MIESCheck8End
MIESCheck8:
    StrLen $0 $INSTALL_I8PATH
    ${If} $0 = 0
      IfSilent +2
      MessageBox MB_OK "Bug: I have no Igor 8 Path."
      Quit
    ${EndIf}
    !insertmacro CheckMIESPresent "$DOCUMENTS\WaveMetrics\Igor Pro 8 User Files" "Igor Pro 8"
    !insertmacro CheckMIESPresent "$INSTALL_I8PATH" "Igor Pro 8"
MIESCheck8End:

  IntCmp $ALLUSER 0 AdminCheckDone
    IntCmp $ISADMIN 1 AdminCheckDone
    IfSilent +2
      MessageBox mb_iconstop "You selected installation for All Users, but you don't have Administrator rights."
    SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
    Quit
AdminCheckDone:

  !include "${NSISINSTDIRLIST}"
  File "vc_redist.x86.exe"
  File "vc_redist.x64.exe"
  !include "${NSISINSTFILELIST}"

  ClearErrors
  FileOpen $FILEHANDLE $INSTDIR\uninstall.lst w
  IfErrors FileError

  IntCmp $ALLUSER 1 InstallAllUser
    CreateDirectory "$DOCUMENTS\WaveMetrics"
    SetShellVarContext current
    IntCmp $INSTALL_I732 0 InstallEnd732
      StrCpy $IGORDIRTEMPL "${IGOR7DIRTEMPL}"
      StrCpy $IGORBITDIRTEMPL "${IGOR732XOPSOURCETEMPL}"
      StrCpy $IGORHDFSOURCETEMPL "${IGOR732HDFXOPSOURCETEMPL}"
      StrCpy $IGORUTILSOURCETEMPL "${IGOR732UTILXOPSOURCETEMPL}"
      StrCpy $IGORTANGOSOURCETEMPL "${IGOR732TANGOXOPSOURCETEMPL}"
      StrCpy $IGOREXTENSIONPATH "${IGOR732EXTENSIONPATH}"
      StrCpy $IGORBASEPATH "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files"
      CreateDirectory "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files"
      !insertmacro CreateLinks
InstallEnd732:
    IntCmp $INSTALL_I764 0 InstallEnd764
      StrCpy $IGORDIRTEMPL "${IGOR7DIRTEMPL}"
      StrCpy $IGORBITDIRTEMPL "${IGOR764XOPSOURCETEMPL}"
      StrCpy $IGORHDFSOURCETEMPL "${IGOR764HDFXOPSOURCETEMPL}"
      StrCpy $IGORUTILSOURCETEMPL "${IGOR764UTILXOPSOURCETEMPL}"
      StrCpy $IGORTANGOSOURCETEMPL "${IGOR764TANGOXOPSOURCETEMPL}"
      StrCpy $IGOREXTENSIONPATH "${IGOR764EXTENSIONPATH}"
      StrCpy $IGORBASEPATH "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files"
      CreateDirectory "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files"
      !insertmacro CreateLinks
InstallEnd764:
    IntCmp $INSTALL_I832 0 InstallEnd832
      StrCpy $IGORDIRTEMPL "${IGOR8DIRTEMPL}"
      StrCpy $IGORBITDIRTEMPL "${IGOR832XOPSOURCETEMPL}"
      StrCpy $IGORHDFSOURCETEMPL "${IGOR832HDFXOPSOURCETEMPL}"
      StrCpy $IGORUTILSOURCETEMPL "${IGOR832UTILXOPSOURCETEMPL}"
      StrCpy $IGORTANGOSOURCETEMPL "${IGOR832TANGOXOPSOURCETEMPL}"
      StrCpy $IGOREXTENSIONPATH "${IGOR832EXTENSIONPATH}"
      StrCpy $IGORBASEPATH "$DOCUMENTS\WaveMetrics\Igor Pro 8 User Files"
      CreateDirectory "$DOCUMENTS\WaveMetrics\Igor Pro 8 User Files"
      !insertmacro CreateLinks
InstallEnd832:
    IntCmp $INSTALL_I864 0 InstallEnd864
      StrCpy $IGORDIRTEMPL "${IGOR8DIRTEMPL}"
      StrCpy $IGORBITDIRTEMPL "${IGOR864XOPSOURCETEMPL}"
      StrCpy $IGORHDFSOURCETEMPL "${IGOR864HDFXOPSOURCETEMPL}"
      StrCpy $IGORUTILSOURCETEMPL "${IGOR864UTILXOPSOURCETEMPL}"
      StrCpy $IGORTANGOSOURCETEMPL "${IGOR864TANGOXOPSOURCETEMPL}"
      StrCpy $IGOREXTENSIONPATH "${IGOR864EXTENSIONPATH}"
      StrCpy $IGORBASEPATH "$DOCUMENTS\WaveMetrics\Igor Pro 8 User Files"
      CreateDirectory "$DOCUMENTS\WaveMetrics\Igor Pro 8 User Files"
      !insertmacro CreateLinks
InstallEnd864:
    Goto EndOfLinks

InstallAllUser:
  IntCmp $INSTALL_I732 0 InstallAEnd732
    StrCpy $IGORDIRTEMPL "${IGOR7DIRTEMPL}"
    StrCpy $IGORBITDIRTEMPL "${IGOR732XOPSOURCETEMPL}"
    StrCpy $IGORHDFSOURCETEMPL "${IGOR732HDFXOPSOURCETEMPL}"
    StrCpy $IGORUTILSOURCETEMPL "${IGOR732UTILXOPSOURCETEMPL}"
    StrCpy $IGORTANGOSOURCETEMPL "${IGOR732TANGOXOPSOURCETEMPL}"
    StrCpy $IGOREXTENSIONPATH "${IGOR732EXTENSIONPATH}"
    StrCpy $IGORBASEPATH $INSTALL_I7PATH
    !insertmacro CreateLinks
InstallAEnd732:
  IntCmp $INSTALL_I764 0 InstallAEnd764
    StrCpy $IGORDIRTEMPL "${IGOR7DIRTEMPL}"
    StrCpy $IGORBITDIRTEMPL "${IGOR764XOPSOURCETEMPL}"
    StrCpy $IGORHDFSOURCETEMPL "${IGOR764HDFXOPSOURCETEMPL}"
    StrCpy $IGORUTILSOURCETEMPL "${IGOR764UTILXOPSOURCETEMPL}"
    StrCpy $IGORTANGOSOURCETEMPL "${IGOR764TANGOXOPSOURCETEMPL}"
    StrCpy $IGOREXTENSIONPATH "${IGOR764EXTENSIONPATH}"
    StrCpy $IGORBASEPATH $INSTALL_I7PATH
    !insertmacro CreateLinks
InstallAEnd764:
  IntCmp $INSTALL_I832 0 InstallAEnd832
    StrCpy $IGORDIRTEMPL "${IGOR8DIRTEMPL}"
    StrCpy $IGORBITDIRTEMPL "${IGOR832XOPSOURCETEMPL}"
    StrCpy $IGORHDFSOURCETEMPL "${IGOR832HDFXOPSOURCETEMPL}"
    StrCpy $IGORUTILSOURCETEMPL "${IGOR832UTILXOPSOURCETEMPL}"
    StrCpy $IGORTANGOSOURCETEMPL "${IGOR832TANGOXOPSOURCETEMPL}"
    StrCpy $IGOREXTENSIONPATH "${IGOR832EXTENSIONPATH}"
    StrCpy $IGORBASEPATH $INSTALL_I8PATH
    !insertmacro CreateLinks
InstallAEnd832:
  IntCmp $INSTALL_I864 0 InstallAEnd864
    StrCpy $IGORDIRTEMPL "${IGOR8DIRTEMPL}"
    StrCpy $IGORBITDIRTEMPL "${IGOR864XOPSOURCETEMPL}"
    StrCpy $IGORHDFSOURCETEMPL "${IGOR864HDFXOPSOURCETEMPL}"
    StrCpy $IGORUTILSOURCETEMPL "${IGOR864UTILXOPSOURCETEMPL}"
    StrCpy $IGORTANGOSOURCETEMPL "${IGOR864TANGOXOPSOURCETEMPL}"
    StrCpy $IGOREXTENSIONPATH "${IGOR864EXTENSIONPATH}"
    StrCpy $IGORBASEPATH $INSTALL_I8PATH
    !insertmacro CreateLinks
InstallAEnd864:
  Goto EndOfLinks

FileError:
  IfSilent +2
    MessageBox MB_OK "Can not create $INSTDIR\uninstall.lst."
  Quit

EndOfLinks:
  FileClose $FILEHANDLE
  WriteUninstaller "$INSTDIR\uninstall.exe"

  File "${APPICON}"
  # Registry information for add/remove programs
  IntCmp $ALLUSER 0 RegistryToHKCU
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${COMPANYNAME} - ${APPNAME} Admin - ${DESCRIPTION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$\"$INSTDIR\${APPICON}$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "${COMPANYNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "HelpLink" "${HELPURL}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLUpdateInfo" "${UPDATEURL}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLInfoAbout" "${ABOUTURL}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "${PACKAGEVERSION}"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMajor" ${VERSIONMAJOR}
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMinor" ${VERSIONMINOR}
  # There is no option for modifying or repairing the install
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoRepair" 1
  # Set the INSTALLSIZE constant (!defined at the top of this script) so Add/Remove Programs can accurately report the size
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "EstimatedSize" ${INSTALLSIZE}
  Goto AfterRegistrySetup
RegistryToHKCU:
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${COMPANYNAME} - ${APPNAME} User - ${DESCRIPTION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$\"$INSTDIR\${APPICON}$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "${COMPANYNAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "HelpLink" "${HELPURL}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLUpdateInfo" "${UPDATEURL}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLInfoAbout" "${ABOUTURL}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "${PACKAGEVERSION}"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMajor" ${VERSIONMAJOR}
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMinor" ${VERSIONMINOR}
  # There is no option for modifying or repairing the install
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoRepair" 1
  # Set the INSTALLSIZE constant (!defined at the top of this script) so Add/Remove Programs can accurately report the size
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "EstimatedSize" ${INSTALLSIZE}
AfterRegistrySetup:

  ExecWait '"$INSTDIR\vc_redist.x86.exe" /quiet'
  ExecWait '"$INSTDIR\vc_redist.x64.exe" /quiet'
  Sleep 1000
  Delete "$INSTDIR\vc_redist.x86.exe"
  Delete "$INSTDIR\vc_redist.x64.exe"
SectionEnd

# Uninstaller

function un.onInit
  !insertmacro PreventMultipleUninstaller
  UserInfo::GetAccountType
  pop $0
  ${If} $0 == "admin"
    IfSilent +3
      MessageBox MB_OKCANCEL "Permanently remove ${APPNAME}?" IDOK Next
    Quit
Next:
  ${EndIf}
  !insertmacro StopOnIgor32
  !insertmacro StopOnIgor64
functionEnd

Section "uninstall"
  ClearErrors
  FileOpen $FILEHANDLE $INSTDIR\uninstall.lst r
  IfErrors FileError
ReadLoop:
  ClearErrors
  FileRead $FILEHANDLE $LINESTR
  IfErrors +1 +2
    Goto EndReadLoop
  ExecCmd::exec "cmd.exe /Cdel $\"$LINESTR$\""
  Pop $0
  ExecCmd::wait $0
  Pop $0
  Goto ReadLoop
EndReadLoop:
  FileClose $FILEHANDLE
  Goto RemoveMain
FileError:
  IfSilent +2
    MessageBox MB_OK "Can not find $INSTDIR\uninstall.lst. Some shortcuts in Igor Pro folders may remain after uninstallation."

RemoveMain:
  !include "${NSISUNINSTFILELIST}"
  Delete "$INSTDIR\${APPICON}"
  Delete $INSTDIR\uninstall.lst
  Delete $INSTDIR\uninstall.exe
  !include "${NSISUNINSTDIRLIST}"
  RMDir $INSTDIR
  StrCpy $1 "$\"$INSTDIR\uninstall.exe$\""
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString"
  StrCmp $0 $1 0 +2
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString"
  StrCmp $0 $1 0 +2
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
SectionEnd
