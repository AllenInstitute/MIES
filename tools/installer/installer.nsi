!include "LogicLib.nsh"
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "setincnames.inc"
!include "${NSISVERSION}"

!define APPNAME "MIES"
!define COMPANYNAME "Allen Institute for Brain Science"
!define DESCRIPTION "Research Accelerator Tool"
!define APPICON "mies.ico"
# These will be displayed by the "Click here for support information" link in "Add/Remove Programs"
# It is possible to use "mailto:" links in here to open the email client
!define HELPURL "mailto:mies@alleninstitute.org" # "Support Information" link
!define UPDATEURL "mailto:mies@alleninstitute.org" # "Product Updates" link
!define ABOUTURL "http://www.alleninstitute.org" # "Publisher" link

# This is the size (in kB) of all the files copied to the HDD
!define INSTALLSIZE 27000

#Unicode true
SetCompressor /SOLID lzma
!include "${NSISREQUEST}"
InstallDir "$PROGRAMFILES64\${APPNAME}"

# rtf or txt file - remember if it is txt, it must be in the DOS text format (\r\n)
#LicenseData "license.txt"
# This will be in the installer/uninstaller's title bar
Name "${COMPANYNAME} - ${APPNAME}"
Icon "${APPICON}"
UninstallIcon "${APPICON}"
!include "${NSISOUTFILE}"
XPStyle on

#Page license
Page custom DialogAllCur
Page custom DialogPartial
Page custom DialogInstallFor78
Page directory
Page instfiles

Var IGOR64
Var IGOR64REGFILE
Var IGOR64REGPATH
Var ALLUSER
Var FULLINST
Var processFound
Var INSTALL_ANABROWSER
Var INSTALL_DATABROWSER
Var INSTALL_WAVEBUILD
Var INSTALL_DOWNSAMP
Var INSTALL_I7
Var INSTALL_I7PATH
Var INSTALL_I8
Var INSTALL_I8PATH
Var IGORBASEPATH
Var FILEHANDLE
Var LINESTR
Var IGOR7DEFPATH
Var IGOR8DEFPATH
Var IGOR7DIRTEMPL
Var IGOR8DIRTEMPL
Var IGORDIRTEMPL

#FindProc return value definitions
!define FindProc_NOT_FOUND 1
!define FindProc_FOUND 0

#GUI vars for All or Current User
Var NSD_AC_Dialog
Var NSD_AC_Label
Var NSD_AC_RB1
Var NSD_AC_RB2

#GUI vars for Partial/Full Install
Var NSD_PA_Dialog
Var NSD_PA_Label
Var NSD_PA_RB1
Var NSD_PA_RB2
Var NSD_PA_CB1
Var NSD_PA_CB2
Var NSD_PA_CB3
Var NSD_PA_CB4

#GUI vars for InstallFor78
Var NSD_IF_Dialog
Var NSD_IF_Label
Var NSD_IF_CB1
Var NSD_IF_CB2

!include "browsefolder.nsh"

!macro AdjustInstdirIfUserIsNotAdmin
  UserInfo::GetAccountType
  pop $0
  StrCpy $INSTDIR "$PROGRAMFILES64\${APPNAME}"
  ${If} $0 != "admin"
    StrCpy $INSTDIR "$DOCUMENTS\${APPNAME}"
  ${EndIf}
!macroend

!macro VerifyUserIsAdmin
  UserInfo::GetAccountType
  pop $0
  ${If} $0 != "admin" ;Require admin rights on NT4+
    IfSilent +2
      MessageBox mb_iconstop "Administrator rights required!"
    SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
    Quit
  ${EndIf}
!macroend

!macro PreventMultiple
  System::Call 'kernel32::CreateMutex(p 0, i 0, t "MIESINSTMutex") p .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +4
    IfSilent +2
      MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
    Quit
!macroend

!macro FindProc result processName
  ExecCmd::exec "%SystemRoot%\System32\tasklist /NH /FI $\"IMAGENAME eq ${processName}$\" | %SystemRoot%\System32\find /I $\"${processName}$\""
  Pop $0 ; The handle for the process
  ExecCmd::wait $0
  Pop ${result} ; The exit code
!macroend

