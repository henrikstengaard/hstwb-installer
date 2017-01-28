# HstWB Installer Setup
# ---------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-01-27
#
# A powershell script to setup HstWB Installer run for an Amiga HDF file installation.


Param(
	[Parameter(Mandatory=$true)]
	[string]$settingsDir
)


Import-Module (Resolve-Path('modules\HstwbInstaller-Config.psm1'))
Import-Module (Resolve-Path('modules\HstwbInstaller-Dialog.psm1'))
Import-Module (Resolve-Path('modules\HstwbInstaller-Data.psm1'))


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
        $choice = Menu "Main Menu" @("Select Image", "Configure Workbench", "Configure Kickstart", "Configure Packages", "Configure WinUAE", "Configure Installer", "Run Installer", "Reset", "Exit") 
        switch ($choice)
        {
            "Select Image" { SelectImageMenu }
            "Configure Workbench" { ConfigureWorkbenchMenu }
            "Configure Kickstart" { ConfigureKickstartMenu }
            "Configure Packages" { ConfigurePackagesMenu }
            "Configure WinUAE" { ConfigureWinuaeMenu }
            "Configure Installer" { ConfigureInstaller }
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
    $newImagePath = SaveFileDialog ("Save new " + $choice + " HDF image") $defaultHdfImageDir "HDF Files|*.hdf|All Files|*.*"

    # return, if new image path is null
    if ($newImagePath -eq $null)
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
    # build old install packages index
    $oldInstallPackages = @{}
    if ($settings.Packages.InstallPackages -and $settings.Packages.InstallPackages -ne '')
    {
        $settings.Packages.InstallPackages.ToLower() -split ',' | Where-Object { $_ } | ForEach-Object { $oldInstallPackages.Set_Item($_, $true) }
    }

    # build available and install packages indexes
    $availablePackages = @{}
    $installPackages = @{}

    foreach ($packageFileName in $packages.keys)
    {
        $package = $packages.Get_Item($packageFileName)
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

        $choice = Menu "Configure Packages Menu" $packageOptions

        if ($choice -ne 'Back')
        {
            $packageName = $choice -replace '^(\+|\-) ', ''

            # get package
            $package = $packages.Get_Item($availablePackages.Get_Item($packageName))

            # remove package and assigns, if package exists in install packages. otherwise, add package to install packages and package default assigns
            if ($installPackages.ContainsKey($packageName))
            {
                $installPackages.Remove($packageName)

                if ($assigns.ContainsKey($package.Package.Name))
                {
                    $assigns.Remove($package.Package.Name)
                }
            }
            else
            {
                $installPackages.Set_Item($packageName, $availablePackages.Get_Item($packageName))
                
                if ($package.DefaultAssigns)
                {
                    $assigns.Set_Item($package.Package.Name, $package.DefaultAssigns)
                }
            }
            
            # build and set new install packages
            $newInstallPackages = @()
            $newInstallPackages += $installPackages.keys | Sort-Object @{expression={$_};Ascending=$true} | ForEach-Object { $installPackages.Get_Item($_) }
            $settings.Packages.InstallPackages = $newInstallPackages -join ','
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


# configure installer
function ConfigureInstaller()
{
    do
    {
        $choice = Menu "Configure Installer" @("Change Installer Mode", "Back") 
        switch ($choice)
        {
            "Change Installer Mode" { ChangeInstallerMode }
        }
    }
    until ($choice -eq 'Back')
}


# change installer mode
function ChangeInstallerMode()
{
    $choice = Menu "Change Installer Mode" @("Install", "Self-Install", "Test") 

    $settings.Installer.Mode = $choice
    Save
}


# run installer
function RunInstaller
{
    Write-Host ""
	& $runFile -settingsDir $settingsDir
    Write-Host ""
}


# save
function Save()
{
    WriteIniFile $settingsFile $settings
    WriteIniFile $assignsFile $assigns
}


# reset
function Reset()
{
    DefaultSettings $settings
    DefaultAssigns $assigns
    Save
}


# resolve paths
$kickstartRomHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Kickstart\kickstart-rom-hashes.csv")
$workbenchAdfHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Workbench\workbench-adf-hashes.csv")
$imagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("images")
$packagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("packages")
$runFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("hstwb-installer-run.ps1")
$settingsDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($settingsDir)

$settingsFile = [System.IO.Path]::Combine($settingsDir, "hstwb-installer-settings.ini")
$assignsFile = [System.IO.Path]::Combine($settingsDir, "hstwb-installer-assigns.ini")


$packages = ReadPackages $packagesPath
$settings = @{}
$assigns = @{}


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
    DefaultSettings $settings
}


# create default assigns, if assigns file doesn't exist
if (test-path -path $assignsFile)
{
    $assigns = ReadIniFile $assignsFile
}
else
{
    DefaultAssigns $assigns
}


# set default installer mode, if not present
if (!$settings.Installer -or !$settings.Installer.Mode)
{
    $settings.Installer = @{}
    $settings.Installer.Mode = "Install"
}


# create packages section in settings, if it doesn't exist
if (!($settings.Packages))
{
    $settings.Packages = @{}
    $settings.Packages.InstallPackages = ''
}


# update packages
UpdatePackages $packages $settings


# update assigns
UpdateAssigns $packages $settings $assigns


# save settings and assigns
Save


# validate settings
if (!(ValidateSettings $settings))
{
    Write-Error "Validate settings failed"
    exit 1
}


# validate assigns
if (!(ValidateAssigns $assigns))
{
    Write-Error "Validate assigns failed"
    exit 1
}


# show main menu
MainMenu