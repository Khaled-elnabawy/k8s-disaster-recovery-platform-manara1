data "aws_caller_identity" "primary" {}

data "aws_caller_identity" "secondary" {
  provider = aws.secondary
}

resource "aws_s3_bucket" "primary_objects" {
  bucket = "${var.project_name}-primary-${data.aws_caller_identity.primary.account_id}-${var.bucket_suffix}"

  tags = {
    Project = var.project_name
    Backup  = "Daily"
    Region  = var.primary_region
  }
}

resource "aws_s3_bucket" "secondary_objects" {
  provider = aws.secondary
  bucket   = "${var.project_name}-replica-${data.aws_caller_identity.secondary.account_id}-${var.bucket_suffix}"

  tags = {
    Project = var.project_name
    Backup  = "Daily"
    Region  = var.secondary_region
  }
}

resource "aws_s3_bucket_public_access_block" "primary_objects" {
  bucket                  = aws_s3_bucket.primary_objects.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "secondary_objects" {
  provider                = aws.secondary
  bucket                  = aws_s3_bucket.secondary_objects.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "primary_objects" {
  bucket = aws_s3_bucket.primary_objects.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "secondary_objects" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary_objects.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary_objects" {
  bucket = aws_s3_bucket.primary_objects.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secondary_objects" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary_objects.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role" "s3_replication" {
  name = "${var.project_name}-s3-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_replication" {
  name = "${var.project_name}-s3-replication"
  role = aws_iam_role.s3_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.primary_objects.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.primary_objects.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.secondary_objects.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "primary_to_secondary" {
  bucket = aws_s3_bucket.primary_objects.id
  role   = aws_iam_role.s3_replication.arn

  rule {
    id     = "replicate-all-objects-to-secondary"
    status = "Enabled"

    filter {}

    destination {
      bucket        = aws_s3_bucket.secondary_objects.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary_objects,
    aws_s3_bucket_versioning.secondary_objects,
    aws_iam_role_policy.s3_replication
  ]
}

resource "aws_dynamodb_table" "global_app_data" {
  name         = "${var.project_name}-app-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  replica {
    region_name = var.secondary_region
  }

  tags = {
    Project = var.project_name
    Backup  = "Daily"
  }
}

resource "aws_db_subnet_group" "primary" {
  name       = "${var.project_name}-primary-db-subnets"
  subnet_ids = var.primary_private_subnet_ids

  tags = {
    Project = var.project_name
    Region  = var.primary_region
  }
}

resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "${var.project_name}-secondary-db-subnets"
  subnet_ids = var.secondary_private_subnet_ids

  tags = {
    Project = var.project_name
    Region  = var.secondary_region
  }
}

resource "aws_rds_global_cluster" "app" {
  global_cluster_identifier = "${var.project_name}-aurora-global"
  engine                    = "aurora-mysql"
  engine_version            = var.aurora_engine_version
  database_name             = var.database_name
  storage_encrypted         = true

  deletion_protection = false
}

resource "aws_rds_cluster" "primary" {
  cluster_identifier          = "${var.project_name}-aurora-primary"
  engine                      = aws_rds_global_cluster.app.engine
  engine_version              = aws_rds_global_cluster.app.engine_version
  global_cluster_identifier   = aws_rds_global_cluster.app.id
  database_name               = var.database_name
  master_username             = var.database_master_username
  manage_master_user_password = true

  db_subnet_group_name    = aws_db_subnet_group.primary.name
  vpc_security_group_ids  = [var.primary_database_security_group_id]
  backup_retention_period = 7
  storage_encrypted       = true
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = {
    Project = var.project_name
    Backup  = "Daily"
    Role    = "Primary"
  }
}

resource "aws_rds_cluster_instance" "primary" {
  identifier         = "${var.project_name}-aurora-primary-1"
  cluster_identifier = aws_rds_cluster.primary.id
  engine             = aws_rds_cluster.primary.engine
  engine_version     = aws_rds_cluster.primary.engine_version
  instance_class     = var.primary_database_instance_class

  tags = {
    Project = var.project_name
    Role    = "Primary"
  }
}

resource "aws_rds_cluster" "secondary" {
  provider                  = aws.secondary
  cluster_identifier        = "${var.project_name}-aurora-secondary"
  engine                    = aws_rds_global_cluster.app.engine
  engine_version            = aws_rds_global_cluster.app.engine_version
  global_cluster_identifier = aws_rds_global_cluster.app.id

  db_subnet_group_name   = aws_db_subnet_group.secondary.name
  vpc_security_group_ids = [var.secondary_database_security_group_id]
  storage_encrypted      = true
  skip_final_snapshot    = true
  deletion_protection    = false

  depends_on = [aws_rds_cluster_instance.primary]

  tags = {
    Project = var.project_name
    Backup  = "Daily"
    Role    = "Secondary"
  }
}

resource "aws_rds_cluster_instance" "secondary" {
  provider           = aws.secondary
  identifier         = "${var.project_name}-aurora-secondary-1"
  cluster_identifier = aws_rds_cluster.secondary.id
  engine             = aws_rds_cluster.secondary.engine
  engine_version     = aws_rds_cluster.secondary.engine_version
  instance_class     = var.secondary_database_instance_class

  tags = {
    Project = var.project_name
    Role    = "Secondary"
  }
}
