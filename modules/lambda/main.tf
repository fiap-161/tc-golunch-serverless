resource "random_pet" "lambda_bucket_name" {
  prefix = "learn-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

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
      JWT_SECRET_KEY       = var.jwt_secret_key
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
