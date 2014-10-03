#!/bin/bash

# Search for Puppet module directories
#
# e.g. ${WORKSPACE}/scripts/puppetbuilder.sh ${WORKSPACE}/soe/puppet/
#

. ${WORKSPACE}/scripts/common.sh

function build_puppetmodule {

    if [[ -e "$1" ]]
    then
        git_commit=$(git log --format="%H" -1  $(pwd))
        if ! [[ ${git_commit} == $(cat .puppetbuild-hash) ]] 
        then
            MODULEDIR=$(dirname ${METADATA})
            if [[ $(basename ${METADATA}) = 'metadata.json' ]] ; then
              modname=$(IGNORECASE=1 awk -F \" '/name/ {print $4;exit;}' ${METADATA} | awk -F \- '{print $2}')
              modversion=$(IGNORECASE=1 awk -F \" '/version/ {print $4;exit;}' ${METADATA})
            elif [[ $(basename ${METADATA}) = 'Modulefile' ]] ; then
              modname=$(IGNORECASE=1 awk -F \' '/^name/ {print $2}' ${METADATA})
              modversion=$(IGNORECASE=1 awk -F \' '/^version/ {print $2}' ${METADATA})
            else
                echo "Could not parse module name and/or module version using ${METADATA}"
                exit 1
            fi
            modarchive=${modname}-${modversion}.tar.gz

            # build the archive
            puppet module build ${MODULEDIR}
            RETVAL=$?
            if [[ ${RETVAL} != 0 ]]
            then
                echo "Could not build puppet module ${modname} using ${METADATA}"
                exit ${MODBUILD_ERR}
            fi
            mv ${MODULEDIR}/pkg/${modarchive} ${PUPPET_REPO}
            echo ${git_commit} > .puppetbuild-hash
        else
            echo "No changes since last build - skipping ${METADATA}"
        fi
    fi
}

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    echo "Usage: $0 <directory containing puppet module directories>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${WORKSPACE} ]] || [[ ! -w ${WORKSPACE} ]]
then
    echo "WORKSPACE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# Traverse directories looking for Modulefiles 
cd ${workdir}
for I in $(ls -d */ )
do
    METADATA=""
    pushd ${I}
    # find Modulefiles
    METADATA=$(find $(pwd) -maxdepth 1 -name 'metadata.json')
    # look for deprecated Modulefile if there is no metadata.json
    if [[ -z ${METADATA} ]] ; then METADATA=$(find $(pwd) -maxdepth 1 -name 'Modulefile') ; fi
    if [[ -n ${METADATA} ]] ; then build_puppetmodule ${METADATA} ; fi
    popd
done

