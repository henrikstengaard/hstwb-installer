# Build EAB WHDLoad Pack Install Script
# -------------------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-11-22
#
# A powershell script to build EAB WHDLoad Pack install script, that copies directories and extracts .lha and .zip files.


Param(
	[Parameter(Mandatory=$true)]
	[string]$userPackageDir
)

# write amiga text lines
function WriteAmigaTextLines($path, $lines)
{
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	$utf8 = [System.Text.Encoding]::UTF8;

	$amigaTextBytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($lines -join "`n"))
	[System.IO.File]::WriteAllText($path, $iso88591.GetString($amigaTextBytes), $iso88591)
}

# paths
$userPackageDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($userPackageDir)

# get user package items
$userPackageItems = @()
$userPackageItems += Get-ChildItem -Path $userPackageDir | Where-Object { $_.Name -notmatch '^(_install|_installdir)$' }

# install script lines
$installScriptLines = @()
$installScriptLines += '; EAB WHDLoad Pack Install Script'
$installScriptLines += '; -------------------------------'
$installScriptLines += ';'
$installScriptLines += '; Author: Henrik Noerfjand Stengaard'
$installScriptLines += ("; Date: {0}" -f (Get-Date -format "yyyy-MM-dd"))
$installScriptLines += ''
$installScriptLines += "; '{0}' install script" -f (Split-Path $userPackageDir -Leaf)

# build install script lines
foreach($userPackageItem in ($userPackageItems | Sort-Object @{expression={$_.Name};Ascending=$true}))
{
    $installScriptLines += ''
    $installScriptLines += "; Install '{0}'" -f $userPackageItem.Name
    $installScriptLines += "IF EXISTS ""USERPACKAGEDIR:{0}""" -f $userPackageItem.Name
    if ($userPackageItem.PSIsContainer)
    {
        $installScriptLines += "  set itemdir ""``execute INSTALLDIR:S/CombinePath ""`$INSTALLDIR"" ""{0}""``""" -f $userPackageItem.Name
        $installScriptLines += "  echo ""Copying '{0}'...""" -f $userPackageItem.Name
        $installScriptLines += "  IF NOT EXISTS ""`$itemdir""" -f $userPackageItem.Name
        $installScriptLines += "    MakePath >NIL: ""`$itemdir""" -f $userPackageItem.Name
        $installScriptLines += "  ENDIF"
        $installScriptLines += "  Copy >NIL: ""USERPACKAGEDIR:{0}"" ""`$itemdir"" ALL" -f $userPackageItem.Name
    }
    elseif ($userPackageItem.Name -match '\.(lha|zip)$')
    {
        if ($userPackageItem.Name -match '^[0-9]')
        {
            $indexName = '0-9'
        }
        else
        {
            $indexName = $userPackageItem.Name.Substring(0, 1)
        }

        $installScriptLines += "  set itemdir ""``execute INSTALLDIR:S/CombinePath ""`$INSTALLDIR"" ""{0}""``""" -f $indexName
        $installScriptLines += "  echo ""Extracting '{0}'...""" -f $userPackageItem.Name
        $installScriptLines += "  IF NOT EXISTS ""`$itemdir""" -f $indexName
        $installScriptLines += "    MakePath >NIL: ""`$itemdir""" -f $indexName
        $installScriptLines += "  ENDIF"

        if ($userPackageItem.Name -match '\.lha$')
        {
            $installScriptLines += "  lha -q -m1 x ""USERPACKAGEDIR:{0}"" ""`$itemdir/""" -f $userPackageItem.Name, $indexName
        }
        elseif ($userPackageItem.Name -match '\.zip$')
        {
            $installScriptLines += "  unzip -qq -o -x ""USERPACKAGEDIR:{0}"" -d ""`$itemdir""" -f $userPackageItem.Name, $indexName
        }
    }
    else
    {
        $installScriptLines += "  Copy >NIL: ""USERPACKAGEDIR:{0}"" ""`$INSTALLDIR""" -f $userPackageItem.Name
    }
    $installScriptLines += "ENDIF"
}

# write install script file
$installScriptFile = Join-Path $userPackageDir -ChildPath '_install'
WriteAmigaTextLines $installScriptFile $installScriptLines
