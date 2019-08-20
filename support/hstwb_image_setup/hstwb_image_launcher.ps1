# HstWB Image Launcher
# --------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-08-20
#
# A powershell script to launch HstWB images.

# the idea is to simplify installing (amigaos and kickstart from amiga forever), selection of emulator and configuration to start.
# store selections in a json file next to the image: hstwb_image_launcher.json
# this also has an indication if this is a self install image and if self install has been completed.
# maybe update hstwb installer to write a 'self_install_complete' file in amigaos, kickstart and userpackages.
# this can be detected by hstwb image launcher and suggest to remove these hard drives from the configuration

# windows version uses powershell and winforms
# macos and linux version uses python and tk. maybe detect of tk is possible and fallback to console.


Param(
	[Parameter(Mandatory=$false)]
    [string]$runDir
)


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function DetectEmulatorName($emulatorFile)
{
    if (!$emulatorFile -or !(Test-Path -Path $emulatorFile))
    {
        return $null
    }

    $version = (get-item $emulatorFile).VersionInfo.FileVersion

    if ($emulatorFile -match 'winuae64.exe$')
    {
        return 'WinUAE {0} 64-bit' -f $version
    }
    elseif ($emulatorFile -match 'winuae.exe$')
    {
        return 'WinUAE {0} 32-bit' -f $version
    }
    elseif ($emulatorFile -match 'fs-uae.exe$')
    {
        return 'FS-UAE {0}' -f $version
    }

    return $null
}

function FindEmulators()
{
    $emulators = @()
    
    $winuaeX64File = "${Env:ProgramFiles}\WinUAE\winuae64.exe"
    if (test-path -path $winuaeX64File)
    {
        $emulators += @{ 'Name' = (DetectEmulatorName $winuaeX64File); 'File' = $winuaeX64File }
    }
    
    $winuaeX86File = "${Env:ProgramFiles(x86)}\WinUAE\winuae.exe"
    if (test-path -path $winuaeX86File)
    {
        $emulators += @{ 'Name' = (DetectEmulatorName $winuaeX86File); 'File' = $winuaeX86File }
    }

    $cloantoWinuaeX64File = "${Env:ProgramFiles}\Cloanto\Amiga Forever\WinUAE\winuae64.exe"
    if (test-path -path $cloantoWinuaeX64File)
    {
        $emulators += @{ 'Name' = (DetectEmulatorName $cloantoWinuaeX64File); 'File' = $cloantoWinuaeX64File }
    }
    
    $cloantoWinuaeX86File = "${Env:ProgramFiles(x86)}\Cloanto\Amiga Forever\WinUAE\winuae.exe"
    if (test-path -path $cloantoWinuaeX86File)
    {
        $emulators += @{ 'Name' = (DetectEmulatorName $cloantoWinuaeX86File); 'File' = $cloantoWinuaeX86File }
    }
    
    # fs-uae 2.8.3
    $fsuaeFile = "${Env:LOCALAPPDATA}\fs-uae\fs-uae.exe"
    if (test-path -path $fsuaeFile)
    {
        $emulators += @{ 'Name' = (DetectEmulatorName $fsuaeFile); 'File' = $fsuaeFile }
    }

    # fs-uae 3.0.0
    $fsuaeFile = "${Env:LOCALAPPDATA}\fs-uae\FS-UAE\Windows\x86-64\fs-uae.exe"
    if (test-path -path $fsuaeFile)
    {
        $emulators += @{ 'Name' = (DetectEmulatorName $fsuaeFile); 'File' = $fsuaeFile }
    }

    return $emulators
}

