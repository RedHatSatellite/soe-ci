#!/usr/bin/python -tt
# Instruct Foreman to rebuild the test VMs
#
# e.g ${WORKSPACE}/scripts/buildtestvms.sh $TESTVM_HOSTGROUP
#
# this will tell Foreman to rebuild all machines in hostgroup TESTVM_HOSTGROUP

import sys
import os
import glob
import shutil
import soeci
import re
from nailgun.entities import HostCollection
from nailgun.entities import Organization
from nailgun.entities import HostGroup

from pprint import pprint








def main(argv):
    
    test_vms = []
    
    soeci.config()

    #hostcollection = HostCollection().search(query={'search':'name="%s"' % soeci.TESTVM_HOSTCOLLECTION})
    
    #hostcollections = HostCollection().search()
    hostcollections = HostCollection().search()
    pprint(hostcollections)
                                                    
                                                    









if __name__=="__main__":
    main(sys.argv[1:])
    
