variable "region" {
  description = "AWS region where the cluster will be created"
  type        = string
}

variable "admin_users" {
  description = "List of IAM users to be given admin access to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "use_fargate" {
  description = "Set to true to use Fargate, false to use EC2-based node groups."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_ssm_path" {
  description = "The SSM parameter path for the VPC ID."
  type        = string
}

# Public Subnets for EKS Cluster
variable "subnet_ssm_paths_public" {
  description = "List of SSM Parameter paths to retrieve public subnet IDs."
  type        = list(string)
}

# Private Subnets for Fargate
variable "subnet_ssm_paths_private" {
  description = "List of SSM Parameter paths to retrieve private subnet IDs for Fargate."
  type        = list(string)
}

variable "node_groups" {
  description = "Configuration for EC2-based node groups (both EKS-managed and self-managed)."
  type = map(object({
    desired_capacity = number
    max_size         = number
    min_size         = number
    instance_types   = list(string)
    key_name         = string
  }))
  default = {}
}

variable "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  type        = string
}

variable "fargate_profiles" {
  description = "Fargate profiles for the EKS cluster."
  type = list(object({
    name                   = string
    pod_execution_role_arn = string
    selectors              = list(object({
      namespace = string
      labels    = optional(map(string)) # Include labels as optional
    }))
  }))
  default = []
}
# variable "fargate_profiles" {
#   description = "Fargate profiles for the EKS cluster."
#   type = list(object({
#     name                   = string
#     pod_execution_role_arn = string
#     selectors              = list(object({
#       namespace = string
#     }))
#   }))
#   default = []
# }
# variable "fargate_profiles" {
#   description = "Map of Fargate profiles for the EKS cluster"
#   type = map(object({
#     name                   = string
#     pod_execution_role_arn = string
#     selectors = list(object({
#       namespace = string
#     }))
#   }))
#   default = {}
# }

# Enable or Disable EKS Auto Mode
variable "enable_eks_auto_mode" {
  description = "Flag to enable or disable EKS Auto Mode for automatic scaling"
  type        = bool
  default     = false  # Set to true if you want to enable Auto Mode by default
}

# Note if you were using EC2's you'd want a eks_node_role
variable "eks_admin_role" {
  description = "The name of the IAM role for EKS cluster administrators"
  type        = string
}

variable "aws_auth_roles" {
  description = "List of role maps to add to the aws-auth configmap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "nonprod"
    Project     = "MyProject"
    Owner       = "YourNameOrTeam"
    ManagedBy   = "Terraform"
  }
}