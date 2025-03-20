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

# Randomly generate a strong password for the RDS master user
resource "random_password" "db_master_password" {
  length           = 41
  special          = false
  override_special = "_%@!"
}

# Create a KMS Key if no KMS Key ID is provided
resource "aws_kms_key" "rds_key" {
  description         = "KMS key for encrypting RDS cluster"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow RDS Usage"
        Effect    = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "rds.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Use the provided KMS Key or fallback to the one created in this module
locals {
  kms_key_id = var.kms_key_id != "" ? var.kms_key_id : aws_kms_key.rds_key.arn
}

# Create security group if not provided
resource "aws_security_group" "rds_sg" {
  count = length(var.security_group_ids) > 0 ? 0 : 1

  name        = "${var.db_cluster_name}-rds-sg"
  description = "Security group for the RDS cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allow_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Create subnets if not provided
resource "aws_subnet" "rds_subnet" {
  count = length(var.subnet_ids) > 0 ? 0 : 3

  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 12) # Offset to avoid conflicts
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name        = "${var.db_cluster_name}-subnet-${count.index}"
      Description = "Subnet for ${var.db_cluster_name} in AZ ${element(data.aws_availability_zones.available.names, count.index)}"
    }
  )
}

# Store the generated credentials securely in AWS Secrets Manager
resource "aws_secretsmanager_secret" "aurora_credentials" {
  name        = "${var.db_cluster_name}-credentials-${replace(timestamp(), ":", "-")}"
  description = "Credentials for Aurora RDS cluster"
  kms_key_id  = local.kms_key_id

  tags = var.tags

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_secretsmanager_secret_version" "aurora_credentials_version" {
  secret_id     = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode({
    username = var.db_master_user
    password = random_password.db_master_password.result
  })
}

# RDS Cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier           = var.db_cluster_name
  engine                       = var.db_engine
  engine_version               = var.db_engine_version
  master_username              = var.db_master_user
  master_password              = random_password.db_master_password.result
  database_name                = var.db_master_name
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "Mon:00:00-Mon:03:00"
  storage_encrypted            = true
  kms_key_id                   = local.kms_key_id
  vpc_security_group_ids       = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.rds_sg[0].id]
  db_subnet_group_name         = aws_db_subnet_group.aurora_subnet.name
  tags                         = var.tags

  # Serverless scaling (conditionally applied)
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.enable_serverless ? [1] : []
    content {
      min_capacity = var.min_capacity
      max_capacity = var.max_capacity
    }
  }

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.db_cluster_name}-final-snapshot"
}

# Subnet group for the RDS cluster
resource "aws_db_subnet_group" "aurora_subnet" {
  name       = "${var.db_cluster_name}-subnet-group"
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : aws_subnet.rds_subnet[*].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.db_cluster_name}-subnet-group"
      Description = "Subnet group for ${var.db_cluster_name}"
    }
  )
}

# Caller identity for AWS account information
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Availability zones for subnets
data "aws_availability_zones" "available" {}