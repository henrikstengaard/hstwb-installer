@echo off
:: Launch
:: ------
::
:: Author: Henrik Noerfjand Stengaard
:: Date:   2017-09-10
::
:: A Windows batch script to launch HstWB Installer.

:: variables
set TASK=%1
set SETTINGSDIR=%LOCALAPPDATA%\HstWB Installer

:: run first time script and goto setup, if it's first time hstwb installer is used
powershell -ExecutionPolicy Bypass -File first-time.ps1 -settingsDir "%SETTINGSDIR%"
IF %ERRORLEVEL% == 1 GOTO setup

:: goto task
IF "%TASK%" == "settings" GOTO settings
IF "%TASK%" == "assigns" GOTO assigns
IF "%TASK%" == "setup" GOTO setup
IF "%TASK%" == "run" GOTO run
GOTO end

:: edit settings
:settings
notepad "%SETTINGSDIR%\hstwb-installer-settings.ini"
GOTO END

:: edit assigns
:assigns
notepad "%SETTINGSDIR%\hstwb-installer-assigns.ini"
GOTO END

:: run hstwb installer setup script
:setup
powershell -ExecutionPolicy Bypass -File setup.ps1 -settingsDir "%SETTINGSDIR%"
GOTO END

:: run hstwb installer run script
:run
powershell -ExecutionPolicy Bypass -File run.ps1 -settingsDir "%SETTINGSDIR%"

:end