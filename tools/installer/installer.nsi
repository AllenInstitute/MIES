!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "x64.nsh"
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
!define IGOR64EXTENSIONPATH "Igor Extensions (64-bit)"
# Endings for Helpfiles- and Packages\HDF- folders
!define IGOR9DIRTEMPL "IP9"
!define IGOR10DIRTEMPL "IP10"
# source folder name for installation with XOPs
!define IGOR964XOPSOURCETEMPL "XOPs-IP9-64bit"
!define IGOR1064XOPSOURCETEMPL "XOPs-IP10-64bit"

# source file names for XOPs for installation without Hardware XOPs
!define IGORUTILXOPSOURCETEMPL "MIESUtils-64.xop"
!define IGORJSONXOPSOURCETEMPL "JSON-64.xop"
!define IGORZEROMQXOPSOURCETEMPL "ZeroMQ-64.xop"
!define IGORTUFXOPSOURCETEMPL "TUF-64.xop"
!define IGORNWBXOPSOURCETEMPL "mies-nwb2-compound-XOP-64.xop"

# Default paths for Igor Installation where the installer looks automatically
!define IGOR9DEFPATH "$PROGRAMFILES64\WaveMetrics\Igor Pro 9 Folder"
!define IGOR10DEFPATH "$PROGRAMFILES64\WaveMetrics\Igor Pro 10 Folder"

# Temp file for command execution output for ExecDos::Exec
!define EXECDOSOUTPUT "ExecOutput.log"

# Return codes
!define ERROR_INSTALLER_ALREADY_RUNNING 1
!define ERROR_UNINSTALLER_ALREADY_RUNNING 2
!define ERROR_CANNOT_GET_TASKLIST 3
!define ERROR_ADMIN_INSTALLATION_PRESENT 4
!define ERROR_IGORPRO_IS_RUNNING 5
!define ERROR_IGORPRO64_IS_RUNNING 6
!define ERROR_64BIT_OS_REQUIRED 7
!define ERROR_ADMIN_REQUIRED 8
!define ERROR_MIES_ALREADY_INSTALLED 9
!define ERROR_NO_IGOR9_PATH 10
!define ERROR_NO_IGOR10_PATH 11
!define ERROR_CANNOT_CREATE_UNINSTALL_FILELIST 12
!define ERROR_CANNOT_DISABLE_ASLR 13
!define ERROR_CANNOT_FIX_OFFICE365 14
!define ERROR_CANNOT_CREATE_INSTALLCONFIG 15
!define ERROR_ELEVATION_REQUIRED 740

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
Page custom DialogInstallFor910
Page directory
Page instfiles

Var IGOR64
Var IGOR64REGFILE
Var IGOR64REGPATH
Var ALLUSER
Var XOPINST
Var processFound
Var INSTALL_I964
Var INSTALL_I9PATH
Var INSTALL_I1064
Var INSTALL_I10PATH
Var IGORBASEPATH
Var FILEHANDLE
Var LINESTR
Var ISADMIN

Var IGORDIRTEMPL
Var IGORBITDIRTEMPL
Var IGORUTILSOURCETEMPL
Var IGORJSONSOURCETEMPL
Var IGORZEROMQSOURCETEMPL
Var IGORTUFSOURCETEMPL
Var IGORNWBSOURCETEMPL
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

#GUI vars for InstallFor89
Var NSD_IF_Dialog
Var NSD_IF_Label
Var NSD_IF_CB2
Var NSD_IF_CB4

!include "browsefolder.nsh"

!macro QuitWithCode code
  SetErrorLevel code
  Quit
!macroend

!macro PreventMultipleInstaller uid
  System::Call 'kernel32::CreateMutex(p 0, i 0, t "MIESINSTALLMutex") p .r1 ?e'
  Pop $R0
  StrCmp $R0 0 MacroEnd_${uid}
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
    !insertmacro QuitWithCode ERROR_INSTALLER_ALREADY_RUNNING
  MacroEnd_${uid}:
!macroend

