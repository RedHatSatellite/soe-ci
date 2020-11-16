#!/bin/bash

# Instruct Foreman to rebuild the VMs you wan to image (as in these will make your golden image)
#
# e.g ${WORKSPACE}/scripts/buildgoldenvms.sh 'test'
#
# this will tell Foreman to rebuild all machines in host collection GOLDENVM_HOSTCOLLECTION

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

# TODO: Error out if no golden VM's are available.
if [ $(echo ${#GOLDEN_VM_LIST[@]}) -eq 0 ]; then
  err "No golden VMs configured in Satellite"
fi

# rebuild golden VMs
for I in "${GOLDEN_VM_LIST[@]}"
do
    inform "Rebuilding VM ID $I"
    ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer host update --name $I --build yes"

    _PROBED_STATUS=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} "hammer host status --name $I" | grep Power | cut -f2 -d: | tr -d ' ')

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
        echo "can not parse power status, please review $0 for status ${_PROBED_STATUS}"
    esac

    if [[ ${_STATUS} == 'On' ]]
    then
        # forcefully poweroff the SUT
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host stop --force --name $I"
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host start --name $I"
    elif [[ ${_STATUS} == 'Off' ]]
    then
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host start --name $I"
    else
        err "Host $I is neither running nor shutoff. No action possible!"
        exit 1
    fi
done


# we need to wait until all the golden machines have been rebuilt by foreman
# this check was previously only in pushtests, but when using pipelines 
# it's more sensible to wait here while the machines are in build mode
# the ping and ssh checks must remain in pushtests.sh
# as a pupet only build will not call this script

declare -A vmcopy # declare an associative array to copy our VM array into
for I in "${GOLDEN_VM_LIST[@]}"; do vmcopy[$I]=$I; done

WAIT=0
while [[ ${#vmcopy[@]} -gt 0 ]]
do
    inform "Waiting 1 minute"
    sleep 60
    ((WAIT+=60))
    for I in "${vmcopy[@]}"
    do
        inform "Checking if host $I is in build mode."
        status=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host info --name $I | \
            grep -e \"Managed.*yes\" -e \"Enabled.*yes\" -e \"Build.*no\" \
                | wc -l")
        # Check if status is OK, then the SUT will have left build mode
        if [[ ${status} == 3 ]]
        then
            tell "host $I no longer in build mode."
            unset vmcopy[$I]
        else
            tell "host $I is still in build mode."
        fi
    done
    if [[ ${WAIT} -gt 6000 ]]
    then
        err "At least one host still in build mode after 6000 seconds. Exiting."
        exit 1
    fi
done

inform "A host that exited build mode is given 3 minutes to finish anaconda cleanly"
sleep 180
