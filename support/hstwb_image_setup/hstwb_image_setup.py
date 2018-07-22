# HstWB Image Setup
# -----------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-06-29
#
# A python script to setup HstWB images with following installation steps:
#
# 1. Find Cloanto Amiga Forever data dir.
#    - Drives or mounted iso.
#    - Environment variable "AMIGAFOREVERDATA".
# 2. Detect if UAE or FS-UAE configuration files contains self install directories.
#    - Detect and install Workbench 3.1 adf and Kickstart rom files from Cloanto Amiga Forever data dir using MD5 hashes.
#    - Validate files in self install directories using MD5 hashes to indicate, if all files are present for self install.
# 3. Detect files for patching configuration files.
#    - Find A1200 Kickstart rom 3.1 in kickstart dir.
#    - Find Amiga OS 3.9 iso file in os39 dir.
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
            if re.search(r'^hard_drive_\d+_label\s*=\s*(workbenchdir|kickstartdir|os39dir|userpackagesdir)', line, re.I) or \
                re.search(r'^(hardfile2|uaehf\d+|filesystem2)=.+(workbenchdir|kickstartdir|os39dir|userpackagesdir):', line, re.I):
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

# get fsuae config dir
def get_fsuae_config_dir():
    """Get FS-UAE config dir"""

    user_home_dir = os.path.expanduser('~')
    directories = [os.path.join(user_home_dir, _f) for _f in os.listdir(user_home_dir) \
        if os.path.isdir(os.path.join(user_home_dir, _f))]

    for directory in directories:
        fsuae_config_dir = os.path.join(directory, os.path.join('FS-UAE', 'Configurations'))
        if os.path.isdir(fsuae_config_dir):
            return fsuae_config_dir

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