!macro PreventMultipleUninstaller uid
  System::Call 'kernel32::CreateMutex(p 0, i 0, t "MIESUNINSTALLMutex") p .r1 ?e'
  Pop $R0
  StrCmp $R0 0 MacroEnd_${uid}
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "The uninstaller is already running."
    !insertmacro QuitWithCode ERROR_UNINSTALLER_ALREADY_RUNNING
  MacroEnd_${uid}:
!macroend

!macro FindProc result processName uid
  ReadEnvStr $0 SYSTEMROOT
  Push "ExecDos::End"
; In contradiction to the docs the two empty strings at the end are mandatory. Otherwise the stack gets cleared.
; The logfile name (third string) is put on the stack before the command output.
; I could not get the plugin to generate any logfile output by itself.
; Stack:
;   <command output>
;   ...
;   <logfile name>
;   <Marker> if pushed before
; I found no way that allows piping to a second application
  ExecDos::exec /NOUNLOAD /TOSTACK "$0\System32\tasklist.exe /NH /FI $\"IMAGENAME eq ${processName}$\"" "" ""
  Pop $0
  ${if} $0 <> 0
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "Can not get current task list through tasklist.exe."
    !insertmacro QuitWithCode ERROR_CANNOT_GET_TASKLIST
  ${EndIf}

  ReadEnvStr $0 TEMP
  FileOpen $4 "$0\${EXECDOSOUTPUT}" w
  Loop_${uid}:
    Pop $1
    StrCmp $1 "ExecDos::End" LoopEnd_${uid}
    FileWrite $4 $1
    Goto Loop_${uid}
  LoopEnd_${uid}:
  FileClose $4

  ReadEnvStr $0 SYSTEMROOT
  ReadEnvStr $1 TEMP
  ExecDos::exec /NOUNLOAD "$0\System32\find.exe /I $\"${processName}$\" $1\${EXECDOSOUTPUT}" "" ""

  Pop ${result} ; The exit code
  Delete $1\${EXECDOSOUTPUT}
!macroend

!macro CheckAllUninstalled uid
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

  IntCmp $2 0 MacroEnd_${uid}
    ifSilent +2
      MessageBox MB_OK|MB_ICONSTOP "There is a already a installation of MIES present that was installed with administrative privileges. Uninstallation requires administrative privileges as well and can not be done with your current rights. Please contact an administrator to uninstall MIES through Add/Remove Programs first."
      !insertmacro QuitWithCode ERROR_ADMIN_INSTALLATION_PRESENT
  MacroEnd_${uid}:
!macroend

!macro UninstallAttemptAdmin
  IfSilent +3
    ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString"
    Goto +2
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString"
  StrLen $1 $0
  ${If} $1 <> 0
    ExecWait '$0 _?=$INSTDIR'
    Delete "$INSTDIR\uninstall.exe"
    RMDir $INSTDIR
    BringToFront
  ${EndIf}
!macroend

!macro UninstallAttemptUser
# this check is just for compatibility with old installations
!define UODUID ${__LINE__}
  IfFileExists "${USERINSTDIR}\uninstall.exe" 0 UODUEnd_{UODUID}
    IfSilent +3
      ExecWait "${USERINSTDIR}\uninstall.exe _?=${USERINSTDIR}"
      Goto +2
    ExecWait '"${USERINSTDIR}\uninstall.exe" /S _?=${USERINSTDIR}'
    Delete "${USERINSTDIR}\uninstall.exe"
    RMDir "${USERINSTDIR}"
    BringToFront
  UODUEnd_{UODUID}:
!undef UODUID

# this is the current check against registry
  IfSilent +3
    ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString"
    Goto +2
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString"
  StrLen $1 $0
  ${If} $1 <> 0
    ExecWait '$0 _?=${USERINSTDIR}'
    Delete "${USERINSTDIR}\uninstall.exe"
    RMDir "${USERINSTDIR}"
    BringToFront
  ${EndIf}
!macroend

!macro WaitForProc ProcName
!define WFPID ${__LINE__}
WFUWaitUninstA_${WFPID}:
    !insertmacro FindProc $processFound "${ProcName}" ${__LINE__}
    IntCmp $processFound ${FindProc_NOT_FOUND} WFUEndWaitUninstA_${WFPID}
      Sleep 100
      Goto WFUWaitUninstA_${WFPID}
