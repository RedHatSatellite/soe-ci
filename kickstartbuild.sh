#!/bin/bash

# Search for kickstarts
#
# e.g. ${WORKSPACE}/scripts/kickstartbuild.sh ${WORKSPACE}/soe/kickstarts/ 
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    usage "$0 <directory containing kickstart files>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${WORKSPACE} ]] || [[ ! -w ${WORKSPACE} ]]
then
    err "Environment variable 'WORKSPACE' not set or not found"
    exit ${WORKSPACE_ERR}
fi

# setup artefacts environment
ARTEFACTS=${WORKSPACE}/artefacts/kickstarts

# copy erb files from one directory to the next, creating directory if needed
rsync -td --out-format="#%n#" --delete-excluded --include=*.erb --exclude=* \
	"${workdir}/" "${ARTEFACTS}" \
	| grep -e '\.erb#$' | tee -a "${MODIFIED_CONTENT_FILE}"
