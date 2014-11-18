#!/bin/bash

# Instruct Foreman to rebuild the test VMs
#
# e.g ${WORKSPACE}/scripts/buildtestvms.sh 'test'
#
# this will tell Foreman to rebuild all test* machines

#
. ${WORKSPACE}/scripts/common.sh


# rebuild test VMs
for I in $(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer host list --search 'hostgroup = \"${TESTVM_HOSTGROUP}\"' | grep \"${TESTVM_HOSTGROUP}\" | 
        cut -f2 -d \"|\" | tr -d ' ' ")
do
    echo "Rebuilding VM ID $I"
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer host update --id $I --build yes"
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer host reboot --id $I"
done




