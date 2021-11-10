# HstWB Image Setup
# -----------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2021-08-06
#
# A python script to setup HstWB images with following installation steps:
#
# 1. Find Cloanto Amiga Forever data dir.
#    - Drives or mounted iso.
#    - Environment variable "AMIGAFOREVERDATA".
# 2. Detect if UAE or FS-UAE configuration files contains self install directories.
#    - Detect and install Amiga OS 3.1 adf and Kickstart rom files from Cloanto Amiga Forever data dir using MD5 hashes.
#    - Validate files in self install directories using MD5 hashes to indicate, if all files are present for self install.
# 3. Detect files for patching configuration files.
#    - Find A1200 Kickstart rom in kickstart dir.
#    - Find Amiga OS 3.9 iso file in amiga os dir.
# 4. Patch and install UAE and FS-UAE configuration files.
#    - For FS-UAE configuration files, .adf files from Workbench directory are added as swappable floppies.


"""HstWB Image Setup"""

import os
import stat
import hashlib
import re
import shutil
import sys
import subprocess


# md5 file
class Md5File:
    md5_hash = ""
    full_filename = ""
    priority = 0

# calculate md5 from file
def calculate_md5_from_file(_file):
    """Calculate md5 from file"""
    hash_md5 = hashlib.md5()
    with open(_file, "rb") as _f:
        for chunk in iter(lambda: _f.read(4096), b""):
            hash_md5.update(chunk)

    return hash_md5.hexdigest().lower()

# get md5 files from dir
def get_md5_files_from_dir(_dir):
    """Get md5 files from dir"""

    md5_files = []    

    files = [os.path.join(_dir, _f) for _f in os.listdir(_dir) \
        if os.path.isfile(os.path.join(_dir, _f))]

    for f in files:
        md5_file = Md5File()
        md5_file.md5_hash = calculate_md5_from_file(f)
        md5_file.full_filename = f
        md5_files.append(md5_file)
    
    return md5_files

# config file has self install dirs
def config_file_has_self_install_dirs(config_file):
    """Config file has self install dirs"""

    has_self_install_dirs = False
    with open(config_file,'rU') as _f:
        for line in _f:
            if re.search(r'^hard_drive_\d+_label\s*=\s*(amigaosdir|kickstartdir|userpackagesdir)', line, re.I) or \
                re.search(r'^(hardfile2|uaehf\d+|filesystem2)=.*[,:](amigaosdir|kickstartdir|userpackagesdir)[,:]', line, re.I):
                has_self_install_dirs = True
                break
    
    return has_self_install_dirs

# run command
def run_command(commands):
    """Run command"""

    # process to run commands
    process = subprocess.Popen(commands, bufsize=-1, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    # get stdout and stderr from process
    (stdout, stderr) = process.communicate()

    # return, if return code is not 0
    if process.returncode:
        return None
    
    return stdout

# find amiga forever data for from media windows
def find_amiga_forever_data_dir_from_media_windows():
    """Find Amiga Forever data dir from media Windows"""

    # run command fsutil to list drives
    output = run_command(['fsutil', 'fsinfo', 'drives'])

    if output == None:
        return None

    # parse volume dirs from output and find valid
    for line in output.split('\n'):
        # match drives
        drives_match = re.search(r'^[^:]+:\s*(.+)\s*$', line)
        if not drives_match:
            continue
        # get drives
        drives = drives_match.group(1).strip().split(' ')
        for drive in drives:
            # find valid amiga files from drive
            amiga_forever_data_dir = find_valid_amiga_files_dir(drive)

            # return, if amiga forever data dir is valid
            if amiga_forever_data_dir != None:
                return amiga_forever_data_dir

    return None

# find amiga forever data dir from media macos
def find_amiga_forever_data_dir_from_media_macos():
    """Find Amiga Forever data dir from media macOS"""

    # run command hdiutil to list mounted volumes
    output = run_command(['hdiutil', 'info'])

    if output == None:
        return None

    # parse volume dirs from output and find valid
    for line in output.split('\n'):
        columns = line.split('\t')
        if len(columns) < 3:
            continue
        # match volume dir from 3rd column
        volume_dir_match = re.search(r'^(/[^/]+/.+)\s*$', columns[2])
        if not volume_dir_match:
            continue
        # get volume dir
        volume_dir = volume_dir_match.group(1)

        # find valid amiga files from volume dir
        amiga_forever_data_dir = find_valid_amiga_files_dir(volume_dir)

        if amiga_forever_data_dir != None:
            return amiga_forever_data_dir
    
    return None

# find amiga forever data dir from media linux
def find_amiga_forever_data_dir_from_media_linux():
    """Find Amiga Forever data dir from media Linux"""

    # run command findmnt to list mounted isos
    output = run_command(['findmnt', '-t', 'iso9660'])

    if output == None:
        return None

    # parse volume dirs from output and find valid
    for line in output.split('\n'):
        # match target dir
        target_dir_match = re.search(r'^(/[^\s]+)', line)
        if not target_dir_match:
            continue
        # get target dir
        target_dir = target_dir_match.group(1)

        # find valid amiga files from target dir
        amiga_forever_data_dir = find_valid_amiga_files_dir(target_dir)

        if amiga_forever_data_dir != None:
            return amiga_forever_data_dir
    
    return None

# find valid amiga files dir
def find_valid_amiga_files_dir(_dir):
    """Find valid amiga files dir"""

    if not os.path.isdir(_dir):
        return None
    amiga_files_dirs = [f for f in os.listdir(_dir) if os.path.isdir(os.path.join(_dir, f))]
    for amiga_files_dir in amiga_files_dirs:
        if re.search(r'^amiga\sfiles$', amiga_files_dir, re.I):
            return os.path.join(_dir, amiga_files_dir)
    return None

# get fsuae dir
def get_fsuae_dir():
    """Get FS-UAE dir"""

    user_home_dir = os.path.expanduser('~')
    directories = [os.path.join(user_home_dir, _f) for _f in os.listdir(user_home_dir) \
        if os.path.isdir(os.path.join(user_home_dir, _f))]

    for directory in directories:
        fsuae_dir = os.path.join(directory, 'FS-UAE')
        fsuae_config_dir = os.path.join(fsuae_dir, 'Configurations')
        if os.path.isdir(fsuae_config_dir):
            return fsuae_dir

    return None

# get winuae config dir
def get_winuae_config_dir():
    """Get WinUAE config dir"""

    # run command reg query to find winuae configuration path
    output = run_command(['reg', 'query', 'HKCU\\Software\\Arabuusimiehet\\WinUAE', '/v', 'ConfigurationPath'])

    if output == None:
        return None

    # parse winuae config dir from output
    for line in output.split('\n'):
        # match configuration path
        configuration_path_match = re.search(r'^\s*ConfigurationPath\s*REG[^\s]*\s*(.+)s*', line)
        if not configuration_path_match:
            continue
        # get winuae config dir
        winuae_config_dir = configuration_path_match.group(1).strip()

        if winuae_config_dir != None:
            return winuae_config_dir
    
    return None

# read model from config file
def read_model_from_config_file( \
    config_file):
    """Read model from config file"""

    model = None

    # read lines from config file
    with open(config_file,'rU') as _f:
        for line in _f:
            # parse model, if line matches model
            model_match = re.search(r'^(;|#)\s+Model:\s+(A\d+)', line, re.I)
            if model_match:
                model = model_match.group(2)
                break
    
    return model

# patch uae config file
def patch_uae_config_file( \
    uae_config_file, \
    kickstart_file, \
    amiga_os_39_iso_file, \
    amiga_os_dir, \
    kickstart_dir, \
    userpackages_dir):
    """Patch UAE Config File"""

    # self install dirs index
    self_install_dirs_index = {
        "amigaosdir": amiga_os_dir,
        "kickstartdir": kickstart_dir,
        "userpackagesdir": userpackages_dir,
    }

    # get uae config dir
    uae_config_dir = os.path.dirname(uae_config_file)

    # read uae config file
    uae_config_lines = []
    with open(uae_config_file,'rU') as _f:
        for line in _f:
            # skip line, if it's empty
            if re.search(r'^\s*$', line):
                continue

            uae_config_lines.append(line)

    # patch uae config lines
    for i in range(0, len(uae_config_lines)):
        line = uae_config_lines[i]

        # patch cd image 0 file
        if re.search(r'^cdimage0\s*=', line, re.I):
            amiga_os_39_iso_file_formatted = ''
            if amiga_os_39_iso_file != None:
                amiga_os_39_iso_file_formatted = amiga_os_39_iso_file.replace('\\', '\\\\')
            line = 'cdimage0={0}\n'.format(
                re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), amiga_os_39_iso_file_formatted))

        # patch kickstart rom file
        if re.search(r'^kickstart_rom_file\s*=', line, re.I):
            kickstart_file_formatted = ''
            if kickstart_file != None:
                kickstart_file_formatted = kickstart_file.replace('\\', '\\\\')
            line = 'kickstart_rom_file={0}\n'.format(
                re.sub(r'[\\/]', os.sep.replace('\\', '\\\\'), kickstart_file_formatted))

        # patch hardfile2 path
        hardfile2_device_match = re.search(r'^hardfile2=[^,]*,([^:]*)', line, re.I)
        hardfile2_path_match = re.search(r'^hardfile2=[^,]*,[^:]*:([^,]+)', line, re.I)
        if hardfile2_device_match and hardfile2_path_match:
            hardfile_path = self_install_dirs_index.get(
                hardfile2_device_match.group(1).lower(),
                os.path.join(uae_config_dir, os.path.basename(hardfile2_path_match.group(1))))
            if hardfile_path == None or not os.path.exists(hardfile_path):
                print('WARNING: Hardfile path \'{0}\' doesn\'t exist'.format(hardfile_path))
            else:
                line = re.sub(r'^(hardfile2=[^,]*,[^,:]*:)[^,]+', 
                    '\\1{0}'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), hardfile_path.replace('\\', '\\\\'))), line, 0, re.I)

            hardfile2_file_system_path_match = re.search(r',([^,]*),uae$', line, re.I)
            if hardfile2_file_system_path_match and hardfile2_file_system_path_match.group(1) != '':
                hardfile2_file_system_path = os.path.join(uae_config_dir, os.path.basename(hardfile2_file_system_path_match.group(1)))
                if hardfile2_file_system_path == None or not os.path.exists(hardfile2_file_system_path):
                    print('WARNING: Hardfile2 filesystem path \'{0}\' doesn\'t exist'.format(hardfile2_file_system_path))
                else:
                    line = re.sub(r'^(.+[^,]*,)[^,]*(,uae)$', 
                        '\\1{0}\\2'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), hardfile2_file_system_path.replace('\\', '\\\\'))), line, 0, re.I)

        # patch uaehf path
        uaehf_device_match = re.search(r'^uaehf\d+=[^,]*,[^,]*,([^,:]*)', line, re.I)

        uaehf_is_dir = False
        if re.search(r'^uaehf\d+=dir', line, re.I):
            uaehf_is_dir = True
            uaehf_path_match = re.search(r'^uaehf\d+=[^,]*,[^,]*,[^,:]*:[^,:]*:"?([^,"]+)', line, re.I)
        else:
            uaehf_path_match = re.search(r'^uaehf\d+=[^,]*,[^,]*,[^,:]*:"?([^,"]+)', line, re.I)

        if uaehf_device_match and uaehf_path_match:
            uaehf_path = self_install_dirs_index.get(
                uaehf_device_match.group(1).lower(),
                os.path.join(uae_config_dir, os.path.basename(uaehf_path_match.group(1))))
            if uaehf_path == None or not os.path.exists(uaehf_path):
                print('WARNING: Uaehf path \'{0}\' doesn\'t exist'.format(uaehf_path))
            else:
                if uaehf_is_dir:
                    line = re.sub(r'^(uaehf\d+=[^,]*,[^,]*,[^,:]*:[^,:]*:"?)[^,"]+', 
                        '\\1{0}'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), uaehf_path.replace('\\', '\\\\'))), line, 0, re.I)
                else:
                    line = re.sub(r'^(uaehf\d+=[^,]*,[^,]*,[^,:]*:"?)[^,"]+', 
                        '\\1{0}'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), uaehf_path.replace('\\', '\\\\'))), line, 0, re.I)

            uaehf_file_system_path_match = re.search(r',([^,]*),uae$', line, re.I)
            if uaehf_file_system_path_match and uaehf_file_system_path_match.group(1) != '':
                uaehf_file_system_path = os.path.join(uae_config_dir, os.path.basename(uaehf_file_system_path_match.group(1)))
                if uaehf_file_system_path == None or not os.path.exists(uaehf_file_system_path):
                    print('WARNING: Uaehf filesystem path \'{0}\' doesn\'t exist'.format(uaehf_file_system_path))
                else:
                    line = re.sub(r'^(.+[^,]*,)[^,]*(,uae)$', 
                        '\\1{0}\\2'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), uaehf_file_system_path.replace('\\', '\\\\'))), line, 0, re.I)

        # patch filesystem2 path
        filesystem2_device_match = re.search(r'^filesystem2=[^,]*,[^,:]*:([^:]*)', line, re.I)
        filesystem2_path_match = re.search(r'^filesystem2=[^,]*,[^,:]*:[^:]*:([^,]+)', line, re.I)
        if filesystem2_device_match and filesystem2_path_match:
            filesystem2_path = self_install_dirs_index.get(
                filesystem2_device_match.group(1).lower(),
                os.path.join(uae_config_dir, os.path.basename(filesystem2_path_match.group(1))))
            if filesystem2_path == None or not os.path.exists(filesystem2_path):
                print('WARNING: Filesystem path \'{0}\' doesn\'t exist'.format(filesystem2_path))
            else:
                line = re.sub(r'^(filesystem2=[^,]*,[^,:]*:[^:]*:)[^,]+', 
                    '\\1{0}'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), filesystem2_path.replace('\\', '\\\\'))), line, 0, re.I)

        # update line, if it's changed
        if line != uae_config_lines[i]:
            uae_config_lines[i] = line

    # write uae config file without byte order mark
    with open(uae_config_file, 'w') as _f:
        _f.writelines(uae_config_lines)

