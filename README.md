# 🔐 Repositório de Autenticação Serverless - GoLunch Auth API

Sistema de autenticação serverless desenvolvido com AWS Lambda, API Gateway e Amazon Cognito para o projeto GoLunch. Este repositório implementa a **camada de autenticação centralizada** que se integra com a **arquitetura de microserviços**, seguindo o padrão arquitetural do monolítico `tc-golunch-api`.

## 🎯 **Abordagem Arquitetural: Serverless + Microserviços**

### **🔄 Padrão de Migração do Monolítico**
Este repositório segue a **estratégia de separação de responsabilidades** extraindo a autenticação do monolítico `tc-golunch-api` para uma camada serverless independente, mantendo **compatibilidade total** com os microserviços.

**Estratégia Implementada:**
```
tc-golunch-api (Monolítico)
├── JWTService (local) ──────────┐
├── AuthController             │ EXTRAÍDO PARA SERVERLESS
├── AuthMiddleware             │
└── Business Logic ─────────────┼──────► Microserviços
                                │
                                ▼
tc-golunch-serverless/
├── RegisterUser Lambda        ◄── Substitui AuthController.Register
├── LoginUser Lambda           ◄── Substitui AuthController.Login  
├── ServiceAuth Lambda         ◄── Substitui JWTService.ValidateToken
└── API Gateway                ◄── Substitui rotas /auth/*
```

### **🏗️ Arquitetura Híbrida Resultante**

- **🔐 Autenticação Serverless** (este repositório): AWS Lambda + Cognito + API Gateway
- **🎯 Core Service**: Lógica de negócio principal (produtos, clientes, pedidos) 
- **💳 Payment Service**: Processamento de pagamentos e MercadoPago
- **🍳 Operation Service**: Operações de cozinha e produção

**Benefícios desta Abordagem:**
- ✅ **Escalabilidade Independente**: Autenticação escala automaticamente via Lambda
- ✅ **Consistência**: Mesma interface `AuthGateway` do monolítico nos microserviços
- ✅ **Segurança Centralizada**: Tokens JWT gerenciados pelo AWS Cognito
- ✅ **Evolução Gradual**: Microserviços podem migrar individualmente do JWT local para serverlessório de Autenticação Serverless - GoLunch Auth API

Sistema de autenticação serverless desenvolvido com AWS Lambda, API Gateway e Amazon Cognito para o projeto GoLunch. Este repositório implementa funcionalidades de autenticação, registro de usuários e login anônimo, integrando-se com a **arquitetura de microserviços** (Core, Payment, Operation Services).

## 🏗️ Arquitetura Híbrida: Serverless + Microserviços

Este repositório implementa a **camada de autenticação serverless** que se integra com os **3 microserviços de negócio**:

- **🔐 Autenticação Serverless** (este repositório): AWS Lambda + Cognito + API Gateway
- **� Core Service** (tc-golunch-core-service): Lógica de negócio principal - produtos, clientes, pedidos
- **💳 Payment Service** (tc-golunch-payment-service): Processamento de pagamentos e MercadoPago
- **🍳 Operation Service** (tc-golunch-operation-service): Operações de cozinha e produção

## 🏛️ [Link Excalidraw - Arquitetura Serverless + Fluxos funcionais](https://excalidraw.com/#room=19187e25c8f502969730,UYsX9MelEMWQAT8VN4Marg)

## Infraestrutura Serverless AWS

### 🔐 Autenticação (Amazon Cognito)
- **User Pool** configurado para gerenciamento de usuários
- **User Pool Client** para integração com aplicações
- Suporte a **login anônimo** para clientes não cadastrados
- **JWT tokens** para autenticação segura

### ⚡ Funções Lambda
- **RegisterUser**: Registro de novos usuários (clientes) no sistema
- **LoginUser**: Autenticação de usuários cadastrados
- **AnonymousLogin**: Login anônimo para clientes não cadastrados  
- **AdminRegister**: Registro de administradores do sistema
- **AdminLogin**: Autenticação de administradores
- **ServiceAuth**: Validação de tokens entre microserviços (Core ↔ Payment ↔ Operation)
- **Runtime**: Node.js 20.x
- **Timeout**: Configurado para operações de autenticação

### 🌐 API Gateway
- **REST API** unificada para todos os endpoints de autenticação
- **CORS** configurado para integração com frontend
- **Integration** com EKS cluster via Network Load Balancer
- **Stages**: Configuração de ambientes (dev/prod)