!macro CheckIgor32
  StrCpy $IGOR32 "1"
  ReadRegStr $1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
  StrLen $0 $1
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
  ${NSD_CreateRadioButton} 95u 48u 100% 13u "All Users"
  Pop $NSD_AC_RB2
  IntCmp $ALLUSER 0 +2
    ${NSD_Check} $NSD_AC_RB2
  ${NSD_OnClick} $NSD_AC_RB2 ClickedAllUser

  nsDialogs::Show
FunctionEnd

#---Installation Type Dialog---
!macro DisableParts
  EnableWindow $NSD_PA_CB1 0
  EnableWindow $NSD_PA_CB2 0
  EnableWindow $NSD_PA_CB3 0
  EnableWindow $NSD_PA_CB4 0
!macroend

!macro EnableParts
  EnableWindow $NSD_PA_CB1 1
  EnableWindow $NSD_PA_CB2 1
  EnableWindow $NSD_PA_CB3 1
  EnableWindow $NSD_PA_CB4 1
!macroend

!macro CheckParts
!define CHECKPRT ${__LINE__}
  IntCmp $FULLINST 1 EnableNext_${CHECKPRT}
    IntCmp $INSTALL_ANABROWSER 1 EnableNext_${CHECKPRT}
      IntCmp $INSTALL_DATABROWSER 1 EnableNext_${CHECKPRT}
        IntCmp $INSTALL_WAVEBUILD 1 EnableNext_${CHECKPRT}
          IntCmp $INSTALL_DOWNSAMP 1 EnableNext_${CHECKPRT}
            GetDlgItem $0 $HWNDPARENT 1
            EnableWindow $0 0
            Goto End_${CHECKPRT}
EnableNext_${CHECKPRT}:
  GetDlgItem $0 $HWNDPARENT 1
  EnableWindow $0 1
End_${CHECKPRT}:
!undef CHECKPRT
!macroend

Function SetInstFull
  Pop $0
  ${NSD_GetState} $0 $FULLINST
  IntCmp $FULLINST 0 Partial
    !insertmacro DisableParts
    Goto End
Partial:
    !insertmacro EnableParts
End:
  !insertmacro CheckParts
FunctionEnd

Function SetInstPartial
  Pop $0
  ${NSD_GetState} $0 $1
  IntCmp $1 1 Partial
    StrCpy $FULLINST "1"
    !insertmacro DisableParts
    Goto End
Partial:
    StrCpy $FULLINST "0"
    !insertmacro EnableParts
End:
  !insertmacro CheckParts
FunctionEnd

Function ClickedAnaBrowser
  Pop $0
  ${NSD_GetState} $0 $INSTALL_ANABROWSER
  !insertmacro CheckParts
FunctionEnd

Function ClickedDataBrowser
  Pop $0
  ${NSD_GetState} $0 $INSTALL_DATABROWSER
  !insertmacro CheckParts
FunctionEnd

Function ClickedWaveBuilder
  Pop $0
  ${NSD_GetState} $0 $INSTALL_WAVEBUILD
  !insertmacro CheckParts
FunctionEnd

Function ClickedDownsample
  Pop $0
  ${NSD_GetState} $0 $INSTALL_DOWNSAMP
  !insertmacro CheckParts
FunctionEnd

Function DialogPartial
  nsDialogs::Create 1018
  Pop $NSD_PA_Dialog

  ${If} $NSD_PA_Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 20u 0u 100% 12u "Select installation content"
  Pop $NSD_PA_Label

  ${NSD_CreateRadioButton} 85u 13u 100% 13u "Full installation"
  Pop $NSD_PA_RB1
  IntCmp $FULLINST 0 +2
    ${NSD_Check} $NSD_PA_RB1
  ${NSD_OnClick} $NSD_PA_RB1 SetInstFull
  ${NSD_CreateRadioButton} 85u 26u 100% 13u "Partial installation"
  Pop $NSD_PA_RB2
  IntCmp $FULLINST 1 +2
    ${NSD_Check} $NSD_PA_RB2
  ${NSD_OnClick} $NSD_PA_RB2 SetInstPartial

  ${NSD_CreateCheckbox} 95u 39u 100% 13u "Analysis Browser"
  Pop $NSD_PA_CB1
  ${NSD_OnClick} $NSD_PA_CB1 ClickedAnaBrowser
  ${NSD_CreateCheckbox} 95u 52u 100% 13u "Data Browser"
  Pop $NSD_PA_CB2
  ${NSD_OnClick} $NSD_PA_CB2 ClickedDataBrowser
  ${NSD_CreateCheckbox} 95u 65u 100% 13u "Wave Builder"
  Pop $NSD_PA_CB3
  ${NSD_OnClick} $NSD_PA_CB3 ClickedWaveBuilder
  ${NSD_CreateCheckbox} 95u 78u 100% 13u "Downsample"
  Pop $NSD_PA_CB4
  ${NSD_OnClick} $NSD_PA_CB4 ClickedDownsample

  IntCmp $INSTALL_ANABROWSER 0 +2
    ${NSD_Check} $NSD_PA_CB1
  IntCmp $INSTALL_DATABROWSER 0 +2
    ${NSD_Check} $NSD_PA_CB2
  IntCmp $INSTALL_WAVEBUILD 0 +2
    ${NSD_Check} $NSD_PA_CB3
  IntCmp $INSTALL_DOWNSAMP 0 +2
    ${NSD_Check} $NSD_PA_CB4

  IntCmp $FULLINST 1 EnableModules
    !insertmacro EnableParts
  Goto ShowIt