# patch fs-uae config file
def patch_fsuae_config_file( \
    fsuae_config_file, \
    kickstart_file, \
    amiga_os_39_iso_file, \
    amiga_os_dir, \
    kickstart_dir, \
    userpackages_dir):
    """Patch FSUAE Config File"""

    # self install dirs index
    self_install_dirs_index = {
        "amigaosdir": amiga_os_dir,
        "kickstartdir": kickstart_dir,
        "userpackagesdir": userpackages_dir,
    }

    # get fs-uae config dir
    fsuae_config_dir = os.path.dirname(fsuae_config_file)

    # read fs-uae config file
    hard_drive_labels = {}
    fsuae_config_lines = []
    with open(fsuae_config_file,'rU') as _f:
        for line in _f:
            # skip line, if it's empty or contains floppy_image
            if re.search(r'^\s*$', line) or re.search(r'^floppy_image_\d+', line):
                continue

            # add hard drive label, if it matches
            hard_drive_match = re.match(
                r'^(hard_drive_\d+)_label\s*=\s*(.*)', line, re.M|re.I)
            if hard_drive_match:
                hard_drive_labels[hard_drive_match.group(1)] = hard_drive_match.group(2)
            fsuae_config_lines.append(line)

    # patch fs-uae config lines
    for i in range(0, len(fsuae_config_lines)):
        line = fsuae_config_lines[i]

        # patch cdrom drive 0
        if re.search(r'^cdrom_drive_0\s*=', line):
            amiga_os_39_iso_file_formatted = ''
            if amiga_os_39_iso_file != None:
                amiga_os_39_iso_file_formatted = amiga_os_39_iso_file.replace('\\', '/')
            line = 'cdrom_drive_0 = {0}\n'.format(
                amiga_os_39_iso_file_formatted)

        # patch logs dir
        if re.search(r'^logs_dir\s*=', line):
            line = 'logs_dir = {0}\n'.format(fsuae_config_dir.replace('\\', '/'))

        # patch kickstart file
        if re.search(r'^kickstart_file\s*=', line):
            kickstart_file_formatted = ''
            if kickstart_file != None:
                kickstart_file_formatted = kickstart_file.replace('\\', '/')
            line = 'kickstart_file = {0}\n'.format(
                kickstart_file_formatted)

        # patch hard drives
        hard_drive_match = re.match(
            r'^(hard_drive_\d+)\s*=\s*(.*)', line, re.M|re.I)
        if hard_drive_match:
            hard_drive_index = hard_drive_match.group(1)
            hard_drive_path = hard_drive_match.group(2)
            if hard_drive_index in hard_drive_labels:
                hard_drive_path = self_install_dirs_index.get(
                    hard_drive_labels[hard_drive_index].lower(),
                    os.path.join(
                        fsuae_config_dir, os.path.basename(hard_drive_path))).replace('\\', '/')
                if hard_drive_path == None or not os.path.exists(hard_drive_path):
                    print('WARNING: Harddrive path \'{0}\' doesn\'t exist'.format(hard_drive_path))
                else:
                    line = re.sub(
                        r'^(hard_drive_\d+\s*=\s*).*', \
                        '\\1{0}'.format(hard_drive_path), line)

        # patch hard drive file system path
        hard_drive_file_system_match = re.match(
            r'^hard_drive_\d+_file_system\s*=\s*(.*)', line, re.M|re.I)
        if hard_drive_file_system_match:
            hard_drive_file_system_path = os.path.join(
                fsuae_config_dir,
                os.path.basename(hard_drive_file_system_match.group(1))).replace('\\', '/')
            if hard_drive_file_system_path == None or not os.path.exists(hard_drive_file_system_path):
                print('WARNING: Hard drive file system path \'{0}\' doesn\'t exist'.format(hard_drive_file_system_path))
            else:
                line = re.sub(
                    r'^(^hard_drive_\d+_file_system\s*=\s*).*', \
                    '\\1{0}'.format(hard_drive_file_system_path), line)

        # update line, if it's changed
        if line != fsuae_config_lines[i]:
            fsuae_config_lines[i] = line

    # get adf files from amiga os dir
    adf_files = []
    if amiga_os_dir != None and os.path.isdir(amiga_os_dir):
        adf_files.extend([os.path.join(amiga_os_dir, _f) for _f in os.listdir(amiga_os_dir) \
            if os.path.isfile(os.path.join(amiga_os_dir, _f)) and _f.endswith(".adf")])

    # add adf files to fs-uae config lines as swappable floppies
    if len(adf_files) > 0:
        for i in range(0, len(adf_files)):
            fsuae_config_lines.append(
                'floppy_image_{0} = {1}\n'.format(i, adf_files[i].replace('\\', '/')))

    # write fs-uae config file without byte order mark
    with open(fsuae_config_file, 'w') as _f:
        _f.writelines(fsuae_config_lines)


