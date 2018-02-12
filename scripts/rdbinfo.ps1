# RDB Info
# --------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-07-30
#
# A powershell script to read rigid disk block from a hdf file and display drive and partition information.
#
# Reference 1: http://lclevy.free.fr/adflib/adf_info.html#p6
# Reference 2: https://searchcode.com/file/55055344/partmap/amiga.c


Param(
	[Parameter(Mandatory=$true)]
	[string]$hdfFile
)


# convert bytes from little endian to int32
function ConvertToInt32([byte[]]$bytes)
{
	[Array]::Reverse($bytes)
	return [System.BitConverter]::ToInt32($bytes, 0)
}


# convert bytes from little endian to uint32
function ConvertToUInt32([byte[]]$bytes)
{
	[Array]::Reverse($bytes)
	return [System.BitConverter]::ToUInt32($bytes, 0)
}


# read magic
function ReadMagic($binaryReader)
{
    $magicBytes = $binaryReader.ReadBytes(4)
    return [System.Text.Encoding]::ASCII.GetString($magicBytes)
}


# read rigid disk block from binary reader
function ReadRigidDiskBlock($binaryReader)
{
    $magic = ReadMagic $binaryReader
    if ($magic -ne 'RDSK')
    {
        return $null
    }

    $size = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $checksum = ConvertToInt32 $binaryReader.ReadBytes(4)
    $hostId = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $blockSize = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $flags = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $badBlockList = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $partitionList = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $fileSysHdrList = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $driveInitCode = ConvertToUInt32 $binaryReader.ReadBytes(4)

    # read reserved
    for ($i = 0; $i -lt 6; $i++)
    {
        [void]$binaryReader.ReadBytes(4)
    }

    # physical drive caracteristics
    $cylinders = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $sectors = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $heads = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $interleave = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $parkingZone = ConvertToUInt32 $binaryReader.ReadBytes(4)

    # read reserved
    for ($i = 0; $i -lt 3; $i++)
    {
        [void]$binaryReader.ReadBytes(4)
    }

    $writePreComp = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $reducedWrite = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $stepRate = ConvertToUInt32 $binaryReader.ReadBytes(4)

    # read reserved
    for ($i = 0; $i -lt 5; $i++)
    {
        [void]$binaryReader.ReadBytes(4)
    }

    # logical drive caracteristics
    $rdbBlockLo = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $rdbBlockHi = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $loCylinder = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $hiCylinder = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $cylBlocks = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $autoParkSeconds = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $highRsdkBlock = ConvertToUInt32 $binaryReader.ReadBytes(4)
    [void]$binaryReader.ReadBytes(4)

    $iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");

    # drive identification
    $diskVendorBytes = $binaryReader.ReadBytes(8)
    $diskProductBytes = $binaryReader.ReadBytes(16)
    $diskRevisionBytes = $binaryReader.ReadBytes(4)
    $controllerVendorBytes = $binaryReader.ReadBytes(8)
    $controllerProductBytes = $binaryReader.ReadBytes(16)
    $controllerRevisionBytes = $binaryReader.ReadBytes(4)
    [void]$binaryReader.ReadBytes(4)

    return New-Object PSObject -Property @{
		'Size' = $size;
		'Checksum' = $checksum;
		'HostId' = $hostId;
		'BlockSize' = $blockSize;
		'Flags' = $flags;
		'BadBlockList' = $badBlockList;
		'PartitionList' = $partitionList;
		'FileSysHdrList' = $fileSysHdrList;
		'DriveInitCode' = $driveInitCode;
		'Cylinders' = $cylinders;
		'Sectors' = $sectors;
		'Heads' = $heads;
		'Interleave' = $interleave;
		'ParkingZone' = $parkingZone;
		'WritePreComp' = $writePreComp;
		'ReducedWrite' = $reducedWrite;
		'StepRate' = $stepRate;
		'RdbBlockLo' = $rdbBlockLo;
		'RdbBlockHi' = $rdbBlockHi;
		'LoCylinder' = $loCylinder;
		'HiCylinder' = $hiCylinder;
		'CylBlocks' = $cylBlocks;
		'AutoParkSeconds' = $autoParkSeconds;
		'HighRsdkBlock' = $highRsdkBlock;
		'DiskVendor' = $iso88591.GetString($diskVendorBytes);
		'DiskProduct' = $iso88591.GetString($diskProductBytes);
		'DiskRevision' = $iso88591.GetString($diskRevisionBytes);
		'ControllerVendor' = $iso88591.GetString($controllerVendorBytes);
		'ControllerProduct' = $iso88591.GetString($controllerProductBytes);
		'ControllerRevision' = $iso88591.GetString($controllerRevisionBytes);
    }
}


