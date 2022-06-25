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
    key            = "resource/alb/terraform.tfstate"
    region         = "ap-southeast-1"
    role_arn       = "arn:aws:iam::AWS_ACCOUNT_ID:role/iress-tf-role"
  }
}


##################################################################
# VPC tfState
##################################################################
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket      = "iress-devops-tf"
    key         = "resource/vpc/terraform.tfstate"
    region         = "ap-southeast-1"
    role_arn       = "arn:aws:iam::AWS_ACCOUNT_ID:role/iress-tf-role"
  }
}


##################################################################
# Security Group
##################################################################
module "iress_sg_alb" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 4"

  name        = "iress-alb-sg"
  description = "Allow trafic from Internet to ports 80, 443 for ALB"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.vpc_id}" # module.vpc.vpc_id

  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_rules            = ["https-443-tcp", "http-80-tcp"]

  egress_cidr_blocks       = ["0.0.0.0/0"]
  egress_rules             = ["all-all"]

  #ingress_with_cidr_blocks = [
  #  {
  #    from_port   = 80
  #    to_port     = 80
  #    protocol    = "tcp"
  #    description = "User-service ports"
  #    cidr_blocks = "0.0.0.0/0"
  #  }
  #]
  
}


##################################################################
# ACM and R53
##################################################################

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name = local.domain_name # trimsuffix(data.aws_route53_zone.this.name, ".") # Terraform >= 0.12.17
  zone_id     = local.zone_id

  subject_alternative_names = [
    "*.${local.domain_name}"
  ]

  wait_for_validation = true
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = "${local.domain_name}"

  for_each = var.record_names
  records = [
    {
      name      = each.value
      #ame      = "test"
      type      = "A"
      alias     = {
        evaluate_target_health = true
        name                   = module.alb.lb_dns_name
        zone_id                = module.alb.lb_zone_id
        }
    }
  ]

}


##################################################################
# Application Load Balancer
##################################################################
module "iress_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "iress-public-alb"

  load_balancer_type = "application"

  vpc_id             = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  #subnets            = ["subnet-abcde012", "subnet-bcde012a"]
  #security_groups    = ["sg-edcd9784", "sg-edcd9785"]
  subnets            = ["${data.terraform_remote_state.vpc.outputs.public_subnets}"[0], "${data.terraform_remote_state.vpc.outputs.public_subnets}"[1]]
  security_groups    = [module.iress_sg_alb.security_group_id]

  #access_logs = {
  #  bucket = "my-alb-logs"
  #}

  target_groups = [
    {
      #ame_prefix      = "pref-"
      name             = "hello-tg-30100"
      backend_protocol = "HTTP"
      backend_port     = 30100
      target_type      = "instance"
      health_check     = {
        enabled             = true
        path                = "/hello/health"
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    },
    {
      name             = "welcome-tg-30101"
      backend_protocol = "HTTP"
      backend_port     = 30101
      target_type      = "instance"
      health_check     = {
        enabled             = true
        path                = "/welcome/health"
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      action_type        = "redirect"
      redirect           = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      action_type        = "fixed-response"
      fixed_response     = {
        status_code  = "503"
        content_type = "text/plain"
      }
    }
  ]

  https_listener_rules = [
    {
      https_listener_index = 0
      priority             = 1

      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]

      conditions = [{
        host_headers = ["hello.iress.cloud"]
      }]
    },
    {
      https_listener_index = 0
      priority             = 2

      actions = [
        {
          type               = "forward"
          target_group_index = 1
        }
      ]

      conditions = [{
        host_headers = ["welcome.iress.cloud"]
      }]
    }
  ]
}
