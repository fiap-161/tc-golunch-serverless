#!/bin/bash
set -euo pipefail

# Variáveis
REGION="us-east-1"
BUCKET_NAME="api-gateway-bucket"

# Verifica se o bucket já existe
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "✅ Bucket $BUCKET_NAME já existe."
else
  echo "🚀 Criando bucket $BUCKET_NAME em $REGION..."

  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi

  echo "🔄 Ativando versionamento no bucket $BUCKET_NAME..."
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

  echo "✅ Bucket $BUCKET_NAME criado com versionamento habilitado."
fi