variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}


variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}


variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "lambda_role_name" {
  description = "IAM role name for Lambda execution"
  type        = string
  default     = "LabRole"
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "serverless_lambda_gw"
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "serverless_lambda_stage"
}


variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "lambda-api-user-pool"
}

variable "cognito_callback_urls" {
  description = "List of allowed callback URLs for the User Pool Client"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "cognito_logout_urls" {
  description = "List of allowed logout URLs for the User Pool Client"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "secret_key" {
  description = "Secret key for signing tokens"
  type        = string
  sensitive   = true
}

# NLB variables removed - now using data source from terraform-infra

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "golunch"
}

variable "domain_name" {
  description = "Domain name for the API"
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
  default     = ""
}