# valid amiga os 3.1 md5 entries
valid_amiga_os_31_md5_entries = [
    { 'Md5': 'c1c673eba985e9ab0888c5762cfa3d8f', 'Filename': 'amiga-os-310-extras.adf', 'Name': 'Amiga OS 3.1 Extras Disk, Cloanto Amiga Forever 2016' },
    { 'Md5': '6fae8b94bde75497021a044bdbf51abc', 'Filename': 'amiga-os-310-fonts.adf', 'Name': 'Amiga OS 3.1 Fonts Disk, Cloanto Amiga Forever 2016' },
    { 'Md5': 'd6aa4537586bf3f2687f30f8d3099c99', 'Filename': 'amiga-os-310-install.adf', 'Name': 'Amiga OS 3.1 Install Disk, Cloanto Amiga Forever 2016' },
    { 'Md5': 'b53c9ff336e168643b10c4a9cfff4276', 'Filename': 'amiga-os-310-locale.adf', 'Name': 'Amiga OS 3.1 Locale Disk, Cloanto Amiga Forever 2016' },
    { 'Md5': '4fa1401aeb814d3ed138f93c54a5caef', 'Filename': 'amiga-os-310-storage.adf', 'Name': 'Amiga OS 3.1 Storage Disk, Cloanto Amiga Forever 2016' },
    { 'Md5': '590c42a69675d6970df350e200fe25dc', 'Filename': 'amiga-os-310-workbench.adf', 'Name': 'Amiga OS 3.1 Workbench Disk, Cloanto Amiga Forever 2016' },

    { 'Md5': 'c5be06daf40d4c3ace4eac874d9b48b1', 'Filename': 'amiga-os-310-install.adf', 'Name': 'Amiga OS 3.1 Install Disk, Cloanto Amiga Forever 7' },
    { 'Md5': 'e7b3a83df665a85e7ec27306a152b171', 'Filename': 'amiga-os-310-workbench.adf', 'Name': 'Amiga OS 3.1 Workbench Disk, Cloanto Amiga Forever 7' }
]

# valid amiga os 3.1.4 adf md5 entries
valid_amiga_os_314_md5_entries = [
    { 'Md5': '988ddad5106d5b846be57b711d878b4c', 'Filename': 'amiga-os-314-extras.adf', 'Name': 'Amiga OS 3.1.4 Extras Disk, Hyperion Entertainment' },
    { 'Md5': '27a7af42777a43a06f8d9d8e74226e56', 'Filename': 'amiga-os-314-fonts.adf', 'Name': 'Amiga OS 3.1.4 Fonts Disk, Hyperion Entertainment' },
    { 'Md5': '7e9b5ec9cf89d9aae771cd1b708792d9', 'Filename': 'amiga-os-314-install.adf', 'Name': 'Amiga OS 3.1.4 Install Disk, Hyperion Entertainment' },
    { 'Md5': '4007bfe06b5b51af981a3fa52c51f54a', 'Filename': 'amiga-os-314-locale.adf', 'Name': 'Amiga OS 3.1.4 Locale Disk, Hyperion Entertainment' },
    { 'Md5': '372215cd27888d65a95db92b6513e702', 'Filename': 'amiga-os-314-storage.adf', 'Name': 'Amiga OS 3.1.4 Storage Disk, Hyperion Entertainment' },
    { 'Md5': '05a7469fd903744aa5f53741765bf668', 'Filename': 'amiga-os-314-workbench.adf', 'Name': 'Amiga OS 3.1.4 Workbench Disk, Hyperion Entertainment' },
    { 'Md5': '8a3824e64dbe2c8327d5995188d5fdd3', 'Filename': 'amiga-os-314-modules-a500.adf', 'Name': 'Amiga OS 3.1.4 Modules A500 Disk, Hyperion Entertainment' },
    { 'Md5': '2065c8850b5ba97099c3ff2672221e3f', 'Filename': 'amiga-os-314-modules-a500.adf', 'Name': 'Amiga OS 3.1.4 Modules A500 Disk, Hyperion Entertainment' },
    { 'Md5': 'c5a96c56ee5a7e2ca639c755d89dda36', 'Filename': 'amiga-os-314-modules-a600.adf', 'Name': 'Amiga OS 3.1.4 Modules A600 Disk, Hyperion Entertainment' },
    { 'Md5': '4e095037af1da015c09ed26e3e107f50', 'Filename': 'amiga-os-314-modules-a600.adf', 'Name': 'Amiga OS 3.1.4 Modules A600 Disk, Hyperion Entertainment' },
    { 'Md5': 'bc48d0bdafd123a6ed459c38c7a1c2e4', 'Filename': 'amiga-os-314-modules-a600.adf', 'Name': 'Amiga OS 3.1.4 Modules A600 Disk, Hyperion Entertainment' },
    { 'Md5': 'b201f0b45c5748be103792e03f938027', 'Filename': 'amiga-os-314-modules-a2000.adf', 'Name': 'Amiga OS 3.1.4 Modules A2000 Disk, Hyperion Entertainment' },
    { 'Md5': 'b8d09ea3369ac538c3920c515ba76e86', 'Filename': 'amiga-os-314-modules-a2000.adf', 'Name': 'Amiga OS 3.1.4 Modules A2000 Disk, Hyperion Entertainment' },
    { 'Md5': '2797193dc7b7daa233abe1bcfee9d5a1', 'Filename': 'amiga-os-314-modules-a1200.adf', 'Name': 'Amiga OS 3.1.4 Modules A1200 Disk, Hyperion Entertainment' },
    { 'Md5': 'd170f8c11d1eb52f12643e0f13b44886', 'Filename': 'amiga-os-314-modules-a1200.adf', 'Name': 'Amiga OS 3.1.4 Modules A1200 Disk, Hyperion Entertainment' },
    { 'Md5': '60263124ea2c5f1831a3af639d085a28', 'Filename': 'amiga-os-314-modules-a3000.adf', 'Name': 'Amiga OS 3.1.4 Modules A3000 Disk, Hyperion Entertainment' },
    { 'Md5': 'd068cbc850390c3e0028879cc1cae4c2', 'Filename': 'amiga-os-314-modules-a3000.adf', 'Name': 'Amiga OS 3.1.4 Modules A3000 Disk, Hyperion Entertainment' },
    { 'Md5': '7d20dc438e802e41def3694d2be59f0f', 'Filename': 'amiga-os-314-modules-a4000d.adf', 'Name': 'Amiga OS 3.1.4 Modules A4000D Disk, Hyperion Entertainment' },
    { 'Md5': '68fb2ca4b81daeaf140d35dc7a63d143', 'Filename': 'amiga-os-314-modules-a4000t.adf', 'Name': 'Amiga OS 3.1.4 Modules A4000T Disk, Hyperion Entertainment' },
    { 'Md5': 'a0ed3065558bd43e80647c1c522322a0', 'Filename': 'amiga-os-314-modules-a4000t.adf', 'Name': 'Amiga OS 3.1.4 Modules A4000T Disk, Hyperion Entertainment' }
]

# valid amiga os 3.2 adf md5 entries
valid_amiga_os_32_md5_entries = [
    { 'Md5': '4f0c3383a10e62fdea5e5758a9238223', 'Filename': 'amiga-os-32-extras.adf', 'Name': 'Amiga OS 3.2 Extras Disk, Hyperion Entertainment' },
    { 'Md5': 'e03eb0505fb244aaf1c7486f6fe61ede', 'Filename': 'amiga-os-32-fonts.adf', 'Name': 'Amiga OS 3.2 Fonts Disk, Hyperion Entertainment' },
    { 'Md5': '71edc1249c013d60380d3db81fd87ae7', 'Filename': 'amiga-os-32-install.adf', 'Name': 'Amiga OS 3.2 Install Disk, Hyperion Entertainment' },
    { 'Md5': 'b697a03f0620b5e06947b5e9d7b16142', 'Filename': 'amiga-os-32-locale.adf', 'Name': 'Amiga OS 3.2 Locale Disk, Hyperion Entertainment' },
    { 'Md5': '3726fab6ec5cfc48f7c2368005964d90', 'Filename': 'amiga-os-32-storage.adf', 'Name': 'Amiga OS 3.2 Storage Disk, Hyperion Entertainment' },
    { 'Md5': '5edf0b7a10409ef992ea351565ef8b6c', 'Filename': 'amiga-os-32-workbench.adf', 'Name': 'Amiga OS 3.2 Workbench Disk, Hyperion Entertainment' },
    { 'Md5': '2236629e7c316ff907b7e0cb1ee0ad18', 'Filename': 'amiga-os-32-backdrops.adf', 'Name': 'Amiga OS 3.2 Backdrops Disk, Hyperion Entertainment' },
    { 'Md5': 'fd11e54b038d5f236248a941125065db', 'Filename': 'amiga-os-32-classes.adf', 'Name': 'Amiga OS 3.2 Classes Disk, Hyperion Entertainment' },
    { 'Md5': '497d0aa96229a0e7fd2c475163d7462a', 'Filename': 'amiga-os-32-disk-doctor.adf', 'Name': 'Amiga OS 3.2 Disk Doctor Disk, Hyperion Entertainment' },
    { 'Md5': '26ef4d09cf71b7fdbd9cc68f333b7373', 'Filename': 'amiga-os-32-glow-icons.adf', 'Name': 'Amiga OS 3.2 Glow Icons Disk, Hyperion Entertainment' },
    { 'Md5': '3d36568bce19234b84fe88aa9629f5bf', 'Filename': 'amiga-os-32-locale-de.adf', 'Name': 'Amiga OS 3.2 Locale DE Disk, Hyperion Entertainment' },
    { 'Md5': '3a80e4f6b0d2d95f727dc45f99068ad8', 'Filename': 'amiga-os-32-locale-dk.adf', 'Name': 'Amiga OS 3.2 Locale DK Disk, Hyperion Entertainment' },
    { 'Md5': '7170c0bc81b7daeee39552279dada58c', 'Filename': 'amiga-os-32-locale-en.adf', 'Name': 'Amiga OS 3.2 Locale EN Disk, Hyperion Entertainment' },
    { 'Md5': '5e2eb9acef8e7b062d103db3fd270a27', 'Filename': 'amiga-os-32-locale-es.adf', 'Name': 'Amiga OS 3.2 Locale ES Disk, Hyperion Entertainment' },
    { 'Md5': '9f65d321d92d72e17d1f744f47d16323', 'Filename': 'amiga-os-32-locale-fr.adf', 'Name': 'Amiga OS 3.2 Locale FR Disk, Hyperion Entertainment' },
    { 'Md5': 'f93f2cd799ad1356adf4db01e20218f1', 'Filename': 'amiga-os-32-locale-gr.adf', 'Name': 'Amiga OS 3.2 Locale GR Disk, Hyperion Entertainment' },
    { 'Md5': 'ad728c377ce3d7f4bd6adba8419a81ae', 'Filename': 'amiga-os-32-locale-it.adf', 'Name': 'Amiga OS 3.2 Locale IT Disk, Hyperion Entertainment' },
    { 'Md5': 'e7b7b5a6583fca0d302201a1cb0b2829', 'Filename': 'amiga-os-32-locale-nl.adf', 'Name': 'Amiga OS 3.2 Locale NL Disk, Hyperion Entertainment' },
    { 'Md5': '1a9b83a7385c1aab8094fc1d72123437', 'Filename': 'amiga-os-32-locale-no.adf', 'Name': 'Amiga OS 3.2 Locale NO Disk, Hyperion Entertainment' },
    { 'Md5': '1aaa138753cec33a55f48d869780b7c8', 'Filename': 'amiga-os-32-locale-pl.adf', 'Name': 'Amiga OS 3.2 Locale PL Disk, Hyperion Entertainment' },
    { 'Md5': '425bbeb03c74fb275d643644bdd1af9a', 'Filename': 'amiga-os-32-locale-pt.adf', 'Name': 'Amiga OS 3.2 Locale PT Disk, Hyperion Entertainment' },
    { 'Md5': 'c45409fca931fc1ce76f6713f27ccd00', 'Filename': 'amiga-os-32-locale-ru.adf', 'Name': 'Amiga OS 3.2 Locale RU Disk, Hyperion Entertainment' },
    { 'Md5': 'a588dbc1ee7bf43e0e79694e10e48669', 'Filename': 'amiga-os-32-locale-se.adf', 'Name': 'Amiga OS 3.2 Locale SE Disk, Hyperion Entertainment' },
    { 'Md5': '6f9a623611fd19e084f7be2106ecfd99', 'Filename': 'amiga-os-32-locale-tr.adf', 'Name': 'Amiga OS 3.2 Locale TR Disk, Hyperion Entertainment' },
    { 'Md5': '8d88812406cbf373cdb38148096972b9', 'Filename': 'amiga-os-32-locale-uk.adf', 'Name': 'Amiga OS 3.2 Locale UK Disk, Hyperion Entertainment' },
    { 'Md5': '66c46918b7005167f1b65e444d0b95f7', 'Filename': 'amiga-os-32-mmulibs.adf', 'Name': 'Amiga OS 3.2 MMULibs Disk, Hyperion Entertainment' },
    { 'Md5': '2d46a2856152256771883f212a4e462d', 'Filename': 'amiga-os-32-modules-a1200.adf', 'Name': 'Amiga OS 3.2 Modules A1200 Disk, Hyperion Entertainment' },
    { 'Md5': '9b18dea310bf073ef9cae2a120254d92', 'Filename': 'amiga-os-32-modules-a2000.adf', 'Name': 'Amiga OS 3.2 Modules A2000 Disk, Hyperion Entertainment' },
    { 'Md5': '99fdc21e434c2b2a988ba96b69d46389', 'Filename': 'amiga-os-32-modules-a3000.adf', 'Name': 'Amiga OS 3.2 Modules A3000 Disk, Hyperion Entertainment' },
    { 'Md5': '729ddf87056936d77ee8287f9ad090a7', 'Filename': 'amiga-os-32-modules-a4000d.adf', 'Name': 'Amiga OS 3.2 Modules A4000D Disk, Hyperion Entertainment' },
    { 'Md5': 'f8eddbca10560582b99a2f4555ad0620', 'Filename': 'amiga-os-32-modules-a4000t.adf', 'Name': 'Amiga OS 3.2 Modules A4000T Disk, Hyperion Entertainment' },
    { 'Md5': '2af6b84449996440211e9547660b10b6', 'Filename': 'amiga-os-32-modules-a500.adf', 'Name': 'Amiga OS 3.2 Modules A500 Disk, Hyperion Entertainment' },
    { 'Md5': 'c6474df1d52300a4993f13a394701697', 'Filename': 'amiga-os-32-modules-a600.adf', 'Name': 'Amiga OS 3.2 Modules A600 Disk, Hyperion Entertainment' },
    { 'Md5': '00b2c4d420c933894151c43dc3a24155', 'Filename': 'amiga-os-32-modules-cd32.adf', 'Name': 'Amiga OS 3.2 Modules CD32 Disk, Hyperion Entertainment' }
]

