#!/usr/bin/python -tt

# Search for kickstarts and template files
#
# e.g. ${WORKSPACE}/scripts/kickstartbuild.py ${WORKSPACE}/soe/kickstarts/ 
#

import sys
import os
import glob
import shutil
import soeci

ARTEFACTDIR = soeci.WORKSPACE + '/artefacts/kickstarts'

class Template:
    
    def __init__(self, path, file):
        self.path = path
        self.file = file

    def publish(self):
        try:
            shutil.copy(self.path + '/' + self.file, ARTEFACTDIR)
        except:
            soeci.stopbuild("Could not copy %s into %s" % (self.file, ARTEFACTDIR))
  
                

def initartefactdir():
    if not os.path.exists(ARTEFACTDIR):
        try:
            os.makedirs(ARTEFACTDIR)
        except:
            soeci.stopbuild("Could not create artefacts directory %s" % ARTEFACTDIR)

    for f in glob.glob(ARTEFACTDIR + '/' + '*'):
        try:
            os.remove(f)
        except:
            soeci.stopbuild("Could not delete file %s" % f)

def main(argv):

    templates = []

    if (len(argv) != 1) or not os.path.isdir(argv[0]):
        soeci.usage("kickstartbuild.py <directory containing template files>")

    initartefactdir()

    try:
        for root, dirs, files in os.walk(argv[0]):
            for file in files:
                if file.endswith('.erb'):
                    templates.append(Template(root,file))
    except:
        soeci.stopbuild("Could not read template directory %s" % argv[0])

    for k in templates:
            k.publish()


if __name__ == "__main__":
    main(sys.argv[1:])