### 🔗 Integração com Microserviços
Esta implementação segue **exatamente o mesmo padrão** do monolítico `tc-golunch-api`, garantindo compatibilidade total:

#### **🔄 Padrão do Monolítico vs Serverless**
```go
// ANTES (tc-golunch-api monolítico):
jwtGateway := external.NewJWTService(secretKey, duration)
authController := authcontroller.New(jwtGateway)
customerController := customercontroller.Build(datasource, authController)
authenticated.Use(middleware.AuthMiddleware(authController))

// DEPOIS (microserviços + serverless):
serverlessAuth := gateway.NewServerlessAuthGateway(lambdaURL, serviceAuthURL)
customerController := customercontroller.Build(datasource, serverlessAuth)
authenticated.Use(middleware.ServerlessAuthMiddleware(serverlessAuth))
```

#### **📡 Comunicação Serverless ↔ Microserviços**
1. **Frontend** → `/auth/login` (API Gateway → Lambda) → **JWT Token**
2. **Frontend** → Microserviço com `Authorization: Bearer <token>`
3. **Microserviço** → `SERVICE_AUTH_LAMBDA_URL` (validação via Lambda)
4. **Lambda ServiceAuth** → Valida token e retorna claims
5. **Microserviço** → Continua processamento com contexto autenticado

#### **🛡️ Service-to-Service Authentication**
```javascript
// Lambda ServiceAuth Environment Variables
CORE_SERVICE_URL      = "http://core-service:8081"      // EKS internal
PAYMENT_SERVICE_URL   = "http://payment-service:8082"   // EKS internal  
OPERATION_SERVICE_URL = "http://operation-service:8083" // EKS internal
SERVICE_SECRET_KEY    = "microservices-shared-secret-key-2024"

// API Keys for validation
CORE_SERVICE_API_KEY      = "core-service-secure-api-key-2024"
PAYMENT_SERVICE_API_KEY   = "payment-service-secure-api-key-2024"
OPERATION_SERVICE_API_KEY = "operation-service-secure-api-key-2024"
```

### ⚙️ Pipeline CI/CD (GitHub Actions)

O repositório contém um pipeline configurado no **GitHub Actions** que executa as seguintes etapas:

1. **Validação** dos arquivos Terraform (`terraform fmt`, `terraform validate`, `terraform plan`).
2. **Build** das funções Lambda (compactação e preparação dos pacotes).
3. **Provisionamento/Atualização** da infraestrutura serverless na AWS (`terraform apply`).
4. **Criação de Backend** via script `create_backend.sh` -> backend utilizado para guardar o tf.state da infra.
5. **Deleção Secrets** via script `secret_deletion.sh` -> evitar problemas quando as secrets forem criadas novamente.
6. **Controle de versão**: qualquer mudança na infra passa pelo fluxo de *Pull Request* e é aplicada somente após revisão e aprovação.

### 🚀 Deploy e Configuração

#### **Pré-requisitos**
- AWS CLI configurado com credenciais adequadas
- Terraform >= 1.2
- Variáveis de ambiente configuradas no `terraform.tfvars`

#### **Deploy Completo**
```bash
# 1. Backend S3 para Terraform State
./create_backend_bucket.sh

# 2. Deploy da infraestrutura serverless
terraform init
terraform plan
terraform apply

# 3. Configuração dos microserviços (environment variables)
export LAMBDA_AUTH_URL="https://your-api-gateway-url/auth"
export SERVICE_AUTH_LAMBDA_URL="https://your-api-gateway-url/service-auth"
```

#### **🔧 Variables de Ambiente Essenciais**
```bash
# Microserviços URLs (para Lambda ServiceAuth)
CORE_SERVICE_URL="http://core-service:8081"
PAYMENT_SERVICE_URL="http://payment-service:8082"  
OPERATION_SERVICE_URL="http://operation-service:8083"

# Authentication URLs (para microserviços)
LAMBDA_AUTH_URL="https://api-gateway-url/auth"
SERVICE_AUTH_LAMBDA_URL="https://api-gateway-url/service-auth"

# Security Keys
JWT_SECRET_KEY="your-jwt-secret-key-2024"
SERVICE_SECRET_KEY="microservices-shared-secret-key-2024"
```

### 📊 Monitoramento

#### **CloudWatch Logs Groups**
- `/aws/lambda/tc-golunch-register`
- `/aws/lambda/tc-golunch-login` 
- `/aws/lambda/tc-golunch-admin-login`
- `/aws/lambda/tc-golunch-service-auth`

