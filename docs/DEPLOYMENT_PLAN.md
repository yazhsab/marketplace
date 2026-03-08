# Marketplace Platform — Deployment Plan & Cloud Cost Comparison

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Component Mapping](#2-component-mapping)
3. [AWS Deployment](#3-aws-deployment)
4. [GCP Deployment](#4-gcp-deployment)
5. [Azure Deployment](#5-azure-deployment)
6. [Cost Comparison Summary](#6-cost-comparison-summary)
7. [Recommended Approach](#7-recommended-approach)

---

## 1. Architecture Overview

```
                    ┌─────────────────────────────────┐
                    │         CDN / Edge Cache         │
                    │   (CloudFront / Cloud CDN / AFD) │
                    └──────────┬──────────────────────┘
                               │
                    ┌──────────▼──────────────────────┐
                    │     Load Balancer (L7 / ALB)     │
                    │         SSL Termination          │
                    └──────┬──────────────┬───────────┘
                           │              │
              ┌────────────▼───┐   ┌──────▼──────────┐
              │  Go Backend    │   │  NextJS Admin    │
              │  (API Server)  │   │  (SSR/SSG)       │
              │  Fiber v2      │   │  App Router      │
              │  x2-3 replicas │   │  x1-2 replicas   │
              └──┬──┬──┬──┬───┘   └──────────────────┘
                 │  │  │  │
      ┌──────────┘  │  │  └──────────────┐
      │             │  │                  │
┌─────▼────┐ ┌─────▼──▼───┐  ┌──────────▼──────────┐
│PostgreSQL │ │   Redis    │  │  Object Storage     │
│16+PostGIS │ │   7.x     │  │  (S3/GCS/Blob)      │
│ Primary + │ │  256MB+   │  │  Product images,    │
│  Replica  │ │  Cluster  │  │  vendor docs, media │
└───────────┘ └────────────┘  └─────────────────────┘
                 │
          ┌──────▼────────┐
          │  Meilisearch   │
          │  v1.6 (VM/     │
          │  Container)    │
          └────────────────┘

External Services:
  • Razorpay (Payments) — SaaS, no cloud hosting needed
  • Firebase FCM (Push Notifications) — Google SaaS
  • SMS Provider — SaaS
```

### Services to Deploy

| Component        | Current (Docker)       | Production Requirement                   |
|------------------|------------------------|------------------------------------------|
| Go Backend       | Single container       | 2-3 replicas, auto-scaling, health checks|
| NextJS Admin     | Single container       | 1-2 replicas, SSR support                |
| PostgreSQL 16    | postgis/postgis:16     | Managed DB with PostGIS, HA, backups     |
| Redis 7          | redis:7-alpine         | Managed Redis, 256MB+, persistence       |
| Meilisearch v1.6 | Container              | VM or container with persistent disk     |
| MinIO            | minio/minio            | Replace with native object storage       |
| Nginx            | nginx:alpine           | Replace with managed LB + CDN            |

---

## 2. Component Mapping

| Component         | AWS                          | GCP                         | Azure                        |
|-------------------|------------------------------|-----------------------------|------------------------------|
| **Compute**       | ECS Fargate / EKS            | Cloud Run / GKE Autopilot   | Container Apps / AKS         |
| **Database**      | RDS PostgreSQL + PostGIS     | Cloud SQL PostgreSQL        | Azure Database for PostgreSQL|
| **Cache**         | ElastiCache Redis            | Memorystore Redis           | Azure Cache for Redis        |
| **Object Storage**| S3                           | Cloud Storage               | Blob Storage                 |
| **Search**        | EC2 / ECS (Meilisearch)      | Compute Engine / Cloud Run  | Container Instance / VM      |
| **Load Balancer** | ALB                          | Cloud Load Balancing        | Application Gateway          |
| **CDN**           | CloudFront                   | Cloud CDN                   | Azure Front Door             |
| **DNS**           | Route 53                     | Cloud DNS                   | Azure DNS                    |
| **SSL**           | ACM (free)                   | Managed SSL (free)          | App Service Certificates     |
| **CI/CD**         | CodePipeline / GitHub Actions| Cloud Build / GitHub Actions | Azure DevOps / GitHub Actions|
| **Monitoring**    | CloudWatch                   | Cloud Monitoring            | Azure Monitor                |
| **Logging**       | CloudWatch Logs              | Cloud Logging               | Azure Log Analytics          |
| **Secrets**       | Secrets Manager              | Secret Manager              | Key Vault                    |
| **Container Reg** | ECR                          | Artifact Registry           | ACR                          |

---

## 3. AWS Deployment

### 3.1 Architecture (ECS Fargate)

```
Route 53 → CloudFront → ALB
                          ├── ECS Fargate (Go Backend, 2 tasks)
                          └── ECS Fargate (NextJS Admin, 1 task)

Data Layer:
  ├── RDS PostgreSQL 16 (Multi-AZ)
  ├── ElastiCache Redis (Single node)
  ├── S3 (replacing MinIO)
  └── ECS Fargate (Meilisearch, 1 task + EBS)
```

### 3.2 Cost Breakdown — AWS

#### Tier 1: Dev/Staging (~$150-200/mo)

| Service               | Spec                                 | Monthly Cost |
|-----------------------|--------------------------------------|-------------|
| ECS Fargate (Backend) | 1 task, 0.5 vCPU, 1GB RAM           | $18         |
| ECS Fargate (Admin)   | 1 task, 0.25 vCPU, 0.5GB RAM        | $9          |
| RDS PostgreSQL        | db.t4g.micro, 20GB, Single-AZ       | $15         |
| ElastiCache Redis     | cache.t4g.micro, 0.5GB              | $12         |
| ECS Fargate (Meili)   | 1 task, 0.5 vCPU, 1GB + 20GB EBS   | $20         |
| S3                    | 10GB storage + requests              | $2          |
| ALB                   | 1 ALB + LCU hours                   | $22         |
| CloudFront            | 50GB transfer                        | $5          |
| Route 53              | 1 hosted zone                        | $1          |
| ECR                   | 5GB images                           | $1          |
| CloudWatch            | Basic monitoring + logs              | $10         |
| Secrets Manager       | 5 secrets                            | $3          |
| Data Transfer          | ~50GB outbound                      | $5          |
| **Total**             |                                      | **~$123/mo**|

#### Tier 2: Production Small (1K-10K users, ~$400-600/mo)

| Service               | Spec                                 | Monthly Cost |
|-----------------------|--------------------------------------|-------------|
| ECS Fargate (Backend) | 2 tasks, 1 vCPU, 2GB RAM each       | $120        |
| ECS Fargate (Admin)   | 1 task, 0.5 vCPU, 1GB RAM           | $30         |
| RDS PostgreSQL        | db.t4g.small, 50GB, Multi-AZ        | $70         |
| ElastiCache Redis     | cache.t4g.small, 1.5GB              | $50         |
| ECS Fargate (Meili)   | 1 task, 1 vCPU, 2GB + 50GB EBS     | $45         |
| S3                    | 100GB + CDN                          | $8          |
| ALB                   | 1 ALB + higher LCU                  | $30         |
| CloudFront            | 200GB transfer                       | $20         |
| Route 53              | 1 hosted zone + health checks        | $3          |
| ECR                   | 10GB images                          | $2          |
| CloudWatch            | Enhanced monitoring + alarms         | $25         |
| Secrets Manager       | 10 secrets                           | $5          |
| WAF                   | Basic web ACL                        | $10         |
| Data Transfer          | ~200GB outbound                     | $18         |
| **Total**             |                                      | **~$436/mo**|

#### Tier 3: Production Scale (10K-100K users, ~$1,200-1,800/mo)

| Service               | Spec                                 | Monthly Cost |
|-----------------------|--------------------------------------|-------------|
| ECS Fargate (Backend) | 3-5 tasks (auto-scaling), 2vCPU, 4GB| $350        |
| ECS Fargate (Admin)   | 2 tasks, 1 vCPU, 2GB RAM            | $120        |
| RDS PostgreSQL        | db.r6g.large, 200GB, Multi-AZ, Read replica | $350 |
| ElastiCache Redis     | cache.r6g.large, 13GB, cluster      | $200        |
| ECS Fargate (Meili)   | 1 task, 2 vCPU, 4GB + 100GB EBS    | $80         |
| S3                    | 500GB + lifecycle policies           | $15         |
| ALB                   | 1 ALB + high LCU                    | $50         |
| CloudFront            | 1TB transfer                         | $85         |
| Route 53              | Health checks + failover             | $5          |
| CloudWatch            | Full observability suite             | $50         |
| WAF + Shield          | Advanced protection                  | $30         |
| Data Transfer          | ~1TB outbound                       | $90         |
| **Total**             |                                      | **~$1,425/mo**|

---

## 4. GCP Deployment

### 4.1 Architecture (Cloud Run)

```
Cloud DNS → Cloud CDN → Cloud Load Balancing
                          ├── Cloud Run (Go Backend, min 1 / max 10)
                          └── Cloud Run (NextJS Admin, min 0 / max 3)

Data Layer:
  ├── Cloud SQL PostgreSQL 16 (HA)
  ├── Memorystore Redis
  ├── Cloud Storage (replacing MinIO)
  └── Compute Engine e2-small (Meilisearch + persistent disk)
```

### 4.2 Cost Breakdown — GCP

#### Tier 1: Dev/Staging (~$120-170/mo)

| Service               | Spec                                 | Monthly Cost |
|-----------------------|--------------------------------------|-------------|
| Cloud Run (Backend)   | 1 vCPU, 512MB, min 1 instance       | $15         |
| Cloud Run (Admin)     | 1 vCPU, 256MB, min 0 (scale to zero)| $5          |
| Cloud SQL PostgreSQL  | db-f1-micro, 10GB SSD, Single zone  | $10         |
| Memorystore Redis     | Basic, 1GB                           | $35         |
| Compute Engine (Meili)| e2-micro, 10GB SSD PD               | $8          |
| Cloud Storage         | 10GB Standard                        | $1          |
| Cloud Load Balancing  | 1 forwarding rule + data             | $20         |
| Cloud CDN             | 50GB egress                          | $4          |
| Cloud DNS             | 1 zone                               | $1          |
| Artifact Registry     | 5GB                                  | $1          |
| Cloud Monitoring      | Basic (free tier covers most)        | $0          |
| Secret Manager        | 5 secrets + access                   | $1          |
| Network Egress        | ~50GB                                | $6          |
| **Total**             |                                      | **~$107/mo**|

#### Tier 2: Production Small (1K-10K users, ~$350-500/mo)

| Service               | Spec                                 | Monthly Cost |
|-----------------------|--------------------------------------|-------------|
| Cloud Run (Backend)   | 2 vCPU, 2GB, min 2 / max 5          | $90         |
| Cloud Run (Admin)     | 1 vCPU, 1GB, min 1 / max 2          | $30         |
| Cloud SQL PostgreSQL  | db-custom-2-8192, 50GB SSD, HA      | $130        |
| Memorystore Redis     | Basic, 2GB                           | $70         |
| Compute Engine (Meili)| e2-small, 50GB SSD PD               | $18         |
| Cloud Storage         | 100GB Standard                       | $3          |
| Cloud Load Balancing  | 1 forwarding rule + data             | $25         |
| Cloud CDN             | 200GB egress                         | $15         |
| Cloud DNS             | 1 zone + queries                     | $1          |
| Artifact Registry     | 10GB                                 | $2          |
| Cloud Monitoring      | Custom metrics + uptime checks       | $15         |
| Cloud Armor           | Basic WAF policy                     | $10         |
| Network Egress        | ~200GB                               | $24         |
| **Total**             |                                      | **~$433/mo**|

#### Tier 3: Production Scale (10K-100K users, ~$1,000-1,500/mo)

| Service               | Spec                                 | Monthly Cost |
|-----------------------|--------------------------------------|-------------|
| Cloud Run (Backend)   | 4 vCPU, 4GB, min 3 / max 15         | $250        |
| Cloud Run (Admin)     | 2 vCPU, 2GB, min 2 / max 5          | $90         |
| Cloud SQL PostgreSQL  | db-custom-4-16384, 200GB SSD, HA + read replica | $380 |
| Memorystore Redis     | Standard (HA), 5GB                   | $175        |
| Compute Engine (Meili)| e2-medium, 100GB SSD PD             | $35         |
| Cloud Storage         | 500GB Standard                       | $10         |
| Cloud Load Balancing  | 1 forwarding rule + high traffic     | $40         |
| Cloud CDN             | 1TB egress                           | $85         |
| Cloud Armor           | Managed WAF rules                    | $20         |
| Cloud Monitoring      | Full suite                           | $30         |
| Network Egress        | ~1TB                                 | $85         |
| **Total**             |                                      | **~$1,200/mo**|

---

## 5. Azure Deployment

### 5.1 Architecture (Container Apps)

```
Azure DNS → Azure Front Door (CDN + WAF)
              ├── Container Apps (Go Backend, min 1 / max 10)
              └── Container Apps (NextJS Admin, min 0 / max 3)

Data Layer:
  ├── Azure Database for PostgreSQL Flexible Server
  ├── Azure Cache for Redis
  ├── Azure Blob Storage (replacing MinIO)
  └── Container Apps (Meilisearch + Azure Files)
```

### 5.2 Cost Breakdown — Azure

#### Tier 1: Dev/Staging (~$150-200/mo)

| Service                      | Spec                              | Monthly Cost |
|------------------------------|-----------------------------------|-------------|
| Container Apps (Backend)     | 0.5 vCPU, 1GB, 1 replica         | $20         |
| Container Apps (Admin)       | 0.25 vCPU, 0.5GB, 1 replica      | $10         |
| PostgreSQL Flexible          | Burstable B1ms, 32GB, Single zone | $18         |
| Azure Cache for Redis        | Basic C0, 250MB                   | $17         |
| Container Apps (Meili)       | 0.5 vCPU, 1GB + 20GB Azure Files | $22         |
| Blob Storage                 | 10GB Hot tier                     | $2          |
| Azure Front Door             | Standard tier + 50GB transfer     | $25         |
| Azure DNS                    | 1 zone                            | $1          |
| ACR (Container Registry)     | Basic tier                         | $5          |
| Azure Monitor                | Basic logs (5GB/mo free)          | $0          |
| Key Vault                    | 5 secrets                         | $1          |
| Data Transfer                | ~50GB outbound                    | $5          |
| **Total**                    |                                   | **~$126/mo**|

#### Tier 2: Production Small (1K-10K users, ~$400-550/mo)

| Service                      | Spec                              | Monthly Cost |
|------------------------------|-----------------------------------|-------------|
| Container Apps (Backend)     | 1 vCPU, 2GB, 2 replicas          | $120        |
| Container Apps (Admin)       | 0.5 vCPU, 1GB, 1 replica         | $35         |
| PostgreSQL Flexible          | GP D2s_v3, 64GB, Zone-redundant  | $130        |
| Azure Cache for Redis        | Standard C1, 1GB                  | $45         |
| Container Apps (Meili)       | 1 vCPU, 2GB + 50GB Azure Files   | $40         |
| Blob Storage                 | 100GB Hot tier                    | $5          |
| Azure Front Door             | Standard + 200GB                  | $35         |
| Azure DNS                    | 1 zone + queries                  | $1          |
| ACR                          | Standard tier                      | $20         |
| Azure Monitor                | Log Analytics 10GB               | $25         |
| WAF on Front Door            | Basic policy                      | $15         |
| Data Transfer                | ~200GB outbound                   | $17         |
| **Total**                    |                                   | **~$488/mo**|

#### Tier 3: Production Scale (10K-100K users, ~$1,300-1,900/mo)

| Service                      | Spec                              | Monthly Cost |
|------------------------------|-----------------------------------|-------------|
| Container Apps (Backend)     | 2 vCPU, 4GB, 3-5 replicas        | $350        |
| Container Apps (Admin)       | 1 vCPU, 2GB, 2 replicas          | $120        |
| PostgreSQL Flexible          | GP D4s_v3, 256GB, Zone-redundant + read replica | $400 |
| Azure Cache for Redis        | Standard C2, 6GB                  | $140        |
| Container Apps (Meili)       | 2 vCPU, 4GB + 100GB Azure Files  | $75         |
| Blob Storage                 | 500GB Hot tier + CDN              | $15         |
| Azure Front Door             | Premium + 1TB + WAF               | $100        |
| ACR                          | Standard tier                      | $20         |
| Azure Monitor                | Full suite + alerts               | $50         |
| Data Transfer                | ~1TB outbound                     | $87         |
| **Total**                    |                                   | **~$1,357/mo**|

---

## 6. Cost Comparison Summary

### Monthly Cost by Tier

| Tier                        | AWS          | GCP          | Azure        |
|-----------------------------|-------------|-------------|-------------|
| **Dev/Staging**             | ~$123/mo    | ~$107/mo    | ~$126/mo    |
| **Production Small** (1K-10K) | ~$436/mo | ~$433/mo    | ~$488/mo    |
| **Production Scale** (10K-100K) | ~$1,425/mo | ~$1,200/mo | ~$1,357/mo |

### Annual Cost

| Tier                        | AWS          | GCP          | Azure        |
|-----------------------------|-------------|-------------|-------------|
| **Dev/Staging**             | ~$1,476/yr  | ~$1,284/yr  | ~$1,512/yr  |
| **Production Small**        | ~$5,232/yr  | ~$5,196/yr  | ~$5,856/yr  |
| **Production Scale**        | ~$17,100/yr | ~$14,400/yr | ~$16,284/yr |

### With Committed Use Discounts (1-year)

| Tier                        | AWS (Savings Plan) | GCP (CUD)     | Azure (Reserved) |
|-----------------------------|-------------------|---------------|-----------------|
| **Production Small**        | ~$350/mo (-20%)   | ~$345/mo (-20%) | ~$390/mo (-20%) |
| **Production Scale**        | ~$1,070/mo (-25%) | ~$900/mo (-25%) | ~$1,020/mo (-25%) |

---

## 7. Recommended Approach

### Winner by Category

| Criteria                | Winner    | Reason                                                    |
|------------------------|-----------|-----------------------------------------------------------|
| **Lowest Cost**        | **GCP**   | Cloud Run scale-to-zero, sustained use discounts auto-applied |
| **Easiest Setup**      | **GCP**   | Cloud Run = zero infra ops; direct Docker deploy          |
| **Best for India**     | **AWS**   | Mumbai (ap-south-1) has most services + lowest latency    |
| **Enterprise/Compliance** | **Azure** | Best for orgs already on Microsoft stack                |
| **Auto-scaling**       | **GCP**   | Cloud Run scales to zero = pay nothing when idle          |
| **Database (PostGIS)** | **AWS**   | RDS has best PostGIS support out of the box               |
| **Managed Services**   | **Tie**   | All three offer equivalent managed PostgreSQL + Redis     |

### Recommendation for This Project: **GCP (Cloud Run)**

**Why GCP Cloud Run is the best fit:**

1. **Scale-to-zero** — Admin panel & low-traffic periods cost $0 compute
2. **Simplest deployment** — Push Docker image → deploy. No cluster management
3. **Built-in Firebase** — Already using Firebase FCM; no cross-cloud auth needed
4. **Best price/performance** — Sustained use discounts auto-applied (no commitment)
5. **Cloud Run + Cloud SQL auth** — Sidecar proxy connects securely without VPN setup
6. **India region** — `asia-south1` (Mumbai) available with all services

**If targeting Indian market specifically:** Consider **AWS** for its more mature Mumbai region (ap-south-1) with the widest service availability and lowest latency infrastructure in India.

---

## Appendix A: Deployment Steps (GCP Cloud Run — Recommended)

### Step 1: Initial Setup
```bash
# Set project
gcloud config set project YOUR_PROJECT_ID
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  redis.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com

# Create Artifact Registry repo
gcloud artifacts repositories create marketplace \
  --repository-format=docker \
  --location=asia-south1
```

### Step 2: Database
```bash
# Cloud SQL PostgreSQL with PostGIS
gcloud sql instances create marketplace-db \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region=asia-south1 \
  --storage-size=10GB \
  --database-flags=cloudsql.enable_pgaudit=on

# Enable PostGIS
gcloud sql connect marketplace-db --user=postgres
# => CREATE EXTENSION postgis;
```

### Step 3: Redis
```bash
gcloud redis instances create marketplace-redis \
  --size=1 \
  --region=asia-south1 \
  --redis-version=redis_7_0
```

### Step 4: Build & Deploy Backend
```bash
# Build
docker build -t asia-south1-docker.pkg.dev/PROJECT/marketplace/backend:latest ./backend
docker push asia-south1-docker.pkg.dev/PROJECT/marketplace/backend:latest

# Deploy
gcloud run deploy marketplace-backend \
  --image=asia-south1-docker.pkg.dev/PROJECT/marketplace/backend:latest \
  --region=asia-south1 \
  --platform=managed \
  --min-instances=1 \
  --max-instances=10 \
  --memory=2Gi \
  --cpu=2 \
  --port=8080 \
  --add-cloudsql-instances=PROJECT:asia-south1:marketplace-db \
  --set-secrets=DB_PASSWORD=db-password:latest,JWT_SECRET=jwt-secret:latest
```

### Step 5: Deploy Admin Panel
```bash
gcloud run deploy marketplace-admin \
  --image=asia-south1-docker.pkg.dev/PROJECT/marketplace/admin:latest \
  --region=asia-south1 \
  --min-instances=0 \
  --max-instances=3 \
  --memory=1Gi \
  --cpu=1 \
  --port=3000
```

### Step 6: Meilisearch (Compute Engine)
```bash
gcloud compute instances create marketplace-meili \
  --zone=asia-south1-a \
  --machine-type=e2-small \
  --boot-disk-size=50GB \
  --metadata=startup-script='#!/bin/bash
    docker run -d --restart always \
      -p 7700:7700 \
      -v /mnt/data:/meili_data \
      -e MEILI_MASTER_KEY=$MEILI_KEY \
      -e MEILI_ENV=production \
      getmeili/meilisearch:v1.6'
```

---

## Appendix B: Deployment Steps (AWS ECS Fargate)

### Step 1: VPC & Networking
```bash
# Create VPC with public/private subnets
aws cloudformation deploy \
  --template-file deploy/aws/vpc.yaml \
  --stack-name marketplace-vpc

# ECR Repository
aws ecr create-repository --repository-name marketplace/backend
aws ecr create-repository --repository-name marketplace/admin
```

### Step 2: Database
```bash
aws rds create-db-instance \
  --db-instance-identifier marketplace-db \
  --db-instance-class db.t4g.small \
  --engine postgres \
  --engine-version 16.4 \
  --allocated-storage 50 \
  --master-username marketplace \
  --master-user-password "$DB_PASSWORD" \
  --multi-az \
  --region ap-south-1
```

### Step 3: Redis
```bash
aws elasticache create-cache-cluster \
  --cache-cluster-id marketplace-redis \
  --cache-node-type cache.t4g.small \
  --engine redis \
  --engine-version 7.1 \
  --num-cache-nodes 1
```

### Step 4: ECS Fargate Task Definitions & Services
```bash
# Register task definitions (from JSON files)
aws ecs register-task-definition --cli-input-json file://deploy/aws/backend-task.json
aws ecs register-task-definition --cli-input-json file://deploy/aws/admin-task.json

# Create ECS cluster
aws ecs create-cluster --cluster-name marketplace

# Create services
aws ecs create-service \
  --cluster marketplace \
  --service-name backend \
  --task-definition marketplace-backend \
  --desired-count 2 \
  --launch-type FARGATE
```

---

## Appendix C: Deployment Steps (Azure Container Apps)

### Step 1: Resource Group & Environment
```bash
az group create --name marketplace-rg --location centralindia

az containerapp env create \
  --name marketplace-env \
  --resource-group marketplace-rg \
  --location centralindia
```

### Step 2: Database
```bash
az postgres flexible-server create \
  --resource-group marketplace-rg \
  --name marketplace-db \
  --location centralindia \
  --sku-name Standard_B1ms \
  --storage-size 32 \
  --version 16 \
  --admin-user marketplace \
  --admin-password "$DB_PASSWORD"
```

### Step 3: Redis
```bash
az redis create \
  --resource-group marketplace-rg \
  --name marketplace-redis \
  --location centralindia \
  --sku Basic \
  --vm-size C0
```

### Step 4: Deploy Container Apps
```bash
az containerapp create \
  --name marketplace-backend \
  --resource-group marketplace-rg \
  --environment marketplace-env \
  --image marketplace.azurecr.io/backend:latest \
  --target-port 8080 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 1.0 \
  --memory 2.0Gi
```

---

## Appendix D: CI/CD Pipeline (GitHub Actions — All Clouds)

```yaml
# .github/workflows/deploy.yml
name: Build & Deploy
on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t marketplace-backend:${{ github.sha }} ./backend

      - name: Run tests
        run: docker run marketplace-backend:${{ github.sha }} go test ./...

      # For GCP:
      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      - run: |
          gcloud auth configure-docker asia-south1-docker.pkg.dev
          docker tag marketplace-backend:${{ github.sha }} asia-south1-docker.pkg.dev/$PROJECT/marketplace/backend:${{ github.sha }}
          docker push asia-south1-docker.pkg.dev/$PROJECT/marketplace/backend:${{ github.sha }}
          gcloud run deploy marketplace-backend \
            --image=asia-south1-docker.pkg.dev/$PROJECT/marketplace/backend:${{ github.sha }} \
            --region=asia-south1

  deploy-admin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t marketplace-admin:${{ github.sha }} ./admin
      # Similar push & deploy steps...
```

---

## Appendix E: Monitoring & Alerting Essentials

| Alert                         | Threshold              | Action                    |
|-------------------------------|------------------------|---------------------------|
| API Error Rate (5xx)          | > 1% for 5 min         | Page on-call              |
| API Latency (p95)             | > 500ms for 5 min      | Notify team               |
| Database CPU                  | > 80% for 10 min       | Scale up / optimize       |
| Database Connections          | > 80% of max           | Check connection pooling  |
| Redis Memory                  | > 80% capacity         | Scale up / eviction check |
| Disk Usage (Meili)            | > 80%                  | Expand volume             |
| Container Restarts            | > 3 in 10 min          | Investigate crash         |
| SSL Certificate Expiry        | < 14 days              | Auto-renew / notify       |
| Failed Health Checks          | > 3 consecutive        | Auto-restart + alert      |

---

*Document generated for the Marketplace Platform. All costs are estimates based on March 2026 public pricing and may vary based on actual usage patterns, region, and negotiated discounts.*
