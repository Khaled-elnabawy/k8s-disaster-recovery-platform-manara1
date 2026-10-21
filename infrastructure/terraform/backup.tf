resource "aws_backup_vault" "primary" {
  name = "${var.project_name}-primary-vault"

  tags = {
    Project = var.project_name
    Region  = var.primary_region
  }
}

resource "aws_backup_vault" "secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-secondary-vault"

  tags = {
    Project = var.project_name
    Region  = var.secondary_region
  }
}

resource "aws_iam_role" "backup" {
  name = "${var.project_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_plan" "daily_cross_region" {
  name = "${var.project_name}-daily-cross-region"

  rule {
    rule_name         = "daily-backup-and-copy"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 3 * * ? *)"
    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 35
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.secondary.arn

      lifecycle {
        delete_after = 35
      }
    }
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_backup_selection" "tagged_resources" {
  name         = "${var.project_name}-daily-tagged-resources"
  plan_id      = aws_backup_plan.daily_cross_region.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    "arn:aws:ec2:*:*:instance/*",
    "arn:aws:rds:*:*:cluster:*",
    "arn:aws:dynamodb:*:*:table/*",
    "arn:aws:s3:::*"
  ]

  condition {
    string_equals {
      key   = "aws:ResourceTag/Backup"
      value = "Daily"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.backup,
    aws_iam_role_policy_attachment.restore
  ]
}
