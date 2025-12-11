import os
import boto3
import joblib
import pandas as pd
from sklearn.ensemble import IsolationForest

# ---------------------------
# CONFIG
# ---------------------------
LOCAL_TRAINING_DIR = "training-data/"
LOCAL_MODEL_DIR = "models/"
S3_BUCKET = "aiopsplatform-data-bucket"

os.makedirs(LOCAL_TRAINING_DIR, exist_ok=True)
os.makedirs(LOCAL_MODEL_DIR, exist_ok=True)

s3 = boto3.client("s3")

# ---------------------------
# EXPECTED DATASETS
# ---------------------------
DATASETS = {
    "cpu": "cpu.csv",
    "memory": "memory.csv",
    "traffic": "traffic.csv"
}

# ---------------------------
# DOWNLOAD CSV FROM S3
# ---------------------------
def download_csv_from_s3(label):
    key = f"training-data/{label}.csv"
    local_path = os.path.join(LOCAL_TRAINING_DIR, f"{label}.csv")

    try:
        s3.download_file(S3_BUCKET, key, local_path)
        print(f"⬇ Downloaded: s3://{S3_BUCKET}/{key}")
        return local_path
    except Exception as e:
        print(f"❌ Could not download {key} - {e}")
        return None


# ---------------------------
# TRAIN ISOLATION FOREST
# ---------------------------
def train_model(label, csv_path):

    print(f"\n🔹 Training model for: {label}")

    df = pd.read_csv(csv_path)

    if df.empty:
        print(f"⚠ No data found for {label}, skipping...")
        return None

    X = df[['value']]   # Only numeric feature

    model = IsolationForest(
        n_estimators=200,
        contamination=0.01,
        random_state=42
    )

    model.fit(X)

    model_path = f"{LOCAL_MODEL_DIR}/{label}_model.pkl"
    joblib.dump(model, model_path)

    print(f"✔ Saved model: {model_path}")
    return model_path


# ---------------------------
# UPLOAD MODEL TO S3
# ---------------------------
def upload_model_to_s3(local_path):
    key = f"models/{os.path.basename(local_path)}"
    s3.upload_file(local_path, S3_BUCKET, key)
    print(f"⬆ Uploaded to S3 → s3://{S3_BUCKET}/{key}")


# ---------------------------
# MAIN WORKFLOW
# ---------------------------
def main():
    print("\n===============================")
    print("AIOps Model Training Started")
    print("===============================\n")

    for label in DATASETS.keys():

        # Step 1 — Download CSV
        csv_path = download_csv_from_s3(label)
        if not csv_path or not os.path.exists(csv_path):
            print(f"❌ Missing training file: {label}.csv")
            continue

        # Step 2 — Train model
        model_file = train_model(label, csv_path)
        if not model_file:
            continue

        # Step 3 — Upload to S3
        upload_model_to_s3(model_file)

    print("\n🎉 Training complete! Models uploaded successfully.\n")


if __name__ == "__main__":
    main()
