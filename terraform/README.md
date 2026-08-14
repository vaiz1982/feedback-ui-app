Practical path forward

Stick with what's already working: S3 (both buckets) + DynamoDB + API Gateway REST API are all successfully imported into Terraform state. That's a real, meaningful chunk of your infrastructure now under IaC management.

For the rest — IAM role, Lambda function, CloudFront — document them as manually-managed rather than fighting this further. In your Terraform README, add a note like:

Note: Due to account-level permission restrictions (likely an AWS Organizations SCP) on this training/sandbox AWS account, the IAM role, Lambda function, and CloudFront distribution could not be imported into Terraform state. These resources remain manually managed via the AWS Console. The corresponding .tf files describe the intended configuration and can be imported once elevated permissions are available.

This is a completely legitimate, professional way to handle this — and honestly, correctly diagnosing "this is an SCP I can't see or fix" instead of endlessly guessing is itself a real skill.
