
output "base_url" {
  description = "Base URL for API Gateway stage"
  value       = module.api_gateway.base_url
}

output "api_id" {
  description = "ID of the API Gateway"
  value       = module.api_gateway.api_id
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = module.cognito.user_pool_client_id
}
