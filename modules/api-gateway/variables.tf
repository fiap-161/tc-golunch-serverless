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


variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}



variable "register_lambda_invoke_arn" {
  description = "ARN to invoke the Register Lambda function"
  type        = string
}

variable "register_lambda_function_name" {
  description = "Name of the Register Lambda function"
  type        = string
}

variable "login_lambda_invoke_arn" {
  description = "ARN to invoke the Login Lambda function"
  type        = string
}

variable "login_lambda_function_name" {
  description = "Name of the Login Lambda function"
  type        = string
}

variable "anonymous_lambda_invoke_arn" {
  description = "ARN to invoke the Anonymous Login Lambda function"
  type        = string
}

variable "anonymous_lambda_function_name" {
  description = "Name of the Anonymous Login Lambda function"
  type        = string
}

variable "nlb_arn" {
  description = "ARN of the Network Load Balancer for VPC Link"
  type        = string
}

variable "nlb_listener_arn" {
  description = "ARN of the NLB listener for API Gateway integration"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for VPC Link"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for VPC Link"
  type        = list(string)
}

variable "vpc_link_security_group_id" {
  description = "Security Group ID for VPC Link"
  type        = string
}