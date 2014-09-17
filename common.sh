#!/bin/bash 

# common stuff

# Error states
NOARGS=1
GITVER_ERR=2
GITREV_ERR=3
RPMBUILD_ERR=4
WORKSPACE_ERR=5
SRPMBUILD_ERR=6
MODBUILD_ERR=7
PUSH_USER=jenkins
SATELLITE=satellite6.faa.redhat.com
REPO_ID=16
PUPPET_REPO_ID=22
RSA_ID=/var/lib/jenkins/.ssh/id_rsa
KNOWN_HOSTS=/var/lib/jenkins/.ssh/known_hosts
TESTVM_PATTERN=test1
TEST_ROOT=r3dhat00
MODAUTHOR=DBr
YUM_REPO=/var/www/html/pub/soe-repo
PUPPET_REPO=/var/www/html/pub/soe-puppet


