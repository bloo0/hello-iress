provider "aws" {
  region  = "${var.aws_region}"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}

terraform {
  backend "s3" {
    bucket         = "iress-devops-tf"
    key            = "resource/ecr/terraform.tfstate"
    region         = "ap-southeast-1"
    role_arn       = "arn:aws:iam::AWS_ACCOUNT_ID:role/iress-tf-role"
  }
}


##################################################################
# ECR
##################################################################
resource "aws_ecr_repository" "hello" {
  name                 = "hello"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
      Terraform       = "true"
      Environment     = "${terraform.workspace}"
  }
}

resource "aws_ecr_repository" "welcome" {
  name                 = "welcome"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
      Terraform       = "true"
      Environment     = "${terraform.workspace}"
  }
}
