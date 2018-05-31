# HstWB Image Setup
# -----------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-05-31
#
# A python script to setup HstWB images with following installation:
# - Detect and install Workbench 3.1 adf and Kickstart rom files from Cloanto Amiga Forever using MD5 hashes.
# - Validate files in self install directories using MD5 hashes to indicate, if all files are present for self install.
# - Patch and install UAE and FS-UAE configuration files.
# - For FS-UAE configuration files, .adf files from Workbench directory are added as swappable floppies.


"""HstWB Image Setup"""

import os
import hashlib
import re
import shutil
import sys


# md5 file
class Md5File:
    md5_hash = ""
    full_filename = ""

# calculate md5 from file
def calculate_md5_from_file(_file):
    """Calculate MD5 From File"""
    hash_md5 = hashlib.md5()
    with open(_file, "rb") as _f:
        for chunk in iter(lambda: _f.read(4096), b""):
            hash_md5.update(chunk)

    return hash_md5.hexdigest().lower()

# get md5 files from dir
def get_md5_files_from_dir(_dir):
    """Get Md5 Files From Dir"""

    md5_files = []    

    files = [os.path.join(_dir, _f) for _f in os.listdir(_dir) \
        if os.path.isfile(os.path.join(_dir, _f))]

    for f in files:
        md5_file = Md5File()
        md5_file.md5_hash = calculate_md5_from_file(f)
        md5_file.full_filename = f
        md5_files.append(md5_file)
    
    return md5_files

# find a1200 kickstart 3.1 rom file
def find_a1200_kickstart31_rom_file(kickstart_dir):
    """Find A1200 Kickstart31 Rom File"""

    # return none, if kickstart dir doesn't exist
    if not os.path.exists(kickstart_dir):
        return None

    # get rom files from kickstart dir
    rom_files = [os.path.join(kickstart_dir, _f) for _f in os.listdir(kickstart_dir) \
        if os.path.isfile(os.path.join(kickstart_dir, _f)) and _f.endswith(".rom")]

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
    fsuae_config_file, \
    a1200_kickstart_rom_file, \
    current_dir, \
    workbench_dir, \
    kickstart_dir, \
    os39_dir, \
    userpackages_dir):
    """Patch FSUAE Config File"""

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
            if a1200_kickstart_rom_file:
                line = 'kickstart_file = {0}\n'.format(
                    a1200_kickstart_rom_file.replace('\\', '/'))
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
    adf_files = []
    if os.path.isdir(workbench_dir):
        adf_files.extend([os.path.join(workbench_dir, _f) for _f in os.listdir(workbench_dir) \
            if os.path.isfile(os.path.join(workbench_dir, _f)) and _f.endswith(".adf")])

    # add adf files to fs-uae config lines as swappable floppies
    for i in range(0, len(adf_files)):
        fsuae_config_lines.append(
            'floppy_image_{0} = {1}\n'.format(i, adf_files[i].replace('\\', '/')))

    # write fs-uae config file without byte order mark
    with open(fsuae_config_file, 'w') as _f:
        _f.writelines(fsuae_config_lines)


# md5_files = get_md5_entries_from_dir('test\\kickstart')

# for md5_file in md5_files:
#     print(md5_file.md5_hash, md5_file.full_filename)

# exit


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
INSTALL_DIR = '.'
AMIGA_FOREVER_DATA_DIR = None

# set amiga forever data directory to amiga forever data environment variable, if not defined
if (os.environ['AMIGAFOREVERDATA'] != None):
    AMIGA_FOREVER_DATA_DIR = os.environ['AMIGAFOREVERDATA']

# get arguments
for i in range(0, len(sys.argv)):
    # install dir argument
    if (i + 1 < len(sys.argv) and re.search(r'--installdir', sys.argv[i])):
        INSTALL_DIR = sys.argv[i + 1]
    # amiga forever data dir argument
    if (i + 1 < len(sys.argv) and re.search(r'--amigaforeverdatadir', sys.argv[i])):
        AMIGA_FOREVER_DATA_DIR = sys.argv[i + 1]

# print hstwb image setup title
print '-----------------'
print 'HstWB Image Setup'
print '-----------------'
print 'Author: Henrik Noerfjand Stengaard'
print 'Date: 2018-05-31'
print ''
print 'Install dir \'{0}\''.format(INSTALL_DIR)

# fail, if install directory doesn't exist
if (INSTALL_DIR != None and not os.path.isdir(INSTALL_DIR)):
    print 'Error: Install dir doesn\'t exist'
    exit(1)

# self install directories
WORKBENCH_DIR = os.path.join(INSTALL_DIR, 'workbench')
KICKSTART_DIR = os.path.join(INSTALL_DIR, 'kickstart')
OS39_DIR = os.path.join(INSTALL_DIR, 'os39')
USERPACKAGES_DIR = os.path.join(INSTALL_DIR, 'userpackages')

# create self install directories, if they don't exist
for SELF_INSTALL_DIR in [WORKBENCH_DIR, KICKSTART_DIR, OS39_DIR, USERPACKAGES_DIR]:
    if not os.path.exists(SELF_INSTALL_DIR):
        os.makedirs(SELF_INSTALL_DIR)


