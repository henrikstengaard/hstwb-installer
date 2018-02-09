"""Setup py2exe Windows"""

# Prerequisites:
# - py2exe

# Build:
# python setup-py2exe-windows.py py2exe

from distutils.core import setup
import py2exe

setup(
    data_files = ['./hstwb-installer.ico'],
    windows = [{
        'script': './hstwb-installer.py',
        'version': '2.0.0',
        'company_name': 'First Realize',
        'copyright': 'First Realize',
        'name': 'HstWB Installer'
        }],
    zipfile = None,
    options = {
        'py2exe': {
            'bundle_files': 3,
            'compressed': True,
            'dll_excludes': [
                'w9xpopen.exe',
                'crypt32.dll',
                'mpr.dll',
                'mswsock.dll',
                'powrprof.dll'
            ]
        }
    })
