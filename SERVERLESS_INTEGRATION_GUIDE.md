# 🚀 Guia de Integração Serverless - Para Desenvolvedores

## 📋 Resumo das Mudanças Necessárias

Este documento contém **TODAS** as alterações que os desenvolvedores precisam fazer para integrar a autenticação serverless (AWS Lambda) com os microserviços.

## ⚠️ IMPORTANTE: Alterações Já Implementadas

**O código já foi 100% atualizado!** Os passos necessários:

1. **PRIMEIRO**: Deploy do `tc-golunch-serverless` (gera URLs reais)
2. **DEPOIS**: Configurar URLs reais nos microserviços

### ✅ Código Já Atualizado (Zero Code Changes Needed)

1. **ServerlessAuthGateway**: Implementado em todos os microserviços
2. **ServerlessAuthMiddleware**: Middleware serverless compatível 
3. **main.go**: Dependency injection atualizada para serverless
4. **CustomClaims**: Entidade para JWT claims adicionada
5. **Interface compatibility**: Mantida 100% compatibilidade com padrão existente

## 🔧 ÚNICA MUDANÇA NECESSÁRIA: Deploy Serverless + Configurar URLs

### **⚠️ PREREQUISITO OBRIGATÓRIO: Deploy do Serverless**

**ANTES** de configurar qualquer microserviço, faça deploy do serverless:

```bash
# PASSO 1: Deploy serverless (cria Lambda + API Gateway)
cd tc-golunch-serverless
terraform init
terraform apply

# PASSO 2: Obter URLs REAIS geradas
terraform output
# Exemplo output:
# api_gateway_url = "https://abc123def.execute-api.us-east-1.amazonaws.com"
```

### **Passo 3: Configurar URLs Reais por Serviço**

#### **🎯 Core Service (porta 8081)**
```bash
# ⚠️ PREREQUISITO: Deploy tc-golunch-serverless PRIMEIRO!

# URLs Serverless (SUBSTITUIR por URLs reais do terraform output)
export LAMBDA_AUTH_URL="https://abc123def.execute-api.us-east-1.amazonaws.com/auth"
export SERVICE_AUTH_LAMBDA_URL="https://abc123def.execute-api.us-east-1.amazonaws.com/service-auth"

# Variáveis existentes (mantidas)
export DATABASE_URL="host=localhost user=golunch_order password=golunch_order123 dbname=golunch_orders port=5433 sslmode=disable TimeZone=America/Sao_Paulo"
export PAYMENT_SERVICE_URL="http://localhost:8082"
export OPERATION_SERVICE_URL="http://localhost:8083"
```

#### **💳 Payment Service (porta 8082)**
```bash
# ⚠️ PREREQUISITO: Deploy tc-golunch-serverless PRIMEIRO!

# URLs Serverless (SUBSTITUIR por URLs reais do terraform output)
export LAMBDA_AUTH_URL="https://abc123def.execute-api.us-east-1.amazonaws.com/auth"
export SERVICE_AUTH_LAMBDA_URL="https://abc123def.execute-api.us-east-1.amazonaws.com/service-auth"

# Variáveis existentes (mantidas)
export MONGODB_URI="mongodb://localhost:27017"
export MONGODB_DATABASE="golunch_payments"
export PAYMENT_SERVICE_PORT="8082"
export ORDER_SERVICE_URL="http://localhost:8081"
export OPERATION_SERVICE_URL="http://localhost:8083"
export MP_ACCESS_TOKEN="seu-mercado-pago-token"
export MP_USER_ID="seu-user-id"
export MP_POS_ID="seu-pos-id"
```

#### **👨‍🍳 Operation Service (porta 8083)**
```bash
# ⚠️ PREREQUISITO: Deploy tc-golunch-serverless PRIMEIRO!

# URLs Serverless (SUBSTITUIR por URLs reais do terraform output)
export LAMBDA_AUTH_URL="https://abc123def.execute-api.us-east-1.amazonaws.com/auth"
export SERVICE_AUTH_LAMBDA_URL="https://abc123def.execute-api.us-east-1.amazonaws.com/service-auth"

# Variáveis existentes (mantidas)
export DATABASE_URL="host=localhost user=golunch_prod password=golunch_prod123 dbname=golunch_production port=5434 sslmode=disable TimeZone=America/Sao_Paulo"
export SECRET_KEY="production-secret-key-2024"
export OPERATION_SERVICE_PORT="8083"
export ORDER_SERVICE_URL="http://localhost:8081"
export PAYMENT_SERVICE_URL="http://localhost:8082"
```

## 🐳 Deploy Kubernetes - Exemplo Completo

### **Core Service Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-service
  namespace: golunch
spec:
  replicas: 2
  selector:
    matchLabels:
      app: core-service
  template:
    metadata:
      labels:
        app: core-service
    spec:
      containers:
      - name: core-service
        image: your-ecr/core-service:latest
        ports:
        - containerPort: 8081
        env:
        # NOVAS VARIÁVEIS SERVERLESS
        - name: LAMBDA_AUTH_URL
          value: "https://abc123def.execute-api.us-east-1.amazonaws.com/auth"
        - name: SERVICE_AUTH_LAMBDA_URL
          value: "https://abc123def.execute-api.us-east-1.amazonaws.com/service-auth"
        # VARIÁVEIS EXISTENTES
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: core-db-url
        - name: PAYMENT_SERVICE_URL
          value: "http://payment-service:8082"
        - name: OPERATION_SERVICE_URL
          value: "http://operation-service:8083"
