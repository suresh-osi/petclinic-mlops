import gzip
import json
import logging
import os
import re
import boto3
import urllib.request

logger = logging.getLogger()
logger.setLevel(logging.INFO)

LICENSE_KEY = os.getenv("LICENSE_KEY", "")
LOGGING_ENABLED = os.getenv("LOGGING_ENABLED", "true").lower() == "true"
NR_LOGGING_ENDPOINT = os.getenv("NR_LOGGING_ENDPOINT", "https://log-api.newrelic.com/log/v1")

def lambda_handler(event, context):
    log_data = event.get("awslogs", {}).get("data", "")
    if not log_data:
        logger.warning("No log data in event")
        return

    compressed = __import__("base64").b64decode(log_data)
    payload = json.loads(gzip.decompress(compressed))

    log_group   = payload.get("logGroup", "unknown")
    log_stream  = payload.get("logStream", "unknown")
    log_events  = payload.get("logEvents", [])

    if LOGGING_ENABLED:
        logger.info(f"Processing {len(log_events)} events from {log_group}/{log_stream}")

    logs = []
    for evt in log_events:
        logs.append({
            "timestamp": evt.get("timestamp"),
            "message":   evt.get("message", ""),
            "attributes": {
                "logGroup":   log_group,
                "logStream":  log_stream,
                "aws.accountId": context.invoked_function_arn.split(":")[4] if context else "",
            }
        })

    if not logs:
        return

    body = json.dumps([{"logs": logs}]).encode("utf-8")
    req = urllib.request.Request(
        NR_LOGGING_ENDPOINT,
        data=body,
        headers={
            "Content-Type":       "application/json",
            "X-License-Key":      LICENSE_KEY,
            "X-Event-Source":     "logs",
            "Content-Encoding":   "identity",
        },
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        status = resp.getcode()
        if LOGGING_ENABLED:
            logger.info(f"NewRelic response: {status}")
    return {"statusCode": status}
