resource "aws_cognito_user_pool" "main" {
  name = var.user_pool_name


  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}"
    email_subject        = "Your verification code"
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
}