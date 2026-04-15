terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

resource "aws_vpc" "york_hub_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "york-hub-vpc"
    Project     = "CSCL1070-Capstone"
    Environment = "Demo"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.york_hub_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ca-central-1a"
  tags = { Name = "york-public-ca-central-1a" }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.york_hub_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ca-central-1b"
  tags = { Name = "york-public-ca-central-1b" }
}

resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.york_hub_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ca-central-1a"
  tags = { Name = "york-private-app-ca-central-1a" }
}

resource "aws_subnet" "private_data_a" {
  vpc_id            = aws_vpc.york_hub_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ca-central-1a"
  tags = { Name = "york-private-data-ca-central-1a" }
}

resource "aws_subnet" "private_data_b" {
  vpc_id            = aws_vpc.york_hub_vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ca-central-1b"
  tags = { Name = "york-private-data-ca-central-1b" }
}

resource "aws_internet_gateway" "york_igw" {
  vpc_id = aws_vpc.york_hub_vpc.id
  tags = { Name = "york-igw" }
}

resource "aws_security_group" "rds_sg" {
  name        = "york-rds-sg"
  description = "Data tier - PostgreSQL from app tier only"
  vpc_id      = aws_vpc.york_hub_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24"]
    description = "PostgreSQL from app tier only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "york-data-tier-sg" }
}

resource "aws_db_subnet_group" "york_db_sg" {
  name       = "york-db-subnet-group"
  subnet_ids = [aws_subnet.private_data_a.id, aws_subnet.private_data_b.id]
  tags = { Name = "york-db-subnet-group" }
}

resource "aws_db_instance" "york_student_db" {
  identifier        = "york-student-db-demo"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "yorkstudentdb"
  username = "yorkadmin"
  password = "YorkCapstone2026!"

  db_subnet_group_name   = aws_db_subnet_group.york_db_sg.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 1

  tags = {
    Name       = "york-student-db-demo"
    Project    = "CSCL1070-Capstone"
    DataTier   = "Tier2-Operational"
    Compliance = "PIPEDA"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "york-portal-cpu-scale-out"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Triggers when RDS CPU exceeds 70% for 2 periods"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.york_student_db.identifier
  }

  tags = { Project = "CSCL1070-Capstone" }
}

output "vpc_id" {
  value       = aws_vpc.york_hub_vpc.id
  description = "York Hub VPC ID - ca-central-1"
}

output "vpc_cidr" {
  value = aws_vpc.york_hub_vpc.cidr_block
}

output "rds_endpoint" {
  value       = aws_db_instance.york_student_db.endpoint
  description = "RDS PostgreSQL endpoint - ca-central-1"
}

output "rds_engine_version" {
  value = aws_db_instance.york_student_db.engine_version_actual
}

output "region" {
  value = "ca-central-1"
}