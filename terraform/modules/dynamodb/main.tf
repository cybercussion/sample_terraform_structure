terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

resource "aws_dynamodb_table" "this" {
  name           = var.table_name
  billing_mode   = var.billing_mode
  hash_key       = var.hash_key

  # Primary key definition
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  # Optional range key
  dynamic "attribute" {
    for_each = var.range_key != null ? [1] : []
    content {
      name = var.range_key
      type = var.range_key_type
    }
  }

  # Range key support
  range_key = var.range_key

  # Optional Global Secondary Indexes (GSI)
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      projection_type    = global_secondary_index.value.projection_type
      read_capacity      = lookup(global_secondary_index.value, "read_capacity", null)
      write_capacity     = lookup(global_secondary_index.value, "write_capacity", null)
    }
  }

  # Optional TTL (Time to Live)
  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      attribute_name = var.ttl_attribute_name
      enabled        = true
    }
  }

  # Optional server-side encryption
  server_side_encryption {
    enabled     = var.encryption_enabled
    kms_key_arn = var.kms_key_arn
  }

  # Tags for the table
  tags = var.tags
}