## S3 bucket access policy
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid       = "S3${local.name}${local.environment}0"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    sid = "S3${local.name}${local.environment}1"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.s3_liveness_bucket.s3_bucket_arn}",
      "${module.s3_detect_match_bucket.s3_bucket_arn}"
    ]
  }

  statement {
    sid = "S3${local.name}${local.environment}2"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.s3_liveness_bucket.s3_bucket_arn}/*",
      "${module.s3_detect_match_bucket.s3_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_policy" {
  name   = "${local.name}${local.environment}s3"
  path   = "/"
  policy = data.aws_iam_policy_document.s3_policy.json

  tags = local.tags
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  description      = "A service linked role for autoscaling"
  custom_suffix    = "${local.name}-${local.environment}-temp"

  # Sometimes good sleep is required to have some IAM resources created before they can be used
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

data "aws_ami" "faceapi" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${local.name}-${local.environment}-${var.faceapi_engine}-*"]
  }
}

data "template_file" "startup" {
  template = file("${path.module}/user-data/startup.tpl")

  vars = {
    AWS_REGION                  = var.region
    WORKER_COUNT                = var.worker_count
    DB_USERNAME                 = var.db_username
    DB_PASSD                    = var.db_password
    DB_HOST                     = module.rds.db_instance_address
    DB_NAME                     = var.db_name
    S3_BUCKET_DETECT_MATCH_NAME = module.s3_detect_match_bucket.s3_bucket_id
    S3_BUCKET_LIVENESS_NAME     = module.s3_liveness_bucket.s3_bucket_id
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.4"

  # Autoscaling group
  name = "${local.name}-${local.environment}"

  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  wait_for_capacity_timeout = 0
  default_instance_warmup   = 300
  default_cooldown          = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = module.vpc.private_subnets
  service_linked_role_arn   = aws_iam_service_linked_role.autoscaling.arn
  health_check_grace_period = 300

  initial_lifecycle_hooks = [
    {
      name                  = "ExampleStartupLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 120
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                  = "ExampleTerminationLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 180
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]
  termination_policies = ["OldestLaunchConfiguration"]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 60
      checkpoint_percentages = [35, 70, 100]
      min_healthy_percentage = 100
    }
    triggers = ["tag"]
  }

  # Launch template
  launch_template_name        = "${local.name}-${local.environment}-lt"
  launch_template_description = "${local.name} ${local.environment} Launch template"
  update_default_version      = true

  image_id           = data.aws_ami.faceapi.id
  instance_type      = var.faceapi_instance_type
  user_data          = base64encode(data.template_file.startup.rendered)
  capacity_rebalance = true

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-${local.environment}-asg"
  iam_role_path               = "/ec2/"
  iam_role_description        = "FaceAPI IAM role"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }

  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    S3BucketAccess               = aws_iam_policy.s3_policy.arn
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 32
  }

  security_groups = [module.vpc.default_security_group_id, module.security_group_face_ec2.security_group_id]

  target_group_arns = [for k, v in module.alb.target_groups : v.arn]

  scaling_policies = {
    avg-policy-greater-than = {
      estimated_instance_warmup = 300
      policy_type               = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 20
      }
    }
  }

  # Mixed instances
  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = var.asg_on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.asg_on_demand_percentage_above_base_capacity
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
  }

  tags = local.tags

  depends_on = [module.vpc.natgw_ids]
}

module "security_group_face_ec2" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name        = "${local.name}-${local.environment}-ec2"
  description = "EC2 security group"
  vpc_id      = module.vpc.vpc_id

  # Ingress
  ingress_with_cidr_blocks = [
    for key, value in module.vpc.private_subnets_cidr_blocks :
    {
      rule        = "ssh-tcp"
      cidr_blocks = value
    }
  ]

  # Egress
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.tags
}
