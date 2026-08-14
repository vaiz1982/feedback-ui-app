variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for resource naming"
  type        = string
  default     = "feedback-app"
}

variable "frontend_bucket_name" {
  description = "Globally-unique S3 bucket name for the static frontend"
  type        = string
}

variable "pdf_bucket_name" {
  description = "Globally-unique S3 bucket name for uploaded PDF attachments"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for storing feedback records"
  type        = string
  default     = "FeedbackDBTable"
}

variable "admin_email" {
  description = "Email address that receives feedback notifications (must be SES-verified while in sandbox)"
  type        = string
}

variable "ses_verify_admin_identity" {
  description = "Whether Terraform should register the admin email as an SES identity (still requires manual click-to-verify)"
  type        = bool
  default     = true
}
