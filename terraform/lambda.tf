# NOTE: Lambda function is manually managed — see iam.tf for why.
# The archive_file data source is safe to keep active (it just zips
# local code, doesn't touch AWS), but the resources below are commented out.

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/build/lambda_function.zip"
}

# resource "aws_lambda_function" "submit_feedback" {
#   function_name    = "${var.project_name}-submit-feedback"
#   role             = aws_iam_role.lambda_exec.arn
#   handler          = "lambda_function.lambda_handler"
#   runtime          = "python3.13"
#   timeout          = 29
#   memory_size      = 128
#
#   filename         = data.archive_file.lambda_zip.output_path
#   source_code_hash = data.archive_file.lambda_zip.output_base64sha256
#
#   environment {
#     variables = {
#       TABLE_NAME  = aws_dynamodb_table.feedback.name
#       BUCKET_NAME = aws_s3_bucket.pdf_storage.bucket
#       ADMIN_EMAIL = var.admin_email
#       REGION      = var.aws_region
#     }
#   }
# }
#
# resource "aws_lambda_permission" "apigw_invoke" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.submit_feedback.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.feedback_api.execution_arn}/*/*"
# }
