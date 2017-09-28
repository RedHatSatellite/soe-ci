#!/bin/bash

# power off the test VMs
# hammer (without the --force flag) will attempt a clean shutdown
#
# e.g ${WORKSPACE}/scripts/powerofftestvms.sh 'test'
#

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

# TODO: Error out if no test VM's are available.
if [ $(echo ${#TEST_VM_LIST[@]}) -eq 0 ]; then
  err "No test VMs configured in Satellite"
fi

# shutdown test VMs
for I in "${TEST_VM_LIST[@]}"
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
        # exit 0 while testingi for issue  #50,
        # allows for manual rebooting of the test VM(s)
        exit 0
    fi
done
