module "app" {
  source = "./modules/app"
  
  name                                         = var.name
  environment                                  = var.environment
  region                                       = var.region
  vpc_network                                  = var.vpc_network
  domain                                       = var.domain
  db_instance_class                            = var.db_instance_class
  db_name                                      = var.db_name
  db_username                                  = var.db_username
  db_password                                  = var.db_password
  asg_min_size                                 = var.asg_min_size
  asg_max_size                                 = var.asg_max_size
  asg_desired_capacity                         = var.asg_desired_capacity
  asg_on_demand_base_capacity                  = var.asg_on_demand_base_capacity
  asg_on_demand_percentage_above_base_capacity = var.asg_on_demand_percentage_above_base_capacity
  docreader_instance_type                      = var.docreader_instance_type
  worker_count                                 = var.worker_count
}
