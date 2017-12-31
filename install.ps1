$currentDir = split-path -parent $MyInvocation.MyCommand.Definition
$hstwbInstallerIconFile = Join-Path $currentDir -ChildPath 'hstwb_installer.ico'

$objShell = New-Object -ComObject WScript.Shell

# install launcher.lnk shortcut
$launcherLinkFile = Join-Path $currentDir -ChildPath 'launcher.lnk'
$launcherLink = $objShell.CreateShortcut($launcherLinkFile)
$launcherLink.WorkingDirectory = $currentDir
$launcherLink.IconLocation = "{0},0" -f $hstwbInstallerIconFile
$launcherLink.Save()

# install setup.lnk shortcut
$setupLinkFile = Join-Path $currentDir -ChildPath 'setup.lnk'
$setupLink = $objShell.CreateShortcut($setupLinkFile)
$setupLink.WorkingDirectory = $currentDir
$setupLink.IconLocation = "{0},0" -f $hstwbInstallerIconFile
$setupLink.Save()

# install run.lnk shortcut
$runLinkFile = Join-Path $currentDir -ChildPath 'run.lnk'
$runLink = $objShell.CreateShortcut($runLinkFile)
$runLink.WorkingDirectory = $currentDir
$runLink.IconLocation = "{0},0" -f $hstwbInstallerIconFile
$runLink.Save()

# install fonts
$fonts = 0x14
$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace($fonts)
$systemFontsDir = $objFolder.Self.Path
$fontsDir = Join-Path $currentDir -ChildPath 'fonts'

Get-ChildItem -Path $fontsDir *.ttf | Where-Object { !(Test-Path (Join-Path $systemFontsDir -ChildPath $_.Name)) } | ForEach-Object { $objFolder.CopyHere($_.FullName) }