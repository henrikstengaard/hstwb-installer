# HstWB Installer Setup
# ---------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-09-18
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
function ConfirmDialog($title, $message)
{
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OKCancel)

    if($result -eq "OK")
    {
        return $true
    }

    return $false
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
        $choice = Menu $hstwb "Main Menu" @("Select Image", "Configure Workbench", "Configure Amiga OS 3.9", "Configure Kickstart", "Configure Packages", "Configure WinUAE", "Configure Installer", "Run Installer", "Reset", "Exit") 
        switch ($choice)
        {
            "Select Image" { SelectImageMenu $hstwb }
            "Configure Workbench" { ConfigureWorkbenchMenu $hstwb }
            "Configure Amiga OS 3.9" { ConfigureAmigaOS39Menu $hstwb }
            "Configure Kickstart" { ConfigureKickstartMenu $hstwb }
            "Configure Packages" { ConfigurePackagesMenu $hstwb }
            "Configure WinUAE" { ConfigureWinuaeMenu $hstwb }
            "Configure Installer" { ConfigureInstaller $hstwb }
            "Run Installer" { RunInstaller $hstwb }
            "Reset" { Reset $hstwb }
        }
    }
    until ($choice -eq 'Exit')
}


# select image menu
function SelectImageMenu($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Select Image Menu" @("Existing Image Directory", "Create Image Directory From Image Template", "Back") 
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
                    Start-Sleep -s 2
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
        $choice = Menu $hstwb "Configure Workbench Menu" @("Switch Install Workbench", "Change Workbench Adf Path", "Select Workbench Adf Set", "Back") 
        switch ($choice)
        {
            "Switch Install Workbench" { SwitchInstallWorkbench $hstwb }
            "Change Workbench Adf Path" { ChangeWorkbenchAdfPath $hstwb }
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


# change workbench adf path
function ChangeWorkbenchAdfPath($hstwb)
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

    $path = if (!$hstwb.Settings.Workbench.WorkbenchAdfPath) { $defaultWorkbenchAdfPath } else { $hstwb.Settings.Workbench.WorkbenchAdfPath }
    $newPath = FolderBrowserDialog "Select Workbench Adf Directory" $path $false

    if ($newPath -and $newPath -ne '')
    {
        $hstwb.Settings.Workbench.WorkbenchAdfPath = $newPath
        Save $hstwb
    }
}


# select workbench adf set
function SelectWorkbenchAdfSet($hstwb)
{
    # read workbench adf hashes
    $workbenchAdfHashes = @()
    $workbenchAdfHashes += (Import-Csv -Delimiter ';' $hstwb.Paths.WorkbenchAdfHashesFile)
    $workbenchNamePadding = ($workbenchAdfHashes | ForEach-Object { $_.Name } | Sort-Object @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

    # find files with hashes matching workbench adf hashes
    FindMatchingFileHashes $workbenchAdfHashes $hstwb.Settings.Workbench.WorkbenchAdfPath


    # find files with disk names matching workbench adf hashes
    FindMatchingWorkbenchAdfs $workbenchAdfHashes $hstwb.Settings.Workbench.WorkbenchAdfPath


    # get workbench rom sets
    $workbenchAdfSets = $workbenchAdfHashes | ForEach-Object { $_.Set } | Sort-Object | Get-Unique

    foreach($workbenchAdfSet in $workbenchAdfSets)
    {
        Write-Host ""
        Write-Host $workbenchAdfSet

        # get workbench adf set hashes
        $workbenchAdfSetHashes = $workbenchAdfHashes | Where-Object { $_.Set -eq $workbenchAdfSet }
        
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
        $choice = Menu $hstwb "Configure Kickstart Menu" @("Switch Install Kickstart", "Change Kickstart Rom Path", "Select Kickstart Rom Set", "Back") 
        switch ($choice)
        {
            "Switch Install Kickstart" { SwitchInstallKickstart $hstwb }
            "Change Kickstart Rom Path" { ChangeKickstartRomPath $hstwb }
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


# change kickstart rom path
function ChangeKickstartRomPath($hstwb)
{
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $defaultKickstartRomPath = Join-Path $amigaForeverDataPath -ChildPath "Shared\rom"
    }
    else
    {
        $defaultKickstartRomPath = ${Env:USERPROFILE}
    }

    $path = if (!$hstwb.Settings.Kickstart.KickstartRomPath) { $defaultKickstartRomPath } else { $hstwb.Settings.Kickstart.KickstartRomPath }
    $newPath = FolderBrowserDialog "Select Kickstart Rom Directory" $path $false

    if ($newPath -and $newPath -ne '')
    {
        $hstwb.Settings.Kickstart.KickstartRomPath = $newPath
        Save $hstwb
    }
}


# select kickstart rom path
function SelectKickstartRomSet($hstwb)
{
    # read kickstart rom hashes
    $kickstartRomHashes = @()
    $kickstartRomHashes += (Import-Csv -Delimiter ';' $hstwb.Paths.KickstartRomHashesFile)
    $kickstartNamePadding = ($kickstartRomHashes | ForEach-Object { $_.Name } | Sort-Object @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

    # find files with hashes matching kickstart rom hashes
    FindMatchingFileHashes $kickstartRomHashes $hstwb.Settings.Kickstart.KickstartRomPath

    # get kickstart rom sets
    $kickstartRomSets = $kickstartRomHashes | ForEach-Object { $_.Set } | Sort-Object | Get-Unique

    foreach($kickstartRomSet in $kickstartRomSets)
    {
        Write-Host ""
        Write-Host $kickstartRomSet

        # get kickstart rom set hashes
        $kickstartRomSetHashes = $kickstartRomHashes | Where-Object { $_.Set -eq $kickstartRomSet }
        
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


# configure packages menu
function ConfigurePackagesMenu($hstwb)
{
    # build old install packages index
    $oldInstallPackages = @{}
    if ($hstwb.Settings.Packages.InstallPackages -and $hstwb.Settings.Packages.InstallPackages -ne '')
    {
        $hstwb.Settings.Packages.InstallPackages.ToLower() -split ',' | Where-Object { $_ } | ForEach-Object { $oldInstallPackages.Set_Item($_, $true) }
    }

    # build available and install packages indexes
    $availablePackages = @{}
    $installPackages = @{}

    foreach ($packageFileName in $hstwb.Packages.keys)
    {
        $package = $hstwb.Packages.Get_Item($packageFileName)
        $packageName = $package.Package.Name + ' v' + $package.Package.Version

        $availablePackages.Set_Item($packageName, $packageFileName)

        if ($oldInstallPackages.ContainsKey($packageFileName))
        {
            $installPackages.Set_Item($packageName, $packageFileName)
        }
    }

    do
    {
        # build package options
        $packageOptions = @()
        $packageOptions += $availablePackages.keys | Sort-Object @{expression={$_};Ascending=$true} | ForEach-Object { if ($installPackages.ContainsKey($_)) { ("- " + $_) } else { ("+ " + $_) } }
        $packageOptions += "Back"

        $choice = Menu $hstwb "Configure Packages Menu" $packageOptions

        if ($choice -ne 'Back')
        {
            $packageName = $choice -replace '^(\+|\-) ', ''

            # get package
            $package = $hstwb.Packages.Get_Item($availablePackages.Get_Item($packageName))

            # remove package and assigns, if package exists in install packages. otherwise, add package to install packages and package default assigns
            if ($installPackages.ContainsKey($packageName))
            {
                $installPackages.Remove($packageName)

                if ($hstwb.Assigns.ContainsKey($package.Package.Name))
                {
                    $hstwb.Assigns.Remove($package.Package.Name)
                }
            }
            else
            {
                $installPackages.Set_Item($packageName, $availablePackages.Get_Item($packageName))
                
                if ($package.DefaultAssigns)
                {
                    $hstwb.Assigns.Set_Item($package.Package.Name, $package.DefaultAssigns)
                }
            }
            
            # build and set new install packages
            $newInstallPackages = @()
            $newInstallPackages += $installPackages.keys | Sort-Object @{expression={$_};Ascending=$true} | ForEach-Object { $installPackages.Get_Item($_) }
            $hstwb.Settings.Packages.InstallPackages = $newInstallPackages -join ','
            Save $hstwb
        }
    }
    until ($choice -eq 'Back')
}


# configure winuae menu
function ConfigureWinuaeMenu($hstwb)
{
    do
    {
        $choice = Menu $hstwb "Configure WinUAE Menu" @("Change WinUAE Path", "Back") 
        switch ($choice)
        {
            "Change WinUAE Path" { ChangeWinuaePath $hstwb }
        }
    }
    until ($choice -eq 'Back')
}


# change winuae path
function ChangeWinuaePath($hstwb)
{
    $path = if (!$hstwb.Settings.Winuae.WinuaePath) { ${Env:ProgramFiles(x86)} } else { [System.IO.Path]::GetDirectoryName($hstwb.Settings.Winuae.WinuaePath) }
    $newPath = OpenFileDialog "Select WinUAE.exe file" $path "Exe Files|*.exe|All Files|*.*"

    if ($newPath -and $newPath -ne '')
    {
        $hstwb.Settings.Winuae.WinuaePath = $newPath
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
    $choice = Menu $hstwb "Change Installer Mode" @("Install", "Build Self Install", "Build Package Installation", "Test") 

    switch ($choice)
    {
        "Test" { $hstwb.Settings.Installer.Mode = "Test" }
        "Install" { $hstwb.Settings.Installer.Mode = "Install" }
        "Build Self Install" { $hstwb.Settings.Installer.Mode = "BuildSelfInstall" }
        "Build Package Installation" { $hstwb.Settings.Installer.Mode = "BuildPackageInstallation" }
    }

    Save $hstwb
}


# run installer
function RunInstaller($hstwb)
{
    Write-Host ""
    & $hstwb.Paths.RunFile -settingsDir $hstwb.Paths.SettingsDir
    Write-Host ""
    if ($LastExitCode -ne 0)
    {
        Write-Host "Press enter to continue"
        Read-Host
    }
}


# save
function Save($hstwb)
{
    WriteIniFile $hstwb.Paths.SettingsFile $hstwb.Settings
    WriteIniFile $hstwb.Paths.AssignsFile $hstwb.Assigns
}


# reset
function Reset($hstwb)
{
    $confirm = ConfirmDialog "Reset" "Do you really want to reset settings?"
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
    'Settings' = @{};
    'Assigns' = @{}
}


# create settings dir, if it doesn't exist
if(!(test-path -path $hstwb.Paths.SettingsDir))
{
    mkdir $hstwb.Paths.SettingsDir | Out-Null
}


# create default settings, if settings file doesn't exist
if (test-path -path $hstwb.Paths.SettingsFile)
{
    $hstwb.Settings = ReadIniFile $hstwb.Paths.SettingsFile
}
else
{
    DefaultSettings $hstwb.Settings
}


# read assigns, if assigns file exist
if (test-path -path $hstwb.Paths.AssignsFile)
{
    $hstwb.Assigns = ReadIniFile $hstwb.Paths.AssignsFile
}

# create defailt assigns, if assigns is empty or doesn't contain global assigns
if ($hstwb.Assigns.Keys.Count -eq 0 -or !$hstwb.Assigns.ContainsKey('Global'))
{
    DefaultAssigns $hstwb.Assigns
}


# set default installer mode, if not present
if (!$hstwb.Settings.Installer -or !$hstwb.Settings.Installer.Mode)
{
    $hstwb.Settings.Installer = @{}
    $hstwb.Settings.Installer.Mode = "Install"
}


# create packages section in settings, if it doesn't exist
if (!($hstwb.Settings.Packages))
{
    $hstwb.Settings.Packages = @{}
    $hstwb.Settings.Packages.InstallPackages = ''
}


# create amiga os 3.9 section in settings, if it doesn't exist
if (!($hstwb.Settings.AmigaOS39))
{
    $hstwb.Settings.AmigaOS39 = @{}
    $hstwb.Settings.AmigaOS39.InstallAmigaOS39 = 'No'
    $hstwb.Settings.AmigaOS39.InstallBoingBags = 'No'
}


# set default image dir, if image dir doesn't exist
if ($hstwb.Settings.Image.ImageDir -match '^.+$' -and !(test-path -path $hstwb.Settings.Image.ImageDir))
{
    $hstwb.Settings.Image.ImageDir = ''
}



# update packages
UpdatePackages $hstwb.Packages $hstwb.Settings


# update assigns
UpdateAssigns $hstwb.Packages $hstwb.Settings $hstwb.Assigns


# save settings and assigns
Save $hstwb


# validate settings
if (!(ValidateSettings $hstwb.Settings))
{
    Write-Error "Validate settings failed"
    exit 1
}


# validate assigns
if (!(ValidateAssigns $hstwb.Assigns))
{
    Write-Error "Validate assigns failed"
    exit 1
}


# show main menu
MainMenu $hstwb