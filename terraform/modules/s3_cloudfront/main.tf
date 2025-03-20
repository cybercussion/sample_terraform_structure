terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88.0" # Or use a specific compatible version like 5.76.0
    }
  }

  backend "s3" {}
}

data "aws_ssm_parameter" "domain" {
  name = var.ssm_domain_param
}

data "aws_ssm_parameter" "certificate" {
  name = var.ssm_cert_param
}

resource "aws_s3_bucket" "spa_bucket" {
  bucket = "${var.app_name}-${var.env}.${data.aws_ssm_parameter.domain.value}"
}

resource "aws_s3_bucket_website_configuration" "spa_website" {
  bucket = aws_s3_bucket.spa_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.spa_bucket.id

  cors_rule {
    allowed_headers = ["Authorization", "Date", "Content-Type", "Content-Length"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["Date", "ETag", "Connection", "Content-Length"]
    max_age_seconds = 3000
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for CloudFront to S3"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.spa_bucket.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "PolicyForCloudFrontOAI"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.spa_bucket.arn}/*"
      },
      {
        Sid    = "DenyPublicRead"
        Effect = "Deny"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.spa_bucket.arn}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = false
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "cf_distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.spa_bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"] # Newly added required attribute
    compress         = true
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.cache_behaviors
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      allowed_methods  = ordered_cache_behavior.value.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cached_methods
      compress         = ordered_cache_behavior.value.compress
      target_origin_id = "S3Origin"

      forwarded_values {
        query_string = ordered_cache_behavior.value.forwarded_values.query_string
        cookies {
          forward = ordered_cache_behavior.value.forwarded_values.cookies.forward
        }
      }

      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy

      # Set Cache-Control using Response Headers Policy
      response_headers_policy_id = aws_cloudfront_response_headers_policy.cache_control[ordered_cache_behavior.key].id
    }
  }

  custom_error_response {
    error_code          = 403
    response_code       = 200
    response_page_path  = "/index.html"
  }

  custom_error_response {
    error_code          = 404
    response_code       = 200
    response_page_path  = "/index.html"
  }

  aliases = [
    "${var.app_name}-${var.env}.${data.aws_ssm_parameter.domain.value}"
  ]

  viewer_certificate {
    acm_certificate_arn      = data.aws_ssm_parameter.certificate.value
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}