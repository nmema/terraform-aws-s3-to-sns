resource "aws_s3_bucket" "repo" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.repo.id

  versioning_configuration {
    status = "Enabled"
  }
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
            "s3:RequestObjectTag/Environment" : "dev"
            "s3:RequestObjectTag/Owner" : ["HR", "Finance", "IT"]
          }
        }
      }
    ]
  })
}