WFUEndWaitUninstA_${WFPID}:
!undef WFPID
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

!macro StopOnIgor32 uid
  !insertmacro FindProc $processFound "Igor.exe" ${__LINE__}
  IntCmp $processFound ${FindProc_NOT_FOUND} MacroEnd_${uid}
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "Igor Pro is running. Please close it first" /SD IDOK
    !insertmacro QuitWithCode ERROR_IGORPRO_IS_RUNNING
  MacroEnd_${uid}:
!macroend

!macro StopOnIgor64 uid
  !insertmacro FindProc $processFound "Igor64.exe" ${__LINE__}
  IntCmp $processFound ${FindProc_NOT_FOUND} MacroEnd_${uid}
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "Igor Pro (64-bit) is running. Please close it first" /SD IDOK
    !insertmacro QuitWithCode ERROR_IGORPRO64_IS_RUNNING
  MacroEnd_${uid}:
!macroend

!macro SetInstallPath
  StrCpy $INSTDIR "$PROGRAMFILES64\${APPNAME}"
  IntCmp $ALLUSER 1 +2
    StrCpy $INSTDIR "${USERINSTDIR}"
!macroend

!macro WriteITCRegistry
  WriteRegStr HKLM "Software\Instrutech" "" ""
  AccessControl::GrantOnRegKey HKLM "Software\Instrutech" "(BU)" "FullAccess"
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

  !insertmacro SetInstallPath
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

#---Install for Igor 9,10 Dialog---
!macro CheckIgorSel
!define CHECKIGSEL ${__LINE__}
    IntCmp $INSTALL_I964 1 EnableNext_${CHECKIGSEL}
        IntCmp $INSTALL_I1064 1 EnableNext_${CHECKIGSEL}
          GetDlgItem $0 $HWNDPARENT 1
          EnableWindow $0 0
          Goto End_${CHECKIGSEL}
EnableNext_${CHECKIGSEL}:
  GetDlgItem $0 $HWNDPARENT 1
  EnableWindow $0 1
End_${CHECKIGSEL}:
!undef CHECKIGSEL
!macroend

Function ClickedIgor964
  Pop $0
  ${NSD_GetState} $0 $INSTALL_I964
  IntCmp $INSTALL_I964 0 EndSet
  StrLen $1 $INSTALL_I9PATH
  IntCmp $1 0 +2
    Goto EndSet
  MessageBox MB_OK "The installer can not find your Igor Pro 9 program folder. Please help."
  Push "" #Initial Pathselection
  Push "Choose Igor Pro 9 program folder" #Heading
  Push "$PROGRAMFILES64\WaveMetrics"  #Root Path
  Call BrowseForFolder
  Pop $1
  StrLen $2 $1
  IntCmp $2 0 BrowseCancel
    GetDLLVersion "$1\IgorBinaries_x64\Igor64.exe" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    IntCmp $R2 8 +3
      MessageBox MB_OK "Could not find the Igor Pro 9 executable. (at $1\IgorBinaries_x64\Igor64.exe)"
      Goto BrowseCancel
    StrCpy $INSTALL_I9PATH "$1"
    Goto EndSet
BrowseCancel:
  ${NSD_Uncheck} $0
  StrCpy $INSTALL_I964 "0"
EndSet:
  !insertmacro CheckIgorSel
FunctionEnd

Function ClickedIGOR1064
  Pop $0
  ${NSD_GetState} $0 $INSTALL_I1064
  IntCmp $INSTALL_I1064 0 EndSet
  StrLen $1 $INSTALL_I10PATH
  IntCmp $1 0 +2
    Goto EndSet
  MessageBox MB_OK "The installer can not find your Igor Pro 10 program folder. Please help."
  Push "" #Initial Pathselection
  Push "Choose Igor Pro 10 program folder" #Heading
  Push "$PROGRAMFILES64\WaveMetrics"  #Root Path
  Call BrowseForFolder
  Pop $1
  StrLen $2 $1
  IntCmp $2 0 BrowseCancel
    GetDLLVersion "$1\IgorBinaries_x64\Igor64.exe" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    IntCmp $R2 9 +3
      MessageBox MB_OK "Could not find the Igor Pro 10 executable. (at $1\IgorBinaries_x64\Igor64.exe)"
      Goto BrowseCancel
    StrCpy $INSTALL_I10PATH "$1"
    Goto EndSet
