#!/bin/bash 

# Clean-up the Jenkins Workspace after a successful build
#
# e.g. ${WORKSPACE}/scripts/cleanup.sh
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ ! -n "${WORKSPACE}" || ! -d "${WORKSPACE}" ]]
then
    err "Variable 'WORKSPACE' undefined or set to non existing '${WORKSPACE}'."
    exit ${WORKSPACE_ERR}
fi

# We delete the list of modified contents only once a build has been
# successful, or we might not test all changes done.
# If a build is unstable, the failed test(s) should at least tell us which
# content needs amendment.
rm -fv "${MODIFIED_CONTENT_FILE}"
rm -fv "${MODIFIED_RPMS_FILE}"
rm -fv "${MODIFIED_PUPPET_FILE}"

