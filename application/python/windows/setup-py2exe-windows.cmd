@echo off

:: Clean output
IF EXIST ".output" RMDIR /S /Q ".output"
MKDIR ".output"

:: Copy python scripts
copy "..\hstwb-installer.*" ".output"
copy "setup-py2exe-windows.py" ".output"
xcopy /s /i "..\ui" ".output\ui"

:: Run py2exe
cd ".output"
python setup-py2exe-windows.py py2exe
cd ".."