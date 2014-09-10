#!/bin/bash 

# common stuff

# Error states
NOARGS=1
GITVER_ERR=2
GITREV_ERR=3
RPMBUILD_ERR=4
WORKSPACE_ERR=5
SRPMBUILD_ERR=6

PUSH_USER=jenkins
SATELLITE=satellite6.faa.redhat.com
REPO_ID=16
RSA_ID=/var/lib/jenkins/.ssh/id_rsa
KNOWN_HOSTS=/var/lib/jenkins/.ssh/known_hosts
TESTVM_PATTERN=test1
TEST_ROOT=r3dhat00
