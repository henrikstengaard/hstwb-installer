# Decrypt Rom
# -----------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-09-07
#
# A powershell script to decrypt Amiga kickstart roms.
#
# Reference: https://github.com/keirf/Amiga-Stuff/blob/master/kickconv.c


Param(
	[Parameter(Mandatory=$true)]
	[string]$keyFile,
	[Parameter(Mandatory=$true)]
	[string]$romFile,
	[Parameter(Mandatory=$true)]
	[string]$outputRomFile
)

# read key bytes
$keyBytes = @()
$keyBytes += [System.IO.File]::ReadAllBytes($keyFile)

# read rom bytes
$romBytes = @()
$romBytes += [System.IO.File]::ReadAllBytes($romFile)

# header for encrypted roms
$header = "AMIROMTYPE1"

# fail, if header from rom bytes doesn't match 
if ($header -ne [System.Text.Encoding]::ASCII.GetString($romBytes[0..($header.Length - 1)]))
{
    Write-Error "Rom file not encrypted"
    exit 1
}

# strip header from rom bytes
$romBytes = $romBytes[$header.Length..$romBytes.Count]

# decrypt rom bytes using bitwise xor of key bytes
for ($i = $j = 0; $i -lt $romBytes.Count; $i++)
{
    $romBytes[$i] = $romBytes[$i] -bxor $keyBytes[$j]
    $j = ($j + 1) % $keyBytes.Count
}

# write decrypted rom bytes til output rom file
[System.IO.File]::WriteAllBytes($outputRomFile, $romBytes)