# patch uae config file
def patch_uae_config_file( \
    uae_config_file, \
    a1200_kickstart_rom_file, \
    amiga_os39_iso_file, \
    workbench_dir):
    """Patch UAE Config File"""

    # get uae config dir
    uae_config_dir = os.path.dirname(uae_config_file)

    # read uae config file
    uae_config_lines = []
    with open(uae_config_file) as _f:
        for line in _f:
            uae_config_lines.append(line)

    # patch uae config lines
    for i in range(0, len(uae_config_lines)):
        line = uae_config_lines[i]

        # patch cd image 0 file
        if re.search(r'^cdimage0\s*=', line, re.I) and amiga_os39_iso_file:
            line = 'cdimage0={0}\n'.format(
                re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), amiga_os39_iso_file.replace('\\', '\\\\')))

        # patch kickstart rom file
        if re.search(r'^kickstart_rom_file\s*=', line, re.I) and a1200_kickstart_rom_file:
            line = 'kickstart_rom_file={0}\n'.format(
                re.sub(r'[\\/]', os.sep.replace('\\', '\\\\'), a1200_kickstart_rom_file.replace('\\', '\\\\')))

        # patch hardfile2 path
        hardfile2_match = re.search(r'^hardfile2=[^,]*,[^:]*:([^,]+)', line, re.I)
        if hardfile2_match:
            hardfile_path = os.path.join(uae_config_dir, os.path.basename(hardfile2_match.group(1)))
            line = re.sub(r'^(hardfile2=[^,]*,[^,:]*:)[^,]+', 
                '\\1{0}'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), hardfile_path.replace('\\', '\\\\'))), line, 0, re.I)

        # patch uaehf path
        uaehf_match = re.search(r'^uaehf\d+=[^,]*,[^,]*,[^,:]*:"?([^,"]+)', line, re.I)
        if uaehf_match:
            uaehf_path = os.path.join(uae_config_dir, os.path.basename(uaehf_match.group(1)))
            line = re.sub(r'^(uaehf\d+=[^,]*,[^,]*,[^,:]*:"?)[^,"]+', 
                '\\1{0}'.format(re.sub(r'(\\|/)', os.sep.replace('\\', '\\\\'), uaehf_path.replace('\\', '\\\\'))), line, 0, re.I)

        # patch filesystem2 path
        filesystem2_match = re.search(r'^filesystem2=[^,]*,[^,:]*:[^:]*:([^,]+)', line, re.I)
        if filesystem2_match:
            filesystem2_path = os.path.join(uae_config_dir, os.path.basename(filesystem2_match.group(1)))
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
    a1200_kickstart_rom_file, \
    amiga_os39_iso_file, \
    workbench_dir):
    """Patch FSUAE Config File"""

    # get fs-uae config dir
    fsuae_config_dir = os.path.dirname(fsuae_config_file)

    # read fs-uae config file
    hard_drive_labels = {}
    fsuae_config_lines = []
    with open(fsuae_config_file) as _f:
        for line in _f:
            # skip line, if it contains floppy_image
            if re.search(r'^floppy_image_\d+', line):
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
        if re.search(r'^cdrom_drive_0\s*=', line) and amiga_os39_iso_file:
            line = 'cdrom_drive_0 = {0}\n'.format(
                amiga_os39_iso_file.replace('\\', '/'))

        # patch logs dir
        if re.search(r'^logs_dir\s*=', line):
            line = 'logs_dir = {0}\n'.format(fsuae_config_dir.replace('\\', '/'))

        # patch kickstart file
        if re.search(r'^kickstart_file\s*=', line) and a1200_kickstart_rom_file:
            line = 'kickstart_file = {0}\n'.format(
                a1200_kickstart_rom_file.replace('\\', '/'))

        # patch hard drives
        hard_drive_match = re.match(
            r'^(hard_drive_\d+)\s*=\s*(.*)', line, re.M|re.I)
        if hard_drive_match:
            hard_drive_index = hard_drive_match.group(1)
            hard_drive_path = hard_drive_match.group(2)
            if hard_drive_index in hard_drive_labels:
                # patch hard drive
                hard_drive_path = os.path.join(
                    fsuae_config_dir, os.path.basename(hard_drive_path)).replace('\\', '/')
                line = re.sub(
                    r'^(hard_drive_\d+\s*=\s*).*', \
                    '\\1{0}'.format(hard_drive_path), line)

        # update line, if it's changed
        if line != fsuae_config_lines[i]:
            fsuae_config_lines[i] = line

    # get adf files from workbench dir
    adf_files = []
    if workbench_dir != None and os.path.isdir(workbench_dir):
        adf_files.extend([os.path.join(workbench_dir, _f) for _f in os.listdir(unicode(workbench_dir, 'utf-8')) \
            if os.path.isfile(os.path.join(workbench_dir, _f)) and _f.endswith(".adf")])

    # add adf files to fs-uae config lines as swappable floppies
    if len(adf_files) > 0:
        fsuae_config_lines.append('\n')
        for i in range(0, len(adf_files)):
            fsuae_config_lines.append(
                'floppy_image_{0} = {1}\n'.format(i, adf_files[i].replace('\\', '/')))

    # write fs-uae config file without byte order mark
    with open(fsuae_config_file, 'w') as _f:
        _f.writelines(fsuae_config_lines)


# valid workbench 3.1 md5 entries
valid_workbench31_md5_entries = [
    { 'Md5': 'c1c673eba985e9ab0888c5762cfa3d8f', 'Filename': 'workbench31extras.adf', 'Name': 'Workbench 3.1, Extras Disk (Cloanto Amiga Forever 2016)' },
    { 'Md5': '6fae8b94bde75497021a044bdbf51abc', 'Filename': 'workbench31fonts.adf', 'Name': 'Workbench 3.1, Fonts Disk (Cloanto Amiga Forever 2016)' },
    { 'Md5': 'd6aa4537586bf3f2687f30f8d3099c99', 'Filename': 'workbench31install.adf', 'Name': 'Workbench 3.1, Install Disk (Cloanto Amiga Forever 2016)' },
    { 'Md5': 'b53c9ff336e168643b10c4a9cfff4276', 'Filename': 'workbench31locale.adf', 'Name': 'Workbench 3.1, Locale Disk (Cloanto Amiga Forever 2016)' },
    { 'Md5': '4fa1401aeb814d3ed138f93c54a5caef', 'Filename': 'workbench31storage.adf', 'Name': 'Workbench 3.1, Storage Disk (Cloanto Amiga Forever 2016)' },
    { 'Md5': '590c42a69675d6970df350e200fe25dc', 'Filename': 'workbench31workbench.adf', 'Name': 'Workbench 3.1, Workbench Disk (Cloanto Amiga Forever 2016)' },

    { 'Md5': 'c5be06daf40d4c3ace4eac874d9b48b1', 'Filename': 'workbench31install.adf', 'Name': 'Workbench 3.1, Install Disk (Cloanto Amiga Forever 7)' },
    { 'Md5': 'e7b3a83df665a85e7ec27306a152b171', 'Filename': 'workbench31workbench.adf', 'Name': 'Workbench 3.1, Workbench Disk (Cloanto Amiga Forever 7)' }
]

# valid kickstart md5 entries
valid_kickstart_md5_entries = [
    { 'Md5': 'c56ca2a3c644d53e780a7e4dbdc6b699', 'Filename': 'kick33180.A500', 'Encrypted': True, 'Name': 'Kickstart 1.2, 33.180, A500 Rom (Cloanto Amiga Forever 7/2016)' },
    { 'Md5': '89160c06ef4f17094382fc09841557a6', 'Filename': 'kick34005.A500', 'Encrypted': True, 'Name': 'Kickstart 1.3, 34.5, A500 Rom (Cloanto Amiga Forever 7/2016)' },
    { 'Md5': 'c3e114cd3b513dc0377a4f5d149e2dd9', 'Filename': 'kick40063.A600', 'Encrypted': True, 'Name': 'Kickstart 3.1, 40.063, A600 Rom (Cloanto Amiga Forever 7/2016)' },
    { 'Md5': 'dc3f5e4698936da34186d596c53681ab', 'Filename': 'kick40068.A1200', 'Encrypted': True, 'Name': 'Kickstart 3.1, 40.068, A1200 Rom (Cloanto Amiga Forever 7/2016)' },
    { 'Md5': '8b54c2c5786e9d856ce820476505367d', 'Filename': 'kick40068.A4000', 'Encrypted': True, 'Name': 'Kickstart 3.1, 40.068, A4000 Rom (Cloanto Amiga Forever 7/2016)' },

    { 'Md5': '85ad74194e87c08904327de1a9443b7a', 'Filename': 'kick33180.A500', 'Encrypted': False, 'Name': 'Kickstart 1.2, 33.180, A500 Rom (Original)' },
    { 'Md5': '82a21c1890cae844b3df741f2762d48d', 'Filename': 'kick34005.A500', 'Encrypted': False, 'Name': 'Kickstart 1.3, 34.5, A500 Rom (Original)' },
    { 'Md5': 'e40a5dfb3d017ba8779faba30cbd1c8e', 'Filename': 'kick40063.A600', 'Encrypted': False, 'Name': 'Kickstart 3.1, 40.063, A600 Rom (Original)' },
    { 'Md5': '646773759326fbac3b2311fd8c8793ee', 'Filename': 'kick40068.A1200', 'Encrypted': False, 'Name': 'Kickstart 3.1, 40.068, A1200 Rom (Original)' },
    { 'Md5': '9bdedde6a4f33555b4a270c8ca53297d', 'Filename': 'kick40068.A4000', 'Encrypted': False, 'Name': 'Kickstart 3.1, 40.068, A4000 Rom (Original)' }
]

# valid os39 md5 entries
valid_os39_md5_entries = [
    { 'Md5': '3cb96e77d922a4f8eb696e525a240448', 'Filename': 'amigaos3.9.iso', 'Name': 'Amiga OS 3.9 iso', 'Size': 490856448 },
    { 'Md5': 'e32a107e68edfc9b28a2fe075e32e5f6', 'Filename': 'amigaos3.9.iso', 'Name': 'Amiga OS 3.9 iso', 'Size': 490686464 },
    { 'Md5': '71353d4aeb9af1f129545618d013a8c8', 'Filename': 'boingbag39-1.lha', 'Name': 'Boing Bag 1 for Amiga OS 3.9', 'Size': 5254174 },
    { 'Md5': 'fd45d24bb408203883a4c9a56e968e28', 'Filename': 'boingbag39-2.lha', 'Name': 'Boing Bag 2 for Amiga OS 3.9', 'Size': 2053444 }
]

