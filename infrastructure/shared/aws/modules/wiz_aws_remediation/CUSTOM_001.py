"""
This is a sample custom response function that simply returns a message
to CloudWatch and the Wiz System Activity Log (SAL)
"""

import boto3

from aws.function.source import auto_tagging
from aws.function.source import utils
from aws.function.source import constants


def remediate(session: boto3.Session, event: dict, lambda_context):
    scan_id = event["scanId"]
    presigned_url = event["presignURL"]

    response_action_message = (
        "Sample custom response function CUSTOM_001 has been run successfully"
    )
    response_action_status = constants.ResponseActionStatus.SUCCESS
    print(response_action_message)
    utils.send_response_action_result(
        presigned_url, scan_id, response_action_status, response_action_message
    )
