
#########################################
# IAM policy
#########################################
module "terraform_inPolicy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "iress-tf-inPolicy"
  path        = "/"
  description = ""

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::iress-devops-tf"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::iress-devops-tf/*"
        }
    ]
}
EOF

  tags = {
    Terraform       = "true"
    Environment     = "npr"
    Project         = "iress"
  }
}

################################################################################
# Assumable Roles
################################################################################
module "terraform_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_arns = [
    "arn:aws:iam::AWS_ACCOUNT_ID:role/iress-npr"
  ]

  #trusted_role_services = [
  #  "lambda.amazonaws.com"
  #]

  create_role = true
  #create_instance_profile = true

  role_name         = "iress-tf-role"
  role_requires_mfa = false

  custom_role_policy_arns = [
    module.terraform_inPolicy.arn
  ]

  tags = {
    Name            = "iress-tf-role"
    Terraform       = "true"
    Project         = "iress"
  }

}
