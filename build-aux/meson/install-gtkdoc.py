#!/usr/bin/env python3

import sys
from os import environ, path, getcwd
import shutil

destdir = environ.get('MESON_INSTALL_DESTDIR_PREFIX', '')

a = path.join(sys.argv[1], 'html')
b = path.join(destdir, sys.argv[2])

print(a,b)
shutil.copytree(a, b, dirs_exist_ok=True)


