# Calculate Drive Geometry
# ------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-01-21
#
# A powershell script to calculate drive geometry for manual configuration using HDToolBox

Param(
	[Parameter(Mandatory=$true, Position=0)]
	[string]$driveSize,
	[Parameter(Mandatory=$false)]
	[int32]$sectorSize = 512,
	[Parameter(Mandatory=$false)]
	[int32]$heads = 16,
	[Parameter(Mandatory=$false)]
	[int32]$blocksPerTrack = 63,
	[Parameter(Mandatory=$false)]
	[string[]]$partitionSizes
)

# convert to bytes
function ConvertToBytes($size)
{
	$bytes = [uint64]($size -replace '[bgkm]*$')

	if ($size -match 'kb$')
	{
		$bytes *= 1024
	}

	if ($size -match 'mb$')
	{
		$bytes *= [math]::Pow(1024, 2)
	}

	if ($size -match 'gb$')
	{
		$bytes *= [math]::Pow(1024, 3)
	}
	
	return $bytes
}

# format bytes
function FormatBytes($size, $precision)
{
    $base = [Math]::Log($size, 1024)
    $units = @('', 'K', 'M', 'G', 'T')
    return "{0} {1}B" -f [Math]::Round([Math]::Pow(1024, $base - [Math]::Floor($base)), $precision), $units[[Math]::Floor($base)]
}

# calculate drive bytes and blocks
$driveBytes = ConvertToBytes $driveSize
$driveBlocks = [math]::Floor($driveBytes / $sectorSize)

# calculate blocks per cylinder, cylinders and total blocks
$blocksPerCylinder = $heads * $blocksPerTrack
$cylinders = [math]::Floor($driveBytes / ($heads * $blocksPerTrack * $sectorSize))
$totalBlocks = $cylinders * $heads * $blocksPerTrack

# show drive geometry
Write-Host "Drive Geometry" -ForegroundColor 'Yellow'
Write-Host ("Drive size:            {0} ({1} bytes)" -f (FormatBytes $driveBytes), $driveBytes)
Write-Host ("Drive blocks:          {0}" -f $driveBlocks)
Write-Host ""
Write-Host ("Cylinders:             {0}" -f $cylinders)
Write-Host ("Heads:                 {0}" -f $heads)
Write-Host ("Blocks per track:      {0}" -f $blocksPerTrack)
Write-Host ("Blocks per cylinder:   {0}" -f $blocksPerCylinder)
Write-Host ("Total blocks:          {0}" -f $totalBlocks)


$startCylinder = 2

for($i = 0; $i -lt $partitionSizes.Count; $i++)
{
	$partitionSize = $partitionSizes[$i]

	$partitionBytes = ConvertToBytes $partitionSize
	$cylinders = [math]::Floor($partitionBytes / ($heads * $blocksPerTrack * $sectorSize))
	$endCylinders = $startCylinder + $cylinders - 1

	Write-Host ""
	Write-Host ("Partition {0}" -f ($i + 1)) -ForegroundColor 'Yellow'
	Write-Host ("Partition Size:        {0} ({1} bytes)" -f (FormatBytes $partitionBytes), $partitionBytes)
	Write-Host ("Start Cylinder:        {0}" -f $startCylinder)
	Write-Host ("End Cylinders:         {0}" -f $endCylinders)
	Write-Host ("Total Cylinders:       {0}" -f $cylinders)

	$startCylinder += $cylinders
}