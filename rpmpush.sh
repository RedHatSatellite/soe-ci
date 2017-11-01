#!/bin/bash

# Push RPMs to satellite via a yum repo
#
# e.g. ${WORKSPACE}/scripts/rpmpush.sh ${WORKSPACE}/soe/artefacts/
#

#set -x

# Load common parameter variables
source scripts/common.sh

# has anything changed? If yes, then MODIFIED_CONTENT_FILE is not 0 bytes 
if [[ ! -s "${MODIFIED_RPMS_FILE}" ]]
then
    inform "No entries in ${MODIFIED_RPMS_FILE} no need to continue with $0"
    exit 0
fi

printf -v escaped_1 %q "${1}"

if [[ -z ${escaped_1} ]]
then
    usage "$0 <artefacts directory>"
    warn "the test zero length failed for ${escaped_1}"
    warn "you used $0 $@"
    exit ${NOARGS}
fi

if [[ ! -d "${1}" ]]
then
    usage "$0 <artefacts directory>"
    warn "the test directory exists failed for ${escaped_1}"
    warn "you used $0 $@"
    exit ${NOARGS}
fi

workdir=$1
printf -v escaped_workdir %q "${1}"

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]
then
    err "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# refresh the upstream yum repo
createrepo ${YUM_REPO}

# use hammer on the satellite to push the RPMs into the repo
# the ID of the ACME Test repository is 16
inform "Synchronize repository ID ${REPO_ID}"
ssh -q -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa ${SATELLITE} \
    "hammer repository synchronize --id ${REPO_ID}" || \
  { err "Repository '${REPO_ID}' couldn't be synchronized."; exit 1; }
