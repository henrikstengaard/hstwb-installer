# Calculate Drive Geometry
# ------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-01-25
#
# A powershell script to calculate drive geometry for manual configuration using HDToolBox
#
# Calculate drive geometry for a drive of size 15200000000 bytes, a partition of size 500MB and a partition that expands to available cylinders:
# .\calculate_drive_geometry.ps1 -driveSize '15200000000' -partitions '500MB','+'
#
# Calculate drive geometry for a drive of size 20 gb, a partition of size 500MB and 2 partitions that expands to available cylinders:
# .\calculate_drive_geometry.ps1 -driveSize '20GB' -partitions '500MB','+','+'
#
# Calculate drive geometry for a drive of size 8gb.hdf file is in bytes, a partition of size 100MB and a partition that expands to available cylinders:
# .\calculate_drive_geometry.ps1 -driveSize ((get-item '8gb.hdf').length) -partitions '100MB','+'

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
$driveCylinders = [math]::Floor($driveBytes / ($heads * $blocksPerTrack * $sectorSize))
$totalBlocks = $driveCylinders * $heads * $blocksPerTrack

# show drive geometry
Write-Host "Drive Geometry" -ForegroundColor 'Yellow'
Write-Host ("Drive size:            {0} ({1} bytes)" -f (FormatBytes $driveBytes), $driveBytes)
Write-Host ("Drive blocks:          {0}" -f $driveBlocks)
Write-Host ""
Write-Host ("Cylinders:             {0}" -f $driveCylinders)
Write-Host ("Heads:                 {0}" -f $heads)
Write-Host ("Blocks per track:      {0}" -f $blocksPerTrack)
Write-Host ("Blocks per cylinder:   {0}" -f $blocksPerCylinder)
Write-Host ("Total blocks:          {0}" -f $totalBlocks)


$expandableCylinders = $driveCylinders - 1
$partitions = @()

# calculate bytes and cylinders per partition and expandable cylinders
for($i = 0; $i -lt $partitionSizes.Count; $i++)
{
	$partitionSize = $partitionSizes[$i]

	$expandable = $partitionSize -match '\+'

	if ($expandable)
	{
		$bytes = 0
		$cylinders = 0
	}
	else
	{
		$bytes = ConvertToBytes $partitionSize
		$cylinders = [math]::Floor($bytes / ($heads * $blocksPerTrack * $sectorSize))
		$expandableCylinders -= $cylinders
	}

	$partitions += @{ 'Expandable' = $expandable; 'Bytes' = $bytes; 'Cylinders' = $cylinders }
}

# calculate expandable partition cylinders
$expandablePartitions = @()
$expandablePartitions += $partitions | Where-Object { $_.Expandable }
if ($expandablePartitions.Count -gt 0)
{
	$expandablePartitionCylinders = [math]::Floor($expandableCylinders / $expandablePartitions.Count)
}
else
{
	$expandablePartitionCylinders = $expandableCylinders
}

# calculate expandable partition bytes
$expandablePartitionBytes = $expandablePartitionCylinders * $heads * $blocksPerTrack * $sectorSize

# show partitions geometry
$startCylinder = 2
for($i = 0; $i -lt $partitions.Count; $i++)
{
	$partition = $partitions[$i]

	if ($partition.Expandable)
	{
		$bytes = $expandablePartitionBytes
		$cylinders = $expandablePartitionCylinders
	}
	else
	{
		$bytes = $partition.Bytes
		$cylinders = $partition.Cylinders
	}

	# calculate end cylinder
	$endCylinder = $startCylinder + $cylinders - 1

	# adjust cylinders and bytes, if end cylinder is larger than drive cylinders
	if ($endCylinder -ge $driveCylinders)
	{
		$endCylinder = $driveCylinders - 1
		$cylinders = $endCylinder - $startCylinder
		$bytes = $cylinders * $heads * $blocksPerTrack * $sectorSize
	}

	Write-Host ""
	Write-Host ("Partition {0}" -f ($i + 1)) -ForegroundColor 'Yellow'
	Write-Host ("Partition Size:        {0} ({1} bytes)" -f (FormatBytes $bytes), $bytes)
	Write-Host ("Start Cylinder:        {0}" -f $startCylinder)
	Write-Host ("End Cylinder:          {0}" -f $endCylinder)
	Write-Host ("Total Cylinders:       {0}" -f $cylinders)

	$startCylinder += $cylinders
}