"""
PetClinic ML Model Training Script
Trains a RandomForest classifier to predict appointment no-shows.
Compatible with SageMaker Training Jobs.
"""

import argparse
import os
import joblib
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import LabelEncoder


def parse_args():
    parser = argparse.ArgumentParser(description="Train PetClinic No-Show Prediction Model")
    parser.add_argument("--n-estimators", type=int, default=100)
    parser.add_argument("--max-depth", type=int, default=10)
    parser.add_argument("--test-size", type=float, default=0.2)
    parser.add_argument("--random-state", type=int, default=42)

    # SageMaker specific arguments
    parser.add_argument("--model-dir", type=str, default=os.environ.get("SM_MODEL_DIR", "/opt/ml/model"))
    parser.add_argument("--train", type=str, default=os.environ.get("SM_CHANNEL_TRAIN", "/opt/ml/input/data/train"))
    parser.add_argument("--output-data-dir", type=str,
                        default=os.environ.get("SM_OUTPUT_DATA_DIR", "/opt/ml/output/data"))

    return parser.parse_args()


def load_data(train_dir):
    """Load training data from the SageMaker input channel."""
    input_files = [
        os.path.join(train_dir, f)
        for f in os.listdir(train_dir)
        if f.endswith(".csv")
    ]
    if not input_files:
        raise ValueError(f"No CSV files found in {train_dir}")

    df = pd.concat([pd.read_csv(f) for f in input_files], ignore_index=True)
    print(f"Loaded {len(df)} records from {len(input_files)} file(s)")
    return df


def preprocess(df):
    """Encode categorical features and prepare X, y."""
    le = LabelEncoder()
    df["pet_type_encoded"] = le.fit_transform(df["pet_type"])

    feature_columns = ["pet_age", "pet_type_encoded", "visit_count", "previous_no_show"]
    X = df[feature_columns]
    y = df["miss_next_visit"]

    return X, y, le


def train_model(X_train, y_train, args):
    """Train the RandomForest classifier."""
    model = RandomForestClassifier(
        n_estimators=args.n_estimators,
        max_depth=args.max_depth,
        random_state=args.random_state,
        n_jobs=-1,
    )
    model.fit(X_train, y_train)
    return model


def evaluate_model(model, X_test, y_test):
    """Evaluate and print model metrics."""
    predictions = model.predict(X_test)
    accuracy = accuracy_score(y_test, predictions)
    print(f"\nModel Accuracy: {accuracy:.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, predictions, target_names=["Will Attend", "Will Miss"]))
    return accuracy


def save_model(model, label_encoder, model_dir):
    """Save model artifacts for SageMaker."""
    os.makedirs(model_dir, exist_ok=True)
    joblib.dump(model, os.path.join(model_dir, "model.joblib"))
    joblib.dump(label_encoder, os.path.join(model_dir, "label_encoder.joblib"))
    print(f"Model saved to {model_dir}")


if __name__ == "__main__":
    args = parse_args()
    print("=" * 60)
    print("PetClinic Appointment No-Show Prediction - Training")
    print("=" * 60)
    print(f"Parameters: n_estimators={args.n_estimators}, max_depth={args.max_depth}")

    # Load and preprocess data
    df = load_data(args.train)
    X, y, label_encoder = preprocess(df)

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=args.test_size, random_state=args.random_state
    )
    print(f"Training set: {len(X_train)} samples")
    print(f"Test set: {len(X_test)} samples")

    # Train
    model = train_model(X_train, y_train, args)

    # Evaluate
    accuracy = evaluate_model(model, X_test, y_test)

    # Save
    save_model(model, label_encoder, args.model_dir)

    print("\nTraining complete!")
