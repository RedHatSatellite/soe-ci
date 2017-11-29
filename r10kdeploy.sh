#!/bin/bash
 
# Push Puppet Modules out via r10k
#
# e.g. ${WORKSPACE}/scripts/r10kdeploy.sh
#
 
source scripts/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]] || [[ -z ${R10K_USER} ]]
then
    err "PUSH_USER, R10K_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi
 
# use hammer on the satellite to push the modules into the repo
for I in $(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer --csv capsule list" | tail -n +2 | awk -F, '{print $2}')
do
    ssh -l ${R10K_USER} -i ${RSA_ID} ${I} \
        "cd /etc/puppet ; r10k deploy environment ${R10K_ENV} -pv"
done
