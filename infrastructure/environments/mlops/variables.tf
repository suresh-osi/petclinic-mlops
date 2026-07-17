# ============================================================
# Variables for PetClinic MLOps (us-east-1)
# ============================================================

variable "aws_region" {
  description = "AWS region for MLOps infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "mlops"
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for MLOps VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.1.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.1.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.1.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.1.4.0/24"
}

variable "availability_zone_1" {
  description = "Availability zone 1"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Availability zone 2"
  type        = string
  default     = "us-east-1b"
}

# EKS
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.31"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.micro"
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 3
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 1
}

# SageMaker
variable "sagemaker_endpoint_name" {
  description = "Name of the SageMaker inference endpoint"
  type        = string
  default     = "petclinic-predict-endpoint"
}

variable "sagemaker_instance_type" {
  description = "Instance type for SageMaker endpoint"
  type        = string
  default     = "ml.t2.medium"
}

variable "sagemaker_instance_count" {
  description = "Number of instances for SageMaker endpoint"
  type        = number
  default     = 1
}

# CI/CD
variable "codestar_connection_arn" {
  description = "ARN of the CodeStar connection to GitHub"
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "suresh-osi/petclinic-mlops"
}

variable "github_branch" {
  description = "GitHub branch to track"
  type        = string
  default     = "main"
}

# Application
variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}
