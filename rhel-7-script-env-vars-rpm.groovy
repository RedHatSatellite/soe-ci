//this is for RHEL7 only as we build packages and shove them in a RHEL7 only yum repo
env.REPO_ID="10"
env.PUPPET_REPO_ID="8"
env.TESTVM_HOSTCOLLECTION="Test Servers installed from image"
env.YUM_REPO="/var/www/html/pub/soe-repo/rhel7"
env.PUPPET_REPO="/var/www/html/pub/soe-puppet"
env.CV="cv-RHEL-Server-Jenkins-pipeline"
env.CV_PASSIVE_LIST=""
env.CCV_NAME_PATTERN=""
env.CONDITIONAL_VM_BUILD=false
env.MOCK_CONFIG="rhel-7-x86_64"
env.PUPPET_DONE_SLEEP="75"
