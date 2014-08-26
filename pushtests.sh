#!/bin/bash -x

# Push BATS tests to test VMs
#
# e.g ${WORKSPACE}/scripts/pushtests.sh 'test'
#

NOARGS=1

if [[ -z "$1" ]]
then
    echo "Usage: $0 <VM name pattern>"
    exit ${NOARGS}
fi
testvm=$1

# get our test machines
J=0
for I in $(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        'hammer host list --search ${testvm} | tail -3 | head -n -1 | cut -f3 -d " "')
do
  vm[$J]=$I
  ((J++))
done

# we need to wait until all the test machines have been rebuilt by foreman
REBUILT=0
WAIT=0
while [[ ${REBUILT} -lt ${#vm[@]} ]]
    do
    sleep 10
    ((WAIT+=10))
    echo "Waiting 10 seconds"
    for I in ${vm[@]}
    do
        echo -n "Checking if test server $I has rebuilt..."
        status=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host info --name $I | \
            grep -e \"Managed.*true\" -e \"Enabled.*true\" -e \"Build.*false\" | wc -l")
        if [[ ${status} == 3 ]]
        then
            echo "Success!"
            ((REBUILT++))
        else
            echo "Not yet"
        fi
    done
    if [[ ${WAIT} -gt 300 ]]
    then
        echo "Test servers still not rebuilt after 300 seconds. Exiting."
        exit 1
    fi
done

# Wait another 30s to be on the safe side
sleep 30

# copy our tests to the test servers
export SSH_ASKPASS=${WORKSPACE}/scripts/askpass.sh
for I in ${vm[@]}
do
    echo "Setting up ssh keys for test server $I"
    sed -i.bak "s/^$I.*//" ${KNOWN_HOSTS}
    setsid ssh-copy-id -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I
    echo "copying tests to test server $I"
    rsync -va -e "ssh -i ${RSA_ID}" ${WORKSPACE}/soe/tests \
        root@$I:
done

# execute the tests - this should be parallelised
mkdir -p ${WORKSPACE}/test_results
for I in ${vm[@]}
do
    echo "Installing BATS on test server $I"
    ssh -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I "yum install -y bats"
    echo "Running TAPS tests on test server $I"
    ssh -o StrictHostKeyChecking=no -i ${RSA_ID} root@$I \
        'cd tests ; bats -t *.bats' > ${WORKSPACE}/test_results/$I.tap
done

    