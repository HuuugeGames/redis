#!/usr/bin/env bash

set -x

pid=0

for i in "$@"
do
case $i in
    --save=*)
    SAVE="${i#*=}"
    shift
    ;;
    --slaveof=*)
    SLAVEOF="${i#*=}"
    shift
    ;;
esac
done

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

# run application
env |sed 's/^\(.*\)$/export \1/g' > /root/.profile
# change redis dump file name to date and project name
if [ -e /etc/redis/redis.conf ] && [ -n "$HBI_PROJECT_NAME" ]
then
    sed -i "s/dbfilename dump.rdb/dbfilename dump_metrics_${HOSTNAME}_${HBI_PROJECT_NAME}.rdb/" /etc/redis/redis.conf
fi
crond
if [ -n "${SAVE}" ] || [ -n "${SLAVEOF}" ]
then
    redis-server /etc/redis/redis.conf --save ${SAVE} --slaveof ${SLAVEOF}
else
    redis-server /etc/redis/redis.conf &
fi
pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
