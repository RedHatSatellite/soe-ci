#!/bin/bash

# Push Templates to satellite
#
# e.g. ${WORKSPACE}/scripts/kickstartpush.sh ${WORKSPACE}/artefacts/kickstarts/
#

#set -x

# Load common parameter variables
source scripts/common.sh

printf -v escaped_1 %q "${1}"

if [[ -z ${escaped_1} ]]
then
    usage "$0 <kickstarts directory>"
    warn "the test zero length failed for ${escaped_1}"
    warn "you used $0 $@"
    exit ${NOARGS}
fi

if [[ ! -d "${1}" ]]
then
    usage "$0 <kickstarts directory>"
    warn "the test directory exists failed for ${1}"
    warn "you used $0 $@"
    exit ${NOARGS}
fi

workdir=$1
printf -v escaped_workdir %q "${1}"

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]
then
    err "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# We delete extraneous kickstarts on the satellite so that we don't keep pushing the same kickstarts into foreman
rsync --delete -va -e "ssh -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa" -va \
    "${workdir}/kickstarts/" ${SATELLITE}:kickstarts

# either update or create each kickstart in turn
cd "${workdir}/kickstarts"
for I in *.erb
do
    name=$(sed -n 's/^name:\s*\(.*\)/\1/p' ${I})
    id=0
    id=$(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "/usr/bin/hammer --csv template list --per-page 9999" | grep "${name}" | cut -d, -f1)
    ttype=$(sed -n 's/^kind:\s*\(.*\)/\1/p' ${I})
    if [[ ${id} -ne 0 ]]
    then
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} /usr/bin/hammer template update --id ${id} --file kickstarts/${I} --type ${ttype}
    else
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "/usr/bin/hammer template create --file kickstarts/${I} --name \"${name}\" --type ${ttype} --organizations \"${ORG}\""
    fi
done
