#!/bin/bash

# Push RPMs to satellite via a yum repo
#
# e.g. ${WORKSPACE}/scripts/rpmpush.sh ${WORKSPACE}/soe/artefacts/
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

# has anything changed? If yes, then MODIFIED_CONTENT_FILE is not 0 bytes 
if [[ ! -s "${MODIFIED_CONTENT_FILE}" ]]
then
    info "No entries in ${MODIFIED_CONTENT_FILE} no need to continue with $0"
    exit 0
fi

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    usage "$0 <artefacts directory>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]
then
    err "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# refresh the upstream yum repo
createrepo ${YUM_REPO}

# use hammer on the satellite to push the RPMs into the repo
# the ID of the ACME Test repository is 16
ssh -q -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa ${SATELLITE} \
    "hammer repository synchronize --id ${REPO_ID}" || \
  { err "Repository '${REPO_ID}' couldn't be synchronized."; exit 1; }
