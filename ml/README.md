# PetClinic MLOps - Appointment No-Show Prediction

## Overview

This ML feature predicts whether a pet is likely to miss its next appointment based on:
- Pet age
- Pet type
- Visit count history
- Previous no-shows

## Architecture

```
PetClinic (EC2) → REST API → SageMaker Endpoint → Prediction Response
                                    ↑
                          SageMaker Pipeline (Training)
                                    ↑
                              S3 (Training Data)
```

## Directory Structure

```
ml/
├── data/                    # Sample training data
│   └── train.csv
├── model/                   # Model training and inference code
│   ├── train.py
│   ├── inference.py
│   └── requirements.txt
├── pipeline/                # SageMaker Pipeline definition
│   ├── pipeline.py
│   └── config.json
├── docker/                  # Custom container for training/inference
│   └── Dockerfile
└── README.md
```

## Quick Start

### 1. Upload Training Data
```bash
aws s3 cp ml/data/train.csv s3://petclinic-ml-data-<ACCOUNT_ID>/data/train.csv
```

### 2. Run SageMaker Pipeline
```bash
cd ml/pipeline
python pipeline.py
```

### 3. Deploy Model Endpoint
```bash
cd infrastructure/environments/dev
terraform apply
```

### 4. Test Prediction
```bash
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name petclinic-predict-endpoint \
  --content-type application/json \
  --body '{"pet_age":10,"pet_type":"dog","visit_count":1,"previous_no_show":1}' \
  output.json
```
