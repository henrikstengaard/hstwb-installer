# First Time
# ----------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-09-09
#
# A powershell script to check if HstWB Installer is used for the first time and show run hstwb installer setup dialog.


Param(
    [Parameter(Mandatory=$true)]
	[string]$settingsDir
)


Add-Type -AssemblyName System.Windows.Forms


# confirm dialog
function ConfirmDialog($title, $message)
{
    $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    $icon = [System.Windows.Forms.MessageBoxIcon]::Question
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icon)

    if($result -eq 'Yes')
    {
        return $true
    }

    return $false
}

$settingsFile = Join-Path $settingsDir -ChildPath 'hstwb-installer-settings.ini'

if (!(Test-Path $settingsFile))
{
    $confirm = ConfirmDialog "Run HstWB Installer Setup" ("It appears this is the first time you're using HstWB Installer,{1}since settings file '{0}' doesn't exist.{1}{1}Do you want to start HstWB Installer Setup,{1}which will create a default settings file?" -f $settingsFile, [Environment]::NewLine)
    if ($confirm)
    {
        exit 1
    }
}