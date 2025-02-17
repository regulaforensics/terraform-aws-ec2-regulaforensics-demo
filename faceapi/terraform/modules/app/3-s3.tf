resource "random_uuid" "default" {
}

module "s3_detect_match_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${local.name}-${random_uuid.default.result}-detect-match"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  force_destroy = true

  versioning = {
    enabled = true
  }

  tags = local.tags
}

module "s3_liveness_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${local.name}-${random_uuid.default.result}-liveness"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  force_destroy = true

  versioning = {
    enabled = true
  }

  tags = local.tags
}


