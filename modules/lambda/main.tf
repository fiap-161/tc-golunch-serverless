resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "golunch-lambda-functions-serverless"
}

# Bucket ownership and ACL simplified - using defaults

resource "aws_s3_object" "lambda_function" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "${var.source_file}.zip"
  source = data.archive_file.lambda_function.output_path

  etag = filemd5(data.archive_file.lambda_function.output_path)
}

resource "aws_lambda_function" "lambda_function" {
  function_name = var.function_name

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_function.key

  runtime = var.runtime
  handler = var.handler

  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  role = data.aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_CLIENT_ID    = var.cognito_client_id
      SECRET_KEY           = var.secret_key
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_function" {
  name = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"

  retention_in_days = var.log_retention_days
}

data "aws_iam_role" "lambda_exec" {
  name = var.lambda_role_name
}

data "aws_region" "current" {}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${var.source_file}.zip"
}
