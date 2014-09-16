#!/bin/bash 

# Push Templates to satellite
#
# e.g. ${WORKSPACE}/scripts/kickstartpush.sh ${WORKSPACE}/artefacts/kickstarts/
#
. ${WORKSPACE}/scripts/common.sh

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    echo "Usage: $0 <kickstarts directory>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]
then
    echo "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# We delete extraneous kickstarts on the satellite so that we don't keep pushing the same kickstarts into foreman
rsync --delete -va -e "ssh -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa" -va \
    ${workdir}/kickstarts/ ${SATELLITE}:kickstarts
    
# either update or create each kickstart in turn
ssh -l ${PUSH_USER} -i /var/lib/jenkins/.ssh/id_rsa ${SATELLITE} <<EOF
cd kickstart
for I in *.erb
do
name=$(sed -n 's/^name:\s*\(.*\)/\1/p' ${I})
id=0
id=$(hammer --csv template list --per-page 9999 | grep "${name}" cut -d, -f1)
if [[ ${id} != 0 ]]
then
hammer template update --id ${id} ${I}
else
type=$(sed -n 's/^kind:\s*\(.*\)/\1/p' ${I})
hammer template create --file ${I} --name "${name}" --type ${kind}
fi
done
EOF


