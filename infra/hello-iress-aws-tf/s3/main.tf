provider "aws" {
  region  = "${var.aws_region}"
}

terraform {
  backend "s3" {
    bucket         = "iress-devops-tf"
    key            = "remoteStateConfig/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}

resource "aws_s3_bucket" "iressTerraformState" {
  bucket = "iress-devops-tf"
}

resource "aws_s3_bucket_versioning" "iressTerraformState" {
  bucket = aws_s3_bucket.iressTerraformState.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "iressTerraformState" {
  bucket = aws_s3_bucket.iressTerraformState.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block-public-access" {
  bucket = aws_s3_bucket.iressTerraformState.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "set-bucket-policy" {
  bucket = aws_s3_bucket.iressTerraformState.id
  policy = jsonencode({
        "Version": "2012-10-17",
        "Id": "SSLPolicy",
        "Statement": [
            {
                "Sid": "DenyInsecureConnections",
                "Effect": "Deny",
                "Principal": "*",
                "Action": "s3:*",
                "Resource": [
                    "${aws_s3_bucket.iressTerraformState.arn}",
                    "${aws_s3_bucket.iressTerraformState.arn}/*"
                    ],
                "Condition": {
                    "Bool": {
                        "aws:SecureTransport": "false"
                        }
                    }
                }
            ]
        })

}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.iressTerraformState.arn
  description = "The ARN of the S3 bucket"
}
