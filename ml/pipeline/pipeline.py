"""
SageMaker Pipeline Definition for PetClinic No-Show Prediction Model.

This pipeline automates:
1. Data processing
2. Model training
3. Model evaluation
4. Model registration
5. Model deployment to endpoint
"""

import json
import boto3
import sagemaker
from sagemaker.workflow.pipeline import Pipeline
from sagemaker.workflow.steps import TrainingStep, CreateModelStep
from sagemaker.workflow.parameters import ParameterString, ParameterInteger
from sagemaker.sklearn.estimator import SKLearn
from sagemaker.sklearn.model import SKLearnModel
from sagemaker.model_metrics import MetricsSource, ModelMetrics
from sagemaker.workflow.model_step import ModelStep


def load_config():
    """Load pipeline configuration."""
    with open("config.json") as f:
        return json.load(f)


def create_pipeline(config):
    """Create the SageMaker Pipeline."""
    region = config["region"]
    sess = sagemaker.Session(boto_session=boto3.Session(region_name=region))
    role = sagemaker.get_execution_role()
    account_id = boto3.client("sts").get_caller_identity()["Account"]
    bucket = f"{config['s3_bucket']}-{account_id}"

    # Pipeline parameters
    training_instance_type = ParameterString(
        name="TrainingInstanceType",
        default_value=config["training_instance_type"],
    )
    n_estimators = ParameterString(
        name="NEstimators",
        default_value=config["hyperparameters"]["n_estimators"],
    )
    max_depth = ParameterString(
        name="MaxDepth",
        default_value=config["hyperparameters"]["max_depth"],
    )

    # Training step
    sklearn_estimator = SKLearn(
        entry_point="train.py",
        source_dir="../model",
        role=role,
        instance_type=training_instance_type,
        framework_version=config["framework_version"],
        py_version=config["python_version"],
        hyperparameters={
            "n-estimators": n_estimators,
            "max-depth": max_depth,
            "test-size": config["hyperparameters"]["test_size"],
        },
        sagemaker_session=sess,
    )

    train_step = TrainingStep(
        name="TrainPetClinicModel",
        estimator=sklearn_estimator,
        inputs={
            "train": f"s3://{bucket}/data/",
        },
    )

    # Model creation step
    model = SKLearnModel(
        model_data=train_step.properties.ModelArtifacts.S3ModelArtifacts,
        role=role,
        entry_point="inference.py",
        source_dir="../model",
        framework_version=config["framework_version"],
        py_version=config["python_version"],
        sagemaker_session=sess,
    )

    model_step = ModelStep(
        name="RegisterPetClinicModel",
        step_args=model.register(
            content_types=["application/json"],
            response_types=["application/json"],
            inference_instances=["ml.t2.medium", "ml.m5.large"],
            transform_instances=["ml.m5.large"],
            model_package_group_name="petclinic-noshow-models",
            approval_status="PendingManualApproval",
        ),
    )

    # Create pipeline
    pipeline = Pipeline(
        name=config["pipeline_name"],
        parameters=[
            training_instance_type,
            n_estimators,
            max_depth,
        ],
        steps=[train_step, model_step],
        sagemaker_session=sess,
    )

    return pipeline


def main():
    config = load_config()
    pipeline = create_pipeline(config)

    # Upsert (create or update) the pipeline
    pipeline.upsert(
        role_arn=sagemaker.get_execution_role(),
        description="PetClinic Appointment No-Show Prediction MLOps Pipeline",
    )
    print(f"Pipeline '{config['pipeline_name']}' created/updated successfully.")

    # Start pipeline execution
    execution = pipeline.start()
    print(f"Pipeline execution started: {execution.arn}")


if __name__ == "__main__":
    main()
