terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88.0"
    }
  }

  backend "s3" {}
}

resource "aws_ecr_repository" "repo" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
  # lifecycle {
  #   ignore_changes = [repository_url]
  # }

  force_delete = true
  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "repo_lifecycle" {
  repository = aws_ecr_repository.repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.untagged_expiry_days} days"
        selection    = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.max_tagged_images} tagged images with a specific prefix"
        selection    = {
          tagStatus   = "tagged"
          tagPrefixList = ["latest", "release", "prod"]  # Define your tag prefixes here
          countType   = "imageCountMoreThan"
          countNumber = var.max_tagged_images
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "null_resource" "push_placeholder_image" {
  depends_on = [aws_ecr_repository.repo]

  count = var.enable_placeholder_image ? 1 : 0 
  triggers = {
    repo_url = aws_ecr_repository.repo.repository_url
    image    = var.placeholder_image
    tag      = var.placeholder_tag
  }
  provisioner "local-exec" {
    command = <<EOT
    if ! command -v aws &> /dev/null; then
      echo "Error: AWS CLI is not installed or not found in PATH."
      exit 1
    fi
    if ! command -v docker &> /dev/null; then
      echo "Error: Docker is not installed or not found in PATH."
      exit 1
    fi

    if ! docker info &> /dev/null; then
      echo "Error: Docker daemon is not running."
      exit 1
    fi

    aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.repo.repository_url}

    # Pull the correct architecture image
    docker pull --platform linux/amd64 ${var.placeholder_image}
    
    # Retag the pulled image with the correct architecture before pushing
    docker tag $(docker images --format "{{.Repository}}:{{.Tag}}" | grep "${var.placeholder_image}") ${aws_ecr_repository.repo.repository_url}:${var.placeholder_tag}
    
    # Push the image to ECR
    docker push ${aws_ecr_repository.repo.repository_url}:${var.placeholder_tag}
    EOT
  }
}

resource "null_resource" "delete_all_images" {
  triggers = {
    repo_name = var.repository_name
    region    = var.region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
    set -e

    # Check if repository exists before trying to delete images
    REPO_EXISTS=$(aws ecr describe-repositories --repository-names "$REPO_NAME" --region ${self.triggers.region} 2>/dev/null || echo "notfound")

    if [ "$REPO_EXISTS" != "notfound" ]; then
      IMAGES=$(aws ecr list-images --repository-name "$REPO_NAME" --region ${self.triggers.region} --query 'imageIds[*]' --output json)
      
      if [ "$IMAGES" != "[]" ]; then
        aws ecr batch-delete-image --repository-name "$REPO_NAME" --region ${self.triggers.region} --image-ids "$IMAGES"
      fi
    else
      echo "Repository $REPO_NAME does not exist. Skipping image deletion."
    fi
    EOT
  }
}