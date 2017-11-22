#!/bin/bash

# Push RPMs to satellite via a yum repo
#
# e.g. ${WORKSPACE}/scripts/rpmpush.sh ${WORKSPACE}/soe/artefacts/
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]] || [[ -z ${YUM_REPO} ]] || [[ -z ${WORKSPACE} ]]
then
    err "PUSH_USER, SATELLITE, YUM_REPO or WORKSPACE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# get the RPM (src and binary) names found in ${YUM_REPO}
# and verify that a folder for this is in git.
# mind you, this explicitly does not differentiate between the RPM versions.
# the reason is that we want to remove all versions of the RPM.
# see Issue #102 at https://github.com/RedHatSatellite/soe-ci/issues/102
inform "checking '${YUM_REPO}' for RPMs no longer in git"
pushd "${YUM_REPO}"
    find . -type f -name "*.rpm" | while read I
    do
        # get RPM name
        J=$(rpm -qp --queryformat "%{name}\n" ${I})

        # check if RPM still exists in git
        if [[ ! -d "${WORKSPACE}/soe/rpms/${J}" ]]
        then
            warn "RPM '${I}' found in '${YUM_REPO}' but not in git."
            warn "Deleting the RPM now."
            rm --verbose --interactive=never ${I}
        fi
    done
popd
inform "RPM check completed"

# has anything changed? If yes, then MODIFIED_CONTENT_FILE is not 0 bytes 
if [[ ! -s "${MODIFIED_RPMS_FILE}" ]]
then
    inform "No entries in ${MODIFIED_RPMS_FILE} no need to continue with $0"
    exit 0
fi

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    usage "$0 <artefacts directory>"
    exit ${NOARGS}
fi
workdir=$1

# refresh the upstream yum repo
createrepo ${YUM_REPO}

# use hammer on the satellite to push the RPMs into the repo
# the ID of the ACME Test repository is 16
inform "Synchronize repository ID ${REPO_ID}"
ssh -q -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa ${SATELLITE} \
    "hammer repository synchronize --id ${REPO_ID}" || \
  { err "Repository '${REPO_ID}' couldn't be synchronized."; exit 1; }
