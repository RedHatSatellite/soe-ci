#!/bin/bash 

# Push Puppet Modules to satellite
#
# e.g. ${WORKSPACE}/scripts/puppetpush.sh ${WORKSPACE}/soe/artefacts/
#
. ${WORKSPACE}/scripts/common.sh

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    echo "Usage: $0 <artefacts directory>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]
then
    echo "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# We delete extraneous modules on the satellite so that we don't keep pushing the same modules into the repo
rsync --delete -va -e "ssh -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa" -va \
    ${workdir}/puppet/*.tar.gz ${SATELLITE}:puppet
    
# use hammer on the satellite to push the RPMs into the repo
# the ID of the ACME Test repository is 16
ssh -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa ${SATELLITE} \
    "hammer repository upload-content --id ${REPO_ID} --path ./puppet"


