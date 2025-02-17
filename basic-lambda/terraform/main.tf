locals {
  # We use the folder name to make the lambda and s3 bucket names unique.
  folder_name_raw = basename(dirname(abspath(path.module)))
  # We have to santize the name to make sure it is valid. 
  folder_name_sanitized = substr(replace(local.folder_name_raw, "/[^A-Za-z0-9_-]/", ""), 0, 50)

  lambda_name     = "react-router-app-${local.folder_name_sanitized}"
  lambda_source   = "../build/"
  lambda_zip_file = "build/lambda-app.zip"

  bucket_name   = "react-router-app-assets-${local.folder_name_sanitized}"
  assets_source = "../build/client"

  content_type_map = {
    "js"   = "application/javascript"
    "html" = "text/html"
    "css"  = "text/css"
    "ico"  = "image/x-icon"
    "svg"  = "image/svg+xml"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.85"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}

## IAM Roles

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_assume_role" {
  name               = "lambda_assume_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Lambda 

data "archive_file" "app" {
  type             = "zip"
  source_dir       = local.lambda_source
  output_file_mode = "0666"
  output_path      = local.lambda_zip_file
}

resource "aws_lambda_function" "app" {
  filename      = local.lambda_zip_file
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_assume_role.arn
  handler       = "server/index.handler"

  depends_on = [aws_cloudwatch_log_group.app_lambda_log_group]

  source_code_hash = data.archive_file.app.output_base64sha256

  runtime = "nodejs22.x"

  environment {
    variables = {
      NODE_ENV = "production"
    }
  }
}

resource "aws_lambda_function_url" "app_latest" {
  function_name      = aws_lambda_function.app.function_name
  authorization_type = "NONE"
}

resource "aws_cloudwatch_log_group" "app_lambda_log_group" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

// S3 Bucket for static resources

resource "aws_s3_bucket" "assets" {
  bucket = local.bucket_name
}

resource "aws_s3_object" "assets" {
  for_each = fileset(local.assets_source, "**")

  bucket       = aws_s3_bucket.assets.bucket
  key          = each.value
  source       = "${local.assets_source}/${each.value}"
  source_hash  = filemd5("${local.assets_source}/${each.value}")
  content_type = lookup(local.content_type_map, reverse(split(".", "${each.value}"))[0], "text/html")
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront.json
}

data "aws_iam_policy_document" "allow_access_from_cloudfront" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.assets.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_cloudfront_origin_access_control" "basic" {
  name                              = "Basic Origin Access control"
  description                       = "Access s3 files"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# resource "aws_cloudfront_origin_access_identity" "example" {
#   comment = "Some comment"
# }

data "aws_cloudfront_cache_policy" "managed_cache_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "managed_cache_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "managed_all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

# Create a Cloudfront distribution with 2 origins: lambda fuctions URL and s3 bucket
# containing client site assets.
resource "aws_cloudfront_distribution" "main" {

  origin {
    # remove the https:// and the trailing slash
    domain_name = replace(replace(aws_lambda_function_url.app_latest.function_url, "https://", ""), "/", "")
    origin_id   = "Lambda-${aws_lambda_function.app.function_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.assets.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.basic.id
  }

  enabled         = true
  is_ipv6_enabled = true


  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "Lambda-${aws_lambda_function.app.function_name}"
    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_cache_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_all_viewer_except_host_header.id
    viewer_protocol_policy   = "allow-all"
    compress                 = true
  }

  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.assets.id}"
    viewer_protocol_policy = "allow-all"
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_cache_optimized.id
  }

  ordered_cache_behavior {
    path_pattern           = "/favicon.ico"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.assets.id}"
    viewer_protocol_policy = "allow-all"
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_cache_optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
