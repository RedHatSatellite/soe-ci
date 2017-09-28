#!/bin/bash

NO_ARGS=0
OPTERROR=65

usage()
{
  echo "Usage: $0 -s <seconds>"
  echo "       s = number of seconds to sleep"
  exit 1
}
if [ $# -eq "$NO_ARGS" ]
then
  usage
fi

look_for_state()
{
  while [[ ! -d /var/lib/puppet/state ]]
  do
    echo "no /var/lib/puppet/state yet, checking again in 10 seconds"
    sleep 10
  done
}

look_for_daemon_lock()
{
  while [[ -e /var/lib/puppet/state/puppetdlock ]]
  do
    echo "puppet daemon is holding a lock, waiting 10 secs"
    sleep 10
  done
  echo "puppet daemon not holding lock"
}

look_for_agent_lock()
{
  while [[ -e /var/lib/puppet/state/agent_catalog_run.lock ]]
  do
    echo "puppet agent is holding a lock, waiting 10 secs"
    sleep 10
  done
  echo "puppet agent not holding lock"
}

look_for_finished()
{
  NOTFINISHED=1
  while [[ ${NOTFINISHED} -ne 0 ]]
  do
    echo "Checking if puppet is done"
    grep 'Finished catalog run\|Failed to apply catalog' /var/lib/puppet/state/last_run_report.yaml
    NOTFINISHED=$?
    sleep 10
  done
}

date

# Let's not wait for puppet on a host that is actually using Ansible
if ! rpm -q puppet ; then
  echo "puppet is not installed"
  exit 0
fi

while getopts "c:n:s:h" Option
do
  case $Option in
    s) SLEEP=${OPTARG}
    ;;
    h)
      usage
    ;;
    *) echo "Non valid switch"
    ;;
  esac
done

# if you run puppet on boot, sleep 75 seconds (just over a minute)
# if this is a run in the puppet only workflow, no real need to sleep
echo "waiting ${SLEEP} seconds before checking on puppet"
sleep ${SLEEP}

# /var/lib/puppet/state gets created on first run?
look_for_state

# now that the directory is there, look for the daemon lock
look_for_daemon_lock

# look for agent lock
look_for_agent_lock

# see if puppet has finished
look_for_finished

date
echo "puppet seems done"

