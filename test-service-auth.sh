#!/bin/bash

# Test Service Authentication Lambda
# Usage: ./test-service-auth.sh [api-gateway-url]

set -e

API_URL=${1:-"https://your-api-gateway-url.amazonaws.com/validate-service"}

echo "🧪 Testing Service Authentication Lambda..."
echo "🔗 API URL: $API_URL"
echo ""

# Test 1: Valid authentication
echo "✅ Test 1: Valid Core Service Authentication"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "X-Service-Name: core-service" \
  -H "X-Service-Key: core-service-secure-api-key-2024" \
  -d '{}' \
  -w "\nStatus Code: %{http_code}\n" \
  -s | jq .

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 2: Invalid API key
echo "❌ Test 2: Invalid API Key"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "X-Service-Name: core-service" \
  -H "X-Service-Key: invalid-key" \
  -d '{}' \
  -w "\nStatus Code: %{http_code}\n" \
  -s | jq .

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 3: Missing headers
echo "❌ Test 3: Missing Headers"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{}' \
  -w "\nStatus Code: %{http_code}\n" \
  -s | jq .

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 4: Body authentication (alternative method)
echo "✅ Test 4: Body Authentication - Payment Service"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceName": "payment-service",
    "apiKey": "payment-service-secure-api-key-2024"
  }' \
  -w "\nStatus Code: %{http_code}\n" \
  -s | jq .

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 5: Unknown service
echo "❌ Test 5: Unknown Service"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceName": "unknown-service",
    "apiKey": "some-api-key"
  }' \
  -w "\nStatus Code: %{http_code}\n" \
  -s | jq .

echo ""
echo "🎉 All tests completed!"
echo ""
echo "📊 Expected Results:"
echo "✅ Test 1: Status 200 - Valid authentication"
echo "❌ Test 2: Status 401 - Invalid API key"
echo "❌ Test 3: Status 400 - Missing headers"
echo "✅ Test 4: Status 200 - Valid body authentication"
echo "❌ Test 5: Status 401 - Unknown service"