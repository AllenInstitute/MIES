$sh = new-object -com 'Shell.Application'
$sh.ShellExecute('powershell', "-Command `"Set-ProcessMitigation -PolicyFilePath $PSScriptRoot\Settings.xml`"", '', 'runas')
