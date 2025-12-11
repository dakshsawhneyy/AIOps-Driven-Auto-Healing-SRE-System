# normalizer.py (Lambda)
import base64
import boto3
import json
import os
import uuid
from datetime import datetime, timezone
from dateutil.parser import parse as parse_dt

s3 = boto3.client("s3")
BUCKET = os.environ.get("TARGET_BUCKET")

# -------------------------
# helpers
# -------------------------
def to_utc(dt_or_str):
    """
    Accepts datetime or string, returns timezone-aware datetime in UTC.
    """
    if dt_or_str is None:
        return None
    if isinstance(dt_or_str, str):
        parsed = parse_dt(dt_or_str)
    elif isinstance(dt_or_str, datetime):
        parsed = dt_or_str
    else:
        parsed = parse_dt(str(dt_or_str))
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)

# -------------------------
# load labels from training/<label>/
# -------------------------
def load_labels_from_s3():
    label_types = ["cpu", "memory", "latency", "traffic", "pod_crash"]
    labels = []

    for label in label_types:
        prefix = f"training/{label}/"
        resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix, MaxKeys=1000)
        if "Contents" not in resp:
            continue

        for item in resp["Contents"]:
            obj = s3.get_object(Bucket=BUCKET, Key=item["Key"])
            data = json.loads(obj["Body"].read())

            start = to_utc(data.get("start_timestamp"))
            end = to_utc(data.get("end_timestamp")) if data.get("end_timestamp") else None

            labels.append({
                "label": label,
                "start": start,
                "end": end,
                "s3_key": item["Key"]
            })

    print("Loaded label windows:", labels)
    return labels

# -------------------------
# load normalized metrics from S3 (normalized/metrics/)
# -------------------------
def load_metrics_from_s3():
    metrics = []
    prefix = "normalized/metrics/"
    resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix, MaxKeys=1000)
    if "Contents" not in resp:
        return metrics

    for item in resp["Contents"]:
        obj = s3.get_object(Bucket=BUCKET, Key=item["Key"])
        try:
            data = json.loads(obj["Body"].read())
        except Exception as e:
            print("skip bad json", item["Key"], e)
            continue

        ts = to_utc(data.get("timestamp"))
        # Some normalizers may produce numeric strings: ensure float
        try:
            value = float(data.get("value", 0))
        except:
            value = 0.0

        metrics.append({
            "timestamp": ts,
            "value": value,
            "metric_type": data.get("metric_type"),
            "s3_key": item["Key"]
        })

    print("Loaded metrics count:", len(metrics))
    return metrics

# -------------------------
# generate training CSVs
# -------------------------
def generate_training_datasets():
    labels = load_labels_from_s3()
    metrics = load_metrics_from_s3()

    dataset = { "cpu": [], "memory": [], "latency": [], "traffic": [], "pod_crash": [] }

    # Match metrics to windows
    for metric in metrics:
        ts = metric["timestamp"]
        if ts is None:
            continue
        for window in labels:
            if window["end"] is None:
                continue  # skip open windows
            if window["start"] <= ts <= window["end"]:
                dataset[window["label"]].append({
                    "timestamp": ts.isoformat(),
                    "value": metric["value"],
                    "label": window["label"]
                })

    # Upload CSV (overwrite every run)
    for label, rows in dataset.items():
        csv_data = "timestamp,value,label\n"
        for row in rows:
            csv_data += f"{row['timestamp']},{row['value']},{label}\n"

        key = f"training-data/{label}.csv"
        s3.put_object(Bucket=BUCKET, Key=key, Body=csv_data, ContentType="text/csv")
        print(f"wrote {key} rows={len(rows)}")

    print("FINAL DATASET:", {k: len(v) for k, v in dataset.items()})
    return {"status": "training data generated", "counts": {k: len(v) for k, v in dataset.items()}}

# -------------------------
# runtime normalizer for Kinesis events
# -------------------------
def normalize_metric(record):
    # record already a dict
    return {
        "timestamp": record.get("timestamp") or datetime.now(timezone.utc).isoformat(),
        "service": record.get("service", "unknown"),
        "node": record.get("node", "unknown-node"),
        "metric_type": record.get("metric_type", "unknown"),
        "value": record.get("value", 0),
        "unit": record.get("unit", "unknown")
    }

def normalize_log(record):
    return {
        "timestamp": record.get("timestamp") or datetime.now(timezone.utc).isoformat(),
        "service": record.get("service", "unknown"),
        "log_level": record.get("level") or record.get("log_level") or "INFO",
        "message": record.get("message") or record.get("log") or "",
        "node": record.get("node", "unknown-node")
    }

def detect_type(record):
    if "metric_type" in record:
        return "metric"
    if "level" in record or "log" in record or "message" in record:
        return "log"
    return "unknown"

def upload_to_s3(normalized, record_type):
    folder = "normalized/metrics" if record_type == "metric" else "normalized/logs"
    timestamp_prefix = datetime.now(timezone.utc).strftime("%Y/%m/%d/")
    file_id = str(uuid.uuid4()) + ".json"
    key = f"{folder}/{timestamp_prefix}{file_id}"
    s3.put_object(Bucket=BUCKET, Key=key, Body=json.dumps(normalized), ContentType="application/json")
    return key

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

# -------------------------
# Lambda handler
# -------------------------
def handler(event, context):
    # manual dataset generation mode
    if event.get("generate_dataset") == True:
        return generate_training_datasets()

    # normal kinesis processing
    results = []
    if "Records" not in event:
        return {"status": "no live records"}

    for record in event["Records"]:
        payload = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")
        normalized, rtype = process_record(payload)
        if not normalized:
            continue
        key = upload_to_s3(normalized, rtype)
        results.append({"type": rtype, "s3_key": key})

    return {"normalized_records": len(results)}
