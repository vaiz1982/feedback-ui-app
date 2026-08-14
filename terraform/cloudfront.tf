# NOTE: CloudFront is manually managed — cloudfront:* actions are blocked
# for TerraformUser on this account (same restriction as IAM, likely an
# AWS Organizations SCP). The distribution and OAC below are documented
# for reference but NOT actively managed by Terraform.
#
# If you have elevated permissions in a different AWS account, uncomment
# this block and run:
#   terraform import aws_cloudfront_origin_access_control.frontend <oac-id>
#   terraform import aws_cloudfront_distribution.frontend <distribution-id>

# resource "aws_cloudfront_origin_access_control" "frontend" {
#   name                              = "${var.project_name}-oac"
#   description                      = "OAC for private frontend S3 bucket"
#   origin_access_control_origin_type = "s3"
#   signing_behavior                  = "always"
#   signing_protocol                  = "sigv4"
# }

# resource "aws_cloudfront_distribution" "frontend" {
#   enabled             = true
#   default_root_object = "index.html"
#   comment              = "${var.project_name} frontend distribution"
#
#   origin {
#     domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
#     origin_id                = "frontend-s3-origin"
#     origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
#   }
#
#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD"]
#     cached_methods          = ["GET", "HEAD"]
#     target_origin_id        = "frontend-s3-origin"
#     viewer_protocol_policy  = "redirect-to-https"
#     compress                = true
#
#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#     }
#   }
#
#   # SPA-style fallback: unknown paths still resolve to index.html
#   custom_error_response {
#     error_code         = 403
#     response_code       = 200
#     response_page_path  = "/index.html"
#   }
#   custom_error_response {
#     error_code         = 404
#     response_code       = 200
#     response_page_path  = "/index.html"
#   }
#
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }
#
#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }
# }
