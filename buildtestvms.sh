#!/bin/bash

# Instruct Foreman to rebuild the test VMs
#
# e.g ${WORKSPACE}/scripts/buildtestvms.sh 'test'
#
# this will tell Foreman to rebuild all machines in hostgroup TESTVM_HOSTGROUP

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]  || [[ -z ${RSA_ID} ]] \
   || [[ -z ${ORG} ]] || [[ -z ${TESTVM_HOSTCOLLECTION} ]]
then
    err "Environment variable PUSH_USER, SATELLITE, RSA_ID, ORG " \
        "or TESTVM_HOSTCOLLECTION not set or not found."
    exit ${WORKSPACE_ERR}
fi

get_test_vm_list # populate TEST_VM_LIST

# rebuild test VMs
for I in "${TEST_VM_LIST[@]}"
do
    info "Rebuilding VM ID $I"
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer host update --id $I --build yes"

    _STATUS=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} "hammer host status --id $I" | grep Power | cut -f2 -d: | tr -d ' ')
    if [[ ${_STATUS} == 'running' ]]
    then
        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host stop --id $I"
        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host start --id $I"
    elif [[ ${_STATUS} == 'shutoff' ]]
    then
        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host start --id $I"
    else
        err "Host $I is neither running nor shutoff. No action possible!"
        exit 1
    fi
done