#### **Métricas Key**
- **Invocations**: Número total de chamadas por Lambda
- **Duration**: Tempo de execução (target < 1000ms)
- **Errors**: Rate de erro (target < 1%)
- **Throttles**: Controle de concorrência

### 🧪 Testes

#### **Testes Unitários (Local)**
```bash
# Para cada função Lambda
cd auth/register && go test ./...
cd ../login && go test ./...
cd ../admin_login && go test ./...
cd ../service_auth && go test ./...
```

#### **Testes de Integração**
```bash
# Collection Bruno para testes end-to-end
cd ../fiap161-tc-collections
# Executar cenários de login, registro e validação
```

#### **Load Testing**
```bash
# Usando Fortio (disponível no k8s/)
kubectl apply -f fortio-stress-job.yaml
```

## 📁 Estrutura do Projeto

```
tc-golunch-serverless/
├── auth/                          # Código das funções Lambda
│   ├── anonymous.js              # Login anônimo (clientes)
│   ├── login.js                  # Autenticação de clientes
│   ├── register.js               # Registro de clientes
│   ├── admin-register.js         # Registro de administradores  
│   ├── admin-login.js           # Autenticação de administradores
│   ├── service-auth.js          # Validação entre microserviços
│   └── package.json              # Dependências Node.js
├── modules/                      # Módulos Terraform
│   ├── api-gateway/              # Configuração do API Gateway
│   ├── cognito/                  # Configuração do Cognito
│   └── lambda/                   # Configuração das Lambdas
├── environments/                 # Configurações por ambiente
│   ├── dev.tfvars               # Variáveis para desenvolvimento
│   └── prod.tfvars              # Variáveis para produção
├── main.tf                      # Configuração principal do Terraform
├── variables.tf                  # Definição de variáveis
├── outputs.tf                   # Outputs da infraestrutura
└── terraform.tfvars.example     # Exemplo de configuração
```

## 🚀 Endpoints Disponíveis

### 👤 Autenticação de Clientes
- `POST /auth/register` - Registro de novos clientes
- `POST /auth/login` - Login de clientes cadastrados
- `POST /auth/anonymous` - Login anônimo para clientes

### 🛡️ Autenticação Administrativa  
- `POST /admin/register` - Registro de administradores
- `POST /admin/login` - Login de administradores

### 🔗 Validação Entre Serviços
- `POST /service/auth` - Validação de tokens entre microserviços
- `GET /health` - Health check da API

## 🔄 Fluxo de Integração com Microserviços

1. **Cliente** faz login via `/auth/login` → recebe JWT token
2. **Frontend** envia requests para **Core Service** com token JWT
3. **Core Service** valida token via `/service/auth` (opcional, pode validar localmente)
4. **Core Service** comunica com **Payment/Operation Services** repassando contexto de autenticação
5. **Logs centralizados** via CloudWatch para auditoria

## 🔧 Configuração e Deploy

### **Setup Inicial**
1. **Clone o repositório**
2. **Configure as variáveis** copiando `terraform.tfvars.example` para `terraform.tfvars`
3. **Configure as credenciais AWS** via AWS CLI ou variáveis de ambiente
4. **Execute o deploy** seguindo os passos na seção "Deploy e Configuração"

### **Integração com Microserviços**
Após o deploy do serverless, configure os microserviços com as URLs geradas:
```bash
# No deployment dos microserviços, adicionar:
- name: LAMBDA_AUTH_URL
  value: "https://seu-api-gateway-id.execute-api.region.amazonaws.com/auth"
- name: SERVICE_AUTH_LAMBDA_URL  
  value: "https://seu-api-gateway-id.execute-api.region.amazonaws.com/service-auth"
```

## 📋 Dependências

- **Terraform** >= 1.2
- **AWS CLI** configurado
- **Node.js** 20.x (para desenvolvimento local das Lambdas)
- **Integração** com microserviços: Core Service (8081), Payment Service (8082), Operation Service (8083)
- **Acesso** aos outputs do repositório `tc-golunch-infra`

## 🔗 Repositórios Relacionados

- **tc-golunch-core-service**: Lógica de negócio principal (produtos, clientes, pedidos)
- **tc-golunch-payment-service**: Processamento de pagamentos com MercadoPago
- **tc-golunch-operation-service**: Operações de cozinha e produção
- **tc-golunch-infra**: Infraestrutura EKS e recursos compartilhados
- **tc-golunch-database**: Configuração dos bancos de dados dos microserviços
