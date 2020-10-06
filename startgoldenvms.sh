#!/bin/bash

# Instruct Foreman to start the golden VMs (just in case they are off)
#
# e.g ${WORKSPACE}/scripts/startgoldenvms.sh 'test'
#
# this will tell Foreman to start all machines in hostgroup GOLDENVM_HOSTGROUP

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]  || [[ -z ${RSA_ID} ]] \
   || [[ -z ${ORG} ]] || [[ -z ${GOLDENVM_HOSTCOLLECTION} ]]
then
    err "Environment variable PUSH_USER, SATELLITE, RSA_ID, ORG " \
        "or GOLDENVM_HOSTCOLLECTION not set or not found."
    exit ${WORKSPACE_ERR}
fi

get_golden_vm_list # populate GOLDEN_VM_LIST

if [ $(echo ${#GOLDEN_VM_LIST[@]}) -eq 0 ]; then
  err "No golden VMs configured in Satellite"
  exit 1
fi

# rebuild golden VMs
for I in "${GOLDEN_VM_LIST[@]}"
do
    inform "Making sure VM ID $I is on"

    _PROBED_STATUS=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} "hammer host status --id $I" | grep Power | cut -f2 -d: | tr -d ' ')

    # different hypervisors report power status with different words. parse and get a single word per status
    # KVM uses running / shutoff
    # VMware uses poweredOn / poweredOff
    # add other hypervisors as you come across them and please submit to https://github.com/RedHatEMEA/soe-ci

    case "${_PROBED_STATUS}" in
      running)
        _STATUS=On
        ;;
      poweredOn)
        _STATUS=On
        ;;
      up)
        _STATUS=On
        ;;
      shutoff)
        _STATUS=Off
        ;;
      poweredOff)
        _STATUS=Off
        ;;
      down)
        _STATUS=Off
        ;;
      off)
        _STATUS=Off
        ;;
      *)
        echo "can not parse power status, please review $0"
    esac

    if [[ ${_STATUS} == 'On' ]]
    then
        inform "Host $I is already on."
    elif [[ ${_STATUS} == 'Off' ]]
    then
        inform "Host $I is already off, switching it on."
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host start --id $I"
    else
        err "Host $I is neither running nor shutoff. No action possible!"
        exit 1
    fi
done
