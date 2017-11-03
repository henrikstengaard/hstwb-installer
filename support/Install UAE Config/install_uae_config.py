# Install UAE config
# ------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-11-03
#
# A python script to install UAE config for HstWB images by patching
# hard drive directories to current directory, use A1200 Kickstart 3.1
# from Kickstart directory and add .adf files from Workbench directory
# as swappable floppies.

"""Install UAE Config"""

import os
import hashlib
import re
import shutil
import sys

# calculate md5 from file
def calculate_md5_from_file(fname):
    """Calculate MD5 From File"""
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as _f:
        for chunk in iter(lambda: _f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

# find a1200 kickstart 3.1 rom file
def find_a1200_kickstart31_rom_file(kickstart_dir):
    """Find A1200 Kickstart31 Rom File"""

    # return none, if kickstart dir doesn't exist
    if not os.path.exists(kickstart_dir):
        return None

    # get rom files from kickstart dir
    rom_files = [os.path.join(kickstart_dir, _f) for _f in os.listdir(kickstart_dir) \
        if os.path.isfile(os.path.join(kickstart_dir, _f))]

    for rom_file in rom_files:
        md5_hash = calculate_md5_from_file(rom_file)

        # return kickstart file, if md5 matches
        # Cloanto Amiga Forever 2016 Kickstart 3.1 (40.068) (A1200) rom
        if md5_hash == 'dc3f5e4698936da34186d596c53681ab':
            return rom_file

        # return kickstart file, if md5 matches
        # Custom Kickstart 3.1 (40.068) (A1200) rom
        if md5_hash == '646773759326fbac3b2311fd8c8793ee':
            return rom_file

    return None

# find amiga os 3.9 iso file
def find_amiga_os_39_iso_file(os39_dir):
    """Find Amiga OS 3.9 iso file"""

    # return none, if os39 dir doesn't exist
    if not os.path.exists(os39_dir):
        return None

    # get amiga os 3.9 iso files from os39 directory
    amiga_os_39_iso_files = [os.path.join(os39_dir, _f) for _f in os.listdir(os39_dir) \
        if os.path.isfile(os.path.join(os39_dir, _f)) and re.search(r'amigaos3\.9\.iso$', _f)]

    # return none, if amiga os 3.9 iso files exist doesn't exist
    if len(amiga_os_39_iso_files) == 0:
        return None

    return amiga_os_39_iso_files[0]

# find fsuae config dir
def find_fsuae_config_dir():
    """Find FSUAE Config Dir"""
    user_home_dir = os.path.expanduser('~')
    directories = [os.path.join(user_home_dir, _f) for _f in os.listdir(user_home_dir) \
        if os.path.isdir(os.path.join(user_home_dir, _f))]

    for directory in directories:
        fsuae_config_dir = os.path.join(directory, os.path.join('FS-UAE', 'Configurations'))
        if os.path.isdir(fsuae_config_dir):
            return fsuae_config_dir

    return None

# patch fs-uae config file
def patch_fsuae_config_file( \
    fsuae_config_file, current_dir, workbench_dir, kickstart_dir, os39_dir, userpackages_dir):
    """Patch FSUAE Config File"""

    # find A1200 kickstart 3.1 rom file in kickstart dir
    a1200_kickstart31_rom_file = find_a1200_kickstart31_rom_file(kickstart_dir)

    # find amiga os 3.9 iso file in os39 dir
    amiga_os_39_iso_file = find_amiga_os_39_iso_file(os39_dir)

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
        if re.search(r'^cdrom_drive_0\s*=', line):
            if amiga_os_39_iso_file:
                line = 'cdrom_drive_0 = {0}\n'.format(amiga_os_39_iso_file.replace('\\', '/'))
            else:
                line = 'cdrom_drive_0 = \n'

        # patch logs dir
        if re.search(r'^logs_dir\s*=', line):
            line = 'logs_dir = {0}\n'.format(current_dir.replace('\\', '/'))

        # patch kickstart file
        if re.search(r'^kickstart_file\s*=', line):
            if a1200_kickstart31_rom_file:
                line = 'kickstart_file = {0}\n'.format(
                    a1200_kickstart31_rom_file.replace('\\', '/'))
            else:
                line = 'kickstart_file = \n'

        # patch hard drives
        hard_drive_match = re.match(
            r'^(hard_drive_\d+)\s*=\s*(.*)', line, re.M|re.I)
        if hard_drive_match:
            hard_drive_index = hard_drive_match.group(1)
            hard_drive_path = hard_drive_match.group(2)
            if hard_drive_index in hard_drive_labels:
                # patch workbenchdir hard drive
                if hard_drive_labels[hard_drive_index] == 'WORKBENCHDIR':
                    line = re.sub(
                        r'^(hard_drive_\d+\s*=\s*).*', \
                        '\\1{0}'.format(workbench_dir.replace('\\', '/')), line)
                # patch kickstartdir hard drive
                elif hard_drive_labels[hard_drive_index] == 'KICKSTARTDIR':
                    line = re.sub(
                        r'^(hard_drive_\d+\s*=\s*).*', \
                        '\\1{0}'.format(kickstart_dir.replace('\\', '/')), line)
                # patch os39dir hard drive
                elif hard_drive_labels[hard_drive_index] == 'OS39DIR':
                    line = re.sub(
                        r'^(hard_drive_\d+\s*=\s*).*', \
                        '\\1{0}'.format(os39_dir.replace('\\', '/')), line)
                # patch userpackagesdir hard drive
                elif hard_drive_labels[hard_drive_index] == 'USERPACKAGESDIR':
                    line = re.sub(
                        r'^(hard_drive_\d+\s*=\s*).*', \
                        '\\1{0}'.format(userpackages_dir.replace('\\', '/')), line)
                # patch hard drive
                else:
                    hard_drive_path = os.path.join(
                        current_dir, os.path.basename(hard_drive_path)).replace('\\', '/')
                    line = re.sub(
                        r'^(hard_drive_\d+\s*=\s*).*', \
                        '\\1{0}'.format(hard_drive_path), line)

        # update line, if it's changed
        if line != fsuae_config_lines[i]:
            fsuae_config_lines[i] = line

    # get adf files from workbench dir
    adf_files = [os.path.join(workbench_dir, _f) for _f in os.listdir(workbench_dir) \
        if os.path.isfile(os.path.join(workbench_dir, _f)) and _f.endswith(".adf")]

    # add adf files to fs-uae config lines as swappable floppies
    for i in range(0, len(adf_files)):
        fsuae_config_lines.append(
            'floppy_image_{0} = {1}\n'.format(i, adf_files[i].replace('\\', '/')))

    # write fs-uae config file without byte order mark
    with open(fsuae_config_file, 'w') as _f:
        _f.writelines(fsuae_config_lines)

# get patch only argument
PATCH_ONLY = len(sys.argv) >= 2 and re.search(r'--patch-only', sys.argv[1])

# get current directory
CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

# read winuae and fs-uae config files
UAE_CONFIG_LINES = []

# add fs-uae config lines, if fs-uae config file exists
FSUAE_CONFIG_FILE = os.path.join(CURRENT_DIR, 'hstwb-installer.fs-uae')
if os.path.isfile(FSUAE_CONFIG_FILE):
    with open(FSUAE_CONFIG_FILE) as f:
        UAE_CONFIG_LINES.extend(f.readlines())

# self install directories
WORKBENCH_DIR = os.path.join(CURRENT_DIR, 'Workbench')
KICKSTART_DIR = os.path.join(CURRENT_DIR, 'Kickstart')
OS39_DIR = os.path.join(CURRENT_DIR, 'OS39')
USERPACKAGES_DIR = os.path.join(CURRENT_DIR, 'UserPackages')
SELF_INSTALL_DIRS = []

# check, if self install directories exists in uae config files
WORKBENCH_DIR_PRESENT = False
KICKSTART_DIR_PRESENT = False
OS39_DIR_PRESENT = False
USERPACKAGES_DIR_PRESENT = False
for UAE_CONFIG_LINE in UAE_CONFIG_LINES:
    if re.search('WORKBENCHDIR', UAE_CONFIG_LINE):
        WORKBENCH_DIR_PRESENT = True
        SELF_INSTALL_DIRS.append(WORKBENCH_DIR)
    if re.search('KICKSTARTDIR', UAE_CONFIG_LINE):
        KICKSTART_DIR_PRESENT = True
        SELF_INSTALL_DIRS.append(KICKSTART_DIR)
    if re.search('OS39DIR', UAE_CONFIG_LINE):
        OS39_DIR_PRESENT = True
        SELF_INSTALL_DIRS.append(OS39_DIR)
    if re.search('USERPACKAGESDIR', UAE_CONFIG_LINE):
        USERPACKAGES_DIR_PRESENT = True
        SELF_INSTALL_DIRS.append(USERPACKAGES_DIR)

# create self install directories, if they don't exist
for SELF_INSTALL_DIR in SELF_INSTALL_DIRS:
    if not os.path.exists(SELF_INSTALL_DIR):
        os.makedirs(SELF_INSTALL_DIR)


# print install use config title
print '------------------'
print 'Install UAE Config'
print '------------------'
print 'Author: Henrik Noerfjand Stengaard'
print 'Date: 2017-11-03'
print ''
print 'Patch hard drives to use the following directories:'
print 'IMAGEDIR        : "{0}"'.format(CURRENT_DIR)

# print workbenchdir, if it's present
if WORKBENCH_DIR_PRESENT:
    print 'WORKBENCHDIR    : "{0}"'.format(WORKBENCH_DIR)

# print kickstartdir, if it's present
if KICKSTART_DIR_PRESENT:
    print 'KICKSTARTDIR    : "{0}"'.format(KICKSTART_DIR)

# print os39dir, if it's present
if OS39_DIR_PRESENT:
    print 'OS39DIR         : "{0}"'.format(OS39_DIR)

# print userpackagesdir, if it's present
if USERPACKAGES_DIR_PRESENT:
    print 'USERPACKAGESDIR : "{0}"'.format(USERPACKAGES_DIR)


# patch and install fs-uae config file, if it exists
if os.path.isfile(FSUAE_CONFIG_FILE):
    print ''
    print 'FS-UAE configuration file "{0}"'.format(FSUAE_CONFIG_FILE)
    print '- Patching hard drive directories, kickstart rom file, ' \
        'Amiga OS 3.9 iso file and add Workbench adf files as swappable floppies...'

    # patch fs-uae config file
    patch_fsuae_config_file(
        FSUAE_CONFIG_FILE, CURRENT_DIR, WORKBENCH_DIR, KICKSTART_DIR, OS39_DIR, USERPACKAGES_DIR)

    # get fs-uae config directory
    FSUAE_CONFIG_DIR = find_fsuae_config_dir()

    # install fs-uae config file, if fs-uae config directory exists and patch only is not set
    if not PATCH_ONLY and FSUAE_CONFIG_DIR:
        print '- Installing in FS-UAE configuration directory "{0}"...'.format(FSUAE_CONFIG_DIR)
        INSTALL_FSUAE_CONFIG_FILE = os.path.join(
            FSUAE_CONFIG_DIR, os.path.basename(FSUAE_CONFIG_FILE))
        shutil.copyfile(FSUAE_CONFIG_FILE, INSTALL_FSUAE_CONFIG_FILE)

    print 'Done'
else:
    print 'FS-UAE configuration file "{0}" doesn''t exist!'.format(FSUAE_CONFIG_FILE)
    