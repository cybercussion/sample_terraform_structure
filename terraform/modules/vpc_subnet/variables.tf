variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
}

variable "az_1" {
  description = "Availability Zone for subnet 1"
  type        = string
}

variable "az_2" {
  description = "Availability Zone for subnet 2"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}