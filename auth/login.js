const { CognitoIdentityProviderClient, AdminInitiateAuthCommand } = require("@aws-sdk/client-cognito-identity-provider");
const jwt = require("jsonwebtoken");

const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.AWS_REGION || "us-east-1" });

function generateJWTToken(userID, userType, additionalClaims = {}) {
  const now = Math.floor(Date.now() / 1000);
  const expiryDuration = 24 * 60 * 60; // 24 hours in seconds

  const claims = {
    exp: now + expiryDuration,
    iat: now,
    nbf: now,
    userID: userID,
    userType: userType,
    is_anonymous: false,
    custom: additionalClaims
  };

  const secretKey = process.env.SECRET_KEY;
  if (!secretKey) {
    throw new Error("SECRET_KEY environment variable is required");
  }

  return jwt.sign(claims, secretKey, { algorithm: 'HS256' });
}

module.exports.handler = async (event) => {
  console.log("Login Event: ", event);
  
  try {
    const body = JSON.parse(event.body || '{}');
    const { cpf } = body;

    if (!cpf) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "CPF is required",
        }),
      };
    }

    const userPoolId = process.env.COGNITO_USER_POOL_ID;
    const clientId = process.env.COGNITO_CLIENT_ID;
    
    if (!userPoolId || !clientId) {
      throw new Error("COGNITO_USER_POOL_ID and COGNITO_CLIENT_ID environment variables are required");
    }

    const command = new AdminInitiateAuthCommand({
      UserPoolId: userPoolId,
      ClientId: clientId,
      AuthFlow: 'ADMIN_NO_SRP_AUTH',
      AuthParameters: {
        USERNAME: cpf,
        PASSWORD: `${cpf}Temp!`
      }
    });

    const response = await cognitoClient.send(command);

    // Generate custom JWT token with is_anonymous: false
    const customJWT = generateJWTToken(cpf, "regular", { cpf });

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Login successful",
        token: customJWT,
        accessToken: response.AuthenticationResult?.AccessToken,
        idToken: response.AuthenticationResult?.IdToken,
        refreshToken: response.AuthenticationResult?.RefreshToken,
        expiresIn: response.AuthenticationResult?.ExpiresIn
      }),
    };
  } catch (error) {
    console.error("Error during login:", error);
    
    if (error.name === 'UserNotFoundException' || error.name === 'NotAuthorizedException') {
      return {
        statusCode: 401,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Invalid CPF or user not found"
        }),
      };
    }

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error during login",
        error: error.message
      }),
    };
  }
};