# Icon Pos
# --------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-01-17
#
# Powershell script to read and show Amiga icon and drawer sizes and positions from .info files.
# Reference: http://krashan.ppa.pl/articles/amigaicons/

Param(
	[Parameter(Mandatory=$true)]
	[string]$iconDir
)

# resolve path
$iconDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($iconDir)

function ToUInt32($bytes)
{
	[Array]::Reverse($bytes)
	return [System.BitConverter]::ToUInt32($bytes, 0)
}

function ToInt16($bytes)
{
	[Array]::Reverse($bytes)
	return [System.BitConverter]::ToInt16($bytes, 0)
}

function ToInt32($bytes)
{
	[Array]::Reverse($bytes)
	return [System.BitConverter]::ToInt32($bytes, 0)
}


$infoFiles = @()
$infoFiles += Get-ChildItem -Path $iconDir -Filter *.info

foreach ($infoFile in $infoFiles)
{
    $infoFileStream = New-Object System.IO.FileStream $infoFile.FullName, 'Open', 'Read', 'Read'
    $infoBinaryReader = New-Object System.IO.BinaryReader($infoFileStream)

    $magicBytes = $infoBinaryReader.ReadBytes(2)

    if ($magicBytes[0] -eq 227 -and $magicBytes[1] -eq 16)
    {
        $infoBinaryReader.BaseStream.Seek(58, ([System.IO.SeekOrigin]::Begin)) | Out-Null
        $currentX = ToUInt32 $infoBinaryReader.ReadBytes(4)
        $currentY = ToUInt32 $infoBinaryReader.ReadBytes(4)

        # $infoBinaryReader.BaseStream.Seek(72, ([System.IO.SeekOrigin]::Begin)) | Out-Null
        # $type = $infoBinaryReader.ReadByte()

        $infoBinaryReader.BaseStream.Seek(78, ([System.IO.SeekOrigin]::Begin)) | Out-Null
        $left = ToInt16 $infoBinaryReader.ReadBytes(2)
        $top = ToInt16 $infoBinaryReader.ReadBytes(2)
        $width = ToInt16 $infoBinaryReader.ReadBytes(2)
        $height = ToInt16 $infoBinaryReader.ReadBytes(2)
    
        Write-Output ('{0} X {1} Y {2} LEFT {3} TOP {4} WIDTH {5} HEIGHT {6}' -f $infoFile.Name, $currentX, $currentY, $left, $top, $width, $height)
    }

    $infoBinaryReader.Close()
    $infoBinaryReader.Dispose()
    $infoFileStream.Close()
    $infoFileStream.Dispose()
}