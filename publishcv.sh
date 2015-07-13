#!/bin/bash -x

# Publish the content view and promote if necessary

# Load common parameter variables
. $(dirname "${0}")/common.sh

ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view publish --name \"${CV}\" --organization \"${ORG}\" --description \"Build ${BUILD_URL}\"" || \
	{ err "Content view '${CV}' couldn't be published."; exit 1; }

# sleep after publishing content view to give chance for locks to get cleared up
sleep 90

# get the latest version of the CV
VER=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
	"hammer content-view info --name \"${CV}\" --organization \"${ORG}\" \
	| grep \"ID:\" | tail -1 | tr -d ' ' | cut -f2 -d ':'")

if [[ -n ${CCV_NAME_PATTERN} ]]
then # we want to update and publish all CCVs containing our CV
    # Create an array of content view version IDs
    CV_VER_IDS=( $(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer --csv content-view version list --content-view \"${CV}\" --organization \"${ORG}\"" | awk -F',' '$1 != "ID" {print $1}') )
    # Create an array of composite content view IDs matching the given pattern
    CCV_TMP_IDS=( $(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer --csv content-view list --organization \"${ORG}\" --search \"${CCV_NAME_PATTERN}\"" | awk -F, '$1 ~ /^[0-9]+$/ {print $1}') )

    # We need at the same time to find out which of the CCVs use the given CV
    # as well as keep the ID of all other used CV versions, but filter out
    # the currently used version of our CV, to avoid two versions of the same CV
    for ccv_id in ${CCV_TMP_IDS[@]}
    do
	cv_used_ver_ids=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer --output yaml content-view info --id ${ccv_id} --organization \"${ORG}\"" \
	| awk -v cv="${CV}" -v cvver="${CV_VER_IDS[*]}" -F': *' '
	BEGIN { split(cvver,cvv," ");
		for (ver in cvv) cv_versions[cvv[ver]]=ver}
	$1 == "Components" {cmp = 1; next}
	{if (!cmp) next}
	/^[A-Z]/ {cmp = 0; next}
	$1 ~ / *ID/ {
		if ($2 in cv_versions) {
			ccv = 1;
		} else {
			ids=$2 "," ids;
		}
	}
	END {if (ccv) {print ids} else {exit 3}}')
        rc=$?
        if [[ ${rc} -ne 3 ]]
        then # the CCV really uses the given CV in any version
            CCV_IDS=( "${CCV_IDS[@]}" ${ccv_id} )
            CV_USED_VER_IDS=( "${CV_USED_VER_IDS[@]}" "${cv_used_ver_ids}" )
        fi
    done
fi

# We update the found CCVs with the new version and publish them
if [[ ${#CCV_IDS[*]} -gt 0 ]]
then # there is at least one CCV using the given CV
    for (( i = 0; i < ${#CCV_IDS[@]}; i++ ))
    do
            ccv_id=${CCV_IDS[$i]}
            cv_used_ver_ids=${CV_USED_VER_IDS[$i]}

            # we add back the CV under its latest version to the CCV
	    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
                "hammer content-view update --id ${ccv_id} --component-ids "${cv_used_ver_ids}${VER}" --organization \"${ORG}\"" || \
	            { err "CCV '${ccv_id}' couldn't be updated with '${cv_used_ver_ids}${VER}'."; exit 1; }

            # sleep after updating CV for locks to get cleared up
            sleep 10

            # And then we publish the updated CCV
            ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
                "hammer content-view publish --id \"${ccv_id}\" --organization \"${ORG}\" --description \"Build ${BUILD_URL}\"" || \
	            { err "CCV '${ccv_id}' couldn't be published."; exit 1; }
    done
fi

if [[ -n ${TESTVM_ENV} ]]
then
    # promote the latest version of the CV
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view version promote --content-view \"${CV}\" --organization \"${ORG}\" \
    --to-lifecycle-environment-id \"${TESTVM_ENV}\" --id ${VER}"

    # we also promote the latest version of each CCV
    for ccv_id in ${CCV_IDS[@]}
    do
        ccv_ver=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer --csv content-view version list --content-view-id ${ccv_id} --organization \"${ORG}\"" | awk -F',' '$1 ~ /^[0-9]+$/ {if ($3 > maxver) {maxver = $3; maxid = $1} } END {print maxid}')
        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer content-view version promote --content-view-id \"${ccv_id}\" --organization \"${ORG}\" \
        --to-lifecycle-environment-id \"${TESTVM_ENV}\" --id ${ccv_ver}"
    done
fi
