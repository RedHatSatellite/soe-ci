#!/bin/bash -x

# promote the content view(s) from TESTVM_ENV to GOLDENVM_ENV

# Load common parameter variables
. $(dirname "${0}")/common.sh

# If MODIFIED_CONTENT_FILE is not 0 bytes, then publishcv.sh has
# attempted a (C)CV publish step plus a promotion to LCE TESTVM_ENV
# thus we can promote to GOLDENVM_ENV now
# (since this script is called by a pipelline step that is only executed if the prior steps did NOT fail)
if [[ ! -s "${MODIFIED_CONTENT_FILE}" ]]
then
    echo "No entries in ${MODIFIED_CONTENT_FILE} no need to continue with $0"
    exit 0
fi

# Create an array from all the content view names
oldIFS="${IFS}"
i=0
IFS=','
for cv in ${CV} ${CV_PASSIVE_LIST}
do
        CV_LIST[$i]="${cv}"
        ((i++))
done
IFS="${oldIFS}"

# Get a list of all CV version IDs
for cv in "${CV_LIST[@]}"
do
    # get the latest version of each CV, add it to the array
    inform "Get the latest version of CV ${cv}"
    VER_ID_LIST+=( "$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
	"hammer content-view info --name \"${cv}\" --organization \"${ORG}\" \
	| sed -n \"/Versions:/,/Components:/p\" | grep \"ID:\" | tr -d ' ' | cut -f2 -d ':' | sort -n | tail -n 1")" )
done

if [[ -n ${GOLDENVM_ENV} ]]
then
    for (( i = 0; i < ${#CV_LIST[@]}; i++ ))
    do # promote the latest version of each CV
        cv=${CV_LIST[$i]}
        ver_id=${VER_ID_LIST[$i]}

        inform "Promoting version ID ${ver_id} of ${cv} to LCE ${GOLDENVM_ENV}"
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer content-view version promote --content-view \"${cv}\" --organization \"${ORG}\" \
        --to-lifecycle-environment-id \"${GOLDENVM_ENV}\" --force --id ${ver_id}"
    done

    # we also promote the latest version of each CCV
    for ccv_id in ${CCV_IDS[@]}
    do
        ccv_ver=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer --csv content-view version list --content-view-id ${ccv_id} --organization \"${ORG}\"" | awk -F',' '$1 ~ /^[0-9]+$/ {if ($3 > maxver) {maxver = $3; maxid = $1} } END {print maxid}')
        inform "Promoting version ${ccv_ver} of CCV ID ${ccv_id} to LCE ${GOLDENVM_ENV}"
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer content-view version promote --content-view-id \"${ccv_id}\" --organization \"${ORG}\" \
        --to-lifecycle-environment-id \"${GOLDENVM_ENV}\" --force --id ${ccv_ver}"
    done
fi
