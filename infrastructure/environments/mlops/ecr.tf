# ============================================================
# ECR Repositories (us-east-1)
# ============================================================

resource "aws_ecr_repository" "petclinic_app" {
  name                 = "petclinic-mlops"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "petclinic-mlops"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "petclinic_ml" {
  name                 = "petclinic-ml-model"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "petclinic-ml-model"
    Environment = var.environment
  }
}

# Lifecycle policies
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.petclinic_app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "ml" {
  repository = aws_ecr_repository.petclinic_ml.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