BrowseCancel:
  ${NSD_Uncheck} $0
  StrCpy $INSTALL_I1064 "0"
EndSet:
  !insertmacro CheckIgorSel
FunctionEnd

Function DialogInstallFor910
  nsDialogs::Create 1018
  Pop $NSD_IF_Dialog

  ${If} $NSD_IF_Dialog == error
    Abort
  ${EndIf}

  !insertmacro CheckIgorSel
  ${NSD_CreateLabel} 20u 10u 100% 13u "Select Igor Pro version(s) where MIES should be included"
  Pop $NSD_IF_Label
  ${NSD_CreateCheckbox} 95u 23u 100% 13u "Igor Pro 9 64-bit"
  Pop $NSD_IF_CB2
  IntCmp $INSTALL_I964 0 NoIgor964
    ${NSD_Check} $NSD_IF_CB2
  NoIgor964:
  ${NSD_OnClick} $NSD_IF_CB2 ClickedIgor964
  ${NSD_CreateCheckbox} 95u 36u 100% 13u "Igor Pro 10 64-bit"
  Pop $NSD_IF_CB4
  IntCmp $INSTALL_I1064 0 NoIGOR1064
    ${NSD_Check} $NSD_IF_CB4
  NoIGOR1064:
  ${NSD_OnClick} $NSD_IF_CB4 ClickedIGOR1064

  nsDialogs::Show
FunctionEnd

function .onInit
  ${IfNot} ${RunningX64}
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "Aborting: MIES requires a 64-bit Windows OS."
    !insertmacro QuitWithCode ERROR_64BIT_OS_REQUIRED
  ${EndIf}

  ClearErrors
  # Setting if /SKIPHWXOPS was encountered
  StrCpy $XOPINST "0"
  ${GetOptions} $CMDLINE /SKIPHWXOPS $0
  ${If} ${Errors}
    # default setting install with XOPs
    StrCpy $XOPINST "1"
  ${EndIf}

  StrCpy $ISADMIN "0"
  UserInfo::GetAccountType
  pop $0
  StrCmp $0 "admin" 0 +2
    StrCpy $ISADMIN "1"

  ClearErrors
  ${GetOptions} $CMDLINE /ALLUSER $0
  ${If} ${Errors}
    # default setting
    StrCpy $ALLUSER "0"
  ${Else}
    IntCmp $ISADMIN 0 QuitCantAlluser
    StrCpy $ALLUSER "1"
    Goto CheckIgorPaths
QuitCantAlluser:
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "Aborting: You need to administrator privileges for /ALLUSER installation."
    !insertmacro QuitWithCode ERROR_ADMIN_REQUIRED
  ${EndIf}

CheckIgorPaths:
  # Get Igor Path from Registry and check which version we have
  !insertmacro CheckIgor64
  IntCmp $IGOR64 0 NoRegIgor64
    GetDLLVersion "$IGOR64REGFILE" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    StrCpy $INSTALL_I964 "1"
    StrCpy $INSTALL_I1064 "1"
    StrCpy $INSTALL_I9PATH $IGOR64REGPATH -17
    StrCpy $INSTALL_I10PATH $IGOR64REGPATH -17
    # check IP version number
    IntCmp $R2 9 CheckIGOR1064Path
      StrCpy $INSTALL_I964 "0"
      StrCpy $INSTALL_I9PATH ""
CheckIGOR1064Path:
    IntCmp $R2 10 NoRegIgor64
      StrCpy $INSTALL_I1064 "0"
      StrCpy $INSTALL_I10PATH ""
NoRegIgor64:

