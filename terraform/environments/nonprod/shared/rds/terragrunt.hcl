# Include the root Terragrunt configuration (remote state setup, etc.)
include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/rds" # Adjust this path to match your RDS module location
}

# Input variables for the Terraform module
inputs = {
  db_cluster_name         = "project-cluster"             # Customize for your cluster
  db_engine               = "aurora-postgresql"
  db_engine_version       = "15.3"
  skip_final_snapshot     = true                             # You would want false in production
  db_master_user          = "postgres"                       # Default master username for PostgreSQL
  db_master_name          = "project_nonprod_db"
  backup_retention_period = 7

  # Blank out to dynamically create security group and subnets
  security_group_ids      = []
  subnet_ids              = []
  vpc_id                  = "vpc-0e7abce5bf76aa89d"          # Your VPC ID
  vpc_cidr                = "172.16.0.0/16"                  # CIDR block for dynamic subnet creation
  # allow_ingress_cidr_blocks = ["192.168.0.0/24"]

  # Serverless scaling configuration
  min_capacity            = 0.5
  max_capacity            = 8

  # Tags for resources
  tags = {
    Environment = "nonprod"
    Project     = "project-rds"
    Owner       = "your-team"
  }
}