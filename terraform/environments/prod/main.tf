terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = "k8s-dr-platform"
}

module "iam" {
  source = "../../modules/iam"

  project_name = "k8s-dr-platform"
}

module "eks" {
  source = "../../modules/eks"

  project_name      = "k8s-dr-platform"
  cluster_role_arn  = module.iam.eks_cluster_role_arn
  node_role_arn     = module.iam.eks_nodes_role_arn
  subnet_ids        = module.vpc.private_subnet_ids
}
module "s3" {
  source = "../../modules/s3"

  project_name = "k8s-dr-platform"
}
resource "aws_ecr_repository" "demo_app" {
  name                 = "k8s-dr-platform-demo-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
