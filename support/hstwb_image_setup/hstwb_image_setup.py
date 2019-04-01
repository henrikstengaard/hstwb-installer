# HstWB Image Setup
# -----------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-04-01
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
    with open(config_file) as _f:
        for line in _f:
            if re.search(r'^hard_drive_\d+_label\s*=\s*(amigaosdir|kickstartdir|userpackagesdir)', line, re.I) or \
                re.search(r'^(hardfile2|uaehf\d+|filesystem2)=.+(amigaosdir|kickstartdir|userpackagesdir):', line, re.I):
                has_self_install_dirs = True
                break
    
    return has_self_install_dirs

# run command
def run_command(commands):
    """Run command"""

    # process to run commands
    process = subprocess.Popen(commands, bufsize=-1,
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
            amiga_forever_data_dir = find_valid_amiga_files_dir(unicode(drive, 'utf-8'))

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
        amiga_forever_data_dir = find_valid_amiga_files_dir(unicode(volume_dir, 'utf-8'))

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
        amiga_forever_data_dir = find_valid_amiga_files_dir(unicode(target_dir, 'utf-8'))

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
    with open(config_file) as _f:
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
    with open(uae_config_file) as _f:
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
            line = re.sub(r'^(hardfile2=[^,]*,[^,:]*:)[^,]+', 
                '\\1{0}'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), hardfile_path.replace('\\', '\\\\'))), line, 0, re.I)

        # patch uaehf path
        uaehf_device_match = re.search(r'^uaehf\d+=[^,]*,[^,]*,([^,:]*)', line, re.I)
        uaehf_path_match = re.search(r'^uaehf\d+=[^,]*,[^,]*,[^,:]*:"?([^,"]+)', line, re.I)
        if uaehf_device_match and uaehf_path_match:
            uaehf_path = self_install_dirs_index.get(
                uaehf_device_match.group(1).lower(),
                os.path.join(uae_config_dir, os.path.basename(uaehf_path_match.group(1))))
            line = re.sub(r'^(uaehf\d+=[^,]*,[^,]*,[^,:]*:"?)[^,"]+', 
                '\\1{0}'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), uaehf_path.replace('\\', '\\\\'))), line, 0, re.I)

        # patch filesystem2 path
        filesystem2_device_match = re.search(r'^filesystem2=[^,]*,[^,:]*:([^:]*)', line, re.I)
        filesystem2_path_match = re.search(r'^filesystem2=[^,]*,[^,:]*:[^:]*:([^,]+)', line, re.I)
        if filesystem2_device_match and filesystem2_path_match:
            filesystem2_path = self_install_dirs_index.get(
                filesystem2_device_match.group(1).lower(),
                os.path.join(uae_config_dir, os.path.basename(filesystem2_path_match.group(1))))
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
    with open(fsuae_config_file) as _f:
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
                line = re.sub(
                    r'^(hard_drive_\d+\s*=\s*).*', \
                    '\\1{0}'.format(hard_drive_path), line)

        # update line, if it's changed
        if line != fsuae_config_lines[i]:
            fsuae_config_lines[i] = line

    # get adf files from amiga os dir
    adf_files = []
    if amiga_os_dir != None and os.path.isdir(amiga_os_dir):
        adf_files.extend([os.path.join(amiga_os_dir, _f) for _f in os.listdir(unicode(amiga_os_dir, 'utf-8')) \
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
    { 'Md5': '8a3824e64dbe2c8327d5995188d5fdd3', 'Filename': 'amiga-os-314-modules-a500.adf', 'Name': 'Amiga OS 3.1.4 Modules A500 Disk, Hyperion Entertainment 1st release' },
    { 'Md5': '2065c8850b5ba97099c3ff2672221e3f', 'Filename': 'amiga-os-314-modules-a500.adf', 'Name': 'Amiga OS 3.1.4 Modules A500 Disk, Hyperion Entertainment 2nd release' },
    { 'Md5': 'c5a96c56ee5a7e2ca639c755d89dda36', 'Filename': 'amiga-os-314-modules-a600.adf', 'Name': 'Amiga OS 3.1.4 Modules A600 Disk, Hyperion Entertainment 1st release' },
    { 'Md5': '4e095037af1da015c09ed26e3e107f50', 'Filename': 'amiga-os-314-modules-a600.adf', 'Name': 'Amiga OS 3.1.4 Modules A600 Disk, Hyperion Entertainment 2nd release' },
    { 'Md5': 'b201f0b45c5748be103792e03f938027', 'Filename': 'amiga-os-314-modules-a2000.adf', 'Name': 'Amiga OS 3.1.4 Modules A2000 Disk, Hyperion Entertainment 1st release' },
    { 'Md5': 'b8d09ea3369ac538c3920c515ba76e86', 'Filename': 'amiga-os-314-modules-a2000.adf', 'Name': 'Amiga OS 3.1.4 Modules A2000 Disk, Hyperion Entertainment 2nd release' },
    { 'Md5': '2797193dc7b7daa233abe1bcfee9d5a1', 'Filename': 'amiga-os-314-modules-a1200.adf', 'Name': 'Amiga OS 3.1.4 Modules A1200 Disk, Hyperion Entertainment 1st release' },
    { 'Md5': 'd170f8c11d1eb52f12643e0f13b44886', 'Filename': 'amiga-os-314-modules-a1200.adf', 'Name': 'Amiga OS 3.1.4 Modules A1200 Disk, Hyperion Entertainment 2nd release' },
    { 'Md5': '60263124ea2c5f1831a3af639d085a28', 'Filename': 'amiga-os-314-modules-a3000.adf', 'Name': 'Amiga OS 3.1.4 Modules A3000 Disk, Hyperion Entertainment 1st release' },
    { 'Md5': '7d20dc438e802e41def3694d2be59f0f', 'Filename': 'amiga-os-314-modules-a4000d.adf', 'Name': 'Amiga OS 3.1.4 Modules A4000D Disk, Hyperion Entertainment 1st release' },
    { 'Md5': '68fb2ca4b81daeaf140d35dc7a63d143', 'Filename': 'amiga-os-314-modules-a4000t.adf', 'Name': 'Amiga OS 3.1.4 Modules A4000T Disk, Hyperion Entertainment 1st release' }
]

# valid kickstart md5 entries
valid_kickstart_md5_entries = [
    { 'Md5': '8b54c2c5786e9d856ce820476505367d', 'Filename': 'kick40068.A4000', 'Encrypted': True, 'Name': 'Kickstart 3.1 40.068 A4000 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A4000', 'ConfigSupported': False },
    { 'Md5': 'dc3f5e4698936da34186d596c53681ab', 'Filename': 'kick40068.A1200', 'Encrypted': True, 'Name': 'Kickstart 3.1 40.068 A1200 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A1200', 'ConfigSupported': True },
    { 'Md5': 'c3e114cd3b513dc0377a4f5d149e2dd9', 'Filename': 'kick40063.A600', 'Encrypted': True, 'Name': 'Kickstart 3.1 40.063 A500-A600-A2000 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A500', 'ConfigSupported': True },
    { 'Md5': '89160c06ef4f17094382fc09841557a6', 'Filename': 'kick34005.A500', 'Encrypted': True, 'Name': 'Kickstart 1.3 34.5 A500 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A500', 'ConfigSupported': False },
    { 'Md5': 'c56ca2a3c644d53e780a7e4dbdc6b699', 'Filename': 'kick33180.A500', 'Encrypted': True, 'Name': 'Kickstart 1.2 33.180 A500 Rom, Cloanto Amiga Forever 7/2016', 'Model': 'A500', 'ConfigSupported': False },

    { 'Md5': '9bdedde6a4f33555b4a270c8ca53297d', 'Filename': 'kick40068.A4000', 'Encrypted': False, 'Name': 'Kickstart 3.1 40.068 A4000 Rom, Dump of original Amiga Kickstart', 'Model': 'A4000', 'ConfigSupported': False },
    { 'Md5': '646773759326fbac3b2311fd8c8793ee', 'Filename': 'kick40068.A1200', 'Encrypted': False, 'Name': 'Kickstart 3.1 40.068 A1200 Rom, Dump of original Amiga Kickstart', 'Model': 'A1200', 'ConfigSupported': True },
    { 'Md5': 'e40a5dfb3d017ba8779faba30cbd1c8e', 'Filename': 'kick40063.A600', 'Encrypted': False, 'Name': 'Kickstart 3.1 40.063 A500-A600-A2000 Rom, Dump of original Amiga Kickstart', 'Model': 'A500', 'ConfigSupported': True },
    { 'Md5': '82a21c1890cae844b3df741f2762d48d', 'Filename': 'kick34005.A500', 'Encrypted': False, 'Name': 'Kickstart 1.3 34.5 A500 Rom, Dump of original Amiga Kickstart', 'Model': 'A500', 'ConfigSupported': False },
    { 'Md5': '85ad74194e87c08904327de1a9443b7a', 'Filename': 'kick33180.A500', 'Encrypted': False, 'Name': 'Kickstart 1.2 33.180 A500 Rom, Dump of original Amiga Kickstart', 'Model': 'A500', 'ConfigSupported': False },

    { 'Md5': '6de08cd5c5efd926d0a7643e8fb776fe', 'Filename': 'kick.a1200.46.143', 'Encrypted': False, 'Name': 'Kickstart 3.1.4 46.143 A1200 Rom, Hyperion Entertainment 1st release', 'Model': 'A1200', 'ConfigSupported': True },
    { 'Md5': '79bfe8876cd5abe397c50f60ea4306b9', 'Filename': 'kick.a1200.46.143', 'Encrypted': False, 'Name': 'Kickstart 3.1.4 46.143 A1200 Rom, Hyperion Entertainment 2nd release', 'Model': 'A1200', 'ConfigSupported': True },

    { 'Md5': '7fe1eb0ba2b767659bf547bfb40d67c4', 'Filename': 'kick.a500.46.143', 'Encrypted': False, 'Name': 'Kickstart 3.1.4 46.143 A500-A600-A2000 Rom, Hyperion Entertainment 1st release', 'Model': 'A500', 'ConfigSupported': True },
    { 'Md5': '61c5b9931555b8937803505db868d5a8', 'Filename': 'kick.a500.46.143', 'Encrypted': False, 'Name': 'Kickstart 3.1.4 46.143 A500-A600-A2000 Rom, Hyperion Entertainment 2nd release', 'Model': 'A500', 'ConfigSupported': True }
]

# valid amiga os 3.9 md5 entries
valid_amiga_os_39_md5_entries = [
    { 'Md5': '3cb96e77d922a4f8eb696e525a240448', 'Filename': 'amigaos3.9.iso', 'Name': 'Amiga OS 3.9 iso', 'Size': 490856448 },
    { 'Md5': 'e32a107e68edfc9b28a2fe075e32e5f6', 'Filename': 'amigaos3.9.iso', 'Name': 'Amiga OS 3.9 iso', 'Size': 490686464 },
    { 'Md5': '71353d4aeb9af1f129545618d013a8c8', 'Filename': 'boingbag39-1.lha', 'Name': 'Boing Bag 1 for Amiga OS 3.9', 'Size': 5254174 },
    { 'Md5': 'fd45d24bb408203883a4c9a56e968e28', 'Filename': 'boingbag39-2.lha', 'Name': 'Boing Bag 2 for Amiga OS 3.9', 'Size': 2053444 }
]

# index valid amiga 3.1.4 md5 entries
valid_amiga_os_314_md5_index = {}
for entry in valid_amiga_os_314_md5_entries:
    valid_amiga_os_314_md5_index[entry['Md5'].lower()] = entry

# index valid amiga 3.1 md5 entries
valid_amiga_os_31_md5_index = {}
for entry in valid_amiga_os_31_md5_entries:
    valid_amiga_os_31_md5_index[entry['Md5'].lower()] = entry

# index valid kickstart rom md5 entries
valid_kickstart_md5_index = {}
for entry in valid_kickstart_md5_entries:
    valid_kickstart_md5_index[entry['Md5'].lower()] = entry

# index valid os39 md5 entries
valid_amiga_os_39_md5_index = {}
valid_amiga_os_39_filename_index = {}
for entry in valid_amiga_os_39_md5_entries:
    valid_amiga_os_39_md5_index[entry['Md5'].lower()] = entry
    valid_amiga_os_39_filename_index[entry['Filename'].lower()] = entry

# arguments
install_dir = '.'
amiga_os_dir = None
kickstart_dir = None
user_packages_dir = None
amiga_forever_data_dir = None
uae_install_dir = None
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
    # uae install dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--uaeinstalldir', sys.argv[i])):
        uae_install_dir = sys.argv[i + 1]
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
print '-----------------'
print 'HstWB Image Setup'
print '-----------------'
print 'Author: Henrik Noerfjand Stengaard'
print 'Date: 2019-04-01'
print ''
print 'Install dir \'{0}\''.format(install_dir)

# fail, if install directory doesn't exist
if (install_dir != None and not os.path.isdir(install_dir)):
    print 'Error: Install dir \'{0}\' doesn\'t exist'.format(install_dir)
    exit(1)

# set uae install directory to detected winuae config directory, if uae install directory is not defined and platform is win32
if uae_install_dir == None and sys.platform == "win32":
    uae_install_dir = get_winuae_config_dir()

# set fs-uae directory to detected fs-uae config directory, if fs-uae directory is not defined
if fsuae_dir == None:
    fsuae_dir = get_fsuae_dir()

# get uae config files from install directory
uae_config_files = [os.path.join(install_dir, n) for n in os.listdir(unicode(install_dir, 'utf-8')) \
    if os.path.isfile(os.path.join(install_dir, n)) and re.search(r'\.uae$', n, re.I)]

# get fs-uae config files from install directory
fsuae_config_files = [os.path.join(install_dir, n) for n in os.listdir(unicode(install_dir, 'utf-8')) \
    if os.path.isfile(os.path.join(install_dir, n)) and re.search(r'\.fs-uae$', n, re.I)]

# print uae and fs-uae configuration files
print '{0} UAE configuration file(s)'.format(len(uae_config_files))
print '{0} FS-UAE configuration file(s)'.format(len(fsuae_config_files))

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
    self_install = True

# set install directories, if self install is true
if self_install:
    amiga_os_dir = os.path.join(install_dir, 'amigaos')
    kickstart_dir = os.path.join(install_dir, 'kickstart')
    user_packages_dir = os.path.join(install_dir, 'userpackages')

    # create install directories, if they don't exist
    for d in [amiga_os_dir, kickstart_dir, user_packages_dir]:
        if not os.path.exists(d):
            os.makedirs(d)

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

    # set kickstart dir to amiga forever data dir, if self install is false and amiga forever data shared rom dir exists
    if not self_install and amiga_forever_data_dir != None:
        shared_dir = os.path.join(amiga_forever_data_dir, 'Shared')
        shared_rom_dir = os.path.join(shared_dir, 'rom')
        if kickstart_dir == None and os.path.isdir(shared_rom_dir):
            kickstart_dir = shared_rom_dir


# print install directories
if amiga_os_dir != None:
    print 'Amiga OS dir \'{0}\''.format(amiga_os_dir)
if kickstart_dir != None:
    print 'Kickstart dir \'{0}\''.format(kickstart_dir)
if user_packages_dir != None:
    print 'User packages dir \'{0}\''.format(user_packages_dir)
if amiga_forever_data_dir != None:
    print 'Amiga Forever data dir \'{0}\''.format(amiga_forever_data_dir)

# print amiga forever data dir, if it defined and exists
if self_install and amiga_forever_data_dir != None and os.path.isdir(amiga_forever_data_dir):
    # cloanto amiga forever
    print ''
    print 'Cloanto Amiga Forever'
    print '---------------------'
    print 'Install Amiga OS 3.1 adf and Kickstart rom files from Amiga Forever data dir...'

    shared_dir = os.path.join(amiga_forever_data_dir, 'Shared')
    shared_adf_dir = os.path.join(shared_dir, 'adf')
    shared_rom_dir = os.path.join(shared_dir, 'rom')

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
        print '- {0} Amiga OS 3.1 adf files installed \'{1}\''.format(
            len(installed_amiga_os_31_adf_filenames), 
            ', '.join(installed_amiga_os_31_adf_filenames))
    else:
        print '- No Amiga Forever data shared adf dir detected'

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
        print '- {0} Kickstart rom files installed \'{1}\''.format(
            len(installed_kickstart_rom_filenames), 
            ', '.join(installed_kickstart_rom_filenames))
    else:
        print '- No Amiga Forever data shared rom dir detected'
    print 'Done'


# validate self install directories, if self install is defined
if self_install:
    # print self install
    print ''
    print 'Self install'
    print '------------'

    # print amiga os directory
    print 'Validating Amiga OS...'
    print '- Amiga OS dir \'{0}\''.format(amiga_os_dir)

    # get amiga os files from amiga os directory
    amiga_os_md5_files = get_md5_files_from_dir(amiga_os_dir)

    # amiga os 3.9 filenames detected
    detected_amiga_os_39_filenames_index = {}
    for md5_file in amiga_os_md5_files:
        os39_filename = os.path.basename(md5_file.full_filename)
        if not os39_filename.lower() in valid_amiga_os_39_filename_index:
            continue
        detected_amiga_os_39_filenames_index[valid_amiga_os_39_filename_index[os39_filename.lower()]['Filename'].lower()] = md5_file
    for md5_file in amiga_os_md5_files:
        if not md5_file.md5_hash in valid_amiga_os_39_md5_index:
            continue
        detected_amiga_os_39_filenames_index[valid_amiga_os_39_md5_index[md5_file.md5_hash]['Filename']] = md5_file

    # amiga os 3.9 filenames
    detected_amiga_os_39_filenames = detected_amiga_os_39_filenames_index.keys()
    detected_amiga_os_39_filenames.sort()

    # print detected amiga os 3.9 files
    if len(detected_amiga_os_39_filenames) > 0:
        print '- {0} Amiga OS 3.9 files detected \'{1}\''.format(len(detected_amiga_os_39_filenames_index), ', '.join(detected_amiga_os_39_filenames))
    else:
        print '- No Amiga OS 3.9 files detected'


    # detected amiga os 3.1.4 md5 index and filenames from workbench dir that matches valid amiga os 3.1 md5
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

    # detected amiga os 3.1.4 adfs
    detected_amiga_os_314_adfs = []
    for k in detected_amiga_os_314_md5_index:
        detected_amiga_os_314_adfs.append(detected_amiga_os_314_md5_index[k]['Name'])
    detected_amiga_os_314_adfs = list(set(detected_amiga_os_314_adfs))
    detected_amiga_os_314_adfs.sort()

    # print detected amiga os 3.1.4 adf files
    if len(detected_amiga_os_314_filenames) > 0:
        print '- {0} Amiga OS 3.1.4 adf files detected \'{1}\''.format(
            len(detected_amiga_os_314_filenames), 
            ', '.join(detected_amiga_os_314_filenames))
        print '- {0} Amiga OS 3.1.4 adfs detected \'{1}\''.format(
            len(detected_amiga_os_314_adfs), 
            ', '.join(detected_amiga_os_314_adfs))
    else:
        print '- No Amiga OS 3.1.4 adf files detected'


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

    # detected amiga os 3.1 adfs
    detected_amiga_os_31_adfs = []
    for k in detected_amiga_os_31_md5_index:
        detected_amiga_os_31_adfs.append(detected_amiga_os_31_md5_index[k]['Name'])
    detected_amiga_os_31_adfs = list(set(detected_amiga_os_31_adfs))
    detected_amiga_os_31_adfs.sort()

    # print detected amiga os 3.1 adf files
    if len(detected_amiga_os_31_filenames) > 0:
        print '- {0} Amiga OS 3.1 adf files detected \'{1}\''.format(
            len(detected_amiga_os_31_filenames), 
            ', '.join(detected_amiga_os_31_filenames))
        print '- {0} Amiga OS 3.1 adfs detected \'{1}\''.format(
            len(detected_amiga_os_31_adfs), 
            ', '.join(detected_amiga_os_31_adfs))
    else:
        print '- No Amiga OS 3.1 adf files detected'
    print 'Done'


    # print kickstart directory
    print ''
    print 'Validating Kickstart...'
    print '- Kickstart dir \'{0}\''.format(kickstart_dir)

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
        detected_kickstart_md5_index[valid_kickstart_md5_index[md5_file.md5_hash]['Filename'].lower()] = \
            valid_kickstart_md5_index[md5_file.md5_hash]
        detected_kickstart_filenames.append(kickstart_filename)
    detected_kickstart_filenames = list(set(detected_kickstart_filenames))
    detected_kickstart_filenames.sort()

    # detected kickstart roms
    detected_kickstart_roms = []
    for k in detected_kickstart_md5_index:
        detected_kickstart_roms.append(detected_kickstart_md5_index[k]['Name'])
    detected_kickstart_roms = list(set(detected_kickstart_roms))
    detected_kickstart_roms.sort()

    # print detected kickstart rom files
    if len(detected_kickstart_filenames) > 0:
        print '- {0} Kickstart rom files detected \'{1}\''.format(
            len(detected_kickstart_filenames), 
            ', '.join(detected_kickstart_filenames))
        print '- {0} Kickstart roms detected \'{1}\''.format(
            len(detected_kickstart_roms), 
            ', '.join(detected_kickstart_roms))
    else:
        print '- No Kickstart rom files detected'
    print 'Done'


    # print user packages directory
    print ''
    print 'Validating User Packages...'
    print '- User Packages dir \'{0}\''.format(user_packages_dir)

    # get user package dirs
    user_package_dirs = [n for n in os.listdir(unicode(user_packages_dir, 'utf-8')) \
        if os.path.isfile(os.path.join(os.path.join(user_packages_dir, n), '_installdir'))]

    # print detected user packages
    if len(user_package_dirs) > 0:
        print '- {0} user packages detected \'{1}\''.format(len(user_package_dirs), ', '.join(user_package_dirs))
    else:
        print '- No user packages detected'
    print 'Done'


# find files for patching, if uae or fs-uae config files are present
amiga_os_39_iso_file = None
if len(uae_config_files) > 0 or len(fsuae_config_files) > 0:
    # print files for patching
    print ''
    print 'Files for patching'
    print '------------------'
    print 'Finding A1200 Kickstart rom and Amiga OS 3.9 iso files...'

    # add kickstart files to kickstart index
    for md5_file in get_md5_files_from_dir(kickstart_dir):
        if md5_file.md5_hash in valid_kickstart_md5_index:
            valid_kickstart_md5_index[md5_file.md5_hash]['File'] = md5_file.full_filename

    # find amiga os 3.9 iso file, if amiga os dir is defined and exists
    if amiga_os_dir != None and os.path.isdir(amiga_os_dir):
        # get amiga os 3.9 md5 files matching valid amiga os 3.9 md5 hash or has name 'amigaos3.9.iso'        
        amiga_amiga_os_39_iso_md5_files = []
        amiga_os_39_md5_files = get_md5_files_from_dir(amiga_os_dir)
        for md5_file in amiga_os_39_md5_files:
            if ((md5_file.md5_hash in valid_amiga_os_39_md5_index and 
                re.search(r'amigaos3\.?9\.iso', valid_amiga_os_39_md5_index[md5_file.md5_hash]['Filename'], re.I)) or 
                re.search(r'(\\|//)?amigaos3\.?9\.iso$', md5_file.full_filename, re.I)):
                amiga_amiga_os_39_iso_md5_files.append(md5_file)

        # sort amiga os39 md5 files by matching md5, then filename
        amiga_amiga_os_39_iso_md5_files = sorted(amiga_amiga_os_39_iso_md5_files, key=lambda x: x.md5_hash not in valid_amiga_os_39_md5_index)

        if len(amiga_amiga_os_39_iso_md5_files) >= 1:
            amiga_amiga_os_39_iso_file = amiga_amiga_os_39_iso_md5_files[0].full_filename

    # print amiga os39 iso file, if it's defined
    if amiga_os_39_iso_file != None:
        print '- Using Amiga OS 3.9 iso file \'{0}\''.format(amiga_os_39_iso_file)
    else:
        print '- No Amiga OS 3.9 iso file detected'

    print 'Done'


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
    print ''
    print 'UAE configuration'
    print '-----------------'
    print 'Patching and installing UAE configuration files...'

    # print uae install dir, if it exists
    if uae_install_dir != None:
        print '- UAE install dir \'{0}\''.format(uae_install_dir)

    print '- {0} UAE configuration files \'{1}\''.format(len(uae_config_files), ', '.join(uae_config_files))    
    for uae_config_file in uae_config_files:
        kickstart_file = None

        # read model from uae config file
        model = read_model_from_config_file(
            os.path.realpath(uae_config_file))

        # get kickstart file for model, if model is defined. otherwise set model to unknown
        if model:
            for k, v in valid_kickstart_md5_index.items():
                if re.search(model, v['Model']) and v['ConfigSupported'] and 'File' in v:
                    # set kickstart file
                    kickstart_file = v['File']
        else:
            model = 'unknown'

        if kickstart_file:
            print '- \'{0}\'. Using Kickstart file \'{1}\' for {2} model'.format(uae_config_file, kickstart_file, model)
            kickstart_file = os.path.realpath(kickstart_file)
        else:
            print '- \'{0}\'. No Kickstart file for {1} model in configuration file!'.format(uae_config_file, model)

        # patch uae config file
        patch_uae_config_file(
            os.path.realpath(uae_config_file),
            kickstart_file,
            amiga_os_39_iso_file,
            amiga_os_dir,
            kickstart_dir,
            user_packages_dir)
        
        # install uae config file in uae install directory, if uae install directory is defined
        if uae_install_dir != None:
            shutil.copyfile(
                uae_config_file, 
                os.path.join(uae_install_dir, os.path.basename(uae_config_file)))

    print 'Done'


# patch and install fs-uae configuration files, if they are present
if len(fsuae_config_files) > 0:
    # print fs-uae configuration
    print ''
    print 'FS-UAE configuration'
    print '--------------------'
    print 'Patching and installing FS-UAE configuration files...'

    # fs-uae config dir
    fsuae_config_dir = None

    # print fs-uae directory, if it exists
    if fsuae_dir != None:
        print '- FS-UAE dir \'{0}\''.format(fsuae_dir)

        # fs-uae configuration directory
        fsuae_config_dir = os.path.join(fsuae_dir, 'Configurations')

        # create fs-uae configuration directory, if it doesn't exist
        if not os.path.exists(fsuae_config_dir):
            os.makedirs(fsuae_config_dir)

    print '- {0} FS-UAE configuration files'.format(len(fsuae_config_files))
    for fsuae_config_file in fsuae_config_files:
        kickstart_file = None

        # read model from fs-uae config file
        model = read_model_from_config_file(
            os.path.realpath(fsuae_config_file))

        # get kickstart file for model, if model is defined. otherwise set model to unknown
        if model:
            for k, v in valid_kickstart_md5_index.items():
                if re.search(model, v['Model']) and v['ConfigSupported'] and 'File' in v:
                    # set kickstart file
                    kickstart_file = v['File']
        else:
            model = 'unknown'

        if kickstart_file:
            print '- \'{0}\'. Using Kickstart file \'{1}\' for {2} model'.format(fsuae_config_file, kickstart_file, model)
            kickstart_file = os.path.realpath(kickstart_file)
        else:
            print '- \'{0}\'. No Kickstart file for {1} model!'.format(fsuae_config_file, model)

        # patch fs-uae config file
        patch_fsuae_config_file(
            os.path.realpath(fsuae_config_file),
            kickstart_file,
            amiga_os_39_iso_file,
            amiga_os_dir,
            kickstart_dir,
            user_packages_dir)

        # install fs-uae config file in fs-uae install directory, if fs-uae install directory is defined
        if fsuae_config_dir != None:
            shutil.copyfile(
                fsuae_config_file, 
                os.path.join(fsuae_config_dir, os.path.basename(fsuae_config_file)))

    # install fs-uae hstwb installer theme
    hstwb_installer_fsuae_theme_dir = os.path.join(os.path.join(os.path.join(install_dir, 'fs-uae'), 'themes'), 'hstwb-installer')
    if fsuae_dir != None and os.path.exists(hstwb_installer_fsuae_theme_dir):
        # create hstwb installer fs-uae configuration directory, if it doesn't exist
        hstwb_installer_fsuae_theme_dir_installed = os.path.join(os.path.join(fsuae_dir, 'themes'), 'hstwb-installer')
        if not os.path.exists(hstwb_installer_fsuae_theme_dir_installed):
            os.makedirs(hstwb_installer_fsuae_theme_dir_installed)

        # copy hstwb installer fs-uae theme directory
        for filename in os.listdir(unicode(hstwb_installer_fsuae_theme_dir, 'utf-8')):
            source_file = os.path.join(hstwb_installer_fsuae_theme_dir, filename) 
            shutil.copyfile(
                source_file, 
                os.path.join(hstwb_installer_fsuae_theme_dir_installed, filename))

        print '- HstWB Installer FS-UAE theme installed'

    print 'Done'