# valid kickstart md5 entries
valid_kickstart_md5_entries = [
    { 'Md5': 'cad62a102848e13bf04d8a3b0f8be6ab', 'Filename': 'kick.a1200.47.96', 'Encrypted': False, 'Name': 'Kickstart 3.2 47.96 A1200 Rom, Hyperion Entertainment', 'Model': 'A1200', 'ConfigSupported': True },
    { 'Md5': '1d9b6068abff5a44b4b2f1d5d3516dd9', 'Filename': 'kick.a500.47.96', 'Encrypted': False, 'Name': 'Kickstart 3.2 47.96 A500 Rom, Hyperion Entertainment', 'Model': 'A500', 'ConfigSupported': True },

    { 'Md5': '6de08cd5c5efd926d0a7643e8fb776fe', 'Filename': 'kick.a1200.46.143', 'Encrypted': False, 'Name': 'Kickstart 3.1.4 46.143 A1200 Rom, Hyperion Entertainment', 'Model': 'A1200', 'ConfigSupported': True },
    { 'Md5': '79bfe8876cd5abe397c50f60ea4306b9', 'Filename': 'kick.a1200.46.143', 'Encrypted': False, 'Name': 'Kickstart 3.1.4 46.143 A1200 Rom, Hyperion Entertainment', 'Model': 'A1200', 'ConfigSupported': True },

    { 'Md5': '7fe1eb0ba2b767659bf547bfb40d67c4', 'Filename': 'kick.a500.46.143', 'Encrypted': False, 'Name': 'Kickstart 3.1.4 46.143 A500-A600-A2000 Rom, Hyperion Entertainment', 'Model': 'A500', 'ConfigSupported': True },
    { 'Md5': '61c5b9931555b8937803505db868d5a8', 'Filename': 'kick.a500.46.143', 'Encrypted': False, 'Name': 'Kickstart 3.1.4 46.143 A500-A600-A2000 Rom, Hyperion Entertainment', 'Model': 'A500', 'ConfigSupported': True },

    { 'Md5': '151cce9d7aa9a36a835ec2f78853125b', 'Filename': 'kick40068.A4000', 'Encrypted': True, 'Name': 'Kickstart 3.1 40.068 A4000 Rom, Cloanto Amiga Forever 8', 'Model': 'A4000', 'ConfigSupported': False },
    { 'Md5': '43efffafb382528355bb4cdde9fa9ce7', 'Filename': 'kick40068.A1200', 'Encrypted': True, 'Name': 'Kickstart 3.1 40.068 A1200 Rom, Cloanto Amiga Forever 8', 'Model': 'A1200', 'ConfigSupported': True },
    { 'Md5': '85a45066a0aebf9ec5870591b6ddcc52', 'Filename': 'kick40063.A600', 'Encrypted': True, 'Name': 'Kickstart 3.1 40.063 A500-A600-A2000 Rom, Cloanto Amiga Forever 8', 'Model': 'A500', 'ConfigSupported': True },
    { 'Md5': '189fd22ec463a9375f2ea63045ed6315', 'Filename': 'kick34005.A500', 'Encrypted': True, 'Name': 'Kickstart 1.3 34.5 A500 Rom, Cloanto Amiga Forever 8', 'Model': 'A500', 'ConfigSupported': False },
    { 'Md5': 'd59262012424ee5ddc5aadab9cb57cad', 'Filename': 'kick33180.A500', 'Encrypted': True, 'Name': 'Kickstart 1.2 33.180 A500 Rom, Cloanto Amiga Forever 8', 'Model': 'A500', 'ConfigSupported': False },

    { 'Md5': '8b54c2c5786e9d856ce820476505367d', 'Filename': 'kick40068.A4000', 'Encrypted': True, 'Name': 'Kickstart 3.1 40.068 A4000 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A4000', 'ConfigSupported': False },
    { 'Md5': 'dc3f5e4698936da34186d596c53681ab', 'Filename': 'kick40068.A1200', 'Encrypted': True, 'Name': 'Kickstart 3.1 40.068 A1200 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A1200', 'ConfigSupported': True },
    { 'Md5': 'c3e114cd3b513dc0377a4f5d149e2dd9', 'Filename': 'kick40063.A600', 'Encrypted': True, 'Name': 'Kickstart 3.1 40.063 A500-A600-A2000 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A500', 'ConfigSupported': True },
    { 'Md5': '89160c06ef4f17094382fc09841557a6', 'Filename': 'kick34005.A500', 'Encrypted': True, 'Name': 'Kickstart 1.3 34.5 A500 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A500', 'ConfigSupported': False },
    { 'Md5': 'c56ca2a3c644d53e780a7e4dbdc6b699', 'Filename': 'kick33180.A500', 'Encrypted': True, 'Name': 'Kickstart 1.2 33.180 A500 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A500', 'ConfigSupported': False },

    { 'Md5': '9bdedde6a4f33555b4a270c8ca53297d', 'Filename': 'kick40068.A4000', 'Encrypted': False, 'Name': 'Kickstart 3.1 40.068 A4000 Rom, Dump of original Amiga Kickstart', 'Model': 'A4000', 'ConfigSupported': False },
    { 'Md5': '646773759326fbac3b2311fd8c8793ee', 'Filename': 'kick40068.A1200', 'Encrypted': False, 'Name': 'Kickstart 3.1 40.068 A1200 Rom, Dump of original Amiga Kickstart', 'Model': 'A1200', 'ConfigSupported': True },
    { 'Md5': 'e40a5dfb3d017ba8779faba30cbd1c8e', 'Filename': 'kick40063.A600', 'Encrypted': False, 'Name': 'Kickstart 3.1 40.063 A500-A600-A2000 Rom, Dump of original Amiga Kickstart', 'Model': 'A500', 'ConfigSupported': True },
    { 'Md5': '82a21c1890cae844b3df741f2762d48d', 'Filename': 'kick34005.A500', 'Encrypted': False, 'Name': 'Kickstart 1.3 34.5 A500 Rom, Dump of original Amiga Kickstart', 'Model': 'A500', 'ConfigSupported': False },
    { 'Md5': '85ad74194e87c08904327de1a9443b7a', 'Filename': 'kick33180.A500', 'Encrypted': False, 'Name': 'Kickstart 1.2 33.180 A500 Rom, Dump of original Amiga Kickstart', 'Model': 'A500', 'ConfigSupported': False }
]

# valid amiga os 3.9 md5 entries
valid_amiga_os_39_md5_entries = [
    { 'Md5': '3cb96e77d922a4f8eb696e525a240448', 'Filename': 'amigaos3.9.iso', 'Name': 'Amiga OS 3.9 iso', 'Size': 490856448 },
    { 'Md5': 'e32a107e68edfc9b28a2fe075e32e5f6', 'Filename': 'amigaos3.9.iso', 'Name': 'Amiga OS 3.9 iso', 'Size': 490686464 },
    { 'Md5': '71353d4aeb9af1f129545618d013a8c8', 'Filename': 'boingbag39-1.lha', 'Name': 'Boing Bag 1 for Amiga OS 3.9', 'Size': 5254174 },
    { 'Md5': 'fd45d24bb408203883a4c9a56e968e28', 'Filename': 'boingbag39-2.lha', 'Name': 'Boing Bag 2 for Amiga OS 3.9', 'Size': 2053444 }
]

# index valid amiga 3.2 md5 entries
valid_amiga_os_32_md5_index = {}
for entry in valid_amiga_os_32_md5_entries:
    entry['Priority'] = len(valid_amiga_os_32_md5_index) + 1
    valid_amiga_os_32_md5_index[entry['Md5'].lower()] = entry

# index valid amiga 3.1.4 md5 entries
valid_amiga_os_314_md5_index = {}
for entry in valid_amiga_os_314_md5_entries:
    entry['Priority'] = len(valid_amiga_os_314_md5_index) + 1
    valid_amiga_os_314_md5_index[entry['Md5'].lower()] = entry

