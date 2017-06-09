Param(
	[Parameter(Mandatory=$true)]
	[string]$file
)

function Get-CRC32 {
    <#
        .SYNOPSIS
            Calculate CRC.
        .DESCRIPTION
            This function calculates the CRC of the input data using the CRC32 algorithm.
        .EXAMPLE
            Get-CRC32 $data
        .EXAMPLE
            $data | Get-CRC32
        .NOTES
            C to PowerShell conversion based on code in https://www.w3.org/TR/PNG/#D-CRCAppendix
            Author: Øyvind Kallstad
            Date: 06.02.2017
            Version: 1.0
        .INPUTS
            byte[]
        .OUTPUTS
            uint32
        .LINK
            https://communary.net/
        .LINK
            https://www.w3.org/TR/PNG/#D-CRCAppendix
    #>
    [CmdletBinding()]
    param (
        # Array of Bytes to use for CRC calculation
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [byte[]]$InputObject
    )

    Begin {

        function New-CrcTable {
            [uint32]$c = $null
            $crcTable = New-Object 'System.Uint32[]' 256

            for ($n = 0; $n -lt 256; $n++) {
                $c = [uint32]$n
                for ($k = 0; $k -lt 8; $k++) {
                    if ($c -band 1) {
                        $c = (0xEDB88320 -bxor ($c -shr 1))
                    }
                    else {
                        $c = ($c -shr 1)
                    }
                }
                $crcTable[$n] = $c
            }

            Write-Output $crcTable
        }

        function Update-Crc ([uint32]$crc, [byte[]]$buffer, [int]$length) {
            [uint32]$c = $crc

            if (-not($script:crcTable)) {
                $script:crcTable = New-CrcTable
            }

            for ($n = 0; $n -lt $length; $n++) {
                $c = ($script:crcTable[($c -bxor $buffer[$n]) -band 0xFF]) -bxor ($c -shr 8)
            }

            Write-output $c
        }

        $dataArray = @()
    }

    Process {
        foreach ($item  in $InputObject) {
            $dataArray += $item
        }
    }

    End {
        $inputLength = $dataArray.Length
        Write-Output ((Update-Crc -crc 0xffffffffL -buffer $dataArray -length $inputLength) -bxor 0xffffffffL)
    }
}

function CalculateCrc32($file)
{
    return [System.Convert]::ToString(([System.Text.Encoding]::ASCII.GetBytes($file) | Get-CRC32), 16)
}

CalculateCrc32 $file