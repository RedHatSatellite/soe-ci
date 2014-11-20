#!/bin/bash 

# common stuff - much of this could go into a parameterised job in Jenkins

# Error states
NOARGS=1
GITVER_ERR=2
GITREV_ERR=3
RPMBUILD_ERR=4
WORKSPACE_ERR=5
SRPMBUILD_ERR=6
MODBUILD_ERR=7
PUSH_USER=jenkins
SATELLITE=satellite6.acme
REPO_ID=16
PUPPET_REPO_ID=17
RSA_ID=/var/lib/jenkins/.ssh/id_rsa
KNOWN_HOSTS=/var/lib/jenkins/.ssh/known_hosts
TESTVM_HOSTGROUP="Test Servers"
TESTVM_ENV=2
TEST_ROOT=1234567890
MODAUTHOR=acme
YUM_REPO=/var/www/html/pub/soe-repo
PUPPET_REPO=/var/www/html/pub/soe-puppet
CV=acme-7.0.0
ORG=Default_Organization


