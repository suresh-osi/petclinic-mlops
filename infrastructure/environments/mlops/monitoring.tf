# ============================================================
# CloudWatch Monitoring (us-east-1)
# ============================================================

# Log Groups
resource "aws_cloudwatch_log_group" "sagemaker" {
  name              = "/aws/sagemaker/Endpoints/${var.sagemaker_endpoint_name}"
  retention_in_days = 14

  tags = {
    Name        = "petclinic-sagemaker-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "codebuild_app" {
  name              = "/aws/codebuild/petclinic-mlops-app-build"
  retention_in_days = 14

  tags = {
    Name        = "petclinic-codebuild-app-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "codebuild_ml" {
  name              = "/aws/codebuild/petclinic-mlops-ml-build"
  retention_in_days = 14

  tags = {
    Name        = "petclinic-codebuild-ml-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/petclinic-eks-cluster/cluster"
  retention_in_days = 14

  tags = {
    Name        = "petclinic-eks-logs"
    Environment = var.environment
  }
}

# Dashboard
resource "aws_cloudwatch_dashboard" "mlops" {
  dashboard_name = "PetClinic-MLOps"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 3
        properties = {
          markdown = <<-EOT
            # PetClinic MLOps Dashboard (us-east-1)
            
            | Component | Service | Status |
            |-----------|---------|--------|
            | Application | EKS: `petclinic-eks-cluster` | Active |
            | ML Model | SageMaker: `${var.sagemaker_endpoint_name}` | Deployed |
            | CI/CD | CodePipeline: `petclinic-mlops-pipeline` | Active |
            | Container Registry | ECR: `petclinic-mlops`, `petclinic-ml-model` | Ready |
          EOT
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 3
        width  = 12
        height = 6
        properties = {
          title   = "EKS - Pod CPU Utilization"
          view    = "timeSeries"
          metrics = [["ContainerInsights", "pod_cpu_utilization", "ClusterName", "petclinic-eks-cluster"]]
          period  = 300
          stat    = "Average"
          region  = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 3
        width  = 12
        height = 6
        properties = {
          title   = "EKS - Pod Memory Utilization"
          view    = "timeSeries"
          metrics = [["ContainerInsights", "pod_memory_utilization", "ClusterName", "petclinic-eks-cluster"]]
          period  = 300
          stat    = "Average"
          region  = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 9
        width  = 12
        height = 6
        properties = {
          title   = "SageMaker - Invocations"
          view    = "timeSeries"
          metrics = [["AWS/SageMaker", "Invocations", "EndpointName", var.sagemaker_endpoint_name, "VariantName", "primary"]]
          period  = 300
          stat    = "Sum"
          region  = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 9
        width  = 12
        height = 6
        properties = {
          title   = "SageMaker - Model Latency (ms)"
          view    = "timeSeries"
          metrics = [["AWS/SageMaker", "ModelLatency", "EndpointName", var.sagemaker_endpoint_name, "VariantName", "primary"]]
          period  = 300
          stat    = "Average"
          region  = var.aws_region
        }
      }
    ]
  })
}
