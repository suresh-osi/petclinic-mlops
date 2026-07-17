# ============================================================
# Outputs (us-east-1 MLOps)
# ============================================================

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.petclinic.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.petclinic.endpoint
}

output "eks_cluster_security_group" {
  description = "EKS cluster security group"
  value       = aws_eks_cluster.petclinic.vpc_config[0].cluster_security_group_id
}

output "ecr_app_repository_url" {
  description = "ECR repository URL for PetClinic app"
  value       = aws_ecr_repository.petclinic_app.repository_url
}

output "ecr_ml_repository_url" {
  description = "ECR repository URL for ML model"
  value       = aws_ecr_repository.petclinic_ml.repository_url
}

output "ml_data_bucket" {
  description = "S3 bucket for ML data"
  value       = aws_s3_bucket.ml_data.bucket
}

output "sagemaker_role_arn" {
  description = "SageMaker execution role ARN"
  value       = aws_iam_role.sagemaker_role.arn
}

output "codepipeline_name" {
  description = "CodePipeline name"
  value       = var.codestar_connection_arn != "" ? aws_codepipeline.mlops[0].name : "not-deployed (set codestar_connection_arn first)"
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=PetClinic-MLOps"
}

output "eks_kubectl_config" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.petclinic.name} --region ${var.aws_region}"
}
