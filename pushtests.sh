#!/bin/bash -x

# Push BATS tests to test VMs
#
# e.g ${WORKSPACE}/scripts/pushtests.sh 'test'
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

get_test_vm_list # populate TEST_VM_LIST

# we need to wait until all the test machines have been rebuilt by foreman
declare -A vmcopy # declare an associative array to copy our VM array into
for I in "${TEST_VM_LIST[@]}"; do vmcopy[$I]=$I; done

WAIT=0
while [[ ${#vmcopy[@]} -gt 0 ]]
do
    sleep 10
    ((WAIT+=10))
    info "Waiting 10 seconds"
    for I in "${vmcopy[@]}"
    do
        echo -n "Checking if test server $I has rebuilt... "
        status=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host info --name $I | \
            grep -e \"Managed.*true\" -e \"Enabled.*true\" -e \"Build.*false\" \
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
    info "Setting up ssh keys for test server $I"
    sed -i.bak "/^$I[, ]/d" ${KNOWN_HOSTS} # remove test server from the file

    # Copy Jenkins' SSH key to the newly created server(s)
    if [ $(sed -e 's/^.*release //' -e 's/\..*$//' /etc/redhat-release) -ge 7 ]
    then # Only starting with RHEL 7 does ssh-copy-id support -o parameter
        setsid ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I
    else # Workaround for RHEL 6 and before
        setsid ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I 'true'
        setsid ssh-copy-id -i ${RSA_ID} root@$I
    fi

    # copy puppet-done-test.sh to SUT
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} \
        ${WORKSPACE}/scripts/puppet-done-test.sh root@$I:

    # wait for puppet to finish
    ssh -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I \
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I \
        "/root/puppet-done-test.sh"

    info "Installing bats and rsync on test server $I"
    if ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I \
        "yum install -y bats rsync"
    then
        info "copying tests to test server $I"
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
    info "Starting TAPS tests on test server $I"
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I \
        'cd tests ; bats -t *.bats' > ${WORKSPACE}/test_results/$I.tap &
done

# wait until all backgrounded processes have exited
wait
