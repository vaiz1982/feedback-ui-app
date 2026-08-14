# NOTE: This account has restricted IAM read permissions (likely an AWS
# Organizations SCP) that blocks `terraform import` for IAM roles, even
# with an explicit Allow policy in place. The role below is documented
# for reference but NOT actively managed by Terraform — it was created
# and is maintained manually via the AWS Console.
#
# If you have elevated permissions in a different AWS account, uncomment
# this block and run: terraform import aws_iam_role.lambda_exec <role-name>

########################################
# Lambda execution role
########################################

# resource "aws_iam_role" "lambda_exec" {
#   name = "${var.project_name}-lambda-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = { Service = "lambda.amazonaws.com" }
#         Action    = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# Baseline CloudWatch Logs permissions (equivalent to the AWS-managed
# AWSLambdaBasicExecutionRole)
# resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
#   role       = aws_iam_role.lambda_exec.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# s3:PutObject on the PDF bucket only — this is the exact permission that
# was missing and caused the first AccessDenied error during manual setup.
# resource "aws_iam_role_policy" "lambda_s3_put" {
#   name = "${var.project_name}-lambda-s3-put"
#   role = aws_iam_role.lambda_exec.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = ["s3:PutObject"]
#         Resource = "${aws_s3_bucket.pdf_storage.arn}/*"
#       }
#     ]
#   })
# }

# dynamodb:PutItem on the feedback table only — the second AccessDenied
# error hit during manual setup, after the S3 permission was fixed.
# resource "aws_iam_role_policy" "lambda_dynamodb_put" {
#   name = "${var.project_name}-lambda-dynamodb-put"
#   role = aws_iam_role.lambda_exec.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = ["dynamodb:PutItem"]
#         Resource = aws_dynamodb_table.feedback.arn
#       }
#     ]
#   })
# }

# ses:SendEmail — scoped to * since SES identity ARNs aren't known until
# verification; can be tightened to a specific identity ARN once the
# admin email/domain is verified.
# resource "aws_iam_role_policy" "lambda_ses_send" {
#   name = "${var.project_name}-lambda-ses-send"
#   role = aws_iam_role.lambda_exec.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = ["ses:SendEmail", "ses:SendRawEmail"]
#         Resource = "*"
#       }
#     ]
#   })
# }
