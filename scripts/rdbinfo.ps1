# RDB Info
# --------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-02-14
#
# A powershell script to read rigid disk block from a hdf file and display drive and partition information.
#
# Reference 1: http://lclevy.free.fr/adflib/adf_info.html#p6
# Reference 2: https://searchcode.com/file/55055344/partmap/amiga.c
# Reference 3: https://github.com/trentm/illumos-joyent/blob/master/usr/src/lib/libparted/common/libparted/labels/rdb.c

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
    $magic = ReadMagic $binaryReader # Identifier 32 bit word : 'RDSK'
    if ($magic -ne 'RDSK')
    {
        return $null
    }

    $size = ConvertToUInt32 $binaryReader.ReadBytes(4) # Size of the structure for checksums
    $checksum = ConvertToInt32 $binaryReader.ReadBytes(4) # Checksum of the structure
    $hostId = ConvertToUInt32 $binaryReader.ReadBytes(4) # SCSI Target ID of host, not really used
    $blockSize = ConvertToUInt32 $binaryReader.ReadBytes(4) # Size of disk blocks
    $flags = ConvertToUInt32 $binaryReader.ReadBytes(4) # RDB Flags
    $badBlockList = ConvertToUInt32 $binaryReader.ReadBytes(4) # Bad block list
    $partitionList = ConvertToUInt32 $binaryReader.ReadBytes(4) # Partition list
    $fileSysHdrList = ConvertToUInt32 $binaryReader.ReadBytes(4) # File system header list
    $driveInitCode = ConvertToUInt32 $binaryReader.ReadBytes(4) # Drive specific init code
    $bootBlockList = ConvertToUInt32 $binaryReader.ReadBytes(4) # Amiga OS 4 Boot Blocks

    # read reserved, unused word, need to be set to $ffffffff
    for ($i = 0; $i -lt 5; $i++)
    {
        [void]$binaryReader.ReadBytes(4)
    }

    # physical drive caracteristics
    $cylinders = ConvertToUInt32 $binaryReader.ReadBytes(4) # Number of the cylinders of the drive
    $sectors = ConvertToUInt32 $binaryReader.ReadBytes(4) # Number of sectors of the drive
    $heads = ConvertToUInt32 $binaryReader.ReadBytes(4) # Number of heads of the drive
    $interleave = ConvertToUInt32 $binaryReader.ReadBytes(4) # Interleave 
    $parkingZone = ConvertToUInt32 $binaryReader.ReadBytes(4) # Head parking cylinder

    # read reserved, unused word, need to be set to $ffffffff
    for ($i = 0; $i -lt 3; $i++)
    {
        [void]$binaryReader.ReadBytes(4)
    }

    $writePreComp = ConvertToUInt32 $binaryReader.ReadBytes(4) # Starting cylinder of write precompensation 
    $reducedWrite = ConvertToUInt32 $binaryReader.ReadBytes(4) # Starting cylinder of reduced write current
    $stepRate = ConvertToUInt32 $binaryReader.ReadBytes(4) # Step rate of the drive

    # read reserved, unused word, need to be set to $ffffffff
    for ($i = 0; $i -lt 5; $i++)
    {
        [void]$binaryReader.ReadBytes(4)
    }

    # logical drive caracteristics
    $rdbBlockLo = ConvertToUInt32 $binaryReader.ReadBytes(4) # low block of range reserved for hardblocks
    $rdbBlockHi = ConvertToUInt32 $binaryReader.ReadBytes(4) # high block of range for these hardblocks
    $loCylinder = ConvertToUInt32 $binaryReader.ReadBytes(4) # low cylinder of partitionable disk area
    $hiCylinder = ConvertToUInt32 $binaryReader.ReadBytes(4) # high cylinder of partitionable data area
    $cylBlocks = ConvertToUInt32 $binaryReader.ReadBytes(4) # number of blocks available per cylinder
    $autoParkSeconds = ConvertToUInt32 $binaryReader.ReadBytes(4) # zero for no auto park
    $highRsdkBlock = ConvertToUInt32 $binaryReader.ReadBytes(4) # highest block used by RDSK (not including replacement bad blocks)
    [void]$binaryReader.ReadBytes(4) # read reserved, unused word

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
    $magic = ReadMagic $binaryReader # Identifier 32 bit word : 'PART'
    if ($magic -ne 'PART')
    {
        return $null
    }

    $size = ConvertToUInt32 $binaryReader.ReadBytes(4) # Size of the structure for checksums
    $checksum = ConvertToInt32 $binaryReader.ReadBytes(4) # Checksum of the structure
    $hostId = ConvertToUInt32 $binaryReader.ReadBytes(4) # SCSI Target ID of host, not really used 
    $nextPartitionBlock = ConvertToUInt32 $binaryReader.ReadBytes(4) # Block number of the next PartitionBlock
    $flags = ConvertToUInt32 $binaryReader.ReadBytes(4) # Part Flags (NOMOUNT and BOOTABLE)

    # read reserved
    for ($i = 0; $i -lt 2; $i++)
    {
        $binaryReader.ReadUInt32()
    }

    $devFlags = ConvertToUInt32 $binaryReader.ReadBytes(4) # Preferred flags for OpenDevice
    $driveNameLength = $binaryReader.ReadByte() # Preferred DOS device name: BSTR form
    $driveNameBytes = $binaryReader.ReadBytes($driveNameLength) # Preferred DOS device name: BSTR form

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

    $sizeOfVector = ConvertToUInt32 $binaryReader.ReadBytes(4) # Size of Environment vector
    $sizeBlock = ConvertToUInt32 $binaryReader.ReadBytes(4) # Size of the blocks in 32 bit words, usually 128
    $secOrg = ConvertToUInt32 $binaryReader.ReadBytes(4) # Not used; must be 0
    $surfaces = ConvertToUInt32 $binaryReader.ReadBytes(4) # Number of heads (surfaces)
    $sectors = ConvertToUInt32 $binaryReader.ReadBytes(4) # Disk sectors per block, used with SizeBlock, usually 1
    $blocksPerTrack = ConvertToUInt32 $binaryReader.ReadBytes(4) # Blocks per track. drive specific
    $reserved = ConvertToUInt32 $binaryReader.ReadBytes(4) # DOS reserved blocks at start of partition.
    $preAlloc = ConvertToUInt32 $binaryReader.ReadBytes(4) # DOS reserved blocks at end of partition
    $interleave = ConvertToUInt32 $binaryReader.ReadBytes(4) # Not used, usually 0
    $lowCyl	= ConvertToUInt32 $binaryReader.ReadBytes(4) # First cylinder of the partition
    $highCyl = ConvertToUInt32 $binaryReader.ReadBytes(4) # Last cylinder of the partition
    $numBuffer = ConvertToUInt32 $binaryReader.ReadBytes(4) # Initial # DOS of buffers.
    $bufMemType = ConvertToUInt32 $binaryReader.ReadBytes(4) # Type of mem to allocate for buffers
    $maxTransfer = ConvertToUInt32 $binaryReader.ReadBytes(4) # Max number of bytes to transfer at a time
    $mask = ConvertToUInt32 $binaryReader.ReadBytes(4) # Address Mask to block out certain memory
    $bootPriority = ConvertToUInt32 $binaryReader.ReadBytes(4) # Boot priority for autoboot
    $dosType = $binaryReader.ReadBytes(4) # Dostype of the file system
    $baud = ConvertToUInt32 $binaryReader.ReadBytes(4) # Baud rate for serial handler
    $control = ConvertToUInt32 $binaryReader.ReadBytes(4) # Control word for handler/filesystem 
    $bootBlocks = ConvertToUInt32 $binaryReader.ReadBytes(4) # Number of blocks containing boot code 

    # read reserved
    for ($i = 0; $i -lt 12; $i++)
    {
        $binaryReader.ReadUInt32()
    }
    

    return New-Object PSObject -Property @{
		'Size' = $size;
		'Checksum' = $checksum;
		'HostId' = $hostId;
		'NextPartitionBlock' = $nextPartitionBlock;
		'Flags' = $flags;
		'DevFlags' = $devFlags;
        'DriveName' = $driveName;
        'SizeBlock' = $sizeBlock;
        'Surfaces' = $surfaces;
        'Sectors' = $sectors;
        'BlocksPerTrack' = $blocksPerTrack;
        'Reserved' = $reserved;
        'PreAlloc' = $preAlloc;
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



# add flags enum type
Add-Type -TypeDefinition @"
	[System.Flags]
	public enum PartitionFlagsEnum
	{
		Bootable = 1,
        NoMount = 2,
        Raid = 4,
        Lvm = 8
	}
"@


# fail, if hdf file doesn't exist
if (!(Test-Path $hdfFile))
{
    throw ("Hdf file '{0}' doesn't exist!" -f $hdfFile)
}

# get hdf size
$hdfSize = (Get-Item $hdfFile).Length

# write program information
Write-Output 'RDBInfo'
Write-Output '-------'
Write-Output ("Hdf File = {0}" -f $hdfFile)
Write-Output ("Hdf Size = {0} ({1} bytes)" -f (FormatBytes $hdfSize 1), $hdfSize)
Write-Output ''


# open hdf file stream and binary reader
$stream = New-Object System.IO.FileStream $hdfFile, 'Open', 'Read', 'Read'
$binaryReader = New-Object System.IO.BinaryReader($stream)


$block = 0
$blockSize = 512
$rdbLocationLimit = 16

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
}while ($block -lt $rdbLocationLimit -and $rigidDiskBlock -eq $null)


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
Write-Output ("Drive Size = {0} ({1} bytes)" -f (FormatBytes $driveSize 1), $driveSize)
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
    $dosTypeFormatted = '{0}\{1:d2}' -f $iso88591.GetString(($partitionBlock.DosType | Select-Object -First 3)), $partitionBlock.DosType[3]
    
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
    Write-Output ("File System Block Size = {0}" -f ($partitionBlock.SizeBlock * 4 * $partitionBlock.Sectors))
    Write-Output ("Reserved = {0} (DOS Blocks reserved at the beginning of partition)" -f $partitionBlock.Reserved)
    Write-Output ("PreAlloc = {0} (DOS Blocks reserved at the end of partition)" -f $partitionBlock.PreAlloc)

    $partitionFlags = [PartitionFlagsEnum]$partitionBlock.Flags

    if ($partitionFlags -band [PartitionFlagsEnum]::Bootable)
    {
        Write-Output ("Bootable, Boot Priority = {0}" -f $partitionBlock.BootPriority)
    }

    if ($partitionFlags -band [PartitionFlagsEnum]::NoMount)
    {
        Write-Output "No Automount"
    }

    Write-Output ("Mask = 0x{0}" -f (FormatInteger $partitionBlock.Mask))
    Write-Output ("Max Transfer = 0x{0}, ({1})" -f (FormatInteger $partitionBlock.MaxTransfer), $partitionBlock.MaxTransfer)
    Write-Output ("Dos Type = 0x{0}, ({1})" -f (ConvertToHex $partitionBlock.DosType), $dosTypeFormatted)
    Write-Output ("Partition Size = {0} ({1} bytes)" -f (FormatBytes $partitionSize 1), $partitionSize)


    # get next partition list block and increase partition number
    $partitionList = $partitionBlock.NextPartitionBlock
    $partitionNumber++
} while ($partitionList -gt 0 -and $partitionList -ne 4294967295)


# close and dispose binary reader and stream
$binaryReader.Close()
$binaryReader.Dispose()
$stream.Close()
$stream.Dispose()