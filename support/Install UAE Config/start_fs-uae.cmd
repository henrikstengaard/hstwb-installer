@ECHO OFF
:: Set FS-UAE exe
set FSUAEEXE=%LOCALAPPDATA%\fs-uae\fs-uae.exe

:: Start FS-UAE emulator with hstwb-installer.fs-uae configuration file, if FS-UAE exe exists
IF EXIST "%FSUAEEXE%" (
	"%FSUAEEXE%" "hstwb-installer.fs-uae"
) ELSE (
	echo "FS-UAE is not installed at '%FSUAEEXE%'"
)

pause