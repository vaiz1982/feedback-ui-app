# Registers the admin email as an SES identity. AWS still requires a
# manual click-to-verify via the email Amazon sends — Terraform cannot
# complete that step automatically. Until verified (or until SES
# production access is granted), sending is limited to verified
# addresses only (SES sandbox behavior).

resource "aws_ses_email_identity" "admin" {
  count = var.ses_verify_admin_identity ? 1 : 0
  email = var.admin_email
}
