"""
Creates model.tar.gz with proper inference.py for SageMaker sklearn container.
"""
import tarfile
import os
import tempfile
import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
import boto3

REGION = "us-east-1"
ACCOUNT_ID = "633426742056"
BUCKET = f"petclinic-mlops-data-{ACCOUNT_ID}"

# Train the model
df = pd.read_csv(os.path.join(os.path.dirname(__file__), "..", "data", "train.csv"))
le = LabelEncoder()
df["pet_type_encoded"] = le.fit_transform(df["pet_type"])
X = df[["pet_age", "pet_type_encoded", "visit_count", "previous_no_show"]]
y = df["miss_next_visit"]

model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
model.fit(X, y)
print(f"Model trained on {len(X)} samples")

# Create inference.py content
inference_py = '''
import joblib
import json
import numpy as np
import os

PET_TYPE_MAP = {"dog": 0, "cat": 1, "bird": 2, "hamster": 3, "snake": 4}

def model_fn(model_dir):
    model = joblib.load(os.path.join(model_dir, "model.joblib"))
    return model

def input_fn(request_body, request_content_type):
    if request_content_type == "application/json":
        data = json.loads(request_body)
        pet_type_enc = PET_TYPE_MAP.get(data.get("pet_type", "dog"), 0)
        features = [[
            data.get("pet_age", 5),
            pet_type_enc,
            data.get("visit_count", 3),
            data.get("previous_no_show", 0)
        ]]
        return np.array(features)
    raise ValueError(f"Unsupported content type: {request_content_type}")

def predict_fn(input_data, model):
    prediction = model.predict(input_data)[0]
    probabilities = model.predict_proba(input_data)[0]
    return {
        "prediction": int(prediction),
        "probability_miss": float(probabilities[1]) if len(probabilities) > 1 else 0.0,
        "probability_attend": float(probabilities[0]),
        "label": "likely_miss" if prediction == 1 else "likely_attend"
    }

def output_fn(prediction, accept):
    return json.dumps(prediction), "application/json"
'''

# Create tar.gz
tmpdir = tempfile.mkdtemp()
joblib.dump(model, os.path.join(tmpdir, "model.joblib"))
joblib.dump(le, os.path.join(tmpdir, "label_encoder.joblib"))

with open(os.path.join(tmpdir, "inference.py"), "w") as f:
    f.write(inference_py)

tar_path = os.path.join(os.path.dirname(__file__), "..", "..", "model.tar.gz")
with tarfile.open(tar_path, "w:gz") as tar:
    tar.add(os.path.join(tmpdir, "model.joblib"), arcname="model.joblib")
    tar.add(os.path.join(tmpdir, "label_encoder.joblib"), arcname="label_encoder.joblib")
    tar.add(os.path.join(tmpdir, "inference.py"), arcname="inference.py")

print(f"Created {tar_path} ({os.path.getsize(tar_path)} bytes)")

# Upload to S3
s3 = boto3.client("s3", region_name=REGION)
s3.upload_file(tar_path, BUCKET, "model-output/model.tar.gz")
print(f"Uploaded to s3://{BUCKET}/model-output/model.tar.gz")
print("Done!")