# Look for Igor9,10 at default install folder, if not already known
  StrLen $0 $INSTALL_I9PATH
  IntCmp $0 0 +2
    Goto IGOR9CheckEnd
  GetDLLVersion "${IGOR9DEFPATH}\IgorBinaries_x64\Igor64.exe" $R0 $R1
  IntOp $R2 $R0 / 0x00010000
  # check IP version number
  IntCmp $R2 9 +2
    Goto IGOR9CheckEnd
  StrCpy $INSTALL_I9PATH "${IGOR9DEFPATH}"
  StrCpy $INSTALL_I964 "1"
IGOR9CheckEnd:

  StrLen $0 $INSTALL_I10PATH
  IntCmp $0 0 +2
    Goto IGOR10CheckEnd
  GetDLLVersion "${IGOR10DEFPATH}\IgorBinaries_x64\Igor64.exe" $R0 $R1
  IntOp $R2 $R0 / 0x00010000
  # check IP version number
  IntCmp $R2 10 +2
    Goto IGOR10CheckEnd
  StrCpy $INSTALL_I10PATH "${IGOR10DEFPATH}"
  StrCpy $INSTALL_I1064 "1"
IGOR10CheckEnd:

  # If found all available Igor installations are enabled for install at this point

  # the /CIS skips various installation checks and is reserved for internal use
  # on the CI server only
  ClearErrors
  ${GetOptions} $CMDLINE /CIS $0
  ${If} ${Errors}
    # normal installation

    !insertmacro PreventMultipleInstaller ${__LINE__}
    !insertmacro StopOnIgor32 ${__LINE__}
    !insertmacro StopOnIgor64 ${__LINE__}
    IntCmp $ISADMIN 0 SkipAdminUninstall
      !insertmacro UninstallAttemptAdmin
SkipAdminUninstall:
    !insertmacro UninstallAttemptUser

    !insertmacro CheckAllUninstalled ${__LINE__}
  ${EndIf}

  !insertmacro SetInstallPath
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

!macro CheckMIESPresent Path NiceInfo uid
  !insertmacro CheckLinkTarget "${Path}\Igor Procedures" "MIES_Include.ipf"
  Pop $1
  IntCmp $1 0 MacroEnd_${uid}
    IfSilent +2
      MessageBox MB_OK|MB_ICONSTOP "It appears that there is already MIES for ${NiceInfo} installed. Please remove MIES manually first."
    !insertmacro QuitWithCode ERROR_MIES_ALREADY_INSTALLED
  MacroEnd_${uid}:
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

    Goto ProcInst_${CREALNKSID}
NoXOPInst__${CREALNKSID}:
# Link XOP files directly that are not Hardware XOPs
    StrLen $0 $IGORUTILSOURCETEMPL
    ${If} $0 != 0
      CreateShortCut "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORUTILSOURCETEMPL.lnk" "$INSTDIR\$IGORBITDIRTEMPL\$IGORUTILSOURCETEMPL"
      FileWrite $FILEHANDLE "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORUTILSOURCETEMPL.lnk$\n"
    ${EndIf}
    StrLen $0 $IGORJSONSOURCETEMPL
    ${If} $0 != 0
      CreateShortCut "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORJSONSOURCETEMPL.lnk" "$INSTDIR\$IGORBITDIRTEMPL\$IGORJSONSOURCETEMPL"
      FileWrite $FILEHANDLE "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORJSONSOURCETEMPL.lnk$\n"
    ${EndIf}
    StrLen $0 $IGORZEROMQSOURCETEMPL
    ${If} $0 != 0
      CreateShortCut "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORZEROMQSOURCETEMPL.lnk" "$INSTDIR\$IGORBITDIRTEMPL\$IGORZEROMQSOURCETEMPL"
      FileWrite $FILEHANDLE "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORZEROMQSOURCETEMPL.lnk$\n"
    ${EndIf}
    StrLen $0 $IGORTUFSOURCETEMPL
    ${If} $0 != 0
      CreateShortCut "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORTUFSOURCETEMPL.lnk" "$INSTDIR\$IGORBITDIRTEMPL\$IGORTUFSOURCETEMPL"
      FileWrite $FILEHANDLE "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORTUFSOURCETEMPL.lnk$\n"
    ${EndIf}
    StrLen $0 $IGORNWBSOURCETEMPL
    ${If} $0 != 0
      CreateShortCut "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORNWBSOURCETEMPL.lnk" "$INSTDIR\$IGORBITDIRTEMPL\$IGORNWBSOURCETEMPL"
      FileWrite $FILEHANDLE "$IGORBASEPATH\$IGOREXTENSIONPATH\$IGORNWBSOURCETEMPL.lnk$\n"
    ${EndIf}

