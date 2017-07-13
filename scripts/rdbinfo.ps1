# http://lclevy.free.fr/adflib/adf_info.html#p6

Param(
	[Parameter(Mandatory=$true)]
	[string]$hdfFile
)

$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");


# get little endian int32
function GetLittleEndianInt32([uint32]$value)
{
	$bytes = [System.BitConverter]::GetBytes($value)
	[Array]::Reverse($bytes)
	return [System.BitConverter]::ToInt32($bytes, 0)
}


# get little endian uint32
function GetLittleEndianUInt32([uint32]$value)
{
	$bytes = [System.BitConverter]::GetBytes($value)
	[Array]::Reverse($bytes)
	return [System.BitConverter]::ToUInt32($bytes, 0)
}


# read rigid disk block from binary reader
function ReadRigidDiskBlock($binaryReader)
{
    $size = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $checksum = GetLittleEndianInt32 $binaryReader.ReadInt32()
    $hostId = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $blockSize = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $flags = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $badBlockList = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $partitionList = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $fileSysHdrList = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $driveInitCode = GetLittleEndianUInt32 $binaryReader.ReadUInt32()

    # read reserved
    for ($i = 0; $i -lt 6; $i++)
    {
        $binaryReader.ReadUInt32()
    }

    $cylinders = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $sectors = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $heads = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $interleave = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $parkingZone = GetLittleEndianUInt32 $binaryReader.ReadUInt32()

    # read reserved
    for ($i = 0; $i -lt 3; $i++)
    {
        $binaryReader.ReadUInt32()
    }

    $writePreComp = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $eeducedWrite = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $stepRate = GetLittleEndianUInt32 $binaryReader.ReadUInt32()

    # read reserved
    for ($i = 0; $i -lt 5; $i++)
    {
        $binaryReader.ReadUInt32()
    }
    
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
	}
}

# read partition block from binary reader
function ReadPartitionBlock($binaryReader)
{
    $size = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $checksum = GetLittleEndianInt32 $binaryReader.ReadUInt32()
    $hostId = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $nextPartitionBlock = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $flags = GetLittleEndianUInt32 $binaryReader.ReadUInt32()

    # read reserved
    for ($i = 0; $i -lt 2; $i++)
    {
        $binaryReader.ReadUInt32()
    }

    $devFlags = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $driveNameLength = $binaryReader.ReadByte()
    $driveNameBytes = $binaryReader.ReadBytes($driveNameLength)

    if ($driveNameLength -lt 31)
    {
        $binaryReader.ReadBytes(31 - $driveNameLength)
    }

    $driveName = $iso88591.GetString($driveNameBytes)

    # read reserved
    for ($i = 0; $i -lt 15; $i++)
    {
        $binaryReader.ReadUInt32()
    }

    $sizeOfVector = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $sizeBlock = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $secOrg = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $surfaces = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $sectors = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $blocks = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $binaryReader.ReadUInt32()
    $preAlloc = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $interleave = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $lowCyl	= GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $highCyl = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $numBuffer = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $bufMemType = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $maxTransfer = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $mask = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $bootPriority = GetLittleEndianUInt32 $binaryReader.ReadUInt32()
    $dosTypeBytes = $binaryReader.ReadBytes(4)
    $dosType = $iso88591.GetString($dosTypeBytes)

    return New-Object PSObject -Property @{
		'Size' = $size;
		'Checksum' = $checksum;
		'HostId' = $hostId;
		'NextPartitionBlock' = $nextPartitionBlock;
		'Flags' = $flags;
		'DevFlags' = $devFlags;
		'DriveName' = $driveName;
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


$hdfFileStream = New-Object System.IO.FileStream $hdfFile, 'Open', 'Read', 'Read'
$hdfFileBinaryReader = New-Object System.IO.BinaryReader($hdfFileStream)

$idBytes = $hdfFileBinaryReader.ReadBytes(4)

if ($iso88591.GetString($idBytes) -eq 'RDSK')
{
    $rigidDiskBlock = ReadRigidDiskBlock $hdfFileBinaryReader
}
else
{
    Write-Error "No rigid disk block!"
    exit 1
}

$partitionList = $rigidDiskBlock.PartitionList

do
{
    # calculate partition block offset
    $partitionBlockOffset = $rigidDiskBlock.BlockSize * $partitionList

    [void]$hdfFileBinaryReader.BaseStream.Seek($partitionBlockOffset, [System.IO.SeekOrigin]::Begin)
    $idBytes = $hdfFileBinaryReader.ReadBytes(4)

    if ($iso88591.GetString($idBytes) -ne 'PART')
    {
        break;
    }

    $partitionBlock = ReadPartitionBlock $hdfFileBinaryReader

    Write-Output ''
    Write-Output ("DriveName = '{0}'" -f $partitionBlock.DriveName)
    Write-Output ("LowCyl = '{0}'" -f $partitionBlock.LowCyl)
    Write-Output ("HighCyl = '{0}'" -f $partitionBlock.HighCyl)
    Write-Output ("NumBuffer = '{0}'" -f $partitionBlock.NumBuffer)
    Write-Output ("MaxTransfer = '{0}'" -f $partitionBlock.MaxTransfer)
    Write-Output ("BootPriority = '{0}'" -f $partitionBlock.BootPriority)
    Write-Output ("DosType = '{0}'" -f $partitionBlock.DosType)

    $partitionList = $partitionBlock.NextPartitionBlock
} while ($partitionList -gt 0)


$hdfFileBinaryReader.Close()
$hdfFileBinaryReader.Dispose()

$hdfFileStream.Close()
$hdfFileStream.Dispose()