# index valid workbench 3.1 md5 entries
valid_workbench31_md5_index = {}
for entry in valid_workbench31_md5_entries:
    valid_workbench31_md5_index[entry['Md5'].lower()] = entry

# index valid kickstart rom md5 entries
valid_kickstart_md5_index = {}
for entry in valid_kickstart_md5_entries:
    valid_kickstart_md5_index[entry['Md5'].lower()] = entry

# index valid os39 md5 entries
valid_os39_md5_index = {}
valid_os39_filename_index = {}
for entry in valid_os39_md5_entries:
    valid_os39_md5_index[entry['Md5'].lower()] = entry
    valid_os39_filename_index[entry['Filename'].lower()] = entry

# arguments
install_dir = '.'
workbench_dir = None
kickstart_dir = None
os39_dir = None
user_packages_dir = None
amiga_forever_data_dir = None
uae_install_dir = None
fsuae_install_dir = None
patch_only = False
self_install = False

# get arguments
for i in range(0, len(sys.argv)):
    # install dir argument
    if (i + 1 < len(sys.argv) and re.search(r'--installdir', sys.argv[i])):
        install_dir = sys.argv[i + 1]
    # workbench dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--workbenchdir', sys.argv[i])):
        workbench_dir = sys.argv[i + 1]
    # kickstart dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--kickstartdir', sys.argv[i])):
        kickstart_dir = sys.argv[i + 1]
    # os39 dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--os39dir', sys.argv[i])):
        os39_dir = sys.argv[i + 1]
    # user packages dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--userpackagesdir', sys.argv[i])):
        user_packages_dir = sys.argv[i + 1]
    # amiga forever data dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--amigaforeverdatadir', sys.argv[i])):
        amiga_forever_data_dir = sys.argv[i + 1]
    # uae install dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--uaeinstalldir', sys.argv[i])):
        uae_install_dir = sys.argv[i + 1]
    # fs-uae install dir argument
    elif (i + 1 < len(sys.argv) and re.search(r'--fsuaeinstalldir', sys.argv[i])):
        fsuae_install_dir = sys.argv[i + 1]
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
print 'Date: 2018-06-29'
print ''
print 'Install dir \'{0}\''.format(install_dir)

# fail, if install directory doesn't exist
if (install_dir != None and not os.path.isdir(install_dir)):
    print 'Error: Install dir \'{0}\' doesn\'t exist'.format(install_dir)
    exit(1)

# set uae install directory to detected winuae config directory, if uae install directory is not defined and platform is win32
if uae_install_dir == None and sys.platform == "win32":
    uae_install_dir = get_winuae_config_dir()

# set fs-uae install directory to detected fs-uae config directory, if fs-uae install directory is not defined
if fsuae_install_dir == None:
    fsuae_install_dir = get_fsuae_config_dir()

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
    workbench_dir = os.path.join(install_dir, 'workbench')
    kickstart_dir = os.path.join(install_dir, 'kickstart')
    os39_dir = os.path.join(install_dir, 'os39')
    user_packages_dir = os.path.join(install_dir, 'userpackages')

    # create install directories, if they don't exist
    for d in [workbench_dir, kickstart_dir, os39_dir, user_packages_dir]:
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
if workbench_dir != None:
    print 'Workbench dir \'{0}\''.format(workbench_dir)
if kickstart_dir != None:
    print 'Kickstart dir \'{0}\''.format(kickstart_dir)
