# powershell script to remove carrier return from amiga script files

Param(
	[Parameter(Mandatory=$true)]
	[string]$dir
)

function IsText($byte)
{
    # bytearray({7,8,9,10,12,13,27} | set(range(0x20, 0x100)) - {0x7f})
    return $byte -eq 7 -or $byte -eq 8 -or $byte -eq 9 -or $byte -eq 10 -or $byte -eq 12 -or
        $byte -eq 13 -or $byte -eq 27 -or ($byte -ge 0x20 -and $byte -le 0x7e) -or
        ($byte -ge 0x80 -and $byte -le 255)
}

function IsTextFile($bytes)
{
    for($i = 0; $i -lt $bytes.Length; $i++)
    {
        if ($i -le $bytes.Length - $i - 1 -and (!(IsText($bytes[$i])) -or !(IsText($bytes[$bytes.Length - $i - 1]))))
        {
            return $false
        }
    }

    return $true
}

function HasCarrierReturn($bytes)
{
    for($i = 0; $i -lt $bytes.Length; $i++)
    {
        if ($i -le $bytes.Length - $i - 1 -and $bytes[$i] -eq 13 -or $bytes[$bytes.Length - $i - 1] -eq 13)
        {

            return $true
        }
    }

    return $false
}

$files = Get-ChildItem -Recurse $dir -File

ForEach ($file in $files)
{
    $bytes = @()
    $bytes += [System.IO.File]::ReadAllBytes($file.FullName)

    if (!(IsTextFile($bytes)))
    {
        continue
    }

    if (!(HasCarrierReturn($bytes)))
    {
        continue
    }

    Write-Host $file.FullName
    
    # read lines from file
    $lines = @()
    $lines = Get-Content -Path $file.FullName

    # write lines joined with only newline
    Set-Content -Path $file.FullName -NoNewline -Value (($lines -join "`n") + "`n")
}
