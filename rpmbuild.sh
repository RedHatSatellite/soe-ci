#!/bin/bash -x

# Search for RPM source directories and package
#
# e.g. ${WORKSPACE}/scripts/rpmbuilder.sh ${WORKSPACE}/soe/rpms/ 
#

NOARGS=1
GITVER_ERR=2
GITREV_ERR=3
RPMBUILD_ERR=4
WORKSPACE_ERR=5

function build_rpm {
    
    if [[ -e "$1" ]]
    then
        git_commit=$(git log --format="%H" -1  $(pwd))
        if ! [[ ${git_commit} -eq $(cat .rpmbuild-hash) ]]
        then
            echo ${git_commit} > .rpmbuild-hash
            # determine the name of the rpm from the specfile
            rpmname=$(IGNORECASE=1 awk '/^Name:/ {print $2}' ${SPECFILE})   
            cp ${SPECFILE} ${rpmtop}/SPECS
            cp -a * ${rpmtop}/SOURCES
            rpmbuild --define "_topdir ${rpmtop}" -ba ${rpmtop}/SPECS/$(basename ${SPECFILE})
            RETVAL=$?
            if [[ ${RETVAL} != 0 ]]
            then
                echo "Could not build RPM ${rpmname} using the specfile ${SPECFILE}"
                exit ${RPMBUILD_ERR}
            fi
        else
            echo "No changes since last build - skipping ${SPECFILE}"
        fi
    fi
}    

# setup RPM build environment
rpmtop=${WORKSPACE}/rpmbuild
mkdir -p ${rpmtop}/{SPECS,SOURCES,BUILD,BUILDROOT,RPMS,SRPMS} 
mkdir -p ${WORKSPACE}/artefacts/{rpms,srpms,debug-rpms}


if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    echo "Usage: $0 <directory containing RPM sources>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${WORKSPACE} ]] || [[ ! -w ${WORKSPACE} ]]
then
    echo "WORKSPACE not set or not found"
    exit ${WORKSPACE_ERR}
fi


# Traverse directories looking for spec files
cd ${workdir}
for I in $( ls -d */ )
do
    SPECFILE=""
    pushd $I
    # find the spec files
    SPECFILE=$(find . -name "*.spec")
    if [[ -n ${SPECFILE} ]] ; then build_rpm ${SPECFILE} ; fi
    popd
done
    
# copy all created RPMs to the artefacts directory
cd ${rpmtop}
find . -name '*debuginfo*.rpm' -exec mv {} ${WORKSPACE}/artefacts/debug-rpms \;
find . -name '*.src.rpm' -exec mv {} ${WORKSPACE}/artefacts/srpms \;
find . -name '*.rpm' -exec mv {} ${WORKSPACE}/artefacts/rpms \;



