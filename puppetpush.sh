#!/bin/bash

# Push Puppet Modules to satellite via a Pulp repo
#
# e.g. ${WORKSPACE}/scripts/puppetpush.sh
#

# Load common parameter variables
source scripts/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]
then
    err "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# has anything changed? If yes, then MODIFIED_CONTENT_FILE is not 0 bytes 
if [[ ! -s "${MODIFIED_PUPPET_FILE}" ]]
then
    echo "No entries in ${MODIFIED_PUPPET_FILE} no need to continue with $0"
    exit 0
fi

# Refresh the PULP_MANIFEST
cd ${PUPPET_REPO}
rm PULP_MANIFEST
touch PULP_MANIFEST
for I in *.tar.gz
do
    size=$(du -b ${I} | awk '{print $1}')
    sha256=$(sha256sum ${I} | awk '{print $1}')
    echo "${I},${sha256},${size}" >> PULP_MANIFEST
done



# use hammer on the satellite to push the modules into the repo
ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer repository synchronize --id ${PUPPET_REPO_ID}" || \
  { err "Repository '${PUPPET_REPO_ID}' couldn't be synchronized."; exit 1; }

if [[ -z "${CV}" ]]
then
    inform "Variable 'CV' empty, no need to attach new modules."
    exit 0
fi

# we need to add any new modules into the CV
# as unlike RPMs they are not picked up automatically by republishing the CV

# list all the packages currently in the CV
n=0
for I in $(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer --csv content-view puppet-module list --content-view=\"${CV}\" --organization=\"${ORG}\"" | tail -n +2 | awk -F, '{printf "%s@%s\n",$2,$3}')
do
    cv_mods[$n]=$I
    ((n+=1))
done

# iterate over all modules in the repository and add ones that are missing to the CV
# we always add by modulename and author as this ensures that we get the latest version
# of the module when we republish the CV
for I in $(ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer --csv puppet-module list --repository-id ${PUPPET_REPO_ID}" | tail -n +2 | awk -F, '{printf "%s@%s\n",$2,$3}')
do
    mod_name=${I%%@*}
    mod_auth=${I##*@}
    push=1
    # does this module already exist in the CV?
    for J in ${cv_mods[@]}
    do
        if [[ ${mod_name} == ${J%%@*} && ${mod_auth} == ${J##*@} ]]
        then
            push=0
        fi
    done
    if [[ ${push} == 1 ]]
    then
        ssh -q -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer content-view puppet-module add --author=${mod_auth} --name=${mod_name} --organization=\"${ORG}\" --content-view=\"${CV}\""
    fi
done
