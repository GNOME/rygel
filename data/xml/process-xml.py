#!/usr/bin/env python3

import sys
import re

with open(sys.argv[1], 'r') as f:
    for data in f:
        print(data.strip(), end='')