ProcInst_${CREALNKSID}:
    CreateShortCut "$IGORBASEPATH\Igor Procedures\MIES_Include.lnk" "$INSTDIR\Packages\MIES_Include.ipf"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Procedures\MIES_Include.lnk$\n"

    CreateShortCut "$IGORBASEPATH\User Procedures\IPNWB.lnk" "$INSTDIR\Packages\IPNWB"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\IPNWB.lnk$\n"
    CreateShortCut "$IGORBASEPATH\User Procedures\MIES.lnk" "$INSTDIR\Packages\MIES"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\MIES.lnk$\n"

    CreateShortCut "$IGORBASEPATH\Igor Help Files\HelpFiles-$IGORDIRTEMPL.lnk" "$INSTDIR\HelpFiles-$IGORDIRTEMPL"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Help Files\HelpFiles-$IGORDIRTEMPL.lnk$\n"

!undef CREALNKSID
!macroend

Section "install"
  SetOutPath $INSTDIR

  IntCmp $INSTALL_I964 1 MIESCheck9
  Goto MIESCheck9End
MIESCheck9:
      StrLen $0 $INSTALL_I9PATH
      ${If} $0 = 0
        IfSilent +2
          MessageBox MB_OK "Bug: I have no Igor 9 Path."
        !insertmacro QuitWithCode ERROR_NO_IGOR9_PATH
      ${EndIf}
      !insertmacro CheckMIESPresent "$DOCUMENTS\WaveMetrics\Igor Pro 9 User Files" "Igor Pro 9" ${__LINE__}
      !insertmacro CheckMIESPresent "$INSTALL_I9PATH" "Igor Pro 9" ${__LINE__}
MIESCheck9End:
  IntCmp $INSTALL_I1064 1 MIESCheck10
  Goto MIESCheck10End
MIESCheck10:
    StrLen $0 $INSTALL_I10PATH
    ${If} $0 = 0
      IfSilent +2
        MessageBox MB_OK "Bug: I have no Igor 10 Path."
      !insertmacro QuitWithCode ERROR_NO_IGOR10_PATH
    ${EndIf}
    !insertmacro CheckMIESPresent "$DOCUMENTS\WaveMetrics\Igor Pro 10 User Files" "Igor Pro 10" ${__LINE__}
    !insertmacro CheckMIESPresent "$INSTALL_I10PATH" "Igor Pro 10" ${__LINE__}
MIESCheck10End:

  IntCmp $ALLUSER 0 AdminCheckDone
    IntCmp $ISADMIN 1 AdminCheckDone
    IfSilent +2
      MessageBox mb_iconstop "You selected installation for All Users, but you don't have Administrator rights."
    !insertmacro QuitWithCode ERROR_ELEVATION_REQUIRED
AdminCheckDone:

  !include "${NSISINSTDIRLIST}"
  File "vc_redist.x64.exe"
  !include "${NSISINSTFILELIST}"

  ClearErrors
  FileOpen $FILEHANDLE $INSTDIR\uninstall.lst w
  IfErrors FileError

  IntCmp $ALLUSER 1 InstallAllUser
    CreateDirectory "$DOCUMENTS\WaveMetrics"
    SetShellVarContext current
    IntCmp $INSTALL_I964 0 InstallEnd964
      StrCpy $IGORDIRTEMPL "${IGOR9DIRTEMPL}"
      StrCpy $IGORBITDIRTEMPL "${IGOR964XOPSOURCETEMPL}"
      StrCpy $IGORUTILSOURCETEMPL "${IGORUTILXOPSOURCETEMPL}"
      StrCpy $IGORJSONSOURCETEMPL "${IGORJSONXOPSOURCETEMPL}"
      StrCpy $IGORZEROMQSOURCETEMPL "${IGORZEROMQXOPSOURCETEMPL}"
      StrCpy $IGORTUFSOURCETEMPL "${IGORTUFXOPSOURCETEMPL}"
      StrCpy $IGORNWBSOURCETEMPL "${IGORNWBXOPSOURCETEMPL}"
      StrCpy $IGOREXTENSIONPATH "${IGOR64EXTENSIONPATH}"
      StrCpy $IGORBASEPATH "$DOCUMENTS\WaveMetrics\Igor Pro 9 User Files"
      CreateDirectory "$DOCUMENTS\WaveMetrics\Igor Pro 9 User Files"
      !insertmacro CreateLinks
