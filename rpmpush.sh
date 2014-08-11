#!/bin/bash -x

# Push RPMs to satellite
#
# e.g. ${WORKSPACE}/scripts/rpmpush.sh ${WORKSPACE}/soe/artefacts/
#
NOARGS=1
WORKSPACE_ERR=5

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    echo "Usage: $0 <artefacts directory>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${PUSH_USER} ]] || [[ ! -z ${SATELLITE} ]]
then
    echo "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

rsync -va ${workdir}/{debug-rpms,rpms,srpms} ${PUSH_USER}@${SATELLITE}:


