#!/bin/bash

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
    grep "Finished catalog run" /var/lib/puppet/state/last_run_report.yaml
    NOTFINISHED=$?
    sleep 10
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

