#!/bin/bash 

# Push Puppet Modules to satellite
#
# e.g. ${WORKSPACE}/scripts/puppetpush.sh 
#
# this should eventually be refactored to use Puppet Force and a repo synch on the satellite
# as rpmpush.sh does

. ${WORKSPACE}/scripts/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]
then
    echo "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

rsync -va -e "ssh -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa" -va \
    ${PUPPET_REPO} ${SATELLITE}:puppet
    
# use hammer on the satellite to push the modules into the repo
# the ID of the ACME Test repository is 16
ssh -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa ${SATELLITE} \
    "hammer repository upload-content --id ${PUPPET_REPO_ID} --path ./puppet"


