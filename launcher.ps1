# Launcher
# --------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2022-01-16
#
# A powershell script to launch HstWB Installer.


Param(
	[Parameter(Mandatory=$false)]
	[string]$settingsDir
)


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Import-Module (Resolve-Path('modules\version.psm1')) -Force


function MessageDialog($title, $message)
{
    $buttons = [System.Windows.Forms.MessageBoxButtons]::OK
    $icon = [System.Windows.Forms.MessageBoxIcon]::Information
    [void][System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icon)
}

# confirm dialog
function ConfirmDialog($title, $message)
{
    $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    $icon = [System.Windows.Forms.MessageBoxIcon]::Question
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icon)

    if($result -eq 'Yes')
    {
        return $true
    }

    return $false
}

function Run($runFile)
{
    Start-Process $runFile -Wait -WindowStyle Maximized
}

function Setup($setupFile)
{
    Start-Process $setupFile -Wait -WindowStyle Maximized
}

function Settings($settingsFile)
{
    Start-Process "Notepad.exe" "$settingsFile" -Wait -WindowStyle Maximized
}

function Assigns($assignsFile)
{
    Start-Process "Notepad.exe" "$assignsFile" -Wait -WindowStyle Maximized
}

function ShowReadme()
{
    $readmeDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('Readme')
    $readmeFile = Join-Path $readmeDir -ChildPath 'readme.html'

    if (Test-Path -Path $readmeFile)
    {
        Start-Process $readmeFile
    }
    else
    {
        Start-Process "https://github.com/henrikstengaard/hstwb-installer#hstwb-installer"
    }
}

function ShowSupportFiles()
{
    $supportDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('Support')
    Start-Process $supportDir
}

function ShowWebsite()
{
    Start-Process "https://hstwb.firstrealize.com/"
}

function ShowSourceCode()
{
    Start-Process "https://github.com/henrikstengaard/hstwb-installer"
}

function ReportAnIssue()
{
    Start-Process "https://github.com/henrikstengaard/hstwb-installer/issues"
}

function GuiMenu($title, $options)
{
    $hash = [hashtable]::Synchronized(@{}) 
    $hash.option = $null
    
    $privateFontCollection = New-Object System.Drawing.Text.PrivateFontCollection
    $privateFontCollection.AddFontFile($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('fonts\TopazPlus_a1200_v1.0.ttf'));

    $buttonFont = New-Object System.Drawing.Font($privateFontCollection.Families[0],14)

    $blueColor = [System.Drawing.Color]::FromArgb(0, 85, 170)

    $width = 350;
    $height = 100 + ($options.Count * 70)

    $form = New-Object System.Windows.Forms.Form
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = 'None'
    $form.MinimizeBox = $False
    $form.MaximizeBox = $False
    $form.WindowState = "Normal"
    $form.SizeGripStyle = "Hide"
    $form.Icon = New-Object System.Drawing.Icon ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('hstwb_installer.ico'))
    $form.ClientSize = New-Object System.Drawing.Size ($width, $height)
    $form.BackColor = $blueColor
    $form.Text = "HstWB Installer v{0}" -f (HstwbInstallerVersion)
    $form.Add_Paint({
        $graphics = $form.createGraphics()
        $blackBrush = new-object Drawing.SolidBrush 'Black'
        $rectangle = new-object Drawing.Rectangle 0, 0, $width, $height
        $graphics.FillRectangle($blackBrush, $rectangle)
        $blueBrush = new-object Drawing.SolidBrush $blueColor
        $rectangle = new-object Drawing.Rectangle 2, 2, ($width - 4), ($height - 4)
        $graphics.FillRectangle($blueBrush, $rectangle)
    })

    $captionLabel = New-Object System.Windows.Forms.Label
    $captionLabel.AutoSize = $false
    $captionLabel.TextAlign = 'MiddleCenter'
    $captionLabel.Size = New-Object System.Drawing.Size ($width - 4), 30
    $captionLabel.Location = New-Object System.Drawing.Point(2, 2)
    $captionLabel.Text = "HstWB Installer v{0}" -f (HstwbInstallerVersion)
    $captionLabel.Font = $buttonFont
    $captionLabel.ForeColor = $blueColor
    $captionLabel.BackColor = "White"
    $captionLabel.Anchor = "Left", "Top", "Right"
    $form.Controls.Add($captionLabel)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.AutoSize = $false
    $titleLabel.TextAlign = 'MiddleCenter'
    $titleLabel.Location = New-Object System.Drawing.Point(2, 40)
    $titleLabel.Text = $title
    $titleLabel.Size = New-Object System.Drawing.Size ($width - 4), 50
    $titleLabel.Font = $buttonFont
    $titleLabel.ForeColor = "White"
    $titleLabel.Anchor = "Left", "Top", "Right"
    $form.Controls.Add($titleLabel)
    
    $positionY = 100

    foreach ($option in $options)
    {
        $button = New-Object System.Windows.Forms.Button
        $button.Location = New-Object System.Drawing.Point(20, $positionY)
        $button.Text = $option
        $button.Size = New-Object System.Drawing.Size (($width - 40), 50)
        $button.Font = $buttonFont
        $button.ForeColor = $blueColor
        $button.BackColor = "White"
        $button.Anchor = "Left", "Top", "Right"

        $button.Add_Click({
            $form.Close()
            $hash.option = $option
        }.GetNewClosure())
        $button.Add_GotFocus({
            $button.BackColor = [System.Drawing.Color]::FromArgb(210, 210, 210);
        }.GetNewClosure())
        $button.Add_LostFocus({
            $button.BackColor = "White";
        }.GetNewClosure())

        $form.Controls.Add($button)

        $positionY += 70
    }

    [void]$form.ShowDialog()

    return $hash.option
}

