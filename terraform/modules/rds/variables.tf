variable "db_cluster_name" {
  description = "The name of the RDS cluster"
  type        = string
}

variable "db_engine" {
  description = "The database engine type (e.g., aurora-postgresql)"
  type        = string
  default     = "aurora-postgresql"
}

variable "db_engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = "15.3"
}

variable "db_master_user" {
  description = "The master username for the database"
  type        = string
  default     = "postgres"
}

variable "db_master_password" {
  description = "The master password for the database"
  type        = string
  default     = "change-me-later"
}

variable "db_master_name" {
  description = "The default database name"
  type        = string
  default     = "postgres"
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "min_capacity" {
  description = "Minimum ACU for serverless"
  type        = number
  default     = 0.5
}

variable "max_capacity" {
  description = "Maximum ACU for serverless"
  type        = number
  default     = 8
}

variable "kms_key_id" {
  description = "KMS key ID for encryption. Leave empty to create a new one."
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "List of existing security group IDs for the RDS cluster. Leave empty to create a new security group."
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of existing subnet IDs for the RDS cluster. Leave empty to create new subnets."
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "The VPC ID where RDS and associated resources will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC for dynamically creating subnets"
  type        = string
}

variable "enable_iam_authentication" {
  description = "Enable IAM authentication for the RDS cluster"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "allow_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the RDS cluster. Used when creating a security group dynamically."
  type        = list(string)
  default     = ["0.0.0.0/0"] # Replace with your CIDR blocks for better security
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when destroying the RDS cluster"
  type        = bool
  default     = false
}

variable "enable_serverless" {
  description = "Enable Aurora Serverless. Set to false for provisioned instances."
  type        = bool
  default     = true
}