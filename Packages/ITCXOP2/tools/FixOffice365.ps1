$ErrorActionPreference = "stop"
New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
Try {
    $officeVer = (Get-ItemProperty -Path HKCR:\Word.Application\CurVer)."(Default)"
}
Catch {
    exit
}
if ($officeVer -eq "Word.Application.16") {
    $acl = (Get-Item HKLM:\SOFTWARE\Wow6432Node).GetAccessControl('Access')
    $acl.SetSecurityDescriptorSddlForm($acl.Sddl.Replace("D:(","D:AI("))
    Set-Acl -Path HKLM:\SOFTWARE\Wow6432Node $acl
}