InstallEnd964:
    IntCmp $INSTALL_I1064 0 InstallEnd1064
      StrCpy $IGORDIRTEMPL "${IGOR10DIRTEMPL}"
      StrCpy $IGORBITDIRTEMPL "${IGOR1064XOPSOURCETEMPL}"
      StrCpy $IGORUTILSOURCETEMPL "${IGORUTILXOPSOURCETEMPL}"
      StrCpy $IGORJSONSOURCETEMPL "${IGORJSONXOPSOURCETEMPL}"
      StrCpy $IGORZEROMQSOURCETEMPL "${IGORZEROMQXOPSOURCETEMPL}"
      StrCpy $IGORTUFSOURCETEMPL "${IGORTUFXOPSOURCETEMPL}"
      StrCpy $IGORNWBSOURCETEMPL "${IGORNWBXOPSOURCETEMPL}"
      StrCpy $IGOREXTENSIONPATH "${IGOR64EXTENSIONPATH}"
      StrCpy $IGORBASEPATH "$DOCUMENTS\WaveMetrics\Igor Pro 10 User Files"
      CreateDirectory "$DOCUMENTS\WaveMetrics\Igor Pro 10 User Files"
      !insertmacro CreateLinks
InstallEnd1064:
    Goto EndOfLinks

InstallAllUser:
  IntCmp $INSTALL_I964 0 InstallAEnd964
    StrCpy $IGORDIRTEMPL "${IGOR9DIRTEMPL}"
    StrCpy $IGORBITDIRTEMPL "${IGOR964XOPSOURCETEMPL}"
    StrCpy $IGORUTILSOURCETEMPL "${IGORUTILXOPSOURCETEMPL}"
    StrCpy $IGORJSONSOURCETEMPL "${IGORJSONXOPSOURCETEMPL}"
    StrCpy $IGORZEROMQSOURCETEMPL "${IGORZEROMQXOPSOURCETEMPL}"
    StrCpy $IGORTUFSOURCETEMPL "${IGORTUFXOPSOURCETEMPL}"
    StrCpy $IGORNWBSOURCETEMPL "${IGORNWBXOPSOURCETEMPL}"
    StrCpy $IGOREXTENSIONPATH "${IGOR64EXTENSIONPATH}"
    StrCpy $IGORBASEPATH $INSTALL_I9PATH
    !insertmacro CreateLinks
InstallAEnd964:
  IntCmp $INSTALL_I1064 0 InstallAEnd1064
    StrCpy $IGORDIRTEMPL "${IGOR10DIRTEMPL}"
    StrCpy $IGORBITDIRTEMPL "${IGOR1064XOPSOURCETEMPL}"
    StrCpy $IGORUTILSOURCETEMPL "${IGORUTILXOPSOURCETEMPL}"
    StrCpy $IGORJSONSOURCETEMPL "${IGORJSONXOPSOURCETEMPL}"
    StrCpy $IGORZEROMQSOURCETEMPL "${IGORZEROMQXOPSOURCETEMPL}"
    StrCpy $IGORTUFSOURCETEMPL "${IGORTUFXOPSOURCETEMPL}"
    StrCpy $IGORNWBSOURCETEMPL "${IGORNWBXOPSOURCETEMPL}"
    StrCpy $IGOREXTENSIONPATH "${IGOR64EXTENSIONPATH}"
    StrCpy $IGORBASEPATH $INSTALL_I10PATH
    !insertmacro CreateLinks
InstallAEnd1064:
  Goto EndOfLinks

