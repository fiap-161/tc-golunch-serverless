const {
  CognitoIdentityProviderClient,
  AdminCreateUserCommand,
  AdminAddUserToGroupCommand
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
 * Handler principal - Registro de Admin
 * @param {object} event - Evento do API Gateway
 * @returns {object} Response HTTP
 */
module.exports.handler = async (event) => {
  console.log("Admin Registration Event: ", JSON.stringify(event, null, 2));

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

    // Validação de senha (mínimo 8 caracteres)
    if (password.length < 8) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Password must be at least 8 characters long",
        }),
      };
    }

    // Verificar variáveis de ambiente
    const userPoolId = process.env.COGNITO_USER_POOL_ID;
    if (!userPoolId) {
      throw new Error("COGNITO_USER_POOL_ID environment variable is required");
    }

    // Criar usuário admin no Cognito
    const createUserCommand = new AdminCreateUserCommand({
      UserPoolId: userPoolId,
      Username: email,  // Email como username
      UserAttributes: [
        {
          Name: 'email',
          Value: email
        },
        {
          Name: 'email_verified',
          Value: 'true'  // Email já verificado para admins
        }
      ],
      TemporaryPassword: password,  // Senha fornecida pelo usuário
      MessageAction: 'SUPPRESS'      // Não enviar email de boas-vindas
    });

    const createUserResponse = await cognitoClient.send(createUserCommand);
    console.log("User created in Cognito:", createUserResponse.User.Username);

    // Adicionar usuário ao grupo "admins"
    const addToGroupCommand = new AdminAddUserToGroupCommand({
      UserPoolId: userPoolId,
      Username: email,
      GroupName: 'admins'
    });

    await cognitoClient.send(addToGroupCommand);
    console.log("User added to 'admins' group");

    // Gera JWT Token customizado com userType="admin"
    const jwtToken = generateJWTToken(email, "admin", {
      email: email
    });

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Admin registered successfully",
        email: createUserResponse.User.Username,
        userStatus: createUserResponse.User.UserStatus,
        token: jwtToken
      }),
    };

  } catch (error) {
    console.error("Error registering admin:", error);

    // Admin com este email já existe
    if (error.name === 'UsernameExistsException') {
      return {
        statusCode: 409,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Admin with this email already exists"
        }),
      };
    }

    // Grupo "admins" não existe no Cognito
    if (error.name === 'ResourceNotFoundException') {
      return {
        statusCode: 500,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Admin group not found in Cognito. Please contact system administrator.",
          error: error.message
        }),
      };
    }

    // Erro de política de senha do Cognito
    if (error.name === 'InvalidPasswordException') {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "Password does not meet security requirements",
          error: error.message
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
        message: "Error registering admin",
        error: error.message
      }),
    };
  }
};
