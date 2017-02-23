
### Change EmulationStation to show .uae files as roms



Default Retro Pie credentials for Shell and Samba/Windows share access:
###
	Username: pi
	Password: raspberry

### Copy roms and configs files to Retro Pie using Windows Explorer:

Copy roms files with following steps:

1. Start HstWB Installer Support from start menu.
2. Enter "Retro Pie" and "roms" folder.
3. Press CTRL+A to select all files and press CTRL+C to copy them.
4. Enter "\\RETROPIE\roms\amiga" in Windows Explorer path field.
5. Type default Retro Pie credentials, if required.
6. Press CTRL+V to paste files.
7. Close Windows Explorer window.

Copy configs files with following steps:

1. Start HstWB Installer Support from start menu.
2. Enter "Retro Pie" and "configs" folder.
3. Press CTRL+A to select all files and press CTRL+C to copy them.
4. Enter "\\RETROPIE\configs\amiga" in Windows Explorer path field.
5. Type default Retro Pie credentials, if required.
6. Press CTRL+V to paste files.
7. Close Windows Explorer window.

### Method 1: Add UAE extensions using Retro Pie File-Manager

1. Enter Retro Pie menu in EmulationStation.
2. Start File-Manager.
3. Press CTRL+O to hide panels.
4. Type command "sudo bash /home/pi/RetroPie/roms/amiga/add_uae_extensions.sh" without quotes to run bash script.
5. Verify output: "UAE extensions successfully added to EmulationStation configuration."
6. Type command "sudo rm -f /home/pi/RetroPie/roms/amiga/add_uae_extensions.sh" without quotes to delete bash script.
7. Press F10 and enter to exit File-Manager.

### Method 2: Add UAE extensions using Putty

1. Start Putty.
2. Enter "retropie" in host name and click "Open".
3. Type default Retro Pie credentials to login.
4. Type command "sudo bash /home/pi/RetroPie/roms/amiga/add_uae_extensions.sh" without quotes.
5. Verify output: "UAE extensions successfully added to EmulationStation configuration."
6. Type command "sudo rm -f /home/pi/RetroPie/roms/amiga/add_uae_extensions.sh" without quotes to delete bash script.
7. Press CTRL+D to quit Putty.