#!/usr/bin/python -tt
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
import pty

class SRPM:

    def __init__(self,sources,specfile):
        self.sources = sources
        self.specfile = os.path.join(self.sources, specfile)
        self.srpm_path = None 
        self.commit = None
        self.hashfile = self.sources + '/' + '.rpmbuild-hash'
        self.srpms_dir = soeci.WORKSPACE + '/tmp/srpms'
        if not os.path.exists(self.srpms_dir):
            os.makedirs(self.srpms_dir)
        # print self.hashfile;

    def __codechanged__(self):
        # create the hashfile if it does not already exist
        self.commit = subprocess.check_output('git log --format=%%H -1 %s' % self.sources, shell=True, cwd=os.path.dirname(self.sources))
        # print self.commit
        open(self.hashfile,'a').close()
        h = open('.rpmbuild-hash', 'r')
        c = h.read()
        h.close()
        if c == self.commit:
            return False
        else:
            return True

    def build(self):
        os.chdir(self.sources)
        if self.__codechanged__():
            for line in open(self.specfile, 'r'):
                if 'Name:' in line: rpm_name = line.split()[1]
            for file in glob.glob(self.srpms_dir + '/' + rpm_name + '-*.src.rpm'):
                os.remove(file)
            try:
                # we need to fake a tty for mock to get stdout from rpmbuild
                (master, slave) = pty.openpty()
                m = subprocess.check_output('/usr/bin/mock --buildsrpm --spec %s --sources %s --resultdir %s' % 
                    (self.specfile, self.sources, self.srpms_dir), stderr = slave, shell=True)
            except:
                soeci.stopbuild("Mock SRPM build of %s failed" % (self.root + '/' + self.specfile))
            print m
            s = re.search('^Wrote: .*/(.*\.src.rpm)$', m, re.MULTILINE)
            self.srpm_path = self.srpms_dir + '/' + s.group(1)
        else:
            print("NO CHANGES SINCE LAST BUILD, SKIPPING %s" % self.specfile)
        
        
class RPM:
    
    def __init__(self,srpm_path, hashfile, commit):
        self.srpm_path = srpm_path
        self.rpm_path = None
        self.hashfile = hashfile
        self.commit = commit
        self.rpms_dir = soeci.WORKSPACE + '/tmp/rpms'
        if not os.path.exists(self.rpms_dir):
            os.makedirs(self.rpms_dir)

    def build(self):
        try:
            # we need to fake a tty for mock to get stdout from rpmbuild
            (master, slave) = pty.openpty()
            m = subprocess.check_output('/usr/bin/mock --rebuild %s -D "%%debug_package %%{nil}" --resultdir %s' % (self.srpm_path, self.rpms_dir), 
                stderr=slave, shell=True)
            print m
            s = re.findall('^Wrote: .*/(.*\.rpm$)',m, re.MULTILINE)
            self.rpm_path = self.rpms_dir + '/' + s[1]
        except:
            soeci.stopbuild("Mock RPM build of %s failed" % self.srpm_path)
    
    def publish(self):
        try:
            shutil.move(self.rpm_path, soeci.YUM_REPO)
        except shutil.Error as e:
            soeci.stopbuild("Could not publish %s into %s: %s" % (self.rpm_path, soeci.YUM_REPO, e))
    
    def updatehash(self):
        os.chdir(os.path.dirname(self.srpm_path))
        h = open(self.hashfile, 'w')
        h.seek(0)
        h.write(self.commit)
        h.truncate()
        h.close()
        
def publishrepo():
    try:
        subprocess.call('restorecon -F %s' % soeci.YUM_REPO, shell=True)
        subprocess.call('createrepo %s' % soeci.YUM_REPO, shell=True)
    except:
        soeci.stopbuild("Could not create yum repo %s" & soeci.YUM_REPO)
        
def main(argv):

    srpms = []
    rpms = []

    soeci.config()

    try:
        for root, dirs, files in os.walk(argv[0]):
            for file in files:
                if file.endswith('.spec'):
                    srpms.append(SRPM(root,file))
    except:
        soeci.stopbuild("Could not read input directory")

    for s in srpms:
        s.build()
        if s.srpm_path:
            rpms.append(RPM(s.srpm_path, s.hashfile, s.commit))  
        
    for r in rpms:
        r.build()
        r.publish()
        r.updatehash()
        
    publishrepo()


if __name__ == "__main__":
    main(sys.argv[1:])