EnableModules:
    !insertmacro DisableParts
ShowIt:
  nsDialogs::Show
FunctionEnd

#---Install for Igor 7,8 Dialog---
!macro CheckIgorSel
!define CHECKIGSEL ${__LINE__}
  IntCmp $INSTALL_I7 1 EnableNext_${CHECKIGSEL}
    IntCmp $INSTALL_I8 1 EnableNext_${CHECKIGSEL}
      GetDlgItem $0 $HWNDPARENT 1
      EnableWindow $0 0
      Goto End_${CHECKIGSEL}
EnableNext_${CHECKIGSEL}:
  GetDlgItem $0 $HWNDPARENT 1
  EnableWindow $0 1
End_${CHECKIGSEL}:
!undef CHECKIGSEL
!macroend

Function ClickedIgor7
  Pop $0
  ${NSD_GetState} $0 $INSTALL_I7
  IntCmp $INSTALL_I7 0 End
  StrLen $1 $INSTALL_I7PATH
  IntCmp $1 0 +2
    Goto End
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
    Goto End
BrowseCancel:
  ${NSD_Uncheck} $0
  StrCpy $INSTALL_I7 "0"
End:
  !insertmacro CheckIgorSel
FunctionEnd

Function ClickedIgor8
  Pop $0
  ${NSD_GetState} $0 $INSTALL_I8
  IntCmp $INSTALL_I8 0 End
  StrLen $1 $INSTALL_I8PATH
  IntCmp $1 0 +2
    Goto End
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
    Goto End
BrowseCancel:
  ${NSD_Uncheck} $0
  StrCpy $INSTALL_I8 "0"
End:
  !insertmacro CheckIgorSel
FunctionEnd

Function DialogInstallFor78
  nsDialogs::Create 1018
  Pop $NSD_IF_Dialog

  ${If} $NSD_IF_Dialog == error
    Abort
  ${EndIf}

  !insertmacro CheckIgorSel
  ${NSD_CreateLabel} 20u 10u 100% 12u "Select Igor Pro version(s) where MIES should be included"
  Pop $NSD_IF_Label
  ${NSD_CreateCheckbox} 95u 39u 100% 13u "Igor Pro 7"
  Pop $NSD_IF_CB1
  IntCmp $INSTALL_I7 0 NoIgor7
    ${NSD_Check} $NSD_IF_CB1
  NoIgor7:
  ${NSD_OnClick} $NSD_IF_CB1 ClickedIgor7
  ${NSD_CreateCheckbox} 95u 52u 100% 13u "Igor Pro 8"
  Pop $NSD_IF_CB2
  IntCmp $INSTALL_I8 0 NoIgor8
    ${NSD_Check} $NSD_IF_CB2
  NoIgor8:
  ${NSD_OnClick} $NSD_IF_CB2 ClickedIgor8

  nsDialogs::Show
FunctionEnd