# cloanto amiga forever
print ''
print 'Cloanto Amiga Forever'
print '---------------------'
print 'Amiga Forever data dir \'{0}\''.format(AMIGA_FOREVER_DATA_DIR if not AMIGA_FOREVER_DATA_DIR == None else '')
if (AMIGA_FOREVER_DATA_DIR != None and os.path.isdir(AMIGA_FOREVER_DATA_DIR)):
    print 'Install Workbench 3.1 adf and Kickstart rom files from Cloanto Amiga Forever:'

    SHARED_DIR = os.path.join(AMIGA_FOREVER_DATA_DIR, 'Shared')

    # install workbench 3.1 adf rom files from cloanto amiga forever data directory, if shared adf directory exists
    SHARED_ADF_DIR = os.path.join(SHARED_DIR, 'adf')
    print '- Amiga Forever data dir shared adf dir \'{0}\''.format(SHARED_ADF_DIR)
    if os.path.isdir(SHARED_ADF_DIR):
        print '- Installing Workbench 3.1 adf files to Workbench dir \'{0}\'...'.format(WORKBENCH_DIR)

        # copy workbench 3.1 adf files from shared adf dir that matches valid workbench 3.1 md5
        for md5_file in get_md5_files_from_dir(SHARED_ADF_DIR):
            if not md5_file.md5_hash in valid_workbench31_md5_index:
                continue
            shutil.copyfile(
                md5_file.full_filename,
                os.path.join(WORKBENCH_DIR, os.path.basename(md5_file.full_filename)))
    else:
        print 'Skip: Amiga Forever data shared adf dir doesn\'t exist!'

    # install kickstart rom files from cloanto amiga forever data directory, if shared rom directory exists
    SHARED_ROM_DIR = os.path.join(SHARED_DIR, 'rom')
    print '- Amiga Forever data dir shared rom dir \'{0}\''.format(SHARED_ROM_DIR)
    if os.path.isdir(SHARED_ROM_DIR):
        print '- Installing Kickstart rom files to Kickstart dir \'{0}\'...'.format(KICKSTART_DIR)

        # copy kickstart rom files from shared rom dir that matches valid kickstart md5
        for md5_file in get_md5_files_from_dir(SHARED_ROM_DIR):
            if not md5_file.md5_hash in valid_kickstart_md5_index:
                continue
            shutil.copyfile(
                md5_file.full_filename,
                os.path.join(KICKSTART_DIR, os.path.basename(md5_file.full_filename)))

        # copy amiga forever rom key file, if it exists
        rom_key_file = os.path.join(SHARED_ROM_DIR, 'rom.key')
        if os.path.isfile(rom_key_file):
            shutil.copyfile(rom_key_file, os.path.join(KICKSTART_DIR, 'rom.key'))
    else:
        print 'Skip: Amiga Forever data shared rom dir doesn\'t exist!'
    print 'Done'
else:
    print 'Skip: Amiga Forever data dir is not defined or doesn\'t exist!'


# print self install directories
print ''
print 'Self install directories'
print '------------------------'
print "Validating Workbench dir \'{0}\'...".format(WORKBENCH_DIR)

# get workbench 3.1 md5 files from workbench dir that matches valid workbench 3.1 md5
workbench31_md5_files = []
detected_workbench31_filenames = []
for md5_file in get_md5_files_from_dir(WORKBENCH_DIR):
    if not md5_file.md5_hash in valid_workbench31_md5_index:
        continue
    workbench31_md5_files.append(md5_file)
    detected_workbench31_filenames.append(
        valid_workbench31_md5_index[md5_file.md5_hash]['Filename'])
detected_workbench31_filenames = list(set(detected_workbench31_filenames))
detected_workbench31_filenames.sort()

# workbench 3.1 filenames
workbench31_filenames = []
for entry in valid_workbench31_md5_entries:
    workbench31_filenames.append(entry['Filename'].lower())
workbench31_filenames = list(set(workbench31_filenames))
workbench31_filenames.sort()

# print workbench 3.1 md5 files
print '- {0} of {1} Workbench 3.1 adf files detected'.format(
    len(detected_workbench31_filenames), 
    len(workbench31_filenames))
for workbench31_md5_file in workbench31_md5_files:
    print '- {0} MD5 match \'{1}\''.format(
        valid_workbench31_md5_index[workbench31_md5_file.md5_hash]['Name'], 
        workbench31_md5_file.full_filename)
print 'Done'


# print kickstart directory
print ''
print 'Validating Kickstart dir \'{0}\'...'.format(KICKSTART_DIR)

# get kickstart md5 files from kickstart dir that matches valid kickstart md5
kickstart_md5_files = []
detected_kickstart_filenames = []
for md5_file in get_md5_files_from_dir(KICKSTART_DIR):
    if not md5_file.md5_hash in valid_kickstart_md5_index:
        continue
    detected_kickstart_filenames.append(
        valid_kickstart_md5_index[md5_file.md5_hash]['Filename'])
