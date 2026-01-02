terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      module "lambda_anonymous" {
  source = "./modules/lambda"

  function_name         = "AnonymousUser"
  runtime               = var.runtime
  handler               = "anonymous.handler"
  log_retention_days    = var.log_retention_days
  lambda_role_name      = var.lambda_role_name
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.user_pool_client_id
  secret_key            = var.secret_key
  source_dir            = "auth"
  source_file           = "anonymous"
}

# NEW: Service-to-Service Authentication Lambda
module "lambda_service_auth" {
  source = "./modules/lambda"

  function_name         = "ServiceAuth"
  runtime               = var.runtime
  handler               = "service-auth.handler"
  log_retention_days    = var.log_retention_days
  lambda_role_name      = var.lambda_role_name
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.user_pool_client_id
  secret_key            = var.secret_key
  source_dir            = "auth"
  source_file           = "service-auth"
  
  # Service-specific environment variables
  extra_environment_variables = {
    # Service API Keys for validation
    CORE_SERVICE_API_KEY       = "core-service-secure-api-key-2024"
    PAYMENT_SERVICE_API_KEY    = "payment-service-secure-api-key-2024"  
    OPERATION_SERVICE_API_KEY = "operation-service-secure-api-key-2024"
    SERVICE_SECRET_KEY         = "microservices-shared-secret-key-2024"
    
    # Microservice URLs for communication from Lambda
    CORE_SERVICE_URL      = var.core_service_url
    PAYMENT_SERVICE_URL   = var.payment_service_url
    OPERATION_SERVICE_URL = var.operation_service_url
    
    # Environment indicator
    ENVIRONMENT = var.environment
  }
}.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.2"
    }
  }
  backend "s3" {
    bucket = "api-gateway-bucket-serverless"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
  required_version = "~> 1.2"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      tc-golunch-serverless = "lambda-api-gateway"
    }
  }
}

# Data source to get infrastructure outputs from terraform-infra
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "s3-golunch-infra-terraform-fiap"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

module "cognito" {
  source = "./modules/cognito"

  user_pool_name = var.cognito_user_pool_name
  environment    = var.environment
  callback_urls  = var.cognito_callback_urls
  logout_urls    = var.cognito_logout_urls
}


module "lambda_register" {
  source = "./modules/lambda"

  function_name         = "RegisterUser"
  runtime               = var.runtime
  handler               = "register.handler"
  log_retention_days    = var.log_retention_days
  lambda_role_name      = var.lambda_role_name
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.user_pool_client_id
  secret_key            = var.secret_key
  source_dir            = "auth"
  source_file           = "register"
}

module "lambda_login" {
  source = "./modules/lambda"

  function_name         = "LoginUser"
  runtime               = var.runtime
  handler               = "login.handler"
  log_retention_days    = var.log_retention_days
  lambda_role_name      = var.lambda_role_name
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.user_pool_client_id
  secret_key            = var.secret_key
  source_dir            = "auth"
  source_file           = "login"
}

module "lambda_anonymous" {
  source = "./modules/lambda"

  function_name         = "AnonymousLogin"
  runtime               = var.runtime
  handler               = "anonymous.handler"
  log_retention_days    = var.log_retention_days
  lambda_role_name      = var.lambda_role_name
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.user_pool_client_id
  secret_key            = var.secret_key
  source_dir            = "auth"
  source_file           = "anonymous"
}

module "lambda_admin_register" {
  source = "./modules/lambda"

  function_name         = "AdminRegister"
  runtime               = var.runtime
  handler               = "admin-register.handler"
  log_retention_days    = var.log_retention_days
  lambda_role_name      = var.lambda_role_name
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.user_pool_client_id
  secret_key            = var.secret_key
  source_dir            = "auth"
  source_file           = "admin-register"
}

module "lambda_admin_login" {
  source = "./modules/lambda"

  function_name         = "AdminLogin"
  runtime               = var.runtime
  handler               = "admin-login.handler"
  log_retention_days    = var.log_retention_days
  lambda_role_name      = var.lambda_role_name
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.user_pool_client_id
  secret_key            = var.secret_key
  source_dir            = "auth"
  source_file           = "admin-login"
}

module "api_gateway" {
  source = "./modules/api-gateway"

  api_name           = var.api_name
  stage_name         = var.stage_name
  log_retention_days = var.log_retention_days

  # Auth endpoints (Customer)
  register_lambda_invoke_arn     = module.lambda_register.lambda_invoke_arn
  register_lambda_function_name  = module.lambda_register.lambda_function_name
  login_lambda_invoke_arn        = module.lambda_login.lambda_invoke_arn
  login_lambda_function_name     = module.lambda_login.lambda_function_name
  anonymous_lambda_invoke_arn    = module.lambda_anonymous.lambda_invoke_arn
  anonymous_lambda_function_name = module.lambda_anonymous.lambda_function_name

  # Admin endpoints
  admin_register_lambda_invoke_arn    = module.lambda_admin_register.lambda_invoke_arn
  admin_register_lambda_function_name = module.lambda_admin_register.lambda_function_name
  admin_login_lambda_invoke_arn       = module.lambda_admin_login.lambda_invoke_arn
  admin_login_lambda_function_name    = module.lambda_admin_login.lambda_function_name

  # Service Authentication endpoint
  service_auth_lambda_invoke_arn    = module.lambda_service_auth.lambda_invoke_arn
  service_auth_lambda_function_name = module.lambda_service_auth.lambda_function_name

  # NLB for VPC Link to EKS - using data from terraform-infra
  nlb_arn                    = data.terraform_remote_state.infra.outputs.nlb_arn
  nlb_listener_arn           = data.terraform_remote_state.infra.outputs.nlb_listener_arn
  vpc_id                     = data.terraform_remote_state.infra.outputs.vpc_id
  private_subnet_ids         = data.terraform_remote_state.infra.outputs.private_subnet_ids
  vpc_link_security_group_id = data.terraform_remote_state.infra.outputs.vpc_link_security_group_id
}
