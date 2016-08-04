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
import shutil
import soeci

class SRPM:

    def __init__(self,sources,specfile):
        self.sources = sources
        self.specfile = specfile
        self.srpm_path = None
        self.srpms_dir = soeci.WORKSPACE + '/tmp/srpms'
        if not os.path.exists(self.srpms_dir):
            os.makedirs(self.srpms_dir)

    def build(self):
        os.chdir(self.sources)
        commit = subprocess.check_output('git log --format=%%H -1 %s' % self.sources, shell=True)
        # create the hashfile if it does not already exist
        open('.rpmbuild-hash', 'a').close()
        hashfile = open('.rpmbuild-hash', 'r+')
        if commit != hashfile.read():
            for line in open(self.specfile, 'r'):
                if 'Name:' in line: rpm_name = line.split()[1]
            for file in glob.glob(self.srpms_dir + '/' + rpm_name + '-*.src.rpm'):
                os.remove(file)
            try:
                m = subprocess.check_output('/usr/bin/mock --offline --buildsrpm --spec %s --sources %s --resultdir %s' % (self.specfile, self.sources, self.srpms_dir), shell=True)
            except:
                soeci.stopbuild("Mock SRPM build of %s failed" % (self.root + '/' + self.specfile))
            s = re.search('^Wrote: .*/(.*\.src.rpm)$', m, re.MULTILINE)
            self.srpm_path = self.srpms_dir + '/' + s.group(1)
            hashfile.seek(0)
            hashfile.write(commit)
            hashfile.truncate()
        else:
            print("NO CHANGES SINCE LAST BUILD, SKIPPING %s" % self.specfile)
        hashfile.close()
            
        
class RPM:
    
    def __init__(self,srpm_path):
        self.srpm_path = srpm_path
        self.rpm_path = None
        self.rpms_dir = soeci.WORKSPACE + '/tmp/rpms'
        if not os.path.exists(self.rpms_dir):
            os.makedirs(self.rpms_dir)

    def build(self):
        try:
            m = subprocess.check_output('/usr/bin/mock --rebuild %s -D "%%debug_package %%{nil}" --resultdir %s' % (self.srpm_path, self.rpms_dir), shell=True)
            s = re.findall('^Wrote: .*/(.*\.rpm$)',m, re.MULTILINE)
            self.rpm_path = self.rpms_dir + '/' + s[1]
        except:
            soeci.stopbuild("Mock RPM build of %s failed" % self.srpm_path)
    
    def publish(self):
        try:
            shutil.move(self.rpm_path, soeci.YUM_REPO)
        except:
            soeci.stopbuild("Could not publish %s into %s" % (self.rpm_path, soeci.YUM_REPO))
        
def main(argv):

    srpms = []
    rpms = []

    for root, dirs, files in os.walk(argv[0]):
        for file in files:
            if file.endswith('.spec'):
                srpms.append(SRPM(root,file))

    for s in srpms:
        s.build()
        if s.srpm_path:
            rpms.append(RPM(s.srpm_path))  
        
    for r in rpms:
        r.build()
        r.publish()



if __name__ == "__main__":
    main(sys.argv[1:])