if os39_dir != None:
    print 'OS39 dir \'{0}\''.format(os39_dir)
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
    print 'Install Workbench 3.1 adf and Kickstart rom files from Amiga Forever data dir...'

    shared_dir = os.path.join(amiga_forever_data_dir, 'Shared')
    shared_adf_dir = os.path.join(shared_dir, 'adf')
    shared_rom_dir = os.path.join(shared_dir, 'rom')

    # install workbench 3.1 adf rom files from cloanto amiga forever data directory, if shared adf directory exists
    if os.path.isdir(shared_adf_dir):
        # copy workbench 3.1 adf files from shared adf dir that matches valid workbench 3.1 md5
        installed_workbench31_adf_filenames = []
        for md5_file in get_md5_files_from_dir(shared_adf_dir):
            if not md5_file.md5_hash in valid_workbench31_md5_index:
                continue
            workbench31_adf_filename = os.path.basename(md5_file.full_filename)
            installed_workbench31_adf_filenames.append(workbench31_adf_filename)
            installed_workbench31_adf_file = os.path.join(workbench_dir, workbench31_adf_filename)
            shutil.copyfile(
                md5_file.full_filename,
                installed_workbench31_adf_file)
            os.chmod(installed_workbench31_adf_file, stat.S_IWRITE)

        # print installed workbench 3.1 adf files
        print '- {0} Workbench 3.1 adf files installed \'{1}\''.format(
            len(installed_workbench31_adf_filenames), 
            ', '.join(installed_workbench31_adf_filenames))
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

    # print workbench directory
    print 'Validating Workbench...'
    print '- Workbench dir \'{0}\''.format(workbench_dir)

    # detected workbench 3.1 md5 index and filenames from workbench dir that matches valid workbench 3.1 md5
    detected_workbench31_md5_index = {}
    detected_workbench31_filenames = []
    for md5_file in get_md5_files_from_dir(workbench_dir):
        if not md5_file.md5_hash in valid_workbench31_md5_index:
            continue
        detected_workbench31_md5_index[valid_workbench31_md5_index[md5_file.md5_hash]['Filename'].lower()] = \
            valid_workbench31_md5_index[md5_file.md5_hash]
        detected_workbench31_filenames.append(os.path.basename(md5_file.full_filename))
    detected_workbench31_filenames = list(set(detected_workbench31_filenames))
    detected_workbench31_filenames.sort()

    # detected workbench 3.1 adfs
    detected_workbench31_adfs = []
    for k in detected_workbench31_md5_index:
        detected_workbench31_adfs.append(detected_workbench31_md5_index[k]['Name'])
    detected_workbench31_adfs = list(set(detected_workbench31_adfs))
    detected_workbench31_adfs.sort()

    # print detected workbench 3.1 adf files
    if len(detected_workbench31_filenames) > 0:
        print '- {0} Workbench 3.1 adf files detected \'{1}\''.format(
            len(detected_workbench31_filenames), 
            ', '.join(detected_workbench31_filenames))
        print '- {0} Workbench 3.1 adfs detected \'{1}\''.format(
            len(detected_workbench31_adfs), 
            ', '.join(detected_workbench31_adfs))
    else:
        print '- No Workbench 3.1 adf files detected'
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

    # print os39 directory
    print ''
    print 'Validating OS39...'
    print '- OS39 dir \'{0}\''.format(os39_dir)

    # get os39 files from os39 directory
    os39_md5_files = get_md5_files_from_dir(os39_dir)

    # os39 filenames detected
    detected_os39_filenames_index = {}
    for md5_file in os39_md5_files:
        os39_filename = os.path.basename(md5_file.full_filename)
        if not os39_filename.lower() in valid_os39_filename_index:
            continue
        detected_os39_filenames_index[valid_os39_filename_index[os39_filename.lower()]['Filename'].lower()] = md5_file
    for md5_file in os39_md5_files:
        if not md5_file.md5_hash in valid_os39_md5_index:
            continue
        detected_os39_filenames_index[valid_os39_md5_index[md5_file.md5_hash]['Filename']] = md5_file

    # detected os 39 filenames
    detected_os39_filenames = detected_os39_filenames_index.keys()
    detected_os39_filenames.sort()

    # print detected amiga os39 files
    if len(detected_os39_filenames) > 0:
        print '- {0} Amiga OS 3.9 files detected \'{1}\''.format(len(detected_os39_filenames_index), ', '.join(detected_os39_filenames))
    else:
        print '- No Amiga OS 3.9 files detected'
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
a1200_kickstart_rom_file = None
amiga_os39_iso_file = None
if len(uae_config_files) > 0 or len(fsuae_config_files) > 0:
    # print files for patching
    print ''
    print 'Files for patching'
    print '------------------'
    print 'Finding A1200 Kickstart 3.1 rom and Amiga OS 3.9 iso files...'

    # find a1200 kickstart rom file, if kickstart dir is defined and exists
    if kickstart_dir != None and os.path.isdir(kickstart_dir):
        # find first a1200 kickstart 3.1 rom md5 file
        a1200_kickstart_rom_md5_file = None
        for md5_file in get_md5_files_from_dir(kickstart_dir):
            if md5_file.md5_hash in valid_kickstart_md5_index and re.search(r'kick40068\.a1200', valid_kickstart_md5_index[md5_file.md5_hash]['Filename'], re.I):
                a1200_kickstart_rom_md5_file = md5_file
                break

        # find a1200 kickstart 3.1 rom file
        if a1200_kickstart_rom_md5_file != None:
            # fail, if a1200 kickstart rom entry is encrypted and rom key file doesn't exist
            rom_key_file = os.path.join(kickstart_dir, 'rom.key')
            if valid_kickstart_md5_index[md5_file.md5_hash]['Encrypted'] and not os.path.isfile(rom_key_file):
                print 'Error: Amiga Forever rom key file \'{0}\' doesn\'t exist'.format(rom_key_file)
                exit(1)
            a1200_kickstart_rom_file = a1200_kickstart_rom_md5_file.full_filename

    # find amiga os39 iso file, if os39 dir is defined and exists
    if os39_dir != None and os.path.isdir(os39_dir):
        # get amiga os39 md5 files matching valid amiga os 3.9 md5 hash or has name 'amigaos3.9.iso'        
        amiga_os39_iso_md5_files = []
        os39_md5_files = get_md5_files_from_dir(os39_dir)
        for md5_file in os39_md5_files:
            if ((md5_file.md5_hash in valid_os39_md5_index and 
                re.search(r'amigaos3\.9\.iso', valid_os39_md5_index[md5_file.md5_hash]['Filename'], re.I)) or 
                re.search(r'(\\|//)?amigaos3\.9\.iso$', md5_file.full_filename, re.I)):
                amiga_os39_iso_md5_files.append(md5_file)

        # sort amiga os39 md5 files by matching md5, then filename
        amiga_os39_iso_md5_files = sorted(amiga_os39_iso_md5_files, key=lambda x: x.md5_hash not in valid_os39_md5_index)

        if len(amiga_os39_iso_md5_files) >= 1:
            amiga_os39_iso_file = amiga_os39_iso_md5_files[0].full_filename

    # print a1200 kickstart rom file, if it's defined
    if a1200_kickstart_rom_file != None:
        print '- Using A1200 Kickstart 3.1 rom file \'{0}\''.format(a1200_kickstart_rom_file)
    else:
        print '- No A1200 Kickstart 3.1 rom file detected'

    # print amiga os39 iso file, if it's defined
    if amiga_os39_iso_file != None:
        print '- Using Amiga OS 3.9 iso file \'{0}\''.format(amiga_os39_iso_file)
    else:
        print '- No Amiga OS 3.9 iso file detected'

    print 'Done'


