module "db" {
  source     = "terraform-aws-modules/rds/aws"
  version    = "~> 6.5"
  identifier = "docreader${var.environment}"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "16.7"
  family               = "postgres16" # DB parameter group
  major_engine_version = "16"         # DB option group
  instance_class       = var.db_instance_class

  cloudwatch_log_group_retention_in_days = 365

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  manage_master_user_password = false
  db_name                     = var.db_name
  username                    = var.db_username
  password                    = var.db_password
  port                        = 5432

  allocated_storage     = 20
  max_allocated_storage = 100

  multi_az               = false
  db_subnet_group_name   = module.vpc.database_subnet_group
  publicly_accessible    = true
  vpc_security_group_ids = [module.vpc.default_security_group_id, module.security_group_rds.security_group_id]

  backup_retention_period = 14
  skip_final_snapshot     = true

  apply_immediately = true

  deletion_protection = false
  ca_cert_identifier  = "rds-ca-rsa2048-g1"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }

  depends_on = [
    module.vpc
  ]

  tags = local.tags

}

module "security_group_rds" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name        = "docreader-${local.environment}-rds"
  description = "PostgreSQL security group"
  vpc_id      = module.vpc.vpc_id

  # Ingress
  ingress_with_cidr_blocks = [
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.tags

}
