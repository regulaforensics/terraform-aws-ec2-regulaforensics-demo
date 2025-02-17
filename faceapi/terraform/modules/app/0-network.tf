module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = "${local.name}-${local.environment}-vpc"
  cidr = "${var.vpc_network}.0.0/16"

  azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets   = ["${var.vpc_network}.0.0/24", "${var.vpc_network}.1.0/24", "${var.vpc_network}.2.0/24"]
  private_subnets  = ["${var.vpc_network}.3.0/24", "${var.vpc_network}.4.0/24", "${var.vpc_network}.5.0/24"]
  database_subnets = ["${var.vpc_network}.7.0/24", "${var.vpc_network}.8.0/24", "${var.vpc_network}.9.0/24"]

  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  private_subnet_tags = {
    Name = "${local.name}-${local.environment}-private",
    Role = "private"
  }

  public_subnet_tags = {
    Name = "${local.name}-${local.environment}-public",
    Role = "public"
  }

  database_subnet_tags = {
    Name = "${local.name}-${local.environment}-database",
    Role = "database"
  }

  tags = local.tags

}
