provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "us-east-1"
}

#used default VPC
resource "aws_default_vpc" "default_vpc" {
    tags = {
    name = "Default VPC"
  }
}

# define data source for subnets
data "aws_subnet_ids" "default_subnets" {
  vpc_id = aws_default_vpc.default_vpc.id
}

#define data-source for IAM role policy
 data "aws_iam_policy_document" "assume_role_policy" {
   statement {
     actions = ["sts:AssumeRole"]
     principals{
       type = "Service"
       identifiers = ["ecs-tasks.amazonaws.com"]
     }
   }
 }

#Create ECR Repo
resource "aws_ecr_repository" "ecr_repo" {
  name = "ecr_repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

#Create ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs_cluster"
}

#create cloud watch log group
resource "aws_cloudwatch_log_group" "ecs-service-log-group" {
  name = "ecs_service_log_group"
}

#Create ECS Task def and attach docker image from ecr registry and cloud cloudwatch log to it
resource "aws_ecs_task_defination" "ecs_service_task" {
  family = "ecs_service_task"
  container_definations = "<<DEFINATION 
  [
  {
  "name" : "ecs_service_task",
  "image" : "${aws_ecr_repository.ecr_repo.repository_url}:latest",
  "essential" : true,
  "portMappings" : [
  {
  "conatiner_port" : 8000,
  "host_port" : 8000
  }
  ],
  "environment": [
  {
  "name" : "spring.profiles.active",
  "value" : "dev"
  }
  ],
  "logConfigurations": {
  "logDriver" : "awslogs",
  "options": {
  "awslogs-group": "ecs-service-log-group",
  "awslogs-region" : "us-east-1",
  "awslogs-stream-prefix": "myecs"
  }
  },
  "cpu": 400,
  "memory": 2048,
  "memoryReservation": 1024
  }
  ]
  
  DEFINATION
  requires_compatibilities = ["FOFGATE"]
  network_mode = "awsvpc"
  memory = 2048
  cpu = 512
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  }
# Create a IAM role for Task execution
resource "aws_iam_role" "ecs_TaskExecutionRole" {
name = "ecs_TaskExecutionRole"
assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

#attach policy to the role
resource "aws_iam_policy_attachment" "ecs_TaskExecutionRole_policy"{
role = aws_iam_role.ecs_TaskExecutionRole.name
policy_arn= "arn.aws.iam::aws.policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#create security group for application load balancer
resource "aws_security_group" "alb_sg" {
name = "alb_sg"
vpc_id = "aws_default_vpc.default_vpc.id
ingress {
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
egress {
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
}
}

#create application load balance and attached security group
resource "aws_alb" "alb" {
name= "alb"
load_balancer_type = "application"
subnets = data.aws_subnet_id.default_subnets.ids
security_groups = [aws_security_group.alb_sg.id]
}

#create taget group
resource "aws_lb_target_group" "alb_target_group" {
  name = "alb-target-group"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = aws_default_vpc.default_vpc.id
}

#create listener and associate with target group
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

#craete ECS service and attach to task defination and security group
resource "aws_ecs_service" "ecs_service" {
  name = "ecs_service"
  cluster = aws_ecs_cluster.ecs_cluster.id
  desired_count = 1
  task_defination = aws_ecs_task_defination.ecs_service_task.arn
  launch_type = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name = aws_ecs_task_defination.ecs_service_task.family
    conatiner_port = 8000
  }
  
  network_configuration {
    subnets = data.aws_subnet_ids.default_subnets.ids
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_service_sg.id]
  }
  depends_on = [aws_lb_listener.alb_listener]
}

#create security group for service to communicate with alb security group
resource "aws_security_group" "ecs_service_sg" {
  ingress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_groups = [aws_security_group.alb_sg.id]
}
egress {
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
}
  
    
  
