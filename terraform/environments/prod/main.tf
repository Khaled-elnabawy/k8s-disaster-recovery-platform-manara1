terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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

  project_name     = "k8s-dr-platform"
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_nodes_role_arn
  subnet_ids       = module.vpc.private_subnet_ids
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

data "tls_certificate" "eks_oidc" {
  url = module.eks.oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = module.eks.oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
}

locals {
  eks_oidc_issuer_host = trimprefix(module.eks.oidc_issuer_url, "https://")
}

resource "aws_iam_role" "ebs_csi" {
  name = "k8s-dr-platform-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.eks_oidc_issuer_host}:aud" = "sts.amazonaws.com"
          "${local.eks_oidc_issuer_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [aws_iam_role_policy_attachment.ebs_csi]
}

resource "aws_iam_role" "velero" {
  name = "k8s-dr-platform-velero-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.eks_oidc_issuer_host}:aud" = "sts.amazonaws.com"
          "${local.eks_oidc_issuer_host}:sub" = "system:serviceaccount:velero:velero"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "velero" {
  name        = "k8s-dr-platform-velero-policy"
  description = "S3 backup access and EBS snapshot operations for Velero"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BackupBucketMetadata"
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation", "s3:ListBucket"]
        Resource = module.s3.bucket_arn
      },
      {
        Sid    = "BackupObjectOperations"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject"
        ]
        Resource = "${module.s3.bucket_arn}/*"
      },
      {
        Sid    = "EbsSnapshotOperations"
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateVolume",
          "ec2:CreateTags",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "velero" {
  role       = aws_iam_role.velero.name
  policy_arn = aws_iam_policy.velero.arn
}
