#!/usr/bin/env python
import datetime
import os

import boto3
import redis


def put_redis_metric():
    REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT = os.getenv("REDIS_PORT", "6379")
    HBI_PROJECT_NAME = os.getenv("HBI_PROJECT_NAME", "localhost")
    CLOUDWATCH_NAMESPACE = os.getenv("CLOUDWATCH_NAMESPACE", 'dashboard_metrics')

    try:
        r = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT
        )
        mem = r.info('memory').get('used_memory')

        cw_client = boto3.client('cloudwatch', region_name='us-east-1')
        cw_client.put_metric_data(
            Namespace=CLOUDWATCH_NAMESPACE,
            MetricData=[
                {
                    'MetricName': 'redis-info',
                    'Dimensions': [
                        {
                            'Name': 'redis-{0}'.format(HBI_PROJECT_NAME),
                            'Value': 'used_memory_{0}'.format(HBI_PROJECT_NAME)
                        }
                    ],
                    'Timestamp': datetime.datetime.utcnow(),
                    'Value': mem,
                    'Unit': 'Bytes',
                }
            ]
        )
        print("Memory used: {0} bytes".format(mem))
    except Exception as e:
        print "Exception caught: {0}".format(e)


if __name__ == "__main__":
    put_redis_metric()
