#!/usr/bin/env python3
"""
Author : kyclark
Date   : 2019-03-08
Purpose: Copy "MANIFEST" files into Data Store
"""

import os
import sys
import re
import tempfile
from subprocess import run
from shutil import copyfile, rmtree


# --------------------------------------------------
def warn(msg):
    """Print a message to STDERR"""
    print(msg, file=sys.stderr)


# --------------------------------------------------
def die(msg='Something bad happened'):
    """warn() and exit with error"""
    warn(msg)
    sys.exit(1)


# --------------------------------------------------
def main():
    args = sys.argv[1:]
    in_dir = args[0] if len(args) == 1 else os.getcwd()

    if not os.path.isdir(in_dir):
        die('"{}" is not a directory'.format(in_dir))

    if not os.path.isabs(in_dir):
        in_dir = os.path.abspath(in_dir)

    if not re.match('stampede2?$', os.path.basename(in_dir)):
        die('"{}" is not the stampede(2) dir'.format(in_dir))

    app_dir = os.path.join(*in_dir.split('/')[-2:])
    if app_dir.startswith('/'):
        app_dir = app_dir[1:]

    print('Looking in "{}"'.format(in_dir))

    manifests = []
    for root, _, filenames in os.walk(in_dir):
        for filename in filenames:
            if filename == 'MANIFEST':
                manifests.append(os.path.join(root, filename))

    num = len(manifests)
    print('Found {} MANIFEST file{} in "{}"'.format(num, '' if num == 1 else
                                                    's', in_dir))

    if num == 0: die('Nothing to do')

    file_num = 0
    tmp_dir = os.path.join(tempfile.mkdtemp(), app_dir)
    if not os.path.isdir(tmp_dir):
        os.makedirs(tmp_dir)

    for manifest in manifests:
        man_dir = os.path.dirname(manifest)
        print('Processing {}'.format(manifest))
        for file in open(manifest):
            file = file.rstrip()
            path = re.sub('^\.', man_dir, file)
            file_num += 1
            print('{:3}: {}'.format(file_num, path))

            if os.path.isfile(path):
                filedir = os.path.dirname(re.sub(in_dir, '', path))
                if filedir.startswith('/'):
                    filedir = filedir[1:]

                partial = os.path.join(tmp_dir, filedir)
                if not os.path.isdir(partial):
                    os.makedirs(partial)

                copyfile(path, os.path.join(partial, os.path.basename(file)))

    app_base = os.path.split(app_dir)[0]
    dest = 'kyclark/applications/' + app_base
    run(['files-upload', '-F', tmp_dir, dest])
    rmtree(tmp_dir)
    print('Done, check "{}"'.format(dest))


# --------------------------------------------------
main()
