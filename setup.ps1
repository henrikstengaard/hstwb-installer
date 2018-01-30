# HstWB Installer Setup
# ---------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-01-30
#
# A powershell script to setup HstWB Installer run for an Amiga HDF file installation.


Param(
	[Parameter(Mandatory=$true)]
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


# set title
function SetTitle($version)
{
    $host.ui.RawUI.WindowTitle = "HstWB Installer Setup v{0}" -f $version
}


# menu
function Menu($hstwb, $title, $options)
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

    return EnterChoice "Enter choice" $options
}


# main menu
function MainMenu($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Main Menu" @("Configure Image", "Configure Workbench", "Configure Amiga OS 3.9", "Configure Kickstart", "Configure Packages", "Configure User Packages", "Configure Emulator", "Configure Installer", "Run Installer", "Reset Settings", "Exit")
        switch ($choice)
        {
            "Configure Image" { ConfigureImageMenu $hstwb }
            "Configure Workbench" { ConfigureWorkbenchMenu $hstwb }
            "Configure Amiga OS 3.9" { ConfigureAmigaOS39Menu $hstwb }
            "Configure Kickstart" { ConfigureKickstartMenu $hstwb }
            "Configure Packages" { ConfigurePackagesMenu $hstwb }
            "Configure User Packages" { ConfigureUserPackagesMenu $hstwb }
            "Configure Emulator" { ConfigureEmulatorMenu $hstwb }
            "Configure Installer" { ConfigureInstaller $hstwb }
            "Run Installer" { RunInstaller $hstwb }
            "Reset Settings" { ResetSettings $hstwb }
        }
    }
    until ($choice -eq 'Exit')
}


