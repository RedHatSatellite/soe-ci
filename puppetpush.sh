#!/bin/bash 

# Push Puppet Modules to satellite
#
# e.g. ${WORKSPACE}/scripts/puppetpush.sh 
#
# this should eventually be refactored to use a Pulp repo sync on the satellite
# as rpmpush.sh does

. ${WORKSPACE}/scripts/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]
then
    echo "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# Refresh the PULP_MANIFEST
cd ${PUPPET_REPO}
rm PULP_MANIFEST
touch PULP_MANIFEST
for I in *.tar.gz
do
    size=$(du -b ${I} | awk '{print $1}')
    sha256=$(sha256sum ${I} | awk '{print $1}')
    echo "${I},${sha256},${size}" >> PULP_MANIFEST
done

    
    
# use hammer on the satellite to push the modules into the repo
# the ID of the ACME Test repository is 16
ssh -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa ${SATELLITE} \
    "hammer repository synchronize --id ${PUPPET_REPO_ID}"