function GuiMenu($title, $options)
{
    $hash = [hashtable]::Synchronized(@{}) 
    $hash.option = $null
    
    $buttonFont = New-Object System.Drawing.Font('Consolas',14)

    $blueColor = [System.Drawing.Color]::FromArgb(0, 85, 170)

    $width = 350;
    $height = 55 + ($options.Count * 70)

    $form = New-Object System.Windows.Forms.Form
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedSingle'
    $form.MinimizeBox = $false
    $form.MaximizeBox = $false
    $form.WindowState = 'Normal'
    $form.SizeGripStyle = 'Hide'

    # blank transparent icon
    $icon = New-Object System.Drawing.Bitmap 32, 32
    $icon.MakeTransparent()
    $form.Icon = [System.Drawing.Icon]::FromHandle($icon.GetHicon())

    $form.ClientSize = New-Object System.Drawing.Size ($width, $height)
    $form.BackColor = $blueColor
    $form.Text = ''

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.AutoSize = $false
    $titleLabel.TextAlign = 'MiddleCenter'
    $titleLabel.Location = New-Object System.Drawing.Point(2, 2)
    $titleLabel.Text = $title
    $titleLabel.Size = New-Object System.Drawing.Size ($width - 4), 50
    $titleLabel.Font = $buttonFont
    $titleLabel.ForeColor = 'White'
    $titleLabel.Anchor = 'Left', 'Top', 'Right'
    $form.Controls.Add($titleLabel)
    
    $positionY = 55

    foreach ($option in $options)
    {
        $button = New-Object System.Windows.Forms.Button
        $button.Location = New-Object System.Drawing.Point(20, $positionY)
        $button.Text = $option.Text
        $button.Size = New-Object System.Drawing.Size (($width - 40), 50)
        $button.Font = $buttonFont
        $button.ForeColor = $blueColor
        $button.BackColor = 'White'
        $button.Anchor = 'Left', 'Top', 'Right'

        $button.Add_Click({
            $form.Close()
            $hash.option = $option.Value
        }.GetNewClosure())
        $button.Add_GotFocus({
            $button.BackColor = [System.Drawing.Color]::FromArgb(210, 210, 210);
        }.GetNewClosure())
        $button.Add_LostFocus({
            $button.BackColor = 'White';
        }.GetNewClosure())

        $form.Controls.Add($button)

        $positionY += 70
    }

    [void]$form.ShowDialog()

    return $hash.option
}


# set run directory to current directory, if it's not defined
if (!$runDir)
{
    $runDir = '.'
}

# resolve paths
if ($runDir)
{
    $runDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($runDir)
}


# write hstwb image launcher title
Write-Output "--------------------"
Write-Output "HstWB Image Launcher"
Write-Output "--------------------"
Write-Output "Author: Henrik Noerfjand Stengaard"
Write-Output "Date: 2019-08-20"
Write-Output ""
Write-Output ("Run dir '{0}'" -f $runDir)

# fail, if run dir doesn't exist
if (!(Test-Path $runDir))
{
    throw ("Error: Run dir '{0}' doesn't exist" -f $runDir)
}




$mainMenuOptions = @()
$mainMenuOptions += @{ 'Text' = 'Install'; 'Value' = 'install' }
$mainMenuOptions += @{ 'Text' = 'Install'; 'Value' = 'install' }
$mainMenuOptions += @{ 'Text' = 'Select emulator'; 'Value' = 'select-emulator' }
$mainMenuOptions += @{ 'Text' = 'Select configuration'; 'Value' = 'select-configuration' }
$mainMenuOptions += @{ 'Text' = 'Run'; 'Value' = 'install' }
$mainMenuOptions += @{ 'Text' = 'Quit'; 'Value' = 'quit' }

# main menu
$emulatorOption = GuiMenu "HstWB Image Launcher" $mainMenuOptions


# 

$emulators = @()
$emulators += FindEmulators

# emulator options
$emulatorOptions = @()
$emulatorOptions += $emulators | ForEach-Object { @{ 'Text' = $_.Name; 'Value' = $_ } }
$emulatorOptions += @{ 'Text' = 'Other'; 'Value' = @{ 'Name' = '_other_' } }

# select emulator
$emulatorOption = GuiMenu "Select emulator" $emulatorOptions

$emulatorOption
$emulatorFile = $emulatorOption.File
$emulatorArgs = ''

if ($emulatorFile -match 'winuae(64)?\.exe$')
{
    # get uae config files from install directory
    $uaeConfigFiles = @()
    $uaeConfigFiles += Get-ChildItem $runDir | `
        Where-Object { !$_.PSIsContainer -and $_.Name -match '\.uae$' }

    if ($uaeConfigFiles.Count -eq 0)
    {
        Write-Host "No config files"
        exit 0
    }

    $configOptions = @()
    $configOptions += $uaeConfigFiles | ForEach-Object { @{ 'Text' = $_.Name; 'Value' = $_.FullName } }

    # select configuration
    $configOption = GuiMenu "Select configuration" $configOptions

    $emulatorArgs = '-f "{0}"' -f $configOption
}
elseif ($emulatorFile -match 'fs-uae.exe$')
{
    # get fs-uae config files from install directory
    $fsuaeConfigFiles = @()
    $fsuaeConfigFiles += Get-ChildItem $runDir | `
        Where-Object { !$_.PSIsContainer -and $_.Name -match '\.fs-uae$' }

    if ($fsuaeConfigFiles.Count -eq 0)
    {
        Write-Host "No config files"
        exit 0
    }

    $emulatorArgs = '"{0}"' -f $configOption
}


# start emulator
$emulatorProcess = Start-Process $emulatorFile $emulatorArgs -Wait -NoNewWindow

# fail, if emulator process doesn't return error code 0
if ($emulatorProcess -and $emulatorProcess.ExitCode -ne 0)
{
    Fail $hstwb ("Failed to run '" + $emulatorFile + "' with arguments '$emulatorArgs'")
}
