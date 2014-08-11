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

# setup RPM build environment
rpmtop=${WORKSPACE}/rpmbuild
mkdir -p ${rpmtop}/{SPECS,SOURCES,BUILD,BUILDROOT,RPMS,SRPMS} 
mkdir -p ${WORKSPACE}/artefacts/rpms

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
    if [[ -n ${SPECFILE} ]] ; then build_rpm() ; fi
    popd
done
    

build_rpm () {
    
    if [[ -e ${SPECFILE} ]]
    then
        # determine the name of the rpm from the specfile
        rpmname=$(IGNORECASE=1 awk '/^Name:/ {print $2}' ${SPECFILE})
        cp ${SPECFILE} ${rpmtop}/SPECS
        tar cvzf ${rpmtop}/SOURCES/${rpmname}.tgz --exclude $rpmtop --exclude dist .
        rpmbuild --define "_topdir ${rpmtop}" -bb ${rpmtop}/SPECS/$(basename ${SPECFILE})
        RETVAL=$?
        if [[ ${RETVAL} != 0 ]]
        then
            echo "Could not build RPM ${rpmname} using the specfile ${SPECFILE}"
            exit ${RPMBUILD_ERR}
        fi
    fi
}    