# configure image menu
function ConfigureImageMenu($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure Image Menu" @("Existing Image Directory", "Create Image Directory From Image Template", "Back") 
        switch ($choice)
        {
            "Existing Image Directory" { ExistingImageDirectory $hstwb }
            "Create Image Directory From Image Template" { CreateImageDirectoryFromImageTemplateMenu $hstwb }
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

    $newPath = FolderBrowserDialog "Select existing image directory" $path $false

    if ($newPath -and $newPath -ne '')
    {
        $hstwb.Settings.Image.ImageDir = $newPath
        Save $hstwb
    }
}


# create image directory menu
function CreateImageDirectoryFromImageTemplateMenu($hstwb)
{
    $toNatural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }

    $imageTemplateOptions = @()
    $imageTemplateOptions += $hstwb.Images.keys | Sort-Object $toNatural
    $imageTemplateOptions += "Back"
    

    # create image directory from image template
    $choice = Menu $hstwb "Create Image Directory From Image Template Menu" $imageTemplateOptions

    if ($choice -eq 'Back')
    {
        return
    }

    # get image file
    $imageFile = $hstwb.Images.Get_Item($choice)


    # read harddrives uae text file from image file
    $harddrivesUaeText = ReadZipEntryTextFile $imageFile 'harddrives\.uae$'

    # return, if harddrives uae text doesn't exist
    if (!$harddrivesUaeText)
    {
        Write-Error ("Image file '$imageFile' doesn't contain harddrives.uae file!")
        Write-Host ""
        Write-Host "Press enter to continue"
        Read-Host
        return
    }


    # get harddrives from harddrives uae text
    $harddrives = @()
    $harddrivesUaeText -split "`r`n" | ForEach-Object { $_ | Select-String -Pattern '^uaehf\d+=(hdf|dir),[^,]*,([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $harddrives += @{ "Type" = $_.Groups[1].Value.Trim(); "Path" = $_.Groups[2].Value.Trim() } } }

    # return, if harddrives uae file doesn't contain uaehf lines
    if ($harddrives.Count -eq 0)
    {
        Write-Error ("Image file '$imageFile' harddrives.uae doesn't contain uaehf lines!")
        Write-Host ""
        Write-Host "Press enter to continue"
        Read-Host
        return
    }

    # return, if harddrives uae file contains invalid uaehf lines
    if (($harddrives | Where-Object { ($_.Type -and $_.Type -eq '') -or ($_.Path -and $_.Path -eq '') }).Count -gt 0)
    {
        Write-Error ("Image file '$imageFile' harddrives.uae has invalid 'uaehf' lines!")
        Write-Host ""
        Write-Host "Press enter to continue"
        Read-Host
        return
    }


    # check, if image has large harddrives
    $largeHarddrivesPresent = $false
    foreach($harddrive in ($harddrives | Where-Object { $_.Type -match 'hdf' }))
    {
        # get harddrive path
        $harddrivePath = $harddrive.Path -replace '.+:([^:]+)$', '$1'
        $harddrivePath = $harddrivePath.Replace('[$ImageDir]', $newImageDirectoryPath)
        $harddrivePath = $harddrivePath.Replace('[$ImageDirEscaped]', $newImageDirectoryPath)
        $harddrivePath = $harddrivePath -replace '\\+', '\' -replace '"', ''

        # get hdf filename
        $hdfFileName = Split-Path $harddrivePath -Leaf

        # open image file and get hdf zip entry matching hdf filename
        $zip = [System.IO.Compression.ZipFile]::Open($imageFile,"Read")
        $hdfZipEntry = $zip.Entries | Where-Object { $_.FullName -like ('*' + $hdfFileName + '*') }

        # return, if image file doesn't contain hdf filename
        if (!$hdfZipEntry)
        {
            $zip.Dispose()
            Write-Error ("Image file '" + $imageFile + "' doesn't contain HDF file '$hdfFileName'!")
            Write-Host ""
            Write-Host "Press enter to continue"
            return
        }

        # show large harddrive warning, if image has a hdf file larger than 4GB
        if ($hdfZipEntry.Length -gt 4000000000)
        {
            $largeHarddrivesPresent = $true
        }

        # close image file
        $zip.Dispose()
    }


    # show large harddrive warning, if image has large harddrives
    if ($largeHarddrivesPresent)
    {
        $confirm = ConfirmDialog 'Large harddrive' ("Image '{0}' uses harddrive(s) larger than 4GB and might become corrupt depending on scsi.device and filesystem used.`r`n`r`nIt's recommended to use tools to check and repair harddrive integrity, e.g. pfsdoctor for partitions with PFS\3 filesystem.`r`n`r`nDo you want to use the image?" -f $choice) 'Warning'
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
    $newImageDirectoryPath = FolderBrowserDialog "Select new image directory for '$choice'" $defaultImageDir $true

    # return, if new image directory path is null
    if ($newImageDirectoryPath -eq $null)
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




    # harddrives uae file
    $harddrivesUaeFile = Join-Path $newImageDirectoryPath -ChildPath "harddrives.uae"

    # confirm overwrite, if harddrives.uae already exists in new image directory path
    if (Test-Path -Path $harddrivesUaeFile)
    {
        $confirm = ConfirmDialog "Overwrite files" ("Image directory '" + $newImageDirectoryPath + "' already contains harddrives.uae and image files.`r`n`r`nDo you want to overwrite files?")
        if (!$confirm)
        {
            return
        }
    }


    # write harddrives.uae to new image directory path
    [System.IO.File]::WriteAllText($harddrivesUaeFile, $harddrivesUaeText)


    Write-Host ""


    # prepare harddrives
    foreach($harddrive in $harddrives)
    {
        # get harddrive path
        $harddrivePath = $harddrive.Path -replace '.+:([^:]+)$', '$1'
        $harddrivePath = $harddrivePath.Replace('[$ImageDir]', $newImageDirectoryPath)
        $harddrivePath = $harddrivePath.Replace('[$ImageDirEscaped]', $newImageDirectoryPath)
        $harddrivePath = $harddrivePath -replace '\\+', '\' -replace '"', ''


        # extract hdf or create dir harddrive
        switch ($harddrive.Type)
        {
            "hdf"
            {
                # get hdf filename
                $hdfFileName = [System.IO.Path]::GetFileName($harddrivePath)

                # open image file and get hdf zip entry matching hdf filename
                $zip = [System.IO.Compression.ZipFile]::Open($imageFile,"Read")
                $hdfZipEntry = $zip.Entries | Where-Object { $_.FullName -like ('*' + $hdfFileName + '*') }

                # return, if image file doesn't contain hdf filename
                if (!$hdfZipEntry)
                {
                    $zip.Dispose()
                    Write-Error ("Image file '" + $imageFile + "' doesn't contain HDF file '$hdfFileName'!")
                    Write-Host ""
                    Write-Host "Press enter to continue"
                    return
                }

                # extract hdf zip entry to harddrive path
                Write-Host "Extracting hdf file '$hdfFileName' to '$harddrivePath'..." 
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($hdfZipEntry, $harddrivePath, $true);
                Write-Host "Done."
                $zip.Dispose()
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


    # wait 5 seconds
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
}


# configure workbench menu
function ConfigureWorkbenchMenu($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure Workbench Menu" @("Switch Install Workbench", "Change Workbench Adf Dir", "Select Workbench Adf Set", "Back") 
        switch ($choice)
        {
            "Switch Install Workbench" { SwitchInstallWorkbench $hstwb }
            "Change Workbench Adf Dir" { ChangeWorkbenchAdfDir $hstwb }
            "Select Workbench Adf Set" { SelectWorkbenchAdfSet $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# switch install workbench
function SwitchInstallWorkbench($hstwb)
{
    if ($hstwb.Settings.Workbench.InstallWorkbench -eq 'Yes')
    {
        $hstwb.Settings.Workbench.InstallWorkbench = 'No'
    }
    else
    {
        $hstwb.Settings.Workbench.InstallWorkbench = 'Yes'
    }
    Save $hstwb
}


# change workbench adf dir
function ChangeWorkbenchAdfDir($hstwb)
{
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $defaultWorkbenchAdfPath = Join-Path $amigaForeverDataPath -ChildPath "Shared\adf"
    }
    else
    {
        $defaultWorkbenchAdfPath = ${Env:USERPROFILE}
    }

    $path = if (!$hstwb.Settings.Workbench.WorkbenchAdfDir) { $defaultWorkbenchAdfPath } else { $hstwb.Settings.Workbench.WorkbenchAdfDir }
    $newWorkbenchAdfDir = FolderBrowserDialog "Select Workbench Adf Directory" $path $false

    if ($newWorkbenchAdfDir -and $newWorkbenchAdfDir -ne '')
    {
        # set new workbench adf dir
        $hstwb.Settings.Workbench.WorkbenchAdfDir = $newWorkbenchAdfDir

        # set new workbench adf set and save
        $hstwb.Settings.Workbench.WorkbenchAdfSet = FindBestMatchingWorkbenchAdfSet $hstwb
        Save $hstwb
    }
}


# select workbench adf set
function SelectWorkbenchAdfSet($hstwb)
{
    # get workbench name padding
    $workbenchNamePadding = ($hstwb.WorkbenchAdfHashes | ForEach-Object { $_.Name } | Sort-Object @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

    # get workbench rom sets
    $workbenchAdfSets = $hstwb.WorkbenchAdfHashes | ForEach-Object { $_.Set } | Sort-Object | Get-Unique

    foreach($workbenchAdfSet in $workbenchAdfSets)
    {
        # get workbench adf set hashes
        $workbenchAdfSetHashes = @()
        $workbenchAdfSetHashes += $hstwb.WorkbenchAdfHashes | Where-Object { $_.Set -eq $workbenchAdfSet }

        $workbenchAdfSetFiles = @()
        $workbenchAdfSetFiles += $workbenchAdfSetHashes | Where-Object { $_.File }
        $workbenchAdfSetComplete = ($workbenchAdfSetFiles.Count -eq $workbenchAdfSetHashes.Count)
        
        Write-Host ""
        if ($workbenchAdfSetComplete)
        {
            Write-Host ("'{0}' ({1}/{2})" -f $workbenchAdfSet, $workbenchAdfSetFiles.Count, $workbenchAdfSetHashes.Count) -ForegroundColor "Green"
        }
        else
        {
            Write-Host ("'{0}' ({1}/{2})" -f $workbenchAdfSet, $workbenchAdfSetFiles.Count, $workbenchAdfSetHashes.Count) -ForegroundColor "Yellow"
        }

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
        $hstwb.Settings.Workbench.WorkbenchAdfSet = $choise
        Save $hstwb
    }
}


# configure amiga os 3.9 menu
function ConfigureAmigaOS39Menu($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure Amiga OS 3.9 Menu" @("Switch Install Amiga OS 3.9", "Switch Install Boing Bags", "Change Amiga OS 3.9 Iso File", "Back") 
        switch ($choice)
        {
            "Switch Install Amiga OS 3.9" { SwitchInstallAmigaOS39 $hstwb }
            "Switch Install Boing Bags" { SwitchInstallBoingBags $hstwb }
            "Change Amiga OS 3.9 Iso File" { ChangeAmigaOS39IsoFile $hstwb }
        }
    }
    until ($choice -eq 'Back')

}


# switch install amiga os 3.9
function SwitchInstallAmigaOS39($hstwb)
{
    if ($hstwb.Settings.AmigaOS39.InstallAmigaOS39 -eq 'Yes')
    {
        $hstwb.Settings.AmigaOS39.InstallAmigaOS39 = 'No'
    }
    else
    {
        $hstwb.Settings.AmigaOS39.InstallAmigaOS39 = 'Yes'
        $hstwb.Settings.AmigaOS39.InstallBoingBags = 'Yes'
    }
    Save $hstwb
}


# switch install boing bags
function SwitchInstallBoingBags($hstwb)
{
    if ($hstwb.Settings.AmigaOS39.InstallBoingBags -eq 'Yes')
    {
        $hstwb.Settings.AmigaOS39.InstallBoingBags = 'No'
    }
    else
    {
        $hstwb.Settings.AmigaOS39.InstallBoingBags = 'Yes'
    }
    Save $hstwb
}


# change amiga os 3.9 iso file
function ChangeAmigaOS39IsoFile($hstwb)
{
    $path = if (!$hstwb.Settings.AmigaOS39.AmigaOS39IsoFile) { ${Env:USERPROFILE} } else { $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile }
    $newPath = OpenFileDialog "Select Amiga OS 3.9 iso file" $path "Iso Files|*.iso|All Files|*.*"

    if ($newPath -and $newPath -ne '')
    {
        $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile = $newPath
        Save $hstwb
    }
}


# configure kickstart menu
function ConfigureKickstartMenu($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure Kickstart Menu" @("Switch Install Kickstart", "Change Kickstart Rom Dir", "Select Kickstart Rom Set", "Back") 
        switch ($choice)
        {
            "Switch Install Kickstart" { SwitchInstallKickstart $hstwb }
            "Change Kickstart Rom Dir" { ChangeKickstartRomDir $hstwb }
            "Select Kickstart Rom Set" { SelectKickstartRomSet $hstwb }
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


# change kickstart rom dir
function ChangeKickstartRomDir($hstwb)
{
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $defaultKickstartRomDir = Join-Path $amigaForeverDataPath -ChildPath "Shared\rom"
    }
    else
    {
        $defaultKickstartRomDir = ${Env:USERPROFILE}
    }

    $path = if (!$hstwb.Settings.Kickstart.KickstartRomDir) { $defaultKickstartRomDir } else { $hstwb.Settings.Kickstart.KickstartRomDir }
    $newKickstartRomDir = FolderBrowserDialog "Select Kickstart Rom Directory" $path $false

    if ($newKickstartRomDir -and $newKickstartRomDir -ne '')
    {
        # set new kickstart rom dir
        $hstwb.Settings.Kickstart.KickstartRomDir = $newKickstartRomDir
        
        # set new kickstart rom set and save
        $hstwb.Settings.Kickstart.KickstartRomSet = FindBestMatchingKickstartRomSet $hstwb
        Save $hstwb
    }
}


# select kickstart rom path
function SelectKickstartRomSet($hstwb)
{
    # get kickstart name padding
    $kickstartNamePadding = ($hstwb.KickstartRomHashes | ForEach-Object { $_.Name } | Sort-Object @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

    # get kickstart rom sets
    $kickstartRomSets = $hstwb.KickstartRomHashes | ForEach-Object { $_.Set } | Sort-Object | Get-Unique

    foreach($kickstartRomSet in $kickstartRomSets)
    {
        # get kickstart rom set hashes
        $kickstartRomSetHashes = $hstwb.KickstartRomHashes | Where-Object { $_.Set -eq $kickstartRomSet }
        
        $kickstartRomSetFiles = @()
        $kickstartRomSetFiles += $kickstartRomSetHashes | Where-Object { $_.File }
        $kickstartRomSetComplete = ($kickstartRomSetFiles.Count -eq $kickstartRomSetHashes.Count)

        Write-Host ""
        if ($kickstartRomSetComplete)
        {
            Write-Host ("'{0}' ({1}/{2})" -f $kickstartRomSet, $kickstartRomSetFiles.Count, $kickstartRomSetHashes.Count) -ForegroundColor "Green"
        }
        else
        {
            Write-Host ("'{0}' ({1}/{2})" -f $kickstartRomSet, $kickstartRomSetFiles.Count, $kickstartRomSetHashes.Count) -ForegroundColor "Yellow"
        }

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
        $hstwb.Settings.Kickstart.KickstartRomSet = $choise
        Save $hstwb
    }
}


# configure user packages menu
function ConfigurePackagesMenu($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure Packages Menu" @("Select Packages Menu", "Back") 
        switch ($choice)
        {
            "Select Packages Menu" { SelectPackagesMenu $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# select packages menu
function SelectPackagesMenu($hstwb)
{
    $packageNames = @()
    $packageNames += SortPackageNames $hstwb | ForEach-Object { $_.ToLower() }

    # get install packages
    $installPackages = @{}
    foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
    {
        $installPackages.Set_Item($hstwb.Settings.Packages.Get_Item($installPackageKey.ToLower()), $true)
    }

    # build available and install packages indexes
    $packageNamesFormattedMap = @{}
    $packageNamesMap = @{}
    $installPackagesMap = @{}
    $dependencyPackageNamesIndex = @{}

    foreach ($packageName in $packageNames)
    {
        $package = $hstwb.Packages.Get_Item($packageName).Latest

        $hasDependenciesIndicator = if ($package.PackageDependencies.Count -gt 0) { ' (*)' } else { '' }
        
        $packageNameFormatted = "{0}{1}" -f $package.PackageFullName, $hasDependenciesIndicator

        $packageNamesFormattedMap.Set_Item($packageNameFormatted, $packageName)
        $packageNamesMap.Set_Item($packageName, $packageNameFormatted)
        $installPackagesMap.Set_Item($packageName, $package.Package.Name)

        foreach($dependencyPackageName in $package.PackageDependencies)
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

    do
    {
        # build package options
        $packageOptions = @('Select all', 'Deselect all')
        $packageOptions += $packageNames | ForEach-Object { if ($installPackages.ContainsKey($_)) { ("- " + $packageNamesMap.Get_Item($_)) } else { ("+ " + $packageNamesMap.Get_Item($_)) } }
        $packageOptions += "Back"

        $choice = Menu $hstwb "Select Packages Menu" $packageOptions

        $addPackageNames = @()
        $removePackageNames = @()
        
        if ($choice -eq 'Select all')
        {
            $addPackageNames += $hstwb.Packages.Keys
        }
        elseif ($choice -eq 'Deselect all')
        {
            $removePackageNames += $installPackages.Keys
        }
        elseif ($choice -ne 'Back')
        {
            $packageNameFormatted = $choice -replace '^(\+|\-) ', ''
            $packageName = $packageNamesFormattedMap.Get_Item($packageNameFormatted)

            # deselect package, if it's already selected. otherwise deselect package
            if ($installPackages.ContainsKey($packageName))
            {
                $deselectPackage = $true

                # show package dependency warning, if package has dependencies
                if ($dependencyPackageNamesIndex.ContainsKey($packageName))
                {
                    # get package
                    $package = $hstwb.Packages.Get_Item($packageName).Latest

                    # list selected package names that has dependencies to package
                    $dependencyPackageNames = @()
                    $dependencyPackageNames += $dependencyPackageNamesIndex.Get_Item($packageName) | Where-Object { $installPackages.ContainsKey($_) } | Foreach-Object { $hstwb.Packages.Get_Item($_).Latest.Package.Name }

                    # show package dependency warning
                    if (!(ConfirmDialog "Package dependency warning" ("Warning! Package(s) '{0}' has a dependency to '{1}' and deselecting it may cause issues when installing packages.`r`n`r`nAre you sure you want to deselect package '{1}'?" -f ($dependencyPackageNames -join ', '), $package.Package.Name)))
                    {
                        $deselectPackage = $false
                    }
                }

                if ($deselectPackage)
                {
                    $removePackageNames += $packageName
                }
            }
            else
            {
                $addPackageNames += $packageName
            }         
        }

        
        if ($removePackageNames.Count -gt 0)
        {
            foreach($packageName in $removePackageNames)
            {
                if (!$installPackages.ContainsKey($packageName))
                {
                    continue
                }

                # get package
                $package = $hstwb.Packages.Get_Item($packageName).Latest
            
                $installPackages.Remove($packageName)
                
                $packageAssignsKey = $hstwb.Assigns.Keys | Where-Object { $_ -like ('*{0}*' -f $package.Package.Name) } | Select-Object -First 1

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
                if ($installPackages.ContainsKey($packageName))
                {
                    continue
                }

                # get package
                $package = $hstwb.Packages.Get_Item($packageName).Latest

                $selectedPackageNames = @()
                
                if ($package.PackageDependencies.Count -gt 0)
                {
                    $selectedPackageNames += GetDependencyPackageNames $hstwb $package
                }

                $selectedPackageNames += $packageName

                foreach($selectedPackageName in $selectedPackageNames)
                {
                    if ($installPackages.ContainsKey($selectedPackageName))
                    {
                        continue
                    }

                    $installPackages.Set_Item($selectedPackageName, $true)

                    # get selected package
                    $selectedPackage = $hstwb.Packages.Get_Item($selectedPackageName).Latest
            
                    if ($selectedPackage.Package.DefaultAssigns)
                    {
                        $hstwb.Assigns.Set_Item($package.Package.Name, $selectedPackage.Package.DefaultAssigns)
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
            $newInstallPackages += $packageNames | Where-Object { $installPackages.ContainsKey($_) } | Foreach-Object { $installPackagesMap.Get_Item($_) }

            # add install packages to packages
            for($i = 0; $i -lt $newInstallPackages.Count; $i++)
            {
                $hstwb.Settings.Packages.Set_Item(("InstallPackage{0}" -f ($i + 1)), $newInstallPackages[$i])
            }

            Save $hstwb            
        }
    }
    until ($choice -eq 'Back')
}


# configure user packages menu
function ConfigureUserPackagesMenu($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure User Packages Menu" @("Change User Packages Dir", "Select User Packages Menu", "Back") 
        switch ($choice)
        {
            "Change User Packages Dir" { ChangeUserPackagesDir $hstwb }
            "Select User Packages Menu" { SelectUserPackagesMenu $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# change user packages dir
function ChangeUserPackagesDir($hstwb)
{
    $path = if (!$hstwb.Settings.UserPackages.UserPackagesDir) { ${Env:USERPROFILE} } else { $hstwb.Settings.UserPackages.UserPackagesDir }
    $newPath = FolderBrowserDialog "Select User Packages Directory" $path $false

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


# select user packages menu
function SelectUserPackagesMenu($hstwb)
{
    # get user packages
    $userPackageNames = $hstwb.UserPackages.keys | Sort-Object @{expression={$_};Ascending=$true}

    # get install packages
    $installUserPackages = @{}
    foreach($installUserPackageKey in ($hstwb.Settings.UserPackages.Keys | Where-Object { $_ -match 'InstallUserPackage\d+' }))
    {
        $installUserPackages.Set_Item($hstwb.Settings.UserPackages.Get_Item($installUserPackageKey.ToLower()), $true)
    }

    # build user package names maps
    $userPackageNamesFormattedMap = @{}
    $userPackageNamesMap = @{}
    foreach ($userPackageName in $userPackageNames)
    {
        $userPackage = $hstwb.UserPackages.Get_Item($userPackageName)

        $userPackageNamesFormattedMap.Set_Item($userPackage.Name, $userPackageName)
        $userPackageNamesMap.Set_Item($userPackageName, $userPackage.Name)
    }

    do
    {
        # build user package options
        $userPackageOptions = @('Select all', 'Deselect all')
        $userPackageOptions += $userPackageNames | ForEach-Object { if ($installUserPackages.ContainsKey($_)) { ("- " + $userPackageNamesMap.Get_Item($_)) } else { ("+ " + $userPackageNamesMap.Get_Item($_)) } }
        $userPackageOptions += "Back"

        $choice = Menu $hstwb "Select User Packages Menu" $userPackageOptions


        $addUserPackageNames = @()
        $removeUserPackageNames = @()
        
        if ($choice -eq 'Select all')
        {
            $addUserPackageNames += $hstwb.UserPackages.Keys
        }
        elseif ($choice -eq 'Deselect all')
        {
            $removeUserPackageNames += $installUserPackages.Keys
        }
        elseif ($choice -ne 'Back')
        {
            $userPackageNameFormatted = $choice -replace '^(\+|\-) ', ''
            $userPackageName = $userPackageNamesFormattedMap.Get_Item($userPackageNameFormatted)

            # remove user package, if user package exists in install userpackages. otherwise, add user package to install user packages
            if ($installUserPackages.ContainsKey($userPackageName))
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
                if ($installUserPackages.ContainsKey($userPackageName))
                {
                    continue
                }
    
                $installUserPackages.Set_Item($userPackageName, $true)
            }
        }

        if ($removeUserPackageNames.Count -gt 0)
        {
            foreach($userPackageName in $removeUserPackageNames)
            {
                if (!$installUserPackages.ContainsKey($userPackageName))
                {
                    continue
                }
    
                $installUserPackages.Remove($userPackageName)
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
            $newInstallUserPackages += $installUserPackages.keys | ForEach-Object { $userPackageNamesMap.Get_Item($_) } | Sort-Object @{expression={$_};Ascending=$true}

            # add install user packages to user packages
            for($i = 0; $i -lt $newInstallUserPackages.Count; $i++)
            {
                $hstwb.Settings.UserPackages.Set_Item(("InstallUserPackage{0}" -f ($i + 1)), $newInstallUserPackages[$i])
            }
            
            Save $hstwb
        }
    }
    until ($choice -eq 'Back')
}


# configure emulator menu
function ConfigureEmulatorMenu($hstwb)
{
    do
    {
        $choice = Menu $hstwb 'Configure Emulator Menu' @('Select Emulator Menu', 'Back')
        switch ($choice)
        {
            'Select Emulator Menu' { SelectEmulatorMenu $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# select emulator menu
function SelectEmulatorMenu($hstwb)
{
    $emulators = @{}
    $hstwb.Emulators | ForEach-Object { $emulators.Set_Item(('{0} ({1})' -f $_.Name,$_.File), $_.File ) }
    
    $toNatural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }
    
    $options = @()
    $options += $emulators.Keys | Sort-Object $toNatural
    $options += 'Custom, select emulator .exe file'
    $options += 'Back'
    
    $choice = Menu $hstwb "Select Emulator Menu" $options 

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
        $choice = Menu $hstwb "Configure Installer" @("Change Installer Mode", "Back") 
        switch ($choice)
        {
            "Change Installer Mode" { ChangeInstallerMode $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# change installer mode
function ChangeInstallerMode($hstwb)
{
    $choice = Menu $hstwb "Change Installer Mode" @("Install", "Build Self Install", "Build Package Installation", "Build User Package Installation", "Test")

    switch ($choice)
    {
        "Test" { $hstwb.Settings.Installer.Mode = "Test" }
        "Install" { $hstwb.Settings.Installer.Mode = "Install" }
        "Build Self Install" { $hstwb.Settings.Installer.Mode = "BuildSelfInstall" }
        "Build Package Installation" { $hstwb.Settings.Installer.Mode = "BuildPackageInstallation" }
        "Build User Package Installation" { $hstwb.Settings.Installer.Mode = "BuildUserPackageInstallation" }
    }

    Save $hstwb
}


# run installer
function RunInstaller($hstwb)
{
    Write-Host ""
    & $hstwb.Paths.RunFile -settingsDir $hstwb.Paths.SettingsDir
    Write-Host ""

    SetTitle($hstwb.Version)
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

    DefaultSettings $hstwb.Settings
    DefaultAssigns $hstwb.Assigns
    Save $hstwb
}


# resolve paths
$kickstartRomHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Kickstart\kickstart-rom-hashes.csv")
$workbenchAdfHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Workbench\workbench-adf-hashes.csv")
$imagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("images")
$packagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("packages")
$runFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("run.ps1")
$settingsDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($settingsDir)

$settingsFile = Join-Path $settingsDir -ChildPath "hstwb-installer-settings.ini"
$assignsFile = Join-Path $settingsDir -ChildPath "hstwb-installer-assigns.ini"

SetTitle HstwbInstallerVersion

try
{
    Write-Host "Starting HstWB Installer Setup..."

    # create settings dir, if it doesn't exist
    if(!(test-path -path $settingsDir))
    {
        mkdir $settingsDir | Out-Null
    }
    
    
    # create default settings, if settings file doesn't exist
    if (test-path -path $settingsFile)
    {
        $settings = ReadIniFile $settingsFile
    }
    else
    {
        $settings = @{}
        DefaultSettings $settings
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
            'KickstartRomHashesFile' = $kickstartRomHashesFile;
            'WorkbenchAdfHashesFile' = $workbenchAdfHashesFile;
            'ImagesPath' = $imagesPath;
            'PackagesPath' = $packagesPath;
            'SettingsFile' = $settingsFile;
            'AssignsFile' = $assignsFile;
            'RunFile' = $runFile;
            'SettingsDir' = $settingsDir
        };
        'Images' = ReadImages $imagesPath;
        'Packages' = ReadPackages $packagesPath;
        'Settings' = $settings;
        'Assigns' = $assigns
    }

    # read kickstart rom hashes
    if (Test-Path -Path $kickstartRomHashesFile)
    {
        $kickstartRomHashes = @()
        $kickstartRomHashes += (Import-Csv -Delimiter ';' $kickstartRomHashesFile)
        $hstwb.KickstartRomHashes = $kickstartRomHashes
    }
    else
    {
        throw ("Kickstart rom data file '{0}' doesn't exist" -f $kickstartRomHashesFile)
    }

    # read workbench adf hashes
    if (Test-Path -Path $workbenchAdfHashesFile)
    {
        $workbenchAdfHashes = @()
        $workbenchAdfHashes += (Import-Csv -Delimiter ';' $workbenchAdfHashesFile)
        $hstwb.WorkbenchAdfHashes = $workbenchAdfHashes
    }
    else
    {
        throw ("Workbench adf data file '{0}' doesn't exist" -f $workbenchAdfHashesFile)
    }

    # upgrade settings and assigns
    UpgradeSettings $hstwb
    UpgradeAssigns $hstwb
        
    # detect user packages
    $hstwb.UserPackages = DetectUserPackages $hstwb
    $hstwb.Emulators = FindEmulators
    
    # find workbench adfs
    FindWorkbenchAdfs $hstwb

    # find kickstart roms
    FindKickstartRoms $hstwb
        
    # update packages, user packages and assigns
    UpdatePackages $hstwb
    UpdateUserPackages $hstwb
    UpdateAssigns $hstwb

    # find best matching kickstart rom set, if kickstart rom set doesn't exist
    if (($hstwb.KickstartRomHashes | Where-Object { $_.Set -like $hstwb.Settings.Kickstart.KickstartRomSet }).Count -eq 0)
    {
        # set new kickstart rom set and save
        $hstwb.Settings.Kickstart.KickstartRomSet = FindBestMatchingKickstartRomSet $hstwb
    }

    # find best matching workbench adf set, if workbench adf set doesn't exist
    if (($hstwb.WorkbenchAdfHashes | Where-Object { $_.Set -eq $hstwb.Settings.Workbench.WorkbenchAdfSet }).Count -eq 0)
    {
        # set new workbench adf set and save
        $hstwb.Settings.Workbench.WorkbenchAdfSet = FindBestMatchingWorkbenchAdfSet $hstwb
    }
    
    # save settings and assigns
    Save $hstwb

    # show main menu
    MainMenu $hstwb
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