```

### **Payment Service Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: golunch
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
      - name: payment-service
        image: your-ecr/payment-service:latest
        ports:
        - containerPort: 8082
        env:
        # NOVAS VARIÁVEIS SERVERLESS
        - name: LAMBDA_AUTH_URL
          value: "https://abc123def.execute-api.us-east-1.amazonaws.com/auth"
        - name: SERVICE_AUTH_LAMBDA_URL
          value: "https://abc123def.execute-api.us-east-1.amazonaws.com/service-auth"
        # VARIÁVEIS EXISTENTES
        - name: MONGODB_URI
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: mongodb-uri
        - name: MONGODB_DATABASE
          value: "golunch_payments"
        - name: PAYMENT_SERVICE_PORT
          value: "8082"
        - name: ORDER_SERVICE_URL
          value: "http://core-service:8081"
        - name: OPERATION_SERVICE_URL
          value: "http://operation-service:8083"
        - name: MP_ACCESS_TOKEN
          valueFrom:
            secretKeyRef:
              name: mercadopago-secret
              key: access-token
```

### **Operation Service Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: operation-service
  namespace: golunch
spec:
  replicas: 2
  selector:
    matchLabels:
      app: operation-service
  template:
    metadata:
      labels:
        app: operation-service
    spec:
      containers:
      - name: operation-service
        image: your-ecr/operation-service:latest
        ports:
        - containerPort: 8083
        env:
        # NOVAS VARIÁVEIS SERVERLESS
        - name: LAMBDA_AUTH_URL
          value: "https://abc123def.execute-api.us-east-1.amazonaws.com/auth"
        - name: SERVICE_AUTH_LAMBDA_URL
          value: "https://abc123def.execute-api.us-east-1.amazonaws.com/service-auth"
        # VARIÁVEIS EXISTENTES
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: operation-db-url
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: secret-key
        - name: OPERATION_SERVICE_PORT
          value: "8083"
        - name: ORDER_SERVICE_URL
          value: "http://core-service:8081"
        - name: PAYMENT_SERVICE_URL
          value: "http://payment-service:8082"
```

## 🧪 Testes de Validação

### **1. Teste Local (Development)**
```bash
# 1. Configure as variáveis de ambiente
export LAMBDA_AUTH_URL="https://your-api-gateway.amazonaws.com/auth"
export SERVICE_AUTH_LAMBDA_URL="https://your-api-gateway.amazonaws.com/service-auth"

# 2. Inicie cada serviço
cd tc-golunch-core-service && go run cmd/api/main.go &
cd tc-golunch-payment-service && go run cmd/api/main.go &
cd tc-golunch-operation-service && go run cmd/api/main.go &

# 3. Teste autenticação serverless
curl -X POST http://localhost:8081/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 4. Use token retornado para testar endpoints protegidos
curl -X GET http://localhost:8081/admin/orders \
  -H "Authorization: Bearer <jwt-token-from-lambda>"
```

### **2. Teste Kubernetes (Production)**
```bash
# 1. Deploy com as novas variáveis
kubectl apply -f k8s/core-service-deployment.yaml
kubectl apply -f k8s/payment-service-deployment.yaml  
kubectl apply -f k8s/operation-service-deployment.yaml

# 2. Verifique se pods estão rodando
kubectl get pods -n golunch

# 3. Teste via port-forward
kubectl port-forward svc/core-service 8081:8081 -n golunch &
curl -X POST http://localhost:8081/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

## 🔍 Troubleshooting

### **Problema: "Failed to connect to Lambda"**
```bash
# Verifique se as URLs estão corretas
echo $LAMBDA_AUTH_URL
echo $SERVICE_AUTH_LAMBDA_URL

# Teste conectividade
curl -X POST $LAMBDA_AUTH_URL/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'
```

### **Problema: "Authentication failed"**
```bash
# Verifique logs do serviço
kubectl logs -f deployment/core-service -n golunch

# Verifique se Lambda está rodando
aws lambda list-functions --query 'Functions[?contains(FunctionName, `golunch`)]'
```

### **Problema: "Environment variable not set"**
```bash
# Verifique variáveis no pod
kubectl exec -it deployment/core-service -n golunch -- env | grep LAMBDA
```

## ✅ Checklist Final para Desenvolvedores

- [ ] Deploy do `tc-golunch-serverless` realizado
- [ ] URLs do API Gateway obtidas via `terraform output`
- [ ] Variáveis `LAMBDA_AUTH_URL` e `SERVICE_AUTH_LAMBDA_URL` configuradas
- [ ] Testes locais executados com sucesso
- [ ] Manifests Kubernetes atualizados com novas variáveis
- [ ] Deploy em Kubernetes realizado
- [ ] Testes de integração passando
- [ ] Logs confirmam integração com Lambda

## 🎯 Benefícios da Migração

1. **Autenticação Centralizada**: Um único ponto de autenticação para todos os serviços
2. **Escalabilidade**: AWS Lambda escala automaticamente
3. **Segurança**: Tokens JWT gerados em ambiente controlado
4. **Compatibilidade**: Zero breaking changes nos endpoints existentes
5. **Flexibilidade**: Pode rodar local (fallback) ou serverless (produção)

## 📞 Suporte

Se encontrar problemas durante a integração, consulte:

1. **Logs dos serviços**: `kubectl logs -f deployment/SERVICE_NAME -n golunch`
2. **CloudWatch**: Logs das funções Lambda
3. **Swagger UI**: `http://localhost:PORT/swagger/index.html`
4. **README específico** de cada serviço para detalhes adicionais
