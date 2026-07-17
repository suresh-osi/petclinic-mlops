# SageMaker compatible container for PetClinic ML model
FROM python:3.10-slim

# Install dependencies
COPY ml/model/requirements.txt /opt/ml/code/requirements.txt
RUN pip install --no-cache-dir -r /opt/ml/code/requirements.txt

# Copy model code
COPY ml/model/train.py /opt/ml/code/train.py
COPY ml/model/inference.py /opt/ml/code/inference.py

# SageMaker expects the training script at this location
ENV SAGEMAKER_PROGRAM train.py

WORKDIR /opt/ml/code

ENTRYPOINT ["python", "train.py"]
