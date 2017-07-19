#!/usr/bin/python -tt
# Push RPMs to satellite via a yum repo
#
# e.g. ${WORKSPACE}/scripts/rpmpush.sh
#


import soeci
import requests
from nailgun.entities import Repository

if __name__ == "__main__":

    soeci.config()
    repo = Repository(id=soeci.REPO_ID)
    try:
        repo.sync()
    except requests.exceptions.HTTPError as e:
        soeci.stopbuild("Could not sync repository %s. Error: %s" % (soeci.REPO_ID, e))

