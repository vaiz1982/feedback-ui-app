# NOTE: cloudfront_domain_name and lambda_function_name are hardcoded
# plain strings (not resource references) since CloudFront and Lambda
# are manually managed on this account, not Terraform-tracked.

output "cloudfront_domain_name" {
  description = "Public URL for the deployed frontend (manually managed)"
  value       = "https://dvudwljz7c6un.cloudfront.net"
}

output "api_invoke_url" {
  description = "Base invoke URL for the API Gateway prod stage"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "submit_endpoint" {
  description = "Full endpoint the frontend should POST feedback to"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/submit"
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "pdf_bucket_name" {
  value = aws_s3_bucket.pdf_storage.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.feedback.name
}

output "lambda_function_name" {
  description = "Manually managed — not tracked by Terraform"
  value       = "SubmitFeetbackFunction"
}
