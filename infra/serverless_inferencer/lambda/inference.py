import boto3
import json
import os
import base64
from datetime import datetime, timezone
import pickle
from uuid import uuid4

dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")
s3 = boto3.client("s3")

INFERENCE_TABLE = os.environ["INFERENCE_TABLE"]
SNS_TOPIC = os.environ["SNS_TOPIC"]
MODEL_BUCKET = os.environ["MODEL_BUCKET"]

table = dynamodb.Table(INFERENCE_TABLE)

# -----------------------------
# Load all models on cold start
# -----------------------------
models = {}

def load_models():
    global models
    # metric_types = ["cpu", "memory", "traffic"]
    metric_types = ["cpu"]

    for m in metric_types:
        key = f"models/{m}_model.pkl"
        try:
            print(f"Loading: {key}")
            obj = s3.get_object(Bucket=MODEL_BUCKET, Key=key)
            body = obj["Body"].read()
            models[m] = pickle.loads(body)
            print(f"Loaded model: {m}")
        except Exception as e:
            print(f"ERROR loading model {m}: {e}")
            models[m] = None
            
load_models()


# -----------------------------
# Predict anomaly
# -----------------------------
def predict(model, value):
    if model is None:
        return 1  # no anomaly detection possible
    try:
        result = model.predict([[value]])
        return int(result[0])
    except Exception as e:
        print("Prediction error:", e)
        return 1
    
    
# -----------------------------
# Store incident
# -----------------------------
def store_incident(item):
    table.put_item(Item=item)
    print(f"Storing incident in {table} DynamoDB Table")
    

# -----------------------------
# Send SNS alert
# -----------------------------
def send_alert(item):
    message = f"""
AIOps Anomaly Detected 

Metric: {item['metric_type']}
Value: {item['value']}
Node: {item['node']}
Prediction: {item['prediction']}
Severity: HIGH
Timestamp: {item['timestamp']}
"""
    sns.publish(
        TopicArn=SNS_TOPIC,
        Subject="AIOps Incident Alert",
        Message=message
    )
    print(f"Pushing message to SNS Topic {SNS_TOPIC}")

# -----------------------------
# Handler
# -----------------------------
def handler(event, context):
    results = []

    print("handler started")
    
    for record in event["Records"]:
        payload = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")
        metric = json.loads(payload)

        metric_type = metric["metric_type"]
        value = float(metric["value"])

        model = models.get(metric_type)
        pred = predict(model, value)   # -1 → anomaly

        if pred == -1:
            incident = {
                "incident_id": str(uuid4()),
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "metric_type": metric_type,
                "value": value,
                "node": metric.get("node", "unknown"),
                "service": metric.get("service", "unknown"),
                "prediction": "-1",
                "severity": "high"
            }

            store_incident(incident)
            send_alert(incident)

        results.append({"metric_type": metric_type, "prediction": pred})

    return {"processed": len(results), "results": results}