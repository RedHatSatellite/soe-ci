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
            MODULEDIR=$(dirname ${MODULEFILE})
            modname=$(IGNORECASE=1 awk -F \' '/^name/ {print $2}' ${MODULEFILE})
            modversion=$(IGNORECASE=1 awk -F \' '/^version/ {print $2}' ${MODULEFILE})
            modarchive=${modname}-${modversion}.tar.gz
        
            # build the archive
            puppet module build ${MODULEDIR}
            RETVAL=$?
            if [[ ${RETVAL} != 0 ]]
            then
                echo "Could not build puppet module ${modname} using the Modulefile ${MODULEFILE}"
                exit ${MODBUILD_ERR}
            fi
            mv ${MODULEDIR}/pkg/${modarchive} ${ARTEFACTS}
            echo ${git_commit} > .puppetbuild-hash
        else
            echo "No changes since last build - skipping ${MODULEFILE}"
        fi
    fi
}    

# setup artefacts environment 
ARTEFACTS=${WORKSPACE}/artefacts/puppet
mkdir -p ${ARTEFACTS}


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
    MODULEFILE=""
    pushd ${I}
    # find Modulefiles
    MODULEFILE=$(find $(pwd) -maxdepth 1 -name "Modulefile")
    if [[ -n ${MODULEFILE} ]] ; then build_puppetmodule ${MODULEFILE} ; fi
    popd
done



