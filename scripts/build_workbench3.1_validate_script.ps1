function WriteAmigaTextLines($path, $lines)
{
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	$utf8 = [System.Text.Encoding]::UTF8;

	$amigaTextBytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($lines -join "`n"))
	[System.IO.File]::WriteAllText($path, $iso88591.GetString($amigaTextBytes), $iso88591)
}

# resolve paths
$md5FilesListFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("workbench3.1_md5.txt")
$validateScriptFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("workbench3.1_validate_md5")

$validateScriptLines = @()

$md5Files = Get-Content $md5FilesListFile

foreach ($md5File in $md5Files)
{
	$columns = $md5File -split ';'
	$md5 = $columns[0]
	$file = $columns[1]

	$validateScriptLines += @(
		('IF EXISTS "' + $file + '"'),
		('  SET md5 `md5 "' + $file + '"`'),
		('  IF NOT "$md5" eq "' + $md5 + '"'),
		('    ECHO "File ''' + $file + ''' has invalid md5 checksum"'),
		"  ENDIF"
		'ELSE',
		('  ECHO "File ''' + $file + ''' doesn''t exist"'),
		'ENDIF')
}

WriteAmigaTextLines $validateScriptFile $validateScriptLines
