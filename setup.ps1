# HstWB Installer Setup
# ---------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2022-01-03
#
# A powershell script to setup HstWB Installer run for an Amiga HDF file installation.


Using module .\modules\packages.psm1

Param(
	[Parameter(Mandatory=$false)]
	[string]$settingsDir
)

Import-Module (Resolve-Path('modules\version.psm1')) -Force
Import-Module (Resolve-Path('modules\config.psm1')) -Force
Import-Module (Resolve-Path('modules\dialog.psm1')) -Force
Import-Module (Resolve-Path('modules\data.psm1')) -Force

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Windows.Forms


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
function FolderBrowserDialog($title, $directory, $showNewFolderButton)
{
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.Description = $title
    $folderBrowserDialog.SelectedPath = $directory
    $folderBrowserDialog.ShowNewFolderButton = $showNewFolderButton
    $result = $folderBrowserDialog.ShowDialog()

    if($result -ne "OK")
    {
        return $null
    }    

    return $folderBrowserDialog.SelectedPath    
}


# confirm dialog
function ConfirmDialog($title, $message, $icon = 'Asterisk')
{
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OKCancel, $icon)

    if($result -eq "OK")
    {
        return $true
    }

    return $false
}


# menu
function Menu($hstwb, $title, $options, $returnIndex = $false)
{
    Clear-Host
    $versionPadding = new-object System.String('-', ($hstwb.Version.Length + 2))
    Write-Host ("---------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
    Write-Host ("HstWB Installer Setup v{0}" -f $hstwb.Version) -foregroundcolor "Yellow"
    Write-Host ("---------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
    Write-Host ""
    PrintSettings $hstwb
    Write-Host ""
    Write-Host $title -foregroundcolor "Cyan"
    Write-Host ""

    return EnterChoiceColor "Enter choice" $options $returnIndex
}


# main
function Main($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Main" @("Configure Installer", "Configure image", "Configure Amiga OS", "Configure Kickstart", "Configure packages", "Configure user packages", "Configure emulator", "Run Installer", "Reset settings", "Exit")
        switch ($choice)
        {
            "Configure Installer" { ConfigureInstaller $hstwb }
            "Configure image" { ConfigureImage $hstwb }
            "Configure Amiga OS" { ConfigureAmigaOs $hstwb }
            "Configure Kickstart" { ConfigureKickstart $hstwb }
            "Configure packages" { ConfigurePackages $hstwb }
            "Configure user packages" { ConfigureUserPackages $hstwb }
            "Configure emulator" { ConfigureEmulator $hstwb }
            "Run Installer" { RunInstaller $hstwb }
            "Reset settings" { ResetSettings $hstwb }
        }
    }
    until ($choice -eq 'Exit')
}


# configure image
function ConfigureImage($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure image" @("Existing image directory", "Create image directory from image template", "Back") 
        switch ($choice)
        {
            "Existing image directory" { ExistingImageDirectory $hstwb }
            "Create image directory from image template" { CreateImageDirectoryFromImageTemplate $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# existing image directory
function ExistingImageDirectory($hstwb)
{
    if ($hstwb.Settings.Image.ImageDir -and (Test-Path -path $hstwb.Settings.Image.ImageDir))
    {
        $defaultImageDir = $hstwb.Settings.Image.ImageDir
    }
    else
    {
        $defaultImageDir = ${Env:USERPROFILE}
    }

    $newImageDir = FolderBrowserDialog "Select existing image directory" $defaultImageDir $false

    # return, if new image directory is not defined
    if (!$newImageDir -or $newImageDir -eq '')
    {
        return
    }

    # read hstwb image json file
    $hstwbImageJsonFile = Join-Path -Path $newImageDir -ChildPath 'hstwb-image.json' 

    # return, if hstwb image json file doesn't exist
    if (!(Test-Path -Path $hstwbImageJsonFile))
    {
        Write-Error ("Image directory '{0}' doesn't contain 'hstwb-image.json' file!" -f $newPath)
        Write-Host ""
        Write-Host "Press enter to continue"
        Read-Host
        return
    }

    # read hstwb image json file
    $image = Get-Content $hstwbImageJsonFile -Raw | ConvertFrom-Json

    # check, if image has large harddrives
    $largeHarddrivesPresent = $image.Harddrives | Where-Object { $_.Type -match 'hdf' -and $_.Size -gt 4000000000 } | Select-Object -First 1

    # show large harddrive warning, if image has large harddrives
    if ($largeHarddrivesPresent)
    {
        $confirm = ConfirmDialog 'Large harddrive' ("Image directory '{0}' uses harddrive(s) larger than 4GB and might become corrupt depending on scsi.device and filesystem used.`r`n`r`nIt's recommended to use tools to check and repair harddrive integrity, e.g. pfsdoctor for partitions with PFS\3 filesystem.`r`n`r`nDo you want to use the image?" -f $newImageDir) 'Warning'
        if (!$confirm)
        {
            return
        }
    }

    # save new image directory
    $hstwb.Settings.Image.ImageDir = $newImageDir
    Save $hstwb
}


# create image directory from image template
function CreateImageDirectoryFromImageTemplate($hstwb)
{
    # get images sorted naturally
    $images = $hstwb.Images | Sort-Object @{expression={ [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(20) }) };Ascending=$true}

    # build image template options
    $imageTemplateOptions = @()
    $imageTemplateOptions += $images | ForEach-Object { $_.Name }
    $imageTemplateOptions += "Back"
    

    # create image directory from image template
    $choice = Menu $hstwb "Create image directory from image template" $imageTemplateOptions $true

    if ($choice -eq 'Back')
    {
        return
    }

    # get image file
    $imageFile = $images[$choice].ImageFile

    # read hstwb image json file from image file
    $hstwbImageJsonText = ReadZipEntryTextFile $imageFile 'hstwb-image\.json$'

    # return, if hstwb image json file doesn't exist
    if (!$hstwbImageJsonText)
    {
        Write-Error ("Image file '$imageFile' doesn't contain 'hstwb-image.json' file!")
        Write-Host ""
        Write-Host "Press enter to continue"
        Read-Host
        return
    }

    # read hstwb image json text
    $image = $hstwbImageJsonText | ConvertFrom-Json

    # check, if image has large harddrives
    $largeHarddrivesPresent = $image.Harddrives | Where-Object { $_.Type -match 'hdf' -and $_.Size -gt 4000000000 } | Select-Object -First 1

    # show large harddrive warning, if image has large harddrives
    if ($largeHarddrivesPresent)
    {
        $confirm = ConfirmDialog 'Large harddrive' ("Image '{0}' uses harddrive(s) larger than 4GB and might become corrupt depending on scsi.device and filesystem used.`r`n`r`nIt's recommended to use tools to check and repair harddrive integrity, e.g. pfsdoctor for partitions with PFS\3 filesystem.`r`n`r`nDo you want to use the image?" -f $image.Name) 'Warning'
        if (!$confirm)
        {
            return
        }
    }

    # default image dir
    if ($hstwb.Settings.Image.ImageDir)
    {
        $defaultImageDir = $hstwb.Settings.Image.ImageDir
    }
    else
    {
        $defaultImageDir = ${Env:USERPROFILE}
    }

    # select new image directory
    $newImageDirectoryPath = FolderBrowserDialog ("Select new image directory for '{0}'" -f $image.Name) $defaultImageDir $true

    # return, if new image directory path is null
    if ($null -eq $newImageDirectoryPath)
    {
        return
    }

    # return, if no write permission
    try 
    {
        $tempFile = Join-Path $newImageDirectoryPath -ChildPath "__test__"
        [System.IO.File]::OpenWrite($tempFile).Close()
        Remove-Item -Path $tempFile -Force
    }
    catch
    {
        Write-Error ("Failed writing to new image directory '" + $newImageDirectoryPath + "'. No write permission!")
        Write-Host ""
        Write-Host "Press enter to continue"
        Read-Host
        return
    }

    # hstwb image json file
    $hstwbImageJsonFile = Join-Path $newImageDirectoryPath -ChildPath "hstwb-image.json"

    # confirm overwrite, if hstwb image json file already exists in new image directory path
    if (Test-Path -Path $hstwbImageJsonFile)
    {
        $confirm = ConfirmDialog "Overwrite files" ("Image directory '" + $newImageDirectoryPath + "' already contains 'hstwb-image.json' and image files.`r`n`r`nDo you want to overwrite files?")
        if (!$confirm)
        {
            return
        }
    }

    # write harddrives.uae to new image directory path
    Set-Content -Path $hstwbImageJsonFile -Value $hstwbImageJsonText

    Write-Host ""
    Write-Host ("Creating image '{0}' in directory '{1}'" -f $image.Name, $newImageDirectoryPath) -ForegroundColor Yellow

    # prepare harddrives
    foreach($harddrive in $image.Harddrives)
    {
        # get harddrive path
        $harddrivePath = Join-Path -Path $newImageDirectoryPath -ChildPath $harddrive.Path

        # extract hdf or create dir harddrive
        switch ($harddrive.Type)
        {
            "hdf"
            {
                # open image file and get hdf zip entry matching hdf filename
                $zip = [System.IO.Compression.ZipFile]::Open($imageFile,"Read")

                # extract filesystem, if it's defined
                if ($harddrive.FileSystem -and $harddrive.FileSystem -notmatch '^\s*$')
                {
                    # find file system file in zip file entries
                    $fileSystemZipEntry = $zip.Entries | Where-Object { $_.FullName -like ('*' + $harddrive.FileSystem + '*') }

                    # return, if image file doesn't contain file system file
                    if (!$fileSystemZipEntry)
                    {
                        $zip.Dispose()
                        Write-Error ("Image file '{0}' doesn't contain file system file '{1}'!" -f $imageFile, $harddrive.FileSystem)
                        Write-Host ""
                        Write-Host "Press enter to continue"
                        return
                    }

                    # extract file system zip entry to new image directory
                    $fileSystemPath = Join-Path -Path $newImageDirectoryPath -ChildPath $harddrive.FileSystem
                    Write-Host ("Extracting file system file '{0}' to '{1}'..." -f $harddrive.FileSystem, $fileSystemPath)
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($fileSystemZipEntry, $fileSystemPath, $true);
                    Write-Host "Done."
                }


                # find hdf file in zip file entries
                $hdfZipEntry = $zip.Entries | Where-Object { $_.FullName -like ('*' + $harddrive.Path + '*') } | Select-Object -First 1

                # find zipped hdf file, if image file doesn't contain hdf filename
                if (!$hdfZipEntry)
                {
                    # find hdf zip file in zip file entries
                    $hdfZipEntry = $zip.Entries | Where-Object { $_.FullName -like ('*' + ($harddrive.Path -replace '\.hdf$', '.zip') + '*') } | Select-Object -First 1
                }

                # return, if image file doesn't contain hdf filename
                if (!$hdfZipEntry)
                {
                    $zip.Dispose()
                    Write-Error ("Image file '{0}' doesn't contain hdf file '{1}'!" -f $imageFile, $harddrive.Path)
                    Write-Host ""
                    Write-Host "Press enter to continue"
                    Read-Host
                    return
                }

                $hdfZipFile = $null
                if ($hdfZipEntry.Name -match '\.zip$')
                {
                    $hdfZipFile = Join-Path $newImageDirectoryPath -ChildPath $hdfZipEntry.Name

                    Write-Host ("Extracting zip file '{0}' to '{1}'..." -f $hdfZipEntry.Name, $hdfZipFile)
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($hdfZipEntry, $hdfZipFile, $true)
                }
                else
                {
                    Write-Host ("Extracting hdf file '{0}' to '{1}'..." -f $harddrive.Path, $harddrivePath)
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($hdfZipEntry, $harddrivePath, $true)
                }
                Write-Host "Done."

                # dispose zip file
                $zip.Dispose()

                if ($hdfZipFile)
                {
                    # open hdf zip file
                    $zip = [System.IO.Compression.ZipFile]::Open($hdfZipFile,"Read")

                    # find hdf file in zip file entries
                    $hdfZipEntry = $zip.Entries | Where-Object { $_.FullName -like ('*' + $harddrive.Path + '*') } | Select-Object -First 1

                    # return, if image file doesn't contain hdf filename
                    if (!$hdfZipEntry)
                    {
                        $zip.Dispose()
                        Write-Error ("Image file '{0}' doesn't contain hdf file '{1}'!" -f $imageFile, $harddrive.Path)
                        Write-Host ""
                        Write-Host "Press enter to continue"
                        Read-Host
                        return
                    }

                    Write-Host ("Extracting hdf file '{0}' to '{1}'..." -f $harddrive.Path, $harddrivePath)

                    # extract hdf zip entry to new image directory
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($hdfZipEntry, $harddrivePath, $true)

                    # dispose zip file
                    $zip.Dispose()

                    Write-Host "Done."
                    
                    # remove hdf zip file
                    Write-Host ("Deleting zip file '{0}'..." -f $hdfZipFile)
                    Remove-Item $hdfZipFile -Force
                    Write-Host "Done."
                }                
            }
            "dir"
            {
                Write-Host "Creating hdf directory '$harddrivePath'..." 

                # create harddrive path, if it doesn't exist
                if(!(test-path -path $harddrivePath))
                {
                    mkdir $harddrivePath | Out-Null
                }

                Write-Host "Done."
            }
        }
    }

    # save settings
    $hstwb.Settings.Image.ImageDir = $newImageDirectoryPath
    Save $hstwb

    # continue
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
}


# configure amiga os
function ConfigureAmigaOs($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure Amiga OS" @("Switch install Amiga OS", "Change Amiga OS dir", "Select Amiga OS set", "View Amiga Os set files", "Back") 
        switch ($choice)
        {
            "Switch install Amiga OS" { SwitchInstallAmigaOs $hstwb }
            "Change Amiga OS dir" { ChangeAmigaOsDir $hstwb }
            "Select Amiga OS set" { SelectAmigaOsSet $hstwb }
            "View Amiga Os set files" { ViewAmigaOsSetFiles $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# switch install amiga os
function SwitchInstallAmigaOs($hstwb)
{
    if ($hstwb.Settings.AmigaOs.InstallAmigaOs -eq 'Yes')
    {
        $hstwb.Settings.AmigaOs.InstallAmigaOs = 'No'
    }
    else
    {
        $hstwb.Settings.AmigaOs.InstallAmigaOs = 'Yes'
    }
    Save $hstwb
}


# change amiga os adf dir
function ChangeAmigaOsDir($hstwb)
{
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $defaultAmigaOsPath = Join-Path $amigaForeverDataPath -ChildPath "Shared\adf"
    }
    else
    {
        $defaultAmigaOsPath = ${Env:USERPROFILE}
    }

    $path = if (!$hstwb.Settings.AmigaOs.AmigaOsDir) { $defaultAmigaOsPath } else { $hstwb.Settings.AmigaOs.AmigaOsDir }
    $newAmigaOsDir = FolderBrowserDialog "Select Amiga OS directory" $path $false

    if ($newAmigaOsDir -and $newAmigaOsDir -ne '')
    {
        # set new amiga os dir
        $hstwb.Settings.AmigaOs.AmigaOsDir = $newAmigaOsDir

        # update amiga os entries
        UpdateAmigaOsEntries $hstwb

        # find amiga os files
        Write-Host "Finding Amiga OS sets in Amiga OS dir..."

        # find best matching amiga os set
        $hstwb.Settings.AmigaOs.AmigaOsSet = FindBestMatchingAmigaOsSet $hstwb

        # update package filtering and install packages, if install mode is used
        if ($hstwb.Settings.Installer.Mode -eq "Install")
        {
            UpdatePackageFiltering $hstwb
        }
        else
        {
            $hstwb.Settings.Packages.PackageFiltering = 'All'
        }
        UpdateInstallPackages $hstwb

        # ui amiga os set info
        UiAmigaOsSetInfo $hstwb $hstwb.Settings.AmigaOs.AmigaOsSet

        # save settings
        Save $hstwb
    }
}

# select amiga os set
function SelectAmigaOsSet($hstwb)
{
    $amigaOsSetNames = $hstwb.AmigaOsEntries | ForEach-Object { $_.Set } | Get-Unique

    $amigaOsSetOptions = @()

    foreach($amigaOsSetName in $amigaOsSetNames)
    {
        $amigaOsSetResult = ValidateSet $hstwb.AmigaOsEntries $amigaOsSetName

        $amigaOsSetInfo = FormatAmigaOsSetInfo $amigaOsSetResult

        $amigaOsSetOptions += @{
            'Text' = $amigaOsSetInfo.Text;
            'Color' = $amigaOsSetInfo.Color;
            'Value' = $amigaOsSetName
        }
    }

    $amigaOsSetOptions += @{
        'Text' = 'Back';
        'Value' = 'Back'
    }

    Write-Host ""
    $choise = EnterChoiceColor "Enter Amiga OS set" $amigaOsSetOptions

    if ($choise -and $choise.Value -ne 'Back')
    {
        $hstwb.UI.AmigaOs.AmigaOsSetInfo = $choise

        $hstwb.Settings.AmigaOs.AmigaOsSet = $choise.Value

        # build amiga os versions
        $amigaOsVersionsIndex = @{}
        foreach ($package in ($hstwb.Packages.Values | Where-Object { $_.AmigaOsVersions }))
        {
            $package.AmigaOsVersions | ForEach-Object { $amigaOsVersionsIndex[$_] = $true }
        }
        $amigaOsVersions = $amigaOsVersionsIndex.Keys | Sort-Object -Descending

        # get first amiga os entry for amiga os set
        $amigaOsEntry = $hstwb.AmigaOsEntries | Where-Object { $_.Set -eq $hstwb.Settings.AmigaOs.AmigaOsSet } | Select-Object -First 1
        
        # set package filtering to amiga os entry's amiga os version, if it's defined and matches one of amiga os versions present in packages. otherwise set package filtering to all
        if ($amigaOsEntry -and $amigaOsEntry.AmigaOsVersion -and $amigaOsVersions -contains $amigaOsEntry.AmigaOsVersion)
        {
            $hstwb.Settings.Packages.PackageFiltering = $amigaOsEntry.AmigaOsVersion
        }
        else
        {
            $hstwb.Settings.Packages.PackageFiltering = 'All'
        }

        Save $hstwb
    }
}

# view amiga os set files
function ViewAmigaOsSetFiles($hstwb)
{
    Write-Host ""

    # show warning, if maiga os set is not selected
    if (!$hstwb.Settings.AmigaOs.AmigaOsSet -or $hstwb.Settings.AmigaOs.AmigaOsSet -eq '')
    {
        Write-Host 'Amiga OS set is not selected!' -ForegroundColor 'Yellow'
        Write-Host ''
        Write-Host 'Press enter to continue'
        Read-Host
        return
    }

    $amigaOsSetEntries = @()
    $amigaOsSetEntries = $hstwb.AmigaOsEntries | Where-Object { $_.Set -eq $hstwb.Settings.AmigaOs.AmigaOsSet }

    if ($hstwb.UI.AmigaOs.AmigaOsSetInfo.Color)
    {
        Write-Host $hstwb.UI.AmigaOs.AmigaOsSetInfo.Text -ForegroundColor $hstwb.UI.AmigaOs.AmigaOsSetInfo.Color
    }
    else
    {
        Write-Host $hstwb.UI.AmigaOs.AmigaOsSetInfo.Text
    }

    # get name padding
    $namePadding = ($amigaOsSetEntries | ForEach-Object { $_.Name } | Sort-Object @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

    $amigaOsSetEntriesFirstIndex = @{}

    # list amiga os set entries
    foreach($amigaOsSetEntry in $amigaOsSetEntries)
    {
        if ($amigaOsSetEntriesFirstIndex.ContainsKey($amigaOsSetEntry.Name))
        {
            continue
        }

        $amigaOsSetEntriesFirstIndex[$amigaOsSetEntry.Name] = $true

        $bestMatchingAmigaOsSetEntry = $amigaOsSetEntries | Where-Object { $_.Name -eq $amigaOsSetEntry.Name } | Sort-Object @{expression={$_.MatchRank};Ascending=$true} | Select-Object -First 1

        Write-Host (("  {0,-" + $namePadding + "} : ") -f $bestMatchingAmigaOsSetEntry.Name) -NoNewline -Foregroundcolor "Gray"
        if ($bestMatchingAmigaOsSetEntry.File)
        {
            Write-Host ("'" + $bestMatchingAmigaOsSetEntry.File + "'") -NoNewline -Foregroundcolor "Green"
            Write-Host (' (Match {0}' -f $bestMatchingAmigaOsSetEntry.MatchType) -NoNewline
            if ($bestMatchingAmigaOsSetEntry.Comment -and $bestMatchingAmigaOsSetEntry.Comment -ne '')
            {
                Write-Host ('. {0}' -f $bestMatchingAmigaOsSetEntry.Comment) -NoNewline
            }
            Write-Host ")"
        }
        else
        {
            if ($bestMatchingAmigaOsSetEntry.Required -eq 'True')
            {
                Write-Host "Not found!" -Foregroundcolor "Red"
            }
            else
            {
                Write-Host "Not found!" -Foregroundcolor "Yellow"                
            }
        }
    }

    # continue
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
}

# configure kickstart
function ConfigureKickstart($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure Kickstart" @("Switch install Kickstart", "Change Kickstart dir", "Select Kickstart set", "View Kickstart set files", "Back") 
        switch ($choice)
        {
            "Switch install Kickstart" { SwitchInstallKickstart $hstwb }
            "Change Kickstart dir" { ChangeKickstartDir $hstwb }
            "Select Kickstart set" { SelectKickstartSet $hstwb }
            "View Kickstart set files" { ViewKickstartSetFiles $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# switch install kickstart
function SwitchInstallKickstart($hstwb)
{
    if ($hstwb.Settings.Kickstart.InstallKickstart -eq 'Yes')
    {
        $hstwb.Settings.Kickstart.InstallKickstart = 'No'
    }
    else
    {
        $hstwb.Settings.Kickstart.InstallKickstart = 'Yes'
    }
    Save $hstwb
}


# get default kickstart dir
function GetDefaultKickstartDir()
{
    if (${Env:AMIGAFOREVERDATA} -and (Test-Path ${Env:AMIGAFOREVERDATA}))
    {
        $amigaForeverDataSharedRomDir = Join-Path ${Env:AMIGAFOREVERDATA} -ChildPath "Shared\rom"
        if (Test-Path $amigaForeverDataSharedRomDir)
        {
            return $amigaForeverDataSharedRomDir
        }
    }

    return ${Env:USERPROFILE}
}

# change kickstart dir
function ChangeKickstartDir($hstwb)
{
    $kickstartDir = if ($hstwb.Settings.Kickstart.KickstartDir -and (Test-Path $hstwb.Settings.Kickstart.KickstartDir)) { $hstwb.Settings.Kickstart.KickstartDir } else { GetDefaultKickstartDir }
    $newKickstartDir = FolderBrowserDialog "Select Kickstart directory" $kickstartDir $false

    if ($newKickstartDir -and $newKickstartDir -ne '')
    {
        # set new kickstart rom dir
        $hstwb.Settings.Kickstart.KickstartDir = $newKickstartDir

        # update kickstart entries
        UpdateKickstartEntries $hstwb

        # find kickstart files
        Write-Host "Finding Kickstart sets in Kickstart dir..."

        # set new kickstart rom set and save
        $hstwb.Settings.Kickstart.KickstartSet = FindBestMatchingKickstartSet $hstwb

        # ui kickstart set info
        UiKickstartSetInfo $hstwb $hstwb.Settings.Kickstart.KickstartSet

        # ui amiga os set info
        UiAmigaOsSetInfo $hstwb $hstwb.Settings.AmigaOs.AmigaOsSet

        Save $hstwb
    }
}

# select kickstart set
function SelectKickstartSet($hstwb)
{
    $kickstartSetNames = @()
    $kickstartSetNames += $hstwb.KickstartEntries | ForEach-Object { $_.Set } | Get-Unique

    $kickstartSetOptions = @()
    foreach($kickstartSetName in $kickstartSetNames)
    {
        $kickstartSetResult = ValidateSet $hstwb.KickstartEntries $kickstartSetName

        $kickstartSetInfo = FormatKickstartSetInfo $kickstartSetResult

        $kickstartSetOptions += @{
            'Text' = $kickstartSetInfo.Text;
            'Color' = $kickstartSetInfo.Color;
            'Value' = $kickstartSetName
        }
    }

    $kickstartSetOptions += @{
        'Text' = 'Back';
        'Value' = 'Back'
    }

    $choise = Menu $hstwb "Enter Kickstart set" $kickstartSetOptions

    if ($choise.Value -ne 'Back')
    {
        # set ui kickstart set info
        $hstwb.UI.Kickstart.KickstartSetInfo = $choise

        # set kickstart set
        $hstwb.Settings.Kickstart.KickstartSet = $choise.Value

        # save settings
        Save $hstwb
    }
}

# view kickstart set files
function ViewKickstartSetFiles($hstwb)
{
    Write-Host ""

    # show warning, if kickstart set is not selected
    if (!$hstwb.Settings.Kickstart.KickstartSet -or $hstwb.Settings.Kickstart.KickstartSet -eq '')
    {
        Write-Host 'Kickstart set is not selected!' -ForegroundColor 'Yellow'
        Write-Host ''
        Write-Host 'Press enter to continue'
        Read-Host
        return
    }

    # get kickstart set entries
    $kickstartSetEntries = @()
    $kickstartSetEntries = $hstwb.KickstartEntries | Where-Object { $_.Set -eq $hstwb.Settings.Kickstart.KickstartSet }

    # show kickstart set info
    if ($hstwb.UI.Kickstart.KickstartSetInfo.Color)
    {
        Write-Host $hstwb.UI.Kickstart.KickstartSetInfo.Text -ForegroundColor $hstwb.UI.Kickstart.KickstartSetInfo.Color
    }
    else
    {
        Write-Host $hstwb.UI.Kickstart.KickstartSetInfo.Text
    }
    
    # get name padding
    $namePadding = ($kickstartSetEntries | ForEach-Object { $_.Name } | Sort-Object @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

    $kickstartSetEntriesFirstIndex = @{}

    # list amiga os set entries
    foreach($kickstartSetEntry in $kickstartSetEntries)
    {
        if ($kickstartSetEntriesFirstIndex.ContainsKey($kickstartSetEntry.Name))
        {
            continue
        }

        $kickstartSetEntriesFirstIndex[$kickstartSetEntry.Name] = $true

        $bestMatchingKickstartSetEntry = $kickstartSetEntries | Where-Object { $_.Name -eq $kickstartSetEntry.Name } | Sort-Object @{expression={$_.MatchRank};Ascending=$true} | Select-Object -First 1

        Write-Host (("  {0,-" + $namePadding + "} : ") -f $bestMatchingKickstartSetEntry.Name) -NoNewline -Foregroundcolor "Gray"
        if ($bestMatchingKickstartSetEntry.File)
        {
            Write-Host ("'" + $bestMatchingKickstartSetEntry.File + "'") -NoNewline -Foregroundcolor "Green"
            Write-Host (' (Match ') -NoNewline
            if ($bestMatchingKickstartSetEntry.Encrypted)
            {
                Write-Host ('Decrypted ') -NoNewline
            }
            Write-Host $bestMatchingKickstartSetEntry.MatchType -NoNewline
            if ($bestMatchingKickstartSetEntry.Encrypted)
            {
                Write-Host (', requires rom key') -NoNewline
            }
            if ($bestMatchingKickstartSetEntry.Comment -and $bestMatchingKickstartSetEntry.Comment -ne '')
            {
                Write-Host ('. {0}' -f $bestMatchingKickstartSetEntry.Comment) -NoNewline
            }
            Write-Host ")"
        }
        else
        {
            if ($bestMatchingKickstartSetEntry.Required -eq 'True')
            {
                Write-Host "Not found!" -Foregroundcolor "Red"
            }
            else
            {
                Write-Host "Not found!" -Foregroundcolor "Yellow"                
            }
        }
    }

    # continue
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
}

# configure user packages
function ConfigurePackages($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure packages" @("Select packages", "Update packages", "Back") 
        switch ($choice)
        {
            "Select packages" { SelectPackages $hstwb }
            "Update packages" { UpdatePackages $hstwb }
        }
    }
    until ($choice -eq 'Back')
}

# select package filtering
function SelectPackageFiltering($hstwb)
{
    # build amiga os versions
    $amigaOsVersionsIndex = @{}
    foreach ($package in ($hstwb.Packages.Values | Where-Object { $_.AmigaOsVersions }))
    {
        $package.AmigaOsVersions | ForEach-Object { $amigaOsVersionsIndex[$_] = $true }
    }
    $amigaOsVersions = $amigaOsVersionsIndex.Keys | Sort-Object -Descending

    # build amiga os version options
    $amigaOsVersionOptions = @()
    $amigaOsVersionColor = if ('All' -eq $hstwb.Settings.Packages.PackageFiltering) { 'Green' } else { $null }
    $amigaOsVersionOptions += @{ 'Text' = 'All Amiga OS versions'; 'Value' = 'All'; 'Color' = $amigaOsVersionColor }
    
    foreach ($amigaOsVersion in $amigaOsVersions)
    {
        $amigaOsVersionColor = if ($amigaOsVersion -eq $hstwb.Settings.Packages.PackageFiltering) { 'Green' } else { $null }
        $amigaOsVersionOptions += @{
            'Text' = ('Amiga OS {0}' -f $amigaOsVersion);
            'Value' = $amigaOsVersion;
            'Color' = $amigaOsVersionColor
        }
    }
    #$amigaOsVersionOptions += $amigaOsVersions | ForEach-Object { @{ 'Text' = ('Amiga OS {0}' -f $_); 'Value' = $_; 'Color' = (if ($_ -and $hstwb.Settings.Packages.PackageFiltering) { 'Green' } else { $null }) } }
    $amigaOsVersionOptions += @{ 'Text' = 'Back'; 'Value' = 'Back' }

    do
    {
        $choice = Menu $hstwb "Select package filtering" $amigaOsVersionOptions

        # get first amiga os entry for amiga os set
        $amigaOsEntry = $hstwb.AmigaOsEntries | Where-Object { $_.Set -eq $hstwb.Settings.AmigaOs.AmigaOsSet } | Select-Object -First 1

        # add package filtering warning, if package filtering doesn't match amiga os version for amiga os set
        $amigaOsVersionWarning = ''
        if ($hstwb.Settings.Installer.Mode -eq "Install" -and $amigaOsEntry -and $amigaOsEntry.AmigaOsVersion -ne $choice.Value)
        {
            $amigaOsVersionWarning = ("Selected package filtering '{0}' doesn't match Amiga OS set 'Amiga OS {1}'. This will show packages that are not supported by selected Amiga OS and packages might not work correctly and could result in corrupt or incorrect installation.`r`n`r`n" -f $choice.Text, $amigaOsEntry.AmigaOsVersion)
        }

        if ($choice.Value -ne 'Back' -and (ConfirmDialog "Select package filtering" ("{0}Changing package filtering will reset install packages.`r`n`r`nAre you sure you want to select package filtering '{1}'?" -f $amigaOsVersionWarning, $choice.Text) "Warning"))
        {
            # remove install packages from packages
            foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
            {
                $hstwb.Settings.Packages.Remove($installPackageKey)
            }

            $hstwb.Settings.Packages.PackageFiltering = $choice.Value
            Save $hstwb

            break
        }
    } until ($choice.Value -eq 'Back')
}

# select packages
function SelectPackages($hstwb)
{
    # get package names sorted
    $packageNames = @()
    $packageNames += SortPackageNames $hstwb | Where-Object { $hstwb.Settings.Packages.PackageFiltering -eq 'All' -or !$hstwb.Packages[$_].AmigaOsVersions -or $hstwb.Packages[$_].AmigaOsVersions -contains $hstwb.Settings.Packages.PackageFiltering } | ForEach-Object { $_.ToLower() }

    # get install packages
    $packageNamesInstallIndex = @{}
    $hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' } | ForEach-Object { $packageNamesInstallIndex[$hstwb.Settings.Packages[$_]] = $true }

    # build available and install packages indexes
    $dependencyPackageNamesIndex = @{}
    $contentIdPackages = @{}

    foreach ($packageName in $packageNames)
    {
        $package = $hstwb.Packages[$packageName]

        if ($package.Dependencies)
        {
            foreach($dependencyPackageName in ($package.Dependencies | ForEach-Object { $_.Name.ToLower() }))
            {
                if ($dependencyPackageNamesIndex.ContainsKey($dependencyPackageName))
                {
                    $dependencyPackageNames = $dependencyPackageNamesIndex.Get_Item($dependencyPackageName)
                }
                else
                {
                    $dependencyPackageNames = @()
                }
    
                $dependencyPackageNames += $packageName
    
                $dependencyPackageNamesIndex.Set_Item($dependencyPackageName, $dependencyPackageNames)
            }
        }

        if ($package.ContentIds)
        {
            foreach($contentId in ($package.ContentIds | ForEach-Object { $_.ToLower() }))
            {
                if (!$contentIdPackages.ContainsKey($contentId))
                {
                    $contentIdPackages[$contentId] = @()
                }
    
                if (($contentIdPackages[$contentId] | Where-Object { $_.Id -eq $package.Id }).Count -gt 0)
                {
                    continue
                }
    
                $contentIdPackages[$contentId] += $package
            }            
        }
    }

    do
    {
        # build package options
        $packageOptions = @(
            @{ 'Text' = 'Select package filtering'; 'Value' = 'select-package-filtering' },
            @{ 'Text' = 'Install all packages'; 'Value' = 'install-all-packages' },
            @{ 'Text' = 'Skip all packages'; 'Value' = 'skip-all-packages' }
        )

        foreach ($packageName in $packageNames)
        {
            $package = $hstwb.Packages[$packageName]
            $dependenciesIndicator = if ($package.Dependencies -and $package.Dependencies.Count -gt 0) { ' (*)' } else { '' }
        
            $packageNameFormatted = "{0}{1}" -f $package.FullName, $dependenciesIndicator
    
            $installPackage = $packageNamesInstallIndex.ContainsKey($packageName)

            $packageOptions += @{
                'Text' = if ($installPackage) { ("Install : {0}" -f $packageNameFormatted) } else { ("Skip    : " + $packageNameFormatted) };
                'Value' = $packageName;
                'Color' = if ($installPackage) { 'Green' } else { $null }
            }
        }

        $packageOptions += @{
            'Text' = 'Back';
            'Value' = 'back'
        }

        $choice = Menu $hstwb "Select packages" $packageOptions

        $addPackageNames = @()
        $removePackageNames = @()
        
        if ($choice.Value -eq 'select-package-filtering')
        {
            SelectPackageFiltering $hstwb

            # get package names sorted
            $packageNames = @()
            $packageNames += SortPackageNames $hstwb | Where-Object { $hstwb.Settings.Packages.PackageFiltering -eq 'All' -or !$hstwb.Packages[$_].AmigaOsVersions -or $hstwb.Packages[$_].AmigaOsVersions -contains $hstwb.Settings.Packages.PackageFiltering } | ForEach-Object { $_.ToLower() }

            # get install packages
            $packageNamesInstallIndex = @{}
            $hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' } | ForEach-Object { $packageNamesInstallIndex[$hstwb.Settings.Packages[$_]] = $true }
        }
        elseif ($choice.Value -eq 'install-all-packages')
        {
            $addPackageNames += $packageNames
        }
        elseif ($choice.Value -eq 'skip-all-packages')
        {
            $removePackageNames += $packageNamesInstallIndex.Keys
        }
        elseif ($choice.Value -ne 'back')
        {
            $packageName = $choice.Value

            # skip package, if it's set to install. otherwise deselect package
            if ($packageNamesInstallIndex.ContainsKey($packageName))
            {
                $skipPackage = $true

                # show package dependency warning, if package has dependencies
                if ($dependencyPackageNamesIndex.ContainsKey($packageName))
                {
                    # get package
                    $package = $hstwb.Packages[$packageName]

                    # list selected package names that has dependencies to package
                    $dependencyPackageNames = @()
                    $dependencyPackageNames += $dependencyPackageNamesIndex[$packageName] | Where-Object { $packageNamesInstallIndex.ContainsKey($_) } | Foreach-Object { $hstwb.Packages[$_].Name }

                    # show package dependency warning
                    if ($dependencyPackageNames.Count -gt 0 -and !(ConfirmDialog "Package dependency warning" ("Warning! Package(s) '{0}' has a dependency to '{1}' and skipping it may cause issues when installing packages.`r`n`r`nAre you sure you want to skip package '{1}'?" -f ($dependencyPackageNames -join ', '), $package.Name)))
                    {
                        $skipPackage = $false
                    }
                }

                if ($skipPackage)
                {
                    $removePackageNames += $packageName
                }
            }
            else
            {
                # add package
                $addPackageNames += $packageName

                # get package
                $package = $hstwb.Packages[$packageName]

                $identicalContentIds = @()
                if ($hstwb.Settings.Installer.Mode -eq "Install" -and $package.ContentIds)
                {
                    $identicalContentIds += (Compare-Object -ReferenceObject ($contentIdPackages.keys | ForEach-Object { $_.ToString() }) -DifferenceObject $package.ContentIds -includeEqual -ExcludeDifferent).InputObject
                }

                if ($identicalContentIds.Count -gt 0)
                {
                    $dependencyPackageNames = @()
                    if ($dependencyPackageNamesIndex.ContainsKey($packageName))
                    {
                        $dependencyPackageNames += $dependencyPackageNamesIndex[$packageName] | Where-Object { $packageNamesInstallIndex.ContainsKey($_) } | Foreach-Object { $hstwb.Packages[$_].Name }
                    }

                    $removePackageNames += $identicalContentIds | ForEach-Object { $contentIdPackages[$_] } | Where-Object { $_.Id -ne $package.Id -and $dependencyPackageNames -notcontains $_.Name } | Sort-Object -Property Id -Unique | ForEach-Object { $_.Name }
                }        
            }         
        }

        
        if ($removePackageNames.Count -gt 0)
        {
            foreach($packageName in $removePackageNames)
            {
                if (!$packageNamesInstallIndex.ContainsKey($packageName))
                {
                    continue
                }

                $packageNamesInstallIndex.Remove($packageName)
                
                $packageAssignsKey = $hstwb.Assigns.Keys | Where-Object { $_ -like $packageName } | Select-Object -First 1

                if ($packageAssignsKey)
                {
                    $hstwb.Assigns.Remove($packageAssignsKey)
                }
            }
        }

        if ($addPackageNames.Count -gt 0)
        {
            foreach($packageName in $addPackageNames)
            {
                if ($packageNamesInstallIndex.ContainsKey($packageName))
                {
                    continue
                }

                # get package
                $package = $hstwb.Packages[$packageName]

                $selectedPackageNames = @()
                
                if ($package.Dependencies.Count -gt 0)
                {
                    $selectedPackageNames += GetDependencyPackageNames $hstwb $package
                }

                $selectedPackageNames += $packageName

                foreach($selectedPackageName in $selectedPackageNames)
                {
                    if ($packageNamesInstallIndex.ContainsKey($selectedPackageName))
                    {
                        continue
                    }

                    $packageNamesInstallIndex.Set_Item($selectedPackageName, $true)

                    # get selected package
                    $selectedPackage = $hstwb.Packages[$selectedPackageName]
            
                    if ($selectedPackage.Assigns -and $selectedPackage.Assigns.Count -gt 0)
                    {
                        $packageAssigns = @()
                        $packageAssigns += $selectedPackage.Assigns | Where-Object { $_.Path -and $_.Path -notmatch '^\s*$' }

                        if ($packageAssigns.Count -eq 0)
                        {
                            continue
                        }

                        $hstwb.Assigns[$package.Name] = @{}
                        $packageAssigns | ForEach-Object { $hstwb.Assigns[$package.Name][$_.Name] = $_.Path }
                    }
                }
            }
        }

        if ($addPackageNames.Count -gt 0 -or $removePackageNames -gt 0)
        {
            # remove install packages from packages
            foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
            {
                $hstwb.Settings.Packages.Remove($installPackageKey)
            }

            # build and set new install packages
            $newInstallPackages = @()
            $newInstallPackages += $packageNames | Where-Object { $packageNamesInstallIndex.ContainsKey($_) } | Foreach-Object { $hstwb.Packages[$_].Name }

            # add install packages to packages
            for($i = 0; $i -lt $newInstallPackages.Count; $i++)
            {
                $hstwb.Settings.Packages.Set_Item(("InstallPackage{0}" -f ($i + 1)), $newInstallPackages[$i])
            }

            Save $hstwb            
        }
    }
    until ($choice.Value -eq 'back')
}

# update packages
function UpdatePackages($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Update packages" @("Update packages list", "Download latest prerelease packages", "Download latest packages", "Back") 
        switch ($choice)
        {
            "Update packages list" { UpdatePackagesList $hstwb }
            "Download latest prerelease packages" { DownloadLatestPackages $hstwb $true }
            "Download latest packages" { DownloadLatestPackages $hstwb $false }
        }
    }
    until ($choice -eq 'Back')
}

# update packages list
function UpdatePackagesList($hstwb)
{
    # read packages list file
    $packagesList = Get-Content $hstwb.Paths.PackagesListFile -Raw | ConvertFrom-Json

    Write-Host ''
    Write-Host 'Downloading packages list...' -ForegroundColor 'Yellow'

    try
    {
        Write-Host $packagesList.Url -ForegroundColor 'Yellow'
        $newPackagesList = Invoke-WebRequest $packagesList.Url
        Set-Content $hstwb.Paths.PackagesListFile -Value $newPackagesList
        Write-Host 'Done' -ForegroundColor 'Yellow'
    }
    catch
    {
        Write-Host ("Failed to download packages list: {0}" -f $_.Exception.Message) -ForegroundColor 'Red'
    }

    Write-Host ''
    Write-Host "Press enter to continue"
    Read-Host
}

# download latest packages
function DownloadLatestPackages($hstwb, $prerelease)
{
    $prereleaseText = if ($prerelease) { 'prerelease ' } else { '' }
    if (!(ConfirmDialog ("Download latest {0}packages" -f $prereleaseText) ("Do you want to download latest {0}packages?" -f $prereleaseText)))
    {
        return
    }

    Write-Host ''
    Write-Host 'Downloading packages...' -ForegroundColor 'Yellow'

    # read packages list file
    $packagesList = Get-Content $hstwb.Paths.PackagesListFile -Raw | ConvertFrom-Json

    # download packages
    $packageManager = [PackageManager]::new($hstwb.Paths.PackagesPath)
    $packageManager.DownloadPackages($packagesList.Packages, $prerelease)

    # read packages
    $hstwb.Packages = ReadPackages $hstwb.Paths.PackagesPath;

    Write-Host 'Done' -ForegroundColor 'Yellow'
    Write-Host ''
    Write-Host "Press enter to continue"
    Read-Host
}

# configure user packages
function ConfigureUserPackages($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure user packages" @("Change user packages dir", "Select user packages", "Back") 
        switch ($choice)
        {
            "Change user packages dir" { ChangeUserPackagesDir $hstwb }
            "Select user packages" { SelectUserPackages $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# change user packages dir
function ChangeUserPackagesDir($hstwb)
{
    $path = if (!$hstwb.Settings.UserPackages.UserPackagesDir) { ${Env:USERPROFILE} } else { $hstwb.Settings.UserPackages.UserPackagesDir }
    $newPath = FolderBrowserDialog "Select user packages directory" $path $false

    if ($newPath -and $newPath -ne '')
    {
        $hstwb.Settings.UserPackages.UserPackagesDir = $newPath

        foreach($installUserPackageKey in ($hstwb.Settings.UserPackages.Keys | Where-Object { $_ -match 'InstallUserPackage\d+' }))
        {
            $hstwb.Settings.UserPackages.Remove($installUserPackageKey)
        }

        Save $hstwb

        $hstwb.UserPackages = DetectUserPackages $hstwb
    }
}


# select user packages
function SelectUserPackages($hstwb)
{
    # get user packages
    $userPackageNames = $hstwb.UserPackages.keys | Sort-Object @{expression={$_};Ascending=$true}

    # get user install packages index
    $userPackageNamesInstallIndex = @{}
    $hstwb.Settings.UserPackages.Keys | Where-Object { $_ -match 'InstallUserPackage\d+' } | ForEach-Object { $userPackageNamesInstallIndex[$hstwb.Settings.UserPackages[$_]] = $true }

    do
    {
        # build user package options
        $userPackageOptions = @(
            @{ 'Text' = 'Install all user packages'; 'Value' = 'install-all-user-packages' },
            @{ 'Text' = 'Skip all user packages'; 'Value' = 'skip-all-user-packages' }
        )
        foreach ($userPackageName in $userPackageNames)
        {
            $userPackage = $hstwb.UserPackages.Get_Item($userPackageName)
            $installUserPackage = $userPackageNamesInstallIndex.ContainsKey($userPackageName)

            $userPackageOptions += @{
                'Text' = if ($installUserPackage) { ("Install : {0}" -f $userPackage.Name) } else { ("Skip    : " + $userPackage.Name) };
                'Value' = $userPackageName;
                'Color' = if ($installUserPackage) { 'Green' } else { $null }
            }
        }
        $userPackageOptions += @{
            'Text' = 'Back';
            'Value' = 'back'
        }

        $choice = Menu $hstwb "Select user packages" $userPackageOptions

        $addUserPackageNames = @()
        $removeUserPackageNames = @()
        
        if ($choice.Value -eq 'install-all-user-packages')
        {
            $addUserPackageNames += $hstwb.UserPackages.Keys
        }
        elseif ($choice.Value -eq 'skip-all-user-packages')
        {
            $removeUserPackageNames += $userPackageNamesInstallIndex.Keys
        }
        elseif ($choice.Value -ne 'back')
        {
            $userPackageName = $choice.Value

            # remove user package, if user package exists in install userpackages. otherwise, add user package to install user packages
            if ($userPackageNamesInstallIndex.ContainsKey($userPackageName))
            {
                $removeUserPackageNames += $userPackageName
            }
            else
            {
                $addUserPackageNames += $userPackageName
            }
        }

        if ($addUserPackageNames.Count -gt 0)
        {
            foreach($userPackageName in $addUserPackageNames)
            {
                if ($userPackageNamesInstallIndex.ContainsKey($userPackageName))
                {
                    continue
                }
    
                $userPackageNamesInstallIndex.Set_Item($userPackageName, $true)
            }
        }

        if ($removeUserPackageNames.Count -gt 0)
        {
            foreach($userPackageName in $removeUserPackageNames)
            {
                if (!$userPackageNamesInstallIndex.ContainsKey($userPackageName))
                {
                    continue
                }
    
                $userPackageNamesInstallIndex.Remove($userPackageName)
            }
        }

        if ($addUserPackageNames.Count -gt 0 -or $removeUserPackageNames -gt 0)
        {
            # remove install user packages from user packages
            foreach($installUserPackageKey in ($hstwb.Settings.UserPackages.Keys | Where-Object { $_ -match 'InstallUserPackage\d+' }))
            {
                $hstwb.Settings.UserPackages.Remove($installUserPackageKey)
            }
            
            # build and set new install user packages
            $newInstallUserPackages = @()
            $newInstallUserPackages += $userPackageNamesInstallIndex.keys | Sort-Object @{expression={$_};Ascending=$true}

            # add install user packages to user packages
            for($i = 0; $i -lt $newInstallUserPackages.Count; $i++)
            {
                $hstwb.Settings.UserPackages.Set_Item(("InstallUserPackage{0}" -f ($i + 1)), $newInstallUserPackages[$i])
            }
            
            Save $hstwb
        }
    }
    until ($choice.Value -eq 'back')
}


# configure emulator
function ConfigureEmulator($hstwb)
{
    do
    {
        $choice = Menu $hstwb 'Configure emulator' @('Select emulator', 'Back')
        switch ($choice)
        {
            'Select emulator' { SelectEmulator $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# select emulator
function SelectEmulator($hstwb)
{
    $emulators = @{}
    $hstwb.Emulators | ForEach-Object { $emulators.Set_Item(('{0} ({1})' -f $_.Name,$_.File), $_.File ) }
    
    $toNatural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }
    
    $options = @()
    $options += $emulators.Keys | Sort-Object $toNatural
    $options += 'Custom, select emulator .exe file'
    $options += 'Back'
    
    $choice = Menu $hstwb "Select emulator" $options 

    if ($choice -eq 'Custom, select emulator .exe file')
    {
        SelectEmulatorExeFile $hstwb
    }
    elseif ($choice -ne 'Back')
    {
        $hstwb.Settings.Emulator.EmulatorFile = $emulators[$choice]
        Save $hstwb
    }
}


# select emulator exe file
function SelectEmulatorExeFile($hstwb)
{
    $path = if (!$hstwb.Settings.Emulator.EmulatorFile) { ${Env:ProgramFiles(x86)} } else { [System.IO.Path]::GetDirectoryName($hstwb.Settings.Emulator.EmulatorFile) }
    $emulatorFile = OpenFileDialog "Select emulator .exe file" $path "Exe Files|*.exe|All Files|*.*"

    if ($emulatorFile -and $emulatorFile -ne '')
    {
        $hstwb.Settings.Emulator.EmulatorFile = $emulatorFile
        Save $hstwb
    }
}


# configure installer
function ConfigureInstaller($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure Installer" @("Change Installer mode", "Back") 
        switch ($choice)
        {
            "Change Installer mode" { ChangeInstallerMode $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# change installer mode
function ChangeInstallerMode($hstwb)
{
    # installer mode options
    $installerModeOptions = @()
    $installerModeOptionColor = if ($hstwb.Settings.Installer.Mode -eq 'Install') { "Green" } else { $null }
    $installerModeOptions += @{
        'Text' = 'Install';
        'Value' = 'Install';
        'Color' = $installerModeOptionColor
    }
    $installerModeOptionColor = if ($hstwb.Settings.Installer.Mode -eq 'BuildSelfInstall') { "Green" } else { $null }
    $installerModeOptions += @{
        'Text' = 'Build Self Install';
        'Value' = 'BuildSelfInstall';
        'Color' = $installerModeOptionColor
    }
    $installerModeOptionColor = if ($hstwb.Settings.Installer.Mode -eq 'BuildPackageInstallation') { "Green" } else { $null }
    $installerModeOptions += @{
        'Text' = 'Build Package Installation';
        'Value' = 'BuildPackageInstallation';
        'Color' = $installerModeOptionColor
    }
    $installerModeOptionColor = if ($hstwb.Settings.Installer.Mode -eq 'BuildUserPackageInstallation') { "Green" } else { $null }
    $installerModeOptions += @{
        'Text' = 'Build User Package Installation';
        'Value' = 'BuildUserPackageInstallation';
        'Color' = $installerModeOptionColor
    }
    $installerModeOptionColor = if ($hstwb.Settings.Installer.Mode -eq 'Test') { "Green" } else { $null }
    $installerModeOptions += @{
        'Text' = 'Test';
        'Value' = 'Test';
        'Color' = $installerModeOptionColor
    }
    $installerModeOptions += @{
        'Text' = 'Back';
        'Value' = 'Back'
    }

    $choice = Menu $hstwb "Change Installer Mode" $installerModeOptions

    if ($choice.Value -ne 'Back')
    {
        # set ignore identical content to false
        $hstwb.IgnoreIdenticalContent = $false

        # remove install packages, if installer mode is changed
        if ($hstwb.Settings.Installer.Mode -ne $choice.Value)
        {
            RemoveInstallPackages $hstwb
        }

        # set installer mode
        $hstwb.Settings.Installer.Mode = $choice.Value

        # update package filtering and install packages, if install mode is used
        if ($hstwb.Settings.Installer.Mode -eq "Install")
        {
            UpdatePackageFiltering $hstwb
        }
        else
        {
            $hstwb.Settings.Packages.PackageFiltering = 'All'
        }
        UpdateInstallPackages $hstwb

        # ui amiga os set info
        UiAmigaOsSetInfo $hstwb $hstwb.Settings.AmigaOs.AmigaOsSet

        Save $hstwb
    }
}


# run installer
function RunInstaller($hstwb)
{
    Write-Host ""
    & $hstwb.Paths.RunFile -settingsDir $hstwb.Paths.SettingsDir
    Write-Host ""

    $host.ui.RawUI.WindowTitle = "HstWB Installer Setup v{0}" -f (HstwbInstallerVersion)
}


# save
function Save($hstwb)
{
    WriteIniFile $hstwb.Paths.SettingsFile $hstwb.Settings
    WriteIniFile $hstwb.Paths.AssignsFile $hstwb.Assigns
}


# reset settings
function ResetSettings($hstwb)
{
    $confirm = ConfirmDialog "Reset" "Are you sure you want to reset settings?"
    if (!$confirm)
    {
        return
    }

    DefaultSettings $hstwb
    DefaultAssigns $hstwb.Assigns
    Save $hstwb

    $hstwb.UserPackages = DetectUserPackages $hstwb
}


# resolve paths
$kickstartEntriesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("data\kickstart-entries.csv")
$amigaOsEntriesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("data\amiga-os-entries.csv")
$hstwbPackagesListFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("data\hstwb-packages.json")
$imagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("images")
$packagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("packages")
$runFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("run.ps1")
$userPackagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("user-packages")

if (!$settingsDir)
{
    $settingsDir = Join-Path $env:LOCALAPPDATA -ChildPath 'HstWB Installer'
}
$settingsDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($settingsDir)
$settingsFile = Join-Path $settingsDir -ChildPath "hstwb-installer-settings.ini"
$assignsFile = Join-Path $settingsDir -ChildPath "hstwb-installer-assigns.ini"

$host.ui.RawUI.WindowTitle = "HstWB Installer Setup v{0}" -f (HstwbInstallerVersion)


try
{
    Write-Host "Starting HstWB Installer Setup..."

    # create settings dir, if it doesn't exist
    if(!(test-path -path $settingsDir))
    {
        mkdir $settingsDir | Out-Null
    }
    
    
    
    
    # read assigns, if assigns file exist
    if (test-path -path $assignsFile)
    {
        $assigns = ReadIniFile $assignsFile
    }
    else
    {
        $assigns = @{}
    }

    # hstwb
    $hstwb = @{
        'Version' = HstwbInstallerVersion;
        'Paths' = @{
            'KickstartEntriesFile' = $kickstartEntriesFile;
            'AmigaOsEntriesFile' = $amigaOsEntriesFile;
            'PackagesListFile' = $hstwbPackagesListFile
            'ImagesPath' = $imagesPath;
            'PackagesPath' = $packagesPath;
            'SettingsFile' = $settingsFile;
            'AssignsFile' = $assignsFile;
            'RunFile' = $runFile;
            'SettingsDir' = $settingsDir;
            'UserPackagesPath' = $userPackagesPath
        };
        'Models' = @('A1200', 'A500');
        'Images' = (ReadImages $imagesPath | Where-Object { $_ });
        'Packages' = (ReadPackages $packagesPath | Where-Object { $_ });
        'Settings' = @{};
        'Assigns' = $assigns;
        'UI' = @{
            'AmigaOs' = @{};
            'Kickstart' = @{}
        };
        'AmigaOsSets' = @()
    }

    # create default settings, if settings file doesn't exist
    if (test-path -path $settingsFile)
    {
        $hstwb.Settings = ReadIniFile $settingsFile
    }
    else
    {
        DefaultSettings $hstwb
    }

    # upgrade settings and assigns
    UpgradeSettings $hstwb
    UpgradeAssigns $hstwb

    # update amiga os entries
    UpdateAmigaOsEntries $hstwb

    # update kickstart entries
    UpdateKickstartEntries $hstwb

    # detect user packages
    $hstwb.UserPackages = DetectUserPackages $hstwb
    $hstwb.Emulators = FindEmulators
    
    # update packages, user packages and assigns
    UpdateInstallPackages $hstwb
    UpdateInstallUserPackages $hstwb
    UpdateAssigns $hstwb

    # find best matching amiga os set, if amiga os set is not defined. otherwise find amiga os files
    Write-Host "Finding Amiga OS sets in Amiga OS dir..."
    if (!$hstwb.Settings.AmigaOs.AmigaOsSet -or $hstwb.Settings.AmigaOs.AmigaOsSet -match '^\s*$')
    {
        $hstwb.Settings.AmigaOs.AmigaOsSet = FindBestMatchingAmigaOsSet $hstwb    
    }
    else
    {
        FindAmigaOsFiles $hstwb
    }

    # find best matching kickstart set, if kickstart set is not defined. otherwise find kickstart files
    Write-Host "Finding Kickstart sets in Kickstart dir..."
    if (!$hstwb.Settings.Kickstart.KickstartSet -or $hstwb.Settings.Kickstart.KickstartSet -match '^\s*$')
    {
        $hstwb.Settings.Kickstart.KickstartSet = FindBestMatchingKickstartSet $hstwb
    }
    else
    {
        FindKickstartFiles $hstwb
    }

    # save settings and assigns
    Save $hstwb

    Write-Host "Done"
    Start-Sleep -m 200

    # ui amiga os set info
    UiAmigaOsSetInfo $hstwb $hstwb.Settings.AmigaOs.AmigaOsSet

    # ui kickstart set info
    UiKickstartSetInfo $hstwb $hstwb.Settings.Kickstart.KickstartSet

    # show main
    Main $hstwb
}
catch
{
    $errorFormatingString = "{0} : {1}`n{2}`n" +
    "    + CategoryInfo          : {3}`n" +
    "    + FullyQualifiedErrorId : {4}`n"

    $errorFields = $_.InvocationInfo.MyCommand.Name,
    $_.ErrorDetails.Message,
    $_.InvocationInfo.PositionMessage,
    $_.CategoryInfo.ToString(),
    $_.FullyQualifiedErrorId

    $message = $errorFormatingString -f $errorFields
    $logFile = Join-Path $settingsDir -ChildPath "hstwb_installer.log"
    Add-Content $logFile ("{0} | ERROR | {1}" -f (Get-Date -Format s), $message) -Encoding UTF8
    Write-Host ""
    Write-Error "HstWB Installer Run Failed! $message"
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
}