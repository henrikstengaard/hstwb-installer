#!/bin/sh
set -e

rm -rf build dist
python setup.py py2app -A