# read partition block from binary reader
function ReadPartitionBlock($binaryReader)
{
    $magic = ReadMagic $binaryReader
    if ($magic -ne 'PART')
    {
        return $null
    }

    $size = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $checksum = ConvertToInt32 $binaryReader.ReadBytes(4)
    $hostId = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $nextPartitionBlock = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $flags = ConvertToUInt32 $binaryReader.ReadBytes(4)

    # read reserved
    for ($i = 0; $i -lt 2; $i++)
    {
        $binaryReader.ReadUInt32()
    }

    $devFlags = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $driveNameLength = $binaryReader.ReadByte()
    $driveNameBytes = $binaryReader.ReadBytes($driveNameLength)

    if ($driveNameLength -lt 31)
    {
        $binaryReader.ReadBytes(31 - $driveNameLength)
    }

    $iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
    $driveName = $iso88591.GetString($driveNameBytes)

    # read reserved
    for ($i = 0; $i -lt 15; $i++)
    {
        $binaryReader.ReadUInt32()
    }

    $sizeOfVector = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $sizeBlock = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $secOrg = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $surfaces = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $sectors = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $blocksPerTrack = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $binaryReader.ReadUInt32()
    $preAlloc = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $interleave = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $lowCyl	= ConvertToUInt32 $binaryReader.ReadBytes(4)
    $highCyl = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $numBuffer = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $bufMemType = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $maxTransfer = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $mask = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $bootPriority = ConvertToUInt32 $binaryReader.ReadBytes(4)
    $dosType = $binaryReader.ReadBytes(4)


    return New-Object PSObject -Property @{
		'Size' = $size;
		'Checksum' = $checksum;
		'HostId' = $hostId;
		'NextPartitionBlock' = $nextPartitionBlock;
		'Flags' = $flags;
		'DevFlags' = $devFlags;
        'DriveName' = $driveName;
        'Surfaces' = $surfaces;
        'BlocksPerTrack' = $blocksPerTrack;
		'LowCyl' = $lowCyl;
		'HighCyl' = $highCyl;
		'NumBuffer' = $numBuffer;
		'BufMemType' = $bufMemType;
		'MaxTransfer' = $maxTransfer;
		'Mask' = $mask;
		'BootPriority' = $bootPriority;
		'DosType' = $dosType;
	}
}


# format bytes
function FormatBytes($size, $precision)
{
    $base = [Math]::Log($size, 1024)
    $units = @('', 'K', 'M', 'G', 'T')
    return "{0} {1}B" -f [Math]::Round([Math]::Pow(1024, $base - [Math]::Floor($base)), $precision), $units[[Math]::Floor($base)]
}


# format integer
function FormatInteger($value)
{
    $bytes = [System.BitConverter]::GetBytes($value)
    [array]::Reverse($bytes)
    return ConvertToHex $bytes
}


# convert to hex
function ConvertToHex($bytes)
{
    return ($bytes | foreach-object { '{0:x2}' -f $_ }) -join ''
}


# write program information
Write-Output 'RDBInfo'
Write-Output '-------'
Write-Output ("Hdf file = {0}" -f $hdfFile)
Write-Output ''


# fail, if hdf file doesn't exist
if (!(Test-Path $hdfFile))
{
    throw ("Hdf file '{0}' doesn't exist!" -f $hdfFile)
}


# open hdf file stream and binary reader
$stream = New-Object System.IO.FileStream $hdfFile, 'Open', 'Read', 'Read'
$binaryReader = New-Object System.IO.BinaryReader($stream)


$block = 0
$blockSize = 512


