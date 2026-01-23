#!/bin/bash

# Build and Deploy Service Authentication Lambda
# Usage: ./build-service-auth.sh

set -e

echo "🔐 Building Service Authentication Lambda..."
echo ""

# Check if we're in the right directory
if [ ! -f "auth/service-auth.js" ]; then
    echo "❌ Error: auth/service-auth.js not found!"
    echo "Please run this script from the tc-golunch-serverless directory"
    exit 1
fi

# Create service-auth.zip
echo "📦 Creating service-auth.zip..."
cd auth
zip -r ../service-auth.zip service-auth.js
cd ..
echo "✅ service-auth.zip created"

# Verify the zip contents
echo ""
echo "📋 Zip contents:"
unzip -l service-auth.zip

# Check Terraform configuration
echo ""
echo "🔍 Validating Terraform configuration..."
terraform validate

if [ $? -eq 0 ]; then
    echo "✅ Terraform configuration is valid"
    echo ""
    
    echo "🚀 Ready to deploy! Run the following commands:"
    echo "terraform plan"
    echo "terraform apply"
else
    echo "❌ Terraform configuration has errors"
    exit 1
fi

echo ""
echo "🎉 Build completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Review the plan: terraform plan"
echo "2. Deploy: terraform apply"
echo "3. Test the endpoint: POST https://your-api-url/validate-service"