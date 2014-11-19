#!/bin/bash -x

# Publish the content view and promote if necessary

. ${WORKSPACE}/scripts/common.sh

ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view publish --name \"${CV}\" --organization \"${ORG}\""

if [[ -n ${TESTVM_ENV} ]]
then
# get the latest version of the CV and promote it
    VER=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view info --name \"${CV}\" --organization \"${ORG}\" \
    | grep \"Version:\" | tail -1 | tr -d ' ' | cut -f2 -d ':'")
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view version promote --content-view \"${CV}\" --organization \"${ORG}\" \
    --lifecycle-environment-id \"${TESTVM_ENV}\" --id ${VER}"
fi

