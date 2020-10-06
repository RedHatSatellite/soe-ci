#!/bin/bash

# power off the golden VMs
# hammer (without the --force flag) will attempt a clean shutdown
#
# e.g ${WORKSPACE}/scripts/poweroffgoldenvms.sh 'test'
#

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

# shutdown golden VMs
for I in "${GOLDEN_VM_LIST[@]}"
do
    inform "Checking status of VM ID $I"

    _PROBED_STATUS=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} "hammer host status --id $I" | grep Power | cut -f2 -d: | tr -d ' ')

    # different hypervisors report power status with different words. parse and get a single word per status
    # KVM uses running / shutoff
    # VMware uses poweredOn / poweredOff
    # libvirt uses running / off
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

    # n.b. kickstart can either reboot or power down at the end, so we must handle both cases
    if [[ ${_STATUS} == 'On' ]]
    then
        inform "Shutting down VM ID $I"
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host stop --id $I"
    elif [[ ${_STATUS} == 'Off' ]]
    then
        inform "VM ID $I seems off already, no action done."
    else
        err "Host $I is neither running nor shutoff. No action possible!"
        exit 1
    fi
done
