#!/bin/bash

# Search for kickstarts
#
# e.g. ${WORKSPACE}/scripts/kickstartbuild.sh ${WORKSPACE}/soe/kickstarts/ 
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    usage "$0 <directory containing puppet module directories>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${WORKSPACE} ]] || [[ ! -w ${WORKSPACE} ]]
then
    err "WORKSPACE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# setup artefacts environment 
ARTEFACTS=${WORKSPACE}/artefacts/kickstarts
rm -f ${ARTEFACTS}/*.erb
mkdir -p ${ARTEFACTS}

cp ${workdir}/*.erb ${ARTEFACTS}


