#!/bin/bash

# While a Capsule Sync is in progress, we must wait
# as the System Under Test (SUT) may be behind a Capsule

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]  || [[ -z ${RSA_ID} ]] \
   || [[ -z ${ORG} ]] || [[ -z ${TESTVM_HOSTCOLLECTION} ]]
then
    err "Environment variable PUSH_USER, SATELLITE, RSA_ID, ORG " \
        "or TESTVM_HOSTCOLLECTION not set or not found."
    exit ${WORKSPACE_ERR}
fi

count_capsule_syncs_in_progress()
{
  _CAPSULE_SYNC_COUNT=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} "hammer --csv task list --search 'state = running and label =  Actions::Katello::ContentView::CapsuleGenerateAndSync'" | tail -n +2 | wc -l)
}

info "Checking if there is a Capsule Sync in progress"
count_capsule_syncs_in_progress
if [[ ${_CAPSULE_SYNC_COUNT} -gt 0 ]]
then
  _CHECKING_SINCE=$(date)
  warn "${_CAPSULE_SYNC_COUNT} sync jobs to capsules in progress"
  while [[ ${_CAPSULE_SYNC_COUNT} -gt 0 ]]
  do
    inform "Will check again in 5 minutes"
    inform "We have been checking since      ${_CHECKING_SINCE}"
    sleep 300
    count_capsule_syncs_in_progress
    warn "${_CAPSULE_SYNC_COUNT} sync jobs to capsules still running"
  done
else
  info "No sync jobs to capsules in progress"
fi
