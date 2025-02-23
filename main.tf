provider "aws" {
  region  = "ap-southeast-2"
  profile = "sandpit"
}

# VPC module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# ECS module
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.12.0"

  cluster_name = var.ecs_cluster_name
  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }
}

# AutoScaling module
module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.1.0"

  name                      = var.asg_name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = module.vpc.private_subnets

  tags = {
    Name        = var.asg_name
    Environment = "dev"
  }
}

# Security Group module for ALB
module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name                = "alb_sg"
  description         = "Security group for web-server with HTTP ports open within VPC"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Name        = "ecs_security_group"
    Environment = "dev"
  }
}

# Security Group module for ECS
module "ecs_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "ecs_sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id
  ingress_with_source_security_group_id = [{
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    source_security_group_id = module.alb_sg.security_group_id
  }]

  tags = {
    Name        = "ecs_sg"
    Environment = "dev"
  }
}

# ALB module
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.13.0"

  name               = "ecs-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "nginx"
      }
    }
  }

  target_groups = {
    nginx = {
      name             = "ecs-nginx-tg"
      protocol         = "HTTP"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      create_attachment = false
      health_check = {
        enabled  = true
        path     = "/"
        interval = 30
        timeout  = 5
      }
    }
  }

  tags = {
    Name        = "ecs-alb"
    Environment = "dev"
  }
}


# Nginx Service module
module "nginx_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.0"

  name        = "nginx"
  cluster_arn = module.ecs.cluster_id
  container_definitions = {
    desired_count   = 1
    launch_type     = "EC2"
    subnet_ids      = module.vpc.private_subnets
    security_groups = [module.ecs_sg.security_group_id]

    load_balancer = {
      target_group_arn = module.alb.target_groups["nginx"].arn
      container_name   = "nginx"
      container_port   = 80
    }

    tags = {
      Name        = "nginx-service"
      Environment = "dev"
    }
  }
}

# ECS Container Definition module
module "ecs_container_definition" {
  source  = "terraform-aws-modules/ecs/aws//modules/container-definition"
  version = "5.12.0"

  name      = "nginx"
  cpu       = 256
  memory    = 512
  essential = true
  image     = "nginx:latest"
  port_mappings = [
    {
      container_port = 80
      host_port      = 80
    }
  ]
}