FileError:
  IfSilent +2
    MessageBox MB_OK "Can not create $INSTDIR\uninstall.lst."
  !insertmacro QuitWithCode ERROR_CANNOT_CREATE_UNINSTALL_FILELIST

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

  IntCmp $ISADMIN 0 SkipVCRedistInstallation
    ExecWait '"$INSTDIR\vc_redist.x64.exe" /quiet'
SkipVCRedistInstallation:

    Sleep 1000
    Delete "$INSTDIR\vc_redist.x64.exe"

  IntCmp $ISADMIN 0 SkipASLRSetup
    IntCmp $XOPINST 0  SkipASLRSetup
      # This special execution is required because we need to run 64-bit powershell here
      ExecWait '$WINDIR\sysnative\windowspowershell\v1.0\powershell.exe -executionPolicy bypass -File "$INSTDIR\Packages\ITCXOP2\tools\Disable-ASLR-for-Igor64.ps1"' $0
      IntCmp $0 0 SkipASLRSetup
        IfSilent +2
          MessageBox MB_OK "Can not disable ASLR for Igor64.exe."
        !insertmacro QuitWithCode ERROR_CANNOT_DISABLE_ASLR

SkipASLRSetup:

  IntCmp $ISADMIN 0 SkipITCSetup
    IntCmp $XOPINST 0  SkipITCSetup
      ExecWait 'Powershell.exe -executionPolicy bypass -File "$INSTDIR\Packages\ITCXOP2\tools\FixOffice365.ps1"' $0
      IntCmp $0 0 FixOffice365Done
        IfSilent +2
          MessageBox MB_OK "Can not apply Office365 fixes."
        !insertmacro QuitWithCode ERROR_CANNOT_FIX_OFFICE365
FixOffice365Done:
      !insertmacro WriteITCRegistry
      ${If} ${RunningX64}
        SetRegView 64
        !insertmacro WriteITCRegistry
        SetRegView default
      ${EndIf}
SkipITCSetup:
; Write out installed configuration
; Format of the json file:
; /Installation/User : <string> ; for what user target the installation was done, either "current" or "all"
; /Installation/WithHardware : <number> ; if the installation was done with hardware XOPs, either "1" or "0"
  ClearErrors
  FileOpen $FILEHANDLE "$INSTDIR\installation_configuration.json" w
  IfErrors FileErrorInstallConfig
  FileWrite $FILEHANDLE '{$\n'
  FileWrite $FILEHANDLE '$\t"Installation" : {$\n'
  IntCmp $ALLUSER 1 ConfigWriteUserAll
    FileWrite $FILEHANDLE '$\t$\t"User" : "current",$\n'
    Goto ConfigWriteUserEnd
ConfigWriteUserAll:
    FileWrite $FILEHANDLE '$\t$\t"User" : "all",$\n'
ConfigWriteUserEnd:
  IntCmp $XOPINST 1 ConfigWriteWithHardwareYes
  FileWrite $FILEHANDLE '$\t$\t"WithHardware" : 0$\n'
  Goto ConfigWriteWithHardwareEnd
ConfigWriteWithHardwareYes:
  FileWrite $FILEHANDLE '$\t$\t"WithHardware" : 1$\n'
ConfigWriteWithHardwareEnd:
  FileWrite $FILEHANDLE '$\t}$\n'
  FileWrite $FILEHANDLE '}'
  FileClose $FILEHANDLE
  Goto EndOfInstallation
FileErrorInstallConfig:
  IfSilent +2
    MessageBox MB_OK "Can not create installation configuration file."
  !insertmacro QuitWithCode ERROR_CANNOT_CREATE_INSTALLCONFIG

EndOfInstallation:

SectionEnd

# Uninstaller

function un.onInit
  !insertmacro PreventMultipleUninstaller ${__LINE__}
  !insertmacro StopOnIgor32 ${__LINE__}
  !insertmacro StopOnIgor64 ${__LINE__}
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
  ExecDos::exec /NOUNLOAD "cmd.exe /Cdel $\"$LINESTR$\"" "" ""
  Pop $0
  ExecDos::wait $0
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