function .onInit
  StrCpy $IGOR7DEFPATH "$PROGRAMFILES64\WaveMetrics\Igor Pro 7 Folder"
  StrCpy $IGOR8DEFPATH "$PROGRAMFILES64\WaveMetrics\Igor Pro 8 Folder"
  StrCpy $ALLUSER "0"
  StrCpy $FULLINST "1"
  StrCpy $INSTALL_ANABROWSER "0"
  StrCpy $INSTALL_DATABROWSER "0"
  StrCpy $INSTALL_WAVEBUILD "0"
  StrCpy $INSTALL_DOWNSAMP "0"
  StrCpy $IGOR7DIRTEMPL "IP7"
  StrCpy $IGOR8DIRTEMPL "IP7"

  !insertmacro AdjustInstdirIfUserIsNotAdmin

  # Get Igor Path from Registry and check which version we have
  !insertmacro CheckIgor64
  IntCmp $IGOR64 0 NoRegIgor64
    GetDLLVersion "$IGOR64REGFILE" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    StrCpy $INSTALL_I7 "1"
    StrCpy $INSTALL_I8 "1"
    StrCpy $INSTALL_I7PATH $IGOR64REGPATH -17
    StrCpy $INSTALL_I8PATH $IGOR64REGPATH -17
    IntCmp $R2 7 CheckIgor8
      StrCpy $INSTALL_I7 "0"
      StrCpy $INSTALL_I7PATH ""
CheckIgor8:
    IntCmp $R2 8 NoRegIgor64
      StrCpy $INSTALL_I8 "0"
      StrCpy $INSTALL_I8PATH ""
NoRegIgor64:

  #Look for Igor7,8 at default install folder, if not already known
  StrLen $0 $INSTALL_I7PATH
  IntCmp $0 0 +2
    Goto Igor7CheckEnd
  GetDLLVersion "$IGOR7DEFPATH\IgorBinaries_x64\Igor64.exe" $R0 $R1
  IntOp $R2 $R0 / 0x00010000
  IntCmp $R2 7 +2
    Goto Igor7CheckEnd
  StrCpy $INSTALL_I7PATH "$IGOR7DEFPATH"
  StrCpy $INSTALL_I7 "1"
Igor7CheckEnd:

  StrLen $0 $INSTALL_I8PATH
  IntCmp $0 0 +2
    Goto Igor8CheckEnd
  GetDLLVersion "$IGOR8DEFPATH\IgorBinaries_x64\Igor64.exe" $R0 $R1
  IntOp $R2 $R0 / 0x00010000
  IntCmp $R2 8 +2
    Goto Igor8CheckEnd
  StrCpy $INSTALL_I8PATH "$IGOR8DEFPATH"
  StrCpy $INSTALL_I8 "1"
Igor8CheckEnd:

  !insertmacro PreventMultiple
  !insertmacro StopOnIgor32
  !insertmacro StopOnIgor64
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
!define CMIESPID ${__LINE__}
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName"
  StrLen $1 $0
  IntCmp $1 0 +1 FinishMacro_${CMIESPID} FinishMacro_${CMIESPID}
    !insertmacro CheckLinkTarget "${Path}\Igor Procedures" "MIES_Include.ipf"
    Pop $1
    IntCmp $1 0 +4
      IfSilent +2
        MessageBox MB_OK|MB_ICONSTOP "It appears that there is already MIES for ${NiceInfo} installed. Please remove it manually first."
      Quit
    !insertmacro CheckLinkTarget "${Path}\Igor Procedures" "MIES_AnalysisBrowser.ipf"
    Pop $1
    IntCmp $1 0 +4
      IfSilent +2
        MessageBox MB_OK|MB_ICONSTOP "It appears that there is already MIES Analysis Browser for ${NiceInfo} installed. Please remove it manually first."
      Quit
    !insertmacro CheckLinkTarget "${Path}\Igor Procedures" "MIES_DataBrowser.ipf"
    Pop $1
    IntCmp $1 0 +4
      IfSilent +2
        MessageBox MB_OK|MB_ICONSTOP "It appears that there is already MIES Data Browser for ${NiceInfo} installed. Please remove it manually first."
      Quit
    !insertmacro CheckLinkTarget "${Path}\Igor Procedures" "MIES_WaveBuilderPanel.ipf"
    Pop $1
    IntCmp $1 0 +4
      IfSilent +2
        MessageBox MB_OK|MB_ICONSTOP "It appears that there is already MIES Wave Builder Panel for ${NiceInfo} installed. Please remove it manually first."
      Quit
    !insertmacro CheckLinkTarget "${Path}\Igor Procedures" "MIES_Downsample.ipf"
    Pop $1
    IntCmp $1 0 +4
      IfSilent +2
        MessageBox MB_OK|MB_ICONSTOP "It appears that there is already MIES Downsample for ${NiceInfo} installed. Please remove it manually first."
      Quit
