//this is for RHEL8 only as we build packages and shove them in a RHEL8 only yum repo
env.REPO_ID="3825"
env.PUPPET_REPO_ID="8"
env.TESTVM_HOSTCOLLECTION="hc-soe-el8-test"
env.YUM_REPO="/var/www/html/pub/soe-repo/rhel8"
env.PUPPET_REPO="/var/www/html/pub/soe-puppet"
env.CV="cv-soe-ci-el8"
env.CV_PASSIVE_LIST=""
env.CCV_NAME_PATTERN=""
env.CONDITIONAL_VM_BUILD=false
env.MOCK_CONFIG="rhel-8-x86_64"
env.PUPPET_DONE_SLEEP="75"