detected_kickstart_filenames = list(set(detected_kickstart_filenames))
detected_kickstart_filenames.sort()

# kickstart filenames
kickstart_filenames = []
for entry in valid_kickstart_md5_entries:
    kickstart_filenames.append(entry['Filename'].lower())
kickstart_filenames = list(set(kickstart_filenames))
kickstart_filenames.sort()

# print kickstart md5 files
print '- {0} of {1} Kickstart rom files detected'.format(
    len(detected_kickstart_filenames), 
    len(kickstart_filenames))
for kickstart_md5_file in kickstart_md5_files:
    print '- {0} MD5 match \'{1}\''.format(
        valid_kickstart_md5_index[kickstart_md5_file.md5_hash]['Name'], 
        kickstart_md5_file.full_filename)
print 'Done'

# print os39 directory
print ''
print 'Validating OS39 dir \'{0}\'...'.format(OS39_DIR)

# get os39 files from os39 dir
os39_md5_files = get_md5_files_from_dir(OS39_DIR)

# os39 filenames detected
detected_os39_filenames_index = {}
for md5_file in os39_md5_files:
    os39_filename = os.path.basename(md5_file.full_filename).lower()
    if not os39_filename in valid_os39_filename_index:
        continue
    detected_os39_filenames_index[valid_os39_filename_index[os39_filename]['Filename']] = md5_file
for md5_file in os39_md5_files:
    if not md5_file.md5_hash in valid_os39_md5_index:
        continue
    detected_os39_filenames_index[valid_os39_md5_index[md5_file.md5_hash]['Filename']] = md5_file

# print os39 files
print '- {0} Amiga OS 3.9 files detected'.format(len(detected_os39_filenames_index))

detected_os39_filenames = []
for detected_os39_filename in detected_os39_filenames_index.keys():
    detected_os39_filenames.append(detected_os39_filename)
detected_os39_filenames.sort()

for os39_filename in detected_os39_filenames:
    os39_md5_file = detected_os39_filenames_index[os39_filename]

    if os39_md5_file.md5_hash in valid_os39_md5_index:
        print '- {0} MD5 match \'{1}\''.format(valid_os39_md5_index[os39_md5_file.md5_hash]['Name'], os39_md5_file.full_filename)
    elif os39_filename in valid_os39_filename_index:
        print '- {0} filename match \'{1}\''.format(valid_os39_filename_index[os39_filename]['Name'], os39_md5_file.full_filename)

exit(0)


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
WORKBENCH_DIR = os.path.join(CURRENT_DIR, 'workbench')
KICKSTART_DIR = os.path.join(CURRENT_DIR, 'kickstart')
OS39_DIR = os.path.join(CURRENT_DIR, 'os39')
USERPACKAGES_DIR = os.path.join(CURRENT_DIR, 'userpackages')
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
print 'Date: 2017-11-09'
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

# set a1200 kickstart rom dir to kickstart dir, if it exists.
# otherwise set a1200 kickstart rom dir to current dir
if KICKSTART_DIR_PRESENT:
    A1200_KICKSTART_ROM_DIR = KICKSTART_DIR
else:
    A1200_KICKSTART_ROM_DIR = CURRENT_DIR

# get a1200 kickstart 3.1 rom from a1200 kickstart rom dir
A1200_KICKSTART_ROM_FILE = find_a1200_kickstart31_rom_file(A1200_KICKSTART_ROM_DIR)

# patch and install fs-uae config file, if it exists
if os.path.isfile(FSUAE_CONFIG_FILE):
    print ''
    print 'FS-UAE configuration file "{0}"'.format(FSUAE_CONFIG_FILE)
    print '- Patching hard drive directories, kickstart rom file, ' \
        'Amiga OS 3.9 iso file and add Workbench adf files as swappable floppies...'

    # patch fs-uae config file
    patch_fsuae_config_file(
        FSUAE_CONFIG_FILE, \
        A1200_KICKSTART_ROM_FILE, \
        CURRENT_DIR, \
        WORKBENCH_DIR, \
        KICKSTART_DIR, \
        OS39_DIR, \
        USERPACKAGES_DIR)

    # get fs-uae config directory
    FSUAE_CONFIG_DIR = find_fsuae_config_dir()

    # install fs-uae config file, if fs-uae config directory exists and patch only is not set
    # if not PATCH_ONLY and FSUAE_CONFIG_DIR:
    #     print '- Installing in FS-UAE configuration directory "{0}"...'.format(FSUAE_CONFIG_DIR)
    #     INSTALL_FSUAE_CONFIG_FILE = os.path.join(
    #         FSUAE_CONFIG_DIR, os.path.basename(FSUAE_CONFIG_FILE))
    #     shutil.copyfile(FSUAE_CONFIG_FILE, INSTALL_FSUAE_CONFIG_FILE)

    print 'Done'
else:
    print 'FS-UAE configuration file "{0}" doesn''t exist!'.format(FSUAE_CONFIG_FILE)
    