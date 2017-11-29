#!/bin/bash

# While a Capsule Sync is in progress, we must wait
# as the System Under Test (SUT) may be behind a Capsule

#set -x

# Load common parameter variables
source scripts/common.sh


# how long do we wait
# 30 minutes is 1800 seconds
# 4 hours is 14400 seconds
MAX_SYNC_WAIT=14400

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]  || [[ -z ${RSA_ID} ]] \
   || [[ -z ${ORG} ]] || [[ -z ${TESTVM_HOSTCOLLECTION} ]]
then
    err "Environment variable PUSH_USER, SATELLITE, RSA_ID, ORG " \
        "or TESTVM_HOSTCOLLECTION not set or not found."
    exit ${WORKSPACE_ERR}
fi

count_capsule_syncs_in_progress()
{
  _CAPSULE_SYNC_COUNT=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} "hammer --csv task list --search 'state = running and label ~  CapsuleGenerateAndSync'" | tail -n +2 | wc -l)
}

inform "Checking if there is a Capsule Sync in progress"
count_capsule_syncs_in_progress
if [[ ${_CAPSULE_SYNC_COUNT} -gt 0 ]]
then
  _CHECKING_SINCE=$(date)
  WAIT=0
  warn "${_CAPSULE_SYNC_COUNT} sync jobs to capsules in progress"
  while [[ ${_CAPSULE_SYNC_COUNT} -gt 0 ]]
  do
    if [[ ${WAIT} -gt ${MAX_SYNC_WAIT} ]]
    then
	    err "Capsules seem to still be syncing after ${MAX_SYNC_WAIT} seconds. Exiting."
	    err "It is most strongly recommended you look into why your capsules are still syncing after such a long wait."
	    exit 1
    fi
    inform "Will check again in 5 minutes"
    inform "We have been checking since ${_CHECKING_SINCE}"
    sleep 300
    ((WAIT+=300))
    count_capsule_syncs_in_progress
    warn "${_CAPSULE_SYNC_COUNT} sync jobs to capsules still running"
  done
else
  inform "No sync jobs to capsules in progress"
fi
