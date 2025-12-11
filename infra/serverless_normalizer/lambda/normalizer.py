import base64
import boto3
import json
import os
import uuid
from datetime import datetime
from dateutil.parser import parse as parse_dt   # <-- IMPORTANT

s3 = boto3.client("s3")
BUCKET = os.environ.get("TARGET_BUCKET")

# =====================================================================
# LOAD CHAOS LABELS FROM S3
# =====================================================================

def load_labels_from_s3():
    """
    Walks through training/<label>/*.json files
    Returns list of:
    { "label": "...", "start": datetime, "end": datetime }
    """

    label_types = ["cpu", "memory", "latency", "traffic", "pod_crash"]
    labels = []

    for label in label_types:
        prefix = f"training/{label}/"

        resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix)

        if "Contents" not in resp:
            continue

        for item in resp["Contents"]:
            obj = s3.get_object(Bucket=BUCKET, Key=item["Key"])
            data = json.loads(obj["Body"].read())

            labels.append({
                "label": label,
                "start": parse_dt(data["start_timestamp"]),
                "end": parse_dt(data["end_timestamp"])
            })

    return labels

# =====================================================================
# LOAD METRICS FROM S3
# =====================================================================

def load_metrics_from_s3():
    """
    Scans metrics/ folder and returns ALL metrics as:
    {timestamp, value}
    """

    metrics = []

    resp = s3.list_objects_v2(Bucket=BUCKET, Prefix="metrics/")

    if "Contents" not in resp:
        return metrics

    for item in resp["Contents"]:
        obj = s3.get_object(Bucket=BUCKET, Key=item["Key"])
        data = json.loads(obj["Body"].read())

        ts = parse_dt(data["timestamp"])
        value = data["value"]

        metrics.append({"timestamp": ts, "value": value})

    return metrics

# =====================================================================
# MATCH METRICS TO LABEL WINDOWS
# =====================================================================

def generate_training_datasets():
    labels = load_labels_from_s3()
    metrics = load_metrics_from_s3()

    # Prepare dataset buckets
    dataset = {
        "cpu": [],
        "memory": [],
        "latency": [],
        "traffic": [],
        "pod_crash": []
    }

    # Match metrics to windows
    for metric in metrics:
        ts = metric["timestamp"]

        for window in labels:
            if window["start"] <= ts <= window["end"]:
                dataset[window["label"]].append({
                    "timestamp": ts.isoformat(),
                    "value": metric["value"],
                    "label": window["label"]
                })

    # Upload CSVs
    for label, rows in dataset.items():
        csv_data = "timestamp,value,label\n"

        for row in rows:
            csv_data += f"{row['timestamp']},{row['value']},{label}\n"

        key = f"training-data/{label}.csv"

        s3.put_object(
            Bucket=BUCKET,
            Key=key,
            Body=csv_data,
            ContentType="text/csv"
        )

    return {"status": "training data generated"}

# =====================================================================
# EXISTING CODE: PROCESS REAL-TIME KINESIS (UNMODIFIED BELOW)
# =====================================================================

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

def detect_type(record):
    if "metric_type" in record:
        return "metric"
    if "level" in record or "log" in record or "message" in record:
        return "log"
    return "unknown"

def upload_to_s3(normalized, record_type):
    folder = "normalized/metrics" if record_type == "metric" else "normalized/logs"
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

# =====================================================================
# MAIN HANDLER
# =====================================================================

def handler(event, context):

    # ------------------------------------------------------------
    # MODE 1 → GENERATE DATASET
    # ------------------------------------------------------------
    if event.get("generate_dataset") == True:
        return generate_training_datasets()

    # ------------------------------------------------------------
    # MODE 2 → NORMAL KINESIS PROCESSING
    # ------------------------------------------------------------
    results = []

    if "Records" not in event:
        return {"status": "no live records"}

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
