#!/bin/bash 

# Push RPMs to satellite
#
# e.g. ${WORKSPACE}/scripts/rpmpush.sh ${WORKSPACE}/soe/artefacts/
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
    
# scrub the srpms and mock build logs as they confuse satellite6
rm ${YUM_REPO}/*.src.rpm
rm ${YUM_REPO}/*.log
    
# refresh the upstream yum repo
createrepo ${YUM_REPO}
    
# use hammer on the satellite to push the RPMs into the repo
# the ID of the ACME Test repository is 16
ssh -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa ${SATELLITE} \
    "hammer repository synchronize --id ${REPO_ID}"
    


