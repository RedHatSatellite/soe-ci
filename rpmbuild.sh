#!/bin/bash 

# Search for RPM source directories and package
#
# e.g. ${WORKSPACE}/scripts/rpmbuilder.sh ${WORKSPACE}/soe/rpms/ 
#

#set -x

# Load common parameter variables
source scripts/common.sh

printf -v escaped_1 %q "${1}"

function build_srpm {
    
    if [[ -e "$1" ]]
    then
        git_commit=$(git log --format="%H" -1  .)
        if  [[ ! -e .rpmbuild-hash ]] || [[ ${git_commit} != $(cat .rpmbuild-hash) ]]
        then
            # determine the name of the rpm from the specfile
            rpmname=$(IGNORECASE=1 awk '/^Name:/ {print $2}' ${SPECFILE})
            rm -f "${SRPMS_DIR}/${rpmname}-*.src.rpm"
            /usr/bin/mock --buildsrpm --spec "${SPECFILE}" --sources "$(pwd)" --resultdir "${SRPMS_DIR}" --root ${MOCK_CONFIG}
            RETVAL=$?
            if [[ ${RETVAL} != 0 ]]
            then
                err "Could not build SRPM ${rpmname} using the specfile ${SPECFILE}"
                exit ${SRPMBUILD_ERR}
            fi

            pushd "${WORKSPACE}"
            # printf -v srpmrelpath %q "$(find tmp/srpms -name ${rpmname}*)"
            srpmrelpath="$(find tmp/srpms -name ${rpmname}*)"
            popd

            #srpmname="${WORKSPACE}/${srpmrelpath}"
            printf -v srpmname_escaped %q "${WORKSPACE}/${srpmrelpath}"
            srpmname="${WORKSPACE}/${srpmrelpath}"

            /usr/bin/mock --rebuild "${srpmname}" -D "%debug_package %{nil}" --resultdir "${RPMS_DIR}" --root ${MOCK_CONFIG}
            RETVAL=$?
            if [[ ${RETVAL} != 0 ]]
            then
                err "Could not build RPM ${rpmname} from ${srpmname}"
                exit ${RPMBUILD_ERR}
            fi
            pushd "${RPMS_DIR}"
            mv -nv *.rpm ${YUM_REPO} # don't overwrite RPMs
            popd
            restorecon -F ${YUM_REPO}/*.rpm
            if [ "$(echo ${RPMS_DIR}/*.rpm)" != "${RPMS_DIR}/*.rpm" ]
            then # not all RPM files could be moved, some are remaining
	        warn "RPM package '${rpmname}' already in repository," \
                     "You might have forgotten to increase the version" \
                     "after doing changes. Skipping ${SPECFILE}"
            fi
            # Something has changed, track it for build and for tests
            echo ${git_commit} > .rpmbuild-hash
            echo "#${rpmname}#" >> "${MODIFIED_CONTENT_FILE}"
            echo "${rpmname}"  >> "${MODIFIED_RPMS_FILE}"
        else
            inform "No changes since last build - skipping ${SPECFILE}"
        fi
    fi
}

if [[ -z ${escaped_1} ]]
then
    usage "$0 <directory containing RPM source directories>"
    warn "the test zero length failed for ${escaped_1}"
    warn "you used $0 $@"
    exit ${NOARGS}
fi

if [[ ! -d "${1}" ]]
then
    usage "$0 <directory containing RPM source directories>"
    warn "the test directory exists failed for ${1}"
    warn "you used $0 $@"
    exit ${NOARGS}
fi

workdir=$1
printf -v escaped_workdir %q "${1}"

if [[ -z ${WORKSPACE} ]] || [[ ! -w ${WORKSPACE} ]]
then
    err "WORKSPACE not set or not found"
    exit ${WORKSPACE_ERR}
fi

SRPMS_DIR="${WORKSPACE}/tmp/srpms"
RPMS_DIR="${WORKSPACE}/tmp/rpms"
mkdir -p "${SRPMS_DIR}" "${RPMS_DIR}"

# Traverse directories looking for spec files and build SRPMs
cd "${workdir}"
for I in $( ls -d */ )
do
    SPECFILE=""
    pushd ${I}
    # find the spec files
    SPECFILE=$(find . -name "*.spec")
    if [[ -n ${SPECFILE} ]] ; then build_srpm ${SPECFILE} ; fi
    popd
done
wait # TODO: add comment to explain why this?
