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
	[switch]$showFolderBrowserDialog,
	[Parameter(Mandatory=$false)]
	[switch]$showConfirmDialog
)


Add-Type -AssemblyName System.Windows.Forms


# show folder browser dialog using WinForms
function FolderBrowserDialog($title, $directory, $showNewFolderButton)
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

# show folder browser dialog
if ($showFolderBrowserDialog)
{
    if (!$path)
    {
        $path = default?
    }

    $result = FolderBrowserDialog $title $path $true

    if ($result)
    {
        return $result
    }
}
# show confirm dialog
elseif ($showConfirmDialog)
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