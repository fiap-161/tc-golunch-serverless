# Admin Endpoints - Documentação de Testes

Este documento descreve como testar as novas Lambda Functions de autenticação de administradores.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Endpoints Disponíveis](#endpoints-disponíveis)
- [Como Testar](#como-testar)
- [Exemplos de Requisições](#exemplos-de-requisições)
- [Validações e Regras](#validações-e-regras)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

As novas Lambda Functions permitem registro e login de usuários administradores usando **email e senha**.

### Diferenças entre Customer e Admin

| Aspecto | Customer | Admin |
|---------|----------|-------|
| **Identificador** | CPF | Email |
| **Endpoint Registro** | POST /auth/register | POST /admin/register |
| **Endpoint Login** | POST /auth/login | POST /admin/login |
| **Cognito Group** | - | admins |
| **userType (JWT)** | "regular" | "admin" |

---

## 📡 Endpoints Disponíveis

### 1. POST /admin/register

Registra um novo administrador no sistema.

**URL:** `https://{api-gateway-url}/admin/register`

**Método:** `POST`

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "email": "admin@golunch.com",
  "password": "SecurePassword123!"
}
```

**Resposta de Sucesso (201 Created):**
```json
{
  "message": "Admin registered successfully",
  "email": "admin@golunch.com",
  "userStatus": "FORCE_CHANGE_PASSWORD",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Erros Possíveis:**
- `400 Bad Request` - Email ou senha ausentes/inválidos
- `409 Conflict` - Admin com este email já existe
- `500 Internal Server Error` - Erro do servidor

---

### 2. POST /admin/login

Autentica um administrador existente.

**URL:** `https://{api-gateway-url}/admin/login`

**Método:** `POST`

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "email": "admin@golunch.com",
  "password": "SecurePassword123!"
}
```

**Resposta de Sucesso (200 OK):**
```json
{
  "message": "Admin login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "accessToken": "eyJraWQiOiJ...",
  "idToken": "eyJraWQiOiJ...",
  "refreshToken": "eyJjdHki...",
  "expiresIn": 3600
}
```

**Erros Possíveis:**
- `400 Bad Request` - Email ou senha ausentes/formato inválido
- `401 Unauthorized` - Email ou senha incorretos
- `403 Forbidden` - Usuário não está no grupo "admins"
- `500 Internal Server Error` - Erro do servidor

---

## 🧪 Como Testar

### Opção 1: cURL

#### Registrar Admin
```bash
# Substitua {API_GATEWAY_URL} pela URL do seu API Gateway
API_URL="https://xxxxx.execute-api.us-east-1.amazonaws.com/prod"

curl -X POST "${API_URL}/admin/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@golunch.com",
    "password": "SecurePass123!"
  }'
```

#### Login Admin
```bash
curl -X POST "${API_URL}/admin/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@golunch.com",
    "password": "SecurePass123!"
  }'
```

#### Salvar Token em Variável
```bash
# Registrar e extrair token
TOKEN=$(curl -s -X POST "${API_URL}/admin/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"TestPass123!"}' \
  | jq -r '.token')

echo "Token: $TOKEN"

# Usar token em requisições subsequentes
curl -X GET "${API_URL}/some-protected-endpoint" \
  -H "Authorization: Bearer $TOKEN"
```

---

### Opção 2: Postman

#### 1. Criar Nova Collection

1. Abra Postman
2. Crie uma nova Collection chamada "GoLunch Admin"

#### 2. Configurar Variável de Ambiente

1. Crie um Environment chamado "Dev"
2. Adicione variável:
   - `api_url`: `https://xxxxx.execute-api.us-east-1.amazonaws.com/prod`

#### 3. Criar Requisição - Admin Register

- **Método:** POST
- **URL:** `{{api_url}}/admin/register`
- **Headers:**
  - `Content-Type`: `application/json`
- **Body (raw JSON):**
```json
{
  "email": "admin@golunch.com",
  "password": "SecurePass123!"
}
```

#### 4. Criar Requisição - Admin Login

- **Método:** POST
- **URL:** `{{api_url}}/admin/login`
- **Headers:**
  - `Content-Type`: `application/json`
- **Body (raw JSON):**
```json
{
  "email": "admin@golunch.com",
  "password": "SecurePass123!"
}
```

#### 5. Salvar Token Automaticamente (Script Postman)

Na aba **Tests** da requisição de login, adicione:

```javascript
// Salvar token na variável de ambiente
const response = pm.response.json();
if (response.token) {
    pm.environment.set("admin_token", response.token);
    console.log("Token salvo:", response.token);
}
```

Agora você pode usar `{{admin_token}}` em outras requisições:
```
Authorization: Bearer {{admin_token}}
```

---

### Opção 3: JavaScript/Fetch

```javascript
const API_URL = 'https://xxxxx.execute-api.us-east-1.amazonaws.com/prod';

// Registrar Admin
async function registerAdmin(email, password) {
  const response = await fetch(`${API_URL}/admin/register`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password })
  });

  const data = await response.json();
  console.log('Register response:', data);
  return data;
}

// Login Admin
async function loginAdmin(email, password) {
  const response = await fetch(`${API_URL}/admin/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password })
  });

  const data = await response.json();
  console.log('Login response:', data);
  return data;
}

