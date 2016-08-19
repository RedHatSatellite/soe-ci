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
from nailgun.entities import Host

from pprint import pprint








def main(argv):
    
    test_vms = []
    
    soeci.config()

    #hostcollection = HostCollection().search(query={'search':'name="%s"' % soeci.TESTVM_HOSTCOLLECTION})
    
    #hostcollections = HostCollection().search()
    #hostcollections = HostCollection().search()
    hostcollection = HostCollection(id=1)
    hostcollection = hostcollection.read()
    #pprint(hostcollection.get_values())
    hg = HostCollection(id=1)
    hg = hg.read()
    pprint(hg.get_fields())
    pprint(hg.get_values())
    #pprint(hg.host)
    #hosts = Host().search(query={'search':'hostcollection = "Engineering-Test"'})
  #  hosts = HostCollection(id=1)
  #  hosts = 
  #  for i in hosts:
  #      pprint(i.get_values())
                                                        
                                                    









if __name__=="__main__":
    main(sys.argv[1:])
    
