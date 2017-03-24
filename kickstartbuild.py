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
import re
from nailgun.entities import ConfigTemplate


class Template:
    
    def __init__(self, path, file):
        self.path = path
        self.file = file
        self.name = None

    def publish(self):
        print "Publishing %s" % self.file
        with open('%s/%s' % (self.path, self.file), 'r') as t:
            content = t.read()
            
        s = re.search('^name:\s*(.*)', content, re.MULTILINE)
        if s:
            self.name = s.group(1)
        else:
            soeci.stopbuild("Template %s does not contain a name definition" % self.file)
        
        with open('%s/%s' % (self.path, self.file), 'r') as t:
            content = t.read()

        templates = ConfigTemplate().search(query={'search':'name="%s"' % self.name})
        if templates:
            print "updating template: %s" % self.name 
            templates[0].template = content
            templates[0].update()
            # move the template into the current organisation
            print templates[0].get_values()["template_kind"]
            sys.exit()
        else:
            print "creating template: %s" % self.name 
            template = ConfigTemplate(name=self.name, template=content)
            template.create_missing()
            template.create()
            # move the template into the current organisation

def main(argv):

    templates = []
    soeci.config()


    if (len(argv) != 1) or not os.path.isdir(argv[0]):
        soeci.usage("kickstartbuild.py <directory containing template files>")

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
