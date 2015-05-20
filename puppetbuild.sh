#!/bin/bash

# Search for Puppet module directories and build any modules found
#
# e.g. ${WORKSPACE}/scripts/puppetbuilder.sh ${WORKSPACE}/soe/puppet/
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

function build_puppetmodule {

    if [[ -e "$1" ]]
    then
        git_commit=$(git log --format="%H" -1  $(pwd))
        if [[ ! -e .puppetbuild-hash ]] || [[ ! ${git_commit} == $(cat .puppetbuild-hash) ]] 
        then
            MODULEDIR=$(dirname ${METADATA})
            if [[ $(basename ${METADATA}) = 'metadata.json' ]] ; then
              modname=$(IGNORECASE=1 awk -F \" '/name/ {print $4;exit;}' ${METADATA})
              modversion=$(IGNORECASE=1 awk -F \" '/version/ {print $4;exit;}' ${METADATA})
            elif [[ $(basename ${METADATA}) = 'Modulefile' ]] ; then
              modname=$(IGNORECASE=1 awk -F \' '/^name/ {print $2}' ${METADATA})
              modversion=$(IGNORECASE=1 awk -F \' '/^version/ {print $2}' ${METADATA})
            else
                err "Could not parse module name and/or module version using ${METADATA}"
                exit 1
            fi
            modarchive=${modname}-${modversion}.tar.gz

            if [ -f "${PUPPET_REPO}/${modarchive}" ]
            then
                warn "Puppet module '${modarchive}' already in repository," \
		     "You might have forgotten to increase the version" \
                     "after doing changes. Skipping ${MODULEFILE}."
            else

                # build the archive
                puppet module build ${MODULEDIR}
                RETVAL=$?
                if [[ ${RETVAL} != 0 ]]
                then
                    err "Could not build puppet module ${modname} using ${METADATA}."
                    exit ${MODBUILD_ERR}
                fi
                mv -nv ${MODULEDIR}/pkg/${modarchive} ${PUPPET_REPO} # don't overwrite
            fi
            echo ${git_commit} > .puppetbuild-hash
        else
            info "No changes since last build - skipping ${METADATA}"
        fi
    fi
}

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    usage "$0 <directory containing puppet module directories>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${WORKSPACE} ]] || [[ ! -w ${WORKSPACE} ]]
then
    err "Environment variable 'WORKSPACE' not set or not found"
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
    if [[ -n ${METADATA} ]]
    then
        build_puppetmodule ${METADATA}
    else
        err "Could not find puppet metadata file for puppet module ${I}"
        exit 1
    fi
    popd
done

