#!/bin/bash -x

# Publish the content view and promote if necessary

# Load common parameter variables
. $(dirname "${0}")/common.sh

ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view publish --name \"${CV}\" --organization \"${ORG}\""
# sleep 30s after publishing content view to give change for locks to get cleared up
sleep 30
if [[ -n ${TESTVM_ENV} ]]
then
# get the latest version of the CV and promote it
    VER=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view info --name \"${CV}\" --organization \"${ORG}\" \
    | grep \"ID:\" | tail -1 | tr -d ' ' | cut -f2 -d ':'")
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view version promote --content-view \"${CV}\" --organization \"${ORG}\" \
    --lifecycle-environment-id \"${TESTVM_ENV}\" --id ${VER}"
fi

