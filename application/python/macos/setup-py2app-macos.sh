#!/bin/sh
set -e

# clean output
if [ -d ".output" ]; then
    rm -rf ".output"
fi
mkdir ".output"

# copy python scripts
cp "../hstwb-installer"* ".output"
cp -r "../ui" ".output"
cp "hstwb-installer.icns" ".output"
cp "setup-py2app-macos.py" ".output"

# run py2app
cd ".output"
python setup-py2app-macos.py py2app -A
cd ".."