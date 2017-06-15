# Win32 Dialog
# ------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-06-15
#
# A powershell script to show dialogs for Windows platform.


Param(
	[Parameter(Mandatory=$true)]
	[string]$title,
	[Parameter(Mandatory=$false)]
	[string]$message,
	[Parameter(Mandatory=$false)]
	[string]$path,
	[Parameter(Mandatory=$false)]
	[switch]$folderDialog,
	[Parameter(Mandatory=$false)]
	[switch]$confirmDialog
)


Add-Type -AssemblyName System.Windows.Forms


# folder dialog
function FolderDialog($title, $directory, $showNewFolderButton)
{
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.Description = $title
    $folderBrowserDialog.SelectedPath = $directory
    $folderBrowserDialog.ShowNewFolderButton = $showNewFolderButton
    $result = $folderBrowserDialog.ShowDialog()

    if($result -ne "OK")
    {
        return $null
    }    

    return $folderBrowserDialog.SelectedPath    
}


# confirm dialog
function ConfirmDialog($title, $message)
{
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::YesNo)

    if($result -eq "YES")
    {
        return $true
    }

    return $false
}

# folder dialog
if ($folderDialog)
{
    if (!$path)
    {
        $path = ${Env:USERPROFILE}
    }

    $result = FolderDialog $title $path $true

    if ($result)
    {
        return $result
    }
}
# confirm dialog
elseif ($confirmDialog)
{
    if ((ConfirmDialog $title $message))
    {
        return '1'
    }
    else 
    {
        return '0'
    }
}