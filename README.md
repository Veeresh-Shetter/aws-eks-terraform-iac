# Enterprise AWS EKS & Serverless FinOps Infrastructure (Terraform IaC)

Production-grade, modular Infrastructure as Code (IaC) repository that provisions a secure Multi-AZ AWS VPC, private Amazon EKS Kubernetes cluster, and an event-driven AWS Lambda FinOps auto-scaler to host the [`gitops-app`](https://github.com) microservice.

## Architecture Overview

```mermaid
graph TD
    subgraph AWS["AWS Cloud (ap-south-1 / Mumbai)"]
        subgraph State["Remote State Backend"]
            S3["S3 Bucket (AES-256 + Versioning)"]
            DDB["DynamoDB State Lock Table"]
        end

        subgraph VPC["Custom VPC (10.0.0.0/16)"]
            IGW["Internet Gateway"]
            subgraph Public["Public Subnets (10.0.1.0/24, 10.0.2.0/24)"]
                NAT["NAT Gateway"]
            end
            subgraph Private["Private Subnets (10.0.11.0/24, 10.0.12.0/24)"]
                EKS["Amazon EKS Managed Node Group (t3.small)"]
            end
        end

        subgraph FinOps["Serverless Cost Automation"]
            EB["EventBridge Nightly Cron (11:30 PM IST)"] --> Lambda["AWS Lambda (Python 3.12)"]
            Lambda -->|Scale Nodes to 0| EKS
        end
    end
```

## Key Engineering Highlights
- **Modular Terraform Design:** Decoupled reusable modules (`modules/vpc`, `modules/eks`, `modules/lambda-finops`) wired into `environments/dev`.
- **Remote State & Concurrency Locking:** Encrypted S3 backend with DynamoDB state locking (`bootstrap/`).
- **Zero-Trust Network Isolation:** Worker nodes run exclusively inside private subnets across 2 Availability Zones (`ap-south-1a`, `ap-south-1b`) with outbound-only internet via NAT Gateway.
- **Serverless FinOps Automation:** EventBridge triggers a Python AWS Lambda function nightly to scale EKS worker nodes to zero, eliminating idle compute spend.
- **Shift-Left IaC Security:** GitHub Actions CI enforces `terraform fmt`, `terraform validate`, and Checkov static security analysis on every push.

## Live Deployment Verification

### 1. Amazon EKS Cluster (`ap-south-1`)
![AWS EKS Cluster](assets/aws-eks-console.png)

### 2. Private EKS Worker Node & Running `gitops-app` Microservice Pods
![EKS Nodes and Pods](assets/eks-pods-running.png)

### 3. Serverless AWS Lambda & EventBridge FinOps Auto-Scaler
![AWS Lambda FinOps](assets/aws-lambda-finops.png)

## Quick Start
```bash
# 1. Bootstrap remote state (S3 + DynamoDB)
cd bootstrap && terraform init && terraform apply

# 2. Provision VPC, EKS Cluster, and Lambda FinOps
cd ../environments/dev && terraform init && terraform apply

# 3. Connect kubectl to EKS
aws eks update-kubeconfig --region ap-south-1 --name veeresh-gitops-eks
```
