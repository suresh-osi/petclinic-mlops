# ============================================================
# SageMaker Resources (us-east-1)
# ============================================================

# S3 Bucket for ML Data and Model Artifacts
resource "aws_s3_bucket" "ml_data" {
  bucket = "petclinic-mlops-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "petclinic-mlops-data"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "ml_data" {
  bucket = aws_s3_bucket.ml_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ml_data" {
  bucket = aws_s3_bucket.ml_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# SageMaker Execution Role
resource "aws_iam_role" "sagemaker_role" {
  name = "petclinic-mlops-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "petclinic-mlops-sagemaker-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy" "sagemaker_s3_ecr" {
  name = "sagemaker-s3-ecr"
  role = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [aws_s3_bucket.ml_data.arn, "${aws_s3_bucket.ml_data.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# SageMaker Model Package Group (Model Registry)
resource "aws_sagemaker_model_package_group" "petclinic" {
  model_package_group_name        = "petclinic-noshow-models"
  model_package_group_description = "PetClinic appointment no-show prediction models"

  tags = {
    Name        = "petclinic-noshow-models"
    Environment = var.environment
  }
}
