import base64
import boto3
import json
import os
import uuid
from datetime import datetime

s3 = boto3.client("s3")
BUCKET = os.environ.get("TARGET_BUCKET")


# ======================================================
# CHAOS EVENT LABELING
# ======================================================

def save_chaos_event(event_type, start_timestamp, end_timestamp):
    """
    Writes a chaos event metadata file to S3 for ML training
    """

    # Folder mapping
    event_map = {
        "cpu_spike": "cpu",
        "memory_leak": "memory",
        "high_traffic": "traffic",
        "latency_spike": "latency",
        "pod_crash": "pod_crash"
    }

    folder = event_map.get(event_type)
    if not folder:
        raise ValueError(f"Unknown event type: {event_type}")

    file_id = str(uuid.uuid4()) + ".json"
    key = f"training/{folder}/{file_id}"

    body = {
        "start_timestamp": start_timestamp,
        "end_timestamp": end_timestamp,
        "label": event_type
    }

    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=json.dumps(body),
        ContentType="application/json"
    )

    return key


# -----------------------------
# Normalizers
# -----------------------------
def normalize_metric(record):
    return {
        "timestamp": record.get("timestamp") or datetime.utcnow().isoformat(),
        "service": record.get("service", "unknown"),
        "node": record.get("node", "unknown-node"),
        "metric_type": record.get("metric_type", "unknown"),
        "value": record.get("value", 0),
        "unit": record.get("unit", "unknown")
    }

def normalize_log(record):
    return {
        "timestamp": record.get("timestamp") or datetime.utcnow().isoformat(),
        "service": record.get("service", "unknown"),
        "log_level": record.get("level") or record.get("log_level") or "INFO",
        "message": record.get("message") or record.get("log") or "",
        "node": record.get("node", "unknown-node")
    }

# -----------------------------
# TYPE DETECTION
# -----------------------------
def detect_type(record):
    if "metric_type" in record:
        return "metric"
    if "level" in record or "log" in record or "message" in record:
        return "log"
    return "unknown"

# -----------------------------
# UPLOAD WITH CLEAN PARTITIONING
# -----------------------------
def upload_to_s3(normalized, record_type):
    # record_type = "metric" → "metrics"
    folder = "metrics" if record_type == "metric" else "logs"

    timestamp_prefix = datetime.utcnow().strftime("%Y/%m/%d/")
    file_id = str(uuid.uuid4()) + ".json"

    key = f"{folder}/{timestamp_prefix}{file_id}"

    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=json.dumps(normalized),
        ContentType="application/json"
    )

    return key

# -----------------------------
# PROCESS EACH RECORD
# -----------------------------
def process_record(decoded_payload):
    try:
        record_json = json.loads(decoded_payload)
    except:
        return None, None

    record_type = detect_type(record_json)

    if record_type == "metric":
        return normalize_metric(record_json), "metric"

    if record_type == "log":
        return normalize_log(record_json), "log"

    return None, None

# -----------------------------
# MAIN HANDLER
# -----------------------------
def handler(event, context):
    results = []

    for record in event["Records"]:
        payload = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")

        normalized, rtype = process_record(payload)
        if not normalized:
            continue

        s3_key = upload_to_s3(normalized, rtype)

        results.append({
            "type": rtype,
            "s3_key": s3_key
        })

    return {"normalized_records": len(results)}