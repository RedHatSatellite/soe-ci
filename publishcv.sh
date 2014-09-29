#!/bin/bash 

# Publish the content view

. ${WORKSPACE}/scripts/common.sh

ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view publish --name \"${CV}\" --organization \"${ORG}\""


