#!/usr/bin/python  -t
# Search for RPM source directories and package
#
# e.g. ${WORKSPACE}/scripts/rpmbuilder.py ${WORKSPACE}/soe/rpms/ 
#
# We need to be able to specify a mock configuration

import os
import sys
import glob
import subprocess
import re

WORKSPACE = os.environ.get('WORKSPACE')

#class rpm:

#    def __init__(self,path,srpm):


#    def build(self):




class SRPM:

    def __init__(self,root,specfile):
        self.root = root
        self.specfile = specfile
        self.srpms_dir = WORKSPACE + "/tmp/srpms"

    def build(self):
        os.chdir(self.root)
        commit = subprocess.call('git log --format=%%H -1 %s' % self.root, shell=True)
        # create the hashfile if it does not already exist
        open('.rpmbuild-hash', 'a').close() 
        if commit != open('.rpmbuild-hash', 'r').read():
            for line in open(self.specfile, 'r'):
                if 'Name:' in line: rpm_name = line.split()[1]
            for file in glob.glob(self.srpms_dir + '/' + rpm_name + '-*.src.rpm'):
                os.remove(file)
            m = subprocess.check_output('/usr/bin/mock --offline --buildsrpm --spec %s --sources %s --resultdir %s' % (self.specfile, self.root, self.srpms_dir), shell=True)
            s = re.search("Wrote: (.*)$", m)
        return s.group(1)
        
class RPM:
    
    def __init__(self,path):
        self.srpm_path = path
        self.rpm_path = ""
        self.rpms_dir = WORKSPACE + "/tmp/rpms"
        

    def build(self):
        foo = subprocess.check_output('/usr/bin/mock --rebuild %s -D "%%debug_package %%{nil}" --resultdir %s' % (self.srpm_path, self.rpms_dir), shell=True)
        
def main(argv):

    srpms = []
    rpms = []

    for root, dirs, files in os.walk(argv[0]):
        for file in files:
            if file.endswith(".spec"):
                srpms.append(SRPM(root,file))

    for i in srpms:
        rpms.append(RPM(i.build()))  
        
    for i in rpms:
        i.build()



if __name__ == "__main__":
    main(sys.argv[1:])


