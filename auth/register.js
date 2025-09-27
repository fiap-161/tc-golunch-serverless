const { CognitoIdentityProviderClient, AdminCreateUserCommand } = require("@aws-sdk/client-cognito-identity-provider");
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
    custom: additionalClaims
  };

  const secretKey = process.env.JWT_SECRET_KEY;
  if (!secretKey) {
    throw new Error("JWT_SECRET_KEY environment variable is required");
  }

  return jwt.sign(claims, secretKey, { algorithm: 'HS256' });
}

module.exports.handler = async (event) => {
  console.log("Registration Event: ", event);
  
  try {
    const body = JSON.parse(event.body || '{}');
    const { cpf, name } = body;

    if (!cpf || !name) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "CPF and name are required",
        }),
      };
    }

    const userPoolId = process.env.COGNITO_USER_POOL_ID;
    if (!userPoolId) {
      throw new Error("COGNITO_USER_POOL_ID environment variable is required");
    }

    const command = new AdminCreateUserCommand({
      UserPoolId: userPoolId,
      Username: cpf,
      UserAttributes: [
        {
          Name: 'name',
          Value: name
        },
        {
          Name: 'email',
          Value: `${cpf}@temp.local`
        }
      ],
      TemporaryPassword: `${cpf}Temp!`,
      MessageAction: 'SUPPRESS'
    });

    const response = await cognitoClient.send(command);

    // Generate JWT token (assuming regular user role for new registrations)
    const jwtToken = generateJWTToken(cpf, "regular", { name });

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "User registered successfully",
        username: response.User.Username,
        userStatus: response.User.UserStatus,
        token: jwtToken
      }),
    };
  } catch (error) {
    console.error("Error registering user:", error);
    
    if (error.name === 'UsernameExistsException') {
      return {
        statusCode: 409,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "User with this CPF already exists"
        }),
      };
    }

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error registering user",
        error: error.message
      }),
    };
  }
};