FinishMacro_${CMIESPID}:
!undef CMIESPID
!macroend

!macro CreateLinks
!define CREALNKSID ${__LINE__}
  CreateDirectory "$IGORBASEPATH\User Procedures"
  CreateDirectory "$IGORBASEPATH\Igor Procedures"
  CreateDirectory "$IGORBASEPATH\Igor Extensions"
  CreateDirectory "$IGORBASEPATH\Igor Extensions (64-bit)"
  CreateDirectory "$IGORBASEPATH\Igor Help Files"
  IntCmp $FULLINST 0 PartInst_${CREALNKSID}
    CreateShortCut "$IGORBASEPATH\User Procedures\Arduino.lnk" "$INSTDIR\Packages\Arduino"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\Arduino.lnk$\n"
    CreateShortCut "$IGORBASEPATH\User Procedures\HDF-IP7.lnk" "$INSTDIR\Packages\HDF-IP7"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\HDF-IP7.lnk$\n"
    CreateShortCut "$IGORBASEPATH\User Procedures\IPNWB.lnk" "$INSTDIR\Packages\IPNWB"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\IPNWB.lnk$\n"
    CreateShortCut "$IGORBASEPATH\User Procedures\MIES.lnk" "$INSTDIR\Packages\MIES"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\MIES.lnk$\n"
    CreateShortCut "$IGORBASEPATH\User Procedures\Tango.lnk" "$INSTDIR\Packages\Tango"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\Tango.lnk$\n"
    CreateShortCut "$IGORBASEPATH\Igor Procedures\MIES_Include.lnk" "$INSTDIR\Packages\MIES_Include.ipf"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Procedures\MIES_Include.lnk$\n"
    CreateShortCut "$IGORBASEPATH\Igor Extensions (64-bit)\XOPs-$IGORDIRTEMPL-64bit.lnk" "$INSTDIR\XOPs-$IGORDIRTEMPL-64bit"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Extensions (64-bit)\XOPs-$IGORDIRTEMPL-64bit.lnk$\n"
    CreateShortCut "$IGORBASEPATH\Igor Extensions (64-bit)\XOP-tango-$IGORDIRTEMPL-64bit.lnk" "$INSTDIR\XOP-tango-$IGORDIRTEMPL-64bit"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Extensions (64-bit)\XOP-tango-$IGORDIRTEMPL-64bit.lnk$\n"
    CreateShortCut "$IGORBASEPATH\Igor Help Files\HelpFiles-$IGORDIRTEMPL.lnk" "$INSTDIR\HelpFiles-$IGORDIRTEMPL"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Help Files\HelpFiles-$IGORDIRTEMPL.lnk$\n"
    Goto End_${CREALNKSID}
PartInst_${CREALNKSID}:
  IntCmp $INSTALL_ANABROWSER 0 DataBrowser_${CREALNKSID}
    CreateShortCut "$IGORBASEPATH\User Procedures\HDF-$IGORDIRTEMPL.lnk" "$INSTDIR\Packages\HDF-$IGORDIRTEMPL"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\HDF-$IGORDIRTEMPL.lnk$\n"
    CreateShortCut "$IGORBASEPATH\User Procedures\IPNWB.lnk" "$INSTDIR\Packages\IPNWB"
    FileWrite $FILEHANDLE "$IGORBASEPATH\User Procedures\IPNWB.lnk$\n"
    CreateShortCut "$IGORBASEPATH\Igor Procedures\MIES_AnalysisBrowser.lnk" "$INSTDIR\Packages\MIES\MIES_AnalysisBrowser.ipf"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Procedures\MIES_AnalysisBrowser.lnk$\n"
    CreateShortCut "$IGORBASEPATH\Igor Extensions (64-bit)\XOPs-$IGORDIRTEMPL-64bit.lnk" "$INSTDIR\XOPs-$IGORDIRTEMPL-64bit"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Extensions (64-bit)\XOPs-$IGORDIRTEMPL-64bit.lnk$\n"
DataBrowser_${CREALNKSID}:
  IntCmp $INSTALL_DATABROWSER 0 WaveBuilder_${CREALNKSID}
    CreateShortCut "$IGORBASEPATH\Igor Procedures\MIES_DataBrowser.lnk" "$INSTDIR\Packages\MIES\MIES_DataBrowser.ipf"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Procedures\MIES_DataBrowser.lnk$\n"
