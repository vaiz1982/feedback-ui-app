output "cloudfront_domain_name" {
  description = "Public URL for the deployed frontend"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
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
  value = aws_lambda_function.submit_feedback.function_name
}
