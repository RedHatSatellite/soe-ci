#!/usr/bin/python -tt

# Publish the content view(s) and promote if necessary
#
# This script can be tested /used with a command like:
#   PUSH_USER=jenkins SATELLITE=sat6.example.com \
#   RSA_ID=/var/lib/jenkins/.ssh/id_rsa TESTVM_ENV=2 CV="cv-acme-soe-demo" \
#   CV_PASSIVE_LIST="cv-passive-1,cv-passive-2" ORG=Default_Organization \
#   CCV_NAME_PATTERN="ccv-test-*" BUILD_URL=$$ ./publishcv.sh

import sys
import soeci
import time
from nailgun.entities import ContentView

class SOECV():
    
    def __init__(self, cv_name):
        self.cv_name = cv_name
        try:
            self.cv = ContentView().search(query={'search':'name="%s"' % self.cv_name})[0]
        except:
            soeci.stopbuild("Could not find Content View named %s to promote" % self.cv_name)
        
    def publish(self):        
        self.cv.publish()
        
    def promote(self, environment_id):
        # find the most recent content view version
        self.cv = self.cv.read()
        ver = self.cv.version[-1]

        try:
            ver.promote(data={'environment_id':environment_id, 'force':True})
        except:
            soeci.stopbuild("Could not promote Content View Version %s to Environment %s" % (ver.id, environment_id))


def main(argv):

    cvs = []
    soeci.config()
    
    cvs.append(SOECV(soeci.CV))
    
    for cv in cvs:
        cv.publish()
        # sleep to give time for locks to clear
        time.sleep(90)
        cv.promote(soeci.TESTVM_ENV)
    
if __name__ == "__main__":
    main(sys.argv[1:])
    
    
