provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "my-demo-server-bucket"
    key    = "image-uploader/terraform.tfstate"
    region = "us-east-1"
  }
}

# Create IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "s3_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach permissions to allow Lambda to read from S3 and write logs
resource "aws_iam_policy_attachment" "lambda_policy" {
  name       = "lambda_s3_policy"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create the Lambda function
resource "aws_lambda_function" "s3_lambda" {
  function_name    = "S3BucketTriggerLambda"
  runtime          = "python3.9"
  handler          = "lambda_handler.lambda_handler"
  role             = aws_iam_role.lambda_role.arn
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# Allow S3 to trigger Lambda
resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.bucket.arn
}

# Define an existing S3 bucket
resource "aws_s3_bucket_notification" "s3_event" {
  bucket = data.aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "products/"  # Triggers only when files are uploaded to 'products/' folder
  }
}

# Reference an existing S3 bucket (update bucket name)
data "aws_s3_bucket" "bucket" {
  bucket = "my-demo-server-bucket"
}
