resource "aws_s3_bucket" "main" {
  bucket = "taskflow01-bucket"
}

resource "aws_s3_bucket_public_access_block" "pab" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "boc" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "vers" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "s3_oac" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.main.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "s3_oac" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.s3_oac.json
}