# index valid amiga 3.1 md5 entries
valid_amiga_os_31_md5_index = {}
for entry in valid_amiga_os_31_md5_entries:
    entry['Priority'] = len(valid_amiga_os_31_md5_index) + 1
    valid_amiga_os_31_md5_index[entry['Md5'].lower()] = entry

# index valid kickstart rom md5 entries
valid_kickstart_md5_index = {}
for entry in valid_kickstart_md5_entries:
    entry['Priority'] = len(valid_kickstart_md5_index) + 1
    valid_kickstart_md5_index[entry['Md5'].lower()] = entry

# index valid os39 md5 entries
valid_amiga_os_39_md5_index = {}
valid_amiga_os_39_filename_index = {}
for entry in valid_amiga_os_39_md5_entries:
    entry['Priority'] = len(valid_amiga_os_39_md5_index) + 1
    valid_amiga_os_39_md5_index[entry['Md5'].lower()] = entry
    valid_amiga_os_39_filename_index[entry['Filename'].lower()] = entry

# arguments
install_dir = '.'
amiga_os_dir = None
kickstart_dir = None
user_packages_dir = None
amiga_forever_data_dir = None
uae_config_dir = None
fsuae_dir = None
patch_only = False
self_install = False

# get arguments
for i in range(0, len(sys.argv)):
    # install dir argument
    if (i + 1 < len(sys.argv) and re.search(r'--installdir', sys.argv[i])):
        install_dir = sys.argv[i + 1]
    # amiga os dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--amigaosdir', sys.argv[i])):
        amiga_os_dir = sys.argv[i + 1]
    # kickstart dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--kickstartdir', sys.argv[i])):
        kickstart_dir = sys.argv[i + 1]
    # user packages dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--userpackagesdir', sys.argv[i])):
        user_packages_dir = sys.argv[i + 1]
    # amiga forever data dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--amigaforeverdatadir', sys.argv[i])):
        amiga_forever_data_dir = sys.argv[i + 1]
    # uae config dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--uaeconfigdir', sys.argv[i])):
        uae_config_dir = sys.argv[i + 1]
    # fs-uae dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--fsuaedir', sys.argv[i])):
        fsuae_dir = sys.argv[i + 1]
    # patch only argument
    elif (re.search(r'--patchonly', sys.argv[i])):
        patch_only = True
    # self install argument
    elif (re.search(r'--selfinstall', sys.argv[i])):
        self_install = True

# print hstwb image setup title
print('-----------------')
print('HstWB Image Setup')
print('-----------------')
print('Author: Henrik Noerfjand Stengaard')
print('Date: 2021-08-06')
print('')
print('Install dir \'{0}\''.format(install_dir))

# fail, if install directory doesn't exist
if (install_dir != None and not os.path.isdir(install_dir)):
    print('Error: Install dir \'{0}\' doesn\'t exist'.format(install_dir))
    exit(1)

# set uae config directory to detected winuae config directory, if uae config directory is not defined and platform is win32
if uae_config_dir == None and sys.platform == "win32":
    uae_config_dir = get_winuae_config_dir()

# set fs-uae directory to detected fs-uae config directory, if fs-uae directory is not defined
if fsuae_dir == None:
    fsuae_dir = get_fsuae_dir()

# get uae config files from install directory
uae_config_files = [os.path.join(install_dir, n) for n in os.listdir(install_dir) \
    if os.path.isfile(os.path.join(install_dir, n)) and re.search(r'\.uae$', n, re.I)]

# get fs-uae config files from install directory
fsuae_config_files = [os.path.join(install_dir, n) for n in os.listdir(install_dir) \
    if os.path.isfile(os.path.join(install_dir, n)) and re.search(r'\.fs-uae$', n, re.I)]

# print uae and fs-uae configuration files
print('{0} UAE configuration file(s)'.format(len(uae_config_files)))
print('{0} FS-UAE configuration file(s)'.format(len(fsuae_config_files)))

# detect, if uae or fs-uae config files has self install directories
config_files_has_self_install_dirs = False
for uae_config_file in uae_config_files:
    if config_file_has_self_install_dirs(uae_config_file):
        config_files_has_self_install_dirs = True
        break
for fsuae_config_file in fsuae_config_files:
    if config_file_has_self_install_dirs(fsuae_config_file):
        config_files_has_self_install_dirs = True
        break

# set self install true, if patch only is not defined and config files has self install directories
if not patch_only and config_files_has_self_install_dirs:
    print('One or more configuration files contain self install dirs')
    self_install = True

# set default amiga os dir, if it's not defined
if amiga_os_dir == None:
    amiga_os_dir = os.path.join(install_dir, 'amigaos')

    # unset default amiga os dir, if it doesn't exist
    if not os.path.exists(amiga_os_dir):
        amiga_os_dir = None

# set default kickstart dir, if it's not defined
if kickstart_dir == None:
    kickstart_dir = os.path.join(install_dir, 'kickstart')

    # unset default kickstart_dir dir, if it doesn't exist
    if not os.path.exists(kickstart_dir):
        kickstart_dir = None

# set default user packages dir, if it's not defined
if user_packages_dir == None:
    user_packages_dir = os.path.join(install_dir, 'userpackages')

    # unset default user packages dir, if it doesn't exist
    if not os.path.exists(user_packages_dir):
        user_packages_dir = None


# autodetect amiga forever data dir, if it's not defined
if amiga_forever_data_dir == None:
    # find amiga forever data dir from media on platforms windows, macos and linux
    if sys.platform == "win32":
        amiga_forever_data_dir = find_amiga_forever_data_dir_from_media_windows()
    elif sys.platform == "darwin":    
        amiga_forever_data_dir = find_amiga_forever_data_dir_from_media_macos()
    elif sys.platform == "linux" or sys.platform == "linux2":
        amiga_forever_data_dir = find_amiga_forever_data_dir_from_media_linux()
    
    # get amiga forever data dir from environment variable, if no amiga forever data dir was detected from media
    if amiga_forever_data_dir == None and 'AMIGAFOREVERDATA' in os.environ and os.environ['AMIGAFOREVERDATA'] != None:
        amiga_forever_data_dir = os.environ['AMIGAFOREVERDATA']


# print install directories
if amiga_os_dir != None:
    print('Amiga OS dir \'{0}\''.format(amiga_os_dir))
if kickstart_dir != None:
    print('Kickstart dir \'{0}\''.format(kickstart_dir))
if user_packages_dir != None:
    print('User packages dir \'{0}\''.format(user_packages_dir))
if amiga_forever_data_dir != None:
    print('Amiga Forever data dir \'{0}\''.format(amiga_forever_data_dir))

