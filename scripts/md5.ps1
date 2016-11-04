Param(
	[Parameter(Mandatory=$true)]
	[string]$adfPath
)

function CalculateMd5($path)
{
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	return [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($path)))
}

$files = Get-ChildItem -Path $adfPath -filter "*.*"

foreach ($file in $files)
{
	$md5 = (CalculateMd5 $file.FullName).ToLower().Replace('-', '')

	Write-Output ($file.Name + ";" + $md5)
}
