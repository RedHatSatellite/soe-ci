#!/bin/bash

# /var/lib/puppet/state gets created on first run?
while [[ ! -d /var/lib/puppet/state ]]
do
  echo "no /var/lib/puppet/state yet, checking again in 10 seconds"
  sleep 10
done

# see if puppet has finished
NOTFINISHED=1
while [[ ${NOTFINISHED} -ne 0 ]]
do
  echo "Checking if puppet is done"
  grep "Finished catalog run" /var/lib/puppet/state/last_run_report.yaml
  NOTFINISHED=$?
  sleep 10
done

# now that the directory is there, look for the lock
while [[ -e /var/lib/puppet/state/puppetdlock ]]
do
  echo "puppet is holding a lock, waiting 10 secs"
  sleep 10
done

echo "puppet not holding lock"


