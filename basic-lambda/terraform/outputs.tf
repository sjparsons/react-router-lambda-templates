output "assets_bucket_name" {
  value = aws_s3_bucket.assets.bucket
}

output "cloudfront_distribution_link" {
  value = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "lambda_function_name" {
  value = aws_lambda_function.app.function_name
}
