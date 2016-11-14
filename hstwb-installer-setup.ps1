# HstWB Installer Setup
# ---------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2016-11-06
#
# A powershell script to setup HstWB Installer run for an Amiga HDF file installation.


Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Windows.Forms


# read ini file
function ReadIniFile($iniFile)
{
    $ini = @{}

    switch -regex -file $iniFile
    {
        "^\[(.+)\]$" {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        "(.+)=(.+)" {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }

    return $ini
}


# write ini file
function WriteIniFile($iniFile, $ini)
{
    $iniLines = @()

    foreach ($key in ($ini.keys | Sort-Object))
    {
        if (!($($ini[$key].GetType().Name) -eq "Hashtable"))
        {
            $iniLines += "$key=$($ini[$key])"
        }
        else
        {
            # Section
            $iniLines += "[$key]"
            
            foreach ($sectionKey in ($ini[$key].keys | Sort-Object))
            {
                $iniLines += "$sectionKey=$($ini[$key][$sectionKey])"
            }
        }
    }

    [System.IO.File]::WriteAllText($iniFile, $iniLines -join [System.Environment]::NewLine)
}


# show open file dialog using WinForms
function OpenFileDialog($title, $directory, $filter)
{
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.initialDirectory = $directory
    $openFileDialog.Filter = $filter
    $openFileDialog.FilterIndex = 0
    $openFileDialog.Multiselect = $false
    $openFileDialog.Title = $title
    $result = $openFileDialog.ShowDialog()

    if($result -ne "OK")
    {
        return $null
    }

    return $openFileDialog.FileName
}


# show save file dialog using WinForms
function SaveFileDialog($title, $directory, $filter)
{
    $openFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $openFileDialog.initialDirectory = $directory
    $openFileDialog.Filter = $filter
    $openFileDialog.FilterIndex = 0
    $openFileDialog.Title = $title
    $result = $openFileDialog.ShowDialog()

    if($result -ne "OK")
    {
        return $null
    }

    return $openFileDialog.FileName
}


# show folder browser dialog using WinForms
function FolderBrowserDialog($title, $directory)
{
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.Description = $title
    $folderBrowserDialog.SelectedPath = $directory
    $folderBrowserDialog.ShowNewFolderButton = $false
    $result = $folderBrowserDialog.ShowDialog()

    if($result -ne "OK")
    {
        return $null
    }    

    return $folderBrowserDialog.SelectedPath    
}


# calculate md5 hash
function CalculateMd5($path)
{
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	return [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($path))).ToLower().Replace('-', '')
}


# get file hashes
function GetFileHashes($path)
{
    $adfFiles = Get-ChildItem -Path $path

    $fileHashes = @()

    foreach ($adfFile in $adfFiles)
    {
        $md5Hash = (CalculateMd5 $adfFile.FullName)
        $fileHashes += @{ "File" = $adfFile.FullName; "Md5Hash" = $md5Hash }
    }

    return $fileHashes
}


# find matching file hashes
function FindMatchingFileHashes($hashes, $path)
{
    # get file hashes from path
    $fileHashes = GetFileHashes $path

    # index file hashes
    $fileHashesIndex = @{}
    $fileHashes | % { $fileHashesIndex.Set_Item($_.Md5Hash, $_.File) }

    # find files with matching hashes
    foreach($hash in $hashes)
    {
        if ($fileHashesIndex.ContainsKey($hash.Md5Hash))
        {
            $hash | Add-Member -MemberType NoteProperty -Name 'File' -Value ($fileHashesIndex.Get_Item($hash.Md5Hash)) -Force
        }
    }
}


# read string from bytes
function ReadString($bytes, $offset, $length)
{
	$stringBytes = New-Object 'byte[]' $length 
	[Array]::Copy($bytes, $offset, $stringBytes, 0, $length)
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	return $iso88591.GetString($stringBytes)
}


# read adf disk name
function ReadAdfDiskName($bytes)
{
    # read disk name from offset 0x6E1B0
    $diskNameOffset = 0x6E1B0
    $diskNameLength = $bytes[$diskNameOffset]

    ReadString $bytes ($diskNameOffset + 1) $diskNameLength
}


# find matching workbench adfs
function FindMatchingWorkbenchAdfs($hashes, $path)
{
    $adfFiles = Get-ChildItem -Path $path -filter *.adf

    $validWorkbenchAdfFiles = @()

    foreach ($adfFile in $adfFiles)
    {
        # read adf bytes
        $adfBytes = [System.IO.File]::ReadAllBytes($adfFile.FullName)

        if ($adfBytes.Count -eq 901120)
        {
            $diskName = ReadAdfDiskName $adfBytes
            $validWorkbenchAdfFiles += @{ "DiskName" = $diskName; "File" = $adfFile.FullName }
        }
    }


    # find files with matching disk names
    foreach($hash in ($hashes | Where { $_.DiskName -ne '' -and !$_.File }))
    {
        $workbenchAdfFile = $validWorkbenchAdfFiles | Where { $_.DiskName -eq $hash.DiskName } | Select-Object -First 1

        if (!$workbenchAdfFile)
        {
            continue
        }

        $hash | Add-Member -MemberType NoteProperty -Name 'File' -Value $workbenchAdfFile.File -Force
    }
}


# print settings
function PrintSettings()
{
    Write-Host "Image"
    Write-Host "  HDF Image Path     : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $settings.Image.HdfImagePath + "'")
    Write-Host "Workbench"
    Write-Host "  Install Workbench  : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $settings.Workbench.InstallWorkbench + "'")
    Write-Host "  Workbench Adf Path : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $settings.Workbench.WorkbenchAdfPath + "'")
    Write-Host "  Workbench Adf Set  : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $settings.Workbench.WorkbenchAdfSet + "'")
    Write-Host "Kickstart"
    Write-Host "  Install Kickstart  : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $settings.Kickstart.InstallKickstart + "'")
    Write-Host "  Kickstart Rom Path : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $settings.Kickstart.KickstartRomPath + "'")
    Write-Host "  Kickstart Rom Set  : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $settings.Kickstart.KickstartRomSet + "'")
    Write-Host "Packages"
    Write-Host "  Install Packages   : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $settings.Packages.InstallPackages + "'")
    Write-Host "WinUAE"
    Write-Host "  WinUAE Path        : " -NoNewline -foregroundcolor "Gray"
    Write-Host ("'" + $settings.Winuae.WinuaePath + "'")
}


# enter path
function EnterPath($prompt)
{
    do
    {
        $path = Read-Host $prompt

        if ($path -ne '')
        {
            $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        }
        
        if (!(test-path -path $path))
        {
            Write-Error "Path '$path' doesn't exist"
        }
    }
    until ($path -eq '' -or (test-path -path $path))
    return $path
}


# enter choice
function EnterChoice($prompt, $options)
{
    for ($i = 0; $i -lt $options.Count; $i++)
    {
        Write-Host ("{0}: " -f ($i + 1)) -NoNewline -foregroundcolor "Gray"
        Write-Host $options[$i]
    }
    Write-Host ""

    do
    {
        Write-Host ("{0}: " -f $prompt) -NoNewline -foregroundcolor "Cyan"
        $choice = Read-Host
    }
    until ($choice -ne '' -and $choice -ge 1 -and $choice -le $options.Count)

    return $options[$choice - 1]
}


# menu
function Menu($title, $options)
{
    Clear-Host
    Write-Host "---------------------" -foregroundcolor "Yellow"
    Write-Host "HstWB Installer Setup" -foregroundcolor "Yellow"
    Write-Host "---------------------" -foregroundcolor "Yellow"
    Write-Host ""
    PrintSettings
    Write-Host ""
    Write-Host $title -foregroundcolor "Cyan"
    Write-Host ""

    return EnterChoice "Enter choice" $options
}


# main menu
function MainMenu()
{
    do
    {
        $choice = Menu "Main Menu" @("Select Image", "Configure Workbench", "Configure Kickstart", "Configure Packages", "Configure WinUAE", "Run Installer", "Reset", "Exit") 
        switch ($choice)
        {
            "Select Image" { SelectImageMenu }
            "Configure Workbench" { ConfigureWorkbenchMenu }
            "Configure Kickstart" { ConfigureKickstartMenu }
            "Configure Packages" { ConfigurePackagesMenu }
            "Configure WinUAE" { ConfigureWinuaeMenu }
            "Run Installer" { RunInstaller }
            "Reset" { Reset }
        }
    }
    until ($choice -eq 'Exit')
}


# select image menu
function SelectImageMenu()
{
    do
    {
        $choice = Menu "Select Image Menu" @("Existing Image", "New Image", "Back") 
        switch ($choice)
        {
            "Existing Image" { ExistingImage }
            "New Image" { NewImageMenu }
        }
    }
    until ($choice -eq 'Back')
}


# existing image
function ExistingImage()
{
    if ($settings.Image.HdfImagePath)
    {
        $defaultHdfImageDir = [System.IO.Path]::GetDirectoryName($settings.Image.HdfImagePath)
    }
    else
    {
        $defaultHdfImageDir = ${Env:USERPROFILE}
    }

    $newPath = OpenFileDialog "Select HDF image file" $defaultHdfImageDir "HDF Files|*.hdf|All Files|*.*"
    
    if ($newPath -and $newPath -ne '')
    {
        $settings.Image.HdfImagePath = $newPath
        Save
    }
}


# new image menu
function NewImageMenu()
{
    $newImageOptions = @()
    $newImageOptions += Get-ChildItem -Path $imagesPath -Filter *.zip | % { $_.Name -replace '\.zip$','' }
    $newImageOptions += "Back"


    # select image
    $choice = Menu "Select New Image Menu" $newImageOptions

    if ($choice -eq 'Back')
    {
        return
    }

    $imagePath = [System.IO.Path]::Combine($imagesPath, $choice + ".zip")

    if ($settings.Image.HdfImagePath)
    {
        $defaultHdfImageDir = [System.IO.Path]::GetDirectoryName($settings.Image.HdfImagePath)
    }
    else
    {
        $defaultHdfImageDir = ${Env:USERPROFILE}
    }

    # enter new hdf image path
    do
    {
        $newImagePath = SaveFileDialog ("Save new " + $choice + " HDF image") $defaultHdfImageDir "HDF Files|*.hdf|All Files|*.*"
        
        if ($newImagePath -and (test-path -path $newImagePath))
        {
            Write-Host ("New HDF Image Path '" + $newImagePath + "' already exists!") -foregroundcolor "Red"
            Start-Sleep -s 2
        }
    }
    until (!$newImagePath -or !(test-path -path $newImagePath))


    # return, if new image path is empty
    if (!$newImagePath)
    {
        return
    }


    # return, if no write permission
    try 
    {
        [System.IO.File]::OpenWrite($newImagePath).close()
    }
    catch
    {
        Write-Error ("Failed to write '" + $newImagePath + "'. No write permission!")
        Start-Sleep -s 2
        return
    }


    # open image file and get first hdf file
    $zip = [System.IO.Compression.ZipFile]::Open($imagePath,"Read")
    $hdfZipEntry = $zip.Entries | Where { $_.FullName -match '\.hdf$' }


    # return, if image file doesn't contain a HDF file 
    if (!$hdfZipEntry)
    {
        Write-Error ("Image '" + $imagePath + "' doesn't contain a HDF file!")
        Start-Sleep -s 2
        return
    }


    # extract image to new hdf image path
    Write-Host ("Extracting image '" + $imagePath + "' to new HDF image path '" + $newImagePath + "'...")
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($hdfZipEntry, $newImagePath, $true);


    # save settings
    $settings.Image.HdfImagePath = $newImagePath
    Save
}


# configure workbench menu
function ConfigureWorkbenchMenu()
{
    do
    {
        $choice = Menu "Configure Workbench Menu" @("Switch Install Workbench", "Change Workbench Adf Path", "Select Workbench Adf Set", "Back") 
        switch ($choice)
        {
            "Switch Install Workbench" { SwitchInstallWorkbench }
            "Change Workbench Adf Path" { ChangeWorkbenchAdfPath }
            "Select Workbench Adf Set" { SelectWorkbenchAdfSet }
        }
    }
    until ($choice -eq 'Back')
}


# switch install workbench
function SwitchInstallWorkbench()
{
    if ($settings.Workbench.InstallWorkbench -eq 'Yes')
    {
        $settings.Workbench.InstallWorkbench = 'No'
    }
    else
    {
        $settings.Workbench.InstallWorkbench = 'Yes'
    }
    Save
}


# change workbench adf path
function ChangeWorkbenchAdfPath()
{
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $defaultWorkbenchAdfPath = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\adf")
    }
    else
    {
        $defaultWorkbenchAdfPath = ${Env:USERPROFILE}
    }

    $path = if (!$settings.Workbench.WorkbenchAdfPath) { $defaultWorkbenchAdfPath } else { $settings.Workbench.WorkbenchAdfPath }
    $newPath = FolderBrowserDialog "Select Workbench Adf Directory" $path

    if ($newPath -and $newPath -ne '')
    {
        $settings.Workbench.WorkbenchAdfPath = $newPath
        Save
    }
}


