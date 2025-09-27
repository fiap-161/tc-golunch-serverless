# Example terraform.tfvars for serverless deployment
# Copy to terraform.tfvars and fill in your values

# Basic Configuration
aws_region         = "us-east-1"
runtime            = "nodejs20.x"
log_retention_days = 30
lambda_role_name   = "LabRole"

# API Gateway Configuration
api_name   = "unified-api-gateway"
stage_name = "prod"

# Environment
environment = "prod"

# Cognito Configuration
cognito_user_pool_name = "unified-api-user-pool"
cognito_callback_urls  = ["https://your-frontend-domain.com/callback"]
cognito_logout_urls    = ["https://your-frontend-domain.com/logout"]

# JWT secret key is provided via GitHub Actions workflow
# using the JWT_SECRET_KEY GitHub secret - do not set this here
# jwt_secret_key = "will-be-passed-from-github-secret"

# NLB ARN from terraform-infra output
# This will be automatically passed from the terraform-infra job output
# You don't need to set this manually - it's handled by the GitHub Actions workflow
nlb_arn = "will-be-passed-from-terraform-infra-output"