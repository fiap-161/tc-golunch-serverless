variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "lambda-api-user-pool"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the User Pool Client"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "logout_urls" {
  description = "List of allowed logout URLs for the User Pool Client"
  type        = list(string)
  default     = ["http://localhost:3000"]
}