# get full path for a1200 kickstart rom file, amiga os39 iso file and workbench dir, if they are defined
if a1200_kickstart_rom_file != None:
    a1200_kickstart_rom_file = os.path.realpath(a1200_kickstart_rom_file)
if amiga_os39_iso_file != None:
    amiga_os39_iso_file = os.path.realpath(amiga_os39_iso_file)
if workbench_dir != None:
    workbench_dir = os.path.realpath(workbench_dir)


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
        # patch uae config file
        patch_uae_config_file(
            os.path.realpath(uae_config_file),
            a1200_kickstart_rom_file,
            amiga_os39_iso_file,
            workbench_dir)
        
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

    # print fs-uae install directory, if it exists
    if fsuae_install_dir != None:
        print '- FS-UAE install dir \'{0}\''.format(fsuae_install_dir)

    print '- {0} FS-UAE configuration files \'{1}\''.format(len(fsuae_config_files), ', '.join(fsuae_config_files))
    for fsuae_config_file in fsuae_config_files:
        # patch fs-uae config file
        patch_fsuae_config_file(
            os.path.realpath(fsuae_config_file),
            a1200_kickstart_rom_file,
            amiga_os39_iso_file,
            workbench_dir)

        # install fs-uae config file in fs-uae install directory, if fs-uae install directory is defined
        if fsuae_install_dir != None:
            shutil.copyfile(
                fsuae_config_file, 
                os.path.join(fsuae_install_dir, os.path.basename(fsuae_config_file)))

    print 'Done'
