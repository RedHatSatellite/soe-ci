#!/bin/bash

# Instruct Foreman to rebuild the test VMs
#
# e.g ${WORKSPACE}/scripts/buildtestvms.sh 'test'
#
# this will tell Foreman to rebuild all machines in hostgroup TESTVM_HOSTGROUP

# Load common parameter variables
. $(dirname "${0}")/common.sh


# rebuild test VMs
for I in $(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer --output base content-host list --organization \"${ORG}\" \
		--host-collection \"$TESTVM_HOSTCOLLECTION\" \
            | awk -F': *' '$1 == \"Name\" {print $2}'")
do
    echo "Rebuilding VM ID $I"
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer host update --id $I --build yes"

    _STATUS=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} "hammer host status --id $I" | grep Power | cut -f2 -d: | tr -d ' ')
    if [[ ${_STATUS} == 'running' ]]
    then
        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host reboot --id $I"
    elif [[ ${_STATUS} == 'shutoff' ]]
    then
        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host start --id $I"
    else
        echo "Host $I is neither running nor shutoff. No action possible!"
        exit 1
    fi
done




