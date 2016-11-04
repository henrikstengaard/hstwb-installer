function WriteAmigaTextLines($path, $lines)
{
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	$utf8 = [System.Text.Encoding]::UTF8;

	$amigaTextBytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($lines -join "`n"))
	[System.IO.File]::WriteAllText($path, $iso88591.GetString($amigaTextBytes), $iso88591)
}

# resolve paths
$filesListFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("workbench3.1_files.txt")
$md5ScriptFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("workbench3.1_files_md5")

$md5ScriptLines = @('ECHO "" NOLINE >RAM:workbench3.1_md5.txt')

$files = Get-Content $filesListFile

foreach ($file in $files)
{
	$md5ScriptLines += @(
		('IF EXISTS "' + $file + '"'),
		('  SET md5 `md5 "' + $file + '"`'),
		('  ECHO "$md5;' + $file + '" >>RAM:workbench3.1_md5.txt'),
		'ENDIF')
}

WriteAmigaTextLines $md5ScriptFile $md5ScriptLines
