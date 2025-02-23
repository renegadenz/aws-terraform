variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "terraform-poc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "A list of availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "A list of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = true
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "ecs-cluster"
}

variable "asg_name" {
  description = "The name of the AutoScaling group"
  type        = string
  default     = "ecs-asg"
}

variable "min_size" {
  description = "The minimum size of the AutoScaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum size of the AutoScaling group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "The desired capacity of the AutoScaling group"
  type        = number
  default     = 2
}