# select workbench adf set
function SelectWorkbenchAdfSet()
{
    # read workbench adf hashes
    $workbenchAdfHashes = @()
    $workbenchAdfHashes += (Import-Csv -Delimiter ';' $workbenchAdfHashesFile)
    $workbenchNamePadding = ($workbenchAdfHashes | % { $_.Name } | sort @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

    # find files with hashes matching workbench adf hashes
    FindMatchingFileHashes $workbenchAdfHashes $settings.Workbench.WorkbenchAdfPath


    # find files with disk names matching workbench adf hashes
    FindMatchingWorkbenchAdfs $workbenchAdfHashes $settings.Workbench.WorkbenchAdfPath


    # get workbench rom sets
    $workbenchAdfSets = $workbenchAdfHashes | % { $_.Set } | Sort-Object | Get-Unique

    foreach($workbenchAdfSet in $workbenchAdfSets)
    {
        Write-Host ""
        Write-Host $workbenchAdfSet

        # get workbench adf set hashes
        $workbenchAdfSetHashes = $workbenchAdfHashes | Where { $_.Set -eq $workbenchAdfSet }
        
        foreach($workbenchAdfSetHash in $workbenchAdfSetHashes)
        {
            Write-Host (("  {0,-" + $workbenchNamePadding + "} : ") -f $workbenchAdfSetHash.Name) -NoNewline -foregroundcolor "Gray"
            if ($workbenchAdfSetHash.File)
            {
                Write-Host ("'" + $workbenchAdfSetHash.File + "'") -foregroundcolor "Green"
            }
            else
            {
                Write-Host "Not found!" -foregroundcolor "Red"
            }
        }
    }

    Write-Host ""
    $choise = EnterChoice "Enter Workbench Adf Set" ($workbenchAdfSets += "Back")

    if ($choise -ne 'Back')
    {
        $settings.Workbench.WorkbenchAdfSet = $choise
        Save
    }
}


# configure kickstart menu
function ConfigureKickstartMenu()
{
    do
    {
        $choice = Menu "Configure Kickstart Menu" @("Switch Install Kickstart", "Change Kickstart Rom Path", "Select Kickstart Rom Set", "Back") 
        switch ($choice)
        {
            "Switch Install Kickstart" { SwitchInstallKickstart }
            "Change Kickstart Rom Path" { ChangeKickstartRomPath }
            "Select Kickstart Rom Set" { SelectKickstartRomSet }
        }
    }
    until ($choice -eq 'Back')
}


# switch install kickstart
function SwitchInstallKickstart()
{
    if ($settings.Kickstart.InstallKickstart -eq 'Yes')
    {
        $settings.Kickstart.InstallKickstart = 'No'
    }
    else
    {
        $settings.Kickstart.InstallKickstart = 'Yes'
    }
    Save
}


# change kickstart rom path
function ChangeKickstartRomPath()
{
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $defaultKickstartRomPath = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\rom")
    }
    else
    {
        $defaultKickstartRomPath = ${Env:USERPROFILE}
    }

    $path = if (!$settings.Kickstart.KickstartRomPath) { $defaultKickstartRomPath } else { $settings.Kickstart.KickstartRomPath }
    $newPath = FolderBrowserDialog "Select Kickstart Rom Directory" $path

    if ($newPath -and $newPath -ne '')
    {
        $settings.Kickstart.KickstartRomPath = $newPath
        Save
    }
}


