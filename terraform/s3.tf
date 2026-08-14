########################################
# Frontend bucket (private, served via CloudFront OAC)
########################################

resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket_name
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy granting CloudFront (via OAC) read access — scoped to this
# specific distribution only, matching the "Allow private S3 bucket access
# to CloudFront" checkbox behavior from the console.
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}

########################################
# PDF attachment storage bucket (private, written to only by Lambda)
########################################

resource "aws_s3_bucket" "pdf_storage" {
  bucket = var.pdf_bucket_name
}

resource "aws_s3_bucket_public_access_block" "pdf_storage" {
  bucket                  = aws_s3_bucket.pdf_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
