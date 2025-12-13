import boto3
import json
import os
import requests
from datetime import datetime, timezone
from botocore.exceptions import ClientError
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")

# Fetch Secrets from AWS Secrets Manager
def get_secret():
    client = boto3.client("secretsmanager", region_name="ap-south-1")
    response = client.get_secret_value(SecretId="AIOps-Platform-Secrets")
    secret = json.loads(response["SecretString"])
    return secret["AUTOHEAL_URL"], secret["API_KEY"]

# Fetch these values from AWS Secret Manager
AUTOHEAL_URL, API_KEY = get_secret()

TABLE_NAME = os.environ["DYNAMODB_TABLE"]

table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    print("Event", event)
    
    for record in event["Records"]:
        print("Record", record)
        data = json.loads(record["Sns"]["Message"])
        print("Data: ", data)

        metric = data["metric_type"]
        value = Decimal(str(data["value"]))
        node = data.get("node", "unknown")
        incident_id = data.get("incident_id", "unknown")

        print("Metric is", metric)
        
        # Decision
        if metric == "cpu":
            endpoint = "/heal/cpu"
            action = "scale-backend"
        elif metric == "memory":
            endpoint = "/heal/memory"
            action = "restart-pod"
        elif metric == "traffic":
            endpoint = "/heal/traffic"
            action = "scale-frontend"
        else:
            print("Unknown metric")
            continue

        # Call Auto-Heal Service
        print("Calling API: ", AUTOHEAL_URL + endpoint)
        try:
            res = requests.post(
                AUTOHEAL_URL + endpoint,
                # sending aiops-secret in header for authentication
                headers = { "x-api-key": API_KEY },
                timeout=3
            )
            status = "success" if res.status_code == 200 else "failed"
            print("response is: ", res)
        except Exception as e:
            print("Auto-heal failed:", e)
            status = "failed"

        # Store heal record
        try:
            table.put_item(
                Item={
                    "incident_id": incident_id,
                    "heal_id": f"heal-{datetime.now(timezone.utc).timestamp()}",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "metric": metric,
                    "value": value,
                    "node": node,
                    "action": action,
                    "status": status
                }
            )
            print("Healing Record added to DB")
        except Exception as e:
            print("Failed to add incident report into db", e)

    return {"status": "processed"}