resource "random_id" "cache_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "runner_cache" {
  bucket        = "${local.name}-cache-${random_id.cache_suffix.hex}"
  force_destroy = false
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "runner_cache" {
  bucket = aws_s3_bucket.runner_cache.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "runner_cache" {
  bucket = aws_s3_bucket.runner_cache.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "runner_cache" {
  bucket = aws_s3_bucket.runner_cache.id

  rule {
    id     = "expire-cache"
    status = "Enabled"

    filter {}

    expiration {
      days = var.cache_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