# read rigid disk block from one of the first 15 blocks
do
{
    # calculate block offset
    $blockOffset = $blockSize * $block

    # seek block offset
    [void]$binaryReader.BaseStream.Seek($blockOffset, [System.IO.SeekOrigin]::Begin)

    # read rigid disk block
    $rigidDiskBlock = ReadRigidDiskBlock $binaryReader

    $block++
}while ($block -lt 15 -and $rigidDiskBlock -eq $null)


# fail, if rigid disk block is null
if ($rigidDiskBlock -eq $null)
{
    throw 'Invalid rigid disk block!'
}


# calculate drive size
$driveSize = $rigidDiskBlock.Cylinders * $rigidDiskBlock.Heads * $rigidDiskBlock.Sectors * $blockSize

# write drive information
Write-Output "Drive"
Write-Output "-----"
Write-Output ("Manufacturers Name = {0}" -f $rigidDiskBlock.DiskVendor)
Write-Output ("Drive Name = {0}" -f $rigidDiskBlock.DiskProduct)
Write-Output ("Drive Revision = {0}" -f $rigidDiskBlock.DiskRevision)
Write-Output ''
Write-Output ("Cylinders = {0}" -f $rigidDiskBlock.Cylinders)
Write-Output ("Heads = {0}" -f $rigidDiskBlock.Heads)
Write-Output ("Size = {0}" -f (FormatBytes $driveSize 0))
Write-Output ("Blocks per Track = {0}" -f $rigidDiskBlock.Sectors)
Write-Output ("Blocks per Cylinder = {0}" -f $rigidDiskBlock.CylBlocks)
Write-Output ("Park head where cylinder = {0}" -f $rigidDiskBlock.ParkingZone)


# get partition list block and set partition number to 1
$partitionList = $rigidDiskBlock.PartitionList
$partitionNumber = 1;


do
{
    # calculate partition block offset
    $partitionBlockOffset = $rigidDiskBlock.BlockSize * $partitionList

    # seek partition block offset
    [void]$binaryReader.BaseStream.Seek($partitionBlockOffset, [System.IO.SeekOrigin]::Begin)

    # read partition block
    $partitionBlock = ReadPartitionBlock $binaryReader

    # fail, if partition block is null
    if ($partitionBlock -eq $null)
    {
        throw 'Invalid partition block!'
    }

    # Calculate partition size
    $partitionSize = ($partitionBlock.HighCyl - $partitionBlock.LowCyl + 1) * $partitionBlock.Surfaces * $partitionBlock.BlocksPerTrack * $rigidDiskBlock.BlockSize

    $iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
    $dosTypeFormatted = '{0}\{1}' -f $iso88591.GetString(($partitionBlock.DosType | Select-Object -First 3)), $partitionBlock.DosType[3]
    
    $partitionName = "Partition {0}" -f $partitionNumber

    # write partition information
    Write-Output ''
    Write-Output $partitionName
    Write-Output (new-object System.String('-', $partitionName.Length))

    Write-Output ("Partition Device Name = {0}" -f $partitionBlock.DriveName)
    Write-Output ("Start Cyl = {0}" -f $partitionBlock.LowCyl)
    Write-Output ("End Cyl = {0}" -f $partitionBlock.HighCyl)
    Write-Output ("Total Cyl = {0}" -f ($partitionBlock.HighCyl - $partitionBlock.LowCyl + 1))
    Write-Output ("Buffers = {0}" -f $partitionBlock.NumBuffer)

    Write-Output ("Mask = 0x{0}" -f (FormatInteger $partitionBlock.Mask))
    Write-Output ("Max Transfer = 0x{0}, ({1})" -f (FormatInteger $partitionBlock.MaxTransfer), $partitionBlock.MaxTransfer)
    Write-Output ("Boot Priority = {0}" -f $partitionBlock.BootPriority)

    Write-Output ("Dos Type = 0x{0}, ({1})" -f (ConvertToHex $partitionBlock.DosType), $dosTypeFormatted)
    Write-Output ("Partition Size = {0}" -f (FormatBytes $partitionSize 0))


    # get next partition list block and increase partition number
    $partitionList = $partitionBlock.NextPartitionBlock
    $partitionNumber++
} while ($partitionList -gt 0 -and $partitionList -ne 4294967295)


# close and dispose binary reader and stream
$binaryReader.Close()
$binaryReader.Dispose()
$stream.Close()
$stream.Dispose()