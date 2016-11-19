set WIXTOOLKITPATH=c:\Program Files (x86)\WiX Toolset v3.10\bin\

"%WIXTOOLKITPATH%\heat.exe" dir ..\images -o images.wxs -var var.ImagesDir -dr ImagesComponentDir -cg ImagesComponentGroup -sfrag -gg -g1
"%WIXTOOLKITPATH%\heat.exe" dir ..\kickstart -o kickstart.wxs -var var.KickstartDir -dr KickstartComponentDir -cg KickstartComponentGroup -sfrag -gg -g1
"%WIXTOOLKITPATH%\heat.exe" dir ..\licenses -o licenses.wxs -var var.LicensesDir -dr LicensesComponentDir -cg LicensesComponentGroup -sfrag -gg -g1
"%WIXTOOLKITPATH%\heat.exe" dir ..\packages -o packages.wxs -var var.PackagesDir -dr PackagesComponentDir -cg PackagesComponentGroup -sfrag -gg -g1
"%WIXTOOLKITPATH%\heat.exe" dir ..\winuae -o winuae.wxs -var var.WinuaeDir -dr WinuaeComponentDir -cg WinuaeComponentGroup -sfrag -gg -g1
"%WIXTOOLKITPATH%\heat.exe" dir ..\workbench -o workbench.wxs -var var.WorkbenchDir -dr WorkbenchComponentDir -cg WorkbenchComponentGroup -sfrag -gg -g1

"%WIXTOOLKITPATH%\candle.exe" hstwb-installer.wxs
"%WIXTOOLKITPATH%\candle.exe" -dImagesDir="..\images" images.wxs
"%WIXTOOLKITPATH%\candle.exe" -dKickstartDir="..\kickstart" kickstart.wxs
"%WIXTOOLKITPATH%\candle.exe" -dLicensesDir="..\licenses" licenses.wxs
"%WIXTOOLKITPATH%\candle.exe" -dPackagesDir="..\packages" packages.wxs
"%WIXTOOLKITPATH%\candle.exe" -dWinuaeDir="..\winuae" winuae.wxs
"%WIXTOOLKITPATH%\candle.exe" -dWorkbenchDir="..\workbench" workbench.wxs
::"%WIXTOOLKITPATH%\candle.exe" -dImagesDir="..\images" -dKickstartDir="..\kickstart" -dLicensesDir="..\licenses" -dPackagesDir="..\packages" -dWinuaeDir="..\winuae" -dWorkbenchDir="..\workbench" hstwb-installer.wxs images.wxs kickstart.wxs licenses.wxs packages.wxs winuae.wxs workbench.wxs
::"%WIXTOOLKITPATH%\light.exe" images.wixobj kickstart.wixobj licenses.wixobj packages.wixobj winuae.wixobj workbench.wixobj hstwb-installer.wixobj -o hstwb-installer.1.0.0.msi
"%WIXTOOLKITPATH%\light.exe" *.wixobj -o hstwb-installer.1.0.0.msi -ext WixUIExtension
::@pause