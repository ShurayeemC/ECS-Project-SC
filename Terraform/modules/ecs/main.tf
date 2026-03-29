data "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_cluster" "sc-ecs-cluster" {
  name = "sc-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "sc-ecs-td" {
  family                   = "sc-ecs-td"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = data.aws_iam_role.ecs_execution_role.arn

  container_definitions = <<TASK_DEFINITION
[
  {
    "name": "ecr-threatmod",
    "image": "321431649440.dkr.ecr.eu-west-2.amazonaws.com/ecr-threatmod:v1.0.0",
    "cpu": 1024,
    "memory": 2048,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 3000,
        "protocol": "tcp"
      }
    ]
  }
]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "ecsproject-service" {
  name            = "ecsproject-service"
  cluster         = aws_ecs_cluster.sc-ecs-cluster.id
  task_definition = aws_ecs_task_definition.sc-ecs-td.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "ecr-threatmod"
    container_port   = 3000
  }
}
