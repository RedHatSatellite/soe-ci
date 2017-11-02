#!/bin/bash

# common stuff

# Error states
NOARGS=1
GITVER_ERR=2
GITREV_ERR=3
RPMBUILD_ERR=4
WORKSPACE_ERR=5
SRPMBUILD_ERR=6
MODBUILD_ERR=7

function tell() {
	echo "${@} [$(date)]" | fold --spaces --width=240
}

function inform() {
	tell "INFO:    ${@}"
}

function usage() {
	tell "USAGE:   ${@}"
}

function warn() {
	tell "WARNING: ${@}" >&2
}

function err() {
	tell "ERROR:   ${@}" >&2
}

# Name of file where modified content artefacts are being tracked
# This approach (and file) is only used if CONDITIONAL_VM_BUILD is 'true'
MODIFIED_CONTENT_FILE=${WORKSPACE}/modified_content.track

# as the above tracks RPMs and puppet modules in the same file,
# introduce 2 more tracking files
MODIFIED_RPMS_FILE=${WORKSPACE}/modified_rpms.track
MODIFIED_PUPPET_FILE=${WORKSPACE}/modified_puppet.track

# get our test machines into an array variable TEST_VM_LIST
function get_test_vm_list() {
	local J=0
	for I in $(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
		"hammer host-collection hosts --organization \"${ORG}\" \
			--name \"$TESTVM_HOSTCOLLECTION\" \
		| tail -n +4 | cut -f2 -d \"|\" | head -n -1")
	do
		# If CONDITIONAL_VM_BUILD is 'true', only keep VMs commented
		# with modified #content# as listed in $MODIFIED_CONTENT_FILE
		# If the file is empty or doesn't exist, we test everything
		# as it hints at a script change.
		if [[ "${CONDITIONAL_VM_BUILD}" != 'true' ]] || \
			[[ ! -s "${MODIFIED_CONTENT_FILE}" ]] || \
			ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
			"hammer --output yaml host info --name \"${I}\"" \
				| grep "^Comment:" \
				| grep -Fqf "${MODIFIED_CONTENT_FILE}"
		then
			TEST_VM_LIST[$J]=$I
			((J+=1))
		fi
	done
}
