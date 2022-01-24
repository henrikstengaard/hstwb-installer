# hack to fix electron updater throwing exception "Cannot find module 'fs/promises'"
# https://stackoverflow.com/questions/64725249/fs-promises-api-in-typescript-not-compiling-in-javascript-correctly

$appUpdaterPath = 'obj\Host\node_modules\electron-updater\out\AppUpdater.js'
if (Test-Path $appUpdaterPath)
{
    $isUpdated = $false
    $appUpdaterLines = Get-Content $appUpdaterPath
    for($i = 0; $i -lt $appUpdaterLines.Length; $i++)
    {
        if ($appUpdaterLines[$i] -match 'promises_1 = require\("fs/promises"\)')
        {
            $isUpdated = $true
            $appUpdaterLines[$i] = $appUpdaterLines[$i] -replace 'promises_1 = require\("fs/promises"\)', 'promises_1 = require("fs").promises'
            break
        }
    }
    
    if ($isUpdated)
    {
        Write-Host 'Patched $appUpdaterPath'
        Set-Content $appUpdaterPath $appUpdaterLines
    }
}

# start electron app
& electronize start