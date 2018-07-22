# https://github.com/keirf/Amiga-Stuff/blob/master/hunk_loader.c
# https://github.com/cnvogelg/amitools/blob/master/amitools/rom/RemusFile.py
# https://gist.github.com/iamgreaser/c1b12207d8295f761ee17bf610058f05
# http://amiga-dev.wikidot.com/file-format:hunk#toc7
# https://github.com/cnvogelg/amitools/blob/e7905be7203a1e28c0093bb868277f9ddf97d0cd/amitools/binfmt/hunk/HunkBlockFile.py
# http://amiga.rules.no/abfs/abfs.pdf
# https://github.com/mooli/openkick/blob/master/script/parserom.pl
# https://github.com/cnvogelg/amitools/blob/master/amitools/rom/RemusFile.py


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


$hunkFile = 'workbench.library_40.5'

# open hdf file stream and binary reader
$stream = New-Object System.IO.FileStream $hunkFile, 'Open', 'Read', 'Read'
$binaryReader = New-Object System.IO.BinaryReader($stream)

$hunkId = ConvertToUInt32 $binaryReader.ReadBytes(4)

if ((ConvertToUInt32 $binaryReader.ReadBytes(4)) -ne 0)
{
    throw "bad hunk"
}

$x = ConvertToUInt32 $binaryReader.ReadBytes(4)
$first = ConvertToUInt32 $binaryReader.ReadBytes(4)
$last = ConvertToUInt32 $binaryReader.ReadBytes(4)

Write-Output ("Table Size: {0}" -f $x)
Write-Output ("First: {0}" -f $first)
Write-Output ("Last: {0}" -f $last)

for ($i = $first; $i -le $last; $i++)
{
    $t = ConvertToUInt32 $binaryReader.ReadBytes(4)
    Write-Output ("Hunk {0}: {1} longwords" -f $i, $t)
}

$hunkId = ConvertToUInt32 $binaryReader.ReadBytes(4)
Write-Output ("Hunk Id: {0}" -f $hunkId)


# close and dispose binary reader and stream
$binaryReader.Close()
$binaryReader.Dispose()
$stream.Close()
$stream.Dispose()