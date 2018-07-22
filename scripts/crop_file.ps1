# Crop File
# ---------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-05-25
#
# A powershell script to crop a file to a size primarily used for Raspberry Pi img files.


Param(
	[Parameter(Mandatory=$true)]
	[string]$file,
	[Parameter(Mandatory=$true)]
	[int64]$size
)

# resolve path
$file = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($file)

# fail, if file doesn't exist
if (!(Test-Path $file))
{
	throw ("File '{0}' doesn't exist!" -f $file)
}

$oldSize = (Get-Item $file).Length

# write crop file title
Write-Output ("Crop File")
Write-Output ("---------")
Write-Output ("File: '{0}'" -f $file)
Write-Output ("Old size: {0} bytes" -f $oldSize)
Write-Output ("New size: {0} bytes" -f $size)

# exit, if old file size is already smaller
if ($oldSize -le $size)
{
	Write-Output "Old file size is already smaller. Cancelled!"
	exit
}

# confirm crop file
$confirm = Read-Host -Prompt "Are you sure you want to crop file?"
if ($confirm -notmatch '^(y|yes)$')
{
	Write-Output "Cancelled!"
	exit
}

# crop file
$fileStream = [io.file]::Open($file, 'Open', 'Write')
$fileStream.SetLength($size)
$fileStream.Close()