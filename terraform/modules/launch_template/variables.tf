variable "name_prefix" {
  description = "The prefix for the launch template name."
  type        = string
}

variable "image_id" {
  description = "The AMI ID to use for instances launched by the autoscaling group."
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for instances launched by the autoscaling group."
  type        = string
}

variable "key_name" {
  description = "The EC2 key pair name for SSH access."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to assign to the launch template."
  type        = map(string)
  default     = {}
}