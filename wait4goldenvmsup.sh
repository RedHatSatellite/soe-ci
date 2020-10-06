#!/bin/bash -x

# Wait for golden VMs to be up (is run by pipeline before shutdowngoldenvms.sh)
#
# e.g ${WORKSPACE}/scripts/wait4goldenvmsup.sh 'test'
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

get_golden_vm_list # populate GOLDEN_VM_LIST

# If buildgoldenvms.sh ended cleanly but the VMs remain powered up, then
# we need to wait until all the machines are up and can be ssh-ed to.
# Only then will we tell the hypervisor (via Satellite) to shut down cleanly 
# with a pipeline step shutdowngoldenvms.sh
declare -A vmcopy # declare an associative array to copy our VM array into
for I in "${GOLDEN_VM_LIST[@]}"; do vmcopy[$I]=$I; done

WAIT=0
while [[ ${#vmcopy[@]} -gt 0 ]]
do
    inform "Waiting 15 seconds"
    sleep 15
    ((WAIT+=15))
    for I in "${vmcopy[@]}"
    do
        inform "Checking if golden VM $I has rebooted into OS before next pipeine step attemopts clean shutdown."
        status=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host info --name $I | \
            grep -e \"Managed.*yes\" -e \"Enabled.*yes\" -e \"Build.*no\" \
		| wc -l")
        # Check if status is OK, ping reacts and SSH is there, then success!
        if [[ ${status} == 3 ]] && ping -c 1 -q $I && nc -w 1 $I 22
        then
            tell "Success!"
            unset vmcopy[$I]
        else
            tell "Not yet."
        fi
    done
    if [[ ${WAIT} -gt 6000 ]]
    then
        err "Golden VM not reachable via ssh after 6000 seconds. Exiting."
        exit 1
    fi
done

# Wait another 30s to be on the safe side
sleep 30

# since a golden VM is meant to be imaged, do NOT do anything else here.