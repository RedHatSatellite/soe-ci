#!/usr/bin/python -t
# Utility functions for SOE CI build scripts

import sys
import os

WORKSPACE = os.environ.get('WORKSPACE')
YUM_REPO = os.environ.get('YUM_REPO')

def stopbuild(reason):
    print('BUILD STOPPED: %s' % reason)
    sys.exit(1)

    