# print amiga forever data dir, if it defined and exists
if amiga_forever_data_dir != None and os.path.isdir(amiga_forever_data_dir):
    # cloanto amiga forever
    print('')
    print('Cloanto Amiga Forever')
    print('---------------------')

    shared_dir = os.path.join(amiga_forever_data_dir, 'Shared')
    shared_adf_dir = os.path.join(shared_dir, 'adf')
    shared_rom_dir = os.path.join(shared_dir, 'rom')

    if self_install:
        print('Install Amiga OS 3.1 adf and Kickstart rom files from Amiga Forever data dir...')

        # install amiga os 3.1 adf rom files from cloanto amiga forever data directory, if shared adf directory exists
        if os.path.isdir(shared_adf_dir):
            # copy amiga os 3.1 adf files from shared adf dir that matches valid amiga os 3.1 md5
            installed_amiga_os_31_adf_filenames = []
            for md5_file in get_md5_files_from_dir(shared_adf_dir):
                if not md5_file.md5_hash in valid_amiga_os_31_md5_index:
                    continue
                amiga_os_31_adf_filename = os.path.basename(md5_file.full_filename)
                installed_amiga_os_31_adf_filenames.append(amiga_os_31_adf_filename)
                installed_amiga_os_31_adf_file = os.path.join(amiga_os_dir, amiga_os_31_adf_filename)
                shutil.copyfile(
                    md5_file.full_filename,
                    installed_amiga_os_31_adf_file)
                os.chmod(installed_amiga_os_31_adf_file, stat.S_IWRITE)

            # print installed amiga os 3.1 adf files
            print('- {0} Amiga OS 3.1 adf files installed \'{1}\''.format(
                len(installed_amiga_os_31_adf_filenames), 
                ', '.join(installed_amiga_os_31_adf_filenames)))
        else:
            print('- No Amiga Forever data shared adf dir detected')

        # install kickstart rom files from cloanto amiga forever data directory, if shared rom directory exists
        if os.path.isdir(shared_rom_dir):
            # copy kickstart rom files from shared rom dir that matches valid kickstart md5
            installed_kickstart_rom_filenames = []
            for md5_file in get_md5_files_from_dir(shared_rom_dir):
                if not md5_file.md5_hash in valid_kickstart_md5_index:
                    continue
                kickstart_rom_filename = os.path.basename(md5_file.full_filename)
                installed_kickstart_rom_filenames.append(kickstart_rom_filename)
                installed_kickstart_rom_file = os.path.join(kickstart_dir, kickstart_rom_filename)
                shutil.copyfile(
                    md5_file.full_filename,
                    installed_kickstart_rom_file)
                os.chmod(installed_kickstart_rom_file, stat.S_IWRITE)

            # copy amiga forever rom key file, if it exists
            rom_key_filename = 'rom.key'
            rom_key_file = os.path.join(shared_rom_dir, rom_key_filename)
            if os.path.isfile(rom_key_file):
                installed_kickstart_rom_filenames.append(rom_key_filename)
                installed_kickstart_rom_file = os.path.join(kickstart_dir, rom_key_filename)
                shutil.copyfile(
                    rom_key_file,
                    installed_kickstart_rom_file)
                os.chmod(installed_kickstart_rom_file, stat.S_IWRITE)

            # print installed kickstart rom files
            print('- {0} Kickstart rom files installed \'{1}\''.format(
                len(installed_kickstart_rom_filenames), 
                ', '.join(installed_kickstart_rom_filenames)))
        else:
            print('- No Amiga Forever data shared rom dir detected')
    else:
        print('Using Kickstart rom files from Amiga Forever data dir...')
        if kickstart_dir == None and os.path.isdir(shared_rom_dir):
            kickstart_dir = shared_rom_dir
            print('- Kickstart dir \'{0}\''.format(kickstart_dir))
        else:
            print('- No Amiga Forever data shared rom dir detected or Kickstart dir is already set')
    print('Done')


# print image directories
print('')
print('Image directories')
print('-----------------')

# print detecting amiga os
print('Detecting Amiga OS...')
print('- Amiga OS dir \'{0}\''.format(amiga_os_dir))

# get amiga os files from amiga os directory
amiga_os_md5_files = get_md5_files_from_dir(amiga_os_dir)

# amiga os 3.9 filenames detected
detected_amiga_os_39_filenames_index = {}
for md5_file in amiga_os_md5_files:
    os39_filename = os.path.basename(md5_file.full_filename)
    if not os39_filename.lower() in valid_amiga_os_39_filename_index:
        continue
    index_filename = valid_amiga_os_39_filename_index[os39_filename.lower()]['Filename'].lower()
    detected_amiga_os_39_filenames_index[index_filename] = md5_file
    detected_amiga_os_39_filenames_index[index_filename].priority = valid_amiga_os_39_filename_index[os39_filename.lower()]['Priority']
for md5_file in amiga_os_md5_files:
    if not md5_file.md5_hash in valid_amiga_os_39_md5_index:
        continue
    index_filename = valid_amiga_os_39_md5_index[md5_file.md5_hash]['Filename']
    detected_amiga_os_39_filenames_index[index_filename] = md5_file
    detected_amiga_os_39_filenames_index[index_filename].priority = valid_amiga_os_39_md5_index[md5_file.md5_hash]['Priority']

# amiga os 3.9 filenames
detected_amiga_os_39_filenames = list(detected_amiga_os_39_filenames_index.keys())
detected_amiga_os_39_filenames.sort()

# print detected amiga os 3.9 files
if len(detected_amiga_os_39_filenames) > 0:
    print('- {0} Amiga OS 3.9 files detected \'{1}\''.format(len(detected_amiga_os_39_filenames_index), ', '.join(detected_amiga_os_39_filenames)))
else:
    print('- No Amiga OS 3.9 files detected')


# detected amiga os 3.2 md5 index and filenames from workbench dir that matches valid amiga os 3.2 md5
detected_amiga_os_32_md5_index = {}
detected_amiga_os_32_filenames = []
for md5_file in amiga_os_md5_files:
    if not md5_file.md5_hash in valid_amiga_os_32_md5_index:
        continue
    detected_amiga_os_32_md5_index[valid_amiga_os_32_md5_index[md5_file.md5_hash]['Filename'].lower()] = \
        valid_amiga_os_32_md5_index[md5_file.md5_hash]
    detected_amiga_os_32_filenames.append(os.path.basename(md5_file.full_filename))
detected_amiga_os_32_filenames = list(set(detected_amiga_os_32_filenames))
detected_amiga_os_32_filenames.sort()

# print detected amiga os 3.2 adf files
if len(detected_amiga_os_32_filenames) > 0:
    print('- {0} Amiga OS 3.2 adf files detected \'{1}\''.format(
        len(detected_amiga_os_32_filenames), 
        ', '.join(detected_amiga_os_32_filenames)))
else:
    print('- No Amiga OS 3.2 adf files detected')


# detected amiga os 3.1.4 md5 index and filenames from workbench dir that matches valid amiga os 3.1.4 md5
detected_amiga_os_314_md5_index = {}
detected_amiga_os_314_filenames = []
for md5_file in amiga_os_md5_files:
    if not md5_file.md5_hash in valid_amiga_os_314_md5_index:
        continue
    detected_amiga_os_314_md5_index[valid_amiga_os_314_md5_index[md5_file.md5_hash]['Filename'].lower()] = \
        valid_amiga_os_314_md5_index[md5_file.md5_hash]
    detected_amiga_os_314_filenames.append(os.path.basename(md5_file.full_filename))
detected_amiga_os_314_filenames = list(set(detected_amiga_os_314_filenames))
detected_amiga_os_314_filenames.sort()

# print detected amiga os 3.1.4 adf files
if len(detected_amiga_os_314_filenames) > 0:
    print('- {0} Amiga OS 3.1.4 adf files detected \'{1}\''.format(
        len(detected_amiga_os_314_filenames), 
        ', '.join(detected_amiga_os_314_filenames)))
else:
    print('- No Amiga OS 3.1.4 adf files detected')


# detected amiga os 3.1 md5 index and filenames from workbench dir that matches valid amiga os 3.1 md5
detected_amiga_os_31_md5_index = {}
detected_amiga_os_31_filenames = []
for md5_file in amiga_os_md5_files:
    if not md5_file.md5_hash in valid_amiga_os_31_md5_index:
        continue
    detected_amiga_os_31_md5_index[valid_amiga_os_31_md5_index[md5_file.md5_hash]['Filename'].lower()] = \
        valid_amiga_os_31_md5_index[md5_file.md5_hash]
    detected_amiga_os_31_filenames.append(os.path.basename(md5_file.full_filename))
detected_amiga_os_31_filenames = list(set(detected_amiga_os_31_filenames))
detected_amiga_os_31_filenames.sort()

# print detected amiga os 3.1 adf files
if len(detected_amiga_os_31_filenames) > 0:
    print('- {0} Amiga OS 3.1 adf files detected \'{1}\''.format(
        len(detected_amiga_os_31_filenames), 
        ', '.join(detected_amiga_os_31_filenames)))
else:
    print('- No Amiga OS 3.1 adf files detected')


# print detecting kickstart roms
print('Detecting Kickstart roms...')
print('- Kickstart dir \'{0}\''.format(kickstart_dir))

# detected kickstart md5 index and filenames from kickstart dir that matches valid kickstart md5
detected_kickstart_md5_index = {}
detected_kickstart_filenames = []
for md5_file in get_md5_files_from_dir(kickstart_dir):
    kickstart_filename = os.path.basename(md5_file.full_filename)
    if re.search(r'^rom.key$', kickstart_filename, re.I):
        detected_kickstart_filenames.append(kickstart_filename)
        continue
    if not md5_file.md5_hash in valid_kickstart_md5_index:
        continue
    index_filename = valid_kickstart_md5_index[md5_file.md5_hash]['Filename'].lower()
    detected_kickstart_md5_index[index_filename] = \
        valid_kickstart_md5_index[md5_file.md5_hash]
    detected_kickstart_md5_index[index_filename]['File'] = md5_file.full_filename
    detected_kickstart_filenames.append(kickstart_filename)
detected_kickstart_filenames = list(set(detected_kickstart_filenames))
detected_kickstart_filenames.sort()

