data "aws_acm_certificate" "certificate" {
  most_recent = true
  domain      = var.domain
  statuses    = ["ISSUED"]
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.7"

  name = "${local.name}-${local.environment}-alb"

  load_balancer_type         = "application"
  enable_deletion_protection = false

  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  security_groups            = [module.vpc.default_security_group_id]
  xff_header_processing_mode = "append"

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = data.aws_acm_certificate.certificate.arn

      forward = {
        target_group_key = "docreader"
      }
    }
  }

  target_groups = {
    docreader = {
      name_prefix          = "doc-"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 0
      health_check = {
        enabled             = true
        interval            = 20
        path                = "/api/ping"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 7
        protocol            = "HTTP"
        matcher             = "200-399"
      }

      create_attachment = false
    }
  }

  tags = local.tags
}
