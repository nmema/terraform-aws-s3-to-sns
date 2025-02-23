resource "aws_ses_email_identity" "noreply" {
  email = var.email
}