// Uso
(async () => {
  try {
    // Registrar
    await registerAdmin('admin@golunch.com', 'SecurePass123!');

    // Login
    const loginData = await loginAdmin('admin@golunch.com', 'SecurePass123!');
    const token = loginData.token;

    // Usar token em requisições autenticadas
    const protectedResponse = await fetch(`${API_URL}/some-endpoint`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
  } catch (error) {
    console.error('Error:', error);
  }
})();
```

---

## 🔐 Validações e Regras

### Política de Senha (Cognito)

A senha deve atender aos seguintes requisitos:

- ✅ Mínimo 8 caracteres
- ✅ Pelo menos 1 letra minúscula (a-z)
- ✅ Pelo menos 1 letra maiúscula (A-Z)
- ✅ Pelo menos 1 número (0-9)
- ✅ Pelo menos 1 caractere especial (!@#$%^&*()_+-=[]{}|;:,.<>?)

**Exemplos válidos:**
- `SecurePass123!`
- `Admin@2024`
- `MyP@ssw0rd`

**Exemplos inválidos:**
- `password` (sem maiúsculas, números ou símbolos)
- `Pass123` (sem símbolos, menos de 8 caracteres)
- `PASSWORD!` (sem minúsculas ou números)

### Validação de Email

O email deve seguir o formato padrão:
```
usuario@dominio.com
```

**Exemplos válidos:**
- `admin@golunch.com`
- `john.doe@company.co.uk`
- `user+test@example.com`

**Exemplos inválidos:**
- `admin` (sem @dominio)
- `admin@` (sem domínio)
- `@golunch.com` (sem usuário)

### Verificação de Grupo "admins"

Ao fazer login, o sistema verifica se o usuário está no grupo Cognito **"admins"**.

- ✅ Usuário no grupo → Login permitido
- ❌ Usuário fora do grupo → `403 Forbidden`

---

## 🔍 Estrutura do JWT Token

O token JWT gerado contém os seguintes claims:

```json
{
  "exp": 1701961234,           // Expiration (24 horas)
  "iat": 1701874834,           // Issued At
  "nbf": 1701874834,           // Not Before
  "userID": "admin@golunch.com",
  "userType": "admin",         // Tipo de usuário
  "is_anonymous": false,
  "custom": {
    "email": "admin@golunch.com"
  }
}
```

### Decodificar Token (jwt.io)

Acesse [https://jwt.io](https://jwt.io) e cole o token para ver os claims.

### Validar Token Programaticamente

```javascript
const jwt = require('jsonwebtoken');

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
const SECRET_KEY = process.env.SECRET_KEY;

try {
  const decoded = jwt.verify(token, SECRET_KEY);
  console.log('Token válido:', decoded);
  console.log('User Type:', decoded.userType); // "admin"
} catch (error) {
  console.error('Token inválido:', error.message);
}
```

---

## 🐛 Troubleshooting

### Erro: "Admin with this email already exists" (409)

**Causa:** Tentativa de registrar um email que já existe no Cognito.

**Solução:**
1. Use um email diferente, OU
2. Faça login com o email existente, OU
3. Delete o usuário do Cognito via AWS Console:
   - Acesse: Cognito → User Pools → unified-api-user-pool → Users
   - Busque pelo email e delete

---

### Erro: "Access denied. User is not an admin" (403)

**Causa:** Usuário autenticado, mas não está no grupo "admins".

**Solução:**
1. Verifique se o grupo "admins" existe no Cognito
2. Adicione o usuário ao grupo manualmente:
   - AWS Console → Cognito → User Pools → Groups → admins → Add user

---

### Erro: "Password does not meet security requirements" (400)

**Causa:** Senha não atende aos requisitos da política.

**Solução:**
Use uma senha que atenda aos requisitos:
- Mínimo 8 caracteres
- Letras maiúsculas e minúsculas
- Números
- Símbolos

**Exemplo:** `SecurePass123!`

---

### Erro: "Invalid email or password" (401)

**Causas possíveis:**
1. Email não cadastrado
2. Senha incorreta
3. Usuário não confirmado

**Solução:**
1. Verifique se fez o registro primeiro (`POST /admin/register`)
2. Confirme que está usando a senha correta
3. Verifique o status do usuário no Cognito

---

### Erro: "Admin group not found in Cognito" (500)

**Causa:** Grupo "admins" não foi criado no Cognito.

**Solução:**
1. Execute `terraform apply` para criar o grupo
2. Verifique no AWS Console se o grupo existe:
   - Cognito → User Pools → unified-api-user-pool → Groups

---

### Como obter a URL do API Gateway

Após o deploy com Terraform:

```bash
cd tc-golunch-serverless
terraform output base_url
```

Ou via AWS Console:
1. Acesse: API Gateway → APIs → unified-api-gateway
2. Copie a "Invoke URL"

---

## 📊 Testando o Fluxo Completo

### Cenário 1: Registro + Login + Uso do Token

```bash
#!/bin/bash
API_URL="https://xxxxx.execute-api.us-east-1.amazonaws.com/prod"

# 1. Registrar admin
echo "1. Registrando admin..."
REGISTER_RESPONSE=$(curl -s -X POST "${API_URL}/admin/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"TestPass123!"}')

echo "Resposta: $REGISTER_RESPONSE"
echo ""

# 2. Login
echo "2. Fazendo login..."
LOGIN_RESPONSE=$(curl -s -X POST "${API_URL}/admin/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"TestPass123!"}')

echo "Resposta: $LOGIN_RESPONSE"
echo ""

# 3. Extrair token
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')
echo "3. Token extraído: $TOKEN"
echo ""

# 4. Decodificar token (claims)
echo "4. Claims do token:"
echo $TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq
echo ""

# 5. Usar token em endpoint protegido (exemplo)
echo "5. Usando token em requisição autenticada..."
curl -X GET "${API_URL}/some-protected-endpoint" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🚀 Deploy e CI/CD

### Deploy Manual

```bash
cd tc-golunch-serverless

# Inicializar Terraform
terraform init

# Validar configuração
terraform validate

# Preview de mudanças
terraform plan

# Aplicar mudanças
terraform apply
```

### Deploy via GitHub Actions

O deploy é automático ao fazer push para `main` ou `master`:

```bash
git add .
git commit -m "feat: Add admin Lambda functions"
git push origin main
```

O GitHub Actions executará:
1. Validação Terraform
2. Deploy das Lambdas
3. Criação do grupo Cognito "admins"
4. Configuração das rotas API Gateway

---

## 📝 Logs e Debugging

### CloudWatch Logs

As Lambda Functions registram logs no CloudWatch:

**Localização:**
- `/aws/lambda/AdminRegister`
- `/aws/lambda/AdminLogin`

**Ver logs via AWS CLI:**
```bash
# Logs de registro
aws logs tail /aws/lambda/AdminRegister --follow

# Logs de login
aws logs tail /aws/lambda/AdminLogin --follow
```

**Ver logs via Console:**
1. Acesse: CloudWatch → Log groups
2. Busque por `/aws/lambda/AdminRegister` ou `/aws/lambda/AdminLogin`
3. Clique para ver os logs

---

## 📚 Referências

- [AWS Cognito User Pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html)
- [API Gateway HTTP APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [AWS Lambda Node.js](https://docs.aws.amazon.com/lambda/latest/dg/lambda-nodejs.html)
- [JWT.io - Decodificador de Tokens](https://jwt.io)

---

**Última atualização:** 2025-12-07
