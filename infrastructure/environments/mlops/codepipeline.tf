# ============================================================
# CodePipeline + CodeBuild (us-east-1)
# ============================================================

# Artifacts bucket
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "petclinic-mlops-pipeline-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "petclinic-mlops-pipeline-artifacts"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# CodeBuild Role
resource "aws_iam_role" "codebuild_role" {
  name = "petclinic-mlops-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "petclinic-mlops-codebuild-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:GetBucketLocation", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn, "${aws_s3_bucket.pipeline_artifacts.arn}/*",
          aws_s3_bucket.ml_data.arn, "${aws_s3_bucket.ml_data.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:*"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreatePipeline", "sagemaker:UpdatePipeline",
          "sagemaker:StartPipelineExecution", "sagemaker:DescribePipelineExecution"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = aws_iam_role.sagemaker_role.arn
      },
      {
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = aws_eks_cluster.petclinic.arn
      }
    ]
  })
}

# CodeBuild - Build App Image & Push to ECR
resource "aws_codebuild_project" "app_build" {
  name         = "petclinic-mlops-app-build"
  description  = "Build PetClinic Docker image and push to ECR"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "ECR_REPO_APP"
      value = aws_ecr_repository.petclinic_app.repository_url
    }
    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = aws_eks_cluster.petclinic.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-app.yml"
  }

  tags = {
    Name        = "petclinic-mlops-app-build"
    Environment = var.environment
  }
}

# CodeBuild - Build ML Container & Trigger SageMaker Pipeline
resource "aws_codebuild_project" "ml_build" {
  name         = "petclinic-mlops-ml-build"
  description  = "Build ML container and trigger SageMaker Pipeline"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "ECR_REPO_ML"
      value = aws_ecr_repository.petclinic_ml.repository_url
    }
    environment_variable {
      name  = "SAGEMAKER_ROLE_ARN"
      value = aws_iam_role.sagemaker_role.arn
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-ml.yml"
  }

  tags = {
    Name        = "petclinic-mlops-ml-build"
    Environment = var.environment
  }
}

# CodePipeline Role
resource "aws_iam_role" "codepipeline_role" {
  count = var.codestar_connection_arn != "" ? 1 : 0
  name  = "petclinic-mlops-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "petclinic-mlops-codepipeline-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  count = var.codestar_connection_arn != "" ? 1 : 0
  name  = "codepipeline-policy"
  role  = aws_iam_role.codepipeline_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:GetBucketVersioning", "s3:ListBucket"]
        Resource = [aws_s3_bucket.pipeline_artifacts.arn, "${aws_s3_bucket.pipeline_artifacts.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = [aws_codebuild_project.app_build.arn, aws_codebuild_project.ml_build.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:UseConnection"]
        Resource = var.codestar_connection_arn
      }
    ]
  })
}

# CodePipeline
resource "aws_codepipeline" "mlops" {
  count    = var.codestar_connection_arn != "" ? 1 : 0
  name     = "petclinic-mlops-pipeline"
  role_arn = aws_iam_role.codepipeline_role[0].arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  # Source
  stage {
    name = "Source"
    action {
      name             = "GitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source"]
      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repository
        BranchName       = var.github_branch
      }
    }
  }

  # Build App
  stage {
    name = "Build-App"
    action {
      name             = "BuildApp"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["app_output"]
      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  # Build ML & Trigger SageMaker
  stage {
    name = "Build-ML"
    action {
      name             = "BuildML"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["ml_output"]
      configuration = {
        ProjectName = aws_codebuild_project.ml_build.name
      }
    }
  }

  tags = {
    Name        = "petclinic-mlops-pipeline"
    Environment = var.environment
  }
}
