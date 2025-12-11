import boto3
import json
import os
from datetime import datetime, timezone

s3 = boto3.client("s3")
BUCKET = os.environ.get("TARGET_BUCKET")

def current_ts():
    return datetime.now(timezone.utc).isoformat()

def handler(event, context):
    action = event.get("action")       # start / end
    label  = event.get("label")        # cpu / memory / traffic ...

    if action not in ["start", "end"]:
        return {"error": "action must be start or end"}

    if label not in ["cpu", "memory", "traffic", "latency", "pod_crash"]:
        return {"error": "invalid label"}

    prefix = f"training/{label}/"

    # ----------------------------------------------------
    # START EVENT → create new file
    # ----------------------------------------------------
    if action == "start":
        ts = current_ts()
        key = f"{prefix}event-{ts.replace(':','-')}.json"

        body = {
            "label": label,
            "start_timestamp": ts,
            "end_timestamp": None
        }

        s3.put_object(
            Bucket=BUCKET,
            Key=key,
            Body=json.dumps(body),
            ContentType="application/json"
        )

        return {"status": "start recorded", "file": key}

    # ----------------------------------------------------
    # END EVENT → update latest open file
    # ----------------------------------------------------
    resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix)

    open_events = []
    for item in resp.get("Contents", []):
        obj = s3.get_object(Bucket=BUCKET, Key=item["Key"])
        data = json.loads(obj["Body"].read())

        if data["end_timestamp"] is None:
            open_events.append((item["Key"], data))

    if not open_events:
        return {"error": "No open event to close!"}

    # get latest file
    key, data = sorted(open_events)[-1]

    data["end_timestamp"] = current_ts()

    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=json.dumps(data),
        ContentType="application/json"
    )

    return {"status": "end recorded", "file": key}