function LauncherMenu($hstwb)
{
    do
    {
        $option = GuiMenu "Launcher" @('Setup', 'Advanced', 'Extra', 'Help', 'Exit')
        switch ($option)
        {
            "Setup" { Setup $hstwb.Paths.SetupFile }
            "Advanced" { AdvancedMenu $hstwb }
            "Extra" { ExtraMenu $hstwb }
            "Help" { HelpMenu $hstwb }
        }
    } while ($option -ne $null -and $option -ne 'Exit')    
}

function AdvancedMenu($hstwb)
{
    do
    {
        $option = GuiMenu "Advanced" @('Run', 'Settings', 'Assigns', 'Back')
        switch ($option)
        {
            "Run" { Run $hstwb.Paths.RunFile }
            "Settings" { Settings $hstwb.Paths.SettingsFile }
            "Assigns" { Assigns $hstwb.Paths.AssignsFile }
        }
    } while ($option -ne $null -and $option -ne 'Back')    
}

function ExtraMenu($hstwb)
{
    do
    {
        $option = GuiMenu "Extra" @('Support Files', 'Back')
        switch ($option)
        {
            'Support Files' { ShowSupportFiles }
        }
    } while ($option -ne $null -and $option -ne 'Back')    
}

function HelpMenu($hstwb)
{
    do
    {
        $option = GuiMenu "Help" @('View Readme', 'Show Website', 'Show Source Code', 'Report An Issue', 'Back')
        switch ($option)
        {
            'View Readme' { ShowReadme }
            'Show Website' { ShowWebsite }
            'Show Source Code' { ShowSourceCode }
            'Report An Issue' { ReportAnIssue }
        }
    } while ($option -ne $null -and $option -ne 'Back')    
}

if (!$settingsDir)
{
    $settingsDir = Join-Path $env:LOCALAPPDATA -ChildPath 'HstWB Installer'
}

$runFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('run.cmd')
$setupFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('setup.cmd')
$settingsFile = Join-Path $settingsDir -ChildPath 'hstwb-installer-settings.ini'
$assignsFile = Join-Path $settingsDir -ChildPath 'hstwb-installer-assigns.ini'
$host.ui.RawUI.WindowTitle = "HstWB Installer v{0}" -f (HstwbInstallerVersion)

try
{
    # hstwb
    $hstwb = @{
        'Paths' = @{
            'SettingsDir' = $settingsDir;
            'SetupFile' = $setupFile;
            'RunFile' = $runFile;
            'SettingsFile' = $settingsFile;
            'AssignsFile' = $assignsFile;
        };
    }

    # show launcher menu
    LauncherMenu $hstwb
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
    Write-Error "HstWB Installer Launcher Failed: $message"
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
}