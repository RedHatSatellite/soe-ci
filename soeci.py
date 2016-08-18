#!/usr/bin/python -tt
# Utility functions for SOE CI build scripts

import sys
import os
from nailgun.config import ServerConfig
from nailgun.entities import Organization
from pprint import pprint
import requests

WORKSPACE = None
YUM_REPO = None
REPO_ID = None
SATELLITE = None
SATELLITE_USER = None
SATELLITE_PASSWORD = None
ORG = None
ORG_ID = None
TESTVM_HOSTCOLLECTION = None

def auth_satellite():
    serverconfig = ServerConfig(
        auth = (SATELLITE_USER, SATELLITE_PASSWORD),
        url = ('https://%s' % SATELLITE),
        verify=False)
    serverconfig.save()
    

def get_org_id():
    try:
        org = Organization().search(query={'search':'name="%s"' % ORG})
    except requests.exceptions.HTTPError as e:
        stopbuild("Could not authenticate to satellite: %s" % e)
    
    if org == []:
        stopbuild("Org %s does not exist" % ORG)

    org_id = org[0].get_values()["id"]
        
    return org_id

    

def stopbuild(reason):
        print('BUILD STOPPED: %s' % reason)
        sys.exit(1)

def usage(message):
        print('USAGE: %s' % message)
        sys.exit(1)

def config():
    global WORKSPACE
    global YUM_REPO
    global REPO_ID
    global SATELLITE
    global SATELLITE_USER
    global SATELLITE_PASSWORD
    global ORG
    global ORG_ID
    global TESTVM_HOSTCOLLECTION
    
    WORKSPACE = os.environ.get('WORKSPACE')
    YUM_REPO = os.environ.get('YUM_REPO')
    REPO_ID = os.environ.get('REPO_ID')
    SATELLITE = os.environ.get('SATELLITE')
    SATELLITE_USER = os.environ.get('SATELLITE_USER')
    SATELLITE_PASSWORD = os.environ.get('SATELLITE_PASSWORD')
    ORG = os.environ.get('ORG')
    TESTVM_HOSTCOLLECTION = os.environ.get('TESTVM_HOSTCOLLECTION')
        
    for e in ['WORKSPACE','YUM_REPO','REPO_ID','SATELLITE','SATELLITE_USER','SATELLITE_PASSWORD','ORG', 'TESTVM_HOSTCOLLECTION']:
        if eval(e) == None:
            stopbuild("Environment variable %s is not set" % e)

    auth_satellite() 
    ORG_ID = get_org_id()
