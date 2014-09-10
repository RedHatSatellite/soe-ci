#!/bin/bash

# Instruct Foreman to rebuild the test VMs
#
# e.g ${WORKSPACE}/scripts/buildtestvms.sh 'test'
#
# this will tell Foreman to rebuild all test* machines

#
. ${WORKSPACE}/scripts/common.sh

if [[ -z "$1" ]]
then
    echo "Usage: $0 <VM name pattern>"
    exit ${NOARGS}
fi
testvm=$1

# rebuild test VMs
for I in $(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer host list --search ${TESTVM_PATTERN} | tail -n +4 | head -n -1 | cut -f1 -d ' '")
do
    echo "Rebuilding VM ID $I"
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer host update --id $I --build yes"
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer host reboot --id $I"
done




