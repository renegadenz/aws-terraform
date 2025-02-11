ecs_cluster_name = "dev-ecs-cluster"
desired_count    = 1
ecs_task_family  = "dev-ecs-task-family"
container_image  = "nginx:latest"
ecs_service_name = "dev-ecs-service"
aws_profile      = "dev"