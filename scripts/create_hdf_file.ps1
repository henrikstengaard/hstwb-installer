$hdfGbSize = Read-Host 'Enter HDF size in GB'
$hdfByteSize = [math]::round((([int32]$hdfGbSize * [math]::pow(10, 9)) * 0.95))

$hdfFileName = "{0}gb.hdf" -f $hdfGbSize

$hdfFile = [io.file]::Create($hdfFileName)
$hdfFile.SetLength($hdfByteSize)
$hdfFile.Close()

Write-Host ("Successfully created '{0}' with file size '{1}' MB" -f $hdfFileName, [math]::round($hdfByteSize / [math]::pow(1024, 2))) -ForegroundColor 'Green'