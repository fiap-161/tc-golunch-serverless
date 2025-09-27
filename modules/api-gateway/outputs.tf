output "base_url" {
  description = "Base URL for API Gateway stage"
  value       = aws_apigatewayv2_stage.lambda.invoke_url
}

output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_apigatewayv2_api.lambda.id
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_apigatewayv2_stage.lambda.name
}