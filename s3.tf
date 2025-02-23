resource "aws_s3_bucket" "repo" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.repo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.repo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "require_tags" {
  bucket = aws_s3_bucket.repo.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Deny",
        Principal = "*",
        Action    = "S3:PutObject",
        Resource  = "${aws_s3_bucket.repo.arn}/*"
        Condition = {
          "StringNotEqualsIfExists" = {
            "s3:RequestObjectTag/Owner" : ["HR", "Finance", "IT"]
          }
        }
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.repo.arn
}

resource "aws_s3_bucket_notification" "s3_event_notification" {
  bucket = aws_s3_bucket.repo.id

  lambda_function {
    id                  = "CreationTrigger"
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
