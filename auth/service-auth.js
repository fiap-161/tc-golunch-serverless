// Lambda Function for Service-to-Service Authentication
// This validates API keys between microservices

exports.handler = async (event) => {
    console.log('Service Auth Request:', JSON.stringify(event, null, 2));
    
    try {
        // Parse request body
        const body = JSON.parse(event.body || '{}');
        const { serviceName, apiKey } = body;
        
        // Get headers for alternative authentication method
        const headers = event.headers || {};
        const headerServiceName = headers['X-Service-Name'] || headers['x-service-name'];
        const headerApiKey = headers['X-Service-Key'] || headers['x-service-key'];
        
        // Use headers if body is empty
        const finalServiceName = serviceName || headerServiceName;
        const finalApiKey = apiKey || headerApiKey;
        
        console.log(`Validating service: ${finalServiceName}`);
        
        // Validate required fields
        if (!finalServiceName || !finalApiKey) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'Missing serviceName or apiKey',
                    message: 'Both serviceName and apiKey are required'
                })
            };
        }
        
        // Get expected API key from environment variables
        let expectedApiKey;
        
        switch (finalServiceName) {
            case 'core-service':
                expectedApiKey = process.env.CORE_SERVICE_API_KEY;
                break;
            case 'payment-service':
                expectedApiKey = process.env.PAYMENT_SERVICE_API_KEY;
                break;
            case 'operation-service':
                expectedApiKey = process.env.OPERATION_SERVICE_API_KEY;
                break;
            default:
                console.log(`Unknown service: ${finalServiceName}`);
                return {
                    statusCode: 401,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    body: JSON.stringify({
                        error: 'Unauthorized',
                        message: 'Invalid service name'
                    })
                };
        }
        
        // Validate API key using constant-time comparison
        if (!constantTimeEquals(finalApiKey, expectedApiKey)) {
            console.log(`Invalid API key for service: ${finalServiceName}`);
            return {
                statusCode: 401,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'Unauthorized',
                    message: 'Invalid service credentials'
                })
            };
        }
        
        // Authentication successful
        console.log(`Service authenticated successfully: ${finalServiceName}`);
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: true,
                serviceName: finalServiceName,
                message: 'Service authenticated successfully',
                timestamp: new Date().toISOString()
            })
        };
        
    } catch (error) {
        console.error('Service Auth Error:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'Internal Server Error',
                message: 'Service authentication failed'
            })
        };
    }
};

// Constant-time string comparison to prevent timing attacks
function constantTimeEquals(a, b) {
    if (a.length !== b.length) {
        return false;
    }
    
    let result = 0;
    for (let i = 0; i < a.length; i++) {
        result |= a.charCodeAt(i) ^ b.charCodeAt(i);
    }
    
    return result === 0;
}

// Export for testing
module.exports = {
    handler: exports.handler,
    constantTimeEquals
};