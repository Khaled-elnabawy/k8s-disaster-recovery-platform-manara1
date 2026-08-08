resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "velero_backups" {
  bucket = "${var.project_name}-velero-backups-${random_id.suffix.hex}"

  tags = {
    Name = "${var.project_name}-velero-backups"
  }
}

resource "aws_s3_bucket_versioning" "velero_backups_versioning" {
  bucket = aws_s3_bucket.velero_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero_backups_encryption" {
  bucket = aws_s3_bucket.velero_backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "velero_backups_block" {
  bucket                  = aws_s3_bucket.velero_backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
