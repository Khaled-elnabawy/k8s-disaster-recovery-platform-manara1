"""Scale the warm-standby application tier after a forwarded primary health alarm.

This function does not promote Aurora or change DNS itself. Route 53 owns DNS
failover; database promotion and final health/data validation remain explicit
recovery steps in the runbook.
"""

import json
import os

import boto3


def handler(event, context):
    """Raise secondary Auto Scaling capacity and return the API result."""
    group_name = os.environ["STANDBY_ASG_NAME"]
    desired_capacity = int(os.environ.get("STANDBY_DESIRED_SIZE", "2"))

    detail = event.get("detail", {})
    state = detail.get("state", {}).get("value")
    if state != "ALARM":
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Ignored event outside ALARM state"}),
        }

    client = boto3.client("autoscaling")
    response = client.update_auto_scaling_group(
        AutoScalingGroupName=group_name,
        MinSize=desired_capacity,
        DesiredCapacity=desired_capacity,
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Standby scaling request submitted",
                "autoScalingGroup": group_name,
                "desiredCapacity": desired_capacity,
                "requestId": response["ResponseMetadata"]["RequestId"],
            }
        ),
    }
