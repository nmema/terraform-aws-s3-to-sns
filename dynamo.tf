resource "aws_dynamodb_table" "email_recipients" {
  name         = "S3UploadEmailRecipients"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Owner"

  attribute {
    name = "Owner"
    type = "S"
  }
}