# print detected kickstart rom files
if len(detected_kickstart_filenames) > 0:
    print('- {0} Kickstart rom files detected \'{1}\''.format(
        len(detected_kickstart_filenames), 
        ', '.join(detected_kickstart_filenames)))
else:
    print('- No Kickstart rom files detected')


# print detecting user packages
print('Detecting User Packages...')
print('- User Packages dir \'{0}\''.format(user_packages_dir))

# get user package dirs
user_package_dirs = [n for n in os.listdir(user_packages_dir) \
    if os.path.isfile(os.path.join(os.path.join(user_packages_dir, n), '_installdir'))]

# print detected user packages
if len(user_package_dirs) > 0:
    print('- {0} user packages detected \'{1}\''.format(len(user_package_dirs), ', '.join(user_package_dirs)))
else:
    print('- No user packages detected')
print('Done')


# set amiga os 3.9 iso file, if uae or fs-uae config files are present
amiga_os_39_iso_file = None
if len(uae_config_files) > 0 or len(fsuae_config_files) > 0:

    amiga_os_39_entries = []
    for k, v in detected_amiga_os_39_filenames_index.items():
        if ((v.md5_hash.lower() in valid_amiga_os_39_md5_index and 
            re.search(
                r'amigaos3\.?9\.iso',
                valid_amiga_os_39_md5_index[v.md5_hash.lower()]['Filename'],
                re.I)) or
            re.search(r'(\\|//)?amigaos3\.?9\.iso$', v.full_filename, re.I)):
            amiga_os_39_entries.append(v)

    # sort amiga os39 entries by priority
    amiga_os_39_entries = sorted(amiga_os_39_entries, key=lambda entry: entry.priority)

    if len(amiga_os_39_entries) > 0:
        amiga_os_39_iso_file = amiga_os_39_entries[0].full_filename


# get full path for amiga os39 iso file, workbench, kickstart, os39 and user packages dir, if they are defined
if amiga_os_39_iso_file != None:
    amiga_os_39_iso_file = os.path.realpath(amiga_os_39_iso_file)
if amiga_os_dir != None:
    amiga_os_dir = os.path.realpath(amiga_os_dir)
if kickstart_dir != None:
    kickstart_dir = os.path.realpath(kickstart_dir)
if user_packages_dir != None:
    user_packages_dir = os.path.realpath(user_packages_dir)


# patch and install uae configuration files, if they are present
if len(uae_config_files) > 0:
    # print uae configuration
    print('')
    print('UAE configuration')
    print('-----------------')
    print('Patching and installing UAE configuration files...')

    # print uae config directory, if not patch only and uae config directory exists
    if not patch_only and uae_config_dir != None:
        print('- UAE config dir \'{0}\''.format(uae_config_dir))

    if amiga_os_39_iso_file != None:
        print('- Using Amiga OS 3.9 iso file \'{0}\''.format(amiga_os_39_iso_file))
    else:
        print('- No Amiga OS 3.9 iso file detected')

    print('- {0} UAE configuration files \'{1}\''.format(len(uae_config_files), ', '.join(uae_config_files)))
    for uae_config_file in uae_config_files:
        kickstart_file = None

        # read model from uae config file
        model = read_model_from_config_file(
            os.path.realpath(uae_config_file))

        # get kickstart file for model, if model is defined. otherwise set model to unknown
        if model:
            kickstart_entries = []
            for k, v in valid_kickstart_md5_index.items():
                if re.search(model, v['Model']) and v['ConfigSupported'] and 'File' in v:
                    kickstart_entries.append(v)

            # sort kickstart entries by priority
            kickstart_entries = sorted(kickstart_entries, key=lambda entry: entry['Priority'])

            # set kickstart file
            if len(kickstart_entries) > 0:
                kickstart_file = kickstart_entries[0]['File']
        else:
            model = 'unknown'

        if kickstart_file:
            print('- \'{0}\'. Using Kickstart file \'{1}\' for {2} model'.format(uae_config_file, kickstart_file, model))
            kickstart_file = os.path.realpath(kickstart_file)
        else:
            print('- \'{0}\'. No Kickstart file for {1} model in configuration file!'.format(uae_config_file, model))

        # patch uae config file
        patch_uae_config_file(
            os.path.realpath(uae_config_file),
            kickstart_file,
            amiga_os_39_iso_file,
            amiga_os_dir,
            kickstart_dir,
            user_packages_dir)
        
        # install uae config file in uae config directory, if not patch only and uae config directory is defined
        if not patch_only and uae_config_dir != None:
            shutil.copyfile(
                uae_config_file, 
                os.path.join(uae_config_dir, os.path.basename(uae_config_file)))

    print('Done')

# patch and install fs-uae configuration files, if they are present
if len(fsuae_config_files) > 0:
    # print fs-uae configuration
    print('')
    print('FS-UAE configuration')
    print('--------------------')
    print('Patching and installing FS-UAE configuration files...')

    # fs-uae config dir
    fsuae_config_dir = None

    # set and write fs-uae config directory, if not patch only and fs-uae dir exists
    if not patch_only and fsuae_dir != None:
        # fs-uae configuration directory
        fsuae_config_dir = os.path.join(fsuae_dir, 'Configurations')

        print('- FS-UAE config dir \'{0}\''.format(fsuae_dir))

        # create fs-uae configuration directory, if it doesn't exist
        if not os.path.exists(fsuae_config_dir):
            os.makedirs(fsuae_config_dir)

    if amiga_os_39_iso_file != None:
        print('- Using Amiga OS 3.9 iso file \'{0}\''.format(amiga_os_39_iso_file))
    else:
        print('- No Amiga OS 3.9 iso file detected')

    print('- {0} FS-UAE configuration files'.format(len(fsuae_config_files)))
    for fsuae_config_file in fsuae_config_files:
        kickstart_file = None

        # read model from fs-uae config file
        model = read_model_from_config_file(
            os.path.realpath(fsuae_config_file))

        # get kickstart file for model, if model is defined. otherwise set model to unknown
        if model:
            kickstart_entries = []
            for k, v in valid_kickstart_md5_index.items():
                if re.search(model, v['Model']) and v['ConfigSupported'] and 'File' in v:
                    kickstart_entries.append(v)

            # sort kickstart entries by priority
            kickstart_entries = sorted(kickstart_entries, key=lambda entry: entry['Priority'])

            # set kickstart file
            if len(kickstart_entries) > 0:
                kickstart_file = kickstart_entries[0]['File']
        else:
            model = 'unknown'

        if kickstart_file:
            print('- \'{0}\'. Using Kickstart file \'{1}\' for {2} model'.format(fsuae_config_file, kickstart_file, model))
            kickstart_file = os.path.realpath(kickstart_file)
        else:
            print('- \'{0}\'. No Kickstart file for {1} model!'.format(fsuae_config_file, model))

        # patch fs-uae config file
        patch_fsuae_config_file(
            os.path.realpath(fsuae_config_file),
            kickstart_file,
            amiga_os_39_iso_file,
            amiga_os_dir,
            kickstart_dir,
            user_packages_dir)

        # install fs-uae config file in fs-uae config directory, if not patch only and fs-uae config directory is defined
        if not patch_only and fsuae_config_dir != None:
            shutil.copyfile(
                fsuae_config_file, 
                os.path.join(fsuae_config_dir, os.path.basename(fsuae_config_file)))

    # install fs-uae hstwb installer theme
    hstwb_installer_fsuae_theme_dir = os.path.join(os.path.join(os.path.join(install_dir, 'fs-uae'), 'themes'), 'hstwb-installer')
    if not patch_only and fsuae_dir != None and os.path.exists(hstwb_installer_fsuae_theme_dir):
        # create hstwb installer fs-uae configuration directory, if it doesn't exist
        hstwb_installer_fsuae_theme_dir_installed = os.path.join(os.path.join(fsuae_dir, 'themes'), 'hstwb-installer')
        if not os.path.exists(hstwb_installer_fsuae_theme_dir_installed):
            os.makedirs(hstwb_installer_fsuae_theme_dir_installed)

        # copy hstwb installer fs-uae theme directory
        for filename in os.listdir(hstwb_installer_fsuae_theme_dir):
            source_file = os.path.join(hstwb_installer_fsuae_theme_dir, filename) 
            shutil.copyfile(
                source_file, 
                os.path.join(hstwb_installer_fsuae_theme_dir_installed, filename))

        print('- HstWB Installer FS-UAE theme installed')

    print('Done')
