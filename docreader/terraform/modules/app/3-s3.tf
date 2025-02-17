resource "random_uuid" "default" {
}


module "s3_docreader_bucket_results" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket = "docreader-results-${random_uuid.default.result}"

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

module "s3_docreader_bucket_session_api" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket = "docreader-session-api-${random_uuid.default.result}"

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