WaveBuilder_${CREALNKSID}:
  IntCmp $INSTALL_WAVEBUILD 0 DownSample_${CREALNKSID}
    CreateShortCut "$IGORBASEPATH\Igor Procedures\MIES_WaveBuilderPanel.lnk" "$INSTDIR\Packages\MIES\MIES_WaveBuilderPanel.ipf"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Procedures\MIES_WaveBuilderPanel.lnk$\n"
DownSample_${CREALNKSID}:
  IntCmp $INSTALL_DOWNSAMP 0 End_${CREALNKSID}
    CreateShortCut "$IGORBASEPATH\Igor Procedures\MIES_Downsample.lnk" "$INSTDIR\Packages\MIES\MIES_Downsample.ipf"
    FileWrite $FILEHANDLE "$IGORBASEPATH\Igor Procedures\MIES_Downsample.lnk$\n"
End_${CREALNKSID}:
!undef CREALNKSID
!macroend

Section "install"
  SetOutPath $INSTDIR

  IntCmp $INSTALL_I7 0 MIESCheck7End
    StrLen $0 $INSTALL_I7PATH
    ${If} $0 = 0
      IfSilent +2
      MessageBox MB_OK "Bug: I have no Igor 7 Path."
      Quit
    ${EndIf}
    !insertmacro CheckMIESPresent "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files" "Igor Pro 7"
    !insertmacro CheckMIESPresent "$INSTALL_I7PATH" "Igor Pro 7"
MIESCheck7End:
  IntCmp $INSTALL_I8 0 MIESCheck8End
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
    !insertmacro VerifyUserIsAdmin
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
    IntCmp $INSTALL_I7 0 InstallEnd7
      StrCpy $IGORDIRTEMPL $IGOR7DIRTEMPL
      StrCpy $IGORBASEPATH "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files"
      CreateDirectory "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files"
      !insertmacro CreateLinks
InstallEnd7:
    IntCmp $INSTALL_I8 0 InstallEnd8
      StrCpy $IGORDIRTEMPL $IGOR8DIRTEMPL
      StrCpy $IGORBASEPATH "$DOCUMENTS\WaveMetrics\Igor Pro 8 User Files"
      CreateDirectory "$DOCUMENTS\WaveMetrics\Igor Pro 8 User Files"
      !insertmacro CreateLinks
InstallEnd8:
    Goto EndOfLinks

InstallAllUser:
  IntCmp $INSTALL_I7 0 InstallAEnd7
    StrCpy $IGORDIRTEMPL $IGOR7DIRTEMPL
    StrCpy $IGORBASEPATH $INSTALL_I7PATH
    !insertmacro CreateLinks
InstallAEnd7:
  IntCmp $INSTALL_I8 0 InstallAEnd8
    StrCpy $IGORDIRTEMPL $IGOR8DIRTEMPL
    StrCpy $IGORBASEPATH $INSTALL_I8PATH
    !insertmacro CreateLinks
InstallAEnd8:
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
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${COMPANYNAME} - ${APPNAME} - ${DESCRIPTION}"
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

  ExecCmd::exec "$\"$INSTDIR\vc_redist.x86.exe /quiet$\""
  Pop $0
  ExecCmd::wait $0
  Pop $0
  ExecCmd::exec "$\"$INSTDIR\vc_redist.x64.exe /quiet$\""
  Pop $0
  ExecCmd::wait $0
  Pop $0
  Delete "$INSTDIR\vc_redist.x86.exe"
  Delete "$INSTDIR\vc_redist.x64.exe"
SectionEnd

# Uninstaller

function un.onInit
  !insertmacro PreventMultiple
  UserInfo::GetAccountType
  pop $0
  ${If} $0 == "admin"
    IfSilent +2
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
    MessageBox MB_OK "Can find $INSTDIR\uninstall.lst. Some shortcuts in Igor Pro folders may remain after uninstallation."

RemoveMain:
  !include "${NSISUNINSTFILELIST}"
  Delete "$INSTDIR\${APPICON}"
  Delete $INSTDIR\uninstall.lst
  Delete $INSTDIR\uninstall.exe
  !include "${NSISUNINSTDIRLIST}"
  RMDir $INSTDIR
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
SectionEnd
