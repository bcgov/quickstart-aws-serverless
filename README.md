[![Merge](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/merge.yml/badge.svg)](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/merge.yml)
[![PR](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/pr-open.yml/badge.svg)](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/pr-open.yml)
[![PR Validate](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/pr-validate.yml/badge.svg)](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/pr-validate.yml)
[![CodeQL](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/github-code-scanning/codeql)
[![Pause AWS Resources](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/pause-resources.yml/badge.svg)](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/pause-resources.yml)
[![Resume AWS Resources](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/resume-resources.yml/badge.svg)](https://github.com/bcgov/quickstart-aws-nosql/actions/workflows/resume-resources.yml)

# 🚀 Quickstart for AWS using DynamoDB, ECS Fargate, and CloudFront


## 🏗️ What's Included

- 🗄️ **DynamoDB** - NoSQL database with pay-per-request billing
- 🐳 **ECS Fargate** - Mixed FARGATE/FARGATE_SPOT for cost optimization
- 🌐 **API Gateway** - VPC link integration for secure backend access
- ⚡ **CloudFront** - Frontend CDN with WAF protection
- 🔧 **NestJS** - TypeScript backend API with AWS SDK
- ⚛️ **React + Vite** - Modern frontend application
- 🏗️ **Terragrunt/Terraform** - Infrastructure-as-code deployment
- 🔄 **GitHub Actions** - Complete CI/CD pipeline automation

---

## 📋 Prerequisites

Before you start, make sure you have:

- ✅ BCGOV AWS account with appropriate permissions
- ✅ AWS CLI installed and configured
- ✅ Docker/Podman (for containerized development)
- ✅ Node.js 22+ and npm (for local development)
- ✅ Terraform CLI and Terragrunt

---

## 📁 Project Structure

```
📦 quickstart-aws-nosql
├── 🔄 .github/                   # CI/CD workflows and actions
│   └── workflows/                # GitHub Actions definitions
├── 🏗️ terraform/                 # Environment configurations
│   ├── api/                      # API configs (dev, test)
│   ├── database/                 # Database configs (dev, test)
│   └── frontend/                 # Frontend configs (dev, test)
├── 🏛️ infrastructure/            # Terraform modules
│   ├── api/                      # ECS Fargate + API Gateway
│   ├── frontend/                 # CloudFront + WAF
│   ├── modules/                  # Shared modules
│   └── database/                 # DynamoDB configuration
├── 🔧 backend/                   # NestJS API
│   ├── src/                      # TypeScript source code
│   └── Dockerfile               # Backend container
├── ⚛️ frontend/                  # React + Vite SPA
│   ├── src/                      # React components
│   ├── e2e/                      # Playwright tests
│   └── Dockerfile               # Frontend container
├── 🧪 tests/                     # Cross-service tests
│   ├── integration/              # Integration tests
│   └── load/                     # Performance tests
├── 🐳 docker-compose.yml         # Local development
├── 📖 README.md                  # This file
└── 📦 package.json               # Monorepo config
```

### 🔍 Key Directories Explained

#### 🔄 `.github/`
GitHub workflows for automated testing, deployment, and resource management.

#### 🏗️ `terraform/`
Terragrunt configurations for different environments (dev, test, prod).

#### 🏛️ `infrastructure/`
- **🔧 api/**: ECS Fargate cluster, ALB, API Gateway, auto-scaling
- **⚛️ frontend/**: CloudFront distribution with WAF rules
- **🗄️ database/**: DynamoDB tables and indexes
- **🧩 modules/**: Reusable Terraform components

#### 🔧 `backend/`
NestJS application with AWS SDK integration for DynamoDB operations.

#### ⚛️ `frontend/`
React SPA with Vite build tooling and Playwright E2E tests.

---

## 🏃‍♂️ Quick Start

### 🐳 Option 1: Docker Compose (Recommended)

1. **Clone and navigate to the project:**
   ```bash
   cd <your-project-directory>
   ```

2. **Start the entire stack:**
   ```bash
   docker-compose up --build
   ```

3. **Access your applications:**
   - 🔧 Backend API: http://localhost:3001
   - ⚛️ Frontend: http://localhost:3000

4. **Stop the stack:**
   ```bash
   docker-compose down
   ```

### 💻 Option 2: Local Development

#### Prerequisites Setup
```bash
# Install and start DynamoDB Local
java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb -inMemory
```

#### Database Setup
```bash
# Create local table
aws dynamodb create-table \
  --endpoint-url http://localhost:8000 \
  --table-name users \
  --attribute-definitions AttributeName=id,AttributeType=S AttributeName=email,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --global-secondary-indexes IndexName=EmailIndex,KeySchema=[{AttributeName=email,KeyType=HASH}],Projection={ProjectionType=ALL} \
  --billing-mode PAY_PER_REQUEST

# Add sample data
aws dynamodb put-item \
  --endpoint-url http://localhost:8000 \
  --table-name users \
  --item '{"id":{"S":"1"}, "name":{"S":"John"}, "email":{"S":"John.ipsum@test.com"}}'
```

#### Start Backend
```bash
cd backend
export DYNAMODB_TABLE_NAME=users
export DYNAMODB_ENDPOINT=http://localhost:8000
export AWS_REGION=ca-central-1
export AWS_ACCESS_KEY_ID=dummy
export AWS_SECRET_ACCESS_KEY=dummy
npm run start:dev
```

#### Start Frontend
```bash
cd frontend
npm run dev
```

---

## ☁️ Deploying to AWS

### 🔄 Using GitHub Actions (Recommended)

The repository includes automated CI/CD workflows:

1. **Follow the setup guide:** [AWS Deployment Setup](https://github.com/bcgov/quickstart-aws-helpers/blob/main/AWS-DEPLOY.md)
2. **Push to main branch** to trigger deployment
3. **Monitor workflows** in the Actions tab

### 📊 CI/CD Pipeline Overview

#### 🔀 Pull Request Workflow
When you open a PR:
- ✅ Code building with concurrency control
- 📋 Infrastructure planning with Terraform
- 🧪 Comprehensive testing in isolated environments
- 🛡️ Security scanning with Trivy
- 📊 SonarCloud code quality analysis

#### 🚀 Merge Workflow
When code is merged:
- ▶️ Auto-resume AWS resources
- 🚀 Deploy to dev environment
- 🏷️ Tag containers with 'dev'
- 🧪 Run E2E tests
- 🚀 Deploy to test environment
- 🏷️ Tag containers with 'test'
- ⏸️ Auto-pause resources for cost savings

---

## 🏗️ Architecture Overview

![Architecture](./.diagrams/arch.drawio.svg)

### 🔧 Key Components

#### 🐳 ECS Fargate
- **💰 Cost Strategy**: 20% FARGATE + 80% FARGATE_SPOT
- **📈 Auto-scaling**: CPU/memory-based scaling
- **🔒 Secrets**: AWS Secrets Manager integration

#### 🌐 API Gateway
- HTTP API with VPC Link
- Proxy integration to internal ALB
- Secure backend access

#### 🗄️ DynamoDB
- Pay-per-request billing
- AWS SDK integration
- No migration scripts needed

---

## 🎛️ Customization Guide

### 1. 📝 Repository Setup
- Clone and update project names
- Configure GitHub secrets
- Set up AWS credentials

### 2. 🏗️ Infrastructure
- Modify `terraform/` for your environments
- Adjust ECS resources in `infrastructure/api/ecs.tf`
- Customize auto-scaling thresholds
- Update database configurations

### 3. 💻 Application
- Customize NestJS backend in `backend/`
- Adapt React frontend in `frontend/`
- Update API endpoints and data models

### 4. 🔄 CI/CD Pipeline
- Modify workflows in `.github/workflows/`
- Configure deployment schedules
- Set up environment-specific rules

### 5. 🧪 Testing
- Adapt unit tests (Vitest)
- Update E2E tests (Playwright)
- Configure load tests (k6)
- Set up SonarCloud integration

---

## 💰 Cost Optimization

### ⏸️ Resource Management
- **Auto-pause**: ECS services pause after deployment
- **Auto-resume**: Services resume before deployment
- **Scheduling**: Configurable pause/resume schedules
- **DynamoDB**: Pay-per-request billing (no pause needed)

### 📊 Monitoring
- CloudWatch metrics and alarms
- Cost tracking per environment
- Resource utilization reports

---

## 🤝 Contributing
We welcome contributions to improve this template! Please contribute your ideas! Issues and Pull Requests are appreciated.

Built with ❤️ by the NRIDS Team
