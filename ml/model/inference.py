"""
PetClinic ML Model Inference Script
Handles model loading and prediction for SageMaker Endpoint.
"""

import os
import json
import joblib
import numpy as np


def model_fn(model_dir):
    """Load the trained model and label encoder from model_dir."""
    model = joblib.load(os.path.join(model_dir, "model.joblib"))
    label_encoder = joblib.load(os.path.join(model_dir, "label_encoder.joblib"))
    return {"model": model, "label_encoder": label_encoder}


def input_fn(request_body, request_content_type):
    """Deserialize input data."""
    if request_content_type == "application/json":
        data = json.loads(request_body)
        if isinstance(data, dict):
            data = [data]
        return data
    raise ValueError(f"Unsupported content type: {request_content_type}")


def predict_fn(input_data, model_artifacts):
    """Make predictions using the loaded model."""
    model = model_artifacts["model"]
    label_encoder = model_artifacts["label_encoder"]

    predictions = []
    for record in input_data:
        pet_type_encoded = label_encoder.transform([record.get("pet_type", "dog")])[0]
        features = np.array([[
            record.get("pet_age", 5),
            pet_type_encoded,
            record.get("visit_count", 3),
            record.get("previous_no_show", 0),
        ]])
        prob = model.predict_proba(features)[0]
        prediction = model.predict(features)[0]

        predictions.append({
            "prediction": int(prediction),
            "probability_miss": float(prob[1]),
            "probability_attend": float(prob[0]),
            "label": "Will Miss" if prediction == 1 else "Will Attend",
        })

    return predictions


def output_fn(prediction, accept):
    """Serialize predictions."""
    if accept == "application/json":
        return json.dumps(prediction), "application/json"
    raise ValueError(f"Unsupported accept type: {accept}")
