terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    bucket         = "veeresh-eks-tfstate-765725004368"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "veeresh-eks-tfstate-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project     = "aws-eks-terraform-iac"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  project_name = "veeresh-gitops"
  cluster_name = "veeresh-gitops-eks"
}

module "vpc" {
  source       = "../../modules/vpc"
  project_name = local.project_name
  cluster_name = local.cluster_name
}

module "eks" {
  source             = "../../modules/eks"
  cluster_name       = local.cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "lambda_finops" {
  source         = "../../modules/lambda-finops"
  project_name   = local.project_name
  cluster_name   = module.eks.cluster_name
  nodegroup_name = module.eks.node_group_name
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "configure_kubectl_command" {
  value = "aws eks update-kubeconfig --region ap-south-1 --name ${module.eks.cluster_name}"
}