# select kickstart rom path
function SelectKickstartRomSet()
{
    # read kickstart rom hashes
    $kickstartRomHashes = @()
    $kickstartRomHashes += (Import-Csv -Delimiter ';' $kickstartRomHashesFile)
    $kickstartNamePadding = ($kickstartRomHashes | % { $_.Name } | sort @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

    # find files with hashes matching kickstart rom hashes
    FindMatchingFileHashes $kickstartRomHashes $settings.Kickstart.KickstartRomPath

    # get kickstart rom sets
    $kickstartRomSets = $kickstartRomHashes | % { $_.Set } | Sort-Object | Get-Unique

    foreach($kickstartRomSet in $kickstartRomSets)
    {
        Write-Host ""
        Write-Host $kickstartRomSet

        # get kickstart rom set hashes
        $kickstartRomSetHashes = $kickstartRomHashes | Where { $_.Set -eq $kickstartRomSet }
        
        foreach($kickstartRomSetHash in $kickstartRomSetHashes)
        {
            Write-Host (("  {0,-" + $kickstartNamePadding + "} : ") -f $kickstartRomSetHash.Name) -NoNewline -foregroundcolor "Gray"
            if ($kickstartRomSetHash.File)
            {
                Write-Host ("'" + $kickstartRomSetHash.File + "'") -foregroundcolor "Green"
            }
            else
            {
                Write-Host "Not found!" -foregroundcolor "Red"
            }
        }
    }

    Write-Host ""
    $choise = EnterChoice "Enter Kickstart Rom Set" ($kickstartRomSets += "Back")

    if ($choise -ne 'Back')
    {
        $settings.Kickstart.KickstartRomSet = $choise
        Save
    }
}


# configure packages menu
function ConfigurePackagesMenu()
{
    # get available packages from files in packages directory
    $availablePackages = @()
    $availablePackages += Get-ChildItem -Path $packagesPath -Filter *.zip | sort @{expression={$_.Name};Ascending=$true}

    # get install packages defined in settings packages section
    $installPackages = @()
    $installPackages += ,$settings.Packages.InstallPackages -split ','

    do
    {
        $packageOptions = @()
        $packageOptions += $availablePackages | % { $_ -replace '\.zip$','' } | % { if ($installPackages -contains $_) { "Remove $_" } else { "Add $_" } }
        $packageOptions += "Back"

        $choice = Menu "Configure Packages Menu" $packageOptions

        if ($choice -ne 'Back')
        {
            $package = $choice -replace '^(Add|Remove) ', ''

            if ($installPackages -contains $package)
            {
                $installPackages = ,($installPackages | Where { $_ -ne $package })
            }
            else
            {
                $installPackages += ,$package
            }
            
            $settings.Packages.InstallPackages = ($installPackages | sort @{expression={$_};Ascending=$true}) -join ','
            Save
        } 
    }
    until ($choice -eq 'Back')
}


# configure winuae menu
function ConfigureWinuaeMenu()
{
    do
    {
        $choice = Menu "Configure WinUAE Menu" @("Change WinUAE Path", "Back") 
        switch ($choice)
        {
            "Change WinUAE Path" { ChangeWinuaePath }
        }
    }
    until ($choice -eq 'Back')
}


# change winuae path
function ChangeWinuaePath()
{
    $path = if (!$settings.Winuae.WinuaePath) { ${Env:ProgramFiles(x86)} } else { [System.IO.Path]::GetDirectoryName($settings.Winuae.WinuaePath) }
    $newPath = OpenFileDialog "Select WinUAE.exe file" $path "Exe Files|*.exe|All Files|*.*"

    if ($newPath -and $newPath -ne '')
    {
        $settings.Winuae.WinuaePath = $newPath
        Save
    }
}


# run installer
function RunInstaller
{
    Write-Host ""
	& $runFile
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
}


# save
function Save()
{
    WriteIniFile $settingsFile $settings
}


# reset
function Reset()
{
    DefaultSettings
    Save
}


# default settings
function DefaultSettings()
{
    $settings.Image = @{}
    $settings.Workbench = @{}
    $settings.Kickstart = @{}
    $settings.Winuae = @{}
    $settings.Packages = @{}

    $settings.Workbench.InstallWorkbench = 'Yes'
    $settings.Kickstart.InstallKickstart = 'Yes'
    $settings.Packages.InstallPackages = 'BetterWB.4.0.0,HstWB.1.0.0'
    
    # use cloanto amiga forever data directory, if present
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $workbenchAdfPath = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\adf")
        if (test-path -path $workbenchAdfPath)
        {
            $settings.Workbench.WorkbenchAdfPath = $workbenchAdfPath
            $settings.Workbench.WorkbenchAdfSet = 'Workbench 3.1 Cloanto Amiga Forever 2016'
        }

        $kickstartRomPath = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\rom")
        if (test-path -path $kickstartRomPath)
        {
            $settings.Kickstart.KickstartRomPath = $kickstartRomPath
            $settings.Kickstart.KickstartRomSet = 'Kickstart Cloanto Amiga Forever 2016'
        }
    }

    # use winuae in program files x86, if present
    $winuaePath = "${Env:ProgramFiles(x86)}\WinUAE\winuae.exe"
    if (test-path -path $winuaePath)
    {
        $settings.Winuae.WinuaePath = $winuaePath
    }
}


# resolve paths
$kickstartRomHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Kickstart\kickstart-rom-hashes.csv")
$workbenchAdfHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Workbench\workbench-adf-hashes.csv")
$imagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("images")
$packagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("packages")
$runFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("hstwb-installer-run.ps1")
$settingsFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("hstwb-installer-settings.ini")


$settings = @{}


# create default settings, if settings file doesn't exist
if (test-path -path $settingsFile)
{
    $settings = ReadIniFile $settingsFile
}
else
{
    Reset
}


# create packages section in settings, if it doesn't exist
if (!($settings.Packages))
{
    $settings.Packages = @{}
    $settings.Packages.InstallPackages = 'BetterWB.4.0.0,HstWB.1.0.0'
}


# show main menu
MainMenu