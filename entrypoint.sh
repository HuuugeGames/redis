#!/usr/bin/env bash
env |sed 's/^\(.*\)$/export \1/g' > /root/.profile
# change redis dump file name to date and project name
if [ -e /etc/redis/redis.conf ] && [ -n "$HBI_PROJECT_NAME" ]
then
    sed -i "s/dbfilename dump.rdb/dbfilename dump_metrics_${HOSTNAME}_${HBI_PROJECT_NAME}.rdb/" /etc/redis/redis.conf
fi
crond