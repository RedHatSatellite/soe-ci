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

class Template:
    
    def __init__(self, path, file, artefact_dir):
        self.path = path
        self.file = file
        self.artefact_dir = artefact_dir

    def publish(self):
        try:
            shutil.copy(self.path + '/' + self.file, self.artefact_dir)
        except:
            soeci.stopbuild("Could not copy %s into %s" % (self.file, self.artefact_dir))
  
                

def initartefactdir(artefact_dir):
    if not os.path.exists(artefact_dir):
        try:
            os.makedirs(artefact_dir)
        except:
            soeci.stopbuild("Could not create artefacts directory %s" % artefact_dir)

    for f in glob.glob(artefact_dir + '/' + '*'):
        try:
            os.remove(f)
        except:
            soeci.stopbuild("Could not delete file %s" % f)

def main(argv):

    templates = []

    soeci.config()
    artefact_dir = soeci.WORKSPACE + '/artefacts/kickstarts'


    if (len(argv) != 1) or not os.path.isdir(argv[0]):
        soeci.usage("kickstartbuild.py <directory containing template files>")

    initartefactdir(artefact_dir)

    try:
        for root, dirs, files in os.walk(argv[0]):
            for file in files:
                if file.endswith('.erb'):
                    templates.append(Template(root,file,artefact_dir))
    except:
        soeci.stopbuild("Could not read template directory %s" % argv[0])

    for k in templates:
            k.publish()


if __name__ == "__main__":
    main(sys.argv[1:])
