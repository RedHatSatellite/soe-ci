#!/bin/bash

# Search for kickstarts
#
# e.g. ${WORKSPACE}/scripts/kickstartbuild.sh ${WORKSPACE}/soe/kickstarts/ 
#

#set -x

# Load common parameter variables
source scripts/common.sh

printf -v escaped_1 %q "${1}"

if [[ -z ${escaped_1} ]]
then
    usage "$0 <directory containing kickstart files>"
    warn "the test zero length failed for ${escaped_1}"
    warn "you used $0 $@"
    exit ${NOARGS}
fi

if [[ ! -d "${1}" ]]
then
    usage "$0 <directory containing kickstart files>"
    warn "the test directory exists failed for ${1}"
    warn "you used $0 $@"
    exit ${NOARGS}
fi

workdir=$1
printf -v escaped_workdir %q "${1}"
printf -v escaped_WORKSPACE %q "${WORKSPACE}"

if [[ -z ${WORKSPACE} ]] || [[ ! -w ${WORKSPACE} ]]
then
    err "Environment variable 'WORKSPACE' not set or not found"
    exit ${WORKSPACE_ERR}
fi

# setup artefacts environment
ARTEFACTS="${WORKSPACE}/artefacts/kickstarts"
mkdir -p "${ARTEFACTS}"

# copy erb files from one directory to the next, creating directory if needed
rsync -td --out-format="#%n#" --delete-excluded --include=*.erb --exclude=* \
	"${workdir}/" "${ARTEFACTS}" \
	| grep -e '\.erb#$' | tee -a "${MODIFIED_CONTENT_FILE}"
