"""HstWB Installer Data"""

import hashlib
import csv
import ConfigParser
from os import listdir
from os.path import isfile, join

def calculate_md5_from_file(fname):
    """Calculate MD5 from file"""
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as _f:
        for chunk in iter(lambda: _f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

# read ini file
def read_ini_file(fname):
    """Read Ini File"""
    config = ConfigParser.ConfigParser()
    config.read(fname)
    ini = {}
    for section in config.sections():
        ini[section.lower()] = {}
        for option in config.options(section):
            ini[section.lower()][option.lower()] = config.get(section, option)
    return ini

# read csv file
def read_csv_file(fname):
    """Read CSV File"""
    reader = csv.DictReader(open(fname, 'rb'), delimiter=';', quotechar='"')
    rows = []
    for line in reader:
        rows.append(line)
    return rows

# get file hashes
def get_file_hashes(path):
    """Get file hashes"""
    files = [join(path, _f) for _f in listdir(path) if isfile(join(path, _f))]
    file_hashes = []

    for _f in files:
        md5_hash = calculate_md5_from_file(_f)
        file_hashes.append({'Md5Hash':md5_hash, 'File':_f})

    return file_hashes

# find matching file hashes
def find_matching_file_hashes(hashes, path):
    """Find matching file hashes"""
    # get file hashes from path
    file_hashes = get_file_hashes(path)

    # index file hashes
    file_hashes_index = {}
    for _fh in file_hashes:
        file_hashes_index[_fh['Md5Hash']] = _fh['File']

    for _h in hashes:
        if _h['Md5Hash'] in file_hashes_index.iterkeys():
            _h['File'] = file_hashes_index[_h['Md5Hash']]

# find kickstart rom set hashes
def find_kickstart_rom_set_hashes(settings_ini, kickstart_rom_hashes):
    """Find Kickstart rom set hashes"""

    # find files with hashes matching kickstart rom hashes
    find_matching_file_hashes(
        kickstart_rom_hashes, settings_ini['kickstart']['kickstartrompath'])

    # get kickstart rom set hashes
    kickstart_rom_set_hashes = []
    for _h in kickstart_rom_hashes:
        if _h['Set'] == settings_ini['kickstart']['kickstartromset']:
            kickstart_rom_set_hashes.append(_h)

    if not kickstart_rom_set_hashes:
        raise "Kickstart rom set '" + \
            settings_ini['kickstart']['kickstartromset'] + \
            "' doesn't exist!"

    return kickstart_rom_set_hashes
