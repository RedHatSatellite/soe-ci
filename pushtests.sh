#!/bin/bash

# Push BATS tests to test VMs
#
# e.g ${WORKSPACE}/scripts/pushtests.sh 'test'
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

get_test_vm_list # populate TEST_VM_LIST

# we need to wait until all the test machines are up and can be ssh-ed to
declare -A vmcopy # declare an associative array to copy our VM array into
for I in "${TEST_VM_LIST[@]}"; do vmcopy[$I]=$I; done

WAIT=0
while [[ ${#vmcopy[@]} -gt 0 ]]
do
    inform "Waiting 15 seconds"
    sleep 15
    ((WAIT+=15))
    for I in "${vmcopy[@]}"
    do
        inform "Checking if test server $I has rebooted into OS so that tests can be run."
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
        err "Test servers still not rebuilt after 6000 seconds. Exiting."
        exit 1
    fi
done

# Wait another 30s to be on the safe side
sleep 30

# copy our tests to the test servers
export SSH_ASKPASS=${WORKSPACE}/scripts/askpass.sh
export DISPLAY=nodisplay
export TEST_ROOT
for I in ${TEST_VM_LIST[@]}
do
    # Check the host's entitlements
    inform "Checking entitlements for test server $I"
    ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer content-host info --name ${I} --organization \"${ORG}\""

    inform "Setting up ssh keys for test server $I"
    sed -i.bak "/^$I[, ]/d" ${KNOWN_HOSTS} # remove test server from the file

    # Copy Jenkins' SSH key to the newly created server(s)
    if [ $(sed -e 's/^.*release //' -e 's/\..*$//' /etc/redhat-release) -ge 7 ]
    then # Only starting with RHEL 7 does ssh-copy-id support -o parameter
        setsid ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I
    else # Workaround for RHEL 6 and before
        setsid ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I 'true'
        setsid ssh-copy-id -i ${RSA_ID} root@$I
    fi

    inform "Probing subscription status on test server $I"
    ssh -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I "subscription-manager status"

    # if the repolist does not contain whet you expect, switch off auto-attach on the used activation-key
    inform "Listing repos on test server $I"
    ssh -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I "subscription-manager repos"
    
    # copy puppet-done-test.sh to SUT
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} \
        ${WORKSPACE}/scripts/puppet-done-test.sh root@$I:

    # wait for puppet to finish
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I \
        "/root/puppet-done-test.sh"

    inform "Installing bats and rsync on test server $I"
    if ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I \
        "yum install -y bats rsync"
    then
        inform "copying tests to test server $I"
        rsync --delete -va -e \
            "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID}" \
            ${WORKSPACE}/soe/tests root@$I:
    else
        err "Couldn't install rsync and bats on '$I'."
        exit 1
    fi
done

# execute the tests in parallel on all test servers
mkdir -p ${WORKSPACE}/test_results
for I in ${TEST_VM_LIST[@]}
do
    inform "Starting TAPS tests on test server $I"
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I \
        'cd tests ; bats -t *.bats' > ${WORKSPACE}/test_results/$I.tap &
done

# wait until all backgrounded processes have exited
wait
