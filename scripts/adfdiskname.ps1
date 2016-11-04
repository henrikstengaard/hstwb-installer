Param(
	[Parameter(Mandatory=$true)]
	[string]$adfFile
)


# read string from bytes
function ReadString($bytes, $offset, $length)
{
	$stringBytes = New-Object 'byte[]' $length 
	[Array]::Copy($bytes, $offset, $stringBytes, 0, $length)
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	return $iso88591.GetString($stringBytes)
}


# read adf bytes
$adfBytes = [System.IO.File]::ReadAllBytes($adfFile)


# read disk name from offset 0x6E1B0
$offset = 0x6E1B0
$diskNameLength = $adfBytes[$offset]
#$diskNameBytes = New-Object 'byte[]' $diskNameLength 
#[Array]::Copy($adfBytes, $offset + 1, $diskNameBytes, 0, $diskNameLength)
#$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
#$diskName = $iso88591.GetString($diskNameBytes)

$diskName = ReadString $adfBytes ($offset + 1) $diskNameLength

# print adf file and disk name
Write-Host ("Adf file '" + $adfFile + "'")
Write-Host ("Disk name '" + $diskName + "'")

# For checking, if adf could be workbench disk
$workbenchLibraryOffset1 = 0x28CA6
if ((ReadString $adfBytes $workbenchLibraryOffset1 17) -eq 'workbench.library')
{
	Write-Host "This could be workbench disk"
}


# For checking if adf could be extras, fonts, locale, install and storage disk
$workbenchLibraryOffset2 = 0x626A6
if ((ReadString $adfBytes $workbenchLibraryOffset2 17) -eq 'workbench.library')
{
	Write-Host "This could be extras, fonts, locale, install and storage disk"
}

