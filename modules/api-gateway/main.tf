resource "aws_apigatewayv2_api" "lambda" {
  name          = var.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = var.stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}



resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = var.log_retention_days
}

# Register endpoint
resource "aws_apigatewayv2_integration" "register" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = var.register_lambda_invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "register" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /auth/register"
  target    = "integrations/${aws_apigatewayv2_integration.register.id}"
}

# Login endpoint
resource "aws_apigatewayv2_integration" "login" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = var.login_lambda_invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "login" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.login.id}"
}

# Anonymous endpoint
resource "aws_apigatewayv2_integration" "anonymous" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = var.anonymous_lambda_invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "anonymous" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /auth/anonymous"
  target    = "integrations/${aws_apigatewayv2_integration.anonymous.id}"
}


resource "aws_lambda_permission" "api_gw_register" {
  statement_id  = "AllowExecutionFromAPIGatewayRegister"
  action        = "lambda:InvokeFunction"
  function_name = var.register_lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_login" {
  statement_id  = "AllowExecutionFromAPIGatewayLogin"
  action        = "lambda:InvokeFunction"
  function_name = var.login_lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_anonymous" {
  statement_id  = "AllowExecutionFromAPIGatewayAnonymous"
  action        = "lambda:InvokeFunction"
  function_name = var.anonymous_lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

# Get VPC and subnet information for VPC Link V2
data "aws_lb" "nlb" {
  arn = var.nlb_arn
}

# VPC Link V2 for connecting to EKS via NLB (required for HTTP API)
resource "aws_apigatewayv2_vpc_link" "golang_api_vpc_link" {
  name               = "golang-api-vpc-link"
  security_group_ids = [var.vpc_link_security_group_id]
  subnet_ids         = var.private_subnet_ids

  tags = {
    Name = "golang-api-vpc-link"
  }
}

# Integration for Golang API routes via VPC Link V2
resource "aws_apigatewayv2_integration" "golang_api" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = var.nlb_listener_arn # Must use ELB listener ARN for VPC Link
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.golang_api_vpc_link.id

  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

# Catch-all route for ALL Golang API endpoints
# This forwards any route NOT handled by Lambda functions to the Golang API
resource "aws_apigatewayv2_route" "golang_api_catch_all" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.golang_api.id}"
}