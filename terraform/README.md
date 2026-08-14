Quick sanity check on your live site — reload https://dvudwljz7c6un.cloudfront.net and submit the feedback form once more, just to confirm nothing broke (it shouldn't have, since nothing was destroyed, but it's a cheap way to be 100% sure).

Once confirmed working — let's wrap this up properly

At this point you'll have:

✅ S3 (both buckets) — Terraform-managed
✅ DynamoDB — Terraform-managed
✅ API Gateway — Terraform-managed
📝 IAM role, Lambda, CloudFront — documented in .tf files but manually managed (due to the account's IAM restriction)

This is genuinely a solid, honest outcome — partial IaC adoption with clear documentation of what's blocked and why is a real pattern you'll see in actual jobs, not a failure state. Want me to update the main project README (the one we wrote earlier) to reflect this Terraform layer and the permission constraint you hit? That'd make the whole story — including the debugging — a strong portfolio piece.










#########################################3

Practical path forward

Stick with what's already working: S3 (both buckets) + DynamoDB + API Gateway REST API are all successfully imported into Terraform state. That's a real, meaningful chunk of your infrastructure now under IaC management.

For the rest — IAM role, Lambda function, CloudFront — document them as manually-managed rather than fighting this further. In your Terraform README, add a note like:

Note: Due to account-level permission restrictions (likely an AWS Organizations SCP) on this training/sandbox AWS account, the IAM role, Lambda function, and CloudFront distribution could not be imported into Terraform state. These resources remain manually managed via the AWS Console. The corresponding .tf files describe the intended configuration and can be imported once elevated permissions are available.

This is a completely legitimate, professional way to handle this — and honestly, correctly diagnosing "this is an SCP I can't see or fix" instead of endlessly guessing is itself a real skill.





Good question — let's lay out a clear, concrete plan so this doesn't drag on indefinitely.

## The situation right now

**Successfully imported (Terraform manages these):**
- ✅ S3 frontend bucket
- ✅ S3 PDF bucket
- ✅ DynamoDB table
- ✅ API Gateway REST API

**Blocked by account restrictions (stay manually managed):**
- ❌ IAM role
- ❌ Lambda function
- ❌ CloudFront distribution + OAC

## The immediate risk to fix first

Your `.tf` files still have full resource blocks for the blocked items. If you run `terraform apply` right now, it'll try to **create duplicates** of your Lambda, IAM role, and CloudFront distribution — and worse, overwrite your S3 bucket policy to point at the new (wrong) CloudFront distribution, breaking your live site. We need to stop that before doing anything else.

## Plan — 3 steps

### Step 1: Remove the blocked resources from being "managed" by Terraform

We'll **comment out** (not delete) the resource blocks for IAM role, Lambda function, Lambda permission, and CloudFront — turning those `.tf` files into pure documentation instead of things Terraform will try to create. This is the safest option given the SCP block.

Let's start with `iam.tf` — comment out everything:I don't have access to your actual local repo files (those live on your machine), so here's exactly what to change — copy-paste these into your local files.

### Edit `iam.tf` — comment out everything, add a note at the top

```hcl
# NOTE: This account has restricted IAM read permissions (likely an AWS
# Organizations SCP) that blocks `terraform import` for IAM roles, even
# with an explicit Allow policy in place. The role below is documented
# for reference but NOT actively managed by Terraform — it was created
# and is maintained manually via the AWS Console.
#
# If you have elevated permissions in a different AWS account, uncomment
# this block and run: terraform import aws_iam_role.lambda_exec <role-name>

# resource "aws_iam_role" "lambda_exec" {
#   name = "${var.project_name}-lambda-role"
#   ...
# }
#
# resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
#   ...
# }
#
# resource "aws_iam_role_policy" "lambda_s3_put" {
#   ...
# }
#
# resource "aws_iam_role_policy" "lambda_dynamodb_put" {
#   ...
# }
#
# resource "aws_iam_role_policy" "lambda_ses_send" {
#   ...
# }
```

**Simplest way to do this in VS Code:** select the entire contents of `iam.tf`, then use `Cmd+/` to comment out the whole block at once, and just add the note above it.

### Edit `lambda.tf` — same approach

```hcl
# NOTE: Lambda function is manually managed — see iam.tf for why.
# The archive_file data source is safe to keep active (it just zips
# local code, doesn't touch AWS), but the resources below are commented out.

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/build/lambda_function.zip"
}

# resource "aws_lambda_function" "submit_feedback" {
#   ...
# }
#
# resource "aws_lambda_permission" "apigw_invoke" {
#   ...
# }
```

### Edit `cloudfront.tf` — comment out both resources

```hcl
# NOTE: CloudFront is manually managed — cloudfront:* actions are blocked
# for TerraformUser on this account.

# resource "aws_cloudfront_origin_access_control" "frontend" {
#   ...
# }
#
# resource "aws_cloudfront_distribution" "frontend" {
#   ...
# }
```

### Edit `s3.tf` — the bucket policy references CloudFront, needs a fix

The `aws_s3_bucket_policy.frontend` resource references `aws_cloudfront_distribution.frontend.arn`, which no longer exists once commented out. Replace that one resource with a hardcoded version using your **real, already-existing distribution ARN**:

```hcl
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
            # Hardcoded since the CloudFront distribution isn't Terraform-managed.
            # Format: arn:aws:cloudfront::<account-id>:distribution/<distribution-id>
            "AWS:SourceArn" = "arn:aws:cloudfront::602555456359:distribution/YOUR_DISTRIBUTION_ID"
          }
        }
      }
    ]
  })
}
```

**You need your real CloudFront distribution ID for this** — since `cloudfront:List*` is blocked via CLI too, check it in the **AWS Console → CloudFront → Distributions** page and copy the ID shown there.

## Step 2: Run `terraform plan` and paste it here

Once those edits are done:
```bash
terraform plan
```

Paste the output — this should now show a much smaller, safer plan covering only S3 (public access blocks, bucket policy) and DynamoDB tags.

## Step 3: Apply once the plan looks clean

Only after we review together that nothing destructive shows up.

---

Make those edits, run `terraform plan`, and paste the result — that's the next concrete step.
