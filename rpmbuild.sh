#!/bin/bash 

# Search for RPM source directories and package
#
# e.g. ${WORKSPACE}/scripts/rpmbuilder.sh ${WORKSPACE}/soe/rpms/ 
#

. ${WORKSPACE}/scripts/common.sh

function build_srpm {
    
    if [[ -e "$1" ]]
    then
        git_commit=$(git log --format="%H" -1  $(pwd))
        if ! [[ ${git_commit} == $(cat .rpmbuild-hash) ]]
        then
            # determine the name of the rpm from the specfile
            rpmname=$(IGNORECASE=1 awk '/^Name:/ {print $2}' ${SPECFILE})
            rm -f ${WORKSPACE}/tmp/srpms/${rpmname}-*.src.rpm
            /usr/bin/mock --buildsrpm --spec ${SPECFILE} --sources $(pwd) --resultdir ${WORKSPACE}/tmp/srpms
            RETVAL=$?
            if [[ ${RETVAL} != 0 ]]
            then
                echo "Could not build SRPM ${rpmname} using the specfile ${SPECFILE}"
                exit ${SRPMBUILD_ERR}
            fi
            srpmname=${WORKSPACE}/tmp/srpms/${rpmname}-*.src.rpm
            /usr/bin/mock --rebuild ${srpmname} --resultdir ${YUM_REPO}
            RETVAL=$?
            if [[ ${RETVAL} != 0 ]]
            then
                echo "Could not build RPM ${rpmname} from ${srpmname}"
                exit ${RPMBUILD_ERR}
            fi
            echo ${git_commit} > .rpmbuild-hash
        else
            echo "No changes since last build - skipping ${SPECFILE}"
        fi
    fi
}    

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    echo "Usage: $0 <directory containing RPM source directories>"
    exit ${NOARGS}
fi
workdir=$1

if [[ -z ${WORKSPACE} ]] || [[ ! -w ${WORKSPACE} ]]
then
    echo "WORKSPACE not set or not found"
    exit ${WORKSPACE_ERR}
fi

mkdir -p ${WORKSPACE}/tmp/srpms

# Traverse directories looking for spec files and build SRPMs
cd ${workdir}
for I in $( ls -d */ )
do
    SPECFILE=""
    pushd ${I}
    # find the spec files
    SPECFILE=$(find . -name "*.spec")
    if [[ -n ${SPECFILE} ]] ; then build_srpm ${SPECFILE} ; fi
    popd
done
    



