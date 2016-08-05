#!/usr/bin/python -t
# Utility functions for SOE CI build scripts

import sys
import os

WORKSPACE = os.environ.get('WORKSPACE')
YUM_REPO = os.environ.get('YUM_REPO')

def stopbuild(reason):
    print('BUILD STOPPED: %s' % reason)
    sys.exit(1)

def usage(message):
    print('USAGE: %s' % message)
    sys.exit(1)

for e in ['WORKSPACE', 'YUM_REPO']:
    if eval(e) == None:
        stopbuild("Environment variable %s is not set" % e)

    
