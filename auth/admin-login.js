const {
  CognitoIdentityProviderClient,
  AdminInitiateAuthCommand,
  AdminGetUserCommand,
  AdminListGroupsForUserCommand
} = require("@aws-sdk/client-cognito-identity-provider");
const jwt = require("jsonwebtoken");

const cognitoClient = new CognitoIdentityProviderClient({
  region: process.env.AWS_REGION || "us-east-1"
});

/**
 * Gera JWT Token customizado
 * @param {string} userID - Email do admin
 * @param {string} userType - Tipo de usuário (admin)
 * @param {object} additionalClaims - Claims adicionais
 * @returns {string} JWT Token
 */
function generateJWTToken(userID, userType, additionalClaims = {}) {
  const now = Math.floor(Date.now() / 1000);
  const expiryDuration = 24 * 60 * 60; // 24 horas em segundos

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

/**
 * Valida formato de email
 * @param {string} email
 * @returns {boolean}
 */
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Verifica se o usuário está no grupo "admins"
 * @param {string} userPoolId
 * @param {string} username
 * @returns {Promise<boolean>}
 */
async function isUserInAdminGroup(userPoolId, username) {
  try {
    const command = new AdminListGroupsForUserCommand({
      UserPoolId: userPoolId,
      Username: username
    });

    const response = await cognitoClient.send(command);
    const groups = response.Groups || [];

    // Verifica se "admins" está na lista de grupos
    return groups.some(group => group.GroupName === 'admins');
  } catch (error) {
    console.error("Error checking user groups:", error);
    return false;
  }
}

/**
 * Handler principal - Login de Admin
 * @param {object} event - Evento do API Gateway
 * @returns {object} Response HTTP
 */
module.exports.handler = async (event) => {
  console.log("Admin Login Event: ", JSON.stringify(event, null, 2));

  try {
    // Parse do body
    const body = JSON.parse(event.body || '{}');
    const { email, password } = body;

    // Validação de campos obrigatórios
    if (!email || !password) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Email and password are required",
        }),
      };
    }

    // Validação de formato de email
    if (!isValidEmail(email)) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Invalid email format",
        }),
      };
    }

    // Verificar variáveis de ambiente
    const userPoolId = process.env.COGNITO_USER_POOL_ID;
    const clientId = process.env.COGNITO_CLIENT_ID;

    if (!userPoolId || !clientId) {
      throw new Error("COGNITO_USER_POOL_ID and COGNITO_CLIENT_ID environment variables are required");
    }

    // Autenticar via Cognito
    const authCommand = new AdminInitiateAuthCommand({
      UserPoolId: userPoolId,
      ClientId: clientId,
      AuthFlow: 'ADMIN_NO_SRP_AUTH',
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password
      }
    });

    const authResponse = await cognitoClient.send(authCommand);
    console.log("User authenticated successfully:", email);

    // Verificar se o usuário está no grupo "admins"
    const isAdmin = await isUserInAdminGroup(userPoolId, email);

    if (!isAdmin) {
      console.warn("User is not in admins group:", email);
      return {
        statusCode: 403,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Access denied. User is not an admin."
        }),
      };
    }

    console.log("User verified as admin:", email);

    // Gera JWT Token customizado com userType="admin"
    const customJWT = generateJWTToken(email, "admin", {
      email: email
    });

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Admin login successful",
        token: customJWT,
        accessToken: authResponse.AuthenticationResult?.AccessToken,
        idToken: authResponse.AuthenticationResult?.IdToken,
        refreshToken: authResponse.AuthenticationResult?.RefreshToken,
        expiresIn: authResponse.AuthenticationResult?.ExpiresIn
      }),
    };

  } catch (error) {
    console.error("Error during admin login:", error);

    // Usuário não encontrado ou senha incorreta
    if (error.name === 'UserNotFoundException' || error.name === 'NotAuthorizedException') {
      return {
        statusCode: 401,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Invalid email or password"
        }),
      };
    }

    // Senha temporária precisa ser alterada
    if (error.name === 'PasswordResetRequiredException') {
      return {
        statusCode: 403,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Password reset required. Please contact administrator."
        }),
      };
    }

    // Usuário não confirmado
    if (error.name === 'UserNotConfirmedException') {
      return {
        statusCode: 403,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "User account not confirmed"
        }),
      };
    }

    // Erro genérico
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error during admin login",
        error: error.message
      }),
    };
  }
};
