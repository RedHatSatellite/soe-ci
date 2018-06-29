#!/bin/bash

# how long do we wait in the different stages?
# 5 minutes is 300 seconds
# 30 minutes is 1800 seconds
MAX_STATE_WAIT=300
MAX_LOCK_WAIT=1800
MAX_FINISH_WAIT=1800

look_for_state()
{
  WAIT=0
  while [[ ! -d /var/lib/puppet/state ]]
  do
    echo "no /var/lib/puppet/state yet, waiting since ${WAIT} seconds, checking again in 10 seconds"
    sleep 10
    ((WAIT+=10))
    if [[ ${WAIT} -gt ${MAX_STATE_WAIT} ]]
    then
        echo "no /var/lib/puppet/state after ${MAX_STATE_WAIT} seconds. Exiting."
        exit 1
    fi
  done
}

look_for_daemon_lock()
{
  WAIT=0
  while [[ -e /var/lib/puppet/state/puppetdlock ]]
  do
    echo "puppet daemon is holding a lock, waiting since ${WAIT} seconds, waiting 10 secs until next check"
    sleep 10
    ((WAIT+=10))
    if [[ ${WAIT} -gt ${MAX_LOCK_WAIT} ]]
    then
        echo "puppet daemon still holding lock after ${MAX_LOCK_WAIT} seconds. Exiting."
        exit 1
    fi
  done
  echo "puppet daemon not holding lock"
}

look_for_agent_lock()
{
  WAIT=0
  while [[ -e /var/lib/puppet/state/agent_catalog_run.lock ]]
  do
    echo "puppet agent is holding a lock, waiting since ${WAIT} seconds, waiting 10 secs until next check"
    sleep 10
    ((WAIT+=10))
    if [[ ${WAIT} -gt ${MAX_LOCK_WAIT} ]]
    then
        echo "puppet agent still holding lock after ${MAX_LOCK_WAIT} seconds. Exiting."
        exit 1
    fi
  done
  echo "puppet agent not holding lock"
}

look_for_finished()
{
  NOTFINISHED=1
  WAIT=0
  while [[ ${NOTFINISHED} -ne 0 ]]
  do
    echo "Checking if puppet is done, waiting since ${WAIT} seconds"
    grep 'Finished catalog run\|Failed to apply catalog' /var/lib/puppet/state/last_run_report.yaml
    NOTFINISHED=$?
    sleep 10
    ((WAIT+=10))
    if [[ ${WAIT} -gt ${MAX_FINISH_WAIT} ]]
    then
        echo "puppet not done after ${MAX_FINISH_WAIT} seconds. Exiting."
        exit 1
    fi
  done
}

date

# waiting just over one minute for puppet to start
# this script gets run on first boot after a system was installed
echo "waiting 75 seconds (one minute and a bit) before checking on puppet"
sleep 75

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
