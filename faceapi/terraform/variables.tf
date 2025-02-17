variable "name" {
  description = "Application name to deploy"
  type        = string
  default     = "faceapi"
}

variable "environment" {
  description = "Environment to deploy"
  type        = string
  default     = "dev"
}

variable "faceapi_engine" {
  description = "FaceAPI version: CPU/GPU"
  default     = "cpu"
  type        = string
}

variable "region" {
  description = "AWS Region to deploy"
  default     = "eu-central-1"
  type        = string
}

variable "vpc_network" {
  description = "VPC network octet"
  default     = "10.10"
  type        = string
}

variable "domain" {
  description = "Certificate's domain"
  default     = "*.example.com"
  type        = string
}

variable "db_instance_class" {
  description = "DB Instance Class to deploy"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "RDS name to deploy"
  type        = string
  default     = "faceapi"
}

variable "db_username" {
  description = "DB Instance username to deploy"
  type        = string
}

variable "db_password" {
  description = "DB Instance password to deploy"
  type        = string
}

variable "asg_min_size" {
  description = "ASG GPU Minimum size of the Auto Scaling Group"
  default     = 1
  type        = number
}

variable "asg_max_size" {
  description = "ASG GPU Maximum size of the Auto Scaling Group"
  default     = 4
  type        = number
}

variable "asg_desired_capacity" {
  description = "ASG GPU Number of Amazon EC2 instances that should be running in the group"
  default     = 1
  type        = number
}

variable "asg_on_demand_base_capacity" {
  description = "ASG GPU Absolute minimum amount of desired capacity that must be fulfilled by on-demand instances"
  default     = 0
  type        = number
}

variable "asg_on_demand_percentage_above_base_capacity" {
  description = "ASG GPU Percentage split between on-demand and Spot instances above the base on-demand capacity"
  default     = 0
  type        = number
}

variable "faceapi_instance_type" {
  description = "Faceapi GPU worker Instance type to deploy"
  type        = string
  default     = "c6a.large"
}

variable "worker_count" {
  description = "Faceapi GPU workers count"
  default     = 1
  type        = number
}

