"""
Local training script - trains the model and uploads to S3.
Run this on any machine with Python + sklearn + boto3 installed.

Usage: python ml/scripts/train_local.py
"""
import os
import sys
import json
import tarfile
import tempfile

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import LabelEncoder
import joblib
import boto3

REGION = "us-east-1"
ACCOUNT_ID = "633426742056"
BUCKET = f"petclinic-mlops-data-{ACCOUNT_ID}"
MODEL_S3_KEY = "model-output/model.tar.gz"
ENDPOINT_NAME = "petclinic-predict-endpoint"


def train():
    print("=" * 60)
    print("PetClinic No-Show Prediction - Local Training")
    print("=" * 60)

    # Load data
    data_path = os.path.join(os.path.dirname(__file__), "..", "data", "train.csv")
    df = pd.read_csv(data_path)
    print(f"Loaded {len(df)} samples")

    # Preprocess
    le = LabelEncoder()
    df["pet_type_encoded"] = le.fit_transform(df["pet_type"])
    X = df[["pet_age", "pet_type_encoded", "visit_count", "previous_no_show"]]
    y = df["miss_next_visit"]

    # Split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Train
    model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
    model.fit(X_train, y_train)

    # Evaluate
    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)
    print(f"\nAccuracy: {acc:.4f}")
    print(classification_report(y_test, preds, target_names=["Will Attend", "Will Miss"]))

    # Save model
    with tempfile.TemporaryDirectory() as tmpdir:
        model_path = os.path.join(tmpdir, "model.joblib")
        le_path = os.path.join(tmpdir, "label_encoder.joblib")
        joblib.dump(model, model_path)
        joblib.dump(le, le_path)

        # Create model.tar.gz (SageMaker format)
        tar_path = os.path.join(tmpdir, "model.tar.gz")
        with tarfile.open(tar_path, "w:gz") as tar:
            tar.add(model_path, arcname="model.joblib")
            tar.add(le_path, arcname="label_encoder.joblib")

        # Upload to S3
        s3 = boto3.client("s3", region_name=REGION)
        s3.upload_file(tar_path, BUCKET, MODEL_S3_KEY)
        print(f"\nModel uploaded to s3://{BUCKET}/{MODEL_S3_KEY}")

    return f"s3://{BUCKET}/{MODEL_S3_KEY}"


if __name__ == "__main__":
    train()
    print("\nDone! Model is ready for SageMaker endpoint deployment.")
