const jwt = require("jsonwebtoken");

function generateJWTToken(userID, userType, additionalClaims = {}) {
  const now = Math.floor(Date.now() / 1000);
  const expiryDuration = 24 * 60 * 60; // 24 hours in seconds

  const claims = {
    exp: now + expiryDuration,
    iat: now,
    nbf: now,
    userID: userID,
    userType: userType,
    is_anonymous: true,
    custom: additionalClaims
  };

  const secretKey = process.env.JWT_SECRET_KEY;
  if (!secretKey) {
    throw new Error("JWT_SECRET_KEY environment variable is required");
  }

  return jwt.sign(claims, secretKey, { algorithm: 'HS256' });
}

module.exports.handler = async (event) => {
  console.log("Anonymous Login Event: ", event);

  try {
    // Generate anonymous user ID
    const anonymousUserID = `anonymous_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Generate JWT token for anonymous user
    const jwtToken = generateJWTToken(anonymousUserID, "anonymous", { is_anonymous: true });

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Anonymous login successful",
        token: jwtToken,
        userID: anonymousUserID,
        userType: "anonymous"
      }),
    };
  } catch (error) {
    console.error("Error during anonymous login:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error during anonymous login",
        error: error.message
      }),
    };
  }
};