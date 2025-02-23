data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "TriggerEventLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "LambdaReadS3Policy"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:GetObjectTagging"],
        Resource = "${aws_s3_bucket.repo.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name = "LambdaDynamoDBAccess"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ],
        Resource = aws_dynamodb_table.email_recipients.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "ses_send_email" {
  name = "LambdaSESPolicy"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ses:SendEmail",
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "TriggerNotificationFunction"
  filename      = data.archive_file.lambda.output_path
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda.arn

  environment {
    variables = {
      DDB_TABLE_NAME   = aws_dynamodb_table.email_recipients.name
      SES_SENDER_EMAIL = var.email
    }
  }

  source_code_hash = fileexists("${path.module}/lambda.zip") ? filebase64sha256("${path.module}/lambda.zip") : ""

  depends_on = [data.archive_file.lambda]
}
