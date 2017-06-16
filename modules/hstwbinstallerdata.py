"""HstWB Installer Data"""

import hashlib
import csv

def calculate_md5_from_file(fname):
    """Calculate MD5 from file"""
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as _f:
        for chunk in iter(lambda: _f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def read_csv_file(fname):
    """Read CSV File"""
    reader = csv.DictReader(open(fname, 'rb'), delimiter=';', quotechar='"')
    rows = []
    for line in reader:
        rows.append(line)
    return rows
