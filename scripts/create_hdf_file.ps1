# Create HDF File
# ---------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-11-29
#
# A powershell script to create an Amiga HDF file.


Param(
	[Parameter(Mandatory=$true)]
	[string]$outputDir
)


$hdfGbSize = Read-Host 'Enter HDF size in GB'
$hdfByteSize = [math]::round((([int32]$hdfGbSize * [math]::pow(10, 9)) * 0.95))

$hdfFileName = "{0}gb.hdf" -f $hdfGbSize

$hdfFile = Join-Path $outputDir -ChildPath $hdfFileName
$hdfFileStream = [io.file]::Create($hdfFile)
$hdfFileStream.SetLength($hdfByteSize)
$hdfFileStream.Close()

Write-Host ("Successfully created hdf file '{0}' with file size '{1}' MB" -f $hdfFile, [math]::round($hdfByteSize / [math]::pow(1024, 2))) -ForegroundColor 'Green'